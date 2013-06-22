
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 70 d6 10 80       	mov    $0x8010d670,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 bb 44 10 80       	mov    $0x801044bb,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 e8 93 10 	movl   $0x801093e8,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 e8 5b 00 00       	call   80105c36 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 b0 eb 10 80 a4 	movl   $0x8010eba4,0x8010ebb0
80100055:	eb 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 b4 eb 10 80 a4 	movl   $0x8010eba4,0x8010ebb4
8010005f:	eb 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 d6 10 80 	movl   $0x8010d6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 b4 eb 10 80    	mov    0x8010ebb4,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c a4 eb 10 80 	movl   $0x8010eba4,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 b4 eb 10 80       	mov    %eax,0x8010ebb4

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801000bd:	e8 95 5b 00 00       	call   80105c57 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100104:	e8 b0 5b 00 00       	call   80105cb9 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 55 58 00 00       	call   80105979 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 b0 eb 10 80       	mov    0x8010ebb0,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010017c:	e8 38 5b 00 00       	call   80105cb9 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 a4 eb 10 80 	cmpl   $0x8010eba4,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 ef 93 10 80 	movl   $0x801093ef,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 90 36 00 00       	call   80103868 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 00 94 10 80 	movl   $0x80109400,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 53 36 00 00       	call   80103868 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 07 94 10 80 	movl   $0x80109407,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 16 5a 00 00       	call   80105c57 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 b4 eb 10 80    	mov    0x8010ebb4,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c a4 eb 10 80 	movl   $0x8010eba4,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 b4 eb 10 80       	mov    0x8010ebb4,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 b4 eb 10 80       	mov    %eax,0x8010ebb4

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 b0 57 00 00       	call   80105a52 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 0b 5a 00 00       	call   80105cb9 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 a0 10 80 	movzbl -0x7fef5ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 14 c6 10 80       	mov    0x8010c614,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
801003bc:	e8 96 58 00 00       	call   80105c57 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 0e 94 10 80 	movl   $0x8010940e,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec 17 94 10 80 	movl   $0x80109417,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100536:	e8 7e 57 00 00       	call   80105cb9 <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 14 c6 10 80 00 	movl   $0x0,0x8010c614
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 1e 94 10 80 	movl   $0x8010941e,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 2d 94 10 80 	movl   $0x8010942d,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 71 57 00 00       	call   80105d08 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 2f 94 10 80 	movl   $0x8010942f,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 c0 c5 10 80 01 	movl   $0x1,0x8010c5c0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 c2 58 00 00       	call   80105f79 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 a0 10 80    	mov    0x8010a000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 c0 57 00 00       	call   80105ea6 <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 c0 c5 10 80       	mov    0x8010c5c0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 ce 72 00 00       	call   80107a49 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 c2 72 00 00       	call   80107a49 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 b6 72 00 00       	call   80107a49 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 a9 72 00 00       	call   80107a49 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801007ba:	e8 98 54 00 00       	call   80105c57 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 06 53 00 00       	call   80105af5 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
80100816:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 f4 ed 10 80 	movzbl -0x7fef120c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
80100844:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 7c ee 10 80    	mov    0x8010ee7c,%edx
8010087f:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 f4 ed 10 80    	mov    %dl,-0x7fef120c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 7c ee 10 80       	mov    %eax,0x8010ee7c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008d9:	8b 15 74 ee 10 80    	mov    0x8010ee74,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 7c ee 10 80       	mov    0x8010ee7c,%eax
801008eb:	a3 78 ee 10 80       	mov    %eax,0x8010ee78
          wakeup(&input.r);
801008f0:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
801008f7:	e8 56 51 00 00       	call   80105a52 <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
8010091e:	e8 96 53 00 00       	call   80105cb9 <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 20 1e 00 00       	call   80102756 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 0f 53 00 00       	call   80105c57 <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100961:	e8 53 53 00 00       	call   80105cb9 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 97 1c 00 00       	call   80102608 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 ea 4f 00 00       	call   80105979 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 74 ee 10 80    	mov    0x8010ee74,%edx
80100998:	a1 78 ee 10 80       	mov    0x8010ee78,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 f4 ed 10 80 	movzbl -0x7fef120c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 74 ee 10 80       	mov    %eax,0x8010ee74
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 74 ee 10 80       	mov    0x8010ee74,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 74 ee 10 80       	mov    %eax,0x8010ee74
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100a08:	e8 ac 52 00 00       	call   80105cb9 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 f0 1b 00 00       	call   80102608 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 1f 1d 00 00       	call   80102756 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 14 52 00 00       	call   80105c57 <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a78:	e8 3c 52 00 00       	call   80105cb9 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 80 1b 00 00       	call   80102608 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 33 94 10 	movl   $0x80109433,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 8f 51 00 00       	call   80105c36 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 3b 94 10 	movl   $0x8010943b,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 7b 51 00 00       	call   80105c36 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 4c f8 10 80 26 	movl   $0x80100a26,0x8010f84c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 48 f8 10 80 25 	movl   $0x80100925,0x8010f848
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 90 40 00 00       	call   80104b75 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 31 2f 00 00       	call   80103a2a <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  if((ip = namei(path)) == 0)
80100b05:	8b 45 08             	mov    0x8(%ebp),%eax
80100b08:	89 04 24             	mov    %eax,(%esp)
80100b0b:	e8 9a 26 00 00       	call   801031aa <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 da 1a 00 00       	call   80102608 <ilock>
  pgdir = 0;
80100b2e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b35:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b3c:	00 
80100b3d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b44:	00 
80100b45:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b52:	89 04 24             	mov    %eax,(%esp)
80100b55:	e8 a4 1f 00 00       	call   80102afe <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 b3 3b 10 80 	movl   $0x80103bb3,(%esp)
80100b7b:	e8 0d 80 00 00       	call   80108b8d <setupkvm>
80100b80:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b83:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b87:	0f 84 30 03 00 00    	je     80100ebd <exec+0x3c1>
    goto bad;

  // Load program into memory.
  sz = 0;
80100b8d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b94:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b9b:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100ba1:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100ba4:	e9 c5 00 00 00       	jmp    80100c6e <exec+0x172>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bac:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bb3:	00 
80100bb4:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb8:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bc5:	89 04 24             	mov    %eax,(%esp)
80100bc8:	e8 31 1f 00 00       	call   80102afe <readi>
80100bcd:	83 f8 20             	cmp    $0x20,%eax
80100bd0:	0f 85 ea 02 00 00    	jne    80100ec0 <exec+0x3c4>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100bd6:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bdc:	83 f8 01             	cmp    $0x1,%eax
80100bdf:	75 7f                	jne    80100c60 <exec+0x164>
      continue;
    if(ph.memsz < ph.filesz)
80100be1:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be7:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bed:	39 c2                	cmp    %eax,%edx
80100bef:	0f 82 ce 02 00 00    	jb     80100ec3 <exec+0x3c7>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 46 83 00 00       	call   80108f5f <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	0f 84 a0 02 00 00    	je     80100ec6 <exec+0x3ca>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c26:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2c:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c32:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c38:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c40:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c43:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c47:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c4e:	89 04 24             	mov    %eax,(%esp)
80100c51:	e8 1a 82 00 00       	call   80108e70 <loaduvm>
80100c56:	85 c0                	test   %eax,%eax
80100c58:	0f 88 6b 02 00 00    	js     80100ec9 <exec+0x3cd>
80100c5e:	eb 01                	jmp    80100c61 <exec+0x165>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100c60:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c61:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c65:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c68:	83 c0 20             	add    $0x20,%eax
80100c6b:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6e:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c75:	0f b7 c0             	movzwl %ax,%eax
80100c78:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7b:	0f 8f 28 ff ff ff    	jg     80100ba9 <exec+0xad>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c81:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c84:	89 04 24             	mov    %eax,(%esp)
80100c87:	e8 00 1c 00 00       	call   8010288c <iunlockput>
  ip = 0;
80100c8c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c93:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c96:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c9b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100ca0:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ca3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ca6:	05 00 20 00 00       	add    $0x2000,%eax
80100cab:	89 44 24 08          	mov    %eax,0x8(%esp)
80100caf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cb6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cb9:	89 04 24             	mov    %eax,(%esp)
80100cbc:	e8 9e 82 00 00       	call   80108f5f <allocuvm>
80100cc1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cc4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cc8:	0f 84 fe 01 00 00    	je     80100ecc <exec+0x3d0>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cce:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd1:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cd6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cdd:	89 04 24             	mov    %eax,(%esp)
80100ce0:	e8 9e 84 00 00       	call   80109183 <clearpteu>
  sp = sz;
80100ce5:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ce8:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100ceb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cf2:	e9 81 00 00 00       	jmp    80100d78 <exec+0x27c>
    if(argc >= MAXARG)
80100cf7:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100cfb:	0f 87 ce 01 00 00    	ja     80100ecf <exec+0x3d3>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d04:	c1 e0 02             	shl    $0x2,%eax
80100d07:	03 45 0c             	add    0xc(%ebp),%eax
80100d0a:	8b 00                	mov    (%eax),%eax
80100d0c:	89 04 24             	mov    %eax,(%esp)
80100d0f:	e8 10 54 00 00       	call   80106124 <strlen>
80100d14:	f7 d0                	not    %eax
80100d16:	03 45 dc             	add    -0x24(%ebp),%eax
80100d19:	83 e0 fc             	and    $0xfffffffc,%eax
80100d1c:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d1f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d22:	c1 e0 02             	shl    $0x2,%eax
80100d25:	03 45 0c             	add    0xc(%ebp),%eax
80100d28:	8b 00                	mov    (%eax),%eax
80100d2a:	89 04 24             	mov    %eax,(%esp)
80100d2d:	e8 f2 53 00 00       	call   80106124 <strlen>
80100d32:	83 c0 01             	add    $0x1,%eax
80100d35:	89 c2                	mov    %eax,%edx
80100d37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d3a:	c1 e0 02             	shl    $0x2,%eax
80100d3d:	03 45 0c             	add    0xc(%ebp),%eax
80100d40:	8b 00                	mov    (%eax),%eax
80100d42:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d46:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d54:	89 04 24             	mov    %eax,(%esp)
80100d57:	e8 db 85 00 00       	call   80109337 <copyout>
80100d5c:	85 c0                	test   %eax,%eax
80100d5e:	0f 88 6e 01 00 00    	js     80100ed2 <exec+0x3d6>
      goto bad;
    ustack[3+argc] = sp;
80100d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d67:	8d 50 03             	lea    0x3(%eax),%edx
80100d6a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6d:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d74:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d7b:	c1 e0 02             	shl    $0x2,%eax
80100d7e:	03 45 0c             	add    0xc(%ebp),%eax
80100d81:	8b 00                	mov    (%eax),%eax
80100d83:	85 c0                	test   %eax,%eax
80100d85:	0f 85 6c ff ff ff    	jne    80100cf7 <exec+0x1fb>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100d8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d8e:	83 c0 03             	add    $0x3,%eax
80100d91:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100d98:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100d9c:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100da3:	ff ff ff 
  ustack[1] = argc;
80100da6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da9:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 01             	add    $0x1,%eax
80100db5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dbc:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dbf:	29 d0                	sub    %edx,%eax
80100dc1:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100dc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dca:	83 c0 04             	add    $0x4,%eax
80100dcd:	c1 e0 02             	shl    $0x2,%eax
80100dd0:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 04             	add    $0x4,%eax
80100dd9:	c1 e0 02             	shl    $0x2,%eax
80100ddc:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100de0:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100de6:	89 44 24 08          	mov    %eax,0x8(%esp)
80100dea:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ded:	89 44 24 04          	mov    %eax,0x4(%esp)
80100df1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100df4:	89 04 24             	mov    %eax,(%esp)
80100df7:	e8 3b 85 00 00       	call   80109337 <copyout>
80100dfc:	85 c0                	test   %eax,%eax
80100dfe:	0f 88 d1 00 00 00    	js     80100ed5 <exec+0x3d9>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e04:	8b 45 08             	mov    0x8(%ebp),%eax
80100e07:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e10:	eb 17                	jmp    80100e29 <exec+0x32d>
    if(*s == '/')
80100e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e15:	0f b6 00             	movzbl (%eax),%eax
80100e18:	3c 2f                	cmp    $0x2f,%al
80100e1a:	75 09                	jne    80100e25 <exec+0x329>
      last = s+1;
80100e1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e1f:	83 c0 01             	add    $0x1,%eax
80100e22:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e25:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e2c:	0f b6 00             	movzbl (%eax),%eax
80100e2f:	84 c0                	test   %al,%al
80100e31:	75 df                	jne    80100e12 <exec+0x316>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e33:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e39:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e3c:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e43:	00 
80100e44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e47:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e4b:	89 14 24             	mov    %edx,(%esp)
80100e4e:	e8 83 52 00 00       	call   801060d6 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e59:	8b 40 04             	mov    0x4(%eax),%eax
80100e5c:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e65:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e68:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e71:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e74:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e76:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7c:	8b 40 18             	mov    0x18(%eax),%eax
80100e7f:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100e85:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100e88:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8e:	8b 40 18             	mov    0x18(%eax),%eax
80100e91:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100e94:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100e97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e9d:	89 04 24             	mov    %eax,(%esp)
80100ea0:	e8 d9 7d 00 00       	call   80108c7e <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 45 82 00 00       	call   801090f5 <freevm>
  return 0;
80100eb0:	b8 00 00 00 00       	mov    $0x0,%eax
80100eb5:	eb 46                	jmp    80100efd <exec+0x401>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100eb7:	90                   	nop
80100eb8:	eb 1c                	jmp    80100ed6 <exec+0x3da>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100eba:	90                   	nop
80100ebb:	eb 19                	jmp    80100ed6 <exec+0x3da>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100ebd:	90                   	nop
80100ebe:	eb 16                	jmp    80100ed6 <exec+0x3da>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100ec0:	90                   	nop
80100ec1:	eb 13                	jmp    80100ed6 <exec+0x3da>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100ec3:	90                   	nop
80100ec4:	eb 10                	jmp    80100ed6 <exec+0x3da>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100ec6:	90                   	nop
80100ec7:	eb 0d                	jmp    80100ed6 <exec+0x3da>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100ec9:	90                   	nop
80100eca:	eb 0a                	jmp    80100ed6 <exec+0x3da>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100ecc:	90                   	nop
80100ecd:	eb 07                	jmp    80100ed6 <exec+0x3da>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100ecf:	90                   	nop
80100ed0:	eb 04                	jmp    80100ed6 <exec+0x3da>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100ed2:	90                   	nop
80100ed3:	eb 01                	jmp    80100ed6 <exec+0x3da>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100ed5:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100ed6:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100eda:	74 0b                	je     80100ee7 <exec+0x3eb>
    freevm(pgdir);
80100edc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100edf:	89 04 24             	mov    %eax,(%esp)
80100ee2:	e8 0e 82 00 00       	call   801090f5 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 94 19 00 00       	call   8010288c <iunlockput>
  return -1;
80100ef8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100efd:	c9                   	leave  
80100efe:	c3                   	ret    
	...

80100f00 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f00:	55                   	push   %ebp
80100f01:	89 e5                	mov    %esp,%ebp
80100f03:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f06:	c7 44 24 04 48 94 10 	movl   $0x80109448,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f15:	e8 1c 4d 00 00       	call   80105c36 <initlock>
}
80100f1a:	c9                   	leave  
80100f1b:	c3                   	ret    

80100f1c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f1c:	55                   	push   %ebp
80100f1d:	89 e5                	mov    %esp,%ebp
80100f1f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f22:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f29:	e8 29 4d 00 00       	call   80105c57 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 d4 ee 10 80 	movl   $0x8010eed4,-0xc(%ebp)
80100f35:	eb 29                	jmp    80100f60 <filealloc+0x44>
    if(f->ref == 0){
80100f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f3a:	8b 40 04             	mov    0x4(%eax),%eax
80100f3d:	85 c0                	test   %eax,%eax
80100f3f:	75 1b                	jne    80100f5c <filealloc+0x40>
      f->ref = 1;
80100f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f44:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f4b:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f52:	e8 62 4d 00 00       	call   80105cb9 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 34 f8 10 80 	cmpl   $0x8010f834,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f70:	e8 44 4d 00 00       	call   80105cb9 <release>
  return 0;
80100f75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f7a:	c9                   	leave  
80100f7b:	c3                   	ret    

80100f7c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f7c:	55                   	push   %ebp
80100f7d:	89 e5                	mov    %esp,%ebp
80100f7f:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f82:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f89:	e8 c9 4c 00 00       	call   80105c57 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 4f 94 10 80 	movl   $0x8010944f,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fba:	e8 fa 4c 00 00       	call   80105cb9 <release>
  return f;
80100fbf:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fc2:	c9                   	leave  
80100fc3:	c3                   	ret    

80100fc4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fc4:	55                   	push   %ebp
80100fc5:	89 e5                	mov    %esp,%ebp
80100fc7:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fca:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fd1:	e8 81 4c 00 00       	call   80105c57 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 57 94 10 80 	movl   $0x80109457,(%esp)
80100fe7:	e8 51 f5 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80100fec:	8b 45 08             	mov    0x8(%ebp),%eax
80100fef:	8b 40 04             	mov    0x4(%eax),%eax
80100ff2:	8d 50 ff             	lea    -0x1(%eax),%edx
80100ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff8:	89 50 04             	mov    %edx,0x4(%eax)
80100ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80100ffe:	8b 40 04             	mov    0x4(%eax),%eax
80101001:	85 c0                	test   %eax,%eax
80101003:	7e 11                	jle    80101016 <fileclose+0x52>
    release(&ftable.lock);
80101005:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
8010100c:	e8 a8 4c 00 00       	call   80105cb9 <release>
    return;
80101011:	e9 82 00 00 00       	jmp    80101098 <fileclose+0xd4>
  }
  ff = *f;
80101016:	8b 45 08             	mov    0x8(%ebp),%eax
80101019:	8b 10                	mov    (%eax),%edx
8010101b:	89 55 e0             	mov    %edx,-0x20(%ebp)
8010101e:	8b 50 04             	mov    0x4(%eax),%edx
80101021:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101024:	8b 50 08             	mov    0x8(%eax),%edx
80101027:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010102a:	8b 50 0c             	mov    0xc(%eax),%edx
8010102d:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101030:	8b 50 10             	mov    0x10(%eax),%edx
80101033:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101036:	8b 40 14             	mov    0x14(%eax),%eax
80101039:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
8010103c:	8b 45 08             	mov    0x8(%ebp),%eax
8010103f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
8010104f:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80101056:	e8 5e 4c 00 00       	call   80105cb9 <release>
  
  if(ff.type == FD_PIPE)
8010105b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010105e:	83 f8 01             	cmp    $0x1,%eax
80101061:	75 18                	jne    8010107b <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101063:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101067:	0f be d0             	movsbl %al,%edx
8010106a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010106d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101071:	89 04 24             	mov    %eax,(%esp)
80101074:	e8 b6 3d 00 00       	call   80104e2f <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 49 32 00 00       	call   801042d1 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 28 17 00 00       	call   801027bb <iput>
    commit_trans();
80101093:	e8 82 32 00 00       	call   8010431a <commit_trans>
  }
}
80101098:	c9                   	leave  
80101099:	c3                   	ret    

8010109a <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010109a:	55                   	push   %ebp
8010109b:	89 e5                	mov    %esp,%ebp
8010109d:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010a0:	8b 45 08             	mov    0x8(%ebp),%eax
801010a3:	8b 00                	mov    (%eax),%eax
801010a5:	83 f8 02             	cmp    $0x2,%eax
801010a8:	75 38                	jne    801010e2 <filestat+0x48>
    ilock(f->ip);
801010aa:	8b 45 08             	mov    0x8(%ebp),%eax
801010ad:	8b 40 10             	mov    0x10(%eax),%eax
801010b0:	89 04 24             	mov    %eax,(%esp)
801010b3:	e8 50 15 00 00       	call   80102608 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 ec 19 00 00       	call   80102ab9 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 7b 16 00 00       	call   80102756 <iunlock>
    return 0;
801010db:	b8 00 00 00 00       	mov    $0x0,%eax
801010e0:	eb 05                	jmp    801010e7 <filestat+0x4d>
  }
  return -1;
801010e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010e7:	c9                   	leave  
801010e8:	c3                   	ret    

801010e9 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010e9:	55                   	push   %ebp
801010ea:	89 e5                	mov    %esp,%ebp
801010ec:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010ef:	8b 45 08             	mov    0x8(%ebp),%eax
801010f2:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801010f6:	84 c0                	test   %al,%al
801010f8:	75 0a                	jne    80101104 <fileread+0x1b>
    return -1;
801010fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801010ff:	e9 9f 00 00 00       	jmp    801011a3 <fileread+0xba>
  if(f->type == FD_PIPE)
80101104:	8b 45 08             	mov    0x8(%ebp),%eax
80101107:	8b 00                	mov    (%eax),%eax
80101109:	83 f8 01             	cmp    $0x1,%eax
8010110c:	75 1e                	jne    8010112c <fileread+0x43>
    return piperead(f->pipe, addr, n);
8010110e:	8b 45 08             	mov    0x8(%ebp),%eax
80101111:	8b 40 0c             	mov    0xc(%eax),%eax
80101114:	8b 55 10             	mov    0x10(%ebp),%edx
80101117:	89 54 24 08          	mov    %edx,0x8(%esp)
8010111b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010111e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101122:	89 04 24             	mov    %eax,(%esp)
80101125:	e8 87 3e 00 00       	call   80104fb1 <piperead>
8010112a:	eb 77                	jmp    801011a3 <fileread+0xba>
  if(f->type == FD_INODE){
8010112c:	8b 45 08             	mov    0x8(%ebp),%eax
8010112f:	8b 00                	mov    (%eax),%eax
80101131:	83 f8 02             	cmp    $0x2,%eax
80101134:	75 61                	jne    80101197 <fileread+0xae>
    ilock(f->ip);
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 40 10             	mov    0x10(%eax),%eax
8010113c:	89 04 24             	mov    %eax,(%esp)
8010113f:	e8 c4 14 00 00       	call   80102608 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101144:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101147:	8b 45 08             	mov    0x8(%ebp),%eax
8010114a:	8b 50 14             	mov    0x14(%eax),%edx
8010114d:	8b 45 08             	mov    0x8(%ebp),%eax
80101150:	8b 40 10             	mov    0x10(%eax),%eax
80101153:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101157:	89 54 24 08          	mov    %edx,0x8(%esp)
8010115b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010115e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101162:	89 04 24             	mov    %eax,(%esp)
80101165:	e8 94 19 00 00       	call   80102afe <readi>
8010116a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010116d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101171:	7e 11                	jle    80101184 <fileread+0x9b>
      f->off += r;
80101173:	8b 45 08             	mov    0x8(%ebp),%eax
80101176:	8b 50 14             	mov    0x14(%eax),%edx
80101179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010117c:	01 c2                	add    %eax,%edx
8010117e:	8b 45 08             	mov    0x8(%ebp),%eax
80101181:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101184:	8b 45 08             	mov    0x8(%ebp),%eax
80101187:	8b 40 10             	mov    0x10(%eax),%eax
8010118a:	89 04 24             	mov    %eax,(%esp)
8010118d:	e8 c4 15 00 00       	call   80102756 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 61 94 10 80 	movl   $0x80109461,(%esp)
8010119e:	e8 9a f3 ff ff       	call   8010053d <panic>
}
801011a3:	c9                   	leave  
801011a4:	c3                   	ret    

801011a5 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011a5:	55                   	push   %ebp
801011a6:	89 e5                	mov    %esp,%ebp
801011a8:	53                   	push   %ebx
801011a9:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011ac:	8b 45 08             	mov    0x8(%ebp),%eax
801011af:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011b3:	84 c0                	test   %al,%al
801011b5:	75 0a                	jne    801011c1 <filewrite+0x1c>
    return -1;
801011b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011bc:	e9 23 01 00 00       	jmp    801012e4 <filewrite+0x13f>
  if(f->type == FD_PIPE)
801011c1:	8b 45 08             	mov    0x8(%ebp),%eax
801011c4:	8b 00                	mov    (%eax),%eax
801011c6:	83 f8 01             	cmp    $0x1,%eax
801011c9:	75 21                	jne    801011ec <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011cb:	8b 45 08             	mov    0x8(%ebp),%eax
801011ce:	8b 40 0c             	mov    0xc(%eax),%eax
801011d1:	8b 55 10             	mov    0x10(%ebp),%edx
801011d4:	89 54 24 08          	mov    %edx,0x8(%esp)
801011d8:	8b 55 0c             	mov    0xc(%ebp),%edx
801011db:	89 54 24 04          	mov    %edx,0x4(%esp)
801011df:	89 04 24             	mov    %eax,(%esp)
801011e2:	e8 da 3c 00 00       	call   80104ec1 <pipewrite>
801011e7:	e9 f8 00 00 00       	jmp    801012e4 <filewrite+0x13f>
  if(f->type == FD_INODE){
801011ec:	8b 45 08             	mov    0x8(%ebp),%eax
801011ef:	8b 00                	mov    (%eax),%eax
801011f1:	83 f8 02             	cmp    $0x2,%eax
801011f4:	0f 85 de 00 00 00    	jne    801012d8 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801011fa:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101201:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101208:	e9 a8 00 00 00       	jmp    801012b5 <filewrite+0x110>
      int n1 = n - i;
8010120d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101210:	8b 55 10             	mov    0x10(%ebp),%edx
80101213:	89 d1                	mov    %edx,%ecx
80101215:	29 c1                	sub    %eax,%ecx
80101217:	89 c8                	mov    %ecx,%eax
80101219:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
8010121c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010121f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101222:	7e 06                	jle    8010122a <filewrite+0x85>
        n1 = max;
80101224:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101227:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010122a:	e8 a2 30 00 00       	call   801042d1 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 cb 13 00 00       	call   80102608 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010123d:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	8b 48 14             	mov    0x14(%eax),%ecx
80101246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101249:	89 c2                	mov    %eax,%edx
8010124b:	03 55 0c             	add    0xc(%ebp),%edx
8010124e:	8b 45 08             	mov    0x8(%ebp),%eax
80101251:	8b 40 10             	mov    0x10(%eax),%eax
80101254:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101258:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010125c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101260:	89 04 24             	mov    %eax,(%esp)
80101263:	e8 01 1a 00 00       	call   80102c69 <writei>
80101268:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010126b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010126f:	7e 11                	jle    80101282 <filewrite+0xdd>
        f->off += r;
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 50 14             	mov    0x14(%eax),%edx
80101277:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010127a:	01 c2                	add    %eax,%edx
8010127c:	8b 45 08             	mov    0x8(%ebp),%eax
8010127f:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101282:	8b 45 08             	mov    0x8(%ebp),%eax
80101285:	8b 40 10             	mov    0x10(%eax),%eax
80101288:	89 04 24             	mov    %eax,(%esp)
8010128b:	e8 c6 14 00 00       	call   80102756 <iunlock>
      commit_trans();
80101290:	e8 85 30 00 00       	call   8010431a <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 6a 94 10 80 	movl   $0x8010946a,(%esp)
801012aa:	e8 8e f2 ff ff       	call   8010053d <panic>
      i += r;
801012af:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012b2:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012b8:	3b 45 10             	cmp    0x10(%ebp),%eax
801012bb:	0f 8c 4c ff ff ff    	jl     8010120d <filewrite+0x68>
801012c1:	eb 01                	jmp    801012c4 <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
801012c3:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c7:	3b 45 10             	cmp    0x10(%ebp),%eax
801012ca:	75 05                	jne    801012d1 <filewrite+0x12c>
801012cc:	8b 45 10             	mov    0x10(%ebp),%eax
801012cf:	eb 05                	jmp    801012d6 <filewrite+0x131>
801012d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012d6:	eb 0c                	jmp    801012e4 <filewrite+0x13f>
  }
  panic("filewrite");
801012d8:	c7 04 24 7a 94 10 80 	movl   $0x8010947a,(%esp)
801012df:	e8 59 f2 ff ff       	call   8010053d <panic>
}
801012e4:	83 c4 24             	add    $0x24,%esp
801012e7:	5b                   	pop    %ebx
801012e8:	5d                   	pop    %ebp
801012e9:	c3                   	ret    

801012ea <getFileBlocks>:

int
getFileBlocks(char* path)
{
801012ea:	55                   	push   %ebp
801012eb:	89 e5                	mov    %esp,%ebp
801012ed:	83 ec 38             	sub    $0x38,%esp
  struct file * f;
  struct inode* ip;
  struct buf* bp;
  uint i ,*a;
  
  if((f = fileopen(path,O_RDONLY)) == 0)
801012f0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801012f7:	00 
801012f8:	8b 45 08             	mov    0x8(%ebp),%eax
801012fb:	89 04 24             	mov    %eax,(%esp)
801012fe:	e8 d2 58 00 00       	call   80106bd5 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 84 94 10 80 	movl   $0x80109484,(%esp)
8010131a:	e8 82 f0 ff ff       	call   801003a1 <cprintf>
    return -1;
8010131f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101324:	e9 1c 01 00 00       	jmp    80101445 <getFileBlocks+0x15b>
  }
  ip = f->ip;
80101329:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010132c:	8b 40 10             	mov    0x10(%eax),%eax
8010132f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  ilock(ip);
80101332:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101335:	89 04 24             	mov    %eax,(%esp)
80101338:	e8 cb 12 00 00       	call   80102608 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 9c 94 10 80 	movl   $0x8010949c,(%esp)
8010134b:	e8 51 f0 ff ff       	call   801003a1 <cprintf>
  
  for(i = 0; i < NDIRECT ; i++)
80101350:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101357:	eb 39                	jmp    80101392 <getFileBlocks+0xa8>
  {
    if(ip->addrs[i])
80101359:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010135c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010135f:	83 c2 04             	add    $0x4,%edx
80101362:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101366:	85 c0                	test   %eax,%eax
80101368:	74 24                	je     8010138e <getFileBlocks+0xa4>
      cprintf("DIRECT block #%d = %d\n",i,ip->addrs[i]);
8010136a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010136d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101370:	83 c2 04             	add    $0x4,%edx
80101373:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101377:	89 44 24 08          	mov    %eax,0x8(%esp)
8010137b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101382:	c7 04 24 bf 94 10 80 	movl   $0x801094bf,(%esp)
80101389:	e8 13 f0 ff ff       	call   801003a1 <cprintf>
  ip = f->ip;
  ilock(ip);
  
  cprintf("Printing all blocks for file %s:\n\n",path);
  
  for(i = 0; i < NDIRECT ; i++)
8010138e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101392:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101396:	76 c1                	jbe    80101359 <getFileBlocks+0x6f>
  {
    if(ip->addrs[i])
      cprintf("DIRECT block #%d = %d\n",i,ip->addrs[i]);
  }
  if(ip->addrs[NDIRECT]){
80101398:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010139b:	8b 40 4c             	mov    0x4c(%eax),%eax
8010139e:	85 c0                	test   %eax,%eax
801013a0:	0f 84 8f 00 00 00    	je     80101435 <getFileBlocks+0x14b>
    cprintf("INDIRECT TABLE block #%d = %d\n",i,ip->addrs[NDIRECT]);
801013a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801013a9:	8b 40 4c             	mov    0x4c(%eax),%eax
801013ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801013b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801013b7:	c7 04 24 d8 94 10 80 	movl   $0x801094d8,(%esp)
801013be:	e8 de ef ff ff       	call   801003a1 <cprintf>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801013c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801013c6:	8b 50 4c             	mov    0x4c(%eax),%edx
801013c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801013cc:	8b 00                	mov    (%eax),%eax
801013ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801013d2:	89 04 24             	mov    %eax,(%esp)
801013d5:	e8 cc ed ff ff       	call   801001a6 <bread>
801013da:	89 45 e8             	mov    %eax,-0x18(%ebp)
    a = (uint*)bp->data;
801013dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013e0:	83 c0 18             	add    $0x18,%eax
801013e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(i = 0; i < NINDIRECT; i++){
801013e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013ed:	eb 35                	jmp    80101424 <getFileBlocks+0x13a>
      if(a[i])
801013ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013f2:	c1 e0 02             	shl    $0x2,%eax
801013f5:	03 45 e4             	add    -0x1c(%ebp),%eax
801013f8:	8b 00                	mov    (%eax),%eax
801013fa:	85 c0                	test   %eax,%eax
801013fc:	74 22                	je     80101420 <getFileBlocks+0x136>
        cprintf("INDIRECT block #%d = %d\n",i,a[i]);
801013fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101401:	c1 e0 02             	shl    $0x2,%eax
80101404:	03 45 e4             	add    -0x1c(%ebp),%eax
80101407:	8b 00                	mov    (%eax),%eax
80101409:	89 44 24 08          	mov    %eax,0x8(%esp)
8010140d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101410:	89 44 24 04          	mov    %eax,0x4(%esp)
80101414:	c7 04 24 f7 94 10 80 	movl   $0x801094f7,(%esp)
8010141b:	e8 81 ef ff ff       	call   801003a1 <cprintf>
  }
  if(ip->addrs[NDIRECT]){
    cprintf("INDIRECT TABLE block #%d = %d\n",i,ip->addrs[NDIRECT]);
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(i = 0; i < NINDIRECT; i++){
80101420:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101424:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80101428:	76 c5                	jbe    801013ef <getFileBlocks+0x105>
      if(a[i])
        cprintf("INDIRECT block #%d = %d\n",i,a[i]);
    }
    brelse(bp);
8010142a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010142d:	89 04 24             	mov    %eax,(%esp)
80101430:	e8 e2 ed ff ff       	call   80100217 <brelse>
    
  }
  iunlock(ip);
80101435:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101438:	89 04 24             	mov    %eax,(%esp)
8010143b:	e8 16 13 00 00       	call   80102756 <iunlock>
  return 0;  
80101440:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101445:	c9                   	leave  
80101446:	c3                   	ret    

80101447 <getFreeBlocks>:

int
getFreeBlocks(void)
{
80101447:	55                   	push   %ebp
80101448:	89 e5                	mov    %esp,%ebp
8010144a:	53                   	push   %ebx
8010144b:	83 ec 44             	sub    $0x44,%esp
  int b, bi, m,count = 0;
8010144e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101455:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  readsb(1, &sb);
8010145c:	8d 45 d4             	lea    -0x2c(%ebp),%eax
8010145f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101463:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010146a:	e8 05 0c 00 00       	call   80102074 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010146f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101476:	e9 ae 00 00 00       	jmp    80101529 <getFreeBlocks+0xe2>
    bp = bread(1, BBLOCK(b, sb.ninodes));
8010147b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010147e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101484:	85 c0                	test   %eax,%eax
80101486:	0f 48 c2             	cmovs  %edx,%eax
80101489:	c1 f8 0c             	sar    $0xc,%eax
8010148c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010148f:	c1 ea 03             	shr    $0x3,%edx
80101492:	01 d0                	add    %edx,%eax
80101494:	83 c0 03             	add    $0x3,%eax
80101497:	89 44 24 04          	mov    %eax,0x4(%esp)
8010149b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801014a2:	e8 ff ec ff ff       	call   801001a6 <bread>
801014a7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014aa:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014b1:	eb 4a                	jmp    801014fd <getFreeBlocks+0xb6>
      m = 1 << (bi % 8);
801014b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014b6:	89 c2                	mov    %eax,%edx
801014b8:	c1 fa 1f             	sar    $0x1f,%edx
801014bb:	c1 ea 1d             	shr    $0x1d,%edx
801014be:	01 d0                	add    %edx,%eax
801014c0:	83 e0 07             	and    $0x7,%eax
801014c3:	29 d0                	sub    %edx,%eax
801014c5:	ba 01 00 00 00       	mov    $0x1,%edx
801014ca:	89 d3                	mov    %edx,%ebx
801014cc:	89 c1                	mov    %eax,%ecx
801014ce:	d3 e3                	shl    %cl,%ebx
801014d0:	89 d8                	mov    %ebx,%eax
801014d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014d8:	8d 50 07             	lea    0x7(%eax),%edx
801014db:	85 c0                	test   %eax,%eax
801014dd:	0f 48 c2             	cmovs  %edx,%eax
801014e0:	c1 f8 03             	sar    $0x3,%eax
801014e3:	8b 55 e8             	mov    -0x18(%ebp),%edx
801014e6:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801014eb:	0f b6 c0             	movzbl %al,%eax
801014ee:	23 45 e4             	and    -0x1c(%ebp),%eax
801014f1:	85 c0                	test   %eax,%eax
801014f3:	75 04                	jne    801014f9 <getFreeBlocks+0xb2>
	  count++;
801014f5:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)

  bp = 0;
  readsb(1, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(1, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014f9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014fd:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101504:	7f 11                	jg     80101517 <getFreeBlocks+0xd0>
80101506:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101509:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010150c:	01 d0                	add    %edx,%eax
8010150e:	89 c2                	mov    %eax,%edx
80101510:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101513:	39 c2                	cmp    %eax,%edx
80101515:	72 9c                	jb     801014b3 <getFreeBlocks+0x6c>
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // Is block free?
	  count++;
      }
    }
    brelse(bp);
80101517:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010151a:	89 04 24             	mov    %eax,(%esp)
8010151d:	e8 f5 ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(1, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101522:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101529:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010152c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010152f:	39 c2                	cmp    %eax,%edx
80101531:	0f 82 44 ff ff ff    	jb     8010147b <getFreeBlocks+0x34>
	  count++;
      }
    }
    brelse(bp);
  }
  cprintf("No. of free blocks = %d\n",count);
80101537:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010153a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010153e:	c7 04 24 10 95 10 80 	movl   $0x80109510,(%esp)
80101545:	e8 57 ee ff ff       	call   801003a1 <cprintf>
  return 0;
8010154a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010154f:	83 c4 44             	add    $0x44,%esp
80101552:	5b                   	pop    %ebx
80101553:	5d                   	pop    %ebp
80101554:	c3                   	ret    

80101555 <blkcmp>:

int
blkcmp(struct buf* b1, struct buf* b2)
{//cprintf("in blkcmp\n");
80101555:	55                   	push   %ebp
80101556:	89 e5                	mov    %esp,%ebp
80101558:	83 ec 10             	sub    $0x10,%esp
  int i;
  for(i = 0; i<BSIZE; i++)
8010155b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80101562:	eb 29                	jmp    8010158d <blkcmp+0x38>
  {
    if(b1->data[i] != b2->data[i])
80101564:	8b 45 08             	mov    0x8(%ebp),%eax
80101567:	03 45 fc             	add    -0x4(%ebp),%eax
8010156a:	83 c0 10             	add    $0x10,%eax
8010156d:	0f b6 50 08          	movzbl 0x8(%eax),%edx
80101571:	8b 45 0c             	mov    0xc(%ebp),%eax
80101574:	03 45 fc             	add    -0x4(%ebp),%eax
80101577:	83 c0 10             	add    $0x10,%eax
8010157a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010157e:	38 c2                	cmp    %al,%dl
80101580:	74 07                	je     80101589 <blkcmp+0x34>
      return 0;
80101582:	b8 00 00 00 00       	mov    $0x0,%eax
80101587:	eb 12                	jmp    8010159b <blkcmp+0x46>

int
blkcmp(struct buf* b1, struct buf* b2)
{//cprintf("in blkcmp\n");
  int i;
  for(i = 0; i<BSIZE; i++)
80101589:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010158d:	81 7d fc ff 01 00 00 	cmpl   $0x1ff,-0x4(%ebp)
80101594:	7e ce                	jle    80101564 <blkcmp+0xf>
  {
    if(b1->data[i] != b2->data[i])
      return 0;
  }
  return 1;  
80101596:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010159b:	c9                   	leave  
8010159c:	c3                   	ret    

8010159d <deletedups>:

void
deletedups(struct inode* ip1,struct inode* ip2,struct buf *b1,struct buf *b2,int b1Index,int b2Index,uint* a, uint* b)
{
8010159d:	55                   	push   %ebp
8010159e:	89 e5                	mov    %esp,%ebp
801015a0:	83 ec 28             	sub    $0x28,%esp
  if(!a)
801015a3:	83 7d 20 00          	cmpl   $0x0,0x20(%ebp)
801015a7:	75 46                	jne    801015ef <deletedups+0x52>
  {
    if(!b)
801015a9:	83 7d 24 00          	cmpl   $0x0,0x24(%ebp)
801015ad:	75 1c                	jne    801015cb <deletedups+0x2e>
      ip1->addrs[b1Index] = ip2->addrs[b2Index];
801015af:	8b 45 0c             	mov    0xc(%ebp),%eax
801015b2:	8b 55 1c             	mov    0x1c(%ebp),%edx
801015b5:	83 c2 04             	add    $0x4,%edx
801015b8:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801015bc:	8b 45 08             	mov    0x8(%ebp),%eax
801015bf:	8b 4d 18             	mov    0x18(%ebp),%ecx
801015c2:	83 c1 04             	add    $0x4,%ecx
801015c5:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
801015c9:	eb 18                	jmp    801015e3 <deletedups+0x46>
    else
      ip1->addrs[b1Index] = b[b2Index];
801015cb:	8b 45 1c             	mov    0x1c(%ebp),%eax
801015ce:	c1 e0 02             	shl    $0x2,%eax
801015d1:	03 45 24             	add    0x24(%ebp),%eax
801015d4:	8b 10                	mov    (%eax),%edx
801015d6:	8b 45 08             	mov    0x8(%ebp),%eax
801015d9:	8b 4d 18             	mov    0x18(%ebp),%ecx
801015dc:	83 c1 04             	add    $0x4,%ecx
801015df:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    directChanged = 1;
801015e3:	c7 05 80 ee 10 80 01 	movl   $0x1,0x8010ee80
801015ea:	00 00 00 
801015ed:	eb 40                	jmp    8010162f <deletedups+0x92>
  }
  else
  {
    if(!b)
801015ef:	83 7d 24 00          	cmpl   $0x0,0x24(%ebp)
801015f3:	75 1a                	jne    8010160f <deletedups+0x72>
      a[b1Index] = ip2->addrs[b2Index];
801015f5:	8b 45 18             	mov    0x18(%ebp),%eax
801015f8:	c1 e0 02             	shl    $0x2,%eax
801015fb:	03 45 20             	add    0x20(%ebp),%eax
801015fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101601:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
80101604:	83 c1 04             	add    $0x4,%ecx
80101607:	8b 54 8a 0c          	mov    0xc(%edx,%ecx,4),%edx
8010160b:	89 10                	mov    %edx,(%eax)
8010160d:	eb 16                	jmp    80101625 <deletedups+0x88>
    else
      a[b1Index] = b[b2Index];
8010160f:	8b 45 18             	mov    0x18(%ebp),%eax
80101612:	c1 e0 02             	shl    $0x2,%eax
80101615:	03 45 20             	add    0x20(%ebp),%eax
80101618:	8b 55 1c             	mov    0x1c(%ebp),%edx
8010161b:	c1 e2 02             	shl    $0x2,%edx
8010161e:	03 55 24             	add    0x24(%ebp),%edx
80101621:	8b 12                	mov    (%edx),%edx
80101623:	89 10                	mov    %edx,(%eax)
    indirectChanged = 1;
80101625:	c7 05 90 f8 10 80 01 	movl   $0x1,0x8010f890
8010162c:	00 00 00 
  }
  updateBlkRef(b2->sector,1);
8010162f:	8b 45 14             	mov    0x14(%ebp),%eax
80101632:	8b 40 08             	mov    0x8(%eax),%eax
80101635:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010163c:	00 
8010163d:	89 04 24             	mov    %eax,(%esp)
80101640:	e8 0e 1d 00 00       	call   80103353 <updateBlkRef>
  int ref = getBlkRef(b1->sector);
80101645:	8b 45 10             	mov    0x10(%ebp),%eax
80101648:	8b 40 08             	mov    0x8(%eax),%eax
8010164b:	89 04 24             	mov    %eax,(%esp)
8010164e:	e8 2f 1e 00 00       	call   80103482 <getBlkRef>
80101653:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(ref > 1)
80101656:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
8010165a:	7e 18                	jle    80101674 <deletedups+0xd7>
    updateBlkRef(b1->sector,-1);
8010165c:	8b 45 10             	mov    0x10(%ebp),%eax
8010165f:	8b 40 08             	mov    0x8(%eax),%eax
80101662:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80101669:	ff 
8010166a:	89 04 24             	mov    %eax,(%esp)
8010166d:	e8 e1 1c 00 00       	call   80103353 <updateBlkRef>
80101672:	eb 3e                	jmp    801016b2 <deletedups+0x115>
  else if(ref == 1)
80101674:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101678:	75 38                	jne    801016b2 <deletedups+0x115>
  {
    updateBlkRef(b1->sector,-1);
8010167a:	8b 45 10             	mov    0x10(%ebp),%eax
8010167d:	8b 40 08             	mov    0x8(%eax),%eax
80101680:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80101687:	ff 
80101688:	89 04 24             	mov    %eax,(%esp)
8010168b:	e8 c3 1c 00 00       	call   80103353 <updateBlkRef>
    begin_trans();
80101690:	e8 3c 2c 00 00       	call   801042d1 <begin_trans>
    bfree(b1->dev, b1->sector);
80101695:	8b 45 10             	mov    0x10(%ebp),%eax
80101698:	8b 50 08             	mov    0x8(%eax),%edx
8010169b:	8b 45 10             	mov    0x10(%ebp),%eax
8010169e:	8b 40 04             	mov    0x4(%eax),%eax
801016a1:	89 54 24 04          	mov    %edx,0x4(%esp)
801016a5:	89 04 24             	mov    %eax,(%esp)
801016a8:	e8 cd 0b 00 00       	call   8010227a <bfree>
    commit_trans();
801016ad:	e8 68 2c 00 00       	call   8010431a <commit_trans>
  }
}
801016b2:	c9                   	leave  
801016b3:	c3                   	ret    

801016b4 <dedup>:

int
dedup(void)
{
801016b4:	55                   	push   %ebp
801016b5:	89 e5                	mov    %esp,%ebp
801016b7:	81 ec 88 00 00 00    	sub    $0x88,%esp
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0;
801016bd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
801016c4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
801016cb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016d2:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
801016d9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  struct inode* ip1=0, *ip2=0;
801016e0:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
801016e7:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
801016ee:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
801016f5:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
801016fc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
80101703:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  uint *a = 0, *b = 0;
8010170a:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
80101711:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  struct superblock sb;
  readsb(1, &sb);
80101718:	8d 45 98             	lea    -0x68(%ebp),%eax
8010171b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010171f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101726:	e8 49 09 00 00       	call   80102074 <readsb>
  ninodes = sb.ninodes;
8010172b:	8b 45 a0             	mov    -0x60(%ebp),%eax
8010172e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  zeroNextInum();
80101731:	e8 be 1d 00 00       	call   801034f4 <zeroNextInum>
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101736:	e9 bd 07 00 00       	jmp    80101ef8 <dedup+0x844>
  {  //cprintf("in first while ip1->inum = %d\n",ip1->inum);
    indirects1=0;
8010173b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
    directChanged = 0;
80101742:	c7 05 80 ee 10 80 00 	movl   $0x0,0x8010ee80
80101749:	00 00 00 
    indirectChanged = 0;
8010174c:	c7 05 90 f8 10 80 00 	movl   $0x0,0x8010f890
80101753:	00 00 00 
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
80101756:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101759:	89 04 24             	mov    %eax,(%esp)
8010175c:	e8 a7 0e 00 00       	call   80102608 <ilock>
    if(ip1->addrs[NDIRECT])
80101761:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101764:	8b 40 4c             	mov    0x4c(%eax),%eax
80101767:	85 c0                	test   %eax,%eax
80101769:	74 2a                	je     80101795 <dedup+0xe1>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
8010176b:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010176e:	8b 50 4c             	mov    0x4c(%eax),%edx
80101771:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101774:	8b 00                	mov    (%eax),%eax
80101776:	89 54 24 04          	mov    %edx,0x4(%esp)
8010177a:	89 04 24             	mov    %eax,(%esp)
8010177d:	e8 24 ea ff ff       	call   801001a6 <bread>
80101782:	89 45 dc             	mov    %eax,-0x24(%ebp)
      a = (uint*)bp1->data;
80101785:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101788:	83 c0 18             	add    $0x18,%eax
8010178b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
      indirects1 = NINDIRECT;
8010178e:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101795:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010179c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
801017a3:	e9 ef 06 00 00       	jmp    80101e97 <dedup+0x7e3>
    {//cprintf("in first for blockIndex1 = %d\n",blockIndex1);
      if(blockIndex1<NDIRECT)							// in the same file
801017a8:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801017ac:	0f 8f 5d 02 00 00    	jg     80101a0f <dedup+0x35b>
      {
	if(ip1->addrs[blockIndex1])
801017b2:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017b8:	83 c2 04             	add    $0x4,%edx
801017bb:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017bf:	85 c0                	test   %eax,%eax
801017c1:	0f 84 3c 02 00 00    	je     80101a03 <dedup+0x34f>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
801017c7:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017cd:	83 c2 04             	add    $0x4,%edx
801017d0:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017d4:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017d7:	8b 00                	mov    (%eax),%eax
801017d9:	89 54 24 04          	mov    %edx,0x4(%esp)
801017dd:	89 04 24             	mov    %eax,(%esp)
801017e0:	e8 c1 e9 ff ff       	call   801001a6 <bread>
801017e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801017e8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017eb:	83 c0 0b             	add    $0xb,%eax
801017ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
801017f1:	e9 fc 01 00 00       	jmp    801019f2 <dedup+0x33e>
	  {
	    if(blockIndex2 < NDIRECT)
801017f6:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
801017fa:	0f 8f f3 00 00 00    	jg     801018f3 <dedup+0x23f>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2] && ip1->addrs[blockIndex1] != ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
80101800:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101803:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101806:	83 c2 04             	add    $0x4,%edx
80101809:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010180d:	85 c0                	test   %eax,%eax
8010180f:	0f 84 d9 01 00 00    	je     801019ee <dedup+0x33a>
80101815:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101818:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010181b:	83 c2 04             	add    $0x4,%edx
8010181e:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101822:	85 c0                	test   %eax,%eax
80101824:	0f 84 c4 01 00 00    	je     801019ee <dedup+0x33a>
8010182a:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010182d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101830:	83 c2 04             	add    $0x4,%edx
80101833:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101837:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010183a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010183d:	83 c1 04             	add    $0x4,%ecx
80101840:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101844:	39 c2                	cmp    %eax,%edx
80101846:	0f 84 a2 01 00 00    	je     801019ee <dedup+0x33a>
	      {//cprintf("in 2nd for if\n");
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
8010184c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010184f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101852:	83 c2 04             	add    $0x4,%edx
80101855:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101859:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010185c:	8b 00                	mov    (%eax),%eax
8010185e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101862:	89 04 24             	mov    %eax,(%esp)
80101865:	e8 3c e9 ff ff       	call   801001a6 <bread>
8010186a:	89 45 b8             	mov    %eax,-0x48(%ebp)
		//cprintf("before blkcmp 1\n");
		if(blkcmp(b1,b2))
8010186d:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101870:	89 44 24 04          	mov    %eax,0x4(%esp)
80101874:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101877:	89 04 24             	mov    %eax,(%esp)
8010187a:	e8 d6 fc ff ff       	call   80101555 <blkcmp>
8010187f:	85 c0                	test   %eax,%eax
80101881:	74 60                	je     801018e3 <dedup+0x22f>
		{//cprintf("after blkcmp\n");
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
80101883:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
8010188a:	00 
8010188b:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101892:	00 
80101893:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101896:	89 44 24 14          	mov    %eax,0x14(%esp)
8010189a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010189d:	89 44 24 10          	mov    %eax,0x10(%esp)
801018a1:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
801018a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801018ab:	89 44 24 08          	mov    %eax,0x8(%esp)
801018af:	8b 45 c0             	mov    -0x40(%ebp),%eax
801018b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801018b6:	8b 45 c0             	mov    -0x40(%ebp),%eax
801018b9:	89 04 24             	mov    %eax,(%esp)
801018bc:	e8 dc fc ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
801018c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801018c4:	89 04 24             	mov    %eax,(%esp)
801018c7:	e8 4b e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801018cc:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018cf:	89 04 24             	mov    %eax,(%esp)
801018d2:	e8 40 e9 ff ff       	call   80100217 <brelse>
		  found = 1;
801018d7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801018de:	e9 7c 02 00 00       	jmp    80101b5f <dedup+0x4ab>
		}
		brelse(b2);
801018e3:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018e6:	89 04 24             	mov    %eax,(%esp)
801018e9:	e8 29 e9 ff ff       	call   80100217 <brelse>
801018ee:	e9 fb 00 00 00       	jmp    801019ee <dedup+0x33a>
	      }
	    }
	    else if(a)
801018f3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801018f7:	0f 84 f1 00 00 00    	je     801019ee <dedup+0x33a>
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
801018fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101900:	83 e8 0c             	sub    $0xc,%eax
80101903:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset] && ip1->addrs[blockIndex1] != a[blockIndex2Offset])
80101906:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101909:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010190c:	83 c2 04             	add    $0x4,%edx
8010190f:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101913:	85 c0                	test   %eax,%eax
80101915:	0f 84 d3 00 00 00    	je     801019ee <dedup+0x33a>
8010191b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010191e:	c1 e0 02             	shl    $0x2,%eax
80101921:	03 45 d4             	add    -0x2c(%ebp),%eax
80101924:	8b 00                	mov    (%eax),%eax
80101926:	85 c0                	test   %eax,%eax
80101928:	0f 84 c0 00 00 00    	je     801019ee <dedup+0x33a>
8010192e:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101931:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101934:	83 c2 04             	add    $0x4,%edx
80101937:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010193b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010193e:	c1 e0 02             	shl    $0x2,%eax
80101941:	03 45 d4             	add    -0x2c(%ebp),%eax
80101944:	8b 00                	mov    (%eax),%eax
80101946:	39 c2                	cmp    %eax,%edx
80101948:	0f 84 a0 00 00 00    	je     801019ee <dedup+0x33a>
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);//cprintf("before blkcmp 2\n");
8010194e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101951:	c1 e0 02             	shl    $0x2,%eax
80101954:	03 45 d4             	add    -0x2c(%ebp),%eax
80101957:	8b 10                	mov    (%eax),%edx
80101959:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010195c:	8b 00                	mov    (%eax),%eax
8010195e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101962:	89 04 24             	mov    %eax,(%esp)
80101965:	e8 3c e8 ff ff       	call   801001a6 <bread>
8010196a:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
8010196d:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101970:	89 44 24 04          	mov    %eax,0x4(%esp)
80101974:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101977:	89 04 24             	mov    %eax,(%esp)
8010197a:	e8 d6 fb ff ff       	call   80101555 <blkcmp>
8010197f:	85 c0                	test   %eax,%eax
80101981:	74 60                	je     801019e3 <dedup+0x32f>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
80101983:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101986:	89 44 24 1c          	mov    %eax,0x1c(%esp)
8010198a:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101991:	00 
80101992:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101995:	89 44 24 14          	mov    %eax,0x14(%esp)
80101999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010199c:	89 44 24 10          	mov    %eax,0x10(%esp)
801019a0:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
801019a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801019aa:	89 44 24 08          	mov    %eax,0x8(%esp)
801019ae:	8b 45 c0             	mov    -0x40(%ebp),%eax
801019b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801019b5:	8b 45 c0             	mov    -0x40(%ebp),%eax
801019b8:	89 04 24             	mov    %eax,(%esp)
801019bb:	e8 dd fb ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
801019c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801019c3:	89 04 24             	mov    %eax,(%esp)
801019c6:	e8 4c e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801019cb:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019ce:	89 04 24             	mov    %eax,(%esp)
801019d1:	e8 41 e8 ff ff       	call   80100217 <brelse>
		  found = 1;
801019d6:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801019dd:	90                   	nop
801019de:	e9 7c 01 00 00       	jmp    80101b5f <dedup+0x4ab>
		}
		brelse(b2);
801019e3:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019e6:	89 04 24             	mov    %eax,(%esp)
801019e9:	e8 29 e8 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801019ee:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
801019f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801019f8:	0f 8f f8 fd ff ff    	jg     801017f6 <dedup+0x142>
801019fe:	e9 5c 01 00 00       	jmp    80101b5f <dedup+0x4ab>
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{//cprintf("in 2nd else\n");
	  //brelse(b1);
	  b1 = 0;
80101a03:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	  continue;
80101a0a:	e9 7d 04 00 00       	jmp    80101e8c <dedup+0x7d8>
// 	      brelse(b2);
// 	    }
// 	  } // for blockindex2 < NINDIRECT in ip1
// 	} //if not found match, check INDIRECT
//       } // if blockindex1 is < NDIRECT
      else if(!found)					// in the same file
80101a0f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101a13:	0f 85 46 01 00 00    	jne    80101b5f <dedup+0x4ab>
      {
	if(a)
80101a19:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101a1d:	0f 84 3c 01 00 00    	je     80101b5f <dedup+0x4ab>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
80101a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a26:	83 e8 0c             	sub    $0xc,%eax
80101a29:	89 45 b0             	mov    %eax,-0x50(%ebp)
	  if(a[blockIndex1Offset])
80101a2c:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a2f:	c1 e0 02             	shl    $0x2,%eax
80101a32:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a35:	8b 00                	mov    (%eax),%eax
80101a37:	85 c0                	test   %eax,%eax
80101a39:	0f 84 14 01 00 00    	je     80101b53 <dedup+0x49f>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
80101a3f:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a42:	c1 e0 02             	shl    $0x2,%eax
80101a45:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a48:	8b 10                	mov    (%eax),%edx
80101a4a:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101a4d:	8b 00                	mov    (%eax),%eax
80101a4f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a53:	89 04 24             	mov    %eax,(%esp)
80101a56:	e8 4b e7 ff ff       	call   801001a6 <bread>
80101a5b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101a5e:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
80101a65:	e9 db 00 00 00       	jmp    80101b45 <dedup+0x491>
	    {
	      if(a[blockIndex2] && a[blockIndex2] != a[blockIndex1Offset])
80101a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a6d:	c1 e0 02             	shl    $0x2,%eax
80101a70:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a73:	8b 00                	mov    (%eax),%eax
80101a75:	85 c0                	test   %eax,%eax
80101a77:	0f 84 c4 00 00 00    	je     80101b41 <dedup+0x48d>
80101a7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a80:	c1 e0 02             	shl    $0x2,%eax
80101a83:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a86:	8b 10                	mov    (%eax),%edx
80101a88:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a8b:	c1 e0 02             	shl    $0x2,%eax
80101a8e:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a91:	8b 00                	mov    (%eax),%eax
80101a93:	39 c2                	cmp    %eax,%edx
80101a95:	0f 84 a6 00 00 00    	je     80101b41 <dedup+0x48d>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);//cprintf("before blkcmp 3\n");
80101a9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a9e:	c1 e0 02             	shl    $0x2,%eax
80101aa1:	03 45 d4             	add    -0x2c(%ebp),%eax
80101aa4:	8b 10                	mov    (%eax),%edx
80101aa6:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101aa9:	8b 00                	mov    (%eax),%eax
80101aab:	89 54 24 04          	mov    %edx,0x4(%esp)
80101aaf:	89 04 24             	mov    %eax,(%esp)
80101ab2:	e8 ef e6 ff ff       	call   801001a6 <bread>
80101ab7:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101aba:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101abd:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ac1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101ac4:	89 04 24             	mov    %eax,(%esp)
80101ac7:	e8 89 fa ff ff       	call   80101555 <blkcmp>
80101acc:	85 c0                	test   %eax,%eax
80101ace:	74 66                	je     80101b36 <dedup+0x482>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101ad0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101ad3:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101ad7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101ada:	89 44 24 18          	mov    %eax,0x18(%esp)
80101ade:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ae1:	89 44 24 14          	mov    %eax,0x14(%esp)
80101ae5:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101ae8:	89 44 24 10          	mov    %eax,0x10(%esp)
80101aec:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101aef:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101af3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101af6:	89 44 24 08          	mov    %eax,0x8(%esp)
80101afa:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101afd:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b01:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101b04:	89 04 24             	mov    %eax,(%esp)
80101b07:	e8 91 fa ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101b0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101b0f:	89 04 24             	mov    %eax,(%esp)
80101b12:	e8 00 e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101b17:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b1a:	89 04 24             	mov    %eax,(%esp)
80101b1d:	e8 f5 e6 ff ff       	call   80100217 <brelse>
		  found = 1;
80101b22:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  indirectChanged = 1;
80101b29:	c7 05 90 f8 10 80 01 	movl   $0x1,0x8010f890
80101b30:	00 00 00 
		  break;
80101b33:	90                   	nop
80101b34:	eb 29                	jmp    80101b5f <dedup+0x4ab>
		}
		brelse(b2);
80101b36:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b39:	89 04 24             	mov    %eax,(%esp)
80101b3c:	e8 d6 e6 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101b41:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101b45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b48:	3b 45 b0             	cmp    -0x50(%ebp),%eax
80101b4b:	0f 8f 19 ff ff ff    	jg     80101a6a <dedup+0x3b6>
80101b51:	eb 0c                	jmp    80101b5f <dedup+0x4ab>
	      }
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    b1 = 0;
80101b53:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	    continue;
80101b5a:	e9 2d 03 00 00       	jmp    80101e8c <dedup+0x7d8>
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101b5f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101b63:	0f 85 12 03 00 00    	jne    80101e7b <dedup+0x7c7>
80101b69:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b6d:	0f 84 08 03 00 00    	je     80101e7b <dedup+0x7c7>
      {
	uint* aSub = 0;
80101b73:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	int blockIndex1Offset = blockIndex1;
80101b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b7d:	89 45 c8             	mov    %eax,-0x38(%ebp)
	if(blockIndex1 >= NDIRECT)
80101b80:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101b84:	7e 0f                	jle    80101b95 <dedup+0x4e1>
	{
	  aSub = a;
80101b86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101b89:	89 45 cc             	mov    %eax,-0x34(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b8f:	83 e8 0c             	sub    $0xc,%eax
80101b92:	89 45 c8             	mov    %eax,-0x38(%ebp)
	}
	prevInum = ninodes-1;
80101b95:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101b98:	83 e8 01             	sub    $0x1,%eax
80101b9b:	89 45 a8             	mov    %eax,-0x58(%ebp)
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101b9e:	e9 ba 02 00 00       	jmp    80101e5d <dedup+0x7a9>
	{//cprintf("ip2->inum = %d\n",ip2->inum);
	  indirects2=0;
80101ba3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	  ilock(ip2);
80101baa:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bad:	89 04 24             	mov    %eax,(%esp)
80101bb0:	e8 53 0a 00 00       	call   80102608 <ilock>
	  if(ip2->addrs[NDIRECT])
80101bb5:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bb8:	8b 40 4c             	mov    0x4c(%eax),%eax
80101bbb:	85 c0                	test   %eax,%eax
80101bbd:	74 2a                	je     80101be9 <dedup+0x535>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101bbf:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bc2:	8b 50 4c             	mov    0x4c(%eax),%edx
80101bc5:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bc8:	8b 00                	mov    (%eax),%eax
80101bca:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bce:	89 04 24             	mov    %eax,(%esp)
80101bd1:	e8 d0 e5 ff ff       	call   801001a6 <bread>
80101bd6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	    b = (uint*)bp2->data;
80101bd9:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101bdc:	83 c0 18             	add    $0x18,%eax
80101bdf:	89 45 d0             	mov    %eax,-0x30(%ebp)
	    indirects2 = NINDIRECT;
80101be2:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  //cprintf("before 1st for\n");
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101be9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101bec:	83 c0 0b             	add    $0xb,%eax
80101bef:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101bf2:	e9 3c 02 00 00       	jmp    80101e33 <dedup+0x77f>
	  {
	    if(blockIndex2<NDIRECT)
80101bf7:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101bfb:	0f 8f 03 01 00 00    	jg     80101d04 <dedup+0x650>
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
80101c01:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101c05:	74 20                	je     80101c27 <dedup+0x573>
80101c07:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c0a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c0d:	83 c2 04             	add    $0x4,%edx
80101c10:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c14:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c17:	c1 e0 02             	shl    $0x2,%eax
80101c1a:	03 45 cc             	add    -0x34(%ebp),%eax
80101c1d:	8b 00                	mov    (%eax),%eax
80101c1f:	39 c2                	cmp    %eax,%edx
80101c21:	0f 84 04 02 00 00    	je     80101e2b <dedup+0x777>
80101c27:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c2a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c2d:	83 c2 04             	add    $0x4,%edx
80101c30:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c34:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101c37:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101c3a:	83 c1 04             	add    $0x4,%ecx
80101c3d:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101c41:	39 c2                	cmp    %eax,%edx
80101c43:	0f 84 e2 01 00 00    	je     80101e2b <dedup+0x777>
		continue;
	      if(ip2->addrs[blockIndex2])
80101c49:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c4c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c4f:	83 c2 04             	add    $0x4,%edx
80101c52:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c56:	85 c0                	test   %eax,%eax
80101c58:	0f 84 d1 01 00 00    	je     80101e2f <dedup+0x77b>
	      {
		//if(blockIndex1==1)
		  //cprintf("direct ip2->addrs[blockIndex2] = %d, ip1->addrs[blockIndex1Offset] = %d\n",ip2->addrs[blockIndex2],ip1->addrs[blockIndex1Offset]);
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);//cprintf("before blkcmp 4\n");
80101c5e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c61:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c64:	83 c2 04             	add    $0x4,%edx
80101c67:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c6b:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c6e:	8b 00                	mov    (%eax),%eax
80101c70:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c74:	89 04 24             	mov    %eax,(%esp)
80101c77:	e8 2a e5 ff ff       	call   801001a6 <bread>
80101c7c:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101c7f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c82:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c86:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101c89:	89 04 24             	mov    %eax,(%esp)
80101c8c:	e8 c4 f8 ff ff       	call   80101555 <blkcmp>
80101c91:	85 c0                	test   %eax,%eax
80101c93:	74 5f                	je     80101cf4 <dedup+0x640>
		{
		  //cprintf("direct blockIndex2 = %d\n",blockIndex2);
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101c95:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101c9c:	00 
80101c9d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101ca0:	89 44 24 18          	mov    %eax,0x18(%esp)
80101ca4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca7:	89 44 24 14          	mov    %eax,0x14(%esp)
80101cab:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101cae:	89 44 24 10          	mov    %eax,0x10(%esp)
80101cb2:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cb5:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101cb9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101cbc:	89 44 24 08          	mov    %eax,0x8(%esp)
80101cc0:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101cc3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cc7:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101cca:	89 04 24             	mov    %eax,(%esp)
80101ccd:	e8 cb f8 ff ff       	call   8010159d <deletedups>
		  //cprintf("*****************before 1st brelse direct\n"); 
		  brelse(b1);				// release the outer loop block
80101cd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101cd5:	89 04 24             	mov    %eax,(%esp)
80101cd8:	e8 3a e5 ff ff       	call   80100217 <brelse>
		  //cprintf("*****************after 1st brelse b1 direct\n"); 
		  brelse(b2);
80101cdd:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ce0:	89 04 24             	mov    %eax,(%esp)
80101ce3:	e8 2f e5 ff ff       	call   80100217 <brelse>
		  //cprintf("*****************after 1st brelse b2 direct\n"); 
		  found = 1;
80101ce8:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101cef:	e9 49 01 00 00       	jmp    80101e3d <dedup+0x789>
		}//cprintf("before 1st brelse\n");
		brelse(b2);
80101cf4:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cf7:	89 04 24             	mov    %eax,(%esp)
80101cfa:	e8 18 e5 ff ff       	call   80100217 <brelse>
80101cff:	e9 2b 01 00 00       	jmp    80101e2f <dedup+0x77b>
		//cprintf("after 1st brelse\n");
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
80101d04:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80101d08:	0f 84 21 01 00 00    	je     80101e2f <dedup+0x77b>
	    {//cprintf("inside else if\n");
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
80101d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d11:	83 e8 0c             	sub    $0xc,%eax
80101d14:	89 45 ac             	mov    %eax,-0x54(%ebp)
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
80101d17:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101d1b:	74 1e                	je     80101d3b <dedup+0x687>
80101d1d:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d20:	c1 e0 02             	shl    $0x2,%eax
80101d23:	03 45 d0             	add    -0x30(%ebp),%eax
80101d26:	8b 10                	mov    (%eax),%edx
80101d28:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101d2b:	c1 e0 02             	shl    $0x2,%eax
80101d2e:	03 45 cc             	add    -0x34(%ebp),%eax
80101d31:	8b 00                	mov    (%eax),%eax
80101d33:	39 c2                	cmp    %eax,%edx
80101d35:	0f 84 f3 00 00 00    	je     80101e2e <dedup+0x77a>
80101d3b:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d3e:	c1 e0 02             	shl    $0x2,%eax
80101d41:	03 45 d0             	add    -0x30(%ebp),%eax
80101d44:	8b 10                	mov    (%eax),%edx
80101d46:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101d49:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101d4c:	83 c1 04             	add    $0x4,%ecx
80101d4f:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101d53:	39 c2                	cmp    %eax,%edx
80101d55:	0f 84 d3 00 00 00    	je     80101e2e <dedup+0x77a>
		continue;
	      if(b[blockIndex2Offset])
80101d5b:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d5e:	c1 e0 02             	shl    $0x2,%eax
80101d61:	03 45 d0             	add    -0x30(%ebp),%eax
80101d64:	8b 00                	mov    (%eax),%eax
80101d66:	85 c0                	test   %eax,%eax
80101d68:	0f 84 c1 00 00 00    	je     80101e2f <dedup+0x77b>
	      {
		//if(blockIndex1==1)
		  //cprintf("indirect b[blockIndex2Offset] = %d, ip, ip1->addrs[blockIndex1Offset] = %d\n",b[blockIndex2Offset],ip1->addrs[blockIndex1Offset]);
		b2 = bread(ip2->dev,b[blockIndex2Offset]);//cprintf("before blkcmp 5\n");
80101d6e:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d71:	c1 e0 02             	shl    $0x2,%eax
80101d74:	03 45 d0             	add    -0x30(%ebp),%eax
80101d77:	8b 10                	mov    (%eax),%edx
80101d79:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d7c:	8b 00                	mov    (%eax),%eax
80101d7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d82:	89 04 24             	mov    %eax,(%esp)
80101d85:	e8 1c e4 ff ff       	call   801001a6 <bread>
80101d8a:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101d8d:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d90:	89 44 24 04          	mov    %eax,0x4(%esp)
80101d94:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101d97:	89 04 24             	mov    %eax,(%esp)
80101d9a:	e8 b6 f7 ff ff       	call   80101555 <blkcmp>
80101d9f:	85 c0                	test   %eax,%eax
80101da1:	74 7b                	je     80101e1e <dedup+0x76a>
		{
		  cprintf("indirect b1->sector = %d, b2->sector = %d\n",b1->sector,b2->sector);
80101da3:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101da6:	8b 50 08             	mov    0x8(%eax),%edx
80101da9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101dac:	8b 40 08             	mov    0x8(%eax),%eax
80101daf:	89 54 24 08          	mov    %edx,0x8(%esp)
80101db3:	89 44 24 04          	mov    %eax,0x4(%esp)
80101db7:	c7 04 24 2c 95 10 80 	movl   $0x8010952c,(%esp)
80101dbe:	e8 de e5 ff ff       	call   801003a1 <cprintf>
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101dc3:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101dc6:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101dca:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101dcd:	89 44 24 18          	mov    %eax,0x18(%esp)
80101dd1:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101dd4:	89 44 24 14          	mov    %eax,0x14(%esp)
80101dd8:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101ddb:	89 44 24 10          	mov    %eax,0x10(%esp)
80101ddf:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101de2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101de6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101de9:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ded:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101df0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101df4:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101df7:	89 04 24             	mov    %eax,(%esp)
80101dfa:	e8 9e f7 ff ff       	call   8010159d <deletedups>
		  //cprintf("*****************before 2nd brelse indirect\n"); 
		  brelse(b1);				// release the outer loop block
80101dff:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101e02:	89 04 24             	mov    %eax,(%esp)
80101e05:	e8 0d e4 ff ff       	call   80100217 <brelse>
		  //cprintf("*****************after 2nd brelse indirect\n"); 
		  brelse(b2);
80101e0a:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101e0d:	89 04 24             	mov    %eax,(%esp)
80101e10:	e8 02 e4 ff ff       	call   80100217 <brelse>
		  //cprintf("*****************after 2nd brelse indirect\n"); 
		  found = 1;
80101e15:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101e1c:	eb 1f                	jmp    80101e3d <dedup+0x789>
		}//cprintf("before 2nd brelse\n");
		brelse(b2);
80101e1e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101e21:	89 04 24             	mov    %eax,(%esp)
80101e24:	e8 ee e3 ff ff       	call   80100217 <brelse>
80101e29:	eb 04                	jmp    80101e2f <dedup+0x77b>
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
	  {
	    if(blockIndex2<NDIRECT)
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
		continue;
80101e2b:	90                   	nop
80101e2c:	eb 01                	jmp    80101e2f <dedup+0x77b>
	    else if(b)
	    {//cprintf("inside else if\n");
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
		continue;
80101e2e:	90                   	nop
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  //cprintf("before 1st for\n");
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101e2f:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101e33:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e37:	0f 89 ba fd ff ff    	jns    80101bf7 <dedup+0x543>
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
80101e3d:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e40:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e43:	85 c0                	test   %eax,%eax
80101e45:	74 0b                	je     80101e52 <dedup+0x79e>
	  {
	    //cprintf("before bp2 brelse\n");
	    brelse(bp2);
80101e47:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101e4a:	89 04 24             	mov    %eax,(%esp)
80101e4d:	e8 c5 e3 ff ff       	call   80100217 <brelse>
	    //cprintf("after bp2 brelse\n"); 
	  }
	  
	  iunlockput(ip2);
80101e52:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e55:	89 04 24             	mov    %eax,(%esp)
80101e58:	e8 2f 0a 00 00       	call   8010288c <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101e5d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e61:	75 18                	jne    80101e7b <dedup+0x7c7>
80101e63:	8d 45 a8             	lea    -0x58(%ebp),%eax
80101e66:	89 04 24             	mov    %eax,(%esp)
80101e69:	e8 34 14 00 00       	call   801032a2 <getPrevInode>
80101e6e:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101e71:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101e75:	0f 85 28 fd ff ff    	jne    80101ba3 <dedup+0x4ef>
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
80101e7b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e7f:	75 0b                	jne    80101e8c <dedup+0x7d8>
      {
	//cprintf("*****************before 1st brelse\n"); 
	brelse(b1);				// release the outer loop block
80101e81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101e84:	89 04 24             	mov    %eax,(%esp)
80101e87:	e8 8b e3 ff ff       	call   80100217 <brelse>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101e8c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e90:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101e97:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e9a:	83 c0 0c             	add    $0xc,%eax
80101e9d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101ea0:	0f 8f 02 f9 ff ff    	jg     801017a8 <dedup+0xf4>
	brelse(b1);				// release the outer loop block
	//cprintf("*****************after 1st brelse\n"); 
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101ea6:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ea9:	8b 40 4c             	mov    0x4c(%eax),%eax
80101eac:	85 c0                	test   %eax,%eax
80101eae:	74 1f                	je     80101ecf <dedup+0x81b>
    {
      if(indirectChanged)
80101eb0:	a1 90 f8 10 80       	mov    0x8010f890,%eax
80101eb5:	85 c0                	test   %eax,%eax
80101eb7:	74 0b                	je     80101ec4 <dedup+0x810>
	bwrite(bp1);
80101eb9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101ebc:	89 04 24             	mov    %eax,(%esp)
80101ebf:	e8 19 e3 ff ff       	call   801001dd <bwrite>
      //cprintf("*****************before bp1 brelse\n"); 
      brelse(bp1);
80101ec4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101ec7:	89 04 24             	mov    %eax,(%esp)
80101eca:	e8 48 e3 ff ff       	call   80100217 <brelse>
      //cprintf("*****************after bp1 brelse\n");
    }
    
    if(directChanged)
80101ecf:	a1 80 ee 10 80       	mov    0x8010ee80,%eax
80101ed4:	85 c0                	test   %eax,%eax
80101ed6:	74 15                	je     80101eed <dedup+0x839>
    {
      begin_trans();
80101ed8:	e8 f4 23 00 00       	call   801042d1 <begin_trans>
      iupdate(ip1);
80101edd:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ee0:	89 04 24             	mov    %eax,(%esp)
80101ee3:	e8 64 05 00 00       	call   8010244c <iupdate>
      commit_trans();
80101ee8:	e8 2d 24 00 00       	call   8010431a <commit_trans>
    }
    iunlockput(ip1);
80101eed:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ef0:	89 04 24             	mov    %eax,(%esp)
80101ef3:	e8 94 09 00 00       	call   8010288c <iunlockput>
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  zeroNextInum();
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101ef8:	e8 f1 12 00 00       	call   801031ee <getNextInode>
80101efd:	89 45 c0             	mov    %eax,-0x40(%ebp)
80101f00:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
80101f04:	0f 85 31 f8 ff ff    	jne    8010173b <dedup+0x87>
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
80101f0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101f0f:	c9                   	leave  
80101f10:	c3                   	ret    

80101f11 <getSharedBlocksRate>:

int
getSharedBlocksRate(void)
{
80101f11:	55                   	push   %ebp
80101f12:	89 e5                	mov    %esp,%ebp
80101f14:	83 ec 48             	sub    $0x48,%esp
  int i;
  uchar saved = 0,total = 0;
80101f17:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
80101f1b:	c6 45 f2 00          	movb   $0x0,-0xe(%ebp)
  
  struct buf* bp1 = bread(1,1024);
80101f1f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80101f26:	00 
80101f27:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f2e:	e8 73 e2 ff ff       	call   801001a6 <bread>
80101f33:	89 45 ec             	mov    %eax,-0x14(%ebp)
  struct buf* bp2 = bread(1,1025);
80101f36:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80101f3d:	00 
80101f3e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f45:	e8 5c e2 ff ff       	call   801001a6 <bread>
80101f4a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  
  for(i=0;i<BSIZE;i++)
80101f4d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f54:	e9 a0 00 00 00       	jmp    80101ff9 <getSharedBlocksRate+0xe8>
  {
    if(bp1->data[i] > 1)
80101f59:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f5c:	03 45 f4             	add    -0xc(%ebp),%eax
80101f5f:	83 c0 10             	add    $0x10,%eax
80101f62:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f66:	3c 01                	cmp    $0x1,%al
80101f68:	76 28                	jbe    80101f92 <getSharedBlocksRate+0x81>
    {
      saved += bp1->data[i]-1;
80101f6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f6d:	03 45 f4             	add    -0xc(%ebp),%eax
80101f70:	83 c0 10             	add    $0x10,%eax
80101f73:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f77:	02 45 f3             	add    -0xd(%ebp),%al
80101f7a:	83 e8 01             	sub    $0x1,%eax
80101f7d:	88 45 f3             	mov    %al,-0xd(%ebp)
      total += bp1->data[i];
80101f80:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f83:	03 45 f4             	add    -0xc(%ebp),%eax
80101f86:	83 c0 10             	add    $0x10,%eax
80101f89:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f8d:	00 45 f2             	add    %al,-0xe(%ebp)
80101f90:	eb 15                	jmp    80101fa7 <getSharedBlocksRate+0x96>
    }
    else if(bp1->data[i] == 1)
80101f92:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f95:	03 45 f4             	add    -0xc(%ebp),%eax
80101f98:	83 c0 10             	add    $0x10,%eax
80101f9b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f9f:	3c 01                	cmp    $0x1,%al
80101fa1:	75 04                	jne    80101fa7 <getSharedBlocksRate+0x96>
      total=total+1;
80101fa3:	80 45 f2 01          	addb   $0x1,-0xe(%ebp)
    
    if(bp2->data[i] > 1)
80101fa7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101faa:	03 45 f4             	add    -0xc(%ebp),%eax
80101fad:	83 c0 10             	add    $0x10,%eax
80101fb0:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fb4:	3c 01                	cmp    $0x1,%al
80101fb6:	76 28                	jbe    80101fe0 <getSharedBlocksRate+0xcf>
    {
      saved += bp2->data[i]-1;
80101fb8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101fbb:	03 45 f4             	add    -0xc(%ebp),%eax
80101fbe:	83 c0 10             	add    $0x10,%eax
80101fc1:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fc5:	02 45 f3             	add    -0xd(%ebp),%al
80101fc8:	83 e8 01             	sub    $0x1,%eax
80101fcb:	88 45 f3             	mov    %al,-0xd(%ebp)
      total += bp2->data[i];
80101fce:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101fd1:	03 45 f4             	add    -0xc(%ebp),%eax
80101fd4:	83 c0 10             	add    $0x10,%eax
80101fd7:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fdb:	00 45 f2             	add    %al,-0xe(%ebp)
80101fde:	eb 15                	jmp    80101ff5 <getSharedBlocksRate+0xe4>
    }
    else if(bp2->data[i] == 1)
80101fe0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101fe3:	03 45 f4             	add    -0xc(%ebp),%eax
80101fe6:	83 c0 10             	add    $0x10,%eax
80101fe9:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fed:	3c 01                	cmp    $0x1,%al
80101fef:	75 04                	jne    80101ff5 <getSharedBlocksRate+0xe4>
      total=total+1;
80101ff1:	80 45 f2 01          	addb   $0x1,-0xe(%ebp)
  uchar saved = 0,total = 0;
  
  struct buf* bp1 = bread(1,1024);
  struct buf* bp2 = bread(1,1025);
  
  for(i=0;i<BSIZE;i++)
80101ff5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101ff9:	81 7d f4 ff 01 00 00 	cmpl   $0x1ff,-0xc(%ebp)
80102000:	0f 8e 53 ff ff ff    	jle    80101f59 <getSharedBlocksRate+0x48>
    }
    else if(bp2->data[i] == 1)
      total=total+1;
  }
  
  double res = saved/total;
80102006:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
8010200a:	0f b6 c0             	movzbl %al,%eax
8010200d:	f6 75 f2             	divb   -0xe(%ebp)
80102010:	0f b6 c0             	movzbl %al,%eax
80102013:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80102016:	db 45 d4             	fildl  -0x2c(%ebp)
80102019:	dd 5d e0             	fstpl  -0x20(%ebp)
  cprintf("saved = %d, total = %d\n",saved,total);
8010201c:	0f b6 55 f2          	movzbl -0xe(%ebp),%edx
80102020:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
80102024:	89 54 24 08          	mov    %edx,0x8(%esp)
80102028:	89 44 24 04          	mov    %eax,0x4(%esp)
8010202c:	c7 04 24 57 95 10 80 	movl   $0x80109557,(%esp)
80102033:	e8 69 e3 ff ff       	call   801003a1 <cprintf>
  int conv = res*1000;
80102038:	dd 45 e0             	fldl   -0x20(%ebp)
8010203b:	dd 05 90 95 10 80    	fldl   0x80109590
80102041:	de c9                	fmulp  %st,%st(1)
80102043:	d9 7d d2             	fnstcw -0x2e(%ebp)
80102046:	0f b7 45 d2          	movzwl -0x2e(%ebp),%eax
8010204a:	b4 0c                	mov    $0xc,%ah
8010204c:	66 89 45 d0          	mov    %ax,-0x30(%ebp)
80102050:	d9 6d d0             	fldcw  -0x30(%ebp)
80102053:	db 5d dc             	fistpl -0x24(%ebp)
80102056:	d9 6d d2             	fldcw  -0x2e(%ebp)
  cprintf("Shared block rate is: 0.%d\n",conv);
80102059:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010205c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102060:	c7 04 24 6f 95 10 80 	movl   $0x8010956f,(%esp)
80102067:	e8 35 e3 ff ff       	call   801003a1 <cprintf>
  
  return 0;
8010206c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102071:	c9                   	leave  
80102072:	c3                   	ret    
	...

80102074 <readsb>:
int prevInum = 0;

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80102074:	55                   	push   %ebp
80102075:	89 e5                	mov    %esp,%ebp
80102077:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010207a:	8b 45 08             	mov    0x8(%ebp),%eax
8010207d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102084:	00 
80102085:	89 04 24             	mov    %eax,(%esp)
80102088:	e8 19 e1 ff ff       	call   801001a6 <bread>
8010208d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80102090:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102093:	83 c0 18             	add    $0x18,%eax
80102096:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010209d:	00 
8010209e:	89 44 24 04          	mov    %eax,0x4(%esp)
801020a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801020a5:	89 04 24             	mov    %eax,(%esp)
801020a8:	e8 cc 3e 00 00       	call   80105f79 <memmove>
  brelse(bp);
801020ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020b0:	89 04 24             	mov    %eax,(%esp)
801020b3:	e8 5f e1 ff ff       	call   80100217 <brelse>
}
801020b8:	c9                   	leave  
801020b9:	c3                   	ret    

801020ba <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801020ba:	55                   	push   %ebp
801020bb:	89 e5                	mov    %esp,%ebp
801020bd:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801020c0:	8b 55 0c             	mov    0xc(%ebp),%edx
801020c3:	8b 45 08             	mov    0x8(%ebp),%eax
801020c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801020ca:	89 04 24             	mov    %eax,(%esp)
801020cd:	e8 d4 e0 ff ff       	call   801001a6 <bread>
801020d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801020d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020d8:	83 c0 18             	add    $0x18,%eax
801020db:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801020e2:	00 
801020e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801020ea:	00 
801020eb:	89 04 24             	mov    %eax,(%esp)
801020ee:	e8 b3 3d 00 00       	call   80105ea6 <memset>
  log_write(bp);
801020f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020f6:	89 04 24             	mov    %eax,(%esp)
801020f9:	e8 74 22 00 00       	call   80104372 <log_write>
  brelse(bp);
801020fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102101:	89 04 24             	mov    %eax,(%esp)
80102104:	e8 0e e1 ff ff       	call   80100217 <brelse>
}
80102109:	c9                   	leave  
8010210a:	c3                   	ret    

8010210b <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010210b:	55                   	push   %ebp
8010210c:	89 e5                	mov    %esp,%ebp
8010210e:	53                   	push   %ebx
8010210f:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80102112:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80102119:	8b 45 08             	mov    0x8(%ebp),%eax
8010211c:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010211f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102123:	89 04 24             	mov    %eax,(%esp)
80102126:	e8 49 ff ff ff       	call   80102074 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010212b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102132:	e9 29 01 00 00       	jmp    80102260 <balloc+0x155>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80102137:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010213a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80102140:	85 c0                	test   %eax,%eax
80102142:	0f 48 c2             	cmovs  %edx,%eax
80102145:	c1 f8 0c             	sar    $0xc,%eax
80102148:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010214b:	c1 ea 03             	shr    $0x3,%edx
8010214e:	01 d0                	add    %edx,%eax
80102150:	83 c0 03             	add    $0x3,%eax
80102153:	89 44 24 04          	mov    %eax,0x4(%esp)
80102157:	8b 45 08             	mov    0x8(%ebp),%eax
8010215a:	89 04 24             	mov    %eax,(%esp)
8010215d:	e8 44 e0 ff ff       	call   801001a6 <bread>
80102162:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102165:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010216c:	e9 bf 00 00 00       	jmp    80102230 <balloc+0x125>
      m = 1 << (bi % 8);
80102171:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102174:	89 c2                	mov    %eax,%edx
80102176:	c1 fa 1f             	sar    $0x1f,%edx
80102179:	c1 ea 1d             	shr    $0x1d,%edx
8010217c:	01 d0                	add    %edx,%eax
8010217e:	83 e0 07             	and    $0x7,%eax
80102181:	29 d0                	sub    %edx,%eax
80102183:	ba 01 00 00 00       	mov    $0x1,%edx
80102188:	89 d3                	mov    %edx,%ebx
8010218a:	89 c1                	mov    %eax,%ecx
8010218c:	d3 e3                	shl    %cl,%ebx
8010218e:	89 d8                	mov    %ebx,%eax
80102190:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80102193:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102196:	8d 50 07             	lea    0x7(%eax),%edx
80102199:	85 c0                	test   %eax,%eax
8010219b:	0f 48 c2             	cmovs  %edx,%eax
8010219e:	c1 f8 03             	sar    $0x3,%eax
801021a1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801021a4:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801021a9:	0f b6 c0             	movzbl %al,%eax
801021ac:	23 45 e8             	and    -0x18(%ebp),%eax
801021af:	85 c0                	test   %eax,%eax
801021b1:	75 79                	jne    8010222c <balloc+0x121>
        bp->data[bi/8] |= m;  // Mark block in use.
801021b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b6:	8d 50 07             	lea    0x7(%eax),%edx
801021b9:	85 c0                	test   %eax,%eax
801021bb:	0f 48 c2             	cmovs  %edx,%eax
801021be:	c1 f8 03             	sar    $0x3,%eax
801021c1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801021c4:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801021c9:	89 d1                	mov    %edx,%ecx
801021cb:	8b 55 e8             	mov    -0x18(%ebp),%edx
801021ce:	09 ca                	or     %ecx,%edx
801021d0:	89 d1                	mov    %edx,%ecx
801021d2:	8b 55 ec             	mov    -0x14(%ebp),%edx
801021d5:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
801021d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021dc:	89 04 24             	mov    %eax,(%esp)
801021df:	e8 8e 21 00 00       	call   80104372 <log_write>
        brelse(bp);
801021e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021e7:	89 04 24             	mov    %eax,(%esp)
801021ea:	e8 28 e0 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801021ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021f5:	01 c2                	add    %eax,%edx
801021f7:	8b 45 08             	mov    0x8(%ebp),%eax
801021fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801021fe:	89 04 24             	mov    %eax,(%esp)
80102201:	e8 b4 fe ff ff       	call   801020ba <bzero>
	updateBlkRef(b+bi,1);
80102206:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102209:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010220c:	01 d0                	add    %edx,%eax
8010220e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102215:	00 
80102216:	89 04 24             	mov    %eax,(%esp)
80102219:	e8 35 11 00 00       	call   80103353 <updateBlkRef>
        return b + bi;
8010221e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102221:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102224:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80102226:	83 c4 34             	add    $0x34,%esp
80102229:	5b                   	pop    %ebx
8010222a:	5d                   	pop    %ebp
8010222b:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010222c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102230:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80102237:	7f 15                	jg     8010224e <balloc+0x143>
80102239:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010223c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010223f:	01 d0                	add    %edx,%eax
80102241:	89 c2                	mov    %eax,%edx
80102243:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102246:	39 c2                	cmp    %eax,%edx
80102248:	0f 82 23 ff ff ff    	jb     80102171 <balloc+0x66>
        bzero(dev, b + bi);
	updateBlkRef(b+bi,1);
        return b + bi;
      }
    }
    brelse(bp);
8010224e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102251:	89 04 24             	mov    %eax,(%esp)
80102254:	e8 be df ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80102259:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102260:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102263:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102266:	39 c2                	cmp    %eax,%edx
80102268:	0f 82 c9 fe ff ff    	jb     80102137 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
8010226e:	c7 04 24 98 95 10 80 	movl   $0x80109598,(%esp)
80102275:	e8 c3 e2 ff ff       	call   8010053d <panic>

8010227a <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
8010227a:	55                   	push   %ebp
8010227b:	89 e5                	mov    %esp,%ebp
8010227d:	53                   	push   %ebx
8010227e:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80102281:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102284:	89 44 24 04          	mov    %eax,0x4(%esp)
80102288:	8b 45 08             	mov    0x8(%ebp),%eax
8010228b:	89 04 24             	mov    %eax,(%esp)
8010228e:	e8 e1 fd ff ff       	call   80102074 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80102293:	8b 45 0c             	mov    0xc(%ebp),%eax
80102296:	89 c2                	mov    %eax,%edx
80102298:	c1 ea 0c             	shr    $0xc,%edx
8010229b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010229e:	c1 e8 03             	shr    $0x3,%eax
801022a1:	01 d0                	add    %edx,%eax
801022a3:	8d 50 03             	lea    0x3(%eax),%edx
801022a6:	8b 45 08             	mov    0x8(%ebp),%eax
801022a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801022ad:	89 04 24             	mov    %eax,(%esp)
801022b0:	e8 f1 de ff ff       	call   801001a6 <bread>
801022b5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801022b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801022bb:	25 ff 0f 00 00       	and    $0xfff,%eax
801022c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801022c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022c6:	89 c2                	mov    %eax,%edx
801022c8:	c1 fa 1f             	sar    $0x1f,%edx
801022cb:	c1 ea 1d             	shr    $0x1d,%edx
801022ce:	01 d0                	add    %edx,%eax
801022d0:	83 e0 07             	and    $0x7,%eax
801022d3:	29 d0                	sub    %edx,%eax
801022d5:	ba 01 00 00 00       	mov    $0x1,%edx
801022da:	89 d3                	mov    %edx,%ebx
801022dc:	89 c1                	mov    %eax,%ecx
801022de:	d3 e3                	shl    %cl,%ebx
801022e0:	89 d8                	mov    %ebx,%eax
801022e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801022e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022e8:	8d 50 07             	lea    0x7(%eax),%edx
801022eb:	85 c0                	test   %eax,%eax
801022ed:	0f 48 c2             	cmovs  %edx,%eax
801022f0:	c1 f8 03             	sar    $0x3,%eax
801022f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022f6:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801022fb:	0f b6 c0             	movzbl %al,%eax
801022fe:	23 45 ec             	and    -0x14(%ebp),%eax
80102301:	85 c0                	test   %eax,%eax
80102303:	75 0c                	jne    80102311 <bfree+0x97>
    panic("freeing free block");
80102305:	c7 04 24 ae 95 10 80 	movl   $0x801095ae,(%esp)
8010230c:	e8 2c e2 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80102311:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102314:	8d 50 07             	lea    0x7(%eax),%edx
80102317:	85 c0                	test   %eax,%eax
80102319:	0f 48 c2             	cmovs  %edx,%eax
8010231c:	c1 f8 03             	sar    $0x3,%eax
8010231f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102322:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102327:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010232a:	f7 d1                	not    %ecx
8010232c:	21 ca                	and    %ecx,%edx
8010232e:	89 d1                	mov    %edx,%ecx
80102330:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102333:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80102337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233a:	89 04 24             	mov    %eax,(%esp)
8010233d:	e8 30 20 00 00       	call   80104372 <log_write>
  brelse(bp);
80102342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102345:	89 04 24             	mov    %eax,(%esp)
80102348:	e8 ca de ff ff       	call   80100217 <brelse>
}
8010234d:	83 c4 34             	add    $0x34,%esp
80102350:	5b                   	pop    %ebx
80102351:	5d                   	pop    %ebp
80102352:	c3                   	ret    

80102353 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80102353:	55                   	push   %ebp
80102354:	89 e5                	mov    %esp,%ebp
80102356:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80102359:	c7 44 24 04 c1 95 10 	movl   $0x801095c1,0x4(%esp)
80102360:	80 
80102361:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102368:	e8 c9 38 00 00       	call   80105c36 <initlock>
}
8010236d:	c9                   	leave  
8010236e:	c3                   	ret    

8010236f <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010236f:	55                   	push   %ebp
80102370:	89 e5                	mov    %esp,%ebp
80102372:	83 ec 48             	sub    $0x48,%esp
80102375:	8b 45 0c             	mov    0xc(%ebp),%eax
80102378:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
8010237c:	8b 45 08             	mov    0x8(%ebp),%eax
8010237f:	8d 55 dc             	lea    -0x24(%ebp),%edx
80102382:	89 54 24 04          	mov    %edx,0x4(%esp)
80102386:	89 04 24             	mov    %eax,(%esp)
80102389:	e8 e6 fc ff ff       	call   80102074 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010238e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102395:	e9 98 00 00 00       	jmp    80102432 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010239a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239d:	c1 e8 03             	shr    $0x3,%eax
801023a0:	83 c0 02             	add    $0x2,%eax
801023a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801023a7:	8b 45 08             	mov    0x8(%ebp),%eax
801023aa:	89 04 24             	mov    %eax,(%esp)
801023ad:	e8 f4 dd ff ff       	call   801001a6 <bread>
801023b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801023b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023b8:	8d 50 18             	lea    0x18(%eax),%edx
801023bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023be:	83 e0 07             	and    $0x7,%eax
801023c1:	c1 e0 06             	shl    $0x6,%eax
801023c4:	01 d0                	add    %edx,%eax
801023c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801023c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023cc:	0f b7 00             	movzwl (%eax),%eax
801023cf:	66 85 c0             	test   %ax,%ax
801023d2:	75 4f                	jne    80102423 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801023d4:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801023db:	00 
801023dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801023e3:	00 
801023e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023e7:	89 04 24             	mov    %eax,(%esp)
801023ea:	e8 b7 3a 00 00       	call   80105ea6 <memset>
      dip->type = type;
801023ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801023f2:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801023f6:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801023f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023fc:	89 04 24             	mov    %eax,(%esp)
801023ff:	e8 6e 1f 00 00       	call   80104372 <log_write>
      brelse(bp);
80102404:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102407:	89 04 24             	mov    %eax,(%esp)
8010240a:	e8 08 de ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
8010240f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102412:	89 44 24 04          	mov    %eax,0x4(%esp)
80102416:	8b 45 08             	mov    0x8(%ebp),%eax
80102419:	89 04 24             	mov    %eax,(%esp)
8010241c:	e8 e3 00 00 00       	call   80102504 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80102421:	c9                   	leave  
80102422:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80102423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102426:	89 04 24             	mov    %eax,(%esp)
80102429:	e8 e9 dd ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010242e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102432:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102435:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102438:	39 c2                	cmp    %eax,%edx
8010243a:	0f 82 5a ff ff ff    	jb     8010239a <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80102440:	c7 04 24 c8 95 10 80 	movl   $0x801095c8,(%esp)
80102447:	e8 f1 e0 ff ff       	call   8010053d <panic>

8010244c <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010244c:	55                   	push   %ebp
8010244d:	89 e5                	mov    %esp,%ebp
8010244f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80102452:	8b 45 08             	mov    0x8(%ebp),%eax
80102455:	8b 40 04             	mov    0x4(%eax),%eax
80102458:	c1 e8 03             	shr    $0x3,%eax
8010245b:	8d 50 02             	lea    0x2(%eax),%edx
8010245e:	8b 45 08             	mov    0x8(%ebp),%eax
80102461:	8b 00                	mov    (%eax),%eax
80102463:	89 54 24 04          	mov    %edx,0x4(%esp)
80102467:	89 04 24             	mov    %eax,(%esp)
8010246a:	e8 37 dd ff ff       	call   801001a6 <bread>
8010246f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80102472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102475:	8d 50 18             	lea    0x18(%eax),%edx
80102478:	8b 45 08             	mov    0x8(%ebp),%eax
8010247b:	8b 40 04             	mov    0x4(%eax),%eax
8010247e:	83 e0 07             	and    $0x7,%eax
80102481:	c1 e0 06             	shl    $0x6,%eax
80102484:	01 d0                	add    %edx,%eax
80102486:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80102489:	8b 45 08             	mov    0x8(%ebp),%eax
8010248c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102490:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102493:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80102496:	8b 45 08             	mov    0x8(%ebp),%eax
80102499:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010249d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024a0:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801024a4:	8b 45 08             	mov    0x8(%ebp),%eax
801024a7:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801024ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024ae:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801024b2:	8b 45 08             	mov    0x8(%ebp),%eax
801024b5:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801024b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024bc:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801024c0:	8b 45 08             	mov    0x8(%ebp),%eax
801024c3:	8b 50 18             	mov    0x18(%eax),%edx
801024c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024c9:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801024cc:	8b 45 08             	mov    0x8(%ebp),%eax
801024cf:	8d 50 1c             	lea    0x1c(%eax),%edx
801024d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024d5:	83 c0 0c             	add    $0xc,%eax
801024d8:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801024df:	00 
801024e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801024e4:	89 04 24             	mov    %eax,(%esp)
801024e7:	e8 8d 3a 00 00       	call   80105f79 <memmove>
  log_write(bp);
801024ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ef:	89 04 24             	mov    %eax,(%esp)
801024f2:	e8 7b 1e 00 00       	call   80104372 <log_write>
  brelse(bp);
801024f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024fa:	89 04 24             	mov    %eax,(%esp)
801024fd:	e8 15 dd ff ff       	call   80100217 <brelse>
}
80102502:	c9                   	leave  
80102503:	c3                   	ret    

80102504 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80102504:	55                   	push   %ebp
80102505:	89 e5                	mov    %esp,%ebp
80102507:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010250a:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102511:	e8 41 37 00 00       	call   80105c57 <acquire>

  // Is the inode already cached?
  empty = 0;
80102516:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010251d:	c7 45 f4 d4 f8 10 80 	movl   $0x8010f8d4,-0xc(%ebp)
80102524:	eb 59                	jmp    8010257f <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80102526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102529:	8b 40 08             	mov    0x8(%eax),%eax
8010252c:	85 c0                	test   %eax,%eax
8010252e:	7e 35                	jle    80102565 <iget+0x61>
80102530:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102533:	8b 00                	mov    (%eax),%eax
80102535:	3b 45 08             	cmp    0x8(%ebp),%eax
80102538:	75 2b                	jne    80102565 <iget+0x61>
8010253a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010253d:	8b 40 04             	mov    0x4(%eax),%eax
80102540:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102543:	75 20                	jne    80102565 <iget+0x61>
      ip->ref++;
80102545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102548:	8b 40 08             	mov    0x8(%eax),%eax
8010254b:	8d 50 01             	lea    0x1(%eax),%edx
8010254e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102551:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102554:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010255b:	e8 59 37 00 00       	call   80105cb9 <release>
      return ip;
80102560:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102563:	eb 6f                	jmp    801025d4 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102565:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102569:	75 10                	jne    8010257b <iget+0x77>
8010256b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010256e:	8b 40 08             	mov    0x8(%eax),%eax
80102571:	85 c0                	test   %eax,%eax
80102573:	75 06                	jne    8010257b <iget+0x77>
      empty = ip;
80102575:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102578:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010257b:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010257f:	81 7d f4 74 08 11 80 	cmpl   $0x80110874,-0xc(%ebp)
80102586:	72 9e                	jb     80102526 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80102588:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010258c:	75 0c                	jne    8010259a <iget+0x96>
    panic("iget: no inodes");
8010258e:	c7 04 24 da 95 10 80 	movl   $0x801095da,(%esp)
80102595:	e8 a3 df ff ff       	call   8010053d <panic>

  ip = empty;
8010259a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010259d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801025a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a3:	8b 55 08             	mov    0x8(%ebp),%edx
801025a6:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801025a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025ab:	8b 55 0c             	mov    0xc(%ebp),%edx
801025ae:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801025b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b4:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801025bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025be:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801025c5:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801025cc:	e8 e8 36 00 00       	call   80105cb9 <release>

  return ip;
801025d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801025d4:	c9                   	leave  
801025d5:	c3                   	ret    

801025d6 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801025d6:	55                   	push   %ebp
801025d7:	89 e5                	mov    %esp,%ebp
801025d9:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801025dc:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801025e3:	e8 6f 36 00 00       	call   80105c57 <acquire>
  ip->ref++;
801025e8:	8b 45 08             	mov    0x8(%ebp),%eax
801025eb:	8b 40 08             	mov    0x8(%eax),%eax
801025ee:	8d 50 01             	lea    0x1(%eax),%edx
801025f1:	8b 45 08             	mov    0x8(%ebp),%eax
801025f4:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801025f7:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801025fe:	e8 b6 36 00 00       	call   80105cb9 <release>
  return ip;
80102603:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102606:	c9                   	leave  
80102607:	c3                   	ret    

80102608 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80102608:	55                   	push   %ebp
80102609:	89 e5                	mov    %esp,%ebp
8010260b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
8010260e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102612:	74 0a                	je     8010261e <ilock+0x16>
80102614:	8b 45 08             	mov    0x8(%ebp),%eax
80102617:	8b 40 08             	mov    0x8(%eax),%eax
8010261a:	85 c0                	test   %eax,%eax
8010261c:	7f 0c                	jg     8010262a <ilock+0x22>
    panic("ilock");
8010261e:	c7 04 24 ea 95 10 80 	movl   $0x801095ea,(%esp)
80102625:	e8 13 df ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010262a:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102631:	e8 21 36 00 00       	call   80105c57 <acquire>
  while(ip->flags & I_BUSY)
80102636:	eb 13                	jmp    8010264b <ilock+0x43>
    sleep(ip, &icache.lock);
80102638:	c7 44 24 04 a0 f8 10 	movl   $0x8010f8a0,0x4(%esp)
8010263f:	80 
80102640:	8b 45 08             	mov    0x8(%ebp),%eax
80102643:	89 04 24             	mov    %eax,(%esp)
80102646:	e8 2e 33 00 00       	call   80105979 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010264b:	8b 45 08             	mov    0x8(%ebp),%eax
8010264e:	8b 40 0c             	mov    0xc(%eax),%eax
80102651:	83 e0 01             	and    $0x1,%eax
80102654:	84 c0                	test   %al,%al
80102656:	75 e0                	jne    80102638 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80102658:	8b 45 08             	mov    0x8(%ebp),%eax
8010265b:	8b 40 0c             	mov    0xc(%eax),%eax
8010265e:	89 c2                	mov    %eax,%edx
80102660:	83 ca 01             	or     $0x1,%edx
80102663:	8b 45 08             	mov    0x8(%ebp),%eax
80102666:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80102669:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102670:	e8 44 36 00 00       	call   80105cb9 <release>

  if(!(ip->flags & I_VALID)){
80102675:	8b 45 08             	mov    0x8(%ebp),%eax
80102678:	8b 40 0c             	mov    0xc(%eax),%eax
8010267b:	83 e0 02             	and    $0x2,%eax
8010267e:	85 c0                	test   %eax,%eax
80102680:	0f 85 ce 00 00 00    	jne    80102754 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80102686:	8b 45 08             	mov    0x8(%ebp),%eax
80102689:	8b 40 04             	mov    0x4(%eax),%eax
8010268c:	c1 e8 03             	shr    $0x3,%eax
8010268f:	8d 50 02             	lea    0x2(%eax),%edx
80102692:	8b 45 08             	mov    0x8(%ebp),%eax
80102695:	8b 00                	mov    (%eax),%eax
80102697:	89 54 24 04          	mov    %edx,0x4(%esp)
8010269b:	89 04 24             	mov    %eax,(%esp)
8010269e:	e8 03 db ff ff       	call   801001a6 <bread>
801026a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801026a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026a9:	8d 50 18             	lea    0x18(%eax),%edx
801026ac:	8b 45 08             	mov    0x8(%ebp),%eax
801026af:	8b 40 04             	mov    0x4(%eax),%eax
801026b2:	83 e0 07             	and    $0x7,%eax
801026b5:	c1 e0 06             	shl    $0x6,%eax
801026b8:	01 d0                	add    %edx,%eax
801026ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801026bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026c0:	0f b7 10             	movzwl (%eax),%edx
801026c3:	8b 45 08             	mov    0x8(%ebp),%eax
801026c6:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801026ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026cd:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801026d1:	8b 45 08             	mov    0x8(%ebp),%eax
801026d4:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801026d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026db:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801026df:	8b 45 08             	mov    0x8(%ebp),%eax
801026e2:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801026e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026e9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801026ed:	8b 45 08             	mov    0x8(%ebp),%eax
801026f0:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801026f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026f7:	8b 50 08             	mov    0x8(%eax),%edx
801026fa:	8b 45 08             	mov    0x8(%ebp),%eax
801026fd:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80102700:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102703:	8d 50 0c             	lea    0xc(%eax),%edx
80102706:	8b 45 08             	mov    0x8(%ebp),%eax
80102709:	83 c0 1c             	add    $0x1c,%eax
8010270c:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80102713:	00 
80102714:	89 54 24 04          	mov    %edx,0x4(%esp)
80102718:	89 04 24             	mov    %eax,(%esp)
8010271b:	e8 59 38 00 00       	call   80105f79 <memmove>
    brelse(bp);
80102720:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102723:	89 04 24             	mov    %eax,(%esp)
80102726:	e8 ec da ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010272b:	8b 45 08             	mov    0x8(%ebp),%eax
8010272e:	8b 40 0c             	mov    0xc(%eax),%eax
80102731:	89 c2                	mov    %eax,%edx
80102733:	83 ca 02             	or     $0x2,%edx
80102736:	8b 45 08             	mov    0x8(%ebp),%eax
80102739:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010273c:	8b 45 08             	mov    0x8(%ebp),%eax
8010273f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102743:	66 85 c0             	test   %ax,%ax
80102746:	75 0c                	jne    80102754 <ilock+0x14c>
      panic("ilock: no type");
80102748:	c7 04 24 f0 95 10 80 	movl   $0x801095f0,(%esp)
8010274f:	e8 e9 dd ff ff       	call   8010053d <panic>
  }
}
80102754:	c9                   	leave  
80102755:	c3                   	ret    

80102756 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80102756:	55                   	push   %ebp
80102757:	89 e5                	mov    %esp,%ebp
80102759:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
8010275c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102760:	74 17                	je     80102779 <iunlock+0x23>
80102762:	8b 45 08             	mov    0x8(%ebp),%eax
80102765:	8b 40 0c             	mov    0xc(%eax),%eax
80102768:	83 e0 01             	and    $0x1,%eax
8010276b:	85 c0                	test   %eax,%eax
8010276d:	74 0a                	je     80102779 <iunlock+0x23>
8010276f:	8b 45 08             	mov    0x8(%ebp),%eax
80102772:	8b 40 08             	mov    0x8(%eax),%eax
80102775:	85 c0                	test   %eax,%eax
80102777:	7f 0c                	jg     80102785 <iunlock+0x2f>
    panic("iunlock");
80102779:	c7 04 24 ff 95 10 80 	movl   $0x801095ff,(%esp)
80102780:	e8 b8 dd ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102785:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010278c:	e8 c6 34 00 00       	call   80105c57 <acquire>
  ip->flags &= ~I_BUSY;
80102791:	8b 45 08             	mov    0x8(%ebp),%eax
80102794:	8b 40 0c             	mov    0xc(%eax),%eax
80102797:	89 c2                	mov    %eax,%edx
80102799:	83 e2 fe             	and    $0xfffffffe,%edx
8010279c:	8b 45 08             	mov    0x8(%ebp),%eax
8010279f:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801027a2:	8b 45 08             	mov    0x8(%ebp),%eax
801027a5:	89 04 24             	mov    %eax,(%esp)
801027a8:	e8 a5 32 00 00       	call   80105a52 <wakeup>
  release(&icache.lock);
801027ad:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801027b4:	e8 00 35 00 00       	call   80105cb9 <release>
}
801027b9:	c9                   	leave  
801027ba:	c3                   	ret    

801027bb <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
801027bb:	55                   	push   %ebp
801027bc:	89 e5                	mov    %esp,%ebp
801027be:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801027c1:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801027c8:	e8 8a 34 00 00       	call   80105c57 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801027cd:	8b 45 08             	mov    0x8(%ebp),%eax
801027d0:	8b 40 08             	mov    0x8(%eax),%eax
801027d3:	83 f8 01             	cmp    $0x1,%eax
801027d6:	0f 85 93 00 00 00    	jne    8010286f <iput+0xb4>
801027dc:	8b 45 08             	mov    0x8(%ebp),%eax
801027df:	8b 40 0c             	mov    0xc(%eax),%eax
801027e2:	83 e0 02             	and    $0x2,%eax
801027e5:	85 c0                	test   %eax,%eax
801027e7:	0f 84 82 00 00 00    	je     8010286f <iput+0xb4>
801027ed:	8b 45 08             	mov    0x8(%ebp),%eax
801027f0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801027f4:	66 85 c0             	test   %ax,%ax
801027f7:	75 76                	jne    8010286f <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801027f9:	8b 45 08             	mov    0x8(%ebp),%eax
801027fc:	8b 40 0c             	mov    0xc(%eax),%eax
801027ff:	83 e0 01             	and    $0x1,%eax
80102802:	84 c0                	test   %al,%al
80102804:	74 0c                	je     80102812 <iput+0x57>
      panic("iput busy");
80102806:	c7 04 24 07 96 10 80 	movl   $0x80109607,(%esp)
8010280d:	e8 2b dd ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80102812:	8b 45 08             	mov    0x8(%ebp),%eax
80102815:	8b 40 0c             	mov    0xc(%eax),%eax
80102818:	89 c2                	mov    %eax,%edx
8010281a:	83 ca 01             	or     $0x1,%edx
8010281d:	8b 45 08             	mov    0x8(%ebp),%eax
80102820:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80102823:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010282a:	e8 8a 34 00 00       	call   80105cb9 <release>
    itrunc(ip);
8010282f:	8b 45 08             	mov    0x8(%ebp),%eax
80102832:	89 04 24             	mov    %eax,(%esp)
80102835:	e8 72 01 00 00       	call   801029ac <itrunc>
    ip->type = 0;
8010283a:	8b 45 08             	mov    0x8(%ebp),%eax
8010283d:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80102843:	8b 45 08             	mov    0x8(%ebp),%eax
80102846:	89 04 24             	mov    %eax,(%esp)
80102849:	e8 fe fb ff ff       	call   8010244c <iupdate>
    acquire(&icache.lock);
8010284e:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102855:	e8 fd 33 00 00       	call   80105c57 <acquire>
    ip->flags = 0;
8010285a:	8b 45 08             	mov    0x8(%ebp),%eax
8010285d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102864:	8b 45 08             	mov    0x8(%ebp),%eax
80102867:	89 04 24             	mov    %eax,(%esp)
8010286a:	e8 e3 31 00 00       	call   80105a52 <wakeup>
  }
  ip->ref--;
8010286f:	8b 45 08             	mov    0x8(%ebp),%eax
80102872:	8b 40 08             	mov    0x8(%eax),%eax
80102875:	8d 50 ff             	lea    -0x1(%eax),%edx
80102878:	8b 45 08             	mov    0x8(%ebp),%eax
8010287b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010287e:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102885:	e8 2f 34 00 00       	call   80105cb9 <release>
}
8010288a:	c9                   	leave  
8010288b:	c3                   	ret    

8010288c <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
8010288c:	55                   	push   %ebp
8010288d:	89 e5                	mov    %esp,%ebp
8010288f:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102892:	8b 45 08             	mov    0x8(%ebp),%eax
80102895:	89 04 24             	mov    %eax,(%esp)
80102898:	e8 b9 fe ff ff       	call   80102756 <iunlock>
  iput(ip);
8010289d:	8b 45 08             	mov    0x8(%ebp),%eax
801028a0:	89 04 24             	mov    %eax,(%esp)
801028a3:	e8 13 ff ff ff       	call   801027bb <iput>
}
801028a8:	c9                   	leave  
801028a9:	c3                   	ret    

801028aa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
801028aa:	55                   	push   %ebp
801028ab:	89 e5                	mov    %esp,%ebp
801028ad:	53                   	push   %ebx
801028ae:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
801028b1:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
801028b5:	77 3e                	ja     801028f5 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
801028b7:	8b 45 08             	mov    0x8(%ebp),%eax
801028ba:	8b 55 0c             	mov    0xc(%ebp),%edx
801028bd:	83 c2 04             	add    $0x4,%edx
801028c0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801028c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028c7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801028cb:	75 20                	jne    801028ed <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801028cd:	8b 45 08             	mov    0x8(%ebp),%eax
801028d0:	8b 00                	mov    (%eax),%eax
801028d2:	89 04 24             	mov    %eax,(%esp)
801028d5:	e8 31 f8 ff ff       	call   8010210b <balloc>
801028da:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028dd:	8b 45 08             	mov    0x8(%ebp),%eax
801028e0:	8b 55 0c             	mov    0xc(%ebp),%edx
801028e3:	8d 4a 04             	lea    0x4(%edx),%ecx
801028e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801028e9:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801028ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028f0:	e9 b1 00 00 00       	jmp    801029a6 <bmap+0xfc>
  }
  bn -= NDIRECT;
801028f5:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801028f9:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801028fd:	0f 87 97 00 00 00    	ja     8010299a <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80102903:	8b 45 08             	mov    0x8(%ebp),%eax
80102906:	8b 40 4c             	mov    0x4c(%eax),%eax
80102909:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010290c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102910:	75 19                	jne    8010292b <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80102912:	8b 45 08             	mov    0x8(%ebp),%eax
80102915:	8b 00                	mov    (%eax),%eax
80102917:	89 04 24             	mov    %eax,(%esp)
8010291a:	e8 ec f7 ff ff       	call   8010210b <balloc>
8010291f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102922:	8b 45 08             	mov    0x8(%ebp),%eax
80102925:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102928:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
8010292b:	8b 45 08             	mov    0x8(%ebp),%eax
8010292e:	8b 00                	mov    (%eax),%eax
80102930:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102933:	89 54 24 04          	mov    %edx,0x4(%esp)
80102937:	89 04 24             	mov    %eax,(%esp)
8010293a:	e8 67 d8 ff ff       	call   801001a6 <bread>
8010293f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80102942:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102945:	83 c0 18             	add    $0x18,%eax
80102948:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
8010294b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010294e:	c1 e0 02             	shl    $0x2,%eax
80102951:	03 45 ec             	add    -0x14(%ebp),%eax
80102954:	8b 00                	mov    (%eax),%eax
80102956:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102959:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010295d:	75 2b                	jne    8010298a <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
8010295f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102962:	c1 e0 02             	shl    $0x2,%eax
80102965:	89 c3                	mov    %eax,%ebx
80102967:	03 5d ec             	add    -0x14(%ebp),%ebx
8010296a:	8b 45 08             	mov    0x8(%ebp),%eax
8010296d:	8b 00                	mov    (%eax),%eax
8010296f:	89 04 24             	mov    %eax,(%esp)
80102972:	e8 94 f7 ff ff       	call   8010210b <balloc>
80102977:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010297a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010297d:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010297f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102982:	89 04 24             	mov    %eax,(%esp)
80102985:	e8 e8 19 00 00       	call   80104372 <log_write>
    }
    brelse(bp);
8010298a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010298d:	89 04 24             	mov    %eax,(%esp)
80102990:	e8 82 d8 ff ff       	call   80100217 <brelse>
    return addr;
80102995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102998:	eb 0c                	jmp    801029a6 <bmap+0xfc>
  }

  panic("bmap: out of range");
8010299a:	c7 04 24 11 96 10 80 	movl   $0x80109611,(%esp)
801029a1:	e8 97 db ff ff       	call   8010053d <panic>
}
801029a6:	83 c4 24             	add    $0x24,%esp
801029a9:	5b                   	pop    %ebx
801029aa:	5d                   	pop    %ebp
801029ab:	c3                   	ret    

801029ac <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
801029ac:	55                   	push   %ebp
801029ad:	89 e5                	mov    %esp,%ebp
801029af:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801029b2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029b9:	eb 44                	jmp    801029ff <itrunc+0x53>
    if(ip->addrs[i]){
801029bb:	8b 45 08             	mov    0x8(%ebp),%eax
801029be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029c1:	83 c2 04             	add    $0x4,%edx
801029c4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801029c8:	85 c0                	test   %eax,%eax
801029ca:	74 2f                	je     801029fb <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801029cc:	8b 45 08             	mov    0x8(%ebp),%eax
801029cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029d2:	83 c2 04             	add    $0x4,%edx
801029d5:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801029d9:	8b 45 08             	mov    0x8(%ebp),%eax
801029dc:	8b 00                	mov    (%eax),%eax
801029de:	89 54 24 04          	mov    %edx,0x4(%esp)
801029e2:	89 04 24             	mov    %eax,(%esp)
801029e5:	e8 90 f8 ff ff       	call   8010227a <bfree>
      ip->addrs[i] = 0;
801029ea:	8b 45 08             	mov    0x8(%ebp),%eax
801029ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029f0:	83 c2 04             	add    $0x4,%edx
801029f3:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801029fa:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801029fb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801029ff:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102a03:	7e b6                	jle    801029bb <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102a05:	8b 45 08             	mov    0x8(%ebp),%eax
80102a08:	8b 40 4c             	mov    0x4c(%eax),%eax
80102a0b:	85 c0                	test   %eax,%eax
80102a0d:	0f 84 8f 00 00 00    	je     80102aa2 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102a13:	8b 45 08             	mov    0x8(%ebp),%eax
80102a16:	8b 50 4c             	mov    0x4c(%eax),%edx
80102a19:	8b 45 08             	mov    0x8(%ebp),%eax
80102a1c:	8b 00                	mov    (%eax),%eax
80102a1e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a22:	89 04 24             	mov    %eax,(%esp)
80102a25:	e8 7c d7 ff ff       	call   801001a6 <bread>
80102a2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102a2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a30:	83 c0 18             	add    $0x18,%eax
80102a33:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102a36:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102a3d:	eb 2f                	jmp    80102a6e <itrunc+0xc2>
      if(a[j])
80102a3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a42:	c1 e0 02             	shl    $0x2,%eax
80102a45:	03 45 e8             	add    -0x18(%ebp),%eax
80102a48:	8b 00                	mov    (%eax),%eax
80102a4a:	85 c0                	test   %eax,%eax
80102a4c:	74 1c                	je     80102a6a <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80102a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a51:	c1 e0 02             	shl    $0x2,%eax
80102a54:	03 45 e8             	add    -0x18(%ebp),%eax
80102a57:	8b 10                	mov    (%eax),%edx
80102a59:	8b 45 08             	mov    0x8(%ebp),%eax
80102a5c:	8b 00                	mov    (%eax),%eax
80102a5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a62:	89 04 24             	mov    %eax,(%esp)
80102a65:	e8 10 f8 ff ff       	call   8010227a <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102a6a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a71:	83 f8 7f             	cmp    $0x7f,%eax
80102a74:	76 c9                	jbe    80102a3f <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102a76:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a79:	89 04 24             	mov    %eax,(%esp)
80102a7c:	e8 96 d7 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102a81:	8b 45 08             	mov    0x8(%ebp),%eax
80102a84:	8b 50 4c             	mov    0x4c(%eax),%edx
80102a87:	8b 45 08             	mov    0x8(%ebp),%eax
80102a8a:	8b 00                	mov    (%eax),%eax
80102a8c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a90:	89 04 24             	mov    %eax,(%esp)
80102a93:	e8 e2 f7 ff ff       	call   8010227a <bfree>
    ip->addrs[NDIRECT] = 0;
80102a98:	8b 45 08             	mov    0x8(%ebp),%eax
80102a9b:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102aa2:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa5:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102aac:	8b 45 08             	mov    0x8(%ebp),%eax
80102aaf:	89 04 24             	mov    %eax,(%esp)
80102ab2:	e8 95 f9 ff ff       	call   8010244c <iupdate>
}
80102ab7:	c9                   	leave  
80102ab8:	c3                   	ret    

80102ab9 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102ab9:	55                   	push   %ebp
80102aba:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102abc:	8b 45 08             	mov    0x8(%ebp),%eax
80102abf:	8b 00                	mov    (%eax),%eax
80102ac1:	89 c2                	mov    %eax,%edx
80102ac3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ac6:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80102ac9:	8b 45 08             	mov    0x8(%ebp),%eax
80102acc:	8b 50 04             	mov    0x4(%eax),%edx
80102acf:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ad2:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80102ad5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad8:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102adc:	8b 45 0c             	mov    0xc(%ebp),%eax
80102adf:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102ae2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae5:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102ae9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aec:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102af0:	8b 45 08             	mov    0x8(%ebp),%eax
80102af3:	8b 50 18             	mov    0x18(%eax),%edx
80102af6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102af9:	89 50 10             	mov    %edx,0x10(%eax)
}
80102afc:	5d                   	pop    %ebp
80102afd:	c3                   	ret    

80102afe <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102afe:	55                   	push   %ebp
80102aff:	89 e5                	mov    %esp,%ebp
80102b01:	53                   	push   %ebx
80102b02:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102b05:	8b 45 08             	mov    0x8(%ebp),%eax
80102b08:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102b0c:	66 83 f8 03          	cmp    $0x3,%ax
80102b10:	75 60                	jne    80102b72 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102b12:	8b 45 08             	mov    0x8(%ebp),%eax
80102b15:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102b19:	66 85 c0             	test   %ax,%ax
80102b1c:	78 20                	js     80102b3e <readi+0x40>
80102b1e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b21:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102b25:	66 83 f8 09          	cmp    $0x9,%ax
80102b29:	7f 13                	jg     80102b3e <readi+0x40>
80102b2b:	8b 45 08             	mov    0x8(%ebp),%eax
80102b2e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102b32:	98                   	cwtl   
80102b33:	8b 04 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%eax
80102b3a:	85 c0                	test   %eax,%eax
80102b3c:	75 0a                	jne    80102b48 <readi+0x4a>
      return -1;
80102b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b43:	e9 1b 01 00 00       	jmp    80102c63 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102b48:	8b 45 08             	mov    0x8(%ebp),%eax
80102b4b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102b4f:	98                   	cwtl   
80102b50:	8b 14 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%edx
80102b57:	8b 45 14             	mov    0x14(%ebp),%eax
80102b5a:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b5e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b61:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b65:	8b 45 08             	mov    0x8(%ebp),%eax
80102b68:	89 04 24             	mov    %eax,(%esp)
80102b6b:	ff d2                	call   *%edx
80102b6d:	e9 f1 00 00 00       	jmp    80102c63 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102b72:	8b 45 08             	mov    0x8(%ebp),%eax
80102b75:	8b 40 18             	mov    0x18(%eax),%eax
80102b78:	3b 45 10             	cmp    0x10(%ebp),%eax
80102b7b:	72 0d                	jb     80102b8a <readi+0x8c>
80102b7d:	8b 45 14             	mov    0x14(%ebp),%eax
80102b80:	8b 55 10             	mov    0x10(%ebp),%edx
80102b83:	01 d0                	add    %edx,%eax
80102b85:	3b 45 10             	cmp    0x10(%ebp),%eax
80102b88:	73 0a                	jae    80102b94 <readi+0x96>
    return -1;
80102b8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b8f:	e9 cf 00 00 00       	jmp    80102c63 <readi+0x165>
  if(off + n > ip->size)
80102b94:	8b 45 14             	mov    0x14(%ebp),%eax
80102b97:	8b 55 10             	mov    0x10(%ebp),%edx
80102b9a:	01 c2                	add    %eax,%edx
80102b9c:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9f:	8b 40 18             	mov    0x18(%eax),%eax
80102ba2:	39 c2                	cmp    %eax,%edx
80102ba4:	76 0c                	jbe    80102bb2 <readi+0xb4>
    n = ip->size - off;
80102ba6:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba9:	8b 40 18             	mov    0x18(%eax),%eax
80102bac:	2b 45 10             	sub    0x10(%ebp),%eax
80102baf:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102bb2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102bb9:	e9 96 00 00 00       	jmp    80102c54 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102bbe:	8b 45 10             	mov    0x10(%ebp),%eax
80102bc1:	c1 e8 09             	shr    $0x9,%eax
80102bc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bc8:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcb:	89 04 24             	mov    %eax,(%esp)
80102bce:	e8 d7 fc ff ff       	call   801028aa <bmap>
80102bd3:	8b 55 08             	mov    0x8(%ebp),%edx
80102bd6:	8b 12                	mov    (%edx),%edx
80102bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bdc:	89 14 24             	mov    %edx,(%esp)
80102bdf:	e8 c2 d5 ff ff       	call   801001a6 <bread>
80102be4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102be7:	8b 45 10             	mov    0x10(%ebp),%eax
80102bea:	89 c2                	mov    %eax,%edx
80102bec:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102bf2:	b8 00 02 00 00       	mov    $0x200,%eax
80102bf7:	89 c1                	mov    %eax,%ecx
80102bf9:	29 d1                	sub    %edx,%ecx
80102bfb:	89 ca                	mov    %ecx,%edx
80102bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c00:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102c03:	89 cb                	mov    %ecx,%ebx
80102c05:	29 c3                	sub    %eax,%ebx
80102c07:	89 d8                	mov    %ebx,%eax
80102c09:	39 c2                	cmp    %eax,%edx
80102c0b:	0f 46 c2             	cmovbe %edx,%eax
80102c0e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102c11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102c14:	8d 50 18             	lea    0x18(%eax),%edx
80102c17:	8b 45 10             	mov    0x10(%ebp),%eax
80102c1a:	25 ff 01 00 00       	and    $0x1ff,%eax
80102c1f:	01 c2                	add    %eax,%edx
80102c21:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c24:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c28:	89 54 24 04          	mov    %edx,0x4(%esp)
80102c2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c2f:	89 04 24             	mov    %eax,(%esp)
80102c32:	e8 42 33 00 00       	call   80105f79 <memmove>
    brelse(bp);
80102c37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102c3a:	89 04 24             	mov    %eax,(%esp)
80102c3d:	e8 d5 d5 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102c42:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c45:	01 45 f4             	add    %eax,-0xc(%ebp)
80102c48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c4b:	01 45 10             	add    %eax,0x10(%ebp)
80102c4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102c51:	01 45 0c             	add    %eax,0xc(%ebp)
80102c54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c57:	3b 45 14             	cmp    0x14(%ebp),%eax
80102c5a:	0f 82 5e ff ff ff    	jb     80102bbe <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102c60:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102c63:	83 c4 24             	add    $0x24,%esp
80102c66:	5b                   	pop    %ebx
80102c67:	5d                   	pop    %ebp
80102c68:	c3                   	ret    

80102c69 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102c69:	55                   	push   %ebp
80102c6a:	89 e5                	mov    %esp,%ebp
80102c6c:	53                   	push   %ebx
80102c6d:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102c70:	8b 45 08             	mov    0x8(%ebp),%eax
80102c73:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102c77:	66 83 f8 03          	cmp    $0x3,%ax
80102c7b:	75 60                	jne    80102cdd <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102c7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102c80:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c84:	66 85 c0             	test   %ax,%ax
80102c87:	78 20                	js     80102ca9 <writei+0x40>
80102c89:	8b 45 08             	mov    0x8(%ebp),%eax
80102c8c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c90:	66 83 f8 09          	cmp    $0x9,%ax
80102c94:	7f 13                	jg     80102ca9 <writei+0x40>
80102c96:	8b 45 08             	mov    0x8(%ebp),%eax
80102c99:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c9d:	98                   	cwtl   
80102c9e:	8b 04 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%eax
80102ca5:	85 c0                	test   %eax,%eax
80102ca7:	75 0a                	jne    80102cb3 <writei+0x4a>
      return -1;
80102ca9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102cae:	e9 46 01 00 00       	jmp    80102df9 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80102cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80102cb6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102cba:	98                   	cwtl   
80102cbb:	8b 14 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%edx
80102cc2:	8b 45 14             	mov    0x14(%ebp),%eax
80102cc5:	89 44 24 08          	mov    %eax,0x8(%esp)
80102cc9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ccc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cd0:	8b 45 08             	mov    0x8(%ebp),%eax
80102cd3:	89 04 24             	mov    %eax,(%esp)
80102cd6:	ff d2                	call   *%edx
80102cd8:	e9 1c 01 00 00       	jmp    80102df9 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80102cdd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce0:	8b 40 18             	mov    0x18(%eax),%eax
80102ce3:	3b 45 10             	cmp    0x10(%ebp),%eax
80102ce6:	72 0d                	jb     80102cf5 <writei+0x8c>
80102ce8:	8b 45 14             	mov    0x14(%ebp),%eax
80102ceb:	8b 55 10             	mov    0x10(%ebp),%edx
80102cee:	01 d0                	add    %edx,%eax
80102cf0:	3b 45 10             	cmp    0x10(%ebp),%eax
80102cf3:	73 0a                	jae    80102cff <writei+0x96>
    return -1;
80102cf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102cfa:	e9 fa 00 00 00       	jmp    80102df9 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80102cff:	8b 45 14             	mov    0x14(%ebp),%eax
80102d02:	8b 55 10             	mov    0x10(%ebp),%edx
80102d05:	01 d0                	add    %edx,%eax
80102d07:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102d0c:	76 0a                	jbe    80102d18 <writei+0xaf>
    return -1;
80102d0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d13:	e9 e1 00 00 00       	jmp    80102df9 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102d18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102d1f:	e9 a1 00 00 00       	jmp    80102dc5 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102d24:	8b 45 10             	mov    0x10(%ebp),%eax
80102d27:	c1 e8 09             	shr    $0x9,%eax
80102d2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d31:	89 04 24             	mov    %eax,(%esp)
80102d34:	e8 71 fb ff ff       	call   801028aa <bmap>
80102d39:	8b 55 08             	mov    0x8(%ebp),%edx
80102d3c:	8b 12                	mov    (%edx),%edx
80102d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d42:	89 14 24             	mov    %edx,(%esp)
80102d45:	e8 5c d4 ff ff       	call   801001a6 <bread>
80102d4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102d4d:	8b 45 10             	mov    0x10(%ebp),%eax
80102d50:	89 c2                	mov    %eax,%edx
80102d52:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102d58:	b8 00 02 00 00       	mov    $0x200,%eax
80102d5d:	89 c1                	mov    %eax,%ecx
80102d5f:	29 d1                	sub    %edx,%ecx
80102d61:	89 ca                	mov    %ecx,%edx
80102d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d66:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102d69:	89 cb                	mov    %ecx,%ebx
80102d6b:	29 c3                	sub    %eax,%ebx
80102d6d:	89 d8                	mov    %ebx,%eax
80102d6f:	39 c2                	cmp    %eax,%edx
80102d71:	0f 46 c2             	cmovbe %edx,%eax
80102d74:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d7a:	8d 50 18             	lea    0x18(%eax),%edx
80102d7d:	8b 45 10             	mov    0x10(%ebp),%eax
80102d80:	25 ff 01 00 00       	and    $0x1ff,%eax
80102d85:	01 c2                	add    %eax,%edx
80102d87:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d8a:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d91:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d95:	89 14 24             	mov    %edx,(%esp)
80102d98:	e8 dc 31 00 00       	call   80105f79 <memmove>
    log_write(bp);
80102d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102da0:	89 04 24             	mov    %eax,(%esp)
80102da3:	e8 ca 15 00 00       	call   80104372 <log_write>
    brelse(bp);
80102da8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102dab:	89 04 24             	mov    %eax,(%esp)
80102dae:	e8 64 d4 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102db3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102db6:	01 45 f4             	add    %eax,-0xc(%ebp)
80102db9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102dbc:	01 45 10             	add    %eax,0x10(%ebp)
80102dbf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102dc2:	01 45 0c             	add    %eax,0xc(%ebp)
80102dc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc8:	3b 45 14             	cmp    0x14(%ebp),%eax
80102dcb:	0f 82 53 ff ff ff    	jb     80102d24 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102dd1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102dd5:	74 1f                	je     80102df6 <writei+0x18d>
80102dd7:	8b 45 08             	mov    0x8(%ebp),%eax
80102dda:	8b 40 18             	mov    0x18(%eax),%eax
80102ddd:	3b 45 10             	cmp    0x10(%ebp),%eax
80102de0:	73 14                	jae    80102df6 <writei+0x18d>
    ip->size = off;
80102de2:	8b 45 08             	mov    0x8(%ebp),%eax
80102de5:	8b 55 10             	mov    0x10(%ebp),%edx
80102de8:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102deb:	8b 45 08             	mov    0x8(%ebp),%eax
80102dee:	89 04 24             	mov    %eax,(%esp)
80102df1:	e8 56 f6 ff ff       	call   8010244c <iupdate>
  }
  return n;
80102df6:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102df9:	83 c4 24             	add    $0x24,%esp
80102dfc:	5b                   	pop    %ebx
80102dfd:	5d                   	pop    %ebp
80102dfe:	c3                   	ret    

80102dff <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102dff:	55                   	push   %ebp
80102e00:	89 e5                	mov    %esp,%ebp
80102e02:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102e05:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102e0c:	00 
80102e0d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e10:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e14:	8b 45 08             	mov    0x8(%ebp),%eax
80102e17:	89 04 24             	mov    %eax,(%esp)
80102e1a:	e8 fe 31 00 00       	call   8010601d <strncmp>
}
80102e1f:	c9                   	leave  
80102e20:	c3                   	ret    

80102e21 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102e21:	55                   	push   %ebp
80102e22:	89 e5                	mov    %esp,%ebp
80102e24:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102e27:	8b 45 08             	mov    0x8(%ebp),%eax
80102e2a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102e2e:	66 83 f8 01          	cmp    $0x1,%ax
80102e32:	74 0c                	je     80102e40 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102e34:	c7 04 24 24 96 10 80 	movl   $0x80109624,(%esp)
80102e3b:	e8 fd d6 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102e40:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102e47:	e9 87 00 00 00       	jmp    80102ed3 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102e4c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102e53:	00 
80102e54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e57:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e5b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102e5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e62:	8b 45 08             	mov    0x8(%ebp),%eax
80102e65:	89 04 24             	mov    %eax,(%esp)
80102e68:	e8 91 fc ff ff       	call   80102afe <readi>
80102e6d:	83 f8 10             	cmp    $0x10,%eax
80102e70:	74 0c                	je     80102e7e <dirlookup+0x5d>
      panic("dirlink read");
80102e72:	c7 04 24 36 96 10 80 	movl   $0x80109636,(%esp)
80102e79:	e8 bf d6 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102e7e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102e82:	66 85 c0             	test   %ax,%ax
80102e85:	74 47                	je     80102ece <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102e87:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102e8a:	83 c0 02             	add    $0x2,%eax
80102e8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e91:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e94:	89 04 24             	mov    %eax,(%esp)
80102e97:	e8 63 ff ff ff       	call   80102dff <namecmp>
80102e9c:	85 c0                	test   %eax,%eax
80102e9e:	75 2f                	jne    80102ecf <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102ea0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102ea4:	74 08                	je     80102eae <dirlookup+0x8d>
        *poff = off;
80102ea6:	8b 45 10             	mov    0x10(%ebp),%eax
80102ea9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102eac:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102eae:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102eb2:	0f b7 c0             	movzwl %ax,%eax
80102eb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102eb8:	8b 45 08             	mov    0x8(%ebp),%eax
80102ebb:	8b 00                	mov    (%eax),%eax
80102ebd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ec0:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ec4:	89 04 24             	mov    %eax,(%esp)
80102ec7:	e8 38 f6 ff ff       	call   80102504 <iget>
80102ecc:	eb 19                	jmp    80102ee7 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102ece:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102ecf:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102ed3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ed6:	8b 40 18             	mov    0x18(%eax),%eax
80102ed9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102edc:	0f 87 6a ff ff ff    	ja     80102e4c <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102ee2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ee7:	c9                   	leave  
80102ee8:	c3                   	ret    

80102ee9 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102ee9:	55                   	push   %ebp
80102eea:	89 e5                	mov    %esp,%ebp
80102eec:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102eef:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102ef6:	00 
80102ef7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102efa:	89 44 24 04          	mov    %eax,0x4(%esp)
80102efe:	8b 45 08             	mov    0x8(%ebp),%eax
80102f01:	89 04 24             	mov    %eax,(%esp)
80102f04:	e8 18 ff ff ff       	call   80102e21 <dirlookup>
80102f09:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102f0c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102f10:	74 15                	je     80102f27 <dirlink+0x3e>
    iput(ip);
80102f12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f15:	89 04 24             	mov    %eax,(%esp)
80102f18:	e8 9e f8 ff ff       	call   801027bb <iput>
    return -1;
80102f1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f22:	e9 b8 00 00 00       	jmp    80102fdf <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102f27:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102f2e:	eb 44                	jmp    80102f74 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f33:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102f3a:	00 
80102f3b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f3f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102f42:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f46:	8b 45 08             	mov    0x8(%ebp),%eax
80102f49:	89 04 24             	mov    %eax,(%esp)
80102f4c:	e8 ad fb ff ff       	call   80102afe <readi>
80102f51:	83 f8 10             	cmp    $0x10,%eax
80102f54:	74 0c                	je     80102f62 <dirlink+0x79>
      panic("dirlink read");
80102f56:	c7 04 24 36 96 10 80 	movl   $0x80109636,(%esp)
80102f5d:	e8 db d5 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102f62:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102f66:	66 85 c0             	test   %ax,%ax
80102f69:	74 18                	je     80102f83 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f6e:	83 c0 10             	add    $0x10,%eax
80102f71:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102f74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102f77:	8b 45 08             	mov    0x8(%ebp),%eax
80102f7a:	8b 40 18             	mov    0x18(%eax),%eax
80102f7d:	39 c2                	cmp    %eax,%edx
80102f7f:	72 af                	jb     80102f30 <dirlink+0x47>
80102f81:	eb 01                	jmp    80102f84 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102f83:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102f84:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102f8b:	00 
80102f8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f8f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f93:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102f96:	83 c0 02             	add    $0x2,%eax
80102f99:	89 04 24             	mov    %eax,(%esp)
80102f9c:	e8 d4 30 00 00       	call   80106075 <strncpy>
  de.inum = inum;
80102fa1:	8b 45 10             	mov    0x10(%ebp),%eax
80102fa4:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102fa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fab:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102fb2:	00 
80102fb3:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fb7:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102fba:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fbe:	8b 45 08             	mov    0x8(%ebp),%eax
80102fc1:	89 04 24             	mov    %eax,(%esp)
80102fc4:	e8 a0 fc ff ff       	call   80102c69 <writei>
80102fc9:	83 f8 10             	cmp    $0x10,%eax
80102fcc:	74 0c                	je     80102fda <dirlink+0xf1>
    panic("dirlink");
80102fce:	c7 04 24 43 96 10 80 	movl   $0x80109643,(%esp)
80102fd5:	e8 63 d5 ff ff       	call   8010053d <panic>
  
  return 0;
80102fda:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102fdf:	c9                   	leave  
80102fe0:	c3                   	ret    

80102fe1 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102fe1:	55                   	push   %ebp
80102fe2:	89 e5                	mov    %esp,%ebp
80102fe4:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102fe7:	eb 04                	jmp    80102fed <skipelem+0xc>
    path++;
80102fe9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102fed:	8b 45 08             	mov    0x8(%ebp),%eax
80102ff0:	0f b6 00             	movzbl (%eax),%eax
80102ff3:	3c 2f                	cmp    $0x2f,%al
80102ff5:	74 f2                	je     80102fe9 <skipelem+0x8>
    path++;
  if(*path == 0)
80102ff7:	8b 45 08             	mov    0x8(%ebp),%eax
80102ffa:	0f b6 00             	movzbl (%eax),%eax
80102ffd:	84 c0                	test   %al,%al
80102fff:	75 0a                	jne    8010300b <skipelem+0x2a>
    return 0;
80103001:	b8 00 00 00 00       	mov    $0x0,%eax
80103006:	e9 86 00 00 00       	jmp    80103091 <skipelem+0xb0>
  s = path;
8010300b:	8b 45 08             	mov    0x8(%ebp),%eax
8010300e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80103011:	eb 04                	jmp    80103017 <skipelem+0x36>
    path++;
80103013:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80103017:	8b 45 08             	mov    0x8(%ebp),%eax
8010301a:	0f b6 00             	movzbl (%eax),%eax
8010301d:	3c 2f                	cmp    $0x2f,%al
8010301f:	74 0a                	je     8010302b <skipelem+0x4a>
80103021:	8b 45 08             	mov    0x8(%ebp),%eax
80103024:	0f b6 00             	movzbl (%eax),%eax
80103027:	84 c0                	test   %al,%al
80103029:	75 e8                	jne    80103013 <skipelem+0x32>
    path++;
  len = path - s;
8010302b:	8b 55 08             	mov    0x8(%ebp),%edx
8010302e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103031:	89 d1                	mov    %edx,%ecx
80103033:	29 c1                	sub    %eax,%ecx
80103035:	89 c8                	mov    %ecx,%eax
80103037:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010303a:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010303e:	7e 1c                	jle    8010305c <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80103040:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103047:	00 
80103048:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010304b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010304f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103052:	89 04 24             	mov    %eax,(%esp)
80103055:	e8 1f 2f 00 00       	call   80105f79 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010305a:	eb 28                	jmp    80103084 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
8010305c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010305f:	89 44 24 08          	mov    %eax,0x8(%esp)
80103063:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103066:	89 44 24 04          	mov    %eax,0x4(%esp)
8010306a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010306d:	89 04 24             	mov    %eax,(%esp)
80103070:	e8 04 2f 00 00       	call   80105f79 <memmove>
    name[len] = 0;
80103075:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103078:	03 45 0c             	add    0xc(%ebp),%eax
8010307b:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010307e:	eb 04                	jmp    80103084 <skipelem+0xa3>
    path++;
80103080:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80103084:	8b 45 08             	mov    0x8(%ebp),%eax
80103087:	0f b6 00             	movzbl (%eax),%eax
8010308a:	3c 2f                	cmp    $0x2f,%al
8010308c:	74 f2                	je     80103080 <skipelem+0x9f>
    path++;
  return path;
8010308e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80103091:	c9                   	leave  
80103092:	c3                   	ret    

80103093 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80103093:	55                   	push   %ebp
80103094:	89 e5                	mov    %esp,%ebp
80103096:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80103099:	8b 45 08             	mov    0x8(%ebp),%eax
8010309c:	0f b6 00             	movzbl (%eax),%eax
8010309f:	3c 2f                	cmp    $0x2f,%al
801030a1:	75 1c                	jne    801030bf <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801030a3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801030aa:	00 
801030ab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801030b2:	e8 4d f4 ff ff       	call   80102504 <iget>
801030b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801030ba:	e9 af 00 00 00       	jmp    8010316e <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801030bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801030c5:	8b 40 68             	mov    0x68(%eax),%eax
801030c8:	89 04 24             	mov    %eax,(%esp)
801030cb:	e8 06 f5 ff ff       	call   801025d6 <idup>
801030d0:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801030d3:	e9 96 00 00 00       	jmp    8010316e <namex+0xdb>
    ilock(ip);
801030d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030db:	89 04 24             	mov    %eax,(%esp)
801030de:	e8 25 f5 ff ff       	call   80102608 <ilock>
    if(ip->type != T_DIR){
801030e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030e6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801030ea:	66 83 f8 01          	cmp    $0x1,%ax
801030ee:	74 15                	je     80103105 <namex+0x72>
      iunlockput(ip);
801030f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030f3:	89 04 24             	mov    %eax,(%esp)
801030f6:	e8 91 f7 ff ff       	call   8010288c <iunlockput>
      return 0;
801030fb:	b8 00 00 00 00       	mov    $0x0,%eax
80103100:	e9 a3 00 00 00       	jmp    801031a8 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80103105:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103109:	74 1d                	je     80103128 <namex+0x95>
8010310b:	8b 45 08             	mov    0x8(%ebp),%eax
8010310e:	0f b6 00             	movzbl (%eax),%eax
80103111:	84 c0                	test   %al,%al
80103113:	75 13                	jne    80103128 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80103115:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103118:	89 04 24             	mov    %eax,(%esp)
8010311b:	e8 36 f6 ff ff       	call   80102756 <iunlock>
      return ip;
80103120:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103123:	e9 80 00 00 00       	jmp    801031a8 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80103128:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010312f:	00 
80103130:	8b 45 10             	mov    0x10(%ebp),%eax
80103133:	89 44 24 04          	mov    %eax,0x4(%esp)
80103137:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010313a:	89 04 24             	mov    %eax,(%esp)
8010313d:	e8 df fc ff ff       	call   80102e21 <dirlookup>
80103142:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103145:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103149:	75 12                	jne    8010315d <namex+0xca>
      iunlockput(ip);
8010314b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010314e:	89 04 24             	mov    %eax,(%esp)
80103151:	e8 36 f7 ff ff       	call   8010288c <iunlockput>
      return 0;
80103156:	b8 00 00 00 00       	mov    $0x0,%eax
8010315b:	eb 4b                	jmp    801031a8 <namex+0x115>
    }
    iunlockput(ip);
8010315d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103160:	89 04 24             	mov    %eax,(%esp)
80103163:	e8 24 f7 ff ff       	call   8010288c <iunlockput>
    ip = next;
80103168:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010316b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010316e:	8b 45 10             	mov    0x10(%ebp),%eax
80103171:	89 44 24 04          	mov    %eax,0x4(%esp)
80103175:	8b 45 08             	mov    0x8(%ebp),%eax
80103178:	89 04 24             	mov    %eax,(%esp)
8010317b:	e8 61 fe ff ff       	call   80102fe1 <skipelem>
80103180:	89 45 08             	mov    %eax,0x8(%ebp)
80103183:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103187:	0f 85 4b ff ff ff    	jne    801030d8 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010318d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103191:	74 12                	je     801031a5 <namex+0x112>
    iput(ip);
80103193:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103196:	89 04 24             	mov    %eax,(%esp)
80103199:	e8 1d f6 ff ff       	call   801027bb <iput>
    return 0;
8010319e:	b8 00 00 00 00       	mov    $0x0,%eax
801031a3:	eb 03                	jmp    801031a8 <namex+0x115>
  }
  return ip;
801031a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801031a8:	c9                   	leave  
801031a9:	c3                   	ret    

801031aa <namei>:

struct inode*
namei(char *path)
{
801031aa:	55                   	push   %ebp
801031ab:	89 e5                	mov    %esp,%ebp
801031ad:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801031b0:	8d 45 ea             	lea    -0x16(%ebp),%eax
801031b3:	89 44 24 08          	mov    %eax,0x8(%esp)
801031b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801031be:	00 
801031bf:	8b 45 08             	mov    0x8(%ebp),%eax
801031c2:	89 04 24             	mov    %eax,(%esp)
801031c5:	e8 c9 fe ff ff       	call   80103093 <namex>
}
801031ca:	c9                   	leave  
801031cb:	c3                   	ret    

801031cc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801031cc:	55                   	push   %ebp
801031cd:	89 e5                	mov    %esp,%ebp
801031cf:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801031d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801031d5:	89 44 24 08          	mov    %eax,0x8(%esp)
801031d9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801031e0:	00 
801031e1:	8b 45 08             	mov    0x8(%ebp),%eax
801031e4:	89 04 24             	mov    %eax,(%esp)
801031e7:	e8 a7 fe ff ff       	call   80103093 <namex>
}
801031ec:	c9                   	leave  
801031ed:	c3                   	ret    

801031ee <getNextInode>:

struct inode*
getNextInode(void)
{
801031ee:	55                   	push   %ebp
801031ef:	89 e5                	mov    %esp,%ebp
801031f1:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
801031f4:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801031fb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103202:	e8 6d ee ff ff       	call   80102074 <readsb>
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103207:	a1 18 c6 10 80       	mov    0x8010c618,%eax
8010320c:	83 c0 01             	add    $0x1,%eax
8010320f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103212:	eb 79                	jmp    8010328d <getNextInode+0x9f>
  {
    bp = bread(1, IBLOCK(inum));
80103214:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103217:	c1 e8 03             	shr    $0x3,%eax
8010321a:	83 c0 02             	add    $0x2,%eax
8010321d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103221:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103228:	e8 79 cf ff ff       	call   801001a6 <bread>
8010322d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80103230:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103233:	8d 50 18             	lea    0x18(%eax),%edx
80103236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103239:	83 e0 07             	and    $0x7,%eax
8010323c:	c1 e0 06             	shl    $0x6,%eax
8010323f:	01 d0                	add    %edx,%eax
80103241:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103244:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103247:	0f b7 00             	movzwl (%eax),%eax
8010324a:	66 83 f8 02          	cmp    $0x2,%ax
8010324e:	75 2e                	jne    8010327e <getNextInode+0x90>
    {
      nextInum = inum;
80103250:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103253:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      //cprintf("next: nextInum = %d\n",nextInum);
      ip = iget(1,inum);
80103258:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010325b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010325f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103266:	e8 99 f2 ff ff       	call   80102504 <iget>
8010326b:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
8010326e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103271:	89 04 24             	mov    %eax,(%esp)
80103274:	e8 9e cf ff ff       	call   80100217 <brelse>
      return ip;
80103279:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010327c:	eb 22                	jmp    801032a0 <getNextInode+0xb2>
    }
    brelse(bp);
8010327e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103281:	89 04 24             	mov    %eax,(%esp)
80103284:	e8 8e cf ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103289:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010328d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103290:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103293:	39 c2                	cmp    %eax,%edx
80103295:	0f 82 79 ff ff ff    	jb     80103214 <getNextInode+0x26>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
8010329b:	b8 00 00 00 00       	mov    $0x0,%eax
}
801032a0:	c9                   	leave  
801032a1:	c3                   	ret    

801032a2 <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
801032a2:	55                   	push   %ebp
801032a3:	89 e5                	mov    %esp,%ebp
801032a5:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801032a8:	e9 8d 00 00 00       	jmp    8010333a <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
801032ad:	8b 45 08             	mov    0x8(%ebp),%eax
801032b0:	8b 00                	mov    (%eax),%eax
801032b2:	c1 e8 03             	shr    $0x3,%eax
801032b5:	83 c0 02             	add    $0x2,%eax
801032b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801032bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032c3:	e8 de ce ff ff       	call   801001a6 <bread>
801032c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
801032cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032ce:	8d 50 18             	lea    0x18(%eax),%edx
801032d1:	8b 45 08             	mov    0x8(%ebp),%eax
801032d4:	8b 00                	mov    (%eax),%eax
801032d6:	83 e0 07             	and    $0x7,%eax
801032d9:	c1 e0 06             	shl    $0x6,%eax
801032dc:	01 d0                	add    %edx,%eax
801032de:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
801032e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032e4:	0f b7 00             	movzwl (%eax),%eax
801032e7:	66 83 f8 02          	cmp    $0x2,%ax
801032eb:	75 35                	jne    80103322 <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
801032ed:	8b 45 08             	mov    0x8(%ebp),%eax
801032f0:	8b 00                	mov    (%eax),%eax
801032f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801032f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032fd:	e8 02 f2 ff ff       	call   80102504 <iget>
80103302:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
80103305:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103308:	89 04 24             	mov    %eax,(%esp)
8010330b:	e8 07 cf ff ff       	call   80100217 <brelse>
      //cprintf("prev: before --, prevInum = %d\n",*prevInum);
      (*prevInum)--;
80103310:	8b 45 08             	mov    0x8(%ebp),%eax
80103313:	8b 00                	mov    (%eax),%eax
80103315:	8d 50 ff             	lea    -0x1(%eax),%edx
80103318:	8b 45 08             	mov    0x8(%ebp),%eax
8010331b:	89 10                	mov    %edx,(%eax)
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
8010331d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103320:	eb 2f                	jmp    80103351 <getPrevInode+0xaf>
    }
    brelse(bp);
80103322:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103325:	89 04 24             	mov    %eax,(%esp)
80103328:	e8 ea ce ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
8010332d:	8b 45 08             	mov    0x8(%ebp),%eax
80103330:	8b 00                	mov    (%eax),%eax
80103332:	8d 50 ff             	lea    -0x1(%eax),%edx
80103335:	8b 45 08             	mov    0x8(%ebp),%eax
80103338:	89 10                	mov    %edx,(%eax)
8010333a:	8b 45 08             	mov    0x8(%ebp),%eax
8010333d:	8b 10                	mov    (%eax),%edx
8010333f:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103344:	39 c2                	cmp    %eax,%edx
80103346:	0f 8f 61 ff ff ff    	jg     801032ad <getPrevInode+0xb>
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
    }
    brelse(bp);
  }
  return 0;
8010334c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103351:	c9                   	leave  
80103352:	c3                   	ret    

80103353 <updateBlkRef>:


void
updateBlkRef(uint sector, int flag)
{
80103353:	55                   	push   %ebp
80103354:	89 e5                	mov    %esp,%ebp
80103356:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  if(sector < 512)
80103359:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103360:	0f 87 89 00 00 00    	ja     801033ef <updateBlkRef+0x9c>
  {
    bp = bread(1,1024);
80103366:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010336d:	00 
8010336e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103375:	e8 2c ce ff ff       	call   801001a6 <bread>
8010337a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
8010337d:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103381:	75 1e                	jne    801033a1 <updateBlkRef+0x4e>
      bp->data[sector]++;
80103383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103386:	03 45 08             	add    0x8(%ebp),%eax
80103389:	83 c0 10             	add    $0x10,%eax
8010338c:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103390:	8d 50 01             	lea    0x1(%eax),%edx
80103393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103396:	03 45 08             	add    0x8(%ebp),%eax
80103399:	83 c0 10             	add    $0x10,%eax
8010339c:	88 50 08             	mov    %dl,0x8(%eax)
8010339f:	eb 33                	jmp    801033d4 <updateBlkRef+0x81>
    else if(flag == -1)
801033a1:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801033a5:	75 2d                	jne    801033d4 <updateBlkRef+0x81>
      if(bp->data[sector] > 0)
801033a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033aa:	03 45 08             	add    0x8(%ebp),%eax
801033ad:	83 c0 10             	add    $0x10,%eax
801033b0:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801033b4:	84 c0                	test   %al,%al
801033b6:	74 1c                	je     801033d4 <updateBlkRef+0x81>
	bp->data[sector]--;
801033b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033bb:	03 45 08             	add    0x8(%ebp),%eax
801033be:	83 c0 10             	add    $0x10,%eax
801033c1:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801033c5:	8d 50 ff             	lea    -0x1(%eax),%edx
801033c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033cb:	03 45 08             	add    0x8(%ebp),%eax
801033ce:	83 c0 10             	add    $0x10,%eax
801033d1:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
801033d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d7:	89 04 24             	mov    %eax,(%esp)
801033da:	e8 fe cd ff ff       	call   801001dd <bwrite>
    brelse(bp);
801033df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033e2:	89 04 24             	mov    %eax,(%esp)
801033e5:	e8 2d ce ff ff       	call   80100217 <brelse>
801033ea:	e9 91 00 00 00       	jmp    80103480 <updateBlkRef+0x12d>
  }
  else if(sector < 1024)
801033ef:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801033f6:	0f 87 84 00 00 00    	ja     80103480 <updateBlkRef+0x12d>
  {
    bp = bread(1,1025);
801033fc:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80103403:	00 
80103404:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010340b:	e8 96 cd ff ff       	call   801001a6 <bread>
80103410:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103413:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103417:	75 1c                	jne    80103435 <updateBlkRef+0xe2>
      bp->data[sector-512]++;
80103419:	8b 45 08             	mov    0x8(%ebp),%eax
8010341c:	2d 00 02 00 00       	sub    $0x200,%eax
80103421:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103424:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80103429:	8d 4a 01             	lea    0x1(%edx),%ecx
8010342c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010342f:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
80103433:	eb 35                	jmp    8010346a <updateBlkRef+0x117>
    else if(flag == -1)
80103435:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
80103439:	75 2f                	jne    8010346a <updateBlkRef+0x117>
      if(bp->data[sector-512] > 0)
8010343b:	8b 45 08             	mov    0x8(%ebp),%eax
8010343e:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
80103444:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103447:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
8010344c:	84 c0                	test   %al,%al
8010344e:	74 1a                	je     8010346a <updateBlkRef+0x117>
	bp->data[sector-512]--;
80103450:	8b 45 08             	mov    0x8(%ebp),%eax
80103453:	2d 00 02 00 00       	sub    $0x200,%eax
80103458:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010345b:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80103460:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103463:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103466:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
8010346a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010346d:	89 04 24             	mov    %eax,(%esp)
80103470:	e8 68 cd ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103475:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103478:	89 04 24             	mov    %eax,(%esp)
8010347b:	e8 97 cd ff ff       	call   80100217 <brelse>
  }  
}
80103480:	c9                   	leave  
80103481:	c3                   	ret    

80103482 <getBlkRef>:

int
getBlkRef(uint sector)
{
80103482:	55                   	push   %ebp
80103483:	89 e5                	mov    %esp,%ebp
80103485:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1;
80103488:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  
  if(sector < 512)
8010348f:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103496:	77 19                	ja     801034b1 <getBlkRef+0x2f>
    bp = bread(1,1024);
80103498:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010349f:	00 
801034a0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034a7:	e8 fa cc ff ff       	call   801001a6 <bread>
801034ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
801034af:	eb 20                	jmp    801034d1 <getBlkRef+0x4f>
  else if(sector < 1024)
801034b1:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801034b8:	77 17                	ja     801034d1 <getBlkRef+0x4f>
    bp = bread(1,1025);
801034ba:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
801034c1:	00 
801034c2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034c9:	e8 d8 cc ff ff       	call   801001a6 <bread>
801034ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ret = bp->data[sector];
801034d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d4:	03 45 08             	add    0x8(%ebp),%eax
801034d7:	83 c0 10             	add    $0x10,%eax
801034da:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801034de:	0f b6 c0             	movzbl %al,%eax
801034e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  brelse(bp);
801034e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034e7:	89 04 24             	mov    %eax,(%esp)
801034ea:	e8 28 cd ff ff       	call   80100217 <brelse>
  return ret;
801034ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801034f2:	c9                   	leave  
801034f3:	c3                   	ret    

801034f4 <zeroNextInum>:

void
zeroNextInum(void)
{
801034f4:	55                   	push   %ebp
801034f5:	89 e5                	mov    %esp,%ebp
  nextInum = 0;
801034f7:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
801034fe:	00 00 00 
80103501:	5d                   	pop    %ebp
80103502:	c3                   	ret    
	...

80103504 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103504:	55                   	push   %ebp
80103505:	89 e5                	mov    %esp,%ebp
80103507:	53                   	push   %ebx
80103508:	83 ec 14             	sub    $0x14,%esp
8010350b:	8b 45 08             	mov    0x8(%ebp),%eax
8010350e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103512:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103516:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010351a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010351e:	ec                   	in     (%dx),%al
8010351f:	89 c3                	mov    %eax,%ebx
80103521:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103524:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103528:	83 c4 14             	add    $0x14,%esp
8010352b:	5b                   	pop    %ebx
8010352c:	5d                   	pop    %ebp
8010352d:	c3                   	ret    

8010352e <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010352e:	55                   	push   %ebp
8010352f:	89 e5                	mov    %esp,%ebp
80103531:	57                   	push   %edi
80103532:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80103533:	8b 55 08             	mov    0x8(%ebp),%edx
80103536:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103539:	8b 45 10             	mov    0x10(%ebp),%eax
8010353c:	89 cb                	mov    %ecx,%ebx
8010353e:	89 df                	mov    %ebx,%edi
80103540:	89 c1                	mov    %eax,%ecx
80103542:	fc                   	cld    
80103543:	f3 6d                	rep insl (%dx),%es:(%edi)
80103545:	89 c8                	mov    %ecx,%eax
80103547:	89 fb                	mov    %edi,%ebx
80103549:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010354c:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010354f:	5b                   	pop    %ebx
80103550:	5f                   	pop    %edi
80103551:	5d                   	pop    %ebp
80103552:	c3                   	ret    

80103553 <outb>:

static inline void
outb(ushort port, uchar data)
{
80103553:	55                   	push   %ebp
80103554:	89 e5                	mov    %esp,%ebp
80103556:	83 ec 08             	sub    $0x8,%esp
80103559:	8b 55 08             	mov    0x8(%ebp),%edx
8010355c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010355f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103563:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103566:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010356a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010356e:	ee                   	out    %al,(%dx)
}
8010356f:	c9                   	leave  
80103570:	c3                   	ret    

80103571 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80103571:	55                   	push   %ebp
80103572:	89 e5                	mov    %esp,%ebp
80103574:	56                   	push   %esi
80103575:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80103576:	8b 55 08             	mov    0x8(%ebp),%edx
80103579:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010357c:	8b 45 10             	mov    0x10(%ebp),%eax
8010357f:	89 cb                	mov    %ecx,%ebx
80103581:	89 de                	mov    %ebx,%esi
80103583:	89 c1                	mov    %eax,%ecx
80103585:	fc                   	cld    
80103586:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80103588:	89 c8                	mov    %ecx,%eax
8010358a:	89 f3                	mov    %esi,%ebx
8010358c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010358f:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103592:	5b                   	pop    %ebx
80103593:	5e                   	pop    %esi
80103594:	5d                   	pop    %ebp
80103595:	c3                   	ret    

80103596 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80103596:	55                   	push   %ebp
80103597:	89 e5                	mov    %esp,%ebp
80103599:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010359c:	90                   	nop
8010359d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801035a4:	e8 5b ff ff ff       	call   80103504 <inb>
801035a9:	0f b6 c0             	movzbl %al,%eax
801035ac:	89 45 fc             	mov    %eax,-0x4(%ebp)
801035af:	8b 45 fc             	mov    -0x4(%ebp),%eax
801035b2:	25 c0 00 00 00       	and    $0xc0,%eax
801035b7:	83 f8 40             	cmp    $0x40,%eax
801035ba:	75 e1                	jne    8010359d <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801035bc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801035c0:	74 11                	je     801035d3 <idewait+0x3d>
801035c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801035c5:	83 e0 21             	and    $0x21,%eax
801035c8:	85 c0                	test   %eax,%eax
801035ca:	74 07                	je     801035d3 <idewait+0x3d>
    return -1;
801035cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035d1:	eb 05                	jmp    801035d8 <idewait+0x42>
  return 0;
801035d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801035d8:	c9                   	leave  
801035d9:	c3                   	ret    

801035da <ideinit>:

void
ideinit(void)
{
801035da:	55                   	push   %ebp
801035db:	89 e5                	mov    %esp,%ebp
801035dd:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801035e0:	c7 44 24 04 4b 96 10 	movl   $0x8010964b,0x4(%esp)
801035e7:	80 
801035e8:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801035ef:	e8 42 26 00 00       	call   80105c36 <initlock>
  picenable(IRQ_IDE);
801035f4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801035fb:	e8 75 15 00 00       	call   80104b75 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80103600:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80103605:	83 e8 01             	sub    $0x1,%eax
80103608:	89 44 24 04          	mov    %eax,0x4(%esp)
8010360c:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103613:	e8 12 04 00 00       	call   80103a2a <ioapicenable>
  idewait(0);
80103618:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010361f:	e8 72 ff ff ff       	call   80103596 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103624:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010362b:	00 
8010362c:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103633:	e8 1b ff ff ff       	call   80103553 <outb>
  for(i=0; i<1000; i++){
80103638:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010363f:	eb 20                	jmp    80103661 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103641:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103648:	e8 b7 fe ff ff       	call   80103504 <inb>
8010364d:	84 c0                	test   %al,%al
8010364f:	74 0c                	je     8010365d <ideinit+0x83>
      havedisk1 = 1;
80103651:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80103658:	00 00 00 
      break;
8010365b:	eb 0d                	jmp    8010366a <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
8010365d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103661:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80103668:	7e d7                	jle    80103641 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010366a:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103671:	00 
80103672:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103679:	e8 d5 fe ff ff       	call   80103553 <outb>
}
8010367e:	c9                   	leave  
8010367f:	c3                   	ret    

80103680 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103680:	55                   	push   %ebp
80103681:	89 e5                	mov    %esp,%ebp
80103683:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80103686:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010368a:	75 0c                	jne    80103698 <idestart+0x18>
    panic("idestart");
8010368c:	c7 04 24 4f 96 10 80 	movl   $0x8010964f,(%esp)
80103693:	e8 a5 ce ff ff       	call   8010053d <panic>

  idewait(0);
80103698:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010369f:	e8 f2 fe ff ff       	call   80103596 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801036a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801036ab:	00 
801036ac:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801036b3:	e8 9b fe ff ff       	call   80103553 <outb>
  outb(0x1f2, 1);  // number of sectors
801036b8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801036bf:	00 
801036c0:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801036c7:	e8 87 fe ff ff       	call   80103553 <outb>
  outb(0x1f3, b->sector & 0xff);
801036cc:	8b 45 08             	mov    0x8(%ebp),%eax
801036cf:	8b 40 08             	mov    0x8(%eax),%eax
801036d2:	0f b6 c0             	movzbl %al,%eax
801036d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801036d9:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801036e0:	e8 6e fe ff ff       	call   80103553 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801036e5:	8b 45 08             	mov    0x8(%ebp),%eax
801036e8:	8b 40 08             	mov    0x8(%eax),%eax
801036eb:	c1 e8 08             	shr    $0x8,%eax
801036ee:	0f b6 c0             	movzbl %al,%eax
801036f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801036f5:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801036fc:	e8 52 fe ff ff       	call   80103553 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80103701:	8b 45 08             	mov    0x8(%ebp),%eax
80103704:	8b 40 08             	mov    0x8(%eax),%eax
80103707:	c1 e8 10             	shr    $0x10,%eax
8010370a:	0f b6 c0             	movzbl %al,%eax
8010370d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103711:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80103718:	e8 36 fe ff ff       	call   80103553 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
8010371d:	8b 45 08             	mov    0x8(%ebp),%eax
80103720:	8b 40 04             	mov    0x4(%eax),%eax
80103723:	83 e0 01             	and    $0x1,%eax
80103726:	89 c2                	mov    %eax,%edx
80103728:	c1 e2 04             	shl    $0x4,%edx
8010372b:	8b 45 08             	mov    0x8(%ebp),%eax
8010372e:	8b 40 08             	mov    0x8(%eax),%eax
80103731:	c1 e8 18             	shr    $0x18,%eax
80103734:	83 e0 0f             	and    $0xf,%eax
80103737:	09 d0                	or     %edx,%eax
80103739:	83 c8 e0             	or     $0xffffffe0,%eax
8010373c:	0f b6 c0             	movzbl %al,%eax
8010373f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103743:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010374a:	e8 04 fe ff ff       	call   80103553 <outb>
  if(b->flags & B_DIRTY){
8010374f:	8b 45 08             	mov    0x8(%ebp),%eax
80103752:	8b 00                	mov    (%eax),%eax
80103754:	83 e0 04             	and    $0x4,%eax
80103757:	85 c0                	test   %eax,%eax
80103759:	74 34                	je     8010378f <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010375b:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80103762:	00 
80103763:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010376a:	e8 e4 fd ff ff       	call   80103553 <outb>
    outsl(0x1f0, b->data, 512/4);
8010376f:	8b 45 08             	mov    0x8(%ebp),%eax
80103772:	83 c0 18             	add    $0x18,%eax
80103775:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010377c:	00 
8010377d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103781:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103788:	e8 e4 fd ff ff       	call   80103571 <outsl>
8010378d:	eb 14                	jmp    801037a3 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010378f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103796:	00 
80103797:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010379e:	e8 b0 fd ff ff       	call   80103553 <outb>
  }
}
801037a3:	c9                   	leave  
801037a4:	c3                   	ret    

801037a5 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801037a5:	55                   	push   %ebp
801037a6:	89 e5                	mov    %esp,%ebp
801037a8:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801037ab:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801037b2:	e8 a0 24 00 00       	call   80105c57 <acquire>
  if((b = idequeue) == 0){
801037b7:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801037bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
801037bf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801037c3:	75 11                	jne    801037d6 <ideintr+0x31>
    release(&idelock);
801037c5:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801037cc:	e8 e8 24 00 00       	call   80105cb9 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801037d1:	e9 90 00 00 00       	jmp    80103866 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801037d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037d9:	8b 40 14             	mov    0x14(%eax),%eax
801037dc:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801037e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037e4:	8b 00                	mov    (%eax),%eax
801037e6:	83 e0 04             	and    $0x4,%eax
801037e9:	85 c0                	test   %eax,%eax
801037eb:	75 2e                	jne    8010381b <ideintr+0x76>
801037ed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801037f4:	e8 9d fd ff ff       	call   80103596 <idewait>
801037f9:	85 c0                	test   %eax,%eax
801037fb:	78 1e                	js     8010381b <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801037fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103800:	83 c0 18             	add    $0x18,%eax
80103803:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010380a:	00 
8010380b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010380f:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103816:	e8 13 fd ff ff       	call   8010352e <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010381b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010381e:	8b 00                	mov    (%eax),%eax
80103820:	89 c2                	mov    %eax,%edx
80103822:	83 ca 02             	or     $0x2,%edx
80103825:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103828:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010382a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010382d:	8b 00                	mov    (%eax),%eax
8010382f:	89 c2                	mov    %eax,%edx
80103831:	83 e2 fb             	and    $0xfffffffb,%edx
80103834:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103837:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383c:	89 04 24             	mov    %eax,(%esp)
8010383f:	e8 0e 22 00 00       	call   80105a52 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103844:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103849:	85 c0                	test   %eax,%eax
8010384b:	74 0d                	je     8010385a <ideintr+0xb5>
    idestart(idequeue);
8010384d:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103852:	89 04 24             	mov    %eax,(%esp)
80103855:	e8 26 fe ff ff       	call   80103680 <idestart>

  release(&idelock);
8010385a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103861:	e8 53 24 00 00       	call   80105cb9 <release>
}
80103866:	c9                   	leave  
80103867:	c3                   	ret    

80103868 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103868:	55                   	push   %ebp
80103869:	89 e5                	mov    %esp,%ebp
8010386b:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
8010386e:	8b 45 08             	mov    0x8(%ebp),%eax
80103871:	8b 00                	mov    (%eax),%eax
80103873:	83 e0 01             	and    $0x1,%eax
80103876:	85 c0                	test   %eax,%eax
80103878:	75 0c                	jne    80103886 <iderw+0x1e>
    panic("iderw: buf not busy");
8010387a:	c7 04 24 58 96 10 80 	movl   $0x80109658,(%esp)
80103881:	e8 b7 cc ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103886:	8b 45 08             	mov    0x8(%ebp),%eax
80103889:	8b 00                	mov    (%eax),%eax
8010388b:	83 e0 06             	and    $0x6,%eax
8010388e:	83 f8 02             	cmp    $0x2,%eax
80103891:	75 0c                	jne    8010389f <iderw+0x37>
    panic("iderw: nothing to do");
80103893:	c7 04 24 6c 96 10 80 	movl   $0x8010966c,(%esp)
8010389a:	e8 9e cc ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
8010389f:	8b 45 08             	mov    0x8(%ebp),%eax
801038a2:	8b 40 04             	mov    0x4(%eax),%eax
801038a5:	85 c0                	test   %eax,%eax
801038a7:	74 15                	je     801038be <iderw+0x56>
801038a9:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801038ae:	85 c0                	test   %eax,%eax
801038b0:	75 0c                	jne    801038be <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801038b2:	c7 04 24 81 96 10 80 	movl   $0x80109681,(%esp)
801038b9:	e8 7f cc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801038be:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801038c5:	e8 8d 23 00 00       	call   80105c57 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801038ca:	8b 45 08             	mov    0x8(%ebp),%eax
801038cd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801038d4:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801038db:	eb 0b                	jmp    801038e8 <iderw+0x80>
801038dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038e0:	8b 00                	mov    (%eax),%eax
801038e2:	83 c0 14             	add    $0x14,%eax
801038e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801038e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038eb:	8b 00                	mov    (%eax),%eax
801038ed:	85 c0                	test   %eax,%eax
801038ef:	75 ec                	jne    801038dd <iderw+0x75>
    ;
  *pp = b;
801038f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038f4:	8b 55 08             	mov    0x8(%ebp),%edx
801038f7:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801038f9:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801038fe:	3b 45 08             	cmp    0x8(%ebp),%eax
80103901:	75 22                	jne    80103925 <iderw+0xbd>
    idestart(b);
80103903:	8b 45 08             	mov    0x8(%ebp),%eax
80103906:	89 04 24             	mov    %eax,(%esp)
80103909:	e8 72 fd ff ff       	call   80103680 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010390e:	eb 15                	jmp    80103925 <iderw+0xbd>
    sleep(b, &idelock);
80103910:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103917:	80 
80103918:	8b 45 08             	mov    0x8(%ebp),%eax
8010391b:	89 04 24             	mov    %eax,(%esp)
8010391e:	e8 56 20 00 00       	call   80105979 <sleep>
80103923:	eb 01                	jmp    80103926 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103925:	90                   	nop
80103926:	8b 45 08             	mov    0x8(%ebp),%eax
80103929:	8b 00                	mov    (%eax),%eax
8010392b:	83 e0 06             	and    $0x6,%eax
8010392e:	83 f8 02             	cmp    $0x2,%eax
80103931:	75 dd                	jne    80103910 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103933:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010393a:	e8 7a 23 00 00       	call   80105cb9 <release>
}
8010393f:	c9                   	leave  
80103940:	c3                   	ret    
80103941:	00 00                	add    %al,(%eax)
	...

80103944 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103944:	55                   	push   %ebp
80103945:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103947:	a1 74 08 11 80       	mov    0x80110874,%eax
8010394c:	8b 55 08             	mov    0x8(%ebp),%edx
8010394f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103951:	a1 74 08 11 80       	mov    0x80110874,%eax
80103956:	8b 40 10             	mov    0x10(%eax),%eax
}
80103959:	5d                   	pop    %ebp
8010395a:	c3                   	ret    

8010395b <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010395b:	55                   	push   %ebp
8010395c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010395e:	a1 74 08 11 80       	mov    0x80110874,%eax
80103963:	8b 55 08             	mov    0x8(%ebp),%edx
80103966:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103968:	a1 74 08 11 80       	mov    0x80110874,%eax
8010396d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103970:	89 50 10             	mov    %edx,0x10(%eax)
}
80103973:	5d                   	pop    %ebp
80103974:	c3                   	ret    

80103975 <ioapicinit>:

void
ioapicinit(void)
{
80103975:	55                   	push   %ebp
80103976:	89 e5                	mov    %esp,%ebp
80103978:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010397b:	a1 44 09 11 80       	mov    0x80110944,%eax
80103980:	85 c0                	test   %eax,%eax
80103982:	0f 84 9f 00 00 00    	je     80103a27 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103988:	c7 05 74 08 11 80 00 	movl   $0xfec00000,0x80110874
8010398f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103992:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103999:	e8 a6 ff ff ff       	call   80103944 <ioapicread>
8010399e:	c1 e8 10             	shr    $0x10,%eax
801039a1:	25 ff 00 00 00       	and    $0xff,%eax
801039a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801039a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801039b0:	e8 8f ff ff ff       	call   80103944 <ioapicread>
801039b5:	c1 e8 18             	shr    $0x18,%eax
801039b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801039bb:	0f b6 05 40 09 11 80 	movzbl 0x80110940,%eax
801039c2:	0f b6 c0             	movzbl %al,%eax
801039c5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801039c8:	74 0c                	je     801039d6 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801039ca:	c7 04 24 a0 96 10 80 	movl   $0x801096a0,(%esp)
801039d1:	e8 cb c9 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801039d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801039dd:	eb 3e                	jmp    80103a1d <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801039df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e2:	83 c0 20             	add    $0x20,%eax
801039e5:	0d 00 00 01 00       	or     $0x10000,%eax
801039ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039ed:	83 c2 08             	add    $0x8,%edx
801039f0:	01 d2                	add    %edx,%edx
801039f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801039f6:	89 14 24             	mov    %edx,(%esp)
801039f9:	e8 5d ff ff ff       	call   8010395b <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801039fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a01:	83 c0 08             	add    $0x8,%eax
80103a04:	01 c0                	add    %eax,%eax
80103a06:	83 c0 01             	add    $0x1,%eax
80103a09:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103a10:	00 
80103a11:	89 04 24             	mov    %eax,(%esp)
80103a14:	e8 42 ff ff ff       	call   8010395b <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103a19:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a20:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103a23:	7e ba                	jle    801039df <ioapicinit+0x6a>
80103a25:	eb 01                	jmp    80103a28 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103a27:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103a28:	c9                   	leave  
80103a29:	c3                   	ret    

80103a2a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103a30:	a1 44 09 11 80       	mov    0x80110944,%eax
80103a35:	85 c0                	test   %eax,%eax
80103a37:	74 39                	je     80103a72 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103a39:	8b 45 08             	mov    0x8(%ebp),%eax
80103a3c:	83 c0 20             	add    $0x20,%eax
80103a3f:	8b 55 08             	mov    0x8(%ebp),%edx
80103a42:	83 c2 08             	add    $0x8,%edx
80103a45:	01 d2                	add    %edx,%edx
80103a47:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a4b:	89 14 24             	mov    %edx,(%esp)
80103a4e:	e8 08 ff ff ff       	call   8010395b <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103a53:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a56:	c1 e0 18             	shl    $0x18,%eax
80103a59:	8b 55 08             	mov    0x8(%ebp),%edx
80103a5c:	83 c2 08             	add    $0x8,%edx
80103a5f:	01 d2                	add    %edx,%edx
80103a61:	83 c2 01             	add    $0x1,%edx
80103a64:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a68:	89 14 24             	mov    %edx,(%esp)
80103a6b:	e8 eb fe ff ff       	call   8010395b <ioapicwrite>
80103a70:	eb 01                	jmp    80103a73 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103a72:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103a73:	c9                   	leave  
80103a74:	c3                   	ret    
80103a75:	00 00                	add    %al,(%eax)
	...

80103a78 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103a78:	55                   	push   %ebp
80103a79:	89 e5                	mov    %esp,%ebp
80103a7b:	8b 45 08             	mov    0x8(%ebp),%eax
80103a7e:	05 00 00 00 80       	add    $0x80000000,%eax
80103a83:	5d                   	pop    %ebp
80103a84:	c3                   	ret    

80103a85 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103a85:	55                   	push   %ebp
80103a86:	89 e5                	mov    %esp,%ebp
80103a88:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103a8b:	c7 44 24 04 d2 96 10 	movl   $0x801096d2,0x4(%esp)
80103a92:	80 
80103a93:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103a9a:	e8 97 21 00 00       	call   80105c36 <initlock>
  kmem.use_lock = 0;
80103a9f:	c7 05 b4 08 11 80 00 	movl   $0x0,0x801108b4
80103aa6:	00 00 00 
  freerange(vstart, vend);
80103aa9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103aac:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ab0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ab3:	89 04 24             	mov    %eax,(%esp)
80103ab6:	e8 26 00 00 00       	call   80103ae1 <freerange>
}
80103abb:	c9                   	leave  
80103abc:	c3                   	ret    

80103abd <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103abd:	55                   	push   %ebp
80103abe:	89 e5                	mov    %esp,%ebp
80103ac0:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103ac3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ac6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aca:	8b 45 08             	mov    0x8(%ebp),%eax
80103acd:	89 04 24             	mov    %eax,(%esp)
80103ad0:	e8 0c 00 00 00       	call   80103ae1 <freerange>
  kmem.use_lock = 1;
80103ad5:	c7 05 b4 08 11 80 01 	movl   $0x1,0x801108b4
80103adc:	00 00 00 
}
80103adf:	c9                   	leave  
80103ae0:	c3                   	ret    

80103ae1 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103ae1:	55                   	push   %ebp
80103ae2:	89 e5                	mov    %esp,%ebp
80103ae4:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103ae7:	8b 45 08             	mov    0x8(%ebp),%eax
80103aea:	05 ff 0f 00 00       	add    $0xfff,%eax
80103aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103af4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103af7:	eb 12                	jmp    80103b0b <freerange+0x2a>
    kfree(p);
80103af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103afc:	89 04 24             	mov    %eax,(%esp)
80103aff:	e8 16 00 00 00       	call   80103b1a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103b04:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0e:	05 00 10 00 00       	add    $0x1000,%eax
80103b13:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103b16:	76 e1                	jbe    80103af9 <freerange+0x18>
    kfree(p);
}
80103b18:	c9                   	leave  
80103b19:	c3                   	ret    

80103b1a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103b1a:	55                   	push   %ebp
80103b1b:	89 e5                	mov    %esp,%ebp
80103b1d:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103b20:	8b 45 08             	mov    0x8(%ebp),%eax
80103b23:	25 ff 0f 00 00       	and    $0xfff,%eax
80103b28:	85 c0                	test   %eax,%eax
80103b2a:	75 1b                	jne    80103b47 <kfree+0x2d>
80103b2c:	81 7d 08 3c 37 11 80 	cmpl   $0x8011373c,0x8(%ebp)
80103b33:	72 12                	jb     80103b47 <kfree+0x2d>
80103b35:	8b 45 08             	mov    0x8(%ebp),%eax
80103b38:	89 04 24             	mov    %eax,(%esp)
80103b3b:	e8 38 ff ff ff       	call   80103a78 <v2p>
80103b40:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103b45:	76 0c                	jbe    80103b53 <kfree+0x39>
    panic("kfree");
80103b47:	c7 04 24 d7 96 10 80 	movl   $0x801096d7,(%esp)
80103b4e:	e8 ea c9 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103b53:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103b5a:	00 
80103b5b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103b62:	00 
80103b63:	8b 45 08             	mov    0x8(%ebp),%eax
80103b66:	89 04 24             	mov    %eax,(%esp)
80103b69:	e8 38 23 00 00       	call   80105ea6 <memset>

  if(kmem.use_lock)
80103b6e:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103b73:	85 c0                	test   %eax,%eax
80103b75:	74 0c                	je     80103b83 <kfree+0x69>
    acquire(&kmem.lock);
80103b77:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103b7e:	e8 d4 20 00 00       	call   80105c57 <acquire>
  r = (struct run*)v;
80103b83:	8b 45 08             	mov    0x8(%ebp),%eax
80103b86:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103b89:	8b 15 b8 08 11 80    	mov    0x801108b8,%edx
80103b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b92:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b97:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103b9c:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103ba1:	85 c0                	test   %eax,%eax
80103ba3:	74 0c                	je     80103bb1 <kfree+0x97>
    release(&kmem.lock);
80103ba5:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103bac:	e8 08 21 00 00       	call   80105cb9 <release>
}
80103bb1:	c9                   	leave  
80103bb2:	c3                   	ret    

80103bb3 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103bb3:	55                   	push   %ebp
80103bb4:	89 e5                	mov    %esp,%ebp
80103bb6:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103bb9:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103bbe:	85 c0                	test   %eax,%eax
80103bc0:	74 0c                	je     80103bce <kalloc+0x1b>
    acquire(&kmem.lock);
80103bc2:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103bc9:	e8 89 20 00 00       	call   80105c57 <acquire>
  r = kmem.freelist;
80103bce:	a1 b8 08 11 80       	mov    0x801108b8,%eax
80103bd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103bd6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103bda:	74 0a                	je     80103be6 <kalloc+0x33>
    kmem.freelist = r->next;
80103bdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bdf:	8b 00                	mov    (%eax),%eax
80103be1:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103be6:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103beb:	85 c0                	test   %eax,%eax
80103bed:	74 0c                	je     80103bfb <kalloc+0x48>
    release(&kmem.lock);
80103bef:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103bf6:	e8 be 20 00 00       	call   80105cb9 <release>
  return (char*)r;
80103bfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103bfe:	c9                   	leave  
80103bff:	c3                   	ret    

80103c00 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103c00:	55                   	push   %ebp
80103c01:	89 e5                	mov    %esp,%ebp
80103c03:	53                   	push   %ebx
80103c04:	83 ec 14             	sub    $0x14,%esp
80103c07:	8b 45 08             	mov    0x8(%ebp),%eax
80103c0a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103c0e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103c12:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103c16:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103c1a:	ec                   	in     (%dx),%al
80103c1b:	89 c3                	mov    %eax,%ebx
80103c1d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103c20:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103c24:	83 c4 14             	add    $0x14,%esp
80103c27:	5b                   	pop    %ebx
80103c28:	5d                   	pop    %ebp
80103c29:	c3                   	ret    

80103c2a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103c2a:	55                   	push   %ebp
80103c2b:	89 e5                	mov    %esp,%ebp
80103c2d:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103c30:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103c37:	e8 c4 ff ff ff       	call   80103c00 <inb>
80103c3c:	0f b6 c0             	movzbl %al,%eax
80103c3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c45:	83 e0 01             	and    $0x1,%eax
80103c48:	85 c0                	test   %eax,%eax
80103c4a:	75 0a                	jne    80103c56 <kbdgetc+0x2c>
    return -1;
80103c4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103c51:	e9 23 01 00 00       	jmp    80103d79 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103c56:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103c5d:	e8 9e ff ff ff       	call   80103c00 <inb>
80103c62:	0f b6 c0             	movzbl %al,%eax
80103c65:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103c68:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103c6f:	75 17                	jne    80103c88 <kbdgetc+0x5e>
    shift |= E0ESC;
80103c71:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103c76:	83 c8 40             	or     $0x40,%eax
80103c79:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103c7e:	b8 00 00 00 00       	mov    $0x0,%eax
80103c83:	e9 f1 00 00 00       	jmp    80103d79 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103c88:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103c8b:	25 80 00 00 00       	and    $0x80,%eax
80103c90:	85 c0                	test   %eax,%eax
80103c92:	74 45                	je     80103cd9 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103c94:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103c99:	83 e0 40             	and    $0x40,%eax
80103c9c:	85 c0                	test   %eax,%eax
80103c9e:	75 08                	jne    80103ca8 <kbdgetc+0x7e>
80103ca0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ca3:	83 e0 7f             	and    $0x7f,%eax
80103ca6:	eb 03                	jmp    80103cab <kbdgetc+0x81>
80103ca8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103cab:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103cae:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103cb1:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103cb6:	0f b6 00             	movzbl (%eax),%eax
80103cb9:	83 c8 40             	or     $0x40,%eax
80103cbc:	0f b6 c0             	movzbl %al,%eax
80103cbf:	f7 d0                	not    %eax
80103cc1:	89 c2                	mov    %eax,%edx
80103cc3:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103cc8:	21 d0                	and    %edx,%eax
80103cca:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103ccf:	b8 00 00 00 00       	mov    $0x0,%eax
80103cd4:	e9 a0 00 00 00       	jmp    80103d79 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103cd9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103cde:	83 e0 40             	and    $0x40,%eax
80103ce1:	85 c0                	test   %eax,%eax
80103ce3:	74 14                	je     80103cf9 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103ce5:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103cec:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103cf1:	83 e0 bf             	and    $0xffffffbf,%eax
80103cf4:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103cf9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103cfc:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103d01:	0f b6 00             	movzbl (%eax),%eax
80103d04:	0f b6 d0             	movzbl %al,%edx
80103d07:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103d0c:	09 d0                	or     %edx,%eax
80103d0e:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103d13:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103d16:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103d1b:	0f b6 00             	movzbl (%eax),%eax
80103d1e:	0f b6 d0             	movzbl %al,%edx
80103d21:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103d26:	31 d0                	xor    %edx,%eax
80103d28:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103d2d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103d32:	83 e0 03             	and    $0x3,%eax
80103d35:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103d3c:	03 45 fc             	add    -0x4(%ebp),%eax
80103d3f:	0f b6 00             	movzbl (%eax),%eax
80103d42:	0f b6 c0             	movzbl %al,%eax
80103d45:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103d48:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103d4d:	83 e0 08             	and    $0x8,%eax
80103d50:	85 c0                	test   %eax,%eax
80103d52:	74 22                	je     80103d76 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103d54:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103d58:	76 0c                	jbe    80103d66 <kbdgetc+0x13c>
80103d5a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103d5e:	77 06                	ja     80103d66 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103d60:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103d64:	eb 10                	jmp    80103d76 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103d66:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103d6a:	76 0a                	jbe    80103d76 <kbdgetc+0x14c>
80103d6c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103d70:	77 04                	ja     80103d76 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103d72:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103d76:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103d79:	c9                   	leave  
80103d7a:	c3                   	ret    

80103d7b <kbdintr>:

void
kbdintr(void)
{
80103d7b:	55                   	push   %ebp
80103d7c:	89 e5                	mov    %esp,%ebp
80103d7e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103d81:	c7 04 24 2a 3c 10 80 	movl   $0x80103c2a,(%esp)
80103d88:	e8 20 ca ff ff       	call   801007ad <consoleintr>
}
80103d8d:	c9                   	leave  
80103d8e:	c3                   	ret    
	...

80103d90 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103d90:	55                   	push   %ebp
80103d91:	89 e5                	mov    %esp,%ebp
80103d93:	83 ec 08             	sub    $0x8,%esp
80103d96:	8b 55 08             	mov    0x8(%ebp),%edx
80103d99:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d9c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103da0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103da3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103da7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103dab:	ee                   	out    %al,(%dx)
}
80103dac:	c9                   	leave  
80103dad:	c3                   	ret    

80103dae <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103dae:	55                   	push   %ebp
80103daf:	89 e5                	mov    %esp,%ebp
80103db1:	53                   	push   %ebx
80103db2:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103db5:	9c                   	pushf  
80103db6:	5b                   	pop    %ebx
80103db7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103dba:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103dbd:	83 c4 10             	add    $0x10,%esp
80103dc0:	5b                   	pop    %ebx
80103dc1:	5d                   	pop    %ebp
80103dc2:	c3                   	ret    

80103dc3 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103dc3:	55                   	push   %ebp
80103dc4:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103dc6:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103dcb:	8b 55 08             	mov    0x8(%ebp),%edx
80103dce:	c1 e2 02             	shl    $0x2,%edx
80103dd1:	01 c2                	add    %eax,%edx
80103dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd6:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103dd8:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103ddd:	83 c0 20             	add    $0x20,%eax
80103de0:	8b 00                	mov    (%eax),%eax
}
80103de2:	5d                   	pop    %ebp
80103de3:	c3                   	ret    

80103de4 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103de4:	55                   	push   %ebp
80103de5:	89 e5                	mov    %esp,%ebp
80103de7:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103dea:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103def:	85 c0                	test   %eax,%eax
80103df1:	0f 84 47 01 00 00    	je     80103f3e <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103df7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103dfe:	00 
80103dff:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103e06:	e8 b8 ff ff ff       	call   80103dc3 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103e0b:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103e12:	00 
80103e13:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103e1a:	e8 a4 ff ff ff       	call   80103dc3 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103e1f:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103e26:	00 
80103e27:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103e2e:	e8 90 ff ff ff       	call   80103dc3 <lapicw>
  lapicw(TICR, 10000000); 
80103e33:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103e3a:	00 
80103e3b:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103e42:	e8 7c ff ff ff       	call   80103dc3 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103e47:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103e4e:	00 
80103e4f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103e56:	e8 68 ff ff ff       	call   80103dc3 <lapicw>
  lapicw(LINT1, MASKED);
80103e5b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103e62:	00 
80103e63:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103e6a:	e8 54 ff ff ff       	call   80103dc3 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103e6f:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103e74:	83 c0 30             	add    $0x30,%eax
80103e77:	8b 00                	mov    (%eax),%eax
80103e79:	c1 e8 10             	shr    $0x10,%eax
80103e7c:	25 ff 00 00 00       	and    $0xff,%eax
80103e81:	83 f8 03             	cmp    $0x3,%eax
80103e84:	76 14                	jbe    80103e9a <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103e86:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103e8d:	00 
80103e8e:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103e95:	e8 29 ff ff ff       	call   80103dc3 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103e9a:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103ea1:	00 
80103ea2:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103ea9:	e8 15 ff ff ff       	call   80103dc3 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103eae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103eb5:	00 
80103eb6:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ebd:	e8 01 ff ff ff       	call   80103dc3 <lapicw>
  lapicw(ESR, 0);
80103ec2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103ec9:	00 
80103eca:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ed1:	e8 ed fe ff ff       	call   80103dc3 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103ed6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103edd:	00 
80103ede:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103ee5:	e8 d9 fe ff ff       	call   80103dc3 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103eea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103ef1:	00 
80103ef2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103ef9:	e8 c5 fe ff ff       	call   80103dc3 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103efe:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103f05:	00 
80103f06:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103f0d:	e8 b1 fe ff ff       	call   80103dc3 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103f12:	90                   	nop
80103f13:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f18:	05 00 03 00 00       	add    $0x300,%eax
80103f1d:	8b 00                	mov    (%eax),%eax
80103f1f:	25 00 10 00 00       	and    $0x1000,%eax
80103f24:	85 c0                	test   %eax,%eax
80103f26:	75 eb                	jne    80103f13 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103f28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103f2f:	00 
80103f30:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f37:	e8 87 fe ff ff       	call   80103dc3 <lapicw>
80103f3c:	eb 01                	jmp    80103f3f <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103f3e:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103f3f:	c9                   	leave  
80103f40:	c3                   	ret    

80103f41 <cpunum>:

int
cpunum(void)
{
80103f41:	55                   	push   %ebp
80103f42:	89 e5                	mov    %esp,%ebp
80103f44:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103f47:	e8 62 fe ff ff       	call   80103dae <readeflags>
80103f4c:	25 00 02 00 00       	and    $0x200,%eax
80103f51:	85 c0                	test   %eax,%eax
80103f53:	74 29                	je     80103f7e <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103f55:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103f5a:	85 c0                	test   %eax,%eax
80103f5c:	0f 94 c2             	sete   %dl
80103f5f:	83 c0 01             	add    $0x1,%eax
80103f62:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80103f67:	84 d2                	test   %dl,%dl
80103f69:	74 13                	je     80103f7e <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103f6b:	8b 45 04             	mov    0x4(%ebp),%eax
80103f6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f72:	c7 04 24 e0 96 10 80 	movl   $0x801096e0,(%esp)
80103f79:	e8 23 c4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103f7e:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f83:	85 c0                	test   %eax,%eax
80103f85:	74 0f                	je     80103f96 <cpunum+0x55>
    return lapic[ID]>>24;
80103f87:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f8c:	83 c0 20             	add    $0x20,%eax
80103f8f:	8b 00                	mov    (%eax),%eax
80103f91:	c1 e8 18             	shr    $0x18,%eax
80103f94:	eb 05                	jmp    80103f9b <cpunum+0x5a>
  return 0;
80103f96:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f9b:	c9                   	leave  
80103f9c:	c3                   	ret    

80103f9d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103f9d:	55                   	push   %ebp
80103f9e:	89 e5                	mov    %esp,%ebp
80103fa0:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103fa3:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103fa8:	85 c0                	test   %eax,%eax
80103faa:	74 14                	je     80103fc0 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103fac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103fb3:	00 
80103fb4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103fbb:	e8 03 fe ff ff       	call   80103dc3 <lapicw>
}
80103fc0:	c9                   	leave  
80103fc1:	c3                   	ret    

80103fc2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103fc2:	55                   	push   %ebp
80103fc3:	89 e5                	mov    %esp,%ebp
}
80103fc5:	5d                   	pop    %ebp
80103fc6:	c3                   	ret    

80103fc7 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103fc7:	55                   	push   %ebp
80103fc8:	89 e5                	mov    %esp,%ebp
80103fca:	83 ec 1c             	sub    $0x1c,%esp
80103fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd0:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103fd3:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103fda:	00 
80103fdb:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103fe2:	e8 a9 fd ff ff       	call   80103d90 <outb>
  outb(IO_RTC+1, 0x0A);
80103fe7:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103fee:	00 
80103fef:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103ff6:	e8 95 fd ff ff       	call   80103d90 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103ffb:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80104002:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104005:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010400a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010400d:	8d 50 02             	lea    0x2(%eax),%edx
80104010:	8b 45 0c             	mov    0xc(%ebp),%eax
80104013:	c1 e8 04             	shr    $0x4,%eax
80104016:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80104019:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010401d:	c1 e0 18             	shl    $0x18,%eax
80104020:	89 44 24 04          	mov    %eax,0x4(%esp)
80104024:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010402b:	e8 93 fd ff ff       	call   80103dc3 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80104030:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80104037:	00 
80104038:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010403f:	e8 7f fd ff ff       	call   80103dc3 <lapicw>
  microdelay(200);
80104044:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010404b:	e8 72 ff ff ff       	call   80103fc2 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80104050:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80104057:	00 
80104058:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010405f:	e8 5f fd ff ff       	call   80103dc3 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80104064:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010406b:	e8 52 ff ff ff       	call   80103fc2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104070:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104077:	eb 40                	jmp    801040b9 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80104079:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010407d:	c1 e0 18             	shl    $0x18,%eax
80104080:	89 44 24 04          	mov    %eax,0x4(%esp)
80104084:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010408b:	e8 33 fd ff ff       	call   80103dc3 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80104090:	8b 45 0c             	mov    0xc(%ebp),%eax
80104093:	c1 e8 0c             	shr    $0xc,%eax
80104096:	80 cc 06             	or     $0x6,%ah
80104099:	89 44 24 04          	mov    %eax,0x4(%esp)
8010409d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801040a4:	e8 1a fd ff ff       	call   80103dc3 <lapicw>
    microdelay(200);
801040a9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801040b0:	e8 0d ff ff ff       	call   80103fc2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801040b5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801040b9:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801040bd:	7e ba                	jle    80104079 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801040bf:	c9                   	leave  
801040c0:	c3                   	ret    
801040c1:	00 00                	add    %al,(%eax)
	...

801040c4 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
801040c4:	55                   	push   %ebp
801040c5:	89 e5                	mov    %esp,%ebp
801040c7:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801040ca:	c7 44 24 04 0c 97 10 	movl   $0x8010970c,0x4(%esp)
801040d1:	80 
801040d2:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801040d9:	e8 58 1b 00 00       	call   80105c36 <initlock>
  readsb(ROOTDEV, &sb);
801040de:	8d 45 e8             	lea    -0x18(%ebp),%eax
801040e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801040e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801040ec:	e8 83 df ff ff       	call   80102074 <readsb>
  log.start = sb.size - sb.nlog;
801040f1:	8b 55 e8             	mov    -0x18(%ebp),%edx
801040f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f7:	89 d1                	mov    %edx,%ecx
801040f9:	29 c1                	sub    %eax,%ecx
801040fb:	89 c8                	mov    %ecx,%eax
801040fd:	a3 f4 08 11 80       	mov    %eax,0x801108f4
  log.size = sb.nlog;
80104102:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104105:	a3 f8 08 11 80       	mov    %eax,0x801108f8
  log.dev = ROOTDEV;
8010410a:	c7 05 00 09 11 80 01 	movl   $0x1,0x80110900
80104111:	00 00 00 
  recover_from_log();
80104114:	e8 97 01 00 00       	call   801042b0 <recover_from_log>
}
80104119:	c9                   	leave  
8010411a:	c3                   	ret    

8010411b <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010411b:	55                   	push   %ebp
8010411c:	89 e5                	mov    %esp,%ebp
8010411e:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104121:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104128:	e9 89 00 00 00       	jmp    801041b6 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010412d:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104132:	03 45 f4             	add    -0xc(%ebp),%eax
80104135:	83 c0 01             	add    $0x1,%eax
80104138:	89 c2                	mov    %eax,%edx
8010413a:	a1 00 09 11 80       	mov    0x80110900,%eax
8010413f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104143:	89 04 24             	mov    %eax,(%esp)
80104146:	e8 5b c0 ff ff       	call   801001a6 <bread>
8010414b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010414e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104151:	83 c0 10             	add    $0x10,%eax
80104154:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
8010415b:	89 c2                	mov    %eax,%edx
8010415d:	a1 00 09 11 80       	mov    0x80110900,%eax
80104162:	89 54 24 04          	mov    %edx,0x4(%esp)
80104166:	89 04 24             	mov    %eax,(%esp)
80104169:	e8 38 c0 ff ff       	call   801001a6 <bread>
8010416e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80104171:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104174:	8d 50 18             	lea    0x18(%eax),%edx
80104177:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010417a:	83 c0 18             	add    $0x18,%eax
8010417d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104184:	00 
80104185:	89 54 24 04          	mov    %edx,0x4(%esp)
80104189:	89 04 24             	mov    %eax,(%esp)
8010418c:	e8 e8 1d 00 00       	call   80105f79 <memmove>
    bwrite(dbuf);  // write dst to disk
80104191:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104194:	89 04 24             	mov    %eax,(%esp)
80104197:	e8 41 c0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010419c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010419f:	89 04 24             	mov    %eax,(%esp)
801041a2:	e8 70 c0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801041a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041aa:	89 04 24             	mov    %eax,(%esp)
801041ad:	e8 65 c0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801041b2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801041b6:	a1 04 09 11 80       	mov    0x80110904,%eax
801041bb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801041be:	0f 8f 69 ff ff ff    	jg     8010412d <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801041c4:	c9                   	leave  
801041c5:	c3                   	ret    

801041c6 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801041c6:	55                   	push   %ebp
801041c7:	89 e5                	mov    %esp,%ebp
801041c9:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801041cc:	a1 f4 08 11 80       	mov    0x801108f4,%eax
801041d1:	89 c2                	mov    %eax,%edx
801041d3:	a1 00 09 11 80       	mov    0x80110900,%eax
801041d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801041dc:	89 04 24             	mov    %eax,(%esp)
801041df:	e8 c2 bf ff ff       	call   801001a6 <bread>
801041e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801041e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041ea:	83 c0 18             	add    $0x18,%eax
801041ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801041f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801041f3:	8b 00                	mov    (%eax),%eax
801041f5:	a3 04 09 11 80       	mov    %eax,0x80110904
  for (i = 0; i < log.lh.n; i++) {
801041fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104201:	eb 1b                	jmp    8010421e <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80104203:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104206:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104209:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010420d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104210:	83 c2 10             	add    $0x10,%edx
80104213:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010421a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010421e:	a1 04 09 11 80       	mov    0x80110904,%eax
80104223:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104226:	7f db                	jg     80104203 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80104228:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010422b:	89 04 24             	mov    %eax,(%esp)
8010422e:	e8 e4 bf ff ff       	call   80100217 <brelse>
}
80104233:	c9                   	leave  
80104234:	c3                   	ret    

80104235 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80104235:	55                   	push   %ebp
80104236:	89 e5                	mov    %esp,%ebp
80104238:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010423b:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104240:	89 c2                	mov    %eax,%edx
80104242:	a1 00 09 11 80       	mov    0x80110900,%eax
80104247:	89 54 24 04          	mov    %edx,0x4(%esp)
8010424b:	89 04 24             	mov    %eax,(%esp)
8010424e:	e8 53 bf ff ff       	call   801001a6 <bread>
80104253:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80104256:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104259:	83 c0 18             	add    $0x18,%eax
8010425c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010425f:	8b 15 04 09 11 80    	mov    0x80110904,%edx
80104265:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104268:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010426a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104271:	eb 1b                	jmp    8010428e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80104273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104276:	83 c0 10             	add    $0x10,%eax
80104279:	8b 0c 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%ecx
80104280:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104283:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104286:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010428a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010428e:	a1 04 09 11 80       	mov    0x80110904,%eax
80104293:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104296:	7f db                	jg     80104273 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80104298:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010429b:	89 04 24             	mov    %eax,(%esp)
8010429e:	e8 3a bf ff ff       	call   801001dd <bwrite>
  brelse(buf);
801042a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042a6:	89 04 24             	mov    %eax,(%esp)
801042a9:	e8 69 bf ff ff       	call   80100217 <brelse>
}
801042ae:	c9                   	leave  
801042af:	c3                   	ret    

801042b0 <recover_from_log>:

static void
recover_from_log(void)
{
801042b0:	55                   	push   %ebp
801042b1:	89 e5                	mov    %esp,%ebp
801042b3:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801042b6:	e8 0b ff ff ff       	call   801041c6 <read_head>
  install_trans(); // if committed, copy from log to disk
801042bb:	e8 5b fe ff ff       	call   8010411b <install_trans>
  log.lh.n = 0;
801042c0:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
801042c7:	00 00 00 
  write_head(); // clear the log
801042ca:	e8 66 ff ff ff       	call   80104235 <write_head>
}
801042cf:	c9                   	leave  
801042d0:	c3                   	ret    

801042d1 <begin_trans>:

void
begin_trans(void)
{
801042d1:	55                   	push   %ebp
801042d2:	89 e5                	mov    %esp,%ebp
801042d4:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801042d7:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801042de:	e8 74 19 00 00       	call   80105c57 <acquire>
  while (log.busy) {
801042e3:	eb 14                	jmp    801042f9 <begin_trans+0x28>
    sleep(&log, &log.lock);
801042e5:	c7 44 24 04 c0 08 11 	movl   $0x801108c0,0x4(%esp)
801042ec:	80 
801042ed:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801042f4:	e8 80 16 00 00       	call   80105979 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801042f9:	a1 fc 08 11 80       	mov    0x801108fc,%eax
801042fe:	85 c0                	test   %eax,%eax
80104300:	75 e3                	jne    801042e5 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80104302:	c7 05 fc 08 11 80 01 	movl   $0x1,0x801108fc
80104309:	00 00 00 
  release(&log.lock);
8010430c:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104313:	e8 a1 19 00 00       	call   80105cb9 <release>
}
80104318:	c9                   	leave  
80104319:	c3                   	ret    

8010431a <commit_trans>:

void
commit_trans(void)
{
8010431a:	55                   	push   %ebp
8010431b:	89 e5                	mov    %esp,%ebp
8010431d:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80104320:	a1 04 09 11 80       	mov    0x80110904,%eax
80104325:	85 c0                	test   %eax,%eax
80104327:	7e 19                	jle    80104342 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80104329:	e8 07 ff ff ff       	call   80104235 <write_head>
    install_trans(); // Now install writes to home locations
8010432e:	e8 e8 fd ff ff       	call   8010411b <install_trans>
    log.lh.n = 0; 
80104333:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
8010433a:	00 00 00 
    write_head();    // Erase the transaction from the log
8010433d:	e8 f3 fe ff ff       	call   80104235 <write_head>
  }
  
  acquire(&log.lock);
80104342:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104349:	e8 09 19 00 00       	call   80105c57 <acquire>
  log.busy = 0;
8010434e:	c7 05 fc 08 11 80 00 	movl   $0x0,0x801108fc
80104355:	00 00 00 
  wakeup(&log);
80104358:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010435f:	e8 ee 16 00 00       	call   80105a52 <wakeup>
  release(&log.lock);
80104364:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010436b:	e8 49 19 00 00       	call   80105cb9 <release>
}
80104370:	c9                   	leave  
80104371:	c3                   	ret    

80104372 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80104372:	55                   	push   %ebp
80104373:	89 e5                	mov    %esp,%ebp
80104375:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80104378:	a1 04 09 11 80       	mov    0x80110904,%eax
8010437d:	83 f8 09             	cmp    $0x9,%eax
80104380:	7f 12                	jg     80104394 <log_write+0x22>
80104382:	a1 04 09 11 80       	mov    0x80110904,%eax
80104387:	8b 15 f8 08 11 80    	mov    0x801108f8,%edx
8010438d:	83 ea 01             	sub    $0x1,%edx
80104390:	39 d0                	cmp    %edx,%eax
80104392:	7c 0c                	jl     801043a0 <log_write+0x2e>
    panic("too big a transaction");
80104394:	c7 04 24 10 97 10 80 	movl   $0x80109710,(%esp)
8010439b:	e8 9d c1 ff ff       	call   8010053d <panic>
  if (!log.busy)
801043a0:	a1 fc 08 11 80       	mov    0x801108fc,%eax
801043a5:	85 c0                	test   %eax,%eax
801043a7:	75 0c                	jne    801043b5 <log_write+0x43>
    panic("write outside of trans");
801043a9:	c7 04 24 26 97 10 80 	movl   $0x80109726,(%esp)
801043b0:	e8 88 c1 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801043b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043bc:	eb 1d                	jmp    801043db <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
801043be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c1:	83 c0 10             	add    $0x10,%eax
801043c4:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
801043cb:	89 c2                	mov    %eax,%edx
801043cd:	8b 45 08             	mov    0x8(%ebp),%eax
801043d0:	8b 40 08             	mov    0x8(%eax),%eax
801043d3:	39 c2                	cmp    %eax,%edx
801043d5:	74 10                	je     801043e7 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801043d7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043db:	a1 04 09 11 80       	mov    0x80110904,%eax
801043e0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801043e3:	7f d9                	jg     801043be <log_write+0x4c>
801043e5:	eb 01                	jmp    801043e8 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801043e7:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801043e8:	8b 45 08             	mov    0x8(%ebp),%eax
801043eb:	8b 40 08             	mov    0x8(%eax),%eax
801043ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043f1:	83 c2 10             	add    $0x10,%edx
801043f4:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801043fb:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104400:	03 45 f4             	add    -0xc(%ebp),%eax
80104403:	83 c0 01             	add    $0x1,%eax
80104406:	89 c2                	mov    %eax,%edx
80104408:	8b 45 08             	mov    0x8(%ebp),%eax
8010440b:	8b 40 04             	mov    0x4(%eax),%eax
8010440e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104412:	89 04 24             	mov    %eax,(%esp)
80104415:	e8 8c bd ff ff       	call   801001a6 <bread>
8010441a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
8010441d:	8b 45 08             	mov    0x8(%ebp),%eax
80104420:	8d 50 18             	lea    0x18(%eax),%edx
80104423:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104426:	83 c0 18             	add    $0x18,%eax
80104429:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104430:	00 
80104431:	89 54 24 04          	mov    %edx,0x4(%esp)
80104435:	89 04 24             	mov    %eax,(%esp)
80104438:	e8 3c 1b 00 00       	call   80105f79 <memmove>
  bwrite(lbuf);
8010443d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104440:	89 04 24             	mov    %eax,(%esp)
80104443:	e8 95 bd ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80104448:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010444b:	89 04 24             	mov    %eax,(%esp)
8010444e:	e8 c4 bd ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80104453:	a1 04 09 11 80       	mov    0x80110904,%eax
80104458:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010445b:	75 0d                	jne    8010446a <log_write+0xf8>
    log.lh.n++;
8010445d:	a1 04 09 11 80       	mov    0x80110904,%eax
80104462:	83 c0 01             	add    $0x1,%eax
80104465:	a3 04 09 11 80       	mov    %eax,0x80110904
  b->flags |= B_DIRTY; // XXX prevent eviction
8010446a:	8b 45 08             	mov    0x8(%ebp),%eax
8010446d:	8b 00                	mov    (%eax),%eax
8010446f:	89 c2                	mov    %eax,%edx
80104471:	83 ca 04             	or     $0x4,%edx
80104474:	8b 45 08             	mov    0x8(%ebp),%eax
80104477:	89 10                	mov    %edx,(%eax)
}
80104479:	c9                   	leave  
8010447a:	c3                   	ret    
	...

8010447c <v2p>:
8010447c:	55                   	push   %ebp
8010447d:	89 e5                	mov    %esp,%ebp
8010447f:	8b 45 08             	mov    0x8(%ebp),%eax
80104482:	05 00 00 00 80       	add    $0x80000000,%eax
80104487:	5d                   	pop    %ebp
80104488:	c3                   	ret    

80104489 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80104489:	55                   	push   %ebp
8010448a:	89 e5                	mov    %esp,%ebp
8010448c:	8b 45 08             	mov    0x8(%ebp),%eax
8010448f:	05 00 00 00 80       	add    $0x80000000,%eax
80104494:	5d                   	pop    %ebp
80104495:	c3                   	ret    

80104496 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104496:	55                   	push   %ebp
80104497:	89 e5                	mov    %esp,%ebp
80104499:	53                   	push   %ebx
8010449a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
8010449d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801044a0:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801044a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801044a6:	89 c3                	mov    %eax,%ebx
801044a8:	89 d8                	mov    %ebx,%eax
801044aa:	f0 87 02             	lock xchg %eax,(%edx)
801044ad:	89 c3                	mov    %eax,%ebx
801044af:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801044b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801044b5:	83 c4 10             	add    $0x10,%esp
801044b8:	5b                   	pop    %ebx
801044b9:	5d                   	pop    %ebp
801044ba:	c3                   	ret    

801044bb <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801044bb:	55                   	push   %ebp
801044bc:	89 e5                	mov    %esp,%ebp
801044be:	83 e4 f0             	and    $0xfffffff0,%esp
801044c1:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801044c4:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801044cb:	80 
801044cc:	c7 04 24 3c 37 11 80 	movl   $0x8011373c,(%esp)
801044d3:	e8 ad f5 ff ff       	call   80103a85 <kinit1>
  kvmalloc();      // kernel page table
801044d8:	e8 6d 47 00 00       	call   80108c4a <kvmalloc>
  mpinit();        // collect info about this machine
801044dd:	e8 63 04 00 00       	call   80104945 <mpinit>
  lapicinit(mpbcpu());
801044e2:	e8 2e 02 00 00       	call   80104715 <mpbcpu>
801044e7:	89 04 24             	mov    %eax,(%esp)
801044ea:	e8 f5 f8 ff ff       	call   80103de4 <lapicinit>
  seginit();       // set up segments
801044ef:	e8 f9 40 00 00       	call   801085ed <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801044f4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801044fa:	0f b6 00             	movzbl (%eax),%eax
801044fd:	0f b6 c0             	movzbl %al,%eax
80104500:	89 44 24 04          	mov    %eax,0x4(%esp)
80104504:	c7 04 24 3d 97 10 80 	movl   $0x8010973d,(%esp)
8010450b:	e8 91 be ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104510:	e8 95 06 00 00       	call   80104baa <picinit>
  ioapicinit();    // another interrupt controller
80104515:	e8 5b f4 ff ff       	call   80103975 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010451a:	e8 6e c5 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
8010451f:	e8 14 34 00 00       	call   80107938 <uartinit>
  pinit();         // process table
80104524:	e8 96 0b 00 00       	call   801050bf <pinit>
  tvinit();        // trap vectors
80104529:	e8 ad 2f 00 00       	call   801074db <tvinit>
  binit();         // buffer cache
8010452e:	e8 01 bb ff ff       	call   80100034 <binit>
  fileinit();      // file table
80104533:	e8 c8 c9 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80104538:	e8 16 de ff ff       	call   80102353 <iinit>
  ideinit();       // disk
8010453d:	e8 98 f0 ff ff       	call   801035da <ideinit>
  if(!ismp)
80104542:	a1 44 09 11 80       	mov    0x80110944,%eax
80104547:	85 c0                	test   %eax,%eax
80104549:	75 05                	jne    80104550 <main+0x95>
    timerinit();   // uniprocessor timer
8010454b:	e8 ce 2e 00 00       	call   8010741e <timerinit>
  startothers();   // start other processors
80104550:	e8 87 00 00 00       	call   801045dc <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104555:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
8010455c:	8e 
8010455d:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104564:	e8 54 f5 ff ff       	call   80103abd <kinit2>
  userinit();      // first user process
80104569:	e8 6c 0c 00 00       	call   801051da <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010456e:	e8 22 00 00 00       	call   80104595 <mpmain>

80104573 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80104573:	55                   	push   %ebp
80104574:	89 e5                	mov    %esp,%ebp
80104576:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80104579:	e8 e3 46 00 00       	call   80108c61 <switchkvm>
  seginit();
8010457e:	e8 6a 40 00 00       	call   801085ed <seginit>
  lapicinit(cpunum());
80104583:	e8 b9 f9 ff ff       	call   80103f41 <cpunum>
80104588:	89 04 24             	mov    %eax,(%esp)
8010458b:	e8 54 f8 ff ff       	call   80103de4 <lapicinit>
  mpmain();
80104590:	e8 00 00 00 00       	call   80104595 <mpmain>

80104595 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104595:	55                   	push   %ebp
80104596:	89 e5                	mov    %esp,%ebp
80104598:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010459b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801045a1:	0f b6 00             	movzbl (%eax),%eax
801045a4:	0f b6 c0             	movzbl %al,%eax
801045a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801045ab:	c7 04 24 54 97 10 80 	movl   $0x80109754,(%esp)
801045b2:	e8 ea bd ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801045b7:	e8 93 30 00 00       	call   8010764f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801045bc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801045c2:	05 a8 00 00 00       	add    $0xa8,%eax
801045c7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801045ce:	00 
801045cf:	89 04 24             	mov    %eax,(%esp)
801045d2:	e8 bf fe ff ff       	call   80104496 <xchg>
  scheduler();     // start running processes
801045d7:	e8 f4 11 00 00       	call   801057d0 <scheduler>

801045dc <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801045dc:	55                   	push   %ebp
801045dd:	89 e5                	mov    %esp,%ebp
801045df:	53                   	push   %ebx
801045e0:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801045e3:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801045ea:	e8 9a fe ff ff       	call   80104489 <p2v>
801045ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801045f2:	b8 8a 00 00 00       	mov    $0x8a,%eax
801045f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801045fb:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80104602:	80 
80104603:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104606:	89 04 24             	mov    %eax,(%esp)
80104609:	e8 6b 19 00 00       	call   80105f79 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010460e:	c7 45 f4 60 09 11 80 	movl   $0x80110960,-0xc(%ebp)
80104615:	e9 86 00 00 00       	jmp    801046a0 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010461a:	e8 22 f9 ff ff       	call   80103f41 <cpunum>
8010461f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104625:	05 60 09 11 80       	add    $0x80110960,%eax
8010462a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010462d:	74 69                	je     80104698 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010462f:	e8 7f f5 ff ff       	call   80103bb3 <kalloc>
80104634:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104637:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010463a:	83 e8 04             	sub    $0x4,%eax
8010463d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104640:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104646:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010464b:	83 e8 08             	sub    $0x8,%eax
8010464e:	c7 00 73 45 10 80    	movl   $0x80104573,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104654:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104657:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010465a:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104661:	e8 16 fe ff ff       	call   8010447c <v2p>
80104666:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104668:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010466b:	89 04 24             	mov    %eax,(%esp)
8010466e:	e8 09 fe ff ff       	call   8010447c <v2p>
80104673:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104676:	0f b6 12             	movzbl (%edx),%edx
80104679:	0f b6 d2             	movzbl %dl,%edx
8010467c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104680:	89 14 24             	mov    %edx,(%esp)
80104683:	e8 3f f9 ff ff       	call   80103fc7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104688:	90                   	nop
80104689:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010468c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104692:	85 c0                	test   %eax,%eax
80104694:	74 f3                	je     80104689 <startothers+0xad>
80104696:	eb 01                	jmp    80104699 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80104698:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104699:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801046a0:	a1 40 0f 11 80       	mov    0x80110f40,%eax
801046a5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801046ab:	05 60 09 11 80       	add    $0x80110960,%eax
801046b0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801046b3:	0f 87 61 ff ff ff    	ja     8010461a <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801046b9:	83 c4 24             	add    $0x24,%esp
801046bc:	5b                   	pop    %ebx
801046bd:	5d                   	pop    %ebp
801046be:	c3                   	ret    
	...

801046c0 <p2v>:
801046c0:	55                   	push   %ebp
801046c1:	89 e5                	mov    %esp,%ebp
801046c3:	8b 45 08             	mov    0x8(%ebp),%eax
801046c6:	05 00 00 00 80       	add    $0x80000000,%eax
801046cb:	5d                   	pop    %ebp
801046cc:	c3                   	ret    

801046cd <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801046cd:	55                   	push   %ebp
801046ce:	89 e5                	mov    %esp,%ebp
801046d0:	53                   	push   %ebx
801046d1:	83 ec 14             	sub    $0x14,%esp
801046d4:	8b 45 08             	mov    0x8(%ebp),%eax
801046d7:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801046db:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801046df:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801046e3:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801046e7:	ec                   	in     (%dx),%al
801046e8:	89 c3                	mov    %eax,%ebx
801046ea:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801046ed:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801046f1:	83 c4 14             	add    $0x14,%esp
801046f4:	5b                   	pop    %ebx
801046f5:	5d                   	pop    %ebp
801046f6:	c3                   	ret    

801046f7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801046f7:	55                   	push   %ebp
801046f8:	89 e5                	mov    %esp,%ebp
801046fa:	83 ec 08             	sub    $0x8,%esp
801046fd:	8b 55 08             	mov    0x8(%ebp),%edx
80104700:	8b 45 0c             	mov    0xc(%ebp),%eax
80104703:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104707:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010470a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010470e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104712:	ee                   	out    %al,(%dx)
}
80104713:	c9                   	leave  
80104714:	c3                   	ret    

80104715 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104715:	55                   	push   %ebp
80104716:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104718:	a1 64 c6 10 80       	mov    0x8010c664,%eax
8010471d:	89 c2                	mov    %eax,%edx
8010471f:	b8 60 09 11 80       	mov    $0x80110960,%eax
80104724:	89 d1                	mov    %edx,%ecx
80104726:	29 c1                	sub    %eax,%ecx
80104728:	89 c8                	mov    %ecx,%eax
8010472a:	c1 f8 02             	sar    $0x2,%eax
8010472d:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104733:	5d                   	pop    %ebp
80104734:	c3                   	ret    

80104735 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104735:	55                   	push   %ebp
80104736:	89 e5                	mov    %esp,%ebp
80104738:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010473b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104742:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104749:	eb 13                	jmp    8010475e <sum+0x29>
    sum += addr[i];
8010474b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010474e:	03 45 08             	add    0x8(%ebp),%eax
80104751:	0f b6 00             	movzbl (%eax),%eax
80104754:	0f b6 c0             	movzbl %al,%eax
80104757:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010475a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010475e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104761:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104764:	7c e5                	jl     8010474b <sum+0x16>
    sum += addr[i];
  return sum;
80104766:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104769:	c9                   	leave  
8010476a:	c3                   	ret    

8010476b <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010476b:	55                   	push   %ebp
8010476c:	89 e5                	mov    %esp,%ebp
8010476e:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104771:	8b 45 08             	mov    0x8(%ebp),%eax
80104774:	89 04 24             	mov    %eax,(%esp)
80104777:	e8 44 ff ff ff       	call   801046c0 <p2v>
8010477c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010477f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104782:	03 45 f0             	add    -0x10(%ebp),%eax
80104785:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104788:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010478b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010478e:	eb 3f                	jmp    801047cf <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104790:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104797:	00 
80104798:	c7 44 24 04 68 97 10 	movl   $0x80109768,0x4(%esp)
8010479f:	80 
801047a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047a3:	89 04 24             	mov    %eax,(%esp)
801047a6:	e8 72 17 00 00       	call   80105f1d <memcmp>
801047ab:	85 c0                	test   %eax,%eax
801047ad:	75 1c                	jne    801047cb <mpsearch1+0x60>
801047af:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801047b6:	00 
801047b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ba:	89 04 24             	mov    %eax,(%esp)
801047bd:	e8 73 ff ff ff       	call   80104735 <sum>
801047c2:	84 c0                	test   %al,%al
801047c4:	75 05                	jne    801047cb <mpsearch1+0x60>
      return (struct mp*)p;
801047c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c9:	eb 11                	jmp    801047dc <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801047cb:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801047cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801047d5:	72 b9                	jb     80104790 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801047d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047dc:	c9                   	leave  
801047dd:	c3                   	ret    

801047de <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801047de:	55                   	push   %ebp
801047df:	89 e5                	mov    %esp,%ebp
801047e1:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801047e4:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801047eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ee:	83 c0 0f             	add    $0xf,%eax
801047f1:	0f b6 00             	movzbl (%eax),%eax
801047f4:	0f b6 c0             	movzbl %al,%eax
801047f7:	89 c2                	mov    %eax,%edx
801047f9:	c1 e2 08             	shl    $0x8,%edx
801047fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ff:	83 c0 0e             	add    $0xe,%eax
80104802:	0f b6 00             	movzbl (%eax),%eax
80104805:	0f b6 c0             	movzbl %al,%eax
80104808:	09 d0                	or     %edx,%eax
8010480a:	c1 e0 04             	shl    $0x4,%eax
8010480d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104810:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104814:	74 21                	je     80104837 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104816:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010481d:	00 
8010481e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104821:	89 04 24             	mov    %eax,(%esp)
80104824:	e8 42 ff ff ff       	call   8010476b <mpsearch1>
80104829:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010482c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104830:	74 50                	je     80104882 <mpsearch+0xa4>
      return mp;
80104832:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104835:	eb 5f                	jmp    80104896 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483a:	83 c0 14             	add    $0x14,%eax
8010483d:	0f b6 00             	movzbl (%eax),%eax
80104840:	0f b6 c0             	movzbl %al,%eax
80104843:	89 c2                	mov    %eax,%edx
80104845:	c1 e2 08             	shl    $0x8,%edx
80104848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010484b:	83 c0 13             	add    $0x13,%eax
8010484e:	0f b6 00             	movzbl (%eax),%eax
80104851:	0f b6 c0             	movzbl %al,%eax
80104854:	09 d0                	or     %edx,%eax
80104856:	c1 e0 0a             	shl    $0xa,%eax
80104859:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
8010485c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010485f:	2d 00 04 00 00       	sub    $0x400,%eax
80104864:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010486b:	00 
8010486c:	89 04 24             	mov    %eax,(%esp)
8010486f:	e8 f7 fe ff ff       	call   8010476b <mpsearch1>
80104874:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104877:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010487b:	74 05                	je     80104882 <mpsearch+0xa4>
      return mp;
8010487d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104880:	eb 14                	jmp    80104896 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104882:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104889:	00 
8010488a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104891:	e8 d5 fe ff ff       	call   8010476b <mpsearch1>
}
80104896:	c9                   	leave  
80104897:	c3                   	ret    

80104898 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104898:	55                   	push   %ebp
80104899:	89 e5                	mov    %esp,%ebp
8010489b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010489e:	e8 3b ff ff ff       	call   801047de <mpsearch>
801048a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801048a6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801048aa:	74 0a                	je     801048b6 <mpconfig+0x1e>
801048ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048af:	8b 40 04             	mov    0x4(%eax),%eax
801048b2:	85 c0                	test   %eax,%eax
801048b4:	75 0a                	jne    801048c0 <mpconfig+0x28>
    return 0;
801048b6:	b8 00 00 00 00       	mov    $0x0,%eax
801048bb:	e9 83 00 00 00       	jmp    80104943 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801048c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048c3:	8b 40 04             	mov    0x4(%eax),%eax
801048c6:	89 04 24             	mov    %eax,(%esp)
801048c9:	e8 f2 fd ff ff       	call   801046c0 <p2v>
801048ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801048d1:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801048d8:	00 
801048d9:	c7 44 24 04 6d 97 10 	movl   $0x8010976d,0x4(%esp)
801048e0:	80 
801048e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048e4:	89 04 24             	mov    %eax,(%esp)
801048e7:	e8 31 16 00 00       	call   80105f1d <memcmp>
801048ec:	85 c0                	test   %eax,%eax
801048ee:	74 07                	je     801048f7 <mpconfig+0x5f>
    return 0;
801048f0:	b8 00 00 00 00       	mov    $0x0,%eax
801048f5:	eb 4c                	jmp    80104943 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801048f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048fa:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801048fe:	3c 01                	cmp    $0x1,%al
80104900:	74 12                	je     80104914 <mpconfig+0x7c>
80104902:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104905:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104909:	3c 04                	cmp    $0x4,%al
8010490b:	74 07                	je     80104914 <mpconfig+0x7c>
    return 0;
8010490d:	b8 00 00 00 00       	mov    $0x0,%eax
80104912:	eb 2f                	jmp    80104943 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104914:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104917:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010491b:	0f b7 c0             	movzwl %ax,%eax
8010491e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104925:	89 04 24             	mov    %eax,(%esp)
80104928:	e8 08 fe ff ff       	call   80104735 <sum>
8010492d:	84 c0                	test   %al,%al
8010492f:	74 07                	je     80104938 <mpconfig+0xa0>
    return 0;
80104931:	b8 00 00 00 00       	mov    $0x0,%eax
80104936:	eb 0b                	jmp    80104943 <mpconfig+0xab>
  *pmp = mp;
80104938:	8b 45 08             	mov    0x8(%ebp),%eax
8010493b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010493e:	89 10                	mov    %edx,(%eax)
  return conf;
80104940:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104943:	c9                   	leave  
80104944:	c3                   	ret    

80104945 <mpinit>:

void
mpinit(void)
{
80104945:	55                   	push   %ebp
80104946:	89 e5                	mov    %esp,%ebp
80104948:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010494b:	c7 05 64 c6 10 80 60 	movl   $0x80110960,0x8010c664
80104952:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104955:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104958:	89 04 24             	mov    %eax,(%esp)
8010495b:	e8 38 ff ff ff       	call   80104898 <mpconfig>
80104960:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104963:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104967:	0f 84 9c 01 00 00    	je     80104b09 <mpinit+0x1c4>
    return;
  ismp = 1;
8010496d:	c7 05 44 09 11 80 01 	movl   $0x1,0x80110944
80104974:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104977:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010497a:	8b 40 24             	mov    0x24(%eax),%eax
8010497d:	a3 bc 08 11 80       	mov    %eax,0x801108bc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104982:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104985:	83 c0 2c             	add    $0x2c,%eax
80104988:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010498b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010498e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104992:	0f b7 c0             	movzwl %ax,%eax
80104995:	03 45 f0             	add    -0x10(%ebp),%eax
80104998:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010499b:	e9 f4 00 00 00       	jmp    80104a94 <mpinit+0x14f>
    switch(*p){
801049a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049a3:	0f b6 00             	movzbl (%eax),%eax
801049a6:	0f b6 c0             	movzbl %al,%eax
801049a9:	83 f8 04             	cmp    $0x4,%eax
801049ac:	0f 87 bf 00 00 00    	ja     80104a71 <mpinit+0x12c>
801049b2:	8b 04 85 b0 97 10 80 	mov    -0x7fef6850(,%eax,4),%eax
801049b9:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801049bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049be:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801049c1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801049c4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801049c8:	0f b6 d0             	movzbl %al,%edx
801049cb:	a1 40 0f 11 80       	mov    0x80110f40,%eax
801049d0:	39 c2                	cmp    %eax,%edx
801049d2:	74 2d                	je     80104a01 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801049d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801049d7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801049db:	0f b6 d0             	movzbl %al,%edx
801049de:	a1 40 0f 11 80       	mov    0x80110f40,%eax
801049e3:	89 54 24 08          	mov    %edx,0x8(%esp)
801049e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801049eb:	c7 04 24 72 97 10 80 	movl   $0x80109772,(%esp)
801049f2:	e8 aa b9 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801049f7:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
801049fe:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104a01:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104a04:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104a08:	0f b6 c0             	movzbl %al,%eax
80104a0b:	83 e0 02             	and    $0x2,%eax
80104a0e:	85 c0                	test   %eax,%eax
80104a10:	74 15                	je     80104a27 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104a12:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104a17:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104a1d:	05 60 09 11 80       	add    $0x80110960,%eax
80104a22:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104a27:	8b 15 40 0f 11 80    	mov    0x80110f40,%edx
80104a2d:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104a32:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104a38:	81 c2 60 09 11 80    	add    $0x80110960,%edx
80104a3e:	88 02                	mov    %al,(%edx)
      ncpu++;
80104a40:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104a45:	83 c0 01             	add    $0x1,%eax
80104a48:	a3 40 0f 11 80       	mov    %eax,0x80110f40
      p += sizeof(struct mpproc);
80104a4d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104a51:	eb 41                	jmp    80104a94 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104a59:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a5c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104a60:	a2 40 09 11 80       	mov    %al,0x80110940
      p += sizeof(struct mpioapic);
80104a65:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104a69:	eb 29                	jmp    80104a94 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104a6b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104a6f:	eb 23                	jmp    80104a94 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a74:	0f b6 00             	movzbl (%eax),%eax
80104a77:	0f b6 c0             	movzbl %al,%eax
80104a7a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a7e:	c7 04 24 90 97 10 80 	movl   $0x80109790,(%esp)
80104a85:	e8 17 b9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104a8a:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
80104a91:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104a94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a97:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104a9a:	0f 82 00 ff ff ff    	jb     801049a0 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104aa0:	a1 44 09 11 80       	mov    0x80110944,%eax
80104aa5:	85 c0                	test   %eax,%eax
80104aa7:	75 1d                	jne    80104ac6 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104aa9:	c7 05 40 0f 11 80 01 	movl   $0x1,0x80110f40
80104ab0:	00 00 00 
    lapic = 0;
80104ab3:	c7 05 bc 08 11 80 00 	movl   $0x0,0x801108bc
80104aba:	00 00 00 
    ioapicid = 0;
80104abd:	c6 05 40 09 11 80 00 	movb   $0x0,0x80110940
    return;
80104ac4:	eb 44                	jmp    80104b0a <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104ac6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ac9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104acd:	84 c0                	test   %al,%al
80104acf:	74 39                	je     80104b0a <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104ad1:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104ad8:	00 
80104ad9:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104ae0:	e8 12 fc ff ff       	call   801046f7 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104ae5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104aec:	e8 dc fb ff ff       	call   801046cd <inb>
80104af1:	83 c8 01             	or     $0x1,%eax
80104af4:	0f b6 c0             	movzbl %al,%eax
80104af7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104afb:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104b02:	e8 f0 fb ff ff       	call   801046f7 <outb>
80104b07:	eb 01                	jmp    80104b0a <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104b09:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104b0a:	c9                   	leave  
80104b0b:	c3                   	ret    

80104b0c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104b0c:	55                   	push   %ebp
80104b0d:	89 e5                	mov    %esp,%ebp
80104b0f:	83 ec 08             	sub    $0x8,%esp
80104b12:	8b 55 08             	mov    0x8(%ebp),%edx
80104b15:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b18:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104b1c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104b1f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104b23:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104b27:	ee                   	out    %al,(%dx)
}
80104b28:	c9                   	leave  
80104b29:	c3                   	ret    

80104b2a <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104b2a:	55                   	push   %ebp
80104b2b:	89 e5                	mov    %esp,%ebp
80104b2d:	83 ec 0c             	sub    $0xc,%esp
80104b30:	8b 45 08             	mov    0x8(%ebp),%eax
80104b33:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104b37:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104b3b:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104b41:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104b45:	0f b6 c0             	movzbl %al,%eax
80104b48:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b4c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104b53:	e8 b4 ff ff ff       	call   80104b0c <outb>
  outb(IO_PIC2+1, mask >> 8);
80104b58:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104b5c:	66 c1 e8 08          	shr    $0x8,%ax
80104b60:	0f b6 c0             	movzbl %al,%eax
80104b63:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b67:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104b6e:	e8 99 ff ff ff       	call   80104b0c <outb>
}
80104b73:	c9                   	leave  
80104b74:	c3                   	ret    

80104b75 <picenable>:

void
picenable(int irq)
{
80104b75:	55                   	push   %ebp
80104b76:	89 e5                	mov    %esp,%ebp
80104b78:	53                   	push   %ebx
80104b79:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104b7c:	8b 45 08             	mov    0x8(%ebp),%eax
80104b7f:	ba 01 00 00 00       	mov    $0x1,%edx
80104b84:	89 d3                	mov    %edx,%ebx
80104b86:	89 c1                	mov    %eax,%ecx
80104b88:	d3 e3                	shl    %cl,%ebx
80104b8a:	89 d8                	mov    %ebx,%eax
80104b8c:	89 c2                	mov    %eax,%edx
80104b8e:	f7 d2                	not    %edx
80104b90:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104b97:	21 d0                	and    %edx,%eax
80104b99:	0f b7 c0             	movzwl %ax,%eax
80104b9c:	89 04 24             	mov    %eax,(%esp)
80104b9f:	e8 86 ff ff ff       	call   80104b2a <picsetmask>
}
80104ba4:	83 c4 04             	add    $0x4,%esp
80104ba7:	5b                   	pop    %ebx
80104ba8:	5d                   	pop    %ebp
80104ba9:	c3                   	ret    

80104baa <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104baa:	55                   	push   %ebp
80104bab:	89 e5                	mov    %esp,%ebp
80104bad:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104bb0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104bb7:	00 
80104bb8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104bbf:	e8 48 ff ff ff       	call   80104b0c <outb>
  outb(IO_PIC2+1, 0xFF);
80104bc4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104bcb:	00 
80104bcc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104bd3:	e8 34 ff ff ff       	call   80104b0c <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104bd8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104bdf:	00 
80104be0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104be7:	e8 20 ff ff ff       	call   80104b0c <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104bec:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104bf3:	00 
80104bf4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104bfb:	e8 0c ff ff ff       	call   80104b0c <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104c00:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104c07:	00 
80104c08:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104c0f:	e8 f8 fe ff ff       	call   80104b0c <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104c14:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104c1b:	00 
80104c1c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104c23:	e8 e4 fe ff ff       	call   80104b0c <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104c28:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104c2f:	00 
80104c30:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104c37:	e8 d0 fe ff ff       	call   80104b0c <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104c3c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104c43:	00 
80104c44:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104c4b:	e8 bc fe ff ff       	call   80104b0c <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104c50:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104c57:	00 
80104c58:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104c5f:	e8 a8 fe ff ff       	call   80104b0c <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104c64:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104c6b:	00 
80104c6c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104c73:	e8 94 fe ff ff       	call   80104b0c <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104c78:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104c7f:	00 
80104c80:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104c87:	e8 80 fe ff ff       	call   80104b0c <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104c8c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104c93:	00 
80104c94:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104c9b:	e8 6c fe ff ff       	call   80104b0c <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104ca0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104ca7:	00 
80104ca8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104caf:	e8 58 fe ff ff       	call   80104b0c <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104cb4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104cbb:	00 
80104cbc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104cc3:	e8 44 fe ff ff       	call   80104b0c <outb>

  if(irqmask != 0xFFFF)
80104cc8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ccf:	66 83 f8 ff          	cmp    $0xffff,%ax
80104cd3:	74 12                	je     80104ce7 <picinit+0x13d>
    picsetmask(irqmask);
80104cd5:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104cdc:	0f b7 c0             	movzwl %ax,%eax
80104cdf:	89 04 24             	mov    %eax,(%esp)
80104ce2:	e8 43 fe ff ff       	call   80104b2a <picsetmask>
}
80104ce7:	c9                   	leave  
80104ce8:	c3                   	ret    
80104ce9:	00 00                	add    %al,(%eax)
	...

80104cec <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104cec:	55                   	push   %ebp
80104ced:	89 e5                	mov    %esp,%ebp
80104cef:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104cf2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104cf9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cfc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104d02:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d05:	8b 10                	mov    (%eax),%edx
80104d07:	8b 45 08             	mov    0x8(%ebp),%eax
80104d0a:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104d0c:	e8 0b c2 ff ff       	call   80100f1c <filealloc>
80104d11:	8b 55 08             	mov    0x8(%ebp),%edx
80104d14:	89 02                	mov    %eax,(%edx)
80104d16:	8b 45 08             	mov    0x8(%ebp),%eax
80104d19:	8b 00                	mov    (%eax),%eax
80104d1b:	85 c0                	test   %eax,%eax
80104d1d:	0f 84 c8 00 00 00    	je     80104deb <pipealloc+0xff>
80104d23:	e8 f4 c1 ff ff       	call   80100f1c <filealloc>
80104d28:	8b 55 0c             	mov    0xc(%ebp),%edx
80104d2b:	89 02                	mov    %eax,(%edx)
80104d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d30:	8b 00                	mov    (%eax),%eax
80104d32:	85 c0                	test   %eax,%eax
80104d34:	0f 84 b1 00 00 00    	je     80104deb <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104d3a:	e8 74 ee ff ff       	call   80103bb3 <kalloc>
80104d3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104d42:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104d46:	0f 84 9e 00 00 00    	je     80104dea <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d4f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104d56:	00 00 00 
  p->writeopen = 1;
80104d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d5c:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104d63:	00 00 00 
  p->nwrite = 0;
80104d66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d69:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104d70:	00 00 00 
  p->nread = 0;
80104d73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d76:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104d7d:	00 00 00 
  initlock(&p->lock, "pipe");
80104d80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d83:	c7 44 24 04 c4 97 10 	movl   $0x801097c4,0x4(%esp)
80104d8a:	80 
80104d8b:	89 04 24             	mov    %eax,(%esp)
80104d8e:	e8 a3 0e 00 00       	call   80105c36 <initlock>
  (*f0)->type = FD_PIPE;
80104d93:	8b 45 08             	mov    0x8(%ebp),%eax
80104d96:	8b 00                	mov    (%eax),%eax
80104d98:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104d9e:	8b 45 08             	mov    0x8(%ebp),%eax
80104da1:	8b 00                	mov    (%eax),%eax
80104da3:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104da7:	8b 45 08             	mov    0x8(%ebp),%eax
80104daa:	8b 00                	mov    (%eax),%eax
80104dac:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104db0:	8b 45 08             	mov    0x8(%ebp),%eax
80104db3:	8b 00                	mov    (%eax),%eax
80104db5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104db8:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dbe:	8b 00                	mov    (%eax),%eax
80104dc0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104dc6:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dc9:	8b 00                	mov    (%eax),%eax
80104dcb:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104dd2:	8b 00                	mov    (%eax),%eax
80104dd4:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ddb:	8b 00                	mov    (%eax),%eax
80104ddd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104de0:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104de3:	b8 00 00 00 00       	mov    $0x0,%eax
80104de8:	eb 43                	jmp    80104e2d <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104dea:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104deb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104def:	74 0b                	je     80104dfc <pipealloc+0x110>
    kfree((char*)p);
80104df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104df4:	89 04 24             	mov    %eax,(%esp)
80104df7:	e8 1e ed ff ff       	call   80103b1a <kfree>
  if(*f0)
80104dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80104dff:	8b 00                	mov    (%eax),%eax
80104e01:	85 c0                	test   %eax,%eax
80104e03:	74 0d                	je     80104e12 <pipealloc+0x126>
    fileclose(*f0);
80104e05:	8b 45 08             	mov    0x8(%ebp),%eax
80104e08:	8b 00                	mov    (%eax),%eax
80104e0a:	89 04 24             	mov    %eax,(%esp)
80104e0d:	e8 b2 c1 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104e12:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e15:	8b 00                	mov    (%eax),%eax
80104e17:	85 c0                	test   %eax,%eax
80104e19:	74 0d                	je     80104e28 <pipealloc+0x13c>
    fileclose(*f1);
80104e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e1e:	8b 00                	mov    (%eax),%eax
80104e20:	89 04 24             	mov    %eax,(%esp)
80104e23:	e8 9c c1 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e2d:	c9                   	leave  
80104e2e:	c3                   	ret    

80104e2f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104e2f:	55                   	push   %ebp
80104e30:	89 e5                	mov    %esp,%ebp
80104e32:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104e35:	8b 45 08             	mov    0x8(%ebp),%eax
80104e38:	89 04 24             	mov    %eax,(%esp)
80104e3b:	e8 17 0e 00 00       	call   80105c57 <acquire>
  if(writable){
80104e40:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104e44:	74 1f                	je     80104e65 <pipeclose+0x36>
    p->writeopen = 0;
80104e46:	8b 45 08             	mov    0x8(%ebp),%eax
80104e49:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104e50:	00 00 00 
    wakeup(&p->nread);
80104e53:	8b 45 08             	mov    0x8(%ebp),%eax
80104e56:	05 34 02 00 00       	add    $0x234,%eax
80104e5b:	89 04 24             	mov    %eax,(%esp)
80104e5e:	e8 ef 0b 00 00       	call   80105a52 <wakeup>
80104e63:	eb 1d                	jmp    80104e82 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104e65:	8b 45 08             	mov    0x8(%ebp),%eax
80104e68:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104e6f:	00 00 00 
    wakeup(&p->nwrite);
80104e72:	8b 45 08             	mov    0x8(%ebp),%eax
80104e75:	05 38 02 00 00       	add    $0x238,%eax
80104e7a:	89 04 24             	mov    %eax,(%esp)
80104e7d:	e8 d0 0b 00 00       	call   80105a52 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104e82:	8b 45 08             	mov    0x8(%ebp),%eax
80104e85:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104e8b:	85 c0                	test   %eax,%eax
80104e8d:	75 25                	jne    80104eb4 <pipeclose+0x85>
80104e8f:	8b 45 08             	mov    0x8(%ebp),%eax
80104e92:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104e98:	85 c0                	test   %eax,%eax
80104e9a:	75 18                	jne    80104eb4 <pipeclose+0x85>
    release(&p->lock);
80104e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9f:	89 04 24             	mov    %eax,(%esp)
80104ea2:	e8 12 0e 00 00       	call   80105cb9 <release>
    kfree((char*)p);
80104ea7:	8b 45 08             	mov    0x8(%ebp),%eax
80104eaa:	89 04 24             	mov    %eax,(%esp)
80104ead:	e8 68 ec ff ff       	call   80103b1a <kfree>
80104eb2:	eb 0b                	jmp    80104ebf <pipeclose+0x90>
  } else
    release(&p->lock);
80104eb4:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb7:	89 04 24             	mov    %eax,(%esp)
80104eba:	e8 fa 0d 00 00       	call   80105cb9 <release>
}
80104ebf:	c9                   	leave  
80104ec0:	c3                   	ret    

80104ec1 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104ec1:	55                   	push   %ebp
80104ec2:	89 e5                	mov    %esp,%ebp
80104ec4:	53                   	push   %ebx
80104ec5:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104ec8:	8b 45 08             	mov    0x8(%ebp),%eax
80104ecb:	89 04 24             	mov    %eax,(%esp)
80104ece:	e8 84 0d 00 00       	call   80105c57 <acquire>
  for(i = 0; i < n; i++){
80104ed3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104eda:	e9 a6 00 00 00       	jmp    80104f85 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104edf:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee2:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104ee8:	85 c0                	test   %eax,%eax
80104eea:	74 0d                	je     80104ef9 <pipewrite+0x38>
80104eec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef2:	8b 40 24             	mov    0x24(%eax),%eax
80104ef5:	85 c0                	test   %eax,%eax
80104ef7:	74 15                	je     80104f0e <pipewrite+0x4d>
        release(&p->lock);
80104ef9:	8b 45 08             	mov    0x8(%ebp),%eax
80104efc:	89 04 24             	mov    %eax,(%esp)
80104eff:	e8 b5 0d 00 00       	call   80105cb9 <release>
        return -1;
80104f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f09:	e9 9d 00 00 00       	jmp    80104fab <pipewrite+0xea>
      }
      wakeup(&p->nread);
80104f0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f11:	05 34 02 00 00       	add    $0x234,%eax
80104f16:	89 04 24             	mov    %eax,(%esp)
80104f19:	e8 34 0b 00 00       	call   80105a52 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104f1e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f21:	8b 55 08             	mov    0x8(%ebp),%edx
80104f24:	81 c2 38 02 00 00    	add    $0x238,%edx
80104f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f2e:	89 14 24             	mov    %edx,(%esp)
80104f31:	e8 43 0a 00 00       	call   80105979 <sleep>
80104f36:	eb 01                	jmp    80104f39 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104f38:	90                   	nop
80104f39:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3c:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104f42:	8b 45 08             	mov    0x8(%ebp),%eax
80104f45:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104f4b:	05 00 02 00 00       	add    $0x200,%eax
80104f50:	39 c2                	cmp    %eax,%edx
80104f52:	74 8b                	je     80104edf <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104f54:	8b 45 08             	mov    0x8(%ebp),%eax
80104f57:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104f5d:	89 c3                	mov    %eax,%ebx
80104f5f:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104f65:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f68:	03 55 0c             	add    0xc(%ebp),%edx
80104f6b:	0f b6 0a             	movzbl (%edx),%ecx
80104f6e:	8b 55 08             	mov    0x8(%ebp),%edx
80104f71:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104f75:	8d 50 01             	lea    0x1(%eax),%edx
80104f78:	8b 45 08             	mov    0x8(%ebp),%eax
80104f7b:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104f81:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104f85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f88:	3b 45 10             	cmp    0x10(%ebp),%eax
80104f8b:	7c ab                	jl     80104f38 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104f8d:	8b 45 08             	mov    0x8(%ebp),%eax
80104f90:	05 34 02 00 00       	add    $0x234,%eax
80104f95:	89 04 24             	mov    %eax,(%esp)
80104f98:	e8 b5 0a 00 00       	call   80105a52 <wakeup>
  release(&p->lock);
80104f9d:	8b 45 08             	mov    0x8(%ebp),%eax
80104fa0:	89 04 24             	mov    %eax,(%esp)
80104fa3:	e8 11 0d 00 00       	call   80105cb9 <release>
  return n;
80104fa8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104fab:	83 c4 24             	add    $0x24,%esp
80104fae:	5b                   	pop    %ebx
80104faf:	5d                   	pop    %ebp
80104fb0:	c3                   	ret    

80104fb1 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104fb1:	55                   	push   %ebp
80104fb2:	89 e5                	mov    %esp,%ebp
80104fb4:	53                   	push   %ebx
80104fb5:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104fb8:	8b 45 08             	mov    0x8(%ebp),%eax
80104fbb:	89 04 24             	mov    %eax,(%esp)
80104fbe:	e8 94 0c 00 00       	call   80105c57 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104fc3:	eb 3a                	jmp    80104fff <piperead+0x4e>
    if(proc->killed){
80104fc5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fcb:	8b 40 24             	mov    0x24(%eax),%eax
80104fce:	85 c0                	test   %eax,%eax
80104fd0:	74 15                	je     80104fe7 <piperead+0x36>
      release(&p->lock);
80104fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd5:	89 04 24             	mov    %eax,(%esp)
80104fd8:	e8 dc 0c 00 00       	call   80105cb9 <release>
      return -1;
80104fdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe2:	e9 b6 00 00 00       	jmp    8010509d <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104fe7:	8b 45 08             	mov    0x8(%ebp),%eax
80104fea:	8b 55 08             	mov    0x8(%ebp),%edx
80104fed:	81 c2 34 02 00 00    	add    $0x234,%edx
80104ff3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ff7:	89 14 24             	mov    %edx,(%esp)
80104ffa:	e8 7a 09 00 00       	call   80105979 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104fff:	8b 45 08             	mov    0x8(%ebp),%eax
80105002:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80105008:	8b 45 08             	mov    0x8(%ebp),%eax
8010500b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105011:	39 c2                	cmp    %eax,%edx
80105013:	75 0d                	jne    80105022 <piperead+0x71>
80105015:	8b 45 08             	mov    0x8(%ebp),%eax
80105018:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010501e:	85 c0                	test   %eax,%eax
80105020:	75 a3                	jne    80104fc5 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105022:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105029:	eb 49                	jmp    80105074 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010502b:	8b 45 08             	mov    0x8(%ebp),%eax
8010502e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80105034:	8b 45 08             	mov    0x8(%ebp),%eax
80105037:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010503d:	39 c2                	cmp    %eax,%edx
8010503f:	74 3d                	je     8010507e <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80105041:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105044:	89 c2                	mov    %eax,%edx
80105046:	03 55 0c             	add    0xc(%ebp),%edx
80105049:	8b 45 08             	mov    0x8(%ebp),%eax
8010504c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80105052:	89 c3                	mov    %eax,%ebx
80105054:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010505a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010505d:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80105062:	88 0a                	mov    %cl,(%edx)
80105064:	8d 50 01             	lea    0x1(%eax),%edx
80105067:	8b 45 08             	mov    0x8(%ebp),%eax
8010506a:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105070:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105074:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105077:	3b 45 10             	cmp    0x10(%ebp),%eax
8010507a:	7c af                	jl     8010502b <piperead+0x7a>
8010507c:	eb 01                	jmp    8010507f <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
8010507e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010507f:	8b 45 08             	mov    0x8(%ebp),%eax
80105082:	05 38 02 00 00       	add    $0x238,%eax
80105087:	89 04 24             	mov    %eax,(%esp)
8010508a:	e8 c3 09 00 00       	call   80105a52 <wakeup>
  release(&p->lock);
8010508f:	8b 45 08             	mov    0x8(%ebp),%eax
80105092:	89 04 24             	mov    %eax,(%esp)
80105095:	e8 1f 0c 00 00       	call   80105cb9 <release>
  return i;
8010509a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010509d:	83 c4 24             	add    $0x24,%esp
801050a0:	5b                   	pop    %ebx
801050a1:	5d                   	pop    %ebp
801050a2:	c3                   	ret    
	...

801050a4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801050a4:	55                   	push   %ebp
801050a5:	89 e5                	mov    %esp,%ebp
801050a7:	53                   	push   %ebx
801050a8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801050ab:	9c                   	pushf  
801050ac:	5b                   	pop    %ebx
801050ad:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801050b0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801050b3:	83 c4 10             	add    $0x10,%esp
801050b6:	5b                   	pop    %ebx
801050b7:	5d                   	pop    %ebp
801050b8:	c3                   	ret    

801050b9 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801050b9:	55                   	push   %ebp
801050ba:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801050bc:	fb                   	sti    
}
801050bd:	5d                   	pop    %ebp
801050be:	c3                   	ret    

801050bf <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801050bf:	55                   	push   %ebp
801050c0:	89 e5                	mov    %esp,%ebp
801050c2:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801050c5:	c7 44 24 04 c9 97 10 	movl   $0x801097c9,0x4(%esp)
801050cc:	80 
801050cd:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801050d4:	e8 5d 0b 00 00       	call   80105c36 <initlock>
}
801050d9:	c9                   	leave  
801050da:	c3                   	ret    

801050db <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801050db:	55                   	push   %ebp
801050dc:	89 e5                	mov    %esp,%ebp
801050de:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801050e1:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801050e8:	e8 6a 0b 00 00       	call   80105c57 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801050ed:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
801050f4:	eb 0e                	jmp    80105104 <allocproc+0x29>
    if(p->state == UNUSED)
801050f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050f9:	8b 40 0c             	mov    0xc(%eax),%eax
801050fc:	85 c0                	test   %eax,%eax
801050fe:	74 23                	je     80105123 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105100:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105104:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
8010510b:	72 e9                	jb     801050f6 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010510d:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105114:	e8 a0 0b 00 00       	call   80105cb9 <release>
  return 0;
80105119:	b8 00 00 00 00       	mov    $0x0,%eax
8010511e:	e9 b5 00 00 00       	jmp    801051d8 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80105123:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80105124:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105127:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010512e:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80105133:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105136:	89 42 10             	mov    %eax,0x10(%edx)
80105139:	83 c0 01             	add    $0x1,%eax
8010513c:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80105141:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105148:	e8 6c 0b 00 00       	call   80105cb9 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010514d:	e8 61 ea ff ff       	call   80103bb3 <kalloc>
80105152:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105155:	89 42 08             	mov    %eax,0x8(%edx)
80105158:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515b:	8b 40 08             	mov    0x8(%eax),%eax
8010515e:	85 c0                	test   %eax,%eax
80105160:	75 11                	jne    80105173 <allocproc+0x98>
    p->state = UNUSED;
80105162:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105165:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
8010516c:	b8 00 00 00 00       	mov    $0x0,%eax
80105171:	eb 65                	jmp    801051d8 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80105173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105176:	8b 40 08             	mov    0x8(%eax),%eax
80105179:	05 00 10 00 00       	add    $0x1000,%eax
8010517e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80105181:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80105185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105188:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010518b:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010518e:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80105192:	ba 90 74 10 80       	mov    $0x80107490,%edx
80105197:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010519a:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010519c:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801051a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801051a6:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801051a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ac:	8b 40 1c             	mov    0x1c(%eax),%eax
801051af:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801051b6:	00 
801051b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801051be:	00 
801051bf:	89 04 24             	mov    %eax,(%esp)
801051c2:	e8 df 0c 00 00       	call   80105ea6 <memset>
  p->context->eip = (uint)forkret;
801051c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ca:	8b 40 1c             	mov    0x1c(%eax),%eax
801051cd:	ba 4d 59 10 80       	mov    $0x8010594d,%edx
801051d2:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801051d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801051d8:	c9                   	leave  
801051d9:	c3                   	ret    

801051da <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801051da:	55                   	push   %ebp
801051db:	89 e5                	mov    %esp,%ebp
801051dd:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801051e0:	e8 f6 fe ff ff       	call   801050db <allocproc>
801051e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801051e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051eb:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
801051f0:	c7 04 24 b3 3b 10 80 	movl   $0x80103bb3,(%esp)
801051f7:	e8 91 39 00 00       	call   80108b8d <setupkvm>
801051fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801051ff:	89 42 04             	mov    %eax,0x4(%edx)
80105202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105205:	8b 40 04             	mov    0x4(%eax),%eax
80105208:	85 c0                	test   %eax,%eax
8010520a:	75 0c                	jne    80105218 <userinit+0x3e>
    panic("userinit: out of memory?");
8010520c:	c7 04 24 d0 97 10 80 	movl   $0x801097d0,(%esp)
80105213:	e8 25 b3 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80105218:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010521d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105220:	8b 40 04             	mov    0x4(%eax),%eax
80105223:	89 54 24 08          	mov    %edx,0x8(%esp)
80105227:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
8010522e:	80 
8010522f:	89 04 24             	mov    %eax,(%esp)
80105232:	e8 ae 3b 00 00       	call   80108de5 <inituvm>
  p->sz = PGSIZE;
80105237:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010523a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80105240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105243:	8b 40 18             	mov    0x18(%eax),%eax
80105246:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010524d:	00 
8010524e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105255:	00 
80105256:	89 04 24             	mov    %eax,(%esp)
80105259:	e8 48 0c 00 00       	call   80105ea6 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010525e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105261:	8b 40 18             	mov    0x18(%eax),%eax
80105264:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010526a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010526d:	8b 40 18             	mov    0x18(%eax),%eax
80105270:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80105276:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105279:	8b 40 18             	mov    0x18(%eax),%eax
8010527c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010527f:	8b 52 18             	mov    0x18(%edx),%edx
80105282:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105286:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010528a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010528d:	8b 40 18             	mov    0x18(%eax),%eax
80105290:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105293:	8b 52 18             	mov    0x18(%edx),%edx
80105296:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010529a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010529e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a1:	8b 40 18             	mov    0x18(%eax),%eax
801052a4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801052ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ae:	8b 40 18             	mov    0x18(%eax),%eax
801052b1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801052b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052bb:	8b 40 18             	mov    0x18(%eax),%eax
801052be:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801052c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c8:	83 c0 6c             	add    $0x6c,%eax
801052cb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801052d2:	00 
801052d3:	c7 44 24 04 e9 97 10 	movl   $0x801097e9,0x4(%esp)
801052da:	80 
801052db:	89 04 24             	mov    %eax,(%esp)
801052de:	e8 f3 0d 00 00       	call   801060d6 <safestrcpy>
  p->cwd = namei("/");
801052e3:	c7 04 24 f2 97 10 80 	movl   $0x801097f2,(%esp)
801052ea:	e8 bb de ff ff       	call   801031aa <namei>
801052ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052f2:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801052f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801052ff:	c9                   	leave  
80105300:	c3                   	ret    

80105301 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80105301:	55                   	push   %ebp
80105302:	89 e5                	mov    %esp,%ebp
80105304:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105307:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010530d:	8b 00                	mov    (%eax),%eax
8010530f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105312:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105316:	7e 34                	jle    8010534c <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105318:	8b 45 08             	mov    0x8(%ebp),%eax
8010531b:	89 c2                	mov    %eax,%edx
8010531d:	03 55 f4             	add    -0xc(%ebp),%edx
80105320:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105326:	8b 40 04             	mov    0x4(%eax),%eax
80105329:	89 54 24 08          	mov    %edx,0x8(%esp)
8010532d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105330:	89 54 24 04          	mov    %edx,0x4(%esp)
80105334:	89 04 24             	mov    %eax,(%esp)
80105337:	e8 23 3c 00 00       	call   80108f5f <allocuvm>
8010533c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010533f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105343:	75 41                	jne    80105386 <growproc+0x85>
      return -1;
80105345:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010534a:	eb 58                	jmp    801053a4 <growproc+0xa3>
  } else if(n < 0){
8010534c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105350:	79 34                	jns    80105386 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80105352:	8b 45 08             	mov    0x8(%ebp),%eax
80105355:	89 c2                	mov    %eax,%edx
80105357:	03 55 f4             	add    -0xc(%ebp),%edx
8010535a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105360:	8b 40 04             	mov    0x4(%eax),%eax
80105363:	89 54 24 08          	mov    %edx,0x8(%esp)
80105367:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010536a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010536e:	89 04 24             	mov    %eax,(%esp)
80105371:	e8 c3 3c 00 00       	call   80109039 <deallocuvm>
80105376:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105379:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010537d:	75 07                	jne    80105386 <growproc+0x85>
      return -1;
8010537f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105384:	eb 1e                	jmp    801053a4 <growproc+0xa3>
  }
  proc->sz = sz;
80105386:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010538f:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105391:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105397:	89 04 24             	mov    %eax,(%esp)
8010539a:	e8 df 38 00 00       	call   80108c7e <switchuvm>
  return 0;
8010539f:	b8 00 00 00 00       	mov    $0x0,%eax
}
801053a4:	c9                   	leave  
801053a5:	c3                   	ret    

801053a6 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801053a6:	55                   	push   %ebp
801053a7:	89 e5                	mov    %esp,%ebp
801053a9:	57                   	push   %edi
801053aa:	56                   	push   %esi
801053ab:	53                   	push   %ebx
801053ac:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801053af:	e8 27 fd ff ff       	call   801050db <allocproc>
801053b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
801053b7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801053bb:	75 0a                	jne    801053c7 <fork+0x21>
    return -1;
801053bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053c2:	e9 3a 01 00 00       	jmp    80105501 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801053c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053cd:	8b 10                	mov    (%eax),%edx
801053cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d5:	8b 40 04             	mov    0x4(%eax),%eax
801053d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801053dc:	89 04 24             	mov    %eax,(%esp)
801053df:	e8 e5 3d 00 00       	call   801091c9 <copyuvm>
801053e4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801053e7:	89 42 04             	mov    %eax,0x4(%edx)
801053ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
801053ed:	8b 40 04             	mov    0x4(%eax),%eax
801053f0:	85 c0                	test   %eax,%eax
801053f2:	75 2c                	jne    80105420 <fork+0x7a>
    kfree(np->kstack);
801053f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801053f7:	8b 40 08             	mov    0x8(%eax),%eax
801053fa:	89 04 24             	mov    %eax,(%esp)
801053fd:	e8 18 e7 ff ff       	call   80103b1a <kfree>
    np->kstack = 0;
80105402:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105405:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010540c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010540f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105416:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010541b:	e9 e1 00 00 00       	jmp    80105501 <fork+0x15b>
  }
  np->sz = proc->sz;
80105420:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105426:	8b 10                	mov    (%eax),%edx
80105428:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010542b:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010542d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105434:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105437:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010543a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010543d:	8b 50 18             	mov    0x18(%eax),%edx
80105440:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105446:	8b 40 18             	mov    0x18(%eax),%eax
80105449:	89 c3                	mov    %eax,%ebx
8010544b:	b8 13 00 00 00       	mov    $0x13,%eax
80105450:	89 d7                	mov    %edx,%edi
80105452:	89 de                	mov    %ebx,%esi
80105454:	89 c1                	mov    %eax,%ecx
80105456:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80105458:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010545b:	8b 40 18             	mov    0x18(%eax),%eax
8010545e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105465:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010546c:	eb 3d                	jmp    801054ab <fork+0x105>
    if(proc->ofile[i])
8010546e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105474:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105477:	83 c2 08             	add    $0x8,%edx
8010547a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010547e:	85 c0                	test   %eax,%eax
80105480:	74 25                	je     801054a7 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105482:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105488:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010548b:	83 c2 08             	add    $0x8,%edx
8010548e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105492:	89 04 24             	mov    %eax,(%esp)
80105495:	e8 e2 ba ff ff       	call   80100f7c <filedup>
8010549a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010549d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801054a0:	83 c1 08             	add    $0x8,%ecx
801054a3:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801054a7:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801054ab:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801054af:	7e bd                	jle    8010546e <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801054b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b7:	8b 40 68             	mov    0x68(%eax),%eax
801054ba:	89 04 24             	mov    %eax,(%esp)
801054bd:	e8 14 d1 ff ff       	call   801025d6 <idup>
801054c2:	8b 55 e0             	mov    -0x20(%ebp),%edx
801054c5:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801054c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801054cb:	8b 40 10             	mov    0x10(%eax),%eax
801054ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801054d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801054d4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801054db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054e1:	8d 50 6c             	lea    0x6c(%eax),%edx
801054e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801054e7:	83 c0 6c             	add    $0x6c,%eax
801054ea:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801054f1:	00 
801054f2:	89 54 24 04          	mov    %edx,0x4(%esp)
801054f6:	89 04 24             	mov    %eax,(%esp)
801054f9:	e8 d8 0b 00 00       	call   801060d6 <safestrcpy>
  return pid;
801054fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80105501:	83 c4 2c             	add    $0x2c,%esp
80105504:	5b                   	pop    %ebx
80105505:	5e                   	pop    %esi
80105506:	5f                   	pop    %edi
80105507:	5d                   	pop    %ebp
80105508:	c3                   	ret    

80105509 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105509:	55                   	push   %ebp
8010550a:	89 e5                	mov    %esp,%ebp
8010550c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010550f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105516:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010551b:	39 c2                	cmp    %eax,%edx
8010551d:	75 0c                	jne    8010552b <exit+0x22>
    panic("init exiting");
8010551f:	c7 04 24 f4 97 10 80 	movl   $0x801097f4,(%esp)
80105526:	e8 12 b0 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010552b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105532:	eb 44                	jmp    80105578 <exit+0x6f>
    if(proc->ofile[fd]){
80105534:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010553d:	83 c2 08             	add    $0x8,%edx
80105540:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105544:	85 c0                	test   %eax,%eax
80105546:	74 2c                	je     80105574 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105548:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010554e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105551:	83 c2 08             	add    $0x8,%edx
80105554:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105558:	89 04 24             	mov    %eax,(%esp)
8010555b:	e8 64 ba ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105560:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105566:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105569:	83 c2 08             	add    $0x8,%edx
8010556c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105573:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105574:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105578:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010557c:	7e b6                	jle    80105534 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010557e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105584:	8b 40 68             	mov    0x68(%eax),%eax
80105587:	89 04 24             	mov    %eax,(%esp)
8010558a:	e8 2c d2 ff ff       	call   801027bb <iput>
  proc->cwd = 0;
8010558f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105595:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
8010559c:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801055a3:	e8 af 06 00 00       	call   80105c57 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801055a8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055ae:	8b 40 14             	mov    0x14(%eax),%eax
801055b1:	89 04 24             	mov    %eax,(%esp)
801055b4:	e8 5b 04 00 00       	call   80105a14 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055b9:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
801055c0:	eb 38                	jmp    801055fa <exit+0xf1>
    if(p->parent == proc){
801055c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055c5:	8b 50 14             	mov    0x14(%eax),%edx
801055c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055ce:	39 c2                	cmp    %eax,%edx
801055d0:	75 24                	jne    801055f6 <exit+0xed>
      p->parent = initproc;
801055d2:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801055d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055db:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801055de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e1:	8b 40 0c             	mov    0xc(%eax),%eax
801055e4:	83 f8 05             	cmp    $0x5,%eax
801055e7:	75 0d                	jne    801055f6 <exit+0xed>
        wakeup1(initproc);
801055e9:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801055ee:	89 04 24             	mov    %eax,(%esp)
801055f1:	e8 1e 04 00 00       	call   80105a14 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055f6:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801055fa:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105601:	72 bf                	jb     801055c2 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105603:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105609:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105610:	e8 54 02 00 00       	call   80105869 <sched>
  panic("zombie exit");
80105615:	c7 04 24 01 98 10 80 	movl   $0x80109801,(%esp)
8010561c:	e8 1c af ff ff       	call   8010053d <panic>

80105621 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105621:	55                   	push   %ebp
80105622:	89 e5                	mov    %esp,%ebp
80105624:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105627:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
8010562e:	e8 24 06 00 00       	call   80105c57 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105633:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010563a:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105641:	e9 9a 00 00 00       	jmp    801056e0 <wait+0xbf>
      if(p->parent != proc)
80105646:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105649:	8b 50 14             	mov    0x14(%eax),%edx
8010564c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105652:	39 c2                	cmp    %eax,%edx
80105654:	0f 85 81 00 00 00    	jne    801056db <wait+0xba>
        continue;
      havekids = 1;
8010565a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105661:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105664:	8b 40 0c             	mov    0xc(%eax),%eax
80105667:	83 f8 05             	cmp    $0x5,%eax
8010566a:	75 70                	jne    801056dc <wait+0xbb>
        // Found one.
        pid = p->pid;
8010566c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010566f:	8b 40 10             	mov    0x10(%eax),%eax
80105672:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105678:	8b 40 08             	mov    0x8(%eax),%eax
8010567b:	89 04 24             	mov    %eax,(%esp)
8010567e:	e8 97 e4 ff ff       	call   80103b1a <kfree>
        p->kstack = 0;
80105683:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105686:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
8010568d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105690:	8b 40 04             	mov    0x4(%eax),%eax
80105693:	89 04 24             	mov    %eax,(%esp)
80105696:	e8 5a 3a 00 00       	call   801090f5 <freevm>
        p->state = UNUSED;
8010569b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010569e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801056a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056a8:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801056af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056b2:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801056b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056bc:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801056c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c3:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801056ca:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801056d1:	e8 e3 05 00 00       	call   80105cb9 <release>
        return pid;
801056d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801056d9:	eb 53                	jmp    8010572e <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801056db:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801056dc:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801056e0:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
801056e7:	0f 82 59 ff ff ff    	jb     80105646 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801056ed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801056f1:	74 0d                	je     80105700 <wait+0xdf>
801056f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f9:	8b 40 24             	mov    0x24(%eax),%eax
801056fc:	85 c0                	test   %eax,%eax
801056fe:	74 13                	je     80105713 <wait+0xf2>
      release(&ptable.lock);
80105700:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105707:	e8 ad 05 00 00       	call   80105cb9 <release>
      return -1;
8010570c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105711:	eb 1b                	jmp    8010572e <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105713:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105719:	c7 44 24 04 60 0f 11 	movl   $0x80110f60,0x4(%esp)
80105720:	80 
80105721:	89 04 24             	mov    %eax,(%esp)
80105724:	e8 50 02 00 00       	call   80105979 <sleep>
  }
80105729:	e9 05 ff ff ff       	jmp    80105633 <wait+0x12>
}
8010572e:	c9                   	leave  
8010572f:	c3                   	ret    

80105730 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105730:	55                   	push   %ebp
80105731:	89 e5                	mov    %esp,%ebp
80105733:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80105736:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010573c:	8b 40 18             	mov    0x18(%eax),%eax
8010573f:	8b 40 44             	mov    0x44(%eax),%eax
80105742:	89 c2                	mov    %eax,%edx
80105744:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010574a:	8b 40 04             	mov    0x4(%eax),%eax
8010574d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105751:	89 04 24             	mov    %eax,(%esp)
80105754:	e8 81 3b 00 00       	call   801092da <uva2ka>
80105759:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
8010575c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105762:	8b 40 18             	mov    0x18(%eax),%eax
80105765:	8b 40 44             	mov    0x44(%eax),%eax
80105768:	25 ff 0f 00 00       	and    $0xfff,%eax
8010576d:	85 c0                	test   %eax,%eax
8010576f:	75 0c                	jne    8010577d <register_handler+0x4d>
    panic("esp_offset == 0");
80105771:	c7 04 24 0d 98 10 80 	movl   $0x8010980d,(%esp)
80105778:	e8 c0 ad ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
8010577d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105783:	8b 40 18             	mov    0x18(%eax),%eax
80105786:	8b 40 44             	mov    0x44(%eax),%eax
80105789:	83 e8 04             	sub    $0x4,%eax
8010578c:	25 ff 0f 00 00       	and    $0xfff,%eax
80105791:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105794:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010579b:	8b 52 18             	mov    0x18(%edx),%edx
8010579e:	8b 52 38             	mov    0x38(%edx),%edx
801057a1:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801057a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a9:	8b 40 18             	mov    0x18(%eax),%eax
801057ac:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801057b3:	8b 52 18             	mov    0x18(%edx),%edx
801057b6:	8b 52 44             	mov    0x44(%edx),%edx
801057b9:	83 ea 04             	sub    $0x4,%edx
801057bc:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801057bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057c5:	8b 40 18             	mov    0x18(%eax),%eax
801057c8:	8b 55 08             	mov    0x8(%ebp),%edx
801057cb:	89 50 38             	mov    %edx,0x38(%eax)
}
801057ce:	c9                   	leave  
801057cf:	c3                   	ret    

801057d0 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801057d0:	55                   	push   %ebp
801057d1:	89 e5                	mov    %esp,%ebp
801057d3:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801057d6:	e8 de f8 ff ff       	call   801050b9 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801057db:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801057e2:	e8 70 04 00 00       	call   80105c57 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057e7:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
801057ee:	eb 5f                	jmp    8010584f <scheduler+0x7f>
      if(p->state != RUNNABLE)
801057f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f3:	8b 40 0c             	mov    0xc(%eax),%eax
801057f6:	83 f8 03             	cmp    $0x3,%eax
801057f9:	75 4f                	jne    8010584a <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801057fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057fe:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105807:	89 04 24             	mov    %eax,(%esp)
8010580a:	e8 6f 34 00 00       	call   80108c7e <switchuvm>
      p->state = RUNNING;
8010580f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105812:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105819:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010581f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105822:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105829:	83 c2 04             	add    $0x4,%edx
8010582c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105830:	89 14 24             	mov    %edx,(%esp)
80105833:	e8 14 09 00 00       	call   8010614c <swtch>
      switchkvm();
80105838:	e8 24 34 00 00       	call   80108c61 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
8010583d:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105844:	00 00 00 00 
80105848:	eb 01                	jmp    8010584b <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010584a:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010584b:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010584f:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105856:	72 98                	jb     801057f0 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105858:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
8010585f:	e8 55 04 00 00       	call   80105cb9 <release>

  }
80105864:	e9 6d ff ff ff       	jmp    801057d6 <scheduler+0x6>

80105869 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105869:	55                   	push   %ebp
8010586a:	89 e5                	mov    %esp,%ebp
8010586c:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010586f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105876:	e8 fa 04 00 00       	call   80105d75 <holding>
8010587b:	85 c0                	test   %eax,%eax
8010587d:	75 0c                	jne    8010588b <sched+0x22>
    panic("sched ptable.lock");
8010587f:	c7 04 24 1d 98 10 80 	movl   $0x8010981d,(%esp)
80105886:	e8 b2 ac ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
8010588b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105891:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105897:	83 f8 01             	cmp    $0x1,%eax
8010589a:	74 0c                	je     801058a8 <sched+0x3f>
    panic("sched locks");
8010589c:	c7 04 24 2f 98 10 80 	movl   $0x8010982f,(%esp)
801058a3:	e8 95 ac ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801058a8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ae:	8b 40 0c             	mov    0xc(%eax),%eax
801058b1:	83 f8 04             	cmp    $0x4,%eax
801058b4:	75 0c                	jne    801058c2 <sched+0x59>
    panic("sched running");
801058b6:	c7 04 24 3b 98 10 80 	movl   $0x8010983b,(%esp)
801058bd:	e8 7b ac ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801058c2:	e8 dd f7 ff ff       	call   801050a4 <readeflags>
801058c7:	25 00 02 00 00       	and    $0x200,%eax
801058cc:	85 c0                	test   %eax,%eax
801058ce:	74 0c                	je     801058dc <sched+0x73>
    panic("sched interruptible");
801058d0:	c7 04 24 49 98 10 80 	movl   $0x80109849,(%esp)
801058d7:	e8 61 ac ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801058dc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058e2:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801058e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801058eb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058f1:	8b 40 04             	mov    0x4(%eax),%eax
801058f4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801058fb:	83 c2 1c             	add    $0x1c,%edx
801058fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105902:	89 14 24             	mov    %edx,(%esp)
80105905:	e8 42 08 00 00       	call   8010614c <swtch>
  cpu->intena = intena;
8010590a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105910:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105913:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105919:	c9                   	leave  
8010591a:	c3                   	ret    

8010591b <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010591b:	55                   	push   %ebp
8010591c:	89 e5                	mov    %esp,%ebp
8010591e:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105921:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105928:	e8 2a 03 00 00       	call   80105c57 <acquire>
  proc->state = RUNNABLE;
8010592d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105933:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010593a:	e8 2a ff ff ff       	call   80105869 <sched>
  release(&ptable.lock);
8010593f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105946:	e8 6e 03 00 00       	call   80105cb9 <release>
}
8010594b:	c9                   	leave  
8010594c:	c3                   	ret    

8010594d <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
8010594d:	55                   	push   %ebp
8010594e:	89 e5                	mov    %esp,%ebp
80105950:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105953:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
8010595a:	e8 5a 03 00 00       	call   80105cb9 <release>

  if (first) {
8010595f:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105964:	85 c0                	test   %eax,%eax
80105966:	74 0f                	je     80105977 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105968:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
8010596f:	00 00 00 
    initlog();
80105972:	e8 4d e7 ff ff       	call   801040c4 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105977:	c9                   	leave  
80105978:	c3                   	ret    

80105979 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105979:	55                   	push   %ebp
8010597a:	89 e5                	mov    %esp,%ebp
8010597c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010597f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105985:	85 c0                	test   %eax,%eax
80105987:	75 0c                	jne    80105995 <sleep+0x1c>
    panic("sleep");
80105989:	c7 04 24 5d 98 10 80 	movl   $0x8010985d,(%esp)
80105990:	e8 a8 ab ff ff       	call   8010053d <panic>

  if(lk == 0)
80105995:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105999:	75 0c                	jne    801059a7 <sleep+0x2e>
    panic("sleep without lk");
8010599b:	c7 04 24 63 98 10 80 	movl   $0x80109863,(%esp)
801059a2:	e8 96 ab ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801059a7:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
801059ae:	74 17                	je     801059c7 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801059b0:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801059b7:	e8 9b 02 00 00       	call   80105c57 <acquire>
    release(lk);
801059bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801059bf:	89 04 24             	mov    %eax,(%esp)
801059c2:	e8 f2 02 00 00       	call   80105cb9 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801059c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059cd:	8b 55 08             	mov    0x8(%ebp),%edx
801059d0:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801059d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059d9:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801059e0:	e8 84 fe ff ff       	call   80105869 <sched>

  // Tidy up.
  proc->chan = 0;
801059e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059eb:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801059f2:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
801059f9:	74 17                	je     80105a12 <sleep+0x99>
    release(&ptable.lock);
801059fb:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a02:	e8 b2 02 00 00       	call   80105cb9 <release>
    acquire(lk);
80105a07:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a0a:	89 04 24             	mov    %eax,(%esp)
80105a0d:	e8 45 02 00 00       	call   80105c57 <acquire>
  }
}
80105a12:	c9                   	leave  
80105a13:	c3                   	ret    

80105a14 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105a14:	55                   	push   %ebp
80105a15:	89 e5                	mov    %esp,%ebp
80105a17:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105a1a:	c7 45 fc 94 0f 11 80 	movl   $0x80110f94,-0x4(%ebp)
80105a21:	eb 24                	jmp    80105a47 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105a23:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a26:	8b 40 0c             	mov    0xc(%eax),%eax
80105a29:	83 f8 02             	cmp    $0x2,%eax
80105a2c:	75 15                	jne    80105a43 <wakeup1+0x2f>
80105a2e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a31:	8b 40 20             	mov    0x20(%eax),%eax
80105a34:	3b 45 08             	cmp    0x8(%ebp),%eax
80105a37:	75 0a                	jne    80105a43 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105a39:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a3c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105a43:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105a47:	81 7d fc 94 2e 11 80 	cmpl   $0x80112e94,-0x4(%ebp)
80105a4e:	72 d3                	jb     80105a23 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105a50:	c9                   	leave  
80105a51:	c3                   	ret    

80105a52 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105a52:	55                   	push   %ebp
80105a53:	89 e5                	mov    %esp,%ebp
80105a55:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105a58:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a5f:	e8 f3 01 00 00       	call   80105c57 <acquire>
  wakeup1(chan);
80105a64:	8b 45 08             	mov    0x8(%ebp),%eax
80105a67:	89 04 24             	mov    %eax,(%esp)
80105a6a:	e8 a5 ff ff ff       	call   80105a14 <wakeup1>
  release(&ptable.lock);
80105a6f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a76:	e8 3e 02 00 00       	call   80105cb9 <release>
}
80105a7b:	c9                   	leave  
80105a7c:	c3                   	ret    

80105a7d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105a7d:	55                   	push   %ebp
80105a7e:	89 e5                	mov    %esp,%ebp
80105a80:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105a83:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a8a:	e8 c8 01 00 00       	call   80105c57 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a8f:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105a96:	eb 41                	jmp    80105ad9 <kill+0x5c>
    if(p->pid == pid){
80105a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a9b:	8b 40 10             	mov    0x10(%eax),%eax
80105a9e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105aa1:	75 32                	jne    80105ad5 <kill+0x58>
      p->killed = 1;
80105aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aa6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ab0:	8b 40 0c             	mov    0xc(%eax),%eax
80105ab3:	83 f8 02             	cmp    $0x2,%eax
80105ab6:	75 0a                	jne    80105ac2 <kill+0x45>
        p->state = RUNNABLE;
80105ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105abb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105ac2:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105ac9:	e8 eb 01 00 00       	call   80105cb9 <release>
      return 0;
80105ace:	b8 00 00 00 00       	mov    $0x0,%eax
80105ad3:	eb 1e                	jmp    80105af3 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105ad5:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105ad9:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105ae0:	72 b6                	jb     80105a98 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105ae2:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105ae9:	e8 cb 01 00 00       	call   80105cb9 <release>
  return -1;
80105aee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105af3:	c9                   	leave  
80105af4:	c3                   	ret    

80105af5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105af5:	55                   	push   %ebp
80105af6:	89 e5                	mov    %esp,%ebp
80105af8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105afb:	c7 45 f0 94 0f 11 80 	movl   $0x80110f94,-0x10(%ebp)
80105b02:	e9 d8 00 00 00       	jmp    80105bdf <procdump+0xea>
    if(p->state == UNUSED)
80105b07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b0a:	8b 40 0c             	mov    0xc(%eax),%eax
80105b0d:	85 c0                	test   %eax,%eax
80105b0f:	0f 84 c5 00 00 00    	je     80105bda <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105b15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b18:	8b 40 0c             	mov    0xc(%eax),%eax
80105b1b:	83 f8 05             	cmp    $0x5,%eax
80105b1e:	77 23                	ja     80105b43 <procdump+0x4e>
80105b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b23:	8b 40 0c             	mov    0xc(%eax),%eax
80105b26:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105b2d:	85 c0                	test   %eax,%eax
80105b2f:	74 12                	je     80105b43 <procdump+0x4e>
      state = states[p->state];
80105b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b34:	8b 40 0c             	mov    0xc(%eax),%eax
80105b37:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105b3e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105b41:	eb 07                	jmp    80105b4a <procdump+0x55>
    else
      state = "???";
80105b43:	c7 45 ec 74 98 10 80 	movl   $0x80109874,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105b4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b4d:	8d 50 6c             	lea    0x6c(%eax),%edx
80105b50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b53:	8b 40 10             	mov    0x10(%eax),%eax
80105b56:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105b5a:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b5d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105b61:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b65:	c7 04 24 78 98 10 80 	movl   $0x80109878,(%esp)
80105b6c:	e8 30 a8 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105b71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b74:	8b 40 0c             	mov    0xc(%eax),%eax
80105b77:	83 f8 02             	cmp    $0x2,%eax
80105b7a:	75 50                	jne    80105bcc <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105b7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b7f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105b82:	8b 40 0c             	mov    0xc(%eax),%eax
80105b85:	83 c0 08             	add    $0x8,%eax
80105b88:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105b8b:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b8f:	89 04 24             	mov    %eax,(%esp)
80105b92:	e8 71 01 00 00       	call   80105d08 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105b97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105b9e:	eb 1b                	jmp    80105bbb <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105ba0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ba3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105ba7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bab:	c7 04 24 81 98 10 80 	movl   $0x80109881,(%esp)
80105bb2:	e8 ea a7 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105bb7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105bbb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105bbf:	7f 0b                	jg     80105bcc <procdump+0xd7>
80105bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bc4:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105bc8:	85 c0                	test   %eax,%eax
80105bca:	75 d4                	jne    80105ba0 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105bcc:	c7 04 24 85 98 10 80 	movl   $0x80109885,(%esp)
80105bd3:	e8 c9 a7 ff ff       	call   801003a1 <cprintf>
80105bd8:	eb 01                	jmp    80105bdb <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105bda:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105bdb:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105bdf:	81 7d f0 94 2e 11 80 	cmpl   $0x80112e94,-0x10(%ebp)
80105be6:	0f 82 1b ff ff ff    	jb     80105b07 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105bec:	c9                   	leave  
80105bed:	c3                   	ret    
	...

80105bf0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105bf0:	55                   	push   %ebp
80105bf1:	89 e5                	mov    %esp,%ebp
80105bf3:	53                   	push   %ebx
80105bf4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105bf7:	9c                   	pushf  
80105bf8:	5b                   	pop    %ebx
80105bf9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105bfc:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105bff:	83 c4 10             	add    $0x10,%esp
80105c02:	5b                   	pop    %ebx
80105c03:	5d                   	pop    %ebp
80105c04:	c3                   	ret    

80105c05 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105c05:	55                   	push   %ebp
80105c06:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105c08:	fa                   	cli    
}
80105c09:	5d                   	pop    %ebp
80105c0a:	c3                   	ret    

80105c0b <sti>:

static inline void
sti(void)
{
80105c0b:	55                   	push   %ebp
80105c0c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105c0e:	fb                   	sti    
}
80105c0f:	5d                   	pop    %ebp
80105c10:	c3                   	ret    

80105c11 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105c11:	55                   	push   %ebp
80105c12:	89 e5                	mov    %esp,%ebp
80105c14:	53                   	push   %ebx
80105c15:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105c18:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105c1b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105c1e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105c21:	89 c3                	mov    %eax,%ebx
80105c23:	89 d8                	mov    %ebx,%eax
80105c25:	f0 87 02             	lock xchg %eax,(%edx)
80105c28:	89 c3                	mov    %eax,%ebx
80105c2a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105c2d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105c30:	83 c4 10             	add    $0x10,%esp
80105c33:	5b                   	pop    %ebx
80105c34:	5d                   	pop    %ebp
80105c35:	c3                   	ret    

80105c36 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105c36:	55                   	push   %ebp
80105c37:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105c39:	8b 45 08             	mov    0x8(%ebp),%eax
80105c3c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105c3f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105c42:	8b 45 08             	mov    0x8(%ebp),%eax
80105c45:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105c4b:	8b 45 08             	mov    0x8(%ebp),%eax
80105c4e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105c55:	5d                   	pop    %ebp
80105c56:	c3                   	ret    

80105c57 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105c57:	55                   	push   %ebp
80105c58:	89 e5                	mov    %esp,%ebp
80105c5a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105c5d:	e8 3d 01 00 00       	call   80105d9f <pushcli>
  if(holding(lk))
80105c62:	8b 45 08             	mov    0x8(%ebp),%eax
80105c65:	89 04 24             	mov    %eax,(%esp)
80105c68:	e8 08 01 00 00       	call   80105d75 <holding>
80105c6d:	85 c0                	test   %eax,%eax
80105c6f:	74 0c                	je     80105c7d <acquire+0x26>
    panic("acquire");
80105c71:	c7 04 24 b1 98 10 80 	movl   $0x801098b1,(%esp)
80105c78:	e8 c0 a8 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105c7d:	90                   	nop
80105c7e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c81:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105c88:	00 
80105c89:	89 04 24             	mov    %eax,(%esp)
80105c8c:	e8 80 ff ff ff       	call   80105c11 <xchg>
80105c91:	85 c0                	test   %eax,%eax
80105c93:	75 e9                	jne    80105c7e <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105c95:	8b 45 08             	mov    0x8(%ebp),%eax
80105c98:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105c9f:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105ca2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ca5:	83 c0 0c             	add    $0xc,%eax
80105ca8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cac:	8d 45 08             	lea    0x8(%ebp),%eax
80105caf:	89 04 24             	mov    %eax,(%esp)
80105cb2:	e8 51 00 00 00       	call   80105d08 <getcallerpcs>
}
80105cb7:	c9                   	leave  
80105cb8:	c3                   	ret    

80105cb9 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105cb9:	55                   	push   %ebp
80105cba:	89 e5                	mov    %esp,%ebp
80105cbc:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80105cc2:	89 04 24             	mov    %eax,(%esp)
80105cc5:	e8 ab 00 00 00       	call   80105d75 <holding>
80105cca:	85 c0                	test   %eax,%eax
80105ccc:	75 0c                	jne    80105cda <release+0x21>
    panic("release");
80105cce:	c7 04 24 b9 98 10 80 	movl   $0x801098b9,(%esp)
80105cd5:	e8 63 a8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105cda:	8b 45 08             	mov    0x8(%ebp),%eax
80105cdd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105cee:	8b 45 08             	mov    0x8(%ebp),%eax
80105cf1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105cf8:	00 
80105cf9:	89 04 24             	mov    %eax,(%esp)
80105cfc:	e8 10 ff ff ff       	call   80105c11 <xchg>

  popcli();
80105d01:	e8 e1 00 00 00       	call   80105de7 <popcli>
}
80105d06:	c9                   	leave  
80105d07:	c3                   	ret    

80105d08 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105d08:	55                   	push   %ebp
80105d09:	89 e5                	mov    %esp,%ebp
80105d0b:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105d0e:	8b 45 08             	mov    0x8(%ebp),%eax
80105d11:	83 e8 08             	sub    $0x8,%eax
80105d14:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105d17:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105d1e:	eb 32                	jmp    80105d52 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105d20:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105d24:	74 47                	je     80105d6d <getcallerpcs+0x65>
80105d26:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105d2d:	76 3e                	jbe    80105d6d <getcallerpcs+0x65>
80105d2f:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105d33:	74 38                	je     80105d6d <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105d35:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d38:	c1 e0 02             	shl    $0x2,%eax
80105d3b:	03 45 0c             	add    0xc(%ebp),%eax
80105d3e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d41:	8b 52 04             	mov    0x4(%edx),%edx
80105d44:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105d46:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d49:	8b 00                	mov    (%eax),%eax
80105d4b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105d4e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105d52:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105d56:	7e c8                	jle    80105d20 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105d58:	eb 13                	jmp    80105d6d <getcallerpcs+0x65>
    pcs[i] = 0;
80105d5a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d5d:	c1 e0 02             	shl    $0x2,%eax
80105d60:	03 45 0c             	add    0xc(%ebp),%eax
80105d63:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105d69:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105d6d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105d71:	7e e7                	jle    80105d5a <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105d73:	c9                   	leave  
80105d74:	c3                   	ret    

80105d75 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105d75:	55                   	push   %ebp
80105d76:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105d78:	8b 45 08             	mov    0x8(%ebp),%eax
80105d7b:	8b 00                	mov    (%eax),%eax
80105d7d:	85 c0                	test   %eax,%eax
80105d7f:	74 17                	je     80105d98 <holding+0x23>
80105d81:	8b 45 08             	mov    0x8(%ebp),%eax
80105d84:	8b 50 08             	mov    0x8(%eax),%edx
80105d87:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105d8d:	39 c2                	cmp    %eax,%edx
80105d8f:	75 07                	jne    80105d98 <holding+0x23>
80105d91:	b8 01 00 00 00       	mov    $0x1,%eax
80105d96:	eb 05                	jmp    80105d9d <holding+0x28>
80105d98:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d9d:	5d                   	pop    %ebp
80105d9e:	c3                   	ret    

80105d9f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105d9f:	55                   	push   %ebp
80105da0:	89 e5                	mov    %esp,%ebp
80105da2:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105da5:	e8 46 fe ff ff       	call   80105bf0 <readeflags>
80105daa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105dad:	e8 53 fe ff ff       	call   80105c05 <cli>
  if(cpu->ncli++ == 0)
80105db2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105db8:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105dbe:	85 d2                	test   %edx,%edx
80105dc0:	0f 94 c1             	sete   %cl
80105dc3:	83 c2 01             	add    $0x1,%edx
80105dc6:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105dcc:	84 c9                	test   %cl,%cl
80105dce:	74 15                	je     80105de5 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105dd0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105dd6:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105dd9:	81 e2 00 02 00 00    	and    $0x200,%edx
80105ddf:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105de5:	c9                   	leave  
80105de6:	c3                   	ret    

80105de7 <popcli>:

void
popcli(void)
{
80105de7:	55                   	push   %ebp
80105de8:	89 e5                	mov    %esp,%ebp
80105dea:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105ded:	e8 fe fd ff ff       	call   80105bf0 <readeflags>
80105df2:	25 00 02 00 00       	and    $0x200,%eax
80105df7:	85 c0                	test   %eax,%eax
80105df9:	74 0c                	je     80105e07 <popcli+0x20>
    panic("popcli - interruptible");
80105dfb:	c7 04 24 c1 98 10 80 	movl   $0x801098c1,(%esp)
80105e02:	e8 36 a7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105e07:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e0d:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105e13:	83 ea 01             	sub    $0x1,%edx
80105e16:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105e1c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105e22:	85 c0                	test   %eax,%eax
80105e24:	79 0c                	jns    80105e32 <popcli+0x4b>
    panic("popcli");
80105e26:	c7 04 24 d8 98 10 80 	movl   $0x801098d8,(%esp)
80105e2d:	e8 0b a7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105e32:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e38:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105e3e:	85 c0                	test   %eax,%eax
80105e40:	75 15                	jne    80105e57 <popcli+0x70>
80105e42:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105e48:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105e4e:	85 c0                	test   %eax,%eax
80105e50:	74 05                	je     80105e57 <popcli+0x70>
    sti();
80105e52:	e8 b4 fd ff ff       	call   80105c0b <sti>
}
80105e57:	c9                   	leave  
80105e58:	c3                   	ret    
80105e59:	00 00                	add    %al,(%eax)
	...

80105e5c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105e5c:	55                   	push   %ebp
80105e5d:	89 e5                	mov    %esp,%ebp
80105e5f:	57                   	push   %edi
80105e60:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105e61:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105e64:	8b 55 10             	mov    0x10(%ebp),%edx
80105e67:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e6a:	89 cb                	mov    %ecx,%ebx
80105e6c:	89 df                	mov    %ebx,%edi
80105e6e:	89 d1                	mov    %edx,%ecx
80105e70:	fc                   	cld    
80105e71:	f3 aa                	rep stos %al,%es:(%edi)
80105e73:	89 ca                	mov    %ecx,%edx
80105e75:	89 fb                	mov    %edi,%ebx
80105e77:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e7a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105e7d:	5b                   	pop    %ebx
80105e7e:	5f                   	pop    %edi
80105e7f:	5d                   	pop    %ebp
80105e80:	c3                   	ret    

80105e81 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105e81:	55                   	push   %ebp
80105e82:	89 e5                	mov    %esp,%ebp
80105e84:	57                   	push   %edi
80105e85:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105e86:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105e89:	8b 55 10             	mov    0x10(%ebp),%edx
80105e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e8f:	89 cb                	mov    %ecx,%ebx
80105e91:	89 df                	mov    %ebx,%edi
80105e93:	89 d1                	mov    %edx,%ecx
80105e95:	fc                   	cld    
80105e96:	f3 ab                	rep stos %eax,%es:(%edi)
80105e98:	89 ca                	mov    %ecx,%edx
80105e9a:	89 fb                	mov    %edi,%ebx
80105e9c:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105e9f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ea2:	5b                   	pop    %ebx
80105ea3:	5f                   	pop    %edi
80105ea4:	5d                   	pop    %ebp
80105ea5:	c3                   	ret    

80105ea6 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105ea6:	55                   	push   %ebp
80105ea7:	89 e5                	mov    %esp,%ebp
80105ea9:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105eac:	8b 45 08             	mov    0x8(%ebp),%eax
80105eaf:	83 e0 03             	and    $0x3,%eax
80105eb2:	85 c0                	test   %eax,%eax
80105eb4:	75 49                	jne    80105eff <memset+0x59>
80105eb6:	8b 45 10             	mov    0x10(%ebp),%eax
80105eb9:	83 e0 03             	and    $0x3,%eax
80105ebc:	85 c0                	test   %eax,%eax
80105ebe:	75 3f                	jne    80105eff <memset+0x59>
    c &= 0xFF;
80105ec0:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105ec7:	8b 45 10             	mov    0x10(%ebp),%eax
80105eca:	c1 e8 02             	shr    $0x2,%eax
80105ecd:	89 c2                	mov    %eax,%edx
80105ecf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ed2:	89 c1                	mov    %eax,%ecx
80105ed4:	c1 e1 18             	shl    $0x18,%ecx
80105ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105eda:	c1 e0 10             	shl    $0x10,%eax
80105edd:	09 c1                	or     %eax,%ecx
80105edf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ee2:	c1 e0 08             	shl    $0x8,%eax
80105ee5:	09 c8                	or     %ecx,%eax
80105ee7:	0b 45 0c             	or     0xc(%ebp),%eax
80105eea:	89 54 24 08          	mov    %edx,0x8(%esp)
80105eee:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ef2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ef5:	89 04 24             	mov    %eax,(%esp)
80105ef8:	e8 84 ff ff ff       	call   80105e81 <stosl>
80105efd:	eb 19                	jmp    80105f18 <memset+0x72>
  } else
    stosb(dst, c, n);
80105eff:	8b 45 10             	mov    0x10(%ebp),%eax
80105f02:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f06:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f09:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80105f10:	89 04 24             	mov    %eax,(%esp)
80105f13:	e8 44 ff ff ff       	call   80105e5c <stosb>
  return dst;
80105f18:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105f1b:	c9                   	leave  
80105f1c:	c3                   	ret    

80105f1d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105f1d:	55                   	push   %ebp
80105f1e:	89 e5                	mov    %esp,%ebp
80105f20:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105f23:	8b 45 08             	mov    0x8(%ebp),%eax
80105f26:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105f29:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f2c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105f2f:	eb 32                	jmp    80105f63 <memcmp+0x46>
    if(*s1 != *s2)
80105f31:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f34:	0f b6 10             	movzbl (%eax),%edx
80105f37:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f3a:	0f b6 00             	movzbl (%eax),%eax
80105f3d:	38 c2                	cmp    %al,%dl
80105f3f:	74 1a                	je     80105f5b <memcmp+0x3e>
      return *s1 - *s2;
80105f41:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f44:	0f b6 00             	movzbl (%eax),%eax
80105f47:	0f b6 d0             	movzbl %al,%edx
80105f4a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f4d:	0f b6 00             	movzbl (%eax),%eax
80105f50:	0f b6 c0             	movzbl %al,%eax
80105f53:	89 d1                	mov    %edx,%ecx
80105f55:	29 c1                	sub    %eax,%ecx
80105f57:	89 c8                	mov    %ecx,%eax
80105f59:	eb 1c                	jmp    80105f77 <memcmp+0x5a>
    s1++, s2++;
80105f5b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f5f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105f63:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f67:	0f 95 c0             	setne  %al
80105f6a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f6e:	84 c0                	test   %al,%al
80105f70:	75 bf                	jne    80105f31 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105f72:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f77:	c9                   	leave  
80105f78:	c3                   	ret    

80105f79 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105f79:	55                   	push   %ebp
80105f7a:	89 e5                	mov    %esp,%ebp
80105f7c:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105f7f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f82:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105f85:	8b 45 08             	mov    0x8(%ebp),%eax
80105f88:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105f8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f8e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f91:	73 54                	jae    80105fe7 <memmove+0x6e>
80105f93:	8b 45 10             	mov    0x10(%ebp),%eax
80105f96:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f99:	01 d0                	add    %edx,%eax
80105f9b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105f9e:	76 47                	jbe    80105fe7 <memmove+0x6e>
    s += n;
80105fa0:	8b 45 10             	mov    0x10(%ebp),%eax
80105fa3:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105fa6:	8b 45 10             	mov    0x10(%ebp),%eax
80105fa9:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105fac:	eb 13                	jmp    80105fc1 <memmove+0x48>
      *--d = *--s;
80105fae:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105fb2:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105fb6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fb9:	0f b6 10             	movzbl (%eax),%edx
80105fbc:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fbf:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105fc1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fc5:	0f 95 c0             	setne  %al
80105fc8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105fcc:	84 c0                	test   %al,%al
80105fce:	75 de                	jne    80105fae <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105fd0:	eb 25                	jmp    80105ff7 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105fd2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fd5:	0f b6 10             	movzbl (%eax),%edx
80105fd8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fdb:	88 10                	mov    %dl,(%eax)
80105fdd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105fe1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105fe5:	eb 01                	jmp    80105fe8 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105fe7:	90                   	nop
80105fe8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105fec:	0f 95 c0             	setne  %al
80105fef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ff3:	84 c0                	test   %al,%al
80105ff5:	75 db                	jne    80105fd2 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105ff7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105ffa:	c9                   	leave  
80105ffb:	c3                   	ret    

80105ffc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105ffc:	55                   	push   %ebp
80105ffd:	89 e5                	mov    %esp,%ebp
80105fff:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80106002:	8b 45 10             	mov    0x10(%ebp),%eax
80106005:	89 44 24 08          	mov    %eax,0x8(%esp)
80106009:	8b 45 0c             	mov    0xc(%ebp),%eax
8010600c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106010:	8b 45 08             	mov    0x8(%ebp),%eax
80106013:	89 04 24             	mov    %eax,(%esp)
80106016:	e8 5e ff ff ff       	call   80105f79 <memmove>
}
8010601b:	c9                   	leave  
8010601c:	c3                   	ret    

8010601d <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010601d:	55                   	push   %ebp
8010601e:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80106020:	eb 0c                	jmp    8010602e <strncmp+0x11>
    n--, p++, q++;
80106022:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106026:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010602a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010602e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106032:	74 1a                	je     8010604e <strncmp+0x31>
80106034:	8b 45 08             	mov    0x8(%ebp),%eax
80106037:	0f b6 00             	movzbl (%eax),%eax
8010603a:	84 c0                	test   %al,%al
8010603c:	74 10                	je     8010604e <strncmp+0x31>
8010603e:	8b 45 08             	mov    0x8(%ebp),%eax
80106041:	0f b6 10             	movzbl (%eax),%edx
80106044:	8b 45 0c             	mov    0xc(%ebp),%eax
80106047:	0f b6 00             	movzbl (%eax),%eax
8010604a:	38 c2                	cmp    %al,%dl
8010604c:	74 d4                	je     80106022 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010604e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106052:	75 07                	jne    8010605b <strncmp+0x3e>
    return 0;
80106054:	b8 00 00 00 00       	mov    $0x0,%eax
80106059:	eb 18                	jmp    80106073 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010605b:	8b 45 08             	mov    0x8(%ebp),%eax
8010605e:	0f b6 00             	movzbl (%eax),%eax
80106061:	0f b6 d0             	movzbl %al,%edx
80106064:	8b 45 0c             	mov    0xc(%ebp),%eax
80106067:	0f b6 00             	movzbl (%eax),%eax
8010606a:	0f b6 c0             	movzbl %al,%eax
8010606d:	89 d1                	mov    %edx,%ecx
8010606f:	29 c1                	sub    %eax,%ecx
80106071:	89 c8                	mov    %ecx,%eax
}
80106073:	5d                   	pop    %ebp
80106074:	c3                   	ret    

80106075 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80106075:	55                   	push   %ebp
80106076:	89 e5                	mov    %esp,%ebp
80106078:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010607b:	8b 45 08             	mov    0x8(%ebp),%eax
8010607e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106081:	90                   	nop
80106082:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106086:	0f 9f c0             	setg   %al
80106089:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010608d:	84 c0                	test   %al,%al
8010608f:	74 30                	je     801060c1 <strncpy+0x4c>
80106091:	8b 45 0c             	mov    0xc(%ebp),%eax
80106094:	0f b6 10             	movzbl (%eax),%edx
80106097:	8b 45 08             	mov    0x8(%ebp),%eax
8010609a:	88 10                	mov    %dl,(%eax)
8010609c:	8b 45 08             	mov    0x8(%ebp),%eax
8010609f:	0f b6 00             	movzbl (%eax),%eax
801060a2:	84 c0                	test   %al,%al
801060a4:	0f 95 c0             	setne  %al
801060a7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060ab:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801060af:	84 c0                	test   %al,%al
801060b1:	75 cf                	jne    80106082 <strncpy+0xd>
    ;
  while(n-- > 0)
801060b3:	eb 0c                	jmp    801060c1 <strncpy+0x4c>
    *s++ = 0;
801060b5:	8b 45 08             	mov    0x8(%ebp),%eax
801060b8:	c6 00 00             	movb   $0x0,(%eax)
801060bb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801060bf:	eb 01                	jmp    801060c2 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801060c1:	90                   	nop
801060c2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060c6:	0f 9f c0             	setg   %al
801060c9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060cd:	84 c0                	test   %al,%al
801060cf:	75 e4                	jne    801060b5 <strncpy+0x40>
    *s++ = 0;
  return os;
801060d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801060d4:	c9                   	leave  
801060d5:	c3                   	ret    

801060d6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801060d6:	55                   	push   %ebp
801060d7:	89 e5                	mov    %esp,%ebp
801060d9:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801060dc:	8b 45 08             	mov    0x8(%ebp),%eax
801060df:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801060e2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060e6:	7f 05                	jg     801060ed <safestrcpy+0x17>
    return os;
801060e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060eb:	eb 35                	jmp    80106122 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801060ed:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060f1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060f5:	7e 22                	jle    80106119 <safestrcpy+0x43>
801060f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801060fa:	0f b6 10             	movzbl (%eax),%edx
801060fd:	8b 45 08             	mov    0x8(%ebp),%eax
80106100:	88 10                	mov    %dl,(%eax)
80106102:	8b 45 08             	mov    0x8(%ebp),%eax
80106105:	0f b6 00             	movzbl (%eax),%eax
80106108:	84 c0                	test   %al,%al
8010610a:	0f 95 c0             	setne  %al
8010610d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106111:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106115:	84 c0                	test   %al,%al
80106117:	75 d4                	jne    801060ed <safestrcpy+0x17>
    ;
  *s = 0;
80106119:	8b 45 08             	mov    0x8(%ebp),%eax
8010611c:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010611f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106122:	c9                   	leave  
80106123:	c3                   	ret    

80106124 <strlen>:

int
strlen(const char *s)
{
80106124:	55                   	push   %ebp
80106125:	89 e5                	mov    %esp,%ebp
80106127:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010612a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106131:	eb 04                	jmp    80106137 <strlen+0x13>
80106133:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106137:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010613a:	03 45 08             	add    0x8(%ebp),%eax
8010613d:	0f b6 00             	movzbl (%eax),%eax
80106140:	84 c0                	test   %al,%al
80106142:	75 ef                	jne    80106133 <strlen+0xf>
    ;
  return n;
80106144:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106147:	c9                   	leave  
80106148:	c3                   	ret    
80106149:	00 00                	add    %al,(%eax)
	...

8010614c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010614c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80106150:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106154:	55                   	push   %ebp
  pushl %ebx
80106155:	53                   	push   %ebx
  pushl %esi
80106156:	56                   	push   %esi
  pushl %edi
80106157:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80106158:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010615a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010615c:	5f                   	pop    %edi
  popl %esi
8010615d:	5e                   	pop    %esi
  popl %ebx
8010615e:	5b                   	pop    %ebx
  popl %ebp
8010615f:	5d                   	pop    %ebp
  ret
80106160:	c3                   	ret    
80106161:	00 00                	add    %al,(%eax)
	...

80106164 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80106164:	55                   	push   %ebp
80106165:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80106167:	8b 45 08             	mov    0x8(%ebp),%eax
8010616a:	8b 00                	mov    (%eax),%eax
8010616c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010616f:	76 0f                	jbe    80106180 <fetchint+0x1c>
80106171:	8b 45 0c             	mov    0xc(%ebp),%eax
80106174:	8d 50 04             	lea    0x4(%eax),%edx
80106177:	8b 45 08             	mov    0x8(%ebp),%eax
8010617a:	8b 00                	mov    (%eax),%eax
8010617c:	39 c2                	cmp    %eax,%edx
8010617e:	76 07                	jbe    80106187 <fetchint+0x23>
    return -1;
80106180:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106185:	eb 0f                	jmp    80106196 <fetchint+0x32>
  *ip = *(int*)(addr);
80106187:	8b 45 0c             	mov    0xc(%ebp),%eax
8010618a:	8b 10                	mov    (%eax),%edx
8010618c:	8b 45 10             	mov    0x10(%ebp),%eax
8010618f:	89 10                	mov    %edx,(%eax)
  return 0;
80106191:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106196:	5d                   	pop    %ebp
80106197:	c3                   	ret    

80106198 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80106198:	55                   	push   %ebp
80106199:	89 e5                	mov    %esp,%ebp
8010619b:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
8010619e:	8b 45 08             	mov    0x8(%ebp),%eax
801061a1:	8b 00                	mov    (%eax),%eax
801061a3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801061a6:	77 07                	ja     801061af <fetchstr+0x17>
    return -1;
801061a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ad:	eb 45                	jmp    801061f4 <fetchstr+0x5c>
  *pp = (char*)addr;
801061af:	8b 55 0c             	mov    0xc(%ebp),%edx
801061b2:	8b 45 10             	mov    0x10(%ebp),%eax
801061b5:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
801061b7:	8b 45 08             	mov    0x8(%ebp),%eax
801061ba:	8b 00                	mov    (%eax),%eax
801061bc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801061bf:	8b 45 10             	mov    0x10(%ebp),%eax
801061c2:	8b 00                	mov    (%eax),%eax
801061c4:	89 45 fc             	mov    %eax,-0x4(%ebp)
801061c7:	eb 1e                	jmp    801061e7 <fetchstr+0x4f>
    if(*s == 0)
801061c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061cc:	0f b6 00             	movzbl (%eax),%eax
801061cf:	84 c0                	test   %al,%al
801061d1:	75 10                	jne    801061e3 <fetchstr+0x4b>
      return s - *pp;
801061d3:	8b 55 fc             	mov    -0x4(%ebp),%edx
801061d6:	8b 45 10             	mov    0x10(%ebp),%eax
801061d9:	8b 00                	mov    (%eax),%eax
801061db:	89 d1                	mov    %edx,%ecx
801061dd:	29 c1                	sub    %eax,%ecx
801061df:	89 c8                	mov    %ecx,%eax
801061e1:	eb 11                	jmp    801061f4 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801061e3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801061e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061ea:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801061ed:	72 da                	jb     801061c9 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801061ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801061f4:	c9                   	leave  
801061f5:	c3                   	ret    

801061f6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801061f6:	55                   	push   %ebp
801061f7:	89 e5                	mov    %esp,%ebp
801061f9:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801061fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106202:	8b 40 18             	mov    0x18(%eax),%eax
80106205:	8b 50 44             	mov    0x44(%eax),%edx
80106208:	8b 45 08             	mov    0x8(%ebp),%eax
8010620b:	c1 e0 02             	shl    $0x2,%eax
8010620e:	01 d0                	add    %edx,%eax
80106210:	8d 48 04             	lea    0x4(%eax),%ecx
80106213:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106219:	8b 55 0c             	mov    0xc(%ebp),%edx
8010621c:	89 54 24 08          	mov    %edx,0x8(%esp)
80106220:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106224:	89 04 24             	mov    %eax,(%esp)
80106227:	e8 38 ff ff ff       	call   80106164 <fetchint>
}
8010622c:	c9                   	leave  
8010622d:	c3                   	ret    

8010622e <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010622e:	55                   	push   %ebp
8010622f:	89 e5                	mov    %esp,%ebp
80106231:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106234:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106237:	89 44 24 04          	mov    %eax,0x4(%esp)
8010623b:	8b 45 08             	mov    0x8(%ebp),%eax
8010623e:	89 04 24             	mov    %eax,(%esp)
80106241:	e8 b0 ff ff ff       	call   801061f6 <argint>
80106246:	85 c0                	test   %eax,%eax
80106248:	79 07                	jns    80106251 <argptr+0x23>
    return -1;
8010624a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010624f:	eb 3d                	jmp    8010628e <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106251:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106254:	89 c2                	mov    %eax,%edx
80106256:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010625c:	8b 00                	mov    (%eax),%eax
8010625e:	39 c2                	cmp    %eax,%edx
80106260:	73 16                	jae    80106278 <argptr+0x4a>
80106262:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106265:	89 c2                	mov    %eax,%edx
80106267:	8b 45 10             	mov    0x10(%ebp),%eax
8010626a:	01 c2                	add    %eax,%edx
8010626c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106272:	8b 00                	mov    (%eax),%eax
80106274:	39 c2                	cmp    %eax,%edx
80106276:	76 07                	jbe    8010627f <argptr+0x51>
    return -1;
80106278:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010627d:	eb 0f                	jmp    8010628e <argptr+0x60>
  *pp = (char*)i;
8010627f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106282:	89 c2                	mov    %eax,%edx
80106284:	8b 45 0c             	mov    0xc(%ebp),%eax
80106287:	89 10                	mov    %edx,(%eax)
  return 0;
80106289:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010628e:	c9                   	leave  
8010628f:	c3                   	ret    

80106290 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106290:	55                   	push   %ebp
80106291:	89 e5                	mov    %esp,%ebp
80106293:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106296:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106299:	89 44 24 04          	mov    %eax,0x4(%esp)
8010629d:	8b 45 08             	mov    0x8(%ebp),%eax
801062a0:	89 04 24             	mov    %eax,(%esp)
801062a3:	e8 4e ff ff ff       	call   801061f6 <argint>
801062a8:	85 c0                	test   %eax,%eax
801062aa:	79 07                	jns    801062b3 <argstr+0x23>
    return -1;
801062ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062b1:	eb 1e                	jmp    801062d1 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801062b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062b6:	89 c2                	mov    %eax,%edx
801062b8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801062c1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062c5:	89 54 24 04          	mov    %edx,0x4(%esp)
801062c9:	89 04 24             	mov    %eax,(%esp)
801062cc:	e8 c7 fe ff ff       	call   80106198 <fetchstr>
}
801062d1:	c9                   	leave  
801062d2:	c3                   	ret    

801062d3 <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
801062d3:	55                   	push   %ebp
801062d4:	89 e5                	mov    %esp,%ebp
801062d6:	53                   	push   %ebx
801062d7:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801062da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062e0:	8b 40 18             	mov    0x18(%eax),%eax
801062e3:	8b 40 1c             	mov    0x1c(%eax),%eax
801062e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801062e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801062ed:	78 2e                	js     8010631d <syscall+0x4a>
801062ef:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801062f3:	7f 28                	jg     8010631d <syscall+0x4a>
801062f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f8:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801062ff:	85 c0                	test   %eax,%eax
80106301:	74 1a                	je     8010631d <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80106303:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106309:	8b 58 18             	mov    0x18(%eax),%ebx
8010630c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010630f:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106316:	ff d0                	call   *%eax
80106318:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010631b:	eb 73                	jmp    80106390 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
8010631d:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106321:	7e 30                	jle    80106353 <syscall+0x80>
80106323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106326:	83 f8 19             	cmp    $0x19,%eax
80106329:	77 28                	ja     80106353 <syscall+0x80>
8010632b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010632e:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106335:	85 c0                	test   %eax,%eax
80106337:	74 1a                	je     80106353 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80106339:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010633f:	8b 58 18             	mov    0x18(%eax),%ebx
80106342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106345:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010634c:	ff d0                	call   *%eax
8010634e:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106351:	eb 3d                	jmp    80106390 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106353:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106359:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010635c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106362:	8b 40 10             	mov    0x10(%eax),%eax
80106365:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106368:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010636c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106370:	89 44 24 04          	mov    %eax,0x4(%esp)
80106374:	c7 04 24 df 98 10 80 	movl   $0x801098df,(%esp)
8010637b:	e8 21 a0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106380:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106386:	8b 40 18             	mov    0x18(%eax),%eax
80106389:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106390:	83 c4 24             	add    $0x24,%esp
80106393:	5b                   	pop    %ebx
80106394:	5d                   	pop    %ebp
80106395:	c3                   	ret    
	...

80106398 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106398:	55                   	push   %ebp
80106399:	89 e5                	mov    %esp,%ebp
8010639b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010639e:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801063a5:	8b 45 08             	mov    0x8(%ebp),%eax
801063a8:	89 04 24             	mov    %eax,(%esp)
801063ab:	e8 46 fe ff ff       	call   801061f6 <argint>
801063b0:	85 c0                	test   %eax,%eax
801063b2:	79 07                	jns    801063bb <argfd+0x23>
    return -1;
801063b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063b9:	eb 50                	jmp    8010640b <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801063bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063be:	85 c0                	test   %eax,%eax
801063c0:	78 21                	js     801063e3 <argfd+0x4b>
801063c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063c5:	83 f8 0f             	cmp    $0xf,%eax
801063c8:	7f 19                	jg     801063e3 <argfd+0x4b>
801063ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063d0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801063d3:	83 c2 08             	add    $0x8,%edx
801063d6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801063da:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063e1:	75 07                	jne    801063ea <argfd+0x52>
    return -1;
801063e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063e8:	eb 21                	jmp    8010640b <argfd+0x73>
  if(pfd)
801063ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801063ee:	74 08                	je     801063f8 <argfd+0x60>
    *pfd = fd;
801063f0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801063f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801063f6:	89 10                	mov    %edx,(%eax)
  if(pf)
801063f8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801063fc:	74 08                	je     80106406 <argfd+0x6e>
    *pf = f;
801063fe:	8b 45 10             	mov    0x10(%ebp),%eax
80106401:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106404:	89 10                	mov    %edx,(%eax)
  return 0;
80106406:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010640b:	c9                   	leave  
8010640c:	c3                   	ret    

8010640d <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010640d:	55                   	push   %ebp
8010640e:	89 e5                	mov    %esp,%ebp
80106410:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106413:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010641a:	eb 30                	jmp    8010644c <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
8010641c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106422:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106425:	83 c2 08             	add    $0x8,%edx
80106428:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010642c:	85 c0                	test   %eax,%eax
8010642e:	75 18                	jne    80106448 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106430:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106436:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106439:	8d 4a 08             	lea    0x8(%edx),%ecx
8010643c:	8b 55 08             	mov    0x8(%ebp),%edx
8010643f:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106443:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106446:	eb 0f                	jmp    80106457 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106448:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010644c:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106450:	7e ca                	jle    8010641c <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106452:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106457:	c9                   	leave  
80106458:	c3                   	ret    

80106459 <sys_dup>:

int
sys_dup(void)
{
80106459:	55                   	push   %ebp
8010645a:	89 e5                	mov    %esp,%ebp
8010645c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010645f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106462:	89 44 24 08          	mov    %eax,0x8(%esp)
80106466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010646d:	00 
8010646e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106475:	e8 1e ff ff ff       	call   80106398 <argfd>
8010647a:	85 c0                	test   %eax,%eax
8010647c:	79 07                	jns    80106485 <sys_dup+0x2c>
    return -1;
8010647e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106483:	eb 29                	jmp    801064ae <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106485:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106488:	89 04 24             	mov    %eax,(%esp)
8010648b:	e8 7d ff ff ff       	call   8010640d <fdalloc>
80106490:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106493:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106497:	79 07                	jns    801064a0 <sys_dup+0x47>
    return -1;
80106499:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010649e:	eb 0e                	jmp    801064ae <sys_dup+0x55>
  filedup(f);
801064a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064a3:	89 04 24             	mov    %eax,(%esp)
801064a6:	e8 d1 aa ff ff       	call   80100f7c <filedup>
  return fd;
801064ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801064ae:	c9                   	leave  
801064af:	c3                   	ret    

801064b0 <sys_read>:

int
sys_read(void)
{
801064b0:	55                   	push   %ebp
801064b1:	89 e5                	mov    %esp,%ebp
801064b3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801064b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801064bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801064c4:	00 
801064c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064cc:	e8 c7 fe ff ff       	call   80106398 <argfd>
801064d1:	85 c0                	test   %eax,%eax
801064d3:	78 35                	js     8010650a <sys_read+0x5a>
801064d5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801064dc:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801064e3:	e8 0e fd ff ff       	call   801061f6 <argint>
801064e8:	85 c0                	test   %eax,%eax
801064ea:	78 1e                	js     8010650a <sys_read+0x5a>
801064ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801064f3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801064f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801064fa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106501:	e8 28 fd ff ff       	call   8010622e <argptr>
80106506:	85 c0                	test   %eax,%eax
80106508:	79 07                	jns    80106511 <sys_read+0x61>
    return -1;
8010650a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010650f:	eb 19                	jmp    8010652a <sys_read+0x7a>
  return fileread(f, p, n);
80106511:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106514:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106517:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010651e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106522:	89 04 24             	mov    %eax,(%esp)
80106525:	e8 bf ab ff ff       	call   801010e9 <fileread>
}
8010652a:	c9                   	leave  
8010652b:	c3                   	ret    

8010652c <sys_write>:

int
sys_write(void)
{
8010652c:	55                   	push   %ebp
8010652d:	89 e5                	mov    %esp,%ebp
8010652f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106532:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106535:	89 44 24 08          	mov    %eax,0x8(%esp)
80106539:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106540:	00 
80106541:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106548:	e8 4b fe ff ff       	call   80106398 <argfd>
8010654d:	85 c0                	test   %eax,%eax
8010654f:	78 35                	js     80106586 <sys_write+0x5a>
80106551:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106554:	89 44 24 04          	mov    %eax,0x4(%esp)
80106558:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010655f:	e8 92 fc ff ff       	call   801061f6 <argint>
80106564:	85 c0                	test   %eax,%eax
80106566:	78 1e                	js     80106586 <sys_write+0x5a>
80106568:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010656b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010656f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106572:	89 44 24 04          	mov    %eax,0x4(%esp)
80106576:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010657d:	e8 ac fc ff ff       	call   8010622e <argptr>
80106582:	85 c0                	test   %eax,%eax
80106584:	79 07                	jns    8010658d <sys_write+0x61>
    return -1;
80106586:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010658b:	eb 19                	jmp    801065a6 <sys_write+0x7a>
  return filewrite(f, p, n);
8010658d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106590:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106596:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010659a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010659e:	89 04 24             	mov    %eax,(%esp)
801065a1:	e8 ff ab ff ff       	call   801011a5 <filewrite>
}
801065a6:	c9                   	leave  
801065a7:	c3                   	ret    

801065a8 <sys_close>:

int
sys_close(void)
{
801065a8:	55                   	push   %ebp
801065a9:	89 e5                	mov    %esp,%ebp
801065ab:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801065ae:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065b1:	89 44 24 08          	mov    %eax,0x8(%esp)
801065b5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801065b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801065bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065c3:	e8 d0 fd ff ff       	call   80106398 <argfd>
801065c8:	85 c0                	test   %eax,%eax
801065ca:	79 07                	jns    801065d3 <sys_close+0x2b>
    return -1;
801065cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065d1:	eb 24                	jmp    801065f7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801065d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065dc:	83 c2 08             	add    $0x8,%edx
801065df:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801065e6:	00 
  fileclose(f);
801065e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065ea:	89 04 24             	mov    %eax,(%esp)
801065ed:	e8 d2 a9 ff ff       	call   80100fc4 <fileclose>
  return 0;
801065f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065f7:	c9                   	leave  
801065f8:	c3                   	ret    

801065f9 <sys_fstat>:

int
sys_fstat(void)
{
801065f9:	55                   	push   %ebp
801065fa:	89 e5                	mov    %esp,%ebp
801065fc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801065ff:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106602:	89 44 24 08          	mov    %eax,0x8(%esp)
80106606:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010660d:	00 
8010660e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106615:	e8 7e fd ff ff       	call   80106398 <argfd>
8010661a:	85 c0                	test   %eax,%eax
8010661c:	78 1f                	js     8010663d <sys_fstat+0x44>
8010661e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106625:	00 
80106626:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106629:	89 44 24 04          	mov    %eax,0x4(%esp)
8010662d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106634:	e8 f5 fb ff ff       	call   8010622e <argptr>
80106639:	85 c0                	test   %eax,%eax
8010663b:	79 07                	jns    80106644 <sys_fstat+0x4b>
    return -1;
8010663d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106642:	eb 12                	jmp    80106656 <sys_fstat+0x5d>
  return filestat(f, st);
80106644:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106647:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010664e:	89 04 24             	mov    %eax,(%esp)
80106651:	e8 44 aa ff ff       	call   8010109a <filestat>
}
80106656:	c9                   	leave  
80106657:	c3                   	ret    

80106658 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106658:	55                   	push   %ebp
80106659:	89 e5                	mov    %esp,%ebp
8010665b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010665e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106661:	89 44 24 04          	mov    %eax,0x4(%esp)
80106665:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010666c:	e8 1f fc ff ff       	call   80106290 <argstr>
80106671:	85 c0                	test   %eax,%eax
80106673:	78 17                	js     8010668c <sys_link+0x34>
80106675:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106678:	89 44 24 04          	mov    %eax,0x4(%esp)
8010667c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106683:	e8 08 fc ff ff       	call   80106290 <argstr>
80106688:	85 c0                	test   %eax,%eax
8010668a:	79 0a                	jns    80106696 <sys_link+0x3e>
    return -1;
8010668c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106691:	e9 3c 01 00 00       	jmp    801067d2 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80106696:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106699:	89 04 24             	mov    %eax,(%esp)
8010669c:	e8 09 cb ff ff       	call   801031aa <namei>
801066a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801066a4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801066a8:	75 0a                	jne    801066b4 <sys_link+0x5c>
    return -1;
801066aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066af:	e9 1e 01 00 00       	jmp    801067d2 <sys_link+0x17a>

  begin_trans();
801066b4:	e8 18 dc ff ff       	call   801042d1 <begin_trans>

  ilock(ip);
801066b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bc:	89 04 24             	mov    %eax,(%esp)
801066bf:	e8 44 bf ff ff       	call   80102608 <ilock>
  if(ip->type == T_DIR){
801066c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801066cb:	66 83 f8 01          	cmp    $0x1,%ax
801066cf:	75 1a                	jne    801066eb <sys_link+0x93>
    iunlockput(ip);
801066d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d4:	89 04 24             	mov    %eax,(%esp)
801066d7:	e8 b0 c1 ff ff       	call   8010288c <iunlockput>
    commit_trans();
801066dc:	e8 39 dc ff ff       	call   8010431a <commit_trans>
    return -1;
801066e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066e6:	e9 e7 00 00 00       	jmp    801067d2 <sys_link+0x17a>
  }

  ip->nlink++;
801066eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ee:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801066f2:	8d 50 01             	lea    0x1(%eax),%edx
801066f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801066fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ff:	89 04 24             	mov    %eax,(%esp)
80106702:	e8 45 bd ff ff       	call   8010244c <iupdate>
  iunlock(ip);
80106707:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010670a:	89 04 24             	mov    %eax,(%esp)
8010670d:	e8 44 c0 ff ff       	call   80102756 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106712:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106715:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106718:	89 54 24 04          	mov    %edx,0x4(%esp)
8010671c:	89 04 24             	mov    %eax,(%esp)
8010671f:	e8 a8 ca ff ff       	call   801031cc <nameiparent>
80106724:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106727:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010672b:	74 68                	je     80106795 <sys_link+0x13d>
    goto bad;
  ilock(dp);
8010672d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106730:	89 04 24             	mov    %eax,(%esp)
80106733:	e8 d0 be ff ff       	call   80102608 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106738:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010673b:	8b 10                	mov    (%eax),%edx
8010673d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106740:	8b 00                	mov    (%eax),%eax
80106742:	39 c2                	cmp    %eax,%edx
80106744:	75 20                	jne    80106766 <sys_link+0x10e>
80106746:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106749:	8b 40 04             	mov    0x4(%eax),%eax
8010674c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106750:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106753:	89 44 24 04          	mov    %eax,0x4(%esp)
80106757:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010675a:	89 04 24             	mov    %eax,(%esp)
8010675d:	e8 87 c7 ff ff       	call   80102ee9 <dirlink>
80106762:	85 c0                	test   %eax,%eax
80106764:	79 0d                	jns    80106773 <sys_link+0x11b>
    iunlockput(dp);
80106766:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106769:	89 04 24             	mov    %eax,(%esp)
8010676c:	e8 1b c1 ff ff       	call   8010288c <iunlockput>
    goto bad;
80106771:	eb 23                	jmp    80106796 <sys_link+0x13e>
  }
  iunlockput(dp);
80106773:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106776:	89 04 24             	mov    %eax,(%esp)
80106779:	e8 0e c1 ff ff       	call   8010288c <iunlockput>
  iput(ip);
8010677e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106781:	89 04 24             	mov    %eax,(%esp)
80106784:	e8 32 c0 ff ff       	call   801027bb <iput>

  commit_trans();
80106789:	e8 8c db ff ff       	call   8010431a <commit_trans>

  return 0;
8010678e:	b8 00 00 00 00       	mov    $0x0,%eax
80106793:	eb 3d                	jmp    801067d2 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106795:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106799:	89 04 24             	mov    %eax,(%esp)
8010679c:	e8 67 be ff ff       	call   80102608 <ilock>
  ip->nlink--;
801067a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067a8:	8d 50 ff             	lea    -0x1(%eax),%edx
801067ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ae:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b5:	89 04 24             	mov    %eax,(%esp)
801067b8:	e8 8f bc ff ff       	call   8010244c <iupdate>
  iunlockput(ip);
801067bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c0:	89 04 24             	mov    %eax,(%esp)
801067c3:	e8 c4 c0 ff ff       	call   8010288c <iunlockput>
  commit_trans();
801067c8:	e8 4d db ff ff       	call   8010431a <commit_trans>
  return -1;
801067cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801067d2:	c9                   	leave  
801067d3:	c3                   	ret    

801067d4 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801067d4:	55                   	push   %ebp
801067d5:	89 e5                	mov    %esp,%ebp
801067d7:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801067da:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801067e1:	eb 4b                	jmp    8010682e <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801067e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067e6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801067ed:	00 
801067ee:	89 44 24 08          	mov    %eax,0x8(%esp)
801067f2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801067f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801067f9:	8b 45 08             	mov    0x8(%ebp),%eax
801067fc:	89 04 24             	mov    %eax,(%esp)
801067ff:	e8 fa c2 ff ff       	call   80102afe <readi>
80106804:	83 f8 10             	cmp    $0x10,%eax
80106807:	74 0c                	je     80106815 <isdirempty+0x41>
      panic("isdirempty: readi");
80106809:	c7 04 24 fb 98 10 80 	movl   $0x801098fb,(%esp)
80106810:	e8 28 9d ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106815:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106819:	66 85 c0             	test   %ax,%ax
8010681c:	74 07                	je     80106825 <isdirempty+0x51>
      return 0;
8010681e:	b8 00 00 00 00       	mov    $0x0,%eax
80106823:	eb 1b                	jmp    80106840 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106825:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106828:	83 c0 10             	add    $0x10,%eax
8010682b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010682e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106831:	8b 45 08             	mov    0x8(%ebp),%eax
80106834:	8b 40 18             	mov    0x18(%eax),%eax
80106837:	39 c2                	cmp    %eax,%edx
80106839:	72 a8                	jb     801067e3 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010683b:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106840:	c9                   	leave  
80106841:	c3                   	ret    

80106842 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106842:	55                   	push   %ebp
80106843:	89 e5                	mov    %esp,%ebp
80106845:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106848:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010684b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010684f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106856:	e8 35 fa ff ff       	call   80106290 <argstr>
8010685b:	85 c0                	test   %eax,%eax
8010685d:	79 0a                	jns    80106869 <sys_unlink+0x27>
    return -1;
8010685f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106864:	e9 aa 01 00 00       	jmp    80106a13 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106869:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010686c:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010686f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106873:	89 04 24             	mov    %eax,(%esp)
80106876:	e8 51 c9 ff ff       	call   801031cc <nameiparent>
8010687b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010687e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106882:	75 0a                	jne    8010688e <sys_unlink+0x4c>
    return -1;
80106884:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106889:	e9 85 01 00 00       	jmp    80106a13 <sys_unlink+0x1d1>

  begin_trans();
8010688e:	e8 3e da ff ff       	call   801042d1 <begin_trans>

  ilock(dp);
80106893:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106896:	89 04 24             	mov    %eax,(%esp)
80106899:	e8 6a bd ff ff       	call   80102608 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010689e:	c7 44 24 04 0d 99 10 	movl   $0x8010990d,0x4(%esp)
801068a5:	80 
801068a6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068a9:	89 04 24             	mov    %eax,(%esp)
801068ac:	e8 4e c5 ff ff       	call   80102dff <namecmp>
801068b1:	85 c0                	test   %eax,%eax
801068b3:	0f 84 45 01 00 00    	je     801069fe <sys_unlink+0x1bc>
801068b9:	c7 44 24 04 0f 99 10 	movl   $0x8010990f,0x4(%esp)
801068c0:	80 
801068c1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068c4:	89 04 24             	mov    %eax,(%esp)
801068c7:	e8 33 c5 ff ff       	call   80102dff <namecmp>
801068cc:	85 c0                	test   %eax,%eax
801068ce:	0f 84 2a 01 00 00    	je     801069fe <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801068d4:	8d 45 c8             	lea    -0x38(%ebp),%eax
801068d7:	89 44 24 08          	mov    %eax,0x8(%esp)
801068db:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801068de:	89 44 24 04          	mov    %eax,0x4(%esp)
801068e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e5:	89 04 24             	mov    %eax,(%esp)
801068e8:	e8 34 c5 ff ff       	call   80102e21 <dirlookup>
801068ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068f4:	0f 84 03 01 00 00    	je     801069fd <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801068fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068fd:	89 04 24             	mov    %eax,(%esp)
80106900:	e8 03 bd ff ff       	call   80102608 <ilock>

  if(ip->nlink < 1)
80106905:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106908:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010690c:	66 85 c0             	test   %ax,%ax
8010690f:	7f 0c                	jg     8010691d <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106911:	c7 04 24 12 99 10 80 	movl   $0x80109912,(%esp)
80106918:	e8 20 9c ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010691d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106920:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106924:	66 83 f8 01          	cmp    $0x1,%ax
80106928:	75 1f                	jne    80106949 <sys_unlink+0x107>
8010692a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692d:	89 04 24             	mov    %eax,(%esp)
80106930:	e8 9f fe ff ff       	call   801067d4 <isdirempty>
80106935:	85 c0                	test   %eax,%eax
80106937:	75 10                	jne    80106949 <sys_unlink+0x107>
    iunlockput(ip);
80106939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693c:	89 04 24             	mov    %eax,(%esp)
8010693f:	e8 48 bf ff ff       	call   8010288c <iunlockput>
    goto bad;
80106944:	e9 b5 00 00 00       	jmp    801069fe <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106949:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106950:	00 
80106951:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106958:	00 
80106959:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010695c:	89 04 24             	mov    %eax,(%esp)
8010695f:	e8 42 f5 ff ff       	call   80105ea6 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106964:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106967:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010696e:	00 
8010696f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106973:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106976:	89 44 24 04          	mov    %eax,0x4(%esp)
8010697a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010697d:	89 04 24             	mov    %eax,(%esp)
80106980:	e8 e4 c2 ff ff       	call   80102c69 <writei>
80106985:	83 f8 10             	cmp    $0x10,%eax
80106988:	74 0c                	je     80106996 <sys_unlink+0x154>
    panic("unlink: writei");
8010698a:	c7 04 24 24 99 10 80 	movl   $0x80109924,(%esp)
80106991:	e8 a7 9b ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106996:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106999:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010699d:	66 83 f8 01          	cmp    $0x1,%ax
801069a1:	75 1c                	jne    801069bf <sys_unlink+0x17d>
    dp->nlink--;
801069a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801069aa:	8d 50 ff             	lea    -0x1(%eax),%edx
801069ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801069b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b7:	89 04 24             	mov    %eax,(%esp)
801069ba:	e8 8d ba ff ff       	call   8010244c <iupdate>
  }
  iunlockput(dp);
801069bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c2:	89 04 24             	mov    %eax,(%esp)
801069c5:	e8 c2 be ff ff       	call   8010288c <iunlockput>

  ip->nlink--;
801069ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069cd:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801069d1:	8d 50 ff             	lea    -0x1(%eax),%edx
801069d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069d7:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801069db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069de:	89 04 24             	mov    %eax,(%esp)
801069e1:	e8 66 ba ff ff       	call   8010244c <iupdate>
  iunlockput(ip);
801069e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069e9:	89 04 24             	mov    %eax,(%esp)
801069ec:	e8 9b be ff ff       	call   8010288c <iunlockput>

  commit_trans();
801069f1:	e8 24 d9 ff ff       	call   8010431a <commit_trans>

  return 0;
801069f6:	b8 00 00 00 00       	mov    $0x0,%eax
801069fb:	eb 16                	jmp    80106a13 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801069fd:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801069fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a01:	89 04 24             	mov    %eax,(%esp)
80106a04:	e8 83 be ff ff       	call   8010288c <iunlockput>
  commit_trans();
80106a09:	e8 0c d9 ff ff       	call   8010431a <commit_trans>
  return -1;
80106a0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106a13:	c9                   	leave  
80106a14:	c3                   	ret    

80106a15 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106a15:	55                   	push   %ebp
80106a16:	89 e5                	mov    %esp,%ebp
80106a18:	83 ec 48             	sub    $0x48,%esp
80106a1b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106a1e:	8b 55 10             	mov    0x10(%ebp),%edx
80106a21:	8b 45 14             	mov    0x14(%ebp),%eax
80106a24:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106a28:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106a2c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106a30:	8d 45 de             	lea    -0x22(%ebp),%eax
80106a33:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a37:	8b 45 08             	mov    0x8(%ebp),%eax
80106a3a:	89 04 24             	mov    %eax,(%esp)
80106a3d:	e8 8a c7 ff ff       	call   801031cc <nameiparent>
80106a42:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a45:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a49:	75 0a                	jne    80106a55 <create+0x40>
    return 0;
80106a4b:	b8 00 00 00 00       	mov    $0x0,%eax
80106a50:	e9 7e 01 00 00       	jmp    80106bd3 <create+0x1be>
  ilock(dp);
80106a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a58:	89 04 24             	mov    %eax,(%esp)
80106a5b:	e8 a8 bb ff ff       	call   80102608 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106a60:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106a63:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a67:	8d 45 de             	lea    -0x22(%ebp),%eax
80106a6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a71:	89 04 24             	mov    %eax,(%esp)
80106a74:	e8 a8 c3 ff ff       	call   80102e21 <dirlookup>
80106a79:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a7c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a80:	74 47                	je     80106ac9 <create+0xb4>
    iunlockput(dp);
80106a82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a85:	89 04 24             	mov    %eax,(%esp)
80106a88:	e8 ff bd ff ff       	call   8010288c <iunlockput>
    ilock(ip);
80106a8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a90:	89 04 24             	mov    %eax,(%esp)
80106a93:	e8 70 bb ff ff       	call   80102608 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106a98:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106a9d:	75 15                	jne    80106ab4 <create+0x9f>
80106a9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aa2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106aa6:	66 83 f8 02          	cmp    $0x2,%ax
80106aaa:	75 08                	jne    80106ab4 <create+0x9f>
      return ip;
80106aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aaf:	e9 1f 01 00 00       	jmp    80106bd3 <create+0x1be>
    iunlockput(ip);
80106ab4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab7:	89 04 24             	mov    %eax,(%esp)
80106aba:	e8 cd bd ff ff       	call   8010288c <iunlockput>
    return 0;
80106abf:	b8 00 00 00 00       	mov    $0x0,%eax
80106ac4:	e9 0a 01 00 00       	jmp    80106bd3 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106ac9:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106acd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad0:	8b 00                	mov    (%eax),%eax
80106ad2:	89 54 24 04          	mov    %edx,0x4(%esp)
80106ad6:	89 04 24             	mov    %eax,(%esp)
80106ad9:	e8 91 b8 ff ff       	call   8010236f <ialloc>
80106ade:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ae1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ae5:	75 0c                	jne    80106af3 <create+0xde>
    panic("create: ialloc");
80106ae7:	c7 04 24 33 99 10 80 	movl   $0x80109933,(%esp)
80106aee:	e8 4a 9a ff ff       	call   8010053d <panic>

  ilock(ip);
80106af3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af6:	89 04 24             	mov    %eax,(%esp)
80106af9:	e8 0a bb ff ff       	call   80102608 <ilock>
  ip->major = major;
80106afe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b01:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106b05:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106b09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b0c:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106b10:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106b14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b17:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106b1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b20:	89 04 24             	mov    %eax,(%esp)
80106b23:	e8 24 b9 ff ff       	call   8010244c <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106b28:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106b2d:	75 6a                	jne    80106b99 <create+0x184>
    dp->nlink++;  // for ".."
80106b2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b32:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b36:	8d 50 01             	lea    0x1(%eax),%edx
80106b39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b3c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b43:	89 04 24             	mov    %eax,(%esp)
80106b46:	e8 01 b9 ff ff       	call   8010244c <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106b4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b4e:	8b 40 04             	mov    0x4(%eax),%eax
80106b51:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b55:	c7 44 24 04 0d 99 10 	movl   $0x8010990d,0x4(%esp)
80106b5c:	80 
80106b5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b60:	89 04 24             	mov    %eax,(%esp)
80106b63:	e8 81 c3 ff ff       	call   80102ee9 <dirlink>
80106b68:	85 c0                	test   %eax,%eax
80106b6a:	78 21                	js     80106b8d <create+0x178>
80106b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b6f:	8b 40 04             	mov    0x4(%eax),%eax
80106b72:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b76:	c7 44 24 04 0f 99 10 	movl   $0x8010990f,0x4(%esp)
80106b7d:	80 
80106b7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b81:	89 04 24             	mov    %eax,(%esp)
80106b84:	e8 60 c3 ff ff       	call   80102ee9 <dirlink>
80106b89:	85 c0                	test   %eax,%eax
80106b8b:	79 0c                	jns    80106b99 <create+0x184>
      panic("create dots");
80106b8d:	c7 04 24 42 99 10 80 	movl   $0x80109942,(%esp)
80106b94:	e8 a4 99 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106b99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b9c:	8b 40 04             	mov    0x4(%eax),%eax
80106b9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ba3:	8d 45 de             	lea    -0x22(%ebp),%eax
80106ba6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bad:	89 04 24             	mov    %eax,(%esp)
80106bb0:	e8 34 c3 ff ff       	call   80102ee9 <dirlink>
80106bb5:	85 c0                	test   %eax,%eax
80106bb7:	79 0c                	jns    80106bc5 <create+0x1b0>
    panic("create: dirlink");
80106bb9:	c7 04 24 4e 99 10 80 	movl   $0x8010994e,(%esp)
80106bc0:	e8 78 99 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bc8:	89 04 24             	mov    %eax,(%esp)
80106bcb:	e8 bc bc ff ff       	call   8010288c <iunlockput>

  return ip;
80106bd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106bd3:	c9                   	leave  
80106bd4:	c3                   	ret    

80106bd5 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80106bd5:	55                   	push   %ebp
80106bd6:	89 e5                	mov    %esp,%ebp
80106bd8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80106bde:	25 00 02 00 00       	and    $0x200,%eax
80106be3:	85 c0                	test   %eax,%eax
80106be5:	74 40                	je     80106c27 <fileopen+0x52>
    begin_trans();
80106be7:	e8 e5 d6 ff ff       	call   801042d1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106bec:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106bf3:	00 
80106bf4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106bfb:	00 
80106bfc:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106c03:	00 
80106c04:	8b 45 08             	mov    0x8(%ebp),%eax
80106c07:	89 04 24             	mov    %eax,(%esp)
80106c0a:	e8 06 fe ff ff       	call   80106a15 <create>
80106c0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106c12:	e8 03 d7 ff ff       	call   8010431a <commit_trans>
    if(ip == 0)
80106c17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c1b:	75 5b                	jne    80106c78 <fileopen+0xa3>
      return 0;
80106c1d:	b8 00 00 00 00       	mov    $0x0,%eax
80106c22:	e9 e5 00 00 00       	jmp    80106d0c <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106c27:	8b 45 08             	mov    0x8(%ebp),%eax
80106c2a:	89 04 24             	mov    %eax,(%esp)
80106c2d:	e8 78 c5 ff ff       	call   801031aa <namei>
80106c32:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c35:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c39:	75 0a                	jne    80106c45 <fileopen+0x70>
      return 0;
80106c3b:	b8 00 00 00 00       	mov    $0x0,%eax
80106c40:	e9 c7 00 00 00       	jmp    80106d0c <fileopen+0x137>
    ilock(ip);
80106c45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c48:	89 04 24             	mov    %eax,(%esp)
80106c4b:	e8 b8 b9 ff ff       	call   80102608 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106c50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c53:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c57:	66 83 f8 01          	cmp    $0x1,%ax
80106c5b:	75 1b                	jne    80106c78 <fileopen+0xa3>
80106c5d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106c61:	74 15                	je     80106c78 <fileopen+0xa3>
      iunlockput(ip);
80106c63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c66:	89 04 24             	mov    %eax,(%esp)
80106c69:	e8 1e bc ff ff       	call   8010288c <iunlockput>
      return 0;
80106c6e:	b8 00 00 00 00       	mov    $0x0,%eax
80106c73:	e9 94 00 00 00       	jmp    80106d0c <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106c78:	e8 9f a2 ff ff       	call   80100f1c <filealloc>
80106c7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c84:	75 23                	jne    80106ca9 <fileopen+0xd4>
    if(f)
80106c86:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c8a:	74 0b                	je     80106c97 <fileopen+0xc2>
      fileclose(f);
80106c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c8f:	89 04 24             	mov    %eax,(%esp)
80106c92:	e8 2d a3 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c9a:	89 04 24             	mov    %eax,(%esp)
80106c9d:	e8 ea bb ff ff       	call   8010288c <iunlockput>
    return 0;
80106ca2:	b8 00 00 00 00       	mov    $0x0,%eax
80106ca7:	eb 63                	jmp    80106d0c <fileopen+0x137>
  }
  iunlock(ip);
80106ca9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cac:	89 04 24             	mov    %eax,(%esp)
80106caf:	e8 a2 ba ff ff       	call   80102756 <iunlock>

  f->type = FD_INODE;
80106cb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb7:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106cbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cc0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106cc3:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106cc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cc9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106cd0:	8b 45 0c             	mov    0xc(%ebp),%eax
80106cd3:	83 e0 01             	and    $0x1,%eax
80106cd6:	85 c0                	test   %eax,%eax
80106cd8:	0f 94 c2             	sete   %dl
80106cdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cde:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106ce1:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ce4:	83 e0 01             	and    $0x1,%eax
80106ce7:	84 c0                	test   %al,%al
80106ce9:	75 0a                	jne    80106cf5 <fileopen+0x120>
80106ceb:	8b 45 0c             	mov    0xc(%ebp),%eax
80106cee:	83 e0 02             	and    $0x2,%eax
80106cf1:	85 c0                	test   %eax,%eax
80106cf3:	74 07                	je     80106cfc <fileopen+0x127>
80106cf5:	b8 01 00 00 00       	mov    $0x1,%eax
80106cfa:	eb 05                	jmp    80106d01 <fileopen+0x12c>
80106cfc:	b8 00 00 00 00       	mov    $0x0,%eax
80106d01:	89 c2                	mov    %eax,%edx
80106d03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d06:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106d09:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106d0c:	c9                   	leave  
80106d0d:	c3                   	ret    

80106d0e <sys_open>:

int
sys_open(void)
{
80106d0e:	55                   	push   %ebp
80106d0f:	89 e5                	mov    %esp,%ebp
80106d11:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106d14:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106d17:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d22:	e8 69 f5 ff ff       	call   80106290 <argstr>
80106d27:	85 c0                	test   %eax,%eax
80106d29:	78 17                	js     80106d42 <sys_open+0x34>
80106d2b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106d2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d32:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d39:	e8 b8 f4 ff ff       	call   801061f6 <argint>
80106d3e:	85 c0                	test   %eax,%eax
80106d40:	79 0a                	jns    80106d4c <sys_open+0x3e>
    return -1;
80106d42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d47:	e9 46 01 00 00       	jmp    80106e92 <sys_open+0x184>
  if(omode & O_CREATE){
80106d4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106d4f:	25 00 02 00 00       	and    $0x200,%eax
80106d54:	85 c0                	test   %eax,%eax
80106d56:	74 40                	je     80106d98 <sys_open+0x8a>
    begin_trans();
80106d58:	e8 74 d5 ff ff       	call   801042d1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106d5d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106d60:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106d67:	00 
80106d68:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106d6f:	00 
80106d70:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106d77:	00 
80106d78:	89 04 24             	mov    %eax,(%esp)
80106d7b:	e8 95 fc ff ff       	call   80106a15 <create>
80106d80:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106d83:	e8 92 d5 ff ff       	call   8010431a <commit_trans>
    if(ip == 0)
80106d88:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d8c:	75 5c                	jne    80106dea <sys_open+0xdc>
      return -1;
80106d8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d93:	e9 fa 00 00 00       	jmp    80106e92 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106d98:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106d9b:	89 04 24             	mov    %eax,(%esp)
80106d9e:	e8 07 c4 ff ff       	call   801031aa <namei>
80106da3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106da6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106daa:	75 0a                	jne    80106db6 <sys_open+0xa8>
      return -1;
80106dac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106db1:	e9 dc 00 00 00       	jmp    80106e92 <sys_open+0x184>
    ilock(ip);
80106db6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db9:	89 04 24             	mov    %eax,(%esp)
80106dbc:	e8 47 b8 ff ff       	call   80102608 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dc4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106dc8:	66 83 f8 01          	cmp    $0x1,%ax
80106dcc:	75 1c                	jne    80106dea <sys_open+0xdc>
80106dce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106dd1:	85 c0                	test   %eax,%eax
80106dd3:	74 15                	je     80106dea <sys_open+0xdc>
      iunlockput(ip);
80106dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dd8:	89 04 24             	mov    %eax,(%esp)
80106ddb:	e8 ac ba ff ff       	call   8010288c <iunlockput>
      return -1;
80106de0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106de5:	e9 a8 00 00 00       	jmp    80106e92 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106dea:	e8 2d a1 ff ff       	call   80100f1c <filealloc>
80106def:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106df2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106df6:	74 14                	je     80106e0c <sys_open+0xfe>
80106df8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dfb:	89 04 24             	mov    %eax,(%esp)
80106dfe:	e8 0a f6 ff ff       	call   8010640d <fdalloc>
80106e03:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106e06:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106e0a:	79 23                	jns    80106e2f <sys_open+0x121>
    if(f)
80106e0c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e10:	74 0b                	je     80106e1d <sys_open+0x10f>
      fileclose(f);
80106e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e15:	89 04 24             	mov    %eax,(%esp)
80106e18:	e8 a7 a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e20:	89 04 24             	mov    %eax,(%esp)
80106e23:	e8 64 ba ff ff       	call   8010288c <iunlockput>
    return -1;
80106e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e2d:	eb 63                	jmp    80106e92 <sys_open+0x184>
  }
  iunlock(ip);
80106e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e32:	89 04 24             	mov    %eax,(%esp)
80106e35:	e8 1c b9 ff ff       	call   80102756 <iunlock>

  f->type = FD_INODE;
80106e3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e3d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106e43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e49:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106e4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e4f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e59:	83 e0 01             	and    $0x1,%eax
80106e5c:	85 c0                	test   %eax,%eax
80106e5e:	0f 94 c2             	sete   %dl
80106e61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e64:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106e67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e6a:	83 e0 01             	and    $0x1,%eax
80106e6d:	84 c0                	test   %al,%al
80106e6f:	75 0a                	jne    80106e7b <sys_open+0x16d>
80106e71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e74:	83 e0 02             	and    $0x2,%eax
80106e77:	85 c0                	test   %eax,%eax
80106e79:	74 07                	je     80106e82 <sys_open+0x174>
80106e7b:	b8 01 00 00 00       	mov    $0x1,%eax
80106e80:	eb 05                	jmp    80106e87 <sys_open+0x179>
80106e82:	b8 00 00 00 00       	mov    $0x0,%eax
80106e87:	89 c2                	mov    %eax,%edx
80106e89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e8c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106e8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106e92:	c9                   	leave  
80106e93:	c3                   	ret    

80106e94 <sys_mkdir>:

int
sys_mkdir(void)
{
80106e94:	55                   	push   %ebp
80106e95:	89 e5                	mov    %esp,%ebp
80106e97:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106e9a:	e8 32 d4 ff ff       	call   801042d1 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106e9f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ea2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ea6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ead:	e8 de f3 ff ff       	call   80106290 <argstr>
80106eb2:	85 c0                	test   %eax,%eax
80106eb4:	78 2c                	js     80106ee2 <sys_mkdir+0x4e>
80106eb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eb9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106ec0:	00 
80106ec1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106ec8:	00 
80106ec9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106ed0:	00 
80106ed1:	89 04 24             	mov    %eax,(%esp)
80106ed4:	e8 3c fb ff ff       	call   80106a15 <create>
80106ed9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106edc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ee0:	75 0c                	jne    80106eee <sys_mkdir+0x5a>
    commit_trans();
80106ee2:	e8 33 d4 ff ff       	call   8010431a <commit_trans>
    return -1;
80106ee7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eec:	eb 15                	jmp    80106f03 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106eee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef1:	89 04 24             	mov    %eax,(%esp)
80106ef4:	e8 93 b9 ff ff       	call   8010288c <iunlockput>
  commit_trans();
80106ef9:	e8 1c d4 ff ff       	call   8010431a <commit_trans>
  return 0;
80106efe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106f03:	c9                   	leave  
80106f04:	c3                   	ret    

80106f05 <sys_mknod>:

int
sys_mknod(void)
{
80106f05:	55                   	push   %ebp
80106f06:	89 e5                	mov    %esp,%ebp
80106f08:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80106f0b:	e8 c1 d3 ff ff       	call   801042d1 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80106f10:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106f13:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f17:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f1e:	e8 6d f3 ff ff       	call   80106290 <argstr>
80106f23:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106f26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f2a:	78 5e                	js     80106f8a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106f2c:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f33:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106f3a:	e8 b7 f2 ff ff       	call   801061f6 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106f3f:	85 c0                	test   %eax,%eax
80106f41:	78 47                	js     80106f8a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106f43:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f46:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f4a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106f51:	e8 a0 f2 ff ff       	call   801061f6 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106f56:	85 c0                	test   %eax,%eax
80106f58:	78 30                	js     80106f8a <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106f5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f5d:	0f bf c8             	movswl %ax,%ecx
80106f60:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f63:	0f bf d0             	movswl %ax,%edx
80106f66:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106f69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106f6d:	89 54 24 08          	mov    %edx,0x8(%esp)
80106f71:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106f78:	00 
80106f79:	89 04 24             	mov    %eax,(%esp)
80106f7c:	e8 94 fa ff ff       	call   80106a15 <create>
80106f81:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f84:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f88:	75 0c                	jne    80106f96 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106f8a:	e8 8b d3 ff ff       	call   8010431a <commit_trans>
    return -1;
80106f8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f94:	eb 15                	jmp    80106fab <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106f96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f99:	89 04 24             	mov    %eax,(%esp)
80106f9c:	e8 eb b8 ff ff       	call   8010288c <iunlockput>
  commit_trans();
80106fa1:	e8 74 d3 ff ff       	call   8010431a <commit_trans>
  return 0;
80106fa6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106fab:	c9                   	leave  
80106fac:	c3                   	ret    

80106fad <sys_chdir>:

int
sys_chdir(void)
{
80106fad:	55                   	push   %ebp
80106fae:	89 e5                	mov    %esp,%ebp
80106fb0:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106fb3:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106fb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fc1:	e8 ca f2 ff ff       	call   80106290 <argstr>
80106fc6:	85 c0                	test   %eax,%eax
80106fc8:	78 14                	js     80106fde <sys_chdir+0x31>
80106fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fcd:	89 04 24             	mov    %eax,(%esp)
80106fd0:	e8 d5 c1 ff ff       	call   801031aa <namei>
80106fd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fdc:	75 07                	jne    80106fe5 <sys_chdir+0x38>
    return -1;
80106fde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fe3:	eb 57                	jmp    8010703c <sys_chdir+0x8f>
  ilock(ip);
80106fe5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fe8:	89 04 24             	mov    %eax,(%esp)
80106feb:	e8 18 b6 ff ff       	call   80102608 <ilock>
  if(ip->type != T_DIR){
80106ff0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ff3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ff7:	66 83 f8 01          	cmp    $0x1,%ax
80106ffb:	74 12                	je     8010700f <sys_chdir+0x62>
    iunlockput(ip);
80106ffd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107000:	89 04 24             	mov    %eax,(%esp)
80107003:	e8 84 b8 ff ff       	call   8010288c <iunlockput>
    return -1;
80107008:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010700d:	eb 2d                	jmp    8010703c <sys_chdir+0x8f>
  }
  iunlock(ip);
8010700f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107012:	89 04 24             	mov    %eax,(%esp)
80107015:	e8 3c b7 ff ff       	call   80102756 <iunlock>
  iput(proc->cwd);
8010701a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107020:	8b 40 68             	mov    0x68(%eax),%eax
80107023:	89 04 24             	mov    %eax,(%esp)
80107026:	e8 90 b7 ff ff       	call   801027bb <iput>
  proc->cwd = ip;
8010702b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107031:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107034:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80107037:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010703c:	c9                   	leave  
8010703d:	c3                   	ret    

8010703e <sys_exec>:

int
sys_exec(void)
{
8010703e:	55                   	push   %ebp
8010703f:	89 e5                	mov    %esp,%ebp
80107041:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80107047:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010704a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010704e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107055:	e8 36 f2 ff ff       	call   80106290 <argstr>
8010705a:	85 c0                	test   %eax,%eax
8010705c:	78 1a                	js     80107078 <sys_exec+0x3a>
8010705e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80107064:	89 44 24 04          	mov    %eax,0x4(%esp)
80107068:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010706f:	e8 82 f1 ff ff       	call   801061f6 <argint>
80107074:	85 c0                	test   %eax,%eax
80107076:	79 0a                	jns    80107082 <sys_exec+0x44>
    return -1;
80107078:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010707d:	e9 e2 00 00 00       	jmp    80107164 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107082:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80107089:	00 
8010708a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107091:	00 
80107092:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107098:	89 04 24             	mov    %eax,(%esp)
8010709b:	e8 06 ee ff ff       	call   80105ea6 <memset>
  for(i=0;; i++){
801070a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801070a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070aa:	83 f8 1f             	cmp    $0x1f,%eax
801070ad:	76 0a                	jbe    801070b9 <sys_exec+0x7b>
      return -1;
801070af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070b4:	e9 ab 00 00 00       	jmp    80107164 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
801070b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070bc:	c1 e0 02             	shl    $0x2,%eax
801070bf:	89 c2                	mov    %eax,%edx
801070c1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801070c7:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
801070ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070d0:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
801070d6:	89 54 24 08          	mov    %edx,0x8(%esp)
801070da:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801070de:	89 04 24             	mov    %eax,(%esp)
801070e1:	e8 7e f0 ff ff       	call   80106164 <fetchint>
801070e6:	85 c0                	test   %eax,%eax
801070e8:	79 07                	jns    801070f1 <sys_exec+0xb3>
      return -1;
801070ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070ef:	eb 73                	jmp    80107164 <sys_exec+0x126>
    if(uarg == 0){
801070f1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801070f7:	85 c0                	test   %eax,%eax
801070f9:	75 26                	jne    80107121 <sys_exec+0xe3>
      argv[i] = 0;
801070fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070fe:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107105:	00 00 00 00 
      break;
80107109:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
8010710a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010710d:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107113:	89 54 24 04          	mov    %edx,0x4(%esp)
80107117:	89 04 24             	mov    %eax,(%esp)
8010711a:	e8 dd 99 ff ff       	call   80100afc <exec>
8010711f:	eb 43                	jmp    80107164 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80107121:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107124:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010712b:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107131:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80107134:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
8010713a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107140:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107144:	89 54 24 04          	mov    %edx,0x4(%esp)
80107148:	89 04 24             	mov    %eax,(%esp)
8010714b:	e8 48 f0 ff ff       	call   80106198 <fetchstr>
80107150:	85 c0                	test   %eax,%eax
80107152:	79 07                	jns    8010715b <sys_exec+0x11d>
      return -1;
80107154:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107159:	eb 09                	jmp    80107164 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010715b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010715f:	e9 43 ff ff ff       	jmp    801070a7 <sys_exec+0x69>
  return exec(path, argv);
}
80107164:	c9                   	leave  
80107165:	c3                   	ret    

80107166 <sys_pipe>:

int
sys_pipe(void)
{
80107166:	55                   	push   %ebp
80107167:	89 e5                	mov    %esp,%ebp
80107169:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010716c:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107173:	00 
80107174:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107177:	89 44 24 04          	mov    %eax,0x4(%esp)
8010717b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107182:	e8 a7 f0 ff ff       	call   8010622e <argptr>
80107187:	85 c0                	test   %eax,%eax
80107189:	79 0a                	jns    80107195 <sys_pipe+0x2f>
    return -1;
8010718b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107190:	e9 9b 00 00 00       	jmp    80107230 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80107195:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107198:	89 44 24 04          	mov    %eax,0x4(%esp)
8010719c:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010719f:	89 04 24             	mov    %eax,(%esp)
801071a2:	e8 45 db ff ff       	call   80104cec <pipealloc>
801071a7:	85 c0                	test   %eax,%eax
801071a9:	79 07                	jns    801071b2 <sys_pipe+0x4c>
    return -1;
801071ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071b0:	eb 7e                	jmp    80107230 <sys_pipe+0xca>
  fd0 = -1;
801071b2:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801071b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801071bc:	89 04 24             	mov    %eax,(%esp)
801071bf:	e8 49 f2 ff ff       	call   8010640d <fdalloc>
801071c4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801071c7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071cb:	78 14                	js     801071e1 <sys_pipe+0x7b>
801071cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801071d0:	89 04 24             	mov    %eax,(%esp)
801071d3:	e8 35 f2 ff ff       	call   8010640d <fdalloc>
801071d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801071db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801071df:	79 37                	jns    80107218 <sys_pipe+0xb2>
    if(fd0 >= 0)
801071e1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071e5:	78 14                	js     801071fb <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801071e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801071f0:	83 c2 08             	add    $0x8,%edx
801071f3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801071fa:	00 
    fileclose(rf);
801071fb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801071fe:	89 04 24             	mov    %eax,(%esp)
80107201:	e8 be 9d ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107206:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107209:	89 04 24             	mov    %eax,(%esp)
8010720c:	e8 b3 9d ff ff       	call   80100fc4 <fileclose>
    return -1;
80107211:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107216:	eb 18                	jmp    80107230 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107218:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010721b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010721e:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80107220:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107223:	8d 50 04             	lea    0x4(%eax),%edx
80107226:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107229:	89 02                	mov    %eax,(%edx)
  return 0;
8010722b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107230:	c9                   	leave  
80107231:	c3                   	ret    
	...

80107234 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107234:	55                   	push   %ebp
80107235:	89 e5                	mov    %esp,%ebp
80107237:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010723a:	e8 67 e1 ff ff       	call   801053a6 <fork>
}
8010723f:	c9                   	leave  
80107240:	c3                   	ret    

80107241 <sys_exit>:

int
sys_exit(void)
{
80107241:	55                   	push   %ebp
80107242:	89 e5                	mov    %esp,%ebp
80107244:	83 ec 08             	sub    $0x8,%esp
  exit();
80107247:	e8 bd e2 ff ff       	call   80105509 <exit>
  return 0;  // not reached
8010724c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107251:	c9                   	leave  
80107252:	c3                   	ret    

80107253 <sys_wait>:

int
sys_wait(void)
{
80107253:	55                   	push   %ebp
80107254:	89 e5                	mov    %esp,%ebp
80107256:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107259:	e8 c3 e3 ff ff       	call   80105621 <wait>
}
8010725e:	c9                   	leave  
8010725f:	c3                   	ret    

80107260 <sys_kill>:

int
sys_kill(void)
{
80107260:	55                   	push   %ebp
80107261:	89 e5                	mov    %esp,%ebp
80107263:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80107266:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107269:	89 44 24 04          	mov    %eax,0x4(%esp)
8010726d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107274:	e8 7d ef ff ff       	call   801061f6 <argint>
80107279:	85 c0                	test   %eax,%eax
8010727b:	79 07                	jns    80107284 <sys_kill+0x24>
    return -1;
8010727d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107282:	eb 0b                	jmp    8010728f <sys_kill+0x2f>
  return kill(pid);
80107284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107287:	89 04 24             	mov    %eax,(%esp)
8010728a:	e8 ee e7 ff ff       	call   80105a7d <kill>
}
8010728f:	c9                   	leave  
80107290:	c3                   	ret    

80107291 <sys_getpid>:

int
sys_getpid(void)
{
80107291:	55                   	push   %ebp
80107292:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107294:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010729a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010729d:	5d                   	pop    %ebp
8010729e:	c3                   	ret    

8010729f <sys_sbrk>:

int
sys_sbrk(void)
{
8010729f:	55                   	push   %ebp
801072a0:	89 e5                	mov    %esp,%ebp
801072a2:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801072a5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801072a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801072ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072b3:	e8 3e ef ff ff       	call   801061f6 <argint>
801072b8:	85 c0                	test   %eax,%eax
801072ba:	79 07                	jns    801072c3 <sys_sbrk+0x24>
    return -1;
801072bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072c1:	eb 24                	jmp    801072e7 <sys_sbrk+0x48>
  addr = proc->sz;
801072c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072c9:	8b 00                	mov    (%eax),%eax
801072cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801072ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801072d1:	89 04 24             	mov    %eax,(%esp)
801072d4:	e8 28 e0 ff ff       	call   80105301 <growproc>
801072d9:	85 c0                	test   %eax,%eax
801072db:	79 07                	jns    801072e4 <sys_sbrk+0x45>
    return -1;
801072dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072e2:	eb 03                	jmp    801072e7 <sys_sbrk+0x48>
  return addr;
801072e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801072e7:	c9                   	leave  
801072e8:	c3                   	ret    

801072e9 <sys_sleep>:

int
sys_sleep(void)
{
801072e9:	55                   	push   %ebp
801072ea:	89 e5                	mov    %esp,%ebp
801072ec:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801072ef:	8d 45 f0             	lea    -0x10(%ebp),%eax
801072f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801072f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072fd:	e8 f4 ee ff ff       	call   801061f6 <argint>
80107302:	85 c0                	test   %eax,%eax
80107304:	79 07                	jns    8010730d <sys_sleep+0x24>
    return -1;
80107306:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010730b:	eb 6c                	jmp    80107379 <sys_sleep+0x90>
  acquire(&tickslock);
8010730d:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107314:	e8 3e e9 ff ff       	call   80105c57 <acquire>
  ticks0 = ticks;
80107319:	a1 e0 36 11 80       	mov    0x801136e0,%eax
8010731e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107321:	eb 34                	jmp    80107357 <sys_sleep+0x6e>
    if(proc->killed){
80107323:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107329:	8b 40 24             	mov    0x24(%eax),%eax
8010732c:	85 c0                	test   %eax,%eax
8010732e:	74 13                	je     80107343 <sys_sleep+0x5a>
      release(&tickslock);
80107330:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107337:	e8 7d e9 ff ff       	call   80105cb9 <release>
      return -1;
8010733c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107341:	eb 36                	jmp    80107379 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107343:	c7 44 24 04 a0 2e 11 	movl   $0x80112ea0,0x4(%esp)
8010734a:	80 
8010734b:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
80107352:	e8 22 e6 ff ff       	call   80105979 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80107357:	a1 e0 36 11 80       	mov    0x801136e0,%eax
8010735c:	89 c2                	mov    %eax,%edx
8010735e:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107361:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107364:	39 c2                	cmp    %eax,%edx
80107366:	72 bb                	jb     80107323 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107368:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
8010736f:	e8 45 e9 ff ff       	call   80105cb9 <release>
  return 0;
80107374:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107379:	c9                   	leave  
8010737a:	c3                   	ret    

8010737b <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010737b:	55                   	push   %ebp
8010737c:	89 e5                	mov    %esp,%ebp
8010737e:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107381:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107388:	e8 ca e8 ff ff       	call   80105c57 <acquire>
  xticks = ticks;
8010738d:	a1 e0 36 11 80       	mov    0x801136e0,%eax
80107392:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107395:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
8010739c:	e8 18 e9 ff ff       	call   80105cb9 <release>
  return xticks;
801073a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801073a4:	c9                   	leave  
801073a5:	c3                   	ret    

801073a6 <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
801073a6:	55                   	push   %ebp
801073a7:	89 e5                	mov    %esp,%ebp
801073a9:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
801073ac:	8d 45 f4             	lea    -0xc(%ebp),%eax
801073af:	89 44 24 04          	mov    %eax,0x4(%esp)
801073b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073ba:	e8 d1 ee ff ff       	call   80106290 <argstr>
801073bf:	85 c0                	test   %eax,%eax
801073c1:	79 07                	jns    801073ca <sys_getFileBlocks+0x24>
    return -1;
801073c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073c8:	eb 0b                	jmp    801073d5 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
801073ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073cd:	89 04 24             	mov    %eax,(%esp)
801073d0:	e8 15 9f ff ff       	call   801012ea <getFileBlocks>
}
801073d5:	c9                   	leave  
801073d6:	c3                   	ret    

801073d7 <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
801073d7:	55                   	push   %ebp
801073d8:	89 e5                	mov    %esp,%ebp
801073da:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
801073dd:	e8 65 a0 ff ff       	call   80101447 <getFreeBlocks>
}
801073e2:	c9                   	leave  
801073e3:	c3                   	ret    

801073e4 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
801073e4:	55                   	push   %ebp
801073e5:	89 e5                	mov    %esp,%ebp
801073e7:	83 ec 08             	sub    $0x8,%esp
  return getSharedBlocksRate();
801073ea:	e8 22 ab ff ff       	call   80101f11 <getSharedBlocksRate>
}
801073ef:	c9                   	leave  
801073f0:	c3                   	ret    

801073f1 <sys_dedup>:

int
sys_dedup(void)
{
801073f1:	55                   	push   %ebp
801073f2:	89 e5                	mov    %esp,%ebp
801073f4:	83 ec 08             	sub    $0x8,%esp
  return dedup();
801073f7:	e8 b8 a2 ff ff       	call   801016b4 <dedup>
}
801073fc:	c9                   	leave  
801073fd:	c3                   	ret    
	...

80107400 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107400:	55                   	push   %ebp
80107401:	89 e5                	mov    %esp,%ebp
80107403:	83 ec 08             	sub    $0x8,%esp
80107406:	8b 55 08             	mov    0x8(%ebp),%edx
80107409:	8b 45 0c             	mov    0xc(%ebp),%eax
8010740c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107410:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107413:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107417:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010741b:	ee                   	out    %al,(%dx)
}
8010741c:	c9                   	leave  
8010741d:	c3                   	ret    

8010741e <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010741e:	55                   	push   %ebp
8010741f:	89 e5                	mov    %esp,%ebp
80107421:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107424:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010742b:	00 
8010742c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107433:	e8 c8 ff ff ff       	call   80107400 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107438:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010743f:	00 
80107440:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107447:	e8 b4 ff ff ff       	call   80107400 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010744c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107453:	00 
80107454:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010745b:	e8 a0 ff ff ff       	call   80107400 <outb>
  picenable(IRQ_TIMER);
80107460:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107467:	e8 09 d7 ff ff       	call   80104b75 <picenable>
}
8010746c:	c9                   	leave  
8010746d:	c3                   	ret    
	...

80107470 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107470:	1e                   	push   %ds
  pushl %es
80107471:	06                   	push   %es
  pushl %fs
80107472:	0f a0                	push   %fs
  pushl %gs
80107474:	0f a8                	push   %gs
  pushal
80107476:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107477:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010747b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010747d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010747f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107483:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107485:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107487:	54                   	push   %esp
  call trap
80107488:	e8 de 01 00 00       	call   8010766b <trap>
  addl $4, %esp
8010748d:	83 c4 04             	add    $0x4,%esp

80107490 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107490:	61                   	popa   
  popl %gs
80107491:	0f a9                	pop    %gs
  popl %fs
80107493:	0f a1                	pop    %fs
  popl %es
80107495:	07                   	pop    %es
  popl %ds
80107496:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107497:	83 c4 08             	add    $0x8,%esp
  iret
8010749a:	cf                   	iret   
	...

8010749c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010749c:	55                   	push   %ebp
8010749d:	89 e5                	mov    %esp,%ebp
8010749f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801074a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801074a5:	83 e8 01             	sub    $0x1,%eax
801074a8:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801074ac:	8b 45 08             	mov    0x8(%ebp),%eax
801074af:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801074b3:	8b 45 08             	mov    0x8(%ebp),%eax
801074b6:	c1 e8 10             	shr    $0x10,%eax
801074b9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801074bd:	8d 45 fa             	lea    -0x6(%ebp),%eax
801074c0:	0f 01 18             	lidtl  (%eax)
}
801074c3:	c9                   	leave  
801074c4:	c3                   	ret    

801074c5 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801074c5:	55                   	push   %ebp
801074c6:	89 e5                	mov    %esp,%ebp
801074c8:	53                   	push   %ebx
801074c9:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801074cc:	0f 20 d3             	mov    %cr2,%ebx
801074cf:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801074d2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801074d5:	83 c4 10             	add    $0x10,%esp
801074d8:	5b                   	pop    %ebx
801074d9:	5d                   	pop    %ebp
801074da:	c3                   	ret    

801074db <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801074db:	55                   	push   %ebp
801074dc:	89 e5                	mov    %esp,%ebp
801074de:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801074e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801074e8:	e9 c3 00 00 00       	jmp    801075b0 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801074ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f0:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
801074f7:	89 c2                	mov    %eax,%edx
801074f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074fc:	66 89 14 c5 e0 2e 11 	mov    %dx,-0x7feed120(,%eax,8)
80107503:	80 
80107504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107507:	66 c7 04 c5 e2 2e 11 	movw   $0x8,-0x7feed11e(,%eax,8)
8010750e:	80 08 00 
80107511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107514:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
8010751b:	80 
8010751c:	83 e2 e0             	and    $0xffffffe0,%edx
8010751f:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
80107526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107529:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
80107530:	80 
80107531:	83 e2 1f             	and    $0x1f,%edx
80107534:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
8010753b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010753e:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107545:	80 
80107546:	83 e2 f0             	and    $0xfffffff0,%edx
80107549:	83 ca 0e             	or     $0xe,%edx
8010754c:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107553:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107556:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
8010755d:	80 
8010755e:	83 e2 ef             	and    $0xffffffef,%edx
80107561:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107568:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010756b:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107572:	80 
80107573:	83 e2 9f             	and    $0xffffff9f,%edx
80107576:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
8010757d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107580:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107587:	80 
80107588:	83 ca 80             	or     $0xffffff80,%edx
8010758b:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107595:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
8010759c:	c1 e8 10             	shr    $0x10,%eax
8010759f:	89 c2                	mov    %eax,%edx
801075a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075a4:	66 89 14 c5 e6 2e 11 	mov    %dx,-0x7feed11a(,%eax,8)
801075ab:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801075ac:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801075b0:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801075b7:	0f 8e 30 ff ff ff    	jle    801074ed <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801075bd:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
801075c2:	66 a3 e0 30 11 80    	mov    %ax,0x801130e0
801075c8:	66 c7 05 e2 30 11 80 	movw   $0x8,0x801130e2
801075cf:	08 00 
801075d1:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
801075d8:	83 e0 e0             	and    $0xffffffe0,%eax
801075db:	a2 e4 30 11 80       	mov    %al,0x801130e4
801075e0:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
801075e7:	83 e0 1f             	and    $0x1f,%eax
801075ea:	a2 e4 30 11 80       	mov    %al,0x801130e4
801075ef:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
801075f6:	83 c8 0f             	or     $0xf,%eax
801075f9:	a2 e5 30 11 80       	mov    %al,0x801130e5
801075fe:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107605:	83 e0 ef             	and    $0xffffffef,%eax
80107608:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010760d:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107614:	83 c8 60             	or     $0x60,%eax
80107617:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010761c:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107623:	83 c8 80             	or     $0xffffff80,%eax
80107626:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010762b:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107630:	c1 e8 10             	shr    $0x10,%eax
80107633:	66 a3 e6 30 11 80    	mov    %ax,0x801130e6
  
  initlock(&tickslock, "time");
80107639:	c7 44 24 04 60 99 10 	movl   $0x80109960,0x4(%esp)
80107640:	80 
80107641:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107648:	e8 e9 e5 ff ff       	call   80105c36 <initlock>
}
8010764d:	c9                   	leave  
8010764e:	c3                   	ret    

8010764f <idtinit>:

void
idtinit(void)
{
8010764f:	55                   	push   %ebp
80107650:	89 e5                	mov    %esp,%ebp
80107652:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107655:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010765c:	00 
8010765d:	c7 04 24 e0 2e 11 80 	movl   $0x80112ee0,(%esp)
80107664:	e8 33 fe ff ff       	call   8010749c <lidt>
}
80107669:	c9                   	leave  
8010766a:	c3                   	ret    

8010766b <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010766b:	55                   	push   %ebp
8010766c:	89 e5                	mov    %esp,%ebp
8010766e:	57                   	push   %edi
8010766f:	56                   	push   %esi
80107670:	53                   	push   %ebx
80107671:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107674:	8b 45 08             	mov    0x8(%ebp),%eax
80107677:	8b 40 30             	mov    0x30(%eax),%eax
8010767a:	83 f8 40             	cmp    $0x40,%eax
8010767d:	75 3e                	jne    801076bd <trap+0x52>
    if(proc->killed)
8010767f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107685:	8b 40 24             	mov    0x24(%eax),%eax
80107688:	85 c0                	test   %eax,%eax
8010768a:	74 05                	je     80107691 <trap+0x26>
      exit();
8010768c:	e8 78 de ff ff       	call   80105509 <exit>
    proc->tf = tf;
80107691:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107697:	8b 55 08             	mov    0x8(%ebp),%edx
8010769a:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010769d:	e8 31 ec ff ff       	call   801062d3 <syscall>
    if(proc->killed)
801076a2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076a8:	8b 40 24             	mov    0x24(%eax),%eax
801076ab:	85 c0                	test   %eax,%eax
801076ad:	0f 84 34 02 00 00    	je     801078e7 <trap+0x27c>
      exit();
801076b3:	e8 51 de ff ff       	call   80105509 <exit>
    return;
801076b8:	e9 2a 02 00 00       	jmp    801078e7 <trap+0x27c>
  }

  switch(tf->trapno){
801076bd:	8b 45 08             	mov    0x8(%ebp),%eax
801076c0:	8b 40 30             	mov    0x30(%eax),%eax
801076c3:	83 e8 20             	sub    $0x20,%eax
801076c6:	83 f8 1f             	cmp    $0x1f,%eax
801076c9:	0f 87 bc 00 00 00    	ja     8010778b <trap+0x120>
801076cf:	8b 04 85 08 9a 10 80 	mov    -0x7fef65f8(,%eax,4),%eax
801076d6:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801076d8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801076de:	0f b6 00             	movzbl (%eax),%eax
801076e1:	84 c0                	test   %al,%al
801076e3:	75 31                	jne    80107716 <trap+0xab>
      acquire(&tickslock);
801076e5:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801076ec:	e8 66 e5 ff ff       	call   80105c57 <acquire>
      ticks++;
801076f1:	a1 e0 36 11 80       	mov    0x801136e0,%eax
801076f6:	83 c0 01             	add    $0x1,%eax
801076f9:	a3 e0 36 11 80       	mov    %eax,0x801136e0
      wakeup(&ticks);
801076fe:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
80107705:	e8 48 e3 ff ff       	call   80105a52 <wakeup>
      release(&tickslock);
8010770a:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107711:	e8 a3 e5 ff ff       	call   80105cb9 <release>
    }
    lapiceoi();
80107716:	e8 82 c8 ff ff       	call   80103f9d <lapiceoi>
    break;
8010771b:	e9 41 01 00 00       	jmp    80107861 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107720:	e8 80 c0 ff ff       	call   801037a5 <ideintr>
    lapiceoi();
80107725:	e8 73 c8 ff ff       	call   80103f9d <lapiceoi>
    break;
8010772a:	e9 32 01 00 00       	jmp    80107861 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010772f:	e8 47 c6 ff ff       	call   80103d7b <kbdintr>
    lapiceoi();
80107734:	e8 64 c8 ff ff       	call   80103f9d <lapiceoi>
    break;
80107739:	e9 23 01 00 00       	jmp    80107861 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010773e:	e8 a9 03 00 00       	call   80107aec <uartintr>
    lapiceoi();
80107743:	e8 55 c8 ff ff       	call   80103f9d <lapiceoi>
    break;
80107748:	e9 14 01 00 00       	jmp    80107861 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
8010774d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107750:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107753:	8b 45 08             	mov    0x8(%ebp),%eax
80107756:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010775a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010775d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107763:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107766:	0f b6 c0             	movzbl %al,%eax
80107769:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010776d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107771:	89 44 24 04          	mov    %eax,0x4(%esp)
80107775:	c7 04 24 68 99 10 80 	movl   $0x80109968,(%esp)
8010777c:	e8 20 8c ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107781:	e8 17 c8 ff ff       	call   80103f9d <lapiceoi>
    break;
80107786:	e9 d6 00 00 00       	jmp    80107861 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010778b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107791:	85 c0                	test   %eax,%eax
80107793:	74 11                	je     801077a6 <trap+0x13b>
80107795:	8b 45 08             	mov    0x8(%ebp),%eax
80107798:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010779c:	0f b7 c0             	movzwl %ax,%eax
8010779f:	83 e0 03             	and    $0x3,%eax
801077a2:	85 c0                	test   %eax,%eax
801077a4:	75 46                	jne    801077ec <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801077a6:	e8 1a fd ff ff       	call   801074c5 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801077ab:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801077ae:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801077b1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801077b8:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801077bb:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801077be:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801077c1:	8b 52 30             	mov    0x30(%edx),%edx
801077c4:	89 44 24 10          	mov    %eax,0x10(%esp)
801077c8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801077cc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801077d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801077d4:	c7 04 24 8c 99 10 80 	movl   $0x8010998c,(%esp)
801077db:	e8 c1 8b ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801077e0:	c7 04 24 be 99 10 80 	movl   $0x801099be,(%esp)
801077e7:	e8 51 8d ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077ec:	e8 d4 fc ff ff       	call   801074c5 <rcr2>
801077f1:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077f3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801077f6:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801077f9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801077ff:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107802:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107805:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107808:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010780b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010780e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107811:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107817:	83 c0 6c             	add    $0x6c,%eax
8010781a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010781d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107823:	8b 40 10             	mov    0x10(%eax),%eax
80107826:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010782a:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010782e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107832:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107836:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010783a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010783d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107841:	89 44 24 04          	mov    %eax,0x4(%esp)
80107845:	c7 04 24 c4 99 10 80 	movl   $0x801099c4,(%esp)
8010784c:	e8 50 8b ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107851:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107857:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010785e:	eb 01                	jmp    80107861 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107860:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107861:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107867:	85 c0                	test   %eax,%eax
80107869:	74 24                	je     8010788f <trap+0x224>
8010786b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107871:	8b 40 24             	mov    0x24(%eax),%eax
80107874:	85 c0                	test   %eax,%eax
80107876:	74 17                	je     8010788f <trap+0x224>
80107878:	8b 45 08             	mov    0x8(%ebp),%eax
8010787b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010787f:	0f b7 c0             	movzwl %ax,%eax
80107882:	83 e0 03             	and    $0x3,%eax
80107885:	83 f8 03             	cmp    $0x3,%eax
80107888:	75 05                	jne    8010788f <trap+0x224>
    exit();
8010788a:	e8 7a dc ff ff       	call   80105509 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010788f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107895:	85 c0                	test   %eax,%eax
80107897:	74 1e                	je     801078b7 <trap+0x24c>
80107899:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010789f:	8b 40 0c             	mov    0xc(%eax),%eax
801078a2:	83 f8 04             	cmp    $0x4,%eax
801078a5:	75 10                	jne    801078b7 <trap+0x24c>
801078a7:	8b 45 08             	mov    0x8(%ebp),%eax
801078aa:	8b 40 30             	mov    0x30(%eax),%eax
801078ad:	83 f8 20             	cmp    $0x20,%eax
801078b0:	75 05                	jne    801078b7 <trap+0x24c>
    yield();
801078b2:	e8 64 e0 ff ff       	call   8010591b <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801078b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078bd:	85 c0                	test   %eax,%eax
801078bf:	74 27                	je     801078e8 <trap+0x27d>
801078c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078c7:	8b 40 24             	mov    0x24(%eax),%eax
801078ca:	85 c0                	test   %eax,%eax
801078cc:	74 1a                	je     801078e8 <trap+0x27d>
801078ce:	8b 45 08             	mov    0x8(%ebp),%eax
801078d1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801078d5:	0f b7 c0             	movzwl %ax,%eax
801078d8:	83 e0 03             	and    $0x3,%eax
801078db:	83 f8 03             	cmp    $0x3,%eax
801078de:	75 08                	jne    801078e8 <trap+0x27d>
    exit();
801078e0:	e8 24 dc ff ff       	call   80105509 <exit>
801078e5:	eb 01                	jmp    801078e8 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801078e7:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801078e8:	83 c4 3c             	add    $0x3c,%esp
801078eb:	5b                   	pop    %ebx
801078ec:	5e                   	pop    %esi
801078ed:	5f                   	pop    %edi
801078ee:	5d                   	pop    %ebp
801078ef:	c3                   	ret    

801078f0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801078f0:	55                   	push   %ebp
801078f1:	89 e5                	mov    %esp,%ebp
801078f3:	53                   	push   %ebx
801078f4:	83 ec 14             	sub    $0x14,%esp
801078f7:	8b 45 08             	mov    0x8(%ebp),%eax
801078fa:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801078fe:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107902:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107906:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010790a:	ec                   	in     (%dx),%al
8010790b:	89 c3                	mov    %eax,%ebx
8010790d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107910:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107914:	83 c4 14             	add    $0x14,%esp
80107917:	5b                   	pop    %ebx
80107918:	5d                   	pop    %ebp
80107919:	c3                   	ret    

8010791a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010791a:	55                   	push   %ebp
8010791b:	89 e5                	mov    %esp,%ebp
8010791d:	83 ec 08             	sub    $0x8,%esp
80107920:	8b 55 08             	mov    0x8(%ebp),%edx
80107923:	8b 45 0c             	mov    0xc(%ebp),%eax
80107926:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010792a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010792d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107931:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107935:	ee                   	out    %al,(%dx)
}
80107936:	c9                   	leave  
80107937:	c3                   	ret    

80107938 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107938:	55                   	push   %ebp
80107939:	89 e5                	mov    %esp,%ebp
8010793b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010793e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107945:	00 
80107946:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010794d:	e8 c8 ff ff ff       	call   8010791a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107952:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107959:	00 
8010795a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107961:	e8 b4 ff ff ff       	call   8010791a <outb>
  outb(COM1+0, 115200/9600);
80107966:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010796d:	00 
8010796e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107975:	e8 a0 ff ff ff       	call   8010791a <outb>
  outb(COM1+1, 0);
8010797a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107981:	00 
80107982:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107989:	e8 8c ff ff ff       	call   8010791a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010798e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107995:	00 
80107996:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010799d:	e8 78 ff ff ff       	call   8010791a <outb>
  outb(COM1+4, 0);
801079a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801079a9:	00 
801079aa:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801079b1:	e8 64 ff ff ff       	call   8010791a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801079b6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801079bd:	00 
801079be:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801079c5:	e8 50 ff ff ff       	call   8010791a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801079ca:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801079d1:	e8 1a ff ff ff       	call   801078f0 <inb>
801079d6:	3c ff                	cmp    $0xff,%al
801079d8:	74 6c                	je     80107a46 <uartinit+0x10e>
    return;
  uart = 1;
801079da:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801079e1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801079e4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801079eb:	e8 00 ff ff ff       	call   801078f0 <inb>
  inb(COM1+0);
801079f0:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801079f7:	e8 f4 fe ff ff       	call   801078f0 <inb>
  picenable(IRQ_COM1);
801079fc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107a03:	e8 6d d1 ff ff       	call   80104b75 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107a08:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a0f:	00 
80107a10:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107a17:	e8 0e c0 ff ff       	call   80103a2a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107a1c:	c7 45 f4 88 9a 10 80 	movl   $0x80109a88,-0xc(%ebp)
80107a23:	eb 15                	jmp    80107a3a <uartinit+0x102>
    uartputc(*p);
80107a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a28:	0f b6 00             	movzbl (%eax),%eax
80107a2b:	0f be c0             	movsbl %al,%eax
80107a2e:	89 04 24             	mov    %eax,(%esp)
80107a31:	e8 13 00 00 00       	call   80107a49 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107a36:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107a3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a3d:	0f b6 00             	movzbl (%eax),%eax
80107a40:	84 c0                	test   %al,%al
80107a42:	75 e1                	jne    80107a25 <uartinit+0xed>
80107a44:	eb 01                	jmp    80107a47 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107a46:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107a47:	c9                   	leave  
80107a48:	c3                   	ret    

80107a49 <uartputc>:

void
uartputc(int c)
{
80107a49:	55                   	push   %ebp
80107a4a:	89 e5                	mov    %esp,%ebp
80107a4c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107a4f:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107a54:	85 c0                	test   %eax,%eax
80107a56:	74 4d                	je     80107aa5 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107a58:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107a5f:	eb 10                	jmp    80107a71 <uartputc+0x28>
    microdelay(10);
80107a61:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107a68:	e8 55 c5 ff ff       	call   80103fc2 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107a6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107a71:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107a75:	7f 16                	jg     80107a8d <uartputc+0x44>
80107a77:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107a7e:	e8 6d fe ff ff       	call   801078f0 <inb>
80107a83:	0f b6 c0             	movzbl %al,%eax
80107a86:	83 e0 20             	and    $0x20,%eax
80107a89:	85 c0                	test   %eax,%eax
80107a8b:	74 d4                	je     80107a61 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80107a90:	0f b6 c0             	movzbl %al,%eax
80107a93:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a97:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107a9e:	e8 77 fe ff ff       	call   8010791a <outb>
80107aa3:	eb 01                	jmp    80107aa6 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107aa5:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107aa6:	c9                   	leave  
80107aa7:	c3                   	ret    

80107aa8 <uartgetc>:

static int
uartgetc(void)
{
80107aa8:	55                   	push   %ebp
80107aa9:	89 e5                	mov    %esp,%ebp
80107aab:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107aae:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107ab3:	85 c0                	test   %eax,%eax
80107ab5:	75 07                	jne    80107abe <uartgetc+0x16>
    return -1;
80107ab7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107abc:	eb 2c                	jmp    80107aea <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107abe:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ac5:	e8 26 fe ff ff       	call   801078f0 <inb>
80107aca:	0f b6 c0             	movzbl %al,%eax
80107acd:	83 e0 01             	and    $0x1,%eax
80107ad0:	85 c0                	test   %eax,%eax
80107ad2:	75 07                	jne    80107adb <uartgetc+0x33>
    return -1;
80107ad4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107ad9:	eb 0f                	jmp    80107aea <uartgetc+0x42>
  return inb(COM1+0);
80107adb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107ae2:	e8 09 fe ff ff       	call   801078f0 <inb>
80107ae7:	0f b6 c0             	movzbl %al,%eax
}
80107aea:	c9                   	leave  
80107aeb:	c3                   	ret    

80107aec <uartintr>:

void
uartintr(void)
{
80107aec:	55                   	push   %ebp
80107aed:	89 e5                	mov    %esp,%ebp
80107aef:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107af2:	c7 04 24 a8 7a 10 80 	movl   $0x80107aa8,(%esp)
80107af9:	e8 af 8c ff ff       	call   801007ad <consoleintr>
}
80107afe:	c9                   	leave  
80107aff:	c3                   	ret    

80107b00 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107b00:	6a 00                	push   $0x0
  pushl $0
80107b02:	6a 00                	push   $0x0
  jmp alltraps
80107b04:	e9 67 f9 ff ff       	jmp    80107470 <alltraps>

80107b09 <vector1>:
.globl vector1
vector1:
  pushl $0
80107b09:	6a 00                	push   $0x0
  pushl $1
80107b0b:	6a 01                	push   $0x1
  jmp alltraps
80107b0d:	e9 5e f9 ff ff       	jmp    80107470 <alltraps>

80107b12 <vector2>:
.globl vector2
vector2:
  pushl $0
80107b12:	6a 00                	push   $0x0
  pushl $2
80107b14:	6a 02                	push   $0x2
  jmp alltraps
80107b16:	e9 55 f9 ff ff       	jmp    80107470 <alltraps>

80107b1b <vector3>:
.globl vector3
vector3:
  pushl $0
80107b1b:	6a 00                	push   $0x0
  pushl $3
80107b1d:	6a 03                	push   $0x3
  jmp alltraps
80107b1f:	e9 4c f9 ff ff       	jmp    80107470 <alltraps>

80107b24 <vector4>:
.globl vector4
vector4:
  pushl $0
80107b24:	6a 00                	push   $0x0
  pushl $4
80107b26:	6a 04                	push   $0x4
  jmp alltraps
80107b28:	e9 43 f9 ff ff       	jmp    80107470 <alltraps>

80107b2d <vector5>:
.globl vector5
vector5:
  pushl $0
80107b2d:	6a 00                	push   $0x0
  pushl $5
80107b2f:	6a 05                	push   $0x5
  jmp alltraps
80107b31:	e9 3a f9 ff ff       	jmp    80107470 <alltraps>

80107b36 <vector6>:
.globl vector6
vector6:
  pushl $0
80107b36:	6a 00                	push   $0x0
  pushl $6
80107b38:	6a 06                	push   $0x6
  jmp alltraps
80107b3a:	e9 31 f9 ff ff       	jmp    80107470 <alltraps>

80107b3f <vector7>:
.globl vector7
vector7:
  pushl $0
80107b3f:	6a 00                	push   $0x0
  pushl $7
80107b41:	6a 07                	push   $0x7
  jmp alltraps
80107b43:	e9 28 f9 ff ff       	jmp    80107470 <alltraps>

80107b48 <vector8>:
.globl vector8
vector8:
  pushl $8
80107b48:	6a 08                	push   $0x8
  jmp alltraps
80107b4a:	e9 21 f9 ff ff       	jmp    80107470 <alltraps>

80107b4f <vector9>:
.globl vector9
vector9:
  pushl $0
80107b4f:	6a 00                	push   $0x0
  pushl $9
80107b51:	6a 09                	push   $0x9
  jmp alltraps
80107b53:	e9 18 f9 ff ff       	jmp    80107470 <alltraps>

80107b58 <vector10>:
.globl vector10
vector10:
  pushl $10
80107b58:	6a 0a                	push   $0xa
  jmp alltraps
80107b5a:	e9 11 f9 ff ff       	jmp    80107470 <alltraps>

80107b5f <vector11>:
.globl vector11
vector11:
  pushl $11
80107b5f:	6a 0b                	push   $0xb
  jmp alltraps
80107b61:	e9 0a f9 ff ff       	jmp    80107470 <alltraps>

80107b66 <vector12>:
.globl vector12
vector12:
  pushl $12
80107b66:	6a 0c                	push   $0xc
  jmp alltraps
80107b68:	e9 03 f9 ff ff       	jmp    80107470 <alltraps>

80107b6d <vector13>:
.globl vector13
vector13:
  pushl $13
80107b6d:	6a 0d                	push   $0xd
  jmp alltraps
80107b6f:	e9 fc f8 ff ff       	jmp    80107470 <alltraps>

80107b74 <vector14>:
.globl vector14
vector14:
  pushl $14
80107b74:	6a 0e                	push   $0xe
  jmp alltraps
80107b76:	e9 f5 f8 ff ff       	jmp    80107470 <alltraps>

80107b7b <vector15>:
.globl vector15
vector15:
  pushl $0
80107b7b:	6a 00                	push   $0x0
  pushl $15
80107b7d:	6a 0f                	push   $0xf
  jmp alltraps
80107b7f:	e9 ec f8 ff ff       	jmp    80107470 <alltraps>

80107b84 <vector16>:
.globl vector16
vector16:
  pushl $0
80107b84:	6a 00                	push   $0x0
  pushl $16
80107b86:	6a 10                	push   $0x10
  jmp alltraps
80107b88:	e9 e3 f8 ff ff       	jmp    80107470 <alltraps>

80107b8d <vector17>:
.globl vector17
vector17:
  pushl $17
80107b8d:	6a 11                	push   $0x11
  jmp alltraps
80107b8f:	e9 dc f8 ff ff       	jmp    80107470 <alltraps>

80107b94 <vector18>:
.globl vector18
vector18:
  pushl $0
80107b94:	6a 00                	push   $0x0
  pushl $18
80107b96:	6a 12                	push   $0x12
  jmp alltraps
80107b98:	e9 d3 f8 ff ff       	jmp    80107470 <alltraps>

80107b9d <vector19>:
.globl vector19
vector19:
  pushl $0
80107b9d:	6a 00                	push   $0x0
  pushl $19
80107b9f:	6a 13                	push   $0x13
  jmp alltraps
80107ba1:	e9 ca f8 ff ff       	jmp    80107470 <alltraps>

80107ba6 <vector20>:
.globl vector20
vector20:
  pushl $0
80107ba6:	6a 00                	push   $0x0
  pushl $20
80107ba8:	6a 14                	push   $0x14
  jmp alltraps
80107baa:	e9 c1 f8 ff ff       	jmp    80107470 <alltraps>

80107baf <vector21>:
.globl vector21
vector21:
  pushl $0
80107baf:	6a 00                	push   $0x0
  pushl $21
80107bb1:	6a 15                	push   $0x15
  jmp alltraps
80107bb3:	e9 b8 f8 ff ff       	jmp    80107470 <alltraps>

80107bb8 <vector22>:
.globl vector22
vector22:
  pushl $0
80107bb8:	6a 00                	push   $0x0
  pushl $22
80107bba:	6a 16                	push   $0x16
  jmp alltraps
80107bbc:	e9 af f8 ff ff       	jmp    80107470 <alltraps>

80107bc1 <vector23>:
.globl vector23
vector23:
  pushl $0
80107bc1:	6a 00                	push   $0x0
  pushl $23
80107bc3:	6a 17                	push   $0x17
  jmp alltraps
80107bc5:	e9 a6 f8 ff ff       	jmp    80107470 <alltraps>

80107bca <vector24>:
.globl vector24
vector24:
  pushl $0
80107bca:	6a 00                	push   $0x0
  pushl $24
80107bcc:	6a 18                	push   $0x18
  jmp alltraps
80107bce:	e9 9d f8 ff ff       	jmp    80107470 <alltraps>

80107bd3 <vector25>:
.globl vector25
vector25:
  pushl $0
80107bd3:	6a 00                	push   $0x0
  pushl $25
80107bd5:	6a 19                	push   $0x19
  jmp alltraps
80107bd7:	e9 94 f8 ff ff       	jmp    80107470 <alltraps>

80107bdc <vector26>:
.globl vector26
vector26:
  pushl $0
80107bdc:	6a 00                	push   $0x0
  pushl $26
80107bde:	6a 1a                	push   $0x1a
  jmp alltraps
80107be0:	e9 8b f8 ff ff       	jmp    80107470 <alltraps>

80107be5 <vector27>:
.globl vector27
vector27:
  pushl $0
80107be5:	6a 00                	push   $0x0
  pushl $27
80107be7:	6a 1b                	push   $0x1b
  jmp alltraps
80107be9:	e9 82 f8 ff ff       	jmp    80107470 <alltraps>

80107bee <vector28>:
.globl vector28
vector28:
  pushl $0
80107bee:	6a 00                	push   $0x0
  pushl $28
80107bf0:	6a 1c                	push   $0x1c
  jmp alltraps
80107bf2:	e9 79 f8 ff ff       	jmp    80107470 <alltraps>

80107bf7 <vector29>:
.globl vector29
vector29:
  pushl $0
80107bf7:	6a 00                	push   $0x0
  pushl $29
80107bf9:	6a 1d                	push   $0x1d
  jmp alltraps
80107bfb:	e9 70 f8 ff ff       	jmp    80107470 <alltraps>

80107c00 <vector30>:
.globl vector30
vector30:
  pushl $0
80107c00:	6a 00                	push   $0x0
  pushl $30
80107c02:	6a 1e                	push   $0x1e
  jmp alltraps
80107c04:	e9 67 f8 ff ff       	jmp    80107470 <alltraps>

80107c09 <vector31>:
.globl vector31
vector31:
  pushl $0
80107c09:	6a 00                	push   $0x0
  pushl $31
80107c0b:	6a 1f                	push   $0x1f
  jmp alltraps
80107c0d:	e9 5e f8 ff ff       	jmp    80107470 <alltraps>

80107c12 <vector32>:
.globl vector32
vector32:
  pushl $0
80107c12:	6a 00                	push   $0x0
  pushl $32
80107c14:	6a 20                	push   $0x20
  jmp alltraps
80107c16:	e9 55 f8 ff ff       	jmp    80107470 <alltraps>

80107c1b <vector33>:
.globl vector33
vector33:
  pushl $0
80107c1b:	6a 00                	push   $0x0
  pushl $33
80107c1d:	6a 21                	push   $0x21
  jmp alltraps
80107c1f:	e9 4c f8 ff ff       	jmp    80107470 <alltraps>

80107c24 <vector34>:
.globl vector34
vector34:
  pushl $0
80107c24:	6a 00                	push   $0x0
  pushl $34
80107c26:	6a 22                	push   $0x22
  jmp alltraps
80107c28:	e9 43 f8 ff ff       	jmp    80107470 <alltraps>

80107c2d <vector35>:
.globl vector35
vector35:
  pushl $0
80107c2d:	6a 00                	push   $0x0
  pushl $35
80107c2f:	6a 23                	push   $0x23
  jmp alltraps
80107c31:	e9 3a f8 ff ff       	jmp    80107470 <alltraps>

80107c36 <vector36>:
.globl vector36
vector36:
  pushl $0
80107c36:	6a 00                	push   $0x0
  pushl $36
80107c38:	6a 24                	push   $0x24
  jmp alltraps
80107c3a:	e9 31 f8 ff ff       	jmp    80107470 <alltraps>

80107c3f <vector37>:
.globl vector37
vector37:
  pushl $0
80107c3f:	6a 00                	push   $0x0
  pushl $37
80107c41:	6a 25                	push   $0x25
  jmp alltraps
80107c43:	e9 28 f8 ff ff       	jmp    80107470 <alltraps>

80107c48 <vector38>:
.globl vector38
vector38:
  pushl $0
80107c48:	6a 00                	push   $0x0
  pushl $38
80107c4a:	6a 26                	push   $0x26
  jmp alltraps
80107c4c:	e9 1f f8 ff ff       	jmp    80107470 <alltraps>

80107c51 <vector39>:
.globl vector39
vector39:
  pushl $0
80107c51:	6a 00                	push   $0x0
  pushl $39
80107c53:	6a 27                	push   $0x27
  jmp alltraps
80107c55:	e9 16 f8 ff ff       	jmp    80107470 <alltraps>

80107c5a <vector40>:
.globl vector40
vector40:
  pushl $0
80107c5a:	6a 00                	push   $0x0
  pushl $40
80107c5c:	6a 28                	push   $0x28
  jmp alltraps
80107c5e:	e9 0d f8 ff ff       	jmp    80107470 <alltraps>

80107c63 <vector41>:
.globl vector41
vector41:
  pushl $0
80107c63:	6a 00                	push   $0x0
  pushl $41
80107c65:	6a 29                	push   $0x29
  jmp alltraps
80107c67:	e9 04 f8 ff ff       	jmp    80107470 <alltraps>

80107c6c <vector42>:
.globl vector42
vector42:
  pushl $0
80107c6c:	6a 00                	push   $0x0
  pushl $42
80107c6e:	6a 2a                	push   $0x2a
  jmp alltraps
80107c70:	e9 fb f7 ff ff       	jmp    80107470 <alltraps>

80107c75 <vector43>:
.globl vector43
vector43:
  pushl $0
80107c75:	6a 00                	push   $0x0
  pushl $43
80107c77:	6a 2b                	push   $0x2b
  jmp alltraps
80107c79:	e9 f2 f7 ff ff       	jmp    80107470 <alltraps>

80107c7e <vector44>:
.globl vector44
vector44:
  pushl $0
80107c7e:	6a 00                	push   $0x0
  pushl $44
80107c80:	6a 2c                	push   $0x2c
  jmp alltraps
80107c82:	e9 e9 f7 ff ff       	jmp    80107470 <alltraps>

80107c87 <vector45>:
.globl vector45
vector45:
  pushl $0
80107c87:	6a 00                	push   $0x0
  pushl $45
80107c89:	6a 2d                	push   $0x2d
  jmp alltraps
80107c8b:	e9 e0 f7 ff ff       	jmp    80107470 <alltraps>

80107c90 <vector46>:
.globl vector46
vector46:
  pushl $0
80107c90:	6a 00                	push   $0x0
  pushl $46
80107c92:	6a 2e                	push   $0x2e
  jmp alltraps
80107c94:	e9 d7 f7 ff ff       	jmp    80107470 <alltraps>

80107c99 <vector47>:
.globl vector47
vector47:
  pushl $0
80107c99:	6a 00                	push   $0x0
  pushl $47
80107c9b:	6a 2f                	push   $0x2f
  jmp alltraps
80107c9d:	e9 ce f7 ff ff       	jmp    80107470 <alltraps>

80107ca2 <vector48>:
.globl vector48
vector48:
  pushl $0
80107ca2:	6a 00                	push   $0x0
  pushl $48
80107ca4:	6a 30                	push   $0x30
  jmp alltraps
80107ca6:	e9 c5 f7 ff ff       	jmp    80107470 <alltraps>

80107cab <vector49>:
.globl vector49
vector49:
  pushl $0
80107cab:	6a 00                	push   $0x0
  pushl $49
80107cad:	6a 31                	push   $0x31
  jmp alltraps
80107caf:	e9 bc f7 ff ff       	jmp    80107470 <alltraps>

80107cb4 <vector50>:
.globl vector50
vector50:
  pushl $0
80107cb4:	6a 00                	push   $0x0
  pushl $50
80107cb6:	6a 32                	push   $0x32
  jmp alltraps
80107cb8:	e9 b3 f7 ff ff       	jmp    80107470 <alltraps>

80107cbd <vector51>:
.globl vector51
vector51:
  pushl $0
80107cbd:	6a 00                	push   $0x0
  pushl $51
80107cbf:	6a 33                	push   $0x33
  jmp alltraps
80107cc1:	e9 aa f7 ff ff       	jmp    80107470 <alltraps>

80107cc6 <vector52>:
.globl vector52
vector52:
  pushl $0
80107cc6:	6a 00                	push   $0x0
  pushl $52
80107cc8:	6a 34                	push   $0x34
  jmp alltraps
80107cca:	e9 a1 f7 ff ff       	jmp    80107470 <alltraps>

80107ccf <vector53>:
.globl vector53
vector53:
  pushl $0
80107ccf:	6a 00                	push   $0x0
  pushl $53
80107cd1:	6a 35                	push   $0x35
  jmp alltraps
80107cd3:	e9 98 f7 ff ff       	jmp    80107470 <alltraps>

80107cd8 <vector54>:
.globl vector54
vector54:
  pushl $0
80107cd8:	6a 00                	push   $0x0
  pushl $54
80107cda:	6a 36                	push   $0x36
  jmp alltraps
80107cdc:	e9 8f f7 ff ff       	jmp    80107470 <alltraps>

80107ce1 <vector55>:
.globl vector55
vector55:
  pushl $0
80107ce1:	6a 00                	push   $0x0
  pushl $55
80107ce3:	6a 37                	push   $0x37
  jmp alltraps
80107ce5:	e9 86 f7 ff ff       	jmp    80107470 <alltraps>

80107cea <vector56>:
.globl vector56
vector56:
  pushl $0
80107cea:	6a 00                	push   $0x0
  pushl $56
80107cec:	6a 38                	push   $0x38
  jmp alltraps
80107cee:	e9 7d f7 ff ff       	jmp    80107470 <alltraps>

80107cf3 <vector57>:
.globl vector57
vector57:
  pushl $0
80107cf3:	6a 00                	push   $0x0
  pushl $57
80107cf5:	6a 39                	push   $0x39
  jmp alltraps
80107cf7:	e9 74 f7 ff ff       	jmp    80107470 <alltraps>

80107cfc <vector58>:
.globl vector58
vector58:
  pushl $0
80107cfc:	6a 00                	push   $0x0
  pushl $58
80107cfe:	6a 3a                	push   $0x3a
  jmp alltraps
80107d00:	e9 6b f7 ff ff       	jmp    80107470 <alltraps>

80107d05 <vector59>:
.globl vector59
vector59:
  pushl $0
80107d05:	6a 00                	push   $0x0
  pushl $59
80107d07:	6a 3b                	push   $0x3b
  jmp alltraps
80107d09:	e9 62 f7 ff ff       	jmp    80107470 <alltraps>

80107d0e <vector60>:
.globl vector60
vector60:
  pushl $0
80107d0e:	6a 00                	push   $0x0
  pushl $60
80107d10:	6a 3c                	push   $0x3c
  jmp alltraps
80107d12:	e9 59 f7 ff ff       	jmp    80107470 <alltraps>

80107d17 <vector61>:
.globl vector61
vector61:
  pushl $0
80107d17:	6a 00                	push   $0x0
  pushl $61
80107d19:	6a 3d                	push   $0x3d
  jmp alltraps
80107d1b:	e9 50 f7 ff ff       	jmp    80107470 <alltraps>

80107d20 <vector62>:
.globl vector62
vector62:
  pushl $0
80107d20:	6a 00                	push   $0x0
  pushl $62
80107d22:	6a 3e                	push   $0x3e
  jmp alltraps
80107d24:	e9 47 f7 ff ff       	jmp    80107470 <alltraps>

80107d29 <vector63>:
.globl vector63
vector63:
  pushl $0
80107d29:	6a 00                	push   $0x0
  pushl $63
80107d2b:	6a 3f                	push   $0x3f
  jmp alltraps
80107d2d:	e9 3e f7 ff ff       	jmp    80107470 <alltraps>

80107d32 <vector64>:
.globl vector64
vector64:
  pushl $0
80107d32:	6a 00                	push   $0x0
  pushl $64
80107d34:	6a 40                	push   $0x40
  jmp alltraps
80107d36:	e9 35 f7 ff ff       	jmp    80107470 <alltraps>

80107d3b <vector65>:
.globl vector65
vector65:
  pushl $0
80107d3b:	6a 00                	push   $0x0
  pushl $65
80107d3d:	6a 41                	push   $0x41
  jmp alltraps
80107d3f:	e9 2c f7 ff ff       	jmp    80107470 <alltraps>

80107d44 <vector66>:
.globl vector66
vector66:
  pushl $0
80107d44:	6a 00                	push   $0x0
  pushl $66
80107d46:	6a 42                	push   $0x42
  jmp alltraps
80107d48:	e9 23 f7 ff ff       	jmp    80107470 <alltraps>

80107d4d <vector67>:
.globl vector67
vector67:
  pushl $0
80107d4d:	6a 00                	push   $0x0
  pushl $67
80107d4f:	6a 43                	push   $0x43
  jmp alltraps
80107d51:	e9 1a f7 ff ff       	jmp    80107470 <alltraps>

80107d56 <vector68>:
.globl vector68
vector68:
  pushl $0
80107d56:	6a 00                	push   $0x0
  pushl $68
80107d58:	6a 44                	push   $0x44
  jmp alltraps
80107d5a:	e9 11 f7 ff ff       	jmp    80107470 <alltraps>

80107d5f <vector69>:
.globl vector69
vector69:
  pushl $0
80107d5f:	6a 00                	push   $0x0
  pushl $69
80107d61:	6a 45                	push   $0x45
  jmp alltraps
80107d63:	e9 08 f7 ff ff       	jmp    80107470 <alltraps>

80107d68 <vector70>:
.globl vector70
vector70:
  pushl $0
80107d68:	6a 00                	push   $0x0
  pushl $70
80107d6a:	6a 46                	push   $0x46
  jmp alltraps
80107d6c:	e9 ff f6 ff ff       	jmp    80107470 <alltraps>

80107d71 <vector71>:
.globl vector71
vector71:
  pushl $0
80107d71:	6a 00                	push   $0x0
  pushl $71
80107d73:	6a 47                	push   $0x47
  jmp alltraps
80107d75:	e9 f6 f6 ff ff       	jmp    80107470 <alltraps>

80107d7a <vector72>:
.globl vector72
vector72:
  pushl $0
80107d7a:	6a 00                	push   $0x0
  pushl $72
80107d7c:	6a 48                	push   $0x48
  jmp alltraps
80107d7e:	e9 ed f6 ff ff       	jmp    80107470 <alltraps>

80107d83 <vector73>:
.globl vector73
vector73:
  pushl $0
80107d83:	6a 00                	push   $0x0
  pushl $73
80107d85:	6a 49                	push   $0x49
  jmp alltraps
80107d87:	e9 e4 f6 ff ff       	jmp    80107470 <alltraps>

80107d8c <vector74>:
.globl vector74
vector74:
  pushl $0
80107d8c:	6a 00                	push   $0x0
  pushl $74
80107d8e:	6a 4a                	push   $0x4a
  jmp alltraps
80107d90:	e9 db f6 ff ff       	jmp    80107470 <alltraps>

80107d95 <vector75>:
.globl vector75
vector75:
  pushl $0
80107d95:	6a 00                	push   $0x0
  pushl $75
80107d97:	6a 4b                	push   $0x4b
  jmp alltraps
80107d99:	e9 d2 f6 ff ff       	jmp    80107470 <alltraps>

80107d9e <vector76>:
.globl vector76
vector76:
  pushl $0
80107d9e:	6a 00                	push   $0x0
  pushl $76
80107da0:	6a 4c                	push   $0x4c
  jmp alltraps
80107da2:	e9 c9 f6 ff ff       	jmp    80107470 <alltraps>

80107da7 <vector77>:
.globl vector77
vector77:
  pushl $0
80107da7:	6a 00                	push   $0x0
  pushl $77
80107da9:	6a 4d                	push   $0x4d
  jmp alltraps
80107dab:	e9 c0 f6 ff ff       	jmp    80107470 <alltraps>

80107db0 <vector78>:
.globl vector78
vector78:
  pushl $0
80107db0:	6a 00                	push   $0x0
  pushl $78
80107db2:	6a 4e                	push   $0x4e
  jmp alltraps
80107db4:	e9 b7 f6 ff ff       	jmp    80107470 <alltraps>

80107db9 <vector79>:
.globl vector79
vector79:
  pushl $0
80107db9:	6a 00                	push   $0x0
  pushl $79
80107dbb:	6a 4f                	push   $0x4f
  jmp alltraps
80107dbd:	e9 ae f6 ff ff       	jmp    80107470 <alltraps>

80107dc2 <vector80>:
.globl vector80
vector80:
  pushl $0
80107dc2:	6a 00                	push   $0x0
  pushl $80
80107dc4:	6a 50                	push   $0x50
  jmp alltraps
80107dc6:	e9 a5 f6 ff ff       	jmp    80107470 <alltraps>

80107dcb <vector81>:
.globl vector81
vector81:
  pushl $0
80107dcb:	6a 00                	push   $0x0
  pushl $81
80107dcd:	6a 51                	push   $0x51
  jmp alltraps
80107dcf:	e9 9c f6 ff ff       	jmp    80107470 <alltraps>

80107dd4 <vector82>:
.globl vector82
vector82:
  pushl $0
80107dd4:	6a 00                	push   $0x0
  pushl $82
80107dd6:	6a 52                	push   $0x52
  jmp alltraps
80107dd8:	e9 93 f6 ff ff       	jmp    80107470 <alltraps>

80107ddd <vector83>:
.globl vector83
vector83:
  pushl $0
80107ddd:	6a 00                	push   $0x0
  pushl $83
80107ddf:	6a 53                	push   $0x53
  jmp alltraps
80107de1:	e9 8a f6 ff ff       	jmp    80107470 <alltraps>

80107de6 <vector84>:
.globl vector84
vector84:
  pushl $0
80107de6:	6a 00                	push   $0x0
  pushl $84
80107de8:	6a 54                	push   $0x54
  jmp alltraps
80107dea:	e9 81 f6 ff ff       	jmp    80107470 <alltraps>

80107def <vector85>:
.globl vector85
vector85:
  pushl $0
80107def:	6a 00                	push   $0x0
  pushl $85
80107df1:	6a 55                	push   $0x55
  jmp alltraps
80107df3:	e9 78 f6 ff ff       	jmp    80107470 <alltraps>

80107df8 <vector86>:
.globl vector86
vector86:
  pushl $0
80107df8:	6a 00                	push   $0x0
  pushl $86
80107dfa:	6a 56                	push   $0x56
  jmp alltraps
80107dfc:	e9 6f f6 ff ff       	jmp    80107470 <alltraps>

80107e01 <vector87>:
.globl vector87
vector87:
  pushl $0
80107e01:	6a 00                	push   $0x0
  pushl $87
80107e03:	6a 57                	push   $0x57
  jmp alltraps
80107e05:	e9 66 f6 ff ff       	jmp    80107470 <alltraps>

80107e0a <vector88>:
.globl vector88
vector88:
  pushl $0
80107e0a:	6a 00                	push   $0x0
  pushl $88
80107e0c:	6a 58                	push   $0x58
  jmp alltraps
80107e0e:	e9 5d f6 ff ff       	jmp    80107470 <alltraps>

80107e13 <vector89>:
.globl vector89
vector89:
  pushl $0
80107e13:	6a 00                	push   $0x0
  pushl $89
80107e15:	6a 59                	push   $0x59
  jmp alltraps
80107e17:	e9 54 f6 ff ff       	jmp    80107470 <alltraps>

80107e1c <vector90>:
.globl vector90
vector90:
  pushl $0
80107e1c:	6a 00                	push   $0x0
  pushl $90
80107e1e:	6a 5a                	push   $0x5a
  jmp alltraps
80107e20:	e9 4b f6 ff ff       	jmp    80107470 <alltraps>

80107e25 <vector91>:
.globl vector91
vector91:
  pushl $0
80107e25:	6a 00                	push   $0x0
  pushl $91
80107e27:	6a 5b                	push   $0x5b
  jmp alltraps
80107e29:	e9 42 f6 ff ff       	jmp    80107470 <alltraps>

80107e2e <vector92>:
.globl vector92
vector92:
  pushl $0
80107e2e:	6a 00                	push   $0x0
  pushl $92
80107e30:	6a 5c                	push   $0x5c
  jmp alltraps
80107e32:	e9 39 f6 ff ff       	jmp    80107470 <alltraps>

80107e37 <vector93>:
.globl vector93
vector93:
  pushl $0
80107e37:	6a 00                	push   $0x0
  pushl $93
80107e39:	6a 5d                	push   $0x5d
  jmp alltraps
80107e3b:	e9 30 f6 ff ff       	jmp    80107470 <alltraps>

80107e40 <vector94>:
.globl vector94
vector94:
  pushl $0
80107e40:	6a 00                	push   $0x0
  pushl $94
80107e42:	6a 5e                	push   $0x5e
  jmp alltraps
80107e44:	e9 27 f6 ff ff       	jmp    80107470 <alltraps>

80107e49 <vector95>:
.globl vector95
vector95:
  pushl $0
80107e49:	6a 00                	push   $0x0
  pushl $95
80107e4b:	6a 5f                	push   $0x5f
  jmp alltraps
80107e4d:	e9 1e f6 ff ff       	jmp    80107470 <alltraps>

80107e52 <vector96>:
.globl vector96
vector96:
  pushl $0
80107e52:	6a 00                	push   $0x0
  pushl $96
80107e54:	6a 60                	push   $0x60
  jmp alltraps
80107e56:	e9 15 f6 ff ff       	jmp    80107470 <alltraps>

80107e5b <vector97>:
.globl vector97
vector97:
  pushl $0
80107e5b:	6a 00                	push   $0x0
  pushl $97
80107e5d:	6a 61                	push   $0x61
  jmp alltraps
80107e5f:	e9 0c f6 ff ff       	jmp    80107470 <alltraps>

80107e64 <vector98>:
.globl vector98
vector98:
  pushl $0
80107e64:	6a 00                	push   $0x0
  pushl $98
80107e66:	6a 62                	push   $0x62
  jmp alltraps
80107e68:	e9 03 f6 ff ff       	jmp    80107470 <alltraps>

80107e6d <vector99>:
.globl vector99
vector99:
  pushl $0
80107e6d:	6a 00                	push   $0x0
  pushl $99
80107e6f:	6a 63                	push   $0x63
  jmp alltraps
80107e71:	e9 fa f5 ff ff       	jmp    80107470 <alltraps>

80107e76 <vector100>:
.globl vector100
vector100:
  pushl $0
80107e76:	6a 00                	push   $0x0
  pushl $100
80107e78:	6a 64                	push   $0x64
  jmp alltraps
80107e7a:	e9 f1 f5 ff ff       	jmp    80107470 <alltraps>

80107e7f <vector101>:
.globl vector101
vector101:
  pushl $0
80107e7f:	6a 00                	push   $0x0
  pushl $101
80107e81:	6a 65                	push   $0x65
  jmp alltraps
80107e83:	e9 e8 f5 ff ff       	jmp    80107470 <alltraps>

80107e88 <vector102>:
.globl vector102
vector102:
  pushl $0
80107e88:	6a 00                	push   $0x0
  pushl $102
80107e8a:	6a 66                	push   $0x66
  jmp alltraps
80107e8c:	e9 df f5 ff ff       	jmp    80107470 <alltraps>

80107e91 <vector103>:
.globl vector103
vector103:
  pushl $0
80107e91:	6a 00                	push   $0x0
  pushl $103
80107e93:	6a 67                	push   $0x67
  jmp alltraps
80107e95:	e9 d6 f5 ff ff       	jmp    80107470 <alltraps>

80107e9a <vector104>:
.globl vector104
vector104:
  pushl $0
80107e9a:	6a 00                	push   $0x0
  pushl $104
80107e9c:	6a 68                	push   $0x68
  jmp alltraps
80107e9e:	e9 cd f5 ff ff       	jmp    80107470 <alltraps>

80107ea3 <vector105>:
.globl vector105
vector105:
  pushl $0
80107ea3:	6a 00                	push   $0x0
  pushl $105
80107ea5:	6a 69                	push   $0x69
  jmp alltraps
80107ea7:	e9 c4 f5 ff ff       	jmp    80107470 <alltraps>

80107eac <vector106>:
.globl vector106
vector106:
  pushl $0
80107eac:	6a 00                	push   $0x0
  pushl $106
80107eae:	6a 6a                	push   $0x6a
  jmp alltraps
80107eb0:	e9 bb f5 ff ff       	jmp    80107470 <alltraps>

80107eb5 <vector107>:
.globl vector107
vector107:
  pushl $0
80107eb5:	6a 00                	push   $0x0
  pushl $107
80107eb7:	6a 6b                	push   $0x6b
  jmp alltraps
80107eb9:	e9 b2 f5 ff ff       	jmp    80107470 <alltraps>

80107ebe <vector108>:
.globl vector108
vector108:
  pushl $0
80107ebe:	6a 00                	push   $0x0
  pushl $108
80107ec0:	6a 6c                	push   $0x6c
  jmp alltraps
80107ec2:	e9 a9 f5 ff ff       	jmp    80107470 <alltraps>

80107ec7 <vector109>:
.globl vector109
vector109:
  pushl $0
80107ec7:	6a 00                	push   $0x0
  pushl $109
80107ec9:	6a 6d                	push   $0x6d
  jmp alltraps
80107ecb:	e9 a0 f5 ff ff       	jmp    80107470 <alltraps>

80107ed0 <vector110>:
.globl vector110
vector110:
  pushl $0
80107ed0:	6a 00                	push   $0x0
  pushl $110
80107ed2:	6a 6e                	push   $0x6e
  jmp alltraps
80107ed4:	e9 97 f5 ff ff       	jmp    80107470 <alltraps>

80107ed9 <vector111>:
.globl vector111
vector111:
  pushl $0
80107ed9:	6a 00                	push   $0x0
  pushl $111
80107edb:	6a 6f                	push   $0x6f
  jmp alltraps
80107edd:	e9 8e f5 ff ff       	jmp    80107470 <alltraps>

80107ee2 <vector112>:
.globl vector112
vector112:
  pushl $0
80107ee2:	6a 00                	push   $0x0
  pushl $112
80107ee4:	6a 70                	push   $0x70
  jmp alltraps
80107ee6:	e9 85 f5 ff ff       	jmp    80107470 <alltraps>

80107eeb <vector113>:
.globl vector113
vector113:
  pushl $0
80107eeb:	6a 00                	push   $0x0
  pushl $113
80107eed:	6a 71                	push   $0x71
  jmp alltraps
80107eef:	e9 7c f5 ff ff       	jmp    80107470 <alltraps>

80107ef4 <vector114>:
.globl vector114
vector114:
  pushl $0
80107ef4:	6a 00                	push   $0x0
  pushl $114
80107ef6:	6a 72                	push   $0x72
  jmp alltraps
80107ef8:	e9 73 f5 ff ff       	jmp    80107470 <alltraps>

80107efd <vector115>:
.globl vector115
vector115:
  pushl $0
80107efd:	6a 00                	push   $0x0
  pushl $115
80107eff:	6a 73                	push   $0x73
  jmp alltraps
80107f01:	e9 6a f5 ff ff       	jmp    80107470 <alltraps>

80107f06 <vector116>:
.globl vector116
vector116:
  pushl $0
80107f06:	6a 00                	push   $0x0
  pushl $116
80107f08:	6a 74                	push   $0x74
  jmp alltraps
80107f0a:	e9 61 f5 ff ff       	jmp    80107470 <alltraps>

80107f0f <vector117>:
.globl vector117
vector117:
  pushl $0
80107f0f:	6a 00                	push   $0x0
  pushl $117
80107f11:	6a 75                	push   $0x75
  jmp alltraps
80107f13:	e9 58 f5 ff ff       	jmp    80107470 <alltraps>

80107f18 <vector118>:
.globl vector118
vector118:
  pushl $0
80107f18:	6a 00                	push   $0x0
  pushl $118
80107f1a:	6a 76                	push   $0x76
  jmp alltraps
80107f1c:	e9 4f f5 ff ff       	jmp    80107470 <alltraps>

80107f21 <vector119>:
.globl vector119
vector119:
  pushl $0
80107f21:	6a 00                	push   $0x0
  pushl $119
80107f23:	6a 77                	push   $0x77
  jmp alltraps
80107f25:	e9 46 f5 ff ff       	jmp    80107470 <alltraps>

80107f2a <vector120>:
.globl vector120
vector120:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $120
80107f2c:	6a 78                	push   $0x78
  jmp alltraps
80107f2e:	e9 3d f5 ff ff       	jmp    80107470 <alltraps>

80107f33 <vector121>:
.globl vector121
vector121:
  pushl $0
80107f33:	6a 00                	push   $0x0
  pushl $121
80107f35:	6a 79                	push   $0x79
  jmp alltraps
80107f37:	e9 34 f5 ff ff       	jmp    80107470 <alltraps>

80107f3c <vector122>:
.globl vector122
vector122:
  pushl $0
80107f3c:	6a 00                	push   $0x0
  pushl $122
80107f3e:	6a 7a                	push   $0x7a
  jmp alltraps
80107f40:	e9 2b f5 ff ff       	jmp    80107470 <alltraps>

80107f45 <vector123>:
.globl vector123
vector123:
  pushl $0
80107f45:	6a 00                	push   $0x0
  pushl $123
80107f47:	6a 7b                	push   $0x7b
  jmp alltraps
80107f49:	e9 22 f5 ff ff       	jmp    80107470 <alltraps>

80107f4e <vector124>:
.globl vector124
vector124:
  pushl $0
80107f4e:	6a 00                	push   $0x0
  pushl $124
80107f50:	6a 7c                	push   $0x7c
  jmp alltraps
80107f52:	e9 19 f5 ff ff       	jmp    80107470 <alltraps>

80107f57 <vector125>:
.globl vector125
vector125:
  pushl $0
80107f57:	6a 00                	push   $0x0
  pushl $125
80107f59:	6a 7d                	push   $0x7d
  jmp alltraps
80107f5b:	e9 10 f5 ff ff       	jmp    80107470 <alltraps>

80107f60 <vector126>:
.globl vector126
vector126:
  pushl $0
80107f60:	6a 00                	push   $0x0
  pushl $126
80107f62:	6a 7e                	push   $0x7e
  jmp alltraps
80107f64:	e9 07 f5 ff ff       	jmp    80107470 <alltraps>

80107f69 <vector127>:
.globl vector127
vector127:
  pushl $0
80107f69:	6a 00                	push   $0x0
  pushl $127
80107f6b:	6a 7f                	push   $0x7f
  jmp alltraps
80107f6d:	e9 fe f4 ff ff       	jmp    80107470 <alltraps>

80107f72 <vector128>:
.globl vector128
vector128:
  pushl $0
80107f72:	6a 00                	push   $0x0
  pushl $128
80107f74:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107f79:	e9 f2 f4 ff ff       	jmp    80107470 <alltraps>

80107f7e <vector129>:
.globl vector129
vector129:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $129
80107f80:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107f85:	e9 e6 f4 ff ff       	jmp    80107470 <alltraps>

80107f8a <vector130>:
.globl vector130
vector130:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $130
80107f8c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107f91:	e9 da f4 ff ff       	jmp    80107470 <alltraps>

80107f96 <vector131>:
.globl vector131
vector131:
  pushl $0
80107f96:	6a 00                	push   $0x0
  pushl $131
80107f98:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107f9d:	e9 ce f4 ff ff       	jmp    80107470 <alltraps>

80107fa2 <vector132>:
.globl vector132
vector132:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $132
80107fa4:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107fa9:	e9 c2 f4 ff ff       	jmp    80107470 <alltraps>

80107fae <vector133>:
.globl vector133
vector133:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $133
80107fb0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107fb5:	e9 b6 f4 ff ff       	jmp    80107470 <alltraps>

80107fba <vector134>:
.globl vector134
vector134:
  pushl $0
80107fba:	6a 00                	push   $0x0
  pushl $134
80107fbc:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107fc1:	e9 aa f4 ff ff       	jmp    80107470 <alltraps>

80107fc6 <vector135>:
.globl vector135
vector135:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $135
80107fc8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107fcd:	e9 9e f4 ff ff       	jmp    80107470 <alltraps>

80107fd2 <vector136>:
.globl vector136
vector136:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $136
80107fd4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107fd9:	e9 92 f4 ff ff       	jmp    80107470 <alltraps>

80107fde <vector137>:
.globl vector137
vector137:
  pushl $0
80107fde:	6a 00                	push   $0x0
  pushl $137
80107fe0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107fe5:	e9 86 f4 ff ff       	jmp    80107470 <alltraps>

80107fea <vector138>:
.globl vector138
vector138:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $138
80107fec:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107ff1:	e9 7a f4 ff ff       	jmp    80107470 <alltraps>

80107ff6 <vector139>:
.globl vector139
vector139:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $139
80107ff8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107ffd:	e9 6e f4 ff ff       	jmp    80107470 <alltraps>

80108002 <vector140>:
.globl vector140
vector140:
  pushl $0
80108002:	6a 00                	push   $0x0
  pushl $140
80108004:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80108009:	e9 62 f4 ff ff       	jmp    80107470 <alltraps>

8010800e <vector141>:
.globl vector141
vector141:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $141
80108010:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80108015:	e9 56 f4 ff ff       	jmp    80107470 <alltraps>

8010801a <vector142>:
.globl vector142
vector142:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $142
8010801c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108021:	e9 4a f4 ff ff       	jmp    80107470 <alltraps>

80108026 <vector143>:
.globl vector143
vector143:
  pushl $0
80108026:	6a 00                	push   $0x0
  pushl $143
80108028:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010802d:	e9 3e f4 ff ff       	jmp    80107470 <alltraps>

80108032 <vector144>:
.globl vector144
vector144:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $144
80108034:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108039:	e9 32 f4 ff ff       	jmp    80107470 <alltraps>

8010803e <vector145>:
.globl vector145
vector145:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $145
80108040:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108045:	e9 26 f4 ff ff       	jmp    80107470 <alltraps>

8010804a <vector146>:
.globl vector146
vector146:
  pushl $0
8010804a:	6a 00                	push   $0x0
  pushl $146
8010804c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108051:	e9 1a f4 ff ff       	jmp    80107470 <alltraps>

80108056 <vector147>:
.globl vector147
vector147:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $147
80108058:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010805d:	e9 0e f4 ff ff       	jmp    80107470 <alltraps>

80108062 <vector148>:
.globl vector148
vector148:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $148
80108064:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108069:	e9 02 f4 ff ff       	jmp    80107470 <alltraps>

8010806e <vector149>:
.globl vector149
vector149:
  pushl $0
8010806e:	6a 00                	push   $0x0
  pushl $149
80108070:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108075:	e9 f6 f3 ff ff       	jmp    80107470 <alltraps>

8010807a <vector150>:
.globl vector150
vector150:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $150
8010807c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80108081:	e9 ea f3 ff ff       	jmp    80107470 <alltraps>

80108086 <vector151>:
.globl vector151
vector151:
  pushl $0
80108086:	6a 00                	push   $0x0
  pushl $151
80108088:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010808d:	e9 de f3 ff ff       	jmp    80107470 <alltraps>

80108092 <vector152>:
.globl vector152
vector152:
  pushl $0
80108092:	6a 00                	push   $0x0
  pushl $152
80108094:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108099:	e9 d2 f3 ff ff       	jmp    80107470 <alltraps>

8010809e <vector153>:
.globl vector153
vector153:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $153
801080a0:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801080a5:	e9 c6 f3 ff ff       	jmp    80107470 <alltraps>

801080aa <vector154>:
.globl vector154
vector154:
  pushl $0
801080aa:	6a 00                	push   $0x0
  pushl $154
801080ac:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801080b1:	e9 ba f3 ff ff       	jmp    80107470 <alltraps>

801080b6 <vector155>:
.globl vector155
vector155:
  pushl $0
801080b6:	6a 00                	push   $0x0
  pushl $155
801080b8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801080bd:	e9 ae f3 ff ff       	jmp    80107470 <alltraps>

801080c2 <vector156>:
.globl vector156
vector156:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $156
801080c4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801080c9:	e9 a2 f3 ff ff       	jmp    80107470 <alltraps>

801080ce <vector157>:
.globl vector157
vector157:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $157
801080d0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801080d5:	e9 96 f3 ff ff       	jmp    80107470 <alltraps>

801080da <vector158>:
.globl vector158
vector158:
  pushl $0
801080da:	6a 00                	push   $0x0
  pushl $158
801080dc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801080e1:	e9 8a f3 ff ff       	jmp    80107470 <alltraps>

801080e6 <vector159>:
.globl vector159
vector159:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $159
801080e8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801080ed:	e9 7e f3 ff ff       	jmp    80107470 <alltraps>

801080f2 <vector160>:
.globl vector160
vector160:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $160
801080f4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801080f9:	e9 72 f3 ff ff       	jmp    80107470 <alltraps>

801080fe <vector161>:
.globl vector161
vector161:
  pushl $0
801080fe:	6a 00                	push   $0x0
  pushl $161
80108100:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80108105:	e9 66 f3 ff ff       	jmp    80107470 <alltraps>

8010810a <vector162>:
.globl vector162
vector162:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $162
8010810c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80108111:	e9 5a f3 ff ff       	jmp    80107470 <alltraps>

80108116 <vector163>:
.globl vector163
vector163:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $163
80108118:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010811d:	e9 4e f3 ff ff       	jmp    80107470 <alltraps>

80108122 <vector164>:
.globl vector164
vector164:
  pushl $0
80108122:	6a 00                	push   $0x0
  pushl $164
80108124:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108129:	e9 42 f3 ff ff       	jmp    80107470 <alltraps>

8010812e <vector165>:
.globl vector165
vector165:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $165
80108130:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108135:	e9 36 f3 ff ff       	jmp    80107470 <alltraps>

8010813a <vector166>:
.globl vector166
vector166:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $166
8010813c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108141:	e9 2a f3 ff ff       	jmp    80107470 <alltraps>

80108146 <vector167>:
.globl vector167
vector167:
  pushl $0
80108146:	6a 00                	push   $0x0
  pushl $167
80108148:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010814d:	e9 1e f3 ff ff       	jmp    80107470 <alltraps>

80108152 <vector168>:
.globl vector168
vector168:
  pushl $0
80108152:	6a 00                	push   $0x0
  pushl $168
80108154:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108159:	e9 12 f3 ff ff       	jmp    80107470 <alltraps>

8010815e <vector169>:
.globl vector169
vector169:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $169
80108160:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108165:	e9 06 f3 ff ff       	jmp    80107470 <alltraps>

8010816a <vector170>:
.globl vector170
vector170:
  pushl $0
8010816a:	6a 00                	push   $0x0
  pushl $170
8010816c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108171:	e9 fa f2 ff ff       	jmp    80107470 <alltraps>

80108176 <vector171>:
.globl vector171
vector171:
  pushl $0
80108176:	6a 00                	push   $0x0
  pushl $171
80108178:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010817d:	e9 ee f2 ff ff       	jmp    80107470 <alltraps>

80108182 <vector172>:
.globl vector172
vector172:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $172
80108184:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108189:	e9 e2 f2 ff ff       	jmp    80107470 <alltraps>

8010818e <vector173>:
.globl vector173
vector173:
  pushl $0
8010818e:	6a 00                	push   $0x0
  pushl $173
80108190:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108195:	e9 d6 f2 ff ff       	jmp    80107470 <alltraps>

8010819a <vector174>:
.globl vector174
vector174:
  pushl $0
8010819a:	6a 00                	push   $0x0
  pushl $174
8010819c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801081a1:	e9 ca f2 ff ff       	jmp    80107470 <alltraps>

801081a6 <vector175>:
.globl vector175
vector175:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $175
801081a8:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801081ad:	e9 be f2 ff ff       	jmp    80107470 <alltraps>

801081b2 <vector176>:
.globl vector176
vector176:
  pushl $0
801081b2:	6a 00                	push   $0x0
  pushl $176
801081b4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801081b9:	e9 b2 f2 ff ff       	jmp    80107470 <alltraps>

801081be <vector177>:
.globl vector177
vector177:
  pushl $0
801081be:	6a 00                	push   $0x0
  pushl $177
801081c0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801081c5:	e9 a6 f2 ff ff       	jmp    80107470 <alltraps>

801081ca <vector178>:
.globl vector178
vector178:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $178
801081cc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801081d1:	e9 9a f2 ff ff       	jmp    80107470 <alltraps>

801081d6 <vector179>:
.globl vector179
vector179:
  pushl $0
801081d6:	6a 00                	push   $0x0
  pushl $179
801081d8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801081dd:	e9 8e f2 ff ff       	jmp    80107470 <alltraps>

801081e2 <vector180>:
.globl vector180
vector180:
  pushl $0
801081e2:	6a 00                	push   $0x0
  pushl $180
801081e4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801081e9:	e9 82 f2 ff ff       	jmp    80107470 <alltraps>

801081ee <vector181>:
.globl vector181
vector181:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $181
801081f0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801081f5:	e9 76 f2 ff ff       	jmp    80107470 <alltraps>

801081fa <vector182>:
.globl vector182
vector182:
  pushl $0
801081fa:	6a 00                	push   $0x0
  pushl $182
801081fc:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80108201:	e9 6a f2 ff ff       	jmp    80107470 <alltraps>

80108206 <vector183>:
.globl vector183
vector183:
  pushl $0
80108206:	6a 00                	push   $0x0
  pushl $183
80108208:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010820d:	e9 5e f2 ff ff       	jmp    80107470 <alltraps>

80108212 <vector184>:
.globl vector184
vector184:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $184
80108214:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108219:	e9 52 f2 ff ff       	jmp    80107470 <alltraps>

8010821e <vector185>:
.globl vector185
vector185:
  pushl $0
8010821e:	6a 00                	push   $0x0
  pushl $185
80108220:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108225:	e9 46 f2 ff ff       	jmp    80107470 <alltraps>

8010822a <vector186>:
.globl vector186
vector186:
  pushl $0
8010822a:	6a 00                	push   $0x0
  pushl $186
8010822c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108231:	e9 3a f2 ff ff       	jmp    80107470 <alltraps>

80108236 <vector187>:
.globl vector187
vector187:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $187
80108238:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010823d:	e9 2e f2 ff ff       	jmp    80107470 <alltraps>

80108242 <vector188>:
.globl vector188
vector188:
  pushl $0
80108242:	6a 00                	push   $0x0
  pushl $188
80108244:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108249:	e9 22 f2 ff ff       	jmp    80107470 <alltraps>

8010824e <vector189>:
.globl vector189
vector189:
  pushl $0
8010824e:	6a 00                	push   $0x0
  pushl $189
80108250:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108255:	e9 16 f2 ff ff       	jmp    80107470 <alltraps>

8010825a <vector190>:
.globl vector190
vector190:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $190
8010825c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108261:	e9 0a f2 ff ff       	jmp    80107470 <alltraps>

80108266 <vector191>:
.globl vector191
vector191:
  pushl $0
80108266:	6a 00                	push   $0x0
  pushl $191
80108268:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010826d:	e9 fe f1 ff ff       	jmp    80107470 <alltraps>

80108272 <vector192>:
.globl vector192
vector192:
  pushl $0
80108272:	6a 00                	push   $0x0
  pushl $192
80108274:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108279:	e9 f2 f1 ff ff       	jmp    80107470 <alltraps>

8010827e <vector193>:
.globl vector193
vector193:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $193
80108280:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108285:	e9 e6 f1 ff ff       	jmp    80107470 <alltraps>

8010828a <vector194>:
.globl vector194
vector194:
  pushl $0
8010828a:	6a 00                	push   $0x0
  pushl $194
8010828c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108291:	e9 da f1 ff ff       	jmp    80107470 <alltraps>

80108296 <vector195>:
.globl vector195
vector195:
  pushl $0
80108296:	6a 00                	push   $0x0
  pushl $195
80108298:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010829d:	e9 ce f1 ff ff       	jmp    80107470 <alltraps>

801082a2 <vector196>:
.globl vector196
vector196:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $196
801082a4:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801082a9:	e9 c2 f1 ff ff       	jmp    80107470 <alltraps>

801082ae <vector197>:
.globl vector197
vector197:
  pushl $0
801082ae:	6a 00                	push   $0x0
  pushl $197
801082b0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801082b5:	e9 b6 f1 ff ff       	jmp    80107470 <alltraps>

801082ba <vector198>:
.globl vector198
vector198:
  pushl $0
801082ba:	6a 00                	push   $0x0
  pushl $198
801082bc:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801082c1:	e9 aa f1 ff ff       	jmp    80107470 <alltraps>

801082c6 <vector199>:
.globl vector199
vector199:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $199
801082c8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801082cd:	e9 9e f1 ff ff       	jmp    80107470 <alltraps>

801082d2 <vector200>:
.globl vector200
vector200:
  pushl $0
801082d2:	6a 00                	push   $0x0
  pushl $200
801082d4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801082d9:	e9 92 f1 ff ff       	jmp    80107470 <alltraps>

801082de <vector201>:
.globl vector201
vector201:
  pushl $0
801082de:	6a 00                	push   $0x0
  pushl $201
801082e0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801082e5:	e9 86 f1 ff ff       	jmp    80107470 <alltraps>

801082ea <vector202>:
.globl vector202
vector202:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $202
801082ec:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801082f1:	e9 7a f1 ff ff       	jmp    80107470 <alltraps>

801082f6 <vector203>:
.globl vector203
vector203:
  pushl $0
801082f6:	6a 00                	push   $0x0
  pushl $203
801082f8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801082fd:	e9 6e f1 ff ff       	jmp    80107470 <alltraps>

80108302 <vector204>:
.globl vector204
vector204:
  pushl $0
80108302:	6a 00                	push   $0x0
  pushl $204
80108304:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108309:	e9 62 f1 ff ff       	jmp    80107470 <alltraps>

8010830e <vector205>:
.globl vector205
vector205:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $205
80108310:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108315:	e9 56 f1 ff ff       	jmp    80107470 <alltraps>

8010831a <vector206>:
.globl vector206
vector206:
  pushl $0
8010831a:	6a 00                	push   $0x0
  pushl $206
8010831c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108321:	e9 4a f1 ff ff       	jmp    80107470 <alltraps>

80108326 <vector207>:
.globl vector207
vector207:
  pushl $0
80108326:	6a 00                	push   $0x0
  pushl $207
80108328:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010832d:	e9 3e f1 ff ff       	jmp    80107470 <alltraps>

80108332 <vector208>:
.globl vector208
vector208:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $208
80108334:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108339:	e9 32 f1 ff ff       	jmp    80107470 <alltraps>

8010833e <vector209>:
.globl vector209
vector209:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $209
80108340:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108345:	e9 26 f1 ff ff       	jmp    80107470 <alltraps>

8010834a <vector210>:
.globl vector210
vector210:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $210
8010834c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108351:	e9 1a f1 ff ff       	jmp    80107470 <alltraps>

80108356 <vector211>:
.globl vector211
vector211:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $211
80108358:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010835d:	e9 0e f1 ff ff       	jmp    80107470 <alltraps>

80108362 <vector212>:
.globl vector212
vector212:
  pushl $0
80108362:	6a 00                	push   $0x0
  pushl $212
80108364:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108369:	e9 02 f1 ff ff       	jmp    80107470 <alltraps>

8010836e <vector213>:
.globl vector213
vector213:
  pushl $0
8010836e:	6a 00                	push   $0x0
  pushl $213
80108370:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108375:	e9 f6 f0 ff ff       	jmp    80107470 <alltraps>

8010837a <vector214>:
.globl vector214
vector214:
  pushl $0
8010837a:	6a 00                	push   $0x0
  pushl $214
8010837c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108381:	e9 ea f0 ff ff       	jmp    80107470 <alltraps>

80108386 <vector215>:
.globl vector215
vector215:
  pushl $0
80108386:	6a 00                	push   $0x0
  pushl $215
80108388:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010838d:	e9 de f0 ff ff       	jmp    80107470 <alltraps>

80108392 <vector216>:
.globl vector216
vector216:
  pushl $0
80108392:	6a 00                	push   $0x0
  pushl $216
80108394:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108399:	e9 d2 f0 ff ff       	jmp    80107470 <alltraps>

8010839e <vector217>:
.globl vector217
vector217:
  pushl $0
8010839e:	6a 00                	push   $0x0
  pushl $217
801083a0:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801083a5:	e9 c6 f0 ff ff       	jmp    80107470 <alltraps>

801083aa <vector218>:
.globl vector218
vector218:
  pushl $0
801083aa:	6a 00                	push   $0x0
  pushl $218
801083ac:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801083b1:	e9 ba f0 ff ff       	jmp    80107470 <alltraps>

801083b6 <vector219>:
.globl vector219
vector219:
  pushl $0
801083b6:	6a 00                	push   $0x0
  pushl $219
801083b8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801083bd:	e9 ae f0 ff ff       	jmp    80107470 <alltraps>

801083c2 <vector220>:
.globl vector220
vector220:
  pushl $0
801083c2:	6a 00                	push   $0x0
  pushl $220
801083c4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801083c9:	e9 a2 f0 ff ff       	jmp    80107470 <alltraps>

801083ce <vector221>:
.globl vector221
vector221:
  pushl $0
801083ce:	6a 00                	push   $0x0
  pushl $221
801083d0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801083d5:	e9 96 f0 ff ff       	jmp    80107470 <alltraps>

801083da <vector222>:
.globl vector222
vector222:
  pushl $0
801083da:	6a 00                	push   $0x0
  pushl $222
801083dc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801083e1:	e9 8a f0 ff ff       	jmp    80107470 <alltraps>

801083e6 <vector223>:
.globl vector223
vector223:
  pushl $0
801083e6:	6a 00                	push   $0x0
  pushl $223
801083e8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801083ed:	e9 7e f0 ff ff       	jmp    80107470 <alltraps>

801083f2 <vector224>:
.globl vector224
vector224:
  pushl $0
801083f2:	6a 00                	push   $0x0
  pushl $224
801083f4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801083f9:	e9 72 f0 ff ff       	jmp    80107470 <alltraps>

801083fe <vector225>:
.globl vector225
vector225:
  pushl $0
801083fe:	6a 00                	push   $0x0
  pushl $225
80108400:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108405:	e9 66 f0 ff ff       	jmp    80107470 <alltraps>

8010840a <vector226>:
.globl vector226
vector226:
  pushl $0
8010840a:	6a 00                	push   $0x0
  pushl $226
8010840c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108411:	e9 5a f0 ff ff       	jmp    80107470 <alltraps>

80108416 <vector227>:
.globl vector227
vector227:
  pushl $0
80108416:	6a 00                	push   $0x0
  pushl $227
80108418:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010841d:	e9 4e f0 ff ff       	jmp    80107470 <alltraps>

80108422 <vector228>:
.globl vector228
vector228:
  pushl $0
80108422:	6a 00                	push   $0x0
  pushl $228
80108424:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108429:	e9 42 f0 ff ff       	jmp    80107470 <alltraps>

8010842e <vector229>:
.globl vector229
vector229:
  pushl $0
8010842e:	6a 00                	push   $0x0
  pushl $229
80108430:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108435:	e9 36 f0 ff ff       	jmp    80107470 <alltraps>

8010843a <vector230>:
.globl vector230
vector230:
  pushl $0
8010843a:	6a 00                	push   $0x0
  pushl $230
8010843c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108441:	e9 2a f0 ff ff       	jmp    80107470 <alltraps>

80108446 <vector231>:
.globl vector231
vector231:
  pushl $0
80108446:	6a 00                	push   $0x0
  pushl $231
80108448:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010844d:	e9 1e f0 ff ff       	jmp    80107470 <alltraps>

80108452 <vector232>:
.globl vector232
vector232:
  pushl $0
80108452:	6a 00                	push   $0x0
  pushl $232
80108454:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108459:	e9 12 f0 ff ff       	jmp    80107470 <alltraps>

8010845e <vector233>:
.globl vector233
vector233:
  pushl $0
8010845e:	6a 00                	push   $0x0
  pushl $233
80108460:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108465:	e9 06 f0 ff ff       	jmp    80107470 <alltraps>

8010846a <vector234>:
.globl vector234
vector234:
  pushl $0
8010846a:	6a 00                	push   $0x0
  pushl $234
8010846c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108471:	e9 fa ef ff ff       	jmp    80107470 <alltraps>

80108476 <vector235>:
.globl vector235
vector235:
  pushl $0
80108476:	6a 00                	push   $0x0
  pushl $235
80108478:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010847d:	e9 ee ef ff ff       	jmp    80107470 <alltraps>

80108482 <vector236>:
.globl vector236
vector236:
  pushl $0
80108482:	6a 00                	push   $0x0
  pushl $236
80108484:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108489:	e9 e2 ef ff ff       	jmp    80107470 <alltraps>

8010848e <vector237>:
.globl vector237
vector237:
  pushl $0
8010848e:	6a 00                	push   $0x0
  pushl $237
80108490:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108495:	e9 d6 ef ff ff       	jmp    80107470 <alltraps>

8010849a <vector238>:
.globl vector238
vector238:
  pushl $0
8010849a:	6a 00                	push   $0x0
  pushl $238
8010849c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801084a1:	e9 ca ef ff ff       	jmp    80107470 <alltraps>

801084a6 <vector239>:
.globl vector239
vector239:
  pushl $0
801084a6:	6a 00                	push   $0x0
  pushl $239
801084a8:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801084ad:	e9 be ef ff ff       	jmp    80107470 <alltraps>

801084b2 <vector240>:
.globl vector240
vector240:
  pushl $0
801084b2:	6a 00                	push   $0x0
  pushl $240
801084b4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801084b9:	e9 b2 ef ff ff       	jmp    80107470 <alltraps>

801084be <vector241>:
.globl vector241
vector241:
  pushl $0
801084be:	6a 00                	push   $0x0
  pushl $241
801084c0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801084c5:	e9 a6 ef ff ff       	jmp    80107470 <alltraps>

801084ca <vector242>:
.globl vector242
vector242:
  pushl $0
801084ca:	6a 00                	push   $0x0
  pushl $242
801084cc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801084d1:	e9 9a ef ff ff       	jmp    80107470 <alltraps>

801084d6 <vector243>:
.globl vector243
vector243:
  pushl $0
801084d6:	6a 00                	push   $0x0
  pushl $243
801084d8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801084dd:	e9 8e ef ff ff       	jmp    80107470 <alltraps>

801084e2 <vector244>:
.globl vector244
vector244:
  pushl $0
801084e2:	6a 00                	push   $0x0
  pushl $244
801084e4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801084e9:	e9 82 ef ff ff       	jmp    80107470 <alltraps>

801084ee <vector245>:
.globl vector245
vector245:
  pushl $0
801084ee:	6a 00                	push   $0x0
  pushl $245
801084f0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801084f5:	e9 76 ef ff ff       	jmp    80107470 <alltraps>

801084fa <vector246>:
.globl vector246
vector246:
  pushl $0
801084fa:	6a 00                	push   $0x0
  pushl $246
801084fc:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108501:	e9 6a ef ff ff       	jmp    80107470 <alltraps>

80108506 <vector247>:
.globl vector247
vector247:
  pushl $0
80108506:	6a 00                	push   $0x0
  pushl $247
80108508:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010850d:	e9 5e ef ff ff       	jmp    80107470 <alltraps>

80108512 <vector248>:
.globl vector248
vector248:
  pushl $0
80108512:	6a 00                	push   $0x0
  pushl $248
80108514:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108519:	e9 52 ef ff ff       	jmp    80107470 <alltraps>

8010851e <vector249>:
.globl vector249
vector249:
  pushl $0
8010851e:	6a 00                	push   $0x0
  pushl $249
80108520:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108525:	e9 46 ef ff ff       	jmp    80107470 <alltraps>

8010852a <vector250>:
.globl vector250
vector250:
  pushl $0
8010852a:	6a 00                	push   $0x0
  pushl $250
8010852c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108531:	e9 3a ef ff ff       	jmp    80107470 <alltraps>

80108536 <vector251>:
.globl vector251
vector251:
  pushl $0
80108536:	6a 00                	push   $0x0
  pushl $251
80108538:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010853d:	e9 2e ef ff ff       	jmp    80107470 <alltraps>

80108542 <vector252>:
.globl vector252
vector252:
  pushl $0
80108542:	6a 00                	push   $0x0
  pushl $252
80108544:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108549:	e9 22 ef ff ff       	jmp    80107470 <alltraps>

8010854e <vector253>:
.globl vector253
vector253:
  pushl $0
8010854e:	6a 00                	push   $0x0
  pushl $253
80108550:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108555:	e9 16 ef ff ff       	jmp    80107470 <alltraps>

8010855a <vector254>:
.globl vector254
vector254:
  pushl $0
8010855a:	6a 00                	push   $0x0
  pushl $254
8010855c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108561:	e9 0a ef ff ff       	jmp    80107470 <alltraps>

80108566 <vector255>:
.globl vector255
vector255:
  pushl $0
80108566:	6a 00                	push   $0x0
  pushl $255
80108568:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010856d:	e9 fe ee ff ff       	jmp    80107470 <alltraps>
	...

80108574 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108574:	55                   	push   %ebp
80108575:	89 e5                	mov    %esp,%ebp
80108577:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010857a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010857d:	83 e8 01             	sub    $0x1,%eax
80108580:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108584:	8b 45 08             	mov    0x8(%ebp),%eax
80108587:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010858b:	8b 45 08             	mov    0x8(%ebp),%eax
8010858e:	c1 e8 10             	shr    $0x10,%eax
80108591:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108595:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108598:	0f 01 10             	lgdtl  (%eax)
}
8010859b:	c9                   	leave  
8010859c:	c3                   	ret    

8010859d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010859d:	55                   	push   %ebp
8010859e:	89 e5                	mov    %esp,%ebp
801085a0:	83 ec 04             	sub    $0x4,%esp
801085a3:	8b 45 08             	mov    0x8(%ebp),%eax
801085a6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801085aa:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801085ae:	0f 00 d8             	ltr    %ax
}
801085b1:	c9                   	leave  
801085b2:	c3                   	ret    

801085b3 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801085b3:	55                   	push   %ebp
801085b4:	89 e5                	mov    %esp,%ebp
801085b6:	83 ec 04             	sub    $0x4,%esp
801085b9:	8b 45 08             	mov    0x8(%ebp),%eax
801085bc:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801085c0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801085c4:	8e e8                	mov    %eax,%gs
}
801085c6:	c9                   	leave  
801085c7:	c3                   	ret    

801085c8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801085c8:	55                   	push   %ebp
801085c9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801085cb:	8b 45 08             	mov    0x8(%ebp),%eax
801085ce:	0f 22 d8             	mov    %eax,%cr3
}
801085d1:	5d                   	pop    %ebp
801085d2:	c3                   	ret    

801085d3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801085d3:	55                   	push   %ebp
801085d4:	89 e5                	mov    %esp,%ebp
801085d6:	8b 45 08             	mov    0x8(%ebp),%eax
801085d9:	05 00 00 00 80       	add    $0x80000000,%eax
801085de:	5d                   	pop    %ebp
801085df:	c3                   	ret    

801085e0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801085e0:	55                   	push   %ebp
801085e1:	89 e5                	mov    %esp,%ebp
801085e3:	8b 45 08             	mov    0x8(%ebp),%eax
801085e6:	05 00 00 00 80       	add    $0x80000000,%eax
801085eb:	5d                   	pop    %ebp
801085ec:	c3                   	ret    

801085ed <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801085ed:	55                   	push   %ebp
801085ee:	89 e5                	mov    %esp,%ebp
801085f0:	53                   	push   %ebx
801085f1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801085f4:	e8 48 b9 ff ff       	call   80103f41 <cpunum>
801085f9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801085ff:	05 60 09 11 80       	add    $0x80110960,%eax
80108604:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108607:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860a:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108610:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108613:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108620:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108623:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108627:	83 e2 f0             	and    $0xfffffff0,%edx
8010862a:	83 ca 0a             	or     $0xa,%edx
8010862d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108633:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108637:	83 ca 10             	or     $0x10,%edx
8010863a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010863d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108640:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108644:	83 e2 9f             	and    $0xffffff9f,%edx
80108647:	88 50 7d             	mov    %dl,0x7d(%eax)
8010864a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010864d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108651:	83 ca 80             	or     $0xffffff80,%edx
80108654:	88 50 7d             	mov    %dl,0x7d(%eax)
80108657:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010865a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010865e:	83 ca 0f             	or     $0xf,%edx
80108661:	88 50 7e             	mov    %dl,0x7e(%eax)
80108664:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108667:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010866b:	83 e2 ef             	and    $0xffffffef,%edx
8010866e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108674:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108678:	83 e2 df             	and    $0xffffffdf,%edx
8010867b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010867e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108681:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108685:	83 ca 40             	or     $0x40,%edx
80108688:	88 50 7e             	mov    %dl,0x7e(%eax)
8010868b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010868e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108692:	83 ca 80             	or     $0xffffff80,%edx
80108695:	88 50 7e             	mov    %dl,0x7e(%eax)
80108698:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010869b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010869f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a2:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801086a9:	ff ff 
801086ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ae:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801086b5:	00 00 
801086b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ba:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801086c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086c4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801086cb:	83 e2 f0             	and    $0xfffffff0,%edx
801086ce:	83 ca 02             	or     $0x2,%edx
801086d1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801086d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086da:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801086e1:	83 ca 10             	or     $0x10,%edx
801086e4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801086ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ed:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801086f4:	83 e2 9f             	and    $0xffffff9f,%edx
801086f7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801086fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108700:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108707:	83 ca 80             	or     $0xffffff80,%edx
8010870a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108710:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108713:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010871a:	83 ca 0f             	or     $0xf,%edx
8010871d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108723:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108726:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010872d:	83 e2 ef             	and    $0xffffffef,%edx
80108730:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108739:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108740:	83 e2 df             	and    $0xffffffdf,%edx
80108743:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010874c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108753:	83 ca 40             	or     $0x40,%edx
80108756:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010875c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010875f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108766:	83 ca 80             	or     $0xffffff80,%edx
80108769:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010876f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108772:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010877c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108783:	ff ff 
80108785:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108788:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010878f:	00 00 
80108791:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108794:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010879b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801087a5:	83 e2 f0             	and    $0xfffffff0,%edx
801087a8:	83 ca 0a             	or     $0xa,%edx
801087ab:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801087b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801087bb:	83 ca 10             	or     $0x10,%edx
801087be:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801087c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087c7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801087ce:	83 ca 60             	or     $0x60,%edx
801087d1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801087d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087da:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801087e1:	83 ca 80             	or     $0xffffff80,%edx
801087e4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801087ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ed:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801087f4:	83 ca 0f             	or     $0xf,%edx
801087f7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801087fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108800:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108807:	83 e2 ef             	and    $0xffffffef,%edx
8010880a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108813:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010881a:	83 e2 df             	and    $0xffffffdf,%edx
8010881d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108823:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108826:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010882d:	83 ca 40             	or     $0x40,%edx
80108830:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108836:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108839:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108840:	83 ca 80             	or     $0xffffff80,%edx
80108843:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010884c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108856:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
8010885d:	ff ff 
8010885f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108862:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108869:	00 00 
8010886b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010886e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108875:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108878:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010887f:	83 e2 f0             	and    $0xfffffff0,%edx
80108882:	83 ca 02             	or     $0x2,%edx
80108885:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010888b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010888e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108895:	83 ca 10             	or     $0x10,%edx
80108898:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010889e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a1:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801088a8:	83 ca 60             	or     $0x60,%edx
801088ab:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801088b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088b4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801088bb:	83 ca 80             	or     $0xffffff80,%edx
801088be:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801088c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088ce:	83 ca 0f             	or     $0xf,%edx
801088d1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088da:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088e1:	83 e2 ef             	and    $0xffffffef,%edx
801088e4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ed:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801088f4:	83 e2 df             	and    $0xffffffdf,%edx
801088f7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801088fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108900:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108907:	83 ca 40             	or     $0x40,%edx
8010890a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108910:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108913:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010891a:	83 ca 80             	or     $0xffffff80,%edx
8010891d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108926:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
8010892d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108930:	05 b4 00 00 00       	add    $0xb4,%eax
80108935:	89 c3                	mov    %eax,%ebx
80108937:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010893a:	05 b4 00 00 00       	add    $0xb4,%eax
8010893f:	c1 e8 10             	shr    $0x10,%eax
80108942:	89 c1                	mov    %eax,%ecx
80108944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108947:	05 b4 00 00 00       	add    $0xb4,%eax
8010894c:	c1 e8 18             	shr    $0x18,%eax
8010894f:	89 c2                	mov    %eax,%edx
80108951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108954:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010895b:	00 00 
8010895d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108960:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108970:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108973:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010897a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010897d:	83 c9 02             	or     $0x2,%ecx
80108980:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108989:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108990:	83 c9 10             	or     $0x10,%ecx
80108993:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010899c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801089a3:	83 e1 9f             	and    $0xffffff9f,%ecx
801089a6:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801089ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089af:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801089b6:	83 c9 80             	or     $0xffffff80,%ecx
801089b9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801089bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089c2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801089c9:	83 e1 f0             	and    $0xfffffff0,%ecx
801089cc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801089dc:	83 e1 ef             	and    $0xffffffef,%ecx
801089df:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089e8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801089ef:	83 e1 df             	and    $0xffffffdf,%ecx
801089f2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801089f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108a02:	83 c9 40             	or     $0x40,%ecx
80108a05:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a0e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108a15:	83 c9 80             	or     $0xffffff80,%ecx
80108a18:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108a1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a21:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a2a:	83 c0 70             	add    $0x70,%eax
80108a2d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108a34:	00 
80108a35:	89 04 24             	mov    %eax,(%esp)
80108a38:	e8 37 fb ff ff       	call   80108574 <lgdt>
  loadgs(SEG_KCPU << 3);
80108a3d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108a44:	e8 6a fb ff ff       	call   801085b3 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a4c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108a52:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108a59:	00 00 00 00 
}
80108a5d:	83 c4 24             	add    $0x24,%esp
80108a60:	5b                   	pop    %ebx
80108a61:	5d                   	pop    %ebp
80108a62:	c3                   	ret    

80108a63 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108a63:	55                   	push   %ebp
80108a64:	89 e5                	mov    %esp,%ebp
80108a66:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108a69:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a6c:	c1 e8 16             	shr    $0x16,%eax
80108a6f:	c1 e0 02             	shl    $0x2,%eax
80108a72:	03 45 08             	add    0x8(%ebp),%eax
80108a75:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108a78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a7b:	8b 00                	mov    (%eax),%eax
80108a7d:	83 e0 01             	and    $0x1,%eax
80108a80:	84 c0                	test   %al,%al
80108a82:	74 17                	je     80108a9b <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108a84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a87:	8b 00                	mov    (%eax),%eax
80108a89:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a8e:	89 04 24             	mov    %eax,(%esp)
80108a91:	e8 4a fb ff ff       	call   801085e0 <p2v>
80108a96:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108a99:	eb 4b                	jmp    80108ae6 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108a9b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108a9f:	74 0e                	je     80108aaf <walkpgdir+0x4c>
80108aa1:	e8 0d b1 ff ff       	call   80103bb3 <kalloc>
80108aa6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108aa9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108aad:	75 07                	jne    80108ab6 <walkpgdir+0x53>
      return 0;
80108aaf:	b8 00 00 00 00       	mov    $0x0,%eax
80108ab4:	eb 41                	jmp    80108af7 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108ab6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108abd:	00 
80108abe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ac5:	00 
80108ac6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac9:	89 04 24             	mov    %eax,(%esp)
80108acc:	e8 d5 d3 ff ff       	call   80105ea6 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad4:	89 04 24             	mov    %eax,(%esp)
80108ad7:	e8 f7 fa ff ff       	call   801085d3 <v2p>
80108adc:	89 c2                	mov    %eax,%edx
80108ade:	83 ca 07             	or     $0x7,%edx
80108ae1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ae4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108ae6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ae9:	c1 e8 0c             	shr    $0xc,%eax
80108aec:	25 ff 03 00 00       	and    $0x3ff,%eax
80108af1:	c1 e0 02             	shl    $0x2,%eax
80108af4:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108af7:	c9                   	leave  
80108af8:	c3                   	ret    

80108af9 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108af9:	55                   	push   %ebp
80108afa:	89 e5                	mov    %esp,%ebp
80108afc:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108aff:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b02:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b07:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108b0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b0d:	03 45 10             	add    0x10(%ebp),%eax
80108b10:	83 e8 01             	sub    $0x1,%eax
80108b13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b18:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108b1b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108b22:	00 
80108b23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b26:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80108b2d:	89 04 24             	mov    %eax,(%esp)
80108b30:	e8 2e ff ff ff       	call   80108a63 <walkpgdir>
80108b35:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108b38:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108b3c:	75 07                	jne    80108b45 <mappages+0x4c>
      return -1;
80108b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108b43:	eb 46                	jmp    80108b8b <mappages+0x92>
    if(*pte & PTE_P)
80108b45:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b48:	8b 00                	mov    (%eax),%eax
80108b4a:	83 e0 01             	and    $0x1,%eax
80108b4d:	84 c0                	test   %al,%al
80108b4f:	74 0c                	je     80108b5d <mappages+0x64>
      panic("remap");
80108b51:	c7 04 24 90 9a 10 80 	movl   $0x80109a90,(%esp)
80108b58:	e8 e0 79 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108b5d:	8b 45 18             	mov    0x18(%ebp),%eax
80108b60:	0b 45 14             	or     0x14(%ebp),%eax
80108b63:	89 c2                	mov    %eax,%edx
80108b65:	83 ca 01             	or     $0x1,%edx
80108b68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108b6b:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b70:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108b73:	74 10                	je     80108b85 <mappages+0x8c>
      break;
    a += PGSIZE;
80108b75:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108b7c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108b83:	eb 96                	jmp    80108b1b <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108b85:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108b86:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108b8b:	c9                   	leave  
80108b8c:	c3                   	ret    

80108b8d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108b8d:	55                   	push   %ebp
80108b8e:	89 e5                	mov    %esp,%ebp
80108b90:	53                   	push   %ebx
80108b91:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108b94:	e8 1a b0 ff ff       	call   80103bb3 <kalloc>
80108b99:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108b9c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108ba0:	75 0a                	jne    80108bac <setupkvm+0x1f>
    return 0;
80108ba2:	b8 00 00 00 00       	mov    $0x0,%eax
80108ba7:	e9 98 00 00 00       	jmp    80108c44 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108bac:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108bb3:	00 
80108bb4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108bbb:	00 
80108bbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bbf:	89 04 24             	mov    %eax,(%esp)
80108bc2:	e8 df d2 ff ff       	call   80105ea6 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108bc7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108bce:	e8 0d fa ff ff       	call   801085e0 <p2v>
80108bd3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108bd8:	76 0c                	jbe    80108be6 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108bda:	c7 04 24 96 9a 10 80 	movl   $0x80109a96,(%esp)
80108be1:	e8 57 79 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108be6:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108bed:	eb 49                	jmp    80108c38 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108bef:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108bf2:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108bf8:	8b 50 04             	mov    0x4(%eax),%edx
80108bfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bfe:	8b 58 08             	mov    0x8(%eax),%ebx
80108c01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c04:	8b 40 04             	mov    0x4(%eax),%eax
80108c07:	29 c3                	sub    %eax,%ebx
80108c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0c:	8b 00                	mov    (%eax),%eax
80108c0e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108c12:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108c16:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108c1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c21:	89 04 24             	mov    %eax,(%esp)
80108c24:	e8 d0 fe ff ff       	call   80108af9 <mappages>
80108c29:	85 c0                	test   %eax,%eax
80108c2b:	79 07                	jns    80108c34 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108c2d:	b8 00 00 00 00       	mov    $0x0,%eax
80108c32:	eb 10                	jmp    80108c44 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108c34:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108c38:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108c3f:	72 ae                	jb     80108bef <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108c41:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108c44:	83 c4 34             	add    $0x34,%esp
80108c47:	5b                   	pop    %ebx
80108c48:	5d                   	pop    %ebp
80108c49:	c3                   	ret    

80108c4a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108c4a:	55                   	push   %ebp
80108c4b:	89 e5                	mov    %esp,%ebp
80108c4d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108c50:	e8 38 ff ff ff       	call   80108b8d <setupkvm>
80108c55:	a3 38 37 11 80       	mov    %eax,0x80113738
  switchkvm();
80108c5a:	e8 02 00 00 00       	call   80108c61 <switchkvm>
}
80108c5f:	c9                   	leave  
80108c60:	c3                   	ret    

80108c61 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108c61:	55                   	push   %ebp
80108c62:	89 e5                	mov    %esp,%ebp
80108c64:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108c67:	a1 38 37 11 80       	mov    0x80113738,%eax
80108c6c:	89 04 24             	mov    %eax,(%esp)
80108c6f:	e8 5f f9 ff ff       	call   801085d3 <v2p>
80108c74:	89 04 24             	mov    %eax,(%esp)
80108c77:	e8 4c f9 ff ff       	call   801085c8 <lcr3>
}
80108c7c:	c9                   	leave  
80108c7d:	c3                   	ret    

80108c7e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108c7e:	55                   	push   %ebp
80108c7f:	89 e5                	mov    %esp,%ebp
80108c81:	53                   	push   %ebx
80108c82:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108c85:	e8 15 d1 ff ff       	call   80105d9f <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108c8a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108c90:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108c97:	83 c2 08             	add    $0x8,%edx
80108c9a:	89 d3                	mov    %edx,%ebx
80108c9c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ca3:	83 c2 08             	add    $0x8,%edx
80108ca6:	c1 ea 10             	shr    $0x10,%edx
80108ca9:	89 d1                	mov    %edx,%ecx
80108cab:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108cb2:	83 c2 08             	add    $0x8,%edx
80108cb5:	c1 ea 18             	shr    $0x18,%edx
80108cb8:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108cbf:	67 00 
80108cc1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108cc8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108cce:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108cd5:	83 e1 f0             	and    $0xfffffff0,%ecx
80108cd8:	83 c9 09             	or     $0x9,%ecx
80108cdb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ce1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ce8:	83 c9 10             	or     $0x10,%ecx
80108ceb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108cf1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108cf8:	83 e1 9f             	and    $0xffffff9f,%ecx
80108cfb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108d01:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108d08:	83 c9 80             	or     $0xffffff80,%ecx
80108d0b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108d11:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d18:	83 e1 f0             	and    $0xfffffff0,%ecx
80108d1b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d21:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d28:	83 e1 ef             	and    $0xffffffef,%ecx
80108d2b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d31:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d38:	83 e1 df             	and    $0xffffffdf,%ecx
80108d3b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d41:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d48:	83 c9 40             	or     $0x40,%ecx
80108d4b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d51:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108d58:	83 e1 7f             	and    $0x7f,%ecx
80108d5b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108d61:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108d67:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d6d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108d74:	83 e2 ef             	and    $0xffffffef,%edx
80108d77:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108d7d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d83:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108d89:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108d8f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108d96:	8b 52 08             	mov    0x8(%edx),%edx
80108d99:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108d9f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108da2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108da9:	e8 ef f7 ff ff       	call   8010859d <ltr>
  if(p->pgdir == 0)
80108dae:	8b 45 08             	mov    0x8(%ebp),%eax
80108db1:	8b 40 04             	mov    0x4(%eax),%eax
80108db4:	85 c0                	test   %eax,%eax
80108db6:	75 0c                	jne    80108dc4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108db8:	c7 04 24 a7 9a 10 80 	movl   $0x80109aa7,(%esp)
80108dbf:	e8 79 77 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80108dc7:	8b 40 04             	mov    0x4(%eax),%eax
80108dca:	89 04 24             	mov    %eax,(%esp)
80108dcd:	e8 01 f8 ff ff       	call   801085d3 <v2p>
80108dd2:	89 04 24             	mov    %eax,(%esp)
80108dd5:	e8 ee f7 ff ff       	call   801085c8 <lcr3>
  popcli();
80108dda:	e8 08 d0 ff ff       	call   80105de7 <popcli>
}
80108ddf:	83 c4 14             	add    $0x14,%esp
80108de2:	5b                   	pop    %ebx
80108de3:	5d                   	pop    %ebp
80108de4:	c3                   	ret    

80108de5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108de5:	55                   	push   %ebp
80108de6:	89 e5                	mov    %esp,%ebp
80108de8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108deb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108df2:	76 0c                	jbe    80108e00 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108df4:	c7 04 24 bb 9a 10 80 	movl   $0x80109abb,(%esp)
80108dfb:	e8 3d 77 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108e00:	e8 ae ad ff ff       	call   80103bb3 <kalloc>
80108e05:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108e08:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e0f:	00 
80108e10:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108e17:	00 
80108e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e1b:	89 04 24             	mov    %eax,(%esp)
80108e1e:	e8 83 d0 ff ff       	call   80105ea6 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e26:	89 04 24             	mov    %eax,(%esp)
80108e29:	e8 a5 f7 ff ff       	call   801085d3 <v2p>
80108e2e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108e35:	00 
80108e36:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e3a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e41:	00 
80108e42:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108e49:	00 
80108e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80108e4d:	89 04 24             	mov    %eax,(%esp)
80108e50:	e8 a4 fc ff ff       	call   80108af9 <mappages>
  memmove(mem, init, sz);
80108e55:	8b 45 10             	mov    0x10(%ebp),%eax
80108e58:	89 44 24 08          	mov    %eax,0x8(%esp)
80108e5c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e66:	89 04 24             	mov    %eax,(%esp)
80108e69:	e8 0b d1 ff ff       	call   80105f79 <memmove>
}
80108e6e:	c9                   	leave  
80108e6f:	c3                   	ret    

80108e70 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108e70:	55                   	push   %ebp
80108e71:	89 e5                	mov    %esp,%ebp
80108e73:	53                   	push   %ebx
80108e74:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108e77:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e7a:	25 ff 0f 00 00       	and    $0xfff,%eax
80108e7f:	85 c0                	test   %eax,%eax
80108e81:	74 0c                	je     80108e8f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108e83:	c7 04 24 d8 9a 10 80 	movl   $0x80109ad8,(%esp)
80108e8a:	e8 ae 76 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108e8f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108e96:	e9 ad 00 00 00       	jmp    80108f48 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e9e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108ea1:	01 d0                	add    %edx,%eax
80108ea3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108eaa:	00 
80108eab:	89 44 24 04          	mov    %eax,0x4(%esp)
80108eaf:	8b 45 08             	mov    0x8(%ebp),%eax
80108eb2:	89 04 24             	mov    %eax,(%esp)
80108eb5:	e8 a9 fb ff ff       	call   80108a63 <walkpgdir>
80108eba:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108ebd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ec1:	75 0c                	jne    80108ecf <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108ec3:	c7 04 24 fb 9a 10 80 	movl   $0x80109afb,(%esp)
80108eca:	e8 6e 76 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108ecf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ed2:	8b 00                	mov    (%eax),%eax
80108ed4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ed9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108edc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108edf:	8b 55 18             	mov    0x18(%ebp),%edx
80108ee2:	89 d1                	mov    %edx,%ecx
80108ee4:	29 c1                	sub    %eax,%ecx
80108ee6:	89 c8                	mov    %ecx,%eax
80108ee8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108eed:	77 11                	ja     80108f00 <loaduvm+0x90>
      n = sz - i;
80108eef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ef2:	8b 55 18             	mov    0x18(%ebp),%edx
80108ef5:	89 d1                	mov    %edx,%ecx
80108ef7:	29 c1                	sub    %eax,%ecx
80108ef9:	89 c8                	mov    %ecx,%eax
80108efb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108efe:	eb 07                	jmp    80108f07 <loaduvm+0x97>
    else
      n = PGSIZE;
80108f00:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108f07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f0a:	8b 55 14             	mov    0x14(%ebp),%edx
80108f0d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108f10:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108f13:	89 04 24             	mov    %eax,(%esp)
80108f16:	e8 c5 f6 ff ff       	call   801085e0 <p2v>
80108f1b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108f1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108f22:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108f26:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f2a:	8b 45 10             	mov    0x10(%ebp),%eax
80108f2d:	89 04 24             	mov    %eax,(%esp)
80108f30:	e8 c9 9b ff ff       	call   80102afe <readi>
80108f35:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108f38:	74 07                	je     80108f41 <loaduvm+0xd1>
      return -1;
80108f3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108f3f:	eb 18                	jmp    80108f59 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108f41:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f4b:	3b 45 18             	cmp    0x18(%ebp),%eax
80108f4e:	0f 82 47 ff ff ff    	jb     80108e9b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108f54:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108f59:	83 c4 24             	add    $0x24,%esp
80108f5c:	5b                   	pop    %ebx
80108f5d:	5d                   	pop    %ebp
80108f5e:	c3                   	ret    

80108f5f <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108f5f:	55                   	push   %ebp
80108f60:	89 e5                	mov    %esp,%ebp
80108f62:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108f65:	8b 45 10             	mov    0x10(%ebp),%eax
80108f68:	85 c0                	test   %eax,%eax
80108f6a:	79 0a                	jns    80108f76 <allocuvm+0x17>
    return 0;
80108f6c:	b8 00 00 00 00       	mov    $0x0,%eax
80108f71:	e9 c1 00 00 00       	jmp    80109037 <allocuvm+0xd8>
  if(newsz < oldsz)
80108f76:	8b 45 10             	mov    0x10(%ebp),%eax
80108f79:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108f7c:	73 08                	jae    80108f86 <allocuvm+0x27>
    return oldsz;
80108f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f81:	e9 b1 00 00 00       	jmp    80109037 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108f86:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f89:	05 ff 0f 00 00       	add    $0xfff,%eax
80108f8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f93:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108f96:	e9 8d 00 00 00       	jmp    80109028 <allocuvm+0xc9>
    mem = kalloc();
80108f9b:	e8 13 ac ff ff       	call   80103bb3 <kalloc>
80108fa0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108fa3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108fa7:	75 2c                	jne    80108fd5 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108fa9:	c7 04 24 19 9b 10 80 	movl   $0x80109b19,(%esp)
80108fb0:	e8 ec 73 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108fb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80108fb8:	89 44 24 08          	mov    %eax,0x8(%esp)
80108fbc:	8b 45 10             	mov    0x10(%ebp),%eax
80108fbf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fc3:	8b 45 08             	mov    0x8(%ebp),%eax
80108fc6:	89 04 24             	mov    %eax,(%esp)
80108fc9:	e8 6b 00 00 00       	call   80109039 <deallocuvm>
      return 0;
80108fce:	b8 00 00 00 00       	mov    $0x0,%eax
80108fd3:	eb 62                	jmp    80109037 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108fd5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fdc:	00 
80108fdd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108fe4:	00 
80108fe5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108fe8:	89 04 24             	mov    %eax,(%esp)
80108feb:	e8 b6 ce ff ff       	call   80105ea6 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108ff0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ff3:	89 04 24             	mov    %eax,(%esp)
80108ff6:	e8 d8 f5 ff ff       	call   801085d3 <v2p>
80108ffb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108ffe:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109005:	00 
80109006:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010900a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109011:	00 
80109012:	89 54 24 04          	mov    %edx,0x4(%esp)
80109016:	8b 45 08             	mov    0x8(%ebp),%eax
80109019:	89 04 24             	mov    %eax,(%esp)
8010901c:	e8 d8 fa ff ff       	call   80108af9 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109021:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109028:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010902b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010902e:	0f 82 67 ff ff ff    	jb     80108f9b <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109034:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109037:	c9                   	leave  
80109038:	c3                   	ret    

80109039 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109039:	55                   	push   %ebp
8010903a:	89 e5                	mov    %esp,%ebp
8010903c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010903f:	8b 45 10             	mov    0x10(%ebp),%eax
80109042:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109045:	72 08                	jb     8010904f <deallocuvm+0x16>
    return oldsz;
80109047:	8b 45 0c             	mov    0xc(%ebp),%eax
8010904a:	e9 a4 00 00 00       	jmp    801090f3 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010904f:	8b 45 10             	mov    0x10(%ebp),%eax
80109052:	05 ff 0f 00 00       	add    $0xfff,%eax
80109057:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010905c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010905f:	e9 80 00 00 00       	jmp    801090e4 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109064:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109067:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010906e:	00 
8010906f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109073:	8b 45 08             	mov    0x8(%ebp),%eax
80109076:	89 04 24             	mov    %eax,(%esp)
80109079:	e8 e5 f9 ff ff       	call   80108a63 <walkpgdir>
8010907e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109081:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109085:	75 09                	jne    80109090 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109087:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010908e:	eb 4d                	jmp    801090dd <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80109090:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109093:	8b 00                	mov    (%eax),%eax
80109095:	83 e0 01             	and    $0x1,%eax
80109098:	84 c0                	test   %al,%al
8010909a:	74 41                	je     801090dd <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
8010909c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010909f:	8b 00                	mov    (%eax),%eax
801090a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801090a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801090a9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801090ad:	75 0c                	jne    801090bb <deallocuvm+0x82>
        panic("kfree");
801090af:	c7 04 24 31 9b 10 80 	movl   $0x80109b31,(%esp)
801090b6:	e8 82 74 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
801090bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801090be:	89 04 24             	mov    %eax,(%esp)
801090c1:	e8 1a f5 ff ff       	call   801085e0 <p2v>
801090c6:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801090c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801090cc:	89 04 24             	mov    %eax,(%esp)
801090cf:	e8 46 aa ff ff       	call   80103b1a <kfree>
      *pte = 0;
801090d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090d7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801090dd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090e7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090ea:	0f 82 74 ff ff ff    	jb     80109064 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801090f0:	8b 45 10             	mov    0x10(%ebp),%eax
}
801090f3:	c9                   	leave  
801090f4:	c3                   	ret    

801090f5 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801090f5:	55                   	push   %ebp
801090f6:	89 e5                	mov    %esp,%ebp
801090f8:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801090fb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801090ff:	75 0c                	jne    8010910d <freevm+0x18>
    panic("freevm: no pgdir");
80109101:	c7 04 24 37 9b 10 80 	movl   $0x80109b37,(%esp)
80109108:	e8 30 74 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010910d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109114:	00 
80109115:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010911c:	80 
8010911d:	8b 45 08             	mov    0x8(%ebp),%eax
80109120:	89 04 24             	mov    %eax,(%esp)
80109123:	e8 11 ff ff ff       	call   80109039 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109128:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010912f:	eb 3c                	jmp    8010916d <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109131:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109134:	c1 e0 02             	shl    $0x2,%eax
80109137:	03 45 08             	add    0x8(%ebp),%eax
8010913a:	8b 00                	mov    (%eax),%eax
8010913c:	83 e0 01             	and    $0x1,%eax
8010913f:	84 c0                	test   %al,%al
80109141:	74 26                	je     80109169 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109146:	c1 e0 02             	shl    $0x2,%eax
80109149:	03 45 08             	add    0x8(%ebp),%eax
8010914c:	8b 00                	mov    (%eax),%eax
8010914e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109153:	89 04 24             	mov    %eax,(%esp)
80109156:	e8 85 f4 ff ff       	call   801085e0 <p2v>
8010915b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010915e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109161:	89 04 24             	mov    %eax,(%esp)
80109164:	e8 b1 a9 ff ff       	call   80103b1a <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109169:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010916d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109174:	76 bb                	jbe    80109131 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109176:	8b 45 08             	mov    0x8(%ebp),%eax
80109179:	89 04 24             	mov    %eax,(%esp)
8010917c:	e8 99 a9 ff ff       	call   80103b1a <kfree>
}
80109181:	c9                   	leave  
80109182:	c3                   	ret    

80109183 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109183:	55                   	push   %ebp
80109184:	89 e5                	mov    %esp,%ebp
80109186:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109189:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109190:	00 
80109191:	8b 45 0c             	mov    0xc(%ebp),%eax
80109194:	89 44 24 04          	mov    %eax,0x4(%esp)
80109198:	8b 45 08             	mov    0x8(%ebp),%eax
8010919b:	89 04 24             	mov    %eax,(%esp)
8010919e:	e8 c0 f8 ff ff       	call   80108a63 <walkpgdir>
801091a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801091a6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801091aa:	75 0c                	jne    801091b8 <clearpteu+0x35>
    panic("clearpteu");
801091ac:	c7 04 24 48 9b 10 80 	movl   $0x80109b48,(%esp)
801091b3:	e8 85 73 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
801091b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091bb:	8b 00                	mov    (%eax),%eax
801091bd:	89 c2                	mov    %eax,%edx
801091bf:	83 e2 fb             	and    $0xfffffffb,%edx
801091c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091c5:	89 10                	mov    %edx,(%eax)
}
801091c7:	c9                   	leave  
801091c8:	c3                   	ret    

801091c9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801091c9:	55                   	push   %ebp
801091ca:	89 e5                	mov    %esp,%ebp
801091cc:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801091cf:	e8 b9 f9 ff ff       	call   80108b8d <setupkvm>
801091d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801091d7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801091db:	75 0a                	jne    801091e7 <copyuvm+0x1e>
    return 0;
801091dd:	b8 00 00 00 00       	mov    $0x0,%eax
801091e2:	e9 f1 00 00 00       	jmp    801092d8 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801091e7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801091ee:	e9 c0 00 00 00       	jmp    801092b3 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801091f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091f6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091fd:	00 
801091fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80109202:	8b 45 08             	mov    0x8(%ebp),%eax
80109205:	89 04 24             	mov    %eax,(%esp)
80109208:	e8 56 f8 ff ff       	call   80108a63 <walkpgdir>
8010920d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109210:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109214:	75 0c                	jne    80109222 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80109216:	c7 04 24 52 9b 10 80 	movl   $0x80109b52,(%esp)
8010921d:	e8 1b 73 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109222:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109225:	8b 00                	mov    (%eax),%eax
80109227:	83 e0 01             	and    $0x1,%eax
8010922a:	85 c0                	test   %eax,%eax
8010922c:	75 0c                	jne    8010923a <copyuvm+0x71>
      panic("copyuvm: page not present");
8010922e:	c7 04 24 6c 9b 10 80 	movl   $0x80109b6c,(%esp)
80109235:	e8 03 73 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010923a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010923d:	8b 00                	mov    (%eax),%eax
8010923f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109244:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109247:	e8 67 a9 ff ff       	call   80103bb3 <kalloc>
8010924c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010924f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109253:	74 6f                	je     801092c4 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109255:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109258:	89 04 24             	mov    %eax,(%esp)
8010925b:	e8 80 f3 ff ff       	call   801085e0 <p2v>
80109260:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109267:	00 
80109268:	89 44 24 04          	mov    %eax,0x4(%esp)
8010926c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010926f:	89 04 24             	mov    %eax,(%esp)
80109272:	e8 02 cd ff ff       	call   80105f79 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109277:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010927a:	89 04 24             	mov    %eax,(%esp)
8010927d:	e8 51 f3 ff ff       	call   801085d3 <v2p>
80109282:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109285:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010928c:	00 
8010928d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109291:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109298:	00 
80109299:	89 54 24 04          	mov    %edx,0x4(%esp)
8010929d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092a0:	89 04 24             	mov    %eax,(%esp)
801092a3:	e8 51 f8 ff ff       	call   80108af9 <mappages>
801092a8:	85 c0                	test   %eax,%eax
801092aa:	78 1b                	js     801092c7 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801092ac:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801092b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092b6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801092b9:	0f 82 34 ff ff ff    	jb     801091f3 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801092bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092c2:	eb 14                	jmp    801092d8 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801092c4:	90                   	nop
801092c5:	eb 01                	jmp    801092c8 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801092c7:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801092c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092cb:	89 04 24             	mov    %eax,(%esp)
801092ce:	e8 22 fe ff ff       	call   801090f5 <freevm>
  return 0;
801092d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801092d8:	c9                   	leave  
801092d9:	c3                   	ret    

801092da <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801092da:	55                   	push   %ebp
801092db:	89 e5                	mov    %esp,%ebp
801092dd:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801092e0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092e7:	00 
801092e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801092eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801092ef:	8b 45 08             	mov    0x8(%ebp),%eax
801092f2:	89 04 24             	mov    %eax,(%esp)
801092f5:	e8 69 f7 ff ff       	call   80108a63 <walkpgdir>
801092fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801092fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109300:	8b 00                	mov    (%eax),%eax
80109302:	83 e0 01             	and    $0x1,%eax
80109305:	85 c0                	test   %eax,%eax
80109307:	75 07                	jne    80109310 <uva2ka+0x36>
    return 0;
80109309:	b8 00 00 00 00       	mov    $0x0,%eax
8010930e:	eb 25                	jmp    80109335 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109313:	8b 00                	mov    (%eax),%eax
80109315:	83 e0 04             	and    $0x4,%eax
80109318:	85 c0                	test   %eax,%eax
8010931a:	75 07                	jne    80109323 <uva2ka+0x49>
    return 0;
8010931c:	b8 00 00 00 00       	mov    $0x0,%eax
80109321:	eb 12                	jmp    80109335 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109326:	8b 00                	mov    (%eax),%eax
80109328:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010932d:	89 04 24             	mov    %eax,(%esp)
80109330:	e8 ab f2 ff ff       	call   801085e0 <p2v>
}
80109335:	c9                   	leave  
80109336:	c3                   	ret    

80109337 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109337:	55                   	push   %ebp
80109338:	89 e5                	mov    %esp,%ebp
8010933a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010933d:	8b 45 10             	mov    0x10(%ebp),%eax
80109340:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109343:	e9 8b 00 00 00       	jmp    801093d3 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109348:	8b 45 0c             	mov    0xc(%ebp),%eax
8010934b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109350:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109353:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109356:	89 44 24 04          	mov    %eax,0x4(%esp)
8010935a:	8b 45 08             	mov    0x8(%ebp),%eax
8010935d:	89 04 24             	mov    %eax,(%esp)
80109360:	e8 75 ff ff ff       	call   801092da <uva2ka>
80109365:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109368:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010936c:	75 07                	jne    80109375 <copyout+0x3e>
      return -1;
8010936e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109373:	eb 6d                	jmp    801093e2 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109375:	8b 45 0c             	mov    0xc(%ebp),%eax
80109378:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010937b:	89 d1                	mov    %edx,%ecx
8010937d:	29 c1                	sub    %eax,%ecx
8010937f:	89 c8                	mov    %ecx,%eax
80109381:	05 00 10 00 00       	add    $0x1000,%eax
80109386:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109389:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010938c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010938f:	76 06                	jbe    80109397 <copyout+0x60>
      n = len;
80109391:	8b 45 14             	mov    0x14(%ebp),%eax
80109394:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109397:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010939a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010939d:	89 d1                	mov    %edx,%ecx
8010939f:	29 c1                	sub    %eax,%ecx
801093a1:	89 c8                	mov    %ecx,%eax
801093a3:	03 45 e8             	add    -0x18(%ebp),%eax
801093a6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801093a9:	89 54 24 08          	mov    %edx,0x8(%esp)
801093ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801093b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801093b4:	89 04 24             	mov    %eax,(%esp)
801093b7:	e8 bd cb ff ff       	call   80105f79 <memmove>
    len -= n;
801093bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093bf:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801093c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093c5:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801093c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801093cb:	05 00 10 00 00       	add    $0x1000,%eax
801093d0:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801093d3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801093d7:	0f 85 6b ff ff ff    	jne    80109348 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801093dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801093e2:	c9                   	leave  
801093e3:	c3                   	ret    

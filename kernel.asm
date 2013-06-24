
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
8010002d:	b8 6b 46 10 80       	mov    $0x8010466b,%eax
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
8010003a:	c7 44 24 04 c4 95 10 	movl   $0x801095c4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 98 5d 00 00       	call   80105de6 <initlock>

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
801000bd:	e8 45 5d 00 00       	call   80105e07 <acquire>

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
80100104:	e8 60 5d 00 00       	call   80105e69 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 05 5a 00 00       	call   80105b29 <sleep>
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
8010017c:	e8 e8 5c 00 00       	call   80105e69 <release>
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
80100198:	c7 04 24 cb 95 10 80 	movl   $0x801095cb,(%esp)
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
801001d3:	e8 40 38 00 00       	call   80103a18 <iderw>
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
801001ef:	c7 04 24 dc 95 10 80 	movl   $0x801095dc,(%esp)
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
80100210:	e8 03 38 00 00       	call   80103a18 <iderw>
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
80100229:	c7 04 24 e3 95 10 80 	movl   $0x801095e3,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 c6 5b 00 00       	call   80105e07 <acquire>

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
8010029d:	e8 60 59 00 00       	call   80105c02 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 bb 5b 00 00       	call   80105e69 <release>
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
801003bc:	e8 46 5a 00 00       	call   80105e07 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 ea 95 10 80 	movl   $0x801095ea,(%esp)
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
801004af:	c7 45 ec f3 95 10 80 	movl   $0x801095f3,-0x14(%ebp)
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
80100536:	e8 2e 59 00 00       	call   80105e69 <release>
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
80100562:	c7 04 24 fa 95 10 80 	movl   $0x801095fa,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 09 96 10 80 	movl   $0x80109609,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 21 59 00 00       	call   80105eb8 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 0b 96 10 80 	movl   $0x8010960b,(%esp)
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
801006b2:	e8 72 5a 00 00       	call   80106129 <memmove>
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
801006e1:	e8 70 59 00 00       	call   80106056 <memset>
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
80100776:	e8 ae 74 00 00       	call   80107c29 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 a2 74 00 00       	call   80107c29 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 96 74 00 00       	call   80107c29 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 89 74 00 00       	call   80107c29 <uartputc>
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
801007ba:	e8 48 56 00 00       	call   80105e07 <acquire>
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
801007ea:	e8 b6 54 00 00       	call   80105ca5 <procdump>
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
801008f7:	e8 06 53 00 00       	call   80105c02 <wakeup>
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
8010091e:	e8 46 55 00 00       	call   80105e69 <release>
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
80100931:	e8 88 1e 00 00       	call   801027be <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 bf 54 00 00       	call   80105e07 <acquire>
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
80100961:	e8 03 55 00 00       	call   80105e69 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 ff 1c 00 00       	call   80102670 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 9a 51 00 00       	call   80105b29 <sleep>
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
80100a08:	e8 5c 54 00 00       	call   80105e69 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 58 1c 00 00       	call   80102670 <ilock>

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
80100a32:	e8 87 1d 00 00       	call   801027be <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 c4 53 00 00       	call   80105e07 <acquire>
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
80100a78:	e8 ec 53 00 00       	call   80105e69 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 e8 1b 00 00       	call   80102670 <ilock>

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
80100a93:	c7 44 24 04 0f 96 10 	movl   $0x8010960f,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 3f 53 00 00       	call   80105de6 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 17 96 10 	movl   $0x80109617,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 2b 53 00 00       	call   80105de6 <initlock>

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
80100ae0:	e8 40 42 00 00       	call   80104d25 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 e1 30 00 00       	call   80103bda <ioapicenable>
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
80100b0b:	e8 11 28 00 00       	call   80103321 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 42 1b 00 00       	call   80102670 <ilock>
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
80100b55:	e8 7c 20 00 00       	call   80102bd6 <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 63 3d 10 80 	movl   $0x80103d63,(%esp)
80100b7b:	e8 ed 81 00 00       	call   80108d6d <setupkvm>
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
80100bc8:	e8 09 20 00 00       	call   80102bd6 <readi>
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
80100c14:	e8 26 85 00 00       	call   8010913f <allocuvm>
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
80100c51:	e8 fa 83 00 00       	call   80109050 <loaduvm>
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
80100c87:	e8 68 1c 00 00       	call   801028f4 <iunlockput>
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
80100cbc:	e8 7e 84 00 00       	call   8010913f <allocuvm>
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
80100ce0:	e8 7e 86 00 00       	call   80109363 <clearpteu>
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
80100d0f:	e8 c0 55 00 00       	call   801062d4 <strlen>
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
80100d2d:	e8 a2 55 00 00       	call   801062d4 <strlen>
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
80100d57:	e8 bb 87 00 00       	call   80109517 <copyout>
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
80100df7:	e8 1b 87 00 00       	call   80109517 <copyout>
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
80100e4e:	e8 33 54 00 00       	call   80106286 <safestrcpy>

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
80100ea0:	e8 b9 7f 00 00       	call   80108e5e <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 25 84 00 00       	call   801092d5 <freevm>
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
80100ee2:	e8 ee 83 00 00       	call   801092d5 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 fc 19 00 00       	call   801028f4 <iunlockput>
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
80100f06:	c7 44 24 04 20 96 10 	movl   $0x80109620,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f15:	e8 cc 4e 00 00       	call   80105de6 <initlock>
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
80100f29:	e8 d9 4e 00 00       	call   80105e07 <acquire>
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
80100f52:	e8 12 4f 00 00       	call   80105e69 <release>
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
80100f70:	e8 f4 4e 00 00       	call   80105e69 <release>
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
80100f89:	e8 79 4e 00 00       	call   80105e07 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 27 96 10 80 	movl   $0x80109627,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fba:	e8 aa 4e 00 00       	call   80105e69 <release>
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
80100fd1:	e8 31 4e 00 00       	call   80105e07 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 2f 96 10 80 	movl   $0x8010962f,(%esp)
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
8010100c:	e8 58 4e 00 00       	call   80105e69 <release>
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
80101056:	e8 0e 4e 00 00       	call   80105e69 <release>
  
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
80101074:	e8 66 3f 00 00       	call   80104fdf <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 f9 33 00 00       	call   80104481 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 90 17 00 00       	call   80102823 <iput>
    commit_trans();
80101093:	e8 32 34 00 00       	call   801044ca <commit_trans>
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
801010b3:	e8 b8 15 00 00       	call   80102670 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 c4 1a 00 00       	call   80102b91 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 e3 16 00 00       	call   801027be <iunlock>
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
80101125:	e8 37 40 00 00       	call   80105161 <piperead>
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
8010113f:	e8 2c 15 00 00       	call   80102670 <ilock>
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
80101165:	e8 6c 1a 00 00       	call   80102bd6 <readi>
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
8010118d:	e8 2c 16 00 00       	call   801027be <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 39 96 10 80 	movl   $0x80109639,(%esp)
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
801011e2:	e8 8a 3e 00 00       	call   80105071 <pipewrite>
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
8010122a:	e8 52 32 00 00       	call   80104481 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 33 14 00 00       	call   80102670 <ilock>
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
80101263:	e8 d9 1a 00 00       	call   80102d41 <writei>
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
8010128b:	e8 2e 15 00 00       	call   801027be <iunlock>
      commit_trans();
80101290:	e8 35 32 00 00       	call   801044ca <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 42 96 10 80 	movl   $0x80109642,(%esp)
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
801012d8:	c7 04 24 52 96 10 80 	movl   $0x80109652,(%esp)
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
801012fe:	e8 82 5a 00 00       	call   80106d85 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 5c 96 10 80 	movl   $0x8010965c,(%esp)
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
80101338:	e8 33 13 00 00       	call   80102670 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 74 96 10 80 	movl   $0x80109674,(%esp)
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
80101382:	c7 04 24 97 96 10 80 	movl   $0x80109697,(%esp)
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
801013b7:	c7 04 24 b0 96 10 80 	movl   $0x801096b0,(%esp)
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
80101414:	c7 04 24 cf 96 10 80 	movl   $0x801096cf,(%esp)
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
8010143b:	e8 7e 13 00 00       	call   801027be <iunlock>
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
8010146a:	e8 85 0c 00 00       	call   801020f4 <readsb>
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
  return count;
80101537:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010153a:	83 c4 44             	add    $0x44,%esp
8010153d:	5b                   	pop    %ebx
8010153e:	5d                   	pop    %ebp
8010153f:	c3                   	ret    

80101540 <blkcmp>:

int
blkcmp(struct buf* b1, struct buf* b2)
{
80101540:	55                   	push   %ebp
80101541:	89 e5                	mov    %esp,%ebp
80101543:	83 ec 10             	sub    $0x10,%esp
  int i;
  for(i = 0; i<BSIZE; i++)
80101546:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010154d:	eb 29                	jmp    80101578 <blkcmp+0x38>
  {
    if(b1->data[i] != b2->data[i])
8010154f:	8b 45 08             	mov    0x8(%ebp),%eax
80101552:	03 45 fc             	add    -0x4(%ebp),%eax
80101555:	83 c0 10             	add    $0x10,%eax
80101558:	0f b6 50 08          	movzbl 0x8(%eax),%edx
8010155c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010155f:	03 45 fc             	add    -0x4(%ebp),%eax
80101562:	83 c0 10             	add    $0x10,%eax
80101565:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101569:	38 c2                	cmp    %al,%dl
8010156b:	74 07                	je     80101574 <blkcmp+0x34>
      return 0;
8010156d:	b8 00 00 00 00       	mov    $0x0,%eax
80101572:	eb 12                	jmp    80101586 <blkcmp+0x46>

int
blkcmp(struct buf* b1, struct buf* b2)
{
  int i;
  for(i = 0; i<BSIZE; i++)
80101574:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80101578:	81 7d fc ff 01 00 00 	cmpl   $0x1ff,-0x4(%ebp)
8010157f:	7e ce                	jle    8010154f <blkcmp+0xf>
  {
    if(b1->data[i] != b2->data[i])
      return 0;
  }
  return 1;  
80101581:	b8 01 00 00 00       	mov    $0x1,%eax
}
80101586:	c9                   	leave  
80101587:	c3                   	ret    

80101588 <deletedups>:

void
deletedups(struct inode* ip1,struct inode* ip2,struct buf *b1,struct buf *b2,int b1Index,int b2Index,uint* a, uint* b)
{
80101588:	55                   	push   %ebp
80101589:	89 e5                	mov    %esp,%ebp
8010158b:	83 ec 28             	sub    $0x28,%esp
  if(!a)
8010158e:	83 7d 20 00          	cmpl   $0x0,0x20(%ebp)
80101592:	75 46                	jne    801015da <deletedups+0x52>
  {
    if(!b)
80101594:	83 7d 24 00          	cmpl   $0x0,0x24(%ebp)
80101598:	75 1c                	jne    801015b6 <deletedups+0x2e>
      ip1->addrs[b1Index] = ip2->addrs[b2Index];
8010159a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010159d:	8b 55 1c             	mov    0x1c(%ebp),%edx
801015a0:	83 c2 04             	add    $0x4,%edx
801015a3:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801015a7:	8b 45 08             	mov    0x8(%ebp),%eax
801015aa:	8b 4d 18             	mov    0x18(%ebp),%ecx
801015ad:	83 c1 04             	add    $0x4,%ecx
801015b0:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
801015b4:	eb 18                	jmp    801015ce <deletedups+0x46>
    else
      ip1->addrs[b1Index] = b[b2Index];
801015b6:	8b 45 1c             	mov    0x1c(%ebp),%eax
801015b9:	c1 e0 02             	shl    $0x2,%eax
801015bc:	03 45 24             	add    0x24(%ebp),%eax
801015bf:	8b 10                	mov    (%eax),%edx
801015c1:	8b 45 08             	mov    0x8(%ebp),%eax
801015c4:	8b 4d 18             	mov    0x18(%ebp),%ecx
801015c7:	83 c1 04             	add    $0x4,%ecx
801015ca:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    directChanged = 1;
801015ce:	c7 05 80 ee 10 80 01 	movl   $0x1,0x8010ee80
801015d5:	00 00 00 
801015d8:	eb 40                	jmp    8010161a <deletedups+0x92>
  }
  else
  {
    if(!b)
801015da:	83 7d 24 00          	cmpl   $0x0,0x24(%ebp)
801015de:	75 1a                	jne    801015fa <deletedups+0x72>
      a[b1Index] = ip2->addrs[b2Index];
801015e0:	8b 45 18             	mov    0x18(%ebp),%eax
801015e3:	c1 e0 02             	shl    $0x2,%eax
801015e6:	03 45 20             	add    0x20(%ebp),%eax
801015e9:	8b 55 0c             	mov    0xc(%ebp),%edx
801015ec:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
801015ef:	83 c1 04             	add    $0x4,%ecx
801015f2:	8b 54 8a 0c          	mov    0xc(%edx,%ecx,4),%edx
801015f6:	89 10                	mov    %edx,(%eax)
801015f8:	eb 16                	jmp    80101610 <deletedups+0x88>
    else
      a[b1Index] = b[b2Index];
801015fa:	8b 45 18             	mov    0x18(%ebp),%eax
801015fd:	c1 e0 02             	shl    $0x2,%eax
80101600:	03 45 20             	add    0x20(%ebp),%eax
80101603:	8b 55 1c             	mov    0x1c(%ebp),%edx
80101606:	c1 e2 02             	shl    $0x2,%edx
80101609:	03 55 24             	add    0x24(%ebp),%edx
8010160c:	8b 12                	mov    (%edx),%edx
8010160e:	89 10                	mov    %edx,(%eax)
    indirectChanged = 1;
80101610:	c7 05 90 f8 10 80 01 	movl   $0x1,0x8010f890
80101617:	00 00 00 
  }
  updateBlkRef(b2->sector,1);
8010161a:	8b 45 14             	mov    0x14(%ebp),%eax
8010161d:	8b 40 08             	mov    0x8(%eax),%eax
80101620:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101627:	00 
80101628:	89 04 24             	mov    %eax,(%esp)
8010162b:	e8 9a 1e 00 00       	call   801034ca <updateBlkRef>
  int ref = getBlkRef(b1->sector);
80101630:	8b 45 10             	mov    0x10(%ebp),%eax
80101633:	8b 40 08             	mov    0x8(%eax),%eax
80101636:	89 04 24             	mov    %eax,(%esp)
80101639:	e8 ce 1f 00 00       	call   8010360c <getBlkRef>
8010163e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(ref > 0)
80101641:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101645:	7e 18                	jle    8010165f <deletedups+0xd7>
    updateBlkRef(b1->sector,-1);
80101647:	8b 45 10             	mov    0x10(%ebp),%eax
8010164a:	8b 40 08             	mov    0x8(%eax),%eax
8010164d:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80101654:	ff 
80101655:	89 04 24             	mov    %eax,(%esp)
80101658:	e8 6d 1e 00 00       	call   801034ca <updateBlkRef>
8010165d:	eb 28                	jmp    80101687 <deletedups+0xff>
  else if(ref == 0)
8010165f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101663:	75 22                	jne    80101687 <deletedups+0xff>
  {
    begin_trans();
80101665:	e8 17 2e 00 00       	call   80104481 <begin_trans>
    bfree(b1->dev, b1->sector);
8010166a:	8b 45 10             	mov    0x10(%ebp),%eax
8010166d:	8b 50 08             	mov    0x8(%eax),%edx
80101670:	8b 45 10             	mov    0x10(%ebp),%eax
80101673:	8b 40 04             	mov    0x4(%eax),%eax
80101676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010167a:	89 04 24             	mov    %eax,(%esp)
8010167d:	e8 60 0c 00 00       	call   801022e2 <bfree>
    commit_trans();
80101682:	e8 43 2e 00 00       	call   801044ca <commit_trans>
  }
}
80101687:	c9                   	leave  
80101688:	c3                   	ret    

80101689 <dedup>:

int
dedup(void)
{
80101689:	55                   	push   %ebp
8010168a:	89 e5                	mov    %esp,%ebp
8010168c:	81 ec 88 00 00 00    	sub    $0x88,%esp
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0;
80101692:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101699:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
801016a0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016a7:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
801016ae:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  struct inode* ip1=0, *ip2=0;
801016b5:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
801016bc:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
801016c3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
801016ca:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
801016d1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
801016d8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  uint *a = 0, *b = 0;
801016df:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
801016e6:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  struct superblock sb;
  readsb(1, &sb);
801016ed:	8d 45 98             	lea    -0x68(%ebp),%eax
801016f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801016f4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801016fb:	e8 f4 09 00 00       	call   801020f4 <readsb>
  ninodes = sb.ninodes;
80101700:	8b 45 a0             	mov    -0x60(%ebp),%eax
80101703:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  zeroNextInum();
80101706:	e8 9a 1f 00 00       	call   801036a5 <zeroNextInum>
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
8010170b:	e9 9d 07 00 00       	jmp    80101ead <dedup+0x824>
  {  
    indirects1=0;
80101710:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
    directChanged = 0;
80101717:	c7 05 80 ee 10 80 00 	movl   $0x0,0x8010ee80
8010171e:	00 00 00 
    indirectChanged = 0;
80101721:	c7 05 90 f8 10 80 00 	movl   $0x0,0x8010f890
80101728:	00 00 00 
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
8010172b:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010172e:	89 04 24             	mov    %eax,(%esp)
80101731:	e8 3a 0f 00 00       	call   80102670 <ilock>
    if(ip1->addrs[NDIRECT])
80101736:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101739:	8b 40 4c             	mov    0x4c(%eax),%eax
8010173c:	85 c0                	test   %eax,%eax
8010173e:	74 2a                	je     8010176a <dedup+0xe1>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
80101740:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101743:	8b 50 4c             	mov    0x4c(%eax),%edx
80101746:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101749:	8b 00                	mov    (%eax),%eax
8010174b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010174f:	89 04 24             	mov    %eax,(%esp)
80101752:	e8 4f ea ff ff       	call   801001a6 <bread>
80101757:	89 45 dc             	mov    %eax,-0x24(%ebp)
      a = (uint*)bp1->data;
8010175a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010175d:	83 c0 18             	add    $0x18,%eax
80101760:	89 45 d4             	mov    %eax,-0x2c(%ebp)
      indirects1 = NINDIRECT;
80101763:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
8010176a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101771:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101778:	e9 cf 06 00 00       	jmp    80101e4c <dedup+0x7c3>
    {
      if(blockIndex1<NDIRECT)							// in the same file
8010177d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101781:	0f 8f 5d 02 00 00    	jg     801019e4 <dedup+0x35b>
      {
	if(ip1->addrs[blockIndex1])
80101787:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010178a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010178d:	83 c2 04             	add    $0x4,%edx
80101790:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101794:	85 c0                	test   %eax,%eax
80101796:	0f 84 3c 02 00 00    	je     801019d8 <dedup+0x34f>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
8010179c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010179f:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017a2:	83 c2 04             	add    $0x4,%edx
801017a5:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017a9:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017ac:	8b 00                	mov    (%eax),%eax
801017ae:	89 54 24 04          	mov    %edx,0x4(%esp)
801017b2:	89 04 24             	mov    %eax,(%esp)
801017b5:	e8 ec e9 ff ff       	call   801001a6 <bread>
801017ba:	89 45 e0             	mov    %eax,-0x20(%ebp)
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801017bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017c0:	83 c0 0b             	add    $0xb,%eax
801017c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801017c6:	e9 fc 01 00 00       	jmp    801019c7 <dedup+0x33e>
	  {
	    if(blockIndex2 < NDIRECT)
801017cb:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
801017cf:	0f 8f f3 00 00 00    	jg     801018c8 <dedup+0x23f>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2] && ip1->addrs[blockIndex1] != ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
801017d5:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017db:	83 c2 04             	add    $0x4,%edx
801017de:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017e2:	85 c0                	test   %eax,%eax
801017e4:	0f 84 d9 01 00 00    	je     801019c3 <dedup+0x33a>
801017ea:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
801017f0:	83 c2 04             	add    $0x4,%edx
801017f3:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017f7:	85 c0                	test   %eax,%eax
801017f9:	0f 84 c4 01 00 00    	je     801019c3 <dedup+0x33a>
801017ff:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101802:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101805:	83 c2 04             	add    $0x4,%edx
80101808:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010180c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010180f:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101812:	83 c1 04             	add    $0x4,%ecx
80101815:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101819:	39 c2                	cmp    %eax,%edx
8010181b:	0f 84 a2 01 00 00    	je     801019c3 <dedup+0x33a>
	      {
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
80101821:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101824:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101827:	83 c2 04             	add    $0x4,%edx
8010182a:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010182e:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101831:	8b 00                	mov    (%eax),%eax
80101833:	89 54 24 04          	mov    %edx,0x4(%esp)
80101837:	89 04 24             	mov    %eax,(%esp)
8010183a:	e8 67 e9 ff ff       	call   801001a6 <bread>
8010183f:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101842:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101845:	89 44 24 04          	mov    %eax,0x4(%esp)
80101849:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010184c:	89 04 24             	mov    %eax,(%esp)
8010184f:	e8 ec fc ff ff       	call   80101540 <blkcmp>
80101854:	85 c0                	test   %eax,%eax
80101856:	74 60                	je     801018b8 <dedup+0x22f>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
80101858:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
8010185f:	00 
80101860:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101867:	00 
80101868:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010186b:	89 44 24 14          	mov    %eax,0x14(%esp)
8010186f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101872:	89 44 24 10          	mov    %eax,0x10(%esp)
80101876:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101879:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010187d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101880:	89 44 24 08          	mov    %eax,0x8(%esp)
80101884:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101887:	89 44 24 04          	mov    %eax,0x4(%esp)
8010188b:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010188e:	89 04 24             	mov    %eax,(%esp)
80101891:	e8 f2 fc ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101896:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101899:	89 04 24             	mov    %eax,(%esp)
8010189c:	e8 76 e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801018a1:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018a4:	89 04 24             	mov    %eax,(%esp)
801018a7:	e8 6b e9 ff ff       	call   80100217 <brelse>
		  found = 1;
801018ac:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801018b3:	e9 7c 02 00 00       	jmp    80101b34 <dedup+0x4ab>
		}
		brelse(b2);
801018b8:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018bb:	89 04 24             	mov    %eax,(%esp)
801018be:	e8 54 e9 ff ff       	call   80100217 <brelse>
801018c3:	e9 fb 00 00 00       	jmp    801019c3 <dedup+0x33a>
	      }
	    }
	    else if(a)
801018c8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801018cc:	0f 84 f1 00 00 00    	je     801019c3 <dedup+0x33a>
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
801018d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018d5:	83 e8 0c             	sub    $0xc,%eax
801018d8:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset] && ip1->addrs[blockIndex1] != a[blockIndex2Offset])
801018db:	8b 45 c0             	mov    -0x40(%ebp),%eax
801018de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801018e1:	83 c2 04             	add    $0x4,%edx
801018e4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801018e8:	85 c0                	test   %eax,%eax
801018ea:	0f 84 d3 00 00 00    	je     801019c3 <dedup+0x33a>
801018f0:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801018f3:	c1 e0 02             	shl    $0x2,%eax
801018f6:	03 45 d4             	add    -0x2c(%ebp),%eax
801018f9:	8b 00                	mov    (%eax),%eax
801018fb:	85 c0                	test   %eax,%eax
801018fd:	0f 84 c0 00 00 00    	je     801019c3 <dedup+0x33a>
80101903:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101906:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101909:	83 c2 04             	add    $0x4,%edx
8010190c:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101910:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101913:	c1 e0 02             	shl    $0x2,%eax
80101916:	03 45 d4             	add    -0x2c(%ebp),%eax
80101919:	8b 00                	mov    (%eax),%eax
8010191b:	39 c2                	cmp    %eax,%edx
8010191d:	0f 84 a0 00 00 00    	je     801019c3 <dedup+0x33a>
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);
80101923:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101926:	c1 e0 02             	shl    $0x2,%eax
80101929:	03 45 d4             	add    -0x2c(%ebp),%eax
8010192c:	8b 10                	mov    (%eax),%edx
8010192e:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101931:	8b 00                	mov    (%eax),%eax
80101933:	89 54 24 04          	mov    %edx,0x4(%esp)
80101937:	89 04 24             	mov    %eax,(%esp)
8010193a:	e8 67 e8 ff ff       	call   801001a6 <bread>
8010193f:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101942:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101945:	89 44 24 04          	mov    %eax,0x4(%esp)
80101949:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010194c:	89 04 24             	mov    %eax,(%esp)
8010194f:	e8 ec fb ff ff       	call   80101540 <blkcmp>
80101954:	85 c0                	test   %eax,%eax
80101956:	74 60                	je     801019b8 <dedup+0x32f>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
80101958:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010195b:	89 44 24 1c          	mov    %eax,0x1c(%esp)
8010195f:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101966:	00 
80101967:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010196a:	89 44 24 14          	mov    %eax,0x14(%esp)
8010196e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101971:	89 44 24 10          	mov    %eax,0x10(%esp)
80101975:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101978:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010197c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010197f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101983:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101986:	89 44 24 04          	mov    %eax,0x4(%esp)
8010198a:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010198d:	89 04 24             	mov    %eax,(%esp)
80101990:	e8 f3 fb ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101995:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101998:	89 04 24             	mov    %eax,(%esp)
8010199b:	e8 77 e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801019a0:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019a3:	89 04 24             	mov    %eax,(%esp)
801019a6:	e8 6c e8 ff ff       	call   80100217 <brelse>
		  found = 1;
801019ab:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801019b2:	90                   	nop
801019b3:	e9 7c 01 00 00       	jmp    80101b34 <dedup+0x4ab>
		}
		brelse(b2);
801019b8:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019bb:	89 04 24             	mov    %eax,(%esp)
801019be:	e8 54 e8 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801019c3:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
801019c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019ca:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801019cd:	0f 8f f8 fd ff ff    	jg     801017cb <dedup+0x142>
801019d3:	e9 5c 01 00 00       	jmp    80101b34 <dedup+0x4ab>
	      
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{
	  b1 = 0;
801019d8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	  continue;
801019df:	e9 5d 04 00 00       	jmp    80101e41 <dedup+0x7b8>
	}
      }
	
      else if(!found)					// in the same file
801019e4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801019e8:	0f 85 46 01 00 00    	jne    80101b34 <dedup+0x4ab>
      {
	if(a)
801019ee:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801019f2:	0f 84 3c 01 00 00    	je     80101b34 <dedup+0x4ab>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
801019f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019fb:	83 e8 0c             	sub    $0xc,%eax
801019fe:	89 45 b0             	mov    %eax,-0x50(%ebp)
	  if(a[blockIndex1Offset])
80101a01:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a04:	c1 e0 02             	shl    $0x2,%eax
80101a07:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a0a:	8b 00                	mov    (%eax),%eax
80101a0c:	85 c0                	test   %eax,%eax
80101a0e:	0f 84 14 01 00 00    	je     80101b28 <dedup+0x49f>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
80101a14:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a17:	c1 e0 02             	shl    $0x2,%eax
80101a1a:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a1d:	8b 10                	mov    (%eax),%edx
80101a1f:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101a22:	8b 00                	mov    (%eax),%eax
80101a24:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a28:	89 04 24             	mov    %eax,(%esp)
80101a2b:	e8 76 e7 ff ff       	call   801001a6 <bread>
80101a30:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101a33:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
80101a3a:	e9 db 00 00 00       	jmp    80101b1a <dedup+0x491>
	    {
	      if(a[blockIndex2] && a[blockIndex2] != a[blockIndex1Offset])
80101a3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a42:	c1 e0 02             	shl    $0x2,%eax
80101a45:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a48:	8b 00                	mov    (%eax),%eax
80101a4a:	85 c0                	test   %eax,%eax
80101a4c:	0f 84 c4 00 00 00    	je     80101b16 <dedup+0x48d>
80101a52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a55:	c1 e0 02             	shl    $0x2,%eax
80101a58:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a5b:	8b 10                	mov    (%eax),%edx
80101a5d:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a60:	c1 e0 02             	shl    $0x2,%eax
80101a63:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a66:	8b 00                	mov    (%eax),%eax
80101a68:	39 c2                	cmp    %eax,%edx
80101a6a:	0f 84 a6 00 00 00    	je     80101b16 <dedup+0x48d>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);
80101a70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a73:	c1 e0 02             	shl    $0x2,%eax
80101a76:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a79:	8b 10                	mov    (%eax),%edx
80101a7b:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101a7e:	8b 00                	mov    (%eax),%eax
80101a80:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a84:	89 04 24             	mov    %eax,(%esp)
80101a87:	e8 1a e7 ff ff       	call   801001a6 <bread>
80101a8c:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101a8f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101a92:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a96:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101a99:	89 04 24             	mov    %eax,(%esp)
80101a9c:	e8 9f fa ff ff       	call   80101540 <blkcmp>
80101aa1:	85 c0                	test   %eax,%eax
80101aa3:	74 66                	je     80101b0b <dedup+0x482>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101aa5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101aa8:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101aac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101aaf:	89 44 24 18          	mov    %eax,0x18(%esp)
80101ab3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ab6:	89 44 24 14          	mov    %eax,0x14(%esp)
80101aba:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101abd:	89 44 24 10          	mov    %eax,0x10(%esp)
80101ac1:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ac4:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101ac8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101acb:	89 44 24 08          	mov    %eax,0x8(%esp)
80101acf:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ad2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ad6:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ad9:	89 04 24             	mov    %eax,(%esp)
80101adc:	e8 a7 fa ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101ae1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101ae4:	89 04 24             	mov    %eax,(%esp)
80101ae7:	e8 2b e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101aec:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101aef:	89 04 24             	mov    %eax,(%esp)
80101af2:	e8 20 e7 ff ff       	call   80100217 <brelse>
		  found = 1;
80101af7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  indirectChanged = 1;
80101afe:	c7 05 90 f8 10 80 01 	movl   $0x1,0x8010f890
80101b05:	00 00 00 
		  break;
80101b08:	90                   	nop
80101b09:	eb 29                	jmp    80101b34 <dedup+0x4ab>
		}
		brelse(b2);
80101b0b:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b0e:	89 04 24             	mov    %eax,(%esp)
80101b11:	e8 01 e7 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101b16:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b1d:	3b 45 b0             	cmp    -0x50(%ebp),%eax
80101b20:	0f 8f 19 ff ff ff    	jg     80101a3f <dedup+0x3b6>
80101b26:	eb 0c                	jmp    80101b34 <dedup+0x4ab>
	      }
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    b1 = 0;
80101b28:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	    continue;
80101b2f:	e9 0d 03 00 00       	jmp    80101e41 <dedup+0x7b8>
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101b34:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101b38:	0f 85 f2 02 00 00    	jne    80101e30 <dedup+0x7a7>
80101b3e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b42:	0f 84 e8 02 00 00    	je     80101e30 <dedup+0x7a7>
      {
	uint* aSub = 0;
80101b48:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	int blockIndex1Offset = blockIndex1;
80101b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b52:	89 45 c8             	mov    %eax,-0x38(%ebp)
	if(blockIndex1 >= NDIRECT)
80101b55:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101b59:	7e 0f                	jle    80101b6a <dedup+0x4e1>
	{
	  aSub = a;
80101b5b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101b5e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b64:	83 e8 0c             	sub    $0xc,%eax
80101b67:	89 45 c8             	mov    %eax,-0x38(%ebp)
	}
	prevInum = ninodes-1;
80101b6a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101b6d:	83 e8 01             	sub    $0x1,%eax
80101b70:	89 45 a8             	mov    %eax,-0x58(%ebp)
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101b73:	e9 9a 02 00 00       	jmp    80101e12 <dedup+0x789>
	{
	  indirects2=0;
80101b78:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	  ilock(ip2);
80101b7f:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b82:	89 04 24             	mov    %eax,(%esp)
80101b85:	e8 e6 0a 00 00       	call   80102670 <ilock>
	  if(ip2->addrs[NDIRECT])
80101b8a:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b8d:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b90:	85 c0                	test   %eax,%eax
80101b92:	74 2a                	je     80101bbe <dedup+0x535>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101b94:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b97:	8b 50 4c             	mov    0x4c(%eax),%edx
80101b9a:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b9d:	8b 00                	mov    (%eax),%eax
80101b9f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ba3:	89 04 24             	mov    %eax,(%esp)
80101ba6:	e8 fb e5 ff ff       	call   801001a6 <bread>
80101bab:	89 45 d8             	mov    %eax,-0x28(%ebp)
	    b = (uint*)bp2->data;
80101bae:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101bb1:	83 c0 18             	add    $0x18,%eax
80101bb4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	    indirects2 = NINDIRECT;
80101bb7:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101bbe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101bc1:	83 c0 0b             	add    $0xb,%eax
80101bc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101bc7:	e9 1c 02 00 00       	jmp    80101de8 <dedup+0x75f>
	  {
	    if(blockIndex2<NDIRECT)
80101bcc:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101bd0:	0f 8f 03 01 00 00    	jg     80101cd9 <dedup+0x650>
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
80101bd6:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101bda:	74 20                	je     80101bfc <dedup+0x573>
80101bdc:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bdf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101be2:	83 c2 04             	add    $0x4,%edx
80101be5:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101be9:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101bec:	c1 e0 02             	shl    $0x2,%eax
80101bef:	03 45 cc             	add    -0x34(%ebp),%eax
80101bf2:	8b 00                	mov    (%eax),%eax
80101bf4:	39 c2                	cmp    %eax,%edx
80101bf6:	0f 84 e4 01 00 00    	je     80101de0 <dedup+0x757>
80101bfc:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c02:	83 c2 04             	add    $0x4,%edx
80101c05:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c09:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101c0c:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101c0f:	83 c1 04             	add    $0x4,%ecx
80101c12:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101c16:	39 c2                	cmp    %eax,%edx
80101c18:	0f 84 c2 01 00 00    	je     80101de0 <dedup+0x757>
		continue;
	      if(ip2->addrs[blockIndex2])
80101c1e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c21:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c24:	83 c2 04             	add    $0x4,%edx
80101c27:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c2b:	85 c0                	test   %eax,%eax
80101c2d:	0f 84 b1 01 00 00    	je     80101de4 <dedup+0x75b>
	      {
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);
80101c33:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c36:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c39:	83 c2 04             	add    $0x4,%edx
80101c3c:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c40:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c43:	8b 00                	mov    (%eax),%eax
80101c45:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c49:	89 04 24             	mov    %eax,(%esp)
80101c4c:	e8 55 e5 ff ff       	call   801001a6 <bread>
80101c51:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101c54:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c57:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101c5e:	89 04 24             	mov    %eax,(%esp)
80101c61:	e8 da f8 ff ff       	call   80101540 <blkcmp>
80101c66:	85 c0                	test   %eax,%eax
80101c68:	74 5f                	je     80101cc9 <dedup+0x640>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101c6a:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101c71:	00 
80101c72:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101c75:	89 44 24 18          	mov    %eax,0x18(%esp)
80101c79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c7c:	89 44 24 14          	mov    %eax,0x14(%esp)
80101c80:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c83:	89 44 24 10          	mov    %eax,0x10(%esp)
80101c87:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101c8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101c91:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c95:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c98:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c9c:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101c9f:	89 04 24             	mov    %eax,(%esp)
80101ca2:	e8 e1 f8 ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101ca7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101caa:	89 04 24             	mov    %eax,(%esp)
80101cad:	e8 65 e5 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101cb2:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cb5:	89 04 24             	mov    %eax,(%esp)
80101cb8:	e8 5a e5 ff ff       	call   80100217 <brelse>
		  found = 1;
80101cbd:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101cc4:	e9 29 01 00 00       	jmp    80101df2 <dedup+0x769>
		}
		brelse(b2);
80101cc9:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ccc:	89 04 24             	mov    %eax,(%esp)
80101ccf:	e8 43 e5 ff ff       	call   80100217 <brelse>
80101cd4:	e9 0b 01 00 00       	jmp    80101de4 <dedup+0x75b>
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
80101cd9:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80101cdd:	0f 84 01 01 00 00    	je     80101de4 <dedup+0x75b>
	    {
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
80101ce3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ce6:	83 e8 0c             	sub    $0xc,%eax
80101ce9:	89 45 ac             	mov    %eax,-0x54(%ebp)
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
80101cec:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101cf0:	74 1e                	je     80101d10 <dedup+0x687>
80101cf2:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101cf5:	c1 e0 02             	shl    $0x2,%eax
80101cf8:	03 45 d0             	add    -0x30(%ebp),%eax
80101cfb:	8b 10                	mov    (%eax),%edx
80101cfd:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101d00:	c1 e0 02             	shl    $0x2,%eax
80101d03:	03 45 cc             	add    -0x34(%ebp),%eax
80101d06:	8b 00                	mov    (%eax),%eax
80101d08:	39 c2                	cmp    %eax,%edx
80101d0a:	0f 84 d3 00 00 00    	je     80101de3 <dedup+0x75a>
80101d10:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d13:	c1 e0 02             	shl    $0x2,%eax
80101d16:	03 45 d0             	add    -0x30(%ebp),%eax
80101d19:	8b 10                	mov    (%eax),%edx
80101d1b:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101d1e:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101d21:	83 c1 04             	add    $0x4,%ecx
80101d24:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101d28:	39 c2                	cmp    %eax,%edx
80101d2a:	0f 84 b3 00 00 00    	je     80101de3 <dedup+0x75a>
		continue;
	      if(b[blockIndex2Offset])
80101d30:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d33:	c1 e0 02             	shl    $0x2,%eax
80101d36:	03 45 d0             	add    -0x30(%ebp),%eax
80101d39:	8b 00                	mov    (%eax),%eax
80101d3b:	85 c0                	test   %eax,%eax
80101d3d:	0f 84 a1 00 00 00    	je     80101de4 <dedup+0x75b>
	      {
		b2 = bread(ip2->dev,b[blockIndex2Offset]);
80101d43:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d46:	c1 e0 02             	shl    $0x2,%eax
80101d49:	03 45 d0             	add    -0x30(%ebp),%eax
80101d4c:	8b 10                	mov    (%eax),%edx
80101d4e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d51:	8b 00                	mov    (%eax),%eax
80101d53:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d57:	89 04 24             	mov    %eax,(%esp)
80101d5a:	e8 47 e4 ff ff       	call   801001a6 <bread>
80101d5f:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101d62:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d65:	89 44 24 04          	mov    %eax,0x4(%esp)
80101d69:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101d6c:	89 04 24             	mov    %eax,(%esp)
80101d6f:	e8 cc f7 ff ff       	call   80101540 <blkcmp>
80101d74:	85 c0                	test   %eax,%eax
80101d76:	74 5b                	je     80101dd3 <dedup+0x74a>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101d78:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101d7b:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101d7f:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101d82:	89 44 24 18          	mov    %eax,0x18(%esp)
80101d86:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d89:	89 44 24 14          	mov    %eax,0x14(%esp)
80101d8d:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101d90:	89 44 24 10          	mov    %eax,0x10(%esp)
80101d94:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d97:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101d9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101d9e:	89 44 24 08          	mov    %eax,0x8(%esp)
80101da2:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101da5:	89 44 24 04          	mov    %eax,0x4(%esp)
80101da9:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101dac:	89 04 24             	mov    %eax,(%esp)
80101daf:	e8 d4 f7 ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101db4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101db7:	89 04 24             	mov    %eax,(%esp)
80101dba:	e8 58 e4 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101dbf:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101dc2:	89 04 24             	mov    %eax,(%esp)
80101dc5:	e8 4d e4 ff ff       	call   80100217 <brelse>
		  found = 1;
80101dca:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101dd1:	eb 1f                	jmp    80101df2 <dedup+0x769>
		}
		brelse(b2);
80101dd3:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101dd6:	89 04 24             	mov    %eax,(%esp)
80101dd9:	e8 39 e4 ff ff       	call   80100217 <brelse>
80101dde:	eb 04                	jmp    80101de4 <dedup+0x75b>
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
	  {
	    if(blockIndex2<NDIRECT)
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
		continue;
80101de0:	90                   	nop
80101de1:	eb 01                	jmp    80101de4 <dedup+0x75b>
	    else if(b)
	    {
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
		continue;
80101de3:	90                   	nop
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101de4:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101de8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101dec:	0f 89 da fd ff ff    	jns    80101bcc <dedup+0x543>
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
80101df2:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101df5:	8b 40 4c             	mov    0x4c(%eax),%eax
80101df8:	85 c0                	test   %eax,%eax
80101dfa:	74 0b                	je     80101e07 <dedup+0x77e>
	  {
	    brelse(bp2);
80101dfc:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101dff:	89 04 24             	mov    %eax,(%esp)
80101e02:	e8 10 e4 ff ff       	call   80100217 <brelse>
	  }
	  
	  iunlockput(ip2);
80101e07:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e0a:	89 04 24             	mov    %eax,(%esp)
80101e0d:	e8 e2 0a 00 00       	call   801028f4 <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101e12:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e16:	75 18                	jne    80101e30 <dedup+0x7a7>
80101e18:	8d 45 a8             	lea    -0x58(%ebp),%eax
80101e1b:	89 04 24             	mov    %eax,(%esp)
80101e1e:	e8 f6 15 00 00       	call   80103419 <getPrevInode>
80101e23:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101e26:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101e2a:	0f 85 48 fd ff ff    	jne    80101b78 <dedup+0x4ef>
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
80101e30:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e34:	75 0b                	jne    80101e41 <dedup+0x7b8>
      {
	brelse(b1);				// release the outer loop block
80101e36:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101e39:	89 04 24             	mov    %eax,(%esp)
80101e3c:	e8 d6 e3 ff ff       	call   80100217 <brelse>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101e41:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e45:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101e4c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e4f:	83 c0 0c             	add    $0xc,%eax
80101e52:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101e55:	0f 8f 22 f9 ff ff    	jg     8010177d <dedup+0xf4>
      {
	brelse(b1);				// release the outer loop block
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101e5b:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101e5e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e61:	85 c0                	test   %eax,%eax
80101e63:	74 1f                	je     80101e84 <dedup+0x7fb>
    {
      if(indirectChanged)
80101e65:	a1 90 f8 10 80       	mov    0x8010f890,%eax
80101e6a:	85 c0                	test   %eax,%eax
80101e6c:	74 0b                	je     80101e79 <dedup+0x7f0>
	bwrite(bp1);
80101e6e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101e71:	89 04 24             	mov    %eax,(%esp)
80101e74:	e8 64 e3 ff ff       	call   801001dd <bwrite>
      brelse(bp1);
80101e79:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101e7c:	89 04 24             	mov    %eax,(%esp)
80101e7f:	e8 93 e3 ff ff       	call   80100217 <brelse>
    }
    
    if(directChanged)
80101e84:	a1 80 ee 10 80       	mov    0x8010ee80,%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	74 15                	je     80101ea2 <dedup+0x819>
    {
      begin_trans();
80101e8d:	e8 ef 25 00 00       	call   80104481 <begin_trans>
      iupdate(ip1);
80101e92:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101e95:	89 04 24             	mov    %eax,(%esp)
80101e98:	e8 17 06 00 00       	call   801024b4 <iupdate>
      commit_trans();
80101e9d:	e8 28 26 00 00       	call   801044ca <commit_trans>
    }
    iunlockput(ip1);
80101ea2:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ea5:	89 04 24             	mov    %eax,(%esp)
80101ea8:	e8 47 0a 00 00       	call   801028f4 <iunlockput>
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  zeroNextInum();
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101ead:	e8 b3 14 00 00       	call   80103365 <getNextInode>
80101eb2:	89 45 c0             	mov    %eax,-0x40(%ebp)
80101eb5:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
80101eb9:	0f 85 51 f8 ff ff    	jne    80101710 <dedup+0x87>
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
80101ebf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101ec4:	c9                   	leave  
80101ec5:	c3                   	ret    

80101ec6 <getSharedBlocksRate>:

int
getSharedBlocksRate(void)
{
80101ec6:	55                   	push   %ebp
80101ec7:	89 e5                	mov    %esp,%ebp
80101ec9:	53                   	push   %ebx
80101eca:	83 ec 64             	sub    $0x64,%esp
  int i,digit;
  int saved = 0,total = 0;
80101ecd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101ed4:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  struct buf* bp1 = bread(1,1024);
80101edb:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80101ee2:	00 
80101ee3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101eea:	e8 b7 e2 ff ff       	call   801001a6 <bread>
80101eef:	89 45 e8             	mov    %eax,-0x18(%ebp)
  struct buf* bp2 = bread(1,1025);
80101ef2:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80101ef9:	00 
80101efa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f01:	e8 a0 e2 ff ff       	call   801001a6 <bread>
80101f06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct superblock sb;
  readsb(1, &sb);
80101f09:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80101f0c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f10:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f17:	e8 d8 01 00 00       	call   801020f4 <readsb>
  total = sb.nblocks - getFreeBlocks();
80101f1c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
80101f1f:	e8 23 f5 ff ff       	call   80101447 <getFreeBlocks>
80101f24:	89 da                	mov    %ebx,%edx
80101f26:	29 c2                	sub    %eax,%edx
80101f28:	89 d0                	mov    %edx,%eax
80101f2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  for(i=0;i<BSIZE;i++)
80101f2d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f34:	eb 4c                	jmp    80101f82 <getSharedBlocksRate+0xbc>
  {
    if(bp1->data[i] > 0)
80101f36:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101f39:	03 45 f4             	add    -0xc(%ebp),%eax
80101f3c:	83 c0 10             	add    $0x10,%eax
80101f3f:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f43:	84 c0                	test   %al,%al
80101f45:	74 13                	je     80101f5a <getSharedBlocksRate+0x94>
      saved += bp1->data[i];
80101f47:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101f4a:	03 45 f4             	add    -0xc(%ebp),%eax
80101f4d:	83 c0 10             	add    $0x10,%eax
80101f50:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f54:	0f b6 c0             	movzbl %al,%eax
80101f57:	01 45 f0             	add    %eax,-0x10(%ebp)
    if(bp2->data[i] > 0)
80101f5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f5d:	03 45 f4             	add    -0xc(%ebp),%eax
80101f60:	83 c0 10             	add    $0x10,%eax
80101f63:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f67:	84 c0                	test   %al,%al
80101f69:	74 13                	je     80101f7e <getSharedBlocksRate+0xb8>
      saved += bp2->data[i];
80101f6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f6e:	03 45 f4             	add    -0xc(%ebp),%eax
80101f71:	83 c0 10             	add    $0x10,%eax
80101f74:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f78:	0f b6 c0             	movzbl %al,%eax
80101f7b:	01 45 f0             	add    %eax,-0x10(%ebp)
  struct buf* bp2 = bread(1,1025);
  struct superblock sb;
  readsb(1, &sb);
  total = sb.nblocks - getFreeBlocks();
  
  for(i=0;i<BSIZE;i++)
80101f7e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101f82:	81 7d f4 ff 01 00 00 	cmpl   $0x1ff,-0xc(%ebp)
80101f89:	7e ab                	jle    80101f36 <getSharedBlocksRate+0x70>
      saved += bp1->data[i];
    if(bp2->data[i] > 0)
      saved += bp2->data[i];
  }
  
  total += saved;
80101f8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f8e:	01 45 ec             	add    %eax,-0x14(%ebp)
  
  double res = (double)saved/(double)total;
80101f91:	db 45 f0             	fildl  -0x10(%ebp)
80101f94:	db 45 ec             	fildl  -0x14(%ebp)
80101f97:	de f9                	fdivrp %st,%st(1)
80101f99:	dd 5d d8             	fstpl  -0x28(%ebp)
  cprintf("saved = %d, total = %d\n",saved,total);
80101f9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fa3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa6:	89 44 24 04          	mov    %eax,0x4(%esp)
80101faa:	c7 04 24 e8 96 10 80 	movl   $0x801096e8,(%esp)
80101fb1:	e8 eb e3 ff ff       	call   801003a1 <cprintf>
   
  cprintf("Shared block rate is: 0.");
80101fb6:	c7 04 24 00 97 10 80 	movl   $0x80109700,(%esp)
80101fbd:	e8 df e3 ff ff       	call   801003a1 <cprintf>
  for(i=10;i!=100000;i*=10)
80101fc2:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
80101fc9:	eb 3e                	jmp    80102009 <getSharedBlocksRate+0x143>
  {
    digit = res*i;
80101fcb:	db 45 f4             	fildl  -0xc(%ebp)
80101fce:	dc 4d d8             	fmull  -0x28(%ebp)
80101fd1:	d9 7d b6             	fnstcw -0x4a(%ebp)
80101fd4:	0f b7 45 b6          	movzwl -0x4a(%ebp),%eax
80101fd8:	b4 0c                	mov    $0xc,%ah
80101fda:	66 89 45 b4          	mov    %ax,-0x4c(%ebp)
80101fde:	d9 6d b4             	fldcw  -0x4c(%ebp)
80101fe1:	db 5d d4             	fistpl -0x2c(%ebp)
80101fe4:	d9 6d b6             	fldcw  -0x4a(%ebp)
    cprintf("%d",digit);
80101fe7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101fea:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fee:	c7 04 24 19 97 10 80 	movl   $0x80109719,(%esp)
80101ff5:	e8 a7 e3 ff ff       	call   801003a1 <cprintf>
  
  double res = (double)saved/(double)total;
  cprintf("saved = %d, total = %d\n",saved,total);
   
  cprintf("Shared block rate is: 0.");
  for(i=10;i!=100000;i*=10)
80101ffa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ffd:	89 d0                	mov    %edx,%eax
80101fff:	c1 e0 02             	shl    $0x2,%eax
80102002:	01 d0                	add    %edx,%eax
80102004:	01 c0                	add    %eax,%eax
80102006:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102009:	81 7d f4 a0 86 01 00 	cmpl   $0x186a0,-0xc(%ebp)
80102010:	75 b9                	jne    80101fcb <getSharedBlocksRate+0x105>
  {
    digit = res*i;
    cprintf("%d",digit);
  }
  cprintf("\n");
80102012:	c7 04 24 1c 97 10 80 	movl   $0x8010971c,(%esp)
80102019:	e8 83 e3 ff ff       	call   801003a1 <cprintf>
  
  return 0;
8010201e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102023:	83 c4 64             	add    $0x64,%esp
80102026:	5b                   	pop    %ebx
80102027:	5d                   	pop    %ebp
80102028:	c3                   	ret    
80102029:	00 00                	add    %al,(%eax)
	...

8010202c <replaceBlk>:
int nextInum = 0;
int prevInum = 0;

void
replaceBlk(struct inode* ip, uint old, uint new)
{
8010202c:	55                   	push   %ebp
8010202d:	89 e5                	mov    %esp,%ebp
8010202f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102032:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102039:	eb 37                	jmp    80102072 <replaceBlk+0x46>
    if(ip->addrs[i] && ip->addrs[i] == old){
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102041:	83 c2 04             	add    $0x4,%edx
80102044:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102048:	85 c0                	test   %eax,%eax
8010204a:	74 22                	je     8010206e <replaceBlk+0x42>
8010204c:	8b 45 08             	mov    0x8(%ebp),%eax
8010204f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102052:	83 c2 04             	add    $0x4,%edx
80102055:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102059:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010205c:	75 10                	jne    8010206e <replaceBlk+0x42>
      ip->addrs[i] = new;
8010205e:	8b 45 08             	mov    0x8(%ebp),%eax
80102061:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102064:	8d 4a 04             	lea    0x4(%edx),%ecx
80102067:	8b 55 10             	mov    0x10(%ebp),%edx
8010206a:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010206e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102072:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102076:	7e c3                	jle    8010203b <replaceBlk+0xf>
    if(ip->addrs[i] && ip->addrs[i] == old){
      ip->addrs[i] = new;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102078:	8b 45 08             	mov    0x8(%ebp),%eax
8010207b:	8b 40 4c             	mov    0x4c(%eax),%eax
8010207e:	85 c0                	test   %eax,%eax
80102080:	74 70                	je     801020f2 <replaceBlk+0xc6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102082:	8b 45 08             	mov    0x8(%ebp),%eax
80102085:	8b 50 4c             	mov    0x4c(%eax),%edx
80102088:	8b 45 08             	mov    0x8(%ebp),%eax
8010208b:	8b 00                	mov    (%eax),%eax
8010208d:	89 54 24 04          	mov    %edx,0x4(%esp)
80102091:	89 04 24             	mov    %eax,(%esp)
80102094:	e8 0d e1 ff ff       	call   801001a6 <bread>
80102099:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
8010209c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010209f:	83 c0 18             	add    $0x18,%eax
801020a2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
801020a5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801020ac:	eb 31                	jmp    801020df <replaceBlk+0xb3>
      if(a[j] && a[j] == old)
801020ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020b1:	c1 e0 02             	shl    $0x2,%eax
801020b4:	03 45 e8             	add    -0x18(%ebp),%eax
801020b7:	8b 00                	mov    (%eax),%eax
801020b9:	85 c0                	test   %eax,%eax
801020bb:	74 1e                	je     801020db <replaceBlk+0xaf>
801020bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020c0:	c1 e0 02             	shl    $0x2,%eax
801020c3:	03 45 e8             	add    -0x18(%ebp),%eax
801020c6:	8b 00                	mov    (%eax),%eax
801020c8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801020cb:	75 0e                	jne    801020db <replaceBlk+0xaf>
	a[j] = new;
801020cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020d0:	c1 e0 02             	shl    $0x2,%eax
801020d3:	03 45 e8             	add    -0x18(%ebp),%eax
801020d6:	8b 55 10             	mov    0x10(%ebp),%edx
801020d9:	89 10                	mov    %edx,(%eax)
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
801020db:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801020df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e2:	83 f8 7f             	cmp    $0x7f,%eax
801020e5:	76 c7                	jbe    801020ae <replaceBlk+0x82>
      if(a[j] && a[j] == old)
	a[j] = new;
    }
    brelse(bp);
801020e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ea:	89 04 24             	mov    %eax,(%esp)
801020ed:	e8 25 e1 ff ff       	call   80100217 <brelse>
  }
}
801020f2:	c9                   	leave  
801020f3:	c3                   	ret    

801020f4 <readsb>:
  

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801020f4:	55                   	push   %ebp
801020f5:	89 e5                	mov    %esp,%ebp
801020f7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801020fa:	8b 45 08             	mov    0x8(%ebp),%eax
801020fd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102104:	00 
80102105:	89 04 24             	mov    %eax,(%esp)
80102108:	e8 99 e0 ff ff       	call   801001a6 <bread>
8010210d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80102110:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102113:	83 c0 18             	add    $0x18,%eax
80102116:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010211d:	00 
8010211e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102122:	8b 45 0c             	mov    0xc(%ebp),%eax
80102125:	89 04 24             	mov    %eax,(%esp)
80102128:	e8 fc 3f 00 00       	call   80106129 <memmove>
  brelse(bp);
8010212d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102130:	89 04 24             	mov    %eax,(%esp)
80102133:	e8 df e0 ff ff       	call   80100217 <brelse>
}
80102138:	c9                   	leave  
80102139:	c3                   	ret    

8010213a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010213a:	55                   	push   %ebp
8010213b:	89 e5                	mov    %esp,%ebp
8010213d:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80102140:	8b 55 0c             	mov    0xc(%ebp),%edx
80102143:	8b 45 08             	mov    0x8(%ebp),%eax
80102146:	89 54 24 04          	mov    %edx,0x4(%esp)
8010214a:	89 04 24             	mov    %eax,(%esp)
8010214d:	e8 54 e0 ff ff       	call   801001a6 <bread>
80102152:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80102155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102158:	83 c0 18             	add    $0x18,%eax
8010215b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80102162:	00 
80102163:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010216a:	00 
8010216b:	89 04 24             	mov    %eax,(%esp)
8010216e:	e8 e3 3e 00 00       	call   80106056 <memset>
  log_write(bp);
80102173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102176:	89 04 24             	mov    %eax,(%esp)
80102179:	e8 a4 23 00 00       	call   80104522 <log_write>
  brelse(bp);
8010217e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102181:	89 04 24             	mov    %eax,(%esp)
80102184:	e8 8e e0 ff ff       	call   80100217 <brelse>
}
80102189:	c9                   	leave  
8010218a:	c3                   	ret    

8010218b <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010218b:	55                   	push   %ebp
8010218c:	89 e5                	mov    %esp,%ebp
8010218e:	53                   	push   %ebx
8010218f:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80102192:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80102199:	8b 45 08             	mov    0x8(%ebp),%eax
8010219c:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010219f:	89 54 24 04          	mov    %edx,0x4(%esp)
801021a3:	89 04 24             	mov    %eax,(%esp)
801021a6:	e8 49 ff ff ff       	call   801020f4 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801021ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021b2:	e9 11 01 00 00       	jmp    801022c8 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801021b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021ba:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801021c0:	85 c0                	test   %eax,%eax
801021c2:	0f 48 c2             	cmovs  %edx,%eax
801021c5:	c1 f8 0c             	sar    $0xc,%eax
801021c8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801021cb:	c1 ea 03             	shr    $0x3,%edx
801021ce:	01 d0                	add    %edx,%eax
801021d0:	83 c0 03             	add    $0x3,%eax
801021d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801021d7:	8b 45 08             	mov    0x8(%ebp),%eax
801021da:	89 04 24             	mov    %eax,(%esp)
801021dd:	e8 c4 df ff ff       	call   801001a6 <bread>
801021e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801021e5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801021ec:	e9 a7 00 00 00       	jmp    80102298 <balloc+0x10d>
      m = 1 << (bi % 8);
801021f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021f4:	89 c2                	mov    %eax,%edx
801021f6:	c1 fa 1f             	sar    $0x1f,%edx
801021f9:	c1 ea 1d             	shr    $0x1d,%edx
801021fc:	01 d0                	add    %edx,%eax
801021fe:	83 e0 07             	and    $0x7,%eax
80102201:	29 d0                	sub    %edx,%eax
80102203:	ba 01 00 00 00       	mov    $0x1,%edx
80102208:	89 d3                	mov    %edx,%ebx
8010220a:	89 c1                	mov    %eax,%ecx
8010220c:	d3 e3                	shl    %cl,%ebx
8010220e:	89 d8                	mov    %ebx,%eax
80102210:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80102213:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102216:	8d 50 07             	lea    0x7(%eax),%edx
80102219:	85 c0                	test   %eax,%eax
8010221b:	0f 48 c2             	cmovs  %edx,%eax
8010221e:	c1 f8 03             	sar    $0x3,%eax
80102221:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102224:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80102229:	0f b6 c0             	movzbl %al,%eax
8010222c:	23 45 e8             	and    -0x18(%ebp),%eax
8010222f:	85 c0                	test   %eax,%eax
80102231:	75 61                	jne    80102294 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80102233:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102236:	8d 50 07             	lea    0x7(%eax),%edx
80102239:	85 c0                	test   %eax,%eax
8010223b:	0f 48 c2             	cmovs  %edx,%eax
8010223e:	c1 f8 03             	sar    $0x3,%eax
80102241:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102244:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102249:	89 d1                	mov    %edx,%ecx
8010224b:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010224e:	09 ca                	or     %ecx,%edx
80102250:	89 d1                	mov    %edx,%ecx
80102252:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102255:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80102259:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010225c:	89 04 24             	mov    %eax,(%esp)
8010225f:	e8 be 22 00 00       	call   80104522 <log_write>
        brelse(bp);
80102264:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102267:	89 04 24             	mov    %eax,(%esp)
8010226a:	e8 a8 df ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010226f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102272:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102275:	01 c2                	add    %eax,%edx
80102277:	8b 45 08             	mov    0x8(%ebp),%eax
8010227a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010227e:	89 04 24             	mov    %eax,(%esp)
80102281:	e8 b4 fe ff ff       	call   8010213a <bzero>
        return b + bi;
80102286:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102289:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010228c:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010228e:	83 c4 34             	add    $0x34,%esp
80102291:	5b                   	pop    %ebx
80102292:	5d                   	pop    %ebp
80102293:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102294:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102298:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010229f:	7f 15                	jg     801022b6 <balloc+0x12b>
801022a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022a7:	01 d0                	add    %edx,%eax
801022a9:	89 c2                	mov    %eax,%edx
801022ab:	8b 45 d8             	mov    -0x28(%ebp),%eax
801022ae:	39 c2                	cmp    %eax,%edx
801022b0:	0f 82 3b ff ff ff    	jb     801021f1 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801022b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022b9:	89 04 24             	mov    %eax,(%esp)
801022bc:	e8 56 df ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801022c1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801022c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022cb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801022ce:	39 c2                	cmp    %eax,%edx
801022d0:	0f 82 e1 fe ff ff    	jb     801021b7 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801022d6:	c7 04 24 20 97 10 80 	movl   $0x80109720,(%esp)
801022dd:	e8 5b e2 ff ff       	call   8010053d <panic>

801022e2 <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
801022e2:	55                   	push   %ebp
801022e3:	89 e5                	mov    %esp,%ebp
801022e5:	53                   	push   %ebx
801022e6:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801022e9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801022ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801022f0:	8b 45 08             	mov    0x8(%ebp),%eax
801022f3:	89 04 24             	mov    %eax,(%esp)
801022f6:	e8 f9 fd ff ff       	call   801020f4 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801022fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801022fe:	89 c2                	mov    %eax,%edx
80102300:	c1 ea 0c             	shr    $0xc,%edx
80102303:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102306:	c1 e8 03             	shr    $0x3,%eax
80102309:	01 d0                	add    %edx,%eax
8010230b:	8d 50 03             	lea    0x3(%eax),%edx
8010230e:	8b 45 08             	mov    0x8(%ebp),%eax
80102311:	89 54 24 04          	mov    %edx,0x4(%esp)
80102315:	89 04 24             	mov    %eax,(%esp)
80102318:	e8 89 de ff ff       	call   801001a6 <bread>
8010231d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80102320:	8b 45 0c             	mov    0xc(%ebp),%eax
80102323:	25 ff 0f 00 00       	and    $0xfff,%eax
80102328:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010232b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010232e:	89 c2                	mov    %eax,%edx
80102330:	c1 fa 1f             	sar    $0x1f,%edx
80102333:	c1 ea 1d             	shr    $0x1d,%edx
80102336:	01 d0                	add    %edx,%eax
80102338:	83 e0 07             	and    $0x7,%eax
8010233b:	29 d0                	sub    %edx,%eax
8010233d:	ba 01 00 00 00       	mov    $0x1,%edx
80102342:	89 d3                	mov    %edx,%ebx
80102344:	89 c1                	mov    %eax,%ecx
80102346:	d3 e3                	shl    %cl,%ebx
80102348:	89 d8                	mov    %ebx,%eax
8010234a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010234d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102350:	8d 50 07             	lea    0x7(%eax),%edx
80102353:	85 c0                	test   %eax,%eax
80102355:	0f 48 c2             	cmovs  %edx,%eax
80102358:	c1 f8 03             	sar    $0x3,%eax
8010235b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010235e:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80102363:	0f b6 c0             	movzbl %al,%eax
80102366:	23 45 ec             	and    -0x14(%ebp),%eax
80102369:	85 c0                	test   %eax,%eax
8010236b:	75 0c                	jne    80102379 <bfree+0x97>
    panic("freeing free block");
8010236d:	c7 04 24 36 97 10 80 	movl   $0x80109736,(%esp)
80102374:	e8 c4 e1 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80102379:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010237c:	8d 50 07             	lea    0x7(%eax),%edx
8010237f:	85 c0                	test   %eax,%eax
80102381:	0f 48 c2             	cmovs  %edx,%eax
80102384:	c1 f8 03             	sar    $0x3,%eax
80102387:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010238a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010238f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80102392:	f7 d1                	not    %ecx
80102394:	21 ca                	and    %ecx,%edx
80102396:	89 d1                	mov    %edx,%ecx
80102398:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010239b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010239f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a2:	89 04 24             	mov    %eax,(%esp)
801023a5:	e8 78 21 00 00       	call   80104522 <log_write>
  brelse(bp);
801023aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ad:	89 04 24             	mov    %eax,(%esp)
801023b0:	e8 62 de ff ff       	call   80100217 <brelse>
}
801023b5:	83 c4 34             	add    $0x34,%esp
801023b8:	5b                   	pop    %ebx
801023b9:	5d                   	pop    %ebp
801023ba:	c3                   	ret    

801023bb <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801023bb:	55                   	push   %ebp
801023bc:	89 e5                	mov    %esp,%ebp
801023be:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801023c1:	c7 44 24 04 49 97 10 	movl   $0x80109749,0x4(%esp)
801023c8:	80 
801023c9:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801023d0:	e8 11 3a 00 00       	call   80105de6 <initlock>
}
801023d5:	c9                   	leave  
801023d6:	c3                   	ret    

801023d7 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801023d7:	55                   	push   %ebp
801023d8:	89 e5                	mov    %esp,%ebp
801023da:	83 ec 48             	sub    $0x48,%esp
801023dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801023e0:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801023e4:	8b 45 08             	mov    0x8(%ebp),%eax
801023e7:	8d 55 dc             	lea    -0x24(%ebp),%edx
801023ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801023ee:	89 04 24             	mov    %eax,(%esp)
801023f1:	e8 fe fc ff ff       	call   801020f4 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801023f6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801023fd:	e9 98 00 00 00       	jmp    8010249a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80102402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102405:	c1 e8 03             	shr    $0x3,%eax
80102408:	83 c0 02             	add    $0x2,%eax
8010240b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010240f:	8b 45 08             	mov    0x8(%ebp),%eax
80102412:	89 04 24             	mov    %eax,(%esp)
80102415:	e8 8c dd ff ff       	call   801001a6 <bread>
8010241a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010241d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102420:	8d 50 18             	lea    0x18(%eax),%edx
80102423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102426:	83 e0 07             	and    $0x7,%eax
80102429:	c1 e0 06             	shl    $0x6,%eax
8010242c:	01 d0                	add    %edx,%eax
8010242e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80102431:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102434:	0f b7 00             	movzwl (%eax),%eax
80102437:	66 85 c0             	test   %ax,%ax
8010243a:	75 4f                	jne    8010248b <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
8010243c:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80102443:	00 
80102444:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010244b:	00 
8010244c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010244f:	89 04 24             	mov    %eax,(%esp)
80102452:	e8 ff 3b 00 00       	call   80106056 <memset>
      dip->type = type;
80102457:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010245a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010245e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80102461:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102464:	89 04 24             	mov    %eax,(%esp)
80102467:	e8 b6 20 00 00       	call   80104522 <log_write>
      brelse(bp);
8010246c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010246f:	89 04 24             	mov    %eax,(%esp)
80102472:	e8 a0 dd ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80102477:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010247a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010247e:	8b 45 08             	mov    0x8(%ebp),%eax
80102481:	89 04 24             	mov    %eax,(%esp)
80102484:	e8 e3 00 00 00       	call   8010256c <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80102489:	c9                   	leave  
8010248a:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010248b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010248e:	89 04 24             	mov    %eax,(%esp)
80102491:	e8 81 dd ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80102496:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010249a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010249d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801024a0:	39 c2                	cmp    %eax,%edx
801024a2:	0f 82 5a ff ff ff    	jb     80102402 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801024a8:	c7 04 24 50 97 10 80 	movl   $0x80109750,(%esp)
801024af:	e8 89 e0 ff ff       	call   8010053d <panic>

801024b4 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801024b4:	55                   	push   %ebp
801024b5:	89 e5                	mov    %esp,%ebp
801024b7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801024ba:	8b 45 08             	mov    0x8(%ebp),%eax
801024bd:	8b 40 04             	mov    0x4(%eax),%eax
801024c0:	c1 e8 03             	shr    $0x3,%eax
801024c3:	8d 50 02             	lea    0x2(%eax),%edx
801024c6:	8b 45 08             	mov    0x8(%ebp),%eax
801024c9:	8b 00                	mov    (%eax),%eax
801024cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801024cf:	89 04 24             	mov    %eax,(%esp)
801024d2:	e8 cf dc ff ff       	call   801001a6 <bread>
801024d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801024da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024dd:	8d 50 18             	lea    0x18(%eax),%edx
801024e0:	8b 45 08             	mov    0x8(%ebp),%eax
801024e3:	8b 40 04             	mov    0x4(%eax),%eax
801024e6:	83 e0 07             	and    $0x7,%eax
801024e9:	c1 e0 06             	shl    $0x6,%eax
801024ec:	01 d0                	add    %edx,%eax
801024ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801024f1:	8b 45 08             	mov    0x8(%ebp),%eax
801024f4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801024f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024fb:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801024fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102501:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80102505:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102508:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010250c:	8b 45 08             	mov    0x8(%ebp),%eax
8010250f:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80102513:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102516:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010251a:	8b 45 08             	mov    0x8(%ebp),%eax
8010251d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102521:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102524:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80102528:	8b 45 08             	mov    0x8(%ebp),%eax
8010252b:	8b 50 18             	mov    0x18(%eax),%edx
8010252e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102531:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80102534:	8b 45 08             	mov    0x8(%ebp),%eax
80102537:	8d 50 1c             	lea    0x1c(%eax),%edx
8010253a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010253d:	83 c0 0c             	add    $0xc,%eax
80102540:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80102547:	00 
80102548:	89 54 24 04          	mov    %edx,0x4(%esp)
8010254c:	89 04 24             	mov    %eax,(%esp)
8010254f:	e8 d5 3b 00 00       	call   80106129 <memmove>
  log_write(bp);
80102554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102557:	89 04 24             	mov    %eax,(%esp)
8010255a:	e8 c3 1f 00 00       	call   80104522 <log_write>
  brelse(bp);
8010255f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102562:	89 04 24             	mov    %eax,(%esp)
80102565:	e8 ad dc ff ff       	call   80100217 <brelse>
}
8010256a:	c9                   	leave  
8010256b:	c3                   	ret    

8010256c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010256c:	55                   	push   %ebp
8010256d:	89 e5                	mov    %esp,%ebp
8010256f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80102572:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102579:	e8 89 38 00 00       	call   80105e07 <acquire>

  // Is the inode already cached?
  empty = 0;
8010257e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102585:	c7 45 f4 d4 f8 10 80 	movl   $0x8010f8d4,-0xc(%ebp)
8010258c:	eb 59                	jmp    801025e7 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010258e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102591:	8b 40 08             	mov    0x8(%eax),%eax
80102594:	85 c0                	test   %eax,%eax
80102596:	7e 35                	jle    801025cd <iget+0x61>
80102598:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010259b:	8b 00                	mov    (%eax),%eax
8010259d:	3b 45 08             	cmp    0x8(%ebp),%eax
801025a0:	75 2b                	jne    801025cd <iget+0x61>
801025a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a5:	8b 40 04             	mov    0x4(%eax),%eax
801025a8:	3b 45 0c             	cmp    0xc(%ebp),%eax
801025ab:	75 20                	jne    801025cd <iget+0x61>
      ip->ref++;
801025ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b0:	8b 40 08             	mov    0x8(%eax),%eax
801025b3:	8d 50 01             	lea    0x1(%eax),%edx
801025b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b9:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801025bc:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801025c3:	e8 a1 38 00 00       	call   80105e69 <release>
      return ip;
801025c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025cb:	eb 6f                	jmp    8010263c <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801025cd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801025d1:	75 10                	jne    801025e3 <iget+0x77>
801025d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025d6:	8b 40 08             	mov    0x8(%eax),%eax
801025d9:	85 c0                	test   %eax,%eax
801025db:	75 06                	jne    801025e3 <iget+0x77>
      empty = ip;
801025dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025e0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801025e3:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801025e7:	81 7d f4 74 08 11 80 	cmpl   $0x80110874,-0xc(%ebp)
801025ee:	72 9e                	jb     8010258e <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801025f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801025f4:	75 0c                	jne    80102602 <iget+0x96>
    panic("iget: no inodes");
801025f6:	c7 04 24 62 97 10 80 	movl   $0x80109762,(%esp)
801025fd:	e8 3b df ff ff       	call   8010053d <panic>

  ip = empty;
80102602:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102605:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80102608:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010260b:	8b 55 08             	mov    0x8(%ebp),%edx
8010260e:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80102610:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102613:	8b 55 0c             	mov    0xc(%ebp),%edx
80102616:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80102619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010261c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80102623:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102626:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
8010262d:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102634:	e8 30 38 00 00       	call   80105e69 <release>

  return ip;
80102639:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010263c:	c9                   	leave  
8010263d:	c3                   	ret    

8010263e <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010263e:	55                   	push   %ebp
8010263f:	89 e5                	mov    %esp,%ebp
80102641:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102644:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010264b:	e8 b7 37 00 00       	call   80105e07 <acquire>
  ip->ref++;
80102650:	8b 45 08             	mov    0x8(%ebp),%eax
80102653:	8b 40 08             	mov    0x8(%eax),%eax
80102656:	8d 50 01             	lea    0x1(%eax),%edx
80102659:	8b 45 08             	mov    0x8(%ebp),%eax
8010265c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010265f:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102666:	e8 fe 37 00 00       	call   80105e69 <release>
  return ip;
8010266b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010266e:	c9                   	leave  
8010266f:	c3                   	ret    

80102670 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80102670:	55                   	push   %ebp
80102671:	89 e5                	mov    %esp,%ebp
80102673:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80102676:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010267a:	74 0a                	je     80102686 <ilock+0x16>
8010267c:	8b 45 08             	mov    0x8(%ebp),%eax
8010267f:	8b 40 08             	mov    0x8(%eax),%eax
80102682:	85 c0                	test   %eax,%eax
80102684:	7f 0c                	jg     80102692 <ilock+0x22>
    panic("ilock");
80102686:	c7 04 24 72 97 10 80 	movl   $0x80109772,(%esp)
8010268d:	e8 ab de ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102692:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102699:	e8 69 37 00 00       	call   80105e07 <acquire>
  while(ip->flags & I_BUSY)
8010269e:	eb 13                	jmp    801026b3 <ilock+0x43>
    sleep(ip, &icache.lock);
801026a0:	c7 44 24 04 a0 f8 10 	movl   $0x8010f8a0,0x4(%esp)
801026a7:	80 
801026a8:	8b 45 08             	mov    0x8(%ebp),%eax
801026ab:	89 04 24             	mov    %eax,(%esp)
801026ae:	e8 76 34 00 00       	call   80105b29 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801026b3:	8b 45 08             	mov    0x8(%ebp),%eax
801026b6:	8b 40 0c             	mov    0xc(%eax),%eax
801026b9:	83 e0 01             	and    $0x1,%eax
801026bc:	84 c0                	test   %al,%al
801026be:	75 e0                	jne    801026a0 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801026c0:	8b 45 08             	mov    0x8(%ebp),%eax
801026c3:	8b 40 0c             	mov    0xc(%eax),%eax
801026c6:	89 c2                	mov    %eax,%edx
801026c8:	83 ca 01             	or     $0x1,%edx
801026cb:	8b 45 08             	mov    0x8(%ebp),%eax
801026ce:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801026d1:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801026d8:	e8 8c 37 00 00       	call   80105e69 <release>

  if(!(ip->flags & I_VALID)){
801026dd:	8b 45 08             	mov    0x8(%ebp),%eax
801026e0:	8b 40 0c             	mov    0xc(%eax),%eax
801026e3:	83 e0 02             	and    $0x2,%eax
801026e6:	85 c0                	test   %eax,%eax
801026e8:	0f 85 ce 00 00 00    	jne    801027bc <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801026ee:	8b 45 08             	mov    0x8(%ebp),%eax
801026f1:	8b 40 04             	mov    0x4(%eax),%eax
801026f4:	c1 e8 03             	shr    $0x3,%eax
801026f7:	8d 50 02             	lea    0x2(%eax),%edx
801026fa:	8b 45 08             	mov    0x8(%ebp),%eax
801026fd:	8b 00                	mov    (%eax),%eax
801026ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80102703:	89 04 24             	mov    %eax,(%esp)
80102706:	e8 9b da ff ff       	call   801001a6 <bread>
8010270b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010270e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102711:	8d 50 18             	lea    0x18(%eax),%edx
80102714:	8b 45 08             	mov    0x8(%ebp),%eax
80102717:	8b 40 04             	mov    0x4(%eax),%eax
8010271a:	83 e0 07             	and    $0x7,%eax
8010271d:	c1 e0 06             	shl    $0x6,%eax
80102720:	01 d0                	add    %edx,%eax
80102722:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80102725:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102728:	0f b7 10             	movzwl (%eax),%edx
8010272b:	8b 45 08             	mov    0x8(%ebp),%eax
8010272e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80102732:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102735:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80102739:	8b 45 08             	mov    0x8(%ebp),%eax
8010273c:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80102740:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102743:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80102747:	8b 45 08             	mov    0x8(%ebp),%eax
8010274a:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
8010274e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102751:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80102755:	8b 45 08             	mov    0x8(%ebp),%eax
80102758:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
8010275c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010275f:	8b 50 08             	mov    0x8(%eax),%edx
80102762:	8b 45 08             	mov    0x8(%ebp),%eax
80102765:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80102768:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010276b:	8d 50 0c             	lea    0xc(%eax),%edx
8010276e:	8b 45 08             	mov    0x8(%ebp),%eax
80102771:	83 c0 1c             	add    $0x1c,%eax
80102774:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010277b:	00 
8010277c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102780:	89 04 24             	mov    %eax,(%esp)
80102783:	e8 a1 39 00 00       	call   80106129 <memmove>
    brelse(bp);
80102788:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010278b:	89 04 24             	mov    %eax,(%esp)
8010278e:	e8 84 da ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80102793:	8b 45 08             	mov    0x8(%ebp),%eax
80102796:	8b 40 0c             	mov    0xc(%eax),%eax
80102799:	89 c2                	mov    %eax,%edx
8010279b:	83 ca 02             	or     $0x2,%edx
8010279e:	8b 45 08             	mov    0x8(%ebp),%eax
801027a1:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801027a4:	8b 45 08             	mov    0x8(%ebp),%eax
801027a7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027ab:	66 85 c0             	test   %ax,%ax
801027ae:	75 0c                	jne    801027bc <ilock+0x14c>
      panic("ilock: no type");
801027b0:	c7 04 24 78 97 10 80 	movl   $0x80109778,(%esp)
801027b7:	e8 81 dd ff ff       	call   8010053d <panic>
  }
}
801027bc:	c9                   	leave  
801027bd:	c3                   	ret    

801027be <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801027be:	55                   	push   %ebp
801027bf:	89 e5                	mov    %esp,%ebp
801027c1:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801027c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801027c8:	74 17                	je     801027e1 <iunlock+0x23>
801027ca:	8b 45 08             	mov    0x8(%ebp),%eax
801027cd:	8b 40 0c             	mov    0xc(%eax),%eax
801027d0:	83 e0 01             	and    $0x1,%eax
801027d3:	85 c0                	test   %eax,%eax
801027d5:	74 0a                	je     801027e1 <iunlock+0x23>
801027d7:	8b 45 08             	mov    0x8(%ebp),%eax
801027da:	8b 40 08             	mov    0x8(%eax),%eax
801027dd:	85 c0                	test   %eax,%eax
801027df:	7f 0c                	jg     801027ed <iunlock+0x2f>
    panic("iunlock");
801027e1:	c7 04 24 87 97 10 80 	movl   $0x80109787,(%esp)
801027e8:	e8 50 dd ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801027ed:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801027f4:	e8 0e 36 00 00       	call   80105e07 <acquire>
  ip->flags &= ~I_BUSY;
801027f9:	8b 45 08             	mov    0x8(%ebp),%eax
801027fc:	8b 40 0c             	mov    0xc(%eax),%eax
801027ff:	89 c2                	mov    %eax,%edx
80102801:	83 e2 fe             	and    $0xfffffffe,%edx
80102804:	8b 45 08             	mov    0x8(%ebp),%eax
80102807:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
8010280a:	8b 45 08             	mov    0x8(%ebp),%eax
8010280d:	89 04 24             	mov    %eax,(%esp)
80102810:	e8 ed 33 00 00       	call   80105c02 <wakeup>
  release(&icache.lock);
80102815:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010281c:	e8 48 36 00 00       	call   80105e69 <release>
}
80102821:	c9                   	leave  
80102822:	c3                   	ret    

80102823 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80102823:	55                   	push   %ebp
80102824:	89 e5                	mov    %esp,%ebp
80102826:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102829:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102830:	e8 d2 35 00 00       	call   80105e07 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80102835:	8b 45 08             	mov    0x8(%ebp),%eax
80102838:	8b 40 08             	mov    0x8(%eax),%eax
8010283b:	83 f8 01             	cmp    $0x1,%eax
8010283e:	0f 85 93 00 00 00    	jne    801028d7 <iput+0xb4>
80102844:	8b 45 08             	mov    0x8(%ebp),%eax
80102847:	8b 40 0c             	mov    0xc(%eax),%eax
8010284a:	83 e0 02             	and    $0x2,%eax
8010284d:	85 c0                	test   %eax,%eax
8010284f:	0f 84 82 00 00 00    	je     801028d7 <iput+0xb4>
80102855:	8b 45 08             	mov    0x8(%ebp),%eax
80102858:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010285c:	66 85 c0             	test   %ax,%ax
8010285f:	75 76                	jne    801028d7 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80102861:	8b 45 08             	mov    0x8(%ebp),%eax
80102864:	8b 40 0c             	mov    0xc(%eax),%eax
80102867:	83 e0 01             	and    $0x1,%eax
8010286a:	84 c0                	test   %al,%al
8010286c:	74 0c                	je     8010287a <iput+0x57>
      panic("iput busy");
8010286e:	c7 04 24 8f 97 10 80 	movl   $0x8010978f,(%esp)
80102875:	e8 c3 dc ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
8010287a:	8b 45 08             	mov    0x8(%ebp),%eax
8010287d:	8b 40 0c             	mov    0xc(%eax),%eax
80102880:	89 c2                	mov    %eax,%edx
80102882:	83 ca 01             	or     $0x1,%edx
80102885:	8b 45 08             	mov    0x8(%ebp),%eax
80102888:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
8010288b:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102892:	e8 d2 35 00 00       	call   80105e69 <release>
    itrunc(ip);
80102897:	8b 45 08             	mov    0x8(%ebp),%eax
8010289a:	89 04 24             	mov    %eax,(%esp)
8010289d:	e8 72 01 00 00       	call   80102a14 <itrunc>
    ip->type = 0;
801028a2:	8b 45 08             	mov    0x8(%ebp),%eax
801028a5:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
801028ab:	8b 45 08             	mov    0x8(%ebp),%eax
801028ae:	89 04 24             	mov    %eax,(%esp)
801028b1:	e8 fe fb ff ff       	call   801024b4 <iupdate>
    acquire(&icache.lock);
801028b6:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801028bd:	e8 45 35 00 00       	call   80105e07 <acquire>
    ip->flags = 0;
801028c2:	8b 45 08             	mov    0x8(%ebp),%eax
801028c5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
801028cc:	8b 45 08             	mov    0x8(%ebp),%eax
801028cf:	89 04 24             	mov    %eax,(%esp)
801028d2:	e8 2b 33 00 00       	call   80105c02 <wakeup>
  }
  ip->ref--;
801028d7:	8b 45 08             	mov    0x8(%ebp),%eax
801028da:	8b 40 08             	mov    0x8(%eax),%eax
801028dd:	8d 50 ff             	lea    -0x1(%eax),%edx
801028e0:	8b 45 08             	mov    0x8(%ebp),%eax
801028e3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801028e6:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801028ed:	e8 77 35 00 00       	call   80105e69 <release>
}
801028f2:	c9                   	leave  
801028f3:	c3                   	ret    

801028f4 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
801028f4:	55                   	push   %ebp
801028f5:	89 e5                	mov    %esp,%ebp
801028f7:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
801028fa:	8b 45 08             	mov    0x8(%ebp),%eax
801028fd:	89 04 24             	mov    %eax,(%esp)
80102900:	e8 b9 fe ff ff       	call   801027be <iunlock>
  iput(ip);
80102905:	8b 45 08             	mov    0x8(%ebp),%eax
80102908:	89 04 24             	mov    %eax,(%esp)
8010290b:	e8 13 ff ff ff       	call   80102823 <iput>
}
80102910:	c9                   	leave  
80102911:	c3                   	ret    

80102912 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80102912:	55                   	push   %ebp
80102913:	89 e5                	mov    %esp,%ebp
80102915:	53                   	push   %ebx
80102916:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102919:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
8010291d:	77 3e                	ja     8010295d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
8010291f:	8b 45 08             	mov    0x8(%ebp),%eax
80102922:	8b 55 0c             	mov    0xc(%ebp),%edx
80102925:	83 c2 04             	add    $0x4,%edx
80102928:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010292c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010292f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102933:	75 20                	jne    80102955 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80102935:	8b 45 08             	mov    0x8(%ebp),%eax
80102938:	8b 00                	mov    (%eax),%eax
8010293a:	89 04 24             	mov    %eax,(%esp)
8010293d:	e8 49 f8 ff ff       	call   8010218b <balloc>
80102942:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102945:	8b 45 08             	mov    0x8(%ebp),%eax
80102948:	8b 55 0c             	mov    0xc(%ebp),%edx
8010294b:	8d 4a 04             	lea    0x4(%edx),%ecx
8010294e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102951:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80102955:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102958:	e9 b1 00 00 00       	jmp    80102a0e <bmap+0xfc>
  }
  bn -= NDIRECT;
8010295d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80102961:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80102965:	0f 87 97 00 00 00    	ja     80102a02 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
8010296b:	8b 45 08             	mov    0x8(%ebp),%eax
8010296e:	8b 40 4c             	mov    0x4c(%eax),%eax
80102971:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102974:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102978:	75 19                	jne    80102993 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010297a:	8b 45 08             	mov    0x8(%ebp),%eax
8010297d:	8b 00                	mov    (%eax),%eax
8010297f:	89 04 24             	mov    %eax,(%esp)
80102982:	e8 04 f8 ff ff       	call   8010218b <balloc>
80102987:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010298a:	8b 45 08             	mov    0x8(%ebp),%eax
8010298d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102990:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80102993:	8b 45 08             	mov    0x8(%ebp),%eax
80102996:	8b 00                	mov    (%eax),%eax
80102998:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010299b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010299f:	89 04 24             	mov    %eax,(%esp)
801029a2:	e8 ff d7 ff ff       	call   801001a6 <bread>
801029a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
801029aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801029ad:	83 c0 18             	add    $0x18,%eax
801029b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
801029b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801029b6:	c1 e0 02             	shl    $0x2,%eax
801029b9:	03 45 ec             	add    -0x14(%ebp),%eax
801029bc:	8b 00                	mov    (%eax),%eax
801029be:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029c1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801029c5:	75 2b                	jne    801029f2 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
801029c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801029ca:	c1 e0 02             	shl    $0x2,%eax
801029cd:	89 c3                	mov    %eax,%ebx
801029cf:	03 5d ec             	add    -0x14(%ebp),%ebx
801029d2:	8b 45 08             	mov    0x8(%ebp),%eax
801029d5:	8b 00                	mov    (%eax),%eax
801029d7:	89 04 24             	mov    %eax,(%esp)
801029da:	e8 ac f7 ff ff       	call   8010218b <balloc>
801029df:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e5:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
801029e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801029ea:	89 04 24             	mov    %eax,(%esp)
801029ed:	e8 30 1b 00 00       	call   80104522 <log_write>
    }
    brelse(bp);
801029f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801029f5:	89 04 24             	mov    %eax,(%esp)
801029f8:	e8 1a d8 ff ff       	call   80100217 <brelse>
    return addr;
801029fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a00:	eb 0c                	jmp    80102a0e <bmap+0xfc>
  }

  panic("bmap: out of range");
80102a02:	c7 04 24 99 97 10 80 	movl   $0x80109799,(%esp)
80102a09:	e8 2f db ff ff       	call   8010053d <panic>
}
80102a0e:	83 c4 24             	add    $0x24,%esp
80102a11:	5b                   	pop    %ebx
80102a12:	5d                   	pop    %ebp
80102a13:	c3                   	ret    

80102a14 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102a14:	55                   	push   %ebp
80102a15:	89 e5                	mov    %esp,%ebp
80102a17:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102a1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a21:	eb 7c                	jmp    80102a9f <itrunc+0x8b>
    if(ip->addrs[i]){
80102a23:	8b 45 08             	mov    0x8(%ebp),%eax
80102a26:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a29:	83 c2 04             	add    $0x4,%edx
80102a2c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a30:	85 c0                	test   %eax,%eax
80102a32:	74 67                	je     80102a9b <itrunc+0x87>
      if(getBlkRef(ip->addrs[i]) > 0)
80102a34:	8b 45 08             	mov    0x8(%ebp),%eax
80102a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a3a:	83 c2 04             	add    $0x4,%edx
80102a3d:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a41:	89 04 24             	mov    %eax,(%esp)
80102a44:	e8 c3 0b 00 00       	call   8010360c <getBlkRef>
80102a49:	85 c0                	test   %eax,%eax
80102a4b:	7e 1f                	jle    80102a6c <itrunc+0x58>
	updateBlkRef(ip->addrs[i],-1);
80102a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a50:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a53:	83 c2 04             	add    $0x4,%edx
80102a56:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a5a:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102a61:	ff 
80102a62:	89 04 24             	mov    %eax,(%esp)
80102a65:	e8 60 0a 00 00       	call   801034ca <updateBlkRef>
80102a6a:	eb 1e                	jmp    80102a8a <itrunc+0x76>
      else
	bfree(ip->dev, ip->addrs[i]);
80102a6c:	8b 45 08             	mov    0x8(%ebp),%eax
80102a6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a72:	83 c2 04             	add    $0x4,%edx
80102a75:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80102a79:	8b 45 08             	mov    0x8(%ebp),%eax
80102a7c:	8b 00                	mov    (%eax),%eax
80102a7e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a82:	89 04 24             	mov    %eax,(%esp)
80102a85:	e8 58 f8 ff ff       	call   801022e2 <bfree>
      ip->addrs[i] = 0;
80102a8a:	8b 45 08             	mov    0x8(%ebp),%eax
80102a8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a90:	83 c2 04             	add    $0x4,%edx
80102a93:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80102a9a:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102a9b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a9f:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102aa3:	0f 8e 7a ff ff ff    	jle    80102a23 <itrunc+0xf>
	bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80102aac:	8b 40 4c             	mov    0x4c(%eax),%eax
80102aaf:	85 c0                	test   %eax,%eax
80102ab1:	0f 84 c3 00 00 00    	je     80102b7a <itrunc+0x166>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80102aba:	8b 50 4c             	mov    0x4c(%eax),%edx
80102abd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac0:	8b 00                	mov    (%eax),%eax
80102ac2:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ac6:	89 04 24             	mov    %eax,(%esp)
80102ac9:	e8 d8 d6 ff ff       	call   801001a6 <bread>
80102ace:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102ad1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ad4:	83 c0 18             	add    $0x18,%eax
80102ad7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102ada:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102ae1:	eb 63                	jmp    80102b46 <itrunc+0x132>
      if(a[j])
80102ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ae6:	c1 e0 02             	shl    $0x2,%eax
80102ae9:	03 45 e8             	add    -0x18(%ebp),%eax
80102aec:	8b 00                	mov    (%eax),%eax
80102aee:	85 c0                	test   %eax,%eax
80102af0:	74 50                	je     80102b42 <itrunc+0x12e>
      {
	if(getBlkRef(a[j]) > 0)
80102af2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102af5:	c1 e0 02             	shl    $0x2,%eax
80102af8:	03 45 e8             	add    -0x18(%ebp),%eax
80102afb:	8b 00                	mov    (%eax),%eax
80102afd:	89 04 24             	mov    %eax,(%esp)
80102b00:	e8 07 0b 00 00       	call   8010360c <getBlkRef>
80102b05:	85 c0                	test   %eax,%eax
80102b07:	7e 1d                	jle    80102b26 <itrunc+0x112>
	  updateBlkRef(a[j],-1);
80102b09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b0c:	c1 e0 02             	shl    $0x2,%eax
80102b0f:	03 45 e8             	add    -0x18(%ebp),%eax
80102b12:	8b 00                	mov    (%eax),%eax
80102b14:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102b1b:	ff 
80102b1c:	89 04 24             	mov    %eax,(%esp)
80102b1f:	e8 a6 09 00 00       	call   801034ca <updateBlkRef>
80102b24:	eb 1c                	jmp    80102b42 <itrunc+0x12e>
	else
	  bfree(ip->dev, a[j]);
80102b26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b29:	c1 e0 02             	shl    $0x2,%eax
80102b2c:	03 45 e8             	add    -0x18(%ebp),%eax
80102b2f:	8b 10                	mov    (%eax),%edx
80102b31:	8b 45 08             	mov    0x8(%ebp),%eax
80102b34:	8b 00                	mov    (%eax),%eax
80102b36:	89 54 24 04          	mov    %edx,0x4(%esp)
80102b3a:	89 04 24             	mov    %eax,(%esp)
80102b3d:	e8 a0 f7 ff ff       	call   801022e2 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102b42:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b49:	83 f8 7f             	cmp    $0x7f,%eax
80102b4c:	76 95                	jbe    80102ae3 <itrunc+0xcf>
	  updateBlkRef(a[j],-1);
	else
	  bfree(ip->dev, a[j]);
      }
    }
    brelse(bp);
80102b4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b51:	89 04 24             	mov    %eax,(%esp)
80102b54:	e8 be d6 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102b59:	8b 45 08             	mov    0x8(%ebp),%eax
80102b5c:	8b 50 4c             	mov    0x4c(%eax),%edx
80102b5f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b62:	8b 00                	mov    (%eax),%eax
80102b64:	89 54 24 04          	mov    %edx,0x4(%esp)
80102b68:	89 04 24             	mov    %eax,(%esp)
80102b6b:	e8 72 f7 ff ff       	call   801022e2 <bfree>
    ip->addrs[NDIRECT] = 0;
80102b70:	8b 45 08             	mov    0x8(%ebp),%eax
80102b73:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80102b7d:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102b84:	8b 45 08             	mov    0x8(%ebp),%eax
80102b87:	89 04 24             	mov    %eax,(%esp)
80102b8a:	e8 25 f9 ff ff       	call   801024b4 <iupdate>
}
80102b8f:	c9                   	leave  
80102b90:	c3                   	ret    

80102b91 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102b91:	55                   	push   %ebp
80102b92:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102b94:	8b 45 08             	mov    0x8(%ebp),%eax
80102b97:	8b 00                	mov    (%eax),%eax
80102b99:	89 c2                	mov    %eax,%edx
80102b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b9e:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80102ba1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba4:	8b 50 04             	mov    0x4(%eax),%edx
80102ba7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102baa:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80102bad:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb0:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102bb4:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bb7:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102bba:	8b 45 08             	mov    0x8(%ebp),%eax
80102bbd:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102bc1:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bc4:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102bc8:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcb:	8b 50 18             	mov    0x18(%eax),%edx
80102bce:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bd1:	89 50 10             	mov    %edx,0x10(%eax)
}
80102bd4:	5d                   	pop    %ebp
80102bd5:	c3                   	ret    

80102bd6 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102bd6:	55                   	push   %ebp
80102bd7:	89 e5                	mov    %esp,%ebp
80102bd9:	53                   	push   %ebx
80102bda:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102bdd:	8b 45 08             	mov    0x8(%ebp),%eax
80102be0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102be4:	66 83 f8 03          	cmp    $0x3,%ax
80102be8:	75 60                	jne    80102c4a <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102bea:	8b 45 08             	mov    0x8(%ebp),%eax
80102bed:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102bf1:	66 85 c0             	test   %ax,%ax
80102bf4:	78 20                	js     80102c16 <readi+0x40>
80102bf6:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102bfd:	66 83 f8 09          	cmp    $0x9,%ax
80102c01:	7f 13                	jg     80102c16 <readi+0x40>
80102c03:	8b 45 08             	mov    0x8(%ebp),%eax
80102c06:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c0a:	98                   	cwtl   
80102c0b:	8b 04 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%eax
80102c12:	85 c0                	test   %eax,%eax
80102c14:	75 0a                	jne    80102c20 <readi+0x4a>
      return -1;
80102c16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c1b:	e9 1b 01 00 00       	jmp    80102d3b <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102c20:	8b 45 08             	mov    0x8(%ebp),%eax
80102c23:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c27:	98                   	cwtl   
80102c28:	8b 14 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%edx
80102c2f:	8b 45 14             	mov    0x14(%ebp),%eax
80102c32:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c36:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c39:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c3d:	8b 45 08             	mov    0x8(%ebp),%eax
80102c40:	89 04 24             	mov    %eax,(%esp)
80102c43:	ff d2                	call   *%edx
80102c45:	e9 f1 00 00 00       	jmp    80102d3b <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102c4a:	8b 45 08             	mov    0x8(%ebp),%eax
80102c4d:	8b 40 18             	mov    0x18(%eax),%eax
80102c50:	3b 45 10             	cmp    0x10(%ebp),%eax
80102c53:	72 0d                	jb     80102c62 <readi+0x8c>
80102c55:	8b 45 14             	mov    0x14(%ebp),%eax
80102c58:	8b 55 10             	mov    0x10(%ebp),%edx
80102c5b:	01 d0                	add    %edx,%eax
80102c5d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102c60:	73 0a                	jae    80102c6c <readi+0x96>
    return -1;
80102c62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c67:	e9 cf 00 00 00       	jmp    80102d3b <readi+0x165>
  if(off + n > ip->size)
80102c6c:	8b 45 14             	mov    0x14(%ebp),%eax
80102c6f:	8b 55 10             	mov    0x10(%ebp),%edx
80102c72:	01 c2                	add    %eax,%edx
80102c74:	8b 45 08             	mov    0x8(%ebp),%eax
80102c77:	8b 40 18             	mov    0x18(%eax),%eax
80102c7a:	39 c2                	cmp    %eax,%edx
80102c7c:	76 0c                	jbe    80102c8a <readi+0xb4>
    n = ip->size - off;
80102c7e:	8b 45 08             	mov    0x8(%ebp),%eax
80102c81:	8b 40 18             	mov    0x18(%eax),%eax
80102c84:	2b 45 10             	sub    0x10(%ebp),%eax
80102c87:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102c8a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c91:	e9 96 00 00 00       	jmp    80102d2c <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102c96:	8b 45 10             	mov    0x10(%ebp),%eax
80102c99:	c1 e8 09             	shr    $0x9,%eax
80102c9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ca0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca3:	89 04 24             	mov    %eax,(%esp)
80102ca6:	e8 67 fc ff ff       	call   80102912 <bmap>
80102cab:	8b 55 08             	mov    0x8(%ebp),%edx
80102cae:	8b 12                	mov    (%edx),%edx
80102cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cb4:	89 14 24             	mov    %edx,(%esp)
80102cb7:	e8 ea d4 ff ff       	call   801001a6 <bread>
80102cbc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102cbf:	8b 45 10             	mov    0x10(%ebp),%eax
80102cc2:	89 c2                	mov    %eax,%edx
80102cc4:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102cca:	b8 00 02 00 00       	mov    $0x200,%eax
80102ccf:	89 c1                	mov    %eax,%ecx
80102cd1:	29 d1                	sub    %edx,%ecx
80102cd3:	89 ca                	mov    %ecx,%edx
80102cd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cd8:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102cdb:	89 cb                	mov    %ecx,%ebx
80102cdd:	29 c3                	sub    %eax,%ebx
80102cdf:	89 d8                	mov    %ebx,%eax
80102ce1:	39 c2                	cmp    %eax,%edx
80102ce3:	0f 46 c2             	cmovbe %edx,%eax
80102ce6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102ce9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102cec:	8d 50 18             	lea    0x18(%eax),%edx
80102cef:	8b 45 10             	mov    0x10(%ebp),%eax
80102cf2:	25 ff 01 00 00       	and    $0x1ff,%eax
80102cf7:	01 c2                	add    %eax,%edx
80102cf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102cfc:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d00:	89 54 24 04          	mov    %edx,0x4(%esp)
80102d04:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d07:	89 04 24             	mov    %eax,(%esp)
80102d0a:	e8 1a 34 00 00       	call   80106129 <memmove>
    brelse(bp);
80102d0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d12:	89 04 24             	mov    %eax,(%esp)
80102d15:	e8 fd d4 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102d1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d1d:	01 45 f4             	add    %eax,-0xc(%ebp)
80102d20:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d23:	01 45 10             	add    %eax,0x10(%ebp)
80102d26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d29:	01 45 0c             	add    %eax,0xc(%ebp)
80102d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d2f:	3b 45 14             	cmp    0x14(%ebp),%eax
80102d32:	0f 82 5e ff ff ff    	jb     80102c96 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102d38:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102d3b:	83 c4 24             	add    $0x24,%esp
80102d3e:	5b                   	pop    %ebx
80102d3f:	5d                   	pop    %ebp
80102d40:	c3                   	ret    

80102d41 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102d41:	55                   	push   %ebp
80102d42:	89 e5                	mov    %esp,%ebp
80102d44:	53                   	push   %ebx
80102d45:	83 ec 34             	sub    $0x34,%esp
  uint tot, m,ref;
  struct buf *bp;

  if(ip->type == T_DEV){
80102d48:	8b 45 08             	mov    0x8(%ebp),%eax
80102d4b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102d4f:	66 83 f8 03          	cmp    $0x3,%ax
80102d53:	75 60                	jne    80102db5 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102d55:	8b 45 08             	mov    0x8(%ebp),%eax
80102d58:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d5c:	66 85 c0             	test   %ax,%ax
80102d5f:	78 20                	js     80102d81 <writei+0x40>
80102d61:	8b 45 08             	mov    0x8(%ebp),%eax
80102d64:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d68:	66 83 f8 09          	cmp    $0x9,%ax
80102d6c:	7f 13                	jg     80102d81 <writei+0x40>
80102d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80102d71:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d75:	98                   	cwtl   
80102d76:	8b 04 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%eax
80102d7d:	85 c0                	test   %eax,%eax
80102d7f:	75 0a                	jne    80102d8b <writei+0x4a>
      return -1;
80102d81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d86:	e9 e5 01 00 00       	jmp    80102f70 <writei+0x22f>
    return devsw[ip->major].write(ip, src, n);
80102d8b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d8e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d92:	98                   	cwtl   
80102d93:	8b 14 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%edx
80102d9a:	8b 45 14             	mov    0x14(%ebp),%eax
80102d9d:	89 44 24 08          	mov    %eax,0x8(%esp)
80102da1:	8b 45 0c             	mov    0xc(%ebp),%eax
80102da4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102da8:	8b 45 08             	mov    0x8(%ebp),%eax
80102dab:	89 04 24             	mov    %eax,(%esp)
80102dae:	ff d2                	call   *%edx
80102db0:	e9 bb 01 00 00       	jmp    80102f70 <writei+0x22f>
  }

  if(off > ip->size || off + n < off)
80102db5:	8b 45 08             	mov    0x8(%ebp),%eax
80102db8:	8b 40 18             	mov    0x18(%eax),%eax
80102dbb:	3b 45 10             	cmp    0x10(%ebp),%eax
80102dbe:	72 0d                	jb     80102dcd <writei+0x8c>
80102dc0:	8b 45 14             	mov    0x14(%ebp),%eax
80102dc3:	8b 55 10             	mov    0x10(%ebp),%edx
80102dc6:	01 d0                	add    %edx,%eax
80102dc8:	3b 45 10             	cmp    0x10(%ebp),%eax
80102dcb:	73 0a                	jae    80102dd7 <writei+0x96>
    return -1;
80102dcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102dd2:	e9 99 01 00 00       	jmp    80102f70 <writei+0x22f>
  if(off + n > MAXFILE*BSIZE)
80102dd7:	8b 45 14             	mov    0x14(%ebp),%eax
80102dda:	8b 55 10             	mov    0x10(%ebp),%edx
80102ddd:	01 d0                	add    %edx,%eax
80102ddf:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102de4:	76 0a                	jbe    80102df0 <writei+0xaf>
    return -1;
80102de6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102deb:	e9 80 01 00 00       	jmp    80102f70 <writei+0x22f>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102df0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102df7:	e9 40 01 00 00       	jmp    80102f3c <writei+0x1fb>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102dfc:	8b 45 10             	mov    0x10(%ebp),%eax
80102dff:	c1 e8 09             	shr    $0x9,%eax
80102e02:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e06:	8b 45 08             	mov    0x8(%ebp),%eax
80102e09:	89 04 24             	mov    %eax,(%esp)
80102e0c:	e8 01 fb ff ff       	call   80102912 <bmap>
80102e11:	8b 55 08             	mov    0x8(%ebp),%edx
80102e14:	8b 12                	mov    (%edx),%edx
80102e16:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e1a:	89 14 24             	mov    %edx,(%esp)
80102e1d:	e8 84 d3 ff ff       	call   801001a6 <bread>
80102e22:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((ref = getBlkRef(bp->sector)) > 0)
80102e25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e28:	8b 40 08             	mov    0x8(%eax),%eax
80102e2b:	89 04 24             	mov    %eax,(%esp)
80102e2e:	e8 d9 07 00 00       	call   8010360c <getBlkRef>
80102e33:	89 45 ec             	mov    %eax,-0x14(%ebp)
80102e36:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102e3a:	0f 84 84 00 00 00    	je     80102ec4 <writei+0x183>
    {cprintf ("block = %d, ref = %d\n",bp->sector,ref);
80102e40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e43:	8b 40 08             	mov    0x8(%eax),%eax
80102e46:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102e49:	89 54 24 08          	mov    %edx,0x8(%esp)
80102e4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e51:	c7 04 24 ac 97 10 80 	movl   $0x801097ac,(%esp)
80102e58:	e8 44 d5 ff ff       	call   801003a1 <cprintf>
      uint old = bp->sector;
80102e5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e60:	8b 40 08             	mov    0x8(%eax),%eax
80102e63:	89 45 e8             	mov    %eax,-0x18(%ebp)
      updateBlkRef(old,-1);
80102e66:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102e6d:	ff 
80102e6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102e71:	89 04 24             	mov    %eax,(%esp)
80102e74:	e8 51 06 00 00       	call   801034ca <updateBlkRef>
      brelse(bp);
80102e79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e7c:	89 04 24             	mov    %eax,(%esp)
80102e7f:	e8 93 d3 ff ff       	call   80100217 <brelse>
      uint new = balloc(ip->dev);
80102e84:	8b 45 08             	mov    0x8(%ebp),%eax
80102e87:	8b 00                	mov    (%eax),%eax
80102e89:	89 04 24             	mov    %eax,(%esp)
80102e8c:	e8 fa f2 ff ff       	call   8010218b <balloc>
80102e91:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      replaceBlk(ip,old,new);
80102e94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e97:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e9b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102e9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ea2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ea5:	89 04 24             	mov    %eax,(%esp)
80102ea8:	e8 7f f1 ff ff       	call   8010202c <replaceBlk>
      bp = bread(ip->dev,new);
80102ead:	8b 45 08             	mov    0x8(%ebp),%eax
80102eb0:	8b 00                	mov    (%eax),%eax
80102eb2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102eb5:	89 54 24 04          	mov    %edx,0x4(%esp)
80102eb9:	89 04 24             	mov    %eax,(%esp)
80102ebc:	e8 e5 d2 ff ff       	call   801001a6 <bread>
80102ec1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    m = min(n - tot, BSIZE - off%BSIZE);
80102ec4:	8b 45 10             	mov    0x10(%ebp),%eax
80102ec7:	89 c2                	mov    %eax,%edx
80102ec9:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102ecf:	b8 00 02 00 00       	mov    $0x200,%eax
80102ed4:	89 c1                	mov    %eax,%ecx
80102ed6:	29 d1                	sub    %edx,%ecx
80102ed8:	89 ca                	mov    %ecx,%edx
80102eda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102edd:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102ee0:	89 cb                	mov    %ecx,%ebx
80102ee2:	29 c3                	sub    %eax,%ebx
80102ee4:	89 d8                	mov    %ebx,%eax
80102ee6:	39 c2                	cmp    %eax,%edx
80102ee8:	0f 46 c2             	cmovbe %edx,%eax
80102eeb:	89 45 e0             	mov    %eax,-0x20(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102eee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ef1:	8d 50 18             	lea    0x18(%eax),%edx
80102ef4:	8b 45 10             	mov    0x10(%ebp),%eax
80102ef7:	25 ff 01 00 00       	and    $0x1ff,%eax
80102efc:	01 c2                	add    %eax,%edx
80102efe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f01:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f05:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f08:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f0c:	89 14 24             	mov    %edx,(%esp)
80102f0f:	e8 15 32 00 00       	call   80106129 <memmove>
    log_write(bp);
80102f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f17:	89 04 24             	mov    %eax,(%esp)
80102f1a:	e8 03 16 00 00       	call   80104522 <log_write>
    brelse(bp);
80102f1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f22:	89 04 24             	mov    %eax,(%esp)
80102f25:	e8 ed d2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102f2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f2d:	01 45 f4             	add    %eax,-0xc(%ebp)
80102f30:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f33:	01 45 10             	add    %eax,0x10(%ebp)
80102f36:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f39:	01 45 0c             	add    %eax,0xc(%ebp)
80102f3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f3f:	3b 45 14             	cmp    0x14(%ebp),%eax
80102f42:	0f 82 b4 fe ff ff    	jb     80102dfc <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102f48:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102f4c:	74 1f                	je     80102f6d <writei+0x22c>
80102f4e:	8b 45 08             	mov    0x8(%ebp),%eax
80102f51:	8b 40 18             	mov    0x18(%eax),%eax
80102f54:	3b 45 10             	cmp    0x10(%ebp),%eax
80102f57:	73 14                	jae    80102f6d <writei+0x22c>
    ip->size = off;
80102f59:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5c:	8b 55 10             	mov    0x10(%ebp),%edx
80102f5f:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102f62:	8b 45 08             	mov    0x8(%ebp),%eax
80102f65:	89 04 24             	mov    %eax,(%esp)
80102f68:	e8 47 f5 ff ff       	call   801024b4 <iupdate>
  }
  return n;
80102f6d:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102f70:	83 c4 34             	add    $0x34,%esp
80102f73:	5b                   	pop    %ebx
80102f74:	5d                   	pop    %ebp
80102f75:	c3                   	ret    

80102f76 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102f76:	55                   	push   %ebp
80102f77:	89 e5                	mov    %esp,%ebp
80102f79:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102f7c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102f83:	00 
80102f84:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f87:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80102f8e:	89 04 24             	mov    %eax,(%esp)
80102f91:	e8 37 32 00 00       	call   801061cd <strncmp>
}
80102f96:	c9                   	leave  
80102f97:	c3                   	ret    

80102f98 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102f98:	55                   	push   %ebp
80102f99:	89 e5                	mov    %esp,%ebp
80102f9b:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102f9e:	8b 45 08             	mov    0x8(%ebp),%eax
80102fa1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102fa5:	66 83 f8 01          	cmp    $0x1,%ax
80102fa9:	74 0c                	je     80102fb7 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102fab:	c7 04 24 c2 97 10 80 	movl   $0x801097c2,(%esp)
80102fb2:	e8 86 d5 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102fb7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102fbe:	e9 87 00 00 00       	jmp    8010304a <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102fc3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102fca:	00 
80102fcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fce:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fd2:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102fd5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fd9:	8b 45 08             	mov    0x8(%ebp),%eax
80102fdc:	89 04 24             	mov    %eax,(%esp)
80102fdf:	e8 f2 fb ff ff       	call   80102bd6 <readi>
80102fe4:	83 f8 10             	cmp    $0x10,%eax
80102fe7:	74 0c                	je     80102ff5 <dirlookup+0x5d>
      panic("dirlink read");
80102fe9:	c7 04 24 d4 97 10 80 	movl   $0x801097d4,(%esp)
80102ff0:	e8 48 d5 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102ff5:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102ff9:	66 85 c0             	test   %ax,%ax
80102ffc:	74 47                	je     80103045 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102ffe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103001:	83 c0 02             	add    $0x2,%eax
80103004:	89 44 24 04          	mov    %eax,0x4(%esp)
80103008:	8b 45 0c             	mov    0xc(%ebp),%eax
8010300b:	89 04 24             	mov    %eax,(%esp)
8010300e:	e8 63 ff ff ff       	call   80102f76 <namecmp>
80103013:	85 c0                	test   %eax,%eax
80103015:	75 2f                	jne    80103046 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80103017:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010301b:	74 08                	je     80103025 <dirlookup+0x8d>
        *poff = off;
8010301d:	8b 45 10             	mov    0x10(%ebp),%eax
80103020:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103023:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80103025:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80103029:	0f b7 c0             	movzwl %ax,%eax
8010302c:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
8010302f:	8b 45 08             	mov    0x8(%ebp),%eax
80103032:	8b 00                	mov    (%eax),%eax
80103034:	8b 55 f0             	mov    -0x10(%ebp),%edx
80103037:	89 54 24 04          	mov    %edx,0x4(%esp)
8010303b:	89 04 24             	mov    %eax,(%esp)
8010303e:	e8 29 f5 ff ff       	call   8010256c <iget>
80103043:	eb 19                	jmp    8010305e <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80103045:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80103046:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010304a:	8b 45 08             	mov    0x8(%ebp),%eax
8010304d:	8b 40 18             	mov    0x18(%eax),%eax
80103050:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103053:	0f 87 6a ff ff ff    	ja     80102fc3 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80103059:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010305e:	c9                   	leave  
8010305f:	c3                   	ret    

80103060 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80103060:	55                   	push   %ebp
80103061:	89 e5                	mov    %esp,%ebp
80103063:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80103066:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010306d:	00 
8010306e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103071:	89 44 24 04          	mov    %eax,0x4(%esp)
80103075:	8b 45 08             	mov    0x8(%ebp),%eax
80103078:	89 04 24             	mov    %eax,(%esp)
8010307b:	e8 18 ff ff ff       	call   80102f98 <dirlookup>
80103080:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103083:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103087:	74 15                	je     8010309e <dirlink+0x3e>
    iput(ip);
80103089:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010308c:	89 04 24             	mov    %eax,(%esp)
8010308f:	e8 8f f7 ff ff       	call   80102823 <iput>
    return -1;
80103094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103099:	e9 b8 00 00 00       	jmp    80103156 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010309e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030a5:	eb 44                	jmp    801030eb <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801030a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030aa:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801030b1:	00 
801030b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801030b6:	8d 45 e0             	lea    -0x20(%ebp),%eax
801030b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801030bd:	8b 45 08             	mov    0x8(%ebp),%eax
801030c0:	89 04 24             	mov    %eax,(%esp)
801030c3:	e8 0e fb ff ff       	call   80102bd6 <readi>
801030c8:	83 f8 10             	cmp    $0x10,%eax
801030cb:	74 0c                	je     801030d9 <dirlink+0x79>
      panic("dirlink read");
801030cd:	c7 04 24 d4 97 10 80 	movl   $0x801097d4,(%esp)
801030d4:	e8 64 d4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801030d9:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801030dd:	66 85 c0             	test   %ax,%ax
801030e0:	74 18                	je     801030fa <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801030e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030e5:	83 c0 10             	add    $0x10,%eax
801030e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801030eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801030ee:	8b 45 08             	mov    0x8(%ebp),%eax
801030f1:	8b 40 18             	mov    0x18(%eax),%eax
801030f4:	39 c2                	cmp    %eax,%edx
801030f6:	72 af                	jb     801030a7 <dirlink+0x47>
801030f8:	eb 01                	jmp    801030fb <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
801030fa:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
801030fb:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103102:	00 
80103103:	8b 45 0c             	mov    0xc(%ebp),%eax
80103106:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010310d:	83 c0 02             	add    $0x2,%eax
80103110:	89 04 24             	mov    %eax,(%esp)
80103113:	e8 0d 31 00 00       	call   80106225 <strncpy>
  de.inum = inum;
80103118:	8b 45 10             	mov    0x10(%ebp),%eax
8010311b:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010311f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103122:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80103129:	00 
8010312a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010312e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103131:	89 44 24 04          	mov    %eax,0x4(%esp)
80103135:	8b 45 08             	mov    0x8(%ebp),%eax
80103138:	89 04 24             	mov    %eax,(%esp)
8010313b:	e8 01 fc ff ff       	call   80102d41 <writei>
80103140:	83 f8 10             	cmp    $0x10,%eax
80103143:	74 0c                	je     80103151 <dirlink+0xf1>
    panic("dirlink");
80103145:	c7 04 24 e1 97 10 80 	movl   $0x801097e1,(%esp)
8010314c:	e8 ec d3 ff ff       	call   8010053d <panic>
  
  return 0;
80103151:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103156:	c9                   	leave  
80103157:	c3                   	ret    

80103158 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80103158:	55                   	push   %ebp
80103159:	89 e5                	mov    %esp,%ebp
8010315b:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010315e:	eb 04                	jmp    80103164 <skipelem+0xc>
    path++;
80103160:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80103164:	8b 45 08             	mov    0x8(%ebp),%eax
80103167:	0f b6 00             	movzbl (%eax),%eax
8010316a:	3c 2f                	cmp    $0x2f,%al
8010316c:	74 f2                	je     80103160 <skipelem+0x8>
    path++;
  if(*path == 0)
8010316e:	8b 45 08             	mov    0x8(%ebp),%eax
80103171:	0f b6 00             	movzbl (%eax),%eax
80103174:	84 c0                	test   %al,%al
80103176:	75 0a                	jne    80103182 <skipelem+0x2a>
    return 0;
80103178:	b8 00 00 00 00       	mov    $0x0,%eax
8010317d:	e9 86 00 00 00       	jmp    80103208 <skipelem+0xb0>
  s = path;
80103182:	8b 45 08             	mov    0x8(%ebp),%eax
80103185:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80103188:	eb 04                	jmp    8010318e <skipelem+0x36>
    path++;
8010318a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010318e:	8b 45 08             	mov    0x8(%ebp),%eax
80103191:	0f b6 00             	movzbl (%eax),%eax
80103194:	3c 2f                	cmp    $0x2f,%al
80103196:	74 0a                	je     801031a2 <skipelem+0x4a>
80103198:	8b 45 08             	mov    0x8(%ebp),%eax
8010319b:	0f b6 00             	movzbl (%eax),%eax
8010319e:	84 c0                	test   %al,%al
801031a0:	75 e8                	jne    8010318a <skipelem+0x32>
    path++;
  len = path - s;
801031a2:	8b 55 08             	mov    0x8(%ebp),%edx
801031a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031a8:	89 d1                	mov    %edx,%ecx
801031aa:	29 c1                	sub    %eax,%ecx
801031ac:	89 c8                	mov    %ecx,%eax
801031ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801031b1:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801031b5:	7e 1c                	jle    801031d3 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801031b7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801031be:	00 
801031bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801031c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801031c9:	89 04 24             	mov    %eax,(%esp)
801031cc:	e8 58 2f 00 00       	call   80106129 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801031d1:	eb 28                	jmp    801031fb <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801031d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031d6:	89 44 24 08          	mov    %eax,0x8(%esp)
801031da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801031e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801031e4:	89 04 24             	mov    %eax,(%esp)
801031e7:	e8 3d 2f 00 00       	call   80106129 <memmove>
    name[len] = 0;
801031ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031ef:	03 45 0c             	add    0xc(%ebp),%eax
801031f2:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801031f5:	eb 04                	jmp    801031fb <skipelem+0xa3>
    path++;
801031f7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801031fb:	8b 45 08             	mov    0x8(%ebp),%eax
801031fe:	0f b6 00             	movzbl (%eax),%eax
80103201:	3c 2f                	cmp    $0x2f,%al
80103203:	74 f2                	je     801031f7 <skipelem+0x9f>
    path++;
  return path;
80103205:	8b 45 08             	mov    0x8(%ebp),%eax
}
80103208:	c9                   	leave  
80103209:	c3                   	ret    

8010320a <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010320a:	55                   	push   %ebp
8010320b:	89 e5                	mov    %esp,%ebp
8010320d:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80103210:	8b 45 08             	mov    0x8(%ebp),%eax
80103213:	0f b6 00             	movzbl (%eax),%eax
80103216:	3c 2f                	cmp    $0x2f,%al
80103218:	75 1c                	jne    80103236 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010321a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103221:	00 
80103222:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103229:	e8 3e f3 ff ff       	call   8010256c <iget>
8010322e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80103231:	e9 af 00 00 00       	jmp    801032e5 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80103236:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010323c:	8b 40 68             	mov    0x68(%eax),%eax
8010323f:	89 04 24             	mov    %eax,(%esp)
80103242:	e8 f7 f3 ff ff       	call   8010263e <idup>
80103247:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010324a:	e9 96 00 00 00       	jmp    801032e5 <namex+0xdb>
    ilock(ip);
8010324f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103252:	89 04 24             	mov    %eax,(%esp)
80103255:	e8 16 f4 ff ff       	call   80102670 <ilock>
    if(ip->type != T_DIR){
8010325a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010325d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80103261:	66 83 f8 01          	cmp    $0x1,%ax
80103265:	74 15                	je     8010327c <namex+0x72>
      iunlockput(ip);
80103267:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010326a:	89 04 24             	mov    %eax,(%esp)
8010326d:	e8 82 f6 ff ff       	call   801028f4 <iunlockput>
      return 0;
80103272:	b8 00 00 00 00       	mov    $0x0,%eax
80103277:	e9 a3 00 00 00       	jmp    8010331f <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
8010327c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103280:	74 1d                	je     8010329f <namex+0x95>
80103282:	8b 45 08             	mov    0x8(%ebp),%eax
80103285:	0f b6 00             	movzbl (%eax),%eax
80103288:	84 c0                	test   %al,%al
8010328a:	75 13                	jne    8010329f <namex+0x95>
      // Stop one level early.
      iunlock(ip);
8010328c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010328f:	89 04 24             	mov    %eax,(%esp)
80103292:	e8 27 f5 ff ff       	call   801027be <iunlock>
      return ip;
80103297:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010329a:	e9 80 00 00 00       	jmp    8010331f <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
8010329f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801032a6:	00 
801032a7:	8b 45 10             	mov    0x10(%ebp),%eax
801032aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801032ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b1:	89 04 24             	mov    %eax,(%esp)
801032b4:	e8 df fc ff ff       	call   80102f98 <dirlookup>
801032b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801032bc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032c0:	75 12                	jne    801032d4 <namex+0xca>
      iunlockput(ip);
801032c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c5:	89 04 24             	mov    %eax,(%esp)
801032c8:	e8 27 f6 ff ff       	call   801028f4 <iunlockput>
      return 0;
801032cd:	b8 00 00 00 00       	mov    $0x0,%eax
801032d2:	eb 4b                	jmp    8010331f <namex+0x115>
    }
    iunlockput(ip);
801032d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032d7:	89 04 24             	mov    %eax,(%esp)
801032da:	e8 15 f6 ff ff       	call   801028f4 <iunlockput>
    ip = next;
801032df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801032e5:	8b 45 10             	mov    0x10(%ebp),%eax
801032e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801032ec:	8b 45 08             	mov    0x8(%ebp),%eax
801032ef:	89 04 24             	mov    %eax,(%esp)
801032f2:	e8 61 fe ff ff       	call   80103158 <skipelem>
801032f7:	89 45 08             	mov    %eax,0x8(%ebp)
801032fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801032fe:	0f 85 4b ff ff ff    	jne    8010324f <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80103304:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103308:	74 12                	je     8010331c <namex+0x112>
    iput(ip);
8010330a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010330d:	89 04 24             	mov    %eax,(%esp)
80103310:	e8 0e f5 ff ff       	call   80102823 <iput>
    return 0;
80103315:	b8 00 00 00 00       	mov    $0x0,%eax
8010331a:	eb 03                	jmp    8010331f <namex+0x115>
  }
  return ip;
8010331c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010331f:	c9                   	leave  
80103320:	c3                   	ret    

80103321 <namei>:

struct inode*
namei(char *path)
{
80103321:	55                   	push   %ebp
80103322:	89 e5                	mov    %esp,%ebp
80103324:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80103327:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010332a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010332e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103335:	00 
80103336:	8b 45 08             	mov    0x8(%ebp),%eax
80103339:	89 04 24             	mov    %eax,(%esp)
8010333c:	e8 c9 fe ff ff       	call   8010320a <namex>
}
80103341:	c9                   	leave  
80103342:	c3                   	ret    

80103343 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80103343:	55                   	push   %ebp
80103344:	89 e5                	mov    %esp,%ebp
80103346:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80103349:	8b 45 0c             	mov    0xc(%ebp),%eax
8010334c:	89 44 24 08          	mov    %eax,0x8(%esp)
80103350:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103357:	00 
80103358:	8b 45 08             	mov    0x8(%ebp),%eax
8010335b:	89 04 24             	mov    %eax,(%esp)
8010335e:	e8 a7 fe ff ff       	call   8010320a <namex>
}
80103363:	c9                   	leave  
80103364:	c3                   	ret    

80103365 <getNextInode>:

struct inode*
getNextInode(void)
{
80103365:	55                   	push   %ebp
80103366:	89 e5                	mov    %esp,%ebp
80103368:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
8010336b:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010336e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103372:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103379:	e8 76 ed ff ff       	call   801020f4 <readsb>
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
8010337e:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103383:	83 c0 01             	add    $0x1,%eax
80103386:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103389:	eb 79                	jmp    80103404 <getNextInode+0x9f>
  {
    bp = bread(1, IBLOCK(inum));
8010338b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338e:	c1 e8 03             	shr    $0x3,%eax
80103391:	83 c0 02             	add    $0x2,%eax
80103394:	89 44 24 04          	mov    %eax,0x4(%esp)
80103398:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010339f:	e8 02 ce ff ff       	call   801001a6 <bread>
801033a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801033a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033aa:	8d 50 18             	lea    0x18(%eax),%edx
801033ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033b0:	83 e0 07             	and    $0x7,%eax
801033b3:	c1 e0 06             	shl    $0x6,%eax
801033b6:	01 d0                	add    %edx,%eax
801033b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
801033bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033be:	0f b7 00             	movzwl (%eax),%eax
801033c1:	66 83 f8 02          	cmp    $0x2,%ax
801033c5:	75 2e                	jne    801033f5 <getNextInode+0x90>
    {
      nextInum = inum;
801033c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033ca:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      //cprintf("next: nextInum = %d\n",nextInum);
      ip = iget(1,inum);
801033cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801033d6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033dd:	e8 8a f1 ff ff       	call   8010256c <iget>
801033e2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
801033e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e8:	89 04 24             	mov    %eax,(%esp)
801033eb:	e8 27 ce ff ff       	call   80100217 <brelse>
      return ip;
801033f0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801033f3:	eb 22                	jmp    80103417 <getNextInode+0xb2>
    }
    brelse(bp);
801033f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033f8:	89 04 24             	mov    %eax,(%esp)
801033fb:	e8 17 ce ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103400:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103404:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103407:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010340a:	39 c2                	cmp    %eax,%edx
8010340c:	0f 82 79 ff ff ff    	jb     8010338b <getNextInode+0x26>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
80103412:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103417:	c9                   	leave  
80103418:	c3                   	ret    

80103419 <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
80103419:	55                   	push   %ebp
8010341a:	89 e5                	mov    %esp,%ebp
8010341c:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
8010341f:	e9 8d 00 00 00       	jmp    801034b1 <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
80103424:	8b 45 08             	mov    0x8(%ebp),%eax
80103427:	8b 00                	mov    (%eax),%eax
80103429:	c1 e8 03             	shr    $0x3,%eax
8010342c:	83 c0 02             	add    $0x2,%eax
8010342f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103433:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010343a:	e8 67 cd ff ff       	call   801001a6 <bread>
8010343f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
80103442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103445:	8d 50 18             	lea    0x18(%eax),%edx
80103448:	8b 45 08             	mov    0x8(%ebp),%eax
8010344b:	8b 00                	mov    (%eax),%eax
8010344d:	83 e0 07             	and    $0x7,%eax
80103450:	c1 e0 06             	shl    $0x6,%eax
80103453:	01 d0                	add    %edx,%eax
80103455:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010345b:	0f b7 00             	movzwl (%eax),%eax
8010345e:	66 83 f8 02          	cmp    $0x2,%ax
80103462:	75 35                	jne    80103499 <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
80103464:	8b 45 08             	mov    0x8(%ebp),%eax
80103467:	8b 00                	mov    (%eax),%eax
80103469:	89 44 24 04          	mov    %eax,0x4(%esp)
8010346d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103474:	e8 f3 f0 ff ff       	call   8010256c <iget>
80103479:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
8010347c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010347f:	89 04 24             	mov    %eax,(%esp)
80103482:	e8 90 cd ff ff       	call   80100217 <brelse>
      //cprintf("prev: before --, prevInum = %d\n",*prevInum);
      (*prevInum)--;
80103487:	8b 45 08             	mov    0x8(%ebp),%eax
8010348a:	8b 00                	mov    (%eax),%eax
8010348c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010348f:	8b 45 08             	mov    0x8(%ebp),%eax
80103492:	89 10                	mov    %edx,(%eax)
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
80103494:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103497:	eb 2f                	jmp    801034c8 <getPrevInode+0xaf>
    }
    brelse(bp);
80103499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010349c:	89 04 24             	mov    %eax,(%esp)
8010349f:	e8 73 cd ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801034a4:	8b 45 08             	mov    0x8(%ebp),%eax
801034a7:	8b 00                	mov    (%eax),%eax
801034a9:	8d 50 ff             	lea    -0x1(%eax),%edx
801034ac:	8b 45 08             	mov    0x8(%ebp),%eax
801034af:	89 10                	mov    %edx,(%eax)
801034b1:	8b 45 08             	mov    0x8(%ebp),%eax
801034b4:	8b 10                	mov    (%eax),%edx
801034b6:	a1 18 c6 10 80       	mov    0x8010c618,%eax
801034bb:	39 c2                	cmp    %eax,%edx
801034bd:	0f 8f 61 ff ff ff    	jg     80103424 <getPrevInode+0xb>
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
    }
    brelse(bp);
  }
  return 0;
801034c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034c8:	c9                   	leave  
801034c9:	c3                   	ret    

801034ca <updateBlkRef>:


void
updateBlkRef(uint sector, int flag)
{
801034ca:	55                   	push   %ebp
801034cb:	89 e5                	mov    %esp,%ebp
801034cd:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  cprintf("updateblkref = %d\n",sector);
801034d0:	8b 45 08             	mov    0x8(%ebp),%eax
801034d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801034d7:	c7 04 24 e9 97 10 80 	movl   $0x801097e9,(%esp)
801034de:	e8 be ce ff ff       	call   801003a1 <cprintf>
  if(sector < 512)
801034e3:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801034ea:	0f 87 89 00 00 00    	ja     80103579 <updateBlkRef+0xaf>
  {
    bp = bread(1,1024);
801034f0:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801034f7:	00 
801034f8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034ff:	e8 a2 cc ff ff       	call   801001a6 <bread>
80103504:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103507:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
8010350b:	75 1e                	jne    8010352b <updateBlkRef+0x61>
      bp->data[sector]++;
8010350d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103510:	03 45 08             	add    0x8(%ebp),%eax
80103513:	83 c0 10             	add    $0x10,%eax
80103516:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010351a:	8d 50 01             	lea    0x1(%eax),%edx
8010351d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103520:	03 45 08             	add    0x8(%ebp),%eax
80103523:	83 c0 10             	add    $0x10,%eax
80103526:	88 50 08             	mov    %dl,0x8(%eax)
80103529:	eb 33                	jmp    8010355e <updateBlkRef+0x94>
    else if(flag == -1)
8010352b:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
8010352f:	75 2d                	jne    8010355e <updateBlkRef+0x94>
      if(bp->data[sector] > 0)
80103531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103534:	03 45 08             	add    0x8(%ebp),%eax
80103537:	83 c0 10             	add    $0x10,%eax
8010353a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010353e:	84 c0                	test   %al,%al
80103540:	74 1c                	je     8010355e <updateBlkRef+0x94>
	bp->data[sector]--;
80103542:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103545:	03 45 08             	add    0x8(%ebp),%eax
80103548:	83 c0 10             	add    $0x10,%eax
8010354b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010354f:	8d 50 ff             	lea    -0x1(%eax),%edx
80103552:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103555:	03 45 08             	add    0x8(%ebp),%eax
80103558:	83 c0 10             	add    $0x10,%eax
8010355b:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
8010355e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103561:	89 04 24             	mov    %eax,(%esp)
80103564:	e8 74 cc ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010356c:	89 04 24             	mov    %eax,(%esp)
8010356f:	e8 a3 cc ff ff       	call   80100217 <brelse>
80103574:	e9 91 00 00 00       	jmp    8010360a <updateBlkRef+0x140>
  }
  else if(sector < 1024)
80103579:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103580:	0f 87 84 00 00 00    	ja     8010360a <updateBlkRef+0x140>
  {
    bp = bread(1,1025);
80103586:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
8010358d:	00 
8010358e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103595:	e8 0c cc ff ff       	call   801001a6 <bread>
8010359a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
8010359d:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
801035a1:	75 1c                	jne    801035bf <updateBlkRef+0xf5>
      bp->data[sector-512]++;
801035a3:	8b 45 08             	mov    0x8(%ebp),%eax
801035a6:	2d 00 02 00 00       	sub    $0x200,%eax
801035ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035ae:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801035b3:	8d 4a 01             	lea    0x1(%edx),%ecx
801035b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035b9:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
801035bd:	eb 35                	jmp    801035f4 <updateBlkRef+0x12a>
    else if(flag == -1)
801035bf:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801035c3:	75 2f                	jne    801035f4 <updateBlkRef+0x12a>
      if(bp->data[sector-512] > 0)
801035c5:	8b 45 08             	mov    0x8(%ebp),%eax
801035c8:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
801035ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d1:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
801035d6:	84 c0                	test   %al,%al
801035d8:	74 1a                	je     801035f4 <updateBlkRef+0x12a>
	bp->data[sector-512]--;
801035da:	8b 45 08             	mov    0x8(%ebp),%eax
801035dd:	2d 00 02 00 00       	sub    $0x200,%eax
801035e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035e5:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801035ea:	8d 4a ff             	lea    -0x1(%edx),%ecx
801035ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035f0:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
801035f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035f7:	89 04 24             	mov    %eax,(%esp)
801035fa:	e8 de cb ff ff       	call   801001dd <bwrite>
    brelse(bp);
801035ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103602:	89 04 24             	mov    %eax,(%esp)
80103605:	e8 0d cc ff ff       	call   80100217 <brelse>
  }  
}
8010360a:	c9                   	leave  
8010360b:	c3                   	ret    

8010360c <getBlkRef>:

int
getBlkRef(uint sector)
{
8010360c:	55                   	push   %ebp
8010360d:	89 e5                	mov    %esp,%ebp
8010360f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1;
80103612:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  
  if(sector < 512)
80103619:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103620:	77 19                	ja     8010363b <getBlkRef+0x2f>
    bp = bread(1,1024);
80103622:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103629:	00 
8010362a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103631:	e8 70 cb ff ff       	call   801001a6 <bread>
80103636:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103639:	eb 20                	jmp    8010365b <getBlkRef+0x4f>
  else if(sector < 1024)
8010363b:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103642:	77 17                	ja     8010365b <getBlkRef+0x4f>
    bp = bread(1,1025);
80103644:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
8010364b:	00 
8010364c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103653:	e8 4e cb ff ff       	call   801001a6 <bread>
80103658:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cprintf("getblkref sector = %d, ref = %d\n",sector,bp->data[sector]);
8010365b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010365e:	03 45 08             	add    0x8(%ebp),%eax
80103661:	83 c0 10             	add    $0x10,%eax
80103664:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103668:	0f b6 c0             	movzbl %al,%eax
8010366b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010366f:	8b 45 08             	mov    0x8(%ebp),%eax
80103672:	89 44 24 04          	mov    %eax,0x4(%esp)
80103676:	c7 04 24 fc 97 10 80 	movl   $0x801097fc,(%esp)
8010367d:	e8 1f cd ff ff       	call   801003a1 <cprintf>
  ret = (uchar)bp->data[sector];
80103682:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103685:	03 45 08             	add    0x8(%ebp),%eax
80103688:	83 c0 10             	add    $0x10,%eax
8010368b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010368f:	0f b6 c0             	movzbl %al,%eax
80103692:	89 45 f0             	mov    %eax,-0x10(%ebp)
  brelse(bp);
80103695:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103698:	89 04 24             	mov    %eax,(%esp)
8010369b:	e8 77 cb ff ff       	call   80100217 <brelse>
  return ret;
801036a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801036a3:	c9                   	leave  
801036a4:	c3                   	ret    

801036a5 <zeroNextInum>:

void
zeroNextInum(void)
{
801036a5:	55                   	push   %ebp
801036a6:	89 e5                	mov    %esp,%ebp
  nextInum = 0;
801036a8:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
801036af:	00 00 00 
}
801036b2:	5d                   	pop    %ebp
801036b3:	c3                   	ret    

801036b4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801036b4:	55                   	push   %ebp
801036b5:	89 e5                	mov    %esp,%ebp
801036b7:	53                   	push   %ebx
801036b8:	83 ec 14             	sub    $0x14,%esp
801036bb:	8b 45 08             	mov    0x8(%ebp),%eax
801036be:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801036c2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801036c6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801036ca:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801036ce:	ec                   	in     (%dx),%al
801036cf:	89 c3                	mov    %eax,%ebx
801036d1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801036d4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801036d8:	83 c4 14             	add    $0x14,%esp
801036db:	5b                   	pop    %ebx
801036dc:	5d                   	pop    %ebp
801036dd:	c3                   	ret    

801036de <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801036de:	55                   	push   %ebp
801036df:	89 e5                	mov    %esp,%ebp
801036e1:	57                   	push   %edi
801036e2:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801036e3:	8b 55 08             	mov    0x8(%ebp),%edx
801036e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801036e9:	8b 45 10             	mov    0x10(%ebp),%eax
801036ec:	89 cb                	mov    %ecx,%ebx
801036ee:	89 df                	mov    %ebx,%edi
801036f0:	89 c1                	mov    %eax,%ecx
801036f2:	fc                   	cld    
801036f3:	f3 6d                	rep insl (%dx),%es:(%edi)
801036f5:	89 c8                	mov    %ecx,%eax
801036f7:	89 fb                	mov    %edi,%ebx
801036f9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801036fc:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801036ff:	5b                   	pop    %ebx
80103700:	5f                   	pop    %edi
80103701:	5d                   	pop    %ebp
80103702:	c3                   	ret    

80103703 <outb>:

static inline void
outb(ushort port, uchar data)
{
80103703:	55                   	push   %ebp
80103704:	89 e5                	mov    %esp,%ebp
80103706:	83 ec 08             	sub    $0x8,%esp
80103709:	8b 55 08             	mov    0x8(%ebp),%edx
8010370c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010370f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103713:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103716:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010371a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010371e:	ee                   	out    %al,(%dx)
}
8010371f:	c9                   	leave  
80103720:	c3                   	ret    

80103721 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80103721:	55                   	push   %ebp
80103722:	89 e5                	mov    %esp,%ebp
80103724:	56                   	push   %esi
80103725:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80103726:	8b 55 08             	mov    0x8(%ebp),%edx
80103729:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010372c:	8b 45 10             	mov    0x10(%ebp),%eax
8010372f:	89 cb                	mov    %ecx,%ebx
80103731:	89 de                	mov    %ebx,%esi
80103733:	89 c1                	mov    %eax,%ecx
80103735:	fc                   	cld    
80103736:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80103738:	89 c8                	mov    %ecx,%eax
8010373a:	89 f3                	mov    %esi,%ebx
8010373c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010373f:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103742:	5b                   	pop    %ebx
80103743:	5e                   	pop    %esi
80103744:	5d                   	pop    %ebp
80103745:	c3                   	ret    

80103746 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80103746:	55                   	push   %ebp
80103747:	89 e5                	mov    %esp,%ebp
80103749:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010374c:	90                   	nop
8010374d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103754:	e8 5b ff ff ff       	call   801036b4 <inb>
80103759:	0f b6 c0             	movzbl %al,%eax
8010375c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010375f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103762:	25 c0 00 00 00       	and    $0xc0,%eax
80103767:	83 f8 40             	cmp    $0x40,%eax
8010376a:	75 e1                	jne    8010374d <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
8010376c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103770:	74 11                	je     80103783 <idewait+0x3d>
80103772:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103775:	83 e0 21             	and    $0x21,%eax
80103778:	85 c0                	test   %eax,%eax
8010377a:	74 07                	je     80103783 <idewait+0x3d>
    return -1;
8010377c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103781:	eb 05                	jmp    80103788 <idewait+0x42>
  return 0;
80103783:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103788:	c9                   	leave  
80103789:	c3                   	ret    

8010378a <ideinit>:

void
ideinit(void)
{
8010378a:	55                   	push   %ebp
8010378b:	89 e5                	mov    %esp,%ebp
8010378d:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80103790:	c7 44 24 04 1d 98 10 	movl   $0x8010981d,0x4(%esp)
80103797:	80 
80103798:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010379f:	e8 42 26 00 00       	call   80105de6 <initlock>
  picenable(IRQ_IDE);
801037a4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801037ab:	e8 75 15 00 00       	call   80104d25 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801037b0:	a1 40 0f 11 80       	mov    0x80110f40,%eax
801037b5:	83 e8 01             	sub    $0x1,%eax
801037b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801037bc:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801037c3:	e8 12 04 00 00       	call   80103bda <ioapicenable>
  idewait(0);
801037c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037cf:	e8 72 ff ff ff       	call   80103746 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801037d4:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801037db:	00 
801037dc:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801037e3:	e8 1b ff ff ff       	call   80103703 <outb>
  for(i=0; i<1000; i++){
801037e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037ef:	eb 20                	jmp    80103811 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801037f1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801037f8:	e8 b7 fe ff ff       	call   801036b4 <inb>
801037fd:	84 c0                	test   %al,%al
801037ff:	74 0c                	je     8010380d <ideinit+0x83>
      havedisk1 = 1;
80103801:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80103808:	00 00 00 
      break;
8010380b:	eb 0d                	jmp    8010381a <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
8010380d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103811:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80103818:	7e d7                	jle    801037f1 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010381a:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103821:	00 
80103822:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103829:	e8 d5 fe ff ff       	call   80103703 <outb>
}
8010382e:	c9                   	leave  
8010382f:	c3                   	ret    

80103830 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103830:	55                   	push   %ebp
80103831:	89 e5                	mov    %esp,%ebp
80103833:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80103836:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010383a:	75 0c                	jne    80103848 <idestart+0x18>
    panic("idestart");
8010383c:	c7 04 24 21 98 10 80 	movl   $0x80109821,(%esp)
80103843:	e8 f5 cc ff ff       	call   8010053d <panic>

  idewait(0);
80103848:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010384f:	e8 f2 fe ff ff       	call   80103746 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80103854:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010385b:	00 
8010385c:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80103863:	e8 9b fe ff ff       	call   80103703 <outb>
  outb(0x1f2, 1);  // number of sectors
80103868:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010386f:	00 
80103870:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80103877:	e8 87 fe ff ff       	call   80103703 <outb>
  outb(0x1f3, b->sector & 0xff);
8010387c:	8b 45 08             	mov    0x8(%ebp),%eax
8010387f:	8b 40 08             	mov    0x8(%eax),%eax
80103882:	0f b6 c0             	movzbl %al,%eax
80103885:	89 44 24 04          	mov    %eax,0x4(%esp)
80103889:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80103890:	e8 6e fe ff ff       	call   80103703 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80103895:	8b 45 08             	mov    0x8(%ebp),%eax
80103898:	8b 40 08             	mov    0x8(%eax),%eax
8010389b:	c1 e8 08             	shr    $0x8,%eax
8010389e:	0f b6 c0             	movzbl %al,%eax
801038a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801038a5:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801038ac:	e8 52 fe ff ff       	call   80103703 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801038b1:	8b 45 08             	mov    0x8(%ebp),%eax
801038b4:	8b 40 08             	mov    0x8(%eax),%eax
801038b7:	c1 e8 10             	shr    $0x10,%eax
801038ba:	0f b6 c0             	movzbl %al,%eax
801038bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801038c1:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801038c8:	e8 36 fe ff ff       	call   80103703 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801038cd:	8b 45 08             	mov    0x8(%ebp),%eax
801038d0:	8b 40 04             	mov    0x4(%eax),%eax
801038d3:	83 e0 01             	and    $0x1,%eax
801038d6:	89 c2                	mov    %eax,%edx
801038d8:	c1 e2 04             	shl    $0x4,%edx
801038db:	8b 45 08             	mov    0x8(%ebp),%eax
801038de:	8b 40 08             	mov    0x8(%eax),%eax
801038e1:	c1 e8 18             	shr    $0x18,%eax
801038e4:	83 e0 0f             	and    $0xf,%eax
801038e7:	09 d0                	or     %edx,%eax
801038e9:	83 c8 e0             	or     $0xffffffe0,%eax
801038ec:	0f b6 c0             	movzbl %al,%eax
801038ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801038f3:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801038fa:	e8 04 fe ff ff       	call   80103703 <outb>
  if(b->flags & B_DIRTY){
801038ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103902:	8b 00                	mov    (%eax),%eax
80103904:	83 e0 04             	and    $0x4,%eax
80103907:	85 c0                	test   %eax,%eax
80103909:	74 34                	je     8010393f <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010390b:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80103912:	00 
80103913:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010391a:	e8 e4 fd ff ff       	call   80103703 <outb>
    outsl(0x1f0, b->data, 512/4);
8010391f:	8b 45 08             	mov    0x8(%ebp),%eax
80103922:	83 c0 18             	add    $0x18,%eax
80103925:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010392c:	00 
8010392d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103931:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103938:	e8 e4 fd ff ff       	call   80103721 <outsl>
8010393d:	eb 14                	jmp    80103953 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010393f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103946:	00 
80103947:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010394e:	e8 b0 fd ff ff       	call   80103703 <outb>
  }
}
80103953:	c9                   	leave  
80103954:	c3                   	ret    

80103955 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80103955:	55                   	push   %ebp
80103956:	89 e5                	mov    %esp,%ebp
80103958:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010395b:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103962:	e8 a0 24 00 00       	call   80105e07 <acquire>
  if((b = idequeue) == 0){
80103967:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010396c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010396f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103973:	75 11                	jne    80103986 <ideintr+0x31>
    release(&idelock);
80103975:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010397c:	e8 e8 24 00 00       	call   80105e69 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80103981:	e9 90 00 00 00       	jmp    80103a16 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80103986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103989:	8b 40 14             	mov    0x14(%eax),%eax
8010398c:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80103991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103994:	8b 00                	mov    (%eax),%eax
80103996:	83 e0 04             	and    $0x4,%eax
80103999:	85 c0                	test   %eax,%eax
8010399b:	75 2e                	jne    801039cb <ideintr+0x76>
8010399d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801039a4:	e8 9d fd ff ff       	call   80103746 <idewait>
801039a9:	85 c0                	test   %eax,%eax
801039ab:	78 1e                	js     801039cb <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801039ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039b0:	83 c0 18             	add    $0x18,%eax
801039b3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801039ba:	00 
801039bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801039bf:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801039c6:	e8 13 fd ff ff       	call   801036de <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801039cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ce:	8b 00                	mov    (%eax),%eax
801039d0:	89 c2                	mov    %eax,%edx
801039d2:	83 ca 02             	or     $0x2,%edx
801039d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039d8:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801039da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039dd:	8b 00                	mov    (%eax),%eax
801039df:	89 c2                	mov    %eax,%edx
801039e1:	83 e2 fb             	and    $0xfffffffb,%edx
801039e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039e7:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801039e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039ec:	89 04 24             	mov    %eax,(%esp)
801039ef:	e8 0e 22 00 00       	call   80105c02 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801039f4:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801039f9:	85 c0                	test   %eax,%eax
801039fb:	74 0d                	je     80103a0a <ideintr+0xb5>
    idestart(idequeue);
801039fd:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103a02:	89 04 24             	mov    %eax,(%esp)
80103a05:	e8 26 fe ff ff       	call   80103830 <idestart>

  release(&idelock);
80103a0a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a11:	e8 53 24 00 00       	call   80105e69 <release>
}
80103a16:	c9                   	leave  
80103a17:	c3                   	ret    

80103a18 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103a18:	55                   	push   %ebp
80103a19:	89 e5                	mov    %esp,%ebp
80103a1b:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80103a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80103a21:	8b 00                	mov    (%eax),%eax
80103a23:	83 e0 01             	and    $0x1,%eax
80103a26:	85 c0                	test   %eax,%eax
80103a28:	75 0c                	jne    80103a36 <iderw+0x1e>
    panic("iderw: buf not busy");
80103a2a:	c7 04 24 2a 98 10 80 	movl   $0x8010982a,(%esp)
80103a31:	e8 07 cb ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103a36:	8b 45 08             	mov    0x8(%ebp),%eax
80103a39:	8b 00                	mov    (%eax),%eax
80103a3b:	83 e0 06             	and    $0x6,%eax
80103a3e:	83 f8 02             	cmp    $0x2,%eax
80103a41:	75 0c                	jne    80103a4f <iderw+0x37>
    panic("iderw: nothing to do");
80103a43:	c7 04 24 3e 98 10 80 	movl   $0x8010983e,(%esp)
80103a4a:	e8 ee ca ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80103a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103a52:	8b 40 04             	mov    0x4(%eax),%eax
80103a55:	85 c0                	test   %eax,%eax
80103a57:	74 15                	je     80103a6e <iderw+0x56>
80103a59:	a1 58 c6 10 80       	mov    0x8010c658,%eax
80103a5e:	85 c0                	test   %eax,%eax
80103a60:	75 0c                	jne    80103a6e <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80103a62:	c7 04 24 53 98 10 80 	movl   $0x80109853,(%esp)
80103a69:	e8 cf ca ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80103a6e:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a75:	e8 8d 23 00 00       	call   80105e07 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80103a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80103a7d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80103a84:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80103a8b:	eb 0b                	jmp    80103a98 <iderw+0x80>
80103a8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a90:	8b 00                	mov    (%eax),%eax
80103a92:	83 c0 14             	add    $0x14,%eax
80103a95:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a9b:	8b 00                	mov    (%eax),%eax
80103a9d:	85 c0                	test   %eax,%eax
80103a9f:	75 ec                	jne    80103a8d <iderw+0x75>
    ;
  *pp = b;
80103aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aa4:	8b 55 08             	mov    0x8(%ebp),%edx
80103aa7:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80103aa9:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103aae:	3b 45 08             	cmp    0x8(%ebp),%eax
80103ab1:	75 22                	jne    80103ad5 <iderw+0xbd>
    idestart(b);
80103ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ab6:	89 04 24             	mov    %eax,(%esp)
80103ab9:	e8 72 fd ff ff       	call   80103830 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103abe:	eb 15                	jmp    80103ad5 <iderw+0xbd>
    sleep(b, &idelock);
80103ac0:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103ac7:	80 
80103ac8:	8b 45 08             	mov    0x8(%ebp),%eax
80103acb:	89 04 24             	mov    %eax,(%esp)
80103ace:	e8 56 20 00 00       	call   80105b29 <sleep>
80103ad3:	eb 01                	jmp    80103ad6 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103ad5:	90                   	nop
80103ad6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ad9:	8b 00                	mov    (%eax),%eax
80103adb:	83 e0 06             	and    $0x6,%eax
80103ade:	83 f8 02             	cmp    $0x2,%eax
80103ae1:	75 dd                	jne    80103ac0 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103ae3:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103aea:	e8 7a 23 00 00       	call   80105e69 <release>
}
80103aef:	c9                   	leave  
80103af0:	c3                   	ret    
80103af1:	00 00                	add    %al,(%eax)
	...

80103af4 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103af4:	55                   	push   %ebp
80103af5:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103af7:	a1 74 08 11 80       	mov    0x80110874,%eax
80103afc:	8b 55 08             	mov    0x8(%ebp),%edx
80103aff:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103b01:	a1 74 08 11 80       	mov    0x80110874,%eax
80103b06:	8b 40 10             	mov    0x10(%eax),%eax
}
80103b09:	5d                   	pop    %ebp
80103b0a:	c3                   	ret    

80103b0b <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103b0b:	55                   	push   %ebp
80103b0c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103b0e:	a1 74 08 11 80       	mov    0x80110874,%eax
80103b13:	8b 55 08             	mov    0x8(%ebp),%edx
80103b16:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103b18:	a1 74 08 11 80       	mov    0x80110874,%eax
80103b1d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b20:	89 50 10             	mov    %edx,0x10(%eax)
}
80103b23:	5d                   	pop    %ebp
80103b24:	c3                   	ret    

80103b25 <ioapicinit>:

void
ioapicinit(void)
{
80103b25:	55                   	push   %ebp
80103b26:	89 e5                	mov    %esp,%ebp
80103b28:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103b2b:	a1 44 09 11 80       	mov    0x80110944,%eax
80103b30:	85 c0                	test   %eax,%eax
80103b32:	0f 84 9f 00 00 00    	je     80103bd7 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103b38:	c7 05 74 08 11 80 00 	movl   $0xfec00000,0x80110874
80103b3f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103b42:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103b49:	e8 a6 ff ff ff       	call   80103af4 <ioapicread>
80103b4e:	c1 e8 10             	shr    $0x10,%eax
80103b51:	25 ff 00 00 00       	and    $0xff,%eax
80103b56:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103b59:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103b60:	e8 8f ff ff ff       	call   80103af4 <ioapicread>
80103b65:	c1 e8 18             	shr    $0x18,%eax
80103b68:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103b6b:	0f b6 05 40 09 11 80 	movzbl 0x80110940,%eax
80103b72:	0f b6 c0             	movzbl %al,%eax
80103b75:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b78:	74 0c                	je     80103b86 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103b7a:	c7 04 24 74 98 10 80 	movl   $0x80109874,(%esp)
80103b81:	e8 1b c8 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103b86:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b8d:	eb 3e                	jmp    80103bcd <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b92:	83 c0 20             	add    $0x20,%eax
80103b95:	0d 00 00 01 00       	or     $0x10000,%eax
80103b9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b9d:	83 c2 08             	add    $0x8,%edx
80103ba0:	01 d2                	add    %edx,%edx
80103ba2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ba6:	89 14 24             	mov    %edx,(%esp)
80103ba9:	e8 5d ff ff ff       	call   80103b0b <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bb1:	83 c0 08             	add    $0x8,%eax
80103bb4:	01 c0                	add    %eax,%eax
80103bb6:	83 c0 01             	add    $0x1,%eax
80103bb9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103bc0:	00 
80103bc1:	89 04 24             	mov    %eax,(%esp)
80103bc4:	e8 42 ff ff ff       	call   80103b0b <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103bc9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103bd3:	7e ba                	jle    80103b8f <ioapicinit+0x6a>
80103bd5:	eb 01                	jmp    80103bd8 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103bd7:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103bd8:	c9                   	leave  
80103bd9:	c3                   	ret    

80103bda <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103bda:	55                   	push   %ebp
80103bdb:	89 e5                	mov    %esp,%ebp
80103bdd:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103be0:	a1 44 09 11 80       	mov    0x80110944,%eax
80103be5:	85 c0                	test   %eax,%eax
80103be7:	74 39                	je     80103c22 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103be9:	8b 45 08             	mov    0x8(%ebp),%eax
80103bec:	83 c0 20             	add    $0x20,%eax
80103bef:	8b 55 08             	mov    0x8(%ebp),%edx
80103bf2:	83 c2 08             	add    $0x8,%edx
80103bf5:	01 d2                	add    %edx,%edx
80103bf7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bfb:	89 14 24             	mov    %edx,(%esp)
80103bfe:	e8 08 ff ff ff       	call   80103b0b <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103c03:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c06:	c1 e0 18             	shl    $0x18,%eax
80103c09:	8b 55 08             	mov    0x8(%ebp),%edx
80103c0c:	83 c2 08             	add    $0x8,%edx
80103c0f:	01 d2                	add    %edx,%edx
80103c11:	83 c2 01             	add    $0x1,%edx
80103c14:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c18:	89 14 24             	mov    %edx,(%esp)
80103c1b:	e8 eb fe ff ff       	call   80103b0b <ioapicwrite>
80103c20:	eb 01                	jmp    80103c23 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103c22:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103c23:	c9                   	leave  
80103c24:	c3                   	ret    
80103c25:	00 00                	add    %al,(%eax)
	...

80103c28 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103c28:	55                   	push   %ebp
80103c29:	89 e5                	mov    %esp,%ebp
80103c2b:	8b 45 08             	mov    0x8(%ebp),%eax
80103c2e:	05 00 00 00 80       	add    $0x80000000,%eax
80103c33:	5d                   	pop    %ebp
80103c34:	c3                   	ret    

80103c35 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103c35:	55                   	push   %ebp
80103c36:	89 e5                	mov    %esp,%ebp
80103c38:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103c3b:	c7 44 24 04 a6 98 10 	movl   $0x801098a6,0x4(%esp)
80103c42:	80 
80103c43:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103c4a:	e8 97 21 00 00       	call   80105de6 <initlock>
  kmem.use_lock = 0;
80103c4f:	c7 05 b4 08 11 80 00 	movl   $0x0,0x801108b4
80103c56:	00 00 00 
  freerange(vstart, vend);
80103c59:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c60:	8b 45 08             	mov    0x8(%ebp),%eax
80103c63:	89 04 24             	mov    %eax,(%esp)
80103c66:	e8 26 00 00 00       	call   80103c91 <freerange>
}
80103c6b:	c9                   	leave  
80103c6c:	c3                   	ret    

80103c6d <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103c6d:	55                   	push   %ebp
80103c6e:	89 e5                	mov    %esp,%ebp
80103c70:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103c73:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c76:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c7a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c7d:	89 04 24             	mov    %eax,(%esp)
80103c80:	e8 0c 00 00 00       	call   80103c91 <freerange>
  kmem.use_lock = 1;
80103c85:	c7 05 b4 08 11 80 01 	movl   $0x1,0x801108b4
80103c8c:	00 00 00 
}
80103c8f:	c9                   	leave  
80103c90:	c3                   	ret    

80103c91 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103c91:	55                   	push   %ebp
80103c92:	89 e5                	mov    %esp,%ebp
80103c94:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103c97:	8b 45 08             	mov    0x8(%ebp),%eax
80103c9a:	05 ff 0f 00 00       	add    $0xfff,%eax
80103c9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103ca4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103ca7:	eb 12                	jmp    80103cbb <freerange+0x2a>
    kfree(p);
80103ca9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cac:	89 04 24             	mov    %eax,(%esp)
80103caf:	e8 16 00 00 00       	call   80103cca <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103cb4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103cbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cbe:	05 00 10 00 00       	add    $0x1000,%eax
80103cc3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103cc6:	76 e1                	jbe    80103ca9 <freerange+0x18>
    kfree(p);
}
80103cc8:	c9                   	leave  
80103cc9:	c3                   	ret    

80103cca <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103cca:	55                   	push   %ebp
80103ccb:	89 e5                	mov    %esp,%ebp
80103ccd:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103cd0:	8b 45 08             	mov    0x8(%ebp),%eax
80103cd3:	25 ff 0f 00 00       	and    $0xfff,%eax
80103cd8:	85 c0                	test   %eax,%eax
80103cda:	75 1b                	jne    80103cf7 <kfree+0x2d>
80103cdc:	81 7d 08 3c 37 11 80 	cmpl   $0x8011373c,0x8(%ebp)
80103ce3:	72 12                	jb     80103cf7 <kfree+0x2d>
80103ce5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ce8:	89 04 24             	mov    %eax,(%esp)
80103ceb:	e8 38 ff ff ff       	call   80103c28 <v2p>
80103cf0:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103cf5:	76 0c                	jbe    80103d03 <kfree+0x39>
    panic("kfree");
80103cf7:	c7 04 24 ab 98 10 80 	movl   $0x801098ab,(%esp)
80103cfe:	e8 3a c8 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103d03:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103d0a:	00 
80103d0b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d12:	00 
80103d13:	8b 45 08             	mov    0x8(%ebp),%eax
80103d16:	89 04 24             	mov    %eax,(%esp)
80103d19:	e8 38 23 00 00       	call   80106056 <memset>

  if(kmem.use_lock)
80103d1e:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d23:	85 c0                	test   %eax,%eax
80103d25:	74 0c                	je     80103d33 <kfree+0x69>
    acquire(&kmem.lock);
80103d27:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103d2e:	e8 d4 20 00 00       	call   80105e07 <acquire>
  r = (struct run*)v;
80103d33:	8b 45 08             	mov    0x8(%ebp),%eax
80103d36:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103d39:	8b 15 b8 08 11 80    	mov    0x801108b8,%edx
80103d3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d42:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103d44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d47:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103d4c:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d51:	85 c0                	test   %eax,%eax
80103d53:	74 0c                	je     80103d61 <kfree+0x97>
    release(&kmem.lock);
80103d55:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103d5c:	e8 08 21 00 00       	call   80105e69 <release>
}
80103d61:	c9                   	leave  
80103d62:	c3                   	ret    

80103d63 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103d63:	55                   	push   %ebp
80103d64:	89 e5                	mov    %esp,%ebp
80103d66:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103d69:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d6e:	85 c0                	test   %eax,%eax
80103d70:	74 0c                	je     80103d7e <kalloc+0x1b>
    acquire(&kmem.lock);
80103d72:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103d79:	e8 89 20 00 00       	call   80105e07 <acquire>
  r = kmem.freelist;
80103d7e:	a1 b8 08 11 80       	mov    0x801108b8,%eax
80103d83:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103d86:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d8a:	74 0a                	je     80103d96 <kalloc+0x33>
    kmem.freelist = r->next;
80103d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d8f:	8b 00                	mov    (%eax),%eax
80103d91:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103d96:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d9b:	85 c0                	test   %eax,%eax
80103d9d:	74 0c                	je     80103dab <kalloc+0x48>
    release(&kmem.lock);
80103d9f:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103da6:	e8 be 20 00 00       	call   80105e69 <release>
  return (char*)r;
80103dab:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103dae:	c9                   	leave  
80103daf:	c3                   	ret    

80103db0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103db0:	55                   	push   %ebp
80103db1:	89 e5                	mov    %esp,%ebp
80103db3:	53                   	push   %ebx
80103db4:	83 ec 14             	sub    $0x14,%esp
80103db7:	8b 45 08             	mov    0x8(%ebp),%eax
80103dba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103dbe:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103dc2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103dc6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103dca:	ec                   	in     (%dx),%al
80103dcb:	89 c3                	mov    %eax,%ebx
80103dcd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103dd0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103dd4:	83 c4 14             	add    $0x14,%esp
80103dd7:	5b                   	pop    %ebx
80103dd8:	5d                   	pop    %ebp
80103dd9:	c3                   	ret    

80103dda <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103dda:	55                   	push   %ebp
80103ddb:	89 e5                	mov    %esp,%ebp
80103ddd:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103de0:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103de7:	e8 c4 ff ff ff       	call   80103db0 <inb>
80103dec:	0f b6 c0             	movzbl %al,%eax
80103def:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103df2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df5:	83 e0 01             	and    $0x1,%eax
80103df8:	85 c0                	test   %eax,%eax
80103dfa:	75 0a                	jne    80103e06 <kbdgetc+0x2c>
    return -1;
80103dfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e01:	e9 23 01 00 00       	jmp    80103f29 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103e06:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103e0d:	e8 9e ff ff ff       	call   80103db0 <inb>
80103e12:	0f b6 c0             	movzbl %al,%eax
80103e15:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103e18:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103e1f:	75 17                	jne    80103e38 <kbdgetc+0x5e>
    shift |= E0ESC;
80103e21:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e26:	83 c8 40             	or     $0x40,%eax
80103e29:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103e2e:	b8 00 00 00 00       	mov    $0x0,%eax
80103e33:	e9 f1 00 00 00       	jmp    80103f29 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103e38:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e3b:	25 80 00 00 00       	and    $0x80,%eax
80103e40:	85 c0                	test   %eax,%eax
80103e42:	74 45                	je     80103e89 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103e44:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e49:	83 e0 40             	and    $0x40,%eax
80103e4c:	85 c0                	test   %eax,%eax
80103e4e:	75 08                	jne    80103e58 <kbdgetc+0x7e>
80103e50:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e53:	83 e0 7f             	and    $0x7f,%eax
80103e56:	eb 03                	jmp    80103e5b <kbdgetc+0x81>
80103e58:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e5b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103e5e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e61:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103e66:	0f b6 00             	movzbl (%eax),%eax
80103e69:	83 c8 40             	or     $0x40,%eax
80103e6c:	0f b6 c0             	movzbl %al,%eax
80103e6f:	f7 d0                	not    %eax
80103e71:	89 c2                	mov    %eax,%edx
80103e73:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e78:	21 d0                	and    %edx,%eax
80103e7a:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103e7f:	b8 00 00 00 00       	mov    $0x0,%eax
80103e84:	e9 a0 00 00 00       	jmp    80103f29 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103e89:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e8e:	83 e0 40             	and    $0x40,%eax
80103e91:	85 c0                	test   %eax,%eax
80103e93:	74 14                	je     80103ea9 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103e95:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103e9c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ea1:	83 e0 bf             	and    $0xffffffbf,%eax
80103ea4:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103ea9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103eac:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103eb1:	0f b6 00             	movzbl (%eax),%eax
80103eb4:	0f b6 d0             	movzbl %al,%edx
80103eb7:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ebc:	09 d0                	or     %edx,%eax
80103ebe:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103ec3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ec6:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103ecb:	0f b6 00             	movzbl (%eax),%eax
80103ece:	0f b6 d0             	movzbl %al,%edx
80103ed1:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ed6:	31 d0                	xor    %edx,%eax
80103ed8:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103edd:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ee2:	83 e0 03             	and    $0x3,%eax
80103ee5:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103eec:	03 45 fc             	add    -0x4(%ebp),%eax
80103eef:	0f b6 00             	movzbl (%eax),%eax
80103ef2:	0f b6 c0             	movzbl %al,%eax
80103ef5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103ef8:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103efd:	83 e0 08             	and    $0x8,%eax
80103f00:	85 c0                	test   %eax,%eax
80103f02:	74 22                	je     80103f26 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103f04:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103f08:	76 0c                	jbe    80103f16 <kbdgetc+0x13c>
80103f0a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103f0e:	77 06                	ja     80103f16 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103f10:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103f14:	eb 10                	jmp    80103f26 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103f16:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103f1a:	76 0a                	jbe    80103f26 <kbdgetc+0x14c>
80103f1c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103f20:	77 04                	ja     80103f26 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103f22:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103f26:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103f29:	c9                   	leave  
80103f2a:	c3                   	ret    

80103f2b <kbdintr>:

void
kbdintr(void)
{
80103f2b:	55                   	push   %ebp
80103f2c:	89 e5                	mov    %esp,%ebp
80103f2e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103f31:	c7 04 24 da 3d 10 80 	movl   $0x80103dda,(%esp)
80103f38:	e8 70 c8 ff ff       	call   801007ad <consoleintr>
}
80103f3d:	c9                   	leave  
80103f3e:	c3                   	ret    
	...

80103f40 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f40:	55                   	push   %ebp
80103f41:	89 e5                	mov    %esp,%ebp
80103f43:	83 ec 08             	sub    $0x8,%esp
80103f46:	8b 55 08             	mov    0x8(%ebp),%edx
80103f49:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f4c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f50:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f53:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f57:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f5b:	ee                   	out    %al,(%dx)
}
80103f5c:	c9                   	leave  
80103f5d:	c3                   	ret    

80103f5e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103f5e:	55                   	push   %ebp
80103f5f:	89 e5                	mov    %esp,%ebp
80103f61:	53                   	push   %ebx
80103f62:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103f65:	9c                   	pushf  
80103f66:	5b                   	pop    %ebx
80103f67:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103f6a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103f6d:	83 c4 10             	add    $0x10,%esp
80103f70:	5b                   	pop    %ebx
80103f71:	5d                   	pop    %ebp
80103f72:	c3                   	ret    

80103f73 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103f73:	55                   	push   %ebp
80103f74:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103f76:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f7b:	8b 55 08             	mov    0x8(%ebp),%edx
80103f7e:	c1 e2 02             	shl    $0x2,%edx
80103f81:	01 c2                	add    %eax,%edx
80103f83:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f86:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103f88:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f8d:	83 c0 20             	add    $0x20,%eax
80103f90:	8b 00                	mov    (%eax),%eax
}
80103f92:	5d                   	pop    %ebp
80103f93:	c3                   	ret    

80103f94 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103f94:	55                   	push   %ebp
80103f95:	89 e5                	mov    %esp,%ebp
80103f97:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103f9a:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f9f:	85 c0                	test   %eax,%eax
80103fa1:	0f 84 47 01 00 00    	je     801040ee <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103fa7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103fae:	00 
80103faf:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103fb6:	e8 b8 ff ff ff       	call   80103f73 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103fbb:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103fc2:	00 
80103fc3:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103fca:	e8 a4 ff ff ff       	call   80103f73 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103fcf:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103fd6:	00 
80103fd7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103fde:	e8 90 ff ff ff       	call   80103f73 <lapicw>
  lapicw(TICR, 10000000); 
80103fe3:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103fea:	00 
80103feb:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103ff2:	e8 7c ff ff ff       	call   80103f73 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103ff7:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ffe:	00 
80103fff:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80104006:	e8 68 ff ff ff       	call   80103f73 <lapicw>
  lapicw(LINT1, MASKED);
8010400b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104012:	00 
80104013:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010401a:	e8 54 ff ff ff       	call   80103f73 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010401f:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80104024:	83 c0 30             	add    $0x30,%eax
80104027:	8b 00                	mov    (%eax),%eax
80104029:	c1 e8 10             	shr    $0x10,%eax
8010402c:	25 ff 00 00 00       	and    $0xff,%eax
80104031:	83 f8 03             	cmp    $0x3,%eax
80104034:	76 14                	jbe    8010404a <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80104036:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010403d:	00 
8010403e:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80104045:	e8 29 ff ff ff       	call   80103f73 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010404a:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80104051:	00 
80104052:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80104059:	e8 15 ff ff ff       	call   80103f73 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010405e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104065:	00 
80104066:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010406d:	e8 01 ff ff ff       	call   80103f73 <lapicw>
  lapicw(ESR, 0);
80104072:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104079:	00 
8010407a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104081:	e8 ed fe ff ff       	call   80103f73 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80104086:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010408d:	00 
8010408e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80104095:	e8 d9 fe ff ff       	call   80103f73 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
8010409a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040a1:	00 
801040a2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801040a9:	e8 c5 fe ff ff       	call   80103f73 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801040ae:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801040b5:	00 
801040b6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801040bd:	e8 b1 fe ff ff       	call   80103f73 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801040c2:	90                   	nop
801040c3:	a1 bc 08 11 80       	mov    0x801108bc,%eax
801040c8:	05 00 03 00 00       	add    $0x300,%eax
801040cd:	8b 00                	mov    (%eax),%eax
801040cf:	25 00 10 00 00       	and    $0x1000,%eax
801040d4:	85 c0                	test   %eax,%eax
801040d6:	75 eb                	jne    801040c3 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801040d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040df:	00 
801040e0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040e7:	e8 87 fe ff ff       	call   80103f73 <lapicw>
801040ec:	eb 01                	jmp    801040ef <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
801040ee:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
801040ef:	c9                   	leave  
801040f0:	c3                   	ret    

801040f1 <cpunum>:

int
cpunum(void)
{
801040f1:	55                   	push   %ebp
801040f2:	89 e5                	mov    %esp,%ebp
801040f4:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801040f7:	e8 62 fe ff ff       	call   80103f5e <readeflags>
801040fc:	25 00 02 00 00       	and    $0x200,%eax
80104101:	85 c0                	test   %eax,%eax
80104103:	74 29                	je     8010412e <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80104105:	a1 60 c6 10 80       	mov    0x8010c660,%eax
8010410a:	85 c0                	test   %eax,%eax
8010410c:	0f 94 c2             	sete   %dl
8010410f:	83 c0 01             	add    $0x1,%eax
80104112:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80104117:	84 d2                	test   %dl,%dl
80104119:	74 13                	je     8010412e <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
8010411b:	8b 45 04             	mov    0x4(%ebp),%eax
8010411e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104122:	c7 04 24 b4 98 10 80 	movl   $0x801098b4,(%esp)
80104129:	e8 73 c2 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
8010412e:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80104133:	85 c0                	test   %eax,%eax
80104135:	74 0f                	je     80104146 <cpunum+0x55>
    return lapic[ID]>>24;
80104137:	a1 bc 08 11 80       	mov    0x801108bc,%eax
8010413c:	83 c0 20             	add    $0x20,%eax
8010413f:	8b 00                	mov    (%eax),%eax
80104141:	c1 e8 18             	shr    $0x18,%eax
80104144:	eb 05                	jmp    8010414b <cpunum+0x5a>
  return 0;
80104146:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010414b:	c9                   	leave  
8010414c:	c3                   	ret    

8010414d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010414d:	55                   	push   %ebp
8010414e:	89 e5                	mov    %esp,%ebp
80104150:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80104153:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80104158:	85 c0                	test   %eax,%eax
8010415a:	74 14                	je     80104170 <lapiceoi+0x23>
    lapicw(EOI, 0);
8010415c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104163:	00 
80104164:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010416b:	e8 03 fe ff ff       	call   80103f73 <lapicw>
}
80104170:	c9                   	leave  
80104171:	c3                   	ret    

80104172 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80104172:	55                   	push   %ebp
80104173:	89 e5                	mov    %esp,%ebp
}
80104175:	5d                   	pop    %ebp
80104176:	c3                   	ret    

80104177 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80104177:	55                   	push   %ebp
80104178:	89 e5                	mov    %esp,%ebp
8010417a:	83 ec 1c             	sub    $0x1c,%esp
8010417d:	8b 45 08             	mov    0x8(%ebp),%eax
80104180:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80104183:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010418a:	00 
8010418b:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80104192:	e8 a9 fd ff ff       	call   80103f40 <outb>
  outb(IO_RTC+1, 0x0A);
80104197:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010419e:	00 
8010419f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801041a6:	e8 95 fd ff ff       	call   80103f40 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801041ab:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801041b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801041b5:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801041ba:	8b 45 f8             	mov    -0x8(%ebp),%eax
801041bd:	8d 50 02             	lea    0x2(%eax),%edx
801041c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801041c3:	c1 e8 04             	shr    $0x4,%eax
801041c6:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801041c9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801041cd:	c1 e0 18             	shl    $0x18,%eax
801041d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801041d4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801041db:	e8 93 fd ff ff       	call   80103f73 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801041e0:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801041e7:	00 
801041e8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801041ef:	e8 7f fd ff ff       	call   80103f73 <lapicw>
  microdelay(200);
801041f4:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801041fb:	e8 72 ff ff ff       	call   80104172 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80104200:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80104207:	00 
80104208:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010420f:	e8 5f fd ff ff       	call   80103f73 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80104214:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010421b:	e8 52 ff ff ff       	call   80104172 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104220:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104227:	eb 40                	jmp    80104269 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80104229:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010422d:	c1 e0 18             	shl    $0x18,%eax
80104230:	89 44 24 04          	mov    %eax,0x4(%esp)
80104234:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010423b:	e8 33 fd ff ff       	call   80103f73 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80104240:	8b 45 0c             	mov    0xc(%ebp),%eax
80104243:	c1 e8 0c             	shr    $0xc,%eax
80104246:	80 cc 06             	or     $0x6,%ah
80104249:	89 44 24 04          	mov    %eax,0x4(%esp)
8010424d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104254:	e8 1a fd ff ff       	call   80103f73 <lapicw>
    microdelay(200);
80104259:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80104260:	e8 0d ff ff ff       	call   80104172 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104265:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104269:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010426d:	7e ba                	jle    80104229 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010426f:	c9                   	leave  
80104270:	c3                   	ret    
80104271:	00 00                	add    %al,(%eax)
	...

80104274 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80104274:	55                   	push   %ebp
80104275:	89 e5                	mov    %esp,%ebp
80104277:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010427a:	c7 44 24 04 e0 98 10 	movl   $0x801098e0,0x4(%esp)
80104281:	80 
80104282:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104289:	e8 58 1b 00 00       	call   80105de6 <initlock>
  readsb(ROOTDEV, &sb);
8010428e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104291:	89 44 24 04          	mov    %eax,0x4(%esp)
80104295:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010429c:	e8 53 de ff ff       	call   801020f4 <readsb>
  log.start = sb.size - sb.nlog;
801042a1:	8b 55 e8             	mov    -0x18(%ebp),%edx
801042a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a7:	89 d1                	mov    %edx,%ecx
801042a9:	29 c1                	sub    %eax,%ecx
801042ab:	89 c8                	mov    %ecx,%eax
801042ad:	a3 f4 08 11 80       	mov    %eax,0x801108f4
  log.size = sb.nlog;
801042b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b5:	a3 f8 08 11 80       	mov    %eax,0x801108f8
  log.dev = ROOTDEV;
801042ba:	c7 05 00 09 11 80 01 	movl   $0x1,0x80110900
801042c1:	00 00 00 
  recover_from_log();
801042c4:	e8 97 01 00 00       	call   80104460 <recover_from_log>
}
801042c9:	c9                   	leave  
801042ca:	c3                   	ret    

801042cb <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801042cb:	55                   	push   %ebp
801042cc:	89 e5                	mov    %esp,%ebp
801042ce:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801042d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801042d8:	e9 89 00 00 00       	jmp    80104366 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801042dd:	a1 f4 08 11 80       	mov    0x801108f4,%eax
801042e2:	03 45 f4             	add    -0xc(%ebp),%eax
801042e5:	83 c0 01             	add    $0x1,%eax
801042e8:	89 c2                	mov    %eax,%edx
801042ea:	a1 00 09 11 80       	mov    0x80110900,%eax
801042ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801042f3:	89 04 24             	mov    %eax,(%esp)
801042f6:	e8 ab be ff ff       	call   801001a6 <bread>
801042fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801042fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104301:	83 c0 10             	add    $0x10,%eax
80104304:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
8010430b:	89 c2                	mov    %eax,%edx
8010430d:	a1 00 09 11 80       	mov    0x80110900,%eax
80104312:	89 54 24 04          	mov    %edx,0x4(%esp)
80104316:	89 04 24             	mov    %eax,(%esp)
80104319:	e8 88 be ff ff       	call   801001a6 <bread>
8010431e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80104321:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104324:	8d 50 18             	lea    0x18(%eax),%edx
80104327:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010432a:	83 c0 18             	add    $0x18,%eax
8010432d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104334:	00 
80104335:	89 54 24 04          	mov    %edx,0x4(%esp)
80104339:	89 04 24             	mov    %eax,(%esp)
8010433c:	e8 e8 1d 00 00       	call   80106129 <memmove>
    bwrite(dbuf);  // write dst to disk
80104341:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104344:	89 04 24             	mov    %eax,(%esp)
80104347:	e8 91 be ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010434c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434f:	89 04 24             	mov    %eax,(%esp)
80104352:	e8 c0 be ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80104357:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010435a:	89 04 24             	mov    %eax,(%esp)
8010435d:	e8 b5 be ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104362:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104366:	a1 04 09 11 80       	mov    0x80110904,%eax
8010436b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010436e:	0f 8f 69 ff ff ff    	jg     801042dd <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80104374:	c9                   	leave  
80104375:	c3                   	ret    

80104376 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80104376:	55                   	push   %ebp
80104377:	89 e5                	mov    %esp,%ebp
80104379:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010437c:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104381:	89 c2                	mov    %eax,%edx
80104383:	a1 00 09 11 80       	mov    0x80110900,%eax
80104388:	89 54 24 04          	mov    %edx,0x4(%esp)
8010438c:	89 04 24             	mov    %eax,(%esp)
8010438f:	e8 12 be ff ff       	call   801001a6 <bread>
80104394:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80104397:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010439a:	83 c0 18             	add    $0x18,%eax
8010439d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801043a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043a3:	8b 00                	mov    (%eax),%eax
801043a5:	a3 04 09 11 80       	mov    %eax,0x80110904
  for (i = 0; i < log.lh.n; i++) {
801043aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043b1:	eb 1b                	jmp    801043ce <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801043b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043b9:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801043bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043c0:	83 c2 10             	add    $0x10,%edx
801043c3:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801043ca:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043ce:	a1 04 09 11 80       	mov    0x80110904,%eax
801043d3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801043d6:	7f db                	jg     801043b3 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801043d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043db:	89 04 24             	mov    %eax,(%esp)
801043de:	e8 34 be ff ff       	call   80100217 <brelse>
}
801043e3:	c9                   	leave  
801043e4:	c3                   	ret    

801043e5 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801043e5:	55                   	push   %ebp
801043e6:	89 e5                	mov    %esp,%ebp
801043e8:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801043eb:	a1 f4 08 11 80       	mov    0x801108f4,%eax
801043f0:	89 c2                	mov    %eax,%edx
801043f2:	a1 00 09 11 80       	mov    0x80110900,%eax
801043f7:	89 54 24 04          	mov    %edx,0x4(%esp)
801043fb:	89 04 24             	mov    %eax,(%esp)
801043fe:	e8 a3 bd ff ff       	call   801001a6 <bread>
80104403:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80104406:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104409:	83 c0 18             	add    $0x18,%eax
8010440c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010440f:	8b 15 04 09 11 80    	mov    0x80110904,%edx
80104415:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104418:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010441a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104421:	eb 1b                	jmp    8010443e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80104423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104426:	83 c0 10             	add    $0x10,%eax
80104429:	8b 0c 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%ecx
80104430:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104433:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104436:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010443a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010443e:	a1 04 09 11 80       	mov    0x80110904,%eax
80104443:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104446:	7f db                	jg     80104423 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80104448:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010444b:	89 04 24             	mov    %eax,(%esp)
8010444e:	e8 8a bd ff ff       	call   801001dd <bwrite>
  brelse(buf);
80104453:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104456:	89 04 24             	mov    %eax,(%esp)
80104459:	e8 b9 bd ff ff       	call   80100217 <brelse>
}
8010445e:	c9                   	leave  
8010445f:	c3                   	ret    

80104460 <recover_from_log>:

static void
recover_from_log(void)
{
80104460:	55                   	push   %ebp
80104461:	89 e5                	mov    %esp,%ebp
80104463:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80104466:	e8 0b ff ff ff       	call   80104376 <read_head>
  install_trans(); // if committed, copy from log to disk
8010446b:	e8 5b fe ff ff       	call   801042cb <install_trans>
  log.lh.n = 0;
80104470:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
80104477:	00 00 00 
  write_head(); // clear the log
8010447a:	e8 66 ff ff ff       	call   801043e5 <write_head>
}
8010447f:	c9                   	leave  
80104480:	c3                   	ret    

80104481 <begin_trans>:

void
begin_trans(void)
{
80104481:	55                   	push   %ebp
80104482:	89 e5                	mov    %esp,%ebp
80104484:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80104487:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010448e:	e8 74 19 00 00       	call   80105e07 <acquire>
  while (log.busy) {
80104493:	eb 14                	jmp    801044a9 <begin_trans+0x28>
    sleep(&log, &log.lock);
80104495:	c7 44 24 04 c0 08 11 	movl   $0x801108c0,0x4(%esp)
8010449c:	80 
8010449d:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801044a4:	e8 80 16 00 00       	call   80105b29 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801044a9:	a1 fc 08 11 80       	mov    0x801108fc,%eax
801044ae:	85 c0                	test   %eax,%eax
801044b0:	75 e3                	jne    80104495 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801044b2:	c7 05 fc 08 11 80 01 	movl   $0x1,0x801108fc
801044b9:	00 00 00 
  release(&log.lock);
801044bc:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801044c3:	e8 a1 19 00 00       	call   80105e69 <release>
}
801044c8:	c9                   	leave  
801044c9:	c3                   	ret    

801044ca <commit_trans>:

void
commit_trans(void)
{
801044ca:	55                   	push   %ebp
801044cb:	89 e5                	mov    %esp,%ebp
801044cd:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801044d0:	a1 04 09 11 80       	mov    0x80110904,%eax
801044d5:	85 c0                	test   %eax,%eax
801044d7:	7e 19                	jle    801044f2 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801044d9:	e8 07 ff ff ff       	call   801043e5 <write_head>
    install_trans(); // Now install writes to home locations
801044de:	e8 e8 fd ff ff       	call   801042cb <install_trans>
    log.lh.n = 0; 
801044e3:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
801044ea:	00 00 00 
    write_head();    // Erase the transaction from the log
801044ed:	e8 f3 fe ff ff       	call   801043e5 <write_head>
  }
  
  acquire(&log.lock);
801044f2:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801044f9:	e8 09 19 00 00       	call   80105e07 <acquire>
  log.busy = 0;
801044fe:	c7 05 fc 08 11 80 00 	movl   $0x0,0x801108fc
80104505:	00 00 00 
  wakeup(&log);
80104508:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010450f:	e8 ee 16 00 00       	call   80105c02 <wakeup>
  release(&log.lock);
80104514:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010451b:	e8 49 19 00 00       	call   80105e69 <release>
}
80104520:	c9                   	leave  
80104521:	c3                   	ret    

80104522 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80104522:	55                   	push   %ebp
80104523:	89 e5                	mov    %esp,%ebp
80104525:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80104528:	a1 04 09 11 80       	mov    0x80110904,%eax
8010452d:	83 f8 09             	cmp    $0x9,%eax
80104530:	7f 12                	jg     80104544 <log_write+0x22>
80104532:	a1 04 09 11 80       	mov    0x80110904,%eax
80104537:	8b 15 f8 08 11 80    	mov    0x801108f8,%edx
8010453d:	83 ea 01             	sub    $0x1,%edx
80104540:	39 d0                	cmp    %edx,%eax
80104542:	7c 0c                	jl     80104550 <log_write+0x2e>
    panic("too big a transaction");
80104544:	c7 04 24 e4 98 10 80 	movl   $0x801098e4,(%esp)
8010454b:	e8 ed bf ff ff       	call   8010053d <panic>
  if (!log.busy)
80104550:	a1 fc 08 11 80       	mov    0x801108fc,%eax
80104555:	85 c0                	test   %eax,%eax
80104557:	75 0c                	jne    80104565 <log_write+0x43>
    panic("write outside of trans");
80104559:	c7 04 24 fa 98 10 80 	movl   $0x801098fa,(%esp)
80104560:	e8 d8 bf ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80104565:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010456c:	eb 1d                	jmp    8010458b <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010456e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104571:	83 c0 10             	add    $0x10,%eax
80104574:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
8010457b:	89 c2                	mov    %eax,%edx
8010457d:	8b 45 08             	mov    0x8(%ebp),%eax
80104580:	8b 40 08             	mov    0x8(%eax),%eax
80104583:	39 c2                	cmp    %eax,%edx
80104585:	74 10                	je     80104597 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80104587:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010458b:	a1 04 09 11 80       	mov    0x80110904,%eax
80104590:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104593:	7f d9                	jg     8010456e <log_write+0x4c>
80104595:	eb 01                	jmp    80104598 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80104597:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80104598:	8b 45 08             	mov    0x8(%ebp),%eax
8010459b:	8b 40 08             	mov    0x8(%eax),%eax
8010459e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045a1:	83 c2 10             	add    $0x10,%edx
801045a4:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801045ab:	a1 f4 08 11 80       	mov    0x801108f4,%eax
801045b0:	03 45 f4             	add    -0xc(%ebp),%eax
801045b3:	83 c0 01             	add    $0x1,%eax
801045b6:	89 c2                	mov    %eax,%edx
801045b8:	8b 45 08             	mov    0x8(%ebp),%eax
801045bb:	8b 40 04             	mov    0x4(%eax),%eax
801045be:	89 54 24 04          	mov    %edx,0x4(%esp)
801045c2:	89 04 24             	mov    %eax,(%esp)
801045c5:	e8 dc bb ff ff       	call   801001a6 <bread>
801045ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801045cd:	8b 45 08             	mov    0x8(%ebp),%eax
801045d0:	8d 50 18             	lea    0x18(%eax),%edx
801045d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045d6:	83 c0 18             	add    $0x18,%eax
801045d9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801045e0:	00 
801045e1:	89 54 24 04          	mov    %edx,0x4(%esp)
801045e5:	89 04 24             	mov    %eax,(%esp)
801045e8:	e8 3c 1b 00 00       	call   80106129 <memmove>
  bwrite(lbuf);
801045ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045f0:	89 04 24             	mov    %eax,(%esp)
801045f3:	e8 e5 bb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801045f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045fb:	89 04 24             	mov    %eax,(%esp)
801045fe:	e8 14 bc ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80104603:	a1 04 09 11 80       	mov    0x80110904,%eax
80104608:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010460b:	75 0d                	jne    8010461a <log_write+0xf8>
    log.lh.n++;
8010460d:	a1 04 09 11 80       	mov    0x80110904,%eax
80104612:	83 c0 01             	add    $0x1,%eax
80104615:	a3 04 09 11 80       	mov    %eax,0x80110904
  b->flags |= B_DIRTY; // XXX prevent eviction
8010461a:	8b 45 08             	mov    0x8(%ebp),%eax
8010461d:	8b 00                	mov    (%eax),%eax
8010461f:	89 c2                	mov    %eax,%edx
80104621:	83 ca 04             	or     $0x4,%edx
80104624:	8b 45 08             	mov    0x8(%ebp),%eax
80104627:	89 10                	mov    %edx,(%eax)
}
80104629:	c9                   	leave  
8010462a:	c3                   	ret    
	...

8010462c <v2p>:
8010462c:	55                   	push   %ebp
8010462d:	89 e5                	mov    %esp,%ebp
8010462f:	8b 45 08             	mov    0x8(%ebp),%eax
80104632:	05 00 00 00 80       	add    $0x80000000,%eax
80104637:	5d                   	pop    %ebp
80104638:	c3                   	ret    

80104639 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80104639:	55                   	push   %ebp
8010463a:	89 e5                	mov    %esp,%ebp
8010463c:	8b 45 08             	mov    0x8(%ebp),%eax
8010463f:	05 00 00 00 80       	add    $0x80000000,%eax
80104644:	5d                   	pop    %ebp
80104645:	c3                   	ret    

80104646 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104646:	55                   	push   %ebp
80104647:	89 e5                	mov    %esp,%ebp
80104649:	53                   	push   %ebx
8010464a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
8010464d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104650:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104653:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104656:	89 c3                	mov    %eax,%ebx
80104658:	89 d8                	mov    %ebx,%eax
8010465a:	f0 87 02             	lock xchg %eax,(%edx)
8010465d:	89 c3                	mov    %eax,%ebx
8010465f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104662:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104665:	83 c4 10             	add    $0x10,%esp
80104668:	5b                   	pop    %ebx
80104669:	5d                   	pop    %ebp
8010466a:	c3                   	ret    

8010466b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010466b:	55                   	push   %ebp
8010466c:	89 e5                	mov    %esp,%ebp
8010466e:	83 e4 f0             	and    $0xfffffff0,%esp
80104671:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80104674:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010467b:	80 
8010467c:	c7 04 24 3c 37 11 80 	movl   $0x8011373c,(%esp)
80104683:	e8 ad f5 ff ff       	call   80103c35 <kinit1>
  kvmalloc();      // kernel page table
80104688:	e8 9d 47 00 00       	call   80108e2a <kvmalloc>
  mpinit();        // collect info about this machine
8010468d:	e8 63 04 00 00       	call   80104af5 <mpinit>
  lapicinit(mpbcpu());
80104692:	e8 2e 02 00 00       	call   801048c5 <mpbcpu>
80104697:	89 04 24             	mov    %eax,(%esp)
8010469a:	e8 f5 f8 ff ff       	call   80103f94 <lapicinit>
  seginit();       // set up segments
8010469f:	e8 29 41 00 00       	call   801087cd <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801046a4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801046aa:	0f b6 00             	movzbl (%eax),%eax
801046ad:	0f b6 c0             	movzbl %al,%eax
801046b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801046b4:	c7 04 24 11 99 10 80 	movl   $0x80109911,(%esp)
801046bb:	e8 e1 bc ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801046c0:	e8 95 06 00 00       	call   80104d5a <picinit>
  ioapicinit();    // another interrupt controller
801046c5:	e8 5b f4 ff ff       	call   80103b25 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801046ca:	e8 be c3 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801046cf:	e8 44 34 00 00       	call   80107b18 <uartinit>
  pinit();         // process table
801046d4:	e8 96 0b 00 00       	call   8010526f <pinit>
  tvinit();        // trap vectors
801046d9:	e8 dd 2f 00 00       	call   801076bb <tvinit>
  binit();         // buffer cache
801046de:	e8 51 b9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801046e3:	e8 18 c8 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
801046e8:	e8 ce dc ff ff       	call   801023bb <iinit>
  ideinit();       // disk
801046ed:	e8 98 f0 ff ff       	call   8010378a <ideinit>
  if(!ismp)
801046f2:	a1 44 09 11 80       	mov    0x80110944,%eax
801046f7:	85 c0                	test   %eax,%eax
801046f9:	75 05                	jne    80104700 <main+0x95>
    timerinit();   // uniprocessor timer
801046fb:	e8 fe 2e 00 00       	call   801075fe <timerinit>
  startothers();   // start other processors
80104700:	e8 87 00 00 00       	call   8010478c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104705:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
8010470c:	8e 
8010470d:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104714:	e8 54 f5 ff ff       	call   80103c6d <kinit2>
  userinit();      // first user process
80104719:	e8 6c 0c 00 00       	call   8010538a <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010471e:	e8 22 00 00 00       	call   80104745 <mpmain>

80104723 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80104723:	55                   	push   %ebp
80104724:	89 e5                	mov    %esp,%ebp
80104726:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80104729:	e8 13 47 00 00       	call   80108e41 <switchkvm>
  seginit();
8010472e:	e8 9a 40 00 00       	call   801087cd <seginit>
  lapicinit(cpunum());
80104733:	e8 b9 f9 ff ff       	call   801040f1 <cpunum>
80104738:	89 04 24             	mov    %eax,(%esp)
8010473b:	e8 54 f8 ff ff       	call   80103f94 <lapicinit>
  mpmain();
80104740:	e8 00 00 00 00       	call   80104745 <mpmain>

80104745 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104745:	55                   	push   %ebp
80104746:	89 e5                	mov    %esp,%ebp
80104748:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010474b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104751:	0f b6 00             	movzbl (%eax),%eax
80104754:	0f b6 c0             	movzbl %al,%eax
80104757:	89 44 24 04          	mov    %eax,0x4(%esp)
8010475b:	c7 04 24 28 99 10 80 	movl   $0x80109928,(%esp)
80104762:	e8 3a bc ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80104767:	e8 c3 30 00 00       	call   8010782f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010476c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104772:	05 a8 00 00 00       	add    $0xa8,%eax
80104777:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010477e:	00 
8010477f:	89 04 24             	mov    %eax,(%esp)
80104782:	e8 bf fe ff ff       	call   80104646 <xchg>
  scheduler();     // start running processes
80104787:	e8 f4 11 00 00       	call   80105980 <scheduler>

8010478c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010478c:	55                   	push   %ebp
8010478d:	89 e5                	mov    %esp,%ebp
8010478f:	53                   	push   %ebx
80104790:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80104793:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010479a:	e8 9a fe ff ff       	call   80104639 <p2v>
8010479f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801047a2:	b8 8a 00 00 00       	mov    $0x8a,%eax
801047a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801047ab:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
801047b2:	80 
801047b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047b6:	89 04 24             	mov    %eax,(%esp)
801047b9:	e8 6b 19 00 00       	call   80106129 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801047be:	c7 45 f4 60 09 11 80 	movl   $0x80110960,-0xc(%ebp)
801047c5:	e9 86 00 00 00       	jmp    80104850 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801047ca:	e8 22 f9 ff ff       	call   801040f1 <cpunum>
801047cf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801047d5:	05 60 09 11 80       	add    $0x80110960,%eax
801047da:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801047dd:	74 69                	je     80104848 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801047df:	e8 7f f5 ff ff       	call   80103d63 <kalloc>
801047e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801047e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047ea:	83 e8 04             	sub    $0x4,%eax
801047ed:	8b 55 ec             	mov    -0x14(%ebp),%edx
801047f0:	81 c2 00 10 00 00    	add    $0x1000,%edx
801047f6:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801047f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047fb:	83 e8 08             	sub    $0x8,%eax
801047fe:	c7 00 23 47 10 80    	movl   $0x80104723,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104804:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104807:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010480a:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104811:	e8 16 fe ff ff       	call   8010462c <v2p>
80104816:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104818:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010481b:	89 04 24             	mov    %eax,(%esp)
8010481e:	e8 09 fe ff ff       	call   8010462c <v2p>
80104823:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104826:	0f b6 12             	movzbl (%edx),%edx
80104829:	0f b6 d2             	movzbl %dl,%edx
8010482c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104830:	89 14 24             	mov    %edx,(%esp)
80104833:	e8 3f f9 ff ff       	call   80104177 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104838:	90                   	nop
80104839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104842:	85 c0                	test   %eax,%eax
80104844:	74 f3                	je     80104839 <startothers+0xad>
80104846:	eb 01                	jmp    80104849 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80104848:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104849:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104850:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104855:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010485b:	05 60 09 11 80       	add    $0x80110960,%eax
80104860:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104863:	0f 87 61 ff ff ff    	ja     801047ca <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104869:	83 c4 24             	add    $0x24,%esp
8010486c:	5b                   	pop    %ebx
8010486d:	5d                   	pop    %ebp
8010486e:	c3                   	ret    
	...

80104870 <p2v>:
80104870:	55                   	push   %ebp
80104871:	89 e5                	mov    %esp,%ebp
80104873:	8b 45 08             	mov    0x8(%ebp),%eax
80104876:	05 00 00 00 80       	add    $0x80000000,%eax
8010487b:	5d                   	pop    %ebp
8010487c:	c3                   	ret    

8010487d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010487d:	55                   	push   %ebp
8010487e:	89 e5                	mov    %esp,%ebp
80104880:	53                   	push   %ebx
80104881:	83 ec 14             	sub    $0x14,%esp
80104884:	8b 45 08             	mov    0x8(%ebp),%eax
80104887:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010488b:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010488f:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80104893:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80104897:	ec                   	in     (%dx),%al
80104898:	89 c3                	mov    %eax,%ebx
8010489a:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
8010489d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801048a1:	83 c4 14             	add    $0x14,%esp
801048a4:	5b                   	pop    %ebx
801048a5:	5d                   	pop    %ebp
801048a6:	c3                   	ret    

801048a7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801048a7:	55                   	push   %ebp
801048a8:	89 e5                	mov    %esp,%ebp
801048aa:	83 ec 08             	sub    $0x8,%esp
801048ad:	8b 55 08             	mov    0x8(%ebp),%edx
801048b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801048b3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801048b7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801048ba:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801048be:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801048c2:	ee                   	out    %al,(%dx)
}
801048c3:	c9                   	leave  
801048c4:	c3                   	ret    

801048c5 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801048c5:	55                   	push   %ebp
801048c6:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801048c8:	a1 64 c6 10 80       	mov    0x8010c664,%eax
801048cd:	89 c2                	mov    %eax,%edx
801048cf:	b8 60 09 11 80       	mov    $0x80110960,%eax
801048d4:	89 d1                	mov    %edx,%ecx
801048d6:	29 c1                	sub    %eax,%ecx
801048d8:	89 c8                	mov    %ecx,%eax
801048da:	c1 f8 02             	sar    $0x2,%eax
801048dd:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801048e3:	5d                   	pop    %ebp
801048e4:	c3                   	ret    

801048e5 <sum>:

static uchar
sum(uchar *addr, int len)
{
801048e5:	55                   	push   %ebp
801048e6:	89 e5                	mov    %esp,%ebp
801048e8:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801048eb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801048f2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801048f9:	eb 13                	jmp    8010490e <sum+0x29>
    sum += addr[i];
801048fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801048fe:	03 45 08             	add    0x8(%ebp),%eax
80104901:	0f b6 00             	movzbl (%eax),%eax
80104904:	0f b6 c0             	movzbl %al,%eax
80104907:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010490a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010490e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104911:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104914:	7c e5                	jl     801048fb <sum+0x16>
    sum += addr[i];
  return sum;
80104916:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104919:	c9                   	leave  
8010491a:	c3                   	ret    

8010491b <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010491b:	55                   	push   %ebp
8010491c:	89 e5                	mov    %esp,%ebp
8010491e:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104921:	8b 45 08             	mov    0x8(%ebp),%eax
80104924:	89 04 24             	mov    %eax,(%esp)
80104927:	e8 44 ff ff ff       	call   80104870 <p2v>
8010492c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010492f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104932:	03 45 f0             	add    -0x10(%ebp),%eax
80104935:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104938:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010493b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010493e:	eb 3f                	jmp    8010497f <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104940:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104947:	00 
80104948:	c7 44 24 04 3c 99 10 	movl   $0x8010993c,0x4(%esp)
8010494f:	80 
80104950:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104953:	89 04 24             	mov    %eax,(%esp)
80104956:	e8 72 17 00 00       	call   801060cd <memcmp>
8010495b:	85 c0                	test   %eax,%eax
8010495d:	75 1c                	jne    8010497b <mpsearch1+0x60>
8010495f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104966:	00 
80104967:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010496a:	89 04 24             	mov    %eax,(%esp)
8010496d:	e8 73 ff ff ff       	call   801048e5 <sum>
80104972:	84 c0                	test   %al,%al
80104974:	75 05                	jne    8010497b <mpsearch1+0x60>
      return (struct mp*)p;
80104976:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104979:	eb 11                	jmp    8010498c <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010497b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010497f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104982:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104985:	72 b9                	jb     80104940 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80104987:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010498c:	c9                   	leave  
8010498d:	c3                   	ret    

8010498e <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
8010498e:	55                   	push   %ebp
8010498f:	89 e5                	mov    %esp,%ebp
80104991:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80104994:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010499b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499e:	83 c0 0f             	add    $0xf,%eax
801049a1:	0f b6 00             	movzbl (%eax),%eax
801049a4:	0f b6 c0             	movzbl %al,%eax
801049a7:	89 c2                	mov    %eax,%edx
801049a9:	c1 e2 08             	shl    $0x8,%edx
801049ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049af:	83 c0 0e             	add    $0xe,%eax
801049b2:	0f b6 00             	movzbl (%eax),%eax
801049b5:	0f b6 c0             	movzbl %al,%eax
801049b8:	09 d0                	or     %edx,%eax
801049ba:	c1 e0 04             	shl    $0x4,%eax
801049bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801049c0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801049c4:	74 21                	je     801049e7 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801049c6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801049cd:	00 
801049ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049d1:	89 04 24             	mov    %eax,(%esp)
801049d4:	e8 42 ff ff ff       	call   8010491b <mpsearch1>
801049d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049dc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801049e0:	74 50                	je     80104a32 <mpsearch+0xa4>
      return mp;
801049e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801049e5:	eb 5f                	jmp    80104a46 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801049e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ea:	83 c0 14             	add    $0x14,%eax
801049ed:	0f b6 00             	movzbl (%eax),%eax
801049f0:	0f b6 c0             	movzbl %al,%eax
801049f3:	89 c2                	mov    %eax,%edx
801049f5:	c1 e2 08             	shl    $0x8,%edx
801049f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fb:	83 c0 13             	add    $0x13,%eax
801049fe:	0f b6 00             	movzbl (%eax),%eax
80104a01:	0f b6 c0             	movzbl %al,%eax
80104a04:	09 d0                	or     %edx,%eax
80104a06:	c1 e0 0a             	shl    $0xa,%eax
80104a09:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104a0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a0f:	2d 00 04 00 00       	sub    $0x400,%eax
80104a14:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104a1b:	00 
80104a1c:	89 04 24             	mov    %eax,(%esp)
80104a1f:	e8 f7 fe ff ff       	call   8010491b <mpsearch1>
80104a24:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104a27:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104a2b:	74 05                	je     80104a32 <mpsearch+0xa4>
      return mp;
80104a2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a30:	eb 14                	jmp    80104a46 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104a32:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104a39:	00 
80104a3a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104a41:	e8 d5 fe ff ff       	call   8010491b <mpsearch1>
}
80104a46:	c9                   	leave  
80104a47:	c3                   	ret    

80104a48 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104a48:	55                   	push   %ebp
80104a49:	89 e5                	mov    %esp,%ebp
80104a4b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104a4e:	e8 3b ff ff ff       	call   8010498e <mpsearch>
80104a53:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a56:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a5a:	74 0a                	je     80104a66 <mpconfig+0x1e>
80104a5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5f:	8b 40 04             	mov    0x4(%eax),%eax
80104a62:	85 c0                	test   %eax,%eax
80104a64:	75 0a                	jne    80104a70 <mpconfig+0x28>
    return 0;
80104a66:	b8 00 00 00 00       	mov    $0x0,%eax
80104a6b:	e9 83 00 00 00       	jmp    80104af3 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104a70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a73:	8b 40 04             	mov    0x4(%eax),%eax
80104a76:	89 04 24             	mov    %eax,(%esp)
80104a79:	e8 f2 fd ff ff       	call   80104870 <p2v>
80104a7e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104a81:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104a88:	00 
80104a89:	c7 44 24 04 41 99 10 	movl   $0x80109941,0x4(%esp)
80104a90:	80 
80104a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a94:	89 04 24             	mov    %eax,(%esp)
80104a97:	e8 31 16 00 00       	call   801060cd <memcmp>
80104a9c:	85 c0                	test   %eax,%eax
80104a9e:	74 07                	je     80104aa7 <mpconfig+0x5f>
    return 0;
80104aa0:	b8 00 00 00 00       	mov    $0x0,%eax
80104aa5:	eb 4c                	jmp    80104af3 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80104aa7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aaa:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104aae:	3c 01                	cmp    $0x1,%al
80104ab0:	74 12                	je     80104ac4 <mpconfig+0x7c>
80104ab2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ab5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104ab9:	3c 04                	cmp    $0x4,%al
80104abb:	74 07                	je     80104ac4 <mpconfig+0x7c>
    return 0;
80104abd:	b8 00 00 00 00       	mov    $0x0,%eax
80104ac2:	eb 2f                	jmp    80104af3 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104ac4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ac7:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104acb:	0f b7 c0             	movzwl %ax,%eax
80104ace:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ad5:	89 04 24             	mov    %eax,(%esp)
80104ad8:	e8 08 fe ff ff       	call   801048e5 <sum>
80104add:	84 c0                	test   %al,%al
80104adf:	74 07                	je     80104ae8 <mpconfig+0xa0>
    return 0;
80104ae1:	b8 00 00 00 00       	mov    $0x0,%eax
80104ae6:	eb 0b                	jmp    80104af3 <mpconfig+0xab>
  *pmp = mp;
80104ae8:	8b 45 08             	mov    0x8(%ebp),%eax
80104aeb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104aee:	89 10                	mov    %edx,(%eax)
  return conf;
80104af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104af3:	c9                   	leave  
80104af4:	c3                   	ret    

80104af5 <mpinit>:

void
mpinit(void)
{
80104af5:	55                   	push   %ebp
80104af6:	89 e5                	mov    %esp,%ebp
80104af8:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104afb:	c7 05 64 c6 10 80 60 	movl   $0x80110960,0x8010c664
80104b02:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104b05:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104b08:	89 04 24             	mov    %eax,(%esp)
80104b0b:	e8 38 ff ff ff       	call   80104a48 <mpconfig>
80104b10:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104b13:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104b17:	0f 84 9c 01 00 00    	je     80104cb9 <mpinit+0x1c4>
    return;
  ismp = 1;
80104b1d:	c7 05 44 09 11 80 01 	movl   $0x1,0x80110944
80104b24:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104b27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b2a:	8b 40 24             	mov    0x24(%eax),%eax
80104b2d:	a3 bc 08 11 80       	mov    %eax,0x801108bc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b35:	83 c0 2c             	add    $0x2c,%eax
80104b38:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104b3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b3e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104b42:	0f b7 c0             	movzwl %ax,%eax
80104b45:	03 45 f0             	add    -0x10(%ebp),%eax
80104b48:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b4b:	e9 f4 00 00 00       	jmp    80104c44 <mpinit+0x14f>
    switch(*p){
80104b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b53:	0f b6 00             	movzbl (%eax),%eax
80104b56:	0f b6 c0             	movzbl %al,%eax
80104b59:	83 f8 04             	cmp    $0x4,%eax
80104b5c:	0f 87 bf 00 00 00    	ja     80104c21 <mpinit+0x12c>
80104b62:	8b 04 85 84 99 10 80 	mov    -0x7fef667c(,%eax,4),%eax
80104b69:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104b6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104b71:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b74:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104b78:	0f b6 d0             	movzbl %al,%edx
80104b7b:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b80:	39 c2                	cmp    %eax,%edx
80104b82:	74 2d                	je     80104bb1 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104b84:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b87:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104b8b:	0f b6 d0             	movzbl %al,%edx
80104b8e:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b93:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b97:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b9b:	c7 04 24 46 99 10 80 	movl   $0x80109946,(%esp)
80104ba2:	e8 fa b7 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104ba7:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
80104bae:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104bb1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104bb4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104bb8:	0f b6 c0             	movzbl %al,%eax
80104bbb:	83 e0 02             	and    $0x2,%eax
80104bbe:	85 c0                	test   %eax,%eax
80104bc0:	74 15                	je     80104bd7 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104bc2:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104bc7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104bcd:	05 60 09 11 80       	add    $0x80110960,%eax
80104bd2:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104bd7:	8b 15 40 0f 11 80    	mov    0x80110f40,%edx
80104bdd:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104be2:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104be8:	81 c2 60 09 11 80    	add    $0x80110960,%edx
80104bee:	88 02                	mov    %al,(%edx)
      ncpu++;
80104bf0:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104bf5:	83 c0 01             	add    $0x1,%eax
80104bf8:	a3 40 0f 11 80       	mov    %eax,0x80110f40
      p += sizeof(struct mpproc);
80104bfd:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104c01:	eb 41                	jmp    80104c44 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104c03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104c09:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104c0c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104c10:	a2 40 09 11 80       	mov    %al,0x80110940
      p += sizeof(struct mpioapic);
80104c15:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104c19:	eb 29                	jmp    80104c44 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104c1b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104c1f:	eb 23                	jmp    80104c44 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104c21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c24:	0f b6 00             	movzbl (%eax),%eax
80104c27:	0f b6 c0             	movzbl %al,%eax
80104c2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c2e:	c7 04 24 64 99 10 80 	movl   $0x80109964,(%esp)
80104c35:	e8 67 b7 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104c3a:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
80104c41:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c47:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104c4a:	0f 82 00 ff ff ff    	jb     80104b50 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104c50:	a1 44 09 11 80       	mov    0x80110944,%eax
80104c55:	85 c0                	test   %eax,%eax
80104c57:	75 1d                	jne    80104c76 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104c59:	c7 05 40 0f 11 80 01 	movl   $0x1,0x80110f40
80104c60:	00 00 00 
    lapic = 0;
80104c63:	c7 05 bc 08 11 80 00 	movl   $0x0,0x801108bc
80104c6a:	00 00 00 
    ioapicid = 0;
80104c6d:	c6 05 40 09 11 80 00 	movb   $0x0,0x80110940
    return;
80104c74:	eb 44                	jmp    80104cba <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104c76:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c79:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104c7d:	84 c0                	test   %al,%al
80104c7f:	74 39                	je     80104cba <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104c81:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104c88:	00 
80104c89:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104c90:	e8 12 fc ff ff       	call   801048a7 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104c95:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104c9c:	e8 dc fb ff ff       	call   8010487d <inb>
80104ca1:	83 c8 01             	or     $0x1,%eax
80104ca4:	0f b6 c0             	movzbl %al,%eax
80104ca7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cab:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104cb2:	e8 f0 fb ff ff       	call   801048a7 <outb>
80104cb7:	eb 01                	jmp    80104cba <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104cb9:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104cba:	c9                   	leave  
80104cbb:	c3                   	ret    

80104cbc <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104cbc:	55                   	push   %ebp
80104cbd:	89 e5                	mov    %esp,%ebp
80104cbf:	83 ec 08             	sub    $0x8,%esp
80104cc2:	8b 55 08             	mov    0x8(%ebp),%edx
80104cc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104cc8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104ccc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104ccf:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104cd3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104cd7:	ee                   	out    %al,(%dx)
}
80104cd8:	c9                   	leave  
80104cd9:	c3                   	ret    

80104cda <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104cda:	55                   	push   %ebp
80104cdb:	89 e5                	mov    %esp,%ebp
80104cdd:	83 ec 0c             	sub    $0xc,%esp
80104ce0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ce3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104ce7:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104ceb:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104cf1:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104cf5:	0f b6 c0             	movzbl %al,%eax
80104cf8:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cfc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d03:	e8 b4 ff ff ff       	call   80104cbc <outb>
  outb(IO_PIC2+1, mask >> 8);
80104d08:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104d0c:	66 c1 e8 08          	shr    $0x8,%ax
80104d10:	0f b6 c0             	movzbl %al,%eax
80104d13:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d17:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104d1e:	e8 99 ff ff ff       	call   80104cbc <outb>
}
80104d23:	c9                   	leave  
80104d24:	c3                   	ret    

80104d25 <picenable>:

void
picenable(int irq)
{
80104d25:	55                   	push   %ebp
80104d26:	89 e5                	mov    %esp,%ebp
80104d28:	53                   	push   %ebx
80104d29:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104d2c:	8b 45 08             	mov    0x8(%ebp),%eax
80104d2f:	ba 01 00 00 00       	mov    $0x1,%edx
80104d34:	89 d3                	mov    %edx,%ebx
80104d36:	89 c1                	mov    %eax,%ecx
80104d38:	d3 e3                	shl    %cl,%ebx
80104d3a:	89 d8                	mov    %ebx,%eax
80104d3c:	89 c2                	mov    %eax,%edx
80104d3e:	f7 d2                	not    %edx
80104d40:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104d47:	21 d0                	and    %edx,%eax
80104d49:	0f b7 c0             	movzwl %ax,%eax
80104d4c:	89 04 24             	mov    %eax,(%esp)
80104d4f:	e8 86 ff ff ff       	call   80104cda <picsetmask>
}
80104d54:	83 c4 04             	add    $0x4,%esp
80104d57:	5b                   	pop    %ebx
80104d58:	5d                   	pop    %ebp
80104d59:	c3                   	ret    

80104d5a <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104d5a:	55                   	push   %ebp
80104d5b:	89 e5                	mov    %esp,%ebp
80104d5d:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104d60:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104d67:	00 
80104d68:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d6f:	e8 48 ff ff ff       	call   80104cbc <outb>
  outb(IO_PIC2+1, 0xFF);
80104d74:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104d7b:	00 
80104d7c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104d83:	e8 34 ff ff ff       	call   80104cbc <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104d88:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104d8f:	00 
80104d90:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104d97:	e8 20 ff ff ff       	call   80104cbc <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104d9c:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104da3:	00 
80104da4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104dab:	e8 0c ff ff ff       	call   80104cbc <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104db0:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104db7:	00 
80104db8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104dbf:	e8 f8 fe ff ff       	call   80104cbc <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104dc4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104dcb:	00 
80104dcc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104dd3:	e8 e4 fe ff ff       	call   80104cbc <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104dd8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104ddf:	00 
80104de0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104de7:	e8 d0 fe ff ff       	call   80104cbc <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104dec:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104df3:	00 
80104df4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104dfb:	e8 bc fe ff ff       	call   80104cbc <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104e00:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104e07:	00 
80104e08:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e0f:	e8 a8 fe ff ff       	call   80104cbc <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104e14:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104e1b:	00 
80104e1c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e23:	e8 94 fe ff ff       	call   80104cbc <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104e28:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104e2f:	00 
80104e30:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104e37:	e8 80 fe ff ff       	call   80104cbc <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104e3c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104e43:	00 
80104e44:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104e4b:	e8 6c fe ff ff       	call   80104cbc <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104e50:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104e57:	00 
80104e58:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104e5f:	e8 58 fe ff ff       	call   80104cbc <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104e64:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104e6b:	00 
80104e6c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104e73:	e8 44 fe ff ff       	call   80104cbc <outb>

  if(irqmask != 0xFFFF)
80104e78:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104e7f:	66 83 f8 ff          	cmp    $0xffff,%ax
80104e83:	74 12                	je     80104e97 <picinit+0x13d>
    picsetmask(irqmask);
80104e85:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104e8c:	0f b7 c0             	movzwl %ax,%eax
80104e8f:	89 04 24             	mov    %eax,(%esp)
80104e92:	e8 43 fe ff ff       	call   80104cda <picsetmask>
}
80104e97:	c9                   	leave  
80104e98:	c3                   	ret    
80104e99:	00 00                	add    %al,(%eax)
	...

80104e9c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104e9c:	55                   	push   %ebp
80104e9d:	89 e5                	mov    %esp,%ebp
80104e9f:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104ea2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104ea9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104eb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eb5:	8b 10                	mov    (%eax),%edx
80104eb7:	8b 45 08             	mov    0x8(%ebp),%eax
80104eba:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104ebc:	e8 5b c0 ff ff       	call   80100f1c <filealloc>
80104ec1:	8b 55 08             	mov    0x8(%ebp),%edx
80104ec4:	89 02                	mov    %eax,(%edx)
80104ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec9:	8b 00                	mov    (%eax),%eax
80104ecb:	85 c0                	test   %eax,%eax
80104ecd:	0f 84 c8 00 00 00    	je     80104f9b <pipealloc+0xff>
80104ed3:	e8 44 c0 ff ff       	call   80100f1c <filealloc>
80104ed8:	8b 55 0c             	mov    0xc(%ebp),%edx
80104edb:	89 02                	mov    %eax,(%edx)
80104edd:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee0:	8b 00                	mov    (%eax),%eax
80104ee2:	85 c0                	test   %eax,%eax
80104ee4:	0f 84 b1 00 00 00    	je     80104f9b <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104eea:	e8 74 ee ff ff       	call   80103d63 <kalloc>
80104eef:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104ef2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104ef6:	0f 84 9e 00 00 00    	je     80104f9a <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104efc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eff:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104f06:	00 00 00 
  p->writeopen = 1;
80104f09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f0c:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104f13:	00 00 00 
  p->nwrite = 0;
80104f16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f19:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104f20:	00 00 00 
  p->nread = 0;
80104f23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f26:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104f2d:	00 00 00 
  initlock(&p->lock, "pipe");
80104f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f33:	c7 44 24 04 98 99 10 	movl   $0x80109998,0x4(%esp)
80104f3a:	80 
80104f3b:	89 04 24             	mov    %eax,(%esp)
80104f3e:	e8 a3 0e 00 00       	call   80105de6 <initlock>
  (*f0)->type = FD_PIPE;
80104f43:	8b 45 08             	mov    0x8(%ebp),%eax
80104f46:	8b 00                	mov    (%eax),%eax
80104f48:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104f4e:	8b 45 08             	mov    0x8(%ebp),%eax
80104f51:	8b 00                	mov    (%eax),%eax
80104f53:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104f57:	8b 45 08             	mov    0x8(%ebp),%eax
80104f5a:	8b 00                	mov    (%eax),%eax
80104f5c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104f60:	8b 45 08             	mov    0x8(%ebp),%eax
80104f63:	8b 00                	mov    (%eax),%eax
80104f65:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f68:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f6e:	8b 00                	mov    (%eax),%eax
80104f70:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104f76:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f79:	8b 00                	mov    (%eax),%eax
80104f7b:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104f7f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f82:	8b 00                	mov    (%eax),%eax
80104f84:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104f88:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f8b:	8b 00                	mov    (%eax),%eax
80104f8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f90:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104f93:	b8 00 00 00 00       	mov    $0x0,%eax
80104f98:	eb 43                	jmp    80104fdd <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104f9a:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104f9b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104f9f:	74 0b                	je     80104fac <pipealloc+0x110>
    kfree((char*)p);
80104fa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fa4:	89 04 24             	mov    %eax,(%esp)
80104fa7:	e8 1e ed ff ff       	call   80103cca <kfree>
  if(*f0)
80104fac:	8b 45 08             	mov    0x8(%ebp),%eax
80104faf:	8b 00                	mov    (%eax),%eax
80104fb1:	85 c0                	test   %eax,%eax
80104fb3:	74 0d                	je     80104fc2 <pipealloc+0x126>
    fileclose(*f0);
80104fb5:	8b 45 08             	mov    0x8(%ebp),%eax
80104fb8:	8b 00                	mov    (%eax),%eax
80104fba:	89 04 24             	mov    %eax,(%esp)
80104fbd:	e8 02 c0 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fc5:	8b 00                	mov    (%eax),%eax
80104fc7:	85 c0                	test   %eax,%eax
80104fc9:	74 0d                	je     80104fd8 <pipealloc+0x13c>
    fileclose(*f1);
80104fcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fce:	8b 00                	mov    (%eax),%eax
80104fd0:	89 04 24             	mov    %eax,(%esp)
80104fd3:	e8 ec bf ff ff       	call   80100fc4 <fileclose>
  return -1;
80104fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104fdd:	c9                   	leave  
80104fde:	c3                   	ret    

80104fdf <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104fdf:	55                   	push   %ebp
80104fe0:	89 e5                	mov    %esp,%ebp
80104fe2:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104fe5:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe8:	89 04 24             	mov    %eax,(%esp)
80104feb:	e8 17 0e 00 00       	call   80105e07 <acquire>
  if(writable){
80104ff0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104ff4:	74 1f                	je     80105015 <pipeclose+0x36>
    p->writeopen = 0;
80104ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff9:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80105000:	00 00 00 
    wakeup(&p->nread);
80105003:	8b 45 08             	mov    0x8(%ebp),%eax
80105006:	05 34 02 00 00       	add    $0x234,%eax
8010500b:	89 04 24             	mov    %eax,(%esp)
8010500e:	e8 ef 0b 00 00       	call   80105c02 <wakeup>
80105013:	eb 1d                	jmp    80105032 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80105015:	8b 45 08             	mov    0x8(%ebp),%eax
80105018:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010501f:	00 00 00 
    wakeup(&p->nwrite);
80105022:	8b 45 08             	mov    0x8(%ebp),%eax
80105025:	05 38 02 00 00       	add    $0x238,%eax
8010502a:	89 04 24             	mov    %eax,(%esp)
8010502d:	e8 d0 0b 00 00       	call   80105c02 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80105032:	8b 45 08             	mov    0x8(%ebp),%eax
80105035:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010503b:	85 c0                	test   %eax,%eax
8010503d:	75 25                	jne    80105064 <pipeclose+0x85>
8010503f:	8b 45 08             	mov    0x8(%ebp),%eax
80105042:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80105048:	85 c0                	test   %eax,%eax
8010504a:	75 18                	jne    80105064 <pipeclose+0x85>
    release(&p->lock);
8010504c:	8b 45 08             	mov    0x8(%ebp),%eax
8010504f:	89 04 24             	mov    %eax,(%esp)
80105052:	e8 12 0e 00 00       	call   80105e69 <release>
    kfree((char*)p);
80105057:	8b 45 08             	mov    0x8(%ebp),%eax
8010505a:	89 04 24             	mov    %eax,(%esp)
8010505d:	e8 68 ec ff ff       	call   80103cca <kfree>
80105062:	eb 0b                	jmp    8010506f <pipeclose+0x90>
  } else
    release(&p->lock);
80105064:	8b 45 08             	mov    0x8(%ebp),%eax
80105067:	89 04 24             	mov    %eax,(%esp)
8010506a:	e8 fa 0d 00 00       	call   80105e69 <release>
}
8010506f:	c9                   	leave  
80105070:	c3                   	ret    

80105071 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80105071:	55                   	push   %ebp
80105072:	89 e5                	mov    %esp,%ebp
80105074:	53                   	push   %ebx
80105075:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80105078:	8b 45 08             	mov    0x8(%ebp),%eax
8010507b:	89 04 24             	mov    %eax,(%esp)
8010507e:	e8 84 0d 00 00       	call   80105e07 <acquire>
  for(i = 0; i < n; i++){
80105083:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010508a:	e9 a6 00 00 00       	jmp    80105135 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
8010508f:	8b 45 08             	mov    0x8(%ebp),%eax
80105092:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80105098:	85 c0                	test   %eax,%eax
8010509a:	74 0d                	je     801050a9 <pipewrite+0x38>
8010509c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050a2:	8b 40 24             	mov    0x24(%eax),%eax
801050a5:	85 c0                	test   %eax,%eax
801050a7:	74 15                	je     801050be <pipewrite+0x4d>
        release(&p->lock);
801050a9:	8b 45 08             	mov    0x8(%ebp),%eax
801050ac:	89 04 24             	mov    %eax,(%esp)
801050af:	e8 b5 0d 00 00       	call   80105e69 <release>
        return -1;
801050b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050b9:	e9 9d 00 00 00       	jmp    8010515b <pipewrite+0xea>
      }
      wakeup(&p->nread);
801050be:	8b 45 08             	mov    0x8(%ebp),%eax
801050c1:	05 34 02 00 00       	add    $0x234,%eax
801050c6:	89 04 24             	mov    %eax,(%esp)
801050c9:	e8 34 0b 00 00       	call   80105c02 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801050ce:	8b 45 08             	mov    0x8(%ebp),%eax
801050d1:	8b 55 08             	mov    0x8(%ebp),%edx
801050d4:	81 c2 38 02 00 00    	add    $0x238,%edx
801050da:	89 44 24 04          	mov    %eax,0x4(%esp)
801050de:	89 14 24             	mov    %edx,(%esp)
801050e1:	e8 43 0a 00 00       	call   80105b29 <sleep>
801050e6:	eb 01                	jmp    801050e9 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801050e8:	90                   	nop
801050e9:	8b 45 08             	mov    0x8(%ebp),%eax
801050ec:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801050f2:	8b 45 08             	mov    0x8(%ebp),%eax
801050f5:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801050fb:	05 00 02 00 00       	add    $0x200,%eax
80105100:	39 c2                	cmp    %eax,%edx
80105102:	74 8b                	je     8010508f <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80105104:	8b 45 08             	mov    0x8(%ebp),%eax
80105107:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010510d:	89 c3                	mov    %eax,%ebx
8010510f:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80105115:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105118:	03 55 0c             	add    0xc(%ebp),%edx
8010511b:	0f b6 0a             	movzbl (%edx),%ecx
8010511e:	8b 55 08             	mov    0x8(%ebp),%edx
80105121:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80105125:	8d 50 01             	lea    0x1(%eax),%edx
80105128:	8b 45 08             	mov    0x8(%ebp),%eax
8010512b:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80105131:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105135:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105138:	3b 45 10             	cmp    0x10(%ebp),%eax
8010513b:	7c ab                	jl     801050e8 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010513d:	8b 45 08             	mov    0x8(%ebp),%eax
80105140:	05 34 02 00 00       	add    $0x234,%eax
80105145:	89 04 24             	mov    %eax,(%esp)
80105148:	e8 b5 0a 00 00       	call   80105c02 <wakeup>
  release(&p->lock);
8010514d:	8b 45 08             	mov    0x8(%ebp),%eax
80105150:	89 04 24             	mov    %eax,(%esp)
80105153:	e8 11 0d 00 00       	call   80105e69 <release>
  return n;
80105158:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010515b:	83 c4 24             	add    $0x24,%esp
8010515e:	5b                   	pop    %ebx
8010515f:	5d                   	pop    %ebp
80105160:	c3                   	ret    

80105161 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80105161:	55                   	push   %ebp
80105162:	89 e5                	mov    %esp,%ebp
80105164:	53                   	push   %ebx
80105165:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80105168:	8b 45 08             	mov    0x8(%ebp),%eax
8010516b:	89 04 24             	mov    %eax,(%esp)
8010516e:	e8 94 0c 00 00       	call   80105e07 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80105173:	eb 3a                	jmp    801051af <piperead+0x4e>
    if(proc->killed){
80105175:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010517b:	8b 40 24             	mov    0x24(%eax),%eax
8010517e:	85 c0                	test   %eax,%eax
80105180:	74 15                	je     80105197 <piperead+0x36>
      release(&p->lock);
80105182:	8b 45 08             	mov    0x8(%ebp),%eax
80105185:	89 04 24             	mov    %eax,(%esp)
80105188:	e8 dc 0c 00 00       	call   80105e69 <release>
      return -1;
8010518d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105192:	e9 b6 00 00 00       	jmp    8010524d <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80105197:	8b 45 08             	mov    0x8(%ebp),%eax
8010519a:	8b 55 08             	mov    0x8(%ebp),%edx
8010519d:	81 c2 34 02 00 00    	add    $0x234,%edx
801051a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801051a7:	89 14 24             	mov    %edx,(%esp)
801051aa:	e8 7a 09 00 00       	call   80105b29 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801051af:	8b 45 08             	mov    0x8(%ebp),%eax
801051b2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801051b8:	8b 45 08             	mov    0x8(%ebp),%eax
801051bb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801051c1:	39 c2                	cmp    %eax,%edx
801051c3:	75 0d                	jne    801051d2 <piperead+0x71>
801051c5:	8b 45 08             	mov    0x8(%ebp),%eax
801051c8:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801051ce:	85 c0                	test   %eax,%eax
801051d0:	75 a3                	jne    80105175 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801051d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801051d9:	eb 49                	jmp    80105224 <piperead+0xc3>
    if(p->nread == p->nwrite)
801051db:	8b 45 08             	mov    0x8(%ebp),%eax
801051de:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801051e4:	8b 45 08             	mov    0x8(%ebp),%eax
801051e7:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801051ed:	39 c2                	cmp    %eax,%edx
801051ef:	74 3d                	je     8010522e <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801051f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051f4:	89 c2                	mov    %eax,%edx
801051f6:	03 55 0c             	add    0xc(%ebp),%edx
801051f9:	8b 45 08             	mov    0x8(%ebp),%eax
801051fc:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80105202:	89 c3                	mov    %eax,%ebx
80105204:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010520a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010520d:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80105212:	88 0a                	mov    %cl,(%edx)
80105214:	8d 50 01             	lea    0x1(%eax),%edx
80105217:	8b 45 08             	mov    0x8(%ebp),%eax
8010521a:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105220:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105227:	3b 45 10             	cmp    0x10(%ebp),%eax
8010522a:	7c af                	jl     801051db <piperead+0x7a>
8010522c:	eb 01                	jmp    8010522f <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
8010522e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010522f:	8b 45 08             	mov    0x8(%ebp),%eax
80105232:	05 38 02 00 00       	add    $0x238,%eax
80105237:	89 04 24             	mov    %eax,(%esp)
8010523a:	e8 c3 09 00 00       	call   80105c02 <wakeup>
  release(&p->lock);
8010523f:	8b 45 08             	mov    0x8(%ebp),%eax
80105242:	89 04 24             	mov    %eax,(%esp)
80105245:	e8 1f 0c 00 00       	call   80105e69 <release>
  return i;
8010524a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010524d:	83 c4 24             	add    $0x24,%esp
80105250:	5b                   	pop    %ebx
80105251:	5d                   	pop    %ebp
80105252:	c3                   	ret    
	...

80105254 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105254:	55                   	push   %ebp
80105255:	89 e5                	mov    %esp,%ebp
80105257:	53                   	push   %ebx
80105258:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010525b:	9c                   	pushf  
8010525c:	5b                   	pop    %ebx
8010525d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105260:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105263:	83 c4 10             	add    $0x10,%esp
80105266:	5b                   	pop    %ebx
80105267:	5d                   	pop    %ebp
80105268:	c3                   	ret    

80105269 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80105269:	55                   	push   %ebp
8010526a:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010526c:	fb                   	sti    
}
8010526d:	5d                   	pop    %ebp
8010526e:	c3                   	ret    

8010526f <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010526f:	55                   	push   %ebp
80105270:	89 e5                	mov    %esp,%ebp
80105272:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80105275:	c7 44 24 04 9d 99 10 	movl   $0x8010999d,0x4(%esp)
8010527c:	80 
8010527d:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105284:	e8 5d 0b 00 00       	call   80105de6 <initlock>
}
80105289:	c9                   	leave  
8010528a:	c3                   	ret    

8010528b <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010528b:	55                   	push   %ebp
8010528c:	89 e5                	mov    %esp,%ebp
8010528e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80105291:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105298:	e8 6a 0b 00 00       	call   80105e07 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010529d:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
801052a4:	eb 0e                	jmp    801052b4 <allocproc+0x29>
    if(p->state == UNUSED)
801052a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052a9:	8b 40 0c             	mov    0xc(%eax),%eax
801052ac:	85 c0                	test   %eax,%eax
801052ae:	74 23                	je     801052d3 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801052b0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801052b4:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
801052bb:	72 e9                	jb     801052a6 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801052bd:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801052c4:	e8 a0 0b 00 00       	call   80105e69 <release>
  return 0;
801052c9:	b8 00 00 00 00       	mov    $0x0,%eax
801052ce:	e9 b5 00 00 00       	jmp    80105388 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801052d3:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801052d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d7:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801052de:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801052e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052e6:	89 42 10             	mov    %eax,0x10(%edx)
801052e9:	83 c0 01             	add    $0x1,%eax
801052ec:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801052f1:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801052f8:	e8 6c 0b 00 00       	call   80105e69 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801052fd:	e8 61 ea ff ff       	call   80103d63 <kalloc>
80105302:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105305:	89 42 08             	mov    %eax,0x8(%edx)
80105308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010530b:	8b 40 08             	mov    0x8(%eax),%eax
8010530e:	85 c0                	test   %eax,%eax
80105310:	75 11                	jne    80105323 <allocproc+0x98>
    p->state = UNUSED;
80105312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105315:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
8010531c:	b8 00 00 00 00       	mov    $0x0,%eax
80105321:	eb 65                	jmp    80105388 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80105323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105326:	8b 40 08             	mov    0x8(%eax),%eax
80105329:	05 00 10 00 00       	add    $0x1000,%eax
8010532e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80105331:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80105335:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105338:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010533b:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
8010533e:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80105342:	ba 70 76 10 80       	mov    $0x80107670,%edx
80105347:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010534a:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
8010534c:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80105350:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105353:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105356:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80105359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010535c:	8b 40 1c             	mov    0x1c(%eax),%eax
8010535f:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105366:	00 
80105367:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010536e:	00 
8010536f:	89 04 24             	mov    %eax,(%esp)
80105372:	e8 df 0c 00 00       	call   80106056 <memset>
  p->context->eip = (uint)forkret;
80105377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010537a:	8b 40 1c             	mov    0x1c(%eax),%eax
8010537d:	ba fd 5a 10 80       	mov    $0x80105afd,%edx
80105382:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80105385:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105388:	c9                   	leave  
80105389:	c3                   	ret    

8010538a <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010538a:	55                   	push   %ebp
8010538b:	89 e5                	mov    %esp,%ebp
8010538d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80105390:	e8 f6 fe ff ff       	call   8010528b <allocproc>
80105395:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80105398:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010539b:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
801053a0:	c7 04 24 63 3d 10 80 	movl   $0x80103d63,(%esp)
801053a7:	e8 c1 39 00 00       	call   80108d6d <setupkvm>
801053ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053af:	89 42 04             	mov    %eax,0x4(%edx)
801053b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053b5:	8b 40 04             	mov    0x4(%eax),%eax
801053b8:	85 c0                	test   %eax,%eax
801053ba:	75 0c                	jne    801053c8 <userinit+0x3e>
    panic("userinit: out of memory?");
801053bc:	c7 04 24 a4 99 10 80 	movl   $0x801099a4,(%esp)
801053c3:	e8 75 b1 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801053c8:	ba 2c 00 00 00       	mov    $0x2c,%edx
801053cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053d0:	8b 40 04             	mov    0x4(%eax),%eax
801053d3:	89 54 24 08          	mov    %edx,0x8(%esp)
801053d7:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
801053de:	80 
801053df:	89 04 24             	mov    %eax,(%esp)
801053e2:	e8 de 3b 00 00       	call   80108fc5 <inituvm>
  p->sz = PGSIZE;
801053e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053ea:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801053f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053f3:	8b 40 18             	mov    0x18(%eax),%eax
801053f6:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801053fd:	00 
801053fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105405:	00 
80105406:	89 04 24             	mov    %eax,(%esp)
80105409:	e8 48 0c 00 00       	call   80106056 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010540e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105411:	8b 40 18             	mov    0x18(%eax),%eax
80105414:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010541a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010541d:	8b 40 18             	mov    0x18(%eax),%eax
80105420:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80105426:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105429:	8b 40 18             	mov    0x18(%eax),%eax
8010542c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010542f:	8b 52 18             	mov    0x18(%edx),%edx
80105432:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105436:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010543a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010543d:	8b 40 18             	mov    0x18(%eax),%eax
80105440:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105443:	8b 52 18             	mov    0x18(%edx),%edx
80105446:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010544a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010544e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105451:	8b 40 18             	mov    0x18(%eax),%eax
80105454:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010545b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010545e:	8b 40 18             	mov    0x18(%eax),%eax
80105461:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80105468:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546b:	8b 40 18             	mov    0x18(%eax),%eax
8010546e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105475:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105478:	83 c0 6c             	add    $0x6c,%eax
8010547b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105482:	00 
80105483:	c7 44 24 04 bd 99 10 	movl   $0x801099bd,0x4(%esp)
8010548a:	80 
8010548b:	89 04 24             	mov    %eax,(%esp)
8010548e:	e8 f3 0d 00 00       	call   80106286 <safestrcpy>
  p->cwd = namei("/");
80105493:	c7 04 24 c6 99 10 80 	movl   $0x801099c6,(%esp)
8010549a:	e8 82 de ff ff       	call   80103321 <namei>
8010549f:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054a2:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801054a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801054af:	c9                   	leave  
801054b0:	c3                   	ret    

801054b1 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801054b1:	55                   	push   %ebp
801054b2:	89 e5                	mov    %esp,%ebp
801054b4:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801054b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bd:	8b 00                	mov    (%eax),%eax
801054bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801054c2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801054c6:	7e 34                	jle    801054fc <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801054c8:	8b 45 08             	mov    0x8(%ebp),%eax
801054cb:	89 c2                	mov    %eax,%edx
801054cd:	03 55 f4             	add    -0xc(%ebp),%edx
801054d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054d6:	8b 40 04             	mov    0x4(%eax),%eax
801054d9:	89 54 24 08          	mov    %edx,0x8(%esp)
801054dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801054e4:	89 04 24             	mov    %eax,(%esp)
801054e7:	e8 53 3c 00 00       	call   8010913f <allocuvm>
801054ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054ef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801054f3:	75 41                	jne    80105536 <growproc+0x85>
      return -1;
801054f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054fa:	eb 58                	jmp    80105554 <growproc+0xa3>
  } else if(n < 0){
801054fc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105500:	79 34                	jns    80105536 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80105502:	8b 45 08             	mov    0x8(%ebp),%eax
80105505:	89 c2                	mov    %eax,%edx
80105507:	03 55 f4             	add    -0xc(%ebp),%edx
8010550a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105510:	8b 40 04             	mov    0x4(%eax),%eax
80105513:	89 54 24 08          	mov    %edx,0x8(%esp)
80105517:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010551a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010551e:	89 04 24             	mov    %eax,(%esp)
80105521:	e8 f3 3c 00 00       	call   80109219 <deallocuvm>
80105526:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105529:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010552d:	75 07                	jne    80105536 <growproc+0x85>
      return -1;
8010552f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105534:	eb 1e                	jmp    80105554 <growproc+0xa3>
  }
  proc->sz = sz;
80105536:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010553f:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105541:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105547:	89 04 24             	mov    %eax,(%esp)
8010554a:	e8 0f 39 00 00       	call   80108e5e <switchuvm>
  return 0;
8010554f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105554:	c9                   	leave  
80105555:	c3                   	ret    

80105556 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80105556:	55                   	push   %ebp
80105557:	89 e5                	mov    %esp,%ebp
80105559:	57                   	push   %edi
8010555a:	56                   	push   %esi
8010555b:	53                   	push   %ebx
8010555c:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
8010555f:	e8 27 fd ff ff       	call   8010528b <allocproc>
80105564:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105567:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010556b:	75 0a                	jne    80105577 <fork+0x21>
    return -1;
8010556d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105572:	e9 3a 01 00 00       	jmp    801056b1 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80105577:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010557d:	8b 10                	mov    (%eax),%edx
8010557f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105585:	8b 40 04             	mov    0x4(%eax),%eax
80105588:	89 54 24 04          	mov    %edx,0x4(%esp)
8010558c:	89 04 24             	mov    %eax,(%esp)
8010558f:	e8 15 3e 00 00       	call   801093a9 <copyuvm>
80105594:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105597:	89 42 04             	mov    %eax,0x4(%edx)
8010559a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010559d:	8b 40 04             	mov    0x4(%eax),%eax
801055a0:	85 c0                	test   %eax,%eax
801055a2:	75 2c                	jne    801055d0 <fork+0x7a>
    kfree(np->kstack);
801055a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055a7:	8b 40 08             	mov    0x8(%eax),%eax
801055aa:	89 04 24             	mov    %eax,(%esp)
801055ad:	e8 18 e7 ff ff       	call   80103cca <kfree>
    np->kstack = 0;
801055b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055b5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801055bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055bf:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801055c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055cb:	e9 e1 00 00 00       	jmp    801056b1 <fork+0x15b>
  }
  np->sz = proc->sz;
801055d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055d6:	8b 10                	mov    (%eax),%edx
801055d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055db:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801055dd:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801055e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055e7:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801055ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055ed:	8b 50 18             	mov    0x18(%eax),%edx
801055f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055f6:	8b 40 18             	mov    0x18(%eax),%eax
801055f9:	89 c3                	mov    %eax,%ebx
801055fb:	b8 13 00 00 00       	mov    $0x13,%eax
80105600:	89 d7                	mov    %edx,%edi
80105602:	89 de                	mov    %ebx,%esi
80105604:	89 c1                	mov    %eax,%ecx
80105606:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80105608:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010560b:	8b 40 18             	mov    0x18(%eax),%eax
8010560e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105615:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010561c:	eb 3d                	jmp    8010565b <fork+0x105>
    if(proc->ofile[i])
8010561e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105624:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105627:	83 c2 08             	add    $0x8,%edx
8010562a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010562e:	85 c0                	test   %eax,%eax
80105630:	74 25                	je     80105657 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105632:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105638:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010563b:	83 c2 08             	add    $0x8,%edx
8010563e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105642:	89 04 24             	mov    %eax,(%esp)
80105645:	e8 32 b9 ff ff       	call   80100f7c <filedup>
8010564a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010564d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105650:	83 c1 08             	add    $0x8,%ecx
80105653:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80105657:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010565b:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010565f:	7e bd                	jle    8010561e <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105661:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105667:	8b 40 68             	mov    0x68(%eax),%eax
8010566a:	89 04 24             	mov    %eax,(%esp)
8010566d:	e8 cc cf ff ff       	call   8010263e <idup>
80105672:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105675:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80105678:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010567b:	8b 40 10             	mov    0x10(%eax),%eax
8010567e:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105681:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105684:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010568b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105691:	8d 50 6c             	lea    0x6c(%eax),%edx
80105694:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105697:	83 c0 6c             	add    $0x6c,%eax
8010569a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801056a1:	00 
801056a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801056a6:	89 04 24             	mov    %eax,(%esp)
801056a9:	e8 d8 0b 00 00       	call   80106286 <safestrcpy>
  return pid;
801056ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801056b1:	83 c4 2c             	add    $0x2c,%esp
801056b4:	5b                   	pop    %ebx
801056b5:	5e                   	pop    %esi
801056b6:	5f                   	pop    %edi
801056b7:	5d                   	pop    %ebp
801056b8:	c3                   	ret    

801056b9 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801056b9:	55                   	push   %ebp
801056ba:	89 e5                	mov    %esp,%ebp
801056bc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801056bf:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056c6:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801056cb:	39 c2                	cmp    %eax,%edx
801056cd:	75 0c                	jne    801056db <exit+0x22>
    panic("init exiting");
801056cf:	c7 04 24 c8 99 10 80 	movl   $0x801099c8,(%esp)
801056d6:	e8 62 ae ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801056db:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801056e2:	eb 44                	jmp    80105728 <exit+0x6f>
    if(proc->ofile[fd]){
801056e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056ed:	83 c2 08             	add    $0x8,%edx
801056f0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801056f4:	85 c0                	test   %eax,%eax
801056f6:	74 2c                	je     80105724 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801056f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056fe:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105701:	83 c2 08             	add    $0x8,%edx
80105704:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105708:	89 04 24             	mov    %eax,(%esp)
8010570b:	e8 b4 b8 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105710:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105716:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105719:	83 c2 08             	add    $0x8,%edx
8010571c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105723:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105724:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105728:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010572c:	7e b6                	jle    801056e4 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010572e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105734:	8b 40 68             	mov    0x68(%eax),%eax
80105737:	89 04 24             	mov    %eax,(%esp)
8010573a:	e8 e4 d0 ff ff       	call   80102823 <iput>
  proc->cwd = 0;
8010573f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105745:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
8010574c:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105753:	e8 af 06 00 00       	call   80105e07 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80105758:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010575e:	8b 40 14             	mov    0x14(%eax),%eax
80105761:	89 04 24             	mov    %eax,(%esp)
80105764:	e8 5b 04 00 00       	call   80105bc4 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105769:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105770:	eb 38                	jmp    801057aa <exit+0xf1>
    if(p->parent == proc){
80105772:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105775:	8b 50 14             	mov    0x14(%eax),%edx
80105778:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010577e:	39 c2                	cmp    %eax,%edx
80105780:	75 24                	jne    801057a6 <exit+0xed>
      p->parent = initproc;
80105782:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
80105788:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010578b:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010578e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105791:	8b 40 0c             	mov    0xc(%eax),%eax
80105794:	83 f8 05             	cmp    $0x5,%eax
80105797:	75 0d                	jne    801057a6 <exit+0xed>
        wakeup1(initproc);
80105799:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010579e:	89 04 24             	mov    %eax,(%esp)
801057a1:	e8 1e 04 00 00       	call   80105bc4 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057a6:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801057aa:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
801057b1:	72 bf                	jb     80105772 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801057b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057b9:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801057c0:	e8 54 02 00 00       	call   80105a19 <sched>
  panic("zombie exit");
801057c5:	c7 04 24 d5 99 10 80 	movl   $0x801099d5,(%esp)
801057cc:	e8 6c ad ff ff       	call   8010053d <panic>

801057d1 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801057d1:	55                   	push   %ebp
801057d2:	89 e5                	mov    %esp,%ebp
801057d4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801057d7:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801057de:	e8 24 06 00 00       	call   80105e07 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801057e3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057ea:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
801057f1:	e9 9a 00 00 00       	jmp    80105890 <wait+0xbf>
      if(p->parent != proc)
801057f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f9:	8b 50 14             	mov    0x14(%eax),%edx
801057fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105802:	39 c2                	cmp    %eax,%edx
80105804:	0f 85 81 00 00 00    	jne    8010588b <wait+0xba>
        continue;
      havekids = 1;
8010580a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105814:	8b 40 0c             	mov    0xc(%eax),%eax
80105817:	83 f8 05             	cmp    $0x5,%eax
8010581a:	75 70                	jne    8010588c <wait+0xbb>
        // Found one.
        pid = p->pid;
8010581c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010581f:	8b 40 10             	mov    0x10(%eax),%eax
80105822:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105825:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105828:	8b 40 08             	mov    0x8(%eax),%eax
8010582b:	89 04 24             	mov    %eax,(%esp)
8010582e:	e8 97 e4 ff ff       	call   80103cca <kfree>
        p->kstack = 0;
80105833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105836:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
8010583d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105840:	8b 40 04             	mov    0x4(%eax),%eax
80105843:	89 04 24             	mov    %eax,(%esp)
80105846:	e8 8a 3a 00 00       	call   801092d5 <freevm>
        p->state = UNUSED;
8010584b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010584e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105858:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010585f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105862:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80105869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010586c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105873:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010587a:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105881:	e8 e3 05 00 00       	call   80105e69 <release>
        return pid;
80105886:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105889:	eb 53                	jmp    801058de <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010588b:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010588c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105890:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105897:	0f 82 59 ff ff ff    	jb     801057f6 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
8010589d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058a1:	74 0d                	je     801058b0 <wait+0xdf>
801058a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058a9:	8b 40 24             	mov    0x24(%eax),%eax
801058ac:	85 c0                	test   %eax,%eax
801058ae:	74 13                	je     801058c3 <wait+0xf2>
      release(&ptable.lock);
801058b0:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801058b7:	e8 ad 05 00 00       	call   80105e69 <release>
      return -1;
801058bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058c1:	eb 1b                	jmp    801058de <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801058c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058c9:	c7 44 24 04 60 0f 11 	movl   $0x80110f60,0x4(%esp)
801058d0:	80 
801058d1:	89 04 24             	mov    %eax,(%esp)
801058d4:	e8 50 02 00 00       	call   80105b29 <sleep>
  }
801058d9:	e9 05 ff ff ff       	jmp    801057e3 <wait+0x12>
}
801058de:	c9                   	leave  
801058df:	c3                   	ret    

801058e0 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801058e0:	55                   	push   %ebp
801058e1:	89 e5                	mov    %esp,%ebp
801058e3:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801058e6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ec:	8b 40 18             	mov    0x18(%eax),%eax
801058ef:	8b 40 44             	mov    0x44(%eax),%eax
801058f2:	89 c2                	mov    %eax,%edx
801058f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058fa:	8b 40 04             	mov    0x4(%eax),%eax
801058fd:	89 54 24 04          	mov    %edx,0x4(%esp)
80105901:	89 04 24             	mov    %eax,(%esp)
80105904:	e8 b1 3b 00 00       	call   801094ba <uva2ka>
80105909:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
8010590c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105912:	8b 40 18             	mov    0x18(%eax),%eax
80105915:	8b 40 44             	mov    0x44(%eax),%eax
80105918:	25 ff 0f 00 00       	and    $0xfff,%eax
8010591d:	85 c0                	test   %eax,%eax
8010591f:	75 0c                	jne    8010592d <register_handler+0x4d>
    panic("esp_offset == 0");
80105921:	c7 04 24 e1 99 10 80 	movl   $0x801099e1,(%esp)
80105928:	e8 10 ac ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
8010592d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105933:	8b 40 18             	mov    0x18(%eax),%eax
80105936:	8b 40 44             	mov    0x44(%eax),%eax
80105939:	83 e8 04             	sub    $0x4,%eax
8010593c:	25 ff 0f 00 00       	and    $0xfff,%eax
80105941:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105944:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010594b:	8b 52 18             	mov    0x18(%edx),%edx
8010594e:	8b 52 38             	mov    0x38(%edx),%edx
80105951:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105953:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105959:	8b 40 18             	mov    0x18(%eax),%eax
8010595c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105963:	8b 52 18             	mov    0x18(%edx),%edx
80105966:	8b 52 44             	mov    0x44(%edx),%edx
80105969:	83 ea 04             	sub    $0x4,%edx
8010596c:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010596f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105975:	8b 40 18             	mov    0x18(%eax),%eax
80105978:	8b 55 08             	mov    0x8(%ebp),%edx
8010597b:	89 50 38             	mov    %edx,0x38(%eax)
}
8010597e:	c9                   	leave  
8010597f:	c3                   	ret    

80105980 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105980:	55                   	push   %ebp
80105981:	89 e5                	mov    %esp,%ebp
80105983:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105986:	e8 de f8 ff ff       	call   80105269 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010598b:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105992:	e8 70 04 00 00       	call   80105e07 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105997:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
8010599e:	eb 5f                	jmp    801059ff <scheduler+0x7f>
      if(p->state != RUNNABLE)
801059a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059a3:	8b 40 0c             	mov    0xc(%eax),%eax
801059a6:	83 f8 03             	cmp    $0x3,%eax
801059a9:	75 4f                	jne    801059fa <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801059ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ae:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801059b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b7:	89 04 24             	mov    %eax,(%esp)
801059ba:	e8 9f 34 00 00       	call   80108e5e <switchuvm>
      p->state = RUNNING;
801059bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059c2:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801059c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059cf:	8b 40 1c             	mov    0x1c(%eax),%eax
801059d2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801059d9:	83 c2 04             	add    $0x4,%edx
801059dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801059e0:	89 14 24             	mov    %edx,(%esp)
801059e3:	e8 14 09 00 00       	call   801062fc <swtch>
      switchkvm();
801059e8:	e8 54 34 00 00       	call   80108e41 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801059ed:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801059f4:	00 00 00 00 
801059f8:	eb 01                	jmp    801059fb <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801059fa:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059fb:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801059ff:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105a06:	72 98                	jb     801059a0 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105a08:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a0f:	e8 55 04 00 00       	call   80105e69 <release>

  }
80105a14:	e9 6d ff ff ff       	jmp    80105986 <scheduler+0x6>

80105a19 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105a19:	55                   	push   %ebp
80105a1a:	89 e5                	mov    %esp,%ebp
80105a1c:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105a1f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a26:	e8 fa 04 00 00       	call   80105f25 <holding>
80105a2b:	85 c0                	test   %eax,%eax
80105a2d:	75 0c                	jne    80105a3b <sched+0x22>
    panic("sched ptable.lock");
80105a2f:	c7 04 24 f1 99 10 80 	movl   $0x801099f1,(%esp)
80105a36:	e8 02 ab ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105a3b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a41:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a47:	83 f8 01             	cmp    $0x1,%eax
80105a4a:	74 0c                	je     80105a58 <sched+0x3f>
    panic("sched locks");
80105a4c:	c7 04 24 03 9a 10 80 	movl   $0x80109a03,(%esp)
80105a53:	e8 e5 aa ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105a58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a5e:	8b 40 0c             	mov    0xc(%eax),%eax
80105a61:	83 f8 04             	cmp    $0x4,%eax
80105a64:	75 0c                	jne    80105a72 <sched+0x59>
    panic("sched running");
80105a66:	c7 04 24 0f 9a 10 80 	movl   $0x80109a0f,(%esp)
80105a6d:	e8 cb aa ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105a72:	e8 dd f7 ff ff       	call   80105254 <readeflags>
80105a77:	25 00 02 00 00       	and    $0x200,%eax
80105a7c:	85 c0                	test   %eax,%eax
80105a7e:	74 0c                	je     80105a8c <sched+0x73>
    panic("sched interruptible");
80105a80:	c7 04 24 1d 9a 10 80 	movl   $0x80109a1d,(%esp)
80105a87:	e8 b1 aa ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105a8c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a92:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105a98:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105a9b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105aa1:	8b 40 04             	mov    0x4(%eax),%eax
80105aa4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105aab:	83 c2 1c             	add    $0x1c,%edx
80105aae:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ab2:	89 14 24             	mov    %edx,(%esp)
80105ab5:	e8 42 08 00 00       	call   801062fc <swtch>
  cpu->intena = intena;
80105aba:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ac0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ac3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105ac9:	c9                   	leave  
80105aca:	c3                   	ret    

80105acb <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105acb:	55                   	push   %ebp
80105acc:	89 e5                	mov    %esp,%ebp
80105ace:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105ad1:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105ad8:	e8 2a 03 00 00       	call   80105e07 <acquire>
  proc->state = RUNNABLE;
80105add:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ae3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105aea:	e8 2a ff ff ff       	call   80105a19 <sched>
  release(&ptable.lock);
80105aef:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105af6:	e8 6e 03 00 00       	call   80105e69 <release>
}
80105afb:	c9                   	leave  
80105afc:	c3                   	ret    

80105afd <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105afd:	55                   	push   %ebp
80105afe:	89 e5                	mov    %esp,%ebp
80105b00:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105b03:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105b0a:	e8 5a 03 00 00       	call   80105e69 <release>

  if (first) {
80105b0f:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105b14:	85 c0                	test   %eax,%eax
80105b16:	74 0f                	je     80105b27 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105b18:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105b1f:	00 00 00 
    initlog();
80105b22:	e8 4d e7 ff ff       	call   80104274 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105b27:	c9                   	leave  
80105b28:	c3                   	ret    

80105b29 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105b29:	55                   	push   %ebp
80105b2a:	89 e5                	mov    %esp,%ebp
80105b2c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105b2f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b35:	85 c0                	test   %eax,%eax
80105b37:	75 0c                	jne    80105b45 <sleep+0x1c>
    panic("sleep");
80105b39:	c7 04 24 31 9a 10 80 	movl   $0x80109a31,(%esp)
80105b40:	e8 f8 a9 ff ff       	call   8010053d <panic>

  if(lk == 0)
80105b45:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105b49:	75 0c                	jne    80105b57 <sleep+0x2e>
    panic("sleep without lk");
80105b4b:	c7 04 24 37 9a 10 80 	movl   $0x80109a37,(%esp)
80105b52:	e8 e6 a9 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105b57:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
80105b5e:	74 17                	je     80105b77 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105b60:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105b67:	e8 9b 02 00 00       	call   80105e07 <acquire>
    release(lk);
80105b6c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b6f:	89 04 24             	mov    %eax,(%esp)
80105b72:	e8 f2 02 00 00       	call   80105e69 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105b77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b7d:	8b 55 08             	mov    0x8(%ebp),%edx
80105b80:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105b83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b89:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105b90:	e8 84 fe ff ff       	call   80105a19 <sched>

  // Tidy up.
  proc->chan = 0;
80105b95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b9b:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105ba2:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
80105ba9:	74 17                	je     80105bc2 <sleep+0x99>
    release(&ptable.lock);
80105bab:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105bb2:	e8 b2 02 00 00       	call   80105e69 <release>
    acquire(lk);
80105bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bba:	89 04 24             	mov    %eax,(%esp)
80105bbd:	e8 45 02 00 00       	call   80105e07 <acquire>
  }
}
80105bc2:	c9                   	leave  
80105bc3:	c3                   	ret    

80105bc4 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105bc4:	55                   	push   %ebp
80105bc5:	89 e5                	mov    %esp,%ebp
80105bc7:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105bca:	c7 45 fc 94 0f 11 80 	movl   $0x80110f94,-0x4(%ebp)
80105bd1:	eb 24                	jmp    80105bf7 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105bd3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bd6:	8b 40 0c             	mov    0xc(%eax),%eax
80105bd9:	83 f8 02             	cmp    $0x2,%eax
80105bdc:	75 15                	jne    80105bf3 <wakeup1+0x2f>
80105bde:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105be1:	8b 40 20             	mov    0x20(%eax),%eax
80105be4:	3b 45 08             	cmp    0x8(%ebp),%eax
80105be7:	75 0a                	jne    80105bf3 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105be9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bec:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105bf3:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105bf7:	81 7d fc 94 2e 11 80 	cmpl   $0x80112e94,-0x4(%ebp)
80105bfe:	72 d3                	jb     80105bd3 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105c00:	c9                   	leave  
80105c01:	c3                   	ret    

80105c02 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105c02:	55                   	push   %ebp
80105c03:	89 e5                	mov    %esp,%ebp
80105c05:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105c08:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c0f:	e8 f3 01 00 00       	call   80105e07 <acquire>
  wakeup1(chan);
80105c14:	8b 45 08             	mov    0x8(%ebp),%eax
80105c17:	89 04 24             	mov    %eax,(%esp)
80105c1a:	e8 a5 ff ff ff       	call   80105bc4 <wakeup1>
  release(&ptable.lock);
80105c1f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c26:	e8 3e 02 00 00       	call   80105e69 <release>
}
80105c2b:	c9                   	leave  
80105c2c:	c3                   	ret    

80105c2d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105c2d:	55                   	push   %ebp
80105c2e:	89 e5                	mov    %esp,%ebp
80105c30:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105c33:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c3a:	e8 c8 01 00 00       	call   80105e07 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105c3f:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105c46:	eb 41                	jmp    80105c89 <kill+0x5c>
    if(p->pid == pid){
80105c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c4b:	8b 40 10             	mov    0x10(%eax),%eax
80105c4e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c51:	75 32                	jne    80105c85 <kill+0x58>
      p->killed = 1;
80105c53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c56:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105c5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c60:	8b 40 0c             	mov    0xc(%eax),%eax
80105c63:	83 f8 02             	cmp    $0x2,%eax
80105c66:	75 0a                	jne    80105c72 <kill+0x45>
        p->state = RUNNABLE;
80105c68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c6b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105c72:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c79:	e8 eb 01 00 00       	call   80105e69 <release>
      return 0;
80105c7e:	b8 00 00 00 00       	mov    $0x0,%eax
80105c83:	eb 1e                	jmp    80105ca3 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105c85:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105c89:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105c90:	72 b6                	jb     80105c48 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105c92:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c99:	e8 cb 01 00 00       	call   80105e69 <release>
  return -1;
80105c9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ca3:	c9                   	leave  
80105ca4:	c3                   	ret    

80105ca5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105ca5:	55                   	push   %ebp
80105ca6:	89 e5                	mov    %esp,%ebp
80105ca8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105cab:	c7 45 f0 94 0f 11 80 	movl   $0x80110f94,-0x10(%ebp)
80105cb2:	e9 d8 00 00 00       	jmp    80105d8f <procdump+0xea>
    if(p->state == UNUSED)
80105cb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cba:	8b 40 0c             	mov    0xc(%eax),%eax
80105cbd:	85 c0                	test   %eax,%eax
80105cbf:	0f 84 c5 00 00 00    	je     80105d8a <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105cc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc8:	8b 40 0c             	mov    0xc(%eax),%eax
80105ccb:	83 f8 05             	cmp    $0x5,%eax
80105cce:	77 23                	ja     80105cf3 <procdump+0x4e>
80105cd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cd3:	8b 40 0c             	mov    0xc(%eax),%eax
80105cd6:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105cdd:	85 c0                	test   %eax,%eax
80105cdf:	74 12                	je     80105cf3 <procdump+0x4e>
      state = states[p->state];
80105ce1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ce4:	8b 40 0c             	mov    0xc(%eax),%eax
80105ce7:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105cee:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105cf1:	eb 07                	jmp    80105cfa <procdump+0x55>
    else
      state = "???";
80105cf3:	c7 45 ec 48 9a 10 80 	movl   $0x80109a48,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105cfa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cfd:	8d 50 6c             	lea    0x6c(%eax),%edx
80105d00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d03:	8b 40 10             	mov    0x10(%eax),%eax
80105d06:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105d0a:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105d0d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105d11:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d15:	c7 04 24 4c 9a 10 80 	movl   $0x80109a4c,(%esp)
80105d1c:	e8 80 a6 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105d21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d24:	8b 40 0c             	mov    0xc(%eax),%eax
80105d27:	83 f8 02             	cmp    $0x2,%eax
80105d2a:	75 50                	jne    80105d7c <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d2f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105d32:	8b 40 0c             	mov    0xc(%eax),%eax
80105d35:	83 c0 08             	add    $0x8,%eax
80105d38:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105d3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d3f:	89 04 24             	mov    %eax,(%esp)
80105d42:	e8 71 01 00 00       	call   80105eb8 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105d47:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105d4e:	eb 1b                	jmp    80105d6b <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105d50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d53:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105d57:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d5b:	c7 04 24 55 9a 10 80 	movl   $0x80109a55,(%esp)
80105d62:	e8 3a a6 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105d67:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105d6b:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105d6f:	7f 0b                	jg     80105d7c <procdump+0xd7>
80105d71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d74:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105d78:	85 c0                	test   %eax,%eax
80105d7a:	75 d4                	jne    80105d50 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105d7c:	c7 04 24 59 9a 10 80 	movl   $0x80109a59,(%esp)
80105d83:	e8 19 a6 ff ff       	call   801003a1 <cprintf>
80105d88:	eb 01                	jmp    80105d8b <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105d8a:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105d8b:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105d8f:	81 7d f0 94 2e 11 80 	cmpl   $0x80112e94,-0x10(%ebp)
80105d96:	0f 82 1b ff ff ff    	jb     80105cb7 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105d9c:	c9                   	leave  
80105d9d:	c3                   	ret    
	...

80105da0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105da0:	55                   	push   %ebp
80105da1:	89 e5                	mov    %esp,%ebp
80105da3:	53                   	push   %ebx
80105da4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105da7:	9c                   	pushf  
80105da8:	5b                   	pop    %ebx
80105da9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105dac:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105daf:	83 c4 10             	add    $0x10,%esp
80105db2:	5b                   	pop    %ebx
80105db3:	5d                   	pop    %ebp
80105db4:	c3                   	ret    

80105db5 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105db5:	55                   	push   %ebp
80105db6:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105db8:	fa                   	cli    
}
80105db9:	5d                   	pop    %ebp
80105dba:	c3                   	ret    

80105dbb <sti>:

static inline void
sti(void)
{
80105dbb:	55                   	push   %ebp
80105dbc:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105dbe:	fb                   	sti    
}
80105dbf:	5d                   	pop    %ebp
80105dc0:	c3                   	ret    

80105dc1 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105dc1:	55                   	push   %ebp
80105dc2:	89 e5                	mov    %esp,%ebp
80105dc4:	53                   	push   %ebx
80105dc5:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105dc8:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105dcb:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105dce:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105dd1:	89 c3                	mov    %eax,%ebx
80105dd3:	89 d8                	mov    %ebx,%eax
80105dd5:	f0 87 02             	lock xchg %eax,(%edx)
80105dd8:	89 c3                	mov    %eax,%ebx
80105dda:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105ddd:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105de0:	83 c4 10             	add    $0x10,%esp
80105de3:	5b                   	pop    %ebx
80105de4:	5d                   	pop    %ebp
80105de5:	c3                   	ret    

80105de6 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105de6:	55                   	push   %ebp
80105de7:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105de9:	8b 45 08             	mov    0x8(%ebp),%eax
80105dec:	8b 55 0c             	mov    0xc(%ebp),%edx
80105def:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105df2:	8b 45 08             	mov    0x8(%ebp),%eax
80105df5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80105dfe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105e05:	5d                   	pop    %ebp
80105e06:	c3                   	ret    

80105e07 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105e07:	55                   	push   %ebp
80105e08:	89 e5                	mov    %esp,%ebp
80105e0a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105e0d:	e8 3d 01 00 00       	call   80105f4f <pushcli>
  if(holding(lk))
80105e12:	8b 45 08             	mov    0x8(%ebp),%eax
80105e15:	89 04 24             	mov    %eax,(%esp)
80105e18:	e8 08 01 00 00       	call   80105f25 <holding>
80105e1d:	85 c0                	test   %eax,%eax
80105e1f:	74 0c                	je     80105e2d <acquire+0x26>
    panic("acquire");
80105e21:	c7 04 24 85 9a 10 80 	movl   $0x80109a85,(%esp)
80105e28:	e8 10 a7 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105e2d:	90                   	nop
80105e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e31:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105e38:	00 
80105e39:	89 04 24             	mov    %eax,(%esp)
80105e3c:	e8 80 ff ff ff       	call   80105dc1 <xchg>
80105e41:	85 c0                	test   %eax,%eax
80105e43:	75 e9                	jne    80105e2e <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105e45:	8b 45 08             	mov    0x8(%ebp),%eax
80105e48:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105e4f:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105e52:	8b 45 08             	mov    0x8(%ebp),%eax
80105e55:	83 c0 0c             	add    $0xc,%eax
80105e58:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e5c:	8d 45 08             	lea    0x8(%ebp),%eax
80105e5f:	89 04 24             	mov    %eax,(%esp)
80105e62:	e8 51 00 00 00       	call   80105eb8 <getcallerpcs>
}
80105e67:	c9                   	leave  
80105e68:	c3                   	ret    

80105e69 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105e69:	55                   	push   %ebp
80105e6a:	89 e5                	mov    %esp,%ebp
80105e6c:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105e6f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e72:	89 04 24             	mov    %eax,(%esp)
80105e75:	e8 ab 00 00 00       	call   80105f25 <holding>
80105e7a:	85 c0                	test   %eax,%eax
80105e7c:	75 0c                	jne    80105e8a <release+0x21>
    panic("release");
80105e7e:	c7 04 24 8d 9a 10 80 	movl   $0x80109a8d,(%esp)
80105e85:	e8 b3 a6 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80105e8d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105e94:	8b 45 08             	mov    0x8(%ebp),%eax
80105e97:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105e9e:	8b 45 08             	mov    0x8(%ebp),%eax
80105ea1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105ea8:	00 
80105ea9:	89 04 24             	mov    %eax,(%esp)
80105eac:	e8 10 ff ff ff       	call   80105dc1 <xchg>

  popcli();
80105eb1:	e8 e1 00 00 00       	call   80105f97 <popcli>
}
80105eb6:	c9                   	leave  
80105eb7:	c3                   	ret    

80105eb8 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105eb8:	55                   	push   %ebp
80105eb9:	89 e5                	mov    %esp,%ebp
80105ebb:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec1:	83 e8 08             	sub    $0x8,%eax
80105ec4:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105ec7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105ece:	eb 32                	jmp    80105f02 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105ed0:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105ed4:	74 47                	je     80105f1d <getcallerpcs+0x65>
80105ed6:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105edd:	76 3e                	jbe    80105f1d <getcallerpcs+0x65>
80105edf:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105ee3:	74 38                	je     80105f1d <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105ee5:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ee8:	c1 e0 02             	shl    $0x2,%eax
80105eeb:	03 45 0c             	add    0xc(%ebp),%eax
80105eee:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105ef1:	8b 52 04             	mov    0x4(%edx),%edx
80105ef4:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105ef6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ef9:	8b 00                	mov    (%eax),%eax
80105efb:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105efe:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f02:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105f06:	7e c8                	jle    80105ed0 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105f08:	eb 13                	jmp    80105f1d <getcallerpcs+0x65>
    pcs[i] = 0;
80105f0a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f0d:	c1 e0 02             	shl    $0x2,%eax
80105f10:	03 45 0c             	add    0xc(%ebp),%eax
80105f13:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105f19:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f1d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105f21:	7e e7                	jle    80105f0a <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105f23:	c9                   	leave  
80105f24:	c3                   	ret    

80105f25 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105f25:	55                   	push   %ebp
80105f26:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105f28:	8b 45 08             	mov    0x8(%ebp),%eax
80105f2b:	8b 00                	mov    (%eax),%eax
80105f2d:	85 c0                	test   %eax,%eax
80105f2f:	74 17                	je     80105f48 <holding+0x23>
80105f31:	8b 45 08             	mov    0x8(%ebp),%eax
80105f34:	8b 50 08             	mov    0x8(%eax),%edx
80105f37:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f3d:	39 c2                	cmp    %eax,%edx
80105f3f:	75 07                	jne    80105f48 <holding+0x23>
80105f41:	b8 01 00 00 00       	mov    $0x1,%eax
80105f46:	eb 05                	jmp    80105f4d <holding+0x28>
80105f48:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f4d:	5d                   	pop    %ebp
80105f4e:	c3                   	ret    

80105f4f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105f4f:	55                   	push   %ebp
80105f50:	89 e5                	mov    %esp,%ebp
80105f52:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105f55:	e8 46 fe ff ff       	call   80105da0 <readeflags>
80105f5a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105f5d:	e8 53 fe ff ff       	call   80105db5 <cli>
  if(cpu->ncli++ == 0)
80105f62:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f68:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105f6e:	85 d2                	test   %edx,%edx
80105f70:	0f 94 c1             	sete   %cl
80105f73:	83 c2 01             	add    $0x1,%edx
80105f76:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105f7c:	84 c9                	test   %cl,%cl
80105f7e:	74 15                	je     80105f95 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105f80:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f86:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f89:	81 e2 00 02 00 00    	and    $0x200,%edx
80105f8f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105f95:	c9                   	leave  
80105f96:	c3                   	ret    

80105f97 <popcli>:

void
popcli(void)
{
80105f97:	55                   	push   %ebp
80105f98:	89 e5                	mov    %esp,%ebp
80105f9a:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105f9d:	e8 fe fd ff ff       	call   80105da0 <readeflags>
80105fa2:	25 00 02 00 00       	and    $0x200,%eax
80105fa7:	85 c0                	test   %eax,%eax
80105fa9:	74 0c                	je     80105fb7 <popcli+0x20>
    panic("popcli - interruptible");
80105fab:	c7 04 24 95 9a 10 80 	movl   $0x80109a95,(%esp)
80105fb2:	e8 86 a5 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105fb7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105fbd:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105fc3:	83 ea 01             	sub    $0x1,%edx
80105fc6:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105fcc:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105fd2:	85 c0                	test   %eax,%eax
80105fd4:	79 0c                	jns    80105fe2 <popcli+0x4b>
    panic("popcli");
80105fd6:	c7 04 24 ac 9a 10 80 	movl   $0x80109aac,(%esp)
80105fdd:	e8 5b a5 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105fe2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105fe8:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105fee:	85 c0                	test   %eax,%eax
80105ff0:	75 15                	jne    80106007 <popcli+0x70>
80105ff2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ff8:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105ffe:	85 c0                	test   %eax,%eax
80106000:	74 05                	je     80106007 <popcli+0x70>
    sti();
80106002:	e8 b4 fd ff ff       	call   80105dbb <sti>
}
80106007:	c9                   	leave  
80106008:	c3                   	ret    
80106009:	00 00                	add    %al,(%eax)
	...

8010600c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010600c:	55                   	push   %ebp
8010600d:	89 e5                	mov    %esp,%ebp
8010600f:	57                   	push   %edi
80106010:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80106011:	8b 4d 08             	mov    0x8(%ebp),%ecx
80106014:	8b 55 10             	mov    0x10(%ebp),%edx
80106017:	8b 45 0c             	mov    0xc(%ebp),%eax
8010601a:	89 cb                	mov    %ecx,%ebx
8010601c:	89 df                	mov    %ebx,%edi
8010601e:	89 d1                	mov    %edx,%ecx
80106020:	fc                   	cld    
80106021:	f3 aa                	rep stos %al,%es:(%edi)
80106023:	89 ca                	mov    %ecx,%edx
80106025:	89 fb                	mov    %edi,%ebx
80106027:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010602a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010602d:	5b                   	pop    %ebx
8010602e:	5f                   	pop    %edi
8010602f:	5d                   	pop    %ebp
80106030:	c3                   	ret    

80106031 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80106031:	55                   	push   %ebp
80106032:	89 e5                	mov    %esp,%ebp
80106034:	57                   	push   %edi
80106035:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80106036:	8b 4d 08             	mov    0x8(%ebp),%ecx
80106039:	8b 55 10             	mov    0x10(%ebp),%edx
8010603c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010603f:	89 cb                	mov    %ecx,%ebx
80106041:	89 df                	mov    %ebx,%edi
80106043:	89 d1                	mov    %edx,%ecx
80106045:	fc                   	cld    
80106046:	f3 ab                	rep stos %eax,%es:(%edi)
80106048:	89 ca                	mov    %ecx,%edx
8010604a:	89 fb                	mov    %edi,%ebx
8010604c:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010604f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80106052:	5b                   	pop    %ebx
80106053:	5f                   	pop    %edi
80106054:	5d                   	pop    %ebp
80106055:	c3                   	ret    

80106056 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80106056:	55                   	push   %ebp
80106057:	89 e5                	mov    %esp,%ebp
80106059:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
8010605c:	8b 45 08             	mov    0x8(%ebp),%eax
8010605f:	83 e0 03             	and    $0x3,%eax
80106062:	85 c0                	test   %eax,%eax
80106064:	75 49                	jne    801060af <memset+0x59>
80106066:	8b 45 10             	mov    0x10(%ebp),%eax
80106069:	83 e0 03             	and    $0x3,%eax
8010606c:	85 c0                	test   %eax,%eax
8010606e:	75 3f                	jne    801060af <memset+0x59>
    c &= 0xFF;
80106070:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80106077:	8b 45 10             	mov    0x10(%ebp),%eax
8010607a:	c1 e8 02             	shr    $0x2,%eax
8010607d:	89 c2                	mov    %eax,%edx
8010607f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106082:	89 c1                	mov    %eax,%ecx
80106084:	c1 e1 18             	shl    $0x18,%ecx
80106087:	8b 45 0c             	mov    0xc(%ebp),%eax
8010608a:	c1 e0 10             	shl    $0x10,%eax
8010608d:	09 c1                	or     %eax,%ecx
8010608f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106092:	c1 e0 08             	shl    $0x8,%eax
80106095:	09 c8                	or     %ecx,%eax
80106097:	0b 45 0c             	or     0xc(%ebp),%eax
8010609a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010609e:	89 44 24 04          	mov    %eax,0x4(%esp)
801060a2:	8b 45 08             	mov    0x8(%ebp),%eax
801060a5:	89 04 24             	mov    %eax,(%esp)
801060a8:	e8 84 ff ff ff       	call   80106031 <stosl>
801060ad:	eb 19                	jmp    801060c8 <memset+0x72>
  } else
    stosb(dst, c, n);
801060af:	8b 45 10             	mov    0x10(%ebp),%eax
801060b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801060b6:	8b 45 0c             	mov    0xc(%ebp),%eax
801060b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801060bd:	8b 45 08             	mov    0x8(%ebp),%eax
801060c0:	89 04 24             	mov    %eax,(%esp)
801060c3:	e8 44 ff ff ff       	call   8010600c <stosb>
  return dst;
801060c8:	8b 45 08             	mov    0x8(%ebp),%eax
}
801060cb:	c9                   	leave  
801060cc:	c3                   	ret    

801060cd <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801060cd:	55                   	push   %ebp
801060ce:	89 e5                	mov    %esp,%ebp
801060d0:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801060d3:	8b 45 08             	mov    0x8(%ebp),%eax
801060d6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801060d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801060dc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801060df:	eb 32                	jmp    80106113 <memcmp+0x46>
    if(*s1 != *s2)
801060e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060e4:	0f b6 10             	movzbl (%eax),%edx
801060e7:	8b 45 f8             	mov    -0x8(%ebp),%eax
801060ea:	0f b6 00             	movzbl (%eax),%eax
801060ed:	38 c2                	cmp    %al,%dl
801060ef:	74 1a                	je     8010610b <memcmp+0x3e>
      return *s1 - *s2;
801060f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060f4:	0f b6 00             	movzbl (%eax),%eax
801060f7:	0f b6 d0             	movzbl %al,%edx
801060fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
801060fd:	0f b6 00             	movzbl (%eax),%eax
80106100:	0f b6 c0             	movzbl %al,%eax
80106103:	89 d1                	mov    %edx,%ecx
80106105:	29 c1                	sub    %eax,%ecx
80106107:	89 c8                	mov    %ecx,%eax
80106109:	eb 1c                	jmp    80106127 <memcmp+0x5a>
    s1++, s2++;
8010610b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010610f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80106113:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106117:	0f 95 c0             	setne  %al
8010611a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010611e:	84 c0                	test   %al,%al
80106120:	75 bf                	jne    801060e1 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80106122:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106127:	c9                   	leave  
80106128:	c3                   	ret    

80106129 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80106129:	55                   	push   %ebp
8010612a:	89 e5                	mov    %esp,%ebp
8010612c:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
8010612f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106132:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80106135:	8b 45 08             	mov    0x8(%ebp),%eax
80106138:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010613b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010613e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106141:	73 54                	jae    80106197 <memmove+0x6e>
80106143:	8b 45 10             	mov    0x10(%ebp),%eax
80106146:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106149:	01 d0                	add    %edx,%eax
8010614b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010614e:	76 47                	jbe    80106197 <memmove+0x6e>
    s += n;
80106150:	8b 45 10             	mov    0x10(%ebp),%eax
80106153:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80106156:	8b 45 10             	mov    0x10(%ebp),%eax
80106159:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
8010615c:	eb 13                	jmp    80106171 <memmove+0x48>
      *--d = *--s;
8010615e:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80106162:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80106166:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106169:	0f b6 10             	movzbl (%eax),%edx
8010616c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010616f:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80106171:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106175:	0f 95 c0             	setne  %al
80106178:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010617c:	84 c0                	test   %al,%al
8010617e:	75 de                	jne    8010615e <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80106180:	eb 25                	jmp    801061a7 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80106182:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106185:	0f b6 10             	movzbl (%eax),%edx
80106188:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010618b:	88 10                	mov    %dl,(%eax)
8010618d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80106191:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106195:	eb 01                	jmp    80106198 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80106197:	90                   	nop
80106198:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010619c:	0f 95 c0             	setne  %al
8010619f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061a3:	84 c0                	test   %al,%al
801061a5:	75 db                	jne    80106182 <memmove+0x59>
      *d++ = *s++;

  return dst;
801061a7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801061aa:	c9                   	leave  
801061ab:	c3                   	ret    

801061ac <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801061ac:	55                   	push   %ebp
801061ad:	89 e5                	mov    %esp,%ebp
801061af:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801061b2:	8b 45 10             	mov    0x10(%ebp),%eax
801061b5:	89 44 24 08          	mov    %eax,0x8(%esp)
801061b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801061bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c0:	8b 45 08             	mov    0x8(%ebp),%eax
801061c3:	89 04 24             	mov    %eax,(%esp)
801061c6:	e8 5e ff ff ff       	call   80106129 <memmove>
}
801061cb:	c9                   	leave  
801061cc:	c3                   	ret    

801061cd <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801061cd:	55                   	push   %ebp
801061ce:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801061d0:	eb 0c                	jmp    801061de <strncmp+0x11>
    n--, p++, q++;
801061d2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061d6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801061da:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801061de:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061e2:	74 1a                	je     801061fe <strncmp+0x31>
801061e4:	8b 45 08             	mov    0x8(%ebp),%eax
801061e7:	0f b6 00             	movzbl (%eax),%eax
801061ea:	84 c0                	test   %al,%al
801061ec:	74 10                	je     801061fe <strncmp+0x31>
801061ee:	8b 45 08             	mov    0x8(%ebp),%eax
801061f1:	0f b6 10             	movzbl (%eax),%edx
801061f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801061f7:	0f b6 00             	movzbl (%eax),%eax
801061fa:	38 c2                	cmp    %al,%dl
801061fc:	74 d4                	je     801061d2 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801061fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106202:	75 07                	jne    8010620b <strncmp+0x3e>
    return 0;
80106204:	b8 00 00 00 00       	mov    $0x0,%eax
80106209:	eb 18                	jmp    80106223 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010620b:	8b 45 08             	mov    0x8(%ebp),%eax
8010620e:	0f b6 00             	movzbl (%eax),%eax
80106211:	0f b6 d0             	movzbl %al,%edx
80106214:	8b 45 0c             	mov    0xc(%ebp),%eax
80106217:	0f b6 00             	movzbl (%eax),%eax
8010621a:	0f b6 c0             	movzbl %al,%eax
8010621d:	89 d1                	mov    %edx,%ecx
8010621f:	29 c1                	sub    %eax,%ecx
80106221:	89 c8                	mov    %ecx,%eax
}
80106223:	5d                   	pop    %ebp
80106224:	c3                   	ret    

80106225 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80106225:	55                   	push   %ebp
80106226:	89 e5                	mov    %esp,%ebp
80106228:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010622b:	8b 45 08             	mov    0x8(%ebp),%eax
8010622e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106231:	90                   	nop
80106232:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106236:	0f 9f c0             	setg   %al
80106239:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010623d:	84 c0                	test   %al,%al
8010623f:	74 30                	je     80106271 <strncpy+0x4c>
80106241:	8b 45 0c             	mov    0xc(%ebp),%eax
80106244:	0f b6 10             	movzbl (%eax),%edx
80106247:	8b 45 08             	mov    0x8(%ebp),%eax
8010624a:	88 10                	mov    %dl,(%eax)
8010624c:	8b 45 08             	mov    0x8(%ebp),%eax
8010624f:	0f b6 00             	movzbl (%eax),%eax
80106252:	84 c0                	test   %al,%al
80106254:	0f 95 c0             	setne  %al
80106257:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010625b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010625f:	84 c0                	test   %al,%al
80106261:	75 cf                	jne    80106232 <strncpy+0xd>
    ;
  while(n-- > 0)
80106263:	eb 0c                	jmp    80106271 <strncpy+0x4c>
    *s++ = 0;
80106265:	8b 45 08             	mov    0x8(%ebp),%eax
80106268:	c6 00 00             	movb   $0x0,(%eax)
8010626b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010626f:	eb 01                	jmp    80106272 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106271:	90                   	nop
80106272:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106276:	0f 9f c0             	setg   %al
80106279:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010627d:	84 c0                	test   %al,%al
8010627f:	75 e4                	jne    80106265 <strncpy+0x40>
    *s++ = 0;
  return os;
80106281:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106284:	c9                   	leave  
80106285:	c3                   	ret    

80106286 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80106286:	55                   	push   %ebp
80106287:	89 e5                	mov    %esp,%ebp
80106289:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010628c:	8b 45 08             	mov    0x8(%ebp),%eax
8010628f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106292:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106296:	7f 05                	jg     8010629d <safestrcpy+0x17>
    return os;
80106298:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010629b:	eb 35                	jmp    801062d2 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
8010629d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801062a1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062a5:	7e 22                	jle    801062c9 <safestrcpy+0x43>
801062a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801062aa:	0f b6 10             	movzbl (%eax),%edx
801062ad:	8b 45 08             	mov    0x8(%ebp),%eax
801062b0:	88 10                	mov    %dl,(%eax)
801062b2:	8b 45 08             	mov    0x8(%ebp),%eax
801062b5:	0f b6 00             	movzbl (%eax),%eax
801062b8:	84 c0                	test   %al,%al
801062ba:	0f 95 c0             	setne  %al
801062bd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801062c1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801062c5:	84 c0                	test   %al,%al
801062c7:	75 d4                	jne    8010629d <safestrcpy+0x17>
    ;
  *s = 0;
801062c9:	8b 45 08             	mov    0x8(%ebp),%eax
801062cc:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801062cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801062d2:	c9                   	leave  
801062d3:	c3                   	ret    

801062d4 <strlen>:

int
strlen(const char *s)
{
801062d4:	55                   	push   %ebp
801062d5:	89 e5                	mov    %esp,%ebp
801062d7:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801062da:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801062e1:	eb 04                	jmp    801062e7 <strlen+0x13>
801062e3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801062e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062ea:	03 45 08             	add    0x8(%ebp),%eax
801062ed:	0f b6 00             	movzbl (%eax),%eax
801062f0:	84 c0                	test   %al,%al
801062f2:	75 ef                	jne    801062e3 <strlen+0xf>
    ;
  return n;
801062f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801062f7:	c9                   	leave  
801062f8:	c3                   	ret    
801062f9:	00 00                	add    %al,(%eax)
	...

801062fc <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801062fc:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80106300:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106304:	55                   	push   %ebp
  pushl %ebx
80106305:	53                   	push   %ebx
  pushl %esi
80106306:	56                   	push   %esi
  pushl %edi
80106307:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80106308:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010630a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010630c:	5f                   	pop    %edi
  popl %esi
8010630d:	5e                   	pop    %esi
  popl %ebx
8010630e:	5b                   	pop    %ebx
  popl %ebp
8010630f:	5d                   	pop    %ebp
  ret
80106310:	c3                   	ret    
80106311:	00 00                	add    %al,(%eax)
	...

80106314 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80106314:	55                   	push   %ebp
80106315:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80106317:	8b 45 08             	mov    0x8(%ebp),%eax
8010631a:	8b 00                	mov    (%eax),%eax
8010631c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010631f:	76 0f                	jbe    80106330 <fetchint+0x1c>
80106321:	8b 45 0c             	mov    0xc(%ebp),%eax
80106324:	8d 50 04             	lea    0x4(%eax),%edx
80106327:	8b 45 08             	mov    0x8(%ebp),%eax
8010632a:	8b 00                	mov    (%eax),%eax
8010632c:	39 c2                	cmp    %eax,%edx
8010632e:	76 07                	jbe    80106337 <fetchint+0x23>
    return -1;
80106330:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106335:	eb 0f                	jmp    80106346 <fetchint+0x32>
  *ip = *(int*)(addr);
80106337:	8b 45 0c             	mov    0xc(%ebp),%eax
8010633a:	8b 10                	mov    (%eax),%edx
8010633c:	8b 45 10             	mov    0x10(%ebp),%eax
8010633f:	89 10                	mov    %edx,(%eax)
  return 0;
80106341:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106346:	5d                   	pop    %ebp
80106347:	c3                   	ret    

80106348 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80106348:	55                   	push   %ebp
80106349:	89 e5                	mov    %esp,%ebp
8010634b:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
8010634e:	8b 45 08             	mov    0x8(%ebp),%eax
80106351:	8b 00                	mov    (%eax),%eax
80106353:	3b 45 0c             	cmp    0xc(%ebp),%eax
80106356:	77 07                	ja     8010635f <fetchstr+0x17>
    return -1;
80106358:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010635d:	eb 45                	jmp    801063a4 <fetchstr+0x5c>
  *pp = (char*)addr;
8010635f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106362:	8b 45 10             	mov    0x10(%ebp),%eax
80106365:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80106367:	8b 45 08             	mov    0x8(%ebp),%eax
8010636a:	8b 00                	mov    (%eax),%eax
8010636c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010636f:	8b 45 10             	mov    0x10(%ebp),%eax
80106372:	8b 00                	mov    (%eax),%eax
80106374:	89 45 fc             	mov    %eax,-0x4(%ebp)
80106377:	eb 1e                	jmp    80106397 <fetchstr+0x4f>
    if(*s == 0)
80106379:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010637c:	0f b6 00             	movzbl (%eax),%eax
8010637f:	84 c0                	test   %al,%al
80106381:	75 10                	jne    80106393 <fetchstr+0x4b>
      return s - *pp;
80106383:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106386:	8b 45 10             	mov    0x10(%ebp),%eax
80106389:	8b 00                	mov    (%eax),%eax
8010638b:	89 d1                	mov    %edx,%ecx
8010638d:	29 c1                	sub    %eax,%ecx
8010638f:	89 c8                	mov    %ecx,%eax
80106391:	eb 11                	jmp    801063a4 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80106393:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106397:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010639a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010639d:	72 da                	jb     80106379 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
8010639f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063a4:	c9                   	leave  
801063a5:	c3                   	ret    

801063a6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801063a6:	55                   	push   %ebp
801063a7:	89 e5                	mov    %esp,%ebp
801063a9:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801063ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063b2:	8b 40 18             	mov    0x18(%eax),%eax
801063b5:	8b 50 44             	mov    0x44(%eax),%edx
801063b8:	8b 45 08             	mov    0x8(%ebp),%eax
801063bb:	c1 e0 02             	shl    $0x2,%eax
801063be:	01 d0                	add    %edx,%eax
801063c0:	8d 48 04             	lea    0x4(%eax),%ecx
801063c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063c9:	8b 55 0c             	mov    0xc(%ebp),%edx
801063cc:	89 54 24 08          	mov    %edx,0x8(%esp)
801063d0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801063d4:	89 04 24             	mov    %eax,(%esp)
801063d7:	e8 38 ff ff ff       	call   80106314 <fetchint>
}
801063dc:	c9                   	leave  
801063dd:	c3                   	ret    

801063de <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801063de:	55                   	push   %ebp
801063df:	89 e5                	mov    %esp,%ebp
801063e1:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801063e4:	8d 45 fc             	lea    -0x4(%ebp),%eax
801063e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801063eb:	8b 45 08             	mov    0x8(%ebp),%eax
801063ee:	89 04 24             	mov    %eax,(%esp)
801063f1:	e8 b0 ff ff ff       	call   801063a6 <argint>
801063f6:	85 c0                	test   %eax,%eax
801063f8:	79 07                	jns    80106401 <argptr+0x23>
    return -1;
801063fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063ff:	eb 3d                	jmp    8010643e <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106401:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106404:	89 c2                	mov    %eax,%edx
80106406:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010640c:	8b 00                	mov    (%eax),%eax
8010640e:	39 c2                	cmp    %eax,%edx
80106410:	73 16                	jae    80106428 <argptr+0x4a>
80106412:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106415:	89 c2                	mov    %eax,%edx
80106417:	8b 45 10             	mov    0x10(%ebp),%eax
8010641a:	01 c2                	add    %eax,%edx
8010641c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106422:	8b 00                	mov    (%eax),%eax
80106424:	39 c2                	cmp    %eax,%edx
80106426:	76 07                	jbe    8010642f <argptr+0x51>
    return -1;
80106428:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010642d:	eb 0f                	jmp    8010643e <argptr+0x60>
  *pp = (char*)i;
8010642f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106432:	89 c2                	mov    %eax,%edx
80106434:	8b 45 0c             	mov    0xc(%ebp),%eax
80106437:	89 10                	mov    %edx,(%eax)
  return 0;
80106439:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010643e:	c9                   	leave  
8010643f:	c3                   	ret    

80106440 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106440:	55                   	push   %ebp
80106441:	89 e5                	mov    %esp,%ebp
80106443:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106446:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106449:	89 44 24 04          	mov    %eax,0x4(%esp)
8010644d:	8b 45 08             	mov    0x8(%ebp),%eax
80106450:	89 04 24             	mov    %eax,(%esp)
80106453:	e8 4e ff ff ff       	call   801063a6 <argint>
80106458:	85 c0                	test   %eax,%eax
8010645a:	79 07                	jns    80106463 <argstr+0x23>
    return -1;
8010645c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106461:	eb 1e                	jmp    80106481 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80106463:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106466:	89 c2                	mov    %eax,%edx
80106468:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010646e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106471:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106475:	89 54 24 04          	mov    %edx,0x4(%esp)
80106479:	89 04 24             	mov    %eax,(%esp)
8010647c:	e8 c7 fe ff ff       	call   80106348 <fetchstr>
}
80106481:	c9                   	leave  
80106482:	c3                   	ret    

80106483 <syscall>:
[SYS_getBlkRef]  sys_getBlkRef,
};

void
syscall(void)
{
80106483:	55                   	push   %ebp
80106484:	89 e5                	mov    %esp,%ebp
80106486:	53                   	push   %ebx
80106487:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010648a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106490:	8b 40 18             	mov    0x18(%eax),%eax
80106493:	8b 40 1c             	mov    0x1c(%eax),%eax
80106496:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80106499:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010649d:	78 2e                	js     801064cd <syscall+0x4a>
8010649f:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801064a3:	7f 28                	jg     801064cd <syscall+0x4a>
801064a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a8:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801064af:	85 c0                	test   %eax,%eax
801064b1:	74 1a                	je     801064cd <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801064b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064b9:	8b 58 18             	mov    0x18(%eax),%ebx
801064bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bf:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801064c6:	ff d0                	call   *%eax
801064c8:	89 43 1c             	mov    %eax,0x1c(%ebx)
801064cb:	eb 73                	jmp    80106540 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801064cd:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801064d1:	7e 30                	jle    80106503 <syscall+0x80>
801064d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d6:	83 f8 1a             	cmp    $0x1a,%eax
801064d9:	77 28                	ja     80106503 <syscall+0x80>
801064db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064de:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801064e5:	85 c0                	test   %eax,%eax
801064e7:	74 1a                	je     80106503 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801064e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064ef:	8b 58 18             	mov    0x18(%eax),%ebx
801064f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f5:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801064fc:	ff d0                	call   *%eax
801064fe:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106501:	eb 3d                	jmp    80106540 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106503:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106509:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010650c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106512:	8b 40 10             	mov    0x10(%eax),%eax
80106515:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106518:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010651c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106520:	89 44 24 04          	mov    %eax,0x4(%esp)
80106524:	c7 04 24 b3 9a 10 80 	movl   $0x80109ab3,(%esp)
8010652b:	e8 71 9e ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106530:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106536:	8b 40 18             	mov    0x18(%eax),%eax
80106539:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106540:	83 c4 24             	add    $0x24,%esp
80106543:	5b                   	pop    %ebx
80106544:	5d                   	pop    %ebp
80106545:	c3                   	ret    
	...

80106548 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106548:	55                   	push   %ebp
80106549:	89 e5                	mov    %esp,%ebp
8010654b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010654e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106551:	89 44 24 04          	mov    %eax,0x4(%esp)
80106555:	8b 45 08             	mov    0x8(%ebp),%eax
80106558:	89 04 24             	mov    %eax,(%esp)
8010655b:	e8 46 fe ff ff       	call   801063a6 <argint>
80106560:	85 c0                	test   %eax,%eax
80106562:	79 07                	jns    8010656b <argfd+0x23>
    return -1;
80106564:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106569:	eb 50                	jmp    801065bb <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010656b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010656e:	85 c0                	test   %eax,%eax
80106570:	78 21                	js     80106593 <argfd+0x4b>
80106572:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106575:	83 f8 0f             	cmp    $0xf,%eax
80106578:	7f 19                	jg     80106593 <argfd+0x4b>
8010657a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106580:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106583:	83 c2 08             	add    $0x8,%edx
80106586:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010658a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010658d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106591:	75 07                	jne    8010659a <argfd+0x52>
    return -1;
80106593:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106598:	eb 21                	jmp    801065bb <argfd+0x73>
  if(pfd)
8010659a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010659e:	74 08                	je     801065a8 <argfd+0x60>
    *pfd = fd;
801065a0:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801065a6:	89 10                	mov    %edx,(%eax)
  if(pf)
801065a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801065ac:	74 08                	je     801065b6 <argfd+0x6e>
    *pf = f;
801065ae:	8b 45 10             	mov    0x10(%ebp),%eax
801065b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065b4:	89 10                	mov    %edx,(%eax)
  return 0;
801065b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065bb:	c9                   	leave  
801065bc:	c3                   	ret    

801065bd <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801065bd:	55                   	push   %ebp
801065be:	89 e5                	mov    %esp,%ebp
801065c0:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801065c3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801065ca:	eb 30                	jmp    801065fc <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801065cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065d2:	8b 55 fc             	mov    -0x4(%ebp),%edx
801065d5:	83 c2 08             	add    $0x8,%edx
801065d8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801065dc:	85 c0                	test   %eax,%eax
801065de:	75 18                	jne    801065f8 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801065e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065e6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801065e9:	8d 4a 08             	lea    0x8(%edx),%ecx
801065ec:	8b 55 08             	mov    0x8(%ebp),%edx
801065ef:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801065f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801065f6:	eb 0f                	jmp    80106607 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801065f8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801065fc:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106600:	7e ca                	jle    801065cc <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106602:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106607:	c9                   	leave  
80106608:	c3                   	ret    

80106609 <sys_dup>:

int
sys_dup(void)
{
80106609:	55                   	push   %ebp
8010660a:	89 e5                	mov    %esp,%ebp
8010660c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010660f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106612:	89 44 24 08          	mov    %eax,0x8(%esp)
80106616:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010661d:	00 
8010661e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106625:	e8 1e ff ff ff       	call   80106548 <argfd>
8010662a:	85 c0                	test   %eax,%eax
8010662c:	79 07                	jns    80106635 <sys_dup+0x2c>
    return -1;
8010662e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106633:	eb 29                	jmp    8010665e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106635:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106638:	89 04 24             	mov    %eax,(%esp)
8010663b:	e8 7d ff ff ff       	call   801065bd <fdalloc>
80106640:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106643:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106647:	79 07                	jns    80106650 <sys_dup+0x47>
    return -1;
80106649:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010664e:	eb 0e                	jmp    8010665e <sys_dup+0x55>
  filedup(f);
80106650:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106653:	89 04 24             	mov    %eax,(%esp)
80106656:	e8 21 a9 ff ff       	call   80100f7c <filedup>
  return fd;
8010665b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010665e:	c9                   	leave  
8010665f:	c3                   	ret    

80106660 <sys_read>:

int
sys_read(void)
{
80106660:	55                   	push   %ebp
80106661:	89 e5                	mov    %esp,%ebp
80106663:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106666:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106669:	89 44 24 08          	mov    %eax,0x8(%esp)
8010666d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106674:	00 
80106675:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010667c:	e8 c7 fe ff ff       	call   80106548 <argfd>
80106681:	85 c0                	test   %eax,%eax
80106683:	78 35                	js     801066ba <sys_read+0x5a>
80106685:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106688:	89 44 24 04          	mov    %eax,0x4(%esp)
8010668c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106693:	e8 0e fd ff ff       	call   801063a6 <argint>
80106698:	85 c0                	test   %eax,%eax
8010669a:	78 1e                	js     801066ba <sys_read+0x5a>
8010669c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010669f:	89 44 24 08          	mov    %eax,0x8(%esp)
801066a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801066a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801066aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066b1:	e8 28 fd ff ff       	call   801063de <argptr>
801066b6:	85 c0                	test   %eax,%eax
801066b8:	79 07                	jns    801066c1 <sys_read+0x61>
    return -1;
801066ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066bf:	eb 19                	jmp    801066da <sys_read+0x7a>
  return fileread(f, p, n);
801066c1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801066c4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801066c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801066ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801066d2:	89 04 24             	mov    %eax,(%esp)
801066d5:	e8 0f aa ff ff       	call   801010e9 <fileread>
}
801066da:	c9                   	leave  
801066db:	c3                   	ret    

801066dc <sys_write>:

int
sys_write(void)
{
801066dc:	55                   	push   %ebp
801066dd:	89 e5                	mov    %esp,%ebp
801066df:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801066e2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801066e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801066e9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801066f0:	00 
801066f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066f8:	e8 4b fe ff ff       	call   80106548 <argfd>
801066fd:	85 c0                	test   %eax,%eax
801066ff:	78 35                	js     80106736 <sys_write+0x5a>
80106701:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106704:	89 44 24 04          	mov    %eax,0x4(%esp)
80106708:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010670f:	e8 92 fc ff ff       	call   801063a6 <argint>
80106714:	85 c0                	test   %eax,%eax
80106716:	78 1e                	js     80106736 <sys_write+0x5a>
80106718:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010671b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010671f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106722:	89 44 24 04          	mov    %eax,0x4(%esp)
80106726:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010672d:	e8 ac fc ff ff       	call   801063de <argptr>
80106732:	85 c0                	test   %eax,%eax
80106734:	79 07                	jns    8010673d <sys_write+0x61>
    return -1;
80106736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010673b:	eb 19                	jmp    80106756 <sys_write+0x7a>
  return filewrite(f, p, n);
8010673d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106740:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106746:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010674a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010674e:	89 04 24             	mov    %eax,(%esp)
80106751:	e8 4f aa ff ff       	call   801011a5 <filewrite>
}
80106756:	c9                   	leave  
80106757:	c3                   	ret    

80106758 <sys_close>:

int
sys_close(void)
{
80106758:	55                   	push   %ebp
80106759:	89 e5                	mov    %esp,%ebp
8010675b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010675e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106761:	89 44 24 08          	mov    %eax,0x8(%esp)
80106765:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106768:	89 44 24 04          	mov    %eax,0x4(%esp)
8010676c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106773:	e8 d0 fd ff ff       	call   80106548 <argfd>
80106778:	85 c0                	test   %eax,%eax
8010677a:	79 07                	jns    80106783 <sys_close+0x2b>
    return -1;
8010677c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106781:	eb 24                	jmp    801067a7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106783:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106789:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010678c:	83 c2 08             	add    $0x8,%edx
8010678f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106796:	00 
  fileclose(f);
80106797:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010679a:	89 04 24             	mov    %eax,(%esp)
8010679d:	e8 22 a8 ff ff       	call   80100fc4 <fileclose>
  return 0;
801067a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067a7:	c9                   	leave  
801067a8:	c3                   	ret    

801067a9 <sys_fstat>:

int
sys_fstat(void)
{
801067a9:	55                   	push   %ebp
801067aa:	89 e5                	mov    %esp,%ebp
801067ac:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801067af:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801067b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067bd:	00 
801067be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067c5:	e8 7e fd ff ff       	call   80106548 <argfd>
801067ca:	85 c0                	test   %eax,%eax
801067cc:	78 1f                	js     801067ed <sys_fstat+0x44>
801067ce:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801067d5:	00 
801067d6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801067d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801067dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801067e4:	e8 f5 fb ff ff       	call   801063de <argptr>
801067e9:	85 c0                	test   %eax,%eax
801067eb:	79 07                	jns    801067f4 <sys_fstat+0x4b>
    return -1;
801067ed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067f2:	eb 12                	jmp    80106806 <sys_fstat+0x5d>
  return filestat(f, st);
801067f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801067f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801067fe:	89 04 24             	mov    %eax,(%esp)
80106801:	e8 94 a8 ff ff       	call   8010109a <filestat>
}
80106806:	c9                   	leave  
80106807:	c3                   	ret    

80106808 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106808:	55                   	push   %ebp
80106809:	89 e5                	mov    %esp,%ebp
8010680b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010680e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106811:	89 44 24 04          	mov    %eax,0x4(%esp)
80106815:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010681c:	e8 1f fc ff ff       	call   80106440 <argstr>
80106821:	85 c0                	test   %eax,%eax
80106823:	78 17                	js     8010683c <sys_link+0x34>
80106825:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106828:	89 44 24 04          	mov    %eax,0x4(%esp)
8010682c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106833:	e8 08 fc ff ff       	call   80106440 <argstr>
80106838:	85 c0                	test   %eax,%eax
8010683a:	79 0a                	jns    80106846 <sys_link+0x3e>
    return -1;
8010683c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106841:	e9 3c 01 00 00       	jmp    80106982 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80106846:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106849:	89 04 24             	mov    %eax,(%esp)
8010684c:	e8 d0 ca ff ff       	call   80103321 <namei>
80106851:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106854:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106858:	75 0a                	jne    80106864 <sys_link+0x5c>
    return -1;
8010685a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010685f:	e9 1e 01 00 00       	jmp    80106982 <sys_link+0x17a>

  begin_trans();
80106864:	e8 18 dc ff ff       	call   80104481 <begin_trans>

  ilock(ip);
80106869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010686c:	89 04 24             	mov    %eax,(%esp)
8010686f:	e8 fc bd ff ff       	call   80102670 <ilock>
  if(ip->type == T_DIR){
80106874:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106877:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010687b:	66 83 f8 01          	cmp    $0x1,%ax
8010687f:	75 1a                	jne    8010689b <sys_link+0x93>
    iunlockput(ip);
80106881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106884:	89 04 24             	mov    %eax,(%esp)
80106887:	e8 68 c0 ff ff       	call   801028f4 <iunlockput>
    commit_trans();
8010688c:	e8 39 dc ff ff       	call   801044ca <commit_trans>
    return -1;
80106891:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106896:	e9 e7 00 00 00       	jmp    80106982 <sys_link+0x17a>
  }

  ip->nlink++;
8010689b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010689e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068a2:	8d 50 01             	lea    0x1(%eax),%edx
801068a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068a8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801068ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068af:	89 04 24             	mov    %eax,(%esp)
801068b2:	e8 fd bb ff ff       	call   801024b4 <iupdate>
  iunlock(ip);
801068b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ba:	89 04 24             	mov    %eax,(%esp)
801068bd:	e8 fc be ff ff       	call   801027be <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801068c2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801068c5:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801068c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801068cc:	89 04 24             	mov    %eax,(%esp)
801068cf:	e8 6f ca ff ff       	call   80103343 <nameiparent>
801068d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068d7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068db:	74 68                	je     80106945 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801068dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e0:	89 04 24             	mov    %eax,(%esp)
801068e3:	e8 88 bd ff ff       	call   80102670 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801068e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068eb:	8b 10                	mov    (%eax),%edx
801068ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f0:	8b 00                	mov    (%eax),%eax
801068f2:	39 c2                	cmp    %eax,%edx
801068f4:	75 20                	jne    80106916 <sys_link+0x10e>
801068f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f9:	8b 40 04             	mov    0x4(%eax),%eax
801068fc:	89 44 24 08          	mov    %eax,0x8(%esp)
80106900:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106903:	89 44 24 04          	mov    %eax,0x4(%esp)
80106907:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010690a:	89 04 24             	mov    %eax,(%esp)
8010690d:	e8 4e c7 ff ff       	call   80103060 <dirlink>
80106912:	85 c0                	test   %eax,%eax
80106914:	79 0d                	jns    80106923 <sys_link+0x11b>
    iunlockput(dp);
80106916:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106919:	89 04 24             	mov    %eax,(%esp)
8010691c:	e8 d3 bf ff ff       	call   801028f4 <iunlockput>
    goto bad;
80106921:	eb 23                	jmp    80106946 <sys_link+0x13e>
  }
  iunlockput(dp);
80106923:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106926:	89 04 24             	mov    %eax,(%esp)
80106929:	e8 c6 bf ff ff       	call   801028f4 <iunlockput>
  iput(ip);
8010692e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106931:	89 04 24             	mov    %eax,(%esp)
80106934:	e8 ea be ff ff       	call   80102823 <iput>

  commit_trans();
80106939:	e8 8c db ff ff       	call   801044ca <commit_trans>

  return 0;
8010693e:	b8 00 00 00 00       	mov    $0x0,%eax
80106943:	eb 3d                	jmp    80106982 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106945:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106946:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106949:	89 04 24             	mov    %eax,(%esp)
8010694c:	e8 1f bd ff ff       	call   80102670 <ilock>
  ip->nlink--;
80106951:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106954:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106958:	8d 50 ff             	lea    -0x1(%eax),%edx
8010695b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010695e:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106962:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106965:	89 04 24             	mov    %eax,(%esp)
80106968:	e8 47 bb ff ff       	call   801024b4 <iupdate>
  iunlockput(ip);
8010696d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106970:	89 04 24             	mov    %eax,(%esp)
80106973:	e8 7c bf ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80106978:	e8 4d db ff ff       	call   801044ca <commit_trans>
  return -1;
8010697d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106982:	c9                   	leave  
80106983:	c3                   	ret    

80106984 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106984:	55                   	push   %ebp
80106985:	89 e5                	mov    %esp,%ebp
80106987:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010698a:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106991:	eb 4b                	jmp    801069de <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106993:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106996:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010699d:	00 
8010699e:	89 44 24 08          	mov    %eax,0x8(%esp)
801069a2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801069a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801069a9:	8b 45 08             	mov    0x8(%ebp),%eax
801069ac:	89 04 24             	mov    %eax,(%esp)
801069af:	e8 22 c2 ff ff       	call   80102bd6 <readi>
801069b4:	83 f8 10             	cmp    $0x10,%eax
801069b7:	74 0c                	je     801069c5 <isdirempty+0x41>
      panic("isdirempty: readi");
801069b9:	c7 04 24 cf 9a 10 80 	movl   $0x80109acf,(%esp)
801069c0:	e8 78 9b ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801069c5:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801069c9:	66 85 c0             	test   %ax,%ax
801069cc:	74 07                	je     801069d5 <isdirempty+0x51>
      return 0;
801069ce:	b8 00 00 00 00       	mov    $0x0,%eax
801069d3:	eb 1b                	jmp    801069f0 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801069d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d8:	83 c0 10             	add    $0x10,%eax
801069db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801069e1:	8b 45 08             	mov    0x8(%ebp),%eax
801069e4:	8b 40 18             	mov    0x18(%eax),%eax
801069e7:	39 c2                	cmp    %eax,%edx
801069e9:	72 a8                	jb     80106993 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801069eb:	b8 01 00 00 00       	mov    $0x1,%eax
}
801069f0:	c9                   	leave  
801069f1:	c3                   	ret    

801069f2 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801069f2:	55                   	push   %ebp
801069f3:	89 e5                	mov    %esp,%ebp
801069f5:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
801069f8:	8d 45 cc             	lea    -0x34(%ebp),%eax
801069fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801069ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a06:	e8 35 fa ff ff       	call   80106440 <argstr>
80106a0b:	85 c0                	test   %eax,%eax
80106a0d:	79 0a                	jns    80106a19 <sys_unlink+0x27>
    return -1;
80106a0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a14:	e9 aa 01 00 00       	jmp    80106bc3 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106a19:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106a1c:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106a1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a23:	89 04 24             	mov    %eax,(%esp)
80106a26:	e8 18 c9 ff ff       	call   80103343 <nameiparent>
80106a2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a2e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a32:	75 0a                	jne    80106a3e <sys_unlink+0x4c>
    return -1;
80106a34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a39:	e9 85 01 00 00       	jmp    80106bc3 <sys_unlink+0x1d1>

  begin_trans();
80106a3e:	e8 3e da ff ff       	call   80104481 <begin_trans>

  ilock(dp);
80106a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a46:	89 04 24             	mov    %eax,(%esp)
80106a49:	e8 22 bc ff ff       	call   80102670 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106a4e:	c7 44 24 04 e1 9a 10 	movl   $0x80109ae1,0x4(%esp)
80106a55:	80 
80106a56:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a59:	89 04 24             	mov    %eax,(%esp)
80106a5c:	e8 15 c5 ff ff       	call   80102f76 <namecmp>
80106a61:	85 c0                	test   %eax,%eax
80106a63:	0f 84 45 01 00 00    	je     80106bae <sys_unlink+0x1bc>
80106a69:	c7 44 24 04 e3 9a 10 	movl   $0x80109ae3,0x4(%esp)
80106a70:	80 
80106a71:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a74:	89 04 24             	mov    %eax,(%esp)
80106a77:	e8 fa c4 ff ff       	call   80102f76 <namecmp>
80106a7c:	85 c0                	test   %eax,%eax
80106a7e:	0f 84 2a 01 00 00    	je     80106bae <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106a84:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106a87:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a8b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a8e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a95:	89 04 24             	mov    %eax,(%esp)
80106a98:	e8 fb c4 ff ff       	call   80102f98 <dirlookup>
80106a9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106aa0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106aa4:	0f 84 03 01 00 00    	je     80106bad <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106aaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aad:	89 04 24             	mov    %eax,(%esp)
80106ab0:	e8 bb bb ff ff       	call   80102670 <ilock>

  if(ip->nlink < 1)
80106ab5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106abc:	66 85 c0             	test   %ax,%ax
80106abf:	7f 0c                	jg     80106acd <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106ac1:	c7 04 24 e6 9a 10 80 	movl   $0x80109ae6,(%esp)
80106ac8:	e8 70 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106acd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ad0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ad4:	66 83 f8 01          	cmp    $0x1,%ax
80106ad8:	75 1f                	jne    80106af9 <sys_unlink+0x107>
80106ada:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106add:	89 04 24             	mov    %eax,(%esp)
80106ae0:	e8 9f fe ff ff       	call   80106984 <isdirempty>
80106ae5:	85 c0                	test   %eax,%eax
80106ae7:	75 10                	jne    80106af9 <sys_unlink+0x107>
    iunlockput(ip);
80106ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aec:	89 04 24             	mov    %eax,(%esp)
80106aef:	e8 00 be ff ff       	call   801028f4 <iunlockput>
    goto bad;
80106af4:	e9 b5 00 00 00       	jmp    80106bae <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106af9:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106b00:	00 
80106b01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b08:	00 
80106b09:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b0c:	89 04 24             	mov    %eax,(%esp)
80106b0f:	e8 42 f5 ff ff       	call   80106056 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106b14:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106b17:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106b1e:	00 
80106b1f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b23:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b26:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b2d:	89 04 24             	mov    %eax,(%esp)
80106b30:	e8 0c c2 ff ff       	call   80102d41 <writei>
80106b35:	83 f8 10             	cmp    $0x10,%eax
80106b38:	74 0c                	je     80106b46 <sys_unlink+0x154>
    panic("unlink: writei");
80106b3a:	c7 04 24 f8 9a 10 80 	movl   $0x80109af8,(%esp)
80106b41:	e8 f7 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106b46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b49:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b4d:	66 83 f8 01          	cmp    $0x1,%ax
80106b51:	75 1c                	jne    80106b6f <sys_unlink+0x17d>
    dp->nlink--;
80106b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b56:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b5a:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b60:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b67:	89 04 24             	mov    %eax,(%esp)
80106b6a:	e8 45 b9 ff ff       	call   801024b4 <iupdate>
  }
  iunlockput(dp);
80106b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b72:	89 04 24             	mov    %eax,(%esp)
80106b75:	e8 7a bd ff ff       	call   801028f4 <iunlockput>

  ip->nlink--;
80106b7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b7d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b81:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b87:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106b8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b8e:	89 04 24             	mov    %eax,(%esp)
80106b91:	e8 1e b9 ff ff       	call   801024b4 <iupdate>
  iunlockput(ip);
80106b96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b99:	89 04 24             	mov    %eax,(%esp)
80106b9c:	e8 53 bd ff ff       	call   801028f4 <iunlockput>

  commit_trans();
80106ba1:	e8 24 d9 ff ff       	call   801044ca <commit_trans>

  return 0;
80106ba6:	b8 00 00 00 00       	mov    $0x0,%eax
80106bab:	eb 16                	jmp    80106bc3 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106bad:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb1:	89 04 24             	mov    %eax,(%esp)
80106bb4:	e8 3b bd ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80106bb9:	e8 0c d9 ff ff       	call   801044ca <commit_trans>
  return -1;
80106bbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106bc3:	c9                   	leave  
80106bc4:	c3                   	ret    

80106bc5 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106bc5:	55                   	push   %ebp
80106bc6:	89 e5                	mov    %esp,%ebp
80106bc8:	83 ec 48             	sub    $0x48,%esp
80106bcb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106bce:	8b 55 10             	mov    0x10(%ebp),%edx
80106bd1:	8b 45 14             	mov    0x14(%ebp),%eax
80106bd4:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106bd8:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106bdc:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106be0:	8d 45 de             	lea    -0x22(%ebp),%eax
80106be3:	89 44 24 04          	mov    %eax,0x4(%esp)
80106be7:	8b 45 08             	mov    0x8(%ebp),%eax
80106bea:	89 04 24             	mov    %eax,(%esp)
80106bed:	e8 51 c7 ff ff       	call   80103343 <nameiparent>
80106bf2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bf5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bf9:	75 0a                	jne    80106c05 <create+0x40>
    return 0;
80106bfb:	b8 00 00 00 00       	mov    $0x0,%eax
80106c00:	e9 7e 01 00 00       	jmp    80106d83 <create+0x1be>
  ilock(dp);
80106c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c08:	89 04 24             	mov    %eax,(%esp)
80106c0b:	e8 60 ba ff ff       	call   80102670 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106c10:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c13:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c17:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c21:	89 04 24             	mov    %eax,(%esp)
80106c24:	e8 6f c3 ff ff       	call   80102f98 <dirlookup>
80106c29:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c2c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c30:	74 47                	je     80106c79 <create+0xb4>
    iunlockput(dp);
80106c32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c35:	89 04 24             	mov    %eax,(%esp)
80106c38:	e8 b7 bc ff ff       	call   801028f4 <iunlockput>
    ilock(ip);
80106c3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c40:	89 04 24             	mov    %eax,(%esp)
80106c43:	e8 28 ba ff ff       	call   80102670 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106c48:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106c4d:	75 15                	jne    80106c64 <create+0x9f>
80106c4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c52:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c56:	66 83 f8 02          	cmp    $0x2,%ax
80106c5a:	75 08                	jne    80106c64 <create+0x9f>
      return ip;
80106c5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c5f:	e9 1f 01 00 00       	jmp    80106d83 <create+0x1be>
    iunlockput(ip);
80106c64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c67:	89 04 24             	mov    %eax,(%esp)
80106c6a:	e8 85 bc ff ff       	call   801028f4 <iunlockput>
    return 0;
80106c6f:	b8 00 00 00 00       	mov    $0x0,%eax
80106c74:	e9 0a 01 00 00       	jmp    80106d83 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106c79:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c80:	8b 00                	mov    (%eax),%eax
80106c82:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c86:	89 04 24             	mov    %eax,(%esp)
80106c89:	e8 49 b7 ff ff       	call   801023d7 <ialloc>
80106c8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c91:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c95:	75 0c                	jne    80106ca3 <create+0xde>
    panic("create: ialloc");
80106c97:	c7 04 24 07 9b 10 80 	movl   $0x80109b07,(%esp)
80106c9e:	e8 9a 98 ff ff       	call   8010053d <panic>

  ilock(ip);
80106ca3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca6:	89 04 24             	mov    %eax,(%esp)
80106ca9:	e8 c2 b9 ff ff       	call   80102670 <ilock>
  ip->major = major;
80106cae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb1:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106cb5:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106cb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cbc:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106cc0:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106cc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cc7:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106ccd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cd0:	89 04 24             	mov    %eax,(%esp)
80106cd3:	e8 dc b7 ff ff       	call   801024b4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106cd8:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106cdd:	75 6a                	jne    80106d49 <create+0x184>
    dp->nlink++;  // for ".."
80106cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ce2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106ce6:	8d 50 01             	lea    0x1(%eax),%edx
80106ce9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cec:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cf3:	89 04 24             	mov    %eax,(%esp)
80106cf6:	e8 b9 b7 ff ff       	call   801024b4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cfe:	8b 40 04             	mov    0x4(%eax),%eax
80106d01:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d05:	c7 44 24 04 e1 9a 10 	movl   $0x80109ae1,0x4(%esp)
80106d0c:	80 
80106d0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d10:	89 04 24             	mov    %eax,(%esp)
80106d13:	e8 48 c3 ff ff       	call   80103060 <dirlink>
80106d18:	85 c0                	test   %eax,%eax
80106d1a:	78 21                	js     80106d3d <create+0x178>
80106d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d1f:	8b 40 04             	mov    0x4(%eax),%eax
80106d22:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d26:	c7 44 24 04 e3 9a 10 	movl   $0x80109ae3,0x4(%esp)
80106d2d:	80 
80106d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d31:	89 04 24             	mov    %eax,(%esp)
80106d34:	e8 27 c3 ff ff       	call   80103060 <dirlink>
80106d39:	85 c0                	test   %eax,%eax
80106d3b:	79 0c                	jns    80106d49 <create+0x184>
      panic("create dots");
80106d3d:	c7 04 24 16 9b 10 80 	movl   $0x80109b16,(%esp)
80106d44:	e8 f4 97 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106d49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d4c:	8b 40 04             	mov    0x4(%eax),%eax
80106d4f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d53:	8d 45 de             	lea    -0x22(%ebp),%eax
80106d56:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d5d:	89 04 24             	mov    %eax,(%esp)
80106d60:	e8 fb c2 ff ff       	call   80103060 <dirlink>
80106d65:	85 c0                	test   %eax,%eax
80106d67:	79 0c                	jns    80106d75 <create+0x1b0>
    panic("create: dirlink");
80106d69:	c7 04 24 22 9b 10 80 	movl   $0x80109b22,(%esp)
80106d70:	e8 c8 97 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106d75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d78:	89 04 24             	mov    %eax,(%esp)
80106d7b:	e8 74 bb ff ff       	call   801028f4 <iunlockput>

  return ip;
80106d80:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106d83:	c9                   	leave  
80106d84:	c3                   	ret    

80106d85 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80106d85:	55                   	push   %ebp
80106d86:	89 e5                	mov    %esp,%ebp
80106d88:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106d8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d8e:	25 00 02 00 00       	and    $0x200,%eax
80106d93:	85 c0                	test   %eax,%eax
80106d95:	74 40                	je     80106dd7 <fileopen+0x52>
    begin_trans();
80106d97:	e8 e5 d6 ff ff       	call   80104481 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106d9c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106da3:	00 
80106da4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106dab:	00 
80106dac:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106db3:	00 
80106db4:	8b 45 08             	mov    0x8(%ebp),%eax
80106db7:	89 04 24             	mov    %eax,(%esp)
80106dba:	e8 06 fe ff ff       	call   80106bc5 <create>
80106dbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106dc2:	e8 03 d7 ff ff       	call   801044ca <commit_trans>
    if(ip == 0)
80106dc7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106dcb:	75 5b                	jne    80106e28 <fileopen+0xa3>
      return 0;
80106dcd:	b8 00 00 00 00       	mov    $0x0,%eax
80106dd2:	e9 e5 00 00 00       	jmp    80106ebc <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106dd7:	8b 45 08             	mov    0x8(%ebp),%eax
80106dda:	89 04 24             	mov    %eax,(%esp)
80106ddd:	e8 3f c5 ff ff       	call   80103321 <namei>
80106de2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106de5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106de9:	75 0a                	jne    80106df5 <fileopen+0x70>
      return 0;
80106deb:	b8 00 00 00 00       	mov    $0x0,%eax
80106df0:	e9 c7 00 00 00       	jmp    80106ebc <fileopen+0x137>
    ilock(ip);
80106df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106df8:	89 04 24             	mov    %eax,(%esp)
80106dfb:	e8 70 b8 ff ff       	call   80102670 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106e00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e03:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e07:	66 83 f8 01          	cmp    $0x1,%ax
80106e0b:	75 1b                	jne    80106e28 <fileopen+0xa3>
80106e0d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106e11:	74 15                	je     80106e28 <fileopen+0xa3>
      iunlockput(ip);
80106e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e16:	89 04 24             	mov    %eax,(%esp)
80106e19:	e8 d6 ba ff ff       	call   801028f4 <iunlockput>
      return 0;
80106e1e:	b8 00 00 00 00       	mov    $0x0,%eax
80106e23:	e9 94 00 00 00       	jmp    80106ebc <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106e28:	e8 ef a0 ff ff       	call   80100f1c <filealloc>
80106e2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106e30:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e34:	75 23                	jne    80106e59 <fileopen+0xd4>
    if(f)
80106e36:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e3a:	74 0b                	je     80106e47 <fileopen+0xc2>
      fileclose(f);
80106e3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e3f:	89 04 24             	mov    %eax,(%esp)
80106e42:	e8 7d a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106e47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e4a:	89 04 24             	mov    %eax,(%esp)
80106e4d:	e8 a2 ba ff ff       	call   801028f4 <iunlockput>
    return 0;
80106e52:	b8 00 00 00 00       	mov    $0x0,%eax
80106e57:	eb 63                	jmp    80106ebc <fileopen+0x137>
  }
  iunlock(ip);
80106e59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e5c:	89 04 24             	mov    %eax,(%esp)
80106e5f:	e8 5a b9 ff ff       	call   801027be <iunlock>

  f->type = FD_INODE;
80106e64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e67:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106e6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e70:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e73:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106e76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e79:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106e80:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e83:	83 e0 01             	and    $0x1,%eax
80106e86:	85 c0                	test   %eax,%eax
80106e88:	0f 94 c2             	sete   %dl
80106e8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e8e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106e91:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e94:	83 e0 01             	and    $0x1,%eax
80106e97:	84 c0                	test   %al,%al
80106e99:	75 0a                	jne    80106ea5 <fileopen+0x120>
80106e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e9e:	83 e0 02             	and    $0x2,%eax
80106ea1:	85 c0                	test   %eax,%eax
80106ea3:	74 07                	je     80106eac <fileopen+0x127>
80106ea5:	b8 01 00 00 00       	mov    $0x1,%eax
80106eaa:	eb 05                	jmp    80106eb1 <fileopen+0x12c>
80106eac:	b8 00 00 00 00       	mov    $0x0,%eax
80106eb1:	89 c2                	mov    %eax,%edx
80106eb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eb6:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106eb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106ebc:	c9                   	leave  
80106ebd:	c3                   	ret    

80106ebe <sys_open>:

int
sys_open(void)
{
80106ebe:	55                   	push   %ebp
80106ebf:	89 e5                	mov    %esp,%ebp
80106ec1:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106ec4:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ecb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ed2:	e8 69 f5 ff ff       	call   80106440 <argstr>
80106ed7:	85 c0                	test   %eax,%eax
80106ed9:	78 17                	js     80106ef2 <sys_open+0x34>
80106edb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106ede:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ee2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106ee9:	e8 b8 f4 ff ff       	call   801063a6 <argint>
80106eee:	85 c0                	test   %eax,%eax
80106ef0:	79 0a                	jns    80106efc <sys_open+0x3e>
    return -1;
80106ef2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ef7:	e9 46 01 00 00       	jmp    80107042 <sys_open+0x184>
  if(omode & O_CREATE){
80106efc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106eff:	25 00 02 00 00       	and    $0x200,%eax
80106f04:	85 c0                	test   %eax,%eax
80106f06:	74 40                	je     80106f48 <sys_open+0x8a>
    begin_trans();
80106f08:	e8 74 d5 ff ff       	call   80104481 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106f0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f10:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106f17:	00 
80106f18:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106f1f:	00 
80106f20:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106f27:	00 
80106f28:	89 04 24             	mov    %eax,(%esp)
80106f2b:	e8 95 fc ff ff       	call   80106bc5 <create>
80106f30:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106f33:	e8 92 d5 ff ff       	call   801044ca <commit_trans>
    if(ip == 0)
80106f38:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f3c:	75 5c                	jne    80106f9a <sys_open+0xdc>
      return -1;
80106f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f43:	e9 fa 00 00 00       	jmp    80107042 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106f48:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f4b:	89 04 24             	mov    %eax,(%esp)
80106f4e:	e8 ce c3 ff ff       	call   80103321 <namei>
80106f53:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106f56:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f5a:	75 0a                	jne    80106f66 <sys_open+0xa8>
      return -1;
80106f5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f61:	e9 dc 00 00 00       	jmp    80107042 <sys_open+0x184>
    ilock(ip);
80106f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f69:	89 04 24             	mov    %eax,(%esp)
80106f6c:	e8 ff b6 ff ff       	call   80102670 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f74:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106f78:	66 83 f8 01          	cmp    $0x1,%ax
80106f7c:	75 1c                	jne    80106f9a <sys_open+0xdc>
80106f7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f81:	85 c0                	test   %eax,%eax
80106f83:	74 15                	je     80106f9a <sys_open+0xdc>
      iunlockput(ip);
80106f85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f88:	89 04 24             	mov    %eax,(%esp)
80106f8b:	e8 64 b9 ff ff       	call   801028f4 <iunlockput>
      return -1;
80106f90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f95:	e9 a8 00 00 00       	jmp    80107042 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106f9a:	e8 7d 9f ff ff       	call   80100f1c <filealloc>
80106f9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106fa2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fa6:	74 14                	je     80106fbc <sys_open+0xfe>
80106fa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fab:	89 04 24             	mov    %eax,(%esp)
80106fae:	e8 0a f6 ff ff       	call   801065bd <fdalloc>
80106fb3:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106fb6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106fba:	79 23                	jns    80106fdf <sys_open+0x121>
    if(f)
80106fbc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fc0:	74 0b                	je     80106fcd <sys_open+0x10f>
      fileclose(f);
80106fc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fc5:	89 04 24             	mov    %eax,(%esp)
80106fc8:	e8 f7 9f ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106fcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fd0:	89 04 24             	mov    %eax,(%esp)
80106fd3:	e8 1c b9 ff ff       	call   801028f4 <iunlockput>
    return -1;
80106fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fdd:	eb 63                	jmp    80107042 <sys_open+0x184>
  }
  iunlock(ip);
80106fdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fe2:	89 04 24             	mov    %eax,(%esp)
80106fe5:	e8 d4 b7 ff ff       	call   801027be <iunlock>

  f->type = FD_INODE;
80106fea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fed:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106ff3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ff6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ff9:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106ffc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fff:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80107006:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107009:	83 e0 01             	and    $0x1,%eax
8010700c:	85 c0                	test   %eax,%eax
8010700e:	0f 94 c2             	sete   %dl
80107011:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107014:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80107017:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010701a:	83 e0 01             	and    $0x1,%eax
8010701d:	84 c0                	test   %al,%al
8010701f:	75 0a                	jne    8010702b <sys_open+0x16d>
80107021:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107024:	83 e0 02             	and    $0x2,%eax
80107027:	85 c0                	test   %eax,%eax
80107029:	74 07                	je     80107032 <sys_open+0x174>
8010702b:	b8 01 00 00 00       	mov    $0x1,%eax
80107030:	eb 05                	jmp    80107037 <sys_open+0x179>
80107032:	b8 00 00 00 00       	mov    $0x0,%eax
80107037:	89 c2                	mov    %eax,%edx
80107039:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010703c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010703f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80107042:	c9                   	leave  
80107043:	c3                   	ret    

80107044 <sys_mkdir>:

int
sys_mkdir(void)
{
80107044:	55                   	push   %ebp
80107045:	89 e5                	mov    %esp,%ebp
80107047:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
8010704a:	e8 32 d4 ff ff       	call   80104481 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010704f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107052:	89 44 24 04          	mov    %eax,0x4(%esp)
80107056:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010705d:	e8 de f3 ff ff       	call   80106440 <argstr>
80107062:	85 c0                	test   %eax,%eax
80107064:	78 2c                	js     80107092 <sys_mkdir+0x4e>
80107066:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107069:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80107070:	00 
80107071:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107078:	00 
80107079:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107080:	00 
80107081:	89 04 24             	mov    %eax,(%esp)
80107084:	e8 3c fb ff ff       	call   80106bc5 <create>
80107089:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010708c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107090:	75 0c                	jne    8010709e <sys_mkdir+0x5a>
    commit_trans();
80107092:	e8 33 d4 ff ff       	call   801044ca <commit_trans>
    return -1;
80107097:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010709c:	eb 15                	jmp    801070b3 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010709e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070a1:	89 04 24             	mov    %eax,(%esp)
801070a4:	e8 4b b8 ff ff       	call   801028f4 <iunlockput>
  commit_trans();
801070a9:	e8 1c d4 ff ff       	call   801044ca <commit_trans>
  return 0;
801070ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070b3:	c9                   	leave  
801070b4:	c3                   	ret    

801070b5 <sys_mknod>:

int
sys_mknod(void)
{
801070b5:	55                   	push   %ebp
801070b6:	89 e5                	mov    %esp,%ebp
801070b8:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801070bb:	e8 c1 d3 ff ff       	call   80104481 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801070c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801070c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801070c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070ce:	e8 6d f3 ff ff       	call   80106440 <argstr>
801070d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801070d6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801070da:	78 5e                	js     8010713a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801070dc:	8d 45 e8             	lea    -0x18(%ebp),%eax
801070df:	89 44 24 04          	mov    %eax,0x4(%esp)
801070e3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801070ea:	e8 b7 f2 ff ff       	call   801063a6 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801070ef:	85 c0                	test   %eax,%eax
801070f1:	78 47                	js     8010713a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801070f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801070f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801070fa:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80107101:	e8 a0 f2 ff ff       	call   801063a6 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80107106:	85 c0                	test   %eax,%eax
80107108:	78 30                	js     8010713a <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010710a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010710d:	0f bf c8             	movswl %ax,%ecx
80107110:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107113:	0f bf d0             	movswl %ax,%edx
80107116:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107119:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010711d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107121:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107128:	00 
80107129:	89 04 24             	mov    %eax,(%esp)
8010712c:	e8 94 fa ff ff       	call   80106bc5 <create>
80107131:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107134:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107138:	75 0c                	jne    80107146 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
8010713a:	e8 8b d3 ff ff       	call   801044ca <commit_trans>
    return -1;
8010713f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107144:	eb 15                	jmp    8010715b <sys_mknod+0xa6>
  }
  iunlockput(ip);
80107146:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107149:	89 04 24             	mov    %eax,(%esp)
8010714c:	e8 a3 b7 ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80107151:	e8 74 d3 ff ff       	call   801044ca <commit_trans>
  return 0;
80107156:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010715b:	c9                   	leave  
8010715c:	c3                   	ret    

8010715d <sys_chdir>:

int
sys_chdir(void)
{
8010715d:	55                   	push   %ebp
8010715e:	89 e5                	mov    %esp,%ebp
80107160:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80107163:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107166:	89 44 24 04          	mov    %eax,0x4(%esp)
8010716a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107171:	e8 ca f2 ff ff       	call   80106440 <argstr>
80107176:	85 c0                	test   %eax,%eax
80107178:	78 14                	js     8010718e <sys_chdir+0x31>
8010717a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010717d:	89 04 24             	mov    %eax,(%esp)
80107180:	e8 9c c1 ff ff       	call   80103321 <namei>
80107185:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107188:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010718c:	75 07                	jne    80107195 <sys_chdir+0x38>
    return -1;
8010718e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107193:	eb 57                	jmp    801071ec <sys_chdir+0x8f>
  ilock(ip);
80107195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107198:	89 04 24             	mov    %eax,(%esp)
8010719b:	e8 d0 b4 ff ff       	call   80102670 <ilock>
  if(ip->type != T_DIR){
801071a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071a3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801071a7:	66 83 f8 01          	cmp    $0x1,%ax
801071ab:	74 12                	je     801071bf <sys_chdir+0x62>
    iunlockput(ip);
801071ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071b0:	89 04 24             	mov    %eax,(%esp)
801071b3:	e8 3c b7 ff ff       	call   801028f4 <iunlockput>
    return -1;
801071b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071bd:	eb 2d                	jmp    801071ec <sys_chdir+0x8f>
  }
  iunlock(ip);
801071bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071c2:	89 04 24             	mov    %eax,(%esp)
801071c5:	e8 f4 b5 ff ff       	call   801027be <iunlock>
  iput(proc->cwd);
801071ca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071d0:	8b 40 68             	mov    0x68(%eax),%eax
801071d3:	89 04 24             	mov    %eax,(%esp)
801071d6:	e8 48 b6 ff ff       	call   80102823 <iput>
  proc->cwd = ip;
801071db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801071e4:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801071e7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801071ec:	c9                   	leave  
801071ed:	c3                   	ret    

801071ee <sys_exec>:

int
sys_exec(void)
{
801071ee:	55                   	push   %ebp
801071ef:	89 e5                	mov    %esp,%ebp
801071f1:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801071f7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801071fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801071fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107205:	e8 36 f2 ff ff       	call   80106440 <argstr>
8010720a:	85 c0                	test   %eax,%eax
8010720c:	78 1a                	js     80107228 <sys_exec+0x3a>
8010720e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80107214:	89 44 24 04          	mov    %eax,0x4(%esp)
80107218:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010721f:	e8 82 f1 ff ff       	call   801063a6 <argint>
80107224:	85 c0                	test   %eax,%eax
80107226:	79 0a                	jns    80107232 <sys_exec+0x44>
    return -1;
80107228:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010722d:	e9 e2 00 00 00       	jmp    80107314 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107232:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80107239:	00 
8010723a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107241:	00 
80107242:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107248:	89 04 24             	mov    %eax,(%esp)
8010724b:	e8 06 ee ff ff       	call   80106056 <memset>
  for(i=0;; i++){
80107250:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80107257:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010725a:	83 f8 1f             	cmp    $0x1f,%eax
8010725d:	76 0a                	jbe    80107269 <sys_exec+0x7b>
      return -1;
8010725f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107264:	e9 ab 00 00 00       	jmp    80107314 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80107269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010726c:	c1 e0 02             	shl    $0x2,%eax
8010726f:	89 c2                	mov    %eax,%edx
80107271:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80107277:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
8010727a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107280:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80107286:	89 54 24 08          	mov    %edx,0x8(%esp)
8010728a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010728e:	89 04 24             	mov    %eax,(%esp)
80107291:	e8 7e f0 ff ff       	call   80106314 <fetchint>
80107296:	85 c0                	test   %eax,%eax
80107298:	79 07                	jns    801072a1 <sys_exec+0xb3>
      return -1;
8010729a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010729f:	eb 73                	jmp    80107314 <sys_exec+0x126>
    if(uarg == 0){
801072a1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801072a7:	85 c0                	test   %eax,%eax
801072a9:	75 26                	jne    801072d1 <sys_exec+0xe3>
      argv[i] = 0;
801072ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072ae:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801072b5:	00 00 00 00 
      break;
801072b9:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801072ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801072bd:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801072c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801072c7:	89 04 24             	mov    %eax,(%esp)
801072ca:	e8 2d 98 ff ff       	call   80100afc <exec>
801072cf:	eb 43                	jmp    80107314 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801072d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072d4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801072db:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801072e1:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801072e4:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801072ea:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801072f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801072f8:	89 04 24             	mov    %eax,(%esp)
801072fb:	e8 48 f0 ff ff       	call   80106348 <fetchstr>
80107300:	85 c0                	test   %eax,%eax
80107302:	79 07                	jns    8010730b <sys_exec+0x11d>
      return -1;
80107304:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107309:	eb 09                	jmp    80107314 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010730b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010730f:	e9 43 ff ff ff       	jmp    80107257 <sys_exec+0x69>
  return exec(path, argv);
}
80107314:	c9                   	leave  
80107315:	c3                   	ret    

80107316 <sys_pipe>:

int
sys_pipe(void)
{
80107316:	55                   	push   %ebp
80107317:	89 e5                	mov    %esp,%ebp
80107319:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010731c:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107323:	00 
80107324:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107327:	89 44 24 04          	mov    %eax,0x4(%esp)
8010732b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107332:	e8 a7 f0 ff ff       	call   801063de <argptr>
80107337:	85 c0                	test   %eax,%eax
80107339:	79 0a                	jns    80107345 <sys_pipe+0x2f>
    return -1;
8010733b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107340:	e9 9b 00 00 00       	jmp    801073e0 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80107345:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107348:	89 44 24 04          	mov    %eax,0x4(%esp)
8010734c:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010734f:	89 04 24             	mov    %eax,(%esp)
80107352:	e8 45 db ff ff       	call   80104e9c <pipealloc>
80107357:	85 c0                	test   %eax,%eax
80107359:	79 07                	jns    80107362 <sys_pipe+0x4c>
    return -1;
8010735b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107360:	eb 7e                	jmp    801073e0 <sys_pipe+0xca>
  fd0 = -1;
80107362:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80107369:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010736c:	89 04 24             	mov    %eax,(%esp)
8010736f:	e8 49 f2 ff ff       	call   801065bd <fdalloc>
80107374:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107377:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010737b:	78 14                	js     80107391 <sys_pipe+0x7b>
8010737d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107380:	89 04 24             	mov    %eax,(%esp)
80107383:	e8 35 f2 ff ff       	call   801065bd <fdalloc>
80107388:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010738b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010738f:	79 37                	jns    801073c8 <sys_pipe+0xb2>
    if(fd0 >= 0)
80107391:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107395:	78 14                	js     801073ab <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80107397:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010739d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801073a0:	83 c2 08             	add    $0x8,%edx
801073a3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801073aa:	00 
    fileclose(rf);
801073ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
801073ae:	89 04 24             	mov    %eax,(%esp)
801073b1:	e8 0e 9c ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
801073b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801073b9:	89 04 24             	mov    %eax,(%esp)
801073bc:	e8 03 9c ff ff       	call   80100fc4 <fileclose>
    return -1;
801073c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073c6:	eb 18                	jmp    801073e0 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801073c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801073cb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801073ce:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801073d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801073d3:	8d 50 04             	lea    0x4(%eax),%edx
801073d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801073d9:	89 02                	mov    %eax,(%edx)
  return 0;
801073db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801073e0:	c9                   	leave  
801073e1:	c3                   	ret    
	...

801073e4 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801073e4:	55                   	push   %ebp
801073e5:	89 e5                	mov    %esp,%ebp
801073e7:	83 ec 08             	sub    $0x8,%esp
  return fork();
801073ea:	e8 67 e1 ff ff       	call   80105556 <fork>
}
801073ef:	c9                   	leave  
801073f0:	c3                   	ret    

801073f1 <sys_exit>:

int
sys_exit(void)
{
801073f1:	55                   	push   %ebp
801073f2:	89 e5                	mov    %esp,%ebp
801073f4:	83 ec 08             	sub    $0x8,%esp
  exit();
801073f7:	e8 bd e2 ff ff       	call   801056b9 <exit>
  return 0;  // not reached
801073fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107401:	c9                   	leave  
80107402:	c3                   	ret    

80107403 <sys_wait>:

int
sys_wait(void)
{
80107403:	55                   	push   %ebp
80107404:	89 e5                	mov    %esp,%ebp
80107406:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107409:	e8 c3 e3 ff ff       	call   801057d1 <wait>
}
8010740e:	c9                   	leave  
8010740f:	c3                   	ret    

80107410 <sys_kill>:

int
sys_kill(void)
{
80107410:	55                   	push   %ebp
80107411:	89 e5                	mov    %esp,%ebp
80107413:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80107416:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107419:	89 44 24 04          	mov    %eax,0x4(%esp)
8010741d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107424:	e8 7d ef ff ff       	call   801063a6 <argint>
80107429:	85 c0                	test   %eax,%eax
8010742b:	79 07                	jns    80107434 <sys_kill+0x24>
    return -1;
8010742d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107432:	eb 0b                	jmp    8010743f <sys_kill+0x2f>
  return kill(pid);
80107434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107437:	89 04 24             	mov    %eax,(%esp)
8010743a:	e8 ee e7 ff ff       	call   80105c2d <kill>
}
8010743f:	c9                   	leave  
80107440:	c3                   	ret    

80107441 <sys_getpid>:

int
sys_getpid(void)
{
80107441:	55                   	push   %ebp
80107442:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107444:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010744a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010744d:	5d                   	pop    %ebp
8010744e:	c3                   	ret    

8010744f <sys_sbrk>:

int
sys_sbrk(void)
{
8010744f:	55                   	push   %ebp
80107450:	89 e5                	mov    %esp,%ebp
80107452:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107455:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107458:	89 44 24 04          	mov    %eax,0x4(%esp)
8010745c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107463:	e8 3e ef ff ff       	call   801063a6 <argint>
80107468:	85 c0                	test   %eax,%eax
8010746a:	79 07                	jns    80107473 <sys_sbrk+0x24>
    return -1;
8010746c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107471:	eb 24                	jmp    80107497 <sys_sbrk+0x48>
  addr = proc->sz;
80107473:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107479:	8b 00                	mov    (%eax),%eax
8010747b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010747e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107481:	89 04 24             	mov    %eax,(%esp)
80107484:	e8 28 e0 ff ff       	call   801054b1 <growproc>
80107489:	85 c0                	test   %eax,%eax
8010748b:	79 07                	jns    80107494 <sys_sbrk+0x45>
    return -1;
8010748d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107492:	eb 03                	jmp    80107497 <sys_sbrk+0x48>
  return addr;
80107494:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107497:	c9                   	leave  
80107498:	c3                   	ret    

80107499 <sys_sleep>:

int
sys_sleep(void)
{
80107499:	55                   	push   %ebp
8010749a:	89 e5                	mov    %esp,%ebp
8010749c:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010749f:	8d 45 f0             	lea    -0x10(%ebp),%eax
801074a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801074a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801074ad:	e8 f4 ee ff ff       	call   801063a6 <argint>
801074b2:	85 c0                	test   %eax,%eax
801074b4:	79 07                	jns    801074bd <sys_sleep+0x24>
    return -1;
801074b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074bb:	eb 6c                	jmp    80107529 <sys_sleep+0x90>
  acquire(&tickslock);
801074bd:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801074c4:	e8 3e e9 ff ff       	call   80105e07 <acquire>
  ticks0 = ticks;
801074c9:	a1 e0 36 11 80       	mov    0x801136e0,%eax
801074ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801074d1:	eb 34                	jmp    80107507 <sys_sleep+0x6e>
    if(proc->killed){
801074d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074d9:	8b 40 24             	mov    0x24(%eax),%eax
801074dc:	85 c0                	test   %eax,%eax
801074de:	74 13                	je     801074f3 <sys_sleep+0x5a>
      release(&tickslock);
801074e0:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801074e7:	e8 7d e9 ff ff       	call   80105e69 <release>
      return -1;
801074ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074f1:	eb 36                	jmp    80107529 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801074f3:	c7 44 24 04 a0 2e 11 	movl   $0x80112ea0,0x4(%esp)
801074fa:	80 
801074fb:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
80107502:	e8 22 e6 ff ff       	call   80105b29 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80107507:	a1 e0 36 11 80       	mov    0x801136e0,%eax
8010750c:	89 c2                	mov    %eax,%edx
8010750e:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107511:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107514:	39 c2                	cmp    %eax,%edx
80107516:	72 bb                	jb     801074d3 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107518:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
8010751f:	e8 45 e9 ff ff       	call   80105e69 <release>
  return 0;
80107524:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107529:	c9                   	leave  
8010752a:	c3                   	ret    

8010752b <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010752b:	55                   	push   %ebp
8010752c:	89 e5                	mov    %esp,%ebp
8010752e:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107531:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107538:	e8 ca e8 ff ff       	call   80105e07 <acquire>
  xticks = ticks;
8010753d:	a1 e0 36 11 80       	mov    0x801136e0,%eax
80107542:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107545:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
8010754c:	e8 18 e9 ff ff       	call   80105e69 <release>
  return xticks;
80107551:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107554:	c9                   	leave  
80107555:	c3                   	ret    

80107556 <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
80107556:	55                   	push   %ebp
80107557:	89 e5                	mov    %esp,%ebp
80107559:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
8010755c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010755f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107563:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010756a:	e8 d1 ee ff ff       	call   80106440 <argstr>
8010756f:	85 c0                	test   %eax,%eax
80107571:	79 07                	jns    8010757a <sys_getFileBlocks+0x24>
    return -1;
80107573:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107578:	eb 0b                	jmp    80107585 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
8010757a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010757d:	89 04 24             	mov    %eax,(%esp)
80107580:	e8 65 9d ff ff       	call   801012ea <getFileBlocks>
}
80107585:	c9                   	leave  
80107586:	c3                   	ret    

80107587 <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
80107587:	55                   	push   %ebp
80107588:	89 e5                	mov    %esp,%ebp
8010758a:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
8010758d:	e8 b5 9e ff ff       	call   80101447 <getFreeBlocks>
}
80107592:	c9                   	leave  
80107593:	c3                   	ret    

80107594 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
80107594:	55                   	push   %ebp
80107595:	89 e5                	mov    %esp,%ebp
80107597:	83 ec 08             	sub    $0x8,%esp
  return getSharedBlocksRate();
8010759a:	e8 27 a9 ff ff       	call   80101ec6 <getSharedBlocksRate>
}
8010759f:	c9                   	leave  
801075a0:	c3                   	ret    

801075a1 <sys_dedup>:

int
sys_dedup(void)
{
801075a1:	55                   	push   %ebp
801075a2:	89 e5                	mov    %esp,%ebp
801075a4:	83 ec 08             	sub    $0x8,%esp
  return dedup();
801075a7:	e8 dd a0 ff ff       	call   80101689 <dedup>
}
801075ac:	c9                   	leave  
801075ad:	c3                   	ret    

801075ae <sys_getBlkRef>:

int
sys_getBlkRef(void)
{
801075ae:	55                   	push   %ebp
801075af:	89 e5                	mov    %esp,%ebp
801075b1:	83 ec 28             	sub    $0x28,%esp
  int n;
  if(argint(0, &n) < 0)
801075b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
801075b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801075bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075c2:	e8 df ed ff ff       	call   801063a6 <argint>
801075c7:	85 c0                	test   %eax,%eax
801075c9:	79 07                	jns    801075d2 <sys_getBlkRef+0x24>
    return -1;
801075cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075d0:	eb 0b                	jmp    801075dd <sys_getBlkRef+0x2f>
  return getBlkRef(n);
801075d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d5:	89 04 24             	mov    %eax,(%esp)
801075d8:	e8 2f c0 ff ff       	call   8010360c <getBlkRef>
}
801075dd:	c9                   	leave  
801075de:	c3                   	ret    
	...

801075e0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801075e0:	55                   	push   %ebp
801075e1:	89 e5                	mov    %esp,%ebp
801075e3:	83 ec 08             	sub    $0x8,%esp
801075e6:	8b 55 08             	mov    0x8(%ebp),%edx
801075e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801075ec:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801075f0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801075f3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801075f7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801075fb:	ee                   	out    %al,(%dx)
}
801075fc:	c9                   	leave  
801075fd:	c3                   	ret    

801075fe <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801075fe:	55                   	push   %ebp
801075ff:	89 e5                	mov    %esp,%ebp
80107601:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107604:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010760b:	00 
8010760c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107613:	e8 c8 ff ff ff       	call   801075e0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107618:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010761f:	00 
80107620:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107627:	e8 b4 ff ff ff       	call   801075e0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010762c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107633:	00 
80107634:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010763b:	e8 a0 ff ff ff       	call   801075e0 <outb>
  picenable(IRQ_TIMER);
80107640:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107647:	e8 d9 d6 ff ff       	call   80104d25 <picenable>
}
8010764c:	c9                   	leave  
8010764d:	c3                   	ret    
	...

80107650 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107650:	1e                   	push   %ds
  pushl %es
80107651:	06                   	push   %es
  pushl %fs
80107652:	0f a0                	push   %fs
  pushl %gs
80107654:	0f a8                	push   %gs
  pushal
80107656:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107657:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010765b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010765d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010765f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107663:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107665:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107667:	54                   	push   %esp
  call trap
80107668:	e8 de 01 00 00       	call   8010784b <trap>
  addl $4, %esp
8010766d:	83 c4 04             	add    $0x4,%esp

80107670 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107670:	61                   	popa   
  popl %gs
80107671:	0f a9                	pop    %gs
  popl %fs
80107673:	0f a1                	pop    %fs
  popl %es
80107675:	07                   	pop    %es
  popl %ds
80107676:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107677:	83 c4 08             	add    $0x8,%esp
  iret
8010767a:	cf                   	iret   
	...

8010767c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010767c:	55                   	push   %ebp
8010767d:	89 e5                	mov    %esp,%ebp
8010767f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107682:	8b 45 0c             	mov    0xc(%ebp),%eax
80107685:	83 e8 01             	sub    $0x1,%eax
80107688:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010768c:	8b 45 08             	mov    0x8(%ebp),%eax
8010768f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107693:	8b 45 08             	mov    0x8(%ebp),%eax
80107696:	c1 e8 10             	shr    $0x10,%eax
80107699:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010769d:	8d 45 fa             	lea    -0x6(%ebp),%eax
801076a0:	0f 01 18             	lidtl  (%eax)
}
801076a3:	c9                   	leave  
801076a4:	c3                   	ret    

801076a5 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801076a5:	55                   	push   %ebp
801076a6:	89 e5                	mov    %esp,%ebp
801076a8:	53                   	push   %ebx
801076a9:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801076ac:	0f 20 d3             	mov    %cr2,%ebx
801076af:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801076b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801076b5:	83 c4 10             	add    $0x10,%esp
801076b8:	5b                   	pop    %ebx
801076b9:	5d                   	pop    %ebp
801076ba:	c3                   	ret    

801076bb <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801076bb:	55                   	push   %ebp
801076bc:	89 e5                	mov    %esp,%ebp
801076be:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801076c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801076c8:	e9 c3 00 00 00       	jmp    80107790 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801076cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d0:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
801076d7:	89 c2                	mov    %eax,%edx
801076d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076dc:	66 89 14 c5 e0 2e 11 	mov    %dx,-0x7feed120(,%eax,8)
801076e3:	80 
801076e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e7:	66 c7 04 c5 e2 2e 11 	movw   $0x8,-0x7feed11e(,%eax,8)
801076ee:	80 08 00 
801076f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f4:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
801076fb:	80 
801076fc:	83 e2 e0             	and    $0xffffffe0,%edx
801076ff:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
80107706:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107709:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
80107710:	80 
80107711:	83 e2 1f             	and    $0x1f,%edx
80107714:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
8010771b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010771e:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107725:	80 
80107726:	83 e2 f0             	and    $0xfffffff0,%edx
80107729:	83 ca 0e             	or     $0xe,%edx
8010772c:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107736:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
8010773d:	80 
8010773e:	83 e2 ef             	and    $0xffffffef,%edx
80107741:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107748:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774b:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107752:	80 
80107753:	83 e2 9f             	and    $0xffffff9f,%edx
80107756:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
8010775d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107760:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107767:	80 
80107768:	83 ca 80             	or     $0xffffff80,%edx
8010776b:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
80107772:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107775:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
8010777c:	c1 e8 10             	shr    $0x10,%eax
8010777f:	89 c2                	mov    %eax,%edx
80107781:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107784:	66 89 14 c5 e6 2e 11 	mov    %dx,-0x7feed11a(,%eax,8)
8010778b:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010778c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107790:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107797:	0f 8e 30 ff ff ff    	jle    801076cd <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010779d:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
801077a2:	66 a3 e0 30 11 80    	mov    %ax,0x801130e0
801077a8:	66 c7 05 e2 30 11 80 	movw   $0x8,0x801130e2
801077af:	08 00 
801077b1:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
801077b8:	83 e0 e0             	and    $0xffffffe0,%eax
801077bb:	a2 e4 30 11 80       	mov    %al,0x801130e4
801077c0:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
801077c7:	83 e0 1f             	and    $0x1f,%eax
801077ca:	a2 e4 30 11 80       	mov    %al,0x801130e4
801077cf:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
801077d6:	83 c8 0f             	or     $0xf,%eax
801077d9:	a2 e5 30 11 80       	mov    %al,0x801130e5
801077de:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
801077e5:	83 e0 ef             	and    $0xffffffef,%eax
801077e8:	a2 e5 30 11 80       	mov    %al,0x801130e5
801077ed:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
801077f4:	83 c8 60             	or     $0x60,%eax
801077f7:	a2 e5 30 11 80       	mov    %al,0x801130e5
801077fc:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107803:	83 c8 80             	or     $0xffffff80,%eax
80107806:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010780b:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
80107810:	c1 e8 10             	shr    $0x10,%eax
80107813:	66 a3 e6 30 11 80    	mov    %ax,0x801130e6
  
  initlock(&tickslock, "time");
80107819:	c7 44 24 04 34 9b 10 	movl   $0x80109b34,0x4(%esp)
80107820:	80 
80107821:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107828:	e8 b9 e5 ff ff       	call   80105de6 <initlock>
}
8010782d:	c9                   	leave  
8010782e:	c3                   	ret    

8010782f <idtinit>:

void
idtinit(void)
{
8010782f:	55                   	push   %ebp
80107830:	89 e5                	mov    %esp,%ebp
80107832:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107835:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010783c:	00 
8010783d:	c7 04 24 e0 2e 11 80 	movl   $0x80112ee0,(%esp)
80107844:	e8 33 fe ff ff       	call   8010767c <lidt>
}
80107849:	c9                   	leave  
8010784a:	c3                   	ret    

8010784b <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010784b:	55                   	push   %ebp
8010784c:	89 e5                	mov    %esp,%ebp
8010784e:	57                   	push   %edi
8010784f:	56                   	push   %esi
80107850:	53                   	push   %ebx
80107851:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107854:	8b 45 08             	mov    0x8(%ebp),%eax
80107857:	8b 40 30             	mov    0x30(%eax),%eax
8010785a:	83 f8 40             	cmp    $0x40,%eax
8010785d:	75 3e                	jne    8010789d <trap+0x52>
    if(proc->killed)
8010785f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107865:	8b 40 24             	mov    0x24(%eax),%eax
80107868:	85 c0                	test   %eax,%eax
8010786a:	74 05                	je     80107871 <trap+0x26>
      exit();
8010786c:	e8 48 de ff ff       	call   801056b9 <exit>
    proc->tf = tf;
80107871:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107877:	8b 55 08             	mov    0x8(%ebp),%edx
8010787a:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010787d:	e8 01 ec ff ff       	call   80106483 <syscall>
    if(proc->killed)
80107882:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107888:	8b 40 24             	mov    0x24(%eax),%eax
8010788b:	85 c0                	test   %eax,%eax
8010788d:	0f 84 34 02 00 00    	je     80107ac7 <trap+0x27c>
      exit();
80107893:	e8 21 de ff ff       	call   801056b9 <exit>
    return;
80107898:	e9 2a 02 00 00       	jmp    80107ac7 <trap+0x27c>
  }

  switch(tf->trapno){
8010789d:	8b 45 08             	mov    0x8(%ebp),%eax
801078a0:	8b 40 30             	mov    0x30(%eax),%eax
801078a3:	83 e8 20             	sub    $0x20,%eax
801078a6:	83 f8 1f             	cmp    $0x1f,%eax
801078a9:	0f 87 bc 00 00 00    	ja     8010796b <trap+0x120>
801078af:	8b 04 85 dc 9b 10 80 	mov    -0x7fef6424(,%eax,4),%eax
801078b6:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801078b8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801078be:	0f b6 00             	movzbl (%eax),%eax
801078c1:	84 c0                	test   %al,%al
801078c3:	75 31                	jne    801078f6 <trap+0xab>
      acquire(&tickslock);
801078c5:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801078cc:	e8 36 e5 ff ff       	call   80105e07 <acquire>
      ticks++;
801078d1:	a1 e0 36 11 80       	mov    0x801136e0,%eax
801078d6:	83 c0 01             	add    $0x1,%eax
801078d9:	a3 e0 36 11 80       	mov    %eax,0x801136e0
      wakeup(&ticks);
801078de:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
801078e5:	e8 18 e3 ff ff       	call   80105c02 <wakeup>
      release(&tickslock);
801078ea:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801078f1:	e8 73 e5 ff ff       	call   80105e69 <release>
    }
    lapiceoi();
801078f6:	e8 52 c8 ff ff       	call   8010414d <lapiceoi>
    break;
801078fb:	e9 41 01 00 00       	jmp    80107a41 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107900:	e8 50 c0 ff ff       	call   80103955 <ideintr>
    lapiceoi();
80107905:	e8 43 c8 ff ff       	call   8010414d <lapiceoi>
    break;
8010790a:	e9 32 01 00 00       	jmp    80107a41 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010790f:	e8 17 c6 ff ff       	call   80103f2b <kbdintr>
    lapiceoi();
80107914:	e8 34 c8 ff ff       	call   8010414d <lapiceoi>
    break;
80107919:	e9 23 01 00 00       	jmp    80107a41 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010791e:	e8 a9 03 00 00       	call   80107ccc <uartintr>
    lapiceoi();
80107923:	e8 25 c8 ff ff       	call   8010414d <lapiceoi>
    break;
80107928:	e9 14 01 00 00       	jmp    80107a41 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
8010792d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107930:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107933:	8b 45 08             	mov    0x8(%ebp),%eax
80107936:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010793a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010793d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107943:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107946:	0f b6 c0             	movzbl %al,%eax
80107949:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010794d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107951:	89 44 24 04          	mov    %eax,0x4(%esp)
80107955:	c7 04 24 3c 9b 10 80 	movl   $0x80109b3c,(%esp)
8010795c:	e8 40 8a ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107961:	e8 e7 c7 ff ff       	call   8010414d <lapiceoi>
    break;
80107966:	e9 d6 00 00 00       	jmp    80107a41 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010796b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107971:	85 c0                	test   %eax,%eax
80107973:	74 11                	je     80107986 <trap+0x13b>
80107975:	8b 45 08             	mov    0x8(%ebp),%eax
80107978:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010797c:	0f b7 c0             	movzwl %ax,%eax
8010797f:	83 e0 03             	and    $0x3,%eax
80107982:	85 c0                	test   %eax,%eax
80107984:	75 46                	jne    801079cc <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107986:	e8 1a fd ff ff       	call   801076a5 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010798b:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010798e:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107991:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107998:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010799b:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010799e:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801079a1:	8b 52 30             	mov    0x30(%edx),%edx
801079a4:	89 44 24 10          	mov    %eax,0x10(%esp)
801079a8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801079ac:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801079b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801079b4:	c7 04 24 60 9b 10 80 	movl   $0x80109b60,(%esp)
801079bb:	e8 e1 89 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801079c0:	c7 04 24 92 9b 10 80 	movl   $0x80109b92,(%esp)
801079c7:	e8 71 8b ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801079cc:	e8 d4 fc ff ff       	call   801076a5 <rcr2>
801079d1:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801079d3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801079d6:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801079d9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801079df:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801079e2:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801079e5:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801079e8:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801079eb:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801079ee:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801079f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079f7:	83 c0 6c             	add    $0x6c,%eax
801079fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801079fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a03:	8b 40 10             	mov    0x10(%eax),%eax
80107a06:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107a0a:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107a0e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107a12:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107a16:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107a1a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107a1d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107a21:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a25:	c7 04 24 98 9b 10 80 	movl   $0x80109b98,(%esp)
80107a2c:	e8 70 89 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107a31:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a37:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107a3e:	eb 01                	jmp    80107a41 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107a40:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107a41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a47:	85 c0                	test   %eax,%eax
80107a49:	74 24                	je     80107a6f <trap+0x224>
80107a4b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a51:	8b 40 24             	mov    0x24(%eax),%eax
80107a54:	85 c0                	test   %eax,%eax
80107a56:	74 17                	je     80107a6f <trap+0x224>
80107a58:	8b 45 08             	mov    0x8(%ebp),%eax
80107a5b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107a5f:	0f b7 c0             	movzwl %ax,%eax
80107a62:	83 e0 03             	and    $0x3,%eax
80107a65:	83 f8 03             	cmp    $0x3,%eax
80107a68:	75 05                	jne    80107a6f <trap+0x224>
    exit();
80107a6a:	e8 4a dc ff ff       	call   801056b9 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107a6f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a75:	85 c0                	test   %eax,%eax
80107a77:	74 1e                	je     80107a97 <trap+0x24c>
80107a79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a7f:	8b 40 0c             	mov    0xc(%eax),%eax
80107a82:	83 f8 04             	cmp    $0x4,%eax
80107a85:	75 10                	jne    80107a97 <trap+0x24c>
80107a87:	8b 45 08             	mov    0x8(%ebp),%eax
80107a8a:	8b 40 30             	mov    0x30(%eax),%eax
80107a8d:	83 f8 20             	cmp    $0x20,%eax
80107a90:	75 05                	jne    80107a97 <trap+0x24c>
    yield();
80107a92:	e8 34 e0 ff ff       	call   80105acb <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107a97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a9d:	85 c0                	test   %eax,%eax
80107a9f:	74 27                	je     80107ac8 <trap+0x27d>
80107aa1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107aa7:	8b 40 24             	mov    0x24(%eax),%eax
80107aaa:	85 c0                	test   %eax,%eax
80107aac:	74 1a                	je     80107ac8 <trap+0x27d>
80107aae:	8b 45 08             	mov    0x8(%ebp),%eax
80107ab1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107ab5:	0f b7 c0             	movzwl %ax,%eax
80107ab8:	83 e0 03             	and    $0x3,%eax
80107abb:	83 f8 03             	cmp    $0x3,%eax
80107abe:	75 08                	jne    80107ac8 <trap+0x27d>
    exit();
80107ac0:	e8 f4 db ff ff       	call   801056b9 <exit>
80107ac5:	eb 01                	jmp    80107ac8 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107ac7:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107ac8:	83 c4 3c             	add    $0x3c,%esp
80107acb:	5b                   	pop    %ebx
80107acc:	5e                   	pop    %esi
80107acd:	5f                   	pop    %edi
80107ace:	5d                   	pop    %ebp
80107acf:	c3                   	ret    

80107ad0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107ad0:	55                   	push   %ebp
80107ad1:	89 e5                	mov    %esp,%ebp
80107ad3:	53                   	push   %ebx
80107ad4:	83 ec 14             	sub    $0x14,%esp
80107ad7:	8b 45 08             	mov    0x8(%ebp),%eax
80107ada:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107ade:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107ae2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107ae6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107aea:	ec                   	in     (%dx),%al
80107aeb:	89 c3                	mov    %eax,%ebx
80107aed:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107af0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107af4:	83 c4 14             	add    $0x14,%esp
80107af7:	5b                   	pop    %ebx
80107af8:	5d                   	pop    %ebp
80107af9:	c3                   	ret    

80107afa <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107afa:	55                   	push   %ebp
80107afb:	89 e5                	mov    %esp,%ebp
80107afd:	83 ec 08             	sub    $0x8,%esp
80107b00:	8b 55 08             	mov    0x8(%ebp),%edx
80107b03:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b06:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107b0a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107b0d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107b11:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107b15:	ee                   	out    %al,(%dx)
}
80107b16:	c9                   	leave  
80107b17:	c3                   	ret    

80107b18 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107b18:	55                   	push   %ebp
80107b19:	89 e5                	mov    %esp,%ebp
80107b1b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107b1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b25:	00 
80107b26:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107b2d:	e8 c8 ff ff ff       	call   80107afa <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107b32:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107b39:	00 
80107b3a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107b41:	e8 b4 ff ff ff       	call   80107afa <outb>
  outb(COM1+0, 115200/9600);
80107b46:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107b4d:	00 
80107b4e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107b55:	e8 a0 ff ff ff       	call   80107afa <outb>
  outb(COM1+1, 0);
80107b5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b61:	00 
80107b62:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107b69:	e8 8c ff ff ff       	call   80107afa <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107b6e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107b75:	00 
80107b76:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107b7d:	e8 78 ff ff ff       	call   80107afa <outb>
  outb(COM1+4, 0);
80107b82:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b89:	00 
80107b8a:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107b91:	e8 64 ff ff ff       	call   80107afa <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107b96:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107b9d:	00 
80107b9e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107ba5:	e8 50 ff ff ff       	call   80107afa <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107baa:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107bb1:	e8 1a ff ff ff       	call   80107ad0 <inb>
80107bb6:	3c ff                	cmp    $0xff,%al
80107bb8:	74 6c                	je     80107c26 <uartinit+0x10e>
    return;
  uart = 1;
80107bba:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
80107bc1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107bc4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107bcb:	e8 00 ff ff ff       	call   80107ad0 <inb>
  inb(COM1+0);
80107bd0:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107bd7:	e8 f4 fe ff ff       	call   80107ad0 <inb>
  picenable(IRQ_COM1);
80107bdc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107be3:	e8 3d d1 ff ff       	call   80104d25 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107be8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107bef:	00 
80107bf0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107bf7:	e8 de bf ff ff       	call   80103bda <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107bfc:	c7 45 f4 5c 9c 10 80 	movl   $0x80109c5c,-0xc(%ebp)
80107c03:	eb 15                	jmp    80107c1a <uartinit+0x102>
    uartputc(*p);
80107c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c08:	0f b6 00             	movzbl (%eax),%eax
80107c0b:	0f be c0             	movsbl %al,%eax
80107c0e:	89 04 24             	mov    %eax,(%esp)
80107c11:	e8 13 00 00 00       	call   80107c29 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107c16:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107c1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c1d:	0f b6 00             	movzbl (%eax),%eax
80107c20:	84 c0                	test   %al,%al
80107c22:	75 e1                	jne    80107c05 <uartinit+0xed>
80107c24:	eb 01                	jmp    80107c27 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107c26:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107c27:	c9                   	leave  
80107c28:	c3                   	ret    

80107c29 <uartputc>:

void
uartputc(int c)
{
80107c29:	55                   	push   %ebp
80107c2a:	89 e5                	mov    %esp,%ebp
80107c2c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107c2f:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107c34:	85 c0                	test   %eax,%eax
80107c36:	74 4d                	je     80107c85 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107c38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107c3f:	eb 10                	jmp    80107c51 <uartputc+0x28>
    microdelay(10);
80107c41:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107c48:	e8 25 c5 ff ff       	call   80104172 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107c4d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107c51:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107c55:	7f 16                	jg     80107c6d <uartputc+0x44>
80107c57:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107c5e:	e8 6d fe ff ff       	call   80107ad0 <inb>
80107c63:	0f b6 c0             	movzbl %al,%eax
80107c66:	83 e0 20             	and    $0x20,%eax
80107c69:	85 c0                	test   %eax,%eax
80107c6b:	74 d4                	je     80107c41 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107c6d:	8b 45 08             	mov    0x8(%ebp),%eax
80107c70:	0f b6 c0             	movzbl %al,%eax
80107c73:	89 44 24 04          	mov    %eax,0x4(%esp)
80107c77:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c7e:	e8 77 fe ff ff       	call   80107afa <outb>
80107c83:	eb 01                	jmp    80107c86 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107c85:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107c86:	c9                   	leave  
80107c87:	c3                   	ret    

80107c88 <uartgetc>:

static int
uartgetc(void)
{
80107c88:	55                   	push   %ebp
80107c89:	89 e5                	mov    %esp,%ebp
80107c8b:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107c8e:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107c93:	85 c0                	test   %eax,%eax
80107c95:	75 07                	jne    80107c9e <uartgetc+0x16>
    return -1;
80107c97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107c9c:	eb 2c                	jmp    80107cca <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107c9e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ca5:	e8 26 fe ff ff       	call   80107ad0 <inb>
80107caa:	0f b6 c0             	movzbl %al,%eax
80107cad:	83 e0 01             	and    $0x1,%eax
80107cb0:	85 c0                	test   %eax,%eax
80107cb2:	75 07                	jne    80107cbb <uartgetc+0x33>
    return -1;
80107cb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107cb9:	eb 0f                	jmp    80107cca <uartgetc+0x42>
  return inb(COM1+0);
80107cbb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107cc2:	e8 09 fe ff ff       	call   80107ad0 <inb>
80107cc7:	0f b6 c0             	movzbl %al,%eax
}
80107cca:	c9                   	leave  
80107ccb:	c3                   	ret    

80107ccc <uartintr>:

void
uartintr(void)
{
80107ccc:	55                   	push   %ebp
80107ccd:	89 e5                	mov    %esp,%ebp
80107ccf:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107cd2:	c7 04 24 88 7c 10 80 	movl   $0x80107c88,(%esp)
80107cd9:	e8 cf 8a ff ff       	call   801007ad <consoleintr>
}
80107cde:	c9                   	leave  
80107cdf:	c3                   	ret    

80107ce0 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107ce0:	6a 00                	push   $0x0
  pushl $0
80107ce2:	6a 00                	push   $0x0
  jmp alltraps
80107ce4:	e9 67 f9 ff ff       	jmp    80107650 <alltraps>

80107ce9 <vector1>:
.globl vector1
vector1:
  pushl $0
80107ce9:	6a 00                	push   $0x0
  pushl $1
80107ceb:	6a 01                	push   $0x1
  jmp alltraps
80107ced:	e9 5e f9 ff ff       	jmp    80107650 <alltraps>

80107cf2 <vector2>:
.globl vector2
vector2:
  pushl $0
80107cf2:	6a 00                	push   $0x0
  pushl $2
80107cf4:	6a 02                	push   $0x2
  jmp alltraps
80107cf6:	e9 55 f9 ff ff       	jmp    80107650 <alltraps>

80107cfb <vector3>:
.globl vector3
vector3:
  pushl $0
80107cfb:	6a 00                	push   $0x0
  pushl $3
80107cfd:	6a 03                	push   $0x3
  jmp alltraps
80107cff:	e9 4c f9 ff ff       	jmp    80107650 <alltraps>

80107d04 <vector4>:
.globl vector4
vector4:
  pushl $0
80107d04:	6a 00                	push   $0x0
  pushl $4
80107d06:	6a 04                	push   $0x4
  jmp alltraps
80107d08:	e9 43 f9 ff ff       	jmp    80107650 <alltraps>

80107d0d <vector5>:
.globl vector5
vector5:
  pushl $0
80107d0d:	6a 00                	push   $0x0
  pushl $5
80107d0f:	6a 05                	push   $0x5
  jmp alltraps
80107d11:	e9 3a f9 ff ff       	jmp    80107650 <alltraps>

80107d16 <vector6>:
.globl vector6
vector6:
  pushl $0
80107d16:	6a 00                	push   $0x0
  pushl $6
80107d18:	6a 06                	push   $0x6
  jmp alltraps
80107d1a:	e9 31 f9 ff ff       	jmp    80107650 <alltraps>

80107d1f <vector7>:
.globl vector7
vector7:
  pushl $0
80107d1f:	6a 00                	push   $0x0
  pushl $7
80107d21:	6a 07                	push   $0x7
  jmp alltraps
80107d23:	e9 28 f9 ff ff       	jmp    80107650 <alltraps>

80107d28 <vector8>:
.globl vector8
vector8:
  pushl $8
80107d28:	6a 08                	push   $0x8
  jmp alltraps
80107d2a:	e9 21 f9 ff ff       	jmp    80107650 <alltraps>

80107d2f <vector9>:
.globl vector9
vector9:
  pushl $0
80107d2f:	6a 00                	push   $0x0
  pushl $9
80107d31:	6a 09                	push   $0x9
  jmp alltraps
80107d33:	e9 18 f9 ff ff       	jmp    80107650 <alltraps>

80107d38 <vector10>:
.globl vector10
vector10:
  pushl $10
80107d38:	6a 0a                	push   $0xa
  jmp alltraps
80107d3a:	e9 11 f9 ff ff       	jmp    80107650 <alltraps>

80107d3f <vector11>:
.globl vector11
vector11:
  pushl $11
80107d3f:	6a 0b                	push   $0xb
  jmp alltraps
80107d41:	e9 0a f9 ff ff       	jmp    80107650 <alltraps>

80107d46 <vector12>:
.globl vector12
vector12:
  pushl $12
80107d46:	6a 0c                	push   $0xc
  jmp alltraps
80107d48:	e9 03 f9 ff ff       	jmp    80107650 <alltraps>

80107d4d <vector13>:
.globl vector13
vector13:
  pushl $13
80107d4d:	6a 0d                	push   $0xd
  jmp alltraps
80107d4f:	e9 fc f8 ff ff       	jmp    80107650 <alltraps>

80107d54 <vector14>:
.globl vector14
vector14:
  pushl $14
80107d54:	6a 0e                	push   $0xe
  jmp alltraps
80107d56:	e9 f5 f8 ff ff       	jmp    80107650 <alltraps>

80107d5b <vector15>:
.globl vector15
vector15:
  pushl $0
80107d5b:	6a 00                	push   $0x0
  pushl $15
80107d5d:	6a 0f                	push   $0xf
  jmp alltraps
80107d5f:	e9 ec f8 ff ff       	jmp    80107650 <alltraps>

80107d64 <vector16>:
.globl vector16
vector16:
  pushl $0
80107d64:	6a 00                	push   $0x0
  pushl $16
80107d66:	6a 10                	push   $0x10
  jmp alltraps
80107d68:	e9 e3 f8 ff ff       	jmp    80107650 <alltraps>

80107d6d <vector17>:
.globl vector17
vector17:
  pushl $17
80107d6d:	6a 11                	push   $0x11
  jmp alltraps
80107d6f:	e9 dc f8 ff ff       	jmp    80107650 <alltraps>

80107d74 <vector18>:
.globl vector18
vector18:
  pushl $0
80107d74:	6a 00                	push   $0x0
  pushl $18
80107d76:	6a 12                	push   $0x12
  jmp alltraps
80107d78:	e9 d3 f8 ff ff       	jmp    80107650 <alltraps>

80107d7d <vector19>:
.globl vector19
vector19:
  pushl $0
80107d7d:	6a 00                	push   $0x0
  pushl $19
80107d7f:	6a 13                	push   $0x13
  jmp alltraps
80107d81:	e9 ca f8 ff ff       	jmp    80107650 <alltraps>

80107d86 <vector20>:
.globl vector20
vector20:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $20
80107d88:	6a 14                	push   $0x14
  jmp alltraps
80107d8a:	e9 c1 f8 ff ff       	jmp    80107650 <alltraps>

80107d8f <vector21>:
.globl vector21
vector21:
  pushl $0
80107d8f:	6a 00                	push   $0x0
  pushl $21
80107d91:	6a 15                	push   $0x15
  jmp alltraps
80107d93:	e9 b8 f8 ff ff       	jmp    80107650 <alltraps>

80107d98 <vector22>:
.globl vector22
vector22:
  pushl $0
80107d98:	6a 00                	push   $0x0
  pushl $22
80107d9a:	6a 16                	push   $0x16
  jmp alltraps
80107d9c:	e9 af f8 ff ff       	jmp    80107650 <alltraps>

80107da1 <vector23>:
.globl vector23
vector23:
  pushl $0
80107da1:	6a 00                	push   $0x0
  pushl $23
80107da3:	6a 17                	push   $0x17
  jmp alltraps
80107da5:	e9 a6 f8 ff ff       	jmp    80107650 <alltraps>

80107daa <vector24>:
.globl vector24
vector24:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $24
80107dac:	6a 18                	push   $0x18
  jmp alltraps
80107dae:	e9 9d f8 ff ff       	jmp    80107650 <alltraps>

80107db3 <vector25>:
.globl vector25
vector25:
  pushl $0
80107db3:	6a 00                	push   $0x0
  pushl $25
80107db5:	6a 19                	push   $0x19
  jmp alltraps
80107db7:	e9 94 f8 ff ff       	jmp    80107650 <alltraps>

80107dbc <vector26>:
.globl vector26
vector26:
  pushl $0
80107dbc:	6a 00                	push   $0x0
  pushl $26
80107dbe:	6a 1a                	push   $0x1a
  jmp alltraps
80107dc0:	e9 8b f8 ff ff       	jmp    80107650 <alltraps>

80107dc5 <vector27>:
.globl vector27
vector27:
  pushl $0
80107dc5:	6a 00                	push   $0x0
  pushl $27
80107dc7:	6a 1b                	push   $0x1b
  jmp alltraps
80107dc9:	e9 82 f8 ff ff       	jmp    80107650 <alltraps>

80107dce <vector28>:
.globl vector28
vector28:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $28
80107dd0:	6a 1c                	push   $0x1c
  jmp alltraps
80107dd2:	e9 79 f8 ff ff       	jmp    80107650 <alltraps>

80107dd7 <vector29>:
.globl vector29
vector29:
  pushl $0
80107dd7:	6a 00                	push   $0x0
  pushl $29
80107dd9:	6a 1d                	push   $0x1d
  jmp alltraps
80107ddb:	e9 70 f8 ff ff       	jmp    80107650 <alltraps>

80107de0 <vector30>:
.globl vector30
vector30:
  pushl $0
80107de0:	6a 00                	push   $0x0
  pushl $30
80107de2:	6a 1e                	push   $0x1e
  jmp alltraps
80107de4:	e9 67 f8 ff ff       	jmp    80107650 <alltraps>

80107de9 <vector31>:
.globl vector31
vector31:
  pushl $0
80107de9:	6a 00                	push   $0x0
  pushl $31
80107deb:	6a 1f                	push   $0x1f
  jmp alltraps
80107ded:	e9 5e f8 ff ff       	jmp    80107650 <alltraps>

80107df2 <vector32>:
.globl vector32
vector32:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $32
80107df4:	6a 20                	push   $0x20
  jmp alltraps
80107df6:	e9 55 f8 ff ff       	jmp    80107650 <alltraps>

80107dfb <vector33>:
.globl vector33
vector33:
  pushl $0
80107dfb:	6a 00                	push   $0x0
  pushl $33
80107dfd:	6a 21                	push   $0x21
  jmp alltraps
80107dff:	e9 4c f8 ff ff       	jmp    80107650 <alltraps>

80107e04 <vector34>:
.globl vector34
vector34:
  pushl $0
80107e04:	6a 00                	push   $0x0
  pushl $34
80107e06:	6a 22                	push   $0x22
  jmp alltraps
80107e08:	e9 43 f8 ff ff       	jmp    80107650 <alltraps>

80107e0d <vector35>:
.globl vector35
vector35:
  pushl $0
80107e0d:	6a 00                	push   $0x0
  pushl $35
80107e0f:	6a 23                	push   $0x23
  jmp alltraps
80107e11:	e9 3a f8 ff ff       	jmp    80107650 <alltraps>

80107e16 <vector36>:
.globl vector36
vector36:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $36
80107e18:	6a 24                	push   $0x24
  jmp alltraps
80107e1a:	e9 31 f8 ff ff       	jmp    80107650 <alltraps>

80107e1f <vector37>:
.globl vector37
vector37:
  pushl $0
80107e1f:	6a 00                	push   $0x0
  pushl $37
80107e21:	6a 25                	push   $0x25
  jmp alltraps
80107e23:	e9 28 f8 ff ff       	jmp    80107650 <alltraps>

80107e28 <vector38>:
.globl vector38
vector38:
  pushl $0
80107e28:	6a 00                	push   $0x0
  pushl $38
80107e2a:	6a 26                	push   $0x26
  jmp alltraps
80107e2c:	e9 1f f8 ff ff       	jmp    80107650 <alltraps>

80107e31 <vector39>:
.globl vector39
vector39:
  pushl $0
80107e31:	6a 00                	push   $0x0
  pushl $39
80107e33:	6a 27                	push   $0x27
  jmp alltraps
80107e35:	e9 16 f8 ff ff       	jmp    80107650 <alltraps>

80107e3a <vector40>:
.globl vector40
vector40:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $40
80107e3c:	6a 28                	push   $0x28
  jmp alltraps
80107e3e:	e9 0d f8 ff ff       	jmp    80107650 <alltraps>

80107e43 <vector41>:
.globl vector41
vector41:
  pushl $0
80107e43:	6a 00                	push   $0x0
  pushl $41
80107e45:	6a 29                	push   $0x29
  jmp alltraps
80107e47:	e9 04 f8 ff ff       	jmp    80107650 <alltraps>

80107e4c <vector42>:
.globl vector42
vector42:
  pushl $0
80107e4c:	6a 00                	push   $0x0
  pushl $42
80107e4e:	6a 2a                	push   $0x2a
  jmp alltraps
80107e50:	e9 fb f7 ff ff       	jmp    80107650 <alltraps>

80107e55 <vector43>:
.globl vector43
vector43:
  pushl $0
80107e55:	6a 00                	push   $0x0
  pushl $43
80107e57:	6a 2b                	push   $0x2b
  jmp alltraps
80107e59:	e9 f2 f7 ff ff       	jmp    80107650 <alltraps>

80107e5e <vector44>:
.globl vector44
vector44:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $44
80107e60:	6a 2c                	push   $0x2c
  jmp alltraps
80107e62:	e9 e9 f7 ff ff       	jmp    80107650 <alltraps>

80107e67 <vector45>:
.globl vector45
vector45:
  pushl $0
80107e67:	6a 00                	push   $0x0
  pushl $45
80107e69:	6a 2d                	push   $0x2d
  jmp alltraps
80107e6b:	e9 e0 f7 ff ff       	jmp    80107650 <alltraps>

80107e70 <vector46>:
.globl vector46
vector46:
  pushl $0
80107e70:	6a 00                	push   $0x0
  pushl $46
80107e72:	6a 2e                	push   $0x2e
  jmp alltraps
80107e74:	e9 d7 f7 ff ff       	jmp    80107650 <alltraps>

80107e79 <vector47>:
.globl vector47
vector47:
  pushl $0
80107e79:	6a 00                	push   $0x0
  pushl $47
80107e7b:	6a 2f                	push   $0x2f
  jmp alltraps
80107e7d:	e9 ce f7 ff ff       	jmp    80107650 <alltraps>

80107e82 <vector48>:
.globl vector48
vector48:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $48
80107e84:	6a 30                	push   $0x30
  jmp alltraps
80107e86:	e9 c5 f7 ff ff       	jmp    80107650 <alltraps>

80107e8b <vector49>:
.globl vector49
vector49:
  pushl $0
80107e8b:	6a 00                	push   $0x0
  pushl $49
80107e8d:	6a 31                	push   $0x31
  jmp alltraps
80107e8f:	e9 bc f7 ff ff       	jmp    80107650 <alltraps>

80107e94 <vector50>:
.globl vector50
vector50:
  pushl $0
80107e94:	6a 00                	push   $0x0
  pushl $50
80107e96:	6a 32                	push   $0x32
  jmp alltraps
80107e98:	e9 b3 f7 ff ff       	jmp    80107650 <alltraps>

80107e9d <vector51>:
.globl vector51
vector51:
  pushl $0
80107e9d:	6a 00                	push   $0x0
  pushl $51
80107e9f:	6a 33                	push   $0x33
  jmp alltraps
80107ea1:	e9 aa f7 ff ff       	jmp    80107650 <alltraps>

80107ea6 <vector52>:
.globl vector52
vector52:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $52
80107ea8:	6a 34                	push   $0x34
  jmp alltraps
80107eaa:	e9 a1 f7 ff ff       	jmp    80107650 <alltraps>

80107eaf <vector53>:
.globl vector53
vector53:
  pushl $0
80107eaf:	6a 00                	push   $0x0
  pushl $53
80107eb1:	6a 35                	push   $0x35
  jmp alltraps
80107eb3:	e9 98 f7 ff ff       	jmp    80107650 <alltraps>

80107eb8 <vector54>:
.globl vector54
vector54:
  pushl $0
80107eb8:	6a 00                	push   $0x0
  pushl $54
80107eba:	6a 36                	push   $0x36
  jmp alltraps
80107ebc:	e9 8f f7 ff ff       	jmp    80107650 <alltraps>

80107ec1 <vector55>:
.globl vector55
vector55:
  pushl $0
80107ec1:	6a 00                	push   $0x0
  pushl $55
80107ec3:	6a 37                	push   $0x37
  jmp alltraps
80107ec5:	e9 86 f7 ff ff       	jmp    80107650 <alltraps>

80107eca <vector56>:
.globl vector56
vector56:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $56
80107ecc:	6a 38                	push   $0x38
  jmp alltraps
80107ece:	e9 7d f7 ff ff       	jmp    80107650 <alltraps>

80107ed3 <vector57>:
.globl vector57
vector57:
  pushl $0
80107ed3:	6a 00                	push   $0x0
  pushl $57
80107ed5:	6a 39                	push   $0x39
  jmp alltraps
80107ed7:	e9 74 f7 ff ff       	jmp    80107650 <alltraps>

80107edc <vector58>:
.globl vector58
vector58:
  pushl $0
80107edc:	6a 00                	push   $0x0
  pushl $58
80107ede:	6a 3a                	push   $0x3a
  jmp alltraps
80107ee0:	e9 6b f7 ff ff       	jmp    80107650 <alltraps>

80107ee5 <vector59>:
.globl vector59
vector59:
  pushl $0
80107ee5:	6a 00                	push   $0x0
  pushl $59
80107ee7:	6a 3b                	push   $0x3b
  jmp alltraps
80107ee9:	e9 62 f7 ff ff       	jmp    80107650 <alltraps>

80107eee <vector60>:
.globl vector60
vector60:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $60
80107ef0:	6a 3c                	push   $0x3c
  jmp alltraps
80107ef2:	e9 59 f7 ff ff       	jmp    80107650 <alltraps>

80107ef7 <vector61>:
.globl vector61
vector61:
  pushl $0
80107ef7:	6a 00                	push   $0x0
  pushl $61
80107ef9:	6a 3d                	push   $0x3d
  jmp alltraps
80107efb:	e9 50 f7 ff ff       	jmp    80107650 <alltraps>

80107f00 <vector62>:
.globl vector62
vector62:
  pushl $0
80107f00:	6a 00                	push   $0x0
  pushl $62
80107f02:	6a 3e                	push   $0x3e
  jmp alltraps
80107f04:	e9 47 f7 ff ff       	jmp    80107650 <alltraps>

80107f09 <vector63>:
.globl vector63
vector63:
  pushl $0
80107f09:	6a 00                	push   $0x0
  pushl $63
80107f0b:	6a 3f                	push   $0x3f
  jmp alltraps
80107f0d:	e9 3e f7 ff ff       	jmp    80107650 <alltraps>

80107f12 <vector64>:
.globl vector64
vector64:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $64
80107f14:	6a 40                	push   $0x40
  jmp alltraps
80107f16:	e9 35 f7 ff ff       	jmp    80107650 <alltraps>

80107f1b <vector65>:
.globl vector65
vector65:
  pushl $0
80107f1b:	6a 00                	push   $0x0
  pushl $65
80107f1d:	6a 41                	push   $0x41
  jmp alltraps
80107f1f:	e9 2c f7 ff ff       	jmp    80107650 <alltraps>

80107f24 <vector66>:
.globl vector66
vector66:
  pushl $0
80107f24:	6a 00                	push   $0x0
  pushl $66
80107f26:	6a 42                	push   $0x42
  jmp alltraps
80107f28:	e9 23 f7 ff ff       	jmp    80107650 <alltraps>

80107f2d <vector67>:
.globl vector67
vector67:
  pushl $0
80107f2d:	6a 00                	push   $0x0
  pushl $67
80107f2f:	6a 43                	push   $0x43
  jmp alltraps
80107f31:	e9 1a f7 ff ff       	jmp    80107650 <alltraps>

80107f36 <vector68>:
.globl vector68
vector68:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $68
80107f38:	6a 44                	push   $0x44
  jmp alltraps
80107f3a:	e9 11 f7 ff ff       	jmp    80107650 <alltraps>

80107f3f <vector69>:
.globl vector69
vector69:
  pushl $0
80107f3f:	6a 00                	push   $0x0
  pushl $69
80107f41:	6a 45                	push   $0x45
  jmp alltraps
80107f43:	e9 08 f7 ff ff       	jmp    80107650 <alltraps>

80107f48 <vector70>:
.globl vector70
vector70:
  pushl $0
80107f48:	6a 00                	push   $0x0
  pushl $70
80107f4a:	6a 46                	push   $0x46
  jmp alltraps
80107f4c:	e9 ff f6 ff ff       	jmp    80107650 <alltraps>

80107f51 <vector71>:
.globl vector71
vector71:
  pushl $0
80107f51:	6a 00                	push   $0x0
  pushl $71
80107f53:	6a 47                	push   $0x47
  jmp alltraps
80107f55:	e9 f6 f6 ff ff       	jmp    80107650 <alltraps>

80107f5a <vector72>:
.globl vector72
vector72:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $72
80107f5c:	6a 48                	push   $0x48
  jmp alltraps
80107f5e:	e9 ed f6 ff ff       	jmp    80107650 <alltraps>

80107f63 <vector73>:
.globl vector73
vector73:
  pushl $0
80107f63:	6a 00                	push   $0x0
  pushl $73
80107f65:	6a 49                	push   $0x49
  jmp alltraps
80107f67:	e9 e4 f6 ff ff       	jmp    80107650 <alltraps>

80107f6c <vector74>:
.globl vector74
vector74:
  pushl $0
80107f6c:	6a 00                	push   $0x0
  pushl $74
80107f6e:	6a 4a                	push   $0x4a
  jmp alltraps
80107f70:	e9 db f6 ff ff       	jmp    80107650 <alltraps>

80107f75 <vector75>:
.globl vector75
vector75:
  pushl $0
80107f75:	6a 00                	push   $0x0
  pushl $75
80107f77:	6a 4b                	push   $0x4b
  jmp alltraps
80107f79:	e9 d2 f6 ff ff       	jmp    80107650 <alltraps>

80107f7e <vector76>:
.globl vector76
vector76:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $76
80107f80:	6a 4c                	push   $0x4c
  jmp alltraps
80107f82:	e9 c9 f6 ff ff       	jmp    80107650 <alltraps>

80107f87 <vector77>:
.globl vector77
vector77:
  pushl $0
80107f87:	6a 00                	push   $0x0
  pushl $77
80107f89:	6a 4d                	push   $0x4d
  jmp alltraps
80107f8b:	e9 c0 f6 ff ff       	jmp    80107650 <alltraps>

80107f90 <vector78>:
.globl vector78
vector78:
  pushl $0
80107f90:	6a 00                	push   $0x0
  pushl $78
80107f92:	6a 4e                	push   $0x4e
  jmp alltraps
80107f94:	e9 b7 f6 ff ff       	jmp    80107650 <alltraps>

80107f99 <vector79>:
.globl vector79
vector79:
  pushl $0
80107f99:	6a 00                	push   $0x0
  pushl $79
80107f9b:	6a 4f                	push   $0x4f
  jmp alltraps
80107f9d:	e9 ae f6 ff ff       	jmp    80107650 <alltraps>

80107fa2 <vector80>:
.globl vector80
vector80:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $80
80107fa4:	6a 50                	push   $0x50
  jmp alltraps
80107fa6:	e9 a5 f6 ff ff       	jmp    80107650 <alltraps>

80107fab <vector81>:
.globl vector81
vector81:
  pushl $0
80107fab:	6a 00                	push   $0x0
  pushl $81
80107fad:	6a 51                	push   $0x51
  jmp alltraps
80107faf:	e9 9c f6 ff ff       	jmp    80107650 <alltraps>

80107fb4 <vector82>:
.globl vector82
vector82:
  pushl $0
80107fb4:	6a 00                	push   $0x0
  pushl $82
80107fb6:	6a 52                	push   $0x52
  jmp alltraps
80107fb8:	e9 93 f6 ff ff       	jmp    80107650 <alltraps>

80107fbd <vector83>:
.globl vector83
vector83:
  pushl $0
80107fbd:	6a 00                	push   $0x0
  pushl $83
80107fbf:	6a 53                	push   $0x53
  jmp alltraps
80107fc1:	e9 8a f6 ff ff       	jmp    80107650 <alltraps>

80107fc6 <vector84>:
.globl vector84
vector84:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $84
80107fc8:	6a 54                	push   $0x54
  jmp alltraps
80107fca:	e9 81 f6 ff ff       	jmp    80107650 <alltraps>

80107fcf <vector85>:
.globl vector85
vector85:
  pushl $0
80107fcf:	6a 00                	push   $0x0
  pushl $85
80107fd1:	6a 55                	push   $0x55
  jmp alltraps
80107fd3:	e9 78 f6 ff ff       	jmp    80107650 <alltraps>

80107fd8 <vector86>:
.globl vector86
vector86:
  pushl $0
80107fd8:	6a 00                	push   $0x0
  pushl $86
80107fda:	6a 56                	push   $0x56
  jmp alltraps
80107fdc:	e9 6f f6 ff ff       	jmp    80107650 <alltraps>

80107fe1 <vector87>:
.globl vector87
vector87:
  pushl $0
80107fe1:	6a 00                	push   $0x0
  pushl $87
80107fe3:	6a 57                	push   $0x57
  jmp alltraps
80107fe5:	e9 66 f6 ff ff       	jmp    80107650 <alltraps>

80107fea <vector88>:
.globl vector88
vector88:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $88
80107fec:	6a 58                	push   $0x58
  jmp alltraps
80107fee:	e9 5d f6 ff ff       	jmp    80107650 <alltraps>

80107ff3 <vector89>:
.globl vector89
vector89:
  pushl $0
80107ff3:	6a 00                	push   $0x0
  pushl $89
80107ff5:	6a 59                	push   $0x59
  jmp alltraps
80107ff7:	e9 54 f6 ff ff       	jmp    80107650 <alltraps>

80107ffc <vector90>:
.globl vector90
vector90:
  pushl $0
80107ffc:	6a 00                	push   $0x0
  pushl $90
80107ffe:	6a 5a                	push   $0x5a
  jmp alltraps
80108000:	e9 4b f6 ff ff       	jmp    80107650 <alltraps>

80108005 <vector91>:
.globl vector91
vector91:
  pushl $0
80108005:	6a 00                	push   $0x0
  pushl $91
80108007:	6a 5b                	push   $0x5b
  jmp alltraps
80108009:	e9 42 f6 ff ff       	jmp    80107650 <alltraps>

8010800e <vector92>:
.globl vector92
vector92:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $92
80108010:	6a 5c                	push   $0x5c
  jmp alltraps
80108012:	e9 39 f6 ff ff       	jmp    80107650 <alltraps>

80108017 <vector93>:
.globl vector93
vector93:
  pushl $0
80108017:	6a 00                	push   $0x0
  pushl $93
80108019:	6a 5d                	push   $0x5d
  jmp alltraps
8010801b:	e9 30 f6 ff ff       	jmp    80107650 <alltraps>

80108020 <vector94>:
.globl vector94
vector94:
  pushl $0
80108020:	6a 00                	push   $0x0
  pushl $94
80108022:	6a 5e                	push   $0x5e
  jmp alltraps
80108024:	e9 27 f6 ff ff       	jmp    80107650 <alltraps>

80108029 <vector95>:
.globl vector95
vector95:
  pushl $0
80108029:	6a 00                	push   $0x0
  pushl $95
8010802b:	6a 5f                	push   $0x5f
  jmp alltraps
8010802d:	e9 1e f6 ff ff       	jmp    80107650 <alltraps>

80108032 <vector96>:
.globl vector96
vector96:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $96
80108034:	6a 60                	push   $0x60
  jmp alltraps
80108036:	e9 15 f6 ff ff       	jmp    80107650 <alltraps>

8010803b <vector97>:
.globl vector97
vector97:
  pushl $0
8010803b:	6a 00                	push   $0x0
  pushl $97
8010803d:	6a 61                	push   $0x61
  jmp alltraps
8010803f:	e9 0c f6 ff ff       	jmp    80107650 <alltraps>

80108044 <vector98>:
.globl vector98
vector98:
  pushl $0
80108044:	6a 00                	push   $0x0
  pushl $98
80108046:	6a 62                	push   $0x62
  jmp alltraps
80108048:	e9 03 f6 ff ff       	jmp    80107650 <alltraps>

8010804d <vector99>:
.globl vector99
vector99:
  pushl $0
8010804d:	6a 00                	push   $0x0
  pushl $99
8010804f:	6a 63                	push   $0x63
  jmp alltraps
80108051:	e9 fa f5 ff ff       	jmp    80107650 <alltraps>

80108056 <vector100>:
.globl vector100
vector100:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $100
80108058:	6a 64                	push   $0x64
  jmp alltraps
8010805a:	e9 f1 f5 ff ff       	jmp    80107650 <alltraps>

8010805f <vector101>:
.globl vector101
vector101:
  pushl $0
8010805f:	6a 00                	push   $0x0
  pushl $101
80108061:	6a 65                	push   $0x65
  jmp alltraps
80108063:	e9 e8 f5 ff ff       	jmp    80107650 <alltraps>

80108068 <vector102>:
.globl vector102
vector102:
  pushl $0
80108068:	6a 00                	push   $0x0
  pushl $102
8010806a:	6a 66                	push   $0x66
  jmp alltraps
8010806c:	e9 df f5 ff ff       	jmp    80107650 <alltraps>

80108071 <vector103>:
.globl vector103
vector103:
  pushl $0
80108071:	6a 00                	push   $0x0
  pushl $103
80108073:	6a 67                	push   $0x67
  jmp alltraps
80108075:	e9 d6 f5 ff ff       	jmp    80107650 <alltraps>

8010807a <vector104>:
.globl vector104
vector104:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $104
8010807c:	6a 68                	push   $0x68
  jmp alltraps
8010807e:	e9 cd f5 ff ff       	jmp    80107650 <alltraps>

80108083 <vector105>:
.globl vector105
vector105:
  pushl $0
80108083:	6a 00                	push   $0x0
  pushl $105
80108085:	6a 69                	push   $0x69
  jmp alltraps
80108087:	e9 c4 f5 ff ff       	jmp    80107650 <alltraps>

8010808c <vector106>:
.globl vector106
vector106:
  pushl $0
8010808c:	6a 00                	push   $0x0
  pushl $106
8010808e:	6a 6a                	push   $0x6a
  jmp alltraps
80108090:	e9 bb f5 ff ff       	jmp    80107650 <alltraps>

80108095 <vector107>:
.globl vector107
vector107:
  pushl $0
80108095:	6a 00                	push   $0x0
  pushl $107
80108097:	6a 6b                	push   $0x6b
  jmp alltraps
80108099:	e9 b2 f5 ff ff       	jmp    80107650 <alltraps>

8010809e <vector108>:
.globl vector108
vector108:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $108
801080a0:	6a 6c                	push   $0x6c
  jmp alltraps
801080a2:	e9 a9 f5 ff ff       	jmp    80107650 <alltraps>

801080a7 <vector109>:
.globl vector109
vector109:
  pushl $0
801080a7:	6a 00                	push   $0x0
  pushl $109
801080a9:	6a 6d                	push   $0x6d
  jmp alltraps
801080ab:	e9 a0 f5 ff ff       	jmp    80107650 <alltraps>

801080b0 <vector110>:
.globl vector110
vector110:
  pushl $0
801080b0:	6a 00                	push   $0x0
  pushl $110
801080b2:	6a 6e                	push   $0x6e
  jmp alltraps
801080b4:	e9 97 f5 ff ff       	jmp    80107650 <alltraps>

801080b9 <vector111>:
.globl vector111
vector111:
  pushl $0
801080b9:	6a 00                	push   $0x0
  pushl $111
801080bb:	6a 6f                	push   $0x6f
  jmp alltraps
801080bd:	e9 8e f5 ff ff       	jmp    80107650 <alltraps>

801080c2 <vector112>:
.globl vector112
vector112:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $112
801080c4:	6a 70                	push   $0x70
  jmp alltraps
801080c6:	e9 85 f5 ff ff       	jmp    80107650 <alltraps>

801080cb <vector113>:
.globl vector113
vector113:
  pushl $0
801080cb:	6a 00                	push   $0x0
  pushl $113
801080cd:	6a 71                	push   $0x71
  jmp alltraps
801080cf:	e9 7c f5 ff ff       	jmp    80107650 <alltraps>

801080d4 <vector114>:
.globl vector114
vector114:
  pushl $0
801080d4:	6a 00                	push   $0x0
  pushl $114
801080d6:	6a 72                	push   $0x72
  jmp alltraps
801080d8:	e9 73 f5 ff ff       	jmp    80107650 <alltraps>

801080dd <vector115>:
.globl vector115
vector115:
  pushl $0
801080dd:	6a 00                	push   $0x0
  pushl $115
801080df:	6a 73                	push   $0x73
  jmp alltraps
801080e1:	e9 6a f5 ff ff       	jmp    80107650 <alltraps>

801080e6 <vector116>:
.globl vector116
vector116:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $116
801080e8:	6a 74                	push   $0x74
  jmp alltraps
801080ea:	e9 61 f5 ff ff       	jmp    80107650 <alltraps>

801080ef <vector117>:
.globl vector117
vector117:
  pushl $0
801080ef:	6a 00                	push   $0x0
  pushl $117
801080f1:	6a 75                	push   $0x75
  jmp alltraps
801080f3:	e9 58 f5 ff ff       	jmp    80107650 <alltraps>

801080f8 <vector118>:
.globl vector118
vector118:
  pushl $0
801080f8:	6a 00                	push   $0x0
  pushl $118
801080fa:	6a 76                	push   $0x76
  jmp alltraps
801080fc:	e9 4f f5 ff ff       	jmp    80107650 <alltraps>

80108101 <vector119>:
.globl vector119
vector119:
  pushl $0
80108101:	6a 00                	push   $0x0
  pushl $119
80108103:	6a 77                	push   $0x77
  jmp alltraps
80108105:	e9 46 f5 ff ff       	jmp    80107650 <alltraps>

8010810a <vector120>:
.globl vector120
vector120:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $120
8010810c:	6a 78                	push   $0x78
  jmp alltraps
8010810e:	e9 3d f5 ff ff       	jmp    80107650 <alltraps>

80108113 <vector121>:
.globl vector121
vector121:
  pushl $0
80108113:	6a 00                	push   $0x0
  pushl $121
80108115:	6a 79                	push   $0x79
  jmp alltraps
80108117:	e9 34 f5 ff ff       	jmp    80107650 <alltraps>

8010811c <vector122>:
.globl vector122
vector122:
  pushl $0
8010811c:	6a 00                	push   $0x0
  pushl $122
8010811e:	6a 7a                	push   $0x7a
  jmp alltraps
80108120:	e9 2b f5 ff ff       	jmp    80107650 <alltraps>

80108125 <vector123>:
.globl vector123
vector123:
  pushl $0
80108125:	6a 00                	push   $0x0
  pushl $123
80108127:	6a 7b                	push   $0x7b
  jmp alltraps
80108129:	e9 22 f5 ff ff       	jmp    80107650 <alltraps>

8010812e <vector124>:
.globl vector124
vector124:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $124
80108130:	6a 7c                	push   $0x7c
  jmp alltraps
80108132:	e9 19 f5 ff ff       	jmp    80107650 <alltraps>

80108137 <vector125>:
.globl vector125
vector125:
  pushl $0
80108137:	6a 00                	push   $0x0
  pushl $125
80108139:	6a 7d                	push   $0x7d
  jmp alltraps
8010813b:	e9 10 f5 ff ff       	jmp    80107650 <alltraps>

80108140 <vector126>:
.globl vector126
vector126:
  pushl $0
80108140:	6a 00                	push   $0x0
  pushl $126
80108142:	6a 7e                	push   $0x7e
  jmp alltraps
80108144:	e9 07 f5 ff ff       	jmp    80107650 <alltraps>

80108149 <vector127>:
.globl vector127
vector127:
  pushl $0
80108149:	6a 00                	push   $0x0
  pushl $127
8010814b:	6a 7f                	push   $0x7f
  jmp alltraps
8010814d:	e9 fe f4 ff ff       	jmp    80107650 <alltraps>

80108152 <vector128>:
.globl vector128
vector128:
  pushl $0
80108152:	6a 00                	push   $0x0
  pushl $128
80108154:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80108159:	e9 f2 f4 ff ff       	jmp    80107650 <alltraps>

8010815e <vector129>:
.globl vector129
vector129:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $129
80108160:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80108165:	e9 e6 f4 ff ff       	jmp    80107650 <alltraps>

8010816a <vector130>:
.globl vector130
vector130:
  pushl $0
8010816a:	6a 00                	push   $0x0
  pushl $130
8010816c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80108171:	e9 da f4 ff ff       	jmp    80107650 <alltraps>

80108176 <vector131>:
.globl vector131
vector131:
  pushl $0
80108176:	6a 00                	push   $0x0
  pushl $131
80108178:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010817d:	e9 ce f4 ff ff       	jmp    80107650 <alltraps>

80108182 <vector132>:
.globl vector132
vector132:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $132
80108184:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80108189:	e9 c2 f4 ff ff       	jmp    80107650 <alltraps>

8010818e <vector133>:
.globl vector133
vector133:
  pushl $0
8010818e:	6a 00                	push   $0x0
  pushl $133
80108190:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80108195:	e9 b6 f4 ff ff       	jmp    80107650 <alltraps>

8010819a <vector134>:
.globl vector134
vector134:
  pushl $0
8010819a:	6a 00                	push   $0x0
  pushl $134
8010819c:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801081a1:	e9 aa f4 ff ff       	jmp    80107650 <alltraps>

801081a6 <vector135>:
.globl vector135
vector135:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $135
801081a8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801081ad:	e9 9e f4 ff ff       	jmp    80107650 <alltraps>

801081b2 <vector136>:
.globl vector136
vector136:
  pushl $0
801081b2:	6a 00                	push   $0x0
  pushl $136
801081b4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801081b9:	e9 92 f4 ff ff       	jmp    80107650 <alltraps>

801081be <vector137>:
.globl vector137
vector137:
  pushl $0
801081be:	6a 00                	push   $0x0
  pushl $137
801081c0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801081c5:	e9 86 f4 ff ff       	jmp    80107650 <alltraps>

801081ca <vector138>:
.globl vector138
vector138:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $138
801081cc:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801081d1:	e9 7a f4 ff ff       	jmp    80107650 <alltraps>

801081d6 <vector139>:
.globl vector139
vector139:
  pushl $0
801081d6:	6a 00                	push   $0x0
  pushl $139
801081d8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801081dd:	e9 6e f4 ff ff       	jmp    80107650 <alltraps>

801081e2 <vector140>:
.globl vector140
vector140:
  pushl $0
801081e2:	6a 00                	push   $0x0
  pushl $140
801081e4:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801081e9:	e9 62 f4 ff ff       	jmp    80107650 <alltraps>

801081ee <vector141>:
.globl vector141
vector141:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $141
801081f0:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801081f5:	e9 56 f4 ff ff       	jmp    80107650 <alltraps>

801081fa <vector142>:
.globl vector142
vector142:
  pushl $0
801081fa:	6a 00                	push   $0x0
  pushl $142
801081fc:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108201:	e9 4a f4 ff ff       	jmp    80107650 <alltraps>

80108206 <vector143>:
.globl vector143
vector143:
  pushl $0
80108206:	6a 00                	push   $0x0
  pushl $143
80108208:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010820d:	e9 3e f4 ff ff       	jmp    80107650 <alltraps>

80108212 <vector144>:
.globl vector144
vector144:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $144
80108214:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108219:	e9 32 f4 ff ff       	jmp    80107650 <alltraps>

8010821e <vector145>:
.globl vector145
vector145:
  pushl $0
8010821e:	6a 00                	push   $0x0
  pushl $145
80108220:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108225:	e9 26 f4 ff ff       	jmp    80107650 <alltraps>

8010822a <vector146>:
.globl vector146
vector146:
  pushl $0
8010822a:	6a 00                	push   $0x0
  pushl $146
8010822c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108231:	e9 1a f4 ff ff       	jmp    80107650 <alltraps>

80108236 <vector147>:
.globl vector147
vector147:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $147
80108238:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010823d:	e9 0e f4 ff ff       	jmp    80107650 <alltraps>

80108242 <vector148>:
.globl vector148
vector148:
  pushl $0
80108242:	6a 00                	push   $0x0
  pushl $148
80108244:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80108249:	e9 02 f4 ff ff       	jmp    80107650 <alltraps>

8010824e <vector149>:
.globl vector149
vector149:
  pushl $0
8010824e:	6a 00                	push   $0x0
  pushl $149
80108250:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108255:	e9 f6 f3 ff ff       	jmp    80107650 <alltraps>

8010825a <vector150>:
.globl vector150
vector150:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $150
8010825c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80108261:	e9 ea f3 ff ff       	jmp    80107650 <alltraps>

80108266 <vector151>:
.globl vector151
vector151:
  pushl $0
80108266:	6a 00                	push   $0x0
  pushl $151
80108268:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010826d:	e9 de f3 ff ff       	jmp    80107650 <alltraps>

80108272 <vector152>:
.globl vector152
vector152:
  pushl $0
80108272:	6a 00                	push   $0x0
  pushl $152
80108274:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80108279:	e9 d2 f3 ff ff       	jmp    80107650 <alltraps>

8010827e <vector153>:
.globl vector153
vector153:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $153
80108280:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80108285:	e9 c6 f3 ff ff       	jmp    80107650 <alltraps>

8010828a <vector154>:
.globl vector154
vector154:
  pushl $0
8010828a:	6a 00                	push   $0x0
  pushl $154
8010828c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80108291:	e9 ba f3 ff ff       	jmp    80107650 <alltraps>

80108296 <vector155>:
.globl vector155
vector155:
  pushl $0
80108296:	6a 00                	push   $0x0
  pushl $155
80108298:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010829d:	e9 ae f3 ff ff       	jmp    80107650 <alltraps>

801082a2 <vector156>:
.globl vector156
vector156:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $156
801082a4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801082a9:	e9 a2 f3 ff ff       	jmp    80107650 <alltraps>

801082ae <vector157>:
.globl vector157
vector157:
  pushl $0
801082ae:	6a 00                	push   $0x0
  pushl $157
801082b0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801082b5:	e9 96 f3 ff ff       	jmp    80107650 <alltraps>

801082ba <vector158>:
.globl vector158
vector158:
  pushl $0
801082ba:	6a 00                	push   $0x0
  pushl $158
801082bc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801082c1:	e9 8a f3 ff ff       	jmp    80107650 <alltraps>

801082c6 <vector159>:
.globl vector159
vector159:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $159
801082c8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801082cd:	e9 7e f3 ff ff       	jmp    80107650 <alltraps>

801082d2 <vector160>:
.globl vector160
vector160:
  pushl $0
801082d2:	6a 00                	push   $0x0
  pushl $160
801082d4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801082d9:	e9 72 f3 ff ff       	jmp    80107650 <alltraps>

801082de <vector161>:
.globl vector161
vector161:
  pushl $0
801082de:	6a 00                	push   $0x0
  pushl $161
801082e0:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801082e5:	e9 66 f3 ff ff       	jmp    80107650 <alltraps>

801082ea <vector162>:
.globl vector162
vector162:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $162
801082ec:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801082f1:	e9 5a f3 ff ff       	jmp    80107650 <alltraps>

801082f6 <vector163>:
.globl vector163
vector163:
  pushl $0
801082f6:	6a 00                	push   $0x0
  pushl $163
801082f8:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801082fd:	e9 4e f3 ff ff       	jmp    80107650 <alltraps>

80108302 <vector164>:
.globl vector164
vector164:
  pushl $0
80108302:	6a 00                	push   $0x0
  pushl $164
80108304:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108309:	e9 42 f3 ff ff       	jmp    80107650 <alltraps>

8010830e <vector165>:
.globl vector165
vector165:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $165
80108310:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108315:	e9 36 f3 ff ff       	jmp    80107650 <alltraps>

8010831a <vector166>:
.globl vector166
vector166:
  pushl $0
8010831a:	6a 00                	push   $0x0
  pushl $166
8010831c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108321:	e9 2a f3 ff ff       	jmp    80107650 <alltraps>

80108326 <vector167>:
.globl vector167
vector167:
  pushl $0
80108326:	6a 00                	push   $0x0
  pushl $167
80108328:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010832d:	e9 1e f3 ff ff       	jmp    80107650 <alltraps>

80108332 <vector168>:
.globl vector168
vector168:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $168
80108334:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80108339:	e9 12 f3 ff ff       	jmp    80107650 <alltraps>

8010833e <vector169>:
.globl vector169
vector169:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $169
80108340:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108345:	e9 06 f3 ff ff       	jmp    80107650 <alltraps>

8010834a <vector170>:
.globl vector170
vector170:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $170
8010834c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108351:	e9 fa f2 ff ff       	jmp    80107650 <alltraps>

80108356 <vector171>:
.globl vector171
vector171:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $171
80108358:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010835d:	e9 ee f2 ff ff       	jmp    80107650 <alltraps>

80108362 <vector172>:
.globl vector172
vector172:
  pushl $0
80108362:	6a 00                	push   $0x0
  pushl $172
80108364:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80108369:	e9 e2 f2 ff ff       	jmp    80107650 <alltraps>

8010836e <vector173>:
.globl vector173
vector173:
  pushl $0
8010836e:	6a 00                	push   $0x0
  pushl $173
80108370:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108375:	e9 d6 f2 ff ff       	jmp    80107650 <alltraps>

8010837a <vector174>:
.globl vector174
vector174:
  pushl $0
8010837a:	6a 00                	push   $0x0
  pushl $174
8010837c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80108381:	e9 ca f2 ff ff       	jmp    80107650 <alltraps>

80108386 <vector175>:
.globl vector175
vector175:
  pushl $0
80108386:	6a 00                	push   $0x0
  pushl $175
80108388:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010838d:	e9 be f2 ff ff       	jmp    80107650 <alltraps>

80108392 <vector176>:
.globl vector176
vector176:
  pushl $0
80108392:	6a 00                	push   $0x0
  pushl $176
80108394:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108399:	e9 b2 f2 ff ff       	jmp    80107650 <alltraps>

8010839e <vector177>:
.globl vector177
vector177:
  pushl $0
8010839e:	6a 00                	push   $0x0
  pushl $177
801083a0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801083a5:	e9 a6 f2 ff ff       	jmp    80107650 <alltraps>

801083aa <vector178>:
.globl vector178
vector178:
  pushl $0
801083aa:	6a 00                	push   $0x0
  pushl $178
801083ac:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801083b1:	e9 9a f2 ff ff       	jmp    80107650 <alltraps>

801083b6 <vector179>:
.globl vector179
vector179:
  pushl $0
801083b6:	6a 00                	push   $0x0
  pushl $179
801083b8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801083bd:	e9 8e f2 ff ff       	jmp    80107650 <alltraps>

801083c2 <vector180>:
.globl vector180
vector180:
  pushl $0
801083c2:	6a 00                	push   $0x0
  pushl $180
801083c4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801083c9:	e9 82 f2 ff ff       	jmp    80107650 <alltraps>

801083ce <vector181>:
.globl vector181
vector181:
  pushl $0
801083ce:	6a 00                	push   $0x0
  pushl $181
801083d0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801083d5:	e9 76 f2 ff ff       	jmp    80107650 <alltraps>

801083da <vector182>:
.globl vector182
vector182:
  pushl $0
801083da:	6a 00                	push   $0x0
  pushl $182
801083dc:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801083e1:	e9 6a f2 ff ff       	jmp    80107650 <alltraps>

801083e6 <vector183>:
.globl vector183
vector183:
  pushl $0
801083e6:	6a 00                	push   $0x0
  pushl $183
801083e8:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801083ed:	e9 5e f2 ff ff       	jmp    80107650 <alltraps>

801083f2 <vector184>:
.globl vector184
vector184:
  pushl $0
801083f2:	6a 00                	push   $0x0
  pushl $184
801083f4:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801083f9:	e9 52 f2 ff ff       	jmp    80107650 <alltraps>

801083fe <vector185>:
.globl vector185
vector185:
  pushl $0
801083fe:	6a 00                	push   $0x0
  pushl $185
80108400:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108405:	e9 46 f2 ff ff       	jmp    80107650 <alltraps>

8010840a <vector186>:
.globl vector186
vector186:
  pushl $0
8010840a:	6a 00                	push   $0x0
  pushl $186
8010840c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108411:	e9 3a f2 ff ff       	jmp    80107650 <alltraps>

80108416 <vector187>:
.globl vector187
vector187:
  pushl $0
80108416:	6a 00                	push   $0x0
  pushl $187
80108418:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010841d:	e9 2e f2 ff ff       	jmp    80107650 <alltraps>

80108422 <vector188>:
.globl vector188
vector188:
  pushl $0
80108422:	6a 00                	push   $0x0
  pushl $188
80108424:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108429:	e9 22 f2 ff ff       	jmp    80107650 <alltraps>

8010842e <vector189>:
.globl vector189
vector189:
  pushl $0
8010842e:	6a 00                	push   $0x0
  pushl $189
80108430:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108435:	e9 16 f2 ff ff       	jmp    80107650 <alltraps>

8010843a <vector190>:
.globl vector190
vector190:
  pushl $0
8010843a:	6a 00                	push   $0x0
  pushl $190
8010843c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108441:	e9 0a f2 ff ff       	jmp    80107650 <alltraps>

80108446 <vector191>:
.globl vector191
vector191:
  pushl $0
80108446:	6a 00                	push   $0x0
  pushl $191
80108448:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010844d:	e9 fe f1 ff ff       	jmp    80107650 <alltraps>

80108452 <vector192>:
.globl vector192
vector192:
  pushl $0
80108452:	6a 00                	push   $0x0
  pushl $192
80108454:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108459:	e9 f2 f1 ff ff       	jmp    80107650 <alltraps>

8010845e <vector193>:
.globl vector193
vector193:
  pushl $0
8010845e:	6a 00                	push   $0x0
  pushl $193
80108460:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108465:	e9 e6 f1 ff ff       	jmp    80107650 <alltraps>

8010846a <vector194>:
.globl vector194
vector194:
  pushl $0
8010846a:	6a 00                	push   $0x0
  pushl $194
8010846c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108471:	e9 da f1 ff ff       	jmp    80107650 <alltraps>

80108476 <vector195>:
.globl vector195
vector195:
  pushl $0
80108476:	6a 00                	push   $0x0
  pushl $195
80108478:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010847d:	e9 ce f1 ff ff       	jmp    80107650 <alltraps>

80108482 <vector196>:
.globl vector196
vector196:
  pushl $0
80108482:	6a 00                	push   $0x0
  pushl $196
80108484:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108489:	e9 c2 f1 ff ff       	jmp    80107650 <alltraps>

8010848e <vector197>:
.globl vector197
vector197:
  pushl $0
8010848e:	6a 00                	push   $0x0
  pushl $197
80108490:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80108495:	e9 b6 f1 ff ff       	jmp    80107650 <alltraps>

8010849a <vector198>:
.globl vector198
vector198:
  pushl $0
8010849a:	6a 00                	push   $0x0
  pushl $198
8010849c:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801084a1:	e9 aa f1 ff ff       	jmp    80107650 <alltraps>

801084a6 <vector199>:
.globl vector199
vector199:
  pushl $0
801084a6:	6a 00                	push   $0x0
  pushl $199
801084a8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801084ad:	e9 9e f1 ff ff       	jmp    80107650 <alltraps>

801084b2 <vector200>:
.globl vector200
vector200:
  pushl $0
801084b2:	6a 00                	push   $0x0
  pushl $200
801084b4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801084b9:	e9 92 f1 ff ff       	jmp    80107650 <alltraps>

801084be <vector201>:
.globl vector201
vector201:
  pushl $0
801084be:	6a 00                	push   $0x0
  pushl $201
801084c0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801084c5:	e9 86 f1 ff ff       	jmp    80107650 <alltraps>

801084ca <vector202>:
.globl vector202
vector202:
  pushl $0
801084ca:	6a 00                	push   $0x0
  pushl $202
801084cc:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801084d1:	e9 7a f1 ff ff       	jmp    80107650 <alltraps>

801084d6 <vector203>:
.globl vector203
vector203:
  pushl $0
801084d6:	6a 00                	push   $0x0
  pushl $203
801084d8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801084dd:	e9 6e f1 ff ff       	jmp    80107650 <alltraps>

801084e2 <vector204>:
.globl vector204
vector204:
  pushl $0
801084e2:	6a 00                	push   $0x0
  pushl $204
801084e4:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801084e9:	e9 62 f1 ff ff       	jmp    80107650 <alltraps>

801084ee <vector205>:
.globl vector205
vector205:
  pushl $0
801084ee:	6a 00                	push   $0x0
  pushl $205
801084f0:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801084f5:	e9 56 f1 ff ff       	jmp    80107650 <alltraps>

801084fa <vector206>:
.globl vector206
vector206:
  pushl $0
801084fa:	6a 00                	push   $0x0
  pushl $206
801084fc:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108501:	e9 4a f1 ff ff       	jmp    80107650 <alltraps>

80108506 <vector207>:
.globl vector207
vector207:
  pushl $0
80108506:	6a 00                	push   $0x0
  pushl $207
80108508:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010850d:	e9 3e f1 ff ff       	jmp    80107650 <alltraps>

80108512 <vector208>:
.globl vector208
vector208:
  pushl $0
80108512:	6a 00                	push   $0x0
  pushl $208
80108514:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108519:	e9 32 f1 ff ff       	jmp    80107650 <alltraps>

8010851e <vector209>:
.globl vector209
vector209:
  pushl $0
8010851e:	6a 00                	push   $0x0
  pushl $209
80108520:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108525:	e9 26 f1 ff ff       	jmp    80107650 <alltraps>

8010852a <vector210>:
.globl vector210
vector210:
  pushl $0
8010852a:	6a 00                	push   $0x0
  pushl $210
8010852c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108531:	e9 1a f1 ff ff       	jmp    80107650 <alltraps>

80108536 <vector211>:
.globl vector211
vector211:
  pushl $0
80108536:	6a 00                	push   $0x0
  pushl $211
80108538:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010853d:	e9 0e f1 ff ff       	jmp    80107650 <alltraps>

80108542 <vector212>:
.globl vector212
vector212:
  pushl $0
80108542:	6a 00                	push   $0x0
  pushl $212
80108544:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108549:	e9 02 f1 ff ff       	jmp    80107650 <alltraps>

8010854e <vector213>:
.globl vector213
vector213:
  pushl $0
8010854e:	6a 00                	push   $0x0
  pushl $213
80108550:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108555:	e9 f6 f0 ff ff       	jmp    80107650 <alltraps>

8010855a <vector214>:
.globl vector214
vector214:
  pushl $0
8010855a:	6a 00                	push   $0x0
  pushl $214
8010855c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108561:	e9 ea f0 ff ff       	jmp    80107650 <alltraps>

80108566 <vector215>:
.globl vector215
vector215:
  pushl $0
80108566:	6a 00                	push   $0x0
  pushl $215
80108568:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010856d:	e9 de f0 ff ff       	jmp    80107650 <alltraps>

80108572 <vector216>:
.globl vector216
vector216:
  pushl $0
80108572:	6a 00                	push   $0x0
  pushl $216
80108574:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108579:	e9 d2 f0 ff ff       	jmp    80107650 <alltraps>

8010857e <vector217>:
.globl vector217
vector217:
  pushl $0
8010857e:	6a 00                	push   $0x0
  pushl $217
80108580:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108585:	e9 c6 f0 ff ff       	jmp    80107650 <alltraps>

8010858a <vector218>:
.globl vector218
vector218:
  pushl $0
8010858a:	6a 00                	push   $0x0
  pushl $218
8010858c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108591:	e9 ba f0 ff ff       	jmp    80107650 <alltraps>

80108596 <vector219>:
.globl vector219
vector219:
  pushl $0
80108596:	6a 00                	push   $0x0
  pushl $219
80108598:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
8010859d:	e9 ae f0 ff ff       	jmp    80107650 <alltraps>

801085a2 <vector220>:
.globl vector220
vector220:
  pushl $0
801085a2:	6a 00                	push   $0x0
  pushl $220
801085a4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801085a9:	e9 a2 f0 ff ff       	jmp    80107650 <alltraps>

801085ae <vector221>:
.globl vector221
vector221:
  pushl $0
801085ae:	6a 00                	push   $0x0
  pushl $221
801085b0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801085b5:	e9 96 f0 ff ff       	jmp    80107650 <alltraps>

801085ba <vector222>:
.globl vector222
vector222:
  pushl $0
801085ba:	6a 00                	push   $0x0
  pushl $222
801085bc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801085c1:	e9 8a f0 ff ff       	jmp    80107650 <alltraps>

801085c6 <vector223>:
.globl vector223
vector223:
  pushl $0
801085c6:	6a 00                	push   $0x0
  pushl $223
801085c8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801085cd:	e9 7e f0 ff ff       	jmp    80107650 <alltraps>

801085d2 <vector224>:
.globl vector224
vector224:
  pushl $0
801085d2:	6a 00                	push   $0x0
  pushl $224
801085d4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801085d9:	e9 72 f0 ff ff       	jmp    80107650 <alltraps>

801085de <vector225>:
.globl vector225
vector225:
  pushl $0
801085de:	6a 00                	push   $0x0
  pushl $225
801085e0:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801085e5:	e9 66 f0 ff ff       	jmp    80107650 <alltraps>

801085ea <vector226>:
.globl vector226
vector226:
  pushl $0
801085ea:	6a 00                	push   $0x0
  pushl $226
801085ec:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801085f1:	e9 5a f0 ff ff       	jmp    80107650 <alltraps>

801085f6 <vector227>:
.globl vector227
vector227:
  pushl $0
801085f6:	6a 00                	push   $0x0
  pushl $227
801085f8:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801085fd:	e9 4e f0 ff ff       	jmp    80107650 <alltraps>

80108602 <vector228>:
.globl vector228
vector228:
  pushl $0
80108602:	6a 00                	push   $0x0
  pushl $228
80108604:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108609:	e9 42 f0 ff ff       	jmp    80107650 <alltraps>

8010860e <vector229>:
.globl vector229
vector229:
  pushl $0
8010860e:	6a 00                	push   $0x0
  pushl $229
80108610:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108615:	e9 36 f0 ff ff       	jmp    80107650 <alltraps>

8010861a <vector230>:
.globl vector230
vector230:
  pushl $0
8010861a:	6a 00                	push   $0x0
  pushl $230
8010861c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108621:	e9 2a f0 ff ff       	jmp    80107650 <alltraps>

80108626 <vector231>:
.globl vector231
vector231:
  pushl $0
80108626:	6a 00                	push   $0x0
  pushl $231
80108628:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010862d:	e9 1e f0 ff ff       	jmp    80107650 <alltraps>

80108632 <vector232>:
.globl vector232
vector232:
  pushl $0
80108632:	6a 00                	push   $0x0
  pushl $232
80108634:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108639:	e9 12 f0 ff ff       	jmp    80107650 <alltraps>

8010863e <vector233>:
.globl vector233
vector233:
  pushl $0
8010863e:	6a 00                	push   $0x0
  pushl $233
80108640:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108645:	e9 06 f0 ff ff       	jmp    80107650 <alltraps>

8010864a <vector234>:
.globl vector234
vector234:
  pushl $0
8010864a:	6a 00                	push   $0x0
  pushl $234
8010864c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108651:	e9 fa ef ff ff       	jmp    80107650 <alltraps>

80108656 <vector235>:
.globl vector235
vector235:
  pushl $0
80108656:	6a 00                	push   $0x0
  pushl $235
80108658:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010865d:	e9 ee ef ff ff       	jmp    80107650 <alltraps>

80108662 <vector236>:
.globl vector236
vector236:
  pushl $0
80108662:	6a 00                	push   $0x0
  pushl $236
80108664:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108669:	e9 e2 ef ff ff       	jmp    80107650 <alltraps>

8010866e <vector237>:
.globl vector237
vector237:
  pushl $0
8010866e:	6a 00                	push   $0x0
  pushl $237
80108670:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108675:	e9 d6 ef ff ff       	jmp    80107650 <alltraps>

8010867a <vector238>:
.globl vector238
vector238:
  pushl $0
8010867a:	6a 00                	push   $0x0
  pushl $238
8010867c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108681:	e9 ca ef ff ff       	jmp    80107650 <alltraps>

80108686 <vector239>:
.globl vector239
vector239:
  pushl $0
80108686:	6a 00                	push   $0x0
  pushl $239
80108688:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010868d:	e9 be ef ff ff       	jmp    80107650 <alltraps>

80108692 <vector240>:
.globl vector240
vector240:
  pushl $0
80108692:	6a 00                	push   $0x0
  pushl $240
80108694:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108699:	e9 b2 ef ff ff       	jmp    80107650 <alltraps>

8010869e <vector241>:
.globl vector241
vector241:
  pushl $0
8010869e:	6a 00                	push   $0x0
  pushl $241
801086a0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801086a5:	e9 a6 ef ff ff       	jmp    80107650 <alltraps>

801086aa <vector242>:
.globl vector242
vector242:
  pushl $0
801086aa:	6a 00                	push   $0x0
  pushl $242
801086ac:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801086b1:	e9 9a ef ff ff       	jmp    80107650 <alltraps>

801086b6 <vector243>:
.globl vector243
vector243:
  pushl $0
801086b6:	6a 00                	push   $0x0
  pushl $243
801086b8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801086bd:	e9 8e ef ff ff       	jmp    80107650 <alltraps>

801086c2 <vector244>:
.globl vector244
vector244:
  pushl $0
801086c2:	6a 00                	push   $0x0
  pushl $244
801086c4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801086c9:	e9 82 ef ff ff       	jmp    80107650 <alltraps>

801086ce <vector245>:
.globl vector245
vector245:
  pushl $0
801086ce:	6a 00                	push   $0x0
  pushl $245
801086d0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801086d5:	e9 76 ef ff ff       	jmp    80107650 <alltraps>

801086da <vector246>:
.globl vector246
vector246:
  pushl $0
801086da:	6a 00                	push   $0x0
  pushl $246
801086dc:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801086e1:	e9 6a ef ff ff       	jmp    80107650 <alltraps>

801086e6 <vector247>:
.globl vector247
vector247:
  pushl $0
801086e6:	6a 00                	push   $0x0
  pushl $247
801086e8:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801086ed:	e9 5e ef ff ff       	jmp    80107650 <alltraps>

801086f2 <vector248>:
.globl vector248
vector248:
  pushl $0
801086f2:	6a 00                	push   $0x0
  pushl $248
801086f4:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801086f9:	e9 52 ef ff ff       	jmp    80107650 <alltraps>

801086fe <vector249>:
.globl vector249
vector249:
  pushl $0
801086fe:	6a 00                	push   $0x0
  pushl $249
80108700:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108705:	e9 46 ef ff ff       	jmp    80107650 <alltraps>

8010870a <vector250>:
.globl vector250
vector250:
  pushl $0
8010870a:	6a 00                	push   $0x0
  pushl $250
8010870c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108711:	e9 3a ef ff ff       	jmp    80107650 <alltraps>

80108716 <vector251>:
.globl vector251
vector251:
  pushl $0
80108716:	6a 00                	push   $0x0
  pushl $251
80108718:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010871d:	e9 2e ef ff ff       	jmp    80107650 <alltraps>

80108722 <vector252>:
.globl vector252
vector252:
  pushl $0
80108722:	6a 00                	push   $0x0
  pushl $252
80108724:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108729:	e9 22 ef ff ff       	jmp    80107650 <alltraps>

8010872e <vector253>:
.globl vector253
vector253:
  pushl $0
8010872e:	6a 00                	push   $0x0
  pushl $253
80108730:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108735:	e9 16 ef ff ff       	jmp    80107650 <alltraps>

8010873a <vector254>:
.globl vector254
vector254:
  pushl $0
8010873a:	6a 00                	push   $0x0
  pushl $254
8010873c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108741:	e9 0a ef ff ff       	jmp    80107650 <alltraps>

80108746 <vector255>:
.globl vector255
vector255:
  pushl $0
80108746:	6a 00                	push   $0x0
  pushl $255
80108748:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010874d:	e9 fe ee ff ff       	jmp    80107650 <alltraps>
	...

80108754 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108754:	55                   	push   %ebp
80108755:	89 e5                	mov    %esp,%ebp
80108757:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010875a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010875d:	83 e8 01             	sub    $0x1,%eax
80108760:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108764:	8b 45 08             	mov    0x8(%ebp),%eax
80108767:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010876b:	8b 45 08             	mov    0x8(%ebp),%eax
8010876e:	c1 e8 10             	shr    $0x10,%eax
80108771:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108775:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108778:	0f 01 10             	lgdtl  (%eax)
}
8010877b:	c9                   	leave  
8010877c:	c3                   	ret    

8010877d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010877d:	55                   	push   %ebp
8010877e:	89 e5                	mov    %esp,%ebp
80108780:	83 ec 04             	sub    $0x4,%esp
80108783:	8b 45 08             	mov    0x8(%ebp),%eax
80108786:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010878a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010878e:	0f 00 d8             	ltr    %ax
}
80108791:	c9                   	leave  
80108792:	c3                   	ret    

80108793 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108793:	55                   	push   %ebp
80108794:	89 e5                	mov    %esp,%ebp
80108796:	83 ec 04             	sub    $0x4,%esp
80108799:	8b 45 08             	mov    0x8(%ebp),%eax
8010879c:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801087a0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801087a4:	8e e8                	mov    %eax,%gs
}
801087a6:	c9                   	leave  
801087a7:	c3                   	ret    

801087a8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801087a8:	55                   	push   %ebp
801087a9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801087ab:	8b 45 08             	mov    0x8(%ebp),%eax
801087ae:	0f 22 d8             	mov    %eax,%cr3
}
801087b1:	5d                   	pop    %ebp
801087b2:	c3                   	ret    

801087b3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801087b3:	55                   	push   %ebp
801087b4:	89 e5                	mov    %esp,%ebp
801087b6:	8b 45 08             	mov    0x8(%ebp),%eax
801087b9:	05 00 00 00 80       	add    $0x80000000,%eax
801087be:	5d                   	pop    %ebp
801087bf:	c3                   	ret    

801087c0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801087c0:	55                   	push   %ebp
801087c1:	89 e5                	mov    %esp,%ebp
801087c3:	8b 45 08             	mov    0x8(%ebp),%eax
801087c6:	05 00 00 00 80       	add    $0x80000000,%eax
801087cb:	5d                   	pop    %ebp
801087cc:	c3                   	ret    

801087cd <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801087cd:	55                   	push   %ebp
801087ce:	89 e5                	mov    %esp,%ebp
801087d0:	53                   	push   %ebx
801087d1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801087d4:	e8 18 b9 ff ff       	call   801040f1 <cpunum>
801087d9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801087df:	05 60 09 11 80       	add    $0x80110960,%eax
801087e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801087e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ea:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801087f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f3:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801087f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087fc:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108803:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108807:	83 e2 f0             	and    $0xfffffff0,%edx
8010880a:	83 ca 0a             	or     $0xa,%edx
8010880d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108813:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108817:	83 ca 10             	or     $0x10,%edx
8010881a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010881d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108820:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108824:	83 e2 9f             	and    $0xffffff9f,%edx
80108827:	88 50 7d             	mov    %dl,0x7d(%eax)
8010882a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108831:	83 ca 80             	or     $0xffffff80,%edx
80108834:	88 50 7d             	mov    %dl,0x7d(%eax)
80108837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010883e:	83 ca 0f             	or     $0xf,%edx
80108841:	88 50 7e             	mov    %dl,0x7e(%eax)
80108844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108847:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010884b:	83 e2 ef             	and    $0xffffffef,%edx
8010884e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108854:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108858:	83 e2 df             	and    $0xffffffdf,%edx
8010885b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010885e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108861:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108865:	83 ca 40             	or     $0x40,%edx
80108868:	88 50 7e             	mov    %dl,0x7e(%eax)
8010886b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010886e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108872:	83 ca 80             	or     $0xffffff80,%edx
80108875:	88 50 7e             	mov    %dl,0x7e(%eax)
80108878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010887b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010887f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108882:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108889:	ff ff 
8010888b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010888e:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108895:	00 00 
80108897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010889a:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801088a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801088ab:	83 e2 f0             	and    $0xfffffff0,%edx
801088ae:	83 ca 02             	or     $0x2,%edx
801088b1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801088b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ba:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801088c1:	83 ca 10             	or     $0x10,%edx
801088c4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801088ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088cd:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801088d4:	83 e2 9f             	and    $0xffffff9f,%edx
801088d7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801088dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801088e7:	83 ca 80             	or     $0xffffff80,%edx
801088ea:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801088f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801088fa:	83 ca 0f             	or     $0xf,%edx
801088fd:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108903:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108906:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010890d:	83 e2 ef             	and    $0xffffffef,%edx
80108910:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108916:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108919:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108920:	83 e2 df             	and    $0xffffffdf,%edx
80108923:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108929:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010892c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108933:	83 ca 40             	or     $0x40,%edx
80108936:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010893c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010893f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108946:	83 ca 80             	or     $0xffffff80,%edx
80108949:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010894f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108952:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108963:	ff ff 
80108965:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108968:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010896f:	00 00 
80108971:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108974:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010897b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010897e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108985:	83 e2 f0             	and    $0xfffffff0,%edx
80108988:	83 ca 0a             	or     $0xa,%edx
8010898b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108991:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108994:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010899b:	83 ca 10             	or     $0x10,%edx
8010899e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801089ae:	83 ca 60             	or     $0x60,%edx
801089b1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ba:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801089c1:	83 ca 80             	or     $0xffffff80,%edx
801089c4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089cd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801089d4:	83 ca 0f             	or     $0xf,%edx
801089d7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801089dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089e0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801089e7:	83 e2 ef             	and    $0xffffffef,%edx
801089ea:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801089f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801089fa:	83 e2 df             	and    $0xffffffdf,%edx
801089fd:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a06:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a0d:	83 ca 40             	or     $0x40,%edx
80108a10:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a19:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a20:	83 ca 80             	or     $0xffffff80,%edx
80108a23:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a2c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a36:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108a3d:	ff ff 
80108a3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a42:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108a49:	00 00 
80108a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a4e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a58:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108a5f:	83 e2 f0             	and    $0xfffffff0,%edx
80108a62:	83 ca 02             	or     $0x2,%edx
80108a65:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a6e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108a75:	83 ca 10             	or     $0x10,%edx
80108a78:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a81:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108a88:	83 ca 60             	or     $0x60,%edx
80108a8b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a94:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108a9b:	83 ca 80             	or     $0xffffff80,%edx
80108a9e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108aa4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108aae:	83 ca 0f             	or     $0xf,%edx
80108ab1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aba:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108ac1:	83 e2 ef             	and    $0xffffffef,%edx
80108ac4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108acd:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108ad4:	83 e2 df             	and    $0xffffffdf,%edx
80108ad7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108add:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ae0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108ae7:	83 ca 40             	or     $0x40,%edx
80108aea:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108af0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108af3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108afa:	83 ca 80             	or     $0xffffff80,%edx
80108afd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b06:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b10:	05 b4 00 00 00       	add    $0xb4,%eax
80108b15:	89 c3                	mov    %eax,%ebx
80108b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b1a:	05 b4 00 00 00       	add    $0xb4,%eax
80108b1f:	c1 e8 10             	shr    $0x10,%eax
80108b22:	89 c1                	mov    %eax,%ecx
80108b24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b27:	05 b4 00 00 00       	add    $0xb4,%eax
80108b2c:	c1 e8 18             	shr    $0x18,%eax
80108b2f:	89 c2                	mov    %eax,%edx
80108b31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b34:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108b3b:	00 00 
80108b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b40:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b4a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b53:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b5a:	83 e1 f0             	and    $0xfffffff0,%ecx
80108b5d:	83 c9 02             	or     $0x2,%ecx
80108b60:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b69:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b70:	83 c9 10             	or     $0x10,%ecx
80108b73:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b7c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b83:	83 e1 9f             	and    $0xffffff9f,%ecx
80108b86:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b8f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b96:	83 c9 80             	or     $0xffffff80,%ecx
80108b99:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ba2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108ba9:	83 e1 f0             	and    $0xfffffff0,%ecx
80108bac:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108bb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108bbc:	83 e1 ef             	and    $0xffffffef,%ecx
80108bbf:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108bcf:	83 e1 df             	and    $0xffffffdf,%ecx
80108bd2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bdb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108be2:	83 c9 40             	or     $0x40,%ecx
80108be5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bee:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108bf5:	83 c9 80             	or     $0xffffff80,%ecx
80108bf8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c01:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0a:	83 c0 70             	add    $0x70,%eax
80108c0d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108c14:	00 
80108c15:	89 04 24             	mov    %eax,(%esp)
80108c18:	e8 37 fb ff ff       	call   80108754 <lgdt>
  loadgs(SEG_KCPU << 3);
80108c1d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108c24:	e8 6a fb ff ff       	call   80108793 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108c29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c2c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108c32:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108c39:	00 00 00 00 
}
80108c3d:	83 c4 24             	add    $0x24,%esp
80108c40:	5b                   	pop    %ebx
80108c41:	5d                   	pop    %ebp
80108c42:	c3                   	ret    

80108c43 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108c43:	55                   	push   %ebp
80108c44:	89 e5                	mov    %esp,%ebp
80108c46:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108c49:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c4c:	c1 e8 16             	shr    $0x16,%eax
80108c4f:	c1 e0 02             	shl    $0x2,%eax
80108c52:	03 45 08             	add    0x8(%ebp),%eax
80108c55:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108c58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c5b:	8b 00                	mov    (%eax),%eax
80108c5d:	83 e0 01             	and    $0x1,%eax
80108c60:	84 c0                	test   %al,%al
80108c62:	74 17                	je     80108c7b <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108c64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c67:	8b 00                	mov    (%eax),%eax
80108c69:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c6e:	89 04 24             	mov    %eax,(%esp)
80108c71:	e8 4a fb ff ff       	call   801087c0 <p2v>
80108c76:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108c79:	eb 4b                	jmp    80108cc6 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108c7b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108c7f:	74 0e                	je     80108c8f <walkpgdir+0x4c>
80108c81:	e8 dd b0 ff ff       	call   80103d63 <kalloc>
80108c86:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108c89:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108c8d:	75 07                	jne    80108c96 <walkpgdir+0x53>
      return 0;
80108c8f:	b8 00 00 00 00       	mov    $0x0,%eax
80108c94:	eb 41                	jmp    80108cd7 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108c96:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c9d:	00 
80108c9e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ca5:	00 
80108ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ca9:	89 04 24             	mov    %eax,(%esp)
80108cac:	e8 a5 d3 ff ff       	call   80106056 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108cb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb4:	89 04 24             	mov    %eax,(%esp)
80108cb7:	e8 f7 fa ff ff       	call   801087b3 <v2p>
80108cbc:	89 c2                	mov    %eax,%edx
80108cbe:	83 ca 07             	or     $0x7,%edx
80108cc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108cc4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108cc6:	8b 45 0c             	mov    0xc(%ebp),%eax
80108cc9:	c1 e8 0c             	shr    $0xc,%eax
80108ccc:	25 ff 03 00 00       	and    $0x3ff,%eax
80108cd1:	c1 e0 02             	shl    $0x2,%eax
80108cd4:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108cd7:	c9                   	leave  
80108cd8:	c3                   	ret    

80108cd9 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108cd9:	55                   	push   %ebp
80108cda:	89 e5                	mov    %esp,%ebp
80108cdc:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108cdf:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ce2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ce7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108cea:	8b 45 0c             	mov    0xc(%ebp),%eax
80108ced:	03 45 10             	add    0x10(%ebp),%eax
80108cf0:	83 e8 01             	sub    $0x1,%eax
80108cf3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cf8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108cfb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108d02:	00 
80108d03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d06:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d0a:	8b 45 08             	mov    0x8(%ebp),%eax
80108d0d:	89 04 24             	mov    %eax,(%esp)
80108d10:	e8 2e ff ff ff       	call   80108c43 <walkpgdir>
80108d15:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108d18:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d1c:	75 07                	jne    80108d25 <mappages+0x4c>
      return -1;
80108d1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d23:	eb 46                	jmp    80108d6b <mappages+0x92>
    if(*pte & PTE_P)
80108d25:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d28:	8b 00                	mov    (%eax),%eax
80108d2a:	83 e0 01             	and    $0x1,%eax
80108d2d:	84 c0                	test   %al,%al
80108d2f:	74 0c                	je     80108d3d <mappages+0x64>
      panic("remap");
80108d31:	c7 04 24 64 9c 10 80 	movl   $0x80109c64,(%esp)
80108d38:	e8 00 78 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108d3d:	8b 45 18             	mov    0x18(%ebp),%eax
80108d40:	0b 45 14             	or     0x14(%ebp),%eax
80108d43:	89 c2                	mov    %eax,%edx
80108d45:	83 ca 01             	or     $0x1,%edx
80108d48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d4b:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108d4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d50:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108d53:	74 10                	je     80108d65 <mappages+0x8c>
      break;
    a += PGSIZE;
80108d55:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108d5c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108d63:	eb 96                	jmp    80108cfb <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108d65:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108d66:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108d6b:	c9                   	leave  
80108d6c:	c3                   	ret    

80108d6d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108d6d:	55                   	push   %ebp
80108d6e:	89 e5                	mov    %esp,%ebp
80108d70:	53                   	push   %ebx
80108d71:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108d74:	e8 ea af ff ff       	call   80103d63 <kalloc>
80108d79:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108d7c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108d80:	75 0a                	jne    80108d8c <setupkvm+0x1f>
    return 0;
80108d82:	b8 00 00 00 00       	mov    $0x0,%eax
80108d87:	e9 98 00 00 00       	jmp    80108e24 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108d8c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108d93:	00 
80108d94:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108d9b:	00 
80108d9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d9f:	89 04 24             	mov    %eax,(%esp)
80108da2:	e8 af d2 ff ff       	call   80106056 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108da7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108dae:	e8 0d fa ff ff       	call   801087c0 <p2v>
80108db3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108db8:	76 0c                	jbe    80108dc6 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108dba:	c7 04 24 6a 9c 10 80 	movl   $0x80109c6a,(%esp)
80108dc1:	e8 77 77 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108dc6:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108dcd:	eb 49                	jmp    80108e18 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108dd2:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108dd8:	8b 50 04             	mov    0x4(%eax),%edx
80108ddb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dde:	8b 58 08             	mov    0x8(%eax),%ebx
80108de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108de4:	8b 40 04             	mov    0x4(%eax),%eax
80108de7:	29 c3                	sub    %eax,%ebx
80108de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dec:	8b 00                	mov    (%eax),%eax
80108dee:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108df2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108df6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108dfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80108dfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e01:	89 04 24             	mov    %eax,(%esp)
80108e04:	e8 d0 fe ff ff       	call   80108cd9 <mappages>
80108e09:	85 c0                	test   %eax,%eax
80108e0b:	79 07                	jns    80108e14 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108e0d:	b8 00 00 00 00       	mov    $0x0,%eax
80108e12:	eb 10                	jmp    80108e24 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108e14:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108e18:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108e1f:	72 ae                	jb     80108dcf <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108e21:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108e24:	83 c4 34             	add    $0x34,%esp
80108e27:	5b                   	pop    %ebx
80108e28:	5d                   	pop    %ebp
80108e29:	c3                   	ret    

80108e2a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108e2a:	55                   	push   %ebp
80108e2b:	89 e5                	mov    %esp,%ebp
80108e2d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108e30:	e8 38 ff ff ff       	call   80108d6d <setupkvm>
80108e35:	a3 38 37 11 80       	mov    %eax,0x80113738
  switchkvm();
80108e3a:	e8 02 00 00 00       	call   80108e41 <switchkvm>
}
80108e3f:	c9                   	leave  
80108e40:	c3                   	ret    

80108e41 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108e41:	55                   	push   %ebp
80108e42:	89 e5                	mov    %esp,%ebp
80108e44:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108e47:	a1 38 37 11 80       	mov    0x80113738,%eax
80108e4c:	89 04 24             	mov    %eax,(%esp)
80108e4f:	e8 5f f9 ff ff       	call   801087b3 <v2p>
80108e54:	89 04 24             	mov    %eax,(%esp)
80108e57:	e8 4c f9 ff ff       	call   801087a8 <lcr3>
}
80108e5c:	c9                   	leave  
80108e5d:	c3                   	ret    

80108e5e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108e5e:	55                   	push   %ebp
80108e5f:	89 e5                	mov    %esp,%ebp
80108e61:	53                   	push   %ebx
80108e62:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108e65:	e8 e5 d0 ff ff       	call   80105f4f <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108e6a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108e70:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108e77:	83 c2 08             	add    $0x8,%edx
80108e7a:	89 d3                	mov    %edx,%ebx
80108e7c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108e83:	83 c2 08             	add    $0x8,%edx
80108e86:	c1 ea 10             	shr    $0x10,%edx
80108e89:	89 d1                	mov    %edx,%ecx
80108e8b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108e92:	83 c2 08             	add    $0x8,%edx
80108e95:	c1 ea 18             	shr    $0x18,%edx
80108e98:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108e9f:	67 00 
80108ea1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108ea8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108eae:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108eb5:	83 e1 f0             	and    $0xfffffff0,%ecx
80108eb8:	83 c9 09             	or     $0x9,%ecx
80108ebb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ec1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ec8:	83 c9 10             	or     $0x10,%ecx
80108ecb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ed1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ed8:	83 e1 9f             	and    $0xffffff9f,%ecx
80108edb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ee1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ee8:	83 c9 80             	or     $0xffffff80,%ecx
80108eeb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ef1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108ef8:	83 e1 f0             	and    $0xfffffff0,%ecx
80108efb:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f01:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f08:	83 e1 ef             	and    $0xffffffef,%ecx
80108f0b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f11:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f18:	83 e1 df             	and    $0xffffffdf,%ecx
80108f1b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f21:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f28:	83 c9 40             	or     $0x40,%ecx
80108f2b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f31:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f38:	83 e1 7f             	and    $0x7f,%ecx
80108f3b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f41:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108f47:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f4d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108f54:	83 e2 ef             	and    $0xffffffef,%edx
80108f57:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108f5d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f63:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108f69:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f6f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108f76:	8b 52 08             	mov    0x8(%edx),%edx
80108f79:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108f7f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108f82:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108f89:	e8 ef f7 ff ff       	call   8010877d <ltr>
  if(p->pgdir == 0)
80108f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80108f91:	8b 40 04             	mov    0x4(%eax),%eax
80108f94:	85 c0                	test   %eax,%eax
80108f96:	75 0c                	jne    80108fa4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108f98:	c7 04 24 7b 9c 10 80 	movl   $0x80109c7b,(%esp)
80108f9f:	e8 99 75 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80108fa7:	8b 40 04             	mov    0x4(%eax),%eax
80108faa:	89 04 24             	mov    %eax,(%esp)
80108fad:	e8 01 f8 ff ff       	call   801087b3 <v2p>
80108fb2:	89 04 24             	mov    %eax,(%esp)
80108fb5:	e8 ee f7 ff ff       	call   801087a8 <lcr3>
  popcli();
80108fba:	e8 d8 cf ff ff       	call   80105f97 <popcli>
}
80108fbf:	83 c4 14             	add    $0x14,%esp
80108fc2:	5b                   	pop    %ebx
80108fc3:	5d                   	pop    %ebp
80108fc4:	c3                   	ret    

80108fc5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108fc5:	55                   	push   %ebp
80108fc6:	89 e5                	mov    %esp,%ebp
80108fc8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108fcb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108fd2:	76 0c                	jbe    80108fe0 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108fd4:	c7 04 24 8f 9c 10 80 	movl   $0x80109c8f,(%esp)
80108fdb:	e8 5d 75 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108fe0:	e8 7e ad ff ff       	call   80103d63 <kalloc>
80108fe5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108fe8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108fef:	00 
80108ff0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ff7:	00 
80108ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ffb:	89 04 24             	mov    %eax,(%esp)
80108ffe:	e8 53 d0 ff ff       	call   80106056 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109003:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109006:	89 04 24             	mov    %eax,(%esp)
80109009:	e8 a5 f7 ff ff       	call   801087b3 <v2p>
8010900e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109015:	00 
80109016:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010901a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109021:	00 
80109022:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109029:	00 
8010902a:	8b 45 08             	mov    0x8(%ebp),%eax
8010902d:	89 04 24             	mov    %eax,(%esp)
80109030:	e8 a4 fc ff ff       	call   80108cd9 <mappages>
  memmove(mem, init, sz);
80109035:	8b 45 10             	mov    0x10(%ebp),%eax
80109038:	89 44 24 08          	mov    %eax,0x8(%esp)
8010903c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010903f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109043:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109046:	89 04 24             	mov    %eax,(%esp)
80109049:	e8 db d0 ff ff       	call   80106129 <memmove>
}
8010904e:	c9                   	leave  
8010904f:	c3                   	ret    

80109050 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80109050:	55                   	push   %ebp
80109051:	89 e5                	mov    %esp,%ebp
80109053:	53                   	push   %ebx
80109054:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80109057:	8b 45 0c             	mov    0xc(%ebp),%eax
8010905a:	25 ff 0f 00 00       	and    $0xfff,%eax
8010905f:	85 c0                	test   %eax,%eax
80109061:	74 0c                	je     8010906f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80109063:	c7 04 24 ac 9c 10 80 	movl   $0x80109cac,(%esp)
8010906a:	e8 ce 74 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010906f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109076:	e9 ad 00 00 00       	jmp    80109128 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010907b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010907e:	8b 55 0c             	mov    0xc(%ebp),%edx
80109081:	01 d0                	add    %edx,%eax
80109083:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010908a:	00 
8010908b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010908f:	8b 45 08             	mov    0x8(%ebp),%eax
80109092:	89 04 24             	mov    %eax,(%esp)
80109095:	e8 a9 fb ff ff       	call   80108c43 <walkpgdir>
8010909a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010909d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801090a1:	75 0c                	jne    801090af <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801090a3:	c7 04 24 cf 9c 10 80 	movl   $0x80109ccf,(%esp)
801090aa:	e8 8e 74 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801090af:	8b 45 ec             	mov    -0x14(%ebp),%eax
801090b2:	8b 00                	mov    (%eax),%eax
801090b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801090b9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801090bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090bf:	8b 55 18             	mov    0x18(%ebp),%edx
801090c2:	89 d1                	mov    %edx,%ecx
801090c4:	29 c1                	sub    %eax,%ecx
801090c6:	89 c8                	mov    %ecx,%eax
801090c8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801090cd:	77 11                	ja     801090e0 <loaduvm+0x90>
      n = sz - i;
801090cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090d2:	8b 55 18             	mov    0x18(%ebp),%edx
801090d5:	89 d1                	mov    %edx,%ecx
801090d7:	29 c1                	sub    %eax,%ecx
801090d9:	89 c8                	mov    %ecx,%eax
801090db:	89 45 f0             	mov    %eax,-0x10(%ebp)
801090de:	eb 07                	jmp    801090e7 <loaduvm+0x97>
    else
      n = PGSIZE;
801090e0:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801090e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090ea:	8b 55 14             	mov    0x14(%ebp),%edx
801090ed:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801090f0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801090f3:	89 04 24             	mov    %eax,(%esp)
801090f6:	e8 c5 f6 ff ff       	call   801087c0 <p2v>
801090fb:	8b 55 f0             	mov    -0x10(%ebp),%edx
801090fe:	89 54 24 0c          	mov    %edx,0xc(%esp)
80109102:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109106:	89 44 24 04          	mov    %eax,0x4(%esp)
8010910a:	8b 45 10             	mov    0x10(%ebp),%eax
8010910d:	89 04 24             	mov    %eax,(%esp)
80109110:	e8 c1 9a ff ff       	call   80102bd6 <readi>
80109115:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80109118:	74 07                	je     80109121 <loaduvm+0xd1>
      return -1;
8010911a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010911f:	eb 18                	jmp    80109139 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109121:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109128:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010912b:	3b 45 18             	cmp    0x18(%ebp),%eax
8010912e:	0f 82 47 ff ff ff    	jb     8010907b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109134:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109139:	83 c4 24             	add    $0x24,%esp
8010913c:	5b                   	pop    %ebx
8010913d:	5d                   	pop    %ebp
8010913e:	c3                   	ret    

8010913f <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010913f:	55                   	push   %ebp
80109140:	89 e5                	mov    %esp,%ebp
80109142:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109145:	8b 45 10             	mov    0x10(%ebp),%eax
80109148:	85 c0                	test   %eax,%eax
8010914a:	79 0a                	jns    80109156 <allocuvm+0x17>
    return 0;
8010914c:	b8 00 00 00 00       	mov    $0x0,%eax
80109151:	e9 c1 00 00 00       	jmp    80109217 <allocuvm+0xd8>
  if(newsz < oldsz)
80109156:	8b 45 10             	mov    0x10(%ebp),%eax
80109159:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010915c:	73 08                	jae    80109166 <allocuvm+0x27>
    return oldsz;
8010915e:	8b 45 0c             	mov    0xc(%ebp),%eax
80109161:	e9 b1 00 00 00       	jmp    80109217 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80109166:	8b 45 0c             	mov    0xc(%ebp),%eax
80109169:	05 ff 0f 00 00       	add    $0xfff,%eax
8010916e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109173:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80109176:	e9 8d 00 00 00       	jmp    80109208 <allocuvm+0xc9>
    mem = kalloc();
8010917b:	e8 e3 ab ff ff       	call   80103d63 <kalloc>
80109180:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80109183:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109187:	75 2c                	jne    801091b5 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80109189:	c7 04 24 ed 9c 10 80 	movl   $0x80109ced,(%esp)
80109190:	e8 0c 72 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80109195:	8b 45 0c             	mov    0xc(%ebp),%eax
80109198:	89 44 24 08          	mov    %eax,0x8(%esp)
8010919c:	8b 45 10             	mov    0x10(%ebp),%eax
8010919f:	89 44 24 04          	mov    %eax,0x4(%esp)
801091a3:	8b 45 08             	mov    0x8(%ebp),%eax
801091a6:	89 04 24             	mov    %eax,(%esp)
801091a9:	e8 6b 00 00 00       	call   80109219 <deallocuvm>
      return 0;
801091ae:	b8 00 00 00 00       	mov    $0x0,%eax
801091b3:	eb 62                	jmp    80109217 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801091b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801091bc:	00 
801091bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801091c4:	00 
801091c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091c8:	89 04 24             	mov    %eax,(%esp)
801091cb:	e8 86 ce ff ff       	call   80106056 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801091d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091d3:	89 04 24             	mov    %eax,(%esp)
801091d6:	e8 d8 f5 ff ff       	call   801087b3 <v2p>
801091db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801091de:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801091e5:	00 
801091e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
801091ea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801091f1:	00 
801091f2:	89 54 24 04          	mov    %edx,0x4(%esp)
801091f6:	8b 45 08             	mov    0x8(%ebp),%eax
801091f9:	89 04 24             	mov    %eax,(%esp)
801091fc:	e8 d8 fa ff ff       	call   80108cd9 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109201:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109208:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010920b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010920e:	0f 82 67 ff ff ff    	jb     8010917b <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109214:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109217:	c9                   	leave  
80109218:	c3                   	ret    

80109219 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109219:	55                   	push   %ebp
8010921a:	89 e5                	mov    %esp,%ebp
8010921c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010921f:	8b 45 10             	mov    0x10(%ebp),%eax
80109222:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109225:	72 08                	jb     8010922f <deallocuvm+0x16>
    return oldsz;
80109227:	8b 45 0c             	mov    0xc(%ebp),%eax
8010922a:	e9 a4 00 00 00       	jmp    801092d3 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010922f:	8b 45 10             	mov    0x10(%ebp),%eax
80109232:	05 ff 0f 00 00       	add    $0xfff,%eax
80109237:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010923c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010923f:	e9 80 00 00 00       	jmp    801092c4 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109244:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109247:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010924e:	00 
8010924f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109253:	8b 45 08             	mov    0x8(%ebp),%eax
80109256:	89 04 24             	mov    %eax,(%esp)
80109259:	e8 e5 f9 ff ff       	call   80108c43 <walkpgdir>
8010925e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109261:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109265:	75 09                	jne    80109270 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80109267:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
8010926e:	eb 4d                	jmp    801092bd <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80109270:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109273:	8b 00                	mov    (%eax),%eax
80109275:	83 e0 01             	and    $0x1,%eax
80109278:	84 c0                	test   %al,%al
8010927a:	74 41                	je     801092bd <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
8010927c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010927f:	8b 00                	mov    (%eax),%eax
80109281:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109286:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80109289:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010928d:	75 0c                	jne    8010929b <deallocuvm+0x82>
        panic("kfree");
8010928f:	c7 04 24 05 9d 10 80 	movl   $0x80109d05,(%esp)
80109296:	e8 a2 72 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
8010929b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010929e:	89 04 24             	mov    %eax,(%esp)
801092a1:	e8 1a f5 ff ff       	call   801087c0 <p2v>
801092a6:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801092a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092ac:	89 04 24             	mov    %eax,(%esp)
801092af:	e8 16 aa ff ff       	call   80103cca <kfree>
      *pte = 0;
801092b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092b7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801092bd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801092c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092c7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801092ca:	0f 82 74 ff ff ff    	jb     80109244 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801092d0:	8b 45 10             	mov    0x10(%ebp),%eax
}
801092d3:	c9                   	leave  
801092d4:	c3                   	ret    

801092d5 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801092d5:	55                   	push   %ebp
801092d6:	89 e5                	mov    %esp,%ebp
801092d8:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801092db:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801092df:	75 0c                	jne    801092ed <freevm+0x18>
    panic("freevm: no pgdir");
801092e1:	c7 04 24 0b 9d 10 80 	movl   $0x80109d0b,(%esp)
801092e8:	e8 50 72 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801092ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092f4:	00 
801092f5:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801092fc:	80 
801092fd:	8b 45 08             	mov    0x8(%ebp),%eax
80109300:	89 04 24             	mov    %eax,(%esp)
80109303:	e8 11 ff ff ff       	call   80109219 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109308:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010930f:	eb 3c                	jmp    8010934d <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109311:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109314:	c1 e0 02             	shl    $0x2,%eax
80109317:	03 45 08             	add    0x8(%ebp),%eax
8010931a:	8b 00                	mov    (%eax),%eax
8010931c:	83 e0 01             	and    $0x1,%eax
8010931f:	84 c0                	test   %al,%al
80109321:	74 26                	je     80109349 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109326:	c1 e0 02             	shl    $0x2,%eax
80109329:	03 45 08             	add    0x8(%ebp),%eax
8010932c:	8b 00                	mov    (%eax),%eax
8010932e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109333:	89 04 24             	mov    %eax,(%esp)
80109336:	e8 85 f4 ff ff       	call   801087c0 <p2v>
8010933b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
8010933e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109341:	89 04 24             	mov    %eax,(%esp)
80109344:	e8 81 a9 ff ff       	call   80103cca <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80109349:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010934d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109354:	76 bb                	jbe    80109311 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80109356:	8b 45 08             	mov    0x8(%ebp),%eax
80109359:	89 04 24             	mov    %eax,(%esp)
8010935c:	e8 69 a9 ff ff       	call   80103cca <kfree>
}
80109361:	c9                   	leave  
80109362:	c3                   	ret    

80109363 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109363:	55                   	push   %ebp
80109364:	89 e5                	mov    %esp,%ebp
80109366:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109369:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109370:	00 
80109371:	8b 45 0c             	mov    0xc(%ebp),%eax
80109374:	89 44 24 04          	mov    %eax,0x4(%esp)
80109378:	8b 45 08             	mov    0x8(%ebp),%eax
8010937b:	89 04 24             	mov    %eax,(%esp)
8010937e:	e8 c0 f8 ff ff       	call   80108c43 <walkpgdir>
80109383:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80109386:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010938a:	75 0c                	jne    80109398 <clearpteu+0x35>
    panic("clearpteu");
8010938c:	c7 04 24 1c 9d 10 80 	movl   $0x80109d1c,(%esp)
80109393:	e8 a5 71 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80109398:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010939b:	8b 00                	mov    (%eax),%eax
8010939d:	89 c2                	mov    %eax,%edx
8010939f:	83 e2 fb             	and    $0xfffffffb,%edx
801093a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093a5:	89 10                	mov    %edx,(%eax)
}
801093a7:	c9                   	leave  
801093a8:	c3                   	ret    

801093a9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801093a9:	55                   	push   %ebp
801093aa:	89 e5                	mov    %esp,%ebp
801093ac:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801093af:	e8 b9 f9 ff ff       	call   80108d6d <setupkvm>
801093b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801093b7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801093bb:	75 0a                	jne    801093c7 <copyuvm+0x1e>
    return 0;
801093bd:	b8 00 00 00 00       	mov    $0x0,%eax
801093c2:	e9 f1 00 00 00       	jmp    801094b8 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801093c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801093ce:	e9 c0 00 00 00       	jmp    80109493 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801093d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093d6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801093dd:	00 
801093de:	89 44 24 04          	mov    %eax,0x4(%esp)
801093e2:	8b 45 08             	mov    0x8(%ebp),%eax
801093e5:	89 04 24             	mov    %eax,(%esp)
801093e8:	e8 56 f8 ff ff       	call   80108c43 <walkpgdir>
801093ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
801093f0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801093f4:	75 0c                	jne    80109402 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801093f6:	c7 04 24 26 9d 10 80 	movl   $0x80109d26,(%esp)
801093fd:	e8 3b 71 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109402:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109405:	8b 00                	mov    (%eax),%eax
80109407:	83 e0 01             	and    $0x1,%eax
8010940a:	85 c0                	test   %eax,%eax
8010940c:	75 0c                	jne    8010941a <copyuvm+0x71>
      panic("copyuvm: page not present");
8010940e:	c7 04 24 40 9d 10 80 	movl   $0x80109d40,(%esp)
80109415:	e8 23 71 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010941a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010941d:	8b 00                	mov    (%eax),%eax
8010941f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109424:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109427:	e8 37 a9 ff ff       	call   80103d63 <kalloc>
8010942c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010942f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109433:	74 6f                	je     801094a4 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109435:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109438:	89 04 24             	mov    %eax,(%esp)
8010943b:	e8 80 f3 ff ff       	call   801087c0 <p2v>
80109440:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109447:	00 
80109448:	89 44 24 04          	mov    %eax,0x4(%esp)
8010944c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010944f:	89 04 24             	mov    %eax,(%esp)
80109452:	e8 d2 cc ff ff       	call   80106129 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109457:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010945a:	89 04 24             	mov    %eax,(%esp)
8010945d:	e8 51 f3 ff ff       	call   801087b3 <v2p>
80109462:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109465:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010946c:	00 
8010946d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109471:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109478:	00 
80109479:	89 54 24 04          	mov    %edx,0x4(%esp)
8010947d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109480:	89 04 24             	mov    %eax,(%esp)
80109483:	e8 51 f8 ff ff       	call   80108cd9 <mappages>
80109488:	85 c0                	test   %eax,%eax
8010948a:	78 1b                	js     801094a7 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010948c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109496:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109499:	0f 82 34 ff ff ff    	jb     801093d3 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010949f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094a2:	eb 14                	jmp    801094b8 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801094a4:	90                   	nop
801094a5:	eb 01                	jmp    801094a8 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801094a7:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801094a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094ab:	89 04 24             	mov    %eax,(%esp)
801094ae:	e8 22 fe ff ff       	call   801092d5 <freevm>
  return 0;
801094b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801094b8:	c9                   	leave  
801094b9:	c3                   	ret    

801094ba <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801094ba:	55                   	push   %ebp
801094bb:	89 e5                	mov    %esp,%ebp
801094bd:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801094c0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094c7:	00 
801094c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801094cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801094cf:	8b 45 08             	mov    0x8(%ebp),%eax
801094d2:	89 04 24             	mov    %eax,(%esp)
801094d5:	e8 69 f7 ff ff       	call   80108c43 <walkpgdir>
801094da:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801094dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094e0:	8b 00                	mov    (%eax),%eax
801094e2:	83 e0 01             	and    $0x1,%eax
801094e5:	85 c0                	test   %eax,%eax
801094e7:	75 07                	jne    801094f0 <uva2ka+0x36>
    return 0;
801094e9:	b8 00 00 00 00       	mov    $0x0,%eax
801094ee:	eb 25                	jmp    80109515 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801094f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094f3:	8b 00                	mov    (%eax),%eax
801094f5:	83 e0 04             	and    $0x4,%eax
801094f8:	85 c0                	test   %eax,%eax
801094fa:	75 07                	jne    80109503 <uva2ka+0x49>
    return 0;
801094fc:	b8 00 00 00 00       	mov    $0x0,%eax
80109501:	eb 12                	jmp    80109515 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109506:	8b 00                	mov    (%eax),%eax
80109508:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010950d:	89 04 24             	mov    %eax,(%esp)
80109510:	e8 ab f2 ff ff       	call   801087c0 <p2v>
}
80109515:	c9                   	leave  
80109516:	c3                   	ret    

80109517 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109517:	55                   	push   %ebp
80109518:	89 e5                	mov    %esp,%ebp
8010951a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010951d:	8b 45 10             	mov    0x10(%ebp),%eax
80109520:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109523:	e9 8b 00 00 00       	jmp    801095b3 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109528:	8b 45 0c             	mov    0xc(%ebp),%eax
8010952b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109530:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109533:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109536:	89 44 24 04          	mov    %eax,0x4(%esp)
8010953a:	8b 45 08             	mov    0x8(%ebp),%eax
8010953d:	89 04 24             	mov    %eax,(%esp)
80109540:	e8 75 ff ff ff       	call   801094ba <uva2ka>
80109545:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109548:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010954c:	75 07                	jne    80109555 <copyout+0x3e>
      return -1;
8010954e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109553:	eb 6d                	jmp    801095c2 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109555:	8b 45 0c             	mov    0xc(%ebp),%eax
80109558:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010955b:	89 d1                	mov    %edx,%ecx
8010955d:	29 c1                	sub    %eax,%ecx
8010955f:	89 c8                	mov    %ecx,%eax
80109561:	05 00 10 00 00       	add    $0x1000,%eax
80109566:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109569:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010956c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010956f:	76 06                	jbe    80109577 <copyout+0x60>
      n = len;
80109571:	8b 45 14             	mov    0x14(%ebp),%eax
80109574:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109577:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010957a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010957d:	89 d1                	mov    %edx,%ecx
8010957f:	29 c1                	sub    %eax,%ecx
80109581:	89 c8                	mov    %ecx,%eax
80109583:	03 45 e8             	add    -0x18(%ebp),%eax
80109586:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109589:	89 54 24 08          	mov    %edx,0x8(%esp)
8010958d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109590:	89 54 24 04          	mov    %edx,0x4(%esp)
80109594:	89 04 24             	mov    %eax,(%esp)
80109597:	e8 8d cb ff ff       	call   80106129 <memmove>
    len -= n;
8010959c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010959f:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801095a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095a5:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801095a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801095ab:	05 00 10 00 00       	add    $0x1000,%eax
801095b0:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801095b3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801095b7:	0f 85 6b ff ff ff    	jne    80109528 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801095bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801095c2:	c9                   	leave  
801095c3:	c3                   	ret    

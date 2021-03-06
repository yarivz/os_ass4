
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
8010002d:	b8 3f 47 10 80       	mov    $0x8010473f,%eax
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
8010003a:	c7 44 24 04 98 96 10 	movl   $0x80109698,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 6c 5e 00 00       	call   80105eba <initlock>

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
801000bd:	e8 19 5e 00 00       	call   80105edb <acquire>

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
80100104:	e8 34 5e 00 00       	call   80105f3d <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 d9 5a 00 00       	call   80105bfd <sleep>
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
8010017c:	e8 bc 5d 00 00       	call   80105f3d <release>
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
80100198:	c7 04 24 9f 96 10 80 	movl   $0x8010969f,(%esp)
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
801001d3:	e8 14 39 00 00       	call   80103aec <iderw>
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
801001ef:	c7 04 24 b0 96 10 80 	movl   $0x801096b0,(%esp)
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
80100210:	e8 d7 38 00 00       	call   80103aec <iderw>
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
80100229:	c7 04 24 b7 96 10 80 	movl   $0x801096b7,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 9a 5c 00 00       	call   80105edb <acquire>

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
8010029d:	e8 34 5a 00 00       	call   80105cd6 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 8f 5c 00 00       	call   80105f3d <release>
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
801003bc:	e8 1a 5b 00 00       	call   80105edb <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 be 96 10 80 	movl   $0x801096be,(%esp)
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
801004af:	c7 45 ec c7 96 10 80 	movl   $0x801096c7,-0x14(%ebp)
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
80100536:	e8 02 5a 00 00       	call   80105f3d <release>
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
80100562:	c7 04 24 ce 96 10 80 	movl   $0x801096ce,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 dd 96 10 80 	movl   $0x801096dd,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 f5 59 00 00       	call   80105f8c <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 df 96 10 80 	movl   $0x801096df,(%esp)
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
801006b2:	e8 46 5b 00 00       	call   801061fd <memmove>
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
801006e1:	e8 44 5a 00 00       	call   8010612a <memset>
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
80100776:	e8 82 75 00 00       	call   80107cfd <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 76 75 00 00       	call   80107cfd <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 6a 75 00 00       	call   80107cfd <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 5d 75 00 00       	call   80107cfd <uartputc>
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
801007ba:	e8 1c 57 00 00       	call   80105edb <acquire>
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
801007ea:	e8 8a 55 00 00       	call   80105d79 <procdump>
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
801008f7:	e8 da 53 00 00       	call   80105cd6 <wakeup>
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
8010091e:	e8 1a 56 00 00       	call   80105f3d <release>
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
80100931:	e8 f4 1e 00 00       	call   8010282a <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 93 55 00 00       	call   80105edb <acquire>
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
80100961:	e8 d7 55 00 00       	call   80105f3d <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 6b 1d 00 00       	call   801026dc <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 6e 52 00 00       	call   80105bfd <sleep>
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
80100a08:	e8 30 55 00 00       	call   80105f3d <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 c4 1c 00 00       	call   801026dc <ilock>

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
80100a32:	e8 f3 1d 00 00       	call   8010282a <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 98 54 00 00       	call   80105edb <acquire>
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
80100a78:	e8 c0 54 00 00       	call   80105f3d <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 54 1c 00 00       	call   801026dc <ilock>

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
80100a93:	c7 44 24 04 e3 96 10 	movl   $0x801096e3,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 13 54 00 00       	call   80105eba <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 eb 96 10 	movl   $0x801096eb,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 ff 53 00 00       	call   80105eba <initlock>

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
80100ae0:	e8 14 43 00 00       	call   80104df9 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 b5 31 00 00       	call   80103cae <ioapicenable>
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
80100b0b:	e8 a6 28 00 00       	call   801033b6 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 ae 1b 00 00       	call   801026dc <ilock>
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
80100b55:	e8 e8 20 00 00       	call   80102c42 <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 37 3e 10 80 	movl   $0x80103e37,(%esp)
80100b7b:	e8 c1 82 00 00       	call   80108e41 <setupkvm>
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
80100bc8:	e8 75 20 00 00       	call   80102c42 <readi>
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
80100c14:	e8 fa 85 00 00       	call   80109213 <allocuvm>
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
80100c51:	e8 ce 84 00 00       	call   80109124 <loaduvm>
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
80100c87:	e8 d4 1c 00 00       	call   80102960 <iunlockput>
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
80100cbc:	e8 52 85 00 00       	call   80109213 <allocuvm>
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
80100ce0:	e8 52 87 00 00       	call   80109437 <clearpteu>
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
80100d0f:	e8 94 56 00 00       	call   801063a8 <strlen>
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
80100d2d:	e8 76 56 00 00       	call   801063a8 <strlen>
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
80100d57:	e8 8f 88 00 00       	call   801095eb <copyout>
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
80100df7:	e8 ef 87 00 00       	call   801095eb <copyout>
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
80100e4e:	e8 07 55 00 00       	call   8010635a <safestrcpy>

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
80100ea0:	e8 8d 80 00 00       	call   80108f32 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 f9 84 00 00       	call   801093a9 <freevm>
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
80100ee2:	e8 c2 84 00 00       	call   801093a9 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 68 1a 00 00       	call   80102960 <iunlockput>
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
80100f06:	c7 44 24 04 f4 96 10 	movl   $0x801096f4,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f15:	e8 a0 4f 00 00       	call   80105eba <initlock>
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
80100f29:	e8 ad 4f 00 00       	call   80105edb <acquire>
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
80100f52:	e8 e6 4f 00 00       	call   80105f3d <release>
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
80100f70:	e8 c8 4f 00 00       	call   80105f3d <release>
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
80100f89:	e8 4d 4f 00 00       	call   80105edb <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 fb 96 10 80 	movl   $0x801096fb,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fba:	e8 7e 4f 00 00       	call   80105f3d <release>
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
80100fd1:	e8 05 4f 00 00       	call   80105edb <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 03 97 10 80 	movl   $0x80109703,(%esp)
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
8010100c:	e8 2c 4f 00 00       	call   80105f3d <release>
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
80101056:	e8 e2 4e 00 00       	call   80105f3d <release>
  
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
80101074:	e8 3a 40 00 00       	call   801050b3 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 cd 34 00 00       	call   80104555 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 fc 17 00 00       	call   8010288f <iput>
    commit_trans();
80101093:	e8 06 35 00 00       	call   8010459e <commit_trans>
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
801010b3:	e8 24 16 00 00       	call   801026dc <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 30 1b 00 00       	call   80102bfd <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 4f 17 00 00       	call   8010282a <iunlock>
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
80101125:	e8 0b 41 00 00       	call   80105235 <piperead>
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
8010113f:	e8 98 15 00 00       	call   801026dc <ilock>
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
80101165:	e8 d8 1a 00 00       	call   80102c42 <readi>
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
8010118d:	e8 98 16 00 00       	call   8010282a <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 0d 97 10 80 	movl   $0x8010970d,(%esp)
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
801011e2:	e8 5e 3f 00 00       	call   80105145 <pipewrite>
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
8010122a:	e8 26 33 00 00       	call   80104555 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 9f 14 00 00       	call   801026dc <ilock>
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
80101263:	e8 45 1b 00 00       	call   80102dad <writei>
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
8010128b:	e8 9a 15 00 00       	call   8010282a <iunlock>
      commit_trans();
80101290:	e8 09 33 00 00       	call   8010459e <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 16 97 10 80 	movl   $0x80109716,(%esp)
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
801012d8:	c7 04 24 26 97 10 80 	movl   $0x80109726,(%esp)
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
801012fe:	e8 56 5b 00 00       	call   80106e59 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 30 97 10 80 	movl   $0x80109730,(%esp)
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
80101338:	e8 9f 13 00 00       	call   801026dc <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 48 97 10 80 	movl   $0x80109748,(%esp)
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
80101382:	c7 04 24 6b 97 10 80 	movl   $0x8010976b,(%esp)
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
801013b7:	c7 04 24 84 97 10 80 	movl   $0x80109784,(%esp)
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
80101414:	c7 04 24 a3 97 10 80 	movl   $0x801097a3,(%esp)
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
8010143b:	e8 ea 13 00 00       	call   8010282a <iunlock>
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
8010145c:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010145f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101463:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010146a:	e8 f1 0c 00 00       	call   80102160 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010146f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101476:	e9 ae 00 00 00       	jmp    80101529 <getFreeBlocks+0xe2>
    bp = bread(1, BBLOCK(b, sb.ninodes));
8010147b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010147e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101484:	85 c0                	test   %eax,%eax
80101486:	0f 48 c2             	cmovs  %edx,%eax
80101489:	c1 f8 0c             	sar    $0xc,%eax
8010148c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
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
80101510:	8b 45 cc             	mov    -0x34(%ebp),%eax
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
8010152c:	8b 45 cc             	mov    -0x34(%ebp),%eax
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
8010162b:	e8 75 1f 00 00       	call   801035a5 <updateBlkRef>
  int ref = getBlkRef(b1->sector);
80101630:	8b 45 10             	mov    0x10(%ebp),%eax
80101633:	8b 40 08             	mov    0x8(%eax),%eax
80101636:	89 04 24             	mov    %eax,(%esp)
80101639:	e8 a6 20 00 00       	call   801036e4 <getBlkRef>
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
80101658:	e8 48 1f 00 00       	call   801035a5 <updateBlkRef>
8010165d:	eb 28                	jmp    80101687 <deletedups+0xff>
  else if(ref == 0)
8010165f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101663:	75 22                	jne    80101687 <deletedups+0xff>
  {
    begin_trans();
80101665:	e8 eb 2e 00 00       	call   80104555 <begin_trans>
    bfree(b1->dev, b1->sector);
8010166a:	8b 45 10             	mov    0x10(%ebp),%eax
8010166d:	8b 50 08             	mov    0x8(%eax),%edx
80101670:	8b 45 10             	mov    0x10(%ebp),%eax
80101673:	8b 40 04             	mov    0x4(%eax),%eax
80101676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010167a:	89 04 24             	mov    %eax,(%esp)
8010167d:	e8 cc 0c 00 00       	call   8010234e <bfree>
    commit_trans();
80101682:	e8 17 2f 00 00       	call   8010459e <commit_trans>
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
8010168c:	81 ec 98 00 00 00    	sub    $0x98,%esp
  cprintf("\nstarting de-duplication: \n");
80101692:	c7 04 24 bc 97 10 80 	movl   $0x801097bc,(%esp)
80101699:	e8 03 ed ff ff       	call   801003a1 <cprintf>
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0;
8010169e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
801016a5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
801016ac:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016b3:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
801016ba:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  struct inode* ip1=0, *ip2=0;
801016c1:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
801016c8:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
801016cf:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
801016d6:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
801016dd:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
801016e4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  uint *a = 0, *b = 0;
801016eb:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
801016f2:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  struct superblock sb;
  readsb(1, &sb);
801016f9:	8d 45 90             	lea    -0x70(%ebp),%eax
801016fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80101700:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101707:	e8 54 0a 00 00       	call   80102160 <readsb>
  ninodes = sb.ninodes;
8010170c:	8b 45 98             	mov    -0x68(%ebp),%eax
8010170f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  zeroNextInum();
80101712:	e8 60 20 00 00       	call   80103777 <zeroNextInum>
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101717:	e9 a9 07 00 00       	jmp    80101ec5 <dedup+0x83c>
  {  
    cprintf("*\n");
8010171c:	c7 04 24 d8 97 10 80 	movl   $0x801097d8,(%esp)
80101723:	e8 79 ec ff ff       	call   801003a1 <cprintf>
    indirects1=0;
80101728:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
    directChanged = 0;
8010172f:	c7 05 80 ee 10 80 00 	movl   $0x0,0x8010ee80
80101736:	00 00 00 
    indirectChanged = 0;
80101739:	c7 05 90 f8 10 80 00 	movl   $0x0,0x8010f890
80101740:	00 00 00 
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
80101743:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101746:	89 04 24             	mov    %eax,(%esp)
80101749:	e8 8e 0f 00 00       	call   801026dc <ilock>
    if(ip1->addrs[NDIRECT])
8010174e:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101751:	8b 40 4c             	mov    0x4c(%eax),%eax
80101754:	85 c0                	test   %eax,%eax
80101756:	74 2a                	je     80101782 <dedup+0xf9>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
80101758:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010175b:	8b 50 4c             	mov    0x4c(%eax),%edx
8010175e:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101761:	8b 00                	mov    (%eax),%eax
80101763:	89 54 24 04          	mov    %edx,0x4(%esp)
80101767:	89 04 24             	mov    %eax,(%esp)
8010176a:	e8 37 ea ff ff       	call   801001a6 <bread>
8010176f:	89 45 dc             	mov    %eax,-0x24(%ebp)
      a = (uint*)bp1->data;
80101772:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101775:	83 c0 18             	add    $0x18,%eax
80101778:	89 45 d4             	mov    %eax,-0x2c(%ebp)
      indirects1 = NINDIRECT;
8010177b:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101782:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101789:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101790:	e9 cf 06 00 00       	jmp    80101e64 <dedup+0x7db>
    {
      if(blockIndex1<NDIRECT)							// in the same file
80101795:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101799:	0f 8f 5d 02 00 00    	jg     801019fc <dedup+0x373>
      {
	if(ip1->addrs[blockIndex1])
8010179f:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017a5:	83 c2 04             	add    $0x4,%edx
801017a8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017ac:	85 c0                	test   %eax,%eax
801017ae:	0f 84 3c 02 00 00    	je     801019f0 <dedup+0x367>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
801017b4:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017ba:	83 c2 04             	add    $0x4,%edx
801017bd:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017c1:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017c4:	8b 00                	mov    (%eax),%eax
801017c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ca:	89 04 24             	mov    %eax,(%esp)
801017cd:	e8 d4 e9 ff ff       	call   801001a6 <bread>
801017d2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801017d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017d8:	83 c0 0b             	add    $0xb,%eax
801017db:	89 45 f0             	mov    %eax,-0x10(%ebp)
801017de:	e9 fc 01 00 00       	jmp    801019df <dedup+0x356>
	  {
	    if(blockIndex2 < NDIRECT)
801017e3:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
801017e7:	0f 8f f3 00 00 00    	jg     801018e0 <dedup+0x257>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2] && ip1->addrs[blockIndex1] != ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
801017ed:	8b 45 c0             	mov    -0x40(%ebp),%eax
801017f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017f3:	83 c2 04             	add    $0x4,%edx
801017f6:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017fa:	85 c0                	test   %eax,%eax
801017fc:	0f 84 d9 01 00 00    	je     801019db <dedup+0x352>
80101802:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101805:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101808:	83 c2 04             	add    $0x4,%edx
8010180b:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010180f:	85 c0                	test   %eax,%eax
80101811:	0f 84 c4 01 00 00    	je     801019db <dedup+0x352>
80101817:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010181a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010181d:	83 c2 04             	add    $0x4,%edx
80101820:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101824:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101827:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010182a:	83 c1 04             	add    $0x4,%ecx
8010182d:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101831:	39 c2                	cmp    %eax,%edx
80101833:	0f 84 a2 01 00 00    	je     801019db <dedup+0x352>
	      {
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
80101839:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010183c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010183f:	83 c2 04             	add    $0x4,%edx
80101842:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101846:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101849:	8b 00                	mov    (%eax),%eax
8010184b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010184f:	89 04 24             	mov    %eax,(%esp)
80101852:	e8 4f e9 ff ff       	call   801001a6 <bread>
80101857:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
8010185a:	8b 45 b8             	mov    -0x48(%ebp),%eax
8010185d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101861:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101864:	89 04 24             	mov    %eax,(%esp)
80101867:	e8 d4 fc ff ff       	call   80101540 <blkcmp>
8010186c:	85 c0                	test   %eax,%eax
8010186e:	74 60                	je     801018d0 <dedup+0x247>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
80101870:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101877:	00 
80101878:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
8010187f:	00 
80101880:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101883:	89 44 24 14          	mov    %eax,0x14(%esp)
80101887:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010188a:	89 44 24 10          	mov    %eax,0x10(%esp)
8010188e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101891:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101895:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101898:	89 44 24 08          	mov    %eax,0x8(%esp)
8010189c:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010189f:	89 44 24 04          	mov    %eax,0x4(%esp)
801018a3:	8b 45 c0             	mov    -0x40(%ebp),%eax
801018a6:	89 04 24             	mov    %eax,(%esp)
801018a9:	e8 da fc ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
801018ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801018b1:	89 04 24             	mov    %eax,(%esp)
801018b4:	e8 5e e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801018b9:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018bc:	89 04 24             	mov    %eax,(%esp)
801018bf:	e8 53 e9 ff ff       	call   80100217 <brelse>
		  found = 1;
801018c4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801018cb:	e9 7c 02 00 00       	jmp    80101b4c <dedup+0x4c3>
		}
		brelse(b2);
801018d0:	8b 45 b8             	mov    -0x48(%ebp),%eax
801018d3:	89 04 24             	mov    %eax,(%esp)
801018d6:	e8 3c e9 ff ff       	call   80100217 <brelse>
801018db:	e9 fb 00 00 00       	jmp    801019db <dedup+0x352>
	      }
	    }
	    else if(a)
801018e0:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801018e4:	0f 84 f1 00 00 00    	je     801019db <dedup+0x352>
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
801018ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018ed:	83 e8 0c             	sub    $0xc,%eax
801018f0:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset] && ip1->addrs[blockIndex1] != a[blockIndex2Offset])
801018f3:	8b 45 c0             	mov    -0x40(%ebp),%eax
801018f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801018f9:	83 c2 04             	add    $0x4,%edx
801018fc:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101900:	85 c0                	test   %eax,%eax
80101902:	0f 84 d3 00 00 00    	je     801019db <dedup+0x352>
80101908:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010190b:	c1 e0 02             	shl    $0x2,%eax
8010190e:	03 45 d4             	add    -0x2c(%ebp),%eax
80101911:	8b 00                	mov    (%eax),%eax
80101913:	85 c0                	test   %eax,%eax
80101915:	0f 84 c0 00 00 00    	je     801019db <dedup+0x352>
8010191b:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010191e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101921:	83 c2 04             	add    $0x4,%edx
80101924:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101928:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010192b:	c1 e0 02             	shl    $0x2,%eax
8010192e:	03 45 d4             	add    -0x2c(%ebp),%eax
80101931:	8b 00                	mov    (%eax),%eax
80101933:	39 c2                	cmp    %eax,%edx
80101935:	0f 84 a0 00 00 00    	je     801019db <dedup+0x352>
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);
8010193b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010193e:	c1 e0 02             	shl    $0x2,%eax
80101941:	03 45 d4             	add    -0x2c(%ebp),%eax
80101944:	8b 10                	mov    (%eax),%edx
80101946:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101949:	8b 00                	mov    (%eax),%eax
8010194b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010194f:	89 04 24             	mov    %eax,(%esp)
80101952:	e8 4f e8 ff ff       	call   801001a6 <bread>
80101957:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
8010195a:	8b 45 b8             	mov    -0x48(%ebp),%eax
8010195d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101961:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101964:	89 04 24             	mov    %eax,(%esp)
80101967:	e8 d4 fb ff ff       	call   80101540 <blkcmp>
8010196c:	85 c0                	test   %eax,%eax
8010196e:	74 60                	je     801019d0 <dedup+0x347>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
80101970:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101973:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101977:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
8010197e:	00 
8010197f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101982:	89 44 24 14          	mov    %eax,0x14(%esp)
80101986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101989:	89 44 24 10          	mov    %eax,0x10(%esp)
8010198d:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101990:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101994:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101997:	89 44 24 08          	mov    %eax,0x8(%esp)
8010199b:	8b 45 c0             	mov    -0x40(%ebp),%eax
8010199e:	89 44 24 04          	mov    %eax,0x4(%esp)
801019a2:	8b 45 c0             	mov    -0x40(%ebp),%eax
801019a5:	89 04 24             	mov    %eax,(%esp)
801019a8:	e8 db fb ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
801019ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
801019b0:	89 04 24             	mov    %eax,(%esp)
801019b3:	e8 5f e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
801019b8:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019bb:	89 04 24             	mov    %eax,(%esp)
801019be:	e8 54 e8 ff ff       	call   80100217 <brelse>
		  found = 1;
801019c3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
801019ca:	90                   	nop
801019cb:	e9 7c 01 00 00       	jmp    80101b4c <dedup+0x4c3>
		}
		brelse(b2);
801019d0:	8b 45 b8             	mov    -0x48(%ebp),%eax
801019d3:	89 04 24             	mov    %eax,(%esp)
801019d6:	e8 3c e8 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801019db:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
801019df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019e2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801019e5:	0f 8f f8 fd ff ff    	jg     801017e3 <dedup+0x15a>
801019eb:	e9 5c 01 00 00       	jmp    80101b4c <dedup+0x4c3>
	      
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{
	  b1 = 0;
801019f0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	  continue;
801019f7:	e9 5d 04 00 00       	jmp    80101e59 <dedup+0x7d0>
	}
      }
	
      else if(!found)					// in the same file
801019fc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101a00:	0f 85 46 01 00 00    	jne    80101b4c <dedup+0x4c3>
      {
	if(a)
80101a06:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101a0a:	0f 84 3c 01 00 00    	je     80101b4c <dedup+0x4c3>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
80101a10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a13:	83 e8 0c             	sub    $0xc,%eax
80101a16:	89 45 b0             	mov    %eax,-0x50(%ebp)
	  if(a[blockIndex1Offset])
80101a19:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a1c:	c1 e0 02             	shl    $0x2,%eax
80101a1f:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a22:	8b 00                	mov    (%eax),%eax
80101a24:	85 c0                	test   %eax,%eax
80101a26:	0f 84 14 01 00 00    	je     80101b40 <dedup+0x4b7>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
80101a2c:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a2f:	c1 e0 02             	shl    $0x2,%eax
80101a32:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a35:	8b 10                	mov    (%eax),%edx
80101a37:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101a3a:	8b 00                	mov    (%eax),%eax
80101a3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a40:	89 04 24             	mov    %eax,(%esp)
80101a43:	e8 5e e7 ff ff       	call   801001a6 <bread>
80101a48:	89 45 e0             	mov    %eax,-0x20(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101a4b:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
80101a52:	e9 db 00 00 00       	jmp    80101b32 <dedup+0x4a9>
	    {
	      if(a[blockIndex2] && a[blockIndex2] != a[blockIndex1Offset])
80101a57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a5a:	c1 e0 02             	shl    $0x2,%eax
80101a5d:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a60:	8b 00                	mov    (%eax),%eax
80101a62:	85 c0                	test   %eax,%eax
80101a64:	0f 84 c4 00 00 00    	je     80101b2e <dedup+0x4a5>
80101a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a6d:	c1 e0 02             	shl    $0x2,%eax
80101a70:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a73:	8b 10                	mov    (%eax),%edx
80101a75:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a78:	c1 e0 02             	shl    $0x2,%eax
80101a7b:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a7e:	8b 00                	mov    (%eax),%eax
80101a80:	39 c2                	cmp    %eax,%edx
80101a82:	0f 84 a6 00 00 00    	je     80101b2e <dedup+0x4a5>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);
80101a88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a8b:	c1 e0 02             	shl    $0x2,%eax
80101a8e:	03 45 d4             	add    -0x2c(%ebp),%eax
80101a91:	8b 10                	mov    (%eax),%edx
80101a93:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101a96:	8b 00                	mov    (%eax),%eax
80101a98:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a9c:	89 04 24             	mov    %eax,(%esp)
80101a9f:	e8 02 e7 ff ff       	call   801001a6 <bread>
80101aa4:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101aa7:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101aaa:	89 44 24 04          	mov    %eax,0x4(%esp)
80101aae:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101ab1:	89 04 24             	mov    %eax,(%esp)
80101ab4:	e8 87 fa ff ff       	call   80101540 <blkcmp>
80101ab9:	85 c0                	test   %eax,%eax
80101abb:	74 66                	je     80101b23 <dedup+0x49a>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101abd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101ac0:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101ac4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101ac7:	89 44 24 18          	mov    %eax,0x18(%esp)
80101acb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ace:	89 44 24 14          	mov    %eax,0x14(%esp)
80101ad2:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101ad5:	89 44 24 10          	mov    %eax,0x10(%esp)
80101ad9:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101adc:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101ae3:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ae7:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101aea:	89 44 24 04          	mov    %eax,0x4(%esp)
80101aee:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101af1:	89 04 24             	mov    %eax,(%esp)
80101af4:	e8 8f fa ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101af9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101afc:	89 04 24             	mov    %eax,(%esp)
80101aff:	e8 13 e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101b04:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b07:	89 04 24             	mov    %eax,(%esp)
80101b0a:	e8 08 e7 ff ff       	call   80100217 <brelse>
		  found = 1;
80101b0f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  indirectChanged = 1;
80101b16:	c7 05 90 f8 10 80 01 	movl   $0x1,0x8010f890
80101b1d:	00 00 00 
		  break;
80101b20:	90                   	nop
80101b21:	eb 29                	jmp    80101b4c <dedup+0x4c3>
		}
		brelse(b2);
80101b23:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b26:	89 04 24             	mov    %eax,(%esp)
80101b29:	e8 e9 e6 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101b2e:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b35:	3b 45 b0             	cmp    -0x50(%ebp),%eax
80101b38:	0f 8f 19 ff ff ff    	jg     80101a57 <dedup+0x3ce>
80101b3e:	eb 0c                	jmp    80101b4c <dedup+0x4c3>
	      }
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    b1 = 0;
80101b40:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	    continue;
80101b47:	e9 0d 03 00 00       	jmp    80101e59 <dedup+0x7d0>
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101b4c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101b50:	0f 85 f2 02 00 00    	jne    80101e48 <dedup+0x7bf>
80101b56:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b5a:	0f 84 e8 02 00 00    	je     80101e48 <dedup+0x7bf>
      {
	uint* aSub = 0;
80101b60:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	int blockIndex1Offset = blockIndex1;
80101b67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b6a:	89 45 c8             	mov    %eax,-0x38(%ebp)
	if(blockIndex1 >= NDIRECT)
80101b6d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101b71:	7e 0f                	jle    80101b82 <dedup+0x4f9>
	{
	  aSub = a;
80101b73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101b76:	89 45 cc             	mov    %eax,-0x34(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b7c:	83 e8 0c             	sub    $0xc,%eax
80101b7f:	89 45 c8             	mov    %eax,-0x38(%ebp)
	}
	prevInum = ninodes-1;
80101b82:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101b85:	83 e8 01             	sub    $0x1,%eax
80101b88:	89 45 a8             	mov    %eax,-0x58(%ebp)
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101b8b:	e9 9a 02 00 00       	jmp    80101e2a <dedup+0x7a1>
	{
	  indirects2=0;
80101b90:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	  ilock(ip2);
80101b97:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b9a:	89 04 24             	mov    %eax,(%esp)
80101b9d:	e8 3a 0b 00 00       	call   801026dc <ilock>
	  if(ip2->addrs[NDIRECT])
80101ba2:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101ba5:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ba8:	85 c0                	test   %eax,%eax
80101baa:	74 2a                	je     80101bd6 <dedup+0x54d>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101bac:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101baf:	8b 50 4c             	mov    0x4c(%eax),%edx
80101bb2:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bb5:	8b 00                	mov    (%eax),%eax
80101bb7:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bbb:	89 04 24             	mov    %eax,(%esp)
80101bbe:	e8 e3 e5 ff ff       	call   801001a6 <bread>
80101bc3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	    b = (uint*)bp2->data;
80101bc6:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101bc9:	83 c0 18             	add    $0x18,%eax
80101bcc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	    indirects2 = NINDIRECT;
80101bcf:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101bd6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101bd9:	83 c0 0b             	add    $0xb,%eax
80101bdc:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101bdf:	e9 1c 02 00 00       	jmp    80101e00 <dedup+0x777>
	  {
	    if(blockIndex2<NDIRECT)
80101be4:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101be8:	0f 8f 03 01 00 00    	jg     80101cf1 <dedup+0x668>
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
80101bee:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101bf2:	74 20                	je     80101c14 <dedup+0x58b>
80101bf4:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101bf7:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101bfa:	83 c2 04             	add    $0x4,%edx
80101bfd:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c01:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c04:	c1 e0 02             	shl    $0x2,%eax
80101c07:	03 45 cc             	add    -0x34(%ebp),%eax
80101c0a:	8b 00                	mov    (%eax),%eax
80101c0c:	39 c2                	cmp    %eax,%edx
80101c0e:	0f 84 e4 01 00 00    	je     80101df8 <dedup+0x76f>
80101c14:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c17:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c1a:	83 c2 04             	add    $0x4,%edx
80101c1d:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c21:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101c24:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101c27:	83 c1 04             	add    $0x4,%ecx
80101c2a:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101c2e:	39 c2                	cmp    %eax,%edx
80101c30:	0f 84 c2 01 00 00    	je     80101df8 <dedup+0x76f>
		continue;
	      if(ip2->addrs[blockIndex2])
80101c36:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c39:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c3c:	83 c2 04             	add    $0x4,%edx
80101c3f:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c43:	85 c0                	test   %eax,%eax
80101c45:	0f 84 b1 01 00 00    	je     80101dfc <dedup+0x773>
	      {
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);
80101c4b:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c4e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101c51:	83 c2 04             	add    $0x4,%edx
80101c54:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c58:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c5b:	8b 00                	mov    (%eax),%eax
80101c5d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c61:	89 04 24             	mov    %eax,(%esp)
80101c64:	e8 3d e5 ff ff       	call   801001a6 <bread>
80101c69:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101c6c:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c73:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101c76:	89 04 24             	mov    %eax,(%esp)
80101c79:	e8 c2 f8 ff ff       	call   80101540 <blkcmp>
80101c7e:	85 c0                	test   %eax,%eax
80101c80:	74 5f                	je     80101ce1 <dedup+0x658>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101c82:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101c89:	00 
80101c8a:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101c8d:	89 44 24 18          	mov    %eax,0x18(%esp)
80101c91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c94:	89 44 24 14          	mov    %eax,0x14(%esp)
80101c98:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c9b:	89 44 24 10          	mov    %eax,0x10(%esp)
80101c9f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ca2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101ca6:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101ca9:	89 44 24 08          	mov    %eax,0x8(%esp)
80101cad:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cb4:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101cb7:	89 04 24             	mov    %eax,(%esp)
80101cba:	e8 c9 f8 ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101cbf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101cc2:	89 04 24             	mov    %eax,(%esp)
80101cc5:	e8 4d e5 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101cca:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ccd:	89 04 24             	mov    %eax,(%esp)
80101cd0:	e8 42 e5 ff ff       	call   80100217 <brelse>
		  found = 1;
80101cd5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101cdc:	e9 29 01 00 00       	jmp    80101e0a <dedup+0x781>
		}
		brelse(b2);
80101ce1:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ce4:	89 04 24             	mov    %eax,(%esp)
80101ce7:	e8 2b e5 ff ff       	call   80100217 <brelse>
80101cec:	e9 0b 01 00 00       	jmp    80101dfc <dedup+0x773>
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
80101cf1:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80101cf5:	0f 84 01 01 00 00    	je     80101dfc <dedup+0x773>
	    {
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
80101cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cfe:	83 e8 0c             	sub    $0xc,%eax
80101d01:	89 45 ac             	mov    %eax,-0x54(%ebp)
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
80101d04:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101d08:	74 1e                	je     80101d28 <dedup+0x69f>
80101d0a:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d0d:	c1 e0 02             	shl    $0x2,%eax
80101d10:	03 45 d0             	add    -0x30(%ebp),%eax
80101d13:	8b 10                	mov    (%eax),%edx
80101d15:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101d18:	c1 e0 02             	shl    $0x2,%eax
80101d1b:	03 45 cc             	add    -0x34(%ebp),%eax
80101d1e:	8b 00                	mov    (%eax),%eax
80101d20:	39 c2                	cmp    %eax,%edx
80101d22:	0f 84 d3 00 00 00    	je     80101dfb <dedup+0x772>
80101d28:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d2b:	c1 e0 02             	shl    $0x2,%eax
80101d2e:	03 45 d0             	add    -0x30(%ebp),%eax
80101d31:	8b 10                	mov    (%eax),%edx
80101d33:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101d36:	8b 4d c8             	mov    -0x38(%ebp),%ecx
80101d39:	83 c1 04             	add    $0x4,%ecx
80101d3c:	8b 44 88 0c          	mov    0xc(%eax,%ecx,4),%eax
80101d40:	39 c2                	cmp    %eax,%edx
80101d42:	0f 84 b3 00 00 00    	je     80101dfb <dedup+0x772>
		continue;
	      if(b[blockIndex2Offset])
80101d48:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d4b:	c1 e0 02             	shl    $0x2,%eax
80101d4e:	03 45 d0             	add    -0x30(%ebp),%eax
80101d51:	8b 00                	mov    (%eax),%eax
80101d53:	85 c0                	test   %eax,%eax
80101d55:	0f 84 a1 00 00 00    	je     80101dfc <dedup+0x773>
	      {
		b2 = bread(ip2->dev,b[blockIndex2Offset]);
80101d5b:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101d5e:	c1 e0 02             	shl    $0x2,%eax
80101d61:	03 45 d0             	add    -0x30(%ebp),%eax
80101d64:	8b 10                	mov    (%eax),%edx
80101d66:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d69:	8b 00                	mov    (%eax),%eax
80101d6b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d6f:	89 04 24             	mov    %eax,(%esp)
80101d72:	e8 2f e4 ff ff       	call   801001a6 <bread>
80101d77:	89 45 b8             	mov    %eax,-0x48(%ebp)
		if(blkcmp(b1,b2))
80101d7a:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101d81:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101d84:	89 04 24             	mov    %eax,(%esp)
80101d87:	e8 b4 f7 ff ff       	call   80101540 <blkcmp>
80101d8c:	85 c0                	test   %eax,%eax
80101d8e:	74 5b                	je     80101deb <dedup+0x762>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101d90:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101d93:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101d97:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101d9a:	89 44 24 18          	mov    %eax,0x18(%esp)
80101d9e:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101da1:	89 44 24 14          	mov    %eax,0x14(%esp)
80101da5:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101da8:	89 44 24 10          	mov    %eax,0x10(%esp)
80101dac:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101daf:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101db3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101db6:	89 44 24 08          	mov    %eax,0x8(%esp)
80101dba:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101dbd:	89 44 24 04          	mov    %eax,0x4(%esp)
80101dc1:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101dc4:	89 04 24             	mov    %eax,(%esp)
80101dc7:	e8 bc f7 ff ff       	call   80101588 <deletedups>
		  brelse(b1);				// release the outer loop block
80101dcc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101dcf:	89 04 24             	mov    %eax,(%esp)
80101dd2:	e8 40 e4 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101dd7:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101dda:	89 04 24             	mov    %eax,(%esp)
80101ddd:	e8 35 e4 ff ff       	call   80100217 <brelse>
		  found = 1;
80101de2:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  break;
80101de9:	eb 1f                	jmp    80101e0a <dedup+0x781>
		}
		brelse(b2);
80101deb:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101dee:	89 04 24             	mov    %eax,(%esp)
80101df1:	e8 21 e4 ff ff       	call   80100217 <brelse>
80101df6:	eb 04                	jmp    80101dfc <dedup+0x773>
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
	  {
	    if(blockIndex2<NDIRECT)
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
		continue;
80101df8:	90                   	nop
80101df9:	eb 01                	jmp    80101dfc <dedup+0x773>
	    else if(b)
	    {
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
		continue;
80101dfb:	90                   	nop
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101dfc:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101e00:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e04:	0f 89 da fd ff ff    	jns    80101be4 <dedup+0x55b>
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
80101e0a:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e0d:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e10:	85 c0                	test   %eax,%eax
80101e12:	74 0b                	je     80101e1f <dedup+0x796>
	  {
	    brelse(bp2);
80101e14:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101e17:	89 04 24             	mov    %eax,(%esp)
80101e1a:	e8 f8 e3 ff ff       	call   80100217 <brelse>
	  }
	  
	  iunlockput(ip2);
80101e1f:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e22:	89 04 24             	mov    %eax,(%esp)
80101e25:	e8 36 0b 00 00       	call   80102960 <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101e2a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e2e:	75 18                	jne    80101e48 <dedup+0x7bf>
80101e30:	8d 45 a8             	lea    -0x58(%ebp),%eax
80101e33:	89 04 24             	mov    %eax,(%esp)
80101e36:	e8 73 16 00 00       	call   801034ae <getPrevInode>
80101e3b:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101e3e:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101e42:	0f 85 48 fd ff ff    	jne    80101b90 <dedup+0x507>
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
80101e48:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e4c:	75 0b                	jne    80101e59 <dedup+0x7d0>
      {
	brelse(b1);				// release the outer loop block
80101e4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101e51:	89 04 24             	mov    %eax,(%esp)
80101e54:	e8 be e3 ff ff       	call   80100217 <brelse>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101e59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101e5d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101e64:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e67:	83 c0 0c             	add    $0xc,%eax
80101e6a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101e6d:	0f 8f 22 f9 ff ff    	jg     80101795 <dedup+0x10c>
      {
	brelse(b1);				// release the outer loop block
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101e73:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101e76:	8b 40 4c             	mov    0x4c(%eax),%eax
80101e79:	85 c0                	test   %eax,%eax
80101e7b:	74 1f                	je     80101e9c <dedup+0x813>
    {
      if(indirectChanged)
80101e7d:	a1 90 f8 10 80       	mov    0x8010f890,%eax
80101e82:	85 c0                	test   %eax,%eax
80101e84:	74 0b                	je     80101e91 <dedup+0x808>
	bwrite(bp1);
80101e86:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101e89:	89 04 24             	mov    %eax,(%esp)
80101e8c:	e8 4c e3 ff ff       	call   801001dd <bwrite>
      brelse(bp1);
80101e91:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101e94:	89 04 24             	mov    %eax,(%esp)
80101e97:	e8 7b e3 ff ff       	call   80100217 <brelse>
    }
    
    if(directChanged)
80101e9c:	a1 80 ee 10 80       	mov    0x8010ee80,%eax
80101ea1:	85 c0                	test   %eax,%eax
80101ea3:	74 15                	je     80101eba <dedup+0x831>
    {
      begin_trans();
80101ea5:	e8 ab 26 00 00       	call   80104555 <begin_trans>
      iupdate(ip1);
80101eaa:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ead:	89 04 24             	mov    %eax,(%esp)
80101eb0:	e8 6b 06 00 00       	call   80102520 <iupdate>
      commit_trans();
80101eb5:	e8 e4 26 00 00       	call   8010459e <commit_trans>
    }
    iunlockput(ip1);
80101eba:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ebd:	89 04 24             	mov    %eax,(%esp)
80101ec0:	e8 9b 0a 00 00       	call   80102960 <iunlockput>
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  zeroNextInum();
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101ec5:	e8 30 15 00 00       	call   801033fa <getNextInode>
80101eca:	89 45 c0             	mov    %eax,-0x40(%ebp)
80101ecd:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
80101ed1:	0f 85 45 f8 ff ff    	jne    8010171c <dedup+0x93>
      iupdate(ip1);
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
  return 0;		
80101ed7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101edc:	c9                   	leave  
80101edd:	c3                   	ret    

80101ede <getSharedBlocksRate>:

int
getSharedBlocksRate(void)
{
80101ede:	55                   	push   %ebp
80101edf:	89 e5                	mov    %esp,%ebp
80101ee1:	53                   	push   %ebx
80101ee2:	83 ec 64             	sub    $0x64,%esp
  int i,digit;
  int saved = 0,total = 0;
80101ee5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101eec:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  struct buf* bp1 = bread(1,getRefCount(1));
80101ef3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101efa:	e8 60 16 00 00       	call   8010355f <getRefCount>
80101eff:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f03:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f0a:	e8 97 e2 ff ff       	call   801001a6 <bread>
80101f0f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct buf* bp2 = bread(1,getRefCount(2));
80101f12:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80101f19:	e8 41 16 00 00       	call   8010355f <getRefCount>
80101f1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f22:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f29:	e8 78 e2 ff ff       	call   801001a6 <bread>
80101f2e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  struct superblock sb;
  readsb(1, &sb);
80101f31:	8d 45 c0             	lea    -0x40(%ebp),%eax
80101f34:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f38:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f3f:	e8 1c 02 00 00       	call   80102160 <readsb>
  total = sb.nblocks - getFreeBlocks();
80101f44:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
80101f47:	e8 fb f4 ff ff       	call   80101447 <getFreeBlocks>
80101f4c:	89 da                	mov    %ebx,%edx
80101f4e:	29 c2                	sub    %eax,%edx
80101f50:	89 d0                	mov    %edx,%eax
80101f52:	89 45 e8             	mov    %eax,-0x18(%ebp)

  for(i=0;i<BSIZE;i++)
80101f55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f5c:	eb 4c                	jmp    80101faa <getSharedBlocksRate+0xcc>
  {
    if(bp1->data[i] > 0)
80101f5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f61:	03 45 f4             	add    -0xc(%ebp),%eax
80101f64:	83 c0 10             	add    $0x10,%eax
80101f67:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f6b:	84 c0                	test   %al,%al
80101f6d:	74 13                	je     80101f82 <getSharedBlocksRate+0xa4>
      saved += bp1->data[i];
80101f6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f72:	03 45 f4             	add    -0xc(%ebp),%eax
80101f75:	83 c0 10             	add    $0x10,%eax
80101f78:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f7c:	0f b6 c0             	movzbl %al,%eax
80101f7f:	01 45 ec             	add    %eax,-0x14(%ebp)
    if(bp2->data[i] > 0)
80101f82:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101f85:	03 45 f4             	add    -0xc(%ebp),%eax
80101f88:	83 c0 10             	add    $0x10,%eax
80101f8b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f8f:	84 c0                	test   %al,%al
80101f91:	74 13                	je     80101fa6 <getSharedBlocksRate+0xc8>
      saved += bp2->data[i];
80101f93:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101f96:	03 45 f4             	add    -0xc(%ebp),%eax
80101f99:	83 c0 10             	add    $0x10,%eax
80101f9c:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fa0:	0f b6 c0             	movzbl %al,%eax
80101fa3:	01 45 ec             	add    %eax,-0x14(%ebp)
  struct buf* bp2 = bread(1,getRefCount(2));
  struct superblock sb;
  readsb(1, &sb);
  total = sb.nblocks - getFreeBlocks();

  for(i=0;i<BSIZE;i++)
80101fa6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101faa:	81 7d f4 ff 01 00 00 	cmpl   $0x1ff,-0xc(%ebp)
80101fb1:	7e ab                	jle    80101f5e <getSharedBlocksRate+0x80>
    if(bp1->data[i] > 0)
      saved += bp1->data[i];
    if(bp2->data[i] > 0)
      saved += bp2->data[i];
  }
  brelse(bp1);
80101fb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101fb6:	89 04 24             	mov    %eax,(%esp)
80101fb9:	e8 59 e2 ff ff       	call   80100217 <brelse>
  brelse(bp2);
80101fbe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101fc1:	89 04 24             	mov    %eax,(%esp)
80101fc4:	e8 4e e2 ff ff       	call   80100217 <brelse>
  
  total += saved;
80101fc9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fcc:	01 45 e8             	add    %eax,-0x18(%ebp)
  
  double res = (double)saved/(double)total;
80101fcf:	db 45 ec             	fildl  -0x14(%ebp)
80101fd2:	db 45 e8             	fildl  -0x18(%ebp)
80101fd5:	de f9                	fdivrp %st,%st(1)
80101fd7:	dd 5d d8             	fstpl  -0x28(%ebp)
  cprintf("saved = %d, total = %d\n",saved,total);
80101fda:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101fdd:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fe1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fe4:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe8:	c7 04 24 db 97 10 80 	movl   $0x801097db,(%esp)
80101fef:	e8 ad e3 ff ff       	call   801003a1 <cprintf>
   
  cprintf("Shared block rate is: 0.");
80101ff4:	c7 04 24 f3 97 10 80 	movl   $0x801097f3,(%esp)
80101ffb:	e8 a1 e3 ff ff       	call   801003a1 <cprintf>
  for(i=10;i!=100000;i*=10)
80102000:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
80102007:	eb 6e                	jmp    80102077 <getSharedBlocksRate+0x199>
  {
    digit = res*i;
80102009:	db 45 f4             	fildl  -0xc(%ebp)
8010200c:	dc 4d d8             	fmull  -0x28(%ebp)
8010200f:	d9 7d b6             	fnstcw -0x4a(%ebp)
80102012:	0f b7 45 b6          	movzwl -0x4a(%ebp),%eax
80102016:	b4 0c                	mov    $0xc,%ah
80102018:	66 89 45 b4          	mov    %ax,-0x4c(%ebp)
8010201c:	d9 6d b4             	fldcw  -0x4c(%ebp)
8010201f:	db 5d f0             	fistpl -0x10(%ebp)
80102022:	d9 6d b6             	fldcw  -0x4a(%ebp)
    while(digit >= 10)
80102025:	eb 28                	jmp    8010204f <getSharedBlocksRate+0x171>
      digit %=10;
80102027:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010202a:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010202f:	89 c8                	mov    %ecx,%eax
80102031:	f7 ea                	imul   %edx
80102033:	c1 fa 02             	sar    $0x2,%edx
80102036:	89 c8                	mov    %ecx,%eax
80102038:	c1 f8 1f             	sar    $0x1f,%eax
8010203b:	29 c2                	sub    %eax,%edx
8010203d:	89 d0                	mov    %edx,%eax
8010203f:	c1 e0 02             	shl    $0x2,%eax
80102042:	01 d0                	add    %edx,%eax
80102044:	01 c0                	add    %eax,%eax
80102046:	89 ca                	mov    %ecx,%edx
80102048:	29 c2                	sub    %eax,%edx
8010204a:	89 d0                	mov    %edx,%eax
8010204c:	89 45 f0             	mov    %eax,-0x10(%ebp)
   
  cprintf("Shared block rate is: 0.");
  for(i=10;i!=100000;i*=10)
  {
    digit = res*i;
    while(digit >= 10)
8010204f:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
80102053:	7f d2                	jg     80102027 <getSharedBlocksRate+0x149>
      digit %=10;
    cprintf("%d",digit);
80102055:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102058:	89 44 24 04          	mov    %eax,0x4(%esp)
8010205c:	c7 04 24 0c 98 10 80 	movl   $0x8010980c,(%esp)
80102063:	e8 39 e3 ff ff       	call   801003a1 <cprintf>
  
  double res = (double)saved/(double)total;
  cprintf("saved = %d, total = %d\n",saved,total);
   
  cprintf("Shared block rate is: 0.");
  for(i=10;i!=100000;i*=10)
80102068:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010206b:	89 d0                	mov    %edx,%eax
8010206d:	c1 e0 02             	shl    $0x2,%eax
80102070:	01 d0                	add    %edx,%eax
80102072:	01 c0                	add    %eax,%eax
80102074:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102077:	81 7d f4 a0 86 01 00 	cmpl   $0x186a0,-0xc(%ebp)
8010207e:	75 89                	jne    80102009 <getSharedBlocksRate+0x12b>
    digit = res*i;
    while(digit >= 10)
      digit %=10;
    cprintf("%d",digit);
  }
  cprintf("\n");
80102080:	c7 04 24 0f 98 10 80 	movl   $0x8010980f,(%esp)
80102087:	e8 15 e3 ff ff       	call   801003a1 <cprintf>
  
  return 0;
8010208c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102091:	83 c4 64             	add    $0x64,%esp
80102094:	5b                   	pop    %ebx
80102095:	5d                   	pop    %ebp
80102096:	c3                   	ret    
	...

80102098 <replaceBlk>:
int prevInum = 0;
uint refCount1,refCount2;

void
replaceBlk(struct inode* ip, uint old, uint new)
{
80102098:	55                   	push   %ebp
80102099:	89 e5                	mov    %esp,%ebp
8010209b:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010209e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020a5:	eb 37                	jmp    801020de <replaceBlk+0x46>
    if(ip->addrs[i] && ip->addrs[i] == old){
801020a7:	8b 45 08             	mov    0x8(%ebp),%eax
801020aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801020ad:	83 c2 04             	add    $0x4,%edx
801020b0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801020b4:	85 c0                	test   %eax,%eax
801020b6:	74 22                	je     801020da <replaceBlk+0x42>
801020b8:	8b 45 08             	mov    0x8(%ebp),%eax
801020bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801020be:	83 c2 04             	add    $0x4,%edx
801020c1:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801020c5:	3b 45 0c             	cmp    0xc(%ebp),%eax
801020c8:	75 10                	jne    801020da <replaceBlk+0x42>
      ip->addrs[i] = new;
801020ca:	8b 45 08             	mov    0x8(%ebp),%eax
801020cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801020d0:	8d 4a 04             	lea    0x4(%edx),%ecx
801020d3:	8b 55 10             	mov    0x10(%ebp),%edx
801020d6:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801020da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801020de:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801020e2:	7e c3                	jle    801020a7 <replaceBlk+0xf>
    if(ip->addrs[i] && ip->addrs[i] == old){
      ip->addrs[i] = new;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801020e4:	8b 45 08             	mov    0x8(%ebp),%eax
801020e7:	8b 40 4c             	mov    0x4c(%eax),%eax
801020ea:	85 c0                	test   %eax,%eax
801020ec:	74 70                	je     8010215e <replaceBlk+0xc6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801020ee:	8b 45 08             	mov    0x8(%ebp),%eax
801020f1:	8b 50 4c             	mov    0x4c(%eax),%edx
801020f4:	8b 45 08             	mov    0x8(%ebp),%eax
801020f7:	8b 00                	mov    (%eax),%eax
801020f9:	89 54 24 04          	mov    %edx,0x4(%esp)
801020fd:	89 04 24             	mov    %eax,(%esp)
80102100:	e8 a1 e0 ff ff       	call   801001a6 <bread>
80102105:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102108:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010210b:	83 c0 18             	add    $0x18,%eax
8010210e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102111:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102118:	eb 31                	jmp    8010214b <replaceBlk+0xb3>
      if(a[j] && a[j] == old)
8010211a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010211d:	c1 e0 02             	shl    $0x2,%eax
80102120:	03 45 e8             	add    -0x18(%ebp),%eax
80102123:	8b 00                	mov    (%eax),%eax
80102125:	85 c0                	test   %eax,%eax
80102127:	74 1e                	je     80102147 <replaceBlk+0xaf>
80102129:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010212c:	c1 e0 02             	shl    $0x2,%eax
8010212f:	03 45 e8             	add    -0x18(%ebp),%eax
80102132:	8b 00                	mov    (%eax),%eax
80102134:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102137:	75 0e                	jne    80102147 <replaceBlk+0xaf>
	a[j] = new;
80102139:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010213c:	c1 e0 02             	shl    $0x2,%eax
8010213f:	03 45 e8             	add    -0x18(%ebp),%eax
80102142:	8b 55 10             	mov    0x10(%ebp),%edx
80102145:	89 10                	mov    %edx,(%eax)
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102147:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010214b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010214e:	83 f8 7f             	cmp    $0x7f,%eax
80102151:	76 c7                	jbe    8010211a <replaceBlk+0x82>
      if(a[j] && a[j] == old)
	a[j] = new;
    }
    brelse(bp);
80102153:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102156:	89 04 24             	mov    %eax,(%esp)
80102159:	e8 b9 e0 ff ff       	call   80100217 <brelse>
  }
}
8010215e:	c9                   	leave  
8010215f:	c3                   	ret    

80102160 <readsb>:
  

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80102160:	55                   	push   %ebp
80102161:	89 e5                	mov    %esp,%ebp
80102163:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80102166:	8b 45 08             	mov    0x8(%ebp),%eax
80102169:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102170:	00 
80102171:	89 04 24             	mov    %eax,(%esp)
80102174:	e8 2d e0 ff ff       	call   801001a6 <bread>
80102179:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010217c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010217f:	83 c0 18             	add    $0x18,%eax
80102182:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80102189:	00 
8010218a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010218e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102191:	89 04 24             	mov    %eax,(%esp)
80102194:	e8 64 40 00 00       	call   801061fd <memmove>
  brelse(bp);
80102199:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010219c:	89 04 24             	mov    %eax,(%esp)
8010219f:	e8 73 e0 ff ff       	call   80100217 <brelse>
}
801021a4:	c9                   	leave  
801021a5:	c3                   	ret    

801021a6 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801021a6:	55                   	push   %ebp
801021a7:	89 e5                	mov    %esp,%ebp
801021a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801021ac:	8b 55 0c             	mov    0xc(%ebp),%edx
801021af:	8b 45 08             	mov    0x8(%ebp),%eax
801021b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801021b6:	89 04 24             	mov    %eax,(%esp)
801021b9:	e8 e8 df ff ff       	call   801001a6 <bread>
801021be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801021c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021c4:	83 c0 18             	add    $0x18,%eax
801021c7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801021ce:	00 
801021cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801021d6:	00 
801021d7:	89 04 24             	mov    %eax,(%esp)
801021da:	e8 4b 3f 00 00       	call   8010612a <memset>
  log_write(bp);
801021df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021e2:	89 04 24             	mov    %eax,(%esp)
801021e5:	e8 0c 24 00 00       	call   801045f6 <log_write>
  brelse(bp);
801021ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021ed:	89 04 24             	mov    %eax,(%esp)
801021f0:	e8 22 e0 ff ff       	call   80100217 <brelse>
}
801021f5:	c9                   	leave  
801021f6:	c3                   	ret    

801021f7 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801021f7:	55                   	push   %ebp
801021f8:	89 e5                	mov    %esp,%ebp
801021fa:	53                   	push   %ebx
801021fb:	83 ec 44             	sub    $0x44,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801021fe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80102205:	8b 45 08             	mov    0x8(%ebp),%eax
80102208:	8d 55 d0             	lea    -0x30(%ebp),%edx
8010220b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010220f:	89 04 24             	mov    %eax,(%esp)
80102212:	e8 49 ff ff ff       	call   80102160 <readsb>
  for(b = 0; b < sb.size; b += BPB){
80102217:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010221e:	e9 11 01 00 00       	jmp    80102334 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80102223:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102226:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
8010222c:	85 c0                	test   %eax,%eax
8010222e:	0f 48 c2             	cmovs  %edx,%eax
80102231:	c1 f8 0c             	sar    $0xc,%eax
80102234:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102237:	c1 ea 03             	shr    $0x3,%edx
8010223a:	01 d0                	add    %edx,%eax
8010223c:	83 c0 03             	add    $0x3,%eax
8010223f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102243:	8b 45 08             	mov    0x8(%ebp),%eax
80102246:	89 04 24             	mov    %eax,(%esp)
80102249:	e8 58 df ff ff       	call   801001a6 <bread>
8010224e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102251:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102258:	e9 a7 00 00 00       	jmp    80102304 <balloc+0x10d>
      m = 1 << (bi % 8);
8010225d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102260:	89 c2                	mov    %eax,%edx
80102262:	c1 fa 1f             	sar    $0x1f,%edx
80102265:	c1 ea 1d             	shr    $0x1d,%edx
80102268:	01 d0                	add    %edx,%eax
8010226a:	83 e0 07             	and    $0x7,%eax
8010226d:	29 d0                	sub    %edx,%eax
8010226f:	ba 01 00 00 00       	mov    $0x1,%edx
80102274:	89 d3                	mov    %edx,%ebx
80102276:	89 c1                	mov    %eax,%ecx
80102278:	d3 e3                	shl    %cl,%ebx
8010227a:	89 d8                	mov    %ebx,%eax
8010227c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010227f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102282:	8d 50 07             	lea    0x7(%eax),%edx
80102285:	85 c0                	test   %eax,%eax
80102287:	0f 48 c2             	cmovs  %edx,%eax
8010228a:	c1 f8 03             	sar    $0x3,%eax
8010228d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80102290:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80102295:	0f b6 c0             	movzbl %al,%eax
80102298:	23 45 e8             	and    -0x18(%ebp),%eax
8010229b:	85 c0                	test   %eax,%eax
8010229d:	75 61                	jne    80102300 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
8010229f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022a2:	8d 50 07             	lea    0x7(%eax),%edx
801022a5:	85 c0                	test   %eax,%eax
801022a7:	0f 48 c2             	cmovs  %edx,%eax
801022aa:	c1 f8 03             	sar    $0x3,%eax
801022ad:	8b 55 ec             	mov    -0x14(%ebp),%edx
801022b0:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801022b5:	89 d1                	mov    %edx,%ecx
801022b7:	8b 55 e8             	mov    -0x18(%ebp),%edx
801022ba:	09 ca                	or     %ecx,%edx
801022bc:	89 d1                	mov    %edx,%ecx
801022be:	8b 55 ec             	mov    -0x14(%ebp),%edx
801022c1:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
801022c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022c8:	89 04 24             	mov    %eax,(%esp)
801022cb:	e8 26 23 00 00       	call   801045f6 <log_write>
        brelse(bp);
801022d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022d3:	89 04 24             	mov    %eax,(%esp)
801022d6:	e8 3c df ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801022db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022e1:	01 c2                	add    %eax,%edx
801022e3:	8b 45 08             	mov    0x8(%ebp),%eax
801022e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801022ea:	89 04 24             	mov    %eax,(%esp)
801022ed:	e8 b4 fe ff ff       	call   801021a6 <bzero>
        return b + bi;
801022f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022f8:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801022fa:	83 c4 44             	add    $0x44,%esp
801022fd:	5b                   	pop    %ebx
801022fe:	5d                   	pop    %ebp
801022ff:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102300:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102304:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010230b:	7f 15                	jg     80102322 <balloc+0x12b>
8010230d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102310:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102313:	01 d0                	add    %edx,%eax
80102315:	89 c2                	mov    %eax,%edx
80102317:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010231a:	39 c2                	cmp    %eax,%edx
8010231c:	0f 82 3b ff ff ff    	jb     8010225d <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80102322:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102325:	89 04 24             	mov    %eax,(%esp)
80102328:	e8 ea de ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
8010232d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102334:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102337:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010233a:	39 c2                	cmp    %eax,%edx
8010233c:	0f 82 e1 fe ff ff    	jb     80102223 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80102342:	c7 04 24 11 98 10 80 	movl   $0x80109811,(%esp)
80102349:	e8 ef e1 ff ff       	call   8010053d <panic>

8010234e <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
8010234e:	55                   	push   %ebp
8010234f:	89 e5                	mov    %esp,%ebp
80102351:	53                   	push   %ebx
80102352:	83 ec 44             	sub    $0x44,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80102355:	8d 45 d4             	lea    -0x2c(%ebp),%eax
80102358:	89 44 24 04          	mov    %eax,0x4(%esp)
8010235c:	8b 45 08             	mov    0x8(%ebp),%eax
8010235f:	89 04 24             	mov    %eax,(%esp)
80102362:	e8 f9 fd ff ff       	call   80102160 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80102367:	8b 45 0c             	mov    0xc(%ebp),%eax
8010236a:	89 c2                	mov    %eax,%edx
8010236c:	c1 ea 0c             	shr    $0xc,%edx
8010236f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102372:	c1 e8 03             	shr    $0x3,%eax
80102375:	01 d0                	add    %edx,%eax
80102377:	8d 50 03             	lea    0x3(%eax),%edx
8010237a:	8b 45 08             	mov    0x8(%ebp),%eax
8010237d:	89 54 24 04          	mov    %edx,0x4(%esp)
80102381:	89 04 24             	mov    %eax,(%esp)
80102384:	e8 1d de ff ff       	call   801001a6 <bread>
80102389:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010238c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010238f:	25 ff 0f 00 00       	and    $0xfff,%eax
80102394:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80102397:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010239a:	89 c2                	mov    %eax,%edx
8010239c:	c1 fa 1f             	sar    $0x1f,%edx
8010239f:	c1 ea 1d             	shr    $0x1d,%edx
801023a2:	01 d0                	add    %edx,%eax
801023a4:	83 e0 07             	and    $0x7,%eax
801023a7:	29 d0                	sub    %edx,%eax
801023a9:	ba 01 00 00 00       	mov    $0x1,%edx
801023ae:	89 d3                	mov    %edx,%ebx
801023b0:	89 c1                	mov    %eax,%ecx
801023b2:	d3 e3                	shl    %cl,%ebx
801023b4:	89 d8                	mov    %ebx,%eax
801023b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801023b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023bc:	8d 50 07             	lea    0x7(%eax),%edx
801023bf:	85 c0                	test   %eax,%eax
801023c1:	0f 48 c2             	cmovs  %edx,%eax
801023c4:	c1 f8 03             	sar    $0x3,%eax
801023c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023ca:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801023cf:	0f b6 c0             	movzbl %al,%eax
801023d2:	23 45 ec             	and    -0x14(%ebp),%eax
801023d5:	85 c0                	test   %eax,%eax
801023d7:	75 0c                	jne    801023e5 <bfree+0x97>
    panic("freeing free block");
801023d9:	c7 04 24 27 98 10 80 	movl   $0x80109827,(%esp)
801023e0:	e8 58 e1 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801023e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023e8:	8d 50 07             	lea    0x7(%eax),%edx
801023eb:	85 c0                	test   %eax,%eax
801023ed:	0f 48 c2             	cmovs  %edx,%eax
801023f0:	c1 f8 03             	sar    $0x3,%eax
801023f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023f6:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801023fb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801023fe:	f7 d1                	not    %ecx
80102400:	21 ca                	and    %ecx,%edx
80102402:	89 d1                	mov    %edx,%ecx
80102404:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102407:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010240b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010240e:	89 04 24             	mov    %eax,(%esp)
80102411:	e8 e0 21 00 00       	call   801045f6 <log_write>
  brelse(bp);
80102416:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102419:	89 04 24             	mov    %eax,(%esp)
8010241c:	e8 f6 dd ff ff       	call   80100217 <brelse>
}
80102421:	83 c4 44             	add    $0x44,%esp
80102424:	5b                   	pop    %ebx
80102425:	5d                   	pop    %ebp
80102426:	c3                   	ret    

80102427 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80102427:	55                   	push   %ebp
80102428:	89 e5                	mov    %esp,%ebp
8010242a:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
8010242d:	c7 44 24 04 3a 98 10 	movl   $0x8010983a,0x4(%esp)
80102434:	80 
80102435:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010243c:	e8 79 3a 00 00       	call   80105eba <initlock>
}
80102441:	c9                   	leave  
80102442:	c3                   	ret    

80102443 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80102443:	55                   	push   %ebp
80102444:	89 e5                	mov    %esp,%ebp
80102446:	83 ec 58             	sub    $0x58,%esp
80102449:	8b 45 0c             	mov    0xc(%ebp),%eax
8010244c:	66 89 45 c4          	mov    %ax,-0x3c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80102450:	8b 45 08             	mov    0x8(%ebp),%eax
80102453:	8d 55 d4             	lea    -0x2c(%ebp),%edx
80102456:	89 54 24 04          	mov    %edx,0x4(%esp)
8010245a:	89 04 24             	mov    %eax,(%esp)
8010245d:	e8 fe fc ff ff       	call   80102160 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80102462:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102469:	e9 98 00 00 00       	jmp    80102506 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010246e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102471:	c1 e8 03             	shr    $0x3,%eax
80102474:	83 c0 02             	add    $0x2,%eax
80102477:	89 44 24 04          	mov    %eax,0x4(%esp)
8010247b:	8b 45 08             	mov    0x8(%ebp),%eax
8010247e:	89 04 24             	mov    %eax,(%esp)
80102481:	e8 20 dd ff ff       	call   801001a6 <bread>
80102486:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80102489:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010248c:	8d 50 18             	lea    0x18(%eax),%edx
8010248f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102492:	83 e0 07             	and    $0x7,%eax
80102495:	c1 e0 06             	shl    $0x6,%eax
80102498:	01 d0                	add    %edx,%eax
8010249a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010249d:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024a0:	0f b7 00             	movzwl (%eax),%eax
801024a3:	66 85 c0             	test   %ax,%ax
801024a6:	75 4f                	jne    801024f7 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801024a8:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801024af:	00 
801024b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801024b7:	00 
801024b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024bb:	89 04 24             	mov    %eax,(%esp)
801024be:	e8 67 3c 00 00       	call   8010612a <memset>
      dip->type = type;
801024c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024c6:	0f b7 55 c4          	movzwl -0x3c(%ebp),%edx
801024ca:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801024cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024d0:	89 04 24             	mov    %eax,(%esp)
801024d3:	e8 1e 21 00 00       	call   801045f6 <log_write>
      brelse(bp);
801024d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024db:	89 04 24             	mov    %eax,(%esp)
801024de:	e8 34 dd ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801024e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801024ea:	8b 45 08             	mov    0x8(%ebp),%eax
801024ed:	89 04 24             	mov    %eax,(%esp)
801024f0:	e8 e3 00 00 00       	call   801025d8 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801024f5:	c9                   	leave  
801024f6:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801024f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024fa:	89 04 24             	mov    %eax,(%esp)
801024fd:	e8 15 dd ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80102502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102506:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102509:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010250c:	39 c2                	cmp    %eax,%edx
8010250e:	0f 82 5a ff ff ff    	jb     8010246e <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80102514:	c7 04 24 41 98 10 80 	movl   $0x80109841,(%esp)
8010251b:	e8 1d e0 ff ff       	call   8010053d <panic>

80102520 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80102520:	55                   	push   %ebp
80102521:	89 e5                	mov    %esp,%ebp
80102523:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80102526:	8b 45 08             	mov    0x8(%ebp),%eax
80102529:	8b 40 04             	mov    0x4(%eax),%eax
8010252c:	c1 e8 03             	shr    $0x3,%eax
8010252f:	8d 50 02             	lea    0x2(%eax),%edx
80102532:	8b 45 08             	mov    0x8(%ebp),%eax
80102535:	8b 00                	mov    (%eax),%eax
80102537:	89 54 24 04          	mov    %edx,0x4(%esp)
8010253b:	89 04 24             	mov    %eax,(%esp)
8010253e:	e8 63 dc ff ff       	call   801001a6 <bread>
80102543:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80102546:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102549:	8d 50 18             	lea    0x18(%eax),%edx
8010254c:	8b 45 08             	mov    0x8(%ebp),%eax
8010254f:	8b 40 04             	mov    0x4(%eax),%eax
80102552:	83 e0 07             	and    $0x7,%eax
80102555:	c1 e0 06             	shl    $0x6,%eax
80102558:	01 d0                	add    %edx,%eax
8010255a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010255d:	8b 45 08             	mov    0x8(%ebp),%eax
80102560:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102564:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102567:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010256a:	8b 45 08             	mov    0x8(%ebp),%eax
8010256d:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80102571:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102574:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102578:	8b 45 08             	mov    0x8(%ebp),%eax
8010257b:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010257f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102582:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80102586:	8b 45 08             	mov    0x8(%ebp),%eax
80102589:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010258d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102590:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80102594:	8b 45 08             	mov    0x8(%ebp),%eax
80102597:	8b 50 18             	mov    0x18(%eax),%edx
8010259a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010259d:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801025a0:	8b 45 08             	mov    0x8(%ebp),%eax
801025a3:	8d 50 1c             	lea    0x1c(%eax),%edx
801025a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801025a9:	83 c0 0c             	add    $0xc,%eax
801025ac:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801025b3:	00 
801025b4:	89 54 24 04          	mov    %edx,0x4(%esp)
801025b8:	89 04 24             	mov    %eax,(%esp)
801025bb:	e8 3d 3c 00 00       	call   801061fd <memmove>
  log_write(bp);
801025c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025c3:	89 04 24             	mov    %eax,(%esp)
801025c6:	e8 2b 20 00 00       	call   801045f6 <log_write>
  brelse(bp);
801025cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025ce:	89 04 24             	mov    %eax,(%esp)
801025d1:	e8 41 dc ff ff       	call   80100217 <brelse>
}
801025d6:	c9                   	leave  
801025d7:	c3                   	ret    

801025d8 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801025d8:	55                   	push   %ebp
801025d9:	89 e5                	mov    %esp,%ebp
801025db:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801025de:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801025e5:	e8 f1 38 00 00       	call   80105edb <acquire>

  // Is the inode already cached?
  empty = 0;
801025ea:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801025f1:	c7 45 f4 f4 f8 10 80 	movl   $0x8010f8f4,-0xc(%ebp)
801025f8:	eb 59                	jmp    80102653 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801025fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025fd:	8b 40 08             	mov    0x8(%eax),%eax
80102600:	85 c0                	test   %eax,%eax
80102602:	7e 35                	jle    80102639 <iget+0x61>
80102604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102607:	8b 00                	mov    (%eax),%eax
80102609:	3b 45 08             	cmp    0x8(%ebp),%eax
8010260c:	75 2b                	jne    80102639 <iget+0x61>
8010260e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102611:	8b 40 04             	mov    0x4(%eax),%eax
80102614:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102617:	75 20                	jne    80102639 <iget+0x61>
      ip->ref++;
80102619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010261c:	8b 40 08             	mov    0x8(%eax),%eax
8010261f:	8d 50 01             	lea    0x1(%eax),%edx
80102622:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102625:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102628:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010262f:	e8 09 39 00 00       	call   80105f3d <release>
      return ip;
80102634:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102637:	eb 6f                	jmp    801026a8 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102639:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010263d:	75 10                	jne    8010264f <iget+0x77>
8010263f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102642:	8b 40 08             	mov    0x8(%eax),%eax
80102645:	85 c0                	test   %eax,%eax
80102647:	75 06                	jne    8010264f <iget+0x77>
      empty = ip;
80102649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010264c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010264f:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80102653:	81 7d f4 94 08 11 80 	cmpl   $0x80110894,-0xc(%ebp)
8010265a:	72 9e                	jb     801025fa <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010265c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102660:	75 0c                	jne    8010266e <iget+0x96>
    panic("iget: no inodes");
80102662:	c7 04 24 53 98 10 80 	movl   $0x80109853,(%esp)
80102669:	e8 cf de ff ff       	call   8010053d <panic>

  ip = empty;
8010266e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102671:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80102674:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102677:	8b 55 08             	mov    0x8(%ebp),%edx
8010267a:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
8010267c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010267f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102682:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80102685:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102688:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010268f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102692:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80102699:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801026a0:	e8 98 38 00 00       	call   80105f3d <release>

  return ip;
801026a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801026a8:	c9                   	leave  
801026a9:	c3                   	ret    

801026aa <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801026aa:	55                   	push   %ebp
801026ab:	89 e5                	mov    %esp,%ebp
801026ad:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801026b0:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801026b7:	e8 1f 38 00 00       	call   80105edb <acquire>
  ip->ref++;
801026bc:	8b 45 08             	mov    0x8(%ebp),%eax
801026bf:	8b 40 08             	mov    0x8(%eax),%eax
801026c2:	8d 50 01             	lea    0x1(%eax),%edx
801026c5:	8b 45 08             	mov    0x8(%ebp),%eax
801026c8:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801026cb:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801026d2:	e8 66 38 00 00       	call   80105f3d <release>
  return ip;
801026d7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801026da:	c9                   	leave  
801026db:	c3                   	ret    

801026dc <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801026dc:	55                   	push   %ebp
801026dd:	89 e5                	mov    %esp,%ebp
801026df:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801026e2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026e6:	74 0a                	je     801026f2 <ilock+0x16>
801026e8:	8b 45 08             	mov    0x8(%ebp),%eax
801026eb:	8b 40 08             	mov    0x8(%eax),%eax
801026ee:	85 c0                	test   %eax,%eax
801026f0:	7f 0c                	jg     801026fe <ilock+0x22>
    panic("ilock");
801026f2:	c7 04 24 63 98 10 80 	movl   $0x80109863,(%esp)
801026f9:	e8 3f de ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801026fe:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102705:	e8 d1 37 00 00       	call   80105edb <acquire>
  while(ip->flags & I_BUSY)
8010270a:	eb 13                	jmp    8010271f <ilock+0x43>
    sleep(ip, &icache.lock);
8010270c:	c7 44 24 04 c0 f8 10 	movl   $0x8010f8c0,0x4(%esp)
80102713:	80 
80102714:	8b 45 08             	mov    0x8(%ebp),%eax
80102717:	89 04 24             	mov    %eax,(%esp)
8010271a:	e8 de 34 00 00       	call   80105bfd <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010271f:	8b 45 08             	mov    0x8(%ebp),%eax
80102722:	8b 40 0c             	mov    0xc(%eax),%eax
80102725:	83 e0 01             	and    $0x1,%eax
80102728:	84 c0                	test   %al,%al
8010272a:	75 e0                	jne    8010270c <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
8010272c:	8b 45 08             	mov    0x8(%ebp),%eax
8010272f:	8b 40 0c             	mov    0xc(%eax),%eax
80102732:	89 c2                	mov    %eax,%edx
80102734:	83 ca 01             	or     $0x1,%edx
80102737:	8b 45 08             	mov    0x8(%ebp),%eax
8010273a:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
8010273d:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102744:	e8 f4 37 00 00       	call   80105f3d <release>

  if(!(ip->flags & I_VALID)){
80102749:	8b 45 08             	mov    0x8(%ebp),%eax
8010274c:	8b 40 0c             	mov    0xc(%eax),%eax
8010274f:	83 e0 02             	and    $0x2,%eax
80102752:	85 c0                	test   %eax,%eax
80102754:	0f 85 ce 00 00 00    	jne    80102828 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
8010275a:	8b 45 08             	mov    0x8(%ebp),%eax
8010275d:	8b 40 04             	mov    0x4(%eax),%eax
80102760:	c1 e8 03             	shr    $0x3,%eax
80102763:	8d 50 02             	lea    0x2(%eax),%edx
80102766:	8b 45 08             	mov    0x8(%ebp),%eax
80102769:	8b 00                	mov    (%eax),%eax
8010276b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010276f:	89 04 24             	mov    %eax,(%esp)
80102772:	e8 2f da ff ff       	call   801001a6 <bread>
80102777:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010277a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277d:	8d 50 18             	lea    0x18(%eax),%edx
80102780:	8b 45 08             	mov    0x8(%ebp),%eax
80102783:	8b 40 04             	mov    0x4(%eax),%eax
80102786:	83 e0 07             	and    $0x7,%eax
80102789:	c1 e0 06             	shl    $0x6,%eax
8010278c:	01 d0                	add    %edx,%eax
8010278e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80102791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102794:	0f b7 10             	movzwl (%eax),%edx
80102797:	8b 45 08             	mov    0x8(%ebp),%eax
8010279a:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010279e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027a1:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801027a5:	8b 45 08             	mov    0x8(%ebp),%eax
801027a8:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801027ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027af:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801027b3:	8b 45 08             	mov    0x8(%ebp),%eax
801027b6:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801027ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027bd:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801027c1:	8b 45 08             	mov    0x8(%ebp),%eax
801027c4:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801027c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027cb:	8b 50 08             	mov    0x8(%eax),%edx
801027ce:	8b 45 08             	mov    0x8(%ebp),%eax
801027d1:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801027d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027d7:	8d 50 0c             	lea    0xc(%eax),%edx
801027da:	8b 45 08             	mov    0x8(%ebp),%eax
801027dd:	83 c0 1c             	add    $0x1c,%eax
801027e0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801027e7:	00 
801027e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801027ec:	89 04 24             	mov    %eax,(%esp)
801027ef:	e8 09 3a 00 00       	call   801061fd <memmove>
    brelse(bp);
801027f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027f7:	89 04 24             	mov    %eax,(%esp)
801027fa:	e8 18 da ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801027ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102802:	8b 40 0c             	mov    0xc(%eax),%eax
80102805:	89 c2                	mov    %eax,%edx
80102807:	83 ca 02             	or     $0x2,%edx
8010280a:	8b 45 08             	mov    0x8(%ebp),%eax
8010280d:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80102810:	8b 45 08             	mov    0x8(%ebp),%eax
80102813:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102817:	66 85 c0             	test   %ax,%ax
8010281a:	75 0c                	jne    80102828 <ilock+0x14c>
      panic("ilock: no type");
8010281c:	c7 04 24 69 98 10 80 	movl   $0x80109869,(%esp)
80102823:	e8 15 dd ff ff       	call   8010053d <panic>
  }
}
80102828:	c9                   	leave  
80102829:	c3                   	ret    

8010282a <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
8010282a:	55                   	push   %ebp
8010282b:	89 e5                	mov    %esp,%ebp
8010282d:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102830:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102834:	74 17                	je     8010284d <iunlock+0x23>
80102836:	8b 45 08             	mov    0x8(%ebp),%eax
80102839:	8b 40 0c             	mov    0xc(%eax),%eax
8010283c:	83 e0 01             	and    $0x1,%eax
8010283f:	85 c0                	test   %eax,%eax
80102841:	74 0a                	je     8010284d <iunlock+0x23>
80102843:	8b 45 08             	mov    0x8(%ebp),%eax
80102846:	8b 40 08             	mov    0x8(%eax),%eax
80102849:	85 c0                	test   %eax,%eax
8010284b:	7f 0c                	jg     80102859 <iunlock+0x2f>
    panic("iunlock");
8010284d:	c7 04 24 78 98 10 80 	movl   $0x80109878,(%esp)
80102854:	e8 e4 dc ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102859:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102860:	e8 76 36 00 00       	call   80105edb <acquire>
  ip->flags &= ~I_BUSY;
80102865:	8b 45 08             	mov    0x8(%ebp),%eax
80102868:	8b 40 0c             	mov    0xc(%eax),%eax
8010286b:	89 c2                	mov    %eax,%edx
8010286d:	83 e2 fe             	and    $0xfffffffe,%edx
80102870:	8b 45 08             	mov    0x8(%ebp),%eax
80102873:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102876:	8b 45 08             	mov    0x8(%ebp),%eax
80102879:	89 04 24             	mov    %eax,(%esp)
8010287c:	e8 55 34 00 00       	call   80105cd6 <wakeup>
  release(&icache.lock);
80102881:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102888:	e8 b0 36 00 00       	call   80105f3d <release>
}
8010288d:	c9                   	leave  
8010288e:	c3                   	ret    

8010288f <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
8010288f:	55                   	push   %ebp
80102890:	89 e5                	mov    %esp,%ebp
80102892:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102895:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010289c:	e8 3a 36 00 00       	call   80105edb <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801028a1:	8b 45 08             	mov    0x8(%ebp),%eax
801028a4:	8b 40 08             	mov    0x8(%eax),%eax
801028a7:	83 f8 01             	cmp    $0x1,%eax
801028aa:	0f 85 93 00 00 00    	jne    80102943 <iput+0xb4>
801028b0:	8b 45 08             	mov    0x8(%ebp),%eax
801028b3:	8b 40 0c             	mov    0xc(%eax),%eax
801028b6:	83 e0 02             	and    $0x2,%eax
801028b9:	85 c0                	test   %eax,%eax
801028bb:	0f 84 82 00 00 00    	je     80102943 <iput+0xb4>
801028c1:	8b 45 08             	mov    0x8(%ebp),%eax
801028c4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801028c8:	66 85 c0             	test   %ax,%ax
801028cb:	75 76                	jne    80102943 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801028cd:	8b 45 08             	mov    0x8(%ebp),%eax
801028d0:	8b 40 0c             	mov    0xc(%eax),%eax
801028d3:	83 e0 01             	and    $0x1,%eax
801028d6:	84 c0                	test   %al,%al
801028d8:	74 0c                	je     801028e6 <iput+0x57>
      panic("iput busy");
801028da:	c7 04 24 80 98 10 80 	movl   $0x80109880,(%esp)
801028e1:	e8 57 dc ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801028e6:	8b 45 08             	mov    0x8(%ebp),%eax
801028e9:	8b 40 0c             	mov    0xc(%eax),%eax
801028ec:	89 c2                	mov    %eax,%edx
801028ee:	83 ca 01             	or     $0x1,%edx
801028f1:	8b 45 08             	mov    0x8(%ebp),%eax
801028f4:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
801028f7:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801028fe:	e8 3a 36 00 00       	call   80105f3d <release>
    itrunc(ip);
80102903:	8b 45 08             	mov    0x8(%ebp),%eax
80102906:	89 04 24             	mov    %eax,(%esp)
80102909:	e8 72 01 00 00       	call   80102a80 <itrunc>
    ip->type = 0;
8010290e:	8b 45 08             	mov    0x8(%ebp),%eax
80102911:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80102917:	8b 45 08             	mov    0x8(%ebp),%eax
8010291a:	89 04 24             	mov    %eax,(%esp)
8010291d:	e8 fe fb ff ff       	call   80102520 <iupdate>
    acquire(&icache.lock);
80102922:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102929:	e8 ad 35 00 00       	call   80105edb <acquire>
    ip->flags = 0;
8010292e:	8b 45 08             	mov    0x8(%ebp),%eax
80102931:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102938:	8b 45 08             	mov    0x8(%ebp),%eax
8010293b:	89 04 24             	mov    %eax,(%esp)
8010293e:	e8 93 33 00 00       	call   80105cd6 <wakeup>
  }
  ip->ref--;
80102943:	8b 45 08             	mov    0x8(%ebp),%eax
80102946:	8b 40 08             	mov    0x8(%eax),%eax
80102949:	8d 50 ff             	lea    -0x1(%eax),%edx
8010294c:	8b 45 08             	mov    0x8(%ebp),%eax
8010294f:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102952:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102959:	e8 df 35 00 00       	call   80105f3d <release>
}
8010295e:	c9                   	leave  
8010295f:	c3                   	ret    

80102960 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102960:	55                   	push   %ebp
80102961:	89 e5                	mov    %esp,%ebp
80102963:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102966:	8b 45 08             	mov    0x8(%ebp),%eax
80102969:	89 04 24             	mov    %eax,(%esp)
8010296c:	e8 b9 fe ff ff       	call   8010282a <iunlock>
  iput(ip);
80102971:	8b 45 08             	mov    0x8(%ebp),%eax
80102974:	89 04 24             	mov    %eax,(%esp)
80102977:	e8 13 ff ff ff       	call   8010288f <iput>
}
8010297c:	c9                   	leave  
8010297d:	c3                   	ret    

8010297e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010297e:	55                   	push   %ebp
8010297f:	89 e5                	mov    %esp,%ebp
80102981:	53                   	push   %ebx
80102982:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102985:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80102989:	77 3e                	ja     801029c9 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
8010298b:	8b 45 08             	mov    0x8(%ebp),%eax
8010298e:	8b 55 0c             	mov    0xc(%ebp),%edx
80102991:	83 c2 04             	add    $0x4,%edx
80102994:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102998:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010299b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010299f:	75 20                	jne    801029c1 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801029a1:	8b 45 08             	mov    0x8(%ebp),%eax
801029a4:	8b 00                	mov    (%eax),%eax
801029a6:	89 04 24             	mov    %eax,(%esp)
801029a9:	e8 49 f8 ff ff       	call   801021f7 <balloc>
801029ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029b1:	8b 45 08             	mov    0x8(%ebp),%eax
801029b4:	8b 55 0c             	mov    0xc(%ebp),%edx
801029b7:	8d 4a 04             	lea    0x4(%edx),%ecx
801029ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029bd:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801029c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029c4:	e9 b1 00 00 00       	jmp    80102a7a <bmap+0xfc>
  }
  bn -= NDIRECT;
801029c9:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801029cd:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801029d1:	0f 87 97 00 00 00    	ja     80102a6e <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801029d7:	8b 45 08             	mov    0x8(%ebp),%eax
801029da:	8b 40 4c             	mov    0x4c(%eax),%eax
801029dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029e0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801029e4:	75 19                	jne    801029ff <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801029e6:	8b 45 08             	mov    0x8(%ebp),%eax
801029e9:	8b 00                	mov    (%eax),%eax
801029eb:	89 04 24             	mov    %eax,(%esp)
801029ee:	e8 04 f8 ff ff       	call   801021f7 <balloc>
801029f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029f6:	8b 45 08             	mov    0x8(%ebp),%eax
801029f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029fc:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
801029ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102a02:	8b 00                	mov    (%eax),%eax
80102a04:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a07:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a0b:	89 04 24             	mov    %eax,(%esp)
80102a0e:	e8 93 d7 ff ff       	call   801001a6 <bread>
80102a13:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80102a16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a19:	83 c0 18             	add    $0x18,%eax
80102a1c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80102a1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a22:	c1 e0 02             	shl    $0x2,%eax
80102a25:	03 45 ec             	add    -0x14(%ebp),%eax
80102a28:	8b 00                	mov    (%eax),%eax
80102a2a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a2d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102a31:	75 2b                	jne    80102a5e <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80102a33:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a36:	c1 e0 02             	shl    $0x2,%eax
80102a39:	89 c3                	mov    %eax,%ebx
80102a3b:	03 5d ec             	add    -0x14(%ebp),%ebx
80102a3e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a41:	8b 00                	mov    (%eax),%eax
80102a43:	89 04 24             	mov    %eax,(%esp)
80102a46:	e8 ac f7 ff ff       	call   801021f7 <balloc>
80102a4b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a51:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80102a53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a56:	89 04 24             	mov    %eax,(%esp)
80102a59:	e8 98 1b 00 00       	call   801045f6 <log_write>
    }
    brelse(bp);
80102a5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a61:	89 04 24             	mov    %eax,(%esp)
80102a64:	e8 ae d7 ff ff       	call   80100217 <brelse>
    return addr;
80102a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a6c:	eb 0c                	jmp    80102a7a <bmap+0xfc>
  }

  panic("bmap: out of range");
80102a6e:	c7 04 24 8a 98 10 80 	movl   $0x8010988a,(%esp)
80102a75:	e8 c3 da ff ff       	call   8010053d <panic>
}
80102a7a:	83 c4 24             	add    $0x24,%esp
80102a7d:	5b                   	pop    %ebx
80102a7e:	5d                   	pop    %ebp
80102a7f:	c3                   	ret    

80102a80 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102a80:	55                   	push   %ebp
80102a81:	89 e5                	mov    %esp,%ebp
80102a83:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;
  for(i = 0; i < NDIRECT; i++){
80102a86:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a8d:	eb 7c                	jmp    80102b0b <itrunc+0x8b>
    if(ip->addrs[i]){
80102a8f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a92:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a95:	83 c2 04             	add    $0x4,%edx
80102a98:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a9c:	85 c0                	test   %eax,%eax
80102a9e:	74 67                	je     80102b07 <itrunc+0x87>
      if(getBlkRef(ip->addrs[i]) > 0)
80102aa0:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102aa6:	83 c2 04             	add    $0x4,%edx
80102aa9:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102aad:	89 04 24             	mov    %eax,(%esp)
80102ab0:	e8 2f 0c 00 00       	call   801036e4 <getBlkRef>
80102ab5:	85 c0                	test   %eax,%eax
80102ab7:	7e 1f                	jle    80102ad8 <itrunc+0x58>
	updateBlkRef(ip->addrs[i],-1);
80102ab9:	8b 45 08             	mov    0x8(%ebp),%eax
80102abc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102abf:	83 c2 04             	add    $0x4,%edx
80102ac2:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102ac6:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102acd:	ff 
80102ace:	89 04 24             	mov    %eax,(%esp)
80102ad1:	e8 cf 0a 00 00       	call   801035a5 <updateBlkRef>
80102ad6:	eb 1e                	jmp    80102af6 <itrunc+0x76>
      else
	bfree(ip->dev, ip->addrs[i]);
80102ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80102adb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ade:	83 c2 04             	add    $0x4,%edx
80102ae1:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80102ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae8:	8b 00                	mov    (%eax),%eax
80102aea:	89 54 24 04          	mov    %edx,0x4(%esp)
80102aee:	89 04 24             	mov    %eax,(%esp)
80102af1:	e8 58 f8 ff ff       	call   8010234e <bfree>
      ip->addrs[i] = 0;
80102af6:	8b 45 08             	mov    0x8(%ebp),%eax
80102af9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102afc:	83 c2 04             	add    $0x4,%edx
80102aff:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80102b06:	00 
itrunc(struct inode *ip)
{
  int i, j;
  struct buf *bp;
  uint *a;
  for(i = 0; i < NDIRECT; i++){
80102b07:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b0b:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102b0f:	0f 8e 7a ff ff ff    	jle    80102a8f <itrunc+0xf>
	bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102b15:	8b 45 08             	mov    0x8(%ebp),%eax
80102b18:	8b 40 4c             	mov    0x4c(%eax),%eax
80102b1b:	85 c0                	test   %eax,%eax
80102b1d:	0f 84 c3 00 00 00    	je     80102be6 <itrunc+0x166>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102b23:	8b 45 08             	mov    0x8(%ebp),%eax
80102b26:	8b 50 4c             	mov    0x4c(%eax),%edx
80102b29:	8b 45 08             	mov    0x8(%ebp),%eax
80102b2c:	8b 00                	mov    (%eax),%eax
80102b2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102b32:	89 04 24             	mov    %eax,(%esp)
80102b35:	e8 6c d6 ff ff       	call   801001a6 <bread>
80102b3a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102b3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b40:	83 c0 18             	add    $0x18,%eax
80102b43:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102b46:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102b4d:	eb 63                	jmp    80102bb2 <itrunc+0x132>
      if(a[j])
80102b4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b52:	c1 e0 02             	shl    $0x2,%eax
80102b55:	03 45 e8             	add    -0x18(%ebp),%eax
80102b58:	8b 00                	mov    (%eax),%eax
80102b5a:	85 c0                	test   %eax,%eax
80102b5c:	74 50                	je     80102bae <itrunc+0x12e>
      {
	if(getBlkRef(a[j]) > 0)
80102b5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b61:	c1 e0 02             	shl    $0x2,%eax
80102b64:	03 45 e8             	add    -0x18(%ebp),%eax
80102b67:	8b 00                	mov    (%eax),%eax
80102b69:	89 04 24             	mov    %eax,(%esp)
80102b6c:	e8 73 0b 00 00       	call   801036e4 <getBlkRef>
80102b71:	85 c0                	test   %eax,%eax
80102b73:	7e 1d                	jle    80102b92 <itrunc+0x112>
	  updateBlkRef(a[j],-1);
80102b75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b78:	c1 e0 02             	shl    $0x2,%eax
80102b7b:	03 45 e8             	add    -0x18(%ebp),%eax
80102b7e:	8b 00                	mov    (%eax),%eax
80102b80:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102b87:	ff 
80102b88:	89 04 24             	mov    %eax,(%esp)
80102b8b:	e8 15 0a 00 00       	call   801035a5 <updateBlkRef>
80102b90:	eb 1c                	jmp    80102bae <itrunc+0x12e>
	else
	  bfree(ip->dev, a[j]);
80102b92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b95:	c1 e0 02             	shl    $0x2,%eax
80102b98:	03 45 e8             	add    -0x18(%ebp),%eax
80102b9b:	8b 10                	mov    (%eax),%edx
80102b9d:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba0:	8b 00                	mov    (%eax),%eax
80102ba2:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ba6:	89 04 24             	mov    %eax,(%esp)
80102ba9:	e8 a0 f7 ff ff       	call   8010234e <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102bae:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102bb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102bb5:	83 f8 7f             	cmp    $0x7f,%eax
80102bb8:	76 95                	jbe    80102b4f <itrunc+0xcf>
	  updateBlkRef(a[j],-1);
	else
	  bfree(ip->dev, a[j]);
      }
    }
    brelse(bp);
80102bba:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bbd:	89 04 24             	mov    %eax,(%esp)
80102bc0:	e8 52 d6 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102bc5:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc8:	8b 50 4c             	mov    0x4c(%eax),%edx
80102bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80102bce:	8b 00                	mov    (%eax),%eax
80102bd0:	89 54 24 04          	mov    %edx,0x4(%esp)
80102bd4:	89 04 24             	mov    %eax,(%esp)
80102bd7:	e8 72 f7 ff ff       	call   8010234e <bfree>
    ip->addrs[NDIRECT] = 0;
80102bdc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bdf:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102be6:	8b 45 08             	mov    0x8(%ebp),%eax
80102be9:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102bf0:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf3:	89 04 24             	mov    %eax,(%esp)
80102bf6:	e8 25 f9 ff ff       	call   80102520 <iupdate>
}
80102bfb:	c9                   	leave  
80102bfc:	c3                   	ret    

80102bfd <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102c00:	8b 45 08             	mov    0x8(%ebp),%eax
80102c03:	8b 00                	mov    (%eax),%eax
80102c05:	89 c2                	mov    %eax,%edx
80102c07:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c0a:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80102c0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102c10:	8b 50 04             	mov    0x4(%eax),%edx
80102c13:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c16:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80102c19:	8b 45 08             	mov    0x8(%ebp),%eax
80102c1c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102c20:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c23:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102c26:	8b 45 08             	mov    0x8(%ebp),%eax
80102c29:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102c2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c30:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102c34:	8b 45 08             	mov    0x8(%ebp),%eax
80102c37:	8b 50 18             	mov    0x18(%eax),%edx
80102c3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c3d:	89 50 10             	mov    %edx,0x10(%eax)
}
80102c40:	5d                   	pop    %ebp
80102c41:	c3                   	ret    

80102c42 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102c42:	55                   	push   %ebp
80102c43:	89 e5                	mov    %esp,%ebp
80102c45:	53                   	push   %ebx
80102c46:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102c49:	8b 45 08             	mov    0x8(%ebp),%eax
80102c4c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102c50:	66 83 f8 03          	cmp    $0x3,%ax
80102c54:	75 60                	jne    80102cb6 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102c56:	8b 45 08             	mov    0x8(%ebp),%eax
80102c59:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c5d:	66 85 c0             	test   %ax,%ax
80102c60:	78 20                	js     80102c82 <readi+0x40>
80102c62:	8b 45 08             	mov    0x8(%ebp),%eax
80102c65:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c69:	66 83 f8 09          	cmp    $0x9,%ax
80102c6d:	7f 13                	jg     80102c82 <readi+0x40>
80102c6f:	8b 45 08             	mov    0x8(%ebp),%eax
80102c72:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c76:	98                   	cwtl   
80102c77:	8b 04 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%eax
80102c7e:	85 c0                	test   %eax,%eax
80102c80:	75 0a                	jne    80102c8c <readi+0x4a>
      return -1;
80102c82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c87:	e9 1b 01 00 00       	jmp    80102da7 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102c8c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c8f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c93:	98                   	cwtl   
80102c94:	8b 14 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%edx
80102c9b:	8b 45 14             	mov    0x14(%ebp),%eax
80102c9e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ca2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ca5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ca9:	8b 45 08             	mov    0x8(%ebp),%eax
80102cac:	89 04 24             	mov    %eax,(%esp)
80102caf:	ff d2                	call   *%edx
80102cb1:	e9 f1 00 00 00       	jmp    80102da7 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102cb6:	8b 45 08             	mov    0x8(%ebp),%eax
80102cb9:	8b 40 18             	mov    0x18(%eax),%eax
80102cbc:	3b 45 10             	cmp    0x10(%ebp),%eax
80102cbf:	72 0d                	jb     80102cce <readi+0x8c>
80102cc1:	8b 45 14             	mov    0x14(%ebp),%eax
80102cc4:	8b 55 10             	mov    0x10(%ebp),%edx
80102cc7:	01 d0                	add    %edx,%eax
80102cc9:	3b 45 10             	cmp    0x10(%ebp),%eax
80102ccc:	73 0a                	jae    80102cd8 <readi+0x96>
    return -1;
80102cce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102cd3:	e9 cf 00 00 00       	jmp    80102da7 <readi+0x165>
  if(off + n > ip->size)
80102cd8:	8b 45 14             	mov    0x14(%ebp),%eax
80102cdb:	8b 55 10             	mov    0x10(%ebp),%edx
80102cde:	01 c2                	add    %eax,%edx
80102ce0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce3:	8b 40 18             	mov    0x18(%eax),%eax
80102ce6:	39 c2                	cmp    %eax,%edx
80102ce8:	76 0c                	jbe    80102cf6 <readi+0xb4>
    n = ip->size - off;
80102cea:	8b 45 08             	mov    0x8(%ebp),%eax
80102ced:	8b 40 18             	mov    0x18(%eax),%eax
80102cf0:	2b 45 10             	sub    0x10(%ebp),%eax
80102cf3:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102cf6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cfd:	e9 96 00 00 00       	jmp    80102d98 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102d02:	8b 45 10             	mov    0x10(%ebp),%eax
80102d05:	c1 e8 09             	shr    $0x9,%eax
80102d08:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d0c:	8b 45 08             	mov    0x8(%ebp),%eax
80102d0f:	89 04 24             	mov    %eax,(%esp)
80102d12:	e8 67 fc ff ff       	call   8010297e <bmap>
80102d17:	8b 55 08             	mov    0x8(%ebp),%edx
80102d1a:	8b 12                	mov    (%edx),%edx
80102d1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d20:	89 14 24             	mov    %edx,(%esp)
80102d23:	e8 7e d4 ff ff       	call   801001a6 <bread>
80102d28:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102d2b:	8b 45 10             	mov    0x10(%ebp),%eax
80102d2e:	89 c2                	mov    %eax,%edx
80102d30:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102d36:	b8 00 02 00 00       	mov    $0x200,%eax
80102d3b:	89 c1                	mov    %eax,%ecx
80102d3d:	29 d1                	sub    %edx,%ecx
80102d3f:	89 ca                	mov    %ecx,%edx
80102d41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d44:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102d47:	89 cb                	mov    %ecx,%ebx
80102d49:	29 c3                	sub    %eax,%ebx
80102d4b:	89 d8                	mov    %ebx,%eax
80102d4d:	39 c2                	cmp    %eax,%edx
80102d4f:	0f 46 c2             	cmovbe %edx,%eax
80102d52:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d58:	8d 50 18             	lea    0x18(%eax),%edx
80102d5b:	8b 45 10             	mov    0x10(%ebp),%eax
80102d5e:	25 ff 01 00 00       	and    $0x1ff,%eax
80102d63:	01 c2                	add    %eax,%edx
80102d65:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d68:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d6c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102d70:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d73:	89 04 24             	mov    %eax,(%esp)
80102d76:	e8 82 34 00 00       	call   801061fd <memmove>
    brelse(bp);
80102d7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d7e:	89 04 24             	mov    %eax,(%esp)
80102d81:	e8 91 d4 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102d86:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d89:	01 45 f4             	add    %eax,-0xc(%ebp)
80102d8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d8f:	01 45 10             	add    %eax,0x10(%ebp)
80102d92:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d95:	01 45 0c             	add    %eax,0xc(%ebp)
80102d98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d9b:	3b 45 14             	cmp    0x14(%ebp),%eax
80102d9e:	0f 82 5e ff ff ff    	jb     80102d02 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102da4:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102da7:	83 c4 24             	add    $0x24,%esp
80102daa:	5b                   	pop    %ebx
80102dab:	5d                   	pop    %ebp
80102dac:	c3                   	ret    

80102dad <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102dad:	55                   	push   %ebp
80102dae:	89 e5                	mov    %esp,%ebp
80102db0:	53                   	push   %ebx
80102db1:	81 ec 34 02 00 00    	sub    $0x234,%esp
  uint tot, m,ref;
  struct buf *bp;

  if(ip->type == T_DEV){
80102db7:	8b 45 08             	mov    0x8(%ebp),%eax
80102dba:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102dbe:	66 83 f8 03          	cmp    $0x3,%ax
80102dc2:	75 60                	jne    80102e24 <writei+0x77>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80102dc7:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102dcb:	66 85 c0             	test   %ax,%ax
80102dce:	78 20                	js     80102df0 <writei+0x43>
80102dd0:	8b 45 08             	mov    0x8(%ebp),%eax
80102dd3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102dd7:	66 83 f8 09          	cmp    $0x9,%ax
80102ddb:	7f 13                	jg     80102df0 <writei+0x43>
80102ddd:	8b 45 08             	mov    0x8(%ebp),%eax
80102de0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102de4:	98                   	cwtl   
80102de5:	8b 04 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%eax
80102dec:	85 c0                	test   %eax,%eax
80102dee:	75 0a                	jne    80102dfa <writei+0x4d>
      return -1;
80102df0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102df5:	e9 08 02 00 00       	jmp    80103002 <writei+0x255>
    return devsw[ip->major].write(ip, src, n);
80102dfa:	8b 45 08             	mov    0x8(%ebp),%eax
80102dfd:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102e01:	98                   	cwtl   
80102e02:	8b 14 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%edx
80102e09:	8b 45 14             	mov    0x14(%ebp),%eax
80102e0c:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e10:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e13:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e17:	8b 45 08             	mov    0x8(%ebp),%eax
80102e1a:	89 04 24             	mov    %eax,(%esp)
80102e1d:	ff d2                	call   *%edx
80102e1f:	e9 de 01 00 00       	jmp    80103002 <writei+0x255>
  }

  if(off > ip->size || off + n < off)
80102e24:	8b 45 08             	mov    0x8(%ebp),%eax
80102e27:	8b 40 18             	mov    0x18(%eax),%eax
80102e2a:	3b 45 10             	cmp    0x10(%ebp),%eax
80102e2d:	72 0d                	jb     80102e3c <writei+0x8f>
80102e2f:	8b 45 14             	mov    0x14(%ebp),%eax
80102e32:	8b 55 10             	mov    0x10(%ebp),%edx
80102e35:	01 d0                	add    %edx,%eax
80102e37:	3b 45 10             	cmp    0x10(%ebp),%eax
80102e3a:	73 0a                	jae    80102e46 <writei+0x99>
    return -1;
80102e3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e41:	e9 bc 01 00 00       	jmp    80103002 <writei+0x255>
  if(off + n > MAXFILE*BSIZE)
80102e46:	8b 45 14             	mov    0x14(%ebp),%eax
80102e49:	8b 55 10             	mov    0x10(%ebp),%edx
80102e4c:	01 d0                	add    %edx,%eax
80102e4e:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102e53:	76 0a                	jbe    80102e5f <writei+0xb2>
    return -1;
80102e55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e5a:	e9 a3 01 00 00       	jmp    80103002 <writei+0x255>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102e5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102e66:	e9 63 01 00 00       	jmp    80102fce <writei+0x221>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102e6b:	8b 45 10             	mov    0x10(%ebp),%eax
80102e6e:	c1 e8 09             	shr    $0x9,%eax
80102e71:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e75:	8b 45 08             	mov    0x8(%ebp),%eax
80102e78:	89 04 24             	mov    %eax,(%esp)
80102e7b:	e8 fe fa ff ff       	call   8010297e <bmap>
80102e80:	8b 55 08             	mov    0x8(%ebp),%edx
80102e83:	8b 12                	mov    (%edx),%edx
80102e85:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e89:	89 14 24             	mov    %edx,(%esp)
80102e8c:	e8 15 d3 ff ff       	call   801001a6 <bread>
80102e91:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((ref = getBlkRef(bp->sector)) > 0)
80102e94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e97:	8b 40 08             	mov    0x8(%eax),%eax
80102e9a:	89 04 24             	mov    %eax,(%esp)
80102e9d:	e8 42 08 00 00       	call   801036e4 <getBlkRef>
80102ea2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80102ea5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102ea9:	0f 84 a7 00 00 00    	je     80102f56 <writei+0x1a9>
    {
      uint old = bp->sector;
80102eaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102eb2:	8b 40 08             	mov    0x8(%eax),%eax
80102eb5:	89 45 e8             	mov    %eax,-0x18(%ebp)
      updateBlkRef(old,-1);
80102eb8:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102ebf:	ff 
80102ec0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102ec3:	89 04 24             	mov    %eax,(%esp)
80102ec6:	e8 da 06 00 00       	call   801035a5 <updateBlkRef>
      char tmp[BSIZE];
      memmove(tmp,bp->data, BSIZE);
80102ecb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ece:	83 c0 18             	add    $0x18,%eax
80102ed1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80102ed8:	00 
80102ed9:	89 44 24 04          	mov    %eax,0x4(%esp)
80102edd:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
80102ee3:	89 04 24             	mov    %eax,(%esp)
80102ee6:	e8 12 33 00 00       	call   801061fd <memmove>
      brelse(bp);
80102eeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102eee:	89 04 24             	mov    %eax,(%esp)
80102ef1:	e8 21 d3 ff ff       	call   80100217 <brelse>
      uint new = balloc(ip->dev);
80102ef6:	8b 45 08             	mov    0x8(%ebp),%eax
80102ef9:	8b 00                	mov    (%eax),%eax
80102efb:	89 04 24             	mov    %eax,(%esp)
80102efe:	e8 f4 f2 ff ff       	call   801021f7 <balloc>
80102f03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      replaceBlk(ip,old,new);
80102f06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f09:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102f10:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f14:	8b 45 08             	mov    0x8(%ebp),%eax
80102f17:	89 04 24             	mov    %eax,(%esp)
80102f1a:	e8 79 f1 ff ff       	call   80102098 <replaceBlk>
      bp = bread(ip->dev,new);
80102f1f:	8b 45 08             	mov    0x8(%ebp),%eax
80102f22:	8b 00                	mov    (%eax),%eax
80102f24:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102f27:	89 54 24 04          	mov    %edx,0x4(%esp)
80102f2b:	89 04 24             	mov    %eax,(%esp)
80102f2e:	e8 73 d2 ff ff       	call   801001a6 <bread>
80102f33:	89 45 f0             	mov    %eax,-0x10(%ebp)
      memmove(bp->data,tmp, BSIZE);
80102f36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f39:	8d 50 18             	lea    0x18(%eax),%edx
80102f3c:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80102f43:	00 
80102f44:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
80102f4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f4e:	89 14 24             	mov    %edx,(%esp)
80102f51:	e8 a7 32 00 00       	call   801061fd <memmove>
    }
    m = min(n - tot, BSIZE - off%BSIZE);
80102f56:	8b 45 10             	mov    0x10(%ebp),%eax
80102f59:	89 c2                	mov    %eax,%edx
80102f5b:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102f61:	b8 00 02 00 00       	mov    $0x200,%eax
80102f66:	89 c1                	mov    %eax,%ecx
80102f68:	29 d1                	sub    %edx,%ecx
80102f6a:	89 ca                	mov    %ecx,%edx
80102f6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f6f:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102f72:	89 cb                	mov    %ecx,%ebx
80102f74:	29 c3                	sub    %eax,%ebx
80102f76:	89 d8                	mov    %ebx,%eax
80102f78:	39 c2                	cmp    %eax,%edx
80102f7a:	0f 46 c2             	cmovbe %edx,%eax
80102f7d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102f80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f83:	8d 50 18             	lea    0x18(%eax),%edx
80102f86:	8b 45 10             	mov    0x10(%ebp),%eax
80102f89:	25 ff 01 00 00       	and    $0x1ff,%eax
80102f8e:	01 c2                	add    %eax,%edx
80102f90:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f93:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f97:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f9e:	89 14 24             	mov    %edx,(%esp)
80102fa1:	e8 57 32 00 00       	call   801061fd <memmove>
    log_write(bp);
80102fa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102fa9:	89 04 24             	mov    %eax,(%esp)
80102fac:	e8 45 16 00 00       	call   801045f6 <log_write>
    brelse(bp);
80102fb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102fb4:	89 04 24             	mov    %eax,(%esp)
80102fb7:	e8 5b d2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102fbc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102fbf:	01 45 f4             	add    %eax,-0xc(%ebp)
80102fc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102fc5:	01 45 10             	add    %eax,0x10(%ebp)
80102fc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102fcb:	01 45 0c             	add    %eax,0xc(%ebp)
80102fce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fd1:	3b 45 14             	cmp    0x14(%ebp),%eax
80102fd4:	0f 82 91 fe ff ff    	jb     80102e6b <writei+0xbe>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102fda:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102fde:	74 1f                	je     80102fff <writei+0x252>
80102fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80102fe3:	8b 40 18             	mov    0x18(%eax),%eax
80102fe6:	3b 45 10             	cmp    0x10(%ebp),%eax
80102fe9:	73 14                	jae    80102fff <writei+0x252>
    ip->size = off;
80102feb:	8b 45 08             	mov    0x8(%ebp),%eax
80102fee:	8b 55 10             	mov    0x10(%ebp),%edx
80102ff1:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102ff4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ff7:	89 04 24             	mov    %eax,(%esp)
80102ffa:	e8 21 f5 ff ff       	call   80102520 <iupdate>
  }
  return n;
80102fff:	8b 45 14             	mov    0x14(%ebp),%eax
}
80103002:	81 c4 34 02 00 00    	add    $0x234,%esp
80103008:	5b                   	pop    %ebx
80103009:	5d                   	pop    %ebp
8010300a:	c3                   	ret    

8010300b <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010300b:	55                   	push   %ebp
8010300c:	89 e5                	mov    %esp,%ebp
8010300e:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80103011:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103018:	00 
80103019:	8b 45 0c             	mov    0xc(%ebp),%eax
8010301c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103020:	8b 45 08             	mov    0x8(%ebp),%eax
80103023:	89 04 24             	mov    %eax,(%esp)
80103026:	e8 76 32 00 00       	call   801062a1 <strncmp>
}
8010302b:	c9                   	leave  
8010302c:	c3                   	ret    

8010302d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
8010302d:	55                   	push   %ebp
8010302e:	89 e5                	mov    %esp,%ebp
80103030:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80103033:	8b 45 08             	mov    0x8(%ebp),%eax
80103036:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010303a:	66 83 f8 01          	cmp    $0x1,%ax
8010303e:	74 0c                	je     8010304c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80103040:	c7 04 24 9d 98 10 80 	movl   $0x8010989d,(%esp)
80103047:	e8 f1 d4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010304c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103053:	e9 87 00 00 00       	jmp    801030df <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80103058:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010305f:	00 
80103060:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103063:	89 44 24 08          	mov    %eax,0x8(%esp)
80103067:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010306a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010306e:	8b 45 08             	mov    0x8(%ebp),%eax
80103071:	89 04 24             	mov    %eax,(%esp)
80103074:	e8 c9 fb ff ff       	call   80102c42 <readi>
80103079:	83 f8 10             	cmp    $0x10,%eax
8010307c:	74 0c                	je     8010308a <dirlookup+0x5d>
      panic("dirlink read");
8010307e:	c7 04 24 af 98 10 80 	movl   $0x801098af,(%esp)
80103085:	e8 b3 d4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010308a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010308e:	66 85 c0             	test   %ax,%ax
80103091:	74 47                	je     801030da <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80103093:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103096:	83 c0 02             	add    $0x2,%eax
80103099:	89 44 24 04          	mov    %eax,0x4(%esp)
8010309d:	8b 45 0c             	mov    0xc(%ebp),%eax
801030a0:	89 04 24             	mov    %eax,(%esp)
801030a3:	e8 63 ff ff ff       	call   8010300b <namecmp>
801030a8:	85 c0                	test   %eax,%eax
801030aa:	75 2f                	jne    801030db <dirlookup+0xae>
      // entry matches path element
      if(poff)
801030ac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801030b0:	74 08                	je     801030ba <dirlookup+0x8d>
        *poff = off;
801030b2:	8b 45 10             	mov    0x10(%ebp),%eax
801030b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801030b8:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801030ba:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801030be:	0f b7 c0             	movzwl %ax,%eax
801030c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801030c4:	8b 45 08             	mov    0x8(%ebp),%eax
801030c7:	8b 00                	mov    (%eax),%eax
801030c9:	8b 55 f0             	mov    -0x10(%ebp),%edx
801030cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801030d0:	89 04 24             	mov    %eax,(%esp)
801030d3:	e8 00 f5 ff ff       	call   801025d8 <iget>
801030d8:	eb 19                	jmp    801030f3 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
801030da:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801030db:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801030df:	8b 45 08             	mov    0x8(%ebp),%eax
801030e2:	8b 40 18             	mov    0x18(%eax),%eax
801030e5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801030e8:	0f 87 6a ff ff ff    	ja     80103058 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801030ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030f3:	c9                   	leave  
801030f4:	c3                   	ret    

801030f5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801030f5:	55                   	push   %ebp
801030f6:	89 e5                	mov    %esp,%ebp
801030f8:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801030fb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103102:	00 
80103103:	8b 45 0c             	mov    0xc(%ebp),%eax
80103106:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310a:	8b 45 08             	mov    0x8(%ebp),%eax
8010310d:	89 04 24             	mov    %eax,(%esp)
80103110:	e8 18 ff ff ff       	call   8010302d <dirlookup>
80103115:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103118:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010311c:	74 15                	je     80103133 <dirlink+0x3e>
    iput(ip);
8010311e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103121:	89 04 24             	mov    %eax,(%esp)
80103124:	e8 66 f7 ff ff       	call   8010288f <iput>
    return -1;
80103129:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010312e:	e9 b8 00 00 00       	jmp    801031eb <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80103133:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010313a:	eb 44                	jmp    80103180 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010313c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010313f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80103146:	00 
80103147:	89 44 24 08          	mov    %eax,0x8(%esp)
8010314b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010314e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103152:	8b 45 08             	mov    0x8(%ebp),%eax
80103155:	89 04 24             	mov    %eax,(%esp)
80103158:	e8 e5 fa ff ff       	call   80102c42 <readi>
8010315d:	83 f8 10             	cmp    $0x10,%eax
80103160:	74 0c                	je     8010316e <dirlink+0x79>
      panic("dirlink read");
80103162:	c7 04 24 af 98 10 80 	movl   $0x801098af,(%esp)
80103169:	e8 cf d3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010316e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80103172:	66 85 c0             	test   %ax,%ax
80103175:	74 18                	je     8010318f <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80103177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010317a:	83 c0 10             	add    $0x10,%eax
8010317d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103180:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103183:	8b 45 08             	mov    0x8(%ebp),%eax
80103186:	8b 40 18             	mov    0x18(%eax),%eax
80103189:	39 c2                	cmp    %eax,%edx
8010318b:	72 af                	jb     8010313c <dirlink+0x47>
8010318d:	eb 01                	jmp    80103190 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010318f:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80103190:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103197:	00 
80103198:	8b 45 0c             	mov    0xc(%ebp),%eax
8010319b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010319f:	8d 45 e0             	lea    -0x20(%ebp),%eax
801031a2:	83 c0 02             	add    $0x2,%eax
801031a5:	89 04 24             	mov    %eax,(%esp)
801031a8:	e8 4c 31 00 00       	call   801062f9 <strncpy>
  de.inum = inum;
801031ad:	8b 45 10             	mov    0x10(%ebp),%eax
801031b0:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801031b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031b7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801031be:	00 
801031bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801031c3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801031c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801031ca:	8b 45 08             	mov    0x8(%ebp),%eax
801031cd:	89 04 24             	mov    %eax,(%esp)
801031d0:	e8 d8 fb ff ff       	call   80102dad <writei>
801031d5:	83 f8 10             	cmp    $0x10,%eax
801031d8:	74 0c                	je     801031e6 <dirlink+0xf1>
    panic("dirlink");
801031da:	c7 04 24 bc 98 10 80 	movl   $0x801098bc,(%esp)
801031e1:	e8 57 d3 ff ff       	call   8010053d <panic>
  
  return 0;
801031e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801031eb:	c9                   	leave  
801031ec:	c3                   	ret    

801031ed <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801031ed:	55                   	push   %ebp
801031ee:	89 e5                	mov    %esp,%ebp
801031f0:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801031f3:	eb 04                	jmp    801031f9 <skipelem+0xc>
    path++;
801031f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801031f9:	8b 45 08             	mov    0x8(%ebp),%eax
801031fc:	0f b6 00             	movzbl (%eax),%eax
801031ff:	3c 2f                	cmp    $0x2f,%al
80103201:	74 f2                	je     801031f5 <skipelem+0x8>
    path++;
  if(*path == 0)
80103203:	8b 45 08             	mov    0x8(%ebp),%eax
80103206:	0f b6 00             	movzbl (%eax),%eax
80103209:	84 c0                	test   %al,%al
8010320b:	75 0a                	jne    80103217 <skipelem+0x2a>
    return 0;
8010320d:	b8 00 00 00 00       	mov    $0x0,%eax
80103212:	e9 86 00 00 00       	jmp    8010329d <skipelem+0xb0>
  s = path;
80103217:	8b 45 08             	mov    0x8(%ebp),%eax
8010321a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010321d:	eb 04                	jmp    80103223 <skipelem+0x36>
    path++;
8010321f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80103223:	8b 45 08             	mov    0x8(%ebp),%eax
80103226:	0f b6 00             	movzbl (%eax),%eax
80103229:	3c 2f                	cmp    $0x2f,%al
8010322b:	74 0a                	je     80103237 <skipelem+0x4a>
8010322d:	8b 45 08             	mov    0x8(%ebp),%eax
80103230:	0f b6 00             	movzbl (%eax),%eax
80103233:	84 c0                	test   %al,%al
80103235:	75 e8                	jne    8010321f <skipelem+0x32>
    path++;
  len = path - s;
80103237:	8b 55 08             	mov    0x8(%ebp),%edx
8010323a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010323d:	89 d1                	mov    %edx,%ecx
8010323f:	29 c1                	sub    %eax,%ecx
80103241:	89 c8                	mov    %ecx,%eax
80103243:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80103246:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010324a:	7e 1c                	jle    80103268 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
8010324c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103253:	00 
80103254:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103257:	89 44 24 04          	mov    %eax,0x4(%esp)
8010325b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010325e:	89 04 24             	mov    %eax,(%esp)
80103261:	e8 97 2f 00 00       	call   801061fd <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80103266:	eb 28                	jmp    80103290 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80103268:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010326b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010326f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103272:	89 44 24 04          	mov    %eax,0x4(%esp)
80103276:	8b 45 0c             	mov    0xc(%ebp),%eax
80103279:	89 04 24             	mov    %eax,(%esp)
8010327c:	e8 7c 2f 00 00       	call   801061fd <memmove>
    name[len] = 0;
80103281:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103284:	03 45 0c             	add    0xc(%ebp),%eax
80103287:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010328a:	eb 04                	jmp    80103290 <skipelem+0xa3>
    path++;
8010328c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80103290:	8b 45 08             	mov    0x8(%ebp),%eax
80103293:	0f b6 00             	movzbl (%eax),%eax
80103296:	3c 2f                	cmp    $0x2f,%al
80103298:	74 f2                	je     8010328c <skipelem+0x9f>
    path++;
  return path;
8010329a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010329d:	c9                   	leave  
8010329e:	c3                   	ret    

8010329f <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010329f:	55                   	push   %ebp
801032a0:	89 e5                	mov    %esp,%ebp
801032a2:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801032a5:	8b 45 08             	mov    0x8(%ebp),%eax
801032a8:	0f b6 00             	movzbl (%eax),%eax
801032ab:	3c 2f                	cmp    $0x2f,%al
801032ad:	75 1c                	jne    801032cb <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801032af:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801032b6:	00 
801032b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032be:	e8 15 f3 ff ff       	call   801025d8 <iget>
801032c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801032c6:	e9 af 00 00 00       	jmp    8010337a <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801032cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801032d1:	8b 40 68             	mov    0x68(%eax),%eax
801032d4:	89 04 24             	mov    %eax,(%esp)
801032d7:	e8 ce f3 ff ff       	call   801026aa <idup>
801032dc:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801032df:	e9 96 00 00 00       	jmp    8010337a <namex+0xdb>
    ilock(ip);
801032e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032e7:	89 04 24             	mov    %eax,(%esp)
801032ea:	e8 ed f3 ff ff       	call   801026dc <ilock>
    if(ip->type != T_DIR){
801032ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032f2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801032f6:	66 83 f8 01          	cmp    $0x1,%ax
801032fa:	74 15                	je     80103311 <namex+0x72>
      iunlockput(ip);
801032fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032ff:	89 04 24             	mov    %eax,(%esp)
80103302:	e8 59 f6 ff ff       	call   80102960 <iunlockput>
      return 0;
80103307:	b8 00 00 00 00       	mov    $0x0,%eax
8010330c:	e9 a3 00 00 00       	jmp    801033b4 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80103311:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103315:	74 1d                	je     80103334 <namex+0x95>
80103317:	8b 45 08             	mov    0x8(%ebp),%eax
8010331a:	0f b6 00             	movzbl (%eax),%eax
8010331d:	84 c0                	test   %al,%al
8010331f:	75 13                	jne    80103334 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80103321:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103324:	89 04 24             	mov    %eax,(%esp)
80103327:	e8 fe f4 ff ff       	call   8010282a <iunlock>
      return ip;
8010332c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010332f:	e9 80 00 00 00       	jmp    801033b4 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80103334:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010333b:	00 
8010333c:	8b 45 10             	mov    0x10(%ebp),%eax
8010333f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103346:	89 04 24             	mov    %eax,(%esp)
80103349:	e8 df fc ff ff       	call   8010302d <dirlookup>
8010334e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103351:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103355:	75 12                	jne    80103369 <namex+0xca>
      iunlockput(ip);
80103357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010335a:	89 04 24             	mov    %eax,(%esp)
8010335d:	e8 fe f5 ff ff       	call   80102960 <iunlockput>
      return 0;
80103362:	b8 00 00 00 00       	mov    $0x0,%eax
80103367:	eb 4b                	jmp    801033b4 <namex+0x115>
    }
    iunlockput(ip);
80103369:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010336c:	89 04 24             	mov    %eax,(%esp)
8010336f:	e8 ec f5 ff ff       	call   80102960 <iunlockput>
    ip = next;
80103374:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103377:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010337a:	8b 45 10             	mov    0x10(%ebp),%eax
8010337d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103381:	8b 45 08             	mov    0x8(%ebp),%eax
80103384:	89 04 24             	mov    %eax,(%esp)
80103387:	e8 61 fe ff ff       	call   801031ed <skipelem>
8010338c:	89 45 08             	mov    %eax,0x8(%ebp)
8010338f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103393:	0f 85 4b ff ff ff    	jne    801032e4 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80103399:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010339d:	74 12                	je     801033b1 <namex+0x112>
    iput(ip);
8010339f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033a2:	89 04 24             	mov    %eax,(%esp)
801033a5:	e8 e5 f4 ff ff       	call   8010288f <iput>
    return 0;
801033aa:	b8 00 00 00 00       	mov    $0x0,%eax
801033af:	eb 03                	jmp    801033b4 <namex+0x115>
  }
  return ip;
801033b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801033b4:	c9                   	leave  
801033b5:	c3                   	ret    

801033b6 <namei>:

struct inode*
namei(char *path)
{
801033b6:	55                   	push   %ebp
801033b7:	89 e5                	mov    %esp,%ebp
801033b9:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801033bc:	8d 45 ea             	lea    -0x16(%ebp),%eax
801033bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801033c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033ca:	00 
801033cb:	8b 45 08             	mov    0x8(%ebp),%eax
801033ce:	89 04 24             	mov    %eax,(%esp)
801033d1:	e8 c9 fe ff ff       	call   8010329f <namex>
}
801033d6:	c9                   	leave  
801033d7:	c3                   	ret    

801033d8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801033d8:	55                   	push   %ebp
801033d9:	89 e5                	mov    %esp,%ebp
801033db:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801033de:	8b 45 0c             	mov    0xc(%ebp),%eax
801033e1:	89 44 24 08          	mov    %eax,0x8(%esp)
801033e5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801033ec:	00 
801033ed:	8b 45 08             	mov    0x8(%ebp),%eax
801033f0:	89 04 24             	mov    %eax,(%esp)
801033f3:	e8 a7 fe ff ff       	call   8010329f <namex>
}
801033f8:	c9                   	leave  
801033f9:	c3                   	ret    

801033fa <getNextInode>:

struct inode*
getNextInode(void)
{
801033fa:	55                   	push   %ebp
801033fb:	89 e5                	mov    %esp,%ebp
801033fd:	83 ec 48             	sub    $0x48,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80103400:	8d 45 d0             	lea    -0x30(%ebp),%eax
80103403:	89 44 24 04          	mov    %eax,0x4(%esp)
80103407:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010340e:	e8 4d ed ff ff       	call   80102160 <readsb>
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103413:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103418:	83 c0 01             	add    $0x1,%eax
8010341b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010341e:	eb 79                	jmp    80103499 <getNextInode+0x9f>
  {
    bp = bread(1, IBLOCK(inum));
80103420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103423:	c1 e8 03             	shr    $0x3,%eax
80103426:	83 c0 02             	add    $0x2,%eax
80103429:	89 44 24 04          	mov    %eax,0x4(%esp)
8010342d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103434:	e8 6d cd ff ff       	call   801001a6 <bread>
80103439:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010343c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010343f:	8d 50 18             	lea    0x18(%eax),%edx
80103442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103445:	83 e0 07             	and    $0x7,%eax
80103448:	c1 e0 06             	shl    $0x6,%eax
8010344b:	01 d0                	add    %edx,%eax
8010344d:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103450:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103453:	0f b7 00             	movzwl (%eax),%eax
80103456:	66 83 f8 02          	cmp    $0x2,%ax
8010345a:	75 2e                	jne    8010348a <getNextInode+0x90>
    {
      nextInum = inum;
8010345c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010345f:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      ip = iget(1,inum);
80103464:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103467:	89 44 24 04          	mov    %eax,0x4(%esp)
8010346b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103472:	e8 61 f1 ff ff       	call   801025d8 <iget>
80103477:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
8010347a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010347d:	89 04 24             	mov    %eax,(%esp)
80103480:	e8 92 cd ff ff       	call   80100217 <brelse>
      return ip;
80103485:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103488:	eb 22                	jmp    801034ac <getNextInode+0xb2>
    }
    brelse(bp);
8010348a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010348d:	89 04 24             	mov    %eax,(%esp)
80103490:	e8 82 cd ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103495:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103499:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010349c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010349f:	39 c2                	cmp    %eax,%edx
801034a1:	0f 82 79 ff ff ff    	jb     80103420 <getNextInode+0x26>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
801034a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034ac:	c9                   	leave  
801034ad:	c3                   	ret    

801034ae <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
801034ae:	55                   	push   %ebp
801034af:	89 e5                	mov    %esp,%ebp
801034b1:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801034b4:	e9 8d 00 00 00       	jmp    80103546 <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
801034b9:	8b 45 08             	mov    0x8(%ebp),%eax
801034bc:	8b 00                	mov    (%eax),%eax
801034be:	c1 e8 03             	shr    $0x3,%eax
801034c1:	83 c0 02             	add    $0x2,%eax
801034c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801034c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034cf:	e8 d2 cc ff ff       	call   801001a6 <bread>
801034d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
801034d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034da:	8d 50 18             	lea    0x18(%eax),%edx
801034dd:	8b 45 08             	mov    0x8(%ebp),%eax
801034e0:	8b 00                	mov    (%eax),%eax
801034e2:	83 e0 07             	and    $0x7,%eax
801034e5:	c1 e0 06             	shl    $0x6,%eax
801034e8:	01 d0                	add    %edx,%eax
801034ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
801034ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f0:	0f b7 00             	movzwl (%eax),%eax
801034f3:	66 83 f8 02          	cmp    $0x2,%ax
801034f7:	75 35                	jne    8010352e <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
801034f9:	8b 45 08             	mov    0x8(%ebp),%eax
801034fc:	8b 00                	mov    (%eax),%eax
801034fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80103502:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103509:	e8 ca f0 ff ff       	call   801025d8 <iget>
8010350e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
80103511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103514:	89 04 24             	mov    %eax,(%esp)
80103517:	e8 fb cc ff ff       	call   80100217 <brelse>
      (*prevInum)--;
8010351c:	8b 45 08             	mov    0x8(%ebp),%eax
8010351f:	8b 00                	mov    (%eax),%eax
80103521:	8d 50 ff             	lea    -0x1(%eax),%edx
80103524:	8b 45 08             	mov    0x8(%ebp),%eax
80103527:	89 10                	mov    %edx,(%eax)
      return ip;
80103529:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010352c:	eb 2f                	jmp    8010355d <getPrevInode+0xaf>
    }
    brelse(bp);
8010352e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103531:	89 04 24             	mov    %eax,(%esp)
80103534:	e8 de cc ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
80103539:	8b 45 08             	mov    0x8(%ebp),%eax
8010353c:	8b 00                	mov    (%eax),%eax
8010353e:	8d 50 ff             	lea    -0x1(%eax),%edx
80103541:	8b 45 08             	mov    0x8(%ebp),%eax
80103544:	89 10                	mov    %edx,(%eax)
80103546:	8b 45 08             	mov    0x8(%ebp),%eax
80103549:	8b 10                	mov    (%eax),%edx
8010354b:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103550:	39 c2                	cmp    %eax,%edx
80103552:	0f 8f 61 ff ff ff    	jg     801034b9 <getPrevInode+0xb>
      (*prevInum)--;
      return ip;
    }
    brelse(bp);
  }
  return 0;
80103558:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010355d:	c9                   	leave  
8010355e:	c3                   	ret    

8010355f <getRefCount>:

uint
getRefCount(uint ref)
{
8010355f:	55                   	push   %ebp
80103560:	89 e5                	mov    %esp,%ebp
80103562:	83 ec 38             	sub    $0x38,%esp
  if(refCount1==0)
80103565:	a1 a4 f8 10 80       	mov    0x8010f8a4,%eax
8010356a:	85 c0                	test   %eax,%eax
8010356c:	75 23                	jne    80103591 <getRefCount+0x32>
  {
    struct superblock sb;
    readsb(1,&sb);
8010356e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103571:	89 44 24 04          	mov    %eax,0x4(%esp)
80103575:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010357c:	e8 df eb ff ff       	call   80102160 <readsb>
    refCount1 = sb.refCount1;
80103581:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103584:	a3 a4 f8 10 80       	mov    %eax,0x8010f8a4
    refCount2 = sb.refCount2;
80103589:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010358c:	a3 a0 f8 10 80       	mov    %eax,0x8010f8a0
  }
  
  if(ref==1)
80103591:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
80103595:	75 07                	jne    8010359e <getRefCount+0x3f>
    return refCount1;
80103597:	a1 a4 f8 10 80       	mov    0x8010f8a4,%eax
8010359c:	eb 05                	jmp    801035a3 <getRefCount+0x44>
  else
    return refCount2;
8010359e:	a1 a0 f8 10 80       	mov    0x8010f8a0,%eax
}
801035a3:	c9                   	leave  
801035a4:	c3                   	ret    

801035a5 <updateBlkRef>:

void
updateBlkRef(uint sector, int flag)
{
801035a5:	55                   	push   %ebp
801035a6:	89 e5                	mov    %esp,%ebp
801035a8:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  if(sector < BSIZE)
801035ab:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801035b2:	0f 87 91 00 00 00    	ja     80103649 <updateBlkRef+0xa4>
  {
    bp = bread(1,getRefCount(1));
801035b8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035bf:	e8 9b ff ff ff       	call   8010355f <getRefCount>
801035c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801035c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035cf:	e8 d2 cb ff ff       	call   801001a6 <bread>
801035d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
801035d7:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
801035db:	75 1e                	jne    801035fb <updateBlkRef+0x56>
      bp->data[sector]++;
801035dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035e0:	03 45 08             	add    0x8(%ebp),%eax
801035e3:	83 c0 10             	add    $0x10,%eax
801035e6:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801035ea:	8d 50 01             	lea    0x1(%eax),%edx
801035ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035f0:	03 45 08             	add    0x8(%ebp),%eax
801035f3:	83 c0 10             	add    $0x10,%eax
801035f6:	88 50 08             	mov    %dl,0x8(%eax)
801035f9:	eb 33                	jmp    8010362e <updateBlkRef+0x89>
    else if(flag == -1)
801035fb:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801035ff:	75 2d                	jne    8010362e <updateBlkRef+0x89>
      if(bp->data[sector] > 0)
80103601:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103604:	03 45 08             	add    0x8(%ebp),%eax
80103607:	83 c0 10             	add    $0x10,%eax
8010360a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010360e:	84 c0                	test   %al,%al
80103610:	74 1c                	je     8010362e <updateBlkRef+0x89>
	bp->data[sector]--;
80103612:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103615:	03 45 08             	add    0x8(%ebp),%eax
80103618:	83 c0 10             	add    $0x10,%eax
8010361b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010361f:	8d 50 ff             	lea    -0x1(%eax),%edx
80103622:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103625:	03 45 08             	add    0x8(%ebp),%eax
80103628:	83 c0 10             	add    $0x10,%eax
8010362b:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
8010362e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103631:	89 04 24             	mov    %eax,(%esp)
80103634:	e8 a4 cb ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010363c:	89 04 24             	mov    %eax,(%esp)
8010363f:	e8 d3 cb ff ff       	call   80100217 <brelse>
80103644:	e9 99 00 00 00       	jmp    801036e2 <updateBlkRef+0x13d>
  }
  else if(sector < BSIZE*2)
80103649:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103650:	0f 87 8c 00 00 00    	ja     801036e2 <updateBlkRef+0x13d>
  {
    bp = bread(1,getRefCount(2));
80103656:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010365d:	e8 fd fe ff ff       	call   8010355f <getRefCount>
80103662:	89 44 24 04          	mov    %eax,0x4(%esp)
80103666:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010366d:	e8 34 cb ff ff       	call   801001a6 <bread>
80103672:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103675:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103679:	75 1c                	jne    80103697 <updateBlkRef+0xf2>
      bp->data[sector-BSIZE]++;
8010367b:	8b 45 08             	mov    0x8(%ebp),%eax
8010367e:	2d 00 02 00 00       	sub    $0x200,%eax
80103683:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103686:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010368b:	8d 4a 01             	lea    0x1(%edx),%ecx
8010368e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103691:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
80103695:	eb 35                	jmp    801036cc <updateBlkRef+0x127>
    else if(flag == -1)
80103697:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
8010369b:	75 2f                	jne    801036cc <updateBlkRef+0x127>
      if(bp->data[sector-BSIZE] > 0)
8010369d:	8b 45 08             	mov    0x8(%ebp),%eax
801036a0:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
801036a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036a9:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
801036ae:	84 c0                	test   %al,%al
801036b0:	74 1a                	je     801036cc <updateBlkRef+0x127>
	bp->data[sector-BSIZE]--;
801036b2:	8b 45 08             	mov    0x8(%ebp),%eax
801036b5:	2d 00 02 00 00       	sub    $0x200,%eax
801036ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036bd:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801036c2:	8d 4a ff             	lea    -0x1(%edx),%ecx
801036c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036c8:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
801036cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036cf:	89 04 24             	mov    %eax,(%esp)
801036d2:	e8 06 cb ff ff       	call   801001dd <bwrite>
    brelse(bp);
801036d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036da:	89 04 24             	mov    %eax,(%esp)
801036dd:	e8 35 cb ff ff       	call   80100217 <brelse>
  }  
}
801036e2:	c9                   	leave  
801036e3:	c3                   	ret    

801036e4 <getBlkRef>:

int
getBlkRef(uint sector)
{
801036e4:	55                   	push   %ebp
801036e5:	89 e5                	mov    %esp,%ebp
801036e7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1,offset = 0;
801036ea:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
801036f1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  if(sector < BSIZE)
801036f8:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801036ff:	77 21                	ja     80103722 <getBlkRef+0x3e>
    bp = bread(1,getRefCount(1));
80103701:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103708:	e8 52 fe ff ff       	call   8010355f <getRefCount>
8010370d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103711:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103718:	e8 89 ca ff ff       	call   801001a6 <bread>
8010371d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103720:	eb 2f                	jmp    80103751 <getBlkRef+0x6d>
  else if(sector < BSIZE*2)
80103722:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103729:	77 26                	ja     80103751 <getBlkRef+0x6d>
  {
    bp = bread(1,getRefCount(2));
8010372b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103732:	e8 28 fe ff ff       	call   8010355f <getRefCount>
80103737:	89 44 24 04          	mov    %eax,0x4(%esp)
8010373b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103742:	e8 5f ca ff ff       	call   801001a6 <bread>
80103747:	89 45 f4             	mov    %eax,-0xc(%ebp)
    offset = BSIZE;
8010374a:	c7 45 f0 00 02 00 00 	movl   $0x200,-0x10(%ebp)
  }
  ret = (uchar)bp->data[sector-offset];
80103751:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103754:	8b 55 08             	mov    0x8(%ebp),%edx
80103757:	29 c2                	sub    %eax,%edx
80103759:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010375c:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
80103761:	0f b6 c0             	movzbl %al,%eax
80103764:	89 45 ec             	mov    %eax,-0x14(%ebp)
  brelse(bp);
80103767:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010376a:	89 04 24             	mov    %eax,(%esp)
8010376d:	e8 a5 ca ff ff       	call   80100217 <brelse>
  return ret;
80103772:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80103775:	c9                   	leave  
80103776:	c3                   	ret    

80103777 <zeroNextInum>:

void
zeroNextInum(void)
{
80103777:	55                   	push   %ebp
80103778:	89 e5                	mov    %esp,%ebp
  nextInum = 0;
8010377a:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
80103781:	00 00 00 
}
80103784:	5d                   	pop    %ebp
80103785:	c3                   	ret    
	...

80103788 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103788:	55                   	push   %ebp
80103789:	89 e5                	mov    %esp,%ebp
8010378b:	53                   	push   %ebx
8010378c:	83 ec 14             	sub    $0x14,%esp
8010378f:	8b 45 08             	mov    0x8(%ebp),%eax
80103792:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103796:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010379a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010379e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801037a2:	ec                   	in     (%dx),%al
801037a3:	89 c3                	mov    %eax,%ebx
801037a5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801037a8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801037ac:	83 c4 14             	add    $0x14,%esp
801037af:	5b                   	pop    %ebx
801037b0:	5d                   	pop    %ebp
801037b1:	c3                   	ret    

801037b2 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801037b2:	55                   	push   %ebp
801037b3:	89 e5                	mov    %esp,%ebp
801037b5:	57                   	push   %edi
801037b6:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801037b7:	8b 55 08             	mov    0x8(%ebp),%edx
801037ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801037bd:	8b 45 10             	mov    0x10(%ebp),%eax
801037c0:	89 cb                	mov    %ecx,%ebx
801037c2:	89 df                	mov    %ebx,%edi
801037c4:	89 c1                	mov    %eax,%ecx
801037c6:	fc                   	cld    
801037c7:	f3 6d                	rep insl (%dx),%es:(%edi)
801037c9:	89 c8                	mov    %ecx,%eax
801037cb:	89 fb                	mov    %edi,%ebx
801037cd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801037d0:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801037d3:	5b                   	pop    %ebx
801037d4:	5f                   	pop    %edi
801037d5:	5d                   	pop    %ebp
801037d6:	c3                   	ret    

801037d7 <outb>:

static inline void
outb(ushort port, uchar data)
{
801037d7:	55                   	push   %ebp
801037d8:	89 e5                	mov    %esp,%ebp
801037da:	83 ec 08             	sub    $0x8,%esp
801037dd:	8b 55 08             	mov    0x8(%ebp),%edx
801037e0:	8b 45 0c             	mov    0xc(%ebp),%eax
801037e3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801037e7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801037ea:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801037ee:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801037f2:	ee                   	out    %al,(%dx)
}
801037f3:	c9                   	leave  
801037f4:	c3                   	ret    

801037f5 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801037f5:	55                   	push   %ebp
801037f6:	89 e5                	mov    %esp,%ebp
801037f8:	56                   	push   %esi
801037f9:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801037fa:	8b 55 08             	mov    0x8(%ebp),%edx
801037fd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103800:	8b 45 10             	mov    0x10(%ebp),%eax
80103803:	89 cb                	mov    %ecx,%ebx
80103805:	89 de                	mov    %ebx,%esi
80103807:	89 c1                	mov    %eax,%ecx
80103809:	fc                   	cld    
8010380a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010380c:	89 c8                	mov    %ecx,%eax
8010380e:	89 f3                	mov    %esi,%ebx
80103810:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103813:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103816:	5b                   	pop    %ebx
80103817:	5e                   	pop    %esi
80103818:	5d                   	pop    %ebp
80103819:	c3                   	ret    

8010381a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010381a:	55                   	push   %ebp
8010381b:	89 e5                	mov    %esp,%ebp
8010381d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80103820:	90                   	nop
80103821:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103828:	e8 5b ff ff ff       	call   80103788 <inb>
8010382d:	0f b6 c0             	movzbl %al,%eax
80103830:	89 45 fc             	mov    %eax,-0x4(%ebp)
80103833:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103836:	25 c0 00 00 00       	and    $0xc0,%eax
8010383b:	83 f8 40             	cmp    $0x40,%eax
8010383e:	75 e1                	jne    80103821 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80103840:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103844:	74 11                	je     80103857 <idewait+0x3d>
80103846:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103849:	83 e0 21             	and    $0x21,%eax
8010384c:	85 c0                	test   %eax,%eax
8010384e:	74 07                	je     80103857 <idewait+0x3d>
    return -1;
80103850:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103855:	eb 05                	jmp    8010385c <idewait+0x42>
  return 0;
80103857:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010385c:	c9                   	leave  
8010385d:	c3                   	ret    

8010385e <ideinit>:

void
ideinit(void)
{
8010385e:	55                   	push   %ebp
8010385f:	89 e5                	mov    %esp,%ebp
80103861:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80103864:	c7 44 24 04 c4 98 10 	movl   $0x801098c4,0x4(%esp)
8010386b:	80 
8010386c:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103873:	e8 42 26 00 00       	call   80105eba <initlock>
  picenable(IRQ_IDE);
80103878:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010387f:	e8 75 15 00 00       	call   80104df9 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80103884:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80103889:	83 e8 01             	sub    $0x1,%eax
8010388c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103890:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103897:	e8 12 04 00 00       	call   80103cae <ioapicenable>
  idewait(0);
8010389c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801038a3:	e8 72 ff ff ff       	call   8010381a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801038a8:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801038af:	00 
801038b0:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801038b7:	e8 1b ff ff ff       	call   801037d7 <outb>
  for(i=0; i<1000; i++){
801038bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801038c3:	eb 20                	jmp    801038e5 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801038c5:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801038cc:	e8 b7 fe ff ff       	call   80103788 <inb>
801038d1:	84 c0                	test   %al,%al
801038d3:	74 0c                	je     801038e1 <ideinit+0x83>
      havedisk1 = 1;
801038d5:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
801038dc:	00 00 00 
      break;
801038df:	eb 0d                	jmp    801038ee <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801038e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801038e5:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801038ec:	7e d7                	jle    801038c5 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801038ee:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801038f5:	00 
801038f6:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801038fd:	e8 d5 fe ff ff       	call   801037d7 <outb>
}
80103902:	c9                   	leave  
80103903:	c3                   	ret    

80103904 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103904:	55                   	push   %ebp
80103905:	89 e5                	mov    %esp,%ebp
80103907:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010390a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010390e:	75 0c                	jne    8010391c <idestart+0x18>
    panic("idestart");
80103910:	c7 04 24 c8 98 10 80 	movl   $0x801098c8,(%esp)
80103917:	e8 21 cc ff ff       	call   8010053d <panic>

  idewait(0);
8010391c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103923:	e8 f2 fe ff ff       	call   8010381a <idewait>
  outb(0x3f6, 0);  // generate interrupt
80103928:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010392f:	00 
80103930:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80103937:	e8 9b fe ff ff       	call   801037d7 <outb>
  outb(0x1f2, 1);  // number of sectors
8010393c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103943:	00 
80103944:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010394b:	e8 87 fe ff ff       	call   801037d7 <outb>
  outb(0x1f3, b->sector & 0xff);
80103950:	8b 45 08             	mov    0x8(%ebp),%eax
80103953:	8b 40 08             	mov    0x8(%eax),%eax
80103956:	0f b6 c0             	movzbl %al,%eax
80103959:	89 44 24 04          	mov    %eax,0x4(%esp)
8010395d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80103964:	e8 6e fe ff ff       	call   801037d7 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80103969:	8b 45 08             	mov    0x8(%ebp),%eax
8010396c:	8b 40 08             	mov    0x8(%eax),%eax
8010396f:	c1 e8 08             	shr    $0x8,%eax
80103972:	0f b6 c0             	movzbl %al,%eax
80103975:	89 44 24 04          	mov    %eax,0x4(%esp)
80103979:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80103980:	e8 52 fe ff ff       	call   801037d7 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80103985:	8b 45 08             	mov    0x8(%ebp),%eax
80103988:	8b 40 08             	mov    0x8(%eax),%eax
8010398b:	c1 e8 10             	shr    $0x10,%eax
8010398e:	0f b6 c0             	movzbl %al,%eax
80103991:	89 44 24 04          	mov    %eax,0x4(%esp)
80103995:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010399c:	e8 36 fe ff ff       	call   801037d7 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801039a1:	8b 45 08             	mov    0x8(%ebp),%eax
801039a4:	8b 40 04             	mov    0x4(%eax),%eax
801039a7:	83 e0 01             	and    $0x1,%eax
801039aa:	89 c2                	mov    %eax,%edx
801039ac:	c1 e2 04             	shl    $0x4,%edx
801039af:	8b 45 08             	mov    0x8(%ebp),%eax
801039b2:	8b 40 08             	mov    0x8(%eax),%eax
801039b5:	c1 e8 18             	shr    $0x18,%eax
801039b8:	83 e0 0f             	and    $0xf,%eax
801039bb:	09 d0                	or     %edx,%eax
801039bd:	83 c8 e0             	or     $0xffffffe0,%eax
801039c0:	0f b6 c0             	movzbl %al,%eax
801039c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801039c7:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801039ce:	e8 04 fe ff ff       	call   801037d7 <outb>
  if(b->flags & B_DIRTY){
801039d3:	8b 45 08             	mov    0x8(%ebp),%eax
801039d6:	8b 00                	mov    (%eax),%eax
801039d8:	83 e0 04             	and    $0x4,%eax
801039db:	85 c0                	test   %eax,%eax
801039dd:	74 34                	je     80103a13 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801039df:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801039e6:	00 
801039e7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801039ee:	e8 e4 fd ff ff       	call   801037d7 <outb>
    outsl(0x1f0, b->data, 512/4);
801039f3:	8b 45 08             	mov    0x8(%ebp),%eax
801039f6:	83 c0 18             	add    $0x18,%eax
801039f9:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103a00:	00 
80103a01:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a05:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103a0c:	e8 e4 fd ff ff       	call   801037f5 <outsl>
80103a11:	eb 14                	jmp    80103a27 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80103a13:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103a1a:	00 
80103a1b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103a22:	e8 b0 fd ff ff       	call   801037d7 <outb>
  }
}
80103a27:	c9                   	leave  
80103a28:	c3                   	ret    

80103a29 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80103a29:	55                   	push   %ebp
80103a2a:	89 e5                	mov    %esp,%ebp
80103a2c:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80103a2f:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a36:	e8 a0 24 00 00       	call   80105edb <acquire>
  if((b = idequeue) == 0){
80103a3b:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103a40:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a43:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103a47:	75 11                	jne    80103a5a <ideintr+0x31>
    release(&idelock);
80103a49:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a50:	e8 e8 24 00 00       	call   80105f3d <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80103a55:	e9 90 00 00 00       	jmp    80103aea <ideintr+0xc1>
  }
  idequeue = b->qnext;
80103a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a5d:	8b 40 14             	mov    0x14(%eax),%eax
80103a60:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80103a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a68:	8b 00                	mov    (%eax),%eax
80103a6a:	83 e0 04             	and    $0x4,%eax
80103a6d:	85 c0                	test   %eax,%eax
80103a6f:	75 2e                	jne    80103a9f <ideintr+0x76>
80103a71:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103a78:	e8 9d fd ff ff       	call   8010381a <idewait>
80103a7d:	85 c0                	test   %eax,%eax
80103a7f:	78 1e                	js     80103a9f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80103a81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a84:	83 c0 18             	add    $0x18,%eax
80103a87:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103a8e:	00 
80103a8f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a93:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103a9a:	e8 13 fd ff ff       	call   801037b2 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80103a9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aa2:	8b 00                	mov    (%eax),%eax
80103aa4:	89 c2                	mov    %eax,%edx
80103aa6:	83 ca 02             	or     $0x2,%edx
80103aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103aac:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80103aae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ab1:	8b 00                	mov    (%eax),%eax
80103ab3:	89 c2                	mov    %eax,%edx
80103ab5:	83 e2 fb             	and    $0xfffffffb,%edx
80103ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103abb:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103abd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ac0:	89 04 24             	mov    %eax,(%esp)
80103ac3:	e8 0e 22 00 00       	call   80105cd6 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103ac8:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103acd:	85 c0                	test   %eax,%eax
80103acf:	74 0d                	je     80103ade <ideintr+0xb5>
    idestart(idequeue);
80103ad1:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103ad6:	89 04 24             	mov    %eax,(%esp)
80103ad9:	e8 26 fe ff ff       	call   80103904 <idestart>

  release(&idelock);
80103ade:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103ae5:	e8 53 24 00 00       	call   80105f3d <release>
}
80103aea:	c9                   	leave  
80103aeb:	c3                   	ret    

80103aec <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103aec:	55                   	push   %ebp
80103aed:	89 e5                	mov    %esp,%ebp
80103aef:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80103af2:	8b 45 08             	mov    0x8(%ebp),%eax
80103af5:	8b 00                	mov    (%eax),%eax
80103af7:	83 e0 01             	and    $0x1,%eax
80103afa:	85 c0                	test   %eax,%eax
80103afc:	75 0c                	jne    80103b0a <iderw+0x1e>
    panic("iderw: buf not busy");
80103afe:	c7 04 24 d1 98 10 80 	movl   $0x801098d1,(%esp)
80103b05:	e8 33 ca ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80103b0d:	8b 00                	mov    (%eax),%eax
80103b0f:	83 e0 06             	and    $0x6,%eax
80103b12:	83 f8 02             	cmp    $0x2,%eax
80103b15:	75 0c                	jne    80103b23 <iderw+0x37>
    panic("iderw: nothing to do");
80103b17:	c7 04 24 e5 98 10 80 	movl   $0x801098e5,(%esp)
80103b1e:	e8 1a ca ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80103b23:	8b 45 08             	mov    0x8(%ebp),%eax
80103b26:	8b 40 04             	mov    0x4(%eax),%eax
80103b29:	85 c0                	test   %eax,%eax
80103b2b:	74 15                	je     80103b42 <iderw+0x56>
80103b2d:	a1 58 c6 10 80       	mov    0x8010c658,%eax
80103b32:	85 c0                	test   %eax,%eax
80103b34:	75 0c                	jne    80103b42 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80103b36:	c7 04 24 fa 98 10 80 	movl   $0x801098fa,(%esp)
80103b3d:	e8 fb c9 ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80103b42:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103b49:	e8 8d 23 00 00       	call   80105edb <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80103b4e:	8b 45 08             	mov    0x8(%ebp),%eax
80103b51:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80103b58:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80103b5f:	eb 0b                	jmp    80103b6c <iderw+0x80>
80103b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b64:	8b 00                	mov    (%eax),%eax
80103b66:	83 c0 14             	add    $0x14,%eax
80103b69:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b6f:	8b 00                	mov    (%eax),%eax
80103b71:	85 c0                	test   %eax,%eax
80103b73:	75 ec                	jne    80103b61 <iderw+0x75>
    ;
  *pp = b;
80103b75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b78:	8b 55 08             	mov    0x8(%ebp),%edx
80103b7b:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80103b7d:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103b82:	3b 45 08             	cmp    0x8(%ebp),%eax
80103b85:	75 22                	jne    80103ba9 <iderw+0xbd>
    idestart(b);
80103b87:	8b 45 08             	mov    0x8(%ebp),%eax
80103b8a:	89 04 24             	mov    %eax,(%esp)
80103b8d:	e8 72 fd ff ff       	call   80103904 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103b92:	eb 15                	jmp    80103ba9 <iderw+0xbd>
    sleep(b, &idelock);
80103b94:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103b9b:	80 
80103b9c:	8b 45 08             	mov    0x8(%ebp),%eax
80103b9f:	89 04 24             	mov    %eax,(%esp)
80103ba2:	e8 56 20 00 00       	call   80105bfd <sleep>
80103ba7:	eb 01                	jmp    80103baa <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103ba9:	90                   	nop
80103baa:	8b 45 08             	mov    0x8(%ebp),%eax
80103bad:	8b 00                	mov    (%eax),%eax
80103baf:	83 e0 06             	and    $0x6,%eax
80103bb2:	83 f8 02             	cmp    $0x2,%eax
80103bb5:	75 dd                	jne    80103b94 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103bb7:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103bbe:	e8 7a 23 00 00       	call   80105f3d <release>
}
80103bc3:	c9                   	leave  
80103bc4:	c3                   	ret    
80103bc5:	00 00                	add    %al,(%eax)
	...

80103bc8 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103bc8:	55                   	push   %ebp
80103bc9:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103bcb:	a1 94 08 11 80       	mov    0x80110894,%eax
80103bd0:	8b 55 08             	mov    0x8(%ebp),%edx
80103bd3:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103bd5:	a1 94 08 11 80       	mov    0x80110894,%eax
80103bda:	8b 40 10             	mov    0x10(%eax),%eax
}
80103bdd:	5d                   	pop    %ebp
80103bde:	c3                   	ret    

80103bdf <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103bdf:	55                   	push   %ebp
80103be0:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103be2:	a1 94 08 11 80       	mov    0x80110894,%eax
80103be7:	8b 55 08             	mov    0x8(%ebp),%edx
80103bea:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103bec:	a1 94 08 11 80       	mov    0x80110894,%eax
80103bf1:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bf4:	89 50 10             	mov    %edx,0x10(%eax)
}
80103bf7:	5d                   	pop    %ebp
80103bf8:	c3                   	ret    

80103bf9 <ioapicinit>:

void
ioapicinit(void)
{
80103bf9:	55                   	push   %ebp
80103bfa:	89 e5                	mov    %esp,%ebp
80103bfc:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103bff:	a1 64 09 11 80       	mov    0x80110964,%eax
80103c04:	85 c0                	test   %eax,%eax
80103c06:	0f 84 9f 00 00 00    	je     80103cab <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103c0c:	c7 05 94 08 11 80 00 	movl   $0xfec00000,0x80110894
80103c13:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103c16:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103c1d:	e8 a6 ff ff ff       	call   80103bc8 <ioapicread>
80103c22:	c1 e8 10             	shr    $0x10,%eax
80103c25:	25 ff 00 00 00       	and    $0xff,%eax
80103c2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103c2d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103c34:	e8 8f ff ff ff       	call   80103bc8 <ioapicread>
80103c39:	c1 e8 18             	shr    $0x18,%eax
80103c3c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103c3f:	0f b6 05 60 09 11 80 	movzbl 0x80110960,%eax
80103c46:	0f b6 c0             	movzbl %al,%eax
80103c49:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c4c:	74 0c                	je     80103c5a <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103c4e:	c7 04 24 18 99 10 80 	movl   $0x80109918,(%esp)
80103c55:	e8 47 c7 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103c5a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103c61:	eb 3e                	jmp    80103ca1 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103c63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c66:	83 c0 20             	add    $0x20,%eax
80103c69:	0d 00 00 01 00       	or     $0x10000,%eax
80103c6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c71:	83 c2 08             	add    $0x8,%edx
80103c74:	01 d2                	add    %edx,%edx
80103c76:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c7a:	89 14 24             	mov    %edx,(%esp)
80103c7d:	e8 5d ff ff ff       	call   80103bdf <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c85:	83 c0 08             	add    $0x8,%eax
80103c88:	01 c0                	add    %eax,%eax
80103c8a:	83 c0 01             	add    $0x1,%eax
80103c8d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103c94:	00 
80103c95:	89 04 24             	mov    %eax,(%esp)
80103c98:	e8 42 ff ff ff       	call   80103bdf <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103c9d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103ca7:	7e ba                	jle    80103c63 <ioapicinit+0x6a>
80103ca9:	eb 01                	jmp    80103cac <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103cab:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103cac:	c9                   	leave  
80103cad:	c3                   	ret    

80103cae <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103cae:	55                   	push   %ebp
80103caf:	89 e5                	mov    %esp,%ebp
80103cb1:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103cb4:	a1 64 09 11 80       	mov    0x80110964,%eax
80103cb9:	85 c0                	test   %eax,%eax
80103cbb:	74 39                	je     80103cf6 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103cbd:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc0:	83 c0 20             	add    $0x20,%eax
80103cc3:	8b 55 08             	mov    0x8(%ebp),%edx
80103cc6:	83 c2 08             	add    $0x8,%edx
80103cc9:	01 d2                	add    %edx,%edx
80103ccb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ccf:	89 14 24             	mov    %edx,(%esp)
80103cd2:	e8 08 ff ff ff       	call   80103bdf <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103cd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cda:	c1 e0 18             	shl    $0x18,%eax
80103cdd:	8b 55 08             	mov    0x8(%ebp),%edx
80103ce0:	83 c2 08             	add    $0x8,%edx
80103ce3:	01 d2                	add    %edx,%edx
80103ce5:	83 c2 01             	add    $0x1,%edx
80103ce8:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cec:	89 14 24             	mov    %edx,(%esp)
80103cef:	e8 eb fe ff ff       	call   80103bdf <ioapicwrite>
80103cf4:	eb 01                	jmp    80103cf7 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103cf6:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103cf7:	c9                   	leave  
80103cf8:	c3                   	ret    
80103cf9:	00 00                	add    %al,(%eax)
	...

80103cfc <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103cfc:	55                   	push   %ebp
80103cfd:	89 e5                	mov    %esp,%ebp
80103cff:	8b 45 08             	mov    0x8(%ebp),%eax
80103d02:	05 00 00 00 80       	add    $0x80000000,%eax
80103d07:	5d                   	pop    %ebp
80103d08:	c3                   	ret    

80103d09 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103d09:	55                   	push   %ebp
80103d0a:	89 e5                	mov    %esp,%ebp
80103d0c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103d0f:	c7 44 24 04 4a 99 10 	movl   $0x8010994a,0x4(%esp)
80103d16:	80 
80103d17:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103d1e:	e8 97 21 00 00       	call   80105eba <initlock>
  kmem.use_lock = 0;
80103d23:	c7 05 d4 08 11 80 00 	movl   $0x0,0x801108d4
80103d2a:	00 00 00 
  freerange(vstart, vend);
80103d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d30:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d34:	8b 45 08             	mov    0x8(%ebp),%eax
80103d37:	89 04 24             	mov    %eax,(%esp)
80103d3a:	e8 26 00 00 00       	call   80103d65 <freerange>
}
80103d3f:	c9                   	leave  
80103d40:	c3                   	ret    

80103d41 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103d41:	55                   	push   %ebp
80103d42:	89 e5                	mov    %esp,%ebp
80103d44:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103d47:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80103d51:	89 04 24             	mov    %eax,(%esp)
80103d54:	e8 0c 00 00 00       	call   80103d65 <freerange>
  kmem.use_lock = 1;
80103d59:	c7 05 d4 08 11 80 01 	movl   $0x1,0x801108d4
80103d60:	00 00 00 
}
80103d63:	c9                   	leave  
80103d64:	c3                   	ret    

80103d65 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103d65:	55                   	push   %ebp
80103d66:	89 e5                	mov    %esp,%ebp
80103d68:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103d6b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d6e:	05 ff 0f 00 00       	add    $0xfff,%eax
80103d73:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103d78:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103d7b:	eb 12                	jmp    80103d8f <freerange+0x2a>
    kfree(p);
80103d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d80:	89 04 24             	mov    %eax,(%esp)
80103d83:	e8 16 00 00 00       	call   80103d9e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103d88:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103d8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d92:	05 00 10 00 00       	add    $0x1000,%eax
80103d97:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103d9a:	76 e1                	jbe    80103d7d <freerange+0x18>
    kfree(p);
}
80103d9c:	c9                   	leave  
80103d9d:	c3                   	ret    

80103d9e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103d9e:	55                   	push   %ebp
80103d9f:	89 e5                	mov    %esp,%ebp
80103da1:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103da4:	8b 45 08             	mov    0x8(%ebp),%eax
80103da7:	25 ff 0f 00 00       	and    $0xfff,%eax
80103dac:	85 c0                	test   %eax,%eax
80103dae:	75 1b                	jne    80103dcb <kfree+0x2d>
80103db0:	81 7d 08 5c 37 11 80 	cmpl   $0x8011375c,0x8(%ebp)
80103db7:	72 12                	jb     80103dcb <kfree+0x2d>
80103db9:	8b 45 08             	mov    0x8(%ebp),%eax
80103dbc:	89 04 24             	mov    %eax,(%esp)
80103dbf:	e8 38 ff ff ff       	call   80103cfc <v2p>
80103dc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103dc9:	76 0c                	jbe    80103dd7 <kfree+0x39>
    panic("kfree");
80103dcb:	c7 04 24 4f 99 10 80 	movl   $0x8010994f,(%esp)
80103dd2:	e8 66 c7 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103dd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103dde:	00 
80103ddf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103de6:	00 
80103de7:	8b 45 08             	mov    0x8(%ebp),%eax
80103dea:	89 04 24             	mov    %eax,(%esp)
80103ded:	e8 38 23 00 00       	call   8010612a <memset>

  if(kmem.use_lock)
80103df2:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103df7:	85 c0                	test   %eax,%eax
80103df9:	74 0c                	je     80103e07 <kfree+0x69>
    acquire(&kmem.lock);
80103dfb:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e02:	e8 d4 20 00 00       	call   80105edb <acquire>
  r = (struct run*)v;
80103e07:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103e0d:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80103e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e16:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e1b:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  if(kmem.use_lock)
80103e20:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103e25:	85 c0                	test   %eax,%eax
80103e27:	74 0c                	je     80103e35 <kfree+0x97>
    release(&kmem.lock);
80103e29:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e30:	e8 08 21 00 00       	call   80105f3d <release>
}
80103e35:	c9                   	leave  
80103e36:	c3                   	ret    

80103e37 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103e37:	55                   	push   %ebp
80103e38:	89 e5                	mov    %esp,%ebp
80103e3a:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103e3d:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103e42:	85 c0                	test   %eax,%eax
80103e44:	74 0c                	je     80103e52 <kalloc+0x1b>
    acquire(&kmem.lock);
80103e46:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e4d:	e8 89 20 00 00       	call   80105edb <acquire>
  r = kmem.freelist;
80103e52:	a1 d8 08 11 80       	mov    0x801108d8,%eax
80103e57:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103e5a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e5e:	74 0a                	je     80103e6a <kalloc+0x33>
    kmem.freelist = r->next;
80103e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e63:	8b 00                	mov    (%eax),%eax
80103e65:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  if(kmem.use_lock)
80103e6a:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103e6f:	85 c0                	test   %eax,%eax
80103e71:	74 0c                	je     80103e7f <kalloc+0x48>
    release(&kmem.lock);
80103e73:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e7a:	e8 be 20 00 00       	call   80105f3d <release>
  return (char*)r;
80103e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103e82:	c9                   	leave  
80103e83:	c3                   	ret    

80103e84 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103e84:	55                   	push   %ebp
80103e85:	89 e5                	mov    %esp,%ebp
80103e87:	53                   	push   %ebx
80103e88:	83 ec 14             	sub    $0x14,%esp
80103e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103e92:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103e96:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103e9a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103e9e:	ec                   	in     (%dx),%al
80103e9f:	89 c3                	mov    %eax,%ebx
80103ea1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103ea4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103ea8:	83 c4 14             	add    $0x14,%esp
80103eab:	5b                   	pop    %ebx
80103eac:	5d                   	pop    %ebp
80103ead:	c3                   	ret    

80103eae <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103eae:	55                   	push   %ebp
80103eaf:	89 e5                	mov    %esp,%ebp
80103eb1:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103eb4:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103ebb:	e8 c4 ff ff ff       	call   80103e84 <inb>
80103ec0:	0f b6 c0             	movzbl %al,%eax
80103ec3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103ec6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ec9:	83 e0 01             	and    $0x1,%eax
80103ecc:	85 c0                	test   %eax,%eax
80103ece:	75 0a                	jne    80103eda <kbdgetc+0x2c>
    return -1;
80103ed0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ed5:	e9 23 01 00 00       	jmp    80103ffd <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103eda:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103ee1:	e8 9e ff ff ff       	call   80103e84 <inb>
80103ee6:	0f b6 c0             	movzbl %al,%eax
80103ee9:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103eec:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103ef3:	75 17                	jne    80103f0c <kbdgetc+0x5e>
    shift |= E0ESC;
80103ef5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103efa:	83 c8 40             	or     $0x40,%eax
80103efd:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103f02:	b8 00 00 00 00       	mov    $0x0,%eax
80103f07:	e9 f1 00 00 00       	jmp    80103ffd <kbdgetc+0x14f>
  } else if(data & 0x80){
80103f0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f0f:	25 80 00 00 00       	and    $0x80,%eax
80103f14:	85 c0                	test   %eax,%eax
80103f16:	74 45                	je     80103f5d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103f18:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f1d:	83 e0 40             	and    $0x40,%eax
80103f20:	85 c0                	test   %eax,%eax
80103f22:	75 08                	jne    80103f2c <kbdgetc+0x7e>
80103f24:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f27:	83 e0 7f             	and    $0x7f,%eax
80103f2a:	eb 03                	jmp    80103f2f <kbdgetc+0x81>
80103f2c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f2f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103f32:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f35:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103f3a:	0f b6 00             	movzbl (%eax),%eax
80103f3d:	83 c8 40             	or     $0x40,%eax
80103f40:	0f b6 c0             	movzbl %al,%eax
80103f43:	f7 d0                	not    %eax
80103f45:	89 c2                	mov    %eax,%edx
80103f47:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f4c:	21 d0                	and    %edx,%eax
80103f4e:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103f53:	b8 00 00 00 00       	mov    $0x0,%eax
80103f58:	e9 a0 00 00 00       	jmp    80103ffd <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103f5d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f62:	83 e0 40             	and    $0x40,%eax
80103f65:	85 c0                	test   %eax,%eax
80103f67:	74 14                	je     80103f7d <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103f69:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103f70:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f75:	83 e0 bf             	and    $0xffffffbf,%eax
80103f78:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103f7d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f80:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103f85:	0f b6 00             	movzbl (%eax),%eax
80103f88:	0f b6 d0             	movzbl %al,%edx
80103f8b:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f90:	09 d0                	or     %edx,%eax
80103f92:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103f97:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f9a:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103f9f:	0f b6 00             	movzbl (%eax),%eax
80103fa2:	0f b6 d0             	movzbl %al,%edx
80103fa5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103faa:	31 d0                	xor    %edx,%eax
80103fac:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103fb1:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103fb6:	83 e0 03             	and    $0x3,%eax
80103fb9:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103fc0:	03 45 fc             	add    -0x4(%ebp),%eax
80103fc3:	0f b6 00             	movzbl (%eax),%eax
80103fc6:	0f b6 c0             	movzbl %al,%eax
80103fc9:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103fcc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103fd1:	83 e0 08             	and    $0x8,%eax
80103fd4:	85 c0                	test   %eax,%eax
80103fd6:	74 22                	je     80103ffa <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103fd8:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103fdc:	76 0c                	jbe    80103fea <kbdgetc+0x13c>
80103fde:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103fe2:	77 06                	ja     80103fea <kbdgetc+0x13c>
      c += 'A' - 'a';
80103fe4:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103fe8:	eb 10                	jmp    80103ffa <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103fea:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103fee:	76 0a                	jbe    80103ffa <kbdgetc+0x14c>
80103ff0:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103ff4:	77 04                	ja     80103ffa <kbdgetc+0x14c>
      c += 'a' - 'A';
80103ff6:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103ffa:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103ffd:	c9                   	leave  
80103ffe:	c3                   	ret    

80103fff <kbdintr>:

void
kbdintr(void)
{
80103fff:	55                   	push   %ebp
80104000:	89 e5                	mov    %esp,%ebp
80104002:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80104005:	c7 04 24 ae 3e 10 80 	movl   $0x80103eae,(%esp)
8010400c:	e8 9c c7 ff ff       	call   801007ad <consoleintr>
}
80104011:	c9                   	leave  
80104012:	c3                   	ret    
	...

80104014 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104014:	55                   	push   %ebp
80104015:	89 e5                	mov    %esp,%ebp
80104017:	83 ec 08             	sub    $0x8,%esp
8010401a:	8b 55 08             	mov    0x8(%ebp),%edx
8010401d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104020:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104024:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104027:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010402b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010402f:	ee                   	out    %al,(%dx)
}
80104030:	c9                   	leave  
80104031:	c3                   	ret    

80104032 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104032:	55                   	push   %ebp
80104033:	89 e5                	mov    %esp,%ebp
80104035:	53                   	push   %ebx
80104036:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104039:	9c                   	pushf  
8010403a:	5b                   	pop    %ebx
8010403b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010403e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104041:	83 c4 10             	add    $0x10,%esp
80104044:	5b                   	pop    %ebx
80104045:	5d                   	pop    %ebp
80104046:	c3                   	ret    

80104047 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80104047:	55                   	push   %ebp
80104048:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010404a:	a1 dc 08 11 80       	mov    0x801108dc,%eax
8010404f:	8b 55 08             	mov    0x8(%ebp),%edx
80104052:	c1 e2 02             	shl    $0x2,%edx
80104055:	01 c2                	add    %eax,%edx
80104057:	8b 45 0c             	mov    0xc(%ebp),%eax
8010405a:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
8010405c:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104061:	83 c0 20             	add    $0x20,%eax
80104064:	8b 00                	mov    (%eax),%eax
}
80104066:	5d                   	pop    %ebp
80104067:	c3                   	ret    

80104068 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80104068:	55                   	push   %ebp
80104069:	89 e5                	mov    %esp,%ebp
8010406b:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
8010406e:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104073:	85 c0                	test   %eax,%eax
80104075:	0f 84 47 01 00 00    	je     801041c2 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010407b:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80104082:	00 
80104083:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
8010408a:	e8 b8 ff ff ff       	call   80104047 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
8010408f:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80104096:	00 
80104097:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
8010409e:	e8 a4 ff ff ff       	call   80104047 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801040a3:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801040aa:	00 
801040ab:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801040b2:	e8 90 ff ff ff       	call   80104047 <lapicw>
  lapicw(TICR, 10000000); 
801040b7:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
801040be:	00 
801040bf:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
801040c6:	e8 7c ff ff ff       	call   80104047 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
801040cb:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801040d2:	00 
801040d3:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
801040da:	e8 68 ff ff ff       	call   80104047 <lapicw>
  lapicw(LINT1, MASKED);
801040df:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801040e6:	00 
801040e7:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
801040ee:	e8 54 ff ff ff       	call   80104047 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801040f3:	a1 dc 08 11 80       	mov    0x801108dc,%eax
801040f8:	83 c0 30             	add    $0x30,%eax
801040fb:	8b 00                	mov    (%eax),%eax
801040fd:	c1 e8 10             	shr    $0x10,%eax
80104100:	25 ff 00 00 00       	and    $0xff,%eax
80104105:	83 f8 03             	cmp    $0x3,%eax
80104108:	76 14                	jbe    8010411e <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010410a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104111:	00 
80104112:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80104119:	e8 29 ff ff ff       	call   80104047 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010411e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80104125:	00 
80104126:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010412d:	e8 15 ff ff ff       	call   80104047 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80104132:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104139:	00 
8010413a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104141:	e8 01 ff ff ff       	call   80104047 <lapicw>
  lapicw(ESR, 0);
80104146:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010414d:	00 
8010414e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104155:	e8 ed fe ff ff       	call   80104047 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010415a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104161:	00 
80104162:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80104169:	e8 d9 fe ff ff       	call   80104047 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
8010416e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104175:	00 
80104176:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010417d:	e8 c5 fe ff ff       	call   80104047 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80104182:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80104189:	00 
8010418a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104191:	e8 b1 fe ff ff       	call   80104047 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80104196:	90                   	nop
80104197:	a1 dc 08 11 80       	mov    0x801108dc,%eax
8010419c:	05 00 03 00 00       	add    $0x300,%eax
801041a1:	8b 00                	mov    (%eax),%eax
801041a3:	25 00 10 00 00       	and    $0x1000,%eax
801041a8:	85 c0                	test   %eax,%eax
801041aa:	75 eb                	jne    80104197 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801041ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041b3:	00 
801041b4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801041bb:	e8 87 fe ff ff       	call   80104047 <lapicw>
801041c0:	eb 01                	jmp    801041c3 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
801041c2:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
801041c3:	c9                   	leave  
801041c4:	c3                   	ret    

801041c5 <cpunum>:

int
cpunum(void)
{
801041c5:	55                   	push   %ebp
801041c6:	89 e5                	mov    %esp,%ebp
801041c8:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801041cb:	e8 62 fe ff ff       	call   80104032 <readeflags>
801041d0:	25 00 02 00 00       	and    $0x200,%eax
801041d5:	85 c0                	test   %eax,%eax
801041d7:	74 29                	je     80104202 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
801041d9:	a1 60 c6 10 80       	mov    0x8010c660,%eax
801041de:	85 c0                	test   %eax,%eax
801041e0:	0f 94 c2             	sete   %dl
801041e3:	83 c0 01             	add    $0x1,%eax
801041e6:	a3 60 c6 10 80       	mov    %eax,0x8010c660
801041eb:	84 d2                	test   %dl,%dl
801041ed:	74 13                	je     80104202 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
801041ef:	8b 45 04             	mov    0x4(%ebp),%eax
801041f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801041f6:	c7 04 24 58 99 10 80 	movl   $0x80109958,(%esp)
801041fd:	e8 9f c1 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80104202:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104207:	85 c0                	test   %eax,%eax
80104209:	74 0f                	je     8010421a <cpunum+0x55>
    return lapic[ID]>>24;
8010420b:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104210:	83 c0 20             	add    $0x20,%eax
80104213:	8b 00                	mov    (%eax),%eax
80104215:	c1 e8 18             	shr    $0x18,%eax
80104218:	eb 05                	jmp    8010421f <cpunum+0x5a>
  return 0;
8010421a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010421f:	c9                   	leave  
80104220:	c3                   	ret    

80104221 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80104221:	55                   	push   %ebp
80104222:	89 e5                	mov    %esp,%ebp
80104224:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80104227:	a1 dc 08 11 80       	mov    0x801108dc,%eax
8010422c:	85 c0                	test   %eax,%eax
8010422e:	74 14                	je     80104244 <lapiceoi+0x23>
    lapicw(EOI, 0);
80104230:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104237:	00 
80104238:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010423f:	e8 03 fe ff ff       	call   80104047 <lapicw>
}
80104244:	c9                   	leave  
80104245:	c3                   	ret    

80104246 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80104246:	55                   	push   %ebp
80104247:	89 e5                	mov    %esp,%ebp
}
80104249:	5d                   	pop    %ebp
8010424a:	c3                   	ret    

8010424b <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010424b:	55                   	push   %ebp
8010424c:	89 e5                	mov    %esp,%ebp
8010424e:	83 ec 1c             	sub    $0x1c,%esp
80104251:	8b 45 08             	mov    0x8(%ebp),%eax
80104254:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80104257:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010425e:	00 
8010425f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80104266:	e8 a9 fd ff ff       	call   80104014 <outb>
  outb(IO_RTC+1, 0x0A);
8010426b:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104272:	00 
80104273:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010427a:	e8 95 fd ff ff       	call   80104014 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
8010427f:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80104286:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104289:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010428e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104291:	8d 50 02             	lea    0x2(%eax),%edx
80104294:	8b 45 0c             	mov    0xc(%ebp),%eax
80104297:	c1 e8 04             	shr    $0x4,%eax
8010429a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010429d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801042a1:	c1 e0 18             	shl    $0x18,%eax
801042a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801042a8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801042af:	e8 93 fd ff ff       	call   80104047 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801042b4:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801042bb:	00 
801042bc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801042c3:	e8 7f fd ff ff       	call   80104047 <lapicw>
  microdelay(200);
801042c8:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801042cf:	e8 72 ff ff ff       	call   80104246 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801042d4:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801042db:	00 
801042dc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801042e3:	e8 5f fd ff ff       	call   80104047 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801042e8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801042ef:	e8 52 ff ff ff       	call   80104246 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801042f4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801042fb:	eb 40                	jmp    8010433d <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801042fd:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80104301:	c1 e0 18             	shl    $0x18,%eax
80104304:	89 44 24 04          	mov    %eax,0x4(%esp)
80104308:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010430f:	e8 33 fd ff ff       	call   80104047 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80104314:	8b 45 0c             	mov    0xc(%ebp),%eax
80104317:	c1 e8 0c             	shr    $0xc,%eax
8010431a:	80 cc 06             	or     $0x6,%ah
8010431d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104321:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104328:	e8 1a fd ff ff       	call   80104047 <lapicw>
    microdelay(200);
8010432d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80104334:	e8 0d ff ff ff       	call   80104246 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104339:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010433d:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80104341:	7e ba                	jle    801042fd <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80104343:	c9                   	leave  
80104344:	c3                   	ret    
80104345:	00 00                	add    %al,(%eax)
	...

80104348 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{ 
80104348:	55                   	push   %ebp
80104349:	89 e5                	mov    %esp,%ebp
8010434b:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010434e:	c7 44 24 04 84 99 10 	movl   $0x80109984,0x4(%esp)
80104355:	80 
80104356:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
8010435d:	e8 58 1b 00 00       	call   80105eba <initlock>
  readsb(ROOTDEV, &sb);
80104362:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104365:	89 44 24 04          	mov    %eax,0x4(%esp)
80104369:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80104370:	e8 eb dd ff ff       	call   80102160 <readsb>
  log.start = sb.size - sb.nlog;
80104375:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104378:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010437b:	89 d1                	mov    %edx,%ecx
8010437d:	29 c1                	sub    %eax,%ecx
8010437f:	89 c8                	mov    %ecx,%eax
80104381:	a3 14 09 11 80       	mov    %eax,0x80110914
  log.size = sb.nlog;
80104386:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104389:	a3 18 09 11 80       	mov    %eax,0x80110918
  log.dev = ROOTDEV;
8010438e:	c7 05 20 09 11 80 01 	movl   $0x1,0x80110920
80104395:	00 00 00 
  recover_from_log();
80104398:	e8 97 01 00 00       	call   80104534 <recover_from_log>
  
  
}
8010439d:	c9                   	leave  
8010439e:	c3                   	ret    

8010439f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010439f:	55                   	push   %ebp
801043a0:	89 e5                	mov    %esp,%ebp
801043a2:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801043a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043ac:	e9 89 00 00 00       	jmp    8010443a <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801043b1:	a1 14 09 11 80       	mov    0x80110914,%eax
801043b6:	03 45 f4             	add    -0xc(%ebp),%eax
801043b9:	83 c0 01             	add    $0x1,%eax
801043bc:	89 c2                	mov    %eax,%edx
801043be:	a1 20 09 11 80       	mov    0x80110920,%eax
801043c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801043c7:	89 04 24             	mov    %eax,(%esp)
801043ca:	e8 d7 bd ff ff       	call   801001a6 <bread>
801043cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801043d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d5:	83 c0 10             	add    $0x10,%eax
801043d8:	8b 04 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%eax
801043df:	89 c2                	mov    %eax,%edx
801043e1:	a1 20 09 11 80       	mov    0x80110920,%eax
801043e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801043ea:	89 04 24             	mov    %eax,(%esp)
801043ed:	e8 b4 bd ff ff       	call   801001a6 <bread>
801043f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801043f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043f8:	8d 50 18             	lea    0x18(%eax),%edx
801043fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043fe:	83 c0 18             	add    $0x18,%eax
80104401:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104408:	00 
80104409:	89 54 24 04          	mov    %edx,0x4(%esp)
8010440d:	89 04 24             	mov    %eax,(%esp)
80104410:	e8 e8 1d 00 00       	call   801061fd <memmove>
    bwrite(dbuf);  // write dst to disk
80104415:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104418:	89 04 24             	mov    %eax,(%esp)
8010441b:	e8 bd bd ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80104420:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104423:	89 04 24             	mov    %eax,(%esp)
80104426:	e8 ec bd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010442b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010442e:	89 04 24             	mov    %eax,(%esp)
80104431:	e8 e1 bd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104436:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010443a:	a1 24 09 11 80       	mov    0x80110924,%eax
8010443f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104442:	0f 8f 69 ff ff ff    	jg     801043b1 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80104448:	c9                   	leave  
80104449:	c3                   	ret    

8010444a <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010444a:	55                   	push   %ebp
8010444b:	89 e5                	mov    %esp,%ebp
8010444d:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80104450:	a1 14 09 11 80       	mov    0x80110914,%eax
80104455:	89 c2                	mov    %eax,%edx
80104457:	a1 20 09 11 80       	mov    0x80110920,%eax
8010445c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104460:	89 04 24             	mov    %eax,(%esp)
80104463:	e8 3e bd ff ff       	call   801001a6 <bread>
80104468:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010446b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010446e:	83 c0 18             	add    $0x18,%eax
80104471:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80104474:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104477:	8b 00                	mov    (%eax),%eax
80104479:	a3 24 09 11 80       	mov    %eax,0x80110924
  for (i = 0; i < log.lh.n; i++) {
8010447e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104485:	eb 1b                	jmp    801044a2 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80104487:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010448a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010448d:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80104491:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104494:	83 c2 10             	add    $0x10,%edx
80104497:	89 04 95 e8 08 11 80 	mov    %eax,-0x7feef718(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010449e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801044a2:	a1 24 09 11 80       	mov    0x80110924,%eax
801044a7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801044aa:	7f db                	jg     80104487 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801044ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044af:	89 04 24             	mov    %eax,(%esp)
801044b2:	e8 60 bd ff ff       	call   80100217 <brelse>
}
801044b7:	c9                   	leave  
801044b8:	c3                   	ret    

801044b9 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801044b9:	55                   	push   %ebp
801044ba:	89 e5                	mov    %esp,%ebp
801044bc:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801044bf:	a1 14 09 11 80       	mov    0x80110914,%eax
801044c4:	89 c2                	mov    %eax,%edx
801044c6:	a1 20 09 11 80       	mov    0x80110920,%eax
801044cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801044cf:	89 04 24             	mov    %eax,(%esp)
801044d2:	e8 cf bc ff ff       	call   801001a6 <bread>
801044d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801044da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801044dd:	83 c0 18             	add    $0x18,%eax
801044e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801044e3:	8b 15 24 09 11 80    	mov    0x80110924,%edx
801044e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801044ec:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801044ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801044f5:	eb 1b                	jmp    80104512 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801044f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044fa:	83 c0 10             	add    $0x10,%eax
801044fd:	8b 0c 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%ecx
80104504:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104507:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010450a:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010450e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104512:	a1 24 09 11 80       	mov    0x80110924,%eax
80104517:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010451a:	7f db                	jg     801044f7 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
8010451c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010451f:	89 04 24             	mov    %eax,(%esp)
80104522:	e8 b6 bc ff ff       	call   801001dd <bwrite>
  brelse(buf);
80104527:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010452a:	89 04 24             	mov    %eax,(%esp)
8010452d:	e8 e5 bc ff ff       	call   80100217 <brelse>
}
80104532:	c9                   	leave  
80104533:	c3                   	ret    

80104534 <recover_from_log>:

static void
recover_from_log(void)
{
80104534:	55                   	push   %ebp
80104535:	89 e5                	mov    %esp,%ebp
80104537:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010453a:	e8 0b ff ff ff       	call   8010444a <read_head>
  install_trans(); // if committed, copy from log to disk
8010453f:	e8 5b fe ff ff       	call   8010439f <install_trans>
  log.lh.n = 0;
80104544:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
8010454b:	00 00 00 
  write_head(); // clear the log
8010454e:	e8 66 ff ff ff       	call   801044b9 <write_head>
}
80104553:	c9                   	leave  
80104554:	c3                   	ret    

80104555 <begin_trans>:

void
begin_trans(void)
{
80104555:	55                   	push   %ebp
80104556:	89 e5                	mov    %esp,%ebp
80104558:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010455b:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
80104562:	e8 74 19 00 00       	call   80105edb <acquire>
  while (log.busy) {
80104567:	eb 14                	jmp    8010457d <begin_trans+0x28>
    sleep(&log, &log.lock);
80104569:	c7 44 24 04 e0 08 11 	movl   $0x801108e0,0x4(%esp)
80104570:	80 
80104571:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
80104578:	e8 80 16 00 00       	call   80105bfd <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
8010457d:	a1 1c 09 11 80       	mov    0x8011091c,%eax
80104582:	85 c0                	test   %eax,%eax
80104584:	75 e3                	jne    80104569 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80104586:	c7 05 1c 09 11 80 01 	movl   $0x1,0x8011091c
8010458d:	00 00 00 
  release(&log.lock);
80104590:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
80104597:	e8 a1 19 00 00       	call   80105f3d <release>
}
8010459c:	c9                   	leave  
8010459d:	c3                   	ret    

8010459e <commit_trans>:

void
commit_trans(void)
{
8010459e:	55                   	push   %ebp
8010459f:	89 e5                	mov    %esp,%ebp
801045a1:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801045a4:	a1 24 09 11 80       	mov    0x80110924,%eax
801045a9:	85 c0                	test   %eax,%eax
801045ab:	7e 19                	jle    801045c6 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801045ad:	e8 07 ff ff ff       	call   801044b9 <write_head>
    install_trans(); // Now install writes to home locations
801045b2:	e8 e8 fd ff ff       	call   8010439f <install_trans>
    log.lh.n = 0; 
801045b7:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801045be:	00 00 00 
    write_head();    // Erase the transaction from the log
801045c1:	e8 f3 fe ff ff       	call   801044b9 <write_head>
  }
  
  acquire(&log.lock);
801045c6:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801045cd:	e8 09 19 00 00       	call   80105edb <acquire>
  log.busy = 0;
801045d2:	c7 05 1c 09 11 80 00 	movl   $0x0,0x8011091c
801045d9:	00 00 00 
  wakeup(&log);
801045dc:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801045e3:	e8 ee 16 00 00       	call   80105cd6 <wakeup>
  release(&log.lock);
801045e8:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801045ef:	e8 49 19 00 00       	call   80105f3d <release>
}
801045f4:	c9                   	leave  
801045f5:	c3                   	ret    

801045f6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801045f6:	55                   	push   %ebp
801045f7:	89 e5                	mov    %esp,%ebp
801045f9:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801045fc:	a1 24 09 11 80       	mov    0x80110924,%eax
80104601:	83 f8 09             	cmp    $0x9,%eax
80104604:	7f 12                	jg     80104618 <log_write+0x22>
80104606:	a1 24 09 11 80       	mov    0x80110924,%eax
8010460b:	8b 15 18 09 11 80    	mov    0x80110918,%edx
80104611:	83 ea 01             	sub    $0x1,%edx
80104614:	39 d0                	cmp    %edx,%eax
80104616:	7c 0c                	jl     80104624 <log_write+0x2e>
    panic("too big a transaction");
80104618:	c7 04 24 88 99 10 80 	movl   $0x80109988,(%esp)
8010461f:	e8 19 bf ff ff       	call   8010053d <panic>
  if (!log.busy)
80104624:	a1 1c 09 11 80       	mov    0x8011091c,%eax
80104629:	85 c0                	test   %eax,%eax
8010462b:	75 0c                	jne    80104639 <log_write+0x43>
    panic("write outside of trans");
8010462d:	c7 04 24 9e 99 10 80 	movl   $0x8010999e,(%esp)
80104634:	e8 04 bf ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80104639:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104640:	eb 1d                	jmp    8010465f <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80104642:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104645:	83 c0 10             	add    $0x10,%eax
80104648:	8b 04 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%eax
8010464f:	89 c2                	mov    %eax,%edx
80104651:	8b 45 08             	mov    0x8(%ebp),%eax
80104654:	8b 40 08             	mov    0x8(%eax),%eax
80104657:	39 c2                	cmp    %eax,%edx
80104659:	74 10                	je     8010466b <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010465b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010465f:	a1 24 09 11 80       	mov    0x80110924,%eax
80104664:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104667:	7f d9                	jg     80104642 <log_write+0x4c>
80104669:	eb 01                	jmp    8010466c <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010466b:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
8010466c:	8b 45 08             	mov    0x8(%ebp),%eax
8010466f:	8b 40 08             	mov    0x8(%eax),%eax
80104672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104675:	83 c2 10             	add    $0x10,%edx
80104678:	89 04 95 e8 08 11 80 	mov    %eax,-0x7feef718(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010467f:	a1 14 09 11 80       	mov    0x80110914,%eax
80104684:	03 45 f4             	add    -0xc(%ebp),%eax
80104687:	83 c0 01             	add    $0x1,%eax
8010468a:	89 c2                	mov    %eax,%edx
8010468c:	8b 45 08             	mov    0x8(%ebp),%eax
8010468f:	8b 40 04             	mov    0x4(%eax),%eax
80104692:	89 54 24 04          	mov    %edx,0x4(%esp)
80104696:	89 04 24             	mov    %eax,(%esp)
80104699:	e8 08 bb ff ff       	call   801001a6 <bread>
8010469e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801046a1:	8b 45 08             	mov    0x8(%ebp),%eax
801046a4:	8d 50 18             	lea    0x18(%eax),%edx
801046a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046aa:	83 c0 18             	add    $0x18,%eax
801046ad:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801046b4:	00 
801046b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801046b9:	89 04 24             	mov    %eax,(%esp)
801046bc:	e8 3c 1b 00 00       	call   801061fd <memmove>
  bwrite(lbuf);
801046c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046c4:	89 04 24             	mov    %eax,(%esp)
801046c7:	e8 11 bb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801046cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046cf:	89 04 24             	mov    %eax,(%esp)
801046d2:	e8 40 bb ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801046d7:	a1 24 09 11 80       	mov    0x80110924,%eax
801046dc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801046df:	75 0d                	jne    801046ee <log_write+0xf8>
    log.lh.n++;
801046e1:	a1 24 09 11 80       	mov    0x80110924,%eax
801046e6:	83 c0 01             	add    $0x1,%eax
801046e9:	a3 24 09 11 80       	mov    %eax,0x80110924
  b->flags |= B_DIRTY; // XXX prevent eviction
801046ee:	8b 45 08             	mov    0x8(%ebp),%eax
801046f1:	8b 00                	mov    (%eax),%eax
801046f3:	89 c2                	mov    %eax,%edx
801046f5:	83 ca 04             	or     $0x4,%edx
801046f8:	8b 45 08             	mov    0x8(%ebp),%eax
801046fb:	89 10                	mov    %edx,(%eax)
}
801046fd:	c9                   	leave  
801046fe:	c3                   	ret    
	...

80104700 <v2p>:
80104700:	55                   	push   %ebp
80104701:	89 e5                	mov    %esp,%ebp
80104703:	8b 45 08             	mov    0x8(%ebp),%eax
80104706:	05 00 00 00 80       	add    $0x80000000,%eax
8010470b:	5d                   	pop    %ebp
8010470c:	c3                   	ret    

8010470d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010470d:	55                   	push   %ebp
8010470e:	89 e5                	mov    %esp,%ebp
80104710:	8b 45 08             	mov    0x8(%ebp),%eax
80104713:	05 00 00 00 80       	add    $0x80000000,%eax
80104718:	5d                   	pop    %ebp
80104719:	c3                   	ret    

8010471a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010471a:	55                   	push   %ebp
8010471b:	89 e5                	mov    %esp,%ebp
8010471d:	53                   	push   %ebx
8010471e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104721:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104724:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104727:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010472a:	89 c3                	mov    %eax,%ebx
8010472c:	89 d8                	mov    %ebx,%eax
8010472e:	f0 87 02             	lock xchg %eax,(%edx)
80104731:	89 c3                	mov    %eax,%ebx
80104733:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104736:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104739:	83 c4 10             	add    $0x10,%esp
8010473c:	5b                   	pop    %ebx
8010473d:	5d                   	pop    %ebp
8010473e:	c3                   	ret    

8010473f <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010473f:	55                   	push   %ebp
80104740:	89 e5                	mov    %esp,%ebp
80104742:	83 e4 f0             	and    $0xfffffff0,%esp
80104745:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80104748:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010474f:	80 
80104750:	c7 04 24 5c 37 11 80 	movl   $0x8011375c,(%esp)
80104757:	e8 ad f5 ff ff       	call   80103d09 <kinit1>
  kvmalloc();      // kernel page table
8010475c:	e8 9d 47 00 00       	call   80108efe <kvmalloc>
  mpinit();        // collect info about this machine
80104761:	e8 63 04 00 00       	call   80104bc9 <mpinit>
  lapicinit(mpbcpu());
80104766:	e8 2e 02 00 00       	call   80104999 <mpbcpu>
8010476b:	89 04 24             	mov    %eax,(%esp)
8010476e:	e8 f5 f8 ff ff       	call   80104068 <lapicinit>
  seginit();       // set up segments
80104773:	e8 29 41 00 00       	call   801088a1 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80104778:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010477e:	0f b6 00             	movzbl (%eax),%eax
80104781:	0f b6 c0             	movzbl %al,%eax
80104784:	89 44 24 04          	mov    %eax,0x4(%esp)
80104788:	c7 04 24 b5 99 10 80 	movl   $0x801099b5,(%esp)
8010478f:	e8 0d bc ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104794:	e8 95 06 00 00       	call   80104e2e <picinit>
  ioapicinit();    // another interrupt controller
80104799:	e8 5b f4 ff ff       	call   80103bf9 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010479e:	e8 ea c2 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801047a3:	e8 44 34 00 00       	call   80107bec <uartinit>
  pinit();         // process table
801047a8:	e8 96 0b 00 00       	call   80105343 <pinit>
  tvinit();        // trap vectors
801047ad:	e8 dd 2f 00 00       	call   8010778f <tvinit>
  binit();         // buffer cache
801047b2:	e8 7d b8 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801047b7:	e8 44 c7 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
801047bc:	e8 66 dc ff ff       	call   80102427 <iinit>
  ideinit();       // disk
801047c1:	e8 98 f0 ff ff       	call   8010385e <ideinit>
  if(!ismp)
801047c6:	a1 64 09 11 80       	mov    0x80110964,%eax
801047cb:	85 c0                	test   %eax,%eax
801047cd:	75 05                	jne    801047d4 <main+0x95>
    timerinit();   // uniprocessor timer
801047cf:	e8 fe 2e 00 00       	call   801076d2 <timerinit>
  startothers();   // start other processors
801047d4:	e8 87 00 00 00       	call   80104860 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801047d9:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801047e0:	8e 
801047e1:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801047e8:	e8 54 f5 ff ff       	call   80103d41 <kinit2>
  userinit();      // first user process
801047ed:	e8 6c 0c 00 00       	call   8010545e <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801047f2:	e8 22 00 00 00       	call   80104819 <mpmain>

801047f7 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801047f7:	55                   	push   %ebp
801047f8:	89 e5                	mov    %esp,%ebp
801047fa:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
801047fd:	e8 13 47 00 00       	call   80108f15 <switchkvm>
  seginit();
80104802:	e8 9a 40 00 00       	call   801088a1 <seginit>
  lapicinit(cpunum());
80104807:	e8 b9 f9 ff ff       	call   801041c5 <cpunum>
8010480c:	89 04 24             	mov    %eax,(%esp)
8010480f:	e8 54 f8 ff ff       	call   80104068 <lapicinit>
  mpmain();
80104814:	e8 00 00 00 00       	call   80104819 <mpmain>

80104819 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104819:	55                   	push   %ebp
8010481a:	89 e5                	mov    %esp,%ebp
8010481c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010481f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104825:	0f b6 00             	movzbl (%eax),%eax
80104828:	0f b6 c0             	movzbl %al,%eax
8010482b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010482f:	c7 04 24 cc 99 10 80 	movl   $0x801099cc,(%esp)
80104836:	e8 66 bb ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010483b:	e8 c3 30 00 00       	call   80107903 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80104840:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104846:	05 a8 00 00 00       	add    $0xa8,%eax
8010484b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104852:	00 
80104853:	89 04 24             	mov    %eax,(%esp)
80104856:	e8 bf fe ff ff       	call   8010471a <xchg>
  scheduler();     // start running processes
8010485b:	e8 f4 11 00 00       	call   80105a54 <scheduler>

80104860 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80104860:	55                   	push   %ebp
80104861:	89 e5                	mov    %esp,%ebp
80104863:	53                   	push   %ebx
80104864:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80104867:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010486e:	e8 9a fe ff ff       	call   8010470d <p2v>
80104873:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80104876:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010487b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010487f:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80104886:	80 
80104887:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010488a:	89 04 24             	mov    %eax,(%esp)
8010488d:	e8 6b 19 00 00       	call   801061fd <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80104892:	c7 45 f4 80 09 11 80 	movl   $0x80110980,-0xc(%ebp)
80104899:	e9 86 00 00 00       	jmp    80104924 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010489e:	e8 22 f9 ff ff       	call   801041c5 <cpunum>
801048a3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801048a9:	05 80 09 11 80       	add    $0x80110980,%eax
801048ae:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801048b1:	74 69                	je     8010491c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801048b3:	e8 7f f5 ff ff       	call   80103e37 <kalloc>
801048b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801048bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048be:	83 e8 04             	sub    $0x4,%eax
801048c1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801048c4:	81 c2 00 10 00 00    	add    $0x1000,%edx
801048ca:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801048cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048cf:	83 e8 08             	sub    $0x8,%eax
801048d2:	c7 00 f7 47 10 80    	movl   $0x801047f7,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801048d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048db:	8d 58 f4             	lea    -0xc(%eax),%ebx
801048de:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
801048e5:	e8 16 fe ff ff       	call   80104700 <v2p>
801048ea:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801048ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048ef:	89 04 24             	mov    %eax,(%esp)
801048f2:	e8 09 fe ff ff       	call   80104700 <v2p>
801048f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048fa:	0f b6 12             	movzbl (%edx),%edx
801048fd:	0f b6 d2             	movzbl %dl,%edx
80104900:	89 44 24 04          	mov    %eax,0x4(%esp)
80104904:	89 14 24             	mov    %edx,(%esp)
80104907:	e8 3f f9 ff ff       	call   8010424b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010490c:	90                   	nop
8010490d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104910:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104916:	85 c0                	test   %eax,%eax
80104918:	74 f3                	je     8010490d <startothers+0xad>
8010491a:	eb 01                	jmp    8010491d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010491c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010491d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104924:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104929:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010492f:	05 80 09 11 80       	add    $0x80110980,%eax
80104934:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104937:	0f 87 61 ff ff ff    	ja     8010489e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010493d:	83 c4 24             	add    $0x24,%esp
80104940:	5b                   	pop    %ebx
80104941:	5d                   	pop    %ebp
80104942:	c3                   	ret    
	...

80104944 <p2v>:
80104944:	55                   	push   %ebp
80104945:	89 e5                	mov    %esp,%ebp
80104947:	8b 45 08             	mov    0x8(%ebp),%eax
8010494a:	05 00 00 00 80       	add    $0x80000000,%eax
8010494f:	5d                   	pop    %ebp
80104950:	c3                   	ret    

80104951 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80104951:	55                   	push   %ebp
80104952:	89 e5                	mov    %esp,%ebp
80104954:	53                   	push   %ebx
80104955:	83 ec 14             	sub    $0x14,%esp
80104958:	8b 45 08             	mov    0x8(%ebp),%eax
8010495b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010495f:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80104963:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80104967:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010496b:	ec                   	in     (%dx),%al
8010496c:	89 c3                	mov    %eax,%ebx
8010496e:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80104971:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80104975:	83 c4 14             	add    $0x14,%esp
80104978:	5b                   	pop    %ebx
80104979:	5d                   	pop    %ebp
8010497a:	c3                   	ret    

8010497b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010497b:	55                   	push   %ebp
8010497c:	89 e5                	mov    %esp,%ebp
8010497e:	83 ec 08             	sub    $0x8,%esp
80104981:	8b 55 08             	mov    0x8(%ebp),%edx
80104984:	8b 45 0c             	mov    0xc(%ebp),%eax
80104987:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010498b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010498e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104992:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104996:	ee                   	out    %al,(%dx)
}
80104997:	c9                   	leave  
80104998:	c3                   	ret    

80104999 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104999:	55                   	push   %ebp
8010499a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010499c:	a1 64 c6 10 80       	mov    0x8010c664,%eax
801049a1:	89 c2                	mov    %eax,%edx
801049a3:	b8 80 09 11 80       	mov    $0x80110980,%eax
801049a8:	89 d1                	mov    %edx,%ecx
801049aa:	29 c1                	sub    %eax,%ecx
801049ac:	89 c8                	mov    %ecx,%eax
801049ae:	c1 f8 02             	sar    $0x2,%eax
801049b1:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801049b7:	5d                   	pop    %ebp
801049b8:	c3                   	ret    

801049b9 <sum>:

static uchar
sum(uchar *addr, int len)
{
801049b9:	55                   	push   %ebp
801049ba:	89 e5                	mov    %esp,%ebp
801049bc:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801049bf:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801049c6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801049cd:	eb 13                	jmp    801049e2 <sum+0x29>
    sum += addr[i];
801049cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049d2:	03 45 08             	add    0x8(%ebp),%eax
801049d5:	0f b6 00             	movzbl (%eax),%eax
801049d8:	0f b6 c0             	movzbl %al,%eax
801049db:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801049de:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801049e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801049e5:	3b 45 0c             	cmp    0xc(%ebp),%eax
801049e8:	7c e5                	jl     801049cf <sum+0x16>
    sum += addr[i];
  return sum;
801049ea:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801049ed:	c9                   	leave  
801049ee:	c3                   	ret    

801049ef <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801049ef:	55                   	push   %ebp
801049f0:	89 e5                	mov    %esp,%ebp
801049f2:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801049f5:	8b 45 08             	mov    0x8(%ebp),%eax
801049f8:	89 04 24             	mov    %eax,(%esp)
801049fb:	e8 44 ff ff ff       	call   80104944 <p2v>
80104a00:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104a03:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a06:	03 45 f0             	add    -0x10(%ebp),%eax
80104a09:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104a0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a12:	eb 3f                	jmp    80104a53 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104a14:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104a1b:	00 
80104a1c:	c7 44 24 04 e0 99 10 	movl   $0x801099e0,0x4(%esp)
80104a23:	80 
80104a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a27:	89 04 24             	mov    %eax,(%esp)
80104a2a:	e8 72 17 00 00       	call   801061a1 <memcmp>
80104a2f:	85 c0                	test   %eax,%eax
80104a31:	75 1c                	jne    80104a4f <mpsearch1+0x60>
80104a33:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104a3a:	00 
80104a3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3e:	89 04 24             	mov    %eax,(%esp)
80104a41:	e8 73 ff ff ff       	call   801049b9 <sum>
80104a46:	84 c0                	test   %al,%al
80104a48:	75 05                	jne    80104a4f <mpsearch1+0x60>
      return (struct mp*)p;
80104a4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4d:	eb 11                	jmp    80104a60 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80104a4f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80104a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a56:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104a59:	72 b9                	jb     80104a14 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80104a5b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a60:	c9                   	leave  
80104a61:	c3                   	ret    

80104a62 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80104a62:	55                   	push   %ebp
80104a63:	89 e5                	mov    %esp,%ebp
80104a65:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80104a68:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80104a6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a72:	83 c0 0f             	add    $0xf,%eax
80104a75:	0f b6 00             	movzbl (%eax),%eax
80104a78:	0f b6 c0             	movzbl %al,%eax
80104a7b:	89 c2                	mov    %eax,%edx
80104a7d:	c1 e2 08             	shl    $0x8,%edx
80104a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a83:	83 c0 0e             	add    $0xe,%eax
80104a86:	0f b6 00             	movzbl (%eax),%eax
80104a89:	0f b6 c0             	movzbl %al,%eax
80104a8c:	09 d0                	or     %edx,%eax
80104a8e:	c1 e0 04             	shl    $0x4,%eax
80104a91:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104a94:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a98:	74 21                	je     80104abb <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104a9a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104aa1:	00 
80104aa2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aa5:	89 04 24             	mov    %eax,(%esp)
80104aa8:	e8 42 ff ff ff       	call   801049ef <mpsearch1>
80104aad:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104ab0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104ab4:	74 50                	je     80104b06 <mpsearch+0xa4>
      return mp;
80104ab6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104ab9:	eb 5f                	jmp    80104b1a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104abb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abe:	83 c0 14             	add    $0x14,%eax
80104ac1:	0f b6 00             	movzbl (%eax),%eax
80104ac4:	0f b6 c0             	movzbl %al,%eax
80104ac7:	89 c2                	mov    %eax,%edx
80104ac9:	c1 e2 08             	shl    $0x8,%edx
80104acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104acf:	83 c0 13             	add    $0x13,%eax
80104ad2:	0f b6 00             	movzbl (%eax),%eax
80104ad5:	0f b6 c0             	movzbl %al,%eax
80104ad8:	09 d0                	or     %edx,%eax
80104ada:	c1 e0 0a             	shl    $0xa,%eax
80104add:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104ae0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ae3:	2d 00 04 00 00       	sub    $0x400,%eax
80104ae8:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104aef:	00 
80104af0:	89 04 24             	mov    %eax,(%esp)
80104af3:	e8 f7 fe ff ff       	call   801049ef <mpsearch1>
80104af8:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104afb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104aff:	74 05                	je     80104b06 <mpsearch+0xa4>
      return mp;
80104b01:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b04:	eb 14                	jmp    80104b1a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104b06:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104b0d:	00 
80104b0e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104b15:	e8 d5 fe ff ff       	call   801049ef <mpsearch1>
}
80104b1a:	c9                   	leave  
80104b1b:	c3                   	ret    

80104b1c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104b1c:	55                   	push   %ebp
80104b1d:	89 e5                	mov    %esp,%ebp
80104b1f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104b22:	e8 3b ff ff ff       	call   80104a62 <mpsearch>
80104b27:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104b2a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b2e:	74 0a                	je     80104b3a <mpconfig+0x1e>
80104b30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b33:	8b 40 04             	mov    0x4(%eax),%eax
80104b36:	85 c0                	test   %eax,%eax
80104b38:	75 0a                	jne    80104b44 <mpconfig+0x28>
    return 0;
80104b3a:	b8 00 00 00 00       	mov    $0x0,%eax
80104b3f:	e9 83 00 00 00       	jmp    80104bc7 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b47:	8b 40 04             	mov    0x4(%eax),%eax
80104b4a:	89 04 24             	mov    %eax,(%esp)
80104b4d:	e8 f2 fd ff ff       	call   80104944 <p2v>
80104b52:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104b55:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104b5c:	00 
80104b5d:	c7 44 24 04 e5 99 10 	movl   $0x801099e5,0x4(%esp)
80104b64:	80 
80104b65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b68:	89 04 24             	mov    %eax,(%esp)
80104b6b:	e8 31 16 00 00       	call   801061a1 <memcmp>
80104b70:	85 c0                	test   %eax,%eax
80104b72:	74 07                	je     80104b7b <mpconfig+0x5f>
    return 0;
80104b74:	b8 00 00 00 00       	mov    $0x0,%eax
80104b79:	eb 4c                	jmp    80104bc7 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80104b7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b7e:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104b82:	3c 01                	cmp    $0x1,%al
80104b84:	74 12                	je     80104b98 <mpconfig+0x7c>
80104b86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b89:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104b8d:	3c 04                	cmp    $0x4,%al
80104b8f:	74 07                	je     80104b98 <mpconfig+0x7c>
    return 0;
80104b91:	b8 00 00 00 00       	mov    $0x0,%eax
80104b96:	eb 2f                	jmp    80104bc7 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104b98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b9b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104b9f:	0f b7 c0             	movzwl %ax,%eax
80104ba2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ba6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ba9:	89 04 24             	mov    %eax,(%esp)
80104bac:	e8 08 fe ff ff       	call   801049b9 <sum>
80104bb1:	84 c0                	test   %al,%al
80104bb3:	74 07                	je     80104bbc <mpconfig+0xa0>
    return 0;
80104bb5:	b8 00 00 00 00       	mov    $0x0,%eax
80104bba:	eb 0b                	jmp    80104bc7 <mpconfig+0xab>
  *pmp = mp;
80104bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80104bbf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bc2:	89 10                	mov    %edx,(%eax)
  return conf;
80104bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104bc7:	c9                   	leave  
80104bc8:	c3                   	ret    

80104bc9 <mpinit>:

void
mpinit(void)
{
80104bc9:	55                   	push   %ebp
80104bca:	89 e5                	mov    %esp,%ebp
80104bcc:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104bcf:	c7 05 64 c6 10 80 80 	movl   $0x80110980,0x8010c664
80104bd6:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104bd9:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104bdc:	89 04 24             	mov    %eax,(%esp)
80104bdf:	e8 38 ff ff ff       	call   80104b1c <mpconfig>
80104be4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104be7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104beb:	0f 84 9c 01 00 00    	je     80104d8d <mpinit+0x1c4>
    return;
  ismp = 1;
80104bf1:	c7 05 64 09 11 80 01 	movl   $0x1,0x80110964
80104bf8:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104bfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bfe:	8b 40 24             	mov    0x24(%eax),%eax
80104c01:	a3 dc 08 11 80       	mov    %eax,0x801108dc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c09:	83 c0 2c             	add    $0x2c,%eax
80104c0c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104c0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c12:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104c16:	0f b7 c0             	movzwl %ax,%eax
80104c19:	03 45 f0             	add    -0x10(%ebp),%eax
80104c1c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104c1f:	e9 f4 00 00 00       	jmp    80104d18 <mpinit+0x14f>
    switch(*p){
80104c24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c27:	0f b6 00             	movzbl (%eax),%eax
80104c2a:	0f b6 c0             	movzbl %al,%eax
80104c2d:	83 f8 04             	cmp    $0x4,%eax
80104c30:	0f 87 bf 00 00 00    	ja     80104cf5 <mpinit+0x12c>
80104c36:	8b 04 85 28 9a 10 80 	mov    -0x7fef65d8(,%eax,4),%eax
80104c3d:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104c3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c42:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104c45:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104c48:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104c4c:	0f b6 d0             	movzbl %al,%edx
80104c4f:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c54:	39 c2                	cmp    %eax,%edx
80104c56:	74 2d                	je     80104c85 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104c58:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104c5b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104c5f:	0f b6 d0             	movzbl %al,%edx
80104c62:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c67:	89 54 24 08          	mov    %edx,0x8(%esp)
80104c6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c6f:	c7 04 24 ea 99 10 80 	movl   $0x801099ea,(%esp)
80104c76:	e8 26 b7 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104c7b:	c7 05 64 09 11 80 00 	movl   $0x0,0x80110964
80104c82:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104c85:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104c88:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104c8c:	0f b6 c0             	movzbl %al,%eax
80104c8f:	83 e0 02             	and    $0x2,%eax
80104c92:	85 c0                	test   %eax,%eax
80104c94:	74 15                	je     80104cab <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104c96:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c9b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104ca1:	05 80 09 11 80       	add    $0x80110980,%eax
80104ca6:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104cab:	8b 15 60 0f 11 80    	mov    0x80110f60,%edx
80104cb1:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104cb6:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104cbc:	81 c2 80 09 11 80    	add    $0x80110980,%edx
80104cc2:	88 02                	mov    %al,(%edx)
      ncpu++;
80104cc4:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104cc9:	83 c0 01             	add    $0x1,%eax
80104ccc:	a3 60 0f 11 80       	mov    %eax,0x80110f60
      p += sizeof(struct mpproc);
80104cd1:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104cd5:	eb 41                	jmp    80104d18 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104cd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104cdd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104ce0:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104ce4:	a2 60 09 11 80       	mov    %al,0x80110960
      p += sizeof(struct mpioapic);
80104ce9:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104ced:	eb 29                	jmp    80104d18 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104cef:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104cf3:	eb 23                	jmp    80104d18 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104cf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf8:	0f b6 00             	movzbl (%eax),%eax
80104cfb:	0f b6 c0             	movzbl %al,%eax
80104cfe:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d02:	c7 04 24 08 9a 10 80 	movl   $0x80109a08,(%esp)
80104d09:	e8 93 b6 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104d0e:	c7 05 64 09 11 80 00 	movl   $0x0,0x80110964
80104d15:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104d18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d1b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104d1e:	0f 82 00 ff ff ff    	jb     80104c24 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104d24:	a1 64 09 11 80       	mov    0x80110964,%eax
80104d29:	85 c0                	test   %eax,%eax
80104d2b:	75 1d                	jne    80104d4a <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104d2d:	c7 05 60 0f 11 80 01 	movl   $0x1,0x80110f60
80104d34:	00 00 00 
    lapic = 0;
80104d37:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80104d3e:	00 00 00 
    ioapicid = 0;
80104d41:	c6 05 60 09 11 80 00 	movb   $0x0,0x80110960
    return;
80104d48:	eb 44                	jmp    80104d8e <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104d4a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104d4d:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104d51:	84 c0                	test   %al,%al
80104d53:	74 39                	je     80104d8e <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104d55:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104d5c:	00 
80104d5d:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104d64:	e8 12 fc ff ff       	call   8010497b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104d69:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104d70:	e8 dc fb ff ff       	call   80104951 <inb>
80104d75:	83 c8 01             	or     $0x1,%eax
80104d78:	0f b6 c0             	movzbl %al,%eax
80104d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d7f:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104d86:	e8 f0 fb ff ff       	call   8010497b <outb>
80104d8b:	eb 01                	jmp    80104d8e <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104d8d:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104d8e:	c9                   	leave  
80104d8f:	c3                   	ret    

80104d90 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104d90:	55                   	push   %ebp
80104d91:	89 e5                	mov    %esp,%ebp
80104d93:	83 ec 08             	sub    $0x8,%esp
80104d96:	8b 55 08             	mov    0x8(%ebp),%edx
80104d99:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d9c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104da0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104da3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104da7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104dab:	ee                   	out    %al,(%dx)
}
80104dac:	c9                   	leave  
80104dad:	c3                   	ret    

80104dae <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104dae:	55                   	push   %ebp
80104daf:	89 e5                	mov    %esp,%ebp
80104db1:	83 ec 0c             	sub    $0xc,%esp
80104db4:	8b 45 08             	mov    0x8(%ebp),%eax
80104db7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104dbb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104dbf:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104dc5:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104dc9:	0f b6 c0             	movzbl %al,%eax
80104dcc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104dd0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104dd7:	e8 b4 ff ff ff       	call   80104d90 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104ddc:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104de0:	66 c1 e8 08          	shr    $0x8,%ax
80104de4:	0f b6 c0             	movzbl %al,%eax
80104de7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104deb:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104df2:	e8 99 ff ff ff       	call   80104d90 <outb>
}
80104df7:	c9                   	leave  
80104df8:	c3                   	ret    

80104df9 <picenable>:

void
picenable(int irq)
{
80104df9:	55                   	push   %ebp
80104dfa:	89 e5                	mov    %esp,%ebp
80104dfc:	53                   	push   %ebx
80104dfd:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104e00:	8b 45 08             	mov    0x8(%ebp),%eax
80104e03:	ba 01 00 00 00       	mov    $0x1,%edx
80104e08:	89 d3                	mov    %edx,%ebx
80104e0a:	89 c1                	mov    %eax,%ecx
80104e0c:	d3 e3                	shl    %cl,%ebx
80104e0e:	89 d8                	mov    %ebx,%eax
80104e10:	89 c2                	mov    %eax,%edx
80104e12:	f7 d2                	not    %edx
80104e14:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104e1b:	21 d0                	and    %edx,%eax
80104e1d:	0f b7 c0             	movzwl %ax,%eax
80104e20:	89 04 24             	mov    %eax,(%esp)
80104e23:	e8 86 ff ff ff       	call   80104dae <picsetmask>
}
80104e28:	83 c4 04             	add    $0x4,%esp
80104e2b:	5b                   	pop    %ebx
80104e2c:	5d                   	pop    %ebp
80104e2d:	c3                   	ret    

80104e2e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104e2e:	55                   	push   %ebp
80104e2f:	89 e5                	mov    %esp,%ebp
80104e31:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104e34:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104e3b:	00 
80104e3c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104e43:	e8 48 ff ff ff       	call   80104d90 <outb>
  outb(IO_PIC2+1, 0xFF);
80104e48:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104e4f:	00 
80104e50:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e57:	e8 34 ff ff ff       	call   80104d90 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104e5c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104e63:	00 
80104e64:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104e6b:	e8 20 ff ff ff       	call   80104d90 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104e70:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104e77:	00 
80104e78:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104e7f:	e8 0c ff ff ff       	call   80104d90 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104e84:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104e8b:	00 
80104e8c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104e93:	e8 f8 fe ff ff       	call   80104d90 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104e98:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104e9f:	00 
80104ea0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104ea7:	e8 e4 fe ff ff       	call   80104d90 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104eac:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104eb3:	00 
80104eb4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104ebb:	e8 d0 fe ff ff       	call   80104d90 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104ec0:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104ec7:	00 
80104ec8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104ecf:	e8 bc fe ff ff       	call   80104d90 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104ed4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104edb:	00 
80104edc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104ee3:	e8 a8 fe ff ff       	call   80104d90 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104ee8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104eef:	00 
80104ef0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104ef7:	e8 94 fe ff ff       	call   80104d90 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104efc:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104f03:	00 
80104f04:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104f0b:	e8 80 fe ff ff       	call   80104d90 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104f10:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104f17:	00 
80104f18:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104f1f:	e8 6c fe ff ff       	call   80104d90 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104f24:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104f2b:	00 
80104f2c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104f33:	e8 58 fe ff ff       	call   80104d90 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104f38:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104f3f:	00 
80104f40:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104f47:	e8 44 fe ff ff       	call   80104d90 <outb>

  if(irqmask != 0xFFFF)
80104f4c:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104f53:	66 83 f8 ff          	cmp    $0xffff,%ax
80104f57:	74 12                	je     80104f6b <picinit+0x13d>
    picsetmask(irqmask);
80104f59:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104f60:	0f b7 c0             	movzwl %ax,%eax
80104f63:	89 04 24             	mov    %eax,(%esp)
80104f66:	e8 43 fe ff ff       	call   80104dae <picsetmask>
}
80104f6b:	c9                   	leave  
80104f6c:	c3                   	ret    
80104f6d:	00 00                	add    %al,(%eax)
	...

80104f70 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104f70:	55                   	push   %ebp
80104f71:	89 e5                	mov    %esp,%ebp
80104f73:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104f76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f80:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104f86:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f89:	8b 10                	mov    (%eax),%edx
80104f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f8e:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104f90:	e8 87 bf ff ff       	call   80100f1c <filealloc>
80104f95:	8b 55 08             	mov    0x8(%ebp),%edx
80104f98:	89 02                	mov    %eax,(%edx)
80104f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9d:	8b 00                	mov    (%eax),%eax
80104f9f:	85 c0                	test   %eax,%eax
80104fa1:	0f 84 c8 00 00 00    	je     8010506f <pipealloc+0xff>
80104fa7:	e8 70 bf ff ff       	call   80100f1c <filealloc>
80104fac:	8b 55 0c             	mov    0xc(%ebp),%edx
80104faf:	89 02                	mov    %eax,(%edx)
80104fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb4:	8b 00                	mov    (%eax),%eax
80104fb6:	85 c0                	test   %eax,%eax
80104fb8:	0f 84 b1 00 00 00    	je     8010506f <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104fbe:	e8 74 ee ff ff       	call   80103e37 <kalloc>
80104fc3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104fc6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104fca:	0f 84 9e 00 00 00    	je     8010506e <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104fd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fd3:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104fda:	00 00 00 
  p->writeopen = 1;
80104fdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fe0:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104fe7:	00 00 00 
  p->nwrite = 0;
80104fea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fed:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104ff4:	00 00 00 
  p->nread = 0;
80104ff7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ffa:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80105001:	00 00 00 
  initlock(&p->lock, "pipe");
80105004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105007:	c7 44 24 04 3c 9a 10 	movl   $0x80109a3c,0x4(%esp)
8010500e:	80 
8010500f:	89 04 24             	mov    %eax,(%esp)
80105012:	e8 a3 0e 00 00       	call   80105eba <initlock>
  (*f0)->type = FD_PIPE;
80105017:	8b 45 08             	mov    0x8(%ebp),%eax
8010501a:	8b 00                	mov    (%eax),%eax
8010501c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80105022:	8b 45 08             	mov    0x8(%ebp),%eax
80105025:	8b 00                	mov    (%eax),%eax
80105027:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010502b:	8b 45 08             	mov    0x8(%ebp),%eax
8010502e:	8b 00                	mov    (%eax),%eax
80105030:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80105034:	8b 45 08             	mov    0x8(%ebp),%eax
80105037:	8b 00                	mov    (%eax),%eax
80105039:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010503c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010503f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105042:	8b 00                	mov    (%eax),%eax
80105044:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010504a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010504d:	8b 00                	mov    (%eax),%eax
8010504f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80105053:	8b 45 0c             	mov    0xc(%ebp),%eax
80105056:	8b 00                	mov    (%eax),%eax
80105058:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010505c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010505f:	8b 00                	mov    (%eax),%eax
80105061:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105064:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80105067:	b8 00 00 00 00       	mov    $0x0,%eax
8010506c:	eb 43                	jmp    801050b1 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
8010506e:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
8010506f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105073:	74 0b                	je     80105080 <pipealloc+0x110>
    kfree((char*)p);
80105075:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105078:	89 04 24             	mov    %eax,(%esp)
8010507b:	e8 1e ed ff ff       	call   80103d9e <kfree>
  if(*f0)
80105080:	8b 45 08             	mov    0x8(%ebp),%eax
80105083:	8b 00                	mov    (%eax),%eax
80105085:	85 c0                	test   %eax,%eax
80105087:	74 0d                	je     80105096 <pipealloc+0x126>
    fileclose(*f0);
80105089:	8b 45 08             	mov    0x8(%ebp),%eax
8010508c:	8b 00                	mov    (%eax),%eax
8010508e:	89 04 24             	mov    %eax,(%esp)
80105091:	e8 2e bf ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80105096:	8b 45 0c             	mov    0xc(%ebp),%eax
80105099:	8b 00                	mov    (%eax),%eax
8010509b:	85 c0                	test   %eax,%eax
8010509d:	74 0d                	je     801050ac <pipealloc+0x13c>
    fileclose(*f1);
8010509f:	8b 45 0c             	mov    0xc(%ebp),%eax
801050a2:	8b 00                	mov    (%eax),%eax
801050a4:	89 04 24             	mov    %eax,(%esp)
801050a7:	e8 18 bf ff ff       	call   80100fc4 <fileclose>
  return -1;
801050ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801050b1:	c9                   	leave  
801050b2:	c3                   	ret    

801050b3 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801050b3:	55                   	push   %ebp
801050b4:	89 e5                	mov    %esp,%ebp
801050b6:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801050b9:	8b 45 08             	mov    0x8(%ebp),%eax
801050bc:	89 04 24             	mov    %eax,(%esp)
801050bf:	e8 17 0e 00 00       	call   80105edb <acquire>
  if(writable){
801050c4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801050c8:	74 1f                	je     801050e9 <pipeclose+0x36>
    p->writeopen = 0;
801050ca:	8b 45 08             	mov    0x8(%ebp),%eax
801050cd:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801050d4:	00 00 00 
    wakeup(&p->nread);
801050d7:	8b 45 08             	mov    0x8(%ebp),%eax
801050da:	05 34 02 00 00       	add    $0x234,%eax
801050df:	89 04 24             	mov    %eax,(%esp)
801050e2:	e8 ef 0b 00 00       	call   80105cd6 <wakeup>
801050e7:	eb 1d                	jmp    80105106 <pipeclose+0x53>
  } else {
    p->readopen = 0;
801050e9:	8b 45 08             	mov    0x8(%ebp),%eax
801050ec:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801050f3:	00 00 00 
    wakeup(&p->nwrite);
801050f6:	8b 45 08             	mov    0x8(%ebp),%eax
801050f9:	05 38 02 00 00       	add    $0x238,%eax
801050fe:	89 04 24             	mov    %eax,(%esp)
80105101:	e8 d0 0b 00 00       	call   80105cd6 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80105106:	8b 45 08             	mov    0x8(%ebp),%eax
80105109:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010510f:	85 c0                	test   %eax,%eax
80105111:	75 25                	jne    80105138 <pipeclose+0x85>
80105113:	8b 45 08             	mov    0x8(%ebp),%eax
80105116:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010511c:	85 c0                	test   %eax,%eax
8010511e:	75 18                	jne    80105138 <pipeclose+0x85>
    release(&p->lock);
80105120:	8b 45 08             	mov    0x8(%ebp),%eax
80105123:	89 04 24             	mov    %eax,(%esp)
80105126:	e8 12 0e 00 00       	call   80105f3d <release>
    kfree((char*)p);
8010512b:	8b 45 08             	mov    0x8(%ebp),%eax
8010512e:	89 04 24             	mov    %eax,(%esp)
80105131:	e8 68 ec ff ff       	call   80103d9e <kfree>
80105136:	eb 0b                	jmp    80105143 <pipeclose+0x90>
  } else
    release(&p->lock);
80105138:	8b 45 08             	mov    0x8(%ebp),%eax
8010513b:	89 04 24             	mov    %eax,(%esp)
8010513e:	e8 fa 0d 00 00       	call   80105f3d <release>
}
80105143:	c9                   	leave  
80105144:	c3                   	ret    

80105145 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80105145:	55                   	push   %ebp
80105146:	89 e5                	mov    %esp,%ebp
80105148:	53                   	push   %ebx
80105149:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010514c:	8b 45 08             	mov    0x8(%ebp),%eax
8010514f:	89 04 24             	mov    %eax,(%esp)
80105152:	e8 84 0d 00 00       	call   80105edb <acquire>
  for(i = 0; i < n; i++){
80105157:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010515e:	e9 a6 00 00 00       	jmp    80105209 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80105163:	8b 45 08             	mov    0x8(%ebp),%eax
80105166:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010516c:	85 c0                	test   %eax,%eax
8010516e:	74 0d                	je     8010517d <pipewrite+0x38>
80105170:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105176:	8b 40 24             	mov    0x24(%eax),%eax
80105179:	85 c0                	test   %eax,%eax
8010517b:	74 15                	je     80105192 <pipewrite+0x4d>
        release(&p->lock);
8010517d:	8b 45 08             	mov    0x8(%ebp),%eax
80105180:	89 04 24             	mov    %eax,(%esp)
80105183:	e8 b5 0d 00 00       	call   80105f3d <release>
        return -1;
80105188:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010518d:	e9 9d 00 00 00       	jmp    8010522f <pipewrite+0xea>
      }
      wakeup(&p->nread);
80105192:	8b 45 08             	mov    0x8(%ebp),%eax
80105195:	05 34 02 00 00       	add    $0x234,%eax
8010519a:	89 04 24             	mov    %eax,(%esp)
8010519d:	e8 34 0b 00 00       	call   80105cd6 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801051a2:	8b 45 08             	mov    0x8(%ebp),%eax
801051a5:	8b 55 08             	mov    0x8(%ebp),%edx
801051a8:	81 c2 38 02 00 00    	add    $0x238,%edx
801051ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801051b2:	89 14 24             	mov    %edx,(%esp)
801051b5:	e8 43 0a 00 00       	call   80105bfd <sleep>
801051ba:	eb 01                	jmp    801051bd <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801051bc:	90                   	nop
801051bd:	8b 45 08             	mov    0x8(%ebp),%eax
801051c0:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801051c6:	8b 45 08             	mov    0x8(%ebp),%eax
801051c9:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801051cf:	05 00 02 00 00       	add    $0x200,%eax
801051d4:	39 c2                	cmp    %eax,%edx
801051d6:	74 8b                	je     80105163 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801051d8:	8b 45 08             	mov    0x8(%ebp),%eax
801051db:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801051e1:	89 c3                	mov    %eax,%ebx
801051e3:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801051e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801051ec:	03 55 0c             	add    0xc(%ebp),%edx
801051ef:	0f b6 0a             	movzbl (%edx),%ecx
801051f2:	8b 55 08             	mov    0x8(%ebp),%edx
801051f5:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801051f9:	8d 50 01             	lea    0x1(%eax),%edx
801051fc:	8b 45 08             	mov    0x8(%ebp),%eax
801051ff:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80105205:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105209:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010520c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010520f:	7c ab                	jl     801051bc <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80105211:	8b 45 08             	mov    0x8(%ebp),%eax
80105214:	05 34 02 00 00       	add    $0x234,%eax
80105219:	89 04 24             	mov    %eax,(%esp)
8010521c:	e8 b5 0a 00 00       	call   80105cd6 <wakeup>
  release(&p->lock);
80105221:	8b 45 08             	mov    0x8(%ebp),%eax
80105224:	89 04 24             	mov    %eax,(%esp)
80105227:	e8 11 0d 00 00       	call   80105f3d <release>
  return n;
8010522c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010522f:	83 c4 24             	add    $0x24,%esp
80105232:	5b                   	pop    %ebx
80105233:	5d                   	pop    %ebp
80105234:	c3                   	ret    

80105235 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80105235:	55                   	push   %ebp
80105236:	89 e5                	mov    %esp,%ebp
80105238:	53                   	push   %ebx
80105239:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010523c:	8b 45 08             	mov    0x8(%ebp),%eax
8010523f:	89 04 24             	mov    %eax,(%esp)
80105242:	e8 94 0c 00 00       	call   80105edb <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80105247:	eb 3a                	jmp    80105283 <piperead+0x4e>
    if(proc->killed){
80105249:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010524f:	8b 40 24             	mov    0x24(%eax),%eax
80105252:	85 c0                	test   %eax,%eax
80105254:	74 15                	je     8010526b <piperead+0x36>
      release(&p->lock);
80105256:	8b 45 08             	mov    0x8(%ebp),%eax
80105259:	89 04 24             	mov    %eax,(%esp)
8010525c:	e8 dc 0c 00 00       	call   80105f3d <release>
      return -1;
80105261:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105266:	e9 b6 00 00 00       	jmp    80105321 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010526b:	8b 45 08             	mov    0x8(%ebp),%eax
8010526e:	8b 55 08             	mov    0x8(%ebp),%edx
80105271:	81 c2 34 02 00 00    	add    $0x234,%edx
80105277:	89 44 24 04          	mov    %eax,0x4(%esp)
8010527b:	89 14 24             	mov    %edx,(%esp)
8010527e:	e8 7a 09 00 00       	call   80105bfd <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80105283:	8b 45 08             	mov    0x8(%ebp),%eax
80105286:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010528c:	8b 45 08             	mov    0x8(%ebp),%eax
8010528f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105295:	39 c2                	cmp    %eax,%edx
80105297:	75 0d                	jne    801052a6 <piperead+0x71>
80105299:	8b 45 08             	mov    0x8(%ebp),%eax
8010529c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801052a2:	85 c0                	test   %eax,%eax
801052a4:	75 a3                	jne    80105249 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801052a6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801052ad:	eb 49                	jmp    801052f8 <piperead+0xc3>
    if(p->nread == p->nwrite)
801052af:	8b 45 08             	mov    0x8(%ebp),%eax
801052b2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801052b8:	8b 45 08             	mov    0x8(%ebp),%eax
801052bb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801052c1:	39 c2                	cmp    %eax,%edx
801052c3:	74 3d                	je     80105302 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801052c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c8:	89 c2                	mov    %eax,%edx
801052ca:	03 55 0c             	add    0xc(%ebp),%edx
801052cd:	8b 45 08             	mov    0x8(%ebp),%eax
801052d0:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801052d6:	89 c3                	mov    %eax,%ebx
801052d8:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801052de:	8b 4d 08             	mov    0x8(%ebp),%ecx
801052e1:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801052e6:	88 0a                	mov    %cl,(%edx)
801052e8:	8d 50 01             	lea    0x1(%eax),%edx
801052eb:	8b 45 08             	mov    0x8(%ebp),%eax
801052ee:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801052f4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801052f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052fb:	3b 45 10             	cmp    0x10(%ebp),%eax
801052fe:	7c af                	jl     801052af <piperead+0x7a>
80105300:	eb 01                	jmp    80105303 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80105302:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80105303:	8b 45 08             	mov    0x8(%ebp),%eax
80105306:	05 38 02 00 00       	add    $0x238,%eax
8010530b:	89 04 24             	mov    %eax,(%esp)
8010530e:	e8 c3 09 00 00       	call   80105cd6 <wakeup>
  release(&p->lock);
80105313:	8b 45 08             	mov    0x8(%ebp),%eax
80105316:	89 04 24             	mov    %eax,(%esp)
80105319:	e8 1f 0c 00 00       	call   80105f3d <release>
  return i;
8010531e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105321:	83 c4 24             	add    $0x24,%esp
80105324:	5b                   	pop    %ebx
80105325:	5d                   	pop    %ebp
80105326:	c3                   	ret    
	...

80105328 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105328:	55                   	push   %ebp
80105329:	89 e5                	mov    %esp,%ebp
8010532b:	53                   	push   %ebx
8010532c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010532f:	9c                   	pushf  
80105330:	5b                   	pop    %ebx
80105331:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105334:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105337:	83 c4 10             	add    $0x10,%esp
8010533a:	5b                   	pop    %ebx
8010533b:	5d                   	pop    %ebp
8010533c:	c3                   	ret    

8010533d <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010533d:	55                   	push   %ebp
8010533e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105340:	fb                   	sti    
}
80105341:	5d                   	pop    %ebp
80105342:	c3                   	ret    

80105343 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80105343:	55                   	push   %ebp
80105344:	89 e5                	mov    %esp,%ebp
80105346:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80105349:	c7 44 24 04 41 9a 10 	movl   $0x80109a41,0x4(%esp)
80105350:	80 
80105351:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105358:	e8 5d 0b 00 00       	call   80105eba <initlock>
}
8010535d:	c9                   	leave  
8010535e:	c3                   	ret    

8010535f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010535f:	55                   	push   %ebp
80105360:	89 e5                	mov    %esp,%ebp
80105362:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80105365:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
8010536c:	e8 6a 0b 00 00       	call   80105edb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105371:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105378:	eb 0e                	jmp    80105388 <allocproc+0x29>
    if(p->state == UNUSED)
8010537a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010537d:	8b 40 0c             	mov    0xc(%eax),%eax
80105380:	85 c0                	test   %eax,%eax
80105382:	74 23                	je     801053a7 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105384:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105388:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
8010538f:	72 e9                	jb     8010537a <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80105391:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105398:	e8 a0 0b 00 00       	call   80105f3d <release>
  return 0;
8010539d:	b8 00 00 00 00       	mov    $0x0,%eax
801053a2:	e9 b5 00 00 00       	jmp    8010545c <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801053a7:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801053a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053ab:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801053b2:	a1 04 c0 10 80       	mov    0x8010c004,%eax
801053b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053ba:	89 42 10             	mov    %eax,0x10(%edx)
801053bd:	83 c0 01             	add    $0x1,%eax
801053c0:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
801053c5:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801053cc:	e8 6c 0b 00 00       	call   80105f3d <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801053d1:	e8 61 ea ff ff       	call   80103e37 <kalloc>
801053d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053d9:	89 42 08             	mov    %eax,0x8(%edx)
801053dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053df:	8b 40 08             	mov    0x8(%eax),%eax
801053e2:	85 c0                	test   %eax,%eax
801053e4:	75 11                	jne    801053f7 <allocproc+0x98>
    p->state = UNUSED;
801053e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053e9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801053f0:	b8 00 00 00 00       	mov    $0x0,%eax
801053f5:	eb 65                	jmp    8010545c <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801053f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fa:	8b 40 08             	mov    0x8(%eax),%eax
801053fd:	05 00 10 00 00       	add    $0x1000,%eax
80105402:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80105405:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80105409:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010540c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010540f:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80105412:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80105416:	ba 44 77 10 80       	mov    $0x80107744,%edx
8010541b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010541e:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80105420:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80105424:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105427:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010542a:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010542d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105430:	8b 40 1c             	mov    0x1c(%eax),%eax
80105433:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010543a:	00 
8010543b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105442:	00 
80105443:	89 04 24             	mov    %eax,(%esp)
80105446:	e8 df 0c 00 00       	call   8010612a <memset>
  p->context->eip = (uint)forkret;
8010544b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010544e:	8b 40 1c             	mov    0x1c(%eax),%eax
80105451:	ba d1 5b 10 80       	mov    $0x80105bd1,%edx
80105456:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80105459:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010545c:	c9                   	leave  
8010545d:	c3                   	ret    

8010545e <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010545e:	55                   	push   %ebp
8010545f:	89 e5                	mov    %esp,%ebp
80105461:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80105464:	e8 f6 fe ff ff       	call   8010535f <allocproc>
80105469:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
8010546c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546f:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80105474:	c7 04 24 37 3e 10 80 	movl   $0x80103e37,(%esp)
8010547b:	e8 c1 39 00 00       	call   80108e41 <setupkvm>
80105480:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105483:	89 42 04             	mov    %eax,0x4(%edx)
80105486:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105489:	8b 40 04             	mov    0x4(%eax),%eax
8010548c:	85 c0                	test   %eax,%eax
8010548e:	75 0c                	jne    8010549c <userinit+0x3e>
    panic("userinit: out of memory?");
80105490:	c7 04 24 48 9a 10 80 	movl   $0x80109a48,(%esp)
80105497:	e8 a1 b0 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010549c:	ba 2c 00 00 00       	mov    $0x2c,%edx
801054a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a4:	8b 40 04             	mov    0x4(%eax),%eax
801054a7:	89 54 24 08          	mov    %edx,0x8(%esp)
801054ab:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
801054b2:	80 
801054b3:	89 04 24             	mov    %eax,(%esp)
801054b6:	e8 de 3b 00 00       	call   80109099 <inituvm>
  p->sz = PGSIZE;
801054bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054be:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801054c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054c7:	8b 40 18             	mov    0x18(%eax),%eax
801054ca:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801054d1:	00 
801054d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054d9:	00 
801054da:	89 04 24             	mov    %eax,(%esp)
801054dd:	e8 48 0c 00 00       	call   8010612a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801054e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054e5:	8b 40 18             	mov    0x18(%eax),%eax
801054e8:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801054ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054f1:	8b 40 18             	mov    0x18(%eax),%eax
801054f4:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801054fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054fd:	8b 40 18             	mov    0x18(%eax),%eax
80105500:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105503:	8b 52 18             	mov    0x18(%edx),%edx
80105506:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010550a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010550e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105511:	8b 40 18             	mov    0x18(%eax),%eax
80105514:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105517:	8b 52 18             	mov    0x18(%edx),%edx
8010551a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010551e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80105522:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105525:	8b 40 18             	mov    0x18(%eax),%eax
80105528:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010552f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105532:	8b 40 18             	mov    0x18(%eax),%eax
80105535:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010553c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010553f:	8b 40 18             	mov    0x18(%eax),%eax
80105542:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105549:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010554c:	83 c0 6c             	add    $0x6c,%eax
8010554f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105556:	00 
80105557:	c7 44 24 04 61 9a 10 	movl   $0x80109a61,0x4(%esp)
8010555e:	80 
8010555f:	89 04 24             	mov    %eax,(%esp)
80105562:	e8 f3 0d 00 00       	call   8010635a <safestrcpy>
  p->cwd = namei("/");
80105567:	c7 04 24 6a 9a 10 80 	movl   $0x80109a6a,(%esp)
8010556e:	e8 43 de ff ff       	call   801033b6 <namei>
80105573:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105576:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;  
80105579:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010557c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80105583:	c9                   	leave  
80105584:	c3                   	ret    

80105585 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80105585:	55                   	push   %ebp
80105586:	89 e5                	mov    %esp,%ebp
80105588:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010558b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105591:	8b 00                	mov    (%eax),%eax
80105593:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105596:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010559a:	7e 34                	jle    801055d0 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010559c:	8b 45 08             	mov    0x8(%ebp),%eax
8010559f:	89 c2                	mov    %eax,%edx
801055a1:	03 55 f4             	add    -0xc(%ebp),%edx
801055a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055aa:	8b 40 04             	mov    0x4(%eax),%eax
801055ad:	89 54 24 08          	mov    %edx,0x8(%esp)
801055b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055b4:	89 54 24 04          	mov    %edx,0x4(%esp)
801055b8:	89 04 24             	mov    %eax,(%esp)
801055bb:	e8 53 3c 00 00       	call   80109213 <allocuvm>
801055c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801055c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801055c7:	75 41                	jne    8010560a <growproc+0x85>
      return -1;
801055c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055ce:	eb 58                	jmp    80105628 <growproc+0xa3>
  } else if(n < 0){
801055d0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801055d4:	79 34                	jns    8010560a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801055d6:	8b 45 08             	mov    0x8(%ebp),%eax
801055d9:	89 c2                	mov    %eax,%edx
801055db:	03 55 f4             	add    -0xc(%ebp),%edx
801055de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055e4:	8b 40 04             	mov    0x4(%eax),%eax
801055e7:	89 54 24 08          	mov    %edx,0x8(%esp)
801055eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801055f2:	89 04 24             	mov    %eax,(%esp)
801055f5:	e8 f3 3c 00 00       	call   801092ed <deallocuvm>
801055fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
801055fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105601:	75 07                	jne    8010560a <growproc+0x85>
      return -1;
80105603:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105608:	eb 1e                	jmp    80105628 <growproc+0xa3>
  }
  proc->sz = sz;
8010560a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105610:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105613:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105615:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010561b:	89 04 24             	mov    %eax,(%esp)
8010561e:	e8 0f 39 00 00       	call   80108f32 <switchuvm>
  return 0;
80105623:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105628:	c9                   	leave  
80105629:	c3                   	ret    

8010562a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010562a:	55                   	push   %ebp
8010562b:	89 e5                	mov    %esp,%ebp
8010562d:	57                   	push   %edi
8010562e:	56                   	push   %esi
8010562f:	53                   	push   %ebx
80105630:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80105633:	e8 27 fd ff ff       	call   8010535f <allocproc>
80105638:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010563b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010563f:	75 0a                	jne    8010564b <fork+0x21>
    return -1;
80105641:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105646:	e9 3a 01 00 00       	jmp    80105785 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010564b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105651:	8b 10                	mov    (%eax),%edx
80105653:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105659:	8b 40 04             	mov    0x4(%eax),%eax
8010565c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105660:	89 04 24             	mov    %eax,(%esp)
80105663:	e8 15 3e 00 00       	call   8010947d <copyuvm>
80105668:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010566b:	89 42 04             	mov    %eax,0x4(%edx)
8010566e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105671:	8b 40 04             	mov    0x4(%eax),%eax
80105674:	85 c0                	test   %eax,%eax
80105676:	75 2c                	jne    801056a4 <fork+0x7a>
    kfree(np->kstack);
80105678:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010567b:	8b 40 08             	mov    0x8(%eax),%eax
8010567e:	89 04 24             	mov    %eax,(%esp)
80105681:	e8 18 e7 ff ff       	call   80103d9e <kfree>
    np->kstack = 0;
80105686:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105689:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105690:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105693:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010569a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010569f:	e9 e1 00 00 00       	jmp    80105785 <fork+0x15b>
  }
  np->sz = proc->sz;
801056a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056aa:	8b 10                	mov    (%eax),%edx
801056ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056af:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801056b1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056bb:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801056be:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056c1:	8b 50 18             	mov    0x18(%eax),%edx
801056c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ca:	8b 40 18             	mov    0x18(%eax),%eax
801056cd:	89 c3                	mov    %eax,%ebx
801056cf:	b8 13 00 00 00       	mov    $0x13,%eax
801056d4:	89 d7                	mov    %edx,%edi
801056d6:	89 de                	mov    %ebx,%esi
801056d8:	89 c1                	mov    %eax,%ecx
801056da:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801056dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056df:	8b 40 18             	mov    0x18(%eax),%eax
801056e2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801056e9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801056f0:	eb 3d                	jmp    8010572f <fork+0x105>
    if(proc->ofile[i])
801056f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056f8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801056fb:	83 c2 08             	add    $0x8,%edx
801056fe:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105702:	85 c0                	test   %eax,%eax
80105704:	74 25                	je     8010572b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105706:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010570c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010570f:	83 c2 08             	add    $0x8,%edx
80105712:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105716:	89 04 24             	mov    %eax,(%esp)
80105719:	e8 5e b8 ff ff       	call   80100f7c <filedup>
8010571e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105721:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105724:	83 c1 08             	add    $0x8,%ecx
80105727:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010572b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010572f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80105733:	7e bd                	jle    801056f2 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105735:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010573b:	8b 40 68             	mov    0x68(%eax),%eax
8010573e:	89 04 24             	mov    %eax,(%esp)
80105741:	e8 64 cf ff ff       	call   801026aa <idup>
80105746:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105749:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
8010574c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010574f:	8b 40 10             	mov    0x10(%eax),%eax
80105752:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105755:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105758:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010575f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105765:	8d 50 6c             	lea    0x6c(%eax),%edx
80105768:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010576b:	83 c0 6c             	add    $0x6c,%eax
8010576e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105775:	00 
80105776:	89 54 24 04          	mov    %edx,0x4(%esp)
8010577a:	89 04 24             	mov    %eax,(%esp)
8010577d:	e8 d8 0b 00 00       	call   8010635a <safestrcpy>
  return pid;
80105782:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80105785:	83 c4 2c             	add    $0x2c,%esp
80105788:	5b                   	pop    %ebx
80105789:	5e                   	pop    %esi
8010578a:	5f                   	pop    %edi
8010578b:	5d                   	pop    %ebp
8010578c:	c3                   	ret    

8010578d <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010578d:	55                   	push   %ebp
8010578e:	89 e5                	mov    %esp,%ebp
80105790:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80105793:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010579a:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010579f:	39 c2                	cmp    %eax,%edx
801057a1:	75 0c                	jne    801057af <exit+0x22>
    panic("init exiting");
801057a3:	c7 04 24 6c 9a 10 80 	movl   $0x80109a6c,(%esp)
801057aa:	e8 8e ad ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801057af:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801057b6:	eb 44                	jmp    801057fc <exit+0x6f>
    if(proc->ofile[fd]){
801057b8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057be:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057c1:	83 c2 08             	add    $0x8,%edx
801057c4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801057c8:	85 c0                	test   %eax,%eax
801057ca:	74 2c                	je     801057f8 <exit+0x6b>
      fileclose(proc->ofile[fd]);
801057cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057d2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057d5:	83 c2 08             	add    $0x8,%edx
801057d8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801057dc:	89 04 24             	mov    %eax,(%esp)
801057df:	e8 e0 b7 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801057e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057ed:	83 c2 08             	add    $0x8,%edx
801057f0:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801057f7:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801057f8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801057fc:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105800:	7e b6                	jle    801057b8 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80105802:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105808:	8b 40 68             	mov    0x68(%eax),%eax
8010580b:	89 04 24             	mov    %eax,(%esp)
8010580e:	e8 7c d0 ff ff       	call   8010288f <iput>
  proc->cwd = 0;
80105813:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105819:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80105820:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105827:	e8 af 06 00 00       	call   80105edb <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010582c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105832:	8b 40 14             	mov    0x14(%eax),%eax
80105835:	89 04 24             	mov    %eax,(%esp)
80105838:	e8 5b 04 00 00       	call   80105c98 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010583d:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105844:	eb 38                	jmp    8010587e <exit+0xf1>
    if(p->parent == proc){
80105846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105849:	8b 50 14             	mov    0x14(%eax),%edx
8010584c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105852:	39 c2                	cmp    %eax,%edx
80105854:	75 24                	jne    8010587a <exit+0xed>
      p->parent = initproc;
80105856:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
8010585c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010585f:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80105862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105865:	8b 40 0c             	mov    0xc(%eax),%eax
80105868:	83 f8 05             	cmp    $0x5,%eax
8010586b:	75 0d                	jne    8010587a <exit+0xed>
        wakeup1(initproc);
8010586d:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80105872:	89 04 24             	mov    %eax,(%esp)
80105875:	e8 1e 04 00 00       	call   80105c98 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010587a:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010587e:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
80105885:	72 bf                	jb     80105846 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105887:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010588d:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105894:	e8 54 02 00 00       	call   80105aed <sched>
  panic("zombie exit");
80105899:	c7 04 24 79 9a 10 80 	movl   $0x80109a79,(%esp)
801058a0:	e8 98 ac ff ff       	call   8010053d <panic>

801058a5 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801058a5:	55                   	push   %ebp
801058a6:	89 e5                	mov    %esp,%ebp
801058a8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801058ab:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801058b2:	e8 24 06 00 00       	call   80105edb <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801058b7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058be:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
801058c5:	e9 9a 00 00 00       	jmp    80105964 <wait+0xbf>
      if(p->parent != proc)
801058ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058cd:	8b 50 14             	mov    0x14(%eax),%edx
801058d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058d6:	39 c2                	cmp    %eax,%edx
801058d8:	0f 85 81 00 00 00    	jne    8010595f <wait+0xba>
        continue;
      havekids = 1;
801058de:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801058e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e8:	8b 40 0c             	mov    0xc(%eax),%eax
801058eb:	83 f8 05             	cmp    $0x5,%eax
801058ee:	75 70                	jne    80105960 <wait+0xbb>
        // Found one.
        pid = p->pid;
801058f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f3:	8b 40 10             	mov    0x10(%eax),%eax
801058f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801058f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058fc:	8b 40 08             	mov    0x8(%eax),%eax
801058ff:	89 04 24             	mov    %eax,(%esp)
80105902:	e8 97 e4 ff ff       	call   80103d9e <kfree>
        p->kstack = 0;
80105907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010590a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105911:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105914:	8b 40 04             	mov    0x4(%eax),%eax
80105917:	89 04 24             	mov    %eax,(%esp)
8010591a:	e8 8a 3a 00 00       	call   801093a9 <freevm>
        p->state = UNUSED;
8010591f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105922:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105929:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010592c:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105933:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105936:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010593d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105940:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105947:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010594e:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105955:	e8 e3 05 00 00       	call   80105f3d <release>
        return pid;
8010595a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010595d:	eb 53                	jmp    801059b2 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010595f:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105960:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105964:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
8010596b:	0f 82 59 ff ff ff    	jb     801058ca <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80105971:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105975:	74 0d                	je     80105984 <wait+0xdf>
80105977:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010597d:	8b 40 24             	mov    0x24(%eax),%eax
80105980:	85 c0                	test   %eax,%eax
80105982:	74 13                	je     80105997 <wait+0xf2>
      release(&ptable.lock);
80105984:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
8010598b:	e8 ad 05 00 00       	call   80105f3d <release>
      return -1;
80105990:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105995:	eb 1b                	jmp    801059b2 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105997:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010599d:	c7 44 24 04 80 0f 11 	movl   $0x80110f80,0x4(%esp)
801059a4:	80 
801059a5:	89 04 24             	mov    %eax,(%esp)
801059a8:	e8 50 02 00 00       	call   80105bfd <sleep>
  }
801059ad:	e9 05 ff ff ff       	jmp    801058b7 <wait+0x12>
}
801059b2:	c9                   	leave  
801059b3:	c3                   	ret    

801059b4 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801059b4:	55                   	push   %ebp
801059b5:	89 e5                	mov    %esp,%ebp
801059b7:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801059ba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059c0:	8b 40 18             	mov    0x18(%eax),%eax
801059c3:	8b 40 44             	mov    0x44(%eax),%eax
801059c6:	89 c2                	mov    %eax,%edx
801059c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059ce:	8b 40 04             	mov    0x4(%eax),%eax
801059d1:	89 54 24 04          	mov    %edx,0x4(%esp)
801059d5:	89 04 24             	mov    %eax,(%esp)
801059d8:	e8 b1 3b 00 00       	call   8010958e <uva2ka>
801059dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801059e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059e6:	8b 40 18             	mov    0x18(%eax),%eax
801059e9:	8b 40 44             	mov    0x44(%eax),%eax
801059ec:	25 ff 0f 00 00       	and    $0xfff,%eax
801059f1:	85 c0                	test   %eax,%eax
801059f3:	75 0c                	jne    80105a01 <register_handler+0x4d>
    panic("esp_offset == 0");
801059f5:	c7 04 24 85 9a 10 80 	movl   $0x80109a85,(%esp)
801059fc:	e8 3c ab ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105a01:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a07:	8b 40 18             	mov    0x18(%eax),%eax
80105a0a:	8b 40 44             	mov    0x44(%eax),%eax
80105a0d:	83 e8 04             	sub    $0x4,%eax
80105a10:	25 ff 0f 00 00       	and    $0xfff,%eax
80105a15:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105a18:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105a1f:	8b 52 18             	mov    0x18(%edx),%edx
80105a22:	8b 52 38             	mov    0x38(%edx),%edx
80105a25:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105a27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a2d:	8b 40 18             	mov    0x18(%eax),%eax
80105a30:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105a37:	8b 52 18             	mov    0x18(%edx),%edx
80105a3a:	8b 52 44             	mov    0x44(%edx),%edx
80105a3d:	83 ea 04             	sub    $0x4,%edx
80105a40:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80105a43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a49:	8b 40 18             	mov    0x18(%eax),%eax
80105a4c:	8b 55 08             	mov    0x8(%ebp),%edx
80105a4f:	89 50 38             	mov    %edx,0x38(%eax)
}
80105a52:	c9                   	leave  
80105a53:	c3                   	ret    

80105a54 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105a54:	55                   	push   %ebp
80105a55:	89 e5                	mov    %esp,%ebp
80105a57:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105a5a:	e8 de f8 ff ff       	call   8010533d <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80105a5f:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105a66:	e8 70 04 00 00       	call   80105edb <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a6b:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105a72:	eb 5f                	jmp    80105ad3 <scheduler+0x7f>
      if(p->state != RUNNABLE)
80105a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a77:	8b 40 0c             	mov    0xc(%eax),%eax
80105a7a:	83 f8 03             	cmp    $0x3,%eax
80105a7d:	75 4f                	jne    80105ace <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80105a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a82:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a8b:	89 04 24             	mov    %eax,(%esp)
80105a8e:	e8 9f 34 00 00       	call   80108f32 <switchuvm>
      p->state = RUNNING;
80105a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a96:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105a9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105aa3:	8b 40 1c             	mov    0x1c(%eax),%eax
80105aa6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105aad:	83 c2 04             	add    $0x4,%edx
80105ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ab4:	89 14 24             	mov    %edx,(%esp)
80105ab7:	e8 14 09 00 00       	call   801063d0 <swtch>
      switchkvm();
80105abc:	e8 54 34 00 00       	call   80108f15 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105ac1:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105ac8:	00 00 00 00 
80105acc:	eb 01                	jmp    80105acf <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80105ace:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105acf:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105ad3:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
80105ada:	72 98                	jb     80105a74 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105adc:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105ae3:	e8 55 04 00 00       	call   80105f3d <release>

  }
80105ae8:	e9 6d ff ff ff       	jmp    80105a5a <scheduler+0x6>

80105aed <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105aed:	55                   	push   %ebp
80105aee:	89 e5                	mov    %esp,%ebp
80105af0:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105af3:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105afa:	e8 fa 04 00 00       	call   80105ff9 <holding>
80105aff:	85 c0                	test   %eax,%eax
80105b01:	75 0c                	jne    80105b0f <sched+0x22>
    panic("sched ptable.lock");
80105b03:	c7 04 24 95 9a 10 80 	movl   $0x80109a95,(%esp)
80105b0a:	e8 2e aa ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105b0f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b15:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105b1b:	83 f8 01             	cmp    $0x1,%eax
80105b1e:	74 0c                	je     80105b2c <sched+0x3f>
    panic("sched locks");
80105b20:	c7 04 24 a7 9a 10 80 	movl   $0x80109aa7,(%esp)
80105b27:	e8 11 aa ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105b2c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b32:	8b 40 0c             	mov    0xc(%eax),%eax
80105b35:	83 f8 04             	cmp    $0x4,%eax
80105b38:	75 0c                	jne    80105b46 <sched+0x59>
    panic("sched running");
80105b3a:	c7 04 24 b3 9a 10 80 	movl   $0x80109ab3,(%esp)
80105b41:	e8 f7 a9 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105b46:	e8 dd f7 ff ff       	call   80105328 <readeflags>
80105b4b:	25 00 02 00 00       	and    $0x200,%eax
80105b50:	85 c0                	test   %eax,%eax
80105b52:	74 0c                	je     80105b60 <sched+0x73>
    panic("sched interruptible");
80105b54:	c7 04 24 c1 9a 10 80 	movl   $0x80109ac1,(%esp)
80105b5b:	e8 dd a9 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105b60:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b66:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105b6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105b6f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b75:	8b 40 04             	mov    0x4(%eax),%eax
80105b78:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105b7f:	83 c2 1c             	add    $0x1c,%edx
80105b82:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b86:	89 14 24             	mov    %edx,(%esp)
80105b89:	e8 42 08 00 00       	call   801063d0 <swtch>
  cpu->intena = intena;
80105b8e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b94:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b97:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105b9d:	c9                   	leave  
80105b9e:	c3                   	ret    

80105b9f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105b9f:	55                   	push   %ebp
80105ba0:	89 e5                	mov    %esp,%ebp
80105ba2:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105ba5:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105bac:	e8 2a 03 00 00       	call   80105edb <acquire>
  proc->state = RUNNABLE;
80105bb1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bb7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105bbe:	e8 2a ff ff ff       	call   80105aed <sched>
  release(&ptable.lock);
80105bc3:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105bca:	e8 6e 03 00 00       	call   80105f3d <release>
}
80105bcf:	c9                   	leave  
80105bd0:	c3                   	ret    

80105bd1 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105bd1:	55                   	push   %ebp
80105bd2:	89 e5                	mov    %esp,%ebp
80105bd4:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105bd7:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105bde:	e8 5a 03 00 00       	call   80105f3d <release>

  if (first) {
80105be3:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105be8:	85 c0                	test   %eax,%eax
80105bea:	74 0f                	je     80105bfb <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105bec:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105bf3:	00 00 00 
    initlog();
80105bf6:	e8 4d e7 ff ff       	call   80104348 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105bfb:	c9                   	leave  
80105bfc:	c3                   	ret    

80105bfd <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105bfd:	55                   	push   %ebp
80105bfe:	89 e5                	mov    %esp,%ebp
80105c00:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105c03:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c09:	85 c0                	test   %eax,%eax
80105c0b:	75 0c                	jne    80105c19 <sleep+0x1c>
    panic("sleep");
80105c0d:	c7 04 24 d5 9a 10 80 	movl   $0x80109ad5,(%esp)
80105c14:	e8 24 a9 ff ff       	call   8010053d <panic>

  if(lk == 0)
80105c19:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105c1d:	75 0c                	jne    80105c2b <sleep+0x2e>
    panic("sleep without lk");
80105c1f:	c7 04 24 db 9a 10 80 	movl   $0x80109adb,(%esp)
80105c26:	e8 12 a9 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105c2b:	81 7d 0c 80 0f 11 80 	cmpl   $0x80110f80,0xc(%ebp)
80105c32:	74 17                	je     80105c4b <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105c34:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105c3b:	e8 9b 02 00 00       	call   80105edb <acquire>
    release(lk);
80105c40:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c43:	89 04 24             	mov    %eax,(%esp)
80105c46:	e8 f2 02 00 00       	call   80105f3d <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105c4b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c51:	8b 55 08             	mov    0x8(%ebp),%edx
80105c54:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105c57:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c5d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105c64:	e8 84 fe ff ff       	call   80105aed <sched>

  // Tidy up.
  proc->chan = 0;
80105c69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c6f:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105c76:	81 7d 0c 80 0f 11 80 	cmpl   $0x80110f80,0xc(%ebp)
80105c7d:	74 17                	je     80105c96 <sleep+0x99>
    release(&ptable.lock);
80105c7f:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105c86:	e8 b2 02 00 00       	call   80105f3d <release>
    acquire(lk);
80105c8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c8e:	89 04 24             	mov    %eax,(%esp)
80105c91:	e8 45 02 00 00       	call   80105edb <acquire>
  }
}
80105c96:	c9                   	leave  
80105c97:	c3                   	ret    

80105c98 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105c98:	55                   	push   %ebp
80105c99:	89 e5                	mov    %esp,%ebp
80105c9b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105c9e:	c7 45 fc b4 0f 11 80 	movl   $0x80110fb4,-0x4(%ebp)
80105ca5:	eb 24                	jmp    80105ccb <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105ca7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105caa:	8b 40 0c             	mov    0xc(%eax),%eax
80105cad:	83 f8 02             	cmp    $0x2,%eax
80105cb0:	75 15                	jne    80105cc7 <wakeup1+0x2f>
80105cb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cb5:	8b 40 20             	mov    0x20(%eax),%eax
80105cb8:	3b 45 08             	cmp    0x8(%ebp),%eax
80105cbb:	75 0a                	jne    80105cc7 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105cbd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cc0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105cc7:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105ccb:	81 7d fc b4 2e 11 80 	cmpl   $0x80112eb4,-0x4(%ebp)
80105cd2:	72 d3                	jb     80105ca7 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105cd4:	c9                   	leave  
80105cd5:	c3                   	ret    

80105cd6 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105cd6:	55                   	push   %ebp
80105cd7:	89 e5                	mov    %esp,%ebp
80105cd9:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105cdc:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105ce3:	e8 f3 01 00 00       	call   80105edb <acquire>
  wakeup1(chan);
80105ce8:	8b 45 08             	mov    0x8(%ebp),%eax
80105ceb:	89 04 24             	mov    %eax,(%esp)
80105cee:	e8 a5 ff ff ff       	call   80105c98 <wakeup1>
  release(&ptable.lock);
80105cf3:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105cfa:	e8 3e 02 00 00       	call   80105f3d <release>
}
80105cff:	c9                   	leave  
80105d00:	c3                   	ret    

80105d01 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105d01:	55                   	push   %ebp
80105d02:	89 e5                	mov    %esp,%ebp
80105d04:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105d07:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105d0e:	e8 c8 01 00 00       	call   80105edb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105d13:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105d1a:	eb 41                	jmp    80105d5d <kill+0x5c>
    if(p->pid == pid){
80105d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d1f:	8b 40 10             	mov    0x10(%eax),%eax
80105d22:	3b 45 08             	cmp    0x8(%ebp),%eax
80105d25:	75 32                	jne    80105d59 <kill+0x58>
      p->killed = 1;
80105d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d2a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d34:	8b 40 0c             	mov    0xc(%eax),%eax
80105d37:	83 f8 02             	cmp    $0x2,%eax
80105d3a:	75 0a                	jne    80105d46 <kill+0x45>
        p->state = RUNNABLE;
80105d3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d3f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105d46:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105d4d:	e8 eb 01 00 00       	call   80105f3d <release>
      return 0;
80105d52:	b8 00 00 00 00       	mov    $0x0,%eax
80105d57:	eb 1e                	jmp    80105d77 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105d59:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105d5d:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
80105d64:	72 b6                	jb     80105d1c <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105d66:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105d6d:	e8 cb 01 00 00       	call   80105f3d <release>
  return -1;
80105d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d77:	c9                   	leave  
80105d78:	c3                   	ret    

80105d79 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105d79:	55                   	push   %ebp
80105d7a:	89 e5                	mov    %esp,%ebp
80105d7c:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105d7f:	c7 45 f0 b4 0f 11 80 	movl   $0x80110fb4,-0x10(%ebp)
80105d86:	e9 d8 00 00 00       	jmp    80105e63 <procdump+0xea>
    if(p->state == UNUSED)
80105d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d8e:	8b 40 0c             	mov    0xc(%eax),%eax
80105d91:	85 c0                	test   %eax,%eax
80105d93:	0f 84 c5 00 00 00    	je     80105e5e <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105d99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d9c:	8b 40 0c             	mov    0xc(%eax),%eax
80105d9f:	83 f8 05             	cmp    $0x5,%eax
80105da2:	77 23                	ja     80105dc7 <procdump+0x4e>
80105da4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105da7:	8b 40 0c             	mov    0xc(%eax),%eax
80105daa:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105db1:	85 c0                	test   %eax,%eax
80105db3:	74 12                	je     80105dc7 <procdump+0x4e>
      state = states[p->state];
80105db5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105db8:	8b 40 0c             	mov    0xc(%eax),%eax
80105dbb:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105dc2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105dc5:	eb 07                	jmp    80105dce <procdump+0x55>
    else
      state = "???";
80105dc7:	c7 45 ec ec 9a 10 80 	movl   $0x80109aec,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105dce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd1:	8d 50 6c             	lea    0x6c(%eax),%edx
80105dd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd7:	8b 40 10             	mov    0x10(%eax),%eax
80105dda:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105dde:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105de1:	89 54 24 08          	mov    %edx,0x8(%esp)
80105de5:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de9:	c7 04 24 f0 9a 10 80 	movl   $0x80109af0,(%esp)
80105df0:	e8 ac a5 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105df5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105df8:	8b 40 0c             	mov    0xc(%eax),%eax
80105dfb:	83 f8 02             	cmp    $0x2,%eax
80105dfe:	75 50                	jne    80105e50 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105e00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e03:	8b 40 1c             	mov    0x1c(%eax),%eax
80105e06:	8b 40 0c             	mov    0xc(%eax),%eax
80105e09:	83 c0 08             	add    $0x8,%eax
80105e0c:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105e0f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e13:	89 04 24             	mov    %eax,(%esp)
80105e16:	e8 71 01 00 00       	call   80105f8c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105e1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105e22:	eb 1b                	jmp    80105e3f <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105e24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e27:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105e2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e2f:	c7 04 24 f9 9a 10 80 	movl   $0x80109af9,(%esp)
80105e36:	e8 66 a5 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105e3b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105e3f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105e43:	7f 0b                	jg     80105e50 <procdump+0xd7>
80105e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e48:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105e4c:	85 c0                	test   %eax,%eax
80105e4e:	75 d4                	jne    80105e24 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105e50:	c7 04 24 fd 9a 10 80 	movl   $0x80109afd,(%esp)
80105e57:	e8 45 a5 ff ff       	call   801003a1 <cprintf>
80105e5c:	eb 01                	jmp    80105e5f <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105e5e:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105e5f:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105e63:	81 7d f0 b4 2e 11 80 	cmpl   $0x80112eb4,-0x10(%ebp)
80105e6a:	0f 82 1b ff ff ff    	jb     80105d8b <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105e70:	c9                   	leave  
80105e71:	c3                   	ret    
	...

80105e74 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105e74:	55                   	push   %ebp
80105e75:	89 e5                	mov    %esp,%ebp
80105e77:	53                   	push   %ebx
80105e78:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105e7b:	9c                   	pushf  
80105e7c:	5b                   	pop    %ebx
80105e7d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105e80:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105e83:	83 c4 10             	add    $0x10,%esp
80105e86:	5b                   	pop    %ebx
80105e87:	5d                   	pop    %ebp
80105e88:	c3                   	ret    

80105e89 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105e89:	55                   	push   %ebp
80105e8a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105e8c:	fa                   	cli    
}
80105e8d:	5d                   	pop    %ebp
80105e8e:	c3                   	ret    

80105e8f <sti>:

static inline void
sti(void)
{
80105e8f:	55                   	push   %ebp
80105e90:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105e92:	fb                   	sti    
}
80105e93:	5d                   	pop    %ebp
80105e94:	c3                   	ret    

80105e95 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105e95:	55                   	push   %ebp
80105e96:	89 e5                	mov    %esp,%ebp
80105e98:	53                   	push   %ebx
80105e99:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105e9c:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105e9f:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105ea2:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105ea5:	89 c3                	mov    %eax,%ebx
80105ea7:	89 d8                	mov    %ebx,%eax
80105ea9:	f0 87 02             	lock xchg %eax,(%edx)
80105eac:	89 c3                	mov    %eax,%ebx
80105eae:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105eb1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105eb4:	83 c4 10             	add    $0x10,%esp
80105eb7:	5b                   	pop    %ebx
80105eb8:	5d                   	pop    %ebp
80105eb9:	c3                   	ret    

80105eba <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105eba:	55                   	push   %ebp
80105ebb:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec0:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ec3:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105ecf:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105ed9:	5d                   	pop    %ebp
80105eda:	c3                   	ret    

80105edb <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105edb:	55                   	push   %ebp
80105edc:	89 e5                	mov    %esp,%ebp
80105ede:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105ee1:	e8 3d 01 00 00       	call   80106023 <pushcli>
  if(holding(lk))
80105ee6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ee9:	89 04 24             	mov    %eax,(%esp)
80105eec:	e8 08 01 00 00       	call   80105ff9 <holding>
80105ef1:	85 c0                	test   %eax,%eax
80105ef3:	74 0c                	je     80105f01 <acquire+0x26>
    panic("acquire");
80105ef5:	c7 04 24 29 9b 10 80 	movl   $0x80109b29,(%esp)
80105efc:	e8 3c a6 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105f01:	90                   	nop
80105f02:	8b 45 08             	mov    0x8(%ebp),%eax
80105f05:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105f0c:	00 
80105f0d:	89 04 24             	mov    %eax,(%esp)
80105f10:	e8 80 ff ff ff       	call   80105e95 <xchg>
80105f15:	85 c0                	test   %eax,%eax
80105f17:	75 e9                	jne    80105f02 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105f19:	8b 45 08             	mov    0x8(%ebp),%eax
80105f1c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105f23:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105f26:	8b 45 08             	mov    0x8(%ebp),%eax
80105f29:	83 c0 0c             	add    $0xc,%eax
80105f2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f30:	8d 45 08             	lea    0x8(%ebp),%eax
80105f33:	89 04 24             	mov    %eax,(%esp)
80105f36:	e8 51 00 00 00       	call   80105f8c <getcallerpcs>
}
80105f3b:	c9                   	leave  
80105f3c:	c3                   	ret    

80105f3d <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105f3d:	55                   	push   %ebp
80105f3e:	89 e5                	mov    %esp,%ebp
80105f40:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105f43:	8b 45 08             	mov    0x8(%ebp),%eax
80105f46:	89 04 24             	mov    %eax,(%esp)
80105f49:	e8 ab 00 00 00       	call   80105ff9 <holding>
80105f4e:	85 c0                	test   %eax,%eax
80105f50:	75 0c                	jne    80105f5e <release+0x21>
    panic("release");
80105f52:	c7 04 24 31 9b 10 80 	movl   $0x80109b31,(%esp)
80105f59:	e8 df a5 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105f5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105f61:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105f68:	8b 45 08             	mov    0x8(%ebp),%eax
80105f6b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105f72:	8b 45 08             	mov    0x8(%ebp),%eax
80105f75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f7c:	00 
80105f7d:	89 04 24             	mov    %eax,(%esp)
80105f80:	e8 10 ff ff ff       	call   80105e95 <xchg>

  popcli();
80105f85:	e8 e1 00 00 00       	call   8010606b <popcli>
}
80105f8a:	c9                   	leave  
80105f8b:	c3                   	ret    

80105f8c <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105f8c:	55                   	push   %ebp
80105f8d:	89 e5                	mov    %esp,%ebp
80105f8f:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105f92:	8b 45 08             	mov    0x8(%ebp),%eax
80105f95:	83 e8 08             	sub    $0x8,%eax
80105f98:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105f9b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105fa2:	eb 32                	jmp    80105fd6 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105fa4:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105fa8:	74 47                	je     80105ff1 <getcallerpcs+0x65>
80105faa:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105fb1:	76 3e                	jbe    80105ff1 <getcallerpcs+0x65>
80105fb3:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105fb7:	74 38                	je     80105ff1 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105fb9:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fbc:	c1 e0 02             	shl    $0x2,%eax
80105fbf:	03 45 0c             	add    0xc(%ebp),%eax
80105fc2:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fc5:	8b 52 04             	mov    0x4(%edx),%edx
80105fc8:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105fca:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fcd:	8b 00                	mov    (%eax),%eax
80105fcf:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105fd2:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105fd6:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105fda:	7e c8                	jle    80105fa4 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105fdc:	eb 13                	jmp    80105ff1 <getcallerpcs+0x65>
    pcs[i] = 0;
80105fde:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105fe1:	c1 e0 02             	shl    $0x2,%eax
80105fe4:	03 45 0c             	add    0xc(%ebp),%eax
80105fe7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105fed:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ff1:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105ff5:	7e e7                	jle    80105fde <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105ff7:	c9                   	leave  
80105ff8:	c3                   	ret    

80105ff9 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105ff9:	55                   	push   %ebp
80105ffa:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80105fff:	8b 00                	mov    (%eax),%eax
80106001:	85 c0                	test   %eax,%eax
80106003:	74 17                	je     8010601c <holding+0x23>
80106005:	8b 45 08             	mov    0x8(%ebp),%eax
80106008:	8b 50 08             	mov    0x8(%eax),%edx
8010600b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106011:	39 c2                	cmp    %eax,%edx
80106013:	75 07                	jne    8010601c <holding+0x23>
80106015:	b8 01 00 00 00       	mov    $0x1,%eax
8010601a:	eb 05                	jmp    80106021 <holding+0x28>
8010601c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106021:	5d                   	pop    %ebp
80106022:	c3                   	ret    

80106023 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80106023:	55                   	push   %ebp
80106024:	89 e5                	mov    %esp,%ebp
80106026:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80106029:	e8 46 fe ff ff       	call   80105e74 <readeflags>
8010602e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80106031:	e8 53 fe ff ff       	call   80105e89 <cli>
  if(cpu->ncli++ == 0)
80106036:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010603c:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80106042:	85 d2                	test   %edx,%edx
80106044:	0f 94 c1             	sete   %cl
80106047:	83 c2 01             	add    $0x1,%edx
8010604a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80106050:	84 c9                	test   %cl,%cl
80106052:	74 15                	je     80106069 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80106054:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010605a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010605d:	81 e2 00 02 00 00    	and    $0x200,%edx
80106063:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80106069:	c9                   	leave  
8010606a:	c3                   	ret    

8010606b <popcli>:

void
popcli(void)
{
8010606b:	55                   	push   %ebp
8010606c:	89 e5                	mov    %esp,%ebp
8010606e:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80106071:	e8 fe fd ff ff       	call   80105e74 <readeflags>
80106076:	25 00 02 00 00       	and    $0x200,%eax
8010607b:	85 c0                	test   %eax,%eax
8010607d:	74 0c                	je     8010608b <popcli+0x20>
    panic("popcli - interruptible");
8010607f:	c7 04 24 39 9b 10 80 	movl   $0x80109b39,(%esp)
80106086:	e8 b2 a4 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
8010608b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106091:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80106097:	83 ea 01             	sub    $0x1,%edx
8010609a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801060a0:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801060a6:	85 c0                	test   %eax,%eax
801060a8:	79 0c                	jns    801060b6 <popcli+0x4b>
    panic("popcli");
801060aa:	c7 04 24 50 9b 10 80 	movl   $0x80109b50,(%esp)
801060b1:	e8 87 a4 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
801060b6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801060bc:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801060c2:	85 c0                	test   %eax,%eax
801060c4:	75 15                	jne    801060db <popcli+0x70>
801060c6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801060cc:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801060d2:	85 c0                	test   %eax,%eax
801060d4:	74 05                	je     801060db <popcli+0x70>
    sti();
801060d6:	e8 b4 fd ff ff       	call   80105e8f <sti>
}
801060db:	c9                   	leave  
801060dc:	c3                   	ret    
801060dd:	00 00                	add    %al,(%eax)
	...

801060e0 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
801060e0:	55                   	push   %ebp
801060e1:	89 e5                	mov    %esp,%ebp
801060e3:	57                   	push   %edi
801060e4:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
801060e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801060e8:	8b 55 10             	mov    0x10(%ebp),%edx
801060eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801060ee:	89 cb                	mov    %ecx,%ebx
801060f0:	89 df                	mov    %ebx,%edi
801060f2:	89 d1                	mov    %edx,%ecx
801060f4:	fc                   	cld    
801060f5:	f3 aa                	rep stos %al,%es:(%edi)
801060f7:	89 ca                	mov    %ecx,%edx
801060f9:	89 fb                	mov    %edi,%ebx
801060fb:	89 5d 08             	mov    %ebx,0x8(%ebp)
801060fe:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80106101:	5b                   	pop    %ebx
80106102:	5f                   	pop    %edi
80106103:	5d                   	pop    %ebp
80106104:	c3                   	ret    

80106105 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80106105:	55                   	push   %ebp
80106106:	89 e5                	mov    %esp,%ebp
80106108:	57                   	push   %edi
80106109:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010610a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010610d:	8b 55 10             	mov    0x10(%ebp),%edx
80106110:	8b 45 0c             	mov    0xc(%ebp),%eax
80106113:	89 cb                	mov    %ecx,%ebx
80106115:	89 df                	mov    %ebx,%edi
80106117:	89 d1                	mov    %edx,%ecx
80106119:	fc                   	cld    
8010611a:	f3 ab                	rep stos %eax,%es:(%edi)
8010611c:	89 ca                	mov    %ecx,%edx
8010611e:	89 fb                	mov    %edi,%ebx
80106120:	89 5d 08             	mov    %ebx,0x8(%ebp)
80106123:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80106126:	5b                   	pop    %ebx
80106127:	5f                   	pop    %edi
80106128:	5d                   	pop    %ebp
80106129:	c3                   	ret    

8010612a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010612a:	55                   	push   %ebp
8010612b:	89 e5                	mov    %esp,%ebp
8010612d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80106130:	8b 45 08             	mov    0x8(%ebp),%eax
80106133:	83 e0 03             	and    $0x3,%eax
80106136:	85 c0                	test   %eax,%eax
80106138:	75 49                	jne    80106183 <memset+0x59>
8010613a:	8b 45 10             	mov    0x10(%ebp),%eax
8010613d:	83 e0 03             	and    $0x3,%eax
80106140:	85 c0                	test   %eax,%eax
80106142:	75 3f                	jne    80106183 <memset+0x59>
    c &= 0xFF;
80106144:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010614b:	8b 45 10             	mov    0x10(%ebp),%eax
8010614e:	c1 e8 02             	shr    $0x2,%eax
80106151:	89 c2                	mov    %eax,%edx
80106153:	8b 45 0c             	mov    0xc(%ebp),%eax
80106156:	89 c1                	mov    %eax,%ecx
80106158:	c1 e1 18             	shl    $0x18,%ecx
8010615b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010615e:	c1 e0 10             	shl    $0x10,%eax
80106161:	09 c1                	or     %eax,%ecx
80106163:	8b 45 0c             	mov    0xc(%ebp),%eax
80106166:	c1 e0 08             	shl    $0x8,%eax
80106169:	09 c8                	or     %ecx,%eax
8010616b:	0b 45 0c             	or     0xc(%ebp),%eax
8010616e:	89 54 24 08          	mov    %edx,0x8(%esp)
80106172:	89 44 24 04          	mov    %eax,0x4(%esp)
80106176:	8b 45 08             	mov    0x8(%ebp),%eax
80106179:	89 04 24             	mov    %eax,(%esp)
8010617c:	e8 84 ff ff ff       	call   80106105 <stosl>
80106181:	eb 19                	jmp    8010619c <memset+0x72>
  } else
    stosb(dst, c, n);
80106183:	8b 45 10             	mov    0x10(%ebp),%eax
80106186:	89 44 24 08          	mov    %eax,0x8(%esp)
8010618a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010618d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106191:	8b 45 08             	mov    0x8(%ebp),%eax
80106194:	89 04 24             	mov    %eax,(%esp)
80106197:	e8 44 ff ff ff       	call   801060e0 <stosb>
  return dst;
8010619c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010619f:	c9                   	leave  
801061a0:	c3                   	ret    

801061a1 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801061a1:	55                   	push   %ebp
801061a2:	89 e5                	mov    %esp,%ebp
801061a4:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801061a7:	8b 45 08             	mov    0x8(%ebp),%eax
801061aa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801061ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801061b0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801061b3:	eb 32                	jmp    801061e7 <memcmp+0x46>
    if(*s1 != *s2)
801061b5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061b8:	0f b6 10             	movzbl (%eax),%edx
801061bb:	8b 45 f8             	mov    -0x8(%ebp),%eax
801061be:	0f b6 00             	movzbl (%eax),%eax
801061c1:	38 c2                	cmp    %al,%dl
801061c3:	74 1a                	je     801061df <memcmp+0x3e>
      return *s1 - *s2;
801061c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061c8:	0f b6 00             	movzbl (%eax),%eax
801061cb:	0f b6 d0             	movzbl %al,%edx
801061ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
801061d1:	0f b6 00             	movzbl (%eax),%eax
801061d4:	0f b6 c0             	movzbl %al,%eax
801061d7:	89 d1                	mov    %edx,%ecx
801061d9:	29 c1                	sub    %eax,%ecx
801061db:	89 c8                	mov    %ecx,%eax
801061dd:	eb 1c                	jmp    801061fb <memcmp+0x5a>
    s1++, s2++;
801061df:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801061e3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801061e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061eb:	0f 95 c0             	setne  %al
801061ee:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061f2:	84 c0                	test   %al,%al
801061f4:	75 bf                	jne    801061b5 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801061f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061fb:	c9                   	leave  
801061fc:	c3                   	ret    

801061fd <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801061fd:	55                   	push   %ebp
801061fe:	89 e5                	mov    %esp,%ebp
80106200:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80106203:	8b 45 0c             	mov    0xc(%ebp),%eax
80106206:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80106209:	8b 45 08             	mov    0x8(%ebp),%eax
8010620c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010620f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106212:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106215:	73 54                	jae    8010626b <memmove+0x6e>
80106217:	8b 45 10             	mov    0x10(%ebp),%eax
8010621a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010621d:	01 d0                	add    %edx,%eax
8010621f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106222:	76 47                	jbe    8010626b <memmove+0x6e>
    s += n;
80106224:	8b 45 10             	mov    0x10(%ebp),%eax
80106227:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010622a:	8b 45 10             	mov    0x10(%ebp),%eax
8010622d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80106230:	eb 13                	jmp    80106245 <memmove+0x48>
      *--d = *--s;
80106232:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80106236:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010623a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010623d:	0f b6 10             	movzbl (%eax),%edx
80106240:	8b 45 f8             	mov    -0x8(%ebp),%eax
80106243:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80106245:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106249:	0f 95 c0             	setne  %al
8010624c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106250:	84 c0                	test   %al,%al
80106252:	75 de                	jne    80106232 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80106254:	eb 25                	jmp    8010627b <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80106256:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106259:	0f b6 10             	movzbl (%eax),%edx
8010625c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010625f:	88 10                	mov    %dl,(%eax)
80106261:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80106265:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106269:	eb 01                	jmp    8010626c <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010626b:	90                   	nop
8010626c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106270:	0f 95 c0             	setne  %al
80106273:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106277:	84 c0                	test   %al,%al
80106279:	75 db                	jne    80106256 <memmove+0x59>
      *d++ = *s++;

  return dst;
8010627b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010627e:	c9                   	leave  
8010627f:	c3                   	ret    

80106280 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80106280:	55                   	push   %ebp
80106281:	89 e5                	mov    %esp,%ebp
80106283:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80106286:	8b 45 10             	mov    0x10(%ebp),%eax
80106289:	89 44 24 08          	mov    %eax,0x8(%esp)
8010628d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106290:	89 44 24 04          	mov    %eax,0x4(%esp)
80106294:	8b 45 08             	mov    0x8(%ebp),%eax
80106297:	89 04 24             	mov    %eax,(%esp)
8010629a:	e8 5e ff ff ff       	call   801061fd <memmove>
}
8010629f:	c9                   	leave  
801062a0:	c3                   	ret    

801062a1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801062a1:	55                   	push   %ebp
801062a2:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801062a4:	eb 0c                	jmp    801062b2 <strncmp+0x11>
    n--, p++, q++;
801062a6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801062aa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801062ae:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801062b2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062b6:	74 1a                	je     801062d2 <strncmp+0x31>
801062b8:	8b 45 08             	mov    0x8(%ebp),%eax
801062bb:	0f b6 00             	movzbl (%eax),%eax
801062be:	84 c0                	test   %al,%al
801062c0:	74 10                	je     801062d2 <strncmp+0x31>
801062c2:	8b 45 08             	mov    0x8(%ebp),%eax
801062c5:	0f b6 10             	movzbl (%eax),%edx
801062c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801062cb:	0f b6 00             	movzbl (%eax),%eax
801062ce:	38 c2                	cmp    %al,%dl
801062d0:	74 d4                	je     801062a6 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801062d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062d6:	75 07                	jne    801062df <strncmp+0x3e>
    return 0;
801062d8:	b8 00 00 00 00       	mov    $0x0,%eax
801062dd:	eb 18                	jmp    801062f7 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801062df:	8b 45 08             	mov    0x8(%ebp),%eax
801062e2:	0f b6 00             	movzbl (%eax),%eax
801062e5:	0f b6 d0             	movzbl %al,%edx
801062e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801062eb:	0f b6 00             	movzbl (%eax),%eax
801062ee:	0f b6 c0             	movzbl %al,%eax
801062f1:	89 d1                	mov    %edx,%ecx
801062f3:	29 c1                	sub    %eax,%ecx
801062f5:	89 c8                	mov    %ecx,%eax
}
801062f7:	5d                   	pop    %ebp
801062f8:	c3                   	ret    

801062f9 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801062f9:	55                   	push   %ebp
801062fa:	89 e5                	mov    %esp,%ebp
801062fc:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801062ff:	8b 45 08             	mov    0x8(%ebp),%eax
80106302:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106305:	90                   	nop
80106306:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010630a:	0f 9f c0             	setg   %al
8010630d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106311:	84 c0                	test   %al,%al
80106313:	74 30                	je     80106345 <strncpy+0x4c>
80106315:	8b 45 0c             	mov    0xc(%ebp),%eax
80106318:	0f b6 10             	movzbl (%eax),%edx
8010631b:	8b 45 08             	mov    0x8(%ebp),%eax
8010631e:	88 10                	mov    %dl,(%eax)
80106320:	8b 45 08             	mov    0x8(%ebp),%eax
80106323:	0f b6 00             	movzbl (%eax),%eax
80106326:	84 c0                	test   %al,%al
80106328:	0f 95 c0             	setne  %al
8010632b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010632f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106333:	84 c0                	test   %al,%al
80106335:	75 cf                	jne    80106306 <strncpy+0xd>
    ;
  while(n-- > 0)
80106337:	eb 0c                	jmp    80106345 <strncpy+0x4c>
    *s++ = 0;
80106339:	8b 45 08             	mov    0x8(%ebp),%eax
8010633c:	c6 00 00             	movb   $0x0,(%eax)
8010633f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106343:	eb 01                	jmp    80106346 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106345:	90                   	nop
80106346:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010634a:	0f 9f c0             	setg   %al
8010634d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106351:	84 c0                	test   %al,%al
80106353:	75 e4                	jne    80106339 <strncpy+0x40>
    *s++ = 0;
  return os;
80106355:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106358:	c9                   	leave  
80106359:	c3                   	ret    

8010635a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010635a:	55                   	push   %ebp
8010635b:	89 e5                	mov    %esp,%ebp
8010635d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80106360:	8b 45 08             	mov    0x8(%ebp),%eax
80106363:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106366:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010636a:	7f 05                	jg     80106371 <safestrcpy+0x17>
    return os;
8010636c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010636f:	eb 35                	jmp    801063a6 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80106371:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106375:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106379:	7e 22                	jle    8010639d <safestrcpy+0x43>
8010637b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010637e:	0f b6 10             	movzbl (%eax),%edx
80106381:	8b 45 08             	mov    0x8(%ebp),%eax
80106384:	88 10                	mov    %dl,(%eax)
80106386:	8b 45 08             	mov    0x8(%ebp),%eax
80106389:	0f b6 00             	movzbl (%eax),%eax
8010638c:	84 c0                	test   %al,%al
8010638e:	0f 95 c0             	setne  %al
80106391:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106395:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106399:	84 c0                	test   %al,%al
8010639b:	75 d4                	jne    80106371 <safestrcpy+0x17>
    ;
  *s = 0;
8010639d:	8b 45 08             	mov    0x8(%ebp),%eax
801063a0:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801063a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801063a6:	c9                   	leave  
801063a7:	c3                   	ret    

801063a8 <strlen>:

int
strlen(const char *s)
{
801063a8:	55                   	push   %ebp
801063a9:	89 e5                	mov    %esp,%ebp
801063ab:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801063ae:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801063b5:	eb 04                	jmp    801063bb <strlen+0x13>
801063b7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801063bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063be:	03 45 08             	add    0x8(%ebp),%eax
801063c1:	0f b6 00             	movzbl (%eax),%eax
801063c4:	84 c0                	test   %al,%al
801063c6:	75 ef                	jne    801063b7 <strlen+0xf>
    ;
  return n;
801063c8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801063cb:	c9                   	leave  
801063cc:	c3                   	ret    
801063cd:	00 00                	add    %al,(%eax)
	...

801063d0 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801063d0:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801063d4:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801063d8:	55                   	push   %ebp
  pushl %ebx
801063d9:	53                   	push   %ebx
  pushl %esi
801063da:	56                   	push   %esi
  pushl %edi
801063db:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801063dc:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801063de:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801063e0:	5f                   	pop    %edi
  popl %esi
801063e1:	5e                   	pop    %esi
  popl %ebx
801063e2:	5b                   	pop    %ebx
  popl %ebp
801063e3:	5d                   	pop    %ebp
  ret
801063e4:	c3                   	ret    
801063e5:	00 00                	add    %al,(%eax)
	...

801063e8 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801063e8:	55                   	push   %ebp
801063e9:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801063eb:	8b 45 08             	mov    0x8(%ebp),%eax
801063ee:	8b 00                	mov    (%eax),%eax
801063f0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801063f3:	76 0f                	jbe    80106404 <fetchint+0x1c>
801063f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801063f8:	8d 50 04             	lea    0x4(%eax),%edx
801063fb:	8b 45 08             	mov    0x8(%ebp),%eax
801063fe:	8b 00                	mov    (%eax),%eax
80106400:	39 c2                	cmp    %eax,%edx
80106402:	76 07                	jbe    8010640b <fetchint+0x23>
    return -1;
80106404:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106409:	eb 0f                	jmp    8010641a <fetchint+0x32>
  *ip = *(int*)(addr);
8010640b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010640e:	8b 10                	mov    (%eax),%edx
80106410:	8b 45 10             	mov    0x10(%ebp),%eax
80106413:	89 10                	mov    %edx,(%eax)
  return 0;
80106415:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010641a:	5d                   	pop    %ebp
8010641b:	c3                   	ret    

8010641c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010641c:	55                   	push   %ebp
8010641d:	89 e5                	mov    %esp,%ebp
8010641f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80106422:	8b 45 08             	mov    0x8(%ebp),%eax
80106425:	8b 00                	mov    (%eax),%eax
80106427:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010642a:	77 07                	ja     80106433 <fetchstr+0x17>
    return -1;
8010642c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106431:	eb 45                	jmp    80106478 <fetchstr+0x5c>
  *pp = (char*)addr;
80106433:	8b 55 0c             	mov    0xc(%ebp),%edx
80106436:	8b 45 10             	mov    0x10(%ebp),%eax
80106439:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010643b:	8b 45 08             	mov    0x8(%ebp),%eax
8010643e:	8b 00                	mov    (%eax),%eax
80106440:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80106443:	8b 45 10             	mov    0x10(%ebp),%eax
80106446:	8b 00                	mov    (%eax),%eax
80106448:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010644b:	eb 1e                	jmp    8010646b <fetchstr+0x4f>
    if(*s == 0)
8010644d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106450:	0f b6 00             	movzbl (%eax),%eax
80106453:	84 c0                	test   %al,%al
80106455:	75 10                	jne    80106467 <fetchstr+0x4b>
      return s - *pp;
80106457:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010645a:	8b 45 10             	mov    0x10(%ebp),%eax
8010645d:	8b 00                	mov    (%eax),%eax
8010645f:	89 d1                	mov    %edx,%ecx
80106461:	29 c1                	sub    %eax,%ecx
80106463:	89 c8                	mov    %ecx,%eax
80106465:	eb 11                	jmp    80106478 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80106467:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010646b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010646e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106471:	72 da                	jb     8010644d <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80106473:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106478:	c9                   	leave  
80106479:	c3                   	ret    

8010647a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010647a:	55                   	push   %ebp
8010647b:	89 e5                	mov    %esp,%ebp
8010647d:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80106480:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106486:	8b 40 18             	mov    0x18(%eax),%eax
80106489:	8b 50 44             	mov    0x44(%eax),%edx
8010648c:	8b 45 08             	mov    0x8(%ebp),%eax
8010648f:	c1 e0 02             	shl    $0x2,%eax
80106492:	01 d0                	add    %edx,%eax
80106494:	8d 48 04             	lea    0x4(%eax),%ecx
80106497:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010649d:	8b 55 0c             	mov    0xc(%ebp),%edx
801064a0:	89 54 24 08          	mov    %edx,0x8(%esp)
801064a4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801064a8:	89 04 24             	mov    %eax,(%esp)
801064ab:	e8 38 ff ff ff       	call   801063e8 <fetchint>
}
801064b0:	c9                   	leave  
801064b1:	c3                   	ret    

801064b2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801064b2:	55                   	push   %ebp
801064b3:	89 e5                	mov    %esp,%ebp
801064b5:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801064b8:	8d 45 fc             	lea    -0x4(%ebp),%eax
801064bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801064bf:	8b 45 08             	mov    0x8(%ebp),%eax
801064c2:	89 04 24             	mov    %eax,(%esp)
801064c5:	e8 b0 ff ff ff       	call   8010647a <argint>
801064ca:	85 c0                	test   %eax,%eax
801064cc:	79 07                	jns    801064d5 <argptr+0x23>
    return -1;
801064ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064d3:	eb 3d                	jmp    80106512 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801064d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801064d8:	89 c2                	mov    %eax,%edx
801064da:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064e0:	8b 00                	mov    (%eax),%eax
801064e2:	39 c2                	cmp    %eax,%edx
801064e4:	73 16                	jae    801064fc <argptr+0x4a>
801064e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801064e9:	89 c2                	mov    %eax,%edx
801064eb:	8b 45 10             	mov    0x10(%ebp),%eax
801064ee:	01 c2                	add    %eax,%edx
801064f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064f6:	8b 00                	mov    (%eax),%eax
801064f8:	39 c2                	cmp    %eax,%edx
801064fa:	76 07                	jbe    80106503 <argptr+0x51>
    return -1;
801064fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106501:	eb 0f                	jmp    80106512 <argptr+0x60>
  *pp = (char*)i;
80106503:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106506:	89 c2                	mov    %eax,%edx
80106508:	8b 45 0c             	mov    0xc(%ebp),%eax
8010650b:	89 10                	mov    %edx,(%eax)
  return 0;
8010650d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106512:	c9                   	leave  
80106513:	c3                   	ret    

80106514 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106514:	55                   	push   %ebp
80106515:	89 e5                	mov    %esp,%ebp
80106517:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010651a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010651d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106521:	8b 45 08             	mov    0x8(%ebp),%eax
80106524:	89 04 24             	mov    %eax,(%esp)
80106527:	e8 4e ff ff ff       	call   8010647a <argint>
8010652c:	85 c0                	test   %eax,%eax
8010652e:	79 07                	jns    80106537 <argstr+0x23>
    return -1;
80106530:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106535:	eb 1e                	jmp    80106555 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80106537:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010653a:	89 c2                	mov    %eax,%edx
8010653c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106542:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106545:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106549:	89 54 24 04          	mov    %edx,0x4(%esp)
8010654d:	89 04 24             	mov    %eax,(%esp)
80106550:	e8 c7 fe ff ff       	call   8010641c <fetchstr>
}
80106555:	c9                   	leave  
80106556:	c3                   	ret    

80106557 <syscall>:
[SYS_getBlkRef]  sys_getBlkRef,
};

void
syscall(void)
{
80106557:	55                   	push   %ebp
80106558:	89 e5                	mov    %esp,%ebp
8010655a:	53                   	push   %ebx
8010655b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010655e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106564:	8b 40 18             	mov    0x18(%eax),%eax
80106567:	8b 40 1c             	mov    0x1c(%eax),%eax
8010656a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
8010656d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106571:	78 2e                	js     801065a1 <syscall+0x4a>
80106573:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106577:	7f 28                	jg     801065a1 <syscall+0x4a>
80106579:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010657c:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106583:	85 c0                	test   %eax,%eax
80106585:	74 1a                	je     801065a1 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80106587:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010658d:	8b 58 18             	mov    0x18(%eax),%ebx
80106590:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106593:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010659a:	ff d0                	call   *%eax
8010659c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010659f:	eb 73                	jmp    80106614 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801065a1:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801065a5:	7e 30                	jle    801065d7 <syscall+0x80>
801065a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065aa:	83 f8 1a             	cmp    $0x1a,%eax
801065ad:	77 28                	ja     801065d7 <syscall+0x80>
801065af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b2:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801065b9:	85 c0                	test   %eax,%eax
801065bb:	74 1a                	je     801065d7 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801065bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065c3:	8b 58 18             	mov    0x18(%eax),%ebx
801065c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c9:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801065d0:	ff d0                	call   *%eax
801065d2:	89 43 1c             	mov    %eax,0x1c(%ebx)
801065d5:	eb 3d                	jmp    80106614 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801065d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065dd:	8d 48 6c             	lea    0x6c(%eax),%ecx
801065e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801065e6:	8b 40 10             	mov    0x10(%eax),%eax
801065e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065ec:	89 54 24 0c          	mov    %edx,0xc(%esp)
801065f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801065f8:	c7 04 24 57 9b 10 80 	movl   $0x80109b57,(%esp)
801065ff:	e8 9d 9d ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106604:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010660a:	8b 40 18             	mov    0x18(%eax),%eax
8010660d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106614:	83 c4 24             	add    $0x24,%esp
80106617:	5b                   	pop    %ebx
80106618:	5d                   	pop    %ebp
80106619:	c3                   	ret    
	...

8010661c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010661c:	55                   	push   %ebp
8010661d:	89 e5                	mov    %esp,%ebp
8010661f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106622:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106625:	89 44 24 04          	mov    %eax,0x4(%esp)
80106629:	8b 45 08             	mov    0x8(%ebp),%eax
8010662c:	89 04 24             	mov    %eax,(%esp)
8010662f:	e8 46 fe ff ff       	call   8010647a <argint>
80106634:	85 c0                	test   %eax,%eax
80106636:	79 07                	jns    8010663f <argfd+0x23>
    return -1;
80106638:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010663d:	eb 50                	jmp    8010668f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010663f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106642:	85 c0                	test   %eax,%eax
80106644:	78 21                	js     80106667 <argfd+0x4b>
80106646:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106649:	83 f8 0f             	cmp    $0xf,%eax
8010664c:	7f 19                	jg     80106667 <argfd+0x4b>
8010664e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106654:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106657:	83 c2 08             	add    $0x8,%edx
8010665a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010665e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106665:	75 07                	jne    8010666e <argfd+0x52>
    return -1;
80106667:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010666c:	eb 21                	jmp    8010668f <argfd+0x73>
  if(pfd)
8010666e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106672:	74 08                	je     8010667c <argfd+0x60>
    *pfd = fd;
80106674:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106677:	8b 45 0c             	mov    0xc(%ebp),%eax
8010667a:	89 10                	mov    %edx,(%eax)
  if(pf)
8010667c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106680:	74 08                	je     8010668a <argfd+0x6e>
    *pf = f;
80106682:	8b 45 10             	mov    0x10(%ebp),%eax
80106685:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106688:	89 10                	mov    %edx,(%eax)
  return 0;
8010668a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010668f:	c9                   	leave  
80106690:	c3                   	ret    

80106691 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106691:	55                   	push   %ebp
80106692:	89 e5                	mov    %esp,%ebp
80106694:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106697:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010669e:	eb 30                	jmp    801066d0 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801066a0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066a6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801066a9:	83 c2 08             	add    $0x8,%edx
801066ac:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801066b0:	85 c0                	test   %eax,%eax
801066b2:	75 18                	jne    801066cc <fdalloc+0x3b>
      proc->ofile[fd] = f;
801066b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066ba:	8b 55 fc             	mov    -0x4(%ebp),%edx
801066bd:	8d 4a 08             	lea    0x8(%edx),%ecx
801066c0:	8b 55 08             	mov    0x8(%ebp),%edx
801066c3:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801066c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801066ca:	eb 0f                	jmp    801066db <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801066cc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801066d0:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801066d4:	7e ca                	jle    801066a0 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801066d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801066db:	c9                   	leave  
801066dc:	c3                   	ret    

801066dd <sys_dup>:

int
sys_dup(void)
{
801066dd:	55                   	push   %ebp
801066de:	89 e5                	mov    %esp,%ebp
801066e0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801066e3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066e6:	89 44 24 08          	mov    %eax,0x8(%esp)
801066ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801066f1:	00 
801066f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066f9:	e8 1e ff ff ff       	call   8010661c <argfd>
801066fe:	85 c0                	test   %eax,%eax
80106700:	79 07                	jns    80106709 <sys_dup+0x2c>
    return -1;
80106702:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106707:	eb 29                	jmp    80106732 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106709:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010670c:	89 04 24             	mov    %eax,(%esp)
8010670f:	e8 7d ff ff ff       	call   80106691 <fdalloc>
80106714:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106717:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010671b:	79 07                	jns    80106724 <sys_dup+0x47>
    return -1;
8010671d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106722:	eb 0e                	jmp    80106732 <sys_dup+0x55>
  filedup(f);
80106724:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106727:	89 04 24             	mov    %eax,(%esp)
8010672a:	e8 4d a8 ff ff       	call   80100f7c <filedup>
  return fd;
8010672f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106732:	c9                   	leave  
80106733:	c3                   	ret    

80106734 <sys_read>:

int
sys_read(void)
{
80106734:	55                   	push   %ebp
80106735:	89 e5                	mov    %esp,%ebp
80106737:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010673a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010673d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106741:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106748:	00 
80106749:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106750:	e8 c7 fe ff ff       	call   8010661c <argfd>
80106755:	85 c0                	test   %eax,%eax
80106757:	78 35                	js     8010678e <sys_read+0x5a>
80106759:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010675c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106760:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106767:	e8 0e fd ff ff       	call   8010647a <argint>
8010676c:	85 c0                	test   %eax,%eax
8010676e:	78 1e                	js     8010678e <sys_read+0x5a>
80106770:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106773:	89 44 24 08          	mov    %eax,0x8(%esp)
80106777:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010677a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010677e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106785:	e8 28 fd ff ff       	call   801064b2 <argptr>
8010678a:	85 c0                	test   %eax,%eax
8010678c:	79 07                	jns    80106795 <sys_read+0x61>
    return -1;
8010678e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106793:	eb 19                	jmp    801067ae <sys_read+0x7a>
  return fileread(f, p, n);
80106795:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106798:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010679b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801067a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801067a6:	89 04 24             	mov    %eax,(%esp)
801067a9:	e8 3b a9 ff ff       	call   801010e9 <fileread>
}
801067ae:	c9                   	leave  
801067af:	c3                   	ret    

801067b0 <sys_write>:

int
sys_write(void)
{
801067b0:	55                   	push   %ebp
801067b1:	89 e5                	mov    %esp,%ebp
801067b3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801067b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801067bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067c4:	00 
801067c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067cc:	e8 4b fe ff ff       	call   8010661c <argfd>
801067d1:	85 c0                	test   %eax,%eax
801067d3:	78 35                	js     8010680a <sys_write+0x5a>
801067d5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801067d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801067dc:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801067e3:	e8 92 fc ff ff       	call   8010647a <argint>
801067e8:	85 c0                	test   %eax,%eax
801067ea:	78 1e                	js     8010680a <sys_write+0x5a>
801067ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801067f3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801067f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801067fa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106801:	e8 ac fc ff ff       	call   801064b2 <argptr>
80106806:	85 c0                	test   %eax,%eax
80106808:	79 07                	jns    80106811 <sys_write+0x61>
    return -1;
8010680a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010680f:	eb 19                	jmp    8010682a <sys_write+0x7a>
  return filewrite(f, p, n);
80106811:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106814:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010681a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010681e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106822:	89 04 24             	mov    %eax,(%esp)
80106825:	e8 7b a9 ff ff       	call   801011a5 <filewrite>
}
8010682a:	c9                   	leave  
8010682b:	c3                   	ret    

8010682c <sys_close>:

int
sys_close(void)
{
8010682c:	55                   	push   %ebp
8010682d:	89 e5                	mov    %esp,%ebp
8010682f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80106832:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106835:	89 44 24 08          	mov    %eax,0x8(%esp)
80106839:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010683c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106840:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106847:	e8 d0 fd ff ff       	call   8010661c <argfd>
8010684c:	85 c0                	test   %eax,%eax
8010684e:	79 07                	jns    80106857 <sys_close+0x2b>
    return -1;
80106850:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106855:	eb 24                	jmp    8010687b <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106857:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010685d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106860:	83 c2 08             	add    $0x8,%edx
80106863:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010686a:	00 
  fileclose(f);
8010686b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010686e:	89 04 24             	mov    %eax,(%esp)
80106871:	e8 4e a7 ff ff       	call   80100fc4 <fileclose>
  return 0;
80106876:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010687b:	c9                   	leave  
8010687c:	c3                   	ret    

8010687d <sys_fstat>:

int
sys_fstat(void)
{
8010687d:	55                   	push   %ebp
8010687e:	89 e5                	mov    %esp,%ebp
80106880:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80106883:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106886:	89 44 24 08          	mov    %eax,0x8(%esp)
8010688a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106891:	00 
80106892:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106899:	e8 7e fd ff ff       	call   8010661c <argfd>
8010689e:	85 c0                	test   %eax,%eax
801068a0:	78 1f                	js     801068c1 <sys_fstat+0x44>
801068a2:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801068a9:	00 
801068aa:	8d 45 f0             	lea    -0x10(%ebp),%eax
801068ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801068b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801068b8:	e8 f5 fb ff ff       	call   801064b2 <argptr>
801068bd:	85 c0                	test   %eax,%eax
801068bf:	79 07                	jns    801068c8 <sys_fstat+0x4b>
    return -1;
801068c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068c6:	eb 12                	jmp    801068da <sys_fstat+0x5d>
  return filestat(f, st);
801068c8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801068cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801068d2:	89 04 24             	mov    %eax,(%esp)
801068d5:	e8 c0 a7 ff ff       	call   8010109a <filestat>
}
801068da:	c9                   	leave  
801068db:	c3                   	ret    

801068dc <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801068dc:	55                   	push   %ebp
801068dd:	89 e5                	mov    %esp,%ebp
801068df:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801068e2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801068e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801068e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068f0:	e8 1f fc ff ff       	call   80106514 <argstr>
801068f5:	85 c0                	test   %eax,%eax
801068f7:	78 17                	js     80106910 <sys_link+0x34>
801068f9:	8d 45 dc             	lea    -0x24(%ebp),%eax
801068fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80106900:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106907:	e8 08 fc ff ff       	call   80106514 <argstr>
8010690c:	85 c0                	test   %eax,%eax
8010690e:	79 0a                	jns    8010691a <sys_link+0x3e>
    return -1;
80106910:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106915:	e9 3c 01 00 00       	jmp    80106a56 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010691a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010691d:	89 04 24             	mov    %eax,(%esp)
80106920:	e8 91 ca ff ff       	call   801033b6 <namei>
80106925:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106928:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010692c:	75 0a                	jne    80106938 <sys_link+0x5c>
    return -1;
8010692e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106933:	e9 1e 01 00 00       	jmp    80106a56 <sys_link+0x17a>

  begin_trans();
80106938:	e8 18 dc ff ff       	call   80104555 <begin_trans>

  ilock(ip);
8010693d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106940:	89 04 24             	mov    %eax,(%esp)
80106943:	e8 94 bd ff ff       	call   801026dc <ilock>
  if(ip->type == T_DIR){
80106948:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010694b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010694f:	66 83 f8 01          	cmp    $0x1,%ax
80106953:	75 1a                	jne    8010696f <sys_link+0x93>
    iunlockput(ip);
80106955:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106958:	89 04 24             	mov    %eax,(%esp)
8010695b:	e8 00 c0 ff ff       	call   80102960 <iunlockput>
    commit_trans();
80106960:	e8 39 dc ff ff       	call   8010459e <commit_trans>
    return -1;
80106965:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010696a:	e9 e7 00 00 00       	jmp    80106a56 <sys_link+0x17a>
  }

  ip->nlink++;
8010696f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106972:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106976:	8d 50 01             	lea    0x1(%eax),%edx
80106979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010697c:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106983:	89 04 24             	mov    %eax,(%esp)
80106986:	e8 95 bb ff ff       	call   80102520 <iupdate>
  iunlock(ip);
8010698b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010698e:	89 04 24             	mov    %eax,(%esp)
80106991:	e8 94 be ff ff       	call   8010282a <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106996:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106999:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010699c:	89 54 24 04          	mov    %edx,0x4(%esp)
801069a0:	89 04 24             	mov    %eax,(%esp)
801069a3:	e8 30 ca ff ff       	call   801033d8 <nameiparent>
801069a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801069ab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801069af:	74 68                	je     80106a19 <sys_link+0x13d>
    goto bad;
  ilock(dp);
801069b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069b4:	89 04 24             	mov    %eax,(%esp)
801069b7:	e8 20 bd ff ff       	call   801026dc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801069bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069bf:	8b 10                	mov    (%eax),%edx
801069c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c4:	8b 00                	mov    (%eax),%eax
801069c6:	39 c2                	cmp    %eax,%edx
801069c8:	75 20                	jne    801069ea <sys_link+0x10e>
801069ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069cd:	8b 40 04             	mov    0x4(%eax),%eax
801069d0:	89 44 24 08          	mov    %eax,0x8(%esp)
801069d4:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801069d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801069db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069de:	89 04 24             	mov    %eax,(%esp)
801069e1:	e8 0f c7 ff ff       	call   801030f5 <dirlink>
801069e6:	85 c0                	test   %eax,%eax
801069e8:	79 0d                	jns    801069f7 <sys_link+0x11b>
    iunlockput(dp);
801069ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069ed:	89 04 24             	mov    %eax,(%esp)
801069f0:	e8 6b bf ff ff       	call   80102960 <iunlockput>
    goto bad;
801069f5:	eb 23                	jmp    80106a1a <sys_link+0x13e>
  }
  iunlockput(dp);
801069f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069fa:	89 04 24             	mov    %eax,(%esp)
801069fd:	e8 5e bf ff ff       	call   80102960 <iunlockput>
  iput(ip);
80106a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a05:	89 04 24             	mov    %eax,(%esp)
80106a08:	e8 82 be ff ff       	call   8010288f <iput>

  commit_trans();
80106a0d:	e8 8c db ff ff       	call   8010459e <commit_trans>

  return 0;
80106a12:	b8 00 00 00 00       	mov    $0x0,%eax
80106a17:	eb 3d                	jmp    80106a56 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106a19:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a1d:	89 04 24             	mov    %eax,(%esp)
80106a20:	e8 b7 bc ff ff       	call   801026dc <ilock>
  ip->nlink--;
80106a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a28:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a2c:	8d 50 ff             	lea    -0x1(%eax),%edx
80106a2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a32:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a39:	89 04 24             	mov    %eax,(%esp)
80106a3c:	e8 df ba ff ff       	call   80102520 <iupdate>
  iunlockput(ip);
80106a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a44:	89 04 24             	mov    %eax,(%esp)
80106a47:	e8 14 bf ff ff       	call   80102960 <iunlockput>
  commit_trans();
80106a4c:	e8 4d db ff ff       	call   8010459e <commit_trans>
  return -1;
80106a51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106a56:	c9                   	leave  
80106a57:	c3                   	ret    

80106a58 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106a58:	55                   	push   %ebp
80106a59:	89 e5                	mov    %esp,%ebp
80106a5b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106a5e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106a65:	eb 4b                	jmp    80106ab2 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106a67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a6a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106a71:	00 
80106a72:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a76:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106a79:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80106a80:	89 04 24             	mov    %eax,(%esp)
80106a83:	e8 ba c1 ff ff       	call   80102c42 <readi>
80106a88:	83 f8 10             	cmp    $0x10,%eax
80106a8b:	74 0c                	je     80106a99 <isdirempty+0x41>
      panic("isdirempty: readi");
80106a8d:	c7 04 24 73 9b 10 80 	movl   $0x80109b73,(%esp)
80106a94:	e8 a4 9a ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106a99:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106a9d:	66 85 c0             	test   %ax,%ax
80106aa0:	74 07                	je     80106aa9 <isdirempty+0x51>
      return 0;
80106aa2:	b8 00 00 00 00       	mov    $0x0,%eax
80106aa7:	eb 1b                	jmp    80106ac4 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aac:	83 c0 10             	add    $0x10,%eax
80106aaf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ab2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ab5:	8b 45 08             	mov    0x8(%ebp),%eax
80106ab8:	8b 40 18             	mov    0x18(%eax),%eax
80106abb:	39 c2                	cmp    %eax,%edx
80106abd:	72 a8                	jb     80106a67 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106abf:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106ac4:	c9                   	leave  
80106ac5:	c3                   	ret    

80106ac6 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106ac6:	55                   	push   %ebp
80106ac7:	89 e5                	mov    %esp,%ebp
80106ac9:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106acc:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106acf:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ad3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ada:	e8 35 fa ff ff       	call   80106514 <argstr>
80106adf:	85 c0                	test   %eax,%eax
80106ae1:	79 0a                	jns    80106aed <sys_unlink+0x27>
    return -1;
80106ae3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ae8:	e9 aa 01 00 00       	jmp    80106c97 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106aed:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106af0:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106af3:	89 54 24 04          	mov    %edx,0x4(%esp)
80106af7:	89 04 24             	mov    %eax,(%esp)
80106afa:	e8 d9 c8 ff ff       	call   801033d8 <nameiparent>
80106aff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b02:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b06:	75 0a                	jne    80106b12 <sys_unlink+0x4c>
    return -1;
80106b08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b0d:	e9 85 01 00 00       	jmp    80106c97 <sys_unlink+0x1d1>

  begin_trans();
80106b12:	e8 3e da ff ff       	call   80104555 <begin_trans>

  ilock(dp);
80106b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b1a:	89 04 24             	mov    %eax,(%esp)
80106b1d:	e8 ba bb ff ff       	call   801026dc <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106b22:	c7 44 24 04 85 9b 10 	movl   $0x80109b85,0x4(%esp)
80106b29:	80 
80106b2a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b2d:	89 04 24             	mov    %eax,(%esp)
80106b30:	e8 d6 c4 ff ff       	call   8010300b <namecmp>
80106b35:	85 c0                	test   %eax,%eax
80106b37:	0f 84 45 01 00 00    	je     80106c82 <sys_unlink+0x1bc>
80106b3d:	c7 44 24 04 87 9b 10 	movl   $0x80109b87,0x4(%esp)
80106b44:	80 
80106b45:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b48:	89 04 24             	mov    %eax,(%esp)
80106b4b:	e8 bb c4 ff ff       	call   8010300b <namecmp>
80106b50:	85 c0                	test   %eax,%eax
80106b52:	0f 84 2a 01 00 00    	je     80106c82 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106b58:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106b5b:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b5f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106b62:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b69:	89 04 24             	mov    %eax,(%esp)
80106b6c:	e8 bc c4 ff ff       	call   8010302d <dirlookup>
80106b71:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106b74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106b78:	0f 84 03 01 00 00    	je     80106c81 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106b7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b81:	89 04 24             	mov    %eax,(%esp)
80106b84:	e8 53 bb ff ff       	call   801026dc <ilock>

  if(ip->nlink < 1)
80106b89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b8c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b90:	66 85 c0             	test   %ax,%ax
80106b93:	7f 0c                	jg     80106ba1 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106b95:	c7 04 24 8a 9b 10 80 	movl   $0x80109b8a,(%esp)
80106b9c:	e8 9c 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106ba1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ba4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ba8:	66 83 f8 01          	cmp    $0x1,%ax
80106bac:	75 1f                	jne    80106bcd <sys_unlink+0x107>
80106bae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bb1:	89 04 24             	mov    %eax,(%esp)
80106bb4:	e8 9f fe ff ff       	call   80106a58 <isdirempty>
80106bb9:	85 c0                	test   %eax,%eax
80106bbb:	75 10                	jne    80106bcd <sys_unlink+0x107>
    iunlockput(ip);
80106bbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bc0:	89 04 24             	mov    %eax,(%esp)
80106bc3:	e8 98 bd ff ff       	call   80102960 <iunlockput>
    goto bad;
80106bc8:	e9 b5 00 00 00       	jmp    80106c82 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106bcd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106bd4:	00 
80106bd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106bdc:	00 
80106bdd:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106be0:	89 04 24             	mov    %eax,(%esp)
80106be3:	e8 42 f5 ff ff       	call   8010612a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106be8:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106beb:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106bf2:	00 
80106bf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80106bf7:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106bfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c01:	89 04 24             	mov    %eax,(%esp)
80106c04:	e8 a4 c1 ff ff       	call   80102dad <writei>
80106c09:	83 f8 10             	cmp    $0x10,%eax
80106c0c:	74 0c                	je     80106c1a <sys_unlink+0x154>
    panic("unlink: writei");
80106c0e:	c7 04 24 9c 9b 10 80 	movl   $0x80109b9c,(%esp)
80106c15:	e8 23 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106c1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c1d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c21:	66 83 f8 01          	cmp    $0x1,%ax
80106c25:	75 1c                	jne    80106c43 <sys_unlink+0x17d>
    dp->nlink--;
80106c27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c2a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c2e:	8d 50 ff             	lea    -0x1(%eax),%edx
80106c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c34:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c3b:	89 04 24             	mov    %eax,(%esp)
80106c3e:	e8 dd b8 ff ff       	call   80102520 <iupdate>
  }
  iunlockput(dp);
80106c43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c46:	89 04 24             	mov    %eax,(%esp)
80106c49:	e8 12 bd ff ff       	call   80102960 <iunlockput>

  ip->nlink--;
80106c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c51:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c55:	8d 50 ff             	lea    -0x1(%eax),%edx
80106c58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c5b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106c5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c62:	89 04 24             	mov    %eax,(%esp)
80106c65:	e8 b6 b8 ff ff       	call   80102520 <iupdate>
  iunlockput(ip);
80106c6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c6d:	89 04 24             	mov    %eax,(%esp)
80106c70:	e8 eb bc ff ff       	call   80102960 <iunlockput>

  commit_trans();
80106c75:	e8 24 d9 ff ff       	call   8010459e <commit_trans>

  return 0;
80106c7a:	b8 00 00 00 00       	mov    $0x0,%eax
80106c7f:	eb 16                	jmp    80106c97 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106c81:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c85:	89 04 24             	mov    %eax,(%esp)
80106c88:	e8 d3 bc ff ff       	call   80102960 <iunlockput>
  commit_trans();
80106c8d:	e8 0c d9 ff ff       	call   8010459e <commit_trans>
  return -1;
80106c92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106c97:	c9                   	leave  
80106c98:	c3                   	ret    

80106c99 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106c99:	55                   	push   %ebp
80106c9a:	89 e5                	mov    %esp,%ebp
80106c9c:	83 ec 48             	sub    $0x48,%esp
80106c9f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106ca2:	8b 55 10             	mov    0x10(%ebp),%edx
80106ca5:	8b 45 14             	mov    0x14(%ebp),%eax
80106ca8:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106cac:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106cb0:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106cb4:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80106cbe:	89 04 24             	mov    %eax,(%esp)
80106cc1:	e8 12 c7 ff ff       	call   801033d8 <nameiparent>
80106cc6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cc9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ccd:	75 0a                	jne    80106cd9 <create+0x40>
    return 0;
80106ccf:	b8 00 00 00 00       	mov    $0x0,%eax
80106cd4:	e9 7e 01 00 00       	jmp    80106e57 <create+0x1be>
  ilock(dp);
80106cd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cdc:	89 04 24             	mov    %eax,(%esp)
80106cdf:	e8 f8 b9 ff ff       	call   801026dc <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106ce4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106ce7:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ceb:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cee:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cf5:	89 04 24             	mov    %eax,(%esp)
80106cf8:	e8 30 c3 ff ff       	call   8010302d <dirlookup>
80106cfd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d00:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d04:	74 47                	je     80106d4d <create+0xb4>
    iunlockput(dp);
80106d06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d09:	89 04 24             	mov    %eax,(%esp)
80106d0c:	e8 4f bc ff ff       	call   80102960 <iunlockput>
    ilock(ip);
80106d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d14:	89 04 24             	mov    %eax,(%esp)
80106d17:	e8 c0 b9 ff ff       	call   801026dc <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106d1c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106d21:	75 15                	jne    80106d38 <create+0x9f>
80106d23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d26:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106d2a:	66 83 f8 02          	cmp    $0x2,%ax
80106d2e:	75 08                	jne    80106d38 <create+0x9f>
      return ip;
80106d30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d33:	e9 1f 01 00 00       	jmp    80106e57 <create+0x1be>
    iunlockput(ip);
80106d38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d3b:	89 04 24             	mov    %eax,(%esp)
80106d3e:	e8 1d bc ff ff       	call   80102960 <iunlockput>
    return 0;
80106d43:	b8 00 00 00 00       	mov    $0x0,%eax
80106d48:	e9 0a 01 00 00       	jmp    80106e57 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106d4d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106d51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d54:	8b 00                	mov    (%eax),%eax
80106d56:	89 54 24 04          	mov    %edx,0x4(%esp)
80106d5a:	89 04 24             	mov    %eax,(%esp)
80106d5d:	e8 e1 b6 ff ff       	call   80102443 <ialloc>
80106d62:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d65:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d69:	75 0c                	jne    80106d77 <create+0xde>
    panic("create: ialloc");
80106d6b:	c7 04 24 ab 9b 10 80 	movl   $0x80109bab,(%esp)
80106d72:	e8 c6 97 ff ff       	call   8010053d <panic>

  ilock(ip);
80106d77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d7a:	89 04 24             	mov    %eax,(%esp)
80106d7d:	e8 5a b9 ff ff       	call   801026dc <ilock>
  ip->major = major;
80106d82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d85:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106d89:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106d8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d90:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106d94:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106d98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d9b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106da1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106da4:	89 04 24             	mov    %eax,(%esp)
80106da7:	e8 74 b7 ff ff       	call   80102520 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106dac:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106db1:	75 6a                	jne    80106e1d <create+0x184>
    dp->nlink++;  // for ".."
80106db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106dba:	8d 50 01             	lea    0x1(%eax),%edx
80106dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dc0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dc7:	89 04 24             	mov    %eax,(%esp)
80106dca:	e8 51 b7 ff ff       	call   80102520 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106dcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dd2:	8b 40 04             	mov    0x4(%eax),%eax
80106dd5:	89 44 24 08          	mov    %eax,0x8(%esp)
80106dd9:	c7 44 24 04 85 9b 10 	movl   $0x80109b85,0x4(%esp)
80106de0:	80 
80106de1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106de4:	89 04 24             	mov    %eax,(%esp)
80106de7:	e8 09 c3 ff ff       	call   801030f5 <dirlink>
80106dec:	85 c0                	test   %eax,%eax
80106dee:	78 21                	js     80106e11 <create+0x178>
80106df0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106df3:	8b 40 04             	mov    0x4(%eax),%eax
80106df6:	89 44 24 08          	mov    %eax,0x8(%esp)
80106dfa:	c7 44 24 04 87 9b 10 	movl   $0x80109b87,0x4(%esp)
80106e01:	80 
80106e02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e05:	89 04 24             	mov    %eax,(%esp)
80106e08:	e8 e8 c2 ff ff       	call   801030f5 <dirlink>
80106e0d:	85 c0                	test   %eax,%eax
80106e0f:	79 0c                	jns    80106e1d <create+0x184>
      panic("create dots");
80106e11:	c7 04 24 ba 9b 10 80 	movl   $0x80109bba,(%esp)
80106e18:	e8 20 97 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106e1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e20:	8b 40 04             	mov    0x4(%eax),%eax
80106e23:	89 44 24 08          	mov    %eax,0x8(%esp)
80106e27:	8d 45 de             	lea    -0x22(%ebp),%eax
80106e2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e31:	89 04 24             	mov    %eax,(%esp)
80106e34:	e8 bc c2 ff ff       	call   801030f5 <dirlink>
80106e39:	85 c0                	test   %eax,%eax
80106e3b:	79 0c                	jns    80106e49 <create+0x1b0>
    panic("create: dirlink");
80106e3d:	c7 04 24 c6 9b 10 80 	movl   $0x80109bc6,(%esp)
80106e44:	e8 f4 96 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e4c:	89 04 24             	mov    %eax,(%esp)
80106e4f:	e8 0c bb ff ff       	call   80102960 <iunlockput>

  return ip;
80106e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106e57:	c9                   	leave  
80106e58:	c3                   	ret    

80106e59 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80106e59:	55                   	push   %ebp
80106e5a:	89 e5                	mov    %esp,%ebp
80106e5c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106e5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e62:	25 00 02 00 00       	and    $0x200,%eax
80106e67:	85 c0                	test   %eax,%eax
80106e69:	74 40                	je     80106eab <fileopen+0x52>
    begin_trans();
80106e6b:	e8 e5 d6 ff ff       	call   80104555 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106e70:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106e77:	00 
80106e78:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106e7f:	00 
80106e80:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106e87:	00 
80106e88:	8b 45 08             	mov    0x8(%ebp),%eax
80106e8b:	89 04 24             	mov    %eax,(%esp)
80106e8e:	e8 06 fe ff ff       	call   80106c99 <create>
80106e93:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106e96:	e8 03 d7 ff ff       	call   8010459e <commit_trans>
    if(ip == 0)
80106e9b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e9f:	75 5b                	jne    80106efc <fileopen+0xa3>
      return 0;
80106ea1:	b8 00 00 00 00       	mov    $0x0,%eax
80106ea6:	e9 e5 00 00 00       	jmp    80106f90 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106eab:	8b 45 08             	mov    0x8(%ebp),%eax
80106eae:	89 04 24             	mov    %eax,(%esp)
80106eb1:	e8 00 c5 ff ff       	call   801033b6 <namei>
80106eb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106eb9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ebd:	75 0a                	jne    80106ec9 <fileopen+0x70>
      return 0;
80106ebf:	b8 00 00 00 00       	mov    $0x0,%eax
80106ec4:	e9 c7 00 00 00       	jmp    80106f90 <fileopen+0x137>
    ilock(ip);
80106ec9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ecc:	89 04 24             	mov    %eax,(%esp)
80106ecf:	e8 08 b8 ff ff       	call   801026dc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106edb:	66 83 f8 01          	cmp    $0x1,%ax
80106edf:	75 1b                	jne    80106efc <fileopen+0xa3>
80106ee1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106ee5:	74 15                	je     80106efc <fileopen+0xa3>
      iunlockput(ip);
80106ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eea:	89 04 24             	mov    %eax,(%esp)
80106eed:	e8 6e ba ff ff       	call   80102960 <iunlockput>
      return 0;
80106ef2:	b8 00 00 00 00       	mov    $0x0,%eax
80106ef7:	e9 94 00 00 00       	jmp    80106f90 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106efc:	e8 1b a0 ff ff       	call   80100f1c <filealloc>
80106f01:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f04:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f08:	75 23                	jne    80106f2d <fileopen+0xd4>
    if(f)
80106f0a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f0e:	74 0b                	je     80106f1b <fileopen+0xc2>
      fileclose(f);
80106f10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f13:	89 04 24             	mov    %eax,(%esp)
80106f16:	e8 a9 a0 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f1e:	89 04 24             	mov    %eax,(%esp)
80106f21:	e8 3a ba ff ff       	call   80102960 <iunlockput>
    return 0;
80106f26:	b8 00 00 00 00       	mov    $0x0,%eax
80106f2b:	eb 63                	jmp    80106f90 <fileopen+0x137>
  }
  iunlock(ip);
80106f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f30:	89 04 24             	mov    %eax,(%esp)
80106f33:	e8 f2 b8 ff ff       	call   8010282a <iunlock>

  f->type = FD_INODE;
80106f38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f3b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106f41:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f44:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f47:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106f4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f4d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106f54:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f57:	83 e0 01             	and    $0x1,%eax
80106f5a:	85 c0                	test   %eax,%eax
80106f5c:	0f 94 c2             	sete   %dl
80106f5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f62:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106f65:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f68:	83 e0 01             	and    $0x1,%eax
80106f6b:	84 c0                	test   %al,%al
80106f6d:	75 0a                	jne    80106f79 <fileopen+0x120>
80106f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f72:	83 e0 02             	and    $0x2,%eax
80106f75:	85 c0                	test   %eax,%eax
80106f77:	74 07                	je     80106f80 <fileopen+0x127>
80106f79:	b8 01 00 00 00       	mov    $0x1,%eax
80106f7e:	eb 05                	jmp    80106f85 <fileopen+0x12c>
80106f80:	b8 00 00 00 00       	mov    $0x0,%eax
80106f85:	89 c2                	mov    %eax,%edx
80106f87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f8a:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106f8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106f90:	c9                   	leave  
80106f91:	c3                   	ret    

80106f92 <sys_open>:

int
sys_open(void)
{
80106f92:	55                   	push   %ebp
80106f93:	89 e5                	mov    %esp,%ebp
80106f95:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106f98:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f9f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106fa6:	e8 69 f5 ff ff       	call   80106514 <argstr>
80106fab:	85 c0                	test   %eax,%eax
80106fad:	78 17                	js     80106fc6 <sys_open+0x34>
80106faf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106fb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106fb6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106fbd:	e8 b8 f4 ff ff       	call   8010647a <argint>
80106fc2:	85 c0                	test   %eax,%eax
80106fc4:	79 0a                	jns    80106fd0 <sys_open+0x3e>
    return -1;
80106fc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fcb:	e9 46 01 00 00       	jmp    80107116 <sys_open+0x184>
  if(omode & O_CREATE){
80106fd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fd3:	25 00 02 00 00       	and    $0x200,%eax
80106fd8:	85 c0                	test   %eax,%eax
80106fda:	74 40                	je     8010701c <sys_open+0x8a>
    begin_trans();
80106fdc:	e8 74 d5 ff ff       	call   80104555 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106fe1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106fe4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106feb:	00 
80106fec:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106ff3:	00 
80106ff4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106ffb:	00 
80106ffc:	89 04 24             	mov    %eax,(%esp)
80106fff:	e8 95 fc ff ff       	call   80106c99 <create>
80107004:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80107007:	e8 92 d5 ff ff       	call   8010459e <commit_trans>
    if(ip == 0)
8010700c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107010:	75 5c                	jne    8010706e <sys_open+0xdc>
      return -1;
80107012:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107017:	e9 fa 00 00 00       	jmp    80107116 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
8010701c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010701f:	89 04 24             	mov    %eax,(%esp)
80107022:	e8 8f c3 ff ff       	call   801033b6 <namei>
80107027:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010702a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010702e:	75 0a                	jne    8010703a <sys_open+0xa8>
      return -1;
80107030:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107035:	e9 dc 00 00 00       	jmp    80107116 <sys_open+0x184>
    ilock(ip);
8010703a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010703d:	89 04 24             	mov    %eax,(%esp)
80107040:	e8 97 b6 ff ff       	call   801026dc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80107045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107048:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010704c:	66 83 f8 01          	cmp    $0x1,%ax
80107050:	75 1c                	jne    8010706e <sys_open+0xdc>
80107052:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107055:	85 c0                	test   %eax,%eax
80107057:	74 15                	je     8010706e <sys_open+0xdc>
      iunlockput(ip);
80107059:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010705c:	89 04 24             	mov    %eax,(%esp)
8010705f:	e8 fc b8 ff ff       	call   80102960 <iunlockput>
      return -1;
80107064:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107069:	e9 a8 00 00 00       	jmp    80107116 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010706e:	e8 a9 9e ff ff       	call   80100f1c <filealloc>
80107073:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107076:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010707a:	74 14                	je     80107090 <sys_open+0xfe>
8010707c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010707f:	89 04 24             	mov    %eax,(%esp)
80107082:	e8 0a f6 ff ff       	call   80106691 <fdalloc>
80107087:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010708a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010708e:	79 23                	jns    801070b3 <sys_open+0x121>
    if(f)
80107090:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107094:	74 0b                	je     801070a1 <sys_open+0x10f>
      fileclose(f);
80107096:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107099:	89 04 24             	mov    %eax,(%esp)
8010709c:	e8 23 9f ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801070a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070a4:	89 04 24             	mov    %eax,(%esp)
801070a7:	e8 b4 b8 ff ff       	call   80102960 <iunlockput>
    return -1;
801070ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070b1:	eb 63                	jmp    80107116 <sys_open+0x184>
  }
  iunlock(ip);
801070b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070b6:	89 04 24             	mov    %eax,(%esp)
801070b9:	e8 6c b7 ff ff       	call   8010282a <iunlock>

  f->type = FD_INODE;
801070be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070c1:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801070c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801070cd:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801070d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070d3:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801070da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070dd:	83 e0 01             	and    $0x1,%eax
801070e0:	85 c0                	test   %eax,%eax
801070e2:	0f 94 c2             	sete   %dl
801070e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070e8:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801070eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070ee:	83 e0 01             	and    $0x1,%eax
801070f1:	84 c0                	test   %al,%al
801070f3:	75 0a                	jne    801070ff <sys_open+0x16d>
801070f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070f8:	83 e0 02             	and    $0x2,%eax
801070fb:	85 c0                	test   %eax,%eax
801070fd:	74 07                	je     80107106 <sys_open+0x174>
801070ff:	b8 01 00 00 00       	mov    $0x1,%eax
80107104:	eb 05                	jmp    8010710b <sys_open+0x179>
80107106:	b8 00 00 00 00       	mov    $0x0,%eax
8010710b:	89 c2                	mov    %eax,%edx
8010710d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107110:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80107113:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80107116:	c9                   	leave  
80107117:	c3                   	ret    

80107118 <sys_mkdir>:

int
sys_mkdir(void)
{
80107118:	55                   	push   %ebp
80107119:	89 e5                	mov    %esp,%ebp
8010711b:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
8010711e:	e8 32 d4 ff ff       	call   80104555 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80107123:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107126:	89 44 24 04          	mov    %eax,0x4(%esp)
8010712a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107131:	e8 de f3 ff ff       	call   80106514 <argstr>
80107136:	85 c0                	test   %eax,%eax
80107138:	78 2c                	js     80107166 <sys_mkdir+0x4e>
8010713a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010713d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80107144:	00 
80107145:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010714c:	00 
8010714d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107154:	00 
80107155:	89 04 24             	mov    %eax,(%esp)
80107158:	e8 3c fb ff ff       	call   80106c99 <create>
8010715d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107160:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107164:	75 0c                	jne    80107172 <sys_mkdir+0x5a>
    commit_trans();
80107166:	e8 33 d4 ff ff       	call   8010459e <commit_trans>
    return -1;
8010716b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107170:	eb 15                	jmp    80107187 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80107172:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107175:	89 04 24             	mov    %eax,(%esp)
80107178:	e8 e3 b7 ff ff       	call   80102960 <iunlockput>
  commit_trans();
8010717d:	e8 1c d4 ff ff       	call   8010459e <commit_trans>
  return 0;
80107182:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107187:	c9                   	leave  
80107188:	c3                   	ret    

80107189 <sys_mknod>:

int
sys_mknod(void)
{
80107189:	55                   	push   %ebp
8010718a:	89 e5                	mov    %esp,%ebp
8010718c:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
8010718f:	e8 c1 d3 ff ff       	call   80104555 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80107194:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107197:	89 44 24 04          	mov    %eax,0x4(%esp)
8010719b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071a2:	e8 6d f3 ff ff       	call   80106514 <argstr>
801071a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801071aa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071ae:	78 5e                	js     8010720e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801071b0:	8d 45 e8             	lea    -0x18(%ebp),%eax
801071b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801071b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071be:	e8 b7 f2 ff ff       	call   8010647a <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801071c3:	85 c0                	test   %eax,%eax
801071c5:	78 47                	js     8010720e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801071c7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801071ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801071ce:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801071d5:	e8 a0 f2 ff ff       	call   8010647a <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801071da:	85 c0                	test   %eax,%eax
801071dc:	78 30                	js     8010720e <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801071de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801071e1:	0f bf c8             	movswl %ax,%ecx
801071e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801071e7:	0f bf d0             	movswl %ax,%edx
801071ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801071ed:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801071f1:	89 54 24 08          	mov    %edx,0x8(%esp)
801071f5:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801071fc:	00 
801071fd:	89 04 24             	mov    %eax,(%esp)
80107200:	e8 94 fa ff ff       	call   80106c99 <create>
80107205:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107208:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010720c:	75 0c                	jne    8010721a <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
8010720e:	e8 8b d3 ff ff       	call   8010459e <commit_trans>
    return -1;
80107213:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107218:	eb 15                	jmp    8010722f <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010721a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010721d:	89 04 24             	mov    %eax,(%esp)
80107220:	e8 3b b7 ff ff       	call   80102960 <iunlockput>
  commit_trans();
80107225:	e8 74 d3 ff ff       	call   8010459e <commit_trans>
  return 0;
8010722a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010722f:	c9                   	leave  
80107230:	c3                   	ret    

80107231 <sys_chdir>:

int
sys_chdir(void)
{
80107231:	55                   	push   %ebp
80107232:	89 e5                	mov    %esp,%ebp
80107234:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80107237:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010723a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010723e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107245:	e8 ca f2 ff ff       	call   80106514 <argstr>
8010724a:	85 c0                	test   %eax,%eax
8010724c:	78 14                	js     80107262 <sys_chdir+0x31>
8010724e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107251:	89 04 24             	mov    %eax,(%esp)
80107254:	e8 5d c1 ff ff       	call   801033b6 <namei>
80107259:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010725c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107260:	75 07                	jne    80107269 <sys_chdir+0x38>
    return -1;
80107262:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107267:	eb 57                	jmp    801072c0 <sys_chdir+0x8f>
  ilock(ip);
80107269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010726c:	89 04 24             	mov    %eax,(%esp)
8010726f:	e8 68 b4 ff ff       	call   801026dc <ilock>
  if(ip->type != T_DIR){
80107274:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107277:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010727b:	66 83 f8 01          	cmp    $0x1,%ax
8010727f:	74 12                	je     80107293 <sys_chdir+0x62>
    iunlockput(ip);
80107281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107284:	89 04 24             	mov    %eax,(%esp)
80107287:	e8 d4 b6 ff ff       	call   80102960 <iunlockput>
    return -1;
8010728c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107291:	eb 2d                	jmp    801072c0 <sys_chdir+0x8f>
  }
  iunlock(ip);
80107293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107296:	89 04 24             	mov    %eax,(%esp)
80107299:	e8 8c b5 ff ff       	call   8010282a <iunlock>
  iput(proc->cwd);
8010729e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072a4:	8b 40 68             	mov    0x68(%eax),%eax
801072a7:	89 04 24             	mov    %eax,(%esp)
801072aa:	e8 e0 b5 ff ff       	call   8010288f <iput>
  proc->cwd = ip;
801072af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801072b8:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801072bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801072c0:	c9                   	leave  
801072c1:	c3                   	ret    

801072c2 <sys_exec>:

int
sys_exec(void)
{
801072c2:	55                   	push   %ebp
801072c3:	89 e5                	mov    %esp,%ebp
801072c5:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801072cb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801072ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801072d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072d9:	e8 36 f2 ff ff       	call   80106514 <argstr>
801072de:	85 c0                	test   %eax,%eax
801072e0:	78 1a                	js     801072fc <sys_exec+0x3a>
801072e2:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801072e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801072ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801072f3:	e8 82 f1 ff ff       	call   8010647a <argint>
801072f8:	85 c0                	test   %eax,%eax
801072fa:	79 0a                	jns    80107306 <sys_exec+0x44>
    return -1;
801072fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107301:	e9 e2 00 00 00       	jmp    801073e8 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107306:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010730d:	00 
8010730e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107315:	00 
80107316:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010731c:	89 04 24             	mov    %eax,(%esp)
8010731f:	e8 06 ee ff ff       	call   8010612a <memset>
  for(i=0;; i++){
80107324:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010732b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010732e:	83 f8 1f             	cmp    $0x1f,%eax
80107331:	76 0a                	jbe    8010733d <sys_exec+0x7b>
      return -1;
80107333:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107338:	e9 ab 00 00 00       	jmp    801073e8 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
8010733d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107340:	c1 e0 02             	shl    $0x2,%eax
80107343:	89 c2                	mov    %eax,%edx
80107345:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010734b:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
8010734e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107354:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
8010735a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010735e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80107362:	89 04 24             	mov    %eax,(%esp)
80107365:	e8 7e f0 ff ff       	call   801063e8 <fetchint>
8010736a:	85 c0                	test   %eax,%eax
8010736c:	79 07                	jns    80107375 <sys_exec+0xb3>
      return -1;
8010736e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107373:	eb 73                	jmp    801073e8 <sys_exec+0x126>
    if(uarg == 0){
80107375:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
8010737b:	85 c0                	test   %eax,%eax
8010737d:	75 26                	jne    801073a5 <sys_exec+0xe3>
      argv[i] = 0;
8010737f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107382:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107389:	00 00 00 00 
      break;
8010738d:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
8010738e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107391:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107397:	89 54 24 04          	mov    %edx,0x4(%esp)
8010739b:	89 04 24             	mov    %eax,(%esp)
8010739e:	e8 59 97 ff ff       	call   80100afc <exec>
801073a3:	eb 43                	jmp    801073e8 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801073a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073a8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801073af:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801073b5:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801073b8:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801073be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073c4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801073c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801073cc:	89 04 24             	mov    %eax,(%esp)
801073cf:	e8 48 f0 ff ff       	call   8010641c <fetchstr>
801073d4:	85 c0                	test   %eax,%eax
801073d6:	79 07                	jns    801073df <sys_exec+0x11d>
      return -1;
801073d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073dd:	eb 09                	jmp    801073e8 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801073df:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801073e3:	e9 43 ff ff ff       	jmp    8010732b <sys_exec+0x69>
  return exec(path, argv);
}
801073e8:	c9                   	leave  
801073e9:	c3                   	ret    

801073ea <sys_pipe>:

int
sys_pipe(void)
{
801073ea:	55                   	push   %ebp
801073eb:	89 e5                	mov    %esp,%ebp
801073ed:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801073f0:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801073f7:	00 
801073f8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801073fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801073ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107406:	e8 a7 f0 ff ff       	call   801064b2 <argptr>
8010740b:	85 c0                	test   %eax,%eax
8010740d:	79 0a                	jns    80107419 <sys_pipe+0x2f>
    return -1;
8010740f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107414:	e9 9b 00 00 00       	jmp    801074b4 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80107419:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010741c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107420:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107423:	89 04 24             	mov    %eax,(%esp)
80107426:	e8 45 db ff ff       	call   80104f70 <pipealloc>
8010742b:	85 c0                	test   %eax,%eax
8010742d:	79 07                	jns    80107436 <sys_pipe+0x4c>
    return -1;
8010742f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107434:	eb 7e                	jmp    801074b4 <sys_pipe+0xca>
  fd0 = -1;
80107436:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010743d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107440:	89 04 24             	mov    %eax,(%esp)
80107443:	e8 49 f2 ff ff       	call   80106691 <fdalloc>
80107448:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010744b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010744f:	78 14                	js     80107465 <sys_pipe+0x7b>
80107451:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107454:	89 04 24             	mov    %eax,(%esp)
80107457:	e8 35 f2 ff ff       	call   80106691 <fdalloc>
8010745c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010745f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107463:	79 37                	jns    8010749c <sys_pipe+0xb2>
    if(fd0 >= 0)
80107465:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107469:	78 14                	js     8010747f <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010746b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107471:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107474:	83 c2 08             	add    $0x8,%edx
80107477:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010747e:	00 
    fileclose(rf);
8010747f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107482:	89 04 24             	mov    %eax,(%esp)
80107485:	e8 3a 9b ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
8010748a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010748d:	89 04 24             	mov    %eax,(%esp)
80107490:	e8 2f 9b ff ff       	call   80100fc4 <fileclose>
    return -1;
80107495:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010749a:	eb 18                	jmp    801074b4 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010749c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010749f:	8b 55 f4             	mov    -0xc(%ebp),%edx
801074a2:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801074a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801074a7:	8d 50 04             	lea    0x4(%eax),%edx
801074aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074ad:	89 02                	mov    %eax,(%edx)
  return 0;
801074af:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074b4:	c9                   	leave  
801074b5:	c3                   	ret    
	...

801074b8 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801074b8:	55                   	push   %ebp
801074b9:	89 e5                	mov    %esp,%ebp
801074bb:	83 ec 08             	sub    $0x8,%esp
  return fork();
801074be:	e8 67 e1 ff ff       	call   8010562a <fork>
}
801074c3:	c9                   	leave  
801074c4:	c3                   	ret    

801074c5 <sys_exit>:

int
sys_exit(void)
{
801074c5:	55                   	push   %ebp
801074c6:	89 e5                	mov    %esp,%ebp
801074c8:	83 ec 08             	sub    $0x8,%esp
  exit();
801074cb:	e8 bd e2 ff ff       	call   8010578d <exit>
  return 0;  // not reached
801074d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074d5:	c9                   	leave  
801074d6:	c3                   	ret    

801074d7 <sys_wait>:

int
sys_wait(void)
{
801074d7:	55                   	push   %ebp
801074d8:	89 e5                	mov    %esp,%ebp
801074da:	83 ec 08             	sub    $0x8,%esp
  return wait();
801074dd:	e8 c3 e3 ff ff       	call   801058a5 <wait>
}
801074e2:	c9                   	leave  
801074e3:	c3                   	ret    

801074e4 <sys_kill>:

int
sys_kill(void)
{
801074e4:	55                   	push   %ebp
801074e5:	89 e5                	mov    %esp,%ebp
801074e7:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801074ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
801074ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801074f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801074f8:	e8 7d ef ff ff       	call   8010647a <argint>
801074fd:	85 c0                	test   %eax,%eax
801074ff:	79 07                	jns    80107508 <sys_kill+0x24>
    return -1;
80107501:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107506:	eb 0b                	jmp    80107513 <sys_kill+0x2f>
  return kill(pid);
80107508:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010750b:	89 04 24             	mov    %eax,(%esp)
8010750e:	e8 ee e7 ff ff       	call   80105d01 <kill>
}
80107513:	c9                   	leave  
80107514:	c3                   	ret    

80107515 <sys_getpid>:

int
sys_getpid(void)
{
80107515:	55                   	push   %ebp
80107516:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107518:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010751e:	8b 40 10             	mov    0x10(%eax),%eax
}
80107521:	5d                   	pop    %ebp
80107522:	c3                   	ret    

80107523 <sys_sbrk>:

int
sys_sbrk(void)
{
80107523:	55                   	push   %ebp
80107524:	89 e5                	mov    %esp,%ebp
80107526:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107529:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010752c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107530:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107537:	e8 3e ef ff ff       	call   8010647a <argint>
8010753c:	85 c0                	test   %eax,%eax
8010753e:	79 07                	jns    80107547 <sys_sbrk+0x24>
    return -1;
80107540:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107545:	eb 24                	jmp    8010756b <sys_sbrk+0x48>
  addr = proc->sz;
80107547:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010754d:	8b 00                	mov    (%eax),%eax
8010754f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80107552:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107555:	89 04 24             	mov    %eax,(%esp)
80107558:	e8 28 e0 ff ff       	call   80105585 <growproc>
8010755d:	85 c0                	test   %eax,%eax
8010755f:	79 07                	jns    80107568 <sys_sbrk+0x45>
    return -1;
80107561:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107566:	eb 03                	jmp    8010756b <sys_sbrk+0x48>
  return addr;
80107568:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010756b:	c9                   	leave  
8010756c:	c3                   	ret    

8010756d <sys_sleep>:

int
sys_sleep(void)
{
8010756d:	55                   	push   %ebp
8010756e:	89 e5                	mov    %esp,%ebp
80107570:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80107573:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107576:	89 44 24 04          	mov    %eax,0x4(%esp)
8010757a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107581:	e8 f4 ee ff ff       	call   8010647a <argint>
80107586:	85 c0                	test   %eax,%eax
80107588:	79 07                	jns    80107591 <sys_sleep+0x24>
    return -1;
8010758a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010758f:	eb 6c                	jmp    801075fd <sys_sleep+0x90>
  acquire(&tickslock);
80107591:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107598:	e8 3e e9 ff ff       	call   80105edb <acquire>
  ticks0 = ticks;
8010759d:	a1 00 37 11 80       	mov    0x80113700,%eax
801075a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801075a5:	eb 34                	jmp    801075db <sys_sleep+0x6e>
    if(proc->killed){
801075a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801075ad:	8b 40 24             	mov    0x24(%eax),%eax
801075b0:	85 c0                	test   %eax,%eax
801075b2:	74 13                	je     801075c7 <sys_sleep+0x5a>
      release(&tickslock);
801075b4:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
801075bb:	e8 7d e9 ff ff       	call   80105f3d <release>
      return -1;
801075c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075c5:	eb 36                	jmp    801075fd <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801075c7:	c7 44 24 04 c0 2e 11 	movl   $0x80112ec0,0x4(%esp)
801075ce:	80 
801075cf:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801075d6:	e8 22 e6 ff ff       	call   80105bfd <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801075db:	a1 00 37 11 80       	mov    0x80113700,%eax
801075e0:	89 c2                	mov    %eax,%edx
801075e2:	2b 55 f4             	sub    -0xc(%ebp),%edx
801075e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801075e8:	39 c2                	cmp    %eax,%edx
801075ea:	72 bb                	jb     801075a7 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801075ec:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
801075f3:	e8 45 e9 ff ff       	call   80105f3d <release>
  return 0;
801075f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801075fd:	c9                   	leave  
801075fe:	c3                   	ret    

801075ff <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801075ff:	55                   	push   %ebp
80107600:	89 e5                	mov    %esp,%ebp
80107602:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107605:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
8010760c:	e8 ca e8 ff ff       	call   80105edb <acquire>
  xticks = ticks;
80107611:	a1 00 37 11 80       	mov    0x80113700,%eax
80107616:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107619:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107620:	e8 18 e9 ff ff       	call   80105f3d <release>
  return xticks;
80107625:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107628:	c9                   	leave  
80107629:	c3                   	ret    

8010762a <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
8010762a:	55                   	push   %ebp
8010762b:	89 e5                	mov    %esp,%ebp
8010762d:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
80107630:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107633:	89 44 24 04          	mov    %eax,0x4(%esp)
80107637:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010763e:	e8 d1 ee ff ff       	call   80106514 <argstr>
80107643:	85 c0                	test   %eax,%eax
80107645:	79 07                	jns    8010764e <sys_getFileBlocks+0x24>
    return -1;
80107647:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010764c:	eb 0b                	jmp    80107659 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
8010764e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107651:	89 04 24             	mov    %eax,(%esp)
80107654:	e8 91 9c ff ff       	call   801012ea <getFileBlocks>
}
80107659:	c9                   	leave  
8010765a:	c3                   	ret    

8010765b <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
8010765b:	55                   	push   %ebp
8010765c:	89 e5                	mov    %esp,%ebp
8010765e:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
80107661:	e8 e1 9d ff ff       	call   80101447 <getFreeBlocks>
}
80107666:	c9                   	leave  
80107667:	c3                   	ret    

80107668 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
80107668:	55                   	push   %ebp
80107669:	89 e5                	mov    %esp,%ebp
8010766b:	83 ec 08             	sub    $0x8,%esp
  return getSharedBlocksRate();
8010766e:	e8 6b a8 ff ff       	call   80101ede <getSharedBlocksRate>
}
80107673:	c9                   	leave  
80107674:	c3                   	ret    

80107675 <sys_dedup>:

int
sys_dedup(void)
{
80107675:	55                   	push   %ebp
80107676:	89 e5                	mov    %esp,%ebp
80107678:	83 ec 08             	sub    $0x8,%esp
  return dedup();
8010767b:	e8 09 a0 ff ff       	call   80101689 <dedup>
}
80107680:	c9                   	leave  
80107681:	c3                   	ret    

80107682 <sys_getBlkRef>:

int
sys_getBlkRef(void)
{
80107682:	55                   	push   %ebp
80107683:	89 e5                	mov    %esp,%ebp
80107685:	83 ec 28             	sub    $0x28,%esp
  int n;
  if(argint(0, &n) < 0)
80107688:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010768b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010768f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107696:	e8 df ed ff ff       	call   8010647a <argint>
8010769b:	85 c0                	test   %eax,%eax
8010769d:	79 07                	jns    801076a6 <sys_getBlkRef+0x24>
    return -1;
8010769f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801076a4:	eb 0b                	jmp    801076b1 <sys_getBlkRef+0x2f>
  return getBlkRef(n);
801076a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a9:	89 04 24             	mov    %eax,(%esp)
801076ac:	e8 33 c0 ff ff       	call   801036e4 <getBlkRef>
}
801076b1:	c9                   	leave  
801076b2:	c3                   	ret    
	...

801076b4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801076b4:	55                   	push   %ebp
801076b5:	89 e5                	mov    %esp,%ebp
801076b7:	83 ec 08             	sub    $0x8,%esp
801076ba:	8b 55 08             	mov    0x8(%ebp),%edx
801076bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801076c0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801076c4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801076c7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801076cb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801076cf:	ee                   	out    %al,(%dx)
}
801076d0:	c9                   	leave  
801076d1:	c3                   	ret    

801076d2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801076d2:	55                   	push   %ebp
801076d3:	89 e5                	mov    %esp,%ebp
801076d5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801076d8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801076df:	00 
801076e0:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801076e7:	e8 c8 ff ff ff       	call   801076b4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801076ec:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801076f3:	00 
801076f4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801076fb:	e8 b4 ff ff ff       	call   801076b4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107700:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107707:	00 
80107708:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010770f:	e8 a0 ff ff ff       	call   801076b4 <outb>
  picenable(IRQ_TIMER);
80107714:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010771b:	e8 d9 d6 ff ff       	call   80104df9 <picenable>
}
80107720:	c9                   	leave  
80107721:	c3                   	ret    
	...

80107724 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107724:	1e                   	push   %ds
  pushl %es
80107725:	06                   	push   %es
  pushl %fs
80107726:	0f a0                	push   %fs
  pushl %gs
80107728:	0f a8                	push   %gs
  pushal
8010772a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010772b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010772f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107731:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80107733:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107737:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107739:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010773b:	54                   	push   %esp
  call trap
8010773c:	e8 de 01 00 00       	call   8010791f <trap>
  addl $4, %esp
80107741:	83 c4 04             	add    $0x4,%esp

80107744 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107744:	61                   	popa   
  popl %gs
80107745:	0f a9                	pop    %gs
  popl %fs
80107747:	0f a1                	pop    %fs
  popl %es
80107749:	07                   	pop    %es
  popl %ds
8010774a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010774b:	83 c4 08             	add    $0x8,%esp
  iret
8010774e:	cf                   	iret   
	...

80107750 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107750:	55                   	push   %ebp
80107751:	89 e5                	mov    %esp,%ebp
80107753:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107756:	8b 45 0c             	mov    0xc(%ebp),%eax
80107759:	83 e8 01             	sub    $0x1,%eax
8010775c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107760:	8b 45 08             	mov    0x8(%ebp),%eax
80107763:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107767:	8b 45 08             	mov    0x8(%ebp),%eax
8010776a:	c1 e8 10             	shr    $0x10,%eax
8010776d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80107771:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107774:	0f 01 18             	lidtl  (%eax)
}
80107777:	c9                   	leave  
80107778:	c3                   	ret    

80107779 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107779:	55                   	push   %ebp
8010777a:	89 e5                	mov    %esp,%ebp
8010777c:	53                   	push   %ebx
8010777d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80107780:	0f 20 d3             	mov    %cr2,%ebx
80107783:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80107786:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80107789:	83 c4 10             	add    $0x10,%esp
8010778c:	5b                   	pop    %ebx
8010778d:	5d                   	pop    %ebp
8010778e:	c3                   	ret    

8010778f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010778f:	55                   	push   %ebp
80107790:	89 e5                	mov    %esp,%ebp
80107792:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107795:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010779c:	e9 c3 00 00 00       	jmp    80107864 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801077a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a4:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
801077ab:	89 c2                	mov    %eax,%edx
801077ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b0:	66 89 14 c5 00 2f 11 	mov    %dx,-0x7feed100(,%eax,8)
801077b7:	80 
801077b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077bb:	66 c7 04 c5 02 2f 11 	movw   $0x8,-0x7feed0fe(,%eax,8)
801077c2:	80 08 00 
801077c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c8:	0f b6 14 c5 04 2f 11 	movzbl -0x7feed0fc(,%eax,8),%edx
801077cf:	80 
801077d0:	83 e2 e0             	and    $0xffffffe0,%edx
801077d3:	88 14 c5 04 2f 11 80 	mov    %dl,-0x7feed0fc(,%eax,8)
801077da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077dd:	0f b6 14 c5 04 2f 11 	movzbl -0x7feed0fc(,%eax,8),%edx
801077e4:	80 
801077e5:	83 e2 1f             	and    $0x1f,%edx
801077e8:	88 14 c5 04 2f 11 80 	mov    %dl,-0x7feed0fc(,%eax,8)
801077ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f2:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
801077f9:	80 
801077fa:	83 e2 f0             	and    $0xfffffff0,%edx
801077fd:	83 ca 0e             	or     $0xe,%edx
80107800:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
80107807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780a:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
80107811:	80 
80107812:	83 e2 ef             	and    $0xffffffef,%edx
80107815:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
8010781c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781f:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
80107826:	80 
80107827:	83 e2 9f             	and    $0xffffff9f,%edx
8010782a:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
80107831:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107834:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
8010783b:	80 
8010783c:	83 ca 80             	or     $0xffffff80,%edx
8010783f:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
80107846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107849:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
80107850:	c1 e8 10             	shr    $0x10,%eax
80107853:	89 c2                	mov    %eax,%edx
80107855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107858:	66 89 14 c5 06 2f 11 	mov    %dx,-0x7feed0fa(,%eax,8)
8010785f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107860:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107864:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010786b:	0f 8e 30 ff ff ff    	jle    801077a1 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80107871:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
80107876:	66 a3 00 31 11 80    	mov    %ax,0x80113100
8010787c:	66 c7 05 02 31 11 80 	movw   $0x8,0x80113102
80107883:	08 00 
80107885:	0f b6 05 04 31 11 80 	movzbl 0x80113104,%eax
8010788c:	83 e0 e0             	and    $0xffffffe0,%eax
8010788f:	a2 04 31 11 80       	mov    %al,0x80113104
80107894:	0f b6 05 04 31 11 80 	movzbl 0x80113104,%eax
8010789b:	83 e0 1f             	and    $0x1f,%eax
8010789e:	a2 04 31 11 80       	mov    %al,0x80113104
801078a3:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
801078aa:	83 c8 0f             	or     $0xf,%eax
801078ad:	a2 05 31 11 80       	mov    %al,0x80113105
801078b2:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
801078b9:	83 e0 ef             	and    $0xffffffef,%eax
801078bc:	a2 05 31 11 80       	mov    %al,0x80113105
801078c1:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
801078c8:	83 c8 60             	or     $0x60,%eax
801078cb:	a2 05 31 11 80       	mov    %al,0x80113105
801078d0:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
801078d7:	83 c8 80             	or     $0xffffff80,%eax
801078da:	a2 05 31 11 80       	mov    %al,0x80113105
801078df:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
801078e4:	c1 e8 10             	shr    $0x10,%eax
801078e7:	66 a3 06 31 11 80    	mov    %ax,0x80113106
  
  initlock(&tickslock, "time");
801078ed:	c7 44 24 04 d8 9b 10 	movl   $0x80109bd8,0x4(%esp)
801078f4:	80 
801078f5:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
801078fc:	e8 b9 e5 ff ff       	call   80105eba <initlock>
}
80107901:	c9                   	leave  
80107902:	c3                   	ret    

80107903 <idtinit>:

void
idtinit(void)
{
80107903:	55                   	push   %ebp
80107904:	89 e5                	mov    %esp,%ebp
80107906:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107909:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107910:	00 
80107911:	c7 04 24 00 2f 11 80 	movl   $0x80112f00,(%esp)
80107918:	e8 33 fe ff ff       	call   80107750 <lidt>
}
8010791d:	c9                   	leave  
8010791e:	c3                   	ret    

8010791f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010791f:	55                   	push   %ebp
80107920:	89 e5                	mov    %esp,%ebp
80107922:	57                   	push   %edi
80107923:	56                   	push   %esi
80107924:	53                   	push   %ebx
80107925:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107928:	8b 45 08             	mov    0x8(%ebp),%eax
8010792b:	8b 40 30             	mov    0x30(%eax),%eax
8010792e:	83 f8 40             	cmp    $0x40,%eax
80107931:	75 3e                	jne    80107971 <trap+0x52>
    if(proc->killed)
80107933:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107939:	8b 40 24             	mov    0x24(%eax),%eax
8010793c:	85 c0                	test   %eax,%eax
8010793e:	74 05                	je     80107945 <trap+0x26>
      exit();
80107940:	e8 48 de ff ff       	call   8010578d <exit>
    proc->tf = tf;
80107945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010794b:	8b 55 08             	mov    0x8(%ebp),%edx
8010794e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107951:	e8 01 ec ff ff       	call   80106557 <syscall>
    if(proc->killed)
80107956:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010795c:	8b 40 24             	mov    0x24(%eax),%eax
8010795f:	85 c0                	test   %eax,%eax
80107961:	0f 84 34 02 00 00    	je     80107b9b <trap+0x27c>
      exit();
80107967:	e8 21 de ff ff       	call   8010578d <exit>
    return;
8010796c:	e9 2a 02 00 00       	jmp    80107b9b <trap+0x27c>
  }

  switch(tf->trapno){
80107971:	8b 45 08             	mov    0x8(%ebp),%eax
80107974:	8b 40 30             	mov    0x30(%eax),%eax
80107977:	83 e8 20             	sub    $0x20,%eax
8010797a:	83 f8 1f             	cmp    $0x1f,%eax
8010797d:	0f 87 bc 00 00 00    	ja     80107a3f <trap+0x120>
80107983:	8b 04 85 80 9c 10 80 	mov    -0x7fef6380(,%eax,4),%eax
8010798a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010798c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107992:	0f b6 00             	movzbl (%eax),%eax
80107995:	84 c0                	test   %al,%al
80107997:	75 31                	jne    801079ca <trap+0xab>
      acquire(&tickslock);
80107999:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
801079a0:	e8 36 e5 ff ff       	call   80105edb <acquire>
      ticks++;
801079a5:	a1 00 37 11 80       	mov    0x80113700,%eax
801079aa:	83 c0 01             	add    $0x1,%eax
801079ad:	a3 00 37 11 80       	mov    %eax,0x80113700
      wakeup(&ticks);
801079b2:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
801079b9:	e8 18 e3 ff ff       	call   80105cd6 <wakeup>
      release(&tickslock);
801079be:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
801079c5:	e8 73 e5 ff ff       	call   80105f3d <release>
    }
    lapiceoi();
801079ca:	e8 52 c8 ff ff       	call   80104221 <lapiceoi>
    break;
801079cf:	e9 41 01 00 00       	jmp    80107b15 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801079d4:	e8 50 c0 ff ff       	call   80103a29 <ideintr>
    lapiceoi();
801079d9:	e8 43 c8 ff ff       	call   80104221 <lapiceoi>
    break;
801079de:	e9 32 01 00 00       	jmp    80107b15 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801079e3:	e8 17 c6 ff ff       	call   80103fff <kbdintr>
    lapiceoi();
801079e8:	e8 34 c8 ff ff       	call   80104221 <lapiceoi>
    break;
801079ed:	e9 23 01 00 00       	jmp    80107b15 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801079f2:	e8 a9 03 00 00       	call   80107da0 <uartintr>
    lapiceoi();
801079f7:	e8 25 c8 ff ff       	call   80104221 <lapiceoi>
    break;
801079fc:	e9 14 01 00 00       	jmp    80107b15 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107a01:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a04:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107a07:	8b 45 08             	mov    0x8(%ebp),%eax
80107a0a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a0e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107a11:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a17:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107a1a:	0f b6 c0             	movzbl %al,%eax
80107a1d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107a21:	89 54 24 08          	mov    %edx,0x8(%esp)
80107a25:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a29:	c7 04 24 e0 9b 10 80 	movl   $0x80109be0,(%esp)
80107a30:	e8 6c 89 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107a35:	e8 e7 c7 ff ff       	call   80104221 <lapiceoi>
    break;
80107a3a:	e9 d6 00 00 00       	jmp    80107b15 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107a3f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a45:	85 c0                	test   %eax,%eax
80107a47:	74 11                	je     80107a5a <trap+0x13b>
80107a49:	8b 45 08             	mov    0x8(%ebp),%eax
80107a4c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107a50:	0f b7 c0             	movzwl %ax,%eax
80107a53:	83 e0 03             	and    $0x3,%eax
80107a56:	85 c0                	test   %eax,%eax
80107a58:	75 46                	jne    80107aa0 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a5a:	e8 1a fd ff ff       	call   80107779 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107a5f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a62:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107a65:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107a6c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a6f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107a72:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107a75:	8b 52 30             	mov    0x30(%edx),%edx
80107a78:	89 44 24 10          	mov    %eax,0x10(%esp)
80107a7c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80107a80:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107a84:	89 54 24 04          	mov    %edx,0x4(%esp)
80107a88:	c7 04 24 04 9c 10 80 	movl   $0x80109c04,(%esp)
80107a8f:	e8 0d 89 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107a94:	c7 04 24 36 9c 10 80 	movl   $0x80109c36,(%esp)
80107a9b:	e8 9d 8a ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107aa0:	e8 d4 fc ff ff       	call   80107779 <rcr2>
80107aa5:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107aa7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107aaa:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107aad:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107ab3:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107ab6:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107ab9:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107abc:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107abf:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107ac2:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107ac5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107acb:	83 c0 6c             	add    $0x6c,%eax
80107ace:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107ad1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107ad7:	8b 40 10             	mov    0x10(%eax),%eax
80107ada:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107ade:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107ae2:	89 74 24 14          	mov    %esi,0x14(%esp)
80107ae6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107aea:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107aee:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107af1:	89 54 24 08          	mov    %edx,0x8(%esp)
80107af5:	89 44 24 04          	mov    %eax,0x4(%esp)
80107af9:	c7 04 24 3c 9c 10 80 	movl   $0x80109c3c,(%esp)
80107b00:	e8 9c 88 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107b05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b0b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107b12:	eb 01                	jmp    80107b15 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107b14:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107b15:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b1b:	85 c0                	test   %eax,%eax
80107b1d:	74 24                	je     80107b43 <trap+0x224>
80107b1f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b25:	8b 40 24             	mov    0x24(%eax),%eax
80107b28:	85 c0                	test   %eax,%eax
80107b2a:	74 17                	je     80107b43 <trap+0x224>
80107b2c:	8b 45 08             	mov    0x8(%ebp),%eax
80107b2f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107b33:	0f b7 c0             	movzwl %ax,%eax
80107b36:	83 e0 03             	and    $0x3,%eax
80107b39:	83 f8 03             	cmp    $0x3,%eax
80107b3c:	75 05                	jne    80107b43 <trap+0x224>
    exit();
80107b3e:	e8 4a dc ff ff       	call   8010578d <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107b43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b49:	85 c0                	test   %eax,%eax
80107b4b:	74 1e                	je     80107b6b <trap+0x24c>
80107b4d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b53:	8b 40 0c             	mov    0xc(%eax),%eax
80107b56:	83 f8 04             	cmp    $0x4,%eax
80107b59:	75 10                	jne    80107b6b <trap+0x24c>
80107b5b:	8b 45 08             	mov    0x8(%ebp),%eax
80107b5e:	8b 40 30             	mov    0x30(%eax),%eax
80107b61:	83 f8 20             	cmp    $0x20,%eax
80107b64:	75 05                	jne    80107b6b <trap+0x24c>
    yield();
80107b66:	e8 34 e0 ff ff       	call   80105b9f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107b6b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b71:	85 c0                	test   %eax,%eax
80107b73:	74 27                	je     80107b9c <trap+0x27d>
80107b75:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107b7b:	8b 40 24             	mov    0x24(%eax),%eax
80107b7e:	85 c0                	test   %eax,%eax
80107b80:	74 1a                	je     80107b9c <trap+0x27d>
80107b82:	8b 45 08             	mov    0x8(%ebp),%eax
80107b85:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107b89:	0f b7 c0             	movzwl %ax,%eax
80107b8c:	83 e0 03             	and    $0x3,%eax
80107b8f:	83 f8 03             	cmp    $0x3,%eax
80107b92:	75 08                	jne    80107b9c <trap+0x27d>
    exit();
80107b94:	e8 f4 db ff ff       	call   8010578d <exit>
80107b99:	eb 01                	jmp    80107b9c <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107b9b:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107b9c:	83 c4 3c             	add    $0x3c,%esp
80107b9f:	5b                   	pop    %ebx
80107ba0:	5e                   	pop    %esi
80107ba1:	5f                   	pop    %edi
80107ba2:	5d                   	pop    %ebp
80107ba3:	c3                   	ret    

80107ba4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107ba4:	55                   	push   %ebp
80107ba5:	89 e5                	mov    %esp,%ebp
80107ba7:	53                   	push   %ebx
80107ba8:	83 ec 14             	sub    $0x14,%esp
80107bab:	8b 45 08             	mov    0x8(%ebp),%eax
80107bae:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107bb2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107bb6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107bba:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107bbe:	ec                   	in     (%dx),%al
80107bbf:	89 c3                	mov    %eax,%ebx
80107bc1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107bc4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107bc8:	83 c4 14             	add    $0x14,%esp
80107bcb:	5b                   	pop    %ebx
80107bcc:	5d                   	pop    %ebp
80107bcd:	c3                   	ret    

80107bce <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107bce:	55                   	push   %ebp
80107bcf:	89 e5                	mov    %esp,%ebp
80107bd1:	83 ec 08             	sub    $0x8,%esp
80107bd4:	8b 55 08             	mov    0x8(%ebp),%edx
80107bd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107bda:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107bde:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107be1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107be5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107be9:	ee                   	out    %al,(%dx)
}
80107bea:	c9                   	leave  
80107beb:	c3                   	ret    

80107bec <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107bec:	55                   	push   %ebp
80107bed:	89 e5                	mov    %esp,%ebp
80107bef:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107bf2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107bf9:	00 
80107bfa:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107c01:	e8 c8 ff ff ff       	call   80107bce <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107c06:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107c0d:	00 
80107c0e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107c15:	e8 b4 ff ff ff       	call   80107bce <outb>
  outb(COM1+0, 115200/9600);
80107c1a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107c21:	00 
80107c22:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c29:	e8 a0 ff ff ff       	call   80107bce <outb>
  outb(COM1+1, 0);
80107c2e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c35:	00 
80107c36:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107c3d:	e8 8c ff ff ff       	call   80107bce <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107c42:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107c49:	00 
80107c4a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107c51:	e8 78 ff ff ff       	call   80107bce <outb>
  outb(COM1+4, 0);
80107c56:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c5d:	00 
80107c5e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107c65:	e8 64 ff ff ff       	call   80107bce <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107c6a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107c71:	00 
80107c72:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107c79:	e8 50 ff ff ff       	call   80107bce <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107c7e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107c85:	e8 1a ff ff ff       	call   80107ba4 <inb>
80107c8a:	3c ff                	cmp    $0xff,%al
80107c8c:	74 6c                	je     80107cfa <uartinit+0x10e>
    return;
  uart = 1;
80107c8e:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
80107c95:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107c98:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107c9f:	e8 00 ff ff ff       	call   80107ba4 <inb>
  inb(COM1+0);
80107ca4:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107cab:	e8 f4 fe ff ff       	call   80107ba4 <inb>
  picenable(IRQ_COM1);
80107cb0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107cb7:	e8 3d d1 ff ff       	call   80104df9 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107cbc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cc3:	00 
80107cc4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107ccb:	e8 de bf ff ff       	call   80103cae <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107cd0:	c7 45 f4 00 9d 10 80 	movl   $0x80109d00,-0xc(%ebp)
80107cd7:	eb 15                	jmp    80107cee <uartinit+0x102>
    uartputc(*p);
80107cd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cdc:	0f b6 00             	movzbl (%eax),%eax
80107cdf:	0f be c0             	movsbl %al,%eax
80107ce2:	89 04 24             	mov    %eax,(%esp)
80107ce5:	e8 13 00 00 00       	call   80107cfd <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107cea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107cee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cf1:	0f b6 00             	movzbl (%eax),%eax
80107cf4:	84 c0                	test   %al,%al
80107cf6:	75 e1                	jne    80107cd9 <uartinit+0xed>
80107cf8:	eb 01                	jmp    80107cfb <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107cfa:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107cfb:	c9                   	leave  
80107cfc:	c3                   	ret    

80107cfd <uartputc>:

void
uartputc(int c)
{
80107cfd:	55                   	push   %ebp
80107cfe:	89 e5                	mov    %esp,%ebp
80107d00:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107d03:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107d08:	85 c0                	test   %eax,%eax
80107d0a:	74 4d                	je     80107d59 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d0c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d13:	eb 10                	jmp    80107d25 <uartputc+0x28>
    microdelay(10);
80107d15:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107d1c:	e8 25 c5 ff ff       	call   80104246 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107d21:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107d25:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107d29:	7f 16                	jg     80107d41 <uartputc+0x44>
80107d2b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107d32:	e8 6d fe ff ff       	call   80107ba4 <inb>
80107d37:	0f b6 c0             	movzbl %al,%eax
80107d3a:	83 e0 20             	and    $0x20,%eax
80107d3d:	85 c0                	test   %eax,%eax
80107d3f:	74 d4                	je     80107d15 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107d41:	8b 45 08             	mov    0x8(%ebp),%eax
80107d44:	0f b6 c0             	movzbl %al,%eax
80107d47:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d4b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d52:	e8 77 fe ff ff       	call   80107bce <outb>
80107d57:	eb 01                	jmp    80107d5a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107d59:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107d5a:	c9                   	leave  
80107d5b:	c3                   	ret    

80107d5c <uartgetc>:

static int
uartgetc(void)
{
80107d5c:	55                   	push   %ebp
80107d5d:	89 e5                	mov    %esp,%ebp
80107d5f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107d62:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107d67:	85 c0                	test   %eax,%eax
80107d69:	75 07                	jne    80107d72 <uartgetc+0x16>
    return -1;
80107d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d70:	eb 2c                	jmp    80107d9e <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107d72:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107d79:	e8 26 fe ff ff       	call   80107ba4 <inb>
80107d7e:	0f b6 c0             	movzbl %al,%eax
80107d81:	83 e0 01             	and    $0x1,%eax
80107d84:	85 c0                	test   %eax,%eax
80107d86:	75 07                	jne    80107d8f <uartgetc+0x33>
    return -1;
80107d88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d8d:	eb 0f                	jmp    80107d9e <uartgetc+0x42>
  return inb(COM1+0);
80107d8f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d96:	e8 09 fe ff ff       	call   80107ba4 <inb>
80107d9b:	0f b6 c0             	movzbl %al,%eax
}
80107d9e:	c9                   	leave  
80107d9f:	c3                   	ret    

80107da0 <uartintr>:

void
uartintr(void)
{
80107da0:	55                   	push   %ebp
80107da1:	89 e5                	mov    %esp,%ebp
80107da3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107da6:	c7 04 24 5c 7d 10 80 	movl   $0x80107d5c,(%esp)
80107dad:	e8 fb 89 ff ff       	call   801007ad <consoleintr>
}
80107db2:	c9                   	leave  
80107db3:	c3                   	ret    

80107db4 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107db4:	6a 00                	push   $0x0
  pushl $0
80107db6:	6a 00                	push   $0x0
  jmp alltraps
80107db8:	e9 67 f9 ff ff       	jmp    80107724 <alltraps>

80107dbd <vector1>:
.globl vector1
vector1:
  pushl $0
80107dbd:	6a 00                	push   $0x0
  pushl $1
80107dbf:	6a 01                	push   $0x1
  jmp alltraps
80107dc1:	e9 5e f9 ff ff       	jmp    80107724 <alltraps>

80107dc6 <vector2>:
.globl vector2
vector2:
  pushl $0
80107dc6:	6a 00                	push   $0x0
  pushl $2
80107dc8:	6a 02                	push   $0x2
  jmp alltraps
80107dca:	e9 55 f9 ff ff       	jmp    80107724 <alltraps>

80107dcf <vector3>:
.globl vector3
vector3:
  pushl $0
80107dcf:	6a 00                	push   $0x0
  pushl $3
80107dd1:	6a 03                	push   $0x3
  jmp alltraps
80107dd3:	e9 4c f9 ff ff       	jmp    80107724 <alltraps>

80107dd8 <vector4>:
.globl vector4
vector4:
  pushl $0
80107dd8:	6a 00                	push   $0x0
  pushl $4
80107dda:	6a 04                	push   $0x4
  jmp alltraps
80107ddc:	e9 43 f9 ff ff       	jmp    80107724 <alltraps>

80107de1 <vector5>:
.globl vector5
vector5:
  pushl $0
80107de1:	6a 00                	push   $0x0
  pushl $5
80107de3:	6a 05                	push   $0x5
  jmp alltraps
80107de5:	e9 3a f9 ff ff       	jmp    80107724 <alltraps>

80107dea <vector6>:
.globl vector6
vector6:
  pushl $0
80107dea:	6a 00                	push   $0x0
  pushl $6
80107dec:	6a 06                	push   $0x6
  jmp alltraps
80107dee:	e9 31 f9 ff ff       	jmp    80107724 <alltraps>

80107df3 <vector7>:
.globl vector7
vector7:
  pushl $0
80107df3:	6a 00                	push   $0x0
  pushl $7
80107df5:	6a 07                	push   $0x7
  jmp alltraps
80107df7:	e9 28 f9 ff ff       	jmp    80107724 <alltraps>

80107dfc <vector8>:
.globl vector8
vector8:
  pushl $8
80107dfc:	6a 08                	push   $0x8
  jmp alltraps
80107dfe:	e9 21 f9 ff ff       	jmp    80107724 <alltraps>

80107e03 <vector9>:
.globl vector9
vector9:
  pushl $0
80107e03:	6a 00                	push   $0x0
  pushl $9
80107e05:	6a 09                	push   $0x9
  jmp alltraps
80107e07:	e9 18 f9 ff ff       	jmp    80107724 <alltraps>

80107e0c <vector10>:
.globl vector10
vector10:
  pushl $10
80107e0c:	6a 0a                	push   $0xa
  jmp alltraps
80107e0e:	e9 11 f9 ff ff       	jmp    80107724 <alltraps>

80107e13 <vector11>:
.globl vector11
vector11:
  pushl $11
80107e13:	6a 0b                	push   $0xb
  jmp alltraps
80107e15:	e9 0a f9 ff ff       	jmp    80107724 <alltraps>

80107e1a <vector12>:
.globl vector12
vector12:
  pushl $12
80107e1a:	6a 0c                	push   $0xc
  jmp alltraps
80107e1c:	e9 03 f9 ff ff       	jmp    80107724 <alltraps>

80107e21 <vector13>:
.globl vector13
vector13:
  pushl $13
80107e21:	6a 0d                	push   $0xd
  jmp alltraps
80107e23:	e9 fc f8 ff ff       	jmp    80107724 <alltraps>

80107e28 <vector14>:
.globl vector14
vector14:
  pushl $14
80107e28:	6a 0e                	push   $0xe
  jmp alltraps
80107e2a:	e9 f5 f8 ff ff       	jmp    80107724 <alltraps>

80107e2f <vector15>:
.globl vector15
vector15:
  pushl $0
80107e2f:	6a 00                	push   $0x0
  pushl $15
80107e31:	6a 0f                	push   $0xf
  jmp alltraps
80107e33:	e9 ec f8 ff ff       	jmp    80107724 <alltraps>

80107e38 <vector16>:
.globl vector16
vector16:
  pushl $0
80107e38:	6a 00                	push   $0x0
  pushl $16
80107e3a:	6a 10                	push   $0x10
  jmp alltraps
80107e3c:	e9 e3 f8 ff ff       	jmp    80107724 <alltraps>

80107e41 <vector17>:
.globl vector17
vector17:
  pushl $17
80107e41:	6a 11                	push   $0x11
  jmp alltraps
80107e43:	e9 dc f8 ff ff       	jmp    80107724 <alltraps>

80107e48 <vector18>:
.globl vector18
vector18:
  pushl $0
80107e48:	6a 00                	push   $0x0
  pushl $18
80107e4a:	6a 12                	push   $0x12
  jmp alltraps
80107e4c:	e9 d3 f8 ff ff       	jmp    80107724 <alltraps>

80107e51 <vector19>:
.globl vector19
vector19:
  pushl $0
80107e51:	6a 00                	push   $0x0
  pushl $19
80107e53:	6a 13                	push   $0x13
  jmp alltraps
80107e55:	e9 ca f8 ff ff       	jmp    80107724 <alltraps>

80107e5a <vector20>:
.globl vector20
vector20:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $20
80107e5c:	6a 14                	push   $0x14
  jmp alltraps
80107e5e:	e9 c1 f8 ff ff       	jmp    80107724 <alltraps>

80107e63 <vector21>:
.globl vector21
vector21:
  pushl $0
80107e63:	6a 00                	push   $0x0
  pushl $21
80107e65:	6a 15                	push   $0x15
  jmp alltraps
80107e67:	e9 b8 f8 ff ff       	jmp    80107724 <alltraps>

80107e6c <vector22>:
.globl vector22
vector22:
  pushl $0
80107e6c:	6a 00                	push   $0x0
  pushl $22
80107e6e:	6a 16                	push   $0x16
  jmp alltraps
80107e70:	e9 af f8 ff ff       	jmp    80107724 <alltraps>

80107e75 <vector23>:
.globl vector23
vector23:
  pushl $0
80107e75:	6a 00                	push   $0x0
  pushl $23
80107e77:	6a 17                	push   $0x17
  jmp alltraps
80107e79:	e9 a6 f8 ff ff       	jmp    80107724 <alltraps>

80107e7e <vector24>:
.globl vector24
vector24:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $24
80107e80:	6a 18                	push   $0x18
  jmp alltraps
80107e82:	e9 9d f8 ff ff       	jmp    80107724 <alltraps>

80107e87 <vector25>:
.globl vector25
vector25:
  pushl $0
80107e87:	6a 00                	push   $0x0
  pushl $25
80107e89:	6a 19                	push   $0x19
  jmp alltraps
80107e8b:	e9 94 f8 ff ff       	jmp    80107724 <alltraps>

80107e90 <vector26>:
.globl vector26
vector26:
  pushl $0
80107e90:	6a 00                	push   $0x0
  pushl $26
80107e92:	6a 1a                	push   $0x1a
  jmp alltraps
80107e94:	e9 8b f8 ff ff       	jmp    80107724 <alltraps>

80107e99 <vector27>:
.globl vector27
vector27:
  pushl $0
80107e99:	6a 00                	push   $0x0
  pushl $27
80107e9b:	6a 1b                	push   $0x1b
  jmp alltraps
80107e9d:	e9 82 f8 ff ff       	jmp    80107724 <alltraps>

80107ea2 <vector28>:
.globl vector28
vector28:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $28
80107ea4:	6a 1c                	push   $0x1c
  jmp alltraps
80107ea6:	e9 79 f8 ff ff       	jmp    80107724 <alltraps>

80107eab <vector29>:
.globl vector29
vector29:
  pushl $0
80107eab:	6a 00                	push   $0x0
  pushl $29
80107ead:	6a 1d                	push   $0x1d
  jmp alltraps
80107eaf:	e9 70 f8 ff ff       	jmp    80107724 <alltraps>

80107eb4 <vector30>:
.globl vector30
vector30:
  pushl $0
80107eb4:	6a 00                	push   $0x0
  pushl $30
80107eb6:	6a 1e                	push   $0x1e
  jmp alltraps
80107eb8:	e9 67 f8 ff ff       	jmp    80107724 <alltraps>

80107ebd <vector31>:
.globl vector31
vector31:
  pushl $0
80107ebd:	6a 00                	push   $0x0
  pushl $31
80107ebf:	6a 1f                	push   $0x1f
  jmp alltraps
80107ec1:	e9 5e f8 ff ff       	jmp    80107724 <alltraps>

80107ec6 <vector32>:
.globl vector32
vector32:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $32
80107ec8:	6a 20                	push   $0x20
  jmp alltraps
80107eca:	e9 55 f8 ff ff       	jmp    80107724 <alltraps>

80107ecf <vector33>:
.globl vector33
vector33:
  pushl $0
80107ecf:	6a 00                	push   $0x0
  pushl $33
80107ed1:	6a 21                	push   $0x21
  jmp alltraps
80107ed3:	e9 4c f8 ff ff       	jmp    80107724 <alltraps>

80107ed8 <vector34>:
.globl vector34
vector34:
  pushl $0
80107ed8:	6a 00                	push   $0x0
  pushl $34
80107eda:	6a 22                	push   $0x22
  jmp alltraps
80107edc:	e9 43 f8 ff ff       	jmp    80107724 <alltraps>

80107ee1 <vector35>:
.globl vector35
vector35:
  pushl $0
80107ee1:	6a 00                	push   $0x0
  pushl $35
80107ee3:	6a 23                	push   $0x23
  jmp alltraps
80107ee5:	e9 3a f8 ff ff       	jmp    80107724 <alltraps>

80107eea <vector36>:
.globl vector36
vector36:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $36
80107eec:	6a 24                	push   $0x24
  jmp alltraps
80107eee:	e9 31 f8 ff ff       	jmp    80107724 <alltraps>

80107ef3 <vector37>:
.globl vector37
vector37:
  pushl $0
80107ef3:	6a 00                	push   $0x0
  pushl $37
80107ef5:	6a 25                	push   $0x25
  jmp alltraps
80107ef7:	e9 28 f8 ff ff       	jmp    80107724 <alltraps>

80107efc <vector38>:
.globl vector38
vector38:
  pushl $0
80107efc:	6a 00                	push   $0x0
  pushl $38
80107efe:	6a 26                	push   $0x26
  jmp alltraps
80107f00:	e9 1f f8 ff ff       	jmp    80107724 <alltraps>

80107f05 <vector39>:
.globl vector39
vector39:
  pushl $0
80107f05:	6a 00                	push   $0x0
  pushl $39
80107f07:	6a 27                	push   $0x27
  jmp alltraps
80107f09:	e9 16 f8 ff ff       	jmp    80107724 <alltraps>

80107f0e <vector40>:
.globl vector40
vector40:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $40
80107f10:	6a 28                	push   $0x28
  jmp alltraps
80107f12:	e9 0d f8 ff ff       	jmp    80107724 <alltraps>

80107f17 <vector41>:
.globl vector41
vector41:
  pushl $0
80107f17:	6a 00                	push   $0x0
  pushl $41
80107f19:	6a 29                	push   $0x29
  jmp alltraps
80107f1b:	e9 04 f8 ff ff       	jmp    80107724 <alltraps>

80107f20 <vector42>:
.globl vector42
vector42:
  pushl $0
80107f20:	6a 00                	push   $0x0
  pushl $42
80107f22:	6a 2a                	push   $0x2a
  jmp alltraps
80107f24:	e9 fb f7 ff ff       	jmp    80107724 <alltraps>

80107f29 <vector43>:
.globl vector43
vector43:
  pushl $0
80107f29:	6a 00                	push   $0x0
  pushl $43
80107f2b:	6a 2b                	push   $0x2b
  jmp alltraps
80107f2d:	e9 f2 f7 ff ff       	jmp    80107724 <alltraps>

80107f32 <vector44>:
.globl vector44
vector44:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $44
80107f34:	6a 2c                	push   $0x2c
  jmp alltraps
80107f36:	e9 e9 f7 ff ff       	jmp    80107724 <alltraps>

80107f3b <vector45>:
.globl vector45
vector45:
  pushl $0
80107f3b:	6a 00                	push   $0x0
  pushl $45
80107f3d:	6a 2d                	push   $0x2d
  jmp alltraps
80107f3f:	e9 e0 f7 ff ff       	jmp    80107724 <alltraps>

80107f44 <vector46>:
.globl vector46
vector46:
  pushl $0
80107f44:	6a 00                	push   $0x0
  pushl $46
80107f46:	6a 2e                	push   $0x2e
  jmp alltraps
80107f48:	e9 d7 f7 ff ff       	jmp    80107724 <alltraps>

80107f4d <vector47>:
.globl vector47
vector47:
  pushl $0
80107f4d:	6a 00                	push   $0x0
  pushl $47
80107f4f:	6a 2f                	push   $0x2f
  jmp alltraps
80107f51:	e9 ce f7 ff ff       	jmp    80107724 <alltraps>

80107f56 <vector48>:
.globl vector48
vector48:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $48
80107f58:	6a 30                	push   $0x30
  jmp alltraps
80107f5a:	e9 c5 f7 ff ff       	jmp    80107724 <alltraps>

80107f5f <vector49>:
.globl vector49
vector49:
  pushl $0
80107f5f:	6a 00                	push   $0x0
  pushl $49
80107f61:	6a 31                	push   $0x31
  jmp alltraps
80107f63:	e9 bc f7 ff ff       	jmp    80107724 <alltraps>

80107f68 <vector50>:
.globl vector50
vector50:
  pushl $0
80107f68:	6a 00                	push   $0x0
  pushl $50
80107f6a:	6a 32                	push   $0x32
  jmp alltraps
80107f6c:	e9 b3 f7 ff ff       	jmp    80107724 <alltraps>

80107f71 <vector51>:
.globl vector51
vector51:
  pushl $0
80107f71:	6a 00                	push   $0x0
  pushl $51
80107f73:	6a 33                	push   $0x33
  jmp alltraps
80107f75:	e9 aa f7 ff ff       	jmp    80107724 <alltraps>

80107f7a <vector52>:
.globl vector52
vector52:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $52
80107f7c:	6a 34                	push   $0x34
  jmp alltraps
80107f7e:	e9 a1 f7 ff ff       	jmp    80107724 <alltraps>

80107f83 <vector53>:
.globl vector53
vector53:
  pushl $0
80107f83:	6a 00                	push   $0x0
  pushl $53
80107f85:	6a 35                	push   $0x35
  jmp alltraps
80107f87:	e9 98 f7 ff ff       	jmp    80107724 <alltraps>

80107f8c <vector54>:
.globl vector54
vector54:
  pushl $0
80107f8c:	6a 00                	push   $0x0
  pushl $54
80107f8e:	6a 36                	push   $0x36
  jmp alltraps
80107f90:	e9 8f f7 ff ff       	jmp    80107724 <alltraps>

80107f95 <vector55>:
.globl vector55
vector55:
  pushl $0
80107f95:	6a 00                	push   $0x0
  pushl $55
80107f97:	6a 37                	push   $0x37
  jmp alltraps
80107f99:	e9 86 f7 ff ff       	jmp    80107724 <alltraps>

80107f9e <vector56>:
.globl vector56
vector56:
  pushl $0
80107f9e:	6a 00                	push   $0x0
  pushl $56
80107fa0:	6a 38                	push   $0x38
  jmp alltraps
80107fa2:	e9 7d f7 ff ff       	jmp    80107724 <alltraps>

80107fa7 <vector57>:
.globl vector57
vector57:
  pushl $0
80107fa7:	6a 00                	push   $0x0
  pushl $57
80107fa9:	6a 39                	push   $0x39
  jmp alltraps
80107fab:	e9 74 f7 ff ff       	jmp    80107724 <alltraps>

80107fb0 <vector58>:
.globl vector58
vector58:
  pushl $0
80107fb0:	6a 00                	push   $0x0
  pushl $58
80107fb2:	6a 3a                	push   $0x3a
  jmp alltraps
80107fb4:	e9 6b f7 ff ff       	jmp    80107724 <alltraps>

80107fb9 <vector59>:
.globl vector59
vector59:
  pushl $0
80107fb9:	6a 00                	push   $0x0
  pushl $59
80107fbb:	6a 3b                	push   $0x3b
  jmp alltraps
80107fbd:	e9 62 f7 ff ff       	jmp    80107724 <alltraps>

80107fc2 <vector60>:
.globl vector60
vector60:
  pushl $0
80107fc2:	6a 00                	push   $0x0
  pushl $60
80107fc4:	6a 3c                	push   $0x3c
  jmp alltraps
80107fc6:	e9 59 f7 ff ff       	jmp    80107724 <alltraps>

80107fcb <vector61>:
.globl vector61
vector61:
  pushl $0
80107fcb:	6a 00                	push   $0x0
  pushl $61
80107fcd:	6a 3d                	push   $0x3d
  jmp alltraps
80107fcf:	e9 50 f7 ff ff       	jmp    80107724 <alltraps>

80107fd4 <vector62>:
.globl vector62
vector62:
  pushl $0
80107fd4:	6a 00                	push   $0x0
  pushl $62
80107fd6:	6a 3e                	push   $0x3e
  jmp alltraps
80107fd8:	e9 47 f7 ff ff       	jmp    80107724 <alltraps>

80107fdd <vector63>:
.globl vector63
vector63:
  pushl $0
80107fdd:	6a 00                	push   $0x0
  pushl $63
80107fdf:	6a 3f                	push   $0x3f
  jmp alltraps
80107fe1:	e9 3e f7 ff ff       	jmp    80107724 <alltraps>

80107fe6 <vector64>:
.globl vector64
vector64:
  pushl $0
80107fe6:	6a 00                	push   $0x0
  pushl $64
80107fe8:	6a 40                	push   $0x40
  jmp alltraps
80107fea:	e9 35 f7 ff ff       	jmp    80107724 <alltraps>

80107fef <vector65>:
.globl vector65
vector65:
  pushl $0
80107fef:	6a 00                	push   $0x0
  pushl $65
80107ff1:	6a 41                	push   $0x41
  jmp alltraps
80107ff3:	e9 2c f7 ff ff       	jmp    80107724 <alltraps>

80107ff8 <vector66>:
.globl vector66
vector66:
  pushl $0
80107ff8:	6a 00                	push   $0x0
  pushl $66
80107ffa:	6a 42                	push   $0x42
  jmp alltraps
80107ffc:	e9 23 f7 ff ff       	jmp    80107724 <alltraps>

80108001 <vector67>:
.globl vector67
vector67:
  pushl $0
80108001:	6a 00                	push   $0x0
  pushl $67
80108003:	6a 43                	push   $0x43
  jmp alltraps
80108005:	e9 1a f7 ff ff       	jmp    80107724 <alltraps>

8010800a <vector68>:
.globl vector68
vector68:
  pushl $0
8010800a:	6a 00                	push   $0x0
  pushl $68
8010800c:	6a 44                	push   $0x44
  jmp alltraps
8010800e:	e9 11 f7 ff ff       	jmp    80107724 <alltraps>

80108013 <vector69>:
.globl vector69
vector69:
  pushl $0
80108013:	6a 00                	push   $0x0
  pushl $69
80108015:	6a 45                	push   $0x45
  jmp alltraps
80108017:	e9 08 f7 ff ff       	jmp    80107724 <alltraps>

8010801c <vector70>:
.globl vector70
vector70:
  pushl $0
8010801c:	6a 00                	push   $0x0
  pushl $70
8010801e:	6a 46                	push   $0x46
  jmp alltraps
80108020:	e9 ff f6 ff ff       	jmp    80107724 <alltraps>

80108025 <vector71>:
.globl vector71
vector71:
  pushl $0
80108025:	6a 00                	push   $0x0
  pushl $71
80108027:	6a 47                	push   $0x47
  jmp alltraps
80108029:	e9 f6 f6 ff ff       	jmp    80107724 <alltraps>

8010802e <vector72>:
.globl vector72
vector72:
  pushl $0
8010802e:	6a 00                	push   $0x0
  pushl $72
80108030:	6a 48                	push   $0x48
  jmp alltraps
80108032:	e9 ed f6 ff ff       	jmp    80107724 <alltraps>

80108037 <vector73>:
.globl vector73
vector73:
  pushl $0
80108037:	6a 00                	push   $0x0
  pushl $73
80108039:	6a 49                	push   $0x49
  jmp alltraps
8010803b:	e9 e4 f6 ff ff       	jmp    80107724 <alltraps>

80108040 <vector74>:
.globl vector74
vector74:
  pushl $0
80108040:	6a 00                	push   $0x0
  pushl $74
80108042:	6a 4a                	push   $0x4a
  jmp alltraps
80108044:	e9 db f6 ff ff       	jmp    80107724 <alltraps>

80108049 <vector75>:
.globl vector75
vector75:
  pushl $0
80108049:	6a 00                	push   $0x0
  pushl $75
8010804b:	6a 4b                	push   $0x4b
  jmp alltraps
8010804d:	e9 d2 f6 ff ff       	jmp    80107724 <alltraps>

80108052 <vector76>:
.globl vector76
vector76:
  pushl $0
80108052:	6a 00                	push   $0x0
  pushl $76
80108054:	6a 4c                	push   $0x4c
  jmp alltraps
80108056:	e9 c9 f6 ff ff       	jmp    80107724 <alltraps>

8010805b <vector77>:
.globl vector77
vector77:
  pushl $0
8010805b:	6a 00                	push   $0x0
  pushl $77
8010805d:	6a 4d                	push   $0x4d
  jmp alltraps
8010805f:	e9 c0 f6 ff ff       	jmp    80107724 <alltraps>

80108064 <vector78>:
.globl vector78
vector78:
  pushl $0
80108064:	6a 00                	push   $0x0
  pushl $78
80108066:	6a 4e                	push   $0x4e
  jmp alltraps
80108068:	e9 b7 f6 ff ff       	jmp    80107724 <alltraps>

8010806d <vector79>:
.globl vector79
vector79:
  pushl $0
8010806d:	6a 00                	push   $0x0
  pushl $79
8010806f:	6a 4f                	push   $0x4f
  jmp alltraps
80108071:	e9 ae f6 ff ff       	jmp    80107724 <alltraps>

80108076 <vector80>:
.globl vector80
vector80:
  pushl $0
80108076:	6a 00                	push   $0x0
  pushl $80
80108078:	6a 50                	push   $0x50
  jmp alltraps
8010807a:	e9 a5 f6 ff ff       	jmp    80107724 <alltraps>

8010807f <vector81>:
.globl vector81
vector81:
  pushl $0
8010807f:	6a 00                	push   $0x0
  pushl $81
80108081:	6a 51                	push   $0x51
  jmp alltraps
80108083:	e9 9c f6 ff ff       	jmp    80107724 <alltraps>

80108088 <vector82>:
.globl vector82
vector82:
  pushl $0
80108088:	6a 00                	push   $0x0
  pushl $82
8010808a:	6a 52                	push   $0x52
  jmp alltraps
8010808c:	e9 93 f6 ff ff       	jmp    80107724 <alltraps>

80108091 <vector83>:
.globl vector83
vector83:
  pushl $0
80108091:	6a 00                	push   $0x0
  pushl $83
80108093:	6a 53                	push   $0x53
  jmp alltraps
80108095:	e9 8a f6 ff ff       	jmp    80107724 <alltraps>

8010809a <vector84>:
.globl vector84
vector84:
  pushl $0
8010809a:	6a 00                	push   $0x0
  pushl $84
8010809c:	6a 54                	push   $0x54
  jmp alltraps
8010809e:	e9 81 f6 ff ff       	jmp    80107724 <alltraps>

801080a3 <vector85>:
.globl vector85
vector85:
  pushl $0
801080a3:	6a 00                	push   $0x0
  pushl $85
801080a5:	6a 55                	push   $0x55
  jmp alltraps
801080a7:	e9 78 f6 ff ff       	jmp    80107724 <alltraps>

801080ac <vector86>:
.globl vector86
vector86:
  pushl $0
801080ac:	6a 00                	push   $0x0
  pushl $86
801080ae:	6a 56                	push   $0x56
  jmp alltraps
801080b0:	e9 6f f6 ff ff       	jmp    80107724 <alltraps>

801080b5 <vector87>:
.globl vector87
vector87:
  pushl $0
801080b5:	6a 00                	push   $0x0
  pushl $87
801080b7:	6a 57                	push   $0x57
  jmp alltraps
801080b9:	e9 66 f6 ff ff       	jmp    80107724 <alltraps>

801080be <vector88>:
.globl vector88
vector88:
  pushl $0
801080be:	6a 00                	push   $0x0
  pushl $88
801080c0:	6a 58                	push   $0x58
  jmp alltraps
801080c2:	e9 5d f6 ff ff       	jmp    80107724 <alltraps>

801080c7 <vector89>:
.globl vector89
vector89:
  pushl $0
801080c7:	6a 00                	push   $0x0
  pushl $89
801080c9:	6a 59                	push   $0x59
  jmp alltraps
801080cb:	e9 54 f6 ff ff       	jmp    80107724 <alltraps>

801080d0 <vector90>:
.globl vector90
vector90:
  pushl $0
801080d0:	6a 00                	push   $0x0
  pushl $90
801080d2:	6a 5a                	push   $0x5a
  jmp alltraps
801080d4:	e9 4b f6 ff ff       	jmp    80107724 <alltraps>

801080d9 <vector91>:
.globl vector91
vector91:
  pushl $0
801080d9:	6a 00                	push   $0x0
  pushl $91
801080db:	6a 5b                	push   $0x5b
  jmp alltraps
801080dd:	e9 42 f6 ff ff       	jmp    80107724 <alltraps>

801080e2 <vector92>:
.globl vector92
vector92:
  pushl $0
801080e2:	6a 00                	push   $0x0
  pushl $92
801080e4:	6a 5c                	push   $0x5c
  jmp alltraps
801080e6:	e9 39 f6 ff ff       	jmp    80107724 <alltraps>

801080eb <vector93>:
.globl vector93
vector93:
  pushl $0
801080eb:	6a 00                	push   $0x0
  pushl $93
801080ed:	6a 5d                	push   $0x5d
  jmp alltraps
801080ef:	e9 30 f6 ff ff       	jmp    80107724 <alltraps>

801080f4 <vector94>:
.globl vector94
vector94:
  pushl $0
801080f4:	6a 00                	push   $0x0
  pushl $94
801080f6:	6a 5e                	push   $0x5e
  jmp alltraps
801080f8:	e9 27 f6 ff ff       	jmp    80107724 <alltraps>

801080fd <vector95>:
.globl vector95
vector95:
  pushl $0
801080fd:	6a 00                	push   $0x0
  pushl $95
801080ff:	6a 5f                	push   $0x5f
  jmp alltraps
80108101:	e9 1e f6 ff ff       	jmp    80107724 <alltraps>

80108106 <vector96>:
.globl vector96
vector96:
  pushl $0
80108106:	6a 00                	push   $0x0
  pushl $96
80108108:	6a 60                	push   $0x60
  jmp alltraps
8010810a:	e9 15 f6 ff ff       	jmp    80107724 <alltraps>

8010810f <vector97>:
.globl vector97
vector97:
  pushl $0
8010810f:	6a 00                	push   $0x0
  pushl $97
80108111:	6a 61                	push   $0x61
  jmp alltraps
80108113:	e9 0c f6 ff ff       	jmp    80107724 <alltraps>

80108118 <vector98>:
.globl vector98
vector98:
  pushl $0
80108118:	6a 00                	push   $0x0
  pushl $98
8010811a:	6a 62                	push   $0x62
  jmp alltraps
8010811c:	e9 03 f6 ff ff       	jmp    80107724 <alltraps>

80108121 <vector99>:
.globl vector99
vector99:
  pushl $0
80108121:	6a 00                	push   $0x0
  pushl $99
80108123:	6a 63                	push   $0x63
  jmp alltraps
80108125:	e9 fa f5 ff ff       	jmp    80107724 <alltraps>

8010812a <vector100>:
.globl vector100
vector100:
  pushl $0
8010812a:	6a 00                	push   $0x0
  pushl $100
8010812c:	6a 64                	push   $0x64
  jmp alltraps
8010812e:	e9 f1 f5 ff ff       	jmp    80107724 <alltraps>

80108133 <vector101>:
.globl vector101
vector101:
  pushl $0
80108133:	6a 00                	push   $0x0
  pushl $101
80108135:	6a 65                	push   $0x65
  jmp alltraps
80108137:	e9 e8 f5 ff ff       	jmp    80107724 <alltraps>

8010813c <vector102>:
.globl vector102
vector102:
  pushl $0
8010813c:	6a 00                	push   $0x0
  pushl $102
8010813e:	6a 66                	push   $0x66
  jmp alltraps
80108140:	e9 df f5 ff ff       	jmp    80107724 <alltraps>

80108145 <vector103>:
.globl vector103
vector103:
  pushl $0
80108145:	6a 00                	push   $0x0
  pushl $103
80108147:	6a 67                	push   $0x67
  jmp alltraps
80108149:	e9 d6 f5 ff ff       	jmp    80107724 <alltraps>

8010814e <vector104>:
.globl vector104
vector104:
  pushl $0
8010814e:	6a 00                	push   $0x0
  pushl $104
80108150:	6a 68                	push   $0x68
  jmp alltraps
80108152:	e9 cd f5 ff ff       	jmp    80107724 <alltraps>

80108157 <vector105>:
.globl vector105
vector105:
  pushl $0
80108157:	6a 00                	push   $0x0
  pushl $105
80108159:	6a 69                	push   $0x69
  jmp alltraps
8010815b:	e9 c4 f5 ff ff       	jmp    80107724 <alltraps>

80108160 <vector106>:
.globl vector106
vector106:
  pushl $0
80108160:	6a 00                	push   $0x0
  pushl $106
80108162:	6a 6a                	push   $0x6a
  jmp alltraps
80108164:	e9 bb f5 ff ff       	jmp    80107724 <alltraps>

80108169 <vector107>:
.globl vector107
vector107:
  pushl $0
80108169:	6a 00                	push   $0x0
  pushl $107
8010816b:	6a 6b                	push   $0x6b
  jmp alltraps
8010816d:	e9 b2 f5 ff ff       	jmp    80107724 <alltraps>

80108172 <vector108>:
.globl vector108
vector108:
  pushl $0
80108172:	6a 00                	push   $0x0
  pushl $108
80108174:	6a 6c                	push   $0x6c
  jmp alltraps
80108176:	e9 a9 f5 ff ff       	jmp    80107724 <alltraps>

8010817b <vector109>:
.globl vector109
vector109:
  pushl $0
8010817b:	6a 00                	push   $0x0
  pushl $109
8010817d:	6a 6d                	push   $0x6d
  jmp alltraps
8010817f:	e9 a0 f5 ff ff       	jmp    80107724 <alltraps>

80108184 <vector110>:
.globl vector110
vector110:
  pushl $0
80108184:	6a 00                	push   $0x0
  pushl $110
80108186:	6a 6e                	push   $0x6e
  jmp alltraps
80108188:	e9 97 f5 ff ff       	jmp    80107724 <alltraps>

8010818d <vector111>:
.globl vector111
vector111:
  pushl $0
8010818d:	6a 00                	push   $0x0
  pushl $111
8010818f:	6a 6f                	push   $0x6f
  jmp alltraps
80108191:	e9 8e f5 ff ff       	jmp    80107724 <alltraps>

80108196 <vector112>:
.globl vector112
vector112:
  pushl $0
80108196:	6a 00                	push   $0x0
  pushl $112
80108198:	6a 70                	push   $0x70
  jmp alltraps
8010819a:	e9 85 f5 ff ff       	jmp    80107724 <alltraps>

8010819f <vector113>:
.globl vector113
vector113:
  pushl $0
8010819f:	6a 00                	push   $0x0
  pushl $113
801081a1:	6a 71                	push   $0x71
  jmp alltraps
801081a3:	e9 7c f5 ff ff       	jmp    80107724 <alltraps>

801081a8 <vector114>:
.globl vector114
vector114:
  pushl $0
801081a8:	6a 00                	push   $0x0
  pushl $114
801081aa:	6a 72                	push   $0x72
  jmp alltraps
801081ac:	e9 73 f5 ff ff       	jmp    80107724 <alltraps>

801081b1 <vector115>:
.globl vector115
vector115:
  pushl $0
801081b1:	6a 00                	push   $0x0
  pushl $115
801081b3:	6a 73                	push   $0x73
  jmp alltraps
801081b5:	e9 6a f5 ff ff       	jmp    80107724 <alltraps>

801081ba <vector116>:
.globl vector116
vector116:
  pushl $0
801081ba:	6a 00                	push   $0x0
  pushl $116
801081bc:	6a 74                	push   $0x74
  jmp alltraps
801081be:	e9 61 f5 ff ff       	jmp    80107724 <alltraps>

801081c3 <vector117>:
.globl vector117
vector117:
  pushl $0
801081c3:	6a 00                	push   $0x0
  pushl $117
801081c5:	6a 75                	push   $0x75
  jmp alltraps
801081c7:	e9 58 f5 ff ff       	jmp    80107724 <alltraps>

801081cc <vector118>:
.globl vector118
vector118:
  pushl $0
801081cc:	6a 00                	push   $0x0
  pushl $118
801081ce:	6a 76                	push   $0x76
  jmp alltraps
801081d0:	e9 4f f5 ff ff       	jmp    80107724 <alltraps>

801081d5 <vector119>:
.globl vector119
vector119:
  pushl $0
801081d5:	6a 00                	push   $0x0
  pushl $119
801081d7:	6a 77                	push   $0x77
  jmp alltraps
801081d9:	e9 46 f5 ff ff       	jmp    80107724 <alltraps>

801081de <vector120>:
.globl vector120
vector120:
  pushl $0
801081de:	6a 00                	push   $0x0
  pushl $120
801081e0:	6a 78                	push   $0x78
  jmp alltraps
801081e2:	e9 3d f5 ff ff       	jmp    80107724 <alltraps>

801081e7 <vector121>:
.globl vector121
vector121:
  pushl $0
801081e7:	6a 00                	push   $0x0
  pushl $121
801081e9:	6a 79                	push   $0x79
  jmp alltraps
801081eb:	e9 34 f5 ff ff       	jmp    80107724 <alltraps>

801081f0 <vector122>:
.globl vector122
vector122:
  pushl $0
801081f0:	6a 00                	push   $0x0
  pushl $122
801081f2:	6a 7a                	push   $0x7a
  jmp alltraps
801081f4:	e9 2b f5 ff ff       	jmp    80107724 <alltraps>

801081f9 <vector123>:
.globl vector123
vector123:
  pushl $0
801081f9:	6a 00                	push   $0x0
  pushl $123
801081fb:	6a 7b                	push   $0x7b
  jmp alltraps
801081fd:	e9 22 f5 ff ff       	jmp    80107724 <alltraps>

80108202 <vector124>:
.globl vector124
vector124:
  pushl $0
80108202:	6a 00                	push   $0x0
  pushl $124
80108204:	6a 7c                	push   $0x7c
  jmp alltraps
80108206:	e9 19 f5 ff ff       	jmp    80107724 <alltraps>

8010820b <vector125>:
.globl vector125
vector125:
  pushl $0
8010820b:	6a 00                	push   $0x0
  pushl $125
8010820d:	6a 7d                	push   $0x7d
  jmp alltraps
8010820f:	e9 10 f5 ff ff       	jmp    80107724 <alltraps>

80108214 <vector126>:
.globl vector126
vector126:
  pushl $0
80108214:	6a 00                	push   $0x0
  pushl $126
80108216:	6a 7e                	push   $0x7e
  jmp alltraps
80108218:	e9 07 f5 ff ff       	jmp    80107724 <alltraps>

8010821d <vector127>:
.globl vector127
vector127:
  pushl $0
8010821d:	6a 00                	push   $0x0
  pushl $127
8010821f:	6a 7f                	push   $0x7f
  jmp alltraps
80108221:	e9 fe f4 ff ff       	jmp    80107724 <alltraps>

80108226 <vector128>:
.globl vector128
vector128:
  pushl $0
80108226:	6a 00                	push   $0x0
  pushl $128
80108228:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010822d:	e9 f2 f4 ff ff       	jmp    80107724 <alltraps>

80108232 <vector129>:
.globl vector129
vector129:
  pushl $0
80108232:	6a 00                	push   $0x0
  pushl $129
80108234:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80108239:	e9 e6 f4 ff ff       	jmp    80107724 <alltraps>

8010823e <vector130>:
.globl vector130
vector130:
  pushl $0
8010823e:	6a 00                	push   $0x0
  pushl $130
80108240:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80108245:	e9 da f4 ff ff       	jmp    80107724 <alltraps>

8010824a <vector131>:
.globl vector131
vector131:
  pushl $0
8010824a:	6a 00                	push   $0x0
  pushl $131
8010824c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80108251:	e9 ce f4 ff ff       	jmp    80107724 <alltraps>

80108256 <vector132>:
.globl vector132
vector132:
  pushl $0
80108256:	6a 00                	push   $0x0
  pushl $132
80108258:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010825d:	e9 c2 f4 ff ff       	jmp    80107724 <alltraps>

80108262 <vector133>:
.globl vector133
vector133:
  pushl $0
80108262:	6a 00                	push   $0x0
  pushl $133
80108264:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80108269:	e9 b6 f4 ff ff       	jmp    80107724 <alltraps>

8010826e <vector134>:
.globl vector134
vector134:
  pushl $0
8010826e:	6a 00                	push   $0x0
  pushl $134
80108270:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80108275:	e9 aa f4 ff ff       	jmp    80107724 <alltraps>

8010827a <vector135>:
.globl vector135
vector135:
  pushl $0
8010827a:	6a 00                	push   $0x0
  pushl $135
8010827c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80108281:	e9 9e f4 ff ff       	jmp    80107724 <alltraps>

80108286 <vector136>:
.globl vector136
vector136:
  pushl $0
80108286:	6a 00                	push   $0x0
  pushl $136
80108288:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010828d:	e9 92 f4 ff ff       	jmp    80107724 <alltraps>

80108292 <vector137>:
.globl vector137
vector137:
  pushl $0
80108292:	6a 00                	push   $0x0
  pushl $137
80108294:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80108299:	e9 86 f4 ff ff       	jmp    80107724 <alltraps>

8010829e <vector138>:
.globl vector138
vector138:
  pushl $0
8010829e:	6a 00                	push   $0x0
  pushl $138
801082a0:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801082a5:	e9 7a f4 ff ff       	jmp    80107724 <alltraps>

801082aa <vector139>:
.globl vector139
vector139:
  pushl $0
801082aa:	6a 00                	push   $0x0
  pushl $139
801082ac:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801082b1:	e9 6e f4 ff ff       	jmp    80107724 <alltraps>

801082b6 <vector140>:
.globl vector140
vector140:
  pushl $0
801082b6:	6a 00                	push   $0x0
  pushl $140
801082b8:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801082bd:	e9 62 f4 ff ff       	jmp    80107724 <alltraps>

801082c2 <vector141>:
.globl vector141
vector141:
  pushl $0
801082c2:	6a 00                	push   $0x0
  pushl $141
801082c4:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801082c9:	e9 56 f4 ff ff       	jmp    80107724 <alltraps>

801082ce <vector142>:
.globl vector142
vector142:
  pushl $0
801082ce:	6a 00                	push   $0x0
  pushl $142
801082d0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801082d5:	e9 4a f4 ff ff       	jmp    80107724 <alltraps>

801082da <vector143>:
.globl vector143
vector143:
  pushl $0
801082da:	6a 00                	push   $0x0
  pushl $143
801082dc:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801082e1:	e9 3e f4 ff ff       	jmp    80107724 <alltraps>

801082e6 <vector144>:
.globl vector144
vector144:
  pushl $0
801082e6:	6a 00                	push   $0x0
  pushl $144
801082e8:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801082ed:	e9 32 f4 ff ff       	jmp    80107724 <alltraps>

801082f2 <vector145>:
.globl vector145
vector145:
  pushl $0
801082f2:	6a 00                	push   $0x0
  pushl $145
801082f4:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801082f9:	e9 26 f4 ff ff       	jmp    80107724 <alltraps>

801082fe <vector146>:
.globl vector146
vector146:
  pushl $0
801082fe:	6a 00                	push   $0x0
  pushl $146
80108300:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108305:	e9 1a f4 ff ff       	jmp    80107724 <alltraps>

8010830a <vector147>:
.globl vector147
vector147:
  pushl $0
8010830a:	6a 00                	push   $0x0
  pushl $147
8010830c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80108311:	e9 0e f4 ff ff       	jmp    80107724 <alltraps>

80108316 <vector148>:
.globl vector148
vector148:
  pushl $0
80108316:	6a 00                	push   $0x0
  pushl $148
80108318:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010831d:	e9 02 f4 ff ff       	jmp    80107724 <alltraps>

80108322 <vector149>:
.globl vector149
vector149:
  pushl $0
80108322:	6a 00                	push   $0x0
  pushl $149
80108324:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108329:	e9 f6 f3 ff ff       	jmp    80107724 <alltraps>

8010832e <vector150>:
.globl vector150
vector150:
  pushl $0
8010832e:	6a 00                	push   $0x0
  pushl $150
80108330:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80108335:	e9 ea f3 ff ff       	jmp    80107724 <alltraps>

8010833a <vector151>:
.globl vector151
vector151:
  pushl $0
8010833a:	6a 00                	push   $0x0
  pushl $151
8010833c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80108341:	e9 de f3 ff ff       	jmp    80107724 <alltraps>

80108346 <vector152>:
.globl vector152
vector152:
  pushl $0
80108346:	6a 00                	push   $0x0
  pushl $152
80108348:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010834d:	e9 d2 f3 ff ff       	jmp    80107724 <alltraps>

80108352 <vector153>:
.globl vector153
vector153:
  pushl $0
80108352:	6a 00                	push   $0x0
  pushl $153
80108354:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80108359:	e9 c6 f3 ff ff       	jmp    80107724 <alltraps>

8010835e <vector154>:
.globl vector154
vector154:
  pushl $0
8010835e:	6a 00                	push   $0x0
  pushl $154
80108360:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80108365:	e9 ba f3 ff ff       	jmp    80107724 <alltraps>

8010836a <vector155>:
.globl vector155
vector155:
  pushl $0
8010836a:	6a 00                	push   $0x0
  pushl $155
8010836c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80108371:	e9 ae f3 ff ff       	jmp    80107724 <alltraps>

80108376 <vector156>:
.globl vector156
vector156:
  pushl $0
80108376:	6a 00                	push   $0x0
  pushl $156
80108378:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010837d:	e9 a2 f3 ff ff       	jmp    80107724 <alltraps>

80108382 <vector157>:
.globl vector157
vector157:
  pushl $0
80108382:	6a 00                	push   $0x0
  pushl $157
80108384:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80108389:	e9 96 f3 ff ff       	jmp    80107724 <alltraps>

8010838e <vector158>:
.globl vector158
vector158:
  pushl $0
8010838e:	6a 00                	push   $0x0
  pushl $158
80108390:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80108395:	e9 8a f3 ff ff       	jmp    80107724 <alltraps>

8010839a <vector159>:
.globl vector159
vector159:
  pushl $0
8010839a:	6a 00                	push   $0x0
  pushl $159
8010839c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801083a1:	e9 7e f3 ff ff       	jmp    80107724 <alltraps>

801083a6 <vector160>:
.globl vector160
vector160:
  pushl $0
801083a6:	6a 00                	push   $0x0
  pushl $160
801083a8:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801083ad:	e9 72 f3 ff ff       	jmp    80107724 <alltraps>

801083b2 <vector161>:
.globl vector161
vector161:
  pushl $0
801083b2:	6a 00                	push   $0x0
  pushl $161
801083b4:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801083b9:	e9 66 f3 ff ff       	jmp    80107724 <alltraps>

801083be <vector162>:
.globl vector162
vector162:
  pushl $0
801083be:	6a 00                	push   $0x0
  pushl $162
801083c0:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801083c5:	e9 5a f3 ff ff       	jmp    80107724 <alltraps>

801083ca <vector163>:
.globl vector163
vector163:
  pushl $0
801083ca:	6a 00                	push   $0x0
  pushl $163
801083cc:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801083d1:	e9 4e f3 ff ff       	jmp    80107724 <alltraps>

801083d6 <vector164>:
.globl vector164
vector164:
  pushl $0
801083d6:	6a 00                	push   $0x0
  pushl $164
801083d8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801083dd:	e9 42 f3 ff ff       	jmp    80107724 <alltraps>

801083e2 <vector165>:
.globl vector165
vector165:
  pushl $0
801083e2:	6a 00                	push   $0x0
  pushl $165
801083e4:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801083e9:	e9 36 f3 ff ff       	jmp    80107724 <alltraps>

801083ee <vector166>:
.globl vector166
vector166:
  pushl $0
801083ee:	6a 00                	push   $0x0
  pushl $166
801083f0:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801083f5:	e9 2a f3 ff ff       	jmp    80107724 <alltraps>

801083fa <vector167>:
.globl vector167
vector167:
  pushl $0
801083fa:	6a 00                	push   $0x0
  pushl $167
801083fc:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80108401:	e9 1e f3 ff ff       	jmp    80107724 <alltraps>

80108406 <vector168>:
.globl vector168
vector168:
  pushl $0
80108406:	6a 00                	push   $0x0
  pushl $168
80108408:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010840d:	e9 12 f3 ff ff       	jmp    80107724 <alltraps>

80108412 <vector169>:
.globl vector169
vector169:
  pushl $0
80108412:	6a 00                	push   $0x0
  pushl $169
80108414:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108419:	e9 06 f3 ff ff       	jmp    80107724 <alltraps>

8010841e <vector170>:
.globl vector170
vector170:
  pushl $0
8010841e:	6a 00                	push   $0x0
  pushl $170
80108420:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108425:	e9 fa f2 ff ff       	jmp    80107724 <alltraps>

8010842a <vector171>:
.globl vector171
vector171:
  pushl $0
8010842a:	6a 00                	push   $0x0
  pushl $171
8010842c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80108431:	e9 ee f2 ff ff       	jmp    80107724 <alltraps>

80108436 <vector172>:
.globl vector172
vector172:
  pushl $0
80108436:	6a 00                	push   $0x0
  pushl $172
80108438:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010843d:	e9 e2 f2 ff ff       	jmp    80107724 <alltraps>

80108442 <vector173>:
.globl vector173
vector173:
  pushl $0
80108442:	6a 00                	push   $0x0
  pushl $173
80108444:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80108449:	e9 d6 f2 ff ff       	jmp    80107724 <alltraps>

8010844e <vector174>:
.globl vector174
vector174:
  pushl $0
8010844e:	6a 00                	push   $0x0
  pushl $174
80108450:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80108455:	e9 ca f2 ff ff       	jmp    80107724 <alltraps>

8010845a <vector175>:
.globl vector175
vector175:
  pushl $0
8010845a:	6a 00                	push   $0x0
  pushl $175
8010845c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80108461:	e9 be f2 ff ff       	jmp    80107724 <alltraps>

80108466 <vector176>:
.globl vector176
vector176:
  pushl $0
80108466:	6a 00                	push   $0x0
  pushl $176
80108468:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010846d:	e9 b2 f2 ff ff       	jmp    80107724 <alltraps>

80108472 <vector177>:
.globl vector177
vector177:
  pushl $0
80108472:	6a 00                	push   $0x0
  pushl $177
80108474:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80108479:	e9 a6 f2 ff ff       	jmp    80107724 <alltraps>

8010847e <vector178>:
.globl vector178
vector178:
  pushl $0
8010847e:	6a 00                	push   $0x0
  pushl $178
80108480:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80108485:	e9 9a f2 ff ff       	jmp    80107724 <alltraps>

8010848a <vector179>:
.globl vector179
vector179:
  pushl $0
8010848a:	6a 00                	push   $0x0
  pushl $179
8010848c:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80108491:	e9 8e f2 ff ff       	jmp    80107724 <alltraps>

80108496 <vector180>:
.globl vector180
vector180:
  pushl $0
80108496:	6a 00                	push   $0x0
  pushl $180
80108498:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010849d:	e9 82 f2 ff ff       	jmp    80107724 <alltraps>

801084a2 <vector181>:
.globl vector181
vector181:
  pushl $0
801084a2:	6a 00                	push   $0x0
  pushl $181
801084a4:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801084a9:	e9 76 f2 ff ff       	jmp    80107724 <alltraps>

801084ae <vector182>:
.globl vector182
vector182:
  pushl $0
801084ae:	6a 00                	push   $0x0
  pushl $182
801084b0:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801084b5:	e9 6a f2 ff ff       	jmp    80107724 <alltraps>

801084ba <vector183>:
.globl vector183
vector183:
  pushl $0
801084ba:	6a 00                	push   $0x0
  pushl $183
801084bc:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801084c1:	e9 5e f2 ff ff       	jmp    80107724 <alltraps>

801084c6 <vector184>:
.globl vector184
vector184:
  pushl $0
801084c6:	6a 00                	push   $0x0
  pushl $184
801084c8:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801084cd:	e9 52 f2 ff ff       	jmp    80107724 <alltraps>

801084d2 <vector185>:
.globl vector185
vector185:
  pushl $0
801084d2:	6a 00                	push   $0x0
  pushl $185
801084d4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801084d9:	e9 46 f2 ff ff       	jmp    80107724 <alltraps>

801084de <vector186>:
.globl vector186
vector186:
  pushl $0
801084de:	6a 00                	push   $0x0
  pushl $186
801084e0:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801084e5:	e9 3a f2 ff ff       	jmp    80107724 <alltraps>

801084ea <vector187>:
.globl vector187
vector187:
  pushl $0
801084ea:	6a 00                	push   $0x0
  pushl $187
801084ec:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801084f1:	e9 2e f2 ff ff       	jmp    80107724 <alltraps>

801084f6 <vector188>:
.globl vector188
vector188:
  pushl $0
801084f6:	6a 00                	push   $0x0
  pushl $188
801084f8:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801084fd:	e9 22 f2 ff ff       	jmp    80107724 <alltraps>

80108502 <vector189>:
.globl vector189
vector189:
  pushl $0
80108502:	6a 00                	push   $0x0
  pushl $189
80108504:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108509:	e9 16 f2 ff ff       	jmp    80107724 <alltraps>

8010850e <vector190>:
.globl vector190
vector190:
  pushl $0
8010850e:	6a 00                	push   $0x0
  pushl $190
80108510:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108515:	e9 0a f2 ff ff       	jmp    80107724 <alltraps>

8010851a <vector191>:
.globl vector191
vector191:
  pushl $0
8010851a:	6a 00                	push   $0x0
  pushl $191
8010851c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108521:	e9 fe f1 ff ff       	jmp    80107724 <alltraps>

80108526 <vector192>:
.globl vector192
vector192:
  pushl $0
80108526:	6a 00                	push   $0x0
  pushl $192
80108528:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010852d:	e9 f2 f1 ff ff       	jmp    80107724 <alltraps>

80108532 <vector193>:
.globl vector193
vector193:
  pushl $0
80108532:	6a 00                	push   $0x0
  pushl $193
80108534:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108539:	e9 e6 f1 ff ff       	jmp    80107724 <alltraps>

8010853e <vector194>:
.globl vector194
vector194:
  pushl $0
8010853e:	6a 00                	push   $0x0
  pushl $194
80108540:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108545:	e9 da f1 ff ff       	jmp    80107724 <alltraps>

8010854a <vector195>:
.globl vector195
vector195:
  pushl $0
8010854a:	6a 00                	push   $0x0
  pushl $195
8010854c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80108551:	e9 ce f1 ff ff       	jmp    80107724 <alltraps>

80108556 <vector196>:
.globl vector196
vector196:
  pushl $0
80108556:	6a 00                	push   $0x0
  pushl $196
80108558:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010855d:	e9 c2 f1 ff ff       	jmp    80107724 <alltraps>

80108562 <vector197>:
.globl vector197
vector197:
  pushl $0
80108562:	6a 00                	push   $0x0
  pushl $197
80108564:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80108569:	e9 b6 f1 ff ff       	jmp    80107724 <alltraps>

8010856e <vector198>:
.globl vector198
vector198:
  pushl $0
8010856e:	6a 00                	push   $0x0
  pushl $198
80108570:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80108575:	e9 aa f1 ff ff       	jmp    80107724 <alltraps>

8010857a <vector199>:
.globl vector199
vector199:
  pushl $0
8010857a:	6a 00                	push   $0x0
  pushl $199
8010857c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80108581:	e9 9e f1 ff ff       	jmp    80107724 <alltraps>

80108586 <vector200>:
.globl vector200
vector200:
  pushl $0
80108586:	6a 00                	push   $0x0
  pushl $200
80108588:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
8010858d:	e9 92 f1 ff ff       	jmp    80107724 <alltraps>

80108592 <vector201>:
.globl vector201
vector201:
  pushl $0
80108592:	6a 00                	push   $0x0
  pushl $201
80108594:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80108599:	e9 86 f1 ff ff       	jmp    80107724 <alltraps>

8010859e <vector202>:
.globl vector202
vector202:
  pushl $0
8010859e:	6a 00                	push   $0x0
  pushl $202
801085a0:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801085a5:	e9 7a f1 ff ff       	jmp    80107724 <alltraps>

801085aa <vector203>:
.globl vector203
vector203:
  pushl $0
801085aa:	6a 00                	push   $0x0
  pushl $203
801085ac:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801085b1:	e9 6e f1 ff ff       	jmp    80107724 <alltraps>

801085b6 <vector204>:
.globl vector204
vector204:
  pushl $0
801085b6:	6a 00                	push   $0x0
  pushl $204
801085b8:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801085bd:	e9 62 f1 ff ff       	jmp    80107724 <alltraps>

801085c2 <vector205>:
.globl vector205
vector205:
  pushl $0
801085c2:	6a 00                	push   $0x0
  pushl $205
801085c4:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801085c9:	e9 56 f1 ff ff       	jmp    80107724 <alltraps>

801085ce <vector206>:
.globl vector206
vector206:
  pushl $0
801085ce:	6a 00                	push   $0x0
  pushl $206
801085d0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801085d5:	e9 4a f1 ff ff       	jmp    80107724 <alltraps>

801085da <vector207>:
.globl vector207
vector207:
  pushl $0
801085da:	6a 00                	push   $0x0
  pushl $207
801085dc:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801085e1:	e9 3e f1 ff ff       	jmp    80107724 <alltraps>

801085e6 <vector208>:
.globl vector208
vector208:
  pushl $0
801085e6:	6a 00                	push   $0x0
  pushl $208
801085e8:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801085ed:	e9 32 f1 ff ff       	jmp    80107724 <alltraps>

801085f2 <vector209>:
.globl vector209
vector209:
  pushl $0
801085f2:	6a 00                	push   $0x0
  pushl $209
801085f4:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801085f9:	e9 26 f1 ff ff       	jmp    80107724 <alltraps>

801085fe <vector210>:
.globl vector210
vector210:
  pushl $0
801085fe:	6a 00                	push   $0x0
  pushl $210
80108600:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108605:	e9 1a f1 ff ff       	jmp    80107724 <alltraps>

8010860a <vector211>:
.globl vector211
vector211:
  pushl $0
8010860a:	6a 00                	push   $0x0
  pushl $211
8010860c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108611:	e9 0e f1 ff ff       	jmp    80107724 <alltraps>

80108616 <vector212>:
.globl vector212
vector212:
  pushl $0
80108616:	6a 00                	push   $0x0
  pushl $212
80108618:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010861d:	e9 02 f1 ff ff       	jmp    80107724 <alltraps>

80108622 <vector213>:
.globl vector213
vector213:
  pushl $0
80108622:	6a 00                	push   $0x0
  pushl $213
80108624:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108629:	e9 f6 f0 ff ff       	jmp    80107724 <alltraps>

8010862e <vector214>:
.globl vector214
vector214:
  pushl $0
8010862e:	6a 00                	push   $0x0
  pushl $214
80108630:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108635:	e9 ea f0 ff ff       	jmp    80107724 <alltraps>

8010863a <vector215>:
.globl vector215
vector215:
  pushl $0
8010863a:	6a 00                	push   $0x0
  pushl $215
8010863c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108641:	e9 de f0 ff ff       	jmp    80107724 <alltraps>

80108646 <vector216>:
.globl vector216
vector216:
  pushl $0
80108646:	6a 00                	push   $0x0
  pushl $216
80108648:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010864d:	e9 d2 f0 ff ff       	jmp    80107724 <alltraps>

80108652 <vector217>:
.globl vector217
vector217:
  pushl $0
80108652:	6a 00                	push   $0x0
  pushl $217
80108654:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108659:	e9 c6 f0 ff ff       	jmp    80107724 <alltraps>

8010865e <vector218>:
.globl vector218
vector218:
  pushl $0
8010865e:	6a 00                	push   $0x0
  pushl $218
80108660:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108665:	e9 ba f0 ff ff       	jmp    80107724 <alltraps>

8010866a <vector219>:
.globl vector219
vector219:
  pushl $0
8010866a:	6a 00                	push   $0x0
  pushl $219
8010866c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80108671:	e9 ae f0 ff ff       	jmp    80107724 <alltraps>

80108676 <vector220>:
.globl vector220
vector220:
  pushl $0
80108676:	6a 00                	push   $0x0
  pushl $220
80108678:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010867d:	e9 a2 f0 ff ff       	jmp    80107724 <alltraps>

80108682 <vector221>:
.globl vector221
vector221:
  pushl $0
80108682:	6a 00                	push   $0x0
  pushl $221
80108684:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80108689:	e9 96 f0 ff ff       	jmp    80107724 <alltraps>

8010868e <vector222>:
.globl vector222
vector222:
  pushl $0
8010868e:	6a 00                	push   $0x0
  pushl $222
80108690:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108695:	e9 8a f0 ff ff       	jmp    80107724 <alltraps>

8010869a <vector223>:
.globl vector223
vector223:
  pushl $0
8010869a:	6a 00                	push   $0x0
  pushl $223
8010869c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801086a1:	e9 7e f0 ff ff       	jmp    80107724 <alltraps>

801086a6 <vector224>:
.globl vector224
vector224:
  pushl $0
801086a6:	6a 00                	push   $0x0
  pushl $224
801086a8:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801086ad:	e9 72 f0 ff ff       	jmp    80107724 <alltraps>

801086b2 <vector225>:
.globl vector225
vector225:
  pushl $0
801086b2:	6a 00                	push   $0x0
  pushl $225
801086b4:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801086b9:	e9 66 f0 ff ff       	jmp    80107724 <alltraps>

801086be <vector226>:
.globl vector226
vector226:
  pushl $0
801086be:	6a 00                	push   $0x0
  pushl $226
801086c0:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801086c5:	e9 5a f0 ff ff       	jmp    80107724 <alltraps>

801086ca <vector227>:
.globl vector227
vector227:
  pushl $0
801086ca:	6a 00                	push   $0x0
  pushl $227
801086cc:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801086d1:	e9 4e f0 ff ff       	jmp    80107724 <alltraps>

801086d6 <vector228>:
.globl vector228
vector228:
  pushl $0
801086d6:	6a 00                	push   $0x0
  pushl $228
801086d8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801086dd:	e9 42 f0 ff ff       	jmp    80107724 <alltraps>

801086e2 <vector229>:
.globl vector229
vector229:
  pushl $0
801086e2:	6a 00                	push   $0x0
  pushl $229
801086e4:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801086e9:	e9 36 f0 ff ff       	jmp    80107724 <alltraps>

801086ee <vector230>:
.globl vector230
vector230:
  pushl $0
801086ee:	6a 00                	push   $0x0
  pushl $230
801086f0:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801086f5:	e9 2a f0 ff ff       	jmp    80107724 <alltraps>

801086fa <vector231>:
.globl vector231
vector231:
  pushl $0
801086fa:	6a 00                	push   $0x0
  pushl $231
801086fc:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108701:	e9 1e f0 ff ff       	jmp    80107724 <alltraps>

80108706 <vector232>:
.globl vector232
vector232:
  pushl $0
80108706:	6a 00                	push   $0x0
  pushl $232
80108708:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010870d:	e9 12 f0 ff ff       	jmp    80107724 <alltraps>

80108712 <vector233>:
.globl vector233
vector233:
  pushl $0
80108712:	6a 00                	push   $0x0
  pushl $233
80108714:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108719:	e9 06 f0 ff ff       	jmp    80107724 <alltraps>

8010871e <vector234>:
.globl vector234
vector234:
  pushl $0
8010871e:	6a 00                	push   $0x0
  pushl $234
80108720:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108725:	e9 fa ef ff ff       	jmp    80107724 <alltraps>

8010872a <vector235>:
.globl vector235
vector235:
  pushl $0
8010872a:	6a 00                	push   $0x0
  pushl $235
8010872c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108731:	e9 ee ef ff ff       	jmp    80107724 <alltraps>

80108736 <vector236>:
.globl vector236
vector236:
  pushl $0
80108736:	6a 00                	push   $0x0
  pushl $236
80108738:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010873d:	e9 e2 ef ff ff       	jmp    80107724 <alltraps>

80108742 <vector237>:
.globl vector237
vector237:
  pushl $0
80108742:	6a 00                	push   $0x0
  pushl $237
80108744:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108749:	e9 d6 ef ff ff       	jmp    80107724 <alltraps>

8010874e <vector238>:
.globl vector238
vector238:
  pushl $0
8010874e:	6a 00                	push   $0x0
  pushl $238
80108750:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108755:	e9 ca ef ff ff       	jmp    80107724 <alltraps>

8010875a <vector239>:
.globl vector239
vector239:
  pushl $0
8010875a:	6a 00                	push   $0x0
  pushl $239
8010875c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80108761:	e9 be ef ff ff       	jmp    80107724 <alltraps>

80108766 <vector240>:
.globl vector240
vector240:
  pushl $0
80108766:	6a 00                	push   $0x0
  pushl $240
80108768:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010876d:	e9 b2 ef ff ff       	jmp    80107724 <alltraps>

80108772 <vector241>:
.globl vector241
vector241:
  pushl $0
80108772:	6a 00                	push   $0x0
  pushl $241
80108774:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108779:	e9 a6 ef ff ff       	jmp    80107724 <alltraps>

8010877e <vector242>:
.globl vector242
vector242:
  pushl $0
8010877e:	6a 00                	push   $0x0
  pushl $242
80108780:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108785:	e9 9a ef ff ff       	jmp    80107724 <alltraps>

8010878a <vector243>:
.globl vector243
vector243:
  pushl $0
8010878a:	6a 00                	push   $0x0
  pushl $243
8010878c:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108791:	e9 8e ef ff ff       	jmp    80107724 <alltraps>

80108796 <vector244>:
.globl vector244
vector244:
  pushl $0
80108796:	6a 00                	push   $0x0
  pushl $244
80108798:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010879d:	e9 82 ef ff ff       	jmp    80107724 <alltraps>

801087a2 <vector245>:
.globl vector245
vector245:
  pushl $0
801087a2:	6a 00                	push   $0x0
  pushl $245
801087a4:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801087a9:	e9 76 ef ff ff       	jmp    80107724 <alltraps>

801087ae <vector246>:
.globl vector246
vector246:
  pushl $0
801087ae:	6a 00                	push   $0x0
  pushl $246
801087b0:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801087b5:	e9 6a ef ff ff       	jmp    80107724 <alltraps>

801087ba <vector247>:
.globl vector247
vector247:
  pushl $0
801087ba:	6a 00                	push   $0x0
  pushl $247
801087bc:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801087c1:	e9 5e ef ff ff       	jmp    80107724 <alltraps>

801087c6 <vector248>:
.globl vector248
vector248:
  pushl $0
801087c6:	6a 00                	push   $0x0
  pushl $248
801087c8:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801087cd:	e9 52 ef ff ff       	jmp    80107724 <alltraps>

801087d2 <vector249>:
.globl vector249
vector249:
  pushl $0
801087d2:	6a 00                	push   $0x0
  pushl $249
801087d4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801087d9:	e9 46 ef ff ff       	jmp    80107724 <alltraps>

801087de <vector250>:
.globl vector250
vector250:
  pushl $0
801087de:	6a 00                	push   $0x0
  pushl $250
801087e0:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801087e5:	e9 3a ef ff ff       	jmp    80107724 <alltraps>

801087ea <vector251>:
.globl vector251
vector251:
  pushl $0
801087ea:	6a 00                	push   $0x0
  pushl $251
801087ec:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801087f1:	e9 2e ef ff ff       	jmp    80107724 <alltraps>

801087f6 <vector252>:
.globl vector252
vector252:
  pushl $0
801087f6:	6a 00                	push   $0x0
  pushl $252
801087f8:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801087fd:	e9 22 ef ff ff       	jmp    80107724 <alltraps>

80108802 <vector253>:
.globl vector253
vector253:
  pushl $0
80108802:	6a 00                	push   $0x0
  pushl $253
80108804:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108809:	e9 16 ef ff ff       	jmp    80107724 <alltraps>

8010880e <vector254>:
.globl vector254
vector254:
  pushl $0
8010880e:	6a 00                	push   $0x0
  pushl $254
80108810:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108815:	e9 0a ef ff ff       	jmp    80107724 <alltraps>

8010881a <vector255>:
.globl vector255
vector255:
  pushl $0
8010881a:	6a 00                	push   $0x0
  pushl $255
8010881c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108821:	e9 fe ee ff ff       	jmp    80107724 <alltraps>
	...

80108828 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108828:	55                   	push   %ebp
80108829:	89 e5                	mov    %esp,%ebp
8010882b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010882e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108831:	83 e8 01             	sub    $0x1,%eax
80108834:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108838:	8b 45 08             	mov    0x8(%ebp),%eax
8010883b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010883f:	8b 45 08             	mov    0x8(%ebp),%eax
80108842:	c1 e8 10             	shr    $0x10,%eax
80108845:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108849:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010884c:	0f 01 10             	lgdtl  (%eax)
}
8010884f:	c9                   	leave  
80108850:	c3                   	ret    

80108851 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108851:	55                   	push   %ebp
80108852:	89 e5                	mov    %esp,%ebp
80108854:	83 ec 04             	sub    $0x4,%esp
80108857:	8b 45 08             	mov    0x8(%ebp),%eax
8010885a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010885e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108862:	0f 00 d8             	ltr    %ax
}
80108865:	c9                   	leave  
80108866:	c3                   	ret    

80108867 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108867:	55                   	push   %ebp
80108868:	89 e5                	mov    %esp,%ebp
8010886a:	83 ec 04             	sub    $0x4,%esp
8010886d:	8b 45 08             	mov    0x8(%ebp),%eax
80108870:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108874:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108878:	8e e8                	mov    %eax,%gs
}
8010887a:	c9                   	leave  
8010887b:	c3                   	ret    

8010887c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010887c:	55                   	push   %ebp
8010887d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010887f:	8b 45 08             	mov    0x8(%ebp),%eax
80108882:	0f 22 d8             	mov    %eax,%cr3
}
80108885:	5d                   	pop    %ebp
80108886:	c3                   	ret    

80108887 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108887:	55                   	push   %ebp
80108888:	89 e5                	mov    %esp,%ebp
8010888a:	8b 45 08             	mov    0x8(%ebp),%eax
8010888d:	05 00 00 00 80       	add    $0x80000000,%eax
80108892:	5d                   	pop    %ebp
80108893:	c3                   	ret    

80108894 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108894:	55                   	push   %ebp
80108895:	89 e5                	mov    %esp,%ebp
80108897:	8b 45 08             	mov    0x8(%ebp),%eax
8010889a:	05 00 00 00 80       	add    $0x80000000,%eax
8010889f:	5d                   	pop    %ebp
801088a0:	c3                   	ret    

801088a1 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801088a1:	55                   	push   %ebp
801088a2:	89 e5                	mov    %esp,%ebp
801088a4:	53                   	push   %ebx
801088a5:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801088a8:	e8 18 b9 ff ff       	call   801041c5 <cpunum>
801088ad:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801088b3:	05 80 09 11 80       	add    $0x80110980,%eax
801088b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801088bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088be:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801088c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c7:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801088cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801088d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801088db:	83 e2 f0             	and    $0xfffffff0,%edx
801088de:	83 ca 0a             	or     $0xa,%edx
801088e1:	88 50 7d             	mov    %dl,0x7d(%eax)
801088e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801088eb:	83 ca 10             	or     $0x10,%edx
801088ee:	88 50 7d             	mov    %dl,0x7d(%eax)
801088f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088f4:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801088f8:	83 e2 9f             	and    $0xffffff9f,%edx
801088fb:	88 50 7d             	mov    %dl,0x7d(%eax)
801088fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108901:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108905:	83 ca 80             	or     $0xffffff80,%edx
80108908:	88 50 7d             	mov    %dl,0x7d(%eax)
8010890b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010890e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108912:	83 ca 0f             	or     $0xf,%edx
80108915:	88 50 7e             	mov    %dl,0x7e(%eax)
80108918:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010891f:	83 e2 ef             	and    $0xffffffef,%edx
80108922:	88 50 7e             	mov    %dl,0x7e(%eax)
80108925:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108928:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010892c:	83 e2 df             	and    $0xffffffdf,%edx
8010892f:	88 50 7e             	mov    %dl,0x7e(%eax)
80108932:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108935:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108939:	83 ca 40             	or     $0x40,%edx
8010893c:	88 50 7e             	mov    %dl,0x7e(%eax)
8010893f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108942:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108946:	83 ca 80             	or     $0xffffff80,%edx
80108949:	88 50 7e             	mov    %dl,0x7e(%eax)
8010894c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010894f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108953:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108956:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010895d:	ff ff 
8010895f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108962:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108969:	00 00 
8010896b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010896e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108978:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010897f:	83 e2 f0             	and    $0xfffffff0,%edx
80108982:	83 ca 02             	or     $0x2,%edx
80108985:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010898b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010898e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108995:	83 ca 10             	or     $0x10,%edx
80108998:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010899e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a1:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089a8:	83 e2 9f             	and    $0xffffff9f,%edx
801089ab:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801089bb:	83 ca 80             	or     $0xffffff80,%edx
801089be:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801089c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089c7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801089ce:	83 ca 0f             	or     $0xf,%edx
801089d1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801089d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089da:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801089e1:	83 e2 ef             	and    $0xffffffef,%edx
801089e4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801089ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ed:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801089f4:	83 e2 df             	and    $0xffffffdf,%edx
801089f7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801089fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a00:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a07:	83 ca 40             	or     $0x40,%edx
80108a0a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a13:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108a1a:	83 ca 80             	or     $0xffffff80,%edx
80108a1d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a26:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a30:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108a37:	ff ff 
80108a39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a3c:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108a43:	00 00 
80108a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a48:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a52:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a59:	83 e2 f0             	and    $0xfffffff0,%edx
80108a5c:	83 ca 0a             	or     $0xa,%edx
80108a5f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a68:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a6f:	83 ca 10             	or     $0x10,%edx
80108a72:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a7b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a82:	83 ca 60             	or     $0x60,%edx
80108a85:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a8e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a95:	83 ca 80             	or     $0xffffff80,%edx
80108a98:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108aa8:	83 ca 0f             	or     $0xf,%edx
80108aab:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab4:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108abb:	83 e2 ef             	and    $0xffffffef,%edx
80108abe:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108ac4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108ace:	83 e2 df             	and    $0xffffffdf,%edx
80108ad1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ada:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108ae1:	83 ca 40             	or     $0x40,%edx
80108ae4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108aea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aed:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108af4:	83 ca 80             	or     $0xffffff80,%edx
80108af7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b00:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108b07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b0a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108b11:	ff ff 
80108b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b16:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108b1d:	00 00 
80108b1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b22:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b2c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b33:	83 e2 f0             	and    $0xfffffff0,%edx
80108b36:	83 ca 02             	or     $0x2,%edx
80108b39:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b42:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b49:	83 ca 10             	or     $0x10,%edx
80108b4c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b55:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b5c:	83 ca 60             	or     $0x60,%edx
80108b5f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b68:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108b6f:	83 ca 80             	or     $0xffffff80,%edx
80108b72:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108b78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b7b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b82:	83 ca 0f             	or     $0xf,%edx
80108b85:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b8e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b95:	83 e2 ef             	and    $0xffffffef,%edx
80108b98:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ba1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108ba8:	83 e2 df             	and    $0xffffffdf,%edx
80108bab:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bb4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bbb:	83 ca 40             	or     $0x40,%edx
80108bbe:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108bce:	83 ca 80             	or     $0xffffff80,%edx
80108bd1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bda:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be4:	05 b4 00 00 00       	add    $0xb4,%eax
80108be9:	89 c3                	mov    %eax,%ebx
80108beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bee:	05 b4 00 00 00       	add    $0xb4,%eax
80108bf3:	c1 e8 10             	shr    $0x10,%eax
80108bf6:	89 c1                	mov    %eax,%ecx
80108bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bfb:	05 b4 00 00 00       	add    $0xb4,%eax
80108c00:	c1 e8 18             	shr    $0x18,%eax
80108c03:	89 c2                	mov    %eax,%edx
80108c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c08:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108c0f:	00 00 
80108c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c14:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108c1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c1e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108c24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c27:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c2e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108c31:	83 c9 02             	or     $0x2,%ecx
80108c34:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c3d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c44:	83 c9 10             	or     $0x10,%ecx
80108c47:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c50:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c57:	83 e1 9f             	and    $0xffffff9f,%ecx
80108c5a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c63:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108c6a:	83 c9 80             	or     $0xffffff80,%ecx
80108c6d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108c73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c76:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c7d:	83 e1 f0             	and    $0xfffffff0,%ecx
80108c80:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c89:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c90:	83 e1 ef             	and    $0xffffffef,%ecx
80108c93:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c9c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108ca3:	83 e1 df             	and    $0xffffffdf,%ecx
80108ca6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108caf:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cb6:	83 c9 40             	or     $0x40,%ecx
80108cb9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108cc9:	83 c9 80             	or     $0xffffff80,%ecx
80108ccc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108cd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd5:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108cdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cde:	83 c0 70             	add    $0x70,%eax
80108ce1:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108ce8:	00 
80108ce9:	89 04 24             	mov    %eax,(%esp)
80108cec:	e8 37 fb ff ff       	call   80108828 <lgdt>
  loadgs(SEG_KCPU << 3);
80108cf1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108cf8:	e8 6a fb ff ff       	call   80108867 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d00:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108d06:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108d0d:	00 00 00 00 
}
80108d11:	83 c4 24             	add    $0x24,%esp
80108d14:	5b                   	pop    %ebx
80108d15:	5d                   	pop    %ebp
80108d16:	c3                   	ret    

80108d17 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108d17:	55                   	push   %ebp
80108d18:	89 e5                	mov    %esp,%ebp
80108d1a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d20:	c1 e8 16             	shr    $0x16,%eax
80108d23:	c1 e0 02             	shl    $0x2,%eax
80108d26:	03 45 08             	add    0x8(%ebp),%eax
80108d29:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d2f:	8b 00                	mov    (%eax),%eax
80108d31:	83 e0 01             	and    $0x1,%eax
80108d34:	84 c0                	test   %al,%al
80108d36:	74 17                	je     80108d4f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108d38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d3b:	8b 00                	mov    (%eax),%eax
80108d3d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d42:	89 04 24             	mov    %eax,(%esp)
80108d45:	e8 4a fb ff ff       	call   80108894 <p2v>
80108d4a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108d4d:	eb 4b                	jmp    80108d9a <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108d4f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108d53:	74 0e                	je     80108d63 <walkpgdir+0x4c>
80108d55:	e8 dd b0 ff ff       	call   80103e37 <kalloc>
80108d5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108d5d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108d61:	75 07                	jne    80108d6a <walkpgdir+0x53>
      return 0;
80108d63:	b8 00 00 00 00       	mov    $0x0,%eax
80108d68:	eb 41                	jmp    80108dab <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108d6a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108d71:	00 
80108d72:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108d79:	00 
80108d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d7d:	89 04 24             	mov    %eax,(%esp)
80108d80:	e8 a5 d3 ff ff       	call   8010612a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108d85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d88:	89 04 24             	mov    %eax,(%esp)
80108d8b:	e8 f7 fa ff ff       	call   80108887 <v2p>
80108d90:	89 c2                	mov    %eax,%edx
80108d92:	83 ca 07             	or     $0x7,%edx
80108d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d98:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d9d:	c1 e8 0c             	shr    $0xc,%eax
80108da0:	25 ff 03 00 00       	and    $0x3ff,%eax
80108da5:	c1 e0 02             	shl    $0x2,%eax
80108da8:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108dab:	c9                   	leave  
80108dac:	c3                   	ret    

80108dad <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108dad:	55                   	push   %ebp
80108dae:	89 e5                	mov    %esp,%ebp
80108db0:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108db3:	8b 45 0c             	mov    0xc(%ebp),%eax
80108db6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dbb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108dbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80108dc1:	03 45 10             	add    0x10(%ebp),%eax
80108dc4:	83 e8 01             	sub    $0x1,%eax
80108dc7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dcc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108dcf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108dd6:	00 
80108dd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dda:	89 44 24 04          	mov    %eax,0x4(%esp)
80108dde:	8b 45 08             	mov    0x8(%ebp),%eax
80108de1:	89 04 24             	mov    %eax,(%esp)
80108de4:	e8 2e ff ff ff       	call   80108d17 <walkpgdir>
80108de9:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108dec:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108df0:	75 07                	jne    80108df9 <mappages+0x4c>
      return -1;
80108df2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108df7:	eb 46                	jmp    80108e3f <mappages+0x92>
    if(*pte & PTE_P)
80108df9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108dfc:	8b 00                	mov    (%eax),%eax
80108dfe:	83 e0 01             	and    $0x1,%eax
80108e01:	84 c0                	test   %al,%al
80108e03:	74 0c                	je     80108e11 <mappages+0x64>
      panic("remap");
80108e05:	c7 04 24 08 9d 10 80 	movl   $0x80109d08,(%esp)
80108e0c:	e8 2c 77 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108e11:	8b 45 18             	mov    0x18(%ebp),%eax
80108e14:	0b 45 14             	or     0x14(%ebp),%eax
80108e17:	89 c2                	mov    %eax,%edx
80108e19:	83 ca 01             	or     $0x1,%edx
80108e1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e1f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108e21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e24:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108e27:	74 10                	je     80108e39 <mappages+0x8c>
      break;
    a += PGSIZE;
80108e29:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108e30:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108e37:	eb 96                	jmp    80108dcf <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108e39:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108e3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108e3f:	c9                   	leave  
80108e40:	c3                   	ret    

80108e41 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108e41:	55                   	push   %ebp
80108e42:	89 e5                	mov    %esp,%ebp
80108e44:	53                   	push   %ebx
80108e45:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108e48:	e8 ea af ff ff       	call   80103e37 <kalloc>
80108e4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108e50:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e54:	75 0a                	jne    80108e60 <setupkvm+0x1f>
    return 0;
80108e56:	b8 00 00 00 00       	mov    $0x0,%eax
80108e5b:	e9 98 00 00 00       	jmp    80108ef8 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108e60:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e67:	00 
80108e68:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108e6f:	00 
80108e70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e73:	89 04 24             	mov    %eax,(%esp)
80108e76:	e8 af d2 ff ff       	call   8010612a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108e7b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108e82:	e8 0d fa ff ff       	call   80108894 <p2v>
80108e87:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108e8c:	76 0c                	jbe    80108e9a <setupkvm+0x59>
    panic("PHYSTOP too high");
80108e8e:	c7 04 24 0e 9d 10 80 	movl   $0x80109d0e,(%esp)
80108e95:	e8 a3 76 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108e9a:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108ea1:	eb 49                	jmp    80108eec <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108ea6:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108eac:	8b 50 04             	mov    0x4(%eax),%edx
80108eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eb2:	8b 58 08             	mov    0x8(%eax),%ebx
80108eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eb8:	8b 40 04             	mov    0x4(%eax),%eax
80108ebb:	29 c3                	sub    %eax,%ebx
80108ebd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ec0:	8b 00                	mov    (%eax),%eax
80108ec2:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108ec6:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108eca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108ece:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ed2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ed5:	89 04 24             	mov    %eax,(%esp)
80108ed8:	e8 d0 fe ff ff       	call   80108dad <mappages>
80108edd:	85 c0                	test   %eax,%eax
80108edf:	79 07                	jns    80108ee8 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108ee1:	b8 00 00 00 00       	mov    $0x0,%eax
80108ee6:	eb 10                	jmp    80108ef8 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108ee8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108eec:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108ef3:	72 ae                	jb     80108ea3 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108ef5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108ef8:	83 c4 34             	add    $0x34,%esp
80108efb:	5b                   	pop    %ebx
80108efc:	5d                   	pop    %ebp
80108efd:	c3                   	ret    

80108efe <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108efe:	55                   	push   %ebp
80108eff:	89 e5                	mov    %esp,%ebp
80108f01:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108f04:	e8 38 ff ff ff       	call   80108e41 <setupkvm>
80108f09:	a3 58 37 11 80       	mov    %eax,0x80113758
  switchkvm();
80108f0e:	e8 02 00 00 00       	call   80108f15 <switchkvm>
}
80108f13:	c9                   	leave  
80108f14:	c3                   	ret    

80108f15 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108f15:	55                   	push   %ebp
80108f16:	89 e5                	mov    %esp,%ebp
80108f18:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108f1b:	a1 58 37 11 80       	mov    0x80113758,%eax
80108f20:	89 04 24             	mov    %eax,(%esp)
80108f23:	e8 5f f9 ff ff       	call   80108887 <v2p>
80108f28:	89 04 24             	mov    %eax,(%esp)
80108f2b:	e8 4c f9 ff ff       	call   8010887c <lcr3>
}
80108f30:	c9                   	leave  
80108f31:	c3                   	ret    

80108f32 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108f32:	55                   	push   %ebp
80108f33:	89 e5                	mov    %esp,%ebp
80108f35:	53                   	push   %ebx
80108f36:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108f39:	e8 e5 d0 ff ff       	call   80106023 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108f3e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f44:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f4b:	83 c2 08             	add    $0x8,%edx
80108f4e:	89 d3                	mov    %edx,%ebx
80108f50:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f57:	83 c2 08             	add    $0x8,%edx
80108f5a:	c1 ea 10             	shr    $0x10,%edx
80108f5d:	89 d1                	mov    %edx,%ecx
80108f5f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108f66:	83 c2 08             	add    $0x8,%edx
80108f69:	c1 ea 18             	shr    $0x18,%edx
80108f6c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108f73:	67 00 
80108f75:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108f7c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108f82:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108f89:	83 e1 f0             	and    $0xfffffff0,%ecx
80108f8c:	83 c9 09             	or     $0x9,%ecx
80108f8f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108f95:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108f9c:	83 c9 10             	or     $0x10,%ecx
80108f9f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fa5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fac:	83 e1 9f             	and    $0xffffff9f,%ecx
80108faf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fb5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108fbc:	83 c9 80             	or     $0xffffff80,%ecx
80108fbf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108fc5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108fcc:	83 e1 f0             	and    $0xfffffff0,%ecx
80108fcf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108fd5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108fdc:	83 e1 ef             	and    $0xffffffef,%ecx
80108fdf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108fe5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108fec:	83 e1 df             	and    $0xffffffdf,%ecx
80108fef:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108ff5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108ffc:	83 c9 40             	or     $0x40,%ecx
80108fff:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109005:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010900c:	83 e1 7f             	and    $0x7f,%ecx
8010900f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80109015:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010901b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109021:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80109028:	83 e2 ef             	and    $0xffffffef,%edx
8010902b:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80109031:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109037:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
8010903d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80109043:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010904a:	8b 52 08             	mov    0x8(%edx),%edx
8010904d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80109053:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80109056:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
8010905d:	e8 ef f7 ff ff       	call   80108851 <ltr>
  if(p->pgdir == 0)
80109062:	8b 45 08             	mov    0x8(%ebp),%eax
80109065:	8b 40 04             	mov    0x4(%eax),%eax
80109068:	85 c0                	test   %eax,%eax
8010906a:	75 0c                	jne    80109078 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
8010906c:	c7 04 24 1f 9d 10 80 	movl   $0x80109d1f,(%esp)
80109073:	e8 c5 74 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80109078:	8b 45 08             	mov    0x8(%ebp),%eax
8010907b:	8b 40 04             	mov    0x4(%eax),%eax
8010907e:	89 04 24             	mov    %eax,(%esp)
80109081:	e8 01 f8 ff ff       	call   80108887 <v2p>
80109086:	89 04 24             	mov    %eax,(%esp)
80109089:	e8 ee f7 ff ff       	call   8010887c <lcr3>
  popcli();
8010908e:	e8 d8 cf ff ff       	call   8010606b <popcli>
}
80109093:	83 c4 14             	add    $0x14,%esp
80109096:	5b                   	pop    %ebx
80109097:	5d                   	pop    %ebp
80109098:	c3                   	ret    

80109099 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80109099:	55                   	push   %ebp
8010909a:	89 e5                	mov    %esp,%ebp
8010909c:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
8010909f:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801090a6:	76 0c                	jbe    801090b4 <inituvm+0x1b>
    panic("inituvm: more than a page");
801090a8:	c7 04 24 33 9d 10 80 	movl   $0x80109d33,(%esp)
801090af:	e8 89 74 ff ff       	call   8010053d <panic>
  mem = kalloc();
801090b4:	e8 7e ad ff ff       	call   80103e37 <kalloc>
801090b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801090bc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090c3:	00 
801090c4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801090cb:	00 
801090cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090cf:	89 04 24             	mov    %eax,(%esp)
801090d2:	e8 53 d0 ff ff       	call   8010612a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
801090d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090da:	89 04 24             	mov    %eax,(%esp)
801090dd:	e8 a5 f7 ff ff       	call   80108887 <v2p>
801090e2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801090e9:	00 
801090ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
801090ee:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090f5:	00 
801090f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801090fd:	00 
801090fe:	8b 45 08             	mov    0x8(%ebp),%eax
80109101:	89 04 24             	mov    %eax,(%esp)
80109104:	e8 a4 fc ff ff       	call   80108dad <mappages>
  memmove(mem, init, sz);
80109109:	8b 45 10             	mov    0x10(%ebp),%eax
8010910c:	89 44 24 08          	mov    %eax,0x8(%esp)
80109110:	8b 45 0c             	mov    0xc(%ebp),%eax
80109113:	89 44 24 04          	mov    %eax,0x4(%esp)
80109117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010911a:	89 04 24             	mov    %eax,(%esp)
8010911d:	e8 db d0 ff ff       	call   801061fd <memmove>
}
80109122:	c9                   	leave  
80109123:	c3                   	ret    

80109124 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80109124:	55                   	push   %ebp
80109125:	89 e5                	mov    %esp,%ebp
80109127:	53                   	push   %ebx
80109128:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010912b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010912e:	25 ff 0f 00 00       	and    $0xfff,%eax
80109133:	85 c0                	test   %eax,%eax
80109135:	74 0c                	je     80109143 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80109137:	c7 04 24 50 9d 10 80 	movl   $0x80109d50,(%esp)
8010913e:	e8 fa 73 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80109143:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010914a:	e9 ad 00 00 00       	jmp    801091fc <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010914f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109152:	8b 55 0c             	mov    0xc(%ebp),%edx
80109155:	01 d0                	add    %edx,%eax
80109157:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010915e:	00 
8010915f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109163:	8b 45 08             	mov    0x8(%ebp),%eax
80109166:	89 04 24             	mov    %eax,(%esp)
80109169:	e8 a9 fb ff ff       	call   80108d17 <walkpgdir>
8010916e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109171:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109175:	75 0c                	jne    80109183 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80109177:	c7 04 24 73 9d 10 80 	movl   $0x80109d73,(%esp)
8010917e:	e8 ba 73 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80109183:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109186:	8b 00                	mov    (%eax),%eax
80109188:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010918d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80109190:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109193:	8b 55 18             	mov    0x18(%ebp),%edx
80109196:	89 d1                	mov    %edx,%ecx
80109198:	29 c1                	sub    %eax,%ecx
8010919a:	89 c8                	mov    %ecx,%eax
8010919c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801091a1:	77 11                	ja     801091b4 <loaduvm+0x90>
      n = sz - i;
801091a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091a6:	8b 55 18             	mov    0x18(%ebp),%edx
801091a9:	89 d1                	mov    %edx,%ecx
801091ab:	29 c1                	sub    %eax,%ecx
801091ad:	89 c8                	mov    %ecx,%eax
801091af:	89 45 f0             	mov    %eax,-0x10(%ebp)
801091b2:	eb 07                	jmp    801091bb <loaduvm+0x97>
    else
      n = PGSIZE;
801091b4:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801091bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091be:	8b 55 14             	mov    0x14(%ebp),%edx
801091c1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801091c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801091c7:	89 04 24             	mov    %eax,(%esp)
801091ca:	e8 c5 f6 ff ff       	call   80108894 <p2v>
801091cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091d2:	89 54 24 0c          	mov    %edx,0xc(%esp)
801091d6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801091da:	89 44 24 04          	mov    %eax,0x4(%esp)
801091de:	8b 45 10             	mov    0x10(%ebp),%eax
801091e1:	89 04 24             	mov    %eax,(%esp)
801091e4:	e8 59 9a ff ff       	call   80102c42 <readi>
801091e9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801091ec:	74 07                	je     801091f5 <loaduvm+0xd1>
      return -1;
801091ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801091f3:	eb 18                	jmp    8010920d <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801091f5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801091fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091ff:	3b 45 18             	cmp    0x18(%ebp),%eax
80109202:	0f 82 47 ff ff ff    	jb     8010914f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109208:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010920d:	83 c4 24             	add    $0x24,%esp
80109210:	5b                   	pop    %ebx
80109211:	5d                   	pop    %ebp
80109212:	c3                   	ret    

80109213 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109213:	55                   	push   %ebp
80109214:	89 e5                	mov    %esp,%ebp
80109216:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109219:	8b 45 10             	mov    0x10(%ebp),%eax
8010921c:	85 c0                	test   %eax,%eax
8010921e:	79 0a                	jns    8010922a <allocuvm+0x17>
    return 0;
80109220:	b8 00 00 00 00       	mov    $0x0,%eax
80109225:	e9 c1 00 00 00       	jmp    801092eb <allocuvm+0xd8>
  if(newsz < oldsz)
8010922a:	8b 45 10             	mov    0x10(%ebp),%eax
8010922d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109230:	73 08                	jae    8010923a <allocuvm+0x27>
    return oldsz;
80109232:	8b 45 0c             	mov    0xc(%ebp),%eax
80109235:	e9 b1 00 00 00       	jmp    801092eb <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010923a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010923d:	05 ff 0f 00 00       	add    $0xfff,%eax
80109242:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109247:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010924a:	e9 8d 00 00 00       	jmp    801092dc <allocuvm+0xc9>
    mem = kalloc();
8010924f:	e8 e3 ab ff ff       	call   80103e37 <kalloc>
80109254:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80109257:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010925b:	75 2c                	jne    80109289 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010925d:	c7 04 24 91 9d 10 80 	movl   $0x80109d91,(%esp)
80109264:	e8 38 71 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80109269:	8b 45 0c             	mov    0xc(%ebp),%eax
8010926c:	89 44 24 08          	mov    %eax,0x8(%esp)
80109270:	8b 45 10             	mov    0x10(%ebp),%eax
80109273:	89 44 24 04          	mov    %eax,0x4(%esp)
80109277:	8b 45 08             	mov    0x8(%ebp),%eax
8010927a:	89 04 24             	mov    %eax,(%esp)
8010927d:	e8 6b 00 00 00       	call   801092ed <deallocuvm>
      return 0;
80109282:	b8 00 00 00 00       	mov    $0x0,%eax
80109287:	eb 62                	jmp    801092eb <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80109289:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109290:	00 
80109291:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109298:	00 
80109299:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010929c:	89 04 24             	mov    %eax,(%esp)
8010929f:	e8 86 ce ff ff       	call   8010612a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801092a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092a7:	89 04 24             	mov    %eax,(%esp)
801092aa:	e8 d8 f5 ff ff       	call   80108887 <v2p>
801092af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801092b2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801092b9:	00 
801092ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
801092be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801092c5:	00 
801092c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801092ca:	8b 45 08             	mov    0x8(%ebp),%eax
801092cd:	89 04 24             	mov    %eax,(%esp)
801092d0:	e8 d8 fa ff ff       	call   80108dad <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801092d5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801092dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801092df:	3b 45 10             	cmp    0x10(%ebp),%eax
801092e2:	0f 82 67 ff ff ff    	jb     8010924f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801092e8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801092eb:	c9                   	leave  
801092ec:	c3                   	ret    

801092ed <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801092ed:	55                   	push   %ebp
801092ee:	89 e5                	mov    %esp,%ebp
801092f0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801092f3:	8b 45 10             	mov    0x10(%ebp),%eax
801092f6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801092f9:	72 08                	jb     80109303 <deallocuvm+0x16>
    return oldsz;
801092fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801092fe:	e9 a4 00 00 00       	jmp    801093a7 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80109303:	8b 45 10             	mov    0x10(%ebp),%eax
80109306:	05 ff 0f 00 00       	add    $0xfff,%eax
8010930b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109310:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80109313:	e9 80 00 00 00       	jmp    80109398 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010931b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109322:	00 
80109323:	89 44 24 04          	mov    %eax,0x4(%esp)
80109327:	8b 45 08             	mov    0x8(%ebp),%eax
8010932a:	89 04 24             	mov    %eax,(%esp)
8010932d:	e8 e5 f9 ff ff       	call   80108d17 <walkpgdir>
80109332:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80109335:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109339:	75 09                	jne    80109344 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010933b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80109342:	eb 4d                	jmp    80109391 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80109344:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109347:	8b 00                	mov    (%eax),%eax
80109349:	83 e0 01             	and    $0x1,%eax
8010934c:	84 c0                	test   %al,%al
8010934e:	74 41                	je     80109391 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80109350:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109353:	8b 00                	mov    (%eax),%eax
80109355:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010935a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
8010935d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109361:	75 0c                	jne    8010936f <deallocuvm+0x82>
        panic("kfree");
80109363:	c7 04 24 a9 9d 10 80 	movl   $0x80109da9,(%esp)
8010936a:	e8 ce 71 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
8010936f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109372:	89 04 24             	mov    %eax,(%esp)
80109375:	e8 1a f5 ff ff       	call   80108894 <p2v>
8010937a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010937d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109380:	89 04 24             	mov    %eax,(%esp)
80109383:	e8 16 aa ff ff       	call   80103d9e <kfree>
      *pte = 0;
80109388:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010938b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80109391:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109398:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010939b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010939e:	0f 82 74 ff ff ff    	jb     80109318 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801093a4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801093a7:	c9                   	leave  
801093a8:	c3                   	ret    

801093a9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801093a9:	55                   	push   %ebp
801093aa:	89 e5                	mov    %esp,%ebp
801093ac:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801093af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801093b3:	75 0c                	jne    801093c1 <freevm+0x18>
    panic("freevm: no pgdir");
801093b5:	c7 04 24 af 9d 10 80 	movl   $0x80109daf,(%esp)
801093bc:	e8 7c 71 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801093c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801093c8:	00 
801093c9:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801093d0:	80 
801093d1:	8b 45 08             	mov    0x8(%ebp),%eax
801093d4:	89 04 24             	mov    %eax,(%esp)
801093d7:	e8 11 ff ff ff       	call   801092ed <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801093dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801093e3:	eb 3c                	jmp    80109421 <freevm+0x78>
    if(pgdir[i] & PTE_P){
801093e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093e8:	c1 e0 02             	shl    $0x2,%eax
801093eb:	03 45 08             	add    0x8(%ebp),%eax
801093ee:	8b 00                	mov    (%eax),%eax
801093f0:	83 e0 01             	and    $0x1,%eax
801093f3:	84 c0                	test   %al,%al
801093f5:	74 26                	je     8010941d <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801093f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093fa:	c1 e0 02             	shl    $0x2,%eax
801093fd:	03 45 08             	add    0x8(%ebp),%eax
80109400:	8b 00                	mov    (%eax),%eax
80109402:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109407:	89 04 24             	mov    %eax,(%esp)
8010940a:	e8 85 f4 ff ff       	call   80108894 <p2v>
8010940f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80109412:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109415:	89 04 24             	mov    %eax,(%esp)
80109418:	e8 81 a9 ff ff       	call   80103d9e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010941d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109421:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109428:	76 bb                	jbe    801093e5 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010942a:	8b 45 08             	mov    0x8(%ebp),%eax
8010942d:	89 04 24             	mov    %eax,(%esp)
80109430:	e8 69 a9 ff ff       	call   80103d9e <kfree>
}
80109435:	c9                   	leave  
80109436:	c3                   	ret    

80109437 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80109437:	55                   	push   %ebp
80109438:	89 e5                	mov    %esp,%ebp
8010943a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010943d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109444:	00 
80109445:	8b 45 0c             	mov    0xc(%ebp),%eax
80109448:	89 44 24 04          	mov    %eax,0x4(%esp)
8010944c:	8b 45 08             	mov    0x8(%ebp),%eax
8010944f:	89 04 24             	mov    %eax,(%esp)
80109452:	e8 c0 f8 ff ff       	call   80108d17 <walkpgdir>
80109457:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010945a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010945e:	75 0c                	jne    8010946c <clearpteu+0x35>
    panic("clearpteu");
80109460:	c7 04 24 c0 9d 10 80 	movl   $0x80109dc0,(%esp)
80109467:	e8 d1 70 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
8010946c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010946f:	8b 00                	mov    (%eax),%eax
80109471:	89 c2                	mov    %eax,%edx
80109473:	83 e2 fb             	and    $0xfffffffb,%edx
80109476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109479:	89 10                	mov    %edx,(%eax)
}
8010947b:	c9                   	leave  
8010947c:	c3                   	ret    

8010947d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010947d:	55                   	push   %ebp
8010947e:	89 e5                	mov    %esp,%ebp
80109480:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80109483:	e8 b9 f9 ff ff       	call   80108e41 <setupkvm>
80109488:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010948b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010948f:	75 0a                	jne    8010949b <copyuvm+0x1e>
    return 0;
80109491:	b8 00 00 00 00       	mov    $0x0,%eax
80109496:	e9 f1 00 00 00       	jmp    8010958c <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010949b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801094a2:	e9 c0 00 00 00       	jmp    80109567 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801094a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094aa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801094b1:	00 
801094b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801094b6:	8b 45 08             	mov    0x8(%ebp),%eax
801094b9:	89 04 24             	mov    %eax,(%esp)
801094bc:	e8 56 f8 ff ff       	call   80108d17 <walkpgdir>
801094c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801094c4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801094c8:	75 0c                	jne    801094d6 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801094ca:	c7 04 24 ca 9d 10 80 	movl   $0x80109dca,(%esp)
801094d1:	e8 67 70 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801094d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094d9:	8b 00                	mov    (%eax),%eax
801094db:	83 e0 01             	and    $0x1,%eax
801094de:	85 c0                	test   %eax,%eax
801094e0:	75 0c                	jne    801094ee <copyuvm+0x71>
      panic("copyuvm: page not present");
801094e2:	c7 04 24 e4 9d 10 80 	movl   $0x80109de4,(%esp)
801094e9:	e8 4f 70 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801094ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094f1:	8b 00                	mov    (%eax),%eax
801094f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094f8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801094fb:	e8 37 a9 ff ff       	call   80103e37 <kalloc>
80109500:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80109503:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109507:	74 6f                	je     80109578 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109509:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010950c:	89 04 24             	mov    %eax,(%esp)
8010950f:	e8 80 f3 ff ff       	call   80108894 <p2v>
80109514:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010951b:	00 
8010951c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109520:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109523:	89 04 24             	mov    %eax,(%esp)
80109526:	e8 d2 cc ff ff       	call   801061fd <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010952b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010952e:	89 04 24             	mov    %eax,(%esp)
80109531:	e8 51 f3 ff ff       	call   80108887 <v2p>
80109536:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109539:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109540:	00 
80109541:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109545:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010954c:	00 
8010954d:	89 54 24 04          	mov    %edx,0x4(%esp)
80109551:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109554:	89 04 24             	mov    %eax,(%esp)
80109557:	e8 51 f8 ff ff       	call   80108dad <mappages>
8010955c:	85 c0                	test   %eax,%eax
8010955e:	78 1b                	js     8010957b <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80109560:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010956a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010956d:	0f 82 34 ff ff ff    	jb     801094a7 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80109573:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109576:	eb 14                	jmp    8010958c <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80109578:	90                   	nop
80109579:	eb 01                	jmp    8010957c <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010957b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010957c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010957f:	89 04 24             	mov    %eax,(%esp)
80109582:	e8 22 fe ff ff       	call   801093a9 <freevm>
  return 0;
80109587:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010958c:	c9                   	leave  
8010958d:	c3                   	ret    

8010958e <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010958e:	55                   	push   %ebp
8010958f:	89 e5                	mov    %esp,%ebp
80109591:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109594:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010959b:	00 
8010959c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010959f:	89 44 24 04          	mov    %eax,0x4(%esp)
801095a3:	8b 45 08             	mov    0x8(%ebp),%eax
801095a6:	89 04 24             	mov    %eax,(%esp)
801095a9:	e8 69 f7 ff ff       	call   80108d17 <walkpgdir>
801095ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801095b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095b4:	8b 00                	mov    (%eax),%eax
801095b6:	83 e0 01             	and    $0x1,%eax
801095b9:	85 c0                	test   %eax,%eax
801095bb:	75 07                	jne    801095c4 <uva2ka+0x36>
    return 0;
801095bd:	b8 00 00 00 00       	mov    $0x0,%eax
801095c2:	eb 25                	jmp    801095e9 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801095c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095c7:	8b 00                	mov    (%eax),%eax
801095c9:	83 e0 04             	and    $0x4,%eax
801095cc:	85 c0                	test   %eax,%eax
801095ce:	75 07                	jne    801095d7 <uva2ka+0x49>
    return 0;
801095d0:	b8 00 00 00 00       	mov    $0x0,%eax
801095d5:	eb 12                	jmp    801095e9 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801095d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801095da:	8b 00                	mov    (%eax),%eax
801095dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801095e1:	89 04 24             	mov    %eax,(%esp)
801095e4:	e8 ab f2 ff ff       	call   80108894 <p2v>
}
801095e9:	c9                   	leave  
801095ea:	c3                   	ret    

801095eb <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801095eb:	55                   	push   %ebp
801095ec:	89 e5                	mov    %esp,%ebp
801095ee:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801095f1:	8b 45 10             	mov    0x10(%ebp),%eax
801095f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801095f7:	e9 8b 00 00 00       	jmp    80109687 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801095fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801095ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109604:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109607:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010960a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010960e:	8b 45 08             	mov    0x8(%ebp),%eax
80109611:	89 04 24             	mov    %eax,(%esp)
80109614:	e8 75 ff ff ff       	call   8010958e <uva2ka>
80109619:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010961c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109620:	75 07                	jne    80109629 <copyout+0x3e>
      return -1;
80109622:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109627:	eb 6d                	jmp    80109696 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109629:	8b 45 0c             	mov    0xc(%ebp),%eax
8010962c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010962f:	89 d1                	mov    %edx,%ecx
80109631:	29 c1                	sub    %eax,%ecx
80109633:	89 c8                	mov    %ecx,%eax
80109635:	05 00 10 00 00       	add    $0x1000,%eax
8010963a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010963d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109640:	3b 45 14             	cmp    0x14(%ebp),%eax
80109643:	76 06                	jbe    8010964b <copyout+0x60>
      n = len;
80109645:	8b 45 14             	mov    0x14(%ebp),%eax
80109648:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010964b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010964e:	8b 55 0c             	mov    0xc(%ebp),%edx
80109651:	89 d1                	mov    %edx,%ecx
80109653:	29 c1                	sub    %eax,%ecx
80109655:	89 c8                	mov    %ecx,%eax
80109657:	03 45 e8             	add    -0x18(%ebp),%eax
8010965a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010965d:	89 54 24 08          	mov    %edx,0x8(%esp)
80109661:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109664:	89 54 24 04          	mov    %edx,0x4(%esp)
80109668:	89 04 24             	mov    %eax,(%esp)
8010966b:	e8 8d cb ff ff       	call   801061fd <memmove>
    len -= n;
80109670:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109673:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109676:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109679:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010967c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010967f:	05 00 10 00 00       	add    $0x1000,%eax
80109684:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109687:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010968b:	0f 85 6b ff ff ff    	jne    801095fc <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109691:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109696:	c9                   	leave  
80109697:	c3                   	ret    

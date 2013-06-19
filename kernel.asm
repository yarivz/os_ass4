
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
8010002d:	b8 93 3e 10 80       	mov    $0x80103e93,%eax
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
8010003a:	c7 44 24 04 b8 8d 10 	movl   $0x80108db8,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 c0 55 00 00       	call   8010560e <initlock>

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
801000bd:	e8 6d 55 00 00       	call   8010562f <acquire>

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
80100104:	e8 88 55 00 00       	call   80105691 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 2d 52 00 00       	call   80105351 <sleep>
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
8010017c:	e8 10 55 00 00       	call   80105691 <release>
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
80100198:	c7 04 24 bf 8d 10 80 	movl   $0x80108dbf,(%esp)
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
801001d3:	e8 68 30 00 00       	call   80103240 <iderw>
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
801001ef:	c7 04 24 d0 8d 10 80 	movl   $0x80108dd0,(%esp)
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
80100210:	e8 2b 30 00 00       	call   80103240 <iderw>
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
80100229:	c7 04 24 d7 8d 10 80 	movl   $0x80108dd7,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 ee 53 00 00       	call   8010562f <acquire>

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
8010029d:	e8 88 51 00 00       	call   8010542a <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 e3 53 00 00       	call   80105691 <release>
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
801003bc:	e8 6e 52 00 00       	call   8010562f <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 de 8d 10 80 	movl   $0x80108dde,(%esp)
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
801004af:	c7 45 ec e7 8d 10 80 	movl   $0x80108de7,-0x14(%ebp)
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
80100536:	e8 56 51 00 00       	call   80105691 <release>
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
80100562:	c7 04 24 ee 8d 10 80 	movl   $0x80108dee,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 fd 8d 10 80 	movl   $0x80108dfd,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 49 51 00 00       	call   801056e0 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 ff 8d 10 80 	movl   $0x80108dff,(%esp)
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
801006b2:	e8 9a 52 00 00       	call   80105951 <memmove>
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
801006e1:	e8 98 51 00 00       	call   8010587e <memset>
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
80100776:	e8 a2 6c 00 00       	call   8010741d <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 96 6c 00 00       	call   8010741d <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 8a 6c 00 00       	call   8010741d <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 7d 6c 00 00       	call   8010741d <uartputc>
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
801007ba:	e8 70 4e 00 00       	call   8010562f <acquire>
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
801007ea:	e8 de 4c 00 00       	call   801054cd <procdump>
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
801008f7:	e8 2e 4b 00 00       	call   8010542a <wakeup>
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
8010091e:	e8 6e 4d 00 00       	call   80105691 <release>
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
80100931:	e8 0c 1b 00 00       	call   80102442 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 e7 4c 00 00       	call   8010562f <acquire>
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
80100961:	e8 2b 4d 00 00       	call   80105691 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 83 19 00 00       	call   801022f4 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 c2 49 00 00       	call   80105351 <sleep>
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
80100a08:	e8 84 4c 00 00       	call   80105691 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 dc 18 00 00       	call   801022f4 <ilock>

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
80100a32:	e8 0b 1a 00 00       	call   80102442 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 ec 4b 00 00       	call   8010562f <acquire>
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
80100a78:	e8 14 4c 00 00       	call   80105691 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 6c 18 00 00       	call   801022f4 <ilock>

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
80100a93:	c7 44 24 04 03 8e 10 	movl   $0x80108e03,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 67 4b 00 00       	call   8010560e <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 0b 8e 10 	movl   $0x80108e0b,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 53 4b 00 00       	call   8010560e <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c f8 10 80 26 	movl   $0x80100a26,0x8010f82c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 f8 10 80 25 	movl   $0x80100925,0x8010f828
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 68 3a 00 00       	call   8010454d <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 09 29 00 00       	call   80103402 <ioapicenable>
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
80100b0b:	e8 86 23 00 00       	call   80102e96 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 c6 17 00 00       	call   801022f4 <ilock>
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
80100b55:	e8 90 1c 00 00       	call   801027ea <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 8b 35 10 80 	movl   $0x8010358b,(%esp)
80100b7b:	e8 e1 79 00 00       	call   80108561 <setupkvm>
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
80100bc8:	e8 1d 1c 00 00       	call   801027ea <readi>
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
80100c14:	e8 1a 7d 00 00       	call   80108933 <allocuvm>
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
80100c51:	e8 ee 7b 00 00       	call   80108844 <loaduvm>
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
80100c87:	e8 ec 18 00 00       	call   80102578 <iunlockput>
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
80100cbc:	e8 72 7c 00 00       	call   80108933 <allocuvm>
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
80100ce0:	e8 72 7e 00 00       	call   80108b57 <clearpteu>
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
80100d0f:	e8 e8 4d 00 00       	call   80105afc <strlen>
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
80100d2d:	e8 ca 4d 00 00       	call   80105afc <strlen>
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
80100d57:	e8 af 7f 00 00       	call   80108d0b <copyout>
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
80100df7:	e8 0f 7f 00 00       	call   80108d0b <copyout>
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
80100e4e:	e8 5b 4c 00 00       	call   80105aae <safestrcpy>

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
80100ea0:	e8 ad 77 00 00       	call   80108652 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 19 7c 00 00       	call   80108ac9 <freevm>
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
80100ee2:	e8 e2 7b 00 00       	call   80108ac9 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 80 16 00 00       	call   80102578 <iunlockput>
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
80100f06:	c7 44 24 04 14 8e 10 	movl   $0x80108e14,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 f4 46 00 00       	call   8010560e <initlock>
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
80100f22:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f29:	e8 01 47 00 00       	call   8010562f <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 b4 ee 10 80 	movl   $0x8010eeb4,-0xc(%ebp)
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
80100f4b:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f52:	e8 3a 47 00 00       	call   80105691 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 14 f8 10 80 	cmpl   $0x8010f814,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f70:	e8 1c 47 00 00       	call   80105691 <release>
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
80100f82:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f89:	e8 a1 46 00 00       	call   8010562f <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 1b 8e 10 80 	movl   $0x80108e1b,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 d2 46 00 00       	call   80105691 <release>
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
80100fca:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fd1:	e8 59 46 00 00       	call   8010562f <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 23 8e 10 80 	movl   $0x80108e23,(%esp)
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
80101005:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
8010100c:	e8 80 46 00 00       	call   80105691 <release>
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
8010104f:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80101056:	e8 36 46 00 00       	call   80105691 <release>
  
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
80101074:	e8 8e 37 00 00       	call   80104807 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 21 2c 00 00       	call   80103ca9 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 14 14 00 00       	call   801024a7 <iput>
    commit_trans();
80101093:	e8 5a 2c 00 00       	call   80103cf2 <commit_trans>
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
801010b3:	e8 3c 12 00 00       	call   801022f4 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 d8 16 00 00       	call   801027a5 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 67 13 00 00       	call   80102442 <iunlock>
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
80101125:	e8 5f 38 00 00       	call   80104989 <piperead>
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
8010113f:	e8 b0 11 00 00       	call   801022f4 <ilock>
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
80101165:	e8 80 16 00 00       	call   801027ea <readi>
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
8010118d:	e8 b0 12 00 00       	call   80102442 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 2d 8e 10 80 	movl   $0x80108e2d,(%esp)
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
801011e2:	e8 b2 36 00 00       	call   80104899 <pipewrite>
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
8010122a:	e8 7a 2a 00 00       	call   80103ca9 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 b7 10 00 00       	call   801022f4 <ilock>
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
80101263:	e8 ed 16 00 00       	call   80102955 <writei>
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
8010128b:	e8 b2 11 00 00       	call   80102442 <iunlock>
      commit_trans();
80101290:	e8 5d 2a 00 00       	call   80103cf2 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 36 8e 10 80 	movl   $0x80108e36,(%esp)
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
801012d8:	c7 04 24 46 8e 10 80 	movl   $0x80108e46,(%esp)
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
801012fe:	e8 aa 52 00 00       	call   801065ad <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 50 8e 10 80 	movl   $0x80108e50,(%esp)
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
80101338:	e8 b7 0f 00 00       	call   801022f4 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 68 8e 10 80 	movl   $0x80108e68,(%esp)
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
80101382:	c7 04 24 8b 8e 10 80 	movl   $0x80108e8b,(%esp)
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
801013b7:	c7 04 24 a4 8e 10 80 	movl   $0x80108ea4,(%esp)
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
80101414:	c7 04 24 c3 8e 10 80 	movl   $0x80108ec3,(%esp)
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
8010143b:	e8 02 10 00 00       	call   80102442 <iunlock>
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
8010146a:	e8 09 09 00 00       	call   80101d78 <readsb>
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
8010153e:	c7 04 24 dc 8e 10 80 	movl   $0x80108edc,(%esp)
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
{
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
{
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
801015a0:	83 ec 18             	sub    $0x18,%esp
  if(!a)
801015a3:	83 7d 20 00          	cmpl   $0x0,0x20(%ebp)
801015a7:	75 3c                	jne    801015e5 <deletedups+0x48>
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
801015c9:	eb 50                	jmp    8010161b <deletedups+0x7e>
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
801015e3:	eb 36                	jmp    8010161b <deletedups+0x7e>
  }
  else
  {
    if(!b)
801015e5:	83 7d 24 00          	cmpl   $0x0,0x24(%ebp)
801015e9:	75 1a                	jne    80101605 <deletedups+0x68>
      a[b1Index] = ip2->addrs[b2Index];
801015eb:	8b 45 18             	mov    0x18(%ebp),%eax
801015ee:	c1 e0 02             	shl    $0x2,%eax
801015f1:	03 45 20             	add    0x20(%ebp),%eax
801015f4:	8b 55 0c             	mov    0xc(%ebp),%edx
801015f7:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
801015fa:	83 c1 04             	add    $0x4,%ecx
801015fd:	8b 54 8a 0c          	mov    0xc(%edx,%ecx,4),%edx
80101601:	89 10                	mov    %edx,(%eax)
80101603:	eb 16                	jmp    8010161b <deletedups+0x7e>
    else
      a[b1Index] = b[b2Index];
80101605:	8b 45 18             	mov    0x18(%ebp),%eax
80101608:	c1 e0 02             	shl    $0x2,%eax
8010160b:	03 45 20             	add    0x20(%ebp),%eax
8010160e:	8b 55 1c             	mov    0x1c(%ebp),%edx
80101611:	c1 e2 02             	shl    $0x2,%edx
80101614:	03 55 24             	add    0x24(%ebp),%edx
80101617:	8b 12                	mov    (%edx),%edx
80101619:	89 10                	mov    %edx,(%eax)
  }
  bfree(b1->dev, b1->sector);
8010161b:	8b 45 10             	mov    0x10(%ebp),%eax
8010161e:	8b 50 08             	mov    0x8(%eax),%edx
80101621:	8b 45 10             	mov    0x10(%ebp),%eax
80101624:	8b 40 04             	mov    0x4(%eax),%eax
80101627:	89 54 24 04          	mov    %edx,0x4(%esp)
8010162b:	89 04 24             	mov    %eax,(%esp)
8010162e:	e8 33 09 00 00       	call   80101f66 <bfree>
}
80101633:	c9                   	leave  
80101634:	c3                   	ret    

80101635 <dedup>:

int
dedup(void)
{
80101635:	55                   	push   %ebp
80101636:	89 e5                	mov    %esp,%ebp
80101638:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  int fileIndex1,fileIndex2,blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0;
8010163e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101645:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
8010164c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  struct file f1, f2;
  struct inode* ip1=0, *ip2=0;
80101653:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
8010165a:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
80101661:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
80101668:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
8010166f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
80101676:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  uint *a = 0, *b = 0;
8010167d:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
80101684:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
  
  acquire(&ftable.lock);
8010168b:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80101692:	e8 98 3f 00 00       	call   8010562f <acquire>
  for(fileIndex1=0; fileIndex1 < NFILE - 1; fileIndex1++) //iterate over all the files in the system - outer file loop
80101697:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010169e:	e9 c4 06 00 00       	jmp    80101d67 <dedup+0x732>
  {
    f1 = ftable.file[fileIndex1];
801016a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016a6:	89 d0                	mov    %edx,%eax
801016a8:	01 c0                	add    %eax,%eax
801016aa:	01 d0                	add    %edx,%eax
801016ac:	c1 e0 03             	shl    $0x3,%eax
801016af:	05 b0 ee 10 80       	add    $0x8010eeb0,%eax
801016b4:	8b 50 04             	mov    0x4(%eax),%edx
801016b7:	89 55 94             	mov    %edx,-0x6c(%ebp)
801016ba:	8b 50 08             	mov    0x8(%eax),%edx
801016bd:	89 55 98             	mov    %edx,-0x68(%ebp)
801016c0:	8b 50 0c             	mov    0xc(%eax),%edx
801016c3:	89 55 9c             	mov    %edx,-0x64(%ebp)
801016c6:	8b 50 10             	mov    0x10(%eax),%edx
801016c9:	89 55 a0             	mov    %edx,-0x60(%ebp)
801016cc:	8b 50 14             	mov    0x14(%eax),%edx
801016cf:	89 55 a4             	mov    %edx,-0x5c(%ebp)
801016d2:	8b 40 18             	mov    0x18(%eax),%eax
801016d5:	89 45 a8             	mov    %eax,-0x58(%ebp)
    if(f1.ip)
801016d8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
801016db:	85 c0                	test   %eax,%eax
801016dd:	0f 84 80 06 00 00    	je     80101d63 <dedup+0x72e>
    {
      ip1 = f1.ip;				//iterate over the i-th file's blocks and look for duplicate data
801016e3:	8b 45 a4             	mov    -0x5c(%ebp),%eax
801016e6:	89 45 bc             	mov    %eax,-0x44(%ebp)
      if(ip1->addrs[NDIRECT])
801016e9:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016ec:	8b 40 4c             	mov    0x4c(%eax),%eax
801016ef:	85 c0                	test   %eax,%eax
801016f1:	74 2a                	je     8010171d <dedup+0xe8>
      {
	bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
801016f3:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016f6:	8b 50 4c             	mov    0x4c(%eax),%edx
801016f9:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016fc:	8b 00                	mov    (%eax),%eax
801016fe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101702:	89 04 24             	mov    %eax,(%esp)
80101705:	e8 9c ea ff ff       	call   801001a6 <bread>
8010170a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	a = (uint*)bp1->data;
8010170d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101710:	83 c0 18             	add    $0x18,%eax
80101713:	89 45 cc             	mov    %eax,-0x34(%ebp)
	indirects1 = NINDIRECT;
80101716:	c7 45 e0 80 00 00 00 	movl   $0x80,-0x20(%ebp)
      }
      for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
8010171d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101724:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010172b:	e9 0f 06 00 00       	jmp    80101d3f <dedup+0x70a>
      {
	if(blockIndex1<NDIRECT)							// in the same file
80101730:	83 7d ec 0b          	cmpl   $0xb,-0x14(%ebp)
80101734:	0f 8f 2d 02 00 00    	jg     80101967 <dedup+0x332>
	{
	  if(ip1->addrs[blockIndex1])
8010173a:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010173d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101740:	83 c2 04             	add    $0x4,%edx
80101743:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101747:	85 c0                	test   %eax,%eax
80101749:	0f 84 11 01 00 00    	je     80101860 <dedup+0x22b>
	  {
	    b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
8010174f:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101752:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101755:	83 c2 04             	add    $0x4,%edx
80101758:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010175c:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010175f:	8b 00                	mov    (%eax),%eax
80101761:	89 54 24 04          	mov    %edx,0x4(%esp)
80101765:	89 04 24             	mov    %eax,(%esp)
80101768:	e8 39 ea ff ff       	call   801001a6 <bread>
8010176d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	    for(blockIndex2 = NDIRECT; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to direct
80101770:	c7 45 e8 0c 00 00 00 	movl   $0xc,-0x18(%ebp)
80101777:	e9 cd 00 00 00       	jmp    80101849 <dedup+0x214>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
8010177c:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010177f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101782:	83 c2 04             	add    $0x4,%edx
80101785:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101789:	85 c0                	test   %eax,%eax
8010178b:	0f 84 b4 00 00 00    	je     80101845 <dedup+0x210>
80101791:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101794:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101797:	83 c2 04             	add    $0x4,%edx
8010179a:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010179e:	85 c0                	test   %eax,%eax
801017a0:	0f 84 9f 00 00 00    	je     80101845 <dedup+0x210>
	      {
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
801017a6:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017a9:	8b 55 e8             	mov    -0x18(%ebp),%edx
801017ac:	83 c2 04             	add    $0x4,%edx
801017af:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017b3:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017b6:	8b 00                	mov    (%eax),%eax
801017b8:	89 54 24 04          	mov    %edx,0x4(%esp)
801017bc:	89 04 24             	mov    %eax,(%esp)
801017bf:	e8 e2 e9 ff ff       	call   801001a6 <bread>
801017c4:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
801017c7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801017ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801017ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801017d1:	89 04 24             	mov    %eax,(%esp)
801017d4:	e8 7c fd ff ff       	call   80101555 <blkcmp>
801017d9:	85 c0                	test   %eax,%eax
801017db:	74 5d                	je     8010183a <dedup+0x205>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
801017dd:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
801017e4:	00 
801017e5:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
801017ec:	00 
801017ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017f0:	89 44 24 14          	mov    %eax,0x14(%esp)
801017f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017f7:	89 44 24 10          	mov    %eax,0x10(%esp)
801017fb:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801017fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101802:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101805:	89 44 24 08          	mov    %eax,0x8(%esp)
80101809:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010180c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101810:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101813:	89 04 24             	mov    %eax,(%esp)
80101816:	e8 82 fd ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
8010181b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010181e:	89 04 24             	mov    %eax,(%esp)
80101821:	e8 f1 e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101826:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101829:	89 04 24             	mov    %eax,(%esp)
8010182c:	e8 e6 e9 ff ff       	call   80100217 <brelse>
		  found = 1;
80101831:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
		  break;
80101838:	eb 1b                	jmp    80101855 <dedup+0x220>
		}
		brelse(b2);
8010183a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010183d:	89 04 24             	mov    %eax,(%esp)
80101840:	e8 d2 e9 ff ff       	call   80100217 <brelse>
	if(blockIndex1<NDIRECT)							// in the same file
	{
	  if(ip1->addrs[blockIndex1])
	  {
	    b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	    for(blockIndex2 = NDIRECT; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to direct
80101845:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
80101849:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010184c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010184f:	0f 8f 27 ff ff ff    	jg     8010177c <dedup+0x147>
	  {
	    b1 = 0;
	    continue;
	  }
	  
	  if(b1 && a && !found)
80101855:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101859:	75 11                	jne    8010186c <dedup+0x237>
8010185b:	e9 30 02 00 00       	jmp    80101a90 <dedup+0x45b>
	      }
	    }
	  }
	  else
	  {
	    b1 = 0;
80101860:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	    continue;
80101867:	e9 c8 04 00 00       	jmp    80101d34 <dedup+0x6ff>
	  }
	  
	  if(b1 && a && !found)
8010186c:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101870:	0f 84 19 02 00 00    	je     80101a8f <dedup+0x45a>
80101876:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010187a:	0f 85 0f 02 00 00    	jne    80101a8f <dedup+0x45a>
	  {
	    for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101880:	c7 45 e8 7f 00 00 00 	movl   $0x7f,-0x18(%ebp)
80101887:	e9 cc 00 00 00       	jmp    80101958 <dedup+0x323>
	    {
	      if(ip1->addrs[blockIndex1] && a[blockIndex2])
8010188c:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010188f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101892:	83 c2 04             	add    $0x4,%edx
80101895:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101899:	85 c0                	test   %eax,%eax
8010189b:	0f 84 b3 00 00 00    	je     80101954 <dedup+0x31f>
801018a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018a4:	c1 e0 02             	shl    $0x2,%eax
801018a7:	03 45 cc             	add    -0x34(%ebp),%eax
801018aa:	8b 00                	mov    (%eax),%eax
801018ac:	85 c0                	test   %eax,%eax
801018ae:	0f 84 a0 00 00 00    	je     80101954 <dedup+0x31f>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);
801018b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018b7:	c1 e0 02             	shl    $0x2,%eax
801018ba:	03 45 cc             	add    -0x34(%ebp),%eax
801018bd:	8b 10                	mov    (%eax),%edx
801018bf:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018c2:	8b 00                	mov    (%eax),%eax
801018c4:	89 54 24 04          	mov    %edx,0x4(%esp)
801018c8:	89 04 24             	mov    %eax,(%esp)
801018cb:	e8 d6 e8 ff ff       	call   801001a6 <bread>
801018d0:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
801018d3:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801018d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801018da:	8b 45 d8             	mov    -0x28(%ebp),%eax
801018dd:	89 04 24             	mov    %eax,(%esp)
801018e0:	e8 70 fc ff ff       	call   80101555 <blkcmp>
801018e5:	85 c0                	test   %eax,%eax
801018e7:	74 60                	je     80101949 <dedup+0x314>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,a);
801018e9:	8b 45 cc             	mov    -0x34(%ebp),%eax
801018ec:	89 44 24 1c          	mov    %eax,0x1c(%esp)
801018f0:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
801018f7:	00 
801018f8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018fb:	89 44 24 14          	mov    %eax,0x14(%esp)
801018ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101902:	89 44 24 10          	mov    %eax,0x10(%esp)
80101906:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101909:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010190d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101910:	89 44 24 08          	mov    %eax,0x8(%esp)
80101914:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101917:	89 44 24 04          	mov    %eax,0x4(%esp)
8010191b:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010191e:	89 04 24             	mov    %eax,(%esp)
80101921:	e8 77 fc ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101926:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101929:	89 04 24             	mov    %eax,(%esp)
8010192c:	e8 e6 e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101931:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101934:	89 04 24             	mov    %eax,(%esp)
80101937:	e8 db e8 ff ff       	call   80100217 <brelse>
		  found = 1;
8010193c:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
		  break;
80101943:	90                   	nop
80101944:	e9 47 01 00 00       	jmp    80101a90 <dedup+0x45b>
		}
		brelse(b2);
80101949:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010194c:	89 04 24             	mov    %eax,(%esp)
8010194f:	e8 c3 e8 ff ff       	call   80100217 <brelse>
	    continue;
	  }
	  
	  if(b1 && a && !found)
	  {
	    for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101954:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
80101958:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010195c:	0f 89 2a ff ff ff    	jns    8010188c <dedup+0x257>
80101962:	e9 28 01 00 00       	jmp    80101a8f <dedup+0x45a>
		brelse(b2);
	      }
	    }
	  }
	}
	else if(!found)					// in the same file
80101967:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010196b:	0f 85 1f 01 00 00    	jne    80101a90 <dedup+0x45b>
	{
	  if(a)
80101971:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101975:	0f 84 15 01 00 00    	je     80101a90 <dedup+0x45b>
	  {
	    int blockIndex1Offset = blockIndex1 - NDIRECT;
8010197b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010197e:	83 e8 0c             	sub    $0xc,%eax
80101981:	89 45 b0             	mov    %eax,-0x50(%ebp)
	    if(a[blockIndex1Offset])
80101984:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101987:	c1 e0 02             	shl    $0x2,%eax
8010198a:	03 45 cc             	add    -0x34(%ebp),%eax
8010198d:	8b 00                	mov    (%eax),%eax
8010198f:	85 c0                	test   %eax,%eax
80101991:	0f 84 ec 00 00 00    	je     80101a83 <dedup+0x44e>
	    {
	      b1 = bread(ip1->dev,a[blockIndex1Offset]);
80101997:	8b 45 b0             	mov    -0x50(%ebp),%eax
8010199a:	c1 e0 02             	shl    $0x2,%eax
8010199d:	03 45 cc             	add    -0x34(%ebp),%eax
801019a0:	8b 10                	mov    (%eax),%edx
801019a2:	8b 45 bc             	mov    -0x44(%ebp),%eax
801019a5:	8b 00                	mov    (%eax),%eax
801019a7:	89 54 24 04          	mov    %edx,0x4(%esp)
801019ab:	89 04 24             	mov    %eax,(%esp)
801019ae:	e8 f3 e7 ff ff       	call   801001a6 <bread>
801019b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	      for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
801019b6:	c7 45 e8 7f 00 00 00 	movl   $0x7f,-0x18(%ebp)
801019bd:	e9 b3 00 00 00       	jmp    80101a75 <dedup+0x440>
	      {
		if(a[blockIndex2])
801019c2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801019c5:	c1 e0 02             	shl    $0x2,%eax
801019c8:	03 45 cc             	add    -0x34(%ebp),%eax
801019cb:	8b 00                	mov    (%eax),%eax
801019cd:	85 c0                	test   %eax,%eax
801019cf:	0f 84 9c 00 00 00    	je     80101a71 <dedup+0x43c>
		{
		  b2 = bread(ip1->dev,a[blockIndex2]);
801019d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801019d8:	c1 e0 02             	shl    $0x2,%eax
801019db:	03 45 cc             	add    -0x34(%ebp),%eax
801019de:	8b 10                	mov    (%eax),%edx
801019e0:	8b 45 bc             	mov    -0x44(%ebp),%eax
801019e3:	8b 00                	mov    (%eax),%eax
801019e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801019e9:	89 04 24             	mov    %eax,(%esp)
801019ec:	e8 b5 e7 ff ff       	call   801001a6 <bread>
801019f1:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		  if(blkcmp(b1,b2))
801019f4:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801019f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801019fb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801019fe:	89 04 24             	mov    %eax,(%esp)
80101a01:	e8 4f fb ff ff       	call   80101555 <blkcmp>
80101a06:	85 c0                	test   %eax,%eax
80101a08:	74 5c                	je     80101a66 <dedup+0x431>
		  {
		    deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101a0a:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101a0d:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101a11:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101a14:	89 44 24 18          	mov    %eax,0x18(%esp)
80101a18:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101a1b:	89 44 24 14          	mov    %eax,0x14(%esp)
80101a1f:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a22:	89 44 24 10          	mov    %eax,0x10(%esp)
80101a26:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a29:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101a2d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101a30:	89 44 24 08          	mov    %eax,0x8(%esp)
80101a34:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a37:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a3b:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a3e:	89 04 24             	mov    %eax,(%esp)
80101a41:	e8 57 fb ff ff       	call   8010159d <deletedups>
		    brelse(b1);				// release the outer loop block
80101a46:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101a49:	89 04 24             	mov    %eax,(%esp)
80101a4c:	e8 c6 e7 ff ff       	call   80100217 <brelse>
		    brelse(b2);
80101a51:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a54:	89 04 24             	mov    %eax,(%esp)
80101a57:	e8 bb e7 ff ff       	call   80100217 <brelse>
		    found = 1;
80101a5c:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
		    break;
80101a63:	90                   	nop
80101a64:	eb 2a                	jmp    80101a90 <dedup+0x45b>
		  }
		  brelse(b2);
80101a66:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a69:	89 04 24             	mov    %eax,(%esp)
80101a6c:	e8 a6 e7 ff ff       	call   80100217 <brelse>
	  {
	    int blockIndex1Offset = blockIndex1 - NDIRECT;
	    if(a[blockIndex1Offset])
	    {
	      b1 = bread(ip1->dev,a[blockIndex1Offset]);
	      for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101a71:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
80101a75:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101a78:	3b 45 b0             	cmp    -0x50(%ebp),%eax
80101a7b:	0f 8f 41 ff ff ff    	jg     801019c2 <dedup+0x38d>
80101a81:	eb 0d                	jmp    80101a90 <dedup+0x45b>
		}
	      }
	    }
	    else
	    {
	      b1 = 0;
80101a83:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	      continue;
80101a8a:	e9 a5 02 00 00       	jmp    80101d34 <dedup+0x6ff>
	    continue;
	  }
	  
	  if(b1 && a && !found)
	  {
	    for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101a8f:	90                   	nop
	      continue;
	    }
	  }
	}
	
	if(!found && b1)					// in other files
80101a90:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80101a94:	0f 85 8f 02 00 00    	jne    80101d29 <dedup+0x6f4>
80101a9a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101a9e:	0f 84 85 02 00 00    	je     80101d29 <dedup+0x6f4>
	{
	  uint* aSub = 0;
80101aa4:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
	  int blockIndex1Offset = blockIndex1;
80101aab:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101aae:	89 45 c0             	mov    %eax,-0x40(%ebp)
	  if(blockIndex1 >= NDIRECT)
80101ab1:	83 7d ec 0b          	cmpl   $0xb,-0x14(%ebp)
80101ab5:	7e 0f                	jle    80101ac6 <dedup+0x491>
	  {
	    aSub = a;
80101ab7:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101aba:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	    blockIndex1Offset = blockIndex1 - NDIRECT;
80101abd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ac0:	83 e8 0c             	sub    $0xc,%eax
80101ac3:	89 45 c0             	mov    %eax,-0x40(%ebp)
	  }
	  for(fileIndex2=NFILE - 1; fileIndex2 > fileIndex1 && !found; fileIndex2--) //iterate over all the files in the system - get the next file - inner file loop
80101ac6:	c7 45 f0 63 00 00 00 	movl   $0x63,-0x10(%ebp)
80101acd:	e9 45 02 00 00       	jmp    80101d17 <dedup+0x6e2>
	  {
	    f2 = ftable.file[fileIndex2];
80101ad2:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101ad5:	89 d0                	mov    %edx,%eax
80101ad7:	01 c0                	add    %eax,%eax
80101ad9:	01 d0                	add    %edx,%eax
80101adb:	c1 e0 03             	shl    $0x3,%eax
80101ade:	05 b0 ee 10 80       	add    $0x8010eeb0,%eax
80101ae3:	8b 50 04             	mov    0x4(%eax),%edx
80101ae6:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
80101aec:	8b 50 08             	mov    0x8(%eax),%edx
80101aef:	89 55 80             	mov    %edx,-0x80(%ebp)
80101af2:	8b 50 0c             	mov    0xc(%eax),%edx
80101af5:	89 55 84             	mov    %edx,-0x7c(%ebp)
80101af8:	8b 50 10             	mov    0x10(%eax),%edx
80101afb:	89 55 88             	mov    %edx,-0x78(%ebp)
80101afe:	8b 50 14             	mov    0x14(%eax),%edx
80101b01:	89 55 8c             	mov    %edx,-0x74(%ebp)
80101b04:	8b 40 18             	mov    0x18(%eax),%eax
80101b07:	89 45 90             	mov    %eax,-0x70(%ebp)
	    if(f2.ip)
80101b0a:	8b 45 8c             	mov    -0x74(%ebp),%eax
80101b0d:	85 c0                	test   %eax,%eax
80101b0f:	0f 84 fe 01 00 00    	je     80101d13 <dedup+0x6de>
	    {
	      ip2 = f2.ip;				//iterate over the i-th file's blocks and look for duplicate data
80101b15:	8b 45 8c             	mov    -0x74(%ebp),%eax
80101b18:	89 45 b8             	mov    %eax,-0x48(%ebp)
	      if(ip2->addrs[NDIRECT])
80101b1b:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b1e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b21:	85 c0                	test   %eax,%eax
80101b23:	74 2a                	je     80101b4f <dedup+0x51a>
	      {
		bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101b25:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b28:	8b 50 4c             	mov    0x4c(%eax),%edx
80101b2b:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b2e:	8b 00                	mov    (%eax),%eax
80101b30:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b34:	89 04 24             	mov    %eax,(%esp)
80101b37:	e8 6a e6 ff ff       	call   801001a6 <bread>
80101b3c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		b = (uint*)bp2->data;
80101b3f:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101b42:	83 c0 18             	add    $0x18,%eax
80101b45:	89 45 c8             	mov    %eax,-0x38(%ebp)
		indirects2 = NINDIRECT;
80101b48:	c7 45 dc 80 00 00 00 	movl   $0x80,-0x24(%ebp)
	      }
	      
	      for(blockIndex2 = 0; blockIndex2 < NDIRECT + indirects2; blockIndex2++) 		//get the first block - outer block loop
80101b4f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80101b56:	e9 94 01 00 00       	jmp    80101cef <dedup+0x6ba>
	      {
		if(blockIndex2<NDIRECT)
80101b5b:	83 7d e8 0b          	cmpl   $0xb,-0x18(%ebp)
80101b5f:	0f 8f bb 00 00 00    	jg     80101c20 <dedup+0x5eb>
		{
		  if(ip1->addrs[blockIndex2])
80101b65:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b68:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101b6b:	83 c2 04             	add    $0x4,%edx
80101b6e:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b72:	85 c0                	test   %eax,%eax
80101b74:	0f 84 71 01 00 00    	je     80101ceb <dedup+0x6b6>
		  {
		    b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
80101b7a:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b7d:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101b80:	83 c2 04             	add    $0x4,%edx
80101b83:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101b87:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b8a:	8b 00                	mov    (%eax),%eax
80101b8c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b90:	89 04 24             	mov    %eax,(%esp)
80101b93:	e8 0e e6 ff ff       	call   801001a6 <bread>
80101b98:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		    if(blkcmp(b1,b2))
80101b9b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ba2:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101ba5:	89 04 24             	mov    %eax,(%esp)
80101ba8:	e8 a8 f9 ff ff       	call   80101555 <blkcmp>
80101bad:	85 c0                	test   %eax,%eax
80101baf:	74 5f                	je     80101c10 <dedup+0x5db>
		    {
		      deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101bb1:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101bb8:	00 
80101bb9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101bbc:	89 44 24 18          	mov    %eax,0x18(%esp)
80101bc0:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101bc3:	89 44 24 14          	mov    %eax,0x14(%esp)
80101bc7:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101bca:	89 44 24 10          	mov    %eax,0x10(%esp)
80101bce:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bd1:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101bd5:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101bd8:	89 44 24 08          	mov    %eax,0x8(%esp)
80101bdc:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101bdf:	89 44 24 04          	mov    %eax,0x4(%esp)
80101be3:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101be6:	89 04 24             	mov    %eax,(%esp)
80101be9:	e8 af f9 ff ff       	call   8010159d <deletedups>
		      brelse(b1);				// release the outer loop block
80101bee:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101bf1:	89 04 24             	mov    %eax,(%esp)
80101bf4:	e8 1e e6 ff ff       	call   80100217 <brelse>
		      brelse(b2);
80101bf9:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bfc:	89 04 24             	mov    %eax,(%esp)
80101bff:	e8 13 e6 ff ff       	call   80100217 <brelse>
		      found = 1;
80101c04:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
		      break;
80101c0b:	e9 ee 00 00 00       	jmp    80101cfe <dedup+0x6c9>
		    }
		    brelse(b2);
80101c10:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c13:	89 04 24             	mov    %eax,(%esp)
80101c16:	e8 fc e5 ff ff       	call   80100217 <brelse>
80101c1b:	e9 cb 00 00 00       	jmp    80101ceb <dedup+0x6b6>
		  }
		}
		else if(!found)
80101c20:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80101c24:	0f 85 c1 00 00 00    	jne    80101ceb <dedup+0x6b6>
		{
		  if(b)
80101c2a:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
80101c2e:	0f 84 b7 00 00 00    	je     80101ceb <dedup+0x6b6>
		  {
		    int blockIndex2Offset = blockIndex2 - NDIRECT;
80101c34:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101c37:	83 e8 0c             	sub    $0xc,%eax
80101c3a:	89 45 ac             	mov    %eax,-0x54(%ebp)
		    if(b[blockIndex2Offset])
80101c3d:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c40:	c1 e0 02             	shl    $0x2,%eax
80101c43:	03 45 c8             	add    -0x38(%ebp),%eax
80101c46:	8b 00                	mov    (%eax),%eax
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	0f 84 9b 00 00 00    	je     80101ceb <dedup+0x6b6>
		    {
		      b2 = bread(ip1->dev,b[blockIndex2Offset]);
80101c50:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c53:	c1 e0 02             	shl    $0x2,%eax
80101c56:	03 45 c8             	add    -0x38(%ebp),%eax
80101c59:	8b 10                	mov    (%eax),%edx
80101c5b:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c5e:	8b 00                	mov    (%eax),%eax
80101c60:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c64:	89 04 24             	mov    %eax,(%esp)
80101c67:	e8 3a e5 ff ff       	call   801001a6 <bread>
80101c6c:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		      if(blkcmp(b1,b2))
80101c6f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c72:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c76:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101c79:	89 04 24             	mov    %eax,(%esp)
80101c7c:	e8 d4 f8 ff ff       	call   80101555 <blkcmp>
80101c81:	85 c0                	test   %eax,%eax
80101c83:	74 5b                	je     80101ce0 <dedup+0x6ab>
		      {
			deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101c85:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c88:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101c8c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101c8f:	89 44 24 18          	mov    %eax,0x18(%esp)
80101c93:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c96:	89 44 24 14          	mov    %eax,0x14(%esp)
80101c9a:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101c9d:	89 44 24 10          	mov    %eax,0x10(%esp)
80101ca1:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101ca4:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101ca8:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101cab:	89 44 24 08          	mov    %eax,0x8(%esp)
80101caf:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cb2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cb6:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101cb9:	89 04 24             	mov    %eax,(%esp)
80101cbc:	e8 dc f8 ff ff       	call   8010159d <deletedups>
			brelse(b1);				// release the outer loop block
80101cc1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101cc4:	89 04 24             	mov    %eax,(%esp)
80101cc7:	e8 4b e5 ff ff       	call   80100217 <brelse>
			brelse(b2);
80101ccc:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101ccf:	89 04 24             	mov    %eax,(%esp)
80101cd2:	e8 40 e5 ff ff       	call   80100217 <brelse>
			found = 1;
80101cd7:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
			break;
80101cde:	eb 1e                	jmp    80101cfe <dedup+0x6c9>
		      }
		      brelse(b2);
80101ce0:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101ce3:	89 04 24             	mov    %eax,(%esp)
80101ce6:	e8 2c e5 ff ff       	call   80100217 <brelse>
		bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
		b = (uint*)bp2->data;
		indirects2 = NINDIRECT;
	      }
	      
	      for(blockIndex2 = 0; blockIndex2 < NDIRECT + indirects2; blockIndex2++) 		//get the first block - outer block loop
80101ceb:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
80101cef:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101cf2:	83 c0 0c             	add    $0xc,%eax
80101cf5:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80101cf8:	0f 8f 5d fe ff ff    	jg     80101b5b <dedup+0x526>
		    }
		  }
		}
	      }
	      
	      if(ip2->addrs[NDIRECT])
80101cfe:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d01:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d04:	85 c0                	test   %eax,%eax
80101d06:	74 0b                	je     80101d13 <dedup+0x6de>
		brelse(bp2);
80101d08:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101d0b:	89 04 24             	mov    %eax,(%esp)
80101d0e:	e8 04 e5 ff ff       	call   80100217 <brelse>
	  if(blockIndex1 >= NDIRECT)
	  {
	    aSub = a;
	    blockIndex1Offset = blockIndex1 - NDIRECT;
	  }
	  for(fileIndex2=NFILE - 1; fileIndex2 > fileIndex1 && !found; fileIndex2--) //iterate over all the files in the system - get the next file - inner file loop
80101d13:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101d17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d1a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101d1d:	7e 0a                	jle    80101d29 <dedup+0x6f4>
80101d1f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80101d23:	0f 84 a9 fd ff ff    	je     80101ad2 <dedup+0x49d>
	      if(ip2->addrs[NDIRECT])
		brelse(bp2);
	    }
	  }
	}	  
	brelse(b1);				// release the outer loop block
80101d29:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101d2c:	89 04 24             	mov    %eax,(%esp)
80101d2f:	e8 e3 e4 ff ff       	call   80100217 <brelse>
      {
	bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
	a = (uint*)bp1->data;
	indirects1 = NINDIRECT;
      }
      for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101d34:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80101d38:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101d3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101d42:	83 c0 0c             	add    $0xc,%eax
80101d45:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101d48:	0f 8f e2 f9 ff ff    	jg     80101730 <dedup+0xfb>
	  }
	}	  
	brelse(b1);				// release the outer loop block
      }
      
      if(ip1->addrs[NDIRECT])
80101d4e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d51:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d54:	85 c0                	test   %eax,%eax
80101d56:	74 0b                	je     80101d63 <dedup+0x72e>
	brelse(bp1);
80101d58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101d5b:	89 04 24             	mov    %eax,(%esp)
80101d5e:	e8 b4 e4 ff ff       	call   80100217 <brelse>
  struct inode* ip1=0, *ip2=0;
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
  uint *a = 0, *b = 0;
  
  acquire(&ftable.lock);
  for(fileIndex1=0; fileIndex1 < NFILE - 1; fileIndex1++) //iterate over all the files in the system - outer file loop
80101d63:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d67:	83 7d f4 62          	cmpl   $0x62,-0xc(%ebp)
80101d6b:	0f 8e 32 f9 ff ff    	jle    801016a3 <dedup+0x6e>
      if(ip1->addrs[NDIRECT])
	brelse(bp1);
    }
  }
    
  return 0;		
80101d71:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101d76:	c9                   	leave  
80101d77:	c3                   	ret    

80101d78 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101d78:	55                   	push   %ebp
80101d79:	89 e5                	mov    %esp,%ebp
80101d7b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101d7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d81:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101d88:	00 
80101d89:	89 04 24             	mov    %eax,(%esp)
80101d8c:	e8 15 e4 ff ff       	call   801001a6 <bread>
80101d91:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d97:	83 c0 18             	add    $0x18,%eax
80101d9a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101da1:	00 
80101da2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101da6:	8b 45 0c             	mov    0xc(%ebp),%eax
80101da9:	89 04 24             	mov    %eax,(%esp)
80101dac:	e8 a0 3b 00 00       	call   80105951 <memmove>
  brelse(bp);
80101db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101db4:	89 04 24             	mov    %eax,(%esp)
80101db7:	e8 5b e4 ff ff       	call   80100217 <brelse>
}
80101dbc:	c9                   	leave  
80101dbd:	c3                   	ret    

80101dbe <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101dbe:	55                   	push   %ebp
80101dbf:	89 e5                	mov    %esp,%ebp
80101dc1:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101dc4:	8b 55 0c             	mov    0xc(%ebp),%edx
80101dc7:	8b 45 08             	mov    0x8(%ebp),%eax
80101dca:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dce:	89 04 24             	mov    %eax,(%esp)
80101dd1:	e8 d0 e3 ff ff       	call   801001a6 <bread>
80101dd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ddc:	83 c0 18             	add    $0x18,%eax
80101ddf:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101de6:	00 
80101de7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101dee:	00 
80101def:	89 04 24             	mov    %eax,(%esp)
80101df2:	e8 87 3a 00 00       	call   8010587e <memset>
  log_write(bp);
80101df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dfa:	89 04 24             	mov    %eax,(%esp)
80101dfd:	e8 48 1f 00 00       	call   80103d4a <log_write>
  brelse(bp);
80101e02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e05:	89 04 24             	mov    %eax,(%esp)
80101e08:	e8 0a e4 ff ff       	call   80100217 <brelse>
}
80101e0d:	c9                   	leave  
80101e0e:	c3                   	ret    

80101e0f <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101e0f:	55                   	push   %ebp
80101e10:	89 e5                	mov    %esp,%ebp
80101e12:	53                   	push   %ebx
80101e13:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101e16:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101e1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e20:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101e23:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e27:	89 04 24             	mov    %eax,(%esp)
80101e2a:	e8 49 ff ff ff       	call   80101d78 <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101e2f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e36:	e9 11 01 00 00       	jmp    80101f4c <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e3e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101e44:	85 c0                	test   %eax,%eax
80101e46:	0f 48 c2             	cmovs  %edx,%eax
80101e49:	c1 f8 0c             	sar    $0xc,%eax
80101e4c:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101e4f:	c1 ea 03             	shr    $0x3,%edx
80101e52:	01 d0                	add    %edx,%eax
80101e54:	83 c0 03             	add    $0x3,%eax
80101e57:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5e:	89 04 24             	mov    %eax,(%esp)
80101e61:	e8 40 e3 ff ff       	call   801001a6 <bread>
80101e66:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101e69:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e70:	e9 a7 00 00 00       	jmp    80101f1c <balloc+0x10d>
      m = 1 << (bi % 8);
80101e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e78:	89 c2                	mov    %eax,%edx
80101e7a:	c1 fa 1f             	sar    $0x1f,%edx
80101e7d:	c1 ea 1d             	shr    $0x1d,%edx
80101e80:	01 d0                	add    %edx,%eax
80101e82:	83 e0 07             	and    $0x7,%eax
80101e85:	29 d0                	sub    %edx,%eax
80101e87:	ba 01 00 00 00       	mov    $0x1,%edx
80101e8c:	89 d3                	mov    %edx,%ebx
80101e8e:	89 c1                	mov    %eax,%ecx
80101e90:	d3 e3                	shl    %cl,%ebx
80101e92:	89 d8                	mov    %ebx,%eax
80101e94:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101e97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e9a:	8d 50 07             	lea    0x7(%eax),%edx
80101e9d:	85 c0                	test   %eax,%eax
80101e9f:	0f 48 c2             	cmovs  %edx,%eax
80101ea2:	c1 f8 03             	sar    $0x3,%eax
80101ea5:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ea8:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101ead:	0f b6 c0             	movzbl %al,%eax
80101eb0:	23 45 e8             	and    -0x18(%ebp),%eax
80101eb3:	85 c0                	test   %eax,%eax
80101eb5:	75 61                	jne    80101f18 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101eb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eba:	8d 50 07             	lea    0x7(%eax),%edx
80101ebd:	85 c0                	test   %eax,%eax
80101ebf:	0f 48 c2             	cmovs  %edx,%eax
80101ec2:	c1 f8 03             	sar    $0x3,%eax
80101ec5:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ec8:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101ecd:	89 d1                	mov    %edx,%ecx
80101ecf:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101ed2:	09 ca                	or     %ecx,%edx
80101ed4:	89 d1                	mov    %edx,%ecx
80101ed6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ed9:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101edd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ee0:	89 04 24             	mov    %eax,(%esp)
80101ee3:	e8 62 1e 00 00       	call   80103d4a <log_write>
        brelse(bp);
80101ee8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eeb:	89 04 24             	mov    %eax,(%esp)
80101eee:	e8 24 e3 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101ef3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ef6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ef9:	01 c2                	add    %eax,%edx
80101efb:	8b 45 08             	mov    0x8(%ebp),%eax
80101efe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f02:	89 04 24             	mov    %eax,(%esp)
80101f05:	e8 b4 fe ff ff       	call   80101dbe <bzero>
        return b + bi;
80101f0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f10:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80101f12:	83 c4 34             	add    $0x34,%esp
80101f15:	5b                   	pop    %ebx
80101f16:	5d                   	pop    %ebp
80101f17:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101f18:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101f1c:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101f23:	7f 15                	jg     80101f3a <balloc+0x12b>
80101f25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f28:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f2b:	01 d0                	add    %edx,%eax
80101f2d:	89 c2                	mov    %eax,%edx
80101f2f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101f32:	39 c2                	cmp    %eax,%edx
80101f34:	0f 82 3b ff ff ff    	jb     80101e75 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101f3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f3d:	89 04 24             	mov    %eax,(%esp)
80101f40:	e8 d2 e2 ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101f45:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101f4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101f52:	39 c2                	cmp    %eax,%edx
80101f54:	0f 82 e1 fe ff ff    	jb     80101e3b <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101f5a:	c7 04 24 f5 8e 10 80 	movl   $0x80108ef5,(%esp)
80101f61:	e8 d7 e5 ff ff       	call   8010053d <panic>

80101f66 <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
80101f66:	55                   	push   %ebp
80101f67:	89 e5                	mov    %esp,%ebp
80101f69:	53                   	push   %ebx
80101f6a:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101f6d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101f70:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f74:	8b 45 08             	mov    0x8(%ebp),%eax
80101f77:	89 04 24             	mov    %eax,(%esp)
80101f7a:	e8 f9 fd ff ff       	call   80101d78 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101f7f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f82:	89 c2                	mov    %eax,%edx
80101f84:	c1 ea 0c             	shr    $0xc,%edx
80101f87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f8a:	c1 e8 03             	shr    $0x3,%eax
80101f8d:	01 d0                	add    %edx,%eax
80101f8f:	8d 50 03             	lea    0x3(%eax),%edx
80101f92:	8b 45 08             	mov    0x8(%ebp),%eax
80101f95:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f99:	89 04 24             	mov    %eax,(%esp)
80101f9c:	e8 05 e2 ff ff       	call   801001a6 <bread>
80101fa1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fa7:	25 ff 0f 00 00       	and    $0xfff,%eax
80101fac:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101faf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fb2:	89 c2                	mov    %eax,%edx
80101fb4:	c1 fa 1f             	sar    $0x1f,%edx
80101fb7:	c1 ea 1d             	shr    $0x1d,%edx
80101fba:	01 d0                	add    %edx,%eax
80101fbc:	83 e0 07             	and    $0x7,%eax
80101fbf:	29 d0                	sub    %edx,%eax
80101fc1:	ba 01 00 00 00       	mov    $0x1,%edx
80101fc6:	89 d3                	mov    %edx,%ebx
80101fc8:	89 c1                	mov    %eax,%ecx
80101fca:	d3 e3                	shl    %cl,%ebx
80101fcc:	89 d8                	mov    %ebx,%eax
80101fce:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101fd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fd4:	8d 50 07             	lea    0x7(%eax),%edx
80101fd7:	85 c0                	test   %eax,%eax
80101fd9:	0f 48 c2             	cmovs  %edx,%eax
80101fdc:	c1 f8 03             	sar    $0x3,%eax
80101fdf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101fe2:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101fe7:	0f b6 c0             	movzbl %al,%eax
80101fea:	23 45 ec             	and    -0x14(%ebp),%eax
80101fed:	85 c0                	test   %eax,%eax
80101fef:	75 0c                	jne    80101ffd <bfree+0x97>
    panic("freeing free block");
80101ff1:	c7 04 24 0b 8f 10 80 	movl   $0x80108f0b,(%esp)
80101ff8:	e8 40 e5 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	8d 50 07             	lea    0x7(%eax),%edx
80102003:	85 c0                	test   %eax,%eax
80102005:	0f 48 c2             	cmovs  %edx,%eax
80102008:	c1 f8 03             	sar    $0x3,%eax
8010200b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010200e:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102013:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80102016:	f7 d1                	not    %ecx
80102018:	21 ca                	and    %ecx,%edx
8010201a:	89 d1                	mov    %edx,%ecx
8010201c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010201f:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80102023:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102026:	89 04 24             	mov    %eax,(%esp)
80102029:	e8 1c 1d 00 00       	call   80103d4a <log_write>
  brelse(bp);
8010202e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102031:	89 04 24             	mov    %eax,(%esp)
80102034:	e8 de e1 ff ff       	call   80100217 <brelse>
}
80102039:	83 c4 34             	add    $0x34,%esp
8010203c:	5b                   	pop    %ebx
8010203d:	5d                   	pop    %ebp
8010203e:	c3                   	ret    

8010203f <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010203f:	55                   	push   %ebp
80102040:	89 e5                	mov    %esp,%ebp
80102042:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80102045:	c7 44 24 04 1e 8f 10 	movl   $0x80108f1e,0x4(%esp)
8010204c:	80 
8010204d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102054:	e8 b5 35 00 00       	call   8010560e <initlock>
}
80102059:	c9                   	leave  
8010205a:	c3                   	ret    

8010205b <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010205b:	55                   	push   %ebp
8010205c:	89 e5                	mov    %esp,%ebp
8010205e:	83 ec 48             	sub    $0x48,%esp
80102061:	8b 45 0c             	mov    0xc(%ebp),%eax
80102064:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80102068:	8b 45 08             	mov    0x8(%ebp),%eax
8010206b:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010206e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102072:	89 04 24             	mov    %eax,(%esp)
80102075:	e8 fe fc ff ff       	call   80101d78 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010207a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102081:	e9 98 00 00 00       	jmp    8010211e <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80102086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102089:	c1 e8 03             	shr    $0x3,%eax
8010208c:	83 c0 02             	add    $0x2,%eax
8010208f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102093:	8b 45 08             	mov    0x8(%ebp),%eax
80102096:	89 04 24             	mov    %eax,(%esp)
80102099:	e8 08 e1 ff ff       	call   801001a6 <bread>
8010209e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801020a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020a4:	8d 50 18             	lea    0x18(%eax),%edx
801020a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020aa:	83 e0 07             	and    $0x7,%eax
801020ad:	c1 e0 06             	shl    $0x6,%eax
801020b0:	01 d0                	add    %edx,%eax
801020b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801020b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020b8:	0f b7 00             	movzwl (%eax),%eax
801020bb:	66 85 c0             	test   %ax,%ax
801020be:	75 4f                	jne    8010210f <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801020c0:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801020c7:	00 
801020c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801020cf:	00 
801020d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020d3:	89 04 24             	mov    %eax,(%esp)
801020d6:	e8 a3 37 00 00       	call   8010587e <memset>
      dip->type = type;
801020db:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020de:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801020e2:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801020e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e8:	89 04 24             	mov    %eax,(%esp)
801020eb:	e8 5a 1c 00 00       	call   80103d4a <log_write>
      brelse(bp);
801020f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020f3:	89 04 24             	mov    %eax,(%esp)
801020f6:	e8 1c e1 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801020fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102102:	8b 45 08             	mov    0x8(%ebp),%eax
80102105:	89 04 24             	mov    %eax,(%esp)
80102108:	e8 e3 00 00 00       	call   801021f0 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
8010210d:	c9                   	leave  
8010210e:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010210f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102112:	89 04 24             	mov    %eax,(%esp)
80102115:	e8 fd e0 ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010211a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010211e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102121:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102124:	39 c2                	cmp    %eax,%edx
80102126:	0f 82 5a ff ff ff    	jb     80102086 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010212c:	c7 04 24 25 8f 10 80 	movl   $0x80108f25,(%esp)
80102133:	e8 05 e4 ff ff       	call   8010053d <panic>

80102138 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80102138:	55                   	push   %ebp
80102139:	89 e5                	mov    %esp,%ebp
8010213b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010213e:	8b 45 08             	mov    0x8(%ebp),%eax
80102141:	8b 40 04             	mov    0x4(%eax),%eax
80102144:	c1 e8 03             	shr    $0x3,%eax
80102147:	8d 50 02             	lea    0x2(%eax),%edx
8010214a:	8b 45 08             	mov    0x8(%ebp),%eax
8010214d:	8b 00                	mov    (%eax),%eax
8010214f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102153:	89 04 24             	mov    %eax,(%esp)
80102156:	e8 4b e0 ff ff       	call   801001a6 <bread>
8010215b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010215e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102161:	8d 50 18             	lea    0x18(%eax),%edx
80102164:	8b 45 08             	mov    0x8(%ebp),%eax
80102167:	8b 40 04             	mov    0x4(%eax),%eax
8010216a:	83 e0 07             	and    $0x7,%eax
8010216d:	c1 e0 06             	shl    $0x6,%eax
80102170:	01 d0                	add    %edx,%eax
80102172:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80102175:	8b 45 08             	mov    0x8(%ebp),%eax
80102178:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010217c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010217f:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80102182:	8b 45 08             	mov    0x8(%ebp),%eax
80102185:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80102189:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010218c:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102190:	8b 45 08             	mov    0x8(%ebp),%eax
80102193:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80102197:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010219a:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010219e:	8b 45 08             	mov    0x8(%ebp),%eax
801021a1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801021a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021a8:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801021ac:	8b 45 08             	mov    0x8(%ebp),%eax
801021af:	8b 50 18             	mov    0x18(%eax),%edx
801021b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b5:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801021b8:	8b 45 08             	mov    0x8(%ebp),%eax
801021bb:	8d 50 1c             	lea    0x1c(%eax),%edx
801021be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c1:	83 c0 0c             	add    $0xc,%eax
801021c4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801021cb:	00 
801021cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801021d0:	89 04 24             	mov    %eax,(%esp)
801021d3:	e8 79 37 00 00       	call   80105951 <memmove>
  log_write(bp);
801021d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021db:	89 04 24             	mov    %eax,(%esp)
801021de:	e8 67 1b 00 00       	call   80103d4a <log_write>
  brelse(bp);
801021e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021e6:	89 04 24             	mov    %eax,(%esp)
801021e9:	e8 29 e0 ff ff       	call   80100217 <brelse>
}
801021ee:	c9                   	leave  
801021ef:	c3                   	ret    

801021f0 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801021f0:	55                   	push   %ebp
801021f1:	89 e5                	mov    %esp,%ebp
801021f3:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801021f6:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801021fd:	e8 2d 34 00 00       	call   8010562f <acquire>

  // Is the inode already cached?
  empty = 0;
80102202:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102209:	c7 45 f4 b4 f8 10 80 	movl   $0x8010f8b4,-0xc(%ebp)
80102210:	eb 59                	jmp    8010226b <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80102212:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102215:	8b 40 08             	mov    0x8(%eax),%eax
80102218:	85 c0                	test   %eax,%eax
8010221a:	7e 35                	jle    80102251 <iget+0x61>
8010221c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010221f:	8b 00                	mov    (%eax),%eax
80102221:	3b 45 08             	cmp    0x8(%ebp),%eax
80102224:	75 2b                	jne    80102251 <iget+0x61>
80102226:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102229:	8b 40 04             	mov    0x4(%eax),%eax
8010222c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010222f:	75 20                	jne    80102251 <iget+0x61>
      ip->ref++;
80102231:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102234:	8b 40 08             	mov    0x8(%eax),%eax
80102237:	8d 50 01             	lea    0x1(%eax),%edx
8010223a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010223d:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102240:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102247:	e8 45 34 00 00       	call   80105691 <release>
      return ip;
8010224c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010224f:	eb 6f                	jmp    801022c0 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102251:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102255:	75 10                	jne    80102267 <iget+0x77>
80102257:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010225a:	8b 40 08             	mov    0x8(%eax),%eax
8010225d:	85 c0                	test   %eax,%eax
8010225f:	75 06                	jne    80102267 <iget+0x77>
      empty = ip;
80102261:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102264:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102267:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010226b:	81 7d f4 54 08 11 80 	cmpl   $0x80110854,-0xc(%ebp)
80102272:	72 9e                	jb     80102212 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80102274:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102278:	75 0c                	jne    80102286 <iget+0x96>
    panic("iget: no inodes");
8010227a:	c7 04 24 37 8f 10 80 	movl   $0x80108f37,(%esp)
80102281:	e8 b7 e2 ff ff       	call   8010053d <panic>

  ip = empty;
80102286:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102289:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010228c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010228f:	8b 55 08             	mov    0x8(%ebp),%edx
80102292:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80102294:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102297:	8b 55 0c             	mov    0xc(%ebp),%edx
8010229a:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010229d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022a0:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801022a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022aa:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801022b1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022b8:	e8 d4 33 00 00       	call   80105691 <release>

  return ip;
801022bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801022c0:	c9                   	leave  
801022c1:	c3                   	ret    

801022c2 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801022c2:	55                   	push   %ebp
801022c3:	89 e5                	mov    %esp,%ebp
801022c5:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801022c8:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022cf:	e8 5b 33 00 00       	call   8010562f <acquire>
  ip->ref++;
801022d4:	8b 45 08             	mov    0x8(%ebp),%eax
801022d7:	8b 40 08             	mov    0x8(%eax),%eax
801022da:	8d 50 01             	lea    0x1(%eax),%edx
801022dd:	8b 45 08             	mov    0x8(%ebp),%eax
801022e0:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801022e3:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022ea:	e8 a2 33 00 00       	call   80105691 <release>
  return ip;
801022ef:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022f2:	c9                   	leave  
801022f3:	c3                   	ret    

801022f4 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801022f4:	55                   	push   %ebp
801022f5:	89 e5                	mov    %esp,%ebp
801022f7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801022fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801022fe:	74 0a                	je     8010230a <ilock+0x16>
80102300:	8b 45 08             	mov    0x8(%ebp),%eax
80102303:	8b 40 08             	mov    0x8(%eax),%eax
80102306:	85 c0                	test   %eax,%eax
80102308:	7f 0c                	jg     80102316 <ilock+0x22>
    panic("ilock");
8010230a:	c7 04 24 47 8f 10 80 	movl   $0x80108f47,(%esp)
80102311:	e8 27 e2 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102316:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010231d:	e8 0d 33 00 00       	call   8010562f <acquire>
  while(ip->flags & I_BUSY)
80102322:	eb 13                	jmp    80102337 <ilock+0x43>
    sleep(ip, &icache.lock);
80102324:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010232b:	80 
8010232c:	8b 45 08             	mov    0x8(%ebp),%eax
8010232f:	89 04 24             	mov    %eax,(%esp)
80102332:	e8 1a 30 00 00       	call   80105351 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80102337:	8b 45 08             	mov    0x8(%ebp),%eax
8010233a:	8b 40 0c             	mov    0xc(%eax),%eax
8010233d:	83 e0 01             	and    $0x1,%eax
80102340:	84 c0                	test   %al,%al
80102342:	75 e0                	jne    80102324 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80102344:	8b 45 08             	mov    0x8(%ebp),%eax
80102347:	8b 40 0c             	mov    0xc(%eax),%eax
8010234a:	89 c2                	mov    %eax,%edx
8010234c:	83 ca 01             	or     $0x1,%edx
8010234f:	8b 45 08             	mov    0x8(%ebp),%eax
80102352:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80102355:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010235c:	e8 30 33 00 00       	call   80105691 <release>

  if(!(ip->flags & I_VALID)){
80102361:	8b 45 08             	mov    0x8(%ebp),%eax
80102364:	8b 40 0c             	mov    0xc(%eax),%eax
80102367:	83 e0 02             	and    $0x2,%eax
8010236a:	85 c0                	test   %eax,%eax
8010236c:	0f 85 ce 00 00 00    	jne    80102440 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80102372:	8b 45 08             	mov    0x8(%ebp),%eax
80102375:	8b 40 04             	mov    0x4(%eax),%eax
80102378:	c1 e8 03             	shr    $0x3,%eax
8010237b:	8d 50 02             	lea    0x2(%eax),%edx
8010237e:	8b 45 08             	mov    0x8(%ebp),%eax
80102381:	8b 00                	mov    (%eax),%eax
80102383:	89 54 24 04          	mov    %edx,0x4(%esp)
80102387:	89 04 24             	mov    %eax,(%esp)
8010238a:	e8 17 de ff ff       	call   801001a6 <bread>
8010238f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80102392:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102395:	8d 50 18             	lea    0x18(%eax),%edx
80102398:	8b 45 08             	mov    0x8(%ebp),%eax
8010239b:	8b 40 04             	mov    0x4(%eax),%eax
8010239e:	83 e0 07             	and    $0x7,%eax
801023a1:	c1 e0 06             	shl    $0x6,%eax
801023a4:	01 d0                	add    %edx,%eax
801023a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801023a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ac:	0f b7 10             	movzwl (%eax),%edx
801023af:	8b 45 08             	mov    0x8(%ebp),%eax
801023b2:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801023b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023b9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801023bd:	8b 45 08             	mov    0x8(%ebp),%eax
801023c0:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801023c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c7:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801023cb:	8b 45 08             	mov    0x8(%ebp),%eax
801023ce:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801023d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023d5:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801023d9:	8b 45 08             	mov    0x8(%ebp),%eax
801023dc:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801023e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023e3:	8b 50 08             	mov    0x8(%eax),%edx
801023e6:	8b 45 08             	mov    0x8(%ebp),%eax
801023e9:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801023ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ef:	8d 50 0c             	lea    0xc(%eax),%edx
801023f2:	8b 45 08             	mov    0x8(%ebp),%eax
801023f5:	83 c0 1c             	add    $0x1c,%eax
801023f8:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801023ff:	00 
80102400:	89 54 24 04          	mov    %edx,0x4(%esp)
80102404:	89 04 24             	mov    %eax,(%esp)
80102407:	e8 45 35 00 00       	call   80105951 <memmove>
    brelse(bp);
8010240c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010240f:	89 04 24             	mov    %eax,(%esp)
80102412:	e8 00 de ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80102417:	8b 45 08             	mov    0x8(%ebp),%eax
8010241a:	8b 40 0c             	mov    0xc(%eax),%eax
8010241d:	89 c2                	mov    %eax,%edx
8010241f:	83 ca 02             	or     $0x2,%edx
80102422:	8b 45 08             	mov    0x8(%ebp),%eax
80102425:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80102428:	8b 45 08             	mov    0x8(%ebp),%eax
8010242b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010242f:	66 85 c0             	test   %ax,%ax
80102432:	75 0c                	jne    80102440 <ilock+0x14c>
      panic("ilock: no type");
80102434:	c7 04 24 4d 8f 10 80 	movl   $0x80108f4d,(%esp)
8010243b:	e8 fd e0 ff ff       	call   8010053d <panic>
  }
}
80102440:	c9                   	leave  
80102441:	c3                   	ret    

80102442 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80102442:	55                   	push   %ebp
80102443:	89 e5                	mov    %esp,%ebp
80102445:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102448:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010244c:	74 17                	je     80102465 <iunlock+0x23>
8010244e:	8b 45 08             	mov    0x8(%ebp),%eax
80102451:	8b 40 0c             	mov    0xc(%eax),%eax
80102454:	83 e0 01             	and    $0x1,%eax
80102457:	85 c0                	test   %eax,%eax
80102459:	74 0a                	je     80102465 <iunlock+0x23>
8010245b:	8b 45 08             	mov    0x8(%ebp),%eax
8010245e:	8b 40 08             	mov    0x8(%eax),%eax
80102461:	85 c0                	test   %eax,%eax
80102463:	7f 0c                	jg     80102471 <iunlock+0x2f>
    panic("iunlock");
80102465:	c7 04 24 5c 8f 10 80 	movl   $0x80108f5c,(%esp)
8010246c:	e8 cc e0 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102471:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102478:	e8 b2 31 00 00       	call   8010562f <acquire>
  ip->flags &= ~I_BUSY;
8010247d:	8b 45 08             	mov    0x8(%ebp),%eax
80102480:	8b 40 0c             	mov    0xc(%eax),%eax
80102483:	89 c2                	mov    %eax,%edx
80102485:	83 e2 fe             	and    $0xfffffffe,%edx
80102488:	8b 45 08             	mov    0x8(%ebp),%eax
8010248b:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
8010248e:	8b 45 08             	mov    0x8(%ebp),%eax
80102491:	89 04 24             	mov    %eax,(%esp)
80102494:	e8 91 2f 00 00       	call   8010542a <wakeup>
  release(&icache.lock);
80102499:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801024a0:	e8 ec 31 00 00       	call   80105691 <release>
}
801024a5:	c9                   	leave  
801024a6:	c3                   	ret    

801024a7 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
801024a7:	55                   	push   %ebp
801024a8:	89 e5                	mov    %esp,%ebp
801024aa:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801024ad:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801024b4:	e8 76 31 00 00       	call   8010562f <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801024b9:	8b 45 08             	mov    0x8(%ebp),%eax
801024bc:	8b 40 08             	mov    0x8(%eax),%eax
801024bf:	83 f8 01             	cmp    $0x1,%eax
801024c2:	0f 85 93 00 00 00    	jne    8010255b <iput+0xb4>
801024c8:	8b 45 08             	mov    0x8(%ebp),%eax
801024cb:	8b 40 0c             	mov    0xc(%eax),%eax
801024ce:	83 e0 02             	and    $0x2,%eax
801024d1:	85 c0                	test   %eax,%eax
801024d3:	0f 84 82 00 00 00    	je     8010255b <iput+0xb4>
801024d9:	8b 45 08             	mov    0x8(%ebp),%eax
801024dc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801024e0:	66 85 c0             	test   %ax,%ax
801024e3:	75 76                	jne    8010255b <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801024e5:	8b 45 08             	mov    0x8(%ebp),%eax
801024e8:	8b 40 0c             	mov    0xc(%eax),%eax
801024eb:	83 e0 01             	and    $0x1,%eax
801024ee:	84 c0                	test   %al,%al
801024f0:	74 0c                	je     801024fe <iput+0x57>
      panic("iput busy");
801024f2:	c7 04 24 64 8f 10 80 	movl   $0x80108f64,(%esp)
801024f9:	e8 3f e0 ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801024fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102501:	8b 40 0c             	mov    0xc(%eax),%eax
80102504:	89 c2                	mov    %eax,%edx
80102506:	83 ca 01             	or     $0x1,%edx
80102509:	8b 45 08             	mov    0x8(%ebp),%eax
8010250c:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
8010250f:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102516:	e8 76 31 00 00       	call   80105691 <release>
    itrunc(ip);
8010251b:	8b 45 08             	mov    0x8(%ebp),%eax
8010251e:	89 04 24             	mov    %eax,(%esp)
80102521:	e8 72 01 00 00       	call   80102698 <itrunc>
    ip->type = 0;
80102526:	8b 45 08             	mov    0x8(%ebp),%eax
80102529:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
8010252f:	8b 45 08             	mov    0x8(%ebp),%eax
80102532:	89 04 24             	mov    %eax,(%esp)
80102535:	e8 fe fb ff ff       	call   80102138 <iupdate>
    acquire(&icache.lock);
8010253a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102541:	e8 e9 30 00 00       	call   8010562f <acquire>
    ip->flags = 0;
80102546:	8b 45 08             	mov    0x8(%ebp),%eax
80102549:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102550:	8b 45 08             	mov    0x8(%ebp),%eax
80102553:	89 04 24             	mov    %eax,(%esp)
80102556:	e8 cf 2e 00 00       	call   8010542a <wakeup>
  }
  ip->ref--;
8010255b:	8b 45 08             	mov    0x8(%ebp),%eax
8010255e:	8b 40 08             	mov    0x8(%eax),%eax
80102561:	8d 50 ff             	lea    -0x1(%eax),%edx
80102564:	8b 45 08             	mov    0x8(%ebp),%eax
80102567:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010256a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102571:	e8 1b 31 00 00       	call   80105691 <release>
}
80102576:	c9                   	leave  
80102577:	c3                   	ret    

80102578 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102578:	55                   	push   %ebp
80102579:	89 e5                	mov    %esp,%ebp
8010257b:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
8010257e:	8b 45 08             	mov    0x8(%ebp),%eax
80102581:	89 04 24             	mov    %eax,(%esp)
80102584:	e8 b9 fe ff ff       	call   80102442 <iunlock>
  iput(ip);
80102589:	8b 45 08             	mov    0x8(%ebp),%eax
8010258c:	89 04 24             	mov    %eax,(%esp)
8010258f:	e8 13 ff ff ff       	call   801024a7 <iput>
}
80102594:	c9                   	leave  
80102595:	c3                   	ret    

80102596 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80102596:	55                   	push   %ebp
80102597:	89 e5                	mov    %esp,%ebp
80102599:	53                   	push   %ebx
8010259a:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
8010259d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
801025a1:	77 3e                	ja     801025e1 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
801025a3:	8b 45 08             	mov    0x8(%ebp),%eax
801025a6:	8b 55 0c             	mov    0xc(%ebp),%edx
801025a9:	83 c2 04             	add    $0x4,%edx
801025ac:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801025b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801025b7:	75 20                	jne    801025d9 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801025b9:	8b 45 08             	mov    0x8(%ebp),%eax
801025bc:	8b 00                	mov    (%eax),%eax
801025be:	89 04 24             	mov    %eax,(%esp)
801025c1:	e8 49 f8 ff ff       	call   80101e0f <balloc>
801025c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025c9:	8b 45 08             	mov    0x8(%ebp),%eax
801025cc:	8b 55 0c             	mov    0xc(%ebp),%edx
801025cf:	8d 4a 04             	lea    0x4(%edx),%ecx
801025d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801025d5:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801025d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025dc:	e9 b1 00 00 00       	jmp    80102692 <bmap+0xfc>
  }
  bn -= NDIRECT;
801025e1:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801025e5:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801025e9:	0f 87 97 00 00 00    	ja     80102686 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801025ef:	8b 45 08             	mov    0x8(%ebp),%eax
801025f2:	8b 40 4c             	mov    0x4c(%eax),%eax
801025f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801025fc:	75 19                	jne    80102617 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801025fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102601:	8b 00                	mov    (%eax),%eax
80102603:	89 04 24             	mov    %eax,(%esp)
80102606:	e8 04 f8 ff ff       	call   80101e0f <balloc>
8010260b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010260e:	8b 45 08             	mov    0x8(%ebp),%eax
80102611:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102614:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80102617:	8b 45 08             	mov    0x8(%ebp),%eax
8010261a:	8b 00                	mov    (%eax),%eax
8010261c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010261f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102623:	89 04 24             	mov    %eax,(%esp)
80102626:	e8 7b db ff ff       	call   801001a6 <bread>
8010262b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
8010262e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102631:	83 c0 18             	add    $0x18,%eax
80102634:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80102637:	8b 45 0c             	mov    0xc(%ebp),%eax
8010263a:	c1 e0 02             	shl    $0x2,%eax
8010263d:	03 45 ec             	add    -0x14(%ebp),%eax
80102640:	8b 00                	mov    (%eax),%eax
80102642:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102645:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102649:	75 2b                	jne    80102676 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
8010264b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010264e:	c1 e0 02             	shl    $0x2,%eax
80102651:	89 c3                	mov    %eax,%ebx
80102653:	03 5d ec             	add    -0x14(%ebp),%ebx
80102656:	8b 45 08             	mov    0x8(%ebp),%eax
80102659:	8b 00                	mov    (%eax),%eax
8010265b:	89 04 24             	mov    %eax,(%esp)
8010265e:	e8 ac f7 ff ff       	call   80101e0f <balloc>
80102663:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102666:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102669:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010266b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010266e:	89 04 24             	mov    %eax,(%esp)
80102671:	e8 d4 16 00 00       	call   80103d4a <log_write>
    }
    brelse(bp);
80102676:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102679:	89 04 24             	mov    %eax,(%esp)
8010267c:	e8 96 db ff ff       	call   80100217 <brelse>
    return addr;
80102681:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102684:	eb 0c                	jmp    80102692 <bmap+0xfc>
  }

  panic("bmap: out of range");
80102686:	c7 04 24 6e 8f 10 80 	movl   $0x80108f6e,(%esp)
8010268d:	e8 ab de ff ff       	call   8010053d <panic>
}
80102692:	83 c4 24             	add    $0x24,%esp
80102695:	5b                   	pop    %ebx
80102696:	5d                   	pop    %ebp
80102697:	c3                   	ret    

80102698 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102698:	55                   	push   %ebp
80102699:	89 e5                	mov    %esp,%ebp
8010269b:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010269e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801026a5:	eb 44                	jmp    801026eb <itrunc+0x53>
    if(ip->addrs[i]){
801026a7:	8b 45 08             	mov    0x8(%ebp),%eax
801026aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026ad:	83 c2 04             	add    $0x4,%edx
801026b0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801026b4:	85 c0                	test   %eax,%eax
801026b6:	74 2f                	je     801026e7 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801026b8:	8b 45 08             	mov    0x8(%ebp),%eax
801026bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026be:	83 c2 04             	add    $0x4,%edx
801026c1:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801026c5:	8b 45 08             	mov    0x8(%ebp),%eax
801026c8:	8b 00                	mov    (%eax),%eax
801026ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801026ce:	89 04 24             	mov    %eax,(%esp)
801026d1:	e8 90 f8 ff ff       	call   80101f66 <bfree>
      ip->addrs[i] = 0;
801026d6:	8b 45 08             	mov    0x8(%ebp),%eax
801026d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026dc:	83 c2 04             	add    $0x4,%edx
801026df:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801026e6:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801026e7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026eb:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801026ef:	7e b6                	jle    801026a7 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801026f1:	8b 45 08             	mov    0x8(%ebp),%eax
801026f4:	8b 40 4c             	mov    0x4c(%eax),%eax
801026f7:	85 c0                	test   %eax,%eax
801026f9:	0f 84 8f 00 00 00    	je     8010278e <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801026ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102702:	8b 50 4c             	mov    0x4c(%eax),%edx
80102705:	8b 45 08             	mov    0x8(%ebp),%eax
80102708:	8b 00                	mov    (%eax),%eax
8010270a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010270e:	89 04 24             	mov    %eax,(%esp)
80102711:	e8 90 da ff ff       	call   801001a6 <bread>
80102716:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102719:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010271c:	83 c0 18             	add    $0x18,%eax
8010271f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102722:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102729:	eb 2f                	jmp    8010275a <itrunc+0xc2>
      if(a[j])
8010272b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010272e:	c1 e0 02             	shl    $0x2,%eax
80102731:	03 45 e8             	add    -0x18(%ebp),%eax
80102734:	8b 00                	mov    (%eax),%eax
80102736:	85 c0                	test   %eax,%eax
80102738:	74 1c                	je     80102756 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
8010273a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010273d:	c1 e0 02             	shl    $0x2,%eax
80102740:	03 45 e8             	add    -0x18(%ebp),%eax
80102743:	8b 10                	mov    (%eax),%edx
80102745:	8b 45 08             	mov    0x8(%ebp),%eax
80102748:	8b 00                	mov    (%eax),%eax
8010274a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010274e:	89 04 24             	mov    %eax,(%esp)
80102751:	e8 10 f8 ff ff       	call   80101f66 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102756:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010275a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010275d:	83 f8 7f             	cmp    $0x7f,%eax
80102760:	76 c9                	jbe    8010272b <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102762:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102765:	89 04 24             	mov    %eax,(%esp)
80102768:	e8 aa da ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
8010276d:	8b 45 08             	mov    0x8(%ebp),%eax
80102770:	8b 50 4c             	mov    0x4c(%eax),%edx
80102773:	8b 45 08             	mov    0x8(%ebp),%eax
80102776:	8b 00                	mov    (%eax),%eax
80102778:	89 54 24 04          	mov    %edx,0x4(%esp)
8010277c:	89 04 24             	mov    %eax,(%esp)
8010277f:	e8 e2 f7 ff ff       	call   80101f66 <bfree>
    ip->addrs[NDIRECT] = 0;
80102784:	8b 45 08             	mov    0x8(%ebp),%eax
80102787:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
8010278e:	8b 45 08             	mov    0x8(%ebp),%eax
80102791:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102798:	8b 45 08             	mov    0x8(%ebp),%eax
8010279b:	89 04 24             	mov    %eax,(%esp)
8010279e:	e8 95 f9 ff ff       	call   80102138 <iupdate>
}
801027a3:	c9                   	leave  
801027a4:	c3                   	ret    

801027a5 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
801027a5:	55                   	push   %ebp
801027a6:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
801027a8:	8b 45 08             	mov    0x8(%ebp),%eax
801027ab:	8b 00                	mov    (%eax),%eax
801027ad:	89 c2                	mov    %eax,%edx
801027af:	8b 45 0c             	mov    0xc(%ebp),%eax
801027b2:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801027b5:	8b 45 08             	mov    0x8(%ebp),%eax
801027b8:	8b 50 04             	mov    0x4(%eax),%edx
801027bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801027be:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801027c1:	8b 45 08             	mov    0x8(%ebp),%eax
801027c4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801027c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801027cb:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801027ce:	8b 45 08             	mov    0x8(%ebp),%eax
801027d1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801027d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801027d8:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801027dc:	8b 45 08             	mov    0x8(%ebp),%eax
801027df:	8b 50 18             	mov    0x18(%eax),%edx
801027e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801027e5:	89 50 10             	mov    %edx,0x10(%eax)
}
801027e8:	5d                   	pop    %ebp
801027e9:	c3                   	ret    

801027ea <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801027ea:	55                   	push   %ebp
801027eb:	89 e5                	mov    %esp,%ebp
801027ed:	53                   	push   %ebx
801027ee:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801027f1:	8b 45 08             	mov    0x8(%ebp),%eax
801027f4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027f8:	66 83 f8 03          	cmp    $0x3,%ax
801027fc:	75 60                	jne    8010285e <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801027fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102801:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102805:	66 85 c0             	test   %ax,%ax
80102808:	78 20                	js     8010282a <readi+0x40>
8010280a:	8b 45 08             	mov    0x8(%ebp),%eax
8010280d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102811:	66 83 f8 09          	cmp    $0x9,%ax
80102815:	7f 13                	jg     8010282a <readi+0x40>
80102817:	8b 45 08             	mov    0x8(%ebp),%eax
8010281a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010281e:	98                   	cwtl   
8010281f:	8b 04 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%eax
80102826:	85 c0                	test   %eax,%eax
80102828:	75 0a                	jne    80102834 <readi+0x4a>
      return -1;
8010282a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010282f:	e9 1b 01 00 00       	jmp    8010294f <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102834:	8b 45 08             	mov    0x8(%ebp),%eax
80102837:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010283b:	98                   	cwtl   
8010283c:	8b 14 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%edx
80102843:	8b 45 14             	mov    0x14(%ebp),%eax
80102846:	89 44 24 08          	mov    %eax,0x8(%esp)
8010284a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010284d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102851:	8b 45 08             	mov    0x8(%ebp),%eax
80102854:	89 04 24             	mov    %eax,(%esp)
80102857:	ff d2                	call   *%edx
80102859:	e9 f1 00 00 00       	jmp    8010294f <readi+0x165>
  }

  if(off > ip->size || off + n < off)
8010285e:	8b 45 08             	mov    0x8(%ebp),%eax
80102861:	8b 40 18             	mov    0x18(%eax),%eax
80102864:	3b 45 10             	cmp    0x10(%ebp),%eax
80102867:	72 0d                	jb     80102876 <readi+0x8c>
80102869:	8b 45 14             	mov    0x14(%ebp),%eax
8010286c:	8b 55 10             	mov    0x10(%ebp),%edx
8010286f:	01 d0                	add    %edx,%eax
80102871:	3b 45 10             	cmp    0x10(%ebp),%eax
80102874:	73 0a                	jae    80102880 <readi+0x96>
    return -1;
80102876:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010287b:	e9 cf 00 00 00       	jmp    8010294f <readi+0x165>
  if(off + n > ip->size)
80102880:	8b 45 14             	mov    0x14(%ebp),%eax
80102883:	8b 55 10             	mov    0x10(%ebp),%edx
80102886:	01 c2                	add    %eax,%edx
80102888:	8b 45 08             	mov    0x8(%ebp),%eax
8010288b:	8b 40 18             	mov    0x18(%eax),%eax
8010288e:	39 c2                	cmp    %eax,%edx
80102890:	76 0c                	jbe    8010289e <readi+0xb4>
    n = ip->size - off;
80102892:	8b 45 08             	mov    0x8(%ebp),%eax
80102895:	8b 40 18             	mov    0x18(%eax),%eax
80102898:	2b 45 10             	sub    0x10(%ebp),%eax
8010289b:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010289e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801028a5:	e9 96 00 00 00       	jmp    80102940 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801028aa:	8b 45 10             	mov    0x10(%ebp),%eax
801028ad:	c1 e8 09             	shr    $0x9,%eax
801028b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801028b4:	8b 45 08             	mov    0x8(%ebp),%eax
801028b7:	89 04 24             	mov    %eax,(%esp)
801028ba:	e8 d7 fc ff ff       	call   80102596 <bmap>
801028bf:	8b 55 08             	mov    0x8(%ebp),%edx
801028c2:	8b 12                	mov    (%edx),%edx
801028c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801028c8:	89 14 24             	mov    %edx,(%esp)
801028cb:	e8 d6 d8 ff ff       	call   801001a6 <bread>
801028d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801028d3:	8b 45 10             	mov    0x10(%ebp),%eax
801028d6:	89 c2                	mov    %eax,%edx
801028d8:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801028de:	b8 00 02 00 00       	mov    $0x200,%eax
801028e3:	89 c1                	mov    %eax,%ecx
801028e5:	29 d1                	sub    %edx,%ecx
801028e7:	89 ca                	mov    %ecx,%edx
801028e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ec:	8b 4d 14             	mov    0x14(%ebp),%ecx
801028ef:	89 cb                	mov    %ecx,%ebx
801028f1:	29 c3                	sub    %eax,%ebx
801028f3:	89 d8                	mov    %ebx,%eax
801028f5:	39 c2                	cmp    %eax,%edx
801028f7:	0f 46 c2             	cmovbe %edx,%eax
801028fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801028fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102900:	8d 50 18             	lea    0x18(%eax),%edx
80102903:	8b 45 10             	mov    0x10(%ebp),%eax
80102906:	25 ff 01 00 00       	and    $0x1ff,%eax
8010290b:	01 c2                	add    %eax,%edx
8010290d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102910:	89 44 24 08          	mov    %eax,0x8(%esp)
80102914:	89 54 24 04          	mov    %edx,0x4(%esp)
80102918:	8b 45 0c             	mov    0xc(%ebp),%eax
8010291b:	89 04 24             	mov    %eax,(%esp)
8010291e:	e8 2e 30 00 00       	call   80105951 <memmove>
    brelse(bp);
80102923:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102926:	89 04 24             	mov    %eax,(%esp)
80102929:	e8 e9 d8 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010292e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102931:	01 45 f4             	add    %eax,-0xc(%ebp)
80102934:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102937:	01 45 10             	add    %eax,0x10(%ebp)
8010293a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010293d:	01 45 0c             	add    %eax,0xc(%ebp)
80102940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102943:	3b 45 14             	cmp    0x14(%ebp),%eax
80102946:	0f 82 5e ff ff ff    	jb     801028aa <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010294c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010294f:	83 c4 24             	add    $0x24,%esp
80102952:	5b                   	pop    %ebx
80102953:	5d                   	pop    %ebp
80102954:	c3                   	ret    

80102955 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102955:	55                   	push   %ebp
80102956:	89 e5                	mov    %esp,%ebp
80102958:	53                   	push   %ebx
80102959:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010295c:	8b 45 08             	mov    0x8(%ebp),%eax
8010295f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102963:	66 83 f8 03          	cmp    $0x3,%ax
80102967:	75 60                	jne    801029c9 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102969:	8b 45 08             	mov    0x8(%ebp),%eax
8010296c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102970:	66 85 c0             	test   %ax,%ax
80102973:	78 20                	js     80102995 <writei+0x40>
80102975:	8b 45 08             	mov    0x8(%ebp),%eax
80102978:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010297c:	66 83 f8 09          	cmp    $0x9,%ax
80102980:	7f 13                	jg     80102995 <writei+0x40>
80102982:	8b 45 08             	mov    0x8(%ebp),%eax
80102985:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102989:	98                   	cwtl   
8010298a:	8b 04 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%eax
80102991:	85 c0                	test   %eax,%eax
80102993:	75 0a                	jne    8010299f <writei+0x4a>
      return -1;
80102995:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010299a:	e9 46 01 00 00       	jmp    80102ae5 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
8010299f:	8b 45 08             	mov    0x8(%ebp),%eax
801029a2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801029a6:	98                   	cwtl   
801029a7:	8b 14 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%edx
801029ae:	8b 45 14             	mov    0x14(%ebp),%eax
801029b1:	89 44 24 08          	mov    %eax,0x8(%esp)
801029b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801029b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801029bc:	8b 45 08             	mov    0x8(%ebp),%eax
801029bf:	89 04 24             	mov    %eax,(%esp)
801029c2:	ff d2                	call   *%edx
801029c4:	e9 1c 01 00 00       	jmp    80102ae5 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
801029c9:	8b 45 08             	mov    0x8(%ebp),%eax
801029cc:	8b 40 18             	mov    0x18(%eax),%eax
801029cf:	3b 45 10             	cmp    0x10(%ebp),%eax
801029d2:	72 0d                	jb     801029e1 <writei+0x8c>
801029d4:	8b 45 14             	mov    0x14(%ebp),%eax
801029d7:	8b 55 10             	mov    0x10(%ebp),%edx
801029da:	01 d0                	add    %edx,%eax
801029dc:	3b 45 10             	cmp    0x10(%ebp),%eax
801029df:	73 0a                	jae    801029eb <writei+0x96>
    return -1;
801029e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801029e6:	e9 fa 00 00 00       	jmp    80102ae5 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
801029eb:	8b 45 14             	mov    0x14(%ebp),%eax
801029ee:	8b 55 10             	mov    0x10(%ebp),%edx
801029f1:	01 d0                	add    %edx,%eax
801029f3:	3d 00 18 01 00       	cmp    $0x11800,%eax
801029f8:	76 0a                	jbe    80102a04 <writei+0xaf>
    return -1;
801029fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801029ff:	e9 e1 00 00 00       	jmp    80102ae5 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102a04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a0b:	e9 a1 00 00 00       	jmp    80102ab1 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102a10:	8b 45 10             	mov    0x10(%ebp),%eax
80102a13:	c1 e8 09             	shr    $0x9,%eax
80102a16:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80102a1d:	89 04 24             	mov    %eax,(%esp)
80102a20:	e8 71 fb ff ff       	call   80102596 <bmap>
80102a25:	8b 55 08             	mov    0x8(%ebp),%edx
80102a28:	8b 12                	mov    (%edx),%edx
80102a2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a2e:	89 14 24             	mov    %edx,(%esp)
80102a31:	e8 70 d7 ff ff       	call   801001a6 <bread>
80102a36:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102a39:	8b 45 10             	mov    0x10(%ebp),%eax
80102a3c:	89 c2                	mov    %eax,%edx
80102a3e:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102a44:	b8 00 02 00 00       	mov    $0x200,%eax
80102a49:	89 c1                	mov    %eax,%ecx
80102a4b:	29 d1                	sub    %edx,%ecx
80102a4d:	89 ca                	mov    %ecx,%edx
80102a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a52:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102a55:	89 cb                	mov    %ecx,%ebx
80102a57:	29 c3                	sub    %eax,%ebx
80102a59:	89 d8                	mov    %ebx,%eax
80102a5b:	39 c2                	cmp    %eax,%edx
80102a5d:	0f 46 c2             	cmovbe %edx,%eax
80102a60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a66:	8d 50 18             	lea    0x18(%eax),%edx
80102a69:	8b 45 10             	mov    0x10(%ebp),%eax
80102a6c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102a71:	01 c2                	add    %eax,%edx
80102a73:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a76:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a81:	89 14 24             	mov    %edx,(%esp)
80102a84:	e8 c8 2e 00 00       	call   80105951 <memmove>
    log_write(bp);
80102a89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a8c:	89 04 24             	mov    %eax,(%esp)
80102a8f:	e8 b6 12 00 00       	call   80103d4a <log_write>
    brelse(bp);
80102a94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a97:	89 04 24             	mov    %eax,(%esp)
80102a9a:	e8 78 d7 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102a9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102aa2:	01 45 f4             	add    %eax,-0xc(%ebp)
80102aa5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102aa8:	01 45 10             	add    %eax,0x10(%ebp)
80102aab:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102aae:	01 45 0c             	add    %eax,0xc(%ebp)
80102ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ab4:	3b 45 14             	cmp    0x14(%ebp),%eax
80102ab7:	0f 82 53 ff ff ff    	jb     80102a10 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102abd:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102ac1:	74 1f                	je     80102ae2 <writei+0x18d>
80102ac3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac6:	8b 40 18             	mov    0x18(%eax),%eax
80102ac9:	3b 45 10             	cmp    0x10(%ebp),%eax
80102acc:	73 14                	jae    80102ae2 <writei+0x18d>
    ip->size = off;
80102ace:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad1:	8b 55 10             	mov    0x10(%ebp),%edx
80102ad4:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102ad7:	8b 45 08             	mov    0x8(%ebp),%eax
80102ada:	89 04 24             	mov    %eax,(%esp)
80102add:	e8 56 f6 ff ff       	call   80102138 <iupdate>
  }
  return n;
80102ae2:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102ae5:	83 c4 24             	add    $0x24,%esp
80102ae8:	5b                   	pop    %ebx
80102ae9:	5d                   	pop    %ebp
80102aea:	c3                   	ret    

80102aeb <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102aeb:	55                   	push   %ebp
80102aec:	89 e5                	mov    %esp,%ebp
80102aee:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102af1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102af8:	00 
80102af9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102afc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b00:	8b 45 08             	mov    0x8(%ebp),%eax
80102b03:	89 04 24             	mov    %eax,(%esp)
80102b06:	e8 ea 2e 00 00       	call   801059f5 <strncmp>
}
80102b0b:	c9                   	leave  
80102b0c:	c3                   	ret    

80102b0d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102b0d:	55                   	push   %ebp
80102b0e:	89 e5                	mov    %esp,%ebp
80102b10:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102b13:	8b 45 08             	mov    0x8(%ebp),%eax
80102b16:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102b1a:	66 83 f8 01          	cmp    $0x1,%ax
80102b1e:	74 0c                	je     80102b2c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102b20:	c7 04 24 81 8f 10 80 	movl   $0x80108f81,(%esp)
80102b27:	e8 11 da ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102b2c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b33:	e9 87 00 00 00       	jmp    80102bbf <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102b38:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102b3f:	00 
80102b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b43:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b47:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102b4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b4e:	8b 45 08             	mov    0x8(%ebp),%eax
80102b51:	89 04 24             	mov    %eax,(%esp)
80102b54:	e8 91 fc ff ff       	call   801027ea <readi>
80102b59:	83 f8 10             	cmp    $0x10,%eax
80102b5c:	74 0c                	je     80102b6a <dirlookup+0x5d>
      panic("dirlink read");
80102b5e:	c7 04 24 93 8f 10 80 	movl   $0x80108f93,(%esp)
80102b65:	e8 d3 d9 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102b6a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102b6e:	66 85 c0             	test   %ax,%ax
80102b71:	74 47                	je     80102bba <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102b73:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102b76:	83 c0 02             	add    $0x2,%eax
80102b79:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b80:	89 04 24             	mov    %eax,(%esp)
80102b83:	e8 63 ff ff ff       	call   80102aeb <namecmp>
80102b88:	85 c0                	test   %eax,%eax
80102b8a:	75 2f                	jne    80102bbb <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102b8c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102b90:	74 08                	je     80102b9a <dirlookup+0x8d>
        *poff = off;
80102b92:	8b 45 10             	mov    0x10(%ebp),%eax
80102b95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b98:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102b9a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102b9e:	0f b7 c0             	movzwl %ax,%eax
80102ba1:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba7:	8b 00                	mov    (%eax),%eax
80102ba9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102bac:	89 54 24 04          	mov    %edx,0x4(%esp)
80102bb0:	89 04 24             	mov    %eax,(%esp)
80102bb3:	e8 38 f6 ff ff       	call   801021f0 <iget>
80102bb8:	eb 19                	jmp    80102bd3 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102bba:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102bbb:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102bbf:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc2:	8b 40 18             	mov    0x18(%eax),%eax
80102bc5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102bc8:	0f 87 6a ff ff ff    	ja     80102b38 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102bce:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bd3:	c9                   	leave  
80102bd4:	c3                   	ret    

80102bd5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102bd5:	55                   	push   %ebp
80102bd6:	89 e5                	mov    %esp,%ebp
80102bd8:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102bdb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102be2:	00 
80102be3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102be6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bea:	8b 45 08             	mov    0x8(%ebp),%eax
80102bed:	89 04 24             	mov    %eax,(%esp)
80102bf0:	e8 18 ff ff ff       	call   80102b0d <dirlookup>
80102bf5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102bf8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102bfc:	74 15                	je     80102c13 <dirlink+0x3e>
    iput(ip);
80102bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102c01:	89 04 24             	mov    %eax,(%esp)
80102c04:	e8 9e f8 ff ff       	call   801024a7 <iput>
    return -1;
80102c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c0e:	e9 b8 00 00 00       	jmp    80102ccb <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102c13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c1a:	eb 44                	jmp    80102c60 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c1f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c26:	00 
80102c27:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c2b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c32:	8b 45 08             	mov    0x8(%ebp),%eax
80102c35:	89 04 24             	mov    %eax,(%esp)
80102c38:	e8 ad fb ff ff       	call   801027ea <readi>
80102c3d:	83 f8 10             	cmp    $0x10,%eax
80102c40:	74 0c                	je     80102c4e <dirlink+0x79>
      panic("dirlink read");
80102c42:	c7 04 24 93 8f 10 80 	movl   $0x80108f93,(%esp)
80102c49:	e8 ef d8 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102c4e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c52:	66 85 c0             	test   %ax,%ax
80102c55:	74 18                	je     80102c6f <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102c57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c5a:	83 c0 10             	add    $0x10,%eax
80102c5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102c60:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102c63:	8b 45 08             	mov    0x8(%ebp),%eax
80102c66:	8b 40 18             	mov    0x18(%eax),%eax
80102c69:	39 c2                	cmp    %eax,%edx
80102c6b:	72 af                	jb     80102c1c <dirlink+0x47>
80102c6d:	eb 01                	jmp    80102c70 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102c6f:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102c70:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102c77:	00 
80102c78:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c7f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c82:	83 c0 02             	add    $0x2,%eax
80102c85:	89 04 24             	mov    %eax,(%esp)
80102c88:	e8 c0 2d 00 00       	call   80105a4d <strncpy>
  de.inum = inum;
80102c8d:	8b 45 10             	mov    0x10(%ebp),%eax
80102c90:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c97:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c9e:	00 
80102c9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ca3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102ca6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102caa:	8b 45 08             	mov    0x8(%ebp),%eax
80102cad:	89 04 24             	mov    %eax,(%esp)
80102cb0:	e8 a0 fc ff ff       	call   80102955 <writei>
80102cb5:	83 f8 10             	cmp    $0x10,%eax
80102cb8:	74 0c                	je     80102cc6 <dirlink+0xf1>
    panic("dirlink");
80102cba:	c7 04 24 a0 8f 10 80 	movl   $0x80108fa0,(%esp)
80102cc1:	e8 77 d8 ff ff       	call   8010053d <panic>
  
  return 0;
80102cc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ccb:	c9                   	leave  
80102ccc:	c3                   	ret    

80102ccd <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102ccd:	55                   	push   %ebp
80102cce:	89 e5                	mov    %esp,%ebp
80102cd0:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102cd3:	eb 04                	jmp    80102cd9 <skipelem+0xc>
    path++;
80102cd5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102cd9:	8b 45 08             	mov    0x8(%ebp),%eax
80102cdc:	0f b6 00             	movzbl (%eax),%eax
80102cdf:	3c 2f                	cmp    $0x2f,%al
80102ce1:	74 f2                	je     80102cd5 <skipelem+0x8>
    path++;
  if(*path == 0)
80102ce3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce6:	0f b6 00             	movzbl (%eax),%eax
80102ce9:	84 c0                	test   %al,%al
80102ceb:	75 0a                	jne    80102cf7 <skipelem+0x2a>
    return 0;
80102ced:	b8 00 00 00 00       	mov    $0x0,%eax
80102cf2:	e9 86 00 00 00       	jmp    80102d7d <skipelem+0xb0>
  s = path;
80102cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102cfd:	eb 04                	jmp    80102d03 <skipelem+0x36>
    path++;
80102cff:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102d03:	8b 45 08             	mov    0x8(%ebp),%eax
80102d06:	0f b6 00             	movzbl (%eax),%eax
80102d09:	3c 2f                	cmp    $0x2f,%al
80102d0b:	74 0a                	je     80102d17 <skipelem+0x4a>
80102d0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102d10:	0f b6 00             	movzbl (%eax),%eax
80102d13:	84 c0                	test   %al,%al
80102d15:	75 e8                	jne    80102cff <skipelem+0x32>
    path++;
  len = path - s;
80102d17:	8b 55 08             	mov    0x8(%ebp),%edx
80102d1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d1d:	89 d1                	mov    %edx,%ecx
80102d1f:	29 c1                	sub    %eax,%ecx
80102d21:	89 c8                	mov    %ecx,%eax
80102d23:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102d26:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102d2a:	7e 1c                	jle    80102d48 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102d2c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102d33:	00 
80102d34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d37:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d3e:	89 04 24             	mov    %eax,(%esp)
80102d41:	e8 0b 2c 00 00       	call   80105951 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102d46:	eb 28                	jmp    80102d70 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102d48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d4b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d52:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d56:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d59:	89 04 24             	mov    %eax,(%esp)
80102d5c:	e8 f0 2b 00 00       	call   80105951 <memmove>
    name[len] = 0;
80102d61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d64:	03 45 0c             	add    0xc(%ebp),%eax
80102d67:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102d6a:	eb 04                	jmp    80102d70 <skipelem+0xa3>
    path++;
80102d6c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102d70:	8b 45 08             	mov    0x8(%ebp),%eax
80102d73:	0f b6 00             	movzbl (%eax),%eax
80102d76:	3c 2f                	cmp    $0x2f,%al
80102d78:	74 f2                	je     80102d6c <skipelem+0x9f>
    path++;
  return path;
80102d7a:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102d7d:	c9                   	leave  
80102d7e:	c3                   	ret    

80102d7f <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102d7f:	55                   	push   %ebp
80102d80:	89 e5                	mov    %esp,%ebp
80102d82:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102d85:	8b 45 08             	mov    0x8(%ebp),%eax
80102d88:	0f b6 00             	movzbl (%eax),%eax
80102d8b:	3c 2f                	cmp    $0x2f,%al
80102d8d:	75 1c                	jne    80102dab <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102d8f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d96:	00 
80102d97:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102d9e:	e8 4d f4 ff ff       	call   801021f0 <iget>
80102da3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102da6:	e9 af 00 00 00       	jmp    80102e5a <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102dab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102db1:	8b 40 68             	mov    0x68(%eax),%eax
80102db4:	89 04 24             	mov    %eax,(%esp)
80102db7:	e8 06 f5 ff ff       	call   801022c2 <idup>
80102dbc:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102dbf:	e9 96 00 00 00       	jmp    80102e5a <namex+0xdb>
    ilock(ip);
80102dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc7:	89 04 24             	mov    %eax,(%esp)
80102dca:	e8 25 f5 ff ff       	call   801022f4 <ilock>
    if(ip->type != T_DIR){
80102dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dd2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102dd6:	66 83 f8 01          	cmp    $0x1,%ax
80102dda:	74 15                	je     80102df1 <namex+0x72>
      iunlockput(ip);
80102ddc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ddf:	89 04 24             	mov    %eax,(%esp)
80102de2:	e8 91 f7 ff ff       	call   80102578 <iunlockput>
      return 0;
80102de7:	b8 00 00 00 00       	mov    $0x0,%eax
80102dec:	e9 a3 00 00 00       	jmp    80102e94 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102df1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102df5:	74 1d                	je     80102e14 <namex+0x95>
80102df7:	8b 45 08             	mov    0x8(%ebp),%eax
80102dfa:	0f b6 00             	movzbl (%eax),%eax
80102dfd:	84 c0                	test   %al,%al
80102dff:	75 13                	jne    80102e14 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102e01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e04:	89 04 24             	mov    %eax,(%esp)
80102e07:	e8 36 f6 ff ff       	call   80102442 <iunlock>
      return ip;
80102e0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e0f:	e9 80 00 00 00       	jmp    80102e94 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102e14:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102e1b:	00 
80102e1c:	8b 45 10             	mov    0x10(%ebp),%eax
80102e1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e26:	89 04 24             	mov    %eax,(%esp)
80102e29:	e8 df fc ff ff       	call   80102b0d <dirlookup>
80102e2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102e31:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102e35:	75 12                	jne    80102e49 <namex+0xca>
      iunlockput(ip);
80102e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e3a:	89 04 24             	mov    %eax,(%esp)
80102e3d:	e8 36 f7 ff ff       	call   80102578 <iunlockput>
      return 0;
80102e42:	b8 00 00 00 00       	mov    $0x0,%eax
80102e47:	eb 4b                	jmp    80102e94 <namex+0x115>
    }
    iunlockput(ip);
80102e49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e4c:	89 04 24             	mov    %eax,(%esp)
80102e4f:	e8 24 f7 ff ff       	call   80102578 <iunlockput>
    ip = next;
80102e54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e57:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102e5a:	8b 45 10             	mov    0x10(%ebp),%eax
80102e5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e61:	8b 45 08             	mov    0x8(%ebp),%eax
80102e64:	89 04 24             	mov    %eax,(%esp)
80102e67:	e8 61 fe ff ff       	call   80102ccd <skipelem>
80102e6c:	89 45 08             	mov    %eax,0x8(%ebp)
80102e6f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102e73:	0f 85 4b ff ff ff    	jne    80102dc4 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102e79:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e7d:	74 12                	je     80102e91 <namex+0x112>
    iput(ip);
80102e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e82:	89 04 24             	mov    %eax,(%esp)
80102e85:	e8 1d f6 ff ff       	call   801024a7 <iput>
    return 0;
80102e8a:	b8 00 00 00 00       	mov    $0x0,%eax
80102e8f:	eb 03                	jmp    80102e94 <namex+0x115>
  }
  return ip;
80102e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102e94:	c9                   	leave  
80102e95:	c3                   	ret    

80102e96 <namei>:

struct inode*
namei(char *path)
{
80102e96:	55                   	push   %ebp
80102e97:	89 e5                	mov    %esp,%ebp
80102e99:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102e9c:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102e9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ea3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102eaa:	00 
80102eab:	8b 45 08             	mov    0x8(%ebp),%eax
80102eae:	89 04 24             	mov    %eax,(%esp)
80102eb1:	e8 c9 fe ff ff       	call   80102d7f <namex>
}
80102eb6:	c9                   	leave  
80102eb7:	c3                   	ret    

80102eb8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102eb8:	55                   	push   %ebp
80102eb9:	89 e5                	mov    %esp,%ebp
80102ebb:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102ebe:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ec1:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ec5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ecc:	00 
80102ecd:	8b 45 08             	mov    0x8(%ebp),%eax
80102ed0:	89 04 24             	mov    %eax,(%esp)
80102ed3:	e8 a7 fe ff ff       	call   80102d7f <namex>
}
80102ed8:	c9                   	leave  
80102ed9:	c3                   	ret    
	...

80102edc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102edc:	55                   	push   %ebp
80102edd:	89 e5                	mov    %esp,%ebp
80102edf:	53                   	push   %ebx
80102ee0:	83 ec 14             	sub    $0x14,%esp
80102ee3:	8b 45 08             	mov    0x8(%ebp),%eax
80102ee6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102eea:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102eee:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102ef2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102ef6:	ec                   	in     (%dx),%al
80102ef7:	89 c3                	mov    %eax,%ebx
80102ef9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102efc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102f00:	83 c4 14             	add    $0x14,%esp
80102f03:	5b                   	pop    %ebx
80102f04:	5d                   	pop    %ebp
80102f05:	c3                   	ret    

80102f06 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102f06:	55                   	push   %ebp
80102f07:	89 e5                	mov    %esp,%ebp
80102f09:	57                   	push   %edi
80102f0a:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102f0b:	8b 55 08             	mov    0x8(%ebp),%edx
80102f0e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102f11:	8b 45 10             	mov    0x10(%ebp),%eax
80102f14:	89 cb                	mov    %ecx,%ebx
80102f16:	89 df                	mov    %ebx,%edi
80102f18:	89 c1                	mov    %eax,%ecx
80102f1a:	fc                   	cld    
80102f1b:	f3 6d                	rep insl (%dx),%es:(%edi)
80102f1d:	89 c8                	mov    %ecx,%eax
80102f1f:	89 fb                	mov    %edi,%ebx
80102f21:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102f24:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102f27:	5b                   	pop    %ebx
80102f28:	5f                   	pop    %edi
80102f29:	5d                   	pop    %ebp
80102f2a:	c3                   	ret    

80102f2b <outb>:

static inline void
outb(ushort port, uchar data)
{
80102f2b:	55                   	push   %ebp
80102f2c:	89 e5                	mov    %esp,%ebp
80102f2e:	83 ec 08             	sub    $0x8,%esp
80102f31:	8b 55 08             	mov    0x8(%ebp),%edx
80102f34:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f37:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102f3b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f3e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102f42:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102f46:	ee                   	out    %al,(%dx)
}
80102f47:	c9                   	leave  
80102f48:	c3                   	ret    

80102f49 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102f49:	55                   	push   %ebp
80102f4a:	89 e5                	mov    %esp,%ebp
80102f4c:	56                   	push   %esi
80102f4d:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102f4e:	8b 55 08             	mov    0x8(%ebp),%edx
80102f51:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102f54:	8b 45 10             	mov    0x10(%ebp),%eax
80102f57:	89 cb                	mov    %ecx,%ebx
80102f59:	89 de                	mov    %ebx,%esi
80102f5b:	89 c1                	mov    %eax,%ecx
80102f5d:	fc                   	cld    
80102f5e:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102f60:	89 c8                	mov    %ecx,%eax
80102f62:	89 f3                	mov    %esi,%ebx
80102f64:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102f67:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102f6a:	5b                   	pop    %ebx
80102f6b:	5e                   	pop    %esi
80102f6c:	5d                   	pop    %ebp
80102f6d:	c3                   	ret    

80102f6e <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102f6e:	55                   	push   %ebp
80102f6f:	89 e5                	mov    %esp,%ebp
80102f71:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102f74:	90                   	nop
80102f75:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102f7c:	e8 5b ff ff ff       	call   80102edc <inb>
80102f81:	0f b6 c0             	movzbl %al,%eax
80102f84:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102f87:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102f8a:	25 c0 00 00 00       	and    $0xc0,%eax
80102f8f:	83 f8 40             	cmp    $0x40,%eax
80102f92:	75 e1                	jne    80102f75 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102f94:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102f98:	74 11                	je     80102fab <idewait+0x3d>
80102f9a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102f9d:	83 e0 21             	and    $0x21,%eax
80102fa0:	85 c0                	test   %eax,%eax
80102fa2:	74 07                	je     80102fab <idewait+0x3d>
    return -1;
80102fa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102fa9:	eb 05                	jmp    80102fb0 <idewait+0x42>
  return 0;
80102fab:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102fb0:	c9                   	leave  
80102fb1:	c3                   	ret    

80102fb2 <ideinit>:

void
ideinit(void)
{
80102fb2:	55                   	push   %ebp
80102fb3:	89 e5                	mov    %esp,%ebp
80102fb5:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102fb8:	c7 44 24 04 a8 8f 10 	movl   $0x80108fa8,0x4(%esp)
80102fbf:	80 
80102fc0:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102fc7:	e8 42 26 00 00       	call   8010560e <initlock>
  picenable(IRQ_IDE);
80102fcc:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102fd3:	e8 75 15 00 00       	call   8010454d <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102fd8:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80102fdd:	83 e8 01             	sub    $0x1,%eax
80102fe0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fe4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102feb:	e8 12 04 00 00       	call   80103402 <ioapicenable>
  idewait(0);
80102ff0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102ff7:	e8 72 ff ff ff       	call   80102f6e <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102ffc:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80103003:	00 
80103004:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010300b:	e8 1b ff ff ff       	call   80102f2b <outb>
  for(i=0; i<1000; i++){
80103010:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103017:	eb 20                	jmp    80103039 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103019:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103020:	e8 b7 fe ff ff       	call   80102edc <inb>
80103025:	84 c0                	test   %al,%al
80103027:	74 0c                	je     80103035 <ideinit+0x83>
      havedisk1 = 1;
80103029:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80103030:	00 00 00 
      break;
80103033:	eb 0d                	jmp    80103042 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80103035:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103039:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80103040:	7e d7                	jle    80103019 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80103042:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103049:	00 
8010304a:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103051:	e8 d5 fe ff ff       	call   80102f2b <outb>
}
80103056:	c9                   	leave  
80103057:	c3                   	ret    

80103058 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103058:	55                   	push   %ebp
80103059:	89 e5                	mov    %esp,%ebp
8010305b:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010305e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103062:	75 0c                	jne    80103070 <idestart+0x18>
    panic("idestart");
80103064:	c7 04 24 ac 8f 10 80 	movl   $0x80108fac,(%esp)
8010306b:	e8 cd d4 ff ff       	call   8010053d <panic>

  idewait(0);
80103070:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103077:	e8 f2 fe ff ff       	call   80102f6e <idewait>
  outb(0x3f6, 0);  // generate interrupt
8010307c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103083:	00 
80103084:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010308b:	e8 9b fe ff ff       	call   80102f2b <outb>
  outb(0x1f2, 1);  // number of sectors
80103090:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103097:	00 
80103098:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010309f:	e8 87 fe ff ff       	call   80102f2b <outb>
  outb(0x1f3, b->sector & 0xff);
801030a4:	8b 45 08             	mov    0x8(%ebp),%eax
801030a7:	8b 40 08             	mov    0x8(%eax),%eax
801030aa:	0f b6 c0             	movzbl %al,%eax
801030ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801030b1:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801030b8:	e8 6e fe ff ff       	call   80102f2b <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801030bd:	8b 45 08             	mov    0x8(%ebp),%eax
801030c0:	8b 40 08             	mov    0x8(%eax),%eax
801030c3:	c1 e8 08             	shr    $0x8,%eax
801030c6:	0f b6 c0             	movzbl %al,%eax
801030c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801030cd:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801030d4:	e8 52 fe ff ff       	call   80102f2b <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801030d9:	8b 45 08             	mov    0x8(%ebp),%eax
801030dc:	8b 40 08             	mov    0x8(%eax),%eax
801030df:	c1 e8 10             	shr    $0x10,%eax
801030e2:	0f b6 c0             	movzbl %al,%eax
801030e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801030e9:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801030f0:	e8 36 fe ff ff       	call   80102f2b <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801030f5:	8b 45 08             	mov    0x8(%ebp),%eax
801030f8:	8b 40 04             	mov    0x4(%eax),%eax
801030fb:	83 e0 01             	and    $0x1,%eax
801030fe:	89 c2                	mov    %eax,%edx
80103100:	c1 e2 04             	shl    $0x4,%edx
80103103:	8b 45 08             	mov    0x8(%ebp),%eax
80103106:	8b 40 08             	mov    0x8(%eax),%eax
80103109:	c1 e8 18             	shr    $0x18,%eax
8010310c:	83 e0 0f             	and    $0xf,%eax
8010310f:	09 d0                	or     %edx,%eax
80103111:	83 c8 e0             	or     $0xffffffe0,%eax
80103114:	0f b6 c0             	movzbl %al,%eax
80103117:	89 44 24 04          	mov    %eax,0x4(%esp)
8010311b:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103122:	e8 04 fe ff ff       	call   80102f2b <outb>
  if(b->flags & B_DIRTY){
80103127:	8b 45 08             	mov    0x8(%ebp),%eax
8010312a:	8b 00                	mov    (%eax),%eax
8010312c:	83 e0 04             	and    $0x4,%eax
8010312f:	85 c0                	test   %eax,%eax
80103131:	74 34                	je     80103167 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80103133:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
8010313a:	00 
8010313b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103142:	e8 e4 fd ff ff       	call   80102f2b <outb>
    outsl(0x1f0, b->data, 512/4);
80103147:	8b 45 08             	mov    0x8(%ebp),%eax
8010314a:	83 c0 18             	add    $0x18,%eax
8010314d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103154:	00 
80103155:	89 44 24 04          	mov    %eax,0x4(%esp)
80103159:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103160:	e8 e4 fd ff ff       	call   80102f49 <outsl>
80103165:	eb 14                	jmp    8010317b <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80103167:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010316e:	00 
8010316f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103176:	e8 b0 fd ff ff       	call   80102f2b <outb>
  }
}
8010317b:	c9                   	leave  
8010317c:	c3                   	ret    

8010317d <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
8010317d:	55                   	push   %ebp
8010317e:	89 e5                	mov    %esp,%ebp
80103180:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80103183:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010318a:	e8 a0 24 00 00       	call   8010562f <acquire>
  if((b = idequeue) == 0){
8010318f:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103194:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103197:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010319b:	75 11                	jne    801031ae <ideintr+0x31>
    release(&idelock);
8010319d:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801031a4:	e8 e8 24 00 00       	call   80105691 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801031a9:	e9 90 00 00 00       	jmp    8010323e <ideintr+0xc1>
  }
  idequeue = b->qnext;
801031ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031b1:	8b 40 14             	mov    0x14(%eax),%eax
801031b4:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801031b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031bc:	8b 00                	mov    (%eax),%eax
801031be:	83 e0 04             	and    $0x4,%eax
801031c1:	85 c0                	test   %eax,%eax
801031c3:	75 2e                	jne    801031f3 <ideintr+0x76>
801031c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801031cc:	e8 9d fd ff ff       	call   80102f6e <idewait>
801031d1:	85 c0                	test   %eax,%eax
801031d3:	78 1e                	js     801031f3 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801031d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031d8:	83 c0 18             	add    $0x18,%eax
801031db:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801031e2:	00 
801031e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801031e7:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801031ee:	e8 13 fd ff ff       	call   80102f06 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801031f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031f6:	8b 00                	mov    (%eax),%eax
801031f8:	89 c2                	mov    %eax,%edx
801031fa:	83 ca 02             	or     $0x2,%edx
801031fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103200:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80103202:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103205:	8b 00                	mov    (%eax),%eax
80103207:	89 c2                	mov    %eax,%edx
80103209:	83 e2 fb             	and    $0xfffffffb,%edx
8010320c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010320f:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103211:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103214:	89 04 24             	mov    %eax,(%esp)
80103217:	e8 0e 22 00 00       	call   8010542a <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
8010321c:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103221:	85 c0                	test   %eax,%eax
80103223:	74 0d                	je     80103232 <ideintr+0xb5>
    idestart(idequeue);
80103225:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010322a:	89 04 24             	mov    %eax,(%esp)
8010322d:	e8 26 fe ff ff       	call   80103058 <idestart>

  release(&idelock);
80103232:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103239:	e8 53 24 00 00       	call   80105691 <release>
}
8010323e:	c9                   	leave  
8010323f:	c3                   	ret    

80103240 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103240:	55                   	push   %ebp
80103241:	89 e5                	mov    %esp,%ebp
80103243:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80103246:	8b 45 08             	mov    0x8(%ebp),%eax
80103249:	8b 00                	mov    (%eax),%eax
8010324b:	83 e0 01             	and    $0x1,%eax
8010324e:	85 c0                	test   %eax,%eax
80103250:	75 0c                	jne    8010325e <iderw+0x1e>
    panic("iderw: buf not busy");
80103252:	c7 04 24 b5 8f 10 80 	movl   $0x80108fb5,(%esp)
80103259:	e8 df d2 ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010325e:	8b 45 08             	mov    0x8(%ebp),%eax
80103261:	8b 00                	mov    (%eax),%eax
80103263:	83 e0 06             	and    $0x6,%eax
80103266:	83 f8 02             	cmp    $0x2,%eax
80103269:	75 0c                	jne    80103277 <iderw+0x37>
    panic("iderw: nothing to do");
8010326b:	c7 04 24 c9 8f 10 80 	movl   $0x80108fc9,(%esp)
80103272:	e8 c6 d2 ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80103277:	8b 45 08             	mov    0x8(%ebp),%eax
8010327a:	8b 40 04             	mov    0x4(%eax),%eax
8010327d:	85 c0                	test   %eax,%eax
8010327f:	74 15                	je     80103296 <iderw+0x56>
80103281:	a1 58 c6 10 80       	mov    0x8010c658,%eax
80103286:	85 c0                	test   %eax,%eax
80103288:	75 0c                	jne    80103296 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
8010328a:	c7 04 24 de 8f 10 80 	movl   $0x80108fde,(%esp)
80103291:	e8 a7 d2 ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80103296:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010329d:	e8 8d 23 00 00       	call   8010562f <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801032a2:	8b 45 08             	mov    0x8(%ebp),%eax
801032a5:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801032ac:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801032b3:	eb 0b                	jmp    801032c0 <iderw+0x80>
801032b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b8:	8b 00                	mov    (%eax),%eax
801032ba:	83 c0 14             	add    $0x14,%eax
801032bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801032c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c3:	8b 00                	mov    (%eax),%eax
801032c5:	85 c0                	test   %eax,%eax
801032c7:	75 ec                	jne    801032b5 <iderw+0x75>
    ;
  *pp = b;
801032c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032cc:	8b 55 08             	mov    0x8(%ebp),%edx
801032cf:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801032d1:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801032d6:	3b 45 08             	cmp    0x8(%ebp),%eax
801032d9:	75 22                	jne    801032fd <iderw+0xbd>
    idestart(b);
801032db:	8b 45 08             	mov    0x8(%ebp),%eax
801032de:	89 04 24             	mov    %eax,(%esp)
801032e1:	e8 72 fd ff ff       	call   80103058 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801032e6:	eb 15                	jmp    801032fd <iderw+0xbd>
    sleep(b, &idelock);
801032e8:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
801032ef:	80 
801032f0:	8b 45 08             	mov    0x8(%ebp),%eax
801032f3:	89 04 24             	mov    %eax,(%esp)
801032f6:	e8 56 20 00 00       	call   80105351 <sleep>
801032fb:	eb 01                	jmp    801032fe <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801032fd:	90                   	nop
801032fe:	8b 45 08             	mov    0x8(%ebp),%eax
80103301:	8b 00                	mov    (%eax),%eax
80103303:	83 e0 06             	and    $0x6,%eax
80103306:	83 f8 02             	cmp    $0x2,%eax
80103309:	75 dd                	jne    801032e8 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
8010330b:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103312:	e8 7a 23 00 00       	call   80105691 <release>
}
80103317:	c9                   	leave  
80103318:	c3                   	ret    
80103319:	00 00                	add    %al,(%eax)
	...

8010331c <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
8010331c:	55                   	push   %ebp
8010331d:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010331f:	a1 54 08 11 80       	mov    0x80110854,%eax
80103324:	8b 55 08             	mov    0x8(%ebp),%edx
80103327:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103329:	a1 54 08 11 80       	mov    0x80110854,%eax
8010332e:	8b 40 10             	mov    0x10(%eax),%eax
}
80103331:	5d                   	pop    %ebp
80103332:	c3                   	ret    

80103333 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103333:	55                   	push   %ebp
80103334:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103336:	a1 54 08 11 80       	mov    0x80110854,%eax
8010333b:	8b 55 08             	mov    0x8(%ebp),%edx
8010333e:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103340:	a1 54 08 11 80       	mov    0x80110854,%eax
80103345:	8b 55 0c             	mov    0xc(%ebp),%edx
80103348:	89 50 10             	mov    %edx,0x10(%eax)
}
8010334b:	5d                   	pop    %ebp
8010334c:	c3                   	ret    

8010334d <ioapicinit>:

void
ioapicinit(void)
{
8010334d:	55                   	push   %ebp
8010334e:	89 e5                	mov    %esp,%ebp
80103350:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103353:	a1 24 09 11 80       	mov    0x80110924,%eax
80103358:	85 c0                	test   %eax,%eax
8010335a:	0f 84 9f 00 00 00    	je     801033ff <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103360:	c7 05 54 08 11 80 00 	movl   $0xfec00000,0x80110854
80103367:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010336a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103371:	e8 a6 ff ff ff       	call   8010331c <ioapicread>
80103376:	c1 e8 10             	shr    $0x10,%eax
80103379:	25 ff 00 00 00       	and    $0xff,%eax
8010337e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103381:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103388:	e8 8f ff ff ff       	call   8010331c <ioapicread>
8010338d:	c1 e8 18             	shr    $0x18,%eax
80103390:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103393:	0f b6 05 20 09 11 80 	movzbl 0x80110920,%eax
8010339a:	0f b6 c0             	movzbl %al,%eax
8010339d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801033a0:	74 0c                	je     801033ae <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801033a2:	c7 04 24 fc 8f 10 80 	movl   $0x80108ffc,(%esp)
801033a9:	e8 f3 cf ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801033ae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033b5:	eb 3e                	jmp    801033f5 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801033b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033ba:	83 c0 20             	add    $0x20,%eax
801033bd:	0d 00 00 01 00       	or     $0x10000,%eax
801033c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c5:	83 c2 08             	add    $0x8,%edx
801033c8:	01 d2                	add    %edx,%edx
801033ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801033ce:	89 14 24             	mov    %edx,(%esp)
801033d1:	e8 5d ff ff ff       	call   80103333 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801033d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d9:	83 c0 08             	add    $0x8,%eax
801033dc:	01 c0                	add    %eax,%eax
801033de:	83 c0 01             	add    $0x1,%eax
801033e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801033e8:	00 
801033e9:	89 04 24             	mov    %eax,(%esp)
801033ec:	e8 42 ff ff ff       	call   80103333 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801033f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033f8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801033fb:	7e ba                	jle    801033b7 <ioapicinit+0x6a>
801033fd:	eb 01                	jmp    80103400 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
801033ff:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103400:	c9                   	leave  
80103401:	c3                   	ret    

80103402 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103402:	55                   	push   %ebp
80103403:	89 e5                	mov    %esp,%ebp
80103405:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103408:	a1 24 09 11 80       	mov    0x80110924,%eax
8010340d:	85 c0                	test   %eax,%eax
8010340f:	74 39                	je     8010344a <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103411:	8b 45 08             	mov    0x8(%ebp),%eax
80103414:	83 c0 20             	add    $0x20,%eax
80103417:	8b 55 08             	mov    0x8(%ebp),%edx
8010341a:	83 c2 08             	add    $0x8,%edx
8010341d:	01 d2                	add    %edx,%edx
8010341f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103423:	89 14 24             	mov    %edx,(%esp)
80103426:	e8 08 ff ff ff       	call   80103333 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
8010342b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010342e:	c1 e0 18             	shl    $0x18,%eax
80103431:	8b 55 08             	mov    0x8(%ebp),%edx
80103434:	83 c2 08             	add    $0x8,%edx
80103437:	01 d2                	add    %edx,%edx
80103439:	83 c2 01             	add    $0x1,%edx
8010343c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103440:	89 14 24             	mov    %edx,(%esp)
80103443:	e8 eb fe ff ff       	call   80103333 <ioapicwrite>
80103448:	eb 01                	jmp    8010344b <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
8010344a:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
8010344b:	c9                   	leave  
8010344c:	c3                   	ret    
8010344d:	00 00                	add    %al,(%eax)
	...

80103450 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103450:	55                   	push   %ebp
80103451:	89 e5                	mov    %esp,%ebp
80103453:	8b 45 08             	mov    0x8(%ebp),%eax
80103456:	05 00 00 00 80       	add    $0x80000000,%eax
8010345b:	5d                   	pop    %ebp
8010345c:	c3                   	ret    

8010345d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
8010345d:	55                   	push   %ebp
8010345e:	89 e5                	mov    %esp,%ebp
80103460:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103463:	c7 44 24 04 2e 90 10 	movl   $0x8010902e,0x4(%esp)
8010346a:	80 
8010346b:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80103472:	e8 97 21 00 00       	call   8010560e <initlock>
  kmem.use_lock = 0;
80103477:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
8010347e:	00 00 00 
  freerange(vstart, vend);
80103481:	8b 45 0c             	mov    0xc(%ebp),%eax
80103484:	89 44 24 04          	mov    %eax,0x4(%esp)
80103488:	8b 45 08             	mov    0x8(%ebp),%eax
8010348b:	89 04 24             	mov    %eax,(%esp)
8010348e:	e8 26 00 00 00       	call   801034b9 <freerange>
}
80103493:	c9                   	leave  
80103494:	c3                   	ret    

80103495 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103495:	55                   	push   %ebp
80103496:	89 e5                	mov    %esp,%ebp
80103498:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
8010349b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010349e:	89 44 24 04          	mov    %eax,0x4(%esp)
801034a2:	8b 45 08             	mov    0x8(%ebp),%eax
801034a5:	89 04 24             	mov    %eax,(%esp)
801034a8:	e8 0c 00 00 00       	call   801034b9 <freerange>
  kmem.use_lock = 1;
801034ad:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
801034b4:	00 00 00 
}
801034b7:	c9                   	leave  
801034b8:	c3                   	ret    

801034b9 <freerange>:

void
freerange(void *vstart, void *vend)
{
801034b9:	55                   	push   %ebp
801034ba:	89 e5                	mov    %esp,%ebp
801034bc:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801034bf:	8b 45 08             	mov    0x8(%ebp),%eax
801034c2:	05 ff 0f 00 00       	add    $0xfff,%eax
801034c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801034cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801034cf:	eb 12                	jmp    801034e3 <freerange+0x2a>
    kfree(p);
801034d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d4:	89 04 24             	mov    %eax,(%esp)
801034d7:	e8 16 00 00 00       	call   801034f2 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801034dc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801034e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034e6:	05 00 10 00 00       	add    $0x1000,%eax
801034eb:	3b 45 0c             	cmp    0xc(%ebp),%eax
801034ee:	76 e1                	jbe    801034d1 <freerange+0x18>
    kfree(p);
}
801034f0:	c9                   	leave  
801034f1:	c3                   	ret    

801034f2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
801034f2:	55                   	push   %ebp
801034f3:	89 e5                	mov    %esp,%ebp
801034f5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
801034f8:	8b 45 08             	mov    0x8(%ebp),%eax
801034fb:	25 ff 0f 00 00       	and    $0xfff,%eax
80103500:	85 c0                	test   %eax,%eax
80103502:	75 1b                	jne    8010351f <kfree+0x2d>
80103504:	81 7d 08 1c 37 11 80 	cmpl   $0x8011371c,0x8(%ebp)
8010350b:	72 12                	jb     8010351f <kfree+0x2d>
8010350d:	8b 45 08             	mov    0x8(%ebp),%eax
80103510:	89 04 24             	mov    %eax,(%esp)
80103513:	e8 38 ff ff ff       	call   80103450 <v2p>
80103518:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
8010351d:	76 0c                	jbe    8010352b <kfree+0x39>
    panic("kfree");
8010351f:	c7 04 24 33 90 10 80 	movl   $0x80109033,(%esp)
80103526:	e8 12 d0 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010352b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103532:	00 
80103533:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010353a:	00 
8010353b:	8b 45 08             	mov    0x8(%ebp),%eax
8010353e:	89 04 24             	mov    %eax,(%esp)
80103541:	e8 38 23 00 00       	call   8010587e <memset>

  if(kmem.use_lock)
80103546:	a1 94 08 11 80       	mov    0x80110894,%eax
8010354b:	85 c0                	test   %eax,%eax
8010354d:	74 0c                	je     8010355b <kfree+0x69>
    acquire(&kmem.lock);
8010354f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80103556:	e8 d4 20 00 00       	call   8010562f <acquire>
  r = (struct run*)v;
8010355b:	8b 45 08             	mov    0x8(%ebp),%eax
8010355e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103561:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80103567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010356a:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
8010356c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010356f:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80103574:	a1 94 08 11 80       	mov    0x80110894,%eax
80103579:	85 c0                	test   %eax,%eax
8010357b:	74 0c                	je     80103589 <kfree+0x97>
    release(&kmem.lock);
8010357d:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80103584:	e8 08 21 00 00       	call   80105691 <release>
}
80103589:	c9                   	leave  
8010358a:	c3                   	ret    

8010358b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
8010358b:	55                   	push   %ebp
8010358c:	89 e5                	mov    %esp,%ebp
8010358e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103591:	a1 94 08 11 80       	mov    0x80110894,%eax
80103596:	85 c0                	test   %eax,%eax
80103598:	74 0c                	je     801035a6 <kalloc+0x1b>
    acquire(&kmem.lock);
8010359a:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801035a1:	e8 89 20 00 00       	call   8010562f <acquire>
  r = kmem.freelist;
801035a6:	a1 98 08 11 80       	mov    0x80110898,%eax
801035ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801035ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801035b2:	74 0a                	je     801035be <kalloc+0x33>
    kmem.freelist = r->next;
801035b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035b7:	8b 00                	mov    (%eax),%eax
801035b9:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
801035be:	a1 94 08 11 80       	mov    0x80110894,%eax
801035c3:	85 c0                	test   %eax,%eax
801035c5:	74 0c                	je     801035d3 <kalloc+0x48>
    release(&kmem.lock);
801035c7:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801035ce:	e8 be 20 00 00       	call   80105691 <release>
  return (char*)r;
801035d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801035d6:	c9                   	leave  
801035d7:	c3                   	ret    

801035d8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801035d8:	55                   	push   %ebp
801035d9:	89 e5                	mov    %esp,%ebp
801035db:	53                   	push   %ebx
801035dc:	83 ec 14             	sub    $0x14,%esp
801035df:	8b 45 08             	mov    0x8(%ebp),%eax
801035e2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801035e6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801035ea:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801035ee:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801035f2:	ec                   	in     (%dx),%al
801035f3:	89 c3                	mov    %eax,%ebx
801035f5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801035f8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801035fc:	83 c4 14             	add    $0x14,%esp
801035ff:	5b                   	pop    %ebx
80103600:	5d                   	pop    %ebp
80103601:	c3                   	ret    

80103602 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103602:	55                   	push   %ebp
80103603:	89 e5                	mov    %esp,%ebp
80103605:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103608:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010360f:	e8 c4 ff ff ff       	call   801035d8 <inb>
80103614:	0f b6 c0             	movzbl %al,%eax
80103617:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
8010361a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010361d:	83 e0 01             	and    $0x1,%eax
80103620:	85 c0                	test   %eax,%eax
80103622:	75 0a                	jne    8010362e <kbdgetc+0x2c>
    return -1;
80103624:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103629:	e9 23 01 00 00       	jmp    80103751 <kbdgetc+0x14f>
  data = inb(KBDATAP);
8010362e:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103635:	e8 9e ff ff ff       	call   801035d8 <inb>
8010363a:	0f b6 c0             	movzbl %al,%eax
8010363d:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103640:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103647:	75 17                	jne    80103660 <kbdgetc+0x5e>
    shift |= E0ESC;
80103649:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010364e:	83 c8 40             	or     $0x40,%eax
80103651:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103656:	b8 00 00 00 00       	mov    $0x0,%eax
8010365b:	e9 f1 00 00 00       	jmp    80103751 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103660:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103663:	25 80 00 00 00       	and    $0x80,%eax
80103668:	85 c0                	test   %eax,%eax
8010366a:	74 45                	je     801036b1 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
8010366c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103671:	83 e0 40             	and    $0x40,%eax
80103674:	85 c0                	test   %eax,%eax
80103676:	75 08                	jne    80103680 <kbdgetc+0x7e>
80103678:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010367b:	83 e0 7f             	and    $0x7f,%eax
8010367e:	eb 03                	jmp    80103683 <kbdgetc+0x81>
80103680:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103683:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103686:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103689:	05 20 a0 10 80       	add    $0x8010a020,%eax
8010368e:	0f b6 00             	movzbl (%eax),%eax
80103691:	83 c8 40             	or     $0x40,%eax
80103694:	0f b6 c0             	movzbl %al,%eax
80103697:	f7 d0                	not    %eax
80103699:	89 c2                	mov    %eax,%edx
8010369b:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801036a0:	21 d0                	and    %edx,%eax
801036a2:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
801036a7:	b8 00 00 00 00       	mov    $0x0,%eax
801036ac:	e9 a0 00 00 00       	jmp    80103751 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
801036b1:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801036b6:	83 e0 40             	and    $0x40,%eax
801036b9:	85 c0                	test   %eax,%eax
801036bb:	74 14                	je     801036d1 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801036bd:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801036c4:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801036c9:	83 e0 bf             	and    $0xffffffbf,%eax
801036cc:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
801036d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036d4:	05 20 a0 10 80       	add    $0x8010a020,%eax
801036d9:	0f b6 00             	movzbl (%eax),%eax
801036dc:	0f b6 d0             	movzbl %al,%edx
801036df:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801036e4:	09 d0                	or     %edx,%eax
801036e6:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
801036eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036ee:	05 20 a1 10 80       	add    $0x8010a120,%eax
801036f3:	0f b6 00             	movzbl (%eax),%eax
801036f6:	0f b6 d0             	movzbl %al,%edx
801036f9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801036fe:	31 d0                	xor    %edx,%eax
80103700:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103705:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010370a:	83 e0 03             	and    $0x3,%eax
8010370d:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103714:	03 45 fc             	add    -0x4(%ebp),%eax
80103717:	0f b6 00             	movzbl (%eax),%eax
8010371a:	0f b6 c0             	movzbl %al,%eax
8010371d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103720:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103725:	83 e0 08             	and    $0x8,%eax
80103728:	85 c0                	test   %eax,%eax
8010372a:	74 22                	je     8010374e <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
8010372c:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103730:	76 0c                	jbe    8010373e <kbdgetc+0x13c>
80103732:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103736:	77 06                	ja     8010373e <kbdgetc+0x13c>
      c += 'A' - 'a';
80103738:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
8010373c:	eb 10                	jmp    8010374e <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
8010373e:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103742:	76 0a                	jbe    8010374e <kbdgetc+0x14c>
80103744:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103748:	77 04                	ja     8010374e <kbdgetc+0x14c>
      c += 'a' - 'A';
8010374a:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
8010374e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103751:	c9                   	leave  
80103752:	c3                   	ret    

80103753 <kbdintr>:

void
kbdintr(void)
{
80103753:	55                   	push   %ebp
80103754:	89 e5                	mov    %esp,%ebp
80103756:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103759:	c7 04 24 02 36 10 80 	movl   $0x80103602,(%esp)
80103760:	e8 48 d0 ff ff       	call   801007ad <consoleintr>
}
80103765:	c9                   	leave  
80103766:	c3                   	ret    
	...

80103768 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103768:	55                   	push   %ebp
80103769:	89 e5                	mov    %esp,%ebp
8010376b:	83 ec 08             	sub    $0x8,%esp
8010376e:	8b 55 08             	mov    0x8(%ebp),%edx
80103771:	8b 45 0c             	mov    0xc(%ebp),%eax
80103774:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103778:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010377b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010377f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103783:	ee                   	out    %al,(%dx)
}
80103784:	c9                   	leave  
80103785:	c3                   	ret    

80103786 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103786:	55                   	push   %ebp
80103787:	89 e5                	mov    %esp,%ebp
80103789:	53                   	push   %ebx
8010378a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010378d:	9c                   	pushf  
8010378e:	5b                   	pop    %ebx
8010378f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103792:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103795:	83 c4 10             	add    $0x10,%esp
80103798:	5b                   	pop    %ebx
80103799:	5d                   	pop    %ebp
8010379a:	c3                   	ret    

8010379b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010379b:	55                   	push   %ebp
8010379c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010379e:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801037a3:	8b 55 08             	mov    0x8(%ebp),%edx
801037a6:	c1 e2 02             	shl    $0x2,%edx
801037a9:	01 c2                	add    %eax,%edx
801037ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801037ae:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801037b0:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801037b5:	83 c0 20             	add    $0x20,%eax
801037b8:	8b 00                	mov    (%eax),%eax
}
801037ba:	5d                   	pop    %ebp
801037bb:	c3                   	ret    

801037bc <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
801037bc:	55                   	push   %ebp
801037bd:	89 e5                	mov    %esp,%ebp
801037bf:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801037c2:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801037c7:	85 c0                	test   %eax,%eax
801037c9:	0f 84 47 01 00 00    	je     80103916 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801037cf:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801037d6:	00 
801037d7:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801037de:	e8 b8 ff ff ff       	call   8010379b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801037e3:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801037ea:	00 
801037eb:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801037f2:	e8 a4 ff ff ff       	call   8010379b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801037f7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801037fe:	00 
801037ff:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103806:	e8 90 ff ff ff       	call   8010379b <lapicw>
  lapicw(TICR, 10000000); 
8010380b:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103812:	00 
80103813:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
8010381a:	e8 7c ff ff ff       	call   8010379b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010381f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103826:	00 
80103827:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010382e:	e8 68 ff ff ff       	call   8010379b <lapicw>
  lapicw(LINT1, MASKED);
80103833:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010383a:	00 
8010383b:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103842:	e8 54 ff ff ff       	call   8010379b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103847:	a1 9c 08 11 80       	mov    0x8011089c,%eax
8010384c:	83 c0 30             	add    $0x30,%eax
8010384f:	8b 00                	mov    (%eax),%eax
80103851:	c1 e8 10             	shr    $0x10,%eax
80103854:	25 ff 00 00 00       	and    $0xff,%eax
80103859:	83 f8 03             	cmp    $0x3,%eax
8010385c:	76 14                	jbe    80103872 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010385e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103865:	00 
80103866:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010386d:	e8 29 ff ff ff       	call   8010379b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103872:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103879:	00 
8010387a:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103881:	e8 15 ff ff ff       	call   8010379b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103886:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010388d:	00 
8010388e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103895:	e8 01 ff ff ff       	call   8010379b <lapicw>
  lapicw(ESR, 0);
8010389a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801038a1:	00 
801038a2:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801038a9:	e8 ed fe ff ff       	call   8010379b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801038ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801038b5:	00 
801038b6:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801038bd:	e8 d9 fe ff ff       	call   8010379b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801038c2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801038c9:	00 
801038ca:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801038d1:	e8 c5 fe ff ff       	call   8010379b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801038d6:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801038dd:	00 
801038de:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801038e5:	e8 b1 fe ff ff       	call   8010379b <lapicw>
  while(lapic[ICRLO] & DELIVS)
801038ea:	90                   	nop
801038eb:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801038f0:	05 00 03 00 00       	add    $0x300,%eax
801038f5:	8b 00                	mov    (%eax),%eax
801038f7:	25 00 10 00 00       	and    $0x1000,%eax
801038fc:	85 c0                	test   %eax,%eax
801038fe:	75 eb                	jne    801038eb <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103900:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103907:	00 
80103908:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010390f:	e8 87 fe ff ff       	call   8010379b <lapicw>
80103914:	eb 01                	jmp    80103917 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103916:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103917:	c9                   	leave  
80103918:	c3                   	ret    

80103919 <cpunum>:

int
cpunum(void)
{
80103919:	55                   	push   %ebp
8010391a:	89 e5                	mov    %esp,%ebp
8010391c:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010391f:	e8 62 fe ff ff       	call   80103786 <readeflags>
80103924:	25 00 02 00 00       	and    $0x200,%eax
80103929:	85 c0                	test   %eax,%eax
8010392b:	74 29                	je     80103956 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
8010392d:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103932:	85 c0                	test   %eax,%eax
80103934:	0f 94 c2             	sete   %dl
80103937:	83 c0 01             	add    $0x1,%eax
8010393a:	a3 60 c6 10 80       	mov    %eax,0x8010c660
8010393f:	84 d2                	test   %dl,%dl
80103941:	74 13                	je     80103956 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103943:	8b 45 04             	mov    0x4(%ebp),%eax
80103946:	89 44 24 04          	mov    %eax,0x4(%esp)
8010394a:	c7 04 24 3c 90 10 80 	movl   $0x8010903c,(%esp)
80103951:	e8 4b ca ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103956:	a1 9c 08 11 80       	mov    0x8011089c,%eax
8010395b:	85 c0                	test   %eax,%eax
8010395d:	74 0f                	je     8010396e <cpunum+0x55>
    return lapic[ID]>>24;
8010395f:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103964:	83 c0 20             	add    $0x20,%eax
80103967:	8b 00                	mov    (%eax),%eax
80103969:	c1 e8 18             	shr    $0x18,%eax
8010396c:	eb 05                	jmp    80103973 <cpunum+0x5a>
  return 0;
8010396e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103973:	c9                   	leave  
80103974:	c3                   	ret    

80103975 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103975:	55                   	push   %ebp
80103976:	89 e5                	mov    %esp,%ebp
80103978:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010397b:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103980:	85 c0                	test   %eax,%eax
80103982:	74 14                	je     80103998 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103984:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010398b:	00 
8010398c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103993:	e8 03 fe ff ff       	call   8010379b <lapicw>
}
80103998:	c9                   	leave  
80103999:	c3                   	ret    

8010399a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010399a:	55                   	push   %ebp
8010399b:	89 e5                	mov    %esp,%ebp
}
8010399d:	5d                   	pop    %ebp
8010399e:	c3                   	ret    

8010399f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010399f:	55                   	push   %ebp
801039a0:	89 e5                	mov    %esp,%ebp
801039a2:	83 ec 1c             	sub    $0x1c,%esp
801039a5:	8b 45 08             	mov    0x8(%ebp),%eax
801039a8:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
801039ab:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801039b2:	00 
801039b3:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801039ba:	e8 a9 fd ff ff       	call   80103768 <outb>
  outb(IO_RTC+1, 0x0A);
801039bf:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801039c6:	00 
801039c7:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801039ce:	e8 95 fd ff ff       	call   80103768 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801039d3:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801039da:	8b 45 f8             	mov    -0x8(%ebp),%eax
801039dd:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801039e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801039e5:	8d 50 02             	lea    0x2(%eax),%edx
801039e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801039eb:	c1 e8 04             	shr    $0x4,%eax
801039ee:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801039f1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801039f5:	c1 e0 18             	shl    $0x18,%eax
801039f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801039fc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103a03:	e8 93 fd ff ff       	call   8010379b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103a08:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103a0f:	00 
80103a10:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103a17:	e8 7f fd ff ff       	call   8010379b <lapicw>
  microdelay(200);
80103a1c:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103a23:	e8 72 ff ff ff       	call   8010399a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103a28:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103a2f:	00 
80103a30:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103a37:	e8 5f fd ff ff       	call   8010379b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103a3c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103a43:	e8 52 ff ff ff       	call   8010399a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103a48:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a4f:	eb 40                	jmp    80103a91 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103a51:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103a55:	c1 e0 18             	shl    $0x18,%eax
80103a58:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a5c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103a63:	e8 33 fd ff ff       	call   8010379b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103a68:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a6b:	c1 e8 0c             	shr    $0xc,%eax
80103a6e:	80 cc 06             	or     $0x6,%ah
80103a71:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a75:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103a7c:	e8 1a fd ff ff       	call   8010379b <lapicw>
    microdelay(200);
80103a81:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103a88:	e8 0d ff ff ff       	call   8010399a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103a8d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a91:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103a95:	7e ba                	jle    80103a51 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103a97:	c9                   	leave  
80103a98:	c3                   	ret    
80103a99:	00 00                	add    %al,(%eax)
	...

80103a9c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103a9c:	55                   	push   %ebp
80103a9d:	89 e5                	mov    %esp,%ebp
80103a9f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103aa2:	c7 44 24 04 68 90 10 	movl   $0x80109068,0x4(%esp)
80103aa9:	80 
80103aaa:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103ab1:	e8 58 1b 00 00       	call   8010560e <initlock>
  readsb(ROOTDEV, &sb);
80103ab6:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103ab9:	89 44 24 04          	mov    %eax,0x4(%esp)
80103abd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103ac4:	e8 af e2 ff ff       	call   80101d78 <readsb>
  log.start = sb.size - sb.nlog;
80103ac9:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103acf:	89 d1                	mov    %edx,%ecx
80103ad1:	29 c1                	sub    %eax,%ecx
80103ad3:	89 c8                	mov    %ecx,%eax
80103ad5:	a3 d4 08 11 80       	mov    %eax,0x801108d4
  log.size = sb.nlog;
80103ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103add:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  log.dev = ROOTDEV;
80103ae2:	c7 05 e0 08 11 80 01 	movl   $0x1,0x801108e0
80103ae9:	00 00 00 
  recover_from_log();
80103aec:	e8 97 01 00 00       	call   80103c88 <recover_from_log>
}
80103af1:	c9                   	leave  
80103af2:	c3                   	ret    

80103af3 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103af3:	55                   	push   %ebp
80103af4:	89 e5                	mov    %esp,%ebp
80103af6:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103af9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b00:	e9 89 00 00 00       	jmp    80103b8e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103b05:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103b0a:	03 45 f4             	add    -0xc(%ebp),%eax
80103b0d:	83 c0 01             	add    $0x1,%eax
80103b10:	89 c2                	mov    %eax,%edx
80103b12:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103b17:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b1b:	89 04 24             	mov    %eax,(%esp)
80103b1e:	e8 83 c6 ff ff       	call   801001a6 <bread>
80103b23:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b29:	83 c0 10             	add    $0x10,%eax
80103b2c:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103b33:	89 c2                	mov    %eax,%edx
80103b35:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103b3a:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b3e:	89 04 24             	mov    %eax,(%esp)
80103b41:	e8 60 c6 ff ff       	call   801001a6 <bread>
80103b46:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103b49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b4c:	8d 50 18             	lea    0x18(%eax),%edx
80103b4f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b52:	83 c0 18             	add    $0x18,%eax
80103b55:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103b5c:	00 
80103b5d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103b61:	89 04 24             	mov    %eax,(%esp)
80103b64:	e8 e8 1d 00 00       	call   80105951 <memmove>
    bwrite(dbuf);  // write dst to disk
80103b69:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b6c:	89 04 24             	mov    %eax,(%esp)
80103b6f:	e8 69 c6 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103b74:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b77:	89 04 24             	mov    %eax,(%esp)
80103b7a:	e8 98 c6 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103b7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b82:	89 04 24             	mov    %eax,(%esp)
80103b85:	e8 8d c6 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103b8a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b8e:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103b93:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103b96:	0f 8f 69 ff ff ff    	jg     80103b05 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103b9c:	c9                   	leave  
80103b9d:	c3                   	ret    

80103b9e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103b9e:	55                   	push   %ebp
80103b9f:	89 e5                	mov    %esp,%ebp
80103ba1:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103ba4:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103ba9:	89 c2                	mov    %eax,%edx
80103bab:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103bb0:	89 54 24 04          	mov    %edx,0x4(%esp)
80103bb4:	89 04 24             	mov    %eax,(%esp)
80103bb7:	e8 ea c5 ff ff       	call   801001a6 <bread>
80103bbc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103bbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bc2:	83 c0 18             	add    $0x18,%eax
80103bc5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103bc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bcb:	8b 00                	mov    (%eax),%eax
80103bcd:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  for (i = 0; i < log.lh.n; i++) {
80103bd2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103bd9:	eb 1b                	jmp    80103bf6 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103bdb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103bde:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103be1:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103be5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103be8:	83 c2 10             	add    $0x10,%edx
80103beb:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103bf2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103bf6:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103bfb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bfe:	7f db                	jg     80103bdb <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103c00:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c03:	89 04 24             	mov    %eax,(%esp)
80103c06:	e8 0c c6 ff ff       	call   80100217 <brelse>
}
80103c0b:	c9                   	leave  
80103c0c:	c3                   	ret    

80103c0d <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103c0d:	55                   	push   %ebp
80103c0e:	89 e5                	mov    %esp,%ebp
80103c10:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103c13:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103c18:	89 c2                	mov    %eax,%edx
80103c1a:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103c1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c23:	89 04 24             	mov    %eax,(%esp)
80103c26:	e8 7b c5 ff ff       	call   801001a6 <bread>
80103c2b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103c2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c31:	83 c0 18             	add    $0x18,%eax
80103c34:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103c37:	8b 15 e4 08 11 80    	mov    0x801108e4,%edx
80103c3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c40:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103c42:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103c49:	eb 1b                	jmp    80103c66 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c4e:	83 c0 10             	add    $0x10,%eax
80103c51:	8b 0c 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%ecx
80103c58:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c5b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c5e:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103c62:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103c66:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103c6b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103c6e:	7f db                	jg     80103c4b <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103c70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c73:	89 04 24             	mov    %eax,(%esp)
80103c76:	e8 62 c5 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103c7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c7e:	89 04 24             	mov    %eax,(%esp)
80103c81:	e8 91 c5 ff ff       	call   80100217 <brelse>
}
80103c86:	c9                   	leave  
80103c87:	c3                   	ret    

80103c88 <recover_from_log>:

static void
recover_from_log(void)
{
80103c88:	55                   	push   %ebp
80103c89:	89 e5                	mov    %esp,%ebp
80103c8b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103c8e:	e8 0b ff ff ff       	call   80103b9e <read_head>
  install_trans(); // if committed, copy from log to disk
80103c93:	e8 5b fe ff ff       	call   80103af3 <install_trans>
  log.lh.n = 0;
80103c98:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
80103c9f:	00 00 00 
  write_head(); // clear the log
80103ca2:	e8 66 ff ff ff       	call   80103c0d <write_head>
}
80103ca7:	c9                   	leave  
80103ca8:	c3                   	ret    

80103ca9 <begin_trans>:

void
begin_trans(void)
{
80103ca9:	55                   	push   %ebp
80103caa:	89 e5                	mov    %esp,%ebp
80103cac:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103caf:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103cb6:	e8 74 19 00 00       	call   8010562f <acquire>
  while (log.busy) {
80103cbb:	eb 14                	jmp    80103cd1 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103cbd:	c7 44 24 04 a0 08 11 	movl   $0x801108a0,0x4(%esp)
80103cc4:	80 
80103cc5:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103ccc:	e8 80 16 00 00       	call   80105351 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103cd1:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103cd6:	85 c0                	test   %eax,%eax
80103cd8:	75 e3                	jne    80103cbd <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80103cda:	c7 05 dc 08 11 80 01 	movl   $0x1,0x801108dc
80103ce1:	00 00 00 
  release(&log.lock);
80103ce4:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103ceb:	e8 a1 19 00 00       	call   80105691 <release>
}
80103cf0:	c9                   	leave  
80103cf1:	c3                   	ret    

80103cf2 <commit_trans>:

void
commit_trans(void)
{
80103cf2:	55                   	push   %ebp
80103cf3:	89 e5                	mov    %esp,%ebp
80103cf5:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103cf8:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103cfd:	85 c0                	test   %eax,%eax
80103cff:	7e 19                	jle    80103d1a <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103d01:	e8 07 ff ff ff       	call   80103c0d <write_head>
    install_trans(); // Now install writes to home locations
80103d06:	e8 e8 fd ff ff       	call   80103af3 <install_trans>
    log.lh.n = 0; 
80103d0b:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
80103d12:	00 00 00 
    write_head();    // Erase the transaction from the log
80103d15:	e8 f3 fe ff ff       	call   80103c0d <write_head>
  }
  
  acquire(&log.lock);
80103d1a:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103d21:	e8 09 19 00 00       	call   8010562f <acquire>
  log.busy = 0;
80103d26:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80103d2d:	00 00 00 
  wakeup(&log);
80103d30:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103d37:	e8 ee 16 00 00       	call   8010542a <wakeup>
  release(&log.lock);
80103d3c:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103d43:	e8 49 19 00 00       	call   80105691 <release>
}
80103d48:	c9                   	leave  
80103d49:	c3                   	ret    

80103d4a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103d4a:	55                   	push   %ebp
80103d4b:	89 e5                	mov    %esp,%ebp
80103d4d:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103d50:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103d55:	83 f8 09             	cmp    $0x9,%eax
80103d58:	7f 12                	jg     80103d6c <log_write+0x22>
80103d5a:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103d5f:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80103d65:	83 ea 01             	sub    $0x1,%edx
80103d68:	39 d0                	cmp    %edx,%eax
80103d6a:	7c 0c                	jl     80103d78 <log_write+0x2e>
    panic("too big a transaction");
80103d6c:	c7 04 24 6c 90 10 80 	movl   $0x8010906c,(%esp)
80103d73:	e8 c5 c7 ff ff       	call   8010053d <panic>
  if (!log.busy)
80103d78:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103d7d:	85 c0                	test   %eax,%eax
80103d7f:	75 0c                	jne    80103d8d <log_write+0x43>
    panic("write outside of trans");
80103d81:	c7 04 24 82 90 10 80 	movl   $0x80109082,(%esp)
80103d88:	e8 b0 c7 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103d8d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d94:	eb 1d                	jmp    80103db3 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103d96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d99:	83 c0 10             	add    $0x10,%eax
80103d9c:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103da3:	89 c2                	mov    %eax,%edx
80103da5:	8b 45 08             	mov    0x8(%ebp),%eax
80103da8:	8b 40 08             	mov    0x8(%eax),%eax
80103dab:	39 c2                	cmp    %eax,%edx
80103dad:	74 10                	je     80103dbf <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103daf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103db3:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103db8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103dbb:	7f d9                	jg     80103d96 <log_write+0x4c>
80103dbd:	eb 01                	jmp    80103dc0 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103dbf:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103dc0:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc3:	8b 40 08             	mov    0x8(%eax),%eax
80103dc6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103dc9:	83 c2 10             	add    $0x10,%edx
80103dcc:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103dd3:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103dd8:	03 45 f4             	add    -0xc(%ebp),%eax
80103ddb:	83 c0 01             	add    $0x1,%eax
80103dde:	89 c2                	mov    %eax,%edx
80103de0:	8b 45 08             	mov    0x8(%ebp),%eax
80103de3:	8b 40 04             	mov    0x4(%eax),%eax
80103de6:	89 54 24 04          	mov    %edx,0x4(%esp)
80103dea:	89 04 24             	mov    %eax,(%esp)
80103ded:	e8 b4 c3 ff ff       	call   801001a6 <bread>
80103df2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103df5:	8b 45 08             	mov    0x8(%ebp),%eax
80103df8:	8d 50 18             	lea    0x18(%eax),%edx
80103dfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103dfe:	83 c0 18             	add    $0x18,%eax
80103e01:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103e08:	00 
80103e09:	89 54 24 04          	mov    %edx,0x4(%esp)
80103e0d:	89 04 24             	mov    %eax,(%esp)
80103e10:	e8 3c 1b 00 00       	call   80105951 <memmove>
  bwrite(lbuf);
80103e15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e18:	89 04 24             	mov    %eax,(%esp)
80103e1b:	e8 bd c3 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103e20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e23:	89 04 24             	mov    %eax,(%esp)
80103e26:	e8 ec c3 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103e2b:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103e30:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103e33:	75 0d                	jne    80103e42 <log_write+0xf8>
    log.lh.n++;
80103e35:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103e3a:	83 c0 01             	add    $0x1,%eax
80103e3d:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103e42:	8b 45 08             	mov    0x8(%ebp),%eax
80103e45:	8b 00                	mov    (%eax),%eax
80103e47:	89 c2                	mov    %eax,%edx
80103e49:	83 ca 04             	or     $0x4,%edx
80103e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4f:	89 10                	mov    %edx,(%eax)
}
80103e51:	c9                   	leave  
80103e52:	c3                   	ret    
	...

80103e54 <v2p>:
80103e54:	55                   	push   %ebp
80103e55:	89 e5                	mov    %esp,%ebp
80103e57:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5a:	05 00 00 00 80       	add    $0x80000000,%eax
80103e5f:	5d                   	pop    %ebp
80103e60:	c3                   	ret    

80103e61 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103e61:	55                   	push   %ebp
80103e62:	89 e5                	mov    %esp,%ebp
80103e64:	8b 45 08             	mov    0x8(%ebp),%eax
80103e67:	05 00 00 00 80       	add    $0x80000000,%eax
80103e6c:	5d                   	pop    %ebp
80103e6d:	c3                   	ret    

80103e6e <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103e6e:	55                   	push   %ebp
80103e6f:	89 e5                	mov    %esp,%ebp
80103e71:	53                   	push   %ebx
80103e72:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103e75:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103e78:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103e7b:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103e7e:	89 c3                	mov    %eax,%ebx
80103e80:	89 d8                	mov    %ebx,%eax
80103e82:	f0 87 02             	lock xchg %eax,(%edx)
80103e85:	89 c3                	mov    %eax,%ebx
80103e87:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103e8a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103e8d:	83 c4 10             	add    $0x10,%esp
80103e90:	5b                   	pop    %ebx
80103e91:	5d                   	pop    %ebp
80103e92:	c3                   	ret    

80103e93 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103e93:	55                   	push   %ebp
80103e94:	89 e5                	mov    %esp,%ebp
80103e96:	83 e4 f0             	and    $0xfffffff0,%esp
80103e99:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103e9c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103ea3:	80 
80103ea4:	c7 04 24 1c 37 11 80 	movl   $0x8011371c,(%esp)
80103eab:	e8 ad f5 ff ff       	call   8010345d <kinit1>
  kvmalloc();      // kernel page table
80103eb0:	e8 69 47 00 00       	call   8010861e <kvmalloc>
  mpinit();        // collect info about this machine
80103eb5:	e8 63 04 00 00       	call   8010431d <mpinit>
  lapicinit(mpbcpu());
80103eba:	e8 2e 02 00 00       	call   801040ed <mpbcpu>
80103ebf:	89 04 24             	mov    %eax,(%esp)
80103ec2:	e8 f5 f8 ff ff       	call   801037bc <lapicinit>
  seginit();       // set up segments
80103ec7:	e8 f5 40 00 00       	call   80107fc1 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103ecc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103ed2:	0f b6 00             	movzbl (%eax),%eax
80103ed5:	0f b6 c0             	movzbl %al,%eax
80103ed8:	89 44 24 04          	mov    %eax,0x4(%esp)
80103edc:	c7 04 24 99 90 10 80 	movl   $0x80109099,(%esp)
80103ee3:	e8 b9 c4 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103ee8:	e8 95 06 00 00       	call   80104582 <picinit>
  ioapicinit();    // another interrupt controller
80103eed:	e8 5b f4 ff ff       	call   8010334d <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ef2:	e8 96 cb ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103ef7:	e8 10 34 00 00       	call   8010730c <uartinit>
  pinit();         // process table
80103efc:	e8 96 0b 00 00       	call   80104a97 <pinit>
  tvinit();        // trap vectors
80103f01:	e8 a9 2f 00 00       	call   80106eaf <tvinit>
  binit();         // buffer cache
80103f06:	e8 29 c1 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103f0b:	e8 f0 cf ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80103f10:	e8 2a e1 ff ff       	call   8010203f <iinit>
  ideinit();       // disk
80103f15:	e8 98 f0 ff ff       	call   80102fb2 <ideinit>
  if(!ismp)
80103f1a:	a1 24 09 11 80       	mov    0x80110924,%eax
80103f1f:	85 c0                	test   %eax,%eax
80103f21:	75 05                	jne    80103f28 <main+0x95>
    timerinit();   // uniprocessor timer
80103f23:	e8 ca 2e 00 00       	call   80106df2 <timerinit>
  startothers();   // start other processors
80103f28:	e8 87 00 00 00       	call   80103fb4 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103f2d:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103f34:	8e 
80103f35:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103f3c:	e8 54 f5 ff ff       	call   80103495 <kinit2>
  userinit();      // first user process
80103f41:	e8 6c 0c 00 00       	call   80104bb2 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103f46:	e8 22 00 00 00       	call   80103f6d <mpmain>

80103f4b <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103f4b:	55                   	push   %ebp
80103f4c:	89 e5                	mov    %esp,%ebp
80103f4e:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103f51:	e8 df 46 00 00       	call   80108635 <switchkvm>
  seginit();
80103f56:	e8 66 40 00 00       	call   80107fc1 <seginit>
  lapicinit(cpunum());
80103f5b:	e8 b9 f9 ff ff       	call   80103919 <cpunum>
80103f60:	89 04 24             	mov    %eax,(%esp)
80103f63:	e8 54 f8 ff ff       	call   801037bc <lapicinit>
  mpmain();
80103f68:	e8 00 00 00 00       	call   80103f6d <mpmain>

80103f6d <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103f6d:	55                   	push   %ebp
80103f6e:	89 e5                	mov    %esp,%ebp
80103f70:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103f73:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f79:	0f b6 00             	movzbl (%eax),%eax
80103f7c:	0f b6 c0             	movzbl %al,%eax
80103f7f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f83:	c7 04 24 b0 90 10 80 	movl   $0x801090b0,(%esp)
80103f8a:	e8 12 c4 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103f8f:	e8 8f 30 00 00       	call   80107023 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103f94:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103f9a:	05 a8 00 00 00       	add    $0xa8,%eax
80103f9f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103fa6:	00 
80103fa7:	89 04 24             	mov    %eax,(%esp)
80103faa:	e8 bf fe ff ff       	call   80103e6e <xchg>
  scheduler();     // start running processes
80103faf:	e8 f4 11 00 00       	call   801051a8 <scheduler>

80103fb4 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103fb4:	55                   	push   %ebp
80103fb5:	89 e5                	mov    %esp,%ebp
80103fb7:	53                   	push   %ebx
80103fb8:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103fbb:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103fc2:	e8 9a fe ff ff       	call   80103e61 <p2v>
80103fc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103fca:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103fcf:	89 44 24 08          	mov    %eax,0x8(%esp)
80103fd3:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103fda:	80 
80103fdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fde:	89 04 24             	mov    %eax,(%esp)
80103fe1:	e8 6b 19 00 00       	call   80105951 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103fe6:	c7 45 f4 40 09 11 80 	movl   $0x80110940,-0xc(%ebp)
80103fed:	e9 86 00 00 00       	jmp    80104078 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103ff2:	e8 22 f9 ff ff       	call   80103919 <cpunum>
80103ff7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103ffd:	05 40 09 11 80       	add    $0x80110940,%eax
80104002:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104005:	74 69                	je     80104070 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104007:	e8 7f f5 ff ff       	call   8010358b <kalloc>
8010400c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010400f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104012:	83 e8 04             	sub    $0x4,%eax
80104015:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104018:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010401e:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104020:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104023:	83 e8 08             	sub    $0x8,%eax
80104026:	c7 00 4b 3f 10 80    	movl   $0x80103f4b,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
8010402c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010402f:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104032:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104039:	e8 16 fe ff ff       	call   80103e54 <v2p>
8010403e:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104040:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104043:	89 04 24             	mov    %eax,(%esp)
80104046:	e8 09 fe ff ff       	call   80103e54 <v2p>
8010404b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010404e:	0f b6 12             	movzbl (%edx),%edx
80104051:	0f b6 d2             	movzbl %dl,%edx
80104054:	89 44 24 04          	mov    %eax,0x4(%esp)
80104058:	89 14 24             	mov    %edx,(%esp)
8010405b:	e8 3f f9 ff ff       	call   8010399f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104060:	90                   	nop
80104061:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104064:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010406a:	85 c0                	test   %eax,%eax
8010406c:	74 f3                	je     80104061 <startothers+0xad>
8010406e:	eb 01                	jmp    80104071 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80104070:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104071:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104078:	a1 20 0f 11 80       	mov    0x80110f20,%eax
8010407d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104083:	05 40 09 11 80       	add    $0x80110940,%eax
80104088:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010408b:	0f 87 61 ff ff ff    	ja     80103ff2 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104091:	83 c4 24             	add    $0x24,%esp
80104094:	5b                   	pop    %ebx
80104095:	5d                   	pop    %ebp
80104096:	c3                   	ret    
	...

80104098 <p2v>:
80104098:	55                   	push   %ebp
80104099:	89 e5                	mov    %esp,%ebp
8010409b:	8b 45 08             	mov    0x8(%ebp),%eax
8010409e:	05 00 00 00 80       	add    $0x80000000,%eax
801040a3:	5d                   	pop    %ebp
801040a4:	c3                   	ret    

801040a5 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801040a5:	55                   	push   %ebp
801040a6:	89 e5                	mov    %esp,%ebp
801040a8:	53                   	push   %ebx
801040a9:	83 ec 14             	sub    $0x14,%esp
801040ac:	8b 45 08             	mov    0x8(%ebp),%eax
801040af:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801040b3:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801040b7:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801040bb:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801040bf:	ec                   	in     (%dx),%al
801040c0:	89 c3                	mov    %eax,%ebx
801040c2:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801040c5:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801040c9:	83 c4 14             	add    $0x14,%esp
801040cc:	5b                   	pop    %ebx
801040cd:	5d                   	pop    %ebp
801040ce:	c3                   	ret    

801040cf <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040cf:	55                   	push   %ebp
801040d0:	89 e5                	mov    %esp,%ebp
801040d2:	83 ec 08             	sub    $0x8,%esp
801040d5:	8b 55 08             	mov    0x8(%ebp),%edx
801040d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801040db:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040df:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040e2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040e6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040ea:	ee                   	out    %al,(%dx)
}
801040eb:	c9                   	leave  
801040ec:	c3                   	ret    

801040ed <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801040ed:	55                   	push   %ebp
801040ee:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801040f0:	a1 64 c6 10 80       	mov    0x8010c664,%eax
801040f5:	89 c2                	mov    %eax,%edx
801040f7:	b8 40 09 11 80       	mov    $0x80110940,%eax
801040fc:	89 d1                	mov    %edx,%ecx
801040fe:	29 c1                	sub    %eax,%ecx
80104100:	89 c8                	mov    %ecx,%eax
80104102:	c1 f8 02             	sar    $0x2,%eax
80104105:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010410b:	5d                   	pop    %ebp
8010410c:	c3                   	ret    

8010410d <sum>:

static uchar
sum(uchar *addr, int len)
{
8010410d:	55                   	push   %ebp
8010410e:	89 e5                	mov    %esp,%ebp
80104110:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104113:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010411a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104121:	eb 13                	jmp    80104136 <sum+0x29>
    sum += addr[i];
80104123:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104126:	03 45 08             	add    0x8(%ebp),%eax
80104129:	0f b6 00             	movzbl (%eax),%eax
8010412c:	0f b6 c0             	movzbl %al,%eax
8010412f:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104132:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104136:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104139:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010413c:	7c e5                	jl     80104123 <sum+0x16>
    sum += addr[i];
  return sum;
8010413e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104141:	c9                   	leave  
80104142:	c3                   	ret    

80104143 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104143:	55                   	push   %ebp
80104144:	89 e5                	mov    %esp,%ebp
80104146:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104149:	8b 45 08             	mov    0x8(%ebp),%eax
8010414c:	89 04 24             	mov    %eax,(%esp)
8010414f:	e8 44 ff ff ff       	call   80104098 <p2v>
80104154:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104157:	8b 45 0c             	mov    0xc(%ebp),%eax
8010415a:	03 45 f0             	add    -0x10(%ebp),%eax
8010415d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104160:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104163:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104166:	eb 3f                	jmp    801041a7 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104168:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010416f:	00 
80104170:	c7 44 24 04 c4 90 10 	movl   $0x801090c4,0x4(%esp)
80104177:	80 
80104178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417b:	89 04 24             	mov    %eax,(%esp)
8010417e:	e8 72 17 00 00       	call   801058f5 <memcmp>
80104183:	85 c0                	test   %eax,%eax
80104185:	75 1c                	jne    801041a3 <mpsearch1+0x60>
80104187:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010418e:	00 
8010418f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104192:	89 04 24             	mov    %eax,(%esp)
80104195:	e8 73 ff ff ff       	call   8010410d <sum>
8010419a:	84 c0                	test   %al,%al
8010419c:	75 05                	jne    801041a3 <mpsearch1+0x60>
      return (struct mp*)p;
8010419e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a1:	eb 11                	jmp    801041b4 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801041a3:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801041a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041aa:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801041ad:	72 b9                	jb     80104168 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801041af:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041b4:	c9                   	leave  
801041b5:	c3                   	ret    

801041b6 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801041b6:	55                   	push   %ebp
801041b7:	89 e5                	mov    %esp,%ebp
801041b9:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801041bc:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801041c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041c6:	83 c0 0f             	add    $0xf,%eax
801041c9:	0f b6 00             	movzbl (%eax),%eax
801041cc:	0f b6 c0             	movzbl %al,%eax
801041cf:	89 c2                	mov    %eax,%edx
801041d1:	c1 e2 08             	shl    $0x8,%edx
801041d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d7:	83 c0 0e             	add    $0xe,%eax
801041da:	0f b6 00             	movzbl (%eax),%eax
801041dd:	0f b6 c0             	movzbl %al,%eax
801041e0:	09 d0                	or     %edx,%eax
801041e2:	c1 e0 04             	shl    $0x4,%eax
801041e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801041e8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801041ec:	74 21                	je     8010420f <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801041ee:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801041f5:	00 
801041f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041f9:	89 04 24             	mov    %eax,(%esp)
801041fc:	e8 42 ff ff ff       	call   80104143 <mpsearch1>
80104201:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104204:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104208:	74 50                	je     8010425a <mpsearch+0xa4>
      return mp;
8010420a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010420d:	eb 5f                	jmp    8010426e <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010420f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104212:	83 c0 14             	add    $0x14,%eax
80104215:	0f b6 00             	movzbl (%eax),%eax
80104218:	0f b6 c0             	movzbl %al,%eax
8010421b:	89 c2                	mov    %eax,%edx
8010421d:	c1 e2 08             	shl    $0x8,%edx
80104220:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104223:	83 c0 13             	add    $0x13,%eax
80104226:	0f b6 00             	movzbl (%eax),%eax
80104229:	0f b6 c0             	movzbl %al,%eax
8010422c:	09 d0                	or     %edx,%eax
8010422e:	c1 e0 0a             	shl    $0xa,%eax
80104231:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104234:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104237:	2d 00 04 00 00       	sub    $0x400,%eax
8010423c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104243:	00 
80104244:	89 04 24             	mov    %eax,(%esp)
80104247:	e8 f7 fe ff ff       	call   80104143 <mpsearch1>
8010424c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010424f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104253:	74 05                	je     8010425a <mpsearch+0xa4>
      return mp;
80104255:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104258:	eb 14                	jmp    8010426e <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010425a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104261:	00 
80104262:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104269:	e8 d5 fe ff ff       	call   80104143 <mpsearch1>
}
8010426e:	c9                   	leave  
8010426f:	c3                   	ret    

80104270 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104270:	55                   	push   %ebp
80104271:	89 e5                	mov    %esp,%ebp
80104273:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104276:	e8 3b ff ff ff       	call   801041b6 <mpsearch>
8010427b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010427e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104282:	74 0a                	je     8010428e <mpconfig+0x1e>
80104284:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104287:	8b 40 04             	mov    0x4(%eax),%eax
8010428a:	85 c0                	test   %eax,%eax
8010428c:	75 0a                	jne    80104298 <mpconfig+0x28>
    return 0;
8010428e:	b8 00 00 00 00       	mov    $0x0,%eax
80104293:	e9 83 00 00 00       	jmp    8010431b <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429b:	8b 40 04             	mov    0x4(%eax),%eax
8010429e:	89 04 24             	mov    %eax,(%esp)
801042a1:	e8 f2 fd ff ff       	call   80104098 <p2v>
801042a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801042a9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801042b0:	00 
801042b1:	c7 44 24 04 c9 90 10 	movl   $0x801090c9,0x4(%esp)
801042b8:	80 
801042b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042bc:	89 04 24             	mov    %eax,(%esp)
801042bf:	e8 31 16 00 00       	call   801058f5 <memcmp>
801042c4:	85 c0                	test   %eax,%eax
801042c6:	74 07                	je     801042cf <mpconfig+0x5f>
    return 0;
801042c8:	b8 00 00 00 00       	mov    $0x0,%eax
801042cd:	eb 4c                	jmp    8010431b <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801042cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042d2:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042d6:	3c 01                	cmp    $0x1,%al
801042d8:	74 12                	je     801042ec <mpconfig+0x7c>
801042da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042dd:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801042e1:	3c 04                	cmp    $0x4,%al
801042e3:	74 07                	je     801042ec <mpconfig+0x7c>
    return 0;
801042e5:	b8 00 00 00 00       	mov    $0x0,%eax
801042ea:	eb 2f                	jmp    8010431b <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801042ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042ef:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801042f3:	0f b7 c0             	movzwl %ax,%eax
801042f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801042fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042fd:	89 04 24             	mov    %eax,(%esp)
80104300:	e8 08 fe ff ff       	call   8010410d <sum>
80104305:	84 c0                	test   %al,%al
80104307:	74 07                	je     80104310 <mpconfig+0xa0>
    return 0;
80104309:	b8 00 00 00 00       	mov    $0x0,%eax
8010430e:	eb 0b                	jmp    8010431b <mpconfig+0xab>
  *pmp = mp;
80104310:	8b 45 08             	mov    0x8(%ebp),%eax
80104313:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104316:	89 10                	mov    %edx,(%eax)
  return conf;
80104318:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010431b:	c9                   	leave  
8010431c:	c3                   	ret    

8010431d <mpinit>:

void
mpinit(void)
{
8010431d:	55                   	push   %ebp
8010431e:	89 e5                	mov    %esp,%ebp
80104320:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104323:	c7 05 64 c6 10 80 40 	movl   $0x80110940,0x8010c664
8010432a:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
8010432d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104330:	89 04 24             	mov    %eax,(%esp)
80104333:	e8 38 ff ff ff       	call   80104270 <mpconfig>
80104338:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010433b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010433f:	0f 84 9c 01 00 00    	je     801044e1 <mpinit+0x1c4>
    return;
  ismp = 1;
80104345:	c7 05 24 09 11 80 01 	movl   $0x1,0x80110924
8010434c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010434f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104352:	8b 40 24             	mov    0x24(%eax),%eax
80104355:	a3 9c 08 11 80       	mov    %eax,0x8011089c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010435a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010435d:	83 c0 2c             	add    $0x2c,%eax
80104360:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104363:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104366:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010436a:	0f b7 c0             	movzwl %ax,%eax
8010436d:	03 45 f0             	add    -0x10(%ebp),%eax
80104370:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104373:	e9 f4 00 00 00       	jmp    8010446c <mpinit+0x14f>
    switch(*p){
80104378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010437b:	0f b6 00             	movzbl (%eax),%eax
8010437e:	0f b6 c0             	movzbl %al,%eax
80104381:	83 f8 04             	cmp    $0x4,%eax
80104384:	0f 87 bf 00 00 00    	ja     80104449 <mpinit+0x12c>
8010438a:	8b 04 85 0c 91 10 80 	mov    -0x7fef6ef4(,%eax,4),%eax
80104391:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104396:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104399:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010439c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043a0:	0f b6 d0             	movzbl %al,%edx
801043a3:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801043a8:	39 c2                	cmp    %eax,%edx
801043aa:	74 2d                	je     801043d9 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801043ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043af:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801043b3:	0f b6 d0             	movzbl %al,%edx
801043b6:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801043bb:	89 54 24 08          	mov    %edx,0x8(%esp)
801043bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801043c3:	c7 04 24 ce 90 10 80 	movl   $0x801090ce,(%esp)
801043ca:	e8 d2 bf ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801043cf:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801043d6:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801043d9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801043dc:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801043e0:	0f b6 c0             	movzbl %al,%eax
801043e3:	83 e0 02             	and    $0x2,%eax
801043e6:	85 c0                	test   %eax,%eax
801043e8:	74 15                	je     801043ff <mpinit+0xe2>
        bcpu = &cpus[ncpu];
801043ea:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801043ef:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801043f5:	05 40 09 11 80       	add    $0x80110940,%eax
801043fa:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
801043ff:	8b 15 20 0f 11 80    	mov    0x80110f20,%edx
80104405:	a1 20 0f 11 80       	mov    0x80110f20,%eax
8010440a:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104410:	81 c2 40 09 11 80    	add    $0x80110940,%edx
80104416:	88 02                	mov    %al,(%edx)
      ncpu++;
80104418:	a1 20 0f 11 80       	mov    0x80110f20,%eax
8010441d:	83 c0 01             	add    $0x1,%eax
80104420:	a3 20 0f 11 80       	mov    %eax,0x80110f20
      p += sizeof(struct mpproc);
80104425:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104429:	eb 41                	jmp    8010446c <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010442b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010442e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104431:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104434:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104438:	a2 20 09 11 80       	mov    %al,0x80110920
      p += sizeof(struct mpioapic);
8010443d:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104441:	eb 29                	jmp    8010446c <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104443:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104447:	eb 23                	jmp    8010446c <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444c:	0f b6 00             	movzbl (%eax),%eax
8010444f:	0f b6 c0             	movzbl %al,%eax
80104452:	89 44 24 04          	mov    %eax,0x4(%esp)
80104456:	c7 04 24 ec 90 10 80 	movl   $0x801090ec,(%esp)
8010445d:	e8 3f bf ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104462:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
80104469:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010446c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010446f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104472:	0f 82 00 ff ff ff    	jb     80104378 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104478:	a1 24 09 11 80       	mov    0x80110924,%eax
8010447d:	85 c0                	test   %eax,%eax
8010447f:	75 1d                	jne    8010449e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104481:	c7 05 20 0f 11 80 01 	movl   $0x1,0x80110f20
80104488:	00 00 00 
    lapic = 0;
8010448b:	c7 05 9c 08 11 80 00 	movl   $0x0,0x8011089c
80104492:	00 00 00 
    ioapicid = 0;
80104495:	c6 05 20 09 11 80 00 	movb   $0x0,0x80110920
    return;
8010449c:	eb 44                	jmp    801044e2 <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010449e:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044a1:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801044a5:	84 c0                	test   %al,%al
801044a7:	74 39                	je     801044e2 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801044a9:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801044b0:	00 
801044b1:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801044b8:	e8 12 fc ff ff       	call   801040cf <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801044bd:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044c4:	e8 dc fb ff ff       	call   801040a5 <inb>
801044c9:	83 c8 01             	or     $0x1,%eax
801044cc:	0f b6 c0             	movzbl %al,%eax
801044cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801044d3:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801044da:	e8 f0 fb ff ff       	call   801040cf <outb>
801044df:	eb 01                	jmp    801044e2 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
801044e1:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
801044e2:	c9                   	leave  
801044e3:	c3                   	ret    

801044e4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044e4:	55                   	push   %ebp
801044e5:	89 e5                	mov    %esp,%ebp
801044e7:	83 ec 08             	sub    $0x8,%esp
801044ea:	8b 55 08             	mov    0x8(%ebp),%edx
801044ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801044f0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044f4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044f7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801044fb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801044ff:	ee                   	out    %al,(%dx)
}
80104500:	c9                   	leave  
80104501:	c3                   	ret    

80104502 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104502:	55                   	push   %ebp
80104503:	89 e5                	mov    %esp,%ebp
80104505:	83 ec 0c             	sub    $0xc,%esp
80104508:	8b 45 08             	mov    0x8(%ebp),%eax
8010450b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010450f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104513:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104519:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010451d:	0f b6 c0             	movzbl %al,%eax
80104520:	89 44 24 04          	mov    %eax,0x4(%esp)
80104524:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010452b:	e8 b4 ff ff ff       	call   801044e4 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104530:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104534:	66 c1 e8 08          	shr    $0x8,%ax
80104538:	0f b6 c0             	movzbl %al,%eax
8010453b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010453f:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104546:	e8 99 ff ff ff       	call   801044e4 <outb>
}
8010454b:	c9                   	leave  
8010454c:	c3                   	ret    

8010454d <picenable>:

void
picenable(int irq)
{
8010454d:	55                   	push   %ebp
8010454e:	89 e5                	mov    %esp,%ebp
80104550:	53                   	push   %ebx
80104551:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104554:	8b 45 08             	mov    0x8(%ebp),%eax
80104557:	ba 01 00 00 00       	mov    $0x1,%edx
8010455c:	89 d3                	mov    %edx,%ebx
8010455e:	89 c1                	mov    %eax,%ecx
80104560:	d3 e3                	shl    %cl,%ebx
80104562:	89 d8                	mov    %ebx,%eax
80104564:	89 c2                	mov    %eax,%edx
80104566:	f7 d2                	not    %edx
80104568:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010456f:	21 d0                	and    %edx,%eax
80104571:	0f b7 c0             	movzwl %ax,%eax
80104574:	89 04 24             	mov    %eax,(%esp)
80104577:	e8 86 ff ff ff       	call   80104502 <picsetmask>
}
8010457c:	83 c4 04             	add    $0x4,%esp
8010457f:	5b                   	pop    %ebx
80104580:	5d                   	pop    %ebp
80104581:	c3                   	ret    

80104582 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104582:	55                   	push   %ebp
80104583:	89 e5                	mov    %esp,%ebp
80104585:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104588:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010458f:	00 
80104590:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104597:	e8 48 ff ff ff       	call   801044e4 <outb>
  outb(IO_PIC2+1, 0xFF);
8010459c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801045a3:	00 
801045a4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801045ab:	e8 34 ff ff ff       	call   801044e4 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801045b0:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801045b7:	00 
801045b8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801045bf:	e8 20 ff ff ff       	call   801044e4 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801045c4:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801045cb:	00 
801045cc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045d3:	e8 0c ff ff ff       	call   801044e4 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801045d8:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801045df:	00 
801045e0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045e7:	e8 f8 fe ff ff       	call   801044e4 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801045ec:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801045f3:	00 
801045f4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801045fb:	e8 e4 fe ff ff       	call   801044e4 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104600:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104607:	00 
80104608:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010460f:	e8 d0 fe ff ff       	call   801044e4 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104614:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
8010461b:	00 
8010461c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104623:	e8 bc fe ff ff       	call   801044e4 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104628:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010462f:	00 
80104630:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104637:	e8 a8 fe ff ff       	call   801044e4 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
8010463c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104643:	00 
80104644:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010464b:	e8 94 fe ff ff       	call   801044e4 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104650:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104657:	00 
80104658:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010465f:	e8 80 fe ff ff       	call   801044e4 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104664:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010466b:	00 
8010466c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104673:	e8 6c fe ff ff       	call   801044e4 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104678:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010467f:	00 
80104680:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104687:	e8 58 fe ff ff       	call   801044e4 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
8010468c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104693:	00 
80104694:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010469b:	e8 44 fe ff ff       	call   801044e4 <outb>

  if(irqmask != 0xFFFF)
801046a0:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801046a7:	66 83 f8 ff          	cmp    $0xffff,%ax
801046ab:	74 12                	je     801046bf <picinit+0x13d>
    picsetmask(irqmask);
801046ad:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801046b4:	0f b7 c0             	movzwl %ax,%eax
801046b7:	89 04 24             	mov    %eax,(%esp)
801046ba:	e8 43 fe ff ff       	call   80104502 <picsetmask>
}
801046bf:	c9                   	leave  
801046c0:	c3                   	ret    
801046c1:	00 00                	add    %al,(%eax)
	...

801046c4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801046c4:	55                   	push   %ebp
801046c5:	89 e5                	mov    %esp,%ebp
801046c7:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801046ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801046d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801046d4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801046da:	8b 45 0c             	mov    0xc(%ebp),%eax
801046dd:	8b 10                	mov    (%eax),%edx
801046df:	8b 45 08             	mov    0x8(%ebp),%eax
801046e2:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801046e4:	e8 33 c8 ff ff       	call   80100f1c <filealloc>
801046e9:	8b 55 08             	mov    0x8(%ebp),%edx
801046ec:	89 02                	mov    %eax,(%edx)
801046ee:	8b 45 08             	mov    0x8(%ebp),%eax
801046f1:	8b 00                	mov    (%eax),%eax
801046f3:	85 c0                	test   %eax,%eax
801046f5:	0f 84 c8 00 00 00    	je     801047c3 <pipealloc+0xff>
801046fb:	e8 1c c8 ff ff       	call   80100f1c <filealloc>
80104700:	8b 55 0c             	mov    0xc(%ebp),%edx
80104703:	89 02                	mov    %eax,(%edx)
80104705:	8b 45 0c             	mov    0xc(%ebp),%eax
80104708:	8b 00                	mov    (%eax),%eax
8010470a:	85 c0                	test   %eax,%eax
8010470c:	0f 84 b1 00 00 00    	je     801047c3 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104712:	e8 74 ee ff ff       	call   8010358b <kalloc>
80104717:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010471a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010471e:	0f 84 9e 00 00 00    	je     801047c2 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104724:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104727:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010472e:	00 00 00 
  p->writeopen = 1;
80104731:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104734:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010473b:	00 00 00 
  p->nwrite = 0;
8010473e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104741:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104748:	00 00 00 
  p->nread = 0;
8010474b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104755:	00 00 00 
  initlock(&p->lock, "pipe");
80104758:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010475b:	c7 44 24 04 20 91 10 	movl   $0x80109120,0x4(%esp)
80104762:	80 
80104763:	89 04 24             	mov    %eax,(%esp)
80104766:	e8 a3 0e 00 00       	call   8010560e <initlock>
  (*f0)->type = FD_PIPE;
8010476b:	8b 45 08             	mov    0x8(%ebp),%eax
8010476e:	8b 00                	mov    (%eax),%eax
80104770:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104776:	8b 45 08             	mov    0x8(%ebp),%eax
80104779:	8b 00                	mov    (%eax),%eax
8010477b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010477f:	8b 45 08             	mov    0x8(%ebp),%eax
80104782:	8b 00                	mov    (%eax),%eax
80104784:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104788:	8b 45 08             	mov    0x8(%ebp),%eax
8010478b:	8b 00                	mov    (%eax),%eax
8010478d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104790:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104793:	8b 45 0c             	mov    0xc(%ebp),%eax
80104796:	8b 00                	mov    (%eax),%eax
80104798:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010479e:	8b 45 0c             	mov    0xc(%ebp),%eax
801047a1:	8b 00                	mov    (%eax),%eax
801047a3:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801047a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801047aa:	8b 00                	mov    (%eax),%eax
801047ac:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801047b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801047b3:	8b 00                	mov    (%eax),%eax
801047b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047b8:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801047bb:	b8 00 00 00 00       	mov    $0x0,%eax
801047c0:	eb 43                	jmp    80104805 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
801047c2:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
801047c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801047c7:	74 0b                	je     801047d4 <pipealloc+0x110>
    kfree((char*)p);
801047c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047cc:	89 04 24             	mov    %eax,(%esp)
801047cf:	e8 1e ed ff ff       	call   801034f2 <kfree>
  if(*f0)
801047d4:	8b 45 08             	mov    0x8(%ebp),%eax
801047d7:	8b 00                	mov    (%eax),%eax
801047d9:	85 c0                	test   %eax,%eax
801047db:	74 0d                	je     801047ea <pipealloc+0x126>
    fileclose(*f0);
801047dd:	8b 45 08             	mov    0x8(%ebp),%eax
801047e0:	8b 00                	mov    (%eax),%eax
801047e2:	89 04 24             	mov    %eax,(%esp)
801047e5:	e8 da c7 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
801047ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801047ed:	8b 00                	mov    (%eax),%eax
801047ef:	85 c0                	test   %eax,%eax
801047f1:	74 0d                	je     80104800 <pipealloc+0x13c>
    fileclose(*f1);
801047f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801047f6:	8b 00                	mov    (%eax),%eax
801047f8:	89 04 24             	mov    %eax,(%esp)
801047fb:	e8 c4 c7 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104800:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104805:	c9                   	leave  
80104806:	c3                   	ret    

80104807 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104807:	55                   	push   %ebp
80104808:	89 e5                	mov    %esp,%ebp
8010480a:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
8010480d:	8b 45 08             	mov    0x8(%ebp),%eax
80104810:	89 04 24             	mov    %eax,(%esp)
80104813:	e8 17 0e 00 00       	call   8010562f <acquire>
  if(writable){
80104818:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010481c:	74 1f                	je     8010483d <pipeclose+0x36>
    p->writeopen = 0;
8010481e:	8b 45 08             	mov    0x8(%ebp),%eax
80104821:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104828:	00 00 00 
    wakeup(&p->nread);
8010482b:	8b 45 08             	mov    0x8(%ebp),%eax
8010482e:	05 34 02 00 00       	add    $0x234,%eax
80104833:	89 04 24             	mov    %eax,(%esp)
80104836:	e8 ef 0b 00 00       	call   8010542a <wakeup>
8010483b:	eb 1d                	jmp    8010485a <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010483d:	8b 45 08             	mov    0x8(%ebp),%eax
80104840:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104847:	00 00 00 
    wakeup(&p->nwrite);
8010484a:	8b 45 08             	mov    0x8(%ebp),%eax
8010484d:	05 38 02 00 00       	add    $0x238,%eax
80104852:	89 04 24             	mov    %eax,(%esp)
80104855:	e8 d0 0b 00 00       	call   8010542a <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010485a:	8b 45 08             	mov    0x8(%ebp),%eax
8010485d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104863:	85 c0                	test   %eax,%eax
80104865:	75 25                	jne    8010488c <pipeclose+0x85>
80104867:	8b 45 08             	mov    0x8(%ebp),%eax
8010486a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104870:	85 c0                	test   %eax,%eax
80104872:	75 18                	jne    8010488c <pipeclose+0x85>
    release(&p->lock);
80104874:	8b 45 08             	mov    0x8(%ebp),%eax
80104877:	89 04 24             	mov    %eax,(%esp)
8010487a:	e8 12 0e 00 00       	call   80105691 <release>
    kfree((char*)p);
8010487f:	8b 45 08             	mov    0x8(%ebp),%eax
80104882:	89 04 24             	mov    %eax,(%esp)
80104885:	e8 68 ec ff ff       	call   801034f2 <kfree>
8010488a:	eb 0b                	jmp    80104897 <pipeclose+0x90>
  } else
    release(&p->lock);
8010488c:	8b 45 08             	mov    0x8(%ebp),%eax
8010488f:	89 04 24             	mov    %eax,(%esp)
80104892:	e8 fa 0d 00 00       	call   80105691 <release>
}
80104897:	c9                   	leave  
80104898:	c3                   	ret    

80104899 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104899:	55                   	push   %ebp
8010489a:	89 e5                	mov    %esp,%ebp
8010489c:	53                   	push   %ebx
8010489d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801048a0:	8b 45 08             	mov    0x8(%ebp),%eax
801048a3:	89 04 24             	mov    %eax,(%esp)
801048a6:	e8 84 0d 00 00       	call   8010562f <acquire>
  for(i = 0; i < n; i++){
801048ab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801048b2:	e9 a6 00 00 00       	jmp    8010495d <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801048b7:	8b 45 08             	mov    0x8(%ebp),%eax
801048ba:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801048c0:	85 c0                	test   %eax,%eax
801048c2:	74 0d                	je     801048d1 <pipewrite+0x38>
801048c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ca:	8b 40 24             	mov    0x24(%eax),%eax
801048cd:	85 c0                	test   %eax,%eax
801048cf:	74 15                	je     801048e6 <pipewrite+0x4d>
        release(&p->lock);
801048d1:	8b 45 08             	mov    0x8(%ebp),%eax
801048d4:	89 04 24             	mov    %eax,(%esp)
801048d7:	e8 b5 0d 00 00       	call   80105691 <release>
        return -1;
801048dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048e1:	e9 9d 00 00 00       	jmp    80104983 <pipewrite+0xea>
      }
      wakeup(&p->nread);
801048e6:	8b 45 08             	mov    0x8(%ebp),%eax
801048e9:	05 34 02 00 00       	add    $0x234,%eax
801048ee:	89 04 24             	mov    %eax,(%esp)
801048f1:	e8 34 0b 00 00       	call   8010542a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801048f6:	8b 45 08             	mov    0x8(%ebp),%eax
801048f9:	8b 55 08             	mov    0x8(%ebp),%edx
801048fc:	81 c2 38 02 00 00    	add    $0x238,%edx
80104902:	89 44 24 04          	mov    %eax,0x4(%esp)
80104906:	89 14 24             	mov    %edx,(%esp)
80104909:	e8 43 0a 00 00       	call   80105351 <sleep>
8010490e:	eb 01                	jmp    80104911 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104910:	90                   	nop
80104911:	8b 45 08             	mov    0x8(%ebp),%eax
80104914:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010491a:	8b 45 08             	mov    0x8(%ebp),%eax
8010491d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104923:	05 00 02 00 00       	add    $0x200,%eax
80104928:	39 c2                	cmp    %eax,%edx
8010492a:	74 8b                	je     801048b7 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010492c:	8b 45 08             	mov    0x8(%ebp),%eax
8010492f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104935:	89 c3                	mov    %eax,%ebx
80104937:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010493d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104940:	03 55 0c             	add    0xc(%ebp),%edx
80104943:	0f b6 0a             	movzbl (%edx),%ecx
80104946:	8b 55 08             	mov    0x8(%ebp),%edx
80104949:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
8010494d:	8d 50 01             	lea    0x1(%eax),%edx
80104950:	8b 45 08             	mov    0x8(%ebp),%eax
80104953:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104959:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010495d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104960:	3b 45 10             	cmp    0x10(%ebp),%eax
80104963:	7c ab                	jl     80104910 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104965:	8b 45 08             	mov    0x8(%ebp),%eax
80104968:	05 34 02 00 00       	add    $0x234,%eax
8010496d:	89 04 24             	mov    %eax,(%esp)
80104970:	e8 b5 0a 00 00       	call   8010542a <wakeup>
  release(&p->lock);
80104975:	8b 45 08             	mov    0x8(%ebp),%eax
80104978:	89 04 24             	mov    %eax,(%esp)
8010497b:	e8 11 0d 00 00       	call   80105691 <release>
  return n;
80104980:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104983:	83 c4 24             	add    $0x24,%esp
80104986:	5b                   	pop    %ebx
80104987:	5d                   	pop    %ebp
80104988:	c3                   	ret    

80104989 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104989:	55                   	push   %ebp
8010498a:	89 e5                	mov    %esp,%ebp
8010498c:	53                   	push   %ebx
8010498d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104990:	8b 45 08             	mov    0x8(%ebp),%eax
80104993:	89 04 24             	mov    %eax,(%esp)
80104996:	e8 94 0c 00 00       	call   8010562f <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010499b:	eb 3a                	jmp    801049d7 <piperead+0x4e>
    if(proc->killed){
8010499d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a3:	8b 40 24             	mov    0x24(%eax),%eax
801049a6:	85 c0                	test   %eax,%eax
801049a8:	74 15                	je     801049bf <piperead+0x36>
      release(&p->lock);
801049aa:	8b 45 08             	mov    0x8(%ebp),%eax
801049ad:	89 04 24             	mov    %eax,(%esp)
801049b0:	e8 dc 0c 00 00       	call   80105691 <release>
      return -1;
801049b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049ba:	e9 b6 00 00 00       	jmp    80104a75 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801049bf:	8b 45 08             	mov    0x8(%ebp),%eax
801049c2:	8b 55 08             	mov    0x8(%ebp),%edx
801049c5:	81 c2 34 02 00 00    	add    $0x234,%edx
801049cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801049cf:	89 14 24             	mov    %edx,(%esp)
801049d2:	e8 7a 09 00 00       	call   80105351 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801049d7:	8b 45 08             	mov    0x8(%ebp),%eax
801049da:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801049e0:	8b 45 08             	mov    0x8(%ebp),%eax
801049e3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801049e9:	39 c2                	cmp    %eax,%edx
801049eb:	75 0d                	jne    801049fa <piperead+0x71>
801049ed:	8b 45 08             	mov    0x8(%ebp),%eax
801049f0:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801049f6:	85 c0                	test   %eax,%eax
801049f8:	75 a3                	jne    8010499d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801049fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104a01:	eb 49                	jmp    80104a4c <piperead+0xc3>
    if(p->nread == p->nwrite)
80104a03:	8b 45 08             	mov    0x8(%ebp),%eax
80104a06:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104a0c:	8b 45 08             	mov    0x8(%ebp),%eax
80104a0f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a15:	39 c2                	cmp    %eax,%edx
80104a17:	74 3d                	je     80104a56 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a1c:	89 c2                	mov    %eax,%edx
80104a1e:	03 55 0c             	add    0xc(%ebp),%edx
80104a21:	8b 45 08             	mov    0x8(%ebp),%eax
80104a24:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a2a:	89 c3                	mov    %eax,%ebx
80104a2c:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104a32:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104a35:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104a3a:	88 0a                	mov    %cl,(%edx)
80104a3c:	8d 50 01             	lea    0x1(%eax),%edx
80104a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80104a42:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104a48:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a4f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a52:	7c af                	jl     80104a03 <piperead+0x7a>
80104a54:	eb 01                	jmp    80104a57 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104a56:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104a57:	8b 45 08             	mov    0x8(%ebp),%eax
80104a5a:	05 38 02 00 00       	add    $0x238,%eax
80104a5f:	89 04 24             	mov    %eax,(%esp)
80104a62:	e8 c3 09 00 00       	call   8010542a <wakeup>
  release(&p->lock);
80104a67:	8b 45 08             	mov    0x8(%ebp),%eax
80104a6a:	89 04 24             	mov    %eax,(%esp)
80104a6d:	e8 1f 0c 00 00       	call   80105691 <release>
  return i;
80104a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104a75:	83 c4 24             	add    $0x24,%esp
80104a78:	5b                   	pop    %ebx
80104a79:	5d                   	pop    %ebp
80104a7a:	c3                   	ret    
	...

80104a7c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104a7c:	55                   	push   %ebp
80104a7d:	89 e5                	mov    %esp,%ebp
80104a7f:	53                   	push   %ebx
80104a80:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104a83:	9c                   	pushf  
80104a84:	5b                   	pop    %ebx
80104a85:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104a88:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104a8b:	83 c4 10             	add    $0x10,%esp
80104a8e:	5b                   	pop    %ebx
80104a8f:	5d                   	pop    %ebp
80104a90:	c3                   	ret    

80104a91 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104a91:	55                   	push   %ebp
80104a92:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104a94:	fb                   	sti    
}
80104a95:	5d                   	pop    %ebp
80104a96:	c3                   	ret    

80104a97 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104a97:	55                   	push   %ebp
80104a98:	89 e5                	mov    %esp,%ebp
80104a9a:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104a9d:	c7 44 24 04 25 91 10 	movl   $0x80109125,0x4(%esp)
80104aa4:	80 
80104aa5:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104aac:	e8 5d 0b 00 00       	call   8010560e <initlock>
}
80104ab1:	c9                   	leave  
80104ab2:	c3                   	ret    

80104ab3 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104ab3:	55                   	push   %ebp
80104ab4:	89 e5                	mov    %esp,%ebp
80104ab6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104ab9:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104ac0:	e8 6a 0b 00 00       	call   8010562f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ac5:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80104acc:	eb 0e                	jmp    80104adc <allocproc+0x29>
    if(p->state == UNUSED)
80104ace:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad1:	8b 40 0c             	mov    0xc(%eax),%eax
80104ad4:	85 c0                	test   %eax,%eax
80104ad6:	74 23                	je     80104afb <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ad8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104adc:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80104ae3:	72 e9                	jb     80104ace <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104ae5:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104aec:	e8 a0 0b 00 00       	call   80105691 <release>
  return 0;
80104af1:	b8 00 00 00 00       	mov    $0x0,%eax
80104af6:	e9 b5 00 00 00       	jmp    80104bb0 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104afb:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aff:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104b06:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104b0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b0e:	89 42 10             	mov    %eax,0x10(%edx)
80104b11:	83 c0 01             	add    $0x1,%eax
80104b14:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80104b19:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104b20:	e8 6c 0b 00 00       	call   80105691 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104b25:	e8 61 ea ff ff       	call   8010358b <kalloc>
80104b2a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b2d:	89 42 08             	mov    %eax,0x8(%edx)
80104b30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b33:	8b 40 08             	mov    0x8(%eax),%eax
80104b36:	85 c0                	test   %eax,%eax
80104b38:	75 11                	jne    80104b4b <allocproc+0x98>
    p->state = UNUSED;
80104b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b3d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104b44:	b8 00 00 00 00       	mov    $0x0,%eax
80104b49:	eb 65                	jmp    80104bb0 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104b4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b4e:	8b 40 08             	mov    0x8(%eax),%eax
80104b51:	05 00 10 00 00       	add    $0x1000,%eax
80104b56:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104b59:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104b5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b60:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b63:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104b66:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104b6a:	ba 64 6e 10 80       	mov    $0x80106e64,%edx
80104b6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b72:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104b74:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104b78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b7e:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b84:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b87:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104b8e:	00 
80104b8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104b96:	00 
80104b97:	89 04 24             	mov    %eax,(%esp)
80104b9a:	e8 df 0c 00 00       	call   8010587e <memset>
  p->context->eip = (uint)forkret;
80104b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba2:	8b 40 1c             	mov    0x1c(%eax),%eax
80104ba5:	ba 25 53 10 80       	mov    $0x80105325,%edx
80104baa:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104bad:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104bb0:	c9                   	leave  
80104bb1:	c3                   	ret    

80104bb2 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104bb2:	55                   	push   %ebp
80104bb3:	89 e5                	mov    %esp,%ebp
80104bb5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104bb8:	e8 f6 fe ff ff       	call   80104ab3 <allocproc>
80104bbd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bc3:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104bc8:	c7 04 24 8b 35 10 80 	movl   $0x8010358b,(%esp)
80104bcf:	e8 8d 39 00 00       	call   80108561 <setupkvm>
80104bd4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bd7:	89 42 04             	mov    %eax,0x4(%edx)
80104bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bdd:	8b 40 04             	mov    0x4(%eax),%eax
80104be0:	85 c0                	test   %eax,%eax
80104be2:	75 0c                	jne    80104bf0 <userinit+0x3e>
    panic("userinit: out of memory?");
80104be4:	c7 04 24 2c 91 10 80 	movl   $0x8010912c,(%esp)
80104beb:	e8 4d b9 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104bf0:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf8:	8b 40 04             	mov    0x4(%eax),%eax
80104bfb:	89 54 24 08          	mov    %edx,0x8(%esp)
80104bff:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104c06:	80 
80104c07:	89 04 24             	mov    %eax,(%esp)
80104c0a:	e8 aa 3b 00 00       	call   801087b9 <inituvm>
  p->sz = PGSIZE;
80104c0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c12:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104c18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c1b:	8b 40 18             	mov    0x18(%eax),%eax
80104c1e:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104c25:	00 
80104c26:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104c2d:	00 
80104c2e:	89 04 24             	mov    %eax,(%esp)
80104c31:	e8 48 0c 00 00       	call   8010587e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104c36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c39:	8b 40 18             	mov    0x18(%eax),%eax
80104c3c:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c45:	8b 40 18             	mov    0x18(%eax),%eax
80104c48:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c51:	8b 40 18             	mov    0x18(%eax),%eax
80104c54:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c57:	8b 52 18             	mov    0x18(%edx),%edx
80104c5a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104c5e:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104c62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c65:	8b 40 18             	mov    0x18(%eax),%eax
80104c68:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c6b:	8b 52 18             	mov    0x18(%edx),%edx
80104c6e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104c72:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c79:	8b 40 18             	mov    0x18(%eax),%eax
80104c7c:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c86:	8b 40 18             	mov    0x18(%eax),%eax
80104c89:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c93:	8b 40 18             	mov    0x18(%eax),%eax
80104c96:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104c9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ca0:	83 c0 6c             	add    $0x6c,%eax
80104ca3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104caa:	00 
80104cab:	c7 44 24 04 45 91 10 	movl   $0x80109145,0x4(%esp)
80104cb2:	80 
80104cb3:	89 04 24             	mov    %eax,(%esp)
80104cb6:	e8 f3 0d 00 00       	call   80105aae <safestrcpy>
  p->cwd = namei("/");
80104cbb:	c7 04 24 4e 91 10 80 	movl   $0x8010914e,(%esp)
80104cc2:	e8 cf e1 ff ff       	call   80102e96 <namei>
80104cc7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cca:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104ccd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cd0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104cd7:	c9                   	leave  
80104cd8:	c3                   	ret    

80104cd9 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104cd9:	55                   	push   %ebp
80104cda:	89 e5                	mov    %esp,%ebp
80104cdc:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104cdf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ce5:	8b 00                	mov    (%eax),%eax
80104ce7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104cea:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104cee:	7e 34                	jle    80104d24 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104cf0:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf3:	89 c2                	mov    %eax,%edx
80104cf5:	03 55 f4             	add    -0xc(%ebp),%edx
80104cf8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cfe:	8b 40 04             	mov    0x4(%eax),%eax
80104d01:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d05:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d08:	89 54 24 04          	mov    %edx,0x4(%esp)
80104d0c:	89 04 24             	mov    %eax,(%esp)
80104d0f:	e8 1f 3c 00 00       	call   80108933 <allocuvm>
80104d14:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104d17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104d1b:	75 41                	jne    80104d5e <growproc+0x85>
      return -1;
80104d1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d22:	eb 58                	jmp    80104d7c <growproc+0xa3>
  } else if(n < 0){
80104d24:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104d28:	79 34                	jns    80104d5e <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d2d:	89 c2                	mov    %eax,%edx
80104d2f:	03 55 f4             	add    -0xc(%ebp),%edx
80104d32:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d38:	8b 40 04             	mov    0x4(%eax),%eax
80104d3b:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d3f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d42:	89 54 24 04          	mov    %edx,0x4(%esp)
80104d46:	89 04 24             	mov    %eax,(%esp)
80104d49:	e8 bf 3c 00 00       	call   80108a0d <deallocuvm>
80104d4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104d51:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104d55:	75 07                	jne    80104d5e <growproc+0x85>
      return -1;
80104d57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d5c:	eb 1e                	jmp    80104d7c <growproc+0xa3>
  }
  proc->sz = sz;
80104d5e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d64:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d67:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104d69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d6f:	89 04 24             	mov    %eax,(%esp)
80104d72:	e8 db 38 00 00       	call   80108652 <switchuvm>
  return 0;
80104d77:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d7c:	c9                   	leave  
80104d7d:	c3                   	ret    

80104d7e <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104d7e:	55                   	push   %ebp
80104d7f:	89 e5                	mov    %esp,%ebp
80104d81:	57                   	push   %edi
80104d82:	56                   	push   %esi
80104d83:	53                   	push   %ebx
80104d84:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104d87:	e8 27 fd ff ff       	call   80104ab3 <allocproc>
80104d8c:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104d8f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104d93:	75 0a                	jne    80104d9f <fork+0x21>
    return -1;
80104d95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d9a:	e9 3a 01 00 00       	jmp    80104ed9 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104d9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104da5:	8b 10                	mov    (%eax),%edx
80104da7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dad:	8b 40 04             	mov    0x4(%eax),%eax
80104db0:	89 54 24 04          	mov    %edx,0x4(%esp)
80104db4:	89 04 24             	mov    %eax,(%esp)
80104db7:	e8 e1 3d 00 00       	call   80108b9d <copyuvm>
80104dbc:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104dbf:	89 42 04             	mov    %eax,0x4(%edx)
80104dc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104dc5:	8b 40 04             	mov    0x4(%eax),%eax
80104dc8:	85 c0                	test   %eax,%eax
80104dca:	75 2c                	jne    80104df8 <fork+0x7a>
    kfree(np->kstack);
80104dcc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104dcf:	8b 40 08             	mov    0x8(%eax),%eax
80104dd2:	89 04 24             	mov    %eax,(%esp)
80104dd5:	e8 18 e7 ff ff       	call   801034f2 <kfree>
    np->kstack = 0;
80104dda:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ddd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104de4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104de7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104df3:	e9 e1 00 00 00       	jmp    80104ed9 <fork+0x15b>
  }
  np->sz = proc->sz;
80104df8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dfe:	8b 10                	mov    (%eax),%edx
80104e00:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e03:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104e05:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104e0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e0f:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e15:	8b 50 18             	mov    0x18(%eax),%edx
80104e18:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e1e:	8b 40 18             	mov    0x18(%eax),%eax
80104e21:	89 c3                	mov    %eax,%ebx
80104e23:	b8 13 00 00 00       	mov    $0x13,%eax
80104e28:	89 d7                	mov    %edx,%edi
80104e2a:	89 de                	mov    %ebx,%esi
80104e2c:	89 c1                	mov    %eax,%ecx
80104e2e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104e30:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104e33:	8b 40 18             	mov    0x18(%eax),%eax
80104e36:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104e3d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104e44:	eb 3d                	jmp    80104e83 <fork+0x105>
    if(proc->ofile[i])
80104e46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e4c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104e4f:	83 c2 08             	add    $0x8,%edx
80104e52:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e56:	85 c0                	test   %eax,%eax
80104e58:	74 25                	je     80104e7f <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104e5a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e60:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104e63:	83 c2 08             	add    $0x8,%edx
80104e66:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104e6a:	89 04 24             	mov    %eax,(%esp)
80104e6d:	e8 0a c1 ff ff       	call   80100f7c <filedup>
80104e72:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104e75:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104e78:	83 c1 08             	add    $0x8,%ecx
80104e7b:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104e7f:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104e83:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104e87:	7e bd                	jle    80104e46 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104e89:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e8f:	8b 40 68             	mov    0x68(%eax),%eax
80104e92:	89 04 24             	mov    %eax,(%esp)
80104e95:	e8 28 d4 ff ff       	call   801022c2 <idup>
80104e9a:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104e9d:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104ea0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ea3:	8b 40 10             	mov    0x10(%eax),%eax
80104ea6:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104ea9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eac:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104eb3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104eb9:	8d 50 6c             	lea    0x6c(%eax),%edx
80104ebc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ebf:	83 c0 6c             	add    $0x6c,%eax
80104ec2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104ec9:	00 
80104eca:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ece:	89 04 24             	mov    %eax,(%esp)
80104ed1:	e8 d8 0b 00 00       	call   80105aae <safestrcpy>
  return pid;
80104ed6:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104ed9:	83 c4 2c             	add    $0x2c,%esp
80104edc:	5b                   	pop    %ebx
80104edd:	5e                   	pop    %esi
80104ede:	5f                   	pop    %edi
80104edf:	5d                   	pop    %ebp
80104ee0:	c3                   	ret    

80104ee1 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104ee1:	55                   	push   %ebp
80104ee2:	89 e5                	mov    %esp,%ebp
80104ee4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104ee7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104eee:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104ef3:	39 c2                	cmp    %eax,%edx
80104ef5:	75 0c                	jne    80104f03 <exit+0x22>
    panic("init exiting");
80104ef7:	c7 04 24 50 91 10 80 	movl   $0x80109150,(%esp)
80104efe:	e8 3a b6 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104f03:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104f0a:	eb 44                	jmp    80104f50 <exit+0x6f>
    if(proc->ofile[fd]){
80104f0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f12:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f15:	83 c2 08             	add    $0x8,%edx
80104f18:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f1c:	85 c0                	test   %eax,%eax
80104f1e:	74 2c                	je     80104f4c <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104f20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f26:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f29:	83 c2 08             	add    $0x8,%edx
80104f2c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f30:	89 04 24             	mov    %eax,(%esp)
80104f33:	e8 8c c0 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80104f38:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f3e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f41:	83 c2 08             	add    $0x8,%edx
80104f44:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104f4b:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104f4c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104f50:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104f54:	7e b6                	jle    80104f0c <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104f56:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f5c:	8b 40 68             	mov    0x68(%eax),%eax
80104f5f:	89 04 24             	mov    %eax,(%esp)
80104f62:	e8 40 d5 ff ff       	call   801024a7 <iput>
  proc->cwd = 0;
80104f67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f6d:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104f74:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104f7b:	e8 af 06 00 00       	call   8010562f <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104f80:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f86:	8b 40 14             	mov    0x14(%eax),%eax
80104f89:	89 04 24             	mov    %eax,(%esp)
80104f8c:	e8 5b 04 00 00       	call   801053ec <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f91:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80104f98:	eb 38                	jmp    80104fd2 <exit+0xf1>
    if(p->parent == proc){
80104f9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f9d:	8b 50 14             	mov    0x14(%eax),%edx
80104fa0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fa6:	39 c2                	cmp    %eax,%edx
80104fa8:	75 24                	jne    80104fce <exit+0xed>
      p->parent = initproc;
80104faa:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
80104fb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb3:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104fb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fb9:	8b 40 0c             	mov    0xc(%eax),%eax
80104fbc:	83 f8 05             	cmp    $0x5,%eax
80104fbf:	75 0d                	jne    80104fce <exit+0xed>
        wakeup1(initproc);
80104fc1:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104fc6:	89 04 24             	mov    %eax,(%esp)
80104fc9:	e8 1e 04 00 00       	call   801053ec <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104fce:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104fd2:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80104fd9:	72 bf                	jb     80104f9a <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104fdb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fe1:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104fe8:	e8 54 02 00 00       	call   80105241 <sched>
  panic("zombie exit");
80104fed:	c7 04 24 5d 91 10 80 	movl   $0x8010915d,(%esp)
80104ff4:	e8 44 b5 ff ff       	call   8010053d <panic>

80104ff9 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104ff9:	55                   	push   %ebp
80104ffa:	89 e5                	mov    %esp,%ebp
80104ffc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104fff:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105006:	e8 24 06 00 00       	call   8010562f <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
8010500b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105012:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80105019:	e9 9a 00 00 00       	jmp    801050b8 <wait+0xbf>
      if(p->parent != proc)
8010501e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105021:	8b 50 14             	mov    0x14(%eax),%edx
80105024:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010502a:	39 c2                	cmp    %eax,%edx
8010502c:	0f 85 81 00 00 00    	jne    801050b3 <wait+0xba>
        continue;
      havekids = 1;
80105032:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105039:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010503c:	8b 40 0c             	mov    0xc(%eax),%eax
8010503f:	83 f8 05             	cmp    $0x5,%eax
80105042:	75 70                	jne    801050b4 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105044:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105047:	8b 40 10             	mov    0x10(%eax),%eax
8010504a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010504d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105050:	8b 40 08             	mov    0x8(%eax),%eax
80105053:	89 04 24             	mov    %eax,(%esp)
80105056:	e8 97 e4 ff ff       	call   801034f2 <kfree>
        p->kstack = 0;
8010505b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010505e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105065:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105068:	8b 40 04             	mov    0x4(%eax),%eax
8010506b:	89 04 24             	mov    %eax,(%esp)
8010506e:	e8 56 3a 00 00       	call   80108ac9 <freevm>
        p->state = UNUSED;
80105073:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105076:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010507d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105080:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80105087:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010508a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80105091:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105094:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010509b:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801050a2:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801050a9:	e8 e3 05 00 00       	call   80105691 <release>
        return pid;
801050ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801050b1:	eb 53                	jmp    80105106 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801050b3:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050b4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801050b8:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801050bf:	0f 82 59 ff ff ff    	jb     8010501e <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801050c5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801050c9:	74 0d                	je     801050d8 <wait+0xdf>
801050cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050d1:	8b 40 24             	mov    0x24(%eax),%eax
801050d4:	85 c0                	test   %eax,%eax
801050d6:	74 13                	je     801050eb <wait+0xf2>
      release(&ptable.lock);
801050d8:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801050df:	e8 ad 05 00 00       	call   80105691 <release>
      return -1;
801050e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050e9:	eb 1b                	jmp    80105106 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801050eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f1:	c7 44 24 04 40 0f 11 	movl   $0x80110f40,0x4(%esp)
801050f8:	80 
801050f9:	89 04 24             	mov    %eax,(%esp)
801050fc:	e8 50 02 00 00       	call   80105351 <sleep>
  }
80105101:	e9 05 ff ff ff       	jmp    8010500b <wait+0x12>
}
80105106:	c9                   	leave  
80105107:	c3                   	ret    

80105108 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105108:	55                   	push   %ebp
80105109:	89 e5                	mov    %esp,%ebp
8010510b:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010510e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105114:	8b 40 18             	mov    0x18(%eax),%eax
80105117:	8b 40 44             	mov    0x44(%eax),%eax
8010511a:	89 c2                	mov    %eax,%edx
8010511c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105122:	8b 40 04             	mov    0x4(%eax),%eax
80105125:	89 54 24 04          	mov    %edx,0x4(%esp)
80105129:	89 04 24             	mov    %eax,(%esp)
8010512c:	e8 7d 3b 00 00       	call   80108cae <uva2ka>
80105131:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105134:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010513a:	8b 40 18             	mov    0x18(%eax),%eax
8010513d:	8b 40 44             	mov    0x44(%eax),%eax
80105140:	25 ff 0f 00 00       	and    $0xfff,%eax
80105145:	85 c0                	test   %eax,%eax
80105147:	75 0c                	jne    80105155 <register_handler+0x4d>
    panic("esp_offset == 0");
80105149:	c7 04 24 69 91 10 80 	movl   $0x80109169,(%esp)
80105150:	e8 e8 b3 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105155:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010515b:	8b 40 18             	mov    0x18(%eax),%eax
8010515e:	8b 40 44             	mov    0x44(%eax),%eax
80105161:	83 e8 04             	sub    $0x4,%eax
80105164:	25 ff 0f 00 00       	and    $0xfff,%eax
80105169:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010516c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105173:	8b 52 18             	mov    0x18(%edx),%edx
80105176:	8b 52 38             	mov    0x38(%edx),%edx
80105179:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010517b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105181:	8b 40 18             	mov    0x18(%eax),%eax
80105184:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010518b:	8b 52 18             	mov    0x18(%edx),%edx
8010518e:	8b 52 44             	mov    0x44(%edx),%edx
80105191:	83 ea 04             	sub    $0x4,%edx
80105194:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80105197:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010519d:	8b 40 18             	mov    0x18(%eax),%eax
801051a0:	8b 55 08             	mov    0x8(%ebp),%edx
801051a3:	89 50 38             	mov    %edx,0x38(%eax)
}
801051a6:	c9                   	leave  
801051a7:	c3                   	ret    

801051a8 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801051a8:	55                   	push   %ebp
801051a9:	89 e5                	mov    %esp,%ebp
801051ab:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801051ae:	e8 de f8 ff ff       	call   80104a91 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801051b3:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801051ba:	e8 70 04 00 00       	call   8010562f <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051bf:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801051c6:	eb 5f                	jmp    80105227 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801051c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051cb:	8b 40 0c             	mov    0xc(%eax),%eax
801051ce:	83 f8 03             	cmp    $0x3,%eax
801051d1:	75 4f                	jne    80105222 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801051d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d6:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801051dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051df:	89 04 24             	mov    %eax,(%esp)
801051e2:	e8 6b 34 00 00       	call   80108652 <switchuvm>
      p->state = RUNNING;
801051e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ea:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801051f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051f7:	8b 40 1c             	mov    0x1c(%eax),%eax
801051fa:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105201:	83 c2 04             	add    $0x4,%edx
80105204:	89 44 24 04          	mov    %eax,0x4(%esp)
80105208:	89 14 24             	mov    %edx,(%esp)
8010520b:	e8 14 09 00 00       	call   80105b24 <swtch>
      switchkvm();
80105210:	e8 20 34 00 00       	call   80108635 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105215:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010521c:	00 00 00 00 
80105220:	eb 01                	jmp    80105223 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80105222:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105223:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105227:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
8010522e:	72 98                	jb     801051c8 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105230:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105237:	e8 55 04 00 00       	call   80105691 <release>

  }
8010523c:	e9 6d ff ff ff       	jmp    801051ae <scheduler+0x6>

80105241 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105241:	55                   	push   %ebp
80105242:	89 e5                	mov    %esp,%ebp
80105244:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105247:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010524e:	e8 fa 04 00 00       	call   8010574d <holding>
80105253:	85 c0                	test   %eax,%eax
80105255:	75 0c                	jne    80105263 <sched+0x22>
    panic("sched ptable.lock");
80105257:	c7 04 24 79 91 10 80 	movl   $0x80109179,(%esp)
8010525e:	e8 da b2 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105263:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105269:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010526f:	83 f8 01             	cmp    $0x1,%eax
80105272:	74 0c                	je     80105280 <sched+0x3f>
    panic("sched locks");
80105274:	c7 04 24 8b 91 10 80 	movl   $0x8010918b,(%esp)
8010527b:	e8 bd b2 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105280:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105286:	8b 40 0c             	mov    0xc(%eax),%eax
80105289:	83 f8 04             	cmp    $0x4,%eax
8010528c:	75 0c                	jne    8010529a <sched+0x59>
    panic("sched running");
8010528e:	c7 04 24 97 91 10 80 	movl   $0x80109197,(%esp)
80105295:	e8 a3 b2 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
8010529a:	e8 dd f7 ff ff       	call   80104a7c <readeflags>
8010529f:	25 00 02 00 00       	and    $0x200,%eax
801052a4:	85 c0                	test   %eax,%eax
801052a6:	74 0c                	je     801052b4 <sched+0x73>
    panic("sched interruptible");
801052a8:	c7 04 24 a5 91 10 80 	movl   $0x801091a5,(%esp)
801052af:	e8 89 b2 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801052b4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052ba:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801052c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801052c3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052c9:	8b 40 04             	mov    0x4(%eax),%eax
801052cc:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801052d3:	83 c2 1c             	add    $0x1c,%edx
801052d6:	89 44 24 04          	mov    %eax,0x4(%esp)
801052da:	89 14 24             	mov    %edx,(%esp)
801052dd:	e8 42 08 00 00       	call   80105b24 <swtch>
  cpu->intena = intena;
801052e2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801052e8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052eb:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801052f1:	c9                   	leave  
801052f2:	c3                   	ret    

801052f3 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
801052f3:	55                   	push   %ebp
801052f4:	89 e5                	mov    %esp,%ebp
801052f6:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801052f9:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105300:	e8 2a 03 00 00       	call   8010562f <acquire>
  proc->state = RUNNABLE;
80105305:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010530b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105312:	e8 2a ff ff ff       	call   80105241 <sched>
  release(&ptable.lock);
80105317:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010531e:	e8 6e 03 00 00       	call   80105691 <release>
}
80105323:	c9                   	leave  
80105324:	c3                   	ret    

80105325 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105325:	55                   	push   %ebp
80105326:	89 e5                	mov    %esp,%ebp
80105328:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010532b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105332:	e8 5a 03 00 00       	call   80105691 <release>

  if (first) {
80105337:	a1 20 c0 10 80       	mov    0x8010c020,%eax
8010533c:	85 c0                	test   %eax,%eax
8010533e:	74 0f                	je     8010534f <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105340:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105347:	00 00 00 
    initlog();
8010534a:	e8 4d e7 ff ff       	call   80103a9c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010534f:	c9                   	leave  
80105350:	c3                   	ret    

80105351 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105351:	55                   	push   %ebp
80105352:	89 e5                	mov    %esp,%ebp
80105354:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535d:	85 c0                	test   %eax,%eax
8010535f:	75 0c                	jne    8010536d <sleep+0x1c>
    panic("sleep");
80105361:	c7 04 24 b9 91 10 80 	movl   $0x801091b9,(%esp)
80105368:	e8 d0 b1 ff ff       	call   8010053d <panic>

  if(lk == 0)
8010536d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105371:	75 0c                	jne    8010537f <sleep+0x2e>
    panic("sleep without lk");
80105373:	c7 04 24 bf 91 10 80 	movl   $0x801091bf,(%esp)
8010537a:	e8 be b1 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010537f:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
80105386:	74 17                	je     8010539f <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105388:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010538f:	e8 9b 02 00 00       	call   8010562f <acquire>
    release(lk);
80105394:	8b 45 0c             	mov    0xc(%ebp),%eax
80105397:	89 04 24             	mov    %eax,(%esp)
8010539a:	e8 f2 02 00 00       	call   80105691 <release>
  }

  // Go to sleep.
  proc->chan = chan;
8010539f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053a5:	8b 55 08             	mov    0x8(%ebp),%edx
801053a8:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801053ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053b1:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801053b8:	e8 84 fe ff ff       	call   80105241 <sched>

  // Tidy up.
  proc->chan = 0;
801053bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c3:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801053ca:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801053d1:	74 17                	je     801053ea <sleep+0x99>
    release(&ptable.lock);
801053d3:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801053da:	e8 b2 02 00 00       	call   80105691 <release>
    acquire(lk);
801053df:	8b 45 0c             	mov    0xc(%ebp),%eax
801053e2:	89 04 24             	mov    %eax,(%esp)
801053e5:	e8 45 02 00 00       	call   8010562f <acquire>
  }
}
801053ea:	c9                   	leave  
801053eb:	c3                   	ret    

801053ec <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801053ec:	55                   	push   %ebp
801053ed:	89 e5                	mov    %esp,%ebp
801053ef:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801053f2:	c7 45 fc 74 0f 11 80 	movl   $0x80110f74,-0x4(%ebp)
801053f9:	eb 24                	jmp    8010541f <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
801053fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053fe:	8b 40 0c             	mov    0xc(%eax),%eax
80105401:	83 f8 02             	cmp    $0x2,%eax
80105404:	75 15                	jne    8010541b <wakeup1+0x2f>
80105406:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105409:	8b 40 20             	mov    0x20(%eax),%eax
8010540c:	3b 45 08             	cmp    0x8(%ebp),%eax
8010540f:	75 0a                	jne    8010541b <wakeup1+0x2f>
      p->state = RUNNABLE;
80105411:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105414:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010541b:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
8010541f:	81 7d fc 74 2e 11 80 	cmpl   $0x80112e74,-0x4(%ebp)
80105426:	72 d3                	jb     801053fb <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105428:	c9                   	leave  
80105429:	c3                   	ret    

8010542a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010542a:	55                   	push   %ebp
8010542b:	89 e5                	mov    %esp,%ebp
8010542d:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105430:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105437:	e8 f3 01 00 00       	call   8010562f <acquire>
  wakeup1(chan);
8010543c:	8b 45 08             	mov    0x8(%ebp),%eax
8010543f:	89 04 24             	mov    %eax,(%esp)
80105442:	e8 a5 ff ff ff       	call   801053ec <wakeup1>
  release(&ptable.lock);
80105447:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010544e:	e8 3e 02 00 00       	call   80105691 <release>
}
80105453:	c9                   	leave  
80105454:	c3                   	ret    

80105455 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105455:	55                   	push   %ebp
80105456:	89 e5                	mov    %esp,%ebp
80105458:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
8010545b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105462:	e8 c8 01 00 00       	call   8010562f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105467:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
8010546e:	eb 41                	jmp    801054b1 <kill+0x5c>
    if(p->pid == pid){
80105470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105473:	8b 40 10             	mov    0x10(%eax),%eax
80105476:	3b 45 08             	cmp    0x8(%ebp),%eax
80105479:	75 32                	jne    801054ad <kill+0x58>
      p->killed = 1;
8010547b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010547e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105488:	8b 40 0c             	mov    0xc(%eax),%eax
8010548b:	83 f8 02             	cmp    $0x2,%eax
8010548e:	75 0a                	jne    8010549a <kill+0x45>
        p->state = RUNNABLE;
80105490:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105493:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
8010549a:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054a1:	e8 eb 01 00 00       	call   80105691 <release>
      return 0;
801054a6:	b8 00 00 00 00       	mov    $0x0,%eax
801054ab:	eb 1e                	jmp    801054cb <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054ad:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801054b1:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801054b8:	72 b6                	jb     80105470 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801054ba:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054c1:	e8 cb 01 00 00       	call   80105691 <release>
  return -1;
801054c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801054cb:	c9                   	leave  
801054cc:	c3                   	ret    

801054cd <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801054cd:	55                   	push   %ebp
801054ce:	89 e5                	mov    %esp,%ebp
801054d0:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054d3:	c7 45 f0 74 0f 11 80 	movl   $0x80110f74,-0x10(%ebp)
801054da:	e9 d8 00 00 00       	jmp    801055b7 <procdump+0xea>
    if(p->state == UNUSED)
801054df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054e2:	8b 40 0c             	mov    0xc(%eax),%eax
801054e5:	85 c0                	test   %eax,%eax
801054e7:	0f 84 c5 00 00 00    	je     801055b2 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801054ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f0:	8b 40 0c             	mov    0xc(%eax),%eax
801054f3:	83 f8 05             	cmp    $0x5,%eax
801054f6:	77 23                	ja     8010551b <procdump+0x4e>
801054f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054fb:	8b 40 0c             	mov    0xc(%eax),%eax
801054fe:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105505:	85 c0                	test   %eax,%eax
80105507:	74 12                	je     8010551b <procdump+0x4e>
      state = states[p->state];
80105509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010550c:	8b 40 0c             	mov    0xc(%eax),%eax
8010550f:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105516:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105519:	eb 07                	jmp    80105522 <procdump+0x55>
    else
      state = "???";
8010551b:	c7 45 ec d0 91 10 80 	movl   $0x801091d0,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105522:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105525:	8d 50 6c             	lea    0x6c(%eax),%edx
80105528:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010552b:	8b 40 10             	mov    0x10(%eax),%eax
8010552e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105532:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105535:	89 54 24 08          	mov    %edx,0x8(%esp)
80105539:	89 44 24 04          	mov    %eax,0x4(%esp)
8010553d:	c7 04 24 d4 91 10 80 	movl   $0x801091d4,(%esp)
80105544:	e8 58 ae ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105549:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010554c:	8b 40 0c             	mov    0xc(%eax),%eax
8010554f:	83 f8 02             	cmp    $0x2,%eax
80105552:	75 50                	jne    801055a4 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105554:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105557:	8b 40 1c             	mov    0x1c(%eax),%eax
8010555a:	8b 40 0c             	mov    0xc(%eax),%eax
8010555d:	83 c0 08             	add    $0x8,%eax
80105560:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105563:	89 54 24 04          	mov    %edx,0x4(%esp)
80105567:	89 04 24             	mov    %eax,(%esp)
8010556a:	e8 71 01 00 00       	call   801056e0 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
8010556f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105576:	eb 1b                	jmp    80105593 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105578:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010557b:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010557f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105583:	c7 04 24 dd 91 10 80 	movl   $0x801091dd,(%esp)
8010558a:	e8 12 ae ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
8010558f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105593:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105597:	7f 0b                	jg     801055a4 <procdump+0xd7>
80105599:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559c:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801055a0:	85 c0                	test   %eax,%eax
801055a2:	75 d4                	jne    80105578 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801055a4:	c7 04 24 e1 91 10 80 	movl   $0x801091e1,(%esp)
801055ab:	e8 f1 ad ff ff       	call   801003a1 <cprintf>
801055b0:	eb 01                	jmp    801055b3 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
801055b2:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055b3:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801055b7:	81 7d f0 74 2e 11 80 	cmpl   $0x80112e74,-0x10(%ebp)
801055be:	0f 82 1b ff ff ff    	jb     801054df <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801055c4:	c9                   	leave  
801055c5:	c3                   	ret    
	...

801055c8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801055c8:	55                   	push   %ebp
801055c9:	89 e5                	mov    %esp,%ebp
801055cb:	53                   	push   %ebx
801055cc:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801055cf:	9c                   	pushf  
801055d0:	5b                   	pop    %ebx
801055d1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801055d4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801055d7:	83 c4 10             	add    $0x10,%esp
801055da:	5b                   	pop    %ebx
801055db:	5d                   	pop    %ebp
801055dc:	c3                   	ret    

801055dd <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801055dd:	55                   	push   %ebp
801055de:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801055e0:	fa                   	cli    
}
801055e1:	5d                   	pop    %ebp
801055e2:	c3                   	ret    

801055e3 <sti>:

static inline void
sti(void)
{
801055e3:	55                   	push   %ebp
801055e4:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801055e6:	fb                   	sti    
}
801055e7:	5d                   	pop    %ebp
801055e8:	c3                   	ret    

801055e9 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801055e9:	55                   	push   %ebp
801055ea:	89 e5                	mov    %esp,%ebp
801055ec:	53                   	push   %ebx
801055ed:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801055f0:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801055f3:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801055f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801055f9:	89 c3                	mov    %eax,%ebx
801055fb:	89 d8                	mov    %ebx,%eax
801055fd:	f0 87 02             	lock xchg %eax,(%edx)
80105600:	89 c3                	mov    %eax,%ebx
80105602:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105605:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105608:	83 c4 10             	add    $0x10,%esp
8010560b:	5b                   	pop    %ebx
8010560c:	5d                   	pop    %ebp
8010560d:	c3                   	ret    

8010560e <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
8010560e:	55                   	push   %ebp
8010560f:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105611:	8b 45 08             	mov    0x8(%ebp),%eax
80105614:	8b 55 0c             	mov    0xc(%ebp),%edx
80105617:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
8010561a:	8b 45 08             	mov    0x8(%ebp),%eax
8010561d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105623:	8b 45 08             	mov    0x8(%ebp),%eax
80105626:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
8010562d:	5d                   	pop    %ebp
8010562e:	c3                   	ret    

8010562f <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010562f:	55                   	push   %ebp
80105630:	89 e5                	mov    %esp,%ebp
80105632:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105635:	e8 3d 01 00 00       	call   80105777 <pushcli>
  if(holding(lk))
8010563a:	8b 45 08             	mov    0x8(%ebp),%eax
8010563d:	89 04 24             	mov    %eax,(%esp)
80105640:	e8 08 01 00 00       	call   8010574d <holding>
80105645:	85 c0                	test   %eax,%eax
80105647:	74 0c                	je     80105655 <acquire+0x26>
    panic("acquire");
80105649:	c7 04 24 0d 92 10 80 	movl   $0x8010920d,(%esp)
80105650:	e8 e8 ae ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105655:	90                   	nop
80105656:	8b 45 08             	mov    0x8(%ebp),%eax
80105659:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105660:	00 
80105661:	89 04 24             	mov    %eax,(%esp)
80105664:	e8 80 ff ff ff       	call   801055e9 <xchg>
80105669:	85 c0                	test   %eax,%eax
8010566b:	75 e9                	jne    80105656 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
8010566d:	8b 45 08             	mov    0x8(%ebp),%eax
80105670:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105677:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
8010567a:	8b 45 08             	mov    0x8(%ebp),%eax
8010567d:	83 c0 0c             	add    $0xc,%eax
80105680:	89 44 24 04          	mov    %eax,0x4(%esp)
80105684:	8d 45 08             	lea    0x8(%ebp),%eax
80105687:	89 04 24             	mov    %eax,(%esp)
8010568a:	e8 51 00 00 00       	call   801056e0 <getcallerpcs>
}
8010568f:	c9                   	leave  
80105690:	c3                   	ret    

80105691 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105691:	55                   	push   %ebp
80105692:	89 e5                	mov    %esp,%ebp
80105694:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105697:	8b 45 08             	mov    0x8(%ebp),%eax
8010569a:	89 04 24             	mov    %eax,(%esp)
8010569d:	e8 ab 00 00 00       	call   8010574d <holding>
801056a2:	85 c0                	test   %eax,%eax
801056a4:	75 0c                	jne    801056b2 <release+0x21>
    panic("release");
801056a6:	c7 04 24 15 92 10 80 	movl   $0x80109215,(%esp)
801056ad:	e8 8b ae ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
801056b2:	8b 45 08             	mov    0x8(%ebp),%eax
801056b5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801056bc:	8b 45 08             	mov    0x8(%ebp),%eax
801056bf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801056c6:	8b 45 08             	mov    0x8(%ebp),%eax
801056c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801056d0:	00 
801056d1:	89 04 24             	mov    %eax,(%esp)
801056d4:	e8 10 ff ff ff       	call   801055e9 <xchg>

  popcli();
801056d9:	e8 e1 00 00 00       	call   801057bf <popcli>
}
801056de:	c9                   	leave  
801056df:	c3                   	ret    

801056e0 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801056e0:	55                   	push   %ebp
801056e1:	89 e5                	mov    %esp,%ebp
801056e3:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801056e6:	8b 45 08             	mov    0x8(%ebp),%eax
801056e9:	83 e8 08             	sub    $0x8,%eax
801056ec:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801056ef:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801056f6:	eb 32                	jmp    8010572a <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801056f8:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801056fc:	74 47                	je     80105745 <getcallerpcs+0x65>
801056fe:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105705:	76 3e                	jbe    80105745 <getcallerpcs+0x65>
80105707:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
8010570b:	74 38                	je     80105745 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
8010570d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105710:	c1 e0 02             	shl    $0x2,%eax
80105713:	03 45 0c             	add    0xc(%ebp),%eax
80105716:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105719:	8b 52 04             	mov    0x4(%edx),%edx
8010571c:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
8010571e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105721:	8b 00                	mov    (%eax),%eax
80105723:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105726:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010572a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010572e:	7e c8                	jle    801056f8 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105730:	eb 13                	jmp    80105745 <getcallerpcs+0x65>
    pcs[i] = 0;
80105732:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105735:	c1 e0 02             	shl    $0x2,%eax
80105738:	03 45 0c             	add    0xc(%ebp),%eax
8010573b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105741:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105745:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105749:	7e e7                	jle    80105732 <getcallerpcs+0x52>
    pcs[i] = 0;
}
8010574b:	c9                   	leave  
8010574c:	c3                   	ret    

8010574d <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
8010574d:	55                   	push   %ebp
8010574e:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105750:	8b 45 08             	mov    0x8(%ebp),%eax
80105753:	8b 00                	mov    (%eax),%eax
80105755:	85 c0                	test   %eax,%eax
80105757:	74 17                	je     80105770 <holding+0x23>
80105759:	8b 45 08             	mov    0x8(%ebp),%eax
8010575c:	8b 50 08             	mov    0x8(%eax),%edx
8010575f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105765:	39 c2                	cmp    %eax,%edx
80105767:	75 07                	jne    80105770 <holding+0x23>
80105769:	b8 01 00 00 00       	mov    $0x1,%eax
8010576e:	eb 05                	jmp    80105775 <holding+0x28>
80105770:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105775:	5d                   	pop    %ebp
80105776:	c3                   	ret    

80105777 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105777:	55                   	push   %ebp
80105778:	89 e5                	mov    %esp,%ebp
8010577a:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
8010577d:	e8 46 fe ff ff       	call   801055c8 <readeflags>
80105782:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105785:	e8 53 fe ff ff       	call   801055dd <cli>
  if(cpu->ncli++ == 0)
8010578a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105790:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105796:	85 d2                	test   %edx,%edx
80105798:	0f 94 c1             	sete   %cl
8010579b:	83 c2 01             	add    $0x1,%edx
8010579e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801057a4:	84 c9                	test   %cl,%cl
801057a6:	74 15                	je     801057bd <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
801057a8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801057ae:	8b 55 fc             	mov    -0x4(%ebp),%edx
801057b1:	81 e2 00 02 00 00    	and    $0x200,%edx
801057b7:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801057bd:	c9                   	leave  
801057be:	c3                   	ret    

801057bf <popcli>:

void
popcli(void)
{
801057bf:	55                   	push   %ebp
801057c0:	89 e5                	mov    %esp,%ebp
801057c2:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801057c5:	e8 fe fd ff ff       	call   801055c8 <readeflags>
801057ca:	25 00 02 00 00       	and    $0x200,%eax
801057cf:	85 c0                	test   %eax,%eax
801057d1:	74 0c                	je     801057df <popcli+0x20>
    panic("popcli - interruptible");
801057d3:	c7 04 24 1d 92 10 80 	movl   $0x8010921d,(%esp)
801057da:	e8 5e ad ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
801057df:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801057e5:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801057eb:	83 ea 01             	sub    $0x1,%edx
801057ee:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801057f4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801057fa:	85 c0                	test   %eax,%eax
801057fc:	79 0c                	jns    8010580a <popcli+0x4b>
    panic("popcli");
801057fe:	c7 04 24 34 92 10 80 	movl   $0x80109234,(%esp)
80105805:	e8 33 ad ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
8010580a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105810:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105816:	85 c0                	test   %eax,%eax
80105818:	75 15                	jne    8010582f <popcli+0x70>
8010581a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105820:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105826:	85 c0                	test   %eax,%eax
80105828:	74 05                	je     8010582f <popcli+0x70>
    sti();
8010582a:	e8 b4 fd ff ff       	call   801055e3 <sti>
}
8010582f:	c9                   	leave  
80105830:	c3                   	ret    
80105831:	00 00                	add    %al,(%eax)
	...

80105834 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105834:	55                   	push   %ebp
80105835:	89 e5                	mov    %esp,%ebp
80105837:	57                   	push   %edi
80105838:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105839:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010583c:	8b 55 10             	mov    0x10(%ebp),%edx
8010583f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105842:	89 cb                	mov    %ecx,%ebx
80105844:	89 df                	mov    %ebx,%edi
80105846:	89 d1                	mov    %edx,%ecx
80105848:	fc                   	cld    
80105849:	f3 aa                	rep stos %al,%es:(%edi)
8010584b:	89 ca                	mov    %ecx,%edx
8010584d:	89 fb                	mov    %edi,%ebx
8010584f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105852:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105855:	5b                   	pop    %ebx
80105856:	5f                   	pop    %edi
80105857:	5d                   	pop    %ebp
80105858:	c3                   	ret    

80105859 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105859:	55                   	push   %ebp
8010585a:	89 e5                	mov    %esp,%ebp
8010585c:	57                   	push   %edi
8010585d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010585e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105861:	8b 55 10             	mov    0x10(%ebp),%edx
80105864:	8b 45 0c             	mov    0xc(%ebp),%eax
80105867:	89 cb                	mov    %ecx,%ebx
80105869:	89 df                	mov    %ebx,%edi
8010586b:	89 d1                	mov    %edx,%ecx
8010586d:	fc                   	cld    
8010586e:	f3 ab                	rep stos %eax,%es:(%edi)
80105870:	89 ca                	mov    %ecx,%edx
80105872:	89 fb                	mov    %edi,%ebx
80105874:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105877:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010587a:	5b                   	pop    %ebx
8010587b:	5f                   	pop    %edi
8010587c:	5d                   	pop    %ebp
8010587d:	c3                   	ret    

8010587e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010587e:	55                   	push   %ebp
8010587f:	89 e5                	mov    %esp,%ebp
80105881:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105884:	8b 45 08             	mov    0x8(%ebp),%eax
80105887:	83 e0 03             	and    $0x3,%eax
8010588a:	85 c0                	test   %eax,%eax
8010588c:	75 49                	jne    801058d7 <memset+0x59>
8010588e:	8b 45 10             	mov    0x10(%ebp),%eax
80105891:	83 e0 03             	and    $0x3,%eax
80105894:	85 c0                	test   %eax,%eax
80105896:	75 3f                	jne    801058d7 <memset+0x59>
    c &= 0xFF;
80105898:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010589f:	8b 45 10             	mov    0x10(%ebp),%eax
801058a2:	c1 e8 02             	shr    $0x2,%eax
801058a5:	89 c2                	mov    %eax,%edx
801058a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801058aa:	89 c1                	mov    %eax,%ecx
801058ac:	c1 e1 18             	shl    $0x18,%ecx
801058af:	8b 45 0c             	mov    0xc(%ebp),%eax
801058b2:	c1 e0 10             	shl    $0x10,%eax
801058b5:	09 c1                	or     %eax,%ecx
801058b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801058ba:	c1 e0 08             	shl    $0x8,%eax
801058bd:	09 c8                	or     %ecx,%eax
801058bf:	0b 45 0c             	or     0xc(%ebp),%eax
801058c2:	89 54 24 08          	mov    %edx,0x8(%esp)
801058c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801058ca:	8b 45 08             	mov    0x8(%ebp),%eax
801058cd:	89 04 24             	mov    %eax,(%esp)
801058d0:	e8 84 ff ff ff       	call   80105859 <stosl>
801058d5:	eb 19                	jmp    801058f0 <memset+0x72>
  } else
    stosb(dst, c, n);
801058d7:	8b 45 10             	mov    0x10(%ebp),%eax
801058da:	89 44 24 08          	mov    %eax,0x8(%esp)
801058de:	8b 45 0c             	mov    0xc(%ebp),%eax
801058e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801058e5:	8b 45 08             	mov    0x8(%ebp),%eax
801058e8:	89 04 24             	mov    %eax,(%esp)
801058eb:	e8 44 ff ff ff       	call   80105834 <stosb>
  return dst;
801058f0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801058f3:	c9                   	leave  
801058f4:	c3                   	ret    

801058f5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801058f5:	55                   	push   %ebp
801058f6:	89 e5                	mov    %esp,%ebp
801058f8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801058fb:	8b 45 08             	mov    0x8(%ebp),%eax
801058fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105901:	8b 45 0c             	mov    0xc(%ebp),%eax
80105904:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105907:	eb 32                	jmp    8010593b <memcmp+0x46>
    if(*s1 != *s2)
80105909:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010590c:	0f b6 10             	movzbl (%eax),%edx
8010590f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105912:	0f b6 00             	movzbl (%eax),%eax
80105915:	38 c2                	cmp    %al,%dl
80105917:	74 1a                	je     80105933 <memcmp+0x3e>
      return *s1 - *s2;
80105919:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010591c:	0f b6 00             	movzbl (%eax),%eax
8010591f:	0f b6 d0             	movzbl %al,%edx
80105922:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105925:	0f b6 00             	movzbl (%eax),%eax
80105928:	0f b6 c0             	movzbl %al,%eax
8010592b:	89 d1                	mov    %edx,%ecx
8010592d:	29 c1                	sub    %eax,%ecx
8010592f:	89 c8                	mov    %ecx,%eax
80105931:	eb 1c                	jmp    8010594f <memcmp+0x5a>
    s1++, s2++;
80105933:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105937:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010593b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010593f:	0f 95 c0             	setne  %al
80105942:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105946:	84 c0                	test   %al,%al
80105948:	75 bf                	jne    80105909 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010594a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010594f:	c9                   	leave  
80105950:	c3                   	ret    

80105951 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105951:	55                   	push   %ebp
80105952:	89 e5                	mov    %esp,%ebp
80105954:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105957:	8b 45 0c             	mov    0xc(%ebp),%eax
8010595a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010595d:	8b 45 08             	mov    0x8(%ebp),%eax
80105960:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105963:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105966:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105969:	73 54                	jae    801059bf <memmove+0x6e>
8010596b:	8b 45 10             	mov    0x10(%ebp),%eax
8010596e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105971:	01 d0                	add    %edx,%eax
80105973:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105976:	76 47                	jbe    801059bf <memmove+0x6e>
    s += n;
80105978:	8b 45 10             	mov    0x10(%ebp),%eax
8010597b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010597e:	8b 45 10             	mov    0x10(%ebp),%eax
80105981:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105984:	eb 13                	jmp    80105999 <memmove+0x48>
      *--d = *--s;
80105986:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010598a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010598e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105991:	0f b6 10             	movzbl (%eax),%edx
80105994:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105997:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105999:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010599d:	0f 95 c0             	setne  %al
801059a0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801059a4:	84 c0                	test   %al,%al
801059a6:	75 de                	jne    80105986 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801059a8:	eb 25                	jmp    801059cf <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801059aa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801059ad:	0f b6 10             	movzbl (%eax),%edx
801059b0:	8b 45 f8             	mov    -0x8(%ebp),%eax
801059b3:	88 10                	mov    %dl,(%eax)
801059b5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801059b9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801059bd:	eb 01                	jmp    801059c0 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801059bf:	90                   	nop
801059c0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801059c4:	0f 95 c0             	setne  %al
801059c7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801059cb:	84 c0                	test   %al,%al
801059cd:	75 db                	jne    801059aa <memmove+0x59>
      *d++ = *s++;

  return dst;
801059cf:	8b 45 08             	mov    0x8(%ebp),%eax
}
801059d2:	c9                   	leave  
801059d3:	c3                   	ret    

801059d4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801059d4:	55                   	push   %ebp
801059d5:	89 e5                	mov    %esp,%ebp
801059d7:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801059da:	8b 45 10             	mov    0x10(%ebp),%eax
801059dd:	89 44 24 08          	mov    %eax,0x8(%esp)
801059e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801059e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801059e8:	8b 45 08             	mov    0x8(%ebp),%eax
801059eb:	89 04 24             	mov    %eax,(%esp)
801059ee:	e8 5e ff ff ff       	call   80105951 <memmove>
}
801059f3:	c9                   	leave  
801059f4:	c3                   	ret    

801059f5 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801059f5:	55                   	push   %ebp
801059f6:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801059f8:	eb 0c                	jmp    80105a06 <strncmp+0x11>
    n--, p++, q++;
801059fa:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801059fe:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105a02:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105a06:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a0a:	74 1a                	je     80105a26 <strncmp+0x31>
80105a0c:	8b 45 08             	mov    0x8(%ebp),%eax
80105a0f:	0f b6 00             	movzbl (%eax),%eax
80105a12:	84 c0                	test   %al,%al
80105a14:	74 10                	je     80105a26 <strncmp+0x31>
80105a16:	8b 45 08             	mov    0x8(%ebp),%eax
80105a19:	0f b6 10             	movzbl (%eax),%edx
80105a1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1f:	0f b6 00             	movzbl (%eax),%eax
80105a22:	38 c2                	cmp    %al,%dl
80105a24:	74 d4                	je     801059fa <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105a26:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a2a:	75 07                	jne    80105a33 <strncmp+0x3e>
    return 0;
80105a2c:	b8 00 00 00 00       	mov    $0x0,%eax
80105a31:	eb 18                	jmp    80105a4b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105a33:	8b 45 08             	mov    0x8(%ebp),%eax
80105a36:	0f b6 00             	movzbl (%eax),%eax
80105a39:	0f b6 d0             	movzbl %al,%edx
80105a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a3f:	0f b6 00             	movzbl (%eax),%eax
80105a42:	0f b6 c0             	movzbl %al,%eax
80105a45:	89 d1                	mov    %edx,%ecx
80105a47:	29 c1                	sub    %eax,%ecx
80105a49:	89 c8                	mov    %ecx,%eax
}
80105a4b:	5d                   	pop    %ebp
80105a4c:	c3                   	ret    

80105a4d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105a4d:	55                   	push   %ebp
80105a4e:	89 e5                	mov    %esp,%ebp
80105a50:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105a53:	8b 45 08             	mov    0x8(%ebp),%eax
80105a56:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105a59:	90                   	nop
80105a5a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a5e:	0f 9f c0             	setg   %al
80105a61:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105a65:	84 c0                	test   %al,%al
80105a67:	74 30                	je     80105a99 <strncpy+0x4c>
80105a69:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a6c:	0f b6 10             	movzbl (%eax),%edx
80105a6f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a72:	88 10                	mov    %dl,(%eax)
80105a74:	8b 45 08             	mov    0x8(%ebp),%eax
80105a77:	0f b6 00             	movzbl (%eax),%eax
80105a7a:	84 c0                	test   %al,%al
80105a7c:	0f 95 c0             	setne  %al
80105a7f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105a83:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105a87:	84 c0                	test   %al,%al
80105a89:	75 cf                	jne    80105a5a <strncpy+0xd>
    ;
  while(n-- > 0)
80105a8b:	eb 0c                	jmp    80105a99 <strncpy+0x4c>
    *s++ = 0;
80105a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80105a90:	c6 00 00             	movb   $0x0,(%eax)
80105a93:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105a97:	eb 01                	jmp    80105a9a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105a99:	90                   	nop
80105a9a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a9e:	0f 9f c0             	setg   %al
80105aa1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105aa5:	84 c0                	test   %al,%al
80105aa7:	75 e4                	jne    80105a8d <strncpy+0x40>
    *s++ = 0;
  return os;
80105aa9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105aac:	c9                   	leave  
80105aad:	c3                   	ret    

80105aae <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105aae:	55                   	push   %ebp
80105aaf:	89 e5                	mov    %esp,%ebp
80105ab1:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ab7:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105aba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105abe:	7f 05                	jg     80105ac5 <safestrcpy+0x17>
    return os;
80105ac0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ac3:	eb 35                	jmp    80105afa <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105ac5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ac9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105acd:	7e 22                	jle    80105af1 <safestrcpy+0x43>
80105acf:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ad2:	0f b6 10             	movzbl (%eax),%edx
80105ad5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ad8:	88 10                	mov    %dl,(%eax)
80105ada:	8b 45 08             	mov    0x8(%ebp),%eax
80105add:	0f b6 00             	movzbl (%eax),%eax
80105ae0:	84 c0                	test   %al,%al
80105ae2:	0f 95 c0             	setne  %al
80105ae5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105ae9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105aed:	84 c0                	test   %al,%al
80105aef:	75 d4                	jne    80105ac5 <safestrcpy+0x17>
    ;
  *s = 0;
80105af1:	8b 45 08             	mov    0x8(%ebp),%eax
80105af4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105af7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105afa:	c9                   	leave  
80105afb:	c3                   	ret    

80105afc <strlen>:

int
strlen(const char *s)
{
80105afc:	55                   	push   %ebp
80105afd:	89 e5                	mov    %esp,%ebp
80105aff:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105b02:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105b09:	eb 04                	jmp    80105b0f <strlen+0x13>
80105b0b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105b0f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b12:	03 45 08             	add    0x8(%ebp),%eax
80105b15:	0f b6 00             	movzbl (%eax),%eax
80105b18:	84 c0                	test   %al,%al
80105b1a:	75 ef                	jne    80105b0b <strlen+0xf>
    ;
  return n;
80105b1c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105b1f:	c9                   	leave  
80105b20:	c3                   	ret    
80105b21:	00 00                	add    %al,(%eax)
	...

80105b24 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105b24:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105b28:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105b2c:	55                   	push   %ebp
  pushl %ebx
80105b2d:	53                   	push   %ebx
  pushl %esi
80105b2e:	56                   	push   %esi
  pushl %edi
80105b2f:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105b30:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105b32:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105b34:	5f                   	pop    %edi
  popl %esi
80105b35:	5e                   	pop    %esi
  popl %ebx
80105b36:	5b                   	pop    %ebx
  popl %ebp
80105b37:	5d                   	pop    %ebp
  ret
80105b38:	c3                   	ret    
80105b39:	00 00                	add    %al,(%eax)
	...

80105b3c <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105b3c:	55                   	push   %ebp
80105b3d:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105b3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105b42:	8b 00                	mov    (%eax),%eax
80105b44:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105b47:	76 0f                	jbe    80105b58 <fetchint+0x1c>
80105b49:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b4c:	8d 50 04             	lea    0x4(%eax),%edx
80105b4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105b52:	8b 00                	mov    (%eax),%eax
80105b54:	39 c2                	cmp    %eax,%edx
80105b56:	76 07                	jbe    80105b5f <fetchint+0x23>
    return -1;
80105b58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b5d:	eb 0f                	jmp    80105b6e <fetchint+0x32>
  *ip = *(int*)(addr);
80105b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b62:	8b 10                	mov    (%eax),%edx
80105b64:	8b 45 10             	mov    0x10(%ebp),%eax
80105b67:	89 10                	mov    %edx,(%eax)
  return 0;
80105b69:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b6e:	5d                   	pop    %ebp
80105b6f:	c3                   	ret    

80105b70 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105b70:	55                   	push   %ebp
80105b71:	89 e5                	mov    %esp,%ebp
80105b73:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105b76:	8b 45 08             	mov    0x8(%ebp),%eax
80105b79:	8b 00                	mov    (%eax),%eax
80105b7b:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105b7e:	77 07                	ja     80105b87 <fetchstr+0x17>
    return -1;
80105b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b85:	eb 45                	jmp    80105bcc <fetchstr+0x5c>
  *pp = (char*)addr;
80105b87:	8b 55 0c             	mov    0xc(%ebp),%edx
80105b8a:	8b 45 10             	mov    0x10(%ebp),%eax
80105b8d:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105b8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105b92:	8b 00                	mov    (%eax),%eax
80105b94:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105b97:	8b 45 10             	mov    0x10(%ebp),%eax
80105b9a:	8b 00                	mov    (%eax),%eax
80105b9c:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105b9f:	eb 1e                	jmp    80105bbf <fetchstr+0x4f>
    if(*s == 0)
80105ba1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ba4:	0f b6 00             	movzbl (%eax),%eax
80105ba7:	84 c0                	test   %al,%al
80105ba9:	75 10                	jne    80105bbb <fetchstr+0x4b>
      return s - *pp;
80105bab:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bae:	8b 45 10             	mov    0x10(%ebp),%eax
80105bb1:	8b 00                	mov    (%eax),%eax
80105bb3:	89 d1                	mov    %edx,%ecx
80105bb5:	29 c1                	sub    %eax,%ecx
80105bb7:	89 c8                	mov    %ecx,%eax
80105bb9:	eb 11                	jmp    80105bcc <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105bbb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105bbf:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bc2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105bc5:	72 da                	jb     80105ba1 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105bc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105bcc:	c9                   	leave  
80105bcd:	c3                   	ret    

80105bce <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105bce:	55                   	push   %ebp
80105bcf:	89 e5                	mov    %esp,%ebp
80105bd1:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105bd4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bda:	8b 40 18             	mov    0x18(%eax),%eax
80105bdd:	8b 50 44             	mov    0x44(%eax),%edx
80105be0:	8b 45 08             	mov    0x8(%ebp),%eax
80105be3:	c1 e0 02             	shl    $0x2,%eax
80105be6:	01 d0                	add    %edx,%eax
80105be8:	8d 48 04             	lea    0x4(%eax),%ecx
80105beb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bf1:	8b 55 0c             	mov    0xc(%ebp),%edx
80105bf4:	89 54 24 08          	mov    %edx,0x8(%esp)
80105bf8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105bfc:	89 04 24             	mov    %eax,(%esp)
80105bff:	e8 38 ff ff ff       	call   80105b3c <fetchint>
}
80105c04:	c9                   	leave  
80105c05:	c3                   	ret    

80105c06 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105c06:	55                   	push   %ebp
80105c07:	89 e5                	mov    %esp,%ebp
80105c09:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105c0c:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105c0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c13:	8b 45 08             	mov    0x8(%ebp),%eax
80105c16:	89 04 24             	mov    %eax,(%esp)
80105c19:	e8 b0 ff ff ff       	call   80105bce <argint>
80105c1e:	85 c0                	test   %eax,%eax
80105c20:	79 07                	jns    80105c29 <argptr+0x23>
    return -1;
80105c22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c27:	eb 3d                	jmp    80105c66 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105c29:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c2c:	89 c2                	mov    %eax,%edx
80105c2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c34:	8b 00                	mov    (%eax),%eax
80105c36:	39 c2                	cmp    %eax,%edx
80105c38:	73 16                	jae    80105c50 <argptr+0x4a>
80105c3a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c3d:	89 c2                	mov    %eax,%edx
80105c3f:	8b 45 10             	mov    0x10(%ebp),%eax
80105c42:	01 c2                	add    %eax,%edx
80105c44:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c4a:	8b 00                	mov    (%eax),%eax
80105c4c:	39 c2                	cmp    %eax,%edx
80105c4e:	76 07                	jbe    80105c57 <argptr+0x51>
    return -1;
80105c50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c55:	eb 0f                	jmp    80105c66 <argptr+0x60>
  *pp = (char*)i;
80105c57:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c5a:	89 c2                	mov    %eax,%edx
80105c5c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c5f:	89 10                	mov    %edx,(%eax)
  return 0;
80105c61:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c66:	c9                   	leave  
80105c67:	c3                   	ret    

80105c68 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105c68:	55                   	push   %ebp
80105c69:	89 e5                	mov    %esp,%ebp
80105c6b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105c6e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105c71:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c75:	8b 45 08             	mov    0x8(%ebp),%eax
80105c78:	89 04 24             	mov    %eax,(%esp)
80105c7b:	e8 4e ff ff ff       	call   80105bce <argint>
80105c80:	85 c0                	test   %eax,%eax
80105c82:	79 07                	jns    80105c8b <argstr+0x23>
    return -1;
80105c84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c89:	eb 1e                	jmp    80105ca9 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105c8b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c8e:	89 c2                	mov    %eax,%edx
80105c90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105c96:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105c99:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105c9d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ca1:	89 04 24             	mov    %eax,(%esp)
80105ca4:	e8 c7 fe ff ff       	call   80105b70 <fetchstr>
}
80105ca9:	c9                   	leave  
80105caa:	c3                   	ret    

80105cab <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
80105cab:	55                   	push   %ebp
80105cac:	89 e5                	mov    %esp,%ebp
80105cae:	53                   	push   %ebx
80105caf:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105cb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cb8:	8b 40 18             	mov    0x18(%eax),%eax
80105cbb:	8b 40 1c             	mov    0x1c(%eax),%eax
80105cbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105cc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cc5:	78 2e                	js     80105cf5 <syscall+0x4a>
80105cc7:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105ccb:	7f 28                	jg     80105cf5 <syscall+0x4a>
80105ccd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cd0:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105cd7:	85 c0                	test   %eax,%eax
80105cd9:	74 1a                	je     80105cf5 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105cdb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ce1:	8b 58 18             	mov    0x18(%eax),%ebx
80105ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ce7:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105cee:	ff d0                	call   *%eax
80105cf0:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105cf3:	eb 73                	jmp    80105d68 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105cf5:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105cf9:	7e 30                	jle    80105d2b <syscall+0x80>
80105cfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cfe:	83 f8 19             	cmp    $0x19,%eax
80105d01:	77 28                	ja     80105d2b <syscall+0x80>
80105d03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d06:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105d0d:	85 c0                	test   %eax,%eax
80105d0f:	74 1a                	je     80105d2b <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80105d11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d17:	8b 58 18             	mov    0x18(%eax),%ebx
80105d1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d1d:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105d24:	ff d0                	call   *%eax
80105d26:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105d29:	eb 3d                	jmp    80105d68 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105d2b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d31:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105d34:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105d3a:	8b 40 10             	mov    0x10(%eax),%eax
80105d3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d40:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105d44:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105d48:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d4c:	c7 04 24 3b 92 10 80 	movl   $0x8010923b,(%esp)
80105d53:	e8 49 a6 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105d58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d5e:	8b 40 18             	mov    0x18(%eax),%eax
80105d61:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105d68:	83 c4 24             	add    $0x24,%esp
80105d6b:	5b                   	pop    %ebx
80105d6c:	5d                   	pop    %ebp
80105d6d:	c3                   	ret    
	...

80105d70 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105d70:	55                   	push   %ebp
80105d71:	89 e5                	mov    %esp,%ebp
80105d73:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105d76:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d79:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d80:	89 04 24             	mov    %eax,(%esp)
80105d83:	e8 46 fe ff ff       	call   80105bce <argint>
80105d88:	85 c0                	test   %eax,%eax
80105d8a:	79 07                	jns    80105d93 <argfd+0x23>
    return -1;
80105d8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d91:	eb 50                	jmp    80105de3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105d93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d96:	85 c0                	test   %eax,%eax
80105d98:	78 21                	js     80105dbb <argfd+0x4b>
80105d9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d9d:	83 f8 0f             	cmp    $0xf,%eax
80105da0:	7f 19                	jg     80105dbb <argfd+0x4b>
80105da2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105da8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105dab:	83 c2 08             	add    $0x8,%edx
80105dae:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105db2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105db5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105db9:	75 07                	jne    80105dc2 <argfd+0x52>
    return -1;
80105dbb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dc0:	eb 21                	jmp    80105de3 <argfd+0x73>
  if(pfd)
80105dc2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105dc6:	74 08                	je     80105dd0 <argfd+0x60>
    *pfd = fd;
80105dc8:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105dcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105dce:	89 10                	mov    %edx,(%eax)
  if(pf)
80105dd0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105dd4:	74 08                	je     80105dde <argfd+0x6e>
    *pf = f;
80105dd6:	8b 45 10             	mov    0x10(%ebp),%eax
80105dd9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ddc:	89 10                	mov    %edx,(%eax)
  return 0;
80105dde:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105de3:	c9                   	leave  
80105de4:	c3                   	ret    

80105de5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105de5:	55                   	push   %ebp
80105de6:	89 e5                	mov    %esp,%ebp
80105de8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105deb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105df2:	eb 30                	jmp    80105e24 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105df4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dfa:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105dfd:	83 c2 08             	add    $0x8,%edx
80105e00:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105e04:	85 c0                	test   %eax,%eax
80105e06:	75 18                	jne    80105e20 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105e08:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e0e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e11:	8d 4a 08             	lea    0x8(%edx),%ecx
80105e14:	8b 55 08             	mov    0x8(%ebp),%edx
80105e17:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105e1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e1e:	eb 0f                	jmp    80105e2f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105e20:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105e24:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105e28:	7e ca                	jle    80105df4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105e2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105e2f:	c9                   	leave  
80105e30:	c3                   	ret    

80105e31 <sys_dup>:

int
sys_dup(void)
{
80105e31:	55                   	push   %ebp
80105e32:	89 e5                	mov    %esp,%ebp
80105e34:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105e37:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e3a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e3e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e45:	00 
80105e46:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e4d:	e8 1e ff ff ff       	call   80105d70 <argfd>
80105e52:	85 c0                	test   %eax,%eax
80105e54:	79 07                	jns    80105e5d <sys_dup+0x2c>
    return -1;
80105e56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e5b:	eb 29                	jmp    80105e86 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105e5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e60:	89 04 24             	mov    %eax,(%esp)
80105e63:	e8 7d ff ff ff       	call   80105de5 <fdalloc>
80105e68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e6f:	79 07                	jns    80105e78 <sys_dup+0x47>
    return -1;
80105e71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e76:	eb 0e                	jmp    80105e86 <sys_dup+0x55>
  filedup(f);
80105e78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e7b:	89 04 24             	mov    %eax,(%esp)
80105e7e:	e8 f9 b0 ff ff       	call   80100f7c <filedup>
  return fd;
80105e83:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105e86:	c9                   	leave  
80105e87:	c3                   	ret    

80105e88 <sys_read>:

int
sys_read(void)
{
80105e88:	55                   	push   %ebp
80105e89:	89 e5                	mov    %esp,%ebp
80105e8b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105e8e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105e91:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e95:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e9c:	00 
80105e9d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ea4:	e8 c7 fe ff ff       	call   80105d70 <argfd>
80105ea9:	85 c0                	test   %eax,%eax
80105eab:	78 35                	js     80105ee2 <sys_read+0x5a>
80105ead:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105eb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eb4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105ebb:	e8 0e fd ff ff       	call   80105bce <argint>
80105ec0:	85 c0                	test   %eax,%eax
80105ec2:	78 1e                	js     80105ee2 <sys_read+0x5a>
80105ec4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ecb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105ece:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ed9:	e8 28 fd ff ff       	call   80105c06 <argptr>
80105ede:	85 c0                	test   %eax,%eax
80105ee0:	79 07                	jns    80105ee9 <sys_read+0x61>
    return -1;
80105ee2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ee7:	eb 19                	jmp    80105f02 <sys_read+0x7a>
  return fileread(f, p, n);
80105ee9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105eec:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105eef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ef2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ef6:	89 54 24 04          	mov    %edx,0x4(%esp)
80105efa:	89 04 24             	mov    %eax,(%esp)
80105efd:	e8 e7 b1 ff ff       	call   801010e9 <fileread>
}
80105f02:	c9                   	leave  
80105f03:	c3                   	ret    

80105f04 <sys_write>:

int
sys_write(void)
{
80105f04:	55                   	push   %ebp
80105f05:	89 e5                	mov    %esp,%ebp
80105f07:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105f0a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f0d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f18:	00 
80105f19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f20:	e8 4b fe ff ff       	call   80105d70 <argfd>
80105f25:	85 c0                	test   %eax,%eax
80105f27:	78 35                	js     80105f5e <sys_write+0x5a>
80105f29:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f30:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105f37:	e8 92 fc ff ff       	call   80105bce <argint>
80105f3c:	85 c0                	test   %eax,%eax
80105f3e:	78 1e                	js     80105f5e <sys_write+0x5a>
80105f40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f43:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f47:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105f4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f4e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f55:	e8 ac fc ff ff       	call   80105c06 <argptr>
80105f5a:	85 c0                	test   %eax,%eax
80105f5c:	79 07                	jns    80105f65 <sys_write+0x61>
    return -1;
80105f5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f63:	eb 19                	jmp    80105f7e <sys_write+0x7a>
  return filewrite(f, p, n);
80105f65:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105f68:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105f6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f6e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105f72:	89 54 24 04          	mov    %edx,0x4(%esp)
80105f76:	89 04 24             	mov    %eax,(%esp)
80105f79:	e8 27 b2 ff ff       	call   801011a5 <filewrite>
}
80105f7e:	c9                   	leave  
80105f7f:	c3                   	ret    

80105f80 <sys_close>:

int
sys_close(void)
{
80105f80:	55                   	push   %ebp
80105f81:	89 e5                	mov    %esp,%ebp
80105f83:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105f86:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f89:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f8d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105f90:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f94:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f9b:	e8 d0 fd ff ff       	call   80105d70 <argfd>
80105fa0:	85 c0                	test   %eax,%eax
80105fa2:	79 07                	jns    80105fab <sys_close+0x2b>
    return -1;
80105fa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa9:	eb 24                	jmp    80105fcf <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105fab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105fb1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105fb4:	83 c2 08             	add    $0x8,%edx
80105fb7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105fbe:	00 
  fileclose(f);
80105fbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fc2:	89 04 24             	mov    %eax,(%esp)
80105fc5:	e8 fa af ff ff       	call   80100fc4 <fileclose>
  return 0;
80105fca:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105fcf:	c9                   	leave  
80105fd0:	c3                   	ret    

80105fd1 <sys_fstat>:

int
sys_fstat(void)
{
80105fd1:	55                   	push   %ebp
80105fd2:	89 e5                	mov    %esp,%ebp
80105fd4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105fd7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fda:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fde:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fe5:	00 
80105fe6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fed:	e8 7e fd ff ff       	call   80105d70 <argfd>
80105ff2:	85 c0                	test   %eax,%eax
80105ff4:	78 1f                	js     80106015 <sys_fstat+0x44>
80105ff6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105ffd:	00 
80105ffe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106001:	89 44 24 04          	mov    %eax,0x4(%esp)
80106005:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010600c:	e8 f5 fb ff ff       	call   80105c06 <argptr>
80106011:	85 c0                	test   %eax,%eax
80106013:	79 07                	jns    8010601c <sys_fstat+0x4b>
    return -1;
80106015:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010601a:	eb 12                	jmp    8010602e <sys_fstat+0x5d>
  return filestat(f, st);
8010601c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010601f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106022:	89 54 24 04          	mov    %edx,0x4(%esp)
80106026:	89 04 24             	mov    %eax,(%esp)
80106029:	e8 6c b0 ff ff       	call   8010109a <filestat>
}
8010602e:	c9                   	leave  
8010602f:	c3                   	ret    

80106030 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106030:	55                   	push   %ebp
80106031:	89 e5                	mov    %esp,%ebp
80106033:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106036:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106039:	89 44 24 04          	mov    %eax,0x4(%esp)
8010603d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106044:	e8 1f fc ff ff       	call   80105c68 <argstr>
80106049:	85 c0                	test   %eax,%eax
8010604b:	78 17                	js     80106064 <sys_link+0x34>
8010604d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106050:	89 44 24 04          	mov    %eax,0x4(%esp)
80106054:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010605b:	e8 08 fc ff ff       	call   80105c68 <argstr>
80106060:	85 c0                	test   %eax,%eax
80106062:	79 0a                	jns    8010606e <sys_link+0x3e>
    return -1;
80106064:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106069:	e9 3c 01 00 00       	jmp    801061aa <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010606e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106071:	89 04 24             	mov    %eax,(%esp)
80106074:	e8 1d ce ff ff       	call   80102e96 <namei>
80106079:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010607c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106080:	75 0a                	jne    8010608c <sys_link+0x5c>
    return -1;
80106082:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106087:	e9 1e 01 00 00       	jmp    801061aa <sys_link+0x17a>

  begin_trans();
8010608c:	e8 18 dc ff ff       	call   80103ca9 <begin_trans>

  ilock(ip);
80106091:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106094:	89 04 24             	mov    %eax,(%esp)
80106097:	e8 58 c2 ff ff       	call   801022f4 <ilock>
  if(ip->type == T_DIR){
8010609c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010609f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801060a3:	66 83 f8 01          	cmp    $0x1,%ax
801060a7:	75 1a                	jne    801060c3 <sys_link+0x93>
    iunlockput(ip);
801060a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ac:	89 04 24             	mov    %eax,(%esp)
801060af:	e8 c4 c4 ff ff       	call   80102578 <iunlockput>
    commit_trans();
801060b4:	e8 39 dc ff ff       	call   80103cf2 <commit_trans>
    return -1;
801060b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060be:	e9 e7 00 00 00       	jmp    801061aa <sys_link+0x17a>
  }

  ip->nlink++;
801060c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060c6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801060ca:	8d 50 01             	lea    0x1(%eax),%edx
801060cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060d0:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801060d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060d7:	89 04 24             	mov    %eax,(%esp)
801060da:	e8 59 c0 ff ff       	call   80102138 <iupdate>
  iunlock(ip);
801060df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060e2:	89 04 24             	mov    %eax,(%esp)
801060e5:	e8 58 c3 ff ff       	call   80102442 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801060ea:	8b 45 dc             	mov    -0x24(%ebp),%eax
801060ed:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801060f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801060f4:	89 04 24             	mov    %eax,(%esp)
801060f7:	e8 bc cd ff ff       	call   80102eb8 <nameiparent>
801060fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060ff:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106103:	74 68                	je     8010616d <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106105:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106108:	89 04 24             	mov    %eax,(%esp)
8010610b:	e8 e4 c1 ff ff       	call   801022f4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106110:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106113:	8b 10                	mov    (%eax),%edx
80106115:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106118:	8b 00                	mov    (%eax),%eax
8010611a:	39 c2                	cmp    %eax,%edx
8010611c:	75 20                	jne    8010613e <sys_link+0x10e>
8010611e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106121:	8b 40 04             	mov    0x4(%eax),%eax
80106124:	89 44 24 08          	mov    %eax,0x8(%esp)
80106128:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010612b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010612f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106132:	89 04 24             	mov    %eax,(%esp)
80106135:	e8 9b ca ff ff       	call   80102bd5 <dirlink>
8010613a:	85 c0                	test   %eax,%eax
8010613c:	79 0d                	jns    8010614b <sys_link+0x11b>
    iunlockput(dp);
8010613e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106141:	89 04 24             	mov    %eax,(%esp)
80106144:	e8 2f c4 ff ff       	call   80102578 <iunlockput>
    goto bad;
80106149:	eb 23                	jmp    8010616e <sys_link+0x13e>
  }
  iunlockput(dp);
8010614b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010614e:	89 04 24             	mov    %eax,(%esp)
80106151:	e8 22 c4 ff ff       	call   80102578 <iunlockput>
  iput(ip);
80106156:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106159:	89 04 24             	mov    %eax,(%esp)
8010615c:	e8 46 c3 ff ff       	call   801024a7 <iput>

  commit_trans();
80106161:	e8 8c db ff ff       	call   80103cf2 <commit_trans>

  return 0;
80106166:	b8 00 00 00 00       	mov    $0x0,%eax
8010616b:	eb 3d                	jmp    801061aa <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
8010616d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010616e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106171:	89 04 24             	mov    %eax,(%esp)
80106174:	e8 7b c1 ff ff       	call   801022f4 <ilock>
  ip->nlink--;
80106179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010617c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106180:	8d 50 ff             	lea    -0x1(%eax),%edx
80106183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106186:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010618a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618d:	89 04 24             	mov    %eax,(%esp)
80106190:	e8 a3 bf ff ff       	call   80102138 <iupdate>
  iunlockput(ip);
80106195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106198:	89 04 24             	mov    %eax,(%esp)
8010619b:	e8 d8 c3 ff ff       	call   80102578 <iunlockput>
  commit_trans();
801061a0:	e8 4d db ff ff       	call   80103cf2 <commit_trans>
  return -1;
801061a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801061aa:	c9                   	leave  
801061ab:	c3                   	ret    

801061ac <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801061ac:	55                   	push   %ebp
801061ad:	89 e5                	mov    %esp,%ebp
801061af:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801061b2:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801061b9:	eb 4b                	jmp    80106206 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801061bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061be:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801061c5:	00 
801061c6:	89 44 24 08          	mov    %eax,0x8(%esp)
801061ca:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801061cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801061d1:	8b 45 08             	mov    0x8(%ebp),%eax
801061d4:	89 04 24             	mov    %eax,(%esp)
801061d7:	e8 0e c6 ff ff       	call   801027ea <readi>
801061dc:	83 f8 10             	cmp    $0x10,%eax
801061df:	74 0c                	je     801061ed <isdirempty+0x41>
      panic("isdirempty: readi");
801061e1:	c7 04 24 57 92 10 80 	movl   $0x80109257,(%esp)
801061e8:	e8 50 a3 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801061ed:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801061f1:	66 85 c0             	test   %ax,%ax
801061f4:	74 07                	je     801061fd <isdirempty+0x51>
      return 0;
801061f6:	b8 00 00 00 00       	mov    $0x0,%eax
801061fb:	eb 1b                	jmp    80106218 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801061fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106200:	83 c0 10             	add    $0x10,%eax
80106203:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106206:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106209:	8b 45 08             	mov    0x8(%ebp),%eax
8010620c:	8b 40 18             	mov    0x18(%eax),%eax
8010620f:	39 c2                	cmp    %eax,%edx
80106211:	72 a8                	jb     801061bb <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106213:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106218:	c9                   	leave  
80106219:	c3                   	ret    

8010621a <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010621a:	55                   	push   %ebp
8010621b:	89 e5                	mov    %esp,%ebp
8010621d:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106220:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106223:	89 44 24 04          	mov    %eax,0x4(%esp)
80106227:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010622e:	e8 35 fa ff ff       	call   80105c68 <argstr>
80106233:	85 c0                	test   %eax,%eax
80106235:	79 0a                	jns    80106241 <sys_unlink+0x27>
    return -1;
80106237:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623c:	e9 aa 01 00 00       	jmp    801063eb <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106241:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106244:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106247:	89 54 24 04          	mov    %edx,0x4(%esp)
8010624b:	89 04 24             	mov    %eax,(%esp)
8010624e:	e8 65 cc ff ff       	call   80102eb8 <nameiparent>
80106253:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106256:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010625a:	75 0a                	jne    80106266 <sys_unlink+0x4c>
    return -1;
8010625c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106261:	e9 85 01 00 00       	jmp    801063eb <sys_unlink+0x1d1>

  begin_trans();
80106266:	e8 3e da ff ff       	call   80103ca9 <begin_trans>

  ilock(dp);
8010626b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626e:	89 04 24             	mov    %eax,(%esp)
80106271:	e8 7e c0 ff ff       	call   801022f4 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106276:	c7 44 24 04 69 92 10 	movl   $0x80109269,0x4(%esp)
8010627d:	80 
8010627e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106281:	89 04 24             	mov    %eax,(%esp)
80106284:	e8 62 c8 ff ff       	call   80102aeb <namecmp>
80106289:	85 c0                	test   %eax,%eax
8010628b:	0f 84 45 01 00 00    	je     801063d6 <sys_unlink+0x1bc>
80106291:	c7 44 24 04 6b 92 10 	movl   $0x8010926b,0x4(%esp)
80106298:	80 
80106299:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010629c:	89 04 24             	mov    %eax,(%esp)
8010629f:	e8 47 c8 ff ff       	call   80102aeb <namecmp>
801062a4:	85 c0                	test   %eax,%eax
801062a6:	0f 84 2a 01 00 00    	je     801063d6 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801062ac:	8d 45 c8             	lea    -0x38(%ebp),%eax
801062af:	89 44 24 08          	mov    %eax,0x8(%esp)
801062b3:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801062b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bd:	89 04 24             	mov    %eax,(%esp)
801062c0:	e8 48 c8 ff ff       	call   80102b0d <dirlookup>
801062c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801062c8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801062cc:	0f 84 03 01 00 00    	je     801063d5 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801062d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062d5:	89 04 24             	mov    %eax,(%esp)
801062d8:	e8 17 c0 ff ff       	call   801022f4 <ilock>

  if(ip->nlink < 1)
801062dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801062e4:	66 85 c0             	test   %ax,%ax
801062e7:	7f 0c                	jg     801062f5 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
801062e9:	c7 04 24 6e 92 10 80 	movl   $0x8010926e,(%esp)
801062f0:	e8 48 a2 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801062f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801062fc:	66 83 f8 01          	cmp    $0x1,%ax
80106300:	75 1f                	jne    80106321 <sys_unlink+0x107>
80106302:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106305:	89 04 24             	mov    %eax,(%esp)
80106308:	e8 9f fe ff ff       	call   801061ac <isdirempty>
8010630d:	85 c0                	test   %eax,%eax
8010630f:	75 10                	jne    80106321 <sys_unlink+0x107>
    iunlockput(ip);
80106311:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106314:	89 04 24             	mov    %eax,(%esp)
80106317:	e8 5c c2 ff ff       	call   80102578 <iunlockput>
    goto bad;
8010631c:	e9 b5 00 00 00       	jmp    801063d6 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106321:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106328:	00 
80106329:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106330:	00 
80106331:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106334:	89 04 24             	mov    %eax,(%esp)
80106337:	e8 42 f5 ff ff       	call   8010587e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010633c:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010633f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106346:	00 
80106347:	89 44 24 08          	mov    %eax,0x8(%esp)
8010634b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010634e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106355:	89 04 24             	mov    %eax,(%esp)
80106358:	e8 f8 c5 ff ff       	call   80102955 <writei>
8010635d:	83 f8 10             	cmp    $0x10,%eax
80106360:	74 0c                	je     8010636e <sys_unlink+0x154>
    panic("unlink: writei");
80106362:	c7 04 24 80 92 10 80 	movl   $0x80109280,(%esp)
80106369:	e8 cf a1 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010636e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106371:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106375:	66 83 f8 01          	cmp    $0x1,%ax
80106379:	75 1c                	jne    80106397 <sys_unlink+0x17d>
    dp->nlink--;
8010637b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106382:	8d 50 ff             	lea    -0x1(%eax),%edx
80106385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106388:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010638c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010638f:	89 04 24             	mov    %eax,(%esp)
80106392:	e8 a1 bd ff ff       	call   80102138 <iupdate>
  }
  iunlockput(dp);
80106397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639a:	89 04 24             	mov    %eax,(%esp)
8010639d:	e8 d6 c1 ff ff       	call   80102578 <iunlockput>

  ip->nlink--;
801063a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063a5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063a9:	8d 50 ff             	lea    -0x1(%eax),%edx
801063ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063af:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801063b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063b6:	89 04 24             	mov    %eax,(%esp)
801063b9:	e8 7a bd ff ff       	call   80102138 <iupdate>
  iunlockput(ip);
801063be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063c1:	89 04 24             	mov    %eax,(%esp)
801063c4:	e8 af c1 ff ff       	call   80102578 <iunlockput>

  commit_trans();
801063c9:	e8 24 d9 ff ff       	call   80103cf2 <commit_trans>

  return 0;
801063ce:	b8 00 00 00 00       	mov    $0x0,%eax
801063d3:	eb 16                	jmp    801063eb <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801063d5:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801063d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d9:	89 04 24             	mov    %eax,(%esp)
801063dc:	e8 97 c1 ff ff       	call   80102578 <iunlockput>
  commit_trans();
801063e1:	e8 0c d9 ff ff       	call   80103cf2 <commit_trans>
  return -1;
801063e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063eb:	c9                   	leave  
801063ec:	c3                   	ret    

801063ed <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
801063ed:	55                   	push   %ebp
801063ee:	89 e5                	mov    %esp,%ebp
801063f0:	83 ec 48             	sub    $0x48,%esp
801063f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801063f6:	8b 55 10             	mov    0x10(%ebp),%edx
801063f9:	8b 45 14             	mov    0x14(%ebp),%eax
801063fc:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106400:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106404:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106408:	8d 45 de             	lea    -0x22(%ebp),%eax
8010640b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010640f:	8b 45 08             	mov    0x8(%ebp),%eax
80106412:	89 04 24             	mov    %eax,(%esp)
80106415:	e8 9e ca ff ff       	call   80102eb8 <nameiparent>
8010641a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010641d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106421:	75 0a                	jne    8010642d <create+0x40>
    return 0;
80106423:	b8 00 00 00 00       	mov    $0x0,%eax
80106428:	e9 7e 01 00 00       	jmp    801065ab <create+0x1be>
  ilock(dp);
8010642d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106430:	89 04 24             	mov    %eax,(%esp)
80106433:	e8 bc be ff ff       	call   801022f4 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106438:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010643b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010643f:	8d 45 de             	lea    -0x22(%ebp),%eax
80106442:	89 44 24 04          	mov    %eax,0x4(%esp)
80106446:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106449:	89 04 24             	mov    %eax,(%esp)
8010644c:	e8 bc c6 ff ff       	call   80102b0d <dirlookup>
80106451:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106454:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106458:	74 47                	je     801064a1 <create+0xb4>
    iunlockput(dp);
8010645a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010645d:	89 04 24             	mov    %eax,(%esp)
80106460:	e8 13 c1 ff ff       	call   80102578 <iunlockput>
    ilock(ip);
80106465:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106468:	89 04 24             	mov    %eax,(%esp)
8010646b:	e8 84 be ff ff       	call   801022f4 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106470:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106475:	75 15                	jne    8010648c <create+0x9f>
80106477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010647a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010647e:	66 83 f8 02          	cmp    $0x2,%ax
80106482:	75 08                	jne    8010648c <create+0x9f>
      return ip;
80106484:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106487:	e9 1f 01 00 00       	jmp    801065ab <create+0x1be>
    iunlockput(ip);
8010648c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010648f:	89 04 24             	mov    %eax,(%esp)
80106492:	e8 e1 c0 ff ff       	call   80102578 <iunlockput>
    return 0;
80106497:	b8 00 00 00 00       	mov    $0x0,%eax
8010649c:	e9 0a 01 00 00       	jmp    801065ab <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801064a1:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801064a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a8:	8b 00                	mov    (%eax),%eax
801064aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801064ae:	89 04 24             	mov    %eax,(%esp)
801064b1:	e8 a5 bb ff ff       	call   8010205b <ialloc>
801064b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801064b9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801064bd:	75 0c                	jne    801064cb <create+0xde>
    panic("create: ialloc");
801064bf:	c7 04 24 8f 92 10 80 	movl   $0x8010928f,(%esp)
801064c6:	e8 72 a0 ff ff       	call   8010053d <panic>

  ilock(ip);
801064cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ce:	89 04 24             	mov    %eax,(%esp)
801064d1:	e8 1e be ff ff       	call   801022f4 <ilock>
  ip->major = major;
801064d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064d9:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801064dd:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801064e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064e4:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801064e8:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801064ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ef:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801064f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064f8:	89 04 24             	mov    %eax,(%esp)
801064fb:	e8 38 bc ff ff       	call   80102138 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106500:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106505:	75 6a                	jne    80106571 <create+0x184>
    dp->nlink++;  // for ".."
80106507:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010650a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010650e:	8d 50 01             	lea    0x1(%eax),%edx
80106511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106514:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106518:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651b:	89 04 24             	mov    %eax,(%esp)
8010651e:	e8 15 bc ff ff       	call   80102138 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106523:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106526:	8b 40 04             	mov    0x4(%eax),%eax
80106529:	89 44 24 08          	mov    %eax,0x8(%esp)
8010652d:	c7 44 24 04 69 92 10 	movl   $0x80109269,0x4(%esp)
80106534:	80 
80106535:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106538:	89 04 24             	mov    %eax,(%esp)
8010653b:	e8 95 c6 ff ff       	call   80102bd5 <dirlink>
80106540:	85 c0                	test   %eax,%eax
80106542:	78 21                	js     80106565 <create+0x178>
80106544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106547:	8b 40 04             	mov    0x4(%eax),%eax
8010654a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010654e:	c7 44 24 04 6b 92 10 	movl   $0x8010926b,0x4(%esp)
80106555:	80 
80106556:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106559:	89 04 24             	mov    %eax,(%esp)
8010655c:	e8 74 c6 ff ff       	call   80102bd5 <dirlink>
80106561:	85 c0                	test   %eax,%eax
80106563:	79 0c                	jns    80106571 <create+0x184>
      panic("create dots");
80106565:	c7 04 24 9e 92 10 80 	movl   $0x8010929e,(%esp)
8010656c:	e8 cc 9f ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106571:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106574:	8b 40 04             	mov    0x4(%eax),%eax
80106577:	89 44 24 08          	mov    %eax,0x8(%esp)
8010657b:	8d 45 de             	lea    -0x22(%ebp),%eax
8010657e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106585:	89 04 24             	mov    %eax,(%esp)
80106588:	e8 48 c6 ff ff       	call   80102bd5 <dirlink>
8010658d:	85 c0                	test   %eax,%eax
8010658f:	79 0c                	jns    8010659d <create+0x1b0>
    panic("create: dirlink");
80106591:	c7 04 24 aa 92 10 80 	movl   $0x801092aa,(%esp)
80106598:	e8 a0 9f ff ff       	call   8010053d <panic>

  iunlockput(dp);
8010659d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a0:	89 04 24             	mov    %eax,(%esp)
801065a3:	e8 d0 bf ff ff       	call   80102578 <iunlockput>

  return ip;
801065a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801065ab:	c9                   	leave  
801065ac:	c3                   	ret    

801065ad <fileopen>:

struct file*
fileopen(char* path, int omode)
{
801065ad:	55                   	push   %ebp
801065ae:	89 e5                	mov    %esp,%ebp
801065b0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
801065b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801065b6:	25 00 02 00 00       	and    $0x200,%eax
801065bb:	85 c0                	test   %eax,%eax
801065bd:	74 40                	je     801065ff <fileopen+0x52>
    begin_trans();
801065bf:	e8 e5 d6 ff ff       	call   80103ca9 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801065c4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801065cb:	00 
801065cc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801065d3:	00 
801065d4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801065db:	00 
801065dc:	8b 45 08             	mov    0x8(%ebp),%eax
801065df:	89 04 24             	mov    %eax,(%esp)
801065e2:	e8 06 fe ff ff       	call   801063ed <create>
801065e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
801065ea:	e8 03 d7 ff ff       	call   80103cf2 <commit_trans>
    if(ip == 0)
801065ef:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065f3:	75 5b                	jne    80106650 <fileopen+0xa3>
      return 0;
801065f5:	b8 00 00 00 00       	mov    $0x0,%eax
801065fa:	e9 e5 00 00 00       	jmp    801066e4 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
801065ff:	8b 45 08             	mov    0x8(%ebp),%eax
80106602:	89 04 24             	mov    %eax,(%esp)
80106605:	e8 8c c8 ff ff       	call   80102e96 <namei>
8010660a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010660d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106611:	75 0a                	jne    8010661d <fileopen+0x70>
      return 0;
80106613:	b8 00 00 00 00       	mov    $0x0,%eax
80106618:	e9 c7 00 00 00       	jmp    801066e4 <fileopen+0x137>
    ilock(ip);
8010661d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106620:	89 04 24             	mov    %eax,(%esp)
80106623:	e8 cc bc ff ff       	call   801022f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106628:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010662f:	66 83 f8 01          	cmp    $0x1,%ax
80106633:	75 1b                	jne    80106650 <fileopen+0xa3>
80106635:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106639:	74 15                	je     80106650 <fileopen+0xa3>
      iunlockput(ip);
8010663b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663e:	89 04 24             	mov    %eax,(%esp)
80106641:	e8 32 bf ff ff       	call   80102578 <iunlockput>
      return 0;
80106646:	b8 00 00 00 00       	mov    $0x0,%eax
8010664b:	e9 94 00 00 00       	jmp    801066e4 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106650:	e8 c7 a8 ff ff       	call   80100f1c <filealloc>
80106655:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106658:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010665c:	75 23                	jne    80106681 <fileopen+0xd4>
    if(f)
8010665e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106662:	74 0b                	je     8010666f <fileopen+0xc2>
      fileclose(f);
80106664:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106667:	89 04 24             	mov    %eax,(%esp)
8010666a:	e8 55 a9 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
8010666f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106672:	89 04 24             	mov    %eax,(%esp)
80106675:	e8 fe be ff ff       	call   80102578 <iunlockput>
    return 0;
8010667a:	b8 00 00 00 00       	mov    $0x0,%eax
8010667f:	eb 63                	jmp    801066e4 <fileopen+0x137>
  }
  iunlock(ip);
80106681:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106684:	89 04 24             	mov    %eax,(%esp)
80106687:	e8 b6 bd ff ff       	call   80102442 <iunlock>

  f->type = FD_INODE;
8010668c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010668f:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106695:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106698:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010669b:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010669e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066a1:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801066a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801066ab:	83 e0 01             	and    $0x1,%eax
801066ae:	85 c0                	test   %eax,%eax
801066b0:	0f 94 c2             	sete   %dl
801066b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b6:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801066b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801066bc:	83 e0 01             	and    $0x1,%eax
801066bf:	84 c0                	test   %al,%al
801066c1:	75 0a                	jne    801066cd <fileopen+0x120>
801066c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801066c6:	83 e0 02             	and    $0x2,%eax
801066c9:	85 c0                	test   %eax,%eax
801066cb:	74 07                	je     801066d4 <fileopen+0x127>
801066cd:	b8 01 00 00 00       	mov    $0x1,%eax
801066d2:	eb 05                	jmp    801066d9 <fileopen+0x12c>
801066d4:	b8 00 00 00 00       	mov    $0x0,%eax
801066d9:	89 c2                	mov    %eax,%edx
801066db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066de:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
801066e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066e4:	c9                   	leave  
801066e5:	c3                   	ret    

801066e6 <sys_open>:

int
sys_open(void)
{
801066e6:	55                   	push   %ebp
801066e7:	89 e5                	mov    %esp,%ebp
801066e9:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801066ec:	8d 45 e8             	lea    -0x18(%ebp),%eax
801066ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801066f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066fa:	e8 69 f5 ff ff       	call   80105c68 <argstr>
801066ff:	85 c0                	test   %eax,%eax
80106701:	78 17                	js     8010671a <sys_open+0x34>
80106703:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106706:	89 44 24 04          	mov    %eax,0x4(%esp)
8010670a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106711:	e8 b8 f4 ff ff       	call   80105bce <argint>
80106716:	85 c0                	test   %eax,%eax
80106718:	79 0a                	jns    80106724 <sys_open+0x3e>
    return -1;
8010671a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010671f:	e9 46 01 00 00       	jmp    8010686a <sys_open+0x184>
  if(omode & O_CREATE){
80106724:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106727:	25 00 02 00 00       	and    $0x200,%eax
8010672c:	85 c0                	test   %eax,%eax
8010672e:	74 40                	je     80106770 <sys_open+0x8a>
    begin_trans();
80106730:	e8 74 d5 ff ff       	call   80103ca9 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106735:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106738:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010673f:	00 
80106740:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106747:	00 
80106748:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010674f:	00 
80106750:	89 04 24             	mov    %eax,(%esp)
80106753:	e8 95 fc ff ff       	call   801063ed <create>
80106758:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
8010675b:	e8 92 d5 ff ff       	call   80103cf2 <commit_trans>
    if(ip == 0)
80106760:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106764:	75 5c                	jne    801067c2 <sys_open+0xdc>
      return -1;
80106766:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010676b:	e9 fa 00 00 00       	jmp    8010686a <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106770:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106773:	89 04 24             	mov    %eax,(%esp)
80106776:	e8 1b c7 ff ff       	call   80102e96 <namei>
8010677b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010677e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106782:	75 0a                	jne    8010678e <sys_open+0xa8>
      return -1;
80106784:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106789:	e9 dc 00 00 00       	jmp    8010686a <sys_open+0x184>
    ilock(ip);
8010678e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106791:	89 04 24             	mov    %eax,(%esp)
80106794:	e8 5b bb ff ff       	call   801022f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801067a0:	66 83 f8 01          	cmp    $0x1,%ax
801067a4:	75 1c                	jne    801067c2 <sys_open+0xdc>
801067a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801067a9:	85 c0                	test   %eax,%eax
801067ab:	74 15                	je     801067c2 <sys_open+0xdc>
      iunlockput(ip);
801067ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b0:	89 04 24             	mov    %eax,(%esp)
801067b3:	e8 c0 bd ff ff       	call   80102578 <iunlockput>
      return -1;
801067b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067bd:	e9 a8 00 00 00       	jmp    8010686a <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801067c2:	e8 55 a7 ff ff       	call   80100f1c <filealloc>
801067c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801067ca:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067ce:	74 14                	je     801067e4 <sys_open+0xfe>
801067d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067d3:	89 04 24             	mov    %eax,(%esp)
801067d6:	e8 0a f6 ff ff       	call   80105de5 <fdalloc>
801067db:	89 45 ec             	mov    %eax,-0x14(%ebp)
801067de:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801067e2:	79 23                	jns    80106807 <sys_open+0x121>
    if(f)
801067e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801067e8:	74 0b                	je     801067f5 <sys_open+0x10f>
      fileclose(f);
801067ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067ed:	89 04 24             	mov    %eax,(%esp)
801067f0:	e8 cf a7 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
801067f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067f8:	89 04 24             	mov    %eax,(%esp)
801067fb:	e8 78 bd ff ff       	call   80102578 <iunlockput>
    return -1;
80106800:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106805:	eb 63                	jmp    8010686a <sys_open+0x184>
  }
  iunlock(ip);
80106807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680a:	89 04 24             	mov    %eax,(%esp)
8010680d:	e8 30 bc ff ff       	call   80102442 <iunlock>

  f->type = FD_INODE;
80106812:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106815:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
8010681b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010681e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106821:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106824:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106827:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010682e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106831:	83 e0 01             	and    $0x1,%eax
80106834:	85 c0                	test   %eax,%eax
80106836:	0f 94 c2             	sete   %dl
80106839:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010683c:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010683f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106842:	83 e0 01             	and    $0x1,%eax
80106845:	84 c0                	test   %al,%al
80106847:	75 0a                	jne    80106853 <sys_open+0x16d>
80106849:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010684c:	83 e0 02             	and    $0x2,%eax
8010684f:	85 c0                	test   %eax,%eax
80106851:	74 07                	je     8010685a <sys_open+0x174>
80106853:	b8 01 00 00 00       	mov    $0x1,%eax
80106858:	eb 05                	jmp    8010685f <sys_open+0x179>
8010685a:	b8 00 00 00 00       	mov    $0x0,%eax
8010685f:	89 c2                	mov    %eax,%edx
80106861:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106864:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106867:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010686a:	c9                   	leave  
8010686b:	c3                   	ret    

8010686c <sys_mkdir>:

int
sys_mkdir(void)
{
8010686c:	55                   	push   %ebp
8010686d:	89 e5                	mov    %esp,%ebp
8010686f:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106872:	e8 32 d4 ff ff       	call   80103ca9 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106877:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010687a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010687e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106885:	e8 de f3 ff ff       	call   80105c68 <argstr>
8010688a:	85 c0                	test   %eax,%eax
8010688c:	78 2c                	js     801068ba <sys_mkdir+0x4e>
8010688e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106891:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106898:	00 
80106899:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801068a0:	00 
801068a1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801068a8:	00 
801068a9:	89 04 24             	mov    %eax,(%esp)
801068ac:	e8 3c fb ff ff       	call   801063ed <create>
801068b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068b4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801068b8:	75 0c                	jne    801068c6 <sys_mkdir+0x5a>
    commit_trans();
801068ba:	e8 33 d4 ff ff       	call   80103cf2 <commit_trans>
    return -1;
801068bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068c4:	eb 15                	jmp    801068db <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801068c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c9:	89 04 24             	mov    %eax,(%esp)
801068cc:	e8 a7 bc ff ff       	call   80102578 <iunlockput>
  commit_trans();
801068d1:	e8 1c d4 ff ff       	call   80103cf2 <commit_trans>
  return 0;
801068d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068db:	c9                   	leave  
801068dc:	c3                   	ret    

801068dd <sys_mknod>:

int
sys_mknod(void)
{
801068dd:	55                   	push   %ebp
801068de:	89 e5                	mov    %esp,%ebp
801068e0:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801068e3:	e8 c1 d3 ff ff       	call   80103ca9 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801068e8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801068eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801068ef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801068f6:	e8 6d f3 ff ff       	call   80105c68 <argstr>
801068fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801068fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106902:	78 5e                	js     80106962 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106904:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106907:	89 44 24 04          	mov    %eax,0x4(%esp)
8010690b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106912:	e8 b7 f2 ff ff       	call   80105bce <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106917:	85 c0                	test   %eax,%eax
80106919:	78 47                	js     80106962 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010691b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010691e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106922:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106929:	e8 a0 f2 ff ff       	call   80105bce <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010692e:	85 c0                	test   %eax,%eax
80106930:	78 30                	js     80106962 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106932:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106935:	0f bf c8             	movswl %ax,%ecx
80106938:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010693b:	0f bf d0             	movswl %ax,%edx
8010693e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106941:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106945:	89 54 24 08          	mov    %edx,0x8(%esp)
80106949:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106950:	00 
80106951:	89 04 24             	mov    %eax,(%esp)
80106954:	e8 94 fa ff ff       	call   801063ed <create>
80106959:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010695c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106960:	75 0c                	jne    8010696e <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106962:	e8 8b d3 ff ff       	call   80103cf2 <commit_trans>
    return -1;
80106967:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010696c:	eb 15                	jmp    80106983 <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010696e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106971:	89 04 24             	mov    %eax,(%esp)
80106974:	e8 ff bb ff ff       	call   80102578 <iunlockput>
  commit_trans();
80106979:	e8 74 d3 ff ff       	call   80103cf2 <commit_trans>
  return 0;
8010697e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106983:	c9                   	leave  
80106984:	c3                   	ret    

80106985 <sys_chdir>:

int
sys_chdir(void)
{
80106985:	55                   	push   %ebp
80106986:	89 e5                	mov    %esp,%ebp
80106988:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
8010698b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010698e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106992:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106999:	e8 ca f2 ff ff       	call   80105c68 <argstr>
8010699e:	85 c0                	test   %eax,%eax
801069a0:	78 14                	js     801069b6 <sys_chdir+0x31>
801069a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069a5:	89 04 24             	mov    %eax,(%esp)
801069a8:	e8 e9 c4 ff ff       	call   80102e96 <namei>
801069ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069b0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069b4:	75 07                	jne    801069bd <sys_chdir+0x38>
    return -1;
801069b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069bb:	eb 57                	jmp    80106a14 <sys_chdir+0x8f>
  ilock(ip);
801069bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c0:	89 04 24             	mov    %eax,(%esp)
801069c3:	e8 2c b9 ff ff       	call   801022f4 <ilock>
  if(ip->type != T_DIR){
801069c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069cb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069cf:	66 83 f8 01          	cmp    $0x1,%ax
801069d3:	74 12                	je     801069e7 <sys_chdir+0x62>
    iunlockput(ip);
801069d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d8:	89 04 24             	mov    %eax,(%esp)
801069db:	e8 98 bb ff ff       	call   80102578 <iunlockput>
    return -1;
801069e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069e5:	eb 2d                	jmp    80106a14 <sys_chdir+0x8f>
  }
  iunlock(ip);
801069e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ea:	89 04 24             	mov    %eax,(%esp)
801069ed:	e8 50 ba ff ff       	call   80102442 <iunlock>
  iput(proc->cwd);
801069f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069f8:	8b 40 68             	mov    0x68(%eax),%eax
801069fb:	89 04 24             	mov    %eax,(%esp)
801069fe:	e8 a4 ba ff ff       	call   801024a7 <iput>
  proc->cwd = ip;
80106a03:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a0c:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106a0f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a14:	c9                   	leave  
80106a15:	c3                   	ret    

80106a16 <sys_exec>:

int
sys_exec(void)
{
80106a16:	55                   	push   %ebp
80106a17:	89 e5                	mov    %esp,%ebp
80106a19:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106a1f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106a22:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a2d:	e8 36 f2 ff ff       	call   80105c68 <argstr>
80106a32:	85 c0                	test   %eax,%eax
80106a34:	78 1a                	js     80106a50 <sys_exec+0x3a>
80106a36:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a40:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a47:	e8 82 f1 ff ff       	call   80105bce <argint>
80106a4c:	85 c0                	test   %eax,%eax
80106a4e:	79 0a                	jns    80106a5a <sys_exec+0x44>
    return -1;
80106a50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a55:	e9 e2 00 00 00       	jmp    80106b3c <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106a5a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106a61:	00 
80106a62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106a69:	00 
80106a6a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106a70:	89 04 24             	mov    %eax,(%esp)
80106a73:	e8 06 ee ff ff       	call   8010587e <memset>
  for(i=0;; i++){
80106a78:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a82:	83 f8 1f             	cmp    $0x1f,%eax
80106a85:	76 0a                	jbe    80106a91 <sys_exec+0x7b>
      return -1;
80106a87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a8c:	e9 ab 00 00 00       	jmp    80106b3c <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a94:	c1 e0 02             	shl    $0x2,%eax
80106a97:	89 c2                	mov    %eax,%edx
80106a99:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106a9f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106aa2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106aa8:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106aae:	89 54 24 08          	mov    %edx,0x8(%esp)
80106ab2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106ab6:	89 04 24             	mov    %eax,(%esp)
80106ab9:	e8 7e f0 ff ff       	call   80105b3c <fetchint>
80106abe:	85 c0                	test   %eax,%eax
80106ac0:	79 07                	jns    80106ac9 <sys_exec+0xb3>
      return -1;
80106ac2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ac7:	eb 73                	jmp    80106b3c <sys_exec+0x126>
    if(uarg == 0){
80106ac9:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106acf:	85 c0                	test   %eax,%eax
80106ad1:	75 26                	jne    80106af9 <sys_exec+0xe3>
      argv[i] = 0;
80106ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad6:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106add:	00 00 00 00 
      break;
80106ae1:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae5:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106aeb:	89 54 24 04          	mov    %edx,0x4(%esp)
80106aef:	89 04 24             	mov    %eax,(%esp)
80106af2:	e8 05 a0 ff ff       	call   80100afc <exec>
80106af7:	eb 43                	jmp    80106b3c <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106afc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106b03:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b09:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106b0c:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106b12:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106b1c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106b20:	89 04 24             	mov    %eax,(%esp)
80106b23:	e8 48 f0 ff ff       	call   80105b70 <fetchstr>
80106b28:	85 c0                	test   %eax,%eax
80106b2a:	79 07                	jns    80106b33 <sys_exec+0x11d>
      return -1;
80106b2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b31:	eb 09                	jmp    80106b3c <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106b33:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106b37:	e9 43 ff ff ff       	jmp    80106a7f <sys_exec+0x69>
  return exec(path, argv);
}
80106b3c:	c9                   	leave  
80106b3d:	c3                   	ret    

80106b3e <sys_pipe>:

int
sys_pipe(void)
{
80106b3e:	55                   	push   %ebp
80106b3f:	89 e5                	mov    %esp,%ebp
80106b41:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106b44:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106b4b:	00 
80106b4c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b53:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b5a:	e8 a7 f0 ff ff       	call   80105c06 <argptr>
80106b5f:	85 c0                	test   %eax,%eax
80106b61:	79 0a                	jns    80106b6d <sys_pipe+0x2f>
    return -1;
80106b63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b68:	e9 9b 00 00 00       	jmp    80106c08 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106b6d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b70:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b74:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b77:	89 04 24             	mov    %eax,(%esp)
80106b7a:	e8 45 db ff ff       	call   801046c4 <pipealloc>
80106b7f:	85 c0                	test   %eax,%eax
80106b81:	79 07                	jns    80106b8a <sys_pipe+0x4c>
    return -1;
80106b83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b88:	eb 7e                	jmp    80106c08 <sys_pipe+0xca>
  fd0 = -1;
80106b8a:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106b91:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b94:	89 04 24             	mov    %eax,(%esp)
80106b97:	e8 49 f2 ff ff       	call   80105de5 <fdalloc>
80106b9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b9f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ba3:	78 14                	js     80106bb9 <sys_pipe+0x7b>
80106ba5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ba8:	89 04 24             	mov    %eax,(%esp)
80106bab:	e8 35 f2 ff ff       	call   80105de5 <fdalloc>
80106bb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bb3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bb7:	79 37                	jns    80106bf0 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106bb9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bbd:	78 14                	js     80106bd3 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106bbf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bc5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bc8:	83 c2 08             	add    $0x8,%edx
80106bcb:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106bd2:	00 
    fileclose(rf);
80106bd3:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bd6:	89 04 24             	mov    %eax,(%esp)
80106bd9:	e8 e6 a3 ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80106bde:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106be1:	89 04 24             	mov    %eax,(%esp)
80106be4:	e8 db a3 ff ff       	call   80100fc4 <fileclose>
    return -1;
80106be9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bee:	eb 18                	jmp    80106c08 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106bf0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bf3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106bf6:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106bf8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106bfb:	8d 50 04             	lea    0x4(%eax),%edx
80106bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c01:	89 02                	mov    %eax,(%edx)
  return 0;
80106c03:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c08:	c9                   	leave  
80106c09:	c3                   	ret    
	...

80106c0c <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106c0c:	55                   	push   %ebp
80106c0d:	89 e5                	mov    %esp,%ebp
80106c0f:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106c12:	e8 67 e1 ff ff       	call   80104d7e <fork>
}
80106c17:	c9                   	leave  
80106c18:	c3                   	ret    

80106c19 <sys_exit>:

int
sys_exit(void)
{
80106c19:	55                   	push   %ebp
80106c1a:	89 e5                	mov    %esp,%ebp
80106c1c:	83 ec 08             	sub    $0x8,%esp
  exit();
80106c1f:	e8 bd e2 ff ff       	call   80104ee1 <exit>
  return 0;  // not reached
80106c24:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106c29:	c9                   	leave  
80106c2a:	c3                   	ret    

80106c2b <sys_wait>:

int
sys_wait(void)
{
80106c2b:	55                   	push   %ebp
80106c2c:	89 e5                	mov    %esp,%ebp
80106c2e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106c31:	e8 c3 e3 ff ff       	call   80104ff9 <wait>
}
80106c36:	c9                   	leave  
80106c37:	c3                   	ret    

80106c38 <sys_kill>:

int
sys_kill(void)
{
80106c38:	55                   	push   %ebp
80106c39:	89 e5                	mov    %esp,%ebp
80106c3b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106c3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106c41:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c4c:	e8 7d ef ff ff       	call   80105bce <argint>
80106c51:	85 c0                	test   %eax,%eax
80106c53:	79 07                	jns    80106c5c <sys_kill+0x24>
    return -1;
80106c55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c5a:	eb 0b                	jmp    80106c67 <sys_kill+0x2f>
  return kill(pid);
80106c5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c5f:	89 04 24             	mov    %eax,(%esp)
80106c62:	e8 ee e7 ff ff       	call   80105455 <kill>
}
80106c67:	c9                   	leave  
80106c68:	c3                   	ret    

80106c69 <sys_getpid>:

int
sys_getpid(void)
{
80106c69:	55                   	push   %ebp
80106c6a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106c6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c72:	8b 40 10             	mov    0x10(%eax),%eax
}
80106c75:	5d                   	pop    %ebp
80106c76:	c3                   	ret    

80106c77 <sys_sbrk>:

int
sys_sbrk(void)
{
80106c77:	55                   	push   %ebp
80106c78:	89 e5                	mov    %esp,%ebp
80106c7a:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106c7d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c80:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c84:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c8b:	e8 3e ef ff ff       	call   80105bce <argint>
80106c90:	85 c0                	test   %eax,%eax
80106c92:	79 07                	jns    80106c9b <sys_sbrk+0x24>
    return -1;
80106c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c99:	eb 24                	jmp    80106cbf <sys_sbrk+0x48>
  addr = proc->sz;
80106c9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ca1:	8b 00                	mov    (%eax),%eax
80106ca3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106ca6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca9:	89 04 24             	mov    %eax,(%esp)
80106cac:	e8 28 e0 ff ff       	call   80104cd9 <growproc>
80106cb1:	85 c0                	test   %eax,%eax
80106cb3:	79 07                	jns    80106cbc <sys_sbrk+0x45>
    return -1;
80106cb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cba:	eb 03                	jmp    80106cbf <sys_sbrk+0x48>
  return addr;
80106cbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106cbf:	c9                   	leave  
80106cc0:	c3                   	ret    

80106cc1 <sys_sleep>:

int
sys_sleep(void)
{
80106cc1:	55                   	push   %ebp
80106cc2:	89 e5                	mov    %esp,%ebp
80106cc4:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106cc7:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106cca:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cd5:	e8 f4 ee ff ff       	call   80105bce <argint>
80106cda:	85 c0                	test   %eax,%eax
80106cdc:	79 07                	jns    80106ce5 <sys_sleep+0x24>
    return -1;
80106cde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ce3:	eb 6c                	jmp    80106d51 <sys_sleep+0x90>
  acquire(&tickslock);
80106ce5:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106cec:	e8 3e e9 ff ff       	call   8010562f <acquire>
  ticks0 = ticks;
80106cf1:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106cf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106cf9:	eb 34                	jmp    80106d2f <sys_sleep+0x6e>
    if(proc->killed){
80106cfb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d01:	8b 40 24             	mov    0x24(%eax),%eax
80106d04:	85 c0                	test   %eax,%eax
80106d06:	74 13                	je     80106d1b <sys_sleep+0x5a>
      release(&tickslock);
80106d08:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106d0f:	e8 7d e9 ff ff       	call   80105691 <release>
      return -1;
80106d14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d19:	eb 36                	jmp    80106d51 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106d1b:	c7 44 24 04 80 2e 11 	movl   $0x80112e80,0x4(%esp)
80106d22:	80 
80106d23:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80106d2a:	e8 22 e6 ff ff       	call   80105351 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106d2f:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106d34:	89 c2                	mov    %eax,%edx
80106d36:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d3c:	39 c2                	cmp    %eax,%edx
80106d3e:	72 bb                	jb     80106cfb <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106d40:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106d47:	e8 45 e9 ff ff       	call   80105691 <release>
  return 0;
80106d4c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d51:	c9                   	leave  
80106d52:	c3                   	ret    

80106d53 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106d53:	55                   	push   %ebp
80106d54:	89 e5                	mov    %esp,%ebp
80106d56:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106d59:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106d60:	e8 ca e8 ff ff       	call   8010562f <acquire>
  xticks = ticks;
80106d65:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106d6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106d6d:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106d74:	e8 18 e9 ff ff       	call   80105691 <release>
  return xticks;
80106d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106d7c:	c9                   	leave  
80106d7d:	c3                   	ret    

80106d7e <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
80106d7e:	55                   	push   %ebp
80106d7f:	89 e5                	mov    %esp,%ebp
80106d81:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
80106d84:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106d87:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d8b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d92:	e8 d1 ee ff ff       	call   80105c68 <argstr>
80106d97:	85 c0                	test   %eax,%eax
80106d99:	79 07                	jns    80106da2 <sys_getFileBlocks+0x24>
    return -1;
80106d9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106da0:	eb 0b                	jmp    80106dad <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
80106da2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106da5:	89 04 24             	mov    %eax,(%esp)
80106da8:	e8 3d a5 ff ff       	call   801012ea <getFileBlocks>
}
80106dad:	c9                   	leave  
80106dae:	c3                   	ret    

80106daf <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
80106daf:	55                   	push   %ebp
80106db0:	89 e5                	mov    %esp,%ebp
80106db2:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
80106db5:	e8 8d a6 ff ff       	call   80101447 <getFreeBlocks>
}
80106dba:	c9                   	leave  
80106dbb:	c3                   	ret    

80106dbc <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
80106dbc:	55                   	push   %ebp
80106dbd:	89 e5                	mov    %esp,%ebp
  return 0;
80106dbf:	b8 00 00 00 00       	mov    $0x0,%eax
  
}
80106dc4:	5d                   	pop    %ebp
80106dc5:	c3                   	ret    

80106dc6 <sys_dedup>:

int
sys_dedup(void)
{
80106dc6:	55                   	push   %ebp
80106dc7:	89 e5                	mov    %esp,%ebp
80106dc9:	83 ec 08             	sub    $0x8,%esp
  return dedup();
80106dcc:	e8 64 a8 ff ff       	call   80101635 <dedup>
}
80106dd1:	c9                   	leave  
80106dd2:	c3                   	ret    
	...

80106dd4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106dd4:	55                   	push   %ebp
80106dd5:	89 e5                	mov    %esp,%ebp
80106dd7:	83 ec 08             	sub    $0x8,%esp
80106dda:	8b 55 08             	mov    0x8(%ebp),%edx
80106ddd:	8b 45 0c             	mov    0xc(%ebp),%eax
80106de0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106de4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106de7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106deb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106def:	ee                   	out    %al,(%dx)
}
80106df0:	c9                   	leave  
80106df1:	c3                   	ret    

80106df2 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106df2:	55                   	push   %ebp
80106df3:	89 e5                	mov    %esp,%ebp
80106df5:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106df8:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106dff:	00 
80106e00:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106e07:	e8 c8 ff ff ff       	call   80106dd4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106e0c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106e13:	00 
80106e14:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106e1b:	e8 b4 ff ff ff       	call   80106dd4 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106e20:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106e27:	00 
80106e28:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106e2f:	e8 a0 ff ff ff       	call   80106dd4 <outb>
  picenable(IRQ_TIMER);
80106e34:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e3b:	e8 0d d7 ff ff       	call   8010454d <picenable>
}
80106e40:	c9                   	leave  
80106e41:	c3                   	ret    
	...

80106e44 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106e44:	1e                   	push   %ds
  pushl %es
80106e45:	06                   	push   %es
  pushl %fs
80106e46:	0f a0                	push   %fs
  pushl %gs
80106e48:	0f a8                	push   %gs
  pushal
80106e4a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106e4b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106e4f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106e51:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106e53:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106e57:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106e59:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106e5b:	54                   	push   %esp
  call trap
80106e5c:	e8 de 01 00 00       	call   8010703f <trap>
  addl $4, %esp
80106e61:	83 c4 04             	add    $0x4,%esp

80106e64 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106e64:	61                   	popa   
  popl %gs
80106e65:	0f a9                	pop    %gs
  popl %fs
80106e67:	0f a1                	pop    %fs
  popl %es
80106e69:	07                   	pop    %es
  popl %ds
80106e6a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106e6b:	83 c4 08             	add    $0x8,%esp
  iret
80106e6e:	cf                   	iret   
	...

80106e70 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106e70:	55                   	push   %ebp
80106e71:	89 e5                	mov    %esp,%ebp
80106e73:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106e76:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e79:	83 e8 01             	sub    $0x1,%eax
80106e7c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106e80:	8b 45 08             	mov    0x8(%ebp),%eax
80106e83:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106e87:	8b 45 08             	mov    0x8(%ebp),%eax
80106e8a:	c1 e8 10             	shr    $0x10,%eax
80106e8d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106e91:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106e94:	0f 01 18             	lidtl  (%eax)
}
80106e97:	c9                   	leave  
80106e98:	c3                   	ret    

80106e99 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106e99:	55                   	push   %ebp
80106e9a:	89 e5                	mov    %esp,%ebp
80106e9c:	53                   	push   %ebx
80106e9d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106ea0:	0f 20 d3             	mov    %cr2,%ebx
80106ea3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106ea6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106ea9:	83 c4 10             	add    $0x10,%esp
80106eac:	5b                   	pop    %ebx
80106ead:	5d                   	pop    %ebp
80106eae:	c3                   	ret    

80106eaf <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106eaf:	55                   	push   %ebp
80106eb0:	89 e5                	mov    %esp,%ebp
80106eb2:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106eb5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106ebc:	e9 c3 00 00 00       	jmp    80106f84 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106ec1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ec4:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80106ecb:	89 c2                	mov    %eax,%edx
80106ecd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ed0:	66 89 14 c5 c0 2e 11 	mov    %dx,-0x7feed140(,%eax,8)
80106ed7:	80 
80106ed8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106edb:	66 c7 04 c5 c2 2e 11 	movw   $0x8,-0x7feed13e(,%eax,8)
80106ee2:	80 08 00 
80106ee5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ee8:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80106eef:	80 
80106ef0:	83 e2 e0             	and    $0xffffffe0,%edx
80106ef3:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80106efa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efd:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80106f04:	80 
80106f05:	83 e2 1f             	and    $0x1f,%edx
80106f08:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80106f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f12:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80106f19:	80 
80106f1a:	83 e2 f0             	and    $0xfffffff0,%edx
80106f1d:	83 ca 0e             	or     $0xe,%edx
80106f20:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80106f27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f2a:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80106f31:	80 
80106f32:	83 e2 ef             	and    $0xffffffef,%edx
80106f35:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80106f3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f3f:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80106f46:	80 
80106f47:	83 e2 9f             	and    $0xffffff9f,%edx
80106f4a:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80106f51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f54:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80106f5b:	80 
80106f5c:	83 ca 80             	or     $0xffffff80,%edx
80106f5f:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80106f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f69:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80106f70:	c1 e8 10             	shr    $0x10,%eax
80106f73:	89 c2                	mov    %eax,%edx
80106f75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f78:	66 89 14 c5 c6 2e 11 	mov    %dx,-0x7feed13a(,%eax,8)
80106f7f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106f80:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f84:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106f8b:	0f 8e 30 ff ff ff    	jle    80106ec1 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106f91:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80106f96:	66 a3 c0 30 11 80    	mov    %ax,0x801130c0
80106f9c:	66 c7 05 c2 30 11 80 	movw   $0x8,0x801130c2
80106fa3:	08 00 
80106fa5:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
80106fac:	83 e0 e0             	and    $0xffffffe0,%eax
80106faf:	a2 c4 30 11 80       	mov    %al,0x801130c4
80106fb4:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
80106fbb:	83 e0 1f             	and    $0x1f,%eax
80106fbe:	a2 c4 30 11 80       	mov    %al,0x801130c4
80106fc3:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80106fca:	83 c8 0f             	or     $0xf,%eax
80106fcd:	a2 c5 30 11 80       	mov    %al,0x801130c5
80106fd2:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80106fd9:	83 e0 ef             	and    $0xffffffef,%eax
80106fdc:	a2 c5 30 11 80       	mov    %al,0x801130c5
80106fe1:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80106fe8:	83 c8 60             	or     $0x60,%eax
80106feb:	a2 c5 30 11 80       	mov    %al,0x801130c5
80106ff0:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80106ff7:	83 c8 80             	or     $0xffffff80,%eax
80106ffa:	a2 c5 30 11 80       	mov    %al,0x801130c5
80106fff:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107004:	c1 e8 10             	shr    $0x10,%eax
80107007:	66 a3 c6 30 11 80    	mov    %ax,0x801130c6
  
  initlock(&tickslock, "time");
8010700d:	c7 44 24 04 bc 92 10 	movl   $0x801092bc,0x4(%esp)
80107014:	80 
80107015:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
8010701c:	e8 ed e5 ff ff       	call   8010560e <initlock>
}
80107021:	c9                   	leave  
80107022:	c3                   	ret    

80107023 <idtinit>:

void
idtinit(void)
{
80107023:	55                   	push   %ebp
80107024:	89 e5                	mov    %esp,%ebp
80107026:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107029:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107030:	00 
80107031:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107038:	e8 33 fe ff ff       	call   80106e70 <lidt>
}
8010703d:	c9                   	leave  
8010703e:	c3                   	ret    

8010703f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010703f:	55                   	push   %ebp
80107040:	89 e5                	mov    %esp,%ebp
80107042:	57                   	push   %edi
80107043:	56                   	push   %esi
80107044:	53                   	push   %ebx
80107045:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107048:	8b 45 08             	mov    0x8(%ebp),%eax
8010704b:	8b 40 30             	mov    0x30(%eax),%eax
8010704e:	83 f8 40             	cmp    $0x40,%eax
80107051:	75 3e                	jne    80107091 <trap+0x52>
    if(proc->killed)
80107053:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107059:	8b 40 24             	mov    0x24(%eax),%eax
8010705c:	85 c0                	test   %eax,%eax
8010705e:	74 05                	je     80107065 <trap+0x26>
      exit();
80107060:	e8 7c de ff ff       	call   80104ee1 <exit>
    proc->tf = tf;
80107065:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010706b:	8b 55 08             	mov    0x8(%ebp),%edx
8010706e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107071:	e8 35 ec ff ff       	call   80105cab <syscall>
    if(proc->killed)
80107076:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010707c:	8b 40 24             	mov    0x24(%eax),%eax
8010707f:	85 c0                	test   %eax,%eax
80107081:	0f 84 34 02 00 00    	je     801072bb <trap+0x27c>
      exit();
80107087:	e8 55 de ff ff       	call   80104ee1 <exit>
    return;
8010708c:	e9 2a 02 00 00       	jmp    801072bb <trap+0x27c>
  }

  switch(tf->trapno){
80107091:	8b 45 08             	mov    0x8(%ebp),%eax
80107094:	8b 40 30             	mov    0x30(%eax),%eax
80107097:	83 e8 20             	sub    $0x20,%eax
8010709a:	83 f8 1f             	cmp    $0x1f,%eax
8010709d:	0f 87 bc 00 00 00    	ja     8010715f <trap+0x120>
801070a3:	8b 04 85 64 93 10 80 	mov    -0x7fef6c9c(,%eax,4),%eax
801070aa:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801070ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801070b2:	0f b6 00             	movzbl (%eax),%eax
801070b5:	84 c0                	test   %al,%al
801070b7:	75 31                	jne    801070ea <trap+0xab>
      acquire(&tickslock);
801070b9:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801070c0:	e8 6a e5 ff ff       	call   8010562f <acquire>
      ticks++;
801070c5:	a1 c0 36 11 80       	mov    0x801136c0,%eax
801070ca:	83 c0 01             	add    $0x1,%eax
801070cd:	a3 c0 36 11 80       	mov    %eax,0x801136c0
      wakeup(&ticks);
801070d2:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
801070d9:	e8 4c e3 ff ff       	call   8010542a <wakeup>
      release(&tickslock);
801070de:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801070e5:	e8 a7 e5 ff ff       	call   80105691 <release>
    }
    lapiceoi();
801070ea:	e8 86 c8 ff ff       	call   80103975 <lapiceoi>
    break;
801070ef:	e9 41 01 00 00       	jmp    80107235 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801070f4:	e8 84 c0 ff ff       	call   8010317d <ideintr>
    lapiceoi();
801070f9:	e8 77 c8 ff ff       	call   80103975 <lapiceoi>
    break;
801070fe:	e9 32 01 00 00       	jmp    80107235 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107103:	e8 4b c6 ff ff       	call   80103753 <kbdintr>
    lapiceoi();
80107108:	e8 68 c8 ff ff       	call   80103975 <lapiceoi>
    break;
8010710d:	e9 23 01 00 00       	jmp    80107235 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107112:	e8 a9 03 00 00       	call   801074c0 <uartintr>
    lapiceoi();
80107117:	e8 59 c8 ff ff       	call   80103975 <lapiceoi>
    break;
8010711c:	e9 14 01 00 00       	jmp    80107235 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107121:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107124:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107127:	8b 45 08             	mov    0x8(%ebp),%eax
8010712a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010712e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107131:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107137:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010713a:	0f b6 c0             	movzbl %al,%eax
8010713d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107141:	89 54 24 08          	mov    %edx,0x8(%esp)
80107145:	89 44 24 04          	mov    %eax,0x4(%esp)
80107149:	c7 04 24 c4 92 10 80 	movl   $0x801092c4,(%esp)
80107150:	e8 4c 92 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107155:	e8 1b c8 ff ff       	call   80103975 <lapiceoi>
    break;
8010715a:	e9 d6 00 00 00       	jmp    80107235 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010715f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107165:	85 c0                	test   %eax,%eax
80107167:	74 11                	je     8010717a <trap+0x13b>
80107169:	8b 45 08             	mov    0x8(%ebp),%eax
8010716c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107170:	0f b7 c0             	movzwl %ax,%eax
80107173:	83 e0 03             	and    $0x3,%eax
80107176:	85 c0                	test   %eax,%eax
80107178:	75 46                	jne    801071c0 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010717a:	e8 1a fd ff ff       	call   80106e99 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010717f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107182:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107185:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010718c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010718f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107192:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107195:	8b 52 30             	mov    0x30(%edx),%edx
80107198:	89 44 24 10          	mov    %eax,0x10(%esp)
8010719c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801071a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801071a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801071a8:	c7 04 24 e8 92 10 80 	movl   $0x801092e8,(%esp)
801071af:	e8 ed 91 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801071b4:	c7 04 24 1a 93 10 80 	movl   $0x8010931a,(%esp)
801071bb:	e8 7d 93 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071c0:	e8 d4 fc ff ff       	call   80106e99 <rcr2>
801071c5:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071c7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071ca:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071cd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801071d3:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071d6:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071d9:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071dc:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071df:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071e2:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801071e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071eb:	83 c0 6c             	add    $0x6c,%eax
801071ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801071f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801071f7:	8b 40 10             	mov    0x10(%eax),%eax
801071fa:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801071fe:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107202:	89 74 24 14          	mov    %esi,0x14(%esp)
80107206:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010720a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010720e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107211:	89 54 24 08          	mov    %edx,0x8(%esp)
80107215:	89 44 24 04          	mov    %eax,0x4(%esp)
80107219:	c7 04 24 20 93 10 80 	movl   $0x80109320,(%esp)
80107220:	e8 7c 91 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107225:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010722b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107232:	eb 01                	jmp    80107235 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107234:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107235:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010723b:	85 c0                	test   %eax,%eax
8010723d:	74 24                	je     80107263 <trap+0x224>
8010723f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107245:	8b 40 24             	mov    0x24(%eax),%eax
80107248:	85 c0                	test   %eax,%eax
8010724a:	74 17                	je     80107263 <trap+0x224>
8010724c:	8b 45 08             	mov    0x8(%ebp),%eax
8010724f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107253:	0f b7 c0             	movzwl %ax,%eax
80107256:	83 e0 03             	and    $0x3,%eax
80107259:	83 f8 03             	cmp    $0x3,%eax
8010725c:	75 05                	jne    80107263 <trap+0x224>
    exit();
8010725e:	e8 7e dc ff ff       	call   80104ee1 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107263:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107269:	85 c0                	test   %eax,%eax
8010726b:	74 1e                	je     8010728b <trap+0x24c>
8010726d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107273:	8b 40 0c             	mov    0xc(%eax),%eax
80107276:	83 f8 04             	cmp    $0x4,%eax
80107279:	75 10                	jne    8010728b <trap+0x24c>
8010727b:	8b 45 08             	mov    0x8(%ebp),%eax
8010727e:	8b 40 30             	mov    0x30(%eax),%eax
80107281:	83 f8 20             	cmp    $0x20,%eax
80107284:	75 05                	jne    8010728b <trap+0x24c>
    yield();
80107286:	e8 68 e0 ff ff       	call   801052f3 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010728b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107291:	85 c0                	test   %eax,%eax
80107293:	74 27                	je     801072bc <trap+0x27d>
80107295:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010729b:	8b 40 24             	mov    0x24(%eax),%eax
8010729e:	85 c0                	test   %eax,%eax
801072a0:	74 1a                	je     801072bc <trap+0x27d>
801072a2:	8b 45 08             	mov    0x8(%ebp),%eax
801072a5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801072a9:	0f b7 c0             	movzwl %ax,%eax
801072ac:	83 e0 03             	and    $0x3,%eax
801072af:	83 f8 03             	cmp    $0x3,%eax
801072b2:	75 08                	jne    801072bc <trap+0x27d>
    exit();
801072b4:	e8 28 dc ff ff       	call   80104ee1 <exit>
801072b9:	eb 01                	jmp    801072bc <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801072bb:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801072bc:	83 c4 3c             	add    $0x3c,%esp
801072bf:	5b                   	pop    %ebx
801072c0:	5e                   	pop    %esi
801072c1:	5f                   	pop    %edi
801072c2:	5d                   	pop    %ebp
801072c3:	c3                   	ret    

801072c4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801072c4:	55                   	push   %ebp
801072c5:	89 e5                	mov    %esp,%ebp
801072c7:	53                   	push   %ebx
801072c8:	83 ec 14             	sub    $0x14,%esp
801072cb:	8b 45 08             	mov    0x8(%ebp),%eax
801072ce:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801072d2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801072d6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801072da:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801072de:	ec                   	in     (%dx),%al
801072df:	89 c3                	mov    %eax,%ebx
801072e1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801072e4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801072e8:	83 c4 14             	add    $0x14,%esp
801072eb:	5b                   	pop    %ebx
801072ec:	5d                   	pop    %ebp
801072ed:	c3                   	ret    

801072ee <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801072ee:	55                   	push   %ebp
801072ef:	89 e5                	mov    %esp,%ebp
801072f1:	83 ec 08             	sub    $0x8,%esp
801072f4:	8b 55 08             	mov    0x8(%ebp),%edx
801072f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801072fa:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801072fe:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107301:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107305:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107309:	ee                   	out    %al,(%dx)
}
8010730a:	c9                   	leave  
8010730b:	c3                   	ret    

8010730c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
8010730c:	55                   	push   %ebp
8010730d:	89 e5                	mov    %esp,%ebp
8010730f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107312:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107319:	00 
8010731a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107321:	e8 c8 ff ff ff       	call   801072ee <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107326:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
8010732d:	00 
8010732e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107335:	e8 b4 ff ff ff       	call   801072ee <outb>
  outb(COM1+0, 115200/9600);
8010733a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107341:	00 
80107342:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107349:	e8 a0 ff ff ff       	call   801072ee <outb>
  outb(COM1+1, 0);
8010734e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107355:	00 
80107356:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010735d:	e8 8c ff ff ff       	call   801072ee <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107362:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107369:	00 
8010736a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107371:	e8 78 ff ff ff       	call   801072ee <outb>
  outb(COM1+4, 0);
80107376:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010737d:	00 
8010737e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107385:	e8 64 ff ff ff       	call   801072ee <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010738a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107391:	00 
80107392:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107399:	e8 50 ff ff ff       	call   801072ee <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010739e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801073a5:	e8 1a ff ff ff       	call   801072c4 <inb>
801073aa:	3c ff                	cmp    $0xff,%al
801073ac:	74 6c                	je     8010741a <uartinit+0x10e>
    return;
  uart = 1;
801073ae:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801073b5:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801073b8:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801073bf:	e8 00 ff ff ff       	call   801072c4 <inb>
  inb(COM1+0);
801073c4:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801073cb:	e8 f4 fe ff ff       	call   801072c4 <inb>
  picenable(IRQ_COM1);
801073d0:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801073d7:	e8 71 d1 ff ff       	call   8010454d <picenable>
  ioapicenable(IRQ_COM1, 0);
801073dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801073e3:	00 
801073e4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801073eb:	e8 12 c0 ff ff       	call   80103402 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801073f0:	c7 45 f4 e4 93 10 80 	movl   $0x801093e4,-0xc(%ebp)
801073f7:	eb 15                	jmp    8010740e <uartinit+0x102>
    uartputc(*p);
801073f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073fc:	0f b6 00             	movzbl (%eax),%eax
801073ff:	0f be c0             	movsbl %al,%eax
80107402:	89 04 24             	mov    %eax,(%esp)
80107405:	e8 13 00 00 00       	call   8010741d <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010740a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010740e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107411:	0f b6 00             	movzbl (%eax),%eax
80107414:	84 c0                	test   %al,%al
80107416:	75 e1                	jne    801073f9 <uartinit+0xed>
80107418:	eb 01                	jmp    8010741b <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010741a:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010741b:	c9                   	leave  
8010741c:	c3                   	ret    

8010741d <uartputc>:

void
uartputc(int c)
{
8010741d:	55                   	push   %ebp
8010741e:	89 e5                	mov    %esp,%ebp
80107420:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107423:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107428:	85 c0                	test   %eax,%eax
8010742a:	74 4d                	je     80107479 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010742c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107433:	eb 10                	jmp    80107445 <uartputc+0x28>
    microdelay(10);
80107435:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010743c:	e8 59 c5 ff ff       	call   8010399a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107441:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107445:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107449:	7f 16                	jg     80107461 <uartputc+0x44>
8010744b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107452:	e8 6d fe ff ff       	call   801072c4 <inb>
80107457:	0f b6 c0             	movzbl %al,%eax
8010745a:	83 e0 20             	and    $0x20,%eax
8010745d:	85 c0                	test   %eax,%eax
8010745f:	74 d4                	je     80107435 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107461:	8b 45 08             	mov    0x8(%ebp),%eax
80107464:	0f b6 c0             	movzbl %al,%eax
80107467:	89 44 24 04          	mov    %eax,0x4(%esp)
8010746b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107472:	e8 77 fe ff ff       	call   801072ee <outb>
80107477:	eb 01                	jmp    8010747a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107479:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010747a:	c9                   	leave  
8010747b:	c3                   	ret    

8010747c <uartgetc>:

static int
uartgetc(void)
{
8010747c:	55                   	push   %ebp
8010747d:	89 e5                	mov    %esp,%ebp
8010747f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107482:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107487:	85 c0                	test   %eax,%eax
80107489:	75 07                	jne    80107492 <uartgetc+0x16>
    return -1;
8010748b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107490:	eb 2c                	jmp    801074be <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107492:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107499:	e8 26 fe ff ff       	call   801072c4 <inb>
8010749e:	0f b6 c0             	movzbl %al,%eax
801074a1:	83 e0 01             	and    $0x1,%eax
801074a4:	85 c0                	test   %eax,%eax
801074a6:	75 07                	jne    801074af <uartgetc+0x33>
    return -1;
801074a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074ad:	eb 0f                	jmp    801074be <uartgetc+0x42>
  return inb(COM1+0);
801074af:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074b6:	e8 09 fe ff ff       	call   801072c4 <inb>
801074bb:	0f b6 c0             	movzbl %al,%eax
}
801074be:	c9                   	leave  
801074bf:	c3                   	ret    

801074c0 <uartintr>:

void
uartintr(void)
{
801074c0:	55                   	push   %ebp
801074c1:	89 e5                	mov    %esp,%ebp
801074c3:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801074c6:	c7 04 24 7c 74 10 80 	movl   $0x8010747c,(%esp)
801074cd:	e8 db 92 ff ff       	call   801007ad <consoleintr>
}
801074d2:	c9                   	leave  
801074d3:	c3                   	ret    

801074d4 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801074d4:	6a 00                	push   $0x0
  pushl $0
801074d6:	6a 00                	push   $0x0
  jmp alltraps
801074d8:	e9 67 f9 ff ff       	jmp    80106e44 <alltraps>

801074dd <vector1>:
.globl vector1
vector1:
  pushl $0
801074dd:	6a 00                	push   $0x0
  pushl $1
801074df:	6a 01                	push   $0x1
  jmp alltraps
801074e1:	e9 5e f9 ff ff       	jmp    80106e44 <alltraps>

801074e6 <vector2>:
.globl vector2
vector2:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $2
801074e8:	6a 02                	push   $0x2
  jmp alltraps
801074ea:	e9 55 f9 ff ff       	jmp    80106e44 <alltraps>

801074ef <vector3>:
.globl vector3
vector3:
  pushl $0
801074ef:	6a 00                	push   $0x0
  pushl $3
801074f1:	6a 03                	push   $0x3
  jmp alltraps
801074f3:	e9 4c f9 ff ff       	jmp    80106e44 <alltraps>

801074f8 <vector4>:
.globl vector4
vector4:
  pushl $0
801074f8:	6a 00                	push   $0x0
  pushl $4
801074fa:	6a 04                	push   $0x4
  jmp alltraps
801074fc:	e9 43 f9 ff ff       	jmp    80106e44 <alltraps>

80107501 <vector5>:
.globl vector5
vector5:
  pushl $0
80107501:	6a 00                	push   $0x0
  pushl $5
80107503:	6a 05                	push   $0x5
  jmp alltraps
80107505:	e9 3a f9 ff ff       	jmp    80106e44 <alltraps>

8010750a <vector6>:
.globl vector6
vector6:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $6
8010750c:	6a 06                	push   $0x6
  jmp alltraps
8010750e:	e9 31 f9 ff ff       	jmp    80106e44 <alltraps>

80107513 <vector7>:
.globl vector7
vector7:
  pushl $0
80107513:	6a 00                	push   $0x0
  pushl $7
80107515:	6a 07                	push   $0x7
  jmp alltraps
80107517:	e9 28 f9 ff ff       	jmp    80106e44 <alltraps>

8010751c <vector8>:
.globl vector8
vector8:
  pushl $8
8010751c:	6a 08                	push   $0x8
  jmp alltraps
8010751e:	e9 21 f9 ff ff       	jmp    80106e44 <alltraps>

80107523 <vector9>:
.globl vector9
vector9:
  pushl $0
80107523:	6a 00                	push   $0x0
  pushl $9
80107525:	6a 09                	push   $0x9
  jmp alltraps
80107527:	e9 18 f9 ff ff       	jmp    80106e44 <alltraps>

8010752c <vector10>:
.globl vector10
vector10:
  pushl $10
8010752c:	6a 0a                	push   $0xa
  jmp alltraps
8010752e:	e9 11 f9 ff ff       	jmp    80106e44 <alltraps>

80107533 <vector11>:
.globl vector11
vector11:
  pushl $11
80107533:	6a 0b                	push   $0xb
  jmp alltraps
80107535:	e9 0a f9 ff ff       	jmp    80106e44 <alltraps>

8010753a <vector12>:
.globl vector12
vector12:
  pushl $12
8010753a:	6a 0c                	push   $0xc
  jmp alltraps
8010753c:	e9 03 f9 ff ff       	jmp    80106e44 <alltraps>

80107541 <vector13>:
.globl vector13
vector13:
  pushl $13
80107541:	6a 0d                	push   $0xd
  jmp alltraps
80107543:	e9 fc f8 ff ff       	jmp    80106e44 <alltraps>

80107548 <vector14>:
.globl vector14
vector14:
  pushl $14
80107548:	6a 0e                	push   $0xe
  jmp alltraps
8010754a:	e9 f5 f8 ff ff       	jmp    80106e44 <alltraps>

8010754f <vector15>:
.globl vector15
vector15:
  pushl $0
8010754f:	6a 00                	push   $0x0
  pushl $15
80107551:	6a 0f                	push   $0xf
  jmp alltraps
80107553:	e9 ec f8 ff ff       	jmp    80106e44 <alltraps>

80107558 <vector16>:
.globl vector16
vector16:
  pushl $0
80107558:	6a 00                	push   $0x0
  pushl $16
8010755a:	6a 10                	push   $0x10
  jmp alltraps
8010755c:	e9 e3 f8 ff ff       	jmp    80106e44 <alltraps>

80107561 <vector17>:
.globl vector17
vector17:
  pushl $17
80107561:	6a 11                	push   $0x11
  jmp alltraps
80107563:	e9 dc f8 ff ff       	jmp    80106e44 <alltraps>

80107568 <vector18>:
.globl vector18
vector18:
  pushl $0
80107568:	6a 00                	push   $0x0
  pushl $18
8010756a:	6a 12                	push   $0x12
  jmp alltraps
8010756c:	e9 d3 f8 ff ff       	jmp    80106e44 <alltraps>

80107571 <vector19>:
.globl vector19
vector19:
  pushl $0
80107571:	6a 00                	push   $0x0
  pushl $19
80107573:	6a 13                	push   $0x13
  jmp alltraps
80107575:	e9 ca f8 ff ff       	jmp    80106e44 <alltraps>

8010757a <vector20>:
.globl vector20
vector20:
  pushl $0
8010757a:	6a 00                	push   $0x0
  pushl $20
8010757c:	6a 14                	push   $0x14
  jmp alltraps
8010757e:	e9 c1 f8 ff ff       	jmp    80106e44 <alltraps>

80107583 <vector21>:
.globl vector21
vector21:
  pushl $0
80107583:	6a 00                	push   $0x0
  pushl $21
80107585:	6a 15                	push   $0x15
  jmp alltraps
80107587:	e9 b8 f8 ff ff       	jmp    80106e44 <alltraps>

8010758c <vector22>:
.globl vector22
vector22:
  pushl $0
8010758c:	6a 00                	push   $0x0
  pushl $22
8010758e:	6a 16                	push   $0x16
  jmp alltraps
80107590:	e9 af f8 ff ff       	jmp    80106e44 <alltraps>

80107595 <vector23>:
.globl vector23
vector23:
  pushl $0
80107595:	6a 00                	push   $0x0
  pushl $23
80107597:	6a 17                	push   $0x17
  jmp alltraps
80107599:	e9 a6 f8 ff ff       	jmp    80106e44 <alltraps>

8010759e <vector24>:
.globl vector24
vector24:
  pushl $0
8010759e:	6a 00                	push   $0x0
  pushl $24
801075a0:	6a 18                	push   $0x18
  jmp alltraps
801075a2:	e9 9d f8 ff ff       	jmp    80106e44 <alltraps>

801075a7 <vector25>:
.globl vector25
vector25:
  pushl $0
801075a7:	6a 00                	push   $0x0
  pushl $25
801075a9:	6a 19                	push   $0x19
  jmp alltraps
801075ab:	e9 94 f8 ff ff       	jmp    80106e44 <alltraps>

801075b0 <vector26>:
.globl vector26
vector26:
  pushl $0
801075b0:	6a 00                	push   $0x0
  pushl $26
801075b2:	6a 1a                	push   $0x1a
  jmp alltraps
801075b4:	e9 8b f8 ff ff       	jmp    80106e44 <alltraps>

801075b9 <vector27>:
.globl vector27
vector27:
  pushl $0
801075b9:	6a 00                	push   $0x0
  pushl $27
801075bb:	6a 1b                	push   $0x1b
  jmp alltraps
801075bd:	e9 82 f8 ff ff       	jmp    80106e44 <alltraps>

801075c2 <vector28>:
.globl vector28
vector28:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $28
801075c4:	6a 1c                	push   $0x1c
  jmp alltraps
801075c6:	e9 79 f8 ff ff       	jmp    80106e44 <alltraps>

801075cb <vector29>:
.globl vector29
vector29:
  pushl $0
801075cb:	6a 00                	push   $0x0
  pushl $29
801075cd:	6a 1d                	push   $0x1d
  jmp alltraps
801075cf:	e9 70 f8 ff ff       	jmp    80106e44 <alltraps>

801075d4 <vector30>:
.globl vector30
vector30:
  pushl $0
801075d4:	6a 00                	push   $0x0
  pushl $30
801075d6:	6a 1e                	push   $0x1e
  jmp alltraps
801075d8:	e9 67 f8 ff ff       	jmp    80106e44 <alltraps>

801075dd <vector31>:
.globl vector31
vector31:
  pushl $0
801075dd:	6a 00                	push   $0x0
  pushl $31
801075df:	6a 1f                	push   $0x1f
  jmp alltraps
801075e1:	e9 5e f8 ff ff       	jmp    80106e44 <alltraps>

801075e6 <vector32>:
.globl vector32
vector32:
  pushl $0
801075e6:	6a 00                	push   $0x0
  pushl $32
801075e8:	6a 20                	push   $0x20
  jmp alltraps
801075ea:	e9 55 f8 ff ff       	jmp    80106e44 <alltraps>

801075ef <vector33>:
.globl vector33
vector33:
  pushl $0
801075ef:	6a 00                	push   $0x0
  pushl $33
801075f1:	6a 21                	push   $0x21
  jmp alltraps
801075f3:	e9 4c f8 ff ff       	jmp    80106e44 <alltraps>

801075f8 <vector34>:
.globl vector34
vector34:
  pushl $0
801075f8:	6a 00                	push   $0x0
  pushl $34
801075fa:	6a 22                	push   $0x22
  jmp alltraps
801075fc:	e9 43 f8 ff ff       	jmp    80106e44 <alltraps>

80107601 <vector35>:
.globl vector35
vector35:
  pushl $0
80107601:	6a 00                	push   $0x0
  pushl $35
80107603:	6a 23                	push   $0x23
  jmp alltraps
80107605:	e9 3a f8 ff ff       	jmp    80106e44 <alltraps>

8010760a <vector36>:
.globl vector36
vector36:
  pushl $0
8010760a:	6a 00                	push   $0x0
  pushl $36
8010760c:	6a 24                	push   $0x24
  jmp alltraps
8010760e:	e9 31 f8 ff ff       	jmp    80106e44 <alltraps>

80107613 <vector37>:
.globl vector37
vector37:
  pushl $0
80107613:	6a 00                	push   $0x0
  pushl $37
80107615:	6a 25                	push   $0x25
  jmp alltraps
80107617:	e9 28 f8 ff ff       	jmp    80106e44 <alltraps>

8010761c <vector38>:
.globl vector38
vector38:
  pushl $0
8010761c:	6a 00                	push   $0x0
  pushl $38
8010761e:	6a 26                	push   $0x26
  jmp alltraps
80107620:	e9 1f f8 ff ff       	jmp    80106e44 <alltraps>

80107625 <vector39>:
.globl vector39
vector39:
  pushl $0
80107625:	6a 00                	push   $0x0
  pushl $39
80107627:	6a 27                	push   $0x27
  jmp alltraps
80107629:	e9 16 f8 ff ff       	jmp    80106e44 <alltraps>

8010762e <vector40>:
.globl vector40
vector40:
  pushl $0
8010762e:	6a 00                	push   $0x0
  pushl $40
80107630:	6a 28                	push   $0x28
  jmp alltraps
80107632:	e9 0d f8 ff ff       	jmp    80106e44 <alltraps>

80107637 <vector41>:
.globl vector41
vector41:
  pushl $0
80107637:	6a 00                	push   $0x0
  pushl $41
80107639:	6a 29                	push   $0x29
  jmp alltraps
8010763b:	e9 04 f8 ff ff       	jmp    80106e44 <alltraps>

80107640 <vector42>:
.globl vector42
vector42:
  pushl $0
80107640:	6a 00                	push   $0x0
  pushl $42
80107642:	6a 2a                	push   $0x2a
  jmp alltraps
80107644:	e9 fb f7 ff ff       	jmp    80106e44 <alltraps>

80107649 <vector43>:
.globl vector43
vector43:
  pushl $0
80107649:	6a 00                	push   $0x0
  pushl $43
8010764b:	6a 2b                	push   $0x2b
  jmp alltraps
8010764d:	e9 f2 f7 ff ff       	jmp    80106e44 <alltraps>

80107652 <vector44>:
.globl vector44
vector44:
  pushl $0
80107652:	6a 00                	push   $0x0
  pushl $44
80107654:	6a 2c                	push   $0x2c
  jmp alltraps
80107656:	e9 e9 f7 ff ff       	jmp    80106e44 <alltraps>

8010765b <vector45>:
.globl vector45
vector45:
  pushl $0
8010765b:	6a 00                	push   $0x0
  pushl $45
8010765d:	6a 2d                	push   $0x2d
  jmp alltraps
8010765f:	e9 e0 f7 ff ff       	jmp    80106e44 <alltraps>

80107664 <vector46>:
.globl vector46
vector46:
  pushl $0
80107664:	6a 00                	push   $0x0
  pushl $46
80107666:	6a 2e                	push   $0x2e
  jmp alltraps
80107668:	e9 d7 f7 ff ff       	jmp    80106e44 <alltraps>

8010766d <vector47>:
.globl vector47
vector47:
  pushl $0
8010766d:	6a 00                	push   $0x0
  pushl $47
8010766f:	6a 2f                	push   $0x2f
  jmp alltraps
80107671:	e9 ce f7 ff ff       	jmp    80106e44 <alltraps>

80107676 <vector48>:
.globl vector48
vector48:
  pushl $0
80107676:	6a 00                	push   $0x0
  pushl $48
80107678:	6a 30                	push   $0x30
  jmp alltraps
8010767a:	e9 c5 f7 ff ff       	jmp    80106e44 <alltraps>

8010767f <vector49>:
.globl vector49
vector49:
  pushl $0
8010767f:	6a 00                	push   $0x0
  pushl $49
80107681:	6a 31                	push   $0x31
  jmp alltraps
80107683:	e9 bc f7 ff ff       	jmp    80106e44 <alltraps>

80107688 <vector50>:
.globl vector50
vector50:
  pushl $0
80107688:	6a 00                	push   $0x0
  pushl $50
8010768a:	6a 32                	push   $0x32
  jmp alltraps
8010768c:	e9 b3 f7 ff ff       	jmp    80106e44 <alltraps>

80107691 <vector51>:
.globl vector51
vector51:
  pushl $0
80107691:	6a 00                	push   $0x0
  pushl $51
80107693:	6a 33                	push   $0x33
  jmp alltraps
80107695:	e9 aa f7 ff ff       	jmp    80106e44 <alltraps>

8010769a <vector52>:
.globl vector52
vector52:
  pushl $0
8010769a:	6a 00                	push   $0x0
  pushl $52
8010769c:	6a 34                	push   $0x34
  jmp alltraps
8010769e:	e9 a1 f7 ff ff       	jmp    80106e44 <alltraps>

801076a3 <vector53>:
.globl vector53
vector53:
  pushl $0
801076a3:	6a 00                	push   $0x0
  pushl $53
801076a5:	6a 35                	push   $0x35
  jmp alltraps
801076a7:	e9 98 f7 ff ff       	jmp    80106e44 <alltraps>

801076ac <vector54>:
.globl vector54
vector54:
  pushl $0
801076ac:	6a 00                	push   $0x0
  pushl $54
801076ae:	6a 36                	push   $0x36
  jmp alltraps
801076b0:	e9 8f f7 ff ff       	jmp    80106e44 <alltraps>

801076b5 <vector55>:
.globl vector55
vector55:
  pushl $0
801076b5:	6a 00                	push   $0x0
  pushl $55
801076b7:	6a 37                	push   $0x37
  jmp alltraps
801076b9:	e9 86 f7 ff ff       	jmp    80106e44 <alltraps>

801076be <vector56>:
.globl vector56
vector56:
  pushl $0
801076be:	6a 00                	push   $0x0
  pushl $56
801076c0:	6a 38                	push   $0x38
  jmp alltraps
801076c2:	e9 7d f7 ff ff       	jmp    80106e44 <alltraps>

801076c7 <vector57>:
.globl vector57
vector57:
  pushl $0
801076c7:	6a 00                	push   $0x0
  pushl $57
801076c9:	6a 39                	push   $0x39
  jmp alltraps
801076cb:	e9 74 f7 ff ff       	jmp    80106e44 <alltraps>

801076d0 <vector58>:
.globl vector58
vector58:
  pushl $0
801076d0:	6a 00                	push   $0x0
  pushl $58
801076d2:	6a 3a                	push   $0x3a
  jmp alltraps
801076d4:	e9 6b f7 ff ff       	jmp    80106e44 <alltraps>

801076d9 <vector59>:
.globl vector59
vector59:
  pushl $0
801076d9:	6a 00                	push   $0x0
  pushl $59
801076db:	6a 3b                	push   $0x3b
  jmp alltraps
801076dd:	e9 62 f7 ff ff       	jmp    80106e44 <alltraps>

801076e2 <vector60>:
.globl vector60
vector60:
  pushl $0
801076e2:	6a 00                	push   $0x0
  pushl $60
801076e4:	6a 3c                	push   $0x3c
  jmp alltraps
801076e6:	e9 59 f7 ff ff       	jmp    80106e44 <alltraps>

801076eb <vector61>:
.globl vector61
vector61:
  pushl $0
801076eb:	6a 00                	push   $0x0
  pushl $61
801076ed:	6a 3d                	push   $0x3d
  jmp alltraps
801076ef:	e9 50 f7 ff ff       	jmp    80106e44 <alltraps>

801076f4 <vector62>:
.globl vector62
vector62:
  pushl $0
801076f4:	6a 00                	push   $0x0
  pushl $62
801076f6:	6a 3e                	push   $0x3e
  jmp alltraps
801076f8:	e9 47 f7 ff ff       	jmp    80106e44 <alltraps>

801076fd <vector63>:
.globl vector63
vector63:
  pushl $0
801076fd:	6a 00                	push   $0x0
  pushl $63
801076ff:	6a 3f                	push   $0x3f
  jmp alltraps
80107701:	e9 3e f7 ff ff       	jmp    80106e44 <alltraps>

80107706 <vector64>:
.globl vector64
vector64:
  pushl $0
80107706:	6a 00                	push   $0x0
  pushl $64
80107708:	6a 40                	push   $0x40
  jmp alltraps
8010770a:	e9 35 f7 ff ff       	jmp    80106e44 <alltraps>

8010770f <vector65>:
.globl vector65
vector65:
  pushl $0
8010770f:	6a 00                	push   $0x0
  pushl $65
80107711:	6a 41                	push   $0x41
  jmp alltraps
80107713:	e9 2c f7 ff ff       	jmp    80106e44 <alltraps>

80107718 <vector66>:
.globl vector66
vector66:
  pushl $0
80107718:	6a 00                	push   $0x0
  pushl $66
8010771a:	6a 42                	push   $0x42
  jmp alltraps
8010771c:	e9 23 f7 ff ff       	jmp    80106e44 <alltraps>

80107721 <vector67>:
.globl vector67
vector67:
  pushl $0
80107721:	6a 00                	push   $0x0
  pushl $67
80107723:	6a 43                	push   $0x43
  jmp alltraps
80107725:	e9 1a f7 ff ff       	jmp    80106e44 <alltraps>

8010772a <vector68>:
.globl vector68
vector68:
  pushl $0
8010772a:	6a 00                	push   $0x0
  pushl $68
8010772c:	6a 44                	push   $0x44
  jmp alltraps
8010772e:	e9 11 f7 ff ff       	jmp    80106e44 <alltraps>

80107733 <vector69>:
.globl vector69
vector69:
  pushl $0
80107733:	6a 00                	push   $0x0
  pushl $69
80107735:	6a 45                	push   $0x45
  jmp alltraps
80107737:	e9 08 f7 ff ff       	jmp    80106e44 <alltraps>

8010773c <vector70>:
.globl vector70
vector70:
  pushl $0
8010773c:	6a 00                	push   $0x0
  pushl $70
8010773e:	6a 46                	push   $0x46
  jmp alltraps
80107740:	e9 ff f6 ff ff       	jmp    80106e44 <alltraps>

80107745 <vector71>:
.globl vector71
vector71:
  pushl $0
80107745:	6a 00                	push   $0x0
  pushl $71
80107747:	6a 47                	push   $0x47
  jmp alltraps
80107749:	e9 f6 f6 ff ff       	jmp    80106e44 <alltraps>

8010774e <vector72>:
.globl vector72
vector72:
  pushl $0
8010774e:	6a 00                	push   $0x0
  pushl $72
80107750:	6a 48                	push   $0x48
  jmp alltraps
80107752:	e9 ed f6 ff ff       	jmp    80106e44 <alltraps>

80107757 <vector73>:
.globl vector73
vector73:
  pushl $0
80107757:	6a 00                	push   $0x0
  pushl $73
80107759:	6a 49                	push   $0x49
  jmp alltraps
8010775b:	e9 e4 f6 ff ff       	jmp    80106e44 <alltraps>

80107760 <vector74>:
.globl vector74
vector74:
  pushl $0
80107760:	6a 00                	push   $0x0
  pushl $74
80107762:	6a 4a                	push   $0x4a
  jmp alltraps
80107764:	e9 db f6 ff ff       	jmp    80106e44 <alltraps>

80107769 <vector75>:
.globl vector75
vector75:
  pushl $0
80107769:	6a 00                	push   $0x0
  pushl $75
8010776b:	6a 4b                	push   $0x4b
  jmp alltraps
8010776d:	e9 d2 f6 ff ff       	jmp    80106e44 <alltraps>

80107772 <vector76>:
.globl vector76
vector76:
  pushl $0
80107772:	6a 00                	push   $0x0
  pushl $76
80107774:	6a 4c                	push   $0x4c
  jmp alltraps
80107776:	e9 c9 f6 ff ff       	jmp    80106e44 <alltraps>

8010777b <vector77>:
.globl vector77
vector77:
  pushl $0
8010777b:	6a 00                	push   $0x0
  pushl $77
8010777d:	6a 4d                	push   $0x4d
  jmp alltraps
8010777f:	e9 c0 f6 ff ff       	jmp    80106e44 <alltraps>

80107784 <vector78>:
.globl vector78
vector78:
  pushl $0
80107784:	6a 00                	push   $0x0
  pushl $78
80107786:	6a 4e                	push   $0x4e
  jmp alltraps
80107788:	e9 b7 f6 ff ff       	jmp    80106e44 <alltraps>

8010778d <vector79>:
.globl vector79
vector79:
  pushl $0
8010778d:	6a 00                	push   $0x0
  pushl $79
8010778f:	6a 4f                	push   $0x4f
  jmp alltraps
80107791:	e9 ae f6 ff ff       	jmp    80106e44 <alltraps>

80107796 <vector80>:
.globl vector80
vector80:
  pushl $0
80107796:	6a 00                	push   $0x0
  pushl $80
80107798:	6a 50                	push   $0x50
  jmp alltraps
8010779a:	e9 a5 f6 ff ff       	jmp    80106e44 <alltraps>

8010779f <vector81>:
.globl vector81
vector81:
  pushl $0
8010779f:	6a 00                	push   $0x0
  pushl $81
801077a1:	6a 51                	push   $0x51
  jmp alltraps
801077a3:	e9 9c f6 ff ff       	jmp    80106e44 <alltraps>

801077a8 <vector82>:
.globl vector82
vector82:
  pushl $0
801077a8:	6a 00                	push   $0x0
  pushl $82
801077aa:	6a 52                	push   $0x52
  jmp alltraps
801077ac:	e9 93 f6 ff ff       	jmp    80106e44 <alltraps>

801077b1 <vector83>:
.globl vector83
vector83:
  pushl $0
801077b1:	6a 00                	push   $0x0
  pushl $83
801077b3:	6a 53                	push   $0x53
  jmp alltraps
801077b5:	e9 8a f6 ff ff       	jmp    80106e44 <alltraps>

801077ba <vector84>:
.globl vector84
vector84:
  pushl $0
801077ba:	6a 00                	push   $0x0
  pushl $84
801077bc:	6a 54                	push   $0x54
  jmp alltraps
801077be:	e9 81 f6 ff ff       	jmp    80106e44 <alltraps>

801077c3 <vector85>:
.globl vector85
vector85:
  pushl $0
801077c3:	6a 00                	push   $0x0
  pushl $85
801077c5:	6a 55                	push   $0x55
  jmp alltraps
801077c7:	e9 78 f6 ff ff       	jmp    80106e44 <alltraps>

801077cc <vector86>:
.globl vector86
vector86:
  pushl $0
801077cc:	6a 00                	push   $0x0
  pushl $86
801077ce:	6a 56                	push   $0x56
  jmp alltraps
801077d0:	e9 6f f6 ff ff       	jmp    80106e44 <alltraps>

801077d5 <vector87>:
.globl vector87
vector87:
  pushl $0
801077d5:	6a 00                	push   $0x0
  pushl $87
801077d7:	6a 57                	push   $0x57
  jmp alltraps
801077d9:	e9 66 f6 ff ff       	jmp    80106e44 <alltraps>

801077de <vector88>:
.globl vector88
vector88:
  pushl $0
801077de:	6a 00                	push   $0x0
  pushl $88
801077e0:	6a 58                	push   $0x58
  jmp alltraps
801077e2:	e9 5d f6 ff ff       	jmp    80106e44 <alltraps>

801077e7 <vector89>:
.globl vector89
vector89:
  pushl $0
801077e7:	6a 00                	push   $0x0
  pushl $89
801077e9:	6a 59                	push   $0x59
  jmp alltraps
801077eb:	e9 54 f6 ff ff       	jmp    80106e44 <alltraps>

801077f0 <vector90>:
.globl vector90
vector90:
  pushl $0
801077f0:	6a 00                	push   $0x0
  pushl $90
801077f2:	6a 5a                	push   $0x5a
  jmp alltraps
801077f4:	e9 4b f6 ff ff       	jmp    80106e44 <alltraps>

801077f9 <vector91>:
.globl vector91
vector91:
  pushl $0
801077f9:	6a 00                	push   $0x0
  pushl $91
801077fb:	6a 5b                	push   $0x5b
  jmp alltraps
801077fd:	e9 42 f6 ff ff       	jmp    80106e44 <alltraps>

80107802 <vector92>:
.globl vector92
vector92:
  pushl $0
80107802:	6a 00                	push   $0x0
  pushl $92
80107804:	6a 5c                	push   $0x5c
  jmp alltraps
80107806:	e9 39 f6 ff ff       	jmp    80106e44 <alltraps>

8010780b <vector93>:
.globl vector93
vector93:
  pushl $0
8010780b:	6a 00                	push   $0x0
  pushl $93
8010780d:	6a 5d                	push   $0x5d
  jmp alltraps
8010780f:	e9 30 f6 ff ff       	jmp    80106e44 <alltraps>

80107814 <vector94>:
.globl vector94
vector94:
  pushl $0
80107814:	6a 00                	push   $0x0
  pushl $94
80107816:	6a 5e                	push   $0x5e
  jmp alltraps
80107818:	e9 27 f6 ff ff       	jmp    80106e44 <alltraps>

8010781d <vector95>:
.globl vector95
vector95:
  pushl $0
8010781d:	6a 00                	push   $0x0
  pushl $95
8010781f:	6a 5f                	push   $0x5f
  jmp alltraps
80107821:	e9 1e f6 ff ff       	jmp    80106e44 <alltraps>

80107826 <vector96>:
.globl vector96
vector96:
  pushl $0
80107826:	6a 00                	push   $0x0
  pushl $96
80107828:	6a 60                	push   $0x60
  jmp alltraps
8010782a:	e9 15 f6 ff ff       	jmp    80106e44 <alltraps>

8010782f <vector97>:
.globl vector97
vector97:
  pushl $0
8010782f:	6a 00                	push   $0x0
  pushl $97
80107831:	6a 61                	push   $0x61
  jmp alltraps
80107833:	e9 0c f6 ff ff       	jmp    80106e44 <alltraps>

80107838 <vector98>:
.globl vector98
vector98:
  pushl $0
80107838:	6a 00                	push   $0x0
  pushl $98
8010783a:	6a 62                	push   $0x62
  jmp alltraps
8010783c:	e9 03 f6 ff ff       	jmp    80106e44 <alltraps>

80107841 <vector99>:
.globl vector99
vector99:
  pushl $0
80107841:	6a 00                	push   $0x0
  pushl $99
80107843:	6a 63                	push   $0x63
  jmp alltraps
80107845:	e9 fa f5 ff ff       	jmp    80106e44 <alltraps>

8010784a <vector100>:
.globl vector100
vector100:
  pushl $0
8010784a:	6a 00                	push   $0x0
  pushl $100
8010784c:	6a 64                	push   $0x64
  jmp alltraps
8010784e:	e9 f1 f5 ff ff       	jmp    80106e44 <alltraps>

80107853 <vector101>:
.globl vector101
vector101:
  pushl $0
80107853:	6a 00                	push   $0x0
  pushl $101
80107855:	6a 65                	push   $0x65
  jmp alltraps
80107857:	e9 e8 f5 ff ff       	jmp    80106e44 <alltraps>

8010785c <vector102>:
.globl vector102
vector102:
  pushl $0
8010785c:	6a 00                	push   $0x0
  pushl $102
8010785e:	6a 66                	push   $0x66
  jmp alltraps
80107860:	e9 df f5 ff ff       	jmp    80106e44 <alltraps>

80107865 <vector103>:
.globl vector103
vector103:
  pushl $0
80107865:	6a 00                	push   $0x0
  pushl $103
80107867:	6a 67                	push   $0x67
  jmp alltraps
80107869:	e9 d6 f5 ff ff       	jmp    80106e44 <alltraps>

8010786e <vector104>:
.globl vector104
vector104:
  pushl $0
8010786e:	6a 00                	push   $0x0
  pushl $104
80107870:	6a 68                	push   $0x68
  jmp alltraps
80107872:	e9 cd f5 ff ff       	jmp    80106e44 <alltraps>

80107877 <vector105>:
.globl vector105
vector105:
  pushl $0
80107877:	6a 00                	push   $0x0
  pushl $105
80107879:	6a 69                	push   $0x69
  jmp alltraps
8010787b:	e9 c4 f5 ff ff       	jmp    80106e44 <alltraps>

80107880 <vector106>:
.globl vector106
vector106:
  pushl $0
80107880:	6a 00                	push   $0x0
  pushl $106
80107882:	6a 6a                	push   $0x6a
  jmp alltraps
80107884:	e9 bb f5 ff ff       	jmp    80106e44 <alltraps>

80107889 <vector107>:
.globl vector107
vector107:
  pushl $0
80107889:	6a 00                	push   $0x0
  pushl $107
8010788b:	6a 6b                	push   $0x6b
  jmp alltraps
8010788d:	e9 b2 f5 ff ff       	jmp    80106e44 <alltraps>

80107892 <vector108>:
.globl vector108
vector108:
  pushl $0
80107892:	6a 00                	push   $0x0
  pushl $108
80107894:	6a 6c                	push   $0x6c
  jmp alltraps
80107896:	e9 a9 f5 ff ff       	jmp    80106e44 <alltraps>

8010789b <vector109>:
.globl vector109
vector109:
  pushl $0
8010789b:	6a 00                	push   $0x0
  pushl $109
8010789d:	6a 6d                	push   $0x6d
  jmp alltraps
8010789f:	e9 a0 f5 ff ff       	jmp    80106e44 <alltraps>

801078a4 <vector110>:
.globl vector110
vector110:
  pushl $0
801078a4:	6a 00                	push   $0x0
  pushl $110
801078a6:	6a 6e                	push   $0x6e
  jmp alltraps
801078a8:	e9 97 f5 ff ff       	jmp    80106e44 <alltraps>

801078ad <vector111>:
.globl vector111
vector111:
  pushl $0
801078ad:	6a 00                	push   $0x0
  pushl $111
801078af:	6a 6f                	push   $0x6f
  jmp alltraps
801078b1:	e9 8e f5 ff ff       	jmp    80106e44 <alltraps>

801078b6 <vector112>:
.globl vector112
vector112:
  pushl $0
801078b6:	6a 00                	push   $0x0
  pushl $112
801078b8:	6a 70                	push   $0x70
  jmp alltraps
801078ba:	e9 85 f5 ff ff       	jmp    80106e44 <alltraps>

801078bf <vector113>:
.globl vector113
vector113:
  pushl $0
801078bf:	6a 00                	push   $0x0
  pushl $113
801078c1:	6a 71                	push   $0x71
  jmp alltraps
801078c3:	e9 7c f5 ff ff       	jmp    80106e44 <alltraps>

801078c8 <vector114>:
.globl vector114
vector114:
  pushl $0
801078c8:	6a 00                	push   $0x0
  pushl $114
801078ca:	6a 72                	push   $0x72
  jmp alltraps
801078cc:	e9 73 f5 ff ff       	jmp    80106e44 <alltraps>

801078d1 <vector115>:
.globl vector115
vector115:
  pushl $0
801078d1:	6a 00                	push   $0x0
  pushl $115
801078d3:	6a 73                	push   $0x73
  jmp alltraps
801078d5:	e9 6a f5 ff ff       	jmp    80106e44 <alltraps>

801078da <vector116>:
.globl vector116
vector116:
  pushl $0
801078da:	6a 00                	push   $0x0
  pushl $116
801078dc:	6a 74                	push   $0x74
  jmp alltraps
801078de:	e9 61 f5 ff ff       	jmp    80106e44 <alltraps>

801078e3 <vector117>:
.globl vector117
vector117:
  pushl $0
801078e3:	6a 00                	push   $0x0
  pushl $117
801078e5:	6a 75                	push   $0x75
  jmp alltraps
801078e7:	e9 58 f5 ff ff       	jmp    80106e44 <alltraps>

801078ec <vector118>:
.globl vector118
vector118:
  pushl $0
801078ec:	6a 00                	push   $0x0
  pushl $118
801078ee:	6a 76                	push   $0x76
  jmp alltraps
801078f0:	e9 4f f5 ff ff       	jmp    80106e44 <alltraps>

801078f5 <vector119>:
.globl vector119
vector119:
  pushl $0
801078f5:	6a 00                	push   $0x0
  pushl $119
801078f7:	6a 77                	push   $0x77
  jmp alltraps
801078f9:	e9 46 f5 ff ff       	jmp    80106e44 <alltraps>

801078fe <vector120>:
.globl vector120
vector120:
  pushl $0
801078fe:	6a 00                	push   $0x0
  pushl $120
80107900:	6a 78                	push   $0x78
  jmp alltraps
80107902:	e9 3d f5 ff ff       	jmp    80106e44 <alltraps>

80107907 <vector121>:
.globl vector121
vector121:
  pushl $0
80107907:	6a 00                	push   $0x0
  pushl $121
80107909:	6a 79                	push   $0x79
  jmp alltraps
8010790b:	e9 34 f5 ff ff       	jmp    80106e44 <alltraps>

80107910 <vector122>:
.globl vector122
vector122:
  pushl $0
80107910:	6a 00                	push   $0x0
  pushl $122
80107912:	6a 7a                	push   $0x7a
  jmp alltraps
80107914:	e9 2b f5 ff ff       	jmp    80106e44 <alltraps>

80107919 <vector123>:
.globl vector123
vector123:
  pushl $0
80107919:	6a 00                	push   $0x0
  pushl $123
8010791b:	6a 7b                	push   $0x7b
  jmp alltraps
8010791d:	e9 22 f5 ff ff       	jmp    80106e44 <alltraps>

80107922 <vector124>:
.globl vector124
vector124:
  pushl $0
80107922:	6a 00                	push   $0x0
  pushl $124
80107924:	6a 7c                	push   $0x7c
  jmp alltraps
80107926:	e9 19 f5 ff ff       	jmp    80106e44 <alltraps>

8010792b <vector125>:
.globl vector125
vector125:
  pushl $0
8010792b:	6a 00                	push   $0x0
  pushl $125
8010792d:	6a 7d                	push   $0x7d
  jmp alltraps
8010792f:	e9 10 f5 ff ff       	jmp    80106e44 <alltraps>

80107934 <vector126>:
.globl vector126
vector126:
  pushl $0
80107934:	6a 00                	push   $0x0
  pushl $126
80107936:	6a 7e                	push   $0x7e
  jmp alltraps
80107938:	e9 07 f5 ff ff       	jmp    80106e44 <alltraps>

8010793d <vector127>:
.globl vector127
vector127:
  pushl $0
8010793d:	6a 00                	push   $0x0
  pushl $127
8010793f:	6a 7f                	push   $0x7f
  jmp alltraps
80107941:	e9 fe f4 ff ff       	jmp    80106e44 <alltraps>

80107946 <vector128>:
.globl vector128
vector128:
  pushl $0
80107946:	6a 00                	push   $0x0
  pushl $128
80107948:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010794d:	e9 f2 f4 ff ff       	jmp    80106e44 <alltraps>

80107952 <vector129>:
.globl vector129
vector129:
  pushl $0
80107952:	6a 00                	push   $0x0
  pushl $129
80107954:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107959:	e9 e6 f4 ff ff       	jmp    80106e44 <alltraps>

8010795e <vector130>:
.globl vector130
vector130:
  pushl $0
8010795e:	6a 00                	push   $0x0
  pushl $130
80107960:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107965:	e9 da f4 ff ff       	jmp    80106e44 <alltraps>

8010796a <vector131>:
.globl vector131
vector131:
  pushl $0
8010796a:	6a 00                	push   $0x0
  pushl $131
8010796c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107971:	e9 ce f4 ff ff       	jmp    80106e44 <alltraps>

80107976 <vector132>:
.globl vector132
vector132:
  pushl $0
80107976:	6a 00                	push   $0x0
  pushl $132
80107978:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010797d:	e9 c2 f4 ff ff       	jmp    80106e44 <alltraps>

80107982 <vector133>:
.globl vector133
vector133:
  pushl $0
80107982:	6a 00                	push   $0x0
  pushl $133
80107984:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107989:	e9 b6 f4 ff ff       	jmp    80106e44 <alltraps>

8010798e <vector134>:
.globl vector134
vector134:
  pushl $0
8010798e:	6a 00                	push   $0x0
  pushl $134
80107990:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107995:	e9 aa f4 ff ff       	jmp    80106e44 <alltraps>

8010799a <vector135>:
.globl vector135
vector135:
  pushl $0
8010799a:	6a 00                	push   $0x0
  pushl $135
8010799c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801079a1:	e9 9e f4 ff ff       	jmp    80106e44 <alltraps>

801079a6 <vector136>:
.globl vector136
vector136:
  pushl $0
801079a6:	6a 00                	push   $0x0
  pushl $136
801079a8:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801079ad:	e9 92 f4 ff ff       	jmp    80106e44 <alltraps>

801079b2 <vector137>:
.globl vector137
vector137:
  pushl $0
801079b2:	6a 00                	push   $0x0
  pushl $137
801079b4:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801079b9:	e9 86 f4 ff ff       	jmp    80106e44 <alltraps>

801079be <vector138>:
.globl vector138
vector138:
  pushl $0
801079be:	6a 00                	push   $0x0
  pushl $138
801079c0:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801079c5:	e9 7a f4 ff ff       	jmp    80106e44 <alltraps>

801079ca <vector139>:
.globl vector139
vector139:
  pushl $0
801079ca:	6a 00                	push   $0x0
  pushl $139
801079cc:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801079d1:	e9 6e f4 ff ff       	jmp    80106e44 <alltraps>

801079d6 <vector140>:
.globl vector140
vector140:
  pushl $0
801079d6:	6a 00                	push   $0x0
  pushl $140
801079d8:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801079dd:	e9 62 f4 ff ff       	jmp    80106e44 <alltraps>

801079e2 <vector141>:
.globl vector141
vector141:
  pushl $0
801079e2:	6a 00                	push   $0x0
  pushl $141
801079e4:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801079e9:	e9 56 f4 ff ff       	jmp    80106e44 <alltraps>

801079ee <vector142>:
.globl vector142
vector142:
  pushl $0
801079ee:	6a 00                	push   $0x0
  pushl $142
801079f0:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801079f5:	e9 4a f4 ff ff       	jmp    80106e44 <alltraps>

801079fa <vector143>:
.globl vector143
vector143:
  pushl $0
801079fa:	6a 00                	push   $0x0
  pushl $143
801079fc:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107a01:	e9 3e f4 ff ff       	jmp    80106e44 <alltraps>

80107a06 <vector144>:
.globl vector144
vector144:
  pushl $0
80107a06:	6a 00                	push   $0x0
  pushl $144
80107a08:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107a0d:	e9 32 f4 ff ff       	jmp    80106e44 <alltraps>

80107a12 <vector145>:
.globl vector145
vector145:
  pushl $0
80107a12:	6a 00                	push   $0x0
  pushl $145
80107a14:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107a19:	e9 26 f4 ff ff       	jmp    80106e44 <alltraps>

80107a1e <vector146>:
.globl vector146
vector146:
  pushl $0
80107a1e:	6a 00                	push   $0x0
  pushl $146
80107a20:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107a25:	e9 1a f4 ff ff       	jmp    80106e44 <alltraps>

80107a2a <vector147>:
.globl vector147
vector147:
  pushl $0
80107a2a:	6a 00                	push   $0x0
  pushl $147
80107a2c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107a31:	e9 0e f4 ff ff       	jmp    80106e44 <alltraps>

80107a36 <vector148>:
.globl vector148
vector148:
  pushl $0
80107a36:	6a 00                	push   $0x0
  pushl $148
80107a38:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107a3d:	e9 02 f4 ff ff       	jmp    80106e44 <alltraps>

80107a42 <vector149>:
.globl vector149
vector149:
  pushl $0
80107a42:	6a 00                	push   $0x0
  pushl $149
80107a44:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107a49:	e9 f6 f3 ff ff       	jmp    80106e44 <alltraps>

80107a4e <vector150>:
.globl vector150
vector150:
  pushl $0
80107a4e:	6a 00                	push   $0x0
  pushl $150
80107a50:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107a55:	e9 ea f3 ff ff       	jmp    80106e44 <alltraps>

80107a5a <vector151>:
.globl vector151
vector151:
  pushl $0
80107a5a:	6a 00                	push   $0x0
  pushl $151
80107a5c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107a61:	e9 de f3 ff ff       	jmp    80106e44 <alltraps>

80107a66 <vector152>:
.globl vector152
vector152:
  pushl $0
80107a66:	6a 00                	push   $0x0
  pushl $152
80107a68:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107a6d:	e9 d2 f3 ff ff       	jmp    80106e44 <alltraps>

80107a72 <vector153>:
.globl vector153
vector153:
  pushl $0
80107a72:	6a 00                	push   $0x0
  pushl $153
80107a74:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107a79:	e9 c6 f3 ff ff       	jmp    80106e44 <alltraps>

80107a7e <vector154>:
.globl vector154
vector154:
  pushl $0
80107a7e:	6a 00                	push   $0x0
  pushl $154
80107a80:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107a85:	e9 ba f3 ff ff       	jmp    80106e44 <alltraps>

80107a8a <vector155>:
.globl vector155
vector155:
  pushl $0
80107a8a:	6a 00                	push   $0x0
  pushl $155
80107a8c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107a91:	e9 ae f3 ff ff       	jmp    80106e44 <alltraps>

80107a96 <vector156>:
.globl vector156
vector156:
  pushl $0
80107a96:	6a 00                	push   $0x0
  pushl $156
80107a98:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107a9d:	e9 a2 f3 ff ff       	jmp    80106e44 <alltraps>

80107aa2 <vector157>:
.globl vector157
vector157:
  pushl $0
80107aa2:	6a 00                	push   $0x0
  pushl $157
80107aa4:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107aa9:	e9 96 f3 ff ff       	jmp    80106e44 <alltraps>

80107aae <vector158>:
.globl vector158
vector158:
  pushl $0
80107aae:	6a 00                	push   $0x0
  pushl $158
80107ab0:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107ab5:	e9 8a f3 ff ff       	jmp    80106e44 <alltraps>

80107aba <vector159>:
.globl vector159
vector159:
  pushl $0
80107aba:	6a 00                	push   $0x0
  pushl $159
80107abc:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107ac1:	e9 7e f3 ff ff       	jmp    80106e44 <alltraps>

80107ac6 <vector160>:
.globl vector160
vector160:
  pushl $0
80107ac6:	6a 00                	push   $0x0
  pushl $160
80107ac8:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107acd:	e9 72 f3 ff ff       	jmp    80106e44 <alltraps>

80107ad2 <vector161>:
.globl vector161
vector161:
  pushl $0
80107ad2:	6a 00                	push   $0x0
  pushl $161
80107ad4:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107ad9:	e9 66 f3 ff ff       	jmp    80106e44 <alltraps>

80107ade <vector162>:
.globl vector162
vector162:
  pushl $0
80107ade:	6a 00                	push   $0x0
  pushl $162
80107ae0:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107ae5:	e9 5a f3 ff ff       	jmp    80106e44 <alltraps>

80107aea <vector163>:
.globl vector163
vector163:
  pushl $0
80107aea:	6a 00                	push   $0x0
  pushl $163
80107aec:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107af1:	e9 4e f3 ff ff       	jmp    80106e44 <alltraps>

80107af6 <vector164>:
.globl vector164
vector164:
  pushl $0
80107af6:	6a 00                	push   $0x0
  pushl $164
80107af8:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107afd:	e9 42 f3 ff ff       	jmp    80106e44 <alltraps>

80107b02 <vector165>:
.globl vector165
vector165:
  pushl $0
80107b02:	6a 00                	push   $0x0
  pushl $165
80107b04:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107b09:	e9 36 f3 ff ff       	jmp    80106e44 <alltraps>

80107b0e <vector166>:
.globl vector166
vector166:
  pushl $0
80107b0e:	6a 00                	push   $0x0
  pushl $166
80107b10:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107b15:	e9 2a f3 ff ff       	jmp    80106e44 <alltraps>

80107b1a <vector167>:
.globl vector167
vector167:
  pushl $0
80107b1a:	6a 00                	push   $0x0
  pushl $167
80107b1c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107b21:	e9 1e f3 ff ff       	jmp    80106e44 <alltraps>

80107b26 <vector168>:
.globl vector168
vector168:
  pushl $0
80107b26:	6a 00                	push   $0x0
  pushl $168
80107b28:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107b2d:	e9 12 f3 ff ff       	jmp    80106e44 <alltraps>

80107b32 <vector169>:
.globl vector169
vector169:
  pushl $0
80107b32:	6a 00                	push   $0x0
  pushl $169
80107b34:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107b39:	e9 06 f3 ff ff       	jmp    80106e44 <alltraps>

80107b3e <vector170>:
.globl vector170
vector170:
  pushl $0
80107b3e:	6a 00                	push   $0x0
  pushl $170
80107b40:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107b45:	e9 fa f2 ff ff       	jmp    80106e44 <alltraps>

80107b4a <vector171>:
.globl vector171
vector171:
  pushl $0
80107b4a:	6a 00                	push   $0x0
  pushl $171
80107b4c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107b51:	e9 ee f2 ff ff       	jmp    80106e44 <alltraps>

80107b56 <vector172>:
.globl vector172
vector172:
  pushl $0
80107b56:	6a 00                	push   $0x0
  pushl $172
80107b58:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107b5d:	e9 e2 f2 ff ff       	jmp    80106e44 <alltraps>

80107b62 <vector173>:
.globl vector173
vector173:
  pushl $0
80107b62:	6a 00                	push   $0x0
  pushl $173
80107b64:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107b69:	e9 d6 f2 ff ff       	jmp    80106e44 <alltraps>

80107b6e <vector174>:
.globl vector174
vector174:
  pushl $0
80107b6e:	6a 00                	push   $0x0
  pushl $174
80107b70:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107b75:	e9 ca f2 ff ff       	jmp    80106e44 <alltraps>

80107b7a <vector175>:
.globl vector175
vector175:
  pushl $0
80107b7a:	6a 00                	push   $0x0
  pushl $175
80107b7c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107b81:	e9 be f2 ff ff       	jmp    80106e44 <alltraps>

80107b86 <vector176>:
.globl vector176
vector176:
  pushl $0
80107b86:	6a 00                	push   $0x0
  pushl $176
80107b88:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107b8d:	e9 b2 f2 ff ff       	jmp    80106e44 <alltraps>

80107b92 <vector177>:
.globl vector177
vector177:
  pushl $0
80107b92:	6a 00                	push   $0x0
  pushl $177
80107b94:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107b99:	e9 a6 f2 ff ff       	jmp    80106e44 <alltraps>

80107b9e <vector178>:
.globl vector178
vector178:
  pushl $0
80107b9e:	6a 00                	push   $0x0
  pushl $178
80107ba0:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107ba5:	e9 9a f2 ff ff       	jmp    80106e44 <alltraps>

80107baa <vector179>:
.globl vector179
vector179:
  pushl $0
80107baa:	6a 00                	push   $0x0
  pushl $179
80107bac:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107bb1:	e9 8e f2 ff ff       	jmp    80106e44 <alltraps>

80107bb6 <vector180>:
.globl vector180
vector180:
  pushl $0
80107bb6:	6a 00                	push   $0x0
  pushl $180
80107bb8:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107bbd:	e9 82 f2 ff ff       	jmp    80106e44 <alltraps>

80107bc2 <vector181>:
.globl vector181
vector181:
  pushl $0
80107bc2:	6a 00                	push   $0x0
  pushl $181
80107bc4:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107bc9:	e9 76 f2 ff ff       	jmp    80106e44 <alltraps>

80107bce <vector182>:
.globl vector182
vector182:
  pushl $0
80107bce:	6a 00                	push   $0x0
  pushl $182
80107bd0:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107bd5:	e9 6a f2 ff ff       	jmp    80106e44 <alltraps>

80107bda <vector183>:
.globl vector183
vector183:
  pushl $0
80107bda:	6a 00                	push   $0x0
  pushl $183
80107bdc:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107be1:	e9 5e f2 ff ff       	jmp    80106e44 <alltraps>

80107be6 <vector184>:
.globl vector184
vector184:
  pushl $0
80107be6:	6a 00                	push   $0x0
  pushl $184
80107be8:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107bed:	e9 52 f2 ff ff       	jmp    80106e44 <alltraps>

80107bf2 <vector185>:
.globl vector185
vector185:
  pushl $0
80107bf2:	6a 00                	push   $0x0
  pushl $185
80107bf4:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107bf9:	e9 46 f2 ff ff       	jmp    80106e44 <alltraps>

80107bfe <vector186>:
.globl vector186
vector186:
  pushl $0
80107bfe:	6a 00                	push   $0x0
  pushl $186
80107c00:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107c05:	e9 3a f2 ff ff       	jmp    80106e44 <alltraps>

80107c0a <vector187>:
.globl vector187
vector187:
  pushl $0
80107c0a:	6a 00                	push   $0x0
  pushl $187
80107c0c:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107c11:	e9 2e f2 ff ff       	jmp    80106e44 <alltraps>

80107c16 <vector188>:
.globl vector188
vector188:
  pushl $0
80107c16:	6a 00                	push   $0x0
  pushl $188
80107c18:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107c1d:	e9 22 f2 ff ff       	jmp    80106e44 <alltraps>

80107c22 <vector189>:
.globl vector189
vector189:
  pushl $0
80107c22:	6a 00                	push   $0x0
  pushl $189
80107c24:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107c29:	e9 16 f2 ff ff       	jmp    80106e44 <alltraps>

80107c2e <vector190>:
.globl vector190
vector190:
  pushl $0
80107c2e:	6a 00                	push   $0x0
  pushl $190
80107c30:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107c35:	e9 0a f2 ff ff       	jmp    80106e44 <alltraps>

80107c3a <vector191>:
.globl vector191
vector191:
  pushl $0
80107c3a:	6a 00                	push   $0x0
  pushl $191
80107c3c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107c41:	e9 fe f1 ff ff       	jmp    80106e44 <alltraps>

80107c46 <vector192>:
.globl vector192
vector192:
  pushl $0
80107c46:	6a 00                	push   $0x0
  pushl $192
80107c48:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107c4d:	e9 f2 f1 ff ff       	jmp    80106e44 <alltraps>

80107c52 <vector193>:
.globl vector193
vector193:
  pushl $0
80107c52:	6a 00                	push   $0x0
  pushl $193
80107c54:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107c59:	e9 e6 f1 ff ff       	jmp    80106e44 <alltraps>

80107c5e <vector194>:
.globl vector194
vector194:
  pushl $0
80107c5e:	6a 00                	push   $0x0
  pushl $194
80107c60:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107c65:	e9 da f1 ff ff       	jmp    80106e44 <alltraps>

80107c6a <vector195>:
.globl vector195
vector195:
  pushl $0
80107c6a:	6a 00                	push   $0x0
  pushl $195
80107c6c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107c71:	e9 ce f1 ff ff       	jmp    80106e44 <alltraps>

80107c76 <vector196>:
.globl vector196
vector196:
  pushl $0
80107c76:	6a 00                	push   $0x0
  pushl $196
80107c78:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107c7d:	e9 c2 f1 ff ff       	jmp    80106e44 <alltraps>

80107c82 <vector197>:
.globl vector197
vector197:
  pushl $0
80107c82:	6a 00                	push   $0x0
  pushl $197
80107c84:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107c89:	e9 b6 f1 ff ff       	jmp    80106e44 <alltraps>

80107c8e <vector198>:
.globl vector198
vector198:
  pushl $0
80107c8e:	6a 00                	push   $0x0
  pushl $198
80107c90:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107c95:	e9 aa f1 ff ff       	jmp    80106e44 <alltraps>

80107c9a <vector199>:
.globl vector199
vector199:
  pushl $0
80107c9a:	6a 00                	push   $0x0
  pushl $199
80107c9c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107ca1:	e9 9e f1 ff ff       	jmp    80106e44 <alltraps>

80107ca6 <vector200>:
.globl vector200
vector200:
  pushl $0
80107ca6:	6a 00                	push   $0x0
  pushl $200
80107ca8:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107cad:	e9 92 f1 ff ff       	jmp    80106e44 <alltraps>

80107cb2 <vector201>:
.globl vector201
vector201:
  pushl $0
80107cb2:	6a 00                	push   $0x0
  pushl $201
80107cb4:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107cb9:	e9 86 f1 ff ff       	jmp    80106e44 <alltraps>

80107cbe <vector202>:
.globl vector202
vector202:
  pushl $0
80107cbe:	6a 00                	push   $0x0
  pushl $202
80107cc0:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107cc5:	e9 7a f1 ff ff       	jmp    80106e44 <alltraps>

80107cca <vector203>:
.globl vector203
vector203:
  pushl $0
80107cca:	6a 00                	push   $0x0
  pushl $203
80107ccc:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107cd1:	e9 6e f1 ff ff       	jmp    80106e44 <alltraps>

80107cd6 <vector204>:
.globl vector204
vector204:
  pushl $0
80107cd6:	6a 00                	push   $0x0
  pushl $204
80107cd8:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107cdd:	e9 62 f1 ff ff       	jmp    80106e44 <alltraps>

80107ce2 <vector205>:
.globl vector205
vector205:
  pushl $0
80107ce2:	6a 00                	push   $0x0
  pushl $205
80107ce4:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107ce9:	e9 56 f1 ff ff       	jmp    80106e44 <alltraps>

80107cee <vector206>:
.globl vector206
vector206:
  pushl $0
80107cee:	6a 00                	push   $0x0
  pushl $206
80107cf0:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107cf5:	e9 4a f1 ff ff       	jmp    80106e44 <alltraps>

80107cfa <vector207>:
.globl vector207
vector207:
  pushl $0
80107cfa:	6a 00                	push   $0x0
  pushl $207
80107cfc:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107d01:	e9 3e f1 ff ff       	jmp    80106e44 <alltraps>

80107d06 <vector208>:
.globl vector208
vector208:
  pushl $0
80107d06:	6a 00                	push   $0x0
  pushl $208
80107d08:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107d0d:	e9 32 f1 ff ff       	jmp    80106e44 <alltraps>

80107d12 <vector209>:
.globl vector209
vector209:
  pushl $0
80107d12:	6a 00                	push   $0x0
  pushl $209
80107d14:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107d19:	e9 26 f1 ff ff       	jmp    80106e44 <alltraps>

80107d1e <vector210>:
.globl vector210
vector210:
  pushl $0
80107d1e:	6a 00                	push   $0x0
  pushl $210
80107d20:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107d25:	e9 1a f1 ff ff       	jmp    80106e44 <alltraps>

80107d2a <vector211>:
.globl vector211
vector211:
  pushl $0
80107d2a:	6a 00                	push   $0x0
  pushl $211
80107d2c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107d31:	e9 0e f1 ff ff       	jmp    80106e44 <alltraps>

80107d36 <vector212>:
.globl vector212
vector212:
  pushl $0
80107d36:	6a 00                	push   $0x0
  pushl $212
80107d38:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107d3d:	e9 02 f1 ff ff       	jmp    80106e44 <alltraps>

80107d42 <vector213>:
.globl vector213
vector213:
  pushl $0
80107d42:	6a 00                	push   $0x0
  pushl $213
80107d44:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107d49:	e9 f6 f0 ff ff       	jmp    80106e44 <alltraps>

80107d4e <vector214>:
.globl vector214
vector214:
  pushl $0
80107d4e:	6a 00                	push   $0x0
  pushl $214
80107d50:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107d55:	e9 ea f0 ff ff       	jmp    80106e44 <alltraps>

80107d5a <vector215>:
.globl vector215
vector215:
  pushl $0
80107d5a:	6a 00                	push   $0x0
  pushl $215
80107d5c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107d61:	e9 de f0 ff ff       	jmp    80106e44 <alltraps>

80107d66 <vector216>:
.globl vector216
vector216:
  pushl $0
80107d66:	6a 00                	push   $0x0
  pushl $216
80107d68:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107d6d:	e9 d2 f0 ff ff       	jmp    80106e44 <alltraps>

80107d72 <vector217>:
.globl vector217
vector217:
  pushl $0
80107d72:	6a 00                	push   $0x0
  pushl $217
80107d74:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107d79:	e9 c6 f0 ff ff       	jmp    80106e44 <alltraps>

80107d7e <vector218>:
.globl vector218
vector218:
  pushl $0
80107d7e:	6a 00                	push   $0x0
  pushl $218
80107d80:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107d85:	e9 ba f0 ff ff       	jmp    80106e44 <alltraps>

80107d8a <vector219>:
.globl vector219
vector219:
  pushl $0
80107d8a:	6a 00                	push   $0x0
  pushl $219
80107d8c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107d91:	e9 ae f0 ff ff       	jmp    80106e44 <alltraps>

80107d96 <vector220>:
.globl vector220
vector220:
  pushl $0
80107d96:	6a 00                	push   $0x0
  pushl $220
80107d98:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107d9d:	e9 a2 f0 ff ff       	jmp    80106e44 <alltraps>

80107da2 <vector221>:
.globl vector221
vector221:
  pushl $0
80107da2:	6a 00                	push   $0x0
  pushl $221
80107da4:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107da9:	e9 96 f0 ff ff       	jmp    80106e44 <alltraps>

80107dae <vector222>:
.globl vector222
vector222:
  pushl $0
80107dae:	6a 00                	push   $0x0
  pushl $222
80107db0:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107db5:	e9 8a f0 ff ff       	jmp    80106e44 <alltraps>

80107dba <vector223>:
.globl vector223
vector223:
  pushl $0
80107dba:	6a 00                	push   $0x0
  pushl $223
80107dbc:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107dc1:	e9 7e f0 ff ff       	jmp    80106e44 <alltraps>

80107dc6 <vector224>:
.globl vector224
vector224:
  pushl $0
80107dc6:	6a 00                	push   $0x0
  pushl $224
80107dc8:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107dcd:	e9 72 f0 ff ff       	jmp    80106e44 <alltraps>

80107dd2 <vector225>:
.globl vector225
vector225:
  pushl $0
80107dd2:	6a 00                	push   $0x0
  pushl $225
80107dd4:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107dd9:	e9 66 f0 ff ff       	jmp    80106e44 <alltraps>

80107dde <vector226>:
.globl vector226
vector226:
  pushl $0
80107dde:	6a 00                	push   $0x0
  pushl $226
80107de0:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107de5:	e9 5a f0 ff ff       	jmp    80106e44 <alltraps>

80107dea <vector227>:
.globl vector227
vector227:
  pushl $0
80107dea:	6a 00                	push   $0x0
  pushl $227
80107dec:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107df1:	e9 4e f0 ff ff       	jmp    80106e44 <alltraps>

80107df6 <vector228>:
.globl vector228
vector228:
  pushl $0
80107df6:	6a 00                	push   $0x0
  pushl $228
80107df8:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107dfd:	e9 42 f0 ff ff       	jmp    80106e44 <alltraps>

80107e02 <vector229>:
.globl vector229
vector229:
  pushl $0
80107e02:	6a 00                	push   $0x0
  pushl $229
80107e04:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107e09:	e9 36 f0 ff ff       	jmp    80106e44 <alltraps>

80107e0e <vector230>:
.globl vector230
vector230:
  pushl $0
80107e0e:	6a 00                	push   $0x0
  pushl $230
80107e10:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107e15:	e9 2a f0 ff ff       	jmp    80106e44 <alltraps>

80107e1a <vector231>:
.globl vector231
vector231:
  pushl $0
80107e1a:	6a 00                	push   $0x0
  pushl $231
80107e1c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107e21:	e9 1e f0 ff ff       	jmp    80106e44 <alltraps>

80107e26 <vector232>:
.globl vector232
vector232:
  pushl $0
80107e26:	6a 00                	push   $0x0
  pushl $232
80107e28:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107e2d:	e9 12 f0 ff ff       	jmp    80106e44 <alltraps>

80107e32 <vector233>:
.globl vector233
vector233:
  pushl $0
80107e32:	6a 00                	push   $0x0
  pushl $233
80107e34:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107e39:	e9 06 f0 ff ff       	jmp    80106e44 <alltraps>

80107e3e <vector234>:
.globl vector234
vector234:
  pushl $0
80107e3e:	6a 00                	push   $0x0
  pushl $234
80107e40:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107e45:	e9 fa ef ff ff       	jmp    80106e44 <alltraps>

80107e4a <vector235>:
.globl vector235
vector235:
  pushl $0
80107e4a:	6a 00                	push   $0x0
  pushl $235
80107e4c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107e51:	e9 ee ef ff ff       	jmp    80106e44 <alltraps>

80107e56 <vector236>:
.globl vector236
vector236:
  pushl $0
80107e56:	6a 00                	push   $0x0
  pushl $236
80107e58:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107e5d:	e9 e2 ef ff ff       	jmp    80106e44 <alltraps>

80107e62 <vector237>:
.globl vector237
vector237:
  pushl $0
80107e62:	6a 00                	push   $0x0
  pushl $237
80107e64:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107e69:	e9 d6 ef ff ff       	jmp    80106e44 <alltraps>

80107e6e <vector238>:
.globl vector238
vector238:
  pushl $0
80107e6e:	6a 00                	push   $0x0
  pushl $238
80107e70:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107e75:	e9 ca ef ff ff       	jmp    80106e44 <alltraps>

80107e7a <vector239>:
.globl vector239
vector239:
  pushl $0
80107e7a:	6a 00                	push   $0x0
  pushl $239
80107e7c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107e81:	e9 be ef ff ff       	jmp    80106e44 <alltraps>

80107e86 <vector240>:
.globl vector240
vector240:
  pushl $0
80107e86:	6a 00                	push   $0x0
  pushl $240
80107e88:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107e8d:	e9 b2 ef ff ff       	jmp    80106e44 <alltraps>

80107e92 <vector241>:
.globl vector241
vector241:
  pushl $0
80107e92:	6a 00                	push   $0x0
  pushl $241
80107e94:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107e99:	e9 a6 ef ff ff       	jmp    80106e44 <alltraps>

80107e9e <vector242>:
.globl vector242
vector242:
  pushl $0
80107e9e:	6a 00                	push   $0x0
  pushl $242
80107ea0:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107ea5:	e9 9a ef ff ff       	jmp    80106e44 <alltraps>

80107eaa <vector243>:
.globl vector243
vector243:
  pushl $0
80107eaa:	6a 00                	push   $0x0
  pushl $243
80107eac:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107eb1:	e9 8e ef ff ff       	jmp    80106e44 <alltraps>

80107eb6 <vector244>:
.globl vector244
vector244:
  pushl $0
80107eb6:	6a 00                	push   $0x0
  pushl $244
80107eb8:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107ebd:	e9 82 ef ff ff       	jmp    80106e44 <alltraps>

80107ec2 <vector245>:
.globl vector245
vector245:
  pushl $0
80107ec2:	6a 00                	push   $0x0
  pushl $245
80107ec4:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107ec9:	e9 76 ef ff ff       	jmp    80106e44 <alltraps>

80107ece <vector246>:
.globl vector246
vector246:
  pushl $0
80107ece:	6a 00                	push   $0x0
  pushl $246
80107ed0:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107ed5:	e9 6a ef ff ff       	jmp    80106e44 <alltraps>

80107eda <vector247>:
.globl vector247
vector247:
  pushl $0
80107eda:	6a 00                	push   $0x0
  pushl $247
80107edc:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107ee1:	e9 5e ef ff ff       	jmp    80106e44 <alltraps>

80107ee6 <vector248>:
.globl vector248
vector248:
  pushl $0
80107ee6:	6a 00                	push   $0x0
  pushl $248
80107ee8:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107eed:	e9 52 ef ff ff       	jmp    80106e44 <alltraps>

80107ef2 <vector249>:
.globl vector249
vector249:
  pushl $0
80107ef2:	6a 00                	push   $0x0
  pushl $249
80107ef4:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107ef9:	e9 46 ef ff ff       	jmp    80106e44 <alltraps>

80107efe <vector250>:
.globl vector250
vector250:
  pushl $0
80107efe:	6a 00                	push   $0x0
  pushl $250
80107f00:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107f05:	e9 3a ef ff ff       	jmp    80106e44 <alltraps>

80107f0a <vector251>:
.globl vector251
vector251:
  pushl $0
80107f0a:	6a 00                	push   $0x0
  pushl $251
80107f0c:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107f11:	e9 2e ef ff ff       	jmp    80106e44 <alltraps>

80107f16 <vector252>:
.globl vector252
vector252:
  pushl $0
80107f16:	6a 00                	push   $0x0
  pushl $252
80107f18:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107f1d:	e9 22 ef ff ff       	jmp    80106e44 <alltraps>

80107f22 <vector253>:
.globl vector253
vector253:
  pushl $0
80107f22:	6a 00                	push   $0x0
  pushl $253
80107f24:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107f29:	e9 16 ef ff ff       	jmp    80106e44 <alltraps>

80107f2e <vector254>:
.globl vector254
vector254:
  pushl $0
80107f2e:	6a 00                	push   $0x0
  pushl $254
80107f30:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107f35:	e9 0a ef ff ff       	jmp    80106e44 <alltraps>

80107f3a <vector255>:
.globl vector255
vector255:
  pushl $0
80107f3a:	6a 00                	push   $0x0
  pushl $255
80107f3c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107f41:	e9 fe ee ff ff       	jmp    80106e44 <alltraps>
	...

80107f48 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107f48:	55                   	push   %ebp
80107f49:	89 e5                	mov    %esp,%ebp
80107f4b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107f4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f51:	83 e8 01             	sub    $0x1,%eax
80107f54:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107f58:	8b 45 08             	mov    0x8(%ebp),%eax
80107f5b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107f5f:	8b 45 08             	mov    0x8(%ebp),%eax
80107f62:	c1 e8 10             	shr    $0x10,%eax
80107f65:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107f69:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107f6c:	0f 01 10             	lgdtl  (%eax)
}
80107f6f:	c9                   	leave  
80107f70:	c3                   	ret    

80107f71 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107f71:	55                   	push   %ebp
80107f72:	89 e5                	mov    %esp,%ebp
80107f74:	83 ec 04             	sub    $0x4,%esp
80107f77:	8b 45 08             	mov    0x8(%ebp),%eax
80107f7a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107f7e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f82:	0f 00 d8             	ltr    %ax
}
80107f85:	c9                   	leave  
80107f86:	c3                   	ret    

80107f87 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107f87:	55                   	push   %ebp
80107f88:	89 e5                	mov    %esp,%ebp
80107f8a:	83 ec 04             	sub    $0x4,%esp
80107f8d:	8b 45 08             	mov    0x8(%ebp),%eax
80107f90:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107f94:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107f98:	8e e8                	mov    %eax,%gs
}
80107f9a:	c9                   	leave  
80107f9b:	c3                   	ret    

80107f9c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107f9c:	55                   	push   %ebp
80107f9d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107f9f:	8b 45 08             	mov    0x8(%ebp),%eax
80107fa2:	0f 22 d8             	mov    %eax,%cr3
}
80107fa5:	5d                   	pop    %ebp
80107fa6:	c3                   	ret    

80107fa7 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107fa7:	55                   	push   %ebp
80107fa8:	89 e5                	mov    %esp,%ebp
80107faa:	8b 45 08             	mov    0x8(%ebp),%eax
80107fad:	05 00 00 00 80       	add    $0x80000000,%eax
80107fb2:	5d                   	pop    %ebp
80107fb3:	c3                   	ret    

80107fb4 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107fb4:	55                   	push   %ebp
80107fb5:	89 e5                	mov    %esp,%ebp
80107fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80107fba:	05 00 00 00 80       	add    $0x80000000,%eax
80107fbf:	5d                   	pop    %ebp
80107fc0:	c3                   	ret    

80107fc1 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107fc1:	55                   	push   %ebp
80107fc2:	89 e5                	mov    %esp,%ebp
80107fc4:	53                   	push   %ebx
80107fc5:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107fc8:	e8 4c b9 ff ff       	call   80103919 <cpunum>
80107fcd:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107fd3:	05 40 09 11 80       	add    $0x80110940,%eax
80107fd8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107fdb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fde:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107fe4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fe7:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107fed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff0:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107ff4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ff7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107ffb:	83 e2 f0             	and    $0xfffffff0,%edx
80107ffe:	83 ca 0a             	or     $0xa,%edx
80108001:	88 50 7d             	mov    %dl,0x7d(%eax)
80108004:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108007:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010800b:	83 ca 10             	or     $0x10,%edx
8010800e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108011:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108014:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108018:	83 e2 9f             	and    $0xffffff9f,%edx
8010801b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010801e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108021:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108025:	83 ca 80             	or     $0xffffff80,%edx
80108028:	88 50 7d             	mov    %dl,0x7d(%eax)
8010802b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108032:	83 ca 0f             	or     $0xf,%edx
80108035:	88 50 7e             	mov    %dl,0x7e(%eax)
80108038:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010803b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010803f:	83 e2 ef             	and    $0xffffffef,%edx
80108042:	88 50 7e             	mov    %dl,0x7e(%eax)
80108045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108048:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010804c:	83 e2 df             	and    $0xffffffdf,%edx
8010804f:	88 50 7e             	mov    %dl,0x7e(%eax)
80108052:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108055:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108059:	83 ca 40             	or     $0x40,%edx
8010805c:	88 50 7e             	mov    %dl,0x7e(%eax)
8010805f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108062:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108066:	83 ca 80             	or     $0xffffff80,%edx
80108069:	88 50 7e             	mov    %dl,0x7e(%eax)
8010806c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108073:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108076:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010807d:	ff ff 
8010807f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108082:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108089:	00 00 
8010808b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010808e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108095:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108098:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010809f:	83 e2 f0             	and    $0xfffffff0,%edx
801080a2:	83 ca 02             	or     $0x2,%edx
801080a5:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ae:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080b5:	83 ca 10             	or     $0x10,%edx
801080b8:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c1:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080c8:	83 e2 9f             	and    $0xffffff9f,%edx
801080cb:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801080db:	83 ca 80             	or     $0xffffff80,%edx
801080de:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801080e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e7:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801080ee:	83 ca 0f             	or     $0xf,%edx
801080f1:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801080f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080fa:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108101:	83 e2 ef             	and    $0xffffffef,%edx
80108104:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010810a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010810d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108114:	83 e2 df             	and    $0xffffffdf,%edx
80108117:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010811d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108120:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108127:	83 ca 40             	or     $0x40,%edx
8010812a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108130:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108133:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010813a:	83 ca 80             	or     $0xffffff80,%edx
8010813d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108146:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010814d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108150:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108157:	ff ff 
80108159:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010815c:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108163:	00 00 
80108165:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108168:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010816f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108172:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108179:	83 e2 f0             	and    $0xfffffff0,%edx
8010817c:	83 ca 0a             	or     $0xa,%edx
8010817f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108188:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010818f:	83 ca 10             	or     $0x10,%edx
80108192:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108198:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081a2:	83 ca 60             	or     $0x60,%edx
801081a5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ae:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801081b5:	83 ca 80             	or     $0xffffff80,%edx
801081b8:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801081be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081c8:	83 ca 0f             	or     $0xf,%edx
801081cb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d4:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081db:	83 e2 ef             	and    $0xffffffef,%edx
801081de:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e7:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801081ee:	83 e2 df             	and    $0xffffffdf,%edx
801081f1:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801081f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081fa:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108201:	83 ca 40             	or     $0x40,%edx
80108204:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010820a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108214:	83 ca 80             	or     $0xffffff80,%edx
80108217:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010821d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108220:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108227:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010822a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108231:	ff ff 
80108233:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108236:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
8010823d:	00 00 
8010823f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108242:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108249:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010824c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108253:	83 e2 f0             	and    $0xfffffff0,%edx
80108256:	83 ca 02             	or     $0x2,%edx
80108259:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010825f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108262:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108269:	83 ca 10             	or     $0x10,%edx
8010826c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108272:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108275:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010827c:	83 ca 60             	or     $0x60,%edx
8010827f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108285:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108288:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010828f:	83 ca 80             	or     $0xffffff80,%edx
80108292:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108298:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010829b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082a2:	83 ca 0f             	or     $0xf,%edx
801082a5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ae:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082b5:	83 e2 ef             	and    $0xffffffef,%edx
801082b8:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c1:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082c8:	83 e2 df             	and    $0xffffffdf,%edx
801082cb:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d4:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082db:	83 ca 40             	or     $0x40,%edx
801082de:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082e7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801082ee:	83 ca 80             	or     $0xffffff80,%edx
801082f1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801082f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082fa:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108304:	05 b4 00 00 00       	add    $0xb4,%eax
80108309:	89 c3                	mov    %eax,%ebx
8010830b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830e:	05 b4 00 00 00       	add    $0xb4,%eax
80108313:	c1 e8 10             	shr    $0x10,%eax
80108316:	89 c1                	mov    %eax,%ecx
80108318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010831b:	05 b4 00 00 00       	add    $0xb4,%eax
80108320:	c1 e8 18             	shr    $0x18,%eax
80108323:	89 c2                	mov    %eax,%edx
80108325:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108328:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010832f:	00 00 
80108331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108334:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010833b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010833e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108344:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108347:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010834e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108351:	83 c9 02             	or     $0x2,%ecx
80108354:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010835a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835d:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108364:	83 c9 10             	or     $0x10,%ecx
80108367:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010836d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108370:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108377:	83 e1 9f             	and    $0xffffff9f,%ecx
8010837a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108380:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108383:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010838a:	83 c9 80             	or     $0xffffff80,%ecx
8010838d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108396:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010839d:	83 e1 f0             	and    $0xfffffff0,%ecx
801083a0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a9:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083b0:	83 e1 ef             	and    $0xffffffef,%ecx
801083b3:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083bc:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083c3:	83 e1 df             	and    $0xffffffdf,%ecx
801083c6:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083cf:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083d6:	83 c9 40             	or     $0x40,%ecx
801083d9:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801083e9:	83 c9 80             	or     $0xffffff80,%ecx
801083ec:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801083f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f5:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801083fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fe:	83 c0 70             	add    $0x70,%eax
80108401:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108408:	00 
80108409:	89 04 24             	mov    %eax,(%esp)
8010840c:	e8 37 fb ff ff       	call   80107f48 <lgdt>
  loadgs(SEG_KCPU << 3);
80108411:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108418:	e8 6a fb ff ff       	call   80107f87 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
8010841d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108420:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108426:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010842d:	00 00 00 00 
}
80108431:	83 c4 24             	add    $0x24,%esp
80108434:	5b                   	pop    %ebx
80108435:	5d                   	pop    %ebp
80108436:	c3                   	ret    

80108437 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108437:	55                   	push   %ebp
80108438:	89 e5                	mov    %esp,%ebp
8010843a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
8010843d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108440:	c1 e8 16             	shr    $0x16,%eax
80108443:	c1 e0 02             	shl    $0x2,%eax
80108446:	03 45 08             	add    0x8(%ebp),%eax
80108449:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
8010844c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010844f:	8b 00                	mov    (%eax),%eax
80108451:	83 e0 01             	and    $0x1,%eax
80108454:	84 c0                	test   %al,%al
80108456:	74 17                	je     8010846f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108458:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010845b:	8b 00                	mov    (%eax),%eax
8010845d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108462:	89 04 24             	mov    %eax,(%esp)
80108465:	e8 4a fb ff ff       	call   80107fb4 <p2v>
8010846a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010846d:	eb 4b                	jmp    801084ba <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010846f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108473:	74 0e                	je     80108483 <walkpgdir+0x4c>
80108475:	e8 11 b1 ff ff       	call   8010358b <kalloc>
8010847a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010847d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108481:	75 07                	jne    8010848a <walkpgdir+0x53>
      return 0;
80108483:	b8 00 00 00 00       	mov    $0x0,%eax
80108488:	eb 41                	jmp    801084cb <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010848a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108491:	00 
80108492:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108499:	00 
8010849a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849d:	89 04 24             	mov    %eax,(%esp)
801084a0:	e8 d9 d3 ff ff       	call   8010587e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801084a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a8:	89 04 24             	mov    %eax,(%esp)
801084ab:	e8 f7 fa ff ff       	call   80107fa7 <v2p>
801084b0:	89 c2                	mov    %eax,%edx
801084b2:	83 ca 07             	or     $0x7,%edx
801084b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084b8:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801084ba:	8b 45 0c             	mov    0xc(%ebp),%eax
801084bd:	c1 e8 0c             	shr    $0xc,%eax
801084c0:	25 ff 03 00 00       	and    $0x3ff,%eax
801084c5:	c1 e0 02             	shl    $0x2,%eax
801084c8:	03 45 f4             	add    -0xc(%ebp),%eax
}
801084cb:	c9                   	leave  
801084cc:	c3                   	ret    

801084cd <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801084cd:	55                   	push   %ebp
801084ce:	89 e5                	mov    %esp,%ebp
801084d0:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801084d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801084d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084db:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801084de:	8b 45 0c             	mov    0xc(%ebp),%eax
801084e1:	03 45 10             	add    0x10(%ebp),%eax
801084e4:	83 e8 01             	sub    $0x1,%eax
801084e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801084ef:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801084f6:	00 
801084f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801084fe:	8b 45 08             	mov    0x8(%ebp),%eax
80108501:	89 04 24             	mov    %eax,(%esp)
80108504:	e8 2e ff ff ff       	call   80108437 <walkpgdir>
80108509:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010850c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108510:	75 07                	jne    80108519 <mappages+0x4c>
      return -1;
80108512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108517:	eb 46                	jmp    8010855f <mappages+0x92>
    if(*pte & PTE_P)
80108519:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010851c:	8b 00                	mov    (%eax),%eax
8010851e:	83 e0 01             	and    $0x1,%eax
80108521:	84 c0                	test   %al,%al
80108523:	74 0c                	je     80108531 <mappages+0x64>
      panic("remap");
80108525:	c7 04 24 ec 93 10 80 	movl   $0x801093ec,(%esp)
8010852c:	e8 0c 80 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108531:	8b 45 18             	mov    0x18(%ebp),%eax
80108534:	0b 45 14             	or     0x14(%ebp),%eax
80108537:	89 c2                	mov    %eax,%edx
80108539:	83 ca 01             	or     $0x1,%edx
8010853c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010853f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108541:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108544:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108547:	74 10                	je     80108559 <mappages+0x8c>
      break;
    a += PGSIZE;
80108549:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108550:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108557:	eb 96                	jmp    801084ef <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108559:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010855a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010855f:	c9                   	leave  
80108560:	c3                   	ret    

80108561 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108561:	55                   	push   %ebp
80108562:	89 e5                	mov    %esp,%ebp
80108564:	53                   	push   %ebx
80108565:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108568:	e8 1e b0 ff ff       	call   8010358b <kalloc>
8010856d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108570:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108574:	75 0a                	jne    80108580 <setupkvm+0x1f>
    return 0;
80108576:	b8 00 00 00 00       	mov    $0x0,%eax
8010857b:	e9 98 00 00 00       	jmp    80108618 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108580:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108587:	00 
80108588:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010858f:	00 
80108590:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108593:	89 04 24             	mov    %eax,(%esp)
80108596:	e8 e3 d2 ff ff       	call   8010587e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
8010859b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801085a2:	e8 0d fa ff ff       	call   80107fb4 <p2v>
801085a7:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801085ac:	76 0c                	jbe    801085ba <setupkvm+0x59>
    panic("PHYSTOP too high");
801085ae:	c7 04 24 f2 93 10 80 	movl   $0x801093f2,(%esp)
801085b5:	e8 83 7f ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801085ba:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
801085c1:	eb 49                	jmp    8010860c <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801085c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801085c6:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801085c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801085cc:	8b 50 04             	mov    0x4(%eax),%edx
801085cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d2:	8b 58 08             	mov    0x8(%eax),%ebx
801085d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d8:	8b 40 04             	mov    0x4(%eax),%eax
801085db:	29 c3                	sub    %eax,%ebx
801085dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e0:	8b 00                	mov    (%eax),%eax
801085e2:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801085e6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801085ea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801085ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801085f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085f5:	89 04 24             	mov    %eax,(%esp)
801085f8:	e8 d0 fe ff ff       	call   801084cd <mappages>
801085fd:	85 c0                	test   %eax,%eax
801085ff:	79 07                	jns    80108608 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108601:	b8 00 00 00 00       	mov    $0x0,%eax
80108606:	eb 10                	jmp    80108618 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108608:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010860c:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108613:	72 ae                	jb     801085c3 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108615:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108618:	83 c4 34             	add    $0x34,%esp
8010861b:	5b                   	pop    %ebx
8010861c:	5d                   	pop    %ebp
8010861d:	c3                   	ret    

8010861e <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
8010861e:	55                   	push   %ebp
8010861f:	89 e5                	mov    %esp,%ebp
80108621:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108624:	e8 38 ff ff ff       	call   80108561 <setupkvm>
80108629:	a3 18 37 11 80       	mov    %eax,0x80113718
  switchkvm();
8010862e:	e8 02 00 00 00       	call   80108635 <switchkvm>
}
80108633:	c9                   	leave  
80108634:	c3                   	ret    

80108635 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108635:	55                   	push   %ebp
80108636:	89 e5                	mov    %esp,%ebp
80108638:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
8010863b:	a1 18 37 11 80       	mov    0x80113718,%eax
80108640:	89 04 24             	mov    %eax,(%esp)
80108643:	e8 5f f9 ff ff       	call   80107fa7 <v2p>
80108648:	89 04 24             	mov    %eax,(%esp)
8010864b:	e8 4c f9 ff ff       	call   80107f9c <lcr3>
}
80108650:	c9                   	leave  
80108651:	c3                   	ret    

80108652 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108652:	55                   	push   %ebp
80108653:	89 e5                	mov    %esp,%ebp
80108655:	53                   	push   %ebx
80108656:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108659:	e8 19 d1 ff ff       	call   80105777 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
8010865e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108664:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010866b:	83 c2 08             	add    $0x8,%edx
8010866e:	89 d3                	mov    %edx,%ebx
80108670:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108677:	83 c2 08             	add    $0x8,%edx
8010867a:	c1 ea 10             	shr    $0x10,%edx
8010867d:	89 d1                	mov    %edx,%ecx
8010867f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108686:	83 c2 08             	add    $0x8,%edx
80108689:	c1 ea 18             	shr    $0x18,%edx
8010868c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108693:	67 00 
80108695:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
8010869c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801086a2:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086a9:	83 e1 f0             	and    $0xfffffff0,%ecx
801086ac:	83 c9 09             	or     $0x9,%ecx
801086af:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086b5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086bc:	83 c9 10             	or     $0x10,%ecx
801086bf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086c5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086cc:	83 e1 9f             	and    $0xffffff9f,%ecx
801086cf:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086d5:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801086dc:	83 c9 80             	or     $0xffffff80,%ecx
801086df:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801086e5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086ec:	83 e1 f0             	and    $0xfffffff0,%ecx
801086ef:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
801086f5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
801086fc:	83 e1 ef             	and    $0xffffffef,%ecx
801086ff:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108705:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010870c:	83 e1 df             	and    $0xffffffdf,%ecx
8010870f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108715:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010871c:	83 c9 40             	or     $0x40,%ecx
8010871f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108725:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
8010872c:	83 e1 7f             	and    $0x7f,%ecx
8010872f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108735:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010873b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108741:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108748:	83 e2 ef             	and    $0xffffffef,%edx
8010874b:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108751:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108757:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
8010875d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108763:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010876a:	8b 52 08             	mov    0x8(%edx),%edx
8010876d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108773:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108776:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
8010877d:	e8 ef f7 ff ff       	call   80107f71 <ltr>
  if(p->pgdir == 0)
80108782:	8b 45 08             	mov    0x8(%ebp),%eax
80108785:	8b 40 04             	mov    0x4(%eax),%eax
80108788:	85 c0                	test   %eax,%eax
8010878a:	75 0c                	jne    80108798 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
8010878c:	c7 04 24 03 94 10 80 	movl   $0x80109403,(%esp)
80108793:	e8 a5 7d ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108798:	8b 45 08             	mov    0x8(%ebp),%eax
8010879b:	8b 40 04             	mov    0x4(%eax),%eax
8010879e:	89 04 24             	mov    %eax,(%esp)
801087a1:	e8 01 f8 ff ff       	call   80107fa7 <v2p>
801087a6:	89 04 24             	mov    %eax,(%esp)
801087a9:	e8 ee f7 ff ff       	call   80107f9c <lcr3>
  popcli();
801087ae:	e8 0c d0 ff ff       	call   801057bf <popcli>
}
801087b3:	83 c4 14             	add    $0x14,%esp
801087b6:	5b                   	pop    %ebx
801087b7:	5d                   	pop    %ebp
801087b8:	c3                   	ret    

801087b9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801087b9:	55                   	push   %ebp
801087ba:	89 e5                	mov    %esp,%ebp
801087bc:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801087bf:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801087c6:	76 0c                	jbe    801087d4 <inituvm+0x1b>
    panic("inituvm: more than a page");
801087c8:	c7 04 24 17 94 10 80 	movl   $0x80109417,(%esp)
801087cf:	e8 69 7d ff ff       	call   8010053d <panic>
  mem = kalloc();
801087d4:	e8 b2 ad ff ff       	call   8010358b <kalloc>
801087d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801087dc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801087e3:	00 
801087e4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801087eb:	00 
801087ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ef:	89 04 24             	mov    %eax,(%esp)
801087f2:	e8 87 d0 ff ff       	call   8010587e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
801087f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087fa:	89 04 24             	mov    %eax,(%esp)
801087fd:	e8 a5 f7 ff ff       	call   80107fa7 <v2p>
80108802:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108809:	00 
8010880a:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010880e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108815:	00 
80108816:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010881d:	00 
8010881e:	8b 45 08             	mov    0x8(%ebp),%eax
80108821:	89 04 24             	mov    %eax,(%esp)
80108824:	e8 a4 fc ff ff       	call   801084cd <mappages>
  memmove(mem, init, sz);
80108829:	8b 45 10             	mov    0x10(%ebp),%eax
8010882c:	89 44 24 08          	mov    %eax,0x8(%esp)
80108830:	8b 45 0c             	mov    0xc(%ebp),%eax
80108833:	89 44 24 04          	mov    %eax,0x4(%esp)
80108837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883a:	89 04 24             	mov    %eax,(%esp)
8010883d:	e8 0f d1 ff ff       	call   80105951 <memmove>
}
80108842:	c9                   	leave  
80108843:	c3                   	ret    

80108844 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108844:	55                   	push   %ebp
80108845:	89 e5                	mov    %esp,%ebp
80108847:	53                   	push   %ebx
80108848:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010884b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010884e:	25 ff 0f 00 00       	and    $0xfff,%eax
80108853:	85 c0                	test   %eax,%eax
80108855:	74 0c                	je     80108863 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108857:	c7 04 24 34 94 10 80 	movl   $0x80109434,(%esp)
8010885e:	e8 da 7c ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108863:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010886a:	e9 ad 00 00 00       	jmp    8010891c <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010886f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108872:	8b 55 0c             	mov    0xc(%ebp),%edx
80108875:	01 d0                	add    %edx,%eax
80108877:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010887e:	00 
8010887f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108883:	8b 45 08             	mov    0x8(%ebp),%eax
80108886:	89 04 24             	mov    %eax,(%esp)
80108889:	e8 a9 fb ff ff       	call   80108437 <walkpgdir>
8010888e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108891:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108895:	75 0c                	jne    801088a3 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108897:	c7 04 24 57 94 10 80 	movl   $0x80109457,(%esp)
8010889e:	e8 9a 7c ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801088a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088a6:	8b 00                	mov    (%eax),%eax
801088a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088ad:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801088b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088b3:	8b 55 18             	mov    0x18(%ebp),%edx
801088b6:	89 d1                	mov    %edx,%ecx
801088b8:	29 c1                	sub    %eax,%ecx
801088ba:	89 c8                	mov    %ecx,%eax
801088bc:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801088c1:	77 11                	ja     801088d4 <loaduvm+0x90>
      n = sz - i;
801088c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c6:	8b 55 18             	mov    0x18(%ebp),%edx
801088c9:	89 d1                	mov    %edx,%ecx
801088cb:	29 c1                	sub    %eax,%ecx
801088cd:	89 c8                	mov    %ecx,%eax
801088cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
801088d2:	eb 07                	jmp    801088db <loaduvm+0x97>
    else
      n = PGSIZE;
801088d4:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801088db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088de:	8b 55 14             	mov    0x14(%ebp),%edx
801088e1:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801088e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801088e7:	89 04 24             	mov    %eax,(%esp)
801088ea:	e8 c5 f6 ff ff       	call   80107fb4 <p2v>
801088ef:	8b 55 f0             	mov    -0x10(%ebp),%edx
801088f2:	89 54 24 0c          	mov    %edx,0xc(%esp)
801088f6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801088fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801088fe:	8b 45 10             	mov    0x10(%ebp),%eax
80108901:	89 04 24             	mov    %eax,(%esp)
80108904:	e8 e1 9e ff ff       	call   801027ea <readi>
80108909:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010890c:	74 07                	je     80108915 <loaduvm+0xd1>
      return -1;
8010890e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108913:	eb 18                	jmp    8010892d <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108915:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010891c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891f:	3b 45 18             	cmp    0x18(%ebp),%eax
80108922:	0f 82 47 ff ff ff    	jb     8010886f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108928:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010892d:	83 c4 24             	add    $0x24,%esp
80108930:	5b                   	pop    %ebx
80108931:	5d                   	pop    %ebp
80108932:	c3                   	ret    

80108933 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108933:	55                   	push   %ebp
80108934:	89 e5                	mov    %esp,%ebp
80108936:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108939:	8b 45 10             	mov    0x10(%ebp),%eax
8010893c:	85 c0                	test   %eax,%eax
8010893e:	79 0a                	jns    8010894a <allocuvm+0x17>
    return 0;
80108940:	b8 00 00 00 00       	mov    $0x0,%eax
80108945:	e9 c1 00 00 00       	jmp    80108a0b <allocuvm+0xd8>
  if(newsz < oldsz)
8010894a:	8b 45 10             	mov    0x10(%ebp),%eax
8010894d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108950:	73 08                	jae    8010895a <allocuvm+0x27>
    return oldsz;
80108952:	8b 45 0c             	mov    0xc(%ebp),%eax
80108955:	e9 b1 00 00 00       	jmp    80108a0b <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010895a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010895d:	05 ff 0f 00 00       	add    $0xfff,%eax
80108962:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108967:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010896a:	e9 8d 00 00 00       	jmp    801089fc <allocuvm+0xc9>
    mem = kalloc();
8010896f:	e8 17 ac ff ff       	call   8010358b <kalloc>
80108974:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108977:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010897b:	75 2c                	jne    801089a9 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
8010897d:	c7 04 24 75 94 10 80 	movl   $0x80109475,(%esp)
80108984:	e8 18 7a ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108989:	8b 45 0c             	mov    0xc(%ebp),%eax
8010898c:	89 44 24 08          	mov    %eax,0x8(%esp)
80108990:	8b 45 10             	mov    0x10(%ebp),%eax
80108993:	89 44 24 04          	mov    %eax,0x4(%esp)
80108997:	8b 45 08             	mov    0x8(%ebp),%eax
8010899a:	89 04 24             	mov    %eax,(%esp)
8010899d:	e8 6b 00 00 00       	call   80108a0d <deallocuvm>
      return 0;
801089a2:	b8 00 00 00 00       	mov    $0x0,%eax
801089a7:	eb 62                	jmp    80108a0b <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801089a9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089b0:	00 
801089b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089b8:	00 
801089b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089bc:	89 04 24             	mov    %eax,(%esp)
801089bf:	e8 ba ce ff ff       	call   8010587e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801089c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089c7:	89 04 24             	mov    %eax,(%esp)
801089ca:	e8 d8 f5 ff ff       	call   80107fa7 <v2p>
801089cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801089d2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801089d9:	00 
801089da:	89 44 24 0c          	mov    %eax,0xc(%esp)
801089de:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089e5:	00 
801089e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801089ea:	8b 45 08             	mov    0x8(%ebp),%eax
801089ed:	89 04 24             	mov    %eax,(%esp)
801089f0:	e8 d8 fa ff ff       	call   801084cd <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801089f5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801089fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ff:	3b 45 10             	cmp    0x10(%ebp),%eax
80108a02:	0f 82 67 ff ff ff    	jb     8010896f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108a08:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108a0b:	c9                   	leave  
80108a0c:	c3                   	ret    

80108a0d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108a0d:	55                   	push   %ebp
80108a0e:	89 e5                	mov    %esp,%ebp
80108a10:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108a13:	8b 45 10             	mov    0x10(%ebp),%eax
80108a16:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108a19:	72 08                	jb     80108a23 <deallocuvm+0x16>
    return oldsz;
80108a1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a1e:	e9 a4 00 00 00       	jmp    80108ac7 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108a23:	8b 45 10             	mov    0x10(%ebp),%eax
80108a26:	05 ff 0f 00 00       	add    $0xfff,%eax
80108a2b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a30:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108a33:	e9 80 00 00 00       	jmp    80108ab8 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a3b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108a42:	00 
80108a43:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a47:	8b 45 08             	mov    0x8(%ebp),%eax
80108a4a:	89 04 24             	mov    %eax,(%esp)
80108a4d:	e8 e5 f9 ff ff       	call   80108437 <walkpgdir>
80108a52:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108a55:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108a59:	75 09                	jne    80108a64 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108a5b:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108a62:	eb 4d                	jmp    80108ab1 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a67:	8b 00                	mov    (%eax),%eax
80108a69:	83 e0 01             	and    $0x1,%eax
80108a6c:	84 c0                	test   %al,%al
80108a6e:	74 41                	je     80108ab1 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108a70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a73:	8b 00                	mov    (%eax),%eax
80108a75:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a7a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108a7d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108a81:	75 0c                	jne    80108a8f <deallocuvm+0x82>
        panic("kfree");
80108a83:	c7 04 24 8d 94 10 80 	movl   $0x8010948d,(%esp)
80108a8a:	e8 ae 7a ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108a8f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108a92:	89 04 24             	mov    %eax,(%esp)
80108a95:	e8 1a f5 ff ff       	call   80107fb4 <p2v>
80108a9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108a9d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108aa0:	89 04 24             	mov    %eax,(%esp)
80108aa3:	e8 4a aa ff ff       	call   801034f2 <kfree>
      *pte = 0;
80108aa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108aab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108ab1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108abb:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108abe:	0f 82 74 ff ff ff    	jb     80108a38 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108ac4:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108ac7:	c9                   	leave  
80108ac8:	c3                   	ret    

80108ac9 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108ac9:	55                   	push   %ebp
80108aca:	89 e5                	mov    %esp,%ebp
80108acc:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108acf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108ad3:	75 0c                	jne    80108ae1 <freevm+0x18>
    panic("freevm: no pgdir");
80108ad5:	c7 04 24 93 94 10 80 	movl   $0x80109493,(%esp)
80108adc:	e8 5c 7a ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108ae1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ae8:	00 
80108ae9:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108af0:	80 
80108af1:	8b 45 08             	mov    0x8(%ebp),%eax
80108af4:	89 04 24             	mov    %eax,(%esp)
80108af7:	e8 11 ff ff ff       	call   80108a0d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108afc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108b03:	eb 3c                	jmp    80108b41 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b08:	c1 e0 02             	shl    $0x2,%eax
80108b0b:	03 45 08             	add    0x8(%ebp),%eax
80108b0e:	8b 00                	mov    (%eax),%eax
80108b10:	83 e0 01             	and    $0x1,%eax
80108b13:	84 c0                	test   %al,%al
80108b15:	74 26                	je     80108b3d <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108b17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b1a:	c1 e0 02             	shl    $0x2,%eax
80108b1d:	03 45 08             	add    0x8(%ebp),%eax
80108b20:	8b 00                	mov    (%eax),%eax
80108b22:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b27:	89 04 24             	mov    %eax,(%esp)
80108b2a:	e8 85 f4 ff ff       	call   80107fb4 <p2v>
80108b2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b35:	89 04 24             	mov    %eax,(%esp)
80108b38:	e8 b5 a9 ff ff       	call   801034f2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108b3d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108b41:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108b48:	76 bb                	jbe    80108b05 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108b4a:	8b 45 08             	mov    0x8(%ebp),%eax
80108b4d:	89 04 24             	mov    %eax,(%esp)
80108b50:	e8 9d a9 ff ff       	call   801034f2 <kfree>
}
80108b55:	c9                   	leave  
80108b56:	c3                   	ret    

80108b57 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108b57:	55                   	push   %ebp
80108b58:	89 e5                	mov    %esp,%ebp
80108b5a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108b5d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b64:	00 
80108b65:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b68:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b6c:	8b 45 08             	mov    0x8(%ebp),%eax
80108b6f:	89 04 24             	mov    %eax,(%esp)
80108b72:	e8 c0 f8 ff ff       	call   80108437 <walkpgdir>
80108b77:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108b7a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108b7e:	75 0c                	jne    80108b8c <clearpteu+0x35>
    panic("clearpteu");
80108b80:	c7 04 24 a4 94 10 80 	movl   $0x801094a4,(%esp)
80108b87:	e8 b1 79 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108b8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b8f:	8b 00                	mov    (%eax),%eax
80108b91:	89 c2                	mov    %eax,%edx
80108b93:	83 e2 fb             	and    $0xfffffffb,%edx
80108b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b99:	89 10                	mov    %edx,(%eax)
}
80108b9b:	c9                   	leave  
80108b9c:	c3                   	ret    

80108b9d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108b9d:	55                   	push   %ebp
80108b9e:	89 e5                	mov    %esp,%ebp
80108ba0:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108ba3:	e8 b9 f9 ff ff       	call   80108561 <setupkvm>
80108ba8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108bab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108baf:	75 0a                	jne    80108bbb <copyuvm+0x1e>
    return 0;
80108bb1:	b8 00 00 00 00       	mov    $0x0,%eax
80108bb6:	e9 f1 00 00 00       	jmp    80108cac <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108bbb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108bc2:	e9 c0 00 00 00       	jmp    80108c87 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108bc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108bd1:	00 
80108bd2:	89 44 24 04          	mov    %eax,0x4(%esp)
80108bd6:	8b 45 08             	mov    0x8(%ebp),%eax
80108bd9:	89 04 24             	mov    %eax,(%esp)
80108bdc:	e8 56 f8 ff ff       	call   80108437 <walkpgdir>
80108be1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108be4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108be8:	75 0c                	jne    80108bf6 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108bea:	c7 04 24 ae 94 10 80 	movl   $0x801094ae,(%esp)
80108bf1:	e8 47 79 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80108bf6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108bf9:	8b 00                	mov    (%eax),%eax
80108bfb:	83 e0 01             	and    $0x1,%eax
80108bfe:	85 c0                	test   %eax,%eax
80108c00:	75 0c                	jne    80108c0e <copyuvm+0x71>
      panic("copyuvm: page not present");
80108c02:	c7 04 24 c8 94 10 80 	movl   $0x801094c8,(%esp)
80108c09:	e8 2f 79 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108c0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108c11:	8b 00                	mov    (%eax),%eax
80108c13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c18:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108c1b:	e8 6b a9 ff ff       	call   8010358b <kalloc>
80108c20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108c23:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108c27:	74 6f                	je     80108c98 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108c29:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108c2c:	89 04 24             	mov    %eax,(%esp)
80108c2f:	e8 80 f3 ff ff       	call   80107fb4 <p2v>
80108c34:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c3b:	00 
80108c3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108c43:	89 04 24             	mov    %eax,(%esp)
80108c46:	e8 06 cd ff ff       	call   80105951 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80108c4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108c4e:	89 04 24             	mov    %eax,(%esp)
80108c51:	e8 51 f3 ff ff       	call   80107fa7 <v2p>
80108c56:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108c59:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c60:	00 
80108c61:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c65:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c6c:	00 
80108c6d:	89 54 24 04          	mov    %edx,0x4(%esp)
80108c71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c74:	89 04 24             	mov    %eax,(%esp)
80108c77:	e8 51 f8 ff ff       	call   801084cd <mappages>
80108c7c:	85 c0                	test   %eax,%eax
80108c7e:	78 1b                	js     80108c9b <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108c80:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108c87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c8a:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108c8d:	0f 82 34 ff ff ff    	jb     80108bc7 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108c93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c96:	eb 14                	jmp    80108cac <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108c98:	90                   	nop
80108c99:	eb 01                	jmp    80108c9c <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108c9b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108c9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c9f:	89 04 24             	mov    %eax,(%esp)
80108ca2:	e8 22 fe ff ff       	call   80108ac9 <freevm>
  return 0;
80108ca7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108cac:	c9                   	leave  
80108cad:	c3                   	ret    

80108cae <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108cae:	55                   	push   %ebp
80108caf:	89 e5                	mov    %esp,%ebp
80108cb1:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108cb4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108cbb:	00 
80108cbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80108cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80108cc6:	89 04 24             	mov    %eax,(%esp)
80108cc9:	e8 69 f7 ff ff       	call   80108437 <walkpgdir>
80108cce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108cd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd4:	8b 00                	mov    (%eax),%eax
80108cd6:	83 e0 01             	and    $0x1,%eax
80108cd9:	85 c0                	test   %eax,%eax
80108cdb:	75 07                	jne    80108ce4 <uva2ka+0x36>
    return 0;
80108cdd:	b8 00 00 00 00       	mov    $0x0,%eax
80108ce2:	eb 25                	jmp    80108d09 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce7:	8b 00                	mov    (%eax),%eax
80108ce9:	83 e0 04             	and    $0x4,%eax
80108cec:	85 c0                	test   %eax,%eax
80108cee:	75 07                	jne    80108cf7 <uva2ka+0x49>
    return 0;
80108cf0:	b8 00 00 00 00       	mov    $0x0,%eax
80108cf5:	eb 12                	jmp    80108d09 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfa:	8b 00                	mov    (%eax),%eax
80108cfc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d01:	89 04 24             	mov    %eax,(%esp)
80108d04:	e8 ab f2 ff ff       	call   80107fb4 <p2v>
}
80108d09:	c9                   	leave  
80108d0a:	c3                   	ret    

80108d0b <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108d0b:	55                   	push   %ebp
80108d0c:	89 e5                	mov    %esp,%ebp
80108d0e:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108d11:	8b 45 10             	mov    0x10(%ebp),%eax
80108d14:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108d17:	e9 8b 00 00 00       	jmp    80108da7 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d24:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108d27:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80108d31:	89 04 24             	mov    %eax,(%esp)
80108d34:	e8 75 ff ff ff       	call   80108cae <uva2ka>
80108d39:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108d3c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108d40:	75 07                	jne    80108d49 <copyout+0x3e>
      return -1;
80108d42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d47:	eb 6d                	jmp    80108db6 <copyout+0xab>
    n = PGSIZE - (va - va0);
80108d49:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d4c:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108d4f:	89 d1                	mov    %edx,%ecx
80108d51:	29 c1                	sub    %eax,%ecx
80108d53:	89 c8                	mov    %ecx,%eax
80108d55:	05 00 10 00 00       	add    $0x1000,%eax
80108d5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d60:	3b 45 14             	cmp    0x14(%ebp),%eax
80108d63:	76 06                	jbe    80108d6b <copyout+0x60>
      n = len;
80108d65:	8b 45 14             	mov    0x14(%ebp),%eax
80108d68:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108d6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d6e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108d71:	89 d1                	mov    %edx,%ecx
80108d73:	29 c1                	sub    %eax,%ecx
80108d75:	89 c8                	mov    %ecx,%eax
80108d77:	03 45 e8             	add    -0x18(%ebp),%eax
80108d7a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d7d:	89 54 24 08          	mov    %edx,0x8(%esp)
80108d81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108d84:	89 54 24 04          	mov    %edx,0x4(%esp)
80108d88:	89 04 24             	mov    %eax,(%esp)
80108d8b:	e8 c1 cb ff ff       	call   80105951 <memmove>
    len -= n;
80108d90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d93:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108d96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d99:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108d9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d9f:	05 00 10 00 00       	add    $0x1000,%eax
80108da4:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108da7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108dab:	0f 85 6b ff ff ff    	jne    80108d1c <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108db1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108db6:	c9                   	leave  
80108db7:	c3                   	ret    


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
8010002d:	b8 ab 3f 10 80       	mov    $0x80103fab,%eax
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
8010003a:	c7 44 24 04 d0 8e 10 	movl   $0x80108ed0,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 d8 56 00 00       	call   80105726 <initlock>

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
801000bd:	e8 85 56 00 00       	call   80105747 <acquire>

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
80100104:	e8 a0 56 00 00       	call   801057a9 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 45 53 00 00       	call   80105469 <sleep>
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
8010017c:	e8 28 56 00 00       	call   801057a9 <release>
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
80100198:	c7 04 24 d7 8e 10 80 	movl   $0x80108ed7,(%esp)
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
801001d3:	e8 80 31 00 00       	call   80103358 <iderw>
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
801001ef:	c7 04 24 e8 8e 10 80 	movl   $0x80108ee8,(%esp)
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
80100210:	e8 43 31 00 00       	call   80103358 <iderw>
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
80100229:	c7 04 24 ef 8e 10 80 	movl   $0x80108eef,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 06 55 00 00       	call   80105747 <acquire>

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
8010029d:	e8 a0 52 00 00       	call   80105542 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 fb 54 00 00       	call   801057a9 <release>
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
801003bc:	e8 86 53 00 00       	call   80105747 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 f6 8e 10 80 	movl   $0x80108ef6,(%esp)
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
801004af:	c7 45 ec ff 8e 10 80 	movl   $0x80108eff,-0x14(%ebp)
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
80100536:	e8 6e 52 00 00       	call   801057a9 <release>
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
80100562:	c7 04 24 06 8f 10 80 	movl   $0x80108f06,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 15 8f 10 80 	movl   $0x80108f15,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 61 52 00 00       	call   801057f8 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 17 8f 10 80 	movl   $0x80108f17,(%esp)
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
801006b2:	e8 b2 53 00 00       	call   80105a69 <memmove>
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
801006e1:	e8 b0 52 00 00       	call   80105996 <memset>
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
80100776:	e8 ba 6d 00 00       	call   80107535 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 ae 6d 00 00       	call   80107535 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 a2 6d 00 00       	call   80107535 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 95 6d 00 00       	call   80107535 <uartputc>
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
801007ba:	e8 88 4f 00 00       	call   80105747 <acquire>
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
801007ea:	e8 f6 4d 00 00       	call   801055e5 <procdump>
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
801008f7:	e8 46 4c 00 00       	call   80105542 <wakeup>
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
8010091e:	e8 86 4e 00 00       	call   801057a9 <release>
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
80100931:	e8 00 1b 00 00       	call   80102436 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 ff 4d 00 00       	call   80105747 <acquire>
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
80100961:	e8 43 4e 00 00       	call   801057a9 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 77 19 00 00       	call   801022e8 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 da 4a 00 00       	call   80105469 <sleep>
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
80100a08:	e8 9c 4d 00 00       	call   801057a9 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 d0 18 00 00       	call   801022e8 <ilock>

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
80100a32:	e8 ff 19 00 00       	call   80102436 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 04 4d 00 00       	call   80105747 <acquire>
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
80100a78:	e8 2c 4d 00 00       	call   801057a9 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 60 18 00 00       	call   801022e8 <ilock>

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
80100a93:	c7 44 24 04 1b 8f 10 	movl   $0x80108f1b,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 7f 4c 00 00       	call   80105726 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 23 8f 10 	movl   $0x80108f23,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 6b 4c 00 00       	call   80105726 <initlock>

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
80100ae0:	e8 80 3b 00 00       	call   80104665 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 21 2a 00 00       	call   8010351a <ioapicenable>
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
80100b0b:	e8 7a 23 00 00       	call   80102e8a <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 ba 17 00 00       	call   801022e8 <ilock>
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
80100b55:	e8 84 1c 00 00       	call   801027de <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 a3 36 10 80 	movl   $0x801036a3,(%esp)
80100b7b:	e8 f9 7a 00 00       	call   80108679 <setupkvm>
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
80100bc8:	e8 11 1c 00 00       	call   801027de <readi>
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
80100c14:	e8 32 7e 00 00       	call   80108a4b <allocuvm>
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
80100c51:	e8 06 7d 00 00       	call   8010895c <loaduvm>
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
80100c87:	e8 e0 18 00 00       	call   8010256c <iunlockput>
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
80100cbc:	e8 8a 7d 00 00       	call   80108a4b <allocuvm>
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
80100ce0:	e8 8a 7f 00 00       	call   80108c6f <clearpteu>
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
80100d0f:	e8 00 4f 00 00       	call   80105c14 <strlen>
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
80100d2d:	e8 e2 4e 00 00       	call   80105c14 <strlen>
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
80100d57:	e8 c7 80 00 00       	call   80108e23 <copyout>
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
80100df7:	e8 27 80 00 00       	call   80108e23 <copyout>
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
80100e4e:	e8 73 4d 00 00       	call   80105bc6 <safestrcpy>

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
80100ea0:	e8 c5 78 00 00       	call   8010876a <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 31 7d 00 00       	call   80108be1 <freevm>
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
80100ee2:	e8 fa 7c 00 00       	call   80108be1 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 74 16 00 00       	call   8010256c <iunlockput>
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
80100f06:	c7 44 24 04 2c 8f 10 	movl   $0x80108f2c,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 0c 48 00 00       	call   80105726 <initlock>
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
80100f29:	e8 19 48 00 00       	call   80105747 <acquire>
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
80100f52:	e8 52 48 00 00       	call   801057a9 <release>
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
80100f70:	e8 34 48 00 00       	call   801057a9 <release>
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
80100f89:	e8 b9 47 00 00       	call   80105747 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 33 8f 10 80 	movl   $0x80108f33,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 ea 47 00 00       	call   801057a9 <release>
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
80100fd1:	e8 71 47 00 00       	call   80105747 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 3b 8f 10 80 	movl   $0x80108f3b,(%esp)
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
8010100c:	e8 98 47 00 00       	call   801057a9 <release>
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
80101056:	e8 4e 47 00 00       	call   801057a9 <release>
  
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
80101074:	e8 a6 38 00 00       	call   8010491f <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 39 2d 00 00       	call   80103dc1 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 08 14 00 00       	call   8010249b <iput>
    commit_trans();
80101093:	e8 72 2d 00 00       	call   80103e0a <commit_trans>
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
801010b3:	e8 30 12 00 00       	call   801022e8 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 cc 16 00 00       	call   80102799 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 5b 13 00 00       	call   80102436 <iunlock>
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
80101125:	e8 77 39 00 00       	call   80104aa1 <piperead>
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
8010113f:	e8 a4 11 00 00       	call   801022e8 <ilock>
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
80101165:	e8 74 16 00 00       	call   801027de <readi>
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
8010118d:	e8 a4 12 00 00       	call   80102436 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 45 8f 10 80 	movl   $0x80108f45,(%esp)
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
801011e2:	e8 ca 37 00 00       	call   801049b1 <pipewrite>
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
8010122a:	e8 92 2b 00 00       	call   80103dc1 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 ab 10 00 00       	call   801022e8 <ilock>
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
80101263:	e8 e1 16 00 00       	call   80102949 <writei>
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
8010128b:	e8 a6 11 00 00       	call   80102436 <iunlock>
      commit_trans();
80101290:	e8 75 2b 00 00       	call   80103e0a <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 4e 8f 10 80 	movl   $0x80108f4e,(%esp)
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
801012d8:	c7 04 24 5e 8f 10 80 	movl   $0x80108f5e,(%esp)
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
801012fe:	e8 c2 53 00 00       	call   801066c5 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 68 8f 10 80 	movl   $0x80108f68,(%esp)
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
80101338:	e8 ab 0f 00 00       	call   801022e8 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 80 8f 10 80 	movl   $0x80108f80,(%esp)
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
80101382:	c7 04 24 a3 8f 10 80 	movl   $0x80108fa3,(%esp)
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
801013b7:	c7 04 24 bc 8f 10 80 	movl   $0x80108fbc,(%esp)
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
80101414:	c7 04 24 db 8f 10 80 	movl   $0x80108fdb,(%esp)
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
8010143b:	e8 f6 0f 00 00       	call   80102436 <iunlock>
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
8010146a:	e8 fd 08 00 00       	call   80101d6c <readsb>
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
8010153e:	c7 04 24 f4 8f 10 80 	movl   $0x80108ff4,(%esp)
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
8010162e:	e8 27 09 00 00       	call   80101f5a <bfree>
}
80101633:	c9                   	leave  
80101634:	c3                   	ret    

80101635 <dedup>:

int
dedup(void)
{
80101635:	55                   	push   %ebp
80101636:	89 e5                	mov    %esp,%ebp
80101638:	81 ec 88 00 00 00    	sub    $0x88,%esp
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0, iChanged;
8010163e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101645:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
8010164c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101653:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
8010165a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  struct inode* ip1=0, *ip2=0;
80101661:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
80101668:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
8010166f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
80101676:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
8010167d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
80101684:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  uint *a = 0, *b = 0;
8010168b:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
80101692:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  struct superblock sb;
  readsb(1, &sb);
80101699:	8d 45 98             	lea    -0x68(%ebp),%eax
8010169c:	89 44 24 04          	mov    %eax,0x4(%esp)
801016a0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801016a7:	e8 c0 06 00 00       	call   80101d6c <readsb>
  ninodes = sb.ninodes;
801016ac:	8b 45 a0             	mov    -0x60(%ebp),%eax
801016af:	89 45 c0             	mov    %eax,-0x40(%ebp)
  
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
801016b2:	e9 9c 06 00 00       	jmp    80101d53 <dedup+0x71e>
  {
    iChanged = 0;
801016b7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
801016be:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016c1:	89 04 24             	mov    %eax,(%esp)
801016c4:	e8 1f 0c 00 00       	call   801022e8 <ilock>
    if(ip1->addrs[NDIRECT])
801016c9:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016cc:	8b 40 4c             	mov    0x4c(%eax),%eax
801016cf:	85 c0                	test   %eax,%eax
801016d1:	74 2a                	je     801016fd <dedup+0xc8>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
801016d3:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016d6:	8b 50 4c             	mov    0x4c(%eax),%edx
801016d9:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016dc:	8b 00                	mov    (%eax),%eax
801016de:	89 54 24 04          	mov    %edx,0x4(%esp)
801016e2:	89 04 24             	mov    %eax,(%esp)
801016e5:	e8 bc ea ff ff       	call   801001a6 <bread>
801016ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
      a = (uint*)bp1->data;
801016ed:	8b 45 d8             	mov    -0x28(%ebp),%eax
801016f0:	83 c0 18             	add    $0x18,%eax
801016f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
      indirects1 = NINDIRECT;
801016f6:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
801016fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101704:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
8010170b:	e9 03 06 00 00       	jmp    80101d13 <dedup+0x6de>
    {
      if(blockIndex1<NDIRECT)							// in the same file
80101710:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101714:	0f 8f 3b 02 00 00    	jg     80101955 <dedup+0x320>
      {
	if(ip1->addrs[blockIndex1])
8010171a:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010171d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101720:	83 c2 04             	add    $0x4,%edx
80101723:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101727:	85 c0                	test   %eax,%eax
80101729:	0f 84 18 01 00 00    	je     80101847 <dedup+0x212>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
8010172f:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101732:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101735:	83 c2 04             	add    $0x4,%edx
80101738:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010173c:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010173f:	8b 00                	mov    (%eax),%eax
80101741:	89 54 24 04          	mov    %edx,0x4(%esp)
80101745:	89 04 24             	mov    %eax,(%esp)
80101748:	e8 59 ea ff ff       	call   801001a6 <bread>
8010174d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	  for(blockIndex2 = NDIRECT; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to direct
80101750:	c7 45 f0 0c 00 00 00 	movl   $0xc,-0x10(%ebp)
80101757:	e9 d4 00 00 00       	jmp    80101830 <dedup+0x1fb>
	  {
	    if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
8010175c:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010175f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101762:	83 c2 04             	add    $0x4,%edx
80101765:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101769:	85 c0                	test   %eax,%eax
8010176b:	0f 84 bb 00 00 00    	je     8010182c <dedup+0x1f7>
80101771:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101774:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101777:	83 c2 04             	add    $0x4,%edx
8010177a:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010177e:	85 c0                	test   %eax,%eax
80101780:	0f 84 a6 00 00 00    	je     8010182c <dedup+0x1f7>
	    {
	      b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
80101786:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101789:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010178c:	83 c2 04             	add    $0x4,%edx
8010178f:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101793:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101796:	8b 00                	mov    (%eax),%eax
80101798:	89 54 24 04          	mov    %edx,0x4(%esp)
8010179c:	89 04 24             	mov    %eax,(%esp)
8010179f:	e8 02 ea ff ff       	call   801001a6 <bread>
801017a4:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	      if(blkcmp(b1,b2))
801017a7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801017aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801017ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
801017b1:	89 04 24             	mov    %eax,(%esp)
801017b4:	e8 9c fd ff ff       	call   80101555 <blkcmp>
801017b9:	85 c0                	test   %eax,%eax
801017bb:	74 64                	je     80101821 <dedup+0x1ec>
	      {
		deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
801017bd:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
801017c4:	00 
801017c5:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
801017cc:	00 
801017cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017d0:	89 44 24 14          	mov    %eax,0x14(%esp)
801017d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017d7:	89 44 24 10          	mov    %eax,0x10(%esp)
801017db:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801017de:	89 44 24 0c          	mov    %eax,0xc(%esp)
801017e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801017e5:	89 44 24 08          	mov    %eax,0x8(%esp)
801017e9:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017ec:	89 44 24 04          	mov    %eax,0x4(%esp)
801017f0:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017f3:	89 04 24             	mov    %eax,(%esp)
801017f6:	e8 a2 fd ff ff       	call   8010159d <deletedups>
		brelse(b1);				// release the outer loop block
801017fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
801017fe:	89 04 24             	mov    %eax,(%esp)
80101801:	e8 11 ea ff ff       	call   80100217 <brelse>
		brelse(b2);
80101806:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101809:	89 04 24             	mov    %eax,(%esp)
8010180c:	e8 06 ea ff ff       	call   80100217 <brelse>
		found = 1;
80101811:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		iChanged = 1;
80101818:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		break;
8010181f:	eb 1b                	jmp    8010183c <dedup+0x207>
	      }
	      brelse(b2);
80101821:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101824:	89 04 24             	mov    %eax,(%esp)
80101827:	e8 eb e9 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to direct
8010182c:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101830:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101833:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101836:	0f 8f 20 ff ff ff    	jg     8010175c <dedup+0x127>
	{
	  b1 = 0;
	  continue;
	}
	
	if(b1 && a && !found)
8010183c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80101840:	75 11                	jne    80101853 <dedup+0x21e>
80101842:	e9 3e 02 00 00       	jmp    80101a85 <dedup+0x450>
	    }
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{
	  b1 = 0;
80101847:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	  continue;
8010184e:	e9 b5 04 00 00       	jmp    80101d08 <dedup+0x6d3>
	}
	
	if(b1 && a && !found)
80101853:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80101857:	0f 84 27 02 00 00    	je     80101a84 <dedup+0x44f>
8010185d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101861:	0f 85 1d 02 00 00    	jne    80101a84 <dedup+0x44f>
	{
	  for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101867:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
8010186e:	e9 d3 00 00 00       	jmp    80101946 <dedup+0x311>
	  {
	    if(ip1->addrs[blockIndex1] && a[blockIndex2])
80101873:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101876:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101879:	83 c2 04             	add    $0x4,%edx
8010187c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101880:	85 c0                	test   %eax,%eax
80101882:	0f 84 ba 00 00 00    	je     80101942 <dedup+0x30d>
80101888:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010188b:	c1 e0 02             	shl    $0x2,%eax
8010188e:	03 45 d0             	add    -0x30(%ebp),%eax
80101891:	8b 00                	mov    (%eax),%eax
80101893:	85 c0                	test   %eax,%eax
80101895:	0f 84 a7 00 00 00    	je     80101942 <dedup+0x30d>
	    {
	      b2 = bread(ip1->dev,a[blockIndex2]);
8010189b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010189e:	c1 e0 02             	shl    $0x2,%eax
801018a1:	03 45 d0             	add    -0x30(%ebp),%eax
801018a4:	8b 10                	mov    (%eax),%edx
801018a6:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018a9:	8b 00                	mov    (%eax),%eax
801018ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801018af:	89 04 24             	mov    %eax,(%esp)
801018b2:	e8 ef e8 ff ff       	call   801001a6 <bread>
801018b7:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	      if(blkcmp(b1,b2))
801018ba:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801018bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801018c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
801018c4:	89 04 24             	mov    %eax,(%esp)
801018c7:	e8 89 fc ff ff       	call   80101555 <blkcmp>
801018cc:	85 c0                	test   %eax,%eax
801018ce:	74 67                	je     80101937 <dedup+0x302>
	      {
		deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,a);
801018d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
801018d3:	89 44 24 1c          	mov    %eax,0x1c(%esp)
801018d7:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
801018de:	00 
801018df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018e2:	89 44 24 14          	mov    %eax,0x14(%esp)
801018e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018e9:	89 44 24 10          	mov    %eax,0x10(%esp)
801018ed:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801018f0:	89 44 24 0c          	mov    %eax,0xc(%esp)
801018f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
801018f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801018fb:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80101902:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101905:	89 04 24             	mov    %eax,(%esp)
80101908:	e8 90 fc ff ff       	call   8010159d <deletedups>
		brelse(b1);				// release the outer loop block
8010190d:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101910:	89 04 24             	mov    %eax,(%esp)
80101913:	e8 ff e8 ff ff       	call   80100217 <brelse>
		brelse(b2);
80101918:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010191b:	89 04 24             	mov    %eax,(%esp)
8010191e:	e8 f4 e8 ff ff       	call   80100217 <brelse>
		found = 1;
80101923:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		iChanged = 1;
8010192a:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		break;
80101931:	90                   	nop
80101932:	e9 4e 01 00 00       	jmp    80101a85 <dedup+0x450>
	      }
	      brelse(b2);
80101937:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010193a:	89 04 24             	mov    %eax,(%esp)
8010193d:	e8 d5 e8 ff ff       	call   80100217 <brelse>
	  continue;
	}
	
	if(b1 && a && !found)
	{
	  for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101942:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101946:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010194a:	0f 89 23 ff ff ff    	jns    80101873 <dedup+0x23e>
80101950:	e9 2f 01 00 00       	jmp    80101a84 <dedup+0x44f>
	      brelse(b2);
	    }
	  } // for blockindex2 < NINDIRECT in ip1
	} //if not found match, check INDIRECT
      } // if blockindex1 is < NDIRECT
      else if(!found)					// in the same file
80101955:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101959:	0f 85 26 01 00 00    	jne    80101a85 <dedup+0x450>
      {
	if(a)
8010195f:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
80101963:	0f 84 1c 01 00 00    	je     80101a85 <dedup+0x450>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
80101969:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010196c:	83 e8 0c             	sub    $0xc,%eax
8010196f:	89 45 b0             	mov    %eax,-0x50(%ebp)
	  if(a[blockIndex1Offset])
80101972:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101975:	c1 e0 02             	shl    $0x2,%eax
80101978:	03 45 d0             	add    -0x30(%ebp),%eax
8010197b:	8b 00                	mov    (%eax),%eax
8010197d:	85 c0                	test   %eax,%eax
8010197f:	0f 84 f3 00 00 00    	je     80101a78 <dedup+0x443>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
80101985:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101988:	c1 e0 02             	shl    $0x2,%eax
8010198b:	03 45 d0             	add    -0x30(%ebp),%eax
8010198e:	8b 10                	mov    (%eax),%edx
80101990:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101993:	8b 00                	mov    (%eax),%eax
80101995:	89 54 24 04          	mov    %edx,0x4(%esp)
80101999:	89 04 24             	mov    %eax,(%esp)
8010199c:	e8 05 e8 ff ff       	call   801001a6 <bread>
801019a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
801019a4:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
801019ab:	e9 ba 00 00 00       	jmp    80101a6a <dedup+0x435>
	    {
	      if(a[blockIndex2])
801019b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019b3:	c1 e0 02             	shl    $0x2,%eax
801019b6:	03 45 d0             	add    -0x30(%ebp),%eax
801019b9:	8b 00                	mov    (%eax),%eax
801019bb:	85 c0                	test   %eax,%eax
801019bd:	0f 84 a3 00 00 00    	je     80101a66 <dedup+0x431>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);
801019c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019c6:	c1 e0 02             	shl    $0x2,%eax
801019c9:	03 45 d0             	add    -0x30(%ebp),%eax
801019cc:	8b 10                	mov    (%eax),%edx
801019ce:	8b 45 bc             	mov    -0x44(%ebp),%eax
801019d1:	8b 00                	mov    (%eax),%eax
801019d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801019d7:	89 04 24             	mov    %eax,(%esp)
801019da:	e8 c7 e7 ff ff       	call   801001a6 <bread>
801019df:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
801019e2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801019e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801019e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801019ec:	89 04 24             	mov    %eax,(%esp)
801019ef:	e8 61 fb ff ff       	call   80101555 <blkcmp>
801019f4:	85 c0                	test   %eax,%eax
801019f6:	74 63                	je     80101a5b <dedup+0x426>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
801019f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
801019fb:	89 44 24 1c          	mov    %eax,0x1c(%esp)
801019ff:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101a02:	89 44 24 18          	mov    %eax,0x18(%esp)
80101a06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a09:	89 44 24 14          	mov    %eax,0x14(%esp)
80101a0d:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101a10:	89 44 24 10          	mov    %eax,0x10(%esp)
80101a14:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a17:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101a1b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a1e:	89 44 24 08          	mov    %eax,0x8(%esp)
80101a22:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a25:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a29:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a2c:	89 04 24             	mov    %eax,(%esp)
80101a2f:	e8 69 fb ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101a34:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a37:	89 04 24             	mov    %eax,(%esp)
80101a3a:	e8 d8 e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101a3f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a42:	89 04 24             	mov    %eax,(%esp)
80101a45:	e8 cd e7 ff ff       	call   80100217 <brelse>
		  found = 1;
80101a4a:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101a51:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101a58:	90                   	nop
80101a59:	eb 2a                	jmp    80101a85 <dedup+0x450>
		}
		brelse(b2);
80101a5b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a5e:	89 04 24             	mov    %eax,(%esp)
80101a61:	e8 b1 e7 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101a66:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101a6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a6d:	3b 45 b0             	cmp    -0x50(%ebp),%eax
80101a70:	0f 8f 3a ff ff ff    	jg     801019b0 <dedup+0x37b>
80101a76:	eb 0d                	jmp    80101a85 <dedup+0x450>
	      }
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    b1 = 0;
80101a78:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	    continue;
80101a7f:	e9 84 02 00 00       	jmp    80101d08 <dedup+0x6d3>
	  continue;
	}
	
	if(b1 && a && !found)
	{
	  for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
80101a84:	90                   	nop
	    continue;
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101a85:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101a89:	0f 85 6e 02 00 00    	jne    80101cfd <dedup+0x6c8>
80101a8f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80101a93:	0f 84 64 02 00 00    	je     80101cfd <dedup+0x6c8>
      {
	uint* aSub = 0;
80101a99:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
	int blockIndex1Offset = blockIndex1;
80101aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101aa3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if(blockIndex1 >= NDIRECT)
80101aa6:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101aaa:	7e 0f                	jle    80101abb <dedup+0x486>
	{
	  aSub = a;
80101aac:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101aaf:	89 45 c8             	mov    %eax,-0x38(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101ab2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ab5:	83 e8 0c             	sub    $0xc,%eax
80101ab8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	}
	prevInum = ninodes-1;
80101abb:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101abe:	83 e8 01             	sub    $0x1,%eax
80101ac1:	89 45 a8             	mov    %eax,-0x58(%ebp)
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101ac4:	e9 1c 02 00 00       	jmp    80101ce5 <dedup+0x6b0>
	{
	  ilock(ip2);
80101ac9:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101acc:	89 04 24             	mov    %eax,(%esp)
80101acf:	e8 14 08 00 00       	call   801022e8 <ilock>
	  if(ip2->addrs[NDIRECT])
80101ad4:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ad7:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ada:	85 c0                	test   %eax,%eax
80101adc:	74 2a                	je     80101b08 <dedup+0x4d3>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101ade:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ae1:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ae4:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ae7:	8b 00                	mov    (%eax),%eax
80101ae9:	89 54 24 04          	mov    %edx,0x4(%esp)
80101aed:	89 04 24             	mov    %eax,(%esp)
80101af0:	e8 b1 e6 ff ff       	call   801001a6 <bread>
80101af5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	    b = (uint*)bp2->data;
80101af8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101afb:	83 c0 18             	add    $0x18,%eax
80101afe:	89 45 cc             	mov    %eax,-0x34(%ebp)
	    indirects2 = NINDIRECT;
80101b01:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  
	  for(blockIndex2 = 0; blockIndex2 < NDIRECT + indirects2; blockIndex2++) 		//get the first block - outer block loop
80101b08:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101b0f:	e9 a2 01 00 00       	jmp    80101cb6 <dedup+0x681>
	  {
	    if(blockIndex2<NDIRECT)
80101b14:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101b18:	0f 8f c2 00 00 00    	jg     80101be0 <dedup+0x5ab>
	    {
	      if(ip2->addrs[blockIndex2])
80101b1e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b21:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b24:	83 c2 04             	add    $0x4,%edx
80101b27:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b2b:	85 c0                	test   %eax,%eax
80101b2d:	0f 84 7f 01 00 00    	je     80101cb2 <dedup+0x67d>
	      {
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);
80101b33:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b36:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b39:	83 c2 04             	add    $0x4,%edx
80101b3c:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101b40:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b43:	8b 00                	mov    (%eax),%eax
80101b45:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b49:	89 04 24             	mov    %eax,(%esp)
80101b4c:	e8 55 e6 ff ff       	call   801001a6 <bread>
80101b51:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101b54:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101b57:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b5b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101b5e:	89 04 24             	mov    %eax,(%esp)
80101b61:	e8 ef f9 ff ff       	call   80101555 <blkcmp>
80101b66:	85 c0                	test   %eax,%eax
80101b68:	74 66                	je     80101bd0 <dedup+0x59b>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101b6a:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101b71:	00 
80101b72:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101b75:	89 44 24 18          	mov    %eax,0x18(%esp)
80101b79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b7c:	89 44 24 14          	mov    %eax,0x14(%esp)
80101b80:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101b83:	89 44 24 10          	mov    %eax,0x10(%esp)
80101b87:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101b8a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101b8e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101b91:	89 44 24 08          	mov    %eax,0x8(%esp)
80101b95:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b98:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b9c:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101b9f:	89 04 24             	mov    %eax,(%esp)
80101ba2:	e8 f6 f9 ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101ba7:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101baa:	89 04 24             	mov    %eax,(%esp)
80101bad:	e8 65 e6 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101bb2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bb5:	89 04 24             	mov    %eax,(%esp)
80101bb8:	e8 5a e6 ff ff       	call   80100217 <brelse>
		  found = 1;
80101bbd:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101bc4:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101bcb:	e9 f5 00 00 00       	jmp    80101cc5 <dedup+0x690>
		}
		brelse(b2);
80101bd0:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bd3:	89 04 24             	mov    %eax,(%esp)
80101bd6:	e8 3c e6 ff ff       	call   80100217 <brelse>
80101bdb:	e9 d2 00 00 00       	jmp    80101cb2 <dedup+0x67d>
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT
	    else if(!found)
80101be0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101be4:	0f 85 c8 00 00 00    	jne    80101cb2 <dedup+0x67d>
	    {
	      if(b)
80101bea:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101bee:	0f 84 be 00 00 00    	je     80101cb2 <dedup+0x67d>
	      {
		int blockIndex2Offset = blockIndex2 - NDIRECT;
80101bf4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bf7:	83 e8 0c             	sub    $0xc,%eax
80101bfa:	89 45 ac             	mov    %eax,-0x54(%ebp)
		if(b[blockIndex2Offset])
80101bfd:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c00:	c1 e0 02             	shl    $0x2,%eax
80101c03:	03 45 cc             	add    -0x34(%ebp),%eax
80101c06:	8b 00                	mov    (%eax),%eax
80101c08:	85 c0                	test   %eax,%eax
80101c0a:	0f 84 a2 00 00 00    	je     80101cb2 <dedup+0x67d>
		{
		  b2 = bread(ip2->dev,b[blockIndex2Offset]);
80101c10:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c13:	c1 e0 02             	shl    $0x2,%eax
80101c16:	03 45 cc             	add    -0x34(%ebp),%eax
80101c19:	8b 10                	mov    (%eax),%edx
80101c1b:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c1e:	8b 00                	mov    (%eax),%eax
80101c20:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c24:	89 04 24             	mov    %eax,(%esp)
80101c27:	e8 7a e5 ff ff       	call   801001a6 <bread>
80101c2c:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		  if(blkcmp(b1,b2))
80101c2f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c36:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c39:	89 04 24             	mov    %eax,(%esp)
80101c3c:	e8 14 f9 ff ff       	call   80101555 <blkcmp>
80101c41:	85 c0                	test   %eax,%eax
80101c43:	74 62                	je     80101ca7 <dedup+0x672>
		  {
		    deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101c45:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101c48:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101c4c:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101c4f:	89 44 24 18          	mov    %eax,0x18(%esp)
80101c53:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101c56:	89 44 24 14          	mov    %eax,0x14(%esp)
80101c5a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101c5d:	89 44 24 10          	mov    %eax,0x10(%esp)
80101c61:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c64:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101c68:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c6b:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c6f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c72:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c76:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c79:	89 04 24             	mov    %eax,(%esp)
80101c7c:	e8 1c f9 ff ff       	call   8010159d <deletedups>
		    brelse(b1);				// release the outer loop block
80101c81:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c84:	89 04 24             	mov    %eax,(%esp)
80101c87:	e8 8b e5 ff ff       	call   80100217 <brelse>
		    brelse(b2);
80101c8c:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c8f:	89 04 24             	mov    %eax,(%esp)
80101c92:	e8 80 e5 ff ff       	call   80100217 <brelse>
		    found = 1;
80101c97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		    iChanged = 1;
80101c9e:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		    break;
80101ca5:	eb 1e                	jmp    80101cc5 <dedup+0x690>
		  }
		  brelse(b2);
80101ca7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101caa:	89 04 24             	mov    %eax,(%esp)
80101cad:	e8 65 e5 ff ff       	call   80100217 <brelse>
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  
	  for(blockIndex2 = 0; blockIndex2 < NDIRECT + indirects2; blockIndex2++) 		//get the first block - outer block loop
80101cb2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101cb9:	83 c0 0c             	add    $0xc,%eax
80101cbc:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101cbf:	0f 8f 4f fe ff ff    	jg     80101b14 <dedup+0x4df>
		  brelse(b2);
		} // if blockIndex2Offset in ip2 != 0
	      }// if ip2 has INDIRECT
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  if(ip2->addrs[NDIRECT])
80101cc5:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cc8:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ccb:	85 c0                	test   %eax,%eax
80101ccd:	74 0b                	je     80101cda <dedup+0x6a5>
	    brelse(bp2);
80101ccf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101cd2:	89 04 24             	mov    %eax,(%esp)
80101cd5:	e8 3d e5 ff ff       	call   80100217 <brelse>
	  
	  iunlockput(ip2);
80101cda:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cdd:	89 04 24             	mov    %eax,(%esp)
80101ce0:	e8 87 08 00 00       	call   8010256c <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101ce5:	8d 45 a8             	lea    -0x58(%ebp),%eax
80101ce8:	89 04 24             	mov    %eax,(%esp)
80101ceb:	e8 7b 12 00 00       	call   80102f6b <getPrevInode>
80101cf0:	89 45 b8             	mov    %eax,-0x48(%ebp)
80101cf3:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
80101cf7:	0f 85 cc fd ff ff    	jne    80101ac9 <dedup+0x494>
	    brelse(bp2);
	  
	  iunlockput(ip2);
	} //while ip2
      }	  
      brelse(b1);				// release the outer loop block
80101cfd:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101d00:	89 04 24             	mov    %eax,(%esp)
80101d03:	e8 0f e5 ff ff       	call   80100217 <brelse>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101d08:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d0c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101d13:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d16:	83 c0 0c             	add    $0xc,%eax
80101d19:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101d1c:	0f 8f ee f9 ff ff    	jg     80101710 <dedup+0xdb>
	} //while ip2
      }	  
      brelse(b1);				// release the outer loop block
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101d22:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d25:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d28:	85 c0                	test   %eax,%eax
80101d2a:	74 0b                	je     80101d37 <dedup+0x702>
      brelse(bp1);
80101d2c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101d2f:	89 04 24             	mov    %eax,(%esp)
80101d32:	e8 e0 e4 ff ff       	call   80100217 <brelse>
    
    if(iChanged)
80101d37:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101d3b:	74 0b                	je     80101d48 <dedup+0x713>
      iupdate(ip1);
80101d3d:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d40:	89 04 24             	mov    %eax,(%esp)
80101d43:	e8 e4 03 00 00       	call   8010212c <iupdate>
    iunlockput(ip1);
80101d48:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d4b:	89 04 24             	mov    %eax,(%esp)
80101d4e:	e8 19 08 00 00       	call   8010256c <iunlockput>
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
80101d53:	e8 76 11 00 00       	call   80102ece <getNextInode>
80101d58:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101d5b:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101d5f:	0f 85 52 f9 ff ff    	jne    801016b7 <dedup+0x82>
    if(iChanged)
      iupdate(ip1);
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
80101d65:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101d6a:	c9                   	leave  
80101d6b:	c3                   	ret    

80101d6c <readsb>:
int prevInum = 0;

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101d6c:	55                   	push   %ebp
80101d6d:	89 e5                	mov    %esp,%ebp
80101d6f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101d72:	8b 45 08             	mov    0x8(%ebp),%eax
80101d75:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101d7c:	00 
80101d7d:	89 04 24             	mov    %eax,(%esp)
80101d80:	e8 21 e4 ff ff       	call   801001a6 <bread>
80101d85:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101d88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d8b:	83 c0 18             	add    $0x18,%eax
80101d8e:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101d95:	00 
80101d96:	89 44 24 04          	mov    %eax,0x4(%esp)
80101d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d9d:	89 04 24             	mov    %eax,(%esp)
80101da0:	e8 c4 3c 00 00       	call   80105a69 <memmove>
  brelse(bp);
80101da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101da8:	89 04 24             	mov    %eax,(%esp)
80101dab:	e8 67 e4 ff ff       	call   80100217 <brelse>
}
80101db0:	c9                   	leave  
80101db1:	c3                   	ret    

80101db2 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101db2:	55                   	push   %ebp
80101db3:	89 e5                	mov    %esp,%ebp
80101db5:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101db8:	8b 55 0c             	mov    0xc(%ebp),%edx
80101dbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dc2:	89 04 24             	mov    %eax,(%esp)
80101dc5:	e8 dc e3 ff ff       	call   801001a6 <bread>
80101dca:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101dcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dd0:	83 c0 18             	add    $0x18,%eax
80101dd3:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101dda:	00 
80101ddb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101de2:	00 
80101de3:	89 04 24             	mov    %eax,(%esp)
80101de6:	e8 ab 3b 00 00       	call   80105996 <memset>
  log_write(bp);
80101deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dee:	89 04 24             	mov    %eax,(%esp)
80101df1:	e8 6c 20 00 00       	call   80103e62 <log_write>
  brelse(bp);
80101df6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101df9:	89 04 24             	mov    %eax,(%esp)
80101dfc:	e8 16 e4 ff ff       	call   80100217 <brelse>
}
80101e01:	c9                   	leave  
80101e02:	c3                   	ret    

80101e03 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101e03:	55                   	push   %ebp
80101e04:	89 e5                	mov    %esp,%ebp
80101e06:	53                   	push   %ebx
80101e07:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101e0a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101e11:	8b 45 08             	mov    0x8(%ebp),%eax
80101e14:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101e17:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e1b:	89 04 24             	mov    %eax,(%esp)
80101e1e:	e8 49 ff ff ff       	call   80101d6c <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101e23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e2a:	e9 11 01 00 00       	jmp    80101f40 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e32:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101e38:	85 c0                	test   %eax,%eax
80101e3a:	0f 48 c2             	cmovs  %edx,%eax
80101e3d:	c1 f8 0c             	sar    $0xc,%eax
80101e40:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101e43:	c1 ea 03             	shr    $0x3,%edx
80101e46:	01 d0                	add    %edx,%eax
80101e48:	83 c0 03             	add    $0x3,%eax
80101e4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e52:	89 04 24             	mov    %eax,(%esp)
80101e55:	e8 4c e3 ff ff       	call   801001a6 <bread>
80101e5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101e5d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e64:	e9 a7 00 00 00       	jmp    80101f10 <balloc+0x10d>
      m = 1 << (bi % 8);
80101e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e6c:	89 c2                	mov    %eax,%edx
80101e6e:	c1 fa 1f             	sar    $0x1f,%edx
80101e71:	c1 ea 1d             	shr    $0x1d,%edx
80101e74:	01 d0                	add    %edx,%eax
80101e76:	83 e0 07             	and    $0x7,%eax
80101e79:	29 d0                	sub    %edx,%eax
80101e7b:	ba 01 00 00 00       	mov    $0x1,%edx
80101e80:	89 d3                	mov    %edx,%ebx
80101e82:	89 c1                	mov    %eax,%ecx
80101e84:	d3 e3                	shl    %cl,%ebx
80101e86:	89 d8                	mov    %ebx,%eax
80101e88:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101e8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e8e:	8d 50 07             	lea    0x7(%eax),%edx
80101e91:	85 c0                	test   %eax,%eax
80101e93:	0f 48 c2             	cmovs  %edx,%eax
80101e96:	c1 f8 03             	sar    $0x3,%eax
80101e99:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101e9c:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101ea1:	0f b6 c0             	movzbl %al,%eax
80101ea4:	23 45 e8             	and    -0x18(%ebp),%eax
80101ea7:	85 c0                	test   %eax,%eax
80101ea9:	75 61                	jne    80101f0c <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101eab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eae:	8d 50 07             	lea    0x7(%eax),%edx
80101eb1:	85 c0                	test   %eax,%eax
80101eb3:	0f 48 c2             	cmovs  %edx,%eax
80101eb6:	c1 f8 03             	sar    $0x3,%eax
80101eb9:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ebc:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101ec1:	89 d1                	mov    %edx,%ecx
80101ec3:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101ec6:	09 ca                	or     %ecx,%edx
80101ec8:	89 d1                	mov    %edx,%ecx
80101eca:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ecd:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101ed1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ed4:	89 04 24             	mov    %eax,(%esp)
80101ed7:	e8 86 1f 00 00       	call   80103e62 <log_write>
        brelse(bp);
80101edc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101edf:	89 04 24             	mov    %eax,(%esp)
80101ee2:	e8 30 e3 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101ee7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eea:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101eed:	01 c2                	add    %eax,%edx
80101eef:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ef6:	89 04 24             	mov    %eax,(%esp)
80101ef9:	e8 b4 fe ff ff       	call   80101db2 <bzero>
        return b + bi;
80101efe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f01:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f04:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80101f06:	83 c4 34             	add    $0x34,%esp
80101f09:	5b                   	pop    %ebx
80101f0a:	5d                   	pop    %ebp
80101f0b:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101f0c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101f10:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101f17:	7f 15                	jg     80101f2e <balloc+0x12b>
80101f19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f1f:	01 d0                	add    %edx,%eax
80101f21:	89 c2                	mov    %eax,%edx
80101f23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101f26:	39 c2                	cmp    %eax,%edx
80101f28:	0f 82 3b ff ff ff    	jb     80101e69 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101f2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f31:	89 04 24             	mov    %eax,(%esp)
80101f34:	e8 de e2 ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101f39:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101f40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101f43:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101f46:	39 c2                	cmp    %eax,%edx
80101f48:	0f 82 e1 fe ff ff    	jb     80101e2f <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101f4e:	c7 04 24 0d 90 10 80 	movl   $0x8010900d,(%esp)
80101f55:	e8 e3 e5 ff ff       	call   8010053d <panic>

80101f5a <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
80101f5a:	55                   	push   %ebp
80101f5b:	89 e5                	mov    %esp,%ebp
80101f5d:	53                   	push   %ebx
80101f5e:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101f61:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101f64:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f68:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6b:	89 04 24             	mov    %eax,(%esp)
80101f6e:	e8 f9 fd ff ff       	call   80101d6c <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101f73:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f76:	89 c2                	mov    %eax,%edx
80101f78:	c1 ea 0c             	shr    $0xc,%edx
80101f7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f7e:	c1 e8 03             	shr    $0x3,%eax
80101f81:	01 d0                	add    %edx,%eax
80101f83:	8d 50 03             	lea    0x3(%eax),%edx
80101f86:	8b 45 08             	mov    0x8(%ebp),%eax
80101f89:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f8d:	89 04 24             	mov    %eax,(%esp)
80101f90:	e8 11 e2 ff ff       	call   801001a6 <bread>
80101f95:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101f98:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f9b:	25 ff 0f 00 00       	and    $0xfff,%eax
80101fa0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101fa3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa6:	89 c2                	mov    %eax,%edx
80101fa8:	c1 fa 1f             	sar    $0x1f,%edx
80101fab:	c1 ea 1d             	shr    $0x1d,%edx
80101fae:	01 d0                	add    %edx,%eax
80101fb0:	83 e0 07             	and    $0x7,%eax
80101fb3:	29 d0                	sub    %edx,%eax
80101fb5:	ba 01 00 00 00       	mov    $0x1,%edx
80101fba:	89 d3                	mov    %edx,%ebx
80101fbc:	89 c1                	mov    %eax,%ecx
80101fbe:	d3 e3                	shl    %cl,%ebx
80101fc0:	89 d8                	mov    %ebx,%eax
80101fc2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101fc5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fc8:	8d 50 07             	lea    0x7(%eax),%edx
80101fcb:	85 c0                	test   %eax,%eax
80101fcd:	0f 48 c2             	cmovs  %edx,%eax
80101fd0:	c1 f8 03             	sar    $0x3,%eax
80101fd3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101fd6:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101fdb:	0f b6 c0             	movzbl %al,%eax
80101fde:	23 45 ec             	and    -0x14(%ebp),%eax
80101fe1:	85 c0                	test   %eax,%eax
80101fe3:	75 0c                	jne    80101ff1 <bfree+0x97>
    panic("freeing free block");
80101fe5:	c7 04 24 23 90 10 80 	movl   $0x80109023,(%esp)
80101fec:	e8 4c e5 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101ff1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff4:	8d 50 07             	lea    0x7(%eax),%edx
80101ff7:	85 c0                	test   %eax,%eax
80101ff9:	0f 48 c2             	cmovs  %edx,%eax
80101ffc:	c1 f8 03             	sar    $0x3,%eax
80101fff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102002:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102007:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010200a:	f7 d1                	not    %ecx
8010200c:	21 ca                	and    %ecx,%edx
8010200e:	89 d1                	mov    %edx,%ecx
80102010:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102013:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80102017:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010201a:	89 04 24             	mov    %eax,(%esp)
8010201d:	e8 40 1e 00 00       	call   80103e62 <log_write>
  brelse(bp);
80102022:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102025:	89 04 24             	mov    %eax,(%esp)
80102028:	e8 ea e1 ff ff       	call   80100217 <brelse>
}
8010202d:	83 c4 34             	add    $0x34,%esp
80102030:	5b                   	pop    %ebx
80102031:	5d                   	pop    %ebp
80102032:	c3                   	ret    

80102033 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80102039:	c7 44 24 04 36 90 10 	movl   $0x80109036,0x4(%esp)
80102040:	80 
80102041:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102048:	e8 d9 36 00 00       	call   80105726 <initlock>
}
8010204d:	c9                   	leave  
8010204e:	c3                   	ret    

8010204f <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010204f:	55                   	push   %ebp
80102050:	89 e5                	mov    %esp,%ebp
80102052:	83 ec 48             	sub    $0x48,%esp
80102055:	8b 45 0c             	mov    0xc(%ebp),%eax
80102058:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
8010205c:	8b 45 08             	mov    0x8(%ebp),%eax
8010205f:	8d 55 dc             	lea    -0x24(%ebp),%edx
80102062:	89 54 24 04          	mov    %edx,0x4(%esp)
80102066:	89 04 24             	mov    %eax,(%esp)
80102069:	e8 fe fc ff ff       	call   80101d6c <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010206e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102075:	e9 98 00 00 00       	jmp    80102112 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010207a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010207d:	c1 e8 03             	shr    $0x3,%eax
80102080:	83 c0 02             	add    $0x2,%eax
80102083:	89 44 24 04          	mov    %eax,0x4(%esp)
80102087:	8b 45 08             	mov    0x8(%ebp),%eax
8010208a:	89 04 24             	mov    %eax,(%esp)
8010208d:	e8 14 e1 ff ff       	call   801001a6 <bread>
80102092:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80102095:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102098:	8d 50 18             	lea    0x18(%eax),%edx
8010209b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010209e:	83 e0 07             	and    $0x7,%eax
801020a1:	c1 e0 06             	shl    $0x6,%eax
801020a4:	01 d0                	add    %edx,%eax
801020a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801020a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ac:	0f b7 00             	movzwl (%eax),%eax
801020af:	66 85 c0             	test   %ax,%ax
801020b2:	75 4f                	jne    80102103 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801020b4:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801020bb:	00 
801020bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801020c3:	00 
801020c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020c7:	89 04 24             	mov    %eax,(%esp)
801020ca:	e8 c7 38 00 00       	call   80105996 <memset>
      dip->type = type;
801020cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020d2:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801020d6:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801020d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020dc:	89 04 24             	mov    %eax,(%esp)
801020df:	e8 7e 1d 00 00       	call   80103e62 <log_write>
      brelse(bp);
801020e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e7:	89 04 24             	mov    %eax,(%esp)
801020ea:	e8 28 e1 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801020ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801020f6:	8b 45 08             	mov    0x8(%ebp),%eax
801020f9:	89 04 24             	mov    %eax,(%esp)
801020fc:	e8 e3 00 00 00       	call   801021e4 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80102101:	c9                   	leave  
80102102:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80102103:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102106:	89 04 24             	mov    %eax,(%esp)
80102109:	e8 09 e1 ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010210e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102112:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102115:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102118:	39 c2                	cmp    %eax,%edx
8010211a:	0f 82 5a ff ff ff    	jb     8010207a <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80102120:	c7 04 24 3d 90 10 80 	movl   $0x8010903d,(%esp)
80102127:	e8 11 e4 ff ff       	call   8010053d <panic>

8010212c <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010212c:	55                   	push   %ebp
8010212d:	89 e5                	mov    %esp,%ebp
8010212f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80102132:	8b 45 08             	mov    0x8(%ebp),%eax
80102135:	8b 40 04             	mov    0x4(%eax),%eax
80102138:	c1 e8 03             	shr    $0x3,%eax
8010213b:	8d 50 02             	lea    0x2(%eax),%edx
8010213e:	8b 45 08             	mov    0x8(%ebp),%eax
80102141:	8b 00                	mov    (%eax),%eax
80102143:	89 54 24 04          	mov    %edx,0x4(%esp)
80102147:	89 04 24             	mov    %eax,(%esp)
8010214a:	e8 57 e0 ff ff       	call   801001a6 <bread>
8010214f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80102152:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102155:	8d 50 18             	lea    0x18(%eax),%edx
80102158:	8b 45 08             	mov    0x8(%ebp),%eax
8010215b:	8b 40 04             	mov    0x4(%eax),%eax
8010215e:	83 e0 07             	and    $0x7,%eax
80102161:	c1 e0 06             	shl    $0x6,%eax
80102164:	01 d0                	add    %edx,%eax
80102166:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80102169:	8b 45 08             	mov    0x8(%ebp),%eax
8010216c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102170:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102173:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80102176:	8b 45 08             	mov    0x8(%ebp),%eax
80102179:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010217d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102180:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102184:	8b 45 08             	mov    0x8(%ebp),%eax
80102187:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010218b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010218e:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80102192:	8b 45 08             	mov    0x8(%ebp),%eax
80102195:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102199:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010219c:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801021a0:	8b 45 08             	mov    0x8(%ebp),%eax
801021a3:	8b 50 18             	mov    0x18(%eax),%edx
801021a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021a9:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801021ac:	8b 45 08             	mov    0x8(%ebp),%eax
801021af:	8d 50 1c             	lea    0x1c(%eax),%edx
801021b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021b5:	83 c0 0c             	add    $0xc,%eax
801021b8:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801021bf:	00 
801021c0:	89 54 24 04          	mov    %edx,0x4(%esp)
801021c4:	89 04 24             	mov    %eax,(%esp)
801021c7:	e8 9d 38 00 00       	call   80105a69 <memmove>
  log_write(bp);
801021cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021cf:	89 04 24             	mov    %eax,(%esp)
801021d2:	e8 8b 1c 00 00       	call   80103e62 <log_write>
  brelse(bp);
801021d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021da:	89 04 24             	mov    %eax,(%esp)
801021dd:	e8 35 e0 ff ff       	call   80100217 <brelse>
}
801021e2:	c9                   	leave  
801021e3:	c3                   	ret    

801021e4 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801021e4:	55                   	push   %ebp
801021e5:	89 e5                	mov    %esp,%ebp
801021e7:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801021ea:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801021f1:	e8 51 35 00 00       	call   80105747 <acquire>

  // Is the inode already cached?
  empty = 0;
801021f6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801021fd:	c7 45 f4 b4 f8 10 80 	movl   $0x8010f8b4,-0xc(%ebp)
80102204:	eb 59                	jmp    8010225f <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80102206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102209:	8b 40 08             	mov    0x8(%eax),%eax
8010220c:	85 c0                	test   %eax,%eax
8010220e:	7e 35                	jle    80102245 <iget+0x61>
80102210:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102213:	8b 00                	mov    (%eax),%eax
80102215:	3b 45 08             	cmp    0x8(%ebp),%eax
80102218:	75 2b                	jne    80102245 <iget+0x61>
8010221a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010221d:	8b 40 04             	mov    0x4(%eax),%eax
80102220:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102223:	75 20                	jne    80102245 <iget+0x61>
      ip->ref++;
80102225:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102228:	8b 40 08             	mov    0x8(%eax),%eax
8010222b:	8d 50 01             	lea    0x1(%eax),%edx
8010222e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102231:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102234:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010223b:	e8 69 35 00 00       	call   801057a9 <release>
      return ip;
80102240:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102243:	eb 6f                	jmp    801022b4 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102245:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102249:	75 10                	jne    8010225b <iget+0x77>
8010224b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010224e:	8b 40 08             	mov    0x8(%eax),%eax
80102251:	85 c0                	test   %eax,%eax
80102253:	75 06                	jne    8010225b <iget+0x77>
      empty = ip;
80102255:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102258:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010225b:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010225f:	81 7d f4 54 08 11 80 	cmpl   $0x80110854,-0xc(%ebp)
80102266:	72 9e                	jb     80102206 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80102268:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010226c:	75 0c                	jne    8010227a <iget+0x96>
    panic("iget: no inodes");
8010226e:	c7 04 24 4f 90 10 80 	movl   $0x8010904f,(%esp)
80102275:	e8 c3 e2 ff ff       	call   8010053d <panic>

  ip = empty;
8010227a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010227d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80102280:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102283:	8b 55 08             	mov    0x8(%ebp),%edx
80102286:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80102288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010228b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010228e:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80102291:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102294:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010229b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010229e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801022a5:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022ac:	e8 f8 34 00 00       	call   801057a9 <release>

  return ip;
801022b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801022b4:	c9                   	leave  
801022b5:	c3                   	ret    

801022b6 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801022b6:	55                   	push   %ebp
801022b7:	89 e5                	mov    %esp,%ebp
801022b9:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801022bc:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022c3:	e8 7f 34 00 00       	call   80105747 <acquire>
  ip->ref++;
801022c8:	8b 45 08             	mov    0x8(%ebp),%eax
801022cb:	8b 40 08             	mov    0x8(%eax),%eax
801022ce:	8d 50 01             	lea    0x1(%eax),%edx
801022d1:	8b 45 08             	mov    0x8(%ebp),%eax
801022d4:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801022d7:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022de:	e8 c6 34 00 00       	call   801057a9 <release>
  return ip;
801022e3:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022e6:	c9                   	leave  
801022e7:	c3                   	ret    

801022e8 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801022e8:	55                   	push   %ebp
801022e9:	89 e5                	mov    %esp,%ebp
801022eb:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801022ee:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801022f2:	74 0a                	je     801022fe <ilock+0x16>
801022f4:	8b 45 08             	mov    0x8(%ebp),%eax
801022f7:	8b 40 08             	mov    0x8(%eax),%eax
801022fa:	85 c0                	test   %eax,%eax
801022fc:	7f 0c                	jg     8010230a <ilock+0x22>
    panic("ilock");
801022fe:	c7 04 24 5f 90 10 80 	movl   $0x8010905f,(%esp)
80102305:	e8 33 e2 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010230a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102311:	e8 31 34 00 00       	call   80105747 <acquire>
  while(ip->flags & I_BUSY)
80102316:	eb 13                	jmp    8010232b <ilock+0x43>
    sleep(ip, &icache.lock);
80102318:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010231f:	80 
80102320:	8b 45 08             	mov    0x8(%ebp),%eax
80102323:	89 04 24             	mov    %eax,(%esp)
80102326:	e8 3e 31 00 00       	call   80105469 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010232b:	8b 45 08             	mov    0x8(%ebp),%eax
8010232e:	8b 40 0c             	mov    0xc(%eax),%eax
80102331:	83 e0 01             	and    $0x1,%eax
80102334:	84 c0                	test   %al,%al
80102336:	75 e0                	jne    80102318 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80102338:	8b 45 08             	mov    0x8(%ebp),%eax
8010233b:	8b 40 0c             	mov    0xc(%eax),%eax
8010233e:	89 c2                	mov    %eax,%edx
80102340:	83 ca 01             	or     $0x1,%edx
80102343:	8b 45 08             	mov    0x8(%ebp),%eax
80102346:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80102349:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102350:	e8 54 34 00 00       	call   801057a9 <release>

  if(!(ip->flags & I_VALID)){
80102355:	8b 45 08             	mov    0x8(%ebp),%eax
80102358:	8b 40 0c             	mov    0xc(%eax),%eax
8010235b:	83 e0 02             	and    $0x2,%eax
8010235e:	85 c0                	test   %eax,%eax
80102360:	0f 85 ce 00 00 00    	jne    80102434 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80102366:	8b 45 08             	mov    0x8(%ebp),%eax
80102369:	8b 40 04             	mov    0x4(%eax),%eax
8010236c:	c1 e8 03             	shr    $0x3,%eax
8010236f:	8d 50 02             	lea    0x2(%eax),%edx
80102372:	8b 45 08             	mov    0x8(%ebp),%eax
80102375:	8b 00                	mov    (%eax),%eax
80102377:	89 54 24 04          	mov    %edx,0x4(%esp)
8010237b:	89 04 24             	mov    %eax,(%esp)
8010237e:	e8 23 de ff ff       	call   801001a6 <bread>
80102383:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80102386:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102389:	8d 50 18             	lea    0x18(%eax),%edx
8010238c:	8b 45 08             	mov    0x8(%ebp),%eax
8010238f:	8b 40 04             	mov    0x4(%eax),%eax
80102392:	83 e0 07             	and    $0x7,%eax
80102395:	c1 e0 06             	shl    $0x6,%eax
80102398:	01 d0                	add    %edx,%eax
8010239a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010239d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023a0:	0f b7 10             	movzwl (%eax),%edx
801023a3:	8b 45 08             	mov    0x8(%ebp),%eax
801023a6:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801023aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ad:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801023b1:	8b 45 08             	mov    0x8(%ebp),%eax
801023b4:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801023b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023bb:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801023bf:	8b 45 08             	mov    0x8(%ebp),%eax
801023c2:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801023c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801023cd:	8b 45 08             	mov    0x8(%ebp),%eax
801023d0:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801023d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023d7:	8b 50 08             	mov    0x8(%eax),%edx
801023da:	8b 45 08             	mov    0x8(%ebp),%eax
801023dd:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801023e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023e3:	8d 50 0c             	lea    0xc(%eax),%edx
801023e6:	8b 45 08             	mov    0x8(%ebp),%eax
801023e9:	83 c0 1c             	add    $0x1c,%eax
801023ec:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801023f3:	00 
801023f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801023f8:	89 04 24             	mov    %eax,(%esp)
801023fb:	e8 69 36 00 00       	call   80105a69 <memmove>
    brelse(bp);
80102400:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102403:	89 04 24             	mov    %eax,(%esp)
80102406:	e8 0c de ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010240b:	8b 45 08             	mov    0x8(%ebp),%eax
8010240e:	8b 40 0c             	mov    0xc(%eax),%eax
80102411:	89 c2                	mov    %eax,%edx
80102413:	83 ca 02             	or     $0x2,%edx
80102416:	8b 45 08             	mov    0x8(%ebp),%eax
80102419:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010241c:	8b 45 08             	mov    0x8(%ebp),%eax
8010241f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102423:	66 85 c0             	test   %ax,%ax
80102426:	75 0c                	jne    80102434 <ilock+0x14c>
      panic("ilock: no type");
80102428:	c7 04 24 65 90 10 80 	movl   $0x80109065,(%esp)
8010242f:	e8 09 e1 ff ff       	call   8010053d <panic>
  }
}
80102434:	c9                   	leave  
80102435:	c3                   	ret    

80102436 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80102436:	55                   	push   %ebp
80102437:	89 e5                	mov    %esp,%ebp
80102439:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
8010243c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102440:	74 17                	je     80102459 <iunlock+0x23>
80102442:	8b 45 08             	mov    0x8(%ebp),%eax
80102445:	8b 40 0c             	mov    0xc(%eax),%eax
80102448:	83 e0 01             	and    $0x1,%eax
8010244b:	85 c0                	test   %eax,%eax
8010244d:	74 0a                	je     80102459 <iunlock+0x23>
8010244f:	8b 45 08             	mov    0x8(%ebp),%eax
80102452:	8b 40 08             	mov    0x8(%eax),%eax
80102455:	85 c0                	test   %eax,%eax
80102457:	7f 0c                	jg     80102465 <iunlock+0x2f>
    panic("iunlock");
80102459:	c7 04 24 74 90 10 80 	movl   $0x80109074,(%esp)
80102460:	e8 d8 e0 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102465:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010246c:	e8 d6 32 00 00       	call   80105747 <acquire>
  ip->flags &= ~I_BUSY;
80102471:	8b 45 08             	mov    0x8(%ebp),%eax
80102474:	8b 40 0c             	mov    0xc(%eax),%eax
80102477:	89 c2                	mov    %eax,%edx
80102479:	83 e2 fe             	and    $0xfffffffe,%edx
8010247c:	8b 45 08             	mov    0x8(%ebp),%eax
8010247f:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102482:	8b 45 08             	mov    0x8(%ebp),%eax
80102485:	89 04 24             	mov    %eax,(%esp)
80102488:	e8 b5 30 00 00       	call   80105542 <wakeup>
  release(&icache.lock);
8010248d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102494:	e8 10 33 00 00       	call   801057a9 <release>
}
80102499:	c9                   	leave  
8010249a:	c3                   	ret    

8010249b <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
8010249b:	55                   	push   %ebp
8010249c:	89 e5                	mov    %esp,%ebp
8010249e:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801024a1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801024a8:	e8 9a 32 00 00       	call   80105747 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801024ad:	8b 45 08             	mov    0x8(%ebp),%eax
801024b0:	8b 40 08             	mov    0x8(%eax),%eax
801024b3:	83 f8 01             	cmp    $0x1,%eax
801024b6:	0f 85 93 00 00 00    	jne    8010254f <iput+0xb4>
801024bc:	8b 45 08             	mov    0x8(%ebp),%eax
801024bf:	8b 40 0c             	mov    0xc(%eax),%eax
801024c2:	83 e0 02             	and    $0x2,%eax
801024c5:	85 c0                	test   %eax,%eax
801024c7:	0f 84 82 00 00 00    	je     8010254f <iput+0xb4>
801024cd:	8b 45 08             	mov    0x8(%ebp),%eax
801024d0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801024d4:	66 85 c0             	test   %ax,%ax
801024d7:	75 76                	jne    8010254f <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801024d9:	8b 45 08             	mov    0x8(%ebp),%eax
801024dc:	8b 40 0c             	mov    0xc(%eax),%eax
801024df:	83 e0 01             	and    $0x1,%eax
801024e2:	84 c0                	test   %al,%al
801024e4:	74 0c                	je     801024f2 <iput+0x57>
      panic("iput busy");
801024e6:	c7 04 24 7c 90 10 80 	movl   $0x8010907c,(%esp)
801024ed:	e8 4b e0 ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801024f2:	8b 45 08             	mov    0x8(%ebp),%eax
801024f5:	8b 40 0c             	mov    0xc(%eax),%eax
801024f8:	89 c2                	mov    %eax,%edx
801024fa:	83 ca 01             	or     $0x1,%edx
801024fd:	8b 45 08             	mov    0x8(%ebp),%eax
80102500:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80102503:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010250a:	e8 9a 32 00 00       	call   801057a9 <release>
    itrunc(ip);
8010250f:	8b 45 08             	mov    0x8(%ebp),%eax
80102512:	89 04 24             	mov    %eax,(%esp)
80102515:	e8 72 01 00 00       	call   8010268c <itrunc>
    ip->type = 0;
8010251a:	8b 45 08             	mov    0x8(%ebp),%eax
8010251d:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80102523:	8b 45 08             	mov    0x8(%ebp),%eax
80102526:	89 04 24             	mov    %eax,(%esp)
80102529:	e8 fe fb ff ff       	call   8010212c <iupdate>
    acquire(&icache.lock);
8010252e:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102535:	e8 0d 32 00 00       	call   80105747 <acquire>
    ip->flags = 0;
8010253a:	8b 45 08             	mov    0x8(%ebp),%eax
8010253d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102544:	8b 45 08             	mov    0x8(%ebp),%eax
80102547:	89 04 24             	mov    %eax,(%esp)
8010254a:	e8 f3 2f 00 00       	call   80105542 <wakeup>
  }
  ip->ref--;
8010254f:	8b 45 08             	mov    0x8(%ebp),%eax
80102552:	8b 40 08             	mov    0x8(%eax),%eax
80102555:	8d 50 ff             	lea    -0x1(%eax),%edx
80102558:	8b 45 08             	mov    0x8(%ebp),%eax
8010255b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010255e:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102565:	e8 3f 32 00 00       	call   801057a9 <release>
}
8010256a:	c9                   	leave  
8010256b:	c3                   	ret    

8010256c <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
8010256c:	55                   	push   %ebp
8010256d:	89 e5                	mov    %esp,%ebp
8010256f:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102572:	8b 45 08             	mov    0x8(%ebp),%eax
80102575:	89 04 24             	mov    %eax,(%esp)
80102578:	e8 b9 fe ff ff       	call   80102436 <iunlock>
  iput(ip);
8010257d:	8b 45 08             	mov    0x8(%ebp),%eax
80102580:	89 04 24             	mov    %eax,(%esp)
80102583:	e8 13 ff ff ff       	call   8010249b <iput>
}
80102588:	c9                   	leave  
80102589:	c3                   	ret    

8010258a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010258a:	55                   	push   %ebp
8010258b:	89 e5                	mov    %esp,%ebp
8010258d:	53                   	push   %ebx
8010258e:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102591:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80102595:	77 3e                	ja     801025d5 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80102597:	8b 45 08             	mov    0x8(%ebp),%eax
8010259a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010259d:	83 c2 04             	add    $0x4,%edx
801025a0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801025a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025a7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801025ab:	75 20                	jne    801025cd <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801025ad:	8b 45 08             	mov    0x8(%ebp),%eax
801025b0:	8b 00                	mov    (%eax),%eax
801025b2:	89 04 24             	mov    %eax,(%esp)
801025b5:	e8 49 f8 ff ff       	call   80101e03 <balloc>
801025ba:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025bd:	8b 45 08             	mov    0x8(%ebp),%eax
801025c0:	8b 55 0c             	mov    0xc(%ebp),%edx
801025c3:	8d 4a 04             	lea    0x4(%edx),%ecx
801025c6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801025c9:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801025cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025d0:	e9 b1 00 00 00       	jmp    80102686 <bmap+0xfc>
  }
  bn -= NDIRECT;
801025d5:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801025d9:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801025dd:	0f 87 97 00 00 00    	ja     8010267a <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801025e3:	8b 45 08             	mov    0x8(%ebp),%eax
801025e6:	8b 40 4c             	mov    0x4c(%eax),%eax
801025e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801025ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801025f0:	75 19                	jne    8010260b <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801025f2:	8b 45 08             	mov    0x8(%ebp),%eax
801025f5:	8b 00                	mov    (%eax),%eax
801025f7:	89 04 24             	mov    %eax,(%esp)
801025fa:	e8 04 f8 ff ff       	call   80101e03 <balloc>
801025ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102602:	8b 45 08             	mov    0x8(%ebp),%eax
80102605:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102608:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
8010260b:	8b 45 08             	mov    0x8(%ebp),%eax
8010260e:	8b 00                	mov    (%eax),%eax
80102610:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102613:	89 54 24 04          	mov    %edx,0x4(%esp)
80102617:	89 04 24             	mov    %eax,(%esp)
8010261a:	e8 87 db ff ff       	call   801001a6 <bread>
8010261f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80102622:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102625:	83 c0 18             	add    $0x18,%eax
80102628:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
8010262b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010262e:	c1 e0 02             	shl    $0x2,%eax
80102631:	03 45 ec             	add    -0x14(%ebp),%eax
80102634:	8b 00                	mov    (%eax),%eax
80102636:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102639:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010263d:	75 2b                	jne    8010266a <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
8010263f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102642:	c1 e0 02             	shl    $0x2,%eax
80102645:	89 c3                	mov    %eax,%ebx
80102647:	03 5d ec             	add    -0x14(%ebp),%ebx
8010264a:	8b 45 08             	mov    0x8(%ebp),%eax
8010264d:	8b 00                	mov    (%eax),%eax
8010264f:	89 04 24             	mov    %eax,(%esp)
80102652:	e8 ac f7 ff ff       	call   80101e03 <balloc>
80102657:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010265a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010265d:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010265f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102662:	89 04 24             	mov    %eax,(%esp)
80102665:	e8 f8 17 00 00       	call   80103e62 <log_write>
    }
    brelse(bp);
8010266a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010266d:	89 04 24             	mov    %eax,(%esp)
80102670:	e8 a2 db ff ff       	call   80100217 <brelse>
    return addr;
80102675:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102678:	eb 0c                	jmp    80102686 <bmap+0xfc>
  }

  panic("bmap: out of range");
8010267a:	c7 04 24 86 90 10 80 	movl   $0x80109086,(%esp)
80102681:	e8 b7 de ff ff       	call   8010053d <panic>
}
80102686:	83 c4 24             	add    $0x24,%esp
80102689:	5b                   	pop    %ebx
8010268a:	5d                   	pop    %ebp
8010268b:	c3                   	ret    

8010268c <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
8010268c:	55                   	push   %ebp
8010268d:	89 e5                	mov    %esp,%ebp
8010268f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102692:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102699:	eb 44                	jmp    801026df <itrunc+0x53>
    if(ip->addrs[i]){
8010269b:	8b 45 08             	mov    0x8(%ebp),%eax
8010269e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026a1:	83 c2 04             	add    $0x4,%edx
801026a4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801026a8:	85 c0                	test   %eax,%eax
801026aa:	74 2f                	je     801026db <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801026ac:	8b 45 08             	mov    0x8(%ebp),%eax
801026af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026b2:	83 c2 04             	add    $0x4,%edx
801026b5:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801026b9:	8b 45 08             	mov    0x8(%ebp),%eax
801026bc:	8b 00                	mov    (%eax),%eax
801026be:	89 54 24 04          	mov    %edx,0x4(%esp)
801026c2:	89 04 24             	mov    %eax,(%esp)
801026c5:	e8 90 f8 ff ff       	call   80101f5a <bfree>
      ip->addrs[i] = 0;
801026ca:	8b 45 08             	mov    0x8(%ebp),%eax
801026cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026d0:	83 c2 04             	add    $0x4,%edx
801026d3:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801026da:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801026db:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026df:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801026e3:	7e b6                	jle    8010269b <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801026e5:	8b 45 08             	mov    0x8(%ebp),%eax
801026e8:	8b 40 4c             	mov    0x4c(%eax),%eax
801026eb:	85 c0                	test   %eax,%eax
801026ed:	0f 84 8f 00 00 00    	je     80102782 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801026f3:	8b 45 08             	mov    0x8(%ebp),%eax
801026f6:	8b 50 4c             	mov    0x4c(%eax),%edx
801026f9:	8b 45 08             	mov    0x8(%ebp),%eax
801026fc:	8b 00                	mov    (%eax),%eax
801026fe:	89 54 24 04          	mov    %edx,0x4(%esp)
80102702:	89 04 24             	mov    %eax,(%esp)
80102705:	e8 9c da ff ff       	call   801001a6 <bread>
8010270a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
8010270d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102710:	83 c0 18             	add    $0x18,%eax
80102713:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102716:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010271d:	eb 2f                	jmp    8010274e <itrunc+0xc2>
      if(a[j])
8010271f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102722:	c1 e0 02             	shl    $0x2,%eax
80102725:	03 45 e8             	add    -0x18(%ebp),%eax
80102728:	8b 00                	mov    (%eax),%eax
8010272a:	85 c0                	test   %eax,%eax
8010272c:	74 1c                	je     8010274a <itrunc+0xbe>
        bfree(ip->dev, a[j]);
8010272e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102731:	c1 e0 02             	shl    $0x2,%eax
80102734:	03 45 e8             	add    -0x18(%ebp),%eax
80102737:	8b 10                	mov    (%eax),%edx
80102739:	8b 45 08             	mov    0x8(%ebp),%eax
8010273c:	8b 00                	mov    (%eax),%eax
8010273e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102742:	89 04 24             	mov    %eax,(%esp)
80102745:	e8 10 f8 ff ff       	call   80101f5a <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
8010274a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010274e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102751:	83 f8 7f             	cmp    $0x7f,%eax
80102754:	76 c9                	jbe    8010271f <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102756:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102759:	89 04 24             	mov    %eax,(%esp)
8010275c:	e8 b6 da ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102761:	8b 45 08             	mov    0x8(%ebp),%eax
80102764:	8b 50 4c             	mov    0x4c(%eax),%edx
80102767:	8b 45 08             	mov    0x8(%ebp),%eax
8010276a:	8b 00                	mov    (%eax),%eax
8010276c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102770:	89 04 24             	mov    %eax,(%esp)
80102773:	e8 e2 f7 ff ff       	call   80101f5a <bfree>
    ip->addrs[NDIRECT] = 0;
80102778:	8b 45 08             	mov    0x8(%ebp),%eax
8010277b:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102782:	8b 45 08             	mov    0x8(%ebp),%eax
80102785:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
8010278c:	8b 45 08             	mov    0x8(%ebp),%eax
8010278f:	89 04 24             	mov    %eax,(%esp)
80102792:	e8 95 f9 ff ff       	call   8010212c <iupdate>
}
80102797:	c9                   	leave  
80102798:	c3                   	ret    

80102799 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102799:	55                   	push   %ebp
8010279a:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
8010279c:	8b 45 08             	mov    0x8(%ebp),%eax
8010279f:	8b 00                	mov    (%eax),%eax
801027a1:	89 c2                	mov    %eax,%edx
801027a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801027a6:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801027a9:	8b 45 08             	mov    0x8(%ebp),%eax
801027ac:	8b 50 04             	mov    0x4(%eax),%edx
801027af:	8b 45 0c             	mov    0xc(%ebp),%eax
801027b2:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801027b5:	8b 45 08             	mov    0x8(%ebp),%eax
801027b8:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801027bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801027bf:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801027c2:	8b 45 08             	mov    0x8(%ebp),%eax
801027c5:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801027c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801027cc:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801027d0:	8b 45 08             	mov    0x8(%ebp),%eax
801027d3:	8b 50 18             	mov    0x18(%eax),%edx
801027d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801027d9:	89 50 10             	mov    %edx,0x10(%eax)
}
801027dc:	5d                   	pop    %ebp
801027dd:	c3                   	ret    

801027de <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801027de:	55                   	push   %ebp
801027df:	89 e5                	mov    %esp,%ebp
801027e1:	53                   	push   %ebx
801027e2:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801027e5:	8b 45 08             	mov    0x8(%ebp),%eax
801027e8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027ec:	66 83 f8 03          	cmp    $0x3,%ax
801027f0:	75 60                	jne    80102852 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801027f2:	8b 45 08             	mov    0x8(%ebp),%eax
801027f5:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801027f9:	66 85 c0             	test   %ax,%ax
801027fc:	78 20                	js     8010281e <readi+0x40>
801027fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102801:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102805:	66 83 f8 09          	cmp    $0x9,%ax
80102809:	7f 13                	jg     8010281e <readi+0x40>
8010280b:	8b 45 08             	mov    0x8(%ebp),%eax
8010280e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102812:	98                   	cwtl   
80102813:	8b 04 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%eax
8010281a:	85 c0                	test   %eax,%eax
8010281c:	75 0a                	jne    80102828 <readi+0x4a>
      return -1;
8010281e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102823:	e9 1b 01 00 00       	jmp    80102943 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102828:	8b 45 08             	mov    0x8(%ebp),%eax
8010282b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010282f:	98                   	cwtl   
80102830:	8b 14 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%edx
80102837:	8b 45 14             	mov    0x14(%ebp),%eax
8010283a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010283e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102841:	89 44 24 04          	mov    %eax,0x4(%esp)
80102845:	8b 45 08             	mov    0x8(%ebp),%eax
80102848:	89 04 24             	mov    %eax,(%esp)
8010284b:	ff d2                	call   *%edx
8010284d:	e9 f1 00 00 00       	jmp    80102943 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102852:	8b 45 08             	mov    0x8(%ebp),%eax
80102855:	8b 40 18             	mov    0x18(%eax),%eax
80102858:	3b 45 10             	cmp    0x10(%ebp),%eax
8010285b:	72 0d                	jb     8010286a <readi+0x8c>
8010285d:	8b 45 14             	mov    0x14(%ebp),%eax
80102860:	8b 55 10             	mov    0x10(%ebp),%edx
80102863:	01 d0                	add    %edx,%eax
80102865:	3b 45 10             	cmp    0x10(%ebp),%eax
80102868:	73 0a                	jae    80102874 <readi+0x96>
    return -1;
8010286a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010286f:	e9 cf 00 00 00       	jmp    80102943 <readi+0x165>
  if(off + n > ip->size)
80102874:	8b 45 14             	mov    0x14(%ebp),%eax
80102877:	8b 55 10             	mov    0x10(%ebp),%edx
8010287a:	01 c2                	add    %eax,%edx
8010287c:	8b 45 08             	mov    0x8(%ebp),%eax
8010287f:	8b 40 18             	mov    0x18(%eax),%eax
80102882:	39 c2                	cmp    %eax,%edx
80102884:	76 0c                	jbe    80102892 <readi+0xb4>
    n = ip->size - off;
80102886:	8b 45 08             	mov    0x8(%ebp),%eax
80102889:	8b 40 18             	mov    0x18(%eax),%eax
8010288c:	2b 45 10             	sub    0x10(%ebp),%eax
8010288f:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102892:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102899:	e9 96 00 00 00       	jmp    80102934 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010289e:	8b 45 10             	mov    0x10(%ebp),%eax
801028a1:	c1 e8 09             	shr    $0x9,%eax
801028a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801028a8:	8b 45 08             	mov    0x8(%ebp),%eax
801028ab:	89 04 24             	mov    %eax,(%esp)
801028ae:	e8 d7 fc ff ff       	call   8010258a <bmap>
801028b3:	8b 55 08             	mov    0x8(%ebp),%edx
801028b6:	8b 12                	mov    (%edx),%edx
801028b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801028bc:	89 14 24             	mov    %edx,(%esp)
801028bf:	e8 e2 d8 ff ff       	call   801001a6 <bread>
801028c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801028c7:	8b 45 10             	mov    0x10(%ebp),%eax
801028ca:	89 c2                	mov    %eax,%edx
801028cc:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801028d2:	b8 00 02 00 00       	mov    $0x200,%eax
801028d7:	89 c1                	mov    %eax,%ecx
801028d9:	29 d1                	sub    %edx,%ecx
801028db:	89 ca                	mov    %ecx,%edx
801028dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028e0:	8b 4d 14             	mov    0x14(%ebp),%ecx
801028e3:	89 cb                	mov    %ecx,%ebx
801028e5:	29 c3                	sub    %eax,%ebx
801028e7:	89 d8                	mov    %ebx,%eax
801028e9:	39 c2                	cmp    %eax,%edx
801028eb:	0f 46 c2             	cmovbe %edx,%eax
801028ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801028f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801028f4:	8d 50 18             	lea    0x18(%eax),%edx
801028f7:	8b 45 10             	mov    0x10(%ebp),%eax
801028fa:	25 ff 01 00 00       	and    $0x1ff,%eax
801028ff:	01 c2                	add    %eax,%edx
80102901:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102904:	89 44 24 08          	mov    %eax,0x8(%esp)
80102908:	89 54 24 04          	mov    %edx,0x4(%esp)
8010290c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010290f:	89 04 24             	mov    %eax,(%esp)
80102912:	e8 52 31 00 00       	call   80105a69 <memmove>
    brelse(bp);
80102917:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010291a:	89 04 24             	mov    %eax,(%esp)
8010291d:	e8 f5 d8 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102922:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102925:	01 45 f4             	add    %eax,-0xc(%ebp)
80102928:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010292b:	01 45 10             	add    %eax,0x10(%ebp)
8010292e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102931:	01 45 0c             	add    %eax,0xc(%ebp)
80102934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102937:	3b 45 14             	cmp    0x14(%ebp),%eax
8010293a:	0f 82 5e ff ff ff    	jb     8010289e <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102940:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102943:	83 c4 24             	add    $0x24,%esp
80102946:	5b                   	pop    %ebx
80102947:	5d                   	pop    %ebp
80102948:	c3                   	ret    

80102949 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102949:	55                   	push   %ebp
8010294a:	89 e5                	mov    %esp,%ebp
8010294c:	53                   	push   %ebx
8010294d:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102950:	8b 45 08             	mov    0x8(%ebp),%eax
80102953:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102957:	66 83 f8 03          	cmp    $0x3,%ax
8010295b:	75 60                	jne    801029bd <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
8010295d:	8b 45 08             	mov    0x8(%ebp),%eax
80102960:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102964:	66 85 c0             	test   %ax,%ax
80102967:	78 20                	js     80102989 <writei+0x40>
80102969:	8b 45 08             	mov    0x8(%ebp),%eax
8010296c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102970:	66 83 f8 09          	cmp    $0x9,%ax
80102974:	7f 13                	jg     80102989 <writei+0x40>
80102976:	8b 45 08             	mov    0x8(%ebp),%eax
80102979:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010297d:	98                   	cwtl   
8010297e:	8b 04 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%eax
80102985:	85 c0                	test   %eax,%eax
80102987:	75 0a                	jne    80102993 <writei+0x4a>
      return -1;
80102989:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010298e:	e9 46 01 00 00       	jmp    80102ad9 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80102993:	8b 45 08             	mov    0x8(%ebp),%eax
80102996:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010299a:	98                   	cwtl   
8010299b:	8b 14 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%edx
801029a2:	8b 45 14             	mov    0x14(%ebp),%eax
801029a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801029a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801029ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801029b0:	8b 45 08             	mov    0x8(%ebp),%eax
801029b3:	89 04 24             	mov    %eax,(%esp)
801029b6:	ff d2                	call   *%edx
801029b8:	e9 1c 01 00 00       	jmp    80102ad9 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
801029bd:	8b 45 08             	mov    0x8(%ebp),%eax
801029c0:	8b 40 18             	mov    0x18(%eax),%eax
801029c3:	3b 45 10             	cmp    0x10(%ebp),%eax
801029c6:	72 0d                	jb     801029d5 <writei+0x8c>
801029c8:	8b 45 14             	mov    0x14(%ebp),%eax
801029cb:	8b 55 10             	mov    0x10(%ebp),%edx
801029ce:	01 d0                	add    %edx,%eax
801029d0:	3b 45 10             	cmp    0x10(%ebp),%eax
801029d3:	73 0a                	jae    801029df <writei+0x96>
    return -1;
801029d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801029da:	e9 fa 00 00 00       	jmp    80102ad9 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
801029df:	8b 45 14             	mov    0x14(%ebp),%eax
801029e2:	8b 55 10             	mov    0x10(%ebp),%edx
801029e5:	01 d0                	add    %edx,%eax
801029e7:	3d 00 18 01 00       	cmp    $0x11800,%eax
801029ec:	76 0a                	jbe    801029f8 <writei+0xaf>
    return -1;
801029ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801029f3:	e9 e1 00 00 00       	jmp    80102ad9 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801029f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029ff:	e9 a1 00 00 00       	jmp    80102aa5 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102a04:	8b 45 10             	mov    0x10(%ebp),%eax
80102a07:	c1 e8 09             	shr    $0x9,%eax
80102a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a11:	89 04 24             	mov    %eax,(%esp)
80102a14:	e8 71 fb ff ff       	call   8010258a <bmap>
80102a19:	8b 55 08             	mov    0x8(%ebp),%edx
80102a1c:	8b 12                	mov    (%edx),%edx
80102a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a22:	89 14 24             	mov    %edx,(%esp)
80102a25:	e8 7c d7 ff ff       	call   801001a6 <bread>
80102a2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102a2d:	8b 45 10             	mov    0x10(%ebp),%eax
80102a30:	89 c2                	mov    %eax,%edx
80102a32:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102a38:	b8 00 02 00 00       	mov    $0x200,%eax
80102a3d:	89 c1                	mov    %eax,%ecx
80102a3f:	29 d1                	sub    %edx,%ecx
80102a41:	89 ca                	mov    %ecx,%edx
80102a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a46:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102a49:	89 cb                	mov    %ecx,%ebx
80102a4b:	29 c3                	sub    %eax,%ebx
80102a4d:	89 d8                	mov    %ebx,%eax
80102a4f:	39 c2                	cmp    %eax,%edx
80102a51:	0f 46 c2             	cmovbe %edx,%eax
80102a54:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102a57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a5a:	8d 50 18             	lea    0x18(%eax),%edx
80102a5d:	8b 45 10             	mov    0x10(%ebp),%eax
80102a60:	25 ff 01 00 00       	and    $0x1ff,%eax
80102a65:	01 c2                	add    %eax,%edx
80102a67:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a6a:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a71:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a75:	89 14 24             	mov    %edx,(%esp)
80102a78:	e8 ec 2f 00 00       	call   80105a69 <memmove>
    log_write(bp);
80102a7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a80:	89 04 24             	mov    %eax,(%esp)
80102a83:	e8 da 13 00 00       	call   80103e62 <log_write>
    brelse(bp);
80102a88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a8b:	89 04 24             	mov    %eax,(%esp)
80102a8e:	e8 84 d7 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102a93:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a96:	01 45 f4             	add    %eax,-0xc(%ebp)
80102a99:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a9c:	01 45 10             	add    %eax,0x10(%ebp)
80102a9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102aa2:	01 45 0c             	add    %eax,0xc(%ebp)
80102aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aa8:	3b 45 14             	cmp    0x14(%ebp),%eax
80102aab:	0f 82 53 ff ff ff    	jb     80102a04 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102ab1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102ab5:	74 1f                	je     80102ad6 <writei+0x18d>
80102ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80102aba:	8b 40 18             	mov    0x18(%eax),%eax
80102abd:	3b 45 10             	cmp    0x10(%ebp),%eax
80102ac0:	73 14                	jae    80102ad6 <writei+0x18d>
    ip->size = off;
80102ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac5:	8b 55 10             	mov    0x10(%ebp),%edx
80102ac8:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102acb:	8b 45 08             	mov    0x8(%ebp),%eax
80102ace:	89 04 24             	mov    %eax,(%esp)
80102ad1:	e8 56 f6 ff ff       	call   8010212c <iupdate>
  }
  return n;
80102ad6:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102ad9:	83 c4 24             	add    $0x24,%esp
80102adc:	5b                   	pop    %ebx
80102add:	5d                   	pop    %ebp
80102ade:	c3                   	ret    

80102adf <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102adf:	55                   	push   %ebp
80102ae0:	89 e5                	mov    %esp,%ebp
80102ae2:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102ae5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102aec:	00 
80102aed:	8b 45 0c             	mov    0xc(%ebp),%eax
80102af0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102af4:	8b 45 08             	mov    0x8(%ebp),%eax
80102af7:	89 04 24             	mov    %eax,(%esp)
80102afa:	e8 0e 30 00 00       	call   80105b0d <strncmp>
}
80102aff:	c9                   	leave  
80102b00:	c3                   	ret    

80102b01 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102b01:	55                   	push   %ebp
80102b02:	89 e5                	mov    %esp,%ebp
80102b04:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102b07:	8b 45 08             	mov    0x8(%ebp),%eax
80102b0a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102b0e:	66 83 f8 01          	cmp    $0x1,%ax
80102b12:	74 0c                	je     80102b20 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102b14:	c7 04 24 99 90 10 80 	movl   $0x80109099,(%esp)
80102b1b:	e8 1d da ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102b20:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b27:	e9 87 00 00 00       	jmp    80102bb3 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102b2c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102b33:	00 
80102b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b37:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b3b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102b3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b42:	8b 45 08             	mov    0x8(%ebp),%eax
80102b45:	89 04 24             	mov    %eax,(%esp)
80102b48:	e8 91 fc ff ff       	call   801027de <readi>
80102b4d:	83 f8 10             	cmp    $0x10,%eax
80102b50:	74 0c                	je     80102b5e <dirlookup+0x5d>
      panic("dirlink read");
80102b52:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
80102b59:	e8 df d9 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102b5e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102b62:	66 85 c0             	test   %ax,%ax
80102b65:	74 47                	je     80102bae <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102b67:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102b6a:	83 c0 02             	add    $0x2,%eax
80102b6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b71:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b74:	89 04 24             	mov    %eax,(%esp)
80102b77:	e8 63 ff ff ff       	call   80102adf <namecmp>
80102b7c:	85 c0                	test   %eax,%eax
80102b7e:	75 2f                	jne    80102baf <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102b80:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102b84:	74 08                	je     80102b8e <dirlookup+0x8d>
        *poff = off;
80102b86:	8b 45 10             	mov    0x10(%ebp),%eax
80102b89:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102b8c:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102b8e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102b92:	0f b7 c0             	movzwl %ax,%eax
80102b95:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102b98:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9b:	8b 00                	mov    (%eax),%eax
80102b9d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ba0:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ba4:	89 04 24             	mov    %eax,(%esp)
80102ba7:	e8 38 f6 ff ff       	call   801021e4 <iget>
80102bac:	eb 19                	jmp    80102bc7 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102bae:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102baf:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102bb3:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb6:	8b 40 18             	mov    0x18(%eax),%eax
80102bb9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102bbc:	0f 87 6a ff ff ff    	ja     80102b2c <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102bc2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102bc7:	c9                   	leave  
80102bc8:	c3                   	ret    

80102bc9 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102bc9:	55                   	push   %ebp
80102bca:	89 e5                	mov    %esp,%ebp
80102bcc:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102bcf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102bd6:	00 
80102bd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bda:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bde:	8b 45 08             	mov    0x8(%ebp),%eax
80102be1:	89 04 24             	mov    %eax,(%esp)
80102be4:	e8 18 ff ff ff       	call   80102b01 <dirlookup>
80102be9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102bec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102bf0:	74 15                	je     80102c07 <dirlink+0x3e>
    iput(ip);
80102bf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102bf5:	89 04 24             	mov    %eax,(%esp)
80102bf8:	e8 9e f8 ff ff       	call   8010249b <iput>
    return -1;
80102bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c02:	e9 b8 00 00 00       	jmp    80102cbf <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102c07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c0e:	eb 44                	jmp    80102c54 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c13:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c1a:	00 
80102c1b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c1f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c22:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c26:	8b 45 08             	mov    0x8(%ebp),%eax
80102c29:	89 04 24             	mov    %eax,(%esp)
80102c2c:	e8 ad fb ff ff       	call   801027de <readi>
80102c31:	83 f8 10             	cmp    $0x10,%eax
80102c34:	74 0c                	je     80102c42 <dirlink+0x79>
      panic("dirlink read");
80102c36:	c7 04 24 ab 90 10 80 	movl   $0x801090ab,(%esp)
80102c3d:	e8 fb d8 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102c42:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c46:	66 85 c0             	test   %ax,%ax
80102c49:	74 18                	je     80102c63 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c4e:	83 c0 10             	add    $0x10,%eax
80102c51:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102c54:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102c57:	8b 45 08             	mov    0x8(%ebp),%eax
80102c5a:	8b 40 18             	mov    0x18(%eax),%eax
80102c5d:	39 c2                	cmp    %eax,%edx
80102c5f:	72 af                	jb     80102c10 <dirlink+0x47>
80102c61:	eb 01                	jmp    80102c64 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102c63:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102c64:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102c6b:	00 
80102c6c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c6f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c73:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c76:	83 c0 02             	add    $0x2,%eax
80102c79:	89 04 24             	mov    %eax,(%esp)
80102c7c:	e8 e4 2e 00 00       	call   80105b65 <strncpy>
  de.inum = inum;
80102c81:	8b 45 10             	mov    0x10(%ebp),%eax
80102c84:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c8b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c92:	00 
80102c93:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c97:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca1:	89 04 24             	mov    %eax,(%esp)
80102ca4:	e8 a0 fc ff ff       	call   80102949 <writei>
80102ca9:	83 f8 10             	cmp    $0x10,%eax
80102cac:	74 0c                	je     80102cba <dirlink+0xf1>
    panic("dirlink");
80102cae:	c7 04 24 b8 90 10 80 	movl   $0x801090b8,(%esp)
80102cb5:	e8 83 d8 ff ff       	call   8010053d <panic>
  
  return 0;
80102cba:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102cbf:	c9                   	leave  
80102cc0:	c3                   	ret    

80102cc1 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102cc1:	55                   	push   %ebp
80102cc2:	89 e5                	mov    %esp,%ebp
80102cc4:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102cc7:	eb 04                	jmp    80102ccd <skipelem+0xc>
    path++;
80102cc9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102ccd:	8b 45 08             	mov    0x8(%ebp),%eax
80102cd0:	0f b6 00             	movzbl (%eax),%eax
80102cd3:	3c 2f                	cmp    $0x2f,%al
80102cd5:	74 f2                	je     80102cc9 <skipelem+0x8>
    path++;
  if(*path == 0)
80102cd7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cda:	0f b6 00             	movzbl (%eax),%eax
80102cdd:	84 c0                	test   %al,%al
80102cdf:	75 0a                	jne    80102ceb <skipelem+0x2a>
    return 0;
80102ce1:	b8 00 00 00 00       	mov    $0x0,%eax
80102ce6:	e9 86 00 00 00       	jmp    80102d71 <skipelem+0xb0>
  s = path;
80102ceb:	8b 45 08             	mov    0x8(%ebp),%eax
80102cee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102cf1:	eb 04                	jmp    80102cf7 <skipelem+0x36>
    path++;
80102cf3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102cf7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cfa:	0f b6 00             	movzbl (%eax),%eax
80102cfd:	3c 2f                	cmp    $0x2f,%al
80102cff:	74 0a                	je     80102d0b <skipelem+0x4a>
80102d01:	8b 45 08             	mov    0x8(%ebp),%eax
80102d04:	0f b6 00             	movzbl (%eax),%eax
80102d07:	84 c0                	test   %al,%al
80102d09:	75 e8                	jne    80102cf3 <skipelem+0x32>
    path++;
  len = path - s;
80102d0b:	8b 55 08             	mov    0x8(%ebp),%edx
80102d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d11:	89 d1                	mov    %edx,%ecx
80102d13:	29 c1                	sub    %eax,%ecx
80102d15:	89 c8                	mov    %ecx,%eax
80102d17:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102d1a:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102d1e:	7e 1c                	jle    80102d3c <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102d20:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102d27:	00 
80102d28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d32:	89 04 24             	mov    %eax,(%esp)
80102d35:	e8 2f 2d 00 00       	call   80105a69 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102d3a:	eb 28                	jmp    80102d64 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102d3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d3f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d46:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d4a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d4d:	89 04 24             	mov    %eax,(%esp)
80102d50:	e8 14 2d 00 00       	call   80105a69 <memmove>
    name[len] = 0;
80102d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d58:	03 45 0c             	add    0xc(%ebp),%eax
80102d5b:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102d5e:	eb 04                	jmp    80102d64 <skipelem+0xa3>
    path++;
80102d60:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102d64:	8b 45 08             	mov    0x8(%ebp),%eax
80102d67:	0f b6 00             	movzbl (%eax),%eax
80102d6a:	3c 2f                	cmp    $0x2f,%al
80102d6c:	74 f2                	je     80102d60 <skipelem+0x9f>
    path++;
  return path;
80102d6e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102d71:	c9                   	leave  
80102d72:	c3                   	ret    

80102d73 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102d73:	55                   	push   %ebp
80102d74:	89 e5                	mov    %esp,%ebp
80102d76:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102d79:	8b 45 08             	mov    0x8(%ebp),%eax
80102d7c:	0f b6 00             	movzbl (%eax),%eax
80102d7f:	3c 2f                	cmp    $0x2f,%al
80102d81:	75 1c                	jne    80102d9f <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102d83:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d8a:	00 
80102d8b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102d92:	e8 4d f4 ff ff       	call   801021e4 <iget>
80102d97:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102d9a:	e9 af 00 00 00       	jmp    80102e4e <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102d9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102da5:	8b 40 68             	mov    0x68(%eax),%eax
80102da8:	89 04 24             	mov    %eax,(%esp)
80102dab:	e8 06 f5 ff ff       	call   801022b6 <idup>
80102db0:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102db3:	e9 96 00 00 00       	jmp    80102e4e <namex+0xdb>
    ilock(ip);
80102db8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dbb:	89 04 24             	mov    %eax,(%esp)
80102dbe:	e8 25 f5 ff ff       	call   801022e8 <ilock>
    if(ip->type != T_DIR){
80102dc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102dca:	66 83 f8 01          	cmp    $0x1,%ax
80102dce:	74 15                	je     80102de5 <namex+0x72>
      iunlockput(ip);
80102dd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dd3:	89 04 24             	mov    %eax,(%esp)
80102dd6:	e8 91 f7 ff ff       	call   8010256c <iunlockput>
      return 0;
80102ddb:	b8 00 00 00 00       	mov    $0x0,%eax
80102de0:	e9 a3 00 00 00       	jmp    80102e88 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102de5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102de9:	74 1d                	je     80102e08 <namex+0x95>
80102deb:	8b 45 08             	mov    0x8(%ebp),%eax
80102dee:	0f b6 00             	movzbl (%eax),%eax
80102df1:	84 c0                	test   %al,%al
80102df3:	75 13                	jne    80102e08 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102df8:	89 04 24             	mov    %eax,(%esp)
80102dfb:	e8 36 f6 ff ff       	call   80102436 <iunlock>
      return ip;
80102e00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e03:	e9 80 00 00 00       	jmp    80102e88 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102e08:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102e0f:	00 
80102e10:	8b 45 10             	mov    0x10(%ebp),%eax
80102e13:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e1a:	89 04 24             	mov    %eax,(%esp)
80102e1d:	e8 df fc ff ff       	call   80102b01 <dirlookup>
80102e22:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102e25:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102e29:	75 12                	jne    80102e3d <namex+0xca>
      iunlockput(ip);
80102e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e2e:	89 04 24             	mov    %eax,(%esp)
80102e31:	e8 36 f7 ff ff       	call   8010256c <iunlockput>
      return 0;
80102e36:	b8 00 00 00 00       	mov    $0x0,%eax
80102e3b:	eb 4b                	jmp    80102e88 <namex+0x115>
    }
    iunlockput(ip);
80102e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e40:	89 04 24             	mov    %eax,(%esp)
80102e43:	e8 24 f7 ff ff       	call   8010256c <iunlockput>
    ip = next;
80102e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e4b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102e4e:	8b 45 10             	mov    0x10(%ebp),%eax
80102e51:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e55:	8b 45 08             	mov    0x8(%ebp),%eax
80102e58:	89 04 24             	mov    %eax,(%esp)
80102e5b:	e8 61 fe ff ff       	call   80102cc1 <skipelem>
80102e60:	89 45 08             	mov    %eax,0x8(%ebp)
80102e63:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102e67:	0f 85 4b ff ff ff    	jne    80102db8 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102e6d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e71:	74 12                	je     80102e85 <namex+0x112>
    iput(ip);
80102e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e76:	89 04 24             	mov    %eax,(%esp)
80102e79:	e8 1d f6 ff ff       	call   8010249b <iput>
    return 0;
80102e7e:	b8 00 00 00 00       	mov    $0x0,%eax
80102e83:	eb 03                	jmp    80102e88 <namex+0x115>
  }
  return ip;
80102e85:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102e88:	c9                   	leave  
80102e89:	c3                   	ret    

80102e8a <namei>:

struct inode*
namei(char *path)
{
80102e8a:	55                   	push   %ebp
80102e8b:	89 e5                	mov    %esp,%ebp
80102e8d:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102e90:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102e93:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e97:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e9e:	00 
80102e9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102ea2:	89 04 24             	mov    %eax,(%esp)
80102ea5:	e8 c9 fe ff ff       	call   80102d73 <namex>
}
80102eaa:	c9                   	leave  
80102eab:	c3                   	ret    

80102eac <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102eac:	55                   	push   %ebp
80102ead:	89 e5                	mov    %esp,%ebp
80102eaf:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102eb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102eb5:	89 44 24 08          	mov    %eax,0x8(%esp)
80102eb9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ec0:	00 
80102ec1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ec4:	89 04 24             	mov    %eax,(%esp)
80102ec7:	e8 a7 fe ff ff       	call   80102d73 <namex>
}
80102ecc:	c9                   	leave  
80102ecd:	c3                   	ret    

80102ece <getNextInode>:

struct inode*
getNextInode(void)
{
80102ece:	55                   	push   %ebp
80102ecf:	89 e5                	mov    %esp,%ebp
80102ed1:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80102ed4:	8d 45 d8             	lea    -0x28(%ebp),%eax
80102ed7:	89 44 24 04          	mov    %eax,0x4(%esp)
80102edb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102ee2:	e8 85 ee ff ff       	call   80101d6c <readsb>

  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80102ee7:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80102eec:	83 c0 01             	add    $0x1,%eax
80102eef:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102ef2:	eb 63                	jmp    80102f57 <getNextInode+0x89>
  {
    bp = bread(1, IBLOCK(inum));
80102ef4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ef7:	c1 e8 03             	shr    $0x3,%eax
80102efa:	83 c0 02             	add    $0x2,%eax
80102efd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f01:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102f08:	e8 99 d2 ff ff       	call   801001a6 <bread>
80102f0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80102f10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f13:	8d 50 18             	lea    0x18(%eax),%edx
80102f16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f19:	83 e0 07             	and    $0x7,%eax
80102f1c:	c1 e0 06             	shl    $0x6,%eax
80102f1f:	01 d0                	add    %edx,%eax
80102f21:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
80102f24:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102f27:	0f b7 00             	movzwl (%eax),%eax
80102f2a:	66 83 f8 02          	cmp    $0x2,%ax
80102f2e:	75 23                	jne    80102f53 <getNextInode+0x85>
    {
      nextInum = inum;
80102f30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f33:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      ip = iget(1,inum);
80102f38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f3f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102f46:	e8 99 f2 ff ff       	call   801021e4 <iget>
80102f4b:	89 45 e8             	mov    %eax,-0x18(%ebp)
      return ip;
80102f4e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102f51:	eb 16                	jmp    80102f69 <getNextInode+0x9b>
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);

  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80102f53:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f5a:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102f5d:	83 ea 01             	sub    $0x1,%edx
80102f60:	39 d0                	cmp    %edx,%eax
80102f62:	72 90                	jb     80102ef4 <getNextInode+0x26>
      nextInum = inum;
      ip = iget(1,inum);
      return ip;
    }
  }
  return 0;
80102f64:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f69:	c9                   	leave  
80102f6a:	c3                   	ret    

80102f6b <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
80102f6b:	55                   	push   %ebp
80102f6c:	89 e5                	mov    %esp,%ebp
80102f6e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
80102f71:	eb 6a                	jmp    80102fdd <getPrevInode+0x72>
  {
    bp = bread(1, IBLOCK(*prevInum));
80102f73:	8b 45 08             	mov    0x8(%ebp),%eax
80102f76:	8b 00                	mov    (%eax),%eax
80102f78:	c1 e8 03             	shr    $0x3,%eax
80102f7b:	83 c0 02             	add    $0x2,%eax
80102f7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f82:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102f89:	e8 18 d2 ff ff       	call   801001a6 <bread>
80102f8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
80102f91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f94:	8d 50 18             	lea    0x18(%eax),%edx
80102f97:	8b 45 08             	mov    0x8(%ebp),%eax
80102f9a:	8b 00                	mov    (%eax),%eax
80102f9c:	83 e0 07             	and    $0x7,%eax
80102f9f:	c1 e0 06             	shl    $0x6,%eax
80102fa2:	01 d0                	add    %edx,%eax
80102fa4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
80102fa7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102faa:	0f b7 00             	movzwl (%eax),%eax
80102fad:	66 83 f8 02          	cmp    $0x2,%ax
80102fb1:	75 1d                	jne    80102fd0 <getPrevInode+0x65>
    {
      ip = iget(1,*prevInum);
80102fb3:	8b 45 08             	mov    0x8(%ebp),%eax
80102fb6:	8b 00                	mov    (%eax),%eax
80102fb8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fbc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fc3:	e8 1c f2 ff ff       	call   801021e4 <iget>
80102fc8:	89 45 ec             	mov    %eax,-0x14(%ebp)
      return ip;
80102fcb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102fce:	eb 20                	jmp    80102ff0 <getPrevInode+0x85>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
80102fd0:	8b 45 08             	mov    0x8(%ebp),%eax
80102fd3:	8b 00                	mov    (%eax),%eax
80102fd5:	8d 50 ff             	lea    -0x1(%eax),%edx
80102fd8:	8b 45 08             	mov    0x8(%ebp),%eax
80102fdb:	89 10                	mov    %edx,(%eax)
80102fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80102fe0:	8b 10                	mov    (%eax),%edx
80102fe2:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80102fe7:	39 c2                	cmp    %eax,%edx
80102fe9:	7f 88                	jg     80102f73 <getPrevInode+0x8>
    {
      ip = iget(1,*prevInum);
      return ip;
    }
  }
  return 0;
80102feb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ff0:	c9                   	leave  
80102ff1:	c3                   	ret    
	...

80102ff4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ff4:	55                   	push   %ebp
80102ff5:	89 e5                	mov    %esp,%ebp
80102ff7:	53                   	push   %ebx
80102ff8:	83 ec 14             	sub    $0x14,%esp
80102ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80102ffe:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103002:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103006:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010300a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010300e:	ec                   	in     (%dx),%al
8010300f:	89 c3                	mov    %eax,%ebx
80103011:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103014:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103018:	83 c4 14             	add    $0x14,%esp
8010301b:	5b                   	pop    %ebx
8010301c:	5d                   	pop    %ebp
8010301d:	c3                   	ret    

8010301e <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010301e:	55                   	push   %ebp
8010301f:	89 e5                	mov    %esp,%ebp
80103021:	57                   	push   %edi
80103022:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80103023:	8b 55 08             	mov    0x8(%ebp),%edx
80103026:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103029:	8b 45 10             	mov    0x10(%ebp),%eax
8010302c:	89 cb                	mov    %ecx,%ebx
8010302e:	89 df                	mov    %ebx,%edi
80103030:	89 c1                	mov    %eax,%ecx
80103032:	fc                   	cld    
80103033:	f3 6d                	rep insl (%dx),%es:(%edi)
80103035:	89 c8                	mov    %ecx,%eax
80103037:	89 fb                	mov    %edi,%ebx
80103039:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010303c:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010303f:	5b                   	pop    %ebx
80103040:	5f                   	pop    %edi
80103041:	5d                   	pop    %ebp
80103042:	c3                   	ret    

80103043 <outb>:

static inline void
outb(ushort port, uchar data)
{
80103043:	55                   	push   %ebp
80103044:	89 e5                	mov    %esp,%ebp
80103046:	83 ec 08             	sub    $0x8,%esp
80103049:	8b 55 08             	mov    0x8(%ebp),%edx
8010304c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010304f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103053:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103056:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010305a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010305e:	ee                   	out    %al,(%dx)
}
8010305f:	c9                   	leave  
80103060:	c3                   	ret    

80103061 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80103061:	55                   	push   %ebp
80103062:	89 e5                	mov    %esp,%ebp
80103064:	56                   	push   %esi
80103065:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80103066:	8b 55 08             	mov    0x8(%ebp),%edx
80103069:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010306c:	8b 45 10             	mov    0x10(%ebp),%eax
8010306f:	89 cb                	mov    %ecx,%ebx
80103071:	89 de                	mov    %ebx,%esi
80103073:	89 c1                	mov    %eax,%ecx
80103075:	fc                   	cld    
80103076:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80103078:	89 c8                	mov    %ecx,%eax
8010307a:	89 f3                	mov    %esi,%ebx
8010307c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010307f:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103082:	5b                   	pop    %ebx
80103083:	5e                   	pop    %esi
80103084:	5d                   	pop    %ebp
80103085:	c3                   	ret    

80103086 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80103086:	55                   	push   %ebp
80103087:	89 e5                	mov    %esp,%ebp
80103089:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010308c:	90                   	nop
8010308d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103094:	e8 5b ff ff ff       	call   80102ff4 <inb>
80103099:	0f b6 c0             	movzbl %al,%eax
8010309c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010309f:	8b 45 fc             	mov    -0x4(%ebp),%eax
801030a2:	25 c0 00 00 00       	and    $0xc0,%eax
801030a7:	83 f8 40             	cmp    $0x40,%eax
801030aa:	75 e1                	jne    8010308d <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801030ac:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801030b0:	74 11                	je     801030c3 <idewait+0x3d>
801030b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801030b5:	83 e0 21             	and    $0x21,%eax
801030b8:	85 c0                	test   %eax,%eax
801030ba:	74 07                	je     801030c3 <idewait+0x3d>
    return -1;
801030bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801030c1:	eb 05                	jmp    801030c8 <idewait+0x42>
  return 0;
801030c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030c8:	c9                   	leave  
801030c9:	c3                   	ret    

801030ca <ideinit>:

void
ideinit(void)
{
801030ca:	55                   	push   %ebp
801030cb:	89 e5                	mov    %esp,%ebp
801030cd:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801030d0:	c7 44 24 04 c0 90 10 	movl   $0x801090c0,0x4(%esp)
801030d7:	80 
801030d8:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801030df:	e8 42 26 00 00       	call   80105726 <initlock>
  picenable(IRQ_IDE);
801030e4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801030eb:	e8 75 15 00 00       	call   80104665 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801030f0:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801030f5:	83 e8 01             	sub    $0x1,%eax
801030f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801030fc:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103103:	e8 12 04 00 00       	call   8010351a <ioapicenable>
  idewait(0);
80103108:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010310f:	e8 72 ff ff ff       	call   80103086 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103114:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010311b:	00 
8010311c:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103123:	e8 1b ff ff ff       	call   80103043 <outb>
  for(i=0; i<1000; i++){
80103128:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010312f:	eb 20                	jmp    80103151 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103131:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103138:	e8 b7 fe ff ff       	call   80102ff4 <inb>
8010313d:	84 c0                	test   %al,%al
8010313f:	74 0c                	je     8010314d <ideinit+0x83>
      havedisk1 = 1;
80103141:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80103148:	00 00 00 
      break;
8010314b:	eb 0d                	jmp    8010315a <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
8010314d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103151:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80103158:	7e d7                	jle    80103131 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010315a:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103161:	00 
80103162:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103169:	e8 d5 fe ff ff       	call   80103043 <outb>
}
8010316e:	c9                   	leave  
8010316f:	c3                   	ret    

80103170 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103170:	55                   	push   %ebp
80103171:	89 e5                	mov    %esp,%ebp
80103173:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80103176:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010317a:	75 0c                	jne    80103188 <idestart+0x18>
    panic("idestart");
8010317c:	c7 04 24 c4 90 10 80 	movl   $0x801090c4,(%esp)
80103183:	e8 b5 d3 ff ff       	call   8010053d <panic>

  idewait(0);
80103188:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010318f:	e8 f2 fe ff ff       	call   80103086 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80103194:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010319b:	00 
8010319c:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801031a3:	e8 9b fe ff ff       	call   80103043 <outb>
  outb(0x1f2, 1);  // number of sectors
801031a8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801031af:	00 
801031b0:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801031b7:	e8 87 fe ff ff       	call   80103043 <outb>
  outb(0x1f3, b->sector & 0xff);
801031bc:	8b 45 08             	mov    0x8(%ebp),%eax
801031bf:	8b 40 08             	mov    0x8(%eax),%eax
801031c2:	0f b6 c0             	movzbl %al,%eax
801031c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801031c9:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801031d0:	e8 6e fe ff ff       	call   80103043 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801031d5:	8b 45 08             	mov    0x8(%ebp),%eax
801031d8:	8b 40 08             	mov    0x8(%eax),%eax
801031db:	c1 e8 08             	shr    $0x8,%eax
801031de:	0f b6 c0             	movzbl %al,%eax
801031e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801031e5:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801031ec:	e8 52 fe ff ff       	call   80103043 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801031f1:	8b 45 08             	mov    0x8(%ebp),%eax
801031f4:	8b 40 08             	mov    0x8(%eax),%eax
801031f7:	c1 e8 10             	shr    $0x10,%eax
801031fa:	0f b6 c0             	movzbl %al,%eax
801031fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80103201:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80103208:	e8 36 fe ff ff       	call   80103043 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
8010320d:	8b 45 08             	mov    0x8(%ebp),%eax
80103210:	8b 40 04             	mov    0x4(%eax),%eax
80103213:	83 e0 01             	and    $0x1,%eax
80103216:	89 c2                	mov    %eax,%edx
80103218:	c1 e2 04             	shl    $0x4,%edx
8010321b:	8b 45 08             	mov    0x8(%ebp),%eax
8010321e:	8b 40 08             	mov    0x8(%eax),%eax
80103221:	c1 e8 18             	shr    $0x18,%eax
80103224:	83 e0 0f             	and    $0xf,%eax
80103227:	09 d0                	or     %edx,%eax
80103229:	83 c8 e0             	or     $0xffffffe0,%eax
8010322c:	0f b6 c0             	movzbl %al,%eax
8010322f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103233:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010323a:	e8 04 fe ff ff       	call   80103043 <outb>
  if(b->flags & B_DIRTY){
8010323f:	8b 45 08             	mov    0x8(%ebp),%eax
80103242:	8b 00                	mov    (%eax),%eax
80103244:	83 e0 04             	and    $0x4,%eax
80103247:	85 c0                	test   %eax,%eax
80103249:	74 34                	je     8010327f <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010324b:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80103252:	00 
80103253:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010325a:	e8 e4 fd ff ff       	call   80103043 <outb>
    outsl(0x1f0, b->data, 512/4);
8010325f:	8b 45 08             	mov    0x8(%ebp),%eax
80103262:	83 c0 18             	add    $0x18,%eax
80103265:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010326c:	00 
8010326d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103271:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103278:	e8 e4 fd ff ff       	call   80103061 <outsl>
8010327d:	eb 14                	jmp    80103293 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010327f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103286:	00 
80103287:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010328e:	e8 b0 fd ff ff       	call   80103043 <outb>
  }
}
80103293:	c9                   	leave  
80103294:	c3                   	ret    

80103295 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80103295:	55                   	push   %ebp
80103296:	89 e5                	mov    %esp,%ebp
80103298:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010329b:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801032a2:	e8 a0 24 00 00       	call   80105747 <acquire>
  if((b = idequeue) == 0){
801032a7:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801032ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
801032af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801032b3:	75 11                	jne    801032c6 <ideintr+0x31>
    release(&idelock);
801032b5:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801032bc:	e8 e8 24 00 00       	call   801057a9 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801032c1:	e9 90 00 00 00       	jmp    80103356 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801032c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c9:	8b 40 14             	mov    0x14(%eax),%eax
801032cc:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801032d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032d4:	8b 00                	mov    (%eax),%eax
801032d6:	83 e0 04             	and    $0x4,%eax
801032d9:	85 c0                	test   %eax,%eax
801032db:	75 2e                	jne    8010330b <ideintr+0x76>
801032dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032e4:	e8 9d fd ff ff       	call   80103086 <idewait>
801032e9:	85 c0                	test   %eax,%eax
801032eb:	78 1e                	js     8010330b <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801032ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032f0:	83 c0 18             	add    $0x18,%eax
801032f3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801032fa:	00 
801032fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801032ff:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103306:	e8 13 fd ff ff       	call   8010301e <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010330b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010330e:	8b 00                	mov    (%eax),%eax
80103310:	89 c2                	mov    %eax,%edx
80103312:	83 ca 02             	or     $0x2,%edx
80103315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103318:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010331a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010331d:	8b 00                	mov    (%eax),%eax
8010331f:	89 c2                	mov    %eax,%edx
80103321:	83 e2 fb             	and    $0xfffffffb,%edx
80103324:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103327:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103329:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010332c:	89 04 24             	mov    %eax,(%esp)
8010332f:	e8 0e 22 00 00       	call   80105542 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103334:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103339:	85 c0                	test   %eax,%eax
8010333b:	74 0d                	je     8010334a <ideintr+0xb5>
    idestart(idequeue);
8010333d:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103342:	89 04 24             	mov    %eax,(%esp)
80103345:	e8 26 fe ff ff       	call   80103170 <idestart>

  release(&idelock);
8010334a:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103351:	e8 53 24 00 00       	call   801057a9 <release>
}
80103356:	c9                   	leave  
80103357:	c3                   	ret    

80103358 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103358:	55                   	push   %ebp
80103359:	89 e5                	mov    %esp,%ebp
8010335b:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
8010335e:	8b 45 08             	mov    0x8(%ebp),%eax
80103361:	8b 00                	mov    (%eax),%eax
80103363:	83 e0 01             	and    $0x1,%eax
80103366:	85 c0                	test   %eax,%eax
80103368:	75 0c                	jne    80103376 <iderw+0x1e>
    panic("iderw: buf not busy");
8010336a:	c7 04 24 cd 90 10 80 	movl   $0x801090cd,(%esp)
80103371:	e8 c7 d1 ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103376:	8b 45 08             	mov    0x8(%ebp),%eax
80103379:	8b 00                	mov    (%eax),%eax
8010337b:	83 e0 06             	and    $0x6,%eax
8010337e:	83 f8 02             	cmp    $0x2,%eax
80103381:	75 0c                	jne    8010338f <iderw+0x37>
    panic("iderw: nothing to do");
80103383:	c7 04 24 e1 90 10 80 	movl   $0x801090e1,(%esp)
8010338a:	e8 ae d1 ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
8010338f:	8b 45 08             	mov    0x8(%ebp),%eax
80103392:	8b 40 04             	mov    0x4(%eax),%eax
80103395:	85 c0                	test   %eax,%eax
80103397:	74 15                	je     801033ae <iderw+0x56>
80103399:	a1 58 c6 10 80       	mov    0x8010c658,%eax
8010339e:	85 c0                	test   %eax,%eax
801033a0:	75 0c                	jne    801033ae <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801033a2:	c7 04 24 f6 90 10 80 	movl   $0x801090f6,(%esp)
801033a9:	e8 8f d1 ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801033ae:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801033b5:	e8 8d 23 00 00       	call   80105747 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801033ba:	8b 45 08             	mov    0x8(%ebp),%eax
801033bd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801033c4:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801033cb:	eb 0b                	jmp    801033d8 <iderw+0x80>
801033cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d0:	8b 00                	mov    (%eax),%eax
801033d2:	83 c0 14             	add    $0x14,%eax
801033d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801033d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033db:	8b 00                	mov    (%eax),%eax
801033dd:	85 c0                	test   %eax,%eax
801033df:	75 ec                	jne    801033cd <iderw+0x75>
    ;
  *pp = b;
801033e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033e4:	8b 55 08             	mov    0x8(%ebp),%edx
801033e7:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801033e9:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801033ee:	3b 45 08             	cmp    0x8(%ebp),%eax
801033f1:	75 22                	jne    80103415 <iderw+0xbd>
    idestart(b);
801033f3:	8b 45 08             	mov    0x8(%ebp),%eax
801033f6:	89 04 24             	mov    %eax,(%esp)
801033f9:	e8 72 fd ff ff       	call   80103170 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801033fe:	eb 15                	jmp    80103415 <iderw+0xbd>
    sleep(b, &idelock);
80103400:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103407:	80 
80103408:	8b 45 08             	mov    0x8(%ebp),%eax
8010340b:	89 04 24             	mov    %eax,(%esp)
8010340e:	e8 56 20 00 00       	call   80105469 <sleep>
80103413:	eb 01                	jmp    80103416 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103415:	90                   	nop
80103416:	8b 45 08             	mov    0x8(%ebp),%eax
80103419:	8b 00                	mov    (%eax),%eax
8010341b:	83 e0 06             	and    $0x6,%eax
8010341e:	83 f8 02             	cmp    $0x2,%eax
80103421:	75 dd                	jne    80103400 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103423:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010342a:	e8 7a 23 00 00       	call   801057a9 <release>
}
8010342f:	c9                   	leave  
80103430:	c3                   	ret    
80103431:	00 00                	add    %al,(%eax)
	...

80103434 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103434:	55                   	push   %ebp
80103435:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103437:	a1 54 08 11 80       	mov    0x80110854,%eax
8010343c:	8b 55 08             	mov    0x8(%ebp),%edx
8010343f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103441:	a1 54 08 11 80       	mov    0x80110854,%eax
80103446:	8b 40 10             	mov    0x10(%eax),%eax
}
80103449:	5d                   	pop    %ebp
8010344a:	c3                   	ret    

8010344b <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010344b:	55                   	push   %ebp
8010344c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010344e:	a1 54 08 11 80       	mov    0x80110854,%eax
80103453:	8b 55 08             	mov    0x8(%ebp),%edx
80103456:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103458:	a1 54 08 11 80       	mov    0x80110854,%eax
8010345d:	8b 55 0c             	mov    0xc(%ebp),%edx
80103460:	89 50 10             	mov    %edx,0x10(%eax)
}
80103463:	5d                   	pop    %ebp
80103464:	c3                   	ret    

80103465 <ioapicinit>:

void
ioapicinit(void)
{
80103465:	55                   	push   %ebp
80103466:	89 e5                	mov    %esp,%ebp
80103468:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010346b:	a1 24 09 11 80       	mov    0x80110924,%eax
80103470:	85 c0                	test   %eax,%eax
80103472:	0f 84 9f 00 00 00    	je     80103517 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103478:	c7 05 54 08 11 80 00 	movl   $0xfec00000,0x80110854
8010347f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103482:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103489:	e8 a6 ff ff ff       	call   80103434 <ioapicread>
8010348e:	c1 e8 10             	shr    $0x10,%eax
80103491:	25 ff 00 00 00       	and    $0xff,%eax
80103496:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103499:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801034a0:	e8 8f ff ff ff       	call   80103434 <ioapicread>
801034a5:	c1 e8 18             	shr    $0x18,%eax
801034a8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801034ab:	0f b6 05 20 09 11 80 	movzbl 0x80110920,%eax
801034b2:	0f b6 c0             	movzbl %al,%eax
801034b5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801034b8:	74 0c                	je     801034c6 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801034ba:	c7 04 24 14 91 10 80 	movl   $0x80109114,(%esp)
801034c1:	e8 db ce ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801034c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034cd:	eb 3e                	jmp    8010350d <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801034cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d2:	83 c0 20             	add    $0x20,%eax
801034d5:	0d 00 00 01 00       	or     $0x10000,%eax
801034da:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034dd:	83 c2 08             	add    $0x8,%edx
801034e0:	01 d2                	add    %edx,%edx
801034e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801034e6:	89 14 24             	mov    %edx,(%esp)
801034e9:	e8 5d ff ff ff       	call   8010344b <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801034ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034f1:	83 c0 08             	add    $0x8,%eax
801034f4:	01 c0                	add    %eax,%eax
801034f6:	83 c0 01             	add    $0x1,%eax
801034f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103500:	00 
80103501:	89 04 24             	mov    %eax,(%esp)
80103504:	e8 42 ff ff ff       	call   8010344b <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103509:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010350d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103510:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103513:	7e ba                	jle    801034cf <ioapicinit+0x6a>
80103515:	eb 01                	jmp    80103518 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103517:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103518:	c9                   	leave  
80103519:	c3                   	ret    

8010351a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010351a:	55                   	push   %ebp
8010351b:	89 e5                	mov    %esp,%ebp
8010351d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103520:	a1 24 09 11 80       	mov    0x80110924,%eax
80103525:	85 c0                	test   %eax,%eax
80103527:	74 39                	je     80103562 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103529:	8b 45 08             	mov    0x8(%ebp),%eax
8010352c:	83 c0 20             	add    $0x20,%eax
8010352f:	8b 55 08             	mov    0x8(%ebp),%edx
80103532:	83 c2 08             	add    $0x8,%edx
80103535:	01 d2                	add    %edx,%edx
80103537:	89 44 24 04          	mov    %eax,0x4(%esp)
8010353b:	89 14 24             	mov    %edx,(%esp)
8010353e:	e8 08 ff ff ff       	call   8010344b <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103543:	8b 45 0c             	mov    0xc(%ebp),%eax
80103546:	c1 e0 18             	shl    $0x18,%eax
80103549:	8b 55 08             	mov    0x8(%ebp),%edx
8010354c:	83 c2 08             	add    $0x8,%edx
8010354f:	01 d2                	add    %edx,%edx
80103551:	83 c2 01             	add    $0x1,%edx
80103554:	89 44 24 04          	mov    %eax,0x4(%esp)
80103558:	89 14 24             	mov    %edx,(%esp)
8010355b:	e8 eb fe ff ff       	call   8010344b <ioapicwrite>
80103560:	eb 01                	jmp    80103563 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103562:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103563:	c9                   	leave  
80103564:	c3                   	ret    
80103565:	00 00                	add    %al,(%eax)
	...

80103568 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103568:	55                   	push   %ebp
80103569:	89 e5                	mov    %esp,%ebp
8010356b:	8b 45 08             	mov    0x8(%ebp),%eax
8010356e:	05 00 00 00 80       	add    $0x80000000,%eax
80103573:	5d                   	pop    %ebp
80103574:	c3                   	ret    

80103575 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103575:	55                   	push   %ebp
80103576:	89 e5                	mov    %esp,%ebp
80103578:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
8010357b:	c7 44 24 04 46 91 10 	movl   $0x80109146,0x4(%esp)
80103582:	80 
80103583:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
8010358a:	e8 97 21 00 00       	call   80105726 <initlock>
  kmem.use_lock = 0;
8010358f:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
80103596:	00 00 00 
  freerange(vstart, vend);
80103599:	8b 45 0c             	mov    0xc(%ebp),%eax
8010359c:	89 44 24 04          	mov    %eax,0x4(%esp)
801035a0:	8b 45 08             	mov    0x8(%ebp),%eax
801035a3:	89 04 24             	mov    %eax,(%esp)
801035a6:	e8 26 00 00 00       	call   801035d1 <freerange>
}
801035ab:	c9                   	leave  
801035ac:	c3                   	ret    

801035ad <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801035ad:	55                   	push   %ebp
801035ae:	89 e5                	mov    %esp,%ebp
801035b0:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801035b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801035b6:	89 44 24 04          	mov    %eax,0x4(%esp)
801035ba:	8b 45 08             	mov    0x8(%ebp),%eax
801035bd:	89 04 24             	mov    %eax,(%esp)
801035c0:	e8 0c 00 00 00       	call   801035d1 <freerange>
  kmem.use_lock = 1;
801035c5:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
801035cc:	00 00 00 
}
801035cf:	c9                   	leave  
801035d0:	c3                   	ret    

801035d1 <freerange>:

void
freerange(void *vstart, void *vend)
{
801035d1:	55                   	push   %ebp
801035d2:	89 e5                	mov    %esp,%ebp
801035d4:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801035d7:	8b 45 08             	mov    0x8(%ebp),%eax
801035da:	05 ff 0f 00 00       	add    $0xfff,%eax
801035df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801035e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801035e7:	eb 12                	jmp    801035fb <freerange+0x2a>
    kfree(p);
801035e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035ec:	89 04 24             	mov    %eax,(%esp)
801035ef:	e8 16 00 00 00       	call   8010360a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801035f4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801035fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035fe:	05 00 10 00 00       	add    $0x1000,%eax
80103603:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103606:	76 e1                	jbe    801035e9 <freerange+0x18>
    kfree(p);
}
80103608:	c9                   	leave  
80103609:	c3                   	ret    

8010360a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
8010360a:	55                   	push   %ebp
8010360b:	89 e5                	mov    %esp,%ebp
8010360d:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103610:	8b 45 08             	mov    0x8(%ebp),%eax
80103613:	25 ff 0f 00 00       	and    $0xfff,%eax
80103618:	85 c0                	test   %eax,%eax
8010361a:	75 1b                	jne    80103637 <kfree+0x2d>
8010361c:	81 7d 08 1c 37 11 80 	cmpl   $0x8011371c,0x8(%ebp)
80103623:	72 12                	jb     80103637 <kfree+0x2d>
80103625:	8b 45 08             	mov    0x8(%ebp),%eax
80103628:	89 04 24             	mov    %eax,(%esp)
8010362b:	e8 38 ff ff ff       	call   80103568 <v2p>
80103630:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103635:	76 0c                	jbe    80103643 <kfree+0x39>
    panic("kfree");
80103637:	c7 04 24 4b 91 10 80 	movl   $0x8010914b,(%esp)
8010363e:	e8 fa ce ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103643:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010364a:	00 
8010364b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103652:	00 
80103653:	8b 45 08             	mov    0x8(%ebp),%eax
80103656:	89 04 24             	mov    %eax,(%esp)
80103659:	e8 38 23 00 00       	call   80105996 <memset>

  if(kmem.use_lock)
8010365e:	a1 94 08 11 80       	mov    0x80110894,%eax
80103663:	85 c0                	test   %eax,%eax
80103665:	74 0c                	je     80103673 <kfree+0x69>
    acquire(&kmem.lock);
80103667:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
8010366e:	e8 d4 20 00 00       	call   80105747 <acquire>
  r = (struct run*)v;
80103673:	8b 45 08             	mov    0x8(%ebp),%eax
80103676:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103679:	8b 15 98 08 11 80    	mov    0x80110898,%edx
8010367f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103682:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103684:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103687:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
8010368c:	a1 94 08 11 80       	mov    0x80110894,%eax
80103691:	85 c0                	test   %eax,%eax
80103693:	74 0c                	je     801036a1 <kfree+0x97>
    release(&kmem.lock);
80103695:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
8010369c:	e8 08 21 00 00       	call   801057a9 <release>
}
801036a1:	c9                   	leave  
801036a2:	c3                   	ret    

801036a3 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801036a3:	55                   	push   %ebp
801036a4:	89 e5                	mov    %esp,%ebp
801036a6:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
801036a9:	a1 94 08 11 80       	mov    0x80110894,%eax
801036ae:	85 c0                	test   %eax,%eax
801036b0:	74 0c                	je     801036be <kalloc+0x1b>
    acquire(&kmem.lock);
801036b2:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801036b9:	e8 89 20 00 00       	call   80105747 <acquire>
  r = kmem.freelist;
801036be:	a1 98 08 11 80       	mov    0x80110898,%eax
801036c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801036c6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801036ca:	74 0a                	je     801036d6 <kalloc+0x33>
    kmem.freelist = r->next;
801036cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036cf:	8b 00                	mov    (%eax),%eax
801036d1:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
801036d6:	a1 94 08 11 80       	mov    0x80110894,%eax
801036db:	85 c0                	test   %eax,%eax
801036dd:	74 0c                	je     801036eb <kalloc+0x48>
    release(&kmem.lock);
801036df:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801036e6:	e8 be 20 00 00       	call   801057a9 <release>
  return (char*)r;
801036eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801036ee:	c9                   	leave  
801036ef:	c3                   	ret    

801036f0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801036f0:	55                   	push   %ebp
801036f1:	89 e5                	mov    %esp,%ebp
801036f3:	53                   	push   %ebx
801036f4:	83 ec 14             	sub    $0x14,%esp
801036f7:	8b 45 08             	mov    0x8(%ebp),%eax
801036fa:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801036fe:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103702:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103706:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010370a:	ec                   	in     (%dx),%al
8010370b:	89 c3                	mov    %eax,%ebx
8010370d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103710:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103714:	83 c4 14             	add    $0x14,%esp
80103717:	5b                   	pop    %ebx
80103718:	5d                   	pop    %ebp
80103719:	c3                   	ret    

8010371a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010371a:	55                   	push   %ebp
8010371b:	89 e5                	mov    %esp,%ebp
8010371d:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103720:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103727:	e8 c4 ff ff ff       	call   801036f0 <inb>
8010372c:	0f b6 c0             	movzbl %al,%eax
8010372f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103732:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103735:	83 e0 01             	and    $0x1,%eax
80103738:	85 c0                	test   %eax,%eax
8010373a:	75 0a                	jne    80103746 <kbdgetc+0x2c>
    return -1;
8010373c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103741:	e9 23 01 00 00       	jmp    80103869 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103746:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
8010374d:	e8 9e ff ff ff       	call   801036f0 <inb>
80103752:	0f b6 c0             	movzbl %al,%eax
80103755:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103758:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
8010375f:	75 17                	jne    80103778 <kbdgetc+0x5e>
    shift |= E0ESC;
80103761:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103766:	83 c8 40             	or     $0x40,%eax
80103769:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
8010376e:	b8 00 00 00 00       	mov    $0x0,%eax
80103773:	e9 f1 00 00 00       	jmp    80103869 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103778:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010377b:	25 80 00 00 00       	and    $0x80,%eax
80103780:	85 c0                	test   %eax,%eax
80103782:	74 45                	je     801037c9 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103784:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103789:	83 e0 40             	and    $0x40,%eax
8010378c:	85 c0                	test   %eax,%eax
8010378e:	75 08                	jne    80103798 <kbdgetc+0x7e>
80103790:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103793:	83 e0 7f             	and    $0x7f,%eax
80103796:	eb 03                	jmp    8010379b <kbdgetc+0x81>
80103798:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010379b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
8010379e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037a1:	05 20 a0 10 80       	add    $0x8010a020,%eax
801037a6:	0f b6 00             	movzbl (%eax),%eax
801037a9:	83 c8 40             	or     $0x40,%eax
801037ac:	0f b6 c0             	movzbl %al,%eax
801037af:	f7 d0                	not    %eax
801037b1:	89 c2                	mov    %eax,%edx
801037b3:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801037b8:	21 d0                	and    %edx,%eax
801037ba:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
801037bf:	b8 00 00 00 00       	mov    $0x0,%eax
801037c4:	e9 a0 00 00 00       	jmp    80103869 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
801037c9:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801037ce:	83 e0 40             	and    $0x40,%eax
801037d1:	85 c0                	test   %eax,%eax
801037d3:	74 14                	je     801037e9 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801037d5:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801037dc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801037e1:	83 e0 bf             	and    $0xffffffbf,%eax
801037e4:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
801037e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037ec:	05 20 a0 10 80       	add    $0x8010a020,%eax
801037f1:	0f b6 00             	movzbl (%eax),%eax
801037f4:	0f b6 d0             	movzbl %al,%edx
801037f7:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
801037fc:	09 d0                	or     %edx,%eax
801037fe:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103803:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103806:	05 20 a1 10 80       	add    $0x8010a120,%eax
8010380b:	0f b6 00             	movzbl (%eax),%eax
8010380e:	0f b6 d0             	movzbl %al,%edx
80103811:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103816:	31 d0                	xor    %edx,%eax
80103818:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
8010381d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103822:	83 e0 03             	and    $0x3,%eax
80103825:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
8010382c:	03 45 fc             	add    -0x4(%ebp),%eax
8010382f:	0f b6 00             	movzbl (%eax),%eax
80103832:	0f b6 c0             	movzbl %al,%eax
80103835:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103838:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
8010383d:	83 e0 08             	and    $0x8,%eax
80103840:	85 c0                	test   %eax,%eax
80103842:	74 22                	je     80103866 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103844:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103848:	76 0c                	jbe    80103856 <kbdgetc+0x13c>
8010384a:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
8010384e:	77 06                	ja     80103856 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103850:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103854:	eb 10                	jmp    80103866 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103856:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010385a:	76 0a                	jbe    80103866 <kbdgetc+0x14c>
8010385c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103860:	77 04                	ja     80103866 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103862:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103866:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103869:	c9                   	leave  
8010386a:	c3                   	ret    

8010386b <kbdintr>:

void
kbdintr(void)
{
8010386b:	55                   	push   %ebp
8010386c:	89 e5                	mov    %esp,%ebp
8010386e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103871:	c7 04 24 1a 37 10 80 	movl   $0x8010371a,(%esp)
80103878:	e8 30 cf ff ff       	call   801007ad <consoleintr>
}
8010387d:	c9                   	leave  
8010387e:	c3                   	ret    
	...

80103880 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103880:	55                   	push   %ebp
80103881:	89 e5                	mov    %esp,%ebp
80103883:	83 ec 08             	sub    $0x8,%esp
80103886:	8b 55 08             	mov    0x8(%ebp),%edx
80103889:	8b 45 0c             	mov    0xc(%ebp),%eax
8010388c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103890:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103893:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103897:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010389b:	ee                   	out    %al,(%dx)
}
8010389c:	c9                   	leave  
8010389d:	c3                   	ret    

8010389e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010389e:	55                   	push   %ebp
8010389f:	89 e5                	mov    %esp,%ebp
801038a1:	53                   	push   %ebx
801038a2:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801038a5:	9c                   	pushf  
801038a6:	5b                   	pop    %ebx
801038a7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801038aa:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801038ad:	83 c4 10             	add    $0x10,%esp
801038b0:	5b                   	pop    %ebx
801038b1:	5d                   	pop    %ebp
801038b2:	c3                   	ret    

801038b3 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801038b3:	55                   	push   %ebp
801038b4:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801038b6:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801038bb:	8b 55 08             	mov    0x8(%ebp),%edx
801038be:	c1 e2 02             	shl    $0x2,%edx
801038c1:	01 c2                	add    %eax,%edx
801038c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801038c6:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
801038c8:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801038cd:	83 c0 20             	add    $0x20,%eax
801038d0:	8b 00                	mov    (%eax),%eax
}
801038d2:	5d                   	pop    %ebp
801038d3:	c3                   	ret    

801038d4 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
801038d4:	55                   	push   %ebp
801038d5:	89 e5                	mov    %esp,%ebp
801038d7:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801038da:	a1 9c 08 11 80       	mov    0x8011089c,%eax
801038df:	85 c0                	test   %eax,%eax
801038e1:	0f 84 47 01 00 00    	je     80103a2e <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801038e7:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801038ee:	00 
801038ef:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801038f6:	e8 b8 ff ff ff       	call   801038b3 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801038fb:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103902:	00 
80103903:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
8010390a:	e8 a4 ff ff ff       	call   801038b3 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010390f:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103916:	00 
80103917:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010391e:	e8 90 ff ff ff       	call   801038b3 <lapicw>
  lapicw(TICR, 10000000); 
80103923:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010392a:	00 
8010392b:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103932:	e8 7c ff ff ff       	call   801038b3 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103937:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010393e:	00 
8010393f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103946:	e8 68 ff ff ff       	call   801038b3 <lapicw>
  lapicw(LINT1, MASKED);
8010394b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103952:	00 
80103953:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010395a:	e8 54 ff ff ff       	call   801038b3 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010395f:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103964:	83 c0 30             	add    $0x30,%eax
80103967:	8b 00                	mov    (%eax),%eax
80103969:	c1 e8 10             	shr    $0x10,%eax
8010396c:	25 ff 00 00 00       	and    $0xff,%eax
80103971:	83 f8 03             	cmp    $0x3,%eax
80103974:	76 14                	jbe    8010398a <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103976:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010397d:	00 
8010397e:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103985:	e8 29 ff ff ff       	call   801038b3 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010398a:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103991:	00 
80103992:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103999:	e8 15 ff ff ff       	call   801038b3 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
8010399e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801039a5:	00 
801039a6:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801039ad:	e8 01 ff ff ff       	call   801038b3 <lapicw>
  lapicw(ESR, 0);
801039b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801039b9:	00 
801039ba:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801039c1:	e8 ed fe ff ff       	call   801038b3 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801039c6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801039cd:	00 
801039ce:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801039d5:	e8 d9 fe ff ff       	call   801038b3 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801039da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801039e1:	00 
801039e2:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801039e9:	e8 c5 fe ff ff       	call   801038b3 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801039ee:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801039f5:	00 
801039f6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801039fd:	e8 b1 fe ff ff       	call   801038b3 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103a02:	90                   	nop
80103a03:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103a08:	05 00 03 00 00       	add    $0x300,%eax
80103a0d:	8b 00                	mov    (%eax),%eax
80103a0f:	25 00 10 00 00       	and    $0x1000,%eax
80103a14:	85 c0                	test   %eax,%eax
80103a16:	75 eb                	jne    80103a03 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103a18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103a1f:	00 
80103a20:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103a27:	e8 87 fe ff ff       	call   801038b3 <lapicw>
80103a2c:	eb 01                	jmp    80103a2f <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103a2e:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103a2f:	c9                   	leave  
80103a30:	c3                   	ret    

80103a31 <cpunum>:

int
cpunum(void)
{
80103a31:	55                   	push   %ebp
80103a32:	89 e5                	mov    %esp,%ebp
80103a34:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103a37:	e8 62 fe ff ff       	call   8010389e <readeflags>
80103a3c:	25 00 02 00 00       	and    $0x200,%eax
80103a41:	85 c0                	test   %eax,%eax
80103a43:	74 29                	je     80103a6e <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103a45:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103a4a:	85 c0                	test   %eax,%eax
80103a4c:	0f 94 c2             	sete   %dl
80103a4f:	83 c0 01             	add    $0x1,%eax
80103a52:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80103a57:	84 d2                	test   %dl,%dl
80103a59:	74 13                	je     80103a6e <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103a5b:	8b 45 04             	mov    0x4(%ebp),%eax
80103a5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a62:	c7 04 24 54 91 10 80 	movl   $0x80109154,(%esp)
80103a69:	e8 33 c9 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103a6e:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103a73:	85 c0                	test   %eax,%eax
80103a75:	74 0f                	je     80103a86 <cpunum+0x55>
    return lapic[ID]>>24;
80103a77:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103a7c:	83 c0 20             	add    $0x20,%eax
80103a7f:	8b 00                	mov    (%eax),%eax
80103a81:	c1 e8 18             	shr    $0x18,%eax
80103a84:	eb 05                	jmp    80103a8b <cpunum+0x5a>
  return 0;
80103a86:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103a8b:	c9                   	leave  
80103a8c:	c3                   	ret    

80103a8d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103a8d:	55                   	push   %ebp
80103a8e:	89 e5                	mov    %esp,%ebp
80103a90:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103a93:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103a98:	85 c0                	test   %eax,%eax
80103a9a:	74 14                	je     80103ab0 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103a9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103aa3:	00 
80103aa4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103aab:	e8 03 fe ff ff       	call   801038b3 <lapicw>
}
80103ab0:	c9                   	leave  
80103ab1:	c3                   	ret    

80103ab2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103ab2:	55                   	push   %ebp
80103ab3:	89 e5                	mov    %esp,%ebp
}
80103ab5:	5d                   	pop    %ebp
80103ab6:	c3                   	ret    

80103ab7 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103ab7:	55                   	push   %ebp
80103ab8:	89 e5                	mov    %esp,%ebp
80103aba:	83 ec 1c             	sub    $0x1c,%esp
80103abd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ac0:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103ac3:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103aca:	00 
80103acb:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103ad2:	e8 a9 fd ff ff       	call   80103880 <outb>
  outb(IO_RTC+1, 0x0A);
80103ad7:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103ade:	00 
80103adf:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103ae6:	e8 95 fd ff ff       	call   80103880 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103aeb:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103af2:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103af5:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103afa:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103afd:	8d 50 02             	lea    0x2(%eax),%edx
80103b00:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b03:	c1 e8 04             	shr    $0x4,%eax
80103b06:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103b09:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103b0d:	c1 e0 18             	shl    $0x18,%eax
80103b10:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b14:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103b1b:	e8 93 fd ff ff       	call   801038b3 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103b20:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103b27:	00 
80103b28:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103b2f:	e8 7f fd ff ff       	call   801038b3 <lapicw>
  microdelay(200);
80103b34:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103b3b:	e8 72 ff ff ff       	call   80103ab2 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103b40:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103b47:	00 
80103b48:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103b4f:	e8 5f fd ff ff       	call   801038b3 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103b54:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103b5b:	e8 52 ff ff ff       	call   80103ab2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103b60:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103b67:	eb 40                	jmp    80103ba9 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103b69:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103b6d:	c1 e0 18             	shl    $0x18,%eax
80103b70:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b74:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103b7b:	e8 33 fd ff ff       	call   801038b3 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103b80:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b83:	c1 e8 0c             	shr    $0xc,%eax
80103b86:	80 cc 06             	or     $0x6,%ah
80103b89:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b8d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103b94:	e8 1a fd ff ff       	call   801038b3 <lapicw>
    microdelay(200);
80103b99:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103ba0:	e8 0d ff ff ff       	call   80103ab2 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103ba5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103ba9:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103bad:	7e ba                	jle    80103b69 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103baf:	c9                   	leave  
80103bb0:	c3                   	ret    
80103bb1:	00 00                	add    %al,(%eax)
	...

80103bb4 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103bb4:	55                   	push   %ebp
80103bb5:	89 e5                	mov    %esp,%ebp
80103bb7:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103bba:	c7 44 24 04 80 91 10 	movl   $0x80109180,0x4(%esp)
80103bc1:	80 
80103bc2:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103bc9:	e8 58 1b 00 00       	call   80105726 <initlock>
  readsb(ROOTDEV, &sb);
80103bce:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103bd1:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bd5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103bdc:	e8 8b e1 ff ff       	call   80101d6c <readsb>
  log.start = sb.size - sb.nlog;
80103be1:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103be4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be7:	89 d1                	mov    %edx,%ecx
80103be9:	29 c1                	sub    %eax,%ecx
80103beb:	89 c8                	mov    %ecx,%eax
80103bed:	a3 d4 08 11 80       	mov    %eax,0x801108d4
  log.size = sb.nlog;
80103bf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bf5:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  log.dev = ROOTDEV;
80103bfa:	c7 05 e0 08 11 80 01 	movl   $0x1,0x801108e0
80103c01:	00 00 00 
  recover_from_log();
80103c04:	e8 97 01 00 00       	call   80103da0 <recover_from_log>
}
80103c09:	c9                   	leave  
80103c0a:	c3                   	ret    

80103c0b <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103c0b:	55                   	push   %ebp
80103c0c:	89 e5                	mov    %esp,%ebp
80103c0e:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103c11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103c18:	e9 89 00 00 00       	jmp    80103ca6 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103c1d:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103c22:	03 45 f4             	add    -0xc(%ebp),%eax
80103c25:	83 c0 01             	add    $0x1,%eax
80103c28:	89 c2                	mov    %eax,%edx
80103c2a:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103c2f:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c33:	89 04 24             	mov    %eax,(%esp)
80103c36:	e8 6b c5 ff ff       	call   801001a6 <bread>
80103c3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103c3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c41:	83 c0 10             	add    $0x10,%eax
80103c44:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103c4b:	89 c2                	mov    %eax,%edx
80103c4d:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103c52:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c56:	89 04 24             	mov    %eax,(%esp)
80103c59:	e8 48 c5 ff ff       	call   801001a6 <bread>
80103c5e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103c61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c64:	8d 50 18             	lea    0x18(%eax),%edx
80103c67:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c6a:	83 c0 18             	add    $0x18,%eax
80103c6d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103c74:	00 
80103c75:	89 54 24 04          	mov    %edx,0x4(%esp)
80103c79:	89 04 24             	mov    %eax,(%esp)
80103c7c:	e8 e8 1d 00 00       	call   80105a69 <memmove>
    bwrite(dbuf);  // write dst to disk
80103c81:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c84:	89 04 24             	mov    %eax,(%esp)
80103c87:	e8 51 c5 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c8f:	89 04 24             	mov    %eax,(%esp)
80103c92:	e8 80 c5 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103c97:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c9a:	89 04 24             	mov    %eax,(%esp)
80103c9d:	e8 75 c5 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103ca2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ca6:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103cab:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103cae:	0f 8f 69 ff ff ff    	jg     80103c1d <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103cb4:	c9                   	leave  
80103cb5:	c3                   	ret    

80103cb6 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103cb6:	55                   	push   %ebp
80103cb7:	89 e5                	mov    %esp,%ebp
80103cb9:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103cbc:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103cc1:	89 c2                	mov    %eax,%edx
80103cc3:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80103ccc:	89 04 24             	mov    %eax,(%esp)
80103ccf:	e8 d2 c4 ff ff       	call   801001a6 <bread>
80103cd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103cd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cda:	83 c0 18             	add    $0x18,%eax
80103cdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ce3:	8b 00                	mov    (%eax),%eax
80103ce5:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  for (i = 0; i < log.lh.n; i++) {
80103cea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103cf1:	eb 1b                	jmp    80103d0e <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103cf3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103cf6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103cf9:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103cfd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d00:	83 c2 10             	add    $0x10,%edx
80103d03:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103d0a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d0e:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103d13:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d16:	7f db                	jg     80103cf3 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80103d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d1b:	89 04 24             	mov    %eax,(%esp)
80103d1e:	e8 f4 c4 ff ff       	call   80100217 <brelse>
}
80103d23:	c9                   	leave  
80103d24:	c3                   	ret    

80103d25 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103d25:	55                   	push   %ebp
80103d26:	89 e5                	mov    %esp,%ebp
80103d28:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103d2b:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103d30:	89 c2                	mov    %eax,%edx
80103d32:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103d37:	89 54 24 04          	mov    %edx,0x4(%esp)
80103d3b:	89 04 24             	mov    %eax,(%esp)
80103d3e:	e8 63 c4 ff ff       	call   801001a6 <bread>
80103d43:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103d46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d49:	83 c0 18             	add    $0x18,%eax
80103d4c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103d4f:	8b 15 e4 08 11 80    	mov    0x801108e4,%edx
80103d55:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d58:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103d5a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103d61:	eb 1b                	jmp    80103d7e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d66:	83 c0 10             	add    $0x10,%eax
80103d69:	8b 0c 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%ecx
80103d70:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103d73:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d76:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103d7a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103d7e:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103d83:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103d86:	7f db                	jg     80103d63 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d8b:	89 04 24             	mov    %eax,(%esp)
80103d8e:	e8 4a c4 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103d93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d96:	89 04 24             	mov    %eax,(%esp)
80103d99:	e8 79 c4 ff ff       	call   80100217 <brelse>
}
80103d9e:	c9                   	leave  
80103d9f:	c3                   	ret    

80103da0 <recover_from_log>:

static void
recover_from_log(void)
{
80103da0:	55                   	push   %ebp
80103da1:	89 e5                	mov    %esp,%ebp
80103da3:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103da6:	e8 0b ff ff ff       	call   80103cb6 <read_head>
  install_trans(); // if committed, copy from log to disk
80103dab:	e8 5b fe ff ff       	call   80103c0b <install_trans>
  log.lh.n = 0;
80103db0:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
80103db7:	00 00 00 
  write_head(); // clear the log
80103dba:	e8 66 ff ff ff       	call   80103d25 <write_head>
}
80103dbf:	c9                   	leave  
80103dc0:	c3                   	ret    

80103dc1 <begin_trans>:

void
begin_trans(void)
{
80103dc1:	55                   	push   %ebp
80103dc2:	89 e5                	mov    %esp,%ebp
80103dc4:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103dc7:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103dce:	e8 74 19 00 00       	call   80105747 <acquire>
  while (log.busy) {
80103dd3:	eb 14                	jmp    80103de9 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103dd5:	c7 44 24 04 a0 08 11 	movl   $0x801108a0,0x4(%esp)
80103ddc:	80 
80103ddd:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103de4:	e8 80 16 00 00       	call   80105469 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103de9:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103dee:	85 c0                	test   %eax,%eax
80103df0:	75 e3                	jne    80103dd5 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80103df2:	c7 05 dc 08 11 80 01 	movl   $0x1,0x801108dc
80103df9:	00 00 00 
  release(&log.lock);
80103dfc:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e03:	e8 a1 19 00 00       	call   801057a9 <release>
}
80103e08:	c9                   	leave  
80103e09:	c3                   	ret    

80103e0a <commit_trans>:

void
commit_trans(void)
{
80103e0a:	55                   	push   %ebp
80103e0b:	89 e5                	mov    %esp,%ebp
80103e0d:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103e10:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103e15:	85 c0                	test   %eax,%eax
80103e17:	7e 19                	jle    80103e32 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80103e19:	e8 07 ff ff ff       	call   80103d25 <write_head>
    install_trans(); // Now install writes to home locations
80103e1e:	e8 e8 fd ff ff       	call   80103c0b <install_trans>
    log.lh.n = 0; 
80103e23:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
80103e2a:	00 00 00 
    write_head();    // Erase the transaction from the log
80103e2d:	e8 f3 fe ff ff       	call   80103d25 <write_head>
  }
  
  acquire(&log.lock);
80103e32:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e39:	e8 09 19 00 00       	call   80105747 <acquire>
  log.busy = 0;
80103e3e:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80103e45:	00 00 00 
  wakeup(&log);
80103e48:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e4f:	e8 ee 16 00 00       	call   80105542 <wakeup>
  release(&log.lock);
80103e54:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103e5b:	e8 49 19 00 00       	call   801057a9 <release>
}
80103e60:	c9                   	leave  
80103e61:	c3                   	ret    

80103e62 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103e62:	55                   	push   %ebp
80103e63:	89 e5                	mov    %esp,%ebp
80103e65:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103e68:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103e6d:	83 f8 09             	cmp    $0x9,%eax
80103e70:	7f 12                	jg     80103e84 <log_write+0x22>
80103e72:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103e77:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80103e7d:	83 ea 01             	sub    $0x1,%edx
80103e80:	39 d0                	cmp    %edx,%eax
80103e82:	7c 0c                	jl     80103e90 <log_write+0x2e>
    panic("too big a transaction");
80103e84:	c7 04 24 84 91 10 80 	movl   $0x80109184,(%esp)
80103e8b:	e8 ad c6 ff ff       	call   8010053d <panic>
  if (!log.busy)
80103e90:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103e95:	85 c0                	test   %eax,%eax
80103e97:	75 0c                	jne    80103ea5 <log_write+0x43>
    panic("write outside of trans");
80103e99:	c7 04 24 9a 91 10 80 	movl   $0x8010919a,(%esp)
80103ea0:	e8 98 c6 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103ea5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103eac:	eb 1d                	jmp    80103ecb <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eb1:	83 c0 10             	add    $0x10,%eax
80103eb4:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103ebb:	89 c2                	mov    %eax,%edx
80103ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec0:	8b 40 08             	mov    0x8(%eax),%eax
80103ec3:	39 c2                	cmp    %eax,%edx
80103ec5:	74 10                	je     80103ed7 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103ec7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103ecb:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103ed0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ed3:	7f d9                	jg     80103eae <log_write+0x4c>
80103ed5:	eb 01                	jmp    80103ed8 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103ed7:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103ed8:	8b 45 08             	mov    0x8(%ebp),%eax
80103edb:	8b 40 08             	mov    0x8(%eax),%eax
80103ede:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ee1:	83 c2 10             	add    $0x10,%edx
80103ee4:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
80103eeb:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103ef0:	03 45 f4             	add    -0xc(%ebp),%eax
80103ef3:	83 c0 01             	add    $0x1,%eax
80103ef6:	89 c2                	mov    %eax,%edx
80103ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80103efb:	8b 40 04             	mov    0x4(%eax),%eax
80103efe:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f02:	89 04 24             	mov    %eax,(%esp)
80103f05:	e8 9c c2 ff ff       	call   801001a6 <bread>
80103f0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f10:	8d 50 18             	lea    0x18(%eax),%edx
80103f13:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f16:	83 c0 18             	add    $0x18,%eax
80103f19:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103f20:	00 
80103f21:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f25:	89 04 24             	mov    %eax,(%esp)
80103f28:	e8 3c 1b 00 00       	call   80105a69 <memmove>
  bwrite(lbuf);
80103f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f30:	89 04 24             	mov    %eax,(%esp)
80103f33:	e8 a5 c2 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103f38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f3b:	89 04 24             	mov    %eax,(%esp)
80103f3e:	e8 d4 c2 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103f43:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103f48:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103f4b:	75 0d                	jne    80103f5a <log_write+0xf8>
    log.lh.n++;
80103f4d:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103f52:	83 c0 01             	add    $0x1,%eax
80103f55:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103f5a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f5d:	8b 00                	mov    (%eax),%eax
80103f5f:	89 c2                	mov    %eax,%edx
80103f61:	83 ca 04             	or     $0x4,%edx
80103f64:	8b 45 08             	mov    0x8(%ebp),%eax
80103f67:	89 10                	mov    %edx,(%eax)
}
80103f69:	c9                   	leave  
80103f6a:	c3                   	ret    
	...

80103f6c <v2p>:
80103f6c:	55                   	push   %ebp
80103f6d:	89 e5                	mov    %esp,%ebp
80103f6f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f72:	05 00 00 00 80       	add    $0x80000000,%eax
80103f77:	5d                   	pop    %ebp
80103f78:	c3                   	ret    

80103f79 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103f79:	55                   	push   %ebp
80103f7a:	89 e5                	mov    %esp,%ebp
80103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f7f:	05 00 00 00 80       	add    $0x80000000,%eax
80103f84:	5d                   	pop    %ebp
80103f85:	c3                   	ret    

80103f86 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103f86:	55                   	push   %ebp
80103f87:	89 e5                	mov    %esp,%ebp
80103f89:	53                   	push   %ebx
80103f8a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103f8d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103f90:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103f93:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103f96:	89 c3                	mov    %eax,%ebx
80103f98:	89 d8                	mov    %ebx,%eax
80103f9a:	f0 87 02             	lock xchg %eax,(%edx)
80103f9d:	89 c3                	mov    %eax,%ebx
80103f9f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103fa2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103fa5:	83 c4 10             	add    $0x10,%esp
80103fa8:	5b                   	pop    %ebx
80103fa9:	5d                   	pop    %ebp
80103faa:	c3                   	ret    

80103fab <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103fab:	55                   	push   %ebp
80103fac:	89 e5                	mov    %esp,%ebp
80103fae:	83 e4 f0             	and    $0xfffffff0,%esp
80103fb1:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103fb4:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103fbb:	80 
80103fbc:	c7 04 24 1c 37 11 80 	movl   $0x8011371c,(%esp)
80103fc3:	e8 ad f5 ff ff       	call   80103575 <kinit1>
  kvmalloc();      // kernel page table
80103fc8:	e8 69 47 00 00       	call   80108736 <kvmalloc>
  mpinit();        // collect info about this machine
80103fcd:	e8 63 04 00 00       	call   80104435 <mpinit>
  lapicinit(mpbcpu());
80103fd2:	e8 2e 02 00 00       	call   80104205 <mpbcpu>
80103fd7:	89 04 24             	mov    %eax,(%esp)
80103fda:	e8 f5 f8 ff ff       	call   801038d4 <lapicinit>
  seginit();       // set up segments
80103fdf:	e8 f5 40 00 00       	call   801080d9 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103fe4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103fea:	0f b6 00             	movzbl (%eax),%eax
80103fed:	0f b6 c0             	movzbl %al,%eax
80103ff0:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ff4:	c7 04 24 b1 91 10 80 	movl   $0x801091b1,(%esp)
80103ffb:	e8 a1 c3 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104000:	e8 95 06 00 00       	call   8010469a <picinit>
  ioapicinit();    // another interrupt controller
80104005:	e8 5b f4 ff ff       	call   80103465 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010400a:	e8 7e ca ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
8010400f:	e8 10 34 00 00       	call   80107424 <uartinit>
  pinit();         // process table
80104014:	e8 96 0b 00 00       	call   80104baf <pinit>
  tvinit();        // trap vectors
80104019:	e8 a9 2f 00 00       	call   80106fc7 <tvinit>
  binit();         // buffer cache
8010401e:	e8 11 c0 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80104023:	e8 d8 ce ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80104028:	e8 06 e0 ff ff       	call   80102033 <iinit>
  ideinit();       // disk
8010402d:	e8 98 f0 ff ff       	call   801030ca <ideinit>
  if(!ismp)
80104032:	a1 24 09 11 80       	mov    0x80110924,%eax
80104037:	85 c0                	test   %eax,%eax
80104039:	75 05                	jne    80104040 <main+0x95>
    timerinit();   // uniprocessor timer
8010403b:	e8 ca 2e 00 00       	call   80106f0a <timerinit>
  startothers();   // start other processors
80104040:	e8 87 00 00 00       	call   801040cc <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104045:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
8010404c:	8e 
8010404d:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104054:	e8 54 f5 ff ff       	call   801035ad <kinit2>
  userinit();      // first user process
80104059:	e8 6c 0c 00 00       	call   80104cca <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010405e:	e8 22 00 00 00       	call   80104085 <mpmain>

80104063 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80104063:	55                   	push   %ebp
80104064:	89 e5                	mov    %esp,%ebp
80104066:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80104069:	e8 df 46 00 00       	call   8010874d <switchkvm>
  seginit();
8010406e:	e8 66 40 00 00       	call   801080d9 <seginit>
  lapicinit(cpunum());
80104073:	e8 b9 f9 ff ff       	call   80103a31 <cpunum>
80104078:	89 04 24             	mov    %eax,(%esp)
8010407b:	e8 54 f8 ff ff       	call   801038d4 <lapicinit>
  mpmain();
80104080:	e8 00 00 00 00       	call   80104085 <mpmain>

80104085 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104085:	55                   	push   %ebp
80104086:	89 e5                	mov    %esp,%ebp
80104088:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010408b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104091:	0f b6 00             	movzbl (%eax),%eax
80104094:	0f b6 c0             	movzbl %al,%eax
80104097:	89 44 24 04          	mov    %eax,0x4(%esp)
8010409b:	c7 04 24 c8 91 10 80 	movl   $0x801091c8,(%esp)
801040a2:	e8 fa c2 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801040a7:	e8 8f 30 00 00       	call   8010713b <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801040ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801040b2:	05 a8 00 00 00       	add    $0xa8,%eax
801040b7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801040be:	00 
801040bf:	89 04 24             	mov    %eax,(%esp)
801040c2:	e8 bf fe ff ff       	call   80103f86 <xchg>
  scheduler();     // start running processes
801040c7:	e8 f4 11 00 00       	call   801052c0 <scheduler>

801040cc <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801040cc:	55                   	push   %ebp
801040cd:	89 e5                	mov    %esp,%ebp
801040cf:	53                   	push   %ebx
801040d0:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801040d3:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801040da:	e8 9a fe ff ff       	call   80103f79 <p2v>
801040df:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801040e2:	b8 8a 00 00 00       	mov    $0x8a,%eax
801040e7:	89 44 24 08          	mov    %eax,0x8(%esp)
801040eb:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
801040f2:	80 
801040f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040f6:	89 04 24             	mov    %eax,(%esp)
801040f9:	e8 6b 19 00 00       	call   80105a69 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801040fe:	c7 45 f4 40 09 11 80 	movl   $0x80110940,-0xc(%ebp)
80104105:	e9 86 00 00 00       	jmp    80104190 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010410a:	e8 22 f9 ff ff       	call   80103a31 <cpunum>
8010410f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104115:	05 40 09 11 80       	add    $0x80110940,%eax
8010411a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010411d:	74 69                	je     80104188 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010411f:	e8 7f f5 ff ff       	call   801036a3 <kalloc>
80104124:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104127:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010412a:	83 e8 04             	sub    $0x4,%eax
8010412d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104130:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104136:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104138:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010413b:	83 e8 08             	sub    $0x8,%eax
8010413e:	c7 00 63 40 10 80    	movl   $0x80104063,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104144:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104147:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010414a:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104151:	e8 16 fe ff ff       	call   80103f6c <v2p>
80104156:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104158:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010415b:	89 04 24             	mov    %eax,(%esp)
8010415e:	e8 09 fe ff ff       	call   80103f6c <v2p>
80104163:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104166:	0f b6 12             	movzbl (%edx),%edx
80104169:	0f b6 d2             	movzbl %dl,%edx
8010416c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104170:	89 14 24             	mov    %edx,(%esp)
80104173:	e8 3f f9 ff ff       	call   80103ab7 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104178:	90                   	nop
80104179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104182:	85 c0                	test   %eax,%eax
80104184:	74 f3                	je     80104179 <startothers+0xad>
80104186:	eb 01                	jmp    80104189 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80104188:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104189:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104190:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104195:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010419b:	05 40 09 11 80       	add    $0x80110940,%eax
801041a0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801041a3:	0f 87 61 ff ff ff    	ja     8010410a <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801041a9:	83 c4 24             	add    $0x24,%esp
801041ac:	5b                   	pop    %ebx
801041ad:	5d                   	pop    %ebp
801041ae:	c3                   	ret    
	...

801041b0 <p2v>:
801041b0:	55                   	push   %ebp
801041b1:	89 e5                	mov    %esp,%ebp
801041b3:	8b 45 08             	mov    0x8(%ebp),%eax
801041b6:	05 00 00 00 80       	add    $0x80000000,%eax
801041bb:	5d                   	pop    %ebp
801041bc:	c3                   	ret    

801041bd <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801041bd:	55                   	push   %ebp
801041be:	89 e5                	mov    %esp,%ebp
801041c0:	53                   	push   %ebx
801041c1:	83 ec 14             	sub    $0x14,%esp
801041c4:	8b 45 08             	mov    0x8(%ebp),%eax
801041c7:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801041cb:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801041cf:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801041d3:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801041d7:	ec                   	in     (%dx),%al
801041d8:	89 c3                	mov    %eax,%ebx
801041da:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801041dd:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801041e1:	83 c4 14             	add    $0x14,%esp
801041e4:	5b                   	pop    %ebx
801041e5:	5d                   	pop    %ebp
801041e6:	c3                   	ret    

801041e7 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801041e7:	55                   	push   %ebp
801041e8:	89 e5                	mov    %esp,%ebp
801041ea:	83 ec 08             	sub    $0x8,%esp
801041ed:	8b 55 08             	mov    0x8(%ebp),%edx
801041f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801041f3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801041f7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801041fa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801041fe:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104202:	ee                   	out    %al,(%dx)
}
80104203:	c9                   	leave  
80104204:	c3                   	ret    

80104205 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104205:	55                   	push   %ebp
80104206:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104208:	a1 64 c6 10 80       	mov    0x8010c664,%eax
8010420d:	89 c2                	mov    %eax,%edx
8010420f:	b8 40 09 11 80       	mov    $0x80110940,%eax
80104214:	89 d1                	mov    %edx,%ecx
80104216:	29 c1                	sub    %eax,%ecx
80104218:	89 c8                	mov    %ecx,%eax
8010421a:	c1 f8 02             	sar    $0x2,%eax
8010421d:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104223:	5d                   	pop    %ebp
80104224:	c3                   	ret    

80104225 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104225:	55                   	push   %ebp
80104226:	89 e5                	mov    %esp,%ebp
80104228:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010422b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104232:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104239:	eb 13                	jmp    8010424e <sum+0x29>
    sum += addr[i];
8010423b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010423e:	03 45 08             	add    0x8(%ebp),%eax
80104241:	0f b6 00             	movzbl (%eax),%eax
80104244:	0f b6 c0             	movzbl %al,%eax
80104247:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010424a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010424e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104251:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104254:	7c e5                	jl     8010423b <sum+0x16>
    sum += addr[i];
  return sum;
80104256:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104259:	c9                   	leave  
8010425a:	c3                   	ret    

8010425b <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010425b:	55                   	push   %ebp
8010425c:	89 e5                	mov    %esp,%ebp
8010425e:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104261:	8b 45 08             	mov    0x8(%ebp),%eax
80104264:	89 04 24             	mov    %eax,(%esp)
80104267:	e8 44 ff ff ff       	call   801041b0 <p2v>
8010426c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010426f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104272:	03 45 f0             	add    -0x10(%ebp),%eax
80104275:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104278:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010427b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010427e:	eb 3f                	jmp    801042bf <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104280:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104287:	00 
80104288:	c7 44 24 04 dc 91 10 	movl   $0x801091dc,0x4(%esp)
8010428f:	80 
80104290:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104293:	89 04 24             	mov    %eax,(%esp)
80104296:	e8 72 17 00 00       	call   80105a0d <memcmp>
8010429b:	85 c0                	test   %eax,%eax
8010429d:	75 1c                	jne    801042bb <mpsearch1+0x60>
8010429f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801042a6:	00 
801042a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042aa:	89 04 24             	mov    %eax,(%esp)
801042ad:	e8 73 ff ff ff       	call   80104225 <sum>
801042b2:	84 c0                	test   %al,%al
801042b4:	75 05                	jne    801042bb <mpsearch1+0x60>
      return (struct mp*)p;
801042b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b9:	eb 11                	jmp    801042cc <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801042bb:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801042bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801042c5:	72 b9                	jb     80104280 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801042c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042cc:	c9                   	leave  
801042cd:	c3                   	ret    

801042ce <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801042ce:	55                   	push   %ebp
801042cf:	89 e5                	mov    %esp,%ebp
801042d1:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801042d4:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801042db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042de:	83 c0 0f             	add    $0xf,%eax
801042e1:	0f b6 00             	movzbl (%eax),%eax
801042e4:	0f b6 c0             	movzbl %al,%eax
801042e7:	89 c2                	mov    %eax,%edx
801042e9:	c1 e2 08             	shl    $0x8,%edx
801042ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042ef:	83 c0 0e             	add    $0xe,%eax
801042f2:	0f b6 00             	movzbl (%eax),%eax
801042f5:	0f b6 c0             	movzbl %al,%eax
801042f8:	09 d0                	or     %edx,%eax
801042fa:	c1 e0 04             	shl    $0x4,%eax
801042fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104300:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104304:	74 21                	je     80104327 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104306:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010430d:	00 
8010430e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104311:	89 04 24             	mov    %eax,(%esp)
80104314:	e8 42 ff ff ff       	call   8010425b <mpsearch1>
80104319:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010431c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104320:	74 50                	je     80104372 <mpsearch+0xa4>
      return mp;
80104322:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104325:	eb 5f                	jmp    80104386 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104327:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010432a:	83 c0 14             	add    $0x14,%eax
8010432d:	0f b6 00             	movzbl (%eax),%eax
80104330:	0f b6 c0             	movzbl %al,%eax
80104333:	89 c2                	mov    %eax,%edx
80104335:	c1 e2 08             	shl    $0x8,%edx
80104338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433b:	83 c0 13             	add    $0x13,%eax
8010433e:	0f b6 00             	movzbl (%eax),%eax
80104341:	0f b6 c0             	movzbl %al,%eax
80104344:	09 d0                	or     %edx,%eax
80104346:	c1 e0 0a             	shl    $0xa,%eax
80104349:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
8010434c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010434f:	2d 00 04 00 00       	sub    $0x400,%eax
80104354:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010435b:	00 
8010435c:	89 04 24             	mov    %eax,(%esp)
8010435f:	e8 f7 fe ff ff       	call   8010425b <mpsearch1>
80104364:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104367:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010436b:	74 05                	je     80104372 <mpsearch+0xa4>
      return mp;
8010436d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104370:	eb 14                	jmp    80104386 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104372:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104379:	00 
8010437a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104381:	e8 d5 fe ff ff       	call   8010425b <mpsearch1>
}
80104386:	c9                   	leave  
80104387:	c3                   	ret    

80104388 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104388:	55                   	push   %ebp
80104389:	89 e5                	mov    %esp,%ebp
8010438b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010438e:	e8 3b ff ff ff       	call   801042ce <mpsearch>
80104393:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104396:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010439a:	74 0a                	je     801043a6 <mpconfig+0x1e>
8010439c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010439f:	8b 40 04             	mov    0x4(%eax),%eax
801043a2:	85 c0                	test   %eax,%eax
801043a4:	75 0a                	jne    801043b0 <mpconfig+0x28>
    return 0;
801043a6:	b8 00 00 00 00       	mov    $0x0,%eax
801043ab:	e9 83 00 00 00       	jmp    80104433 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801043b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043b3:	8b 40 04             	mov    0x4(%eax),%eax
801043b6:	89 04 24             	mov    %eax,(%esp)
801043b9:	e8 f2 fd ff ff       	call   801041b0 <p2v>
801043be:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801043c1:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801043c8:	00 
801043c9:	c7 44 24 04 e1 91 10 	movl   $0x801091e1,0x4(%esp)
801043d0:	80 
801043d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043d4:	89 04 24             	mov    %eax,(%esp)
801043d7:	e8 31 16 00 00       	call   80105a0d <memcmp>
801043dc:	85 c0                	test   %eax,%eax
801043de:	74 07                	je     801043e7 <mpconfig+0x5f>
    return 0;
801043e0:	b8 00 00 00 00       	mov    $0x0,%eax
801043e5:	eb 4c                	jmp    80104433 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801043e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043ea:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801043ee:	3c 01                	cmp    $0x1,%al
801043f0:	74 12                	je     80104404 <mpconfig+0x7c>
801043f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043f5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801043f9:	3c 04                	cmp    $0x4,%al
801043fb:	74 07                	je     80104404 <mpconfig+0x7c>
    return 0;
801043fd:	b8 00 00 00 00       	mov    $0x0,%eax
80104402:	eb 2f                	jmp    80104433 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104404:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104407:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010440b:	0f b7 c0             	movzwl %ax,%eax
8010440e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104412:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104415:	89 04 24             	mov    %eax,(%esp)
80104418:	e8 08 fe ff ff       	call   80104225 <sum>
8010441d:	84 c0                	test   %al,%al
8010441f:	74 07                	je     80104428 <mpconfig+0xa0>
    return 0;
80104421:	b8 00 00 00 00       	mov    $0x0,%eax
80104426:	eb 0b                	jmp    80104433 <mpconfig+0xab>
  *pmp = mp;
80104428:	8b 45 08             	mov    0x8(%ebp),%eax
8010442b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010442e:	89 10                	mov    %edx,(%eax)
  return conf;
80104430:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104433:	c9                   	leave  
80104434:	c3                   	ret    

80104435 <mpinit>:

void
mpinit(void)
{
80104435:	55                   	push   %ebp
80104436:	89 e5                	mov    %esp,%ebp
80104438:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010443b:	c7 05 64 c6 10 80 40 	movl   $0x80110940,0x8010c664
80104442:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104445:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104448:	89 04 24             	mov    %eax,(%esp)
8010444b:	e8 38 ff ff ff       	call   80104388 <mpconfig>
80104450:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104453:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104457:	0f 84 9c 01 00 00    	je     801045f9 <mpinit+0x1c4>
    return;
  ismp = 1;
8010445d:	c7 05 24 09 11 80 01 	movl   $0x1,0x80110924
80104464:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104467:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010446a:	8b 40 24             	mov    0x24(%eax),%eax
8010446d:	a3 9c 08 11 80       	mov    %eax,0x8011089c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104472:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104475:	83 c0 2c             	add    $0x2c,%eax
80104478:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010447b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010447e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104482:	0f b7 c0             	movzwl %ax,%eax
80104485:	03 45 f0             	add    -0x10(%ebp),%eax
80104488:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010448b:	e9 f4 00 00 00       	jmp    80104584 <mpinit+0x14f>
    switch(*p){
80104490:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104493:	0f b6 00             	movzbl (%eax),%eax
80104496:	0f b6 c0             	movzbl %al,%eax
80104499:	83 f8 04             	cmp    $0x4,%eax
8010449c:	0f 87 bf 00 00 00    	ja     80104561 <mpinit+0x12c>
801044a2:	8b 04 85 24 92 10 80 	mov    -0x7fef6ddc(,%eax,4),%eax
801044a9:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801044ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044ae:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801044b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801044b4:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801044b8:	0f b6 d0             	movzbl %al,%edx
801044bb:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801044c0:	39 c2                	cmp    %eax,%edx
801044c2:	74 2d                	je     801044f1 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801044c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
801044c7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801044cb:	0f b6 d0             	movzbl %al,%edx
801044ce:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801044d3:	89 54 24 08          	mov    %edx,0x8(%esp)
801044d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801044db:	c7 04 24 e6 91 10 80 	movl   $0x801091e6,(%esp)
801044e2:	e8 ba be ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801044e7:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801044ee:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801044f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801044f4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801044f8:	0f b6 c0             	movzbl %al,%eax
801044fb:	83 e0 02             	and    $0x2,%eax
801044fe:	85 c0                	test   %eax,%eax
80104500:	74 15                	je     80104517 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104502:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104507:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010450d:	05 40 09 11 80       	add    $0x80110940,%eax
80104512:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104517:	8b 15 20 0f 11 80    	mov    0x80110f20,%edx
8010451d:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104522:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104528:	81 c2 40 09 11 80    	add    $0x80110940,%edx
8010452e:	88 02                	mov    %al,(%edx)
      ncpu++;
80104530:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104535:	83 c0 01             	add    $0x1,%eax
80104538:	a3 20 0f 11 80       	mov    %eax,0x80110f20
      p += sizeof(struct mpproc);
8010453d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104541:	eb 41                	jmp    80104584 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104543:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104546:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104549:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010454c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104550:	a2 20 09 11 80       	mov    %al,0x80110920
      p += sizeof(struct mpioapic);
80104555:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104559:	eb 29                	jmp    80104584 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010455b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010455f:	eb 23                	jmp    80104584 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104561:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104564:	0f b6 00             	movzbl (%eax),%eax
80104567:	0f b6 c0             	movzbl %al,%eax
8010456a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010456e:	c7 04 24 04 92 10 80 	movl   $0x80109204,(%esp)
80104575:	e8 27 be ff ff       	call   801003a1 <cprintf>
      ismp = 0;
8010457a:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
80104581:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104587:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010458a:	0f 82 00 ff ff ff    	jb     80104490 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104590:	a1 24 09 11 80       	mov    0x80110924,%eax
80104595:	85 c0                	test   %eax,%eax
80104597:	75 1d                	jne    801045b6 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104599:	c7 05 20 0f 11 80 01 	movl   $0x1,0x80110f20
801045a0:	00 00 00 
    lapic = 0;
801045a3:	c7 05 9c 08 11 80 00 	movl   $0x0,0x8011089c
801045aa:	00 00 00 
    ioapicid = 0;
801045ad:	c6 05 20 09 11 80 00 	movb   $0x0,0x80110920
    return;
801045b4:	eb 44                	jmp    801045fa <mpinit+0x1c5>
  }

  if(mp->imcrp){
801045b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045b9:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801045bd:	84 c0                	test   %al,%al
801045bf:	74 39                	je     801045fa <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801045c1:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801045c8:	00 
801045c9:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801045d0:	e8 12 fc ff ff       	call   801041e7 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801045d5:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801045dc:	e8 dc fb ff ff       	call   801041bd <inb>
801045e1:	83 c8 01             	or     $0x1,%eax
801045e4:	0f b6 c0             	movzbl %al,%eax
801045e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801045eb:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801045f2:	e8 f0 fb ff ff       	call   801041e7 <outb>
801045f7:	eb 01                	jmp    801045fa <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
801045f9:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
801045fa:	c9                   	leave  
801045fb:	c3                   	ret    

801045fc <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801045fc:	55                   	push   %ebp
801045fd:	89 e5                	mov    %esp,%ebp
801045ff:	83 ec 08             	sub    $0x8,%esp
80104602:	8b 55 08             	mov    0x8(%ebp),%edx
80104605:	8b 45 0c             	mov    0xc(%ebp),%eax
80104608:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010460c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010460f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104613:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104617:	ee                   	out    %al,(%dx)
}
80104618:	c9                   	leave  
80104619:	c3                   	ret    

8010461a <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010461a:	55                   	push   %ebp
8010461b:	89 e5                	mov    %esp,%ebp
8010461d:	83 ec 0c             	sub    $0xc,%esp
80104620:	8b 45 08             	mov    0x8(%ebp),%eax
80104623:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104627:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010462b:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104631:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104635:	0f b6 c0             	movzbl %al,%eax
80104638:	89 44 24 04          	mov    %eax,0x4(%esp)
8010463c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104643:	e8 b4 ff ff ff       	call   801045fc <outb>
  outb(IO_PIC2+1, mask >> 8);
80104648:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010464c:	66 c1 e8 08          	shr    $0x8,%ax
80104650:	0f b6 c0             	movzbl %al,%eax
80104653:	89 44 24 04          	mov    %eax,0x4(%esp)
80104657:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010465e:	e8 99 ff ff ff       	call   801045fc <outb>
}
80104663:	c9                   	leave  
80104664:	c3                   	ret    

80104665 <picenable>:

void
picenable(int irq)
{
80104665:	55                   	push   %ebp
80104666:	89 e5                	mov    %esp,%ebp
80104668:	53                   	push   %ebx
80104669:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
8010466c:	8b 45 08             	mov    0x8(%ebp),%eax
8010466f:	ba 01 00 00 00       	mov    $0x1,%edx
80104674:	89 d3                	mov    %edx,%ebx
80104676:	89 c1                	mov    %eax,%ecx
80104678:	d3 e3                	shl    %cl,%ebx
8010467a:	89 d8                	mov    %ebx,%eax
8010467c:	89 c2                	mov    %eax,%edx
8010467e:	f7 d2                	not    %edx
80104680:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104687:	21 d0                	and    %edx,%eax
80104689:	0f b7 c0             	movzwl %ax,%eax
8010468c:	89 04 24             	mov    %eax,(%esp)
8010468f:	e8 86 ff ff ff       	call   8010461a <picsetmask>
}
80104694:	83 c4 04             	add    $0x4,%esp
80104697:	5b                   	pop    %ebx
80104698:	5d                   	pop    %ebp
80104699:	c3                   	ret    

8010469a <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010469a:	55                   	push   %ebp
8010469b:	89 e5                	mov    %esp,%ebp
8010469d:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801046a0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801046a7:	00 
801046a8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801046af:	e8 48 ff ff ff       	call   801045fc <outb>
  outb(IO_PIC2+1, 0xFF);
801046b4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801046bb:	00 
801046bc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801046c3:	e8 34 ff ff ff       	call   801045fc <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801046c8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801046cf:	00 
801046d0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801046d7:	e8 20 ff ff ff       	call   801045fc <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801046dc:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801046e3:	00 
801046e4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801046eb:	e8 0c ff ff ff       	call   801045fc <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801046f0:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801046f7:	00 
801046f8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801046ff:	e8 f8 fe ff ff       	call   801045fc <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104704:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010470b:	00 
8010470c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104713:	e8 e4 fe ff ff       	call   801045fc <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104718:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010471f:	00 
80104720:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104727:	e8 d0 fe ff ff       	call   801045fc <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010472c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104733:	00 
80104734:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010473b:	e8 bc fe ff ff       	call   801045fc <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104740:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104747:	00 
80104748:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010474f:	e8 a8 fe ff ff       	call   801045fc <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104754:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010475b:	00 
8010475c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104763:	e8 94 fe ff ff       	call   801045fc <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104768:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010476f:	00 
80104770:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104777:	e8 80 fe ff ff       	call   801045fc <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010477c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104783:	00 
80104784:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010478b:	e8 6c fe ff ff       	call   801045fc <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104790:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104797:	00 
80104798:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010479f:	e8 58 fe ff ff       	call   801045fc <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
801047a4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801047ab:	00 
801047ac:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801047b3:	e8 44 fe ff ff       	call   801045fc <outb>

  if(irqmask != 0xFFFF)
801047b8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801047bf:	66 83 f8 ff          	cmp    $0xffff,%ax
801047c3:	74 12                	je     801047d7 <picinit+0x13d>
    picsetmask(irqmask);
801047c5:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801047cc:	0f b7 c0             	movzwl %ax,%eax
801047cf:	89 04 24             	mov    %eax,(%esp)
801047d2:	e8 43 fe ff ff       	call   8010461a <picsetmask>
}
801047d7:	c9                   	leave  
801047d8:	c3                   	ret    
801047d9:	00 00                	add    %al,(%eax)
	...

801047dc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801047dc:	55                   	push   %ebp
801047dd:	89 e5                	mov    %esp,%ebp
801047df:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801047e2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801047e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801047ec:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801047f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801047f5:	8b 10                	mov    (%eax),%edx
801047f7:	8b 45 08             	mov    0x8(%ebp),%eax
801047fa:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801047fc:	e8 1b c7 ff ff       	call   80100f1c <filealloc>
80104801:	8b 55 08             	mov    0x8(%ebp),%edx
80104804:	89 02                	mov    %eax,(%edx)
80104806:	8b 45 08             	mov    0x8(%ebp),%eax
80104809:	8b 00                	mov    (%eax),%eax
8010480b:	85 c0                	test   %eax,%eax
8010480d:	0f 84 c8 00 00 00    	je     801048db <pipealloc+0xff>
80104813:	e8 04 c7 ff ff       	call   80100f1c <filealloc>
80104818:	8b 55 0c             	mov    0xc(%ebp),%edx
8010481b:	89 02                	mov    %eax,(%edx)
8010481d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104820:	8b 00                	mov    (%eax),%eax
80104822:	85 c0                	test   %eax,%eax
80104824:	0f 84 b1 00 00 00    	je     801048db <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
8010482a:	e8 74 ee ff ff       	call   801036a3 <kalloc>
8010482f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104832:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104836:	0f 84 9e 00 00 00    	je     801048da <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
8010483c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104846:	00 00 00 
  p->writeopen = 1;
80104849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010484c:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104853:	00 00 00 
  p->nwrite = 0;
80104856:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104859:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104860:	00 00 00 
  p->nread = 0;
80104863:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104866:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010486d:	00 00 00 
  initlock(&p->lock, "pipe");
80104870:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104873:	c7 44 24 04 38 92 10 	movl   $0x80109238,0x4(%esp)
8010487a:	80 
8010487b:	89 04 24             	mov    %eax,(%esp)
8010487e:	e8 a3 0e 00 00       	call   80105726 <initlock>
  (*f0)->type = FD_PIPE;
80104883:	8b 45 08             	mov    0x8(%ebp),%eax
80104886:	8b 00                	mov    (%eax),%eax
80104888:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010488e:	8b 45 08             	mov    0x8(%ebp),%eax
80104891:	8b 00                	mov    (%eax),%eax
80104893:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104897:	8b 45 08             	mov    0x8(%ebp),%eax
8010489a:	8b 00                	mov    (%eax),%eax
8010489c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801048a0:	8b 45 08             	mov    0x8(%ebp),%eax
801048a3:	8b 00                	mov    (%eax),%eax
801048a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048a8:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
801048ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801048ae:	8b 00                	mov    (%eax),%eax
801048b0:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801048b6:	8b 45 0c             	mov    0xc(%ebp),%eax
801048b9:	8b 00                	mov    (%eax),%eax
801048bb:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801048bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801048c2:	8b 00                	mov    (%eax),%eax
801048c4:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801048c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801048cb:	8b 00                	mov    (%eax),%eax
801048cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048d0:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801048d3:	b8 00 00 00 00       	mov    $0x0,%eax
801048d8:	eb 43                	jmp    8010491d <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
801048da:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
801048db:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801048df:	74 0b                	je     801048ec <pipealloc+0x110>
    kfree((char*)p);
801048e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048e4:	89 04 24             	mov    %eax,(%esp)
801048e7:	e8 1e ed ff ff       	call   8010360a <kfree>
  if(*f0)
801048ec:	8b 45 08             	mov    0x8(%ebp),%eax
801048ef:	8b 00                	mov    (%eax),%eax
801048f1:	85 c0                	test   %eax,%eax
801048f3:	74 0d                	je     80104902 <pipealloc+0x126>
    fileclose(*f0);
801048f5:	8b 45 08             	mov    0x8(%ebp),%eax
801048f8:	8b 00                	mov    (%eax),%eax
801048fa:	89 04 24             	mov    %eax,(%esp)
801048fd:	e8 c2 c6 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104902:	8b 45 0c             	mov    0xc(%ebp),%eax
80104905:	8b 00                	mov    (%eax),%eax
80104907:	85 c0                	test   %eax,%eax
80104909:	74 0d                	je     80104918 <pipealloc+0x13c>
    fileclose(*f1);
8010490b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010490e:	8b 00                	mov    (%eax),%eax
80104910:	89 04 24             	mov    %eax,(%esp)
80104913:	e8 ac c6 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104918:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010491d:	c9                   	leave  
8010491e:	c3                   	ret    

8010491f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010491f:	55                   	push   %ebp
80104920:	89 e5                	mov    %esp,%ebp
80104922:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104925:	8b 45 08             	mov    0x8(%ebp),%eax
80104928:	89 04 24             	mov    %eax,(%esp)
8010492b:	e8 17 0e 00 00       	call   80105747 <acquire>
  if(writable){
80104930:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104934:	74 1f                	je     80104955 <pipeclose+0x36>
    p->writeopen = 0;
80104936:	8b 45 08             	mov    0x8(%ebp),%eax
80104939:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104940:	00 00 00 
    wakeup(&p->nread);
80104943:	8b 45 08             	mov    0x8(%ebp),%eax
80104946:	05 34 02 00 00       	add    $0x234,%eax
8010494b:	89 04 24             	mov    %eax,(%esp)
8010494e:	e8 ef 0b 00 00       	call   80105542 <wakeup>
80104953:	eb 1d                	jmp    80104972 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104955:	8b 45 08             	mov    0x8(%ebp),%eax
80104958:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010495f:	00 00 00 
    wakeup(&p->nwrite);
80104962:	8b 45 08             	mov    0x8(%ebp),%eax
80104965:	05 38 02 00 00       	add    $0x238,%eax
8010496a:	89 04 24             	mov    %eax,(%esp)
8010496d:	e8 d0 0b 00 00       	call   80105542 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104972:	8b 45 08             	mov    0x8(%ebp),%eax
80104975:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010497b:	85 c0                	test   %eax,%eax
8010497d:	75 25                	jne    801049a4 <pipeclose+0x85>
8010497f:	8b 45 08             	mov    0x8(%ebp),%eax
80104982:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104988:	85 c0                	test   %eax,%eax
8010498a:	75 18                	jne    801049a4 <pipeclose+0x85>
    release(&p->lock);
8010498c:	8b 45 08             	mov    0x8(%ebp),%eax
8010498f:	89 04 24             	mov    %eax,(%esp)
80104992:	e8 12 0e 00 00       	call   801057a9 <release>
    kfree((char*)p);
80104997:	8b 45 08             	mov    0x8(%ebp),%eax
8010499a:	89 04 24             	mov    %eax,(%esp)
8010499d:	e8 68 ec ff ff       	call   8010360a <kfree>
801049a2:	eb 0b                	jmp    801049af <pipeclose+0x90>
  } else
    release(&p->lock);
801049a4:	8b 45 08             	mov    0x8(%ebp),%eax
801049a7:	89 04 24             	mov    %eax,(%esp)
801049aa:	e8 fa 0d 00 00       	call   801057a9 <release>
}
801049af:	c9                   	leave  
801049b0:	c3                   	ret    

801049b1 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801049b1:	55                   	push   %ebp
801049b2:	89 e5                	mov    %esp,%ebp
801049b4:	53                   	push   %ebx
801049b5:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801049b8:	8b 45 08             	mov    0x8(%ebp),%eax
801049bb:	89 04 24             	mov    %eax,(%esp)
801049be:	e8 84 0d 00 00       	call   80105747 <acquire>
  for(i = 0; i < n; i++){
801049c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801049ca:	e9 a6 00 00 00       	jmp    80104a75 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801049cf:	8b 45 08             	mov    0x8(%ebp),%eax
801049d2:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801049d8:	85 c0                	test   %eax,%eax
801049da:	74 0d                	je     801049e9 <pipewrite+0x38>
801049dc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049e2:	8b 40 24             	mov    0x24(%eax),%eax
801049e5:	85 c0                	test   %eax,%eax
801049e7:	74 15                	je     801049fe <pipewrite+0x4d>
        release(&p->lock);
801049e9:	8b 45 08             	mov    0x8(%ebp),%eax
801049ec:	89 04 24             	mov    %eax,(%esp)
801049ef:	e8 b5 0d 00 00       	call   801057a9 <release>
        return -1;
801049f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049f9:	e9 9d 00 00 00       	jmp    80104a9b <pipewrite+0xea>
      }
      wakeup(&p->nread);
801049fe:	8b 45 08             	mov    0x8(%ebp),%eax
80104a01:	05 34 02 00 00       	add    $0x234,%eax
80104a06:	89 04 24             	mov    %eax,(%esp)
80104a09:	e8 34 0b 00 00       	call   80105542 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104a0e:	8b 45 08             	mov    0x8(%ebp),%eax
80104a11:	8b 55 08             	mov    0x8(%ebp),%edx
80104a14:	81 c2 38 02 00 00    	add    $0x238,%edx
80104a1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a1e:	89 14 24             	mov    %edx,(%esp)
80104a21:	e8 43 0a 00 00       	call   80105469 <sleep>
80104a26:	eb 01                	jmp    80104a29 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104a28:	90                   	nop
80104a29:	8b 45 08             	mov    0x8(%ebp),%eax
80104a2c:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104a32:	8b 45 08             	mov    0x8(%ebp),%eax
80104a35:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104a3b:	05 00 02 00 00       	add    $0x200,%eax
80104a40:	39 c2                	cmp    %eax,%edx
80104a42:	74 8b                	je     801049cf <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104a44:	8b 45 08             	mov    0x8(%ebp),%eax
80104a47:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104a4d:	89 c3                	mov    %eax,%ebx
80104a4f:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104a55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a58:	03 55 0c             	add    0xc(%ebp),%edx
80104a5b:	0f b6 0a             	movzbl (%edx),%ecx
80104a5e:	8b 55 08             	mov    0x8(%ebp),%edx
80104a61:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104a65:	8d 50 01             	lea    0x1(%eax),%edx
80104a68:	8b 45 08             	mov    0x8(%ebp),%eax
80104a6b:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104a71:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a78:	3b 45 10             	cmp    0x10(%ebp),%eax
80104a7b:	7c ab                	jl     80104a28 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a80:	05 34 02 00 00       	add    $0x234,%eax
80104a85:	89 04 24             	mov    %eax,(%esp)
80104a88:	e8 b5 0a 00 00       	call   80105542 <wakeup>
  release(&p->lock);
80104a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80104a90:	89 04 24             	mov    %eax,(%esp)
80104a93:	e8 11 0d 00 00       	call   801057a9 <release>
  return n;
80104a98:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104a9b:	83 c4 24             	add    $0x24,%esp
80104a9e:	5b                   	pop    %ebx
80104a9f:	5d                   	pop    %ebp
80104aa0:	c3                   	ret    

80104aa1 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104aa1:	55                   	push   %ebp
80104aa2:	89 e5                	mov    %esp,%ebp
80104aa4:	53                   	push   %ebx
80104aa5:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104aa8:	8b 45 08             	mov    0x8(%ebp),%eax
80104aab:	89 04 24             	mov    %eax,(%esp)
80104aae:	e8 94 0c 00 00       	call   80105747 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104ab3:	eb 3a                	jmp    80104aef <piperead+0x4e>
    if(proc->killed){
80104ab5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104abb:	8b 40 24             	mov    0x24(%eax),%eax
80104abe:	85 c0                	test   %eax,%eax
80104ac0:	74 15                	je     80104ad7 <piperead+0x36>
      release(&p->lock);
80104ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80104ac5:	89 04 24             	mov    %eax,(%esp)
80104ac8:	e8 dc 0c 00 00       	call   801057a9 <release>
      return -1;
80104acd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ad2:	e9 b6 00 00 00       	jmp    80104b8d <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104ad7:	8b 45 08             	mov    0x8(%ebp),%eax
80104ada:	8b 55 08             	mov    0x8(%ebp),%edx
80104add:	81 c2 34 02 00 00    	add    $0x234,%edx
80104ae3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ae7:	89 14 24             	mov    %edx,(%esp)
80104aea:	e8 7a 09 00 00       	call   80105469 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104aef:	8b 45 08             	mov    0x8(%ebp),%eax
80104af2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104af8:	8b 45 08             	mov    0x8(%ebp),%eax
80104afb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104b01:	39 c2                	cmp    %eax,%edx
80104b03:	75 0d                	jne    80104b12 <piperead+0x71>
80104b05:	8b 45 08             	mov    0x8(%ebp),%eax
80104b08:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104b0e:	85 c0                	test   %eax,%eax
80104b10:	75 a3                	jne    80104ab5 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104b12:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104b19:	eb 49                	jmp    80104b64 <piperead+0xc3>
    if(p->nread == p->nwrite)
80104b1b:	8b 45 08             	mov    0x8(%ebp),%eax
80104b1e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104b24:	8b 45 08             	mov    0x8(%ebp),%eax
80104b27:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104b2d:	39 c2                	cmp    %eax,%edx
80104b2f:	74 3d                	je     80104b6e <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104b31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b34:	89 c2                	mov    %eax,%edx
80104b36:	03 55 0c             	add    0xc(%ebp),%edx
80104b39:	8b 45 08             	mov    0x8(%ebp),%eax
80104b3c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104b42:	89 c3                	mov    %eax,%ebx
80104b44:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104b4a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104b4d:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104b52:	88 0a                	mov    %cl,(%edx)
80104b54:	8d 50 01             	lea    0x1(%eax),%edx
80104b57:	8b 45 08             	mov    0x8(%ebp),%eax
80104b5a:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104b60:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104b64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b67:	3b 45 10             	cmp    0x10(%ebp),%eax
80104b6a:	7c af                	jl     80104b1b <piperead+0x7a>
80104b6c:	eb 01                	jmp    80104b6f <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104b6e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104b6f:	8b 45 08             	mov    0x8(%ebp),%eax
80104b72:	05 38 02 00 00       	add    $0x238,%eax
80104b77:	89 04 24             	mov    %eax,(%esp)
80104b7a:	e8 c3 09 00 00       	call   80105542 <wakeup>
  release(&p->lock);
80104b7f:	8b 45 08             	mov    0x8(%ebp),%eax
80104b82:	89 04 24             	mov    %eax,(%esp)
80104b85:	e8 1f 0c 00 00       	call   801057a9 <release>
  return i;
80104b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104b8d:	83 c4 24             	add    $0x24,%esp
80104b90:	5b                   	pop    %ebx
80104b91:	5d                   	pop    %ebp
80104b92:	c3                   	ret    
	...

80104b94 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104b94:	55                   	push   %ebp
80104b95:	89 e5                	mov    %esp,%ebp
80104b97:	53                   	push   %ebx
80104b98:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104b9b:	9c                   	pushf  
80104b9c:	5b                   	pop    %ebx
80104b9d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104ba0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104ba3:	83 c4 10             	add    $0x10,%esp
80104ba6:	5b                   	pop    %ebx
80104ba7:	5d                   	pop    %ebp
80104ba8:	c3                   	ret    

80104ba9 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104ba9:	55                   	push   %ebp
80104baa:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104bac:	fb                   	sti    
}
80104bad:	5d                   	pop    %ebp
80104bae:	c3                   	ret    

80104baf <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104baf:	55                   	push   %ebp
80104bb0:	89 e5                	mov    %esp,%ebp
80104bb2:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104bb5:	c7 44 24 04 3d 92 10 	movl   $0x8010923d,0x4(%esp)
80104bbc:	80 
80104bbd:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104bc4:	e8 5d 0b 00 00       	call   80105726 <initlock>
}
80104bc9:	c9                   	leave  
80104bca:	c3                   	ret    

80104bcb <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104bcb:	55                   	push   %ebp
80104bcc:	89 e5                	mov    %esp,%ebp
80104bce:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104bd1:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104bd8:	e8 6a 0b 00 00       	call   80105747 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bdd:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80104be4:	eb 0e                	jmp    80104bf4 <allocproc+0x29>
    if(p->state == UNUSED)
80104be6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be9:	8b 40 0c             	mov    0xc(%eax),%eax
80104bec:	85 c0                	test   %eax,%eax
80104bee:	74 23                	je     80104c13 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bf0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104bf4:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80104bfb:	72 e9                	jb     80104be6 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104bfd:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104c04:	e8 a0 0b 00 00       	call   801057a9 <release>
  return 0;
80104c09:	b8 00 00 00 00       	mov    $0x0,%eax
80104c0e:	e9 b5 00 00 00       	jmp    80104cc8 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104c13:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104c14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c17:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104c1e:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104c23:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c26:	89 42 10             	mov    %eax,0x10(%edx)
80104c29:	83 c0 01             	add    $0x1,%eax
80104c2c:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80104c31:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104c38:	e8 6c 0b 00 00       	call   801057a9 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104c3d:	e8 61 ea ff ff       	call   801036a3 <kalloc>
80104c42:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c45:	89 42 08             	mov    %eax,0x8(%edx)
80104c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4b:	8b 40 08             	mov    0x8(%eax),%eax
80104c4e:	85 c0                	test   %eax,%eax
80104c50:	75 11                	jne    80104c63 <allocproc+0x98>
    p->state = UNUSED;
80104c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c55:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104c5c:	b8 00 00 00 00       	mov    $0x0,%eax
80104c61:	eb 65                	jmp    80104cc8 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104c63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c66:	8b 40 08             	mov    0x8(%eax),%eax
80104c69:	05 00 10 00 00       	add    $0x1000,%eax
80104c6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104c71:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104c75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c78:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c7b:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104c7e:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104c82:	ba 7c 6f 10 80       	mov    $0x80106f7c,%edx
80104c87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c8a:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104c8c:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c93:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104c96:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c9c:	8b 40 1c             	mov    0x1c(%eax),%eax
80104c9f:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104ca6:	00 
80104ca7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cae:	00 
80104caf:	89 04 24             	mov    %eax,(%esp)
80104cb2:	e8 df 0c 00 00       	call   80105996 <memset>
  p->context->eip = (uint)forkret;
80104cb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cba:	8b 40 1c             	mov    0x1c(%eax),%eax
80104cbd:	ba 3d 54 10 80       	mov    $0x8010543d,%edx
80104cc2:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104cc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104cc8:	c9                   	leave  
80104cc9:	c3                   	ret    

80104cca <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104cca:	55                   	push   %ebp
80104ccb:	89 e5                	mov    %esp,%ebp
80104ccd:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104cd0:	e8 f6 fe ff ff       	call   80104bcb <allocproc>
80104cd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cdb:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104ce0:	c7 04 24 a3 36 10 80 	movl   $0x801036a3,(%esp)
80104ce7:	e8 8d 39 00 00       	call   80108679 <setupkvm>
80104cec:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cef:	89 42 04             	mov    %eax,0x4(%edx)
80104cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104cf5:	8b 40 04             	mov    0x4(%eax),%eax
80104cf8:	85 c0                	test   %eax,%eax
80104cfa:	75 0c                	jne    80104d08 <userinit+0x3e>
    panic("userinit: out of memory?");
80104cfc:	c7 04 24 44 92 10 80 	movl   $0x80109244,(%esp)
80104d03:	e8 35 b8 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104d08:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d10:	8b 40 04             	mov    0x4(%eax),%eax
80104d13:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d17:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80104d1e:	80 
80104d1f:	89 04 24             	mov    %eax,(%esp)
80104d22:	e8 aa 3b 00 00       	call   801088d1 <inituvm>
  p->sz = PGSIZE;
80104d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d2a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d33:	8b 40 18             	mov    0x18(%eax),%eax
80104d36:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104d3d:	00 
80104d3e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d45:	00 
80104d46:	89 04 24             	mov    %eax,(%esp)
80104d49:	e8 48 0c 00 00       	call   80105996 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104d4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d51:	8b 40 18             	mov    0x18(%eax),%eax
80104d54:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d5d:	8b 40 18             	mov    0x18(%eax),%eax
80104d60:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104d66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d69:	8b 40 18             	mov    0x18(%eax),%eax
80104d6c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d6f:	8b 52 18             	mov    0x18(%edx),%edx
80104d72:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d76:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104d7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d7d:	8b 40 18             	mov    0x18(%eax),%eax
80104d80:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d83:	8b 52 18             	mov    0x18(%edx),%edx
80104d86:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104d8a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d91:	8b 40 18             	mov    0x18(%eax),%eax
80104d94:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d9e:	8b 40 18             	mov    0x18(%eax),%eax
80104da1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dab:	8b 40 18             	mov    0x18(%eax),%eax
80104dae:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db8:	83 c0 6c             	add    $0x6c,%eax
80104dbb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104dc2:	00 
80104dc3:	c7 44 24 04 5d 92 10 	movl   $0x8010925d,0x4(%esp)
80104dca:	80 
80104dcb:	89 04 24             	mov    %eax,(%esp)
80104dce:	e8 f3 0d 00 00       	call   80105bc6 <safestrcpy>
  p->cwd = namei("/");
80104dd3:	c7 04 24 66 92 10 80 	movl   $0x80109266,(%esp)
80104dda:	e8 ab e0 ff ff       	call   80102e8a <namei>
80104ddf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104de2:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80104de5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104de8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104def:	c9                   	leave  
80104df0:	c3                   	ret    

80104df1 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104df1:	55                   	push   %ebp
80104df2:	89 e5                	mov    %esp,%ebp
80104df4:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104df7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dfd:	8b 00                	mov    (%eax),%eax
80104dff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104e02:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e06:	7e 34                	jle    80104e3c <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104e08:	8b 45 08             	mov    0x8(%ebp),%eax
80104e0b:	89 c2                	mov    %eax,%edx
80104e0d:	03 55 f4             	add    -0xc(%ebp),%edx
80104e10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e16:	8b 40 04             	mov    0x4(%eax),%eax
80104e19:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e20:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e24:	89 04 24             	mov    %eax,(%esp)
80104e27:	e8 1f 3c 00 00       	call   80108a4b <allocuvm>
80104e2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e2f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e33:	75 41                	jne    80104e76 <growproc+0x85>
      return -1;
80104e35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e3a:	eb 58                	jmp    80104e94 <growproc+0xa3>
  } else if(n < 0){
80104e3c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104e40:	79 34                	jns    80104e76 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104e42:	8b 45 08             	mov    0x8(%ebp),%eax
80104e45:	89 c2                	mov    %eax,%edx
80104e47:	03 55 f4             	add    -0xc(%ebp),%edx
80104e4a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e50:	8b 40 04             	mov    0x4(%eax),%eax
80104e53:	89 54 24 08          	mov    %edx,0x8(%esp)
80104e57:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e5e:	89 04 24             	mov    %eax,(%esp)
80104e61:	e8 bf 3c 00 00       	call   80108b25 <deallocuvm>
80104e66:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e69:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e6d:	75 07                	jne    80104e76 <growproc+0x85>
      return -1;
80104e6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e74:	eb 1e                	jmp    80104e94 <growproc+0xa3>
  }
  proc->sz = sz;
80104e76:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e7c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e7f:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104e81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e87:	89 04 24             	mov    %eax,(%esp)
80104e8a:	e8 db 38 00 00       	call   8010876a <switchuvm>
  return 0;
80104e8f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e94:	c9                   	leave  
80104e95:	c3                   	ret    

80104e96 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
80104e96:	55                   	push   %ebp
80104e97:	89 e5                	mov    %esp,%ebp
80104e99:	57                   	push   %edi
80104e9a:	56                   	push   %esi
80104e9b:	53                   	push   %ebx
80104e9c:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104e9f:	e8 27 fd ff ff       	call   80104bcb <allocproc>
80104ea4:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104ea7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104eab:	75 0a                	jne    80104eb7 <fork+0x21>
    return -1;
80104ead:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb2:	e9 3a 01 00 00       	jmp    80104ff1 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104eb7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ebd:	8b 10                	mov    (%eax),%edx
80104ebf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ec5:	8b 40 04             	mov    0x4(%eax),%eax
80104ec8:	89 54 24 04          	mov    %edx,0x4(%esp)
80104ecc:	89 04 24             	mov    %eax,(%esp)
80104ecf:	e8 e1 3d 00 00       	call   80108cb5 <copyuvm>
80104ed4:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104ed7:	89 42 04             	mov    %eax,0x4(%edx)
80104eda:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104edd:	8b 40 04             	mov    0x4(%eax),%eax
80104ee0:	85 c0                	test   %eax,%eax
80104ee2:	75 2c                	jne    80104f10 <fork+0x7a>
    kfree(np->kstack);
80104ee4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ee7:	8b 40 08             	mov    0x8(%eax),%eax
80104eea:	89 04 24             	mov    %eax,(%esp)
80104eed:	e8 18 e7 ff ff       	call   8010360a <kfree>
    np->kstack = 0;
80104ef2:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104ef5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104efc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104eff:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104f06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f0b:	e9 e1 00 00 00       	jmp    80104ff1 <fork+0x15b>
  }
  np->sz = proc->sz;
80104f10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f16:	8b 10                	mov    (%eax),%edx
80104f18:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f1b:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104f1d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104f24:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f27:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104f2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f2d:	8b 50 18             	mov    0x18(%eax),%edx
80104f30:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f36:	8b 40 18             	mov    0x18(%eax),%eax
80104f39:	89 c3                	mov    %eax,%ebx
80104f3b:	b8 13 00 00 00       	mov    $0x13,%eax
80104f40:	89 d7                	mov    %edx,%edi
80104f42:	89 de                	mov    %ebx,%esi
80104f44:	89 c1                	mov    %eax,%ecx
80104f46:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104f48:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104f4b:	8b 40 18             	mov    0x18(%eax),%eax
80104f4e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104f55:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104f5c:	eb 3d                	jmp    80104f9b <fork+0x105>
    if(proc->ofile[i])
80104f5e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f64:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f67:	83 c2 08             	add    $0x8,%edx
80104f6a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f6e:	85 c0                	test   %eax,%eax
80104f70:	74 25                	je     80104f97 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104f72:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f78:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104f7b:	83 c2 08             	add    $0x8,%edx
80104f7e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104f82:	89 04 24             	mov    %eax,(%esp)
80104f85:	e8 f2 bf ff ff       	call   80100f7c <filedup>
80104f8a:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104f8d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104f90:	83 c1 08             	add    $0x8,%ecx
80104f93:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104f97:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104f9b:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104f9f:	7e bd                	jle    80104f5e <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104fa1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fa7:	8b 40 68             	mov    0x68(%eax),%eax
80104faa:	89 04 24             	mov    %eax,(%esp)
80104fad:	e8 04 d3 ff ff       	call   801022b6 <idup>
80104fb2:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104fb5:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104fb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fbb:	8b 40 10             	mov    0x10(%eax),%eax
80104fbe:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104fc1:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fc4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104fcb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104fd1:	8d 50 6c             	lea    0x6c(%eax),%edx
80104fd4:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104fd7:	83 c0 6c             	add    $0x6c,%eax
80104fda:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104fe1:	00 
80104fe2:	89 54 24 04          	mov    %edx,0x4(%esp)
80104fe6:	89 04 24             	mov    %eax,(%esp)
80104fe9:	e8 d8 0b 00 00       	call   80105bc6 <safestrcpy>
  return pid;
80104fee:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104ff1:	83 c4 2c             	add    $0x2c,%esp
80104ff4:	5b                   	pop    %ebx
80104ff5:	5e                   	pop    %esi
80104ff6:	5f                   	pop    %edi
80104ff7:	5d                   	pop    %ebp
80104ff8:	c3                   	ret    

80104ff9 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104ff9:	55                   	push   %ebp
80104ffa:	89 e5                	mov    %esp,%ebp
80104ffc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104fff:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105006:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010500b:	39 c2                	cmp    %eax,%edx
8010500d:	75 0c                	jne    8010501b <exit+0x22>
    panic("init exiting");
8010500f:	c7 04 24 68 92 10 80 	movl   $0x80109268,(%esp)
80105016:	e8 22 b5 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010501b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105022:	eb 44                	jmp    80105068 <exit+0x6f>
    if(proc->ofile[fd]){
80105024:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010502a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010502d:	83 c2 08             	add    $0x8,%edx
80105030:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105034:	85 c0                	test   %eax,%eax
80105036:	74 2c                	je     80105064 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105038:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010503e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105041:	83 c2 08             	add    $0x8,%edx
80105044:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105048:	89 04 24             	mov    %eax,(%esp)
8010504b:	e8 74 bf ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105050:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105056:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105059:	83 c2 08             	add    $0x8,%edx
8010505c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105063:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105064:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105068:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010506c:	7e b6                	jle    80105024 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010506e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105074:	8b 40 68             	mov    0x68(%eax),%eax
80105077:	89 04 24             	mov    %eax,(%esp)
8010507a:	e8 1c d4 ff ff       	call   8010249b <iput>
  proc->cwd = 0;
8010507f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105085:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
8010508c:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105093:	e8 af 06 00 00       	call   80105747 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80105098:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010509e:	8b 40 14             	mov    0x14(%eax),%eax
801050a1:	89 04 24             	mov    %eax,(%esp)
801050a4:	e8 5b 04 00 00       	call   80105504 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050a9:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801050b0:	eb 38                	jmp    801050ea <exit+0xf1>
    if(p->parent == proc){
801050b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050b5:	8b 50 14             	mov    0x14(%eax),%edx
801050b8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050be:	39 c2                	cmp    %eax,%edx
801050c0:	75 24                	jne    801050e6 <exit+0xed>
      p->parent = initproc;
801050c2:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801050c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050cb:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801050ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050d1:	8b 40 0c             	mov    0xc(%eax),%eax
801050d4:	83 f8 05             	cmp    $0x5,%eax
801050d7:	75 0d                	jne    801050e6 <exit+0xed>
        wakeup1(initproc);
801050d9:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801050de:	89 04 24             	mov    %eax,(%esp)
801050e1:	e8 1e 04 00 00       	call   80105504 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050e6:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801050ea:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801050f1:	72 bf                	jb     801050b2 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801050f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050f9:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105100:	e8 54 02 00 00       	call   80105359 <sched>
  panic("zombie exit");
80105105:	c7 04 24 75 92 10 80 	movl   $0x80109275,(%esp)
8010510c:	e8 2c b4 ff ff       	call   8010053d <panic>

80105111 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105111:	55                   	push   %ebp
80105112:	89 e5                	mov    %esp,%ebp
80105114:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105117:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010511e:	e8 24 06 00 00       	call   80105747 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105123:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010512a:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80105131:	e9 9a 00 00 00       	jmp    801051d0 <wait+0xbf>
      if(p->parent != proc)
80105136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105139:	8b 50 14             	mov    0x14(%eax),%edx
8010513c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105142:	39 c2                	cmp    %eax,%edx
80105144:	0f 85 81 00 00 00    	jne    801051cb <wait+0xba>
        continue;
      havekids = 1;
8010514a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105151:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105154:	8b 40 0c             	mov    0xc(%eax),%eax
80105157:	83 f8 05             	cmp    $0x5,%eax
8010515a:	75 70                	jne    801051cc <wait+0xbb>
        // Found one.
        pid = p->pid;
8010515c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010515f:	8b 40 10             	mov    0x10(%eax),%eax
80105162:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105165:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105168:	8b 40 08             	mov    0x8(%eax),%eax
8010516b:	89 04 24             	mov    %eax,(%esp)
8010516e:	e8 97 e4 ff ff       	call   8010360a <kfree>
        p->kstack = 0;
80105173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105176:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
8010517d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105180:	8b 40 04             	mov    0x4(%eax),%eax
80105183:	89 04 24             	mov    %eax,(%esp)
80105186:	e8 56 3a 00 00       	call   80108be1 <freevm>
        p->state = UNUSED;
8010518b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010518e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105198:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
8010519f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051a2:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801051a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051ac:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801051b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051b3:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801051ba:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801051c1:	e8 e3 05 00 00       	call   801057a9 <release>
        return pid;
801051c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801051c9:	eb 53                	jmp    8010521e <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801051cb:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801051cc:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801051d0:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801051d7:	0f 82 59 ff ff ff    	jb     80105136 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801051dd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801051e1:	74 0d                	je     801051f0 <wait+0xdf>
801051e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051e9:	8b 40 24             	mov    0x24(%eax),%eax
801051ec:	85 c0                	test   %eax,%eax
801051ee:	74 13                	je     80105203 <wait+0xf2>
      release(&ptable.lock);
801051f0:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801051f7:	e8 ad 05 00 00       	call   801057a9 <release>
      return -1;
801051fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105201:	eb 1b                	jmp    8010521e <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105203:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105209:	c7 44 24 04 40 0f 11 	movl   $0x80110f40,0x4(%esp)
80105210:	80 
80105211:	89 04 24             	mov    %eax,(%esp)
80105214:	e8 50 02 00 00       	call   80105469 <sleep>
  }
80105219:	e9 05 ff ff ff       	jmp    80105123 <wait+0x12>
}
8010521e:	c9                   	leave  
8010521f:	c3                   	ret    

80105220 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105220:	55                   	push   %ebp
80105221:	89 e5                	mov    %esp,%ebp
80105223:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80105226:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010522c:	8b 40 18             	mov    0x18(%eax),%eax
8010522f:	8b 40 44             	mov    0x44(%eax),%eax
80105232:	89 c2                	mov    %eax,%edx
80105234:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010523a:	8b 40 04             	mov    0x4(%eax),%eax
8010523d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105241:	89 04 24             	mov    %eax,(%esp)
80105244:	e8 7d 3b 00 00       	call   80108dc6 <uva2ka>
80105249:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
8010524c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105252:	8b 40 18             	mov    0x18(%eax),%eax
80105255:	8b 40 44             	mov    0x44(%eax),%eax
80105258:	25 ff 0f 00 00       	and    $0xfff,%eax
8010525d:	85 c0                	test   %eax,%eax
8010525f:	75 0c                	jne    8010526d <register_handler+0x4d>
    panic("esp_offset == 0");
80105261:	c7 04 24 81 92 10 80 	movl   $0x80109281,(%esp)
80105268:	e8 d0 b2 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
8010526d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105273:	8b 40 18             	mov    0x18(%eax),%eax
80105276:	8b 40 44             	mov    0x44(%eax),%eax
80105279:	83 e8 04             	sub    $0x4,%eax
8010527c:	25 ff 0f 00 00       	and    $0xfff,%eax
80105281:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105284:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010528b:	8b 52 18             	mov    0x18(%edx),%edx
8010528e:	8b 52 38             	mov    0x38(%edx),%edx
80105291:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105293:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105299:	8b 40 18             	mov    0x18(%eax),%eax
8010529c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801052a3:	8b 52 18             	mov    0x18(%edx),%edx
801052a6:	8b 52 44             	mov    0x44(%edx),%edx
801052a9:	83 ea 04             	sub    $0x4,%edx
801052ac:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801052af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052b5:	8b 40 18             	mov    0x18(%eax),%eax
801052b8:	8b 55 08             	mov    0x8(%ebp),%edx
801052bb:	89 50 38             	mov    %edx,0x38(%eax)
}
801052be:	c9                   	leave  
801052bf:	c3                   	ret    

801052c0 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801052c0:	55                   	push   %ebp
801052c1:	89 e5                	mov    %esp,%ebp
801052c3:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801052c6:	e8 de f8 ff ff       	call   80104ba9 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801052cb:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801052d2:	e8 70 04 00 00       	call   80105747 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052d7:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801052de:	eb 5f                	jmp    8010533f <scheduler+0x7f>
      if(p->state != RUNNABLE)
801052e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052e3:	8b 40 0c             	mov    0xc(%eax),%eax
801052e6:	83 f8 03             	cmp    $0x3,%eax
801052e9:	75 4f                	jne    8010533a <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801052eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ee:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801052f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f7:	89 04 24             	mov    %eax,(%esp)
801052fa:	e8 6b 34 00 00       	call   8010876a <switchuvm>
      p->state = RUNNING;
801052ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105302:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105309:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010530f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105312:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105319:	83 c2 04             	add    $0x4,%edx
8010531c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105320:	89 14 24             	mov    %edx,(%esp)
80105323:	e8 14 09 00 00       	call   80105c3c <swtch>
      switchkvm();
80105328:	e8 20 34 00 00       	call   8010874d <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
8010532d:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105334:	00 00 00 00 
80105338:	eb 01                	jmp    8010533b <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010533a:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010533b:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010533f:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80105346:	72 98                	jb     801052e0 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105348:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010534f:	e8 55 04 00 00       	call   801057a9 <release>

  }
80105354:	e9 6d ff ff ff       	jmp    801052c6 <scheduler+0x6>

80105359 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105359:	55                   	push   %ebp
8010535a:	89 e5                	mov    %esp,%ebp
8010535c:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010535f:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105366:	e8 fa 04 00 00       	call   80105865 <holding>
8010536b:	85 c0                	test   %eax,%eax
8010536d:	75 0c                	jne    8010537b <sched+0x22>
    panic("sched ptable.lock");
8010536f:	c7 04 24 91 92 10 80 	movl   $0x80109291,(%esp)
80105376:	e8 c2 b1 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
8010537b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105381:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105387:	83 f8 01             	cmp    $0x1,%eax
8010538a:	74 0c                	je     80105398 <sched+0x3f>
    panic("sched locks");
8010538c:	c7 04 24 a3 92 10 80 	movl   $0x801092a3,(%esp)
80105393:	e8 a5 b1 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105398:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010539e:	8b 40 0c             	mov    0xc(%eax),%eax
801053a1:	83 f8 04             	cmp    $0x4,%eax
801053a4:	75 0c                	jne    801053b2 <sched+0x59>
    panic("sched running");
801053a6:	c7 04 24 af 92 10 80 	movl   $0x801092af,(%esp)
801053ad:	e8 8b b1 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801053b2:	e8 dd f7 ff ff       	call   80104b94 <readeflags>
801053b7:	25 00 02 00 00       	and    $0x200,%eax
801053bc:	85 c0                	test   %eax,%eax
801053be:	74 0c                	je     801053cc <sched+0x73>
    panic("sched interruptible");
801053c0:	c7 04 24 bd 92 10 80 	movl   $0x801092bd,(%esp)
801053c7:	e8 71 b1 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801053cc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053d2:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801053d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801053db:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053e1:	8b 40 04             	mov    0x4(%eax),%eax
801053e4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801053eb:	83 c2 1c             	add    $0x1c,%edx
801053ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f2:	89 14 24             	mov    %edx,(%esp)
801053f5:	e8 42 08 00 00       	call   80105c3c <swtch>
  cpu->intena = intena;
801053fa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105400:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105403:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105409:	c9                   	leave  
8010540a:	c3                   	ret    

8010540b <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010540b:	55                   	push   %ebp
8010540c:	89 e5                	mov    %esp,%ebp
8010540e:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105411:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105418:	e8 2a 03 00 00       	call   80105747 <acquire>
  proc->state = RUNNABLE;
8010541d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105423:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010542a:	e8 2a ff ff ff       	call   80105359 <sched>
  release(&ptable.lock);
8010542f:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105436:	e8 6e 03 00 00       	call   801057a9 <release>
}
8010543b:	c9                   	leave  
8010543c:	c3                   	ret    

8010543d <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
8010543d:	55                   	push   %ebp
8010543e:	89 e5                	mov    %esp,%ebp
80105440:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105443:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010544a:	e8 5a 03 00 00       	call   801057a9 <release>

  if (first) {
8010544f:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105454:	85 c0                	test   %eax,%eax
80105456:	74 0f                	je     80105467 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105458:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
8010545f:	00 00 00 
    initlog();
80105462:	e8 4d e7 ff ff       	call   80103bb4 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105467:	c9                   	leave  
80105468:	c3                   	ret    

80105469 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105469:	55                   	push   %ebp
8010546a:	89 e5                	mov    %esp,%ebp
8010546c:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010546f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105475:	85 c0                	test   %eax,%eax
80105477:	75 0c                	jne    80105485 <sleep+0x1c>
    panic("sleep");
80105479:	c7 04 24 d1 92 10 80 	movl   $0x801092d1,(%esp)
80105480:	e8 b8 b0 ff ff       	call   8010053d <panic>

  if(lk == 0)
80105485:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105489:	75 0c                	jne    80105497 <sleep+0x2e>
    panic("sleep without lk");
8010548b:	c7 04 24 d7 92 10 80 	movl   $0x801092d7,(%esp)
80105492:	e8 a6 b0 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105497:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
8010549e:	74 17                	je     801054b7 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801054a0:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054a7:	e8 9b 02 00 00       	call   80105747 <acquire>
    release(lk);
801054ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801054af:	89 04 24             	mov    %eax,(%esp)
801054b2:	e8 f2 02 00 00       	call   801057a9 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801054b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054bd:	8b 55 08             	mov    0x8(%ebp),%edx
801054c0:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801054c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c9:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801054d0:	e8 84 fe ff ff       	call   80105359 <sched>

  // Tidy up.
  proc->chan = 0;
801054d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054db:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801054e2:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801054e9:	74 17                	je     80105502 <sleep+0x99>
    release(&ptable.lock);
801054eb:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054f2:	e8 b2 02 00 00       	call   801057a9 <release>
    acquire(lk);
801054f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801054fa:	89 04 24             	mov    %eax,(%esp)
801054fd:	e8 45 02 00 00       	call   80105747 <acquire>
  }
}
80105502:	c9                   	leave  
80105503:	c3                   	ret    

80105504 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105504:	55                   	push   %ebp
80105505:	89 e5                	mov    %esp,%ebp
80105507:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010550a:	c7 45 fc 74 0f 11 80 	movl   $0x80110f74,-0x4(%ebp)
80105511:	eb 24                	jmp    80105537 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105513:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105516:	8b 40 0c             	mov    0xc(%eax),%eax
80105519:	83 f8 02             	cmp    $0x2,%eax
8010551c:	75 15                	jne    80105533 <wakeup1+0x2f>
8010551e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105521:	8b 40 20             	mov    0x20(%eax),%eax
80105524:	3b 45 08             	cmp    0x8(%ebp),%eax
80105527:	75 0a                	jne    80105533 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105529:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010552c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105533:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105537:	81 7d fc 74 2e 11 80 	cmpl   $0x80112e74,-0x4(%ebp)
8010553e:	72 d3                	jb     80105513 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105540:	c9                   	leave  
80105541:	c3                   	ret    

80105542 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105542:	55                   	push   %ebp
80105543:	89 e5                	mov    %esp,%ebp
80105545:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105548:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010554f:	e8 f3 01 00 00       	call   80105747 <acquire>
  wakeup1(chan);
80105554:	8b 45 08             	mov    0x8(%ebp),%eax
80105557:	89 04 24             	mov    %eax,(%esp)
8010555a:	e8 a5 ff ff ff       	call   80105504 <wakeup1>
  release(&ptable.lock);
8010555f:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105566:	e8 3e 02 00 00       	call   801057a9 <release>
}
8010556b:	c9                   	leave  
8010556c:	c3                   	ret    

8010556d <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010556d:	55                   	push   %ebp
8010556e:	89 e5                	mov    %esp,%ebp
80105570:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105573:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010557a:	e8 c8 01 00 00       	call   80105747 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010557f:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80105586:	eb 41                	jmp    801055c9 <kill+0x5c>
    if(p->pid == pid){
80105588:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010558b:	8b 40 10             	mov    0x10(%eax),%eax
8010558e:	3b 45 08             	cmp    0x8(%ebp),%eax
80105591:	75 32                	jne    801055c5 <kill+0x58>
      p->killed = 1;
80105593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105596:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
8010559d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055a0:	8b 40 0c             	mov    0xc(%eax),%eax
801055a3:	83 f8 02             	cmp    $0x2,%eax
801055a6:	75 0a                	jne    801055b2 <kill+0x45>
        p->state = RUNNABLE;
801055a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ab:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
801055b2:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801055b9:	e8 eb 01 00 00       	call   801057a9 <release>
      return 0;
801055be:	b8 00 00 00 00       	mov    $0x0,%eax
801055c3:	eb 1e                	jmp    801055e3 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055c5:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801055c9:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801055d0:	72 b6                	jb     80105588 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801055d2:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801055d9:	e8 cb 01 00 00       	call   801057a9 <release>
  return -1;
801055de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801055e3:	c9                   	leave  
801055e4:	c3                   	ret    

801055e5 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801055e5:	55                   	push   %ebp
801055e6:	89 e5                	mov    %esp,%ebp
801055e8:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055eb:	c7 45 f0 74 0f 11 80 	movl   $0x80110f74,-0x10(%ebp)
801055f2:	e9 d8 00 00 00       	jmp    801056cf <procdump+0xea>
    if(p->state == UNUSED)
801055f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055fa:	8b 40 0c             	mov    0xc(%eax),%eax
801055fd:	85 c0                	test   %eax,%eax
801055ff:	0f 84 c5 00 00 00    	je     801056ca <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105605:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105608:	8b 40 0c             	mov    0xc(%eax),%eax
8010560b:	83 f8 05             	cmp    $0x5,%eax
8010560e:	77 23                	ja     80105633 <procdump+0x4e>
80105610:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105613:	8b 40 0c             	mov    0xc(%eax),%eax
80105616:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
8010561d:	85 c0                	test   %eax,%eax
8010561f:	74 12                	je     80105633 <procdump+0x4e>
      state = states[p->state];
80105621:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105624:	8b 40 0c             	mov    0xc(%eax),%eax
80105627:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
8010562e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105631:	eb 07                	jmp    8010563a <procdump+0x55>
    else
      state = "???";
80105633:	c7 45 ec e8 92 10 80 	movl   $0x801092e8,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010563a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010563d:	8d 50 6c             	lea    0x6c(%eax),%edx
80105640:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105643:	8b 40 10             	mov    0x10(%eax),%eax
80105646:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010564a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010564d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105651:	89 44 24 04          	mov    %eax,0x4(%esp)
80105655:	c7 04 24 ec 92 10 80 	movl   $0x801092ec,(%esp)
8010565c:	e8 40 ad ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105661:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105664:	8b 40 0c             	mov    0xc(%eax),%eax
80105667:	83 f8 02             	cmp    $0x2,%eax
8010566a:	75 50                	jne    801056bc <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010566c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010566f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105672:	8b 40 0c             	mov    0xc(%eax),%eax
80105675:	83 c0 08             	add    $0x8,%eax
80105678:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010567b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010567f:	89 04 24             	mov    %eax,(%esp)
80105682:	e8 71 01 00 00       	call   801057f8 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105687:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010568e:	eb 1b                	jmp    801056ab <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105690:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105693:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105697:	89 44 24 04          	mov    %eax,0x4(%esp)
8010569b:	c7 04 24 f5 92 10 80 	movl   $0x801092f5,(%esp)
801056a2:	e8 fa ac ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801056a7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056ab:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801056af:	7f 0b                	jg     801056bc <procdump+0xd7>
801056b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056b4:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801056b8:	85 c0                	test   %eax,%eax
801056ba:	75 d4                	jne    80105690 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801056bc:	c7 04 24 f9 92 10 80 	movl   $0x801092f9,(%esp)
801056c3:	e8 d9 ac ff ff       	call   801003a1 <cprintf>
801056c8:	eb 01                	jmp    801056cb <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
801056ca:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801056cb:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801056cf:	81 7d f0 74 2e 11 80 	cmpl   $0x80112e74,-0x10(%ebp)
801056d6:	0f 82 1b ff ff ff    	jb     801055f7 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801056dc:	c9                   	leave  
801056dd:	c3                   	ret    
	...

801056e0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801056e0:	55                   	push   %ebp
801056e1:	89 e5                	mov    %esp,%ebp
801056e3:	53                   	push   %ebx
801056e4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801056e7:	9c                   	pushf  
801056e8:	5b                   	pop    %ebx
801056e9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801056ec:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801056ef:	83 c4 10             	add    $0x10,%esp
801056f2:	5b                   	pop    %ebx
801056f3:	5d                   	pop    %ebp
801056f4:	c3                   	ret    

801056f5 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801056f5:	55                   	push   %ebp
801056f6:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801056f8:	fa                   	cli    
}
801056f9:	5d                   	pop    %ebp
801056fa:	c3                   	ret    

801056fb <sti>:

static inline void
sti(void)
{
801056fb:	55                   	push   %ebp
801056fc:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801056fe:	fb                   	sti    
}
801056ff:	5d                   	pop    %ebp
80105700:	c3                   	ret    

80105701 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105701:	55                   	push   %ebp
80105702:	89 e5                	mov    %esp,%ebp
80105704:	53                   	push   %ebx
80105705:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105708:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010570b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010570e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105711:	89 c3                	mov    %eax,%ebx
80105713:	89 d8                	mov    %ebx,%eax
80105715:	f0 87 02             	lock xchg %eax,(%edx)
80105718:	89 c3                	mov    %eax,%ebx
8010571a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010571d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105720:	83 c4 10             	add    $0x10,%esp
80105723:	5b                   	pop    %ebx
80105724:	5d                   	pop    %ebp
80105725:	c3                   	ret    

80105726 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105726:	55                   	push   %ebp
80105727:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105729:	8b 45 08             	mov    0x8(%ebp),%eax
8010572c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010572f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105732:	8b 45 08             	mov    0x8(%ebp),%eax
80105735:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
8010573b:	8b 45 08             	mov    0x8(%ebp),%eax
8010573e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105745:	5d                   	pop    %ebp
80105746:	c3                   	ret    

80105747 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105747:	55                   	push   %ebp
80105748:	89 e5                	mov    %esp,%ebp
8010574a:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
8010574d:	e8 3d 01 00 00       	call   8010588f <pushcli>
  if(holding(lk))
80105752:	8b 45 08             	mov    0x8(%ebp),%eax
80105755:	89 04 24             	mov    %eax,(%esp)
80105758:	e8 08 01 00 00       	call   80105865 <holding>
8010575d:	85 c0                	test   %eax,%eax
8010575f:	74 0c                	je     8010576d <acquire+0x26>
    panic("acquire");
80105761:	c7 04 24 25 93 10 80 	movl   $0x80109325,(%esp)
80105768:	e8 d0 ad ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
8010576d:	90                   	nop
8010576e:	8b 45 08             	mov    0x8(%ebp),%eax
80105771:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105778:	00 
80105779:	89 04 24             	mov    %eax,(%esp)
8010577c:	e8 80 ff ff ff       	call   80105701 <xchg>
80105781:	85 c0                	test   %eax,%eax
80105783:	75 e9                	jne    8010576e <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105785:	8b 45 08             	mov    0x8(%ebp),%eax
80105788:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010578f:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105792:	8b 45 08             	mov    0x8(%ebp),%eax
80105795:	83 c0 0c             	add    $0xc,%eax
80105798:	89 44 24 04          	mov    %eax,0x4(%esp)
8010579c:	8d 45 08             	lea    0x8(%ebp),%eax
8010579f:	89 04 24             	mov    %eax,(%esp)
801057a2:	e8 51 00 00 00       	call   801057f8 <getcallerpcs>
}
801057a7:	c9                   	leave  
801057a8:	c3                   	ret    

801057a9 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
801057a9:	55                   	push   %ebp
801057aa:	89 e5                	mov    %esp,%ebp
801057ac:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
801057af:	8b 45 08             	mov    0x8(%ebp),%eax
801057b2:	89 04 24             	mov    %eax,(%esp)
801057b5:	e8 ab 00 00 00       	call   80105865 <holding>
801057ba:	85 c0                	test   %eax,%eax
801057bc:	75 0c                	jne    801057ca <release+0x21>
    panic("release");
801057be:	c7 04 24 2d 93 10 80 	movl   $0x8010932d,(%esp)
801057c5:	e8 73 ad ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
801057ca:	8b 45 08             	mov    0x8(%ebp),%eax
801057cd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801057d4:	8b 45 08             	mov    0x8(%ebp),%eax
801057d7:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801057de:	8b 45 08             	mov    0x8(%ebp),%eax
801057e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057e8:	00 
801057e9:	89 04 24             	mov    %eax,(%esp)
801057ec:	e8 10 ff ff ff       	call   80105701 <xchg>

  popcli();
801057f1:	e8 e1 00 00 00       	call   801058d7 <popcli>
}
801057f6:	c9                   	leave  
801057f7:	c3                   	ret    

801057f8 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801057f8:	55                   	push   %ebp
801057f9:	89 e5                	mov    %esp,%ebp
801057fb:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801057fe:	8b 45 08             	mov    0x8(%ebp),%eax
80105801:	83 e8 08             	sub    $0x8,%eax
80105804:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105807:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010580e:	eb 32                	jmp    80105842 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105810:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105814:	74 47                	je     8010585d <getcallerpcs+0x65>
80105816:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010581d:	76 3e                	jbe    8010585d <getcallerpcs+0x65>
8010581f:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105823:	74 38                	je     8010585d <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105825:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105828:	c1 e0 02             	shl    $0x2,%eax
8010582b:	03 45 0c             	add    0xc(%ebp),%eax
8010582e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105831:	8b 52 04             	mov    0x4(%edx),%edx
80105834:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105836:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105839:	8b 00                	mov    (%eax),%eax
8010583b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
8010583e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105842:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105846:	7e c8                	jle    80105810 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105848:	eb 13                	jmp    8010585d <getcallerpcs+0x65>
    pcs[i] = 0;
8010584a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010584d:	c1 e0 02             	shl    $0x2,%eax
80105850:	03 45 0c             	add    0xc(%ebp),%eax
80105853:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105859:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010585d:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105861:	7e e7                	jle    8010584a <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105863:	c9                   	leave  
80105864:	c3                   	ret    

80105865 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105865:	55                   	push   %ebp
80105866:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105868:	8b 45 08             	mov    0x8(%ebp),%eax
8010586b:	8b 00                	mov    (%eax),%eax
8010586d:	85 c0                	test   %eax,%eax
8010586f:	74 17                	je     80105888 <holding+0x23>
80105871:	8b 45 08             	mov    0x8(%ebp),%eax
80105874:	8b 50 08             	mov    0x8(%eax),%edx
80105877:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010587d:	39 c2                	cmp    %eax,%edx
8010587f:	75 07                	jne    80105888 <holding+0x23>
80105881:	b8 01 00 00 00       	mov    $0x1,%eax
80105886:	eb 05                	jmp    8010588d <holding+0x28>
80105888:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010588d:	5d                   	pop    %ebp
8010588e:	c3                   	ret    

8010588f <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010588f:	55                   	push   %ebp
80105890:	89 e5                	mov    %esp,%ebp
80105892:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105895:	e8 46 fe ff ff       	call   801056e0 <readeflags>
8010589a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010589d:	e8 53 fe ff ff       	call   801056f5 <cli>
  if(cpu->ncli++ == 0)
801058a2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058a8:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801058ae:	85 d2                	test   %edx,%edx
801058b0:	0f 94 c1             	sete   %cl
801058b3:	83 c2 01             	add    $0x1,%edx
801058b6:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801058bc:	84 c9                	test   %cl,%cl
801058be:	74 15                	je     801058d5 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
801058c0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058c6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801058c9:	81 e2 00 02 00 00    	and    $0x200,%edx
801058cf:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801058d5:	c9                   	leave  
801058d6:	c3                   	ret    

801058d7 <popcli>:

void
popcli(void)
{
801058d7:	55                   	push   %ebp
801058d8:	89 e5                	mov    %esp,%ebp
801058da:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801058dd:	e8 fe fd ff ff       	call   801056e0 <readeflags>
801058e2:	25 00 02 00 00       	and    $0x200,%eax
801058e7:	85 c0                	test   %eax,%eax
801058e9:	74 0c                	je     801058f7 <popcli+0x20>
    panic("popcli - interruptible");
801058eb:	c7 04 24 35 93 10 80 	movl   $0x80109335,(%esp)
801058f2:	e8 46 ac ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
801058f7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801058fd:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105903:	83 ea 01             	sub    $0x1,%edx
80105906:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
8010590c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105912:	85 c0                	test   %eax,%eax
80105914:	79 0c                	jns    80105922 <popcli+0x4b>
    panic("popcli");
80105916:	c7 04 24 4c 93 10 80 	movl   $0x8010934c,(%esp)
8010591d:	e8 1b ac ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105922:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105928:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010592e:	85 c0                	test   %eax,%eax
80105930:	75 15                	jne    80105947 <popcli+0x70>
80105932:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105938:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
8010593e:	85 c0                	test   %eax,%eax
80105940:	74 05                	je     80105947 <popcli+0x70>
    sti();
80105942:	e8 b4 fd ff ff       	call   801056fb <sti>
}
80105947:	c9                   	leave  
80105948:	c3                   	ret    
80105949:	00 00                	add    %al,(%eax)
	...

8010594c <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
8010594c:	55                   	push   %ebp
8010594d:	89 e5                	mov    %esp,%ebp
8010594f:	57                   	push   %edi
80105950:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105951:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105954:	8b 55 10             	mov    0x10(%ebp),%edx
80105957:	8b 45 0c             	mov    0xc(%ebp),%eax
8010595a:	89 cb                	mov    %ecx,%ebx
8010595c:	89 df                	mov    %ebx,%edi
8010595e:	89 d1                	mov    %edx,%ecx
80105960:	fc                   	cld    
80105961:	f3 aa                	rep stos %al,%es:(%edi)
80105963:	89 ca                	mov    %ecx,%edx
80105965:	89 fb                	mov    %edi,%ebx
80105967:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010596a:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010596d:	5b                   	pop    %ebx
8010596e:	5f                   	pop    %edi
8010596f:	5d                   	pop    %ebp
80105970:	c3                   	ret    

80105971 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105971:	55                   	push   %ebp
80105972:	89 e5                	mov    %esp,%ebp
80105974:	57                   	push   %edi
80105975:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105976:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105979:	8b 55 10             	mov    0x10(%ebp),%edx
8010597c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010597f:	89 cb                	mov    %ecx,%ebx
80105981:	89 df                	mov    %ebx,%edi
80105983:	89 d1                	mov    %edx,%ecx
80105985:	fc                   	cld    
80105986:	f3 ab                	rep stos %eax,%es:(%edi)
80105988:	89 ca                	mov    %ecx,%edx
8010598a:	89 fb                	mov    %edi,%ebx
8010598c:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010598f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105992:	5b                   	pop    %ebx
80105993:	5f                   	pop    %edi
80105994:	5d                   	pop    %ebp
80105995:	c3                   	ret    

80105996 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105996:	55                   	push   %ebp
80105997:	89 e5                	mov    %esp,%ebp
80105999:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
8010599c:	8b 45 08             	mov    0x8(%ebp),%eax
8010599f:	83 e0 03             	and    $0x3,%eax
801059a2:	85 c0                	test   %eax,%eax
801059a4:	75 49                	jne    801059ef <memset+0x59>
801059a6:	8b 45 10             	mov    0x10(%ebp),%eax
801059a9:	83 e0 03             	and    $0x3,%eax
801059ac:	85 c0                	test   %eax,%eax
801059ae:	75 3f                	jne    801059ef <memset+0x59>
    c &= 0xFF;
801059b0:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801059b7:	8b 45 10             	mov    0x10(%ebp),%eax
801059ba:	c1 e8 02             	shr    $0x2,%eax
801059bd:	89 c2                	mov    %eax,%edx
801059bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801059c2:	89 c1                	mov    %eax,%ecx
801059c4:	c1 e1 18             	shl    $0x18,%ecx
801059c7:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ca:	c1 e0 10             	shl    $0x10,%eax
801059cd:	09 c1                	or     %eax,%ecx
801059cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801059d2:	c1 e0 08             	shl    $0x8,%eax
801059d5:	09 c8                	or     %ecx,%eax
801059d7:	0b 45 0c             	or     0xc(%ebp),%eax
801059da:	89 54 24 08          	mov    %edx,0x8(%esp)
801059de:	89 44 24 04          	mov    %eax,0x4(%esp)
801059e2:	8b 45 08             	mov    0x8(%ebp),%eax
801059e5:	89 04 24             	mov    %eax,(%esp)
801059e8:	e8 84 ff ff ff       	call   80105971 <stosl>
801059ed:	eb 19                	jmp    80105a08 <memset+0x72>
  } else
    stosb(dst, c, n);
801059ef:	8b 45 10             	mov    0x10(%ebp),%eax
801059f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801059f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801059f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801059fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105a00:	89 04 24             	mov    %eax,(%esp)
80105a03:	e8 44 ff ff ff       	call   8010594c <stosb>
  return dst;
80105a08:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105a0b:	c9                   	leave  
80105a0c:	c3                   	ret    

80105a0d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105a0d:	55                   	push   %ebp
80105a0e:	89 e5                	mov    %esp,%ebp
80105a10:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105a13:	8b 45 08             	mov    0x8(%ebp),%eax
80105a16:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105a19:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105a1f:	eb 32                	jmp    80105a53 <memcmp+0x46>
    if(*s1 != *s2)
80105a21:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a24:	0f b6 10             	movzbl (%eax),%edx
80105a27:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a2a:	0f b6 00             	movzbl (%eax),%eax
80105a2d:	38 c2                	cmp    %al,%dl
80105a2f:	74 1a                	je     80105a4b <memcmp+0x3e>
      return *s1 - *s2;
80105a31:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a34:	0f b6 00             	movzbl (%eax),%eax
80105a37:	0f b6 d0             	movzbl %al,%edx
80105a3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105a3d:	0f b6 00             	movzbl (%eax),%eax
80105a40:	0f b6 c0             	movzbl %al,%eax
80105a43:	89 d1                	mov    %edx,%ecx
80105a45:	29 c1                	sub    %eax,%ecx
80105a47:	89 c8                	mov    %ecx,%eax
80105a49:	eb 1c                	jmp    80105a67 <memcmp+0x5a>
    s1++, s2++;
80105a4b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a4f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105a53:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105a57:	0f 95 c0             	setne  %al
80105a5a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105a5e:	84 c0                	test   %al,%al
80105a60:	75 bf                	jne    80105a21 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105a62:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105a67:	c9                   	leave  
80105a68:	c3                   	ret    

80105a69 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105a69:	55                   	push   %ebp
80105a6a:	89 e5                	mov    %esp,%ebp
80105a6c:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105a6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a72:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105a75:	8b 45 08             	mov    0x8(%ebp),%eax
80105a78:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105a7b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a7e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105a81:	73 54                	jae    80105ad7 <memmove+0x6e>
80105a83:	8b 45 10             	mov    0x10(%ebp),%eax
80105a86:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105a89:	01 d0                	add    %edx,%eax
80105a8b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105a8e:	76 47                	jbe    80105ad7 <memmove+0x6e>
    s += n;
80105a90:	8b 45 10             	mov    0x10(%ebp),%eax
80105a93:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105a96:	8b 45 10             	mov    0x10(%ebp),%eax
80105a99:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105a9c:	eb 13                	jmp    80105ab1 <memmove+0x48>
      *--d = *--s;
80105a9e:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105aa2:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105aa6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105aa9:	0f b6 10             	movzbl (%eax),%edx
80105aac:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105aaf:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105ab1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ab5:	0f 95 c0             	setne  %al
80105ab8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105abc:	84 c0                	test   %al,%al
80105abe:	75 de                	jne    80105a9e <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105ac0:	eb 25                	jmp    80105ae7 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105ac2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ac5:	0f b6 10             	movzbl (%eax),%edx
80105ac8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105acb:	88 10                	mov    %dl,(%eax)
80105acd:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ad1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105ad5:	eb 01                	jmp    80105ad8 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105ad7:	90                   	nop
80105ad8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105adc:	0f 95 c0             	setne  %al
80105adf:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ae3:	84 c0                	test   %al,%al
80105ae5:	75 db                	jne    80105ac2 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105ae7:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105aea:	c9                   	leave  
80105aeb:	c3                   	ret    

80105aec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105aec:	55                   	push   %ebp
80105aed:	89 e5                	mov    %esp,%ebp
80105aef:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105af2:	8b 45 10             	mov    0x10(%ebp),%eax
80105af5:	89 44 24 08          	mov    %eax,0x8(%esp)
80105af9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105afc:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b00:	8b 45 08             	mov    0x8(%ebp),%eax
80105b03:	89 04 24             	mov    %eax,(%esp)
80105b06:	e8 5e ff ff ff       	call   80105a69 <memmove>
}
80105b0b:	c9                   	leave  
80105b0c:	c3                   	ret    

80105b0d <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105b0d:	55                   	push   %ebp
80105b0e:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105b10:	eb 0c                	jmp    80105b1e <strncmp+0x11>
    n--, p++, q++;
80105b12:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b16:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b1a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105b1e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b22:	74 1a                	je     80105b3e <strncmp+0x31>
80105b24:	8b 45 08             	mov    0x8(%ebp),%eax
80105b27:	0f b6 00             	movzbl (%eax),%eax
80105b2a:	84 c0                	test   %al,%al
80105b2c:	74 10                	je     80105b3e <strncmp+0x31>
80105b2e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b31:	0f b6 10             	movzbl (%eax),%edx
80105b34:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b37:	0f b6 00             	movzbl (%eax),%eax
80105b3a:	38 c2                	cmp    %al,%dl
80105b3c:	74 d4                	je     80105b12 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105b3e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b42:	75 07                	jne    80105b4b <strncmp+0x3e>
    return 0;
80105b44:	b8 00 00 00 00       	mov    $0x0,%eax
80105b49:	eb 18                	jmp    80105b63 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105b4b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b4e:	0f b6 00             	movzbl (%eax),%eax
80105b51:	0f b6 d0             	movzbl %al,%edx
80105b54:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b57:	0f b6 00             	movzbl (%eax),%eax
80105b5a:	0f b6 c0             	movzbl %al,%eax
80105b5d:	89 d1                	mov    %edx,%ecx
80105b5f:	29 c1                	sub    %eax,%ecx
80105b61:	89 c8                	mov    %ecx,%eax
}
80105b63:	5d                   	pop    %ebp
80105b64:	c3                   	ret    

80105b65 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105b65:	55                   	push   %ebp
80105b66:	89 e5                	mov    %esp,%ebp
80105b68:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105b6b:	8b 45 08             	mov    0x8(%ebp),%eax
80105b6e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105b71:	90                   	nop
80105b72:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105b76:	0f 9f c0             	setg   %al
80105b79:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105b7d:	84 c0                	test   %al,%al
80105b7f:	74 30                	je     80105bb1 <strncpy+0x4c>
80105b81:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b84:	0f b6 10             	movzbl (%eax),%edx
80105b87:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8a:	88 10                	mov    %dl,(%eax)
80105b8c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b8f:	0f b6 00             	movzbl (%eax),%eax
80105b92:	84 c0                	test   %al,%al
80105b94:	0f 95 c0             	setne  %al
80105b97:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105b9b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105b9f:	84 c0                	test   %al,%al
80105ba1:	75 cf                	jne    80105b72 <strncpy+0xd>
    ;
  while(n-- > 0)
80105ba3:	eb 0c                	jmp    80105bb1 <strncpy+0x4c>
    *s++ = 0;
80105ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80105ba8:	c6 00 00             	movb   $0x0,(%eax)
80105bab:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105baf:	eb 01                	jmp    80105bb2 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105bb1:	90                   	nop
80105bb2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bb6:	0f 9f c0             	setg   %al
80105bb9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105bbd:	84 c0                	test   %al,%al
80105bbf:	75 e4                	jne    80105ba5 <strncpy+0x40>
    *s++ = 0;
  return os;
80105bc1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105bc4:	c9                   	leave  
80105bc5:	c3                   	ret    

80105bc6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105bc6:	55                   	push   %ebp
80105bc7:	89 e5                	mov    %esp,%ebp
80105bc9:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80105bcf:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105bd2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105bd6:	7f 05                	jg     80105bdd <safestrcpy+0x17>
    return os;
80105bd8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bdb:	eb 35                	jmp    80105c12 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105bdd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105be1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105be5:	7e 22                	jle    80105c09 <safestrcpy+0x43>
80105be7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bea:	0f b6 10             	movzbl (%eax),%edx
80105bed:	8b 45 08             	mov    0x8(%ebp),%eax
80105bf0:	88 10                	mov    %dl,(%eax)
80105bf2:	8b 45 08             	mov    0x8(%ebp),%eax
80105bf5:	0f b6 00             	movzbl (%eax),%eax
80105bf8:	84 c0                	test   %al,%al
80105bfa:	0f 95 c0             	setne  %al
80105bfd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105c01:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105c05:	84 c0                	test   %al,%al
80105c07:	75 d4                	jne    80105bdd <safestrcpy+0x17>
    ;
  *s = 0;
80105c09:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0c:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105c0f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c12:	c9                   	leave  
80105c13:	c3                   	ret    

80105c14 <strlen>:

int
strlen(const char *s)
{
80105c14:	55                   	push   %ebp
80105c15:	89 e5                	mov    %esp,%ebp
80105c17:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105c1a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105c21:	eb 04                	jmp    80105c27 <strlen+0x13>
80105c23:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105c27:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c2a:	03 45 08             	add    0x8(%ebp),%eax
80105c2d:	0f b6 00             	movzbl (%eax),%eax
80105c30:	84 c0                	test   %al,%al
80105c32:	75 ef                	jne    80105c23 <strlen+0xf>
    ;
  return n;
80105c34:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105c37:	c9                   	leave  
80105c38:	c3                   	ret    
80105c39:	00 00                	add    %al,(%eax)
	...

80105c3c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105c3c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105c40:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105c44:	55                   	push   %ebp
  pushl %ebx
80105c45:	53                   	push   %ebx
  pushl %esi
80105c46:	56                   	push   %esi
  pushl %edi
80105c47:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105c48:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105c4a:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105c4c:	5f                   	pop    %edi
  popl %esi
80105c4d:	5e                   	pop    %esi
  popl %ebx
80105c4e:	5b                   	pop    %ebx
  popl %ebp
80105c4f:	5d                   	pop    %ebp
  ret
80105c50:	c3                   	ret    
80105c51:	00 00                	add    %al,(%eax)
	...

80105c54 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105c54:	55                   	push   %ebp
80105c55:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105c57:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5a:	8b 00                	mov    (%eax),%eax
80105c5c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105c5f:	76 0f                	jbe    80105c70 <fetchint+0x1c>
80105c61:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c64:	8d 50 04             	lea    0x4(%eax),%edx
80105c67:	8b 45 08             	mov    0x8(%ebp),%eax
80105c6a:	8b 00                	mov    (%eax),%eax
80105c6c:	39 c2                	cmp    %eax,%edx
80105c6e:	76 07                	jbe    80105c77 <fetchint+0x23>
    return -1;
80105c70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c75:	eb 0f                	jmp    80105c86 <fetchint+0x32>
  *ip = *(int*)(addr);
80105c77:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c7a:	8b 10                	mov    (%eax),%edx
80105c7c:	8b 45 10             	mov    0x10(%ebp),%eax
80105c7f:	89 10                	mov    %edx,(%eax)
  return 0;
80105c81:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c86:	5d                   	pop    %ebp
80105c87:	c3                   	ret    

80105c88 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105c88:	55                   	push   %ebp
80105c89:	89 e5                	mov    %esp,%ebp
80105c8b:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105c8e:	8b 45 08             	mov    0x8(%ebp),%eax
80105c91:	8b 00                	mov    (%eax),%eax
80105c93:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105c96:	77 07                	ja     80105c9f <fetchstr+0x17>
    return -1;
80105c98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c9d:	eb 45                	jmp    80105ce4 <fetchstr+0x5c>
  *pp = (char*)addr;
80105c9f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105ca2:	8b 45 10             	mov    0x10(%ebp),%eax
80105ca5:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105ca7:	8b 45 08             	mov    0x8(%ebp),%eax
80105caa:	8b 00                	mov    (%eax),%eax
80105cac:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105caf:	8b 45 10             	mov    0x10(%ebp),%eax
80105cb2:	8b 00                	mov    (%eax),%eax
80105cb4:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105cb7:	eb 1e                	jmp    80105cd7 <fetchstr+0x4f>
    if(*s == 0)
80105cb9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cbc:	0f b6 00             	movzbl (%eax),%eax
80105cbf:	84 c0                	test   %al,%al
80105cc1:	75 10                	jne    80105cd3 <fetchstr+0x4b>
      return s - *pp;
80105cc3:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105cc6:	8b 45 10             	mov    0x10(%ebp),%eax
80105cc9:	8b 00                	mov    (%eax),%eax
80105ccb:	89 d1                	mov    %edx,%ecx
80105ccd:	29 c1                	sub    %eax,%ecx
80105ccf:	89 c8                	mov    %ecx,%eax
80105cd1:	eb 11                	jmp    80105ce4 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105cd3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105cd7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105cda:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105cdd:	72 da                	jb     80105cb9 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105cdf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ce4:	c9                   	leave  
80105ce5:	c3                   	ret    

80105ce6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105ce6:	55                   	push   %ebp
80105ce7:	89 e5                	mov    %esp,%ebp
80105ce9:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105cec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105cf2:	8b 40 18             	mov    0x18(%eax),%eax
80105cf5:	8b 50 44             	mov    0x44(%eax),%edx
80105cf8:	8b 45 08             	mov    0x8(%ebp),%eax
80105cfb:	c1 e0 02             	shl    $0x2,%eax
80105cfe:	01 d0                	add    %edx,%eax
80105d00:	8d 48 04             	lea    0x4(%eax),%ecx
80105d03:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d09:	8b 55 0c             	mov    0xc(%ebp),%edx
80105d0c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105d10:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105d14:	89 04 24             	mov    %eax,(%esp)
80105d17:	e8 38 ff ff ff       	call   80105c54 <fetchint>
}
80105d1c:	c9                   	leave  
80105d1d:	c3                   	ret    

80105d1e <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105d1e:	55                   	push   %ebp
80105d1f:	89 e5                	mov    %esp,%ebp
80105d21:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105d24:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d27:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d2b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d2e:	89 04 24             	mov    %eax,(%esp)
80105d31:	e8 b0 ff ff ff       	call   80105ce6 <argint>
80105d36:	85 c0                	test   %eax,%eax
80105d38:	79 07                	jns    80105d41 <argptr+0x23>
    return -1;
80105d3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d3f:	eb 3d                	jmp    80105d7e <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105d41:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d44:	89 c2                	mov    %eax,%edx
80105d46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d4c:	8b 00                	mov    (%eax),%eax
80105d4e:	39 c2                	cmp    %eax,%edx
80105d50:	73 16                	jae    80105d68 <argptr+0x4a>
80105d52:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d55:	89 c2                	mov    %eax,%edx
80105d57:	8b 45 10             	mov    0x10(%ebp),%eax
80105d5a:	01 c2                	add    %eax,%edx
80105d5c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105d62:	8b 00                	mov    (%eax),%eax
80105d64:	39 c2                	cmp    %eax,%edx
80105d66:	76 07                	jbe    80105d6f <argptr+0x51>
    return -1;
80105d68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105d6d:	eb 0f                	jmp    80105d7e <argptr+0x60>
  *pp = (char*)i;
80105d6f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d72:	89 c2                	mov    %eax,%edx
80105d74:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d77:	89 10                	mov    %edx,(%eax)
  return 0;
80105d79:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d7e:	c9                   	leave  
80105d7f:	c3                   	ret    

80105d80 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105d80:	55                   	push   %ebp
80105d81:	89 e5                	mov    %esp,%ebp
80105d83:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105d86:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105d89:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d8d:	8b 45 08             	mov    0x8(%ebp),%eax
80105d90:	89 04 24             	mov    %eax,(%esp)
80105d93:	e8 4e ff ff ff       	call   80105ce6 <argint>
80105d98:	85 c0                	test   %eax,%eax
80105d9a:	79 07                	jns    80105da3 <argstr+0x23>
    return -1;
80105d9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105da1:	eb 1e                	jmp    80105dc1 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105da3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105da6:	89 c2                	mov    %eax,%edx
80105da8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105db1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105db5:	89 54 24 04          	mov    %edx,0x4(%esp)
80105db9:	89 04 24             	mov    %eax,(%esp)
80105dbc:	e8 c7 fe ff ff       	call   80105c88 <fetchstr>
}
80105dc1:	c9                   	leave  
80105dc2:	c3                   	ret    

80105dc3 <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
80105dc3:	55                   	push   %ebp
80105dc4:	89 e5                	mov    %esp,%ebp
80105dc6:	53                   	push   %ebx
80105dc7:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105dca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105dd0:	8b 40 18             	mov    0x18(%eax),%eax
80105dd3:	8b 40 1c             	mov    0x1c(%eax),%eax
80105dd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80105dd9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ddd:	78 2e                	js     80105e0d <syscall+0x4a>
80105ddf:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105de3:	7f 28                	jg     80105e0d <syscall+0x4a>
80105de5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105de8:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105def:	85 c0                	test   %eax,%eax
80105df1:	74 1a                	je     80105e0d <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105df3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105df9:	8b 58 18             	mov    0x18(%eax),%ebx
80105dfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dff:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105e06:	ff d0                	call   *%eax
80105e08:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e0b:	eb 73                	jmp    80105e80 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105e0d:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105e11:	7e 30                	jle    80105e43 <syscall+0x80>
80105e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e16:	83 f8 19             	cmp    $0x19,%eax
80105e19:	77 28                	ja     80105e43 <syscall+0x80>
80105e1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e1e:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105e25:	85 c0                	test   %eax,%eax
80105e27:	74 1a                	je     80105e43 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80105e29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e2f:	8b 58 18             	mov    0x18(%eax),%ebx
80105e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e35:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80105e3c:	ff d0                	call   *%eax
80105e3e:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105e41:	eb 3d                	jmp    80105e80 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105e43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e49:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105e4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105e52:	8b 40 10             	mov    0x10(%eax),%eax
80105e55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e58:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105e5c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105e60:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e64:	c7 04 24 53 93 10 80 	movl   $0x80109353,(%esp)
80105e6b:	e8 31 a5 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105e70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105e76:	8b 40 18             	mov    0x18(%eax),%eax
80105e79:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105e80:	83 c4 24             	add    $0x24,%esp
80105e83:	5b                   	pop    %ebx
80105e84:	5d                   	pop    %ebp
80105e85:	c3                   	ret    
	...

80105e88 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105e88:	55                   	push   %ebp
80105e89:	89 e5                	mov    %esp,%ebp
80105e8b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105e8e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e91:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e95:	8b 45 08             	mov    0x8(%ebp),%eax
80105e98:	89 04 24             	mov    %eax,(%esp)
80105e9b:	e8 46 fe ff ff       	call   80105ce6 <argint>
80105ea0:	85 c0                	test   %eax,%eax
80105ea2:	79 07                	jns    80105eab <argfd+0x23>
    return -1;
80105ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ea9:	eb 50                	jmp    80105efb <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105eab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eae:	85 c0                	test   %eax,%eax
80105eb0:	78 21                	js     80105ed3 <argfd+0x4b>
80105eb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eb5:	83 f8 0f             	cmp    $0xf,%eax
80105eb8:	7f 19                	jg     80105ed3 <argfd+0x4b>
80105eba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ec0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ec3:	83 c2 08             	add    $0x8,%edx
80105ec6:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105eca:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ecd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ed1:	75 07                	jne    80105eda <argfd+0x52>
    return -1;
80105ed3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed8:	eb 21                	jmp    80105efb <argfd+0x73>
  if(pfd)
80105eda:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105ede:	74 08                	je     80105ee8 <argfd+0x60>
    *pfd = fd;
80105ee0:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ee6:	89 10                	mov    %edx,(%eax)
  if(pf)
80105ee8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eec:	74 08                	je     80105ef6 <argfd+0x6e>
    *pf = f;
80105eee:	8b 45 10             	mov    0x10(%ebp),%eax
80105ef1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ef4:	89 10                	mov    %edx,(%eax)
  return 0;
80105ef6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105efb:	c9                   	leave  
80105efc:	c3                   	ret    

80105efd <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105efd:	55                   	push   %ebp
80105efe:	89 e5                	mov    %esp,%ebp
80105f00:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f03:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f0a:	eb 30                	jmp    80105f3c <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105f0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f12:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f15:	83 c2 08             	add    $0x8,%edx
80105f18:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105f1c:	85 c0                	test   %eax,%eax
80105f1e:	75 18                	jne    80105f38 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105f20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f26:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f29:	8d 4a 08             	lea    0x8(%edx),%ecx
80105f2c:	8b 55 08             	mov    0x8(%ebp),%edx
80105f2f:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105f33:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f36:	eb 0f                	jmp    80105f47 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105f38:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f3c:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105f40:	7e ca                	jle    80105f0c <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105f42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105f47:	c9                   	leave  
80105f48:	c3                   	ret    

80105f49 <sys_dup>:

int
sys_dup(void)
{
80105f49:	55                   	push   %ebp
80105f4a:	89 e5                	mov    %esp,%ebp
80105f4c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105f4f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f52:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f56:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f5d:	00 
80105f5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f65:	e8 1e ff ff ff       	call   80105e88 <argfd>
80105f6a:	85 c0                	test   %eax,%eax
80105f6c:	79 07                	jns    80105f75 <sys_dup+0x2c>
    return -1;
80105f6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f73:	eb 29                	jmp    80105f9e <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105f75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f78:	89 04 24             	mov    %eax,(%esp)
80105f7b:	e8 7d ff ff ff       	call   80105efd <fdalloc>
80105f80:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f87:	79 07                	jns    80105f90 <sys_dup+0x47>
    return -1;
80105f89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f8e:	eb 0e                	jmp    80105f9e <sys_dup+0x55>
  filedup(f);
80105f90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f93:	89 04 24             	mov    %eax,(%esp)
80105f96:	e8 e1 af ff ff       	call   80100f7c <filedup>
  return fd;
80105f9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105f9e:	c9                   	leave  
80105f9f:	c3                   	ret    

80105fa0 <sys_read>:

int
sys_read(void)
{
80105fa0:	55                   	push   %ebp
80105fa1:	89 e5                	mov    %esp,%ebp
80105fa3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105fa6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105fa9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105fb4:	00 
80105fb5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105fbc:	e8 c7 fe ff ff       	call   80105e88 <argfd>
80105fc1:	85 c0                	test   %eax,%eax
80105fc3:	78 35                	js     80105ffa <sys_read+0x5a>
80105fc5:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105fc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fcc:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105fd3:	e8 0e fd ff ff       	call   80105ce6 <argint>
80105fd8:	85 c0                	test   %eax,%eax
80105fda:	78 1e                	js     80105ffa <sys_read+0x5a>
80105fdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fdf:	89 44 24 08          	mov    %eax,0x8(%esp)
80105fe3:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105fe6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105fea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ff1:	e8 28 fd ff ff       	call   80105d1e <argptr>
80105ff6:	85 c0                	test   %eax,%eax
80105ff8:	79 07                	jns    80106001 <sys_read+0x61>
    return -1;
80105ffa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fff:	eb 19                	jmp    8010601a <sys_read+0x7a>
  return fileread(f, p, n);
80106001:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106004:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106007:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010600a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010600e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106012:	89 04 24             	mov    %eax,(%esp)
80106015:	e8 cf b0 ff ff       	call   801010e9 <fileread>
}
8010601a:	c9                   	leave  
8010601b:	c3                   	ret    

8010601c <sys_write>:

int
sys_write(void)
{
8010601c:	55                   	push   %ebp
8010601d:	89 e5                	mov    %esp,%ebp
8010601f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106022:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106025:	89 44 24 08          	mov    %eax,0x8(%esp)
80106029:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106030:	00 
80106031:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106038:	e8 4b fe ff ff       	call   80105e88 <argfd>
8010603d:	85 c0                	test   %eax,%eax
8010603f:	78 35                	js     80106076 <sys_write+0x5a>
80106041:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106044:	89 44 24 04          	mov    %eax,0x4(%esp)
80106048:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010604f:	e8 92 fc ff ff       	call   80105ce6 <argint>
80106054:	85 c0                	test   %eax,%eax
80106056:	78 1e                	js     80106076 <sys_write+0x5a>
80106058:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010605b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010605f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106062:	89 44 24 04          	mov    %eax,0x4(%esp)
80106066:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010606d:	e8 ac fc ff ff       	call   80105d1e <argptr>
80106072:	85 c0                	test   %eax,%eax
80106074:	79 07                	jns    8010607d <sys_write+0x61>
    return -1;
80106076:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010607b:	eb 19                	jmp    80106096 <sys_write+0x7a>
  return filewrite(f, p, n);
8010607d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106080:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106083:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106086:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010608a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010608e:	89 04 24             	mov    %eax,(%esp)
80106091:	e8 0f b1 ff ff       	call   801011a5 <filewrite>
}
80106096:	c9                   	leave  
80106097:	c3                   	ret    

80106098 <sys_close>:

int
sys_close(void)
{
80106098:	55                   	push   %ebp
80106099:	89 e5                	mov    %esp,%ebp
8010609b:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
8010609e:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060a1:	89 44 24 08          	mov    %eax,0x8(%esp)
801060a5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801060ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060b3:	e8 d0 fd ff ff       	call   80105e88 <argfd>
801060b8:	85 c0                	test   %eax,%eax
801060ba:	79 07                	jns    801060c3 <sys_close+0x2b>
    return -1;
801060bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060c1:	eb 24                	jmp    801060e7 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801060c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060cc:	83 c2 08             	add    $0x8,%edx
801060cf:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060d6:	00 
  fileclose(f);
801060d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060da:	89 04 24             	mov    %eax,(%esp)
801060dd:	e8 e2 ae ff ff       	call   80100fc4 <fileclose>
  return 0;
801060e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060e7:	c9                   	leave  
801060e8:	c3                   	ret    

801060e9 <sys_fstat>:

int
sys_fstat(void)
{
801060e9:	55                   	push   %ebp
801060ea:	89 e5                	mov    %esp,%ebp
801060ec:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801060ef:	8d 45 f4             	lea    -0xc(%ebp),%eax
801060f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801060f6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801060fd:	00 
801060fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106105:	e8 7e fd ff ff       	call   80105e88 <argfd>
8010610a:	85 c0                	test   %eax,%eax
8010610c:	78 1f                	js     8010612d <sys_fstat+0x44>
8010610e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106115:	00 
80106116:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106119:	89 44 24 04          	mov    %eax,0x4(%esp)
8010611d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106124:	e8 f5 fb ff ff       	call   80105d1e <argptr>
80106129:	85 c0                	test   %eax,%eax
8010612b:	79 07                	jns    80106134 <sys_fstat+0x4b>
    return -1;
8010612d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106132:	eb 12                	jmp    80106146 <sys_fstat+0x5d>
  return filestat(f, st);
80106134:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106137:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010613a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010613e:	89 04 24             	mov    %eax,(%esp)
80106141:	e8 54 af ff ff       	call   8010109a <filestat>
}
80106146:	c9                   	leave  
80106147:	c3                   	ret    

80106148 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106148:	55                   	push   %ebp
80106149:	89 e5                	mov    %esp,%ebp
8010614b:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010614e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106151:	89 44 24 04          	mov    %eax,0x4(%esp)
80106155:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010615c:	e8 1f fc ff ff       	call   80105d80 <argstr>
80106161:	85 c0                	test   %eax,%eax
80106163:	78 17                	js     8010617c <sys_link+0x34>
80106165:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106168:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106173:	e8 08 fc ff ff       	call   80105d80 <argstr>
80106178:	85 c0                	test   %eax,%eax
8010617a:	79 0a                	jns    80106186 <sys_link+0x3e>
    return -1;
8010617c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106181:	e9 3c 01 00 00       	jmp    801062c2 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80106186:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106189:	89 04 24             	mov    %eax,(%esp)
8010618c:	e8 f9 cc ff ff       	call   80102e8a <namei>
80106191:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106194:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106198:	75 0a                	jne    801061a4 <sys_link+0x5c>
    return -1;
8010619a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010619f:	e9 1e 01 00 00       	jmp    801062c2 <sys_link+0x17a>

  begin_trans();
801061a4:	e8 18 dc ff ff       	call   80103dc1 <begin_trans>

  ilock(ip);
801061a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ac:	89 04 24             	mov    %eax,(%esp)
801061af:	e8 34 c1 ff ff       	call   801022e8 <ilock>
  if(ip->type == T_DIR){
801061b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061bb:	66 83 f8 01          	cmp    $0x1,%ax
801061bf:	75 1a                	jne    801061db <sys_link+0x93>
    iunlockput(ip);
801061c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061c4:	89 04 24             	mov    %eax,(%esp)
801061c7:	e8 a0 c3 ff ff       	call   8010256c <iunlockput>
    commit_trans();
801061cc:	e8 39 dc ff ff       	call   80103e0a <commit_trans>
    return -1;
801061d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d6:	e9 e7 00 00 00       	jmp    801062c2 <sys_link+0x17a>
  }

  ip->nlink++;
801061db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061de:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801061e2:	8d 50 01             	lea    0x1(%eax),%edx
801061e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061e8:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801061ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ef:	89 04 24             	mov    %eax,(%esp)
801061f2:	e8 35 bf ff ff       	call   8010212c <iupdate>
  iunlock(ip);
801061f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061fa:	89 04 24             	mov    %eax,(%esp)
801061fd:	e8 34 c2 ff ff       	call   80102436 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106202:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106205:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106208:	89 54 24 04          	mov    %edx,0x4(%esp)
8010620c:	89 04 24             	mov    %eax,(%esp)
8010620f:	e8 98 cc ff ff       	call   80102eac <nameiparent>
80106214:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106217:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010621b:	74 68                	je     80106285 <sys_link+0x13d>
    goto bad;
  ilock(dp);
8010621d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106220:	89 04 24             	mov    %eax,(%esp)
80106223:	e8 c0 c0 ff ff       	call   801022e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106228:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010622b:	8b 10                	mov    (%eax),%edx
8010622d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106230:	8b 00                	mov    (%eax),%eax
80106232:	39 c2                	cmp    %eax,%edx
80106234:	75 20                	jne    80106256 <sys_link+0x10e>
80106236:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106239:	8b 40 04             	mov    0x4(%eax),%eax
8010623c:	89 44 24 08          	mov    %eax,0x8(%esp)
80106240:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106243:	89 44 24 04          	mov    %eax,0x4(%esp)
80106247:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010624a:	89 04 24             	mov    %eax,(%esp)
8010624d:	e8 77 c9 ff ff       	call   80102bc9 <dirlink>
80106252:	85 c0                	test   %eax,%eax
80106254:	79 0d                	jns    80106263 <sys_link+0x11b>
    iunlockput(dp);
80106256:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106259:	89 04 24             	mov    %eax,(%esp)
8010625c:	e8 0b c3 ff ff       	call   8010256c <iunlockput>
    goto bad;
80106261:	eb 23                	jmp    80106286 <sys_link+0x13e>
  }
  iunlockput(dp);
80106263:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106266:	89 04 24             	mov    %eax,(%esp)
80106269:	e8 fe c2 ff ff       	call   8010256c <iunlockput>
  iput(ip);
8010626e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106271:	89 04 24             	mov    %eax,(%esp)
80106274:	e8 22 c2 ff ff       	call   8010249b <iput>

  commit_trans();
80106279:	e8 8c db ff ff       	call   80103e0a <commit_trans>

  return 0;
8010627e:	b8 00 00 00 00       	mov    $0x0,%eax
80106283:	eb 3d                	jmp    801062c2 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106285:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106286:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106289:	89 04 24             	mov    %eax,(%esp)
8010628c:	e8 57 c0 ff ff       	call   801022e8 <ilock>
  ip->nlink--;
80106291:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106294:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106298:	8d 50 ff             	lea    -0x1(%eax),%edx
8010629b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010629e:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801062a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062a5:	89 04 24             	mov    %eax,(%esp)
801062a8:	e8 7f be ff ff       	call   8010212c <iupdate>
  iunlockput(ip);
801062ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b0:	89 04 24             	mov    %eax,(%esp)
801062b3:	e8 b4 c2 ff ff       	call   8010256c <iunlockput>
  commit_trans();
801062b8:	e8 4d db ff ff       	call   80103e0a <commit_trans>
  return -1;
801062bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801062c2:	c9                   	leave  
801062c3:	c3                   	ret    

801062c4 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801062c4:	55                   	push   %ebp
801062c5:	89 e5                	mov    %esp,%ebp
801062c7:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801062ca:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801062d1:	eb 4b                	jmp    8010631e <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801062d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062d6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801062dd:	00 
801062de:	89 44 24 08          	mov    %eax,0x8(%esp)
801062e2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801062e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801062e9:	8b 45 08             	mov    0x8(%ebp),%eax
801062ec:	89 04 24             	mov    %eax,(%esp)
801062ef:	e8 ea c4 ff ff       	call   801027de <readi>
801062f4:	83 f8 10             	cmp    $0x10,%eax
801062f7:	74 0c                	je     80106305 <isdirempty+0x41>
      panic("isdirempty: readi");
801062f9:	c7 04 24 6f 93 10 80 	movl   $0x8010936f,(%esp)
80106300:	e8 38 a2 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106305:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106309:	66 85 c0             	test   %ax,%ax
8010630c:	74 07                	je     80106315 <isdirempty+0x51>
      return 0;
8010630e:	b8 00 00 00 00       	mov    $0x0,%eax
80106313:	eb 1b                	jmp    80106330 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106318:	83 c0 10             	add    $0x10,%eax
8010631b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010631e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106321:	8b 45 08             	mov    0x8(%ebp),%eax
80106324:	8b 40 18             	mov    0x18(%eax),%eax
80106327:	39 c2                	cmp    %eax,%edx
80106329:	72 a8                	jb     801062d3 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010632b:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106330:	c9                   	leave  
80106331:	c3                   	ret    

80106332 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106332:	55                   	push   %ebp
80106333:	89 e5                	mov    %esp,%ebp
80106335:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106338:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010633b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010633f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106346:	e8 35 fa ff ff       	call   80105d80 <argstr>
8010634b:	85 c0                	test   %eax,%eax
8010634d:	79 0a                	jns    80106359 <sys_unlink+0x27>
    return -1;
8010634f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106354:	e9 aa 01 00 00       	jmp    80106503 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106359:	8b 45 cc             	mov    -0x34(%ebp),%eax
8010635c:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010635f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106363:	89 04 24             	mov    %eax,(%esp)
80106366:	e8 41 cb ff ff       	call   80102eac <nameiparent>
8010636b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010636e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106372:	75 0a                	jne    8010637e <sys_unlink+0x4c>
    return -1;
80106374:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106379:	e9 85 01 00 00       	jmp    80106503 <sys_unlink+0x1d1>

  begin_trans();
8010637e:	e8 3e da ff ff       	call   80103dc1 <begin_trans>

  ilock(dp);
80106383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106386:	89 04 24             	mov    %eax,(%esp)
80106389:	e8 5a bf ff ff       	call   801022e8 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010638e:	c7 44 24 04 81 93 10 	movl   $0x80109381,0x4(%esp)
80106395:	80 
80106396:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106399:	89 04 24             	mov    %eax,(%esp)
8010639c:	e8 3e c7 ff ff       	call   80102adf <namecmp>
801063a1:	85 c0                	test   %eax,%eax
801063a3:	0f 84 45 01 00 00    	je     801064ee <sys_unlink+0x1bc>
801063a9:	c7 44 24 04 83 93 10 	movl   $0x80109383,0x4(%esp)
801063b0:	80 
801063b1:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063b4:	89 04 24             	mov    %eax,(%esp)
801063b7:	e8 23 c7 ff ff       	call   80102adf <namecmp>
801063bc:	85 c0                	test   %eax,%eax
801063be:	0f 84 2a 01 00 00    	je     801064ee <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801063c4:	8d 45 c8             	lea    -0x38(%ebp),%eax
801063c7:	89 44 24 08          	mov    %eax,0x8(%esp)
801063cb:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801063ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801063d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d5:	89 04 24             	mov    %eax,(%esp)
801063d8:	e8 24 c7 ff ff       	call   80102b01 <dirlookup>
801063dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801063e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801063e4:	0f 84 03 01 00 00    	je     801064ed <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801063ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063ed:	89 04 24             	mov    %eax,(%esp)
801063f0:	e8 f3 be ff ff       	call   801022e8 <ilock>

  if(ip->nlink < 1)
801063f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063f8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801063fc:	66 85 c0             	test   %ax,%ax
801063ff:	7f 0c                	jg     8010640d <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106401:	c7 04 24 86 93 10 80 	movl   $0x80109386,(%esp)
80106408:	e8 30 a1 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010640d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106410:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106414:	66 83 f8 01          	cmp    $0x1,%ax
80106418:	75 1f                	jne    80106439 <sys_unlink+0x107>
8010641a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010641d:	89 04 24             	mov    %eax,(%esp)
80106420:	e8 9f fe ff ff       	call   801062c4 <isdirempty>
80106425:	85 c0                	test   %eax,%eax
80106427:	75 10                	jne    80106439 <sys_unlink+0x107>
    iunlockput(ip);
80106429:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010642c:	89 04 24             	mov    %eax,(%esp)
8010642f:	e8 38 c1 ff ff       	call   8010256c <iunlockput>
    goto bad;
80106434:	e9 b5 00 00 00       	jmp    801064ee <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106439:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106440:	00 
80106441:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106448:	00 
80106449:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010644c:	89 04 24             	mov    %eax,(%esp)
8010644f:	e8 42 f5 ff ff       	call   80105996 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106454:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106457:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010645e:	00 
8010645f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106463:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106466:	89 44 24 04          	mov    %eax,0x4(%esp)
8010646a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010646d:	89 04 24             	mov    %eax,(%esp)
80106470:	e8 d4 c4 ff ff       	call   80102949 <writei>
80106475:	83 f8 10             	cmp    $0x10,%eax
80106478:	74 0c                	je     80106486 <sys_unlink+0x154>
    panic("unlink: writei");
8010647a:	c7 04 24 98 93 10 80 	movl   $0x80109398,(%esp)
80106481:	e8 b7 a0 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106486:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106489:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010648d:	66 83 f8 01          	cmp    $0x1,%ax
80106491:	75 1c                	jne    801064af <sys_unlink+0x17d>
    dp->nlink--;
80106493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106496:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010649a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010649d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a0:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801064a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064a7:	89 04 24             	mov    %eax,(%esp)
801064aa:	e8 7d bc ff ff       	call   8010212c <iupdate>
  }
  iunlockput(dp);
801064af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b2:	89 04 24             	mov    %eax,(%esp)
801064b5:	e8 b2 c0 ff ff       	call   8010256c <iunlockput>

  ip->nlink--;
801064ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064bd:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064c1:	8d 50 ff             	lea    -0x1(%eax),%edx
801064c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064c7:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064ce:	89 04 24             	mov    %eax,(%esp)
801064d1:	e8 56 bc ff ff       	call   8010212c <iupdate>
  iunlockput(ip);
801064d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064d9:	89 04 24             	mov    %eax,(%esp)
801064dc:	e8 8b c0 ff ff       	call   8010256c <iunlockput>

  commit_trans();
801064e1:	e8 24 d9 ff ff       	call   80103e0a <commit_trans>

  return 0;
801064e6:	b8 00 00 00 00       	mov    $0x0,%eax
801064eb:	eb 16                	jmp    80106503 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801064ed:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801064ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f1:	89 04 24             	mov    %eax,(%esp)
801064f4:	e8 73 c0 ff ff       	call   8010256c <iunlockput>
  commit_trans();
801064f9:	e8 0c d9 ff ff       	call   80103e0a <commit_trans>
  return -1;
801064fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106503:	c9                   	leave  
80106504:	c3                   	ret    

80106505 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106505:	55                   	push   %ebp
80106506:	89 e5                	mov    %esp,%ebp
80106508:	83 ec 48             	sub    $0x48,%esp
8010650b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010650e:	8b 55 10             	mov    0x10(%ebp),%edx
80106511:	8b 45 14             	mov    0x14(%ebp),%eax
80106514:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106518:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
8010651c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106520:	8d 45 de             	lea    -0x22(%ebp),%eax
80106523:	89 44 24 04          	mov    %eax,0x4(%esp)
80106527:	8b 45 08             	mov    0x8(%ebp),%eax
8010652a:	89 04 24             	mov    %eax,(%esp)
8010652d:	e8 7a c9 ff ff       	call   80102eac <nameiparent>
80106532:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106535:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106539:	75 0a                	jne    80106545 <create+0x40>
    return 0;
8010653b:	b8 00 00 00 00       	mov    $0x0,%eax
80106540:	e9 7e 01 00 00       	jmp    801066c3 <create+0x1be>
  ilock(dp);
80106545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106548:	89 04 24             	mov    %eax,(%esp)
8010654b:	e8 98 bd ff ff       	call   801022e8 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106550:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106553:	89 44 24 08          	mov    %eax,0x8(%esp)
80106557:	8d 45 de             	lea    -0x22(%ebp),%eax
8010655a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010655e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106561:	89 04 24             	mov    %eax,(%esp)
80106564:	e8 98 c5 ff ff       	call   80102b01 <dirlookup>
80106569:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010656c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106570:	74 47                	je     801065b9 <create+0xb4>
    iunlockput(dp);
80106572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106575:	89 04 24             	mov    %eax,(%esp)
80106578:	e8 ef bf ff ff       	call   8010256c <iunlockput>
    ilock(ip);
8010657d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106580:	89 04 24             	mov    %eax,(%esp)
80106583:	e8 60 bd ff ff       	call   801022e8 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106588:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
8010658d:	75 15                	jne    801065a4 <create+0x9f>
8010658f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106592:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106596:	66 83 f8 02          	cmp    $0x2,%ax
8010659a:	75 08                	jne    801065a4 <create+0x9f>
      return ip;
8010659c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010659f:	e9 1f 01 00 00       	jmp    801066c3 <create+0x1be>
    iunlockput(ip);
801065a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065a7:	89 04 24             	mov    %eax,(%esp)
801065aa:	e8 bd bf ff ff       	call   8010256c <iunlockput>
    return 0;
801065af:	b8 00 00 00 00       	mov    $0x0,%eax
801065b4:	e9 0a 01 00 00       	jmp    801066c3 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801065b9:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801065bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c0:	8b 00                	mov    (%eax),%eax
801065c2:	89 54 24 04          	mov    %edx,0x4(%esp)
801065c6:	89 04 24             	mov    %eax,(%esp)
801065c9:	e8 81 ba ff ff       	call   8010204f <ialloc>
801065ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
801065d1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801065d5:	75 0c                	jne    801065e3 <create+0xde>
    panic("create: ialloc");
801065d7:	c7 04 24 a7 93 10 80 	movl   $0x801093a7,(%esp)
801065de:	e8 5a 9f ff ff       	call   8010053d <panic>

  ilock(ip);
801065e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065e6:	89 04 24             	mov    %eax,(%esp)
801065e9:	e8 fa bc ff ff       	call   801022e8 <ilock>
  ip->major = major;
801065ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065f1:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801065f5:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801065f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065fc:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106600:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106604:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106607:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
8010660d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106610:	89 04 24             	mov    %eax,(%esp)
80106613:	e8 14 bb ff ff       	call   8010212c <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106618:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010661d:	75 6a                	jne    80106689 <create+0x184>
    dp->nlink++;  // for ".."
8010661f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106622:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106626:	8d 50 01             	lea    0x1(%eax),%edx
80106629:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106633:	89 04 24             	mov    %eax,(%esp)
80106636:	e8 f1 ba ff ff       	call   8010212c <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010663b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010663e:	8b 40 04             	mov    0x4(%eax),%eax
80106641:	89 44 24 08          	mov    %eax,0x8(%esp)
80106645:	c7 44 24 04 81 93 10 	movl   $0x80109381,0x4(%esp)
8010664c:	80 
8010664d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106650:	89 04 24             	mov    %eax,(%esp)
80106653:	e8 71 c5 ff ff       	call   80102bc9 <dirlink>
80106658:	85 c0                	test   %eax,%eax
8010665a:	78 21                	js     8010667d <create+0x178>
8010665c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010665f:	8b 40 04             	mov    0x4(%eax),%eax
80106662:	89 44 24 08          	mov    %eax,0x8(%esp)
80106666:	c7 44 24 04 83 93 10 	movl   $0x80109383,0x4(%esp)
8010666d:	80 
8010666e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106671:	89 04 24             	mov    %eax,(%esp)
80106674:	e8 50 c5 ff ff       	call   80102bc9 <dirlink>
80106679:	85 c0                	test   %eax,%eax
8010667b:	79 0c                	jns    80106689 <create+0x184>
      panic("create dots");
8010667d:	c7 04 24 b6 93 10 80 	movl   $0x801093b6,(%esp)
80106684:	e8 b4 9e ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106689:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010668c:	8b 40 04             	mov    0x4(%eax),%eax
8010668f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106693:	8d 45 de             	lea    -0x22(%ebp),%eax
80106696:	89 44 24 04          	mov    %eax,0x4(%esp)
8010669a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010669d:	89 04 24             	mov    %eax,(%esp)
801066a0:	e8 24 c5 ff ff       	call   80102bc9 <dirlink>
801066a5:	85 c0                	test   %eax,%eax
801066a7:	79 0c                	jns    801066b5 <create+0x1b0>
    panic("create: dirlink");
801066a9:	c7 04 24 c2 93 10 80 	movl   $0x801093c2,(%esp)
801066b0:	e8 88 9e ff ff       	call   8010053d <panic>

  iunlockput(dp);
801066b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066b8:	89 04 24             	mov    %eax,(%esp)
801066bb:	e8 ac be ff ff       	call   8010256c <iunlockput>

  return ip;
801066c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801066c3:	c9                   	leave  
801066c4:	c3                   	ret    

801066c5 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
801066c5:	55                   	push   %ebp
801066c6:	89 e5                	mov    %esp,%ebp
801066c8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
801066cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801066ce:	25 00 02 00 00       	and    $0x200,%eax
801066d3:	85 c0                	test   %eax,%eax
801066d5:	74 40                	je     80106717 <fileopen+0x52>
    begin_trans();
801066d7:	e8 e5 d6 ff ff       	call   80103dc1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801066dc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801066e3:	00 
801066e4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801066eb:	00 
801066ec:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801066f3:	00 
801066f4:	8b 45 08             	mov    0x8(%ebp),%eax
801066f7:	89 04 24             	mov    %eax,(%esp)
801066fa:	e8 06 fe ff ff       	call   80106505 <create>
801066ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106702:	e8 03 d7 ff ff       	call   80103e0a <commit_trans>
    if(ip == 0)
80106707:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010670b:	75 5b                	jne    80106768 <fileopen+0xa3>
      return 0;
8010670d:	b8 00 00 00 00       	mov    $0x0,%eax
80106712:	e9 e5 00 00 00       	jmp    801067fc <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106717:	8b 45 08             	mov    0x8(%ebp),%eax
8010671a:	89 04 24             	mov    %eax,(%esp)
8010671d:	e8 68 c7 ff ff       	call   80102e8a <namei>
80106722:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106725:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106729:	75 0a                	jne    80106735 <fileopen+0x70>
      return 0;
8010672b:	b8 00 00 00 00       	mov    $0x0,%eax
80106730:	e9 c7 00 00 00       	jmp    801067fc <fileopen+0x137>
    ilock(ip);
80106735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106738:	89 04 24             	mov    %eax,(%esp)
8010673b:	e8 a8 bb ff ff       	call   801022e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106743:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106747:	66 83 f8 01          	cmp    $0x1,%ax
8010674b:	75 1b                	jne    80106768 <fileopen+0xa3>
8010674d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106751:	74 15                	je     80106768 <fileopen+0xa3>
      iunlockput(ip);
80106753:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106756:	89 04 24             	mov    %eax,(%esp)
80106759:	e8 0e be ff ff       	call   8010256c <iunlockput>
      return 0;
8010675e:	b8 00 00 00 00       	mov    $0x0,%eax
80106763:	e9 94 00 00 00       	jmp    801067fc <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106768:	e8 af a7 ff ff       	call   80100f1c <filealloc>
8010676d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106770:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106774:	75 23                	jne    80106799 <fileopen+0xd4>
    if(f)
80106776:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010677a:	74 0b                	je     80106787 <fileopen+0xc2>
      fileclose(f);
8010677c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010677f:	89 04 24             	mov    %eax,(%esp)
80106782:	e8 3d a8 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106787:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010678a:	89 04 24             	mov    %eax,(%esp)
8010678d:	e8 da bd ff ff       	call   8010256c <iunlockput>
    return 0;
80106792:	b8 00 00 00 00       	mov    $0x0,%eax
80106797:	eb 63                	jmp    801067fc <fileopen+0x137>
  }
  iunlock(ip);
80106799:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679c:	89 04 24             	mov    %eax,(%esp)
8010679f:	e8 92 bc ff ff       	call   80102436 <iunlock>

  f->type = FD_INODE;
801067a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067a7:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801067ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067b3:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801067b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067b9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801067c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801067c3:	83 e0 01             	and    $0x1,%eax
801067c6:	85 c0                	test   %eax,%eax
801067c8:	0f 94 c2             	sete   %dl
801067cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067ce:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801067d1:	8b 45 0c             	mov    0xc(%ebp),%eax
801067d4:	83 e0 01             	and    $0x1,%eax
801067d7:	84 c0                	test   %al,%al
801067d9:	75 0a                	jne    801067e5 <fileopen+0x120>
801067db:	8b 45 0c             	mov    0xc(%ebp),%eax
801067de:	83 e0 02             	and    $0x2,%eax
801067e1:	85 c0                	test   %eax,%eax
801067e3:	74 07                	je     801067ec <fileopen+0x127>
801067e5:	b8 01 00 00 00       	mov    $0x1,%eax
801067ea:	eb 05                	jmp    801067f1 <fileopen+0x12c>
801067ec:	b8 00 00 00 00       	mov    $0x0,%eax
801067f1:	89 c2                	mov    %eax,%edx
801067f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067f6:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
801067f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801067fc:	c9                   	leave  
801067fd:	c3                   	ret    

801067fe <sys_open>:

int
sys_open(void)
{
801067fe:	55                   	push   %ebp
801067ff:	89 e5                	mov    %esp,%ebp
80106801:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106804:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106807:	89 44 24 04          	mov    %eax,0x4(%esp)
8010680b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106812:	e8 69 f5 ff ff       	call   80105d80 <argstr>
80106817:	85 c0                	test   %eax,%eax
80106819:	78 17                	js     80106832 <sys_open+0x34>
8010681b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010681e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106822:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106829:	e8 b8 f4 ff ff       	call   80105ce6 <argint>
8010682e:	85 c0                	test   %eax,%eax
80106830:	79 0a                	jns    8010683c <sys_open+0x3e>
    return -1;
80106832:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106837:	e9 46 01 00 00       	jmp    80106982 <sys_open+0x184>
  if(omode & O_CREATE){
8010683c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010683f:	25 00 02 00 00       	and    $0x200,%eax
80106844:	85 c0                	test   %eax,%eax
80106846:	74 40                	je     80106888 <sys_open+0x8a>
    begin_trans();
80106848:	e8 74 d5 ff ff       	call   80103dc1 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
8010684d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106850:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106857:	00 
80106858:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010685f:	00 
80106860:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106867:	00 
80106868:	89 04 24             	mov    %eax,(%esp)
8010686b:	e8 95 fc ff ff       	call   80106505 <create>
80106870:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106873:	e8 92 d5 ff ff       	call   80103e0a <commit_trans>
    if(ip == 0)
80106878:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010687c:	75 5c                	jne    801068da <sys_open+0xdc>
      return -1;
8010687e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106883:	e9 fa 00 00 00       	jmp    80106982 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106888:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010688b:	89 04 24             	mov    %eax,(%esp)
8010688e:	e8 f7 c5 ff ff       	call   80102e8a <namei>
80106893:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106896:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010689a:	75 0a                	jne    801068a6 <sys_open+0xa8>
      return -1;
8010689c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068a1:	e9 dc 00 00 00       	jmp    80106982 <sys_open+0x184>
    ilock(ip);
801068a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068a9:	89 04 24             	mov    %eax,(%esp)
801068ac:	e8 37 ba ff ff       	call   801022e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801068b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068b8:	66 83 f8 01          	cmp    $0x1,%ax
801068bc:	75 1c                	jne    801068da <sys_open+0xdc>
801068be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801068c1:	85 c0                	test   %eax,%eax
801068c3:	74 15                	je     801068da <sys_open+0xdc>
      iunlockput(ip);
801068c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c8:	89 04 24             	mov    %eax,(%esp)
801068cb:	e8 9c bc ff ff       	call   8010256c <iunlockput>
      return -1;
801068d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068d5:	e9 a8 00 00 00       	jmp    80106982 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801068da:	e8 3d a6 ff ff       	call   80100f1c <filealloc>
801068df:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068e2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068e6:	74 14                	je     801068fc <sys_open+0xfe>
801068e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068eb:	89 04 24             	mov    %eax,(%esp)
801068ee:	e8 0a f6 ff ff       	call   80105efd <fdalloc>
801068f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
801068f6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801068fa:	79 23                	jns    8010691f <sys_open+0x121>
    if(f)
801068fc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106900:	74 0b                	je     8010690d <sys_open+0x10f>
      fileclose(f);
80106902:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106905:	89 04 24             	mov    %eax,(%esp)
80106908:	e8 b7 a6 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
8010690d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106910:	89 04 24             	mov    %eax,(%esp)
80106913:	e8 54 bc ff ff       	call   8010256c <iunlockput>
    return -1;
80106918:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010691d:	eb 63                	jmp    80106982 <sys_open+0x184>
  }
  iunlock(ip);
8010691f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106922:	89 04 24             	mov    %eax,(%esp)
80106925:	e8 0c bb ff ff       	call   80102436 <iunlock>

  f->type = FD_INODE;
8010692a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106933:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106936:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106939:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010693c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010693f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106946:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106949:	83 e0 01             	and    $0x1,%eax
8010694c:	85 c0                	test   %eax,%eax
8010694e:	0f 94 c2             	sete   %dl
80106951:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106954:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106957:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010695a:	83 e0 01             	and    $0x1,%eax
8010695d:	84 c0                	test   %al,%al
8010695f:	75 0a                	jne    8010696b <sys_open+0x16d>
80106961:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106964:	83 e0 02             	and    $0x2,%eax
80106967:	85 c0                	test   %eax,%eax
80106969:	74 07                	je     80106972 <sys_open+0x174>
8010696b:	b8 01 00 00 00       	mov    $0x1,%eax
80106970:	eb 05                	jmp    80106977 <sys_open+0x179>
80106972:	b8 00 00 00 00       	mov    $0x0,%eax
80106977:	89 c2                	mov    %eax,%edx
80106979:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010697c:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010697f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106982:	c9                   	leave  
80106983:	c3                   	ret    

80106984 <sys_mkdir>:

int
sys_mkdir(void)
{
80106984:	55                   	push   %ebp
80106985:	89 e5                	mov    %esp,%ebp
80106987:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
8010698a:	e8 32 d4 ff ff       	call   80103dc1 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010698f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106992:	89 44 24 04          	mov    %eax,0x4(%esp)
80106996:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010699d:	e8 de f3 ff ff       	call   80105d80 <argstr>
801069a2:	85 c0                	test   %eax,%eax
801069a4:	78 2c                	js     801069d2 <sys_mkdir+0x4e>
801069a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069a9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801069b0:	00 
801069b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069b8:	00 
801069b9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801069c0:	00 
801069c1:	89 04 24             	mov    %eax,(%esp)
801069c4:	e8 3c fb ff ff       	call   80106505 <create>
801069c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069d0:	75 0c                	jne    801069de <sys_mkdir+0x5a>
    commit_trans();
801069d2:	e8 33 d4 ff ff       	call   80103e0a <commit_trans>
    return -1;
801069d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069dc:	eb 15                	jmp    801069f3 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801069de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069e1:	89 04 24             	mov    %eax,(%esp)
801069e4:	e8 83 bb ff ff       	call   8010256c <iunlockput>
  commit_trans();
801069e9:	e8 1c d4 ff ff       	call   80103e0a <commit_trans>
  return 0;
801069ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069f3:	c9                   	leave  
801069f4:	c3                   	ret    

801069f5 <sys_mknod>:

int
sys_mknod(void)
{
801069f5:	55                   	push   %ebp
801069f6:	89 e5                	mov    %esp,%ebp
801069f8:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801069fb:	e8 c1 d3 ff ff       	call   80103dc1 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80106a00:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106a03:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a0e:	e8 6d f3 ff ff       	call   80105d80 <argstr>
80106a13:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a16:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a1a:	78 5e                	js     80106a7a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106a1c:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106a1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a23:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106a2a:	e8 b7 f2 ff ff       	call   80105ce6 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106a2f:	85 c0                	test   %eax,%eax
80106a31:	78 47                	js     80106a7a <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106a33:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106a36:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a3a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106a41:	e8 a0 f2 ff ff       	call   80105ce6 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106a46:	85 c0                	test   %eax,%eax
80106a48:	78 30                	js     80106a7a <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106a4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106a4d:	0f bf c8             	movswl %ax,%ecx
80106a50:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106a53:	0f bf d0             	movswl %ax,%edx
80106a56:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106a59:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a5d:	89 54 24 08          	mov    %edx,0x8(%esp)
80106a61:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106a68:	00 
80106a69:	89 04 24             	mov    %eax,(%esp)
80106a6c:	e8 94 fa ff ff       	call   80106505 <create>
80106a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a78:	75 0c                	jne    80106a86 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106a7a:	e8 8b d3 ff ff       	call   80103e0a <commit_trans>
    return -1;
80106a7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a84:	eb 15                	jmp    80106a9b <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106a86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a89:	89 04 24             	mov    %eax,(%esp)
80106a8c:	e8 db ba ff ff       	call   8010256c <iunlockput>
  commit_trans();
80106a91:	e8 74 d3 ff ff       	call   80103e0a <commit_trans>
  return 0;
80106a96:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106a9b:	c9                   	leave  
80106a9c:	c3                   	ret    

80106a9d <sys_chdir>:

int
sys_chdir(void)
{
80106a9d:	55                   	push   %ebp
80106a9e:	89 e5                	mov    %esp,%ebp
80106aa0:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106aa3:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106aa6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106aaa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ab1:	e8 ca f2 ff ff       	call   80105d80 <argstr>
80106ab6:	85 c0                	test   %eax,%eax
80106ab8:	78 14                	js     80106ace <sys_chdir+0x31>
80106aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106abd:	89 04 24             	mov    %eax,(%esp)
80106ac0:	e8 c5 c3 ff ff       	call   80102e8a <namei>
80106ac5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ac8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106acc:	75 07                	jne    80106ad5 <sys_chdir+0x38>
    return -1;
80106ace:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ad3:	eb 57                	jmp    80106b2c <sys_chdir+0x8f>
  ilock(ip);
80106ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad8:	89 04 24             	mov    %eax,(%esp)
80106adb:	e8 08 b8 ff ff       	call   801022e8 <ilock>
  if(ip->type != T_DIR){
80106ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ae3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106ae7:	66 83 f8 01          	cmp    $0x1,%ax
80106aeb:	74 12                	je     80106aff <sys_chdir+0x62>
    iunlockput(ip);
80106aed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106af0:	89 04 24             	mov    %eax,(%esp)
80106af3:	e8 74 ba ff ff       	call   8010256c <iunlockput>
    return -1;
80106af8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106afd:	eb 2d                	jmp    80106b2c <sys_chdir+0x8f>
  }
  iunlock(ip);
80106aff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b02:	89 04 24             	mov    %eax,(%esp)
80106b05:	e8 2c b9 ff ff       	call   80102436 <iunlock>
  iput(proc->cwd);
80106b0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b10:	8b 40 68             	mov    0x68(%eax),%eax
80106b13:	89 04 24             	mov    %eax,(%esp)
80106b16:	e8 80 b9 ff ff       	call   8010249b <iput>
  proc->cwd = ip;
80106b1b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b21:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106b24:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106b27:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106b2c:	c9                   	leave  
80106b2d:	c3                   	ret    

80106b2e <sys_exec>:

int
sys_exec(void)
{
80106b2e:	55                   	push   %ebp
80106b2f:	89 e5                	mov    %esp,%ebp
80106b31:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106b37:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106b3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b3e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b45:	e8 36 f2 ff ff       	call   80105d80 <argstr>
80106b4a:	85 c0                	test   %eax,%eax
80106b4c:	78 1a                	js     80106b68 <sys_exec+0x3a>
80106b4e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106b54:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b58:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b5f:	e8 82 f1 ff ff       	call   80105ce6 <argint>
80106b64:	85 c0                	test   %eax,%eax
80106b66:	79 0a                	jns    80106b72 <sys_exec+0x44>
    return -1;
80106b68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b6d:	e9 e2 00 00 00       	jmp    80106c54 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106b72:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106b79:	00 
80106b7a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b81:	00 
80106b82:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106b88:	89 04 24             	mov    %eax,(%esp)
80106b8b:	e8 06 ee ff ff       	call   80105996 <memset>
  for(i=0;; i++){
80106b90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b9a:	83 f8 1f             	cmp    $0x1f,%eax
80106b9d:	76 0a                	jbe    80106ba9 <sys_exec+0x7b>
      return -1;
80106b9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba4:	e9 ab 00 00 00       	jmp    80106c54 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106ba9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bac:	c1 e0 02             	shl    $0x2,%eax
80106baf:	89 c2                	mov    %eax,%edx
80106bb1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106bb7:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106bba:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106bc0:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106bc6:	89 54 24 08          	mov    %edx,0x8(%esp)
80106bca:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106bce:	89 04 24             	mov    %eax,(%esp)
80106bd1:	e8 7e f0 ff ff       	call   80105c54 <fetchint>
80106bd6:	85 c0                	test   %eax,%eax
80106bd8:	79 07                	jns    80106be1 <sys_exec+0xb3>
      return -1;
80106bda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bdf:	eb 73                	jmp    80106c54 <sys_exec+0x126>
    if(uarg == 0){
80106be1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106be7:	85 c0                	test   %eax,%eax
80106be9:	75 26                	jne    80106c11 <sys_exec+0xe3>
      argv[i] = 0;
80106beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bee:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106bf5:	00 00 00 00 
      break;
80106bf9:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106bfa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bfd:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106c03:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c07:	89 04 24             	mov    %eax,(%esp)
80106c0a:	e8 ed 9e ff ff       	call   80100afc <exec>
80106c0f:	eb 43                	jmp    80106c54 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c14:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106c1b:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106c21:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106c24:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106c2a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c30:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106c34:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c38:	89 04 24             	mov    %eax,(%esp)
80106c3b:	e8 48 f0 ff ff       	call   80105c88 <fetchstr>
80106c40:	85 c0                	test   %eax,%eax
80106c42:	79 07                	jns    80106c4b <sys_exec+0x11d>
      return -1;
80106c44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c49:	eb 09                	jmp    80106c54 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106c4b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106c4f:	e9 43 ff ff ff       	jmp    80106b97 <sys_exec+0x69>
  return exec(path, argv);
}
80106c54:	c9                   	leave  
80106c55:	c3                   	ret    

80106c56 <sys_pipe>:

int
sys_pipe(void)
{
80106c56:	55                   	push   %ebp
80106c57:	89 e5                	mov    %esp,%ebp
80106c59:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106c5c:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106c63:	00 
80106c64:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c67:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c6b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106c72:	e8 a7 f0 ff ff       	call   80105d1e <argptr>
80106c77:	85 c0                	test   %eax,%eax
80106c79:	79 0a                	jns    80106c85 <sys_pipe+0x2f>
    return -1;
80106c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c80:	e9 9b 00 00 00       	jmp    80106d20 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106c85:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106c88:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c8c:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106c8f:	89 04 24             	mov    %eax,(%esp)
80106c92:	e8 45 db ff ff       	call   801047dc <pipealloc>
80106c97:	85 c0                	test   %eax,%eax
80106c99:	79 07                	jns    80106ca2 <sys_pipe+0x4c>
    return -1;
80106c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ca0:	eb 7e                	jmp    80106d20 <sys_pipe+0xca>
  fd0 = -1;
80106ca2:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106ca9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106cac:	89 04 24             	mov    %eax,(%esp)
80106caf:	e8 49 f2 ff ff       	call   80105efd <fdalloc>
80106cb4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cb7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cbb:	78 14                	js     80106cd1 <sys_pipe+0x7b>
80106cbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106cc0:	89 04 24             	mov    %eax,(%esp)
80106cc3:	e8 35 f2 ff ff       	call   80105efd <fdalloc>
80106cc8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ccb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ccf:	79 37                	jns    80106d08 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106cd1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cd5:	78 14                	js     80106ceb <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106cd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cdd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ce0:	83 c2 08             	add    $0x8,%edx
80106ce3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106cea:	00 
    fileclose(rf);
80106ceb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106cee:	89 04 24             	mov    %eax,(%esp)
80106cf1:	e8 ce a2 ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80106cf6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106cf9:	89 04 24             	mov    %eax,(%esp)
80106cfc:	e8 c3 a2 ff ff       	call   80100fc4 <fileclose>
    return -1;
80106d01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d06:	eb 18                	jmp    80106d20 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106d08:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106d0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106d0e:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80106d10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106d13:	8d 50 04             	lea    0x4(%eax),%edx
80106d16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d19:	89 02                	mov    %eax,(%edx)
  return 0;
80106d1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d20:	c9                   	leave  
80106d21:	c3                   	ret    
	...

80106d24 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106d24:	55                   	push   %ebp
80106d25:	89 e5                	mov    %esp,%ebp
80106d27:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106d2a:	e8 67 e1 ff ff       	call   80104e96 <fork>
}
80106d2f:	c9                   	leave  
80106d30:	c3                   	ret    

80106d31 <sys_exit>:

int
sys_exit(void)
{
80106d31:	55                   	push   %ebp
80106d32:	89 e5                	mov    %esp,%ebp
80106d34:	83 ec 08             	sub    $0x8,%esp
  exit();
80106d37:	e8 bd e2 ff ff       	call   80104ff9 <exit>
  return 0;  // not reached
80106d3c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d41:	c9                   	leave  
80106d42:	c3                   	ret    

80106d43 <sys_wait>:

int
sys_wait(void)
{
80106d43:	55                   	push   %ebp
80106d44:	89 e5                	mov    %esp,%ebp
80106d46:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106d49:	e8 c3 e3 ff ff       	call   80105111 <wait>
}
80106d4e:	c9                   	leave  
80106d4f:	c3                   	ret    

80106d50 <sys_kill>:

int
sys_kill(void)
{
80106d50:	55                   	push   %ebp
80106d51:	89 e5                	mov    %esp,%ebp
80106d53:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106d56:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106d59:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d5d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d64:	e8 7d ef ff ff       	call   80105ce6 <argint>
80106d69:	85 c0                	test   %eax,%eax
80106d6b:	79 07                	jns    80106d74 <sys_kill+0x24>
    return -1;
80106d6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d72:	eb 0b                	jmp    80106d7f <sys_kill+0x2f>
  return kill(pid);
80106d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d77:	89 04 24             	mov    %eax,(%esp)
80106d7a:	e8 ee e7 ff ff       	call   8010556d <kill>
}
80106d7f:	c9                   	leave  
80106d80:	c3                   	ret    

80106d81 <sys_getpid>:

int
sys_getpid(void)
{
80106d81:	55                   	push   %ebp
80106d82:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106d84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d8a:	8b 40 10             	mov    0x10(%eax),%eax
}
80106d8d:	5d                   	pop    %ebp
80106d8e:	c3                   	ret    

80106d8f <sys_sbrk>:

int
sys_sbrk(void)
{
80106d8f:	55                   	push   %ebp
80106d90:	89 e5                	mov    %esp,%ebp
80106d92:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106d95:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106d98:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d9c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106da3:	e8 3e ef ff ff       	call   80105ce6 <argint>
80106da8:	85 c0                	test   %eax,%eax
80106daa:	79 07                	jns    80106db3 <sys_sbrk+0x24>
    return -1;
80106dac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106db1:	eb 24                	jmp    80106dd7 <sys_sbrk+0x48>
  addr = proc->sz;
80106db3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106db9:	8b 00                	mov    (%eax),%eax
80106dbb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106dbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dc1:	89 04 24             	mov    %eax,(%esp)
80106dc4:	e8 28 e0 ff ff       	call   80104df1 <growproc>
80106dc9:	85 c0                	test   %eax,%eax
80106dcb:	79 07                	jns    80106dd4 <sys_sbrk+0x45>
    return -1;
80106dcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dd2:	eb 03                	jmp    80106dd7 <sys_sbrk+0x48>
  return addr;
80106dd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106dd7:	c9                   	leave  
80106dd8:	c3                   	ret    

80106dd9 <sys_sleep>:

int
sys_sleep(void)
{
80106dd9:	55                   	push   %ebp
80106dda:	89 e5                	mov    %esp,%ebp
80106ddc:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80106ddf:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106de2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106de6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ded:	e8 f4 ee ff ff       	call   80105ce6 <argint>
80106df2:	85 c0                	test   %eax,%eax
80106df4:	79 07                	jns    80106dfd <sys_sleep+0x24>
    return -1;
80106df6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dfb:	eb 6c                	jmp    80106e69 <sys_sleep+0x90>
  acquire(&tickslock);
80106dfd:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106e04:	e8 3e e9 ff ff       	call   80105747 <acquire>
  ticks0 = ticks;
80106e09:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106e0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106e11:	eb 34                	jmp    80106e47 <sys_sleep+0x6e>
    if(proc->killed){
80106e13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e19:	8b 40 24             	mov    0x24(%eax),%eax
80106e1c:	85 c0                	test   %eax,%eax
80106e1e:	74 13                	je     80106e33 <sys_sleep+0x5a>
      release(&tickslock);
80106e20:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106e27:	e8 7d e9 ff ff       	call   801057a9 <release>
      return -1;
80106e2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e31:	eb 36                	jmp    80106e69 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106e33:	c7 44 24 04 80 2e 11 	movl   $0x80112e80,0x4(%esp)
80106e3a:	80 
80106e3b:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80106e42:	e8 22 e6 ff ff       	call   80105469 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106e47:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106e4c:	89 c2                	mov    %eax,%edx
80106e4e:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106e51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e54:	39 c2                	cmp    %eax,%edx
80106e56:	72 bb                	jb     80106e13 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106e58:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106e5f:	e8 45 e9 ff ff       	call   801057a9 <release>
  return 0;
80106e64:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e69:	c9                   	leave  
80106e6a:	c3                   	ret    

80106e6b <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106e6b:	55                   	push   %ebp
80106e6c:	89 e5                	mov    %esp,%ebp
80106e6e:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106e71:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106e78:	e8 ca e8 ff ff       	call   80105747 <acquire>
  xticks = ticks;
80106e7d:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80106e82:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106e85:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80106e8c:	e8 18 e9 ff ff       	call   801057a9 <release>
  return xticks;
80106e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106e94:	c9                   	leave  
80106e95:	c3                   	ret    

80106e96 <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
80106e96:	55                   	push   %ebp
80106e97:	89 e5                	mov    %esp,%ebp
80106e99:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
80106e9c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106e9f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ea3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106eaa:	e8 d1 ee ff ff       	call   80105d80 <argstr>
80106eaf:	85 c0                	test   %eax,%eax
80106eb1:	79 07                	jns    80106eba <sys_getFileBlocks+0x24>
    return -1;
80106eb3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eb8:	eb 0b                	jmp    80106ec5 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
80106eba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ebd:	89 04 24             	mov    %eax,(%esp)
80106ec0:	e8 25 a4 ff ff       	call   801012ea <getFileBlocks>
}
80106ec5:	c9                   	leave  
80106ec6:	c3                   	ret    

80106ec7 <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
80106ec7:	55                   	push   %ebp
80106ec8:	89 e5                	mov    %esp,%ebp
80106eca:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
80106ecd:	e8 75 a5 ff ff       	call   80101447 <getFreeBlocks>
}
80106ed2:	c9                   	leave  
80106ed3:	c3                   	ret    

80106ed4 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
80106ed4:	55                   	push   %ebp
80106ed5:	89 e5                	mov    %esp,%ebp
  return 0;
80106ed7:	b8 00 00 00 00       	mov    $0x0,%eax
  
}
80106edc:	5d                   	pop    %ebp
80106edd:	c3                   	ret    

80106ede <sys_dedup>:

int
sys_dedup(void)
{
80106ede:	55                   	push   %ebp
80106edf:	89 e5                	mov    %esp,%ebp
80106ee1:	83 ec 08             	sub    $0x8,%esp
  return dedup();
80106ee4:	e8 4c a7 ff ff       	call   80101635 <dedup>
}
80106ee9:	c9                   	leave  
80106eea:	c3                   	ret    
	...

80106eec <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106eec:	55                   	push   %ebp
80106eed:	89 e5                	mov    %esp,%ebp
80106eef:	83 ec 08             	sub    $0x8,%esp
80106ef2:	8b 55 08             	mov    0x8(%ebp),%edx
80106ef5:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ef8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106efc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106eff:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106f03:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106f07:	ee                   	out    %al,(%dx)
}
80106f08:	c9                   	leave  
80106f09:	c3                   	ret    

80106f0a <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106f0a:	55                   	push   %ebp
80106f0b:	89 e5                	mov    %esp,%ebp
80106f0d:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106f10:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106f17:	00 
80106f18:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106f1f:	e8 c8 ff ff ff       	call   80106eec <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106f24:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106f2b:	00 
80106f2c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106f33:	e8 b4 ff ff ff       	call   80106eec <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106f38:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106f3f:	00 
80106f40:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106f47:	e8 a0 ff ff ff       	call   80106eec <outb>
  picenable(IRQ_TIMER);
80106f4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f53:	e8 0d d7 ff ff       	call   80104665 <picenable>
}
80106f58:	c9                   	leave  
80106f59:	c3                   	ret    
	...

80106f5c <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106f5c:	1e                   	push   %ds
  pushl %es
80106f5d:	06                   	push   %es
  pushl %fs
80106f5e:	0f a0                	push   %fs
  pushl %gs
80106f60:	0f a8                	push   %gs
  pushal
80106f62:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80106f63:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106f67:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106f69:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106f6b:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80106f6f:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80106f71:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80106f73:	54                   	push   %esp
  call trap
80106f74:	e8 de 01 00 00       	call   80107157 <trap>
  addl $4, %esp
80106f79:	83 c4 04             	add    $0x4,%esp

80106f7c <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106f7c:	61                   	popa   
  popl %gs
80106f7d:	0f a9                	pop    %gs
  popl %fs
80106f7f:	0f a1                	pop    %fs
  popl %es
80106f81:	07                   	pop    %es
  popl %ds
80106f82:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106f83:	83 c4 08             	add    $0x8,%esp
  iret
80106f86:	cf                   	iret   
	...

80106f88 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106f88:	55                   	push   %ebp
80106f89:	89 e5                	mov    %esp,%ebp
80106f8b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106f8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106f91:	83 e8 01             	sub    $0x1,%eax
80106f94:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106f98:	8b 45 08             	mov    0x8(%ebp),%eax
80106f9b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106f9f:	8b 45 08             	mov    0x8(%ebp),%eax
80106fa2:	c1 e8 10             	shr    $0x10,%eax
80106fa5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106fa9:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106fac:	0f 01 18             	lidtl  (%eax)
}
80106faf:	c9                   	leave  
80106fb0:	c3                   	ret    

80106fb1 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106fb1:	55                   	push   %ebp
80106fb2:	89 e5                	mov    %esp,%ebp
80106fb4:	53                   	push   %ebx
80106fb5:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106fb8:	0f 20 d3             	mov    %cr2,%ebx
80106fbb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106fbe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106fc1:	83 c4 10             	add    $0x10,%esp
80106fc4:	5b                   	pop    %ebx
80106fc5:	5d                   	pop    %ebp
80106fc6:	c3                   	ret    

80106fc7 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106fc7:	55                   	push   %ebp
80106fc8:	89 e5                	mov    %esp,%ebp
80106fca:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106fcd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106fd4:	e9 c3 00 00 00       	jmp    8010709c <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fdc:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80106fe3:	89 c2                	mov    %eax,%edx
80106fe5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fe8:	66 89 14 c5 c0 2e 11 	mov    %dx,-0x7feed140(,%eax,8)
80106fef:	80 
80106ff0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ff3:	66 c7 04 c5 c2 2e 11 	movw   $0x8,-0x7feed13e(,%eax,8)
80106ffa:	80 08 00 
80106ffd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107000:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80107007:	80 
80107008:	83 e2 e0             	and    $0xffffffe0,%edx
8010700b:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80107012:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107015:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
8010701c:	80 
8010701d:	83 e2 1f             	and    $0x1f,%edx
80107020:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80107027:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010702a:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107031:	80 
80107032:	83 e2 f0             	and    $0xfffffff0,%edx
80107035:	83 ca 0e             	or     $0xe,%edx
80107038:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
8010703f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107042:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107049:	80 
8010704a:	83 e2 ef             	and    $0xffffffef,%edx
8010704d:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107054:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107057:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
8010705e:	80 
8010705f:	83 e2 9f             	and    $0xffffff9f,%edx
80107062:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107069:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010706c:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107073:	80 
80107074:	83 ca 80             	or     $0xffffff80,%edx
80107077:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
8010707e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107081:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80107088:	c1 e8 10             	shr    $0x10,%eax
8010708b:	89 c2                	mov    %eax,%edx
8010708d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107090:	66 89 14 c5 c6 2e 11 	mov    %dx,-0x7feed13a(,%eax,8)
80107097:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80107098:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010709c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801070a3:	0f 8e 30 ff ff ff    	jle    80106fd9 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801070a9:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
801070ae:	66 a3 c0 30 11 80    	mov    %ax,0x801130c0
801070b4:	66 c7 05 c2 30 11 80 	movw   $0x8,0x801130c2
801070bb:	08 00 
801070bd:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801070c4:	83 e0 e0             	and    $0xffffffe0,%eax
801070c7:	a2 c4 30 11 80       	mov    %al,0x801130c4
801070cc:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801070d3:	83 e0 1f             	and    $0x1f,%eax
801070d6:	a2 c4 30 11 80       	mov    %al,0x801130c4
801070db:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801070e2:	83 c8 0f             	or     $0xf,%eax
801070e5:	a2 c5 30 11 80       	mov    %al,0x801130c5
801070ea:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801070f1:	83 e0 ef             	and    $0xffffffef,%eax
801070f4:	a2 c5 30 11 80       	mov    %al,0x801130c5
801070f9:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80107100:	83 c8 60             	or     $0x60,%eax
80107103:	a2 c5 30 11 80       	mov    %al,0x801130c5
80107108:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
8010710f:	83 c8 80             	or     $0xffffff80,%eax
80107112:	a2 c5 30 11 80       	mov    %al,0x801130c5
80107117:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
8010711c:	c1 e8 10             	shr    $0x10,%eax
8010711f:	66 a3 c6 30 11 80    	mov    %ax,0x801130c6
  
  initlock(&tickslock, "time");
80107125:	c7 44 24 04 d4 93 10 	movl   $0x801093d4,0x4(%esp)
8010712c:	80 
8010712d:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107134:	e8 ed e5 ff ff       	call   80105726 <initlock>
}
80107139:	c9                   	leave  
8010713a:	c3                   	ret    

8010713b <idtinit>:

void
idtinit(void)
{
8010713b:	55                   	push   %ebp
8010713c:	89 e5                	mov    %esp,%ebp
8010713e:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107141:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107148:	00 
80107149:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107150:	e8 33 fe ff ff       	call   80106f88 <lidt>
}
80107155:	c9                   	leave  
80107156:	c3                   	ret    

80107157 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107157:	55                   	push   %ebp
80107158:	89 e5                	mov    %esp,%ebp
8010715a:	57                   	push   %edi
8010715b:	56                   	push   %esi
8010715c:	53                   	push   %ebx
8010715d:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107160:	8b 45 08             	mov    0x8(%ebp),%eax
80107163:	8b 40 30             	mov    0x30(%eax),%eax
80107166:	83 f8 40             	cmp    $0x40,%eax
80107169:	75 3e                	jne    801071a9 <trap+0x52>
    if(proc->killed)
8010716b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107171:	8b 40 24             	mov    0x24(%eax),%eax
80107174:	85 c0                	test   %eax,%eax
80107176:	74 05                	je     8010717d <trap+0x26>
      exit();
80107178:	e8 7c de ff ff       	call   80104ff9 <exit>
    proc->tf = tf;
8010717d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107183:	8b 55 08             	mov    0x8(%ebp),%edx
80107186:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107189:	e8 35 ec ff ff       	call   80105dc3 <syscall>
    if(proc->killed)
8010718e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107194:	8b 40 24             	mov    0x24(%eax),%eax
80107197:	85 c0                	test   %eax,%eax
80107199:	0f 84 34 02 00 00    	je     801073d3 <trap+0x27c>
      exit();
8010719f:	e8 55 de ff ff       	call   80104ff9 <exit>
    return;
801071a4:	e9 2a 02 00 00       	jmp    801073d3 <trap+0x27c>
  }

  switch(tf->trapno){
801071a9:	8b 45 08             	mov    0x8(%ebp),%eax
801071ac:	8b 40 30             	mov    0x30(%eax),%eax
801071af:	83 e8 20             	sub    $0x20,%eax
801071b2:	83 f8 1f             	cmp    $0x1f,%eax
801071b5:	0f 87 bc 00 00 00    	ja     80107277 <trap+0x120>
801071bb:	8b 04 85 7c 94 10 80 	mov    -0x7fef6b84(,%eax,4),%eax
801071c2:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801071c4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801071ca:	0f b6 00             	movzbl (%eax),%eax
801071cd:	84 c0                	test   %al,%al
801071cf:	75 31                	jne    80107202 <trap+0xab>
      acquire(&tickslock);
801071d1:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801071d8:	e8 6a e5 ff ff       	call   80105747 <acquire>
      ticks++;
801071dd:	a1 c0 36 11 80       	mov    0x801136c0,%eax
801071e2:	83 c0 01             	add    $0x1,%eax
801071e5:	a3 c0 36 11 80       	mov    %eax,0x801136c0
      wakeup(&ticks);
801071ea:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
801071f1:	e8 4c e3 ff ff       	call   80105542 <wakeup>
      release(&tickslock);
801071f6:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801071fd:	e8 a7 e5 ff ff       	call   801057a9 <release>
    }
    lapiceoi();
80107202:	e8 86 c8 ff ff       	call   80103a8d <lapiceoi>
    break;
80107207:	e9 41 01 00 00       	jmp    8010734d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
8010720c:	e8 84 c0 ff ff       	call   80103295 <ideintr>
    lapiceoi();
80107211:	e8 77 c8 ff ff       	call   80103a8d <lapiceoi>
    break;
80107216:	e9 32 01 00 00       	jmp    8010734d <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010721b:	e8 4b c6 ff ff       	call   8010386b <kbdintr>
    lapiceoi();
80107220:	e8 68 c8 ff ff       	call   80103a8d <lapiceoi>
    break;
80107225:	e9 23 01 00 00       	jmp    8010734d <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010722a:	e8 a9 03 00 00       	call   801075d8 <uartintr>
    lapiceoi();
8010722f:	e8 59 c8 ff ff       	call   80103a8d <lapiceoi>
    break;
80107234:	e9 14 01 00 00       	jmp    8010734d <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107239:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010723c:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010723f:	8b 45 08             	mov    0x8(%ebp),%eax
80107242:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107246:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107249:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010724f:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107252:	0f b6 c0             	movzbl %al,%eax
80107255:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107259:	89 54 24 08          	mov    %edx,0x8(%esp)
8010725d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107261:	c7 04 24 dc 93 10 80 	movl   $0x801093dc,(%esp)
80107268:	e8 34 91 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
8010726d:	e8 1b c8 ff ff       	call   80103a8d <lapiceoi>
    break;
80107272:	e9 d6 00 00 00       	jmp    8010734d <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107277:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010727d:	85 c0                	test   %eax,%eax
8010727f:	74 11                	je     80107292 <trap+0x13b>
80107281:	8b 45 08             	mov    0x8(%ebp),%eax
80107284:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107288:	0f b7 c0             	movzwl %ax,%eax
8010728b:	83 e0 03             	and    $0x3,%eax
8010728e:	85 c0                	test   %eax,%eax
80107290:	75 46                	jne    801072d8 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107292:	e8 1a fd ff ff       	call   80106fb1 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80107297:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010729a:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010729d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801072a4:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801072a7:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801072aa:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801072ad:	8b 52 30             	mov    0x30(%edx),%edx
801072b0:	89 44 24 10          	mov    %eax,0x10(%esp)
801072b4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801072b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801072bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801072c0:	c7 04 24 00 94 10 80 	movl   $0x80109400,(%esp)
801072c7:	e8 d5 90 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801072cc:	c7 04 24 32 94 10 80 	movl   $0x80109432,(%esp)
801072d3:	e8 65 92 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072d8:	e8 d4 fc ff ff       	call   80106fb1 <rcr2>
801072dd:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801072df:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072e2:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801072e5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801072eb:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072ee:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801072f1:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072f4:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801072f7:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801072fa:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801072fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107303:	83 c0 6c             	add    $0x6c,%eax
80107306:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107309:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010730f:	8b 40 10             	mov    0x10(%eax),%eax
80107312:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107316:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010731a:	89 74 24 14          	mov    %esi,0x14(%esp)
8010731e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107322:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107326:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107329:	89 54 24 08          	mov    %edx,0x8(%esp)
8010732d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107331:	c7 04 24 38 94 10 80 	movl   $0x80109438,(%esp)
80107338:	e8 64 90 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
8010733d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107343:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010734a:	eb 01                	jmp    8010734d <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
8010734c:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010734d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107353:	85 c0                	test   %eax,%eax
80107355:	74 24                	je     8010737b <trap+0x224>
80107357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010735d:	8b 40 24             	mov    0x24(%eax),%eax
80107360:	85 c0                	test   %eax,%eax
80107362:	74 17                	je     8010737b <trap+0x224>
80107364:	8b 45 08             	mov    0x8(%ebp),%eax
80107367:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010736b:	0f b7 c0             	movzwl %ax,%eax
8010736e:	83 e0 03             	and    $0x3,%eax
80107371:	83 f8 03             	cmp    $0x3,%eax
80107374:	75 05                	jne    8010737b <trap+0x224>
    exit();
80107376:	e8 7e dc ff ff       	call   80104ff9 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010737b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107381:	85 c0                	test   %eax,%eax
80107383:	74 1e                	je     801073a3 <trap+0x24c>
80107385:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010738b:	8b 40 0c             	mov    0xc(%eax),%eax
8010738e:	83 f8 04             	cmp    $0x4,%eax
80107391:	75 10                	jne    801073a3 <trap+0x24c>
80107393:	8b 45 08             	mov    0x8(%ebp),%eax
80107396:	8b 40 30             	mov    0x30(%eax),%eax
80107399:	83 f8 20             	cmp    $0x20,%eax
8010739c:	75 05                	jne    801073a3 <trap+0x24c>
    yield();
8010739e:	e8 68 e0 ff ff       	call   8010540b <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801073a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073a9:	85 c0                	test   %eax,%eax
801073ab:	74 27                	je     801073d4 <trap+0x27d>
801073ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073b3:	8b 40 24             	mov    0x24(%eax),%eax
801073b6:	85 c0                	test   %eax,%eax
801073b8:	74 1a                	je     801073d4 <trap+0x27d>
801073ba:	8b 45 08             	mov    0x8(%ebp),%eax
801073bd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801073c1:	0f b7 c0             	movzwl %ax,%eax
801073c4:	83 e0 03             	and    $0x3,%eax
801073c7:	83 f8 03             	cmp    $0x3,%eax
801073ca:	75 08                	jne    801073d4 <trap+0x27d>
    exit();
801073cc:	e8 28 dc ff ff       	call   80104ff9 <exit>
801073d1:	eb 01                	jmp    801073d4 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801073d3:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801073d4:	83 c4 3c             	add    $0x3c,%esp
801073d7:	5b                   	pop    %ebx
801073d8:	5e                   	pop    %esi
801073d9:	5f                   	pop    %edi
801073da:	5d                   	pop    %ebp
801073db:	c3                   	ret    

801073dc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801073dc:	55                   	push   %ebp
801073dd:	89 e5                	mov    %esp,%ebp
801073df:	53                   	push   %ebx
801073e0:	83 ec 14             	sub    $0x14,%esp
801073e3:	8b 45 08             	mov    0x8(%ebp),%eax
801073e6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801073ea:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801073ee:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801073f2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801073f6:	ec                   	in     (%dx),%al
801073f7:	89 c3                	mov    %eax,%ebx
801073f9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801073fc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107400:	83 c4 14             	add    $0x14,%esp
80107403:	5b                   	pop    %ebx
80107404:	5d                   	pop    %ebp
80107405:	c3                   	ret    

80107406 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107406:	55                   	push   %ebp
80107407:	89 e5                	mov    %esp,%ebp
80107409:	83 ec 08             	sub    $0x8,%esp
8010740c:	8b 55 08             	mov    0x8(%ebp),%edx
8010740f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107412:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107416:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107419:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010741d:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107421:	ee                   	out    %al,(%dx)
}
80107422:	c9                   	leave  
80107423:	c3                   	ret    

80107424 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107424:	55                   	push   %ebp
80107425:	89 e5                	mov    %esp,%ebp
80107427:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010742a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107431:	00 
80107432:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107439:	e8 c8 ff ff ff       	call   80107406 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010743e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107445:	00 
80107446:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010744d:	e8 b4 ff ff ff       	call   80107406 <outb>
  outb(COM1+0, 115200/9600);
80107452:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107459:	00 
8010745a:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107461:	e8 a0 ff ff ff       	call   80107406 <outb>
  outb(COM1+1, 0);
80107466:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010746d:	00 
8010746e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107475:	e8 8c ff ff ff       	call   80107406 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010747a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107481:	00 
80107482:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107489:	e8 78 ff ff ff       	call   80107406 <outb>
  outb(COM1+4, 0);
8010748e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107495:	00 
80107496:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
8010749d:	e8 64 ff ff ff       	call   80107406 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801074a2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801074a9:	00 
801074aa:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801074b1:	e8 50 ff ff ff       	call   80107406 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801074b6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801074bd:	e8 1a ff ff ff       	call   801073dc <inb>
801074c2:	3c ff                	cmp    $0xff,%al
801074c4:	74 6c                	je     80107532 <uartinit+0x10e>
    return;
  uart = 1;
801074c6:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801074cd:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801074d0:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801074d7:	e8 00 ff ff ff       	call   801073dc <inb>
  inb(COM1+0);
801074dc:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801074e3:	e8 f4 fe ff ff       	call   801073dc <inb>
  picenable(IRQ_COM1);
801074e8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801074ef:	e8 71 d1 ff ff       	call   80104665 <picenable>
  ioapicenable(IRQ_COM1, 0);
801074f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801074fb:	00 
801074fc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107503:	e8 12 c0 ff ff       	call   8010351a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107508:	c7 45 f4 fc 94 10 80 	movl   $0x801094fc,-0xc(%ebp)
8010750f:	eb 15                	jmp    80107526 <uartinit+0x102>
    uartputc(*p);
80107511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107514:	0f b6 00             	movzbl (%eax),%eax
80107517:	0f be c0             	movsbl %al,%eax
8010751a:	89 04 24             	mov    %eax,(%esp)
8010751d:	e8 13 00 00 00       	call   80107535 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107522:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107529:	0f b6 00             	movzbl (%eax),%eax
8010752c:	84 c0                	test   %al,%al
8010752e:	75 e1                	jne    80107511 <uartinit+0xed>
80107530:	eb 01                	jmp    80107533 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107532:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107533:	c9                   	leave  
80107534:	c3                   	ret    

80107535 <uartputc>:

void
uartputc(int c)
{
80107535:	55                   	push   %ebp
80107536:	89 e5                	mov    %esp,%ebp
80107538:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010753b:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107540:	85 c0                	test   %eax,%eax
80107542:	74 4d                	je     80107591 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107544:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010754b:	eb 10                	jmp    8010755d <uartputc+0x28>
    microdelay(10);
8010754d:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107554:	e8 59 c5 ff ff       	call   80103ab2 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107559:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010755d:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107561:	7f 16                	jg     80107579 <uartputc+0x44>
80107563:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010756a:	e8 6d fe ff ff       	call   801073dc <inb>
8010756f:	0f b6 c0             	movzbl %al,%eax
80107572:	83 e0 20             	and    $0x20,%eax
80107575:	85 c0                	test   %eax,%eax
80107577:	74 d4                	je     8010754d <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107579:	8b 45 08             	mov    0x8(%ebp),%eax
8010757c:	0f b6 c0             	movzbl %al,%eax
8010757f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107583:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010758a:	e8 77 fe ff ff       	call   80107406 <outb>
8010758f:	eb 01                	jmp    80107592 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107591:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107592:	c9                   	leave  
80107593:	c3                   	ret    

80107594 <uartgetc>:

static int
uartgetc(void)
{
80107594:	55                   	push   %ebp
80107595:	89 e5                	mov    %esp,%ebp
80107597:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
8010759a:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
8010759f:	85 c0                	test   %eax,%eax
801075a1:	75 07                	jne    801075aa <uartgetc+0x16>
    return -1;
801075a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075a8:	eb 2c                	jmp    801075d6 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801075aa:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801075b1:	e8 26 fe ff ff       	call   801073dc <inb>
801075b6:	0f b6 c0             	movzbl %al,%eax
801075b9:	83 e0 01             	and    $0x1,%eax
801075bc:	85 c0                	test   %eax,%eax
801075be:	75 07                	jne    801075c7 <uartgetc+0x33>
    return -1;
801075c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075c5:	eb 0f                	jmp    801075d6 <uartgetc+0x42>
  return inb(COM1+0);
801075c7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801075ce:	e8 09 fe ff ff       	call   801073dc <inb>
801075d3:	0f b6 c0             	movzbl %al,%eax
}
801075d6:	c9                   	leave  
801075d7:	c3                   	ret    

801075d8 <uartintr>:

void
uartintr(void)
{
801075d8:	55                   	push   %ebp
801075d9:	89 e5                	mov    %esp,%ebp
801075db:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801075de:	c7 04 24 94 75 10 80 	movl   $0x80107594,(%esp)
801075e5:	e8 c3 91 ff ff       	call   801007ad <consoleintr>
}
801075ea:	c9                   	leave  
801075eb:	c3                   	ret    

801075ec <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801075ec:	6a 00                	push   $0x0
  pushl $0
801075ee:	6a 00                	push   $0x0
  jmp alltraps
801075f0:	e9 67 f9 ff ff       	jmp    80106f5c <alltraps>

801075f5 <vector1>:
.globl vector1
vector1:
  pushl $0
801075f5:	6a 00                	push   $0x0
  pushl $1
801075f7:	6a 01                	push   $0x1
  jmp alltraps
801075f9:	e9 5e f9 ff ff       	jmp    80106f5c <alltraps>

801075fe <vector2>:
.globl vector2
vector2:
  pushl $0
801075fe:	6a 00                	push   $0x0
  pushl $2
80107600:	6a 02                	push   $0x2
  jmp alltraps
80107602:	e9 55 f9 ff ff       	jmp    80106f5c <alltraps>

80107607 <vector3>:
.globl vector3
vector3:
  pushl $0
80107607:	6a 00                	push   $0x0
  pushl $3
80107609:	6a 03                	push   $0x3
  jmp alltraps
8010760b:	e9 4c f9 ff ff       	jmp    80106f5c <alltraps>

80107610 <vector4>:
.globl vector4
vector4:
  pushl $0
80107610:	6a 00                	push   $0x0
  pushl $4
80107612:	6a 04                	push   $0x4
  jmp alltraps
80107614:	e9 43 f9 ff ff       	jmp    80106f5c <alltraps>

80107619 <vector5>:
.globl vector5
vector5:
  pushl $0
80107619:	6a 00                	push   $0x0
  pushl $5
8010761b:	6a 05                	push   $0x5
  jmp alltraps
8010761d:	e9 3a f9 ff ff       	jmp    80106f5c <alltraps>

80107622 <vector6>:
.globl vector6
vector6:
  pushl $0
80107622:	6a 00                	push   $0x0
  pushl $6
80107624:	6a 06                	push   $0x6
  jmp alltraps
80107626:	e9 31 f9 ff ff       	jmp    80106f5c <alltraps>

8010762b <vector7>:
.globl vector7
vector7:
  pushl $0
8010762b:	6a 00                	push   $0x0
  pushl $7
8010762d:	6a 07                	push   $0x7
  jmp alltraps
8010762f:	e9 28 f9 ff ff       	jmp    80106f5c <alltraps>

80107634 <vector8>:
.globl vector8
vector8:
  pushl $8
80107634:	6a 08                	push   $0x8
  jmp alltraps
80107636:	e9 21 f9 ff ff       	jmp    80106f5c <alltraps>

8010763b <vector9>:
.globl vector9
vector9:
  pushl $0
8010763b:	6a 00                	push   $0x0
  pushl $9
8010763d:	6a 09                	push   $0x9
  jmp alltraps
8010763f:	e9 18 f9 ff ff       	jmp    80106f5c <alltraps>

80107644 <vector10>:
.globl vector10
vector10:
  pushl $10
80107644:	6a 0a                	push   $0xa
  jmp alltraps
80107646:	e9 11 f9 ff ff       	jmp    80106f5c <alltraps>

8010764b <vector11>:
.globl vector11
vector11:
  pushl $11
8010764b:	6a 0b                	push   $0xb
  jmp alltraps
8010764d:	e9 0a f9 ff ff       	jmp    80106f5c <alltraps>

80107652 <vector12>:
.globl vector12
vector12:
  pushl $12
80107652:	6a 0c                	push   $0xc
  jmp alltraps
80107654:	e9 03 f9 ff ff       	jmp    80106f5c <alltraps>

80107659 <vector13>:
.globl vector13
vector13:
  pushl $13
80107659:	6a 0d                	push   $0xd
  jmp alltraps
8010765b:	e9 fc f8 ff ff       	jmp    80106f5c <alltraps>

80107660 <vector14>:
.globl vector14
vector14:
  pushl $14
80107660:	6a 0e                	push   $0xe
  jmp alltraps
80107662:	e9 f5 f8 ff ff       	jmp    80106f5c <alltraps>

80107667 <vector15>:
.globl vector15
vector15:
  pushl $0
80107667:	6a 00                	push   $0x0
  pushl $15
80107669:	6a 0f                	push   $0xf
  jmp alltraps
8010766b:	e9 ec f8 ff ff       	jmp    80106f5c <alltraps>

80107670 <vector16>:
.globl vector16
vector16:
  pushl $0
80107670:	6a 00                	push   $0x0
  pushl $16
80107672:	6a 10                	push   $0x10
  jmp alltraps
80107674:	e9 e3 f8 ff ff       	jmp    80106f5c <alltraps>

80107679 <vector17>:
.globl vector17
vector17:
  pushl $17
80107679:	6a 11                	push   $0x11
  jmp alltraps
8010767b:	e9 dc f8 ff ff       	jmp    80106f5c <alltraps>

80107680 <vector18>:
.globl vector18
vector18:
  pushl $0
80107680:	6a 00                	push   $0x0
  pushl $18
80107682:	6a 12                	push   $0x12
  jmp alltraps
80107684:	e9 d3 f8 ff ff       	jmp    80106f5c <alltraps>

80107689 <vector19>:
.globl vector19
vector19:
  pushl $0
80107689:	6a 00                	push   $0x0
  pushl $19
8010768b:	6a 13                	push   $0x13
  jmp alltraps
8010768d:	e9 ca f8 ff ff       	jmp    80106f5c <alltraps>

80107692 <vector20>:
.globl vector20
vector20:
  pushl $0
80107692:	6a 00                	push   $0x0
  pushl $20
80107694:	6a 14                	push   $0x14
  jmp alltraps
80107696:	e9 c1 f8 ff ff       	jmp    80106f5c <alltraps>

8010769b <vector21>:
.globl vector21
vector21:
  pushl $0
8010769b:	6a 00                	push   $0x0
  pushl $21
8010769d:	6a 15                	push   $0x15
  jmp alltraps
8010769f:	e9 b8 f8 ff ff       	jmp    80106f5c <alltraps>

801076a4 <vector22>:
.globl vector22
vector22:
  pushl $0
801076a4:	6a 00                	push   $0x0
  pushl $22
801076a6:	6a 16                	push   $0x16
  jmp alltraps
801076a8:	e9 af f8 ff ff       	jmp    80106f5c <alltraps>

801076ad <vector23>:
.globl vector23
vector23:
  pushl $0
801076ad:	6a 00                	push   $0x0
  pushl $23
801076af:	6a 17                	push   $0x17
  jmp alltraps
801076b1:	e9 a6 f8 ff ff       	jmp    80106f5c <alltraps>

801076b6 <vector24>:
.globl vector24
vector24:
  pushl $0
801076b6:	6a 00                	push   $0x0
  pushl $24
801076b8:	6a 18                	push   $0x18
  jmp alltraps
801076ba:	e9 9d f8 ff ff       	jmp    80106f5c <alltraps>

801076bf <vector25>:
.globl vector25
vector25:
  pushl $0
801076bf:	6a 00                	push   $0x0
  pushl $25
801076c1:	6a 19                	push   $0x19
  jmp alltraps
801076c3:	e9 94 f8 ff ff       	jmp    80106f5c <alltraps>

801076c8 <vector26>:
.globl vector26
vector26:
  pushl $0
801076c8:	6a 00                	push   $0x0
  pushl $26
801076ca:	6a 1a                	push   $0x1a
  jmp alltraps
801076cc:	e9 8b f8 ff ff       	jmp    80106f5c <alltraps>

801076d1 <vector27>:
.globl vector27
vector27:
  pushl $0
801076d1:	6a 00                	push   $0x0
  pushl $27
801076d3:	6a 1b                	push   $0x1b
  jmp alltraps
801076d5:	e9 82 f8 ff ff       	jmp    80106f5c <alltraps>

801076da <vector28>:
.globl vector28
vector28:
  pushl $0
801076da:	6a 00                	push   $0x0
  pushl $28
801076dc:	6a 1c                	push   $0x1c
  jmp alltraps
801076de:	e9 79 f8 ff ff       	jmp    80106f5c <alltraps>

801076e3 <vector29>:
.globl vector29
vector29:
  pushl $0
801076e3:	6a 00                	push   $0x0
  pushl $29
801076e5:	6a 1d                	push   $0x1d
  jmp alltraps
801076e7:	e9 70 f8 ff ff       	jmp    80106f5c <alltraps>

801076ec <vector30>:
.globl vector30
vector30:
  pushl $0
801076ec:	6a 00                	push   $0x0
  pushl $30
801076ee:	6a 1e                	push   $0x1e
  jmp alltraps
801076f0:	e9 67 f8 ff ff       	jmp    80106f5c <alltraps>

801076f5 <vector31>:
.globl vector31
vector31:
  pushl $0
801076f5:	6a 00                	push   $0x0
  pushl $31
801076f7:	6a 1f                	push   $0x1f
  jmp alltraps
801076f9:	e9 5e f8 ff ff       	jmp    80106f5c <alltraps>

801076fe <vector32>:
.globl vector32
vector32:
  pushl $0
801076fe:	6a 00                	push   $0x0
  pushl $32
80107700:	6a 20                	push   $0x20
  jmp alltraps
80107702:	e9 55 f8 ff ff       	jmp    80106f5c <alltraps>

80107707 <vector33>:
.globl vector33
vector33:
  pushl $0
80107707:	6a 00                	push   $0x0
  pushl $33
80107709:	6a 21                	push   $0x21
  jmp alltraps
8010770b:	e9 4c f8 ff ff       	jmp    80106f5c <alltraps>

80107710 <vector34>:
.globl vector34
vector34:
  pushl $0
80107710:	6a 00                	push   $0x0
  pushl $34
80107712:	6a 22                	push   $0x22
  jmp alltraps
80107714:	e9 43 f8 ff ff       	jmp    80106f5c <alltraps>

80107719 <vector35>:
.globl vector35
vector35:
  pushl $0
80107719:	6a 00                	push   $0x0
  pushl $35
8010771b:	6a 23                	push   $0x23
  jmp alltraps
8010771d:	e9 3a f8 ff ff       	jmp    80106f5c <alltraps>

80107722 <vector36>:
.globl vector36
vector36:
  pushl $0
80107722:	6a 00                	push   $0x0
  pushl $36
80107724:	6a 24                	push   $0x24
  jmp alltraps
80107726:	e9 31 f8 ff ff       	jmp    80106f5c <alltraps>

8010772b <vector37>:
.globl vector37
vector37:
  pushl $0
8010772b:	6a 00                	push   $0x0
  pushl $37
8010772d:	6a 25                	push   $0x25
  jmp alltraps
8010772f:	e9 28 f8 ff ff       	jmp    80106f5c <alltraps>

80107734 <vector38>:
.globl vector38
vector38:
  pushl $0
80107734:	6a 00                	push   $0x0
  pushl $38
80107736:	6a 26                	push   $0x26
  jmp alltraps
80107738:	e9 1f f8 ff ff       	jmp    80106f5c <alltraps>

8010773d <vector39>:
.globl vector39
vector39:
  pushl $0
8010773d:	6a 00                	push   $0x0
  pushl $39
8010773f:	6a 27                	push   $0x27
  jmp alltraps
80107741:	e9 16 f8 ff ff       	jmp    80106f5c <alltraps>

80107746 <vector40>:
.globl vector40
vector40:
  pushl $0
80107746:	6a 00                	push   $0x0
  pushl $40
80107748:	6a 28                	push   $0x28
  jmp alltraps
8010774a:	e9 0d f8 ff ff       	jmp    80106f5c <alltraps>

8010774f <vector41>:
.globl vector41
vector41:
  pushl $0
8010774f:	6a 00                	push   $0x0
  pushl $41
80107751:	6a 29                	push   $0x29
  jmp alltraps
80107753:	e9 04 f8 ff ff       	jmp    80106f5c <alltraps>

80107758 <vector42>:
.globl vector42
vector42:
  pushl $0
80107758:	6a 00                	push   $0x0
  pushl $42
8010775a:	6a 2a                	push   $0x2a
  jmp alltraps
8010775c:	e9 fb f7 ff ff       	jmp    80106f5c <alltraps>

80107761 <vector43>:
.globl vector43
vector43:
  pushl $0
80107761:	6a 00                	push   $0x0
  pushl $43
80107763:	6a 2b                	push   $0x2b
  jmp alltraps
80107765:	e9 f2 f7 ff ff       	jmp    80106f5c <alltraps>

8010776a <vector44>:
.globl vector44
vector44:
  pushl $0
8010776a:	6a 00                	push   $0x0
  pushl $44
8010776c:	6a 2c                	push   $0x2c
  jmp alltraps
8010776e:	e9 e9 f7 ff ff       	jmp    80106f5c <alltraps>

80107773 <vector45>:
.globl vector45
vector45:
  pushl $0
80107773:	6a 00                	push   $0x0
  pushl $45
80107775:	6a 2d                	push   $0x2d
  jmp alltraps
80107777:	e9 e0 f7 ff ff       	jmp    80106f5c <alltraps>

8010777c <vector46>:
.globl vector46
vector46:
  pushl $0
8010777c:	6a 00                	push   $0x0
  pushl $46
8010777e:	6a 2e                	push   $0x2e
  jmp alltraps
80107780:	e9 d7 f7 ff ff       	jmp    80106f5c <alltraps>

80107785 <vector47>:
.globl vector47
vector47:
  pushl $0
80107785:	6a 00                	push   $0x0
  pushl $47
80107787:	6a 2f                	push   $0x2f
  jmp alltraps
80107789:	e9 ce f7 ff ff       	jmp    80106f5c <alltraps>

8010778e <vector48>:
.globl vector48
vector48:
  pushl $0
8010778e:	6a 00                	push   $0x0
  pushl $48
80107790:	6a 30                	push   $0x30
  jmp alltraps
80107792:	e9 c5 f7 ff ff       	jmp    80106f5c <alltraps>

80107797 <vector49>:
.globl vector49
vector49:
  pushl $0
80107797:	6a 00                	push   $0x0
  pushl $49
80107799:	6a 31                	push   $0x31
  jmp alltraps
8010779b:	e9 bc f7 ff ff       	jmp    80106f5c <alltraps>

801077a0 <vector50>:
.globl vector50
vector50:
  pushl $0
801077a0:	6a 00                	push   $0x0
  pushl $50
801077a2:	6a 32                	push   $0x32
  jmp alltraps
801077a4:	e9 b3 f7 ff ff       	jmp    80106f5c <alltraps>

801077a9 <vector51>:
.globl vector51
vector51:
  pushl $0
801077a9:	6a 00                	push   $0x0
  pushl $51
801077ab:	6a 33                	push   $0x33
  jmp alltraps
801077ad:	e9 aa f7 ff ff       	jmp    80106f5c <alltraps>

801077b2 <vector52>:
.globl vector52
vector52:
  pushl $0
801077b2:	6a 00                	push   $0x0
  pushl $52
801077b4:	6a 34                	push   $0x34
  jmp alltraps
801077b6:	e9 a1 f7 ff ff       	jmp    80106f5c <alltraps>

801077bb <vector53>:
.globl vector53
vector53:
  pushl $0
801077bb:	6a 00                	push   $0x0
  pushl $53
801077bd:	6a 35                	push   $0x35
  jmp alltraps
801077bf:	e9 98 f7 ff ff       	jmp    80106f5c <alltraps>

801077c4 <vector54>:
.globl vector54
vector54:
  pushl $0
801077c4:	6a 00                	push   $0x0
  pushl $54
801077c6:	6a 36                	push   $0x36
  jmp alltraps
801077c8:	e9 8f f7 ff ff       	jmp    80106f5c <alltraps>

801077cd <vector55>:
.globl vector55
vector55:
  pushl $0
801077cd:	6a 00                	push   $0x0
  pushl $55
801077cf:	6a 37                	push   $0x37
  jmp alltraps
801077d1:	e9 86 f7 ff ff       	jmp    80106f5c <alltraps>

801077d6 <vector56>:
.globl vector56
vector56:
  pushl $0
801077d6:	6a 00                	push   $0x0
  pushl $56
801077d8:	6a 38                	push   $0x38
  jmp alltraps
801077da:	e9 7d f7 ff ff       	jmp    80106f5c <alltraps>

801077df <vector57>:
.globl vector57
vector57:
  pushl $0
801077df:	6a 00                	push   $0x0
  pushl $57
801077e1:	6a 39                	push   $0x39
  jmp alltraps
801077e3:	e9 74 f7 ff ff       	jmp    80106f5c <alltraps>

801077e8 <vector58>:
.globl vector58
vector58:
  pushl $0
801077e8:	6a 00                	push   $0x0
  pushl $58
801077ea:	6a 3a                	push   $0x3a
  jmp alltraps
801077ec:	e9 6b f7 ff ff       	jmp    80106f5c <alltraps>

801077f1 <vector59>:
.globl vector59
vector59:
  pushl $0
801077f1:	6a 00                	push   $0x0
  pushl $59
801077f3:	6a 3b                	push   $0x3b
  jmp alltraps
801077f5:	e9 62 f7 ff ff       	jmp    80106f5c <alltraps>

801077fa <vector60>:
.globl vector60
vector60:
  pushl $0
801077fa:	6a 00                	push   $0x0
  pushl $60
801077fc:	6a 3c                	push   $0x3c
  jmp alltraps
801077fe:	e9 59 f7 ff ff       	jmp    80106f5c <alltraps>

80107803 <vector61>:
.globl vector61
vector61:
  pushl $0
80107803:	6a 00                	push   $0x0
  pushl $61
80107805:	6a 3d                	push   $0x3d
  jmp alltraps
80107807:	e9 50 f7 ff ff       	jmp    80106f5c <alltraps>

8010780c <vector62>:
.globl vector62
vector62:
  pushl $0
8010780c:	6a 00                	push   $0x0
  pushl $62
8010780e:	6a 3e                	push   $0x3e
  jmp alltraps
80107810:	e9 47 f7 ff ff       	jmp    80106f5c <alltraps>

80107815 <vector63>:
.globl vector63
vector63:
  pushl $0
80107815:	6a 00                	push   $0x0
  pushl $63
80107817:	6a 3f                	push   $0x3f
  jmp alltraps
80107819:	e9 3e f7 ff ff       	jmp    80106f5c <alltraps>

8010781e <vector64>:
.globl vector64
vector64:
  pushl $0
8010781e:	6a 00                	push   $0x0
  pushl $64
80107820:	6a 40                	push   $0x40
  jmp alltraps
80107822:	e9 35 f7 ff ff       	jmp    80106f5c <alltraps>

80107827 <vector65>:
.globl vector65
vector65:
  pushl $0
80107827:	6a 00                	push   $0x0
  pushl $65
80107829:	6a 41                	push   $0x41
  jmp alltraps
8010782b:	e9 2c f7 ff ff       	jmp    80106f5c <alltraps>

80107830 <vector66>:
.globl vector66
vector66:
  pushl $0
80107830:	6a 00                	push   $0x0
  pushl $66
80107832:	6a 42                	push   $0x42
  jmp alltraps
80107834:	e9 23 f7 ff ff       	jmp    80106f5c <alltraps>

80107839 <vector67>:
.globl vector67
vector67:
  pushl $0
80107839:	6a 00                	push   $0x0
  pushl $67
8010783b:	6a 43                	push   $0x43
  jmp alltraps
8010783d:	e9 1a f7 ff ff       	jmp    80106f5c <alltraps>

80107842 <vector68>:
.globl vector68
vector68:
  pushl $0
80107842:	6a 00                	push   $0x0
  pushl $68
80107844:	6a 44                	push   $0x44
  jmp alltraps
80107846:	e9 11 f7 ff ff       	jmp    80106f5c <alltraps>

8010784b <vector69>:
.globl vector69
vector69:
  pushl $0
8010784b:	6a 00                	push   $0x0
  pushl $69
8010784d:	6a 45                	push   $0x45
  jmp alltraps
8010784f:	e9 08 f7 ff ff       	jmp    80106f5c <alltraps>

80107854 <vector70>:
.globl vector70
vector70:
  pushl $0
80107854:	6a 00                	push   $0x0
  pushl $70
80107856:	6a 46                	push   $0x46
  jmp alltraps
80107858:	e9 ff f6 ff ff       	jmp    80106f5c <alltraps>

8010785d <vector71>:
.globl vector71
vector71:
  pushl $0
8010785d:	6a 00                	push   $0x0
  pushl $71
8010785f:	6a 47                	push   $0x47
  jmp alltraps
80107861:	e9 f6 f6 ff ff       	jmp    80106f5c <alltraps>

80107866 <vector72>:
.globl vector72
vector72:
  pushl $0
80107866:	6a 00                	push   $0x0
  pushl $72
80107868:	6a 48                	push   $0x48
  jmp alltraps
8010786a:	e9 ed f6 ff ff       	jmp    80106f5c <alltraps>

8010786f <vector73>:
.globl vector73
vector73:
  pushl $0
8010786f:	6a 00                	push   $0x0
  pushl $73
80107871:	6a 49                	push   $0x49
  jmp alltraps
80107873:	e9 e4 f6 ff ff       	jmp    80106f5c <alltraps>

80107878 <vector74>:
.globl vector74
vector74:
  pushl $0
80107878:	6a 00                	push   $0x0
  pushl $74
8010787a:	6a 4a                	push   $0x4a
  jmp alltraps
8010787c:	e9 db f6 ff ff       	jmp    80106f5c <alltraps>

80107881 <vector75>:
.globl vector75
vector75:
  pushl $0
80107881:	6a 00                	push   $0x0
  pushl $75
80107883:	6a 4b                	push   $0x4b
  jmp alltraps
80107885:	e9 d2 f6 ff ff       	jmp    80106f5c <alltraps>

8010788a <vector76>:
.globl vector76
vector76:
  pushl $0
8010788a:	6a 00                	push   $0x0
  pushl $76
8010788c:	6a 4c                	push   $0x4c
  jmp alltraps
8010788e:	e9 c9 f6 ff ff       	jmp    80106f5c <alltraps>

80107893 <vector77>:
.globl vector77
vector77:
  pushl $0
80107893:	6a 00                	push   $0x0
  pushl $77
80107895:	6a 4d                	push   $0x4d
  jmp alltraps
80107897:	e9 c0 f6 ff ff       	jmp    80106f5c <alltraps>

8010789c <vector78>:
.globl vector78
vector78:
  pushl $0
8010789c:	6a 00                	push   $0x0
  pushl $78
8010789e:	6a 4e                	push   $0x4e
  jmp alltraps
801078a0:	e9 b7 f6 ff ff       	jmp    80106f5c <alltraps>

801078a5 <vector79>:
.globl vector79
vector79:
  pushl $0
801078a5:	6a 00                	push   $0x0
  pushl $79
801078a7:	6a 4f                	push   $0x4f
  jmp alltraps
801078a9:	e9 ae f6 ff ff       	jmp    80106f5c <alltraps>

801078ae <vector80>:
.globl vector80
vector80:
  pushl $0
801078ae:	6a 00                	push   $0x0
  pushl $80
801078b0:	6a 50                	push   $0x50
  jmp alltraps
801078b2:	e9 a5 f6 ff ff       	jmp    80106f5c <alltraps>

801078b7 <vector81>:
.globl vector81
vector81:
  pushl $0
801078b7:	6a 00                	push   $0x0
  pushl $81
801078b9:	6a 51                	push   $0x51
  jmp alltraps
801078bb:	e9 9c f6 ff ff       	jmp    80106f5c <alltraps>

801078c0 <vector82>:
.globl vector82
vector82:
  pushl $0
801078c0:	6a 00                	push   $0x0
  pushl $82
801078c2:	6a 52                	push   $0x52
  jmp alltraps
801078c4:	e9 93 f6 ff ff       	jmp    80106f5c <alltraps>

801078c9 <vector83>:
.globl vector83
vector83:
  pushl $0
801078c9:	6a 00                	push   $0x0
  pushl $83
801078cb:	6a 53                	push   $0x53
  jmp alltraps
801078cd:	e9 8a f6 ff ff       	jmp    80106f5c <alltraps>

801078d2 <vector84>:
.globl vector84
vector84:
  pushl $0
801078d2:	6a 00                	push   $0x0
  pushl $84
801078d4:	6a 54                	push   $0x54
  jmp alltraps
801078d6:	e9 81 f6 ff ff       	jmp    80106f5c <alltraps>

801078db <vector85>:
.globl vector85
vector85:
  pushl $0
801078db:	6a 00                	push   $0x0
  pushl $85
801078dd:	6a 55                	push   $0x55
  jmp alltraps
801078df:	e9 78 f6 ff ff       	jmp    80106f5c <alltraps>

801078e4 <vector86>:
.globl vector86
vector86:
  pushl $0
801078e4:	6a 00                	push   $0x0
  pushl $86
801078e6:	6a 56                	push   $0x56
  jmp alltraps
801078e8:	e9 6f f6 ff ff       	jmp    80106f5c <alltraps>

801078ed <vector87>:
.globl vector87
vector87:
  pushl $0
801078ed:	6a 00                	push   $0x0
  pushl $87
801078ef:	6a 57                	push   $0x57
  jmp alltraps
801078f1:	e9 66 f6 ff ff       	jmp    80106f5c <alltraps>

801078f6 <vector88>:
.globl vector88
vector88:
  pushl $0
801078f6:	6a 00                	push   $0x0
  pushl $88
801078f8:	6a 58                	push   $0x58
  jmp alltraps
801078fa:	e9 5d f6 ff ff       	jmp    80106f5c <alltraps>

801078ff <vector89>:
.globl vector89
vector89:
  pushl $0
801078ff:	6a 00                	push   $0x0
  pushl $89
80107901:	6a 59                	push   $0x59
  jmp alltraps
80107903:	e9 54 f6 ff ff       	jmp    80106f5c <alltraps>

80107908 <vector90>:
.globl vector90
vector90:
  pushl $0
80107908:	6a 00                	push   $0x0
  pushl $90
8010790a:	6a 5a                	push   $0x5a
  jmp alltraps
8010790c:	e9 4b f6 ff ff       	jmp    80106f5c <alltraps>

80107911 <vector91>:
.globl vector91
vector91:
  pushl $0
80107911:	6a 00                	push   $0x0
  pushl $91
80107913:	6a 5b                	push   $0x5b
  jmp alltraps
80107915:	e9 42 f6 ff ff       	jmp    80106f5c <alltraps>

8010791a <vector92>:
.globl vector92
vector92:
  pushl $0
8010791a:	6a 00                	push   $0x0
  pushl $92
8010791c:	6a 5c                	push   $0x5c
  jmp alltraps
8010791e:	e9 39 f6 ff ff       	jmp    80106f5c <alltraps>

80107923 <vector93>:
.globl vector93
vector93:
  pushl $0
80107923:	6a 00                	push   $0x0
  pushl $93
80107925:	6a 5d                	push   $0x5d
  jmp alltraps
80107927:	e9 30 f6 ff ff       	jmp    80106f5c <alltraps>

8010792c <vector94>:
.globl vector94
vector94:
  pushl $0
8010792c:	6a 00                	push   $0x0
  pushl $94
8010792e:	6a 5e                	push   $0x5e
  jmp alltraps
80107930:	e9 27 f6 ff ff       	jmp    80106f5c <alltraps>

80107935 <vector95>:
.globl vector95
vector95:
  pushl $0
80107935:	6a 00                	push   $0x0
  pushl $95
80107937:	6a 5f                	push   $0x5f
  jmp alltraps
80107939:	e9 1e f6 ff ff       	jmp    80106f5c <alltraps>

8010793e <vector96>:
.globl vector96
vector96:
  pushl $0
8010793e:	6a 00                	push   $0x0
  pushl $96
80107940:	6a 60                	push   $0x60
  jmp alltraps
80107942:	e9 15 f6 ff ff       	jmp    80106f5c <alltraps>

80107947 <vector97>:
.globl vector97
vector97:
  pushl $0
80107947:	6a 00                	push   $0x0
  pushl $97
80107949:	6a 61                	push   $0x61
  jmp alltraps
8010794b:	e9 0c f6 ff ff       	jmp    80106f5c <alltraps>

80107950 <vector98>:
.globl vector98
vector98:
  pushl $0
80107950:	6a 00                	push   $0x0
  pushl $98
80107952:	6a 62                	push   $0x62
  jmp alltraps
80107954:	e9 03 f6 ff ff       	jmp    80106f5c <alltraps>

80107959 <vector99>:
.globl vector99
vector99:
  pushl $0
80107959:	6a 00                	push   $0x0
  pushl $99
8010795b:	6a 63                	push   $0x63
  jmp alltraps
8010795d:	e9 fa f5 ff ff       	jmp    80106f5c <alltraps>

80107962 <vector100>:
.globl vector100
vector100:
  pushl $0
80107962:	6a 00                	push   $0x0
  pushl $100
80107964:	6a 64                	push   $0x64
  jmp alltraps
80107966:	e9 f1 f5 ff ff       	jmp    80106f5c <alltraps>

8010796b <vector101>:
.globl vector101
vector101:
  pushl $0
8010796b:	6a 00                	push   $0x0
  pushl $101
8010796d:	6a 65                	push   $0x65
  jmp alltraps
8010796f:	e9 e8 f5 ff ff       	jmp    80106f5c <alltraps>

80107974 <vector102>:
.globl vector102
vector102:
  pushl $0
80107974:	6a 00                	push   $0x0
  pushl $102
80107976:	6a 66                	push   $0x66
  jmp alltraps
80107978:	e9 df f5 ff ff       	jmp    80106f5c <alltraps>

8010797d <vector103>:
.globl vector103
vector103:
  pushl $0
8010797d:	6a 00                	push   $0x0
  pushl $103
8010797f:	6a 67                	push   $0x67
  jmp alltraps
80107981:	e9 d6 f5 ff ff       	jmp    80106f5c <alltraps>

80107986 <vector104>:
.globl vector104
vector104:
  pushl $0
80107986:	6a 00                	push   $0x0
  pushl $104
80107988:	6a 68                	push   $0x68
  jmp alltraps
8010798a:	e9 cd f5 ff ff       	jmp    80106f5c <alltraps>

8010798f <vector105>:
.globl vector105
vector105:
  pushl $0
8010798f:	6a 00                	push   $0x0
  pushl $105
80107991:	6a 69                	push   $0x69
  jmp alltraps
80107993:	e9 c4 f5 ff ff       	jmp    80106f5c <alltraps>

80107998 <vector106>:
.globl vector106
vector106:
  pushl $0
80107998:	6a 00                	push   $0x0
  pushl $106
8010799a:	6a 6a                	push   $0x6a
  jmp alltraps
8010799c:	e9 bb f5 ff ff       	jmp    80106f5c <alltraps>

801079a1 <vector107>:
.globl vector107
vector107:
  pushl $0
801079a1:	6a 00                	push   $0x0
  pushl $107
801079a3:	6a 6b                	push   $0x6b
  jmp alltraps
801079a5:	e9 b2 f5 ff ff       	jmp    80106f5c <alltraps>

801079aa <vector108>:
.globl vector108
vector108:
  pushl $0
801079aa:	6a 00                	push   $0x0
  pushl $108
801079ac:	6a 6c                	push   $0x6c
  jmp alltraps
801079ae:	e9 a9 f5 ff ff       	jmp    80106f5c <alltraps>

801079b3 <vector109>:
.globl vector109
vector109:
  pushl $0
801079b3:	6a 00                	push   $0x0
  pushl $109
801079b5:	6a 6d                	push   $0x6d
  jmp alltraps
801079b7:	e9 a0 f5 ff ff       	jmp    80106f5c <alltraps>

801079bc <vector110>:
.globl vector110
vector110:
  pushl $0
801079bc:	6a 00                	push   $0x0
  pushl $110
801079be:	6a 6e                	push   $0x6e
  jmp alltraps
801079c0:	e9 97 f5 ff ff       	jmp    80106f5c <alltraps>

801079c5 <vector111>:
.globl vector111
vector111:
  pushl $0
801079c5:	6a 00                	push   $0x0
  pushl $111
801079c7:	6a 6f                	push   $0x6f
  jmp alltraps
801079c9:	e9 8e f5 ff ff       	jmp    80106f5c <alltraps>

801079ce <vector112>:
.globl vector112
vector112:
  pushl $0
801079ce:	6a 00                	push   $0x0
  pushl $112
801079d0:	6a 70                	push   $0x70
  jmp alltraps
801079d2:	e9 85 f5 ff ff       	jmp    80106f5c <alltraps>

801079d7 <vector113>:
.globl vector113
vector113:
  pushl $0
801079d7:	6a 00                	push   $0x0
  pushl $113
801079d9:	6a 71                	push   $0x71
  jmp alltraps
801079db:	e9 7c f5 ff ff       	jmp    80106f5c <alltraps>

801079e0 <vector114>:
.globl vector114
vector114:
  pushl $0
801079e0:	6a 00                	push   $0x0
  pushl $114
801079e2:	6a 72                	push   $0x72
  jmp alltraps
801079e4:	e9 73 f5 ff ff       	jmp    80106f5c <alltraps>

801079e9 <vector115>:
.globl vector115
vector115:
  pushl $0
801079e9:	6a 00                	push   $0x0
  pushl $115
801079eb:	6a 73                	push   $0x73
  jmp alltraps
801079ed:	e9 6a f5 ff ff       	jmp    80106f5c <alltraps>

801079f2 <vector116>:
.globl vector116
vector116:
  pushl $0
801079f2:	6a 00                	push   $0x0
  pushl $116
801079f4:	6a 74                	push   $0x74
  jmp alltraps
801079f6:	e9 61 f5 ff ff       	jmp    80106f5c <alltraps>

801079fb <vector117>:
.globl vector117
vector117:
  pushl $0
801079fb:	6a 00                	push   $0x0
  pushl $117
801079fd:	6a 75                	push   $0x75
  jmp alltraps
801079ff:	e9 58 f5 ff ff       	jmp    80106f5c <alltraps>

80107a04 <vector118>:
.globl vector118
vector118:
  pushl $0
80107a04:	6a 00                	push   $0x0
  pushl $118
80107a06:	6a 76                	push   $0x76
  jmp alltraps
80107a08:	e9 4f f5 ff ff       	jmp    80106f5c <alltraps>

80107a0d <vector119>:
.globl vector119
vector119:
  pushl $0
80107a0d:	6a 00                	push   $0x0
  pushl $119
80107a0f:	6a 77                	push   $0x77
  jmp alltraps
80107a11:	e9 46 f5 ff ff       	jmp    80106f5c <alltraps>

80107a16 <vector120>:
.globl vector120
vector120:
  pushl $0
80107a16:	6a 00                	push   $0x0
  pushl $120
80107a18:	6a 78                	push   $0x78
  jmp alltraps
80107a1a:	e9 3d f5 ff ff       	jmp    80106f5c <alltraps>

80107a1f <vector121>:
.globl vector121
vector121:
  pushl $0
80107a1f:	6a 00                	push   $0x0
  pushl $121
80107a21:	6a 79                	push   $0x79
  jmp alltraps
80107a23:	e9 34 f5 ff ff       	jmp    80106f5c <alltraps>

80107a28 <vector122>:
.globl vector122
vector122:
  pushl $0
80107a28:	6a 00                	push   $0x0
  pushl $122
80107a2a:	6a 7a                	push   $0x7a
  jmp alltraps
80107a2c:	e9 2b f5 ff ff       	jmp    80106f5c <alltraps>

80107a31 <vector123>:
.globl vector123
vector123:
  pushl $0
80107a31:	6a 00                	push   $0x0
  pushl $123
80107a33:	6a 7b                	push   $0x7b
  jmp alltraps
80107a35:	e9 22 f5 ff ff       	jmp    80106f5c <alltraps>

80107a3a <vector124>:
.globl vector124
vector124:
  pushl $0
80107a3a:	6a 00                	push   $0x0
  pushl $124
80107a3c:	6a 7c                	push   $0x7c
  jmp alltraps
80107a3e:	e9 19 f5 ff ff       	jmp    80106f5c <alltraps>

80107a43 <vector125>:
.globl vector125
vector125:
  pushl $0
80107a43:	6a 00                	push   $0x0
  pushl $125
80107a45:	6a 7d                	push   $0x7d
  jmp alltraps
80107a47:	e9 10 f5 ff ff       	jmp    80106f5c <alltraps>

80107a4c <vector126>:
.globl vector126
vector126:
  pushl $0
80107a4c:	6a 00                	push   $0x0
  pushl $126
80107a4e:	6a 7e                	push   $0x7e
  jmp alltraps
80107a50:	e9 07 f5 ff ff       	jmp    80106f5c <alltraps>

80107a55 <vector127>:
.globl vector127
vector127:
  pushl $0
80107a55:	6a 00                	push   $0x0
  pushl $127
80107a57:	6a 7f                	push   $0x7f
  jmp alltraps
80107a59:	e9 fe f4 ff ff       	jmp    80106f5c <alltraps>

80107a5e <vector128>:
.globl vector128
vector128:
  pushl $0
80107a5e:	6a 00                	push   $0x0
  pushl $128
80107a60:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107a65:	e9 f2 f4 ff ff       	jmp    80106f5c <alltraps>

80107a6a <vector129>:
.globl vector129
vector129:
  pushl $0
80107a6a:	6a 00                	push   $0x0
  pushl $129
80107a6c:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107a71:	e9 e6 f4 ff ff       	jmp    80106f5c <alltraps>

80107a76 <vector130>:
.globl vector130
vector130:
  pushl $0
80107a76:	6a 00                	push   $0x0
  pushl $130
80107a78:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107a7d:	e9 da f4 ff ff       	jmp    80106f5c <alltraps>

80107a82 <vector131>:
.globl vector131
vector131:
  pushl $0
80107a82:	6a 00                	push   $0x0
  pushl $131
80107a84:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107a89:	e9 ce f4 ff ff       	jmp    80106f5c <alltraps>

80107a8e <vector132>:
.globl vector132
vector132:
  pushl $0
80107a8e:	6a 00                	push   $0x0
  pushl $132
80107a90:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107a95:	e9 c2 f4 ff ff       	jmp    80106f5c <alltraps>

80107a9a <vector133>:
.globl vector133
vector133:
  pushl $0
80107a9a:	6a 00                	push   $0x0
  pushl $133
80107a9c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107aa1:	e9 b6 f4 ff ff       	jmp    80106f5c <alltraps>

80107aa6 <vector134>:
.globl vector134
vector134:
  pushl $0
80107aa6:	6a 00                	push   $0x0
  pushl $134
80107aa8:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107aad:	e9 aa f4 ff ff       	jmp    80106f5c <alltraps>

80107ab2 <vector135>:
.globl vector135
vector135:
  pushl $0
80107ab2:	6a 00                	push   $0x0
  pushl $135
80107ab4:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107ab9:	e9 9e f4 ff ff       	jmp    80106f5c <alltraps>

80107abe <vector136>:
.globl vector136
vector136:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $136
80107ac0:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107ac5:	e9 92 f4 ff ff       	jmp    80106f5c <alltraps>

80107aca <vector137>:
.globl vector137
vector137:
  pushl $0
80107aca:	6a 00                	push   $0x0
  pushl $137
80107acc:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107ad1:	e9 86 f4 ff ff       	jmp    80106f5c <alltraps>

80107ad6 <vector138>:
.globl vector138
vector138:
  pushl $0
80107ad6:	6a 00                	push   $0x0
  pushl $138
80107ad8:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107add:	e9 7a f4 ff ff       	jmp    80106f5c <alltraps>

80107ae2 <vector139>:
.globl vector139
vector139:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $139
80107ae4:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107ae9:	e9 6e f4 ff ff       	jmp    80106f5c <alltraps>

80107aee <vector140>:
.globl vector140
vector140:
  pushl $0
80107aee:	6a 00                	push   $0x0
  pushl $140
80107af0:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107af5:	e9 62 f4 ff ff       	jmp    80106f5c <alltraps>

80107afa <vector141>:
.globl vector141
vector141:
  pushl $0
80107afa:	6a 00                	push   $0x0
  pushl $141
80107afc:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107b01:	e9 56 f4 ff ff       	jmp    80106f5c <alltraps>

80107b06 <vector142>:
.globl vector142
vector142:
  pushl $0
80107b06:	6a 00                	push   $0x0
  pushl $142
80107b08:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107b0d:	e9 4a f4 ff ff       	jmp    80106f5c <alltraps>

80107b12 <vector143>:
.globl vector143
vector143:
  pushl $0
80107b12:	6a 00                	push   $0x0
  pushl $143
80107b14:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107b19:	e9 3e f4 ff ff       	jmp    80106f5c <alltraps>

80107b1e <vector144>:
.globl vector144
vector144:
  pushl $0
80107b1e:	6a 00                	push   $0x0
  pushl $144
80107b20:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107b25:	e9 32 f4 ff ff       	jmp    80106f5c <alltraps>

80107b2a <vector145>:
.globl vector145
vector145:
  pushl $0
80107b2a:	6a 00                	push   $0x0
  pushl $145
80107b2c:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107b31:	e9 26 f4 ff ff       	jmp    80106f5c <alltraps>

80107b36 <vector146>:
.globl vector146
vector146:
  pushl $0
80107b36:	6a 00                	push   $0x0
  pushl $146
80107b38:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107b3d:	e9 1a f4 ff ff       	jmp    80106f5c <alltraps>

80107b42 <vector147>:
.globl vector147
vector147:
  pushl $0
80107b42:	6a 00                	push   $0x0
  pushl $147
80107b44:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107b49:	e9 0e f4 ff ff       	jmp    80106f5c <alltraps>

80107b4e <vector148>:
.globl vector148
vector148:
  pushl $0
80107b4e:	6a 00                	push   $0x0
  pushl $148
80107b50:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107b55:	e9 02 f4 ff ff       	jmp    80106f5c <alltraps>

80107b5a <vector149>:
.globl vector149
vector149:
  pushl $0
80107b5a:	6a 00                	push   $0x0
  pushl $149
80107b5c:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107b61:	e9 f6 f3 ff ff       	jmp    80106f5c <alltraps>

80107b66 <vector150>:
.globl vector150
vector150:
  pushl $0
80107b66:	6a 00                	push   $0x0
  pushl $150
80107b68:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107b6d:	e9 ea f3 ff ff       	jmp    80106f5c <alltraps>

80107b72 <vector151>:
.globl vector151
vector151:
  pushl $0
80107b72:	6a 00                	push   $0x0
  pushl $151
80107b74:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107b79:	e9 de f3 ff ff       	jmp    80106f5c <alltraps>

80107b7e <vector152>:
.globl vector152
vector152:
  pushl $0
80107b7e:	6a 00                	push   $0x0
  pushl $152
80107b80:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107b85:	e9 d2 f3 ff ff       	jmp    80106f5c <alltraps>

80107b8a <vector153>:
.globl vector153
vector153:
  pushl $0
80107b8a:	6a 00                	push   $0x0
  pushl $153
80107b8c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107b91:	e9 c6 f3 ff ff       	jmp    80106f5c <alltraps>

80107b96 <vector154>:
.globl vector154
vector154:
  pushl $0
80107b96:	6a 00                	push   $0x0
  pushl $154
80107b98:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107b9d:	e9 ba f3 ff ff       	jmp    80106f5c <alltraps>

80107ba2 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ba2:	6a 00                	push   $0x0
  pushl $155
80107ba4:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ba9:	e9 ae f3 ff ff       	jmp    80106f5c <alltraps>

80107bae <vector156>:
.globl vector156
vector156:
  pushl $0
80107bae:	6a 00                	push   $0x0
  pushl $156
80107bb0:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107bb5:	e9 a2 f3 ff ff       	jmp    80106f5c <alltraps>

80107bba <vector157>:
.globl vector157
vector157:
  pushl $0
80107bba:	6a 00                	push   $0x0
  pushl $157
80107bbc:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107bc1:	e9 96 f3 ff ff       	jmp    80106f5c <alltraps>

80107bc6 <vector158>:
.globl vector158
vector158:
  pushl $0
80107bc6:	6a 00                	push   $0x0
  pushl $158
80107bc8:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107bcd:	e9 8a f3 ff ff       	jmp    80106f5c <alltraps>

80107bd2 <vector159>:
.globl vector159
vector159:
  pushl $0
80107bd2:	6a 00                	push   $0x0
  pushl $159
80107bd4:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107bd9:	e9 7e f3 ff ff       	jmp    80106f5c <alltraps>

80107bde <vector160>:
.globl vector160
vector160:
  pushl $0
80107bde:	6a 00                	push   $0x0
  pushl $160
80107be0:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107be5:	e9 72 f3 ff ff       	jmp    80106f5c <alltraps>

80107bea <vector161>:
.globl vector161
vector161:
  pushl $0
80107bea:	6a 00                	push   $0x0
  pushl $161
80107bec:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107bf1:	e9 66 f3 ff ff       	jmp    80106f5c <alltraps>

80107bf6 <vector162>:
.globl vector162
vector162:
  pushl $0
80107bf6:	6a 00                	push   $0x0
  pushl $162
80107bf8:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107bfd:	e9 5a f3 ff ff       	jmp    80106f5c <alltraps>

80107c02 <vector163>:
.globl vector163
vector163:
  pushl $0
80107c02:	6a 00                	push   $0x0
  pushl $163
80107c04:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107c09:	e9 4e f3 ff ff       	jmp    80106f5c <alltraps>

80107c0e <vector164>:
.globl vector164
vector164:
  pushl $0
80107c0e:	6a 00                	push   $0x0
  pushl $164
80107c10:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107c15:	e9 42 f3 ff ff       	jmp    80106f5c <alltraps>

80107c1a <vector165>:
.globl vector165
vector165:
  pushl $0
80107c1a:	6a 00                	push   $0x0
  pushl $165
80107c1c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107c21:	e9 36 f3 ff ff       	jmp    80106f5c <alltraps>

80107c26 <vector166>:
.globl vector166
vector166:
  pushl $0
80107c26:	6a 00                	push   $0x0
  pushl $166
80107c28:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107c2d:	e9 2a f3 ff ff       	jmp    80106f5c <alltraps>

80107c32 <vector167>:
.globl vector167
vector167:
  pushl $0
80107c32:	6a 00                	push   $0x0
  pushl $167
80107c34:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107c39:	e9 1e f3 ff ff       	jmp    80106f5c <alltraps>

80107c3e <vector168>:
.globl vector168
vector168:
  pushl $0
80107c3e:	6a 00                	push   $0x0
  pushl $168
80107c40:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107c45:	e9 12 f3 ff ff       	jmp    80106f5c <alltraps>

80107c4a <vector169>:
.globl vector169
vector169:
  pushl $0
80107c4a:	6a 00                	push   $0x0
  pushl $169
80107c4c:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107c51:	e9 06 f3 ff ff       	jmp    80106f5c <alltraps>

80107c56 <vector170>:
.globl vector170
vector170:
  pushl $0
80107c56:	6a 00                	push   $0x0
  pushl $170
80107c58:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107c5d:	e9 fa f2 ff ff       	jmp    80106f5c <alltraps>

80107c62 <vector171>:
.globl vector171
vector171:
  pushl $0
80107c62:	6a 00                	push   $0x0
  pushl $171
80107c64:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107c69:	e9 ee f2 ff ff       	jmp    80106f5c <alltraps>

80107c6e <vector172>:
.globl vector172
vector172:
  pushl $0
80107c6e:	6a 00                	push   $0x0
  pushl $172
80107c70:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107c75:	e9 e2 f2 ff ff       	jmp    80106f5c <alltraps>

80107c7a <vector173>:
.globl vector173
vector173:
  pushl $0
80107c7a:	6a 00                	push   $0x0
  pushl $173
80107c7c:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107c81:	e9 d6 f2 ff ff       	jmp    80106f5c <alltraps>

80107c86 <vector174>:
.globl vector174
vector174:
  pushl $0
80107c86:	6a 00                	push   $0x0
  pushl $174
80107c88:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107c8d:	e9 ca f2 ff ff       	jmp    80106f5c <alltraps>

80107c92 <vector175>:
.globl vector175
vector175:
  pushl $0
80107c92:	6a 00                	push   $0x0
  pushl $175
80107c94:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107c99:	e9 be f2 ff ff       	jmp    80106f5c <alltraps>

80107c9e <vector176>:
.globl vector176
vector176:
  pushl $0
80107c9e:	6a 00                	push   $0x0
  pushl $176
80107ca0:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107ca5:	e9 b2 f2 ff ff       	jmp    80106f5c <alltraps>

80107caa <vector177>:
.globl vector177
vector177:
  pushl $0
80107caa:	6a 00                	push   $0x0
  pushl $177
80107cac:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107cb1:	e9 a6 f2 ff ff       	jmp    80106f5c <alltraps>

80107cb6 <vector178>:
.globl vector178
vector178:
  pushl $0
80107cb6:	6a 00                	push   $0x0
  pushl $178
80107cb8:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107cbd:	e9 9a f2 ff ff       	jmp    80106f5c <alltraps>

80107cc2 <vector179>:
.globl vector179
vector179:
  pushl $0
80107cc2:	6a 00                	push   $0x0
  pushl $179
80107cc4:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107cc9:	e9 8e f2 ff ff       	jmp    80106f5c <alltraps>

80107cce <vector180>:
.globl vector180
vector180:
  pushl $0
80107cce:	6a 00                	push   $0x0
  pushl $180
80107cd0:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107cd5:	e9 82 f2 ff ff       	jmp    80106f5c <alltraps>

80107cda <vector181>:
.globl vector181
vector181:
  pushl $0
80107cda:	6a 00                	push   $0x0
  pushl $181
80107cdc:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107ce1:	e9 76 f2 ff ff       	jmp    80106f5c <alltraps>

80107ce6 <vector182>:
.globl vector182
vector182:
  pushl $0
80107ce6:	6a 00                	push   $0x0
  pushl $182
80107ce8:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107ced:	e9 6a f2 ff ff       	jmp    80106f5c <alltraps>

80107cf2 <vector183>:
.globl vector183
vector183:
  pushl $0
80107cf2:	6a 00                	push   $0x0
  pushl $183
80107cf4:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107cf9:	e9 5e f2 ff ff       	jmp    80106f5c <alltraps>

80107cfe <vector184>:
.globl vector184
vector184:
  pushl $0
80107cfe:	6a 00                	push   $0x0
  pushl $184
80107d00:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107d05:	e9 52 f2 ff ff       	jmp    80106f5c <alltraps>

80107d0a <vector185>:
.globl vector185
vector185:
  pushl $0
80107d0a:	6a 00                	push   $0x0
  pushl $185
80107d0c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107d11:	e9 46 f2 ff ff       	jmp    80106f5c <alltraps>

80107d16 <vector186>:
.globl vector186
vector186:
  pushl $0
80107d16:	6a 00                	push   $0x0
  pushl $186
80107d18:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107d1d:	e9 3a f2 ff ff       	jmp    80106f5c <alltraps>

80107d22 <vector187>:
.globl vector187
vector187:
  pushl $0
80107d22:	6a 00                	push   $0x0
  pushl $187
80107d24:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107d29:	e9 2e f2 ff ff       	jmp    80106f5c <alltraps>

80107d2e <vector188>:
.globl vector188
vector188:
  pushl $0
80107d2e:	6a 00                	push   $0x0
  pushl $188
80107d30:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107d35:	e9 22 f2 ff ff       	jmp    80106f5c <alltraps>

80107d3a <vector189>:
.globl vector189
vector189:
  pushl $0
80107d3a:	6a 00                	push   $0x0
  pushl $189
80107d3c:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107d41:	e9 16 f2 ff ff       	jmp    80106f5c <alltraps>

80107d46 <vector190>:
.globl vector190
vector190:
  pushl $0
80107d46:	6a 00                	push   $0x0
  pushl $190
80107d48:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107d4d:	e9 0a f2 ff ff       	jmp    80106f5c <alltraps>

80107d52 <vector191>:
.globl vector191
vector191:
  pushl $0
80107d52:	6a 00                	push   $0x0
  pushl $191
80107d54:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107d59:	e9 fe f1 ff ff       	jmp    80106f5c <alltraps>

80107d5e <vector192>:
.globl vector192
vector192:
  pushl $0
80107d5e:	6a 00                	push   $0x0
  pushl $192
80107d60:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107d65:	e9 f2 f1 ff ff       	jmp    80106f5c <alltraps>

80107d6a <vector193>:
.globl vector193
vector193:
  pushl $0
80107d6a:	6a 00                	push   $0x0
  pushl $193
80107d6c:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107d71:	e9 e6 f1 ff ff       	jmp    80106f5c <alltraps>

80107d76 <vector194>:
.globl vector194
vector194:
  pushl $0
80107d76:	6a 00                	push   $0x0
  pushl $194
80107d78:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107d7d:	e9 da f1 ff ff       	jmp    80106f5c <alltraps>

80107d82 <vector195>:
.globl vector195
vector195:
  pushl $0
80107d82:	6a 00                	push   $0x0
  pushl $195
80107d84:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107d89:	e9 ce f1 ff ff       	jmp    80106f5c <alltraps>

80107d8e <vector196>:
.globl vector196
vector196:
  pushl $0
80107d8e:	6a 00                	push   $0x0
  pushl $196
80107d90:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107d95:	e9 c2 f1 ff ff       	jmp    80106f5c <alltraps>

80107d9a <vector197>:
.globl vector197
vector197:
  pushl $0
80107d9a:	6a 00                	push   $0x0
  pushl $197
80107d9c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107da1:	e9 b6 f1 ff ff       	jmp    80106f5c <alltraps>

80107da6 <vector198>:
.globl vector198
vector198:
  pushl $0
80107da6:	6a 00                	push   $0x0
  pushl $198
80107da8:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107dad:	e9 aa f1 ff ff       	jmp    80106f5c <alltraps>

80107db2 <vector199>:
.globl vector199
vector199:
  pushl $0
80107db2:	6a 00                	push   $0x0
  pushl $199
80107db4:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107db9:	e9 9e f1 ff ff       	jmp    80106f5c <alltraps>

80107dbe <vector200>:
.globl vector200
vector200:
  pushl $0
80107dbe:	6a 00                	push   $0x0
  pushl $200
80107dc0:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107dc5:	e9 92 f1 ff ff       	jmp    80106f5c <alltraps>

80107dca <vector201>:
.globl vector201
vector201:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $201
80107dcc:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107dd1:	e9 86 f1 ff ff       	jmp    80106f5c <alltraps>

80107dd6 <vector202>:
.globl vector202
vector202:
  pushl $0
80107dd6:	6a 00                	push   $0x0
  pushl $202
80107dd8:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107ddd:	e9 7a f1 ff ff       	jmp    80106f5c <alltraps>

80107de2 <vector203>:
.globl vector203
vector203:
  pushl $0
80107de2:	6a 00                	push   $0x0
  pushl $203
80107de4:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107de9:	e9 6e f1 ff ff       	jmp    80106f5c <alltraps>

80107dee <vector204>:
.globl vector204
vector204:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $204
80107df0:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80107df5:	e9 62 f1 ff ff       	jmp    80106f5c <alltraps>

80107dfa <vector205>:
.globl vector205
vector205:
  pushl $0
80107dfa:	6a 00                	push   $0x0
  pushl $205
80107dfc:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107e01:	e9 56 f1 ff ff       	jmp    80106f5c <alltraps>

80107e06 <vector206>:
.globl vector206
vector206:
  pushl $0
80107e06:	6a 00                	push   $0x0
  pushl $206
80107e08:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107e0d:	e9 4a f1 ff ff       	jmp    80106f5c <alltraps>

80107e12 <vector207>:
.globl vector207
vector207:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $207
80107e14:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107e19:	e9 3e f1 ff ff       	jmp    80106f5c <alltraps>

80107e1e <vector208>:
.globl vector208
vector208:
  pushl $0
80107e1e:	6a 00                	push   $0x0
  pushl $208
80107e20:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107e25:	e9 32 f1 ff ff       	jmp    80106f5c <alltraps>

80107e2a <vector209>:
.globl vector209
vector209:
  pushl $0
80107e2a:	6a 00                	push   $0x0
  pushl $209
80107e2c:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107e31:	e9 26 f1 ff ff       	jmp    80106f5c <alltraps>

80107e36 <vector210>:
.globl vector210
vector210:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $210
80107e38:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107e3d:	e9 1a f1 ff ff       	jmp    80106f5c <alltraps>

80107e42 <vector211>:
.globl vector211
vector211:
  pushl $0
80107e42:	6a 00                	push   $0x0
  pushl $211
80107e44:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107e49:	e9 0e f1 ff ff       	jmp    80106f5c <alltraps>

80107e4e <vector212>:
.globl vector212
vector212:
  pushl $0
80107e4e:	6a 00                	push   $0x0
  pushl $212
80107e50:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107e55:	e9 02 f1 ff ff       	jmp    80106f5c <alltraps>

80107e5a <vector213>:
.globl vector213
vector213:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $213
80107e5c:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107e61:	e9 f6 f0 ff ff       	jmp    80106f5c <alltraps>

80107e66 <vector214>:
.globl vector214
vector214:
  pushl $0
80107e66:	6a 00                	push   $0x0
  pushl $214
80107e68:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107e6d:	e9 ea f0 ff ff       	jmp    80106f5c <alltraps>

80107e72 <vector215>:
.globl vector215
vector215:
  pushl $0
80107e72:	6a 00                	push   $0x0
  pushl $215
80107e74:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107e79:	e9 de f0 ff ff       	jmp    80106f5c <alltraps>

80107e7e <vector216>:
.globl vector216
vector216:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $216
80107e80:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107e85:	e9 d2 f0 ff ff       	jmp    80106f5c <alltraps>

80107e8a <vector217>:
.globl vector217
vector217:
  pushl $0
80107e8a:	6a 00                	push   $0x0
  pushl $217
80107e8c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107e91:	e9 c6 f0 ff ff       	jmp    80106f5c <alltraps>

80107e96 <vector218>:
.globl vector218
vector218:
  pushl $0
80107e96:	6a 00                	push   $0x0
  pushl $218
80107e98:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107e9d:	e9 ba f0 ff ff       	jmp    80106f5c <alltraps>

80107ea2 <vector219>:
.globl vector219
vector219:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $219
80107ea4:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107ea9:	e9 ae f0 ff ff       	jmp    80106f5c <alltraps>

80107eae <vector220>:
.globl vector220
vector220:
  pushl $0
80107eae:	6a 00                	push   $0x0
  pushl $220
80107eb0:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107eb5:	e9 a2 f0 ff ff       	jmp    80106f5c <alltraps>

80107eba <vector221>:
.globl vector221
vector221:
  pushl $0
80107eba:	6a 00                	push   $0x0
  pushl $221
80107ebc:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107ec1:	e9 96 f0 ff ff       	jmp    80106f5c <alltraps>

80107ec6 <vector222>:
.globl vector222
vector222:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $222
80107ec8:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107ecd:	e9 8a f0 ff ff       	jmp    80106f5c <alltraps>

80107ed2 <vector223>:
.globl vector223
vector223:
  pushl $0
80107ed2:	6a 00                	push   $0x0
  pushl $223
80107ed4:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107ed9:	e9 7e f0 ff ff       	jmp    80106f5c <alltraps>

80107ede <vector224>:
.globl vector224
vector224:
  pushl $0
80107ede:	6a 00                	push   $0x0
  pushl $224
80107ee0:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80107ee5:	e9 72 f0 ff ff       	jmp    80106f5c <alltraps>

80107eea <vector225>:
.globl vector225
vector225:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $225
80107eec:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107ef1:	e9 66 f0 ff ff       	jmp    80106f5c <alltraps>

80107ef6 <vector226>:
.globl vector226
vector226:
  pushl $0
80107ef6:	6a 00                	push   $0x0
  pushl $226
80107ef8:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107efd:	e9 5a f0 ff ff       	jmp    80106f5c <alltraps>

80107f02 <vector227>:
.globl vector227
vector227:
  pushl $0
80107f02:	6a 00                	push   $0x0
  pushl $227
80107f04:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107f09:	e9 4e f0 ff ff       	jmp    80106f5c <alltraps>

80107f0e <vector228>:
.globl vector228
vector228:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $228
80107f10:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107f15:	e9 42 f0 ff ff       	jmp    80106f5c <alltraps>

80107f1a <vector229>:
.globl vector229
vector229:
  pushl $0
80107f1a:	6a 00                	push   $0x0
  pushl $229
80107f1c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107f21:	e9 36 f0 ff ff       	jmp    80106f5c <alltraps>

80107f26 <vector230>:
.globl vector230
vector230:
  pushl $0
80107f26:	6a 00                	push   $0x0
  pushl $230
80107f28:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107f2d:	e9 2a f0 ff ff       	jmp    80106f5c <alltraps>

80107f32 <vector231>:
.globl vector231
vector231:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $231
80107f34:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107f39:	e9 1e f0 ff ff       	jmp    80106f5c <alltraps>

80107f3e <vector232>:
.globl vector232
vector232:
  pushl $0
80107f3e:	6a 00                	push   $0x0
  pushl $232
80107f40:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107f45:	e9 12 f0 ff ff       	jmp    80106f5c <alltraps>

80107f4a <vector233>:
.globl vector233
vector233:
  pushl $0
80107f4a:	6a 00                	push   $0x0
  pushl $233
80107f4c:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107f51:	e9 06 f0 ff ff       	jmp    80106f5c <alltraps>

80107f56 <vector234>:
.globl vector234
vector234:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $234
80107f58:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107f5d:	e9 fa ef ff ff       	jmp    80106f5c <alltraps>

80107f62 <vector235>:
.globl vector235
vector235:
  pushl $0
80107f62:	6a 00                	push   $0x0
  pushl $235
80107f64:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107f69:	e9 ee ef ff ff       	jmp    80106f5c <alltraps>

80107f6e <vector236>:
.globl vector236
vector236:
  pushl $0
80107f6e:	6a 00                	push   $0x0
  pushl $236
80107f70:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107f75:	e9 e2 ef ff ff       	jmp    80106f5c <alltraps>

80107f7a <vector237>:
.globl vector237
vector237:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $237
80107f7c:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107f81:	e9 d6 ef ff ff       	jmp    80106f5c <alltraps>

80107f86 <vector238>:
.globl vector238
vector238:
  pushl $0
80107f86:	6a 00                	push   $0x0
  pushl $238
80107f88:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107f8d:	e9 ca ef ff ff       	jmp    80106f5c <alltraps>

80107f92 <vector239>:
.globl vector239
vector239:
  pushl $0
80107f92:	6a 00                	push   $0x0
  pushl $239
80107f94:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107f99:	e9 be ef ff ff       	jmp    80106f5c <alltraps>

80107f9e <vector240>:
.globl vector240
vector240:
  pushl $0
80107f9e:	6a 00                	push   $0x0
  pushl $240
80107fa0:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107fa5:	e9 b2 ef ff ff       	jmp    80106f5c <alltraps>

80107faa <vector241>:
.globl vector241
vector241:
  pushl $0
80107faa:	6a 00                	push   $0x0
  pushl $241
80107fac:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107fb1:	e9 a6 ef ff ff       	jmp    80106f5c <alltraps>

80107fb6 <vector242>:
.globl vector242
vector242:
  pushl $0
80107fb6:	6a 00                	push   $0x0
  pushl $242
80107fb8:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107fbd:	e9 9a ef ff ff       	jmp    80106f5c <alltraps>

80107fc2 <vector243>:
.globl vector243
vector243:
  pushl $0
80107fc2:	6a 00                	push   $0x0
  pushl $243
80107fc4:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107fc9:	e9 8e ef ff ff       	jmp    80106f5c <alltraps>

80107fce <vector244>:
.globl vector244
vector244:
  pushl $0
80107fce:	6a 00                	push   $0x0
  pushl $244
80107fd0:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107fd5:	e9 82 ef ff ff       	jmp    80106f5c <alltraps>

80107fda <vector245>:
.globl vector245
vector245:
  pushl $0
80107fda:	6a 00                	push   $0x0
  pushl $245
80107fdc:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107fe1:	e9 76 ef ff ff       	jmp    80106f5c <alltraps>

80107fe6 <vector246>:
.globl vector246
vector246:
  pushl $0
80107fe6:	6a 00                	push   $0x0
  pushl $246
80107fe8:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107fed:	e9 6a ef ff ff       	jmp    80106f5c <alltraps>

80107ff2 <vector247>:
.globl vector247
vector247:
  pushl $0
80107ff2:	6a 00                	push   $0x0
  pushl $247
80107ff4:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107ff9:	e9 5e ef ff ff       	jmp    80106f5c <alltraps>

80107ffe <vector248>:
.globl vector248
vector248:
  pushl $0
80107ffe:	6a 00                	push   $0x0
  pushl $248
80108000:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108005:	e9 52 ef ff ff       	jmp    80106f5c <alltraps>

8010800a <vector249>:
.globl vector249
vector249:
  pushl $0
8010800a:	6a 00                	push   $0x0
  pushl $249
8010800c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108011:	e9 46 ef ff ff       	jmp    80106f5c <alltraps>

80108016 <vector250>:
.globl vector250
vector250:
  pushl $0
80108016:	6a 00                	push   $0x0
  pushl $250
80108018:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010801d:	e9 3a ef ff ff       	jmp    80106f5c <alltraps>

80108022 <vector251>:
.globl vector251
vector251:
  pushl $0
80108022:	6a 00                	push   $0x0
  pushl $251
80108024:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108029:	e9 2e ef ff ff       	jmp    80106f5c <alltraps>

8010802e <vector252>:
.globl vector252
vector252:
  pushl $0
8010802e:	6a 00                	push   $0x0
  pushl $252
80108030:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108035:	e9 22 ef ff ff       	jmp    80106f5c <alltraps>

8010803a <vector253>:
.globl vector253
vector253:
  pushl $0
8010803a:	6a 00                	push   $0x0
  pushl $253
8010803c:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108041:	e9 16 ef ff ff       	jmp    80106f5c <alltraps>

80108046 <vector254>:
.globl vector254
vector254:
  pushl $0
80108046:	6a 00                	push   $0x0
  pushl $254
80108048:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010804d:	e9 0a ef ff ff       	jmp    80106f5c <alltraps>

80108052 <vector255>:
.globl vector255
vector255:
  pushl $0
80108052:	6a 00                	push   $0x0
  pushl $255
80108054:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108059:	e9 fe ee ff ff       	jmp    80106f5c <alltraps>
	...

80108060 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108060:	55                   	push   %ebp
80108061:	89 e5                	mov    %esp,%ebp
80108063:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108066:	8b 45 0c             	mov    0xc(%ebp),%eax
80108069:	83 e8 01             	sub    $0x1,%eax
8010806c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108070:	8b 45 08             	mov    0x8(%ebp),%eax
80108073:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108077:	8b 45 08             	mov    0x8(%ebp),%eax
8010807a:	c1 e8 10             	shr    $0x10,%eax
8010807d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108081:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108084:	0f 01 10             	lgdtl  (%eax)
}
80108087:	c9                   	leave  
80108088:	c3                   	ret    

80108089 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108089:	55                   	push   %ebp
8010808a:	89 e5                	mov    %esp,%ebp
8010808c:	83 ec 04             	sub    $0x4,%esp
8010808f:	8b 45 08             	mov    0x8(%ebp),%eax
80108092:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80108096:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010809a:	0f 00 d8             	ltr    %ax
}
8010809d:	c9                   	leave  
8010809e:	c3                   	ret    

8010809f <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010809f:	55                   	push   %ebp
801080a0:	89 e5                	mov    %esp,%ebp
801080a2:	83 ec 04             	sub    $0x4,%esp
801080a5:	8b 45 08             	mov    0x8(%ebp),%eax
801080a8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801080ac:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801080b0:	8e e8                	mov    %eax,%gs
}
801080b2:	c9                   	leave  
801080b3:	c3                   	ret    

801080b4 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801080b4:	55                   	push   %ebp
801080b5:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801080b7:	8b 45 08             	mov    0x8(%ebp),%eax
801080ba:	0f 22 d8             	mov    %eax,%cr3
}
801080bd:	5d                   	pop    %ebp
801080be:	c3                   	ret    

801080bf <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801080bf:	55                   	push   %ebp
801080c0:	89 e5                	mov    %esp,%ebp
801080c2:	8b 45 08             	mov    0x8(%ebp),%eax
801080c5:	05 00 00 00 80       	add    $0x80000000,%eax
801080ca:	5d                   	pop    %ebp
801080cb:	c3                   	ret    

801080cc <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801080cc:	55                   	push   %ebp
801080cd:	89 e5                	mov    %esp,%ebp
801080cf:	8b 45 08             	mov    0x8(%ebp),%eax
801080d2:	05 00 00 00 80       	add    $0x80000000,%eax
801080d7:	5d                   	pop    %ebp
801080d8:	c3                   	ret    

801080d9 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801080d9:	55                   	push   %ebp
801080da:	89 e5                	mov    %esp,%ebp
801080dc:	53                   	push   %ebx
801080dd:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801080e0:	e8 4c b9 ff ff       	call   80103a31 <cpunum>
801080e5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801080eb:	05 40 09 11 80       	add    $0x80110940,%eax
801080f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801080f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f6:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801080fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ff:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108108:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010810c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010810f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108113:	83 e2 f0             	and    $0xfffffff0,%edx
80108116:	83 ca 0a             	or     $0xa,%edx
80108119:	88 50 7d             	mov    %dl,0x7d(%eax)
8010811c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010811f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108123:	83 ca 10             	or     $0x10,%edx
80108126:	88 50 7d             	mov    %dl,0x7d(%eax)
80108129:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108130:	83 e2 9f             	and    $0xffffff9f,%edx
80108133:	88 50 7d             	mov    %dl,0x7d(%eax)
80108136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108139:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010813d:	83 ca 80             	or     $0xffffff80,%edx
80108140:	88 50 7d             	mov    %dl,0x7d(%eax)
80108143:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108146:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010814a:	83 ca 0f             	or     $0xf,%edx
8010814d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108153:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108157:	83 e2 ef             	and    $0xffffffef,%edx
8010815a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010815d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108160:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108164:	83 e2 df             	and    $0xffffffdf,%edx
80108167:	88 50 7e             	mov    %dl,0x7e(%eax)
8010816a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010816d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108171:	83 ca 40             	or     $0x40,%edx
80108174:	88 50 7e             	mov    %dl,0x7e(%eax)
80108177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010817a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010817e:	83 ca 80             	or     $0xffffff80,%edx
80108181:	88 50 7e             	mov    %dl,0x7e(%eax)
80108184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108187:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010818b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010818e:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108195:	ff ff 
80108197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819a:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801081a1:	00 00 
801081a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a6:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801081ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081b0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081b7:	83 e2 f0             	and    $0xfffffff0,%edx
801081ba:	83 ca 02             	or     $0x2,%edx
801081bd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081c6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081cd:	83 ca 10             	or     $0x10,%edx
801081d0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081e0:	83 e2 9f             	and    $0xffffff9f,%edx
801081e3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ec:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801081f3:	83 ca 80             	or     $0xffffff80,%edx
801081f6:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801081fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ff:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108206:	83 ca 0f             	or     $0xf,%edx
80108209:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010820f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108212:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108219:	83 e2 ef             	and    $0xffffffef,%edx
8010821c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108222:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108225:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010822c:	83 e2 df             	and    $0xffffffdf,%edx
8010822f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108238:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010823f:	83 ca 40             	or     $0x40,%edx
80108242:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108248:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010824b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108252:	83 ca 80             	or     $0xffffff80,%edx
80108255:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010825b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010825e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108265:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108268:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010826f:	ff ff 
80108271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108274:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010827b:	00 00 
8010827d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108280:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108287:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108291:	83 e2 f0             	and    $0xfffffff0,%edx
80108294:	83 ca 0a             	or     $0xa,%edx
80108297:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010829d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082a0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082a7:	83 ca 10             	or     $0x10,%edx
801082aa:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082ba:	83 ca 60             	or     $0x60,%edx
801082bd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082c6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801082cd:	83 ca 80             	or     $0xffffff80,%edx
801082d0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801082d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082d9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801082e0:	83 ca 0f             	or     $0xf,%edx
801082e3:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801082e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ec:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801082f3:	83 e2 ef             	and    $0xffffffef,%edx
801082f6:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801082fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ff:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108306:	83 e2 df             	and    $0xffffffdf,%edx
80108309:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010830f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108312:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108319:	83 ca 40             	or     $0x40,%edx
8010831c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108322:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108325:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010832c:	83 ca 80             	or     $0xffffff80,%edx
8010832f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108335:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108338:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010833f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108342:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108349:	ff ff 
8010834b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108355:	00 00 
80108357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010835a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108361:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108364:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010836b:	83 e2 f0             	and    $0xfffffff0,%edx
8010836e:	83 ca 02             	or     $0x2,%edx
80108371:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010837a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108381:	83 ca 10             	or     $0x10,%edx
80108384:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010838a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010838d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108394:	83 ca 60             	or     $0x60,%edx
80108397:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010839d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083a0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801083a7:	83 ca 80             	or     $0xffffff80,%edx
801083aa:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801083b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083b3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083ba:	83 ca 0f             	or     $0xf,%edx
801083bd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083cd:	83 e2 ef             	and    $0xffffffef,%edx
801083d0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083e0:	83 e2 df             	and    $0xffffffdf,%edx
801083e3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ec:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801083f3:	83 ca 40             	or     $0x40,%edx
801083f6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801083fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ff:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108406:	83 ca 80             	or     $0xffffff80,%edx
80108409:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010840f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108412:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108419:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010841c:	05 b4 00 00 00       	add    $0xb4,%eax
80108421:	89 c3                	mov    %eax,%ebx
80108423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108426:	05 b4 00 00 00       	add    $0xb4,%eax
8010842b:	c1 e8 10             	shr    $0x10,%eax
8010842e:	89 c1                	mov    %eax,%ecx
80108430:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108433:	05 b4 00 00 00       	add    $0xb4,%eax
80108438:	c1 e8 18             	shr    $0x18,%eax
8010843b:	89 c2                	mov    %eax,%edx
8010843d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108440:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108447:	00 00 
80108449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108453:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108456:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010845c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108466:	83 e1 f0             	and    $0xfffffff0,%ecx
80108469:	83 c9 02             	or     $0x2,%ecx
8010846c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108472:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108475:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010847c:	83 c9 10             	or     $0x10,%ecx
8010847f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108488:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010848f:	83 e1 9f             	and    $0xffffff9f,%ecx
80108492:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108498:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801084a2:	83 c9 80             	or     $0xffffff80,%ecx
801084a5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801084ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ae:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084b5:	83 e1 f0             	and    $0xfffffff0,%ecx
801084b8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084c1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084c8:	83 e1 ef             	and    $0xffffffef,%ecx
801084cb:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084db:	83 e1 df             	and    $0xffffffdf,%ecx
801084de:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801084ee:	83 c9 40             	or     $0x40,%ecx
801084f1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801084f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084fa:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108501:	83 c9 80             	or     $0xffffff80,%ecx
80108504:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010850a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850d:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108513:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108516:	83 c0 70             	add    $0x70,%eax
80108519:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108520:	00 
80108521:	89 04 24             	mov    %eax,(%esp)
80108524:	e8 37 fb ff ff       	call   80108060 <lgdt>
  loadgs(SEG_KCPU << 3);
80108529:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108530:	e8 6a fb ff ff       	call   8010809f <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108538:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010853e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108545:	00 00 00 00 
}
80108549:	83 c4 24             	add    $0x24,%esp
8010854c:	5b                   	pop    %ebx
8010854d:	5d                   	pop    %ebp
8010854e:	c3                   	ret    

8010854f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010854f:	55                   	push   %ebp
80108550:	89 e5                	mov    %esp,%ebp
80108552:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108555:	8b 45 0c             	mov    0xc(%ebp),%eax
80108558:	c1 e8 16             	shr    $0x16,%eax
8010855b:	c1 e0 02             	shl    $0x2,%eax
8010855e:	03 45 08             	add    0x8(%ebp),%eax
80108561:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108564:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108567:	8b 00                	mov    (%eax),%eax
80108569:	83 e0 01             	and    $0x1,%eax
8010856c:	84 c0                	test   %al,%al
8010856e:	74 17                	je     80108587 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108573:	8b 00                	mov    (%eax),%eax
80108575:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010857a:	89 04 24             	mov    %eax,(%esp)
8010857d:	e8 4a fb ff ff       	call   801080cc <p2v>
80108582:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108585:	eb 4b                	jmp    801085d2 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108587:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010858b:	74 0e                	je     8010859b <walkpgdir+0x4c>
8010858d:	e8 11 b1 ff ff       	call   801036a3 <kalloc>
80108592:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108595:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108599:	75 07                	jne    801085a2 <walkpgdir+0x53>
      return 0;
8010859b:	b8 00 00 00 00       	mov    $0x0,%eax
801085a0:	eb 41                	jmp    801085e3 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801085a2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801085a9:	00 
801085aa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801085b1:	00 
801085b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b5:	89 04 24             	mov    %eax,(%esp)
801085b8:	e8 d9 d3 ff ff       	call   80105996 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801085bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085c0:	89 04 24             	mov    %eax,(%esp)
801085c3:	e8 f7 fa ff ff       	call   801080bf <v2p>
801085c8:	89 c2                	mov    %eax,%edx
801085ca:	83 ca 07             	or     $0x7,%edx
801085cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085d0:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801085d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801085d5:	c1 e8 0c             	shr    $0xc,%eax
801085d8:	25 ff 03 00 00       	and    $0x3ff,%eax
801085dd:	c1 e0 02             	shl    $0x2,%eax
801085e0:	03 45 f4             	add    -0xc(%ebp),%eax
}
801085e3:	c9                   	leave  
801085e4:	c3                   	ret    

801085e5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801085e5:	55                   	push   %ebp
801085e6:	89 e5                	mov    %esp,%ebp
801085e8:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801085eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801085ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801085f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801085f6:	8b 45 0c             	mov    0xc(%ebp),%eax
801085f9:	03 45 10             	add    0x10(%ebp),%eax
801085fc:	83 e8 01             	sub    $0x1,%eax
801085ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108604:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108607:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010860e:	00 
8010860f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108612:	89 44 24 04          	mov    %eax,0x4(%esp)
80108616:	8b 45 08             	mov    0x8(%ebp),%eax
80108619:	89 04 24             	mov    %eax,(%esp)
8010861c:	e8 2e ff ff ff       	call   8010854f <walkpgdir>
80108621:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108624:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108628:	75 07                	jne    80108631 <mappages+0x4c>
      return -1;
8010862a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010862f:	eb 46                	jmp    80108677 <mappages+0x92>
    if(*pte & PTE_P)
80108631:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108634:	8b 00                	mov    (%eax),%eax
80108636:	83 e0 01             	and    $0x1,%eax
80108639:	84 c0                	test   %al,%al
8010863b:	74 0c                	je     80108649 <mappages+0x64>
      panic("remap");
8010863d:	c7 04 24 04 95 10 80 	movl   $0x80109504,(%esp)
80108644:	e8 f4 7e ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108649:	8b 45 18             	mov    0x18(%ebp),%eax
8010864c:	0b 45 14             	or     0x14(%ebp),%eax
8010864f:	89 c2                	mov    %eax,%edx
80108651:	83 ca 01             	or     $0x1,%edx
80108654:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108657:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108659:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010865c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010865f:	74 10                	je     80108671 <mappages+0x8c>
      break;
    a += PGSIZE;
80108661:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108668:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010866f:	eb 96                	jmp    80108607 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108671:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108672:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108677:	c9                   	leave  
80108678:	c3                   	ret    

80108679 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108679:	55                   	push   %ebp
8010867a:	89 e5                	mov    %esp,%ebp
8010867c:	53                   	push   %ebx
8010867d:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108680:	e8 1e b0 ff ff       	call   801036a3 <kalloc>
80108685:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108688:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010868c:	75 0a                	jne    80108698 <setupkvm+0x1f>
    return 0;
8010868e:	b8 00 00 00 00       	mov    $0x0,%eax
80108693:	e9 98 00 00 00       	jmp    80108730 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108698:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010869f:	00 
801086a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801086a7:	00 
801086a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801086ab:	89 04 24             	mov    %eax,(%esp)
801086ae:	e8 e3 d2 ff ff       	call   80105996 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801086b3:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801086ba:	e8 0d fa ff ff       	call   801080cc <p2v>
801086bf:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801086c4:	76 0c                	jbe    801086d2 <setupkvm+0x59>
    panic("PHYSTOP too high");
801086c6:	c7 04 24 0a 95 10 80 	movl   $0x8010950a,(%esp)
801086cd:	e8 6b 7e ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801086d2:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
801086d9:	eb 49                	jmp    80108724 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801086db:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801086de:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801086e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801086e4:	8b 50 04             	mov    0x4(%eax),%edx
801086e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ea:	8b 58 08             	mov    0x8(%eax),%ebx
801086ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f0:	8b 40 04             	mov    0x4(%eax),%eax
801086f3:	29 c3                	sub    %eax,%ebx
801086f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f8:	8b 00                	mov    (%eax),%eax
801086fa:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801086fe:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108702:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108706:	89 44 24 04          	mov    %eax,0x4(%esp)
8010870a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010870d:	89 04 24             	mov    %eax,(%esp)
80108710:	e8 d0 fe ff ff       	call   801085e5 <mappages>
80108715:	85 c0                	test   %eax,%eax
80108717:	79 07                	jns    80108720 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108719:	b8 00 00 00 00       	mov    $0x0,%eax
8010871e:	eb 10                	jmp    80108730 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108720:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108724:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
8010872b:	72 ae                	jb     801086db <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
8010872d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108730:	83 c4 34             	add    $0x34,%esp
80108733:	5b                   	pop    %ebx
80108734:	5d                   	pop    %ebp
80108735:	c3                   	ret    

80108736 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108736:	55                   	push   %ebp
80108737:	89 e5                	mov    %esp,%ebp
80108739:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010873c:	e8 38 ff ff ff       	call   80108679 <setupkvm>
80108741:	a3 18 37 11 80       	mov    %eax,0x80113718
  switchkvm();
80108746:	e8 02 00 00 00       	call   8010874d <switchkvm>
}
8010874b:	c9                   	leave  
8010874c:	c3                   	ret    

8010874d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
8010874d:	55                   	push   %ebp
8010874e:	89 e5                	mov    %esp,%ebp
80108750:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108753:	a1 18 37 11 80       	mov    0x80113718,%eax
80108758:	89 04 24             	mov    %eax,(%esp)
8010875b:	e8 5f f9 ff ff       	call   801080bf <v2p>
80108760:	89 04 24             	mov    %eax,(%esp)
80108763:	e8 4c f9 ff ff       	call   801080b4 <lcr3>
}
80108768:	c9                   	leave  
80108769:	c3                   	ret    

8010876a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010876a:	55                   	push   %ebp
8010876b:	89 e5                	mov    %esp,%ebp
8010876d:	53                   	push   %ebx
8010876e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108771:	e8 19 d1 ff ff       	call   8010588f <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108776:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010877c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108783:	83 c2 08             	add    $0x8,%edx
80108786:	89 d3                	mov    %edx,%ebx
80108788:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010878f:	83 c2 08             	add    $0x8,%edx
80108792:	c1 ea 10             	shr    $0x10,%edx
80108795:	89 d1                	mov    %edx,%ecx
80108797:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010879e:	83 c2 08             	add    $0x8,%edx
801087a1:	c1 ea 18             	shr    $0x18,%edx
801087a4:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801087ab:	67 00 
801087ad:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801087b4:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801087ba:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087c1:	83 e1 f0             	and    $0xfffffff0,%ecx
801087c4:	83 c9 09             	or     $0x9,%ecx
801087c7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801087cd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087d4:	83 c9 10             	or     $0x10,%ecx
801087d7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801087dd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087e4:	83 e1 9f             	and    $0xffffff9f,%ecx
801087e7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801087ed:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801087f4:	83 c9 80             	or     $0xffffff80,%ecx
801087f7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801087fd:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108804:	83 e1 f0             	and    $0xfffffff0,%ecx
80108807:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010880d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108814:	83 e1 ef             	and    $0xffffffef,%ecx
80108817:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010881d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108824:	83 e1 df             	and    $0xffffffdf,%ecx
80108827:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010882d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108834:	83 c9 40             	or     $0x40,%ecx
80108837:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010883d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108844:	83 e1 7f             	and    $0x7f,%ecx
80108847:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
8010884d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108853:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108859:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108860:	83 e2 ef             	and    $0xffffffef,%edx
80108863:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108869:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010886f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108875:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010887b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108882:	8b 52 08             	mov    0x8(%edx),%edx
80108885:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010888b:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010888e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108895:	e8 ef f7 ff ff       	call   80108089 <ltr>
  if(p->pgdir == 0)
8010889a:	8b 45 08             	mov    0x8(%ebp),%eax
8010889d:	8b 40 04             	mov    0x4(%eax),%eax
801088a0:	85 c0                	test   %eax,%eax
801088a2:	75 0c                	jne    801088b0 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801088a4:	c7 04 24 1b 95 10 80 	movl   $0x8010951b,(%esp)
801088ab:	e8 8d 7c ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801088b0:	8b 45 08             	mov    0x8(%ebp),%eax
801088b3:	8b 40 04             	mov    0x4(%eax),%eax
801088b6:	89 04 24             	mov    %eax,(%esp)
801088b9:	e8 01 f8 ff ff       	call   801080bf <v2p>
801088be:	89 04 24             	mov    %eax,(%esp)
801088c1:	e8 ee f7 ff ff       	call   801080b4 <lcr3>
  popcli();
801088c6:	e8 0c d0 ff ff       	call   801058d7 <popcli>
}
801088cb:	83 c4 14             	add    $0x14,%esp
801088ce:	5b                   	pop    %ebx
801088cf:	5d                   	pop    %ebp
801088d0:	c3                   	ret    

801088d1 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801088d1:	55                   	push   %ebp
801088d2:	89 e5                	mov    %esp,%ebp
801088d4:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801088d7:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801088de:	76 0c                	jbe    801088ec <inituvm+0x1b>
    panic("inituvm: more than a page");
801088e0:	c7 04 24 2f 95 10 80 	movl   $0x8010952f,(%esp)
801088e7:	e8 51 7c ff ff       	call   8010053d <panic>
  mem = kalloc();
801088ec:	e8 b2 ad ff ff       	call   801036a3 <kalloc>
801088f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801088f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801088fb:	00 
801088fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108903:	00 
80108904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108907:	89 04 24             	mov    %eax,(%esp)
8010890a:	e8 87 d0 ff ff       	call   80105996 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010890f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108912:	89 04 24             	mov    %eax,(%esp)
80108915:	e8 a5 f7 ff ff       	call   801080bf <v2p>
8010891a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108921:	00 
80108922:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108926:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010892d:	00 
8010892e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108935:	00 
80108936:	8b 45 08             	mov    0x8(%ebp),%eax
80108939:	89 04 24             	mov    %eax,(%esp)
8010893c:	e8 a4 fc ff ff       	call   801085e5 <mappages>
  memmove(mem, init, sz);
80108941:	8b 45 10             	mov    0x10(%ebp),%eax
80108944:	89 44 24 08          	mov    %eax,0x8(%esp)
80108948:	8b 45 0c             	mov    0xc(%ebp),%eax
8010894b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010894f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108952:	89 04 24             	mov    %eax,(%esp)
80108955:	e8 0f d1 ff ff       	call   80105a69 <memmove>
}
8010895a:	c9                   	leave  
8010895b:	c3                   	ret    

8010895c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010895c:	55                   	push   %ebp
8010895d:	89 e5                	mov    %esp,%ebp
8010895f:	53                   	push   %ebx
80108960:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108963:	8b 45 0c             	mov    0xc(%ebp),%eax
80108966:	25 ff 0f 00 00       	and    $0xfff,%eax
8010896b:	85 c0                	test   %eax,%eax
8010896d:	74 0c                	je     8010897b <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010896f:	c7 04 24 4c 95 10 80 	movl   $0x8010954c,(%esp)
80108976:	e8 c2 7b ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
8010897b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108982:	e9 ad 00 00 00       	jmp    80108a34 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010898a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010898d:	01 d0                	add    %edx,%eax
8010898f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108996:	00 
80108997:	89 44 24 04          	mov    %eax,0x4(%esp)
8010899b:	8b 45 08             	mov    0x8(%ebp),%eax
8010899e:	89 04 24             	mov    %eax,(%esp)
801089a1:	e8 a9 fb ff ff       	call   8010854f <walkpgdir>
801089a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
801089a9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801089ad:	75 0c                	jne    801089bb <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801089af:	c7 04 24 6f 95 10 80 	movl   $0x8010956f,(%esp)
801089b6:	e8 82 7b ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801089bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801089be:	8b 00                	mov    (%eax),%eax
801089c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801089c5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801089c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089cb:	8b 55 18             	mov    0x18(%ebp),%edx
801089ce:	89 d1                	mov    %edx,%ecx
801089d0:	29 c1                	sub    %eax,%ecx
801089d2:	89 c8                	mov    %ecx,%eax
801089d4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801089d9:	77 11                	ja     801089ec <loaduvm+0x90>
      n = sz - i;
801089db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089de:	8b 55 18             	mov    0x18(%ebp),%edx
801089e1:	89 d1                	mov    %edx,%ecx
801089e3:	29 c1                	sub    %eax,%ecx
801089e5:	89 c8                	mov    %ecx,%eax
801089e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801089ea:	eb 07                	jmp    801089f3 <loaduvm+0x97>
    else
      n = PGSIZE;
801089ec:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801089f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f6:	8b 55 14             	mov    0x14(%ebp),%edx
801089f9:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801089fc:	8b 45 e8             	mov    -0x18(%ebp),%eax
801089ff:	89 04 24             	mov    %eax,(%esp)
80108a02:	e8 c5 f6 ff ff       	call   801080cc <p2v>
80108a07:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108a0a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108a0e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108a12:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a16:	8b 45 10             	mov    0x10(%ebp),%eax
80108a19:	89 04 24             	mov    %eax,(%esp)
80108a1c:	e8 bd 9d ff ff       	call   801027de <readi>
80108a21:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108a24:	74 07                	je     80108a2d <loaduvm+0xd1>
      return -1;
80108a26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108a2b:	eb 18                	jmp    80108a45 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108a2d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a37:	3b 45 18             	cmp    0x18(%ebp),%eax
80108a3a:	0f 82 47 ff ff ff    	jb     80108987 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108a40:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108a45:	83 c4 24             	add    $0x24,%esp
80108a48:	5b                   	pop    %ebx
80108a49:	5d                   	pop    %ebp
80108a4a:	c3                   	ret    

80108a4b <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108a4b:	55                   	push   %ebp
80108a4c:	89 e5                	mov    %esp,%ebp
80108a4e:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108a51:	8b 45 10             	mov    0x10(%ebp),%eax
80108a54:	85 c0                	test   %eax,%eax
80108a56:	79 0a                	jns    80108a62 <allocuvm+0x17>
    return 0;
80108a58:	b8 00 00 00 00       	mov    $0x0,%eax
80108a5d:	e9 c1 00 00 00       	jmp    80108b23 <allocuvm+0xd8>
  if(newsz < oldsz)
80108a62:	8b 45 10             	mov    0x10(%ebp),%eax
80108a65:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108a68:	73 08                	jae    80108a72 <allocuvm+0x27>
    return oldsz;
80108a6a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a6d:	e9 b1 00 00 00       	jmp    80108b23 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108a72:	8b 45 0c             	mov    0xc(%ebp),%eax
80108a75:	05 ff 0f 00 00       	add    $0xfff,%eax
80108a7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108a7f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108a82:	e9 8d 00 00 00       	jmp    80108b14 <allocuvm+0xc9>
    mem = kalloc();
80108a87:	e8 17 ac ff ff       	call   801036a3 <kalloc>
80108a8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108a8f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108a93:	75 2c                	jne    80108ac1 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108a95:	c7 04 24 8d 95 10 80 	movl   $0x8010958d,(%esp)
80108a9c:	e8 00 79 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108aa1:	8b 45 0c             	mov    0xc(%ebp),%eax
80108aa4:	89 44 24 08          	mov    %eax,0x8(%esp)
80108aa8:	8b 45 10             	mov    0x10(%ebp),%eax
80108aab:	89 44 24 04          	mov    %eax,0x4(%esp)
80108aaf:	8b 45 08             	mov    0x8(%ebp),%eax
80108ab2:	89 04 24             	mov    %eax,(%esp)
80108ab5:	e8 6b 00 00 00       	call   80108b25 <deallocuvm>
      return 0;
80108aba:	b8 00 00 00 00       	mov    $0x0,%eax
80108abf:	eb 62                	jmp    80108b23 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108ac1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ac8:	00 
80108ac9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ad0:	00 
80108ad1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ad4:	89 04 24             	mov    %eax,(%esp)
80108ad7:	e8 ba ce ff ff       	call   80105996 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108adc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108adf:	89 04 24             	mov    %eax,(%esp)
80108ae2:	e8 d8 f5 ff ff       	call   801080bf <v2p>
80108ae7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108aea:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108af1:	00 
80108af2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108af6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108afd:	00 
80108afe:	89 54 24 04          	mov    %edx,0x4(%esp)
80108b02:	8b 45 08             	mov    0x8(%ebp),%eax
80108b05:	89 04 24             	mov    %eax,(%esp)
80108b08:	e8 d8 fa ff ff       	call   801085e5 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108b0d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108b14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b17:	3b 45 10             	cmp    0x10(%ebp),%eax
80108b1a:	0f 82 67 ff ff ff    	jb     80108a87 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108b20:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108b23:	c9                   	leave  
80108b24:	c3                   	ret    

80108b25 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108b25:	55                   	push   %ebp
80108b26:	89 e5                	mov    %esp,%ebp
80108b28:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108b2b:	8b 45 10             	mov    0x10(%ebp),%eax
80108b2e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108b31:	72 08                	jb     80108b3b <deallocuvm+0x16>
    return oldsz;
80108b33:	8b 45 0c             	mov    0xc(%ebp),%eax
80108b36:	e9 a4 00 00 00       	jmp    80108bdf <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108b3b:	8b 45 10             	mov    0x10(%ebp),%eax
80108b3e:	05 ff 0f 00 00       	add    $0xfff,%eax
80108b43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b48:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108b4b:	e9 80 00 00 00       	jmp    80108bd0 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b53:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108b5a:	00 
80108b5b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108b5f:	8b 45 08             	mov    0x8(%ebp),%eax
80108b62:	89 04 24             	mov    %eax,(%esp)
80108b65:	e8 e5 f9 ff ff       	call   8010854f <walkpgdir>
80108b6a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108b6d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108b71:	75 09                	jne    80108b7c <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108b73:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108b7a:	eb 4d                	jmp    80108bc9 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108b7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b7f:	8b 00                	mov    (%eax),%eax
80108b81:	83 e0 01             	and    $0x1,%eax
80108b84:	84 c0                	test   %al,%al
80108b86:	74 41                	je     80108bc9 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108b88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108b8b:	8b 00                	mov    (%eax),%eax
80108b8d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108b92:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108b95:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108b99:	75 0c                	jne    80108ba7 <deallocuvm+0x82>
        panic("kfree");
80108b9b:	c7 04 24 a5 95 10 80 	movl   $0x801095a5,(%esp)
80108ba2:	e8 96 79 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108ba7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108baa:	89 04 24             	mov    %eax,(%esp)
80108bad:	e8 1a f5 ff ff       	call   801080cc <p2v>
80108bb2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108bb5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108bb8:	89 04 24             	mov    %eax,(%esp)
80108bbb:	e8 4a aa ff ff       	call   8010360a <kfree>
      *pte = 0;
80108bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bc3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108bc9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108bd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108bd6:	0f 82 74 ff ff ff    	jb     80108b50 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108bdc:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108bdf:	c9                   	leave  
80108be0:	c3                   	ret    

80108be1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108be1:	55                   	push   %ebp
80108be2:	89 e5                	mov    %esp,%ebp
80108be4:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108be7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108beb:	75 0c                	jne    80108bf9 <freevm+0x18>
    panic("freevm: no pgdir");
80108bed:	c7 04 24 ab 95 10 80 	movl   $0x801095ab,(%esp)
80108bf4:	e8 44 79 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108bf9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108c00:	00 
80108c01:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108c08:	80 
80108c09:	8b 45 08             	mov    0x8(%ebp),%eax
80108c0c:	89 04 24             	mov    %eax,(%esp)
80108c0f:	e8 11 ff ff ff       	call   80108b25 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108c14:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108c1b:	eb 3c                	jmp    80108c59 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c20:	c1 e0 02             	shl    $0x2,%eax
80108c23:	03 45 08             	add    0x8(%ebp),%eax
80108c26:	8b 00                	mov    (%eax),%eax
80108c28:	83 e0 01             	and    $0x1,%eax
80108c2b:	84 c0                	test   %al,%al
80108c2d:	74 26                	je     80108c55 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c32:	c1 e0 02             	shl    $0x2,%eax
80108c35:	03 45 08             	add    0x8(%ebp),%eax
80108c38:	8b 00                	mov    (%eax),%eax
80108c3a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c3f:	89 04 24             	mov    %eax,(%esp)
80108c42:	e8 85 f4 ff ff       	call   801080cc <p2v>
80108c47:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108c4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c4d:	89 04 24             	mov    %eax,(%esp)
80108c50:	e8 b5 a9 ff ff       	call   8010360a <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108c55:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108c59:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108c60:	76 bb                	jbe    80108c1d <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108c62:	8b 45 08             	mov    0x8(%ebp),%eax
80108c65:	89 04 24             	mov    %eax,(%esp)
80108c68:	e8 9d a9 ff ff       	call   8010360a <kfree>
}
80108c6d:	c9                   	leave  
80108c6e:	c3                   	ret    

80108c6f <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108c6f:	55                   	push   %ebp
80108c70:	89 e5                	mov    %esp,%ebp
80108c72:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108c75:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108c7c:	00 
80108c7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c80:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c84:	8b 45 08             	mov    0x8(%ebp),%eax
80108c87:	89 04 24             	mov    %eax,(%esp)
80108c8a:	e8 c0 f8 ff ff       	call   8010854f <walkpgdir>
80108c8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108c92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108c96:	75 0c                	jne    80108ca4 <clearpteu+0x35>
    panic("clearpteu");
80108c98:	c7 04 24 bc 95 10 80 	movl   $0x801095bc,(%esp)
80108c9f:	e8 99 78 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ca7:	8b 00                	mov    (%eax),%eax
80108ca9:	89 c2                	mov    %eax,%edx
80108cab:	83 e2 fb             	and    $0xfffffffb,%edx
80108cae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cb1:	89 10                	mov    %edx,(%eax)
}
80108cb3:	c9                   	leave  
80108cb4:	c3                   	ret    

80108cb5 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108cb5:	55                   	push   %ebp
80108cb6:	89 e5                	mov    %esp,%ebp
80108cb8:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108cbb:	e8 b9 f9 ff ff       	call   80108679 <setupkvm>
80108cc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108cc3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108cc7:	75 0a                	jne    80108cd3 <copyuvm+0x1e>
    return 0;
80108cc9:	b8 00 00 00 00       	mov    $0x0,%eax
80108cce:	e9 f1 00 00 00       	jmp    80108dc4 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108cd3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108cda:	e9 c0 00 00 00       	jmp    80108d9f <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ce9:	00 
80108cea:	89 44 24 04          	mov    %eax,0x4(%esp)
80108cee:	8b 45 08             	mov    0x8(%ebp),%eax
80108cf1:	89 04 24             	mov    %eax,(%esp)
80108cf4:	e8 56 f8 ff ff       	call   8010854f <walkpgdir>
80108cf9:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108cfc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d00:	75 0c                	jne    80108d0e <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80108d02:	c7 04 24 c6 95 10 80 	movl   $0x801095c6,(%esp)
80108d09:	e8 2f 78 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80108d0e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d11:	8b 00                	mov    (%eax),%eax
80108d13:	83 e0 01             	and    $0x1,%eax
80108d16:	85 c0                	test   %eax,%eax
80108d18:	75 0c                	jne    80108d26 <copyuvm+0x71>
      panic("copyuvm: page not present");
80108d1a:	c7 04 24 e0 95 10 80 	movl   $0x801095e0,(%esp)
80108d21:	e8 17 78 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108d26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d29:	8b 00                	mov    (%eax),%eax
80108d2b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d30:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80108d33:	e8 6b a9 ff ff       	call   801036a3 <kalloc>
80108d38:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108d3b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80108d3f:	74 6f                	je     80108db0 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80108d41:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d44:	89 04 24             	mov    %eax,(%esp)
80108d47:	e8 80 f3 ff ff       	call   801080cc <p2v>
80108d4c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108d53:	00 
80108d54:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d5b:	89 04 24             	mov    %eax,(%esp)
80108d5e:	e8 06 cd ff ff       	call   80105a69 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80108d63:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108d66:	89 04 24             	mov    %eax,(%esp)
80108d69:	e8 51 f3 ff ff       	call   801080bf <v2p>
80108d6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108d71:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108d78:	00 
80108d79:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108d7d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108d84:	00 
80108d85:	89 54 24 04          	mov    %edx,0x4(%esp)
80108d89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d8c:	89 04 24             	mov    %eax,(%esp)
80108d8f:	e8 51 f8 ff ff       	call   801085e5 <mappages>
80108d94:	85 c0                	test   %eax,%eax
80108d96:	78 1b                	js     80108db3 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108d98:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108da2:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108da5:	0f 82 34 ff ff ff    	jb     80108cdf <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108dab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108dae:	eb 14                	jmp    80108dc4 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108db0:	90                   	nop
80108db1:	eb 01                	jmp    80108db4 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80108db3:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108db4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108db7:	89 04 24             	mov    %eax,(%esp)
80108dba:	e8 22 fe ff ff       	call   80108be1 <freevm>
  return 0;
80108dbf:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108dc4:	c9                   	leave  
80108dc5:	c3                   	ret    

80108dc6 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108dc6:	55                   	push   %ebp
80108dc7:	89 e5                	mov    %esp,%ebp
80108dc9:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108dcc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108dd3:	00 
80108dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80108dd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80108dde:	89 04 24             	mov    %eax,(%esp)
80108de1:	e8 69 f7 ff ff       	call   8010854f <walkpgdir>
80108de6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dec:	8b 00                	mov    (%eax),%eax
80108dee:	83 e0 01             	and    $0x1,%eax
80108df1:	85 c0                	test   %eax,%eax
80108df3:	75 07                	jne    80108dfc <uva2ka+0x36>
    return 0;
80108df5:	b8 00 00 00 00       	mov    $0x0,%eax
80108dfa:	eb 25                	jmp    80108e21 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108dfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108dff:	8b 00                	mov    (%eax),%eax
80108e01:	83 e0 04             	and    $0x4,%eax
80108e04:	85 c0                	test   %eax,%eax
80108e06:	75 07                	jne    80108e0f <uva2ka+0x49>
    return 0;
80108e08:	b8 00 00 00 00       	mov    $0x0,%eax
80108e0d:	eb 12                	jmp    80108e21 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e12:	8b 00                	mov    (%eax),%eax
80108e14:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e19:	89 04 24             	mov    %eax,(%esp)
80108e1c:	e8 ab f2 ff ff       	call   801080cc <p2v>
}
80108e21:	c9                   	leave  
80108e22:	c3                   	ret    

80108e23 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108e23:	55                   	push   %ebp
80108e24:	89 e5                	mov    %esp,%ebp
80108e26:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108e29:	8b 45 10             	mov    0x10(%ebp),%eax
80108e2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80108e2f:	e9 8b 00 00 00       	jmp    80108ebf <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108e34:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e3c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80108e3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e42:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e46:	8b 45 08             	mov    0x8(%ebp),%eax
80108e49:	89 04 24             	mov    %eax,(%esp)
80108e4c:	e8 75 ff ff ff       	call   80108dc6 <uva2ka>
80108e51:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108e54:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108e58:	75 07                	jne    80108e61 <copyout+0x3e>
      return -1;
80108e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108e5f:	eb 6d                	jmp    80108ece <copyout+0xab>
    n = PGSIZE - (va - va0);
80108e61:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e64:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108e67:	89 d1                	mov    %edx,%ecx
80108e69:	29 c1                	sub    %eax,%ecx
80108e6b:	89 c8                	mov    %ecx,%eax
80108e6d:	05 00 10 00 00       	add    $0x1000,%eax
80108e72:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e78:	3b 45 14             	cmp    0x14(%ebp),%eax
80108e7b:	76 06                	jbe    80108e83 <copyout+0x60>
      n = len;
80108e7d:	8b 45 14             	mov    0x14(%ebp),%eax
80108e80:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80108e83:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108e86:	8b 55 0c             	mov    0xc(%ebp),%edx
80108e89:	89 d1                	mov    %edx,%ecx
80108e8b:	29 c1                	sub    %eax,%ecx
80108e8d:	89 c8                	mov    %ecx,%eax
80108e8f:	03 45 e8             	add    -0x18(%ebp),%eax
80108e92:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108e95:	89 54 24 08          	mov    %edx,0x8(%esp)
80108e99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108e9c:	89 54 24 04          	mov    %edx,0x4(%esp)
80108ea0:	89 04 24             	mov    %eax,(%esp)
80108ea3:	e8 c1 cb ff ff       	call   80105a69 <memmove>
    len -= n;
80108ea8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eab:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108eae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eb1:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108eb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108eb7:	05 00 10 00 00       	add    $0x1000,%eax
80108ebc:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108ebf:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108ec3:	0f 85 6b ff ff ff    	jne    80108e34 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108ec9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108ece:	c9                   	leave  
80108ecf:	c3                   	ret    

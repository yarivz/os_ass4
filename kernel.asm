
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
8010002d:	b8 b7 42 10 80       	mov    $0x801042b7,%eax
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
8010003a:	c7 44 24 04 dc 91 10 	movl   $0x801091dc,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 e4 59 00 00       	call   80105a32 <initlock>

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
801000bd:	e8 91 59 00 00       	call   80105a53 <acquire>

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
80100104:	e8 ac 59 00 00       	call   80105ab5 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 51 56 00 00       	call   80105775 <sleep>
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
8010017c:	e8 34 59 00 00       	call   80105ab5 <release>
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
80100198:	c7 04 24 e3 91 10 80 	movl   $0x801091e3,(%esp)
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
801001d3:	e8 8c 34 00 00       	call   80103664 <iderw>
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
801001ef:	c7 04 24 f4 91 10 80 	movl   $0x801091f4,(%esp)
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
80100210:	e8 4f 34 00 00       	call   80103664 <iderw>
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
80100229:	c7 04 24 fb 91 10 80 	movl   $0x801091fb,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 12 58 00 00       	call   80105a53 <acquire>

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
8010029d:	e8 ac 55 00 00       	call   8010584e <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 07 58 00 00       	call   80105ab5 <release>
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
801003bc:	e8 92 56 00 00       	call   80105a53 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 02 92 10 80 	movl   $0x80109202,(%esp)
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
801004af:	c7 45 ec 0b 92 10 80 	movl   $0x8010920b,-0x14(%ebp)
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
80100536:	e8 7a 55 00 00       	call   80105ab5 <release>
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
80100562:	c7 04 24 12 92 10 80 	movl   $0x80109212,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 21 92 10 80 	movl   $0x80109221,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 6d 55 00 00       	call   80105b04 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 23 92 10 80 	movl   $0x80109223,(%esp)
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
801006b2:	e8 be 56 00 00       	call   80105d75 <memmove>
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
801006e1:	e8 bc 55 00 00       	call   80105ca2 <memset>
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
80100776:	e8 c6 70 00 00       	call   80107841 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 ba 70 00 00       	call   80107841 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 ae 70 00 00       	call   80107841 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 a1 70 00 00       	call   80107841 <uartputc>
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
801007ba:	e8 94 52 00 00       	call   80105a53 <acquire>
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
801007ea:	e8 02 51 00 00       	call   801058f1 <procdump>
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
801008f7:	e8 52 4f 00 00       	call   8010584e <wakeup>
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
8010091e:	e8 92 51 00 00       	call   80105ab5 <release>
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
80100931:	e8 0c 1c 00 00       	call   80102542 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 0b 51 00 00       	call   80105a53 <acquire>
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
80100961:	e8 4f 51 00 00       	call   80105ab5 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 83 1a 00 00       	call   801023f4 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 e6 4d 00 00       	call   80105775 <sleep>
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
80100a08:	e8 a8 50 00 00       	call   80105ab5 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 dc 19 00 00       	call   801023f4 <ilock>

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
80100a32:	e8 0b 1b 00 00       	call   80102542 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 10 50 00 00       	call   80105a53 <acquire>
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
80100a78:	e8 38 50 00 00       	call   80105ab5 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 6c 19 00 00       	call   801023f4 <ilock>

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
80100a93:	c7 44 24 04 27 92 10 	movl   $0x80109227,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 8b 4f 00 00       	call   80105a32 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 2f 92 10 	movl   $0x8010922f,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 77 4f 00 00       	call   80105a32 <initlock>

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
80100ae0:	e8 8c 3e 00 00       	call   80104971 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 2d 2d 00 00       	call   80103826 <ioapicenable>
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
80100b0b:	e8 86 24 00 00       	call   80102f96 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 c6 18 00 00       	call   801023f4 <ilock>
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
80100b55:	e8 90 1d 00 00       	call   801028ea <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 af 39 10 80 	movl   $0x801039af,(%esp)
80100b7b:	e8 05 7e 00 00       	call   80108985 <setupkvm>
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
80100bc8:	e8 1d 1d 00 00       	call   801028ea <readi>
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
80100c14:	e8 3e 81 00 00       	call   80108d57 <allocuvm>
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
80100c51:	e8 12 80 00 00       	call   80108c68 <loaduvm>
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
80100c87:	e8 ec 19 00 00       	call   80102678 <iunlockput>
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
80100cbc:	e8 96 80 00 00       	call   80108d57 <allocuvm>
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
80100ce0:	e8 96 82 00 00       	call   80108f7b <clearpteu>
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
80100d0f:	e8 0c 52 00 00       	call   80105f20 <strlen>
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
80100d2d:	e8 ee 51 00 00       	call   80105f20 <strlen>
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
80100d57:	e8 d3 83 00 00       	call   8010912f <copyout>
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
80100df7:	e8 33 83 00 00       	call   8010912f <copyout>
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
80100e4e:	e8 7f 50 00 00       	call   80105ed2 <safestrcpy>

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
80100ea0:	e8 d1 7b 00 00       	call   80108a76 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 3d 80 00 00       	call   80108eed <freevm>
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
80100ee2:	e8 06 80 00 00       	call   80108eed <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 80 17 00 00       	call   80102678 <iunlockput>
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
80100f06:	c7 44 24 04 38 92 10 	movl   $0x80109238,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 18 4b 00 00       	call   80105a32 <initlock>
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
80100f29:	e8 25 4b 00 00       	call   80105a53 <acquire>
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
80100f52:	e8 5e 4b 00 00       	call   80105ab5 <release>
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
80100f70:	e8 40 4b 00 00       	call   80105ab5 <release>
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
80100f89:	e8 c5 4a 00 00       	call   80105a53 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 3f 92 10 80 	movl   $0x8010923f,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 f6 4a 00 00       	call   80105ab5 <release>
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
80100fd1:	e8 7d 4a 00 00       	call   80105a53 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 47 92 10 80 	movl   $0x80109247,(%esp)
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
8010100c:	e8 a4 4a 00 00       	call   80105ab5 <release>
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
80101056:	e8 5a 4a 00 00       	call   80105ab5 <release>
  
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
80101074:	e8 b2 3b 00 00       	call   80104c2b <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 45 30 00 00       	call   801040cd <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 14 15 00 00       	call   801025a7 <iput>
    commit_trans();
80101093:	e8 7e 30 00 00       	call   80104116 <commit_trans>
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
801010b3:	e8 3c 13 00 00       	call   801023f4 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 d8 17 00 00       	call   801028a5 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 67 14 00 00       	call   80102542 <iunlock>
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
80101125:	e8 83 3c 00 00       	call   80104dad <piperead>
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
8010113f:	e8 b0 12 00 00       	call   801023f4 <ilock>
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
80101165:	e8 80 17 00 00       	call   801028ea <readi>
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
8010118d:	e8 b0 13 00 00       	call   80102542 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 51 92 10 80 	movl   $0x80109251,(%esp)
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
801011e2:	e8 d6 3a 00 00       	call   80104cbd <pipewrite>
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
8010122a:	e8 9e 2e 00 00       	call   801040cd <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 b7 11 00 00       	call   801023f4 <ilock>
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
80101263:	e8 ed 17 00 00       	call   80102a55 <writei>
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
8010128b:	e8 b2 12 00 00       	call   80102542 <iunlock>
      commit_trans();
80101290:	e8 81 2e 00 00       	call   80104116 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 5a 92 10 80 	movl   $0x8010925a,(%esp)
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
801012d8:	c7 04 24 6a 92 10 80 	movl   $0x8010926a,(%esp)
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
801012fe:	e8 ce 56 00 00       	call   801069d1 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 74 92 10 80 	movl   $0x80109274,(%esp)
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
80101338:	e8 b7 10 00 00       	call   801023f4 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 8c 92 10 80 	movl   $0x8010928c,(%esp)
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
80101382:	c7 04 24 af 92 10 80 	movl   $0x801092af,(%esp)
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
801013b7:	c7 04 24 c8 92 10 80 	movl   $0x801092c8,(%esp)
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
80101414:	c7 04 24 e7 92 10 80 	movl   $0x801092e7,(%esp)
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
8010143b:	e8 02 11 00 00       	call   80102542 <iunlock>
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
8010146a:	e8 f1 09 00 00       	call   80101e60 <readsb>
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
8010153e:	c7 04 24 00 93 10 80 	movl   $0x80109300,(%esp)
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
  int ref = getBlkRef(b1->sector);
8010161b:	8b 45 10             	mov    0x10(%ebp),%eax
8010161e:	8b 40 08             	mov    0x8(%eax),%eax
80101621:	89 04 24             	mov    %eax,(%esp)
80101624:	e8 63 1c 00 00       	call   8010328c <getBlkRef>
80101629:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(ref > 1)
8010162c:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101630:	7e 18                	jle    8010164a <deletedups+0xad>
    updateBlkRef(b1->sector,-1);
80101632:	8b 45 10             	mov    0x10(%ebp),%eax
80101635:	8b 40 08             	mov    0x8(%eax),%eax
80101638:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
8010163f:	ff 
80101640:	89 04 24             	mov    %eax,(%esp)
80101643:	e8 15 1b 00 00       	call   8010315d <updateBlkRef>
80101648:	eb 28                	jmp    80101672 <deletedups+0xd5>
  else if(ref == 1)
8010164a:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
8010164e:	75 22                	jne    80101672 <deletedups+0xd5>
  {
    begin_trans();
80101650:	e8 78 2a 00 00       	call   801040cd <begin_trans>
    bfree(b1->dev, b1->sector);
80101655:	8b 45 10             	mov    0x10(%ebp),%eax
80101658:	8b 50 08             	mov    0x8(%eax),%edx
8010165b:	8b 45 10             	mov    0x10(%ebp),%eax
8010165e:	8b 40 04             	mov    0x4(%eax),%eax
80101661:	89 54 24 04          	mov    %edx,0x4(%esp)
80101665:	89 04 24             	mov    %eax,(%esp)
80101668:	e8 f9 09 00 00       	call   80102066 <bfree>
    commit_trans();
8010166d:	e8 a4 2a 00 00       	call   80104116 <commit_trans>
  }
}
80101672:	c9                   	leave  
80101673:	c3                   	ret    

80101674 <dedup>:

int
dedup(void)
{
80101674:	55                   	push   %ebp
80101675:	89 e5                	mov    %esp,%ebp
80101677:	81 ec 98 00 00 00    	sub    $0x98,%esp
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0, iChanged;
8010167d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101684:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
8010168b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101692:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
80101699:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  struct inode* ip1=0, *ip2=0;
801016a0:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
801016a7:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
801016ae:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
801016b5:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
801016bc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
801016c3:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  uint *a = 0, *b = 0;
801016ca:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
801016d1:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  struct superblock sb;
  readsb(1, &sb);
801016d8:	8d 45 94             	lea    -0x6c(%ebp),%eax
801016db:	89 44 24 04          	mov    %eax,0x4(%esp)
801016df:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801016e6:	e8 75 07 00 00       	call   80101e60 <readsb>
  ninodes = sb.ninodes;
801016eb:	8b 45 9c             	mov    -0x64(%ebp),%eax
801016ee:	89 45 c0             	mov    %eax,-0x40(%ebp)
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
801016f1:	e9 51 07 00 00       	jmp    80101e47 <dedup+0x7d3>
  {  cprintf("in first while ip1->inum = %d\n",ip1->inum);
801016f6:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016f9:	8b 40 04             	mov    0x4(%eax),%eax
801016fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80101700:	c7 04 24 1c 93 10 80 	movl   $0x8010931c,(%esp)
80101707:	e8 95 ec ff ff       	call   801003a1 <cprintf>
    iChanged = 0;
8010170c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
80101713:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101716:	89 04 24             	mov    %eax,(%esp)
80101719:	e8 d6 0c 00 00       	call   801023f4 <ilock>
    if(ip1->addrs[NDIRECT])
8010171e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101721:	8b 40 4c             	mov    0x4c(%eax),%eax
80101724:	85 c0                	test   %eax,%eax
80101726:	74 2a                	je     80101752 <dedup+0xde>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
80101728:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010172b:	8b 50 4c             	mov    0x4c(%eax),%edx
8010172e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101731:	8b 00                	mov    (%eax),%eax
80101733:	89 54 24 04          	mov    %edx,0x4(%esp)
80101737:	89 04 24             	mov    %eax,(%esp)
8010173a:	e8 67 ea ff ff       	call   801001a6 <bread>
8010173f:	89 45 d8             	mov    %eax,-0x28(%ebp)
      a = (uint*)bp1->data;
80101742:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101745:	83 c0 18             	add    $0x18,%eax
80101748:	89 45 d0             	mov    %eax,-0x30(%ebp)
      indirects1 = NINDIRECT;
8010174b:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101752:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101759:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101760:	e9 80 06 00 00       	jmp    80101de5 <dedup+0x771>
    {cprintf("in first for blockIndex1 = %d\n",blockIndex1);
80101765:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101768:	89 44 24 04          	mov    %eax,0x4(%esp)
8010176c:	c7 04 24 3c 93 10 80 	movl   $0x8010933c,(%esp)
80101773:	e8 29 ec ff ff       	call   801003a1 <cprintf>
      if(blockIndex1<NDIRECT)							// in the same file
80101778:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
8010177c:	0f 8f 29 02 00 00    	jg     801019ab <dedup+0x337>
      {
	if(ip1->addrs[blockIndex1])
80101782:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101785:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101788:	83 c2 04             	add    $0x4,%edx
8010178b:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010178f:	85 c0                	test   %eax,%eax
80101791:	0f 84 08 02 00 00    	je     8010199f <dedup+0x32b>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
80101797:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010179a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010179d:	83 c2 04             	add    $0x4,%edx
801017a0:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017a4:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017a7:	8b 00                	mov    (%eax),%eax
801017a9:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ad:	89 04 24             	mov    %eax,(%esp)
801017b0:	e8 f1 e9 ff ff       	call   801001a6 <bread>
801017b5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801017b8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017bb:	83 c0 0b             	add    $0xb,%eax
801017be:	89 45 f0             	mov    %eax,-0x10(%ebp)
801017c1:	e9 c8 01 00 00       	jmp    8010198e <dedup+0x31a>
	  {
	    if(blockIndex2 < NDIRECT)
801017c6:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
801017ca:	0f 8f d8 00 00 00    	jg     801018a8 <dedup+0x234>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
801017d0:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017d6:	83 c2 04             	add    $0x4,%edx
801017d9:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017dd:	85 c0                	test   %eax,%eax
801017df:	0f 84 a5 01 00 00    	je     8010198a <dedup+0x316>
801017e5:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017e8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801017eb:	83 c2 04             	add    $0x4,%edx
801017ee:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017f2:	85 c0                	test   %eax,%eax
801017f4:	0f 84 90 01 00 00    	je     8010198a <dedup+0x316>
	      {//cprintf("in 2nd for if\n");
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
801017fa:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017fd:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101800:	83 c2 04             	add    $0x4,%edx
80101803:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101807:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010180a:	8b 00                	mov    (%eax),%eax
8010180c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101810:	89 04 24             	mov    %eax,(%esp)
80101813:	e8 8e e9 ff ff       	call   801001a6 <bread>
80101818:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		//cprintf("before blkcmp 1\n");
		if(blkcmp(b1,b2))
8010181b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010181e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101822:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101825:	89 04 24             	mov    %eax,(%esp)
80101828:	e8 28 fd ff ff       	call   80101555 <blkcmp>
8010182d:	85 c0                	test   %eax,%eax
8010182f:	74 67                	je     80101898 <dedup+0x224>
		{//cprintf("after blkcmp\n");
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
80101831:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101838:	00 
80101839:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101840:	00 
80101841:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101844:	89 44 24 14          	mov    %eax,0x14(%esp)
80101848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184b:	89 44 24 10          	mov    %eax,0x10(%esp)
8010184f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101852:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101856:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101859:	89 44 24 08          	mov    %eax,0x8(%esp)
8010185d:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101860:	89 44 24 04          	mov    %eax,0x4(%esp)
80101864:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101867:	89 04 24             	mov    %eax,(%esp)
8010186a:	e8 2e fd ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
8010186f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101872:	89 04 24             	mov    %eax,(%esp)
80101875:	e8 9d e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
8010187a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010187d:	89 04 24             	mov    %eax,(%esp)
80101880:	e8 92 e9 ff ff       	call   80100217 <brelse>
		  found = 1;
80101885:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
8010188c:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101893:	e9 42 02 00 00       	jmp    80101ada <dedup+0x466>
		}
		brelse(b2);
80101898:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010189b:	89 04 24             	mov    %eax,(%esp)
8010189e:	e8 74 e9 ff ff       	call   80100217 <brelse>
801018a3:	e9 e2 00 00 00       	jmp    8010198a <dedup+0x316>
	      }
	    }
	    else if(a)
801018a8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
801018ac:	0f 84 d8 00 00 00    	je     8010198a <dedup+0x316>
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
801018b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b5:	83 e8 0c             	sub    $0xc,%eax
801018b8:	89 45 b0             	mov    %eax,-0x50(%ebp)
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset])
801018bb:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801018c1:	83 c2 04             	add    $0x4,%edx
801018c4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 ba 00 00 00    	je     8010198a <dedup+0x316>
801018d0:	8b 45 b0             	mov    -0x50(%ebp),%eax
801018d3:	c1 e0 02             	shl    $0x2,%eax
801018d6:	03 45 d0             	add    -0x30(%ebp),%eax
801018d9:	8b 00                	mov    (%eax),%eax
801018db:	85 c0                	test   %eax,%eax
801018dd:	0f 84 a7 00 00 00    	je     8010198a <dedup+0x316>
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);//cprintf("before blkcmp 2\n");
801018e3:	8b 45 b0             	mov    -0x50(%ebp),%eax
801018e6:	c1 e0 02             	shl    $0x2,%eax
801018e9:	03 45 d0             	add    -0x30(%ebp),%eax
801018ec:	8b 10                	mov    (%eax),%edx
801018ee:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018f1:	8b 00                	mov    (%eax),%eax
801018f3:	89 54 24 04          	mov    %edx,0x4(%esp)
801018f7:	89 04 24             	mov    %eax,(%esp)
801018fa:	e8 a7 e8 ff ff       	call   801001a6 <bread>
801018ff:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101902:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101905:	89 44 24 04          	mov    %eax,0x4(%esp)
80101909:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010190c:	89 04 24             	mov    %eax,(%esp)
8010190f:	e8 41 fc ff ff       	call   80101555 <blkcmp>
80101914:	85 c0                	test   %eax,%eax
80101916:	74 67                	je     8010197f <dedup+0x30b>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
80101918:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010191b:	89 44 24 1c          	mov    %eax,0x1c(%esp)
8010191f:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101926:	00 
80101927:	8b 45 b0             	mov    -0x50(%ebp),%eax
8010192a:	89 44 24 14          	mov    %eax,0x14(%esp)
8010192e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101931:	89 44 24 10          	mov    %eax,0x10(%esp)
80101935:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101938:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010193c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010193f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101943:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101946:	89 44 24 04          	mov    %eax,0x4(%esp)
8010194a:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010194d:	89 04 24             	mov    %eax,(%esp)
80101950:	e8 48 fc ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101955:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101958:	89 04 24             	mov    %eax,(%esp)
8010195b:	e8 b7 e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101960:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101963:	89 04 24             	mov    %eax,(%esp)
80101966:	e8 ac e8 ff ff       	call   80100217 <brelse>
		  found = 1;
8010196b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101972:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101979:	90                   	nop
8010197a:	e9 5b 01 00 00       	jmp    80101ada <dedup+0x466>
		}
		brelse(b2);
8010197f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101982:	89 04 24             	mov    %eax,(%esp)
80101985:	e8 8d e8 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
8010198a:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
8010198e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101991:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101994:	0f 8f 2c fe ff ff    	jg     801017c6 <dedup+0x152>
8010199a:	e9 3b 01 00 00       	jmp    80101ada <dedup+0x466>
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{//cprintf("in 2nd else\n");
	  //brelse(b1);
	  b1 = 0;
8010199f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	  continue;
801019a6:	e9 2f 04 00 00       	jmp    80101dda <dedup+0x766>
// 	      brelse(b2);
// 	    }
// 	  } // for blockindex2 < NINDIRECT in ip1
// 	} //if not found match, check INDIRECT
//       } // if blockindex1 is < NDIRECT
      else if(!found)					// in the same file
801019ab:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801019af:	0f 85 25 01 00 00    	jne    80101ada <dedup+0x466>
      {
	if(a)
801019b5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
801019b9:	0f 84 1b 01 00 00    	je     80101ada <dedup+0x466>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
801019bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c2:	83 e8 0c             	sub    $0xc,%eax
801019c5:	89 45 ac             	mov    %eax,-0x54(%ebp)
	  if(a[blockIndex1Offset])
801019c8:	8b 45 ac             	mov    -0x54(%ebp),%eax
801019cb:	c1 e0 02             	shl    $0x2,%eax
801019ce:	03 45 d0             	add    -0x30(%ebp),%eax
801019d1:	8b 00                	mov    (%eax),%eax
801019d3:	85 c0                	test   %eax,%eax
801019d5:	0f 84 f3 00 00 00    	je     80101ace <dedup+0x45a>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
801019db:	8b 45 ac             	mov    -0x54(%ebp),%eax
801019de:	c1 e0 02             	shl    $0x2,%eax
801019e1:	03 45 d0             	add    -0x30(%ebp),%eax
801019e4:	8b 10                	mov    (%eax),%edx
801019e6:	8b 45 bc             	mov    -0x44(%ebp),%eax
801019e9:	8b 00                	mov    (%eax),%eax
801019eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801019ef:	89 04 24             	mov    %eax,(%esp)
801019f2:	e8 af e7 ff ff       	call   801001a6 <bread>
801019f7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
801019fa:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
80101a01:	e9 ba 00 00 00       	jmp    80101ac0 <dedup+0x44c>
	    {
	      if(a[blockIndex2])
80101a06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a09:	c1 e0 02             	shl    $0x2,%eax
80101a0c:	03 45 d0             	add    -0x30(%ebp),%eax
80101a0f:	8b 00                	mov    (%eax),%eax
80101a11:	85 c0                	test   %eax,%eax
80101a13:	0f 84 a3 00 00 00    	je     80101abc <dedup+0x448>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);//cprintf("before blkcmp 3\n");
80101a19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a1c:	c1 e0 02             	shl    $0x2,%eax
80101a1f:	03 45 d0             	add    -0x30(%ebp),%eax
80101a22:	8b 10                	mov    (%eax),%edx
80101a24:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a27:	8b 00                	mov    (%eax),%eax
80101a29:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a2d:	89 04 24             	mov    %eax,(%esp)
80101a30:	e8 71 e7 ff ff       	call   801001a6 <bread>
80101a35:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101a38:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a3f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a42:	89 04 24             	mov    %eax,(%esp)
80101a45:	e8 0b fb ff ff       	call   80101555 <blkcmp>
80101a4a:	85 c0                	test   %eax,%eax
80101a4c:	74 63                	je     80101ab1 <dedup+0x43d>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101a4e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101a51:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101a55:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101a58:	89 44 24 18          	mov    %eax,0x18(%esp)
80101a5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a5f:	89 44 24 14          	mov    %eax,0x14(%esp)
80101a63:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101a66:	89 44 24 10          	mov    %eax,0x10(%esp)
80101a6a:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a6d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101a71:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a74:	89 44 24 08          	mov    %eax,0x8(%esp)
80101a78:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a7f:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a82:	89 04 24             	mov    %eax,(%esp)
80101a85:	e8 13 fb ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101a8a:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a8d:	89 04 24             	mov    %eax,(%esp)
80101a90:	e8 82 e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101a95:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a98:	89 04 24             	mov    %eax,(%esp)
80101a9b:	e8 77 e7 ff ff       	call   80100217 <brelse>
		  found = 1;
80101aa0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101aa7:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101aae:	90                   	nop
80101aaf:	eb 29                	jmp    80101ada <dedup+0x466>
		}
		brelse(b2);
80101ab1:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101ab4:	89 04 24             	mov    %eax,(%esp)
80101ab7:	e8 5b e7 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101abc:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101ac0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ac3:	3b 45 ac             	cmp    -0x54(%ebp),%eax
80101ac6:	0f 8f 3a ff ff ff    	jg     80101a06 <dedup+0x392>
80101acc:	eb 0c                	jmp    80101ada <dedup+0x466>
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    //brelse(b1);
	    b1 = 0;
80101ace:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	    continue;
80101ad5:	e9 00 03 00 00       	jmp    80101dda <dedup+0x766>
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101ada:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101ade:	0f 85 cd 02 00 00    	jne    80101db1 <dedup+0x73d>
80101ae4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80101ae8:	0f 84 c3 02 00 00    	je     80101db1 <dedup+0x73d>
      {
	uint* aSub = 0;
80101aee:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
	int blockIndex1Offset = blockIndex1;
80101af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101af8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if(blockIndex1 >= NDIRECT)
80101afb:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101aff:	7e 0f                	jle    80101b10 <dedup+0x49c>
	{
	  aSub = a;
80101b01:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101b04:	89 45 c8             	mov    %eax,-0x38(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101b07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b0a:	83 e8 0c             	sub    $0xc,%eax
80101b0d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	}
	prevInum = ninodes-1;
80101b10:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101b13:	83 e8 01             	sub    $0x1,%eax
80101b16:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101b19:	e9 7b 02 00 00       	jmp    80101d99 <dedup+0x725>
	{cprintf("ip2->inum = %d\n",ip2->inum);
80101b1e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b21:	8b 40 04             	mov    0x4(%eax),%eax
80101b24:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b28:	c7 04 24 5b 93 10 80 	movl   $0x8010935b,(%esp)
80101b2f:	e8 6d e8 ff ff       	call   801003a1 <cprintf>
	  ilock(ip2);
80101b34:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b37:	89 04 24             	mov    %eax,(%esp)
80101b3a:	e8 b5 08 00 00       	call   801023f4 <ilock>
	  if(ip2->addrs[NDIRECT])
80101b3f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b42:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b45:	85 c0                	test   %eax,%eax
80101b47:	74 2a                	je     80101b73 <dedup+0x4ff>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101b49:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b4c:	8b 50 4c             	mov    0x4c(%eax),%edx
80101b4f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b52:	8b 00                	mov    (%eax),%eax
80101b54:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b58:	89 04 24             	mov    %eax,(%esp)
80101b5b:	e8 46 e6 ff ff       	call   801001a6 <bread>
80101b60:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	    b = (uint*)bp2->data;
80101b63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101b66:	83 c0 18             	add    $0x18,%eax
80101b69:	89 45 cc             	mov    %eax,-0x34(%ebp)
	    indirects2 = NINDIRECT;
80101b6c:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  cprintf("before 1st for\n");
80101b73:	c7 04 24 6b 93 10 80 	movl   $0x8010936b,(%esp)
80101b7a:	e8 22 e8 ff ff       	call   801003a1 <cprintf>
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101b7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101b82:	83 c0 0b             	add    $0xb,%eax
80101b85:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101b88:	e9 ca 01 00 00       	jmp    80101d57 <dedup+0x6e3>
	  {//cprintf("in 1st for\n");
	    if(blockIndex2<NDIRECT)
80101b8d:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101b91:	0f 8f db 00 00 00    	jg     80101c72 <dedup+0x5fe>
	    {
	      if(ip2->addrs[blockIndex2])
80101b97:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b9a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b9d:	83 c2 04             	add    $0x4,%edx
80101ba0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101ba4:	85 c0                	test   %eax,%eax
80101ba6:	0f 84 a7 01 00 00    	je     80101d53 <dedup+0x6df>
	      {
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);//cprintf("before blkcmp 4\n");
80101bac:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101baf:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101bb2:	83 c2 04             	add    $0x4,%edx
80101bb5:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101bb9:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101bbc:	8b 00                	mov    (%eax),%eax
80101bbe:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bc2:	89 04 24             	mov    %eax,(%esp)
80101bc5:	e8 dc e5 ff ff       	call   801001a6 <bread>
80101bca:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101bcd:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bd0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101bd4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101bd7:	89 04 24             	mov    %eax,(%esp)
80101bda:	e8 76 f9 ff ff       	call   80101555 <blkcmp>
80101bdf:	85 c0                	test   %eax,%eax
80101be1:	74 7f                	je     80101c62 <dedup+0x5ee>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101be3:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101bea:	00 
80101beb:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101bee:	89 44 24 18          	mov    %eax,0x18(%esp)
80101bf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bf5:	89 44 24 14          	mov    %eax,0x14(%esp)
80101bf9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101bfc:	89 44 24 10          	mov    %eax,0x10(%esp)
80101c00:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c03:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101c07:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c0e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c11:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c15:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c18:	89 04 24             	mov    %eax,(%esp)
80101c1b:	e8 7d f9 ff ff       	call   8010159d <deletedups>
		  cprintf("*****************before 1st brelse direct\n"); 
80101c20:	c7 04 24 7c 93 10 80 	movl   $0x8010937c,(%esp)
80101c27:	e8 75 e7 ff ff       	call   801003a1 <cprintf>
		  brelse(b1);				// release the outer loop block
80101c2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c2f:	89 04 24             	mov    %eax,(%esp)
80101c32:	e8 e0 e5 ff ff       	call   80100217 <brelse>
		  cprintf("*****************after 1st brelse b1 direct\n"); 
80101c37:	c7 04 24 a8 93 10 80 	movl   $0x801093a8,(%esp)
80101c3e:	e8 5e e7 ff ff       	call   801003a1 <cprintf>
		  //brelse(b2);
		  cprintf("*****************after 1st brelse b2 direct\n"); 
80101c43:	c7 04 24 d8 93 10 80 	movl   $0x801093d8,(%esp)
80101c4a:	e8 52 e7 ff ff       	call   801003a1 <cprintf>
		  found = 1;
80101c4f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101c56:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101c5d:	e9 ff 00 00 00       	jmp    80101d61 <dedup+0x6ed>
		}//cprintf("before 1st brelse\n");
		brelse(b2);
80101c62:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c65:	89 04 24             	mov    %eax,(%esp)
80101c68:	e8 aa e5 ff ff       	call   80100217 <brelse>
80101c6d:	e9 e1 00 00 00       	jmp    80101d53 <dedup+0x6df>
		//cprintf("after 1st brelse\n");
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
80101c72:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101c76:	0f 84 d7 00 00 00    	je     80101d53 <dedup+0x6df>
	    {//cprintf("inside else if\n");
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
80101c7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c7f:	83 e8 0c             	sub    $0xc,%eax
80101c82:	89 45 a8             	mov    %eax,-0x58(%ebp)
	      if(b[blockIndex2Offset])
80101c85:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101c88:	c1 e0 02             	shl    $0x2,%eax
80101c8b:	03 45 cc             	add    -0x34(%ebp),%eax
80101c8e:	8b 00                	mov    (%eax),%eax
80101c90:	85 c0                	test   %eax,%eax
80101c92:	0f 84 bb 00 00 00    	je     80101d53 <dedup+0x6df>
	      {//cprintf("inside indirects2\n");
		b2 = bread(ip2->dev,b[blockIndex2Offset]);//cprintf("before blkcmp 5\n");
80101c98:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101c9b:	c1 e0 02             	shl    $0x2,%eax
80101c9e:	03 45 cc             	add    -0x34(%ebp),%eax
80101ca1:	8b 10                	mov    (%eax),%edx
80101ca3:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ca6:	8b 00                	mov    (%eax),%eax
80101ca8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cac:	89 04 24             	mov    %eax,(%esp)
80101caf:	e8 f2 e4 ff ff       	call   801001a6 <bread>
80101cb4:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101cb7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101cba:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cbe:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101cc1:	89 04 24             	mov    %eax,(%esp)
80101cc4:	e8 8c f8 ff ff       	call   80101555 <blkcmp>
80101cc9:	85 c0                	test   %eax,%eax
80101ccb:	74 7b                	je     80101d48 <dedup+0x6d4>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101ccd:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101cd0:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101cd4:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101cd7:	89 44 24 18          	mov    %eax,0x18(%esp)
80101cdb:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101cde:	89 44 24 14          	mov    %eax,0x14(%esp)
80101ce2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101ce5:	89 44 24 10          	mov    %eax,0x10(%esp)
80101ce9:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101cec:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101cf0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101cf3:	89 44 24 08          	mov    %eax,0x8(%esp)
80101cf7:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cfe:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101d01:	89 04 24             	mov    %eax,(%esp)
80101d04:	e8 94 f8 ff ff       	call   8010159d <deletedups>
		  cprintf("*****************before 2nd brelse indirect\n"); 
80101d09:	c7 04 24 08 94 10 80 	movl   $0x80109408,(%esp)
80101d10:	e8 8c e6 ff ff       	call   801003a1 <cprintf>
		  brelse(b1);				// release the outer loop block
80101d15:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101d18:	89 04 24             	mov    %eax,(%esp)
80101d1b:	e8 f7 e4 ff ff       	call   80100217 <brelse>
		  cprintf("*****************after 2nd brelse indirect\n"); 
80101d20:	c7 04 24 38 94 10 80 	movl   $0x80109438,(%esp)
80101d27:	e8 75 e6 ff ff       	call   801003a1 <cprintf>
		  //brelse(b2);
		  cprintf("*****************after 2nd brelse indirect\n"); 
80101d2c:	c7 04 24 38 94 10 80 	movl   $0x80109438,(%esp)
80101d33:	e8 69 e6 ff ff       	call   801003a1 <cprintf>
		  found = 1;
80101d38:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101d3f:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101d46:	eb 19                	jmp    80101d61 <dedup+0x6ed>
		}//cprintf("before 2nd brelse\n");
		brelse(b2);
80101d48:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101d4b:	89 04 24             	mov    %eax,(%esp)
80101d4e:	e8 c4 e4 ff ff       	call   80100217 <brelse>
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  cprintf("before 1st for\n");
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101d53:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101d57:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101d5b:	0f 89 2c fe ff ff    	jns    80101b8d <dedup+0x519>
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
80101d61:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d64:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d67:	85 c0                	test   %eax,%eax
80101d69:	74 23                	je     80101d8e <dedup+0x71a>
	  {
	    cprintf("before bp2 brelse\n");
80101d6b:	c7 04 24 64 94 10 80 	movl   $0x80109464,(%esp)
80101d72:	e8 2a e6 ff ff       	call   801003a1 <cprintf>
	    brelse(bp2);
80101d77:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101d7a:	89 04 24             	mov    %eax,(%esp)
80101d7d:	e8 95 e4 ff ff       	call   80100217 <brelse>
	    cprintf("after bp2 brelse\n"); 
80101d82:	c7 04 24 77 94 10 80 	movl   $0x80109477,(%esp)
80101d89:	e8 13 e6 ff ff       	call   801003a1 <cprintf>
	  }
	  
	  iunlockput(ip2);
80101d8e:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d91:	89 04 24             	mov    %eax,(%esp)
80101d94:	e8 df 08 00 00       	call   80102678 <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101d99:	8d 45 a4             	lea    -0x5c(%ebp),%eax
80101d9c:	89 04 24             	mov    %eax,(%esp)
80101d9f:	e8 08 13 00 00       	call   801030ac <getPrevInode>
80101da4:	89 45 b8             	mov    %eax,-0x48(%ebp)
80101da7:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
80101dab:	0f 85 6d fd ff ff    	jne    80101b1e <dedup+0x4aa>
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
80101db1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101db5:	75 23                	jne    80101dda <dedup+0x766>
      {
	cprintf("*****************before 1st brelse\n"); 
80101db7:	c7 04 24 8c 94 10 80 	movl   $0x8010948c,(%esp)
80101dbe:	e8 de e5 ff ff       	call   801003a1 <cprintf>
	brelse(b1);				// release the outer loop block
80101dc3:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101dc6:	89 04 24             	mov    %eax,(%esp)
80101dc9:	e8 49 e4 ff ff       	call   80100217 <brelse>
	cprintf("*****************after 1st brelse\n"); 
80101dce:	c7 04 24 b0 94 10 80 	movl   $0x801094b0,(%esp)
80101dd5:	e8 c7 e5 ff ff       	call   801003a1 <cprintf>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101dda:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101dde:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101de5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101de8:	83 c0 0c             	add    $0xc,%eax
80101deb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101dee:	0f 8f 71 f9 ff ff    	jg     80101765 <dedup+0xf1>
	brelse(b1);				// release the outer loop block
	cprintf("*****************after 1st brelse\n"); 
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101df4:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101df7:	8b 40 4c             	mov    0x4c(%eax),%eax
80101dfa:	85 c0                	test   %eax,%eax
80101dfc:	74 23                	je     80101e21 <dedup+0x7ad>
    {
      cprintf("*****************before bp1 brelse\n"); 
80101dfe:	c7 04 24 d4 94 10 80 	movl   $0x801094d4,(%esp)
80101e05:	e8 97 e5 ff ff       	call   801003a1 <cprintf>
      brelse(bp1);
80101e0a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101e0d:	89 04 24             	mov    %eax,(%esp)
80101e10:	e8 02 e4 ff ff       	call   80100217 <brelse>
      cprintf("*****************after bp1 brelse\n");
80101e15:	c7 04 24 f8 94 10 80 	movl   $0x801094f8,(%esp)
80101e1c:	e8 80 e5 ff ff       	call   801003a1 <cprintf>
    }
    
    if(iChanged)
80101e21:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101e25:	74 15                	je     80101e3c <dedup+0x7c8>
    {
      begin_trans();
80101e27:	e8 a1 22 00 00       	call   801040cd <begin_trans>
      iupdate(ip1);
80101e2c:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e2f:	89 04 24             	mov    %eax,(%esp)
80101e32:	e8 01 04 00 00       	call   80102238 <iupdate>
      commit_trans();
80101e37:	e8 da 22 00 00       	call   80104116 <commit_trans>
    }
    iunlockput(ip1);
80101e3c:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e3f:	89 04 24             	mov    %eax,(%esp)
80101e42:	e8 31 08 00 00       	call   80102678 <iunlockput>
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
80101e47:	e8 8e 11 00 00       	call   80102fda <getNextInode>
80101e4c:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101e4f:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101e53:	0f 85 9d f8 ff ff    	jne    801016f6 <dedup+0x82>
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
80101e59:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101e5e:	c9                   	leave  
80101e5f:	c3                   	ret    

80101e60 <readsb>:
int prevInum = 0;

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101e60:	55                   	push   %ebp
80101e61:	89 e5                	mov    %esp,%ebp
80101e63:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101e66:	8b 45 08             	mov    0x8(%ebp),%eax
80101e69:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101e70:	00 
80101e71:	89 04 24             	mov    %eax,(%esp)
80101e74:	e8 2d e3 ff ff       	call   801001a6 <bread>
80101e79:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e7f:	83 c0 18             	add    $0x18,%eax
80101e82:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101e89:	00 
80101e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e91:	89 04 24             	mov    %eax,(%esp)
80101e94:	e8 dc 3e 00 00       	call   80105d75 <memmove>
  brelse(bp);
80101e99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e9c:	89 04 24             	mov    %eax,(%esp)
80101e9f:	e8 73 e3 ff ff       	call   80100217 <brelse>
}
80101ea4:	c9                   	leave  
80101ea5:	c3                   	ret    

80101ea6 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101ea6:	55                   	push   %ebp
80101ea7:	89 e5                	mov    %esp,%ebp
80101ea9:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101eac:	8b 55 0c             	mov    0xc(%ebp),%edx
80101eaf:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eb6:	89 04 24             	mov    %eax,(%esp)
80101eb9:	e8 e8 e2 ff ff       	call   801001a6 <bread>
80101ebe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101ec1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ec4:	83 c0 18             	add    $0x18,%eax
80101ec7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101ece:	00 
80101ecf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101ed6:	00 
80101ed7:	89 04 24             	mov    %eax,(%esp)
80101eda:	e8 c3 3d 00 00       	call   80105ca2 <memset>
  log_write(bp);
80101edf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ee2:	89 04 24             	mov    %eax,(%esp)
80101ee5:	e8 84 22 00 00       	call   8010416e <log_write>
  brelse(bp);
80101eea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eed:	89 04 24             	mov    %eax,(%esp)
80101ef0:	e8 22 e3 ff ff       	call   80100217 <brelse>
}
80101ef5:	c9                   	leave  
80101ef6:	c3                   	ret    

80101ef7 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101ef7:	55                   	push   %ebp
80101ef8:	89 e5                	mov    %esp,%ebp
80101efa:	53                   	push   %ebx
80101efb:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101efe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101f05:	8b 45 08             	mov    0x8(%ebp),%eax
80101f08:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101f0b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f0f:	89 04 24             	mov    %eax,(%esp)
80101f12:	e8 49 ff ff ff       	call   80101e60 <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101f17:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f1e:	e9 29 01 00 00       	jmp    8010204c <balloc+0x155>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101f23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f26:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101f2c:	85 c0                	test   %eax,%eax
80101f2e:	0f 48 c2             	cmovs  %edx,%eax
80101f31:	c1 f8 0c             	sar    $0xc,%eax
80101f34:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101f37:	c1 ea 03             	shr    $0x3,%edx
80101f3a:	01 d0                	add    %edx,%eax
80101f3c:	83 c0 03             	add    $0x3,%eax
80101f3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f43:	8b 45 08             	mov    0x8(%ebp),%eax
80101f46:	89 04 24             	mov    %eax,(%esp)
80101f49:	e8 58 e2 ff ff       	call   801001a6 <bread>
80101f4e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101f51:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101f58:	e9 bf 00 00 00       	jmp    8010201c <balloc+0x125>
      m = 1 << (bi % 8);
80101f5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f60:	89 c2                	mov    %eax,%edx
80101f62:	c1 fa 1f             	sar    $0x1f,%edx
80101f65:	c1 ea 1d             	shr    $0x1d,%edx
80101f68:	01 d0                	add    %edx,%eax
80101f6a:	83 e0 07             	and    $0x7,%eax
80101f6d:	29 d0                	sub    %edx,%eax
80101f6f:	ba 01 00 00 00       	mov    $0x1,%edx
80101f74:	89 d3                	mov    %edx,%ebx
80101f76:	89 c1                	mov    %eax,%ecx
80101f78:	d3 e3                	shl    %cl,%ebx
80101f7a:	89 d8                	mov    %ebx,%eax
80101f7c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101f7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f82:	8d 50 07             	lea    0x7(%eax),%edx
80101f85:	85 c0                	test   %eax,%eax
80101f87:	0f 48 c2             	cmovs  %edx,%eax
80101f8a:	c1 f8 03             	sar    $0x3,%eax
80101f8d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101f90:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101f95:	0f b6 c0             	movzbl %al,%eax
80101f98:	23 45 e8             	and    -0x18(%ebp),%eax
80101f9b:	85 c0                	test   %eax,%eax
80101f9d:	75 79                	jne    80102018 <balloc+0x121>
        bp->data[bi/8] |= m;  // Mark block in use.
80101f9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa2:	8d 50 07             	lea    0x7(%eax),%edx
80101fa5:	85 c0                	test   %eax,%eax
80101fa7:	0f 48 c2             	cmovs  %edx,%eax
80101faa:	c1 f8 03             	sar    $0x3,%eax
80101fad:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101fb0:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101fb5:	89 d1                	mov    %edx,%ecx
80101fb7:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101fba:	09 ca                	or     %ecx,%edx
80101fbc:	89 d1                	mov    %edx,%ecx
80101fbe:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101fc1:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101fc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fc8:	89 04 24             	mov    %eax,(%esp)
80101fcb:	e8 9e 21 00 00       	call   8010416e <log_write>
        brelse(bp);
80101fd0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fd3:	89 04 24             	mov    %eax,(%esp)
80101fd6:	e8 3c e2 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101fdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fde:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101fe1:	01 c2                	add    %eax,%edx
80101fe3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fea:	89 04 24             	mov    %eax,(%esp)
80101fed:	e8 b4 fe ff ff       	call   80101ea6 <bzero>
	updateBlkRef(b+bi,1);
80101ff2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ff5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ff8:	01 d0                	add    %edx,%eax
80101ffa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102001:	00 
80102002:	89 04 24             	mov    %eax,(%esp)
80102005:	e8 53 11 00 00       	call   8010315d <updateBlkRef>
        return b + bi;
8010200a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010200d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102010:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80102012:	83 c4 34             	add    $0x34,%esp
80102015:	5b                   	pop    %ebx
80102016:	5d                   	pop    %ebp
80102017:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102018:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010201c:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80102023:	7f 15                	jg     8010203a <balloc+0x143>
80102025:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102028:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010202b:	01 d0                	add    %edx,%eax
8010202d:	89 c2                	mov    %eax,%edx
8010202f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102032:	39 c2                	cmp    %eax,%edx
80102034:	0f 82 23 ff ff ff    	jb     80101f5d <balloc+0x66>
        bzero(dev, b + bi);
	updateBlkRef(b+bi,1);
        return b + bi;
      }
    }
    brelse(bp);
8010203a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010203d:	89 04 24             	mov    %eax,(%esp)
80102040:	e8 d2 e1 ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80102045:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010204c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010204f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102052:	39 c2                	cmp    %eax,%edx
80102054:	0f 82 c9 fe ff ff    	jb     80101f23 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
8010205a:	c7 04 24 1b 95 10 80 	movl   $0x8010951b,(%esp)
80102061:	e8 d7 e4 ff ff       	call   8010053d <panic>

80102066 <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
80102066:	55                   	push   %ebp
80102067:	89 e5                	mov    %esp,%ebp
80102069:	53                   	push   %ebx
8010206a:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
8010206d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102070:	89 44 24 04          	mov    %eax,0x4(%esp)
80102074:	8b 45 08             	mov    0x8(%ebp),%eax
80102077:	89 04 24             	mov    %eax,(%esp)
8010207a:	e8 e1 fd ff ff       	call   80101e60 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
8010207f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102082:	89 c2                	mov    %eax,%edx
80102084:	c1 ea 0c             	shr    $0xc,%edx
80102087:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010208a:	c1 e8 03             	shr    $0x3,%eax
8010208d:	01 d0                	add    %edx,%eax
8010208f:	8d 50 03             	lea    0x3(%eax),%edx
80102092:	8b 45 08             	mov    0x8(%ebp),%eax
80102095:	89 54 24 04          	mov    %edx,0x4(%esp)
80102099:	89 04 24             	mov    %eax,(%esp)
8010209c:	e8 05 e1 ff ff       	call   801001a6 <bread>
801020a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801020a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801020a7:	25 ff 0f 00 00       	and    $0xfff,%eax
801020ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801020af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020b2:	89 c2                	mov    %eax,%edx
801020b4:	c1 fa 1f             	sar    $0x1f,%edx
801020b7:	c1 ea 1d             	shr    $0x1d,%edx
801020ba:	01 d0                	add    %edx,%eax
801020bc:	83 e0 07             	and    $0x7,%eax
801020bf:	29 d0                	sub    %edx,%eax
801020c1:	ba 01 00 00 00       	mov    $0x1,%edx
801020c6:	89 d3                	mov    %edx,%ebx
801020c8:	89 c1                	mov    %eax,%ecx
801020ca:	d3 e3                	shl    %cl,%ebx
801020cc:	89 d8                	mov    %ebx,%eax
801020ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801020d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020d4:	8d 50 07             	lea    0x7(%eax),%edx
801020d7:	85 c0                	test   %eax,%eax
801020d9:	0f 48 c2             	cmovs  %edx,%eax
801020dc:	c1 f8 03             	sar    $0x3,%eax
801020df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801020e2:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801020e7:	0f b6 c0             	movzbl %al,%eax
801020ea:	23 45 ec             	and    -0x14(%ebp),%eax
801020ed:	85 c0                	test   %eax,%eax
801020ef:	75 0c                	jne    801020fd <bfree+0x97>
    panic("freeing free block");
801020f1:	c7 04 24 31 95 10 80 	movl   $0x80109531,(%esp)
801020f8:	e8 40 e4 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801020fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102100:	8d 50 07             	lea    0x7(%eax),%edx
80102103:	85 c0                	test   %eax,%eax
80102105:	0f 48 c2             	cmovs  %edx,%eax
80102108:	c1 f8 03             	sar    $0x3,%eax
8010210b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010210e:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102113:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80102116:	f7 d1                	not    %ecx
80102118:	21 ca                	and    %ecx,%edx
8010211a:	89 d1                	mov    %edx,%ecx
8010211c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010211f:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80102123:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102126:	89 04 24             	mov    %eax,(%esp)
80102129:	e8 40 20 00 00       	call   8010416e <log_write>
  brelse(bp);
8010212e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102131:	89 04 24             	mov    %eax,(%esp)
80102134:	e8 de e0 ff ff       	call   80100217 <brelse>
}
80102139:	83 c4 34             	add    $0x34,%esp
8010213c:	5b                   	pop    %ebx
8010213d:	5d                   	pop    %ebp
8010213e:	c3                   	ret    

8010213f <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010213f:	55                   	push   %ebp
80102140:	89 e5                	mov    %esp,%ebp
80102142:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80102145:	c7 44 24 04 44 95 10 	movl   $0x80109544,0x4(%esp)
8010214c:	80 
8010214d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102154:	e8 d9 38 00 00       	call   80105a32 <initlock>
}
80102159:	c9                   	leave  
8010215a:	c3                   	ret    

8010215b <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010215b:	55                   	push   %ebp
8010215c:	89 e5                	mov    %esp,%ebp
8010215e:	83 ec 48             	sub    $0x48,%esp
80102161:	8b 45 0c             	mov    0xc(%ebp),%eax
80102164:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80102168:	8b 45 08             	mov    0x8(%ebp),%eax
8010216b:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010216e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102172:	89 04 24             	mov    %eax,(%esp)
80102175:	e8 e6 fc ff ff       	call   80101e60 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010217a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102181:	e9 98 00 00 00       	jmp    8010221e <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80102186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102189:	c1 e8 03             	shr    $0x3,%eax
8010218c:	83 c0 02             	add    $0x2,%eax
8010218f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102193:	8b 45 08             	mov    0x8(%ebp),%eax
80102196:	89 04 24             	mov    %eax,(%esp)
80102199:	e8 08 e0 ff ff       	call   801001a6 <bread>
8010219e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801021a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021a4:	8d 50 18             	lea    0x18(%eax),%edx
801021a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021aa:	83 e0 07             	and    $0x7,%eax
801021ad:	c1 e0 06             	shl    $0x6,%eax
801021b0:	01 d0                	add    %edx,%eax
801021b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801021b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021b8:	0f b7 00             	movzwl (%eax),%eax
801021bb:	66 85 c0             	test   %ax,%ax
801021be:	75 4f                	jne    8010220f <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801021c0:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801021c7:	00 
801021c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801021cf:	00 
801021d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d3:	89 04 24             	mov    %eax,(%esp)
801021d6:	e8 c7 3a 00 00       	call   80105ca2 <memset>
      dip->type = type;
801021db:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021de:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801021e2:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801021e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021e8:	89 04 24             	mov    %eax,(%esp)
801021eb:	e8 7e 1f 00 00       	call   8010416e <log_write>
      brelse(bp);
801021f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021f3:	89 04 24             	mov    %eax,(%esp)
801021f6:	e8 1c e0 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801021fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80102202:	8b 45 08             	mov    0x8(%ebp),%eax
80102205:	89 04 24             	mov    %eax,(%esp)
80102208:	e8 e3 00 00 00       	call   801022f0 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
8010220d:	c9                   	leave  
8010220e:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010220f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102212:	89 04 24             	mov    %eax,(%esp)
80102215:	e8 fd df ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010221a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010221e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102221:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102224:	39 c2                	cmp    %eax,%edx
80102226:	0f 82 5a ff ff ff    	jb     80102186 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010222c:	c7 04 24 4b 95 10 80 	movl   $0x8010954b,(%esp)
80102233:	e8 05 e3 ff ff       	call   8010053d <panic>

80102238 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80102238:	55                   	push   %ebp
80102239:	89 e5                	mov    %esp,%ebp
8010223b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010223e:	8b 45 08             	mov    0x8(%ebp),%eax
80102241:	8b 40 04             	mov    0x4(%eax),%eax
80102244:	c1 e8 03             	shr    $0x3,%eax
80102247:	8d 50 02             	lea    0x2(%eax),%edx
8010224a:	8b 45 08             	mov    0x8(%ebp),%eax
8010224d:	8b 00                	mov    (%eax),%eax
8010224f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102253:	89 04 24             	mov    %eax,(%esp)
80102256:	e8 4b df ff ff       	call   801001a6 <bread>
8010225b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010225e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102261:	8d 50 18             	lea    0x18(%eax),%edx
80102264:	8b 45 08             	mov    0x8(%ebp),%eax
80102267:	8b 40 04             	mov    0x4(%eax),%eax
8010226a:	83 e0 07             	and    $0x7,%eax
8010226d:	c1 e0 06             	shl    $0x6,%eax
80102270:	01 d0                	add    %edx,%eax
80102272:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80102275:	8b 45 08             	mov    0x8(%ebp),%eax
80102278:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010227c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010227f:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80102282:	8b 45 08             	mov    0x8(%ebp),%eax
80102285:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80102289:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010228c:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102290:	8b 45 08             	mov    0x8(%ebp),%eax
80102293:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80102297:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010229a:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010229e:	8b 45 08             	mov    0x8(%ebp),%eax
801022a1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801022a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022a8:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801022ac:	8b 45 08             	mov    0x8(%ebp),%eax
801022af:	8b 50 18             	mov    0x18(%eax),%edx
801022b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b5:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801022b8:	8b 45 08             	mov    0x8(%ebp),%eax
801022bb:	8d 50 1c             	lea    0x1c(%eax),%edx
801022be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022c1:	83 c0 0c             	add    $0xc,%eax
801022c4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801022cb:	00 
801022cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801022d0:	89 04 24             	mov    %eax,(%esp)
801022d3:	e8 9d 3a 00 00       	call   80105d75 <memmove>
  log_write(bp);
801022d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022db:	89 04 24             	mov    %eax,(%esp)
801022de:	e8 8b 1e 00 00       	call   8010416e <log_write>
  brelse(bp);
801022e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022e6:	89 04 24             	mov    %eax,(%esp)
801022e9:	e8 29 df ff ff       	call   80100217 <brelse>
}
801022ee:	c9                   	leave  
801022ef:	c3                   	ret    

801022f0 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801022f0:	55                   	push   %ebp
801022f1:	89 e5                	mov    %esp,%ebp
801022f3:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801022f6:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022fd:	e8 51 37 00 00       	call   80105a53 <acquire>

  // Is the inode already cached?
  empty = 0;
80102302:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102309:	c7 45 f4 b4 f8 10 80 	movl   $0x8010f8b4,-0xc(%ebp)
80102310:	eb 59                	jmp    8010236b <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80102312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102315:	8b 40 08             	mov    0x8(%eax),%eax
80102318:	85 c0                	test   %eax,%eax
8010231a:	7e 35                	jle    80102351 <iget+0x61>
8010231c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010231f:	8b 00                	mov    (%eax),%eax
80102321:	3b 45 08             	cmp    0x8(%ebp),%eax
80102324:	75 2b                	jne    80102351 <iget+0x61>
80102326:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102329:	8b 40 04             	mov    0x4(%eax),%eax
8010232c:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010232f:	75 20                	jne    80102351 <iget+0x61>
      ip->ref++;
80102331:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102334:	8b 40 08             	mov    0x8(%eax),%eax
80102337:	8d 50 01             	lea    0x1(%eax),%edx
8010233a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233d:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102340:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102347:	e8 69 37 00 00       	call   80105ab5 <release>
      return ip;
8010234c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010234f:	eb 6f                	jmp    801023c0 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102351:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102355:	75 10                	jne    80102367 <iget+0x77>
80102357:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010235a:	8b 40 08             	mov    0x8(%eax),%eax
8010235d:	85 c0                	test   %eax,%eax
8010235f:	75 06                	jne    80102367 <iget+0x77>
      empty = ip;
80102361:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102364:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102367:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010236b:	81 7d f4 54 08 11 80 	cmpl   $0x80110854,-0xc(%ebp)
80102372:	72 9e                	jb     80102312 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80102374:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102378:	75 0c                	jne    80102386 <iget+0x96>
    panic("iget: no inodes");
8010237a:	c7 04 24 5d 95 10 80 	movl   $0x8010955d,(%esp)
80102381:	e8 b7 e1 ff ff       	call   8010053d <panic>

  ip = empty;
80102386:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102389:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010238c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010238f:	8b 55 08             	mov    0x8(%ebp),%edx
80102392:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80102394:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102397:	8b 55 0c             	mov    0xc(%ebp),%edx
8010239a:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
8010239d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a0:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801023a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023aa:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801023b1:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023b8:	e8 f8 36 00 00       	call   80105ab5 <release>

  return ip;
801023bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801023c0:	c9                   	leave  
801023c1:	c3                   	ret    

801023c2 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801023c2:	55                   	push   %ebp
801023c3:	89 e5                	mov    %esp,%ebp
801023c5:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801023c8:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023cf:	e8 7f 36 00 00       	call   80105a53 <acquire>
  ip->ref++;
801023d4:	8b 45 08             	mov    0x8(%ebp),%eax
801023d7:	8b 40 08             	mov    0x8(%eax),%eax
801023da:	8d 50 01             	lea    0x1(%eax),%edx
801023dd:	8b 45 08             	mov    0x8(%ebp),%eax
801023e0:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801023e3:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023ea:	e8 c6 36 00 00       	call   80105ab5 <release>
  return ip;
801023ef:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023f2:	c9                   	leave  
801023f3:	c3                   	ret    

801023f4 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801023f4:	55                   	push   %ebp
801023f5:	89 e5                	mov    %esp,%ebp
801023f7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801023fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023fe:	74 0a                	je     8010240a <ilock+0x16>
80102400:	8b 45 08             	mov    0x8(%ebp),%eax
80102403:	8b 40 08             	mov    0x8(%eax),%eax
80102406:	85 c0                	test   %eax,%eax
80102408:	7f 0c                	jg     80102416 <ilock+0x22>
    panic("ilock");
8010240a:	c7 04 24 6d 95 10 80 	movl   $0x8010956d,(%esp)
80102411:	e8 27 e1 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102416:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010241d:	e8 31 36 00 00       	call   80105a53 <acquire>
  while(ip->flags & I_BUSY)
80102422:	eb 13                	jmp    80102437 <ilock+0x43>
    sleep(ip, &icache.lock);
80102424:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
8010242b:	80 
8010242c:	8b 45 08             	mov    0x8(%ebp),%eax
8010242f:	89 04 24             	mov    %eax,(%esp)
80102432:	e8 3e 33 00 00       	call   80105775 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80102437:	8b 45 08             	mov    0x8(%ebp),%eax
8010243a:	8b 40 0c             	mov    0xc(%eax),%eax
8010243d:	83 e0 01             	and    $0x1,%eax
80102440:	84 c0                	test   %al,%al
80102442:	75 e0                	jne    80102424 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80102444:	8b 45 08             	mov    0x8(%ebp),%eax
80102447:	8b 40 0c             	mov    0xc(%eax),%eax
8010244a:	89 c2                	mov    %eax,%edx
8010244c:	83 ca 01             	or     $0x1,%edx
8010244f:	8b 45 08             	mov    0x8(%ebp),%eax
80102452:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80102455:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010245c:	e8 54 36 00 00       	call   80105ab5 <release>

  if(!(ip->flags & I_VALID)){
80102461:	8b 45 08             	mov    0x8(%ebp),%eax
80102464:	8b 40 0c             	mov    0xc(%eax),%eax
80102467:	83 e0 02             	and    $0x2,%eax
8010246a:	85 c0                	test   %eax,%eax
8010246c:	0f 85 ce 00 00 00    	jne    80102540 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80102472:	8b 45 08             	mov    0x8(%ebp),%eax
80102475:	8b 40 04             	mov    0x4(%eax),%eax
80102478:	c1 e8 03             	shr    $0x3,%eax
8010247b:	8d 50 02             	lea    0x2(%eax),%edx
8010247e:	8b 45 08             	mov    0x8(%ebp),%eax
80102481:	8b 00                	mov    (%eax),%eax
80102483:	89 54 24 04          	mov    %edx,0x4(%esp)
80102487:	89 04 24             	mov    %eax,(%esp)
8010248a:	e8 17 dd ff ff       	call   801001a6 <bread>
8010248f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80102492:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102495:	8d 50 18             	lea    0x18(%eax),%edx
80102498:	8b 45 08             	mov    0x8(%ebp),%eax
8010249b:	8b 40 04             	mov    0x4(%eax),%eax
8010249e:	83 e0 07             	and    $0x7,%eax
801024a1:	c1 e0 06             	shl    $0x6,%eax
801024a4:	01 d0                	add    %edx,%eax
801024a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801024a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024ac:	0f b7 10             	movzwl (%eax),%edx
801024af:	8b 45 08             	mov    0x8(%ebp),%eax
801024b2:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801024b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024b9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801024bd:	8b 45 08             	mov    0x8(%ebp),%eax
801024c0:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801024c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024c7:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801024cb:	8b 45 08             	mov    0x8(%ebp),%eax
801024ce:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801024d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024d5:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801024d9:	8b 45 08             	mov    0x8(%ebp),%eax
801024dc:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801024e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024e3:	8b 50 08             	mov    0x8(%eax),%edx
801024e6:	8b 45 08             	mov    0x8(%ebp),%eax
801024e9:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801024ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024ef:	8d 50 0c             	lea    0xc(%eax),%edx
801024f2:	8b 45 08             	mov    0x8(%ebp),%eax
801024f5:	83 c0 1c             	add    $0x1c,%eax
801024f8:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801024ff:	00 
80102500:	89 54 24 04          	mov    %edx,0x4(%esp)
80102504:	89 04 24             	mov    %eax,(%esp)
80102507:	e8 69 38 00 00       	call   80105d75 <memmove>
    brelse(bp);
8010250c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010250f:	89 04 24             	mov    %eax,(%esp)
80102512:	e8 00 dd ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80102517:	8b 45 08             	mov    0x8(%ebp),%eax
8010251a:	8b 40 0c             	mov    0xc(%eax),%eax
8010251d:	89 c2                	mov    %eax,%edx
8010251f:	83 ca 02             	or     $0x2,%edx
80102522:	8b 45 08             	mov    0x8(%ebp),%eax
80102525:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80102528:	8b 45 08             	mov    0x8(%ebp),%eax
8010252b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010252f:	66 85 c0             	test   %ax,%ax
80102532:	75 0c                	jne    80102540 <ilock+0x14c>
      panic("ilock: no type");
80102534:	c7 04 24 73 95 10 80 	movl   $0x80109573,(%esp)
8010253b:	e8 fd df ff ff       	call   8010053d <panic>
  }
}
80102540:	c9                   	leave  
80102541:	c3                   	ret    

80102542 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80102542:	55                   	push   %ebp
80102543:	89 e5                	mov    %esp,%ebp
80102545:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102548:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010254c:	74 17                	je     80102565 <iunlock+0x23>
8010254e:	8b 45 08             	mov    0x8(%ebp),%eax
80102551:	8b 40 0c             	mov    0xc(%eax),%eax
80102554:	83 e0 01             	and    $0x1,%eax
80102557:	85 c0                	test   %eax,%eax
80102559:	74 0a                	je     80102565 <iunlock+0x23>
8010255b:	8b 45 08             	mov    0x8(%ebp),%eax
8010255e:	8b 40 08             	mov    0x8(%eax),%eax
80102561:	85 c0                	test   %eax,%eax
80102563:	7f 0c                	jg     80102571 <iunlock+0x2f>
    panic("iunlock");
80102565:	c7 04 24 82 95 10 80 	movl   $0x80109582,(%esp)
8010256c:	e8 cc df ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102571:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102578:	e8 d6 34 00 00       	call   80105a53 <acquire>
  ip->flags &= ~I_BUSY;
8010257d:	8b 45 08             	mov    0x8(%ebp),%eax
80102580:	8b 40 0c             	mov    0xc(%eax),%eax
80102583:	89 c2                	mov    %eax,%edx
80102585:	83 e2 fe             	and    $0xfffffffe,%edx
80102588:	8b 45 08             	mov    0x8(%ebp),%eax
8010258b:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
8010258e:	8b 45 08             	mov    0x8(%ebp),%eax
80102591:	89 04 24             	mov    %eax,(%esp)
80102594:	e8 b5 32 00 00       	call   8010584e <wakeup>
  release(&icache.lock);
80102599:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801025a0:	e8 10 35 00 00       	call   80105ab5 <release>
}
801025a5:	c9                   	leave  
801025a6:	c3                   	ret    

801025a7 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
801025a7:	55                   	push   %ebp
801025a8:	89 e5                	mov    %esp,%ebp
801025aa:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801025ad:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801025b4:	e8 9a 34 00 00       	call   80105a53 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801025b9:	8b 45 08             	mov    0x8(%ebp),%eax
801025bc:	8b 40 08             	mov    0x8(%eax),%eax
801025bf:	83 f8 01             	cmp    $0x1,%eax
801025c2:	0f 85 93 00 00 00    	jne    8010265b <iput+0xb4>
801025c8:	8b 45 08             	mov    0x8(%ebp),%eax
801025cb:	8b 40 0c             	mov    0xc(%eax),%eax
801025ce:	83 e0 02             	and    $0x2,%eax
801025d1:	85 c0                	test   %eax,%eax
801025d3:	0f 84 82 00 00 00    	je     8010265b <iput+0xb4>
801025d9:	8b 45 08             	mov    0x8(%ebp),%eax
801025dc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801025e0:	66 85 c0             	test   %ax,%ax
801025e3:	75 76                	jne    8010265b <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801025e5:	8b 45 08             	mov    0x8(%ebp),%eax
801025e8:	8b 40 0c             	mov    0xc(%eax),%eax
801025eb:	83 e0 01             	and    $0x1,%eax
801025ee:	84 c0                	test   %al,%al
801025f0:	74 0c                	je     801025fe <iput+0x57>
      panic("iput busy");
801025f2:	c7 04 24 8a 95 10 80 	movl   $0x8010958a,(%esp)
801025f9:	e8 3f df ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801025fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102601:	8b 40 0c             	mov    0xc(%eax),%eax
80102604:	89 c2                	mov    %eax,%edx
80102606:	83 ca 01             	or     $0x1,%edx
80102609:	8b 45 08             	mov    0x8(%ebp),%eax
8010260c:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
8010260f:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102616:	e8 9a 34 00 00       	call   80105ab5 <release>
    itrunc(ip);
8010261b:	8b 45 08             	mov    0x8(%ebp),%eax
8010261e:	89 04 24             	mov    %eax,(%esp)
80102621:	e8 72 01 00 00       	call   80102798 <itrunc>
    ip->type = 0;
80102626:	8b 45 08             	mov    0x8(%ebp),%eax
80102629:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
8010262f:	8b 45 08             	mov    0x8(%ebp),%eax
80102632:	89 04 24             	mov    %eax,(%esp)
80102635:	e8 fe fb ff ff       	call   80102238 <iupdate>
    acquire(&icache.lock);
8010263a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102641:	e8 0d 34 00 00       	call   80105a53 <acquire>
    ip->flags = 0;
80102646:	8b 45 08             	mov    0x8(%ebp),%eax
80102649:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102650:	8b 45 08             	mov    0x8(%ebp),%eax
80102653:	89 04 24             	mov    %eax,(%esp)
80102656:	e8 f3 31 00 00       	call   8010584e <wakeup>
  }
  ip->ref--;
8010265b:	8b 45 08             	mov    0x8(%ebp),%eax
8010265e:	8b 40 08             	mov    0x8(%eax),%eax
80102661:	8d 50 ff             	lea    -0x1(%eax),%edx
80102664:	8b 45 08             	mov    0x8(%ebp),%eax
80102667:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010266a:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102671:	e8 3f 34 00 00       	call   80105ab5 <release>
}
80102676:	c9                   	leave  
80102677:	c3                   	ret    

80102678 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102678:	55                   	push   %ebp
80102679:	89 e5                	mov    %esp,%ebp
8010267b:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
8010267e:	8b 45 08             	mov    0x8(%ebp),%eax
80102681:	89 04 24             	mov    %eax,(%esp)
80102684:	e8 b9 fe ff ff       	call   80102542 <iunlock>
  iput(ip);
80102689:	8b 45 08             	mov    0x8(%ebp),%eax
8010268c:	89 04 24             	mov    %eax,(%esp)
8010268f:	e8 13 ff ff ff       	call   801025a7 <iput>
}
80102694:	c9                   	leave  
80102695:	c3                   	ret    

80102696 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80102696:	55                   	push   %ebp
80102697:	89 e5                	mov    %esp,%ebp
80102699:	53                   	push   %ebx
8010269a:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
8010269d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
801026a1:	77 3e                	ja     801026e1 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
801026a3:	8b 45 08             	mov    0x8(%ebp),%eax
801026a6:	8b 55 0c             	mov    0xc(%ebp),%edx
801026a9:	83 c2 04             	add    $0x4,%edx
801026ac:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801026b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026b7:	75 20                	jne    801026d9 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801026b9:	8b 45 08             	mov    0x8(%ebp),%eax
801026bc:	8b 00                	mov    (%eax),%eax
801026be:	89 04 24             	mov    %eax,(%esp)
801026c1:	e8 31 f8 ff ff       	call   80101ef7 <balloc>
801026c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026c9:	8b 45 08             	mov    0x8(%ebp),%eax
801026cc:	8b 55 0c             	mov    0xc(%ebp),%edx
801026cf:	8d 4a 04             	lea    0x4(%edx),%ecx
801026d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026d5:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801026d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026dc:	e9 b1 00 00 00       	jmp    80102792 <bmap+0xfc>
  }
  bn -= NDIRECT;
801026e1:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801026e5:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801026e9:	0f 87 97 00 00 00    	ja     80102786 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801026ef:	8b 45 08             	mov    0x8(%ebp),%eax
801026f2:	8b 40 4c             	mov    0x4c(%eax),%eax
801026f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026fc:	75 19                	jne    80102717 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801026fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102701:	8b 00                	mov    (%eax),%eax
80102703:	89 04 24             	mov    %eax,(%esp)
80102706:	e8 ec f7 ff ff       	call   80101ef7 <balloc>
8010270b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010270e:	8b 45 08             	mov    0x8(%ebp),%eax
80102711:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102714:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80102717:	8b 45 08             	mov    0x8(%ebp),%eax
8010271a:	8b 00                	mov    (%eax),%eax
8010271c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010271f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102723:	89 04 24             	mov    %eax,(%esp)
80102726:	e8 7b da ff ff       	call   801001a6 <bread>
8010272b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
8010272e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102731:	83 c0 18             	add    $0x18,%eax
80102734:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80102737:	8b 45 0c             	mov    0xc(%ebp),%eax
8010273a:	c1 e0 02             	shl    $0x2,%eax
8010273d:	03 45 ec             	add    -0x14(%ebp),%eax
80102740:	8b 00                	mov    (%eax),%eax
80102742:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102745:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102749:	75 2b                	jne    80102776 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
8010274b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010274e:	c1 e0 02             	shl    $0x2,%eax
80102751:	89 c3                	mov    %eax,%ebx
80102753:	03 5d ec             	add    -0x14(%ebp),%ebx
80102756:	8b 45 08             	mov    0x8(%ebp),%eax
80102759:	8b 00                	mov    (%eax),%eax
8010275b:	89 04 24             	mov    %eax,(%esp)
8010275e:	e8 94 f7 ff ff       	call   80101ef7 <balloc>
80102763:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102766:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102769:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
8010276b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010276e:	89 04 24             	mov    %eax,(%esp)
80102771:	e8 f8 19 00 00       	call   8010416e <log_write>
    }
    brelse(bp);
80102776:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102779:	89 04 24             	mov    %eax,(%esp)
8010277c:	e8 96 da ff ff       	call   80100217 <brelse>
    return addr;
80102781:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102784:	eb 0c                	jmp    80102792 <bmap+0xfc>
  }

  panic("bmap: out of range");
80102786:	c7 04 24 94 95 10 80 	movl   $0x80109594,(%esp)
8010278d:	e8 ab dd ff ff       	call   8010053d <panic>
}
80102792:	83 c4 24             	add    $0x24,%esp
80102795:	5b                   	pop    %ebx
80102796:	5d                   	pop    %ebp
80102797:	c3                   	ret    

80102798 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102798:	55                   	push   %ebp
80102799:	89 e5                	mov    %esp,%ebp
8010279b:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010279e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801027a5:	eb 44                	jmp    801027eb <itrunc+0x53>
    if(ip->addrs[i]){
801027a7:	8b 45 08             	mov    0x8(%ebp),%eax
801027aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027ad:	83 c2 04             	add    $0x4,%edx
801027b0:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801027b4:	85 c0                	test   %eax,%eax
801027b6:	74 2f                	je     801027e7 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801027b8:	8b 45 08             	mov    0x8(%ebp),%eax
801027bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027be:	83 c2 04             	add    $0x4,%edx
801027c1:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801027c5:	8b 45 08             	mov    0x8(%ebp),%eax
801027c8:	8b 00                	mov    (%eax),%eax
801027ca:	89 54 24 04          	mov    %edx,0x4(%esp)
801027ce:	89 04 24             	mov    %eax,(%esp)
801027d1:	e8 90 f8 ff ff       	call   80102066 <bfree>
      ip->addrs[i] = 0;
801027d6:	8b 45 08             	mov    0x8(%ebp),%eax
801027d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027dc:	83 c2 04             	add    $0x4,%edx
801027df:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801027e6:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801027e7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801027eb:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801027ef:	7e b6                	jle    801027a7 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801027f1:	8b 45 08             	mov    0x8(%ebp),%eax
801027f4:	8b 40 4c             	mov    0x4c(%eax),%eax
801027f7:	85 c0                	test   %eax,%eax
801027f9:	0f 84 8f 00 00 00    	je     8010288e <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801027ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102802:	8b 50 4c             	mov    0x4c(%eax),%edx
80102805:	8b 45 08             	mov    0x8(%ebp),%eax
80102808:	8b 00                	mov    (%eax),%eax
8010280a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010280e:	89 04 24             	mov    %eax,(%esp)
80102811:	e8 90 d9 ff ff       	call   801001a6 <bread>
80102816:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102819:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010281c:	83 c0 18             	add    $0x18,%eax
8010281f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102822:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102829:	eb 2f                	jmp    8010285a <itrunc+0xc2>
      if(a[j])
8010282b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010282e:	c1 e0 02             	shl    $0x2,%eax
80102831:	03 45 e8             	add    -0x18(%ebp),%eax
80102834:	8b 00                	mov    (%eax),%eax
80102836:	85 c0                	test   %eax,%eax
80102838:	74 1c                	je     80102856 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
8010283a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010283d:	c1 e0 02             	shl    $0x2,%eax
80102840:	03 45 e8             	add    -0x18(%ebp),%eax
80102843:	8b 10                	mov    (%eax),%edx
80102845:	8b 45 08             	mov    0x8(%ebp),%eax
80102848:	8b 00                	mov    (%eax),%eax
8010284a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010284e:	89 04 24             	mov    %eax,(%esp)
80102851:	e8 10 f8 ff ff       	call   80102066 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102856:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010285a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010285d:	83 f8 7f             	cmp    $0x7f,%eax
80102860:	76 c9                	jbe    8010282b <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80102862:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102865:	89 04 24             	mov    %eax,(%esp)
80102868:	e8 aa d9 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
8010286d:	8b 45 08             	mov    0x8(%ebp),%eax
80102870:	8b 50 4c             	mov    0x4c(%eax),%edx
80102873:	8b 45 08             	mov    0x8(%ebp),%eax
80102876:	8b 00                	mov    (%eax),%eax
80102878:	89 54 24 04          	mov    %edx,0x4(%esp)
8010287c:	89 04 24             	mov    %eax,(%esp)
8010287f:	e8 e2 f7 ff ff       	call   80102066 <bfree>
    ip->addrs[NDIRECT] = 0;
80102884:	8b 45 08             	mov    0x8(%ebp),%eax
80102887:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
8010288e:	8b 45 08             	mov    0x8(%ebp),%eax
80102891:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102898:	8b 45 08             	mov    0x8(%ebp),%eax
8010289b:	89 04 24             	mov    %eax,(%esp)
8010289e:	e8 95 f9 ff ff       	call   80102238 <iupdate>
}
801028a3:	c9                   	leave  
801028a4:	c3                   	ret    

801028a5 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
801028a5:	55                   	push   %ebp
801028a6:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
801028a8:	8b 45 08             	mov    0x8(%ebp),%eax
801028ab:	8b 00                	mov    (%eax),%eax
801028ad:	89 c2                	mov    %eax,%edx
801028af:	8b 45 0c             	mov    0xc(%ebp),%eax
801028b2:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801028b5:	8b 45 08             	mov    0x8(%ebp),%eax
801028b8:	8b 50 04             	mov    0x4(%eax),%edx
801028bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801028be:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801028c1:	8b 45 08             	mov    0x8(%ebp),%eax
801028c4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801028c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801028cb:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801028ce:	8b 45 08             	mov    0x8(%ebp),%eax
801028d1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801028d5:	8b 45 0c             	mov    0xc(%ebp),%eax
801028d8:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801028dc:	8b 45 08             	mov    0x8(%ebp),%eax
801028df:	8b 50 18             	mov    0x18(%eax),%edx
801028e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801028e5:	89 50 10             	mov    %edx,0x10(%eax)
}
801028e8:	5d                   	pop    %ebp
801028e9:	c3                   	ret    

801028ea <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801028ea:	55                   	push   %ebp
801028eb:	89 e5                	mov    %esp,%ebp
801028ed:	53                   	push   %ebx
801028ee:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801028f1:	8b 45 08             	mov    0x8(%ebp),%eax
801028f4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801028f8:	66 83 f8 03          	cmp    $0x3,%ax
801028fc:	75 60                	jne    8010295e <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801028fe:	8b 45 08             	mov    0x8(%ebp),%eax
80102901:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102905:	66 85 c0             	test   %ax,%ax
80102908:	78 20                	js     8010292a <readi+0x40>
8010290a:	8b 45 08             	mov    0x8(%ebp),%eax
8010290d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102911:	66 83 f8 09          	cmp    $0x9,%ax
80102915:	7f 13                	jg     8010292a <readi+0x40>
80102917:	8b 45 08             	mov    0x8(%ebp),%eax
8010291a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010291e:	98                   	cwtl   
8010291f:	8b 04 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%eax
80102926:	85 c0                	test   %eax,%eax
80102928:	75 0a                	jne    80102934 <readi+0x4a>
      return -1;
8010292a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010292f:	e9 1b 01 00 00       	jmp    80102a4f <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102934:	8b 45 08             	mov    0x8(%ebp),%eax
80102937:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010293b:	98                   	cwtl   
8010293c:	8b 14 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%edx
80102943:	8b 45 14             	mov    0x14(%ebp),%eax
80102946:	89 44 24 08          	mov    %eax,0x8(%esp)
8010294a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010294d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102951:	8b 45 08             	mov    0x8(%ebp),%eax
80102954:	89 04 24             	mov    %eax,(%esp)
80102957:	ff d2                	call   *%edx
80102959:	e9 f1 00 00 00       	jmp    80102a4f <readi+0x165>
  }

  if(off > ip->size || off + n < off)
8010295e:	8b 45 08             	mov    0x8(%ebp),%eax
80102961:	8b 40 18             	mov    0x18(%eax),%eax
80102964:	3b 45 10             	cmp    0x10(%ebp),%eax
80102967:	72 0d                	jb     80102976 <readi+0x8c>
80102969:	8b 45 14             	mov    0x14(%ebp),%eax
8010296c:	8b 55 10             	mov    0x10(%ebp),%edx
8010296f:	01 d0                	add    %edx,%eax
80102971:	3b 45 10             	cmp    0x10(%ebp),%eax
80102974:	73 0a                	jae    80102980 <readi+0x96>
    return -1;
80102976:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010297b:	e9 cf 00 00 00       	jmp    80102a4f <readi+0x165>
  if(off + n > ip->size)
80102980:	8b 45 14             	mov    0x14(%ebp),%eax
80102983:	8b 55 10             	mov    0x10(%ebp),%edx
80102986:	01 c2                	add    %eax,%edx
80102988:	8b 45 08             	mov    0x8(%ebp),%eax
8010298b:	8b 40 18             	mov    0x18(%eax),%eax
8010298e:	39 c2                	cmp    %eax,%edx
80102990:	76 0c                	jbe    8010299e <readi+0xb4>
    n = ip->size - off;
80102992:	8b 45 08             	mov    0x8(%ebp),%eax
80102995:	8b 40 18             	mov    0x18(%eax),%eax
80102998:	2b 45 10             	sub    0x10(%ebp),%eax
8010299b:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010299e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029a5:	e9 96 00 00 00       	jmp    80102a40 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801029aa:	8b 45 10             	mov    0x10(%ebp),%eax
801029ad:	c1 e8 09             	shr    $0x9,%eax
801029b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801029b4:	8b 45 08             	mov    0x8(%ebp),%eax
801029b7:	89 04 24             	mov    %eax,(%esp)
801029ba:	e8 d7 fc ff ff       	call   80102696 <bmap>
801029bf:	8b 55 08             	mov    0x8(%ebp),%edx
801029c2:	8b 12                	mov    (%edx),%edx
801029c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801029c8:	89 14 24             	mov    %edx,(%esp)
801029cb:	e8 d6 d7 ff ff       	call   801001a6 <bread>
801029d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801029d3:	8b 45 10             	mov    0x10(%ebp),%eax
801029d6:	89 c2                	mov    %eax,%edx
801029d8:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801029de:	b8 00 02 00 00       	mov    $0x200,%eax
801029e3:	89 c1                	mov    %eax,%ecx
801029e5:	29 d1                	sub    %edx,%ecx
801029e7:	89 ca                	mov    %ecx,%edx
801029e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ec:	8b 4d 14             	mov    0x14(%ebp),%ecx
801029ef:	89 cb                	mov    %ecx,%ebx
801029f1:	29 c3                	sub    %eax,%ebx
801029f3:	89 d8                	mov    %ebx,%eax
801029f5:	39 c2                	cmp    %eax,%edx
801029f7:	0f 46 c2             	cmovbe %edx,%eax
801029fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801029fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a00:	8d 50 18             	lea    0x18(%eax),%edx
80102a03:	8b 45 10             	mov    0x10(%ebp),%eax
80102a06:	25 ff 01 00 00       	and    $0x1ff,%eax
80102a0b:	01 c2                	add    %eax,%edx
80102a0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a10:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a14:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a18:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a1b:	89 04 24             	mov    %eax,(%esp)
80102a1e:	e8 52 33 00 00       	call   80105d75 <memmove>
    brelse(bp);
80102a23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a26:	89 04 24             	mov    %eax,(%esp)
80102a29:	e8 e9 d7 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102a2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a31:	01 45 f4             	add    %eax,-0xc(%ebp)
80102a34:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a37:	01 45 10             	add    %eax,0x10(%ebp)
80102a3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a3d:	01 45 0c             	add    %eax,0xc(%ebp)
80102a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a43:	3b 45 14             	cmp    0x14(%ebp),%eax
80102a46:	0f 82 5e ff ff ff    	jb     801029aa <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102a4c:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102a4f:	83 c4 24             	add    $0x24,%esp
80102a52:	5b                   	pop    %ebx
80102a53:	5d                   	pop    %ebp
80102a54:	c3                   	ret    

80102a55 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102a55:	55                   	push   %ebp
80102a56:	89 e5                	mov    %esp,%ebp
80102a58:	53                   	push   %ebx
80102a59:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102a5c:	8b 45 08             	mov    0x8(%ebp),%eax
80102a5f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102a63:	66 83 f8 03          	cmp    $0x3,%ax
80102a67:	75 60                	jne    80102ac9 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102a69:	8b 45 08             	mov    0x8(%ebp),%eax
80102a6c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a70:	66 85 c0             	test   %ax,%ax
80102a73:	78 20                	js     80102a95 <writei+0x40>
80102a75:	8b 45 08             	mov    0x8(%ebp),%eax
80102a78:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a7c:	66 83 f8 09          	cmp    $0x9,%ax
80102a80:	7f 13                	jg     80102a95 <writei+0x40>
80102a82:	8b 45 08             	mov    0x8(%ebp),%eax
80102a85:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a89:	98                   	cwtl   
80102a8a:	8b 04 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%eax
80102a91:	85 c0                	test   %eax,%eax
80102a93:	75 0a                	jne    80102a9f <writei+0x4a>
      return -1;
80102a95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102a9a:	e9 46 01 00 00       	jmp    80102be5 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80102a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102aa6:	98                   	cwtl   
80102aa7:	8b 14 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%edx
80102aae:	8b 45 14             	mov    0x14(%ebp),%eax
80102ab1:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ab5:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ab8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102abc:	8b 45 08             	mov    0x8(%ebp),%eax
80102abf:	89 04 24             	mov    %eax,(%esp)
80102ac2:	ff d2                	call   *%edx
80102ac4:	e9 1c 01 00 00       	jmp    80102be5 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80102ac9:	8b 45 08             	mov    0x8(%ebp),%eax
80102acc:	8b 40 18             	mov    0x18(%eax),%eax
80102acf:	3b 45 10             	cmp    0x10(%ebp),%eax
80102ad2:	72 0d                	jb     80102ae1 <writei+0x8c>
80102ad4:	8b 45 14             	mov    0x14(%ebp),%eax
80102ad7:	8b 55 10             	mov    0x10(%ebp),%edx
80102ada:	01 d0                	add    %edx,%eax
80102adc:	3b 45 10             	cmp    0x10(%ebp),%eax
80102adf:	73 0a                	jae    80102aeb <writei+0x96>
    return -1;
80102ae1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ae6:	e9 fa 00 00 00       	jmp    80102be5 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80102aeb:	8b 45 14             	mov    0x14(%ebp),%eax
80102aee:	8b 55 10             	mov    0x10(%ebp),%edx
80102af1:	01 d0                	add    %edx,%eax
80102af3:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102af8:	76 0a                	jbe    80102b04 <writei+0xaf>
    return -1;
80102afa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102aff:	e9 e1 00 00 00       	jmp    80102be5 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102b04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b0b:	e9 a1 00 00 00       	jmp    80102bb1 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102b10:	8b 45 10             	mov    0x10(%ebp),%eax
80102b13:	c1 e8 09             	shr    $0x9,%eax
80102b16:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b1a:	8b 45 08             	mov    0x8(%ebp),%eax
80102b1d:	89 04 24             	mov    %eax,(%esp)
80102b20:	e8 71 fb ff ff       	call   80102696 <bmap>
80102b25:	8b 55 08             	mov    0x8(%ebp),%edx
80102b28:	8b 12                	mov    (%edx),%edx
80102b2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b2e:	89 14 24             	mov    %edx,(%esp)
80102b31:	e8 70 d6 ff ff       	call   801001a6 <bread>
80102b36:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102b39:	8b 45 10             	mov    0x10(%ebp),%eax
80102b3c:	89 c2                	mov    %eax,%edx
80102b3e:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102b44:	b8 00 02 00 00       	mov    $0x200,%eax
80102b49:	89 c1                	mov    %eax,%ecx
80102b4b:	29 d1                	sub    %edx,%ecx
80102b4d:	89 ca                	mov    %ecx,%edx
80102b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b52:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102b55:	89 cb                	mov    %ecx,%ebx
80102b57:	29 c3                	sub    %eax,%ebx
80102b59:	89 d8                	mov    %ebx,%eax
80102b5b:	39 c2                	cmp    %eax,%edx
80102b5d:	0f 46 c2             	cmovbe %edx,%eax
80102b60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102b63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b66:	8d 50 18             	lea    0x18(%eax),%edx
80102b69:	8b 45 10             	mov    0x10(%ebp),%eax
80102b6c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102b71:	01 c2                	add    %eax,%edx
80102b73:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b76:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b7d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b81:	89 14 24             	mov    %edx,(%esp)
80102b84:	e8 ec 31 00 00       	call   80105d75 <memmove>
    log_write(bp);
80102b89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b8c:	89 04 24             	mov    %eax,(%esp)
80102b8f:	e8 da 15 00 00       	call   8010416e <log_write>
    brelse(bp);
80102b94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b97:	89 04 24             	mov    %eax,(%esp)
80102b9a:	e8 78 d6 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102b9f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ba2:	01 45 f4             	add    %eax,-0xc(%ebp)
80102ba5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ba8:	01 45 10             	add    %eax,0x10(%ebp)
80102bab:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102bae:	01 45 0c             	add    %eax,0xc(%ebp)
80102bb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bb4:	3b 45 14             	cmp    0x14(%ebp),%eax
80102bb7:	0f 82 53 ff ff ff    	jb     80102b10 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102bbd:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102bc1:	74 1f                	je     80102be2 <writei+0x18d>
80102bc3:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc6:	8b 40 18             	mov    0x18(%eax),%eax
80102bc9:	3b 45 10             	cmp    0x10(%ebp),%eax
80102bcc:	73 14                	jae    80102be2 <writei+0x18d>
    ip->size = off;
80102bce:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd1:	8b 55 10             	mov    0x10(%ebp),%edx
80102bd4:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102bd7:	8b 45 08             	mov    0x8(%ebp),%eax
80102bda:	89 04 24             	mov    %eax,(%esp)
80102bdd:	e8 56 f6 ff ff       	call   80102238 <iupdate>
  }
  return n;
80102be2:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102be5:	83 c4 24             	add    $0x24,%esp
80102be8:	5b                   	pop    %ebx
80102be9:	5d                   	pop    %ebp
80102bea:	c3                   	ret    

80102beb <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102beb:	55                   	push   %ebp
80102bec:	89 e5                	mov    %esp,%ebp
80102bee:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102bf1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102bf8:	00 
80102bf9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bfc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c00:	8b 45 08             	mov    0x8(%ebp),%eax
80102c03:	89 04 24             	mov    %eax,(%esp)
80102c06:	e8 0e 32 00 00       	call   80105e19 <strncmp>
}
80102c0b:	c9                   	leave  
80102c0c:	c3                   	ret    

80102c0d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102c0d:	55                   	push   %ebp
80102c0e:	89 e5                	mov    %esp,%ebp
80102c10:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102c13:	8b 45 08             	mov    0x8(%ebp),%eax
80102c16:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102c1a:	66 83 f8 01          	cmp    $0x1,%ax
80102c1e:	74 0c                	je     80102c2c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102c20:	c7 04 24 a7 95 10 80 	movl   $0x801095a7,(%esp)
80102c27:	e8 11 d9 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102c2c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c33:	e9 87 00 00 00       	jmp    80102cbf <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c38:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c3f:	00 
80102c40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c43:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c47:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c4e:	8b 45 08             	mov    0x8(%ebp),%eax
80102c51:	89 04 24             	mov    %eax,(%esp)
80102c54:	e8 91 fc ff ff       	call   801028ea <readi>
80102c59:	83 f8 10             	cmp    $0x10,%eax
80102c5c:	74 0c                	je     80102c6a <dirlookup+0x5d>
      panic("dirlink read");
80102c5e:	c7 04 24 b9 95 10 80 	movl   $0x801095b9,(%esp)
80102c65:	e8 d3 d8 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102c6a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c6e:	66 85 c0             	test   %ax,%ax
80102c71:	74 47                	je     80102cba <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102c73:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c76:	83 c0 02             	add    $0x2,%eax
80102c79:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c80:	89 04 24             	mov    %eax,(%esp)
80102c83:	e8 63 ff ff ff       	call   80102beb <namecmp>
80102c88:	85 c0                	test   %eax,%eax
80102c8a:	75 2f                	jne    80102cbb <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102c8c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102c90:	74 08                	je     80102c9a <dirlookup+0x8d>
        *poff = off;
80102c92:	8b 45 10             	mov    0x10(%ebp),%eax
80102c95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102c98:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102c9a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c9e:	0f b7 c0             	movzwl %ax,%eax
80102ca1:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102ca4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca7:	8b 00                	mov    (%eax),%eax
80102ca9:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102cac:	89 54 24 04          	mov    %edx,0x4(%esp)
80102cb0:	89 04 24             	mov    %eax,(%esp)
80102cb3:	e8 38 f6 ff ff       	call   801022f0 <iget>
80102cb8:	eb 19                	jmp    80102cd3 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102cba:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102cbb:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102cbf:	8b 45 08             	mov    0x8(%ebp),%eax
80102cc2:	8b 40 18             	mov    0x18(%eax),%eax
80102cc5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102cc8:	0f 87 6a ff ff ff    	ja     80102c38 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102cce:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102cd3:	c9                   	leave  
80102cd4:	c3                   	ret    

80102cd5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102cd5:	55                   	push   %ebp
80102cd6:	89 e5                	mov    %esp,%ebp
80102cd8:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102cdb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102ce2:	00 
80102ce3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ce6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cea:	8b 45 08             	mov    0x8(%ebp),%eax
80102ced:	89 04 24             	mov    %eax,(%esp)
80102cf0:	e8 18 ff ff ff       	call   80102c0d <dirlookup>
80102cf5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102cf8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102cfc:	74 15                	je     80102d13 <dirlink+0x3e>
    iput(ip);
80102cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d01:	89 04 24             	mov    %eax,(%esp)
80102d04:	e8 9e f8 ff ff       	call   801025a7 <iput>
    return -1;
80102d09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d0e:	e9 b8 00 00 00       	jmp    80102dcb <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102d13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102d1a:	eb 44                	jmp    80102d60 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d1f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102d26:	00 
80102d27:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d2b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102d2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d32:	8b 45 08             	mov    0x8(%ebp),%eax
80102d35:	89 04 24             	mov    %eax,(%esp)
80102d38:	e8 ad fb ff ff       	call   801028ea <readi>
80102d3d:	83 f8 10             	cmp    $0x10,%eax
80102d40:	74 0c                	je     80102d4e <dirlink+0x79>
      panic("dirlink read");
80102d42:	c7 04 24 b9 95 10 80 	movl   $0x801095b9,(%esp)
80102d49:	e8 ef d7 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102d4e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102d52:	66 85 c0             	test   %ax,%ax
80102d55:	74 18                	je     80102d6f <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102d57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d5a:	83 c0 10             	add    $0x10,%eax
80102d5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d60:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102d63:	8b 45 08             	mov    0x8(%ebp),%eax
80102d66:	8b 40 18             	mov    0x18(%eax),%eax
80102d69:	39 c2                	cmp    %eax,%edx
80102d6b:	72 af                	jb     80102d1c <dirlink+0x47>
80102d6d:	eb 01                	jmp    80102d70 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102d6f:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102d70:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102d77:	00 
80102d78:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d7f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102d82:	83 c0 02             	add    $0x2,%eax
80102d85:	89 04 24             	mov    %eax,(%esp)
80102d88:	e8 e4 30 00 00       	call   80105e71 <strncpy>
  de.inum = inum;
80102d8d:	8b 45 10             	mov    0x10(%ebp),%eax
80102d90:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d97:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102d9e:	00 
80102d9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102da3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102da6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102daa:	8b 45 08             	mov    0x8(%ebp),%eax
80102dad:	89 04 24             	mov    %eax,(%esp)
80102db0:	e8 a0 fc ff ff       	call   80102a55 <writei>
80102db5:	83 f8 10             	cmp    $0x10,%eax
80102db8:	74 0c                	je     80102dc6 <dirlink+0xf1>
    panic("dirlink");
80102dba:	c7 04 24 c6 95 10 80 	movl   $0x801095c6,(%esp)
80102dc1:	e8 77 d7 ff ff       	call   8010053d <panic>
  
  return 0;
80102dc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102dcb:	c9                   	leave  
80102dcc:	c3                   	ret    

80102dcd <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102dcd:	55                   	push   %ebp
80102dce:	89 e5                	mov    %esp,%ebp
80102dd0:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102dd3:	eb 04                	jmp    80102dd9 <skipelem+0xc>
    path++;
80102dd5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102dd9:	8b 45 08             	mov    0x8(%ebp),%eax
80102ddc:	0f b6 00             	movzbl (%eax),%eax
80102ddf:	3c 2f                	cmp    $0x2f,%al
80102de1:	74 f2                	je     80102dd5 <skipelem+0x8>
    path++;
  if(*path == 0)
80102de3:	8b 45 08             	mov    0x8(%ebp),%eax
80102de6:	0f b6 00             	movzbl (%eax),%eax
80102de9:	84 c0                	test   %al,%al
80102deb:	75 0a                	jne    80102df7 <skipelem+0x2a>
    return 0;
80102ded:	b8 00 00 00 00       	mov    $0x0,%eax
80102df2:	e9 86 00 00 00       	jmp    80102e7d <skipelem+0xb0>
  s = path;
80102df7:	8b 45 08             	mov    0x8(%ebp),%eax
80102dfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102dfd:	eb 04                	jmp    80102e03 <skipelem+0x36>
    path++;
80102dff:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102e03:	8b 45 08             	mov    0x8(%ebp),%eax
80102e06:	0f b6 00             	movzbl (%eax),%eax
80102e09:	3c 2f                	cmp    $0x2f,%al
80102e0b:	74 0a                	je     80102e17 <skipelem+0x4a>
80102e0d:	8b 45 08             	mov    0x8(%ebp),%eax
80102e10:	0f b6 00             	movzbl (%eax),%eax
80102e13:	84 c0                	test   %al,%al
80102e15:	75 e8                	jne    80102dff <skipelem+0x32>
    path++;
  len = path - s;
80102e17:	8b 55 08             	mov    0x8(%ebp),%edx
80102e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e1d:	89 d1                	mov    %edx,%ecx
80102e1f:	29 c1                	sub    %eax,%ecx
80102e21:	89 c8                	mov    %ecx,%eax
80102e23:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102e26:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102e2a:	7e 1c                	jle    80102e48 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102e2c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102e33:	00 
80102e34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e37:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e3e:	89 04 24             	mov    %eax,(%esp)
80102e41:	e8 2f 2f 00 00       	call   80105d75 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102e46:	eb 28                	jmp    80102e70 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102e48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e4b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e52:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e56:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e59:	89 04 24             	mov    %eax,(%esp)
80102e5c:	e8 14 2f 00 00       	call   80105d75 <memmove>
    name[len] = 0;
80102e61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e64:	03 45 0c             	add    0xc(%ebp),%eax
80102e67:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102e6a:	eb 04                	jmp    80102e70 <skipelem+0xa3>
    path++;
80102e6c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102e70:	8b 45 08             	mov    0x8(%ebp),%eax
80102e73:	0f b6 00             	movzbl (%eax),%eax
80102e76:	3c 2f                	cmp    $0x2f,%al
80102e78:	74 f2                	je     80102e6c <skipelem+0x9f>
    path++;
  return path;
80102e7a:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102e7d:	c9                   	leave  
80102e7e:	c3                   	ret    

80102e7f <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102e7f:	55                   	push   %ebp
80102e80:	89 e5                	mov    %esp,%ebp
80102e82:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102e85:	8b 45 08             	mov    0x8(%ebp),%eax
80102e88:	0f b6 00             	movzbl (%eax),%eax
80102e8b:	3c 2f                	cmp    $0x2f,%al
80102e8d:	75 1c                	jne    80102eab <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102e8f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102e96:	00 
80102e97:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e9e:	e8 4d f4 ff ff       	call   801022f0 <iget>
80102ea3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102ea6:	e9 af 00 00 00       	jmp    80102f5a <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102eab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102eb1:	8b 40 68             	mov    0x68(%eax),%eax
80102eb4:	89 04 24             	mov    %eax,(%esp)
80102eb7:	e8 06 f5 ff ff       	call   801023c2 <idup>
80102ebc:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102ebf:	e9 96 00 00 00       	jmp    80102f5a <namex+0xdb>
    ilock(ip);
80102ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ec7:	89 04 24             	mov    %eax,(%esp)
80102eca:	e8 25 f5 ff ff       	call   801023f4 <ilock>
    if(ip->type != T_DIR){
80102ecf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ed2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102ed6:	66 83 f8 01          	cmp    $0x1,%ax
80102eda:	74 15                	je     80102ef1 <namex+0x72>
      iunlockput(ip);
80102edc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102edf:	89 04 24             	mov    %eax,(%esp)
80102ee2:	e8 91 f7 ff ff       	call   80102678 <iunlockput>
      return 0;
80102ee7:	b8 00 00 00 00       	mov    $0x0,%eax
80102eec:	e9 a3 00 00 00       	jmp    80102f94 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102ef1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102ef5:	74 1d                	je     80102f14 <namex+0x95>
80102ef7:	8b 45 08             	mov    0x8(%ebp),%eax
80102efa:	0f b6 00             	movzbl (%eax),%eax
80102efd:	84 c0                	test   %al,%al
80102eff:	75 13                	jne    80102f14 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102f01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f04:	89 04 24             	mov    %eax,(%esp)
80102f07:	e8 36 f6 ff ff       	call   80102542 <iunlock>
      return ip;
80102f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f0f:	e9 80 00 00 00       	jmp    80102f94 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102f14:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102f1b:	00 
80102f1c:	8b 45 10             	mov    0x10(%ebp),%eax
80102f1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f26:	89 04 24             	mov    %eax,(%esp)
80102f29:	e8 df fc ff ff       	call   80102c0d <dirlookup>
80102f2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102f31:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102f35:	75 12                	jne    80102f49 <namex+0xca>
      iunlockput(ip);
80102f37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f3a:	89 04 24             	mov    %eax,(%esp)
80102f3d:	e8 36 f7 ff ff       	call   80102678 <iunlockput>
      return 0;
80102f42:	b8 00 00 00 00       	mov    $0x0,%eax
80102f47:	eb 4b                	jmp    80102f94 <namex+0x115>
    }
    iunlockput(ip);
80102f49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f4c:	89 04 24             	mov    %eax,(%esp)
80102f4f:	e8 24 f7 ff ff       	call   80102678 <iunlockput>
    ip = next;
80102f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f57:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102f5a:	8b 45 10             	mov    0x10(%ebp),%eax
80102f5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f61:	8b 45 08             	mov    0x8(%ebp),%eax
80102f64:	89 04 24             	mov    %eax,(%esp)
80102f67:	e8 61 fe ff ff       	call   80102dcd <skipelem>
80102f6c:	89 45 08             	mov    %eax,0x8(%ebp)
80102f6f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102f73:	0f 85 4b ff ff ff    	jne    80102ec4 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102f79:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f7d:	74 12                	je     80102f91 <namex+0x112>
    iput(ip);
80102f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f82:	89 04 24             	mov    %eax,(%esp)
80102f85:	e8 1d f6 ff ff       	call   801025a7 <iput>
    return 0;
80102f8a:	b8 00 00 00 00       	mov    $0x0,%eax
80102f8f:	eb 03                	jmp    80102f94 <namex+0x115>
  }
  return ip;
80102f91:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102f94:	c9                   	leave  
80102f95:	c3                   	ret    

80102f96 <namei>:

struct inode*
namei(char *path)
{
80102f96:	55                   	push   %ebp
80102f97:	89 e5                	mov    %esp,%ebp
80102f99:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102f9c:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102f9f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fa3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102faa:	00 
80102fab:	8b 45 08             	mov    0x8(%ebp),%eax
80102fae:	89 04 24             	mov    %eax,(%esp)
80102fb1:	e8 c9 fe ff ff       	call   80102e7f <namex>
}
80102fb6:	c9                   	leave  
80102fb7:	c3                   	ret    

80102fb8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102fb8:	55                   	push   %ebp
80102fb9:	89 e5                	mov    %esp,%ebp
80102fbb:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102fbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fc1:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fc5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102fcc:	00 
80102fcd:	8b 45 08             	mov    0x8(%ebp),%eax
80102fd0:	89 04 24             	mov    %eax,(%esp)
80102fd3:	e8 a7 fe ff ff       	call   80102e7f <namex>
}
80102fd8:	c9                   	leave  
80102fd9:	c3                   	ret    

80102fda <getNextInode>:

struct inode*
getNextInode(void)
{
80102fda:	55                   	push   %ebp
80102fdb:	89 e5                	mov    %esp,%ebp
80102fdd:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80102fe0:	8d 45 d8             	lea    -0x28(%ebp),%eax
80102fe3:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fe7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fee:	e8 6d ee ff ff       	call   80101e60 <readsb>
  cprintf("in getnextinode\n");
80102ff3:	c7 04 24 ce 95 10 80 	movl   $0x801095ce,(%esp)
80102ffa:	e8 a2 d3 ff ff       	call   801003a1 <cprintf>
  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80102fff:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103004:	83 c0 01             	add    $0x1,%eax
80103007:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010300a:	e9 85 00 00 00       	jmp    80103094 <getNextInode+0xba>
  {cprintf("in getnextinode for\n");
8010300f:	c7 04 24 df 95 10 80 	movl   $0x801095df,(%esp)
80103016:	e8 86 d3 ff ff       	call   801003a1 <cprintf>
    bp = bread(1, IBLOCK(inum));
8010301b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010301e:	c1 e8 03             	shr    $0x3,%eax
80103021:	83 c0 02             	add    $0x2,%eax
80103024:	89 44 24 04          	mov    %eax,0x4(%esp)
80103028:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010302f:	e8 72 d1 ff ff       	call   801001a6 <bread>
80103034:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80103037:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010303a:	8d 50 18             	lea    0x18(%eax),%edx
8010303d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103040:	83 e0 07             	and    $0x7,%eax
80103043:	c1 e0 06             	shl    $0x6,%eax
80103046:	01 d0                	add    %edx,%eax
80103048:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
8010304b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010304e:	0f b7 00             	movzwl (%eax),%eax
80103051:	66 83 f8 02          	cmp    $0x2,%ax
80103055:	75 2e                	jne    80103085 <getNextInode+0xab>
    {
      nextInum = inum;
80103057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010305a:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      ip = iget(1,inum);
8010305f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103062:	89 44 24 04          	mov    %eax,0x4(%esp)
80103066:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010306d:	e8 7e f2 ff ff       	call   801022f0 <iget>
80103072:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
80103075:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103078:	89 04 24             	mov    %eax,(%esp)
8010307b:	e8 97 d1 ff ff       	call   80100217 <brelse>
      return ip;
80103080:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103083:	eb 25                	jmp    801030aa <getNextInode+0xd0>
    }
    brelse(bp);
80103085:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103088:	89 04 24             	mov    %eax,(%esp)
8010308b:	e8 87 d1 ff ff       	call   80100217 <brelse>
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  cprintf("in getnextinode\n");
  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80103090:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103094:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103097:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010309a:	83 ea 01             	sub    $0x1,%edx
8010309d:	39 d0                	cmp    %edx,%eax
8010309f:	0f 82 6a ff ff ff    	jb     8010300f <getNextInode+0x35>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
801030a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030aa:	c9                   	leave  
801030ab:	c3                   	ret    

801030ac <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
801030ac:	55                   	push   %ebp
801030ad:	89 e5                	mov    %esp,%ebp
801030af:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801030b2:	e9 8d 00 00 00       	jmp    80103144 <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
801030b7:	8b 45 08             	mov    0x8(%ebp),%eax
801030ba:	8b 00                	mov    (%eax),%eax
801030bc:	c1 e8 03             	shr    $0x3,%eax
801030bf:	83 c0 02             	add    $0x2,%eax
801030c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801030c6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801030cd:	e8 d4 d0 ff ff       	call   801001a6 <bread>
801030d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
801030d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030d8:	8d 50 18             	lea    0x18(%eax),%edx
801030db:	8b 45 08             	mov    0x8(%ebp),%eax
801030de:	8b 00                	mov    (%eax),%eax
801030e0:	83 e0 07             	and    $0x7,%eax
801030e3:	c1 e0 06             	shl    $0x6,%eax
801030e6:	01 d0                	add    %edx,%eax
801030e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
801030eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030ee:	0f b7 00             	movzwl (%eax),%eax
801030f1:	66 83 f8 02          	cmp    $0x2,%ax
801030f5:	75 35                	jne    8010312c <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
801030f7:	8b 45 08             	mov    0x8(%ebp),%eax
801030fa:	8b 00                	mov    (%eax),%eax
801030fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103100:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103107:	e8 e4 f1 ff ff       	call   801022f0 <iget>
8010310c:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
8010310f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103112:	89 04 24             	mov    %eax,(%esp)
80103115:	e8 fd d0 ff ff       	call   80100217 <brelse>
      (*prevInum)--;
8010311a:	8b 45 08             	mov    0x8(%ebp),%eax
8010311d:	8b 00                	mov    (%eax),%eax
8010311f:	8d 50 ff             	lea    -0x1(%eax),%edx
80103122:	8b 45 08             	mov    0x8(%ebp),%eax
80103125:	89 10                	mov    %edx,(%eax)
      return ip;
80103127:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010312a:	eb 2f                	jmp    8010315b <getPrevInode+0xaf>
    }
    brelse(bp);
8010312c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010312f:	89 04 24             	mov    %eax,(%esp)
80103132:	e8 e0 d0 ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
80103137:	8b 45 08             	mov    0x8(%ebp),%eax
8010313a:	8b 00                	mov    (%eax),%eax
8010313c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010313f:	8b 45 08             	mov    0x8(%ebp),%eax
80103142:	89 10                	mov    %edx,(%eax)
80103144:	8b 45 08             	mov    0x8(%ebp),%eax
80103147:	8b 10                	mov    (%eax),%edx
80103149:	a1 18 c6 10 80       	mov    0x8010c618,%eax
8010314e:	39 c2                	cmp    %eax,%edx
80103150:	0f 8f 61 ff ff ff    	jg     801030b7 <getPrevInode+0xb>
      (*prevInum)--;
      return ip;
    }
    brelse(bp);
  }
  return 0;
80103156:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010315b:	c9                   	leave  
8010315c:	c3                   	ret    

8010315d <updateBlkRef>:


void
updateBlkRef(uint sector, int flag)
{
8010315d:	55                   	push   %ebp
8010315e:	89 e5                	mov    %esp,%ebp
80103160:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  if(sector < 512)
80103163:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
8010316a:	0f 87 89 00 00 00    	ja     801031f9 <updateBlkRef+0x9c>
  {
    bp = bread(1,1024);
80103170:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103177:	00 
80103178:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010317f:	e8 22 d0 ff ff       	call   801001a6 <bread>
80103184:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103187:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
8010318b:	75 1e                	jne    801031ab <updateBlkRef+0x4e>
      bp->data[sector]++;
8010318d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103190:	03 45 08             	add    0x8(%ebp),%eax
80103193:	83 c0 10             	add    $0x10,%eax
80103196:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010319a:	8d 50 01             	lea    0x1(%eax),%edx
8010319d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031a0:	03 45 08             	add    0x8(%ebp),%eax
801031a3:	83 c0 10             	add    $0x10,%eax
801031a6:	88 50 08             	mov    %dl,0x8(%eax)
801031a9:	eb 33                	jmp    801031de <updateBlkRef+0x81>
    else if(flag == -1)
801031ab:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801031af:	75 2d                	jne    801031de <updateBlkRef+0x81>
      if(bp->data[sector] > 0)
801031b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031b4:	03 45 08             	add    0x8(%ebp),%eax
801031b7:	83 c0 10             	add    $0x10,%eax
801031ba:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801031be:	84 c0                	test   %al,%al
801031c0:	74 1c                	je     801031de <updateBlkRef+0x81>
	bp->data[sector]--;
801031c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c5:	03 45 08             	add    0x8(%ebp),%eax
801031c8:	83 c0 10             	add    $0x10,%eax
801031cb:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801031cf:	8d 50 ff             	lea    -0x1(%eax),%edx
801031d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031d5:	03 45 08             	add    0x8(%ebp),%eax
801031d8:	83 c0 10             	add    $0x10,%eax
801031db:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
801031de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031e1:	89 04 24             	mov    %eax,(%esp)
801031e4:	e8 f4 cf ff ff       	call   801001dd <bwrite>
    brelse(bp);
801031e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ec:	89 04 24             	mov    %eax,(%esp)
801031ef:	e8 23 d0 ff ff       	call   80100217 <brelse>
801031f4:	e9 91 00 00 00       	jmp    8010328a <updateBlkRef+0x12d>
  }
  else if(sector < 1024)
801031f9:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103200:	0f 87 84 00 00 00    	ja     8010328a <updateBlkRef+0x12d>
  {
    bp = bread(1,1025);
80103206:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
8010320d:	00 
8010320e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103215:	e8 8c cf ff ff       	call   801001a6 <bread>
8010321a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
8010321d:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103221:	75 1c                	jne    8010323f <updateBlkRef+0xe2>
      bp->data[sector-512]++;
80103223:	8b 45 08             	mov    0x8(%ebp),%eax
80103226:	2d 00 02 00 00       	sub    $0x200,%eax
8010322b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010322e:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80103233:	8d 4a 01             	lea    0x1(%edx),%ecx
80103236:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103239:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
8010323d:	eb 35                	jmp    80103274 <updateBlkRef+0x117>
    else if(flag == -1)
8010323f:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
80103243:	75 2f                	jne    80103274 <updateBlkRef+0x117>
      if(bp->data[sector-512] > 0)
80103245:	8b 45 08             	mov    0x8(%ebp),%eax
80103248:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
8010324e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103251:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
80103256:	84 c0                	test   %al,%al
80103258:	74 1a                	je     80103274 <updateBlkRef+0x117>
	bp->data[sector-512]--;
8010325a:	8b 45 08             	mov    0x8(%ebp),%eax
8010325d:	2d 00 02 00 00       	sub    $0x200,%eax
80103262:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103265:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010326a:	8d 4a ff             	lea    -0x1(%edx),%ecx
8010326d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103270:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
80103274:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103277:	89 04 24             	mov    %eax,(%esp)
8010327a:	e8 5e cf ff ff       	call   801001dd <bwrite>
    brelse(bp);
8010327f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103282:	89 04 24             	mov    %eax,(%esp)
80103285:	e8 8d cf ff ff       	call   80100217 <brelse>
  }  
}
8010328a:	c9                   	leave  
8010328b:	c3                   	ret    

8010328c <getBlkRef>:

int
getBlkRef(uint sector)
{
8010328c:	55                   	push   %ebp
8010328d:	89 e5                	mov    %esp,%ebp
8010328f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1;
80103292:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  
  if(sector < 512)
80103299:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801032a0:	77 19                	ja     801032bb <getBlkRef+0x2f>
    bp = bread(1,1024);
801032a2:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801032a9:	00 
801032aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032b1:	e8 f0 ce ff ff       	call   801001a6 <bread>
801032b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801032b9:	eb 20                	jmp    801032db <getBlkRef+0x4f>
  else if(sector < 1024)
801032bb:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801032c2:	77 17                	ja     801032db <getBlkRef+0x4f>
    bp = bread(1,1025);
801032c4:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
801032cb:	00 
801032cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032d3:	e8 ce ce ff ff       	call   801001a6 <bread>
801032d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ret = bp->data[sector];
801032db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032de:	03 45 08             	add    0x8(%ebp),%eax
801032e1:	83 c0 10             	add    $0x10,%eax
801032e4:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801032e8:	0f b6 c0             	movzbl %al,%eax
801032eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  brelse(bp);
801032ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032f1:	89 04 24             	mov    %eax,(%esp)
801032f4:	e8 1e cf ff ff       	call   80100217 <brelse>
  return ret;
801032f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801032fc:	c9                   	leave  
801032fd:	c3                   	ret    
	...

80103300 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103300:	55                   	push   %ebp
80103301:	89 e5                	mov    %esp,%ebp
80103303:	53                   	push   %ebx
80103304:	83 ec 14             	sub    $0x14,%esp
80103307:	8b 45 08             	mov    0x8(%ebp),%eax
8010330a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010330e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103312:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103316:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010331a:	ec                   	in     (%dx),%al
8010331b:	89 c3                	mov    %eax,%ebx
8010331d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103320:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103324:	83 c4 14             	add    $0x14,%esp
80103327:	5b                   	pop    %ebx
80103328:	5d                   	pop    %ebp
80103329:	c3                   	ret    

8010332a <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010332a:	55                   	push   %ebp
8010332b:	89 e5                	mov    %esp,%ebp
8010332d:	57                   	push   %edi
8010332e:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010332f:	8b 55 08             	mov    0x8(%ebp),%edx
80103332:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103335:	8b 45 10             	mov    0x10(%ebp),%eax
80103338:	89 cb                	mov    %ecx,%ebx
8010333a:	89 df                	mov    %ebx,%edi
8010333c:	89 c1                	mov    %eax,%ecx
8010333e:	fc                   	cld    
8010333f:	f3 6d                	rep insl (%dx),%es:(%edi)
80103341:	89 c8                	mov    %ecx,%eax
80103343:	89 fb                	mov    %edi,%ebx
80103345:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103348:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010334b:	5b                   	pop    %ebx
8010334c:	5f                   	pop    %edi
8010334d:	5d                   	pop    %ebp
8010334e:	c3                   	ret    

8010334f <outb>:

static inline void
outb(ushort port, uchar data)
{
8010334f:	55                   	push   %ebp
80103350:	89 e5                	mov    %esp,%ebp
80103352:	83 ec 08             	sub    $0x8,%esp
80103355:	8b 55 08             	mov    0x8(%ebp),%edx
80103358:	8b 45 0c             	mov    0xc(%ebp),%eax
8010335b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010335f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103362:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103366:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010336a:	ee                   	out    %al,(%dx)
}
8010336b:	c9                   	leave  
8010336c:	c3                   	ret    

8010336d <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
8010336d:	55                   	push   %ebp
8010336e:	89 e5                	mov    %esp,%ebp
80103370:	56                   	push   %esi
80103371:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80103372:	8b 55 08             	mov    0x8(%ebp),%edx
80103375:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103378:	8b 45 10             	mov    0x10(%ebp),%eax
8010337b:	89 cb                	mov    %ecx,%ebx
8010337d:	89 de                	mov    %ebx,%esi
8010337f:	89 c1                	mov    %eax,%ecx
80103381:	fc                   	cld    
80103382:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80103384:	89 c8                	mov    %ecx,%eax
80103386:	89 f3                	mov    %esi,%ebx
80103388:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010338b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010338e:	5b                   	pop    %ebx
8010338f:	5e                   	pop    %esi
80103390:	5d                   	pop    %ebp
80103391:	c3                   	ret    

80103392 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80103392:	55                   	push   %ebp
80103393:	89 e5                	mov    %esp,%ebp
80103395:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80103398:	90                   	nop
80103399:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801033a0:	e8 5b ff ff ff       	call   80103300 <inb>
801033a5:	0f b6 c0             	movzbl %al,%eax
801033a8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801033ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033ae:	25 c0 00 00 00       	and    $0xc0,%eax
801033b3:	83 f8 40             	cmp    $0x40,%eax
801033b6:	75 e1                	jne    80103399 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801033b8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801033bc:	74 11                	je     801033cf <idewait+0x3d>
801033be:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033c1:	83 e0 21             	and    $0x21,%eax
801033c4:	85 c0                	test   %eax,%eax
801033c6:	74 07                	je     801033cf <idewait+0x3d>
    return -1;
801033c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033cd:	eb 05                	jmp    801033d4 <idewait+0x42>
  return 0;
801033cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033d4:	c9                   	leave  
801033d5:	c3                   	ret    

801033d6 <ideinit>:

void
ideinit(void)
{
801033d6:	55                   	push   %ebp
801033d7:	89 e5                	mov    %esp,%ebp
801033d9:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801033dc:	c7 44 24 04 f4 95 10 	movl   $0x801095f4,0x4(%esp)
801033e3:	80 
801033e4:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801033eb:	e8 42 26 00 00       	call   80105a32 <initlock>
  picenable(IRQ_IDE);
801033f0:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801033f7:	e8 75 15 00 00       	call   80104971 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801033fc:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80103401:	83 e8 01             	sub    $0x1,%eax
80103404:	89 44 24 04          	mov    %eax,0x4(%esp)
80103408:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010340f:	e8 12 04 00 00       	call   80103826 <ioapicenable>
  idewait(0);
80103414:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010341b:	e8 72 ff ff ff       	call   80103392 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103420:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80103427:	00 
80103428:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010342f:	e8 1b ff ff ff       	call   8010334f <outb>
  for(i=0; i<1000; i++){
80103434:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010343b:	eb 20                	jmp    8010345d <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010343d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103444:	e8 b7 fe ff ff       	call   80103300 <inb>
80103449:	84 c0                	test   %al,%al
8010344b:	74 0c                	je     80103459 <ideinit+0x83>
      havedisk1 = 1;
8010344d:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80103454:	00 00 00 
      break;
80103457:	eb 0d                	jmp    80103466 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80103459:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010345d:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80103464:	7e d7                	jle    8010343d <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80103466:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
8010346d:	00 
8010346e:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103475:	e8 d5 fe ff ff       	call   8010334f <outb>
}
8010347a:	c9                   	leave  
8010347b:	c3                   	ret    

8010347c <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010347c:	55                   	push   %ebp
8010347d:	89 e5                	mov    %esp,%ebp
8010347f:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80103482:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103486:	75 0c                	jne    80103494 <idestart+0x18>
    panic("idestart");
80103488:	c7 04 24 f8 95 10 80 	movl   $0x801095f8,(%esp)
8010348f:	e8 a9 d0 ff ff       	call   8010053d <panic>

  idewait(0);
80103494:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010349b:	e8 f2 fe ff ff       	call   80103392 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801034a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034a7:	00 
801034a8:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801034af:	e8 9b fe ff ff       	call   8010334f <outb>
  outb(0x1f2, 1);  // number of sectors
801034b4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801034bb:	00 
801034bc:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801034c3:	e8 87 fe ff ff       	call   8010334f <outb>
  outb(0x1f3, b->sector & 0xff);
801034c8:	8b 45 08             	mov    0x8(%ebp),%eax
801034cb:	8b 40 08             	mov    0x8(%eax),%eax
801034ce:	0f b6 c0             	movzbl %al,%eax
801034d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801034d5:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801034dc:	e8 6e fe ff ff       	call   8010334f <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801034e1:	8b 45 08             	mov    0x8(%ebp),%eax
801034e4:	8b 40 08             	mov    0x8(%eax),%eax
801034e7:	c1 e8 08             	shr    $0x8,%eax
801034ea:	0f b6 c0             	movzbl %al,%eax
801034ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801034f1:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801034f8:	e8 52 fe ff ff       	call   8010334f <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801034fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103500:	8b 40 08             	mov    0x8(%eax),%eax
80103503:	c1 e8 10             	shr    $0x10,%eax
80103506:	0f b6 c0             	movzbl %al,%eax
80103509:	89 44 24 04          	mov    %eax,0x4(%esp)
8010350d:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80103514:	e8 36 fe ff ff       	call   8010334f <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80103519:	8b 45 08             	mov    0x8(%ebp),%eax
8010351c:	8b 40 04             	mov    0x4(%eax),%eax
8010351f:	83 e0 01             	and    $0x1,%eax
80103522:	89 c2                	mov    %eax,%edx
80103524:	c1 e2 04             	shl    $0x4,%edx
80103527:	8b 45 08             	mov    0x8(%ebp),%eax
8010352a:	8b 40 08             	mov    0x8(%eax),%eax
8010352d:	c1 e8 18             	shr    $0x18,%eax
80103530:	83 e0 0f             	and    $0xf,%eax
80103533:	09 d0                	or     %edx,%eax
80103535:	83 c8 e0             	or     $0xffffffe0,%eax
80103538:	0f b6 c0             	movzbl %al,%eax
8010353b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010353f:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103546:	e8 04 fe ff ff       	call   8010334f <outb>
  if(b->flags & B_DIRTY){
8010354b:	8b 45 08             	mov    0x8(%ebp),%eax
8010354e:	8b 00                	mov    (%eax),%eax
80103550:	83 e0 04             	and    $0x4,%eax
80103553:	85 c0                	test   %eax,%eax
80103555:	74 34                	je     8010358b <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80103557:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
8010355e:	00 
8010355f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103566:	e8 e4 fd ff ff       	call   8010334f <outb>
    outsl(0x1f0, b->data, 512/4);
8010356b:	8b 45 08             	mov    0x8(%ebp),%eax
8010356e:	83 c0 18             	add    $0x18,%eax
80103571:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103578:	00 
80103579:	89 44 24 04          	mov    %eax,0x4(%esp)
8010357d:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103584:	e8 e4 fd ff ff       	call   8010336d <outsl>
80103589:	eb 14                	jmp    8010359f <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010358b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103592:	00 
80103593:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010359a:	e8 b0 fd ff ff       	call   8010334f <outb>
  }
}
8010359f:	c9                   	leave  
801035a0:	c3                   	ret    

801035a1 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801035a1:	55                   	push   %ebp
801035a2:	89 e5                	mov    %esp,%ebp
801035a4:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801035a7:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801035ae:	e8 a0 24 00 00       	call   80105a53 <acquire>
  if((b = idequeue) == 0){
801035b3:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801035b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801035bb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801035bf:	75 11                	jne    801035d2 <ideintr+0x31>
    release(&idelock);
801035c1:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801035c8:	e8 e8 24 00 00       	call   80105ab5 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801035cd:	e9 90 00 00 00       	jmp    80103662 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801035d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d5:	8b 40 14             	mov    0x14(%eax),%eax
801035d8:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801035dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035e0:	8b 00                	mov    (%eax),%eax
801035e2:	83 e0 04             	and    $0x4,%eax
801035e5:	85 c0                	test   %eax,%eax
801035e7:	75 2e                	jne    80103617 <ideintr+0x76>
801035e9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035f0:	e8 9d fd ff ff       	call   80103392 <idewait>
801035f5:	85 c0                	test   %eax,%eax
801035f7:	78 1e                	js     80103617 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801035f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035fc:	83 c0 18             	add    $0x18,%eax
801035ff:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103606:	00 
80103607:	89 44 24 04          	mov    %eax,0x4(%esp)
8010360b:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103612:	e8 13 fd ff ff       	call   8010332a <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80103617:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010361a:	8b 00                	mov    (%eax),%eax
8010361c:	89 c2                	mov    %eax,%edx
8010361e:	83 ca 02             	or     $0x2,%edx
80103621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103624:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80103626:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103629:	8b 00                	mov    (%eax),%eax
8010362b:	89 c2                	mov    %eax,%edx
8010362d:	83 e2 fb             	and    $0xfffffffb,%edx
80103630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103633:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103635:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103638:	89 04 24             	mov    %eax,(%esp)
8010363b:	e8 0e 22 00 00       	call   8010584e <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103640:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103645:	85 c0                	test   %eax,%eax
80103647:	74 0d                	je     80103656 <ideintr+0xb5>
    idestart(idequeue);
80103649:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010364e:	89 04 24             	mov    %eax,(%esp)
80103651:	e8 26 fe ff ff       	call   8010347c <idestart>

  release(&idelock);
80103656:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010365d:	e8 53 24 00 00       	call   80105ab5 <release>
}
80103662:	c9                   	leave  
80103663:	c3                   	ret    

80103664 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103664:	55                   	push   %ebp
80103665:	89 e5                	mov    %esp,%ebp
80103667:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
8010366a:	8b 45 08             	mov    0x8(%ebp),%eax
8010366d:	8b 00                	mov    (%eax),%eax
8010366f:	83 e0 01             	and    $0x1,%eax
80103672:	85 c0                	test   %eax,%eax
80103674:	75 0c                	jne    80103682 <iderw+0x1e>
    panic("iderw: buf not busy");
80103676:	c7 04 24 01 96 10 80 	movl   $0x80109601,(%esp)
8010367d:	e8 bb ce ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103682:	8b 45 08             	mov    0x8(%ebp),%eax
80103685:	8b 00                	mov    (%eax),%eax
80103687:	83 e0 06             	and    $0x6,%eax
8010368a:	83 f8 02             	cmp    $0x2,%eax
8010368d:	75 0c                	jne    8010369b <iderw+0x37>
    panic("iderw: nothing to do");
8010368f:	c7 04 24 15 96 10 80 	movl   $0x80109615,(%esp)
80103696:	e8 a2 ce ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
8010369b:	8b 45 08             	mov    0x8(%ebp),%eax
8010369e:	8b 40 04             	mov    0x4(%eax),%eax
801036a1:	85 c0                	test   %eax,%eax
801036a3:	74 15                	je     801036ba <iderw+0x56>
801036a5:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801036aa:	85 c0                	test   %eax,%eax
801036ac:	75 0c                	jne    801036ba <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801036ae:	c7 04 24 2a 96 10 80 	movl   $0x8010962a,(%esp)
801036b5:	e8 83 ce ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801036ba:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801036c1:	e8 8d 23 00 00       	call   80105a53 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801036c6:	8b 45 08             	mov    0x8(%ebp),%eax
801036c9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801036d0:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801036d7:	eb 0b                	jmp    801036e4 <iderw+0x80>
801036d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036dc:	8b 00                	mov    (%eax),%eax
801036de:	83 c0 14             	add    $0x14,%eax
801036e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801036e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036e7:	8b 00                	mov    (%eax),%eax
801036e9:	85 c0                	test   %eax,%eax
801036eb:	75 ec                	jne    801036d9 <iderw+0x75>
    ;
  *pp = b;
801036ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036f0:	8b 55 08             	mov    0x8(%ebp),%edx
801036f3:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801036f5:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801036fa:	3b 45 08             	cmp    0x8(%ebp),%eax
801036fd:	75 22                	jne    80103721 <iderw+0xbd>
    idestart(b);
801036ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103702:	89 04 24             	mov    %eax,(%esp)
80103705:	e8 72 fd ff ff       	call   8010347c <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010370a:	eb 15                	jmp    80103721 <iderw+0xbd>
    sleep(b, &idelock);
8010370c:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103713:	80 
80103714:	8b 45 08             	mov    0x8(%ebp),%eax
80103717:	89 04 24             	mov    %eax,(%esp)
8010371a:	e8 56 20 00 00       	call   80105775 <sleep>
8010371f:	eb 01                	jmp    80103722 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103721:	90                   	nop
80103722:	8b 45 08             	mov    0x8(%ebp),%eax
80103725:	8b 00                	mov    (%eax),%eax
80103727:	83 e0 06             	and    $0x6,%eax
8010372a:	83 f8 02             	cmp    $0x2,%eax
8010372d:	75 dd                	jne    8010370c <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
8010372f:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103736:	e8 7a 23 00 00       	call   80105ab5 <release>
}
8010373b:	c9                   	leave  
8010373c:	c3                   	ret    
8010373d:	00 00                	add    %al,(%eax)
	...

80103740 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103740:	55                   	push   %ebp
80103741:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103743:	a1 54 08 11 80       	mov    0x80110854,%eax
80103748:	8b 55 08             	mov    0x8(%ebp),%edx
8010374b:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
8010374d:	a1 54 08 11 80       	mov    0x80110854,%eax
80103752:	8b 40 10             	mov    0x10(%eax),%eax
}
80103755:	5d                   	pop    %ebp
80103756:	c3                   	ret    

80103757 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103757:	55                   	push   %ebp
80103758:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010375a:	a1 54 08 11 80       	mov    0x80110854,%eax
8010375f:	8b 55 08             	mov    0x8(%ebp),%edx
80103762:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103764:	a1 54 08 11 80       	mov    0x80110854,%eax
80103769:	8b 55 0c             	mov    0xc(%ebp),%edx
8010376c:	89 50 10             	mov    %edx,0x10(%eax)
}
8010376f:	5d                   	pop    %ebp
80103770:	c3                   	ret    

80103771 <ioapicinit>:

void
ioapicinit(void)
{
80103771:	55                   	push   %ebp
80103772:	89 e5                	mov    %esp,%ebp
80103774:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103777:	a1 24 09 11 80       	mov    0x80110924,%eax
8010377c:	85 c0                	test   %eax,%eax
8010377e:	0f 84 9f 00 00 00    	je     80103823 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103784:	c7 05 54 08 11 80 00 	movl   $0xfec00000,0x80110854
8010378b:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
8010378e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103795:	e8 a6 ff ff ff       	call   80103740 <ioapicread>
8010379a:	c1 e8 10             	shr    $0x10,%eax
8010379d:	25 ff 00 00 00       	and    $0xff,%eax
801037a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801037a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037ac:	e8 8f ff ff ff       	call   80103740 <ioapicread>
801037b1:	c1 e8 18             	shr    $0x18,%eax
801037b4:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801037b7:	0f b6 05 20 09 11 80 	movzbl 0x80110920,%eax
801037be:	0f b6 c0             	movzbl %al,%eax
801037c1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801037c4:	74 0c                	je     801037d2 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801037c6:	c7 04 24 48 96 10 80 	movl   $0x80109648,(%esp)
801037cd:	e8 cf cb ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801037d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037d9:	eb 3e                	jmp    80103819 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801037db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037de:	83 c0 20             	add    $0x20,%eax
801037e1:	0d 00 00 01 00       	or     $0x10000,%eax
801037e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037e9:	83 c2 08             	add    $0x8,%edx
801037ec:	01 d2                	add    %edx,%edx
801037ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801037f2:	89 14 24             	mov    %edx,(%esp)
801037f5:	e8 5d ff ff ff       	call   80103757 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801037fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037fd:	83 c0 08             	add    $0x8,%eax
80103800:	01 c0                	add    %eax,%eax
80103802:	83 c0 01             	add    $0x1,%eax
80103805:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010380c:	00 
8010380d:	89 04 24             	mov    %eax,(%esp)
80103810:	e8 42 ff ff ff       	call   80103757 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103815:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010381c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010381f:	7e ba                	jle    801037db <ioapicinit+0x6a>
80103821:	eb 01                	jmp    80103824 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103823:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103824:	c9                   	leave  
80103825:	c3                   	ret    

80103826 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103826:	55                   	push   %ebp
80103827:	89 e5                	mov    %esp,%ebp
80103829:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
8010382c:	a1 24 09 11 80       	mov    0x80110924,%eax
80103831:	85 c0                	test   %eax,%eax
80103833:	74 39                	je     8010386e <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103835:	8b 45 08             	mov    0x8(%ebp),%eax
80103838:	83 c0 20             	add    $0x20,%eax
8010383b:	8b 55 08             	mov    0x8(%ebp),%edx
8010383e:	83 c2 08             	add    $0x8,%edx
80103841:	01 d2                	add    %edx,%edx
80103843:	89 44 24 04          	mov    %eax,0x4(%esp)
80103847:	89 14 24             	mov    %edx,(%esp)
8010384a:	e8 08 ff ff ff       	call   80103757 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
8010384f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103852:	c1 e0 18             	shl    $0x18,%eax
80103855:	8b 55 08             	mov    0x8(%ebp),%edx
80103858:	83 c2 08             	add    $0x8,%edx
8010385b:	01 d2                	add    %edx,%edx
8010385d:	83 c2 01             	add    $0x1,%edx
80103860:	89 44 24 04          	mov    %eax,0x4(%esp)
80103864:	89 14 24             	mov    %edx,(%esp)
80103867:	e8 eb fe ff ff       	call   80103757 <ioapicwrite>
8010386c:	eb 01                	jmp    8010386f <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
8010386e:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
8010386f:	c9                   	leave  
80103870:	c3                   	ret    
80103871:	00 00                	add    %al,(%eax)
	...

80103874 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103874:	55                   	push   %ebp
80103875:	89 e5                	mov    %esp,%ebp
80103877:	8b 45 08             	mov    0x8(%ebp),%eax
8010387a:	05 00 00 00 80       	add    $0x80000000,%eax
8010387f:	5d                   	pop    %ebp
80103880:	c3                   	ret    

80103881 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103881:	55                   	push   %ebp
80103882:	89 e5                	mov    %esp,%ebp
80103884:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103887:	c7 44 24 04 7a 96 10 	movl   $0x8010967a,0x4(%esp)
8010388e:	80 
8010388f:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80103896:	e8 97 21 00 00       	call   80105a32 <initlock>
  kmem.use_lock = 0;
8010389b:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
801038a2:	00 00 00 
  freerange(vstart, vend);
801038a5:	8b 45 0c             	mov    0xc(%ebp),%eax
801038a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801038ac:	8b 45 08             	mov    0x8(%ebp),%eax
801038af:	89 04 24             	mov    %eax,(%esp)
801038b2:	e8 26 00 00 00       	call   801038dd <freerange>
}
801038b7:	c9                   	leave  
801038b8:	c3                   	ret    

801038b9 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801038b9:	55                   	push   %ebp
801038ba:	89 e5                	mov    %esp,%ebp
801038bc:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801038bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801038c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801038c6:	8b 45 08             	mov    0x8(%ebp),%eax
801038c9:	89 04 24             	mov    %eax,(%esp)
801038cc:	e8 0c 00 00 00       	call   801038dd <freerange>
  kmem.use_lock = 1;
801038d1:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
801038d8:	00 00 00 
}
801038db:	c9                   	leave  
801038dc:	c3                   	ret    

801038dd <freerange>:

void
freerange(void *vstart, void *vend)
{
801038dd:	55                   	push   %ebp
801038de:	89 e5                	mov    %esp,%ebp
801038e0:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801038e3:	8b 45 08             	mov    0x8(%ebp),%eax
801038e6:	05 ff 0f 00 00       	add    $0xfff,%eax
801038eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801038f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801038f3:	eb 12                	jmp    80103907 <freerange+0x2a>
    kfree(p);
801038f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038f8:	89 04 24             	mov    %eax,(%esp)
801038fb:	e8 16 00 00 00       	call   80103916 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103900:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010390a:	05 00 10 00 00       	add    $0x1000,%eax
8010390f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103912:	76 e1                	jbe    801038f5 <freerange+0x18>
    kfree(p);
}
80103914:	c9                   	leave  
80103915:	c3                   	ret    

80103916 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103916:	55                   	push   %ebp
80103917:	89 e5                	mov    %esp,%ebp
80103919:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
8010391c:	8b 45 08             	mov    0x8(%ebp),%eax
8010391f:	25 ff 0f 00 00       	and    $0xfff,%eax
80103924:	85 c0                	test   %eax,%eax
80103926:	75 1b                	jne    80103943 <kfree+0x2d>
80103928:	81 7d 08 1c 37 11 80 	cmpl   $0x8011371c,0x8(%ebp)
8010392f:	72 12                	jb     80103943 <kfree+0x2d>
80103931:	8b 45 08             	mov    0x8(%ebp),%eax
80103934:	89 04 24             	mov    %eax,(%esp)
80103937:	e8 38 ff ff ff       	call   80103874 <v2p>
8010393c:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103941:	76 0c                	jbe    8010394f <kfree+0x39>
    panic("kfree");
80103943:	c7 04 24 7f 96 10 80 	movl   $0x8010967f,(%esp)
8010394a:	e8 ee cb ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
8010394f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103956:	00 
80103957:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010395e:	00 
8010395f:	8b 45 08             	mov    0x8(%ebp),%eax
80103962:	89 04 24             	mov    %eax,(%esp)
80103965:	e8 38 23 00 00       	call   80105ca2 <memset>

  if(kmem.use_lock)
8010396a:	a1 94 08 11 80       	mov    0x80110894,%eax
8010396f:	85 c0                	test   %eax,%eax
80103971:	74 0c                	je     8010397f <kfree+0x69>
    acquire(&kmem.lock);
80103973:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
8010397a:	e8 d4 20 00 00       	call   80105a53 <acquire>
  r = (struct run*)v;
8010397f:	8b 45 08             	mov    0x8(%ebp),%eax
80103982:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103985:	8b 15 98 08 11 80    	mov    0x80110898,%edx
8010398b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010398e:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103993:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80103998:	a1 94 08 11 80       	mov    0x80110894,%eax
8010399d:	85 c0                	test   %eax,%eax
8010399f:	74 0c                	je     801039ad <kfree+0x97>
    release(&kmem.lock);
801039a1:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039a8:	e8 08 21 00 00       	call   80105ab5 <release>
}
801039ad:	c9                   	leave  
801039ae:	c3                   	ret    

801039af <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801039af:	55                   	push   %ebp
801039b0:	89 e5                	mov    %esp,%ebp
801039b2:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
801039b5:	a1 94 08 11 80       	mov    0x80110894,%eax
801039ba:	85 c0                	test   %eax,%eax
801039bc:	74 0c                	je     801039ca <kalloc+0x1b>
    acquire(&kmem.lock);
801039be:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039c5:	e8 89 20 00 00       	call   80105a53 <acquire>
  r = kmem.freelist;
801039ca:	a1 98 08 11 80       	mov    0x80110898,%eax
801039cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801039d2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801039d6:	74 0a                	je     801039e2 <kalloc+0x33>
    kmem.freelist = r->next;
801039d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039db:	8b 00                	mov    (%eax),%eax
801039dd:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
801039e2:	a1 94 08 11 80       	mov    0x80110894,%eax
801039e7:	85 c0                	test   %eax,%eax
801039e9:	74 0c                	je     801039f7 <kalloc+0x48>
    release(&kmem.lock);
801039eb:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039f2:	e8 be 20 00 00       	call   80105ab5 <release>
  return (char*)r;
801039f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801039fa:	c9                   	leave  
801039fb:	c3                   	ret    

801039fc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801039fc:	55                   	push   %ebp
801039fd:	89 e5                	mov    %esp,%ebp
801039ff:	53                   	push   %ebx
80103a00:	83 ec 14             	sub    $0x14,%esp
80103a03:	8b 45 08             	mov    0x8(%ebp),%eax
80103a06:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a0a:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103a0e:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103a12:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103a16:	ec                   	in     (%dx),%al
80103a17:	89 c3                	mov    %eax,%ebx
80103a19:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103a1c:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103a20:	83 c4 14             	add    $0x14,%esp
80103a23:	5b                   	pop    %ebx
80103a24:	5d                   	pop    %ebp
80103a25:	c3                   	ret    

80103a26 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103a26:	55                   	push   %ebp
80103a27:	89 e5                	mov    %esp,%ebp
80103a29:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103a2c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103a33:	e8 c4 ff ff ff       	call   801039fc <inb>
80103a38:	0f b6 c0             	movzbl %al,%eax
80103a3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a41:	83 e0 01             	and    $0x1,%eax
80103a44:	85 c0                	test   %eax,%eax
80103a46:	75 0a                	jne    80103a52 <kbdgetc+0x2c>
    return -1;
80103a48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a4d:	e9 23 01 00 00       	jmp    80103b75 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103a52:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103a59:	e8 9e ff ff ff       	call   801039fc <inb>
80103a5e:	0f b6 c0             	movzbl %al,%eax
80103a61:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103a64:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103a6b:	75 17                	jne    80103a84 <kbdgetc+0x5e>
    shift |= E0ESC;
80103a6d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103a72:	83 c8 40             	or     $0x40,%eax
80103a75:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103a7a:	b8 00 00 00 00       	mov    $0x0,%eax
80103a7f:	e9 f1 00 00 00       	jmp    80103b75 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103a84:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a87:	25 80 00 00 00       	and    $0x80,%eax
80103a8c:	85 c0                	test   %eax,%eax
80103a8e:	74 45                	je     80103ad5 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103a90:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103a95:	83 e0 40             	and    $0x40,%eax
80103a98:	85 c0                	test   %eax,%eax
80103a9a:	75 08                	jne    80103aa4 <kbdgetc+0x7e>
80103a9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a9f:	83 e0 7f             	and    $0x7f,%eax
80103aa2:	eb 03                	jmp    80103aa7 <kbdgetc+0x81>
80103aa4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103aa7:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103aaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103aad:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103ab2:	0f b6 00             	movzbl (%eax),%eax
80103ab5:	83 c8 40             	or     $0x40,%eax
80103ab8:	0f b6 c0             	movzbl %al,%eax
80103abb:	f7 d0                	not    %eax
80103abd:	89 c2                	mov    %eax,%edx
80103abf:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ac4:	21 d0                	and    %edx,%eax
80103ac6:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103acb:	b8 00 00 00 00       	mov    $0x0,%eax
80103ad0:	e9 a0 00 00 00       	jmp    80103b75 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103ad5:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ada:	83 e0 40             	and    $0x40,%eax
80103add:	85 c0                	test   %eax,%eax
80103adf:	74 14                	je     80103af5 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103ae1:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103ae8:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103aed:	83 e0 bf             	and    $0xffffffbf,%eax
80103af0:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103af5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103af8:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103afd:	0f b6 00             	movzbl (%eax),%eax
80103b00:	0f b6 d0             	movzbl %al,%edx
80103b03:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b08:	09 d0                	or     %edx,%eax
80103b0a:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103b0f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103b12:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103b17:	0f b6 00             	movzbl (%eax),%eax
80103b1a:	0f b6 d0             	movzbl %al,%edx
80103b1d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b22:	31 d0                	xor    %edx,%eax
80103b24:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103b29:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b2e:	83 e0 03             	and    $0x3,%eax
80103b31:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103b38:	03 45 fc             	add    -0x4(%ebp),%eax
80103b3b:	0f b6 00             	movzbl (%eax),%eax
80103b3e:	0f b6 c0             	movzbl %al,%eax
80103b41:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103b44:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b49:	83 e0 08             	and    $0x8,%eax
80103b4c:	85 c0                	test   %eax,%eax
80103b4e:	74 22                	je     80103b72 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103b50:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103b54:	76 0c                	jbe    80103b62 <kbdgetc+0x13c>
80103b56:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103b5a:	77 06                	ja     80103b62 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103b5c:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103b60:	eb 10                	jmp    80103b72 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103b62:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103b66:	76 0a                	jbe    80103b72 <kbdgetc+0x14c>
80103b68:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103b6c:	77 04                	ja     80103b72 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103b6e:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103b72:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103b75:	c9                   	leave  
80103b76:	c3                   	ret    

80103b77 <kbdintr>:

void
kbdintr(void)
{
80103b77:	55                   	push   %ebp
80103b78:	89 e5                	mov    %esp,%ebp
80103b7a:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103b7d:	c7 04 24 26 3a 10 80 	movl   $0x80103a26,(%esp)
80103b84:	e8 24 cc ff ff       	call   801007ad <consoleintr>
}
80103b89:	c9                   	leave  
80103b8a:	c3                   	ret    
	...

80103b8c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b8c:	55                   	push   %ebp
80103b8d:	89 e5                	mov    %esp,%ebp
80103b8f:	83 ec 08             	sub    $0x8,%esp
80103b92:	8b 55 08             	mov    0x8(%ebp),%edx
80103b95:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b98:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b9c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b9f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103ba3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103ba7:	ee                   	out    %al,(%dx)
}
80103ba8:	c9                   	leave  
80103ba9:	c3                   	ret    

80103baa <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103baa:	55                   	push   %ebp
80103bab:	89 e5                	mov    %esp,%ebp
80103bad:	53                   	push   %ebx
80103bae:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103bb1:	9c                   	pushf  
80103bb2:	5b                   	pop    %ebx
80103bb3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103bb6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103bb9:	83 c4 10             	add    $0x10,%esp
80103bbc:	5b                   	pop    %ebx
80103bbd:	5d                   	pop    %ebp
80103bbe:	c3                   	ret    

80103bbf <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103bbf:	55                   	push   %ebp
80103bc0:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103bc2:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103bc7:	8b 55 08             	mov    0x8(%ebp),%edx
80103bca:	c1 e2 02             	shl    $0x2,%edx
80103bcd:	01 c2                	add    %eax,%edx
80103bcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bd2:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103bd4:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103bd9:	83 c0 20             	add    $0x20,%eax
80103bdc:	8b 00                	mov    (%eax),%eax
}
80103bde:	5d                   	pop    %ebp
80103bdf:	c3                   	ret    

80103be0 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103be0:	55                   	push   %ebp
80103be1:	89 e5                	mov    %esp,%ebp
80103be3:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103be6:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103beb:	85 c0                	test   %eax,%eax
80103bed:	0f 84 47 01 00 00    	je     80103d3a <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103bf3:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103bfa:	00 
80103bfb:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103c02:	e8 b8 ff ff ff       	call   80103bbf <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103c07:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103c0e:	00 
80103c0f:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103c16:	e8 a4 ff ff ff       	call   80103bbf <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103c1b:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103c22:	00 
80103c23:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103c2a:	e8 90 ff ff ff       	call   80103bbf <lapicw>
  lapicw(TICR, 10000000); 
80103c2f:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103c36:	00 
80103c37:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103c3e:	e8 7c ff ff ff       	call   80103bbf <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103c43:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c4a:	00 
80103c4b:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103c52:	e8 68 ff ff ff       	call   80103bbf <lapicw>
  lapicw(LINT1, MASKED);
80103c57:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c5e:	00 
80103c5f:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103c66:	e8 54 ff ff ff       	call   80103bbf <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103c6b:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103c70:	83 c0 30             	add    $0x30,%eax
80103c73:	8b 00                	mov    (%eax),%eax
80103c75:	c1 e8 10             	shr    $0x10,%eax
80103c78:	25 ff 00 00 00       	and    $0xff,%eax
80103c7d:	83 f8 03             	cmp    $0x3,%eax
80103c80:	76 14                	jbe    80103c96 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103c82:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c89:	00 
80103c8a:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103c91:	e8 29 ff ff ff       	call   80103bbf <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103c96:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103c9d:	00 
80103c9e:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103ca5:	e8 15 ff ff ff       	call   80103bbf <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103caa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103cb1:	00 
80103cb2:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cb9:	e8 01 ff ff ff       	call   80103bbf <lapicw>
  lapicw(ESR, 0);
80103cbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103cc5:	00 
80103cc6:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ccd:	e8 ed fe ff ff       	call   80103bbf <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103cd2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103cd9:	00 
80103cda:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103ce1:	e8 d9 fe ff ff       	call   80103bbf <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103ce6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103ced:	00 
80103cee:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103cf5:	e8 c5 fe ff ff       	call   80103bbf <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103cfa:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103d01:	00 
80103d02:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103d09:	e8 b1 fe ff ff       	call   80103bbf <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103d0e:	90                   	nop
80103d0f:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d14:	05 00 03 00 00       	add    $0x300,%eax
80103d19:	8b 00                	mov    (%eax),%eax
80103d1b:	25 00 10 00 00       	and    $0x1000,%eax
80103d20:	85 c0                	test   %eax,%eax
80103d22:	75 eb                	jne    80103d0f <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103d24:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103d2b:	00 
80103d2c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d33:	e8 87 fe ff ff       	call   80103bbf <lapicw>
80103d38:	eb 01                	jmp    80103d3b <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103d3a:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103d3b:	c9                   	leave  
80103d3c:	c3                   	ret    

80103d3d <cpunum>:

int
cpunum(void)
{
80103d3d:	55                   	push   %ebp
80103d3e:	89 e5                	mov    %esp,%ebp
80103d40:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103d43:	e8 62 fe ff ff       	call   80103baa <readeflags>
80103d48:	25 00 02 00 00       	and    $0x200,%eax
80103d4d:	85 c0                	test   %eax,%eax
80103d4f:	74 29                	je     80103d7a <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103d51:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103d56:	85 c0                	test   %eax,%eax
80103d58:	0f 94 c2             	sete   %dl
80103d5b:	83 c0 01             	add    $0x1,%eax
80103d5e:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80103d63:	84 d2                	test   %dl,%dl
80103d65:	74 13                	je     80103d7a <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103d67:	8b 45 04             	mov    0x4(%ebp),%eax
80103d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d6e:	c7 04 24 88 96 10 80 	movl   $0x80109688,(%esp)
80103d75:	e8 27 c6 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103d7a:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d7f:	85 c0                	test   %eax,%eax
80103d81:	74 0f                	je     80103d92 <cpunum+0x55>
    return lapic[ID]>>24;
80103d83:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d88:	83 c0 20             	add    $0x20,%eax
80103d8b:	8b 00                	mov    (%eax),%eax
80103d8d:	c1 e8 18             	shr    $0x18,%eax
80103d90:	eb 05                	jmp    80103d97 <cpunum+0x5a>
  return 0;
80103d92:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103d97:	c9                   	leave  
80103d98:	c3                   	ret    

80103d99 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103d99:	55                   	push   %ebp
80103d9a:	89 e5                	mov    %esp,%ebp
80103d9c:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103d9f:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103da4:	85 c0                	test   %eax,%eax
80103da6:	74 14                	je     80103dbc <lapiceoi+0x23>
    lapicw(EOI, 0);
80103da8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103daf:	00 
80103db0:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103db7:	e8 03 fe ff ff       	call   80103bbf <lapicw>
}
80103dbc:	c9                   	leave  
80103dbd:	c3                   	ret    

80103dbe <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103dbe:	55                   	push   %ebp
80103dbf:	89 e5                	mov    %esp,%ebp
}
80103dc1:	5d                   	pop    %ebp
80103dc2:	c3                   	ret    

80103dc3 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103dc3:	55                   	push   %ebp
80103dc4:	89 e5                	mov    %esp,%ebp
80103dc6:	83 ec 1c             	sub    $0x1c,%esp
80103dc9:	8b 45 08             	mov    0x8(%ebp),%eax
80103dcc:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103dcf:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103dd6:	00 
80103dd7:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103dde:	e8 a9 fd ff ff       	call   80103b8c <outb>
  outb(IO_RTC+1, 0x0A);
80103de3:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103dea:	00 
80103deb:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103df2:	e8 95 fd ff ff       	call   80103b8c <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103df7:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103dfe:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103e01:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103e06:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103e09:	8d 50 02             	lea    0x2(%eax),%edx
80103e0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e0f:	c1 e8 04             	shr    $0x4,%eax
80103e12:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103e15:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103e19:	c1 e0 18             	shl    $0x18,%eax
80103e1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e20:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103e27:	e8 93 fd ff ff       	call   80103bbf <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103e2c:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103e33:	00 
80103e34:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103e3b:	e8 7f fd ff ff       	call   80103bbf <lapicw>
  microdelay(200);
80103e40:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103e47:	e8 72 ff ff ff       	call   80103dbe <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103e4c:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103e53:	00 
80103e54:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103e5b:	e8 5f fd ff ff       	call   80103bbf <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103e60:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103e67:	e8 52 ff ff ff       	call   80103dbe <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103e6c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103e73:	eb 40                	jmp    80103eb5 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103e75:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103e79:	c1 e0 18             	shl    $0x18,%eax
80103e7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e80:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103e87:	e8 33 fd ff ff       	call   80103bbf <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e8f:	c1 e8 0c             	shr    $0xc,%eax
80103e92:	80 cc 06             	or     $0x6,%ah
80103e95:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e99:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103ea0:	e8 1a fd ff ff       	call   80103bbf <lapicw>
    microdelay(200);
80103ea5:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103eac:	e8 0d ff ff ff       	call   80103dbe <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103eb1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103eb5:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103eb9:	7e ba                	jle    80103e75 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103ebb:	c9                   	leave  
80103ebc:	c3                   	ret    
80103ebd:	00 00                	add    %al,(%eax)
	...

80103ec0 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103ec0:	55                   	push   %ebp
80103ec1:	89 e5                	mov    %esp,%ebp
80103ec3:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103ec6:	c7 44 24 04 b4 96 10 	movl   $0x801096b4,0x4(%esp)
80103ecd:	80 
80103ece:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103ed5:	e8 58 1b 00 00       	call   80105a32 <initlock>
  readsb(ROOTDEV, &sb);
80103eda:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103edd:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ee1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103ee8:	e8 73 df ff ff       	call   80101e60 <readsb>
  log.start = sb.size - sb.nlog;
80103eed:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103ef0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef3:	89 d1                	mov    %edx,%ecx
80103ef5:	29 c1                	sub    %eax,%ecx
80103ef7:	89 c8                	mov    %ecx,%eax
80103ef9:	a3 d4 08 11 80       	mov    %eax,0x801108d4
  log.size = sb.nlog;
80103efe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f01:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  log.dev = ROOTDEV;
80103f06:	c7 05 e0 08 11 80 01 	movl   $0x1,0x801108e0
80103f0d:	00 00 00 
  recover_from_log();
80103f10:	e8 97 01 00 00       	call   801040ac <recover_from_log>
}
80103f15:	c9                   	leave  
80103f16:	c3                   	ret    

80103f17 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103f17:	55                   	push   %ebp
80103f18:	89 e5                	mov    %esp,%ebp
80103f1a:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103f1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f24:	e9 89 00 00 00       	jmp    80103fb2 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103f29:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103f2e:	03 45 f4             	add    -0xc(%ebp),%eax
80103f31:	83 c0 01             	add    $0x1,%eax
80103f34:	89 c2                	mov    %eax,%edx
80103f36:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103f3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f3f:	89 04 24             	mov    %eax,(%esp)
80103f42:	e8 5f c2 ff ff       	call   801001a6 <bread>
80103f47:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103f4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f4d:	83 c0 10             	add    $0x10,%eax
80103f50:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103f57:	89 c2                	mov    %eax,%edx
80103f59:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103f5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f62:	89 04 24             	mov    %eax,(%esp)
80103f65:	e8 3c c2 ff ff       	call   801001a6 <bread>
80103f6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103f6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f70:	8d 50 18             	lea    0x18(%eax),%edx
80103f73:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f76:	83 c0 18             	add    $0x18,%eax
80103f79:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103f80:	00 
80103f81:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f85:	89 04 24             	mov    %eax,(%esp)
80103f88:	e8 e8 1d 00 00       	call   80105d75 <memmove>
    bwrite(dbuf);  // write dst to disk
80103f8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f90:	89 04 24             	mov    %eax,(%esp)
80103f93:	e8 45 c2 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f9b:	89 04 24             	mov    %eax,(%esp)
80103f9e:	e8 74 c2 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103fa3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fa6:	89 04 24             	mov    %eax,(%esp)
80103fa9:	e8 69 c2 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103fae:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103fb2:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103fb7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103fba:	0f 8f 69 ff ff ff    	jg     80103f29 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103fc0:	c9                   	leave  
80103fc1:	c3                   	ret    

80103fc2 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103fc2:	55                   	push   %ebp
80103fc3:	89 e5                	mov    %esp,%ebp
80103fc5:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103fc8:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103fcd:	89 c2                	mov    %eax,%edx
80103fcf:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103fd4:	89 54 24 04          	mov    %edx,0x4(%esp)
80103fd8:	89 04 24             	mov    %eax,(%esp)
80103fdb:	e8 c6 c1 ff ff       	call   801001a6 <bread>
80103fe0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103fe3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fe6:	83 c0 18             	add    $0x18,%eax
80103fe9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103fec:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fef:	8b 00                	mov    (%eax),%eax
80103ff1:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  for (i = 0; i < log.lh.n; i++) {
80103ff6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ffd:	eb 1b                	jmp    8010401a <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103fff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104002:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104005:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80104009:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010400c:	83 c2 10             	add    $0x10,%edx
8010400f:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80104016:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010401a:	a1 e4 08 11 80       	mov    0x801108e4,%eax
8010401f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104022:	7f db                	jg     80103fff <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80104024:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104027:	89 04 24             	mov    %eax,(%esp)
8010402a:	e8 e8 c1 ff ff       	call   80100217 <brelse>
}
8010402f:	c9                   	leave  
80104030:	c3                   	ret    

80104031 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80104031:	55                   	push   %ebp
80104032:	89 e5                	mov    %esp,%ebp
80104034:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80104037:	a1 d4 08 11 80       	mov    0x801108d4,%eax
8010403c:	89 c2                	mov    %eax,%edx
8010403e:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80104043:	89 54 24 04          	mov    %edx,0x4(%esp)
80104047:	89 04 24             	mov    %eax,(%esp)
8010404a:	e8 57 c1 ff ff       	call   801001a6 <bread>
8010404f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80104052:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104055:	83 c0 18             	add    $0x18,%eax
80104058:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
8010405b:	8b 15 e4 08 11 80    	mov    0x801108e4,%edx
80104061:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104064:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80104066:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010406d:	eb 1b                	jmp    8010408a <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
8010406f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104072:	83 c0 10             	add    $0x10,%eax
80104075:	8b 0c 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%ecx
8010407c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010407f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104082:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80104086:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010408a:	a1 e4 08 11 80       	mov    0x801108e4,%eax
8010408f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104092:	7f db                	jg     8010406f <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80104094:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104097:	89 04 24             	mov    %eax,(%esp)
8010409a:	e8 3e c1 ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010409f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801040a2:	89 04 24             	mov    %eax,(%esp)
801040a5:	e8 6d c1 ff ff       	call   80100217 <brelse>
}
801040aa:	c9                   	leave  
801040ab:	c3                   	ret    

801040ac <recover_from_log>:

static void
recover_from_log(void)
{
801040ac:	55                   	push   %ebp
801040ad:	89 e5                	mov    %esp,%ebp
801040af:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801040b2:	e8 0b ff ff ff       	call   80103fc2 <read_head>
  install_trans(); // if committed, copy from log to disk
801040b7:	e8 5b fe ff ff       	call   80103f17 <install_trans>
  log.lh.n = 0;
801040bc:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
801040c3:	00 00 00 
  write_head(); // clear the log
801040c6:	e8 66 ff ff ff       	call   80104031 <write_head>
}
801040cb:	c9                   	leave  
801040cc:	c3                   	ret    

801040cd <begin_trans>:

void
begin_trans(void)
{
801040cd:	55                   	push   %ebp
801040ce:	89 e5                	mov    %esp,%ebp
801040d0:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801040d3:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
801040da:	e8 74 19 00 00       	call   80105a53 <acquire>
  while (log.busy) {
801040df:	eb 14                	jmp    801040f5 <begin_trans+0x28>
    sleep(&log, &log.lock);
801040e1:	c7 44 24 04 a0 08 11 	movl   $0x801108a0,0x4(%esp)
801040e8:	80 
801040e9:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
801040f0:	e8 80 16 00 00       	call   80105775 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801040f5:	a1 dc 08 11 80       	mov    0x801108dc,%eax
801040fa:	85 c0                	test   %eax,%eax
801040fc:	75 e3                	jne    801040e1 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801040fe:	c7 05 dc 08 11 80 01 	movl   $0x1,0x801108dc
80104105:	00 00 00 
  release(&log.lock);
80104108:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
8010410f:	e8 a1 19 00 00       	call   80105ab5 <release>
}
80104114:	c9                   	leave  
80104115:	c3                   	ret    

80104116 <commit_trans>:

void
commit_trans(void)
{
80104116:	55                   	push   %ebp
80104117:	89 e5                	mov    %esp,%ebp
80104119:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
8010411c:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104121:	85 c0                	test   %eax,%eax
80104123:	7e 19                	jle    8010413e <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80104125:	e8 07 ff ff ff       	call   80104031 <write_head>
    install_trans(); // Now install writes to home locations
8010412a:	e8 e8 fd ff ff       	call   80103f17 <install_trans>
    log.lh.n = 0; 
8010412f:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
80104136:	00 00 00 
    write_head();    // Erase the transaction from the log
80104139:	e8 f3 fe ff ff       	call   80104031 <write_head>
  }
  
  acquire(&log.lock);
8010413e:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80104145:	e8 09 19 00 00       	call   80105a53 <acquire>
  log.busy = 0;
8010414a:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80104151:	00 00 00 
  wakeup(&log);
80104154:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
8010415b:	e8 ee 16 00 00       	call   8010584e <wakeup>
  release(&log.lock);
80104160:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80104167:	e8 49 19 00 00       	call   80105ab5 <release>
}
8010416c:	c9                   	leave  
8010416d:	c3                   	ret    

8010416e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010416e:	55                   	push   %ebp
8010416f:	89 e5                	mov    %esp,%ebp
80104171:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80104174:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104179:	83 f8 09             	cmp    $0x9,%eax
8010417c:	7f 12                	jg     80104190 <log_write+0x22>
8010417e:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104183:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80104189:	83 ea 01             	sub    $0x1,%edx
8010418c:	39 d0                	cmp    %edx,%eax
8010418e:	7c 0c                	jl     8010419c <log_write+0x2e>
    panic("too big a transaction");
80104190:	c7 04 24 b8 96 10 80 	movl   $0x801096b8,(%esp)
80104197:	e8 a1 c3 ff ff       	call   8010053d <panic>
  if (!log.busy)
8010419c:	a1 dc 08 11 80       	mov    0x801108dc,%eax
801041a1:	85 c0                	test   %eax,%eax
801041a3:	75 0c                	jne    801041b1 <log_write+0x43>
    panic("write outside of trans");
801041a5:	c7 04 24 ce 96 10 80 	movl   $0x801096ce,(%esp)
801041ac:	e8 8c c3 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801041b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041b8:	eb 1d                	jmp    801041d7 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
801041ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041bd:	83 c0 10             	add    $0x10,%eax
801041c0:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
801041c7:	89 c2                	mov    %eax,%edx
801041c9:	8b 45 08             	mov    0x8(%ebp),%eax
801041cc:	8b 40 08             	mov    0x8(%eax),%eax
801041cf:	39 c2                	cmp    %eax,%edx
801041d1:	74 10                	je     801041e3 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801041d3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801041d7:	a1 e4 08 11 80       	mov    0x801108e4,%eax
801041dc:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801041df:	7f d9                	jg     801041ba <log_write+0x4c>
801041e1:	eb 01                	jmp    801041e4 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801041e3:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801041e4:	8b 45 08             	mov    0x8(%ebp),%eax
801041e7:	8b 40 08             	mov    0x8(%eax),%eax
801041ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041ed:	83 c2 10             	add    $0x10,%edx
801041f0:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801041f7:	a1 d4 08 11 80       	mov    0x801108d4,%eax
801041fc:	03 45 f4             	add    -0xc(%ebp),%eax
801041ff:	83 c0 01             	add    $0x1,%eax
80104202:	89 c2                	mov    %eax,%edx
80104204:	8b 45 08             	mov    0x8(%ebp),%eax
80104207:	8b 40 04             	mov    0x4(%eax),%eax
8010420a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010420e:	89 04 24             	mov    %eax,(%esp)
80104211:	e8 90 bf ff ff       	call   801001a6 <bread>
80104216:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80104219:	8b 45 08             	mov    0x8(%ebp),%eax
8010421c:	8d 50 18             	lea    0x18(%eax),%edx
8010421f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104222:	83 c0 18             	add    $0x18,%eax
80104225:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010422c:	00 
8010422d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104231:	89 04 24             	mov    %eax,(%esp)
80104234:	e8 3c 1b 00 00       	call   80105d75 <memmove>
  bwrite(lbuf);
80104239:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010423c:	89 04 24             	mov    %eax,(%esp)
8010423f:	e8 99 bf ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80104244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104247:	89 04 24             	mov    %eax,(%esp)
8010424a:	e8 c8 bf ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
8010424f:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104254:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104257:	75 0d                	jne    80104266 <log_write+0xf8>
    log.lh.n++;
80104259:	a1 e4 08 11 80       	mov    0x801108e4,%eax
8010425e:	83 c0 01             	add    $0x1,%eax
80104261:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80104266:	8b 45 08             	mov    0x8(%ebp),%eax
80104269:	8b 00                	mov    (%eax),%eax
8010426b:	89 c2                	mov    %eax,%edx
8010426d:	83 ca 04             	or     $0x4,%edx
80104270:	8b 45 08             	mov    0x8(%ebp),%eax
80104273:	89 10                	mov    %edx,(%eax)
}
80104275:	c9                   	leave  
80104276:	c3                   	ret    
	...

80104278 <v2p>:
80104278:	55                   	push   %ebp
80104279:	89 e5                	mov    %esp,%ebp
8010427b:	8b 45 08             	mov    0x8(%ebp),%eax
8010427e:	05 00 00 00 80       	add    $0x80000000,%eax
80104283:	5d                   	pop    %ebp
80104284:	c3                   	ret    

80104285 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80104285:	55                   	push   %ebp
80104286:	89 e5                	mov    %esp,%ebp
80104288:	8b 45 08             	mov    0x8(%ebp),%eax
8010428b:	05 00 00 00 80       	add    $0x80000000,%eax
80104290:	5d                   	pop    %ebp
80104291:	c3                   	ret    

80104292 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104292:	55                   	push   %ebp
80104293:	89 e5                	mov    %esp,%ebp
80104295:	53                   	push   %ebx
80104296:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104299:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010429c:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010429f:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801042a2:	89 c3                	mov    %eax,%ebx
801042a4:	89 d8                	mov    %ebx,%eax
801042a6:	f0 87 02             	lock xchg %eax,(%edx)
801042a9:	89 c3                	mov    %eax,%ebx
801042ab:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801042ae:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801042b1:	83 c4 10             	add    $0x10,%esp
801042b4:	5b                   	pop    %ebx
801042b5:	5d                   	pop    %ebp
801042b6:	c3                   	ret    

801042b7 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801042b7:	55                   	push   %ebp
801042b8:	89 e5                	mov    %esp,%ebp
801042ba:	83 e4 f0             	and    $0xfffffff0,%esp
801042bd:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801042c0:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801042c7:	80 
801042c8:	c7 04 24 1c 37 11 80 	movl   $0x8011371c,(%esp)
801042cf:	e8 ad f5 ff ff       	call   80103881 <kinit1>
  kvmalloc();      // kernel page table
801042d4:	e8 69 47 00 00       	call   80108a42 <kvmalloc>
  mpinit();        // collect info about this machine
801042d9:	e8 63 04 00 00       	call   80104741 <mpinit>
  lapicinit(mpbcpu());
801042de:	e8 2e 02 00 00       	call   80104511 <mpbcpu>
801042e3:	89 04 24             	mov    %eax,(%esp)
801042e6:	e8 f5 f8 ff ff       	call   80103be0 <lapicinit>
  seginit();       // set up segments
801042eb:	e8 f5 40 00 00       	call   801083e5 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801042f0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801042f6:	0f b6 00             	movzbl (%eax),%eax
801042f9:	0f b6 c0             	movzbl %al,%eax
801042fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80104300:	c7 04 24 e5 96 10 80 	movl   $0x801096e5,(%esp)
80104307:	e8 95 c0 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
8010430c:	e8 95 06 00 00       	call   801049a6 <picinit>
  ioapicinit();    // another interrupt controller
80104311:	e8 5b f4 ff ff       	call   80103771 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80104316:	e8 72 c7 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
8010431b:	e8 10 34 00 00       	call   80107730 <uartinit>
  pinit();         // process table
80104320:	e8 96 0b 00 00       	call   80104ebb <pinit>
  tvinit();        // trap vectors
80104325:	e8 a9 2f 00 00       	call   801072d3 <tvinit>
  binit();         // buffer cache
8010432a:	e8 05 bd ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010432f:	e8 cc cb ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80104334:	e8 06 de ff ff       	call   8010213f <iinit>
  ideinit();       // disk
80104339:	e8 98 f0 ff ff       	call   801033d6 <ideinit>
  if(!ismp)
8010433e:	a1 24 09 11 80       	mov    0x80110924,%eax
80104343:	85 c0                	test   %eax,%eax
80104345:	75 05                	jne    8010434c <main+0x95>
    timerinit();   // uniprocessor timer
80104347:	e8 ca 2e 00 00       	call   80107216 <timerinit>
  startothers();   // start other processors
8010434c:	e8 87 00 00 00       	call   801043d8 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104351:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80104358:	8e 
80104359:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104360:	e8 54 f5 ff ff       	call   801038b9 <kinit2>
  userinit();      // first user process
80104365:	e8 6c 0c 00 00       	call   80104fd6 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010436a:	e8 22 00 00 00       	call   80104391 <mpmain>

8010436f <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010436f:	55                   	push   %ebp
80104370:	89 e5                	mov    %esp,%ebp
80104372:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80104375:	e8 df 46 00 00       	call   80108a59 <switchkvm>
  seginit();
8010437a:	e8 66 40 00 00       	call   801083e5 <seginit>
  lapicinit(cpunum());
8010437f:	e8 b9 f9 ff ff       	call   80103d3d <cpunum>
80104384:	89 04 24             	mov    %eax,(%esp)
80104387:	e8 54 f8 ff ff       	call   80103be0 <lapicinit>
  mpmain();
8010438c:	e8 00 00 00 00       	call   80104391 <mpmain>

80104391 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104391:	55                   	push   %ebp
80104392:	89 e5                	mov    %esp,%ebp
80104394:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80104397:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010439d:	0f b6 00             	movzbl (%eax),%eax
801043a0:	0f b6 c0             	movzbl %al,%eax
801043a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801043a7:	c7 04 24 fc 96 10 80 	movl   $0x801096fc,(%esp)
801043ae:	e8 ee bf ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801043b3:	e8 8f 30 00 00       	call   80107447 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801043b8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801043be:	05 a8 00 00 00       	add    $0xa8,%eax
801043c3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801043ca:	00 
801043cb:	89 04 24             	mov    %eax,(%esp)
801043ce:	e8 bf fe ff ff       	call   80104292 <xchg>
  scheduler();     // start running processes
801043d3:	e8 f4 11 00 00       	call   801055cc <scheduler>

801043d8 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801043d8:	55                   	push   %ebp
801043d9:	89 e5                	mov    %esp,%ebp
801043db:	53                   	push   %ebx
801043dc:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801043df:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801043e6:	e8 9a fe ff ff       	call   80104285 <p2v>
801043eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801043ee:	b8 8a 00 00 00       	mov    $0x8a,%eax
801043f3:	89 44 24 08          	mov    %eax,0x8(%esp)
801043f7:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
801043fe:	80 
801043ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104402:	89 04 24             	mov    %eax,(%esp)
80104405:	e8 6b 19 00 00       	call   80105d75 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010440a:	c7 45 f4 40 09 11 80 	movl   $0x80110940,-0xc(%ebp)
80104411:	e9 86 00 00 00       	jmp    8010449c <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80104416:	e8 22 f9 ff ff       	call   80103d3d <cpunum>
8010441b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104421:	05 40 09 11 80       	add    $0x80110940,%eax
80104426:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104429:	74 69                	je     80104494 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010442b:	e8 7f f5 ff ff       	call   801039af <kalloc>
80104430:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104433:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104436:	83 e8 04             	sub    $0x4,%eax
80104439:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010443c:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104442:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104444:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104447:	83 e8 08             	sub    $0x8,%eax
8010444a:	c7 00 6f 43 10 80    	movl   $0x8010436f,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104450:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104453:	8d 58 f4             	lea    -0xc(%eax),%ebx
80104456:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
8010445d:	e8 16 fe ff ff       	call   80104278 <v2p>
80104462:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80104464:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104467:	89 04 24             	mov    %eax,(%esp)
8010446a:	e8 09 fe ff ff       	call   80104278 <v2p>
8010446f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104472:	0f b6 12             	movzbl (%edx),%edx
80104475:	0f b6 d2             	movzbl %dl,%edx
80104478:	89 44 24 04          	mov    %eax,0x4(%esp)
8010447c:	89 14 24             	mov    %edx,(%esp)
8010447f:	e8 3f f9 ff ff       	call   80103dc3 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80104484:	90                   	nop
80104485:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104488:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010448e:	85 c0                	test   %eax,%eax
80104490:	74 f3                	je     80104485 <startothers+0xad>
80104492:	eb 01                	jmp    80104495 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80104494:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80104495:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
8010449c:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801044a1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801044a7:	05 40 09 11 80       	add    $0x80110940,%eax
801044ac:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801044af:	0f 87 61 ff ff ff    	ja     80104416 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801044b5:	83 c4 24             	add    $0x24,%esp
801044b8:	5b                   	pop    %ebx
801044b9:	5d                   	pop    %ebp
801044ba:	c3                   	ret    
	...

801044bc <p2v>:
801044bc:	55                   	push   %ebp
801044bd:	89 e5                	mov    %esp,%ebp
801044bf:	8b 45 08             	mov    0x8(%ebp),%eax
801044c2:	05 00 00 00 80       	add    $0x80000000,%eax
801044c7:	5d                   	pop    %ebp
801044c8:	c3                   	ret    

801044c9 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801044c9:	55                   	push   %ebp
801044ca:	89 e5                	mov    %esp,%ebp
801044cc:	53                   	push   %ebx
801044cd:	83 ec 14             	sub    $0x14,%esp
801044d0:	8b 45 08             	mov    0x8(%ebp),%eax
801044d3:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801044d7:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801044db:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801044df:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801044e3:	ec                   	in     (%dx),%al
801044e4:	89 c3                	mov    %eax,%ebx
801044e6:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801044e9:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801044ed:	83 c4 14             	add    $0x14,%esp
801044f0:	5b                   	pop    %ebx
801044f1:	5d                   	pop    %ebp
801044f2:	c3                   	ret    

801044f3 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044f3:	55                   	push   %ebp
801044f4:	89 e5                	mov    %esp,%ebp
801044f6:	83 ec 08             	sub    $0x8,%esp
801044f9:	8b 55 08             	mov    0x8(%ebp),%edx
801044fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801044ff:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104503:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104506:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010450a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010450e:	ee                   	out    %al,(%dx)
}
8010450f:	c9                   	leave  
80104510:	c3                   	ret    

80104511 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104511:	55                   	push   %ebp
80104512:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104514:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80104519:	89 c2                	mov    %eax,%edx
8010451b:	b8 40 09 11 80       	mov    $0x80110940,%eax
80104520:	89 d1                	mov    %edx,%ecx
80104522:	29 c1                	sub    %eax,%ecx
80104524:	89 c8                	mov    %ecx,%eax
80104526:	c1 f8 02             	sar    $0x2,%eax
80104529:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
8010452f:	5d                   	pop    %ebp
80104530:	c3                   	ret    

80104531 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104531:	55                   	push   %ebp
80104532:	89 e5                	mov    %esp,%ebp
80104534:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80104537:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
8010453e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104545:	eb 13                	jmp    8010455a <sum+0x29>
    sum += addr[i];
80104547:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010454a:	03 45 08             	add    0x8(%ebp),%eax
8010454d:	0f b6 00             	movzbl (%eax),%eax
80104550:	0f b6 c0             	movzbl %al,%eax
80104553:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80104556:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010455a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010455d:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104560:	7c e5                	jl     80104547 <sum+0x16>
    sum += addr[i];
  return sum;
80104562:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104565:	c9                   	leave  
80104566:	c3                   	ret    

80104567 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80104567:	55                   	push   %ebp
80104568:	89 e5                	mov    %esp,%ebp
8010456a:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
8010456d:	8b 45 08             	mov    0x8(%ebp),%eax
80104570:	89 04 24             	mov    %eax,(%esp)
80104573:	e8 44 ff ff ff       	call   801044bc <p2v>
80104578:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010457b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010457e:	03 45 f0             	add    -0x10(%ebp),%eax
80104581:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80104584:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104587:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010458a:	eb 3f                	jmp    801045cb <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
8010458c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104593:	00 
80104594:	c7 44 24 04 10 97 10 	movl   $0x80109710,0x4(%esp)
8010459b:	80 
8010459c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010459f:	89 04 24             	mov    %eax,(%esp)
801045a2:	e8 72 17 00 00       	call   80105d19 <memcmp>
801045a7:	85 c0                	test   %eax,%eax
801045a9:	75 1c                	jne    801045c7 <mpsearch1+0x60>
801045ab:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801045b2:	00 
801045b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b6:	89 04 24             	mov    %eax,(%esp)
801045b9:	e8 73 ff ff ff       	call   80104531 <sum>
801045be:	84 c0                	test   %al,%al
801045c0:	75 05                	jne    801045c7 <mpsearch1+0x60>
      return (struct mp*)p;
801045c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c5:	eb 11                	jmp    801045d8 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801045c7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801045cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ce:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801045d1:	72 b9                	jb     8010458c <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801045d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045d8:	c9                   	leave  
801045d9:	c3                   	ret    

801045da <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801045da:	55                   	push   %ebp
801045db:	89 e5                	mov    %esp,%ebp
801045dd:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801045e0:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801045e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ea:	83 c0 0f             	add    $0xf,%eax
801045ed:	0f b6 00             	movzbl (%eax),%eax
801045f0:	0f b6 c0             	movzbl %al,%eax
801045f3:	89 c2                	mov    %eax,%edx
801045f5:	c1 e2 08             	shl    $0x8,%edx
801045f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045fb:	83 c0 0e             	add    $0xe,%eax
801045fe:	0f b6 00             	movzbl (%eax),%eax
80104601:	0f b6 c0             	movzbl %al,%eax
80104604:	09 d0                	or     %edx,%eax
80104606:	c1 e0 04             	shl    $0x4,%eax
80104609:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010460c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104610:	74 21                	je     80104633 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104612:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104619:	00 
8010461a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010461d:	89 04 24             	mov    %eax,(%esp)
80104620:	e8 42 ff ff ff       	call   80104567 <mpsearch1>
80104625:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104628:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010462c:	74 50                	je     8010467e <mpsearch+0xa4>
      return mp;
8010462e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104631:	eb 5f                	jmp    80104692 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104633:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104636:	83 c0 14             	add    $0x14,%eax
80104639:	0f b6 00             	movzbl (%eax),%eax
8010463c:	0f b6 c0             	movzbl %al,%eax
8010463f:	89 c2                	mov    %eax,%edx
80104641:	c1 e2 08             	shl    $0x8,%edx
80104644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104647:	83 c0 13             	add    $0x13,%eax
8010464a:	0f b6 00             	movzbl (%eax),%eax
8010464d:	0f b6 c0             	movzbl %al,%eax
80104650:	09 d0                	or     %edx,%eax
80104652:	c1 e0 0a             	shl    $0xa,%eax
80104655:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010465b:	2d 00 04 00 00       	sub    $0x400,%eax
80104660:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104667:	00 
80104668:	89 04 24             	mov    %eax,(%esp)
8010466b:	e8 f7 fe ff ff       	call   80104567 <mpsearch1>
80104670:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104673:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104677:	74 05                	je     8010467e <mpsearch+0xa4>
      return mp;
80104679:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010467c:	eb 14                	jmp    80104692 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
8010467e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104685:	00 
80104686:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
8010468d:	e8 d5 fe ff ff       	call   80104567 <mpsearch1>
}
80104692:	c9                   	leave  
80104693:	c3                   	ret    

80104694 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104694:	55                   	push   %ebp
80104695:	89 e5                	mov    %esp,%ebp
80104697:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010469a:	e8 3b ff ff ff       	call   801045da <mpsearch>
8010469f:	89 45 f4             	mov    %eax,-0xc(%ebp)
801046a2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801046a6:	74 0a                	je     801046b2 <mpconfig+0x1e>
801046a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046ab:	8b 40 04             	mov    0x4(%eax),%eax
801046ae:	85 c0                	test   %eax,%eax
801046b0:	75 0a                	jne    801046bc <mpconfig+0x28>
    return 0;
801046b2:	b8 00 00 00 00       	mov    $0x0,%eax
801046b7:	e9 83 00 00 00       	jmp    8010473f <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801046bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046bf:	8b 40 04             	mov    0x4(%eax),%eax
801046c2:	89 04 24             	mov    %eax,(%esp)
801046c5:	e8 f2 fd ff ff       	call   801044bc <p2v>
801046ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801046cd:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801046d4:	00 
801046d5:	c7 44 24 04 15 97 10 	movl   $0x80109715,0x4(%esp)
801046dc:	80 
801046dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046e0:	89 04 24             	mov    %eax,(%esp)
801046e3:	e8 31 16 00 00       	call   80105d19 <memcmp>
801046e8:	85 c0                	test   %eax,%eax
801046ea:	74 07                	je     801046f3 <mpconfig+0x5f>
    return 0;
801046ec:	b8 00 00 00 00       	mov    $0x0,%eax
801046f1:	eb 4c                	jmp    8010473f <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801046f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046f6:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801046fa:	3c 01                	cmp    $0x1,%al
801046fc:	74 12                	je     80104710 <mpconfig+0x7c>
801046fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104701:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104705:	3c 04                	cmp    $0x4,%al
80104707:	74 07                	je     80104710 <mpconfig+0x7c>
    return 0;
80104709:	b8 00 00 00 00       	mov    $0x0,%eax
8010470e:	eb 2f                	jmp    8010473f <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104710:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104713:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104717:	0f b7 c0             	movzwl %ax,%eax
8010471a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010471e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104721:	89 04 24             	mov    %eax,(%esp)
80104724:	e8 08 fe ff ff       	call   80104531 <sum>
80104729:	84 c0                	test   %al,%al
8010472b:	74 07                	je     80104734 <mpconfig+0xa0>
    return 0;
8010472d:	b8 00 00 00 00       	mov    $0x0,%eax
80104732:	eb 0b                	jmp    8010473f <mpconfig+0xab>
  *pmp = mp;
80104734:	8b 45 08             	mov    0x8(%ebp),%eax
80104737:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010473a:	89 10                	mov    %edx,(%eax)
  return conf;
8010473c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010473f:	c9                   	leave  
80104740:	c3                   	ret    

80104741 <mpinit>:

void
mpinit(void)
{
80104741:	55                   	push   %ebp
80104742:	89 e5                	mov    %esp,%ebp
80104744:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104747:	c7 05 64 c6 10 80 40 	movl   $0x80110940,0x8010c664
8010474e:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104751:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104754:	89 04 24             	mov    %eax,(%esp)
80104757:	e8 38 ff ff ff       	call   80104694 <mpconfig>
8010475c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010475f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104763:	0f 84 9c 01 00 00    	je     80104905 <mpinit+0x1c4>
    return;
  ismp = 1;
80104769:	c7 05 24 09 11 80 01 	movl   $0x1,0x80110924
80104770:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104773:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104776:	8b 40 24             	mov    0x24(%eax),%eax
80104779:	a3 9c 08 11 80       	mov    %eax,0x8011089c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
8010477e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104781:	83 c0 2c             	add    $0x2c,%eax
80104784:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104787:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010478a:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010478e:	0f b7 c0             	movzwl %ax,%eax
80104791:	03 45 f0             	add    -0x10(%ebp),%eax
80104794:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104797:	e9 f4 00 00 00       	jmp    80104890 <mpinit+0x14f>
    switch(*p){
8010479c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010479f:	0f b6 00             	movzbl (%eax),%eax
801047a2:	0f b6 c0             	movzbl %al,%eax
801047a5:	83 f8 04             	cmp    $0x4,%eax
801047a8:	0f 87 bf 00 00 00    	ja     8010486d <mpinit+0x12c>
801047ae:	8b 04 85 58 97 10 80 	mov    -0x7fef68a8(,%eax,4),%eax
801047b5:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801047b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047ba:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801047bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047c0:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801047c4:	0f b6 d0             	movzbl %al,%edx
801047c7:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801047cc:	39 c2                	cmp    %eax,%edx
801047ce:	74 2d                	je     801047fd <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801047d0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047d3:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801047d7:	0f b6 d0             	movzbl %al,%edx
801047da:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801047df:	89 54 24 08          	mov    %edx,0x8(%esp)
801047e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801047e7:	c7 04 24 1a 97 10 80 	movl   $0x8010971a,(%esp)
801047ee:	e8 ae bb ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801047f3:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801047fa:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801047fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104800:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104804:	0f b6 c0             	movzbl %al,%eax
80104807:	83 e0 02             	and    $0x2,%eax
8010480a:	85 c0                	test   %eax,%eax
8010480c:	74 15                	je     80104823 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
8010480e:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104813:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104819:	05 40 09 11 80       	add    $0x80110940,%eax
8010481e:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104823:	8b 15 20 0f 11 80    	mov    0x80110f20,%edx
80104829:	a1 20 0f 11 80       	mov    0x80110f20,%eax
8010482e:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104834:	81 c2 40 09 11 80    	add    $0x80110940,%edx
8010483a:	88 02                	mov    %al,(%edx)
      ncpu++;
8010483c:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104841:	83 c0 01             	add    $0x1,%eax
80104844:	a3 20 0f 11 80       	mov    %eax,0x80110f20
      p += sizeof(struct mpproc);
80104849:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
8010484d:	eb 41                	jmp    80104890 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
8010484f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104852:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104855:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104858:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010485c:	a2 20 09 11 80       	mov    %al,0x80110920
      p += sizeof(struct mpioapic);
80104861:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104865:	eb 29                	jmp    80104890 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104867:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010486b:	eb 23                	jmp    80104890 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
8010486d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104870:	0f b6 00             	movzbl (%eax),%eax
80104873:	0f b6 c0             	movzbl %al,%eax
80104876:	89 44 24 04          	mov    %eax,0x4(%esp)
8010487a:	c7 04 24 38 97 10 80 	movl   $0x80109738,(%esp)
80104881:	e8 1b bb ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104886:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
8010488d:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104893:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104896:	0f 82 00 ff ff ff    	jb     8010479c <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
8010489c:	a1 24 09 11 80       	mov    0x80110924,%eax
801048a1:	85 c0                	test   %eax,%eax
801048a3:	75 1d                	jne    801048c2 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
801048a5:	c7 05 20 0f 11 80 01 	movl   $0x1,0x80110f20
801048ac:	00 00 00 
    lapic = 0;
801048af:	c7 05 9c 08 11 80 00 	movl   $0x0,0x8011089c
801048b6:	00 00 00 
    ioapicid = 0;
801048b9:	c6 05 20 09 11 80 00 	movb   $0x0,0x80110920
    return;
801048c0:	eb 44                	jmp    80104906 <mpinit+0x1c5>
  }

  if(mp->imcrp){
801048c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048c5:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801048c9:	84 c0                	test   %al,%al
801048cb:	74 39                	je     80104906 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801048cd:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801048d4:	00 
801048d5:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801048dc:	e8 12 fc ff ff       	call   801044f3 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801048e1:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801048e8:	e8 dc fb ff ff       	call   801044c9 <inb>
801048ed:	83 c8 01             	or     $0x1,%eax
801048f0:	0f b6 c0             	movzbl %al,%eax
801048f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801048f7:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801048fe:	e8 f0 fb ff ff       	call   801044f3 <outb>
80104903:	eb 01                	jmp    80104906 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104905:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104906:	c9                   	leave  
80104907:	c3                   	ret    

80104908 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104908:	55                   	push   %ebp
80104909:	89 e5                	mov    %esp,%ebp
8010490b:	83 ec 08             	sub    $0x8,%esp
8010490e:	8b 55 08             	mov    0x8(%ebp),%edx
80104911:	8b 45 0c             	mov    0xc(%ebp),%eax
80104914:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104918:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010491b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010491f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104923:	ee                   	out    %al,(%dx)
}
80104924:	c9                   	leave  
80104925:	c3                   	ret    

80104926 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104926:	55                   	push   %ebp
80104927:	89 e5                	mov    %esp,%ebp
80104929:	83 ec 0c             	sub    $0xc,%esp
8010492c:	8b 45 08             	mov    0x8(%ebp),%eax
8010492f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104933:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104937:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
8010493d:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104941:	0f b6 c0             	movzbl %al,%eax
80104944:	89 44 24 04          	mov    %eax,0x4(%esp)
80104948:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010494f:	e8 b4 ff ff ff       	call   80104908 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104954:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104958:	66 c1 e8 08          	shr    $0x8,%ax
8010495c:	0f b6 c0             	movzbl %al,%eax
8010495f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104963:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010496a:	e8 99 ff ff ff       	call   80104908 <outb>
}
8010496f:	c9                   	leave  
80104970:	c3                   	ret    

80104971 <picenable>:

void
picenable(int irq)
{
80104971:	55                   	push   %ebp
80104972:	89 e5                	mov    %esp,%ebp
80104974:	53                   	push   %ebx
80104975:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104978:	8b 45 08             	mov    0x8(%ebp),%eax
8010497b:	ba 01 00 00 00       	mov    $0x1,%edx
80104980:	89 d3                	mov    %edx,%ebx
80104982:	89 c1                	mov    %eax,%ecx
80104984:	d3 e3                	shl    %cl,%ebx
80104986:	89 d8                	mov    %ebx,%eax
80104988:	89 c2                	mov    %eax,%edx
8010498a:	f7 d2                	not    %edx
8010498c:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104993:	21 d0                	and    %edx,%eax
80104995:	0f b7 c0             	movzwl %ax,%eax
80104998:	89 04 24             	mov    %eax,(%esp)
8010499b:	e8 86 ff ff ff       	call   80104926 <picsetmask>
}
801049a0:	83 c4 04             	add    $0x4,%esp
801049a3:	5b                   	pop    %ebx
801049a4:	5d                   	pop    %ebp
801049a5:	c3                   	ret    

801049a6 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
801049a6:	55                   	push   %ebp
801049a7:	89 e5                	mov    %esp,%ebp
801049a9:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801049ac:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801049b3:	00 
801049b4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801049bb:	e8 48 ff ff ff       	call   80104908 <outb>
  outb(IO_PIC2+1, 0xFF);
801049c0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801049c7:	00 
801049c8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801049cf:	e8 34 ff ff ff       	call   80104908 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801049d4:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801049db:	00 
801049dc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801049e3:	e8 20 ff ff ff       	call   80104908 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801049e8:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801049ef:	00 
801049f0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801049f7:	e8 0c ff ff ff       	call   80104908 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801049fc:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104a03:	00 
80104a04:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104a0b:	e8 f8 fe ff ff       	call   80104908 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104a10:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104a17:	00 
80104a18:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104a1f:	e8 e4 fe ff ff       	call   80104908 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104a24:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104a2b:	00 
80104a2c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104a33:	e8 d0 fe ff ff       	call   80104908 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104a38:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104a3f:	00 
80104a40:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a47:	e8 bc fe ff ff       	call   80104908 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104a4c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104a53:	00 
80104a54:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a5b:	e8 a8 fe ff ff       	call   80104908 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104a60:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104a67:	00 
80104a68:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a6f:	e8 94 fe ff ff       	call   80104908 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104a74:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104a7b:	00 
80104a7c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104a83:	e8 80 fe ff ff       	call   80104908 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104a88:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104a8f:	00 
80104a90:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104a97:	e8 6c fe ff ff       	call   80104908 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104a9c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104aa3:	00 
80104aa4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104aab:	e8 58 fe ff ff       	call   80104908 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104ab0:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104ab7:	00 
80104ab8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104abf:	e8 44 fe ff ff       	call   80104908 <outb>

  if(irqmask != 0xFFFF)
80104ac4:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104acb:	66 83 f8 ff          	cmp    $0xffff,%ax
80104acf:	74 12                	je     80104ae3 <picinit+0x13d>
    picsetmask(irqmask);
80104ad1:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ad8:	0f b7 c0             	movzwl %ax,%eax
80104adb:	89 04 24             	mov    %eax,(%esp)
80104ade:	e8 43 fe ff ff       	call   80104926 <picsetmask>
}
80104ae3:	c9                   	leave  
80104ae4:	c3                   	ret    
80104ae5:	00 00                	add    %al,(%eax)
	...

80104ae8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104ae8:	55                   	push   %ebp
80104ae9:	89 e5                	mov    %esp,%ebp
80104aeb:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104aee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104af5:	8b 45 0c             	mov    0xc(%ebp),%eax
80104af8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104afe:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b01:	8b 10                	mov    (%eax),%edx
80104b03:	8b 45 08             	mov    0x8(%ebp),%eax
80104b06:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104b08:	e8 0f c4 ff ff       	call   80100f1c <filealloc>
80104b0d:	8b 55 08             	mov    0x8(%ebp),%edx
80104b10:	89 02                	mov    %eax,(%edx)
80104b12:	8b 45 08             	mov    0x8(%ebp),%eax
80104b15:	8b 00                	mov    (%eax),%eax
80104b17:	85 c0                	test   %eax,%eax
80104b19:	0f 84 c8 00 00 00    	je     80104be7 <pipealloc+0xff>
80104b1f:	e8 f8 c3 ff ff       	call   80100f1c <filealloc>
80104b24:	8b 55 0c             	mov    0xc(%ebp),%edx
80104b27:	89 02                	mov    %eax,(%edx)
80104b29:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b2c:	8b 00                	mov    (%eax),%eax
80104b2e:	85 c0                	test   %eax,%eax
80104b30:	0f 84 b1 00 00 00    	je     80104be7 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104b36:	e8 74 ee ff ff       	call   801039af <kalloc>
80104b3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104b3e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b42:	0f 84 9e 00 00 00    	je     80104be6 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b4b:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104b52:	00 00 00 
  p->writeopen = 1;
80104b55:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b58:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104b5f:	00 00 00 
  p->nwrite = 0;
80104b62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b65:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104b6c:	00 00 00 
  p->nread = 0;
80104b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b72:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104b79:	00 00 00 
  initlock(&p->lock, "pipe");
80104b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7f:	c7 44 24 04 6c 97 10 	movl   $0x8010976c,0x4(%esp)
80104b86:	80 
80104b87:	89 04 24             	mov    %eax,(%esp)
80104b8a:	e8 a3 0e 00 00       	call   80105a32 <initlock>
  (*f0)->type = FD_PIPE;
80104b8f:	8b 45 08             	mov    0x8(%ebp),%eax
80104b92:	8b 00                	mov    (%eax),%eax
80104b94:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104b9a:	8b 45 08             	mov    0x8(%ebp),%eax
80104b9d:	8b 00                	mov    (%eax),%eax
80104b9f:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104ba3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ba6:	8b 00                	mov    (%eax),%eax
80104ba8:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104bac:	8b 45 08             	mov    0x8(%ebp),%eax
80104baf:	8b 00                	mov    (%eax),%eax
80104bb1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bb4:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bba:	8b 00                	mov    (%eax),%eax
80104bbc:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104bc2:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bc5:	8b 00                	mov    (%eax),%eax
80104bc7:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104bcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bce:	8b 00                	mov    (%eax),%eax
80104bd0:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104bd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bd7:	8b 00                	mov    (%eax),%eax
80104bd9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bdc:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104bdf:	b8 00 00 00 00       	mov    $0x0,%eax
80104be4:	eb 43                	jmp    80104c29 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104be6:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104be7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104beb:	74 0b                	je     80104bf8 <pipealloc+0x110>
    kfree((char*)p);
80104bed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf0:	89 04 24             	mov    %eax,(%esp)
80104bf3:	e8 1e ed ff ff       	call   80103916 <kfree>
  if(*f0)
80104bf8:	8b 45 08             	mov    0x8(%ebp),%eax
80104bfb:	8b 00                	mov    (%eax),%eax
80104bfd:	85 c0                	test   %eax,%eax
80104bff:	74 0d                	je     80104c0e <pipealloc+0x126>
    fileclose(*f0);
80104c01:	8b 45 08             	mov    0x8(%ebp),%eax
80104c04:	8b 00                	mov    (%eax),%eax
80104c06:	89 04 24             	mov    %eax,(%esp)
80104c09:	e8 b6 c3 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104c0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c11:	8b 00                	mov    (%eax),%eax
80104c13:	85 c0                	test   %eax,%eax
80104c15:	74 0d                	je     80104c24 <pipealloc+0x13c>
    fileclose(*f1);
80104c17:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c1a:	8b 00                	mov    (%eax),%eax
80104c1c:	89 04 24             	mov    %eax,(%esp)
80104c1f:	e8 a0 c3 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104c24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c29:	c9                   	leave  
80104c2a:	c3                   	ret    

80104c2b <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104c2b:	55                   	push   %ebp
80104c2c:	89 e5                	mov    %esp,%ebp
80104c2e:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104c31:	8b 45 08             	mov    0x8(%ebp),%eax
80104c34:	89 04 24             	mov    %eax,(%esp)
80104c37:	e8 17 0e 00 00       	call   80105a53 <acquire>
  if(writable){
80104c3c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c40:	74 1f                	je     80104c61 <pipeclose+0x36>
    p->writeopen = 0;
80104c42:	8b 45 08             	mov    0x8(%ebp),%eax
80104c45:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104c4c:	00 00 00 
    wakeup(&p->nread);
80104c4f:	8b 45 08             	mov    0x8(%ebp),%eax
80104c52:	05 34 02 00 00       	add    $0x234,%eax
80104c57:	89 04 24             	mov    %eax,(%esp)
80104c5a:	e8 ef 0b 00 00       	call   8010584e <wakeup>
80104c5f:	eb 1d                	jmp    80104c7e <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104c61:	8b 45 08             	mov    0x8(%ebp),%eax
80104c64:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104c6b:	00 00 00 
    wakeup(&p->nwrite);
80104c6e:	8b 45 08             	mov    0x8(%ebp),%eax
80104c71:	05 38 02 00 00       	add    $0x238,%eax
80104c76:	89 04 24             	mov    %eax,(%esp)
80104c79:	e8 d0 0b 00 00       	call   8010584e <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104c7e:	8b 45 08             	mov    0x8(%ebp),%eax
80104c81:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104c87:	85 c0                	test   %eax,%eax
80104c89:	75 25                	jne    80104cb0 <pipeclose+0x85>
80104c8b:	8b 45 08             	mov    0x8(%ebp),%eax
80104c8e:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104c94:	85 c0                	test   %eax,%eax
80104c96:	75 18                	jne    80104cb0 <pipeclose+0x85>
    release(&p->lock);
80104c98:	8b 45 08             	mov    0x8(%ebp),%eax
80104c9b:	89 04 24             	mov    %eax,(%esp)
80104c9e:	e8 12 0e 00 00       	call   80105ab5 <release>
    kfree((char*)p);
80104ca3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca6:	89 04 24             	mov    %eax,(%esp)
80104ca9:	e8 68 ec ff ff       	call   80103916 <kfree>
80104cae:	eb 0b                	jmp    80104cbb <pipeclose+0x90>
  } else
    release(&p->lock);
80104cb0:	8b 45 08             	mov    0x8(%ebp),%eax
80104cb3:	89 04 24             	mov    %eax,(%esp)
80104cb6:	e8 fa 0d 00 00       	call   80105ab5 <release>
}
80104cbb:	c9                   	leave  
80104cbc:	c3                   	ret    

80104cbd <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104cbd:	55                   	push   %ebp
80104cbe:	89 e5                	mov    %esp,%ebp
80104cc0:	53                   	push   %ebx
80104cc1:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104cc4:	8b 45 08             	mov    0x8(%ebp),%eax
80104cc7:	89 04 24             	mov    %eax,(%esp)
80104cca:	e8 84 0d 00 00       	call   80105a53 <acquire>
  for(i = 0; i < n; i++){
80104ccf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104cd6:	e9 a6 00 00 00       	jmp    80104d81 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104cdb:	8b 45 08             	mov    0x8(%ebp),%eax
80104cde:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104ce4:	85 c0                	test   %eax,%eax
80104ce6:	74 0d                	je     80104cf5 <pipewrite+0x38>
80104ce8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cee:	8b 40 24             	mov    0x24(%eax),%eax
80104cf1:	85 c0                	test   %eax,%eax
80104cf3:	74 15                	je     80104d0a <pipewrite+0x4d>
        release(&p->lock);
80104cf5:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf8:	89 04 24             	mov    %eax,(%esp)
80104cfb:	e8 b5 0d 00 00       	call   80105ab5 <release>
        return -1;
80104d00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d05:	e9 9d 00 00 00       	jmp    80104da7 <pipewrite+0xea>
      }
      wakeup(&p->nread);
80104d0a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d0d:	05 34 02 00 00       	add    $0x234,%eax
80104d12:	89 04 24             	mov    %eax,(%esp)
80104d15:	e8 34 0b 00 00       	call   8010584e <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80104d1d:	8b 55 08             	mov    0x8(%ebp),%edx
80104d20:	81 c2 38 02 00 00    	add    $0x238,%edx
80104d26:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d2a:	89 14 24             	mov    %edx,(%esp)
80104d2d:	e8 43 0a 00 00       	call   80105775 <sleep>
80104d32:	eb 01                	jmp    80104d35 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104d34:	90                   	nop
80104d35:	8b 45 08             	mov    0x8(%ebp),%eax
80104d38:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104d3e:	8b 45 08             	mov    0x8(%ebp),%eax
80104d41:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104d47:	05 00 02 00 00       	add    $0x200,%eax
80104d4c:	39 c2                	cmp    %eax,%edx
80104d4e:	74 8b                	je     80104cdb <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104d50:	8b 45 08             	mov    0x8(%ebp),%eax
80104d53:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104d59:	89 c3                	mov    %eax,%ebx
80104d5b:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104d61:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d64:	03 55 0c             	add    0xc(%ebp),%edx
80104d67:	0f b6 0a             	movzbl (%edx),%ecx
80104d6a:	8b 55 08             	mov    0x8(%ebp),%edx
80104d6d:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104d71:	8d 50 01             	lea    0x1(%eax),%edx
80104d74:	8b 45 08             	mov    0x8(%ebp),%eax
80104d77:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104d7d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d84:	3b 45 10             	cmp    0x10(%ebp),%eax
80104d87:	7c ab                	jl     80104d34 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104d89:	8b 45 08             	mov    0x8(%ebp),%eax
80104d8c:	05 34 02 00 00       	add    $0x234,%eax
80104d91:	89 04 24             	mov    %eax,(%esp)
80104d94:	e8 b5 0a 00 00       	call   8010584e <wakeup>
  release(&p->lock);
80104d99:	8b 45 08             	mov    0x8(%ebp),%eax
80104d9c:	89 04 24             	mov    %eax,(%esp)
80104d9f:	e8 11 0d 00 00       	call   80105ab5 <release>
  return n;
80104da4:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104da7:	83 c4 24             	add    $0x24,%esp
80104daa:	5b                   	pop    %ebx
80104dab:	5d                   	pop    %ebp
80104dac:	c3                   	ret    

80104dad <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104dad:	55                   	push   %ebp
80104dae:	89 e5                	mov    %esp,%ebp
80104db0:	53                   	push   %ebx
80104db1:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104db4:	8b 45 08             	mov    0x8(%ebp),%eax
80104db7:	89 04 24             	mov    %eax,(%esp)
80104dba:	e8 94 0c 00 00       	call   80105a53 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104dbf:	eb 3a                	jmp    80104dfb <piperead+0x4e>
    if(proc->killed){
80104dc1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dc7:	8b 40 24             	mov    0x24(%eax),%eax
80104dca:	85 c0                	test   %eax,%eax
80104dcc:	74 15                	je     80104de3 <piperead+0x36>
      release(&p->lock);
80104dce:	8b 45 08             	mov    0x8(%ebp),%eax
80104dd1:	89 04 24             	mov    %eax,(%esp)
80104dd4:	e8 dc 0c 00 00       	call   80105ab5 <release>
      return -1;
80104dd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dde:	e9 b6 00 00 00       	jmp    80104e99 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104de3:	8b 45 08             	mov    0x8(%ebp),%eax
80104de6:	8b 55 08             	mov    0x8(%ebp),%edx
80104de9:	81 c2 34 02 00 00    	add    $0x234,%edx
80104def:	89 44 24 04          	mov    %eax,0x4(%esp)
80104df3:	89 14 24             	mov    %edx,(%esp)
80104df6:	e8 7a 09 00 00       	call   80105775 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80104dfe:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104e04:	8b 45 08             	mov    0x8(%ebp),%eax
80104e07:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104e0d:	39 c2                	cmp    %eax,%edx
80104e0f:	75 0d                	jne    80104e1e <piperead+0x71>
80104e11:	8b 45 08             	mov    0x8(%ebp),%eax
80104e14:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104e1a:	85 c0                	test   %eax,%eax
80104e1c:	75 a3                	jne    80104dc1 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104e1e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e25:	eb 49                	jmp    80104e70 <piperead+0xc3>
    if(p->nread == p->nwrite)
80104e27:	8b 45 08             	mov    0x8(%ebp),%eax
80104e2a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104e30:	8b 45 08             	mov    0x8(%ebp),%eax
80104e33:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104e39:	39 c2                	cmp    %eax,%edx
80104e3b:	74 3d                	je     80104e7a <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e40:	89 c2                	mov    %eax,%edx
80104e42:	03 55 0c             	add    0xc(%ebp),%edx
80104e45:	8b 45 08             	mov    0x8(%ebp),%eax
80104e48:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104e4e:	89 c3                	mov    %eax,%ebx
80104e50:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104e56:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e59:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104e5e:	88 0a                	mov    %cl,(%edx)
80104e60:	8d 50 01             	lea    0x1(%eax),%edx
80104e63:	8b 45 08             	mov    0x8(%ebp),%eax
80104e66:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104e6c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e73:	3b 45 10             	cmp    0x10(%ebp),%eax
80104e76:	7c af                	jl     80104e27 <piperead+0x7a>
80104e78:	eb 01                	jmp    80104e7b <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104e7a:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104e7b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e7e:	05 38 02 00 00       	add    $0x238,%eax
80104e83:	89 04 24             	mov    %eax,(%esp)
80104e86:	e8 c3 09 00 00       	call   8010584e <wakeup>
  release(&p->lock);
80104e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e8e:	89 04 24             	mov    %eax,(%esp)
80104e91:	e8 1f 0c 00 00       	call   80105ab5 <release>
  return i;
80104e96:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104e99:	83 c4 24             	add    $0x24,%esp
80104e9c:	5b                   	pop    %ebx
80104e9d:	5d                   	pop    %ebp
80104e9e:	c3                   	ret    
	...

80104ea0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104ea0:	55                   	push   %ebp
80104ea1:	89 e5                	mov    %esp,%ebp
80104ea3:	53                   	push   %ebx
80104ea4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104ea7:	9c                   	pushf  
80104ea8:	5b                   	pop    %ebx
80104ea9:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104eac:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104eaf:	83 c4 10             	add    $0x10,%esp
80104eb2:	5b                   	pop    %ebx
80104eb3:	5d                   	pop    %ebp
80104eb4:	c3                   	ret    

80104eb5 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104eb5:	55                   	push   %ebp
80104eb6:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104eb8:	fb                   	sti    
}
80104eb9:	5d                   	pop    %ebp
80104eba:	c3                   	ret    

80104ebb <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104ebb:	55                   	push   %ebp
80104ebc:	89 e5                	mov    %esp,%ebp
80104ebe:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104ec1:	c7 44 24 04 71 97 10 	movl   $0x80109771,0x4(%esp)
80104ec8:	80 
80104ec9:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104ed0:	e8 5d 0b 00 00       	call   80105a32 <initlock>
}
80104ed5:	c9                   	leave  
80104ed6:	c3                   	ret    

80104ed7 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104ed7:	55                   	push   %ebp
80104ed8:	89 e5                	mov    %esp,%ebp
80104eda:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104edd:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104ee4:	e8 6a 0b 00 00       	call   80105a53 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ee9:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80104ef0:	eb 0e                	jmp    80104f00 <allocproc+0x29>
    if(p->state == UNUSED)
80104ef2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef5:	8b 40 0c             	mov    0xc(%eax),%eax
80104ef8:	85 c0                	test   %eax,%eax
80104efa:	74 23                	je     80104f1f <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104efc:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104f00:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80104f07:	72 e9                	jb     80104ef2 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104f09:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104f10:	e8 a0 0b 00 00       	call   80105ab5 <release>
  return 0;
80104f15:	b8 00 00 00 00       	mov    $0x0,%eax
80104f1a:	e9 b5 00 00 00       	jmp    80104fd4 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104f1f:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104f20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f23:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104f2a:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104f2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f32:	89 42 10             	mov    %eax,0x10(%edx)
80104f35:	83 c0 01             	add    $0x1,%eax
80104f38:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80104f3d:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104f44:	e8 6c 0b 00 00       	call   80105ab5 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104f49:	e8 61 ea ff ff       	call   801039af <kalloc>
80104f4e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f51:	89 42 08             	mov    %eax,0x8(%edx)
80104f54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f57:	8b 40 08             	mov    0x8(%eax),%eax
80104f5a:	85 c0                	test   %eax,%eax
80104f5c:	75 11                	jne    80104f6f <allocproc+0x98>
    p->state = UNUSED;
80104f5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f61:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104f68:	b8 00 00 00 00       	mov    $0x0,%eax
80104f6d:	eb 65                	jmp    80104fd4 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104f6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f72:	8b 40 08             	mov    0x8(%eax),%eax
80104f75:	05 00 10 00 00       	add    $0x1000,%eax
80104f7a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104f7d:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104f81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f84:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f87:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104f8a:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104f8e:	ba 88 72 10 80       	mov    $0x80107288,%edx
80104f93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f96:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104f98:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104f9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f9f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104fa2:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fa8:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fab:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104fb2:	00 
80104fb3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104fba:	00 
80104fbb:	89 04 24             	mov    %eax,(%esp)
80104fbe:	e8 df 0c 00 00       	call   80105ca2 <memset>
  p->context->eip = (uint)forkret;
80104fc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fc6:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fc9:	ba 49 57 10 80       	mov    $0x80105749,%edx
80104fce:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104fd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104fd4:	c9                   	leave  
80104fd5:	c3                   	ret    

80104fd6 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104fd6:	55                   	push   %ebp
80104fd7:	89 e5                	mov    %esp,%ebp
80104fd9:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104fdc:	e8 f6 fe ff ff       	call   80104ed7 <allocproc>
80104fe1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104fe4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fe7:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104fec:	c7 04 24 af 39 10 80 	movl   $0x801039af,(%esp)
80104ff3:	e8 8d 39 00 00       	call   80108985 <setupkvm>
80104ff8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ffb:	89 42 04             	mov    %eax,0x4(%edx)
80104ffe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105001:	8b 40 04             	mov    0x4(%eax),%eax
80105004:	85 c0                	test   %eax,%eax
80105006:	75 0c                	jne    80105014 <userinit+0x3e>
    panic("userinit: out of memory?");
80105008:	c7 04 24 78 97 10 80 	movl   $0x80109778,(%esp)
8010500f:	e8 29 b5 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80105014:	ba 2c 00 00 00       	mov    $0x2c,%edx
80105019:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010501c:	8b 40 04             	mov    0x4(%eax),%eax
8010501f:	89 54 24 08          	mov    %edx,0x8(%esp)
80105023:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
8010502a:	80 
8010502b:	89 04 24             	mov    %eax,(%esp)
8010502e:	e8 aa 3b 00 00       	call   80108bdd <inituvm>
  p->sz = PGSIZE;
80105033:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105036:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
8010503c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010503f:	8b 40 18             	mov    0x18(%eax),%eax
80105042:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80105049:	00 
8010504a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105051:	00 
80105052:	89 04 24             	mov    %eax,(%esp)
80105055:	e8 48 0c 00 00       	call   80105ca2 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010505a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010505d:	8b 40 18             	mov    0x18(%eax),%eax
80105060:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80105066:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105069:	8b 40 18             	mov    0x18(%eax),%eax
8010506c:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80105072:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105075:	8b 40 18             	mov    0x18(%eax),%eax
80105078:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010507b:	8b 52 18             	mov    0x18(%edx),%edx
8010507e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105082:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80105086:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105089:	8b 40 18             	mov    0x18(%eax),%eax
8010508c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010508f:	8b 52 18             	mov    0x18(%edx),%edx
80105092:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80105096:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010509a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010509d:	8b 40 18             	mov    0x18(%eax),%eax
801050a0:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801050a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050aa:	8b 40 18             	mov    0x18(%eax),%eax
801050ad:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801050b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050b7:	8b 40 18             	mov    0x18(%eax),%eax
801050ba:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801050c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050c4:	83 c0 6c             	add    $0x6c,%eax
801050c7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801050ce:	00 
801050cf:	c7 44 24 04 91 97 10 	movl   $0x80109791,0x4(%esp)
801050d6:	80 
801050d7:	89 04 24             	mov    %eax,(%esp)
801050da:	e8 f3 0d 00 00       	call   80105ed2 <safestrcpy>
  p->cwd = namei("/");
801050df:	c7 04 24 9a 97 10 80 	movl   $0x8010979a,(%esp)
801050e6:	e8 ab de ff ff       	call   80102f96 <namei>
801050eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050ee:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801050f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050f4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801050fb:	c9                   	leave  
801050fc:	c3                   	ret    

801050fd <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801050fd:	55                   	push   %ebp
801050fe:	89 e5                	mov    %esp,%ebp
80105100:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105103:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105109:	8b 00                	mov    (%eax),%eax
8010510b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010510e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105112:	7e 34                	jle    80105148 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105114:	8b 45 08             	mov    0x8(%ebp),%eax
80105117:	89 c2                	mov    %eax,%edx
80105119:	03 55 f4             	add    -0xc(%ebp),%edx
8010511c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105122:	8b 40 04             	mov    0x4(%eax),%eax
80105125:	89 54 24 08          	mov    %edx,0x8(%esp)
80105129:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010512c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105130:	89 04 24             	mov    %eax,(%esp)
80105133:	e8 1f 3c 00 00       	call   80108d57 <allocuvm>
80105138:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010513b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010513f:	75 41                	jne    80105182 <growproc+0x85>
      return -1;
80105141:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105146:	eb 58                	jmp    801051a0 <growproc+0xa3>
  } else if(n < 0){
80105148:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010514c:	79 34                	jns    80105182 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
8010514e:	8b 45 08             	mov    0x8(%ebp),%eax
80105151:	89 c2                	mov    %eax,%edx
80105153:	03 55 f4             	add    -0xc(%ebp),%edx
80105156:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010515c:	8b 40 04             	mov    0x4(%eax),%eax
8010515f:	89 54 24 08          	mov    %edx,0x8(%esp)
80105163:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105166:	89 54 24 04          	mov    %edx,0x4(%esp)
8010516a:	89 04 24             	mov    %eax,(%esp)
8010516d:	e8 bf 3c 00 00       	call   80108e31 <deallocuvm>
80105172:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105175:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105179:	75 07                	jne    80105182 <growproc+0x85>
      return -1;
8010517b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105180:	eb 1e                	jmp    801051a0 <growproc+0xa3>
  }
  proc->sz = sz;
80105182:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105188:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010518b:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
8010518d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105193:	89 04 24             	mov    %eax,(%esp)
80105196:	e8 db 38 00 00       	call   80108a76 <switchuvm>
  return 0;
8010519b:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051a0:	c9                   	leave  
801051a1:	c3                   	ret    

801051a2 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801051a2:	55                   	push   %ebp
801051a3:	89 e5                	mov    %esp,%ebp
801051a5:	57                   	push   %edi
801051a6:	56                   	push   %esi
801051a7:	53                   	push   %ebx
801051a8:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801051ab:	e8 27 fd ff ff       	call   80104ed7 <allocproc>
801051b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
801051b3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801051b7:	75 0a                	jne    801051c3 <fork+0x21>
    return -1;
801051b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051be:	e9 3a 01 00 00       	jmp    801052fd <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801051c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c9:	8b 10                	mov    (%eax),%edx
801051cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051d1:	8b 40 04             	mov    0x4(%eax),%eax
801051d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801051d8:	89 04 24             	mov    %eax,(%esp)
801051db:	e8 e1 3d 00 00       	call   80108fc1 <copyuvm>
801051e0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801051e3:	89 42 04             	mov    %eax,0x4(%edx)
801051e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051e9:	8b 40 04             	mov    0x4(%eax),%eax
801051ec:	85 c0                	test   %eax,%eax
801051ee:	75 2c                	jne    8010521c <fork+0x7a>
    kfree(np->kstack);
801051f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051f3:	8b 40 08             	mov    0x8(%eax),%eax
801051f6:	89 04 24             	mov    %eax,(%esp)
801051f9:	e8 18 e7 ff ff       	call   80103916 <kfree>
    np->kstack = 0;
801051fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105201:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105208:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010520b:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105212:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105217:	e9 e1 00 00 00       	jmp    801052fd <fork+0x15b>
  }
  np->sz = proc->sz;
8010521c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105222:	8b 10                	mov    (%eax),%edx
80105224:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105227:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80105229:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105230:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105233:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80105236:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105239:	8b 50 18             	mov    0x18(%eax),%edx
8010523c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105242:	8b 40 18             	mov    0x18(%eax),%eax
80105245:	89 c3                	mov    %eax,%ebx
80105247:	b8 13 00 00 00       	mov    $0x13,%eax
8010524c:	89 d7                	mov    %edx,%edi
8010524e:	89 de                	mov    %ebx,%esi
80105250:	89 c1                	mov    %eax,%ecx
80105252:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80105254:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105257:	8b 40 18             	mov    0x18(%eax),%eax
8010525a:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105261:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105268:	eb 3d                	jmp    801052a7 <fork+0x105>
    if(proc->ofile[i])
8010526a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105270:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105273:	83 c2 08             	add    $0x8,%edx
80105276:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010527a:	85 c0                	test   %eax,%eax
8010527c:	74 25                	je     801052a3 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010527e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105284:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80105287:	83 c2 08             	add    $0x8,%edx
8010528a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010528e:	89 04 24             	mov    %eax,(%esp)
80105291:	e8 e6 bc ff ff       	call   80100f7c <filedup>
80105296:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105299:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010529c:	83 c1 08             	add    $0x8,%ecx
8010529f:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801052a3:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801052a7:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801052ab:	7e bd                	jle    8010526a <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801052ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052b3:	8b 40 68             	mov    0x68(%eax),%eax
801052b6:	89 04 24             	mov    %eax,(%esp)
801052b9:	e8 04 d1 ff ff       	call   801023c2 <idup>
801052be:	8b 55 e0             	mov    -0x20(%ebp),%edx
801052c1:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801052c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052c7:	8b 40 10             	mov    0x10(%eax),%eax
801052ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801052cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052d0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801052d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052dd:	8d 50 6c             	lea    0x6c(%eax),%edx
801052e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052e3:	83 c0 6c             	add    $0x6c,%eax
801052e6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801052ed:	00 
801052ee:	89 54 24 04          	mov    %edx,0x4(%esp)
801052f2:	89 04 24             	mov    %eax,(%esp)
801052f5:	e8 d8 0b 00 00       	call   80105ed2 <safestrcpy>
  return pid;
801052fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801052fd:	83 c4 2c             	add    $0x2c,%esp
80105300:	5b                   	pop    %ebx
80105301:	5e                   	pop    %esi
80105302:	5f                   	pop    %edi
80105303:	5d                   	pop    %ebp
80105304:	c3                   	ret    

80105305 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105305:	55                   	push   %ebp
80105306:	89 e5                	mov    %esp,%ebp
80105308:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010530b:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105312:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80105317:	39 c2                	cmp    %eax,%edx
80105319:	75 0c                	jne    80105327 <exit+0x22>
    panic("init exiting");
8010531b:	c7 04 24 9c 97 10 80 	movl   $0x8010979c,(%esp)
80105322:	e8 16 b2 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105327:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010532e:	eb 44                	jmp    80105374 <exit+0x6f>
    if(proc->ofile[fd]){
80105330:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105336:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105339:	83 c2 08             	add    $0x8,%edx
8010533c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105340:	85 c0                	test   %eax,%eax
80105342:	74 2c                	je     80105370 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105344:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010534a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010534d:	83 c2 08             	add    $0x8,%edx
80105350:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105354:	89 04 24             	mov    %eax,(%esp)
80105357:	e8 68 bc ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
8010535c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105362:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105365:	83 c2 08             	add    $0x8,%edx
80105368:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010536f:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105370:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80105374:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105378:	7e b6                	jle    80105330 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
8010537a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105380:	8b 40 68             	mov    0x68(%eax),%eax
80105383:	89 04 24             	mov    %eax,(%esp)
80105386:	e8 1c d2 ff ff       	call   801025a7 <iput>
  proc->cwd = 0;
8010538b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105391:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80105398:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010539f:	e8 af 06 00 00       	call   80105a53 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801053a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053aa:	8b 40 14             	mov    0x14(%eax),%eax
801053ad:	89 04 24             	mov    %eax,(%esp)
801053b0:	e8 5b 04 00 00       	call   80105810 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053b5:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801053bc:	eb 38                	jmp    801053f6 <exit+0xf1>
    if(p->parent == proc){
801053be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c1:	8b 50 14             	mov    0x14(%eax),%edx
801053c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ca:	39 c2                	cmp    %eax,%edx
801053cc:	75 24                	jne    801053f2 <exit+0xed>
      p->parent = initproc;
801053ce:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801053d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053d7:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801053da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053dd:	8b 40 0c             	mov    0xc(%eax),%eax
801053e0:	83 f8 05             	cmp    $0x5,%eax
801053e3:	75 0d                	jne    801053f2 <exit+0xed>
        wakeup1(initproc);
801053e5:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801053ea:	89 04 24             	mov    %eax,(%esp)
801053ed:	e8 1e 04 00 00       	call   80105810 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053f2:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801053f6:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801053fd:	72 bf                	jb     801053be <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801053ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105405:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
8010540c:	e8 54 02 00 00       	call   80105665 <sched>
  panic("zombie exit");
80105411:	c7 04 24 a9 97 10 80 	movl   $0x801097a9,(%esp)
80105418:	e8 20 b1 ff ff       	call   8010053d <panic>

8010541d <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010541d:	55                   	push   %ebp
8010541e:	89 e5                	mov    %esp,%ebp
80105420:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105423:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010542a:	e8 24 06 00 00       	call   80105a53 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
8010542f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105436:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
8010543d:	e9 9a 00 00 00       	jmp    801054dc <wait+0xbf>
      if(p->parent != proc)
80105442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105445:	8b 50 14             	mov    0x14(%eax),%edx
80105448:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010544e:	39 c2                	cmp    %eax,%edx
80105450:	0f 85 81 00 00 00    	jne    801054d7 <wait+0xba>
        continue;
      havekids = 1;
80105456:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
8010545d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105460:	8b 40 0c             	mov    0xc(%eax),%eax
80105463:	83 f8 05             	cmp    $0x5,%eax
80105466:	75 70                	jne    801054d8 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105468:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546b:	8b 40 10             	mov    0x10(%eax),%eax
8010546e:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105471:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105474:	8b 40 08             	mov    0x8(%eax),%eax
80105477:	89 04 24             	mov    %eax,(%esp)
8010547a:	e8 97 e4 ff ff       	call   80103916 <kfree>
        p->kstack = 0;
8010547f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105482:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105489:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010548c:	8b 40 04             	mov    0x4(%eax),%eax
8010548f:	89 04 24             	mov    %eax,(%esp)
80105492:	e8 56 3a 00 00       	call   80108eed <freevm>
        p->state = UNUSED;
80105497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010549a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801054a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a4:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801054ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ae:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801054b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054b8:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801054bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054bf:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801054c6:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054cd:	e8 e3 05 00 00       	call   80105ab5 <release>
        return pid;
801054d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801054d5:	eb 53                	jmp    8010552a <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801054d7:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054d8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801054dc:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801054e3:	0f 82 59 ff ff ff    	jb     80105442 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801054e9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801054ed:	74 0d                	je     801054fc <wait+0xdf>
801054ef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054f5:	8b 40 24             	mov    0x24(%eax),%eax
801054f8:	85 c0                	test   %eax,%eax
801054fa:	74 13                	je     8010550f <wait+0xf2>
      release(&ptable.lock);
801054fc:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105503:	e8 ad 05 00 00       	call   80105ab5 <release>
      return -1;
80105508:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010550d:	eb 1b                	jmp    8010552a <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010550f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105515:	c7 44 24 04 40 0f 11 	movl   $0x80110f40,0x4(%esp)
8010551c:	80 
8010551d:	89 04 24             	mov    %eax,(%esp)
80105520:	e8 50 02 00 00       	call   80105775 <sleep>
  }
80105525:	e9 05 ff ff ff       	jmp    8010542f <wait+0x12>
}
8010552a:	c9                   	leave  
8010552b:	c3                   	ret    

8010552c <register_handler>:

void
register_handler(sighandler_t sighandler)
{
8010552c:	55                   	push   %ebp
8010552d:	89 e5                	mov    %esp,%ebp
8010552f:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80105532:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105538:	8b 40 18             	mov    0x18(%eax),%eax
8010553b:	8b 40 44             	mov    0x44(%eax),%eax
8010553e:	89 c2                	mov    %eax,%edx
80105540:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105546:	8b 40 04             	mov    0x4(%eax),%eax
80105549:	89 54 24 04          	mov    %edx,0x4(%esp)
8010554d:	89 04 24             	mov    %eax,(%esp)
80105550:	e8 7d 3b 00 00       	call   801090d2 <uva2ka>
80105555:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105558:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010555e:	8b 40 18             	mov    0x18(%eax),%eax
80105561:	8b 40 44             	mov    0x44(%eax),%eax
80105564:	25 ff 0f 00 00       	and    $0xfff,%eax
80105569:	85 c0                	test   %eax,%eax
8010556b:	75 0c                	jne    80105579 <register_handler+0x4d>
    panic("esp_offset == 0");
8010556d:	c7 04 24 b5 97 10 80 	movl   $0x801097b5,(%esp)
80105574:	e8 c4 af ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105579:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010557f:	8b 40 18             	mov    0x18(%eax),%eax
80105582:	8b 40 44             	mov    0x44(%eax),%eax
80105585:	83 e8 04             	sub    $0x4,%eax
80105588:	25 ff 0f 00 00       	and    $0xfff,%eax
8010558d:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105590:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105597:	8b 52 18             	mov    0x18(%edx),%edx
8010559a:	8b 52 38             	mov    0x38(%edx),%edx
8010559d:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010559f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055a5:	8b 40 18             	mov    0x18(%eax),%eax
801055a8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801055af:	8b 52 18             	mov    0x18(%edx),%edx
801055b2:	8b 52 44             	mov    0x44(%edx),%edx
801055b5:	83 ea 04             	sub    $0x4,%edx
801055b8:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801055bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c1:	8b 40 18             	mov    0x18(%eax),%eax
801055c4:	8b 55 08             	mov    0x8(%ebp),%edx
801055c7:	89 50 38             	mov    %edx,0x38(%eax)
}
801055ca:	c9                   	leave  
801055cb:	c3                   	ret    

801055cc <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801055cc:	55                   	push   %ebp
801055cd:	89 e5                	mov    %esp,%ebp
801055cf:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801055d2:	e8 de f8 ff ff       	call   80104eb5 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801055d7:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801055de:	e8 70 04 00 00       	call   80105a53 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055e3:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801055ea:	eb 5f                	jmp    8010564b <scheduler+0x7f>
      if(p->state != RUNNABLE)
801055ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ef:	8b 40 0c             	mov    0xc(%eax),%eax
801055f2:	83 f8 03             	cmp    $0x3,%eax
801055f5:	75 4f                	jne    80105646 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801055f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055fa:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105600:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105603:	89 04 24             	mov    %eax,(%esp)
80105606:	e8 6b 34 00 00       	call   80108a76 <switchuvm>
      p->state = RUNNING;
8010560b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010560e:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105615:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010561b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010561e:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105625:	83 c2 04             	add    $0x4,%edx
80105628:	89 44 24 04          	mov    %eax,0x4(%esp)
8010562c:	89 14 24             	mov    %edx,(%esp)
8010562f:	e8 14 09 00 00       	call   80105f48 <swtch>
      switchkvm();
80105634:	e8 20 34 00 00       	call   80108a59 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105639:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105640:	00 00 00 00 
80105644:	eb 01                	jmp    80105647 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80105646:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105647:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010564b:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80105652:	72 98                	jb     801055ec <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105654:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010565b:	e8 55 04 00 00       	call   80105ab5 <release>

  }
80105660:	e9 6d ff ff ff       	jmp    801055d2 <scheduler+0x6>

80105665 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105665:	55                   	push   %ebp
80105666:	89 e5                	mov    %esp,%ebp
80105668:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
8010566b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105672:	e8 fa 04 00 00       	call   80105b71 <holding>
80105677:	85 c0                	test   %eax,%eax
80105679:	75 0c                	jne    80105687 <sched+0x22>
    panic("sched ptable.lock");
8010567b:	c7 04 24 c5 97 10 80 	movl   $0x801097c5,(%esp)
80105682:	e8 b6 ae ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105687:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010568d:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105693:	83 f8 01             	cmp    $0x1,%eax
80105696:	74 0c                	je     801056a4 <sched+0x3f>
    panic("sched locks");
80105698:	c7 04 24 d7 97 10 80 	movl   $0x801097d7,(%esp)
8010569f:	e8 99 ae ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801056a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056aa:	8b 40 0c             	mov    0xc(%eax),%eax
801056ad:	83 f8 04             	cmp    $0x4,%eax
801056b0:	75 0c                	jne    801056be <sched+0x59>
    panic("sched running");
801056b2:	c7 04 24 e3 97 10 80 	movl   $0x801097e3,(%esp)
801056b9:	e8 7f ae ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801056be:	e8 dd f7 ff ff       	call   80104ea0 <readeflags>
801056c3:	25 00 02 00 00       	and    $0x200,%eax
801056c8:	85 c0                	test   %eax,%eax
801056ca:	74 0c                	je     801056d8 <sched+0x73>
    panic("sched interruptible");
801056cc:	c7 04 24 f1 97 10 80 	movl   $0x801097f1,(%esp)
801056d3:	e8 65 ae ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801056d8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056de:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801056e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801056e7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056ed:	8b 40 04             	mov    0x4(%eax),%eax
801056f0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056f7:	83 c2 1c             	add    $0x1c,%edx
801056fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801056fe:	89 14 24             	mov    %edx,(%esp)
80105701:	e8 42 08 00 00       	call   80105f48 <swtch>
  cpu->intena = intena;
80105706:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010570c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010570f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105715:	c9                   	leave  
80105716:	c3                   	ret    

80105717 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105717:	55                   	push   %ebp
80105718:	89 e5                	mov    %esp,%ebp
8010571a:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010571d:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105724:	e8 2a 03 00 00       	call   80105a53 <acquire>
  proc->state = RUNNABLE;
80105729:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010572f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105736:	e8 2a ff ff ff       	call   80105665 <sched>
  release(&ptable.lock);
8010573b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105742:	e8 6e 03 00 00       	call   80105ab5 <release>
}
80105747:	c9                   	leave  
80105748:	c3                   	ret    

80105749 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105749:	55                   	push   %ebp
8010574a:	89 e5                	mov    %esp,%ebp
8010574c:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010574f:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105756:	e8 5a 03 00 00       	call   80105ab5 <release>

  if (first) {
8010575b:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105760:	85 c0                	test   %eax,%eax
80105762:	74 0f                	je     80105773 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105764:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
8010576b:	00 00 00 
    initlog();
8010576e:	e8 4d e7 ff ff       	call   80103ec0 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105773:	c9                   	leave  
80105774:	c3                   	ret    

80105775 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105775:	55                   	push   %ebp
80105776:	89 e5                	mov    %esp,%ebp
80105778:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
8010577b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105781:	85 c0                	test   %eax,%eax
80105783:	75 0c                	jne    80105791 <sleep+0x1c>
    panic("sleep");
80105785:	c7 04 24 05 98 10 80 	movl   $0x80109805,(%esp)
8010578c:	e8 ac ad ff ff       	call   8010053d <panic>

  if(lk == 0)
80105791:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105795:	75 0c                	jne    801057a3 <sleep+0x2e>
    panic("sleep without lk");
80105797:	c7 04 24 0b 98 10 80 	movl   $0x8010980b,(%esp)
8010579e:	e8 9a ad ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801057a3:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801057aa:	74 17                	je     801057c3 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801057ac:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801057b3:	e8 9b 02 00 00       	call   80105a53 <acquire>
    release(lk);
801057b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801057bb:	89 04 24             	mov    %eax,(%esp)
801057be:	e8 f2 02 00 00       	call   80105ab5 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801057c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057c9:	8b 55 08             	mov    0x8(%ebp),%edx
801057cc:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801057cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057d5:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801057dc:	e8 84 fe ff ff       	call   80105665 <sched>

  // Tidy up.
  proc->chan = 0;
801057e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057e7:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801057ee:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801057f5:	74 17                	je     8010580e <sleep+0x99>
    release(&ptable.lock);
801057f7:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801057fe:	e8 b2 02 00 00       	call   80105ab5 <release>
    acquire(lk);
80105803:	8b 45 0c             	mov    0xc(%ebp),%eax
80105806:	89 04 24             	mov    %eax,(%esp)
80105809:	e8 45 02 00 00       	call   80105a53 <acquire>
  }
}
8010580e:	c9                   	leave  
8010580f:	c3                   	ret    

80105810 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105810:	55                   	push   %ebp
80105811:	89 e5                	mov    %esp,%ebp
80105813:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105816:	c7 45 fc 74 0f 11 80 	movl   $0x80110f74,-0x4(%ebp)
8010581d:	eb 24                	jmp    80105843 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
8010581f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105822:	8b 40 0c             	mov    0xc(%eax),%eax
80105825:	83 f8 02             	cmp    $0x2,%eax
80105828:	75 15                	jne    8010583f <wakeup1+0x2f>
8010582a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010582d:	8b 40 20             	mov    0x20(%eax),%eax
80105830:	3b 45 08             	cmp    0x8(%ebp),%eax
80105833:	75 0a                	jne    8010583f <wakeup1+0x2f>
      p->state = RUNNABLE;
80105835:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105838:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010583f:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105843:	81 7d fc 74 2e 11 80 	cmpl   $0x80112e74,-0x4(%ebp)
8010584a:	72 d3                	jb     8010581f <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
8010584c:	c9                   	leave  
8010584d:	c3                   	ret    

8010584e <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010584e:	55                   	push   %ebp
8010584f:	89 e5                	mov    %esp,%ebp
80105851:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105854:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010585b:	e8 f3 01 00 00       	call   80105a53 <acquire>
  wakeup1(chan);
80105860:	8b 45 08             	mov    0x8(%ebp),%eax
80105863:	89 04 24             	mov    %eax,(%esp)
80105866:	e8 a5 ff ff ff       	call   80105810 <wakeup1>
  release(&ptable.lock);
8010586b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105872:	e8 3e 02 00 00       	call   80105ab5 <release>
}
80105877:	c9                   	leave  
80105878:	c3                   	ret    

80105879 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105879:	55                   	push   %ebp
8010587a:	89 e5                	mov    %esp,%ebp
8010587c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
8010587f:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105886:	e8 c8 01 00 00       	call   80105a53 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010588b:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80105892:	eb 41                	jmp    801058d5 <kill+0x5c>
    if(p->pid == pid){
80105894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105897:	8b 40 10             	mov    0x10(%eax),%eax
8010589a:	3b 45 08             	cmp    0x8(%ebp),%eax
8010589d:	75 32                	jne    801058d1 <kill+0x58>
      p->killed = 1;
8010589f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a2:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801058a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ac:	8b 40 0c             	mov    0xc(%eax),%eax
801058af:	83 f8 02             	cmp    $0x2,%eax
801058b2:	75 0a                	jne    801058be <kill+0x45>
        p->state = RUNNABLE;
801058b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
801058be:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801058c5:	e8 eb 01 00 00       	call   80105ab5 <release>
      return 0;
801058ca:	b8 00 00 00 00       	mov    $0x0,%eax
801058cf:	eb 1e                	jmp    801058ef <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058d1:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801058d5:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801058dc:	72 b6                	jb     80105894 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801058de:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801058e5:	e8 cb 01 00 00       	call   80105ab5 <release>
  return -1;
801058ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058ef:	c9                   	leave  
801058f0:	c3                   	ret    

801058f1 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801058f1:	55                   	push   %ebp
801058f2:	89 e5                	mov    %esp,%ebp
801058f4:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058f7:	c7 45 f0 74 0f 11 80 	movl   $0x80110f74,-0x10(%ebp)
801058fe:	e9 d8 00 00 00       	jmp    801059db <procdump+0xea>
    if(p->state == UNUSED)
80105903:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105906:	8b 40 0c             	mov    0xc(%eax),%eax
80105909:	85 c0                	test   %eax,%eax
8010590b:	0f 84 c5 00 00 00    	je     801059d6 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105911:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105914:	8b 40 0c             	mov    0xc(%eax),%eax
80105917:	83 f8 05             	cmp    $0x5,%eax
8010591a:	77 23                	ja     8010593f <procdump+0x4e>
8010591c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010591f:	8b 40 0c             	mov    0xc(%eax),%eax
80105922:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105929:	85 c0                	test   %eax,%eax
8010592b:	74 12                	je     8010593f <procdump+0x4e>
      state = states[p->state];
8010592d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105930:	8b 40 0c             	mov    0xc(%eax),%eax
80105933:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
8010593a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010593d:	eb 07                	jmp    80105946 <procdump+0x55>
    else
      state = "???";
8010593f:	c7 45 ec 1c 98 10 80 	movl   $0x8010981c,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105946:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105949:	8d 50 6c             	lea    0x6c(%eax),%edx
8010594c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010594f:	8b 40 10             	mov    0x10(%eax),%eax
80105952:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105956:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105959:	89 54 24 08          	mov    %edx,0x8(%esp)
8010595d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105961:	c7 04 24 20 98 10 80 	movl   $0x80109820,(%esp)
80105968:	e8 34 aa ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
8010596d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105970:	8b 40 0c             	mov    0xc(%eax),%eax
80105973:	83 f8 02             	cmp    $0x2,%eax
80105976:	75 50                	jne    801059c8 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105978:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010597b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010597e:	8b 40 0c             	mov    0xc(%eax),%eax
80105981:	83 c0 08             	add    $0x8,%eax
80105984:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105987:	89 54 24 04          	mov    %edx,0x4(%esp)
8010598b:	89 04 24             	mov    %eax,(%esp)
8010598e:	e8 71 01 00 00       	call   80105b04 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105993:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010599a:	eb 1b                	jmp    801059b7 <procdump+0xc6>
        cprintf(" %p", pc[i]);
8010599c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801059a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801059a7:	c7 04 24 29 98 10 80 	movl   $0x80109829,(%esp)
801059ae:	e8 ee a9 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801059b3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801059b7:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801059bb:	7f 0b                	jg     801059c8 <procdump+0xd7>
801059bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059c0:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801059c4:	85 c0                	test   %eax,%eax
801059c6:	75 d4                	jne    8010599c <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801059c8:	c7 04 24 2d 98 10 80 	movl   $0x8010982d,(%esp)
801059cf:	e8 cd a9 ff ff       	call   801003a1 <cprintf>
801059d4:	eb 01                	jmp    801059d7 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
801059d6:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059d7:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801059db:	81 7d f0 74 2e 11 80 	cmpl   $0x80112e74,-0x10(%ebp)
801059e2:	0f 82 1b ff ff ff    	jb     80105903 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801059e8:	c9                   	leave  
801059e9:	c3                   	ret    
	...

801059ec <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801059ec:	55                   	push   %ebp
801059ed:	89 e5                	mov    %esp,%ebp
801059ef:	53                   	push   %ebx
801059f0:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801059f3:	9c                   	pushf  
801059f4:	5b                   	pop    %ebx
801059f5:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801059f8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801059fb:	83 c4 10             	add    $0x10,%esp
801059fe:	5b                   	pop    %ebx
801059ff:	5d                   	pop    %ebp
80105a00:	c3                   	ret    

80105a01 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105a01:	55                   	push   %ebp
80105a02:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105a04:	fa                   	cli    
}
80105a05:	5d                   	pop    %ebp
80105a06:	c3                   	ret    

80105a07 <sti>:

static inline void
sti(void)
{
80105a07:	55                   	push   %ebp
80105a08:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105a0a:	fb                   	sti    
}
80105a0b:	5d                   	pop    %ebp
80105a0c:	c3                   	ret    

80105a0d <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105a0d:	55                   	push   %ebp
80105a0e:	89 e5                	mov    %esp,%ebp
80105a10:	53                   	push   %ebx
80105a11:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105a14:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105a17:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105a1a:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105a1d:	89 c3                	mov    %eax,%ebx
80105a1f:	89 d8                	mov    %ebx,%eax
80105a21:	f0 87 02             	lock xchg %eax,(%edx)
80105a24:	89 c3                	mov    %eax,%ebx
80105a26:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105a29:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105a2c:	83 c4 10             	add    $0x10,%esp
80105a2f:	5b                   	pop    %ebx
80105a30:	5d                   	pop    %ebp
80105a31:	c3                   	ret    

80105a32 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105a32:	55                   	push   %ebp
80105a33:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105a35:	8b 45 08             	mov    0x8(%ebp),%eax
80105a38:	8b 55 0c             	mov    0xc(%ebp),%edx
80105a3b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105a3e:	8b 45 08             	mov    0x8(%ebp),%eax
80105a41:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105a47:	8b 45 08             	mov    0x8(%ebp),%eax
80105a4a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105a51:	5d                   	pop    %ebp
80105a52:	c3                   	ret    

80105a53 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105a53:	55                   	push   %ebp
80105a54:	89 e5                	mov    %esp,%ebp
80105a56:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105a59:	e8 3d 01 00 00       	call   80105b9b <pushcli>
  if(holding(lk))
80105a5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105a61:	89 04 24             	mov    %eax,(%esp)
80105a64:	e8 08 01 00 00       	call   80105b71 <holding>
80105a69:	85 c0                	test   %eax,%eax
80105a6b:	74 0c                	je     80105a79 <acquire+0x26>
    panic("acquire");
80105a6d:	c7 04 24 59 98 10 80 	movl   $0x80109859,(%esp)
80105a74:	e8 c4 aa ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105a79:	90                   	nop
80105a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80105a7d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105a84:	00 
80105a85:	89 04 24             	mov    %eax,(%esp)
80105a88:	e8 80 ff ff ff       	call   80105a0d <xchg>
80105a8d:	85 c0                	test   %eax,%eax
80105a8f:	75 e9                	jne    80105a7a <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105a91:	8b 45 08             	mov    0x8(%ebp),%eax
80105a94:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105a9b:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105a9e:	8b 45 08             	mov    0x8(%ebp),%eax
80105aa1:	83 c0 0c             	add    $0xc,%eax
80105aa4:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aa8:	8d 45 08             	lea    0x8(%ebp),%eax
80105aab:	89 04 24             	mov    %eax,(%esp)
80105aae:	e8 51 00 00 00       	call   80105b04 <getcallerpcs>
}
80105ab3:	c9                   	leave  
80105ab4:	c3                   	ret    

80105ab5 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105ab5:	55                   	push   %ebp
80105ab6:	89 e5                	mov    %esp,%ebp
80105ab8:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105abb:	8b 45 08             	mov    0x8(%ebp),%eax
80105abe:	89 04 24             	mov    %eax,(%esp)
80105ac1:	e8 ab 00 00 00       	call   80105b71 <holding>
80105ac6:	85 c0                	test   %eax,%eax
80105ac8:	75 0c                	jne    80105ad6 <release+0x21>
    panic("release");
80105aca:	c7 04 24 61 98 10 80 	movl   $0x80109861,(%esp)
80105ad1:	e8 67 aa ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105ad6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ad9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae3:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105aea:	8b 45 08             	mov    0x8(%ebp),%eax
80105aed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105af4:	00 
80105af5:	89 04 24             	mov    %eax,(%esp)
80105af8:	e8 10 ff ff ff       	call   80105a0d <xchg>

  popcli();
80105afd:	e8 e1 00 00 00       	call   80105be3 <popcli>
}
80105b02:	c9                   	leave  
80105b03:	c3                   	ret    

80105b04 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105b04:	55                   	push   %ebp
80105b05:	89 e5                	mov    %esp,%ebp
80105b07:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80105b0d:	83 e8 08             	sub    $0x8,%eax
80105b10:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105b13:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105b1a:	eb 32                	jmp    80105b4e <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105b1c:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105b20:	74 47                	je     80105b69 <getcallerpcs+0x65>
80105b22:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105b29:	76 3e                	jbe    80105b69 <getcallerpcs+0x65>
80105b2b:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105b2f:	74 38                	je     80105b69 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105b31:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b34:	c1 e0 02             	shl    $0x2,%eax
80105b37:	03 45 0c             	add    0xc(%ebp),%eax
80105b3a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b3d:	8b 52 04             	mov    0x4(%edx),%edx
80105b40:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105b42:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b45:	8b 00                	mov    (%eax),%eax
80105b47:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105b4a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b4e:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b52:	7e c8                	jle    80105b1c <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b54:	eb 13                	jmp    80105b69 <getcallerpcs+0x65>
    pcs[i] = 0;
80105b56:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b59:	c1 e0 02             	shl    $0x2,%eax
80105b5c:	03 45 0c             	add    0xc(%ebp),%eax
80105b5f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b65:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b69:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b6d:	7e e7                	jle    80105b56 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105b6f:	c9                   	leave  
80105b70:	c3                   	ret    

80105b71 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105b71:	55                   	push   %ebp
80105b72:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105b74:	8b 45 08             	mov    0x8(%ebp),%eax
80105b77:	8b 00                	mov    (%eax),%eax
80105b79:	85 c0                	test   %eax,%eax
80105b7b:	74 17                	je     80105b94 <holding+0x23>
80105b7d:	8b 45 08             	mov    0x8(%ebp),%eax
80105b80:	8b 50 08             	mov    0x8(%eax),%edx
80105b83:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b89:	39 c2                	cmp    %eax,%edx
80105b8b:	75 07                	jne    80105b94 <holding+0x23>
80105b8d:	b8 01 00 00 00       	mov    $0x1,%eax
80105b92:	eb 05                	jmp    80105b99 <holding+0x28>
80105b94:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b99:	5d                   	pop    %ebp
80105b9a:	c3                   	ret    

80105b9b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105b9b:	55                   	push   %ebp
80105b9c:	89 e5                	mov    %esp,%ebp
80105b9e:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105ba1:	e8 46 fe ff ff       	call   801059ec <readeflags>
80105ba6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105ba9:	e8 53 fe ff ff       	call   80105a01 <cli>
  if(cpu->ncli++ == 0)
80105bae:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105bb4:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105bba:	85 d2                	test   %edx,%edx
80105bbc:	0f 94 c1             	sete   %cl
80105bbf:	83 c2 01             	add    $0x1,%edx
80105bc2:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105bc8:	84 c9                	test   %cl,%cl
80105bca:	74 15                	je     80105be1 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105bcc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105bd2:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bd5:	81 e2 00 02 00 00    	and    $0x200,%edx
80105bdb:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105be1:	c9                   	leave  
80105be2:	c3                   	ret    

80105be3 <popcli>:

void
popcli(void)
{
80105be3:	55                   	push   %ebp
80105be4:	89 e5                	mov    %esp,%ebp
80105be6:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105be9:	e8 fe fd ff ff       	call   801059ec <readeflags>
80105bee:	25 00 02 00 00       	and    $0x200,%eax
80105bf3:	85 c0                	test   %eax,%eax
80105bf5:	74 0c                	je     80105c03 <popcli+0x20>
    panic("popcli - interruptible");
80105bf7:	c7 04 24 69 98 10 80 	movl   $0x80109869,(%esp)
80105bfe:	e8 3a a9 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105c03:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c09:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105c0f:	83 ea 01             	sub    $0x1,%edx
80105c12:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105c18:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c1e:	85 c0                	test   %eax,%eax
80105c20:	79 0c                	jns    80105c2e <popcli+0x4b>
    panic("popcli");
80105c22:	c7 04 24 80 98 10 80 	movl   $0x80109880,(%esp)
80105c29:	e8 0f a9 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105c2e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c34:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c3a:	85 c0                	test   %eax,%eax
80105c3c:	75 15                	jne    80105c53 <popcli+0x70>
80105c3e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c44:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105c4a:	85 c0                	test   %eax,%eax
80105c4c:	74 05                	je     80105c53 <popcli+0x70>
    sti();
80105c4e:	e8 b4 fd ff ff       	call   80105a07 <sti>
}
80105c53:	c9                   	leave  
80105c54:	c3                   	ret    
80105c55:	00 00                	add    %al,(%eax)
	...

80105c58 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105c58:	55                   	push   %ebp
80105c59:	89 e5                	mov    %esp,%ebp
80105c5b:	57                   	push   %edi
80105c5c:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105c5d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c60:	8b 55 10             	mov    0x10(%ebp),%edx
80105c63:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c66:	89 cb                	mov    %ecx,%ebx
80105c68:	89 df                	mov    %ebx,%edi
80105c6a:	89 d1                	mov    %edx,%ecx
80105c6c:	fc                   	cld    
80105c6d:	f3 aa                	rep stos %al,%es:(%edi)
80105c6f:	89 ca                	mov    %ecx,%edx
80105c71:	89 fb                	mov    %edi,%ebx
80105c73:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c76:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c79:	5b                   	pop    %ebx
80105c7a:	5f                   	pop    %edi
80105c7b:	5d                   	pop    %ebp
80105c7c:	c3                   	ret    

80105c7d <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105c7d:	55                   	push   %ebp
80105c7e:	89 e5                	mov    %esp,%ebp
80105c80:	57                   	push   %edi
80105c81:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105c82:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c85:	8b 55 10             	mov    0x10(%ebp),%edx
80105c88:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c8b:	89 cb                	mov    %ecx,%ebx
80105c8d:	89 df                	mov    %ebx,%edi
80105c8f:	89 d1                	mov    %edx,%ecx
80105c91:	fc                   	cld    
80105c92:	f3 ab                	rep stos %eax,%es:(%edi)
80105c94:	89 ca                	mov    %ecx,%edx
80105c96:	89 fb                	mov    %edi,%ebx
80105c98:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c9b:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c9e:	5b                   	pop    %ebx
80105c9f:	5f                   	pop    %edi
80105ca0:	5d                   	pop    %ebp
80105ca1:	c3                   	ret    

80105ca2 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105ca2:	55                   	push   %ebp
80105ca3:	89 e5                	mov    %esp,%ebp
80105ca5:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105ca8:	8b 45 08             	mov    0x8(%ebp),%eax
80105cab:	83 e0 03             	and    $0x3,%eax
80105cae:	85 c0                	test   %eax,%eax
80105cb0:	75 49                	jne    80105cfb <memset+0x59>
80105cb2:	8b 45 10             	mov    0x10(%ebp),%eax
80105cb5:	83 e0 03             	and    $0x3,%eax
80105cb8:	85 c0                	test   %eax,%eax
80105cba:	75 3f                	jne    80105cfb <memset+0x59>
    c &= 0xFF;
80105cbc:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105cc3:	8b 45 10             	mov    0x10(%ebp),%eax
80105cc6:	c1 e8 02             	shr    $0x2,%eax
80105cc9:	89 c2                	mov    %eax,%edx
80105ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cce:	89 c1                	mov    %eax,%ecx
80105cd0:	c1 e1 18             	shl    $0x18,%ecx
80105cd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cd6:	c1 e0 10             	shl    $0x10,%eax
80105cd9:	09 c1                	or     %eax,%ecx
80105cdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cde:	c1 e0 08             	shl    $0x8,%eax
80105ce1:	09 c8                	or     %ecx,%eax
80105ce3:	0b 45 0c             	or     0xc(%ebp),%eax
80105ce6:	89 54 24 08          	mov    %edx,0x8(%esp)
80105cea:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cee:	8b 45 08             	mov    0x8(%ebp),%eax
80105cf1:	89 04 24             	mov    %eax,(%esp)
80105cf4:	e8 84 ff ff ff       	call   80105c7d <stosl>
80105cf9:	eb 19                	jmp    80105d14 <memset+0x72>
  } else
    stosb(dst, c, n);
80105cfb:	8b 45 10             	mov    0x10(%ebp),%eax
80105cfe:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d02:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d05:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d09:	8b 45 08             	mov    0x8(%ebp),%eax
80105d0c:	89 04 24             	mov    %eax,(%esp)
80105d0f:	e8 44 ff ff ff       	call   80105c58 <stosb>
  return dst;
80105d14:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105d17:	c9                   	leave  
80105d18:	c3                   	ret    

80105d19 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105d19:	55                   	push   %ebp
80105d1a:	89 e5                	mov    %esp,%ebp
80105d1c:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105d1f:	8b 45 08             	mov    0x8(%ebp),%eax
80105d22:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105d25:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d28:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105d2b:	eb 32                	jmp    80105d5f <memcmp+0x46>
    if(*s1 != *s2)
80105d2d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d30:	0f b6 10             	movzbl (%eax),%edx
80105d33:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d36:	0f b6 00             	movzbl (%eax),%eax
80105d39:	38 c2                	cmp    %al,%dl
80105d3b:	74 1a                	je     80105d57 <memcmp+0x3e>
      return *s1 - *s2;
80105d3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d40:	0f b6 00             	movzbl (%eax),%eax
80105d43:	0f b6 d0             	movzbl %al,%edx
80105d46:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d49:	0f b6 00             	movzbl (%eax),%eax
80105d4c:	0f b6 c0             	movzbl %al,%eax
80105d4f:	89 d1                	mov    %edx,%ecx
80105d51:	29 c1                	sub    %eax,%ecx
80105d53:	89 c8                	mov    %ecx,%eax
80105d55:	eb 1c                	jmp    80105d73 <memcmp+0x5a>
    s1++, s2++;
80105d57:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d5b:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105d5f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d63:	0f 95 c0             	setne  %al
80105d66:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105d6a:	84 c0                	test   %al,%al
80105d6c:	75 bf                	jne    80105d2d <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105d6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d73:	c9                   	leave  
80105d74:	c3                   	ret    

80105d75 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105d75:	55                   	push   %ebp
80105d76:	89 e5                	mov    %esp,%ebp
80105d78:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105d7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d7e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105d81:	8b 45 08             	mov    0x8(%ebp),%eax
80105d84:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105d87:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d8a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d8d:	73 54                	jae    80105de3 <memmove+0x6e>
80105d8f:	8b 45 10             	mov    0x10(%ebp),%eax
80105d92:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d95:	01 d0                	add    %edx,%eax
80105d97:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d9a:	76 47                	jbe    80105de3 <memmove+0x6e>
    s += n;
80105d9c:	8b 45 10             	mov    0x10(%ebp),%eax
80105d9f:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105da2:	8b 45 10             	mov    0x10(%ebp),%eax
80105da5:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105da8:	eb 13                	jmp    80105dbd <memmove+0x48>
      *--d = *--s;
80105daa:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105dae:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105db2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105db5:	0f b6 10             	movzbl (%eax),%edx
80105db8:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dbb:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105dbd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105dc1:	0f 95 c0             	setne  %al
80105dc4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105dc8:	84 c0                	test   %al,%al
80105dca:	75 de                	jne    80105daa <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105dcc:	eb 25                	jmp    80105df3 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105dce:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dd1:	0f b6 10             	movzbl (%eax),%edx
80105dd4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dd7:	88 10                	mov    %dl,(%eax)
80105dd9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ddd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105de1:	eb 01                	jmp    80105de4 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105de3:	90                   	nop
80105de4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105de8:	0f 95 c0             	setne  %al
80105deb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105def:	84 c0                	test   %al,%al
80105df1:	75 db                	jne    80105dce <memmove+0x59>
      *d++ = *s++;

  return dst;
80105df3:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105df6:	c9                   	leave  
80105df7:	c3                   	ret    

80105df8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105df8:	55                   	push   %ebp
80105df9:	89 e5                	mov    %esp,%ebp
80105dfb:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105dfe:	8b 45 10             	mov    0x10(%ebp),%eax
80105e01:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e05:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e08:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e0c:	8b 45 08             	mov    0x8(%ebp),%eax
80105e0f:	89 04 24             	mov    %eax,(%esp)
80105e12:	e8 5e ff ff ff       	call   80105d75 <memmove>
}
80105e17:	c9                   	leave  
80105e18:	c3                   	ret    

80105e19 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105e19:	55                   	push   %ebp
80105e1a:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105e1c:	eb 0c                	jmp    80105e2a <strncmp+0x11>
    n--, p++, q++;
80105e1e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105e22:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105e26:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105e2a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e2e:	74 1a                	je     80105e4a <strncmp+0x31>
80105e30:	8b 45 08             	mov    0x8(%ebp),%eax
80105e33:	0f b6 00             	movzbl (%eax),%eax
80105e36:	84 c0                	test   %al,%al
80105e38:	74 10                	je     80105e4a <strncmp+0x31>
80105e3a:	8b 45 08             	mov    0x8(%ebp),%eax
80105e3d:	0f b6 10             	movzbl (%eax),%edx
80105e40:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e43:	0f b6 00             	movzbl (%eax),%eax
80105e46:	38 c2                	cmp    %al,%dl
80105e48:	74 d4                	je     80105e1e <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105e4a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e4e:	75 07                	jne    80105e57 <strncmp+0x3e>
    return 0;
80105e50:	b8 00 00 00 00       	mov    $0x0,%eax
80105e55:	eb 18                	jmp    80105e6f <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105e57:	8b 45 08             	mov    0x8(%ebp),%eax
80105e5a:	0f b6 00             	movzbl (%eax),%eax
80105e5d:	0f b6 d0             	movzbl %al,%edx
80105e60:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e63:	0f b6 00             	movzbl (%eax),%eax
80105e66:	0f b6 c0             	movzbl %al,%eax
80105e69:	89 d1                	mov    %edx,%ecx
80105e6b:	29 c1                	sub    %eax,%ecx
80105e6d:	89 c8                	mov    %ecx,%eax
}
80105e6f:	5d                   	pop    %ebp
80105e70:	c3                   	ret    

80105e71 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105e71:	55                   	push   %ebp
80105e72:	89 e5                	mov    %esp,%ebp
80105e74:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105e77:	8b 45 08             	mov    0x8(%ebp),%eax
80105e7a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105e7d:	90                   	nop
80105e7e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e82:	0f 9f c0             	setg   %al
80105e85:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105e89:	84 c0                	test   %al,%al
80105e8b:	74 30                	je     80105ebd <strncpy+0x4c>
80105e8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e90:	0f b6 10             	movzbl (%eax),%edx
80105e93:	8b 45 08             	mov    0x8(%ebp),%eax
80105e96:	88 10                	mov    %dl,(%eax)
80105e98:	8b 45 08             	mov    0x8(%ebp),%eax
80105e9b:	0f b6 00             	movzbl (%eax),%eax
80105e9e:	84 c0                	test   %al,%al
80105ea0:	0f 95 c0             	setne  %al
80105ea3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105ea7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105eab:	84 c0                	test   %al,%al
80105ead:	75 cf                	jne    80105e7e <strncpy+0xd>
    ;
  while(n-- > 0)
80105eaf:	eb 0c                	jmp    80105ebd <strncpy+0x4c>
    *s++ = 0;
80105eb1:	8b 45 08             	mov    0x8(%ebp),%eax
80105eb4:	c6 00 00             	movb   $0x0,(%eax)
80105eb7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105ebb:	eb 01                	jmp    80105ebe <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105ebd:	90                   	nop
80105ebe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ec2:	0f 9f c0             	setg   %al
80105ec5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ec9:	84 c0                	test   %al,%al
80105ecb:	75 e4                	jne    80105eb1 <strncpy+0x40>
    *s++ = 0;
  return os;
80105ecd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ed0:	c9                   	leave  
80105ed1:	c3                   	ret    

80105ed2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105ed2:	55                   	push   %ebp
80105ed3:	89 e5                	mov    %esp,%ebp
80105ed5:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ed8:	8b 45 08             	mov    0x8(%ebp),%eax
80105edb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105ede:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ee2:	7f 05                	jg     80105ee9 <safestrcpy+0x17>
    return os;
80105ee4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105ee7:	eb 35                	jmp    80105f1e <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105ee9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105eed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ef1:	7e 22                	jle    80105f15 <safestrcpy+0x43>
80105ef3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ef6:	0f b6 10             	movzbl (%eax),%edx
80105ef9:	8b 45 08             	mov    0x8(%ebp),%eax
80105efc:	88 10                	mov    %dl,(%eax)
80105efe:	8b 45 08             	mov    0x8(%ebp),%eax
80105f01:	0f b6 00             	movzbl (%eax),%eax
80105f04:	84 c0                	test   %al,%al
80105f06:	0f 95 c0             	setne  %al
80105f09:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105f0d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105f11:	84 c0                	test   %al,%al
80105f13:	75 d4                	jne    80105ee9 <safestrcpy+0x17>
    ;
  *s = 0;
80105f15:	8b 45 08             	mov    0x8(%ebp),%eax
80105f18:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105f1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f1e:	c9                   	leave  
80105f1f:	c3                   	ret    

80105f20 <strlen>:

int
strlen(const char *s)
{
80105f20:	55                   	push   %ebp
80105f21:	89 e5                	mov    %esp,%ebp
80105f23:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105f26:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f2d:	eb 04                	jmp    80105f33 <strlen+0x13>
80105f2f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f33:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f36:	03 45 08             	add    0x8(%ebp),%eax
80105f39:	0f b6 00             	movzbl (%eax),%eax
80105f3c:	84 c0                	test   %al,%al
80105f3e:	75 ef                	jne    80105f2f <strlen+0xf>
    ;
  return n;
80105f40:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f43:	c9                   	leave  
80105f44:	c3                   	ret    
80105f45:	00 00                	add    %al,(%eax)
	...

80105f48 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105f48:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105f4c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105f50:	55                   	push   %ebp
  pushl %ebx
80105f51:	53                   	push   %ebx
  pushl %esi
80105f52:	56                   	push   %esi
  pushl %edi
80105f53:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105f54:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105f56:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105f58:	5f                   	pop    %edi
  popl %esi
80105f59:	5e                   	pop    %esi
  popl %ebx
80105f5a:	5b                   	pop    %ebx
  popl %ebp
80105f5b:	5d                   	pop    %ebp
  ret
80105f5c:	c3                   	ret    
80105f5d:	00 00                	add    %al,(%eax)
	...

80105f60 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105f60:	55                   	push   %ebp
80105f61:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105f63:	8b 45 08             	mov    0x8(%ebp),%eax
80105f66:	8b 00                	mov    (%eax),%eax
80105f68:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105f6b:	76 0f                	jbe    80105f7c <fetchint+0x1c>
80105f6d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f70:	8d 50 04             	lea    0x4(%eax),%edx
80105f73:	8b 45 08             	mov    0x8(%ebp),%eax
80105f76:	8b 00                	mov    (%eax),%eax
80105f78:	39 c2                	cmp    %eax,%edx
80105f7a:	76 07                	jbe    80105f83 <fetchint+0x23>
    return -1;
80105f7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f81:	eb 0f                	jmp    80105f92 <fetchint+0x32>
  *ip = *(int*)(addr);
80105f83:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f86:	8b 10                	mov    (%eax),%edx
80105f88:	8b 45 10             	mov    0x10(%ebp),%eax
80105f8b:	89 10                	mov    %edx,(%eax)
  return 0;
80105f8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f92:	5d                   	pop    %ebp
80105f93:	c3                   	ret    

80105f94 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105f94:	55                   	push   %ebp
80105f95:	89 e5                	mov    %esp,%ebp
80105f97:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80105f9d:	8b 00                	mov    (%eax),%eax
80105f9f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105fa2:	77 07                	ja     80105fab <fetchstr+0x17>
    return -1;
80105fa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa9:	eb 45                	jmp    80105ff0 <fetchstr+0x5c>
  *pp = (char*)addr;
80105fab:	8b 55 0c             	mov    0xc(%ebp),%edx
80105fae:	8b 45 10             	mov    0x10(%ebp),%eax
80105fb1:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105fb3:	8b 45 08             	mov    0x8(%ebp),%eax
80105fb6:	8b 00                	mov    (%eax),%eax
80105fb8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105fbb:	8b 45 10             	mov    0x10(%ebp),%eax
80105fbe:	8b 00                	mov    (%eax),%eax
80105fc0:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105fc3:	eb 1e                	jmp    80105fe3 <fetchstr+0x4f>
    if(*s == 0)
80105fc5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fc8:	0f b6 00             	movzbl (%eax),%eax
80105fcb:	84 c0                	test   %al,%al
80105fcd:	75 10                	jne    80105fdf <fetchstr+0x4b>
      return s - *pp;
80105fcf:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fd2:	8b 45 10             	mov    0x10(%ebp),%eax
80105fd5:	8b 00                	mov    (%eax),%eax
80105fd7:	89 d1                	mov    %edx,%ecx
80105fd9:	29 c1                	sub    %eax,%ecx
80105fdb:	89 c8                	mov    %ecx,%eax
80105fdd:	eb 11                	jmp    80105ff0 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105fdf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105fe3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fe6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fe9:	72 da                	jb     80105fc5 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105feb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ff0:	c9                   	leave  
80105ff1:	c3                   	ret    

80105ff2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105ff2:	55                   	push   %ebp
80105ff3:	89 e5                	mov    %esp,%ebp
80105ff5:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105ff8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ffe:	8b 40 18             	mov    0x18(%eax),%eax
80106001:	8b 50 44             	mov    0x44(%eax),%edx
80106004:	8b 45 08             	mov    0x8(%ebp),%eax
80106007:	c1 e0 02             	shl    $0x2,%eax
8010600a:	01 d0                	add    %edx,%eax
8010600c:	8d 48 04             	lea    0x4(%eax),%ecx
8010600f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106015:	8b 55 0c             	mov    0xc(%ebp),%edx
80106018:	89 54 24 08          	mov    %edx,0x8(%esp)
8010601c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106020:	89 04 24             	mov    %eax,(%esp)
80106023:	e8 38 ff ff ff       	call   80105f60 <fetchint>
}
80106028:	c9                   	leave  
80106029:	c3                   	ret    

8010602a <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010602a:	55                   	push   %ebp
8010602b:	89 e5                	mov    %esp,%ebp
8010602d:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106030:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106033:	89 44 24 04          	mov    %eax,0x4(%esp)
80106037:	8b 45 08             	mov    0x8(%ebp),%eax
8010603a:	89 04 24             	mov    %eax,(%esp)
8010603d:	e8 b0 ff ff ff       	call   80105ff2 <argint>
80106042:	85 c0                	test   %eax,%eax
80106044:	79 07                	jns    8010604d <argptr+0x23>
    return -1;
80106046:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010604b:	eb 3d                	jmp    8010608a <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
8010604d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106050:	89 c2                	mov    %eax,%edx
80106052:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106058:	8b 00                	mov    (%eax),%eax
8010605a:	39 c2                	cmp    %eax,%edx
8010605c:	73 16                	jae    80106074 <argptr+0x4a>
8010605e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106061:	89 c2                	mov    %eax,%edx
80106063:	8b 45 10             	mov    0x10(%ebp),%eax
80106066:	01 c2                	add    %eax,%edx
80106068:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010606e:	8b 00                	mov    (%eax),%eax
80106070:	39 c2                	cmp    %eax,%edx
80106072:	76 07                	jbe    8010607b <argptr+0x51>
    return -1;
80106074:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106079:	eb 0f                	jmp    8010608a <argptr+0x60>
  *pp = (char*)i;
8010607b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010607e:	89 c2                	mov    %eax,%edx
80106080:	8b 45 0c             	mov    0xc(%ebp),%eax
80106083:	89 10                	mov    %edx,(%eax)
  return 0;
80106085:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010608a:	c9                   	leave  
8010608b:	c3                   	ret    

8010608c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010608c:	55                   	push   %ebp
8010608d:	89 e5                	mov    %esp,%ebp
8010608f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106092:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106095:	89 44 24 04          	mov    %eax,0x4(%esp)
80106099:	8b 45 08             	mov    0x8(%ebp),%eax
8010609c:	89 04 24             	mov    %eax,(%esp)
8010609f:	e8 4e ff ff ff       	call   80105ff2 <argint>
801060a4:	85 c0                	test   %eax,%eax
801060a6:	79 07                	jns    801060af <argstr+0x23>
    return -1;
801060a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060ad:	eb 1e                	jmp    801060cd <argstr+0x41>
  return fetchstr(proc, addr, pp);
801060af:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060b2:	89 c2                	mov    %eax,%edx
801060b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801060bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801060c5:	89 04 24             	mov    %eax,(%esp)
801060c8:	e8 c7 fe ff ff       	call   80105f94 <fetchstr>
}
801060cd:	c9                   	leave  
801060ce:	c3                   	ret    

801060cf <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
801060cf:	55                   	push   %ebp
801060d0:	89 e5                	mov    %esp,%ebp
801060d2:	53                   	push   %ebx
801060d3:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801060d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060dc:	8b 40 18             	mov    0x18(%eax),%eax
801060df:	8b 40 1c             	mov    0x1c(%eax),%eax
801060e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801060e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060e9:	78 2e                	js     80106119 <syscall+0x4a>
801060eb:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801060ef:	7f 28                	jg     80106119 <syscall+0x4a>
801060f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060f4:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060fb:	85 c0                	test   %eax,%eax
801060fd:	74 1a                	je     80106119 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801060ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106105:	8b 58 18             	mov    0x18(%eax),%ebx
80106108:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010610b:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106112:	ff d0                	call   *%eax
80106114:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106117:	eb 73                	jmp    8010618c <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80106119:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
8010611d:	7e 30                	jle    8010614f <syscall+0x80>
8010611f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106122:	83 f8 19             	cmp    $0x19,%eax
80106125:	77 28                	ja     8010614f <syscall+0x80>
80106127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010612a:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106131:	85 c0                	test   %eax,%eax
80106133:	74 1a                	je     8010614f <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80106135:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010613b:	8b 58 18             	mov    0x18(%eax),%ebx
8010613e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106141:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106148:	ff d0                	call   *%eax
8010614a:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010614d:	eb 3d                	jmp    8010618c <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010614f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106155:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106158:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010615e:	8b 40 10             	mov    0x10(%eax),%eax
80106161:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106164:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106168:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010616c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106170:	c7 04 24 87 98 10 80 	movl   $0x80109887,(%esp)
80106177:	e8 25 a2 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
8010617c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106182:	8b 40 18             	mov    0x18(%eax),%eax
80106185:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010618c:	83 c4 24             	add    $0x24,%esp
8010618f:	5b                   	pop    %ebx
80106190:	5d                   	pop    %ebp
80106191:	c3                   	ret    
	...

80106194 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80106194:	55                   	push   %ebp
80106195:	89 e5                	mov    %esp,%ebp
80106197:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010619a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010619d:	89 44 24 04          	mov    %eax,0x4(%esp)
801061a1:	8b 45 08             	mov    0x8(%ebp),%eax
801061a4:	89 04 24             	mov    %eax,(%esp)
801061a7:	e8 46 fe ff ff       	call   80105ff2 <argint>
801061ac:	85 c0                	test   %eax,%eax
801061ae:	79 07                	jns    801061b7 <argfd+0x23>
    return -1;
801061b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061b5:	eb 50                	jmp    80106207 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801061b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061ba:	85 c0                	test   %eax,%eax
801061bc:	78 21                	js     801061df <argfd+0x4b>
801061be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061c1:	83 f8 0f             	cmp    $0xf,%eax
801061c4:	7f 19                	jg     801061df <argfd+0x4b>
801061c6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061cf:	83 c2 08             	add    $0x8,%edx
801061d2:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801061d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061d9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061dd:	75 07                	jne    801061e6 <argfd+0x52>
    return -1;
801061df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e4:	eb 21                	jmp    80106207 <argfd+0x73>
  if(pfd)
801061e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801061ea:	74 08                	je     801061f4 <argfd+0x60>
    *pfd = fd;
801061ec:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801061f2:	89 10                	mov    %edx,(%eax)
  if(pf)
801061f4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061f8:	74 08                	je     80106202 <argfd+0x6e>
    *pf = f;
801061fa:	8b 45 10             	mov    0x10(%ebp),%eax
801061fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106200:	89 10                	mov    %edx,(%eax)
  return 0;
80106202:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106207:	c9                   	leave  
80106208:	c3                   	ret    

80106209 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106209:	55                   	push   %ebp
8010620a:	89 e5                	mov    %esp,%ebp
8010620c:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010620f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106216:	eb 30                	jmp    80106248 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106218:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010621e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106221:	83 c2 08             	add    $0x8,%edx
80106224:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106228:	85 c0                	test   %eax,%eax
8010622a:	75 18                	jne    80106244 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010622c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106232:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106235:	8d 4a 08             	lea    0x8(%edx),%ecx
80106238:	8b 55 08             	mov    0x8(%ebp),%edx
8010623b:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010623f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106242:	eb 0f                	jmp    80106253 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106244:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106248:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010624c:	7e ca                	jle    80106218 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010624e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106253:	c9                   	leave  
80106254:	c3                   	ret    

80106255 <sys_dup>:

int
sys_dup(void)
{
80106255:	55                   	push   %ebp
80106256:	89 e5                	mov    %esp,%ebp
80106258:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010625b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010625e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106262:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106269:	00 
8010626a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106271:	e8 1e ff ff ff       	call   80106194 <argfd>
80106276:	85 c0                	test   %eax,%eax
80106278:	79 07                	jns    80106281 <sys_dup+0x2c>
    return -1;
8010627a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010627f:	eb 29                	jmp    801062aa <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106281:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106284:	89 04 24             	mov    %eax,(%esp)
80106287:	e8 7d ff ff ff       	call   80106209 <fdalloc>
8010628c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010628f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106293:	79 07                	jns    8010629c <sys_dup+0x47>
    return -1;
80106295:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010629a:	eb 0e                	jmp    801062aa <sys_dup+0x55>
  filedup(f);
8010629c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010629f:	89 04 24             	mov    %eax,(%esp)
801062a2:	e8 d5 ac ff ff       	call   80100f7c <filedup>
  return fd;
801062a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801062aa:	c9                   	leave  
801062ab:	c3                   	ret    

801062ac <sys_read>:

int
sys_read(void)
{
801062ac:	55                   	push   %ebp
801062ad:	89 e5                	mov    %esp,%ebp
801062af:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801062b2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801062b5:	89 44 24 08          	mov    %eax,0x8(%esp)
801062b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062c0:	00 
801062c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062c8:	e8 c7 fe ff ff       	call   80106194 <argfd>
801062cd:	85 c0                	test   %eax,%eax
801062cf:	78 35                	js     80106306 <sys_read+0x5a>
801062d1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801062d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801062d8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801062df:	e8 0e fd ff ff       	call   80105ff2 <argint>
801062e4:	85 c0                	test   %eax,%eax
801062e6:	78 1e                	js     80106306 <sys_read+0x5a>
801062e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801062ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801062f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062fd:	e8 28 fd ff ff       	call   8010602a <argptr>
80106302:	85 c0                	test   %eax,%eax
80106304:	79 07                	jns    8010630d <sys_read+0x61>
    return -1;
80106306:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010630b:	eb 19                	jmp    80106326 <sys_read+0x7a>
  return fileread(f, p, n);
8010630d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106310:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106313:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106316:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010631a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010631e:	89 04 24             	mov    %eax,(%esp)
80106321:	e8 c3 ad ff ff       	call   801010e9 <fileread>
}
80106326:	c9                   	leave  
80106327:	c3                   	ret    

80106328 <sys_write>:

int
sys_write(void)
{
80106328:	55                   	push   %ebp
80106329:	89 e5                	mov    %esp,%ebp
8010632b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010632e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106331:	89 44 24 08          	mov    %eax,0x8(%esp)
80106335:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010633c:	00 
8010633d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106344:	e8 4b fe ff ff       	call   80106194 <argfd>
80106349:	85 c0                	test   %eax,%eax
8010634b:	78 35                	js     80106382 <sys_write+0x5a>
8010634d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106350:	89 44 24 04          	mov    %eax,0x4(%esp)
80106354:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010635b:	e8 92 fc ff ff       	call   80105ff2 <argint>
80106360:	85 c0                	test   %eax,%eax
80106362:	78 1e                	js     80106382 <sys_write+0x5a>
80106364:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106367:	89 44 24 08          	mov    %eax,0x8(%esp)
8010636b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010636e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106372:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106379:	e8 ac fc ff ff       	call   8010602a <argptr>
8010637e:	85 c0                	test   %eax,%eax
80106380:	79 07                	jns    80106389 <sys_write+0x61>
    return -1;
80106382:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106387:	eb 19                	jmp    801063a2 <sys_write+0x7a>
  return filewrite(f, p, n);
80106389:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010638c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010638f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106392:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106396:	89 54 24 04          	mov    %edx,0x4(%esp)
8010639a:	89 04 24             	mov    %eax,(%esp)
8010639d:	e8 03 ae ff ff       	call   801011a5 <filewrite>
}
801063a2:	c9                   	leave  
801063a3:	c3                   	ret    

801063a4 <sys_close>:

int
sys_close(void)
{
801063a4:	55                   	push   %ebp
801063a5:	89 e5                	mov    %esp,%ebp
801063a7:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801063aa:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801063b1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801063b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063bf:	e8 d0 fd ff ff       	call   80106194 <argfd>
801063c4:	85 c0                	test   %eax,%eax
801063c6:	79 07                	jns    801063cf <sys_close+0x2b>
    return -1;
801063c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cd:	eb 24                	jmp    801063f3 <sys_close+0x4f>
  proc->ofile[fd] = 0;
801063cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063d8:	83 c2 08             	add    $0x8,%edx
801063db:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801063e2:	00 
  fileclose(f);
801063e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e6:	89 04 24             	mov    %eax,(%esp)
801063e9:	e8 d6 ab ff ff       	call   80100fc4 <fileclose>
  return 0;
801063ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063f3:	c9                   	leave  
801063f4:	c3                   	ret    

801063f5 <sys_fstat>:

int
sys_fstat(void)
{
801063f5:	55                   	push   %ebp
801063f6:	89 e5                	mov    %esp,%ebp
801063f8:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801063fb:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063fe:	89 44 24 08          	mov    %eax,0x8(%esp)
80106402:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106409:	00 
8010640a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106411:	e8 7e fd ff ff       	call   80106194 <argfd>
80106416:	85 c0                	test   %eax,%eax
80106418:	78 1f                	js     80106439 <sys_fstat+0x44>
8010641a:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106421:	00 
80106422:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106425:	89 44 24 04          	mov    %eax,0x4(%esp)
80106429:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106430:	e8 f5 fb ff ff       	call   8010602a <argptr>
80106435:	85 c0                	test   %eax,%eax
80106437:	79 07                	jns    80106440 <sys_fstat+0x4b>
    return -1;
80106439:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010643e:	eb 12                	jmp    80106452 <sys_fstat+0x5d>
  return filestat(f, st);
80106440:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106443:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106446:	89 54 24 04          	mov    %edx,0x4(%esp)
8010644a:	89 04 24             	mov    %eax,(%esp)
8010644d:	e8 48 ac ff ff       	call   8010109a <filestat>
}
80106452:	c9                   	leave  
80106453:	c3                   	ret    

80106454 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106454:	55                   	push   %ebp
80106455:	89 e5                	mov    %esp,%ebp
80106457:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010645a:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010645d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106461:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106468:	e8 1f fc ff ff       	call   8010608c <argstr>
8010646d:	85 c0                	test   %eax,%eax
8010646f:	78 17                	js     80106488 <sys_link+0x34>
80106471:	8d 45 dc             	lea    -0x24(%ebp),%eax
80106474:	89 44 24 04          	mov    %eax,0x4(%esp)
80106478:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010647f:	e8 08 fc ff ff       	call   8010608c <argstr>
80106484:	85 c0                	test   %eax,%eax
80106486:	79 0a                	jns    80106492 <sys_link+0x3e>
    return -1;
80106488:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648d:	e9 3c 01 00 00       	jmp    801065ce <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80106492:	8b 45 d8             	mov    -0x28(%ebp),%eax
80106495:	89 04 24             	mov    %eax,(%esp)
80106498:	e8 f9 ca ff ff       	call   80102f96 <namei>
8010649d:	89 45 f4             	mov    %eax,-0xc(%ebp)
801064a0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064a4:	75 0a                	jne    801064b0 <sys_link+0x5c>
    return -1;
801064a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064ab:	e9 1e 01 00 00       	jmp    801065ce <sys_link+0x17a>

  begin_trans();
801064b0:	e8 18 dc ff ff       	call   801040cd <begin_trans>

  ilock(ip);
801064b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b8:	89 04 24             	mov    %eax,(%esp)
801064bb:	e8 34 bf ff ff       	call   801023f4 <ilock>
  if(ip->type == T_DIR){
801064c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064c7:	66 83 f8 01          	cmp    $0x1,%ax
801064cb:	75 1a                	jne    801064e7 <sys_link+0x93>
    iunlockput(ip);
801064cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d0:	89 04 24             	mov    %eax,(%esp)
801064d3:	e8 a0 c1 ff ff       	call   80102678 <iunlockput>
    commit_trans();
801064d8:	e8 39 dc ff ff       	call   80104116 <commit_trans>
    return -1;
801064dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064e2:	e9 e7 00 00 00       	jmp    801065ce <sys_link+0x17a>
  }

  ip->nlink++;
801064e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ea:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064ee:	8d 50 01             	lea    0x1(%eax),%edx
801064f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f4:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064fb:	89 04 24             	mov    %eax,(%esp)
801064fe:	e8 35 bd ff ff       	call   80102238 <iupdate>
  iunlock(ip);
80106503:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106506:	89 04 24             	mov    %eax,(%esp)
80106509:	e8 34 c0 ff ff       	call   80102542 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010650e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106511:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106514:	89 54 24 04          	mov    %edx,0x4(%esp)
80106518:	89 04 24             	mov    %eax,(%esp)
8010651b:	e8 98 ca ff ff       	call   80102fb8 <nameiparent>
80106520:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106523:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106527:	74 68                	je     80106591 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106529:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010652c:	89 04 24             	mov    %eax,(%esp)
8010652f:	e8 c0 be ff ff       	call   801023f4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106534:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106537:	8b 10                	mov    (%eax),%edx
80106539:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010653c:	8b 00                	mov    (%eax),%eax
8010653e:	39 c2                	cmp    %eax,%edx
80106540:	75 20                	jne    80106562 <sys_link+0x10e>
80106542:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106545:	8b 40 04             	mov    0x4(%eax),%eax
80106548:	89 44 24 08          	mov    %eax,0x8(%esp)
8010654c:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010654f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106553:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106556:	89 04 24             	mov    %eax,(%esp)
80106559:	e8 77 c7 ff ff       	call   80102cd5 <dirlink>
8010655e:	85 c0                	test   %eax,%eax
80106560:	79 0d                	jns    8010656f <sys_link+0x11b>
    iunlockput(dp);
80106562:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106565:	89 04 24             	mov    %eax,(%esp)
80106568:	e8 0b c1 ff ff       	call   80102678 <iunlockput>
    goto bad;
8010656d:	eb 23                	jmp    80106592 <sys_link+0x13e>
  }
  iunlockput(dp);
8010656f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106572:	89 04 24             	mov    %eax,(%esp)
80106575:	e8 fe c0 ff ff       	call   80102678 <iunlockput>
  iput(ip);
8010657a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010657d:	89 04 24             	mov    %eax,(%esp)
80106580:	e8 22 c0 ff ff       	call   801025a7 <iput>

  commit_trans();
80106585:	e8 8c db ff ff       	call   80104116 <commit_trans>

  return 0;
8010658a:	b8 00 00 00 00       	mov    $0x0,%eax
8010658f:	eb 3d                	jmp    801065ce <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106591:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80106592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106595:	89 04 24             	mov    %eax,(%esp)
80106598:	e8 57 be ff ff       	call   801023f4 <ilock>
  ip->nlink--;
8010659d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801065a4:	8d 50 ff             	lea    -0x1(%eax),%edx
801065a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065aa:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801065ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b1:	89 04 24             	mov    %eax,(%esp)
801065b4:	e8 7f bc ff ff       	call   80102238 <iupdate>
  iunlockput(ip);
801065b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065bc:	89 04 24             	mov    %eax,(%esp)
801065bf:	e8 b4 c0 ff ff       	call   80102678 <iunlockput>
  commit_trans();
801065c4:	e8 4d db ff ff       	call   80104116 <commit_trans>
  return -1;
801065c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801065ce:	c9                   	leave  
801065cf:	c3                   	ret    

801065d0 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801065d0:	55                   	push   %ebp
801065d1:	89 e5                	mov    %esp,%ebp
801065d3:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801065d6:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801065dd:	eb 4b                	jmp    8010662a <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801065df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801065e9:	00 
801065ea:	89 44 24 08          	mov    %eax,0x8(%esp)
801065ee:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801065f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801065f5:	8b 45 08             	mov    0x8(%ebp),%eax
801065f8:	89 04 24             	mov    %eax,(%esp)
801065fb:	e8 ea c2 ff ff       	call   801028ea <readi>
80106600:	83 f8 10             	cmp    $0x10,%eax
80106603:	74 0c                	je     80106611 <isdirempty+0x41>
      panic("isdirempty: readi");
80106605:	c7 04 24 a3 98 10 80 	movl   $0x801098a3,(%esp)
8010660c:	e8 2c 9f ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106611:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106615:	66 85 c0             	test   %ax,%ax
80106618:	74 07                	je     80106621 <isdirempty+0x51>
      return 0;
8010661a:	b8 00 00 00 00       	mov    $0x0,%eax
8010661f:	eb 1b                	jmp    8010663c <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106624:	83 c0 10             	add    $0x10,%eax
80106627:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010662a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010662d:	8b 45 08             	mov    0x8(%ebp),%eax
80106630:	8b 40 18             	mov    0x18(%eax),%eax
80106633:	39 c2                	cmp    %eax,%edx
80106635:	72 a8                	jb     801065df <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106637:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010663c:	c9                   	leave  
8010663d:	c3                   	ret    

8010663e <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010663e:	55                   	push   %ebp
8010663f:	89 e5                	mov    %esp,%ebp
80106641:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106644:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106647:	89 44 24 04          	mov    %eax,0x4(%esp)
8010664b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106652:	e8 35 fa ff ff       	call   8010608c <argstr>
80106657:	85 c0                	test   %eax,%eax
80106659:	79 0a                	jns    80106665 <sys_unlink+0x27>
    return -1;
8010665b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106660:	e9 aa 01 00 00       	jmp    8010680f <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106665:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106668:	8d 55 d2             	lea    -0x2e(%ebp),%edx
8010666b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010666f:	89 04 24             	mov    %eax,(%esp)
80106672:	e8 41 c9 ff ff       	call   80102fb8 <nameiparent>
80106677:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010667a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010667e:	75 0a                	jne    8010668a <sys_unlink+0x4c>
    return -1;
80106680:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106685:	e9 85 01 00 00       	jmp    8010680f <sys_unlink+0x1d1>

  begin_trans();
8010668a:	e8 3e da ff ff       	call   801040cd <begin_trans>

  ilock(dp);
8010668f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106692:	89 04 24             	mov    %eax,(%esp)
80106695:	e8 5a bd ff ff       	call   801023f4 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010669a:	c7 44 24 04 b5 98 10 	movl   $0x801098b5,0x4(%esp)
801066a1:	80 
801066a2:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066a5:	89 04 24             	mov    %eax,(%esp)
801066a8:	e8 3e c5 ff ff       	call   80102beb <namecmp>
801066ad:	85 c0                	test   %eax,%eax
801066af:	0f 84 45 01 00 00    	je     801067fa <sys_unlink+0x1bc>
801066b5:	c7 44 24 04 b7 98 10 	movl   $0x801098b7,0x4(%esp)
801066bc:	80 
801066bd:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066c0:	89 04 24             	mov    %eax,(%esp)
801066c3:	e8 23 c5 ff ff       	call   80102beb <namecmp>
801066c8:	85 c0                	test   %eax,%eax
801066ca:	0f 84 2a 01 00 00    	je     801067fa <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801066d0:	8d 45 c8             	lea    -0x38(%ebp),%eax
801066d3:	89 44 24 08          	mov    %eax,0x8(%esp)
801066d7:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066da:	89 44 24 04          	mov    %eax,0x4(%esp)
801066de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e1:	89 04 24             	mov    %eax,(%esp)
801066e4:	e8 24 c5 ff ff       	call   80102c0d <dirlookup>
801066e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066f0:	0f 84 03 01 00 00    	je     801067f9 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801066f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066f9:	89 04 24             	mov    %eax,(%esp)
801066fc:	e8 f3 bc ff ff       	call   801023f4 <ilock>

  if(ip->nlink < 1)
80106701:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106704:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106708:	66 85 c0             	test   %ax,%ax
8010670b:	7f 0c                	jg     80106719 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
8010670d:	c7 04 24 ba 98 10 80 	movl   $0x801098ba,(%esp)
80106714:	e8 24 9e ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106719:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010671c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106720:	66 83 f8 01          	cmp    $0x1,%ax
80106724:	75 1f                	jne    80106745 <sys_unlink+0x107>
80106726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106729:	89 04 24             	mov    %eax,(%esp)
8010672c:	e8 9f fe ff ff       	call   801065d0 <isdirempty>
80106731:	85 c0                	test   %eax,%eax
80106733:	75 10                	jne    80106745 <sys_unlink+0x107>
    iunlockput(ip);
80106735:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106738:	89 04 24             	mov    %eax,(%esp)
8010673b:	e8 38 bf ff ff       	call   80102678 <iunlockput>
    goto bad;
80106740:	e9 b5 00 00 00       	jmp    801067fa <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106745:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010674c:	00 
8010674d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106754:	00 
80106755:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106758:	89 04 24             	mov    %eax,(%esp)
8010675b:	e8 42 f5 ff ff       	call   80105ca2 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106760:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106763:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010676a:	00 
8010676b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010676f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106772:	89 44 24 04          	mov    %eax,0x4(%esp)
80106776:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106779:	89 04 24             	mov    %eax,(%esp)
8010677c:	e8 d4 c2 ff ff       	call   80102a55 <writei>
80106781:	83 f8 10             	cmp    $0x10,%eax
80106784:	74 0c                	je     80106792 <sys_unlink+0x154>
    panic("unlink: writei");
80106786:	c7 04 24 cc 98 10 80 	movl   $0x801098cc,(%esp)
8010678d:	e8 ab 9d ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106792:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106795:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106799:	66 83 f8 01          	cmp    $0x1,%ax
8010679d:	75 1c                	jne    801067bb <sys_unlink+0x17d>
    dp->nlink--;
8010679f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067a6:	8d 50 ff             	lea    -0x1(%eax),%edx
801067a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ac:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801067b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b3:	89 04 24             	mov    %eax,(%esp)
801067b6:	e8 7d ba ff ff       	call   80102238 <iupdate>
  }
  iunlockput(dp);
801067bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067be:	89 04 24             	mov    %eax,(%esp)
801067c1:	e8 b2 be ff ff       	call   80102678 <iunlockput>

  ip->nlink--;
801067c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067c9:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067cd:	8d 50 ff             	lea    -0x1(%eax),%edx
801067d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067d3:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067da:	89 04 24             	mov    %eax,(%esp)
801067dd:	e8 56 ba ff ff       	call   80102238 <iupdate>
  iunlockput(ip);
801067e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067e5:	89 04 24             	mov    %eax,(%esp)
801067e8:	e8 8b be ff ff       	call   80102678 <iunlockput>

  commit_trans();
801067ed:	e8 24 d9 ff ff       	call   80104116 <commit_trans>

  return 0;
801067f2:	b8 00 00 00 00       	mov    $0x0,%eax
801067f7:	eb 16                	jmp    8010680f <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801067f9:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801067fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067fd:	89 04 24             	mov    %eax,(%esp)
80106800:	e8 73 be ff ff       	call   80102678 <iunlockput>
  commit_trans();
80106805:	e8 0c d9 ff ff       	call   80104116 <commit_trans>
  return -1;
8010680a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010680f:	c9                   	leave  
80106810:	c3                   	ret    

80106811 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106811:	55                   	push   %ebp
80106812:	89 e5                	mov    %esp,%ebp
80106814:	83 ec 48             	sub    $0x48,%esp
80106817:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010681a:	8b 55 10             	mov    0x10(%ebp),%edx
8010681d:	8b 45 14             	mov    0x14(%ebp),%eax
80106820:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106824:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106828:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010682c:	8d 45 de             	lea    -0x22(%ebp),%eax
8010682f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106833:	8b 45 08             	mov    0x8(%ebp),%eax
80106836:	89 04 24             	mov    %eax,(%esp)
80106839:	e8 7a c7 ff ff       	call   80102fb8 <nameiparent>
8010683e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106841:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106845:	75 0a                	jne    80106851 <create+0x40>
    return 0;
80106847:	b8 00 00 00 00       	mov    $0x0,%eax
8010684c:	e9 7e 01 00 00       	jmp    801069cf <create+0x1be>
  ilock(dp);
80106851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106854:	89 04 24             	mov    %eax,(%esp)
80106857:	e8 98 bb ff ff       	call   801023f4 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010685c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010685f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106863:	8d 45 de             	lea    -0x22(%ebp),%eax
80106866:	89 44 24 04          	mov    %eax,0x4(%esp)
8010686a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010686d:	89 04 24             	mov    %eax,(%esp)
80106870:	e8 98 c3 ff ff       	call   80102c0d <dirlookup>
80106875:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106878:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010687c:	74 47                	je     801068c5 <create+0xb4>
    iunlockput(dp);
8010687e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106881:	89 04 24             	mov    %eax,(%esp)
80106884:	e8 ef bd ff ff       	call   80102678 <iunlockput>
    ilock(ip);
80106889:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010688c:	89 04 24             	mov    %eax,(%esp)
8010688f:	e8 60 bb ff ff       	call   801023f4 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106894:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106899:	75 15                	jne    801068b0 <create+0x9f>
8010689b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010689e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068a2:	66 83 f8 02          	cmp    $0x2,%ax
801068a6:	75 08                	jne    801068b0 <create+0x9f>
      return ip;
801068a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ab:	e9 1f 01 00 00       	jmp    801069cf <create+0x1be>
    iunlockput(ip);
801068b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068b3:	89 04 24             	mov    %eax,(%esp)
801068b6:	e8 bd bd ff ff       	call   80102678 <iunlockput>
    return 0;
801068bb:	b8 00 00 00 00       	mov    $0x0,%eax
801068c0:	e9 0a 01 00 00       	jmp    801069cf <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801068c5:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801068c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068cc:	8b 00                	mov    (%eax),%eax
801068ce:	89 54 24 04          	mov    %edx,0x4(%esp)
801068d2:	89 04 24             	mov    %eax,(%esp)
801068d5:	e8 81 b8 ff ff       	call   8010215b <ialloc>
801068da:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068dd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068e1:	75 0c                	jne    801068ef <create+0xde>
    panic("create: ialloc");
801068e3:	c7 04 24 db 98 10 80 	movl   $0x801098db,(%esp)
801068ea:	e8 4e 9c ff ff       	call   8010053d <panic>

  ilock(ip);
801068ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068f2:	89 04 24             	mov    %eax,(%esp)
801068f5:	e8 fa ba ff ff       	call   801023f4 <ilock>
  ip->major = major;
801068fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068fd:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106901:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106905:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106908:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
8010690c:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106913:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106919:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010691c:	89 04 24             	mov    %eax,(%esp)
8010691f:	e8 14 b9 ff ff       	call   80102238 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106924:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106929:	75 6a                	jne    80106995 <create+0x184>
    dp->nlink++;  // for ".."
8010692b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010692e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106932:	8d 50 01             	lea    0x1(%eax),%edx
80106935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106938:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
8010693c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010693f:	89 04 24             	mov    %eax,(%esp)
80106942:	e8 f1 b8 ff ff       	call   80102238 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106947:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010694a:	8b 40 04             	mov    0x4(%eax),%eax
8010694d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106951:	c7 44 24 04 b5 98 10 	movl   $0x801098b5,0x4(%esp)
80106958:	80 
80106959:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010695c:	89 04 24             	mov    %eax,(%esp)
8010695f:	e8 71 c3 ff ff       	call   80102cd5 <dirlink>
80106964:	85 c0                	test   %eax,%eax
80106966:	78 21                	js     80106989 <create+0x178>
80106968:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010696b:	8b 40 04             	mov    0x4(%eax),%eax
8010696e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106972:	c7 44 24 04 b7 98 10 	movl   $0x801098b7,0x4(%esp)
80106979:	80 
8010697a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010697d:	89 04 24             	mov    %eax,(%esp)
80106980:	e8 50 c3 ff ff       	call   80102cd5 <dirlink>
80106985:	85 c0                	test   %eax,%eax
80106987:	79 0c                	jns    80106995 <create+0x184>
      panic("create dots");
80106989:	c7 04 24 ea 98 10 80 	movl   $0x801098ea,(%esp)
80106990:	e8 a8 9b ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106995:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106998:	8b 40 04             	mov    0x4(%eax),%eax
8010699b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010699f:	8d 45 de             	lea    -0x22(%ebp),%eax
801069a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801069a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a9:	89 04 24             	mov    %eax,(%esp)
801069ac:	e8 24 c3 ff ff       	call   80102cd5 <dirlink>
801069b1:	85 c0                	test   %eax,%eax
801069b3:	79 0c                	jns    801069c1 <create+0x1b0>
    panic("create: dirlink");
801069b5:	c7 04 24 f6 98 10 80 	movl   $0x801098f6,(%esp)
801069bc:	e8 7c 9b ff ff       	call   8010053d <panic>

  iunlockput(dp);
801069c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069c4:	89 04 24             	mov    %eax,(%esp)
801069c7:	e8 ac bc ff ff       	call   80102678 <iunlockput>

  return ip;
801069cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801069cf:	c9                   	leave  
801069d0:	c3                   	ret    

801069d1 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
801069d1:	55                   	push   %ebp
801069d2:	89 e5                	mov    %esp,%ebp
801069d4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
801069d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801069da:	25 00 02 00 00       	and    $0x200,%eax
801069df:	85 c0                	test   %eax,%eax
801069e1:	74 40                	je     80106a23 <fileopen+0x52>
    begin_trans();
801069e3:	e8 e5 d6 ff ff       	call   801040cd <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801069e8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801069ef:	00 
801069f0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069f7:	00 
801069f8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801069ff:	00 
80106a00:	8b 45 08             	mov    0x8(%ebp),%eax
80106a03:	89 04 24             	mov    %eax,(%esp)
80106a06:	e8 06 fe ff ff       	call   80106811 <create>
80106a0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106a0e:	e8 03 d7 ff ff       	call   80104116 <commit_trans>
    if(ip == 0)
80106a13:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a17:	75 5b                	jne    80106a74 <fileopen+0xa3>
      return 0;
80106a19:	b8 00 00 00 00       	mov    $0x0,%eax
80106a1e:	e9 e5 00 00 00       	jmp    80106b08 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106a23:	8b 45 08             	mov    0x8(%ebp),%eax
80106a26:	89 04 24             	mov    %eax,(%esp)
80106a29:	e8 68 c5 ff ff       	call   80102f96 <namei>
80106a2e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a31:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a35:	75 0a                	jne    80106a41 <fileopen+0x70>
      return 0;
80106a37:	b8 00 00 00 00       	mov    $0x0,%eax
80106a3c:	e9 c7 00 00 00       	jmp    80106b08 <fileopen+0x137>
    ilock(ip);
80106a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a44:	89 04 24             	mov    %eax,(%esp)
80106a47:	e8 a8 b9 ff ff       	call   801023f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a4f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a53:	66 83 f8 01          	cmp    $0x1,%ax
80106a57:	75 1b                	jne    80106a74 <fileopen+0xa3>
80106a59:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106a5d:	74 15                	je     80106a74 <fileopen+0xa3>
      iunlockput(ip);
80106a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a62:	89 04 24             	mov    %eax,(%esp)
80106a65:	e8 0e bc ff ff       	call   80102678 <iunlockput>
      return 0;
80106a6a:	b8 00 00 00 00       	mov    $0x0,%eax
80106a6f:	e9 94 00 00 00       	jmp    80106b08 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106a74:	e8 a3 a4 ff ff       	call   80100f1c <filealloc>
80106a79:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a7c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a80:	75 23                	jne    80106aa5 <fileopen+0xd4>
    if(f)
80106a82:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a86:	74 0b                	je     80106a93 <fileopen+0xc2>
      fileclose(f);
80106a88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a8b:	89 04 24             	mov    %eax,(%esp)
80106a8e:	e8 31 a5 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a96:	89 04 24             	mov    %eax,(%esp)
80106a99:	e8 da bb ff ff       	call   80102678 <iunlockput>
    return 0;
80106a9e:	b8 00 00 00 00       	mov    $0x0,%eax
80106aa3:	eb 63                	jmp    80106b08 <fileopen+0x137>
  }
  iunlock(ip);
80106aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa8:	89 04 24             	mov    %eax,(%esp)
80106aab:	e8 92 ba ff ff       	call   80102542 <iunlock>

  f->type = FD_INODE;
80106ab0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab3:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106ab9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106abc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106abf:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106ac2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac5:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106acc:	8b 45 0c             	mov    0xc(%ebp),%eax
80106acf:	83 e0 01             	and    $0x1,%eax
80106ad2:	85 c0                	test   %eax,%eax
80106ad4:	0f 94 c2             	sete   %dl
80106ad7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ada:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106add:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ae0:	83 e0 01             	and    $0x1,%eax
80106ae3:	84 c0                	test   %al,%al
80106ae5:	75 0a                	jne    80106af1 <fileopen+0x120>
80106ae7:	8b 45 0c             	mov    0xc(%ebp),%eax
80106aea:	83 e0 02             	and    $0x2,%eax
80106aed:	85 c0                	test   %eax,%eax
80106aef:	74 07                	je     80106af8 <fileopen+0x127>
80106af1:	b8 01 00 00 00       	mov    $0x1,%eax
80106af6:	eb 05                	jmp    80106afd <fileopen+0x12c>
80106af8:	b8 00 00 00 00       	mov    $0x0,%eax
80106afd:	89 c2                	mov    %eax,%edx
80106aff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b02:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106b05:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106b08:	c9                   	leave  
80106b09:	c3                   	ret    

80106b0a <sys_open>:

int
sys_open(void)
{
80106b0a:	55                   	push   %ebp
80106b0b:	89 e5                	mov    %esp,%ebp
80106b0d:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106b10:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b13:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b17:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b1e:	e8 69 f5 ff ff       	call   8010608c <argstr>
80106b23:	85 c0                	test   %eax,%eax
80106b25:	78 17                	js     80106b3e <sys_open+0x34>
80106b27:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b2e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b35:	e8 b8 f4 ff ff       	call   80105ff2 <argint>
80106b3a:	85 c0                	test   %eax,%eax
80106b3c:	79 0a                	jns    80106b48 <sys_open+0x3e>
    return -1;
80106b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b43:	e9 46 01 00 00       	jmp    80106c8e <sys_open+0x184>
  if(omode & O_CREATE){
80106b48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b4b:	25 00 02 00 00       	and    $0x200,%eax
80106b50:	85 c0                	test   %eax,%eax
80106b52:	74 40                	je     80106b94 <sys_open+0x8a>
    begin_trans();
80106b54:	e8 74 d5 ff ff       	call   801040cd <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106b59:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b5c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b63:	00 
80106b64:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b6b:	00 
80106b6c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106b73:	00 
80106b74:	89 04 24             	mov    %eax,(%esp)
80106b77:	e8 95 fc ff ff       	call   80106811 <create>
80106b7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106b7f:	e8 92 d5 ff ff       	call   80104116 <commit_trans>
    if(ip == 0)
80106b84:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b88:	75 5c                	jne    80106be6 <sys_open+0xdc>
      return -1;
80106b8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b8f:	e9 fa 00 00 00       	jmp    80106c8e <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106b94:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b97:	89 04 24             	mov    %eax,(%esp)
80106b9a:	e8 f7 c3 ff ff       	call   80102f96 <namei>
80106b9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ba2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106ba6:	75 0a                	jne    80106bb2 <sys_open+0xa8>
      return -1;
80106ba8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bad:	e9 dc 00 00 00       	jmp    80106c8e <sys_open+0x184>
    ilock(ip);
80106bb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb5:	89 04 24             	mov    %eax,(%esp)
80106bb8:	e8 37 b8 ff ff       	call   801023f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106bbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bc0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bc4:	66 83 f8 01          	cmp    $0x1,%ax
80106bc8:	75 1c                	jne    80106be6 <sys_open+0xdc>
80106bca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bcd:	85 c0                	test   %eax,%eax
80106bcf:	74 15                	je     80106be6 <sys_open+0xdc>
      iunlockput(ip);
80106bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd4:	89 04 24             	mov    %eax,(%esp)
80106bd7:	e8 9c ba ff ff       	call   80102678 <iunlockput>
      return -1;
80106bdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106be1:	e9 a8 00 00 00       	jmp    80106c8e <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106be6:	e8 31 a3 ff ff       	call   80100f1c <filealloc>
80106beb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bee:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bf2:	74 14                	je     80106c08 <sys_open+0xfe>
80106bf4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf7:	89 04 24             	mov    %eax,(%esp)
80106bfa:	e8 0a f6 ff ff       	call   80106209 <fdalloc>
80106bff:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106c02:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106c06:	79 23                	jns    80106c2b <sys_open+0x121>
    if(f)
80106c08:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c0c:	74 0b                	je     80106c19 <sys_open+0x10f>
      fileclose(f);
80106c0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c11:	89 04 24             	mov    %eax,(%esp)
80106c14:	e8 ab a3 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c1c:	89 04 24             	mov    %eax,(%esp)
80106c1f:	e8 54 ba ff ff       	call   80102678 <iunlockput>
    return -1;
80106c24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c29:	eb 63                	jmp    80106c8e <sys_open+0x184>
  }
  iunlock(ip);
80106c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c2e:	89 04 24             	mov    %eax,(%esp)
80106c31:	e8 0c b9 ff ff       	call   80102542 <iunlock>

  f->type = FD_INODE;
80106c36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c39:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106c3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c42:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c45:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106c48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c4b:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106c52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c55:	83 e0 01             	and    $0x1,%eax
80106c58:	85 c0                	test   %eax,%eax
80106c5a:	0f 94 c2             	sete   %dl
80106c5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c60:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106c63:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c66:	83 e0 01             	and    $0x1,%eax
80106c69:	84 c0                	test   %al,%al
80106c6b:	75 0a                	jne    80106c77 <sys_open+0x16d>
80106c6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c70:	83 e0 02             	and    $0x2,%eax
80106c73:	85 c0                	test   %eax,%eax
80106c75:	74 07                	je     80106c7e <sys_open+0x174>
80106c77:	b8 01 00 00 00       	mov    $0x1,%eax
80106c7c:	eb 05                	jmp    80106c83 <sys_open+0x179>
80106c7e:	b8 00 00 00 00       	mov    $0x0,%eax
80106c83:	89 c2                	mov    %eax,%edx
80106c85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c88:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106c8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106c8e:	c9                   	leave  
80106c8f:	c3                   	ret    

80106c90 <sys_mkdir>:

int
sys_mkdir(void)
{
80106c90:	55                   	push   %ebp
80106c91:	89 e5                	mov    %esp,%ebp
80106c93:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106c96:	e8 32 d4 ff ff       	call   801040cd <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106c9b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ca2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ca9:	e8 de f3 ff ff       	call   8010608c <argstr>
80106cae:	85 c0                	test   %eax,%eax
80106cb0:	78 2c                	js     80106cde <sys_mkdir+0x4e>
80106cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106cbc:	00 
80106cbd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106cc4:	00 
80106cc5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106ccc:	00 
80106ccd:	89 04 24             	mov    %eax,(%esp)
80106cd0:	e8 3c fb ff ff       	call   80106811 <create>
80106cd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cdc:	75 0c                	jne    80106cea <sys_mkdir+0x5a>
    commit_trans();
80106cde:	e8 33 d4 ff ff       	call   80104116 <commit_trans>
    return -1;
80106ce3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ce8:	eb 15                	jmp    80106cff <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ced:	89 04 24             	mov    %eax,(%esp)
80106cf0:	e8 83 b9 ff ff       	call   80102678 <iunlockput>
  commit_trans();
80106cf5:	e8 1c d4 ff ff       	call   80104116 <commit_trans>
  return 0;
80106cfa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106cff:	c9                   	leave  
80106d00:	c3                   	ret    

80106d01 <sys_mknod>:

int
sys_mknod(void)
{
80106d01:	55                   	push   %ebp
80106d02:	89 e5                	mov    %esp,%ebp
80106d04:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80106d07:	e8 c1 d3 ff ff       	call   801040cd <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80106d0c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106d0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d1a:	e8 6d f3 ff ff       	call   8010608c <argstr>
80106d1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d22:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d26:	78 5e                	js     80106d86 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106d28:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106d2b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d2f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d36:	e8 b7 f2 ff ff       	call   80105ff2 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106d3b:	85 c0                	test   %eax,%eax
80106d3d:	78 47                	js     80106d86 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d3f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106d42:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d46:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106d4d:	e8 a0 f2 ff ff       	call   80105ff2 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106d52:	85 c0                	test   %eax,%eax
80106d54:	78 30                	js     80106d86 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106d56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106d59:	0f bf c8             	movswl %ax,%ecx
80106d5c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106d5f:	0f bf d0             	movswl %ax,%edx
80106d62:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d65:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106d69:	89 54 24 08          	mov    %edx,0x8(%esp)
80106d6d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106d74:	00 
80106d75:	89 04 24             	mov    %eax,(%esp)
80106d78:	e8 94 fa ff ff       	call   80106811 <create>
80106d7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d84:	75 0c                	jne    80106d92 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106d86:	e8 8b d3 ff ff       	call   80104116 <commit_trans>
    return -1;
80106d8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d90:	eb 15                	jmp    80106da7 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106d92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d95:	89 04 24             	mov    %eax,(%esp)
80106d98:	e8 db b8 ff ff       	call   80102678 <iunlockput>
  commit_trans();
80106d9d:	e8 74 d3 ff ff       	call   80104116 <commit_trans>
  return 0;
80106da2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106da7:	c9                   	leave  
80106da8:	c3                   	ret    

80106da9 <sys_chdir>:

int
sys_chdir(void)
{
80106da9:	55                   	push   %ebp
80106daa:	89 e5                	mov    %esp,%ebp
80106dac:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106daf:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106db2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106db6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106dbd:	e8 ca f2 ff ff       	call   8010608c <argstr>
80106dc2:	85 c0                	test   %eax,%eax
80106dc4:	78 14                	js     80106dda <sys_chdir+0x31>
80106dc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dc9:	89 04 24             	mov    %eax,(%esp)
80106dcc:	e8 c5 c1 ff ff       	call   80102f96 <namei>
80106dd1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106dd4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106dd8:	75 07                	jne    80106de1 <sys_chdir+0x38>
    return -1;
80106dda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ddf:	eb 57                	jmp    80106e38 <sys_chdir+0x8f>
  ilock(ip);
80106de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106de4:	89 04 24             	mov    %eax,(%esp)
80106de7:	e8 08 b6 ff ff       	call   801023f4 <ilock>
  if(ip->type != T_DIR){
80106dec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106def:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106df3:	66 83 f8 01          	cmp    $0x1,%ax
80106df7:	74 12                	je     80106e0b <sys_chdir+0x62>
    iunlockput(ip);
80106df9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dfc:	89 04 24             	mov    %eax,(%esp)
80106dff:	e8 74 b8 ff ff       	call   80102678 <iunlockput>
    return -1;
80106e04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e09:	eb 2d                	jmp    80106e38 <sys_chdir+0x8f>
  }
  iunlock(ip);
80106e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e0e:	89 04 24             	mov    %eax,(%esp)
80106e11:	e8 2c b7 ff ff       	call   80102542 <iunlock>
  iput(proc->cwd);
80106e16:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e1c:	8b 40 68             	mov    0x68(%eax),%eax
80106e1f:	89 04 24             	mov    %eax,(%esp)
80106e22:	e8 80 b7 ff ff       	call   801025a7 <iput>
  proc->cwd = ip;
80106e27:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e30:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106e33:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e38:	c9                   	leave  
80106e39:	c3                   	ret    

80106e3a <sys_exec>:

int
sys_exec(void)
{
80106e3a:	55                   	push   %ebp
80106e3b:	89 e5                	mov    %esp,%ebp
80106e3d:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106e43:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106e46:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e51:	e8 36 f2 ff ff       	call   8010608c <argstr>
80106e56:	85 c0                	test   %eax,%eax
80106e58:	78 1a                	js     80106e74 <sys_exec+0x3a>
80106e5a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106e60:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e64:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e6b:	e8 82 f1 ff ff       	call   80105ff2 <argint>
80106e70:	85 c0                	test   %eax,%eax
80106e72:	79 0a                	jns    80106e7e <sys_exec+0x44>
    return -1;
80106e74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e79:	e9 e2 00 00 00       	jmp    80106f60 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106e7e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106e85:	00 
80106e86:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e8d:	00 
80106e8e:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106e94:	89 04 24             	mov    %eax,(%esp)
80106e97:	e8 06 ee ff ff       	call   80105ca2 <memset>
  for(i=0;; i++){
80106e9c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea6:	83 f8 1f             	cmp    $0x1f,%eax
80106ea9:	76 0a                	jbe    80106eb5 <sys_exec+0x7b>
      return -1;
80106eab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eb0:	e9 ab 00 00 00       	jmp    80106f60 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb8:	c1 e0 02             	shl    $0x2,%eax
80106ebb:	89 c2                	mov    %eax,%edx
80106ebd:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ec3:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106ec6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ecc:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106ed2:	89 54 24 08          	mov    %edx,0x8(%esp)
80106ed6:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106eda:	89 04 24             	mov    %eax,(%esp)
80106edd:	e8 7e f0 ff ff       	call   80105f60 <fetchint>
80106ee2:	85 c0                	test   %eax,%eax
80106ee4:	79 07                	jns    80106eed <sys_exec+0xb3>
      return -1;
80106ee6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106eeb:	eb 73                	jmp    80106f60 <sys_exec+0x126>
    if(uarg == 0){
80106eed:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106ef3:	85 c0                	test   %eax,%eax
80106ef5:	75 26                	jne    80106f1d <sys_exec+0xe3>
      argv[i] = 0;
80106ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106efa:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106f01:	00 00 00 00 
      break;
80106f05:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106f06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f09:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106f0f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f13:	89 04 24             	mov    %eax,(%esp)
80106f16:	e8 e1 9b ff ff       	call   80100afc <exec>
80106f1b:	eb 43                	jmp    80106f60 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f20:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106f27:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106f2d:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106f30:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106f36:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f3c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106f40:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f44:	89 04 24             	mov    %eax,(%esp)
80106f47:	e8 48 f0 ff ff       	call   80105f94 <fetchstr>
80106f4c:	85 c0                	test   %eax,%eax
80106f4e:	79 07                	jns    80106f57 <sys_exec+0x11d>
      return -1;
80106f50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f55:	eb 09                	jmp    80106f60 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106f57:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106f5b:	e9 43 ff ff ff       	jmp    80106ea3 <sys_exec+0x69>
  return exec(path, argv);
}
80106f60:	c9                   	leave  
80106f61:	c3                   	ret    

80106f62 <sys_pipe>:

int
sys_pipe(void)
{
80106f62:	55                   	push   %ebp
80106f63:	89 e5                	mov    %esp,%ebp
80106f65:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106f68:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106f6f:	00 
80106f70:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106f73:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f77:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f7e:	e8 a7 f0 ff ff       	call   8010602a <argptr>
80106f83:	85 c0                	test   %eax,%eax
80106f85:	79 0a                	jns    80106f91 <sys_pipe+0x2f>
    return -1;
80106f87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f8c:	e9 9b 00 00 00       	jmp    8010702c <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106f91:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f94:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f98:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f9b:	89 04 24             	mov    %eax,(%esp)
80106f9e:	e8 45 db ff ff       	call   80104ae8 <pipealloc>
80106fa3:	85 c0                	test   %eax,%eax
80106fa5:	79 07                	jns    80106fae <sys_pipe+0x4c>
    return -1;
80106fa7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fac:	eb 7e                	jmp    8010702c <sys_pipe+0xca>
  fd0 = -1;
80106fae:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106fb5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106fb8:	89 04 24             	mov    %eax,(%esp)
80106fbb:	e8 49 f2 ff ff       	call   80106209 <fdalloc>
80106fc0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fc3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fc7:	78 14                	js     80106fdd <sys_pipe+0x7b>
80106fc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fcc:	89 04 24             	mov    %eax,(%esp)
80106fcf:	e8 35 f2 ff ff       	call   80106209 <fdalloc>
80106fd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106fd7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fdb:	79 37                	jns    80107014 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106fdd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fe1:	78 14                	js     80106ff7 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106fe3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fe9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106fec:	83 c2 08             	add    $0x8,%edx
80106fef:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106ff6:	00 
    fileclose(rf);
80106ff7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ffa:	89 04 24             	mov    %eax,(%esp)
80106ffd:	e8 c2 9f ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107002:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107005:	89 04 24             	mov    %eax,(%esp)
80107008:	e8 b7 9f ff ff       	call   80100fc4 <fileclose>
    return -1;
8010700d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107012:	eb 18                	jmp    8010702c <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107014:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107017:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010701a:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010701c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010701f:	8d 50 04             	lea    0x4(%eax),%edx
80107022:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107025:	89 02                	mov    %eax,(%edx)
  return 0;
80107027:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010702c:	c9                   	leave  
8010702d:	c3                   	ret    
	...

80107030 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107030:	55                   	push   %ebp
80107031:	89 e5                	mov    %esp,%ebp
80107033:	83 ec 08             	sub    $0x8,%esp
  return fork();
80107036:	e8 67 e1 ff ff       	call   801051a2 <fork>
}
8010703b:	c9                   	leave  
8010703c:	c3                   	ret    

8010703d <sys_exit>:

int
sys_exit(void)
{
8010703d:	55                   	push   %ebp
8010703e:	89 e5                	mov    %esp,%ebp
80107040:	83 ec 08             	sub    $0x8,%esp
  exit();
80107043:	e8 bd e2 ff ff       	call   80105305 <exit>
  return 0;  // not reached
80107048:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010704d:	c9                   	leave  
8010704e:	c3                   	ret    

8010704f <sys_wait>:

int
sys_wait(void)
{
8010704f:	55                   	push   %ebp
80107050:	89 e5                	mov    %esp,%ebp
80107052:	83 ec 08             	sub    $0x8,%esp
  return wait();
80107055:	e8 c3 e3 ff ff       	call   8010541d <wait>
}
8010705a:	c9                   	leave  
8010705b:	c3                   	ret    

8010705c <sys_kill>:

int
sys_kill(void)
{
8010705c:	55                   	push   %ebp
8010705d:	89 e5                	mov    %esp,%ebp
8010705f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80107062:	8d 45 f4             	lea    -0xc(%ebp),%eax
80107065:	89 44 24 04          	mov    %eax,0x4(%esp)
80107069:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107070:	e8 7d ef ff ff       	call   80105ff2 <argint>
80107075:	85 c0                	test   %eax,%eax
80107077:	79 07                	jns    80107080 <sys_kill+0x24>
    return -1;
80107079:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010707e:	eb 0b                	jmp    8010708b <sys_kill+0x2f>
  return kill(pid);
80107080:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107083:	89 04 24             	mov    %eax,(%esp)
80107086:	e8 ee e7 ff ff       	call   80105879 <kill>
}
8010708b:	c9                   	leave  
8010708c:	c3                   	ret    

8010708d <sys_getpid>:

int
sys_getpid(void)
{
8010708d:	55                   	push   %ebp
8010708e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107090:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107096:	8b 40 10             	mov    0x10(%eax),%eax
}
80107099:	5d                   	pop    %ebp
8010709a:	c3                   	ret    

8010709b <sys_sbrk>:

int
sys_sbrk(void)
{
8010709b:	55                   	push   %ebp
8010709c:	89 e5                	mov    %esp,%ebp
8010709e:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801070a1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801070a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070af:	e8 3e ef ff ff       	call   80105ff2 <argint>
801070b4:	85 c0                	test   %eax,%eax
801070b6:	79 07                	jns    801070bf <sys_sbrk+0x24>
    return -1;
801070b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070bd:	eb 24                	jmp    801070e3 <sys_sbrk+0x48>
  addr = proc->sz;
801070bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070c5:	8b 00                	mov    (%eax),%eax
801070c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801070ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070cd:	89 04 24             	mov    %eax,(%esp)
801070d0:	e8 28 e0 ff ff       	call   801050fd <growproc>
801070d5:	85 c0                	test   %eax,%eax
801070d7:	79 07                	jns    801070e0 <sys_sbrk+0x45>
    return -1;
801070d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070de:	eb 03                	jmp    801070e3 <sys_sbrk+0x48>
  return addr;
801070e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801070e3:	c9                   	leave  
801070e4:	c3                   	ret    

801070e5 <sys_sleep>:

int
sys_sleep(void)
{
801070e5:	55                   	push   %ebp
801070e6:	89 e5                	mov    %esp,%ebp
801070e8:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801070eb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801070f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070f9:	e8 f4 ee ff ff       	call   80105ff2 <argint>
801070fe:	85 c0                	test   %eax,%eax
80107100:	79 07                	jns    80107109 <sys_sleep+0x24>
    return -1;
80107102:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107107:	eb 6c                	jmp    80107175 <sys_sleep+0x90>
  acquire(&tickslock);
80107109:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107110:	e8 3e e9 ff ff       	call   80105a53 <acquire>
  ticks0 = ticks;
80107115:	a1 c0 36 11 80       	mov    0x801136c0,%eax
8010711a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010711d:	eb 34                	jmp    80107153 <sys_sleep+0x6e>
    if(proc->killed){
8010711f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107125:	8b 40 24             	mov    0x24(%eax),%eax
80107128:	85 c0                	test   %eax,%eax
8010712a:	74 13                	je     8010713f <sys_sleep+0x5a>
      release(&tickslock);
8010712c:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107133:	e8 7d e9 ff ff       	call   80105ab5 <release>
      return -1;
80107138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010713d:	eb 36                	jmp    80107175 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010713f:	c7 44 24 04 80 2e 11 	movl   $0x80112e80,0x4(%esp)
80107146:	80 
80107147:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
8010714e:	e8 22 e6 ff ff       	call   80105775 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80107153:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80107158:	89 c2                	mov    %eax,%edx
8010715a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010715d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107160:	39 c2                	cmp    %eax,%edx
80107162:	72 bb                	jb     8010711f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80107164:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
8010716b:	e8 45 e9 ff ff       	call   80105ab5 <release>
  return 0;
80107170:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107175:	c9                   	leave  
80107176:	c3                   	ret    

80107177 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80107177:	55                   	push   %ebp
80107178:	89 e5                	mov    %esp,%ebp
8010717a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010717d:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107184:	e8 ca e8 ff ff       	call   80105a53 <acquire>
  xticks = ticks;
80107189:	a1 c0 36 11 80       	mov    0x801136c0,%eax
8010718e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107191:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107198:	e8 18 e9 ff ff       	call   80105ab5 <release>
  return xticks;
8010719d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801071a0:	c9                   	leave  
801071a1:	c3                   	ret    

801071a2 <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
801071a2:	55                   	push   %ebp
801071a3:	89 e5                	mov    %esp,%ebp
801071a5:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
801071a8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801071ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801071af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071b6:	e8 d1 ee ff ff       	call   8010608c <argstr>
801071bb:	85 c0                	test   %eax,%eax
801071bd:	79 07                	jns    801071c6 <sys_getFileBlocks+0x24>
    return -1;
801071bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071c4:	eb 0b                	jmp    801071d1 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
801071c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071c9:	89 04 24             	mov    %eax,(%esp)
801071cc:	e8 19 a1 ff ff       	call   801012ea <getFileBlocks>
}
801071d1:	c9                   	leave  
801071d2:	c3                   	ret    

801071d3 <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
801071d3:	55                   	push   %ebp
801071d4:	89 e5                	mov    %esp,%ebp
801071d6:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
801071d9:	e8 69 a2 ff ff       	call   80101447 <getFreeBlocks>
}
801071de:	c9                   	leave  
801071df:	c3                   	ret    

801071e0 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
801071e0:	55                   	push   %ebp
801071e1:	89 e5                	mov    %esp,%ebp
  return 0;
801071e3:	b8 00 00 00 00       	mov    $0x0,%eax
  
}
801071e8:	5d                   	pop    %ebp
801071e9:	c3                   	ret    

801071ea <sys_dedup>:

int
sys_dedup(void)
{
801071ea:	55                   	push   %ebp
801071eb:	89 e5                	mov    %esp,%ebp
801071ed:	83 ec 08             	sub    $0x8,%esp
  return dedup();
801071f0:	e8 7f a4 ff ff       	call   80101674 <dedup>
}
801071f5:	c9                   	leave  
801071f6:	c3                   	ret    
	...

801071f8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801071f8:	55                   	push   %ebp
801071f9:	89 e5                	mov    %esp,%ebp
801071fb:	83 ec 08             	sub    $0x8,%esp
801071fe:	8b 55 08             	mov    0x8(%ebp),%edx
80107201:	8b 45 0c             	mov    0xc(%ebp),%eax
80107204:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107208:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010720b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010720f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107213:	ee                   	out    %al,(%dx)
}
80107214:	c9                   	leave  
80107215:	c3                   	ret    

80107216 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80107216:	55                   	push   %ebp
80107217:	89 e5                	mov    %esp,%ebp
80107219:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010721c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80107223:	00 
80107224:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010722b:	e8 c8 ff ff ff       	call   801071f8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107230:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107237:	00 
80107238:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010723f:	e8 b4 ff ff ff       	call   801071f8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107244:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010724b:	00 
8010724c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107253:	e8 a0 ff ff ff       	call   801071f8 <outb>
  picenable(IRQ_TIMER);
80107258:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010725f:	e8 0d d7 ff ff       	call   80104971 <picenable>
}
80107264:	c9                   	leave  
80107265:	c3                   	ret    
	...

80107268 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107268:	1e                   	push   %ds
  pushl %es
80107269:	06                   	push   %es
  pushl %fs
8010726a:	0f a0                	push   %fs
  pushl %gs
8010726c:	0f a8                	push   %gs
  pushal
8010726e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010726f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80107273:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80107275:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80107277:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010727b:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010727d:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010727f:	54                   	push   %esp
  call trap
80107280:	e8 de 01 00 00       	call   80107463 <trap>
  addl $4, %esp
80107285:	83 c4 04             	add    $0x4,%esp

80107288 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107288:	61                   	popa   
  popl %gs
80107289:	0f a9                	pop    %gs
  popl %fs
8010728b:	0f a1                	pop    %fs
  popl %es
8010728d:	07                   	pop    %es
  popl %ds
8010728e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010728f:	83 c4 08             	add    $0x8,%esp
  iret
80107292:	cf                   	iret   
	...

80107294 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80107294:	55                   	push   %ebp
80107295:	89 e5                	mov    %esp,%ebp
80107297:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010729a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010729d:	83 e8 01             	sub    $0x1,%eax
801072a0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801072a4:	8b 45 08             	mov    0x8(%ebp),%eax
801072a7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801072ab:	8b 45 08             	mov    0x8(%ebp),%eax
801072ae:	c1 e8 10             	shr    $0x10,%eax
801072b1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801072b5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801072b8:	0f 01 18             	lidtl  (%eax)
}
801072bb:	c9                   	leave  
801072bc:	c3                   	ret    

801072bd <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801072bd:	55                   	push   %ebp
801072be:	89 e5                	mov    %esp,%ebp
801072c0:	53                   	push   %ebx
801072c1:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801072c4:	0f 20 d3             	mov    %cr2,%ebx
801072c7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801072ca:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801072cd:	83 c4 10             	add    $0x10,%esp
801072d0:	5b                   	pop    %ebx
801072d1:	5d                   	pop    %ebp
801072d2:	c3                   	ret    

801072d3 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801072d3:	55                   	push   %ebp
801072d4:	89 e5                	mov    %esp,%ebp
801072d6:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801072d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801072e0:	e9 c3 00 00 00       	jmp    801073a8 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801072e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072e8:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
801072ef:	89 c2                	mov    %eax,%edx
801072f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072f4:	66 89 14 c5 c0 2e 11 	mov    %dx,-0x7feed140(,%eax,8)
801072fb:	80 
801072fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072ff:	66 c7 04 c5 c2 2e 11 	movw   $0x8,-0x7feed13e(,%eax,8)
80107306:	80 08 00 
80107309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010730c:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80107313:	80 
80107314:	83 e2 e0             	and    $0xffffffe0,%edx
80107317:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
8010731e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107321:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80107328:	80 
80107329:	83 e2 1f             	and    $0x1f,%edx
8010732c:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80107333:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107336:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
8010733d:	80 
8010733e:	83 e2 f0             	and    $0xfffffff0,%edx
80107341:	83 ca 0e             	or     $0xe,%edx
80107344:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
8010734b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010734e:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107355:	80 
80107356:	83 e2 ef             	and    $0xffffffef,%edx
80107359:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107363:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
8010736a:	80 
8010736b:	83 e2 9f             	and    $0xffffff9f,%edx
8010736e:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107375:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107378:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
8010737f:	80 
80107380:	83 ca 80             	or     $0xffffff80,%edx
80107383:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
8010738a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010738d:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80107394:	c1 e8 10             	shr    $0x10,%eax
80107397:	89 c2                	mov    %eax,%edx
80107399:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010739c:	66 89 14 c5 c6 2e 11 	mov    %dx,-0x7feed13a(,%eax,8)
801073a3:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801073a4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801073a8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801073af:	0f 8e 30 ff ff ff    	jle    801072e5 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801073b5:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
801073ba:	66 a3 c0 30 11 80    	mov    %ax,0x801130c0
801073c0:	66 c7 05 c2 30 11 80 	movw   $0x8,0x801130c2
801073c7:	08 00 
801073c9:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801073d0:	83 e0 e0             	and    $0xffffffe0,%eax
801073d3:	a2 c4 30 11 80       	mov    %al,0x801130c4
801073d8:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801073df:	83 e0 1f             	and    $0x1f,%eax
801073e2:	a2 c4 30 11 80       	mov    %al,0x801130c4
801073e7:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801073ee:	83 c8 0f             	or     $0xf,%eax
801073f1:	a2 c5 30 11 80       	mov    %al,0x801130c5
801073f6:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801073fd:	83 e0 ef             	and    $0xffffffef,%eax
80107400:	a2 c5 30 11 80       	mov    %al,0x801130c5
80107405:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
8010740c:	83 c8 60             	or     $0x60,%eax
8010740f:	a2 c5 30 11 80       	mov    %al,0x801130c5
80107414:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
8010741b:	83 c8 80             	or     $0xffffff80,%eax
8010741e:	a2 c5 30 11 80       	mov    %al,0x801130c5
80107423:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107428:	c1 e8 10             	shr    $0x10,%eax
8010742b:	66 a3 c6 30 11 80    	mov    %ax,0x801130c6
  
  initlock(&tickslock, "time");
80107431:	c7 44 24 04 08 99 10 	movl   $0x80109908,0x4(%esp)
80107438:	80 
80107439:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107440:	e8 ed e5 ff ff       	call   80105a32 <initlock>
}
80107445:	c9                   	leave  
80107446:	c3                   	ret    

80107447 <idtinit>:

void
idtinit(void)
{
80107447:	55                   	push   %ebp
80107448:	89 e5                	mov    %esp,%ebp
8010744a:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
8010744d:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107454:	00 
80107455:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
8010745c:	e8 33 fe ff ff       	call   80107294 <lidt>
}
80107461:	c9                   	leave  
80107462:	c3                   	ret    

80107463 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80107463:	55                   	push   %ebp
80107464:	89 e5                	mov    %esp,%ebp
80107466:	57                   	push   %edi
80107467:	56                   	push   %esi
80107468:	53                   	push   %ebx
80107469:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010746c:	8b 45 08             	mov    0x8(%ebp),%eax
8010746f:	8b 40 30             	mov    0x30(%eax),%eax
80107472:	83 f8 40             	cmp    $0x40,%eax
80107475:	75 3e                	jne    801074b5 <trap+0x52>
    if(proc->killed)
80107477:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010747d:	8b 40 24             	mov    0x24(%eax),%eax
80107480:	85 c0                	test   %eax,%eax
80107482:	74 05                	je     80107489 <trap+0x26>
      exit();
80107484:	e8 7c de ff ff       	call   80105305 <exit>
    proc->tf = tf;
80107489:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010748f:	8b 55 08             	mov    0x8(%ebp),%edx
80107492:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80107495:	e8 35 ec ff ff       	call   801060cf <syscall>
    if(proc->killed)
8010749a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074a0:	8b 40 24             	mov    0x24(%eax),%eax
801074a3:	85 c0                	test   %eax,%eax
801074a5:	0f 84 34 02 00 00    	je     801076df <trap+0x27c>
      exit();
801074ab:	e8 55 de ff ff       	call   80105305 <exit>
    return;
801074b0:	e9 2a 02 00 00       	jmp    801076df <trap+0x27c>
  }

  switch(tf->trapno){
801074b5:	8b 45 08             	mov    0x8(%ebp),%eax
801074b8:	8b 40 30             	mov    0x30(%eax),%eax
801074bb:	83 e8 20             	sub    $0x20,%eax
801074be:	83 f8 1f             	cmp    $0x1f,%eax
801074c1:	0f 87 bc 00 00 00    	ja     80107583 <trap+0x120>
801074c7:	8b 04 85 b0 99 10 80 	mov    -0x7fef6650(,%eax,4),%eax
801074ce:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801074d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801074d6:	0f b6 00             	movzbl (%eax),%eax
801074d9:	84 c0                	test   %al,%al
801074db:	75 31                	jne    8010750e <trap+0xab>
      acquire(&tickslock);
801074dd:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801074e4:	e8 6a e5 ff ff       	call   80105a53 <acquire>
      ticks++;
801074e9:	a1 c0 36 11 80       	mov    0x801136c0,%eax
801074ee:	83 c0 01             	add    $0x1,%eax
801074f1:	a3 c0 36 11 80       	mov    %eax,0x801136c0
      wakeup(&ticks);
801074f6:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
801074fd:	e8 4c e3 ff ff       	call   8010584e <wakeup>
      release(&tickslock);
80107502:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107509:	e8 a7 e5 ff ff       	call   80105ab5 <release>
    }
    lapiceoi();
8010750e:	e8 86 c8 ff ff       	call   80103d99 <lapiceoi>
    break;
80107513:	e9 41 01 00 00       	jmp    80107659 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107518:	e8 84 c0 ff ff       	call   801035a1 <ideintr>
    lapiceoi();
8010751d:	e8 77 c8 ff ff       	call   80103d99 <lapiceoi>
    break;
80107522:	e9 32 01 00 00       	jmp    80107659 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107527:	e8 4b c6 ff ff       	call   80103b77 <kbdintr>
    lapiceoi();
8010752c:	e8 68 c8 ff ff       	call   80103d99 <lapiceoi>
    break;
80107531:	e9 23 01 00 00       	jmp    80107659 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107536:	e8 a9 03 00 00       	call   801078e4 <uartintr>
    lapiceoi();
8010753b:	e8 59 c8 ff ff       	call   80103d99 <lapiceoi>
    break;
80107540:	e9 14 01 00 00       	jmp    80107659 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107545:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107548:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
8010754b:	8b 45 08             	mov    0x8(%ebp),%eax
8010754e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107552:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107555:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010755b:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010755e:	0f b6 c0             	movzbl %al,%eax
80107561:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107565:	89 54 24 08          	mov    %edx,0x8(%esp)
80107569:	89 44 24 04          	mov    %eax,0x4(%esp)
8010756d:	c7 04 24 10 99 10 80 	movl   $0x80109910,(%esp)
80107574:	e8 28 8e ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107579:	e8 1b c8 ff ff       	call   80103d99 <lapiceoi>
    break;
8010757e:	e9 d6 00 00 00       	jmp    80107659 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80107583:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107589:	85 c0                	test   %eax,%eax
8010758b:	74 11                	je     8010759e <trap+0x13b>
8010758d:	8b 45 08             	mov    0x8(%ebp),%eax
80107590:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107594:	0f b7 c0             	movzwl %ax,%eax
80107597:	83 e0 03             	and    $0x3,%eax
8010759a:	85 c0                	test   %eax,%eax
8010759c:	75 46                	jne    801075e4 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010759e:	e8 1a fd ff ff       	call   801072bd <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801075a3:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075a6:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801075a9:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801075b0:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075b3:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801075b6:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075b9:	8b 52 30             	mov    0x30(%edx),%edx
801075bc:	89 44 24 10          	mov    %eax,0x10(%esp)
801075c0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801075c4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801075c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801075cc:	c7 04 24 34 99 10 80 	movl   $0x80109934,(%esp)
801075d3:	e8 c9 8d ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801075d8:	c7 04 24 66 99 10 80 	movl   $0x80109966,(%esp)
801075df:	e8 59 8f ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075e4:	e8 d4 fc ff ff       	call   801072bd <rcr2>
801075e9:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075eb:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075ee:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075f1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801075f7:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075fa:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075fd:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107600:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107603:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107606:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107609:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010760f:	83 c0 6c             	add    $0x6c,%eax
80107612:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107615:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010761b:	8b 40 10             	mov    0x10(%eax),%eax
8010761e:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107622:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107626:	89 74 24 14          	mov    %esi,0x14(%esp)
8010762a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
8010762e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107632:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107635:	89 54 24 08          	mov    %edx,0x8(%esp)
80107639:	89 44 24 04          	mov    %eax,0x4(%esp)
8010763d:	c7 04 24 6c 99 10 80 	movl   $0x8010996c,(%esp)
80107644:	e8 58 8d ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107649:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010764f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107656:	eb 01                	jmp    80107659 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107658:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107659:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010765f:	85 c0                	test   %eax,%eax
80107661:	74 24                	je     80107687 <trap+0x224>
80107663:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107669:	8b 40 24             	mov    0x24(%eax),%eax
8010766c:	85 c0                	test   %eax,%eax
8010766e:	74 17                	je     80107687 <trap+0x224>
80107670:	8b 45 08             	mov    0x8(%ebp),%eax
80107673:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107677:	0f b7 c0             	movzwl %ax,%eax
8010767a:	83 e0 03             	and    $0x3,%eax
8010767d:	83 f8 03             	cmp    $0x3,%eax
80107680:	75 05                	jne    80107687 <trap+0x224>
    exit();
80107682:	e8 7e dc ff ff       	call   80105305 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107687:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010768d:	85 c0                	test   %eax,%eax
8010768f:	74 1e                	je     801076af <trap+0x24c>
80107691:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107697:	8b 40 0c             	mov    0xc(%eax),%eax
8010769a:	83 f8 04             	cmp    $0x4,%eax
8010769d:	75 10                	jne    801076af <trap+0x24c>
8010769f:	8b 45 08             	mov    0x8(%ebp),%eax
801076a2:	8b 40 30             	mov    0x30(%eax),%eax
801076a5:	83 f8 20             	cmp    $0x20,%eax
801076a8:	75 05                	jne    801076af <trap+0x24c>
    yield();
801076aa:	e8 68 e0 ff ff       	call   80105717 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801076af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076b5:	85 c0                	test   %eax,%eax
801076b7:	74 27                	je     801076e0 <trap+0x27d>
801076b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076bf:	8b 40 24             	mov    0x24(%eax),%eax
801076c2:	85 c0                	test   %eax,%eax
801076c4:	74 1a                	je     801076e0 <trap+0x27d>
801076c6:	8b 45 08             	mov    0x8(%ebp),%eax
801076c9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801076cd:	0f b7 c0             	movzwl %ax,%eax
801076d0:	83 e0 03             	and    $0x3,%eax
801076d3:	83 f8 03             	cmp    $0x3,%eax
801076d6:	75 08                	jne    801076e0 <trap+0x27d>
    exit();
801076d8:	e8 28 dc ff ff       	call   80105305 <exit>
801076dd:	eb 01                	jmp    801076e0 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801076df:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801076e0:	83 c4 3c             	add    $0x3c,%esp
801076e3:	5b                   	pop    %ebx
801076e4:	5e                   	pop    %esi
801076e5:	5f                   	pop    %edi
801076e6:	5d                   	pop    %ebp
801076e7:	c3                   	ret    

801076e8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801076e8:	55                   	push   %ebp
801076e9:	89 e5                	mov    %esp,%ebp
801076eb:	53                   	push   %ebx
801076ec:	83 ec 14             	sub    $0x14,%esp
801076ef:	8b 45 08             	mov    0x8(%ebp),%eax
801076f2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801076f6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801076fa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801076fe:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107702:	ec                   	in     (%dx),%al
80107703:	89 c3                	mov    %eax,%ebx
80107705:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107708:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010770c:	83 c4 14             	add    $0x14,%esp
8010770f:	5b                   	pop    %ebx
80107710:	5d                   	pop    %ebp
80107711:	c3                   	ret    

80107712 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107712:	55                   	push   %ebp
80107713:	89 e5                	mov    %esp,%ebp
80107715:	83 ec 08             	sub    $0x8,%esp
80107718:	8b 55 08             	mov    0x8(%ebp),%edx
8010771b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010771e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107722:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107725:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107729:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010772d:	ee                   	out    %al,(%dx)
}
8010772e:	c9                   	leave  
8010772f:	c3                   	ret    

80107730 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107730:	55                   	push   %ebp
80107731:	89 e5                	mov    %esp,%ebp
80107733:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107736:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010773d:	00 
8010773e:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107745:	e8 c8 ff ff ff       	call   80107712 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
8010774a:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107751:	00 
80107752:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107759:	e8 b4 ff ff ff       	call   80107712 <outb>
  outb(COM1+0, 115200/9600);
8010775e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107765:	00 
80107766:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010776d:	e8 a0 ff ff ff       	call   80107712 <outb>
  outb(COM1+1, 0);
80107772:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107779:	00 
8010777a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107781:	e8 8c ff ff ff       	call   80107712 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107786:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010778d:	00 
8010778e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107795:	e8 78 ff ff ff       	call   80107712 <outb>
  outb(COM1+4, 0);
8010779a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801077a1:	00 
801077a2:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801077a9:	e8 64 ff ff ff       	call   80107712 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801077ae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801077b5:	00 
801077b6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801077bd:	e8 50 ff ff ff       	call   80107712 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801077c2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801077c9:	e8 1a ff ff ff       	call   801076e8 <inb>
801077ce:	3c ff                	cmp    $0xff,%al
801077d0:	74 6c                	je     8010783e <uartinit+0x10e>
    return;
  uart = 1;
801077d2:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801077d9:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801077dc:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801077e3:	e8 00 ff ff ff       	call   801076e8 <inb>
  inb(COM1+0);
801077e8:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801077ef:	e8 f4 fe ff ff       	call   801076e8 <inb>
  picenable(IRQ_COM1);
801077f4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801077fb:	e8 71 d1 ff ff       	call   80104971 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107800:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107807:	00 
80107808:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010780f:	e8 12 c0 ff ff       	call   80103826 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107814:	c7 45 f4 30 9a 10 80 	movl   $0x80109a30,-0xc(%ebp)
8010781b:	eb 15                	jmp    80107832 <uartinit+0x102>
    uartputc(*p);
8010781d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107820:	0f b6 00             	movzbl (%eax),%eax
80107823:	0f be c0             	movsbl %al,%eax
80107826:	89 04 24             	mov    %eax,(%esp)
80107829:	e8 13 00 00 00       	call   80107841 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010782e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107835:	0f b6 00             	movzbl (%eax),%eax
80107838:	84 c0                	test   %al,%al
8010783a:	75 e1                	jne    8010781d <uartinit+0xed>
8010783c:	eb 01                	jmp    8010783f <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
8010783e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
8010783f:	c9                   	leave  
80107840:	c3                   	ret    

80107841 <uartputc>:

void
uartputc(int c)
{
80107841:	55                   	push   %ebp
80107842:	89 e5                	mov    %esp,%ebp
80107844:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107847:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
8010784c:	85 c0                	test   %eax,%eax
8010784e:	74 4d                	je     8010789d <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107850:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107857:	eb 10                	jmp    80107869 <uartputc+0x28>
    microdelay(10);
80107859:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107860:	e8 59 c5 ff ff       	call   80103dbe <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107865:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107869:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
8010786d:	7f 16                	jg     80107885 <uartputc+0x44>
8010786f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107876:	e8 6d fe ff ff       	call   801076e8 <inb>
8010787b:	0f b6 c0             	movzbl %al,%eax
8010787e:	83 e0 20             	and    $0x20,%eax
80107881:	85 c0                	test   %eax,%eax
80107883:	74 d4                	je     80107859 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107885:	8b 45 08             	mov    0x8(%ebp),%eax
80107888:	0f b6 c0             	movzbl %al,%eax
8010788b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010788f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107896:	e8 77 fe ff ff       	call   80107712 <outb>
8010789b:	eb 01                	jmp    8010789e <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
8010789d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010789e:	c9                   	leave  
8010789f:	c3                   	ret    

801078a0 <uartgetc>:

static int
uartgetc(void)
{
801078a0:	55                   	push   %ebp
801078a1:	89 e5                	mov    %esp,%ebp
801078a3:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801078a6:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
801078ab:	85 c0                	test   %eax,%eax
801078ad:	75 07                	jne    801078b6 <uartgetc+0x16>
    return -1;
801078af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078b4:	eb 2c                	jmp    801078e2 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801078b6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801078bd:	e8 26 fe ff ff       	call   801076e8 <inb>
801078c2:	0f b6 c0             	movzbl %al,%eax
801078c5:	83 e0 01             	and    $0x1,%eax
801078c8:	85 c0                	test   %eax,%eax
801078ca:	75 07                	jne    801078d3 <uartgetc+0x33>
    return -1;
801078cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078d1:	eb 0f                	jmp    801078e2 <uartgetc+0x42>
  return inb(COM1+0);
801078d3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801078da:	e8 09 fe ff ff       	call   801076e8 <inb>
801078df:	0f b6 c0             	movzbl %al,%eax
}
801078e2:	c9                   	leave  
801078e3:	c3                   	ret    

801078e4 <uartintr>:

void
uartintr(void)
{
801078e4:	55                   	push   %ebp
801078e5:	89 e5                	mov    %esp,%ebp
801078e7:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801078ea:	c7 04 24 a0 78 10 80 	movl   $0x801078a0,(%esp)
801078f1:	e8 b7 8e ff ff       	call   801007ad <consoleintr>
}
801078f6:	c9                   	leave  
801078f7:	c3                   	ret    

801078f8 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801078f8:	6a 00                	push   $0x0
  pushl $0
801078fa:	6a 00                	push   $0x0
  jmp alltraps
801078fc:	e9 67 f9 ff ff       	jmp    80107268 <alltraps>

80107901 <vector1>:
.globl vector1
vector1:
  pushl $0
80107901:	6a 00                	push   $0x0
  pushl $1
80107903:	6a 01                	push   $0x1
  jmp alltraps
80107905:	e9 5e f9 ff ff       	jmp    80107268 <alltraps>

8010790a <vector2>:
.globl vector2
vector2:
  pushl $0
8010790a:	6a 00                	push   $0x0
  pushl $2
8010790c:	6a 02                	push   $0x2
  jmp alltraps
8010790e:	e9 55 f9 ff ff       	jmp    80107268 <alltraps>

80107913 <vector3>:
.globl vector3
vector3:
  pushl $0
80107913:	6a 00                	push   $0x0
  pushl $3
80107915:	6a 03                	push   $0x3
  jmp alltraps
80107917:	e9 4c f9 ff ff       	jmp    80107268 <alltraps>

8010791c <vector4>:
.globl vector4
vector4:
  pushl $0
8010791c:	6a 00                	push   $0x0
  pushl $4
8010791e:	6a 04                	push   $0x4
  jmp alltraps
80107920:	e9 43 f9 ff ff       	jmp    80107268 <alltraps>

80107925 <vector5>:
.globl vector5
vector5:
  pushl $0
80107925:	6a 00                	push   $0x0
  pushl $5
80107927:	6a 05                	push   $0x5
  jmp alltraps
80107929:	e9 3a f9 ff ff       	jmp    80107268 <alltraps>

8010792e <vector6>:
.globl vector6
vector6:
  pushl $0
8010792e:	6a 00                	push   $0x0
  pushl $6
80107930:	6a 06                	push   $0x6
  jmp alltraps
80107932:	e9 31 f9 ff ff       	jmp    80107268 <alltraps>

80107937 <vector7>:
.globl vector7
vector7:
  pushl $0
80107937:	6a 00                	push   $0x0
  pushl $7
80107939:	6a 07                	push   $0x7
  jmp alltraps
8010793b:	e9 28 f9 ff ff       	jmp    80107268 <alltraps>

80107940 <vector8>:
.globl vector8
vector8:
  pushl $8
80107940:	6a 08                	push   $0x8
  jmp alltraps
80107942:	e9 21 f9 ff ff       	jmp    80107268 <alltraps>

80107947 <vector9>:
.globl vector9
vector9:
  pushl $0
80107947:	6a 00                	push   $0x0
  pushl $9
80107949:	6a 09                	push   $0x9
  jmp alltraps
8010794b:	e9 18 f9 ff ff       	jmp    80107268 <alltraps>

80107950 <vector10>:
.globl vector10
vector10:
  pushl $10
80107950:	6a 0a                	push   $0xa
  jmp alltraps
80107952:	e9 11 f9 ff ff       	jmp    80107268 <alltraps>

80107957 <vector11>:
.globl vector11
vector11:
  pushl $11
80107957:	6a 0b                	push   $0xb
  jmp alltraps
80107959:	e9 0a f9 ff ff       	jmp    80107268 <alltraps>

8010795e <vector12>:
.globl vector12
vector12:
  pushl $12
8010795e:	6a 0c                	push   $0xc
  jmp alltraps
80107960:	e9 03 f9 ff ff       	jmp    80107268 <alltraps>

80107965 <vector13>:
.globl vector13
vector13:
  pushl $13
80107965:	6a 0d                	push   $0xd
  jmp alltraps
80107967:	e9 fc f8 ff ff       	jmp    80107268 <alltraps>

8010796c <vector14>:
.globl vector14
vector14:
  pushl $14
8010796c:	6a 0e                	push   $0xe
  jmp alltraps
8010796e:	e9 f5 f8 ff ff       	jmp    80107268 <alltraps>

80107973 <vector15>:
.globl vector15
vector15:
  pushl $0
80107973:	6a 00                	push   $0x0
  pushl $15
80107975:	6a 0f                	push   $0xf
  jmp alltraps
80107977:	e9 ec f8 ff ff       	jmp    80107268 <alltraps>

8010797c <vector16>:
.globl vector16
vector16:
  pushl $0
8010797c:	6a 00                	push   $0x0
  pushl $16
8010797e:	6a 10                	push   $0x10
  jmp alltraps
80107980:	e9 e3 f8 ff ff       	jmp    80107268 <alltraps>

80107985 <vector17>:
.globl vector17
vector17:
  pushl $17
80107985:	6a 11                	push   $0x11
  jmp alltraps
80107987:	e9 dc f8 ff ff       	jmp    80107268 <alltraps>

8010798c <vector18>:
.globl vector18
vector18:
  pushl $0
8010798c:	6a 00                	push   $0x0
  pushl $18
8010798e:	6a 12                	push   $0x12
  jmp alltraps
80107990:	e9 d3 f8 ff ff       	jmp    80107268 <alltraps>

80107995 <vector19>:
.globl vector19
vector19:
  pushl $0
80107995:	6a 00                	push   $0x0
  pushl $19
80107997:	6a 13                	push   $0x13
  jmp alltraps
80107999:	e9 ca f8 ff ff       	jmp    80107268 <alltraps>

8010799e <vector20>:
.globl vector20
vector20:
  pushl $0
8010799e:	6a 00                	push   $0x0
  pushl $20
801079a0:	6a 14                	push   $0x14
  jmp alltraps
801079a2:	e9 c1 f8 ff ff       	jmp    80107268 <alltraps>

801079a7 <vector21>:
.globl vector21
vector21:
  pushl $0
801079a7:	6a 00                	push   $0x0
  pushl $21
801079a9:	6a 15                	push   $0x15
  jmp alltraps
801079ab:	e9 b8 f8 ff ff       	jmp    80107268 <alltraps>

801079b0 <vector22>:
.globl vector22
vector22:
  pushl $0
801079b0:	6a 00                	push   $0x0
  pushl $22
801079b2:	6a 16                	push   $0x16
  jmp alltraps
801079b4:	e9 af f8 ff ff       	jmp    80107268 <alltraps>

801079b9 <vector23>:
.globl vector23
vector23:
  pushl $0
801079b9:	6a 00                	push   $0x0
  pushl $23
801079bb:	6a 17                	push   $0x17
  jmp alltraps
801079bd:	e9 a6 f8 ff ff       	jmp    80107268 <alltraps>

801079c2 <vector24>:
.globl vector24
vector24:
  pushl $0
801079c2:	6a 00                	push   $0x0
  pushl $24
801079c4:	6a 18                	push   $0x18
  jmp alltraps
801079c6:	e9 9d f8 ff ff       	jmp    80107268 <alltraps>

801079cb <vector25>:
.globl vector25
vector25:
  pushl $0
801079cb:	6a 00                	push   $0x0
  pushl $25
801079cd:	6a 19                	push   $0x19
  jmp alltraps
801079cf:	e9 94 f8 ff ff       	jmp    80107268 <alltraps>

801079d4 <vector26>:
.globl vector26
vector26:
  pushl $0
801079d4:	6a 00                	push   $0x0
  pushl $26
801079d6:	6a 1a                	push   $0x1a
  jmp alltraps
801079d8:	e9 8b f8 ff ff       	jmp    80107268 <alltraps>

801079dd <vector27>:
.globl vector27
vector27:
  pushl $0
801079dd:	6a 00                	push   $0x0
  pushl $27
801079df:	6a 1b                	push   $0x1b
  jmp alltraps
801079e1:	e9 82 f8 ff ff       	jmp    80107268 <alltraps>

801079e6 <vector28>:
.globl vector28
vector28:
  pushl $0
801079e6:	6a 00                	push   $0x0
  pushl $28
801079e8:	6a 1c                	push   $0x1c
  jmp alltraps
801079ea:	e9 79 f8 ff ff       	jmp    80107268 <alltraps>

801079ef <vector29>:
.globl vector29
vector29:
  pushl $0
801079ef:	6a 00                	push   $0x0
  pushl $29
801079f1:	6a 1d                	push   $0x1d
  jmp alltraps
801079f3:	e9 70 f8 ff ff       	jmp    80107268 <alltraps>

801079f8 <vector30>:
.globl vector30
vector30:
  pushl $0
801079f8:	6a 00                	push   $0x0
  pushl $30
801079fa:	6a 1e                	push   $0x1e
  jmp alltraps
801079fc:	e9 67 f8 ff ff       	jmp    80107268 <alltraps>

80107a01 <vector31>:
.globl vector31
vector31:
  pushl $0
80107a01:	6a 00                	push   $0x0
  pushl $31
80107a03:	6a 1f                	push   $0x1f
  jmp alltraps
80107a05:	e9 5e f8 ff ff       	jmp    80107268 <alltraps>

80107a0a <vector32>:
.globl vector32
vector32:
  pushl $0
80107a0a:	6a 00                	push   $0x0
  pushl $32
80107a0c:	6a 20                	push   $0x20
  jmp alltraps
80107a0e:	e9 55 f8 ff ff       	jmp    80107268 <alltraps>

80107a13 <vector33>:
.globl vector33
vector33:
  pushl $0
80107a13:	6a 00                	push   $0x0
  pushl $33
80107a15:	6a 21                	push   $0x21
  jmp alltraps
80107a17:	e9 4c f8 ff ff       	jmp    80107268 <alltraps>

80107a1c <vector34>:
.globl vector34
vector34:
  pushl $0
80107a1c:	6a 00                	push   $0x0
  pushl $34
80107a1e:	6a 22                	push   $0x22
  jmp alltraps
80107a20:	e9 43 f8 ff ff       	jmp    80107268 <alltraps>

80107a25 <vector35>:
.globl vector35
vector35:
  pushl $0
80107a25:	6a 00                	push   $0x0
  pushl $35
80107a27:	6a 23                	push   $0x23
  jmp alltraps
80107a29:	e9 3a f8 ff ff       	jmp    80107268 <alltraps>

80107a2e <vector36>:
.globl vector36
vector36:
  pushl $0
80107a2e:	6a 00                	push   $0x0
  pushl $36
80107a30:	6a 24                	push   $0x24
  jmp alltraps
80107a32:	e9 31 f8 ff ff       	jmp    80107268 <alltraps>

80107a37 <vector37>:
.globl vector37
vector37:
  pushl $0
80107a37:	6a 00                	push   $0x0
  pushl $37
80107a39:	6a 25                	push   $0x25
  jmp alltraps
80107a3b:	e9 28 f8 ff ff       	jmp    80107268 <alltraps>

80107a40 <vector38>:
.globl vector38
vector38:
  pushl $0
80107a40:	6a 00                	push   $0x0
  pushl $38
80107a42:	6a 26                	push   $0x26
  jmp alltraps
80107a44:	e9 1f f8 ff ff       	jmp    80107268 <alltraps>

80107a49 <vector39>:
.globl vector39
vector39:
  pushl $0
80107a49:	6a 00                	push   $0x0
  pushl $39
80107a4b:	6a 27                	push   $0x27
  jmp alltraps
80107a4d:	e9 16 f8 ff ff       	jmp    80107268 <alltraps>

80107a52 <vector40>:
.globl vector40
vector40:
  pushl $0
80107a52:	6a 00                	push   $0x0
  pushl $40
80107a54:	6a 28                	push   $0x28
  jmp alltraps
80107a56:	e9 0d f8 ff ff       	jmp    80107268 <alltraps>

80107a5b <vector41>:
.globl vector41
vector41:
  pushl $0
80107a5b:	6a 00                	push   $0x0
  pushl $41
80107a5d:	6a 29                	push   $0x29
  jmp alltraps
80107a5f:	e9 04 f8 ff ff       	jmp    80107268 <alltraps>

80107a64 <vector42>:
.globl vector42
vector42:
  pushl $0
80107a64:	6a 00                	push   $0x0
  pushl $42
80107a66:	6a 2a                	push   $0x2a
  jmp alltraps
80107a68:	e9 fb f7 ff ff       	jmp    80107268 <alltraps>

80107a6d <vector43>:
.globl vector43
vector43:
  pushl $0
80107a6d:	6a 00                	push   $0x0
  pushl $43
80107a6f:	6a 2b                	push   $0x2b
  jmp alltraps
80107a71:	e9 f2 f7 ff ff       	jmp    80107268 <alltraps>

80107a76 <vector44>:
.globl vector44
vector44:
  pushl $0
80107a76:	6a 00                	push   $0x0
  pushl $44
80107a78:	6a 2c                	push   $0x2c
  jmp alltraps
80107a7a:	e9 e9 f7 ff ff       	jmp    80107268 <alltraps>

80107a7f <vector45>:
.globl vector45
vector45:
  pushl $0
80107a7f:	6a 00                	push   $0x0
  pushl $45
80107a81:	6a 2d                	push   $0x2d
  jmp alltraps
80107a83:	e9 e0 f7 ff ff       	jmp    80107268 <alltraps>

80107a88 <vector46>:
.globl vector46
vector46:
  pushl $0
80107a88:	6a 00                	push   $0x0
  pushl $46
80107a8a:	6a 2e                	push   $0x2e
  jmp alltraps
80107a8c:	e9 d7 f7 ff ff       	jmp    80107268 <alltraps>

80107a91 <vector47>:
.globl vector47
vector47:
  pushl $0
80107a91:	6a 00                	push   $0x0
  pushl $47
80107a93:	6a 2f                	push   $0x2f
  jmp alltraps
80107a95:	e9 ce f7 ff ff       	jmp    80107268 <alltraps>

80107a9a <vector48>:
.globl vector48
vector48:
  pushl $0
80107a9a:	6a 00                	push   $0x0
  pushl $48
80107a9c:	6a 30                	push   $0x30
  jmp alltraps
80107a9e:	e9 c5 f7 ff ff       	jmp    80107268 <alltraps>

80107aa3 <vector49>:
.globl vector49
vector49:
  pushl $0
80107aa3:	6a 00                	push   $0x0
  pushl $49
80107aa5:	6a 31                	push   $0x31
  jmp alltraps
80107aa7:	e9 bc f7 ff ff       	jmp    80107268 <alltraps>

80107aac <vector50>:
.globl vector50
vector50:
  pushl $0
80107aac:	6a 00                	push   $0x0
  pushl $50
80107aae:	6a 32                	push   $0x32
  jmp alltraps
80107ab0:	e9 b3 f7 ff ff       	jmp    80107268 <alltraps>

80107ab5 <vector51>:
.globl vector51
vector51:
  pushl $0
80107ab5:	6a 00                	push   $0x0
  pushl $51
80107ab7:	6a 33                	push   $0x33
  jmp alltraps
80107ab9:	e9 aa f7 ff ff       	jmp    80107268 <alltraps>

80107abe <vector52>:
.globl vector52
vector52:
  pushl $0
80107abe:	6a 00                	push   $0x0
  pushl $52
80107ac0:	6a 34                	push   $0x34
  jmp alltraps
80107ac2:	e9 a1 f7 ff ff       	jmp    80107268 <alltraps>

80107ac7 <vector53>:
.globl vector53
vector53:
  pushl $0
80107ac7:	6a 00                	push   $0x0
  pushl $53
80107ac9:	6a 35                	push   $0x35
  jmp alltraps
80107acb:	e9 98 f7 ff ff       	jmp    80107268 <alltraps>

80107ad0 <vector54>:
.globl vector54
vector54:
  pushl $0
80107ad0:	6a 00                	push   $0x0
  pushl $54
80107ad2:	6a 36                	push   $0x36
  jmp alltraps
80107ad4:	e9 8f f7 ff ff       	jmp    80107268 <alltraps>

80107ad9 <vector55>:
.globl vector55
vector55:
  pushl $0
80107ad9:	6a 00                	push   $0x0
  pushl $55
80107adb:	6a 37                	push   $0x37
  jmp alltraps
80107add:	e9 86 f7 ff ff       	jmp    80107268 <alltraps>

80107ae2 <vector56>:
.globl vector56
vector56:
  pushl $0
80107ae2:	6a 00                	push   $0x0
  pushl $56
80107ae4:	6a 38                	push   $0x38
  jmp alltraps
80107ae6:	e9 7d f7 ff ff       	jmp    80107268 <alltraps>

80107aeb <vector57>:
.globl vector57
vector57:
  pushl $0
80107aeb:	6a 00                	push   $0x0
  pushl $57
80107aed:	6a 39                	push   $0x39
  jmp alltraps
80107aef:	e9 74 f7 ff ff       	jmp    80107268 <alltraps>

80107af4 <vector58>:
.globl vector58
vector58:
  pushl $0
80107af4:	6a 00                	push   $0x0
  pushl $58
80107af6:	6a 3a                	push   $0x3a
  jmp alltraps
80107af8:	e9 6b f7 ff ff       	jmp    80107268 <alltraps>

80107afd <vector59>:
.globl vector59
vector59:
  pushl $0
80107afd:	6a 00                	push   $0x0
  pushl $59
80107aff:	6a 3b                	push   $0x3b
  jmp alltraps
80107b01:	e9 62 f7 ff ff       	jmp    80107268 <alltraps>

80107b06 <vector60>:
.globl vector60
vector60:
  pushl $0
80107b06:	6a 00                	push   $0x0
  pushl $60
80107b08:	6a 3c                	push   $0x3c
  jmp alltraps
80107b0a:	e9 59 f7 ff ff       	jmp    80107268 <alltraps>

80107b0f <vector61>:
.globl vector61
vector61:
  pushl $0
80107b0f:	6a 00                	push   $0x0
  pushl $61
80107b11:	6a 3d                	push   $0x3d
  jmp alltraps
80107b13:	e9 50 f7 ff ff       	jmp    80107268 <alltraps>

80107b18 <vector62>:
.globl vector62
vector62:
  pushl $0
80107b18:	6a 00                	push   $0x0
  pushl $62
80107b1a:	6a 3e                	push   $0x3e
  jmp alltraps
80107b1c:	e9 47 f7 ff ff       	jmp    80107268 <alltraps>

80107b21 <vector63>:
.globl vector63
vector63:
  pushl $0
80107b21:	6a 00                	push   $0x0
  pushl $63
80107b23:	6a 3f                	push   $0x3f
  jmp alltraps
80107b25:	e9 3e f7 ff ff       	jmp    80107268 <alltraps>

80107b2a <vector64>:
.globl vector64
vector64:
  pushl $0
80107b2a:	6a 00                	push   $0x0
  pushl $64
80107b2c:	6a 40                	push   $0x40
  jmp alltraps
80107b2e:	e9 35 f7 ff ff       	jmp    80107268 <alltraps>

80107b33 <vector65>:
.globl vector65
vector65:
  pushl $0
80107b33:	6a 00                	push   $0x0
  pushl $65
80107b35:	6a 41                	push   $0x41
  jmp alltraps
80107b37:	e9 2c f7 ff ff       	jmp    80107268 <alltraps>

80107b3c <vector66>:
.globl vector66
vector66:
  pushl $0
80107b3c:	6a 00                	push   $0x0
  pushl $66
80107b3e:	6a 42                	push   $0x42
  jmp alltraps
80107b40:	e9 23 f7 ff ff       	jmp    80107268 <alltraps>

80107b45 <vector67>:
.globl vector67
vector67:
  pushl $0
80107b45:	6a 00                	push   $0x0
  pushl $67
80107b47:	6a 43                	push   $0x43
  jmp alltraps
80107b49:	e9 1a f7 ff ff       	jmp    80107268 <alltraps>

80107b4e <vector68>:
.globl vector68
vector68:
  pushl $0
80107b4e:	6a 00                	push   $0x0
  pushl $68
80107b50:	6a 44                	push   $0x44
  jmp alltraps
80107b52:	e9 11 f7 ff ff       	jmp    80107268 <alltraps>

80107b57 <vector69>:
.globl vector69
vector69:
  pushl $0
80107b57:	6a 00                	push   $0x0
  pushl $69
80107b59:	6a 45                	push   $0x45
  jmp alltraps
80107b5b:	e9 08 f7 ff ff       	jmp    80107268 <alltraps>

80107b60 <vector70>:
.globl vector70
vector70:
  pushl $0
80107b60:	6a 00                	push   $0x0
  pushl $70
80107b62:	6a 46                	push   $0x46
  jmp alltraps
80107b64:	e9 ff f6 ff ff       	jmp    80107268 <alltraps>

80107b69 <vector71>:
.globl vector71
vector71:
  pushl $0
80107b69:	6a 00                	push   $0x0
  pushl $71
80107b6b:	6a 47                	push   $0x47
  jmp alltraps
80107b6d:	e9 f6 f6 ff ff       	jmp    80107268 <alltraps>

80107b72 <vector72>:
.globl vector72
vector72:
  pushl $0
80107b72:	6a 00                	push   $0x0
  pushl $72
80107b74:	6a 48                	push   $0x48
  jmp alltraps
80107b76:	e9 ed f6 ff ff       	jmp    80107268 <alltraps>

80107b7b <vector73>:
.globl vector73
vector73:
  pushl $0
80107b7b:	6a 00                	push   $0x0
  pushl $73
80107b7d:	6a 49                	push   $0x49
  jmp alltraps
80107b7f:	e9 e4 f6 ff ff       	jmp    80107268 <alltraps>

80107b84 <vector74>:
.globl vector74
vector74:
  pushl $0
80107b84:	6a 00                	push   $0x0
  pushl $74
80107b86:	6a 4a                	push   $0x4a
  jmp alltraps
80107b88:	e9 db f6 ff ff       	jmp    80107268 <alltraps>

80107b8d <vector75>:
.globl vector75
vector75:
  pushl $0
80107b8d:	6a 00                	push   $0x0
  pushl $75
80107b8f:	6a 4b                	push   $0x4b
  jmp alltraps
80107b91:	e9 d2 f6 ff ff       	jmp    80107268 <alltraps>

80107b96 <vector76>:
.globl vector76
vector76:
  pushl $0
80107b96:	6a 00                	push   $0x0
  pushl $76
80107b98:	6a 4c                	push   $0x4c
  jmp alltraps
80107b9a:	e9 c9 f6 ff ff       	jmp    80107268 <alltraps>

80107b9f <vector77>:
.globl vector77
vector77:
  pushl $0
80107b9f:	6a 00                	push   $0x0
  pushl $77
80107ba1:	6a 4d                	push   $0x4d
  jmp alltraps
80107ba3:	e9 c0 f6 ff ff       	jmp    80107268 <alltraps>

80107ba8 <vector78>:
.globl vector78
vector78:
  pushl $0
80107ba8:	6a 00                	push   $0x0
  pushl $78
80107baa:	6a 4e                	push   $0x4e
  jmp alltraps
80107bac:	e9 b7 f6 ff ff       	jmp    80107268 <alltraps>

80107bb1 <vector79>:
.globl vector79
vector79:
  pushl $0
80107bb1:	6a 00                	push   $0x0
  pushl $79
80107bb3:	6a 4f                	push   $0x4f
  jmp alltraps
80107bb5:	e9 ae f6 ff ff       	jmp    80107268 <alltraps>

80107bba <vector80>:
.globl vector80
vector80:
  pushl $0
80107bba:	6a 00                	push   $0x0
  pushl $80
80107bbc:	6a 50                	push   $0x50
  jmp alltraps
80107bbe:	e9 a5 f6 ff ff       	jmp    80107268 <alltraps>

80107bc3 <vector81>:
.globl vector81
vector81:
  pushl $0
80107bc3:	6a 00                	push   $0x0
  pushl $81
80107bc5:	6a 51                	push   $0x51
  jmp alltraps
80107bc7:	e9 9c f6 ff ff       	jmp    80107268 <alltraps>

80107bcc <vector82>:
.globl vector82
vector82:
  pushl $0
80107bcc:	6a 00                	push   $0x0
  pushl $82
80107bce:	6a 52                	push   $0x52
  jmp alltraps
80107bd0:	e9 93 f6 ff ff       	jmp    80107268 <alltraps>

80107bd5 <vector83>:
.globl vector83
vector83:
  pushl $0
80107bd5:	6a 00                	push   $0x0
  pushl $83
80107bd7:	6a 53                	push   $0x53
  jmp alltraps
80107bd9:	e9 8a f6 ff ff       	jmp    80107268 <alltraps>

80107bde <vector84>:
.globl vector84
vector84:
  pushl $0
80107bde:	6a 00                	push   $0x0
  pushl $84
80107be0:	6a 54                	push   $0x54
  jmp alltraps
80107be2:	e9 81 f6 ff ff       	jmp    80107268 <alltraps>

80107be7 <vector85>:
.globl vector85
vector85:
  pushl $0
80107be7:	6a 00                	push   $0x0
  pushl $85
80107be9:	6a 55                	push   $0x55
  jmp alltraps
80107beb:	e9 78 f6 ff ff       	jmp    80107268 <alltraps>

80107bf0 <vector86>:
.globl vector86
vector86:
  pushl $0
80107bf0:	6a 00                	push   $0x0
  pushl $86
80107bf2:	6a 56                	push   $0x56
  jmp alltraps
80107bf4:	e9 6f f6 ff ff       	jmp    80107268 <alltraps>

80107bf9 <vector87>:
.globl vector87
vector87:
  pushl $0
80107bf9:	6a 00                	push   $0x0
  pushl $87
80107bfb:	6a 57                	push   $0x57
  jmp alltraps
80107bfd:	e9 66 f6 ff ff       	jmp    80107268 <alltraps>

80107c02 <vector88>:
.globl vector88
vector88:
  pushl $0
80107c02:	6a 00                	push   $0x0
  pushl $88
80107c04:	6a 58                	push   $0x58
  jmp alltraps
80107c06:	e9 5d f6 ff ff       	jmp    80107268 <alltraps>

80107c0b <vector89>:
.globl vector89
vector89:
  pushl $0
80107c0b:	6a 00                	push   $0x0
  pushl $89
80107c0d:	6a 59                	push   $0x59
  jmp alltraps
80107c0f:	e9 54 f6 ff ff       	jmp    80107268 <alltraps>

80107c14 <vector90>:
.globl vector90
vector90:
  pushl $0
80107c14:	6a 00                	push   $0x0
  pushl $90
80107c16:	6a 5a                	push   $0x5a
  jmp alltraps
80107c18:	e9 4b f6 ff ff       	jmp    80107268 <alltraps>

80107c1d <vector91>:
.globl vector91
vector91:
  pushl $0
80107c1d:	6a 00                	push   $0x0
  pushl $91
80107c1f:	6a 5b                	push   $0x5b
  jmp alltraps
80107c21:	e9 42 f6 ff ff       	jmp    80107268 <alltraps>

80107c26 <vector92>:
.globl vector92
vector92:
  pushl $0
80107c26:	6a 00                	push   $0x0
  pushl $92
80107c28:	6a 5c                	push   $0x5c
  jmp alltraps
80107c2a:	e9 39 f6 ff ff       	jmp    80107268 <alltraps>

80107c2f <vector93>:
.globl vector93
vector93:
  pushl $0
80107c2f:	6a 00                	push   $0x0
  pushl $93
80107c31:	6a 5d                	push   $0x5d
  jmp alltraps
80107c33:	e9 30 f6 ff ff       	jmp    80107268 <alltraps>

80107c38 <vector94>:
.globl vector94
vector94:
  pushl $0
80107c38:	6a 00                	push   $0x0
  pushl $94
80107c3a:	6a 5e                	push   $0x5e
  jmp alltraps
80107c3c:	e9 27 f6 ff ff       	jmp    80107268 <alltraps>

80107c41 <vector95>:
.globl vector95
vector95:
  pushl $0
80107c41:	6a 00                	push   $0x0
  pushl $95
80107c43:	6a 5f                	push   $0x5f
  jmp alltraps
80107c45:	e9 1e f6 ff ff       	jmp    80107268 <alltraps>

80107c4a <vector96>:
.globl vector96
vector96:
  pushl $0
80107c4a:	6a 00                	push   $0x0
  pushl $96
80107c4c:	6a 60                	push   $0x60
  jmp alltraps
80107c4e:	e9 15 f6 ff ff       	jmp    80107268 <alltraps>

80107c53 <vector97>:
.globl vector97
vector97:
  pushl $0
80107c53:	6a 00                	push   $0x0
  pushl $97
80107c55:	6a 61                	push   $0x61
  jmp alltraps
80107c57:	e9 0c f6 ff ff       	jmp    80107268 <alltraps>

80107c5c <vector98>:
.globl vector98
vector98:
  pushl $0
80107c5c:	6a 00                	push   $0x0
  pushl $98
80107c5e:	6a 62                	push   $0x62
  jmp alltraps
80107c60:	e9 03 f6 ff ff       	jmp    80107268 <alltraps>

80107c65 <vector99>:
.globl vector99
vector99:
  pushl $0
80107c65:	6a 00                	push   $0x0
  pushl $99
80107c67:	6a 63                	push   $0x63
  jmp alltraps
80107c69:	e9 fa f5 ff ff       	jmp    80107268 <alltraps>

80107c6e <vector100>:
.globl vector100
vector100:
  pushl $0
80107c6e:	6a 00                	push   $0x0
  pushl $100
80107c70:	6a 64                	push   $0x64
  jmp alltraps
80107c72:	e9 f1 f5 ff ff       	jmp    80107268 <alltraps>

80107c77 <vector101>:
.globl vector101
vector101:
  pushl $0
80107c77:	6a 00                	push   $0x0
  pushl $101
80107c79:	6a 65                	push   $0x65
  jmp alltraps
80107c7b:	e9 e8 f5 ff ff       	jmp    80107268 <alltraps>

80107c80 <vector102>:
.globl vector102
vector102:
  pushl $0
80107c80:	6a 00                	push   $0x0
  pushl $102
80107c82:	6a 66                	push   $0x66
  jmp alltraps
80107c84:	e9 df f5 ff ff       	jmp    80107268 <alltraps>

80107c89 <vector103>:
.globl vector103
vector103:
  pushl $0
80107c89:	6a 00                	push   $0x0
  pushl $103
80107c8b:	6a 67                	push   $0x67
  jmp alltraps
80107c8d:	e9 d6 f5 ff ff       	jmp    80107268 <alltraps>

80107c92 <vector104>:
.globl vector104
vector104:
  pushl $0
80107c92:	6a 00                	push   $0x0
  pushl $104
80107c94:	6a 68                	push   $0x68
  jmp alltraps
80107c96:	e9 cd f5 ff ff       	jmp    80107268 <alltraps>

80107c9b <vector105>:
.globl vector105
vector105:
  pushl $0
80107c9b:	6a 00                	push   $0x0
  pushl $105
80107c9d:	6a 69                	push   $0x69
  jmp alltraps
80107c9f:	e9 c4 f5 ff ff       	jmp    80107268 <alltraps>

80107ca4 <vector106>:
.globl vector106
vector106:
  pushl $0
80107ca4:	6a 00                	push   $0x0
  pushl $106
80107ca6:	6a 6a                	push   $0x6a
  jmp alltraps
80107ca8:	e9 bb f5 ff ff       	jmp    80107268 <alltraps>

80107cad <vector107>:
.globl vector107
vector107:
  pushl $0
80107cad:	6a 00                	push   $0x0
  pushl $107
80107caf:	6a 6b                	push   $0x6b
  jmp alltraps
80107cb1:	e9 b2 f5 ff ff       	jmp    80107268 <alltraps>

80107cb6 <vector108>:
.globl vector108
vector108:
  pushl $0
80107cb6:	6a 00                	push   $0x0
  pushl $108
80107cb8:	6a 6c                	push   $0x6c
  jmp alltraps
80107cba:	e9 a9 f5 ff ff       	jmp    80107268 <alltraps>

80107cbf <vector109>:
.globl vector109
vector109:
  pushl $0
80107cbf:	6a 00                	push   $0x0
  pushl $109
80107cc1:	6a 6d                	push   $0x6d
  jmp alltraps
80107cc3:	e9 a0 f5 ff ff       	jmp    80107268 <alltraps>

80107cc8 <vector110>:
.globl vector110
vector110:
  pushl $0
80107cc8:	6a 00                	push   $0x0
  pushl $110
80107cca:	6a 6e                	push   $0x6e
  jmp alltraps
80107ccc:	e9 97 f5 ff ff       	jmp    80107268 <alltraps>

80107cd1 <vector111>:
.globl vector111
vector111:
  pushl $0
80107cd1:	6a 00                	push   $0x0
  pushl $111
80107cd3:	6a 6f                	push   $0x6f
  jmp alltraps
80107cd5:	e9 8e f5 ff ff       	jmp    80107268 <alltraps>

80107cda <vector112>:
.globl vector112
vector112:
  pushl $0
80107cda:	6a 00                	push   $0x0
  pushl $112
80107cdc:	6a 70                	push   $0x70
  jmp alltraps
80107cde:	e9 85 f5 ff ff       	jmp    80107268 <alltraps>

80107ce3 <vector113>:
.globl vector113
vector113:
  pushl $0
80107ce3:	6a 00                	push   $0x0
  pushl $113
80107ce5:	6a 71                	push   $0x71
  jmp alltraps
80107ce7:	e9 7c f5 ff ff       	jmp    80107268 <alltraps>

80107cec <vector114>:
.globl vector114
vector114:
  pushl $0
80107cec:	6a 00                	push   $0x0
  pushl $114
80107cee:	6a 72                	push   $0x72
  jmp alltraps
80107cf0:	e9 73 f5 ff ff       	jmp    80107268 <alltraps>

80107cf5 <vector115>:
.globl vector115
vector115:
  pushl $0
80107cf5:	6a 00                	push   $0x0
  pushl $115
80107cf7:	6a 73                	push   $0x73
  jmp alltraps
80107cf9:	e9 6a f5 ff ff       	jmp    80107268 <alltraps>

80107cfe <vector116>:
.globl vector116
vector116:
  pushl $0
80107cfe:	6a 00                	push   $0x0
  pushl $116
80107d00:	6a 74                	push   $0x74
  jmp alltraps
80107d02:	e9 61 f5 ff ff       	jmp    80107268 <alltraps>

80107d07 <vector117>:
.globl vector117
vector117:
  pushl $0
80107d07:	6a 00                	push   $0x0
  pushl $117
80107d09:	6a 75                	push   $0x75
  jmp alltraps
80107d0b:	e9 58 f5 ff ff       	jmp    80107268 <alltraps>

80107d10 <vector118>:
.globl vector118
vector118:
  pushl $0
80107d10:	6a 00                	push   $0x0
  pushl $118
80107d12:	6a 76                	push   $0x76
  jmp alltraps
80107d14:	e9 4f f5 ff ff       	jmp    80107268 <alltraps>

80107d19 <vector119>:
.globl vector119
vector119:
  pushl $0
80107d19:	6a 00                	push   $0x0
  pushl $119
80107d1b:	6a 77                	push   $0x77
  jmp alltraps
80107d1d:	e9 46 f5 ff ff       	jmp    80107268 <alltraps>

80107d22 <vector120>:
.globl vector120
vector120:
  pushl $0
80107d22:	6a 00                	push   $0x0
  pushl $120
80107d24:	6a 78                	push   $0x78
  jmp alltraps
80107d26:	e9 3d f5 ff ff       	jmp    80107268 <alltraps>

80107d2b <vector121>:
.globl vector121
vector121:
  pushl $0
80107d2b:	6a 00                	push   $0x0
  pushl $121
80107d2d:	6a 79                	push   $0x79
  jmp alltraps
80107d2f:	e9 34 f5 ff ff       	jmp    80107268 <alltraps>

80107d34 <vector122>:
.globl vector122
vector122:
  pushl $0
80107d34:	6a 00                	push   $0x0
  pushl $122
80107d36:	6a 7a                	push   $0x7a
  jmp alltraps
80107d38:	e9 2b f5 ff ff       	jmp    80107268 <alltraps>

80107d3d <vector123>:
.globl vector123
vector123:
  pushl $0
80107d3d:	6a 00                	push   $0x0
  pushl $123
80107d3f:	6a 7b                	push   $0x7b
  jmp alltraps
80107d41:	e9 22 f5 ff ff       	jmp    80107268 <alltraps>

80107d46 <vector124>:
.globl vector124
vector124:
  pushl $0
80107d46:	6a 00                	push   $0x0
  pushl $124
80107d48:	6a 7c                	push   $0x7c
  jmp alltraps
80107d4a:	e9 19 f5 ff ff       	jmp    80107268 <alltraps>

80107d4f <vector125>:
.globl vector125
vector125:
  pushl $0
80107d4f:	6a 00                	push   $0x0
  pushl $125
80107d51:	6a 7d                	push   $0x7d
  jmp alltraps
80107d53:	e9 10 f5 ff ff       	jmp    80107268 <alltraps>

80107d58 <vector126>:
.globl vector126
vector126:
  pushl $0
80107d58:	6a 00                	push   $0x0
  pushl $126
80107d5a:	6a 7e                	push   $0x7e
  jmp alltraps
80107d5c:	e9 07 f5 ff ff       	jmp    80107268 <alltraps>

80107d61 <vector127>:
.globl vector127
vector127:
  pushl $0
80107d61:	6a 00                	push   $0x0
  pushl $127
80107d63:	6a 7f                	push   $0x7f
  jmp alltraps
80107d65:	e9 fe f4 ff ff       	jmp    80107268 <alltraps>

80107d6a <vector128>:
.globl vector128
vector128:
  pushl $0
80107d6a:	6a 00                	push   $0x0
  pushl $128
80107d6c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107d71:	e9 f2 f4 ff ff       	jmp    80107268 <alltraps>

80107d76 <vector129>:
.globl vector129
vector129:
  pushl $0
80107d76:	6a 00                	push   $0x0
  pushl $129
80107d78:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107d7d:	e9 e6 f4 ff ff       	jmp    80107268 <alltraps>

80107d82 <vector130>:
.globl vector130
vector130:
  pushl $0
80107d82:	6a 00                	push   $0x0
  pushl $130
80107d84:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107d89:	e9 da f4 ff ff       	jmp    80107268 <alltraps>

80107d8e <vector131>:
.globl vector131
vector131:
  pushl $0
80107d8e:	6a 00                	push   $0x0
  pushl $131
80107d90:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107d95:	e9 ce f4 ff ff       	jmp    80107268 <alltraps>

80107d9a <vector132>:
.globl vector132
vector132:
  pushl $0
80107d9a:	6a 00                	push   $0x0
  pushl $132
80107d9c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107da1:	e9 c2 f4 ff ff       	jmp    80107268 <alltraps>

80107da6 <vector133>:
.globl vector133
vector133:
  pushl $0
80107da6:	6a 00                	push   $0x0
  pushl $133
80107da8:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107dad:	e9 b6 f4 ff ff       	jmp    80107268 <alltraps>

80107db2 <vector134>:
.globl vector134
vector134:
  pushl $0
80107db2:	6a 00                	push   $0x0
  pushl $134
80107db4:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107db9:	e9 aa f4 ff ff       	jmp    80107268 <alltraps>

80107dbe <vector135>:
.globl vector135
vector135:
  pushl $0
80107dbe:	6a 00                	push   $0x0
  pushl $135
80107dc0:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107dc5:	e9 9e f4 ff ff       	jmp    80107268 <alltraps>

80107dca <vector136>:
.globl vector136
vector136:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $136
80107dcc:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107dd1:	e9 92 f4 ff ff       	jmp    80107268 <alltraps>

80107dd6 <vector137>:
.globl vector137
vector137:
  pushl $0
80107dd6:	6a 00                	push   $0x0
  pushl $137
80107dd8:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107ddd:	e9 86 f4 ff ff       	jmp    80107268 <alltraps>

80107de2 <vector138>:
.globl vector138
vector138:
  pushl $0
80107de2:	6a 00                	push   $0x0
  pushl $138
80107de4:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107de9:	e9 7a f4 ff ff       	jmp    80107268 <alltraps>

80107dee <vector139>:
.globl vector139
vector139:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $139
80107df0:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107df5:	e9 6e f4 ff ff       	jmp    80107268 <alltraps>

80107dfa <vector140>:
.globl vector140
vector140:
  pushl $0
80107dfa:	6a 00                	push   $0x0
  pushl $140
80107dfc:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107e01:	e9 62 f4 ff ff       	jmp    80107268 <alltraps>

80107e06 <vector141>:
.globl vector141
vector141:
  pushl $0
80107e06:	6a 00                	push   $0x0
  pushl $141
80107e08:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107e0d:	e9 56 f4 ff ff       	jmp    80107268 <alltraps>

80107e12 <vector142>:
.globl vector142
vector142:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $142
80107e14:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107e19:	e9 4a f4 ff ff       	jmp    80107268 <alltraps>

80107e1e <vector143>:
.globl vector143
vector143:
  pushl $0
80107e1e:	6a 00                	push   $0x0
  pushl $143
80107e20:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107e25:	e9 3e f4 ff ff       	jmp    80107268 <alltraps>

80107e2a <vector144>:
.globl vector144
vector144:
  pushl $0
80107e2a:	6a 00                	push   $0x0
  pushl $144
80107e2c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107e31:	e9 32 f4 ff ff       	jmp    80107268 <alltraps>

80107e36 <vector145>:
.globl vector145
vector145:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $145
80107e38:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107e3d:	e9 26 f4 ff ff       	jmp    80107268 <alltraps>

80107e42 <vector146>:
.globl vector146
vector146:
  pushl $0
80107e42:	6a 00                	push   $0x0
  pushl $146
80107e44:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107e49:	e9 1a f4 ff ff       	jmp    80107268 <alltraps>

80107e4e <vector147>:
.globl vector147
vector147:
  pushl $0
80107e4e:	6a 00                	push   $0x0
  pushl $147
80107e50:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107e55:	e9 0e f4 ff ff       	jmp    80107268 <alltraps>

80107e5a <vector148>:
.globl vector148
vector148:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $148
80107e5c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107e61:	e9 02 f4 ff ff       	jmp    80107268 <alltraps>

80107e66 <vector149>:
.globl vector149
vector149:
  pushl $0
80107e66:	6a 00                	push   $0x0
  pushl $149
80107e68:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107e6d:	e9 f6 f3 ff ff       	jmp    80107268 <alltraps>

80107e72 <vector150>:
.globl vector150
vector150:
  pushl $0
80107e72:	6a 00                	push   $0x0
  pushl $150
80107e74:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107e79:	e9 ea f3 ff ff       	jmp    80107268 <alltraps>

80107e7e <vector151>:
.globl vector151
vector151:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $151
80107e80:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107e85:	e9 de f3 ff ff       	jmp    80107268 <alltraps>

80107e8a <vector152>:
.globl vector152
vector152:
  pushl $0
80107e8a:	6a 00                	push   $0x0
  pushl $152
80107e8c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107e91:	e9 d2 f3 ff ff       	jmp    80107268 <alltraps>

80107e96 <vector153>:
.globl vector153
vector153:
  pushl $0
80107e96:	6a 00                	push   $0x0
  pushl $153
80107e98:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107e9d:	e9 c6 f3 ff ff       	jmp    80107268 <alltraps>

80107ea2 <vector154>:
.globl vector154
vector154:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $154
80107ea4:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107ea9:	e9 ba f3 ff ff       	jmp    80107268 <alltraps>

80107eae <vector155>:
.globl vector155
vector155:
  pushl $0
80107eae:	6a 00                	push   $0x0
  pushl $155
80107eb0:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107eb5:	e9 ae f3 ff ff       	jmp    80107268 <alltraps>

80107eba <vector156>:
.globl vector156
vector156:
  pushl $0
80107eba:	6a 00                	push   $0x0
  pushl $156
80107ebc:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107ec1:	e9 a2 f3 ff ff       	jmp    80107268 <alltraps>

80107ec6 <vector157>:
.globl vector157
vector157:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $157
80107ec8:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ecd:	e9 96 f3 ff ff       	jmp    80107268 <alltraps>

80107ed2 <vector158>:
.globl vector158
vector158:
  pushl $0
80107ed2:	6a 00                	push   $0x0
  pushl $158
80107ed4:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107ed9:	e9 8a f3 ff ff       	jmp    80107268 <alltraps>

80107ede <vector159>:
.globl vector159
vector159:
  pushl $0
80107ede:	6a 00                	push   $0x0
  pushl $159
80107ee0:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107ee5:	e9 7e f3 ff ff       	jmp    80107268 <alltraps>

80107eea <vector160>:
.globl vector160
vector160:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $160
80107eec:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107ef1:	e9 72 f3 ff ff       	jmp    80107268 <alltraps>

80107ef6 <vector161>:
.globl vector161
vector161:
  pushl $0
80107ef6:	6a 00                	push   $0x0
  pushl $161
80107ef8:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107efd:	e9 66 f3 ff ff       	jmp    80107268 <alltraps>

80107f02 <vector162>:
.globl vector162
vector162:
  pushl $0
80107f02:	6a 00                	push   $0x0
  pushl $162
80107f04:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107f09:	e9 5a f3 ff ff       	jmp    80107268 <alltraps>

80107f0e <vector163>:
.globl vector163
vector163:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $163
80107f10:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107f15:	e9 4e f3 ff ff       	jmp    80107268 <alltraps>

80107f1a <vector164>:
.globl vector164
vector164:
  pushl $0
80107f1a:	6a 00                	push   $0x0
  pushl $164
80107f1c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107f21:	e9 42 f3 ff ff       	jmp    80107268 <alltraps>

80107f26 <vector165>:
.globl vector165
vector165:
  pushl $0
80107f26:	6a 00                	push   $0x0
  pushl $165
80107f28:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107f2d:	e9 36 f3 ff ff       	jmp    80107268 <alltraps>

80107f32 <vector166>:
.globl vector166
vector166:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $166
80107f34:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107f39:	e9 2a f3 ff ff       	jmp    80107268 <alltraps>

80107f3e <vector167>:
.globl vector167
vector167:
  pushl $0
80107f3e:	6a 00                	push   $0x0
  pushl $167
80107f40:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107f45:	e9 1e f3 ff ff       	jmp    80107268 <alltraps>

80107f4a <vector168>:
.globl vector168
vector168:
  pushl $0
80107f4a:	6a 00                	push   $0x0
  pushl $168
80107f4c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107f51:	e9 12 f3 ff ff       	jmp    80107268 <alltraps>

80107f56 <vector169>:
.globl vector169
vector169:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $169
80107f58:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107f5d:	e9 06 f3 ff ff       	jmp    80107268 <alltraps>

80107f62 <vector170>:
.globl vector170
vector170:
  pushl $0
80107f62:	6a 00                	push   $0x0
  pushl $170
80107f64:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107f69:	e9 fa f2 ff ff       	jmp    80107268 <alltraps>

80107f6e <vector171>:
.globl vector171
vector171:
  pushl $0
80107f6e:	6a 00                	push   $0x0
  pushl $171
80107f70:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107f75:	e9 ee f2 ff ff       	jmp    80107268 <alltraps>

80107f7a <vector172>:
.globl vector172
vector172:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $172
80107f7c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107f81:	e9 e2 f2 ff ff       	jmp    80107268 <alltraps>

80107f86 <vector173>:
.globl vector173
vector173:
  pushl $0
80107f86:	6a 00                	push   $0x0
  pushl $173
80107f88:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107f8d:	e9 d6 f2 ff ff       	jmp    80107268 <alltraps>

80107f92 <vector174>:
.globl vector174
vector174:
  pushl $0
80107f92:	6a 00                	push   $0x0
  pushl $174
80107f94:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107f99:	e9 ca f2 ff ff       	jmp    80107268 <alltraps>

80107f9e <vector175>:
.globl vector175
vector175:
  pushl $0
80107f9e:	6a 00                	push   $0x0
  pushl $175
80107fa0:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107fa5:	e9 be f2 ff ff       	jmp    80107268 <alltraps>

80107faa <vector176>:
.globl vector176
vector176:
  pushl $0
80107faa:	6a 00                	push   $0x0
  pushl $176
80107fac:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107fb1:	e9 b2 f2 ff ff       	jmp    80107268 <alltraps>

80107fb6 <vector177>:
.globl vector177
vector177:
  pushl $0
80107fb6:	6a 00                	push   $0x0
  pushl $177
80107fb8:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107fbd:	e9 a6 f2 ff ff       	jmp    80107268 <alltraps>

80107fc2 <vector178>:
.globl vector178
vector178:
  pushl $0
80107fc2:	6a 00                	push   $0x0
  pushl $178
80107fc4:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107fc9:	e9 9a f2 ff ff       	jmp    80107268 <alltraps>

80107fce <vector179>:
.globl vector179
vector179:
  pushl $0
80107fce:	6a 00                	push   $0x0
  pushl $179
80107fd0:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107fd5:	e9 8e f2 ff ff       	jmp    80107268 <alltraps>

80107fda <vector180>:
.globl vector180
vector180:
  pushl $0
80107fda:	6a 00                	push   $0x0
  pushl $180
80107fdc:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107fe1:	e9 82 f2 ff ff       	jmp    80107268 <alltraps>

80107fe6 <vector181>:
.globl vector181
vector181:
  pushl $0
80107fe6:	6a 00                	push   $0x0
  pushl $181
80107fe8:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107fed:	e9 76 f2 ff ff       	jmp    80107268 <alltraps>

80107ff2 <vector182>:
.globl vector182
vector182:
  pushl $0
80107ff2:	6a 00                	push   $0x0
  pushl $182
80107ff4:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107ff9:	e9 6a f2 ff ff       	jmp    80107268 <alltraps>

80107ffe <vector183>:
.globl vector183
vector183:
  pushl $0
80107ffe:	6a 00                	push   $0x0
  pushl $183
80108000:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80108005:	e9 5e f2 ff ff       	jmp    80107268 <alltraps>

8010800a <vector184>:
.globl vector184
vector184:
  pushl $0
8010800a:	6a 00                	push   $0x0
  pushl $184
8010800c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108011:	e9 52 f2 ff ff       	jmp    80107268 <alltraps>

80108016 <vector185>:
.globl vector185
vector185:
  pushl $0
80108016:	6a 00                	push   $0x0
  pushl $185
80108018:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010801d:	e9 46 f2 ff ff       	jmp    80107268 <alltraps>

80108022 <vector186>:
.globl vector186
vector186:
  pushl $0
80108022:	6a 00                	push   $0x0
  pushl $186
80108024:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108029:	e9 3a f2 ff ff       	jmp    80107268 <alltraps>

8010802e <vector187>:
.globl vector187
vector187:
  pushl $0
8010802e:	6a 00                	push   $0x0
  pushl $187
80108030:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80108035:	e9 2e f2 ff ff       	jmp    80107268 <alltraps>

8010803a <vector188>:
.globl vector188
vector188:
  pushl $0
8010803a:	6a 00                	push   $0x0
  pushl $188
8010803c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108041:	e9 22 f2 ff ff       	jmp    80107268 <alltraps>

80108046 <vector189>:
.globl vector189
vector189:
  pushl $0
80108046:	6a 00                	push   $0x0
  pushl $189
80108048:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010804d:	e9 16 f2 ff ff       	jmp    80107268 <alltraps>

80108052 <vector190>:
.globl vector190
vector190:
  pushl $0
80108052:	6a 00                	push   $0x0
  pushl $190
80108054:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108059:	e9 0a f2 ff ff       	jmp    80107268 <alltraps>

8010805e <vector191>:
.globl vector191
vector191:
  pushl $0
8010805e:	6a 00                	push   $0x0
  pushl $191
80108060:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108065:	e9 fe f1 ff ff       	jmp    80107268 <alltraps>

8010806a <vector192>:
.globl vector192
vector192:
  pushl $0
8010806a:	6a 00                	push   $0x0
  pushl $192
8010806c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108071:	e9 f2 f1 ff ff       	jmp    80107268 <alltraps>

80108076 <vector193>:
.globl vector193
vector193:
  pushl $0
80108076:	6a 00                	push   $0x0
  pushl $193
80108078:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010807d:	e9 e6 f1 ff ff       	jmp    80107268 <alltraps>

80108082 <vector194>:
.globl vector194
vector194:
  pushl $0
80108082:	6a 00                	push   $0x0
  pushl $194
80108084:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108089:	e9 da f1 ff ff       	jmp    80107268 <alltraps>

8010808e <vector195>:
.globl vector195
vector195:
  pushl $0
8010808e:	6a 00                	push   $0x0
  pushl $195
80108090:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80108095:	e9 ce f1 ff ff       	jmp    80107268 <alltraps>

8010809a <vector196>:
.globl vector196
vector196:
  pushl $0
8010809a:	6a 00                	push   $0x0
  pushl $196
8010809c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801080a1:	e9 c2 f1 ff ff       	jmp    80107268 <alltraps>

801080a6 <vector197>:
.globl vector197
vector197:
  pushl $0
801080a6:	6a 00                	push   $0x0
  pushl $197
801080a8:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801080ad:	e9 b6 f1 ff ff       	jmp    80107268 <alltraps>

801080b2 <vector198>:
.globl vector198
vector198:
  pushl $0
801080b2:	6a 00                	push   $0x0
  pushl $198
801080b4:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801080b9:	e9 aa f1 ff ff       	jmp    80107268 <alltraps>

801080be <vector199>:
.globl vector199
vector199:
  pushl $0
801080be:	6a 00                	push   $0x0
  pushl $199
801080c0:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801080c5:	e9 9e f1 ff ff       	jmp    80107268 <alltraps>

801080ca <vector200>:
.globl vector200
vector200:
  pushl $0
801080ca:	6a 00                	push   $0x0
  pushl $200
801080cc:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801080d1:	e9 92 f1 ff ff       	jmp    80107268 <alltraps>

801080d6 <vector201>:
.globl vector201
vector201:
  pushl $0
801080d6:	6a 00                	push   $0x0
  pushl $201
801080d8:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801080dd:	e9 86 f1 ff ff       	jmp    80107268 <alltraps>

801080e2 <vector202>:
.globl vector202
vector202:
  pushl $0
801080e2:	6a 00                	push   $0x0
  pushl $202
801080e4:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801080e9:	e9 7a f1 ff ff       	jmp    80107268 <alltraps>

801080ee <vector203>:
.globl vector203
vector203:
  pushl $0
801080ee:	6a 00                	push   $0x0
  pushl $203
801080f0:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801080f5:	e9 6e f1 ff ff       	jmp    80107268 <alltraps>

801080fa <vector204>:
.globl vector204
vector204:
  pushl $0
801080fa:	6a 00                	push   $0x0
  pushl $204
801080fc:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108101:	e9 62 f1 ff ff       	jmp    80107268 <alltraps>

80108106 <vector205>:
.globl vector205
vector205:
  pushl $0
80108106:	6a 00                	push   $0x0
  pushl $205
80108108:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
8010810d:	e9 56 f1 ff ff       	jmp    80107268 <alltraps>

80108112 <vector206>:
.globl vector206
vector206:
  pushl $0
80108112:	6a 00                	push   $0x0
  pushl $206
80108114:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108119:	e9 4a f1 ff ff       	jmp    80107268 <alltraps>

8010811e <vector207>:
.globl vector207
vector207:
  pushl $0
8010811e:	6a 00                	push   $0x0
  pushl $207
80108120:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80108125:	e9 3e f1 ff ff       	jmp    80107268 <alltraps>

8010812a <vector208>:
.globl vector208
vector208:
  pushl $0
8010812a:	6a 00                	push   $0x0
  pushl $208
8010812c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108131:	e9 32 f1 ff ff       	jmp    80107268 <alltraps>

80108136 <vector209>:
.globl vector209
vector209:
  pushl $0
80108136:	6a 00                	push   $0x0
  pushl $209
80108138:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010813d:	e9 26 f1 ff ff       	jmp    80107268 <alltraps>

80108142 <vector210>:
.globl vector210
vector210:
  pushl $0
80108142:	6a 00                	push   $0x0
  pushl $210
80108144:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108149:	e9 1a f1 ff ff       	jmp    80107268 <alltraps>

8010814e <vector211>:
.globl vector211
vector211:
  pushl $0
8010814e:	6a 00                	push   $0x0
  pushl $211
80108150:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108155:	e9 0e f1 ff ff       	jmp    80107268 <alltraps>

8010815a <vector212>:
.globl vector212
vector212:
  pushl $0
8010815a:	6a 00                	push   $0x0
  pushl $212
8010815c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108161:	e9 02 f1 ff ff       	jmp    80107268 <alltraps>

80108166 <vector213>:
.globl vector213
vector213:
  pushl $0
80108166:	6a 00                	push   $0x0
  pushl $213
80108168:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010816d:	e9 f6 f0 ff ff       	jmp    80107268 <alltraps>

80108172 <vector214>:
.globl vector214
vector214:
  pushl $0
80108172:	6a 00                	push   $0x0
  pushl $214
80108174:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108179:	e9 ea f0 ff ff       	jmp    80107268 <alltraps>

8010817e <vector215>:
.globl vector215
vector215:
  pushl $0
8010817e:	6a 00                	push   $0x0
  pushl $215
80108180:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80108185:	e9 de f0 ff ff       	jmp    80107268 <alltraps>

8010818a <vector216>:
.globl vector216
vector216:
  pushl $0
8010818a:	6a 00                	push   $0x0
  pushl $216
8010818c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108191:	e9 d2 f0 ff ff       	jmp    80107268 <alltraps>

80108196 <vector217>:
.globl vector217
vector217:
  pushl $0
80108196:	6a 00                	push   $0x0
  pushl $217
80108198:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010819d:	e9 c6 f0 ff ff       	jmp    80107268 <alltraps>

801081a2 <vector218>:
.globl vector218
vector218:
  pushl $0
801081a2:	6a 00                	push   $0x0
  pushl $218
801081a4:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801081a9:	e9 ba f0 ff ff       	jmp    80107268 <alltraps>

801081ae <vector219>:
.globl vector219
vector219:
  pushl $0
801081ae:	6a 00                	push   $0x0
  pushl $219
801081b0:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801081b5:	e9 ae f0 ff ff       	jmp    80107268 <alltraps>

801081ba <vector220>:
.globl vector220
vector220:
  pushl $0
801081ba:	6a 00                	push   $0x0
  pushl $220
801081bc:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801081c1:	e9 a2 f0 ff ff       	jmp    80107268 <alltraps>

801081c6 <vector221>:
.globl vector221
vector221:
  pushl $0
801081c6:	6a 00                	push   $0x0
  pushl $221
801081c8:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801081cd:	e9 96 f0 ff ff       	jmp    80107268 <alltraps>

801081d2 <vector222>:
.globl vector222
vector222:
  pushl $0
801081d2:	6a 00                	push   $0x0
  pushl $222
801081d4:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801081d9:	e9 8a f0 ff ff       	jmp    80107268 <alltraps>

801081de <vector223>:
.globl vector223
vector223:
  pushl $0
801081de:	6a 00                	push   $0x0
  pushl $223
801081e0:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801081e5:	e9 7e f0 ff ff       	jmp    80107268 <alltraps>

801081ea <vector224>:
.globl vector224
vector224:
  pushl $0
801081ea:	6a 00                	push   $0x0
  pushl $224
801081ec:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801081f1:	e9 72 f0 ff ff       	jmp    80107268 <alltraps>

801081f6 <vector225>:
.globl vector225
vector225:
  pushl $0
801081f6:	6a 00                	push   $0x0
  pushl $225
801081f8:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801081fd:	e9 66 f0 ff ff       	jmp    80107268 <alltraps>

80108202 <vector226>:
.globl vector226
vector226:
  pushl $0
80108202:	6a 00                	push   $0x0
  pushl $226
80108204:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108209:	e9 5a f0 ff ff       	jmp    80107268 <alltraps>

8010820e <vector227>:
.globl vector227
vector227:
  pushl $0
8010820e:	6a 00                	push   $0x0
  pushl $227
80108210:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80108215:	e9 4e f0 ff ff       	jmp    80107268 <alltraps>

8010821a <vector228>:
.globl vector228
vector228:
  pushl $0
8010821a:	6a 00                	push   $0x0
  pushl $228
8010821c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108221:	e9 42 f0 ff ff       	jmp    80107268 <alltraps>

80108226 <vector229>:
.globl vector229
vector229:
  pushl $0
80108226:	6a 00                	push   $0x0
  pushl $229
80108228:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010822d:	e9 36 f0 ff ff       	jmp    80107268 <alltraps>

80108232 <vector230>:
.globl vector230
vector230:
  pushl $0
80108232:	6a 00                	push   $0x0
  pushl $230
80108234:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108239:	e9 2a f0 ff ff       	jmp    80107268 <alltraps>

8010823e <vector231>:
.globl vector231
vector231:
  pushl $0
8010823e:	6a 00                	push   $0x0
  pushl $231
80108240:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108245:	e9 1e f0 ff ff       	jmp    80107268 <alltraps>

8010824a <vector232>:
.globl vector232
vector232:
  pushl $0
8010824a:	6a 00                	push   $0x0
  pushl $232
8010824c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108251:	e9 12 f0 ff ff       	jmp    80107268 <alltraps>

80108256 <vector233>:
.globl vector233
vector233:
  pushl $0
80108256:	6a 00                	push   $0x0
  pushl $233
80108258:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010825d:	e9 06 f0 ff ff       	jmp    80107268 <alltraps>

80108262 <vector234>:
.globl vector234
vector234:
  pushl $0
80108262:	6a 00                	push   $0x0
  pushl $234
80108264:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108269:	e9 fa ef ff ff       	jmp    80107268 <alltraps>

8010826e <vector235>:
.globl vector235
vector235:
  pushl $0
8010826e:	6a 00                	push   $0x0
  pushl $235
80108270:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80108275:	e9 ee ef ff ff       	jmp    80107268 <alltraps>

8010827a <vector236>:
.globl vector236
vector236:
  pushl $0
8010827a:	6a 00                	push   $0x0
  pushl $236
8010827c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108281:	e9 e2 ef ff ff       	jmp    80107268 <alltraps>

80108286 <vector237>:
.globl vector237
vector237:
  pushl $0
80108286:	6a 00                	push   $0x0
  pushl $237
80108288:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010828d:	e9 d6 ef ff ff       	jmp    80107268 <alltraps>

80108292 <vector238>:
.globl vector238
vector238:
  pushl $0
80108292:	6a 00                	push   $0x0
  pushl $238
80108294:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108299:	e9 ca ef ff ff       	jmp    80107268 <alltraps>

8010829e <vector239>:
.globl vector239
vector239:
  pushl $0
8010829e:	6a 00                	push   $0x0
  pushl $239
801082a0:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801082a5:	e9 be ef ff ff       	jmp    80107268 <alltraps>

801082aa <vector240>:
.globl vector240
vector240:
  pushl $0
801082aa:	6a 00                	push   $0x0
  pushl $240
801082ac:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801082b1:	e9 b2 ef ff ff       	jmp    80107268 <alltraps>

801082b6 <vector241>:
.globl vector241
vector241:
  pushl $0
801082b6:	6a 00                	push   $0x0
  pushl $241
801082b8:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801082bd:	e9 a6 ef ff ff       	jmp    80107268 <alltraps>

801082c2 <vector242>:
.globl vector242
vector242:
  pushl $0
801082c2:	6a 00                	push   $0x0
  pushl $242
801082c4:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801082c9:	e9 9a ef ff ff       	jmp    80107268 <alltraps>

801082ce <vector243>:
.globl vector243
vector243:
  pushl $0
801082ce:	6a 00                	push   $0x0
  pushl $243
801082d0:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801082d5:	e9 8e ef ff ff       	jmp    80107268 <alltraps>

801082da <vector244>:
.globl vector244
vector244:
  pushl $0
801082da:	6a 00                	push   $0x0
  pushl $244
801082dc:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801082e1:	e9 82 ef ff ff       	jmp    80107268 <alltraps>

801082e6 <vector245>:
.globl vector245
vector245:
  pushl $0
801082e6:	6a 00                	push   $0x0
  pushl $245
801082e8:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801082ed:	e9 76 ef ff ff       	jmp    80107268 <alltraps>

801082f2 <vector246>:
.globl vector246
vector246:
  pushl $0
801082f2:	6a 00                	push   $0x0
  pushl $246
801082f4:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801082f9:	e9 6a ef ff ff       	jmp    80107268 <alltraps>

801082fe <vector247>:
.globl vector247
vector247:
  pushl $0
801082fe:	6a 00                	push   $0x0
  pushl $247
80108300:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108305:	e9 5e ef ff ff       	jmp    80107268 <alltraps>

8010830a <vector248>:
.globl vector248
vector248:
  pushl $0
8010830a:	6a 00                	push   $0x0
  pushl $248
8010830c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108311:	e9 52 ef ff ff       	jmp    80107268 <alltraps>

80108316 <vector249>:
.globl vector249
vector249:
  pushl $0
80108316:	6a 00                	push   $0x0
  pushl $249
80108318:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
8010831d:	e9 46 ef ff ff       	jmp    80107268 <alltraps>

80108322 <vector250>:
.globl vector250
vector250:
  pushl $0
80108322:	6a 00                	push   $0x0
  pushl $250
80108324:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108329:	e9 3a ef ff ff       	jmp    80107268 <alltraps>

8010832e <vector251>:
.globl vector251
vector251:
  pushl $0
8010832e:	6a 00                	push   $0x0
  pushl $251
80108330:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108335:	e9 2e ef ff ff       	jmp    80107268 <alltraps>

8010833a <vector252>:
.globl vector252
vector252:
  pushl $0
8010833a:	6a 00                	push   $0x0
  pushl $252
8010833c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108341:	e9 22 ef ff ff       	jmp    80107268 <alltraps>

80108346 <vector253>:
.globl vector253
vector253:
  pushl $0
80108346:	6a 00                	push   $0x0
  pushl $253
80108348:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
8010834d:	e9 16 ef ff ff       	jmp    80107268 <alltraps>

80108352 <vector254>:
.globl vector254
vector254:
  pushl $0
80108352:	6a 00                	push   $0x0
  pushl $254
80108354:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108359:	e9 0a ef ff ff       	jmp    80107268 <alltraps>

8010835e <vector255>:
.globl vector255
vector255:
  pushl $0
8010835e:	6a 00                	push   $0x0
  pushl $255
80108360:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108365:	e9 fe ee ff ff       	jmp    80107268 <alltraps>
	...

8010836c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010836c:	55                   	push   %ebp
8010836d:	89 e5                	mov    %esp,%ebp
8010836f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108372:	8b 45 0c             	mov    0xc(%ebp),%eax
80108375:	83 e8 01             	sub    $0x1,%eax
80108378:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010837c:	8b 45 08             	mov    0x8(%ebp),%eax
8010837f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108383:	8b 45 08             	mov    0x8(%ebp),%eax
80108386:	c1 e8 10             	shr    $0x10,%eax
80108389:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010838d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108390:	0f 01 10             	lgdtl  (%eax)
}
80108393:	c9                   	leave  
80108394:	c3                   	ret    

80108395 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80108395:	55                   	push   %ebp
80108396:	89 e5                	mov    %esp,%ebp
80108398:	83 ec 04             	sub    $0x4,%esp
8010839b:	8b 45 08             	mov    0x8(%ebp),%eax
8010839e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801083a2:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801083a6:	0f 00 d8             	ltr    %ax
}
801083a9:	c9                   	leave  
801083aa:	c3                   	ret    

801083ab <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801083ab:	55                   	push   %ebp
801083ac:	89 e5                	mov    %esp,%ebp
801083ae:	83 ec 04             	sub    $0x4,%esp
801083b1:	8b 45 08             	mov    0x8(%ebp),%eax
801083b4:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801083b8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801083bc:	8e e8                	mov    %eax,%gs
}
801083be:	c9                   	leave  
801083bf:	c3                   	ret    

801083c0 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801083c0:	55                   	push   %ebp
801083c1:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801083c3:	8b 45 08             	mov    0x8(%ebp),%eax
801083c6:	0f 22 d8             	mov    %eax,%cr3
}
801083c9:	5d                   	pop    %ebp
801083ca:	c3                   	ret    

801083cb <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801083cb:	55                   	push   %ebp
801083cc:	89 e5                	mov    %esp,%ebp
801083ce:	8b 45 08             	mov    0x8(%ebp),%eax
801083d1:	05 00 00 00 80       	add    $0x80000000,%eax
801083d6:	5d                   	pop    %ebp
801083d7:	c3                   	ret    

801083d8 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801083d8:	55                   	push   %ebp
801083d9:	89 e5                	mov    %esp,%ebp
801083db:	8b 45 08             	mov    0x8(%ebp),%eax
801083de:	05 00 00 00 80       	add    $0x80000000,%eax
801083e3:	5d                   	pop    %ebp
801083e4:	c3                   	ret    

801083e5 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801083e5:	55                   	push   %ebp
801083e6:	89 e5                	mov    %esp,%ebp
801083e8:	53                   	push   %ebx
801083e9:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801083ec:	e8 4c b9 ff ff       	call   80103d3d <cpunum>
801083f1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801083f7:	05 40 09 11 80       	add    $0x80110940,%eax
801083fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801083ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108402:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840b:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108414:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108418:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010841b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010841f:	83 e2 f0             	and    $0xfffffff0,%edx
80108422:	83 ca 0a             	or     $0xa,%edx
80108425:	88 50 7d             	mov    %dl,0x7d(%eax)
80108428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010842f:	83 ca 10             	or     $0x10,%edx
80108432:	88 50 7d             	mov    %dl,0x7d(%eax)
80108435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108438:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010843c:	83 e2 9f             	and    $0xffffff9f,%edx
8010843f:	88 50 7d             	mov    %dl,0x7d(%eax)
80108442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108445:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108449:	83 ca 80             	or     $0xffffff80,%edx
8010844c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010844f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108452:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108456:	83 ca 0f             	or     $0xf,%edx
80108459:	88 50 7e             	mov    %dl,0x7e(%eax)
8010845c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108463:	83 e2 ef             	and    $0xffffffef,%edx
80108466:	88 50 7e             	mov    %dl,0x7e(%eax)
80108469:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010846c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108470:	83 e2 df             	and    $0xffffffdf,%edx
80108473:	88 50 7e             	mov    %dl,0x7e(%eax)
80108476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108479:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010847d:	83 ca 40             	or     $0x40,%edx
80108480:	88 50 7e             	mov    %dl,0x7e(%eax)
80108483:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108486:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010848a:	83 ca 80             	or     $0xffffff80,%edx
8010848d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108490:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108493:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80108497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801084a1:	ff ff 
801084a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a6:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801084ad:	00 00 
801084af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084b2:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801084b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084bc:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084c3:	83 e2 f0             	and    $0xfffffff0,%edx
801084c6:	83 ca 02             	or     $0x2,%edx
801084c9:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d2:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084d9:	83 ca 10             	or     $0x10,%edx
801084dc:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e5:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084ec:	83 e2 9f             	and    $0xffffff9f,%edx
801084ef:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084ff:	83 ca 80             	or     $0xffffff80,%edx
80108502:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108508:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108512:	83 ca 0f             	or     $0xf,%edx
80108515:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010851b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010851e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108525:	83 e2 ef             	and    $0xffffffef,%edx
80108528:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010852e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108531:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108538:	83 e2 df             	and    $0xffffffdf,%edx
8010853b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108541:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108544:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010854b:	83 ca 40             	or     $0x40,%edx
8010854e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108557:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010855e:	83 ca 80             	or     $0xffffff80,%edx
80108561:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108571:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108574:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010857b:	ff ff 
8010857d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108580:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80108587:	00 00 
80108589:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010858c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80108593:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108596:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010859d:	83 e2 f0             	and    $0xfffffff0,%edx
801085a0:	83 ca 0a             	or     $0xa,%edx
801085a3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ac:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085b3:	83 ca 10             	or     $0x10,%edx
801085b6:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085bf:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085c6:	83 ca 60             	or     $0x60,%edx
801085c9:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085d9:	83 ca 80             	or     $0xffffff80,%edx
801085dc:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801085ec:	83 ca 0f             	or     $0xf,%edx
801085ef:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801085f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801085ff:	83 e2 ef             	and    $0xffffffef,%edx
80108602:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108608:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108612:	83 e2 df             	and    $0xffffffdf,%edx
80108615:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010861b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108625:	83 ca 40             	or     $0x40,%edx
80108628:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010862e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108631:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108638:	83 ca 80             	or     $0xffffff80,%edx
8010863b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108641:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108644:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010864b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010864e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108655:	ff ff 
80108657:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010865a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108661:	00 00 
80108663:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108666:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010866d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108670:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108677:	83 e2 f0             	and    $0xfffffff0,%edx
8010867a:	83 ca 02             	or     $0x2,%edx
8010867d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108683:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108686:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010868d:	83 ca 10             	or     $0x10,%edx
80108690:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108696:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108699:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086a0:	83 ca 60             	or     $0x60,%edx
801086a3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ac:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086b3:	83 ca 80             	or     $0xffffff80,%edx
801086b6:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086bf:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086c6:	83 ca 0f             	or     $0xf,%edx
801086c9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086d2:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086d9:	83 e2 ef             	and    $0xffffffef,%edx
801086dc:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086e5:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086ec:	83 e2 df             	and    $0xffffffdf,%edx
801086ef:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086ff:	83 ca 40             	or     $0x40,%edx
80108702:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108708:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010870b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108712:	83 ca 80             	or     $0xffffff80,%edx
80108715:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010871b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010871e:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108728:	05 b4 00 00 00       	add    $0xb4,%eax
8010872d:	89 c3                	mov    %eax,%ebx
8010872f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108732:	05 b4 00 00 00       	add    $0xb4,%eax
80108737:	c1 e8 10             	shr    $0x10,%eax
8010873a:	89 c1                	mov    %eax,%ecx
8010873c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010873f:	05 b4 00 00 00       	add    $0xb4,%eax
80108744:	c1 e8 18             	shr    $0x18,%eax
80108747:	89 c2                	mov    %eax,%edx
80108749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010874c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108753:	00 00 
80108755:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108758:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010875f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108762:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108768:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010876b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108772:	83 e1 f0             	and    $0xfffffff0,%ecx
80108775:	83 c9 02             	or     $0x2,%ecx
80108778:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010877e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108781:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108788:	83 c9 10             	or     $0x10,%ecx
8010878b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108791:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108794:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010879b:	83 e1 9f             	and    $0xffffff9f,%ecx
8010879e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087a7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801087ae:	83 c9 80             	or     $0xffffff80,%ecx
801087b1:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ba:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087c1:	83 e1 f0             	and    $0xfffffff0,%ecx
801087c4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087cd:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087d4:	83 e1 ef             	and    $0xffffffef,%ecx
801087d7:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e0:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087e7:	83 e1 df             	and    $0xffffffdf,%ecx
801087ea:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087fa:	83 c9 40             	or     $0x40,%ecx
801087fd:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108806:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010880d:	83 c9 80             	or     $0xffffff80,%ecx
80108810:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108816:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108819:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010881f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108822:	83 c0 70             	add    $0x70,%eax
80108825:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
8010882c:	00 
8010882d:	89 04 24             	mov    %eax,(%esp)
80108830:	e8 37 fb ff ff       	call   8010836c <lgdt>
  loadgs(SEG_KCPU << 3);
80108835:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
8010883c:	e8 6a fb ff ff       	call   801083ab <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108844:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010884a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108851:	00 00 00 00 
}
80108855:	83 c4 24             	add    $0x24,%esp
80108858:	5b                   	pop    %ebx
80108859:	5d                   	pop    %ebp
8010885a:	c3                   	ret    

8010885b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010885b:	55                   	push   %ebp
8010885c:	89 e5                	mov    %esp,%ebp
8010885e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108861:	8b 45 0c             	mov    0xc(%ebp),%eax
80108864:	c1 e8 16             	shr    $0x16,%eax
80108867:	c1 e0 02             	shl    $0x2,%eax
8010886a:	03 45 08             	add    0x8(%ebp),%eax
8010886d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108870:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108873:	8b 00                	mov    (%eax),%eax
80108875:	83 e0 01             	and    $0x1,%eax
80108878:	84 c0                	test   %al,%al
8010887a:	74 17                	je     80108893 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
8010887c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010887f:	8b 00                	mov    (%eax),%eax
80108881:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108886:	89 04 24             	mov    %eax,(%esp)
80108889:	e8 4a fb ff ff       	call   801083d8 <p2v>
8010888e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108891:	eb 4b                	jmp    801088de <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108893:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108897:	74 0e                	je     801088a7 <walkpgdir+0x4c>
80108899:	e8 11 b1 ff ff       	call   801039af <kalloc>
8010889e:	89 45 f4             	mov    %eax,-0xc(%ebp)
801088a1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801088a5:	75 07                	jne    801088ae <walkpgdir+0x53>
      return 0;
801088a7:	b8 00 00 00 00       	mov    $0x0,%eax
801088ac:	eb 41                	jmp    801088ef <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801088ae:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801088b5:	00 
801088b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801088bd:	00 
801088be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c1:	89 04 24             	mov    %eax,(%esp)
801088c4:	e8 d9 d3 ff ff       	call   80105ca2 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801088c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088cc:	89 04 24             	mov    %eax,(%esp)
801088cf:	e8 f7 fa ff ff       	call   801083cb <v2p>
801088d4:	89 c2                	mov    %eax,%edx
801088d6:	83 ca 07             	or     $0x7,%edx
801088d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088dc:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801088de:	8b 45 0c             	mov    0xc(%ebp),%eax
801088e1:	c1 e8 0c             	shr    $0xc,%eax
801088e4:	25 ff 03 00 00       	and    $0x3ff,%eax
801088e9:	c1 e0 02             	shl    $0x2,%eax
801088ec:	03 45 f4             	add    -0xc(%ebp),%eax
}
801088ef:	c9                   	leave  
801088f0:	c3                   	ret    

801088f1 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801088f1:	55                   	push   %ebp
801088f2:	89 e5                	mov    %esp,%ebp
801088f4:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801088f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801088fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108902:	8b 45 0c             	mov    0xc(%ebp),%eax
80108905:	03 45 10             	add    0x10(%ebp),%eax
80108908:	83 e8 01             	sub    $0x1,%eax
8010890b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108910:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108913:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010891a:	00 
8010891b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010891e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108922:	8b 45 08             	mov    0x8(%ebp),%eax
80108925:	89 04 24             	mov    %eax,(%esp)
80108928:	e8 2e ff ff ff       	call   8010885b <walkpgdir>
8010892d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108930:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108934:	75 07                	jne    8010893d <mappages+0x4c>
      return -1;
80108936:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010893b:	eb 46                	jmp    80108983 <mappages+0x92>
    if(*pte & PTE_P)
8010893d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108940:	8b 00                	mov    (%eax),%eax
80108942:	83 e0 01             	and    $0x1,%eax
80108945:	84 c0                	test   %al,%al
80108947:	74 0c                	je     80108955 <mappages+0x64>
      panic("remap");
80108949:	c7 04 24 38 9a 10 80 	movl   $0x80109a38,(%esp)
80108950:	e8 e8 7b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108955:	8b 45 18             	mov    0x18(%ebp),%eax
80108958:	0b 45 14             	or     0x14(%ebp),%eax
8010895b:	89 c2                	mov    %eax,%edx
8010895d:	83 ca 01             	or     $0x1,%edx
80108960:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108963:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108965:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108968:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010896b:	74 10                	je     8010897d <mappages+0x8c>
      break;
    a += PGSIZE;
8010896d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108974:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010897b:	eb 96                	jmp    80108913 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
8010897d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010897e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108983:	c9                   	leave  
80108984:	c3                   	ret    

80108985 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108985:	55                   	push   %ebp
80108986:	89 e5                	mov    %esp,%ebp
80108988:	53                   	push   %ebx
80108989:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
8010898c:	e8 1e b0 ff ff       	call   801039af <kalloc>
80108991:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108994:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108998:	75 0a                	jne    801089a4 <setupkvm+0x1f>
    return 0;
8010899a:	b8 00 00 00 00       	mov    $0x0,%eax
8010899f:	e9 98 00 00 00       	jmp    80108a3c <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801089a4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089ab:	00 
801089ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089b3:	00 
801089b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089b7:	89 04 24             	mov    %eax,(%esp)
801089ba:	e8 e3 d2 ff ff       	call   80105ca2 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801089bf:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801089c6:	e8 0d fa ff ff       	call   801083d8 <p2v>
801089cb:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801089d0:	76 0c                	jbe    801089de <setupkvm+0x59>
    panic("PHYSTOP too high");
801089d2:	c7 04 24 3e 9a 10 80 	movl   $0x80109a3e,(%esp)
801089d9:	e8 5f 7b ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801089de:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
801089e5:	eb 49                	jmp    80108a30 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801089e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801089ea:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801089ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801089f0:	8b 50 04             	mov    0x4(%eax),%edx
801089f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f6:	8b 58 08             	mov    0x8(%eax),%ebx
801089f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fc:	8b 40 04             	mov    0x4(%eax),%eax
801089ff:	29 c3                	sub    %eax,%ebx
80108a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a04:	8b 00                	mov    (%eax),%eax
80108a06:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108a0a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108a0e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108a12:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a19:	89 04 24             	mov    %eax,(%esp)
80108a1c:	e8 d0 fe ff ff       	call   801088f1 <mappages>
80108a21:	85 c0                	test   %eax,%eax
80108a23:	79 07                	jns    80108a2c <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108a25:	b8 00 00 00 00       	mov    $0x0,%eax
80108a2a:	eb 10                	jmp    80108a3c <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108a2c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108a30:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108a37:	72 ae                	jb     801089e7 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108a39:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108a3c:	83 c4 34             	add    $0x34,%esp
80108a3f:	5b                   	pop    %ebx
80108a40:	5d                   	pop    %ebp
80108a41:	c3                   	ret    

80108a42 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108a42:	55                   	push   %ebp
80108a43:	89 e5                	mov    %esp,%ebp
80108a45:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108a48:	e8 38 ff ff ff       	call   80108985 <setupkvm>
80108a4d:	a3 18 37 11 80       	mov    %eax,0x80113718
  switchkvm();
80108a52:	e8 02 00 00 00       	call   80108a59 <switchkvm>
}
80108a57:	c9                   	leave  
80108a58:	c3                   	ret    

80108a59 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108a59:	55                   	push   %ebp
80108a5a:	89 e5                	mov    %esp,%ebp
80108a5c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108a5f:	a1 18 37 11 80       	mov    0x80113718,%eax
80108a64:	89 04 24             	mov    %eax,(%esp)
80108a67:	e8 5f f9 ff ff       	call   801083cb <v2p>
80108a6c:	89 04 24             	mov    %eax,(%esp)
80108a6f:	e8 4c f9 ff ff       	call   801083c0 <lcr3>
}
80108a74:	c9                   	leave  
80108a75:	c3                   	ret    

80108a76 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108a76:	55                   	push   %ebp
80108a77:	89 e5                	mov    %esp,%ebp
80108a79:	53                   	push   %ebx
80108a7a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108a7d:	e8 19 d1 ff ff       	call   80105b9b <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108a82:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a88:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108a8f:	83 c2 08             	add    $0x8,%edx
80108a92:	89 d3                	mov    %edx,%ebx
80108a94:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108a9b:	83 c2 08             	add    $0x8,%edx
80108a9e:	c1 ea 10             	shr    $0x10,%edx
80108aa1:	89 d1                	mov    %edx,%ecx
80108aa3:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108aaa:	83 c2 08             	add    $0x8,%edx
80108aad:	c1 ea 18             	shr    $0x18,%edx
80108ab0:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108ab7:	67 00 
80108ab9:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108ac0:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108ac6:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108acd:	83 e1 f0             	and    $0xfffffff0,%ecx
80108ad0:	83 c9 09             	or     $0x9,%ecx
80108ad3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ad9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ae0:	83 c9 10             	or     $0x10,%ecx
80108ae3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ae9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108af0:	83 e1 9f             	and    $0xffffff9f,%ecx
80108af3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108af9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108b00:	83 c9 80             	or     $0xffffff80,%ecx
80108b03:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108b09:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b10:	83 e1 f0             	and    $0xfffffff0,%ecx
80108b13:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b19:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b20:	83 e1 ef             	and    $0xffffffef,%ecx
80108b23:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b29:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b30:	83 e1 df             	and    $0xffffffdf,%ecx
80108b33:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b39:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b40:	83 c9 40             	or     $0x40,%ecx
80108b43:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b49:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b50:	83 e1 7f             	and    $0x7f,%ecx
80108b53:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b59:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108b5f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b65:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108b6c:	83 e2 ef             	and    $0xffffffef,%edx
80108b6f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108b75:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b7b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108b81:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b87:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108b8e:	8b 52 08             	mov    0x8(%edx),%edx
80108b91:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108b97:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108b9a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108ba1:	e8 ef f7 ff ff       	call   80108395 <ltr>
  if(p->pgdir == 0)
80108ba6:	8b 45 08             	mov    0x8(%ebp),%eax
80108ba9:	8b 40 04             	mov    0x4(%eax),%eax
80108bac:	85 c0                	test   %eax,%eax
80108bae:	75 0c                	jne    80108bbc <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108bb0:	c7 04 24 4f 9a 10 80 	movl   $0x80109a4f,(%esp)
80108bb7:	e8 81 79 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80108bbf:	8b 40 04             	mov    0x4(%eax),%eax
80108bc2:	89 04 24             	mov    %eax,(%esp)
80108bc5:	e8 01 f8 ff ff       	call   801083cb <v2p>
80108bca:	89 04 24             	mov    %eax,(%esp)
80108bcd:	e8 ee f7 ff ff       	call   801083c0 <lcr3>
  popcli();
80108bd2:	e8 0c d0 ff ff       	call   80105be3 <popcli>
}
80108bd7:	83 c4 14             	add    $0x14,%esp
80108bda:	5b                   	pop    %ebx
80108bdb:	5d                   	pop    %ebp
80108bdc:	c3                   	ret    

80108bdd <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108bdd:	55                   	push   %ebp
80108bde:	89 e5                	mov    %esp,%ebp
80108be0:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108be3:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108bea:	76 0c                	jbe    80108bf8 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108bec:	c7 04 24 63 9a 10 80 	movl   $0x80109a63,(%esp)
80108bf3:	e8 45 79 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108bf8:	e8 b2 ad ff ff       	call   801039af <kalloc>
80108bfd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108c00:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c07:	00 
80108c08:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c0f:	00 
80108c10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c13:	89 04 24             	mov    %eax,(%esp)
80108c16:	e8 87 d0 ff ff       	call   80105ca2 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108c1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c1e:	89 04 24             	mov    %eax,(%esp)
80108c21:	e8 a5 f7 ff ff       	call   801083cb <v2p>
80108c26:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c2d:	00 
80108c2e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c32:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c39:	00 
80108c3a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c41:	00 
80108c42:	8b 45 08             	mov    0x8(%ebp),%eax
80108c45:	89 04 24             	mov    %eax,(%esp)
80108c48:	e8 a4 fc ff ff       	call   801088f1 <mappages>
  memmove(mem, init, sz);
80108c4d:	8b 45 10             	mov    0x10(%ebp),%eax
80108c50:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c54:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c57:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c5e:	89 04 24             	mov    %eax,(%esp)
80108c61:	e8 0f d1 ff ff       	call   80105d75 <memmove>
}
80108c66:	c9                   	leave  
80108c67:	c3                   	ret    

80108c68 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108c68:	55                   	push   %ebp
80108c69:	89 e5                	mov    %esp,%ebp
80108c6b:	53                   	push   %ebx
80108c6c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108c6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c72:	25 ff 0f 00 00       	and    $0xfff,%eax
80108c77:	85 c0                	test   %eax,%eax
80108c79:	74 0c                	je     80108c87 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108c7b:	c7 04 24 80 9a 10 80 	movl   $0x80109a80,(%esp)
80108c82:	e8 b6 78 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108c87:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108c8e:	e9 ad 00 00 00       	jmp    80108d40 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c96:	8b 55 0c             	mov    0xc(%ebp),%edx
80108c99:	01 d0                	add    %edx,%eax
80108c9b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ca2:	00 
80108ca3:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ca7:	8b 45 08             	mov    0x8(%ebp),%eax
80108caa:	89 04 24             	mov    %eax,(%esp)
80108cad:	e8 a9 fb ff ff       	call   8010885b <walkpgdir>
80108cb2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108cb5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108cb9:	75 0c                	jne    80108cc7 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108cbb:	c7 04 24 a3 9a 10 80 	movl   $0x80109aa3,(%esp)
80108cc2:	e8 76 78 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108cc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108cca:	8b 00                	mov    (%eax),%eax
80108ccc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cd1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108cd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cd7:	8b 55 18             	mov    0x18(%ebp),%edx
80108cda:	89 d1                	mov    %edx,%ecx
80108cdc:	29 c1                	sub    %eax,%ecx
80108cde:	89 c8                	mov    %ecx,%eax
80108ce0:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108ce5:	77 11                	ja     80108cf8 <loaduvm+0x90>
      n = sz - i;
80108ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cea:	8b 55 18             	mov    0x18(%ebp),%edx
80108ced:	89 d1                	mov    %edx,%ecx
80108cef:	29 c1                	sub    %eax,%ecx
80108cf1:	89 c8                	mov    %ecx,%eax
80108cf3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108cf6:	eb 07                	jmp    80108cff <loaduvm+0x97>
    else
      n = PGSIZE;
80108cf8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108cff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d02:	8b 55 14             	mov    0x14(%ebp),%edx
80108d05:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108d08:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d0b:	89 04 24             	mov    %eax,(%esp)
80108d0e:	e8 c5 f6 ff ff       	call   801083d8 <p2v>
80108d13:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d16:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108d1a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108d1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d22:	8b 45 10             	mov    0x10(%ebp),%eax
80108d25:	89 04 24             	mov    %eax,(%esp)
80108d28:	e8 bd 9b ff ff       	call   801028ea <readi>
80108d2d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108d30:	74 07                	je     80108d39 <loaduvm+0xd1>
      return -1;
80108d32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d37:	eb 18                	jmp    80108d51 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108d39:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d43:	3b 45 18             	cmp    0x18(%ebp),%eax
80108d46:	0f 82 47 ff ff ff    	jb     80108c93 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108d4c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108d51:	83 c4 24             	add    $0x24,%esp
80108d54:	5b                   	pop    %ebx
80108d55:	5d                   	pop    %ebp
80108d56:	c3                   	ret    

80108d57 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108d57:	55                   	push   %ebp
80108d58:	89 e5                	mov    %esp,%ebp
80108d5a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108d5d:	8b 45 10             	mov    0x10(%ebp),%eax
80108d60:	85 c0                	test   %eax,%eax
80108d62:	79 0a                	jns    80108d6e <allocuvm+0x17>
    return 0;
80108d64:	b8 00 00 00 00       	mov    $0x0,%eax
80108d69:	e9 c1 00 00 00       	jmp    80108e2f <allocuvm+0xd8>
  if(newsz < oldsz)
80108d6e:	8b 45 10             	mov    0x10(%ebp),%eax
80108d71:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108d74:	73 08                	jae    80108d7e <allocuvm+0x27>
    return oldsz;
80108d76:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d79:	e9 b1 00 00 00       	jmp    80108e2f <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108d7e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d81:	05 ff 0f 00 00       	add    $0xfff,%eax
80108d86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108d8e:	e9 8d 00 00 00       	jmp    80108e20 <allocuvm+0xc9>
    mem = kalloc();
80108d93:	e8 17 ac ff ff       	call   801039af <kalloc>
80108d98:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108d9b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108d9f:	75 2c                	jne    80108dcd <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108da1:	c7 04 24 c1 9a 10 80 	movl   $0x80109ac1,(%esp)
80108da8:	e8 f4 75 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108dad:	8b 45 0c             	mov    0xc(%ebp),%eax
80108db0:	89 44 24 08          	mov    %eax,0x8(%esp)
80108db4:	8b 45 10             	mov    0x10(%ebp),%eax
80108db7:	89 44 24 04          	mov    %eax,0x4(%esp)
80108dbb:	8b 45 08             	mov    0x8(%ebp),%eax
80108dbe:	89 04 24             	mov    %eax,(%esp)
80108dc1:	e8 6b 00 00 00       	call   80108e31 <deallocuvm>
      return 0;
80108dc6:	b8 00 00 00 00       	mov    $0x0,%eax
80108dcb:	eb 62                	jmp    80108e2f <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108dcd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108dd4:	00 
80108dd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ddc:	00 
80108ddd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108de0:	89 04 24             	mov    %eax,(%esp)
80108de3:	e8 ba ce ff ff       	call   80105ca2 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108de8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108deb:	89 04 24             	mov    %eax,(%esp)
80108dee:	e8 d8 f5 ff ff       	call   801083cb <v2p>
80108df3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108df6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108dfd:	00 
80108dfe:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e02:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e09:	00 
80108e0a:	89 54 24 04          	mov    %edx,0x4(%esp)
80108e0e:	8b 45 08             	mov    0x8(%ebp),%eax
80108e11:	89 04 24             	mov    %eax,(%esp)
80108e14:	e8 d8 fa ff ff       	call   801088f1 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108e19:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e23:	3b 45 10             	cmp    0x10(%ebp),%eax
80108e26:	0f 82 67 ff ff ff    	jb     80108d93 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108e2c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108e2f:	c9                   	leave  
80108e30:	c3                   	ret    

80108e31 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108e31:	55                   	push   %ebp
80108e32:	89 e5                	mov    %esp,%ebp
80108e34:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108e37:	8b 45 10             	mov    0x10(%ebp),%eax
80108e3a:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108e3d:	72 08                	jb     80108e47 <deallocuvm+0x16>
    return oldsz;
80108e3f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e42:	e9 a4 00 00 00       	jmp    80108eeb <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108e47:	8b 45 10             	mov    0x10(%ebp),%eax
80108e4a:	05 ff 0f 00 00       	add    $0xfff,%eax
80108e4f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e54:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108e57:	e9 80 00 00 00       	jmp    80108edc <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108e5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e5f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e66:	00 
80108e67:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e6e:	89 04 24             	mov    %eax,(%esp)
80108e71:	e8 e5 f9 ff ff       	call   8010885b <walkpgdir>
80108e76:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108e79:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e7d:	75 09                	jne    80108e88 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108e7f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108e86:	eb 4d                	jmp    80108ed5 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108e88:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e8b:	8b 00                	mov    (%eax),%eax
80108e8d:	83 e0 01             	and    $0x1,%eax
80108e90:	84 c0                	test   %al,%al
80108e92:	74 41                	je     80108ed5 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108e94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e97:	8b 00                	mov    (%eax),%eax
80108e99:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108ea1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ea5:	75 0c                	jne    80108eb3 <deallocuvm+0x82>
        panic("kfree");
80108ea7:	c7 04 24 d9 9a 10 80 	movl   $0x80109ad9,(%esp)
80108eae:	e8 8a 76 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108eb3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108eb6:	89 04 24             	mov    %eax,(%esp)
80108eb9:	e8 1a f5 ff ff       	call   801083d8 <p2v>
80108ebe:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108ec1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ec4:	89 04 24             	mov    %eax,(%esp)
80108ec7:	e8 4a aa ff ff       	call   80103916 <kfree>
      *pte = 0;
80108ecc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ecf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108ed5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108edc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108edf:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108ee2:	0f 82 74 ff ff ff    	jb     80108e5c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108ee8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108eeb:	c9                   	leave  
80108eec:	c3                   	ret    

80108eed <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108eed:	55                   	push   %ebp
80108eee:	89 e5                	mov    %esp,%ebp
80108ef0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108ef3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108ef7:	75 0c                	jne    80108f05 <freevm+0x18>
    panic("freevm: no pgdir");
80108ef9:	c7 04 24 df 9a 10 80 	movl   $0x80109adf,(%esp)
80108f00:	e8 38 76 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108f05:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f0c:	00 
80108f0d:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108f14:	80 
80108f15:	8b 45 08             	mov    0x8(%ebp),%eax
80108f18:	89 04 24             	mov    %eax,(%esp)
80108f1b:	e8 11 ff ff ff       	call   80108e31 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108f20:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f27:	eb 3c                	jmp    80108f65 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108f29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f2c:	c1 e0 02             	shl    $0x2,%eax
80108f2f:	03 45 08             	add    0x8(%ebp),%eax
80108f32:	8b 00                	mov    (%eax),%eax
80108f34:	83 e0 01             	and    $0x1,%eax
80108f37:	84 c0                	test   %al,%al
80108f39:	74 26                	je     80108f61 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108f3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f3e:	c1 e0 02             	shl    $0x2,%eax
80108f41:	03 45 08             	add    0x8(%ebp),%eax
80108f44:	8b 00                	mov    (%eax),%eax
80108f46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f4b:	89 04 24             	mov    %eax,(%esp)
80108f4e:	e8 85 f4 ff ff       	call   801083d8 <p2v>
80108f53:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108f56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f59:	89 04 24             	mov    %eax,(%esp)
80108f5c:	e8 b5 a9 ff ff       	call   80103916 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108f61:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108f65:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108f6c:	76 bb                	jbe    80108f29 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108f6e:	8b 45 08             	mov    0x8(%ebp),%eax
80108f71:	89 04 24             	mov    %eax,(%esp)
80108f74:	e8 9d a9 ff ff       	call   80103916 <kfree>
}
80108f79:	c9                   	leave  
80108f7a:	c3                   	ret    

80108f7b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108f7b:	55                   	push   %ebp
80108f7c:	89 e5                	mov    %esp,%ebp
80108f7e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108f81:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f88:	00 
80108f89:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f90:	8b 45 08             	mov    0x8(%ebp),%eax
80108f93:	89 04 24             	mov    %eax,(%esp)
80108f96:	e8 c0 f8 ff ff       	call   8010885b <walkpgdir>
80108f9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108f9e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108fa2:	75 0c                	jne    80108fb0 <clearpteu+0x35>
    panic("clearpteu");
80108fa4:	c7 04 24 f0 9a 10 80 	movl   $0x80109af0,(%esp)
80108fab:	e8 8d 75 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108fb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fb3:	8b 00                	mov    (%eax),%eax
80108fb5:	89 c2                	mov    %eax,%edx
80108fb7:	83 e2 fb             	and    $0xfffffffb,%edx
80108fba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fbd:	89 10                	mov    %edx,(%eax)
}
80108fbf:	c9                   	leave  
80108fc0:	c3                   	ret    

80108fc1 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108fc1:	55                   	push   %ebp
80108fc2:	89 e5                	mov    %esp,%ebp
80108fc4:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108fc7:	e8 b9 f9 ff ff       	call   80108985 <setupkvm>
80108fcc:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108fcf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108fd3:	75 0a                	jne    80108fdf <copyuvm+0x1e>
    return 0;
80108fd5:	b8 00 00 00 00       	mov    $0x0,%eax
80108fda:	e9 f1 00 00 00       	jmp    801090d0 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108fdf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108fe6:	e9 c0 00 00 00       	jmp    801090ab <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108feb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ff5:	00 
80108ff6:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ffa:	8b 45 08             	mov    0x8(%ebp),%eax
80108ffd:	89 04 24             	mov    %eax,(%esp)
80109000:	e8 56 f8 ff ff       	call   8010885b <walkpgdir>
80109005:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109008:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010900c:	75 0c                	jne    8010901a <copyuvm+0x59>
      panic("copyuvm: pte should exist");
8010900e:	c7 04 24 fa 9a 10 80 	movl   $0x80109afa,(%esp)
80109015:	e8 23 75 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
8010901a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010901d:	8b 00                	mov    (%eax),%eax
8010901f:	83 e0 01             	and    $0x1,%eax
80109022:	85 c0                	test   %eax,%eax
80109024:	75 0c                	jne    80109032 <copyuvm+0x71>
      panic("copyuvm: page not present");
80109026:	c7 04 24 14 9b 10 80 	movl   $0x80109b14,(%esp)
8010902d:	e8 0b 75 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80109032:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109035:	8b 00                	mov    (%eax),%eax
80109037:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010903c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
8010903f:	e8 6b a9 ff ff       	call   801039af <kalloc>
80109044:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80109047:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010904b:	74 6f                	je     801090bc <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010904d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109050:	89 04 24             	mov    %eax,(%esp)
80109053:	e8 80 f3 ff ff       	call   801083d8 <p2v>
80109058:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010905f:	00 
80109060:	89 44 24 04          	mov    %eax,0x4(%esp)
80109064:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109067:	89 04 24             	mov    %eax,(%esp)
8010906a:	e8 06 cd ff ff       	call   80105d75 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010906f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109072:	89 04 24             	mov    %eax,(%esp)
80109075:	e8 51 f3 ff ff       	call   801083cb <v2p>
8010907a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010907d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109084:	00 
80109085:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109089:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109090:	00 
80109091:	89 54 24 04          	mov    %edx,0x4(%esp)
80109095:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109098:	89 04 24             	mov    %eax,(%esp)
8010909b:	e8 51 f8 ff ff       	call   801088f1 <mappages>
801090a0:	85 c0                	test   %eax,%eax
801090a2:	78 1b                	js     801090bf <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801090a4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090ae:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090b1:	0f 82 34 ff ff ff    	jb     80108feb <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801090b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090ba:	eb 14                	jmp    801090d0 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801090bc:	90                   	nop
801090bd:	eb 01                	jmp    801090c0 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801090bf:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801090c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090c3:	89 04 24             	mov    %eax,(%esp)
801090c6:	e8 22 fe ff ff       	call   80108eed <freevm>
  return 0;
801090cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801090d0:	c9                   	leave  
801090d1:	c3                   	ret    

801090d2 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801090d2:	55                   	push   %ebp
801090d3:	89 e5                	mov    %esp,%ebp
801090d5:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801090d8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801090df:	00 
801090e0:	8b 45 0c             	mov    0xc(%ebp),%eax
801090e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801090e7:	8b 45 08             	mov    0x8(%ebp),%eax
801090ea:	89 04 24             	mov    %eax,(%esp)
801090ed:	e8 69 f7 ff ff       	call   8010885b <walkpgdir>
801090f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801090f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090f8:	8b 00                	mov    (%eax),%eax
801090fa:	83 e0 01             	and    $0x1,%eax
801090fd:	85 c0                	test   %eax,%eax
801090ff:	75 07                	jne    80109108 <uva2ka+0x36>
    return 0;
80109101:	b8 00 00 00 00       	mov    $0x0,%eax
80109106:	eb 25                	jmp    8010912d <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109108:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010910b:	8b 00                	mov    (%eax),%eax
8010910d:	83 e0 04             	and    $0x4,%eax
80109110:	85 c0                	test   %eax,%eax
80109112:	75 07                	jne    8010911b <uva2ka+0x49>
    return 0;
80109114:	b8 00 00 00 00       	mov    $0x0,%eax
80109119:	eb 12                	jmp    8010912d <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010911b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010911e:	8b 00                	mov    (%eax),%eax
80109120:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109125:	89 04 24             	mov    %eax,(%esp)
80109128:	e8 ab f2 ff ff       	call   801083d8 <p2v>
}
8010912d:	c9                   	leave  
8010912e:	c3                   	ret    

8010912f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010912f:	55                   	push   %ebp
80109130:	89 e5                	mov    %esp,%ebp
80109132:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109135:	8b 45 10             	mov    0x10(%ebp),%eax
80109138:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010913b:	e9 8b 00 00 00       	jmp    801091cb <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109140:	8b 45 0c             	mov    0xc(%ebp),%eax
80109143:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109148:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010914b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010914e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109152:	8b 45 08             	mov    0x8(%ebp),%eax
80109155:	89 04 24             	mov    %eax,(%esp)
80109158:	e8 75 ff ff ff       	call   801090d2 <uva2ka>
8010915d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109160:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109164:	75 07                	jne    8010916d <copyout+0x3e>
      return -1;
80109166:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010916b:	eb 6d                	jmp    801091da <copyout+0xab>
    n = PGSIZE - (va - va0);
8010916d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109170:	8b 55 ec             	mov    -0x14(%ebp),%edx
80109173:	89 d1                	mov    %edx,%ecx
80109175:	29 c1                	sub    %eax,%ecx
80109177:	89 c8                	mov    %ecx,%eax
80109179:	05 00 10 00 00       	add    $0x1000,%eax
8010917e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109181:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109184:	3b 45 14             	cmp    0x14(%ebp),%eax
80109187:	76 06                	jbe    8010918f <copyout+0x60>
      n = len;
80109189:	8b 45 14             	mov    0x14(%ebp),%eax
8010918c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010918f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109192:	8b 55 0c             	mov    0xc(%ebp),%edx
80109195:	89 d1                	mov    %edx,%ecx
80109197:	29 c1                	sub    %eax,%ecx
80109199:	89 c8                	mov    %ecx,%eax
8010919b:	03 45 e8             	add    -0x18(%ebp),%eax
8010919e:	8b 55 f0             	mov    -0x10(%ebp),%edx
801091a1:	89 54 24 08          	mov    %edx,0x8(%esp)
801091a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801091a8:	89 54 24 04          	mov    %edx,0x4(%esp)
801091ac:	89 04 24             	mov    %eax,(%esp)
801091af:	e8 c1 cb ff ff       	call   80105d75 <memmove>
    len -= n;
801091b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091b7:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801091ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091bd:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801091c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091c3:	05 00 10 00 00       	add    $0x1000,%eax
801091c8:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801091cb:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801091cf:	0f 85 6b ff ff ff    	jne    80109140 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801091d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801091da:	c9                   	leave  
801091db:	c3                   	ret    

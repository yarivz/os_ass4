
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
8010002d:	b8 af 46 10 80       	mov    $0x801046af,%eax
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
8010003a:	c7 44 24 04 08 96 10 	movl   $0x80109608,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 dc 5d 00 00       	call   80105e2a <initlock>

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
801000bd:	e8 89 5d 00 00       	call   80105e4b <acquire>

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
80100104:	e8 a4 5d 00 00       	call   80105ead <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 49 5a 00 00       	call   80105b6d <sleep>
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
8010017c:	e8 2c 5d 00 00       	call   80105ead <release>
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
80100198:	c7 04 24 0f 96 10 80 	movl   $0x8010960f,(%esp)
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
801001d3:	e8 84 38 00 00       	call   80103a5c <iderw>
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
801001ef:	c7 04 24 20 96 10 80 	movl   $0x80109620,(%esp)
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
80100210:	e8 47 38 00 00       	call   80103a5c <iderw>
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
80100229:	c7 04 24 27 96 10 80 	movl   $0x80109627,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 0a 5c 00 00       	call   80105e4b <acquire>

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
8010029d:	e8 a4 59 00 00       	call   80105c46 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 ff 5b 00 00       	call   80105ead <release>
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
801003bc:	e8 8a 5a 00 00       	call   80105e4b <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 2e 96 10 80 	movl   $0x8010962e,(%esp)
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
801004af:	c7 45 ec 37 96 10 80 	movl   $0x80109637,-0x14(%ebp)
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
80100536:	e8 72 59 00 00       	call   80105ead <release>
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
80100562:	c7 04 24 3e 96 10 80 	movl   $0x8010963e,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 4d 96 10 80 	movl   $0x8010964d,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 65 59 00 00       	call   80105efc <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 4f 96 10 80 	movl   $0x8010964f,(%esp)
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
801006b2:	e8 b6 5a 00 00       	call   8010616d <memmove>
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
801006e1:	e8 b4 59 00 00       	call   8010609a <memset>
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
80100776:	e8 f2 74 00 00       	call   80107c6d <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 e6 74 00 00       	call   80107c6d <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 da 74 00 00       	call   80107c6d <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 cd 74 00 00       	call   80107c6d <uartputc>
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
801007ba:	e8 8c 56 00 00       	call   80105e4b <acquire>
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
801007ea:	e8 fa 54 00 00       	call   80105ce9 <procdump>
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
801008f7:	e8 4a 53 00 00       	call   80105c46 <wakeup>
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
8010091e:	e8 8a 55 00 00       	call   80105ead <release>
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
80100931:	e8 b0 1e 00 00       	call   801027e6 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 03 55 00 00       	call   80105e4b <acquire>
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
80100961:	e8 47 55 00 00       	call   80105ead <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 27 1d 00 00       	call   80102698 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 de 51 00 00       	call   80105b6d <sleep>
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
80100a08:	e8 a0 54 00 00       	call   80105ead <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 80 1c 00 00       	call   80102698 <ilock>

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
80100a32:	e8 af 1d 00 00       	call   801027e6 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 08 54 00 00       	call   80105e4b <acquire>
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
80100a78:	e8 30 54 00 00       	call   80105ead <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 10 1c 00 00       	call   80102698 <ilock>

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
80100a93:	c7 44 24 04 53 96 10 	movl   $0x80109653,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 83 53 00 00       	call   80105e2a <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 5b 96 10 	movl   $0x8010965b,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 6f 53 00 00       	call   80105e2a <initlock>

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
80100ae0:	e8 84 42 00 00       	call   80104d69 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 25 31 00 00       	call   80103c1e <ioapicenable>
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
80100b0b:	e8 18 28 00 00       	call   80103328 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 6a 1b 00 00       	call   80102698 <ilock>
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
80100b55:	e8 a4 20 00 00       	call   80102bfe <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 a7 3d 10 80 	movl   $0x80103da7,(%esp)
80100b7b:	e8 31 82 00 00       	call   80108db1 <setupkvm>
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
80100bc8:	e8 31 20 00 00       	call   80102bfe <readi>
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
80100c14:	e8 6a 85 00 00       	call   80109183 <allocuvm>
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
80100c51:	e8 3e 84 00 00       	call   80109094 <loaduvm>
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
80100c87:	e8 90 1c 00 00       	call   8010291c <iunlockput>
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
80100cbc:	e8 c2 84 00 00       	call   80109183 <allocuvm>
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
80100ce0:	e8 c2 86 00 00       	call   801093a7 <clearpteu>
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
80100d0f:	e8 04 56 00 00       	call   80106318 <strlen>
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
80100d2d:	e8 e6 55 00 00       	call   80106318 <strlen>
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
80100d57:	e8 ff 87 00 00       	call   8010955b <copyout>
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
80100df7:	e8 5f 87 00 00       	call   8010955b <copyout>
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
80100e4e:	e8 77 54 00 00       	call   801062ca <safestrcpy>

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
80100ea0:	e8 fd 7f 00 00       	call   80108ea2 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 69 84 00 00       	call   80109319 <freevm>
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
80100ee2:	e8 32 84 00 00       	call   80109319 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 24 1a 00 00       	call   8010291c <iunlockput>
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
80100f06:	c7 44 24 04 64 96 10 	movl   $0x80109664,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f15:	e8 10 4f 00 00       	call   80105e2a <initlock>
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
80100f29:	e8 1d 4f 00 00       	call   80105e4b <acquire>
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
80100f52:	e8 56 4f 00 00       	call   80105ead <release>
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
80100f70:	e8 38 4f 00 00       	call   80105ead <release>
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
80100f89:	e8 bd 4e 00 00       	call   80105e4b <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 6b 96 10 80 	movl   $0x8010966b,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fba:	e8 ee 4e 00 00       	call   80105ead <release>
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
80100fd1:	e8 75 4e 00 00       	call   80105e4b <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 73 96 10 80 	movl   $0x80109673,(%esp)
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
8010100c:	e8 9c 4e 00 00       	call   80105ead <release>
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
80101056:	e8 52 4e 00 00       	call   80105ead <release>
  
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
80101074:	e8 aa 3f 00 00       	call   80105023 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 3d 34 00 00       	call   801044c5 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 b8 17 00 00       	call   8010284b <iput>
    commit_trans();
80101093:	e8 76 34 00 00       	call   8010450e <commit_trans>
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
801010b3:	e8 e0 15 00 00       	call   80102698 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 ec 1a 00 00       	call   80102bb9 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 0b 17 00 00       	call   801027e6 <iunlock>
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
80101125:	e8 7b 40 00 00       	call   801051a5 <piperead>
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
8010113f:	e8 54 15 00 00       	call   80102698 <ilock>
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
80101165:	e8 94 1a 00 00       	call   80102bfe <readi>
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
8010118d:	e8 54 16 00 00       	call   801027e6 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 7d 96 10 80 	movl   $0x8010967d,(%esp)
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
801011e2:	e8 ce 3e 00 00       	call   801050b5 <pipewrite>
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
8010122a:	e8 96 32 00 00       	call   801044c5 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 5b 14 00 00       	call   80102698 <ilock>
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
80101263:	e8 01 1b 00 00       	call   80102d69 <writei>
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
8010128b:	e8 56 15 00 00       	call   801027e6 <iunlock>
      commit_trans();
80101290:	e8 79 32 00 00       	call   8010450e <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 86 96 10 80 	movl   $0x80109686,(%esp)
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
801012d8:	c7 04 24 96 96 10 80 	movl   $0x80109696,(%esp)
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
801012fe:	e8 c6 5a 00 00       	call   80106dc9 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 a0 96 10 80 	movl   $0x801096a0,(%esp)
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
80101338:	e8 5b 13 00 00       	call   80102698 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 b8 96 10 80 	movl   $0x801096b8,(%esp)
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
80101382:	c7 04 24 db 96 10 80 	movl   $0x801096db,(%esp)
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
801013b7:	c7 04 24 f4 96 10 80 	movl   $0x801096f4,(%esp)
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
80101414:	c7 04 24 13 97 10 80 	movl   $0x80109713,(%esp)
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
8010143b:	e8 a6 13 00 00       	call   801027e6 <iunlock>
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
8010146a:	e8 ad 0c 00 00       	call   8010211c <readsb>
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
8010162b:	e8 e7 1e 00 00       	call   80103517 <updateBlkRef>
  int ref = getBlkRef(b1->sector);
80101630:	8b 45 10             	mov    0x10(%ebp),%eax
80101633:	8b 40 08             	mov    0x8(%eax),%eax
80101636:	89 04 24             	mov    %eax,(%esp)
80101639:	e8 18 20 00 00       	call   80103656 <getBlkRef>
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
80101658:	e8 ba 1e 00 00       	call   80103517 <updateBlkRef>
8010165d:	eb 28                	jmp    80101687 <deletedups+0xff>
  else if(ref == 0)
8010165f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101663:	75 22                	jne    80101687 <deletedups+0xff>
  {
    begin_trans();
80101665:	e8 5b 2e 00 00       	call   801044c5 <begin_trans>
    bfree(b1->dev, b1->sector);
8010166a:	8b 45 10             	mov    0x10(%ebp),%eax
8010166d:	8b 50 08             	mov    0x8(%eax),%edx
80101670:	8b 45 10             	mov    0x10(%ebp),%eax
80101673:	8b 40 04             	mov    0x4(%eax),%eax
80101676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010167a:	89 04 24             	mov    %eax,(%esp)
8010167d:	e8 88 0c 00 00       	call   8010230a <bfree>
    commit_trans();
80101682:	e8 87 2e 00 00       	call   8010450e <commit_trans>
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
  cprintf("\nstarting de-duplication: ");
80101692:	c7 04 24 2c 97 10 80 	movl   $0x8010972c,(%esp)
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
80101707:	e8 10 0a 00 00       	call   8010211c <readsb>
  ninodes = sb.ninodes;
8010170c:	8b 45 98             	mov    -0x68(%ebp),%eax
8010170f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  zeroNextInum();
80101712:	e8 d2 1f 00 00       	call   801036e9 <zeroNextInum>
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101717:	e9 a9 07 00 00       	jmp    80101ec5 <dedup+0x83c>
  {  
    cprintf("*\n");
8010171c:	c7 04 24 47 97 10 80 	movl   $0x80109747,(%esp)
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
80101749:	e8 4a 0f 00 00       	call   80102698 <ilock>
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
80101b9d:	e8 f6 0a 00 00       	call   80102698 <ilock>
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
80101e25:	e8 f2 0a 00 00       	call   8010291c <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101e2a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101e2e:	75 18                	jne    80101e48 <dedup+0x7bf>
80101e30:	8d 45 a8             	lea    -0x58(%ebp),%eax
80101e33:	89 04 24             	mov    %eax,(%esp)
80101e36:	e8 e5 15 00 00       	call   80103420 <getPrevInode>
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
80101ea5:	e8 1b 26 00 00       	call   801044c5 <begin_trans>
      iupdate(ip1);
80101eaa:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ead:	89 04 24             	mov    %eax,(%esp)
80101eb0:	e8 27 06 00 00       	call   801024dc <iupdate>
      commit_trans();
80101eb5:	e8 54 26 00 00       	call   8010450e <commit_trans>
    }
    iunlockput(ip1);
80101eba:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101ebd:	89 04 24             	mov    %eax,(%esp)
80101ec0:	e8 57 0a 00 00       	call   8010291c <iunlockput>
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  zeroNextInum();
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
80101ec5:	e8 a2 14 00 00       	call   8010336c <getNextInode>
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
80101ee5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101eec:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  struct buf* bp1 = bread(1,getRefCount(1));
80101ef3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101efa:	e8 d2 15 00 00       	call   801034d1 <getRefCount>
80101eff:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f03:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f0a:	e8 97 e2 ff ff       	call   801001a6 <bread>
80101f0f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  struct buf* bp2 = bread(1,getRefCount(2));
80101f12:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80101f19:	e8 b3 15 00 00       	call   801034d1 <getRefCount>
80101f1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f22:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f29:	e8 78 e2 ff ff       	call   801001a6 <bread>
80101f2e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct superblock sb;
  readsb(1, &sb);
80101f31:	8d 45 bc             	lea    -0x44(%ebp),%eax
80101f34:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f38:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80101f3f:	e8 d8 01 00 00       	call   8010211c <readsb>
  total = sb.nblocks - getFreeBlocks();
80101f44:	8b 5d c0             	mov    -0x40(%ebp),%ebx
80101f47:	e8 fb f4 ff ff       	call   80101447 <getFreeBlocks>
80101f4c:	89 da                	mov    %ebx,%edx
80101f4e:	29 c2                	sub    %eax,%edx
80101f50:	89 d0                	mov    %edx,%eax
80101f52:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  for(i=0;i<BSIZE;i++)
80101f55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f5c:	eb 4c                	jmp    80101faa <getSharedBlocksRate+0xcc>
  {
    if(bp1->data[i] > 0)
80101f5e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101f61:	03 45 f4             	add    -0xc(%ebp),%eax
80101f64:	83 c0 10             	add    $0x10,%eax
80101f67:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f6b:	84 c0                	test   %al,%al
80101f6d:	74 13                	je     80101f82 <getSharedBlocksRate+0xa4>
      saved += bp1->data[i];
80101f6f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101f72:	03 45 f4             	add    -0xc(%ebp),%eax
80101f75:	83 c0 10             	add    $0x10,%eax
80101f78:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f7c:	0f b6 c0             	movzbl %al,%eax
80101f7f:	01 45 f0             	add    %eax,-0x10(%ebp)
    if(bp2->data[i] > 0)
80101f82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f85:	03 45 f4             	add    -0xc(%ebp),%eax
80101f88:	83 c0 10             	add    $0x10,%eax
80101f8b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101f8f:	84 c0                	test   %al,%al
80101f91:	74 13                	je     80101fa6 <getSharedBlocksRate+0xc8>
      saved += bp2->data[i];
80101f93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101f96:	03 45 f4             	add    -0xc(%ebp),%eax
80101f99:	83 c0 10             	add    $0x10,%eax
80101f9c:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101fa0:	0f b6 c0             	movzbl %al,%eax
80101fa3:	01 45 f0             	add    %eax,-0x10(%ebp)
  struct buf* bp2 = bread(1,getRefCount(2));
  struct superblock sb;
  readsb(1, &sb);
  total = sb.nblocks - getFreeBlocks();
  
  for(i=0;i<BSIZE;i++)
80101fa6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101faa:	81 7d f4 ff 01 00 00 	cmpl   $0x1ff,-0xc(%ebp)
80101fb1:	7e ab                	jle    80101f5e <getSharedBlocksRate+0x80>
      saved += bp1->data[i];
    if(bp2->data[i] > 0)
      saved += bp2->data[i];
  }
  
  total += saved;
80101fb3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fb6:	01 45 ec             	add    %eax,-0x14(%ebp)
  
  double res = (double)saved/(double)total;
80101fb9:	db 45 f0             	fildl  -0x10(%ebp)
80101fbc:	db 45 ec             	fildl  -0x14(%ebp)
80101fbf:	de f9                	fdivrp %st,%st(1)
80101fc1:	dd 5d d8             	fstpl  -0x28(%ebp)
  cprintf("saved = %d, total = %d\n",saved,total);
80101fc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fc7:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fce:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fd2:	c7 04 24 4a 97 10 80 	movl   $0x8010974a,(%esp)
80101fd9:	e8 c3 e3 ff ff       	call   801003a1 <cprintf>
   
  cprintf("Shared block rate is: 0.");
80101fde:	c7 04 24 62 97 10 80 	movl   $0x80109762,(%esp)
80101fe5:	e8 b7 e3 ff ff       	call   801003a1 <cprintf>
  for(i=10;i!=100000;i*=10)
80101fea:	c7 45 f4 0a 00 00 00 	movl   $0xa,-0xc(%ebp)
80101ff1:	eb 3e                	jmp    80102031 <getSharedBlocksRate+0x153>
  {
    digit = res*i;
80101ff3:	db 45 f4             	fildl  -0xc(%ebp)
80101ff6:	dc 4d d8             	fmull  -0x28(%ebp)
80101ff9:	d9 7d b6             	fnstcw -0x4a(%ebp)
80101ffc:	0f b7 45 b6          	movzwl -0x4a(%ebp),%eax
80102000:	b4 0c                	mov    $0xc,%ah
80102002:	66 89 45 b4          	mov    %ax,-0x4c(%ebp)
80102006:	d9 6d b4             	fldcw  -0x4c(%ebp)
80102009:	db 5d d4             	fistpl -0x2c(%ebp)
8010200c:	d9 6d b6             	fldcw  -0x4a(%ebp)
    cprintf("%d",digit);
8010200f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102012:	89 44 24 04          	mov    %eax,0x4(%esp)
80102016:	c7 04 24 7b 97 10 80 	movl   $0x8010977b,(%esp)
8010201d:	e8 7f e3 ff ff       	call   801003a1 <cprintf>
  
  double res = (double)saved/(double)total;
  cprintf("saved = %d, total = %d\n",saved,total);
   
  cprintf("Shared block rate is: 0.");
  for(i=10;i!=100000;i*=10)
80102022:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102025:	89 d0                	mov    %edx,%eax
80102027:	c1 e0 02             	shl    $0x2,%eax
8010202a:	01 d0                	add    %edx,%eax
8010202c:	01 c0                	add    %eax,%eax
8010202e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102031:	81 7d f4 a0 86 01 00 	cmpl   $0x186a0,-0xc(%ebp)
80102038:	75 b9                	jne    80101ff3 <getSharedBlocksRate+0x115>
  {
    digit = res*i;
    cprintf("%d",digit);
  }
  cprintf("\n");
8010203a:	c7 04 24 7e 97 10 80 	movl   $0x8010977e,(%esp)
80102041:	e8 5b e3 ff ff       	call   801003a1 <cprintf>
  
  return 0;
80102046:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010204b:	83 c4 64             	add    $0x64,%esp
8010204e:	5b                   	pop    %ebx
8010204f:	5d                   	pop    %ebp
80102050:	c3                   	ret    
80102051:	00 00                	add    %al,(%eax)
	...

80102054 <replaceBlk>:
int prevInum = 0;
uint refCount1,refCount2;

void
replaceBlk(struct inode* ip, uint old, uint new)
{
80102054:	55                   	push   %ebp
80102055:	89 e5                	mov    %esp,%ebp
80102057:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010205a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102061:	eb 37                	jmp    8010209a <replaceBlk+0x46>
    if(ip->addrs[i] && ip->addrs[i] == old){
80102063:	8b 45 08             	mov    0x8(%ebp),%eax
80102066:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102069:	83 c2 04             	add    $0x4,%edx
8010206c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102070:	85 c0                	test   %eax,%eax
80102072:	74 22                	je     80102096 <replaceBlk+0x42>
80102074:	8b 45 08             	mov    0x8(%ebp),%eax
80102077:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010207a:	83 c2 04             	add    $0x4,%edx
8010207d:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102081:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102084:	75 10                	jne    80102096 <replaceBlk+0x42>
      ip->addrs[i] = new;
80102086:	8b 45 08             	mov    0x8(%ebp),%eax
80102089:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010208c:	8d 4a 04             	lea    0x4(%edx),%ecx
8010208f:	8b 55 10             	mov    0x10(%ebp),%edx
80102092:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102096:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010209a:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
8010209e:	7e c3                	jle    80102063 <replaceBlk+0xf>
    if(ip->addrs[i] && ip->addrs[i] == old){
      ip->addrs[i] = new;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801020a0:	8b 45 08             	mov    0x8(%ebp),%eax
801020a3:	8b 40 4c             	mov    0x4c(%eax),%eax
801020a6:	85 c0                	test   %eax,%eax
801020a8:	74 70                	je     8010211a <replaceBlk+0xc6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801020aa:	8b 45 08             	mov    0x8(%ebp),%eax
801020ad:	8b 50 4c             	mov    0x4c(%eax),%edx
801020b0:	8b 45 08             	mov    0x8(%ebp),%eax
801020b3:	8b 00                	mov    (%eax),%eax
801020b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801020b9:	89 04 24             	mov    %eax,(%esp)
801020bc:	e8 e5 e0 ff ff       	call   801001a6 <bread>
801020c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
801020c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020c7:	83 c0 18             	add    $0x18,%eax
801020ca:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
801020cd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801020d4:	eb 31                	jmp    80102107 <replaceBlk+0xb3>
      if(a[j] && a[j] == old)
801020d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020d9:	c1 e0 02             	shl    $0x2,%eax
801020dc:	03 45 e8             	add    -0x18(%ebp),%eax
801020df:	8b 00                	mov    (%eax),%eax
801020e1:	85 c0                	test   %eax,%eax
801020e3:	74 1e                	je     80102103 <replaceBlk+0xaf>
801020e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e8:	c1 e0 02             	shl    $0x2,%eax
801020eb:	03 45 e8             	add    -0x18(%ebp),%eax
801020ee:	8b 00                	mov    (%eax),%eax
801020f0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801020f3:	75 0e                	jne    80102103 <replaceBlk+0xaf>
	a[j] = new;
801020f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020f8:	c1 e0 02             	shl    $0x2,%eax
801020fb:	03 45 e8             	add    -0x18(%ebp),%eax
801020fe:	8b 55 10             	mov    0x10(%ebp),%edx
80102101:	89 10                	mov    %edx,(%eax)
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102103:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102107:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010210a:	83 f8 7f             	cmp    $0x7f,%eax
8010210d:	76 c7                	jbe    801020d6 <replaceBlk+0x82>
      if(a[j] && a[j] == old)
	a[j] = new;
    }
    brelse(bp);
8010210f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102112:	89 04 24             	mov    %eax,(%esp)
80102115:	e8 fd e0 ff ff       	call   80100217 <brelse>
  }
}
8010211a:	c9                   	leave  
8010211b:	c3                   	ret    

8010211c <readsb>:
  

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
8010211c:	55                   	push   %ebp
8010211d:	89 e5                	mov    %esp,%ebp
8010211f:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80102122:	8b 45 08             	mov    0x8(%ebp),%eax
80102125:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010212c:	00 
8010212d:	89 04 24             	mov    %eax,(%esp)
80102130:	e8 71 e0 ff ff       	call   801001a6 <bread>
80102135:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80102138:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010213b:	83 c0 18             	add    $0x18,%eax
8010213e:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80102145:	00 
80102146:	89 44 24 04          	mov    %eax,0x4(%esp)
8010214a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010214d:	89 04 24             	mov    %eax,(%esp)
80102150:	e8 18 40 00 00       	call   8010616d <memmove>
  brelse(bp);
80102155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102158:	89 04 24             	mov    %eax,(%esp)
8010215b:	e8 b7 e0 ff ff       	call   80100217 <brelse>
}
80102160:	c9                   	leave  
80102161:	c3                   	ret    

80102162 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80102162:	55                   	push   %ebp
80102163:	89 e5                	mov    %esp,%ebp
80102165:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80102168:	8b 55 0c             	mov    0xc(%ebp),%edx
8010216b:	8b 45 08             	mov    0x8(%ebp),%eax
8010216e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102172:	89 04 24             	mov    %eax,(%esp)
80102175:	e8 2c e0 ff ff       	call   801001a6 <bread>
8010217a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010217d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102180:	83 c0 18             	add    $0x18,%eax
80102183:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010218a:	00 
8010218b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102192:	00 
80102193:	89 04 24             	mov    %eax,(%esp)
80102196:	e8 ff 3e 00 00       	call   8010609a <memset>
  log_write(bp);
8010219b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010219e:	89 04 24             	mov    %eax,(%esp)
801021a1:	e8 c0 23 00 00       	call   80104566 <log_write>
  brelse(bp);
801021a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021a9:	89 04 24             	mov    %eax,(%esp)
801021ac:	e8 66 e0 ff ff       	call   80100217 <brelse>
}
801021b1:	c9                   	leave  
801021b2:	c3                   	ret    

801021b3 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801021b3:	55                   	push   %ebp
801021b4:	89 e5                	mov    %esp,%ebp
801021b6:	53                   	push   %ebx
801021b7:	83 ec 44             	sub    $0x44,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801021ba:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801021c1:	8b 45 08             	mov    0x8(%ebp),%eax
801021c4:	8d 55 d0             	lea    -0x30(%ebp),%edx
801021c7:	89 54 24 04          	mov    %edx,0x4(%esp)
801021cb:	89 04 24             	mov    %eax,(%esp)
801021ce:	e8 49 ff ff ff       	call   8010211c <readsb>
  for(b = 0; b < sb.size; b += BPB){
801021d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021da:	e9 11 01 00 00       	jmp    801022f0 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801021df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021e2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801021e8:	85 c0                	test   %eax,%eax
801021ea:	0f 48 c2             	cmovs  %edx,%eax
801021ed:	c1 f8 0c             	sar    $0xc,%eax
801021f0:	8b 55 d8             	mov    -0x28(%ebp),%edx
801021f3:	c1 ea 03             	shr    $0x3,%edx
801021f6:	01 d0                	add    %edx,%eax
801021f8:	83 c0 03             	add    $0x3,%eax
801021fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102202:	89 04 24             	mov    %eax,(%esp)
80102205:	e8 9c df ff ff       	call   801001a6 <bread>
8010220a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010220d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102214:	e9 a7 00 00 00       	jmp    801022c0 <balloc+0x10d>
      m = 1 << (bi % 8);
80102219:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010221c:	89 c2                	mov    %eax,%edx
8010221e:	c1 fa 1f             	sar    $0x1f,%edx
80102221:	c1 ea 1d             	shr    $0x1d,%edx
80102224:	01 d0                	add    %edx,%eax
80102226:	83 e0 07             	and    $0x7,%eax
80102229:	29 d0                	sub    %edx,%eax
8010222b:	ba 01 00 00 00       	mov    $0x1,%edx
80102230:	89 d3                	mov    %edx,%ebx
80102232:	89 c1                	mov    %eax,%ecx
80102234:	d3 e3                	shl    %cl,%ebx
80102236:	89 d8                	mov    %ebx,%eax
80102238:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010223b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010223e:	8d 50 07             	lea    0x7(%eax),%edx
80102241:	85 c0                	test   %eax,%eax
80102243:	0f 48 c2             	cmovs  %edx,%eax
80102246:	c1 f8 03             	sar    $0x3,%eax
80102249:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010224c:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80102251:	0f b6 c0             	movzbl %al,%eax
80102254:	23 45 e8             	and    -0x18(%ebp),%eax
80102257:	85 c0                	test   %eax,%eax
80102259:	75 61                	jne    801022bc <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
8010225b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010225e:	8d 50 07             	lea    0x7(%eax),%edx
80102261:	85 c0                	test   %eax,%eax
80102263:	0f 48 c2             	cmovs  %edx,%eax
80102266:	c1 f8 03             	sar    $0x3,%eax
80102269:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010226c:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80102271:	89 d1                	mov    %edx,%ecx
80102273:	8b 55 e8             	mov    -0x18(%ebp),%edx
80102276:	09 ca                	or     %ecx,%edx
80102278:	89 d1                	mov    %edx,%ecx
8010227a:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010227d:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80102281:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102284:	89 04 24             	mov    %eax,(%esp)
80102287:	e8 da 22 00 00       	call   80104566 <log_write>
        brelse(bp);
8010228c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010228f:	89 04 24             	mov    %eax,(%esp)
80102292:	e8 80 df ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80102297:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010229a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010229d:	01 c2                	add    %eax,%edx
8010229f:	8b 45 08             	mov    0x8(%ebp),%eax
801022a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801022a6:	89 04 24             	mov    %eax,(%esp)
801022a9:	e8 b4 fe ff ff       	call   80102162 <bzero>
        return b + bi;
801022ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022b4:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801022b6:	83 c4 44             	add    $0x44,%esp
801022b9:	5b                   	pop    %ebx
801022ba:	5d                   	pop    %ebp
801022bb:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801022bc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801022c0:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801022c7:	7f 15                	jg     801022de <balloc+0x12b>
801022c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022cf:	01 d0                	add    %edx,%eax
801022d1:	89 c2                	mov    %eax,%edx
801022d3:	8b 45 d0             	mov    -0x30(%ebp),%eax
801022d6:	39 c2                	cmp    %eax,%edx
801022d8:	0f 82 3b ff ff ff    	jb     80102219 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801022de:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022e1:	89 04 24             	mov    %eax,(%esp)
801022e4:	e8 2e df ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801022e9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801022f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022f3:	8b 45 d0             	mov    -0x30(%ebp),%eax
801022f6:	39 c2                	cmp    %eax,%edx
801022f8:	0f 82 e1 fe ff ff    	jb     801021df <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801022fe:	c7 04 24 80 97 10 80 	movl   $0x80109780,(%esp)
80102305:	e8 33 e2 ff ff       	call   8010053d <panic>

8010230a <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
8010230a:	55                   	push   %ebp
8010230b:	89 e5                	mov    %esp,%ebp
8010230d:	53                   	push   %ebx
8010230e:	83 ec 44             	sub    $0x44,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80102311:	8d 45 d4             	lea    -0x2c(%ebp),%eax
80102314:	89 44 24 04          	mov    %eax,0x4(%esp)
80102318:	8b 45 08             	mov    0x8(%ebp),%eax
8010231b:	89 04 24             	mov    %eax,(%esp)
8010231e:	e8 f9 fd ff ff       	call   8010211c <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80102323:	8b 45 0c             	mov    0xc(%ebp),%eax
80102326:	89 c2                	mov    %eax,%edx
80102328:	c1 ea 0c             	shr    $0xc,%edx
8010232b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010232e:	c1 e8 03             	shr    $0x3,%eax
80102331:	01 d0                	add    %edx,%eax
80102333:	8d 50 03             	lea    0x3(%eax),%edx
80102336:	8b 45 08             	mov    0x8(%ebp),%eax
80102339:	89 54 24 04          	mov    %edx,0x4(%esp)
8010233d:	89 04 24             	mov    %eax,(%esp)
80102340:	e8 61 de ff ff       	call   801001a6 <bread>
80102345:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80102348:	8b 45 0c             	mov    0xc(%ebp),%eax
8010234b:	25 ff 0f 00 00       	and    $0xfff,%eax
80102350:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80102353:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102356:	89 c2                	mov    %eax,%edx
80102358:	c1 fa 1f             	sar    $0x1f,%edx
8010235b:	c1 ea 1d             	shr    $0x1d,%edx
8010235e:	01 d0                	add    %edx,%eax
80102360:	83 e0 07             	and    $0x7,%eax
80102363:	29 d0                	sub    %edx,%eax
80102365:	ba 01 00 00 00       	mov    $0x1,%edx
8010236a:	89 d3                	mov    %edx,%ebx
8010236c:	89 c1                	mov    %eax,%ecx
8010236e:	d3 e3                	shl    %cl,%ebx
80102370:	89 d8                	mov    %ebx,%eax
80102372:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80102375:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102378:	8d 50 07             	lea    0x7(%eax),%edx
8010237b:	85 c0                	test   %eax,%eax
8010237d:	0f 48 c2             	cmovs  %edx,%eax
80102380:	c1 f8 03             	sar    $0x3,%eax
80102383:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102386:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010238b:	0f b6 c0             	movzbl %al,%eax
8010238e:	23 45 ec             	and    -0x14(%ebp),%eax
80102391:	85 c0                	test   %eax,%eax
80102393:	75 0c                	jne    801023a1 <bfree+0x97>
    panic("freeing free block");
80102395:	c7 04 24 96 97 10 80 	movl   $0x80109796,(%esp)
8010239c:	e8 9c e1 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801023a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023a4:	8d 50 07             	lea    0x7(%eax),%edx
801023a7:	85 c0                	test   %eax,%eax
801023a9:	0f 48 c2             	cmovs  %edx,%eax
801023ac:	c1 f8 03             	sar    $0x3,%eax
801023af:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023b2:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801023b7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801023ba:	f7 d1                	not    %ecx
801023bc:	21 ca                	and    %ecx,%edx
801023be:	89 d1                	mov    %edx,%ecx
801023c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801023c3:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801023c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ca:	89 04 24             	mov    %eax,(%esp)
801023cd:	e8 94 21 00 00       	call   80104566 <log_write>
  brelse(bp);
801023d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d5:	89 04 24             	mov    %eax,(%esp)
801023d8:	e8 3a de ff ff       	call   80100217 <brelse>
}
801023dd:	83 c4 44             	add    $0x44,%esp
801023e0:	5b                   	pop    %ebx
801023e1:	5d                   	pop    %ebp
801023e2:	c3                   	ret    

801023e3 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801023e3:	55                   	push   %ebp
801023e4:	89 e5                	mov    %esp,%ebp
801023e6:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801023e9:	c7 44 24 04 a9 97 10 	movl   $0x801097a9,0x4(%esp)
801023f0:	80 
801023f1:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801023f8:	e8 2d 3a 00 00       	call   80105e2a <initlock>
}
801023fd:	c9                   	leave  
801023fe:	c3                   	ret    

801023ff <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801023ff:	55                   	push   %ebp
80102400:	89 e5                	mov    %esp,%ebp
80102402:	83 ec 58             	sub    $0x58,%esp
80102405:	8b 45 0c             	mov    0xc(%ebp),%eax
80102408:	66 89 45 c4          	mov    %ax,-0x3c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
8010240c:	8b 45 08             	mov    0x8(%ebp),%eax
8010240f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
80102412:	89 54 24 04          	mov    %edx,0x4(%esp)
80102416:	89 04 24             	mov    %eax,(%esp)
80102419:	e8 fe fc ff ff       	call   8010211c <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010241e:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102425:	e9 98 00 00 00       	jmp    801024c2 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010242a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010242d:	c1 e8 03             	shr    $0x3,%eax
80102430:	83 c0 02             	add    $0x2,%eax
80102433:	89 44 24 04          	mov    %eax,0x4(%esp)
80102437:	8b 45 08             	mov    0x8(%ebp),%eax
8010243a:	89 04 24             	mov    %eax,(%esp)
8010243d:	e8 64 dd ff ff       	call   801001a6 <bread>
80102442:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80102445:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102448:	8d 50 18             	lea    0x18(%eax),%edx
8010244b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244e:	83 e0 07             	and    $0x7,%eax
80102451:	c1 e0 06             	shl    $0x6,%eax
80102454:	01 d0                	add    %edx,%eax
80102456:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80102459:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010245c:	0f b7 00             	movzwl (%eax),%eax
8010245f:	66 85 c0             	test   %ax,%ax
80102462:	75 4f                	jne    801024b3 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80102464:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010246b:	00 
8010246c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102473:	00 
80102474:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102477:	89 04 24             	mov    %eax,(%esp)
8010247a:	e8 1b 3c 00 00       	call   8010609a <memset>
      dip->type = type;
8010247f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102482:	0f b7 55 c4          	movzwl -0x3c(%ebp),%edx
80102486:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80102489:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010248c:	89 04 24             	mov    %eax,(%esp)
8010248f:	e8 d2 20 00 00       	call   80104566 <log_write>
      brelse(bp);
80102494:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102497:	89 04 24             	mov    %eax,(%esp)
8010249a:	e8 78 dd ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
8010249f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801024a6:	8b 45 08             	mov    0x8(%ebp),%eax
801024a9:	89 04 24             	mov    %eax,(%esp)
801024ac:	e8 e3 00 00 00       	call   80102594 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801024b1:	c9                   	leave  
801024b2:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801024b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024b6:	89 04 24             	mov    %eax,(%esp)
801024b9:	e8 59 dd ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801024be:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801024c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801024c5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801024c8:	39 c2                	cmp    %eax,%edx
801024ca:	0f 82 5a ff ff ff    	jb     8010242a <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801024d0:	c7 04 24 b0 97 10 80 	movl   $0x801097b0,(%esp)
801024d7:	e8 61 e0 ff ff       	call   8010053d <panic>

801024dc <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
801024dc:	55                   	push   %ebp
801024dd:	89 e5                	mov    %esp,%ebp
801024df:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801024e2:	8b 45 08             	mov    0x8(%ebp),%eax
801024e5:	8b 40 04             	mov    0x4(%eax),%eax
801024e8:	c1 e8 03             	shr    $0x3,%eax
801024eb:	8d 50 02             	lea    0x2(%eax),%edx
801024ee:	8b 45 08             	mov    0x8(%ebp),%eax
801024f1:	8b 00                	mov    (%eax),%eax
801024f3:	89 54 24 04          	mov    %edx,0x4(%esp)
801024f7:	89 04 24             	mov    %eax,(%esp)
801024fa:	e8 a7 dc ff ff       	call   801001a6 <bread>
801024ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80102502:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102505:	8d 50 18             	lea    0x18(%eax),%edx
80102508:	8b 45 08             	mov    0x8(%ebp),%eax
8010250b:	8b 40 04             	mov    0x4(%eax),%eax
8010250e:	83 e0 07             	and    $0x7,%eax
80102511:	c1 e0 06             	shl    $0x6,%eax
80102514:	01 d0                	add    %edx,%eax
80102516:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80102519:	8b 45 08             	mov    0x8(%ebp),%eax
8010251c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102520:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102523:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80102526:	8b 45 08             	mov    0x8(%ebp),%eax
80102529:	0f b7 50 12          	movzwl 0x12(%eax),%edx
8010252d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102530:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102534:	8b 45 08             	mov    0x8(%ebp),%eax
80102537:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010253b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010253e:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80102542:	8b 45 08             	mov    0x8(%ebp),%eax
80102545:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102549:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010254c:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80102550:	8b 45 08             	mov    0x8(%ebp),%eax
80102553:	8b 50 18             	mov    0x18(%eax),%edx
80102556:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102559:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010255c:	8b 45 08             	mov    0x8(%ebp),%eax
8010255f:	8d 50 1c             	lea    0x1c(%eax),%edx
80102562:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102565:	83 c0 0c             	add    $0xc,%eax
80102568:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
8010256f:	00 
80102570:	89 54 24 04          	mov    %edx,0x4(%esp)
80102574:	89 04 24             	mov    %eax,(%esp)
80102577:	e8 f1 3b 00 00       	call   8010616d <memmove>
  log_write(bp);
8010257c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010257f:	89 04 24             	mov    %eax,(%esp)
80102582:	e8 df 1f 00 00       	call   80104566 <log_write>
  brelse(bp);
80102587:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010258a:	89 04 24             	mov    %eax,(%esp)
8010258d:	e8 85 dc ff ff       	call   80100217 <brelse>
}
80102592:	c9                   	leave  
80102593:	c3                   	ret    

80102594 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80102594:	55                   	push   %ebp
80102595:	89 e5                	mov    %esp,%ebp
80102597:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010259a:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801025a1:	e8 a5 38 00 00       	call   80105e4b <acquire>

  // Is the inode already cached?
  empty = 0;
801025a6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801025ad:	c7 45 f4 f4 f8 10 80 	movl   $0x8010f8f4,-0xc(%ebp)
801025b4:	eb 59                	jmp    8010260f <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801025b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b9:	8b 40 08             	mov    0x8(%eax),%eax
801025bc:	85 c0                	test   %eax,%eax
801025be:	7e 35                	jle    801025f5 <iget+0x61>
801025c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025c3:	8b 00                	mov    (%eax),%eax
801025c5:	3b 45 08             	cmp    0x8(%ebp),%eax
801025c8:	75 2b                	jne    801025f5 <iget+0x61>
801025ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025cd:	8b 40 04             	mov    0x4(%eax),%eax
801025d0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801025d3:	75 20                	jne    801025f5 <iget+0x61>
      ip->ref++;
801025d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025d8:	8b 40 08             	mov    0x8(%eax),%eax
801025db:	8d 50 01             	lea    0x1(%eax),%edx
801025de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025e1:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801025e4:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801025eb:	e8 bd 38 00 00       	call   80105ead <release>
      return ip;
801025f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025f3:	eb 6f                	jmp    80102664 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801025f5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801025f9:	75 10                	jne    8010260b <iget+0x77>
801025fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025fe:	8b 40 08             	mov    0x8(%eax),%eax
80102601:	85 c0                	test   %eax,%eax
80102603:	75 06                	jne    8010260b <iget+0x77>
      empty = ip;
80102605:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102608:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010260b:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010260f:	81 7d f4 94 08 11 80 	cmpl   $0x80110894,-0xc(%ebp)
80102616:	72 9e                	jb     801025b6 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80102618:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010261c:	75 0c                	jne    8010262a <iget+0x96>
    panic("iget: no inodes");
8010261e:	c7 04 24 c2 97 10 80 	movl   $0x801097c2,(%esp)
80102625:	e8 13 df ff ff       	call   8010053d <panic>

  ip = empty;
8010262a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010262d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80102630:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102633:	8b 55 08             	mov    0x8(%ebp),%edx
80102636:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80102638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010263b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010263e:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80102641:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102644:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010264b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010264e:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80102655:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010265c:	e8 4c 38 00 00       	call   80105ead <release>

  return ip;
80102661:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102664:	c9                   	leave  
80102665:	c3                   	ret    

80102666 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80102666:	55                   	push   %ebp
80102667:	89 e5                	mov    %esp,%ebp
80102669:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010266c:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102673:	e8 d3 37 00 00       	call   80105e4b <acquire>
  ip->ref++;
80102678:	8b 45 08             	mov    0x8(%ebp),%eax
8010267b:	8b 40 08             	mov    0x8(%eax),%eax
8010267e:	8d 50 01             	lea    0x1(%eax),%edx
80102681:	8b 45 08             	mov    0x8(%ebp),%eax
80102684:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102687:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010268e:	e8 1a 38 00 00       	call   80105ead <release>
  return ip;
80102693:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102696:	c9                   	leave  
80102697:	c3                   	ret    

80102698 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80102698:	55                   	push   %ebp
80102699:	89 e5                	mov    %esp,%ebp
8010269b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
8010269e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026a2:	74 0a                	je     801026ae <ilock+0x16>
801026a4:	8b 45 08             	mov    0x8(%ebp),%eax
801026a7:	8b 40 08             	mov    0x8(%eax),%eax
801026aa:	85 c0                	test   %eax,%eax
801026ac:	7f 0c                	jg     801026ba <ilock+0x22>
    panic("ilock");
801026ae:	c7 04 24 d2 97 10 80 	movl   $0x801097d2,(%esp)
801026b5:	e8 83 de ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801026ba:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801026c1:	e8 85 37 00 00       	call   80105e4b <acquire>
  while(ip->flags & I_BUSY)
801026c6:	eb 13                	jmp    801026db <ilock+0x43>
    sleep(ip, &icache.lock);
801026c8:	c7 44 24 04 c0 f8 10 	movl   $0x8010f8c0,0x4(%esp)
801026cf:	80 
801026d0:	8b 45 08             	mov    0x8(%ebp),%eax
801026d3:	89 04 24             	mov    %eax,(%esp)
801026d6:	e8 92 34 00 00       	call   80105b6d <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801026db:	8b 45 08             	mov    0x8(%ebp),%eax
801026de:	8b 40 0c             	mov    0xc(%eax),%eax
801026e1:	83 e0 01             	and    $0x1,%eax
801026e4:	84 c0                	test   %al,%al
801026e6:	75 e0                	jne    801026c8 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801026e8:	8b 45 08             	mov    0x8(%ebp),%eax
801026eb:	8b 40 0c             	mov    0xc(%eax),%eax
801026ee:	89 c2                	mov    %eax,%edx
801026f0:	83 ca 01             	or     $0x1,%edx
801026f3:	8b 45 08             	mov    0x8(%ebp),%eax
801026f6:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801026f9:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102700:	e8 a8 37 00 00       	call   80105ead <release>

  if(!(ip->flags & I_VALID)){
80102705:	8b 45 08             	mov    0x8(%ebp),%eax
80102708:	8b 40 0c             	mov    0xc(%eax),%eax
8010270b:	83 e0 02             	and    $0x2,%eax
8010270e:	85 c0                	test   %eax,%eax
80102710:	0f 85 ce 00 00 00    	jne    801027e4 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80102716:	8b 45 08             	mov    0x8(%ebp),%eax
80102719:	8b 40 04             	mov    0x4(%eax),%eax
8010271c:	c1 e8 03             	shr    $0x3,%eax
8010271f:	8d 50 02             	lea    0x2(%eax),%edx
80102722:	8b 45 08             	mov    0x8(%ebp),%eax
80102725:	8b 00                	mov    (%eax),%eax
80102727:	89 54 24 04          	mov    %edx,0x4(%esp)
8010272b:	89 04 24             	mov    %eax,(%esp)
8010272e:	e8 73 da ff ff       	call   801001a6 <bread>
80102733:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80102736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102739:	8d 50 18             	lea    0x18(%eax),%edx
8010273c:	8b 45 08             	mov    0x8(%ebp),%eax
8010273f:	8b 40 04             	mov    0x4(%eax),%eax
80102742:	83 e0 07             	and    $0x7,%eax
80102745:	c1 e0 06             	shl    $0x6,%eax
80102748:	01 d0                	add    %edx,%eax
8010274a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
8010274d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102750:	0f b7 10             	movzwl (%eax),%edx
80102753:	8b 45 08             	mov    0x8(%ebp),%eax
80102756:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010275a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010275d:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80102761:	8b 45 08             	mov    0x8(%ebp),%eax
80102764:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80102768:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010276b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010276f:	8b 45 08             	mov    0x8(%ebp),%eax
80102772:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80102776:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102779:	0f b7 50 06          	movzwl 0x6(%eax),%edx
8010277d:	8b 45 08             	mov    0x8(%ebp),%eax
80102780:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80102784:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102787:	8b 50 08             	mov    0x8(%eax),%edx
8010278a:	8b 45 08             	mov    0x8(%ebp),%eax
8010278d:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80102790:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102793:	8d 50 0c             	lea    0xc(%eax),%edx
80102796:	8b 45 08             	mov    0x8(%ebp),%eax
80102799:	83 c0 1c             	add    $0x1c,%eax
8010279c:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801027a3:	00 
801027a4:	89 54 24 04          	mov    %edx,0x4(%esp)
801027a8:	89 04 24             	mov    %eax,(%esp)
801027ab:	e8 bd 39 00 00       	call   8010616d <memmove>
    brelse(bp);
801027b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027b3:	89 04 24             	mov    %eax,(%esp)
801027b6:	e8 5c da ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801027bb:	8b 45 08             	mov    0x8(%ebp),%eax
801027be:	8b 40 0c             	mov    0xc(%eax),%eax
801027c1:	89 c2                	mov    %eax,%edx
801027c3:	83 ca 02             	or     $0x2,%edx
801027c6:	8b 45 08             	mov    0x8(%ebp),%eax
801027c9:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801027cc:	8b 45 08             	mov    0x8(%ebp),%eax
801027cf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801027d3:	66 85 c0             	test   %ax,%ax
801027d6:	75 0c                	jne    801027e4 <ilock+0x14c>
      panic("ilock: no type");
801027d8:	c7 04 24 d8 97 10 80 	movl   $0x801097d8,(%esp)
801027df:	e8 59 dd ff ff       	call   8010053d <panic>
  }
}
801027e4:	c9                   	leave  
801027e5:	c3                   	ret    

801027e6 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801027e6:	55                   	push   %ebp
801027e7:	89 e5                	mov    %esp,%ebp
801027e9:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801027ec:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801027f0:	74 17                	je     80102809 <iunlock+0x23>
801027f2:	8b 45 08             	mov    0x8(%ebp),%eax
801027f5:	8b 40 0c             	mov    0xc(%eax),%eax
801027f8:	83 e0 01             	and    $0x1,%eax
801027fb:	85 c0                	test   %eax,%eax
801027fd:	74 0a                	je     80102809 <iunlock+0x23>
801027ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102802:	8b 40 08             	mov    0x8(%eax),%eax
80102805:	85 c0                	test   %eax,%eax
80102807:	7f 0c                	jg     80102815 <iunlock+0x2f>
    panic("iunlock");
80102809:	c7 04 24 e7 97 10 80 	movl   $0x801097e7,(%esp)
80102810:	e8 28 dd ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102815:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
8010281c:	e8 2a 36 00 00       	call   80105e4b <acquire>
  ip->flags &= ~I_BUSY;
80102821:	8b 45 08             	mov    0x8(%ebp),%eax
80102824:	8b 40 0c             	mov    0xc(%eax),%eax
80102827:	89 c2                	mov    %eax,%edx
80102829:	83 e2 fe             	and    $0xfffffffe,%edx
8010282c:	8b 45 08             	mov    0x8(%ebp),%eax
8010282f:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102832:	8b 45 08             	mov    0x8(%ebp),%eax
80102835:	89 04 24             	mov    %eax,(%esp)
80102838:	e8 09 34 00 00       	call   80105c46 <wakeup>
  release(&icache.lock);
8010283d:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102844:	e8 64 36 00 00       	call   80105ead <release>
}
80102849:	c9                   	leave  
8010284a:	c3                   	ret    

8010284b <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
8010284b:	55                   	push   %ebp
8010284c:	89 e5                	mov    %esp,%ebp
8010284e:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102851:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102858:	e8 ee 35 00 00       	call   80105e4b <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
8010285d:	8b 45 08             	mov    0x8(%ebp),%eax
80102860:	8b 40 08             	mov    0x8(%eax),%eax
80102863:	83 f8 01             	cmp    $0x1,%eax
80102866:	0f 85 93 00 00 00    	jne    801028ff <iput+0xb4>
8010286c:	8b 45 08             	mov    0x8(%ebp),%eax
8010286f:	8b 40 0c             	mov    0xc(%eax),%eax
80102872:	83 e0 02             	and    $0x2,%eax
80102875:	85 c0                	test   %eax,%eax
80102877:	0f 84 82 00 00 00    	je     801028ff <iput+0xb4>
8010287d:	8b 45 08             	mov    0x8(%ebp),%eax
80102880:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80102884:	66 85 c0             	test   %ax,%ax
80102887:	75 76                	jne    801028ff <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80102889:	8b 45 08             	mov    0x8(%ebp),%eax
8010288c:	8b 40 0c             	mov    0xc(%eax),%eax
8010288f:	83 e0 01             	and    $0x1,%eax
80102892:	84 c0                	test   %al,%al
80102894:	74 0c                	je     801028a2 <iput+0x57>
      panic("iput busy");
80102896:	c7 04 24 ef 97 10 80 	movl   $0x801097ef,(%esp)
8010289d:	e8 9b dc ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801028a2:	8b 45 08             	mov    0x8(%ebp),%eax
801028a5:	8b 40 0c             	mov    0xc(%eax),%eax
801028a8:	89 c2                	mov    %eax,%edx
801028aa:	83 ca 01             	or     $0x1,%edx
801028ad:	8b 45 08             	mov    0x8(%ebp),%eax
801028b0:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
801028b3:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801028ba:	e8 ee 35 00 00       	call   80105ead <release>
    itrunc(ip);
801028bf:	8b 45 08             	mov    0x8(%ebp),%eax
801028c2:	89 04 24             	mov    %eax,(%esp)
801028c5:	e8 72 01 00 00       	call   80102a3c <itrunc>
    ip->type = 0;
801028ca:	8b 45 08             	mov    0x8(%ebp),%eax
801028cd:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
801028d3:	8b 45 08             	mov    0x8(%ebp),%eax
801028d6:	89 04 24             	mov    %eax,(%esp)
801028d9:	e8 fe fb ff ff       	call   801024dc <iupdate>
    acquire(&icache.lock);
801028de:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
801028e5:	e8 61 35 00 00       	call   80105e4b <acquire>
    ip->flags = 0;
801028ea:	8b 45 08             	mov    0x8(%ebp),%eax
801028ed:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
801028f4:	8b 45 08             	mov    0x8(%ebp),%eax
801028f7:	89 04 24             	mov    %eax,(%esp)
801028fa:	e8 47 33 00 00       	call   80105c46 <wakeup>
  }
  ip->ref--;
801028ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102902:	8b 40 08             	mov    0x8(%eax),%eax
80102905:	8d 50 ff             	lea    -0x1(%eax),%edx
80102908:	8b 45 08             	mov    0x8(%ebp),%eax
8010290b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010290e:	c7 04 24 c0 f8 10 80 	movl   $0x8010f8c0,(%esp)
80102915:	e8 93 35 00 00       	call   80105ead <release>
}
8010291a:	c9                   	leave  
8010291b:	c3                   	ret    

8010291c <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
8010291c:	55                   	push   %ebp
8010291d:	89 e5                	mov    %esp,%ebp
8010291f:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102922:	8b 45 08             	mov    0x8(%ebp),%eax
80102925:	89 04 24             	mov    %eax,(%esp)
80102928:	e8 b9 fe ff ff       	call   801027e6 <iunlock>
  iput(ip);
8010292d:	8b 45 08             	mov    0x8(%ebp),%eax
80102930:	89 04 24             	mov    %eax,(%esp)
80102933:	e8 13 ff ff ff       	call   8010284b <iput>
}
80102938:	c9                   	leave  
80102939:	c3                   	ret    

8010293a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010293a:	55                   	push   %ebp
8010293b:	89 e5                	mov    %esp,%ebp
8010293d:	53                   	push   %ebx
8010293e:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102941:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80102945:	77 3e                	ja     80102985 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80102947:	8b 45 08             	mov    0x8(%ebp),%eax
8010294a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010294d:	83 c2 04             	add    $0x4,%edx
80102950:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102954:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102957:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010295b:	75 20                	jne    8010297d <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
8010295d:	8b 45 08             	mov    0x8(%ebp),%eax
80102960:	8b 00                	mov    (%eax),%eax
80102962:	89 04 24             	mov    %eax,(%esp)
80102965:	e8 49 f8 ff ff       	call   801021b3 <balloc>
8010296a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010296d:	8b 45 08             	mov    0x8(%ebp),%eax
80102970:	8b 55 0c             	mov    0xc(%ebp),%edx
80102973:	8d 4a 04             	lea    0x4(%edx),%ecx
80102976:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102979:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
8010297d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102980:	e9 b1 00 00 00       	jmp    80102a36 <bmap+0xfc>
  }
  bn -= NDIRECT;
80102985:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80102989:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
8010298d:	0f 87 97 00 00 00    	ja     80102a2a <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80102993:	8b 45 08             	mov    0x8(%ebp),%eax
80102996:	8b 40 4c             	mov    0x4c(%eax),%eax
80102999:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010299c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801029a0:	75 19                	jne    801029bb <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801029a2:	8b 45 08             	mov    0x8(%ebp),%eax
801029a5:	8b 00                	mov    (%eax),%eax
801029a7:	89 04 24             	mov    %eax,(%esp)
801029aa:	e8 04 f8 ff ff       	call   801021b3 <balloc>
801029af:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029b2:	8b 45 08             	mov    0x8(%ebp),%eax
801029b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029b8:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
801029bb:	8b 45 08             	mov    0x8(%ebp),%eax
801029be:	8b 00                	mov    (%eax),%eax
801029c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029c3:	89 54 24 04          	mov    %edx,0x4(%esp)
801029c7:	89 04 24             	mov    %eax,(%esp)
801029ca:	e8 d7 d7 ff ff       	call   801001a6 <bread>
801029cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
801029d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801029d5:	83 c0 18             	add    $0x18,%eax
801029d8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
801029db:	8b 45 0c             	mov    0xc(%ebp),%eax
801029de:	c1 e0 02             	shl    $0x2,%eax
801029e1:	03 45 ec             	add    -0x14(%ebp),%eax
801029e4:	8b 00                	mov    (%eax),%eax
801029e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029e9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801029ed:	75 2b                	jne    80102a1a <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
801029ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801029f2:	c1 e0 02             	shl    $0x2,%eax
801029f5:	89 c3                	mov    %eax,%ebx
801029f7:	03 5d ec             	add    -0x14(%ebp),%ebx
801029fa:	8b 45 08             	mov    0x8(%ebp),%eax
801029fd:	8b 00                	mov    (%eax),%eax
801029ff:	89 04 24             	mov    %eax,(%esp)
80102a02:	e8 ac f7 ff ff       	call   801021b3 <balloc>
80102a07:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a0d:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80102a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a12:	89 04 24             	mov    %eax,(%esp)
80102a15:	e8 4c 1b 00 00       	call   80104566 <log_write>
    }
    brelse(bp);
80102a1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a1d:	89 04 24             	mov    %eax,(%esp)
80102a20:	e8 f2 d7 ff ff       	call   80100217 <brelse>
    return addr;
80102a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a28:	eb 0c                	jmp    80102a36 <bmap+0xfc>
  }

  panic("bmap: out of range");
80102a2a:	c7 04 24 f9 97 10 80 	movl   $0x801097f9,(%esp)
80102a31:	e8 07 db ff ff       	call   8010053d <panic>
}
80102a36:	83 c4 24             	add    $0x24,%esp
80102a39:	5b                   	pop    %ebx
80102a3a:	5d                   	pop    %ebp
80102a3b:	c3                   	ret    

80102a3c <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102a3c:	55                   	push   %ebp
80102a3d:	89 e5                	mov    %esp,%ebp
80102a3f:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102a42:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102a49:	eb 7c                	jmp    80102ac7 <itrunc+0x8b>
    if(ip->addrs[i]){
80102a4b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a4e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a51:	83 c2 04             	add    $0x4,%edx
80102a54:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a58:	85 c0                	test   %eax,%eax
80102a5a:	74 67                	je     80102ac3 <itrunc+0x87>
      if(getBlkRef(ip->addrs[i]) > 0)
80102a5c:	8b 45 08             	mov    0x8(%ebp),%eax
80102a5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a62:	83 c2 04             	add    $0x4,%edx
80102a65:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a69:	89 04 24             	mov    %eax,(%esp)
80102a6c:	e8 e5 0b 00 00       	call   80103656 <getBlkRef>
80102a71:	85 c0                	test   %eax,%eax
80102a73:	7e 1f                	jle    80102a94 <itrunc+0x58>
	updateBlkRef(ip->addrs[i],-1);
80102a75:	8b 45 08             	mov    0x8(%ebp),%eax
80102a78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a7b:	83 c2 04             	add    $0x4,%edx
80102a7e:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80102a82:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102a89:	ff 
80102a8a:	89 04 24             	mov    %eax,(%esp)
80102a8d:	e8 85 0a 00 00       	call   80103517 <updateBlkRef>
80102a92:	eb 1e                	jmp    80102ab2 <itrunc+0x76>
      else
	bfree(ip->dev, ip->addrs[i]);
80102a94:	8b 45 08             	mov    0x8(%ebp),%eax
80102a97:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102a9a:	83 c2 04             	add    $0x4,%edx
80102a9d:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80102aa1:	8b 45 08             	mov    0x8(%ebp),%eax
80102aa4:	8b 00                	mov    (%eax),%eax
80102aa6:	89 54 24 04          	mov    %edx,0x4(%esp)
80102aaa:	89 04 24             	mov    %eax,(%esp)
80102aad:	e8 58 f8 ff ff       	call   8010230a <bfree>
      ip->addrs[i] = 0;
80102ab2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ab8:	83 c2 04             	add    $0x4,%edx
80102abb:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80102ac2:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102ac3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102ac7:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80102acb:	0f 8e 7a ff ff ff    	jle    80102a4b <itrunc+0xf>
	bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80102ad1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad4:	8b 40 4c             	mov    0x4c(%eax),%eax
80102ad7:	85 c0                	test   %eax,%eax
80102ad9:	0f 84 c3 00 00 00    	je     80102ba2 <itrunc+0x166>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80102adf:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae2:	8b 50 4c             	mov    0x4c(%eax),%edx
80102ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae8:	8b 00                	mov    (%eax),%eax
80102aea:	89 54 24 04          	mov    %edx,0x4(%esp)
80102aee:	89 04 24             	mov    %eax,(%esp)
80102af1:	e8 b0 d6 ff ff       	call   801001a6 <bread>
80102af6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102af9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102afc:	83 c0 18             	add    $0x18,%eax
80102aff:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80102b02:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102b09:	eb 63                	jmp    80102b6e <itrunc+0x132>
      if(a[j])
80102b0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b0e:	c1 e0 02             	shl    $0x2,%eax
80102b11:	03 45 e8             	add    -0x18(%ebp),%eax
80102b14:	8b 00                	mov    (%eax),%eax
80102b16:	85 c0                	test   %eax,%eax
80102b18:	74 50                	je     80102b6a <itrunc+0x12e>
      {
	if(getBlkRef(a[j]) > 0)
80102b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b1d:	c1 e0 02             	shl    $0x2,%eax
80102b20:	03 45 e8             	add    -0x18(%ebp),%eax
80102b23:	8b 00                	mov    (%eax),%eax
80102b25:	89 04 24             	mov    %eax,(%esp)
80102b28:	e8 29 0b 00 00       	call   80103656 <getBlkRef>
80102b2d:	85 c0                	test   %eax,%eax
80102b2f:	7e 1d                	jle    80102b4e <itrunc+0x112>
	  updateBlkRef(a[j],-1);
80102b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b34:	c1 e0 02             	shl    $0x2,%eax
80102b37:	03 45 e8             	add    -0x18(%ebp),%eax
80102b3a:	8b 00                	mov    (%eax),%eax
80102b3c:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102b43:	ff 
80102b44:	89 04 24             	mov    %eax,(%esp)
80102b47:	e8 cb 09 00 00       	call   80103517 <updateBlkRef>
80102b4c:	eb 1c                	jmp    80102b6a <itrunc+0x12e>
	else
	  bfree(ip->dev, a[j]);
80102b4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b51:	c1 e0 02             	shl    $0x2,%eax
80102b54:	03 45 e8             	add    -0x18(%ebp),%eax
80102b57:	8b 10                	mov    (%eax),%edx
80102b59:	8b 45 08             	mov    0x8(%ebp),%eax
80102b5c:	8b 00                	mov    (%eax),%eax
80102b5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102b62:	89 04 24             	mov    %eax,(%esp)
80102b65:	e8 a0 f7 ff ff       	call   8010230a <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102b6a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102b6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b71:	83 f8 7f             	cmp    $0x7f,%eax
80102b74:	76 95                	jbe    80102b0b <itrunc+0xcf>
	  updateBlkRef(a[j],-1);
	else
	  bfree(ip->dev, a[j]);
      }
    }
    brelse(bp);
80102b76:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b79:	89 04 24             	mov    %eax,(%esp)
80102b7c:	e8 96 d6 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102b81:	8b 45 08             	mov    0x8(%ebp),%eax
80102b84:	8b 50 4c             	mov    0x4c(%eax),%edx
80102b87:	8b 45 08             	mov    0x8(%ebp),%eax
80102b8a:	8b 00                	mov    (%eax),%eax
80102b8c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102b90:	89 04 24             	mov    %eax,(%esp)
80102b93:	e8 72 f7 ff ff       	call   8010230a <bfree>
    ip->addrs[NDIRECT] = 0;
80102b98:	8b 45 08             	mov    0x8(%ebp),%eax
80102b9b:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102ba2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ba5:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102bac:	8b 45 08             	mov    0x8(%ebp),%eax
80102baf:	89 04 24             	mov    %eax,(%esp)
80102bb2:	e8 25 f9 ff ff       	call   801024dc <iupdate>
}
80102bb7:	c9                   	leave  
80102bb8:	c3                   	ret    

80102bb9 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102bb9:	55                   	push   %ebp
80102bba:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102bbc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bbf:	8b 00                	mov    (%eax),%eax
80102bc1:	89 c2                	mov    %eax,%edx
80102bc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bc6:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80102bc9:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcc:	8b 50 04             	mov    0x4(%eax),%edx
80102bcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bd2:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80102bd5:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd8:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102bdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bdf:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80102be2:	8b 45 08             	mov    0x8(%ebp),%eax
80102be5:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80102be9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bec:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80102bf0:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf3:	8b 50 18             	mov    0x18(%eax),%edx
80102bf6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bf9:	89 50 10             	mov    %edx,0x10(%eax)
}
80102bfc:	5d                   	pop    %ebp
80102bfd:	c3                   	ret    

80102bfe <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80102bfe:	55                   	push   %ebp
80102bff:	89 e5                	mov    %esp,%ebp
80102c01:	53                   	push   %ebx
80102c02:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102c05:	8b 45 08             	mov    0x8(%ebp),%eax
80102c08:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102c0c:	66 83 f8 03          	cmp    $0x3,%ax
80102c10:	75 60                	jne    80102c72 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80102c12:	8b 45 08             	mov    0x8(%ebp),%eax
80102c15:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c19:	66 85 c0             	test   %ax,%ax
80102c1c:	78 20                	js     80102c3e <readi+0x40>
80102c1e:	8b 45 08             	mov    0x8(%ebp),%eax
80102c21:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c25:	66 83 f8 09          	cmp    $0x9,%ax
80102c29:	7f 13                	jg     80102c3e <readi+0x40>
80102c2b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c2e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c32:	98                   	cwtl   
80102c33:	8b 04 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%eax
80102c3a:	85 c0                	test   %eax,%eax
80102c3c:	75 0a                	jne    80102c48 <readi+0x4a>
      return -1;
80102c3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c43:	e9 1b 01 00 00       	jmp    80102d63 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102c48:	8b 45 08             	mov    0x8(%ebp),%eax
80102c4b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102c4f:	98                   	cwtl   
80102c50:	8b 14 c5 40 f8 10 80 	mov    -0x7fef07c0(,%eax,8),%edx
80102c57:	8b 45 14             	mov    0x14(%ebp),%eax
80102c5a:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c5e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c61:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c65:	8b 45 08             	mov    0x8(%ebp),%eax
80102c68:	89 04 24             	mov    %eax,(%esp)
80102c6b:	ff d2                	call   *%edx
80102c6d:	e9 f1 00 00 00       	jmp    80102d63 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102c72:	8b 45 08             	mov    0x8(%ebp),%eax
80102c75:	8b 40 18             	mov    0x18(%eax),%eax
80102c78:	3b 45 10             	cmp    0x10(%ebp),%eax
80102c7b:	72 0d                	jb     80102c8a <readi+0x8c>
80102c7d:	8b 45 14             	mov    0x14(%ebp),%eax
80102c80:	8b 55 10             	mov    0x10(%ebp),%edx
80102c83:	01 d0                	add    %edx,%eax
80102c85:	3b 45 10             	cmp    0x10(%ebp),%eax
80102c88:	73 0a                	jae    80102c94 <readi+0x96>
    return -1;
80102c8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c8f:	e9 cf 00 00 00       	jmp    80102d63 <readi+0x165>
  if(off + n > ip->size)
80102c94:	8b 45 14             	mov    0x14(%ebp),%eax
80102c97:	8b 55 10             	mov    0x10(%ebp),%edx
80102c9a:	01 c2                	add    %eax,%edx
80102c9c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c9f:	8b 40 18             	mov    0x18(%eax),%eax
80102ca2:	39 c2                	cmp    %eax,%edx
80102ca4:	76 0c                	jbe    80102cb2 <readi+0xb4>
    n = ip->size - off;
80102ca6:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca9:	8b 40 18             	mov    0x18(%eax),%eax
80102cac:	2b 45 10             	sub    0x10(%ebp),%eax
80102caf:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102cb2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102cb9:	e9 96 00 00 00       	jmp    80102d54 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102cbe:	8b 45 10             	mov    0x10(%ebp),%eax
80102cc1:	c1 e8 09             	shr    $0x9,%eax
80102cc4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cc8:	8b 45 08             	mov    0x8(%ebp),%eax
80102ccb:	89 04 24             	mov    %eax,(%esp)
80102cce:	e8 67 fc ff ff       	call   8010293a <bmap>
80102cd3:	8b 55 08             	mov    0x8(%ebp),%edx
80102cd6:	8b 12                	mov    (%edx),%edx
80102cd8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cdc:	89 14 24             	mov    %edx,(%esp)
80102cdf:	e8 c2 d4 ff ff       	call   801001a6 <bread>
80102ce4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102ce7:	8b 45 10             	mov    0x10(%ebp),%eax
80102cea:	89 c2                	mov    %eax,%edx
80102cec:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102cf2:	b8 00 02 00 00       	mov    $0x200,%eax
80102cf7:	89 c1                	mov    %eax,%ecx
80102cf9:	29 d1                	sub    %edx,%ecx
80102cfb:	89 ca                	mov    %ecx,%edx
80102cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d00:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102d03:	89 cb                	mov    %ecx,%ebx
80102d05:	29 c3                	sub    %eax,%ebx
80102d07:	89 d8                	mov    %ebx,%eax
80102d09:	39 c2                	cmp    %eax,%edx
80102d0b:	0f 46 c2             	cmovbe %edx,%eax
80102d0e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d14:	8d 50 18             	lea    0x18(%eax),%edx
80102d17:	8b 45 10             	mov    0x10(%ebp),%eax
80102d1a:	25 ff 01 00 00       	and    $0x1ff,%eax
80102d1f:	01 c2                	add    %eax,%edx
80102d21:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d24:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d28:	89 54 24 04          	mov    %edx,0x4(%esp)
80102d2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d2f:	89 04 24             	mov    %eax,(%esp)
80102d32:	e8 36 34 00 00       	call   8010616d <memmove>
    brelse(bp);
80102d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102d3a:	89 04 24             	mov    %eax,(%esp)
80102d3d:	e8 d5 d4 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102d42:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d45:	01 45 f4             	add    %eax,-0xc(%ebp)
80102d48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d4b:	01 45 10             	add    %eax,0x10(%ebp)
80102d4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102d51:	01 45 0c             	add    %eax,0xc(%ebp)
80102d54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d57:	3b 45 14             	cmp    0x14(%ebp),%eax
80102d5a:	0f 82 5e ff ff ff    	jb     80102cbe <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102d60:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102d63:	83 c4 24             	add    $0x24,%esp
80102d66:	5b                   	pop    %ebx
80102d67:	5d                   	pop    %ebp
80102d68:	c3                   	ret    

80102d69 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102d69:	55                   	push   %ebp
80102d6a:	89 e5                	mov    %esp,%ebp
80102d6c:	53                   	push   %ebx
80102d6d:	83 ec 34             	sub    $0x34,%esp
  uint tot, m,ref;
  struct buf *bp;

  if(ip->type == T_DEV){
80102d70:	8b 45 08             	mov    0x8(%ebp),%eax
80102d73:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102d77:	66 83 f8 03          	cmp    $0x3,%ax
80102d7b:	75 60                	jne    80102ddd <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102d80:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d84:	66 85 c0             	test   %ax,%ax
80102d87:	78 20                	js     80102da9 <writei+0x40>
80102d89:	8b 45 08             	mov    0x8(%ebp),%eax
80102d8c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d90:	66 83 f8 09          	cmp    $0x9,%ax
80102d94:	7f 13                	jg     80102da9 <writei+0x40>
80102d96:	8b 45 08             	mov    0x8(%ebp),%eax
80102d99:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102d9d:	98                   	cwtl   
80102d9e:	8b 04 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%eax
80102da5:	85 c0                	test   %eax,%eax
80102da7:	75 0a                	jne    80102db3 <writei+0x4a>
      return -1;
80102da9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102dae:	e9 c4 01 00 00       	jmp    80102f77 <writei+0x20e>
    return devsw[ip->major].write(ip, src, n);
80102db3:	8b 45 08             	mov    0x8(%ebp),%eax
80102db6:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102dba:	98                   	cwtl   
80102dbb:	8b 14 c5 44 f8 10 80 	mov    -0x7fef07bc(,%eax,8),%edx
80102dc2:	8b 45 14             	mov    0x14(%ebp),%eax
80102dc5:	89 44 24 08          	mov    %eax,0x8(%esp)
80102dc9:	8b 45 0c             	mov    0xc(%ebp),%eax
80102dcc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dd0:	8b 45 08             	mov    0x8(%ebp),%eax
80102dd3:	89 04 24             	mov    %eax,(%esp)
80102dd6:	ff d2                	call   *%edx
80102dd8:	e9 9a 01 00 00       	jmp    80102f77 <writei+0x20e>
  }

  if(off > ip->size || off + n < off)
80102ddd:	8b 45 08             	mov    0x8(%ebp),%eax
80102de0:	8b 40 18             	mov    0x18(%eax),%eax
80102de3:	3b 45 10             	cmp    0x10(%ebp),%eax
80102de6:	72 0d                	jb     80102df5 <writei+0x8c>
80102de8:	8b 45 14             	mov    0x14(%ebp),%eax
80102deb:	8b 55 10             	mov    0x10(%ebp),%edx
80102dee:	01 d0                	add    %edx,%eax
80102df0:	3b 45 10             	cmp    0x10(%ebp),%eax
80102df3:	73 0a                	jae    80102dff <writei+0x96>
    return -1;
80102df5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102dfa:	e9 78 01 00 00       	jmp    80102f77 <writei+0x20e>
  if(off + n > MAXFILE*BSIZE)
80102dff:	8b 45 14             	mov    0x14(%ebp),%eax
80102e02:	8b 55 10             	mov    0x10(%ebp),%edx
80102e05:	01 d0                	add    %edx,%eax
80102e07:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102e0c:	76 0a                	jbe    80102e18 <writei+0xaf>
    return -1;
80102e0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e13:	e9 5f 01 00 00       	jmp    80102f77 <writei+0x20e>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102e18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102e1f:	e9 1f 01 00 00       	jmp    80102f43 <writei+0x1da>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102e24:	8b 45 10             	mov    0x10(%ebp),%eax
80102e27:	c1 e8 09             	shr    $0x9,%eax
80102e2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80102e31:	89 04 24             	mov    %eax,(%esp)
80102e34:	e8 01 fb ff ff       	call   8010293a <bmap>
80102e39:	8b 55 08             	mov    0x8(%ebp),%edx
80102e3c:	8b 12                	mov    (%edx),%edx
80102e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e42:	89 14 24             	mov    %edx,(%esp)
80102e45:	e8 5c d3 ff ff       	call   801001a6 <bread>
80102e4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((ref = getBlkRef(bp->sector)) > 0)
80102e4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e50:	8b 40 08             	mov    0x8(%eax),%eax
80102e53:	89 04 24             	mov    %eax,(%esp)
80102e56:	e8 fb 07 00 00       	call   80103656 <getBlkRef>
80102e5b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80102e5e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80102e62:	74 67                	je     80102ecb <writei+0x162>
    {
      uint old = bp->sector;
80102e64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e67:	8b 40 08             	mov    0x8(%eax),%eax
80102e6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      updateBlkRef(old,-1);
80102e6d:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102e74:	ff 
80102e75:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102e78:	89 04 24             	mov    %eax,(%esp)
80102e7b:	e8 97 06 00 00       	call   80103517 <updateBlkRef>
      brelse(bp);
80102e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e83:	89 04 24             	mov    %eax,(%esp)
80102e86:	e8 8c d3 ff ff       	call   80100217 <brelse>
      uint new = balloc(ip->dev);
80102e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80102e8e:	8b 00                	mov    (%eax),%eax
80102e90:	89 04 24             	mov    %eax,(%esp)
80102e93:	e8 1b f3 ff ff       	call   801021b3 <balloc>
80102e98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      replaceBlk(ip,old,new);
80102e9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e9e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ea2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102ea5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ea9:	8b 45 08             	mov    0x8(%ebp),%eax
80102eac:	89 04 24             	mov    %eax,(%esp)
80102eaf:	e8 a0 f1 ff ff       	call   80102054 <replaceBlk>
      bp = bread(ip->dev,new);
80102eb4:	8b 45 08             	mov    0x8(%ebp),%eax
80102eb7:	8b 00                	mov    (%eax),%eax
80102eb9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102ebc:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ec0:	89 04 24             	mov    %eax,(%esp)
80102ec3:	e8 de d2 ff ff       	call   801001a6 <bread>
80102ec8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    m = min(n - tot, BSIZE - off%BSIZE);
80102ecb:	8b 45 10             	mov    0x10(%ebp),%eax
80102ece:	89 c2                	mov    %eax,%edx
80102ed0:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102ed6:	b8 00 02 00 00       	mov    $0x200,%eax
80102edb:	89 c1                	mov    %eax,%ecx
80102edd:	29 d1                	sub    %edx,%ecx
80102edf:	89 ca                	mov    %ecx,%edx
80102ee1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ee4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102ee7:	89 cb                	mov    %ecx,%ebx
80102ee9:	29 c3                	sub    %eax,%ebx
80102eeb:	89 d8                	mov    %ebx,%eax
80102eed:	39 c2                	cmp    %eax,%edx
80102eef:	0f 46 c2             	cmovbe %edx,%eax
80102ef2:	89 45 e0             	mov    %eax,-0x20(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102ef5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ef8:	8d 50 18             	lea    0x18(%eax),%edx
80102efb:	8b 45 10             	mov    0x10(%ebp),%eax
80102efe:	25 ff 01 00 00       	and    $0x1ff,%eax
80102f03:	01 c2                	add    %eax,%edx
80102f05:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f08:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f13:	89 14 24             	mov    %edx,(%esp)
80102f16:	e8 52 32 00 00       	call   8010616d <memmove>
    log_write(bp);
80102f1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f1e:	89 04 24             	mov    %eax,(%esp)
80102f21:	e8 40 16 00 00       	call   80104566 <log_write>
    brelse(bp);
80102f26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f29:	89 04 24             	mov    %eax,(%esp)
80102f2c:	e8 e6 d2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102f31:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f34:	01 45 f4             	add    %eax,-0xc(%ebp)
80102f37:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f3a:	01 45 10             	add    %eax,0x10(%ebp)
80102f3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102f40:	01 45 0c             	add    %eax,0xc(%ebp)
80102f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f46:	3b 45 14             	cmp    0x14(%ebp),%eax
80102f49:	0f 82 d5 fe ff ff    	jb     80102e24 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102f4f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102f53:	74 1f                	je     80102f74 <writei+0x20b>
80102f55:	8b 45 08             	mov    0x8(%ebp),%eax
80102f58:	8b 40 18             	mov    0x18(%eax),%eax
80102f5b:	3b 45 10             	cmp    0x10(%ebp),%eax
80102f5e:	73 14                	jae    80102f74 <writei+0x20b>
    ip->size = off;
80102f60:	8b 45 08             	mov    0x8(%ebp),%eax
80102f63:	8b 55 10             	mov    0x10(%ebp),%edx
80102f66:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102f69:	8b 45 08             	mov    0x8(%ebp),%eax
80102f6c:	89 04 24             	mov    %eax,(%esp)
80102f6f:	e8 68 f5 ff ff       	call   801024dc <iupdate>
  }
  return n;
80102f74:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102f77:	83 c4 34             	add    $0x34,%esp
80102f7a:	5b                   	pop    %ebx
80102f7b:	5d                   	pop    %ebp
80102f7c:	c3                   	ret    

80102f7d <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102f7d:	55                   	push   %ebp
80102f7e:	89 e5                	mov    %esp,%ebp
80102f80:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102f83:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102f8a:	00 
80102f8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f8e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f92:	8b 45 08             	mov    0x8(%ebp),%eax
80102f95:	89 04 24             	mov    %eax,(%esp)
80102f98:	e8 74 32 00 00       	call   80106211 <strncmp>
}
80102f9d:	c9                   	leave  
80102f9e:	c3                   	ret    

80102f9f <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102f9f:	55                   	push   %ebp
80102fa0:	89 e5                	mov    %esp,%ebp
80102fa2:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102fa5:	8b 45 08             	mov    0x8(%ebp),%eax
80102fa8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102fac:	66 83 f8 01          	cmp    $0x1,%ax
80102fb0:	74 0c                	je     80102fbe <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102fb2:	c7 04 24 0c 98 10 80 	movl   $0x8010980c,(%esp)
80102fb9:	e8 7f d5 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102fbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102fc5:	e9 87 00 00 00       	jmp    80103051 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102fca:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102fd1:	00 
80102fd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fd5:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fd9:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102fdc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80102fe3:	89 04 24             	mov    %eax,(%esp)
80102fe6:	e8 13 fc ff ff       	call   80102bfe <readi>
80102feb:	83 f8 10             	cmp    $0x10,%eax
80102fee:	74 0c                	je     80102ffc <dirlookup+0x5d>
      panic("dirlink read");
80102ff0:	c7 04 24 1e 98 10 80 	movl   $0x8010981e,(%esp)
80102ff7:	e8 41 d5 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102ffc:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80103000:	66 85 c0             	test   %ax,%ax
80103003:	74 47                	je     8010304c <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80103005:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103008:	83 c0 02             	add    $0x2,%eax
8010300b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010300f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103012:	89 04 24             	mov    %eax,(%esp)
80103015:	e8 63 ff ff ff       	call   80102f7d <namecmp>
8010301a:	85 c0                	test   %eax,%eax
8010301c:	75 2f                	jne    8010304d <dirlookup+0xae>
      // entry matches path element
      if(poff)
8010301e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80103022:	74 08                	je     8010302c <dirlookup+0x8d>
        *poff = off;
80103024:	8b 45 10             	mov    0x10(%ebp),%eax
80103027:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010302a:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010302c:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80103030:	0f b7 c0             	movzwl %ax,%eax
80103033:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80103036:	8b 45 08             	mov    0x8(%ebp),%eax
80103039:	8b 00                	mov    (%eax),%eax
8010303b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010303e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103042:	89 04 24             	mov    %eax,(%esp)
80103045:	e8 4a f5 ff ff       	call   80102594 <iget>
8010304a:	eb 19                	jmp    80103065 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
8010304c:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010304d:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103051:	8b 45 08             	mov    0x8(%ebp),%eax
80103054:	8b 40 18             	mov    0x18(%eax),%eax
80103057:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010305a:	0f 87 6a ff ff ff    	ja     80102fca <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80103060:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103065:	c9                   	leave  
80103066:	c3                   	ret    

80103067 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80103067:	55                   	push   %ebp
80103068:	89 e5                	mov    %esp,%ebp
8010306a:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010306d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103074:	00 
80103075:	8b 45 0c             	mov    0xc(%ebp),%eax
80103078:	89 44 24 04          	mov    %eax,0x4(%esp)
8010307c:	8b 45 08             	mov    0x8(%ebp),%eax
8010307f:	89 04 24             	mov    %eax,(%esp)
80103082:	e8 18 ff ff ff       	call   80102f9f <dirlookup>
80103087:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010308a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010308e:	74 15                	je     801030a5 <dirlink+0x3e>
    iput(ip);
80103090:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103093:	89 04 24             	mov    %eax,(%esp)
80103096:	e8 b0 f7 ff ff       	call   8010284b <iput>
    return -1;
8010309b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801030a0:	e9 b8 00 00 00       	jmp    8010315d <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801030a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030ac:	eb 44                	jmp    801030f2 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801030ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030b1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801030b8:	00 
801030b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801030bd:	8d 45 e0             	lea    -0x20(%ebp),%eax
801030c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801030c4:	8b 45 08             	mov    0x8(%ebp),%eax
801030c7:	89 04 24             	mov    %eax,(%esp)
801030ca:	e8 2f fb ff ff       	call   80102bfe <readi>
801030cf:	83 f8 10             	cmp    $0x10,%eax
801030d2:	74 0c                	je     801030e0 <dirlink+0x79>
      panic("dirlink read");
801030d4:	c7 04 24 1e 98 10 80 	movl   $0x8010981e,(%esp)
801030db:	e8 5d d4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801030e0:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801030e4:	66 85 c0             	test   %ax,%ax
801030e7:	74 18                	je     80103101 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801030e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030ec:	83 c0 10             	add    $0x10,%eax
801030ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
801030f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801030f5:	8b 45 08             	mov    0x8(%ebp),%eax
801030f8:	8b 40 18             	mov    0x18(%eax),%eax
801030fb:	39 c2                	cmp    %eax,%edx
801030fd:	72 af                	jb     801030ae <dirlink+0x47>
801030ff:	eb 01                	jmp    80103102 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80103101:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80103102:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103109:	00 
8010310a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010310d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103111:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103114:	83 c0 02             	add    $0x2,%eax
80103117:	89 04 24             	mov    %eax,(%esp)
8010311a:	e8 4a 31 00 00       	call   80106269 <strncpy>
  de.inum = inum;
8010311f:	8b 45 10             	mov    0x10(%ebp),%eax
80103122:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80103126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103129:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80103130:	00 
80103131:	89 44 24 08          	mov    %eax,0x8(%esp)
80103135:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103138:	89 44 24 04          	mov    %eax,0x4(%esp)
8010313c:	8b 45 08             	mov    0x8(%ebp),%eax
8010313f:	89 04 24             	mov    %eax,(%esp)
80103142:	e8 22 fc ff ff       	call   80102d69 <writei>
80103147:	83 f8 10             	cmp    $0x10,%eax
8010314a:	74 0c                	je     80103158 <dirlink+0xf1>
    panic("dirlink");
8010314c:	c7 04 24 2b 98 10 80 	movl   $0x8010982b,(%esp)
80103153:	e8 e5 d3 ff ff       	call   8010053d <panic>
  
  return 0;
80103158:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010315d:	c9                   	leave  
8010315e:	c3                   	ret    

8010315f <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010315f:	55                   	push   %ebp
80103160:	89 e5                	mov    %esp,%ebp
80103162:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80103165:	eb 04                	jmp    8010316b <skipelem+0xc>
    path++;
80103167:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010316b:	8b 45 08             	mov    0x8(%ebp),%eax
8010316e:	0f b6 00             	movzbl (%eax),%eax
80103171:	3c 2f                	cmp    $0x2f,%al
80103173:	74 f2                	je     80103167 <skipelem+0x8>
    path++;
  if(*path == 0)
80103175:	8b 45 08             	mov    0x8(%ebp),%eax
80103178:	0f b6 00             	movzbl (%eax),%eax
8010317b:	84 c0                	test   %al,%al
8010317d:	75 0a                	jne    80103189 <skipelem+0x2a>
    return 0;
8010317f:	b8 00 00 00 00       	mov    $0x0,%eax
80103184:	e9 86 00 00 00       	jmp    8010320f <skipelem+0xb0>
  s = path;
80103189:	8b 45 08             	mov    0x8(%ebp),%eax
8010318c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010318f:	eb 04                	jmp    80103195 <skipelem+0x36>
    path++;
80103191:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80103195:	8b 45 08             	mov    0x8(%ebp),%eax
80103198:	0f b6 00             	movzbl (%eax),%eax
8010319b:	3c 2f                	cmp    $0x2f,%al
8010319d:	74 0a                	je     801031a9 <skipelem+0x4a>
8010319f:	8b 45 08             	mov    0x8(%ebp),%eax
801031a2:	0f b6 00             	movzbl (%eax),%eax
801031a5:	84 c0                	test   %al,%al
801031a7:	75 e8                	jne    80103191 <skipelem+0x32>
    path++;
  len = path - s;
801031a9:	8b 55 08             	mov    0x8(%ebp),%edx
801031ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031af:	89 d1                	mov    %edx,%ecx
801031b1:	29 c1                	sub    %eax,%ecx
801031b3:	89 c8                	mov    %ecx,%eax
801031b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801031b8:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801031bc:	7e 1c                	jle    801031da <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801031be:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801031c5:	00 
801031c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801031cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801031d0:	89 04 24             	mov    %eax,(%esp)
801031d3:	e8 95 2f 00 00       	call   8010616d <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801031d8:	eb 28                	jmp    80103202 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801031da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031dd:	89 44 24 08          	mov    %eax,0x8(%esp)
801031e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801031e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801031eb:	89 04 24             	mov    %eax,(%esp)
801031ee:	e8 7a 2f 00 00       	call   8010616d <memmove>
    name[len] = 0;
801031f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031f6:	03 45 0c             	add    0xc(%ebp),%eax
801031f9:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801031fc:	eb 04                	jmp    80103202 <skipelem+0xa3>
    path++;
801031fe:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80103202:	8b 45 08             	mov    0x8(%ebp),%eax
80103205:	0f b6 00             	movzbl (%eax),%eax
80103208:	3c 2f                	cmp    $0x2f,%al
8010320a:	74 f2                	je     801031fe <skipelem+0x9f>
    path++;
  return path;
8010320c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010320f:	c9                   	leave  
80103210:	c3                   	ret    

80103211 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80103211:	55                   	push   %ebp
80103212:	89 e5                	mov    %esp,%ebp
80103214:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80103217:	8b 45 08             	mov    0x8(%ebp),%eax
8010321a:	0f b6 00             	movzbl (%eax),%eax
8010321d:	3c 2f                	cmp    $0x2f,%al
8010321f:	75 1c                	jne    8010323d <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80103221:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103228:	00 
80103229:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103230:	e8 5f f3 ff ff       	call   80102594 <iget>
80103235:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80103238:	e9 af 00 00 00       	jmp    801032ec <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010323d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103243:	8b 40 68             	mov    0x68(%eax),%eax
80103246:	89 04 24             	mov    %eax,(%esp)
80103249:	e8 18 f4 ff ff       	call   80102666 <idup>
8010324e:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80103251:	e9 96 00 00 00       	jmp    801032ec <namex+0xdb>
    ilock(ip);
80103256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103259:	89 04 24             	mov    %eax,(%esp)
8010325c:	e8 37 f4 ff ff       	call   80102698 <ilock>
    if(ip->type != T_DIR){
80103261:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103264:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80103268:	66 83 f8 01          	cmp    $0x1,%ax
8010326c:	74 15                	je     80103283 <namex+0x72>
      iunlockput(ip);
8010326e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103271:	89 04 24             	mov    %eax,(%esp)
80103274:	e8 a3 f6 ff ff       	call   8010291c <iunlockput>
      return 0;
80103279:	b8 00 00 00 00       	mov    $0x0,%eax
8010327e:	e9 a3 00 00 00       	jmp    80103326 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80103283:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103287:	74 1d                	je     801032a6 <namex+0x95>
80103289:	8b 45 08             	mov    0x8(%ebp),%eax
8010328c:	0f b6 00             	movzbl (%eax),%eax
8010328f:	84 c0                	test   %al,%al
80103291:	75 13                	jne    801032a6 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80103293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103296:	89 04 24             	mov    %eax,(%esp)
80103299:	e8 48 f5 ff ff       	call   801027e6 <iunlock>
      return ip;
8010329e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032a1:	e9 80 00 00 00       	jmp    80103326 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801032a6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801032ad:	00 
801032ae:	8b 45 10             	mov    0x10(%ebp),%eax
801032b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801032b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b8:	89 04 24             	mov    %eax,(%esp)
801032bb:	e8 df fc ff ff       	call   80102f9f <dirlookup>
801032c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801032c3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032c7:	75 12                	jne    801032db <namex+0xca>
      iunlockput(ip);
801032c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032cc:	89 04 24             	mov    %eax,(%esp)
801032cf:	e8 48 f6 ff ff       	call   8010291c <iunlockput>
      return 0;
801032d4:	b8 00 00 00 00       	mov    $0x0,%eax
801032d9:	eb 4b                	jmp    80103326 <namex+0x115>
    }
    iunlockput(ip);
801032db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032de:	89 04 24             	mov    %eax,(%esp)
801032e1:	e8 36 f6 ff ff       	call   8010291c <iunlockput>
    ip = next;
801032e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801032ec:	8b 45 10             	mov    0x10(%ebp),%eax
801032ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801032f3:	8b 45 08             	mov    0x8(%ebp),%eax
801032f6:	89 04 24             	mov    %eax,(%esp)
801032f9:	e8 61 fe ff ff       	call   8010315f <skipelem>
801032fe:	89 45 08             	mov    %eax,0x8(%ebp)
80103301:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103305:	0f 85 4b ff ff ff    	jne    80103256 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
8010330b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010330f:	74 12                	je     80103323 <namex+0x112>
    iput(ip);
80103311:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103314:	89 04 24             	mov    %eax,(%esp)
80103317:	e8 2f f5 ff ff       	call   8010284b <iput>
    return 0;
8010331c:	b8 00 00 00 00       	mov    $0x0,%eax
80103321:	eb 03                	jmp    80103326 <namex+0x115>
  }
  return ip;
80103323:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103326:	c9                   	leave  
80103327:	c3                   	ret    

80103328 <namei>:

struct inode*
namei(char *path)
{
80103328:	55                   	push   %ebp
80103329:	89 e5                	mov    %esp,%ebp
8010332b:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010332e:	8d 45 ea             	lea    -0x16(%ebp),%eax
80103331:	89 44 24 08          	mov    %eax,0x8(%esp)
80103335:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010333c:	00 
8010333d:	8b 45 08             	mov    0x8(%ebp),%eax
80103340:	89 04 24             	mov    %eax,(%esp)
80103343:	e8 c9 fe ff ff       	call   80103211 <namex>
}
80103348:	c9                   	leave  
80103349:	c3                   	ret    

8010334a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010334a:	55                   	push   %ebp
8010334b:	89 e5                	mov    %esp,%ebp
8010334d:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80103350:	8b 45 0c             	mov    0xc(%ebp),%eax
80103353:	89 44 24 08          	mov    %eax,0x8(%esp)
80103357:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010335e:	00 
8010335f:	8b 45 08             	mov    0x8(%ebp),%eax
80103362:	89 04 24             	mov    %eax,(%esp)
80103365:	e8 a7 fe ff ff       	call   80103211 <namex>
}
8010336a:	c9                   	leave  
8010336b:	c3                   	ret    

8010336c <getNextInode>:

struct inode*
getNextInode(void)
{
8010336c:	55                   	push   %ebp
8010336d:	89 e5                	mov    %esp,%ebp
8010336f:	83 ec 48             	sub    $0x48,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80103372:	8d 45 d0             	lea    -0x30(%ebp),%eax
80103375:	89 44 24 04          	mov    %eax,0x4(%esp)
80103379:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103380:	e8 97 ed ff ff       	call   8010211c <readsb>
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103385:	a1 18 c6 10 80       	mov    0x8010c618,%eax
8010338a:	83 c0 01             	add    $0x1,%eax
8010338d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103390:	eb 79                	jmp    8010340b <getNextInode+0x9f>
  {
    bp = bread(1, IBLOCK(inum));
80103392:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103395:	c1 e8 03             	shr    $0x3,%eax
80103398:	83 c0 02             	add    $0x2,%eax
8010339b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010339f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033a6:	e8 fb cd ff ff       	call   801001a6 <bread>
801033ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801033ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033b1:	8d 50 18             	lea    0x18(%eax),%edx
801033b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033b7:	83 e0 07             	and    $0x7,%eax
801033ba:	c1 e0 06             	shl    $0x6,%eax
801033bd:	01 d0                	add    %edx,%eax
801033bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
801033c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c5:	0f b7 00             	movzwl (%eax),%eax
801033c8:	66 83 f8 02          	cmp    $0x2,%ax
801033cc:	75 2e                	jne    801033fc <getNextInode+0x90>
    {
      nextInum = inum;
801033ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d1:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      ip = iget(1,inum);
801033d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801033dd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033e4:	e8 ab f1 ff ff       	call   80102594 <iget>
801033e9:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
801033ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033ef:	89 04 24             	mov    %eax,(%esp)
801033f2:	e8 20 ce ff ff       	call   80100217 <brelse>
      return ip;
801033f7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801033fa:	eb 22                	jmp    8010341e <getNextInode+0xb2>
    }
    brelse(bp);
801033fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033ff:	89 04 24             	mov    %eax,(%esp)
80103402:	e8 10 ce ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103407:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010340b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010340e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80103411:	39 c2                	cmp    %eax,%edx
80103413:	0f 82 79 ff ff ff    	jb     80103392 <getNextInode+0x26>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
80103419:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010341e:	c9                   	leave  
8010341f:	c3                   	ret    

80103420 <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
80103420:	55                   	push   %ebp
80103421:	89 e5                	mov    %esp,%ebp
80103423:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
80103426:	e9 8d 00 00 00       	jmp    801034b8 <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
8010342b:	8b 45 08             	mov    0x8(%ebp),%eax
8010342e:	8b 00                	mov    (%eax),%eax
80103430:	c1 e8 03             	shr    $0x3,%eax
80103433:	83 c0 02             	add    $0x2,%eax
80103436:	89 44 24 04          	mov    %eax,0x4(%esp)
8010343a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103441:	e8 60 cd ff ff       	call   801001a6 <bread>
80103446:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
80103449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010344c:	8d 50 18             	lea    0x18(%eax),%edx
8010344f:	8b 45 08             	mov    0x8(%ebp),%eax
80103452:	8b 00                	mov    (%eax),%eax
80103454:	83 e0 07             	and    $0x7,%eax
80103457:	c1 e0 06             	shl    $0x6,%eax
8010345a:	01 d0                	add    %edx,%eax
8010345c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
8010345f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103462:	0f b7 00             	movzwl (%eax),%eax
80103465:	66 83 f8 02          	cmp    $0x2,%ax
80103469:	75 35                	jne    801034a0 <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
8010346b:	8b 45 08             	mov    0x8(%ebp),%eax
8010346e:	8b 00                	mov    (%eax),%eax
80103470:	89 44 24 04          	mov    %eax,0x4(%esp)
80103474:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010347b:	e8 14 f1 ff ff       	call   80102594 <iget>
80103480:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
80103483:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103486:	89 04 24             	mov    %eax,(%esp)
80103489:	e8 89 cd ff ff       	call   80100217 <brelse>
      (*prevInum)--;
8010348e:	8b 45 08             	mov    0x8(%ebp),%eax
80103491:	8b 00                	mov    (%eax),%eax
80103493:	8d 50 ff             	lea    -0x1(%eax),%edx
80103496:	8b 45 08             	mov    0x8(%ebp),%eax
80103499:	89 10                	mov    %edx,(%eax)
      return ip;
8010349b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010349e:	eb 2f                	jmp    801034cf <getPrevInode+0xaf>
    }
    brelse(bp);
801034a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034a3:	89 04 24             	mov    %eax,(%esp)
801034a6:	e8 6c cd ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801034ab:	8b 45 08             	mov    0x8(%ebp),%eax
801034ae:	8b 00                	mov    (%eax),%eax
801034b0:	8d 50 ff             	lea    -0x1(%eax),%edx
801034b3:	8b 45 08             	mov    0x8(%ebp),%eax
801034b6:	89 10                	mov    %edx,(%eax)
801034b8:	8b 45 08             	mov    0x8(%ebp),%eax
801034bb:	8b 10                	mov    (%eax),%edx
801034bd:	a1 18 c6 10 80       	mov    0x8010c618,%eax
801034c2:	39 c2                	cmp    %eax,%edx
801034c4:	0f 8f 61 ff ff ff    	jg     8010342b <getPrevInode+0xb>
      (*prevInum)--;
      return ip;
    }
    brelse(bp);
  }
  return 0;
801034ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034cf:	c9                   	leave  
801034d0:	c3                   	ret    

801034d1 <getRefCount>:

uint
getRefCount(uint ref)
{
801034d1:	55                   	push   %ebp
801034d2:	89 e5                	mov    %esp,%ebp
801034d4:	83 ec 38             	sub    $0x38,%esp
  if(refCount1==0)
801034d7:	a1 a4 f8 10 80       	mov    0x8010f8a4,%eax
801034dc:	85 c0                	test   %eax,%eax
801034de:	75 23                	jne    80103503 <getRefCount+0x32>
  {
    struct superblock sb;
    readsb(1,&sb);
801034e0:	8d 45 e0             	lea    -0x20(%ebp),%eax
801034e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801034e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034ee:	e8 29 ec ff ff       	call   8010211c <readsb>
    refCount1 = sb.refCount1;
801034f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034f6:	a3 a4 f8 10 80       	mov    %eax,0x8010f8a4
    refCount2 = sb.refCount2;
801034fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034fe:	a3 a0 f8 10 80       	mov    %eax,0x8010f8a0
  }
  
  if(ref==1)
80103503:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
80103507:	75 07                	jne    80103510 <getRefCount+0x3f>
    return refCount1;
80103509:	a1 a4 f8 10 80       	mov    0x8010f8a4,%eax
8010350e:	eb 05                	jmp    80103515 <getRefCount+0x44>
  else
    return refCount2;
80103510:	a1 a0 f8 10 80       	mov    0x8010f8a0,%eax
}
80103515:	c9                   	leave  
80103516:	c3                   	ret    

80103517 <updateBlkRef>:

void
updateBlkRef(uint sector, int flag)
{
80103517:	55                   	push   %ebp
80103518:	89 e5                	mov    %esp,%ebp
8010351a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  if(sector < BSIZE)
8010351d:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103524:	0f 87 91 00 00 00    	ja     801035bb <updateBlkRef+0xa4>
  {
    bp = bread(1,getRefCount(1));
8010352a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103531:	e8 9b ff ff ff       	call   801034d1 <getRefCount>
80103536:	89 44 24 04          	mov    %eax,0x4(%esp)
8010353a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103541:	e8 60 cc ff ff       	call   801001a6 <bread>
80103546:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103549:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
8010354d:	75 1e                	jne    8010356d <updateBlkRef+0x56>
      bp->data[sector]++;
8010354f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103552:	03 45 08             	add    0x8(%ebp),%eax
80103555:	83 c0 10             	add    $0x10,%eax
80103558:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010355c:	8d 50 01             	lea    0x1(%eax),%edx
8010355f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103562:	03 45 08             	add    0x8(%ebp),%eax
80103565:	83 c0 10             	add    $0x10,%eax
80103568:	88 50 08             	mov    %dl,0x8(%eax)
8010356b:	eb 33                	jmp    801035a0 <updateBlkRef+0x89>
    else if(flag == -1)
8010356d:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
80103571:	75 2d                	jne    801035a0 <updateBlkRef+0x89>
      if(bp->data[sector] > 0)
80103573:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103576:	03 45 08             	add    0x8(%ebp),%eax
80103579:	83 c0 10             	add    $0x10,%eax
8010357c:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103580:	84 c0                	test   %al,%al
80103582:	74 1c                	je     801035a0 <updateBlkRef+0x89>
	bp->data[sector]--;
80103584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103587:	03 45 08             	add    0x8(%ebp),%eax
8010358a:	83 c0 10             	add    $0x10,%eax
8010358d:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103591:	8d 50 ff             	lea    -0x1(%eax),%edx
80103594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103597:	03 45 08             	add    0x8(%ebp),%eax
8010359a:	83 c0 10             	add    $0x10,%eax
8010359d:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
801035a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035a3:	89 04 24             	mov    %eax,(%esp)
801035a6:	e8 32 cc ff ff       	call   801001dd <bwrite>
    brelse(bp);
801035ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035ae:	89 04 24             	mov    %eax,(%esp)
801035b1:	e8 61 cc ff ff       	call   80100217 <brelse>
801035b6:	e9 99 00 00 00       	jmp    80103654 <updateBlkRef+0x13d>
  }
  else if(sector < BSIZE*2)
801035bb:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801035c2:	0f 87 8c 00 00 00    	ja     80103654 <updateBlkRef+0x13d>
  {
    bp = bread(1,getRefCount(2));
801035c8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801035cf:	e8 fd fe ff ff       	call   801034d1 <getRefCount>
801035d4:	89 44 24 04          	mov    %eax,0x4(%esp)
801035d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035df:	e8 c2 cb ff ff       	call   801001a6 <bread>
801035e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
801035e7:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
801035eb:	75 1c                	jne    80103609 <updateBlkRef+0xf2>
      bp->data[sector-BSIZE]++;
801035ed:	8b 45 08             	mov    0x8(%ebp),%eax
801035f0:	2d 00 02 00 00       	sub    $0x200,%eax
801035f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035f8:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801035fd:	8d 4a 01             	lea    0x1(%edx),%ecx
80103600:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103603:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
80103607:	eb 35                	jmp    8010363e <updateBlkRef+0x127>
    else if(flag == -1)
80103609:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
8010360d:	75 2f                	jne    8010363e <updateBlkRef+0x127>
      if(bp->data[sector-BSIZE] > 0)
8010360f:	8b 45 08             	mov    0x8(%ebp),%eax
80103612:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
80103618:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010361b:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
80103620:	84 c0                	test   %al,%al
80103622:	74 1a                	je     8010363e <updateBlkRef+0x127>
	bp->data[sector-BSIZE]--;
80103624:	8b 45 08             	mov    0x8(%ebp),%eax
80103627:	2d 00 02 00 00       	sub    $0x200,%eax
8010362c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010362f:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80103634:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103637:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010363a:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
8010363e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103641:	89 04 24             	mov    %eax,(%esp)
80103644:	e8 94 cb ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010364c:	89 04 24             	mov    %eax,(%esp)
8010364f:	e8 c3 cb ff ff       	call   80100217 <brelse>
  }  
}
80103654:	c9                   	leave  
80103655:	c3                   	ret    

80103656 <getBlkRef>:

int
getBlkRef(uint sector)
{
80103656:	55                   	push   %ebp
80103657:	89 e5                	mov    %esp,%ebp
80103659:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1,offset = 0;
8010365c:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
80103663:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  
  if(sector < BSIZE)
8010366a:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103671:	77 21                	ja     80103694 <getBlkRef+0x3e>
    bp = bread(1,getRefCount(1));
80103673:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010367a:	e8 52 fe ff ff       	call   801034d1 <getRefCount>
8010367f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103683:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010368a:	e8 17 cb ff ff       	call   801001a6 <bread>
8010368f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103692:	eb 2f                	jmp    801036c3 <getBlkRef+0x6d>
  else if(sector < BSIZE*2)
80103694:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
8010369b:	77 26                	ja     801036c3 <getBlkRef+0x6d>
  {
    bp = bread(1,getRefCount(2));
8010369d:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801036a4:	e8 28 fe ff ff       	call   801034d1 <getRefCount>
801036a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801036ad:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801036b4:	e8 ed ca ff ff       	call   801001a6 <bread>
801036b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    offset = BSIZE;
801036bc:	c7 45 f0 00 02 00 00 	movl   $0x200,-0x10(%ebp)
  }
  ret = (uchar)bp->data[sector-offset];
801036c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036c6:	8b 55 08             	mov    0x8(%ebp),%edx
801036c9:	29 c2                	sub    %eax,%edx
801036cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036ce:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
801036d3:	0f b6 c0             	movzbl %al,%eax
801036d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  brelse(bp);
801036d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036dc:	89 04 24             	mov    %eax,(%esp)
801036df:	e8 33 cb ff ff       	call   80100217 <brelse>
  return ret;
801036e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801036e7:	c9                   	leave  
801036e8:	c3                   	ret    

801036e9 <zeroNextInum>:

void
zeroNextInum(void)
{
801036e9:	55                   	push   %ebp
801036ea:	89 e5                	mov    %esp,%ebp
  nextInum = 0;
801036ec:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
801036f3:	00 00 00 
}
801036f6:	5d                   	pop    %ebp
801036f7:	c3                   	ret    

801036f8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801036f8:	55                   	push   %ebp
801036f9:	89 e5                	mov    %esp,%ebp
801036fb:	53                   	push   %ebx
801036fc:	83 ec 14             	sub    $0x14,%esp
801036ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103702:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103706:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010370a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010370e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103712:	ec                   	in     (%dx),%al
80103713:	89 c3                	mov    %eax,%ebx
80103715:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103718:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010371c:	83 c4 14             	add    $0x14,%esp
8010371f:	5b                   	pop    %ebx
80103720:	5d                   	pop    %ebp
80103721:	c3                   	ret    

80103722 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80103722:	55                   	push   %ebp
80103723:	89 e5                	mov    %esp,%ebp
80103725:	57                   	push   %edi
80103726:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80103727:	8b 55 08             	mov    0x8(%ebp),%edx
8010372a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010372d:	8b 45 10             	mov    0x10(%ebp),%eax
80103730:	89 cb                	mov    %ecx,%ebx
80103732:	89 df                	mov    %ebx,%edi
80103734:	89 c1                	mov    %eax,%ecx
80103736:	fc                   	cld    
80103737:	f3 6d                	rep insl (%dx),%es:(%edi)
80103739:	89 c8                	mov    %ecx,%eax
8010373b:	89 fb                	mov    %edi,%ebx
8010373d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103740:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80103743:	5b                   	pop    %ebx
80103744:	5f                   	pop    %edi
80103745:	5d                   	pop    %ebp
80103746:	c3                   	ret    

80103747 <outb>:

static inline void
outb(ushort port, uchar data)
{
80103747:	55                   	push   %ebp
80103748:	89 e5                	mov    %esp,%ebp
8010374a:	83 ec 08             	sub    $0x8,%esp
8010374d:	8b 55 08             	mov    0x8(%ebp),%edx
80103750:	8b 45 0c             	mov    0xc(%ebp),%eax
80103753:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103757:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010375a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010375e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103762:	ee                   	out    %al,(%dx)
}
80103763:	c9                   	leave  
80103764:	c3                   	ret    

80103765 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80103765:	55                   	push   %ebp
80103766:	89 e5                	mov    %esp,%ebp
80103768:	56                   	push   %esi
80103769:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010376a:	8b 55 08             	mov    0x8(%ebp),%edx
8010376d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103770:	8b 45 10             	mov    0x10(%ebp),%eax
80103773:	89 cb                	mov    %ecx,%ebx
80103775:	89 de                	mov    %ebx,%esi
80103777:	89 c1                	mov    %eax,%ecx
80103779:	fc                   	cld    
8010377a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010377c:	89 c8                	mov    %ecx,%eax
8010377e:	89 f3                	mov    %esi,%ebx
80103780:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103783:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103786:	5b                   	pop    %ebx
80103787:	5e                   	pop    %esi
80103788:	5d                   	pop    %ebp
80103789:	c3                   	ret    

8010378a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010378a:	55                   	push   %ebp
8010378b:	89 e5                	mov    %esp,%ebp
8010378d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80103790:	90                   	nop
80103791:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103798:	e8 5b ff ff ff       	call   801036f8 <inb>
8010379d:	0f b6 c0             	movzbl %al,%eax
801037a0:	89 45 fc             	mov    %eax,-0x4(%ebp)
801037a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037a6:	25 c0 00 00 00       	and    $0xc0,%eax
801037ab:	83 f8 40             	cmp    $0x40,%eax
801037ae:	75 e1                	jne    80103791 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801037b0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801037b4:	74 11                	je     801037c7 <idewait+0x3d>
801037b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801037b9:	83 e0 21             	and    $0x21,%eax
801037bc:	85 c0                	test   %eax,%eax
801037be:	74 07                	je     801037c7 <idewait+0x3d>
    return -1;
801037c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801037c5:	eb 05                	jmp    801037cc <idewait+0x42>
  return 0;
801037c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801037cc:	c9                   	leave  
801037cd:	c3                   	ret    

801037ce <ideinit>:

void
ideinit(void)
{
801037ce:	55                   	push   %ebp
801037cf:	89 e5                	mov    %esp,%ebp
801037d1:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801037d4:	c7 44 24 04 33 98 10 	movl   $0x80109833,0x4(%esp)
801037db:	80 
801037dc:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801037e3:	e8 42 26 00 00       	call   80105e2a <initlock>
  picenable(IRQ_IDE);
801037e8:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801037ef:	e8 75 15 00 00       	call   80104d69 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801037f4:	a1 60 0f 11 80       	mov    0x80110f60,%eax
801037f9:	83 e8 01             	sub    $0x1,%eax
801037fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103800:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103807:	e8 12 04 00 00       	call   80103c1e <ioapicenable>
  idewait(0);
8010380c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103813:	e8 72 ff ff ff       	call   8010378a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103818:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010381f:	00 
80103820:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103827:	e8 1b ff ff ff       	call   80103747 <outb>
  for(i=0; i<1000; i++){
8010382c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103833:	eb 20                	jmp    80103855 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103835:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010383c:	e8 b7 fe ff ff       	call   801036f8 <inb>
80103841:	84 c0                	test   %al,%al
80103843:	74 0c                	je     80103851 <ideinit+0x83>
      havedisk1 = 1;
80103845:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
8010384c:	00 00 00 
      break;
8010384f:	eb 0d                	jmp    8010385e <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80103851:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103855:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
8010385c:	7e d7                	jle    80103835 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010385e:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103865:	00 
80103866:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010386d:	e8 d5 fe ff ff       	call   80103747 <outb>
}
80103872:	c9                   	leave  
80103873:	c3                   	ret    

80103874 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103874:	55                   	push   %ebp
80103875:	89 e5                	mov    %esp,%ebp
80103877:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010387a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010387e:	75 0c                	jne    8010388c <idestart+0x18>
    panic("idestart");
80103880:	c7 04 24 37 98 10 80 	movl   $0x80109837,(%esp)
80103887:	e8 b1 cc ff ff       	call   8010053d <panic>

  idewait(0);
8010388c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103893:	e8 f2 fe ff ff       	call   8010378a <idewait>
  outb(0x3f6, 0);  // generate interrupt
80103898:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010389f:	00 
801038a0:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801038a7:	e8 9b fe ff ff       	call   80103747 <outb>
  outb(0x1f2, 1);  // number of sectors
801038ac:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801038b3:	00 
801038b4:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801038bb:	e8 87 fe ff ff       	call   80103747 <outb>
  outb(0x1f3, b->sector & 0xff);
801038c0:	8b 45 08             	mov    0x8(%ebp),%eax
801038c3:	8b 40 08             	mov    0x8(%eax),%eax
801038c6:	0f b6 c0             	movzbl %al,%eax
801038c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801038cd:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801038d4:	e8 6e fe ff ff       	call   80103747 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801038d9:	8b 45 08             	mov    0x8(%ebp),%eax
801038dc:	8b 40 08             	mov    0x8(%eax),%eax
801038df:	c1 e8 08             	shr    $0x8,%eax
801038e2:	0f b6 c0             	movzbl %al,%eax
801038e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801038e9:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801038f0:	e8 52 fe ff ff       	call   80103747 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801038f5:	8b 45 08             	mov    0x8(%ebp),%eax
801038f8:	8b 40 08             	mov    0x8(%eax),%eax
801038fb:	c1 e8 10             	shr    $0x10,%eax
801038fe:	0f b6 c0             	movzbl %al,%eax
80103901:	89 44 24 04          	mov    %eax,0x4(%esp)
80103905:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010390c:	e8 36 fe ff ff       	call   80103747 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80103911:	8b 45 08             	mov    0x8(%ebp),%eax
80103914:	8b 40 04             	mov    0x4(%eax),%eax
80103917:	83 e0 01             	and    $0x1,%eax
8010391a:	89 c2                	mov    %eax,%edx
8010391c:	c1 e2 04             	shl    $0x4,%edx
8010391f:	8b 45 08             	mov    0x8(%ebp),%eax
80103922:	8b 40 08             	mov    0x8(%eax),%eax
80103925:	c1 e8 18             	shr    $0x18,%eax
80103928:	83 e0 0f             	and    $0xf,%eax
8010392b:	09 d0                	or     %edx,%eax
8010392d:	83 c8 e0             	or     $0xffffffe0,%eax
80103930:	0f b6 c0             	movzbl %al,%eax
80103933:	89 44 24 04          	mov    %eax,0x4(%esp)
80103937:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010393e:	e8 04 fe ff ff       	call   80103747 <outb>
  if(b->flags & B_DIRTY){
80103943:	8b 45 08             	mov    0x8(%ebp),%eax
80103946:	8b 00                	mov    (%eax),%eax
80103948:	83 e0 04             	and    $0x4,%eax
8010394b:	85 c0                	test   %eax,%eax
8010394d:	74 34                	je     80103983 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010394f:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80103956:	00 
80103957:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010395e:	e8 e4 fd ff ff       	call   80103747 <outb>
    outsl(0x1f0, b->data, 512/4);
80103963:	8b 45 08             	mov    0x8(%ebp),%eax
80103966:	83 c0 18             	add    $0x18,%eax
80103969:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103970:	00 
80103971:	89 44 24 04          	mov    %eax,0x4(%esp)
80103975:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010397c:	e8 e4 fd ff ff       	call   80103765 <outsl>
80103981:	eb 14                	jmp    80103997 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80103983:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010398a:	00 
8010398b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103992:	e8 b0 fd ff ff       	call   80103747 <outb>
  }
}
80103997:	c9                   	leave  
80103998:	c3                   	ret    

80103999 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80103999:	55                   	push   %ebp
8010399a:	89 e5                	mov    %esp,%ebp
8010399c:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010399f:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801039a6:	e8 a0 24 00 00       	call   80105e4b <acquire>
  if((b = idequeue) == 0){
801039ab:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801039b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801039b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801039b7:	75 11                	jne    801039ca <ideintr+0x31>
    release(&idelock);
801039b9:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801039c0:	e8 e8 24 00 00       	call   80105ead <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801039c5:	e9 90 00 00 00       	jmp    80103a5a <ideintr+0xc1>
  }
  idequeue = b->qnext;
801039ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039cd:	8b 40 14             	mov    0x14(%eax),%eax
801039d0:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801039d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039d8:	8b 00                	mov    (%eax),%eax
801039da:	83 e0 04             	and    $0x4,%eax
801039dd:	85 c0                	test   %eax,%eax
801039df:	75 2e                	jne    80103a0f <ideintr+0x76>
801039e1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801039e8:	e8 9d fd ff ff       	call   8010378a <idewait>
801039ed:	85 c0                	test   %eax,%eax
801039ef:	78 1e                	js     80103a0f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801039f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f4:	83 c0 18             	add    $0x18,%eax
801039f7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801039fe:	00 
801039ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a03:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103a0a:	e8 13 fd ff ff       	call   80103722 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80103a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a12:	8b 00                	mov    (%eax),%eax
80103a14:	89 c2                	mov    %eax,%edx
80103a16:	83 ca 02             	or     $0x2,%edx
80103a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a1c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80103a1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a21:	8b 00                	mov    (%eax),%eax
80103a23:	89 c2                	mov    %eax,%edx
80103a25:	83 e2 fb             	and    $0xfffffffb,%edx
80103a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a2b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a30:	89 04 24             	mov    %eax,(%esp)
80103a33:	e8 0e 22 00 00       	call   80105c46 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103a38:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103a3d:	85 c0                	test   %eax,%eax
80103a3f:	74 0d                	je     80103a4e <ideintr+0xb5>
    idestart(idequeue);
80103a41:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103a46:	89 04 24             	mov    %eax,(%esp)
80103a49:	e8 26 fe ff ff       	call   80103874 <idestart>

  release(&idelock);
80103a4e:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a55:	e8 53 24 00 00       	call   80105ead <release>
}
80103a5a:	c9                   	leave  
80103a5b:	c3                   	ret    

80103a5c <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80103a5c:	55                   	push   %ebp
80103a5d:	89 e5                	mov    %esp,%ebp
80103a5f:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80103a62:	8b 45 08             	mov    0x8(%ebp),%eax
80103a65:	8b 00                	mov    (%eax),%eax
80103a67:	83 e0 01             	and    $0x1,%eax
80103a6a:	85 c0                	test   %eax,%eax
80103a6c:	75 0c                	jne    80103a7a <iderw+0x1e>
    panic("iderw: buf not busy");
80103a6e:	c7 04 24 40 98 10 80 	movl   $0x80109840,(%esp)
80103a75:	e8 c3 ca ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80103a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80103a7d:	8b 00                	mov    (%eax),%eax
80103a7f:	83 e0 06             	and    $0x6,%eax
80103a82:	83 f8 02             	cmp    $0x2,%eax
80103a85:	75 0c                	jne    80103a93 <iderw+0x37>
    panic("iderw: nothing to do");
80103a87:	c7 04 24 54 98 10 80 	movl   $0x80109854,(%esp)
80103a8e:	e8 aa ca ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80103a93:	8b 45 08             	mov    0x8(%ebp),%eax
80103a96:	8b 40 04             	mov    0x4(%eax),%eax
80103a99:	85 c0                	test   %eax,%eax
80103a9b:	74 15                	je     80103ab2 <iderw+0x56>
80103a9d:	a1 58 c6 10 80       	mov    0x8010c658,%eax
80103aa2:	85 c0                	test   %eax,%eax
80103aa4:	75 0c                	jne    80103ab2 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80103aa6:	c7 04 24 69 98 10 80 	movl   $0x80109869,(%esp)
80103aad:	e8 8b ca ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80103ab2:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103ab9:	e8 8d 23 00 00       	call   80105e4b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80103abe:	8b 45 08             	mov    0x8(%ebp),%eax
80103ac1:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80103ac8:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80103acf:	eb 0b                	jmp    80103adc <iderw+0x80>
80103ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ad4:	8b 00                	mov    (%eax),%eax
80103ad6:	83 c0 14             	add    $0x14,%eax
80103ad9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103adf:	8b 00                	mov    (%eax),%eax
80103ae1:	85 c0                	test   %eax,%eax
80103ae3:	75 ec                	jne    80103ad1 <iderw+0x75>
    ;
  *pp = b;
80103ae5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ae8:	8b 55 08             	mov    0x8(%ebp),%edx
80103aeb:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80103aed:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103af2:	3b 45 08             	cmp    0x8(%ebp),%eax
80103af5:	75 22                	jne    80103b19 <iderw+0xbd>
    idestart(b);
80103af7:	8b 45 08             	mov    0x8(%ebp),%eax
80103afa:	89 04 24             	mov    %eax,(%esp)
80103afd:	e8 72 fd ff ff       	call   80103874 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103b02:	eb 15                	jmp    80103b19 <iderw+0xbd>
    sleep(b, &idelock);
80103b04:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103b0b:	80 
80103b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103b0f:	89 04 24             	mov    %eax,(%esp)
80103b12:	e8 56 20 00 00       	call   80105b6d <sleep>
80103b17:	eb 01                	jmp    80103b1a <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103b19:	90                   	nop
80103b1a:	8b 45 08             	mov    0x8(%ebp),%eax
80103b1d:	8b 00                	mov    (%eax),%eax
80103b1f:	83 e0 06             	and    $0x6,%eax
80103b22:	83 f8 02             	cmp    $0x2,%eax
80103b25:	75 dd                	jne    80103b04 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103b27:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103b2e:	e8 7a 23 00 00       	call   80105ead <release>
}
80103b33:	c9                   	leave  
80103b34:	c3                   	ret    
80103b35:	00 00                	add    %al,(%eax)
	...

80103b38 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103b38:	55                   	push   %ebp
80103b39:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103b3b:	a1 94 08 11 80       	mov    0x80110894,%eax
80103b40:	8b 55 08             	mov    0x8(%ebp),%edx
80103b43:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103b45:	a1 94 08 11 80       	mov    0x80110894,%eax
80103b4a:	8b 40 10             	mov    0x10(%eax),%eax
}
80103b4d:	5d                   	pop    %ebp
80103b4e:	c3                   	ret    

80103b4f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103b4f:	55                   	push   %ebp
80103b50:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103b52:	a1 94 08 11 80       	mov    0x80110894,%eax
80103b57:	8b 55 08             	mov    0x8(%ebp),%edx
80103b5a:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103b5c:	a1 94 08 11 80       	mov    0x80110894,%eax
80103b61:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b64:	89 50 10             	mov    %edx,0x10(%eax)
}
80103b67:	5d                   	pop    %ebp
80103b68:	c3                   	ret    

80103b69 <ioapicinit>:

void
ioapicinit(void)
{
80103b69:	55                   	push   %ebp
80103b6a:	89 e5                	mov    %esp,%ebp
80103b6c:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103b6f:	a1 64 09 11 80       	mov    0x80110964,%eax
80103b74:	85 c0                	test   %eax,%eax
80103b76:	0f 84 9f 00 00 00    	je     80103c1b <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103b7c:	c7 05 94 08 11 80 00 	movl   $0xfec00000,0x80110894
80103b83:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103b86:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103b8d:	e8 a6 ff ff ff       	call   80103b38 <ioapicread>
80103b92:	c1 e8 10             	shr    $0x10,%eax
80103b95:	25 ff 00 00 00       	and    $0xff,%eax
80103b9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103b9d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103ba4:	e8 8f ff ff ff       	call   80103b38 <ioapicread>
80103ba9:	c1 e8 18             	shr    $0x18,%eax
80103bac:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103baf:	0f b6 05 60 09 11 80 	movzbl 0x80110960,%eax
80103bb6:	0f b6 c0             	movzbl %al,%eax
80103bb9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103bbc:	74 0c                	je     80103bca <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103bbe:	c7 04 24 88 98 10 80 	movl   $0x80109888,(%esp)
80103bc5:	e8 d7 c7 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103bca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103bd1:	eb 3e                	jmp    80103c11 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103bd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd6:	83 c0 20             	add    $0x20,%eax
80103bd9:	0d 00 00 01 00       	or     $0x10000,%eax
80103bde:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103be1:	83 c2 08             	add    $0x8,%edx
80103be4:	01 d2                	add    %edx,%edx
80103be6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bea:	89 14 24             	mov    %edx,(%esp)
80103bed:	e8 5d ff ff ff       	call   80103b4f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103bf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bf5:	83 c0 08             	add    $0x8,%eax
80103bf8:	01 c0                	add    %eax,%eax
80103bfa:	83 c0 01             	add    $0x1,%eax
80103bfd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103c04:	00 
80103c05:	89 04 24             	mov    %eax,(%esp)
80103c08:	e8 42 ff ff ff       	call   80103b4f <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103c0d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c14:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103c17:	7e ba                	jle    80103bd3 <ioapicinit+0x6a>
80103c19:	eb 01                	jmp    80103c1c <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103c1b:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103c1c:	c9                   	leave  
80103c1d:	c3                   	ret    

80103c1e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103c1e:	55                   	push   %ebp
80103c1f:	89 e5                	mov    %esp,%ebp
80103c21:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103c24:	a1 64 09 11 80       	mov    0x80110964,%eax
80103c29:	85 c0                	test   %eax,%eax
80103c2b:	74 39                	je     80103c66 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103c2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103c30:	83 c0 20             	add    $0x20,%eax
80103c33:	8b 55 08             	mov    0x8(%ebp),%edx
80103c36:	83 c2 08             	add    $0x8,%edx
80103c39:	01 d2                	add    %edx,%edx
80103c3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c3f:	89 14 24             	mov    %edx,(%esp)
80103c42:	e8 08 ff ff ff       	call   80103b4f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103c47:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c4a:	c1 e0 18             	shl    $0x18,%eax
80103c4d:	8b 55 08             	mov    0x8(%ebp),%edx
80103c50:	83 c2 08             	add    $0x8,%edx
80103c53:	01 d2                	add    %edx,%edx
80103c55:	83 c2 01             	add    $0x1,%edx
80103c58:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c5c:	89 14 24             	mov    %edx,(%esp)
80103c5f:	e8 eb fe ff ff       	call   80103b4f <ioapicwrite>
80103c64:	eb 01                	jmp    80103c67 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103c66:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103c67:	c9                   	leave  
80103c68:	c3                   	ret    
80103c69:	00 00                	add    %al,(%eax)
	...

80103c6c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103c6c:	55                   	push   %ebp
80103c6d:	89 e5                	mov    %esp,%ebp
80103c6f:	8b 45 08             	mov    0x8(%ebp),%eax
80103c72:	05 00 00 00 80       	add    $0x80000000,%eax
80103c77:	5d                   	pop    %ebp
80103c78:	c3                   	ret    

80103c79 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103c79:	55                   	push   %ebp
80103c7a:	89 e5                	mov    %esp,%ebp
80103c7c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103c7f:	c7 44 24 04 ba 98 10 	movl   $0x801098ba,0x4(%esp)
80103c86:	80 
80103c87:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103c8e:	e8 97 21 00 00       	call   80105e2a <initlock>
  kmem.use_lock = 0;
80103c93:	c7 05 d4 08 11 80 00 	movl   $0x0,0x801108d4
80103c9a:	00 00 00 
  freerange(vstart, vend);
80103c9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ca0:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ca4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ca7:	89 04 24             	mov    %eax,(%esp)
80103caa:	e8 26 00 00 00       	call   80103cd5 <freerange>
}
80103caf:	c9                   	leave  
80103cb0:	c3                   	ret    

80103cb1 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103cb1:	55                   	push   %ebp
80103cb2:	89 e5                	mov    %esp,%ebp
80103cb4:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103cb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cba:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cbe:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc1:	89 04 24             	mov    %eax,(%esp)
80103cc4:	e8 0c 00 00 00       	call   80103cd5 <freerange>
  kmem.use_lock = 1;
80103cc9:	c7 05 d4 08 11 80 01 	movl   $0x1,0x801108d4
80103cd0:	00 00 00 
}
80103cd3:	c9                   	leave  
80103cd4:	c3                   	ret    

80103cd5 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103cd5:	55                   	push   %ebp
80103cd6:	89 e5                	mov    %esp,%ebp
80103cd8:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103cdb:	8b 45 08             	mov    0x8(%ebp),%eax
80103cde:	05 ff 0f 00 00       	add    $0xfff,%eax
80103ce3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103ce8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103ceb:	eb 12                	jmp    80103cff <freerange+0x2a>
    kfree(p);
80103ced:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf0:	89 04 24             	mov    %eax,(%esp)
80103cf3:	e8 16 00 00 00       	call   80103d0e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103cf8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103cff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d02:	05 00 10 00 00       	add    $0x1000,%eax
80103d07:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103d0a:	76 e1                	jbe    80103ced <freerange+0x18>
    kfree(p);
}
80103d0c:	c9                   	leave  
80103d0d:	c3                   	ret    

80103d0e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103d0e:	55                   	push   %ebp
80103d0f:	89 e5                	mov    %esp,%ebp
80103d11:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103d14:	8b 45 08             	mov    0x8(%ebp),%eax
80103d17:	25 ff 0f 00 00       	and    $0xfff,%eax
80103d1c:	85 c0                	test   %eax,%eax
80103d1e:	75 1b                	jne    80103d3b <kfree+0x2d>
80103d20:	81 7d 08 5c 37 11 80 	cmpl   $0x8011375c,0x8(%ebp)
80103d27:	72 12                	jb     80103d3b <kfree+0x2d>
80103d29:	8b 45 08             	mov    0x8(%ebp),%eax
80103d2c:	89 04 24             	mov    %eax,(%esp)
80103d2f:	e8 38 ff ff ff       	call   80103c6c <v2p>
80103d34:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103d39:	76 0c                	jbe    80103d47 <kfree+0x39>
    panic("kfree");
80103d3b:	c7 04 24 bf 98 10 80 	movl   $0x801098bf,(%esp)
80103d42:	e8 f6 c7 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103d47:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103d4e:	00 
80103d4f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103d56:	00 
80103d57:	8b 45 08             	mov    0x8(%ebp),%eax
80103d5a:	89 04 24             	mov    %eax,(%esp)
80103d5d:	e8 38 23 00 00       	call   8010609a <memset>

  if(kmem.use_lock)
80103d62:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103d67:	85 c0                	test   %eax,%eax
80103d69:	74 0c                	je     80103d77 <kfree+0x69>
    acquire(&kmem.lock);
80103d6b:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103d72:	e8 d4 20 00 00       	call   80105e4b <acquire>
  r = (struct run*)v;
80103d77:	8b 45 08             	mov    0x8(%ebp),%eax
80103d7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103d7d:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80103d83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d86:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103d88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d8b:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  if(kmem.use_lock)
80103d90:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103d95:	85 c0                	test   %eax,%eax
80103d97:	74 0c                	je     80103da5 <kfree+0x97>
    release(&kmem.lock);
80103d99:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103da0:	e8 08 21 00 00       	call   80105ead <release>
}
80103da5:	c9                   	leave  
80103da6:	c3                   	ret    

80103da7 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103da7:	55                   	push   %ebp
80103da8:	89 e5                	mov    %esp,%ebp
80103daa:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103dad:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103db2:	85 c0                	test   %eax,%eax
80103db4:	74 0c                	je     80103dc2 <kalloc+0x1b>
    acquire(&kmem.lock);
80103db6:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103dbd:	e8 89 20 00 00       	call   80105e4b <acquire>
  r = kmem.freelist;
80103dc2:	a1 d8 08 11 80       	mov    0x801108d8,%eax
80103dc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103dca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103dce:	74 0a                	je     80103dda <kalloc+0x33>
    kmem.freelist = r->next;
80103dd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dd3:	8b 00                	mov    (%eax),%eax
80103dd5:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  if(kmem.use_lock)
80103dda:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103ddf:	85 c0                	test   %eax,%eax
80103de1:	74 0c                	je     80103def <kalloc+0x48>
    release(&kmem.lock);
80103de3:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103dea:	e8 be 20 00 00       	call   80105ead <release>
  return (char*)r;
80103def:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103df2:	c9                   	leave  
80103df3:	c3                   	ret    

80103df4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103df4:	55                   	push   %ebp
80103df5:	89 e5                	mov    %esp,%ebp
80103df7:	53                   	push   %ebx
80103df8:	83 ec 14             	sub    $0x14,%esp
80103dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dfe:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103e02:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103e06:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103e0a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103e0e:	ec                   	in     (%dx),%al
80103e0f:	89 c3                	mov    %eax,%ebx
80103e11:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103e14:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103e18:	83 c4 14             	add    $0x14,%esp
80103e1b:	5b                   	pop    %ebx
80103e1c:	5d                   	pop    %ebp
80103e1d:	c3                   	ret    

80103e1e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103e1e:	55                   	push   %ebp
80103e1f:	89 e5                	mov    %esp,%ebp
80103e21:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103e24:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103e2b:	e8 c4 ff ff ff       	call   80103df4 <inb>
80103e30:	0f b6 c0             	movzbl %al,%eax
80103e33:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e39:	83 e0 01             	and    $0x1,%eax
80103e3c:	85 c0                	test   %eax,%eax
80103e3e:	75 0a                	jne    80103e4a <kbdgetc+0x2c>
    return -1;
80103e40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103e45:	e9 23 01 00 00       	jmp    80103f6d <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103e4a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103e51:	e8 9e ff ff ff       	call   80103df4 <inb>
80103e56:	0f b6 c0             	movzbl %al,%eax
80103e59:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103e5c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103e63:	75 17                	jne    80103e7c <kbdgetc+0x5e>
    shift |= E0ESC;
80103e65:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e6a:	83 c8 40             	or     $0x40,%eax
80103e6d:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103e72:	b8 00 00 00 00       	mov    $0x0,%eax
80103e77:	e9 f1 00 00 00       	jmp    80103f6d <kbdgetc+0x14f>
  } else if(data & 0x80){
80103e7c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e7f:	25 80 00 00 00       	and    $0x80,%eax
80103e84:	85 c0                	test   %eax,%eax
80103e86:	74 45                	je     80103ecd <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103e88:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e8d:	83 e0 40             	and    $0x40,%eax
80103e90:	85 c0                	test   %eax,%eax
80103e92:	75 08                	jne    80103e9c <kbdgetc+0x7e>
80103e94:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e97:	83 e0 7f             	and    $0x7f,%eax
80103e9a:	eb 03                	jmp    80103e9f <kbdgetc+0x81>
80103e9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e9f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103ea2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ea5:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103eaa:	0f b6 00             	movzbl (%eax),%eax
80103ead:	83 c8 40             	or     $0x40,%eax
80103eb0:	0f b6 c0             	movzbl %al,%eax
80103eb3:	f7 d0                	not    %eax
80103eb5:	89 c2                	mov    %eax,%edx
80103eb7:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ebc:	21 d0                	and    %edx,%eax
80103ebe:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103ec3:	b8 00 00 00 00       	mov    $0x0,%eax
80103ec8:	e9 a0 00 00 00       	jmp    80103f6d <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103ecd:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ed2:	83 e0 40             	and    $0x40,%eax
80103ed5:	85 c0                	test   %eax,%eax
80103ed7:	74 14                	je     80103eed <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103ed9:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103ee0:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ee5:	83 e0 bf             	and    $0xffffffbf,%eax
80103ee8:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103eed:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ef0:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103ef5:	0f b6 00             	movzbl (%eax),%eax
80103ef8:	0f b6 d0             	movzbl %al,%edx
80103efb:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f00:	09 d0                	or     %edx,%eax
80103f02:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103f07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103f0a:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103f0f:	0f b6 00             	movzbl (%eax),%eax
80103f12:	0f b6 d0             	movzbl %al,%edx
80103f15:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f1a:	31 d0                	xor    %edx,%eax
80103f1c:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103f21:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f26:	83 e0 03             	and    $0x3,%eax
80103f29:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103f30:	03 45 fc             	add    -0x4(%ebp),%eax
80103f33:	0f b6 00             	movzbl (%eax),%eax
80103f36:	0f b6 c0             	movzbl %al,%eax
80103f39:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103f3c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103f41:	83 e0 08             	and    $0x8,%eax
80103f44:	85 c0                	test   %eax,%eax
80103f46:	74 22                	je     80103f6a <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103f48:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103f4c:	76 0c                	jbe    80103f5a <kbdgetc+0x13c>
80103f4e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103f52:	77 06                	ja     80103f5a <kbdgetc+0x13c>
      c += 'A' - 'a';
80103f54:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103f58:	eb 10                	jmp    80103f6a <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103f5a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103f5e:	76 0a                	jbe    80103f6a <kbdgetc+0x14c>
80103f60:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103f64:	77 04                	ja     80103f6a <kbdgetc+0x14c>
      c += 'a' - 'A';
80103f66:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103f6a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103f6d:	c9                   	leave  
80103f6e:	c3                   	ret    

80103f6f <kbdintr>:

void
kbdintr(void)
{
80103f6f:	55                   	push   %ebp
80103f70:	89 e5                	mov    %esp,%ebp
80103f72:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103f75:	c7 04 24 1e 3e 10 80 	movl   $0x80103e1e,(%esp)
80103f7c:	e8 2c c8 ff ff       	call   801007ad <consoleintr>
}
80103f81:	c9                   	leave  
80103f82:	c3                   	ret    
	...

80103f84 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f84:	55                   	push   %ebp
80103f85:	89 e5                	mov    %esp,%ebp
80103f87:	83 ec 08             	sub    $0x8,%esp
80103f8a:	8b 55 08             	mov    0x8(%ebp),%edx
80103f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f90:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f94:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f97:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f9b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f9f:	ee                   	out    %al,(%dx)
}
80103fa0:	c9                   	leave  
80103fa1:	c3                   	ret    

80103fa2 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103fa2:	55                   	push   %ebp
80103fa3:	89 e5                	mov    %esp,%ebp
80103fa5:	53                   	push   %ebx
80103fa6:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103fa9:	9c                   	pushf  
80103faa:	5b                   	pop    %ebx
80103fab:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103fae:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103fb1:	83 c4 10             	add    $0x10,%esp
80103fb4:	5b                   	pop    %ebx
80103fb5:	5d                   	pop    %ebp
80103fb6:	c3                   	ret    

80103fb7 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103fb7:	55                   	push   %ebp
80103fb8:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103fba:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103fbf:	8b 55 08             	mov    0x8(%ebp),%edx
80103fc2:	c1 e2 02             	shl    $0x2,%edx
80103fc5:	01 c2                	add    %eax,%edx
80103fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fca:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103fcc:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103fd1:	83 c0 20             	add    $0x20,%eax
80103fd4:	8b 00                	mov    (%eax),%eax
}
80103fd6:	5d                   	pop    %ebp
80103fd7:	c3                   	ret    

80103fd8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103fd8:	55                   	push   %ebp
80103fd9:	89 e5                	mov    %esp,%ebp
80103fdb:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103fde:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80103fe3:	85 c0                	test   %eax,%eax
80103fe5:	0f 84 47 01 00 00    	je     80104132 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103feb:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103ff2:	00 
80103ff3:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103ffa:	e8 b8 ff ff ff       	call   80103fb7 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103fff:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80104006:	00 
80104007:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
8010400e:	e8 a4 ff ff ff       	call   80103fb7 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80104013:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
8010401a:	00 
8010401b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80104022:	e8 90 ff ff ff       	call   80103fb7 <lapicw>
  lapicw(TICR, 10000000); 
80104027:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
8010402e:	00 
8010402f:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80104036:	e8 7c ff ff ff       	call   80103fb7 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010403b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104042:	00 
80104043:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010404a:	e8 68 ff ff ff       	call   80103fb7 <lapicw>
  lapicw(LINT1, MASKED);
8010404f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104056:	00 
80104057:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010405e:	e8 54 ff ff ff       	call   80103fb7 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80104063:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104068:	83 c0 30             	add    $0x30,%eax
8010406b:	8b 00                	mov    (%eax),%eax
8010406d:	c1 e8 10             	shr    $0x10,%eax
80104070:	25 ff 00 00 00       	and    $0xff,%eax
80104075:	83 f8 03             	cmp    $0x3,%eax
80104078:	76 14                	jbe    8010408e <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010407a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104081:	00 
80104082:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80104089:	e8 29 ff ff ff       	call   80103fb7 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010408e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80104095:	00 
80104096:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010409d:	e8 15 ff ff ff       	call   80103fb7 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
801040a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040a9:	00 
801040aa:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040b1:	e8 01 ff ff ff       	call   80103fb7 <lapicw>
  lapicw(ESR, 0);
801040b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040bd:	00 
801040be:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040c5:	e8 ed fe ff ff       	call   80103fb7 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
801040ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040d1:	00 
801040d2:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801040d9:	e8 d9 fe ff ff       	call   80103fb7 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801040de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801040e5:	00 
801040e6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801040ed:	e8 c5 fe ff ff       	call   80103fb7 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801040f2:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801040f9:	00 
801040fa:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104101:	e8 b1 fe ff ff       	call   80103fb7 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80104106:	90                   	nop
80104107:	a1 dc 08 11 80       	mov    0x801108dc,%eax
8010410c:	05 00 03 00 00       	add    $0x300,%eax
80104111:	8b 00                	mov    (%eax),%eax
80104113:	25 00 10 00 00       	and    $0x1000,%eax
80104118:	85 c0                	test   %eax,%eax
8010411a:	75 eb                	jne    80104107 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
8010411c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104123:	00 
80104124:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010412b:	e8 87 fe ff ff       	call   80103fb7 <lapicw>
80104130:	eb 01                	jmp    80104133 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80104132:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80104133:	c9                   	leave  
80104134:	c3                   	ret    

80104135 <cpunum>:

int
cpunum(void)
{
80104135:	55                   	push   %ebp
80104136:	89 e5                	mov    %esp,%ebp
80104138:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010413b:	e8 62 fe ff ff       	call   80103fa2 <readeflags>
80104140:	25 00 02 00 00       	and    $0x200,%eax
80104145:	85 c0                	test   %eax,%eax
80104147:	74 29                	je     80104172 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80104149:	a1 60 c6 10 80       	mov    0x8010c660,%eax
8010414e:	85 c0                	test   %eax,%eax
80104150:	0f 94 c2             	sete   %dl
80104153:	83 c0 01             	add    $0x1,%eax
80104156:	a3 60 c6 10 80       	mov    %eax,0x8010c660
8010415b:	84 d2                	test   %dl,%dl
8010415d:	74 13                	je     80104172 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
8010415f:	8b 45 04             	mov    0x4(%ebp),%eax
80104162:	89 44 24 04          	mov    %eax,0x4(%esp)
80104166:	c7 04 24 c8 98 10 80 	movl   $0x801098c8,(%esp)
8010416d:	e8 2f c2 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80104172:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104177:	85 c0                	test   %eax,%eax
80104179:	74 0f                	je     8010418a <cpunum+0x55>
    return lapic[ID]>>24;
8010417b:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104180:	83 c0 20             	add    $0x20,%eax
80104183:	8b 00                	mov    (%eax),%eax
80104185:	c1 e8 18             	shr    $0x18,%eax
80104188:	eb 05                	jmp    8010418f <cpunum+0x5a>
  return 0;
8010418a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010418f:	c9                   	leave  
80104190:	c3                   	ret    

80104191 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80104191:	55                   	push   %ebp
80104192:	89 e5                	mov    %esp,%ebp
80104194:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80104197:	a1 dc 08 11 80       	mov    0x801108dc,%eax
8010419c:	85 c0                	test   %eax,%eax
8010419e:	74 14                	je     801041b4 <lapiceoi+0x23>
    lapicw(EOI, 0);
801041a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041a7:	00 
801041a8:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801041af:	e8 03 fe ff ff       	call   80103fb7 <lapicw>
}
801041b4:	c9                   	leave  
801041b5:	c3                   	ret    

801041b6 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801041b6:	55                   	push   %ebp
801041b7:	89 e5                	mov    %esp,%ebp
}
801041b9:	5d                   	pop    %ebp
801041ba:	c3                   	ret    

801041bb <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801041bb:	55                   	push   %ebp
801041bc:	89 e5                	mov    %esp,%ebp
801041be:	83 ec 1c             	sub    $0x1c,%esp
801041c1:	8b 45 08             	mov    0x8(%ebp),%eax
801041c4:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
801041c7:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801041ce:	00 
801041cf:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801041d6:	e8 a9 fd ff ff       	call   80103f84 <outb>
  outb(IO_RTC+1, 0x0A);
801041db:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801041e2:	00 
801041e3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801041ea:	e8 95 fd ff ff       	call   80103f84 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801041ef:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801041f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
801041f9:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801041fe:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104201:	8d 50 02             	lea    0x2(%eax),%edx
80104204:	8b 45 0c             	mov    0xc(%ebp),%eax
80104207:	c1 e8 04             	shr    $0x4,%eax
8010420a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010420d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80104211:	c1 e0 18             	shl    $0x18,%eax
80104214:	89 44 24 04          	mov    %eax,0x4(%esp)
80104218:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010421f:	e8 93 fd ff ff       	call   80103fb7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80104224:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010422b:	00 
8010422c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104233:	e8 7f fd ff ff       	call   80103fb7 <lapicw>
  microdelay(200);
80104238:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010423f:	e8 72 ff ff ff       	call   801041b6 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80104244:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010424b:	00 
8010424c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104253:	e8 5f fd ff ff       	call   80103fb7 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80104258:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010425f:	e8 52 ff ff ff       	call   801041b6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104264:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010426b:	eb 40                	jmp    801042ad <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010426d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80104271:	c1 e0 18             	shl    $0x18,%eax
80104274:	89 44 24 04          	mov    %eax,0x4(%esp)
80104278:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010427f:	e8 33 fd ff ff       	call   80103fb7 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80104284:	8b 45 0c             	mov    0xc(%ebp),%eax
80104287:	c1 e8 0c             	shr    $0xc,%eax
8010428a:	80 cc 06             	or     $0x6,%ah
8010428d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104291:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80104298:	e8 1a fd ff ff       	call   80103fb7 <lapicw>
    microdelay(200);
8010429d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801042a4:	e8 0d ff ff ff       	call   801041b6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801042a9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801042ad:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801042b1:	7e ba                	jle    8010426d <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801042b3:	c9                   	leave  
801042b4:	c3                   	ret    
801042b5:	00 00                	add    %al,(%eax)
	...

801042b8 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{ 
801042b8:	55                   	push   %ebp
801042b9:	89 e5                	mov    %esp,%ebp
801042bb:	83 ec 38             	sub    $0x38,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801042be:	c7 44 24 04 f4 98 10 	movl   $0x801098f4,0x4(%esp)
801042c5:	80 
801042c6:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801042cd:	e8 58 1b 00 00       	call   80105e2a <initlock>
  readsb(ROOTDEV, &sb);
801042d2:	8d 45 e0             	lea    -0x20(%ebp),%eax
801042d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801042d9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801042e0:	e8 37 de ff ff       	call   8010211c <readsb>
  log.start = sb.size - sb.nlog;
801042e5:	8b 55 e0             	mov    -0x20(%ebp),%edx
801042e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042eb:	89 d1                	mov    %edx,%ecx
801042ed:	29 c1                	sub    %eax,%ecx
801042ef:	89 c8                	mov    %ecx,%eax
801042f1:	a3 14 09 11 80       	mov    %eax,0x80110914
  log.size = sb.nlog;
801042f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042f9:	a3 18 09 11 80       	mov    %eax,0x80110918
  log.dev = ROOTDEV;
801042fe:	c7 05 20 09 11 80 01 	movl   $0x1,0x80110920
80104305:	00 00 00 
  recover_from_log();
80104308:	e8 97 01 00 00       	call   801044a4 <recover_from_log>
  
  
}
8010430d:	c9                   	leave  
8010430e:	c3                   	ret    

8010430f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010430f:	55                   	push   %ebp
80104310:	89 e5                	mov    %esp,%ebp
80104312:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104315:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010431c:	e9 89 00 00 00       	jmp    801043aa <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80104321:	a1 14 09 11 80       	mov    0x80110914,%eax
80104326:	03 45 f4             	add    -0xc(%ebp),%eax
80104329:	83 c0 01             	add    $0x1,%eax
8010432c:	89 c2                	mov    %eax,%edx
8010432e:	a1 20 09 11 80       	mov    0x80110920,%eax
80104333:	89 54 24 04          	mov    %edx,0x4(%esp)
80104337:	89 04 24             	mov    %eax,(%esp)
8010433a:	e8 67 be ff ff       	call   801001a6 <bread>
8010433f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80104342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104345:	83 c0 10             	add    $0x10,%eax
80104348:	8b 04 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%eax
8010434f:	89 c2                	mov    %eax,%edx
80104351:	a1 20 09 11 80       	mov    0x80110920,%eax
80104356:	89 54 24 04          	mov    %edx,0x4(%esp)
8010435a:	89 04 24             	mov    %eax,(%esp)
8010435d:	e8 44 be ff ff       	call   801001a6 <bread>
80104362:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80104365:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104368:	8d 50 18             	lea    0x18(%eax),%edx
8010436b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010436e:	83 c0 18             	add    $0x18,%eax
80104371:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104378:	00 
80104379:	89 54 24 04          	mov    %edx,0x4(%esp)
8010437d:	89 04 24             	mov    %eax,(%esp)
80104380:	e8 e8 1d 00 00       	call   8010616d <memmove>
    bwrite(dbuf);  // write dst to disk
80104385:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104388:	89 04 24             	mov    %eax,(%esp)
8010438b:	e8 4d be ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80104390:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104393:	89 04 24             	mov    %eax,(%esp)
80104396:	e8 7c be ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010439b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010439e:	89 04 24             	mov    %eax,(%esp)
801043a1:	e8 71 be ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801043a6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043aa:	a1 24 09 11 80       	mov    0x80110924,%eax
801043af:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801043b2:	0f 8f 69 ff ff ff    	jg     80104321 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801043b8:	c9                   	leave  
801043b9:	c3                   	ret    

801043ba <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801043ba:	55                   	push   %ebp
801043bb:	89 e5                	mov    %esp,%ebp
801043bd:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801043c0:	a1 14 09 11 80       	mov    0x80110914,%eax
801043c5:	89 c2                	mov    %eax,%edx
801043c7:	a1 20 09 11 80       	mov    0x80110920,%eax
801043cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801043d0:	89 04 24             	mov    %eax,(%esp)
801043d3:	e8 ce bd ff ff       	call   801001a6 <bread>
801043d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801043db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043de:	83 c0 18             	add    $0x18,%eax
801043e1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801043e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043e7:	8b 00                	mov    (%eax),%eax
801043e9:	a3 24 09 11 80       	mov    %eax,0x80110924
  for (i = 0; i < log.lh.n; i++) {
801043ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043f5:	eb 1b                	jmp    80104412 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801043f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043fd:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80104401:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104404:	83 c2 10             	add    $0x10,%edx
80104407:	89 04 95 e8 08 11 80 	mov    %eax,-0x7feef718(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010440e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104412:	a1 24 09 11 80       	mov    0x80110924,%eax
80104417:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010441a:	7f db                	jg     801043f7 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010441c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010441f:	89 04 24             	mov    %eax,(%esp)
80104422:	e8 f0 bd ff ff       	call   80100217 <brelse>
}
80104427:	c9                   	leave  
80104428:	c3                   	ret    

80104429 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80104429:	55                   	push   %ebp
8010442a:	89 e5                	mov    %esp,%ebp
8010442c:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010442f:	a1 14 09 11 80       	mov    0x80110914,%eax
80104434:	89 c2                	mov    %eax,%edx
80104436:	a1 20 09 11 80       	mov    0x80110920,%eax
8010443b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010443f:	89 04 24             	mov    %eax,(%esp)
80104442:	e8 5f bd ff ff       	call   801001a6 <bread>
80104447:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010444a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010444d:	83 c0 18             	add    $0x18,%eax
80104450:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80104453:	8b 15 24 09 11 80    	mov    0x80110924,%edx
80104459:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010445c:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010445e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104465:	eb 1b                	jmp    80104482 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80104467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010446a:	83 c0 10             	add    $0x10,%eax
8010446d:	8b 0c 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%ecx
80104474:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104477:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010447a:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010447e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104482:	a1 24 09 11 80       	mov    0x80110924,%eax
80104487:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010448a:	7f db                	jg     80104467 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
8010448c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010448f:	89 04 24             	mov    %eax,(%esp)
80104492:	e8 46 bd ff ff       	call   801001dd <bwrite>
  brelse(buf);
80104497:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010449a:	89 04 24             	mov    %eax,(%esp)
8010449d:	e8 75 bd ff ff       	call   80100217 <brelse>
}
801044a2:	c9                   	leave  
801044a3:	c3                   	ret    

801044a4 <recover_from_log>:

static void
recover_from_log(void)
{
801044a4:	55                   	push   %ebp
801044a5:	89 e5                	mov    %esp,%ebp
801044a7:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801044aa:	e8 0b ff ff ff       	call   801043ba <read_head>
  install_trans(); // if committed, copy from log to disk
801044af:	e8 5b fe ff ff       	call   8010430f <install_trans>
  log.lh.n = 0;
801044b4:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801044bb:	00 00 00 
  write_head(); // clear the log
801044be:	e8 66 ff ff ff       	call   80104429 <write_head>
}
801044c3:	c9                   	leave  
801044c4:	c3                   	ret    

801044c5 <begin_trans>:

void
begin_trans(void)
{
801044c5:	55                   	push   %ebp
801044c6:	89 e5                	mov    %esp,%ebp
801044c8:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801044cb:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801044d2:	e8 74 19 00 00       	call   80105e4b <acquire>
  while (log.busy) {
801044d7:	eb 14                	jmp    801044ed <begin_trans+0x28>
    sleep(&log, &log.lock);
801044d9:	c7 44 24 04 e0 08 11 	movl   $0x801108e0,0x4(%esp)
801044e0:	80 
801044e1:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
801044e8:	e8 80 16 00 00       	call   80105b6d <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801044ed:	a1 1c 09 11 80       	mov    0x8011091c,%eax
801044f2:	85 c0                	test   %eax,%eax
801044f4:	75 e3                	jne    801044d9 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801044f6:	c7 05 1c 09 11 80 01 	movl   $0x1,0x8011091c
801044fd:	00 00 00 
  release(&log.lock);
80104500:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
80104507:	e8 a1 19 00 00       	call   80105ead <release>
}
8010450c:	c9                   	leave  
8010450d:	c3                   	ret    

8010450e <commit_trans>:

void
commit_trans(void)
{
8010450e:	55                   	push   %ebp
8010450f:	89 e5                	mov    %esp,%ebp
80104511:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80104514:	a1 24 09 11 80       	mov    0x80110924,%eax
80104519:	85 c0                	test   %eax,%eax
8010451b:	7e 19                	jle    80104536 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
8010451d:	e8 07 ff ff ff       	call   80104429 <write_head>
    install_trans(); // Now install writes to home locations
80104522:	e8 e8 fd ff ff       	call   8010430f <install_trans>
    log.lh.n = 0; 
80104527:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
8010452e:	00 00 00 
    write_head();    // Erase the transaction from the log
80104531:	e8 f3 fe ff ff       	call   80104429 <write_head>
  }
  
  acquire(&log.lock);
80104536:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
8010453d:	e8 09 19 00 00       	call   80105e4b <acquire>
  log.busy = 0;
80104542:	c7 05 1c 09 11 80 00 	movl   $0x0,0x8011091c
80104549:	00 00 00 
  wakeup(&log);
8010454c:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
80104553:	e8 ee 16 00 00       	call   80105c46 <wakeup>
  release(&log.lock);
80104558:	c7 04 24 e0 08 11 80 	movl   $0x801108e0,(%esp)
8010455f:	e8 49 19 00 00       	call   80105ead <release>
}
80104564:	c9                   	leave  
80104565:	c3                   	ret    

80104566 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80104566:	55                   	push   %ebp
80104567:	89 e5                	mov    %esp,%ebp
80104569:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010456c:	a1 24 09 11 80       	mov    0x80110924,%eax
80104571:	83 f8 09             	cmp    $0x9,%eax
80104574:	7f 12                	jg     80104588 <log_write+0x22>
80104576:	a1 24 09 11 80       	mov    0x80110924,%eax
8010457b:	8b 15 18 09 11 80    	mov    0x80110918,%edx
80104581:	83 ea 01             	sub    $0x1,%edx
80104584:	39 d0                	cmp    %edx,%eax
80104586:	7c 0c                	jl     80104594 <log_write+0x2e>
    panic("too big a transaction");
80104588:	c7 04 24 f8 98 10 80 	movl   $0x801098f8,(%esp)
8010458f:	e8 a9 bf ff ff       	call   8010053d <panic>
  if (!log.busy)
80104594:	a1 1c 09 11 80       	mov    0x8011091c,%eax
80104599:	85 c0                	test   %eax,%eax
8010459b:	75 0c                	jne    801045a9 <log_write+0x43>
    panic("write outside of trans");
8010459d:	c7 04 24 0e 99 10 80 	movl   $0x8010990e,(%esp)
801045a4:	e8 94 bf ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801045a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801045b0:	eb 1d                	jmp    801045cf <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
801045b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b5:	83 c0 10             	add    $0x10,%eax
801045b8:	8b 04 85 e8 08 11 80 	mov    -0x7feef718(,%eax,4),%eax
801045bf:	89 c2                	mov    %eax,%edx
801045c1:	8b 45 08             	mov    0x8(%ebp),%eax
801045c4:	8b 40 08             	mov    0x8(%eax),%eax
801045c7:	39 c2                	cmp    %eax,%edx
801045c9:	74 10                	je     801045db <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801045cb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801045cf:	a1 24 09 11 80       	mov    0x80110924,%eax
801045d4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801045d7:	7f d9                	jg     801045b2 <log_write+0x4c>
801045d9:	eb 01                	jmp    801045dc <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801045db:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801045dc:	8b 45 08             	mov    0x8(%ebp),%eax
801045df:	8b 40 08             	mov    0x8(%eax),%eax
801045e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045e5:	83 c2 10             	add    $0x10,%edx
801045e8:	89 04 95 e8 08 11 80 	mov    %eax,-0x7feef718(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801045ef:	a1 14 09 11 80       	mov    0x80110914,%eax
801045f4:	03 45 f4             	add    -0xc(%ebp),%eax
801045f7:	83 c0 01             	add    $0x1,%eax
801045fa:	89 c2                	mov    %eax,%edx
801045fc:	8b 45 08             	mov    0x8(%ebp),%eax
801045ff:	8b 40 04             	mov    0x4(%eax),%eax
80104602:	89 54 24 04          	mov    %edx,0x4(%esp)
80104606:	89 04 24             	mov    %eax,(%esp)
80104609:	e8 98 bb ff ff       	call   801001a6 <bread>
8010460e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80104611:	8b 45 08             	mov    0x8(%ebp),%eax
80104614:	8d 50 18             	lea    0x18(%eax),%edx
80104617:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010461a:	83 c0 18             	add    $0x18,%eax
8010461d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104624:	00 
80104625:	89 54 24 04          	mov    %edx,0x4(%esp)
80104629:	89 04 24             	mov    %eax,(%esp)
8010462c:	e8 3c 1b 00 00       	call   8010616d <memmove>
  bwrite(lbuf);
80104631:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104634:	89 04 24             	mov    %eax,(%esp)
80104637:	e8 a1 bb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
8010463c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010463f:	89 04 24             	mov    %eax,(%esp)
80104642:	e8 d0 bb ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80104647:	a1 24 09 11 80       	mov    0x80110924,%eax
8010464c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010464f:	75 0d                	jne    8010465e <log_write+0xf8>
    log.lh.n++;
80104651:	a1 24 09 11 80       	mov    0x80110924,%eax
80104656:	83 c0 01             	add    $0x1,%eax
80104659:	a3 24 09 11 80       	mov    %eax,0x80110924
  b->flags |= B_DIRTY; // XXX prevent eviction
8010465e:	8b 45 08             	mov    0x8(%ebp),%eax
80104661:	8b 00                	mov    (%eax),%eax
80104663:	89 c2                	mov    %eax,%edx
80104665:	83 ca 04             	or     $0x4,%edx
80104668:	8b 45 08             	mov    0x8(%ebp),%eax
8010466b:	89 10                	mov    %edx,(%eax)
}
8010466d:	c9                   	leave  
8010466e:	c3                   	ret    
	...

80104670 <v2p>:
80104670:	55                   	push   %ebp
80104671:	89 e5                	mov    %esp,%ebp
80104673:	8b 45 08             	mov    0x8(%ebp),%eax
80104676:	05 00 00 00 80       	add    $0x80000000,%eax
8010467b:	5d                   	pop    %ebp
8010467c:	c3                   	ret    

8010467d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010467d:	55                   	push   %ebp
8010467e:	89 e5                	mov    %esp,%ebp
80104680:	8b 45 08             	mov    0x8(%ebp),%eax
80104683:	05 00 00 00 80       	add    $0x80000000,%eax
80104688:	5d                   	pop    %ebp
80104689:	c3                   	ret    

8010468a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010468a:	55                   	push   %ebp
8010468b:	89 e5                	mov    %esp,%ebp
8010468d:	53                   	push   %ebx
8010468e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104691:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104694:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104697:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010469a:	89 c3                	mov    %eax,%ebx
8010469c:	89 d8                	mov    %ebx,%eax
8010469e:	f0 87 02             	lock xchg %eax,(%edx)
801046a1:	89 c3                	mov    %eax,%ebx
801046a3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801046a6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801046a9:	83 c4 10             	add    $0x10,%esp
801046ac:	5b                   	pop    %ebx
801046ad:	5d                   	pop    %ebp
801046ae:	c3                   	ret    

801046af <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801046af:	55                   	push   %ebp
801046b0:	89 e5                	mov    %esp,%ebp
801046b2:	83 e4 f0             	and    $0xfffffff0,%esp
801046b5:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801046b8:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801046bf:	80 
801046c0:	c7 04 24 5c 37 11 80 	movl   $0x8011375c,(%esp)
801046c7:	e8 ad f5 ff ff       	call   80103c79 <kinit1>
  kvmalloc();      // kernel page table
801046cc:	e8 9d 47 00 00       	call   80108e6e <kvmalloc>
  mpinit();        // collect info about this machine
801046d1:	e8 63 04 00 00       	call   80104b39 <mpinit>
  lapicinit(mpbcpu());
801046d6:	e8 2e 02 00 00       	call   80104909 <mpbcpu>
801046db:	89 04 24             	mov    %eax,(%esp)
801046de:	e8 f5 f8 ff ff       	call   80103fd8 <lapicinit>
  seginit();       // set up segments
801046e3:	e8 29 41 00 00       	call   80108811 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801046e8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801046ee:	0f b6 00             	movzbl (%eax),%eax
801046f1:	0f b6 c0             	movzbl %al,%eax
801046f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801046f8:	c7 04 24 25 99 10 80 	movl   $0x80109925,(%esp)
801046ff:	e8 9d bc ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104704:	e8 95 06 00 00       	call   80104d9e <picinit>
  ioapicinit();    // another interrupt controller
80104709:	e8 5b f4 ff ff       	call   80103b69 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010470e:	e8 7a c3 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80104713:	e8 44 34 00 00       	call   80107b5c <uartinit>
  pinit();         // process table
80104718:	e8 96 0b 00 00       	call   801052b3 <pinit>
  tvinit();        // trap vectors
8010471d:	e8 dd 2f 00 00       	call   801076ff <tvinit>
  binit();         // buffer cache
80104722:	e8 0d b9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80104727:	e8 d4 c7 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
8010472c:	e8 b2 dc ff ff       	call   801023e3 <iinit>
  ideinit();       // disk
80104731:	e8 98 f0 ff ff       	call   801037ce <ideinit>
  if(!ismp)
80104736:	a1 64 09 11 80       	mov    0x80110964,%eax
8010473b:	85 c0                	test   %eax,%eax
8010473d:	75 05                	jne    80104744 <main+0x95>
    timerinit();   // uniprocessor timer
8010473f:	e8 fe 2e 00 00       	call   80107642 <timerinit>
  startothers();   // start other processors
80104744:	e8 87 00 00 00       	call   801047d0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104749:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80104750:	8e 
80104751:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104758:	e8 54 f5 ff ff       	call   80103cb1 <kinit2>
  userinit();      // first user process
8010475d:	e8 6c 0c 00 00       	call   801053ce <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80104762:	e8 22 00 00 00       	call   80104789 <mpmain>

80104767 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80104767:	55                   	push   %ebp
80104768:	89 e5                	mov    %esp,%ebp
8010476a:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
8010476d:	e8 13 47 00 00       	call   80108e85 <switchkvm>
  seginit();
80104772:	e8 9a 40 00 00       	call   80108811 <seginit>
  lapicinit(cpunum());
80104777:	e8 b9 f9 ff ff       	call   80104135 <cpunum>
8010477c:	89 04 24             	mov    %eax,(%esp)
8010477f:	e8 54 f8 ff ff       	call   80103fd8 <lapicinit>
  mpmain();
80104784:	e8 00 00 00 00       	call   80104789 <mpmain>

80104789 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104789:	55                   	push   %ebp
8010478a:	89 e5                	mov    %esp,%ebp
8010478c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010478f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104795:	0f b6 00             	movzbl (%eax),%eax
80104798:	0f b6 c0             	movzbl %al,%eax
8010479b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010479f:	c7 04 24 3c 99 10 80 	movl   $0x8010993c,(%esp)
801047a6:	e8 f6 bb ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801047ab:	e8 c3 30 00 00       	call   80107873 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801047b0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801047b6:	05 a8 00 00 00       	add    $0xa8,%eax
801047bb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801047c2:	00 
801047c3:	89 04 24             	mov    %eax,(%esp)
801047c6:	e8 bf fe ff ff       	call   8010468a <xchg>
  scheduler();     // start running processes
801047cb:	e8 f4 11 00 00       	call   801059c4 <scheduler>

801047d0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801047d0:	55                   	push   %ebp
801047d1:	89 e5                	mov    %esp,%ebp
801047d3:	53                   	push   %ebx
801047d4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801047d7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801047de:	e8 9a fe ff ff       	call   8010467d <p2v>
801047e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801047e6:	b8 8a 00 00 00       	mov    $0x8a,%eax
801047eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801047ef:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
801047f6:	80 
801047f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047fa:	89 04 24             	mov    %eax,(%esp)
801047fd:	e8 6b 19 00 00       	call   8010616d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80104802:	c7 45 f4 80 09 11 80 	movl   $0x80110980,-0xc(%ebp)
80104809:	e9 86 00 00 00       	jmp    80104894 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010480e:	e8 22 f9 ff ff       	call   80104135 <cpunum>
80104813:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104819:	05 80 09 11 80       	add    $0x80110980,%eax
8010481e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104821:	74 69                	je     8010488c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104823:	e8 7f f5 ff ff       	call   80103da7 <kalloc>
80104828:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010482b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010482e:	83 e8 04             	sub    $0x4,%eax
80104831:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104834:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010483a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010483c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010483f:	83 e8 08             	sub    $0x8,%eax
80104842:	c7 00 67 47 10 80    	movl   $0x80104767,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104848:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010484b:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010484e:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104855:	e8 16 fe ff ff       	call   80104670 <v2p>
8010485a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010485c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010485f:	89 04 24             	mov    %eax,(%esp)
80104862:	e8 09 fe ff ff       	call   80104670 <v2p>
80104867:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010486a:	0f b6 12             	movzbl (%edx),%edx
8010486d:	0f b6 d2             	movzbl %dl,%edx
80104870:	89 44 24 04          	mov    %eax,0x4(%esp)
80104874:	89 14 24             	mov    %edx,(%esp)
80104877:	e8 3f f9 ff ff       	call   801041bb <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010487c:	90                   	nop
8010487d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104880:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104886:	85 c0                	test   %eax,%eax
80104888:	74 f3                	je     8010487d <startothers+0xad>
8010488a:	eb 01                	jmp    8010488d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010488c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010488d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104894:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104899:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010489f:	05 80 09 11 80       	add    $0x80110980,%eax
801048a4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801048a7:	0f 87 61 ff ff ff    	ja     8010480e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801048ad:	83 c4 24             	add    $0x24,%esp
801048b0:	5b                   	pop    %ebx
801048b1:	5d                   	pop    %ebp
801048b2:	c3                   	ret    
	...

801048b4 <p2v>:
801048b4:	55                   	push   %ebp
801048b5:	89 e5                	mov    %esp,%ebp
801048b7:	8b 45 08             	mov    0x8(%ebp),%eax
801048ba:	05 00 00 00 80       	add    $0x80000000,%eax
801048bf:	5d                   	pop    %ebp
801048c0:	c3                   	ret    

801048c1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801048c1:	55                   	push   %ebp
801048c2:	89 e5                	mov    %esp,%ebp
801048c4:	53                   	push   %ebx
801048c5:	83 ec 14             	sub    $0x14,%esp
801048c8:	8b 45 08             	mov    0x8(%ebp),%eax
801048cb:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801048cf:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801048d3:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801048d7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801048db:	ec                   	in     (%dx),%al
801048dc:	89 c3                	mov    %eax,%ebx
801048de:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801048e1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801048e5:	83 c4 14             	add    $0x14,%esp
801048e8:	5b                   	pop    %ebx
801048e9:	5d                   	pop    %ebp
801048ea:	c3                   	ret    

801048eb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801048eb:	55                   	push   %ebp
801048ec:	89 e5                	mov    %esp,%ebp
801048ee:	83 ec 08             	sub    $0x8,%esp
801048f1:	8b 55 08             	mov    0x8(%ebp),%edx
801048f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801048f7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801048fb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801048fe:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104902:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104906:	ee                   	out    %al,(%dx)
}
80104907:	c9                   	leave  
80104908:	c3                   	ret    

80104909 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104909:	55                   	push   %ebp
8010490a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010490c:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80104911:	89 c2                	mov    %eax,%edx
80104913:	b8 80 09 11 80       	mov    $0x80110980,%eax
80104918:	89 d1                	mov    %edx,%ecx
8010491a:	29 c1                	sub    %eax,%ecx
8010491c:	89 c8                	mov    %ecx,%eax
8010491e:	c1 f8 02             	sar    $0x2,%eax
80104921:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104927:	5d                   	pop    %ebp
80104928:	c3                   	ret    

80104929 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104929:	55                   	push   %ebp
8010492a:	89 e5                	mov    %esp,%ebp
8010492c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010492f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104936:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010493d:	eb 13                	jmp    80104952 <sum+0x29>
    sum += addr[i];
8010493f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104942:	03 45 08             	add    0x8(%ebp),%eax
80104945:	0f b6 00             	movzbl (%eax),%eax
80104948:	0f b6 c0             	movzbl %al,%eax
8010494b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010494e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104952:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104955:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104958:	7c e5                	jl     8010493f <sum+0x16>
    sum += addr[i];
  return sum;
8010495a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010495d:	c9                   	leave  
8010495e:	c3                   	ret    

8010495f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010495f:	55                   	push   %ebp
80104960:	89 e5                	mov    %esp,%ebp
80104962:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104965:	8b 45 08             	mov    0x8(%ebp),%eax
80104968:	89 04 24             	mov    %eax,(%esp)
8010496b:	e8 44 ff ff ff       	call   801048b4 <p2v>
80104970:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104973:	8b 45 0c             	mov    0xc(%ebp),%eax
80104976:	03 45 f0             	add    -0x10(%ebp),%eax
80104979:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010497c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010497f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104982:	eb 3f                	jmp    801049c3 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104984:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010498b:	00 
8010498c:	c7 44 24 04 50 99 10 	movl   $0x80109950,0x4(%esp)
80104993:	80 
80104994:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104997:	89 04 24             	mov    %eax,(%esp)
8010499a:	e8 72 17 00 00       	call   80106111 <memcmp>
8010499f:	85 c0                	test   %eax,%eax
801049a1:	75 1c                	jne    801049bf <mpsearch1+0x60>
801049a3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801049aa:	00 
801049ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ae:	89 04 24             	mov    %eax,(%esp)
801049b1:	e8 73 ff ff ff       	call   80104929 <sum>
801049b6:	84 c0                	test   %al,%al
801049b8:	75 05                	jne    801049bf <mpsearch1+0x60>
      return (struct mp*)p;
801049ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bd:	eb 11                	jmp    801049d0 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801049bf:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801049c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801049c9:	72 b9                	jb     80104984 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801049cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049d0:	c9                   	leave  
801049d1:	c3                   	ret    

801049d2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801049d2:	55                   	push   %ebp
801049d3:	89 e5                	mov    %esp,%ebp
801049d5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801049d8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801049df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e2:	83 c0 0f             	add    $0xf,%eax
801049e5:	0f b6 00             	movzbl (%eax),%eax
801049e8:	0f b6 c0             	movzbl %al,%eax
801049eb:	89 c2                	mov    %eax,%edx
801049ed:	c1 e2 08             	shl    $0x8,%edx
801049f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049f3:	83 c0 0e             	add    $0xe,%eax
801049f6:	0f b6 00             	movzbl (%eax),%eax
801049f9:	0f b6 c0             	movzbl %al,%eax
801049fc:	09 d0                	or     %edx,%eax
801049fe:	c1 e0 04             	shl    $0x4,%eax
80104a01:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104a04:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a08:	74 21                	je     80104a2b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104a0a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104a11:	00 
80104a12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a15:	89 04 24             	mov    %eax,(%esp)
80104a18:	e8 42 ff ff ff       	call   8010495f <mpsearch1>
80104a1d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104a20:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104a24:	74 50                	je     80104a76 <mpsearch+0xa4>
      return mp;
80104a26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a29:	eb 5f                	jmp    80104a8a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a2e:	83 c0 14             	add    $0x14,%eax
80104a31:	0f b6 00             	movzbl (%eax),%eax
80104a34:	0f b6 c0             	movzbl %al,%eax
80104a37:	89 c2                	mov    %eax,%edx
80104a39:	c1 e2 08             	shl    $0x8,%edx
80104a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a3f:	83 c0 13             	add    $0x13,%eax
80104a42:	0f b6 00             	movzbl (%eax),%eax
80104a45:	0f b6 c0             	movzbl %al,%eax
80104a48:	09 d0                	or     %edx,%eax
80104a4a:	c1 e0 0a             	shl    $0xa,%eax
80104a4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104a50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a53:	2d 00 04 00 00       	sub    $0x400,%eax
80104a58:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104a5f:	00 
80104a60:	89 04 24             	mov    %eax,(%esp)
80104a63:	e8 f7 fe ff ff       	call   8010495f <mpsearch1>
80104a68:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104a6b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104a6f:	74 05                	je     80104a76 <mpsearch+0xa4>
      return mp;
80104a71:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104a74:	eb 14                	jmp    80104a8a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104a76:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80104a7d:	00 
80104a7e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104a85:	e8 d5 fe ff ff       	call   8010495f <mpsearch1>
}
80104a8a:	c9                   	leave  
80104a8b:	c3                   	ret    

80104a8c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80104a8c:	55                   	push   %ebp
80104a8d:	89 e5                	mov    %esp,%ebp
80104a8f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104a92:	e8 3b ff ff ff       	call   801049d2 <mpsearch>
80104a97:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104a9a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104a9e:	74 0a                	je     80104aaa <mpconfig+0x1e>
80104aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa3:	8b 40 04             	mov    0x4(%eax),%eax
80104aa6:	85 c0                	test   %eax,%eax
80104aa8:	75 0a                	jne    80104ab4 <mpconfig+0x28>
    return 0;
80104aaa:	b8 00 00 00 00       	mov    $0x0,%eax
80104aaf:	e9 83 00 00 00       	jmp    80104b37 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab7:	8b 40 04             	mov    0x4(%eax),%eax
80104aba:	89 04 24             	mov    %eax,(%esp)
80104abd:	e8 f2 fd ff ff       	call   801048b4 <p2v>
80104ac2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104ac5:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104acc:	00 
80104acd:	c7 44 24 04 55 99 10 	movl   $0x80109955,0x4(%esp)
80104ad4:	80 
80104ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ad8:	89 04 24             	mov    %eax,(%esp)
80104adb:	e8 31 16 00 00       	call   80106111 <memcmp>
80104ae0:	85 c0                	test   %eax,%eax
80104ae2:	74 07                	je     80104aeb <mpconfig+0x5f>
    return 0;
80104ae4:	b8 00 00 00 00       	mov    $0x0,%eax
80104ae9:	eb 4c                	jmp    80104b37 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80104aeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aee:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104af2:	3c 01                	cmp    $0x1,%al
80104af4:	74 12                	je     80104b08 <mpconfig+0x7c>
80104af6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104af9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104afd:	3c 04                	cmp    $0x4,%al
80104aff:	74 07                	je     80104b08 <mpconfig+0x7c>
    return 0;
80104b01:	b8 00 00 00 00       	mov    $0x0,%eax
80104b06:	eb 2f                	jmp    80104b37 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104b08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b0b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104b0f:	0f b7 c0             	movzwl %ax,%eax
80104b12:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b19:	89 04 24             	mov    %eax,(%esp)
80104b1c:	e8 08 fe ff ff       	call   80104929 <sum>
80104b21:	84 c0                	test   %al,%al
80104b23:	74 07                	je     80104b2c <mpconfig+0xa0>
    return 0;
80104b25:	b8 00 00 00 00       	mov    $0x0,%eax
80104b2a:	eb 0b                	jmp    80104b37 <mpconfig+0xab>
  *pmp = mp;
80104b2c:	8b 45 08             	mov    0x8(%ebp),%eax
80104b2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b32:	89 10                	mov    %edx,(%eax)
  return conf;
80104b34:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104b37:	c9                   	leave  
80104b38:	c3                   	ret    

80104b39 <mpinit>:

void
mpinit(void)
{
80104b39:	55                   	push   %ebp
80104b3a:	89 e5                	mov    %esp,%ebp
80104b3c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104b3f:	c7 05 64 c6 10 80 80 	movl   $0x80110980,0x8010c664
80104b46:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104b49:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104b4c:	89 04 24             	mov    %eax,(%esp)
80104b4f:	e8 38 ff ff ff       	call   80104a8c <mpconfig>
80104b54:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104b57:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104b5b:	0f 84 9c 01 00 00    	je     80104cfd <mpinit+0x1c4>
    return;
  ismp = 1;
80104b61:	c7 05 64 09 11 80 01 	movl   $0x1,0x80110964
80104b68:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104b6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b6e:	8b 40 24             	mov    0x24(%eax),%eax
80104b71:	a3 dc 08 11 80       	mov    %eax,0x801108dc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104b76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b79:	83 c0 2c             	add    $0x2c,%eax
80104b7c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b82:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104b86:	0f b7 c0             	movzwl %ax,%eax
80104b89:	03 45 f0             	add    -0x10(%ebp),%eax
80104b8c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b8f:	e9 f4 00 00 00       	jmp    80104c88 <mpinit+0x14f>
    switch(*p){
80104b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b97:	0f b6 00             	movzbl (%eax),%eax
80104b9a:	0f b6 c0             	movzbl %al,%eax
80104b9d:	83 f8 04             	cmp    $0x4,%eax
80104ba0:	0f 87 bf 00 00 00    	ja     80104c65 <mpinit+0x12c>
80104ba6:	8b 04 85 98 99 10 80 	mov    -0x7fef6668(,%eax,4),%eax
80104bad:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104baf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104bb5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104bb8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104bbc:	0f b6 d0             	movzbl %al,%edx
80104bbf:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104bc4:	39 c2                	cmp    %eax,%edx
80104bc6:	74 2d                	je     80104bf5 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104bc8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104bcb:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104bcf:	0f b6 d0             	movzbl %al,%edx
80104bd2:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104bd7:	89 54 24 08          	mov    %edx,0x8(%esp)
80104bdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bdf:	c7 04 24 5a 99 10 80 	movl   $0x8010995a,(%esp)
80104be6:	e8 b6 b7 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104beb:	c7 05 64 09 11 80 00 	movl   $0x0,0x80110964
80104bf2:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104bf5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104bf8:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104bfc:	0f b6 c0             	movzbl %al,%eax
80104bff:	83 e0 02             	and    $0x2,%eax
80104c02:	85 c0                	test   %eax,%eax
80104c04:	74 15                	je     80104c1b <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104c06:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c0b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104c11:	05 80 09 11 80       	add    $0x80110980,%eax
80104c16:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104c1b:	8b 15 60 0f 11 80    	mov    0x80110f60,%edx
80104c21:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c26:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104c2c:	81 c2 80 09 11 80    	add    $0x80110980,%edx
80104c32:	88 02                	mov    %al,(%edx)
      ncpu++;
80104c34:	a1 60 0f 11 80       	mov    0x80110f60,%eax
80104c39:	83 c0 01             	add    $0x1,%eax
80104c3c:	a3 60 0f 11 80       	mov    %eax,0x80110f60
      p += sizeof(struct mpproc);
80104c41:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104c45:	eb 41                	jmp    80104c88 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104c47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104c4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104c50:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104c54:	a2 60 09 11 80       	mov    %al,0x80110960
      p += sizeof(struct mpioapic);
80104c59:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104c5d:	eb 29                	jmp    80104c88 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104c5f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104c63:	eb 23                	jmp    80104c88 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c68:	0f b6 00             	movzbl (%eax),%eax
80104c6b:	0f b6 c0             	movzbl %al,%eax
80104c6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c72:	c7 04 24 78 99 10 80 	movl   $0x80109978,(%esp)
80104c79:	e8 23 b7 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104c7e:	c7 05 64 09 11 80 00 	movl   $0x0,0x80110964
80104c85:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104c88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c8b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104c8e:	0f 82 00 ff ff ff    	jb     80104b94 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104c94:	a1 64 09 11 80       	mov    0x80110964,%eax
80104c99:	85 c0                	test   %eax,%eax
80104c9b:	75 1d                	jne    80104cba <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104c9d:	c7 05 60 0f 11 80 01 	movl   $0x1,0x80110f60
80104ca4:	00 00 00 
    lapic = 0;
80104ca7:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80104cae:	00 00 00 
    ioapicid = 0;
80104cb1:	c6 05 60 09 11 80 00 	movb   $0x0,0x80110960
    return;
80104cb8:	eb 44                	jmp    80104cfe <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104cba:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104cbd:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104cc1:	84 c0                	test   %al,%al
80104cc3:	74 39                	je     80104cfe <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104cc5:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104ccc:	00 
80104ccd:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104cd4:	e8 12 fc ff ff       	call   801048eb <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104cd9:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104ce0:	e8 dc fb ff ff       	call   801048c1 <inb>
80104ce5:	83 c8 01             	or     $0x1,%eax
80104ce8:	0f b6 c0             	movzbl %al,%eax
80104ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cef:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104cf6:	e8 f0 fb ff ff       	call   801048eb <outb>
80104cfb:	eb 01                	jmp    80104cfe <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104cfd:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104cfe:	c9                   	leave  
80104cff:	c3                   	ret    

80104d00 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104d00:	55                   	push   %ebp
80104d01:	89 e5                	mov    %esp,%ebp
80104d03:	83 ec 08             	sub    $0x8,%esp
80104d06:	8b 55 08             	mov    0x8(%ebp),%edx
80104d09:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d0c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104d10:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104d13:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104d17:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104d1b:	ee                   	out    %al,(%dx)
}
80104d1c:	c9                   	leave  
80104d1d:	c3                   	ret    

80104d1e <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104d1e:	55                   	push   %ebp
80104d1f:	89 e5                	mov    %esp,%ebp
80104d21:	83 ec 0c             	sub    $0xc,%esp
80104d24:	8b 45 08             	mov    0x8(%ebp),%eax
80104d27:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104d2b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104d2f:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104d35:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104d39:	0f b6 c0             	movzbl %al,%eax
80104d3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d40:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d47:	e8 b4 ff ff ff       	call   80104d00 <outb>
  outb(IO_PIC2+1, mask >> 8);
80104d4c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104d50:	66 c1 e8 08          	shr    $0x8,%ax
80104d54:	0f b6 c0             	movzbl %al,%eax
80104d57:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d5b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104d62:	e8 99 ff ff ff       	call   80104d00 <outb>
}
80104d67:	c9                   	leave  
80104d68:	c3                   	ret    

80104d69 <picenable>:

void
picenable(int irq)
{
80104d69:	55                   	push   %ebp
80104d6a:	89 e5                	mov    %esp,%ebp
80104d6c:	53                   	push   %ebx
80104d6d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104d70:	8b 45 08             	mov    0x8(%ebp),%eax
80104d73:	ba 01 00 00 00       	mov    $0x1,%edx
80104d78:	89 d3                	mov    %edx,%ebx
80104d7a:	89 c1                	mov    %eax,%ecx
80104d7c:	d3 e3                	shl    %cl,%ebx
80104d7e:	89 d8                	mov    %ebx,%eax
80104d80:	89 c2                	mov    %eax,%edx
80104d82:	f7 d2                	not    %edx
80104d84:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104d8b:	21 d0                	and    %edx,%eax
80104d8d:	0f b7 c0             	movzwl %ax,%eax
80104d90:	89 04 24             	mov    %eax,(%esp)
80104d93:	e8 86 ff ff ff       	call   80104d1e <picsetmask>
}
80104d98:	83 c4 04             	add    $0x4,%esp
80104d9b:	5b                   	pop    %ebx
80104d9c:	5d                   	pop    %ebp
80104d9d:	c3                   	ret    

80104d9e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104d9e:	55                   	push   %ebp
80104d9f:	89 e5                	mov    %esp,%ebp
80104da1:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104da4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104dab:	00 
80104dac:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104db3:	e8 48 ff ff ff       	call   80104d00 <outb>
  outb(IO_PIC2+1, 0xFF);
80104db8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104dbf:	00 
80104dc0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104dc7:	e8 34 ff ff ff       	call   80104d00 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104dcc:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104dd3:	00 
80104dd4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104ddb:	e8 20 ff ff ff       	call   80104d00 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104de0:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104de7:	00 
80104de8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104def:	e8 0c ff ff ff       	call   80104d00 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104df4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104dfb:	00 
80104dfc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104e03:	e8 f8 fe ff ff       	call   80104d00 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104e08:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104e0f:	00 
80104e10:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104e17:	e8 e4 fe ff ff       	call   80104d00 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104e1c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104e23:	00 
80104e24:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104e2b:	e8 d0 fe ff ff       	call   80104d00 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104e30:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104e37:	00 
80104e38:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e3f:	e8 bc fe ff ff       	call   80104d00 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104e44:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104e4b:	00 
80104e4c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e53:	e8 a8 fe ff ff       	call   80104d00 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104e58:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104e5f:	00 
80104e60:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104e67:	e8 94 fe ff ff       	call   80104d00 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104e6c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104e73:	00 
80104e74:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104e7b:	e8 80 fe ff ff       	call   80104d00 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104e80:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104e87:	00 
80104e88:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104e8f:	e8 6c fe ff ff       	call   80104d00 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104e94:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104e9b:	00 
80104e9c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104ea3:	e8 58 fe ff ff       	call   80104d00 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104ea8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104eaf:	00 
80104eb0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104eb7:	e8 44 fe ff ff       	call   80104d00 <outb>

  if(irqmask != 0xFFFF)
80104ebc:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ec3:	66 83 f8 ff          	cmp    $0xffff,%ax
80104ec7:	74 12                	je     80104edb <picinit+0x13d>
    picsetmask(irqmask);
80104ec9:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ed0:	0f b7 c0             	movzwl %ax,%eax
80104ed3:	89 04 24             	mov    %eax,(%esp)
80104ed6:	e8 43 fe ff ff       	call   80104d1e <picsetmask>
}
80104edb:	c9                   	leave  
80104edc:	c3                   	ret    
80104edd:	00 00                	add    %al,(%eax)
	...

80104ee0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104ee0:	55                   	push   %ebp
80104ee1:	89 e5                	mov    %esp,%ebp
80104ee3:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104ee6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104eed:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ef0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104ef6:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ef9:	8b 10                	mov    (%eax),%edx
80104efb:	8b 45 08             	mov    0x8(%ebp),%eax
80104efe:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104f00:	e8 17 c0 ff ff       	call   80100f1c <filealloc>
80104f05:	8b 55 08             	mov    0x8(%ebp),%edx
80104f08:	89 02                	mov    %eax,(%edx)
80104f0a:	8b 45 08             	mov    0x8(%ebp),%eax
80104f0d:	8b 00                	mov    (%eax),%eax
80104f0f:	85 c0                	test   %eax,%eax
80104f11:	0f 84 c8 00 00 00    	je     80104fdf <pipealloc+0xff>
80104f17:	e8 00 c0 ff ff       	call   80100f1c <filealloc>
80104f1c:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f1f:	89 02                	mov    %eax,(%edx)
80104f21:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f24:	8b 00                	mov    (%eax),%eax
80104f26:	85 c0                	test   %eax,%eax
80104f28:	0f 84 b1 00 00 00    	je     80104fdf <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104f2e:	e8 74 ee ff ff       	call   80103da7 <kalloc>
80104f33:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104f36:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104f3a:	0f 84 9e 00 00 00    	je     80104fde <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104f40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f43:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104f4a:	00 00 00 
  p->writeopen = 1;
80104f4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f50:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104f57:	00 00 00 
  p->nwrite = 0;
80104f5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f5d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104f64:	00 00 00 
  p->nread = 0;
80104f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f6a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104f71:	00 00 00 
  initlock(&p->lock, "pipe");
80104f74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f77:	c7 44 24 04 ac 99 10 	movl   $0x801099ac,0x4(%esp)
80104f7e:	80 
80104f7f:	89 04 24             	mov    %eax,(%esp)
80104f82:	e8 a3 0e 00 00       	call   80105e2a <initlock>
  (*f0)->type = FD_PIPE;
80104f87:	8b 45 08             	mov    0x8(%ebp),%eax
80104f8a:	8b 00                	mov    (%eax),%eax
80104f8c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104f92:	8b 45 08             	mov    0x8(%ebp),%eax
80104f95:	8b 00                	mov    (%eax),%eax
80104f97:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104f9b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f9e:	8b 00                	mov    (%eax),%eax
80104fa0:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80104fa7:	8b 00                	mov    (%eax),%eax
80104fa9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fac:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104faf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb2:	8b 00                	mov    (%eax),%eax
80104fb4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104fba:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fbd:	8b 00                	mov    (%eax),%eax
80104fbf:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104fc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fc6:	8b 00                	mov    (%eax),%eax
80104fc8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104fcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fcf:	8b 00                	mov    (%eax),%eax
80104fd1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104fd4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104fd7:	b8 00 00 00 00       	mov    $0x0,%eax
80104fdc:	eb 43                	jmp    80105021 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104fde:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104fdf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104fe3:	74 0b                	je     80104ff0 <pipealloc+0x110>
    kfree((char*)p);
80104fe5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fe8:	89 04 24             	mov    %eax,(%esp)
80104feb:	e8 1e ed ff ff       	call   80103d0e <kfree>
  if(*f0)
80104ff0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff3:	8b 00                	mov    (%eax),%eax
80104ff5:	85 c0                	test   %eax,%eax
80104ff7:	74 0d                	je     80105006 <pipealloc+0x126>
    fileclose(*f0);
80104ff9:	8b 45 08             	mov    0x8(%ebp),%eax
80104ffc:	8b 00                	mov    (%eax),%eax
80104ffe:	89 04 24             	mov    %eax,(%esp)
80105001:	e8 be bf ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80105006:	8b 45 0c             	mov    0xc(%ebp),%eax
80105009:	8b 00                	mov    (%eax),%eax
8010500b:	85 c0                	test   %eax,%eax
8010500d:	74 0d                	je     8010501c <pipealloc+0x13c>
    fileclose(*f1);
8010500f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105012:	8b 00                	mov    (%eax),%eax
80105014:	89 04 24             	mov    %eax,(%esp)
80105017:	e8 a8 bf ff ff       	call   80100fc4 <fileclose>
  return -1;
8010501c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105021:	c9                   	leave  
80105022:	c3                   	ret    

80105023 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80105023:	55                   	push   %ebp
80105024:	89 e5                	mov    %esp,%ebp
80105026:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80105029:	8b 45 08             	mov    0x8(%ebp),%eax
8010502c:	89 04 24             	mov    %eax,(%esp)
8010502f:	e8 17 0e 00 00       	call   80105e4b <acquire>
  if(writable){
80105034:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105038:	74 1f                	je     80105059 <pipeclose+0x36>
    p->writeopen = 0;
8010503a:	8b 45 08             	mov    0x8(%ebp),%eax
8010503d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80105044:	00 00 00 
    wakeup(&p->nread);
80105047:	8b 45 08             	mov    0x8(%ebp),%eax
8010504a:	05 34 02 00 00       	add    $0x234,%eax
8010504f:	89 04 24             	mov    %eax,(%esp)
80105052:	e8 ef 0b 00 00       	call   80105c46 <wakeup>
80105057:	eb 1d                	jmp    80105076 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80105059:	8b 45 08             	mov    0x8(%ebp),%eax
8010505c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80105063:	00 00 00 
    wakeup(&p->nwrite);
80105066:	8b 45 08             	mov    0x8(%ebp),%eax
80105069:	05 38 02 00 00       	add    $0x238,%eax
8010506e:	89 04 24             	mov    %eax,(%esp)
80105071:	e8 d0 0b 00 00       	call   80105c46 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80105076:	8b 45 08             	mov    0x8(%ebp),%eax
80105079:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010507f:	85 c0                	test   %eax,%eax
80105081:	75 25                	jne    801050a8 <pipeclose+0x85>
80105083:	8b 45 08             	mov    0x8(%ebp),%eax
80105086:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010508c:	85 c0                	test   %eax,%eax
8010508e:	75 18                	jne    801050a8 <pipeclose+0x85>
    release(&p->lock);
80105090:	8b 45 08             	mov    0x8(%ebp),%eax
80105093:	89 04 24             	mov    %eax,(%esp)
80105096:	e8 12 0e 00 00       	call   80105ead <release>
    kfree((char*)p);
8010509b:	8b 45 08             	mov    0x8(%ebp),%eax
8010509e:	89 04 24             	mov    %eax,(%esp)
801050a1:	e8 68 ec ff ff       	call   80103d0e <kfree>
801050a6:	eb 0b                	jmp    801050b3 <pipeclose+0x90>
  } else
    release(&p->lock);
801050a8:	8b 45 08             	mov    0x8(%ebp),%eax
801050ab:	89 04 24             	mov    %eax,(%esp)
801050ae:	e8 fa 0d 00 00       	call   80105ead <release>
}
801050b3:	c9                   	leave  
801050b4:	c3                   	ret    

801050b5 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801050b5:	55                   	push   %ebp
801050b6:	89 e5                	mov    %esp,%ebp
801050b8:	53                   	push   %ebx
801050b9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801050bc:	8b 45 08             	mov    0x8(%ebp),%eax
801050bf:	89 04 24             	mov    %eax,(%esp)
801050c2:	e8 84 0d 00 00       	call   80105e4b <acquire>
  for(i = 0; i < n; i++){
801050c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801050ce:	e9 a6 00 00 00       	jmp    80105179 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801050d3:	8b 45 08             	mov    0x8(%ebp),%eax
801050d6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801050dc:	85 c0                	test   %eax,%eax
801050de:	74 0d                	je     801050ed <pipewrite+0x38>
801050e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801050e6:	8b 40 24             	mov    0x24(%eax),%eax
801050e9:	85 c0                	test   %eax,%eax
801050eb:	74 15                	je     80105102 <pipewrite+0x4d>
        release(&p->lock);
801050ed:	8b 45 08             	mov    0x8(%ebp),%eax
801050f0:	89 04 24             	mov    %eax,(%esp)
801050f3:	e8 b5 0d 00 00       	call   80105ead <release>
        return -1;
801050f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050fd:	e9 9d 00 00 00       	jmp    8010519f <pipewrite+0xea>
      }
      wakeup(&p->nread);
80105102:	8b 45 08             	mov    0x8(%ebp),%eax
80105105:	05 34 02 00 00       	add    $0x234,%eax
8010510a:	89 04 24             	mov    %eax,(%esp)
8010510d:	e8 34 0b 00 00       	call   80105c46 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80105112:	8b 45 08             	mov    0x8(%ebp),%eax
80105115:	8b 55 08             	mov    0x8(%ebp),%edx
80105118:	81 c2 38 02 00 00    	add    $0x238,%edx
8010511e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105122:	89 14 24             	mov    %edx,(%esp)
80105125:	e8 43 0a 00 00       	call   80105b6d <sleep>
8010512a:	eb 01                	jmp    8010512d <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010512c:	90                   	nop
8010512d:	8b 45 08             	mov    0x8(%ebp),%eax
80105130:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80105136:	8b 45 08             	mov    0x8(%ebp),%eax
80105139:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010513f:	05 00 02 00 00       	add    $0x200,%eax
80105144:	39 c2                	cmp    %eax,%edx
80105146:	74 8b                	je     801050d3 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80105148:	8b 45 08             	mov    0x8(%ebp),%eax
8010514b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105151:	89 c3                	mov    %eax,%ebx
80105153:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80105159:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010515c:	03 55 0c             	add    0xc(%ebp),%edx
8010515f:	0f b6 0a             	movzbl (%edx),%ecx
80105162:	8b 55 08             	mov    0x8(%ebp),%edx
80105165:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80105169:	8d 50 01             	lea    0x1(%eax),%edx
8010516c:	8b 45 08             	mov    0x8(%ebp),%eax
8010516f:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80105175:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105179:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010517c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010517f:	7c ab                	jl     8010512c <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80105181:	8b 45 08             	mov    0x8(%ebp),%eax
80105184:	05 34 02 00 00       	add    $0x234,%eax
80105189:	89 04 24             	mov    %eax,(%esp)
8010518c:	e8 b5 0a 00 00       	call   80105c46 <wakeup>
  release(&p->lock);
80105191:	8b 45 08             	mov    0x8(%ebp),%eax
80105194:	89 04 24             	mov    %eax,(%esp)
80105197:	e8 11 0d 00 00       	call   80105ead <release>
  return n;
8010519c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010519f:	83 c4 24             	add    $0x24,%esp
801051a2:	5b                   	pop    %ebx
801051a3:	5d                   	pop    %ebp
801051a4:	c3                   	ret    

801051a5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801051a5:	55                   	push   %ebp
801051a6:	89 e5                	mov    %esp,%ebp
801051a8:	53                   	push   %ebx
801051a9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801051ac:	8b 45 08             	mov    0x8(%ebp),%eax
801051af:	89 04 24             	mov    %eax,(%esp)
801051b2:	e8 94 0c 00 00       	call   80105e4b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801051b7:	eb 3a                	jmp    801051f3 <piperead+0x4e>
    if(proc->killed){
801051b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051bf:	8b 40 24             	mov    0x24(%eax),%eax
801051c2:	85 c0                	test   %eax,%eax
801051c4:	74 15                	je     801051db <piperead+0x36>
      release(&p->lock);
801051c6:	8b 45 08             	mov    0x8(%ebp),%eax
801051c9:	89 04 24             	mov    %eax,(%esp)
801051cc:	e8 dc 0c 00 00       	call   80105ead <release>
      return -1;
801051d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051d6:	e9 b6 00 00 00       	jmp    80105291 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801051db:	8b 45 08             	mov    0x8(%ebp),%eax
801051de:	8b 55 08             	mov    0x8(%ebp),%edx
801051e1:	81 c2 34 02 00 00    	add    $0x234,%edx
801051e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801051eb:	89 14 24             	mov    %edx,(%esp)
801051ee:	e8 7a 09 00 00       	call   80105b6d <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801051f3:	8b 45 08             	mov    0x8(%ebp),%eax
801051f6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801051fc:	8b 45 08             	mov    0x8(%ebp),%eax
801051ff:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105205:	39 c2                	cmp    %eax,%edx
80105207:	75 0d                	jne    80105216 <piperead+0x71>
80105209:	8b 45 08             	mov    0x8(%ebp),%eax
8010520c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80105212:	85 c0                	test   %eax,%eax
80105214:	75 a3                	jne    801051b9 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105216:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010521d:	eb 49                	jmp    80105268 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010521f:	8b 45 08             	mov    0x8(%ebp),%eax
80105222:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80105228:	8b 45 08             	mov    0x8(%ebp),%eax
8010522b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105231:	39 c2                	cmp    %eax,%edx
80105233:	74 3d                	je     80105272 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80105235:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105238:	89 c2                	mov    %eax,%edx
8010523a:	03 55 0c             	add    0xc(%ebp),%edx
8010523d:	8b 45 08             	mov    0x8(%ebp),%eax
80105240:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80105246:	89 c3                	mov    %eax,%ebx
80105248:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010524e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105251:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80105256:	88 0a                	mov    %cl,(%edx)
80105258:	8d 50 01             	lea    0x1(%eax),%edx
8010525b:	8b 45 08             	mov    0x8(%ebp),%eax
8010525e:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105264:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010526b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010526e:	7c af                	jl     8010521f <piperead+0x7a>
80105270:	eb 01                	jmp    80105273 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80105272:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80105273:	8b 45 08             	mov    0x8(%ebp),%eax
80105276:	05 38 02 00 00       	add    $0x238,%eax
8010527b:	89 04 24             	mov    %eax,(%esp)
8010527e:	e8 c3 09 00 00       	call   80105c46 <wakeup>
  release(&p->lock);
80105283:	8b 45 08             	mov    0x8(%ebp),%eax
80105286:	89 04 24             	mov    %eax,(%esp)
80105289:	e8 1f 0c 00 00       	call   80105ead <release>
  return i;
8010528e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105291:	83 c4 24             	add    $0x24,%esp
80105294:	5b                   	pop    %ebx
80105295:	5d                   	pop    %ebp
80105296:	c3                   	ret    
	...

80105298 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105298:	55                   	push   %ebp
80105299:	89 e5                	mov    %esp,%ebp
8010529b:	53                   	push   %ebx
8010529c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010529f:	9c                   	pushf  
801052a0:	5b                   	pop    %ebx
801052a1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801052a4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801052a7:	83 c4 10             	add    $0x10,%esp
801052aa:	5b                   	pop    %ebx
801052ab:	5d                   	pop    %ebp
801052ac:	c3                   	ret    

801052ad <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801052ad:	55                   	push   %ebp
801052ae:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801052b0:	fb                   	sti    
}
801052b1:	5d                   	pop    %ebp
801052b2:	c3                   	ret    

801052b3 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801052b3:	55                   	push   %ebp
801052b4:	89 e5                	mov    %esp,%ebp
801052b6:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801052b9:	c7 44 24 04 b1 99 10 	movl   $0x801099b1,0x4(%esp)
801052c0:	80 
801052c1:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801052c8:	e8 5d 0b 00 00       	call   80105e2a <initlock>
}
801052cd:	c9                   	leave  
801052ce:	c3                   	ret    

801052cf <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801052cf:	55                   	push   %ebp
801052d0:	89 e5                	mov    %esp,%ebp
801052d2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801052d5:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801052dc:	e8 6a 0b 00 00       	call   80105e4b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801052e1:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
801052e8:	eb 0e                	jmp    801052f8 <allocproc+0x29>
    if(p->state == UNUSED)
801052ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ed:	8b 40 0c             	mov    0xc(%eax),%eax
801052f0:	85 c0                	test   %eax,%eax
801052f2:	74 23                	je     80105317 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801052f4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801052f8:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
801052ff:	72 e9                	jb     801052ea <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80105301:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105308:	e8 a0 0b 00 00       	call   80105ead <release>
  return 0;
8010530d:	b8 00 00 00 00       	mov    $0x0,%eax
80105312:	e9 b5 00 00 00       	jmp    801053cc <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80105317:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80105318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010531b:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80105322:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80105327:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010532a:	89 42 10             	mov    %eax,0x10(%edx)
8010532d:	83 c0 01             	add    $0x1,%eax
80105330:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80105335:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
8010533c:	e8 6c 0b 00 00       	call   80105ead <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80105341:	e8 61 ea ff ff       	call   80103da7 <kalloc>
80105346:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105349:	89 42 08             	mov    %eax,0x8(%edx)
8010534c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010534f:	8b 40 08             	mov    0x8(%eax),%eax
80105352:	85 c0                	test   %eax,%eax
80105354:	75 11                	jne    80105367 <allocproc+0x98>
    p->state = UNUSED;
80105356:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105359:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80105360:	b8 00 00 00 00       	mov    $0x0,%eax
80105365:	eb 65                	jmp    801053cc <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80105367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010536a:	8b 40 08             	mov    0x8(%eax),%eax
8010536d:	05 00 10 00 00       	add    $0x1000,%eax
80105372:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80105375:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80105379:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010537c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010537f:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80105382:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80105386:	ba b4 76 10 80       	mov    $0x801076b4,%edx
8010538b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010538e:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80105390:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80105394:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105397:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010539a:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010539d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053a0:	8b 40 1c             	mov    0x1c(%eax),%eax
801053a3:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801053aa:	00 
801053ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801053b2:	00 
801053b3:	89 04 24             	mov    %eax,(%esp)
801053b6:	e8 df 0c 00 00       	call   8010609a <memset>
  p->context->eip = (uint)forkret;
801053bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053be:	8b 40 1c             	mov    0x1c(%eax),%eax
801053c1:	ba 41 5b 10 80       	mov    $0x80105b41,%edx
801053c6:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801053c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801053cc:	c9                   	leave  
801053cd:	c3                   	ret    

801053ce <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801053ce:	55                   	push   %ebp
801053cf:	89 e5                	mov    %esp,%ebp
801053d1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801053d4:	e8 f6 fe ff ff       	call   801052cf <allocproc>
801053d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801053dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053df:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
801053e4:	c7 04 24 a7 3d 10 80 	movl   $0x80103da7,(%esp)
801053eb:	e8 c1 39 00 00       	call   80108db1 <setupkvm>
801053f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053f3:	89 42 04             	mov    %eax,0x4(%edx)
801053f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053f9:	8b 40 04             	mov    0x4(%eax),%eax
801053fc:	85 c0                	test   %eax,%eax
801053fe:	75 0c                	jne    8010540c <userinit+0x3e>
    panic("userinit: out of memory?");
80105400:	c7 04 24 b8 99 10 80 	movl   $0x801099b8,(%esp)
80105407:	e8 31 b1 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010540c:	ba 2c 00 00 00       	mov    $0x2c,%edx
80105411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105414:	8b 40 04             	mov    0x4(%eax),%eax
80105417:	89 54 24 08          	mov    %edx,0x8(%esp)
8010541b:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80105422:	80 
80105423:	89 04 24             	mov    %eax,(%esp)
80105426:	e8 de 3b 00 00       	call   80109009 <inituvm>
  p->sz = PGSIZE;
8010542b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010542e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80105434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105437:	8b 40 18             	mov    0x18(%eax),%eax
8010543a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80105441:	00 
80105442:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105449:	00 
8010544a:	89 04 24             	mov    %eax,(%esp)
8010544d:	e8 48 0c 00 00       	call   8010609a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80105452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105455:	8b 40 18             	mov    0x18(%eax),%eax
80105458:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010545e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105461:	8b 40 18             	mov    0x18(%eax),%eax
80105464:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010546a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546d:	8b 40 18             	mov    0x18(%eax),%eax
80105470:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105473:	8b 52 18             	mov    0x18(%edx),%edx
80105476:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010547a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010547e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105481:	8b 40 18             	mov    0x18(%eax),%eax
80105484:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105487:	8b 52 18             	mov    0x18(%edx),%edx
8010548a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010548e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80105492:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105495:	8b 40 18             	mov    0x18(%eax),%eax
80105498:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010549f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a2:	8b 40 18             	mov    0x18(%eax),%eax
801054a5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801054ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054af:	8b 40 18             	mov    0x18(%eax),%eax
801054b2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801054b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054bc:	83 c0 6c             	add    $0x6c,%eax
801054bf:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801054c6:	00 
801054c7:	c7 44 24 04 d1 99 10 	movl   $0x801099d1,0x4(%esp)
801054ce:	80 
801054cf:	89 04 24             	mov    %eax,(%esp)
801054d2:	e8 f3 0d 00 00       	call   801062ca <safestrcpy>
  p->cwd = namei("/");
801054d7:	c7 04 24 da 99 10 80 	movl   $0x801099da,(%esp)
801054de:	e8 45 de ff ff       	call   80103328 <namei>
801054e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054e6:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;  
801054e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ec:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801054f3:	c9                   	leave  
801054f4:	c3                   	ret    

801054f5 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801054f5:	55                   	push   %ebp
801054f6:	89 e5                	mov    %esp,%ebp
801054f8:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801054fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105501:	8b 00                	mov    (%eax),%eax
80105503:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105506:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010550a:	7e 34                	jle    80105540 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010550c:	8b 45 08             	mov    0x8(%ebp),%eax
8010550f:	89 c2                	mov    %eax,%edx
80105511:	03 55 f4             	add    -0xc(%ebp),%edx
80105514:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010551a:	8b 40 04             	mov    0x4(%eax),%eax
8010551d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105521:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105524:	89 54 24 04          	mov    %edx,0x4(%esp)
80105528:	89 04 24             	mov    %eax,(%esp)
8010552b:	e8 53 3c 00 00       	call   80109183 <allocuvm>
80105530:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105533:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105537:	75 41                	jne    8010557a <growproc+0x85>
      return -1;
80105539:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010553e:	eb 58                	jmp    80105598 <growproc+0xa3>
  } else if(n < 0){
80105540:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105544:	79 34                	jns    8010557a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80105546:	8b 45 08             	mov    0x8(%ebp),%eax
80105549:	89 c2                	mov    %eax,%edx
8010554b:	03 55 f4             	add    -0xc(%ebp),%edx
8010554e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105554:	8b 40 04             	mov    0x4(%eax),%eax
80105557:	89 54 24 08          	mov    %edx,0x8(%esp)
8010555b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010555e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105562:	89 04 24             	mov    %eax,(%esp)
80105565:	e8 f3 3c 00 00       	call   8010925d <deallocuvm>
8010556a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010556d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105571:	75 07                	jne    8010557a <growproc+0x85>
      return -1;
80105573:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105578:	eb 1e                	jmp    80105598 <growproc+0xa3>
  }
  proc->sz = sz;
8010557a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105580:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105583:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105585:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010558b:	89 04 24             	mov    %eax,(%esp)
8010558e:	e8 0f 39 00 00       	call   80108ea2 <switchuvm>
  return 0;
80105593:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105598:	c9                   	leave  
80105599:	c3                   	ret    

8010559a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010559a:	55                   	push   %ebp
8010559b:	89 e5                	mov    %esp,%ebp
8010559d:	57                   	push   %edi
8010559e:	56                   	push   %esi
8010559f:	53                   	push   %ebx
801055a0:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801055a3:	e8 27 fd ff ff       	call   801052cf <allocproc>
801055a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
801055ab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801055af:	75 0a                	jne    801055bb <fork+0x21>
    return -1;
801055b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055b6:	e9 3a 01 00 00       	jmp    801056f5 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801055bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c1:	8b 10                	mov    (%eax),%edx
801055c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c9:	8b 40 04             	mov    0x4(%eax),%eax
801055cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801055d0:	89 04 24             	mov    %eax,(%esp)
801055d3:	e8 15 3e 00 00       	call   801093ed <copyuvm>
801055d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801055db:	89 42 04             	mov    %eax,0x4(%edx)
801055de:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055e1:	8b 40 04             	mov    0x4(%eax),%eax
801055e4:	85 c0                	test   %eax,%eax
801055e6:	75 2c                	jne    80105614 <fork+0x7a>
    kfree(np->kstack);
801055e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055eb:	8b 40 08             	mov    0x8(%eax),%eax
801055ee:	89 04 24             	mov    %eax,(%esp)
801055f1:	e8 18 e7 ff ff       	call   80103d0e <kfree>
    np->kstack = 0;
801055f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055f9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105600:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105603:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010560a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010560f:	e9 e1 00 00 00       	jmp    801056f5 <fork+0x15b>
  }
  np->sz = proc->sz;
80105614:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010561a:	8b 10                	mov    (%eax),%edx
8010561c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010561f:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80105621:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105628:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010562b:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010562e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105631:	8b 50 18             	mov    0x18(%eax),%edx
80105634:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010563a:	8b 40 18             	mov    0x18(%eax),%eax
8010563d:	89 c3                	mov    %eax,%ebx
8010563f:	b8 13 00 00 00       	mov    $0x13,%eax
80105644:	89 d7                	mov    %edx,%edi
80105646:	89 de                	mov    %ebx,%esi
80105648:	89 c1                	mov    %eax,%ecx
8010564a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010564c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010564f:	8b 40 18             	mov    0x18(%eax),%eax
80105652:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105659:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105660:	eb 3d                	jmp    8010569f <fork+0x105>
    if(proc->ofile[i])
80105662:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105668:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010566b:	83 c2 08             	add    $0x8,%edx
8010566e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105672:	85 c0                	test   %eax,%eax
80105674:	74 25                	je     8010569b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105676:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010567c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010567f:	83 c2 08             	add    $0x8,%edx
80105682:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105686:	89 04 24             	mov    %eax,(%esp)
80105689:	e8 ee b8 ff ff       	call   80100f7c <filedup>
8010568e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105691:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105694:	83 c1 08             	add    $0x8,%ecx
80105697:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010569b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010569f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801056a3:	7e bd                	jle    80105662 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801056a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056ab:	8b 40 68             	mov    0x68(%eax),%eax
801056ae:	89 04 24             	mov    %eax,(%esp)
801056b1:	e8 b0 cf ff ff       	call   80102666 <idup>
801056b6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801056b9:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801056bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056bf:	8b 40 10             	mov    0x10(%eax),%eax
801056c2:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801056c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056c8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801056cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056d5:	8d 50 6c             	lea    0x6c(%eax),%edx
801056d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801056db:	83 c0 6c             	add    $0x6c,%eax
801056de:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801056e5:	00 
801056e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801056ea:	89 04 24             	mov    %eax,(%esp)
801056ed:	e8 d8 0b 00 00       	call   801062ca <safestrcpy>
  return pid;
801056f2:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801056f5:	83 c4 2c             	add    $0x2c,%esp
801056f8:	5b                   	pop    %ebx
801056f9:	5e                   	pop    %esi
801056fa:	5f                   	pop    %edi
801056fb:	5d                   	pop    %ebp
801056fc:	c3                   	ret    

801056fd <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801056fd:	55                   	push   %ebp
801056fe:	89 e5                	mov    %esp,%ebp
80105700:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80105703:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010570a:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010570f:	39 c2                	cmp    %eax,%edx
80105711:	75 0c                	jne    8010571f <exit+0x22>
    panic("init exiting");
80105713:	c7 04 24 dc 99 10 80 	movl   $0x801099dc,(%esp)
8010571a:	e8 1e ae ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010571f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105726:	eb 44                	jmp    8010576c <exit+0x6f>
    if(proc->ofile[fd]){
80105728:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010572e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105731:	83 c2 08             	add    $0x8,%edx
80105734:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105738:	85 c0                	test   %eax,%eax
8010573a:	74 2c                	je     80105768 <exit+0x6b>
      fileclose(proc->ofile[fd]);
8010573c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105742:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105745:	83 c2 08             	add    $0x8,%edx
80105748:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010574c:	89 04 24             	mov    %eax,(%esp)
8010574f:	e8 70 b8 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105754:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010575a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010575d:	83 c2 08             	add    $0x8,%edx
80105760:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105767:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105768:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010576c:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105770:	7e b6                	jle    80105728 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80105772:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105778:	8b 40 68             	mov    0x68(%eax),%eax
8010577b:	89 04 24             	mov    %eax,(%esp)
8010577e:	e8 c8 d0 ff ff       	call   8010284b <iput>
  proc->cwd = 0;
80105783:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105789:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80105790:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105797:	e8 af 06 00 00       	call   80105e4b <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010579c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a2:	8b 40 14             	mov    0x14(%eax),%eax
801057a5:	89 04 24             	mov    %eax,(%esp)
801057a8:	e8 5b 04 00 00       	call   80105c08 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057ad:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
801057b4:	eb 38                	jmp    801057ee <exit+0xf1>
    if(p->parent == proc){
801057b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b9:	8b 50 14             	mov    0x14(%eax),%edx
801057bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057c2:	39 c2                	cmp    %eax,%edx
801057c4:	75 24                	jne    801057ea <exit+0xed>
      p->parent = initproc;
801057c6:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801057cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057cf:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801057d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d5:	8b 40 0c             	mov    0xc(%eax),%eax
801057d8:	83 f8 05             	cmp    $0x5,%eax
801057db:	75 0d                	jne    801057ea <exit+0xed>
        wakeup1(initproc);
801057dd:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801057e2:	89 04 24             	mov    %eax,(%esp)
801057e5:	e8 1e 04 00 00       	call   80105c08 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801057ea:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801057ee:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
801057f5:	72 bf                	jb     801057b6 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801057f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057fd:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105804:	e8 54 02 00 00       	call   80105a5d <sched>
  panic("zombie exit");
80105809:	c7 04 24 e9 99 10 80 	movl   $0x801099e9,(%esp)
80105810:	e8 28 ad ff ff       	call   8010053d <panic>

80105815 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105815:	55                   	push   %ebp
80105816:	89 e5                	mov    %esp,%ebp
80105818:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010581b:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105822:	e8 24 06 00 00       	call   80105e4b <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105827:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010582e:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105835:	e9 9a 00 00 00       	jmp    801058d4 <wait+0xbf>
      if(p->parent != proc)
8010583a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010583d:	8b 50 14             	mov    0x14(%eax),%edx
80105840:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105846:	39 c2                	cmp    %eax,%edx
80105848:	0f 85 81 00 00 00    	jne    801058cf <wait+0xba>
        continue;
      havekids = 1;
8010584e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105858:	8b 40 0c             	mov    0xc(%eax),%eax
8010585b:	83 f8 05             	cmp    $0x5,%eax
8010585e:	75 70                	jne    801058d0 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105860:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105863:	8b 40 10             	mov    0x10(%eax),%eax
80105866:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010586c:	8b 40 08             	mov    0x8(%eax),%eax
8010586f:	89 04 24             	mov    %eax,(%esp)
80105872:	e8 97 e4 ff ff       	call   80103d0e <kfree>
        p->kstack = 0;
80105877:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010587a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105881:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105884:	8b 40 04             	mov    0x4(%eax),%eax
80105887:	89 04 24             	mov    %eax,(%esp)
8010588a:	e8 8a 3a 00 00       	call   80109319 <freevm>
        p->state = UNUSED;
8010588f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105892:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105899:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589c:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801058a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a6:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801058ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b0:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801058b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b7:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801058be:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801058c5:	e8 e3 05 00 00       	call   80105ead <release>
        return pid;
801058ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801058cd:	eb 53                	jmp    80105922 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801058cf:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058d0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801058d4:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
801058db:	0f 82 59 ff ff ff    	jb     8010583a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801058e1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058e5:	74 0d                	je     801058f4 <wait+0xdf>
801058e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058ed:	8b 40 24             	mov    0x24(%eax),%eax
801058f0:	85 c0                	test   %eax,%eax
801058f2:	74 13                	je     80105907 <wait+0xf2>
      release(&ptable.lock);
801058f4:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801058fb:	e8 ad 05 00 00       	call   80105ead <release>
      return -1;
80105900:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105905:	eb 1b                	jmp    80105922 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105907:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010590d:	c7 44 24 04 80 0f 11 	movl   $0x80110f80,0x4(%esp)
80105914:	80 
80105915:	89 04 24             	mov    %eax,(%esp)
80105918:	e8 50 02 00 00       	call   80105b6d <sleep>
  }
8010591d:	e9 05 ff ff ff       	jmp    80105827 <wait+0x12>
}
80105922:	c9                   	leave  
80105923:	c3                   	ret    

80105924 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105924:	55                   	push   %ebp
80105925:	89 e5                	mov    %esp,%ebp
80105927:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010592a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105930:	8b 40 18             	mov    0x18(%eax),%eax
80105933:	8b 40 44             	mov    0x44(%eax),%eax
80105936:	89 c2                	mov    %eax,%edx
80105938:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010593e:	8b 40 04             	mov    0x4(%eax),%eax
80105941:	89 54 24 04          	mov    %edx,0x4(%esp)
80105945:	89 04 24             	mov    %eax,(%esp)
80105948:	e8 b1 3b 00 00       	call   801094fe <uva2ka>
8010594d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105950:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105956:	8b 40 18             	mov    0x18(%eax),%eax
80105959:	8b 40 44             	mov    0x44(%eax),%eax
8010595c:	25 ff 0f 00 00       	and    $0xfff,%eax
80105961:	85 c0                	test   %eax,%eax
80105963:	75 0c                	jne    80105971 <register_handler+0x4d>
    panic("esp_offset == 0");
80105965:	c7 04 24 f5 99 10 80 	movl   $0x801099f5,(%esp)
8010596c:	e8 cc ab ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105971:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105977:	8b 40 18             	mov    0x18(%eax),%eax
8010597a:	8b 40 44             	mov    0x44(%eax),%eax
8010597d:	83 e8 04             	sub    $0x4,%eax
80105980:	25 ff 0f 00 00       	and    $0xfff,%eax
80105985:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105988:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010598f:	8b 52 18             	mov    0x18(%edx),%edx
80105992:	8b 52 38             	mov    0x38(%edx),%edx
80105995:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105997:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010599d:	8b 40 18             	mov    0x18(%eax),%eax
801059a0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801059a7:	8b 52 18             	mov    0x18(%edx),%edx
801059aa:	8b 52 44             	mov    0x44(%edx),%edx
801059ad:	83 ea 04             	sub    $0x4,%edx
801059b0:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801059b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059b9:	8b 40 18             	mov    0x18(%eax),%eax
801059bc:	8b 55 08             	mov    0x8(%ebp),%edx
801059bf:	89 50 38             	mov    %edx,0x38(%eax)
}
801059c2:	c9                   	leave  
801059c3:	c3                   	ret    

801059c4 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801059c4:	55                   	push   %ebp
801059c5:	89 e5                	mov    %esp,%ebp
801059c7:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801059ca:	e8 de f8 ff ff       	call   801052ad <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801059cf:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
801059d6:	e8 70 04 00 00       	call   80105e4b <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059db:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
801059e2:	eb 5f                	jmp    80105a43 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801059e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059e7:	8b 40 0c             	mov    0xc(%eax),%eax
801059ea:	83 f8 03             	cmp    $0x3,%eax
801059ed:	75 4f                	jne    80105a3e <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801059ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059f2:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801059f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059fb:	89 04 24             	mov    %eax,(%esp)
801059fe:	e8 9f 34 00 00       	call   80108ea2 <switchuvm>
      p->state = RUNNING;
80105a03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a06:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105a0d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a13:	8b 40 1c             	mov    0x1c(%eax),%eax
80105a16:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105a1d:	83 c2 04             	add    $0x4,%edx
80105a20:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a24:	89 14 24             	mov    %edx,(%esp)
80105a27:	e8 14 09 00 00       	call   80106340 <swtch>
      switchkvm();
80105a2c:	e8 54 34 00 00       	call   80108e85 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105a31:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105a38:	00 00 00 00 
80105a3c:	eb 01                	jmp    80105a3f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80105a3e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105a3f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105a43:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
80105a4a:	72 98                	jb     801059e4 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80105a4c:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105a53:	e8 55 04 00 00       	call   80105ead <release>

  }
80105a58:	e9 6d ff ff ff       	jmp    801059ca <scheduler+0x6>

80105a5d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80105a5d:	55                   	push   %ebp
80105a5e:	89 e5                	mov    %esp,%ebp
80105a60:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105a63:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105a6a:	e8 fa 04 00 00       	call   80105f69 <holding>
80105a6f:	85 c0                	test   %eax,%eax
80105a71:	75 0c                	jne    80105a7f <sched+0x22>
    panic("sched ptable.lock");
80105a73:	c7 04 24 05 9a 10 80 	movl   $0x80109a05,(%esp)
80105a7a:	e8 be aa ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80105a7f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a85:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105a8b:	83 f8 01             	cmp    $0x1,%eax
80105a8e:	74 0c                	je     80105a9c <sched+0x3f>
    panic("sched locks");
80105a90:	c7 04 24 17 9a 10 80 	movl   $0x80109a17,(%esp)
80105a97:	e8 a1 aa ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80105a9c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105aa2:	8b 40 0c             	mov    0xc(%eax),%eax
80105aa5:	83 f8 04             	cmp    $0x4,%eax
80105aa8:	75 0c                	jne    80105ab6 <sched+0x59>
    panic("sched running");
80105aaa:	c7 04 24 23 9a 10 80 	movl   $0x80109a23,(%esp)
80105ab1:	e8 87 aa ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105ab6:	e8 dd f7 ff ff       	call   80105298 <readeflags>
80105abb:	25 00 02 00 00       	and    $0x200,%eax
80105ac0:	85 c0                	test   %eax,%eax
80105ac2:	74 0c                	je     80105ad0 <sched+0x73>
    panic("sched interruptible");
80105ac4:	c7 04 24 31 9a 10 80 	movl   $0x80109a31,(%esp)
80105acb:	e8 6d aa ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105ad0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ad6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105adc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105adf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ae5:	8b 40 04             	mov    0x4(%eax),%eax
80105ae8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105aef:	83 c2 1c             	add    $0x1c,%edx
80105af2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105af6:	89 14 24             	mov    %edx,(%esp)
80105af9:	e8 42 08 00 00       	call   80106340 <swtch>
  cpu->intena = intena;
80105afe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b04:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b07:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105b0d:	c9                   	leave  
80105b0e:	c3                   	ret    

80105b0f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105b0f:	55                   	push   %ebp
80105b10:	89 e5                	mov    %esp,%ebp
80105b12:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105b15:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105b1c:	e8 2a 03 00 00       	call   80105e4b <acquire>
  proc->state = RUNNABLE;
80105b21:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b27:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105b2e:	e8 2a ff ff ff       	call   80105a5d <sched>
  release(&ptable.lock);
80105b33:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105b3a:	e8 6e 03 00 00       	call   80105ead <release>
}
80105b3f:	c9                   	leave  
80105b40:	c3                   	ret    

80105b41 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105b41:	55                   	push   %ebp
80105b42:	89 e5                	mov    %esp,%ebp
80105b44:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105b47:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105b4e:	e8 5a 03 00 00       	call   80105ead <release>

  if (first) {
80105b53:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105b58:	85 c0                	test   %eax,%eax
80105b5a:	74 0f                	je     80105b6b <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105b5c:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105b63:	00 00 00 
    initlog();
80105b66:	e8 4d e7 ff ff       	call   801042b8 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105b6b:	c9                   	leave  
80105b6c:	c3                   	ret    

80105b6d <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105b6d:	55                   	push   %ebp
80105b6e:	89 e5                	mov    %esp,%ebp
80105b70:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105b73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b79:	85 c0                	test   %eax,%eax
80105b7b:	75 0c                	jne    80105b89 <sleep+0x1c>
    panic("sleep");
80105b7d:	c7 04 24 45 9a 10 80 	movl   $0x80109a45,(%esp)
80105b84:	e8 b4 a9 ff ff       	call   8010053d <panic>

  if(lk == 0)
80105b89:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105b8d:	75 0c                	jne    80105b9b <sleep+0x2e>
    panic("sleep without lk");
80105b8f:	c7 04 24 4b 9a 10 80 	movl   $0x80109a4b,(%esp)
80105b96:	e8 a2 a9 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105b9b:	81 7d 0c 80 0f 11 80 	cmpl   $0x80110f80,0xc(%ebp)
80105ba2:	74 17                	je     80105bbb <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105ba4:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105bab:	e8 9b 02 00 00       	call   80105e4b <acquire>
    release(lk);
80105bb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bb3:	89 04 24             	mov    %eax,(%esp)
80105bb6:	e8 f2 02 00 00       	call   80105ead <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105bbb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bc1:	8b 55 08             	mov    0x8(%ebp),%edx
80105bc4:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105bc7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bcd:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105bd4:	e8 84 fe ff ff       	call   80105a5d <sched>

  // Tidy up.
  proc->chan = 0;
80105bd9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105bdf:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105be6:	81 7d 0c 80 0f 11 80 	cmpl   $0x80110f80,0xc(%ebp)
80105bed:	74 17                	je     80105c06 <sleep+0x99>
    release(&ptable.lock);
80105bef:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105bf6:	e8 b2 02 00 00       	call   80105ead <release>
    acquire(lk);
80105bfb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bfe:	89 04 24             	mov    %eax,(%esp)
80105c01:	e8 45 02 00 00       	call   80105e4b <acquire>
  }
}
80105c06:	c9                   	leave  
80105c07:	c3                   	ret    

80105c08 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105c08:	55                   	push   %ebp
80105c09:	89 e5                	mov    %esp,%ebp
80105c0b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105c0e:	c7 45 fc b4 0f 11 80 	movl   $0x80110fb4,-0x4(%ebp)
80105c15:	eb 24                	jmp    80105c3b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105c17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c1a:	8b 40 0c             	mov    0xc(%eax),%eax
80105c1d:	83 f8 02             	cmp    $0x2,%eax
80105c20:	75 15                	jne    80105c37 <wakeup1+0x2f>
80105c22:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c25:	8b 40 20             	mov    0x20(%eax),%eax
80105c28:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c2b:	75 0a                	jne    80105c37 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105c2d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105c30:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105c37:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105c3b:	81 7d fc b4 2e 11 80 	cmpl   $0x80112eb4,-0x4(%ebp)
80105c42:	72 d3                	jb     80105c17 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105c44:	c9                   	leave  
80105c45:	c3                   	ret    

80105c46 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105c46:	55                   	push   %ebp
80105c47:	89 e5                	mov    %esp,%ebp
80105c49:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105c4c:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105c53:	e8 f3 01 00 00       	call   80105e4b <acquire>
  wakeup1(chan);
80105c58:	8b 45 08             	mov    0x8(%ebp),%eax
80105c5b:	89 04 24             	mov    %eax,(%esp)
80105c5e:	e8 a5 ff ff ff       	call   80105c08 <wakeup1>
  release(&ptable.lock);
80105c63:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105c6a:	e8 3e 02 00 00       	call   80105ead <release>
}
80105c6f:	c9                   	leave  
80105c70:	c3                   	ret    

80105c71 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105c71:	55                   	push   %ebp
80105c72:	89 e5                	mov    %esp,%ebp
80105c74:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105c77:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105c7e:	e8 c8 01 00 00       	call   80105e4b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105c83:	c7 45 f4 b4 0f 11 80 	movl   $0x80110fb4,-0xc(%ebp)
80105c8a:	eb 41                	jmp    80105ccd <kill+0x5c>
    if(p->pid == pid){
80105c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c8f:	8b 40 10             	mov    0x10(%eax),%eax
80105c92:	3b 45 08             	cmp    0x8(%ebp),%eax
80105c95:	75 32                	jne    80105cc9 <kill+0x58>
      p->killed = 1;
80105c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c9a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ca4:	8b 40 0c             	mov    0xc(%eax),%eax
80105ca7:	83 f8 02             	cmp    $0x2,%eax
80105caa:	75 0a                	jne    80105cb6 <kill+0x45>
        p->state = RUNNABLE;
80105cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105caf:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105cb6:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105cbd:	e8 eb 01 00 00       	call   80105ead <release>
      return 0;
80105cc2:	b8 00 00 00 00       	mov    $0x0,%eax
80105cc7:	eb 1e                	jmp    80105ce7 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105cc9:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105ccd:	81 7d f4 b4 2e 11 80 	cmpl   $0x80112eb4,-0xc(%ebp)
80105cd4:	72 b6                	jb     80105c8c <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105cd6:	c7 04 24 80 0f 11 80 	movl   $0x80110f80,(%esp)
80105cdd:	e8 cb 01 00 00       	call   80105ead <release>
  return -1;
80105ce2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105ce7:	c9                   	leave  
80105ce8:	c3                   	ret    

80105ce9 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105ce9:	55                   	push   %ebp
80105cea:	89 e5                	mov    %esp,%ebp
80105cec:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105cef:	c7 45 f0 b4 0f 11 80 	movl   $0x80110fb4,-0x10(%ebp)
80105cf6:	e9 d8 00 00 00       	jmp    80105dd3 <procdump+0xea>
    if(p->state == UNUSED)
80105cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cfe:	8b 40 0c             	mov    0xc(%eax),%eax
80105d01:	85 c0                	test   %eax,%eax
80105d03:	0f 84 c5 00 00 00    	je     80105dce <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105d09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d0c:	8b 40 0c             	mov    0xc(%eax),%eax
80105d0f:	83 f8 05             	cmp    $0x5,%eax
80105d12:	77 23                	ja     80105d37 <procdump+0x4e>
80105d14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d17:	8b 40 0c             	mov    0xc(%eax),%eax
80105d1a:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105d21:	85 c0                	test   %eax,%eax
80105d23:	74 12                	je     80105d37 <procdump+0x4e>
      state = states[p->state];
80105d25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d28:	8b 40 0c             	mov    0xc(%eax),%eax
80105d2b:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105d32:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105d35:	eb 07                	jmp    80105d3e <procdump+0x55>
    else
      state = "???";
80105d37:	c7 45 ec 5c 9a 10 80 	movl   $0x80109a5c,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105d3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d41:	8d 50 6c             	lea    0x6c(%eax),%edx
80105d44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d47:	8b 40 10             	mov    0x10(%eax),%eax
80105d4a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105d4e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105d51:	89 54 24 08          	mov    %edx,0x8(%esp)
80105d55:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d59:	c7 04 24 60 9a 10 80 	movl   $0x80109a60,(%esp)
80105d60:	e8 3c a6 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105d65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d68:	8b 40 0c             	mov    0xc(%eax),%eax
80105d6b:	83 f8 02             	cmp    $0x2,%eax
80105d6e:	75 50                	jne    80105dc0 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105d70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d73:	8b 40 1c             	mov    0x1c(%eax),%eax
80105d76:	8b 40 0c             	mov    0xc(%eax),%eax
80105d79:	83 c0 08             	add    $0x8,%eax
80105d7c:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105d7f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105d83:	89 04 24             	mov    %eax,(%esp)
80105d86:	e8 71 01 00 00       	call   80105efc <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105d8b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105d92:	eb 1b                	jmp    80105daf <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d97:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105d9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d9f:	c7 04 24 69 9a 10 80 	movl   $0x80109a69,(%esp)
80105da6:	e8 f6 a5 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105dab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105daf:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105db3:	7f 0b                	jg     80105dc0 <procdump+0xd7>
80105db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105db8:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105dbc:	85 c0                	test   %eax,%eax
80105dbe:	75 d4                	jne    80105d94 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105dc0:	c7 04 24 6d 9a 10 80 	movl   $0x80109a6d,(%esp)
80105dc7:	e8 d5 a5 ff ff       	call   801003a1 <cprintf>
80105dcc:	eb 01                	jmp    80105dcf <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105dce:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105dcf:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105dd3:	81 7d f0 b4 2e 11 80 	cmpl   $0x80112eb4,-0x10(%ebp)
80105dda:	0f 82 1b ff ff ff    	jb     80105cfb <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105de0:	c9                   	leave  
80105de1:	c3                   	ret    
	...

80105de4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105de4:	55                   	push   %ebp
80105de5:	89 e5                	mov    %esp,%ebp
80105de7:	53                   	push   %ebx
80105de8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105deb:	9c                   	pushf  
80105dec:	5b                   	pop    %ebx
80105ded:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105df0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105df3:	83 c4 10             	add    $0x10,%esp
80105df6:	5b                   	pop    %ebx
80105df7:	5d                   	pop    %ebp
80105df8:	c3                   	ret    

80105df9 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105df9:	55                   	push   %ebp
80105dfa:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105dfc:	fa                   	cli    
}
80105dfd:	5d                   	pop    %ebp
80105dfe:	c3                   	ret    

80105dff <sti>:

static inline void
sti(void)
{
80105dff:	55                   	push   %ebp
80105e00:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105e02:	fb                   	sti    
}
80105e03:	5d                   	pop    %ebp
80105e04:	c3                   	ret    

80105e05 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105e05:	55                   	push   %ebp
80105e06:	89 e5                	mov    %esp,%ebp
80105e08:	53                   	push   %ebx
80105e09:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105e0c:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105e0f:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105e12:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105e15:	89 c3                	mov    %eax,%ebx
80105e17:	89 d8                	mov    %ebx,%eax
80105e19:	f0 87 02             	lock xchg %eax,(%edx)
80105e1c:	89 c3                	mov    %eax,%ebx
80105e1e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105e21:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105e24:	83 c4 10             	add    $0x10,%esp
80105e27:	5b                   	pop    %ebx
80105e28:	5d                   	pop    %ebp
80105e29:	c3                   	ret    

80105e2a <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105e2a:	55                   	push   %ebp
80105e2b:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105e2d:	8b 45 08             	mov    0x8(%ebp),%eax
80105e30:	8b 55 0c             	mov    0xc(%ebp),%edx
80105e33:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105e36:	8b 45 08             	mov    0x8(%ebp),%eax
80105e39:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e42:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105e49:	5d                   	pop    %ebp
80105e4a:	c3                   	ret    

80105e4b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105e4b:	55                   	push   %ebp
80105e4c:	89 e5                	mov    %esp,%ebp
80105e4e:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105e51:	e8 3d 01 00 00       	call   80105f93 <pushcli>
  if(holding(lk))
80105e56:	8b 45 08             	mov    0x8(%ebp),%eax
80105e59:	89 04 24             	mov    %eax,(%esp)
80105e5c:	e8 08 01 00 00       	call   80105f69 <holding>
80105e61:	85 c0                	test   %eax,%eax
80105e63:	74 0c                	je     80105e71 <acquire+0x26>
    panic("acquire");
80105e65:	c7 04 24 99 9a 10 80 	movl   $0x80109a99,(%esp)
80105e6c:	e8 cc a6 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105e71:	90                   	nop
80105e72:	8b 45 08             	mov    0x8(%ebp),%eax
80105e75:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105e7c:	00 
80105e7d:	89 04 24             	mov    %eax,(%esp)
80105e80:	e8 80 ff ff ff       	call   80105e05 <xchg>
80105e85:	85 c0                	test   %eax,%eax
80105e87:	75 e9                	jne    80105e72 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105e89:	8b 45 08             	mov    0x8(%ebp),%eax
80105e8c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105e93:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105e96:	8b 45 08             	mov    0x8(%ebp),%eax
80105e99:	83 c0 0c             	add    $0xc,%eax
80105e9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ea0:	8d 45 08             	lea    0x8(%ebp),%eax
80105ea3:	89 04 24             	mov    %eax,(%esp)
80105ea6:	e8 51 00 00 00       	call   80105efc <getcallerpcs>
}
80105eab:	c9                   	leave  
80105eac:	c3                   	ret    

80105ead <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105ead:	55                   	push   %ebp
80105eae:	89 e5                	mov    %esp,%ebp
80105eb0:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105eb3:	8b 45 08             	mov    0x8(%ebp),%eax
80105eb6:	89 04 24             	mov    %eax,(%esp)
80105eb9:	e8 ab 00 00 00       	call   80105f69 <holding>
80105ebe:	85 c0                	test   %eax,%eax
80105ec0:	75 0c                	jne    80105ece <release+0x21>
    panic("release");
80105ec2:	c7 04 24 a1 9a 10 80 	movl   $0x80109aa1,(%esp)
80105ec9:	e8 6f a6 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105ece:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ed8:	8b 45 08             	mov    0x8(%ebp),%eax
80105edb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105ee2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ee5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105eec:	00 
80105eed:	89 04 24             	mov    %eax,(%esp)
80105ef0:	e8 10 ff ff ff       	call   80105e05 <xchg>

  popcli();
80105ef5:	e8 e1 00 00 00       	call   80105fdb <popcli>
}
80105efa:	c9                   	leave  
80105efb:	c3                   	ret    

80105efc <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105efc:	55                   	push   %ebp
80105efd:	89 e5                	mov    %esp,%ebp
80105eff:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105f02:	8b 45 08             	mov    0x8(%ebp),%eax
80105f05:	83 e8 08             	sub    $0x8,%eax
80105f08:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105f0b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105f12:	eb 32                	jmp    80105f46 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105f14:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105f18:	74 47                	je     80105f61 <getcallerpcs+0x65>
80105f1a:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105f21:	76 3e                	jbe    80105f61 <getcallerpcs+0x65>
80105f23:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105f27:	74 38                	je     80105f61 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105f29:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f2c:	c1 e0 02             	shl    $0x2,%eax
80105f2f:	03 45 0c             	add    0xc(%ebp),%eax
80105f32:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f35:	8b 52 04             	mov    0x4(%edx),%edx
80105f38:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105f3a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f3d:	8b 00                	mov    (%eax),%eax
80105f3f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105f42:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f46:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105f4a:	7e c8                	jle    80105f14 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105f4c:	eb 13                	jmp    80105f61 <getcallerpcs+0x65>
    pcs[i] = 0;
80105f4e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105f51:	c1 e0 02             	shl    $0x2,%eax
80105f54:	03 45 0c             	add    0xc(%ebp),%eax
80105f57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105f5d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105f61:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105f65:	7e e7                	jle    80105f4e <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105f67:	c9                   	leave  
80105f68:	c3                   	ret    

80105f69 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105f69:	55                   	push   %ebp
80105f6a:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105f6c:	8b 45 08             	mov    0x8(%ebp),%eax
80105f6f:	8b 00                	mov    (%eax),%eax
80105f71:	85 c0                	test   %eax,%eax
80105f73:	74 17                	je     80105f8c <holding+0x23>
80105f75:	8b 45 08             	mov    0x8(%ebp),%eax
80105f78:	8b 50 08             	mov    0x8(%eax),%edx
80105f7b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f81:	39 c2                	cmp    %eax,%edx
80105f83:	75 07                	jne    80105f8c <holding+0x23>
80105f85:	b8 01 00 00 00       	mov    $0x1,%eax
80105f8a:	eb 05                	jmp    80105f91 <holding+0x28>
80105f8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f91:	5d                   	pop    %ebp
80105f92:	c3                   	ret    

80105f93 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105f93:	55                   	push   %ebp
80105f94:	89 e5                	mov    %esp,%ebp
80105f96:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105f99:	e8 46 fe ff ff       	call   80105de4 <readeflags>
80105f9e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105fa1:	e8 53 fe ff ff       	call   80105df9 <cli>
  if(cpu->ncli++ == 0)
80105fa6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105fac:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105fb2:	85 d2                	test   %edx,%edx
80105fb4:	0f 94 c1             	sete   %cl
80105fb7:	83 c2 01             	add    $0x1,%edx
80105fba:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105fc0:	84 c9                	test   %cl,%cl
80105fc2:	74 15                	je     80105fd9 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105fc4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105fca:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fcd:	81 e2 00 02 00 00    	and    $0x200,%edx
80105fd3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105fd9:	c9                   	leave  
80105fda:	c3                   	ret    

80105fdb <popcli>:

void
popcli(void)
{
80105fdb:	55                   	push   %ebp
80105fdc:	89 e5                	mov    %esp,%ebp
80105fde:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105fe1:	e8 fe fd ff ff       	call   80105de4 <readeflags>
80105fe6:	25 00 02 00 00       	and    $0x200,%eax
80105feb:	85 c0                	test   %eax,%eax
80105fed:	74 0c                	je     80105ffb <popcli+0x20>
    panic("popcli - interruptible");
80105fef:	c7 04 24 a9 9a 10 80 	movl   $0x80109aa9,(%esp)
80105ff6:	e8 42 a5 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105ffb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106001:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80106007:	83 ea 01             	sub    $0x1,%edx
8010600a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80106010:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80106016:	85 c0                	test   %eax,%eax
80106018:	79 0c                	jns    80106026 <popcli+0x4b>
    panic("popcli");
8010601a:	c7 04 24 c0 9a 10 80 	movl   $0x80109ac0,(%esp)
80106021:	e8 17 a5 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80106026:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010602c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80106032:	85 c0                	test   %eax,%eax
80106034:	75 15                	jne    8010604b <popcli+0x70>
80106036:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010603c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80106042:	85 c0                	test   %eax,%eax
80106044:	74 05                	je     8010604b <popcli+0x70>
    sti();
80106046:	e8 b4 fd ff ff       	call   80105dff <sti>
}
8010604b:	c9                   	leave  
8010604c:	c3                   	ret    
8010604d:	00 00                	add    %al,(%eax)
	...

80106050 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80106050:	55                   	push   %ebp
80106051:	89 e5                	mov    %esp,%ebp
80106053:	57                   	push   %edi
80106054:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80106055:	8b 4d 08             	mov    0x8(%ebp),%ecx
80106058:	8b 55 10             	mov    0x10(%ebp),%edx
8010605b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010605e:	89 cb                	mov    %ecx,%ebx
80106060:	89 df                	mov    %ebx,%edi
80106062:	89 d1                	mov    %edx,%ecx
80106064:	fc                   	cld    
80106065:	f3 aa                	rep stos %al,%es:(%edi)
80106067:	89 ca                	mov    %ecx,%edx
80106069:	89 fb                	mov    %edi,%ebx
8010606b:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010606e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80106071:	5b                   	pop    %ebx
80106072:	5f                   	pop    %edi
80106073:	5d                   	pop    %ebp
80106074:	c3                   	ret    

80106075 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80106075:	55                   	push   %ebp
80106076:	89 e5                	mov    %esp,%ebp
80106078:	57                   	push   %edi
80106079:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010607a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010607d:	8b 55 10             	mov    0x10(%ebp),%edx
80106080:	8b 45 0c             	mov    0xc(%ebp),%eax
80106083:	89 cb                	mov    %ecx,%ebx
80106085:	89 df                	mov    %ebx,%edi
80106087:	89 d1                	mov    %edx,%ecx
80106089:	fc                   	cld    
8010608a:	f3 ab                	rep stos %eax,%es:(%edi)
8010608c:	89 ca                	mov    %ecx,%edx
8010608e:	89 fb                	mov    %edi,%ebx
80106090:	89 5d 08             	mov    %ebx,0x8(%ebp)
80106093:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80106096:	5b                   	pop    %ebx
80106097:	5f                   	pop    %edi
80106098:	5d                   	pop    %ebp
80106099:	c3                   	ret    

8010609a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010609a:	55                   	push   %ebp
8010609b:	89 e5                	mov    %esp,%ebp
8010609d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
801060a0:	8b 45 08             	mov    0x8(%ebp),%eax
801060a3:	83 e0 03             	and    $0x3,%eax
801060a6:	85 c0                	test   %eax,%eax
801060a8:	75 49                	jne    801060f3 <memset+0x59>
801060aa:	8b 45 10             	mov    0x10(%ebp),%eax
801060ad:	83 e0 03             	and    $0x3,%eax
801060b0:	85 c0                	test   %eax,%eax
801060b2:	75 3f                	jne    801060f3 <memset+0x59>
    c &= 0xFF;
801060b4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801060bb:	8b 45 10             	mov    0x10(%ebp),%eax
801060be:	c1 e8 02             	shr    $0x2,%eax
801060c1:	89 c2                	mov    %eax,%edx
801060c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801060c6:	89 c1                	mov    %eax,%ecx
801060c8:	c1 e1 18             	shl    $0x18,%ecx
801060cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801060ce:	c1 e0 10             	shl    $0x10,%eax
801060d1:	09 c1                	or     %eax,%ecx
801060d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801060d6:	c1 e0 08             	shl    $0x8,%eax
801060d9:	09 c8                	or     %ecx,%eax
801060db:	0b 45 0c             	or     0xc(%ebp),%eax
801060de:	89 54 24 08          	mov    %edx,0x8(%esp)
801060e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801060e6:	8b 45 08             	mov    0x8(%ebp),%eax
801060e9:	89 04 24             	mov    %eax,(%esp)
801060ec:	e8 84 ff ff ff       	call   80106075 <stosl>
801060f1:	eb 19                	jmp    8010610c <memset+0x72>
  } else
    stosb(dst, c, n);
801060f3:	8b 45 10             	mov    0x10(%ebp),%eax
801060f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801060fa:	8b 45 0c             	mov    0xc(%ebp),%eax
801060fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80106101:	8b 45 08             	mov    0x8(%ebp),%eax
80106104:	89 04 24             	mov    %eax,(%esp)
80106107:	e8 44 ff ff ff       	call   80106050 <stosb>
  return dst;
8010610c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010610f:	c9                   	leave  
80106110:	c3                   	ret    

80106111 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80106111:	55                   	push   %ebp
80106112:	89 e5                	mov    %esp,%ebp
80106114:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80106117:	8b 45 08             	mov    0x8(%ebp),%eax
8010611a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
8010611d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106120:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80106123:	eb 32                	jmp    80106157 <memcmp+0x46>
    if(*s1 != *s2)
80106125:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106128:	0f b6 10             	movzbl (%eax),%edx
8010612b:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010612e:	0f b6 00             	movzbl (%eax),%eax
80106131:	38 c2                	cmp    %al,%dl
80106133:	74 1a                	je     8010614f <memcmp+0x3e>
      return *s1 - *s2;
80106135:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106138:	0f b6 00             	movzbl (%eax),%eax
8010613b:	0f b6 d0             	movzbl %al,%edx
8010613e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80106141:	0f b6 00             	movzbl (%eax),%eax
80106144:	0f b6 c0             	movzbl %al,%eax
80106147:	89 d1                	mov    %edx,%ecx
80106149:	29 c1                	sub    %eax,%ecx
8010614b:	89 c8                	mov    %ecx,%eax
8010614d:	eb 1c                	jmp    8010616b <memcmp+0x5a>
    s1++, s2++;
8010614f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106153:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80106157:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010615b:	0f 95 c0             	setne  %al
8010615e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106162:	84 c0                	test   %al,%al
80106164:	75 bf                	jne    80106125 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80106166:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010616b:	c9                   	leave  
8010616c:	c3                   	ret    

8010616d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010616d:	55                   	push   %ebp
8010616e:	89 e5                	mov    %esp,%ebp
80106170:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80106173:	8b 45 0c             	mov    0xc(%ebp),%eax
80106176:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80106179:	8b 45 08             	mov    0x8(%ebp),%eax
8010617c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010617f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106182:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106185:	73 54                	jae    801061db <memmove+0x6e>
80106187:	8b 45 10             	mov    0x10(%ebp),%eax
8010618a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010618d:	01 d0                	add    %edx,%eax
8010618f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106192:	76 47                	jbe    801061db <memmove+0x6e>
    s += n;
80106194:	8b 45 10             	mov    0x10(%ebp),%eax
80106197:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010619a:	8b 45 10             	mov    0x10(%ebp),%eax
8010619d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801061a0:	eb 13                	jmp    801061b5 <memmove+0x48>
      *--d = *--s;
801061a2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801061a6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801061aa:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061ad:	0f b6 10             	movzbl (%eax),%edx
801061b0:	8b 45 f8             	mov    -0x8(%ebp),%eax
801061b3:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801061b5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061b9:	0f 95 c0             	setne  %al
801061bc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061c0:	84 c0                	test   %al,%al
801061c2:	75 de                	jne    801061a2 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801061c4:	eb 25                	jmp    801061eb <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801061c6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061c9:	0f b6 10             	movzbl (%eax),%edx
801061cc:	8b 45 f8             	mov    -0x8(%ebp),%eax
801061cf:	88 10                	mov    %dl,(%eax)
801061d1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801061d5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801061d9:	eb 01                	jmp    801061dc <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801061db:	90                   	nop
801061dc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061e0:	0f 95 c0             	setne  %al
801061e3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061e7:	84 c0                	test   %al,%al
801061e9:	75 db                	jne    801061c6 <memmove+0x59>
      *d++ = *s++;

  return dst;
801061eb:	8b 45 08             	mov    0x8(%ebp),%eax
}
801061ee:	c9                   	leave  
801061ef:	c3                   	ret    

801061f0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801061f0:	55                   	push   %ebp
801061f1:	89 e5                	mov    %esp,%ebp
801061f3:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801061f6:	8b 45 10             	mov    0x10(%ebp),%eax
801061f9:	89 44 24 08          	mov    %eax,0x8(%esp)
801061fd:	8b 45 0c             	mov    0xc(%ebp),%eax
80106200:	89 44 24 04          	mov    %eax,0x4(%esp)
80106204:	8b 45 08             	mov    0x8(%ebp),%eax
80106207:	89 04 24             	mov    %eax,(%esp)
8010620a:	e8 5e ff ff ff       	call   8010616d <memmove>
}
8010620f:	c9                   	leave  
80106210:	c3                   	ret    

80106211 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80106211:	55                   	push   %ebp
80106212:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80106214:	eb 0c                	jmp    80106222 <strncmp+0x11>
    n--, p++, q++;
80106216:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010621a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010621e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80106222:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106226:	74 1a                	je     80106242 <strncmp+0x31>
80106228:	8b 45 08             	mov    0x8(%ebp),%eax
8010622b:	0f b6 00             	movzbl (%eax),%eax
8010622e:	84 c0                	test   %al,%al
80106230:	74 10                	je     80106242 <strncmp+0x31>
80106232:	8b 45 08             	mov    0x8(%ebp),%eax
80106235:	0f b6 10             	movzbl (%eax),%edx
80106238:	8b 45 0c             	mov    0xc(%ebp),%eax
8010623b:	0f b6 00             	movzbl (%eax),%eax
8010623e:	38 c2                	cmp    %al,%dl
80106240:	74 d4                	je     80106216 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80106242:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106246:	75 07                	jne    8010624f <strncmp+0x3e>
    return 0;
80106248:	b8 00 00 00 00       	mov    $0x0,%eax
8010624d:	eb 18                	jmp    80106267 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010624f:	8b 45 08             	mov    0x8(%ebp),%eax
80106252:	0f b6 00             	movzbl (%eax),%eax
80106255:	0f b6 d0             	movzbl %al,%edx
80106258:	8b 45 0c             	mov    0xc(%ebp),%eax
8010625b:	0f b6 00             	movzbl (%eax),%eax
8010625e:	0f b6 c0             	movzbl %al,%eax
80106261:	89 d1                	mov    %edx,%ecx
80106263:	29 c1                	sub    %eax,%ecx
80106265:	89 c8                	mov    %ecx,%eax
}
80106267:	5d                   	pop    %ebp
80106268:	c3                   	ret    

80106269 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80106269:	55                   	push   %ebp
8010626a:	89 e5                	mov    %esp,%ebp
8010626c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010626f:	8b 45 08             	mov    0x8(%ebp),%eax
80106272:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80106275:	90                   	nop
80106276:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010627a:	0f 9f c0             	setg   %al
8010627d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106281:	84 c0                	test   %al,%al
80106283:	74 30                	je     801062b5 <strncpy+0x4c>
80106285:	8b 45 0c             	mov    0xc(%ebp),%eax
80106288:	0f b6 10             	movzbl (%eax),%edx
8010628b:	8b 45 08             	mov    0x8(%ebp),%eax
8010628e:	88 10                	mov    %dl,(%eax)
80106290:	8b 45 08             	mov    0x8(%ebp),%eax
80106293:	0f b6 00             	movzbl (%eax),%eax
80106296:	84 c0                	test   %al,%al
80106298:	0f 95 c0             	setne  %al
8010629b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010629f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801062a3:	84 c0                	test   %al,%al
801062a5:	75 cf                	jne    80106276 <strncpy+0xd>
    ;
  while(n-- > 0)
801062a7:	eb 0c                	jmp    801062b5 <strncpy+0x4c>
    *s++ = 0;
801062a9:	8b 45 08             	mov    0x8(%ebp),%eax
801062ac:	c6 00 00             	movb   $0x0,(%eax)
801062af:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801062b3:	eb 01                	jmp    801062b6 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801062b5:	90                   	nop
801062b6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062ba:	0f 9f c0             	setg   %al
801062bd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801062c1:	84 c0                	test   %al,%al
801062c3:	75 e4                	jne    801062a9 <strncpy+0x40>
    *s++ = 0;
  return os;
801062c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801062c8:	c9                   	leave  
801062c9:	c3                   	ret    

801062ca <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801062ca:	55                   	push   %ebp
801062cb:	89 e5                	mov    %esp,%ebp
801062cd:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801062d0:	8b 45 08             	mov    0x8(%ebp),%eax
801062d3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801062d6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062da:	7f 05                	jg     801062e1 <safestrcpy+0x17>
    return os;
801062dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801062df:	eb 35                	jmp    80106316 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801062e1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801062e5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801062e9:	7e 22                	jle    8010630d <safestrcpy+0x43>
801062eb:	8b 45 0c             	mov    0xc(%ebp),%eax
801062ee:	0f b6 10             	movzbl (%eax),%edx
801062f1:	8b 45 08             	mov    0x8(%ebp),%eax
801062f4:	88 10                	mov    %dl,(%eax)
801062f6:	8b 45 08             	mov    0x8(%ebp),%eax
801062f9:	0f b6 00             	movzbl (%eax),%eax
801062fc:	84 c0                	test   %al,%al
801062fe:	0f 95 c0             	setne  %al
80106301:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106305:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106309:	84 c0                	test   %al,%al
8010630b:	75 d4                	jne    801062e1 <safestrcpy+0x17>
    ;
  *s = 0;
8010630d:	8b 45 08             	mov    0x8(%ebp),%eax
80106310:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80106313:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106316:	c9                   	leave  
80106317:	c3                   	ret    

80106318 <strlen>:

int
strlen(const char *s)
{
80106318:	55                   	push   %ebp
80106319:	89 e5                	mov    %esp,%ebp
8010631b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010631e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106325:	eb 04                	jmp    8010632b <strlen+0x13>
80106327:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010632b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010632e:	03 45 08             	add    0x8(%ebp),%eax
80106331:	0f b6 00             	movzbl (%eax),%eax
80106334:	84 c0                	test   %al,%al
80106336:	75 ef                	jne    80106327 <strlen+0xf>
    ;
  return n;
80106338:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010633b:	c9                   	leave  
8010633c:	c3                   	ret    
8010633d:	00 00                	add    %al,(%eax)
	...

80106340 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80106340:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80106344:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80106348:	55                   	push   %ebp
  pushl %ebx
80106349:	53                   	push   %ebx
  pushl %esi
8010634a:	56                   	push   %esi
  pushl %edi
8010634b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010634c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010634e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80106350:	5f                   	pop    %edi
  popl %esi
80106351:	5e                   	pop    %esi
  popl %ebx
80106352:	5b                   	pop    %ebx
  popl %ebp
80106353:	5d                   	pop    %ebp
  ret
80106354:	c3                   	ret    
80106355:	00 00                	add    %al,(%eax)
	...

80106358 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80106358:	55                   	push   %ebp
80106359:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010635b:	8b 45 08             	mov    0x8(%ebp),%eax
8010635e:	8b 00                	mov    (%eax),%eax
80106360:	3b 45 0c             	cmp    0xc(%ebp),%eax
80106363:	76 0f                	jbe    80106374 <fetchint+0x1c>
80106365:	8b 45 0c             	mov    0xc(%ebp),%eax
80106368:	8d 50 04             	lea    0x4(%eax),%edx
8010636b:	8b 45 08             	mov    0x8(%ebp),%eax
8010636e:	8b 00                	mov    (%eax),%eax
80106370:	39 c2                	cmp    %eax,%edx
80106372:	76 07                	jbe    8010637b <fetchint+0x23>
    return -1;
80106374:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106379:	eb 0f                	jmp    8010638a <fetchint+0x32>
  *ip = *(int*)(addr);
8010637b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010637e:	8b 10                	mov    (%eax),%edx
80106380:	8b 45 10             	mov    0x10(%ebp),%eax
80106383:	89 10                	mov    %edx,(%eax)
  return 0;
80106385:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010638a:	5d                   	pop    %ebp
8010638b:	c3                   	ret    

8010638c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010638c:	55                   	push   %ebp
8010638d:	89 e5                	mov    %esp,%ebp
8010638f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80106392:	8b 45 08             	mov    0x8(%ebp),%eax
80106395:	8b 00                	mov    (%eax),%eax
80106397:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010639a:	77 07                	ja     801063a3 <fetchstr+0x17>
    return -1;
8010639c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063a1:	eb 45                	jmp    801063e8 <fetchstr+0x5c>
  *pp = (char*)addr;
801063a3:	8b 55 0c             	mov    0xc(%ebp),%edx
801063a6:	8b 45 10             	mov    0x10(%ebp),%eax
801063a9:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
801063ab:	8b 45 08             	mov    0x8(%ebp),%eax
801063ae:	8b 00                	mov    (%eax),%eax
801063b0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801063b3:	8b 45 10             	mov    0x10(%ebp),%eax
801063b6:	8b 00                	mov    (%eax),%eax
801063b8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801063bb:	eb 1e                	jmp    801063db <fetchstr+0x4f>
    if(*s == 0)
801063bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063c0:	0f b6 00             	movzbl (%eax),%eax
801063c3:	84 c0                	test   %al,%al
801063c5:	75 10                	jne    801063d7 <fetchstr+0x4b>
      return s - *pp;
801063c7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801063ca:	8b 45 10             	mov    0x10(%ebp),%eax
801063cd:	8b 00                	mov    (%eax),%eax
801063cf:	89 d1                	mov    %edx,%ecx
801063d1:	29 c1                	sub    %eax,%ecx
801063d3:	89 c8                	mov    %ecx,%eax
801063d5:	eb 11                	jmp    801063e8 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801063d7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801063db:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063de:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801063e1:	72 da                	jb     801063bd <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801063e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801063e8:	c9                   	leave  
801063e9:	c3                   	ret    

801063ea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801063ea:	55                   	push   %ebp
801063eb:	89 e5                	mov    %esp,%ebp
801063ed:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801063f0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063f6:	8b 40 18             	mov    0x18(%eax),%eax
801063f9:	8b 50 44             	mov    0x44(%eax),%edx
801063fc:	8b 45 08             	mov    0x8(%ebp),%eax
801063ff:	c1 e0 02             	shl    $0x2,%eax
80106402:	01 d0                	add    %edx,%eax
80106404:	8d 48 04             	lea    0x4(%eax),%ecx
80106407:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010640d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106410:	89 54 24 08          	mov    %edx,0x8(%esp)
80106414:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106418:	89 04 24             	mov    %eax,(%esp)
8010641b:	e8 38 ff ff ff       	call   80106358 <fetchint>
}
80106420:	c9                   	leave  
80106421:	c3                   	ret    

80106422 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80106422:	55                   	push   %ebp
80106423:	89 e5                	mov    %esp,%ebp
80106425:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106428:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010642b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010642f:	8b 45 08             	mov    0x8(%ebp),%eax
80106432:	89 04 24             	mov    %eax,(%esp)
80106435:	e8 b0 ff ff ff       	call   801063ea <argint>
8010643a:	85 c0                	test   %eax,%eax
8010643c:	79 07                	jns    80106445 <argptr+0x23>
    return -1;
8010643e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106443:	eb 3d                	jmp    80106482 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106445:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106448:	89 c2                	mov    %eax,%edx
8010644a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106450:	8b 00                	mov    (%eax),%eax
80106452:	39 c2                	cmp    %eax,%edx
80106454:	73 16                	jae    8010646c <argptr+0x4a>
80106456:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106459:	89 c2                	mov    %eax,%edx
8010645b:	8b 45 10             	mov    0x10(%ebp),%eax
8010645e:	01 c2                	add    %eax,%edx
80106460:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106466:	8b 00                	mov    (%eax),%eax
80106468:	39 c2                	cmp    %eax,%edx
8010646a:	76 07                	jbe    80106473 <argptr+0x51>
    return -1;
8010646c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106471:	eb 0f                	jmp    80106482 <argptr+0x60>
  *pp = (char*)i;
80106473:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106476:	89 c2                	mov    %eax,%edx
80106478:	8b 45 0c             	mov    0xc(%ebp),%eax
8010647b:	89 10                	mov    %edx,(%eax)
  return 0;
8010647d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106482:	c9                   	leave  
80106483:	c3                   	ret    

80106484 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106484:	55                   	push   %ebp
80106485:	89 e5                	mov    %esp,%ebp
80106487:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010648a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010648d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106491:	8b 45 08             	mov    0x8(%ebp),%eax
80106494:	89 04 24             	mov    %eax,(%esp)
80106497:	e8 4e ff ff ff       	call   801063ea <argint>
8010649c:	85 c0                	test   %eax,%eax
8010649e:	79 07                	jns    801064a7 <argstr+0x23>
    return -1;
801064a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a5:	eb 1e                	jmp    801064c5 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801064a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801064aa:	89 c2                	mov    %eax,%edx
801064ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801064b5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801064b9:	89 54 24 04          	mov    %edx,0x4(%esp)
801064bd:	89 04 24             	mov    %eax,(%esp)
801064c0:	e8 c7 fe ff ff       	call   8010638c <fetchstr>
}
801064c5:	c9                   	leave  
801064c6:	c3                   	ret    

801064c7 <syscall>:
[SYS_getBlkRef]  sys_getBlkRef,
};

void
syscall(void)
{
801064c7:	55                   	push   %ebp
801064c8:	89 e5                	mov    %esp,%ebp
801064ca:	53                   	push   %ebx
801064cb:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801064ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d4:	8b 40 18             	mov    0x18(%eax),%eax
801064d7:	8b 40 1c             	mov    0x1c(%eax),%eax
801064da:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801064dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801064e1:	78 2e                	js     80106511 <syscall+0x4a>
801064e3:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801064e7:	7f 28                	jg     80106511 <syscall+0x4a>
801064e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ec:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801064f3:	85 c0                	test   %eax,%eax
801064f5:	74 1a                	je     80106511 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801064f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064fd:	8b 58 18             	mov    0x18(%eax),%ebx
80106500:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106503:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010650a:	ff d0                	call   *%eax
8010650c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010650f:	eb 73                	jmp    80106584 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80106511:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106515:	7e 30                	jle    80106547 <syscall+0x80>
80106517:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010651a:	83 f8 1a             	cmp    $0x1a,%eax
8010651d:	77 28                	ja     80106547 <syscall+0x80>
8010651f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106522:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106529:	85 c0                	test   %eax,%eax
8010652b:	74 1a                	je     80106547 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
8010652d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106533:	8b 58 18             	mov    0x18(%eax),%ebx
80106536:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106539:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106540:	ff d0                	call   *%eax
80106542:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106545:	eb 3d                	jmp    80106584 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106547:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010654d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106550:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106556:	8b 40 10             	mov    0x10(%eax),%eax
80106559:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010655c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106560:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106564:	89 44 24 04          	mov    %eax,0x4(%esp)
80106568:	c7 04 24 c7 9a 10 80 	movl   $0x80109ac7,(%esp)
8010656f:	e8 2d 9e ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106574:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010657a:	8b 40 18             	mov    0x18(%eax),%eax
8010657d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106584:	83 c4 24             	add    $0x24,%esp
80106587:	5b                   	pop    %ebx
80106588:	5d                   	pop    %ebp
80106589:	c3                   	ret    
	...

8010658c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010658c:	55                   	push   %ebp
8010658d:	89 e5                	mov    %esp,%ebp
8010658f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106592:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106595:	89 44 24 04          	mov    %eax,0x4(%esp)
80106599:	8b 45 08             	mov    0x8(%ebp),%eax
8010659c:	89 04 24             	mov    %eax,(%esp)
8010659f:	e8 46 fe ff ff       	call   801063ea <argint>
801065a4:	85 c0                	test   %eax,%eax
801065a6:	79 07                	jns    801065af <argfd+0x23>
    return -1;
801065a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065ad:	eb 50                	jmp    801065ff <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801065af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b2:	85 c0                	test   %eax,%eax
801065b4:	78 21                	js     801065d7 <argfd+0x4b>
801065b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065b9:	83 f8 0f             	cmp    $0xf,%eax
801065bc:	7f 19                	jg     801065d7 <argfd+0x4b>
801065be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065c7:	83 c2 08             	add    $0x8,%edx
801065ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801065ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065d5:	75 07                	jne    801065de <argfd+0x52>
    return -1;
801065d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065dc:	eb 21                	jmp    801065ff <argfd+0x73>
  if(pfd)
801065de:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801065e2:	74 08                	je     801065ec <argfd+0x60>
    *pfd = fd;
801065e4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801065e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801065ea:	89 10                	mov    %edx,(%eax)
  if(pf)
801065ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801065f0:	74 08                	je     801065fa <argfd+0x6e>
    *pf = f;
801065f2:	8b 45 10             	mov    0x10(%ebp),%eax
801065f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801065f8:	89 10                	mov    %edx,(%eax)
  return 0;
801065fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065ff:	c9                   	leave  
80106600:	c3                   	ret    

80106601 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106601:	55                   	push   %ebp
80106602:	89 e5                	mov    %esp,%ebp
80106604:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106607:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010660e:	eb 30                	jmp    80106640 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106610:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106616:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106619:	83 c2 08             	add    $0x8,%edx
8010661c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106620:	85 c0                	test   %eax,%eax
80106622:	75 18                	jne    8010663c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106624:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010662a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010662d:	8d 4a 08             	lea    0x8(%edx),%ecx
80106630:	8b 55 08             	mov    0x8(%ebp),%edx
80106633:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106637:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010663a:	eb 0f                	jmp    8010664b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010663c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106640:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106644:	7e ca                	jle    80106610 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106646:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010664b:	c9                   	leave  
8010664c:	c3                   	ret    

8010664d <sys_dup>:

int
sys_dup(void)
{
8010664d:	55                   	push   %ebp
8010664e:	89 e5                	mov    %esp,%ebp
80106650:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106653:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106656:	89 44 24 08          	mov    %eax,0x8(%esp)
8010665a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106661:	00 
80106662:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106669:	e8 1e ff ff ff       	call   8010658c <argfd>
8010666e:	85 c0                	test   %eax,%eax
80106670:	79 07                	jns    80106679 <sys_dup+0x2c>
    return -1;
80106672:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106677:	eb 29                	jmp    801066a2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106679:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010667c:	89 04 24             	mov    %eax,(%esp)
8010667f:	e8 7d ff ff ff       	call   80106601 <fdalloc>
80106684:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106687:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010668b:	79 07                	jns    80106694 <sys_dup+0x47>
    return -1;
8010668d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106692:	eb 0e                	jmp    801066a2 <sys_dup+0x55>
  filedup(f);
80106694:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106697:	89 04 24             	mov    %eax,(%esp)
8010669a:	e8 dd a8 ff ff       	call   80100f7c <filedup>
  return fd;
8010669f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801066a2:	c9                   	leave  
801066a3:	c3                   	ret    

801066a4 <sys_read>:

int
sys_read(void)
{
801066a4:	55                   	push   %ebp
801066a5:	89 e5                	mov    %esp,%ebp
801066a7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801066aa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801066ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801066b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801066b8:	00 
801066b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801066c0:	e8 c7 fe ff ff       	call   8010658c <argfd>
801066c5:	85 c0                	test   %eax,%eax
801066c7:	78 35                	js     801066fe <sys_read+0x5a>
801066c9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801066d0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801066d7:	e8 0e fd ff ff       	call   801063ea <argint>
801066dc:	85 c0                	test   %eax,%eax
801066de:	78 1e                	js     801066fe <sys_read+0x5a>
801066e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066e3:	89 44 24 08          	mov    %eax,0x8(%esp)
801066e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801066ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066f5:	e8 28 fd ff ff       	call   80106422 <argptr>
801066fa:	85 c0                	test   %eax,%eax
801066fc:	79 07                	jns    80106705 <sys_read+0x61>
    return -1;
801066fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106703:	eb 19                	jmp    8010671e <sys_read+0x7a>
  return fileread(f, p, n);
80106705:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106708:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010670b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010670e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106712:	89 54 24 04          	mov    %edx,0x4(%esp)
80106716:	89 04 24             	mov    %eax,(%esp)
80106719:	e8 cb a9 ff ff       	call   801010e9 <fileread>
}
8010671e:	c9                   	leave  
8010671f:	c3                   	ret    

80106720 <sys_write>:

int
sys_write(void)
{
80106720:	55                   	push   %ebp
80106721:	89 e5                	mov    %esp,%ebp
80106723:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106726:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106729:	89 44 24 08          	mov    %eax,0x8(%esp)
8010672d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106734:	00 
80106735:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010673c:	e8 4b fe ff ff       	call   8010658c <argfd>
80106741:	85 c0                	test   %eax,%eax
80106743:	78 35                	js     8010677a <sys_write+0x5a>
80106745:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106748:	89 44 24 04          	mov    %eax,0x4(%esp)
8010674c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106753:	e8 92 fc ff ff       	call   801063ea <argint>
80106758:	85 c0                	test   %eax,%eax
8010675a:	78 1e                	js     8010677a <sys_write+0x5a>
8010675c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010675f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106763:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106766:	89 44 24 04          	mov    %eax,0x4(%esp)
8010676a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106771:	e8 ac fc ff ff       	call   80106422 <argptr>
80106776:	85 c0                	test   %eax,%eax
80106778:	79 07                	jns    80106781 <sys_write+0x61>
    return -1;
8010677a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010677f:	eb 19                	jmp    8010679a <sys_write+0x7a>
  return filewrite(f, p, n);
80106781:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106784:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106787:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010678a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010678e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106792:	89 04 24             	mov    %eax,(%esp)
80106795:	e8 0b aa ff ff       	call   801011a5 <filewrite>
}
8010679a:	c9                   	leave  
8010679b:	c3                   	ret    

8010679c <sys_close>:

int
sys_close(void)
{
8010679c:	55                   	push   %ebp
8010679d:	89 e5                	mov    %esp,%ebp
8010679f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801067a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801067a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801067a9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801067b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067b7:	e8 d0 fd ff ff       	call   8010658c <argfd>
801067bc:	85 c0                	test   %eax,%eax
801067be:	79 07                	jns    801067c7 <sys_close+0x2b>
    return -1;
801067c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067c5:	eb 24                	jmp    801067eb <sys_close+0x4f>
  proc->ofile[fd] = 0;
801067c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801067d0:	83 c2 08             	add    $0x8,%edx
801067d3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801067da:	00 
  fileclose(f);
801067db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067de:	89 04 24             	mov    %eax,(%esp)
801067e1:	e8 de a7 ff ff       	call   80100fc4 <fileclose>
  return 0;
801067e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067eb:	c9                   	leave  
801067ec:	c3                   	ret    

801067ed <sys_fstat>:

int
sys_fstat(void)
{
801067ed:	55                   	push   %ebp
801067ee:	89 e5                	mov    %esp,%ebp
801067f0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801067f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801067fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106801:	00 
80106802:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106809:	e8 7e fd ff ff       	call   8010658c <argfd>
8010680e:	85 c0                	test   %eax,%eax
80106810:	78 1f                	js     80106831 <sys_fstat+0x44>
80106812:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106819:	00 
8010681a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010681d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106821:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106828:	e8 f5 fb ff ff       	call   80106422 <argptr>
8010682d:	85 c0                	test   %eax,%eax
8010682f:	79 07                	jns    80106838 <sys_fstat+0x4b>
    return -1;
80106831:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106836:	eb 12                	jmp    8010684a <sys_fstat+0x5d>
  return filestat(f, st);
80106838:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010683b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010683e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106842:	89 04 24             	mov    %eax,(%esp)
80106845:	e8 50 a8 ff ff       	call   8010109a <filestat>
}
8010684a:	c9                   	leave  
8010684b:	c3                   	ret    

8010684c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010684c:	55                   	push   %ebp
8010684d:	89 e5                	mov    %esp,%ebp
8010684f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106852:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106855:	89 44 24 04          	mov    %eax,0x4(%esp)
80106859:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106860:	e8 1f fc ff ff       	call   80106484 <argstr>
80106865:	85 c0                	test   %eax,%eax
80106867:	78 17                	js     80106880 <sys_link+0x34>
80106869:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010686c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106870:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106877:	e8 08 fc ff ff       	call   80106484 <argstr>
8010687c:	85 c0                	test   %eax,%eax
8010687e:	79 0a                	jns    8010688a <sys_link+0x3e>
    return -1;
80106880:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106885:	e9 3c 01 00 00       	jmp    801069c6 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010688a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010688d:	89 04 24             	mov    %eax,(%esp)
80106890:	e8 93 ca ff ff       	call   80103328 <namei>
80106895:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106898:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010689c:	75 0a                	jne    801068a8 <sys_link+0x5c>
    return -1;
8010689e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068a3:	e9 1e 01 00 00       	jmp    801069c6 <sys_link+0x17a>

  begin_trans();
801068a8:	e8 18 dc ff ff       	call   801044c5 <begin_trans>

  ilock(ip);
801068ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b0:	89 04 24             	mov    %eax,(%esp)
801068b3:	e8 e0 bd ff ff       	call   80102698 <ilock>
  if(ip->type == T_DIR){
801068b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068bb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068bf:	66 83 f8 01          	cmp    $0x1,%ax
801068c3:	75 1a                	jne    801068df <sys_link+0x93>
    iunlockput(ip);
801068c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c8:	89 04 24             	mov    %eax,(%esp)
801068cb:	e8 4c c0 ff ff       	call   8010291c <iunlockput>
    commit_trans();
801068d0:	e8 39 dc ff ff       	call   8010450e <commit_trans>
    return -1;
801068d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801068da:	e9 e7 00 00 00       	jmp    801069c6 <sys_link+0x17a>
  }

  ip->nlink++;
801068df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068e6:	8d 50 01             	lea    0x1(%eax),%edx
801068e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ec:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801068f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f3:	89 04 24             	mov    %eax,(%esp)
801068f6:	e8 e1 bb ff ff       	call   801024dc <iupdate>
  iunlock(ip);
801068fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068fe:	89 04 24             	mov    %eax,(%esp)
80106901:	e8 e0 be ff ff       	call   801027e6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106906:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106909:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010690c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106910:	89 04 24             	mov    %eax,(%esp)
80106913:	e8 32 ca ff ff       	call   8010334a <nameiparent>
80106918:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010691b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010691f:	74 68                	je     80106989 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106921:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106924:	89 04 24             	mov    %eax,(%esp)
80106927:	e8 6c bd ff ff       	call   80102698 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010692c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010692f:	8b 10                	mov    (%eax),%edx
80106931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106934:	8b 00                	mov    (%eax),%eax
80106936:	39 c2                	cmp    %eax,%edx
80106938:	75 20                	jne    8010695a <sys_link+0x10e>
8010693a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010693d:	8b 40 04             	mov    0x4(%eax),%eax
80106940:	89 44 24 08          	mov    %eax,0x8(%esp)
80106944:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106947:	89 44 24 04          	mov    %eax,0x4(%esp)
8010694b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010694e:	89 04 24             	mov    %eax,(%esp)
80106951:	e8 11 c7 ff ff       	call   80103067 <dirlink>
80106956:	85 c0                	test   %eax,%eax
80106958:	79 0d                	jns    80106967 <sys_link+0x11b>
    iunlockput(dp);
8010695a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010695d:	89 04 24             	mov    %eax,(%esp)
80106960:	e8 b7 bf ff ff       	call   8010291c <iunlockput>
    goto bad;
80106965:	eb 23                	jmp    8010698a <sys_link+0x13e>
  }
  iunlockput(dp);
80106967:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010696a:	89 04 24             	mov    %eax,(%esp)
8010696d:	e8 aa bf ff ff       	call   8010291c <iunlockput>
  iput(ip);
80106972:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106975:	89 04 24             	mov    %eax,(%esp)
80106978:	e8 ce be ff ff       	call   8010284b <iput>

  commit_trans();
8010697d:	e8 8c db ff ff       	call   8010450e <commit_trans>

  return 0;
80106982:	b8 00 00 00 00       	mov    $0x0,%eax
80106987:	eb 3d                	jmp    801069c6 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106989:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010698a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010698d:	89 04 24             	mov    %eax,(%esp)
80106990:	e8 03 bd ff ff       	call   80102698 <ilock>
  ip->nlink--;
80106995:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106998:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010699c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010699f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801069a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a9:	89 04 24             	mov    %eax,(%esp)
801069ac:	e8 2b bb ff ff       	call   801024dc <iupdate>
  iunlockput(ip);
801069b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b4:	89 04 24             	mov    %eax,(%esp)
801069b7:	e8 60 bf ff ff       	call   8010291c <iunlockput>
  commit_trans();
801069bc:	e8 4d db ff ff       	call   8010450e <commit_trans>
  return -1;
801069c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801069c6:	c9                   	leave  
801069c7:	c3                   	ret    

801069c8 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801069c8:	55                   	push   %ebp
801069c9:	89 e5                	mov    %esp,%ebp
801069cb:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801069ce:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801069d5:	eb 4b                	jmp    80106a22 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801069d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069da:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801069e1:	00 
801069e2:	89 44 24 08          	mov    %eax,0x8(%esp)
801069e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801069e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801069ed:	8b 45 08             	mov    0x8(%ebp),%eax
801069f0:	89 04 24             	mov    %eax,(%esp)
801069f3:	e8 06 c2 ff ff       	call   80102bfe <readi>
801069f8:	83 f8 10             	cmp    $0x10,%eax
801069fb:	74 0c                	je     80106a09 <isdirempty+0x41>
      panic("isdirempty: readi");
801069fd:	c7 04 24 e3 9a 10 80 	movl   $0x80109ae3,(%esp)
80106a04:	e8 34 9b ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106a09:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106a0d:	66 85 c0             	test   %ax,%ax
80106a10:	74 07                	je     80106a19 <isdirempty+0x51>
      return 0;
80106a12:	b8 00 00 00 00       	mov    $0x0,%eax
80106a17:	eb 1b                	jmp    80106a34 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106a19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a1c:	83 c0 10             	add    $0x10,%eax
80106a1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a22:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106a25:	8b 45 08             	mov    0x8(%ebp),%eax
80106a28:	8b 40 18             	mov    0x18(%eax),%eax
80106a2b:	39 c2                	cmp    %eax,%edx
80106a2d:	72 a8                	jb     801069d7 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80106a2f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106a34:	c9                   	leave  
80106a35:	c3                   	ret    

80106a36 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106a36:	55                   	push   %ebp
80106a37:	89 e5                	mov    %esp,%ebp
80106a39:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106a3c:	8d 45 cc             	lea    -0x34(%ebp),%eax
80106a3f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a43:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106a4a:	e8 35 fa ff ff       	call   80106484 <argstr>
80106a4f:	85 c0                	test   %eax,%eax
80106a51:	79 0a                	jns    80106a5d <sys_unlink+0x27>
    return -1;
80106a53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a58:	e9 aa 01 00 00       	jmp    80106c07 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80106a5d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106a60:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106a63:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a67:	89 04 24             	mov    %eax,(%esp)
80106a6a:	e8 db c8 ff ff       	call   8010334a <nameiparent>
80106a6f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a72:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a76:	75 0a                	jne    80106a82 <sys_unlink+0x4c>
    return -1;
80106a78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106a7d:	e9 85 01 00 00       	jmp    80106c07 <sys_unlink+0x1d1>

  begin_trans();
80106a82:	e8 3e da ff ff       	call   801044c5 <begin_trans>

  ilock(dp);
80106a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8a:	89 04 24             	mov    %eax,(%esp)
80106a8d:	e8 06 bc ff ff       	call   80102698 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106a92:	c7 44 24 04 f5 9a 10 	movl   $0x80109af5,0x4(%esp)
80106a99:	80 
80106a9a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a9d:	89 04 24             	mov    %eax,(%esp)
80106aa0:	e8 d8 c4 ff ff       	call   80102f7d <namecmp>
80106aa5:	85 c0                	test   %eax,%eax
80106aa7:	0f 84 45 01 00 00    	je     80106bf2 <sys_unlink+0x1bc>
80106aad:	c7 44 24 04 f7 9a 10 	movl   $0x80109af7,0x4(%esp)
80106ab4:	80 
80106ab5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106ab8:	89 04 24             	mov    %eax,(%esp)
80106abb:	e8 bd c4 ff ff       	call   80102f7d <namecmp>
80106ac0:	85 c0                	test   %eax,%eax
80106ac2:	0f 84 2a 01 00 00    	je     80106bf2 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106ac8:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106acb:	89 44 24 08          	mov    %eax,0x8(%esp)
80106acf:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106ad2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad9:	89 04 24             	mov    %eax,(%esp)
80106adc:	e8 be c4 ff ff       	call   80102f9f <dirlookup>
80106ae1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106ae4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106ae8:	0f 84 03 01 00 00    	je     80106bf1 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106aee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106af1:	89 04 24             	mov    %eax,(%esp)
80106af4:	e8 9f bb ff ff       	call   80102698 <ilock>

  if(ip->nlink < 1)
80106af9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106afc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b00:	66 85 c0             	test   %ax,%ax
80106b03:	7f 0c                	jg     80106b11 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106b05:	c7 04 24 fa 9a 10 80 	movl   $0x80109afa,(%esp)
80106b0c:	e8 2c 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106b11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b14:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b18:	66 83 f8 01          	cmp    $0x1,%ax
80106b1c:	75 1f                	jne    80106b3d <sys_unlink+0x107>
80106b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b21:	89 04 24             	mov    %eax,(%esp)
80106b24:	e8 9f fe ff ff       	call   801069c8 <isdirempty>
80106b29:	85 c0                	test   %eax,%eax
80106b2b:	75 10                	jne    80106b3d <sys_unlink+0x107>
    iunlockput(ip);
80106b2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b30:	89 04 24             	mov    %eax,(%esp)
80106b33:	e8 e4 bd ff ff       	call   8010291c <iunlockput>
    goto bad;
80106b38:	e9 b5 00 00 00       	jmp    80106bf2 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106b3d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106b44:	00 
80106b45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b4c:	00 
80106b4d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b50:	89 04 24             	mov    %eax,(%esp)
80106b53:	e8 42 f5 ff ff       	call   8010609a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106b58:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106b5b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106b62:	00 
80106b63:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b67:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106b6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b71:	89 04 24             	mov    %eax,(%esp)
80106b74:	e8 f0 c1 ff ff       	call   80102d69 <writei>
80106b79:	83 f8 10             	cmp    $0x10,%eax
80106b7c:	74 0c                	je     80106b8a <sys_unlink+0x154>
    panic("unlink: writei");
80106b7e:	c7 04 24 0c 9b 10 80 	movl   $0x80109b0c,(%esp)
80106b85:	e8 b3 99 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106b8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b8d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106b91:	66 83 f8 01          	cmp    $0x1,%ax
80106b95:	75 1c                	jne    80106bb3 <sys_unlink+0x17d>
    dp->nlink--;
80106b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b9a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b9e:	8d 50 ff             	lea    -0x1(%eax),%edx
80106ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ba4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bab:	89 04 24             	mov    %eax,(%esp)
80106bae:	e8 29 b9 ff ff       	call   801024dc <iupdate>
  }
  iunlockput(dp);
80106bb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb6:	89 04 24             	mov    %eax,(%esp)
80106bb9:	e8 5e bd ff ff       	call   8010291c <iunlockput>

  ip->nlink--;
80106bbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bc1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106bc5:	8d 50 ff             	lea    -0x1(%eax),%edx
80106bc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bcb:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106bcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bd2:	89 04 24             	mov    %eax,(%esp)
80106bd5:	e8 02 b9 ff ff       	call   801024dc <iupdate>
  iunlockput(ip);
80106bda:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bdd:	89 04 24             	mov    %eax,(%esp)
80106be0:	e8 37 bd ff ff       	call   8010291c <iunlockput>

  commit_trans();
80106be5:	e8 24 d9 ff ff       	call   8010450e <commit_trans>

  return 0;
80106bea:	b8 00 00 00 00       	mov    $0x0,%eax
80106bef:	eb 16                	jmp    80106c07 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106bf1:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106bf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bf5:	89 04 24             	mov    %eax,(%esp)
80106bf8:	e8 1f bd ff ff       	call   8010291c <iunlockput>
  commit_trans();
80106bfd:	e8 0c d9 ff ff       	call   8010450e <commit_trans>
  return -1;
80106c02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106c07:	c9                   	leave  
80106c08:	c3                   	ret    

80106c09 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106c09:	55                   	push   %ebp
80106c0a:	89 e5                	mov    %esp,%ebp
80106c0c:	83 ec 48             	sub    $0x48,%esp
80106c0f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106c12:	8b 55 10             	mov    0x10(%ebp),%edx
80106c15:	8b 45 14             	mov    0x14(%ebp),%eax
80106c18:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106c1c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106c20:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106c24:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c27:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c2b:	8b 45 08             	mov    0x8(%ebp),%eax
80106c2e:	89 04 24             	mov    %eax,(%esp)
80106c31:	e8 14 c7 ff ff       	call   8010334a <nameiparent>
80106c36:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106c39:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106c3d:	75 0a                	jne    80106c49 <create+0x40>
    return 0;
80106c3f:	b8 00 00 00 00       	mov    $0x0,%eax
80106c44:	e9 7e 01 00 00       	jmp    80106dc7 <create+0x1be>
  ilock(dp);
80106c49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c4c:	89 04 24             	mov    %eax,(%esp)
80106c4f:	e8 44 ba ff ff       	call   80102698 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106c54:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106c57:	89 44 24 08          	mov    %eax,0x8(%esp)
80106c5b:	8d 45 de             	lea    -0x22(%ebp),%eax
80106c5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c65:	89 04 24             	mov    %eax,(%esp)
80106c68:	e8 32 c3 ff ff       	call   80102f9f <dirlookup>
80106c6d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c70:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c74:	74 47                	je     80106cbd <create+0xb4>
    iunlockput(dp);
80106c76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c79:	89 04 24             	mov    %eax,(%esp)
80106c7c:	e8 9b bc ff ff       	call   8010291c <iunlockput>
    ilock(ip);
80106c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c84:	89 04 24             	mov    %eax,(%esp)
80106c87:	e8 0c ba ff ff       	call   80102698 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106c8c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106c91:	75 15                	jne    80106ca8 <create+0x9f>
80106c93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c96:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106c9a:	66 83 f8 02          	cmp    $0x2,%ax
80106c9e:	75 08                	jne    80106ca8 <create+0x9f>
      return ip;
80106ca0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca3:	e9 1f 01 00 00       	jmp    80106dc7 <create+0x1be>
    iunlockput(ip);
80106ca8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cab:	89 04 24             	mov    %eax,(%esp)
80106cae:	e8 69 bc ff ff       	call   8010291c <iunlockput>
    return 0;
80106cb3:	b8 00 00 00 00       	mov    $0x0,%eax
80106cb8:	e9 0a 01 00 00       	jmp    80106dc7 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106cbd:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106cc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cc4:	8b 00                	mov    (%eax),%eax
80106cc6:	89 54 24 04          	mov    %edx,0x4(%esp)
80106cca:	89 04 24             	mov    %eax,(%esp)
80106ccd:	e8 2d b7 ff ff       	call   801023ff <ialloc>
80106cd2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106cd5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106cd9:	75 0c                	jne    80106ce7 <create+0xde>
    panic("create: ialloc");
80106cdb:	c7 04 24 1b 9b 10 80 	movl   $0x80109b1b,(%esp)
80106ce2:	e8 56 98 ff ff       	call   8010053d <panic>

  ilock(ip);
80106ce7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cea:	89 04 24             	mov    %eax,(%esp)
80106ced:	e8 a6 b9 ff ff       	call   80102698 <ilock>
  ip->major = major;
80106cf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cf5:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106cf9:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106cfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d00:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106d04:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106d08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d0b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d14:	89 04 24             	mov    %eax,(%esp)
80106d17:	e8 c0 b7 ff ff       	call   801024dc <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106d1c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106d21:	75 6a                	jne    80106d8d <create+0x184>
    dp->nlink++;  // for ".."
80106d23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d26:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106d2a:	8d 50 01             	lea    0x1(%eax),%edx
80106d2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d30:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106d34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d37:	89 04 24             	mov    %eax,(%esp)
80106d3a:	e8 9d b7 ff ff       	call   801024dc <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d42:	8b 40 04             	mov    0x4(%eax),%eax
80106d45:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d49:	c7 44 24 04 f5 9a 10 	movl   $0x80109af5,0x4(%esp)
80106d50:	80 
80106d51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d54:	89 04 24             	mov    %eax,(%esp)
80106d57:	e8 0b c3 ff ff       	call   80103067 <dirlink>
80106d5c:	85 c0                	test   %eax,%eax
80106d5e:	78 21                	js     80106d81 <create+0x178>
80106d60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d63:	8b 40 04             	mov    0x4(%eax),%eax
80106d66:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d6a:	c7 44 24 04 f7 9a 10 	movl   $0x80109af7,0x4(%esp)
80106d71:	80 
80106d72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d75:	89 04 24             	mov    %eax,(%esp)
80106d78:	e8 ea c2 ff ff       	call   80103067 <dirlink>
80106d7d:	85 c0                	test   %eax,%eax
80106d7f:	79 0c                	jns    80106d8d <create+0x184>
      panic("create dots");
80106d81:	c7 04 24 2a 9b 10 80 	movl   $0x80109b2a,(%esp)
80106d88:	e8 b0 97 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106d8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d90:	8b 40 04             	mov    0x4(%eax),%eax
80106d93:	89 44 24 08          	mov    %eax,0x8(%esp)
80106d97:	8d 45 de             	lea    -0x22(%ebp),%eax
80106d9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106da1:	89 04 24             	mov    %eax,(%esp)
80106da4:	e8 be c2 ff ff       	call   80103067 <dirlink>
80106da9:	85 c0                	test   %eax,%eax
80106dab:	79 0c                	jns    80106db9 <create+0x1b0>
    panic("create: dirlink");
80106dad:	c7 04 24 36 9b 10 80 	movl   $0x80109b36,(%esp)
80106db4:	e8 84 97 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dbc:	89 04 24             	mov    %eax,(%esp)
80106dbf:	e8 58 bb ff ff       	call   8010291c <iunlockput>

  return ip;
80106dc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106dc7:	c9                   	leave  
80106dc8:	c3                   	ret    

80106dc9 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80106dc9:	55                   	push   %ebp
80106dca:	89 e5                	mov    %esp,%ebp
80106dcc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80106dd2:	25 00 02 00 00       	and    $0x200,%eax
80106dd7:	85 c0                	test   %eax,%eax
80106dd9:	74 40                	je     80106e1b <fileopen+0x52>
    begin_trans();
80106ddb:	e8 e5 d6 ff ff       	call   801044c5 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106de0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106de7:	00 
80106de8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106def:	00 
80106df0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106df7:	00 
80106df8:	8b 45 08             	mov    0x8(%ebp),%eax
80106dfb:	89 04 24             	mov    %eax,(%esp)
80106dfe:	e8 06 fe ff ff       	call   80106c09 <create>
80106e03:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106e06:	e8 03 d7 ff ff       	call   8010450e <commit_trans>
    if(ip == 0)
80106e0b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e0f:	75 5b                	jne    80106e6c <fileopen+0xa3>
      return 0;
80106e11:	b8 00 00 00 00       	mov    $0x0,%eax
80106e16:	e9 e5 00 00 00       	jmp    80106f00 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106e1b:	8b 45 08             	mov    0x8(%ebp),%eax
80106e1e:	89 04 24             	mov    %eax,(%esp)
80106e21:	e8 02 c5 ff ff       	call   80103328 <namei>
80106e26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106e29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e2d:	75 0a                	jne    80106e39 <fileopen+0x70>
      return 0;
80106e2f:	b8 00 00 00 00       	mov    $0x0,%eax
80106e34:	e9 c7 00 00 00       	jmp    80106f00 <fileopen+0x137>
    ilock(ip);
80106e39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e3c:	89 04 24             	mov    %eax,(%esp)
80106e3f:	e8 54 b8 ff ff       	call   80102698 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106e44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e47:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e4b:	66 83 f8 01          	cmp    $0x1,%ax
80106e4f:	75 1b                	jne    80106e6c <fileopen+0xa3>
80106e51:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106e55:	74 15                	je     80106e6c <fileopen+0xa3>
      iunlockput(ip);
80106e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e5a:	89 04 24             	mov    %eax,(%esp)
80106e5d:	e8 ba ba ff ff       	call   8010291c <iunlockput>
      return 0;
80106e62:	b8 00 00 00 00       	mov    $0x0,%eax
80106e67:	e9 94 00 00 00       	jmp    80106f00 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106e6c:	e8 ab a0 ff ff       	call   80100f1c <filealloc>
80106e71:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106e74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e78:	75 23                	jne    80106e9d <fileopen+0xd4>
    if(f)
80106e7a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106e7e:	74 0b                	je     80106e8b <fileopen+0xc2>
      fileclose(f);
80106e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e83:	89 04 24             	mov    %eax,(%esp)
80106e86:	e8 39 a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106e8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e8e:	89 04 24             	mov    %eax,(%esp)
80106e91:	e8 86 ba ff ff       	call   8010291c <iunlockput>
    return 0;
80106e96:	b8 00 00 00 00       	mov    $0x0,%eax
80106e9b:	eb 63                	jmp    80106f00 <fileopen+0x137>
  }
  iunlock(ip);
80106e9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ea0:	89 04 24             	mov    %eax,(%esp)
80106ea3:	e8 3e b9 ff ff       	call   801027e6 <iunlock>

  f->type = FD_INODE;
80106ea8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eab:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106eb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106eb4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106eb7:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106eba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ebd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ec7:	83 e0 01             	and    $0x1,%eax
80106eca:	85 c0                	test   %eax,%eax
80106ecc:	0f 94 c2             	sete   %dl
80106ecf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ed2:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106ed5:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ed8:	83 e0 01             	and    $0x1,%eax
80106edb:	84 c0                	test   %al,%al
80106edd:	75 0a                	jne    80106ee9 <fileopen+0x120>
80106edf:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ee2:	83 e0 02             	and    $0x2,%eax
80106ee5:	85 c0                	test   %eax,%eax
80106ee7:	74 07                	je     80106ef0 <fileopen+0x127>
80106ee9:	b8 01 00 00 00       	mov    $0x1,%eax
80106eee:	eb 05                	jmp    80106ef5 <fileopen+0x12c>
80106ef0:	b8 00 00 00 00       	mov    $0x0,%eax
80106ef5:	89 c2                	mov    %eax,%edx
80106ef7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106efa:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106efd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106f00:	c9                   	leave  
80106f01:	c3                   	ret    

80106f02 <sys_open>:

int
sys_open(void)
{
80106f02:	55                   	push   %ebp
80106f03:	89 e5                	mov    %esp,%ebp
80106f05:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106f08:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f0f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f16:	e8 69 f5 ff ff       	call   80106484 <argstr>
80106f1b:	85 c0                	test   %eax,%eax
80106f1d:	78 17                	js     80106f36 <sys_open+0x34>
80106f1f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f22:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106f2d:	e8 b8 f4 ff ff       	call   801063ea <argint>
80106f32:	85 c0                	test   %eax,%eax
80106f34:	79 0a                	jns    80106f40 <sys_open+0x3e>
    return -1;
80106f36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f3b:	e9 46 01 00 00       	jmp    80107086 <sys_open+0x184>
  if(omode & O_CREATE){
80106f40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f43:	25 00 02 00 00       	and    $0x200,%eax
80106f48:	85 c0                	test   %eax,%eax
80106f4a:	74 40                	je     80106f8c <sys_open+0x8a>
    begin_trans();
80106f4c:	e8 74 d5 ff ff       	call   801044c5 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106f51:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f54:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106f5b:	00 
80106f5c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106f63:	00 
80106f64:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106f6b:	00 
80106f6c:	89 04 24             	mov    %eax,(%esp)
80106f6f:	e8 95 fc ff ff       	call   80106c09 <create>
80106f74:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106f77:	e8 92 d5 ff ff       	call   8010450e <commit_trans>
    if(ip == 0)
80106f7c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f80:	75 5c                	jne    80106fde <sys_open+0xdc>
      return -1;
80106f82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f87:	e9 fa 00 00 00       	jmp    80107086 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106f8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106f8f:	89 04 24             	mov    %eax,(%esp)
80106f92:	e8 91 c3 ff ff       	call   80103328 <namei>
80106f97:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106f9a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106f9e:	75 0a                	jne    80106faa <sys_open+0xa8>
      return -1;
80106fa0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fa5:	e9 dc 00 00 00       	jmp    80107086 <sys_open+0x184>
    ilock(ip);
80106faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fad:	89 04 24             	mov    %eax,(%esp)
80106fb0:	e8 e3 b6 ff ff       	call   80102698 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fb8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106fbc:	66 83 f8 01          	cmp    $0x1,%ax
80106fc0:	75 1c                	jne    80106fde <sys_open+0xdc>
80106fc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fc5:	85 c0                	test   %eax,%eax
80106fc7:	74 15                	je     80106fde <sys_open+0xdc>
      iunlockput(ip);
80106fc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106fcc:	89 04 24             	mov    %eax,(%esp)
80106fcf:	e8 48 b9 ff ff       	call   8010291c <iunlockput>
      return -1;
80106fd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fd9:	e9 a8 00 00 00       	jmp    80107086 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106fde:	e8 39 9f ff ff       	call   80100f1c <filealloc>
80106fe3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106fe6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fea:	74 14                	je     80107000 <sys_open+0xfe>
80106fec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fef:	89 04 24             	mov    %eax,(%esp)
80106ff2:	e8 0a f6 ff ff       	call   80106601 <fdalloc>
80106ff7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106ffa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106ffe:	79 23                	jns    80107023 <sys_open+0x121>
    if(f)
80107000:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107004:	74 0b                	je     80107011 <sys_open+0x10f>
      fileclose(f);
80107006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107009:	89 04 24             	mov    %eax,(%esp)
8010700c:	e8 b3 9f ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80107011:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107014:	89 04 24             	mov    %eax,(%esp)
80107017:	e8 00 b9 ff ff       	call   8010291c <iunlockput>
    return -1;
8010701c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107021:	eb 63                	jmp    80107086 <sys_open+0x184>
  }
  iunlock(ip);
80107023:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107026:	89 04 24             	mov    %eax,(%esp)
80107029:	e8 b8 b7 ff ff       	call   801027e6 <iunlock>

  f->type = FD_INODE;
8010702e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107031:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80107037:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010703a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010703d:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80107040:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107043:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010704a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010704d:	83 e0 01             	and    $0x1,%eax
80107050:	85 c0                	test   %eax,%eax
80107052:	0f 94 c2             	sete   %dl
80107055:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107058:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010705b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010705e:	83 e0 01             	and    $0x1,%eax
80107061:	84 c0                	test   %al,%al
80107063:	75 0a                	jne    8010706f <sys_open+0x16d>
80107065:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107068:	83 e0 02             	and    $0x2,%eax
8010706b:	85 c0                	test   %eax,%eax
8010706d:	74 07                	je     80107076 <sys_open+0x174>
8010706f:	b8 01 00 00 00       	mov    $0x1,%eax
80107074:	eb 05                	jmp    8010707b <sys_open+0x179>
80107076:	b8 00 00 00 00       	mov    $0x0,%eax
8010707b:	89 c2                	mov    %eax,%edx
8010707d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107080:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80107083:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80107086:	c9                   	leave  
80107087:	c3                   	ret    

80107088 <sys_mkdir>:

int
sys_mkdir(void)
{
80107088:	55                   	push   %ebp
80107089:	89 e5                	mov    %esp,%ebp
8010708b:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
8010708e:	e8 32 d4 ff ff       	call   801044c5 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80107093:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107096:	89 44 24 04          	mov    %eax,0x4(%esp)
8010709a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070a1:	e8 de f3 ff ff       	call   80106484 <argstr>
801070a6:	85 c0                	test   %eax,%eax
801070a8:	78 2c                	js     801070d6 <sys_mkdir+0x4e>
801070aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070ad:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801070b4:	00 
801070b5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801070bc:	00 
801070bd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801070c4:	00 
801070c5:	89 04 24             	mov    %eax,(%esp)
801070c8:	e8 3c fb ff ff       	call   80106c09 <create>
801070cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801070d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801070d4:	75 0c                	jne    801070e2 <sys_mkdir+0x5a>
    commit_trans();
801070d6:	e8 33 d4 ff ff       	call   8010450e <commit_trans>
    return -1;
801070db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070e0:	eb 15                	jmp    801070f7 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801070e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801070e5:	89 04 24             	mov    %eax,(%esp)
801070e8:	e8 2f b8 ff ff       	call   8010291c <iunlockput>
  commit_trans();
801070ed:	e8 1c d4 ff ff       	call   8010450e <commit_trans>
  return 0;
801070f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070f7:	c9                   	leave  
801070f8:	c3                   	ret    

801070f9 <sys_mknod>:

int
sys_mknod(void)
{
801070f9:	55                   	push   %ebp
801070fa:	89 e5                	mov    %esp,%ebp
801070fc:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801070ff:	e8 c1 d3 ff ff       	call   801044c5 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80107104:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107107:	89 44 24 04          	mov    %eax,0x4(%esp)
8010710b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107112:	e8 6d f3 ff ff       	call   80106484 <argstr>
80107117:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010711a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010711e:	78 5e                	js     8010717e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80107120:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107123:	89 44 24 04          	mov    %eax,0x4(%esp)
80107127:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010712e:	e8 b7 f2 ff ff       	call   801063ea <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80107133:	85 c0                	test   %eax,%eax
80107135:	78 47                	js     8010717e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107137:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010713a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010713e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80107145:	e8 a0 f2 ff ff       	call   801063ea <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010714a:	85 c0                	test   %eax,%eax
8010714c:	78 30                	js     8010717e <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010714e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107151:	0f bf c8             	movswl %ax,%ecx
80107154:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107157:	0f bf d0             	movswl %ax,%edx
8010715a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010715d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107161:	89 54 24 08          	mov    %edx,0x8(%esp)
80107165:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010716c:	00 
8010716d:	89 04 24             	mov    %eax,(%esp)
80107170:	e8 94 fa ff ff       	call   80106c09 <create>
80107175:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107178:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010717c:	75 0c                	jne    8010718a <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
8010717e:	e8 8b d3 ff ff       	call   8010450e <commit_trans>
    return -1;
80107183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107188:	eb 15                	jmp    8010719f <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010718a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010718d:	89 04 24             	mov    %eax,(%esp)
80107190:	e8 87 b7 ff ff       	call   8010291c <iunlockput>
  commit_trans();
80107195:	e8 74 d3 ff ff       	call   8010450e <commit_trans>
  return 0;
8010719a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010719f:	c9                   	leave  
801071a0:	c3                   	ret    

801071a1 <sys_chdir>:

int
sys_chdir(void)
{
801071a1:	55                   	push   %ebp
801071a2:	89 e5                	mov    %esp,%ebp
801071a4:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
801071a7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801071aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801071ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071b5:	e8 ca f2 ff ff       	call   80106484 <argstr>
801071ba:	85 c0                	test   %eax,%eax
801071bc:	78 14                	js     801071d2 <sys_chdir+0x31>
801071be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801071c1:	89 04 24             	mov    %eax,(%esp)
801071c4:	e8 5f c1 ff ff       	call   80103328 <namei>
801071c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801071cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801071d0:	75 07                	jne    801071d9 <sys_chdir+0x38>
    return -1;
801071d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071d7:	eb 57                	jmp    80107230 <sys_chdir+0x8f>
  ilock(ip);
801071d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071dc:	89 04 24             	mov    %eax,(%esp)
801071df:	e8 b4 b4 ff ff       	call   80102698 <ilock>
  if(ip->type != T_DIR){
801071e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071e7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801071eb:	66 83 f8 01          	cmp    $0x1,%ax
801071ef:	74 12                	je     80107203 <sys_chdir+0x62>
    iunlockput(ip);
801071f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071f4:	89 04 24             	mov    %eax,(%esp)
801071f7:	e8 20 b7 ff ff       	call   8010291c <iunlockput>
    return -1;
801071fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107201:	eb 2d                	jmp    80107230 <sys_chdir+0x8f>
  }
  iunlock(ip);
80107203:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107206:	89 04 24             	mov    %eax,(%esp)
80107209:	e8 d8 b5 ff ff       	call   801027e6 <iunlock>
  iput(proc->cwd);
8010720e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107214:	8b 40 68             	mov    0x68(%eax),%eax
80107217:	89 04 24             	mov    %eax,(%esp)
8010721a:	e8 2c b6 ff ff       	call   8010284b <iput>
  proc->cwd = ip;
8010721f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107225:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107228:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
8010722b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107230:	c9                   	leave  
80107231:	c3                   	ret    

80107232 <sys_exec>:

int
sys_exec(void)
{
80107232:	55                   	push   %ebp
80107233:	89 e5                	mov    %esp,%ebp
80107235:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
8010723b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010723e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107242:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107249:	e8 36 f2 ff ff       	call   80106484 <argstr>
8010724e:	85 c0                	test   %eax,%eax
80107250:	78 1a                	js     8010726c <sys_exec+0x3a>
80107252:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80107258:	89 44 24 04          	mov    %eax,0x4(%esp)
8010725c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80107263:	e8 82 f1 ff ff       	call   801063ea <argint>
80107268:	85 c0                	test   %eax,%eax
8010726a:	79 0a                	jns    80107276 <sys_exec+0x44>
    return -1;
8010726c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107271:	e9 e2 00 00 00       	jmp    80107358 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80107276:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010727d:	00 
8010727e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107285:	00 
80107286:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010728c:	89 04 24             	mov    %eax,(%esp)
8010728f:	e8 06 ee ff ff       	call   8010609a <memset>
  for(i=0;; i++){
80107294:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010729b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010729e:	83 f8 1f             	cmp    $0x1f,%eax
801072a1:	76 0a                	jbe    801072ad <sys_exec+0x7b>
      return -1;
801072a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072a8:	e9 ab 00 00 00       	jmp    80107358 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
801072ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072b0:	c1 e0 02             	shl    $0x2,%eax
801072b3:	89 c2                	mov    %eax,%edx
801072b5:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
801072bb:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
801072be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801072c4:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
801072ca:	89 54 24 08          	mov    %edx,0x8(%esp)
801072ce:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801072d2:	89 04 24             	mov    %eax,(%esp)
801072d5:	e8 7e f0 ff ff       	call   80106358 <fetchint>
801072da:	85 c0                	test   %eax,%eax
801072dc:	79 07                	jns    801072e5 <sys_exec+0xb3>
      return -1;
801072de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072e3:	eb 73                	jmp    80107358 <sys_exec+0x126>
    if(uarg == 0){
801072e5:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801072eb:	85 c0                	test   %eax,%eax
801072ed:	75 26                	jne    80107315 <sys_exec+0xe3>
      argv[i] = 0;
801072ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072f2:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801072f9:	00 00 00 00 
      break;
801072fd:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801072fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107301:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107307:	89 54 24 04          	mov    %edx,0x4(%esp)
8010730b:	89 04 24             	mov    %eax,(%esp)
8010730e:	e8 e9 97 ff ff       	call   80100afc <exec>
80107313:	eb 43                	jmp    80107358 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80107315:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107318:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010731f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107325:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80107328:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
8010732e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107334:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107338:	89 54 24 04          	mov    %edx,0x4(%esp)
8010733c:	89 04 24             	mov    %eax,(%esp)
8010733f:	e8 48 f0 ff ff       	call   8010638c <fetchstr>
80107344:	85 c0                	test   %eax,%eax
80107346:	79 07                	jns    8010734f <sys_exec+0x11d>
      return -1;
80107348:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010734d:	eb 09                	jmp    80107358 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010734f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80107353:	e9 43 ff ff ff       	jmp    8010729b <sys_exec+0x69>
  return exec(path, argv);
}
80107358:	c9                   	leave  
80107359:	c3                   	ret    

8010735a <sys_pipe>:

int
sys_pipe(void)
{
8010735a:	55                   	push   %ebp
8010735b:	89 e5                	mov    %esp,%ebp
8010735d:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80107360:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80107367:	00 
80107368:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010736b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010736f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107376:	e8 a7 f0 ff ff       	call   80106422 <argptr>
8010737b:	85 c0                	test   %eax,%eax
8010737d:	79 0a                	jns    80107389 <sys_pipe+0x2f>
    return -1;
8010737f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107384:	e9 9b 00 00 00       	jmp    80107424 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80107389:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010738c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107390:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107393:	89 04 24             	mov    %eax,(%esp)
80107396:	e8 45 db ff ff       	call   80104ee0 <pipealloc>
8010739b:	85 c0                	test   %eax,%eax
8010739d:	79 07                	jns    801073a6 <sys_pipe+0x4c>
    return -1;
8010739f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073a4:	eb 7e                	jmp    80107424 <sys_pipe+0xca>
  fd0 = -1;
801073a6:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801073ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
801073b0:	89 04 24             	mov    %eax,(%esp)
801073b3:	e8 49 f2 ff ff       	call   80106601 <fdalloc>
801073b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801073bb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801073bf:	78 14                	js     801073d5 <sys_pipe+0x7b>
801073c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801073c4:	89 04 24             	mov    %eax,(%esp)
801073c7:	e8 35 f2 ff ff       	call   80106601 <fdalloc>
801073cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801073cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801073d3:	79 37                	jns    8010740c <sys_pipe+0xb2>
    if(fd0 >= 0)
801073d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801073d9:	78 14                	js     801073ef <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801073db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801073e4:	83 c2 08             	add    $0x8,%edx
801073e7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801073ee:	00 
    fileclose(rf);
801073ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
801073f2:	89 04 24             	mov    %eax,(%esp)
801073f5:	e8 ca 9b ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
801073fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801073fd:	89 04 24             	mov    %eax,(%esp)
80107400:	e8 bf 9b ff ff       	call   80100fc4 <fileclose>
    return -1;
80107405:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010740a:	eb 18                	jmp    80107424 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010740c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010740f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107412:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80107414:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107417:	8d 50 04             	lea    0x4(%eax),%edx
8010741a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010741d:	89 02                	mov    %eax,(%edx)
  return 0;
8010741f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107424:	c9                   	leave  
80107425:	c3                   	ret    
	...

80107428 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107428:	55                   	push   %ebp
80107429:	89 e5                	mov    %esp,%ebp
8010742b:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010742e:	e8 67 e1 ff ff       	call   8010559a <fork>
}
80107433:	c9                   	leave  
80107434:	c3                   	ret    

80107435 <sys_exit>:

int
sys_exit(void)
{
80107435:	55                   	push   %ebp
80107436:	89 e5                	mov    %esp,%ebp
80107438:	83 ec 08             	sub    $0x8,%esp
  exit();
8010743b:	e8 bd e2 ff ff       	call   801056fd <exit>
  return 0;  // not reached
80107440:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107445:	c9                   	leave  
80107446:	c3                   	ret    

80107447 <sys_wait>:

int
sys_wait(void)
{
80107447:	55                   	push   %ebp
80107448:	89 e5                	mov    %esp,%ebp
8010744a:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010744d:	e8 c3 e3 ff ff       	call   80105815 <wait>
}
80107452:	c9                   	leave  
80107453:	c3                   	ret    

80107454 <sys_kill>:

int
sys_kill(void)
{
80107454:	55                   	push   %ebp
80107455:	89 e5                	mov    %esp,%ebp
80107457:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010745a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010745d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107461:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107468:	e8 7d ef ff ff       	call   801063ea <argint>
8010746d:	85 c0                	test   %eax,%eax
8010746f:	79 07                	jns    80107478 <sys_kill+0x24>
    return -1;
80107471:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107476:	eb 0b                	jmp    80107483 <sys_kill+0x2f>
  return kill(pid);
80107478:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010747b:	89 04 24             	mov    %eax,(%esp)
8010747e:	e8 ee e7 ff ff       	call   80105c71 <kill>
}
80107483:	c9                   	leave  
80107484:	c3                   	ret    

80107485 <sys_getpid>:

int
sys_getpid(void)
{
80107485:	55                   	push   %ebp
80107486:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107488:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010748e:	8b 40 10             	mov    0x10(%eax),%eax
}
80107491:	5d                   	pop    %ebp
80107492:	c3                   	ret    

80107493 <sys_sbrk>:

int
sys_sbrk(void)
{
80107493:	55                   	push   %ebp
80107494:	89 e5                	mov    %esp,%ebp
80107496:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107499:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010749c:	89 44 24 04          	mov    %eax,0x4(%esp)
801074a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801074a7:	e8 3e ef ff ff       	call   801063ea <argint>
801074ac:	85 c0                	test   %eax,%eax
801074ae:	79 07                	jns    801074b7 <sys_sbrk+0x24>
    return -1;
801074b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074b5:	eb 24                	jmp    801074db <sys_sbrk+0x48>
  addr = proc->sz;
801074b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074bd:	8b 00                	mov    (%eax),%eax
801074bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801074c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074c5:	89 04 24             	mov    %eax,(%esp)
801074c8:	e8 28 e0 ff ff       	call   801054f5 <growproc>
801074cd:	85 c0                	test   %eax,%eax
801074cf:	79 07                	jns    801074d8 <sys_sbrk+0x45>
    return -1;
801074d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074d6:	eb 03                	jmp    801074db <sys_sbrk+0x48>
  return addr;
801074d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801074db:	c9                   	leave  
801074dc:	c3                   	ret    

801074dd <sys_sleep>:

int
sys_sleep(void)
{
801074dd:	55                   	push   %ebp
801074de:	89 e5                	mov    %esp,%ebp
801074e0:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801074e3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801074e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801074ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801074f1:	e8 f4 ee ff ff       	call   801063ea <argint>
801074f6:	85 c0                	test   %eax,%eax
801074f8:	79 07                	jns    80107501 <sys_sleep+0x24>
    return -1;
801074fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801074ff:	eb 6c                	jmp    8010756d <sys_sleep+0x90>
  acquire(&tickslock);
80107501:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107508:	e8 3e e9 ff ff       	call   80105e4b <acquire>
  ticks0 = ticks;
8010750d:	a1 00 37 11 80       	mov    0x80113700,%eax
80107512:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107515:	eb 34                	jmp    8010754b <sys_sleep+0x6e>
    if(proc->killed){
80107517:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010751d:	8b 40 24             	mov    0x24(%eax),%eax
80107520:	85 c0                	test   %eax,%eax
80107522:	74 13                	je     80107537 <sys_sleep+0x5a>
      release(&tickslock);
80107524:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
8010752b:	e8 7d e9 ff ff       	call   80105ead <release>
      return -1;
80107530:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107535:	eb 36                	jmp    8010756d <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107537:	c7 44 24 04 c0 2e 11 	movl   $0x80112ec0,0x4(%esp)
8010753e:	80 
8010753f:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80107546:	e8 22 e6 ff ff       	call   80105b6d <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010754b:	a1 00 37 11 80       	mov    0x80113700,%eax
80107550:	89 c2                	mov    %eax,%edx
80107552:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107555:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107558:	39 c2                	cmp    %eax,%edx
8010755a:	72 bb                	jb     80107517 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010755c:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107563:	e8 45 e9 ff ff       	call   80105ead <release>
  return 0;
80107568:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010756d:	c9                   	leave  
8010756e:	c3                   	ret    

8010756f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010756f:	55                   	push   %ebp
80107570:	89 e5                	mov    %esp,%ebp
80107572:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107575:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
8010757c:	e8 ca e8 ff ff       	call   80105e4b <acquire>
  xticks = ticks;
80107581:	a1 00 37 11 80       	mov    0x80113700,%eax
80107586:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107589:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107590:	e8 18 e9 ff ff       	call   80105ead <release>
  return xticks;
80107595:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107598:	c9                   	leave  
80107599:	c3                   	ret    

8010759a <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
8010759a:	55                   	push   %ebp
8010759b:	89 e5                	mov    %esp,%ebp
8010759d:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
801075a0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801075a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801075a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075ae:	e8 d1 ee ff ff       	call   80106484 <argstr>
801075b3:	85 c0                	test   %eax,%eax
801075b5:	79 07                	jns    801075be <sys_getFileBlocks+0x24>
    return -1;
801075b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801075bc:	eb 0b                	jmp    801075c9 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
801075be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c1:	89 04 24             	mov    %eax,(%esp)
801075c4:	e8 21 9d ff ff       	call   801012ea <getFileBlocks>
}
801075c9:	c9                   	leave  
801075ca:	c3                   	ret    

801075cb <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
801075cb:	55                   	push   %ebp
801075cc:	89 e5                	mov    %esp,%ebp
801075ce:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
801075d1:	e8 71 9e ff ff       	call   80101447 <getFreeBlocks>
}
801075d6:	c9                   	leave  
801075d7:	c3                   	ret    

801075d8 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
801075d8:	55                   	push   %ebp
801075d9:	89 e5                	mov    %esp,%ebp
801075db:	83 ec 08             	sub    $0x8,%esp
  return getSharedBlocksRate();
801075de:	e8 fb a8 ff ff       	call   80101ede <getSharedBlocksRate>
}
801075e3:	c9                   	leave  
801075e4:	c3                   	ret    

801075e5 <sys_dedup>:

int
sys_dedup(void)
{
801075e5:	55                   	push   %ebp
801075e6:	89 e5                	mov    %esp,%ebp
801075e8:	83 ec 08             	sub    $0x8,%esp
  return dedup();
801075eb:	e8 99 a0 ff ff       	call   80101689 <dedup>
}
801075f0:	c9                   	leave  
801075f1:	c3                   	ret    

801075f2 <sys_getBlkRef>:

int
sys_getBlkRef(void)
{
801075f2:	55                   	push   %ebp
801075f3:	89 e5                	mov    %esp,%ebp
801075f5:	83 ec 28             	sub    $0x28,%esp
  int n;
  if(argint(0, &n) < 0)
801075f8:	8d 45 f4             	lea    -0xc(%ebp),%eax
801075fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801075ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107606:	e8 df ed ff ff       	call   801063ea <argint>
8010760b:	85 c0                	test   %eax,%eax
8010760d:	79 07                	jns    80107616 <sys_getBlkRef+0x24>
    return -1;
8010760f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107614:	eb 0b                	jmp    80107621 <sys_getBlkRef+0x2f>
  return getBlkRef(n);
80107616:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107619:	89 04 24             	mov    %eax,(%esp)
8010761c:	e8 35 c0 ff ff       	call   80103656 <getBlkRef>
}
80107621:	c9                   	leave  
80107622:	c3                   	ret    
	...

80107624 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107624:	55                   	push   %ebp
80107625:	89 e5                	mov    %esp,%ebp
80107627:	83 ec 08             	sub    $0x8,%esp
8010762a:	8b 55 08             	mov    0x8(%ebp),%edx
8010762d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107630:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107634:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107637:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010763b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010763f:	ee                   	out    %al,(%dx)
}
80107640:	c9                   	leave  
80107641:	c3                   	ret    

80107642 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80107642:	55                   	push   %ebp
80107643:	89 e5                	mov    %esp,%ebp
80107645:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107648:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010764f:	00 
80107650:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107657:	e8 c8 ff ff ff       	call   80107624 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010765c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107663:	00 
80107664:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010766b:	e8 b4 ff ff ff       	call   80107624 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107670:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107677:	00 
80107678:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010767f:	e8 a0 ff ff ff       	call   80107624 <outb>
  picenable(IRQ_TIMER);
80107684:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010768b:	e8 d9 d6 ff ff       	call   80104d69 <picenable>
}
80107690:	c9                   	leave  
80107691:	c3                   	ret    
	...

80107694 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107694:	1e                   	push   %ds
  pushl %es
80107695:	06                   	push   %es
  pushl %fs
80107696:	0f a0                	push   %fs
  pushl %gs
80107698:	0f a8                	push   %gs
  pushal
8010769a:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010769b:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010769f:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801076a1:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801076a3:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801076a7:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801076a9:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801076ab:	54                   	push   %esp
  call trap
801076ac:	e8 de 01 00 00       	call   8010788f <trap>
  addl $4, %esp
801076b1:	83 c4 04             	add    $0x4,%esp

801076b4 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801076b4:	61                   	popa   
  popl %gs
801076b5:	0f a9                	pop    %gs
  popl %fs
801076b7:	0f a1                	pop    %fs
  popl %es
801076b9:	07                   	pop    %es
  popl %ds
801076ba:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801076bb:	83 c4 08             	add    $0x8,%esp
  iret
801076be:	cf                   	iret   
	...

801076c0 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801076c0:	55                   	push   %ebp
801076c1:	89 e5                	mov    %esp,%ebp
801076c3:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801076c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801076c9:	83 e8 01             	sub    $0x1,%eax
801076cc:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801076d0:	8b 45 08             	mov    0x8(%ebp),%eax
801076d3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801076d7:	8b 45 08             	mov    0x8(%ebp),%eax
801076da:	c1 e8 10             	shr    $0x10,%eax
801076dd:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801076e1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801076e4:	0f 01 18             	lidtl  (%eax)
}
801076e7:	c9                   	leave  
801076e8:	c3                   	ret    

801076e9 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801076e9:	55                   	push   %ebp
801076ea:	89 e5                	mov    %esp,%ebp
801076ec:	53                   	push   %ebx
801076ed:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801076f0:	0f 20 d3             	mov    %cr2,%ebx
801076f3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801076f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801076f9:	83 c4 10             	add    $0x10,%esp
801076fc:	5b                   	pop    %ebx
801076fd:	5d                   	pop    %ebp
801076fe:	c3                   	ret    

801076ff <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801076ff:	55                   	push   %ebp
80107700:	89 e5                	mov    %esp,%ebp
80107702:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107705:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010770c:	e9 c3 00 00 00       	jmp    801077d4 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80107711:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107714:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
8010771b:	89 c2                	mov    %eax,%edx
8010771d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107720:	66 89 14 c5 00 2f 11 	mov    %dx,-0x7feed100(,%eax,8)
80107727:	80 
80107728:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010772b:	66 c7 04 c5 02 2f 11 	movw   $0x8,-0x7feed0fe(,%eax,8)
80107732:	80 08 00 
80107735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107738:	0f b6 14 c5 04 2f 11 	movzbl -0x7feed0fc(,%eax,8),%edx
8010773f:	80 
80107740:	83 e2 e0             	and    $0xffffffe0,%edx
80107743:	88 14 c5 04 2f 11 80 	mov    %dl,-0x7feed0fc(,%eax,8)
8010774a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774d:	0f b6 14 c5 04 2f 11 	movzbl -0x7feed0fc(,%eax,8),%edx
80107754:	80 
80107755:	83 e2 1f             	and    $0x1f,%edx
80107758:	88 14 c5 04 2f 11 80 	mov    %dl,-0x7feed0fc(,%eax,8)
8010775f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107762:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
80107769:	80 
8010776a:	83 e2 f0             	and    $0xfffffff0,%edx
8010776d:	83 ca 0e             	or     $0xe,%edx
80107770:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
80107777:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010777a:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
80107781:	80 
80107782:	83 e2 ef             	and    $0xffffffef,%edx
80107785:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
8010778c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010778f:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
80107796:	80 
80107797:	83 e2 9f             	and    $0xffffff9f,%edx
8010779a:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
801077a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a4:	0f b6 14 c5 05 2f 11 	movzbl -0x7feed0fb(,%eax,8),%edx
801077ab:	80 
801077ac:	83 ca 80             	or     $0xffffff80,%edx
801077af:	88 14 c5 05 2f 11 80 	mov    %dl,-0x7feed0fb(,%eax,8)
801077b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b9:	8b 04 85 ac c0 10 80 	mov    -0x7fef3f54(,%eax,4),%eax
801077c0:	c1 e8 10             	shr    $0x10,%eax
801077c3:	89 c2                	mov    %eax,%edx
801077c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c8:	66 89 14 c5 06 2f 11 	mov    %dx,-0x7feed0fa(,%eax,8)
801077cf:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801077d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801077d4:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801077db:	0f 8e 30 ff ff ff    	jle    80107711 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801077e1:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
801077e6:	66 a3 00 31 11 80    	mov    %ax,0x80113100
801077ec:	66 c7 05 02 31 11 80 	movw   $0x8,0x80113102
801077f3:	08 00 
801077f5:	0f b6 05 04 31 11 80 	movzbl 0x80113104,%eax
801077fc:	83 e0 e0             	and    $0xffffffe0,%eax
801077ff:	a2 04 31 11 80       	mov    %al,0x80113104
80107804:	0f b6 05 04 31 11 80 	movzbl 0x80113104,%eax
8010780b:	83 e0 1f             	and    $0x1f,%eax
8010780e:	a2 04 31 11 80       	mov    %al,0x80113104
80107813:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
8010781a:	83 c8 0f             	or     $0xf,%eax
8010781d:	a2 05 31 11 80       	mov    %al,0x80113105
80107822:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
80107829:	83 e0 ef             	and    $0xffffffef,%eax
8010782c:	a2 05 31 11 80       	mov    %al,0x80113105
80107831:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
80107838:	83 c8 60             	or     $0x60,%eax
8010783b:	a2 05 31 11 80       	mov    %al,0x80113105
80107840:	0f b6 05 05 31 11 80 	movzbl 0x80113105,%eax
80107847:	83 c8 80             	or     $0xffffff80,%eax
8010784a:	a2 05 31 11 80       	mov    %al,0x80113105
8010784f:	a1 ac c1 10 80       	mov    0x8010c1ac,%eax
80107854:	c1 e8 10             	shr    $0x10,%eax
80107857:	66 a3 06 31 11 80    	mov    %ax,0x80113106
  
  initlock(&tickslock, "time");
8010785d:	c7 44 24 04 48 9b 10 	movl   $0x80109b48,0x4(%esp)
80107864:	80 
80107865:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
8010786c:	e8 b9 e5 ff ff       	call   80105e2a <initlock>
}
80107871:	c9                   	leave  
80107872:	c3                   	ret    

80107873 <idtinit>:

void
idtinit(void)
{
80107873:	55                   	push   %ebp
80107874:	89 e5                	mov    %esp,%ebp
80107876:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107879:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80107880:	00 
80107881:	c7 04 24 00 2f 11 80 	movl   $0x80112f00,(%esp)
80107888:	e8 33 fe ff ff       	call   801076c0 <lidt>
}
8010788d:	c9                   	leave  
8010788e:	c3                   	ret    

8010788f <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010788f:	55                   	push   %ebp
80107890:	89 e5                	mov    %esp,%ebp
80107892:	57                   	push   %edi
80107893:	56                   	push   %esi
80107894:	53                   	push   %ebx
80107895:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107898:	8b 45 08             	mov    0x8(%ebp),%eax
8010789b:	8b 40 30             	mov    0x30(%eax),%eax
8010789e:	83 f8 40             	cmp    $0x40,%eax
801078a1:	75 3e                	jne    801078e1 <trap+0x52>
    if(proc->killed)
801078a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078a9:	8b 40 24             	mov    0x24(%eax),%eax
801078ac:	85 c0                	test   %eax,%eax
801078ae:	74 05                	je     801078b5 <trap+0x26>
      exit();
801078b0:	e8 48 de ff ff       	call   801056fd <exit>
    proc->tf = tf;
801078b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078bb:	8b 55 08             	mov    0x8(%ebp),%edx
801078be:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801078c1:	e8 01 ec ff ff       	call   801064c7 <syscall>
    if(proc->killed)
801078c6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078cc:	8b 40 24             	mov    0x24(%eax),%eax
801078cf:	85 c0                	test   %eax,%eax
801078d1:	0f 84 34 02 00 00    	je     80107b0b <trap+0x27c>
      exit();
801078d7:	e8 21 de ff ff       	call   801056fd <exit>
    return;
801078dc:	e9 2a 02 00 00       	jmp    80107b0b <trap+0x27c>
  }

  switch(tf->trapno){
801078e1:	8b 45 08             	mov    0x8(%ebp),%eax
801078e4:	8b 40 30             	mov    0x30(%eax),%eax
801078e7:	83 e8 20             	sub    $0x20,%eax
801078ea:	83 f8 1f             	cmp    $0x1f,%eax
801078ed:	0f 87 bc 00 00 00    	ja     801079af <trap+0x120>
801078f3:	8b 04 85 f0 9b 10 80 	mov    -0x7fef6410(,%eax,4),%eax
801078fa:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801078fc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107902:	0f b6 00             	movzbl (%eax),%eax
80107905:	84 c0                	test   %al,%al
80107907:	75 31                	jne    8010793a <trap+0xab>
      acquire(&tickslock);
80107909:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107910:	e8 36 e5 ff ff       	call   80105e4b <acquire>
      ticks++;
80107915:	a1 00 37 11 80       	mov    0x80113700,%eax
8010791a:	83 c0 01             	add    $0x1,%eax
8010791d:	a3 00 37 11 80       	mov    %eax,0x80113700
      wakeup(&ticks);
80107922:	c7 04 24 00 37 11 80 	movl   $0x80113700,(%esp)
80107929:	e8 18 e3 ff ff       	call   80105c46 <wakeup>
      release(&tickslock);
8010792e:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107935:	e8 73 e5 ff ff       	call   80105ead <release>
    }
    lapiceoi();
8010793a:	e8 52 c8 ff ff       	call   80104191 <lapiceoi>
    break;
8010793f:	e9 41 01 00 00       	jmp    80107a85 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107944:	e8 50 c0 ff ff       	call   80103999 <ideintr>
    lapiceoi();
80107949:	e8 43 c8 ff ff       	call   80104191 <lapiceoi>
    break;
8010794e:	e9 32 01 00 00       	jmp    80107a85 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80107953:	e8 17 c6 ff ff       	call   80103f6f <kbdintr>
    lapiceoi();
80107958:	e8 34 c8 ff ff       	call   80104191 <lapiceoi>
    break;
8010795d:	e9 23 01 00 00       	jmp    80107a85 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80107962:	e8 a9 03 00 00       	call   80107d10 <uartintr>
    lapiceoi();
80107967:	e8 25 c8 ff ff       	call   80104191 <lapiceoi>
    break;
8010796c:	e9 14 01 00 00       	jmp    80107a85 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80107971:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107974:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107977:	8b 45 08             	mov    0x8(%ebp),%eax
8010797a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010797e:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80107981:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107987:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010798a:	0f b6 c0             	movzbl %al,%eax
8010798d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107991:	89 54 24 08          	mov    %edx,0x8(%esp)
80107995:	89 44 24 04          	mov    %eax,0x4(%esp)
80107999:	c7 04 24 50 9b 10 80 	movl   $0x80109b50,(%esp)
801079a0:	e8 fc 89 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801079a5:	e8 e7 c7 ff ff       	call   80104191 <lapiceoi>
    break;
801079aa:	e9 d6 00 00 00       	jmp    80107a85 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801079af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079b5:	85 c0                	test   %eax,%eax
801079b7:	74 11                	je     801079ca <trap+0x13b>
801079b9:	8b 45 08             	mov    0x8(%ebp),%eax
801079bc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801079c0:	0f b7 c0             	movzwl %ax,%eax
801079c3:	83 e0 03             	and    $0x3,%eax
801079c6:	85 c0                	test   %eax,%eax
801079c8:	75 46                	jne    80107a10 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801079ca:	e8 1a fd ff ff       	call   801076e9 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801079cf:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801079d2:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801079d5:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801079dc:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801079df:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801079e2:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801079e5:	8b 52 30             	mov    0x30(%edx),%edx
801079e8:	89 44 24 10          	mov    %eax,0x10(%esp)
801079ec:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801079f0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801079f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801079f8:	c7 04 24 74 9b 10 80 	movl   $0x80109b74,(%esp)
801079ff:	e8 9d 89 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107a04:	c7 04 24 a6 9b 10 80 	movl   $0x80109ba6,(%esp)
80107a0b:	e8 2d 8b ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a10:	e8 d4 fc ff ff       	call   801076e9 <rcr2>
80107a15:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107a17:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a1a:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107a1d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107a23:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a26:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107a29:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a2c:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107a2f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a32:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107a35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a3b:	83 c0 6c             	add    $0x6c,%eax
80107a3e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80107a41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107a47:	8b 40 10             	mov    0x10(%eax),%eax
80107a4a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80107a4e:	89 7c 24 18          	mov    %edi,0x18(%esp)
80107a52:	89 74 24 14          	mov    %esi,0x14(%esp)
80107a56:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107a5a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80107a5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80107a61:	89 54 24 08          	mov    %edx,0x8(%esp)
80107a65:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a69:	c7 04 24 ac 9b 10 80 	movl   $0x80109bac,(%esp)
80107a70:	e8 2c 89 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107a75:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a7b:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80107a82:	eb 01                	jmp    80107a85 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107a84:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107a85:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a8b:	85 c0                	test   %eax,%eax
80107a8d:	74 24                	je     80107ab3 <trap+0x224>
80107a8f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a95:	8b 40 24             	mov    0x24(%eax),%eax
80107a98:	85 c0                	test   %eax,%eax
80107a9a:	74 17                	je     80107ab3 <trap+0x224>
80107a9c:	8b 45 08             	mov    0x8(%ebp),%eax
80107a9f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107aa3:	0f b7 c0             	movzwl %ax,%eax
80107aa6:	83 e0 03             	and    $0x3,%eax
80107aa9:	83 f8 03             	cmp    $0x3,%eax
80107aac:	75 05                	jne    80107ab3 <trap+0x224>
    exit();
80107aae:	e8 4a dc ff ff       	call   801056fd <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80107ab3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ab9:	85 c0                	test   %eax,%eax
80107abb:	74 1e                	je     80107adb <trap+0x24c>
80107abd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ac3:	8b 40 0c             	mov    0xc(%eax),%eax
80107ac6:	83 f8 04             	cmp    $0x4,%eax
80107ac9:	75 10                	jne    80107adb <trap+0x24c>
80107acb:	8b 45 08             	mov    0x8(%ebp),%eax
80107ace:	8b 40 30             	mov    0x30(%eax),%eax
80107ad1:	83 f8 20             	cmp    $0x20,%eax
80107ad4:	75 05                	jne    80107adb <trap+0x24c>
    yield();
80107ad6:	e8 34 e0 ff ff       	call   80105b0f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107adb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107ae1:	85 c0                	test   %eax,%eax
80107ae3:	74 27                	je     80107b0c <trap+0x27d>
80107ae5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107aeb:	8b 40 24             	mov    0x24(%eax),%eax
80107aee:	85 c0                	test   %eax,%eax
80107af0:	74 1a                	je     80107b0c <trap+0x27d>
80107af2:	8b 45 08             	mov    0x8(%ebp),%eax
80107af5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107af9:	0f b7 c0             	movzwl %ax,%eax
80107afc:	83 e0 03             	and    $0x3,%eax
80107aff:	83 f8 03             	cmp    $0x3,%eax
80107b02:	75 08                	jne    80107b0c <trap+0x27d>
    exit();
80107b04:	e8 f4 db ff ff       	call   801056fd <exit>
80107b09:	eb 01                	jmp    80107b0c <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107b0b:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107b0c:	83 c4 3c             	add    $0x3c,%esp
80107b0f:	5b                   	pop    %ebx
80107b10:	5e                   	pop    %esi
80107b11:	5f                   	pop    %edi
80107b12:	5d                   	pop    %ebp
80107b13:	c3                   	ret    

80107b14 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107b14:	55                   	push   %ebp
80107b15:	89 e5                	mov    %esp,%ebp
80107b17:	53                   	push   %ebx
80107b18:	83 ec 14             	sub    $0x14,%esp
80107b1b:	8b 45 08             	mov    0x8(%ebp),%eax
80107b1e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107b22:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107b26:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107b2a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107b2e:	ec                   	in     (%dx),%al
80107b2f:	89 c3                	mov    %eax,%ebx
80107b31:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107b34:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107b38:	83 c4 14             	add    $0x14,%esp
80107b3b:	5b                   	pop    %ebx
80107b3c:	5d                   	pop    %ebp
80107b3d:	c3                   	ret    

80107b3e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107b3e:	55                   	push   %ebp
80107b3f:	89 e5                	mov    %esp,%ebp
80107b41:	83 ec 08             	sub    $0x8,%esp
80107b44:	8b 55 08             	mov    0x8(%ebp),%edx
80107b47:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b4a:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107b4e:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107b51:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107b55:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107b59:	ee                   	out    %al,(%dx)
}
80107b5a:	c9                   	leave  
80107b5b:	c3                   	ret    

80107b5c <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107b5c:	55                   	push   %ebp
80107b5d:	89 e5                	mov    %esp,%ebp
80107b5f:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107b62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b69:	00 
80107b6a:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107b71:	e8 c8 ff ff ff       	call   80107b3e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107b76:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107b7d:	00 
80107b7e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107b85:	e8 b4 ff ff ff       	call   80107b3e <outb>
  outb(COM1+0, 115200/9600);
80107b8a:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107b91:	00 
80107b92:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107b99:	e8 a0 ff ff ff       	call   80107b3e <outb>
  outb(COM1+1, 0);
80107b9e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ba5:	00 
80107ba6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107bad:	e8 8c ff ff ff       	call   80107b3e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107bb2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107bb9:	00 
80107bba:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107bc1:	e8 78 ff ff ff       	call   80107b3e <outb>
  outb(COM1+4, 0);
80107bc6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107bcd:	00 
80107bce:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107bd5:	e8 64 ff ff ff       	call   80107b3e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107bda:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107be1:	00 
80107be2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107be9:	e8 50 ff ff ff       	call   80107b3e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107bee:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107bf5:	e8 1a ff ff ff       	call   80107b14 <inb>
80107bfa:	3c ff                	cmp    $0xff,%al
80107bfc:	74 6c                	je     80107c6a <uartinit+0x10e>
    return;
  uart = 1;
80107bfe:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
80107c05:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107c08:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107c0f:	e8 00 ff ff ff       	call   80107b14 <inb>
  inb(COM1+0);
80107c14:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c1b:	e8 f4 fe ff ff       	call   80107b14 <inb>
  picenable(IRQ_COM1);
80107c20:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107c27:	e8 3d d1 ff ff       	call   80104d69 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107c2c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c33:	00 
80107c34:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107c3b:	e8 de bf ff ff       	call   80103c1e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107c40:	c7 45 f4 70 9c 10 80 	movl   $0x80109c70,-0xc(%ebp)
80107c47:	eb 15                	jmp    80107c5e <uartinit+0x102>
    uartputc(*p);
80107c49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c4c:	0f b6 00             	movzbl (%eax),%eax
80107c4f:	0f be c0             	movsbl %al,%eax
80107c52:	89 04 24             	mov    %eax,(%esp)
80107c55:	e8 13 00 00 00       	call   80107c6d <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107c5a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107c5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c61:	0f b6 00             	movzbl (%eax),%eax
80107c64:	84 c0                	test   %al,%al
80107c66:	75 e1                	jne    80107c49 <uartinit+0xed>
80107c68:	eb 01                	jmp    80107c6b <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107c6a:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107c6b:	c9                   	leave  
80107c6c:	c3                   	ret    

80107c6d <uartputc>:

void
uartputc(int c)
{
80107c6d:	55                   	push   %ebp
80107c6e:	89 e5                	mov    %esp,%ebp
80107c70:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107c73:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107c78:	85 c0                	test   %eax,%eax
80107c7a:	74 4d                	je     80107cc9 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107c7c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107c83:	eb 10                	jmp    80107c95 <uartputc+0x28>
    microdelay(10);
80107c85:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107c8c:	e8 25 c5 ff ff       	call   801041b6 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107c91:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107c95:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107c99:	7f 16                	jg     80107cb1 <uartputc+0x44>
80107c9b:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ca2:	e8 6d fe ff ff       	call   80107b14 <inb>
80107ca7:	0f b6 c0             	movzbl %al,%eax
80107caa:	83 e0 20             	and    $0x20,%eax
80107cad:	85 c0                	test   %eax,%eax
80107caf:	74 d4                	je     80107c85 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107cb1:	8b 45 08             	mov    0x8(%ebp),%eax
80107cb4:	0f b6 c0             	movzbl %al,%eax
80107cb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cbb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107cc2:	e8 77 fe ff ff       	call   80107b3e <outb>
80107cc7:	eb 01                	jmp    80107cca <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107cc9:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107cca:	c9                   	leave  
80107ccb:	c3                   	ret    

80107ccc <uartgetc>:

static int
uartgetc(void)
{
80107ccc:	55                   	push   %ebp
80107ccd:	89 e5                	mov    %esp,%ebp
80107ccf:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107cd2:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107cd7:	85 c0                	test   %eax,%eax
80107cd9:	75 07                	jne    80107ce2 <uartgetc+0x16>
    return -1;
80107cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107ce0:	eb 2c                	jmp    80107d0e <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107ce2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107ce9:	e8 26 fe ff ff       	call   80107b14 <inb>
80107cee:	0f b6 c0             	movzbl %al,%eax
80107cf1:	83 e0 01             	and    $0x1,%eax
80107cf4:	85 c0                	test   %eax,%eax
80107cf6:	75 07                	jne    80107cff <uartgetc+0x33>
    return -1;
80107cf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107cfd:	eb 0f                	jmp    80107d0e <uartgetc+0x42>
  return inb(COM1+0);
80107cff:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107d06:	e8 09 fe ff ff       	call   80107b14 <inb>
80107d0b:	0f b6 c0             	movzbl %al,%eax
}
80107d0e:	c9                   	leave  
80107d0f:	c3                   	ret    

80107d10 <uartintr>:

void
uartintr(void)
{
80107d10:	55                   	push   %ebp
80107d11:	89 e5                	mov    %esp,%ebp
80107d13:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107d16:	c7 04 24 cc 7c 10 80 	movl   $0x80107ccc,(%esp)
80107d1d:	e8 8b 8a ff ff       	call   801007ad <consoleintr>
}
80107d22:	c9                   	leave  
80107d23:	c3                   	ret    

80107d24 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107d24:	6a 00                	push   $0x0
  pushl $0
80107d26:	6a 00                	push   $0x0
  jmp alltraps
80107d28:	e9 67 f9 ff ff       	jmp    80107694 <alltraps>

80107d2d <vector1>:
.globl vector1
vector1:
  pushl $0
80107d2d:	6a 00                	push   $0x0
  pushl $1
80107d2f:	6a 01                	push   $0x1
  jmp alltraps
80107d31:	e9 5e f9 ff ff       	jmp    80107694 <alltraps>

80107d36 <vector2>:
.globl vector2
vector2:
  pushl $0
80107d36:	6a 00                	push   $0x0
  pushl $2
80107d38:	6a 02                	push   $0x2
  jmp alltraps
80107d3a:	e9 55 f9 ff ff       	jmp    80107694 <alltraps>

80107d3f <vector3>:
.globl vector3
vector3:
  pushl $0
80107d3f:	6a 00                	push   $0x0
  pushl $3
80107d41:	6a 03                	push   $0x3
  jmp alltraps
80107d43:	e9 4c f9 ff ff       	jmp    80107694 <alltraps>

80107d48 <vector4>:
.globl vector4
vector4:
  pushl $0
80107d48:	6a 00                	push   $0x0
  pushl $4
80107d4a:	6a 04                	push   $0x4
  jmp alltraps
80107d4c:	e9 43 f9 ff ff       	jmp    80107694 <alltraps>

80107d51 <vector5>:
.globl vector5
vector5:
  pushl $0
80107d51:	6a 00                	push   $0x0
  pushl $5
80107d53:	6a 05                	push   $0x5
  jmp alltraps
80107d55:	e9 3a f9 ff ff       	jmp    80107694 <alltraps>

80107d5a <vector6>:
.globl vector6
vector6:
  pushl $0
80107d5a:	6a 00                	push   $0x0
  pushl $6
80107d5c:	6a 06                	push   $0x6
  jmp alltraps
80107d5e:	e9 31 f9 ff ff       	jmp    80107694 <alltraps>

80107d63 <vector7>:
.globl vector7
vector7:
  pushl $0
80107d63:	6a 00                	push   $0x0
  pushl $7
80107d65:	6a 07                	push   $0x7
  jmp alltraps
80107d67:	e9 28 f9 ff ff       	jmp    80107694 <alltraps>

80107d6c <vector8>:
.globl vector8
vector8:
  pushl $8
80107d6c:	6a 08                	push   $0x8
  jmp alltraps
80107d6e:	e9 21 f9 ff ff       	jmp    80107694 <alltraps>

80107d73 <vector9>:
.globl vector9
vector9:
  pushl $0
80107d73:	6a 00                	push   $0x0
  pushl $9
80107d75:	6a 09                	push   $0x9
  jmp alltraps
80107d77:	e9 18 f9 ff ff       	jmp    80107694 <alltraps>

80107d7c <vector10>:
.globl vector10
vector10:
  pushl $10
80107d7c:	6a 0a                	push   $0xa
  jmp alltraps
80107d7e:	e9 11 f9 ff ff       	jmp    80107694 <alltraps>

80107d83 <vector11>:
.globl vector11
vector11:
  pushl $11
80107d83:	6a 0b                	push   $0xb
  jmp alltraps
80107d85:	e9 0a f9 ff ff       	jmp    80107694 <alltraps>

80107d8a <vector12>:
.globl vector12
vector12:
  pushl $12
80107d8a:	6a 0c                	push   $0xc
  jmp alltraps
80107d8c:	e9 03 f9 ff ff       	jmp    80107694 <alltraps>

80107d91 <vector13>:
.globl vector13
vector13:
  pushl $13
80107d91:	6a 0d                	push   $0xd
  jmp alltraps
80107d93:	e9 fc f8 ff ff       	jmp    80107694 <alltraps>

80107d98 <vector14>:
.globl vector14
vector14:
  pushl $14
80107d98:	6a 0e                	push   $0xe
  jmp alltraps
80107d9a:	e9 f5 f8 ff ff       	jmp    80107694 <alltraps>

80107d9f <vector15>:
.globl vector15
vector15:
  pushl $0
80107d9f:	6a 00                	push   $0x0
  pushl $15
80107da1:	6a 0f                	push   $0xf
  jmp alltraps
80107da3:	e9 ec f8 ff ff       	jmp    80107694 <alltraps>

80107da8 <vector16>:
.globl vector16
vector16:
  pushl $0
80107da8:	6a 00                	push   $0x0
  pushl $16
80107daa:	6a 10                	push   $0x10
  jmp alltraps
80107dac:	e9 e3 f8 ff ff       	jmp    80107694 <alltraps>

80107db1 <vector17>:
.globl vector17
vector17:
  pushl $17
80107db1:	6a 11                	push   $0x11
  jmp alltraps
80107db3:	e9 dc f8 ff ff       	jmp    80107694 <alltraps>

80107db8 <vector18>:
.globl vector18
vector18:
  pushl $0
80107db8:	6a 00                	push   $0x0
  pushl $18
80107dba:	6a 12                	push   $0x12
  jmp alltraps
80107dbc:	e9 d3 f8 ff ff       	jmp    80107694 <alltraps>

80107dc1 <vector19>:
.globl vector19
vector19:
  pushl $0
80107dc1:	6a 00                	push   $0x0
  pushl $19
80107dc3:	6a 13                	push   $0x13
  jmp alltraps
80107dc5:	e9 ca f8 ff ff       	jmp    80107694 <alltraps>

80107dca <vector20>:
.globl vector20
vector20:
  pushl $0
80107dca:	6a 00                	push   $0x0
  pushl $20
80107dcc:	6a 14                	push   $0x14
  jmp alltraps
80107dce:	e9 c1 f8 ff ff       	jmp    80107694 <alltraps>

80107dd3 <vector21>:
.globl vector21
vector21:
  pushl $0
80107dd3:	6a 00                	push   $0x0
  pushl $21
80107dd5:	6a 15                	push   $0x15
  jmp alltraps
80107dd7:	e9 b8 f8 ff ff       	jmp    80107694 <alltraps>

80107ddc <vector22>:
.globl vector22
vector22:
  pushl $0
80107ddc:	6a 00                	push   $0x0
  pushl $22
80107dde:	6a 16                	push   $0x16
  jmp alltraps
80107de0:	e9 af f8 ff ff       	jmp    80107694 <alltraps>

80107de5 <vector23>:
.globl vector23
vector23:
  pushl $0
80107de5:	6a 00                	push   $0x0
  pushl $23
80107de7:	6a 17                	push   $0x17
  jmp alltraps
80107de9:	e9 a6 f8 ff ff       	jmp    80107694 <alltraps>

80107dee <vector24>:
.globl vector24
vector24:
  pushl $0
80107dee:	6a 00                	push   $0x0
  pushl $24
80107df0:	6a 18                	push   $0x18
  jmp alltraps
80107df2:	e9 9d f8 ff ff       	jmp    80107694 <alltraps>

80107df7 <vector25>:
.globl vector25
vector25:
  pushl $0
80107df7:	6a 00                	push   $0x0
  pushl $25
80107df9:	6a 19                	push   $0x19
  jmp alltraps
80107dfb:	e9 94 f8 ff ff       	jmp    80107694 <alltraps>

80107e00 <vector26>:
.globl vector26
vector26:
  pushl $0
80107e00:	6a 00                	push   $0x0
  pushl $26
80107e02:	6a 1a                	push   $0x1a
  jmp alltraps
80107e04:	e9 8b f8 ff ff       	jmp    80107694 <alltraps>

80107e09 <vector27>:
.globl vector27
vector27:
  pushl $0
80107e09:	6a 00                	push   $0x0
  pushl $27
80107e0b:	6a 1b                	push   $0x1b
  jmp alltraps
80107e0d:	e9 82 f8 ff ff       	jmp    80107694 <alltraps>

80107e12 <vector28>:
.globl vector28
vector28:
  pushl $0
80107e12:	6a 00                	push   $0x0
  pushl $28
80107e14:	6a 1c                	push   $0x1c
  jmp alltraps
80107e16:	e9 79 f8 ff ff       	jmp    80107694 <alltraps>

80107e1b <vector29>:
.globl vector29
vector29:
  pushl $0
80107e1b:	6a 00                	push   $0x0
  pushl $29
80107e1d:	6a 1d                	push   $0x1d
  jmp alltraps
80107e1f:	e9 70 f8 ff ff       	jmp    80107694 <alltraps>

80107e24 <vector30>:
.globl vector30
vector30:
  pushl $0
80107e24:	6a 00                	push   $0x0
  pushl $30
80107e26:	6a 1e                	push   $0x1e
  jmp alltraps
80107e28:	e9 67 f8 ff ff       	jmp    80107694 <alltraps>

80107e2d <vector31>:
.globl vector31
vector31:
  pushl $0
80107e2d:	6a 00                	push   $0x0
  pushl $31
80107e2f:	6a 1f                	push   $0x1f
  jmp alltraps
80107e31:	e9 5e f8 ff ff       	jmp    80107694 <alltraps>

80107e36 <vector32>:
.globl vector32
vector32:
  pushl $0
80107e36:	6a 00                	push   $0x0
  pushl $32
80107e38:	6a 20                	push   $0x20
  jmp alltraps
80107e3a:	e9 55 f8 ff ff       	jmp    80107694 <alltraps>

80107e3f <vector33>:
.globl vector33
vector33:
  pushl $0
80107e3f:	6a 00                	push   $0x0
  pushl $33
80107e41:	6a 21                	push   $0x21
  jmp alltraps
80107e43:	e9 4c f8 ff ff       	jmp    80107694 <alltraps>

80107e48 <vector34>:
.globl vector34
vector34:
  pushl $0
80107e48:	6a 00                	push   $0x0
  pushl $34
80107e4a:	6a 22                	push   $0x22
  jmp alltraps
80107e4c:	e9 43 f8 ff ff       	jmp    80107694 <alltraps>

80107e51 <vector35>:
.globl vector35
vector35:
  pushl $0
80107e51:	6a 00                	push   $0x0
  pushl $35
80107e53:	6a 23                	push   $0x23
  jmp alltraps
80107e55:	e9 3a f8 ff ff       	jmp    80107694 <alltraps>

80107e5a <vector36>:
.globl vector36
vector36:
  pushl $0
80107e5a:	6a 00                	push   $0x0
  pushl $36
80107e5c:	6a 24                	push   $0x24
  jmp alltraps
80107e5e:	e9 31 f8 ff ff       	jmp    80107694 <alltraps>

80107e63 <vector37>:
.globl vector37
vector37:
  pushl $0
80107e63:	6a 00                	push   $0x0
  pushl $37
80107e65:	6a 25                	push   $0x25
  jmp alltraps
80107e67:	e9 28 f8 ff ff       	jmp    80107694 <alltraps>

80107e6c <vector38>:
.globl vector38
vector38:
  pushl $0
80107e6c:	6a 00                	push   $0x0
  pushl $38
80107e6e:	6a 26                	push   $0x26
  jmp alltraps
80107e70:	e9 1f f8 ff ff       	jmp    80107694 <alltraps>

80107e75 <vector39>:
.globl vector39
vector39:
  pushl $0
80107e75:	6a 00                	push   $0x0
  pushl $39
80107e77:	6a 27                	push   $0x27
  jmp alltraps
80107e79:	e9 16 f8 ff ff       	jmp    80107694 <alltraps>

80107e7e <vector40>:
.globl vector40
vector40:
  pushl $0
80107e7e:	6a 00                	push   $0x0
  pushl $40
80107e80:	6a 28                	push   $0x28
  jmp alltraps
80107e82:	e9 0d f8 ff ff       	jmp    80107694 <alltraps>

80107e87 <vector41>:
.globl vector41
vector41:
  pushl $0
80107e87:	6a 00                	push   $0x0
  pushl $41
80107e89:	6a 29                	push   $0x29
  jmp alltraps
80107e8b:	e9 04 f8 ff ff       	jmp    80107694 <alltraps>

80107e90 <vector42>:
.globl vector42
vector42:
  pushl $0
80107e90:	6a 00                	push   $0x0
  pushl $42
80107e92:	6a 2a                	push   $0x2a
  jmp alltraps
80107e94:	e9 fb f7 ff ff       	jmp    80107694 <alltraps>

80107e99 <vector43>:
.globl vector43
vector43:
  pushl $0
80107e99:	6a 00                	push   $0x0
  pushl $43
80107e9b:	6a 2b                	push   $0x2b
  jmp alltraps
80107e9d:	e9 f2 f7 ff ff       	jmp    80107694 <alltraps>

80107ea2 <vector44>:
.globl vector44
vector44:
  pushl $0
80107ea2:	6a 00                	push   $0x0
  pushl $44
80107ea4:	6a 2c                	push   $0x2c
  jmp alltraps
80107ea6:	e9 e9 f7 ff ff       	jmp    80107694 <alltraps>

80107eab <vector45>:
.globl vector45
vector45:
  pushl $0
80107eab:	6a 00                	push   $0x0
  pushl $45
80107ead:	6a 2d                	push   $0x2d
  jmp alltraps
80107eaf:	e9 e0 f7 ff ff       	jmp    80107694 <alltraps>

80107eb4 <vector46>:
.globl vector46
vector46:
  pushl $0
80107eb4:	6a 00                	push   $0x0
  pushl $46
80107eb6:	6a 2e                	push   $0x2e
  jmp alltraps
80107eb8:	e9 d7 f7 ff ff       	jmp    80107694 <alltraps>

80107ebd <vector47>:
.globl vector47
vector47:
  pushl $0
80107ebd:	6a 00                	push   $0x0
  pushl $47
80107ebf:	6a 2f                	push   $0x2f
  jmp alltraps
80107ec1:	e9 ce f7 ff ff       	jmp    80107694 <alltraps>

80107ec6 <vector48>:
.globl vector48
vector48:
  pushl $0
80107ec6:	6a 00                	push   $0x0
  pushl $48
80107ec8:	6a 30                	push   $0x30
  jmp alltraps
80107eca:	e9 c5 f7 ff ff       	jmp    80107694 <alltraps>

80107ecf <vector49>:
.globl vector49
vector49:
  pushl $0
80107ecf:	6a 00                	push   $0x0
  pushl $49
80107ed1:	6a 31                	push   $0x31
  jmp alltraps
80107ed3:	e9 bc f7 ff ff       	jmp    80107694 <alltraps>

80107ed8 <vector50>:
.globl vector50
vector50:
  pushl $0
80107ed8:	6a 00                	push   $0x0
  pushl $50
80107eda:	6a 32                	push   $0x32
  jmp alltraps
80107edc:	e9 b3 f7 ff ff       	jmp    80107694 <alltraps>

80107ee1 <vector51>:
.globl vector51
vector51:
  pushl $0
80107ee1:	6a 00                	push   $0x0
  pushl $51
80107ee3:	6a 33                	push   $0x33
  jmp alltraps
80107ee5:	e9 aa f7 ff ff       	jmp    80107694 <alltraps>

80107eea <vector52>:
.globl vector52
vector52:
  pushl $0
80107eea:	6a 00                	push   $0x0
  pushl $52
80107eec:	6a 34                	push   $0x34
  jmp alltraps
80107eee:	e9 a1 f7 ff ff       	jmp    80107694 <alltraps>

80107ef3 <vector53>:
.globl vector53
vector53:
  pushl $0
80107ef3:	6a 00                	push   $0x0
  pushl $53
80107ef5:	6a 35                	push   $0x35
  jmp alltraps
80107ef7:	e9 98 f7 ff ff       	jmp    80107694 <alltraps>

80107efc <vector54>:
.globl vector54
vector54:
  pushl $0
80107efc:	6a 00                	push   $0x0
  pushl $54
80107efe:	6a 36                	push   $0x36
  jmp alltraps
80107f00:	e9 8f f7 ff ff       	jmp    80107694 <alltraps>

80107f05 <vector55>:
.globl vector55
vector55:
  pushl $0
80107f05:	6a 00                	push   $0x0
  pushl $55
80107f07:	6a 37                	push   $0x37
  jmp alltraps
80107f09:	e9 86 f7 ff ff       	jmp    80107694 <alltraps>

80107f0e <vector56>:
.globl vector56
vector56:
  pushl $0
80107f0e:	6a 00                	push   $0x0
  pushl $56
80107f10:	6a 38                	push   $0x38
  jmp alltraps
80107f12:	e9 7d f7 ff ff       	jmp    80107694 <alltraps>

80107f17 <vector57>:
.globl vector57
vector57:
  pushl $0
80107f17:	6a 00                	push   $0x0
  pushl $57
80107f19:	6a 39                	push   $0x39
  jmp alltraps
80107f1b:	e9 74 f7 ff ff       	jmp    80107694 <alltraps>

80107f20 <vector58>:
.globl vector58
vector58:
  pushl $0
80107f20:	6a 00                	push   $0x0
  pushl $58
80107f22:	6a 3a                	push   $0x3a
  jmp alltraps
80107f24:	e9 6b f7 ff ff       	jmp    80107694 <alltraps>

80107f29 <vector59>:
.globl vector59
vector59:
  pushl $0
80107f29:	6a 00                	push   $0x0
  pushl $59
80107f2b:	6a 3b                	push   $0x3b
  jmp alltraps
80107f2d:	e9 62 f7 ff ff       	jmp    80107694 <alltraps>

80107f32 <vector60>:
.globl vector60
vector60:
  pushl $0
80107f32:	6a 00                	push   $0x0
  pushl $60
80107f34:	6a 3c                	push   $0x3c
  jmp alltraps
80107f36:	e9 59 f7 ff ff       	jmp    80107694 <alltraps>

80107f3b <vector61>:
.globl vector61
vector61:
  pushl $0
80107f3b:	6a 00                	push   $0x0
  pushl $61
80107f3d:	6a 3d                	push   $0x3d
  jmp alltraps
80107f3f:	e9 50 f7 ff ff       	jmp    80107694 <alltraps>

80107f44 <vector62>:
.globl vector62
vector62:
  pushl $0
80107f44:	6a 00                	push   $0x0
  pushl $62
80107f46:	6a 3e                	push   $0x3e
  jmp alltraps
80107f48:	e9 47 f7 ff ff       	jmp    80107694 <alltraps>

80107f4d <vector63>:
.globl vector63
vector63:
  pushl $0
80107f4d:	6a 00                	push   $0x0
  pushl $63
80107f4f:	6a 3f                	push   $0x3f
  jmp alltraps
80107f51:	e9 3e f7 ff ff       	jmp    80107694 <alltraps>

80107f56 <vector64>:
.globl vector64
vector64:
  pushl $0
80107f56:	6a 00                	push   $0x0
  pushl $64
80107f58:	6a 40                	push   $0x40
  jmp alltraps
80107f5a:	e9 35 f7 ff ff       	jmp    80107694 <alltraps>

80107f5f <vector65>:
.globl vector65
vector65:
  pushl $0
80107f5f:	6a 00                	push   $0x0
  pushl $65
80107f61:	6a 41                	push   $0x41
  jmp alltraps
80107f63:	e9 2c f7 ff ff       	jmp    80107694 <alltraps>

80107f68 <vector66>:
.globl vector66
vector66:
  pushl $0
80107f68:	6a 00                	push   $0x0
  pushl $66
80107f6a:	6a 42                	push   $0x42
  jmp alltraps
80107f6c:	e9 23 f7 ff ff       	jmp    80107694 <alltraps>

80107f71 <vector67>:
.globl vector67
vector67:
  pushl $0
80107f71:	6a 00                	push   $0x0
  pushl $67
80107f73:	6a 43                	push   $0x43
  jmp alltraps
80107f75:	e9 1a f7 ff ff       	jmp    80107694 <alltraps>

80107f7a <vector68>:
.globl vector68
vector68:
  pushl $0
80107f7a:	6a 00                	push   $0x0
  pushl $68
80107f7c:	6a 44                	push   $0x44
  jmp alltraps
80107f7e:	e9 11 f7 ff ff       	jmp    80107694 <alltraps>

80107f83 <vector69>:
.globl vector69
vector69:
  pushl $0
80107f83:	6a 00                	push   $0x0
  pushl $69
80107f85:	6a 45                	push   $0x45
  jmp alltraps
80107f87:	e9 08 f7 ff ff       	jmp    80107694 <alltraps>

80107f8c <vector70>:
.globl vector70
vector70:
  pushl $0
80107f8c:	6a 00                	push   $0x0
  pushl $70
80107f8e:	6a 46                	push   $0x46
  jmp alltraps
80107f90:	e9 ff f6 ff ff       	jmp    80107694 <alltraps>

80107f95 <vector71>:
.globl vector71
vector71:
  pushl $0
80107f95:	6a 00                	push   $0x0
  pushl $71
80107f97:	6a 47                	push   $0x47
  jmp alltraps
80107f99:	e9 f6 f6 ff ff       	jmp    80107694 <alltraps>

80107f9e <vector72>:
.globl vector72
vector72:
  pushl $0
80107f9e:	6a 00                	push   $0x0
  pushl $72
80107fa0:	6a 48                	push   $0x48
  jmp alltraps
80107fa2:	e9 ed f6 ff ff       	jmp    80107694 <alltraps>

80107fa7 <vector73>:
.globl vector73
vector73:
  pushl $0
80107fa7:	6a 00                	push   $0x0
  pushl $73
80107fa9:	6a 49                	push   $0x49
  jmp alltraps
80107fab:	e9 e4 f6 ff ff       	jmp    80107694 <alltraps>

80107fb0 <vector74>:
.globl vector74
vector74:
  pushl $0
80107fb0:	6a 00                	push   $0x0
  pushl $74
80107fb2:	6a 4a                	push   $0x4a
  jmp alltraps
80107fb4:	e9 db f6 ff ff       	jmp    80107694 <alltraps>

80107fb9 <vector75>:
.globl vector75
vector75:
  pushl $0
80107fb9:	6a 00                	push   $0x0
  pushl $75
80107fbb:	6a 4b                	push   $0x4b
  jmp alltraps
80107fbd:	e9 d2 f6 ff ff       	jmp    80107694 <alltraps>

80107fc2 <vector76>:
.globl vector76
vector76:
  pushl $0
80107fc2:	6a 00                	push   $0x0
  pushl $76
80107fc4:	6a 4c                	push   $0x4c
  jmp alltraps
80107fc6:	e9 c9 f6 ff ff       	jmp    80107694 <alltraps>

80107fcb <vector77>:
.globl vector77
vector77:
  pushl $0
80107fcb:	6a 00                	push   $0x0
  pushl $77
80107fcd:	6a 4d                	push   $0x4d
  jmp alltraps
80107fcf:	e9 c0 f6 ff ff       	jmp    80107694 <alltraps>

80107fd4 <vector78>:
.globl vector78
vector78:
  pushl $0
80107fd4:	6a 00                	push   $0x0
  pushl $78
80107fd6:	6a 4e                	push   $0x4e
  jmp alltraps
80107fd8:	e9 b7 f6 ff ff       	jmp    80107694 <alltraps>

80107fdd <vector79>:
.globl vector79
vector79:
  pushl $0
80107fdd:	6a 00                	push   $0x0
  pushl $79
80107fdf:	6a 4f                	push   $0x4f
  jmp alltraps
80107fe1:	e9 ae f6 ff ff       	jmp    80107694 <alltraps>

80107fe6 <vector80>:
.globl vector80
vector80:
  pushl $0
80107fe6:	6a 00                	push   $0x0
  pushl $80
80107fe8:	6a 50                	push   $0x50
  jmp alltraps
80107fea:	e9 a5 f6 ff ff       	jmp    80107694 <alltraps>

80107fef <vector81>:
.globl vector81
vector81:
  pushl $0
80107fef:	6a 00                	push   $0x0
  pushl $81
80107ff1:	6a 51                	push   $0x51
  jmp alltraps
80107ff3:	e9 9c f6 ff ff       	jmp    80107694 <alltraps>

80107ff8 <vector82>:
.globl vector82
vector82:
  pushl $0
80107ff8:	6a 00                	push   $0x0
  pushl $82
80107ffa:	6a 52                	push   $0x52
  jmp alltraps
80107ffc:	e9 93 f6 ff ff       	jmp    80107694 <alltraps>

80108001 <vector83>:
.globl vector83
vector83:
  pushl $0
80108001:	6a 00                	push   $0x0
  pushl $83
80108003:	6a 53                	push   $0x53
  jmp alltraps
80108005:	e9 8a f6 ff ff       	jmp    80107694 <alltraps>

8010800a <vector84>:
.globl vector84
vector84:
  pushl $0
8010800a:	6a 00                	push   $0x0
  pushl $84
8010800c:	6a 54                	push   $0x54
  jmp alltraps
8010800e:	e9 81 f6 ff ff       	jmp    80107694 <alltraps>

80108013 <vector85>:
.globl vector85
vector85:
  pushl $0
80108013:	6a 00                	push   $0x0
  pushl $85
80108015:	6a 55                	push   $0x55
  jmp alltraps
80108017:	e9 78 f6 ff ff       	jmp    80107694 <alltraps>

8010801c <vector86>:
.globl vector86
vector86:
  pushl $0
8010801c:	6a 00                	push   $0x0
  pushl $86
8010801e:	6a 56                	push   $0x56
  jmp alltraps
80108020:	e9 6f f6 ff ff       	jmp    80107694 <alltraps>

80108025 <vector87>:
.globl vector87
vector87:
  pushl $0
80108025:	6a 00                	push   $0x0
  pushl $87
80108027:	6a 57                	push   $0x57
  jmp alltraps
80108029:	e9 66 f6 ff ff       	jmp    80107694 <alltraps>

8010802e <vector88>:
.globl vector88
vector88:
  pushl $0
8010802e:	6a 00                	push   $0x0
  pushl $88
80108030:	6a 58                	push   $0x58
  jmp alltraps
80108032:	e9 5d f6 ff ff       	jmp    80107694 <alltraps>

80108037 <vector89>:
.globl vector89
vector89:
  pushl $0
80108037:	6a 00                	push   $0x0
  pushl $89
80108039:	6a 59                	push   $0x59
  jmp alltraps
8010803b:	e9 54 f6 ff ff       	jmp    80107694 <alltraps>

80108040 <vector90>:
.globl vector90
vector90:
  pushl $0
80108040:	6a 00                	push   $0x0
  pushl $90
80108042:	6a 5a                	push   $0x5a
  jmp alltraps
80108044:	e9 4b f6 ff ff       	jmp    80107694 <alltraps>

80108049 <vector91>:
.globl vector91
vector91:
  pushl $0
80108049:	6a 00                	push   $0x0
  pushl $91
8010804b:	6a 5b                	push   $0x5b
  jmp alltraps
8010804d:	e9 42 f6 ff ff       	jmp    80107694 <alltraps>

80108052 <vector92>:
.globl vector92
vector92:
  pushl $0
80108052:	6a 00                	push   $0x0
  pushl $92
80108054:	6a 5c                	push   $0x5c
  jmp alltraps
80108056:	e9 39 f6 ff ff       	jmp    80107694 <alltraps>

8010805b <vector93>:
.globl vector93
vector93:
  pushl $0
8010805b:	6a 00                	push   $0x0
  pushl $93
8010805d:	6a 5d                	push   $0x5d
  jmp alltraps
8010805f:	e9 30 f6 ff ff       	jmp    80107694 <alltraps>

80108064 <vector94>:
.globl vector94
vector94:
  pushl $0
80108064:	6a 00                	push   $0x0
  pushl $94
80108066:	6a 5e                	push   $0x5e
  jmp alltraps
80108068:	e9 27 f6 ff ff       	jmp    80107694 <alltraps>

8010806d <vector95>:
.globl vector95
vector95:
  pushl $0
8010806d:	6a 00                	push   $0x0
  pushl $95
8010806f:	6a 5f                	push   $0x5f
  jmp alltraps
80108071:	e9 1e f6 ff ff       	jmp    80107694 <alltraps>

80108076 <vector96>:
.globl vector96
vector96:
  pushl $0
80108076:	6a 00                	push   $0x0
  pushl $96
80108078:	6a 60                	push   $0x60
  jmp alltraps
8010807a:	e9 15 f6 ff ff       	jmp    80107694 <alltraps>

8010807f <vector97>:
.globl vector97
vector97:
  pushl $0
8010807f:	6a 00                	push   $0x0
  pushl $97
80108081:	6a 61                	push   $0x61
  jmp alltraps
80108083:	e9 0c f6 ff ff       	jmp    80107694 <alltraps>

80108088 <vector98>:
.globl vector98
vector98:
  pushl $0
80108088:	6a 00                	push   $0x0
  pushl $98
8010808a:	6a 62                	push   $0x62
  jmp alltraps
8010808c:	e9 03 f6 ff ff       	jmp    80107694 <alltraps>

80108091 <vector99>:
.globl vector99
vector99:
  pushl $0
80108091:	6a 00                	push   $0x0
  pushl $99
80108093:	6a 63                	push   $0x63
  jmp alltraps
80108095:	e9 fa f5 ff ff       	jmp    80107694 <alltraps>

8010809a <vector100>:
.globl vector100
vector100:
  pushl $0
8010809a:	6a 00                	push   $0x0
  pushl $100
8010809c:	6a 64                	push   $0x64
  jmp alltraps
8010809e:	e9 f1 f5 ff ff       	jmp    80107694 <alltraps>

801080a3 <vector101>:
.globl vector101
vector101:
  pushl $0
801080a3:	6a 00                	push   $0x0
  pushl $101
801080a5:	6a 65                	push   $0x65
  jmp alltraps
801080a7:	e9 e8 f5 ff ff       	jmp    80107694 <alltraps>

801080ac <vector102>:
.globl vector102
vector102:
  pushl $0
801080ac:	6a 00                	push   $0x0
  pushl $102
801080ae:	6a 66                	push   $0x66
  jmp alltraps
801080b0:	e9 df f5 ff ff       	jmp    80107694 <alltraps>

801080b5 <vector103>:
.globl vector103
vector103:
  pushl $0
801080b5:	6a 00                	push   $0x0
  pushl $103
801080b7:	6a 67                	push   $0x67
  jmp alltraps
801080b9:	e9 d6 f5 ff ff       	jmp    80107694 <alltraps>

801080be <vector104>:
.globl vector104
vector104:
  pushl $0
801080be:	6a 00                	push   $0x0
  pushl $104
801080c0:	6a 68                	push   $0x68
  jmp alltraps
801080c2:	e9 cd f5 ff ff       	jmp    80107694 <alltraps>

801080c7 <vector105>:
.globl vector105
vector105:
  pushl $0
801080c7:	6a 00                	push   $0x0
  pushl $105
801080c9:	6a 69                	push   $0x69
  jmp alltraps
801080cb:	e9 c4 f5 ff ff       	jmp    80107694 <alltraps>

801080d0 <vector106>:
.globl vector106
vector106:
  pushl $0
801080d0:	6a 00                	push   $0x0
  pushl $106
801080d2:	6a 6a                	push   $0x6a
  jmp alltraps
801080d4:	e9 bb f5 ff ff       	jmp    80107694 <alltraps>

801080d9 <vector107>:
.globl vector107
vector107:
  pushl $0
801080d9:	6a 00                	push   $0x0
  pushl $107
801080db:	6a 6b                	push   $0x6b
  jmp alltraps
801080dd:	e9 b2 f5 ff ff       	jmp    80107694 <alltraps>

801080e2 <vector108>:
.globl vector108
vector108:
  pushl $0
801080e2:	6a 00                	push   $0x0
  pushl $108
801080e4:	6a 6c                	push   $0x6c
  jmp alltraps
801080e6:	e9 a9 f5 ff ff       	jmp    80107694 <alltraps>

801080eb <vector109>:
.globl vector109
vector109:
  pushl $0
801080eb:	6a 00                	push   $0x0
  pushl $109
801080ed:	6a 6d                	push   $0x6d
  jmp alltraps
801080ef:	e9 a0 f5 ff ff       	jmp    80107694 <alltraps>

801080f4 <vector110>:
.globl vector110
vector110:
  pushl $0
801080f4:	6a 00                	push   $0x0
  pushl $110
801080f6:	6a 6e                	push   $0x6e
  jmp alltraps
801080f8:	e9 97 f5 ff ff       	jmp    80107694 <alltraps>

801080fd <vector111>:
.globl vector111
vector111:
  pushl $0
801080fd:	6a 00                	push   $0x0
  pushl $111
801080ff:	6a 6f                	push   $0x6f
  jmp alltraps
80108101:	e9 8e f5 ff ff       	jmp    80107694 <alltraps>

80108106 <vector112>:
.globl vector112
vector112:
  pushl $0
80108106:	6a 00                	push   $0x0
  pushl $112
80108108:	6a 70                	push   $0x70
  jmp alltraps
8010810a:	e9 85 f5 ff ff       	jmp    80107694 <alltraps>

8010810f <vector113>:
.globl vector113
vector113:
  pushl $0
8010810f:	6a 00                	push   $0x0
  pushl $113
80108111:	6a 71                	push   $0x71
  jmp alltraps
80108113:	e9 7c f5 ff ff       	jmp    80107694 <alltraps>

80108118 <vector114>:
.globl vector114
vector114:
  pushl $0
80108118:	6a 00                	push   $0x0
  pushl $114
8010811a:	6a 72                	push   $0x72
  jmp alltraps
8010811c:	e9 73 f5 ff ff       	jmp    80107694 <alltraps>

80108121 <vector115>:
.globl vector115
vector115:
  pushl $0
80108121:	6a 00                	push   $0x0
  pushl $115
80108123:	6a 73                	push   $0x73
  jmp alltraps
80108125:	e9 6a f5 ff ff       	jmp    80107694 <alltraps>

8010812a <vector116>:
.globl vector116
vector116:
  pushl $0
8010812a:	6a 00                	push   $0x0
  pushl $116
8010812c:	6a 74                	push   $0x74
  jmp alltraps
8010812e:	e9 61 f5 ff ff       	jmp    80107694 <alltraps>

80108133 <vector117>:
.globl vector117
vector117:
  pushl $0
80108133:	6a 00                	push   $0x0
  pushl $117
80108135:	6a 75                	push   $0x75
  jmp alltraps
80108137:	e9 58 f5 ff ff       	jmp    80107694 <alltraps>

8010813c <vector118>:
.globl vector118
vector118:
  pushl $0
8010813c:	6a 00                	push   $0x0
  pushl $118
8010813e:	6a 76                	push   $0x76
  jmp alltraps
80108140:	e9 4f f5 ff ff       	jmp    80107694 <alltraps>

80108145 <vector119>:
.globl vector119
vector119:
  pushl $0
80108145:	6a 00                	push   $0x0
  pushl $119
80108147:	6a 77                	push   $0x77
  jmp alltraps
80108149:	e9 46 f5 ff ff       	jmp    80107694 <alltraps>

8010814e <vector120>:
.globl vector120
vector120:
  pushl $0
8010814e:	6a 00                	push   $0x0
  pushl $120
80108150:	6a 78                	push   $0x78
  jmp alltraps
80108152:	e9 3d f5 ff ff       	jmp    80107694 <alltraps>

80108157 <vector121>:
.globl vector121
vector121:
  pushl $0
80108157:	6a 00                	push   $0x0
  pushl $121
80108159:	6a 79                	push   $0x79
  jmp alltraps
8010815b:	e9 34 f5 ff ff       	jmp    80107694 <alltraps>

80108160 <vector122>:
.globl vector122
vector122:
  pushl $0
80108160:	6a 00                	push   $0x0
  pushl $122
80108162:	6a 7a                	push   $0x7a
  jmp alltraps
80108164:	e9 2b f5 ff ff       	jmp    80107694 <alltraps>

80108169 <vector123>:
.globl vector123
vector123:
  pushl $0
80108169:	6a 00                	push   $0x0
  pushl $123
8010816b:	6a 7b                	push   $0x7b
  jmp alltraps
8010816d:	e9 22 f5 ff ff       	jmp    80107694 <alltraps>

80108172 <vector124>:
.globl vector124
vector124:
  pushl $0
80108172:	6a 00                	push   $0x0
  pushl $124
80108174:	6a 7c                	push   $0x7c
  jmp alltraps
80108176:	e9 19 f5 ff ff       	jmp    80107694 <alltraps>

8010817b <vector125>:
.globl vector125
vector125:
  pushl $0
8010817b:	6a 00                	push   $0x0
  pushl $125
8010817d:	6a 7d                	push   $0x7d
  jmp alltraps
8010817f:	e9 10 f5 ff ff       	jmp    80107694 <alltraps>

80108184 <vector126>:
.globl vector126
vector126:
  pushl $0
80108184:	6a 00                	push   $0x0
  pushl $126
80108186:	6a 7e                	push   $0x7e
  jmp alltraps
80108188:	e9 07 f5 ff ff       	jmp    80107694 <alltraps>

8010818d <vector127>:
.globl vector127
vector127:
  pushl $0
8010818d:	6a 00                	push   $0x0
  pushl $127
8010818f:	6a 7f                	push   $0x7f
  jmp alltraps
80108191:	e9 fe f4 ff ff       	jmp    80107694 <alltraps>

80108196 <vector128>:
.globl vector128
vector128:
  pushl $0
80108196:	6a 00                	push   $0x0
  pushl $128
80108198:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010819d:	e9 f2 f4 ff ff       	jmp    80107694 <alltraps>

801081a2 <vector129>:
.globl vector129
vector129:
  pushl $0
801081a2:	6a 00                	push   $0x0
  pushl $129
801081a4:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801081a9:	e9 e6 f4 ff ff       	jmp    80107694 <alltraps>

801081ae <vector130>:
.globl vector130
vector130:
  pushl $0
801081ae:	6a 00                	push   $0x0
  pushl $130
801081b0:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801081b5:	e9 da f4 ff ff       	jmp    80107694 <alltraps>

801081ba <vector131>:
.globl vector131
vector131:
  pushl $0
801081ba:	6a 00                	push   $0x0
  pushl $131
801081bc:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801081c1:	e9 ce f4 ff ff       	jmp    80107694 <alltraps>

801081c6 <vector132>:
.globl vector132
vector132:
  pushl $0
801081c6:	6a 00                	push   $0x0
  pushl $132
801081c8:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801081cd:	e9 c2 f4 ff ff       	jmp    80107694 <alltraps>

801081d2 <vector133>:
.globl vector133
vector133:
  pushl $0
801081d2:	6a 00                	push   $0x0
  pushl $133
801081d4:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801081d9:	e9 b6 f4 ff ff       	jmp    80107694 <alltraps>

801081de <vector134>:
.globl vector134
vector134:
  pushl $0
801081de:	6a 00                	push   $0x0
  pushl $134
801081e0:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801081e5:	e9 aa f4 ff ff       	jmp    80107694 <alltraps>

801081ea <vector135>:
.globl vector135
vector135:
  pushl $0
801081ea:	6a 00                	push   $0x0
  pushl $135
801081ec:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801081f1:	e9 9e f4 ff ff       	jmp    80107694 <alltraps>

801081f6 <vector136>:
.globl vector136
vector136:
  pushl $0
801081f6:	6a 00                	push   $0x0
  pushl $136
801081f8:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801081fd:	e9 92 f4 ff ff       	jmp    80107694 <alltraps>

80108202 <vector137>:
.globl vector137
vector137:
  pushl $0
80108202:	6a 00                	push   $0x0
  pushl $137
80108204:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80108209:	e9 86 f4 ff ff       	jmp    80107694 <alltraps>

8010820e <vector138>:
.globl vector138
vector138:
  pushl $0
8010820e:	6a 00                	push   $0x0
  pushl $138
80108210:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80108215:	e9 7a f4 ff ff       	jmp    80107694 <alltraps>

8010821a <vector139>:
.globl vector139
vector139:
  pushl $0
8010821a:	6a 00                	push   $0x0
  pushl $139
8010821c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80108221:	e9 6e f4 ff ff       	jmp    80107694 <alltraps>

80108226 <vector140>:
.globl vector140
vector140:
  pushl $0
80108226:	6a 00                	push   $0x0
  pushl $140
80108228:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010822d:	e9 62 f4 ff ff       	jmp    80107694 <alltraps>

80108232 <vector141>:
.globl vector141
vector141:
  pushl $0
80108232:	6a 00                	push   $0x0
  pushl $141
80108234:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80108239:	e9 56 f4 ff ff       	jmp    80107694 <alltraps>

8010823e <vector142>:
.globl vector142
vector142:
  pushl $0
8010823e:	6a 00                	push   $0x0
  pushl $142
80108240:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108245:	e9 4a f4 ff ff       	jmp    80107694 <alltraps>

8010824a <vector143>:
.globl vector143
vector143:
  pushl $0
8010824a:	6a 00                	push   $0x0
  pushl $143
8010824c:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80108251:	e9 3e f4 ff ff       	jmp    80107694 <alltraps>

80108256 <vector144>:
.globl vector144
vector144:
  pushl $0
80108256:	6a 00                	push   $0x0
  pushl $144
80108258:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010825d:	e9 32 f4 ff ff       	jmp    80107694 <alltraps>

80108262 <vector145>:
.globl vector145
vector145:
  pushl $0
80108262:	6a 00                	push   $0x0
  pushl $145
80108264:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108269:	e9 26 f4 ff ff       	jmp    80107694 <alltraps>

8010826e <vector146>:
.globl vector146
vector146:
  pushl $0
8010826e:	6a 00                	push   $0x0
  pushl $146
80108270:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80108275:	e9 1a f4 ff ff       	jmp    80107694 <alltraps>

8010827a <vector147>:
.globl vector147
vector147:
  pushl $0
8010827a:	6a 00                	push   $0x0
  pushl $147
8010827c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80108281:	e9 0e f4 ff ff       	jmp    80107694 <alltraps>

80108286 <vector148>:
.globl vector148
vector148:
  pushl $0
80108286:	6a 00                	push   $0x0
  pushl $148
80108288:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010828d:	e9 02 f4 ff ff       	jmp    80107694 <alltraps>

80108292 <vector149>:
.globl vector149
vector149:
  pushl $0
80108292:	6a 00                	push   $0x0
  pushl $149
80108294:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80108299:	e9 f6 f3 ff ff       	jmp    80107694 <alltraps>

8010829e <vector150>:
.globl vector150
vector150:
  pushl $0
8010829e:	6a 00                	push   $0x0
  pushl $150
801082a0:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801082a5:	e9 ea f3 ff ff       	jmp    80107694 <alltraps>

801082aa <vector151>:
.globl vector151
vector151:
  pushl $0
801082aa:	6a 00                	push   $0x0
  pushl $151
801082ac:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801082b1:	e9 de f3 ff ff       	jmp    80107694 <alltraps>

801082b6 <vector152>:
.globl vector152
vector152:
  pushl $0
801082b6:	6a 00                	push   $0x0
  pushl $152
801082b8:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801082bd:	e9 d2 f3 ff ff       	jmp    80107694 <alltraps>

801082c2 <vector153>:
.globl vector153
vector153:
  pushl $0
801082c2:	6a 00                	push   $0x0
  pushl $153
801082c4:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801082c9:	e9 c6 f3 ff ff       	jmp    80107694 <alltraps>

801082ce <vector154>:
.globl vector154
vector154:
  pushl $0
801082ce:	6a 00                	push   $0x0
  pushl $154
801082d0:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801082d5:	e9 ba f3 ff ff       	jmp    80107694 <alltraps>

801082da <vector155>:
.globl vector155
vector155:
  pushl $0
801082da:	6a 00                	push   $0x0
  pushl $155
801082dc:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801082e1:	e9 ae f3 ff ff       	jmp    80107694 <alltraps>

801082e6 <vector156>:
.globl vector156
vector156:
  pushl $0
801082e6:	6a 00                	push   $0x0
  pushl $156
801082e8:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801082ed:	e9 a2 f3 ff ff       	jmp    80107694 <alltraps>

801082f2 <vector157>:
.globl vector157
vector157:
  pushl $0
801082f2:	6a 00                	push   $0x0
  pushl $157
801082f4:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801082f9:	e9 96 f3 ff ff       	jmp    80107694 <alltraps>

801082fe <vector158>:
.globl vector158
vector158:
  pushl $0
801082fe:	6a 00                	push   $0x0
  pushl $158
80108300:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80108305:	e9 8a f3 ff ff       	jmp    80107694 <alltraps>

8010830a <vector159>:
.globl vector159
vector159:
  pushl $0
8010830a:	6a 00                	push   $0x0
  pushl $159
8010830c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80108311:	e9 7e f3 ff ff       	jmp    80107694 <alltraps>

80108316 <vector160>:
.globl vector160
vector160:
  pushl $0
80108316:	6a 00                	push   $0x0
  pushl $160
80108318:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010831d:	e9 72 f3 ff ff       	jmp    80107694 <alltraps>

80108322 <vector161>:
.globl vector161
vector161:
  pushl $0
80108322:	6a 00                	push   $0x0
  pushl $161
80108324:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80108329:	e9 66 f3 ff ff       	jmp    80107694 <alltraps>

8010832e <vector162>:
.globl vector162
vector162:
  pushl $0
8010832e:	6a 00                	push   $0x0
  pushl $162
80108330:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80108335:	e9 5a f3 ff ff       	jmp    80107694 <alltraps>

8010833a <vector163>:
.globl vector163
vector163:
  pushl $0
8010833a:	6a 00                	push   $0x0
  pushl $163
8010833c:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80108341:	e9 4e f3 ff ff       	jmp    80107694 <alltraps>

80108346 <vector164>:
.globl vector164
vector164:
  pushl $0
80108346:	6a 00                	push   $0x0
  pushl $164
80108348:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010834d:	e9 42 f3 ff ff       	jmp    80107694 <alltraps>

80108352 <vector165>:
.globl vector165
vector165:
  pushl $0
80108352:	6a 00                	push   $0x0
  pushl $165
80108354:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108359:	e9 36 f3 ff ff       	jmp    80107694 <alltraps>

8010835e <vector166>:
.globl vector166
vector166:
  pushl $0
8010835e:	6a 00                	push   $0x0
  pushl $166
80108360:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108365:	e9 2a f3 ff ff       	jmp    80107694 <alltraps>

8010836a <vector167>:
.globl vector167
vector167:
  pushl $0
8010836a:	6a 00                	push   $0x0
  pushl $167
8010836c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80108371:	e9 1e f3 ff ff       	jmp    80107694 <alltraps>

80108376 <vector168>:
.globl vector168
vector168:
  pushl $0
80108376:	6a 00                	push   $0x0
  pushl $168
80108378:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010837d:	e9 12 f3 ff ff       	jmp    80107694 <alltraps>

80108382 <vector169>:
.globl vector169
vector169:
  pushl $0
80108382:	6a 00                	push   $0x0
  pushl $169
80108384:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80108389:	e9 06 f3 ff ff       	jmp    80107694 <alltraps>

8010838e <vector170>:
.globl vector170
vector170:
  pushl $0
8010838e:	6a 00                	push   $0x0
  pushl $170
80108390:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80108395:	e9 fa f2 ff ff       	jmp    80107694 <alltraps>

8010839a <vector171>:
.globl vector171
vector171:
  pushl $0
8010839a:	6a 00                	push   $0x0
  pushl $171
8010839c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801083a1:	e9 ee f2 ff ff       	jmp    80107694 <alltraps>

801083a6 <vector172>:
.globl vector172
vector172:
  pushl $0
801083a6:	6a 00                	push   $0x0
  pushl $172
801083a8:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801083ad:	e9 e2 f2 ff ff       	jmp    80107694 <alltraps>

801083b2 <vector173>:
.globl vector173
vector173:
  pushl $0
801083b2:	6a 00                	push   $0x0
  pushl $173
801083b4:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801083b9:	e9 d6 f2 ff ff       	jmp    80107694 <alltraps>

801083be <vector174>:
.globl vector174
vector174:
  pushl $0
801083be:	6a 00                	push   $0x0
  pushl $174
801083c0:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801083c5:	e9 ca f2 ff ff       	jmp    80107694 <alltraps>

801083ca <vector175>:
.globl vector175
vector175:
  pushl $0
801083ca:	6a 00                	push   $0x0
  pushl $175
801083cc:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801083d1:	e9 be f2 ff ff       	jmp    80107694 <alltraps>

801083d6 <vector176>:
.globl vector176
vector176:
  pushl $0
801083d6:	6a 00                	push   $0x0
  pushl $176
801083d8:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801083dd:	e9 b2 f2 ff ff       	jmp    80107694 <alltraps>

801083e2 <vector177>:
.globl vector177
vector177:
  pushl $0
801083e2:	6a 00                	push   $0x0
  pushl $177
801083e4:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801083e9:	e9 a6 f2 ff ff       	jmp    80107694 <alltraps>

801083ee <vector178>:
.globl vector178
vector178:
  pushl $0
801083ee:	6a 00                	push   $0x0
  pushl $178
801083f0:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801083f5:	e9 9a f2 ff ff       	jmp    80107694 <alltraps>

801083fa <vector179>:
.globl vector179
vector179:
  pushl $0
801083fa:	6a 00                	push   $0x0
  pushl $179
801083fc:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80108401:	e9 8e f2 ff ff       	jmp    80107694 <alltraps>

80108406 <vector180>:
.globl vector180
vector180:
  pushl $0
80108406:	6a 00                	push   $0x0
  pushl $180
80108408:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010840d:	e9 82 f2 ff ff       	jmp    80107694 <alltraps>

80108412 <vector181>:
.globl vector181
vector181:
  pushl $0
80108412:	6a 00                	push   $0x0
  pushl $181
80108414:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80108419:	e9 76 f2 ff ff       	jmp    80107694 <alltraps>

8010841e <vector182>:
.globl vector182
vector182:
  pushl $0
8010841e:	6a 00                	push   $0x0
  pushl $182
80108420:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80108425:	e9 6a f2 ff ff       	jmp    80107694 <alltraps>

8010842a <vector183>:
.globl vector183
vector183:
  pushl $0
8010842a:	6a 00                	push   $0x0
  pushl $183
8010842c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80108431:	e9 5e f2 ff ff       	jmp    80107694 <alltraps>

80108436 <vector184>:
.globl vector184
vector184:
  pushl $0
80108436:	6a 00                	push   $0x0
  pushl $184
80108438:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010843d:	e9 52 f2 ff ff       	jmp    80107694 <alltraps>

80108442 <vector185>:
.globl vector185
vector185:
  pushl $0
80108442:	6a 00                	push   $0x0
  pushl $185
80108444:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108449:	e9 46 f2 ff ff       	jmp    80107694 <alltraps>

8010844e <vector186>:
.globl vector186
vector186:
  pushl $0
8010844e:	6a 00                	push   $0x0
  pushl $186
80108450:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108455:	e9 3a f2 ff ff       	jmp    80107694 <alltraps>

8010845a <vector187>:
.globl vector187
vector187:
  pushl $0
8010845a:	6a 00                	push   $0x0
  pushl $187
8010845c:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80108461:	e9 2e f2 ff ff       	jmp    80107694 <alltraps>

80108466 <vector188>:
.globl vector188
vector188:
  pushl $0
80108466:	6a 00                	push   $0x0
  pushl $188
80108468:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010846d:	e9 22 f2 ff ff       	jmp    80107694 <alltraps>

80108472 <vector189>:
.globl vector189
vector189:
  pushl $0
80108472:	6a 00                	push   $0x0
  pushl $189
80108474:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108479:	e9 16 f2 ff ff       	jmp    80107694 <alltraps>

8010847e <vector190>:
.globl vector190
vector190:
  pushl $0
8010847e:	6a 00                	push   $0x0
  pushl $190
80108480:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108485:	e9 0a f2 ff ff       	jmp    80107694 <alltraps>

8010848a <vector191>:
.globl vector191
vector191:
  pushl $0
8010848a:	6a 00                	push   $0x0
  pushl $191
8010848c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80108491:	e9 fe f1 ff ff       	jmp    80107694 <alltraps>

80108496 <vector192>:
.globl vector192
vector192:
  pushl $0
80108496:	6a 00                	push   $0x0
  pushl $192
80108498:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010849d:	e9 f2 f1 ff ff       	jmp    80107694 <alltraps>

801084a2 <vector193>:
.globl vector193
vector193:
  pushl $0
801084a2:	6a 00                	push   $0x0
  pushl $193
801084a4:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801084a9:	e9 e6 f1 ff ff       	jmp    80107694 <alltraps>

801084ae <vector194>:
.globl vector194
vector194:
  pushl $0
801084ae:	6a 00                	push   $0x0
  pushl $194
801084b0:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801084b5:	e9 da f1 ff ff       	jmp    80107694 <alltraps>

801084ba <vector195>:
.globl vector195
vector195:
  pushl $0
801084ba:	6a 00                	push   $0x0
  pushl $195
801084bc:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801084c1:	e9 ce f1 ff ff       	jmp    80107694 <alltraps>

801084c6 <vector196>:
.globl vector196
vector196:
  pushl $0
801084c6:	6a 00                	push   $0x0
  pushl $196
801084c8:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801084cd:	e9 c2 f1 ff ff       	jmp    80107694 <alltraps>

801084d2 <vector197>:
.globl vector197
vector197:
  pushl $0
801084d2:	6a 00                	push   $0x0
  pushl $197
801084d4:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801084d9:	e9 b6 f1 ff ff       	jmp    80107694 <alltraps>

801084de <vector198>:
.globl vector198
vector198:
  pushl $0
801084de:	6a 00                	push   $0x0
  pushl $198
801084e0:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801084e5:	e9 aa f1 ff ff       	jmp    80107694 <alltraps>

801084ea <vector199>:
.globl vector199
vector199:
  pushl $0
801084ea:	6a 00                	push   $0x0
  pushl $199
801084ec:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801084f1:	e9 9e f1 ff ff       	jmp    80107694 <alltraps>

801084f6 <vector200>:
.globl vector200
vector200:
  pushl $0
801084f6:	6a 00                	push   $0x0
  pushl $200
801084f8:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801084fd:	e9 92 f1 ff ff       	jmp    80107694 <alltraps>

80108502 <vector201>:
.globl vector201
vector201:
  pushl $0
80108502:	6a 00                	push   $0x0
  pushl $201
80108504:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80108509:	e9 86 f1 ff ff       	jmp    80107694 <alltraps>

8010850e <vector202>:
.globl vector202
vector202:
  pushl $0
8010850e:	6a 00                	push   $0x0
  pushl $202
80108510:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80108515:	e9 7a f1 ff ff       	jmp    80107694 <alltraps>

8010851a <vector203>:
.globl vector203
vector203:
  pushl $0
8010851a:	6a 00                	push   $0x0
  pushl $203
8010851c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80108521:	e9 6e f1 ff ff       	jmp    80107694 <alltraps>

80108526 <vector204>:
.globl vector204
vector204:
  pushl $0
80108526:	6a 00                	push   $0x0
  pushl $204
80108528:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010852d:	e9 62 f1 ff ff       	jmp    80107694 <alltraps>

80108532 <vector205>:
.globl vector205
vector205:
  pushl $0
80108532:	6a 00                	push   $0x0
  pushl $205
80108534:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108539:	e9 56 f1 ff ff       	jmp    80107694 <alltraps>

8010853e <vector206>:
.globl vector206
vector206:
  pushl $0
8010853e:	6a 00                	push   $0x0
  pushl $206
80108540:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108545:	e9 4a f1 ff ff       	jmp    80107694 <alltraps>

8010854a <vector207>:
.globl vector207
vector207:
  pushl $0
8010854a:	6a 00                	push   $0x0
  pushl $207
8010854c:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80108551:	e9 3e f1 ff ff       	jmp    80107694 <alltraps>

80108556 <vector208>:
.globl vector208
vector208:
  pushl $0
80108556:	6a 00                	push   $0x0
  pushl $208
80108558:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010855d:	e9 32 f1 ff ff       	jmp    80107694 <alltraps>

80108562 <vector209>:
.globl vector209
vector209:
  pushl $0
80108562:	6a 00                	push   $0x0
  pushl $209
80108564:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108569:	e9 26 f1 ff ff       	jmp    80107694 <alltraps>

8010856e <vector210>:
.globl vector210
vector210:
  pushl $0
8010856e:	6a 00                	push   $0x0
  pushl $210
80108570:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108575:	e9 1a f1 ff ff       	jmp    80107694 <alltraps>

8010857a <vector211>:
.globl vector211
vector211:
  pushl $0
8010857a:	6a 00                	push   $0x0
  pushl $211
8010857c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80108581:	e9 0e f1 ff ff       	jmp    80107694 <alltraps>

80108586 <vector212>:
.globl vector212
vector212:
  pushl $0
80108586:	6a 00                	push   $0x0
  pushl $212
80108588:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010858d:	e9 02 f1 ff ff       	jmp    80107694 <alltraps>

80108592 <vector213>:
.globl vector213
vector213:
  pushl $0
80108592:	6a 00                	push   $0x0
  pushl $213
80108594:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108599:	e9 f6 f0 ff ff       	jmp    80107694 <alltraps>

8010859e <vector214>:
.globl vector214
vector214:
  pushl $0
8010859e:	6a 00                	push   $0x0
  pushl $214
801085a0:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801085a5:	e9 ea f0 ff ff       	jmp    80107694 <alltraps>

801085aa <vector215>:
.globl vector215
vector215:
  pushl $0
801085aa:	6a 00                	push   $0x0
  pushl $215
801085ac:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801085b1:	e9 de f0 ff ff       	jmp    80107694 <alltraps>

801085b6 <vector216>:
.globl vector216
vector216:
  pushl $0
801085b6:	6a 00                	push   $0x0
  pushl $216
801085b8:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801085bd:	e9 d2 f0 ff ff       	jmp    80107694 <alltraps>

801085c2 <vector217>:
.globl vector217
vector217:
  pushl $0
801085c2:	6a 00                	push   $0x0
  pushl $217
801085c4:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801085c9:	e9 c6 f0 ff ff       	jmp    80107694 <alltraps>

801085ce <vector218>:
.globl vector218
vector218:
  pushl $0
801085ce:	6a 00                	push   $0x0
  pushl $218
801085d0:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801085d5:	e9 ba f0 ff ff       	jmp    80107694 <alltraps>

801085da <vector219>:
.globl vector219
vector219:
  pushl $0
801085da:	6a 00                	push   $0x0
  pushl $219
801085dc:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801085e1:	e9 ae f0 ff ff       	jmp    80107694 <alltraps>

801085e6 <vector220>:
.globl vector220
vector220:
  pushl $0
801085e6:	6a 00                	push   $0x0
  pushl $220
801085e8:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801085ed:	e9 a2 f0 ff ff       	jmp    80107694 <alltraps>

801085f2 <vector221>:
.globl vector221
vector221:
  pushl $0
801085f2:	6a 00                	push   $0x0
  pushl $221
801085f4:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801085f9:	e9 96 f0 ff ff       	jmp    80107694 <alltraps>

801085fe <vector222>:
.globl vector222
vector222:
  pushl $0
801085fe:	6a 00                	push   $0x0
  pushl $222
80108600:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108605:	e9 8a f0 ff ff       	jmp    80107694 <alltraps>

8010860a <vector223>:
.globl vector223
vector223:
  pushl $0
8010860a:	6a 00                	push   $0x0
  pushl $223
8010860c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80108611:	e9 7e f0 ff ff       	jmp    80107694 <alltraps>

80108616 <vector224>:
.globl vector224
vector224:
  pushl $0
80108616:	6a 00                	push   $0x0
  pushl $224
80108618:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010861d:	e9 72 f0 ff ff       	jmp    80107694 <alltraps>

80108622 <vector225>:
.globl vector225
vector225:
  pushl $0
80108622:	6a 00                	push   $0x0
  pushl $225
80108624:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108629:	e9 66 f0 ff ff       	jmp    80107694 <alltraps>

8010862e <vector226>:
.globl vector226
vector226:
  pushl $0
8010862e:	6a 00                	push   $0x0
  pushl $226
80108630:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108635:	e9 5a f0 ff ff       	jmp    80107694 <alltraps>

8010863a <vector227>:
.globl vector227
vector227:
  pushl $0
8010863a:	6a 00                	push   $0x0
  pushl $227
8010863c:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80108641:	e9 4e f0 ff ff       	jmp    80107694 <alltraps>

80108646 <vector228>:
.globl vector228
vector228:
  pushl $0
80108646:	6a 00                	push   $0x0
  pushl $228
80108648:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010864d:	e9 42 f0 ff ff       	jmp    80107694 <alltraps>

80108652 <vector229>:
.globl vector229
vector229:
  pushl $0
80108652:	6a 00                	push   $0x0
  pushl $229
80108654:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108659:	e9 36 f0 ff ff       	jmp    80107694 <alltraps>

8010865e <vector230>:
.globl vector230
vector230:
  pushl $0
8010865e:	6a 00                	push   $0x0
  pushl $230
80108660:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108665:	e9 2a f0 ff ff       	jmp    80107694 <alltraps>

8010866a <vector231>:
.globl vector231
vector231:
  pushl $0
8010866a:	6a 00                	push   $0x0
  pushl $231
8010866c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80108671:	e9 1e f0 ff ff       	jmp    80107694 <alltraps>

80108676 <vector232>:
.globl vector232
vector232:
  pushl $0
80108676:	6a 00                	push   $0x0
  pushl $232
80108678:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010867d:	e9 12 f0 ff ff       	jmp    80107694 <alltraps>

80108682 <vector233>:
.globl vector233
vector233:
  pushl $0
80108682:	6a 00                	push   $0x0
  pushl $233
80108684:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108689:	e9 06 f0 ff ff       	jmp    80107694 <alltraps>

8010868e <vector234>:
.globl vector234
vector234:
  pushl $0
8010868e:	6a 00                	push   $0x0
  pushl $234
80108690:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108695:	e9 fa ef ff ff       	jmp    80107694 <alltraps>

8010869a <vector235>:
.globl vector235
vector235:
  pushl $0
8010869a:	6a 00                	push   $0x0
  pushl $235
8010869c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801086a1:	e9 ee ef ff ff       	jmp    80107694 <alltraps>

801086a6 <vector236>:
.globl vector236
vector236:
  pushl $0
801086a6:	6a 00                	push   $0x0
  pushl $236
801086a8:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801086ad:	e9 e2 ef ff ff       	jmp    80107694 <alltraps>

801086b2 <vector237>:
.globl vector237
vector237:
  pushl $0
801086b2:	6a 00                	push   $0x0
  pushl $237
801086b4:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801086b9:	e9 d6 ef ff ff       	jmp    80107694 <alltraps>

801086be <vector238>:
.globl vector238
vector238:
  pushl $0
801086be:	6a 00                	push   $0x0
  pushl $238
801086c0:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801086c5:	e9 ca ef ff ff       	jmp    80107694 <alltraps>

801086ca <vector239>:
.globl vector239
vector239:
  pushl $0
801086ca:	6a 00                	push   $0x0
  pushl $239
801086cc:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801086d1:	e9 be ef ff ff       	jmp    80107694 <alltraps>

801086d6 <vector240>:
.globl vector240
vector240:
  pushl $0
801086d6:	6a 00                	push   $0x0
  pushl $240
801086d8:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801086dd:	e9 b2 ef ff ff       	jmp    80107694 <alltraps>

801086e2 <vector241>:
.globl vector241
vector241:
  pushl $0
801086e2:	6a 00                	push   $0x0
  pushl $241
801086e4:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801086e9:	e9 a6 ef ff ff       	jmp    80107694 <alltraps>

801086ee <vector242>:
.globl vector242
vector242:
  pushl $0
801086ee:	6a 00                	push   $0x0
  pushl $242
801086f0:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801086f5:	e9 9a ef ff ff       	jmp    80107694 <alltraps>

801086fa <vector243>:
.globl vector243
vector243:
  pushl $0
801086fa:	6a 00                	push   $0x0
  pushl $243
801086fc:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80108701:	e9 8e ef ff ff       	jmp    80107694 <alltraps>

80108706 <vector244>:
.globl vector244
vector244:
  pushl $0
80108706:	6a 00                	push   $0x0
  pushl $244
80108708:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010870d:	e9 82 ef ff ff       	jmp    80107694 <alltraps>

80108712 <vector245>:
.globl vector245
vector245:
  pushl $0
80108712:	6a 00                	push   $0x0
  pushl $245
80108714:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80108719:	e9 76 ef ff ff       	jmp    80107694 <alltraps>

8010871e <vector246>:
.globl vector246
vector246:
  pushl $0
8010871e:	6a 00                	push   $0x0
  pushl $246
80108720:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108725:	e9 6a ef ff ff       	jmp    80107694 <alltraps>

8010872a <vector247>:
.globl vector247
vector247:
  pushl $0
8010872a:	6a 00                	push   $0x0
  pushl $247
8010872c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80108731:	e9 5e ef ff ff       	jmp    80107694 <alltraps>

80108736 <vector248>:
.globl vector248
vector248:
  pushl $0
80108736:	6a 00                	push   $0x0
  pushl $248
80108738:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010873d:	e9 52 ef ff ff       	jmp    80107694 <alltraps>

80108742 <vector249>:
.globl vector249
vector249:
  pushl $0
80108742:	6a 00                	push   $0x0
  pushl $249
80108744:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108749:	e9 46 ef ff ff       	jmp    80107694 <alltraps>

8010874e <vector250>:
.globl vector250
vector250:
  pushl $0
8010874e:	6a 00                	push   $0x0
  pushl $250
80108750:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108755:	e9 3a ef ff ff       	jmp    80107694 <alltraps>

8010875a <vector251>:
.globl vector251
vector251:
  pushl $0
8010875a:	6a 00                	push   $0x0
  pushl $251
8010875c:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80108761:	e9 2e ef ff ff       	jmp    80107694 <alltraps>

80108766 <vector252>:
.globl vector252
vector252:
  pushl $0
80108766:	6a 00                	push   $0x0
  pushl $252
80108768:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010876d:	e9 22 ef ff ff       	jmp    80107694 <alltraps>

80108772 <vector253>:
.globl vector253
vector253:
  pushl $0
80108772:	6a 00                	push   $0x0
  pushl $253
80108774:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108779:	e9 16 ef ff ff       	jmp    80107694 <alltraps>

8010877e <vector254>:
.globl vector254
vector254:
  pushl $0
8010877e:	6a 00                	push   $0x0
  pushl $254
80108780:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108785:	e9 0a ef ff ff       	jmp    80107694 <alltraps>

8010878a <vector255>:
.globl vector255
vector255:
  pushl $0
8010878a:	6a 00                	push   $0x0
  pushl $255
8010878c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80108791:	e9 fe ee ff ff       	jmp    80107694 <alltraps>
	...

80108798 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108798:	55                   	push   %ebp
80108799:	89 e5                	mov    %esp,%ebp
8010879b:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010879e:	8b 45 0c             	mov    0xc(%ebp),%eax
801087a1:	83 e8 01             	sub    $0x1,%eax
801087a4:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801087a8:	8b 45 08             	mov    0x8(%ebp),%eax
801087ab:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801087af:	8b 45 08             	mov    0x8(%ebp),%eax
801087b2:	c1 e8 10             	shr    $0x10,%eax
801087b5:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801087b9:	8d 45 fa             	lea    -0x6(%ebp),%eax
801087bc:	0f 01 10             	lgdtl  (%eax)
}
801087bf:	c9                   	leave  
801087c0:	c3                   	ret    

801087c1 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801087c1:	55                   	push   %ebp
801087c2:	89 e5                	mov    %esp,%ebp
801087c4:	83 ec 04             	sub    $0x4,%esp
801087c7:	8b 45 08             	mov    0x8(%ebp),%eax
801087ca:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801087ce:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801087d2:	0f 00 d8             	ltr    %ax
}
801087d5:	c9                   	leave  
801087d6:	c3                   	ret    

801087d7 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801087d7:	55                   	push   %ebp
801087d8:	89 e5                	mov    %esp,%ebp
801087da:	83 ec 04             	sub    $0x4,%esp
801087dd:	8b 45 08             	mov    0x8(%ebp),%eax
801087e0:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801087e4:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801087e8:	8e e8                	mov    %eax,%gs
}
801087ea:	c9                   	leave  
801087eb:	c3                   	ret    

801087ec <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801087ec:	55                   	push   %ebp
801087ed:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801087ef:	8b 45 08             	mov    0x8(%ebp),%eax
801087f2:	0f 22 d8             	mov    %eax,%cr3
}
801087f5:	5d                   	pop    %ebp
801087f6:	c3                   	ret    

801087f7 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801087f7:	55                   	push   %ebp
801087f8:	89 e5                	mov    %esp,%ebp
801087fa:	8b 45 08             	mov    0x8(%ebp),%eax
801087fd:	05 00 00 00 80       	add    $0x80000000,%eax
80108802:	5d                   	pop    %ebp
80108803:	c3                   	ret    

80108804 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108804:	55                   	push   %ebp
80108805:	89 e5                	mov    %esp,%ebp
80108807:	8b 45 08             	mov    0x8(%ebp),%eax
8010880a:	05 00 00 00 80       	add    $0x80000000,%eax
8010880f:	5d                   	pop    %ebp
80108810:	c3                   	ret    

80108811 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80108811:	55                   	push   %ebp
80108812:	89 e5                	mov    %esp,%ebp
80108814:	53                   	push   %ebx
80108815:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108818:	e8 18 b9 ff ff       	call   80104135 <cpunum>
8010881d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80108823:	05 80 09 11 80       	add    $0x80110980,%eax
80108828:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010882b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882e:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108834:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108837:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010883d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108840:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108847:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010884b:	83 e2 f0             	and    $0xfffffff0,%edx
8010884e:	83 ca 0a             	or     $0xa,%edx
80108851:	88 50 7d             	mov    %dl,0x7d(%eax)
80108854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108857:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010885b:	83 ca 10             	or     $0x10,%edx
8010885e:	88 50 7d             	mov    %dl,0x7d(%eax)
80108861:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108864:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108868:	83 e2 9f             	and    $0xffffff9f,%edx
8010886b:	88 50 7d             	mov    %dl,0x7d(%eax)
8010886e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108871:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108875:	83 ca 80             	or     $0xffffff80,%edx
80108878:	88 50 7d             	mov    %dl,0x7d(%eax)
8010887b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010887e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108882:	83 ca 0f             	or     $0xf,%edx
80108885:	88 50 7e             	mov    %dl,0x7e(%eax)
80108888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010888b:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010888f:	83 e2 ef             	and    $0xffffffef,%edx
80108892:	88 50 7e             	mov    %dl,0x7e(%eax)
80108895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108898:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010889c:	83 e2 df             	and    $0xffffffdf,%edx
8010889f:	88 50 7e             	mov    %dl,0x7e(%eax)
801088a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088a5:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801088a9:	83 ca 40             	or     $0x40,%edx
801088ac:	88 50 7e             	mov    %dl,0x7e(%eax)
801088af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088b2:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801088b6:	83 ca 80             	or     $0xffffff80,%edx
801088b9:	88 50 7e             	mov    %dl,0x7e(%eax)
801088bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088bf:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801088c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c6:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801088cd:	ff ff 
801088cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d2:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801088d9:	00 00 
801088db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088de:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801088e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801088ef:	83 e2 f0             	and    $0xfffffff0,%edx
801088f2:	83 ca 02             	or     $0x2,%edx
801088f5:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801088fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088fe:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108905:	83 ca 10             	or     $0x10,%edx
80108908:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010890e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108911:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108918:	83 e2 9f             	and    $0xffffff9f,%edx
8010891b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108921:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108924:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010892b:	83 ca 80             	or     $0xffffff80,%edx
8010892e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108937:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010893e:	83 ca 0f             	or     $0xf,%edx
80108941:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108947:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010894a:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108951:	83 e2 ef             	and    $0xffffffef,%edx
80108954:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010895a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010895d:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108964:	83 e2 df             	and    $0xffffffdf,%edx
80108967:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010896d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108970:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108977:	83 ca 40             	or     $0x40,%edx
8010897a:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108983:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010898a:	83 ca 80             	or     $0xffffff80,%edx
8010898d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108993:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108996:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010899d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a0:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801089a7:	ff ff 
801089a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ac:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801089b3:	00 00 
801089b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b8:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801089bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089c2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801089c9:	83 e2 f0             	and    $0xfffffff0,%edx
801089cc:	83 ca 0a             	or     $0xa,%edx
801089cf:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089d8:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801089df:	83 ca 10             	or     $0x10,%edx
801089e2:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089eb:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801089f2:	83 ca 60             	or     $0x60,%edx
801089f5:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801089fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fe:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108a05:	83 ca 80             	or     $0xffffff80,%edx
80108a08:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a11:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a18:	83 ca 0f             	or     $0xf,%edx
80108a1b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a24:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a2b:	83 e2 ef             	and    $0xffffffef,%edx
80108a2e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a37:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a3e:	83 e2 df             	and    $0xffffffdf,%edx
80108a41:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a4a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a51:	83 ca 40             	or     $0x40,%edx
80108a54:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a5d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108a64:	83 ca 80             	or     $0xffffff80,%edx
80108a67:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108a6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a70:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108a77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a7a:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108a81:	ff ff 
80108a83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a86:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108a8d:	00 00 
80108a8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a92:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108a99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a9c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108aa3:	83 e2 f0             	and    $0xfffffff0,%edx
80108aa6:	83 ca 02             	or     $0x2,%edx
80108aa9:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108aaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab2:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108ab9:	83 ca 10             	or     $0x10,%edx
80108abc:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac5:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108acc:	83 ca 60             	or     $0x60,%edx
80108acf:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108adf:	83 ca 80             	or     $0xffffff80,%edx
80108ae2:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aeb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108af2:	83 ca 0f             	or     $0xf,%edx
80108af5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108afb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108afe:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b05:	83 e2 ef             	and    $0xffffffef,%edx
80108b08:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b11:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b18:	83 e2 df             	and    $0xffffffdf,%edx
80108b1b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b24:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b2b:	83 ca 40             	or     $0x40,%edx
80108b2e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b37:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108b3e:	83 ca 80             	or     $0xffffff80,%edx
80108b41:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b4a:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108b51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b54:	05 b4 00 00 00       	add    $0xb4,%eax
80108b59:	89 c3                	mov    %eax,%ebx
80108b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5e:	05 b4 00 00 00       	add    $0xb4,%eax
80108b63:	c1 e8 10             	shr    $0x10,%eax
80108b66:	89 c1                	mov    %eax,%ecx
80108b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b6b:	05 b4 00 00 00       	add    $0xb4,%eax
80108b70:	c1 e8 18             	shr    $0x18,%eax
80108b73:	89 c2                	mov    %eax,%edx
80108b75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b78:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108b7f:	00 00 
80108b81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b84:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b8e:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108b94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b97:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b9e:	83 e1 f0             	and    $0xfffffff0,%ecx
80108ba1:	83 c9 02             	or     $0x2,%ecx
80108ba4:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bad:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108bb4:	83 c9 10             	or     $0x10,%ecx
80108bb7:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108bbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bc0:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108bc7:	83 e1 9f             	and    $0xffffff9f,%ecx
80108bca:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108bd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bd3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108bda:	83 c9 80             	or     $0xffffff80,%ecx
80108bdd:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108be3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108be6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108bed:	83 e1 f0             	and    $0xfffffff0,%ecx
80108bf0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108bf9:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c00:	83 e1 ef             	and    $0xffffffef,%ecx
80108c03:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c13:	83 e1 df             	and    $0xffffffdf,%ecx
80108c16:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c1f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c26:	83 c9 40             	or     $0x40,%ecx
80108c29:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c32:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108c39:	83 c9 80             	or     $0xffffff80,%ecx
80108c3c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c45:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108c4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c4e:	83 c0 70             	add    $0x70,%eax
80108c51:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108c58:	00 
80108c59:	89 04 24             	mov    %eax,(%esp)
80108c5c:	e8 37 fb ff ff       	call   80108798 <lgdt>
  loadgs(SEG_KCPU << 3);
80108c61:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108c68:	e8 6a fb ff ff       	call   801087d7 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c70:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108c76:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108c7d:	00 00 00 00 
}
80108c81:	83 c4 24             	add    $0x24,%esp
80108c84:	5b                   	pop    %ebx
80108c85:	5d                   	pop    %ebp
80108c86:	c3                   	ret    

80108c87 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108c87:	55                   	push   %ebp
80108c88:	89 e5                	mov    %esp,%ebp
80108c8a:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108c8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c90:	c1 e8 16             	shr    $0x16,%eax
80108c93:	c1 e0 02             	shl    $0x2,%eax
80108c96:	03 45 08             	add    0x8(%ebp),%eax
80108c99:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108c9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c9f:	8b 00                	mov    (%eax),%eax
80108ca1:	83 e0 01             	and    $0x1,%eax
80108ca4:	84 c0                	test   %al,%al
80108ca6:	74 17                	je     80108cbf <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108ca8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108cab:	8b 00                	mov    (%eax),%eax
80108cad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cb2:	89 04 24             	mov    %eax,(%esp)
80108cb5:	e8 4a fb ff ff       	call   80108804 <p2v>
80108cba:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108cbd:	eb 4b                	jmp    80108d0a <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108cbf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108cc3:	74 0e                	je     80108cd3 <walkpgdir+0x4c>
80108cc5:	e8 dd b0 ff ff       	call   80103da7 <kalloc>
80108cca:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108ccd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108cd1:	75 07                	jne    80108cda <walkpgdir+0x53>
      return 0;
80108cd3:	b8 00 00 00 00       	mov    $0x0,%eax
80108cd8:	eb 41                	jmp    80108d1b <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108cda:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108ce1:	00 
80108ce2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ce9:	00 
80108cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ced:	89 04 24             	mov    %eax,(%esp)
80108cf0:	e8 a5 d3 ff ff       	call   8010609a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108cf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cf8:	89 04 24             	mov    %eax,(%esp)
80108cfb:	e8 f7 fa ff ff       	call   801087f7 <v2p>
80108d00:	89 c2                	mov    %eax,%edx
80108d02:	83 ca 07             	or     $0x7,%edx
80108d05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d08:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108d0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d0d:	c1 e8 0c             	shr    $0xc,%eax
80108d10:	25 ff 03 00 00       	and    $0x3ff,%eax
80108d15:	c1 e0 02             	shl    $0x2,%eax
80108d18:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108d1b:	c9                   	leave  
80108d1c:	c3                   	ret    

80108d1d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108d1d:	55                   	push   %ebp
80108d1e:	89 e5                	mov    %esp,%ebp
80108d20:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108d23:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d26:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108d2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d31:	03 45 10             	add    0x10(%ebp),%eax
80108d34:	83 e8 01             	sub    $0x1,%eax
80108d37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108d3f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108d46:	00 
80108d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d4e:	8b 45 08             	mov    0x8(%ebp),%eax
80108d51:	89 04 24             	mov    %eax,(%esp)
80108d54:	e8 2e ff ff ff       	call   80108c87 <walkpgdir>
80108d59:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108d5c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108d60:	75 07                	jne    80108d69 <mappages+0x4c>
      return -1;
80108d62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d67:	eb 46                	jmp    80108daf <mappages+0x92>
    if(*pte & PTE_P)
80108d69:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d6c:	8b 00                	mov    (%eax),%eax
80108d6e:	83 e0 01             	and    $0x1,%eax
80108d71:	84 c0                	test   %al,%al
80108d73:	74 0c                	je     80108d81 <mappages+0x64>
      panic("remap");
80108d75:	c7 04 24 78 9c 10 80 	movl   $0x80109c78,(%esp)
80108d7c:	e8 bc 77 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108d81:	8b 45 18             	mov    0x18(%ebp),%eax
80108d84:	0b 45 14             	or     0x14(%ebp),%eax
80108d87:	89 c2                	mov    %eax,%edx
80108d89:	83 ca 01             	or     $0x1,%edx
80108d8c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108d8f:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108d91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d94:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108d97:	74 10                	je     80108da9 <mappages+0x8c>
      break;
    a += PGSIZE;
80108d99:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108da0:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108da7:	eb 96                	jmp    80108d3f <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108da9:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108daa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108daf:	c9                   	leave  
80108db0:	c3                   	ret    

80108db1 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108db1:	55                   	push   %ebp
80108db2:	89 e5                	mov    %esp,%ebp
80108db4:	53                   	push   %ebx
80108db5:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108db8:	e8 ea af ff ff       	call   80103da7 <kalloc>
80108dbd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108dc0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108dc4:	75 0a                	jne    80108dd0 <setupkvm+0x1f>
    return 0;
80108dc6:	b8 00 00 00 00       	mov    $0x0,%eax
80108dcb:	e9 98 00 00 00       	jmp    80108e68 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108dd0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108dd7:	00 
80108dd8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108ddf:	00 
80108de0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108de3:	89 04 24             	mov    %eax,(%esp)
80108de6:	e8 af d2 ff ff       	call   8010609a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108deb:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108df2:	e8 0d fa ff ff       	call   80108804 <p2v>
80108df7:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108dfc:	76 0c                	jbe    80108e0a <setupkvm+0x59>
    panic("PHYSTOP too high");
80108dfe:	c7 04 24 7e 9c 10 80 	movl   $0x80109c7e,(%esp)
80108e05:	e8 33 77 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108e0a:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108e11:	eb 49                	jmp    80108e5c <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108e13:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108e16:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108e1c:	8b 50 04             	mov    0x4(%eax),%edx
80108e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e22:	8b 58 08             	mov    0x8(%eax),%ebx
80108e25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e28:	8b 40 04             	mov    0x4(%eax),%eax
80108e2b:	29 c3                	sub    %eax,%ebx
80108e2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e30:	8b 00                	mov    (%eax),%eax
80108e32:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108e36:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108e3a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e42:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e45:	89 04 24             	mov    %eax,(%esp)
80108e48:	e8 d0 fe ff ff       	call   80108d1d <mappages>
80108e4d:	85 c0                	test   %eax,%eax
80108e4f:	79 07                	jns    80108e58 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108e51:	b8 00 00 00 00       	mov    $0x0,%eax
80108e56:	eb 10                	jmp    80108e68 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108e58:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108e5c:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108e63:	72 ae                	jb     80108e13 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108e65:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108e68:	83 c4 34             	add    $0x34,%esp
80108e6b:	5b                   	pop    %ebx
80108e6c:	5d                   	pop    %ebp
80108e6d:	c3                   	ret    

80108e6e <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108e6e:	55                   	push   %ebp
80108e6f:	89 e5                	mov    %esp,%ebp
80108e71:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108e74:	e8 38 ff ff ff       	call   80108db1 <setupkvm>
80108e79:	a3 58 37 11 80       	mov    %eax,0x80113758
  switchkvm();
80108e7e:	e8 02 00 00 00       	call   80108e85 <switchkvm>
}
80108e83:	c9                   	leave  
80108e84:	c3                   	ret    

80108e85 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108e85:	55                   	push   %ebp
80108e86:	89 e5                	mov    %esp,%ebp
80108e88:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108e8b:	a1 58 37 11 80       	mov    0x80113758,%eax
80108e90:	89 04 24             	mov    %eax,(%esp)
80108e93:	e8 5f f9 ff ff       	call   801087f7 <v2p>
80108e98:	89 04 24             	mov    %eax,(%esp)
80108e9b:	e8 4c f9 ff ff       	call   801087ec <lcr3>
}
80108ea0:	c9                   	leave  
80108ea1:	c3                   	ret    

80108ea2 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108ea2:	55                   	push   %ebp
80108ea3:	89 e5                	mov    %esp,%ebp
80108ea5:	53                   	push   %ebx
80108ea6:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108ea9:	e8 e5 d0 ff ff       	call   80105f93 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108eae:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108eb4:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ebb:	83 c2 08             	add    $0x8,%edx
80108ebe:	89 d3                	mov    %edx,%ebx
80108ec0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ec7:	83 c2 08             	add    $0x8,%edx
80108eca:	c1 ea 10             	shr    $0x10,%edx
80108ecd:	89 d1                	mov    %edx,%ecx
80108ecf:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ed6:	83 c2 08             	add    $0x8,%edx
80108ed9:	c1 ea 18             	shr    $0x18,%edx
80108edc:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108ee3:	67 00 
80108ee5:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108eec:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108ef2:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ef9:	83 e1 f0             	and    $0xfffffff0,%ecx
80108efc:	83 c9 09             	or     $0x9,%ecx
80108eff:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108f05:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108f0c:	83 c9 10             	or     $0x10,%ecx
80108f0f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108f15:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108f1c:	83 e1 9f             	and    $0xffffff9f,%ecx
80108f1f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108f25:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108f2c:	83 c9 80             	or     $0xffffff80,%ecx
80108f2f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108f35:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f3c:	83 e1 f0             	and    $0xfffffff0,%ecx
80108f3f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f45:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f4c:	83 e1 ef             	and    $0xffffffef,%ecx
80108f4f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f55:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f5c:	83 e1 df             	and    $0xffffffdf,%ecx
80108f5f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f65:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f6c:	83 c9 40             	or     $0x40,%ecx
80108f6f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f75:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108f7c:	83 e1 7f             	and    $0x7f,%ecx
80108f7f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108f85:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108f8b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108f91:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108f98:	83 e2 ef             	and    $0xffffffef,%edx
80108f9b:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108fa1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108fa7:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108fad:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108fb3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108fba:	8b 52 08             	mov    0x8(%edx),%edx
80108fbd:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108fc3:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108fc6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108fcd:	e8 ef f7 ff ff       	call   801087c1 <ltr>
  if(p->pgdir == 0)
80108fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80108fd5:	8b 40 04             	mov    0x4(%eax),%eax
80108fd8:	85 c0                	test   %eax,%eax
80108fda:	75 0c                	jne    80108fe8 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108fdc:	c7 04 24 8f 9c 10 80 	movl   $0x80109c8f,(%esp)
80108fe3:	e8 55 75 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80108feb:	8b 40 04             	mov    0x4(%eax),%eax
80108fee:	89 04 24             	mov    %eax,(%esp)
80108ff1:	e8 01 f8 ff ff       	call   801087f7 <v2p>
80108ff6:	89 04 24             	mov    %eax,(%esp)
80108ff9:	e8 ee f7 ff ff       	call   801087ec <lcr3>
  popcli();
80108ffe:	e8 d8 cf ff ff       	call   80105fdb <popcli>
}
80109003:	83 c4 14             	add    $0x14,%esp
80109006:	5b                   	pop    %ebx
80109007:	5d                   	pop    %ebp
80109008:	c3                   	ret    

80109009 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80109009:	55                   	push   %ebp
8010900a:	89 e5                	mov    %esp,%ebp
8010900c:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
8010900f:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80109016:	76 0c                	jbe    80109024 <inituvm+0x1b>
    panic("inituvm: more than a page");
80109018:	c7 04 24 a3 9c 10 80 	movl   $0x80109ca3,(%esp)
8010901f:	e8 19 75 ff ff       	call   8010053d <panic>
  mem = kalloc();
80109024:	e8 7e ad ff ff       	call   80103da7 <kalloc>
80109029:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010902c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109033:	00 
80109034:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010903b:	00 
8010903c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010903f:	89 04 24             	mov    %eax,(%esp)
80109042:	e8 53 d0 ff ff       	call   8010609a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109047:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010904a:	89 04 24             	mov    %eax,(%esp)
8010904d:	e8 a5 f7 ff ff       	call   801087f7 <v2p>
80109052:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109059:	00 
8010905a:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010905e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109065:	00 
80109066:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010906d:	00 
8010906e:	8b 45 08             	mov    0x8(%ebp),%eax
80109071:	89 04 24             	mov    %eax,(%esp)
80109074:	e8 a4 fc ff ff       	call   80108d1d <mappages>
  memmove(mem, init, sz);
80109079:	8b 45 10             	mov    0x10(%ebp),%eax
8010907c:	89 44 24 08          	mov    %eax,0x8(%esp)
80109080:	8b 45 0c             	mov    0xc(%ebp),%eax
80109083:	89 44 24 04          	mov    %eax,0x4(%esp)
80109087:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010908a:	89 04 24             	mov    %eax,(%esp)
8010908d:	e8 db d0 ff ff       	call   8010616d <memmove>
}
80109092:	c9                   	leave  
80109093:	c3                   	ret    

80109094 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80109094:	55                   	push   %ebp
80109095:	89 e5                	mov    %esp,%ebp
80109097:	53                   	push   %ebx
80109098:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010909b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010909e:	25 ff 0f 00 00       	and    $0xfff,%eax
801090a3:	85 c0                	test   %eax,%eax
801090a5:	74 0c                	je     801090b3 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801090a7:	c7 04 24 c0 9c 10 80 	movl   $0x80109cc0,(%esp)
801090ae:	e8 8a 74 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
801090b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801090ba:	e9 ad 00 00 00       	jmp    8010916c <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801090bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090c2:	8b 55 0c             	mov    0xc(%ebp),%edx
801090c5:	01 d0                	add    %edx,%eax
801090c7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801090ce:	00 
801090cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801090d3:	8b 45 08             	mov    0x8(%ebp),%eax
801090d6:	89 04 24             	mov    %eax,(%esp)
801090d9:	e8 a9 fb ff ff       	call   80108c87 <walkpgdir>
801090de:	89 45 ec             	mov    %eax,-0x14(%ebp)
801090e1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801090e5:	75 0c                	jne    801090f3 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801090e7:	c7 04 24 e3 9c 10 80 	movl   $0x80109ce3,(%esp)
801090ee:	e8 4a 74 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801090f3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801090f6:	8b 00                	mov    (%eax),%eax
801090f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801090fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80109100:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109103:	8b 55 18             	mov    0x18(%ebp),%edx
80109106:	89 d1                	mov    %edx,%ecx
80109108:	29 c1                	sub    %eax,%ecx
8010910a:	89 c8                	mov    %ecx,%eax
8010910c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80109111:	77 11                	ja     80109124 <loaduvm+0x90>
      n = sz - i;
80109113:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109116:	8b 55 18             	mov    0x18(%ebp),%edx
80109119:	89 d1                	mov    %edx,%ecx
8010911b:	29 c1                	sub    %eax,%ecx
8010911d:	89 c8                	mov    %ecx,%eax
8010911f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109122:	eb 07                	jmp    8010912b <loaduvm+0x97>
    else
      n = PGSIZE;
80109124:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
8010912b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010912e:	8b 55 14             	mov    0x14(%ebp),%edx
80109131:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80109134:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109137:	89 04 24             	mov    %eax,(%esp)
8010913a:	e8 c5 f6 ff ff       	call   80108804 <p2v>
8010913f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109142:	89 54 24 0c          	mov    %edx,0xc(%esp)
80109146:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010914a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010914e:	8b 45 10             	mov    0x10(%ebp),%eax
80109151:	89 04 24             	mov    %eax,(%esp)
80109154:	e8 a5 9a ff ff       	call   80102bfe <readi>
80109159:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010915c:	74 07                	je     80109165 <loaduvm+0xd1>
      return -1;
8010915e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109163:	eb 18                	jmp    8010917d <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109165:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010916c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010916f:	3b 45 18             	cmp    0x18(%ebp),%eax
80109172:	0f 82 47 ff ff ff    	jb     801090bf <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80109178:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010917d:	83 c4 24             	add    $0x24,%esp
80109180:	5b                   	pop    %ebx
80109181:	5d                   	pop    %ebp
80109182:	c3                   	ret    

80109183 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109183:	55                   	push   %ebp
80109184:	89 e5                	mov    %esp,%ebp
80109186:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80109189:	8b 45 10             	mov    0x10(%ebp),%eax
8010918c:	85 c0                	test   %eax,%eax
8010918e:	79 0a                	jns    8010919a <allocuvm+0x17>
    return 0;
80109190:	b8 00 00 00 00       	mov    $0x0,%eax
80109195:	e9 c1 00 00 00       	jmp    8010925b <allocuvm+0xd8>
  if(newsz < oldsz)
8010919a:	8b 45 10             	mov    0x10(%ebp),%eax
8010919d:	3b 45 0c             	cmp    0xc(%ebp),%eax
801091a0:	73 08                	jae    801091aa <allocuvm+0x27>
    return oldsz;
801091a2:	8b 45 0c             	mov    0xc(%ebp),%eax
801091a5:	e9 b1 00 00 00       	jmp    8010925b <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801091aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801091ad:	05 ff 0f 00 00       	add    $0xfff,%eax
801091b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801091ba:	e9 8d 00 00 00       	jmp    8010924c <allocuvm+0xc9>
    mem = kalloc();
801091bf:	e8 e3 ab ff ff       	call   80103da7 <kalloc>
801091c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801091c7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801091cb:	75 2c                	jne    801091f9 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801091cd:	c7 04 24 01 9d 10 80 	movl   $0x80109d01,(%esp)
801091d4:	e8 c8 71 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801091d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801091dc:	89 44 24 08          	mov    %eax,0x8(%esp)
801091e0:	8b 45 10             	mov    0x10(%ebp),%eax
801091e3:	89 44 24 04          	mov    %eax,0x4(%esp)
801091e7:	8b 45 08             	mov    0x8(%ebp),%eax
801091ea:	89 04 24             	mov    %eax,(%esp)
801091ed:	e8 6b 00 00 00       	call   8010925d <deallocuvm>
      return 0;
801091f2:	b8 00 00 00 00       	mov    $0x0,%eax
801091f7:	eb 62                	jmp    8010925b <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801091f9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109200:	00 
80109201:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109208:	00 
80109209:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010920c:	89 04 24             	mov    %eax,(%esp)
8010920f:	e8 86 ce ff ff       	call   8010609a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109214:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109217:	89 04 24             	mov    %eax,(%esp)
8010921a:	e8 d8 f5 ff ff       	call   801087f7 <v2p>
8010921f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109222:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109229:	00 
8010922a:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010922e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109235:	00 
80109236:	89 54 24 04          	mov    %edx,0x4(%esp)
8010923a:	8b 45 08             	mov    0x8(%ebp),%eax
8010923d:	89 04 24             	mov    %eax,(%esp)
80109240:	e8 d8 fa ff ff       	call   80108d1d <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109245:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010924c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010924f:	3b 45 10             	cmp    0x10(%ebp),%eax
80109252:	0f 82 67 ff ff ff    	jb     801091bf <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109258:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010925b:	c9                   	leave  
8010925c:	c3                   	ret    

8010925d <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010925d:	55                   	push   %ebp
8010925e:	89 e5                	mov    %esp,%ebp
80109260:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80109263:	8b 45 10             	mov    0x10(%ebp),%eax
80109266:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109269:	72 08                	jb     80109273 <deallocuvm+0x16>
    return oldsz;
8010926b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010926e:	e9 a4 00 00 00       	jmp    80109317 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80109273:	8b 45 10             	mov    0x10(%ebp),%eax
80109276:	05 ff 0f 00 00       	add    $0xfff,%eax
8010927b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109280:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80109283:	e9 80 00 00 00       	jmp    80109308 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80109288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010928b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109292:	00 
80109293:	89 44 24 04          	mov    %eax,0x4(%esp)
80109297:	8b 45 08             	mov    0x8(%ebp),%eax
8010929a:	89 04 24             	mov    %eax,(%esp)
8010929d:	e8 e5 f9 ff ff       	call   80108c87 <walkpgdir>
801092a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801092a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801092a9:	75 09                	jne    801092b4 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801092ab:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801092b2:	eb 4d                	jmp    80109301 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801092b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092b7:	8b 00                	mov    (%eax),%eax
801092b9:	83 e0 01             	and    $0x1,%eax
801092bc:	84 c0                	test   %al,%al
801092be:	74 41                	je     80109301 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801092c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092c3:	8b 00                	mov    (%eax),%eax
801092c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801092ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801092cd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801092d1:	75 0c                	jne    801092df <deallocuvm+0x82>
        panic("kfree");
801092d3:	c7 04 24 19 9d 10 80 	movl   $0x80109d19,(%esp)
801092da:	e8 5e 72 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
801092df:	8b 45 ec             	mov    -0x14(%ebp),%eax
801092e2:	89 04 24             	mov    %eax,(%esp)
801092e5:	e8 1a f5 ff ff       	call   80108804 <p2v>
801092ea:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801092ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
801092f0:	89 04 24             	mov    %eax,(%esp)
801092f3:	e8 16 aa ff ff       	call   80103d0e <kfree>
      *pte = 0;
801092f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092fb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80109301:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010930b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010930e:	0f 82 74 ff ff ff    	jb     80109288 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80109314:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109317:	c9                   	leave  
80109318:	c3                   	ret    

80109319 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80109319:	55                   	push   %ebp
8010931a:	89 e5                	mov    %esp,%ebp
8010931c:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010931f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80109323:	75 0c                	jne    80109331 <freevm+0x18>
    panic("freevm: no pgdir");
80109325:	c7 04 24 1f 9d 10 80 	movl   $0x80109d1f,(%esp)
8010932c:	e8 0c 72 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80109331:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109338:	00 
80109339:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80109340:	80 
80109341:	8b 45 08             	mov    0x8(%ebp),%eax
80109344:	89 04 24             	mov    %eax,(%esp)
80109347:	e8 11 ff ff ff       	call   8010925d <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010934c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109353:	eb 3c                	jmp    80109391 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109355:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109358:	c1 e0 02             	shl    $0x2,%eax
8010935b:	03 45 08             	add    0x8(%ebp),%eax
8010935e:	8b 00                	mov    (%eax),%eax
80109360:	83 e0 01             	and    $0x1,%eax
80109363:	84 c0                	test   %al,%al
80109365:	74 26                	je     8010938d <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010936a:	c1 e0 02             	shl    $0x2,%eax
8010936d:	03 45 08             	add    0x8(%ebp),%eax
80109370:	8b 00                	mov    (%eax),%eax
80109372:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109377:	89 04 24             	mov    %eax,(%esp)
8010937a:	e8 85 f4 ff ff       	call   80108804 <p2v>
8010937f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80109382:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109385:	89 04 24             	mov    %eax,(%esp)
80109388:	e8 81 a9 ff ff       	call   80103d0e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
8010938d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80109391:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80109398:	76 bb                	jbe    80109355 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010939a:	8b 45 08             	mov    0x8(%ebp),%eax
8010939d:	89 04 24             	mov    %eax,(%esp)
801093a0:	e8 69 a9 ff ff       	call   80103d0e <kfree>
}
801093a5:	c9                   	leave  
801093a6:	c3                   	ret    

801093a7 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801093a7:	55                   	push   %ebp
801093a8:	89 e5                	mov    %esp,%ebp
801093aa:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801093ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801093b4:	00 
801093b5:	8b 45 0c             	mov    0xc(%ebp),%eax
801093b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801093bc:	8b 45 08             	mov    0x8(%ebp),%eax
801093bf:	89 04 24             	mov    %eax,(%esp)
801093c2:	e8 c0 f8 ff ff       	call   80108c87 <walkpgdir>
801093c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801093ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801093ce:	75 0c                	jne    801093dc <clearpteu+0x35>
    panic("clearpteu");
801093d0:	c7 04 24 30 9d 10 80 	movl   $0x80109d30,(%esp)
801093d7:	e8 61 71 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
801093dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093df:	8b 00                	mov    (%eax),%eax
801093e1:	89 c2                	mov    %eax,%edx
801093e3:	83 e2 fb             	and    $0xfffffffb,%edx
801093e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801093e9:	89 10                	mov    %edx,(%eax)
}
801093eb:	c9                   	leave  
801093ec:	c3                   	ret    

801093ed <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801093ed:	55                   	push   %ebp
801093ee:	89 e5                	mov    %esp,%ebp
801093f0:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801093f3:	e8 b9 f9 ff ff       	call   80108db1 <setupkvm>
801093f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801093fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801093ff:	75 0a                	jne    8010940b <copyuvm+0x1e>
    return 0;
80109401:	b8 00 00 00 00       	mov    $0x0,%eax
80109406:	e9 f1 00 00 00       	jmp    801094fc <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010940b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109412:	e9 c0 00 00 00       	jmp    801094d7 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80109417:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010941a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109421:	00 
80109422:	89 44 24 04          	mov    %eax,0x4(%esp)
80109426:	8b 45 08             	mov    0x8(%ebp),%eax
80109429:	89 04 24             	mov    %eax,(%esp)
8010942c:	e8 56 f8 ff ff       	call   80108c87 <walkpgdir>
80109431:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109434:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109438:	75 0c                	jne    80109446 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
8010943a:	c7 04 24 3a 9d 10 80 	movl   $0x80109d3a,(%esp)
80109441:	e8 f7 70 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109446:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109449:	8b 00                	mov    (%eax),%eax
8010944b:	83 e0 01             	and    $0x1,%eax
8010944e:	85 c0                	test   %eax,%eax
80109450:	75 0c                	jne    8010945e <copyuvm+0x71>
      panic("copyuvm: page not present");
80109452:	c7 04 24 54 9d 10 80 	movl   $0x80109d54,(%esp)
80109459:	e8 df 70 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010945e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109461:	8b 00                	mov    (%eax),%eax
80109463:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109468:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
8010946b:	e8 37 a9 ff ff       	call   80103da7 <kalloc>
80109470:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80109473:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109477:	74 6f                	je     801094e8 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109479:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010947c:	89 04 24             	mov    %eax,(%esp)
8010947f:	e8 80 f3 ff ff       	call   80108804 <p2v>
80109484:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010948b:	00 
8010948c:	89 44 24 04          	mov    %eax,0x4(%esp)
80109490:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80109493:	89 04 24             	mov    %eax,(%esp)
80109496:	e8 d2 cc ff ff       	call   8010616d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010949b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010949e:	89 04 24             	mov    %eax,(%esp)
801094a1:	e8 51 f3 ff ff       	call   801087f7 <v2p>
801094a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801094a9:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801094b0:	00 
801094b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
801094b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801094bc:	00 
801094bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801094c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094c4:	89 04 24             	mov    %eax,(%esp)
801094c7:	e8 51 f8 ff ff       	call   80108d1d <mappages>
801094cc:	85 c0                	test   %eax,%eax
801094ce:	78 1b                	js     801094eb <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801094d0:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801094d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801094da:	3b 45 0c             	cmp    0xc(%ebp),%eax
801094dd:	0f 82 34 ff ff ff    	jb     80109417 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801094e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094e6:	eb 14                	jmp    801094fc <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801094e8:	90                   	nop
801094e9:	eb 01                	jmp    801094ec <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801094eb:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801094ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094ef:	89 04 24             	mov    %eax,(%esp)
801094f2:	e8 22 fe ff ff       	call   80109319 <freevm>
  return 0;
801094f7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801094fc:	c9                   	leave  
801094fd:	c3                   	ret    

801094fe <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801094fe:	55                   	push   %ebp
801094ff:	89 e5                	mov    %esp,%ebp
80109501:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109504:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010950b:	00 
8010950c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010950f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109513:	8b 45 08             	mov    0x8(%ebp),%eax
80109516:	89 04 24             	mov    %eax,(%esp)
80109519:	e8 69 f7 ff ff       	call   80108c87 <walkpgdir>
8010951e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109521:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109524:	8b 00                	mov    (%eax),%eax
80109526:	83 e0 01             	and    $0x1,%eax
80109529:	85 c0                	test   %eax,%eax
8010952b:	75 07                	jne    80109534 <uva2ka+0x36>
    return 0;
8010952d:	b8 00 00 00 00       	mov    $0x0,%eax
80109532:	eb 25                	jmp    80109559 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109534:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109537:	8b 00                	mov    (%eax),%eax
80109539:	83 e0 04             	and    $0x4,%eax
8010953c:	85 c0                	test   %eax,%eax
8010953e:	75 07                	jne    80109547 <uva2ka+0x49>
    return 0;
80109540:	b8 00 00 00 00       	mov    $0x0,%eax
80109545:	eb 12                	jmp    80109559 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109547:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010954a:	8b 00                	mov    (%eax),%eax
8010954c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109551:	89 04 24             	mov    %eax,(%esp)
80109554:	e8 ab f2 ff ff       	call   80108804 <p2v>
}
80109559:	c9                   	leave  
8010955a:	c3                   	ret    

8010955b <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010955b:	55                   	push   %ebp
8010955c:	89 e5                	mov    %esp,%ebp
8010955e:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109561:	8b 45 10             	mov    0x10(%ebp),%eax
80109564:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109567:	e9 8b 00 00 00       	jmp    801095f7 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
8010956c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010956f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109574:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109577:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010957a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010957e:	8b 45 08             	mov    0x8(%ebp),%eax
80109581:	89 04 24             	mov    %eax,(%esp)
80109584:	e8 75 ff ff ff       	call   801094fe <uva2ka>
80109589:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010958c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80109590:	75 07                	jne    80109599 <copyout+0x3e>
      return -1;
80109592:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109597:	eb 6d                	jmp    80109606 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109599:	8b 45 0c             	mov    0xc(%ebp),%eax
8010959c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010959f:	89 d1                	mov    %edx,%ecx
801095a1:	29 c1                	sub    %eax,%ecx
801095a3:	89 c8                	mov    %ecx,%eax
801095a5:	05 00 10 00 00       	add    $0x1000,%eax
801095aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801095ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095b0:	3b 45 14             	cmp    0x14(%ebp),%eax
801095b3:	76 06                	jbe    801095bb <copyout+0x60>
      n = len;
801095b5:	8b 45 14             	mov    0x14(%ebp),%eax
801095b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801095bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801095be:	8b 55 0c             	mov    0xc(%ebp),%edx
801095c1:	89 d1                	mov    %edx,%ecx
801095c3:	29 c1                	sub    %eax,%ecx
801095c5:	89 c8                	mov    %ecx,%eax
801095c7:	03 45 e8             	add    -0x18(%ebp),%eax
801095ca:	8b 55 f0             	mov    -0x10(%ebp),%edx
801095cd:	89 54 24 08          	mov    %edx,0x8(%esp)
801095d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801095d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801095d8:	89 04 24             	mov    %eax,(%esp)
801095db:	e8 8d cb ff ff       	call   8010616d <memmove>
    len -= n;
801095e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095e3:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801095e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801095e9:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801095ec:	8b 45 ec             	mov    -0x14(%ebp),%eax
801095ef:	05 00 10 00 00       	add    $0x1000,%eax
801095f4:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801095f7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801095fb:	0f 85 6b ff ff ff    	jne    8010956c <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80109601:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109606:	c9                   	leave  
80109607:	c3                   	ret    

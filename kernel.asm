
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
8010002d:	b8 af 42 10 80       	mov    $0x801042af,%eax
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
8010003a:	c7 44 24 04 d4 91 10 	movl   $0x801091d4,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 dc 59 00 00       	call   80105a2a <initlock>

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
801000bd:	e8 89 59 00 00       	call   80105a4b <acquire>

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
80100104:	e8 a4 59 00 00       	call   80105aad <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 49 56 00 00       	call   8010576d <sleep>
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
8010017c:	e8 2c 59 00 00       	call   80105aad <release>
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
80100198:	c7 04 24 db 91 10 80 	movl   $0x801091db,(%esp)
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
801001d3:	e8 84 34 00 00       	call   8010365c <iderw>
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
801001ef:	c7 04 24 ec 91 10 80 	movl   $0x801091ec,(%esp)
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
80100210:	e8 47 34 00 00       	call   8010365c <iderw>
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
80100229:	c7 04 24 f3 91 10 80 	movl   $0x801091f3,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 0a 58 00 00       	call   80105a4b <acquire>

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
8010029d:	e8 a4 55 00 00       	call   80105846 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 ff 57 00 00       	call   80105aad <release>
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
801003bc:	e8 8a 56 00 00       	call   80105a4b <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 fa 91 10 80 	movl   $0x801091fa,(%esp)
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
801004af:	c7 45 ec 03 92 10 80 	movl   $0x80109203,-0x14(%ebp)
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
80100536:	e8 72 55 00 00       	call   80105aad <release>
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
80100562:	c7 04 24 0a 92 10 80 	movl   $0x8010920a,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 19 92 10 80 	movl   $0x80109219,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 65 55 00 00       	call   80105afc <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 1b 92 10 80 	movl   $0x8010921b,(%esp)
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
801006b2:	e8 b6 56 00 00       	call   80105d6d <memmove>
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
801006e1:	e8 b4 55 00 00       	call   80105c9a <memset>
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
80100776:	e8 be 70 00 00       	call   80107839 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 b2 70 00 00       	call   80107839 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 a6 70 00 00       	call   80107839 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 99 70 00 00       	call   80107839 <uartputc>
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
801007ba:	e8 8c 52 00 00       	call   80105a4b <acquire>
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
801007ea:	e8 fa 50 00 00       	call   801058e9 <procdump>
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
801008f7:	e8 4a 4f 00 00       	call   80105846 <wakeup>
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
8010091e:	e8 8a 51 00 00       	call   80105aad <release>
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
80100931:	e8 04 1c 00 00       	call   8010253a <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100943:	e8 03 51 00 00       	call   80105a4b <acquire>
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
80100961:	e8 47 51 00 00       	call   80105aad <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 7b 1a 00 00       	call   801023ec <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 ed 10 	movl   $0x8010edc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 ee 10 80 	movl   $0x8010ee74,(%esp)
8010098a:	e8 de 4d 00 00       	call   8010576d <sleep>
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
80100a08:	e8 a0 50 00 00       	call   80105aad <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 d4 19 00 00       	call   801023ec <ilock>

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
80100a32:	e8 03 1b 00 00       	call   8010253a <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a3e:	e8 08 50 00 00       	call   80105a4b <acquire>
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
80100a78:	e8 30 50 00 00       	call   80105aad <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 64 19 00 00       	call   801023ec <ilock>

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
80100a93:	c7 44 24 04 1f 92 10 	movl   $0x8010921f,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 83 4f 00 00       	call   80105a2a <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 27 92 10 	movl   $0x80109227,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 6f 4f 00 00       	call   80105a2a <initlock>

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
80100ae0:	e8 84 3e 00 00       	call   80104969 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 25 2d 00 00       	call   8010381e <ioapicenable>
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
80100b0b:	e8 7e 24 00 00       	call   80102f8e <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 be 18 00 00       	call   801023ec <ilock>
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
80100b55:	e8 88 1d 00 00       	call   801028e2 <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 a7 39 10 80 	movl   $0x801039a7,(%esp)
80100b7b:	e8 fd 7d 00 00       	call   8010897d <setupkvm>
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
80100bc8:	e8 15 1d 00 00       	call   801028e2 <readi>
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
80100c14:	e8 36 81 00 00       	call   80108d4f <allocuvm>
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
80100c51:	e8 0a 80 00 00       	call   80108c60 <loaduvm>
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
80100c87:	e8 e4 19 00 00       	call   80102670 <iunlockput>
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
80100cbc:	e8 8e 80 00 00       	call   80108d4f <allocuvm>
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
80100ce0:	e8 8e 82 00 00       	call   80108f73 <clearpteu>
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
80100d0f:	e8 04 52 00 00       	call   80105f18 <strlen>
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
80100d2d:	e8 e6 51 00 00       	call   80105f18 <strlen>
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
80100d57:	e8 cb 83 00 00       	call   80109127 <copyout>
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
80100df7:	e8 2b 83 00 00       	call   80109127 <copyout>
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
80100e4e:	e8 77 50 00 00       	call   80105eca <safestrcpy>

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
80100ea0:	e8 c9 7b 00 00       	call   80108a6e <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 35 80 00 00       	call   80108ee5 <freevm>
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
80100ee2:	e8 fe 7f 00 00       	call   80108ee5 <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 78 17 00 00       	call   80102670 <iunlockput>
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
80100f06:	c7 44 24 04 30 92 10 	movl   $0x80109230,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100f15:	e8 10 4b 00 00       	call   80105a2a <initlock>
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
80100f29:	e8 1d 4b 00 00       	call   80105a4b <acquire>
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
80100f52:	e8 56 4b 00 00       	call   80105aad <release>
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
80100f70:	e8 38 4b 00 00       	call   80105aad <release>
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
80100f89:	e8 bd 4a 00 00       	call   80105a4b <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 37 92 10 80 	movl   $0x80109237,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 ee 10 80 	movl   $0x8010ee80,(%esp)
80100fba:	e8 ee 4a 00 00       	call   80105aad <release>
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
80100fd1:	e8 75 4a 00 00       	call   80105a4b <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 3f 92 10 80 	movl   $0x8010923f,(%esp)
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
8010100c:	e8 9c 4a 00 00       	call   80105aad <release>
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
80101056:	e8 52 4a 00 00       	call   80105aad <release>
  
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
80101074:	e8 aa 3b 00 00       	call   80104c23 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 3d 30 00 00       	call   801040c5 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 0c 15 00 00       	call   8010259f <iput>
    commit_trans();
80101093:	e8 76 30 00 00       	call   8010410e <commit_trans>
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
801010b3:	e8 34 13 00 00       	call   801023ec <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 d0 17 00 00       	call   8010289d <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 5f 14 00 00       	call   8010253a <iunlock>
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
80101125:	e8 7b 3c 00 00       	call   80104da5 <piperead>
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
8010113f:	e8 a8 12 00 00       	call   801023ec <ilock>
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
80101165:	e8 78 17 00 00       	call   801028e2 <readi>
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
8010118d:	e8 a8 13 00 00       	call   8010253a <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 49 92 10 80 	movl   $0x80109249,(%esp)
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
801011e2:	e8 ce 3a 00 00       	call   80104cb5 <pipewrite>
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
8010122a:	e8 96 2e 00 00       	call   801040c5 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 af 11 00 00       	call   801023ec <ilock>
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
80101263:	e8 e5 17 00 00       	call   80102a4d <writei>
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
8010128b:	e8 aa 12 00 00       	call   8010253a <iunlock>
      commit_trans();
80101290:	e8 79 2e 00 00       	call   8010410e <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 52 92 10 80 	movl   $0x80109252,(%esp)
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
801012d8:	c7 04 24 62 92 10 80 	movl   $0x80109262,(%esp)
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
801012fe:	e8 c6 56 00 00       	call   801069c9 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 6c 92 10 80 	movl   $0x8010926c,(%esp)
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
80101338:	e8 af 10 00 00       	call   801023ec <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 84 92 10 80 	movl   $0x80109284,(%esp)
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
80101382:	c7 04 24 a7 92 10 80 	movl   $0x801092a7,(%esp)
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
801013b7:	c7 04 24 c0 92 10 80 	movl   $0x801092c0,(%esp)
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
80101414:	c7 04 24 df 92 10 80 	movl   $0x801092df,(%esp)
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
8010143b:	e8 fa 10 00 00       	call   8010253a <iunlock>
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
8010146a:	e8 e9 09 00 00       	call   80101e58 <readsb>
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
8010153e:	c7 04 24 f8 92 10 80 	movl   $0x801092f8,(%esp)
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
80101624:	e8 5b 1c 00 00       	call   80103284 <getBlkRef>
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
80101643:	e8 0d 1b 00 00       	call   80103155 <updateBlkRef>
80101648:	eb 1e                	jmp    80101668 <deletedups+0xcb>
  else if(ref == 1)
8010164a:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
8010164e:	75 18                	jne    80101668 <deletedups+0xcb>
    bfree(b1->dev, b1->sector);
80101650:	8b 45 10             	mov    0x10(%ebp),%eax
80101653:	8b 50 08             	mov    0x8(%eax),%edx
80101656:	8b 45 10             	mov    0x10(%ebp),%eax
80101659:	8b 40 04             	mov    0x4(%eax),%eax
8010165c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101660:	89 04 24             	mov    %eax,(%esp)
80101663:	e8 f6 09 00 00       	call   8010205e <bfree>
}
80101668:	c9                   	leave  
80101669:	c3                   	ret    

8010166a <dedup>:

int
dedup(void)
{
8010166a:	55                   	push   %ebp
8010166b:	89 e5                	mov    %esp,%ebp
8010166d:	81 ec 98 00 00 00    	sub    $0x98,%esp
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0, iChanged;
80101673:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
8010167a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
80101681:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101688:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
8010168f:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  struct inode* ip1=0, *ip2=0;
80101696:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
8010169d:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
801016a4:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
801016ab:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
801016b2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
801016b9:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  uint *a = 0, *b = 0;
801016c0:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
801016c7:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  struct superblock sb;
  readsb(1, &sb);
801016ce:	8d 45 94             	lea    -0x6c(%ebp),%eax
801016d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801016d5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801016dc:	e8 77 07 00 00       	call   80101e58 <readsb>
  ninodes = sb.ninodes;
801016e1:	8b 45 9c             	mov    -0x64(%ebp),%eax
801016e4:	89 45 c0             	mov    %eax,-0x40(%ebp)
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
801016e7:	e9 51 07 00 00       	jmp    80101e3d <dedup+0x7d3>
  {  cprintf("in first while ip1->inum = %d\n",ip1->inum);
801016ec:	8b 45 bc             	mov    -0x44(%ebp),%eax
801016ef:	8b 40 04             	mov    0x4(%eax),%eax
801016f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801016f6:	c7 04 24 14 93 10 80 	movl   $0x80109314,(%esp)
801016fd:	e8 9f ec ff ff       	call   801003a1 <cprintf>
    iChanged = 0;
80101702:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
80101709:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010170c:	89 04 24             	mov    %eax,(%esp)
8010170f:	e8 d8 0c 00 00       	call   801023ec <ilock>
    if(ip1->addrs[NDIRECT])
80101714:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101717:	8b 40 4c             	mov    0x4c(%eax),%eax
8010171a:	85 c0                	test   %eax,%eax
8010171c:	74 2a                	je     80101748 <dedup+0xde>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
8010171e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101721:	8b 50 4c             	mov    0x4c(%eax),%edx
80101724:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101727:	8b 00                	mov    (%eax),%eax
80101729:	89 54 24 04          	mov    %edx,0x4(%esp)
8010172d:	89 04 24             	mov    %eax,(%esp)
80101730:	e8 71 ea ff ff       	call   801001a6 <bread>
80101735:	89 45 d8             	mov    %eax,-0x28(%ebp)
      a = (uint*)bp1->data;
80101738:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010173b:	83 c0 18             	add    $0x18,%eax
8010173e:	89 45 d0             	mov    %eax,-0x30(%ebp)
      indirects1 = NINDIRECT;
80101741:	c7 45 e8 80 00 00 00 	movl   $0x80,-0x18(%ebp)
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101748:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010174f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101756:	e9 80 06 00 00       	jmp    80101ddb <dedup+0x771>
    {cprintf("in first for blockIndex1 = %d\n",blockIndex1);
8010175b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010175e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101762:	c7 04 24 34 93 10 80 	movl   $0x80109334,(%esp)
80101769:	e8 33 ec ff ff       	call   801003a1 <cprintf>
      if(blockIndex1<NDIRECT)							// in the same file
8010176e:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101772:	0f 8f 29 02 00 00    	jg     801019a1 <dedup+0x337>
      {
	if(ip1->addrs[blockIndex1])
80101778:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010177b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010177e:	83 c2 04             	add    $0x4,%edx
80101781:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101785:	85 c0                	test   %eax,%eax
80101787:	0f 84 08 02 00 00    	je     80101995 <dedup+0x32b>
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
8010178d:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101790:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101793:	83 c2 04             	add    $0x4,%edx
80101796:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
8010179a:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010179d:	8b 00                	mov    (%eax),%eax
8010179f:	89 54 24 04          	mov    %edx,0x4(%esp)
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 fb e9 ff ff       	call   801001a6 <bread>
801017ab:	89 45 dc             	mov    %eax,-0x24(%ebp)
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
801017ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
801017b1:	83 c0 0b             	add    $0xb,%eax
801017b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
801017b7:	e9 c8 01 00 00       	jmp    80101984 <dedup+0x31a>
	  {
	    if(blockIndex2 < NDIRECT)
801017bc:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
801017c0:	0f 8f d8 00 00 00    	jg     8010189e <dedup+0x234>
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
801017c6:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017cc:	83 c2 04             	add    $0x4,%edx
801017cf:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017d3:	85 c0                	test   %eax,%eax
801017d5:	0f 84 a5 01 00 00    	je     80101980 <dedup+0x316>
801017db:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017de:	8b 55 f0             	mov    -0x10(%ebp),%edx
801017e1:	83 c2 04             	add    $0x4,%edx
801017e4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801017e8:	85 c0                	test   %eax,%eax
801017ea:	0f 84 90 01 00 00    	je     80101980 <dedup+0x316>
	      {//cprintf("in 2nd for if\n");
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
801017f0:	8b 45 bc             	mov    -0x44(%ebp),%eax
801017f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801017f6:	83 c2 04             	add    $0x4,%edx
801017f9:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801017fd:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101800:	8b 00                	mov    (%eax),%eax
80101802:	89 54 24 04          	mov    %edx,0x4(%esp)
80101806:	89 04 24             	mov    %eax,(%esp)
80101809:	e8 98 e9 ff ff       	call   801001a6 <bread>
8010180e:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		//cprintf("before blkcmp 1\n");
		if(blkcmp(b1,b2))
80101811:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101814:	89 44 24 04          	mov    %eax,0x4(%esp)
80101818:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010181b:	89 04 24             	mov    %eax,(%esp)
8010181e:	e8 32 fd ff ff       	call   80101555 <blkcmp>
80101823:	85 c0                	test   %eax,%eax
80101825:	74 67                	je     8010188e <dedup+0x224>
		{//cprintf("after blkcmp\n");
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
80101827:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
8010182e:	00 
8010182f:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
80101836:	00 
80101837:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010183a:	89 44 24 14          	mov    %eax,0x14(%esp)
8010183e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101841:	89 44 24 10          	mov    %eax,0x10(%esp)
80101845:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101848:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010184c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010184f:	89 44 24 08          	mov    %eax,0x8(%esp)
80101853:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101856:	89 44 24 04          	mov    %eax,0x4(%esp)
8010185a:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010185d:	89 04 24             	mov    %eax,(%esp)
80101860:	e8 38 fd ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101865:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101868:	89 04 24             	mov    %eax,(%esp)
8010186b:	e8 a7 e9 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101870:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101873:	89 04 24             	mov    %eax,(%esp)
80101876:	e8 9c e9 ff ff       	call   80100217 <brelse>
		  found = 1;
8010187b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101882:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101889:	e9 42 02 00 00       	jmp    80101ad0 <dedup+0x466>
		}
		brelse(b2);
8010188e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101891:	89 04 24             	mov    %eax,(%esp)
80101894:	e8 7e e9 ff ff       	call   80100217 <brelse>
80101899:	e9 e2 00 00 00       	jmp    80101980 <dedup+0x316>
	      }
	    }
	    else if(a)
8010189e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
801018a2:	0f 84 d8 00 00 00    	je     80101980 <dedup+0x316>
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
801018a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018ab:	83 e8 0c             	sub    $0xc,%eax
801018ae:	89 45 b0             	mov    %eax,-0x50(%ebp)
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset])
801018b1:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801018b7:	83 c2 04             	add    $0x4,%edx
801018ba:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801018be:	85 c0                	test   %eax,%eax
801018c0:	0f 84 ba 00 00 00    	je     80101980 <dedup+0x316>
801018c6:	8b 45 b0             	mov    -0x50(%ebp),%eax
801018c9:	c1 e0 02             	shl    $0x2,%eax
801018cc:	03 45 d0             	add    -0x30(%ebp),%eax
801018cf:	8b 00                	mov    (%eax),%eax
801018d1:	85 c0                	test   %eax,%eax
801018d3:	0f 84 a7 00 00 00    	je     80101980 <dedup+0x316>
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);//cprintf("before blkcmp 2\n");
801018d9:	8b 45 b0             	mov    -0x50(%ebp),%eax
801018dc:	c1 e0 02             	shl    $0x2,%eax
801018df:	03 45 d0             	add    -0x30(%ebp),%eax
801018e2:	8b 10                	mov    (%eax),%edx
801018e4:	8b 45 bc             	mov    -0x44(%ebp),%eax
801018e7:	8b 00                	mov    (%eax),%eax
801018e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801018ed:	89 04 24             	mov    %eax,(%esp)
801018f0:	e8 b1 e8 ff ff       	call   801001a6 <bread>
801018f5:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
801018f8:	8b 45 b4             	mov    -0x4c(%ebp),%eax
801018fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801018ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101902:	89 04 24             	mov    %eax,(%esp)
80101905:	e8 4b fc ff ff       	call   80101555 <blkcmp>
8010190a:	85 c0                	test   %eax,%eax
8010190c:	74 67                	je     80101975 <dedup+0x30b>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
8010190e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101911:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101915:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
8010191c:	00 
8010191d:	8b 45 b0             	mov    -0x50(%ebp),%eax
80101920:	89 44 24 14          	mov    %eax,0x14(%esp)
80101924:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101927:	89 44 24 10          	mov    %eax,0x10(%esp)
8010192b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
8010192e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101932:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101935:	89 44 24 08          	mov    %eax,0x8(%esp)
80101939:	8b 45 bc             	mov    -0x44(%ebp),%eax
8010193c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101940:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101943:	89 04 24             	mov    %eax,(%esp)
80101946:	e8 52 fc ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
8010194b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010194e:	89 04 24             	mov    %eax,(%esp)
80101951:	e8 c1 e8 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101956:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101959:	89 04 24             	mov    %eax,(%esp)
8010195c:	e8 b6 e8 ff ff       	call   80100217 <brelse>
		  found = 1;
80101961:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101968:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
8010196f:	90                   	nop
80101970:	e9 5b 01 00 00       	jmp    80101ad0 <dedup+0x466>
		}
		brelse(b2);
80101975:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101978:	89 04 24             	mov    %eax,(%esp)
8010197b:	e8 97 e8 ff ff       	call   80100217 <brelse>
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
80101980:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101984:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101987:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010198a:	0f 8f 2c fe ff ff    	jg     801017bc <dedup+0x152>
80101990:	e9 3b 01 00 00       	jmp    80101ad0 <dedup+0x466>
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{//cprintf("in 2nd else\n");
	  //brelse(b1);
	  b1 = 0;
80101995:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	  continue;
8010199c:	e9 2f 04 00 00       	jmp    80101dd0 <dedup+0x766>
// 	      brelse(b2);
// 	    }
// 	  } // for blockindex2 < NINDIRECT in ip1
// 	} //if not found match, check INDIRECT
//       } // if blockindex1 is < NDIRECT
      else if(!found)					// in the same file
801019a1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801019a5:	0f 85 25 01 00 00    	jne    80101ad0 <dedup+0x466>
      {
	if(a)
801019ab:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
801019af:	0f 84 1b 01 00 00    	je     80101ad0 <dedup+0x466>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
801019b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b8:	83 e8 0c             	sub    $0xc,%eax
801019bb:	89 45 ac             	mov    %eax,-0x54(%ebp)
	  if(a[blockIndex1Offset])
801019be:	8b 45 ac             	mov    -0x54(%ebp),%eax
801019c1:	c1 e0 02             	shl    $0x2,%eax
801019c4:	03 45 d0             	add    -0x30(%ebp),%eax
801019c7:	8b 00                	mov    (%eax),%eax
801019c9:	85 c0                	test   %eax,%eax
801019cb:	0f 84 f3 00 00 00    	je     80101ac4 <dedup+0x45a>
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
801019d1:	8b 45 ac             	mov    -0x54(%ebp),%eax
801019d4:	c1 e0 02             	shl    $0x2,%eax
801019d7:	03 45 d0             	add    -0x30(%ebp),%eax
801019da:	8b 10                	mov    (%eax),%edx
801019dc:	8b 45 bc             	mov    -0x44(%ebp),%eax
801019df:	8b 00                	mov    (%eax),%eax
801019e1:	89 54 24 04          	mov    %edx,0x4(%esp)
801019e5:	89 04 24             	mov    %eax,(%esp)
801019e8:	e8 b9 e7 ff ff       	call   801001a6 <bread>
801019ed:	89 45 dc             	mov    %eax,-0x24(%ebp)
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
801019f0:	c7 45 f0 7f 00 00 00 	movl   $0x7f,-0x10(%ebp)
801019f7:	e9 ba 00 00 00       	jmp    80101ab6 <dedup+0x44c>
	    {
	      if(a[blockIndex2])
801019fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019ff:	c1 e0 02             	shl    $0x2,%eax
80101a02:	03 45 d0             	add    -0x30(%ebp),%eax
80101a05:	8b 00                	mov    (%eax),%eax
80101a07:	85 c0                	test   %eax,%eax
80101a09:	0f 84 a3 00 00 00    	je     80101ab2 <dedup+0x448>
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);//cprintf("before blkcmp 3\n");
80101a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a12:	c1 e0 02             	shl    $0x2,%eax
80101a15:	03 45 d0             	add    -0x30(%ebp),%eax
80101a18:	8b 10                	mov    (%eax),%edx
80101a1a:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a1d:	8b 00                	mov    (%eax),%eax
80101a1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a23:	89 04 24             	mov    %eax,(%esp)
80101a26:	e8 7b e7 ff ff       	call   801001a6 <bread>
80101a2b:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101a2e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a31:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a35:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a38:	89 04 24             	mov    %eax,(%esp)
80101a3b:	e8 15 fb ff ff       	call   80101555 <blkcmp>
80101a40:	85 c0                	test   %eax,%eax
80101a42:	74 63                	je     80101aa7 <dedup+0x43d>
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
80101a44:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101a47:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101a4b:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101a4e:	89 44 24 18          	mov    %eax,0x18(%esp)
80101a52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a55:	89 44 24 14          	mov    %eax,0x14(%esp)
80101a59:	8b 45 ac             	mov    -0x54(%ebp),%eax
80101a5c:	89 44 24 10          	mov    %eax,0x10(%esp)
80101a60:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a63:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101a67:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a6a:	89 44 24 08          	mov    %eax,0x8(%esp)
80101a6e:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a71:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a75:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101a78:	89 04 24             	mov    %eax,(%esp)
80101a7b:	e8 1d fb ff ff       	call   8010159d <deletedups>
		  brelse(b1);				// release the outer loop block
80101a80:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101a83:	89 04 24             	mov    %eax,(%esp)
80101a86:	e8 8c e7 ff ff       	call   80100217 <brelse>
		  brelse(b2);
80101a8b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101a8e:	89 04 24             	mov    %eax,(%esp)
80101a91:	e8 81 e7 ff ff       	call   80100217 <brelse>
		  found = 1;
80101a96:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101a9d:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101aa4:	90                   	nop
80101aa5:	eb 29                	jmp    80101ad0 <dedup+0x466>
		}
		brelse(b2);
80101aa7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101aaa:	89 04 24             	mov    %eax,(%esp)
80101aad:	e8 65 e7 ff ff       	call   80100217 <brelse>
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
80101ab2:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101ab6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ab9:	3b 45 ac             	cmp    -0x54(%ebp),%eax
80101abc:	0f 8f 3a ff ff ff    	jg     801019fc <dedup+0x392>
80101ac2:	eb 0c                	jmp    80101ad0 <dedup+0x466>
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    //brelse(b1);
	    b1 = 0;
80101ac4:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	    continue;
80101acb:	e9 00 03 00 00       	jmp    80101dd0 <dedup+0x766>
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
80101ad0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101ad4:	0f 85 cd 02 00 00    	jne    80101da7 <dedup+0x73d>
80101ada:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80101ade:	0f 84 c3 02 00 00    	je     80101da7 <dedup+0x73d>
      {
	uint* aSub = 0;
80101ae4:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
	int blockIndex1Offset = blockIndex1;
80101aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101aee:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if(blockIndex1 >= NDIRECT)
80101af1:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101af5:	7e 0f                	jle    80101b06 <dedup+0x49c>
	{
	  aSub = a;
80101af7:	8b 45 d0             	mov    -0x30(%ebp),%eax
80101afa:	89 45 c8             	mov    %eax,-0x38(%ebp)
	  blockIndex1Offset = blockIndex1 - NDIRECT;
80101afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b00:	83 e8 0c             	sub    $0xc,%eax
80101b03:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	}
	prevInum = ninodes-1;
80101b06:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101b09:	83 e8 01             	sub    $0x1,%eax
80101b0c:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101b0f:	e9 7b 02 00 00       	jmp    80101d8f <dedup+0x725>
	{cprintf("ip2->inum = %d\n",ip2->inum);
80101b14:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b17:	8b 40 04             	mov    0x4(%eax),%eax
80101b1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b1e:	c7 04 24 53 93 10 80 	movl   $0x80109353,(%esp)
80101b25:	e8 77 e8 ff ff       	call   801003a1 <cprintf>
	  ilock(ip2);
80101b2a:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b2d:	89 04 24             	mov    %eax,(%esp)
80101b30:	e8 b7 08 00 00       	call   801023ec <ilock>
	  if(ip2->addrs[NDIRECT])
80101b35:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b38:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b3b:	85 c0                	test   %eax,%eax
80101b3d:	74 2a                	je     80101b69 <dedup+0x4ff>
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
80101b3f:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b42:	8b 50 4c             	mov    0x4c(%eax),%edx
80101b45:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b48:	8b 00                	mov    (%eax),%eax
80101b4a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b4e:	89 04 24             	mov    %eax,(%esp)
80101b51:	e8 50 e6 ff ff       	call   801001a6 <bread>
80101b56:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	    b = (uint*)bp2->data;
80101b59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101b5c:	83 c0 18             	add    $0x18,%eax
80101b5f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	    indirects2 = NINDIRECT;
80101b62:	c7 45 e4 80 00 00 00 	movl   $0x80,-0x1c(%ebp)
	  } // if ip2 has INDIRECT
	  cprintf("before 1st for\n");
80101b69:	c7 04 24 63 93 10 80 	movl   $0x80109363,(%esp)
80101b70:	e8 2c e8 ff ff       	call   801003a1 <cprintf>
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101b75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101b78:	83 c0 0b             	add    $0xb,%eax
80101b7b:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101b7e:	e9 ca 01 00 00       	jmp    80101d4d <dedup+0x6e3>
	  {//cprintf("in 1st for\n");
	    if(blockIndex2<NDIRECT)
80101b83:	83 7d f0 0b          	cmpl   $0xb,-0x10(%ebp)
80101b87:	0f 8f db 00 00 00    	jg     80101c68 <dedup+0x5fe>
	    {
	      if(ip2->addrs[blockIndex2])
80101b8d:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101b90:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101b93:	83 c2 04             	add    $0x4,%edx
80101b96:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b9a:	85 c0                	test   %eax,%eax
80101b9c:	0f 84 a7 01 00 00    	je     80101d49 <dedup+0x6df>
	      {
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);//cprintf("before blkcmp 4\n");
80101ba2:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101ba5:	8b 55 f0             	mov    -0x10(%ebp),%edx
80101ba8:	83 c2 04             	add    $0x4,%edx
80101bab:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101baf:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101bb2:	8b 00                	mov    (%eax),%eax
80101bb4:	89 54 24 04          	mov    %edx,0x4(%esp)
80101bb8:	89 04 24             	mov    %eax,(%esp)
80101bbb:	e8 e6 e5 ff ff       	call   801001a6 <bread>
80101bc0:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101bc3:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bc6:	89 44 24 04          	mov    %eax,0x4(%esp)
80101bca:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101bcd:	89 04 24             	mov    %eax,(%esp)
80101bd0:	e8 80 f9 ff ff       	call   80101555 <blkcmp>
80101bd5:	85 c0                	test   %eax,%eax
80101bd7:	74 7f                	je     80101c58 <dedup+0x5ee>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
80101bd9:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
80101be0:	00 
80101be1:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101be4:	89 44 24 18          	mov    %eax,0x18(%esp)
80101be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101beb:	89 44 24 14          	mov    %eax,0x14(%esp)
80101bef:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101bf2:	89 44 24 10          	mov    %eax,0x10(%esp)
80101bf6:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101bfd:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c00:	89 44 24 08          	mov    %eax,0x8(%esp)
80101c04:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c07:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c0b:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101c0e:	89 04 24             	mov    %eax,(%esp)
80101c11:	e8 87 f9 ff ff       	call   8010159d <deletedups>
		  cprintf("*****************before 1st brelse direct\n"); 
80101c16:	c7 04 24 74 93 10 80 	movl   $0x80109374,(%esp)
80101c1d:	e8 7f e7 ff ff       	call   801003a1 <cprintf>
		  brelse(b1);				// release the outer loop block
80101c22:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101c25:	89 04 24             	mov    %eax,(%esp)
80101c28:	e8 ea e5 ff ff       	call   80100217 <brelse>
		  cprintf("*****************after 1st brelse b1 direct\n"); 
80101c2d:	c7 04 24 a0 93 10 80 	movl   $0x801093a0,(%esp)
80101c34:	e8 68 e7 ff ff       	call   801003a1 <cprintf>
		  //brelse(b2);
		  cprintf("*****************after 1st brelse b2 direct\n"); 
80101c39:	c7 04 24 d0 93 10 80 	movl   $0x801093d0,(%esp)
80101c40:	e8 5c e7 ff ff       	call   801003a1 <cprintf>
		  found = 1;
80101c45:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101c4c:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101c53:	e9 ff 00 00 00       	jmp    80101d57 <dedup+0x6ed>
		}//cprintf("before 1st brelse\n");
		brelse(b2);
80101c58:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101c5b:	89 04 24             	mov    %eax,(%esp)
80101c5e:	e8 b4 e5 ff ff       	call   80100217 <brelse>
80101c63:	e9 e1 00 00 00       	jmp    80101d49 <dedup+0x6df>
		//cprintf("after 1st brelse\n");
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
80101c68:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
80101c6c:	0f 84 d7 00 00 00    	je     80101d49 <dedup+0x6df>
	    {//cprintf("inside else if\n");
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
80101c72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c75:	83 e8 0c             	sub    $0xc,%eax
80101c78:	89 45 a8             	mov    %eax,-0x58(%ebp)
	      if(b[blockIndex2Offset])
80101c7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101c7e:	c1 e0 02             	shl    $0x2,%eax
80101c81:	03 45 cc             	add    -0x34(%ebp),%eax
80101c84:	8b 00                	mov    (%eax),%eax
80101c86:	85 c0                	test   %eax,%eax
80101c88:	0f 84 bb 00 00 00    	je     80101d49 <dedup+0x6df>
	      {//cprintf("inside indirects2\n");
		b2 = bread(ip2->dev,b[blockIndex2Offset]);//cprintf("before blkcmp 5\n");
80101c8e:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101c91:	c1 e0 02             	shl    $0x2,%eax
80101c94:	03 45 cc             	add    -0x34(%ebp),%eax
80101c97:	8b 10                	mov    (%eax),%edx
80101c99:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101c9c:	8b 00                	mov    (%eax),%eax
80101c9e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ca2:	89 04 24             	mov    %eax,(%esp)
80101ca5:	e8 fc e4 ff ff       	call   801001a6 <bread>
80101caa:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		if(blkcmp(b1,b2))
80101cad:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cb4:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101cb7:	89 04 24             	mov    %eax,(%esp)
80101cba:	e8 96 f8 ff ff       	call   80101555 <blkcmp>
80101cbf:	85 c0                	test   %eax,%eax
80101cc1:	74 7b                	je     80101d3e <dedup+0x6d4>
		{
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
80101cc3:	8b 45 cc             	mov    -0x34(%ebp),%eax
80101cc6:	89 44 24 1c          	mov    %eax,0x1c(%esp)
80101cca:	8b 45 c8             	mov    -0x38(%ebp),%eax
80101ccd:	89 44 24 18          	mov    %eax,0x18(%esp)
80101cd1:	8b 45 a8             	mov    -0x58(%ebp),%eax
80101cd4:	89 44 24 14          	mov    %eax,0x14(%esp)
80101cd8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
80101cdb:	89 44 24 10          	mov    %eax,0x10(%esp)
80101cdf:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101ce2:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101ce6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101ce9:	89 44 24 08          	mov    %eax,0x8(%esp)
80101ced:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101cf0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cf4:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101cf7:	89 04 24             	mov    %eax,(%esp)
80101cfa:	e8 9e f8 ff ff       	call   8010159d <deletedups>
		  cprintf("*****************before 2nd brelse indirect\n"); 
80101cff:	c7 04 24 00 94 10 80 	movl   $0x80109400,(%esp)
80101d06:	e8 96 e6 ff ff       	call   801003a1 <cprintf>
		  brelse(b1);				// release the outer loop block
80101d0b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101d0e:	89 04 24             	mov    %eax,(%esp)
80101d11:	e8 01 e5 ff ff       	call   80100217 <brelse>
		  cprintf("*****************after 2nd brelse indirect\n"); 
80101d16:	c7 04 24 30 94 10 80 	movl   $0x80109430,(%esp)
80101d1d:	e8 7f e6 ff ff       	call   801003a1 <cprintf>
		  //brelse(b2);
		  cprintf("*****************after 2nd brelse indirect\n"); 
80101d22:	c7 04 24 30 94 10 80 	movl   $0x80109430,(%esp)
80101d29:	e8 73 e6 ff ff       	call   801003a1 <cprintf>
		  found = 1;
80101d2e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		  iChanged = 1;
80101d35:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		  break;
80101d3c:	eb 19                	jmp    80101d57 <dedup+0x6ed>
		}//cprintf("before 2nd brelse\n");
		brelse(b2);
80101d3e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
80101d41:	89 04 24             	mov    %eax,(%esp)
80101d44:	e8 ce e4 ff ff       	call   80100217 <brelse>
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  cprintf("before 1st for\n");
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
80101d49:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
80101d4d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101d51:	0f 89 2c fe ff ff    	jns    80101b83 <dedup+0x519>
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
80101d57:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d5a:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d5d:	85 c0                	test   %eax,%eax
80101d5f:	74 23                	je     80101d84 <dedup+0x71a>
	  {
	    cprintf("before bp2 brelse\n");
80101d61:	c7 04 24 5c 94 10 80 	movl   $0x8010945c,(%esp)
80101d68:	e8 34 e6 ff ff       	call   801003a1 <cprintf>
	    brelse(bp2);
80101d6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101d70:	89 04 24             	mov    %eax,(%esp)
80101d73:	e8 9f e4 ff ff       	call   80100217 <brelse>
	    cprintf("after bp2 brelse\n"); 
80101d78:	c7 04 24 6f 94 10 80 	movl   $0x8010946f,(%esp)
80101d7f:	e8 1d e6 ff ff       	call   801003a1 <cprintf>
	  }
	  
	  iunlockput(ip2);
80101d84:	8b 45 b8             	mov    -0x48(%ebp),%eax
80101d87:	89 04 24             	mov    %eax,(%esp)
80101d8a:	e8 e1 08 00 00       	call   80102670 <iunlockput>
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while((ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
80101d8f:	8d 45 a4             	lea    -0x5c(%ebp),%eax
80101d92:	89 04 24             	mov    %eax,(%esp)
80101d95:	e8 0a 13 00 00       	call   801030a4 <getPrevInode>
80101d9a:	89 45 b8             	mov    %eax,-0x48(%ebp)
80101d9d:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
80101da1:	0f 85 6d fd ff ff    	jne    80101b14 <dedup+0x4aa>
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
80101da7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80101dab:	75 23                	jne    80101dd0 <dedup+0x766>
      {
	cprintf("*****************before 1st brelse\n"); 
80101dad:	c7 04 24 84 94 10 80 	movl   $0x80109484,(%esp)
80101db4:	e8 e8 e5 ff ff       	call   801003a1 <cprintf>
	brelse(b1);				// release the outer loop block
80101db9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101dbc:	89 04 24             	mov    %eax,(%esp)
80101dbf:	e8 53 e4 ff ff       	call   80100217 <brelse>
	cprintf("*****************after 1st brelse\n"); 
80101dc4:	c7 04 24 a8 94 10 80 	movl   $0x801094a8,(%esp)
80101dcb:	e8 d1 e5 ff ff       	call   801003a1 <cprintf>
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
80101dd0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101dd4:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101ddb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101dde:	83 c0 0c             	add    $0xc,%eax
80101de1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80101de4:	0f 8f 71 f9 ff ff    	jg     8010175b <dedup+0xf1>
	brelse(b1);				// release the outer loop block
	cprintf("*****************after 1st brelse\n"); 
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
80101dea:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101ded:	8b 40 4c             	mov    0x4c(%eax),%eax
80101df0:	85 c0                	test   %eax,%eax
80101df2:	74 23                	je     80101e17 <dedup+0x7ad>
    {
      cprintf("*****************before bp1 brelse\n"); 
80101df4:	c7 04 24 cc 94 10 80 	movl   $0x801094cc,(%esp)
80101dfb:	e8 a1 e5 ff ff       	call   801003a1 <cprintf>
      brelse(bp1);
80101e00:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101e03:	89 04 24             	mov    %eax,(%esp)
80101e06:	e8 0c e4 ff ff       	call   80100217 <brelse>
      cprintf("*****************after bp1 brelse\n");
80101e0b:	c7 04 24 f0 94 10 80 	movl   $0x801094f0,(%esp)
80101e12:	e8 8a e5 ff ff       	call   801003a1 <cprintf>
    }
    
    if(iChanged)
80101e17:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101e1b:	74 15                	je     80101e32 <dedup+0x7c8>
    {
      begin_trans();
80101e1d:	e8 a3 22 00 00       	call   801040c5 <begin_trans>
      iupdate(ip1);
80101e22:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e25:	89 04 24             	mov    %eax,(%esp)
80101e28:	e8 03 04 00 00       	call   80102230 <iupdate>
      commit_trans();
80101e2d:	e8 dc 22 00 00       	call   8010410e <commit_trans>
    }
    iunlockput(ip1);
80101e32:	8b 45 bc             	mov    -0x44(%ebp),%eax
80101e35:	89 04 24             	mov    %eax,(%esp)
80101e38:	e8 33 08 00 00       	call   80102670 <iunlockput>
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  while((ip1 = getNextInode()) != 0) //iterate over all the files in the system - outer file loop
80101e3d:	e8 90 11 00 00       	call   80102fd2 <getNextInode>
80101e42:	89 45 bc             	mov    %eax,-0x44(%ebp)
80101e45:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
80101e49:	0f 85 9d f8 ff ff    	jne    801016ec <dedup+0x82>
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
80101e4f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101e54:	c9                   	leave  
80101e55:	c3                   	ret    
	...

80101e58 <readsb>:
int prevInum = 0;

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101e58:	55                   	push   %ebp
80101e59:	89 e5                	mov    %esp,%ebp
80101e5b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101e5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101e61:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101e68:	00 
80101e69:	89 04 24             	mov    %eax,(%esp)
80101e6c:	e8 35 e3 ff ff       	call   801001a6 <bread>
80101e71:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e77:	83 c0 18             	add    $0x18,%eax
80101e7a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101e81:	00 
80101e82:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e86:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e89:	89 04 24             	mov    %eax,(%esp)
80101e8c:	e8 dc 3e 00 00       	call   80105d6d <memmove>
  brelse(bp);
80101e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e94:	89 04 24             	mov    %eax,(%esp)
80101e97:	e8 7b e3 ff ff       	call   80100217 <brelse>
}
80101e9c:	c9                   	leave  
80101e9d:	c3                   	ret    

80101e9e <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101e9e:	55                   	push   %ebp
80101e9f:	89 e5                	mov    %esp,%ebp
80101ea1:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
80101ea4:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ea7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eaa:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eae:	89 04 24             	mov    %eax,(%esp)
80101eb1:	e8 f0 e2 ff ff       	call   801001a6 <bread>
80101eb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101eb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ebc:	83 c0 18             	add    $0x18,%eax
80101ebf:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101ec6:	00 
80101ec7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101ece:	00 
80101ecf:	89 04 24             	mov    %eax,(%esp)
80101ed2:	e8 c3 3d 00 00       	call   80105c9a <memset>
  log_write(bp);
80101ed7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eda:	89 04 24             	mov    %eax,(%esp)
80101edd:	e8 84 22 00 00       	call   80104166 <log_write>
  brelse(bp);
80101ee2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ee5:	89 04 24             	mov    %eax,(%esp)
80101ee8:	e8 2a e3 ff ff       	call   80100217 <brelse>
}
80101eed:	c9                   	leave  
80101eee:	c3                   	ret    

80101eef <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101eef:	55                   	push   %ebp
80101ef0:	89 e5                	mov    %esp,%ebp
80101ef2:	53                   	push   %ebx
80101ef3:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101ef6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101efd:	8b 45 08             	mov    0x8(%ebp),%eax
80101f00:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101f03:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f07:	89 04 24             	mov    %eax,(%esp)
80101f0a:	e8 49 ff ff ff       	call   80101e58 <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101f0f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f16:	e9 29 01 00 00       	jmp    80102044 <balloc+0x155>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f1e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101f24:	85 c0                	test   %eax,%eax
80101f26:	0f 48 c2             	cmovs  %edx,%eax
80101f29:	c1 f8 0c             	sar    $0xc,%eax
80101f2c:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101f2f:	c1 ea 03             	shr    $0x3,%edx
80101f32:	01 d0                	add    %edx,%eax
80101f34:	83 c0 03             	add    $0x3,%eax
80101f37:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3e:	89 04 24             	mov    %eax,(%esp)
80101f41:	e8 60 e2 ff ff       	call   801001a6 <bread>
80101f46:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101f49:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101f50:	e9 bf 00 00 00       	jmp    80102014 <balloc+0x125>
      m = 1 << (bi % 8);
80101f55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f58:	89 c2                	mov    %eax,%edx
80101f5a:	c1 fa 1f             	sar    $0x1f,%edx
80101f5d:	c1 ea 1d             	shr    $0x1d,%edx
80101f60:	01 d0                	add    %edx,%eax
80101f62:	83 e0 07             	and    $0x7,%eax
80101f65:	29 d0                	sub    %edx,%eax
80101f67:	ba 01 00 00 00       	mov    $0x1,%edx
80101f6c:	89 d3                	mov    %edx,%ebx
80101f6e:	89 c1                	mov    %eax,%ecx
80101f70:	d3 e3                	shl    %cl,%ebx
80101f72:	89 d8                	mov    %ebx,%eax
80101f74:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101f77:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f7a:	8d 50 07             	lea    0x7(%eax),%edx
80101f7d:	85 c0                	test   %eax,%eax
80101f7f:	0f 48 c2             	cmovs  %edx,%eax
80101f82:	c1 f8 03             	sar    $0x3,%eax
80101f85:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101f88:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101f8d:	0f b6 c0             	movzbl %al,%eax
80101f90:	23 45 e8             	and    -0x18(%ebp),%eax
80101f93:	85 c0                	test   %eax,%eax
80101f95:	75 79                	jne    80102010 <balloc+0x121>
        bp->data[bi/8] |= m;  // Mark block in use.
80101f97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f9a:	8d 50 07             	lea    0x7(%eax),%edx
80101f9d:	85 c0                	test   %eax,%eax
80101f9f:	0f 48 c2             	cmovs  %edx,%eax
80101fa2:	c1 f8 03             	sar    $0x3,%eax
80101fa5:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101fa8:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101fad:	89 d1                	mov    %edx,%ecx
80101faf:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101fb2:	09 ca                	or     %ecx,%edx
80101fb4:	89 d1                	mov    %edx,%ecx
80101fb6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101fb9:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101fbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fc0:	89 04 24             	mov    %eax,(%esp)
80101fc3:	e8 9e 21 00 00       	call   80104166 <log_write>
        brelse(bp);
80101fc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fcb:	89 04 24             	mov    %eax,(%esp)
80101fce:	e8 44 e2 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101fd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fd6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101fd9:	01 c2                	add    %eax,%edx
80101fdb:	8b 45 08             	mov    0x8(%ebp),%eax
80101fde:	89 54 24 04          	mov    %edx,0x4(%esp)
80101fe2:	89 04 24             	mov    %eax,(%esp)
80101fe5:	e8 b4 fe ff ff       	call   80101e9e <bzero>
	updateBlkRef(b+bi,1);
80101fea:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fed:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ff0:	01 d0                	add    %edx,%eax
80101ff2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101ff9:	00 
80101ffa:	89 04 24             	mov    %eax,(%esp)
80101ffd:	e8 53 11 00 00       	call   80103155 <updateBlkRef>
        return b + bi;
80102002:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102005:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102008:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010200a:	83 c4 34             	add    $0x34,%esp
8010200d:	5b                   	pop    %ebx
8010200e:	5d                   	pop    %ebp
8010200f:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80102010:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102014:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010201b:	7f 15                	jg     80102032 <balloc+0x143>
8010201d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102020:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102023:	01 d0                	add    %edx,%eax
80102025:	89 c2                	mov    %eax,%edx
80102027:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010202a:	39 c2                	cmp    %eax,%edx
8010202c:	0f 82 23 ff ff ff    	jb     80101f55 <balloc+0x66>
        bzero(dev, b + bi);
	updateBlkRef(b+bi,1);
        return b + bi;
      }
    }
    brelse(bp);
80102032:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102035:	89 04 24             	mov    %eax,(%esp)
80102038:	e8 da e1 ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
8010203d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102044:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102047:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010204a:	39 c2                	cmp    %eax,%edx
8010204c:	0f 82 c9 fe ff ff    	jb     80101f1b <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80102052:	c7 04 24 13 95 10 80 	movl   $0x80109513,(%esp)
80102059:	e8 df e4 ff ff       	call   8010053d <panic>

8010205e <bfree>:
}

// Free a disk block.
void
bfree(int dev, uint b)
{
8010205e:	55                   	push   %ebp
8010205f:	89 e5                	mov    %esp,%ebp
80102061:	53                   	push   %ebx
80102062:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80102065:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102068:	89 44 24 04          	mov    %eax,0x4(%esp)
8010206c:	8b 45 08             	mov    0x8(%ebp),%eax
8010206f:	89 04 24             	mov    %eax,(%esp)
80102072:	e8 e1 fd ff ff       	call   80101e58 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80102077:	8b 45 0c             	mov    0xc(%ebp),%eax
8010207a:	89 c2                	mov    %eax,%edx
8010207c:	c1 ea 0c             	shr    $0xc,%edx
8010207f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102082:	c1 e8 03             	shr    $0x3,%eax
80102085:	01 d0                	add    %edx,%eax
80102087:	8d 50 03             	lea    0x3(%eax),%edx
8010208a:	8b 45 08             	mov    0x8(%ebp),%eax
8010208d:	89 54 24 04          	mov    %edx,0x4(%esp)
80102091:	89 04 24             	mov    %eax,(%esp)
80102094:	e8 0d e1 ff ff       	call   801001a6 <bread>
80102099:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010209c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010209f:	25 ff 0f 00 00       	and    $0xfff,%eax
801020a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801020a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020aa:	89 c2                	mov    %eax,%edx
801020ac:	c1 fa 1f             	sar    $0x1f,%edx
801020af:	c1 ea 1d             	shr    $0x1d,%edx
801020b2:	01 d0                	add    %edx,%eax
801020b4:	83 e0 07             	and    $0x7,%eax
801020b7:	29 d0                	sub    %edx,%eax
801020b9:	ba 01 00 00 00       	mov    $0x1,%edx
801020be:	89 d3                	mov    %edx,%ebx
801020c0:	89 c1                	mov    %eax,%ecx
801020c2:	d3 e3                	shl    %cl,%ebx
801020c4:	89 d8                	mov    %ebx,%eax
801020c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801020c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020cc:	8d 50 07             	lea    0x7(%eax),%edx
801020cf:	85 c0                	test   %eax,%eax
801020d1:	0f 48 c2             	cmovs  %edx,%eax
801020d4:	c1 f8 03             	sar    $0x3,%eax
801020d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801020da:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801020df:	0f b6 c0             	movzbl %al,%eax
801020e2:	23 45 ec             	and    -0x14(%ebp),%eax
801020e5:	85 c0                	test   %eax,%eax
801020e7:	75 0c                	jne    801020f5 <bfree+0x97>
    panic("freeing free block");
801020e9:	c7 04 24 29 95 10 80 	movl   $0x80109529,(%esp)
801020f0:	e8 48 e4 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801020f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020f8:	8d 50 07             	lea    0x7(%eax),%edx
801020fb:	85 c0                	test   %eax,%eax
801020fd:	0f 48 c2             	cmovs  %edx,%eax
80102100:	c1 f8 03             	sar    $0x3,%eax
80102103:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102106:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010210b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010210e:	f7 d1                	not    %ecx
80102110:	21 ca                	and    %ecx,%edx
80102112:	89 d1                	mov    %edx,%ecx
80102114:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102117:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010211b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010211e:	89 04 24             	mov    %eax,(%esp)
80102121:	e8 40 20 00 00       	call   80104166 <log_write>
  brelse(bp);
80102126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102129:	89 04 24             	mov    %eax,(%esp)
8010212c:	e8 e6 e0 ff ff       	call   80100217 <brelse>
}
80102131:	83 c4 34             	add    $0x34,%esp
80102134:	5b                   	pop    %ebx
80102135:	5d                   	pop    %ebp
80102136:	c3                   	ret    

80102137 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80102137:	55                   	push   %ebp
80102138:	89 e5                	mov    %esp,%ebp
8010213a:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
8010213d:	c7 44 24 04 3c 95 10 	movl   $0x8010953c,0x4(%esp)
80102144:	80 
80102145:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010214c:	e8 d9 38 00 00       	call   80105a2a <initlock>
}
80102151:	c9                   	leave  
80102152:	c3                   	ret    

80102153 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80102153:	55                   	push   %ebp
80102154:	89 e5                	mov    %esp,%ebp
80102156:	83 ec 48             	sub    $0x48,%esp
80102159:	8b 45 0c             	mov    0xc(%ebp),%eax
8010215c:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80102160:	8b 45 08             	mov    0x8(%ebp),%eax
80102163:	8d 55 dc             	lea    -0x24(%ebp),%edx
80102166:	89 54 24 04          	mov    %edx,0x4(%esp)
8010216a:	89 04 24             	mov    %eax,(%esp)
8010216d:	e8 e6 fc ff ff       	call   80101e58 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80102172:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80102179:	e9 98 00 00 00       	jmp    80102216 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010217e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102181:	c1 e8 03             	shr    $0x3,%eax
80102184:	83 c0 02             	add    $0x2,%eax
80102187:	89 44 24 04          	mov    %eax,0x4(%esp)
8010218b:	8b 45 08             	mov    0x8(%ebp),%eax
8010218e:	89 04 24             	mov    %eax,(%esp)
80102191:	e8 10 e0 ff ff       	call   801001a6 <bread>
80102196:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80102199:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010219c:	8d 50 18             	lea    0x18(%eax),%edx
8010219f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021a2:	83 e0 07             	and    $0x7,%eax
801021a5:	c1 e0 06             	shl    $0x6,%eax
801021a8:	01 d0                	add    %edx,%eax
801021aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801021ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021b0:	0f b7 00             	movzwl (%eax),%eax
801021b3:	66 85 c0             	test   %ax,%ax
801021b6:	75 4f                	jne    80102207 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801021b8:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801021bf:	00 
801021c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801021c7:	00 
801021c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021cb:	89 04 24             	mov    %eax,(%esp)
801021ce:	e8 c7 3a 00 00       	call   80105c9a <memset>
      dip->type = type;
801021d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021d6:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801021da:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801021dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021e0:	89 04 24             	mov    %eax,(%esp)
801021e3:	e8 7e 1f 00 00       	call   80104166 <log_write>
      brelse(bp);
801021e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021eb:	89 04 24             	mov    %eax,(%esp)
801021ee:	e8 24 e0 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801021f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021fa:	8b 45 08             	mov    0x8(%ebp),%eax
801021fd:	89 04 24             	mov    %eax,(%esp)
80102200:	e8 e3 00 00 00       	call   801022e8 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80102205:	c9                   	leave  
80102206:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80102207:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010220a:	89 04 24             	mov    %eax,(%esp)
8010220d:	e8 05 e0 ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80102212:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102216:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102219:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010221c:	39 c2                	cmp    %eax,%edx
8010221e:	0f 82 5a ff ff ff    	jb     8010217e <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80102224:	c7 04 24 43 95 10 80 	movl   $0x80109543,(%esp)
8010222b:	e8 0d e3 ff ff       	call   8010053d <panic>

80102230 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80102230:	55                   	push   %ebp
80102231:	89 e5                	mov    %esp,%ebp
80102233:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80102236:	8b 45 08             	mov    0x8(%ebp),%eax
80102239:	8b 40 04             	mov    0x4(%eax),%eax
8010223c:	c1 e8 03             	shr    $0x3,%eax
8010223f:	8d 50 02             	lea    0x2(%eax),%edx
80102242:	8b 45 08             	mov    0x8(%ebp),%eax
80102245:	8b 00                	mov    (%eax),%eax
80102247:	89 54 24 04          	mov    %edx,0x4(%esp)
8010224b:	89 04 24             	mov    %eax,(%esp)
8010224e:	e8 53 df ff ff       	call   801001a6 <bread>
80102253:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80102256:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102259:	8d 50 18             	lea    0x18(%eax),%edx
8010225c:	8b 45 08             	mov    0x8(%ebp),%eax
8010225f:	8b 40 04             	mov    0x4(%eax),%eax
80102262:	83 e0 07             	and    $0x7,%eax
80102265:	c1 e0 06             	shl    $0x6,%eax
80102268:	01 d0                	add    %edx,%eax
8010226a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010226d:	8b 45 08             	mov    0x8(%ebp),%eax
80102270:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80102274:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102277:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010227a:	8b 45 08             	mov    0x8(%ebp),%eax
8010227d:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80102281:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102284:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80102288:	8b 45 08             	mov    0x8(%ebp),%eax
8010228b:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010228f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102292:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80102296:	8b 45 08             	mov    0x8(%ebp),%eax
80102299:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010229d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022a0:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801022a4:	8b 45 08             	mov    0x8(%ebp),%eax
801022a7:	8b 50 18             	mov    0x18(%eax),%edx
801022aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022ad:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801022b0:	8b 45 08             	mov    0x8(%ebp),%eax
801022b3:	8d 50 1c             	lea    0x1c(%eax),%edx
801022b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b9:	83 c0 0c             	add    $0xc,%eax
801022bc:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801022c3:	00 
801022c4:	89 54 24 04          	mov    %edx,0x4(%esp)
801022c8:	89 04 24             	mov    %eax,(%esp)
801022cb:	e8 9d 3a 00 00       	call   80105d6d <memmove>
  log_write(bp);
801022d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022d3:	89 04 24             	mov    %eax,(%esp)
801022d6:	e8 8b 1e 00 00       	call   80104166 <log_write>
  brelse(bp);
801022db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022de:	89 04 24             	mov    %eax,(%esp)
801022e1:	e8 31 df ff ff       	call   80100217 <brelse>
}
801022e6:	c9                   	leave  
801022e7:	c3                   	ret    

801022e8 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801022e8:	55                   	push   %ebp
801022e9:	89 e5                	mov    %esp,%ebp
801022eb:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801022ee:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801022f5:	e8 51 37 00 00       	call   80105a4b <acquire>

  // Is the inode already cached?
  empty = 0;
801022fa:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80102301:	c7 45 f4 b4 f8 10 80 	movl   $0x8010f8b4,-0xc(%ebp)
80102308:	eb 59                	jmp    80102363 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010230a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010230d:	8b 40 08             	mov    0x8(%eax),%eax
80102310:	85 c0                	test   %eax,%eax
80102312:	7e 35                	jle    80102349 <iget+0x61>
80102314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102317:	8b 00                	mov    (%eax),%eax
80102319:	3b 45 08             	cmp    0x8(%ebp),%eax
8010231c:	75 2b                	jne    80102349 <iget+0x61>
8010231e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102321:	8b 40 04             	mov    0x4(%eax),%eax
80102324:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102327:	75 20                	jne    80102349 <iget+0x61>
      ip->ref++;
80102329:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010232c:	8b 40 08             	mov    0x8(%eax),%eax
8010232f:	8d 50 01             	lea    0x1(%eax),%edx
80102332:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102335:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80102338:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010233f:	e8 69 37 00 00       	call   80105aad <release>
      return ip;
80102344:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102347:	eb 6f                	jmp    801023b8 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80102349:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010234d:	75 10                	jne    8010235f <iget+0x77>
8010234f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102352:	8b 40 08             	mov    0x8(%eax),%eax
80102355:	85 c0                	test   %eax,%eax
80102357:	75 06                	jne    8010235f <iget+0x77>
      empty = ip;
80102359:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010235c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010235f:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80102363:	81 7d f4 54 08 11 80 	cmpl   $0x80110854,-0xc(%ebp)
8010236a:	72 9e                	jb     8010230a <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010236c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102370:	75 0c                	jne    8010237e <iget+0x96>
    panic("iget: no inodes");
80102372:	c7 04 24 55 95 10 80 	movl   $0x80109555,(%esp)
80102379:	e8 bf e1 ff ff       	call   8010053d <panic>

  ip = empty;
8010237e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102381:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80102384:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102387:	8b 55 08             	mov    0x8(%ebp),%edx
8010238a:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
8010238c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010238f:	8b 55 0c             	mov    0xc(%ebp),%edx
80102392:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80102395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102398:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010239f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801023a9:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023b0:	e8 f8 36 00 00       	call   80105aad <release>

  return ip;
801023b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801023b8:	c9                   	leave  
801023b9:	c3                   	ret    

801023ba <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801023ba:	55                   	push   %ebp
801023bb:	89 e5                	mov    %esp,%ebp
801023bd:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801023c0:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023c7:	e8 7f 36 00 00       	call   80105a4b <acquire>
  ip->ref++;
801023cc:	8b 45 08             	mov    0x8(%ebp),%eax
801023cf:	8b 40 08             	mov    0x8(%eax),%eax
801023d2:	8d 50 01             	lea    0x1(%eax),%edx
801023d5:	8b 45 08             	mov    0x8(%ebp),%eax
801023d8:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801023db:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801023e2:	e8 c6 36 00 00       	call   80105aad <release>
  return ip;
801023e7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023ea:	c9                   	leave  
801023eb:	c3                   	ret    

801023ec <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801023ec:	55                   	push   %ebp
801023ed:	89 e5                	mov    %esp,%ebp
801023ef:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801023f2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023f6:	74 0a                	je     80102402 <ilock+0x16>
801023f8:	8b 45 08             	mov    0x8(%ebp),%eax
801023fb:	8b 40 08             	mov    0x8(%eax),%eax
801023fe:	85 c0                	test   %eax,%eax
80102400:	7f 0c                	jg     8010240e <ilock+0x22>
    panic("ilock");
80102402:	c7 04 24 65 95 10 80 	movl   $0x80109565,(%esp)
80102409:	e8 2f e1 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010240e:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102415:	e8 31 36 00 00       	call   80105a4b <acquire>
  while(ip->flags & I_BUSY)
8010241a:	eb 13                	jmp    8010242f <ilock+0x43>
    sleep(ip, &icache.lock);
8010241c:	c7 44 24 04 80 f8 10 	movl   $0x8010f880,0x4(%esp)
80102423:	80 
80102424:	8b 45 08             	mov    0x8(%ebp),%eax
80102427:	89 04 24             	mov    %eax,(%esp)
8010242a:	e8 3e 33 00 00       	call   8010576d <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010242f:	8b 45 08             	mov    0x8(%ebp),%eax
80102432:	8b 40 0c             	mov    0xc(%eax),%eax
80102435:	83 e0 01             	and    $0x1,%eax
80102438:	84 c0                	test   %al,%al
8010243a:	75 e0                	jne    8010241c <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
8010243c:	8b 45 08             	mov    0x8(%ebp),%eax
8010243f:	8b 40 0c             	mov    0xc(%eax),%eax
80102442:	89 c2                	mov    %eax,%edx
80102444:	83 ca 01             	or     $0x1,%edx
80102447:	8b 45 08             	mov    0x8(%ebp),%eax
8010244a:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
8010244d:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102454:	e8 54 36 00 00       	call   80105aad <release>

  if(!(ip->flags & I_VALID)){
80102459:	8b 45 08             	mov    0x8(%ebp),%eax
8010245c:	8b 40 0c             	mov    0xc(%eax),%eax
8010245f:	83 e0 02             	and    $0x2,%eax
80102462:	85 c0                	test   %eax,%eax
80102464:	0f 85 ce 00 00 00    	jne    80102538 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
8010246a:	8b 45 08             	mov    0x8(%ebp),%eax
8010246d:	8b 40 04             	mov    0x4(%eax),%eax
80102470:	c1 e8 03             	shr    $0x3,%eax
80102473:	8d 50 02             	lea    0x2(%eax),%edx
80102476:	8b 45 08             	mov    0x8(%ebp),%eax
80102479:	8b 00                	mov    (%eax),%eax
8010247b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010247f:	89 04 24             	mov    %eax,(%esp)
80102482:	e8 1f dd ff ff       	call   801001a6 <bread>
80102487:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010248a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010248d:	8d 50 18             	lea    0x18(%eax),%edx
80102490:	8b 45 08             	mov    0x8(%ebp),%eax
80102493:	8b 40 04             	mov    0x4(%eax),%eax
80102496:	83 e0 07             	and    $0x7,%eax
80102499:	c1 e0 06             	shl    $0x6,%eax
8010249c:	01 d0                	add    %edx,%eax
8010249e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801024a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024a4:	0f b7 10             	movzwl (%eax),%edx
801024a7:	8b 45 08             	mov    0x8(%ebp),%eax
801024aa:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801024ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024b1:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801024b5:	8b 45 08             	mov    0x8(%ebp),%eax
801024b8:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801024bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024bf:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801024c3:	8b 45 08             	mov    0x8(%ebp),%eax
801024c6:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801024ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024cd:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801024d1:	8b 45 08             	mov    0x8(%ebp),%eax
801024d4:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801024d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024db:	8b 50 08             	mov    0x8(%eax),%edx
801024de:	8b 45 08             	mov    0x8(%ebp),%eax
801024e1:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801024e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024e7:	8d 50 0c             	lea    0xc(%eax),%edx
801024ea:	8b 45 08             	mov    0x8(%ebp),%eax
801024ed:	83 c0 1c             	add    $0x1c,%eax
801024f0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801024f7:	00 
801024f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801024fc:	89 04 24             	mov    %eax,(%esp)
801024ff:	e8 69 38 00 00       	call   80105d6d <memmove>
    brelse(bp);
80102504:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102507:	89 04 24             	mov    %eax,(%esp)
8010250a:	e8 08 dd ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010250f:	8b 45 08             	mov    0x8(%ebp),%eax
80102512:	8b 40 0c             	mov    0xc(%eax),%eax
80102515:	89 c2                	mov    %eax,%edx
80102517:	83 ca 02             	or     $0x2,%edx
8010251a:	8b 45 08             	mov    0x8(%ebp),%eax
8010251d:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80102520:	8b 45 08             	mov    0x8(%ebp),%eax
80102523:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102527:	66 85 c0             	test   %ax,%ax
8010252a:	75 0c                	jne    80102538 <ilock+0x14c>
      panic("ilock: no type");
8010252c:	c7 04 24 6b 95 10 80 	movl   $0x8010956b,(%esp)
80102533:	e8 05 e0 ff ff       	call   8010053d <panic>
  }
}
80102538:	c9                   	leave  
80102539:	c3                   	ret    

8010253a <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
8010253a:	55                   	push   %ebp
8010253b:	89 e5                	mov    %esp,%ebp
8010253d:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102540:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102544:	74 17                	je     8010255d <iunlock+0x23>
80102546:	8b 45 08             	mov    0x8(%ebp),%eax
80102549:	8b 40 0c             	mov    0xc(%eax),%eax
8010254c:	83 e0 01             	and    $0x1,%eax
8010254f:	85 c0                	test   %eax,%eax
80102551:	74 0a                	je     8010255d <iunlock+0x23>
80102553:	8b 45 08             	mov    0x8(%ebp),%eax
80102556:	8b 40 08             	mov    0x8(%eax),%eax
80102559:	85 c0                	test   %eax,%eax
8010255b:	7f 0c                	jg     80102569 <iunlock+0x2f>
    panic("iunlock");
8010255d:	c7 04 24 7a 95 10 80 	movl   $0x8010957a,(%esp)
80102564:	e8 d4 df ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102569:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102570:	e8 d6 34 00 00       	call   80105a4b <acquire>
  ip->flags &= ~I_BUSY;
80102575:	8b 45 08             	mov    0x8(%ebp),%eax
80102578:	8b 40 0c             	mov    0xc(%eax),%eax
8010257b:	89 c2                	mov    %eax,%edx
8010257d:	83 e2 fe             	and    $0xfffffffe,%edx
80102580:	8b 45 08             	mov    0x8(%ebp),%eax
80102583:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80102586:	8b 45 08             	mov    0x8(%ebp),%eax
80102589:	89 04 24             	mov    %eax,(%esp)
8010258c:	e8 b5 32 00 00       	call   80105846 <wakeup>
  release(&icache.lock);
80102591:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102598:	e8 10 35 00 00       	call   80105aad <release>
}
8010259d:	c9                   	leave  
8010259e:	c3                   	ret    

8010259f <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
8010259f:	55                   	push   %ebp
801025a0:	89 e5                	mov    %esp,%ebp
801025a2:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801025a5:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
801025ac:	e8 9a 34 00 00       	call   80105a4b <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801025b1:	8b 45 08             	mov    0x8(%ebp),%eax
801025b4:	8b 40 08             	mov    0x8(%eax),%eax
801025b7:	83 f8 01             	cmp    $0x1,%eax
801025ba:	0f 85 93 00 00 00    	jne    80102653 <iput+0xb4>
801025c0:	8b 45 08             	mov    0x8(%ebp),%eax
801025c3:	8b 40 0c             	mov    0xc(%eax),%eax
801025c6:	83 e0 02             	and    $0x2,%eax
801025c9:	85 c0                	test   %eax,%eax
801025cb:	0f 84 82 00 00 00    	je     80102653 <iput+0xb4>
801025d1:	8b 45 08             	mov    0x8(%ebp),%eax
801025d4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801025d8:	66 85 c0             	test   %ax,%ax
801025db:	75 76                	jne    80102653 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801025dd:	8b 45 08             	mov    0x8(%ebp),%eax
801025e0:	8b 40 0c             	mov    0xc(%eax),%eax
801025e3:	83 e0 01             	and    $0x1,%eax
801025e6:	84 c0                	test   %al,%al
801025e8:	74 0c                	je     801025f6 <iput+0x57>
      panic("iput busy");
801025ea:	c7 04 24 82 95 10 80 	movl   $0x80109582,(%esp)
801025f1:	e8 47 df ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801025f6:	8b 45 08             	mov    0x8(%ebp),%eax
801025f9:	8b 40 0c             	mov    0xc(%eax),%eax
801025fc:	89 c2                	mov    %eax,%edx
801025fe:	83 ca 01             	or     $0x1,%edx
80102601:	8b 45 08             	mov    0x8(%ebp),%eax
80102604:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80102607:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
8010260e:	e8 9a 34 00 00       	call   80105aad <release>
    itrunc(ip);
80102613:	8b 45 08             	mov    0x8(%ebp),%eax
80102616:	89 04 24             	mov    %eax,(%esp)
80102619:	e8 72 01 00 00       	call   80102790 <itrunc>
    ip->type = 0;
8010261e:	8b 45 08             	mov    0x8(%ebp),%eax
80102621:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80102627:	8b 45 08             	mov    0x8(%ebp),%eax
8010262a:	89 04 24             	mov    %eax,(%esp)
8010262d:	e8 fe fb ff ff       	call   80102230 <iupdate>
    acquire(&icache.lock);
80102632:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102639:	e8 0d 34 00 00       	call   80105a4b <acquire>
    ip->flags = 0;
8010263e:	8b 45 08             	mov    0x8(%ebp),%eax
80102641:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80102648:	8b 45 08             	mov    0x8(%ebp),%eax
8010264b:	89 04 24             	mov    %eax,(%esp)
8010264e:	e8 f3 31 00 00       	call   80105846 <wakeup>
  }
  ip->ref--;
80102653:	8b 45 08             	mov    0x8(%ebp),%eax
80102656:	8b 40 08             	mov    0x8(%eax),%eax
80102659:	8d 50 ff             	lea    -0x1(%eax),%edx
8010265c:	8b 45 08             	mov    0x8(%ebp),%eax
8010265f:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102662:	c7 04 24 80 f8 10 80 	movl   $0x8010f880,(%esp)
80102669:	e8 3f 34 00 00       	call   80105aad <release>
}
8010266e:	c9                   	leave  
8010266f:	c3                   	ret    

80102670 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102670:	55                   	push   %ebp
80102671:	89 e5                	mov    %esp,%ebp
80102673:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80102676:	8b 45 08             	mov    0x8(%ebp),%eax
80102679:	89 04 24             	mov    %eax,(%esp)
8010267c:	e8 b9 fe ff ff       	call   8010253a <iunlock>
  iput(ip);
80102681:	8b 45 08             	mov    0x8(%ebp),%eax
80102684:	89 04 24             	mov    %eax,(%esp)
80102687:	e8 13 ff ff ff       	call   8010259f <iput>
}
8010268c:	c9                   	leave  
8010268d:	c3                   	ret    

8010268e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
8010268e:	55                   	push   %ebp
8010268f:	89 e5                	mov    %esp,%ebp
80102691:	53                   	push   %ebx
80102692:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102695:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80102699:	77 3e                	ja     801026d9 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
8010269b:	8b 45 08             	mov    0x8(%ebp),%eax
8010269e:	8b 55 0c             	mov    0xc(%ebp),%edx
801026a1:	83 c2 04             	add    $0x4,%edx
801026a4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801026a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026ab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026af:	75 20                	jne    801026d1 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801026b1:	8b 45 08             	mov    0x8(%ebp),%eax
801026b4:	8b 00                	mov    (%eax),%eax
801026b6:	89 04 24             	mov    %eax,(%esp)
801026b9:	e8 31 f8 ff ff       	call   80101eef <balloc>
801026be:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026c1:	8b 45 08             	mov    0x8(%ebp),%eax
801026c4:	8b 55 0c             	mov    0xc(%ebp),%edx
801026c7:	8d 4a 04             	lea    0x4(%edx),%ecx
801026ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801026cd:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801026d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026d4:	e9 b1 00 00 00       	jmp    8010278a <bmap+0xfc>
  }
  bn -= NDIRECT;
801026d9:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801026dd:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801026e1:	0f 87 97 00 00 00    	ja     8010277e <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801026e7:	8b 45 08             	mov    0x8(%ebp),%eax
801026ea:	8b 40 4c             	mov    0x4c(%eax),%eax
801026ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
801026f0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801026f4:	75 19                	jne    8010270f <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801026f6:	8b 45 08             	mov    0x8(%ebp),%eax
801026f9:	8b 00                	mov    (%eax),%eax
801026fb:	89 04 24             	mov    %eax,(%esp)
801026fe:	e8 ec f7 ff ff       	call   80101eef <balloc>
80102703:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102706:	8b 45 08             	mov    0x8(%ebp),%eax
80102709:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010270c:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
8010270f:	8b 45 08             	mov    0x8(%ebp),%eax
80102712:	8b 00                	mov    (%eax),%eax
80102714:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102717:	89 54 24 04          	mov    %edx,0x4(%esp)
8010271b:	89 04 24             	mov    %eax,(%esp)
8010271e:	e8 83 da ff ff       	call   801001a6 <bread>
80102723:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80102726:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102729:	83 c0 18             	add    $0x18,%eax
8010272c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
8010272f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102732:	c1 e0 02             	shl    $0x2,%eax
80102735:	03 45 ec             	add    -0x14(%ebp),%eax
80102738:	8b 00                	mov    (%eax),%eax
8010273a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010273d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102741:	75 2b                	jne    8010276e <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80102743:	8b 45 0c             	mov    0xc(%ebp),%eax
80102746:	c1 e0 02             	shl    $0x2,%eax
80102749:	89 c3                	mov    %eax,%ebx
8010274b:	03 5d ec             	add    -0x14(%ebp),%ebx
8010274e:	8b 45 08             	mov    0x8(%ebp),%eax
80102751:	8b 00                	mov    (%eax),%eax
80102753:	89 04 24             	mov    %eax,(%esp)
80102756:	e8 94 f7 ff ff       	call   80101eef <balloc>
8010275b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010275e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102761:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80102763:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102766:	89 04 24             	mov    %eax,(%esp)
80102769:	e8 f8 19 00 00       	call   80104166 <log_write>
    }
    brelse(bp);
8010276e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102771:	89 04 24             	mov    %eax,(%esp)
80102774:	e8 9e da ff ff       	call   80100217 <brelse>
    return addr;
80102779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010277c:	eb 0c                	jmp    8010278a <bmap+0xfc>
  }

  panic("bmap: out of range");
8010277e:	c7 04 24 8c 95 10 80 	movl   $0x8010958c,(%esp)
80102785:	e8 b3 dd ff ff       	call   8010053d <panic>
}
8010278a:	83 c4 24             	add    $0x24,%esp
8010278d:	5b                   	pop    %ebx
8010278e:	5d                   	pop    %ebp
8010278f:	c3                   	ret    

80102790 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102790:	55                   	push   %ebp
80102791:	89 e5                	mov    %esp,%ebp
80102793:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80102796:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010279d:	eb 44                	jmp    801027e3 <itrunc+0x53>
    if(ip->addrs[i]){
8010279f:	8b 45 08             	mov    0x8(%ebp),%eax
801027a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027a5:	83 c2 04             	add    $0x4,%edx
801027a8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801027ac:	85 c0                	test   %eax,%eax
801027ae:	74 2f                	je     801027df <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801027b0:	8b 45 08             	mov    0x8(%ebp),%eax
801027b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027b6:	83 c2 04             	add    $0x4,%edx
801027b9:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801027bd:	8b 45 08             	mov    0x8(%ebp),%eax
801027c0:	8b 00                	mov    (%eax),%eax
801027c2:	89 54 24 04          	mov    %edx,0x4(%esp)
801027c6:	89 04 24             	mov    %eax,(%esp)
801027c9:	e8 90 f8 ff ff       	call   8010205e <bfree>
      ip->addrs[i] = 0;
801027ce:	8b 45 08             	mov    0x8(%ebp),%eax
801027d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801027d4:	83 c2 04             	add    $0x4,%edx
801027d7:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801027de:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801027df:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801027e3:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801027e7:	7e b6                	jle    8010279f <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801027e9:	8b 45 08             	mov    0x8(%ebp),%eax
801027ec:	8b 40 4c             	mov    0x4c(%eax),%eax
801027ef:	85 c0                	test   %eax,%eax
801027f1:	0f 84 8f 00 00 00    	je     80102886 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801027f7:	8b 45 08             	mov    0x8(%ebp),%eax
801027fa:	8b 50 4c             	mov    0x4c(%eax),%edx
801027fd:	8b 45 08             	mov    0x8(%ebp),%eax
80102800:	8b 00                	mov    (%eax),%eax
80102802:	89 54 24 04          	mov    %edx,0x4(%esp)
80102806:	89 04 24             	mov    %eax,(%esp)
80102809:	e8 98 d9 ff ff       	call   801001a6 <bread>
8010280e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102811:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102814:	83 c0 18             	add    $0x18,%eax
80102817:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
8010281a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102821:	eb 2f                	jmp    80102852 <itrunc+0xc2>
      if(a[j])
80102823:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102826:	c1 e0 02             	shl    $0x2,%eax
80102829:	03 45 e8             	add    -0x18(%ebp),%eax
8010282c:	8b 00                	mov    (%eax),%eax
8010282e:	85 c0                	test   %eax,%eax
80102830:	74 1c                	je     8010284e <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80102832:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102835:	c1 e0 02             	shl    $0x2,%eax
80102838:	03 45 e8             	add    -0x18(%ebp),%eax
8010283b:	8b 10                	mov    (%eax),%edx
8010283d:	8b 45 08             	mov    0x8(%ebp),%eax
80102840:	8b 00                	mov    (%eax),%eax
80102842:	89 54 24 04          	mov    %edx,0x4(%esp)
80102846:	89 04 24             	mov    %eax,(%esp)
80102849:	e8 10 f8 ff ff       	call   8010205e <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
8010284e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102852:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102855:	83 f8 7f             	cmp    $0x7f,%eax
80102858:	76 c9                	jbe    80102823 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
8010285a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010285d:	89 04 24             	mov    %eax,(%esp)
80102860:	e8 b2 d9 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102865:	8b 45 08             	mov    0x8(%ebp),%eax
80102868:	8b 50 4c             	mov    0x4c(%eax),%edx
8010286b:	8b 45 08             	mov    0x8(%ebp),%eax
8010286e:	8b 00                	mov    (%eax),%eax
80102870:	89 54 24 04          	mov    %edx,0x4(%esp)
80102874:	89 04 24             	mov    %eax,(%esp)
80102877:	e8 e2 f7 ff ff       	call   8010205e <bfree>
    ip->addrs[NDIRECT] = 0;
8010287c:	8b 45 08             	mov    0x8(%ebp),%eax
8010287f:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80102886:	8b 45 08             	mov    0x8(%ebp),%eax
80102889:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102890:	8b 45 08             	mov    0x8(%ebp),%eax
80102893:	89 04 24             	mov    %eax,(%esp)
80102896:	e8 95 f9 ff ff       	call   80102230 <iupdate>
}
8010289b:	c9                   	leave  
8010289c:	c3                   	ret    

8010289d <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
8010289d:	55                   	push   %ebp
8010289e:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
801028a0:	8b 45 08             	mov    0x8(%ebp),%eax
801028a3:	8b 00                	mov    (%eax),%eax
801028a5:	89 c2                	mov    %eax,%edx
801028a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801028aa:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801028ad:	8b 45 08             	mov    0x8(%ebp),%eax
801028b0:	8b 50 04             	mov    0x4(%eax),%edx
801028b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801028b6:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801028b9:	8b 45 08             	mov    0x8(%ebp),%eax
801028bc:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801028c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801028c3:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801028c6:	8b 45 08             	mov    0x8(%ebp),%eax
801028c9:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801028cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801028d0:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801028d4:	8b 45 08             	mov    0x8(%ebp),%eax
801028d7:	8b 50 18             	mov    0x18(%eax),%edx
801028da:	8b 45 0c             	mov    0xc(%ebp),%eax
801028dd:	89 50 10             	mov    %edx,0x10(%eax)
}
801028e0:	5d                   	pop    %ebp
801028e1:	c3                   	ret    

801028e2 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801028e2:	55                   	push   %ebp
801028e3:	89 e5                	mov    %esp,%ebp
801028e5:	53                   	push   %ebx
801028e6:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801028e9:	8b 45 08             	mov    0x8(%ebp),%eax
801028ec:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801028f0:	66 83 f8 03          	cmp    $0x3,%ax
801028f4:	75 60                	jne    80102956 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801028f6:	8b 45 08             	mov    0x8(%ebp),%eax
801028f9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801028fd:	66 85 c0             	test   %ax,%ax
80102900:	78 20                	js     80102922 <readi+0x40>
80102902:	8b 45 08             	mov    0x8(%ebp),%eax
80102905:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102909:	66 83 f8 09          	cmp    $0x9,%ax
8010290d:	7f 13                	jg     80102922 <readi+0x40>
8010290f:	8b 45 08             	mov    0x8(%ebp),%eax
80102912:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102916:	98                   	cwtl   
80102917:	8b 04 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%eax
8010291e:	85 c0                	test   %eax,%eax
80102920:	75 0a                	jne    8010292c <readi+0x4a>
      return -1;
80102922:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102927:	e9 1b 01 00 00       	jmp    80102a47 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
8010292c:	8b 45 08             	mov    0x8(%ebp),%eax
8010292f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102933:	98                   	cwtl   
80102934:	8b 14 c5 20 f8 10 80 	mov    -0x7fef07e0(,%eax,8),%edx
8010293b:	8b 45 14             	mov    0x14(%ebp),%eax
8010293e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102942:	8b 45 0c             	mov    0xc(%ebp),%eax
80102945:	89 44 24 04          	mov    %eax,0x4(%esp)
80102949:	8b 45 08             	mov    0x8(%ebp),%eax
8010294c:	89 04 24             	mov    %eax,(%esp)
8010294f:	ff d2                	call   *%edx
80102951:	e9 f1 00 00 00       	jmp    80102a47 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80102956:	8b 45 08             	mov    0x8(%ebp),%eax
80102959:	8b 40 18             	mov    0x18(%eax),%eax
8010295c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010295f:	72 0d                	jb     8010296e <readi+0x8c>
80102961:	8b 45 14             	mov    0x14(%ebp),%eax
80102964:	8b 55 10             	mov    0x10(%ebp),%edx
80102967:	01 d0                	add    %edx,%eax
80102969:	3b 45 10             	cmp    0x10(%ebp),%eax
8010296c:	73 0a                	jae    80102978 <readi+0x96>
    return -1;
8010296e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102973:	e9 cf 00 00 00       	jmp    80102a47 <readi+0x165>
  if(off + n > ip->size)
80102978:	8b 45 14             	mov    0x14(%ebp),%eax
8010297b:	8b 55 10             	mov    0x10(%ebp),%edx
8010297e:	01 c2                	add    %eax,%edx
80102980:	8b 45 08             	mov    0x8(%ebp),%eax
80102983:	8b 40 18             	mov    0x18(%eax),%eax
80102986:	39 c2                	cmp    %eax,%edx
80102988:	76 0c                	jbe    80102996 <readi+0xb4>
    n = ip->size - off;
8010298a:	8b 45 08             	mov    0x8(%ebp),%eax
8010298d:	8b 40 18             	mov    0x18(%eax),%eax
80102990:	2b 45 10             	sub    0x10(%ebp),%eax
80102993:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102996:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010299d:	e9 96 00 00 00       	jmp    80102a38 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801029a2:	8b 45 10             	mov    0x10(%ebp),%eax
801029a5:	c1 e8 09             	shr    $0x9,%eax
801029a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801029ac:	8b 45 08             	mov    0x8(%ebp),%eax
801029af:	89 04 24             	mov    %eax,(%esp)
801029b2:	e8 d7 fc ff ff       	call   8010268e <bmap>
801029b7:	8b 55 08             	mov    0x8(%ebp),%edx
801029ba:	8b 12                	mov    (%edx),%edx
801029bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801029c0:	89 14 24             	mov    %edx,(%esp)
801029c3:	e8 de d7 ff ff       	call   801001a6 <bread>
801029c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801029cb:	8b 45 10             	mov    0x10(%ebp),%eax
801029ce:	89 c2                	mov    %eax,%edx
801029d0:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801029d6:	b8 00 02 00 00       	mov    $0x200,%eax
801029db:	89 c1                	mov    %eax,%ecx
801029dd:	29 d1                	sub    %edx,%ecx
801029df:	89 ca                	mov    %ecx,%edx
801029e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e4:	8b 4d 14             	mov    0x14(%ebp),%ecx
801029e7:	89 cb                	mov    %ecx,%ebx
801029e9:	29 c3                	sub    %eax,%ebx
801029eb:	89 d8                	mov    %ebx,%eax
801029ed:	39 c2                	cmp    %eax,%edx
801029ef:	0f 46 c2             	cmovbe %edx,%eax
801029f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801029f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801029f8:	8d 50 18             	lea    0x18(%eax),%edx
801029fb:	8b 45 10             	mov    0x10(%ebp),%eax
801029fe:	25 ff 01 00 00       	and    $0x1ff,%eax
80102a03:	01 c2                	add    %eax,%edx
80102a05:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a08:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a0c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102a10:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a13:	89 04 24             	mov    %eax,(%esp)
80102a16:	e8 52 33 00 00       	call   80105d6d <memmove>
    brelse(bp);
80102a1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a1e:	89 04 24             	mov    %eax,(%esp)
80102a21:	e8 f1 d7 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102a26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a29:	01 45 f4             	add    %eax,-0xc(%ebp)
80102a2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a2f:	01 45 10             	add    %eax,0x10(%ebp)
80102a32:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a35:	01 45 0c             	add    %eax,0xc(%ebp)
80102a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a3b:	3b 45 14             	cmp    0x14(%ebp),%eax
80102a3e:	0f 82 5e ff ff ff    	jb     801029a2 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102a44:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102a47:	83 c4 24             	add    $0x24,%esp
80102a4a:	5b                   	pop    %ebx
80102a4b:	5d                   	pop    %ebp
80102a4c:	c3                   	ret    

80102a4d <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102a4d:	55                   	push   %ebp
80102a4e:	89 e5                	mov    %esp,%ebp
80102a50:	53                   	push   %ebx
80102a51:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102a54:	8b 45 08             	mov    0x8(%ebp),%eax
80102a57:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102a5b:	66 83 f8 03          	cmp    $0x3,%ax
80102a5f:	75 60                	jne    80102ac1 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102a61:	8b 45 08             	mov    0x8(%ebp),%eax
80102a64:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a68:	66 85 c0             	test   %ax,%ax
80102a6b:	78 20                	js     80102a8d <writei+0x40>
80102a6d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a70:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a74:	66 83 f8 09          	cmp    $0x9,%ax
80102a78:	7f 13                	jg     80102a8d <writei+0x40>
80102a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80102a7d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a81:	98                   	cwtl   
80102a82:	8b 04 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%eax
80102a89:	85 c0                	test   %eax,%eax
80102a8b:	75 0a                	jne    80102a97 <writei+0x4a>
      return -1;
80102a8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102a92:	e9 46 01 00 00       	jmp    80102bdd <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80102a97:	8b 45 08             	mov    0x8(%ebp),%eax
80102a9a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102a9e:	98                   	cwtl   
80102a9f:	8b 14 c5 24 f8 10 80 	mov    -0x7fef07dc(,%eax,8),%edx
80102aa6:	8b 45 14             	mov    0x14(%ebp),%eax
80102aa9:	89 44 24 08          	mov    %eax,0x8(%esp)
80102aad:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab7:	89 04 24             	mov    %eax,(%esp)
80102aba:	ff d2                	call   *%edx
80102abc:	e9 1c 01 00 00       	jmp    80102bdd <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80102ac1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac4:	8b 40 18             	mov    0x18(%eax),%eax
80102ac7:	3b 45 10             	cmp    0x10(%ebp),%eax
80102aca:	72 0d                	jb     80102ad9 <writei+0x8c>
80102acc:	8b 45 14             	mov    0x14(%ebp),%eax
80102acf:	8b 55 10             	mov    0x10(%ebp),%edx
80102ad2:	01 d0                	add    %edx,%eax
80102ad4:	3b 45 10             	cmp    0x10(%ebp),%eax
80102ad7:	73 0a                	jae    80102ae3 <writei+0x96>
    return -1;
80102ad9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ade:	e9 fa 00 00 00       	jmp    80102bdd <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80102ae3:	8b 45 14             	mov    0x14(%ebp),%eax
80102ae6:	8b 55 10             	mov    0x10(%ebp),%edx
80102ae9:	01 d0                	add    %edx,%eax
80102aeb:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102af0:	76 0a                	jbe    80102afc <writei+0xaf>
    return -1;
80102af2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102af7:	e9 e1 00 00 00       	jmp    80102bdd <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102afc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b03:	e9 a1 00 00 00       	jmp    80102ba9 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102b08:	8b 45 10             	mov    0x10(%ebp),%eax
80102b0b:	c1 e8 09             	shr    $0x9,%eax
80102b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b12:	8b 45 08             	mov    0x8(%ebp),%eax
80102b15:	89 04 24             	mov    %eax,(%esp)
80102b18:	e8 71 fb ff ff       	call   8010268e <bmap>
80102b1d:	8b 55 08             	mov    0x8(%ebp),%edx
80102b20:	8b 12                	mov    (%edx),%edx
80102b22:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b26:	89 14 24             	mov    %edx,(%esp)
80102b29:	e8 78 d6 ff ff       	call   801001a6 <bread>
80102b2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102b31:	8b 45 10             	mov    0x10(%ebp),%eax
80102b34:	89 c2                	mov    %eax,%edx
80102b36:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102b3c:	b8 00 02 00 00       	mov    $0x200,%eax
80102b41:	89 c1                	mov    %eax,%ecx
80102b43:	29 d1                	sub    %edx,%ecx
80102b45:	89 ca                	mov    %ecx,%edx
80102b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b4a:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102b4d:	89 cb                	mov    %ecx,%ebx
80102b4f:	29 c3                	sub    %eax,%ebx
80102b51:	89 d8                	mov    %ebx,%eax
80102b53:	39 c2                	cmp    %eax,%edx
80102b55:	0f 46 c2             	cmovbe %edx,%eax
80102b58:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102b5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b5e:	8d 50 18             	lea    0x18(%eax),%edx
80102b61:	8b 45 10             	mov    0x10(%ebp),%eax
80102b64:	25 ff 01 00 00       	and    $0x1ff,%eax
80102b69:	01 c2                	add    %eax,%edx
80102b6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b6e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102b72:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b75:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b79:	89 14 24             	mov    %edx,(%esp)
80102b7c:	e8 ec 31 00 00       	call   80105d6d <memmove>
    log_write(bp);
80102b81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b84:	89 04 24             	mov    %eax,(%esp)
80102b87:	e8 da 15 00 00       	call   80104166 <log_write>
    brelse(bp);
80102b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102b8f:	89 04 24             	mov    %eax,(%esp)
80102b92:	e8 80 d6 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102b97:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102b9a:	01 45 f4             	add    %eax,-0xc(%ebp)
80102b9d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ba0:	01 45 10             	add    %eax,0x10(%ebp)
80102ba3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ba6:	01 45 0c             	add    %eax,0xc(%ebp)
80102ba9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bac:	3b 45 14             	cmp    0x14(%ebp),%eax
80102baf:	0f 82 53 ff ff ff    	jb     80102b08 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102bb5:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102bb9:	74 1f                	je     80102bda <writei+0x18d>
80102bbb:	8b 45 08             	mov    0x8(%ebp),%eax
80102bbe:	8b 40 18             	mov    0x18(%eax),%eax
80102bc1:	3b 45 10             	cmp    0x10(%ebp),%eax
80102bc4:	73 14                	jae    80102bda <writei+0x18d>
    ip->size = off;
80102bc6:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc9:	8b 55 10             	mov    0x10(%ebp),%edx
80102bcc:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102bcf:	8b 45 08             	mov    0x8(%ebp),%eax
80102bd2:	89 04 24             	mov    %eax,(%esp)
80102bd5:	e8 56 f6 ff ff       	call   80102230 <iupdate>
  }
  return n;
80102bda:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102bdd:	83 c4 24             	add    $0x24,%esp
80102be0:	5b                   	pop    %ebx
80102be1:	5d                   	pop    %ebp
80102be2:	c3                   	ret    

80102be3 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102be3:	55                   	push   %ebp
80102be4:	89 e5                	mov    %esp,%ebp
80102be6:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102be9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102bf0:	00 
80102bf1:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bf4:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bf8:	8b 45 08             	mov    0x8(%ebp),%eax
80102bfb:	89 04 24             	mov    %eax,(%esp)
80102bfe:	e8 0e 32 00 00       	call   80105e11 <strncmp>
}
80102c03:	c9                   	leave  
80102c04:	c3                   	ret    

80102c05 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102c05:	55                   	push   %ebp
80102c06:	89 e5                	mov    %esp,%ebp
80102c08:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102c0b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c0e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102c12:	66 83 f8 01          	cmp    $0x1,%ax
80102c16:	74 0c                	je     80102c24 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102c18:	c7 04 24 9f 95 10 80 	movl   $0x8010959f,(%esp)
80102c1f:	e8 19 d9 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102c24:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c2b:	e9 87 00 00 00       	jmp    80102cb7 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102c30:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102c37:	00 
80102c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c3b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102c3f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c42:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c46:	8b 45 08             	mov    0x8(%ebp),%eax
80102c49:	89 04 24             	mov    %eax,(%esp)
80102c4c:	e8 91 fc ff ff       	call   801028e2 <readi>
80102c51:	83 f8 10             	cmp    $0x10,%eax
80102c54:	74 0c                	je     80102c62 <dirlookup+0x5d>
      panic("dirlink read");
80102c56:	c7 04 24 b1 95 10 80 	movl   $0x801095b1,(%esp)
80102c5d:	e8 db d8 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102c62:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c66:	66 85 c0             	test   %ax,%ax
80102c69:	74 47                	je     80102cb2 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102c6b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102c6e:	83 c0 02             	add    $0x2,%eax
80102c71:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c75:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c78:	89 04 24             	mov    %eax,(%esp)
80102c7b:	e8 63 ff ff ff       	call   80102be3 <namecmp>
80102c80:	85 c0                	test   %eax,%eax
80102c82:	75 2f                	jne    80102cb3 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102c84:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102c88:	74 08                	je     80102c92 <dirlookup+0x8d>
        *poff = off;
80102c8a:	8b 45 10             	mov    0x10(%ebp),%eax
80102c8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102c90:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102c92:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102c96:	0f b7 c0             	movzwl %ax,%eax
80102c99:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102c9c:	8b 45 08             	mov    0x8(%ebp),%eax
80102c9f:	8b 00                	mov    (%eax),%eax
80102ca1:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102ca4:	89 54 24 04          	mov    %edx,0x4(%esp)
80102ca8:	89 04 24             	mov    %eax,(%esp)
80102cab:	e8 38 f6 ff ff       	call   801022e8 <iget>
80102cb0:	eb 19                	jmp    80102ccb <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102cb2:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102cb3:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102cb7:	8b 45 08             	mov    0x8(%ebp),%eax
80102cba:	8b 40 18             	mov    0x18(%eax),%eax
80102cbd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102cc0:	0f 87 6a ff ff ff    	ja     80102c30 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102cc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102ccb:	c9                   	leave  
80102ccc:	c3                   	ret    

80102ccd <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102ccd:	55                   	push   %ebp
80102cce:	89 e5                	mov    %esp,%ebp
80102cd0:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102cd3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102cda:	00 
80102cdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102cde:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ce2:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce5:	89 04 24             	mov    %eax,(%esp)
80102ce8:	e8 18 ff ff ff       	call   80102c05 <dirlookup>
80102ced:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102cf0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102cf4:	74 15                	je     80102d0b <dirlink+0x3e>
    iput(ip);
80102cf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102cf9:	89 04 24             	mov    %eax,(%esp)
80102cfc:	e8 9e f8 ff ff       	call   8010259f <iput>
    return -1;
80102d01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d06:	e9 b8 00 00 00       	jmp    80102dc3 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102d0b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102d12:	eb 44                	jmp    80102d58 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102d14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d17:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102d1e:	00 
80102d1f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d23:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102d26:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80102d2d:	89 04 24             	mov    %eax,(%esp)
80102d30:	e8 ad fb ff ff       	call   801028e2 <readi>
80102d35:	83 f8 10             	cmp    $0x10,%eax
80102d38:	74 0c                	je     80102d46 <dirlink+0x79>
      panic("dirlink read");
80102d3a:	c7 04 24 b1 95 10 80 	movl   $0x801095b1,(%esp)
80102d41:	e8 f7 d7 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102d46:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102d4a:	66 85 c0             	test   %ax,%ax
80102d4d:	74 18                	je     80102d67 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102d4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d52:	83 c0 10             	add    $0x10,%eax
80102d55:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d58:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102d5b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d5e:	8b 40 18             	mov    0x18(%eax),%eax
80102d61:	39 c2                	cmp    %eax,%edx
80102d63:	72 af                	jb     80102d14 <dirlink+0x47>
80102d65:	eb 01                	jmp    80102d68 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102d67:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102d68:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102d6f:	00 
80102d70:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d73:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d77:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102d7a:	83 c0 02             	add    $0x2,%eax
80102d7d:	89 04 24             	mov    %eax,(%esp)
80102d80:	e8 e4 30 00 00       	call   80105e69 <strncpy>
  de.inum = inum;
80102d85:	8b 45 10             	mov    0x10(%ebp),%eax
80102d88:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102d8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d8f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102d96:	00 
80102d97:	89 44 24 08          	mov    %eax,0x8(%esp)
80102d9b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102d9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102da2:	8b 45 08             	mov    0x8(%ebp),%eax
80102da5:	89 04 24             	mov    %eax,(%esp)
80102da8:	e8 a0 fc ff ff       	call   80102a4d <writei>
80102dad:	83 f8 10             	cmp    $0x10,%eax
80102db0:	74 0c                	je     80102dbe <dirlink+0xf1>
    panic("dirlink");
80102db2:	c7 04 24 be 95 10 80 	movl   $0x801095be,(%esp)
80102db9:	e8 7f d7 ff ff       	call   8010053d <panic>
  
  return 0;
80102dbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102dc3:	c9                   	leave  
80102dc4:	c3                   	ret    

80102dc5 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102dc5:	55                   	push   %ebp
80102dc6:	89 e5                	mov    %esp,%ebp
80102dc8:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102dcb:	eb 04                	jmp    80102dd1 <skipelem+0xc>
    path++;
80102dcd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102dd1:	8b 45 08             	mov    0x8(%ebp),%eax
80102dd4:	0f b6 00             	movzbl (%eax),%eax
80102dd7:	3c 2f                	cmp    $0x2f,%al
80102dd9:	74 f2                	je     80102dcd <skipelem+0x8>
    path++;
  if(*path == 0)
80102ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80102dde:	0f b6 00             	movzbl (%eax),%eax
80102de1:	84 c0                	test   %al,%al
80102de3:	75 0a                	jne    80102def <skipelem+0x2a>
    return 0;
80102de5:	b8 00 00 00 00       	mov    $0x0,%eax
80102dea:	e9 86 00 00 00       	jmp    80102e75 <skipelem+0xb0>
  s = path;
80102def:	8b 45 08             	mov    0x8(%ebp),%eax
80102df2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102df5:	eb 04                	jmp    80102dfb <skipelem+0x36>
    path++;
80102df7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102dfb:	8b 45 08             	mov    0x8(%ebp),%eax
80102dfe:	0f b6 00             	movzbl (%eax),%eax
80102e01:	3c 2f                	cmp    $0x2f,%al
80102e03:	74 0a                	je     80102e0f <skipelem+0x4a>
80102e05:	8b 45 08             	mov    0x8(%ebp),%eax
80102e08:	0f b6 00             	movzbl (%eax),%eax
80102e0b:	84 c0                	test   %al,%al
80102e0d:	75 e8                	jne    80102df7 <skipelem+0x32>
    path++;
  len = path - s;
80102e0f:	8b 55 08             	mov    0x8(%ebp),%edx
80102e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e15:	89 d1                	mov    %edx,%ecx
80102e17:	29 c1                	sub    %eax,%ecx
80102e19:	89 c8                	mov    %ecx,%eax
80102e1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102e1e:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102e22:	7e 1c                	jle    80102e40 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102e24:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102e2b:	00 
80102e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e33:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e36:	89 04 24             	mov    %eax,(%esp)
80102e39:	e8 2f 2f 00 00       	call   80105d6d <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102e3e:	eb 28                	jmp    80102e68 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102e40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e43:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e4a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e4e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e51:	89 04 24             	mov    %eax,(%esp)
80102e54:	e8 14 2f 00 00       	call   80105d6d <memmove>
    name[len] = 0;
80102e59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e5c:	03 45 0c             	add    0xc(%ebp),%eax
80102e5f:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102e62:	eb 04                	jmp    80102e68 <skipelem+0xa3>
    path++;
80102e64:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102e68:	8b 45 08             	mov    0x8(%ebp),%eax
80102e6b:	0f b6 00             	movzbl (%eax),%eax
80102e6e:	3c 2f                	cmp    $0x2f,%al
80102e70:	74 f2                	je     80102e64 <skipelem+0x9f>
    path++;
  return path;
80102e72:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102e75:	c9                   	leave  
80102e76:	c3                   	ret    

80102e77 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102e77:	55                   	push   %ebp
80102e78:	89 e5                	mov    %esp,%ebp
80102e7a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102e7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102e80:	0f b6 00             	movzbl (%eax),%eax
80102e83:	3c 2f                	cmp    $0x2f,%al
80102e85:	75 1c                	jne    80102ea3 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102e87:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102e8e:	00 
80102e8f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102e96:	e8 4d f4 ff ff       	call   801022e8 <iget>
80102e9b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102e9e:	e9 af 00 00 00       	jmp    80102f52 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102ea3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102ea9:	8b 40 68             	mov    0x68(%eax),%eax
80102eac:	89 04 24             	mov    %eax,(%esp)
80102eaf:	e8 06 f5 ff ff       	call   801023ba <idup>
80102eb4:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102eb7:	e9 96 00 00 00       	jmp    80102f52 <namex+0xdb>
    ilock(ip);
80102ebc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ebf:	89 04 24             	mov    %eax,(%esp)
80102ec2:	e8 25 f5 ff ff       	call   801023ec <ilock>
    if(ip->type != T_DIR){
80102ec7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eca:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102ece:	66 83 f8 01          	cmp    $0x1,%ax
80102ed2:	74 15                	je     80102ee9 <namex+0x72>
      iunlockput(ip);
80102ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ed7:	89 04 24             	mov    %eax,(%esp)
80102eda:	e8 91 f7 ff ff       	call   80102670 <iunlockput>
      return 0;
80102edf:	b8 00 00 00 00       	mov    $0x0,%eax
80102ee4:	e9 a3 00 00 00       	jmp    80102f8c <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102ee9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102eed:	74 1d                	je     80102f0c <namex+0x95>
80102eef:	8b 45 08             	mov    0x8(%ebp),%eax
80102ef2:	0f b6 00             	movzbl (%eax),%eax
80102ef5:	84 c0                	test   %al,%al
80102ef7:	75 13                	jne    80102f0c <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102ef9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102efc:	89 04 24             	mov    %eax,(%esp)
80102eff:	e8 36 f6 ff ff       	call   8010253a <iunlock>
      return ip;
80102f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f07:	e9 80 00 00 00       	jmp    80102f8c <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102f0c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102f13:	00 
80102f14:	8b 45 10             	mov    0x10(%ebp),%eax
80102f17:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f1e:	89 04 24             	mov    %eax,(%esp)
80102f21:	e8 df fc ff ff       	call   80102c05 <dirlookup>
80102f26:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102f29:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102f2d:	75 12                	jne    80102f41 <namex+0xca>
      iunlockput(ip);
80102f2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f32:	89 04 24             	mov    %eax,(%esp)
80102f35:	e8 36 f7 ff ff       	call   80102670 <iunlockput>
      return 0;
80102f3a:	b8 00 00 00 00       	mov    $0x0,%eax
80102f3f:	eb 4b                	jmp    80102f8c <namex+0x115>
    }
    iunlockput(ip);
80102f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f44:	89 04 24             	mov    %eax,(%esp)
80102f47:	e8 24 f7 ff ff       	call   80102670 <iunlockput>
    ip = next;
80102f4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102f4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102f52:	8b 45 10             	mov    0x10(%ebp),%eax
80102f55:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f59:	8b 45 08             	mov    0x8(%ebp),%eax
80102f5c:	89 04 24             	mov    %eax,(%esp)
80102f5f:	e8 61 fe ff ff       	call   80102dc5 <skipelem>
80102f64:	89 45 08             	mov    %eax,0x8(%ebp)
80102f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102f6b:	0f 85 4b ff ff ff    	jne    80102ebc <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102f71:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f75:	74 12                	je     80102f89 <namex+0x112>
    iput(ip);
80102f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f7a:	89 04 24             	mov    %eax,(%esp)
80102f7d:	e8 1d f6 ff ff       	call   8010259f <iput>
    return 0;
80102f82:	b8 00 00 00 00       	mov    $0x0,%eax
80102f87:	eb 03                	jmp    80102f8c <namex+0x115>
  }
  return ip;
80102f89:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102f8c:	c9                   	leave  
80102f8d:	c3                   	ret    

80102f8e <namei>:

struct inode*
namei(char *path)
{
80102f8e:	55                   	push   %ebp
80102f8f:	89 e5                	mov    %esp,%ebp
80102f91:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102f94:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102f97:	89 44 24 08          	mov    %eax,0x8(%esp)
80102f9b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fa2:	00 
80102fa3:	8b 45 08             	mov    0x8(%ebp),%eax
80102fa6:	89 04 24             	mov    %eax,(%esp)
80102fa9:	e8 c9 fe ff ff       	call   80102e77 <namex>
}
80102fae:	c9                   	leave  
80102faf:	c3                   	ret    

80102fb0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102fb0:	55                   	push   %ebp
80102fb1:	89 e5                	mov    %esp,%ebp
80102fb3:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102fb6:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fb9:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fbd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102fc4:	00 
80102fc5:	8b 45 08             	mov    0x8(%ebp),%eax
80102fc8:	89 04 24             	mov    %eax,(%esp)
80102fcb:	e8 a7 fe ff ff       	call   80102e77 <namex>
}
80102fd0:	c9                   	leave  
80102fd1:	c3                   	ret    

80102fd2 <getNextInode>:

struct inode*
getNextInode(void)
{
80102fd2:	55                   	push   %ebp
80102fd3:	89 e5                	mov    %esp,%ebp
80102fd5:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80102fd8:	8d 45 d8             	lea    -0x28(%ebp),%eax
80102fdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fdf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102fe6:	e8 6d ee ff ff       	call   80101e58 <readsb>
  cprintf("in getnextinode\n");
80102feb:	c7 04 24 c6 95 10 80 	movl   $0x801095c6,(%esp)
80102ff2:	e8 aa d3 ff ff       	call   801003a1 <cprintf>
  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80102ff7:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80102ffc:	83 c0 01             	add    $0x1,%eax
80102fff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103002:	e9 85 00 00 00       	jmp    8010308c <getNextInode+0xba>
  {cprintf("in getnextinode for\n");
80103007:	c7 04 24 d7 95 10 80 	movl   $0x801095d7,(%esp)
8010300e:	e8 8e d3 ff ff       	call   801003a1 <cprintf>
    bp = bread(1, IBLOCK(inum));
80103013:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103016:	c1 e8 03             	shr    $0x3,%eax
80103019:	83 c0 02             	add    $0x2,%eax
8010301c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103020:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103027:	e8 7a d1 ff ff       	call   801001a6 <bread>
8010302c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
8010302f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103032:	8d 50 18             	lea    0x18(%eax),%edx
80103035:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103038:	83 e0 07             	and    $0x7,%eax
8010303b:	c1 e0 06             	shl    $0x6,%eax
8010303e:	01 d0                	add    %edx,%eax
80103040:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103043:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103046:	0f b7 00             	movzwl (%eax),%eax
80103049:	66 83 f8 02          	cmp    $0x2,%ax
8010304d:	75 2e                	jne    8010307d <getNextInode+0xab>
    {
      nextInum = inum;
8010304f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103052:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      ip = iget(1,inum);
80103057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010305a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010305e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103065:	e8 7e f2 ff ff       	call   801022e8 <iget>
8010306a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
8010306d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103070:	89 04 24             	mov    %eax,(%esp)
80103073:	e8 9f d1 ff ff       	call   80100217 <brelse>
      return ip;
80103078:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010307b:	eb 25                	jmp    801030a2 <getNextInode+0xd0>
    }
    brelse(bp);
8010307d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103080:	89 04 24             	mov    %eax,(%esp)
80103083:	e8 8f d1 ff ff       	call   80100217 <brelse>
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  cprintf("in getnextinode\n");
  for(inum = nextInum+1; inum < sb.ninodes-1; inum++)
80103088:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010308c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010308f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103092:	83 ea 01             	sub    $0x1,%edx
80103095:	39 d0                	cmp    %edx,%eax
80103097:	0f 82 6a ff ff ff    	jb     80103007 <getNextInode+0x35>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
8010309d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030a2:	c9                   	leave  
801030a3:	c3                   	ret    

801030a4 <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
801030a4:	55                   	push   %ebp
801030a5:	89 e5                	mov    %esp,%ebp
801030a7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801030aa:	e9 8d 00 00 00       	jmp    8010313c <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
801030af:	8b 45 08             	mov    0x8(%ebp),%eax
801030b2:	8b 00                	mov    (%eax),%eax
801030b4:	c1 e8 03             	shr    $0x3,%eax
801030b7:	83 c0 02             	add    $0x2,%eax
801030ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801030be:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801030c5:	e8 dc d0 ff ff       	call   801001a6 <bread>
801030ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
801030cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030d0:	8d 50 18             	lea    0x18(%eax),%edx
801030d3:	8b 45 08             	mov    0x8(%ebp),%eax
801030d6:	8b 00                	mov    (%eax),%eax
801030d8:	83 e0 07             	and    $0x7,%eax
801030db:	c1 e0 06             	shl    $0x6,%eax
801030de:	01 d0                	add    %edx,%eax
801030e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
801030e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801030e6:	0f b7 00             	movzwl (%eax),%eax
801030e9:	66 83 f8 02          	cmp    $0x2,%ax
801030ed:	75 35                	jne    80103124 <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
801030ef:	8b 45 08             	mov    0x8(%ebp),%eax
801030f2:	8b 00                	mov    (%eax),%eax
801030f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801030f8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801030ff:	e8 e4 f1 ff ff       	call   801022e8 <iget>
80103104:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
80103107:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010310a:	89 04 24             	mov    %eax,(%esp)
8010310d:	e8 05 d1 ff ff       	call   80100217 <brelse>
      (*prevInum)--;
80103112:	8b 45 08             	mov    0x8(%ebp),%eax
80103115:	8b 00                	mov    (%eax),%eax
80103117:	8d 50 ff             	lea    -0x1(%eax),%edx
8010311a:	8b 45 08             	mov    0x8(%ebp),%eax
8010311d:	89 10                	mov    %edx,(%eax)
      return ip;
8010311f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103122:	eb 2f                	jmp    80103153 <getPrevInode+0xaf>
    }
    brelse(bp);
80103124:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103127:	89 04 24             	mov    %eax,(%esp)
8010312a:	e8 e8 d0 ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
8010312f:	8b 45 08             	mov    0x8(%ebp),%eax
80103132:	8b 00                	mov    (%eax),%eax
80103134:	8d 50 ff             	lea    -0x1(%eax),%edx
80103137:	8b 45 08             	mov    0x8(%ebp),%eax
8010313a:	89 10                	mov    %edx,(%eax)
8010313c:	8b 45 08             	mov    0x8(%ebp),%eax
8010313f:	8b 10                	mov    (%eax),%edx
80103141:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103146:	39 c2                	cmp    %eax,%edx
80103148:	0f 8f 61 ff ff ff    	jg     801030af <getPrevInode+0xb>
      (*prevInum)--;
      return ip;
    }
    brelse(bp);
  }
  return 0;
8010314e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103153:	c9                   	leave  
80103154:	c3                   	ret    

80103155 <updateBlkRef>:


void
updateBlkRef(uint sector, int flag)
{
80103155:	55                   	push   %ebp
80103156:	89 e5                	mov    %esp,%ebp
80103158:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  if(sector < 512)
8010315b:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103162:	0f 87 89 00 00 00    	ja     801031f1 <updateBlkRef+0x9c>
  {
    bp = bread(1,1024);
80103168:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010316f:	00 
80103170:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103177:	e8 2a d0 ff ff       	call   801001a6 <bread>
8010317c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
8010317f:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103183:	75 1e                	jne    801031a3 <updateBlkRef+0x4e>
      bp->data[sector]++;
80103185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103188:	03 45 08             	add    0x8(%ebp),%eax
8010318b:	83 c0 10             	add    $0x10,%eax
8010318e:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103192:	8d 50 01             	lea    0x1(%eax),%edx
80103195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103198:	03 45 08             	add    0x8(%ebp),%eax
8010319b:	83 c0 10             	add    $0x10,%eax
8010319e:	88 50 08             	mov    %dl,0x8(%eax)
801031a1:	eb 33                	jmp    801031d6 <updateBlkRef+0x81>
    else if(flag == -1)
801031a3:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801031a7:	75 2d                	jne    801031d6 <updateBlkRef+0x81>
      if(bp->data[sector] > 0)
801031a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031ac:	03 45 08             	add    0x8(%ebp),%eax
801031af:	83 c0 10             	add    $0x10,%eax
801031b2:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801031b6:	84 c0                	test   %al,%al
801031b8:	74 1c                	je     801031d6 <updateBlkRef+0x81>
	bp->data[sector]--;
801031ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031bd:	03 45 08             	add    0x8(%ebp),%eax
801031c0:	83 c0 10             	add    $0x10,%eax
801031c3:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801031c7:	8d 50 ff             	lea    -0x1(%eax),%edx
801031ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031cd:	03 45 08             	add    0x8(%ebp),%eax
801031d0:	83 c0 10             	add    $0x10,%eax
801031d3:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
801031d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031d9:	89 04 24             	mov    %eax,(%esp)
801031dc:	e8 fc cf ff ff       	call   801001dd <bwrite>
    brelse(bp);
801031e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031e4:	89 04 24             	mov    %eax,(%esp)
801031e7:	e8 2b d0 ff ff       	call   80100217 <brelse>
801031ec:	e9 91 00 00 00       	jmp    80103282 <updateBlkRef+0x12d>
  }
  else if(sector < 1024)
801031f1:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801031f8:	0f 87 84 00 00 00    	ja     80103282 <updateBlkRef+0x12d>
  {
    bp = bread(1,1025);
801031fe:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80103205:	00 
80103206:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010320d:	e8 94 cf ff ff       	call   801001a6 <bread>
80103212:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103215:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103219:	75 1c                	jne    80103237 <updateBlkRef+0xe2>
      bp->data[sector-512]++;
8010321b:	8b 45 08             	mov    0x8(%ebp),%eax
8010321e:	2d 00 02 00 00       	sub    $0x200,%eax
80103223:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103226:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010322b:	8d 4a 01             	lea    0x1(%edx),%ecx
8010322e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103231:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
80103235:	eb 35                	jmp    8010326c <updateBlkRef+0x117>
    else if(flag == -1)
80103237:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
8010323b:	75 2f                	jne    8010326c <updateBlkRef+0x117>
      if(bp->data[sector-512] > 0)
8010323d:	8b 45 08             	mov    0x8(%ebp),%eax
80103240:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
80103246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103249:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
8010324e:	84 c0                	test   %al,%al
80103250:	74 1a                	je     8010326c <updateBlkRef+0x117>
	bp->data[sector-512]--;
80103252:	8b 45 08             	mov    0x8(%ebp),%eax
80103255:	2d 00 02 00 00       	sub    $0x200,%eax
8010325a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010325d:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80103262:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103265:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103268:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
8010326c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010326f:	89 04 24             	mov    %eax,(%esp)
80103272:	e8 66 cf ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103277:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010327a:	89 04 24             	mov    %eax,(%esp)
8010327d:	e8 95 cf ff ff       	call   80100217 <brelse>
  }  
}
80103282:	c9                   	leave  
80103283:	c3                   	ret    

80103284 <getBlkRef>:

int
getBlkRef(uint sector)
{
80103284:	55                   	push   %ebp
80103285:	89 e5                	mov    %esp,%ebp
80103287:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1;
8010328a:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  
  if(sector < 512)
80103291:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
80103298:	77 19                	ja     801032b3 <getBlkRef+0x2f>
    bp = bread(1,1024);
8010329a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801032a1:	00 
801032a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032a9:	e8 f8 ce ff ff       	call   801001a6 <bread>
801032ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
801032b1:	eb 20                	jmp    801032d3 <getBlkRef+0x4f>
  else if(sector < 1024)
801032b3:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
801032ba:	77 17                	ja     801032d3 <getBlkRef+0x4f>
    bp = bread(1,1025);
801032bc:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
801032c3:	00 
801032c4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032cb:	e8 d6 ce ff ff       	call   801001a6 <bread>
801032d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ret = bp->data[sector];
801032d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032d6:	03 45 08             	add    0x8(%ebp),%eax
801032d9:	83 c0 10             	add    $0x10,%eax
801032dc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801032e0:	0f b6 c0             	movzbl %al,%eax
801032e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  brelse(bp);
801032e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032e9:	89 04 24             	mov    %eax,(%esp)
801032ec:	e8 26 cf ff ff       	call   80100217 <brelse>
  return ret;
801032f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801032f4:	c9                   	leave  
801032f5:	c3                   	ret    
	...

801032f8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801032f8:	55                   	push   %ebp
801032f9:	89 e5                	mov    %esp,%ebp
801032fb:	53                   	push   %ebx
801032fc:	83 ec 14             	sub    $0x14,%esp
801032ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103302:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103306:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010330a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010330e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103312:	ec                   	in     (%dx),%al
80103313:	89 c3                	mov    %eax,%ebx
80103315:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103318:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010331c:	83 c4 14             	add    $0x14,%esp
8010331f:	5b                   	pop    %ebx
80103320:	5d                   	pop    %ebp
80103321:	c3                   	ret    

80103322 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80103322:	55                   	push   %ebp
80103323:	89 e5                	mov    %esp,%ebp
80103325:	57                   	push   %edi
80103326:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80103327:	8b 55 08             	mov    0x8(%ebp),%edx
8010332a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010332d:	8b 45 10             	mov    0x10(%ebp),%eax
80103330:	89 cb                	mov    %ecx,%ebx
80103332:	89 df                	mov    %ebx,%edi
80103334:	89 c1                	mov    %eax,%ecx
80103336:	fc                   	cld    
80103337:	f3 6d                	rep insl (%dx),%es:(%edi)
80103339:	89 c8                	mov    %ecx,%eax
8010333b:	89 fb                	mov    %edi,%ebx
8010333d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103340:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80103343:	5b                   	pop    %ebx
80103344:	5f                   	pop    %edi
80103345:	5d                   	pop    %ebp
80103346:	c3                   	ret    

80103347 <outb>:

static inline void
outb(ushort port, uchar data)
{
80103347:	55                   	push   %ebp
80103348:	89 e5                	mov    %esp,%ebp
8010334a:	83 ec 08             	sub    $0x8,%esp
8010334d:	8b 55 08             	mov    0x8(%ebp),%edx
80103350:	8b 45 0c             	mov    0xc(%ebp),%eax
80103353:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103357:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010335a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010335e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103362:	ee                   	out    %al,(%dx)
}
80103363:	c9                   	leave  
80103364:	c3                   	ret    

80103365 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80103365:	55                   	push   %ebp
80103366:	89 e5                	mov    %esp,%ebp
80103368:	56                   	push   %esi
80103369:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010336a:	8b 55 08             	mov    0x8(%ebp),%edx
8010336d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103370:	8b 45 10             	mov    0x10(%ebp),%eax
80103373:	89 cb                	mov    %ecx,%ebx
80103375:	89 de                	mov    %ebx,%esi
80103377:	89 c1                	mov    %eax,%ecx
80103379:	fc                   	cld    
8010337a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010337c:	89 c8                	mov    %ecx,%eax
8010337e:	89 f3                	mov    %esi,%ebx
80103380:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80103383:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80103386:	5b                   	pop    %ebx
80103387:	5e                   	pop    %esi
80103388:	5d                   	pop    %ebp
80103389:	c3                   	ret    

8010338a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010338a:	55                   	push   %ebp
8010338b:	89 e5                	mov    %esp,%ebp
8010338d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80103390:	90                   	nop
80103391:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103398:	e8 5b ff ff ff       	call   801032f8 <inb>
8010339d:	0f b6 c0             	movzbl %al,%eax
801033a0:	89 45 fc             	mov    %eax,-0x4(%ebp)
801033a3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033a6:	25 c0 00 00 00       	and    $0xc0,%eax
801033ab:	83 f8 40             	cmp    $0x40,%eax
801033ae:	75 e1                	jne    80103391 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801033b0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801033b4:	74 11                	je     801033c7 <idewait+0x3d>
801033b6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801033b9:	83 e0 21             	and    $0x21,%eax
801033bc:	85 c0                	test   %eax,%eax
801033be:	74 07                	je     801033c7 <idewait+0x3d>
    return -1;
801033c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033c5:	eb 05                	jmp    801033cc <idewait+0x42>
  return 0;
801033c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033cc:	c9                   	leave  
801033cd:	c3                   	ret    

801033ce <ideinit>:

void
ideinit(void)
{
801033ce:	55                   	push   %ebp
801033cf:	89 e5                	mov    %esp,%ebp
801033d1:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801033d4:	c7 44 24 04 ec 95 10 	movl   $0x801095ec,0x4(%esp)
801033db:	80 
801033dc:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801033e3:	e8 42 26 00 00       	call   80105a2a <initlock>
  picenable(IRQ_IDE);
801033e8:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801033ef:	e8 75 15 00 00       	call   80104969 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801033f4:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801033f9:	83 e8 01             	sub    $0x1,%eax
801033fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103400:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103407:	e8 12 04 00 00       	call   8010381e <ioapicenable>
  idewait(0);
8010340c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103413:	e8 72 ff ff ff       	call   8010338a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103418:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010341f:	00 
80103420:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103427:	e8 1b ff ff ff       	call   80103347 <outb>
  for(i=0; i<1000; i++){
8010342c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103433:	eb 20                	jmp    80103455 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103435:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010343c:	e8 b7 fe ff ff       	call   801032f8 <inb>
80103441:	84 c0                	test   %al,%al
80103443:	74 0c                	je     80103451 <ideinit+0x83>
      havedisk1 = 1;
80103445:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
8010344c:	00 00 00 
      break;
8010344f:	eb 0d                	jmp    8010345e <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80103451:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103455:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
8010345c:	7e d7                	jle    80103435 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010345e:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80103465:	00 
80103466:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010346d:	e8 d5 fe ff ff       	call   80103347 <outb>
}
80103472:	c9                   	leave  
80103473:	c3                   	ret    

80103474 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80103474:	55                   	push   %ebp
80103475:	89 e5                	mov    %esp,%ebp
80103477:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010347a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010347e:	75 0c                	jne    8010348c <idestart+0x18>
    panic("idestart");
80103480:	c7 04 24 f0 95 10 80 	movl   $0x801095f0,(%esp)
80103487:	e8 b1 d0 ff ff       	call   8010053d <panic>

  idewait(0);
8010348c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103493:	e8 f2 fe ff ff       	call   8010338a <idewait>
  outb(0x3f6, 0);  // generate interrupt
80103498:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010349f:	00 
801034a0:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801034a7:	e8 9b fe ff ff       	call   80103347 <outb>
  outb(0x1f2, 1);  // number of sectors
801034ac:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801034b3:	00 
801034b4:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801034bb:	e8 87 fe ff ff       	call   80103347 <outb>
  outb(0x1f3, b->sector & 0xff);
801034c0:	8b 45 08             	mov    0x8(%ebp),%eax
801034c3:	8b 40 08             	mov    0x8(%eax),%eax
801034c6:	0f b6 c0             	movzbl %al,%eax
801034c9:	89 44 24 04          	mov    %eax,0x4(%esp)
801034cd:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801034d4:	e8 6e fe ff ff       	call   80103347 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801034d9:	8b 45 08             	mov    0x8(%ebp),%eax
801034dc:	8b 40 08             	mov    0x8(%eax),%eax
801034df:	c1 e8 08             	shr    $0x8,%eax
801034e2:	0f b6 c0             	movzbl %al,%eax
801034e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801034e9:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801034f0:	e8 52 fe ff ff       	call   80103347 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801034f5:	8b 45 08             	mov    0x8(%ebp),%eax
801034f8:	8b 40 08             	mov    0x8(%eax),%eax
801034fb:	c1 e8 10             	shr    $0x10,%eax
801034fe:	0f b6 c0             	movzbl %al,%eax
80103501:	89 44 24 04          	mov    %eax,0x4(%esp)
80103505:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010350c:	e8 36 fe ff ff       	call   80103347 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80103511:	8b 45 08             	mov    0x8(%ebp),%eax
80103514:	8b 40 04             	mov    0x4(%eax),%eax
80103517:	83 e0 01             	and    $0x1,%eax
8010351a:	89 c2                	mov    %eax,%edx
8010351c:	c1 e2 04             	shl    $0x4,%edx
8010351f:	8b 45 08             	mov    0x8(%ebp),%eax
80103522:	8b 40 08             	mov    0x8(%eax),%eax
80103525:	c1 e8 18             	shr    $0x18,%eax
80103528:	83 e0 0f             	and    $0xf,%eax
8010352b:	09 d0                	or     %edx,%eax
8010352d:	83 c8 e0             	or     $0xffffffe0,%eax
80103530:	0f b6 c0             	movzbl %al,%eax
80103533:	89 44 24 04          	mov    %eax,0x4(%esp)
80103537:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010353e:	e8 04 fe ff ff       	call   80103347 <outb>
  if(b->flags & B_DIRTY){
80103543:	8b 45 08             	mov    0x8(%ebp),%eax
80103546:	8b 00                	mov    (%eax),%eax
80103548:	83 e0 04             	and    $0x4,%eax
8010354b:	85 c0                	test   %eax,%eax
8010354d:	74 34                	je     80103583 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010354f:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80103556:	00 
80103557:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010355e:	e8 e4 fd ff ff       	call   80103347 <outb>
    outsl(0x1f0, b->data, 512/4);
80103563:	8b 45 08             	mov    0x8(%ebp),%eax
80103566:	83 c0 18             	add    $0x18,%eax
80103569:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80103570:	00 
80103571:	89 44 24 04          	mov    %eax,0x4(%esp)
80103575:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010357c:	e8 e4 fd ff ff       	call   80103365 <outsl>
80103581:	eb 14                	jmp    80103597 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80103583:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010358a:	00 
8010358b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103592:	e8 b0 fd ff ff       	call   80103347 <outb>
  }
}
80103597:	c9                   	leave  
80103598:	c3                   	ret    

80103599 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80103599:	55                   	push   %ebp
8010359a:	89 e5                	mov    %esp,%ebp
8010359c:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010359f:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801035a6:	e8 a0 24 00 00       	call   80105a4b <acquire>
  if((b = idequeue) == 0){
801035ab:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801035b0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801035b3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801035b7:	75 11                	jne    801035ca <ideintr+0x31>
    release(&idelock);
801035b9:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801035c0:	e8 e8 24 00 00       	call   80105aad <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801035c5:	e9 90 00 00 00       	jmp    8010365a <ideintr+0xc1>
  }
  idequeue = b->qnext;
801035ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035cd:	8b 40 14             	mov    0x14(%eax),%eax
801035d0:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801035d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035d8:	8b 00                	mov    (%eax),%eax
801035da:	83 e0 04             	and    $0x4,%eax
801035dd:	85 c0                	test   %eax,%eax
801035df:	75 2e                	jne    8010360f <ideintr+0x76>
801035e1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035e8:	e8 9d fd ff ff       	call   8010338a <idewait>
801035ed:	85 c0                	test   %eax,%eax
801035ef:	78 1e                	js     8010360f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801035f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035f4:	83 c0 18             	add    $0x18,%eax
801035f7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801035fe:	00 
801035ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80103603:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010360a:	e8 13 fd ff ff       	call   80103322 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010360f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103612:	8b 00                	mov    (%eax),%eax
80103614:	89 c2                	mov    %eax,%edx
80103616:	83 ca 02             	or     $0x2,%edx
80103619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010361c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010361e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103621:	8b 00                	mov    (%eax),%eax
80103623:	89 c2                	mov    %eax,%edx
80103625:	83 e2 fb             	and    $0xfffffffb,%edx
80103628:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010362b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010362d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103630:	89 04 24             	mov    %eax,(%esp)
80103633:	e8 0e 22 00 00       	call   80105846 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103638:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010363d:	85 c0                	test   %eax,%eax
8010363f:	74 0d                	je     8010364e <ideintr+0xb5>
    idestart(idequeue);
80103641:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103646:	89 04 24             	mov    %eax,(%esp)
80103649:	e8 26 fe ff ff       	call   80103474 <idestart>

  release(&idelock);
8010364e:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103655:	e8 53 24 00 00       	call   80105aad <release>
}
8010365a:	c9                   	leave  
8010365b:	c3                   	ret    

8010365c <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010365c:	55                   	push   %ebp
8010365d:	89 e5                	mov    %esp,%ebp
8010365f:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80103662:	8b 45 08             	mov    0x8(%ebp),%eax
80103665:	8b 00                	mov    (%eax),%eax
80103667:	83 e0 01             	and    $0x1,%eax
8010366a:	85 c0                	test   %eax,%eax
8010366c:	75 0c                	jne    8010367a <iderw+0x1e>
    panic("iderw: buf not busy");
8010366e:	c7 04 24 f9 95 10 80 	movl   $0x801095f9,(%esp)
80103675:	e8 c3 ce ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010367a:	8b 45 08             	mov    0x8(%ebp),%eax
8010367d:	8b 00                	mov    (%eax),%eax
8010367f:	83 e0 06             	and    $0x6,%eax
80103682:	83 f8 02             	cmp    $0x2,%eax
80103685:	75 0c                	jne    80103693 <iderw+0x37>
    panic("iderw: nothing to do");
80103687:	c7 04 24 0d 96 10 80 	movl   $0x8010960d,(%esp)
8010368e:	e8 aa ce ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80103693:	8b 45 08             	mov    0x8(%ebp),%eax
80103696:	8b 40 04             	mov    0x4(%eax),%eax
80103699:	85 c0                	test   %eax,%eax
8010369b:	74 15                	je     801036b2 <iderw+0x56>
8010369d:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801036a2:	85 c0                	test   %eax,%eax
801036a4:	75 0c                	jne    801036b2 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801036a6:	c7 04 24 22 96 10 80 	movl   $0x80109622,(%esp)
801036ad:	e8 8b ce ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801036b2:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801036b9:	e8 8d 23 00 00       	call   80105a4b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801036be:	8b 45 08             	mov    0x8(%ebp),%eax
801036c1:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801036c8:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801036cf:	eb 0b                	jmp    801036dc <iderw+0x80>
801036d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036d4:	8b 00                	mov    (%eax),%eax
801036d6:	83 c0 14             	add    $0x14,%eax
801036d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801036dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036df:	8b 00                	mov    (%eax),%eax
801036e1:	85 c0                	test   %eax,%eax
801036e3:	75 ec                	jne    801036d1 <iderw+0x75>
    ;
  *pp = b;
801036e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036e8:	8b 55 08             	mov    0x8(%ebp),%edx
801036eb:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801036ed:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801036f2:	3b 45 08             	cmp    0x8(%ebp),%eax
801036f5:	75 22                	jne    80103719 <iderw+0xbd>
    idestart(b);
801036f7:	8b 45 08             	mov    0x8(%ebp),%eax
801036fa:	89 04 24             	mov    %eax,(%esp)
801036fd:	e8 72 fd ff ff       	call   80103474 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103702:	eb 15                	jmp    80103719 <iderw+0xbd>
    sleep(b, &idelock);
80103704:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
8010370b:	80 
8010370c:	8b 45 08             	mov    0x8(%ebp),%eax
8010370f:	89 04 24             	mov    %eax,(%esp)
80103712:	e8 56 20 00 00       	call   8010576d <sleep>
80103717:	eb 01                	jmp    8010371a <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103719:	90                   	nop
8010371a:	8b 45 08             	mov    0x8(%ebp),%eax
8010371d:	8b 00                	mov    (%eax),%eax
8010371f:	83 e0 06             	and    $0x6,%eax
80103722:	83 f8 02             	cmp    $0x2,%eax
80103725:	75 dd                	jne    80103704 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103727:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010372e:	e8 7a 23 00 00       	call   80105aad <release>
}
80103733:	c9                   	leave  
80103734:	c3                   	ret    
80103735:	00 00                	add    %al,(%eax)
	...

80103738 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103738:	55                   	push   %ebp
80103739:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010373b:	a1 54 08 11 80       	mov    0x80110854,%eax
80103740:	8b 55 08             	mov    0x8(%ebp),%edx
80103743:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103745:	a1 54 08 11 80       	mov    0x80110854,%eax
8010374a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010374d:	5d                   	pop    %ebp
8010374e:	c3                   	ret    

8010374f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010374f:	55                   	push   %ebp
80103750:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103752:	a1 54 08 11 80       	mov    0x80110854,%eax
80103757:	8b 55 08             	mov    0x8(%ebp),%edx
8010375a:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
8010375c:	a1 54 08 11 80       	mov    0x80110854,%eax
80103761:	8b 55 0c             	mov    0xc(%ebp),%edx
80103764:	89 50 10             	mov    %edx,0x10(%eax)
}
80103767:	5d                   	pop    %ebp
80103768:	c3                   	ret    

80103769 <ioapicinit>:

void
ioapicinit(void)
{
80103769:	55                   	push   %ebp
8010376a:	89 e5                	mov    %esp,%ebp
8010376c:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010376f:	a1 24 09 11 80       	mov    0x80110924,%eax
80103774:	85 c0                	test   %eax,%eax
80103776:	0f 84 9f 00 00 00    	je     8010381b <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
8010377c:	c7 05 54 08 11 80 00 	movl   $0xfec00000,0x80110854
80103783:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103786:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010378d:	e8 a6 ff ff ff       	call   80103738 <ioapicread>
80103792:	c1 e8 10             	shr    $0x10,%eax
80103795:	25 ff 00 00 00       	and    $0xff,%eax
8010379a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
8010379d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037a4:	e8 8f ff ff ff       	call   80103738 <ioapicread>
801037a9:	c1 e8 18             	shr    $0x18,%eax
801037ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801037af:	0f b6 05 20 09 11 80 	movzbl 0x80110920,%eax
801037b6:	0f b6 c0             	movzbl %al,%eax
801037b9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801037bc:	74 0c                	je     801037ca <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801037be:	c7 04 24 40 96 10 80 	movl   $0x80109640,(%esp)
801037c5:	e8 d7 cb ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801037ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037d1:	eb 3e                	jmp    80103811 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801037d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037d6:	83 c0 20             	add    $0x20,%eax
801037d9:	0d 00 00 01 00       	or     $0x10000,%eax
801037de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037e1:	83 c2 08             	add    $0x8,%edx
801037e4:	01 d2                	add    %edx,%edx
801037e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801037ea:	89 14 24             	mov    %edx,(%esp)
801037ed:	e8 5d ff ff ff       	call   8010374f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
801037f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037f5:	83 c0 08             	add    $0x8,%eax
801037f8:	01 c0                	add    %eax,%eax
801037fa:	83 c0 01             	add    $0x1,%eax
801037fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103804:	00 
80103805:	89 04 24             	mov    %eax,(%esp)
80103808:	e8 42 ff ff ff       	call   8010374f <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
8010380d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103814:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103817:	7e ba                	jle    801037d3 <ioapicinit+0x6a>
80103819:	eb 01                	jmp    8010381c <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
8010381b:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
8010381c:	c9                   	leave  
8010381d:	c3                   	ret    

8010381e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
8010381e:	55                   	push   %ebp
8010381f:	89 e5                	mov    %esp,%ebp
80103821:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103824:	a1 24 09 11 80       	mov    0x80110924,%eax
80103829:	85 c0                	test   %eax,%eax
8010382b:	74 39                	je     80103866 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
8010382d:	8b 45 08             	mov    0x8(%ebp),%eax
80103830:	83 c0 20             	add    $0x20,%eax
80103833:	8b 55 08             	mov    0x8(%ebp),%edx
80103836:	83 c2 08             	add    $0x8,%edx
80103839:	01 d2                	add    %edx,%edx
8010383b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010383f:	89 14 24             	mov    %edx,(%esp)
80103842:	e8 08 ff ff ff       	call   8010374f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103847:	8b 45 0c             	mov    0xc(%ebp),%eax
8010384a:	c1 e0 18             	shl    $0x18,%eax
8010384d:	8b 55 08             	mov    0x8(%ebp),%edx
80103850:	83 c2 08             	add    $0x8,%edx
80103853:	01 d2                	add    %edx,%edx
80103855:	83 c2 01             	add    $0x1,%edx
80103858:	89 44 24 04          	mov    %eax,0x4(%esp)
8010385c:	89 14 24             	mov    %edx,(%esp)
8010385f:	e8 eb fe ff ff       	call   8010374f <ioapicwrite>
80103864:	eb 01                	jmp    80103867 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103866:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103867:	c9                   	leave  
80103868:	c3                   	ret    
80103869:	00 00                	add    %al,(%eax)
	...

8010386c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010386c:	55                   	push   %ebp
8010386d:	89 e5                	mov    %esp,%ebp
8010386f:	8b 45 08             	mov    0x8(%ebp),%eax
80103872:	05 00 00 00 80       	add    $0x80000000,%eax
80103877:	5d                   	pop    %ebp
80103878:	c3                   	ret    

80103879 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103879:	55                   	push   %ebp
8010387a:	89 e5                	mov    %esp,%ebp
8010387c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
8010387f:	c7 44 24 04 72 96 10 	movl   $0x80109672,0x4(%esp)
80103886:	80 
80103887:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
8010388e:	e8 97 21 00 00       	call   80105a2a <initlock>
  kmem.use_lock = 0;
80103893:	c7 05 94 08 11 80 00 	movl   $0x0,0x80110894
8010389a:	00 00 00 
  freerange(vstart, vend);
8010389d:	8b 45 0c             	mov    0xc(%ebp),%eax
801038a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801038a4:	8b 45 08             	mov    0x8(%ebp),%eax
801038a7:	89 04 24             	mov    %eax,(%esp)
801038aa:	e8 26 00 00 00       	call   801038d5 <freerange>
}
801038af:	c9                   	leave  
801038b0:	c3                   	ret    

801038b1 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
801038b1:	55                   	push   %ebp
801038b2:	89 e5                	mov    %esp,%ebp
801038b4:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
801038b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801038ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801038be:	8b 45 08             	mov    0x8(%ebp),%eax
801038c1:	89 04 24             	mov    %eax,(%esp)
801038c4:	e8 0c 00 00 00       	call   801038d5 <freerange>
  kmem.use_lock = 1;
801038c9:	c7 05 94 08 11 80 01 	movl   $0x1,0x80110894
801038d0:	00 00 00 
}
801038d3:	c9                   	leave  
801038d4:	c3                   	ret    

801038d5 <freerange>:

void
freerange(void *vstart, void *vend)
{
801038d5:	55                   	push   %ebp
801038d6:	89 e5                	mov    %esp,%ebp
801038d8:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801038db:	8b 45 08             	mov    0x8(%ebp),%eax
801038de:	05 ff 0f 00 00       	add    $0xfff,%eax
801038e3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801038e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801038eb:	eb 12                	jmp    801038ff <freerange+0x2a>
    kfree(p);
801038ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038f0:	89 04 24             	mov    %eax,(%esp)
801038f3:	e8 16 00 00 00       	call   8010390e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801038f8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801038ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103902:	05 00 10 00 00       	add    $0x1000,%eax
80103907:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010390a:	76 e1                	jbe    801038ed <freerange+0x18>
    kfree(p);
}
8010390c:	c9                   	leave  
8010390d:	c3                   	ret    

8010390e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
8010390e:	55                   	push   %ebp
8010390f:	89 e5                	mov    %esp,%ebp
80103911:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103914:	8b 45 08             	mov    0x8(%ebp),%eax
80103917:	25 ff 0f 00 00       	and    $0xfff,%eax
8010391c:	85 c0                	test   %eax,%eax
8010391e:	75 1b                	jne    8010393b <kfree+0x2d>
80103920:	81 7d 08 1c 37 11 80 	cmpl   $0x8011371c,0x8(%ebp)
80103927:	72 12                	jb     8010393b <kfree+0x2d>
80103929:	8b 45 08             	mov    0x8(%ebp),%eax
8010392c:	89 04 24             	mov    %eax,(%esp)
8010392f:	e8 38 ff ff ff       	call   8010386c <v2p>
80103934:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103939:	76 0c                	jbe    80103947 <kfree+0x39>
    panic("kfree");
8010393b:	c7 04 24 77 96 10 80 	movl   $0x80109677,(%esp)
80103942:	e8 f6 cb ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103947:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010394e:	00 
8010394f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103956:	00 
80103957:	8b 45 08             	mov    0x8(%ebp),%eax
8010395a:	89 04 24             	mov    %eax,(%esp)
8010395d:	e8 38 23 00 00       	call   80105c9a <memset>

  if(kmem.use_lock)
80103962:	a1 94 08 11 80       	mov    0x80110894,%eax
80103967:	85 c0                	test   %eax,%eax
80103969:	74 0c                	je     80103977 <kfree+0x69>
    acquire(&kmem.lock);
8010396b:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
80103972:	e8 d4 20 00 00       	call   80105a4b <acquire>
  r = (struct run*)v;
80103977:	8b 45 08             	mov    0x8(%ebp),%eax
8010397a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
8010397d:	8b 15 98 08 11 80    	mov    0x80110898,%edx
80103983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103986:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103988:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010398b:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
80103990:	a1 94 08 11 80       	mov    0x80110894,%eax
80103995:	85 c0                	test   %eax,%eax
80103997:	74 0c                	je     801039a5 <kfree+0x97>
    release(&kmem.lock);
80103999:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039a0:	e8 08 21 00 00       	call   80105aad <release>
}
801039a5:	c9                   	leave  
801039a6:	c3                   	ret    

801039a7 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801039a7:	55                   	push   %ebp
801039a8:	89 e5                	mov    %esp,%ebp
801039aa:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
801039ad:	a1 94 08 11 80       	mov    0x80110894,%eax
801039b2:	85 c0                	test   %eax,%eax
801039b4:	74 0c                	je     801039c2 <kalloc+0x1b>
    acquire(&kmem.lock);
801039b6:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039bd:	e8 89 20 00 00       	call   80105a4b <acquire>
  r = kmem.freelist;
801039c2:	a1 98 08 11 80       	mov    0x80110898,%eax
801039c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
801039ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801039ce:	74 0a                	je     801039da <kalloc+0x33>
    kmem.freelist = r->next;
801039d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039d3:	8b 00                	mov    (%eax),%eax
801039d5:	a3 98 08 11 80       	mov    %eax,0x80110898
  if(kmem.use_lock)
801039da:	a1 94 08 11 80       	mov    0x80110894,%eax
801039df:	85 c0                	test   %eax,%eax
801039e1:	74 0c                	je     801039ef <kalloc+0x48>
    release(&kmem.lock);
801039e3:	c7 04 24 60 08 11 80 	movl   $0x80110860,(%esp)
801039ea:	e8 be 20 00 00       	call   80105aad <release>
  return (char*)r;
801039ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801039f2:	c9                   	leave  
801039f3:	c3                   	ret    

801039f4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801039f4:	55                   	push   %ebp
801039f5:	89 e5                	mov    %esp,%ebp
801039f7:	53                   	push   %ebx
801039f8:	83 ec 14             	sub    $0x14,%esp
801039fb:	8b 45 08             	mov    0x8(%ebp),%eax
801039fe:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a02:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103a06:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103a0a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103a0e:	ec                   	in     (%dx),%al
80103a0f:	89 c3                	mov    %eax,%ebx
80103a11:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103a14:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103a18:	83 c4 14             	add    $0x14,%esp
80103a1b:	5b                   	pop    %ebx
80103a1c:	5d                   	pop    %ebp
80103a1d:	c3                   	ret    

80103a1e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103a1e:	55                   	push   %ebp
80103a1f:	89 e5                	mov    %esp,%ebp
80103a21:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103a24:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103a2b:	e8 c4 ff ff ff       	call   801039f4 <inb>
80103a30:	0f b6 c0             	movzbl %al,%eax
80103a33:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a39:	83 e0 01             	and    $0x1,%eax
80103a3c:	85 c0                	test   %eax,%eax
80103a3e:	75 0a                	jne    80103a4a <kbdgetc+0x2c>
    return -1;
80103a40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a45:	e9 23 01 00 00       	jmp    80103b6d <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103a4a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103a51:	e8 9e ff ff ff       	call   801039f4 <inb>
80103a56:	0f b6 c0             	movzbl %al,%eax
80103a59:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103a5c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103a63:	75 17                	jne    80103a7c <kbdgetc+0x5e>
    shift |= E0ESC;
80103a65:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103a6a:	83 c8 40             	or     $0x40,%eax
80103a6d:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103a72:	b8 00 00 00 00       	mov    $0x0,%eax
80103a77:	e9 f1 00 00 00       	jmp    80103b6d <kbdgetc+0x14f>
  } else if(data & 0x80){
80103a7c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a7f:	25 80 00 00 00       	and    $0x80,%eax
80103a84:	85 c0                	test   %eax,%eax
80103a86:	74 45                	je     80103acd <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103a88:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103a8d:	83 e0 40             	and    $0x40,%eax
80103a90:	85 c0                	test   %eax,%eax
80103a92:	75 08                	jne    80103a9c <kbdgetc+0x7e>
80103a94:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a97:	83 e0 7f             	and    $0x7f,%eax
80103a9a:	eb 03                	jmp    80103a9f <kbdgetc+0x81>
80103a9c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a9f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103aa2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103aa5:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103aaa:	0f b6 00             	movzbl (%eax),%eax
80103aad:	83 c8 40             	or     $0x40,%eax
80103ab0:	0f b6 c0             	movzbl %al,%eax
80103ab3:	f7 d0                	not    %eax
80103ab5:	89 c2                	mov    %eax,%edx
80103ab7:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103abc:	21 d0                	and    %edx,%eax
80103abe:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103ac3:	b8 00 00 00 00       	mov    $0x0,%eax
80103ac8:	e9 a0 00 00 00       	jmp    80103b6d <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103acd:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ad2:	83 e0 40             	and    $0x40,%eax
80103ad5:	85 c0                	test   %eax,%eax
80103ad7:	74 14                	je     80103aed <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103ad9:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103ae0:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103ae5:	83 e0 bf             	and    $0xffffffbf,%eax
80103ae8:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103aed:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103af0:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103af5:	0f b6 00             	movzbl (%eax),%eax
80103af8:	0f b6 d0             	movzbl %al,%edx
80103afb:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b00:	09 d0                	or     %edx,%eax
80103b02:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103b07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103b0a:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103b0f:	0f b6 00             	movzbl (%eax),%eax
80103b12:	0f b6 d0             	movzbl %al,%edx
80103b15:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b1a:	31 d0                	xor    %edx,%eax
80103b1c:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103b21:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b26:	83 e0 03             	and    $0x3,%eax
80103b29:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103b30:	03 45 fc             	add    -0x4(%ebp),%eax
80103b33:	0f b6 00             	movzbl (%eax),%eax
80103b36:	0f b6 c0             	movzbl %al,%eax
80103b39:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103b3c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103b41:	83 e0 08             	and    $0x8,%eax
80103b44:	85 c0                	test   %eax,%eax
80103b46:	74 22                	je     80103b6a <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103b48:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103b4c:	76 0c                	jbe    80103b5a <kbdgetc+0x13c>
80103b4e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103b52:	77 06                	ja     80103b5a <kbdgetc+0x13c>
      c += 'A' - 'a';
80103b54:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103b58:	eb 10                	jmp    80103b6a <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103b5a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103b5e:	76 0a                	jbe    80103b6a <kbdgetc+0x14c>
80103b60:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103b64:	77 04                	ja     80103b6a <kbdgetc+0x14c>
      c += 'a' - 'A';
80103b66:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103b6a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103b6d:	c9                   	leave  
80103b6e:	c3                   	ret    

80103b6f <kbdintr>:

void
kbdintr(void)
{
80103b6f:	55                   	push   %ebp
80103b70:	89 e5                	mov    %esp,%ebp
80103b72:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103b75:	c7 04 24 1e 3a 10 80 	movl   $0x80103a1e,(%esp)
80103b7c:	e8 2c cc ff ff       	call   801007ad <consoleintr>
}
80103b81:	c9                   	leave  
80103b82:	c3                   	ret    
	...

80103b84 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b84:	55                   	push   %ebp
80103b85:	89 e5                	mov    %esp,%ebp
80103b87:	83 ec 08             	sub    $0x8,%esp
80103b8a:	8b 55 08             	mov    0x8(%ebp),%edx
80103b8d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b90:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b94:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b97:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b9b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b9f:	ee                   	out    %al,(%dx)
}
80103ba0:	c9                   	leave  
80103ba1:	c3                   	ret    

80103ba2 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103ba2:	55                   	push   %ebp
80103ba3:	89 e5                	mov    %esp,%ebp
80103ba5:	53                   	push   %ebx
80103ba6:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103ba9:	9c                   	pushf  
80103baa:	5b                   	pop    %ebx
80103bab:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103bae:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103bb1:	83 c4 10             	add    $0x10,%esp
80103bb4:	5b                   	pop    %ebx
80103bb5:	5d                   	pop    %ebp
80103bb6:	c3                   	ret    

80103bb7 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103bb7:	55                   	push   %ebp
80103bb8:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103bba:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103bbf:	8b 55 08             	mov    0x8(%ebp),%edx
80103bc2:	c1 e2 02             	shl    $0x2,%edx
80103bc5:	01 c2                	add    %eax,%edx
80103bc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bca:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103bcc:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103bd1:	83 c0 20             	add    $0x20,%eax
80103bd4:	8b 00                	mov    (%eax),%eax
}
80103bd6:	5d                   	pop    %ebp
80103bd7:	c3                   	ret    

80103bd8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103bd8:	55                   	push   %ebp
80103bd9:	89 e5                	mov    %esp,%ebp
80103bdb:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103bde:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103be3:	85 c0                	test   %eax,%eax
80103be5:	0f 84 47 01 00 00    	je     80103d32 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103beb:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103bf2:	00 
80103bf3:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103bfa:	e8 b8 ff ff ff       	call   80103bb7 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103bff:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103c06:	00 
80103c07:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103c0e:	e8 a4 ff ff ff       	call   80103bb7 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103c13:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103c1a:	00 
80103c1b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103c22:	e8 90 ff ff ff       	call   80103bb7 <lapicw>
  lapicw(TICR, 10000000); 
80103c27:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103c2e:	00 
80103c2f:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103c36:	e8 7c ff ff ff       	call   80103bb7 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103c3b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c42:	00 
80103c43:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103c4a:	e8 68 ff ff ff       	call   80103bb7 <lapicw>
  lapicw(LINT1, MASKED);
80103c4f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c56:	00 
80103c57:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103c5e:	e8 54 ff ff ff       	call   80103bb7 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103c63:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103c68:	83 c0 30             	add    $0x30,%eax
80103c6b:	8b 00                	mov    (%eax),%eax
80103c6d:	c1 e8 10             	shr    $0x10,%eax
80103c70:	25 ff 00 00 00       	and    $0xff,%eax
80103c75:	83 f8 03             	cmp    $0x3,%eax
80103c78:	76 14                	jbe    80103c8e <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103c7a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103c81:	00 
80103c82:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103c89:	e8 29 ff ff ff       	call   80103bb7 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103c8e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103c95:	00 
80103c96:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103c9d:	e8 15 ff ff ff       	call   80103bb7 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103ca2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103ca9:	00 
80103caa:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cb1:	e8 01 ff ff ff       	call   80103bb7 <lapicw>
  lapicw(ESR, 0);
80103cb6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103cbd:	00 
80103cbe:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cc5:	e8 ed fe ff ff       	call   80103bb7 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80103cca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103cd1:	00 
80103cd2:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103cd9:	e8 d9 fe ff ff       	call   80103bb7 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80103cde:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103ce5:	00 
80103ce6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103ced:	e8 c5 fe ff ff       	call   80103bb7 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80103cf2:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103cf9:	00 
80103cfa:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103d01:	e8 b1 fe ff ff       	call   80103bb7 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80103d06:	90                   	nop
80103d07:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d0c:	05 00 03 00 00       	add    $0x300,%eax
80103d11:	8b 00                	mov    (%eax),%eax
80103d13:	25 00 10 00 00       	and    $0x1000,%eax
80103d18:	85 c0                	test   %eax,%eax
80103d1a:	75 eb                	jne    80103d07 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103d1c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103d23:	00 
80103d24:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d2b:	e8 87 fe ff ff       	call   80103bb7 <lapicw>
80103d30:	eb 01                	jmp    80103d33 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103d32:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103d33:	c9                   	leave  
80103d34:	c3                   	ret    

80103d35 <cpunum>:

int
cpunum(void)
{
80103d35:	55                   	push   %ebp
80103d36:	89 e5                	mov    %esp,%ebp
80103d38:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103d3b:	e8 62 fe ff ff       	call   80103ba2 <readeflags>
80103d40:	25 00 02 00 00       	and    $0x200,%eax
80103d45:	85 c0                	test   %eax,%eax
80103d47:	74 29                	je     80103d72 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103d49:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103d4e:	85 c0                	test   %eax,%eax
80103d50:	0f 94 c2             	sete   %dl
80103d53:	83 c0 01             	add    $0x1,%eax
80103d56:	a3 60 c6 10 80       	mov    %eax,0x8010c660
80103d5b:	84 d2                	test   %dl,%dl
80103d5d:	74 13                	je     80103d72 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103d5f:	8b 45 04             	mov    0x4(%ebp),%eax
80103d62:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d66:	c7 04 24 80 96 10 80 	movl   $0x80109680,(%esp)
80103d6d:	e8 2f c6 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103d72:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d77:	85 c0                	test   %eax,%eax
80103d79:	74 0f                	je     80103d8a <cpunum+0x55>
    return lapic[ID]>>24;
80103d7b:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d80:	83 c0 20             	add    $0x20,%eax
80103d83:	8b 00                	mov    (%eax),%eax
80103d85:	c1 e8 18             	shr    $0x18,%eax
80103d88:	eb 05                	jmp    80103d8f <cpunum+0x5a>
  return 0;
80103d8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103d8f:	c9                   	leave  
80103d90:	c3                   	ret    

80103d91 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103d91:	55                   	push   %ebp
80103d92:	89 e5                	mov    %esp,%ebp
80103d94:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103d97:	a1 9c 08 11 80       	mov    0x8011089c,%eax
80103d9c:	85 c0                	test   %eax,%eax
80103d9e:	74 14                	je     80103db4 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103da0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103da7:	00 
80103da8:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103daf:	e8 03 fe ff ff       	call   80103bb7 <lapicw>
}
80103db4:	c9                   	leave  
80103db5:	c3                   	ret    

80103db6 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103db6:	55                   	push   %ebp
80103db7:	89 e5                	mov    %esp,%ebp
}
80103db9:	5d                   	pop    %ebp
80103dba:	c3                   	ret    

80103dbb <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80103dbb:	55                   	push   %ebp
80103dbc:	89 e5                	mov    %esp,%ebp
80103dbe:	83 ec 1c             	sub    $0x1c,%esp
80103dc1:	8b 45 08             	mov    0x8(%ebp),%eax
80103dc4:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103dc7:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103dce:	00 
80103dcf:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103dd6:	e8 a9 fd ff ff       	call   80103b84 <outb>
  outb(IO_RTC+1, 0x0A);
80103ddb:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103de2:	00 
80103de3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80103dea:	e8 95 fd ff ff       	call   80103b84 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103def:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103df6:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103df9:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103dfe:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103e01:	8d 50 02             	lea    0x2(%eax),%edx
80103e04:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e07:	c1 e8 04             	shr    $0x4,%eax
80103e0a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103e0d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103e11:	c1 e0 18             	shl    $0x18,%eax
80103e14:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e18:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103e1f:	e8 93 fd ff ff       	call   80103bb7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103e24:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80103e2b:	00 
80103e2c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103e33:	e8 7f fd ff ff       	call   80103bb7 <lapicw>
  microdelay(200);
80103e38:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103e3f:	e8 72 ff ff ff       	call   80103db6 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103e44:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80103e4b:	00 
80103e4c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103e53:	e8 5f fd ff ff       	call   80103bb7 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103e58:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103e5f:	e8 52 ff ff ff       	call   80103db6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103e64:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103e6b:	eb 40                	jmp    80103ead <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103e6d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103e71:	c1 e0 18             	shl    $0x18,%eax
80103e74:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e78:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103e7f:	e8 33 fd ff ff       	call   80103bb7 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103e84:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e87:	c1 e8 0c             	shr    $0xc,%eax
80103e8a:	80 cc 06             	or     $0x6,%ah
80103e8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e91:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103e98:	e8 1a fd ff ff       	call   80103bb7 <lapicw>
    microdelay(200);
80103e9d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103ea4:	e8 0d ff ff ff       	call   80103db6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103ea9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103ead:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103eb1:	7e ba                	jle    80103e6d <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103eb3:	c9                   	leave  
80103eb4:	c3                   	ret    
80103eb5:	00 00                	add    %al,(%eax)
	...

80103eb8 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103eb8:	55                   	push   %ebp
80103eb9:	89 e5                	mov    %esp,%ebp
80103ebb:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103ebe:	c7 44 24 04 ac 96 10 	movl   $0x801096ac,0x4(%esp)
80103ec5:	80 
80103ec6:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80103ecd:	e8 58 1b 00 00       	call   80105a2a <initlock>
  readsb(ROOTDEV, &sb);
80103ed2:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103ed5:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ed9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103ee0:	e8 73 df ff ff       	call   80101e58 <readsb>
  log.start = sb.size - sb.nlog;
80103ee5:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eeb:	89 d1                	mov    %edx,%ecx
80103eed:	29 c1                	sub    %eax,%ecx
80103eef:	89 c8                	mov    %ecx,%eax
80103ef1:	a3 d4 08 11 80       	mov    %eax,0x801108d4
  log.size = sb.nlog;
80103ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ef9:	a3 d8 08 11 80       	mov    %eax,0x801108d8
  log.dev = ROOTDEV;
80103efe:	c7 05 e0 08 11 80 01 	movl   $0x1,0x801108e0
80103f05:	00 00 00 
  recover_from_log();
80103f08:	e8 97 01 00 00       	call   801040a4 <recover_from_log>
}
80103f0d:	c9                   	leave  
80103f0e:	c3                   	ret    

80103f0f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
80103f0f:	55                   	push   %ebp
80103f10:	89 e5                	mov    %esp,%ebp
80103f12:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103f15:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103f1c:	e9 89 00 00 00       	jmp    80103faa <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103f21:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103f26:	03 45 f4             	add    -0xc(%ebp),%eax
80103f29:	83 c0 01             	add    $0x1,%eax
80103f2c:	89 c2                	mov    %eax,%edx
80103f2e:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103f33:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f37:	89 04 24             	mov    %eax,(%esp)
80103f3a:	e8 67 c2 ff ff       	call   801001a6 <bread>
80103f3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103f42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f45:	83 c0 10             	add    $0x10,%eax
80103f48:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
80103f4f:	89 c2                	mov    %eax,%edx
80103f51:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103f56:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f5a:	89 04 24             	mov    %eax,(%esp)
80103f5d:	e8 44 c2 ff ff       	call   801001a6 <bread>
80103f62:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103f65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f68:	8d 50 18             	lea    0x18(%eax),%edx
80103f6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f6e:	83 c0 18             	add    $0x18,%eax
80103f71:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103f78:	00 
80103f79:	89 54 24 04          	mov    %edx,0x4(%esp)
80103f7d:	89 04 24             	mov    %eax,(%esp)
80103f80:	e8 e8 1d 00 00       	call   80105d6d <memmove>
    bwrite(dbuf);  // write dst to disk
80103f85:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f88:	89 04 24             	mov    %eax,(%esp)
80103f8b:	e8 4d c2 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103f90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f93:	89 04 24             	mov    %eax,(%esp)
80103f96:	e8 7c c2 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103f9b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103f9e:	89 04 24             	mov    %eax,(%esp)
80103fa1:	e8 71 c2 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103fa6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103faa:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80103faf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103fb2:	0f 8f 69 ff ff ff    	jg     80103f21 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103fb8:	c9                   	leave  
80103fb9:	c3                   	ret    

80103fba <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103fba:	55                   	push   %ebp
80103fbb:	89 e5                	mov    %esp,%ebp
80103fbd:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103fc0:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80103fc5:	89 c2                	mov    %eax,%edx
80103fc7:	a1 e0 08 11 80       	mov    0x801108e0,%eax
80103fcc:	89 54 24 04          	mov    %edx,0x4(%esp)
80103fd0:	89 04 24             	mov    %eax,(%esp)
80103fd3:	e8 ce c1 ff ff       	call   801001a6 <bread>
80103fd8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103fdb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103fde:	83 c0 18             	add    $0x18,%eax
80103fe1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103fe4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103fe7:	8b 00                	mov    (%eax),%eax
80103fe9:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  for (i = 0; i < log.lh.n; i++) {
80103fee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ff5:	eb 1b                	jmp    80104012 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103ff7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103ffa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103ffd:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80104001:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104004:	83 c2 10             	add    $0x10,%edx
80104007:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010400e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104012:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104017:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010401a:	7f db                	jg     80103ff7 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010401c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010401f:	89 04 24             	mov    %eax,(%esp)
80104022:	e8 f0 c1 ff ff       	call   80100217 <brelse>
}
80104027:	c9                   	leave  
80104028:	c3                   	ret    

80104029 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80104029:	55                   	push   %ebp
8010402a:	89 e5                	mov    %esp,%ebp
8010402c:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010402f:	a1 d4 08 11 80       	mov    0x801108d4,%eax
80104034:	89 c2                	mov    %eax,%edx
80104036:	a1 e0 08 11 80       	mov    0x801108e0,%eax
8010403b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010403f:	89 04 24             	mov    %eax,(%esp)
80104042:	e8 5f c1 ff ff       	call   801001a6 <bread>
80104047:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010404a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010404d:	83 c0 18             	add    $0x18,%eax
80104050:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80104053:	8b 15 e4 08 11 80    	mov    0x801108e4,%edx
80104059:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010405c:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010405e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104065:	eb 1b                	jmp    80104082 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80104067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010406a:	83 c0 10             	add    $0x10,%eax
8010406d:	8b 0c 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%ecx
80104074:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104077:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010407a:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010407e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104082:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104087:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010408a:	7f db                	jg     80104067 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
8010408c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010408f:	89 04 24             	mov    %eax,(%esp)
80104092:	e8 46 c1 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80104097:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010409a:	89 04 24             	mov    %eax,(%esp)
8010409d:	e8 75 c1 ff ff       	call   80100217 <brelse>
}
801040a2:	c9                   	leave  
801040a3:	c3                   	ret    

801040a4 <recover_from_log>:

static void
recover_from_log(void)
{
801040a4:	55                   	push   %ebp
801040a5:	89 e5                	mov    %esp,%ebp
801040a7:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801040aa:	e8 0b ff ff ff       	call   80103fba <read_head>
  install_trans(); // if committed, copy from log to disk
801040af:	e8 5b fe ff ff       	call   80103f0f <install_trans>
  log.lh.n = 0;
801040b4:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
801040bb:	00 00 00 
  write_head(); // clear the log
801040be:	e8 66 ff ff ff       	call   80104029 <write_head>
}
801040c3:	c9                   	leave  
801040c4:	c3                   	ret    

801040c5 <begin_trans>:

void
begin_trans(void)
{
801040c5:	55                   	push   %ebp
801040c6:	89 e5                	mov    %esp,%ebp
801040c8:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801040cb:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
801040d2:	e8 74 19 00 00       	call   80105a4b <acquire>
  while (log.busy) {
801040d7:	eb 14                	jmp    801040ed <begin_trans+0x28>
    sleep(&log, &log.lock);
801040d9:	c7 44 24 04 a0 08 11 	movl   $0x801108a0,0x4(%esp)
801040e0:	80 
801040e1:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
801040e8:	e8 80 16 00 00       	call   8010576d <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801040ed:	a1 dc 08 11 80       	mov    0x801108dc,%eax
801040f2:	85 c0                	test   %eax,%eax
801040f4:	75 e3                	jne    801040d9 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801040f6:	c7 05 dc 08 11 80 01 	movl   $0x1,0x801108dc
801040fd:	00 00 00 
  release(&log.lock);
80104100:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80104107:	e8 a1 19 00 00       	call   80105aad <release>
}
8010410c:	c9                   	leave  
8010410d:	c3                   	ret    

8010410e <commit_trans>:

void
commit_trans(void)
{
8010410e:	55                   	push   %ebp
8010410f:	89 e5                	mov    %esp,%ebp
80104111:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80104114:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104119:	85 c0                	test   %eax,%eax
8010411b:	7e 19                	jle    80104136 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
8010411d:	e8 07 ff ff ff       	call   80104029 <write_head>
    install_trans(); // Now install writes to home locations
80104122:	e8 e8 fd ff ff       	call   80103f0f <install_trans>
    log.lh.n = 0; 
80104127:	c7 05 e4 08 11 80 00 	movl   $0x0,0x801108e4
8010412e:	00 00 00 
    write_head();    // Erase the transaction from the log
80104131:	e8 f3 fe ff ff       	call   80104029 <write_head>
  }
  
  acquire(&log.lock);
80104136:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
8010413d:	e8 09 19 00 00       	call   80105a4b <acquire>
  log.busy = 0;
80104142:	c7 05 dc 08 11 80 00 	movl   $0x0,0x801108dc
80104149:	00 00 00 
  wakeup(&log);
8010414c:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
80104153:	e8 ee 16 00 00       	call   80105846 <wakeup>
  release(&log.lock);
80104158:	c7 04 24 a0 08 11 80 	movl   $0x801108a0,(%esp)
8010415f:	e8 49 19 00 00       	call   80105aad <release>
}
80104164:	c9                   	leave  
80104165:	c3                   	ret    

80104166 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80104166:	55                   	push   %ebp
80104167:	89 e5                	mov    %esp,%ebp
80104169:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010416c:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104171:	83 f8 09             	cmp    $0x9,%eax
80104174:	7f 12                	jg     80104188 <log_write+0x22>
80104176:	a1 e4 08 11 80       	mov    0x801108e4,%eax
8010417b:	8b 15 d8 08 11 80    	mov    0x801108d8,%edx
80104181:	83 ea 01             	sub    $0x1,%edx
80104184:	39 d0                	cmp    %edx,%eax
80104186:	7c 0c                	jl     80104194 <log_write+0x2e>
    panic("too big a transaction");
80104188:	c7 04 24 b0 96 10 80 	movl   $0x801096b0,(%esp)
8010418f:	e8 a9 c3 ff ff       	call   8010053d <panic>
  if (!log.busy)
80104194:	a1 dc 08 11 80       	mov    0x801108dc,%eax
80104199:	85 c0                	test   %eax,%eax
8010419b:	75 0c                	jne    801041a9 <log_write+0x43>
    panic("write outside of trans");
8010419d:	c7 04 24 c6 96 10 80 	movl   $0x801096c6,(%esp)
801041a4:	e8 94 c3 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801041a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041b0:	eb 1d                	jmp    801041cf <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
801041b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b5:	83 c0 10             	add    $0x10,%eax
801041b8:	8b 04 85 a8 08 11 80 	mov    -0x7feef758(,%eax,4),%eax
801041bf:	89 c2                	mov    %eax,%edx
801041c1:	8b 45 08             	mov    0x8(%ebp),%eax
801041c4:	8b 40 08             	mov    0x8(%eax),%eax
801041c7:	39 c2                	cmp    %eax,%edx
801041c9:	74 10                	je     801041db <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801041cb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801041cf:	a1 e4 08 11 80       	mov    0x801108e4,%eax
801041d4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801041d7:	7f d9                	jg     801041b2 <log_write+0x4c>
801041d9:	eb 01                	jmp    801041dc <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801041db:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801041dc:	8b 45 08             	mov    0x8(%ebp),%eax
801041df:	8b 40 08             	mov    0x8(%eax),%eax
801041e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041e5:	83 c2 10             	add    $0x10,%edx
801041e8:	89 04 95 a8 08 11 80 	mov    %eax,-0x7feef758(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801041ef:	a1 d4 08 11 80       	mov    0x801108d4,%eax
801041f4:	03 45 f4             	add    -0xc(%ebp),%eax
801041f7:	83 c0 01             	add    $0x1,%eax
801041fa:	89 c2                	mov    %eax,%edx
801041fc:	8b 45 08             	mov    0x8(%ebp),%eax
801041ff:	8b 40 04             	mov    0x4(%eax),%eax
80104202:	89 54 24 04          	mov    %edx,0x4(%esp)
80104206:	89 04 24             	mov    %eax,(%esp)
80104209:	e8 98 bf ff ff       	call   801001a6 <bread>
8010420e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80104211:	8b 45 08             	mov    0x8(%ebp),%eax
80104214:	8d 50 18             	lea    0x18(%eax),%edx
80104217:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010421a:	83 c0 18             	add    $0x18,%eax
8010421d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104224:	00 
80104225:	89 54 24 04          	mov    %edx,0x4(%esp)
80104229:	89 04 24             	mov    %eax,(%esp)
8010422c:	e8 3c 1b 00 00       	call   80105d6d <memmove>
  bwrite(lbuf);
80104231:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104234:	89 04 24             	mov    %eax,(%esp)
80104237:	e8 a1 bf ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
8010423c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010423f:	89 04 24             	mov    %eax,(%esp)
80104242:	e8 d0 bf ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80104247:	a1 e4 08 11 80       	mov    0x801108e4,%eax
8010424c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010424f:	75 0d                	jne    8010425e <log_write+0xf8>
    log.lh.n++;
80104251:	a1 e4 08 11 80       	mov    0x801108e4,%eax
80104256:	83 c0 01             	add    $0x1,%eax
80104259:	a3 e4 08 11 80       	mov    %eax,0x801108e4
  b->flags |= B_DIRTY; // XXX prevent eviction
8010425e:	8b 45 08             	mov    0x8(%ebp),%eax
80104261:	8b 00                	mov    (%eax),%eax
80104263:	89 c2                	mov    %eax,%edx
80104265:	83 ca 04             	or     $0x4,%edx
80104268:	8b 45 08             	mov    0x8(%ebp),%eax
8010426b:	89 10                	mov    %edx,(%eax)
}
8010426d:	c9                   	leave  
8010426e:	c3                   	ret    
	...

80104270 <v2p>:
80104270:	55                   	push   %ebp
80104271:	89 e5                	mov    %esp,%ebp
80104273:	8b 45 08             	mov    0x8(%ebp),%eax
80104276:	05 00 00 00 80       	add    $0x80000000,%eax
8010427b:	5d                   	pop    %ebp
8010427c:	c3                   	ret    

8010427d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010427d:	55                   	push   %ebp
8010427e:	89 e5                	mov    %esp,%ebp
80104280:	8b 45 08             	mov    0x8(%ebp),%eax
80104283:	05 00 00 00 80       	add    $0x80000000,%eax
80104288:	5d                   	pop    %ebp
80104289:	c3                   	ret    

8010428a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010428a:	55                   	push   %ebp
8010428b:	89 e5                	mov    %esp,%ebp
8010428d:	53                   	push   %ebx
8010428e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104291:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104294:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104297:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010429a:	89 c3                	mov    %eax,%ebx
8010429c:	89 d8                	mov    %ebx,%eax
8010429e:	f0 87 02             	lock xchg %eax,(%edx)
801042a1:	89 c3                	mov    %eax,%ebx
801042a3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801042a6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801042a9:	83 c4 10             	add    $0x10,%esp
801042ac:	5b                   	pop    %ebx
801042ad:	5d                   	pop    %ebp
801042ae:	c3                   	ret    

801042af <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801042af:	55                   	push   %ebp
801042b0:	89 e5                	mov    %esp,%ebp
801042b2:	83 e4 f0             	and    $0xfffffff0,%esp
801042b5:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801042b8:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801042bf:	80 
801042c0:	c7 04 24 1c 37 11 80 	movl   $0x8011371c,(%esp)
801042c7:	e8 ad f5 ff ff       	call   80103879 <kinit1>
  kvmalloc();      // kernel page table
801042cc:	e8 69 47 00 00       	call   80108a3a <kvmalloc>
  mpinit();        // collect info about this machine
801042d1:	e8 63 04 00 00       	call   80104739 <mpinit>
  lapicinit(mpbcpu());
801042d6:	e8 2e 02 00 00       	call   80104509 <mpbcpu>
801042db:	89 04 24             	mov    %eax,(%esp)
801042de:	e8 f5 f8 ff ff       	call   80103bd8 <lapicinit>
  seginit();       // set up segments
801042e3:	e8 f5 40 00 00       	call   801083dd <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801042e8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801042ee:	0f b6 00             	movzbl (%eax),%eax
801042f1:	0f b6 c0             	movzbl %al,%eax
801042f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801042f8:	c7 04 24 dd 96 10 80 	movl   $0x801096dd,(%esp)
801042ff:	e8 9d c0 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104304:	e8 95 06 00 00       	call   8010499e <picinit>
  ioapicinit();    // another interrupt controller
80104309:	e8 5b f4 ff ff       	call   80103769 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010430e:	e8 7a c7 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80104313:	e8 10 34 00 00       	call   80107728 <uartinit>
  pinit();         // process table
80104318:	e8 96 0b 00 00       	call   80104eb3 <pinit>
  tvinit();        // trap vectors
8010431d:	e8 a9 2f 00 00       	call   801072cb <tvinit>
  binit();         // buffer cache
80104322:	e8 0d bd ff ff       	call   80100034 <binit>
  fileinit();      // file table
80104327:	e8 d4 cb ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
8010432c:	e8 06 de ff ff       	call   80102137 <iinit>
  ideinit();       // disk
80104331:	e8 98 f0 ff ff       	call   801033ce <ideinit>
  if(!ismp)
80104336:	a1 24 09 11 80       	mov    0x80110924,%eax
8010433b:	85 c0                	test   %eax,%eax
8010433d:	75 05                	jne    80104344 <main+0x95>
    timerinit();   // uniprocessor timer
8010433f:	e8 ca 2e 00 00       	call   8010720e <timerinit>
  startothers();   // start other processors
80104344:	e8 87 00 00 00       	call   801043d0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80104349:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80104350:	8e 
80104351:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80104358:	e8 54 f5 ff ff       	call   801038b1 <kinit2>
  userinit();      // first user process
8010435d:	e8 6c 0c 00 00       	call   80104fce <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80104362:	e8 22 00 00 00       	call   80104389 <mpmain>

80104367 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80104367:	55                   	push   %ebp
80104368:	89 e5                	mov    %esp,%ebp
8010436a:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
8010436d:	e8 df 46 00 00       	call   80108a51 <switchkvm>
  seginit();
80104372:	e8 66 40 00 00       	call   801083dd <seginit>
  lapicinit(cpunum());
80104377:	e8 b9 f9 ff ff       	call   80103d35 <cpunum>
8010437c:	89 04 24             	mov    %eax,(%esp)
8010437f:	e8 54 f8 ff ff       	call   80103bd8 <lapicinit>
  mpmain();
80104384:	e8 00 00 00 00       	call   80104389 <mpmain>

80104389 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80104389:	55                   	push   %ebp
8010438a:	89 e5                	mov    %esp,%ebp
8010438c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010438f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104395:	0f b6 00             	movzbl (%eax),%eax
80104398:	0f b6 c0             	movzbl %al,%eax
8010439b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010439f:	c7 04 24 f4 96 10 80 	movl   $0x801096f4,(%esp)
801043a6:	e8 f6 bf ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801043ab:	e8 8f 30 00 00       	call   8010743f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801043b0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801043b6:	05 a8 00 00 00       	add    $0xa8,%eax
801043bb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801043c2:	00 
801043c3:	89 04 24             	mov    %eax,(%esp)
801043c6:	e8 bf fe ff ff       	call   8010428a <xchg>
  scheduler();     // start running processes
801043cb:	e8 f4 11 00 00       	call   801055c4 <scheduler>

801043d0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801043d0:	55                   	push   %ebp
801043d1:	89 e5                	mov    %esp,%ebp
801043d3:	53                   	push   %ebx
801043d4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801043d7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801043de:	e8 9a fe ff ff       	call   8010427d <p2v>
801043e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801043e6:	b8 8a 00 00 00       	mov    $0x8a,%eax
801043eb:	89 44 24 08          	mov    %eax,0x8(%esp)
801043ef:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
801043f6:	80 
801043f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043fa:	89 04 24             	mov    %eax,(%esp)
801043fd:	e8 6b 19 00 00       	call   80105d6d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80104402:	c7 45 f4 40 09 11 80 	movl   $0x80110940,-0xc(%ebp)
80104409:	e9 86 00 00 00       	jmp    80104494 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010440e:	e8 22 f9 ff ff       	call   80103d35 <cpunum>
80104413:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104419:	05 40 09 11 80       	add    $0x80110940,%eax
8010441e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104421:	74 69                	je     8010448c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80104423:	e8 7f f5 ff ff       	call   801039a7 <kalloc>
80104428:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010442b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010442e:	83 e8 04             	sub    $0x4,%eax
80104431:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104434:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010443a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010443c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010443f:	83 e8 08             	sub    $0x8,%eax
80104442:	c7 00 67 43 10 80    	movl   $0x80104367,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80104448:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010444b:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010444e:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80104455:	e8 16 fe ff ff       	call   80104270 <v2p>
8010445a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010445c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010445f:	89 04 24             	mov    %eax,(%esp)
80104462:	e8 09 fe ff ff       	call   80104270 <v2p>
80104467:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010446a:	0f b6 12             	movzbl (%edx),%edx
8010446d:	0f b6 d2             	movzbl %dl,%edx
80104470:	89 44 24 04          	mov    %eax,0x4(%esp)
80104474:	89 14 24             	mov    %edx,(%esp)
80104477:	e8 3f f9 ff ff       	call   80103dbb <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010447c:	90                   	nop
8010447d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104480:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104486:	85 c0                	test   %eax,%eax
80104488:	74 f3                	je     8010447d <startothers+0xad>
8010448a:	eb 01                	jmp    8010448d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010448c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010448d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80104494:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104499:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010449f:	05 40 09 11 80       	add    $0x80110940,%eax
801044a4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801044a7:	0f 87 61 ff ff ff    	ja     8010440e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801044ad:	83 c4 24             	add    $0x24,%esp
801044b0:	5b                   	pop    %ebx
801044b1:	5d                   	pop    %ebp
801044b2:	c3                   	ret    
	...

801044b4 <p2v>:
801044b4:	55                   	push   %ebp
801044b5:	89 e5                	mov    %esp,%ebp
801044b7:	8b 45 08             	mov    0x8(%ebp),%eax
801044ba:	05 00 00 00 80       	add    $0x80000000,%eax
801044bf:	5d                   	pop    %ebp
801044c0:	c3                   	ret    

801044c1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801044c1:	55                   	push   %ebp
801044c2:	89 e5                	mov    %esp,%ebp
801044c4:	53                   	push   %ebx
801044c5:	83 ec 14             	sub    $0x14,%esp
801044c8:	8b 45 08             	mov    0x8(%ebp),%eax
801044cb:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801044cf:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801044d3:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801044d7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801044db:	ec                   	in     (%dx),%al
801044dc:	89 c3                	mov    %eax,%ebx
801044de:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801044e1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801044e5:	83 c4 14             	add    $0x14,%esp
801044e8:	5b                   	pop    %ebx
801044e9:	5d                   	pop    %ebp
801044ea:	c3                   	ret    

801044eb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801044eb:	55                   	push   %ebp
801044ec:	89 e5                	mov    %esp,%ebp
801044ee:	83 ec 08             	sub    $0x8,%esp
801044f1:	8b 55 08             	mov    0x8(%ebp),%edx
801044f4:	8b 45 0c             	mov    0xc(%ebp),%eax
801044f7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801044fb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801044fe:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104502:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104506:	ee                   	out    %al,(%dx)
}
80104507:	c9                   	leave  
80104508:	c3                   	ret    

80104509 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104509:	55                   	push   %ebp
8010450a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010450c:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80104511:	89 c2                	mov    %eax,%edx
80104513:	b8 40 09 11 80       	mov    $0x80110940,%eax
80104518:	89 d1                	mov    %edx,%ecx
8010451a:	29 c1                	sub    %eax,%ecx
8010451c:	89 c8                	mov    %ecx,%eax
8010451e:	c1 f8 02             	sar    $0x2,%eax
80104521:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104527:	5d                   	pop    %ebp
80104528:	c3                   	ret    

80104529 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104529:	55                   	push   %ebp
8010452a:	89 e5                	mov    %esp,%ebp
8010452c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010452f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104536:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010453d:	eb 13                	jmp    80104552 <sum+0x29>
    sum += addr[i];
8010453f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104542:	03 45 08             	add    0x8(%ebp),%eax
80104545:	0f b6 00             	movzbl (%eax),%eax
80104548:	0f b6 c0             	movzbl %al,%eax
8010454b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010454e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104552:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104555:	3b 45 0c             	cmp    0xc(%ebp),%eax
80104558:	7c e5                	jl     8010453f <sum+0x16>
    sum += addr[i];
  return sum;
8010455a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010455d:	c9                   	leave  
8010455e:	c3                   	ret    

8010455f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010455f:	55                   	push   %ebp
80104560:	89 e5                	mov    %esp,%ebp
80104562:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80104565:	8b 45 08             	mov    0x8(%ebp),%eax
80104568:	89 04 24             	mov    %eax,(%esp)
8010456b:	e8 44 ff ff ff       	call   801044b4 <p2v>
80104570:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80104573:	8b 45 0c             	mov    0xc(%ebp),%eax
80104576:	03 45 f0             	add    -0x10(%ebp),%eax
80104579:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010457c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010457f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104582:	eb 3f                	jmp    801045c3 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80104584:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010458b:	00 
8010458c:	c7 44 24 04 08 97 10 	movl   $0x80109708,0x4(%esp)
80104593:	80 
80104594:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104597:	89 04 24             	mov    %eax,(%esp)
8010459a:	e8 72 17 00 00       	call   80105d11 <memcmp>
8010459f:	85 c0                	test   %eax,%eax
801045a1:	75 1c                	jne    801045bf <mpsearch1+0x60>
801045a3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801045aa:	00 
801045ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ae:	89 04 24             	mov    %eax,(%esp)
801045b1:	e8 73 ff ff ff       	call   80104529 <sum>
801045b6:	84 c0                	test   %al,%al
801045b8:	75 05                	jne    801045bf <mpsearch1+0x60>
      return (struct mp*)p;
801045ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045bd:	eb 11                	jmp    801045d0 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801045bf:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801045c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801045c9:	72 b9                	jb     80104584 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801045cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045d0:	c9                   	leave  
801045d1:	c3                   	ret    

801045d2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801045d2:	55                   	push   %ebp
801045d3:	89 e5                	mov    %esp,%ebp
801045d5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801045d8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801045df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e2:	83 c0 0f             	add    $0xf,%eax
801045e5:	0f b6 00             	movzbl (%eax),%eax
801045e8:	0f b6 c0             	movzbl %al,%eax
801045eb:	89 c2                	mov    %eax,%edx
801045ed:	c1 e2 08             	shl    $0x8,%edx
801045f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f3:	83 c0 0e             	add    $0xe,%eax
801045f6:	0f b6 00             	movzbl (%eax),%eax
801045f9:	0f b6 c0             	movzbl %al,%eax
801045fc:	09 d0                	or     %edx,%eax
801045fe:	c1 e0 04             	shl    $0x4,%eax
80104601:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104604:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104608:	74 21                	je     8010462b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010460a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80104611:	00 
80104612:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104615:	89 04 24             	mov    %eax,(%esp)
80104618:	e8 42 ff ff ff       	call   8010455f <mpsearch1>
8010461d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104620:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104624:	74 50                	je     80104676 <mpsearch+0xa4>
      return mp;
80104626:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104629:	eb 5f                	jmp    8010468a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010462b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010462e:	83 c0 14             	add    $0x14,%eax
80104631:	0f b6 00             	movzbl (%eax),%eax
80104634:	0f b6 c0             	movzbl %al,%eax
80104637:	89 c2                	mov    %eax,%edx
80104639:	c1 e2 08             	shl    $0x8,%edx
8010463c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463f:	83 c0 13             	add    $0x13,%eax
80104642:	0f b6 00             	movzbl (%eax),%eax
80104645:	0f b6 c0             	movzbl %al,%eax
80104648:	09 d0                	or     %edx,%eax
8010464a:	c1 e0 0a             	shl    $0xa,%eax
8010464d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80104650:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104653:	2d 00 04 00 00       	sub    $0x400,%eax
80104658:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010465f:	00 
80104660:	89 04 24             	mov    %eax,(%esp)
80104663:	e8 f7 fe ff ff       	call   8010455f <mpsearch1>
80104668:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010466b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010466f:	74 05                	je     80104676 <mpsearch+0xa4>
      return mp;
80104671:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104674:	eb 14                	jmp    8010468a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80104676:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010467d:	00 
8010467e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80104685:	e8 d5 fe ff ff       	call   8010455f <mpsearch1>
}
8010468a:	c9                   	leave  
8010468b:	c3                   	ret    

8010468c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010468c:	55                   	push   %ebp
8010468d:	89 e5                	mov    %esp,%ebp
8010468f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80104692:	e8 3b ff ff ff       	call   801045d2 <mpsearch>
80104697:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010469a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010469e:	74 0a                	je     801046aa <mpconfig+0x1e>
801046a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a3:	8b 40 04             	mov    0x4(%eax),%eax
801046a6:	85 c0                	test   %eax,%eax
801046a8:	75 0a                	jne    801046b4 <mpconfig+0x28>
    return 0;
801046aa:	b8 00 00 00 00       	mov    $0x0,%eax
801046af:	e9 83 00 00 00       	jmp    80104737 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801046b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b7:	8b 40 04             	mov    0x4(%eax),%eax
801046ba:	89 04 24             	mov    %eax,(%esp)
801046bd:	e8 f2 fd ff ff       	call   801044b4 <p2v>
801046c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801046c5:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801046cc:	00 
801046cd:	c7 44 24 04 0d 97 10 	movl   $0x8010970d,0x4(%esp)
801046d4:	80 
801046d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046d8:	89 04 24             	mov    %eax,(%esp)
801046db:	e8 31 16 00 00       	call   80105d11 <memcmp>
801046e0:	85 c0                	test   %eax,%eax
801046e2:	74 07                	je     801046eb <mpconfig+0x5f>
    return 0;
801046e4:	b8 00 00 00 00       	mov    $0x0,%eax
801046e9:	eb 4c                	jmp    80104737 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801046eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046ee:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801046f2:	3c 01                	cmp    $0x1,%al
801046f4:	74 12                	je     80104708 <mpconfig+0x7c>
801046f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801046f9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801046fd:	3c 04                	cmp    $0x4,%al
801046ff:	74 07                	je     80104708 <mpconfig+0x7c>
    return 0;
80104701:	b8 00 00 00 00       	mov    $0x0,%eax
80104706:	eb 2f                	jmp    80104737 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104708:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010470b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010470f:	0f b7 c0             	movzwl %ax,%eax
80104712:	89 44 24 04          	mov    %eax,0x4(%esp)
80104716:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104719:	89 04 24             	mov    %eax,(%esp)
8010471c:	e8 08 fe ff ff       	call   80104529 <sum>
80104721:	84 c0                	test   %al,%al
80104723:	74 07                	je     8010472c <mpconfig+0xa0>
    return 0;
80104725:	b8 00 00 00 00       	mov    $0x0,%eax
8010472a:	eb 0b                	jmp    80104737 <mpconfig+0xab>
  *pmp = mp;
8010472c:	8b 45 08             	mov    0x8(%ebp),%eax
8010472f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104732:	89 10                	mov    %edx,(%eax)
  return conf;
80104734:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104737:	c9                   	leave  
80104738:	c3                   	ret    

80104739 <mpinit>:

void
mpinit(void)
{
80104739:	55                   	push   %ebp
8010473a:	89 e5                	mov    %esp,%ebp
8010473c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010473f:	c7 05 64 c6 10 80 40 	movl   $0x80110940,0x8010c664
80104746:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104749:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010474c:	89 04 24             	mov    %eax,(%esp)
8010474f:	e8 38 ff ff ff       	call   8010468c <mpconfig>
80104754:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104757:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010475b:	0f 84 9c 01 00 00    	je     801048fd <mpinit+0x1c4>
    return;
  ismp = 1;
80104761:	c7 05 24 09 11 80 01 	movl   $0x1,0x80110924
80104768:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010476b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010476e:	8b 40 24             	mov    0x24(%eax),%eax
80104771:	a3 9c 08 11 80       	mov    %eax,0x8011089c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104776:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104779:	83 c0 2c             	add    $0x2c,%eax
8010477c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010477f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104782:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104786:	0f b7 c0             	movzwl %ax,%eax
80104789:	03 45 f0             	add    -0x10(%ebp),%eax
8010478c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010478f:	e9 f4 00 00 00       	jmp    80104888 <mpinit+0x14f>
    switch(*p){
80104794:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104797:	0f b6 00             	movzbl (%eax),%eax
8010479a:	0f b6 c0             	movzbl %al,%eax
8010479d:	83 f8 04             	cmp    $0x4,%eax
801047a0:	0f 87 bf 00 00 00    	ja     80104865 <mpinit+0x12c>
801047a6:	8b 04 85 50 97 10 80 	mov    -0x7fef68b0(,%eax,4),%eax
801047ad:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801047af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047b2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801047b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047b8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801047bc:	0f b6 d0             	movzbl %al,%edx
801047bf:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801047c4:	39 c2                	cmp    %eax,%edx
801047c6:	74 2d                	je     801047f5 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801047c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047cb:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801047cf:	0f b6 d0             	movzbl %al,%edx
801047d2:	a1 20 0f 11 80       	mov    0x80110f20,%eax
801047d7:	89 54 24 08          	mov    %edx,0x8(%esp)
801047db:	89 44 24 04          	mov    %eax,0x4(%esp)
801047df:	c7 04 24 12 97 10 80 	movl   $0x80109712,(%esp)
801047e6:	e8 b6 bb ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801047eb:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
801047f2:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801047f5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801047f8:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801047fc:	0f b6 c0             	movzbl %al,%eax
801047ff:	83 e0 02             	and    $0x2,%eax
80104802:	85 c0                	test   %eax,%eax
80104804:	74 15                	je     8010481b <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104806:	a1 20 0f 11 80       	mov    0x80110f20,%eax
8010480b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104811:	05 40 09 11 80       	add    $0x80110940,%eax
80104816:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
8010481b:	8b 15 20 0f 11 80    	mov    0x80110f20,%edx
80104821:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104826:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
8010482c:	81 c2 40 09 11 80    	add    $0x80110940,%edx
80104832:	88 02                	mov    %al,(%edx)
      ncpu++;
80104834:	a1 20 0f 11 80       	mov    0x80110f20,%eax
80104839:	83 c0 01             	add    $0x1,%eax
8010483c:	a3 20 0f 11 80       	mov    %eax,0x80110f20
      p += sizeof(struct mpproc);
80104841:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104845:	eb 41                	jmp    80104888 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104847:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010484a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
8010484d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104850:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104854:	a2 20 09 11 80       	mov    %al,0x80110920
      p += sizeof(struct mpioapic);
80104859:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010485d:	eb 29                	jmp    80104888 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010485f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104863:	eb 23                	jmp    80104888 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104868:	0f b6 00             	movzbl (%eax),%eax
8010486b:	0f b6 c0             	movzbl %al,%eax
8010486e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104872:	c7 04 24 30 97 10 80 	movl   $0x80109730,(%esp)
80104879:	e8 23 bb ff ff       	call   801003a1 <cprintf>
      ismp = 0;
8010487e:	c7 05 24 09 11 80 00 	movl   $0x0,0x80110924
80104885:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010488b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010488e:	0f 82 00 ff ff ff    	jb     80104794 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104894:	a1 24 09 11 80       	mov    0x80110924,%eax
80104899:	85 c0                	test   %eax,%eax
8010489b:	75 1d                	jne    801048ba <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
8010489d:	c7 05 20 0f 11 80 01 	movl   $0x1,0x80110f20
801048a4:	00 00 00 
    lapic = 0;
801048a7:	c7 05 9c 08 11 80 00 	movl   $0x0,0x8011089c
801048ae:	00 00 00 
    ioapicid = 0;
801048b1:	c6 05 20 09 11 80 00 	movb   $0x0,0x80110920
    return;
801048b8:	eb 44                	jmp    801048fe <mpinit+0x1c5>
  }

  if(mp->imcrp){
801048ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048bd:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
801048c1:	84 c0                	test   %al,%al
801048c3:	74 39                	je     801048fe <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
801048c5:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
801048cc:	00 
801048cd:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801048d4:	e8 12 fc ff ff       	call   801044eb <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801048d9:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801048e0:	e8 dc fb ff ff       	call   801044c1 <inb>
801048e5:	83 c8 01             	or     $0x1,%eax
801048e8:	0f b6 c0             	movzbl %al,%eax
801048eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801048ef:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801048f6:	e8 f0 fb ff ff       	call   801044eb <outb>
801048fb:	eb 01                	jmp    801048fe <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
801048fd:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
801048fe:	c9                   	leave  
801048ff:	c3                   	ret    

80104900 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104900:	55                   	push   %ebp
80104901:	89 e5                	mov    %esp,%ebp
80104903:	83 ec 08             	sub    $0x8,%esp
80104906:	8b 55 08             	mov    0x8(%ebp),%edx
80104909:	8b 45 0c             	mov    0xc(%ebp),%eax
8010490c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104910:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104913:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104917:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010491b:	ee                   	out    %al,(%dx)
}
8010491c:	c9                   	leave  
8010491d:	c3                   	ret    

8010491e <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
8010491e:	55                   	push   %ebp
8010491f:	89 e5                	mov    %esp,%ebp
80104921:	83 ec 0c             	sub    $0xc,%esp
80104924:	8b 45 08             	mov    0x8(%ebp),%eax
80104927:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
8010492b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010492f:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104935:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104939:	0f b6 c0             	movzbl %al,%eax
8010493c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104940:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104947:	e8 b4 ff ff ff       	call   80104900 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010494c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104950:	66 c1 e8 08          	shr    $0x8,%ax
80104954:	0f b6 c0             	movzbl %al,%eax
80104957:	89 44 24 04          	mov    %eax,0x4(%esp)
8010495b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104962:	e8 99 ff ff ff       	call   80104900 <outb>
}
80104967:	c9                   	leave  
80104968:	c3                   	ret    

80104969 <picenable>:

void
picenable(int irq)
{
80104969:	55                   	push   %ebp
8010496a:	89 e5                	mov    %esp,%ebp
8010496c:	53                   	push   %ebx
8010496d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104970:	8b 45 08             	mov    0x8(%ebp),%eax
80104973:	ba 01 00 00 00       	mov    $0x1,%edx
80104978:	89 d3                	mov    %edx,%ebx
8010497a:	89 c1                	mov    %eax,%ecx
8010497c:	d3 e3                	shl    %cl,%ebx
8010497e:	89 d8                	mov    %ebx,%eax
80104980:	89 c2                	mov    %eax,%edx
80104982:	f7 d2                	not    %edx
80104984:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
8010498b:	21 d0                	and    %edx,%eax
8010498d:	0f b7 c0             	movzwl %ax,%eax
80104990:	89 04 24             	mov    %eax,(%esp)
80104993:	e8 86 ff ff ff       	call   8010491e <picsetmask>
}
80104998:	83 c4 04             	add    $0x4,%esp
8010499b:	5b                   	pop    %ebx
8010499c:	5d                   	pop    %ebp
8010499d:	c3                   	ret    

8010499e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010499e:	55                   	push   %ebp
8010499f:	89 e5                	mov    %esp,%ebp
801049a1:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
801049a4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801049ab:	00 
801049ac:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801049b3:	e8 48 ff ff ff       	call   80104900 <outb>
  outb(IO_PIC2+1, 0xFF);
801049b8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
801049bf:	00 
801049c0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
801049c7:	e8 34 ff ff ff       	call   80104900 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
801049cc:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801049d3:	00 
801049d4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801049db:	e8 20 ff ff ff       	call   80104900 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801049e0:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801049e7:	00 
801049e8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801049ef:	e8 0c ff ff ff       	call   80104900 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801049f4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801049fb:	00 
801049fc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104a03:	e8 f8 fe ff ff       	call   80104900 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104a08:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104a0f:	00 
80104a10:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104a17:	e8 e4 fe ff ff       	call   80104900 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104a1c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104a23:	00 
80104a24:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104a2b:	e8 d0 fe ff ff       	call   80104900 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104a30:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104a37:	00 
80104a38:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a3f:	e8 bc fe ff ff       	call   80104900 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104a44:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104a4b:	00 
80104a4c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a53:	e8 a8 fe ff ff       	call   80104900 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104a58:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104a5f:	00 
80104a60:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104a67:	e8 94 fe ff ff       	call   80104900 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104a6c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104a73:	00 
80104a74:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104a7b:	e8 80 fe ff ff       	call   80104900 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104a80:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104a87:	00 
80104a88:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104a8f:	e8 6c fe ff ff       	call   80104900 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104a94:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104a9b:	00 
80104a9c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104aa3:	e8 58 fe ff ff       	call   80104900 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104aa8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104aaf:	00 
80104ab0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104ab7:	e8 44 fe ff ff       	call   80104900 <outb>

  if(irqmask != 0xFFFF)
80104abc:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ac3:	66 83 f8 ff          	cmp    $0xffff,%ax
80104ac7:	74 12                	je     80104adb <picinit+0x13d>
    picsetmask(irqmask);
80104ac9:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ad0:	0f b7 c0             	movzwl %ax,%eax
80104ad3:	89 04 24             	mov    %eax,(%esp)
80104ad6:	e8 43 fe ff ff       	call   8010491e <picsetmask>
}
80104adb:	c9                   	leave  
80104adc:	c3                   	ret    
80104add:	00 00                	add    %al,(%eax)
	...

80104ae0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104ae0:	55                   	push   %ebp
80104ae1:	89 e5                	mov    %esp,%ebp
80104ae3:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104ae6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104aed:	8b 45 0c             	mov    0xc(%ebp),%eax
80104af0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104af6:	8b 45 0c             	mov    0xc(%ebp),%eax
80104af9:	8b 10                	mov    (%eax),%edx
80104afb:	8b 45 08             	mov    0x8(%ebp),%eax
80104afe:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104b00:	e8 17 c4 ff ff       	call   80100f1c <filealloc>
80104b05:	8b 55 08             	mov    0x8(%ebp),%edx
80104b08:	89 02                	mov    %eax,(%edx)
80104b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80104b0d:	8b 00                	mov    (%eax),%eax
80104b0f:	85 c0                	test   %eax,%eax
80104b11:	0f 84 c8 00 00 00    	je     80104bdf <pipealloc+0xff>
80104b17:	e8 00 c4 ff ff       	call   80100f1c <filealloc>
80104b1c:	8b 55 0c             	mov    0xc(%ebp),%edx
80104b1f:	89 02                	mov    %eax,(%edx)
80104b21:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b24:	8b 00                	mov    (%eax),%eax
80104b26:	85 c0                	test   %eax,%eax
80104b28:	0f 84 b1 00 00 00    	je     80104bdf <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104b2e:	e8 74 ee ff ff       	call   801039a7 <kalloc>
80104b33:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104b36:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b3a:	0f 84 9e 00 00 00    	je     80104bde <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b43:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104b4a:	00 00 00 
  p->writeopen = 1;
80104b4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b50:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104b57:	00 00 00 
  p->nwrite = 0;
80104b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b5d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104b64:	00 00 00 
  p->nread = 0;
80104b67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104b71:	00 00 00 
  initlock(&p->lock, "pipe");
80104b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b77:	c7 44 24 04 64 97 10 	movl   $0x80109764,0x4(%esp)
80104b7e:	80 
80104b7f:	89 04 24             	mov    %eax,(%esp)
80104b82:	e8 a3 0e 00 00       	call   80105a2a <initlock>
  (*f0)->type = FD_PIPE;
80104b87:	8b 45 08             	mov    0x8(%ebp),%eax
80104b8a:	8b 00                	mov    (%eax),%eax
80104b8c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104b92:	8b 45 08             	mov    0x8(%ebp),%eax
80104b95:	8b 00                	mov    (%eax),%eax
80104b97:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104b9b:	8b 45 08             	mov    0x8(%ebp),%eax
80104b9e:	8b 00                	mov    (%eax),%eax
80104ba0:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104ba4:	8b 45 08             	mov    0x8(%ebp),%eax
80104ba7:	8b 00                	mov    (%eax),%eax
80104ba9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bac:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104baf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bb2:	8b 00                	mov    (%eax),%eax
80104bb4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104bba:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bbd:	8b 00                	mov    (%eax),%eax
80104bbf:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104bc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bc6:	8b 00                	mov    (%eax),%eax
80104bc8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bcf:	8b 00                	mov    (%eax),%eax
80104bd1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bd4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104bd7:	b8 00 00 00 00       	mov    $0x0,%eax
80104bdc:	eb 43                	jmp    80104c21 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104bde:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104bdf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104be3:	74 0b                	je     80104bf0 <pipealloc+0x110>
    kfree((char*)p);
80104be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be8:	89 04 24             	mov    %eax,(%esp)
80104beb:	e8 1e ed ff ff       	call   8010390e <kfree>
  if(*f0)
80104bf0:	8b 45 08             	mov    0x8(%ebp),%eax
80104bf3:	8b 00                	mov    (%eax),%eax
80104bf5:	85 c0                	test   %eax,%eax
80104bf7:	74 0d                	je     80104c06 <pipealloc+0x126>
    fileclose(*f0);
80104bf9:	8b 45 08             	mov    0x8(%ebp),%eax
80104bfc:	8b 00                	mov    (%eax),%eax
80104bfe:	89 04 24             	mov    %eax,(%esp)
80104c01:	e8 be c3 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104c06:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c09:	8b 00                	mov    (%eax),%eax
80104c0b:	85 c0                	test   %eax,%eax
80104c0d:	74 0d                	je     80104c1c <pipealloc+0x13c>
    fileclose(*f1);
80104c0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c12:	8b 00                	mov    (%eax),%eax
80104c14:	89 04 24             	mov    %eax,(%esp)
80104c17:	e8 a8 c3 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104c1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c21:	c9                   	leave  
80104c22:	c3                   	ret    

80104c23 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104c23:	55                   	push   %ebp
80104c24:	89 e5                	mov    %esp,%ebp
80104c26:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104c29:	8b 45 08             	mov    0x8(%ebp),%eax
80104c2c:	89 04 24             	mov    %eax,(%esp)
80104c2f:	e8 17 0e 00 00       	call   80105a4b <acquire>
  if(writable){
80104c34:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c38:	74 1f                	je     80104c59 <pipeclose+0x36>
    p->writeopen = 0;
80104c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c3d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104c44:	00 00 00 
    wakeup(&p->nread);
80104c47:	8b 45 08             	mov    0x8(%ebp),%eax
80104c4a:	05 34 02 00 00       	add    $0x234,%eax
80104c4f:	89 04 24             	mov    %eax,(%esp)
80104c52:	e8 ef 0b 00 00       	call   80105846 <wakeup>
80104c57:	eb 1d                	jmp    80104c76 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104c59:	8b 45 08             	mov    0x8(%ebp),%eax
80104c5c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104c63:	00 00 00 
    wakeup(&p->nwrite);
80104c66:	8b 45 08             	mov    0x8(%ebp),%eax
80104c69:	05 38 02 00 00       	add    $0x238,%eax
80104c6e:	89 04 24             	mov    %eax,(%esp)
80104c71:	e8 d0 0b 00 00       	call   80105846 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104c76:	8b 45 08             	mov    0x8(%ebp),%eax
80104c79:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104c7f:	85 c0                	test   %eax,%eax
80104c81:	75 25                	jne    80104ca8 <pipeclose+0x85>
80104c83:	8b 45 08             	mov    0x8(%ebp),%eax
80104c86:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104c8c:	85 c0                	test   %eax,%eax
80104c8e:	75 18                	jne    80104ca8 <pipeclose+0x85>
    release(&p->lock);
80104c90:	8b 45 08             	mov    0x8(%ebp),%eax
80104c93:	89 04 24             	mov    %eax,(%esp)
80104c96:	e8 12 0e 00 00       	call   80105aad <release>
    kfree((char*)p);
80104c9b:	8b 45 08             	mov    0x8(%ebp),%eax
80104c9e:	89 04 24             	mov    %eax,(%esp)
80104ca1:	e8 68 ec ff ff       	call   8010390e <kfree>
80104ca6:	eb 0b                	jmp    80104cb3 <pipeclose+0x90>
  } else
    release(&p->lock);
80104ca8:	8b 45 08             	mov    0x8(%ebp),%eax
80104cab:	89 04 24             	mov    %eax,(%esp)
80104cae:	e8 fa 0d 00 00       	call   80105aad <release>
}
80104cb3:	c9                   	leave  
80104cb4:	c3                   	ret    

80104cb5 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104cb5:	55                   	push   %ebp
80104cb6:	89 e5                	mov    %esp,%ebp
80104cb8:	53                   	push   %ebx
80104cb9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104cbc:	8b 45 08             	mov    0x8(%ebp),%eax
80104cbf:	89 04 24             	mov    %eax,(%esp)
80104cc2:	e8 84 0d 00 00       	call   80105a4b <acquire>
  for(i = 0; i < n; i++){
80104cc7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104cce:	e9 a6 00 00 00       	jmp    80104d79 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104cd3:	8b 45 08             	mov    0x8(%ebp),%eax
80104cd6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104cdc:	85 c0                	test   %eax,%eax
80104cde:	74 0d                	je     80104ced <pipewrite+0x38>
80104ce0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ce6:	8b 40 24             	mov    0x24(%eax),%eax
80104ce9:	85 c0                	test   %eax,%eax
80104ceb:	74 15                	je     80104d02 <pipewrite+0x4d>
        release(&p->lock);
80104ced:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf0:	89 04 24             	mov    %eax,(%esp)
80104cf3:	e8 b5 0d 00 00       	call   80105aad <release>
        return -1;
80104cf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cfd:	e9 9d 00 00 00       	jmp    80104d9f <pipewrite+0xea>
      }
      wakeup(&p->nread);
80104d02:	8b 45 08             	mov    0x8(%ebp),%eax
80104d05:	05 34 02 00 00       	add    $0x234,%eax
80104d0a:	89 04 24             	mov    %eax,(%esp)
80104d0d:	e8 34 0b 00 00       	call   80105846 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104d12:	8b 45 08             	mov    0x8(%ebp),%eax
80104d15:	8b 55 08             	mov    0x8(%ebp),%edx
80104d18:	81 c2 38 02 00 00    	add    $0x238,%edx
80104d1e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d22:	89 14 24             	mov    %edx,(%esp)
80104d25:	e8 43 0a 00 00       	call   8010576d <sleep>
80104d2a:	eb 01                	jmp    80104d2d <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104d2c:	90                   	nop
80104d2d:	8b 45 08             	mov    0x8(%ebp),%eax
80104d30:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104d36:	8b 45 08             	mov    0x8(%ebp),%eax
80104d39:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104d3f:	05 00 02 00 00       	add    $0x200,%eax
80104d44:	39 c2                	cmp    %eax,%edx
80104d46:	74 8b                	je     80104cd3 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104d48:	8b 45 08             	mov    0x8(%ebp),%eax
80104d4b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104d51:	89 c3                	mov    %eax,%ebx
80104d53:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104d59:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d5c:	03 55 0c             	add    0xc(%ebp),%edx
80104d5f:	0f b6 0a             	movzbl (%edx),%ecx
80104d62:	8b 55 08             	mov    0x8(%ebp),%edx
80104d65:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104d69:	8d 50 01             	lea    0x1(%eax),%edx
80104d6c:	8b 45 08             	mov    0x8(%ebp),%eax
80104d6f:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104d75:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d7c:	3b 45 10             	cmp    0x10(%ebp),%eax
80104d7f:	7c ab                	jl     80104d2c <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104d81:	8b 45 08             	mov    0x8(%ebp),%eax
80104d84:	05 34 02 00 00       	add    $0x234,%eax
80104d89:	89 04 24             	mov    %eax,(%esp)
80104d8c:	e8 b5 0a 00 00       	call   80105846 <wakeup>
  release(&p->lock);
80104d91:	8b 45 08             	mov    0x8(%ebp),%eax
80104d94:	89 04 24             	mov    %eax,(%esp)
80104d97:	e8 11 0d 00 00       	call   80105aad <release>
  return n;
80104d9c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104d9f:	83 c4 24             	add    $0x24,%esp
80104da2:	5b                   	pop    %ebx
80104da3:	5d                   	pop    %ebp
80104da4:	c3                   	ret    

80104da5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104da5:	55                   	push   %ebp
80104da6:	89 e5                	mov    %esp,%ebp
80104da8:	53                   	push   %ebx
80104da9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104dac:	8b 45 08             	mov    0x8(%ebp),%eax
80104daf:	89 04 24             	mov    %eax,(%esp)
80104db2:	e8 94 0c 00 00       	call   80105a4b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104db7:	eb 3a                	jmp    80104df3 <piperead+0x4e>
    if(proc->killed){
80104db9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104dbf:	8b 40 24             	mov    0x24(%eax),%eax
80104dc2:	85 c0                	test   %eax,%eax
80104dc4:	74 15                	je     80104ddb <piperead+0x36>
      release(&p->lock);
80104dc6:	8b 45 08             	mov    0x8(%ebp),%eax
80104dc9:	89 04 24             	mov    %eax,(%esp)
80104dcc:	e8 dc 0c 00 00       	call   80105aad <release>
      return -1;
80104dd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd6:	e9 b6 00 00 00       	jmp    80104e91 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80104dde:	8b 55 08             	mov    0x8(%ebp),%edx
80104de1:	81 c2 34 02 00 00    	add    $0x234,%edx
80104de7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104deb:	89 14 24             	mov    %edx,(%esp)
80104dee:	e8 7a 09 00 00       	call   8010576d <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104df3:	8b 45 08             	mov    0x8(%ebp),%eax
80104df6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80104dff:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104e05:	39 c2                	cmp    %eax,%edx
80104e07:	75 0d                	jne    80104e16 <piperead+0x71>
80104e09:	8b 45 08             	mov    0x8(%ebp),%eax
80104e0c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104e12:	85 c0                	test   %eax,%eax
80104e14:	75 a3                	jne    80104db9 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104e16:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e1d:	eb 49                	jmp    80104e68 <piperead+0xc3>
    if(p->nread == p->nwrite)
80104e1f:	8b 45 08             	mov    0x8(%ebp),%eax
80104e22:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104e28:	8b 45 08             	mov    0x8(%ebp),%eax
80104e2b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104e31:	39 c2                	cmp    %eax,%edx
80104e33:	74 3d                	je     80104e72 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104e35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e38:	89 c2                	mov    %eax,%edx
80104e3a:	03 55 0c             	add    0xc(%ebp),%edx
80104e3d:	8b 45 08             	mov    0x8(%ebp),%eax
80104e40:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104e46:	89 c3                	mov    %eax,%ebx
80104e48:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104e4e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e51:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104e56:	88 0a                	mov    %cl,(%edx)
80104e58:	8d 50 01             	lea    0x1(%eax),%edx
80104e5b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e5e:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104e64:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e6b:	3b 45 10             	cmp    0x10(%ebp),%eax
80104e6e:	7c af                	jl     80104e1f <piperead+0x7a>
80104e70:	eb 01                	jmp    80104e73 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104e72:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104e73:	8b 45 08             	mov    0x8(%ebp),%eax
80104e76:	05 38 02 00 00       	add    $0x238,%eax
80104e7b:	89 04 24             	mov    %eax,(%esp)
80104e7e:	e8 c3 09 00 00       	call   80105846 <wakeup>
  release(&p->lock);
80104e83:	8b 45 08             	mov    0x8(%ebp),%eax
80104e86:	89 04 24             	mov    %eax,(%esp)
80104e89:	e8 1f 0c 00 00       	call   80105aad <release>
  return i;
80104e8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104e91:	83 c4 24             	add    $0x24,%esp
80104e94:	5b                   	pop    %ebx
80104e95:	5d                   	pop    %ebp
80104e96:	c3                   	ret    
	...

80104e98 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104e98:	55                   	push   %ebp
80104e99:	89 e5                	mov    %esp,%ebp
80104e9b:	53                   	push   %ebx
80104e9c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104e9f:	9c                   	pushf  
80104ea0:	5b                   	pop    %ebx
80104ea1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104ea4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104ea7:	83 c4 10             	add    $0x10,%esp
80104eaa:	5b                   	pop    %ebx
80104eab:	5d                   	pop    %ebp
80104eac:	c3                   	ret    

80104ead <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104ead:	55                   	push   %ebp
80104eae:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104eb0:	fb                   	sti    
}
80104eb1:	5d                   	pop    %ebp
80104eb2:	c3                   	ret    

80104eb3 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104eb3:	55                   	push   %ebp
80104eb4:	89 e5                	mov    %esp,%ebp
80104eb6:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104eb9:	c7 44 24 04 69 97 10 	movl   $0x80109769,0x4(%esp)
80104ec0:	80 
80104ec1:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104ec8:	e8 5d 0b 00 00       	call   80105a2a <initlock>
}
80104ecd:	c9                   	leave  
80104ece:	c3                   	ret    

80104ecf <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104ecf:	55                   	push   %ebp
80104ed0:	89 e5                	mov    %esp,%ebp
80104ed2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104ed5:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104edc:	e8 6a 0b 00 00       	call   80105a4b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ee1:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80104ee8:	eb 0e                	jmp    80104ef8 <allocproc+0x29>
    if(p->state == UNUSED)
80104eea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eed:	8b 40 0c             	mov    0xc(%eax),%eax
80104ef0:	85 c0                	test   %eax,%eax
80104ef2:	74 23                	je     80104f17 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104ef4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104ef8:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
80104eff:	72 e9                	jb     80104eea <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104f01:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104f08:	e8 a0 0b 00 00       	call   80105aad <release>
  return 0;
80104f0d:	b8 00 00 00 00       	mov    $0x0,%eax
80104f12:	e9 b5 00 00 00       	jmp    80104fcc <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104f17:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104f18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f1b:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104f22:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104f27:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f2a:	89 42 10             	mov    %eax,0x10(%edx)
80104f2d:	83 c0 01             	add    $0x1,%eax
80104f30:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80104f35:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80104f3c:	e8 6c 0b 00 00       	call   80105aad <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104f41:	e8 61 ea ff ff       	call   801039a7 <kalloc>
80104f46:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f49:	89 42 08             	mov    %eax,0x8(%edx)
80104f4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f4f:	8b 40 08             	mov    0x8(%eax),%eax
80104f52:	85 c0                	test   %eax,%eax
80104f54:	75 11                	jne    80104f67 <allocproc+0x98>
    p->state = UNUSED;
80104f56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f59:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104f60:	b8 00 00 00 00       	mov    $0x0,%eax
80104f65:	eb 65                	jmp    80104fcc <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f6a:	8b 40 08             	mov    0x8(%eax),%eax
80104f6d:	05 00 10 00 00       	add    $0x1000,%eax
80104f72:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104f75:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104f79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f7c:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f7f:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104f82:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104f86:	ba 80 72 10 80       	mov    $0x80107280,%edx
80104f8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f8e:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104f90:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104f94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f97:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104f9a:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104f9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fa0:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fa3:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80104faa:	00 
80104fab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104fb2:	00 
80104fb3:	89 04 24             	mov    %eax,(%esp)
80104fb6:	e8 df 0c 00 00       	call   80105c9a <memset>
  p->context->eip = (uint)forkret;
80104fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fbe:	8b 40 1c             	mov    0x1c(%eax),%eax
80104fc1:	ba 41 57 10 80       	mov    $0x80105741,%edx
80104fc6:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104fc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104fcc:	c9                   	leave  
80104fcd:	c3                   	ret    

80104fce <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104fce:	55                   	push   %ebp
80104fcf:	89 e5                	mov    %esp,%ebp
80104fd1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104fd4:	e8 f6 fe ff ff       	call   80104ecf <allocproc>
80104fd9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104fdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104fdf:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80104fe4:	c7 04 24 a7 39 10 80 	movl   $0x801039a7,(%esp)
80104feb:	e8 8d 39 00 00       	call   8010897d <setupkvm>
80104ff0:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ff3:	89 42 04             	mov    %eax,0x4(%edx)
80104ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ff9:	8b 40 04             	mov    0x4(%eax),%eax
80104ffc:	85 c0                	test   %eax,%eax
80104ffe:	75 0c                	jne    8010500c <userinit+0x3e>
    panic("userinit: out of memory?");
80105000:	c7 04 24 70 97 10 80 	movl   $0x80109770,(%esp)
80105007:	e8 31 b5 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010500c:	ba 2c 00 00 00       	mov    $0x2c,%edx
80105011:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105014:	8b 40 04             	mov    0x4(%eax),%eax
80105017:	89 54 24 08          	mov    %edx,0x8(%esp)
8010501b:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
80105022:	80 
80105023:	89 04 24             	mov    %eax,(%esp)
80105026:	e8 aa 3b 00 00       	call   80108bd5 <inituvm>
  p->sz = PGSIZE;
8010502b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010502e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80105034:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105037:	8b 40 18             	mov    0x18(%eax),%eax
8010503a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80105041:	00 
80105042:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105049:	00 
8010504a:	89 04 24             	mov    %eax,(%esp)
8010504d:	e8 48 0c 00 00       	call   80105c9a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80105052:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105055:	8b 40 18             	mov    0x18(%eax),%eax
80105058:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010505e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105061:	8b 40 18             	mov    0x18(%eax),%eax
80105064:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010506a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010506d:	8b 40 18             	mov    0x18(%eax),%eax
80105070:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105073:	8b 52 18             	mov    0x18(%edx),%edx
80105076:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010507a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010507e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105081:	8b 40 18             	mov    0x18(%eax),%eax
80105084:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105087:	8b 52 18             	mov    0x18(%edx),%edx
8010508a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010508e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80105092:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105095:	8b 40 18             	mov    0x18(%eax),%eax
80105098:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010509f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050a2:	8b 40 18             	mov    0x18(%eax),%eax
801050a5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801050ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050af:	8b 40 18             	mov    0x18(%eax),%eax
801050b2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801050b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050bc:	83 c0 6c             	add    $0x6c,%eax
801050bf:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801050c6:	00 
801050c7:	c7 44 24 04 89 97 10 	movl   $0x80109789,0x4(%esp)
801050ce:	80 
801050cf:	89 04 24             	mov    %eax,(%esp)
801050d2:	e8 f3 0d 00 00       	call   80105eca <safestrcpy>
  p->cwd = namei("/");
801050d7:	c7 04 24 92 97 10 80 	movl   $0x80109792,(%esp)
801050de:	e8 ab de ff ff       	call   80102f8e <namei>
801050e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050e6:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801050e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050ec:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801050f3:	c9                   	leave  
801050f4:	c3                   	ret    

801050f5 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801050f5:	55                   	push   %ebp
801050f6:	89 e5                	mov    %esp,%ebp
801050f8:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801050fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105101:	8b 00                	mov    (%eax),%eax
80105103:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105106:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010510a:	7e 34                	jle    80105140 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010510c:	8b 45 08             	mov    0x8(%ebp),%eax
8010510f:	89 c2                	mov    %eax,%edx
80105111:	03 55 f4             	add    -0xc(%ebp),%edx
80105114:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010511a:	8b 40 04             	mov    0x4(%eax),%eax
8010511d:	89 54 24 08          	mov    %edx,0x8(%esp)
80105121:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105124:	89 54 24 04          	mov    %edx,0x4(%esp)
80105128:	89 04 24             	mov    %eax,(%esp)
8010512b:	e8 1f 3c 00 00       	call   80108d4f <allocuvm>
80105130:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105133:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105137:	75 41                	jne    8010517a <growproc+0x85>
      return -1;
80105139:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010513e:	eb 58                	jmp    80105198 <growproc+0xa3>
  } else if(n < 0){
80105140:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105144:	79 34                	jns    8010517a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80105146:	8b 45 08             	mov    0x8(%ebp),%eax
80105149:	89 c2                	mov    %eax,%edx
8010514b:	03 55 f4             	add    -0xc(%ebp),%edx
8010514e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105154:	8b 40 04             	mov    0x4(%eax),%eax
80105157:	89 54 24 08          	mov    %edx,0x8(%esp)
8010515b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010515e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105162:	89 04 24             	mov    %eax,(%esp)
80105165:	e8 bf 3c 00 00       	call   80108e29 <deallocuvm>
8010516a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010516d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105171:	75 07                	jne    8010517a <growproc+0x85>
      return -1;
80105173:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105178:	eb 1e                	jmp    80105198 <growproc+0xa3>
  }
  proc->sz = sz;
8010517a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105180:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105183:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80105185:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010518b:	89 04 24             	mov    %eax,(%esp)
8010518e:	e8 db 38 00 00       	call   80108a6e <switchuvm>
  return 0;
80105193:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105198:	c9                   	leave  
80105199:	c3                   	ret    

8010519a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010519a:	55                   	push   %ebp
8010519b:	89 e5                	mov    %esp,%ebp
8010519d:	57                   	push   %edi
8010519e:	56                   	push   %esi
8010519f:	53                   	push   %ebx
801051a0:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801051a3:	e8 27 fd ff ff       	call   80104ecf <allocproc>
801051a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
801051ab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801051af:	75 0a                	jne    801051bb <fork+0x21>
    return -1;
801051b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b6:	e9 3a 01 00 00       	jmp    801052f5 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801051bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c1:	8b 10                	mov    (%eax),%edx
801051c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801051c9:	8b 40 04             	mov    0x4(%eax),%eax
801051cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801051d0:	89 04 24             	mov    %eax,(%esp)
801051d3:	e8 e1 3d 00 00       	call   80108fb9 <copyuvm>
801051d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801051db:	89 42 04             	mov    %eax,0x4(%edx)
801051de:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051e1:	8b 40 04             	mov    0x4(%eax),%eax
801051e4:	85 c0                	test   %eax,%eax
801051e6:	75 2c                	jne    80105214 <fork+0x7a>
    kfree(np->kstack);
801051e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051eb:	8b 40 08             	mov    0x8(%eax),%eax
801051ee:	89 04 24             	mov    %eax,(%esp)
801051f1:	e8 18 e7 ff ff       	call   8010390e <kfree>
    np->kstack = 0;
801051f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801051f9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80105200:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105203:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010520a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010520f:	e9 e1 00 00 00       	jmp    801052f5 <fork+0x15b>
  }
  np->sz = proc->sz;
80105214:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010521a:	8b 10                	mov    (%eax),%edx
8010521c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010521f:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80105221:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105228:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010522b:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010522e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105231:	8b 50 18             	mov    0x18(%eax),%edx
80105234:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010523a:	8b 40 18             	mov    0x18(%eax),%eax
8010523d:	89 c3                	mov    %eax,%ebx
8010523f:	b8 13 00 00 00       	mov    $0x13,%eax
80105244:	89 d7                	mov    %edx,%edi
80105246:	89 de                	mov    %ebx,%esi
80105248:	89 c1                	mov    %eax,%ecx
8010524a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010524c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010524f:	8b 40 18             	mov    0x18(%eax),%eax
80105252:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80105259:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80105260:	eb 3d                	jmp    8010529f <fork+0x105>
    if(proc->ofile[i])
80105262:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105268:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010526b:	83 c2 08             	add    $0x8,%edx
8010526e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105272:	85 c0                	test   %eax,%eax
80105274:	74 25                	je     8010529b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80105276:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010527c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010527f:	83 c2 08             	add    $0x8,%edx
80105282:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105286:	89 04 24             	mov    %eax,(%esp)
80105289:	e8 ee bc ff ff       	call   80100f7c <filedup>
8010528e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105291:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105294:	83 c1 08             	add    $0x8,%ecx
80105297:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010529b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
8010529f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801052a3:	7e bd                	jle    80105262 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801052a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052ab:	8b 40 68             	mov    0x68(%eax),%eax
801052ae:	89 04 24             	mov    %eax,(%esp)
801052b1:	e8 04 d1 ff ff       	call   801023ba <idup>
801052b6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801052b9:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801052bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052bf:	8b 40 10             	mov    0x10(%eax),%eax
801052c2:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801052c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052c8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801052cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052d5:	8d 50 6c             	lea    0x6c(%eax),%edx
801052d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801052db:	83 c0 6c             	add    $0x6c,%eax
801052de:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801052e5:	00 
801052e6:	89 54 24 04          	mov    %edx,0x4(%esp)
801052ea:	89 04 24             	mov    %eax,(%esp)
801052ed:	e8 d8 0b 00 00       	call   80105eca <safestrcpy>
  return pid;
801052f2:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801052f5:	83 c4 2c             	add    $0x2c,%esp
801052f8:	5b                   	pop    %ebx
801052f9:	5e                   	pop    %esi
801052fa:	5f                   	pop    %edi
801052fb:	5d                   	pop    %ebp
801052fc:	c3                   	ret    

801052fd <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801052fd:	55                   	push   %ebp
801052fe:	89 e5                	mov    %esp,%ebp
80105300:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80105303:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010530a:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010530f:	39 c2                	cmp    %eax,%edx
80105311:	75 0c                	jne    8010531f <exit+0x22>
    panic("init exiting");
80105313:	c7 04 24 94 97 10 80 	movl   $0x80109794,(%esp)
8010531a:	e8 1e b2 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010531f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105326:	eb 44                	jmp    8010536c <exit+0x6f>
    if(proc->ofile[fd]){
80105328:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010532e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105331:	83 c2 08             	add    $0x8,%edx
80105334:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105338:	85 c0                	test   %eax,%eax
8010533a:	74 2c                	je     80105368 <exit+0x6b>
      fileclose(proc->ofile[fd]);
8010533c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105342:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105345:	83 c2 08             	add    $0x8,%edx
80105348:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010534c:	89 04 24             	mov    %eax,(%esp)
8010534f:	e8 70 bc ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80105354:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010535d:	83 c2 08             	add    $0x8,%edx
80105360:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105367:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80105368:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010536c:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80105370:	7e b6                	jle    80105328 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80105372:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105378:	8b 40 68             	mov    0x68(%eax),%eax
8010537b:	89 04 24             	mov    %eax,(%esp)
8010537e:	e8 1c d2 ff ff       	call   8010259f <iput>
  proc->cwd = 0;
80105383:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105389:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80105390:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105397:	e8 af 06 00 00       	call   80105a4b <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
8010539c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053a2:	8b 40 14             	mov    0x14(%eax),%eax
801053a5:	89 04 24             	mov    %eax,(%esp)
801053a8:	e8 5b 04 00 00       	call   80105808 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053ad:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801053b4:	eb 38                	jmp    801053ee <exit+0xf1>
    if(p->parent == proc){
801053b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053b9:	8b 50 14             	mov    0x14(%eax),%edx
801053bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053c2:	39 c2                	cmp    %eax,%edx
801053c4:	75 24                	jne    801053ea <exit+0xed>
      p->parent = initproc;
801053c6:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801053cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053cf:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801053d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053d5:	8b 40 0c             	mov    0xc(%eax),%eax
801053d8:	83 f8 05             	cmp    $0x5,%eax
801053db:	75 0d                	jne    801053ea <exit+0xed>
        wakeup1(initproc);
801053dd:	a1 68 c6 10 80       	mov    0x8010c668,%eax
801053e2:	89 04 24             	mov    %eax,(%esp)
801053e5:	e8 1e 04 00 00       	call   80105808 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801053ea:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801053ee:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801053f5:	72 bf                	jb     801053b6 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801053f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053fd:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105404:	e8 54 02 00 00       	call   8010565d <sched>
  panic("zombie exit");
80105409:	c7 04 24 a1 97 10 80 	movl   $0x801097a1,(%esp)
80105410:	e8 28 b1 ff ff       	call   8010053d <panic>

80105415 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105415:	55                   	push   %ebp
80105416:	89 e5                	mov    %esp,%ebp
80105418:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010541b:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105422:	e8 24 06 00 00       	call   80105a4b <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105427:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010542e:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
80105435:	e9 9a 00 00 00       	jmp    801054d4 <wait+0xbf>
      if(p->parent != proc)
8010543a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010543d:	8b 50 14             	mov    0x14(%eax),%edx
80105440:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105446:	39 c2                	cmp    %eax,%edx
80105448:	0f 85 81 00 00 00    	jne    801054cf <wait+0xba>
        continue;
      havekids = 1;
8010544e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80105455:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105458:	8b 40 0c             	mov    0xc(%eax),%eax
8010545b:	83 f8 05             	cmp    $0x5,%eax
8010545e:	75 70                	jne    801054d0 <wait+0xbb>
        // Found one.
        pid = p->pid;
80105460:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105463:	8b 40 10             	mov    0x10(%eax),%eax
80105466:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80105469:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010546c:	8b 40 08             	mov    0x8(%eax),%eax
8010546f:	89 04 24             	mov    %eax,(%esp)
80105472:	e8 97 e4 ff ff       	call   8010390e <kfree>
        p->kstack = 0;
80105477:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010547a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80105481:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105484:	8b 40 04             	mov    0x4(%eax),%eax
80105487:	89 04 24             	mov    %eax,(%esp)
8010548a:	e8 56 3a 00 00       	call   80108ee5 <freevm>
        p->state = UNUSED;
8010548f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105492:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80105499:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010549c:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801054a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054a6:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801054ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054b0:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801054b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054b7:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801054be:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054c5:	e8 e3 05 00 00       	call   80105aad <release>
        return pid;
801054ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801054cd:	eb 53                	jmp    80105522 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801054cf:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801054d0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801054d4:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801054db:	0f 82 59 ff ff ff    	jb     8010543a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801054e1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801054e5:	74 0d                	je     801054f4 <wait+0xdf>
801054e7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054ed:	8b 40 24             	mov    0x24(%eax),%eax
801054f0:	85 c0                	test   %eax,%eax
801054f2:	74 13                	je     80105507 <wait+0xf2>
      release(&ptable.lock);
801054f4:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801054fb:	e8 ad 05 00 00       	call   80105aad <release>
      return -1;
80105500:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105505:	eb 1b                	jmp    80105522 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105507:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550d:	c7 44 24 04 40 0f 11 	movl   $0x80110f40,0x4(%esp)
80105514:	80 
80105515:	89 04 24             	mov    %eax,(%esp)
80105518:	e8 50 02 00 00       	call   8010576d <sleep>
  }
8010551d:	e9 05 ff ff ff       	jmp    80105427 <wait+0x12>
}
80105522:	c9                   	leave  
80105523:	c3                   	ret    

80105524 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105524:	55                   	push   %ebp
80105525:	89 e5                	mov    %esp,%ebp
80105527:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010552a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105530:	8b 40 18             	mov    0x18(%eax),%eax
80105533:	8b 40 44             	mov    0x44(%eax),%eax
80105536:	89 c2                	mov    %eax,%edx
80105538:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553e:	8b 40 04             	mov    0x4(%eax),%eax
80105541:	89 54 24 04          	mov    %edx,0x4(%esp)
80105545:	89 04 24             	mov    %eax,(%esp)
80105548:	e8 7d 3b 00 00       	call   801090ca <uva2ka>
8010554d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80105550:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105556:	8b 40 18             	mov    0x18(%eax),%eax
80105559:	8b 40 44             	mov    0x44(%eax),%eax
8010555c:	25 ff 0f 00 00       	and    $0xfff,%eax
80105561:	85 c0                	test   %eax,%eax
80105563:	75 0c                	jne    80105571 <register_handler+0x4d>
    panic("esp_offset == 0");
80105565:	c7 04 24 ad 97 10 80 	movl   $0x801097ad,(%esp)
8010556c:	e8 cc af ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80105571:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105577:	8b 40 18             	mov    0x18(%eax),%eax
8010557a:	8b 40 44             	mov    0x44(%eax),%eax
8010557d:	83 e8 04             	sub    $0x4,%eax
80105580:	25 ff 0f 00 00       	and    $0xfff,%eax
80105585:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80105588:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010558f:	8b 52 18             	mov    0x18(%edx),%edx
80105592:	8b 52 38             	mov    0x38(%edx),%edx
80105595:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80105597:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010559d:	8b 40 18             	mov    0x18(%eax),%eax
801055a0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801055a7:	8b 52 18             	mov    0x18(%edx),%edx
801055aa:	8b 52 44             	mov    0x44(%edx),%edx
801055ad:	83 ea 04             	sub    $0x4,%edx
801055b0:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801055b3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055b9:	8b 40 18             	mov    0x18(%eax),%eax
801055bc:	8b 55 08             	mov    0x8(%ebp),%edx
801055bf:	89 50 38             	mov    %edx,0x38(%eax)
}
801055c2:	c9                   	leave  
801055c3:	c3                   	ret    

801055c4 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801055c4:	55                   	push   %ebp
801055c5:	89 e5                	mov    %esp,%ebp
801055c7:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801055ca:	e8 de f8 ff ff       	call   80104ead <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801055cf:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801055d6:	e8 70 04 00 00       	call   80105a4b <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801055db:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
801055e2:	eb 5f                	jmp    80105643 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801055e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055e7:	8b 40 0c             	mov    0xc(%eax),%eax
801055ea:	83 f8 03             	cmp    $0x3,%eax
801055ed:	75 4f                	jne    8010563e <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801055ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055f2:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801055f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055fb:	89 04 24             	mov    %eax,(%esp)
801055fe:	e8 6b 34 00 00       	call   80108a6e <switchuvm>
      p->state = RUNNING;
80105603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105606:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010560d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105613:	8b 40 1c             	mov    0x1c(%eax),%eax
80105616:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010561d:	83 c2 04             	add    $0x4,%edx
80105620:	89 44 24 04          	mov    %eax,0x4(%esp)
80105624:	89 14 24             	mov    %edx,(%esp)
80105627:	e8 14 09 00 00       	call   80105f40 <swtch>
      switchkvm();
8010562c:	e8 20 34 00 00       	call   80108a51 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80105631:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105638:	00 00 00 00 
8010563c:	eb 01                	jmp    8010563f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010563e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010563f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105643:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
8010564a:	72 98                	jb     801055e4 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010564c:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105653:	e8 55 04 00 00       	call   80105aad <release>

  }
80105658:	e9 6d ff ff ff       	jmp    801055ca <scheduler+0x6>

8010565d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010565d:	55                   	push   %ebp
8010565e:	89 e5                	mov    %esp,%ebp
80105660:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80105663:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010566a:	e8 fa 04 00 00       	call   80105b69 <holding>
8010566f:	85 c0                	test   %eax,%eax
80105671:	75 0c                	jne    8010567f <sched+0x22>
    panic("sched ptable.lock");
80105673:	c7 04 24 bd 97 10 80 	movl   $0x801097bd,(%esp)
8010567a:	e8 be ae ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
8010567f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105685:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010568b:	83 f8 01             	cmp    $0x1,%eax
8010568e:	74 0c                	je     8010569c <sched+0x3f>
    panic("sched locks");
80105690:	c7 04 24 cf 97 10 80 	movl   $0x801097cf,(%esp)
80105697:	e8 a1 ae ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
8010569c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056a2:	8b 40 0c             	mov    0xc(%eax),%eax
801056a5:	83 f8 04             	cmp    $0x4,%eax
801056a8:	75 0c                	jne    801056b6 <sched+0x59>
    panic("sched running");
801056aa:	c7 04 24 db 97 10 80 	movl   $0x801097db,(%esp)
801056b1:	e8 87 ae ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801056b6:	e8 dd f7 ff ff       	call   80104e98 <readeflags>
801056bb:	25 00 02 00 00       	and    $0x200,%eax
801056c0:	85 c0                	test   %eax,%eax
801056c2:	74 0c                	je     801056d0 <sched+0x73>
    panic("sched interruptible");
801056c4:	c7 04 24 e9 97 10 80 	movl   $0x801097e9,(%esp)
801056cb:	e8 6d ae ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801056d0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056d6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801056dc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801056df:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801056e5:	8b 40 04             	mov    0x4(%eax),%eax
801056e8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801056ef:	83 c2 1c             	add    $0x1c,%edx
801056f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801056f6:	89 14 24             	mov    %edx,(%esp)
801056f9:	e8 42 08 00 00       	call   80105f40 <swtch>
  cpu->intena = intena;
801056fe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105704:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105707:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010570d:	c9                   	leave  
8010570e:	c3                   	ret    

8010570f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010570f:	55                   	push   %ebp
80105710:	89 e5                	mov    %esp,%ebp
80105712:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105715:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010571c:	e8 2a 03 00 00       	call   80105a4b <acquire>
  proc->state = RUNNABLE;
80105721:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105727:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010572e:	e8 2a ff ff ff       	call   8010565d <sched>
  release(&ptable.lock);
80105733:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010573a:	e8 6e 03 00 00       	call   80105aad <release>
}
8010573f:	c9                   	leave  
80105740:	c3                   	ret    

80105741 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105741:	55                   	push   %ebp
80105742:	89 e5                	mov    %esp,%ebp
80105744:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105747:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010574e:	e8 5a 03 00 00       	call   80105aad <release>

  if (first) {
80105753:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105758:	85 c0                	test   %eax,%eax
8010575a:	74 0f                	je     8010576b <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010575c:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105763:	00 00 00 
    initlog();
80105766:	e8 4d e7 ff ff       	call   80103eb8 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010576b:	c9                   	leave  
8010576c:	c3                   	ret    

8010576d <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
8010576d:	55                   	push   %ebp
8010576e:	89 e5                	mov    %esp,%ebp
80105770:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105773:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105779:	85 c0                	test   %eax,%eax
8010577b:	75 0c                	jne    80105789 <sleep+0x1c>
    panic("sleep");
8010577d:	c7 04 24 fd 97 10 80 	movl   $0x801097fd,(%esp)
80105784:	e8 b4 ad ff ff       	call   8010053d <panic>

  if(lk == 0)
80105789:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010578d:	75 0c                	jne    8010579b <sleep+0x2e>
    panic("sleep without lk");
8010578f:	c7 04 24 03 98 10 80 	movl   $0x80109803,(%esp)
80105796:	e8 a2 ad ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010579b:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801057a2:	74 17                	je     801057bb <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801057a4:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801057ab:	e8 9b 02 00 00       	call   80105a4b <acquire>
    release(lk);
801057b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801057b3:	89 04 24             	mov    %eax,(%esp)
801057b6:	e8 f2 02 00 00       	call   80105aad <release>
  }

  // Go to sleep.
  proc->chan = chan;
801057bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057c1:	8b 55 08             	mov    0x8(%ebp),%edx
801057c4:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801057c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057cd:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801057d4:	e8 84 fe ff ff       	call   8010565d <sched>

  // Tidy up.
  proc->chan = 0;
801057d9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057df:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801057e6:	81 7d 0c 40 0f 11 80 	cmpl   $0x80110f40,0xc(%ebp)
801057ed:	74 17                	je     80105806 <sleep+0x99>
    release(&ptable.lock);
801057ef:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801057f6:	e8 b2 02 00 00       	call   80105aad <release>
    acquire(lk);
801057fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801057fe:	89 04 24             	mov    %eax,(%esp)
80105801:	e8 45 02 00 00       	call   80105a4b <acquire>
  }
}
80105806:	c9                   	leave  
80105807:	c3                   	ret    

80105808 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105808:	55                   	push   %ebp
80105809:	89 e5                	mov    %esp,%ebp
8010580b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010580e:	c7 45 fc 74 0f 11 80 	movl   $0x80110f74,-0x4(%ebp)
80105815:	eb 24                	jmp    8010583b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105817:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010581a:	8b 40 0c             	mov    0xc(%eax),%eax
8010581d:	83 f8 02             	cmp    $0x2,%eax
80105820:	75 15                	jne    80105837 <wakeup1+0x2f>
80105822:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105825:	8b 40 20             	mov    0x20(%eax),%eax
80105828:	3b 45 08             	cmp    0x8(%ebp),%eax
8010582b:	75 0a                	jne    80105837 <wakeup1+0x2f>
      p->state = RUNNABLE;
8010582d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105830:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105837:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
8010583b:	81 7d fc 74 2e 11 80 	cmpl   $0x80112e74,-0x4(%ebp)
80105842:	72 d3                	jb     80105817 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105844:	c9                   	leave  
80105845:	c3                   	ret    

80105846 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105846:	55                   	push   %ebp
80105847:	89 e5                	mov    %esp,%ebp
80105849:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010584c:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
80105853:	e8 f3 01 00 00       	call   80105a4b <acquire>
  wakeup1(chan);
80105858:	8b 45 08             	mov    0x8(%ebp),%eax
8010585b:	89 04 24             	mov    %eax,(%esp)
8010585e:	e8 a5 ff ff ff       	call   80105808 <wakeup1>
  release(&ptable.lock);
80105863:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010586a:	e8 3e 02 00 00       	call   80105aad <release>
}
8010586f:	c9                   	leave  
80105870:	c3                   	ret    

80105871 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105871:	55                   	push   %ebp
80105872:	89 e5                	mov    %esp,%ebp
80105874:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105877:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
8010587e:	e8 c8 01 00 00       	call   80105a4b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105883:	c7 45 f4 74 0f 11 80 	movl   $0x80110f74,-0xc(%ebp)
8010588a:	eb 41                	jmp    801058cd <kill+0x5c>
    if(p->pid == pid){
8010588c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010588f:	8b 40 10             	mov    0x10(%eax),%eax
80105892:	3b 45 08             	cmp    0x8(%ebp),%eax
80105895:	75 32                	jne    801058c9 <kill+0x58>
      p->killed = 1;
80105897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801058a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a4:	8b 40 0c             	mov    0xc(%eax),%eax
801058a7:	83 f8 02             	cmp    $0x2,%eax
801058aa:	75 0a                	jne    801058b6 <kill+0x45>
        p->state = RUNNABLE;
801058ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058af:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
801058b6:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801058bd:	e8 eb 01 00 00       	call   80105aad <release>
      return 0;
801058c2:	b8 00 00 00 00       	mov    $0x0,%eax
801058c7:	eb 1e                	jmp    801058e7 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058c9:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801058cd:	81 7d f4 74 2e 11 80 	cmpl   $0x80112e74,-0xc(%ebp)
801058d4:	72 b6                	jb     8010588c <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801058d6:	c7 04 24 40 0f 11 80 	movl   $0x80110f40,(%esp)
801058dd:	e8 cb 01 00 00       	call   80105aad <release>
  return -1;
801058e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801058e7:	c9                   	leave  
801058e8:	c3                   	ret    

801058e9 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801058e9:	55                   	push   %ebp
801058ea:	89 e5                	mov    %esp,%ebp
801058ec:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801058ef:	c7 45 f0 74 0f 11 80 	movl   $0x80110f74,-0x10(%ebp)
801058f6:	e9 d8 00 00 00       	jmp    801059d3 <procdump+0xea>
    if(p->state == UNUSED)
801058fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058fe:	8b 40 0c             	mov    0xc(%eax),%eax
80105901:	85 c0                	test   %eax,%eax
80105903:	0f 84 c5 00 00 00    	je     801059ce <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105909:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010590c:	8b 40 0c             	mov    0xc(%eax),%eax
8010590f:	83 f8 05             	cmp    $0x5,%eax
80105912:	77 23                	ja     80105937 <procdump+0x4e>
80105914:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105917:	8b 40 0c             	mov    0xc(%eax),%eax
8010591a:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105921:	85 c0                	test   %eax,%eax
80105923:	74 12                	je     80105937 <procdump+0x4e>
      state = states[p->state];
80105925:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105928:	8b 40 0c             	mov    0xc(%eax),%eax
8010592b:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105932:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105935:	eb 07                	jmp    8010593e <procdump+0x55>
    else
      state = "???";
80105937:	c7 45 ec 14 98 10 80 	movl   $0x80109814,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010593e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105941:	8d 50 6c             	lea    0x6c(%eax),%edx
80105944:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105947:	8b 40 10             	mov    0x10(%eax),%eax
8010594a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010594e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105951:	89 54 24 08          	mov    %edx,0x8(%esp)
80105955:	89 44 24 04          	mov    %eax,0x4(%esp)
80105959:	c7 04 24 18 98 10 80 	movl   $0x80109818,(%esp)
80105960:	e8 3c aa ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105965:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105968:	8b 40 0c             	mov    0xc(%eax),%eax
8010596b:	83 f8 02             	cmp    $0x2,%eax
8010596e:	75 50                	jne    801059c0 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105970:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105973:	8b 40 1c             	mov    0x1c(%eax),%eax
80105976:	8b 40 0c             	mov    0xc(%eax),%eax
80105979:	83 c0 08             	add    $0x8,%eax
8010597c:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010597f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105983:	89 04 24             	mov    %eax,(%esp)
80105986:	e8 71 01 00 00       	call   80105afc <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
8010598b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105992:	eb 1b                	jmp    801059af <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105994:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105997:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010599b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010599f:	c7 04 24 21 98 10 80 	movl   $0x80109821,(%esp)
801059a6:	e8 f6 a9 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
801059ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801059af:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801059b3:	7f 0b                	jg     801059c0 <procdump+0xd7>
801059b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b8:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
801059bc:	85 c0                	test   %eax,%eax
801059be:	75 d4                	jne    80105994 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801059c0:	c7 04 24 25 98 10 80 	movl   $0x80109825,(%esp)
801059c7:	e8 d5 a9 ff ff       	call   801003a1 <cprintf>
801059cc:	eb 01                	jmp    801059cf <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
801059ce:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801059cf:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801059d3:	81 7d f0 74 2e 11 80 	cmpl   $0x80112e74,-0x10(%ebp)
801059da:	0f 82 1b ff ff ff    	jb     801058fb <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801059e0:	c9                   	leave  
801059e1:	c3                   	ret    
	...

801059e4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801059e4:	55                   	push   %ebp
801059e5:	89 e5                	mov    %esp,%ebp
801059e7:	53                   	push   %ebx
801059e8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801059eb:	9c                   	pushf  
801059ec:	5b                   	pop    %ebx
801059ed:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801059f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801059f3:	83 c4 10             	add    $0x10,%esp
801059f6:	5b                   	pop    %ebx
801059f7:	5d                   	pop    %ebp
801059f8:	c3                   	ret    

801059f9 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801059f9:	55                   	push   %ebp
801059fa:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801059fc:	fa                   	cli    
}
801059fd:	5d                   	pop    %ebp
801059fe:	c3                   	ret    

801059ff <sti>:

static inline void
sti(void)
{
801059ff:	55                   	push   %ebp
80105a00:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105a02:	fb                   	sti    
}
80105a03:	5d                   	pop    %ebp
80105a04:	c3                   	ret    

80105a05 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105a05:	55                   	push   %ebp
80105a06:	89 e5                	mov    %esp,%ebp
80105a08:	53                   	push   %ebx
80105a09:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105a0c:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105a0f:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105a12:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105a15:	89 c3                	mov    %eax,%ebx
80105a17:	89 d8                	mov    %ebx,%eax
80105a19:	f0 87 02             	lock xchg %eax,(%edx)
80105a1c:	89 c3                	mov    %eax,%ebx
80105a1e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105a21:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105a24:	83 c4 10             	add    $0x10,%esp
80105a27:	5b                   	pop    %ebx
80105a28:	5d                   	pop    %ebp
80105a29:	c3                   	ret    

80105a2a <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105a2a:	55                   	push   %ebp
80105a2b:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105a2d:	8b 45 08             	mov    0x8(%ebp),%eax
80105a30:	8b 55 0c             	mov    0xc(%ebp),%edx
80105a33:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105a36:	8b 45 08             	mov    0x8(%ebp),%eax
80105a39:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a42:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105a49:	5d                   	pop    %ebp
80105a4a:	c3                   	ret    

80105a4b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105a4b:	55                   	push   %ebp
80105a4c:	89 e5                	mov    %esp,%ebp
80105a4e:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105a51:	e8 3d 01 00 00       	call   80105b93 <pushcli>
  if(holding(lk))
80105a56:	8b 45 08             	mov    0x8(%ebp),%eax
80105a59:	89 04 24             	mov    %eax,(%esp)
80105a5c:	e8 08 01 00 00       	call   80105b69 <holding>
80105a61:	85 c0                	test   %eax,%eax
80105a63:	74 0c                	je     80105a71 <acquire+0x26>
    panic("acquire");
80105a65:	c7 04 24 51 98 10 80 	movl   $0x80109851,(%esp)
80105a6c:	e8 cc aa ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105a71:	90                   	nop
80105a72:	8b 45 08             	mov    0x8(%ebp),%eax
80105a75:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105a7c:	00 
80105a7d:	89 04 24             	mov    %eax,(%esp)
80105a80:	e8 80 ff ff ff       	call   80105a05 <xchg>
80105a85:	85 c0                	test   %eax,%eax
80105a87:	75 e9                	jne    80105a72 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105a89:	8b 45 08             	mov    0x8(%ebp),%eax
80105a8c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105a93:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105a96:	8b 45 08             	mov    0x8(%ebp),%eax
80105a99:	83 c0 0c             	add    $0xc,%eax
80105a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aa0:	8d 45 08             	lea    0x8(%ebp),%eax
80105aa3:	89 04 24             	mov    %eax,(%esp)
80105aa6:	e8 51 00 00 00       	call   80105afc <getcallerpcs>
}
80105aab:	c9                   	leave  
80105aac:	c3                   	ret    

80105aad <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105aad:	55                   	push   %ebp
80105aae:	89 e5                	mov    %esp,%ebp
80105ab0:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80105ab6:	89 04 24             	mov    %eax,(%esp)
80105ab9:	e8 ab 00 00 00       	call   80105b69 <holding>
80105abe:	85 c0                	test   %eax,%eax
80105ac0:	75 0c                	jne    80105ace <release+0x21>
    panic("release");
80105ac2:	c7 04 24 59 98 10 80 	movl   $0x80109859,(%esp)
80105ac9:	e8 6f aa ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105ace:	8b 45 08             	mov    0x8(%ebp),%eax
80105ad1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80105adb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105ae2:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105aec:	00 
80105aed:	89 04 24             	mov    %eax,(%esp)
80105af0:	e8 10 ff ff ff       	call   80105a05 <xchg>

  popcli();
80105af5:	e8 e1 00 00 00       	call   80105bdb <popcli>
}
80105afa:	c9                   	leave  
80105afb:	c3                   	ret    

80105afc <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105afc:	55                   	push   %ebp
80105afd:	89 e5                	mov    %esp,%ebp
80105aff:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105b02:	8b 45 08             	mov    0x8(%ebp),%eax
80105b05:	83 e8 08             	sub    $0x8,%eax
80105b08:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105b0b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105b12:	eb 32                	jmp    80105b46 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105b14:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105b18:	74 47                	je     80105b61 <getcallerpcs+0x65>
80105b1a:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105b21:	76 3e                	jbe    80105b61 <getcallerpcs+0x65>
80105b23:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105b27:	74 38                	je     80105b61 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105b29:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b2c:	c1 e0 02             	shl    $0x2,%eax
80105b2f:	03 45 0c             	add    0xc(%ebp),%eax
80105b32:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105b35:	8b 52 04             	mov    0x4(%edx),%edx
80105b38:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105b3a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b3d:	8b 00                	mov    (%eax),%eax
80105b3f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105b42:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b46:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b4a:	7e c8                	jle    80105b14 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b4c:	eb 13                	jmp    80105b61 <getcallerpcs+0x65>
    pcs[i] = 0;
80105b4e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105b51:	c1 e0 02             	shl    $0x2,%eax
80105b54:	03 45 0c             	add    0xc(%ebp),%eax
80105b57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105b5d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105b61:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105b65:	7e e7                	jle    80105b4e <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105b67:	c9                   	leave  
80105b68:	c3                   	ret    

80105b69 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105b69:	55                   	push   %ebp
80105b6a:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105b6c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b6f:	8b 00                	mov    (%eax),%eax
80105b71:	85 c0                	test   %eax,%eax
80105b73:	74 17                	je     80105b8c <holding+0x23>
80105b75:	8b 45 08             	mov    0x8(%ebp),%eax
80105b78:	8b 50 08             	mov    0x8(%eax),%edx
80105b7b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105b81:	39 c2                	cmp    %eax,%edx
80105b83:	75 07                	jne    80105b8c <holding+0x23>
80105b85:	b8 01 00 00 00       	mov    $0x1,%eax
80105b8a:	eb 05                	jmp    80105b91 <holding+0x28>
80105b8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105b91:	5d                   	pop    %ebp
80105b92:	c3                   	ret    

80105b93 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105b93:	55                   	push   %ebp
80105b94:	89 e5                	mov    %esp,%ebp
80105b96:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105b99:	e8 46 fe ff ff       	call   801059e4 <readeflags>
80105b9e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105ba1:	e8 53 fe ff ff       	call   801059f9 <cli>
  if(cpu->ncli++ == 0)
80105ba6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105bac:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105bb2:	85 d2                	test   %edx,%edx
80105bb4:	0f 94 c1             	sete   %cl
80105bb7:	83 c2 01             	add    $0x1,%edx
80105bba:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105bc0:	84 c9                	test   %cl,%cl
80105bc2:	74 15                	je     80105bd9 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105bc4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105bca:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105bcd:	81 e2 00 02 00 00    	and    $0x200,%edx
80105bd3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105bd9:	c9                   	leave  
80105bda:	c3                   	ret    

80105bdb <popcli>:

void
popcli(void)
{
80105bdb:	55                   	push   %ebp
80105bdc:	89 e5                	mov    %esp,%ebp
80105bde:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105be1:	e8 fe fd ff ff       	call   801059e4 <readeflags>
80105be6:	25 00 02 00 00       	and    $0x200,%eax
80105beb:	85 c0                	test   %eax,%eax
80105bed:	74 0c                	je     80105bfb <popcli+0x20>
    panic("popcli - interruptible");
80105bef:	c7 04 24 61 98 10 80 	movl   $0x80109861,(%esp)
80105bf6:	e8 42 a9 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105bfb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c01:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105c07:	83 ea 01             	sub    $0x1,%edx
80105c0a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105c10:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c16:	85 c0                	test   %eax,%eax
80105c18:	79 0c                	jns    80105c26 <popcli+0x4b>
    panic("popcli");
80105c1a:	c7 04 24 78 98 10 80 	movl   $0x80109878,(%esp)
80105c21:	e8 17 a9 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105c26:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c2c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105c32:	85 c0                	test   %eax,%eax
80105c34:	75 15                	jne    80105c4b <popcli+0x70>
80105c36:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c3c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105c42:	85 c0                	test   %eax,%eax
80105c44:	74 05                	je     80105c4b <popcli+0x70>
    sti();
80105c46:	e8 b4 fd ff ff       	call   801059ff <sti>
}
80105c4b:	c9                   	leave  
80105c4c:	c3                   	ret    
80105c4d:	00 00                	add    %al,(%eax)
	...

80105c50 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105c50:	55                   	push   %ebp
80105c51:	89 e5                	mov    %esp,%ebp
80105c53:	57                   	push   %edi
80105c54:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105c55:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c58:	8b 55 10             	mov    0x10(%ebp),%edx
80105c5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c5e:	89 cb                	mov    %ecx,%ebx
80105c60:	89 df                	mov    %ebx,%edi
80105c62:	89 d1                	mov    %edx,%ecx
80105c64:	fc                   	cld    
80105c65:	f3 aa                	rep stos %al,%es:(%edi)
80105c67:	89 ca                	mov    %ecx,%edx
80105c69:	89 fb                	mov    %edi,%ebx
80105c6b:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c6e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c71:	5b                   	pop    %ebx
80105c72:	5f                   	pop    %edi
80105c73:	5d                   	pop    %ebp
80105c74:	c3                   	ret    

80105c75 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105c75:	55                   	push   %ebp
80105c76:	89 e5                	mov    %esp,%ebp
80105c78:	57                   	push   %edi
80105c79:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105c7a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105c7d:	8b 55 10             	mov    0x10(%ebp),%edx
80105c80:	8b 45 0c             	mov    0xc(%ebp),%eax
80105c83:	89 cb                	mov    %ecx,%ebx
80105c85:	89 df                	mov    %ebx,%edi
80105c87:	89 d1                	mov    %edx,%ecx
80105c89:	fc                   	cld    
80105c8a:	f3 ab                	rep stos %eax,%es:(%edi)
80105c8c:	89 ca                	mov    %ecx,%edx
80105c8e:	89 fb                	mov    %edi,%ebx
80105c90:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105c93:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105c96:	5b                   	pop    %ebx
80105c97:	5f                   	pop    %edi
80105c98:	5d                   	pop    %ebp
80105c99:	c3                   	ret    

80105c9a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105c9a:	55                   	push   %ebp
80105c9b:	89 e5                	mov    %esp,%ebp
80105c9d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105ca0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ca3:	83 e0 03             	and    $0x3,%eax
80105ca6:	85 c0                	test   %eax,%eax
80105ca8:	75 49                	jne    80105cf3 <memset+0x59>
80105caa:	8b 45 10             	mov    0x10(%ebp),%eax
80105cad:	83 e0 03             	and    $0x3,%eax
80105cb0:	85 c0                	test   %eax,%eax
80105cb2:	75 3f                	jne    80105cf3 <memset+0x59>
    c &= 0xFF;
80105cb4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105cbb:	8b 45 10             	mov    0x10(%ebp),%eax
80105cbe:	c1 e8 02             	shr    $0x2,%eax
80105cc1:	89 c2                	mov    %eax,%edx
80105cc3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cc6:	89 c1                	mov    %eax,%ecx
80105cc8:	c1 e1 18             	shl    $0x18,%ecx
80105ccb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cce:	c1 e0 10             	shl    $0x10,%eax
80105cd1:	09 c1                	or     %eax,%ecx
80105cd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cd6:	c1 e0 08             	shl    $0x8,%eax
80105cd9:	09 c8                	or     %ecx,%eax
80105cdb:	0b 45 0c             	or     0xc(%ebp),%eax
80105cde:	89 54 24 08          	mov    %edx,0x8(%esp)
80105ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ce6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ce9:	89 04 24             	mov    %eax,(%esp)
80105cec:	e8 84 ff ff ff       	call   80105c75 <stosl>
80105cf1:	eb 19                	jmp    80105d0c <memset+0x72>
  } else
    stosb(dst, c, n);
80105cf3:	8b 45 10             	mov    0x10(%ebp),%eax
80105cf6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d01:	8b 45 08             	mov    0x8(%ebp),%eax
80105d04:	89 04 24             	mov    %eax,(%esp)
80105d07:	e8 44 ff ff ff       	call   80105c50 <stosb>
  return dst;
80105d0c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105d0f:	c9                   	leave  
80105d10:	c3                   	ret    

80105d11 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105d11:	55                   	push   %ebp
80105d12:	89 e5                	mov    %esp,%ebp
80105d14:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105d17:	8b 45 08             	mov    0x8(%ebp),%eax
80105d1a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d20:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105d23:	eb 32                	jmp    80105d57 <memcmp+0x46>
    if(*s1 != *s2)
80105d25:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d28:	0f b6 10             	movzbl (%eax),%edx
80105d2b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d2e:	0f b6 00             	movzbl (%eax),%eax
80105d31:	38 c2                	cmp    %al,%dl
80105d33:	74 1a                	je     80105d4f <memcmp+0x3e>
      return *s1 - *s2;
80105d35:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d38:	0f b6 00             	movzbl (%eax),%eax
80105d3b:	0f b6 d0             	movzbl %al,%edx
80105d3e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105d41:	0f b6 00             	movzbl (%eax),%eax
80105d44:	0f b6 c0             	movzbl %al,%eax
80105d47:	89 d1                	mov    %edx,%ecx
80105d49:	29 c1                	sub    %eax,%ecx
80105d4b:	89 c8                	mov    %ecx,%eax
80105d4d:	eb 1c                	jmp    80105d6b <memcmp+0x5a>
    s1++, s2++;
80105d4f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105d53:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105d57:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105d5b:	0f 95 c0             	setne  %al
80105d5e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105d62:	84 c0                	test   %al,%al
80105d64:	75 bf                	jne    80105d25 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105d66:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105d6b:	c9                   	leave  
80105d6c:	c3                   	ret    

80105d6d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105d6d:	55                   	push   %ebp
80105d6e:	89 e5                	mov    %esp,%ebp
80105d70:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105d73:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d76:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105d79:	8b 45 08             	mov    0x8(%ebp),%eax
80105d7c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105d7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105d82:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d85:	73 54                	jae    80105ddb <memmove+0x6e>
80105d87:	8b 45 10             	mov    0x10(%ebp),%eax
80105d8a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105d8d:	01 d0                	add    %edx,%eax
80105d8f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105d92:	76 47                	jbe    80105ddb <memmove+0x6e>
    s += n;
80105d94:	8b 45 10             	mov    0x10(%ebp),%eax
80105d97:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105d9a:	8b 45 10             	mov    0x10(%ebp),%eax
80105d9d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105da0:	eb 13                	jmp    80105db5 <memmove+0x48>
      *--d = *--s;
80105da2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105da6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105daa:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dad:	0f b6 10             	movzbl (%eax),%edx
80105db0:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105db3:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105db5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105db9:	0f 95 c0             	setne  %al
80105dbc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105dc0:	84 c0                	test   %al,%al
80105dc2:	75 de                	jne    80105da2 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105dc4:	eb 25                	jmp    80105deb <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105dc6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dc9:	0f b6 10             	movzbl (%eax),%edx
80105dcc:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dcf:	88 10                	mov    %dl,(%eax)
80105dd1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105dd5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105dd9:	eb 01                	jmp    80105ddc <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105ddb:	90                   	nop
80105ddc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105de0:	0f 95 c0             	setne  %al
80105de3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105de7:	84 c0                	test   %al,%al
80105de9:	75 db                	jne    80105dc6 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105deb:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105dee:	c9                   	leave  
80105def:	c3                   	ret    

80105df0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105df0:	55                   	push   %ebp
80105df1:	89 e5                	mov    %esp,%ebp
80105df3:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105df6:	8b 45 10             	mov    0x10(%ebp),%eax
80105df9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105dfd:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e00:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e04:	8b 45 08             	mov    0x8(%ebp),%eax
80105e07:	89 04 24             	mov    %eax,(%esp)
80105e0a:	e8 5e ff ff ff       	call   80105d6d <memmove>
}
80105e0f:	c9                   	leave  
80105e10:	c3                   	ret    

80105e11 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105e11:	55                   	push   %ebp
80105e12:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105e14:	eb 0c                	jmp    80105e22 <strncmp+0x11>
    n--, p++, q++;
80105e16:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105e1a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105e1e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105e22:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e26:	74 1a                	je     80105e42 <strncmp+0x31>
80105e28:	8b 45 08             	mov    0x8(%ebp),%eax
80105e2b:	0f b6 00             	movzbl (%eax),%eax
80105e2e:	84 c0                	test   %al,%al
80105e30:	74 10                	je     80105e42 <strncmp+0x31>
80105e32:	8b 45 08             	mov    0x8(%ebp),%eax
80105e35:	0f b6 10             	movzbl (%eax),%edx
80105e38:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e3b:	0f b6 00             	movzbl (%eax),%eax
80105e3e:	38 c2                	cmp    %al,%dl
80105e40:	74 d4                	je     80105e16 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105e42:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e46:	75 07                	jne    80105e4f <strncmp+0x3e>
    return 0;
80105e48:	b8 00 00 00 00       	mov    $0x0,%eax
80105e4d:	eb 18                	jmp    80105e67 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105e4f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e52:	0f b6 00             	movzbl (%eax),%eax
80105e55:	0f b6 d0             	movzbl %al,%edx
80105e58:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e5b:	0f b6 00             	movzbl (%eax),%eax
80105e5e:	0f b6 c0             	movzbl %al,%eax
80105e61:	89 d1                	mov    %edx,%ecx
80105e63:	29 c1                	sub    %eax,%ecx
80105e65:	89 c8                	mov    %ecx,%eax
}
80105e67:	5d                   	pop    %ebp
80105e68:	c3                   	ret    

80105e69 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105e69:	55                   	push   %ebp
80105e6a:	89 e5                	mov    %esp,%ebp
80105e6c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105e6f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e72:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105e75:	90                   	nop
80105e76:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105e7a:	0f 9f c0             	setg   %al
80105e7d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105e81:	84 c0                	test   %al,%al
80105e83:	74 30                	je     80105eb5 <strncpy+0x4c>
80105e85:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e88:	0f b6 10             	movzbl (%eax),%edx
80105e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80105e8e:	88 10                	mov    %dl,(%eax)
80105e90:	8b 45 08             	mov    0x8(%ebp),%eax
80105e93:	0f b6 00             	movzbl (%eax),%eax
80105e96:	84 c0                	test   %al,%al
80105e98:	0f 95 c0             	setne  %al
80105e9b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105e9f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105ea3:	84 c0                	test   %al,%al
80105ea5:	75 cf                	jne    80105e76 <strncpy+0xd>
    ;
  while(n-- > 0)
80105ea7:	eb 0c                	jmp    80105eb5 <strncpy+0x4c>
    *s++ = 0;
80105ea9:	8b 45 08             	mov    0x8(%ebp),%eax
80105eac:	c6 00 00             	movb   $0x0,(%eax)
80105eaf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105eb3:	eb 01                	jmp    80105eb6 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105eb5:	90                   	nop
80105eb6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eba:	0f 9f c0             	setg   %al
80105ebd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ec1:	84 c0                	test   %al,%al
80105ec3:	75 e4                	jne    80105ea9 <strncpy+0x40>
    *s++ = 0;
  return os;
80105ec5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ec8:	c9                   	leave  
80105ec9:	c3                   	ret    

80105eca <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105eca:	55                   	push   %ebp
80105ecb:	89 e5                	mov    %esp,%ebp
80105ecd:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ed0:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105ed6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eda:	7f 05                	jg     80105ee1 <safestrcpy+0x17>
    return os;
80105edc:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105edf:	eb 35                	jmp    80105f16 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
80105ee1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ee5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ee9:	7e 22                	jle    80105f0d <safestrcpy+0x43>
80105eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105eee:	0f b6 10             	movzbl (%eax),%edx
80105ef1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ef4:	88 10                	mov    %dl,(%eax)
80105ef6:	8b 45 08             	mov    0x8(%ebp),%eax
80105ef9:	0f b6 00             	movzbl (%eax),%eax
80105efc:	84 c0                	test   %al,%al
80105efe:	0f 95 c0             	setne  %al
80105f01:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105f05:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105f09:	84 c0                	test   %al,%al
80105f0b:	75 d4                	jne    80105ee1 <safestrcpy+0x17>
    ;
  *s = 0;
80105f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80105f10:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105f13:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f16:	c9                   	leave  
80105f17:	c3                   	ret    

80105f18 <strlen>:

int
strlen(const char *s)
{
80105f18:	55                   	push   %ebp
80105f19:	89 e5                	mov    %esp,%ebp
80105f1b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105f1e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105f25:	eb 04                	jmp    80105f2b <strlen+0x13>
80105f27:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105f2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f2e:	03 45 08             	add    0x8(%ebp),%eax
80105f31:	0f b6 00             	movzbl (%eax),%eax
80105f34:	84 c0                	test   %al,%al
80105f36:	75 ef                	jne    80105f27 <strlen+0xf>
    ;
  return n;
80105f38:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f3b:	c9                   	leave  
80105f3c:	c3                   	ret    
80105f3d:	00 00                	add    %al,(%eax)
	...

80105f40 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105f40:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105f44:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105f48:	55                   	push   %ebp
  pushl %ebx
80105f49:	53                   	push   %ebx
  pushl %esi
80105f4a:	56                   	push   %esi
  pushl %edi
80105f4b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105f4c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105f4e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105f50:	5f                   	pop    %edi
  popl %esi
80105f51:	5e                   	pop    %esi
  popl %ebx
80105f52:	5b                   	pop    %ebx
  popl %ebp
80105f53:	5d                   	pop    %ebp
  ret
80105f54:	c3                   	ret    
80105f55:	00 00                	add    %al,(%eax)
	...

80105f58 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105f58:	55                   	push   %ebp
80105f59:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
80105f5b:	8b 45 08             	mov    0x8(%ebp),%eax
80105f5e:	8b 00                	mov    (%eax),%eax
80105f60:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105f63:	76 0f                	jbe    80105f74 <fetchint+0x1c>
80105f65:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f68:	8d 50 04             	lea    0x4(%eax),%edx
80105f6b:	8b 45 08             	mov    0x8(%ebp),%eax
80105f6e:	8b 00                	mov    (%eax),%eax
80105f70:	39 c2                	cmp    %eax,%edx
80105f72:	76 07                	jbe    80105f7b <fetchint+0x23>
    return -1;
80105f74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f79:	eb 0f                	jmp    80105f8a <fetchint+0x32>
  *ip = *(int*)(addr);
80105f7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105f7e:	8b 10                	mov    (%eax),%edx
80105f80:	8b 45 10             	mov    0x10(%ebp),%eax
80105f83:	89 10                	mov    %edx,(%eax)
  return 0;
80105f85:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f8a:	5d                   	pop    %ebp
80105f8b:	c3                   	ret    

80105f8c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105f8c:	55                   	push   %ebp
80105f8d:	89 e5                	mov    %esp,%ebp
80105f8f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105f92:	8b 45 08             	mov    0x8(%ebp),%eax
80105f95:	8b 00                	mov    (%eax),%eax
80105f97:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105f9a:	77 07                	ja     80105fa3 <fetchstr+0x17>
    return -1;
80105f9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fa1:	eb 45                	jmp    80105fe8 <fetchstr+0x5c>
  *pp = (char*)addr;
80105fa3:	8b 55 0c             	mov    0xc(%ebp),%edx
80105fa6:	8b 45 10             	mov    0x10(%ebp),%eax
80105fa9:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80105fab:	8b 45 08             	mov    0x8(%ebp),%eax
80105fae:	8b 00                	mov    (%eax),%eax
80105fb0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105fb3:	8b 45 10             	mov    0x10(%ebp),%eax
80105fb6:	8b 00                	mov    (%eax),%eax
80105fb8:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105fbb:	eb 1e                	jmp    80105fdb <fetchstr+0x4f>
    if(*s == 0)
80105fbd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fc0:	0f b6 00             	movzbl (%eax),%eax
80105fc3:	84 c0                	test   %al,%al
80105fc5:	75 10                	jne    80105fd7 <fetchstr+0x4b>
      return s - *pp;
80105fc7:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fca:	8b 45 10             	mov    0x10(%ebp),%eax
80105fcd:	8b 00                	mov    (%eax),%eax
80105fcf:	89 d1                	mov    %edx,%ecx
80105fd1:	29 c1                	sub    %eax,%ecx
80105fd3:	89 c8                	mov    %ecx,%eax
80105fd5:	eb 11                	jmp    80105fe8 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80105fd7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105fdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105fde:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105fe1:	72 da                	jb     80105fbd <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
80105fe3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105fe8:	c9                   	leave  
80105fe9:	c3                   	ret    

80105fea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80105fea:	55                   	push   %ebp
80105feb:	89 e5                	mov    %esp,%ebp
80105fed:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105ff0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ff6:	8b 40 18             	mov    0x18(%eax),%eax
80105ff9:	8b 50 44             	mov    0x44(%eax),%edx
80105ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80105fff:	c1 e0 02             	shl    $0x2,%eax
80106002:	01 d0                	add    %edx,%eax
80106004:	8d 48 04             	lea    0x4(%eax),%ecx
80106007:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010600d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106010:	89 54 24 08          	mov    %edx,0x8(%esp)
80106014:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106018:	89 04 24             	mov    %eax,(%esp)
8010601b:	e8 38 ff ff ff       	call   80105f58 <fetchint>
}
80106020:	c9                   	leave  
80106021:	c3                   	ret    

80106022 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80106022:	55                   	push   %ebp
80106023:	89 e5                	mov    %esp,%ebp
80106025:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106028:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010602b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010602f:	8b 45 08             	mov    0x8(%ebp),%eax
80106032:	89 04 24             	mov    %eax,(%esp)
80106035:	e8 b0 ff ff ff       	call   80105fea <argint>
8010603a:	85 c0                	test   %eax,%eax
8010603c:	79 07                	jns    80106045 <argptr+0x23>
    return -1;
8010603e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106043:	eb 3d                	jmp    80106082 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80106045:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106048:	89 c2                	mov    %eax,%edx
8010604a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106050:	8b 00                	mov    (%eax),%eax
80106052:	39 c2                	cmp    %eax,%edx
80106054:	73 16                	jae    8010606c <argptr+0x4a>
80106056:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106059:	89 c2                	mov    %eax,%edx
8010605b:	8b 45 10             	mov    0x10(%ebp),%eax
8010605e:	01 c2                	add    %eax,%edx
80106060:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106066:	8b 00                	mov    (%eax),%eax
80106068:	39 c2                	cmp    %eax,%edx
8010606a:	76 07                	jbe    80106073 <argptr+0x51>
    return -1;
8010606c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106071:	eb 0f                	jmp    80106082 <argptr+0x60>
  *pp = (char*)i;
80106073:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106076:	89 c2                	mov    %eax,%edx
80106078:	8b 45 0c             	mov    0xc(%ebp),%eax
8010607b:	89 10                	mov    %edx,(%eax)
  return 0;
8010607d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106082:	c9                   	leave  
80106083:	c3                   	ret    

80106084 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80106084:	55                   	push   %ebp
80106085:	89 e5                	mov    %esp,%ebp
80106087:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010608a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010608d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106091:	8b 45 08             	mov    0x8(%ebp),%eax
80106094:	89 04 24             	mov    %eax,(%esp)
80106097:	e8 4e ff ff ff       	call   80105fea <argint>
8010609c:	85 c0                	test   %eax,%eax
8010609e:	79 07                	jns    801060a7 <argstr+0x23>
    return -1;
801060a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060a5:	eb 1e                	jmp    801060c5 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801060a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060aa:	89 c2                	mov    %eax,%edx
801060ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801060b5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801060b9:	89 54 24 04          	mov    %edx,0x4(%esp)
801060bd:	89 04 24             	mov    %eax,(%esp)
801060c0:	e8 c7 fe ff ff       	call   80105f8c <fetchstr>
}
801060c5:	c9                   	leave  
801060c6:	c3                   	ret    

801060c7 <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
801060c7:	55                   	push   %ebp
801060c8:	89 e5                	mov    %esp,%ebp
801060ca:	53                   	push   %ebx
801060cb:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801060ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060d4:	8b 40 18             	mov    0x18(%eax),%eax
801060d7:	8b 40 1c             	mov    0x1c(%eax),%eax
801060da:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801060dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060e1:	78 2e                	js     80106111 <syscall+0x4a>
801060e3:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801060e7:	7f 28                	jg     80106111 <syscall+0x4a>
801060e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060ec:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
801060f3:	85 c0                	test   %eax,%eax
801060f5:	74 1a                	je     80106111 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801060f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060fd:	8b 58 18             	mov    0x18(%eax),%ebx
80106100:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106103:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010610a:	ff d0                	call   *%eax
8010610c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010610f:	eb 73                	jmp    80106184 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80106111:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106115:	7e 30                	jle    80106147 <syscall+0x80>
80106117:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010611a:	83 f8 19             	cmp    $0x19,%eax
8010611d:	77 28                	ja     80106147 <syscall+0x80>
8010611f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106122:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106129:	85 c0                	test   %eax,%eax
8010612b:	74 1a                	je     80106147 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
8010612d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106133:	8b 58 18             	mov    0x18(%eax),%ebx
80106136:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106139:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106140:	ff d0                	call   *%eax
80106142:	89 43 1c             	mov    %eax,0x1c(%ebx)
80106145:	eb 3d                	jmp    80106184 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106147:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010614d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106150:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80106156:	8b 40 10             	mov    0x10(%eax),%eax
80106159:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010615c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80106160:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106164:	89 44 24 04          	mov    %eax,0x4(%esp)
80106168:	c7 04 24 7f 98 10 80 	movl   $0x8010987f,(%esp)
8010616f:	e8 2d a2 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80106174:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010617a:	8b 40 18             	mov    0x18(%eax),%eax
8010617d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80106184:	83 c4 24             	add    $0x24,%esp
80106187:	5b                   	pop    %ebx
80106188:	5d                   	pop    %ebp
80106189:	c3                   	ret    
	...

8010618c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010618c:	55                   	push   %ebp
8010618d:	89 e5                	mov    %esp,%ebp
8010618f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80106192:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106195:	89 44 24 04          	mov    %eax,0x4(%esp)
80106199:	8b 45 08             	mov    0x8(%ebp),%eax
8010619c:	89 04 24             	mov    %eax,(%esp)
8010619f:	e8 46 fe ff ff       	call   80105fea <argint>
801061a4:	85 c0                	test   %eax,%eax
801061a6:	79 07                	jns    801061af <argfd+0x23>
    return -1;
801061a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ad:	eb 50                	jmp    801061ff <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801061af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b2:	85 c0                	test   %eax,%eax
801061b4:	78 21                	js     801061d7 <argfd+0x4b>
801061b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061b9:	83 f8 0f             	cmp    $0xf,%eax
801061bc:	7f 19                	jg     801061d7 <argfd+0x4b>
801061be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061c7:	83 c2 08             	add    $0x8,%edx
801061ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801061ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
801061d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801061d5:	75 07                	jne    801061de <argfd+0x52>
    return -1;
801061d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061dc:	eb 21                	jmp    801061ff <argfd+0x73>
  if(pfd)
801061de:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801061e2:	74 08                	je     801061ec <argfd+0x60>
    *pfd = fd;
801061e4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061e7:	8b 45 0c             	mov    0xc(%ebp),%eax
801061ea:	89 10                	mov    %edx,(%eax)
  if(pf)
801061ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061f0:	74 08                	je     801061fa <argfd+0x6e>
    *pf = f;
801061f2:	8b 45 10             	mov    0x10(%ebp),%eax
801061f5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061f8:	89 10                	mov    %edx,(%eax)
  return 0;
801061fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061ff:	c9                   	leave  
80106200:	c3                   	ret    

80106201 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106201:	55                   	push   %ebp
80106202:	89 e5                	mov    %esp,%ebp
80106204:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106207:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010620e:	eb 30                	jmp    80106240 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106210:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106216:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106219:	83 c2 08             	add    $0x8,%edx
8010621c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106220:	85 c0                	test   %eax,%eax
80106222:	75 18                	jne    8010623c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106224:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010622a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010622d:	8d 4a 08             	lea    0x8(%edx),%ecx
80106230:	8b 55 08             	mov    0x8(%ebp),%edx
80106233:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106237:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010623a:	eb 0f                	jmp    8010624b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010623c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106240:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80106244:	7e ca                	jle    80106210 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80106246:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010624b:	c9                   	leave  
8010624c:	c3                   	ret    

8010624d <sys_dup>:

int
sys_dup(void)
{
8010624d:	55                   	push   %ebp
8010624e:	89 e5                	mov    %esp,%ebp
80106250:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80106253:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106256:	89 44 24 08          	mov    %eax,0x8(%esp)
8010625a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106261:	00 
80106262:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106269:	e8 1e ff ff ff       	call   8010618c <argfd>
8010626e:	85 c0                	test   %eax,%eax
80106270:	79 07                	jns    80106279 <sys_dup+0x2c>
    return -1;
80106272:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106277:	eb 29                	jmp    801062a2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80106279:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010627c:	89 04 24             	mov    %eax,(%esp)
8010627f:	e8 7d ff ff ff       	call   80106201 <fdalloc>
80106284:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106287:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010628b:	79 07                	jns    80106294 <sys_dup+0x47>
    return -1;
8010628d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106292:	eb 0e                	jmp    801062a2 <sys_dup+0x55>
  filedup(f);
80106294:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106297:	89 04 24             	mov    %eax,(%esp)
8010629a:	e8 dd ac ff ff       	call   80100f7c <filedup>
  return fd;
8010629f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801062a2:	c9                   	leave  
801062a3:	c3                   	ret    

801062a4 <sys_read>:

int
sys_read(void)
{
801062a4:	55                   	push   %ebp
801062a5:	89 e5                	mov    %esp,%ebp
801062a7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801062aa:	8d 45 f4             	lea    -0xc(%ebp),%eax
801062ad:	89 44 24 08          	mov    %eax,0x8(%esp)
801062b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062b8:	00 
801062b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062c0:	e8 c7 fe ff ff       	call   8010618c <argfd>
801062c5:	85 c0                	test   %eax,%eax
801062c7:	78 35                	js     801062fe <sys_read+0x5a>
801062c9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801062cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801062d0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801062d7:	e8 0e fd ff ff       	call   80105fea <argint>
801062dc:	85 c0                	test   %eax,%eax
801062de:	78 1e                	js     801062fe <sys_read+0x5a>
801062e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062e3:	89 44 24 08          	mov    %eax,0x8(%esp)
801062e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801062ee:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062f5:	e8 28 fd ff ff       	call   80106022 <argptr>
801062fa:	85 c0                	test   %eax,%eax
801062fc:	79 07                	jns    80106305 <sys_read+0x61>
    return -1;
801062fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106303:	eb 19                	jmp    8010631e <sys_read+0x7a>
  return fileread(f, p, n);
80106305:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106308:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010630b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010630e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106312:	89 54 24 04          	mov    %edx,0x4(%esp)
80106316:	89 04 24             	mov    %eax,(%esp)
80106319:	e8 cb ad ff ff       	call   801010e9 <fileread>
}
8010631e:	c9                   	leave  
8010631f:	c3                   	ret    

80106320 <sys_write>:

int
sys_write(void)
{
80106320:	55                   	push   %ebp
80106321:	89 e5                	mov    %esp,%ebp
80106323:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106326:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106329:	89 44 24 08          	mov    %eax,0x8(%esp)
8010632d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106334:	00 
80106335:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010633c:	e8 4b fe ff ff       	call   8010618c <argfd>
80106341:	85 c0                	test   %eax,%eax
80106343:	78 35                	js     8010637a <sys_write+0x5a>
80106345:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106348:	89 44 24 04          	mov    %eax,0x4(%esp)
8010634c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106353:	e8 92 fc ff ff       	call   80105fea <argint>
80106358:	85 c0                	test   %eax,%eax
8010635a:	78 1e                	js     8010637a <sys_write+0x5a>
8010635c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010635f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106363:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106366:	89 44 24 04          	mov    %eax,0x4(%esp)
8010636a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106371:	e8 ac fc ff ff       	call   80106022 <argptr>
80106376:	85 c0                	test   %eax,%eax
80106378:	79 07                	jns    80106381 <sys_write+0x61>
    return -1;
8010637a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010637f:	eb 19                	jmp    8010639a <sys_write+0x7a>
  return filewrite(f, p, n);
80106381:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106384:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010638a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010638e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106392:	89 04 24             	mov    %eax,(%esp)
80106395:	e8 0b ae ff ff       	call   801011a5 <filewrite>
}
8010639a:	c9                   	leave  
8010639b:	c3                   	ret    

8010639c <sys_close>:

int
sys_close(void)
{
8010639c:	55                   	push   %ebp
8010639d:	89 e5                	mov    %esp,%ebp
8010639f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801063a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801063a5:	89 44 24 08          	mov    %eax,0x8(%esp)
801063a9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801063b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063b7:	e8 d0 fd ff ff       	call   8010618c <argfd>
801063bc:	85 c0                	test   %eax,%eax
801063be:	79 07                	jns    801063c7 <sys_close+0x2b>
    return -1;
801063c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063c5:	eb 24                	jmp    801063eb <sys_close+0x4f>
  proc->ofile[fd] = 0;
801063c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063d0:	83 c2 08             	add    $0x8,%edx
801063d3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801063da:	00 
  fileclose(f);
801063db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063de:	89 04 24             	mov    %eax,(%esp)
801063e1:	e8 de ab ff ff       	call   80100fc4 <fileclose>
  return 0;
801063e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063eb:	c9                   	leave  
801063ec:	c3                   	ret    

801063ed <sys_fstat>:

int
sys_fstat(void)
{
801063ed:	55                   	push   %ebp
801063ee:	89 e5                	mov    %esp,%ebp
801063f0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801063f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801063fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106401:	00 
80106402:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106409:	e8 7e fd ff ff       	call   8010618c <argfd>
8010640e:	85 c0                	test   %eax,%eax
80106410:	78 1f                	js     80106431 <sys_fstat+0x44>
80106412:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106419:	00 
8010641a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010641d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106421:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106428:	e8 f5 fb ff ff       	call   80106022 <argptr>
8010642d:	85 c0                	test   %eax,%eax
8010642f:	79 07                	jns    80106438 <sys_fstat+0x4b>
    return -1;
80106431:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106436:	eb 12                	jmp    8010644a <sys_fstat+0x5d>
  return filestat(f, st);
80106438:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010643b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010643e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106442:	89 04 24             	mov    %eax,(%esp)
80106445:	e8 50 ac ff ff       	call   8010109a <filestat>
}
8010644a:	c9                   	leave  
8010644b:	c3                   	ret    

8010644c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010644c:	55                   	push   %ebp
8010644d:	89 e5                	mov    %esp,%ebp
8010644f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106452:	8d 45 d8             	lea    -0x28(%ebp),%eax
80106455:	89 44 24 04          	mov    %eax,0x4(%esp)
80106459:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106460:	e8 1f fc ff ff       	call   80106084 <argstr>
80106465:	85 c0                	test   %eax,%eax
80106467:	78 17                	js     80106480 <sys_link+0x34>
80106469:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010646c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106470:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106477:	e8 08 fc ff ff       	call   80106084 <argstr>
8010647c:	85 c0                	test   %eax,%eax
8010647e:	79 0a                	jns    8010648a <sys_link+0x3e>
    return -1;
80106480:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106485:	e9 3c 01 00 00       	jmp    801065c6 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010648a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010648d:	89 04 24             	mov    %eax,(%esp)
80106490:	e8 f9 ca ff ff       	call   80102f8e <namei>
80106495:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106498:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010649c:	75 0a                	jne    801064a8 <sys_link+0x5c>
    return -1;
8010649e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064a3:	e9 1e 01 00 00       	jmp    801065c6 <sys_link+0x17a>

  begin_trans();
801064a8:	e8 18 dc ff ff       	call   801040c5 <begin_trans>

  ilock(ip);
801064ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064b0:	89 04 24             	mov    %eax,(%esp)
801064b3:	e8 34 bf ff ff       	call   801023ec <ilock>
  if(ip->type == T_DIR){
801064b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064bb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801064bf:	66 83 f8 01          	cmp    $0x1,%ax
801064c3:	75 1a                	jne    801064df <sys_link+0x93>
    iunlockput(ip);
801064c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c8:	89 04 24             	mov    %eax,(%esp)
801064cb:	e8 a0 c1 ff ff       	call   80102670 <iunlockput>
    commit_trans();
801064d0:	e8 39 dc ff ff       	call   8010410e <commit_trans>
    return -1;
801064d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064da:	e9 e7 00 00 00       	jmp    801065c6 <sys_link+0x17a>
  }

  ip->nlink++;
801064df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064e2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801064e6:	8d 50 01             	lea    0x1(%eax),%edx
801064e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064ec:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801064f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064f3:	89 04 24             	mov    %eax,(%esp)
801064f6:	e8 35 bd ff ff       	call   80102230 <iupdate>
  iunlock(ip);
801064fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064fe:	89 04 24             	mov    %eax,(%esp)
80106501:	e8 34 c0 ff ff       	call   8010253a <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106506:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106509:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010650c:	89 54 24 04          	mov    %edx,0x4(%esp)
80106510:	89 04 24             	mov    %eax,(%esp)
80106513:	e8 98 ca ff ff       	call   80102fb0 <nameiparent>
80106518:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010651b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010651f:	74 68                	je     80106589 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80106521:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106524:	89 04 24             	mov    %eax,(%esp)
80106527:	e8 c0 be ff ff       	call   801023ec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010652c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010652f:	8b 10                	mov    (%eax),%edx
80106531:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106534:	8b 00                	mov    (%eax),%eax
80106536:	39 c2                	cmp    %eax,%edx
80106538:	75 20                	jne    8010655a <sys_link+0x10e>
8010653a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010653d:	8b 40 04             	mov    0x4(%eax),%eax
80106540:	89 44 24 08          	mov    %eax,0x8(%esp)
80106544:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106547:	89 44 24 04          	mov    %eax,0x4(%esp)
8010654b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010654e:	89 04 24             	mov    %eax,(%esp)
80106551:	e8 77 c7 ff ff       	call   80102ccd <dirlink>
80106556:	85 c0                	test   %eax,%eax
80106558:	79 0d                	jns    80106567 <sys_link+0x11b>
    iunlockput(dp);
8010655a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010655d:	89 04 24             	mov    %eax,(%esp)
80106560:	e8 0b c1 ff ff       	call   80102670 <iunlockput>
    goto bad;
80106565:	eb 23                	jmp    8010658a <sys_link+0x13e>
  }
  iunlockput(dp);
80106567:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010656a:	89 04 24             	mov    %eax,(%esp)
8010656d:	e8 fe c0 ff ff       	call   80102670 <iunlockput>
  iput(ip);
80106572:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106575:	89 04 24             	mov    %eax,(%esp)
80106578:	e8 22 c0 ff ff       	call   8010259f <iput>

  commit_trans();
8010657d:	e8 8c db ff ff       	call   8010410e <commit_trans>

  return 0;
80106582:	b8 00 00 00 00       	mov    $0x0,%eax
80106587:	eb 3d                	jmp    801065c6 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80106589:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010658a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010658d:	89 04 24             	mov    %eax,(%esp)
80106590:	e8 57 be ff ff       	call   801023ec <ilock>
  ip->nlink--;
80106595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106598:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010659c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010659f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801065a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065a9:	89 04 24             	mov    %eax,(%esp)
801065ac:	e8 7f bc ff ff       	call   80102230 <iupdate>
  iunlockput(ip);
801065b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b4:	89 04 24             	mov    %eax,(%esp)
801065b7:	e8 b4 c0 ff ff       	call   80102670 <iunlockput>
  commit_trans();
801065bc:	e8 4d db ff ff       	call   8010410e <commit_trans>
  return -1;
801065c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801065c6:	c9                   	leave  
801065c7:	c3                   	ret    

801065c8 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801065c8:	55                   	push   %ebp
801065c9:	89 e5                	mov    %esp,%ebp
801065cb:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801065ce:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801065d5:	eb 4b                	jmp    80106622 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801065d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065da:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801065e1:	00 
801065e2:	89 44 24 08          	mov    %eax,0x8(%esp)
801065e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801065e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801065ed:	8b 45 08             	mov    0x8(%ebp),%eax
801065f0:	89 04 24             	mov    %eax,(%esp)
801065f3:	e8 ea c2 ff ff       	call   801028e2 <readi>
801065f8:	83 f8 10             	cmp    $0x10,%eax
801065fb:	74 0c                	je     80106609 <isdirempty+0x41>
      panic("isdirempty: readi");
801065fd:	c7 04 24 9b 98 10 80 	movl   $0x8010989b,(%esp)
80106604:	e8 34 9f ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106609:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010660d:	66 85 c0             	test   %ax,%ax
80106610:	74 07                	je     80106619 <isdirempty+0x51>
      return 0;
80106612:	b8 00 00 00 00       	mov    $0x0,%eax
80106617:	eb 1b                	jmp    80106634 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010661c:	83 c0 10             	add    $0x10,%eax
8010661f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106622:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106625:	8b 45 08             	mov    0x8(%ebp),%eax
80106628:	8b 40 18             	mov    0x18(%eax),%eax
8010662b:	39 c2                	cmp    %eax,%edx
8010662d:	72 a8                	jb     801065d7 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010662f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106634:	c9                   	leave  
80106635:	c3                   	ret    

80106636 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106636:	55                   	push   %ebp
80106637:	89 e5                	mov    %esp,%ebp
80106639:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
8010663c:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010663f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106643:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010664a:	e8 35 fa ff ff       	call   80106084 <argstr>
8010664f:	85 c0                	test   %eax,%eax
80106651:	79 0a                	jns    8010665d <sys_unlink+0x27>
    return -1;
80106653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106658:	e9 aa 01 00 00       	jmp    80106807 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
8010665d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80106660:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80106663:	89 54 24 04          	mov    %edx,0x4(%esp)
80106667:	89 04 24             	mov    %eax,(%esp)
8010666a:	e8 41 c9 ff ff       	call   80102fb0 <nameiparent>
8010666f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106672:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106676:	75 0a                	jne    80106682 <sys_unlink+0x4c>
    return -1;
80106678:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010667d:	e9 85 01 00 00       	jmp    80106807 <sys_unlink+0x1d1>

  begin_trans();
80106682:	e8 3e da ff ff       	call   801040c5 <begin_trans>

  ilock(dp);
80106687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668a:	89 04 24             	mov    %eax,(%esp)
8010668d:	e8 5a bd ff ff       	call   801023ec <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80106692:	c7 44 24 04 ad 98 10 	movl   $0x801098ad,0x4(%esp)
80106699:	80 
8010669a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010669d:	89 04 24             	mov    %eax,(%esp)
801066a0:	e8 3e c5 ff ff       	call   80102be3 <namecmp>
801066a5:	85 c0                	test   %eax,%eax
801066a7:	0f 84 45 01 00 00    	je     801067f2 <sys_unlink+0x1bc>
801066ad:	c7 44 24 04 af 98 10 	movl   $0x801098af,0x4(%esp)
801066b4:	80 
801066b5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066b8:	89 04 24             	mov    %eax,(%esp)
801066bb:	e8 23 c5 ff ff       	call   80102be3 <namecmp>
801066c0:	85 c0                	test   %eax,%eax
801066c2:	0f 84 2a 01 00 00    	je     801067f2 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801066c8:	8d 45 c8             	lea    -0x38(%ebp),%eax
801066cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801066cf:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801066d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801066d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d9:	89 04 24             	mov    %eax,(%esp)
801066dc:	e8 24 c5 ff ff       	call   80102c05 <dirlookup>
801066e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801066e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801066e8:	0f 84 03 01 00 00    	je     801067f1 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801066ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066f1:	89 04 24             	mov    %eax,(%esp)
801066f4:	e8 f3 bc ff ff       	call   801023ec <ilock>

  if(ip->nlink < 1)
801066f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066fc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106700:	66 85 c0             	test   %ax,%ax
80106703:	7f 0c                	jg     80106711 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106705:	c7 04 24 b2 98 10 80 	movl   $0x801098b2,(%esp)
8010670c:	e8 2c 9e ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106711:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106714:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106718:	66 83 f8 01          	cmp    $0x1,%ax
8010671c:	75 1f                	jne    8010673d <sys_unlink+0x107>
8010671e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106721:	89 04 24             	mov    %eax,(%esp)
80106724:	e8 9f fe ff ff       	call   801065c8 <isdirempty>
80106729:	85 c0                	test   %eax,%eax
8010672b:	75 10                	jne    8010673d <sys_unlink+0x107>
    iunlockput(ip);
8010672d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106730:	89 04 24             	mov    %eax,(%esp)
80106733:	e8 38 bf ff ff       	call   80102670 <iunlockput>
    goto bad;
80106738:	e9 b5 00 00 00       	jmp    801067f2 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
8010673d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106744:	00 
80106745:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010674c:	00 
8010674d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106750:	89 04 24             	mov    %eax,(%esp)
80106753:	e8 42 f5 ff ff       	call   80105c9a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106758:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010675b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106762:	00 
80106763:	89 44 24 08          	mov    %eax,0x8(%esp)
80106767:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010676a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010676e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106771:	89 04 24             	mov    %eax,(%esp)
80106774:	e8 d4 c2 ff ff       	call   80102a4d <writei>
80106779:	83 f8 10             	cmp    $0x10,%eax
8010677c:	74 0c                	je     8010678a <sys_unlink+0x154>
    panic("unlink: writei");
8010677e:	c7 04 24 c4 98 10 80 	movl   $0x801098c4,(%esp)
80106785:	e8 b3 9d ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010678a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010678d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106791:	66 83 f8 01          	cmp    $0x1,%ax
80106795:	75 1c                	jne    801067b3 <sys_unlink+0x17d>
    dp->nlink--;
80106797:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010679e:	8d 50 ff             	lea    -0x1(%eax),%edx
801067a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801067a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ab:	89 04 24             	mov    %eax,(%esp)
801067ae:	e8 7d ba ff ff       	call   80102230 <iupdate>
  }
  iunlockput(dp);
801067b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067b6:	89 04 24             	mov    %eax,(%esp)
801067b9:	e8 b2 be ff ff       	call   80102670 <iunlockput>

  ip->nlink--;
801067be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067c1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801067c5:	8d 50 ff             	lea    -0x1(%eax),%edx
801067c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067cb:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801067cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067d2:	89 04 24             	mov    %eax,(%esp)
801067d5:	e8 56 ba ff ff       	call   80102230 <iupdate>
  iunlockput(ip);
801067da:	8b 45 f0             	mov    -0x10(%ebp),%eax
801067dd:	89 04 24             	mov    %eax,(%esp)
801067e0:	e8 8b be ff ff       	call   80102670 <iunlockput>

  commit_trans();
801067e5:	e8 24 d9 ff ff       	call   8010410e <commit_trans>

  return 0;
801067ea:	b8 00 00 00 00       	mov    $0x0,%eax
801067ef:	eb 16                	jmp    80106807 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
801067f1:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
801067f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067f5:	89 04 24             	mov    %eax,(%esp)
801067f8:	e8 73 be ff ff       	call   80102670 <iunlockput>
  commit_trans();
801067fd:	e8 0c d9 ff ff       	call   8010410e <commit_trans>
  return -1;
80106802:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106807:	c9                   	leave  
80106808:	c3                   	ret    

80106809 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106809:	55                   	push   %ebp
8010680a:	89 e5                	mov    %esp,%ebp
8010680c:	83 ec 48             	sub    $0x48,%esp
8010680f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106812:	8b 55 10             	mov    0x10(%ebp),%edx
80106815:	8b 45 14             	mov    0x14(%ebp),%eax
80106818:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010681c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106820:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106824:	8d 45 de             	lea    -0x22(%ebp),%eax
80106827:	89 44 24 04          	mov    %eax,0x4(%esp)
8010682b:	8b 45 08             	mov    0x8(%ebp),%eax
8010682e:	89 04 24             	mov    %eax,(%esp)
80106831:	e8 7a c7 ff ff       	call   80102fb0 <nameiparent>
80106836:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106839:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010683d:	75 0a                	jne    80106849 <create+0x40>
    return 0;
8010683f:	b8 00 00 00 00       	mov    $0x0,%eax
80106844:	e9 7e 01 00 00       	jmp    801069c7 <create+0x1be>
  ilock(dp);
80106849:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010684c:	89 04 24             	mov    %eax,(%esp)
8010684f:	e8 98 bb ff ff       	call   801023ec <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106854:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106857:	89 44 24 08          	mov    %eax,0x8(%esp)
8010685b:	8d 45 de             	lea    -0x22(%ebp),%eax
8010685e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106865:	89 04 24             	mov    %eax,(%esp)
80106868:	e8 98 c3 ff ff       	call   80102c05 <dirlookup>
8010686d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106870:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106874:	74 47                	je     801068bd <create+0xb4>
    iunlockput(dp);
80106876:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106879:	89 04 24             	mov    %eax,(%esp)
8010687c:	e8 ef bd ff ff       	call   80102670 <iunlockput>
    ilock(ip);
80106881:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106884:	89 04 24             	mov    %eax,(%esp)
80106887:	e8 60 bb ff ff       	call   801023ec <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010688c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106891:	75 15                	jne    801068a8 <create+0x9f>
80106893:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106896:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010689a:	66 83 f8 02          	cmp    $0x2,%ax
8010689e:	75 08                	jne    801068a8 <create+0x9f>
      return ip;
801068a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a3:	e9 1f 01 00 00       	jmp    801069c7 <create+0x1be>
    iunlockput(ip);
801068a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ab:	89 04 24             	mov    %eax,(%esp)
801068ae:	e8 bd bd ff ff       	call   80102670 <iunlockput>
    return 0;
801068b3:	b8 00 00 00 00       	mov    $0x0,%eax
801068b8:	e9 0a 01 00 00       	jmp    801069c7 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
801068bd:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
801068c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c4:	8b 00                	mov    (%eax),%eax
801068c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801068ca:	89 04 24             	mov    %eax,(%esp)
801068cd:	e8 81 b8 ff ff       	call   80102153 <ialloc>
801068d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801068d5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801068d9:	75 0c                	jne    801068e7 <create+0xde>
    panic("create: ialloc");
801068db:	c7 04 24 d3 98 10 80 	movl   $0x801098d3,(%esp)
801068e2:	e8 56 9c ff ff       	call   8010053d <panic>

  ilock(ip);
801068e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068ea:	89 04 24             	mov    %eax,(%esp)
801068ed:	e8 fa ba ff ff       	call   801023ec <ilock>
  ip->major = major;
801068f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068f5:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801068f9:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801068fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106900:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106904:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106908:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010690b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106911:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106914:	89 04 24             	mov    %eax,(%esp)
80106917:	e8 14 b9 ff ff       	call   80102230 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
8010691c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106921:	75 6a                	jne    8010698d <create+0x184>
    dp->nlink++;  // for ".."
80106923:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106926:	0f b7 40 16          	movzwl 0x16(%eax),%eax
8010692a:	8d 50 01             	lea    0x1(%eax),%edx
8010692d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106930:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106937:	89 04 24             	mov    %eax,(%esp)
8010693a:	e8 f1 b8 ff ff       	call   80102230 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010693f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106942:	8b 40 04             	mov    0x4(%eax),%eax
80106945:	89 44 24 08          	mov    %eax,0x8(%esp)
80106949:	c7 44 24 04 ad 98 10 	movl   $0x801098ad,0x4(%esp)
80106950:	80 
80106951:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106954:	89 04 24             	mov    %eax,(%esp)
80106957:	e8 71 c3 ff ff       	call   80102ccd <dirlink>
8010695c:	85 c0                	test   %eax,%eax
8010695e:	78 21                	js     80106981 <create+0x178>
80106960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106963:	8b 40 04             	mov    0x4(%eax),%eax
80106966:	89 44 24 08          	mov    %eax,0x8(%esp)
8010696a:	c7 44 24 04 af 98 10 	movl   $0x801098af,0x4(%esp)
80106971:	80 
80106972:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106975:	89 04 24             	mov    %eax,(%esp)
80106978:	e8 50 c3 ff ff       	call   80102ccd <dirlink>
8010697d:	85 c0                	test   %eax,%eax
8010697f:	79 0c                	jns    8010698d <create+0x184>
      panic("create dots");
80106981:	c7 04 24 e2 98 10 80 	movl   $0x801098e2,(%esp)
80106988:	e8 b0 9b ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010698d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106990:	8b 40 04             	mov    0x4(%eax),%eax
80106993:	89 44 24 08          	mov    %eax,0x8(%esp)
80106997:	8d 45 de             	lea    -0x22(%ebp),%eax
8010699a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010699e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a1:	89 04 24             	mov    %eax,(%esp)
801069a4:	e8 24 c3 ff ff       	call   80102ccd <dirlink>
801069a9:	85 c0                	test   %eax,%eax
801069ab:	79 0c                	jns    801069b9 <create+0x1b0>
    panic("create: dirlink");
801069ad:	c7 04 24 ee 98 10 80 	movl   $0x801098ee,(%esp)
801069b4:	e8 84 9b ff ff       	call   8010053d <panic>

  iunlockput(dp);
801069b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069bc:	89 04 24             	mov    %eax,(%esp)
801069bf:	e8 ac bc ff ff       	call   80102670 <iunlockput>

  return ip;
801069c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801069c7:	c9                   	leave  
801069c8:	c3                   	ret    

801069c9 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
801069c9:	55                   	push   %ebp
801069ca:	89 e5                	mov    %esp,%ebp
801069cc:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
801069cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801069d2:	25 00 02 00 00       	and    $0x200,%eax
801069d7:	85 c0                	test   %eax,%eax
801069d9:	74 40                	je     80106a1b <fileopen+0x52>
    begin_trans();
801069db:	e8 e5 d6 ff ff       	call   801040c5 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801069e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801069e7:	00 
801069e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801069ef:	00 
801069f0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
801069f7:	00 
801069f8:	8b 45 08             	mov    0x8(%ebp),%eax
801069fb:	89 04 24             	mov    %eax,(%esp)
801069fe:	e8 06 fe ff ff       	call   80106809 <create>
80106a03:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106a06:	e8 03 d7 ff ff       	call   8010410e <commit_trans>
    if(ip == 0)
80106a0b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a0f:	75 5b                	jne    80106a6c <fileopen+0xa3>
      return 0;
80106a11:	b8 00 00 00 00       	mov    $0x0,%eax
80106a16:	e9 e5 00 00 00       	jmp    80106b00 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106a1b:	8b 45 08             	mov    0x8(%ebp),%eax
80106a1e:	89 04 24             	mov    %eax,(%esp)
80106a21:	e8 68 c5 ff ff       	call   80102f8e <namei>
80106a26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106a29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106a2d:	75 0a                	jne    80106a39 <fileopen+0x70>
      return 0;
80106a2f:	b8 00 00 00 00       	mov    $0x0,%eax
80106a34:	e9 c7 00 00 00       	jmp    80106b00 <fileopen+0x137>
    ilock(ip);
80106a39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a3c:	89 04 24             	mov    %eax,(%esp)
80106a3f:	e8 a8 b9 ff ff       	call   801023ec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a47:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a4b:	66 83 f8 01          	cmp    $0x1,%ax
80106a4f:	75 1b                	jne    80106a6c <fileopen+0xa3>
80106a51:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106a55:	74 15                	je     80106a6c <fileopen+0xa3>
      iunlockput(ip);
80106a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a5a:	89 04 24             	mov    %eax,(%esp)
80106a5d:	e8 0e bc ff ff       	call   80102670 <iunlockput>
      return 0;
80106a62:	b8 00 00 00 00       	mov    $0x0,%eax
80106a67:	e9 94 00 00 00       	jmp    80106b00 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106a6c:	e8 ab a4 ff ff       	call   80100f1c <filealloc>
80106a71:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a78:	75 23                	jne    80106a9d <fileopen+0xd4>
    if(f)
80106a7a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a7e:	74 0b                	je     80106a8b <fileopen+0xc2>
      fileclose(f);
80106a80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a83:	89 04 24             	mov    %eax,(%esp)
80106a86:	e8 39 a5 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8e:	89 04 24             	mov    %eax,(%esp)
80106a91:	e8 da bb ff ff       	call   80102670 <iunlockput>
    return 0;
80106a96:	b8 00 00 00 00       	mov    $0x0,%eax
80106a9b:	eb 63                	jmp    80106b00 <fileopen+0x137>
  }
  iunlock(ip);
80106a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa0:	89 04 24             	mov    %eax,(%esp)
80106aa3:	e8 92 ba ff ff       	call   8010253a <iunlock>

  f->type = FD_INODE;
80106aa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106aab:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106ab1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ab7:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106abd:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106ac4:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ac7:	83 e0 01             	and    $0x1,%eax
80106aca:	85 c0                	test   %eax,%eax
80106acc:	0f 94 c2             	sete   %dl
80106acf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ad2:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106ad5:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ad8:	83 e0 01             	and    $0x1,%eax
80106adb:	84 c0                	test   %al,%al
80106add:	75 0a                	jne    80106ae9 <fileopen+0x120>
80106adf:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ae2:	83 e0 02             	and    $0x2,%eax
80106ae5:	85 c0                	test   %eax,%eax
80106ae7:	74 07                	je     80106af0 <fileopen+0x127>
80106ae9:	b8 01 00 00 00       	mov    $0x1,%eax
80106aee:	eb 05                	jmp    80106af5 <fileopen+0x12c>
80106af0:	b8 00 00 00 00       	mov    $0x0,%eax
80106af5:	89 c2                	mov    %eax,%edx
80106af7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106afa:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106afd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106b00:	c9                   	leave  
80106b01:	c3                   	ret    

80106b02 <sys_open>:

int
sys_open(void)
{
80106b02:	55                   	push   %ebp
80106b03:	89 e5                	mov    %esp,%ebp
80106b05:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106b08:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b0f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b16:	e8 69 f5 ff ff       	call   80106084 <argstr>
80106b1b:	85 c0                	test   %eax,%eax
80106b1d:	78 17                	js     80106b36 <sys_open+0x34>
80106b1f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b22:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b26:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b2d:	e8 b8 f4 ff ff       	call   80105fea <argint>
80106b32:	85 c0                	test   %eax,%eax
80106b34:	79 0a                	jns    80106b40 <sys_open+0x3e>
    return -1;
80106b36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b3b:	e9 46 01 00 00       	jmp    80106c86 <sys_open+0x184>
  if(omode & O_CREATE){
80106b40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b43:	25 00 02 00 00       	and    $0x200,%eax
80106b48:	85 c0                	test   %eax,%eax
80106b4a:	74 40                	je     80106b8c <sys_open+0x8a>
    begin_trans();
80106b4c:	e8 74 d5 ff ff       	call   801040c5 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106b51:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b54:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b5b:	00 
80106b5c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b63:	00 
80106b64:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106b6b:	00 
80106b6c:	89 04 24             	mov    %eax,(%esp)
80106b6f:	e8 95 fc ff ff       	call   80106809 <create>
80106b74:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106b77:	e8 92 d5 ff ff       	call   8010410e <commit_trans>
    if(ip == 0)
80106b7c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b80:	75 5c                	jne    80106bde <sys_open+0xdc>
      return -1;
80106b82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b87:	e9 fa 00 00 00       	jmp    80106c86 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106b8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b8f:	89 04 24             	mov    %eax,(%esp)
80106b92:	e8 f7 c3 ff ff       	call   80102f8e <namei>
80106b97:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b9a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b9e:	75 0a                	jne    80106baa <sys_open+0xa8>
      return -1;
80106ba0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ba5:	e9 dc 00 00 00       	jmp    80106c86 <sys_open+0x184>
    ilock(ip);
80106baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bad:	89 04 24             	mov    %eax,(%esp)
80106bb0:	e8 37 b8 ff ff       	call   801023ec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bb8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bbc:	66 83 f8 01          	cmp    $0x1,%ax
80106bc0:	75 1c                	jne    80106bde <sys_open+0xdc>
80106bc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106bc5:	85 c0                	test   %eax,%eax
80106bc7:	74 15                	je     80106bde <sys_open+0xdc>
      iunlockput(ip);
80106bc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bcc:	89 04 24             	mov    %eax,(%esp)
80106bcf:	e8 9c ba ff ff       	call   80102670 <iunlockput>
      return -1;
80106bd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bd9:	e9 a8 00 00 00       	jmp    80106c86 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106bde:	e8 39 a3 ff ff       	call   80100f1c <filealloc>
80106be3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106be6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bea:	74 14                	je     80106c00 <sys_open+0xfe>
80106bec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bef:	89 04 24             	mov    %eax,(%esp)
80106bf2:	e8 0a f6 ff ff       	call   80106201 <fdalloc>
80106bf7:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106bfa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106bfe:	79 23                	jns    80106c23 <sys_open+0x121>
    if(f)
80106c00:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c04:	74 0b                	je     80106c11 <sys_open+0x10f>
      fileclose(f);
80106c06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c09:	89 04 24             	mov    %eax,(%esp)
80106c0c:	e8 b3 a3 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c14:	89 04 24             	mov    %eax,(%esp)
80106c17:	e8 54 ba ff ff       	call   80102670 <iunlockput>
    return -1;
80106c1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c21:	eb 63                	jmp    80106c86 <sys_open+0x184>
  }
  iunlock(ip);
80106c23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c26:	89 04 24             	mov    %eax,(%esp)
80106c29:	e8 0c b9 ff ff       	call   8010253a <iunlock>

  f->type = FD_INODE;
80106c2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c31:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106c37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c3a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c3d:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106c40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c43:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106c4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c4d:	83 e0 01             	and    $0x1,%eax
80106c50:	85 c0                	test   %eax,%eax
80106c52:	0f 94 c2             	sete   %dl
80106c55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c58:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106c5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c5e:	83 e0 01             	and    $0x1,%eax
80106c61:	84 c0                	test   %al,%al
80106c63:	75 0a                	jne    80106c6f <sys_open+0x16d>
80106c65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c68:	83 e0 02             	and    $0x2,%eax
80106c6b:	85 c0                	test   %eax,%eax
80106c6d:	74 07                	je     80106c76 <sys_open+0x174>
80106c6f:	b8 01 00 00 00       	mov    $0x1,%eax
80106c74:	eb 05                	jmp    80106c7b <sys_open+0x179>
80106c76:	b8 00 00 00 00       	mov    $0x0,%eax
80106c7b:	89 c2                	mov    %eax,%edx
80106c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c80:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106c83:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106c86:	c9                   	leave  
80106c87:	c3                   	ret    

80106c88 <sys_mkdir>:

int
sys_mkdir(void)
{
80106c88:	55                   	push   %ebp
80106c89:	89 e5                	mov    %esp,%ebp
80106c8b:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106c8e:	e8 32 d4 ff ff       	call   801040c5 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106c93:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106c96:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c9a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ca1:	e8 de f3 ff ff       	call   80106084 <argstr>
80106ca6:	85 c0                	test   %eax,%eax
80106ca8:	78 2c                	js     80106cd6 <sys_mkdir+0x4e>
80106caa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cad:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106cb4:	00 
80106cb5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106cbc:	00 
80106cbd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106cc4:	00 
80106cc5:	89 04 24             	mov    %eax,(%esp)
80106cc8:	e8 3c fb ff ff       	call   80106809 <create>
80106ccd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106cd0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106cd4:	75 0c                	jne    80106ce2 <sys_mkdir+0x5a>
    commit_trans();
80106cd6:	e8 33 d4 ff ff       	call   8010410e <commit_trans>
    return -1;
80106cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ce0:	eb 15                	jmp    80106cf7 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106ce2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ce5:	89 04 24             	mov    %eax,(%esp)
80106ce8:	e8 83 b9 ff ff       	call   80102670 <iunlockput>
  commit_trans();
80106ced:	e8 1c d4 ff ff       	call   8010410e <commit_trans>
  return 0;
80106cf2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106cf7:	c9                   	leave  
80106cf8:	c3                   	ret    

80106cf9 <sys_mknod>:

int
sys_mknod(void)
{
80106cf9:	55                   	push   %ebp
80106cfa:	89 e5                	mov    %esp,%ebp
80106cfc:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80106cff:	e8 c1 d3 ff ff       	call   801040c5 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80106d04:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106d07:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d0b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d12:	e8 6d f3 ff ff       	call   80106084 <argstr>
80106d17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d1e:	78 5e                	js     80106d7e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106d20:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106d23:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d27:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d2e:	e8 b7 f2 ff ff       	call   80105fea <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80106d33:	85 c0                	test   %eax,%eax
80106d35:	78 47                	js     80106d7e <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d37:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106d3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d3e:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106d45:	e8 a0 f2 ff ff       	call   80105fea <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106d4a:	85 c0                	test   %eax,%eax
80106d4c:	78 30                	js     80106d7e <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106d51:	0f bf c8             	movswl %ax,%ecx
80106d54:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106d57:	0f bf d0             	movswl %ax,%edx
80106d5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d5d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106d61:	89 54 24 08          	mov    %edx,0x8(%esp)
80106d65:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106d6c:	00 
80106d6d:	89 04 24             	mov    %eax,(%esp)
80106d70:	e8 94 fa ff ff       	call   80106809 <create>
80106d75:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106d78:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106d7c:	75 0c                	jne    80106d8a <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106d7e:	e8 8b d3 ff ff       	call   8010410e <commit_trans>
    return -1;
80106d83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d88:	eb 15                	jmp    80106d9f <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106d8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106d8d:	89 04 24             	mov    %eax,(%esp)
80106d90:	e8 db b8 ff ff       	call   80102670 <iunlockput>
  commit_trans();
80106d95:	e8 74 d3 ff ff       	call   8010410e <commit_trans>
  return 0;
80106d9a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d9f:	c9                   	leave  
80106da0:	c3                   	ret    

80106da1 <sys_chdir>:

int
sys_chdir(void)
{
80106da1:	55                   	push   %ebp
80106da2:	89 e5                	mov    %esp,%ebp
80106da4:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80106da7:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106daa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106dae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106db5:	e8 ca f2 ff ff       	call   80106084 <argstr>
80106dba:	85 c0                	test   %eax,%eax
80106dbc:	78 14                	js     80106dd2 <sys_chdir+0x31>
80106dbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dc1:	89 04 24             	mov    %eax,(%esp)
80106dc4:	e8 c5 c1 ff ff       	call   80102f8e <namei>
80106dc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106dcc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106dd0:	75 07                	jne    80106dd9 <sys_chdir+0x38>
    return -1;
80106dd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dd7:	eb 57                	jmp    80106e30 <sys_chdir+0x8f>
  ilock(ip);
80106dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ddc:	89 04 24             	mov    %eax,(%esp)
80106ddf:	e8 08 b6 ff ff       	call   801023ec <ilock>
  if(ip->type != T_DIR){
80106de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106de7:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106deb:	66 83 f8 01          	cmp    $0x1,%ax
80106def:	74 12                	je     80106e03 <sys_chdir+0x62>
    iunlockput(ip);
80106df1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106df4:	89 04 24             	mov    %eax,(%esp)
80106df7:	e8 74 b8 ff ff       	call   80102670 <iunlockput>
    return -1;
80106dfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e01:	eb 2d                	jmp    80106e30 <sys_chdir+0x8f>
  }
  iunlock(ip);
80106e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e06:	89 04 24             	mov    %eax,(%esp)
80106e09:	e8 2c b7 ff ff       	call   8010253a <iunlock>
  iput(proc->cwd);
80106e0e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e14:	8b 40 68             	mov    0x68(%eax),%eax
80106e17:	89 04 24             	mov    %eax,(%esp)
80106e1a:	e8 80 b7 ff ff       	call   8010259f <iput>
  proc->cwd = ip;
80106e1f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106e25:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e28:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106e2b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106e30:	c9                   	leave  
80106e31:	c3                   	ret    

80106e32 <sys_exec>:

int
sys_exec(void)
{
80106e32:	55                   	push   %ebp
80106e33:	89 e5                	mov    %esp,%ebp
80106e35:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106e3b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e42:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e49:	e8 36 f2 ff ff       	call   80106084 <argstr>
80106e4e:	85 c0                	test   %eax,%eax
80106e50:	78 1a                	js     80106e6c <sys_exec+0x3a>
80106e52:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106e58:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e5c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e63:	e8 82 f1 ff ff       	call   80105fea <argint>
80106e68:	85 c0                	test   %eax,%eax
80106e6a:	79 0a                	jns    80106e76 <sys_exec+0x44>
    return -1;
80106e6c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e71:	e9 e2 00 00 00       	jmp    80106f58 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80106e76:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106e7d:	00 
80106e7e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e85:	00 
80106e86:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106e8c:	89 04 24             	mov    %eax,(%esp)
80106e8f:	e8 06 ee ff ff       	call   80105c9a <memset>
  for(i=0;; i++){
80106e94:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106e9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e9e:	83 f8 1f             	cmp    $0x1f,%eax
80106ea1:	76 0a                	jbe    80106ead <sys_exec+0x7b>
      return -1;
80106ea3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ea8:	e9 ab 00 00 00       	jmp    80106f58 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eb0:	c1 e0 02             	shl    $0x2,%eax
80106eb3:	89 c2                	mov    %eax,%edx
80106eb5:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106ebb:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106ebe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ec4:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106eca:	89 54 24 08          	mov    %edx,0x8(%esp)
80106ece:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106ed2:	89 04 24             	mov    %eax,(%esp)
80106ed5:	e8 7e f0 ff ff       	call   80105f58 <fetchint>
80106eda:	85 c0                	test   %eax,%eax
80106edc:	79 07                	jns    80106ee5 <sys_exec+0xb3>
      return -1;
80106ede:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ee3:	eb 73                	jmp    80106f58 <sys_exec+0x126>
    if(uarg == 0){
80106ee5:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106eeb:	85 c0                	test   %eax,%eax
80106eed:	75 26                	jne    80106f15 <sys_exec+0xe3>
      argv[i] = 0;
80106eef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ef2:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106ef9:	00 00 00 00 
      break;
80106efd:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106efe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f01:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106f07:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f0b:	89 04 24             	mov    %eax,(%esp)
80106f0e:	e8 e9 9b ff ff       	call   80100afc <exec>
80106f13:	eb 43                	jmp    80106f58 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80106f15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f18:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80106f1f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106f25:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106f28:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106f2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106f34:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106f38:	89 54 24 04          	mov    %edx,0x4(%esp)
80106f3c:	89 04 24             	mov    %eax,(%esp)
80106f3f:	e8 48 f0 ff ff       	call   80105f8c <fetchstr>
80106f44:	85 c0                	test   %eax,%eax
80106f46:	79 07                	jns    80106f4f <sys_exec+0x11d>
      return -1;
80106f48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f4d:	eb 09                	jmp    80106f58 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106f4f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106f53:	e9 43 ff ff ff       	jmp    80106e9b <sys_exec+0x69>
  return exec(path, argv);
}
80106f58:	c9                   	leave  
80106f59:	c3                   	ret    

80106f5a <sys_pipe>:

int
sys_pipe(void)
{
80106f5a:	55                   	push   %ebp
80106f5b:	89 e5                	mov    %esp,%ebp
80106f5d:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106f60:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106f67:	00 
80106f68:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106f6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106f76:	e8 a7 f0 ff ff       	call   80106022 <argptr>
80106f7b:	85 c0                	test   %eax,%eax
80106f7d:	79 0a                	jns    80106f89 <sys_pipe+0x2f>
    return -1;
80106f7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f84:	e9 9b 00 00 00       	jmp    80107024 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106f89:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106f8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f90:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106f93:	89 04 24             	mov    %eax,(%esp)
80106f96:	e8 45 db ff ff       	call   80104ae0 <pipealloc>
80106f9b:	85 c0                	test   %eax,%eax
80106f9d:	79 07                	jns    80106fa6 <sys_pipe+0x4c>
    return -1;
80106f9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fa4:	eb 7e                	jmp    80107024 <sys_pipe+0xca>
  fd0 = -1;
80106fa6:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106fad:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106fb0:	89 04 24             	mov    %eax,(%esp)
80106fb3:	e8 49 f2 ff ff       	call   80106201 <fdalloc>
80106fb8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106fbb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fbf:	78 14                	js     80106fd5 <sys_pipe+0x7b>
80106fc1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fc4:	89 04 24             	mov    %eax,(%esp)
80106fc7:	e8 35 f2 ff ff       	call   80106201 <fdalloc>
80106fcc:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106fcf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106fd3:	79 37                	jns    8010700c <sys_pipe+0xb2>
    if(fd0 >= 0)
80106fd5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106fd9:	78 14                	js     80106fef <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106fdb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106fe1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106fe4:	83 c2 08             	add    $0x8,%edx
80106fe7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106fee:	00 
    fileclose(rf);
80106fef:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106ff2:	89 04 24             	mov    %eax,(%esp)
80106ff5:	e8 ca 9f ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80106ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106ffd:	89 04 24             	mov    %eax,(%esp)
80107000:	e8 bf 9f ff ff       	call   80100fc4 <fileclose>
    return -1;
80107005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010700a:	eb 18                	jmp    80107024 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010700c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010700f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107012:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80107014:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107017:	8d 50 04             	lea    0x4(%eax),%edx
8010701a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010701d:	89 02                	mov    %eax,(%edx)
  return 0;
8010701f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107024:	c9                   	leave  
80107025:	c3                   	ret    
	...

80107028 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107028:	55                   	push   %ebp
80107029:	89 e5                	mov    %esp,%ebp
8010702b:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010702e:	e8 67 e1 ff ff       	call   8010519a <fork>
}
80107033:	c9                   	leave  
80107034:	c3                   	ret    

80107035 <sys_exit>:

int
sys_exit(void)
{
80107035:	55                   	push   %ebp
80107036:	89 e5                	mov    %esp,%ebp
80107038:	83 ec 08             	sub    $0x8,%esp
  exit();
8010703b:	e8 bd e2 ff ff       	call   801052fd <exit>
  return 0;  // not reached
80107040:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107045:	c9                   	leave  
80107046:	c3                   	ret    

80107047 <sys_wait>:

int
sys_wait(void)
{
80107047:	55                   	push   %ebp
80107048:	89 e5                	mov    %esp,%ebp
8010704a:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010704d:	e8 c3 e3 ff ff       	call   80105415 <wait>
}
80107052:	c9                   	leave  
80107053:	c3                   	ret    

80107054 <sys_kill>:

int
sys_kill(void)
{
80107054:	55                   	push   %ebp
80107055:	89 e5                	mov    %esp,%ebp
80107057:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010705a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010705d:	89 44 24 04          	mov    %eax,0x4(%esp)
80107061:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107068:	e8 7d ef ff ff       	call   80105fea <argint>
8010706d:	85 c0                	test   %eax,%eax
8010706f:	79 07                	jns    80107078 <sys_kill+0x24>
    return -1;
80107071:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107076:	eb 0b                	jmp    80107083 <sys_kill+0x2f>
  return kill(pid);
80107078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010707b:	89 04 24             	mov    %eax,(%esp)
8010707e:	e8 ee e7 ff ff       	call   80105871 <kill>
}
80107083:	c9                   	leave  
80107084:	c3                   	ret    

80107085 <sys_getpid>:

int
sys_getpid(void)
{
80107085:	55                   	push   %ebp
80107086:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107088:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010708e:	8b 40 10             	mov    0x10(%eax),%eax
}
80107091:	5d                   	pop    %ebp
80107092:	c3                   	ret    

80107093 <sys_sbrk>:

int
sys_sbrk(void)
{
80107093:	55                   	push   %ebp
80107094:	89 e5                	mov    %esp,%ebp
80107096:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107099:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010709c:	89 44 24 04          	mov    %eax,0x4(%esp)
801070a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070a7:	e8 3e ef ff ff       	call   80105fea <argint>
801070ac:	85 c0                	test   %eax,%eax
801070ae:	79 07                	jns    801070b7 <sys_sbrk+0x24>
    return -1;
801070b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070b5:	eb 24                	jmp    801070db <sys_sbrk+0x48>
  addr = proc->sz;
801070b7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801070bd:	8b 00                	mov    (%eax),%eax
801070bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801070c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070c5:	89 04 24             	mov    %eax,(%esp)
801070c8:	e8 28 e0 ff ff       	call   801050f5 <growproc>
801070cd:	85 c0                	test   %eax,%eax
801070cf:	79 07                	jns    801070d8 <sys_sbrk+0x45>
    return -1;
801070d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070d6:	eb 03                	jmp    801070db <sys_sbrk+0x48>
  return addr;
801070d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801070db:	c9                   	leave  
801070dc:	c3                   	ret    

801070dd <sys_sleep>:

int
sys_sleep(void)
{
801070dd:	55                   	push   %ebp
801070de:	89 e5                	mov    %esp,%ebp
801070e0:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801070e3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801070e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801070ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070f1:	e8 f4 ee ff ff       	call   80105fea <argint>
801070f6:	85 c0                	test   %eax,%eax
801070f8:	79 07                	jns    80107101 <sys_sleep+0x24>
    return -1;
801070fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070ff:	eb 6c                	jmp    8010716d <sys_sleep+0x90>
  acquire(&tickslock);
80107101:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107108:	e8 3e e9 ff ff       	call   80105a4b <acquire>
  ticks0 = ticks;
8010710d:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80107112:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107115:	eb 34                	jmp    8010714b <sys_sleep+0x6e>
    if(proc->killed){
80107117:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010711d:	8b 40 24             	mov    0x24(%eax),%eax
80107120:	85 c0                	test   %eax,%eax
80107122:	74 13                	je     80107137 <sys_sleep+0x5a>
      release(&tickslock);
80107124:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
8010712b:	e8 7d e9 ff ff       	call   80105aad <release>
      return -1;
80107130:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107135:	eb 36                	jmp    8010716d <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107137:	c7 44 24 04 80 2e 11 	movl   $0x80112e80,0x4(%esp)
8010713e:	80 
8010713f:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
80107146:	e8 22 e6 ff ff       	call   8010576d <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010714b:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80107150:	89 c2                	mov    %eax,%edx
80107152:	2b 55 f4             	sub    -0xc(%ebp),%edx
80107155:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107158:	39 c2                	cmp    %eax,%edx
8010715a:	72 bb                	jb     80107117 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
8010715c:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107163:	e8 45 e9 ff ff       	call   80105aad <release>
  return 0;
80107168:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010716d:	c9                   	leave  
8010716e:	c3                   	ret    

8010716f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010716f:	55                   	push   %ebp
80107170:	89 e5                	mov    %esp,%ebp
80107172:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107175:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
8010717c:	e8 ca e8 ff ff       	call   80105a4b <acquire>
  xticks = ticks;
80107181:	a1 c0 36 11 80       	mov    0x801136c0,%eax
80107186:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107189:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107190:	e8 18 e9 ff ff       	call   80105aad <release>
  return xticks;
80107195:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107198:	c9                   	leave  
80107199:	c3                   	ret    

8010719a <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
8010719a:	55                   	push   %ebp
8010719b:	89 e5                	mov    %esp,%ebp
8010719d:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
801071a0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801071a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801071a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071ae:	e8 d1 ee ff ff       	call   80106084 <argstr>
801071b3:	85 c0                	test   %eax,%eax
801071b5:	79 07                	jns    801071be <sys_getFileBlocks+0x24>
    return -1;
801071b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071bc:	eb 0b                	jmp    801071c9 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
801071be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071c1:	89 04 24             	mov    %eax,(%esp)
801071c4:	e8 21 a1 ff ff       	call   801012ea <getFileBlocks>
}
801071c9:	c9                   	leave  
801071ca:	c3                   	ret    

801071cb <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
801071cb:	55                   	push   %ebp
801071cc:	89 e5                	mov    %esp,%ebp
801071ce:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
801071d1:	e8 71 a2 ff ff       	call   80101447 <getFreeBlocks>
}
801071d6:	c9                   	leave  
801071d7:	c3                   	ret    

801071d8 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
801071d8:	55                   	push   %ebp
801071d9:	89 e5                	mov    %esp,%ebp
  return 0;
801071db:	b8 00 00 00 00       	mov    $0x0,%eax
  
}
801071e0:	5d                   	pop    %ebp
801071e1:	c3                   	ret    

801071e2 <sys_dedup>:

int
sys_dedup(void)
{
801071e2:	55                   	push   %ebp
801071e3:	89 e5                	mov    %esp,%ebp
801071e5:	83 ec 08             	sub    $0x8,%esp
  return dedup();
801071e8:	e8 7d a4 ff ff       	call   8010166a <dedup>
}
801071ed:	c9                   	leave  
801071ee:	c3                   	ret    
	...

801071f0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801071f0:	55                   	push   %ebp
801071f1:	89 e5                	mov    %esp,%ebp
801071f3:	83 ec 08             	sub    $0x8,%esp
801071f6:	8b 55 08             	mov    0x8(%ebp),%edx
801071f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801071fc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107200:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107203:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107207:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010720b:	ee                   	out    %al,(%dx)
}
8010720c:	c9                   	leave  
8010720d:	c3                   	ret    

8010720e <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010720e:	55                   	push   %ebp
8010720f:	89 e5                	mov    %esp,%ebp
80107211:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107214:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010721b:	00 
8010721c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107223:	e8 c8 ff ff ff       	call   801071f0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107228:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010722f:	00 
80107230:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107237:	e8 b4 ff ff ff       	call   801071f0 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010723c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80107243:	00 
80107244:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010724b:	e8 a0 ff ff ff       	call   801071f0 <outb>
  picenable(IRQ_TIMER);
80107250:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107257:	e8 0d d7 ff ff       	call   80104969 <picenable>
}
8010725c:	c9                   	leave  
8010725d:	c3                   	ret    
	...

80107260 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107260:	1e                   	push   %ds
  pushl %es
80107261:	06                   	push   %es
  pushl %fs
80107262:	0f a0                	push   %fs
  pushl %gs
80107264:	0f a8                	push   %gs
  pushal
80107266:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
80107267:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010726b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010726d:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
8010726f:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
80107273:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
80107275:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
80107277:	54                   	push   %esp
  call trap
80107278:	e8 de 01 00 00       	call   8010745b <trap>
  addl $4, %esp
8010727d:	83 c4 04             	add    $0x4,%esp

80107280 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80107280:	61                   	popa   
  popl %gs
80107281:	0f a9                	pop    %gs
  popl %fs
80107283:	0f a1                	pop    %fs
  popl %es
80107285:	07                   	pop    %es
  popl %ds
80107286:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80107287:	83 c4 08             	add    $0x8,%esp
  iret
8010728a:	cf                   	iret   
	...

8010728c <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010728c:	55                   	push   %ebp
8010728d:	89 e5                	mov    %esp,%ebp
8010728f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107292:	8b 45 0c             	mov    0xc(%ebp),%eax
80107295:	83 e8 01             	sub    $0x1,%eax
80107298:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010729c:	8b 45 08             	mov    0x8(%ebp),%eax
8010729f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801072a3:	8b 45 08             	mov    0x8(%ebp),%eax
801072a6:	c1 e8 10             	shr    $0x10,%eax
801072a9:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801072ad:	8d 45 fa             	lea    -0x6(%ebp),%eax
801072b0:	0f 01 18             	lidtl  (%eax)
}
801072b3:	c9                   	leave  
801072b4:	c3                   	ret    

801072b5 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801072b5:	55                   	push   %ebp
801072b6:	89 e5                	mov    %esp,%ebp
801072b8:	53                   	push   %ebx
801072b9:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801072bc:	0f 20 d3             	mov    %cr2,%ebx
801072bf:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801072c2:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801072c5:	83 c4 10             	add    $0x10,%esp
801072c8:	5b                   	pop    %ebx
801072c9:	5d                   	pop    %ebp
801072ca:	c3                   	ret    

801072cb <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801072cb:	55                   	push   %ebp
801072cc:	89 e5                	mov    %esp,%ebp
801072ce:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801072d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801072d8:	e9 c3 00 00 00       	jmp    801073a0 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801072dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072e0:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
801072e7:	89 c2                	mov    %eax,%edx
801072e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072ec:	66 89 14 c5 c0 2e 11 	mov    %dx,-0x7feed140(,%eax,8)
801072f3:	80 
801072f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801072f7:	66 c7 04 c5 c2 2e 11 	movw   $0x8,-0x7feed13e(,%eax,8)
801072fe:	80 08 00 
80107301:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107304:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
8010730b:	80 
8010730c:	83 e2 e0             	and    $0xffffffe0,%edx
8010730f:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
80107316:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107319:	0f b6 14 c5 c4 2e 11 	movzbl -0x7feed13c(,%eax,8),%edx
80107320:	80 
80107321:	83 e2 1f             	and    $0x1f,%edx
80107324:	88 14 c5 c4 2e 11 80 	mov    %dl,-0x7feed13c(,%eax,8)
8010732b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010732e:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107335:	80 
80107336:	83 e2 f0             	and    $0xfffffff0,%edx
80107339:	83 ca 0e             	or     $0xe,%edx
8010733c:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107346:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
8010734d:	80 
8010734e:	83 e2 ef             	and    $0xffffffef,%edx
80107351:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010735b:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107362:	80 
80107363:	83 e2 9f             	and    $0xffffff9f,%edx
80107366:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
8010736d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107370:	0f b6 14 c5 c5 2e 11 	movzbl -0x7feed13b(,%eax,8),%edx
80107377:	80 
80107378:	83 ca 80             	or     $0xffffff80,%edx
8010737b:	88 14 c5 c5 2e 11 80 	mov    %dl,-0x7feed13b(,%eax,8)
80107382:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107385:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
8010738c:	c1 e8 10             	shr    $0x10,%eax
8010738f:	89 c2                	mov    %eax,%edx
80107391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107394:	66 89 14 c5 c6 2e 11 	mov    %dx,-0x7feed13a(,%eax,8)
8010739b:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
8010739c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801073a0:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801073a7:	0f 8e 30 ff ff ff    	jle    801072dd <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801073ad:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
801073b2:	66 a3 c0 30 11 80    	mov    %ax,0x801130c0
801073b8:	66 c7 05 c2 30 11 80 	movw   $0x8,0x801130c2
801073bf:	08 00 
801073c1:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801073c8:	83 e0 e0             	and    $0xffffffe0,%eax
801073cb:	a2 c4 30 11 80       	mov    %al,0x801130c4
801073d0:	0f b6 05 c4 30 11 80 	movzbl 0x801130c4,%eax
801073d7:	83 e0 1f             	and    $0x1f,%eax
801073da:	a2 c4 30 11 80       	mov    %al,0x801130c4
801073df:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801073e6:	83 c8 0f             	or     $0xf,%eax
801073e9:	a2 c5 30 11 80       	mov    %al,0x801130c5
801073ee:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
801073f5:	83 e0 ef             	and    $0xffffffef,%eax
801073f8:	a2 c5 30 11 80       	mov    %al,0x801130c5
801073fd:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80107404:	83 c8 60             	or     $0x60,%eax
80107407:	a2 c5 30 11 80       	mov    %al,0x801130c5
8010740c:	0f b6 05 c5 30 11 80 	movzbl 0x801130c5,%eax
80107413:	83 c8 80             	or     $0xffffff80,%eax
80107416:	a2 c5 30 11 80       	mov    %al,0x801130c5
8010741b:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107420:	c1 e8 10             	shr    $0x10,%eax
80107423:	66 a3 c6 30 11 80    	mov    %ax,0x801130c6
  
  initlock(&tickslock, "time");
80107429:	c7 44 24 04 00 99 10 	movl   $0x80109900,0x4(%esp)
80107430:	80 
80107431:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107438:	e8 ed e5 ff ff       	call   80105a2a <initlock>
}
8010743d:	c9                   	leave  
8010743e:	c3                   	ret    

8010743f <idtinit>:

void
idtinit(void)
{
8010743f:	55                   	push   %ebp
80107440:	89 e5                	mov    %esp,%ebp
80107442:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107445:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010744c:	00 
8010744d:	c7 04 24 c0 2e 11 80 	movl   $0x80112ec0,(%esp)
80107454:	e8 33 fe ff ff       	call   8010728c <lidt>
}
80107459:	c9                   	leave  
8010745a:	c3                   	ret    

8010745b <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010745b:	55                   	push   %ebp
8010745c:	89 e5                	mov    %esp,%ebp
8010745e:	57                   	push   %edi
8010745f:	56                   	push   %esi
80107460:	53                   	push   %ebx
80107461:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107464:	8b 45 08             	mov    0x8(%ebp),%eax
80107467:	8b 40 30             	mov    0x30(%eax),%eax
8010746a:	83 f8 40             	cmp    $0x40,%eax
8010746d:	75 3e                	jne    801074ad <trap+0x52>
    if(proc->killed)
8010746f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107475:	8b 40 24             	mov    0x24(%eax),%eax
80107478:	85 c0                	test   %eax,%eax
8010747a:	74 05                	je     80107481 <trap+0x26>
      exit();
8010747c:	e8 7c de ff ff       	call   801052fd <exit>
    proc->tf = tf;
80107481:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107487:	8b 55 08             	mov    0x8(%ebp),%edx
8010748a:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
8010748d:	e8 35 ec ff ff       	call   801060c7 <syscall>
    if(proc->killed)
80107492:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107498:	8b 40 24             	mov    0x24(%eax),%eax
8010749b:	85 c0                	test   %eax,%eax
8010749d:	0f 84 34 02 00 00    	je     801076d7 <trap+0x27c>
      exit();
801074a3:	e8 55 de ff ff       	call   801052fd <exit>
    return;
801074a8:	e9 2a 02 00 00       	jmp    801076d7 <trap+0x27c>
  }

  switch(tf->trapno){
801074ad:	8b 45 08             	mov    0x8(%ebp),%eax
801074b0:	8b 40 30             	mov    0x30(%eax),%eax
801074b3:	83 e8 20             	sub    $0x20,%eax
801074b6:	83 f8 1f             	cmp    $0x1f,%eax
801074b9:	0f 87 bc 00 00 00    	ja     8010757b <trap+0x120>
801074bf:	8b 04 85 a8 99 10 80 	mov    -0x7fef6658(,%eax,4),%eax
801074c6:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801074c8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801074ce:	0f b6 00             	movzbl (%eax),%eax
801074d1:	84 c0                	test   %al,%al
801074d3:	75 31                	jne    80107506 <trap+0xab>
      acquire(&tickslock);
801074d5:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
801074dc:	e8 6a e5 ff ff       	call   80105a4b <acquire>
      ticks++;
801074e1:	a1 c0 36 11 80       	mov    0x801136c0,%eax
801074e6:	83 c0 01             	add    $0x1,%eax
801074e9:	a3 c0 36 11 80       	mov    %eax,0x801136c0
      wakeup(&ticks);
801074ee:	c7 04 24 c0 36 11 80 	movl   $0x801136c0,(%esp)
801074f5:	e8 4c e3 ff ff       	call   80105846 <wakeup>
      release(&tickslock);
801074fa:	c7 04 24 80 2e 11 80 	movl   $0x80112e80,(%esp)
80107501:	e8 a7 e5 ff ff       	call   80105aad <release>
    }
    lapiceoi();
80107506:	e8 86 c8 ff ff       	call   80103d91 <lapiceoi>
    break;
8010750b:	e9 41 01 00 00       	jmp    80107651 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107510:	e8 84 c0 ff ff       	call   80103599 <ideintr>
    lapiceoi();
80107515:	e8 77 c8 ff ff       	call   80103d91 <lapiceoi>
    break;
8010751a:	e9 32 01 00 00       	jmp    80107651 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010751f:	e8 4b c6 ff ff       	call   80103b6f <kbdintr>
    lapiceoi();
80107524:	e8 68 c8 ff ff       	call   80103d91 <lapiceoi>
    break;
80107529:	e9 23 01 00 00       	jmp    80107651 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010752e:	e8 a9 03 00 00       	call   801078dc <uartintr>
    lapiceoi();
80107533:	e8 59 c8 ff ff       	call   80103d91 <lapiceoi>
    break;
80107538:	e9 14 01 00 00       	jmp    80107651 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
8010753d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107540:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107543:	8b 45 08             	mov    0x8(%ebp),%eax
80107546:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010754a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010754d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107553:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107556:	0f b6 c0             	movzbl %al,%eax
80107559:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010755d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107561:	89 44 24 04          	mov    %eax,0x4(%esp)
80107565:	c7 04 24 08 99 10 80 	movl   $0x80109908,(%esp)
8010756c:	e8 30 8e ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80107571:	e8 1b c8 ff ff       	call   80103d91 <lapiceoi>
    break;
80107576:	e9 d6 00 00 00       	jmp    80107651 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
8010757b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107581:	85 c0                	test   %eax,%eax
80107583:	74 11                	je     80107596 <trap+0x13b>
80107585:	8b 45 08             	mov    0x8(%ebp),%eax
80107588:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010758c:	0f b7 c0             	movzwl %ax,%eax
8010758f:	83 e0 03             	and    $0x3,%eax
80107592:	85 c0                	test   %eax,%eax
80107594:	75 46                	jne    801075dc <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107596:	e8 1a fd ff ff       	call   801072b5 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010759b:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010759e:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801075a1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801075a8:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075ab:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
801075ae:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075b1:	8b 52 30             	mov    0x30(%edx),%edx
801075b4:	89 44 24 10          	mov    %eax,0x10(%esp)
801075b8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801075bc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801075c0:	89 54 24 04          	mov    %edx,0x4(%esp)
801075c4:	c7 04 24 2c 99 10 80 	movl   $0x8010992c,(%esp)
801075cb:	e8 d1 8d ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
801075d0:	c7 04 24 5e 99 10 80 	movl   $0x8010995e,(%esp)
801075d7:	e8 61 8f ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075dc:	e8 d4 fc ff ff       	call   801072b5 <rcr2>
801075e1:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075e3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075e6:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075e9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801075ef:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075f2:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075f5:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075f8:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801075fb:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801075fe:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107601:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107607:	83 c0 6c             	add    $0x6c,%eax
8010760a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010760d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107613:	8b 40 10             	mov    0x10(%eax),%eax
80107616:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010761a:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010761e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107622:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107626:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010762a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010762d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107631:	89 44 24 04          	mov    %eax,0x4(%esp)
80107635:	c7 04 24 64 99 10 80 	movl   $0x80109964,(%esp)
8010763c:	e8 60 8d ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107641:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107647:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010764e:	eb 01                	jmp    80107651 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107650:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107651:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107657:	85 c0                	test   %eax,%eax
80107659:	74 24                	je     8010767f <trap+0x224>
8010765b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107661:	8b 40 24             	mov    0x24(%eax),%eax
80107664:	85 c0                	test   %eax,%eax
80107666:	74 17                	je     8010767f <trap+0x224>
80107668:	8b 45 08             	mov    0x8(%ebp),%eax
8010766b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010766f:	0f b7 c0             	movzwl %ax,%eax
80107672:	83 e0 03             	and    $0x3,%eax
80107675:	83 f8 03             	cmp    $0x3,%eax
80107678:	75 05                	jne    8010767f <trap+0x224>
    exit();
8010767a:	e8 7e dc ff ff       	call   801052fd <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
8010767f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107685:	85 c0                	test   %eax,%eax
80107687:	74 1e                	je     801076a7 <trap+0x24c>
80107689:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010768f:	8b 40 0c             	mov    0xc(%eax),%eax
80107692:	83 f8 04             	cmp    $0x4,%eax
80107695:	75 10                	jne    801076a7 <trap+0x24c>
80107697:	8b 45 08             	mov    0x8(%ebp),%eax
8010769a:	8b 40 30             	mov    0x30(%eax),%eax
8010769d:	83 f8 20             	cmp    $0x20,%eax
801076a0:	75 05                	jne    801076a7 <trap+0x24c>
    yield();
801076a2:	e8 68 e0 ff ff       	call   8010570f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801076a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076ad:	85 c0                	test   %eax,%eax
801076af:	74 27                	je     801076d8 <trap+0x27d>
801076b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076b7:	8b 40 24             	mov    0x24(%eax),%eax
801076ba:	85 c0                	test   %eax,%eax
801076bc:	74 1a                	je     801076d8 <trap+0x27d>
801076be:	8b 45 08             	mov    0x8(%ebp),%eax
801076c1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801076c5:	0f b7 c0             	movzwl %ax,%eax
801076c8:	83 e0 03             	and    $0x3,%eax
801076cb:	83 f8 03             	cmp    $0x3,%eax
801076ce:	75 08                	jne    801076d8 <trap+0x27d>
    exit();
801076d0:	e8 28 dc ff ff       	call   801052fd <exit>
801076d5:	eb 01                	jmp    801076d8 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
801076d7:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
801076d8:	83 c4 3c             	add    $0x3c,%esp
801076db:	5b                   	pop    %ebx
801076dc:	5e                   	pop    %esi
801076dd:	5f                   	pop    %edi
801076de:	5d                   	pop    %ebp
801076df:	c3                   	ret    

801076e0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801076e0:	55                   	push   %ebp
801076e1:	89 e5                	mov    %esp,%ebp
801076e3:	53                   	push   %ebx
801076e4:	83 ec 14             	sub    $0x14,%esp
801076e7:	8b 45 08             	mov    0x8(%ebp),%eax
801076ea:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801076ee:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801076f2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801076f6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801076fa:	ec                   	in     (%dx),%al
801076fb:	89 c3                	mov    %eax,%ebx
801076fd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107700:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107704:	83 c4 14             	add    $0x14,%esp
80107707:	5b                   	pop    %ebx
80107708:	5d                   	pop    %ebp
80107709:	c3                   	ret    

8010770a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010770a:	55                   	push   %ebp
8010770b:	89 e5                	mov    %esp,%ebp
8010770d:	83 ec 08             	sub    $0x8,%esp
80107710:	8b 55 08             	mov    0x8(%ebp),%edx
80107713:	8b 45 0c             	mov    0xc(%ebp),%eax
80107716:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010771a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010771d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107721:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107725:	ee                   	out    %al,(%dx)
}
80107726:	c9                   	leave  
80107727:	c3                   	ret    

80107728 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107728:	55                   	push   %ebp
80107729:	89 e5                	mov    %esp,%ebp
8010772b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010772e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107735:	00 
80107736:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010773d:	e8 c8 ff ff ff       	call   8010770a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107742:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107749:	00 
8010774a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107751:	e8 b4 ff ff ff       	call   8010770a <outb>
  outb(COM1+0, 115200/9600);
80107756:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010775d:	00 
8010775e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107765:	e8 a0 ff ff ff       	call   8010770a <outb>
  outb(COM1+1, 0);
8010776a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107771:	00 
80107772:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107779:	e8 8c ff ff ff       	call   8010770a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010777e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107785:	00 
80107786:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
8010778d:	e8 78 ff ff ff       	call   8010770a <outb>
  outb(COM1+4, 0);
80107792:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107799:	00 
8010779a:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801077a1:	e8 64 ff ff ff       	call   8010770a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801077a6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801077ad:	00 
801077ae:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801077b5:	e8 50 ff ff ff       	call   8010770a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801077ba:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801077c1:	e8 1a ff ff ff       	call   801076e0 <inb>
801077c6:	3c ff                	cmp    $0xff,%al
801077c8:	74 6c                	je     80107836 <uartinit+0x10e>
    return;
  uart = 1;
801077ca:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801077d1:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801077d4:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801077db:	e8 00 ff ff ff       	call   801076e0 <inb>
  inb(COM1+0);
801077e0:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801077e7:	e8 f4 fe ff ff       	call   801076e0 <inb>
  picenable(IRQ_COM1);
801077ec:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801077f3:	e8 71 d1 ff ff       	call   80104969 <picenable>
  ioapicenable(IRQ_COM1, 0);
801077f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801077ff:	00 
80107800:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107807:	e8 12 c0 ff ff       	call   8010381e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010780c:	c7 45 f4 28 9a 10 80 	movl   $0x80109a28,-0xc(%ebp)
80107813:	eb 15                	jmp    8010782a <uartinit+0x102>
    uartputc(*p);
80107815:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107818:	0f b6 00             	movzbl (%eax),%eax
8010781b:	0f be c0             	movsbl %al,%eax
8010781e:	89 04 24             	mov    %eax,(%esp)
80107821:	e8 13 00 00 00       	call   80107839 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107826:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010782a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782d:	0f b6 00             	movzbl (%eax),%eax
80107830:	84 c0                	test   %al,%al
80107832:	75 e1                	jne    80107815 <uartinit+0xed>
80107834:	eb 01                	jmp    80107837 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107836:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107837:	c9                   	leave  
80107838:	c3                   	ret    

80107839 <uartputc>:

void
uartputc(int c)
{
80107839:	55                   	push   %ebp
8010783a:	89 e5                	mov    %esp,%ebp
8010783c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010783f:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107844:	85 c0                	test   %eax,%eax
80107846:	74 4d                	je     80107895 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107848:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010784f:	eb 10                	jmp    80107861 <uartputc+0x28>
    microdelay(10);
80107851:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107858:	e8 59 c5 ff ff       	call   80103db6 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010785d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107861:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107865:	7f 16                	jg     8010787d <uartputc+0x44>
80107867:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010786e:	e8 6d fe ff ff       	call   801076e0 <inb>
80107873:	0f b6 c0             	movzbl %al,%eax
80107876:	83 e0 20             	and    $0x20,%eax
80107879:	85 c0                	test   %eax,%eax
8010787b:	74 d4                	je     80107851 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
8010787d:	8b 45 08             	mov    0x8(%ebp),%eax
80107880:	0f b6 c0             	movzbl %al,%eax
80107883:	89 44 24 04          	mov    %eax,0x4(%esp)
80107887:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010788e:	e8 77 fe ff ff       	call   8010770a <outb>
80107893:	eb 01                	jmp    80107896 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107895:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107896:	c9                   	leave  
80107897:	c3                   	ret    

80107898 <uartgetc>:

static int
uartgetc(void)
{
80107898:	55                   	push   %ebp
80107899:	89 e5                	mov    %esp,%ebp
8010789b:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
8010789e:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
801078a3:	85 c0                	test   %eax,%eax
801078a5:	75 07                	jne    801078ae <uartgetc+0x16>
    return -1;
801078a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078ac:	eb 2c                	jmp    801078da <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801078ae:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801078b5:	e8 26 fe ff ff       	call   801076e0 <inb>
801078ba:	0f b6 c0             	movzbl %al,%eax
801078bd:	83 e0 01             	and    $0x1,%eax
801078c0:	85 c0                	test   %eax,%eax
801078c2:	75 07                	jne    801078cb <uartgetc+0x33>
    return -1;
801078c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078c9:	eb 0f                	jmp    801078da <uartgetc+0x42>
  return inb(COM1+0);
801078cb:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801078d2:	e8 09 fe ff ff       	call   801076e0 <inb>
801078d7:	0f b6 c0             	movzbl %al,%eax
}
801078da:	c9                   	leave  
801078db:	c3                   	ret    

801078dc <uartintr>:

void
uartintr(void)
{
801078dc:	55                   	push   %ebp
801078dd:	89 e5                	mov    %esp,%ebp
801078df:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
801078e2:	c7 04 24 98 78 10 80 	movl   $0x80107898,(%esp)
801078e9:	e8 bf 8e ff ff       	call   801007ad <consoleintr>
}
801078ee:	c9                   	leave  
801078ef:	c3                   	ret    

801078f0 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801078f0:	6a 00                	push   $0x0
  pushl $0
801078f2:	6a 00                	push   $0x0
  jmp alltraps
801078f4:	e9 67 f9 ff ff       	jmp    80107260 <alltraps>

801078f9 <vector1>:
.globl vector1
vector1:
  pushl $0
801078f9:	6a 00                	push   $0x0
  pushl $1
801078fb:	6a 01                	push   $0x1
  jmp alltraps
801078fd:	e9 5e f9 ff ff       	jmp    80107260 <alltraps>

80107902 <vector2>:
.globl vector2
vector2:
  pushl $0
80107902:	6a 00                	push   $0x0
  pushl $2
80107904:	6a 02                	push   $0x2
  jmp alltraps
80107906:	e9 55 f9 ff ff       	jmp    80107260 <alltraps>

8010790b <vector3>:
.globl vector3
vector3:
  pushl $0
8010790b:	6a 00                	push   $0x0
  pushl $3
8010790d:	6a 03                	push   $0x3
  jmp alltraps
8010790f:	e9 4c f9 ff ff       	jmp    80107260 <alltraps>

80107914 <vector4>:
.globl vector4
vector4:
  pushl $0
80107914:	6a 00                	push   $0x0
  pushl $4
80107916:	6a 04                	push   $0x4
  jmp alltraps
80107918:	e9 43 f9 ff ff       	jmp    80107260 <alltraps>

8010791d <vector5>:
.globl vector5
vector5:
  pushl $0
8010791d:	6a 00                	push   $0x0
  pushl $5
8010791f:	6a 05                	push   $0x5
  jmp alltraps
80107921:	e9 3a f9 ff ff       	jmp    80107260 <alltraps>

80107926 <vector6>:
.globl vector6
vector6:
  pushl $0
80107926:	6a 00                	push   $0x0
  pushl $6
80107928:	6a 06                	push   $0x6
  jmp alltraps
8010792a:	e9 31 f9 ff ff       	jmp    80107260 <alltraps>

8010792f <vector7>:
.globl vector7
vector7:
  pushl $0
8010792f:	6a 00                	push   $0x0
  pushl $7
80107931:	6a 07                	push   $0x7
  jmp alltraps
80107933:	e9 28 f9 ff ff       	jmp    80107260 <alltraps>

80107938 <vector8>:
.globl vector8
vector8:
  pushl $8
80107938:	6a 08                	push   $0x8
  jmp alltraps
8010793a:	e9 21 f9 ff ff       	jmp    80107260 <alltraps>

8010793f <vector9>:
.globl vector9
vector9:
  pushl $0
8010793f:	6a 00                	push   $0x0
  pushl $9
80107941:	6a 09                	push   $0x9
  jmp alltraps
80107943:	e9 18 f9 ff ff       	jmp    80107260 <alltraps>

80107948 <vector10>:
.globl vector10
vector10:
  pushl $10
80107948:	6a 0a                	push   $0xa
  jmp alltraps
8010794a:	e9 11 f9 ff ff       	jmp    80107260 <alltraps>

8010794f <vector11>:
.globl vector11
vector11:
  pushl $11
8010794f:	6a 0b                	push   $0xb
  jmp alltraps
80107951:	e9 0a f9 ff ff       	jmp    80107260 <alltraps>

80107956 <vector12>:
.globl vector12
vector12:
  pushl $12
80107956:	6a 0c                	push   $0xc
  jmp alltraps
80107958:	e9 03 f9 ff ff       	jmp    80107260 <alltraps>

8010795d <vector13>:
.globl vector13
vector13:
  pushl $13
8010795d:	6a 0d                	push   $0xd
  jmp alltraps
8010795f:	e9 fc f8 ff ff       	jmp    80107260 <alltraps>

80107964 <vector14>:
.globl vector14
vector14:
  pushl $14
80107964:	6a 0e                	push   $0xe
  jmp alltraps
80107966:	e9 f5 f8 ff ff       	jmp    80107260 <alltraps>

8010796b <vector15>:
.globl vector15
vector15:
  pushl $0
8010796b:	6a 00                	push   $0x0
  pushl $15
8010796d:	6a 0f                	push   $0xf
  jmp alltraps
8010796f:	e9 ec f8 ff ff       	jmp    80107260 <alltraps>

80107974 <vector16>:
.globl vector16
vector16:
  pushl $0
80107974:	6a 00                	push   $0x0
  pushl $16
80107976:	6a 10                	push   $0x10
  jmp alltraps
80107978:	e9 e3 f8 ff ff       	jmp    80107260 <alltraps>

8010797d <vector17>:
.globl vector17
vector17:
  pushl $17
8010797d:	6a 11                	push   $0x11
  jmp alltraps
8010797f:	e9 dc f8 ff ff       	jmp    80107260 <alltraps>

80107984 <vector18>:
.globl vector18
vector18:
  pushl $0
80107984:	6a 00                	push   $0x0
  pushl $18
80107986:	6a 12                	push   $0x12
  jmp alltraps
80107988:	e9 d3 f8 ff ff       	jmp    80107260 <alltraps>

8010798d <vector19>:
.globl vector19
vector19:
  pushl $0
8010798d:	6a 00                	push   $0x0
  pushl $19
8010798f:	6a 13                	push   $0x13
  jmp alltraps
80107991:	e9 ca f8 ff ff       	jmp    80107260 <alltraps>

80107996 <vector20>:
.globl vector20
vector20:
  pushl $0
80107996:	6a 00                	push   $0x0
  pushl $20
80107998:	6a 14                	push   $0x14
  jmp alltraps
8010799a:	e9 c1 f8 ff ff       	jmp    80107260 <alltraps>

8010799f <vector21>:
.globl vector21
vector21:
  pushl $0
8010799f:	6a 00                	push   $0x0
  pushl $21
801079a1:	6a 15                	push   $0x15
  jmp alltraps
801079a3:	e9 b8 f8 ff ff       	jmp    80107260 <alltraps>

801079a8 <vector22>:
.globl vector22
vector22:
  pushl $0
801079a8:	6a 00                	push   $0x0
  pushl $22
801079aa:	6a 16                	push   $0x16
  jmp alltraps
801079ac:	e9 af f8 ff ff       	jmp    80107260 <alltraps>

801079b1 <vector23>:
.globl vector23
vector23:
  pushl $0
801079b1:	6a 00                	push   $0x0
  pushl $23
801079b3:	6a 17                	push   $0x17
  jmp alltraps
801079b5:	e9 a6 f8 ff ff       	jmp    80107260 <alltraps>

801079ba <vector24>:
.globl vector24
vector24:
  pushl $0
801079ba:	6a 00                	push   $0x0
  pushl $24
801079bc:	6a 18                	push   $0x18
  jmp alltraps
801079be:	e9 9d f8 ff ff       	jmp    80107260 <alltraps>

801079c3 <vector25>:
.globl vector25
vector25:
  pushl $0
801079c3:	6a 00                	push   $0x0
  pushl $25
801079c5:	6a 19                	push   $0x19
  jmp alltraps
801079c7:	e9 94 f8 ff ff       	jmp    80107260 <alltraps>

801079cc <vector26>:
.globl vector26
vector26:
  pushl $0
801079cc:	6a 00                	push   $0x0
  pushl $26
801079ce:	6a 1a                	push   $0x1a
  jmp alltraps
801079d0:	e9 8b f8 ff ff       	jmp    80107260 <alltraps>

801079d5 <vector27>:
.globl vector27
vector27:
  pushl $0
801079d5:	6a 00                	push   $0x0
  pushl $27
801079d7:	6a 1b                	push   $0x1b
  jmp alltraps
801079d9:	e9 82 f8 ff ff       	jmp    80107260 <alltraps>

801079de <vector28>:
.globl vector28
vector28:
  pushl $0
801079de:	6a 00                	push   $0x0
  pushl $28
801079e0:	6a 1c                	push   $0x1c
  jmp alltraps
801079e2:	e9 79 f8 ff ff       	jmp    80107260 <alltraps>

801079e7 <vector29>:
.globl vector29
vector29:
  pushl $0
801079e7:	6a 00                	push   $0x0
  pushl $29
801079e9:	6a 1d                	push   $0x1d
  jmp alltraps
801079eb:	e9 70 f8 ff ff       	jmp    80107260 <alltraps>

801079f0 <vector30>:
.globl vector30
vector30:
  pushl $0
801079f0:	6a 00                	push   $0x0
  pushl $30
801079f2:	6a 1e                	push   $0x1e
  jmp alltraps
801079f4:	e9 67 f8 ff ff       	jmp    80107260 <alltraps>

801079f9 <vector31>:
.globl vector31
vector31:
  pushl $0
801079f9:	6a 00                	push   $0x0
  pushl $31
801079fb:	6a 1f                	push   $0x1f
  jmp alltraps
801079fd:	e9 5e f8 ff ff       	jmp    80107260 <alltraps>

80107a02 <vector32>:
.globl vector32
vector32:
  pushl $0
80107a02:	6a 00                	push   $0x0
  pushl $32
80107a04:	6a 20                	push   $0x20
  jmp alltraps
80107a06:	e9 55 f8 ff ff       	jmp    80107260 <alltraps>

80107a0b <vector33>:
.globl vector33
vector33:
  pushl $0
80107a0b:	6a 00                	push   $0x0
  pushl $33
80107a0d:	6a 21                	push   $0x21
  jmp alltraps
80107a0f:	e9 4c f8 ff ff       	jmp    80107260 <alltraps>

80107a14 <vector34>:
.globl vector34
vector34:
  pushl $0
80107a14:	6a 00                	push   $0x0
  pushl $34
80107a16:	6a 22                	push   $0x22
  jmp alltraps
80107a18:	e9 43 f8 ff ff       	jmp    80107260 <alltraps>

80107a1d <vector35>:
.globl vector35
vector35:
  pushl $0
80107a1d:	6a 00                	push   $0x0
  pushl $35
80107a1f:	6a 23                	push   $0x23
  jmp alltraps
80107a21:	e9 3a f8 ff ff       	jmp    80107260 <alltraps>

80107a26 <vector36>:
.globl vector36
vector36:
  pushl $0
80107a26:	6a 00                	push   $0x0
  pushl $36
80107a28:	6a 24                	push   $0x24
  jmp alltraps
80107a2a:	e9 31 f8 ff ff       	jmp    80107260 <alltraps>

80107a2f <vector37>:
.globl vector37
vector37:
  pushl $0
80107a2f:	6a 00                	push   $0x0
  pushl $37
80107a31:	6a 25                	push   $0x25
  jmp alltraps
80107a33:	e9 28 f8 ff ff       	jmp    80107260 <alltraps>

80107a38 <vector38>:
.globl vector38
vector38:
  pushl $0
80107a38:	6a 00                	push   $0x0
  pushl $38
80107a3a:	6a 26                	push   $0x26
  jmp alltraps
80107a3c:	e9 1f f8 ff ff       	jmp    80107260 <alltraps>

80107a41 <vector39>:
.globl vector39
vector39:
  pushl $0
80107a41:	6a 00                	push   $0x0
  pushl $39
80107a43:	6a 27                	push   $0x27
  jmp alltraps
80107a45:	e9 16 f8 ff ff       	jmp    80107260 <alltraps>

80107a4a <vector40>:
.globl vector40
vector40:
  pushl $0
80107a4a:	6a 00                	push   $0x0
  pushl $40
80107a4c:	6a 28                	push   $0x28
  jmp alltraps
80107a4e:	e9 0d f8 ff ff       	jmp    80107260 <alltraps>

80107a53 <vector41>:
.globl vector41
vector41:
  pushl $0
80107a53:	6a 00                	push   $0x0
  pushl $41
80107a55:	6a 29                	push   $0x29
  jmp alltraps
80107a57:	e9 04 f8 ff ff       	jmp    80107260 <alltraps>

80107a5c <vector42>:
.globl vector42
vector42:
  pushl $0
80107a5c:	6a 00                	push   $0x0
  pushl $42
80107a5e:	6a 2a                	push   $0x2a
  jmp alltraps
80107a60:	e9 fb f7 ff ff       	jmp    80107260 <alltraps>

80107a65 <vector43>:
.globl vector43
vector43:
  pushl $0
80107a65:	6a 00                	push   $0x0
  pushl $43
80107a67:	6a 2b                	push   $0x2b
  jmp alltraps
80107a69:	e9 f2 f7 ff ff       	jmp    80107260 <alltraps>

80107a6e <vector44>:
.globl vector44
vector44:
  pushl $0
80107a6e:	6a 00                	push   $0x0
  pushl $44
80107a70:	6a 2c                	push   $0x2c
  jmp alltraps
80107a72:	e9 e9 f7 ff ff       	jmp    80107260 <alltraps>

80107a77 <vector45>:
.globl vector45
vector45:
  pushl $0
80107a77:	6a 00                	push   $0x0
  pushl $45
80107a79:	6a 2d                	push   $0x2d
  jmp alltraps
80107a7b:	e9 e0 f7 ff ff       	jmp    80107260 <alltraps>

80107a80 <vector46>:
.globl vector46
vector46:
  pushl $0
80107a80:	6a 00                	push   $0x0
  pushl $46
80107a82:	6a 2e                	push   $0x2e
  jmp alltraps
80107a84:	e9 d7 f7 ff ff       	jmp    80107260 <alltraps>

80107a89 <vector47>:
.globl vector47
vector47:
  pushl $0
80107a89:	6a 00                	push   $0x0
  pushl $47
80107a8b:	6a 2f                	push   $0x2f
  jmp alltraps
80107a8d:	e9 ce f7 ff ff       	jmp    80107260 <alltraps>

80107a92 <vector48>:
.globl vector48
vector48:
  pushl $0
80107a92:	6a 00                	push   $0x0
  pushl $48
80107a94:	6a 30                	push   $0x30
  jmp alltraps
80107a96:	e9 c5 f7 ff ff       	jmp    80107260 <alltraps>

80107a9b <vector49>:
.globl vector49
vector49:
  pushl $0
80107a9b:	6a 00                	push   $0x0
  pushl $49
80107a9d:	6a 31                	push   $0x31
  jmp alltraps
80107a9f:	e9 bc f7 ff ff       	jmp    80107260 <alltraps>

80107aa4 <vector50>:
.globl vector50
vector50:
  pushl $0
80107aa4:	6a 00                	push   $0x0
  pushl $50
80107aa6:	6a 32                	push   $0x32
  jmp alltraps
80107aa8:	e9 b3 f7 ff ff       	jmp    80107260 <alltraps>

80107aad <vector51>:
.globl vector51
vector51:
  pushl $0
80107aad:	6a 00                	push   $0x0
  pushl $51
80107aaf:	6a 33                	push   $0x33
  jmp alltraps
80107ab1:	e9 aa f7 ff ff       	jmp    80107260 <alltraps>

80107ab6 <vector52>:
.globl vector52
vector52:
  pushl $0
80107ab6:	6a 00                	push   $0x0
  pushl $52
80107ab8:	6a 34                	push   $0x34
  jmp alltraps
80107aba:	e9 a1 f7 ff ff       	jmp    80107260 <alltraps>

80107abf <vector53>:
.globl vector53
vector53:
  pushl $0
80107abf:	6a 00                	push   $0x0
  pushl $53
80107ac1:	6a 35                	push   $0x35
  jmp alltraps
80107ac3:	e9 98 f7 ff ff       	jmp    80107260 <alltraps>

80107ac8 <vector54>:
.globl vector54
vector54:
  pushl $0
80107ac8:	6a 00                	push   $0x0
  pushl $54
80107aca:	6a 36                	push   $0x36
  jmp alltraps
80107acc:	e9 8f f7 ff ff       	jmp    80107260 <alltraps>

80107ad1 <vector55>:
.globl vector55
vector55:
  pushl $0
80107ad1:	6a 00                	push   $0x0
  pushl $55
80107ad3:	6a 37                	push   $0x37
  jmp alltraps
80107ad5:	e9 86 f7 ff ff       	jmp    80107260 <alltraps>

80107ada <vector56>:
.globl vector56
vector56:
  pushl $0
80107ada:	6a 00                	push   $0x0
  pushl $56
80107adc:	6a 38                	push   $0x38
  jmp alltraps
80107ade:	e9 7d f7 ff ff       	jmp    80107260 <alltraps>

80107ae3 <vector57>:
.globl vector57
vector57:
  pushl $0
80107ae3:	6a 00                	push   $0x0
  pushl $57
80107ae5:	6a 39                	push   $0x39
  jmp alltraps
80107ae7:	e9 74 f7 ff ff       	jmp    80107260 <alltraps>

80107aec <vector58>:
.globl vector58
vector58:
  pushl $0
80107aec:	6a 00                	push   $0x0
  pushl $58
80107aee:	6a 3a                	push   $0x3a
  jmp alltraps
80107af0:	e9 6b f7 ff ff       	jmp    80107260 <alltraps>

80107af5 <vector59>:
.globl vector59
vector59:
  pushl $0
80107af5:	6a 00                	push   $0x0
  pushl $59
80107af7:	6a 3b                	push   $0x3b
  jmp alltraps
80107af9:	e9 62 f7 ff ff       	jmp    80107260 <alltraps>

80107afe <vector60>:
.globl vector60
vector60:
  pushl $0
80107afe:	6a 00                	push   $0x0
  pushl $60
80107b00:	6a 3c                	push   $0x3c
  jmp alltraps
80107b02:	e9 59 f7 ff ff       	jmp    80107260 <alltraps>

80107b07 <vector61>:
.globl vector61
vector61:
  pushl $0
80107b07:	6a 00                	push   $0x0
  pushl $61
80107b09:	6a 3d                	push   $0x3d
  jmp alltraps
80107b0b:	e9 50 f7 ff ff       	jmp    80107260 <alltraps>

80107b10 <vector62>:
.globl vector62
vector62:
  pushl $0
80107b10:	6a 00                	push   $0x0
  pushl $62
80107b12:	6a 3e                	push   $0x3e
  jmp alltraps
80107b14:	e9 47 f7 ff ff       	jmp    80107260 <alltraps>

80107b19 <vector63>:
.globl vector63
vector63:
  pushl $0
80107b19:	6a 00                	push   $0x0
  pushl $63
80107b1b:	6a 3f                	push   $0x3f
  jmp alltraps
80107b1d:	e9 3e f7 ff ff       	jmp    80107260 <alltraps>

80107b22 <vector64>:
.globl vector64
vector64:
  pushl $0
80107b22:	6a 00                	push   $0x0
  pushl $64
80107b24:	6a 40                	push   $0x40
  jmp alltraps
80107b26:	e9 35 f7 ff ff       	jmp    80107260 <alltraps>

80107b2b <vector65>:
.globl vector65
vector65:
  pushl $0
80107b2b:	6a 00                	push   $0x0
  pushl $65
80107b2d:	6a 41                	push   $0x41
  jmp alltraps
80107b2f:	e9 2c f7 ff ff       	jmp    80107260 <alltraps>

80107b34 <vector66>:
.globl vector66
vector66:
  pushl $0
80107b34:	6a 00                	push   $0x0
  pushl $66
80107b36:	6a 42                	push   $0x42
  jmp alltraps
80107b38:	e9 23 f7 ff ff       	jmp    80107260 <alltraps>

80107b3d <vector67>:
.globl vector67
vector67:
  pushl $0
80107b3d:	6a 00                	push   $0x0
  pushl $67
80107b3f:	6a 43                	push   $0x43
  jmp alltraps
80107b41:	e9 1a f7 ff ff       	jmp    80107260 <alltraps>

80107b46 <vector68>:
.globl vector68
vector68:
  pushl $0
80107b46:	6a 00                	push   $0x0
  pushl $68
80107b48:	6a 44                	push   $0x44
  jmp alltraps
80107b4a:	e9 11 f7 ff ff       	jmp    80107260 <alltraps>

80107b4f <vector69>:
.globl vector69
vector69:
  pushl $0
80107b4f:	6a 00                	push   $0x0
  pushl $69
80107b51:	6a 45                	push   $0x45
  jmp alltraps
80107b53:	e9 08 f7 ff ff       	jmp    80107260 <alltraps>

80107b58 <vector70>:
.globl vector70
vector70:
  pushl $0
80107b58:	6a 00                	push   $0x0
  pushl $70
80107b5a:	6a 46                	push   $0x46
  jmp alltraps
80107b5c:	e9 ff f6 ff ff       	jmp    80107260 <alltraps>

80107b61 <vector71>:
.globl vector71
vector71:
  pushl $0
80107b61:	6a 00                	push   $0x0
  pushl $71
80107b63:	6a 47                	push   $0x47
  jmp alltraps
80107b65:	e9 f6 f6 ff ff       	jmp    80107260 <alltraps>

80107b6a <vector72>:
.globl vector72
vector72:
  pushl $0
80107b6a:	6a 00                	push   $0x0
  pushl $72
80107b6c:	6a 48                	push   $0x48
  jmp alltraps
80107b6e:	e9 ed f6 ff ff       	jmp    80107260 <alltraps>

80107b73 <vector73>:
.globl vector73
vector73:
  pushl $0
80107b73:	6a 00                	push   $0x0
  pushl $73
80107b75:	6a 49                	push   $0x49
  jmp alltraps
80107b77:	e9 e4 f6 ff ff       	jmp    80107260 <alltraps>

80107b7c <vector74>:
.globl vector74
vector74:
  pushl $0
80107b7c:	6a 00                	push   $0x0
  pushl $74
80107b7e:	6a 4a                	push   $0x4a
  jmp alltraps
80107b80:	e9 db f6 ff ff       	jmp    80107260 <alltraps>

80107b85 <vector75>:
.globl vector75
vector75:
  pushl $0
80107b85:	6a 00                	push   $0x0
  pushl $75
80107b87:	6a 4b                	push   $0x4b
  jmp alltraps
80107b89:	e9 d2 f6 ff ff       	jmp    80107260 <alltraps>

80107b8e <vector76>:
.globl vector76
vector76:
  pushl $0
80107b8e:	6a 00                	push   $0x0
  pushl $76
80107b90:	6a 4c                	push   $0x4c
  jmp alltraps
80107b92:	e9 c9 f6 ff ff       	jmp    80107260 <alltraps>

80107b97 <vector77>:
.globl vector77
vector77:
  pushl $0
80107b97:	6a 00                	push   $0x0
  pushl $77
80107b99:	6a 4d                	push   $0x4d
  jmp alltraps
80107b9b:	e9 c0 f6 ff ff       	jmp    80107260 <alltraps>

80107ba0 <vector78>:
.globl vector78
vector78:
  pushl $0
80107ba0:	6a 00                	push   $0x0
  pushl $78
80107ba2:	6a 4e                	push   $0x4e
  jmp alltraps
80107ba4:	e9 b7 f6 ff ff       	jmp    80107260 <alltraps>

80107ba9 <vector79>:
.globl vector79
vector79:
  pushl $0
80107ba9:	6a 00                	push   $0x0
  pushl $79
80107bab:	6a 4f                	push   $0x4f
  jmp alltraps
80107bad:	e9 ae f6 ff ff       	jmp    80107260 <alltraps>

80107bb2 <vector80>:
.globl vector80
vector80:
  pushl $0
80107bb2:	6a 00                	push   $0x0
  pushl $80
80107bb4:	6a 50                	push   $0x50
  jmp alltraps
80107bb6:	e9 a5 f6 ff ff       	jmp    80107260 <alltraps>

80107bbb <vector81>:
.globl vector81
vector81:
  pushl $0
80107bbb:	6a 00                	push   $0x0
  pushl $81
80107bbd:	6a 51                	push   $0x51
  jmp alltraps
80107bbf:	e9 9c f6 ff ff       	jmp    80107260 <alltraps>

80107bc4 <vector82>:
.globl vector82
vector82:
  pushl $0
80107bc4:	6a 00                	push   $0x0
  pushl $82
80107bc6:	6a 52                	push   $0x52
  jmp alltraps
80107bc8:	e9 93 f6 ff ff       	jmp    80107260 <alltraps>

80107bcd <vector83>:
.globl vector83
vector83:
  pushl $0
80107bcd:	6a 00                	push   $0x0
  pushl $83
80107bcf:	6a 53                	push   $0x53
  jmp alltraps
80107bd1:	e9 8a f6 ff ff       	jmp    80107260 <alltraps>

80107bd6 <vector84>:
.globl vector84
vector84:
  pushl $0
80107bd6:	6a 00                	push   $0x0
  pushl $84
80107bd8:	6a 54                	push   $0x54
  jmp alltraps
80107bda:	e9 81 f6 ff ff       	jmp    80107260 <alltraps>

80107bdf <vector85>:
.globl vector85
vector85:
  pushl $0
80107bdf:	6a 00                	push   $0x0
  pushl $85
80107be1:	6a 55                	push   $0x55
  jmp alltraps
80107be3:	e9 78 f6 ff ff       	jmp    80107260 <alltraps>

80107be8 <vector86>:
.globl vector86
vector86:
  pushl $0
80107be8:	6a 00                	push   $0x0
  pushl $86
80107bea:	6a 56                	push   $0x56
  jmp alltraps
80107bec:	e9 6f f6 ff ff       	jmp    80107260 <alltraps>

80107bf1 <vector87>:
.globl vector87
vector87:
  pushl $0
80107bf1:	6a 00                	push   $0x0
  pushl $87
80107bf3:	6a 57                	push   $0x57
  jmp alltraps
80107bf5:	e9 66 f6 ff ff       	jmp    80107260 <alltraps>

80107bfa <vector88>:
.globl vector88
vector88:
  pushl $0
80107bfa:	6a 00                	push   $0x0
  pushl $88
80107bfc:	6a 58                	push   $0x58
  jmp alltraps
80107bfe:	e9 5d f6 ff ff       	jmp    80107260 <alltraps>

80107c03 <vector89>:
.globl vector89
vector89:
  pushl $0
80107c03:	6a 00                	push   $0x0
  pushl $89
80107c05:	6a 59                	push   $0x59
  jmp alltraps
80107c07:	e9 54 f6 ff ff       	jmp    80107260 <alltraps>

80107c0c <vector90>:
.globl vector90
vector90:
  pushl $0
80107c0c:	6a 00                	push   $0x0
  pushl $90
80107c0e:	6a 5a                	push   $0x5a
  jmp alltraps
80107c10:	e9 4b f6 ff ff       	jmp    80107260 <alltraps>

80107c15 <vector91>:
.globl vector91
vector91:
  pushl $0
80107c15:	6a 00                	push   $0x0
  pushl $91
80107c17:	6a 5b                	push   $0x5b
  jmp alltraps
80107c19:	e9 42 f6 ff ff       	jmp    80107260 <alltraps>

80107c1e <vector92>:
.globl vector92
vector92:
  pushl $0
80107c1e:	6a 00                	push   $0x0
  pushl $92
80107c20:	6a 5c                	push   $0x5c
  jmp alltraps
80107c22:	e9 39 f6 ff ff       	jmp    80107260 <alltraps>

80107c27 <vector93>:
.globl vector93
vector93:
  pushl $0
80107c27:	6a 00                	push   $0x0
  pushl $93
80107c29:	6a 5d                	push   $0x5d
  jmp alltraps
80107c2b:	e9 30 f6 ff ff       	jmp    80107260 <alltraps>

80107c30 <vector94>:
.globl vector94
vector94:
  pushl $0
80107c30:	6a 00                	push   $0x0
  pushl $94
80107c32:	6a 5e                	push   $0x5e
  jmp alltraps
80107c34:	e9 27 f6 ff ff       	jmp    80107260 <alltraps>

80107c39 <vector95>:
.globl vector95
vector95:
  pushl $0
80107c39:	6a 00                	push   $0x0
  pushl $95
80107c3b:	6a 5f                	push   $0x5f
  jmp alltraps
80107c3d:	e9 1e f6 ff ff       	jmp    80107260 <alltraps>

80107c42 <vector96>:
.globl vector96
vector96:
  pushl $0
80107c42:	6a 00                	push   $0x0
  pushl $96
80107c44:	6a 60                	push   $0x60
  jmp alltraps
80107c46:	e9 15 f6 ff ff       	jmp    80107260 <alltraps>

80107c4b <vector97>:
.globl vector97
vector97:
  pushl $0
80107c4b:	6a 00                	push   $0x0
  pushl $97
80107c4d:	6a 61                	push   $0x61
  jmp alltraps
80107c4f:	e9 0c f6 ff ff       	jmp    80107260 <alltraps>

80107c54 <vector98>:
.globl vector98
vector98:
  pushl $0
80107c54:	6a 00                	push   $0x0
  pushl $98
80107c56:	6a 62                	push   $0x62
  jmp alltraps
80107c58:	e9 03 f6 ff ff       	jmp    80107260 <alltraps>

80107c5d <vector99>:
.globl vector99
vector99:
  pushl $0
80107c5d:	6a 00                	push   $0x0
  pushl $99
80107c5f:	6a 63                	push   $0x63
  jmp alltraps
80107c61:	e9 fa f5 ff ff       	jmp    80107260 <alltraps>

80107c66 <vector100>:
.globl vector100
vector100:
  pushl $0
80107c66:	6a 00                	push   $0x0
  pushl $100
80107c68:	6a 64                	push   $0x64
  jmp alltraps
80107c6a:	e9 f1 f5 ff ff       	jmp    80107260 <alltraps>

80107c6f <vector101>:
.globl vector101
vector101:
  pushl $0
80107c6f:	6a 00                	push   $0x0
  pushl $101
80107c71:	6a 65                	push   $0x65
  jmp alltraps
80107c73:	e9 e8 f5 ff ff       	jmp    80107260 <alltraps>

80107c78 <vector102>:
.globl vector102
vector102:
  pushl $0
80107c78:	6a 00                	push   $0x0
  pushl $102
80107c7a:	6a 66                	push   $0x66
  jmp alltraps
80107c7c:	e9 df f5 ff ff       	jmp    80107260 <alltraps>

80107c81 <vector103>:
.globl vector103
vector103:
  pushl $0
80107c81:	6a 00                	push   $0x0
  pushl $103
80107c83:	6a 67                	push   $0x67
  jmp alltraps
80107c85:	e9 d6 f5 ff ff       	jmp    80107260 <alltraps>

80107c8a <vector104>:
.globl vector104
vector104:
  pushl $0
80107c8a:	6a 00                	push   $0x0
  pushl $104
80107c8c:	6a 68                	push   $0x68
  jmp alltraps
80107c8e:	e9 cd f5 ff ff       	jmp    80107260 <alltraps>

80107c93 <vector105>:
.globl vector105
vector105:
  pushl $0
80107c93:	6a 00                	push   $0x0
  pushl $105
80107c95:	6a 69                	push   $0x69
  jmp alltraps
80107c97:	e9 c4 f5 ff ff       	jmp    80107260 <alltraps>

80107c9c <vector106>:
.globl vector106
vector106:
  pushl $0
80107c9c:	6a 00                	push   $0x0
  pushl $106
80107c9e:	6a 6a                	push   $0x6a
  jmp alltraps
80107ca0:	e9 bb f5 ff ff       	jmp    80107260 <alltraps>

80107ca5 <vector107>:
.globl vector107
vector107:
  pushl $0
80107ca5:	6a 00                	push   $0x0
  pushl $107
80107ca7:	6a 6b                	push   $0x6b
  jmp alltraps
80107ca9:	e9 b2 f5 ff ff       	jmp    80107260 <alltraps>

80107cae <vector108>:
.globl vector108
vector108:
  pushl $0
80107cae:	6a 00                	push   $0x0
  pushl $108
80107cb0:	6a 6c                	push   $0x6c
  jmp alltraps
80107cb2:	e9 a9 f5 ff ff       	jmp    80107260 <alltraps>

80107cb7 <vector109>:
.globl vector109
vector109:
  pushl $0
80107cb7:	6a 00                	push   $0x0
  pushl $109
80107cb9:	6a 6d                	push   $0x6d
  jmp alltraps
80107cbb:	e9 a0 f5 ff ff       	jmp    80107260 <alltraps>

80107cc0 <vector110>:
.globl vector110
vector110:
  pushl $0
80107cc0:	6a 00                	push   $0x0
  pushl $110
80107cc2:	6a 6e                	push   $0x6e
  jmp alltraps
80107cc4:	e9 97 f5 ff ff       	jmp    80107260 <alltraps>

80107cc9 <vector111>:
.globl vector111
vector111:
  pushl $0
80107cc9:	6a 00                	push   $0x0
  pushl $111
80107ccb:	6a 6f                	push   $0x6f
  jmp alltraps
80107ccd:	e9 8e f5 ff ff       	jmp    80107260 <alltraps>

80107cd2 <vector112>:
.globl vector112
vector112:
  pushl $0
80107cd2:	6a 00                	push   $0x0
  pushl $112
80107cd4:	6a 70                	push   $0x70
  jmp alltraps
80107cd6:	e9 85 f5 ff ff       	jmp    80107260 <alltraps>

80107cdb <vector113>:
.globl vector113
vector113:
  pushl $0
80107cdb:	6a 00                	push   $0x0
  pushl $113
80107cdd:	6a 71                	push   $0x71
  jmp alltraps
80107cdf:	e9 7c f5 ff ff       	jmp    80107260 <alltraps>

80107ce4 <vector114>:
.globl vector114
vector114:
  pushl $0
80107ce4:	6a 00                	push   $0x0
  pushl $114
80107ce6:	6a 72                	push   $0x72
  jmp alltraps
80107ce8:	e9 73 f5 ff ff       	jmp    80107260 <alltraps>

80107ced <vector115>:
.globl vector115
vector115:
  pushl $0
80107ced:	6a 00                	push   $0x0
  pushl $115
80107cef:	6a 73                	push   $0x73
  jmp alltraps
80107cf1:	e9 6a f5 ff ff       	jmp    80107260 <alltraps>

80107cf6 <vector116>:
.globl vector116
vector116:
  pushl $0
80107cf6:	6a 00                	push   $0x0
  pushl $116
80107cf8:	6a 74                	push   $0x74
  jmp alltraps
80107cfa:	e9 61 f5 ff ff       	jmp    80107260 <alltraps>

80107cff <vector117>:
.globl vector117
vector117:
  pushl $0
80107cff:	6a 00                	push   $0x0
  pushl $117
80107d01:	6a 75                	push   $0x75
  jmp alltraps
80107d03:	e9 58 f5 ff ff       	jmp    80107260 <alltraps>

80107d08 <vector118>:
.globl vector118
vector118:
  pushl $0
80107d08:	6a 00                	push   $0x0
  pushl $118
80107d0a:	6a 76                	push   $0x76
  jmp alltraps
80107d0c:	e9 4f f5 ff ff       	jmp    80107260 <alltraps>

80107d11 <vector119>:
.globl vector119
vector119:
  pushl $0
80107d11:	6a 00                	push   $0x0
  pushl $119
80107d13:	6a 77                	push   $0x77
  jmp alltraps
80107d15:	e9 46 f5 ff ff       	jmp    80107260 <alltraps>

80107d1a <vector120>:
.globl vector120
vector120:
  pushl $0
80107d1a:	6a 00                	push   $0x0
  pushl $120
80107d1c:	6a 78                	push   $0x78
  jmp alltraps
80107d1e:	e9 3d f5 ff ff       	jmp    80107260 <alltraps>

80107d23 <vector121>:
.globl vector121
vector121:
  pushl $0
80107d23:	6a 00                	push   $0x0
  pushl $121
80107d25:	6a 79                	push   $0x79
  jmp alltraps
80107d27:	e9 34 f5 ff ff       	jmp    80107260 <alltraps>

80107d2c <vector122>:
.globl vector122
vector122:
  pushl $0
80107d2c:	6a 00                	push   $0x0
  pushl $122
80107d2e:	6a 7a                	push   $0x7a
  jmp alltraps
80107d30:	e9 2b f5 ff ff       	jmp    80107260 <alltraps>

80107d35 <vector123>:
.globl vector123
vector123:
  pushl $0
80107d35:	6a 00                	push   $0x0
  pushl $123
80107d37:	6a 7b                	push   $0x7b
  jmp alltraps
80107d39:	e9 22 f5 ff ff       	jmp    80107260 <alltraps>

80107d3e <vector124>:
.globl vector124
vector124:
  pushl $0
80107d3e:	6a 00                	push   $0x0
  pushl $124
80107d40:	6a 7c                	push   $0x7c
  jmp alltraps
80107d42:	e9 19 f5 ff ff       	jmp    80107260 <alltraps>

80107d47 <vector125>:
.globl vector125
vector125:
  pushl $0
80107d47:	6a 00                	push   $0x0
  pushl $125
80107d49:	6a 7d                	push   $0x7d
  jmp alltraps
80107d4b:	e9 10 f5 ff ff       	jmp    80107260 <alltraps>

80107d50 <vector126>:
.globl vector126
vector126:
  pushl $0
80107d50:	6a 00                	push   $0x0
  pushl $126
80107d52:	6a 7e                	push   $0x7e
  jmp alltraps
80107d54:	e9 07 f5 ff ff       	jmp    80107260 <alltraps>

80107d59 <vector127>:
.globl vector127
vector127:
  pushl $0
80107d59:	6a 00                	push   $0x0
  pushl $127
80107d5b:	6a 7f                	push   $0x7f
  jmp alltraps
80107d5d:	e9 fe f4 ff ff       	jmp    80107260 <alltraps>

80107d62 <vector128>:
.globl vector128
vector128:
  pushl $0
80107d62:	6a 00                	push   $0x0
  pushl $128
80107d64:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107d69:	e9 f2 f4 ff ff       	jmp    80107260 <alltraps>

80107d6e <vector129>:
.globl vector129
vector129:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $129
80107d70:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107d75:	e9 e6 f4 ff ff       	jmp    80107260 <alltraps>

80107d7a <vector130>:
.globl vector130
vector130:
  pushl $0
80107d7a:	6a 00                	push   $0x0
  pushl $130
80107d7c:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107d81:	e9 da f4 ff ff       	jmp    80107260 <alltraps>

80107d86 <vector131>:
.globl vector131
vector131:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $131
80107d88:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107d8d:	e9 ce f4 ff ff       	jmp    80107260 <alltraps>

80107d92 <vector132>:
.globl vector132
vector132:
  pushl $0
80107d92:	6a 00                	push   $0x0
  pushl $132
80107d94:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107d99:	e9 c2 f4 ff ff       	jmp    80107260 <alltraps>

80107d9e <vector133>:
.globl vector133
vector133:
  pushl $0
80107d9e:	6a 00                	push   $0x0
  pushl $133
80107da0:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107da5:	e9 b6 f4 ff ff       	jmp    80107260 <alltraps>

80107daa <vector134>:
.globl vector134
vector134:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $134
80107dac:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107db1:	e9 aa f4 ff ff       	jmp    80107260 <alltraps>

80107db6 <vector135>:
.globl vector135
vector135:
  pushl $0
80107db6:	6a 00                	push   $0x0
  pushl $135
80107db8:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107dbd:	e9 9e f4 ff ff       	jmp    80107260 <alltraps>

80107dc2 <vector136>:
.globl vector136
vector136:
  pushl $0
80107dc2:	6a 00                	push   $0x0
  pushl $136
80107dc4:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107dc9:	e9 92 f4 ff ff       	jmp    80107260 <alltraps>

80107dce <vector137>:
.globl vector137
vector137:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $137
80107dd0:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107dd5:	e9 86 f4 ff ff       	jmp    80107260 <alltraps>

80107dda <vector138>:
.globl vector138
vector138:
  pushl $0
80107dda:	6a 00                	push   $0x0
  pushl $138
80107ddc:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107de1:	e9 7a f4 ff ff       	jmp    80107260 <alltraps>

80107de6 <vector139>:
.globl vector139
vector139:
  pushl $0
80107de6:	6a 00                	push   $0x0
  pushl $139
80107de8:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107ded:	e9 6e f4 ff ff       	jmp    80107260 <alltraps>

80107df2 <vector140>:
.globl vector140
vector140:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $140
80107df4:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107df9:	e9 62 f4 ff ff       	jmp    80107260 <alltraps>

80107dfe <vector141>:
.globl vector141
vector141:
  pushl $0
80107dfe:	6a 00                	push   $0x0
  pushl $141
80107e00:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107e05:	e9 56 f4 ff ff       	jmp    80107260 <alltraps>

80107e0a <vector142>:
.globl vector142
vector142:
  pushl $0
80107e0a:	6a 00                	push   $0x0
  pushl $142
80107e0c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107e11:	e9 4a f4 ff ff       	jmp    80107260 <alltraps>

80107e16 <vector143>:
.globl vector143
vector143:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $143
80107e18:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107e1d:	e9 3e f4 ff ff       	jmp    80107260 <alltraps>

80107e22 <vector144>:
.globl vector144
vector144:
  pushl $0
80107e22:	6a 00                	push   $0x0
  pushl $144
80107e24:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107e29:	e9 32 f4 ff ff       	jmp    80107260 <alltraps>

80107e2e <vector145>:
.globl vector145
vector145:
  pushl $0
80107e2e:	6a 00                	push   $0x0
  pushl $145
80107e30:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107e35:	e9 26 f4 ff ff       	jmp    80107260 <alltraps>

80107e3a <vector146>:
.globl vector146
vector146:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $146
80107e3c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107e41:	e9 1a f4 ff ff       	jmp    80107260 <alltraps>

80107e46 <vector147>:
.globl vector147
vector147:
  pushl $0
80107e46:	6a 00                	push   $0x0
  pushl $147
80107e48:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107e4d:	e9 0e f4 ff ff       	jmp    80107260 <alltraps>

80107e52 <vector148>:
.globl vector148
vector148:
  pushl $0
80107e52:	6a 00                	push   $0x0
  pushl $148
80107e54:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107e59:	e9 02 f4 ff ff       	jmp    80107260 <alltraps>

80107e5e <vector149>:
.globl vector149
vector149:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $149
80107e60:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107e65:	e9 f6 f3 ff ff       	jmp    80107260 <alltraps>

80107e6a <vector150>:
.globl vector150
vector150:
  pushl $0
80107e6a:	6a 00                	push   $0x0
  pushl $150
80107e6c:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107e71:	e9 ea f3 ff ff       	jmp    80107260 <alltraps>

80107e76 <vector151>:
.globl vector151
vector151:
  pushl $0
80107e76:	6a 00                	push   $0x0
  pushl $151
80107e78:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107e7d:	e9 de f3 ff ff       	jmp    80107260 <alltraps>

80107e82 <vector152>:
.globl vector152
vector152:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $152
80107e84:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107e89:	e9 d2 f3 ff ff       	jmp    80107260 <alltraps>

80107e8e <vector153>:
.globl vector153
vector153:
  pushl $0
80107e8e:	6a 00                	push   $0x0
  pushl $153
80107e90:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107e95:	e9 c6 f3 ff ff       	jmp    80107260 <alltraps>

80107e9a <vector154>:
.globl vector154
vector154:
  pushl $0
80107e9a:	6a 00                	push   $0x0
  pushl $154
80107e9c:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107ea1:	e9 ba f3 ff ff       	jmp    80107260 <alltraps>

80107ea6 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $155
80107ea8:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ead:	e9 ae f3 ff ff       	jmp    80107260 <alltraps>

80107eb2 <vector156>:
.globl vector156
vector156:
  pushl $0
80107eb2:	6a 00                	push   $0x0
  pushl $156
80107eb4:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107eb9:	e9 a2 f3 ff ff       	jmp    80107260 <alltraps>

80107ebe <vector157>:
.globl vector157
vector157:
  pushl $0
80107ebe:	6a 00                	push   $0x0
  pushl $157
80107ec0:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ec5:	e9 96 f3 ff ff       	jmp    80107260 <alltraps>

80107eca <vector158>:
.globl vector158
vector158:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $158
80107ecc:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107ed1:	e9 8a f3 ff ff       	jmp    80107260 <alltraps>

80107ed6 <vector159>:
.globl vector159
vector159:
  pushl $0
80107ed6:	6a 00                	push   $0x0
  pushl $159
80107ed8:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107edd:	e9 7e f3 ff ff       	jmp    80107260 <alltraps>

80107ee2 <vector160>:
.globl vector160
vector160:
  pushl $0
80107ee2:	6a 00                	push   $0x0
  pushl $160
80107ee4:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107ee9:	e9 72 f3 ff ff       	jmp    80107260 <alltraps>

80107eee <vector161>:
.globl vector161
vector161:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $161
80107ef0:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107ef5:	e9 66 f3 ff ff       	jmp    80107260 <alltraps>

80107efa <vector162>:
.globl vector162
vector162:
  pushl $0
80107efa:	6a 00                	push   $0x0
  pushl $162
80107efc:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107f01:	e9 5a f3 ff ff       	jmp    80107260 <alltraps>

80107f06 <vector163>:
.globl vector163
vector163:
  pushl $0
80107f06:	6a 00                	push   $0x0
  pushl $163
80107f08:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107f0d:	e9 4e f3 ff ff       	jmp    80107260 <alltraps>

80107f12 <vector164>:
.globl vector164
vector164:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $164
80107f14:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107f19:	e9 42 f3 ff ff       	jmp    80107260 <alltraps>

80107f1e <vector165>:
.globl vector165
vector165:
  pushl $0
80107f1e:	6a 00                	push   $0x0
  pushl $165
80107f20:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107f25:	e9 36 f3 ff ff       	jmp    80107260 <alltraps>

80107f2a <vector166>:
.globl vector166
vector166:
  pushl $0
80107f2a:	6a 00                	push   $0x0
  pushl $166
80107f2c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107f31:	e9 2a f3 ff ff       	jmp    80107260 <alltraps>

80107f36 <vector167>:
.globl vector167
vector167:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $167
80107f38:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107f3d:	e9 1e f3 ff ff       	jmp    80107260 <alltraps>

80107f42 <vector168>:
.globl vector168
vector168:
  pushl $0
80107f42:	6a 00                	push   $0x0
  pushl $168
80107f44:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107f49:	e9 12 f3 ff ff       	jmp    80107260 <alltraps>

80107f4e <vector169>:
.globl vector169
vector169:
  pushl $0
80107f4e:	6a 00                	push   $0x0
  pushl $169
80107f50:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107f55:	e9 06 f3 ff ff       	jmp    80107260 <alltraps>

80107f5a <vector170>:
.globl vector170
vector170:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $170
80107f5c:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107f61:	e9 fa f2 ff ff       	jmp    80107260 <alltraps>

80107f66 <vector171>:
.globl vector171
vector171:
  pushl $0
80107f66:	6a 00                	push   $0x0
  pushl $171
80107f68:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107f6d:	e9 ee f2 ff ff       	jmp    80107260 <alltraps>

80107f72 <vector172>:
.globl vector172
vector172:
  pushl $0
80107f72:	6a 00                	push   $0x0
  pushl $172
80107f74:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107f79:	e9 e2 f2 ff ff       	jmp    80107260 <alltraps>

80107f7e <vector173>:
.globl vector173
vector173:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $173
80107f80:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107f85:	e9 d6 f2 ff ff       	jmp    80107260 <alltraps>

80107f8a <vector174>:
.globl vector174
vector174:
  pushl $0
80107f8a:	6a 00                	push   $0x0
  pushl $174
80107f8c:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107f91:	e9 ca f2 ff ff       	jmp    80107260 <alltraps>

80107f96 <vector175>:
.globl vector175
vector175:
  pushl $0
80107f96:	6a 00                	push   $0x0
  pushl $175
80107f98:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107f9d:	e9 be f2 ff ff       	jmp    80107260 <alltraps>

80107fa2 <vector176>:
.globl vector176
vector176:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $176
80107fa4:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107fa9:	e9 b2 f2 ff ff       	jmp    80107260 <alltraps>

80107fae <vector177>:
.globl vector177
vector177:
  pushl $0
80107fae:	6a 00                	push   $0x0
  pushl $177
80107fb0:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107fb5:	e9 a6 f2 ff ff       	jmp    80107260 <alltraps>

80107fba <vector178>:
.globl vector178
vector178:
  pushl $0
80107fba:	6a 00                	push   $0x0
  pushl $178
80107fbc:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107fc1:	e9 9a f2 ff ff       	jmp    80107260 <alltraps>

80107fc6 <vector179>:
.globl vector179
vector179:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $179
80107fc8:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107fcd:	e9 8e f2 ff ff       	jmp    80107260 <alltraps>

80107fd2 <vector180>:
.globl vector180
vector180:
  pushl $0
80107fd2:	6a 00                	push   $0x0
  pushl $180
80107fd4:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107fd9:	e9 82 f2 ff ff       	jmp    80107260 <alltraps>

80107fde <vector181>:
.globl vector181
vector181:
  pushl $0
80107fde:	6a 00                	push   $0x0
  pushl $181
80107fe0:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107fe5:	e9 76 f2 ff ff       	jmp    80107260 <alltraps>

80107fea <vector182>:
.globl vector182
vector182:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $182
80107fec:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107ff1:	e9 6a f2 ff ff       	jmp    80107260 <alltraps>

80107ff6 <vector183>:
.globl vector183
vector183:
  pushl $0
80107ff6:	6a 00                	push   $0x0
  pushl $183
80107ff8:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107ffd:	e9 5e f2 ff ff       	jmp    80107260 <alltraps>

80108002 <vector184>:
.globl vector184
vector184:
  pushl $0
80108002:	6a 00                	push   $0x0
  pushl $184
80108004:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108009:	e9 52 f2 ff ff       	jmp    80107260 <alltraps>

8010800e <vector185>:
.globl vector185
vector185:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $185
80108010:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108015:	e9 46 f2 ff ff       	jmp    80107260 <alltraps>

8010801a <vector186>:
.globl vector186
vector186:
  pushl $0
8010801a:	6a 00                	push   $0x0
  pushl $186
8010801c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108021:	e9 3a f2 ff ff       	jmp    80107260 <alltraps>

80108026 <vector187>:
.globl vector187
vector187:
  pushl $0
80108026:	6a 00                	push   $0x0
  pushl $187
80108028:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010802d:	e9 2e f2 ff ff       	jmp    80107260 <alltraps>

80108032 <vector188>:
.globl vector188
vector188:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $188
80108034:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108039:	e9 22 f2 ff ff       	jmp    80107260 <alltraps>

8010803e <vector189>:
.globl vector189
vector189:
  pushl $0
8010803e:	6a 00                	push   $0x0
  pushl $189
80108040:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108045:	e9 16 f2 ff ff       	jmp    80107260 <alltraps>

8010804a <vector190>:
.globl vector190
vector190:
  pushl $0
8010804a:	6a 00                	push   $0x0
  pushl $190
8010804c:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80108051:	e9 0a f2 ff ff       	jmp    80107260 <alltraps>

80108056 <vector191>:
.globl vector191
vector191:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $191
80108058:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010805d:	e9 fe f1 ff ff       	jmp    80107260 <alltraps>

80108062 <vector192>:
.globl vector192
vector192:
  pushl $0
80108062:	6a 00                	push   $0x0
  pushl $192
80108064:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108069:	e9 f2 f1 ff ff       	jmp    80107260 <alltraps>

8010806e <vector193>:
.globl vector193
vector193:
  pushl $0
8010806e:	6a 00                	push   $0x0
  pushl $193
80108070:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108075:	e9 e6 f1 ff ff       	jmp    80107260 <alltraps>

8010807a <vector194>:
.globl vector194
vector194:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $194
8010807c:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80108081:	e9 da f1 ff ff       	jmp    80107260 <alltraps>

80108086 <vector195>:
.globl vector195
vector195:
  pushl $0
80108086:	6a 00                	push   $0x0
  pushl $195
80108088:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010808d:	e9 ce f1 ff ff       	jmp    80107260 <alltraps>

80108092 <vector196>:
.globl vector196
vector196:
  pushl $0
80108092:	6a 00                	push   $0x0
  pushl $196
80108094:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80108099:	e9 c2 f1 ff ff       	jmp    80107260 <alltraps>

8010809e <vector197>:
.globl vector197
vector197:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $197
801080a0:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801080a5:	e9 b6 f1 ff ff       	jmp    80107260 <alltraps>

801080aa <vector198>:
.globl vector198
vector198:
  pushl $0
801080aa:	6a 00                	push   $0x0
  pushl $198
801080ac:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801080b1:	e9 aa f1 ff ff       	jmp    80107260 <alltraps>

801080b6 <vector199>:
.globl vector199
vector199:
  pushl $0
801080b6:	6a 00                	push   $0x0
  pushl $199
801080b8:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801080bd:	e9 9e f1 ff ff       	jmp    80107260 <alltraps>

801080c2 <vector200>:
.globl vector200
vector200:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $200
801080c4:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801080c9:	e9 92 f1 ff ff       	jmp    80107260 <alltraps>

801080ce <vector201>:
.globl vector201
vector201:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $201
801080d0:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801080d5:	e9 86 f1 ff ff       	jmp    80107260 <alltraps>

801080da <vector202>:
.globl vector202
vector202:
  pushl $0
801080da:	6a 00                	push   $0x0
  pushl $202
801080dc:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801080e1:	e9 7a f1 ff ff       	jmp    80107260 <alltraps>

801080e6 <vector203>:
.globl vector203
vector203:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $203
801080e8:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801080ed:	e9 6e f1 ff ff       	jmp    80107260 <alltraps>

801080f2 <vector204>:
.globl vector204
vector204:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $204
801080f4:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801080f9:	e9 62 f1 ff ff       	jmp    80107260 <alltraps>

801080fe <vector205>:
.globl vector205
vector205:
  pushl $0
801080fe:	6a 00                	push   $0x0
  pushl $205
80108100:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108105:	e9 56 f1 ff ff       	jmp    80107260 <alltraps>

8010810a <vector206>:
.globl vector206
vector206:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $206
8010810c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108111:	e9 4a f1 ff ff       	jmp    80107260 <alltraps>

80108116 <vector207>:
.globl vector207
vector207:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $207
80108118:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010811d:	e9 3e f1 ff ff       	jmp    80107260 <alltraps>

80108122 <vector208>:
.globl vector208
vector208:
  pushl $0
80108122:	6a 00                	push   $0x0
  pushl $208
80108124:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108129:	e9 32 f1 ff ff       	jmp    80107260 <alltraps>

8010812e <vector209>:
.globl vector209
vector209:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $209
80108130:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108135:	e9 26 f1 ff ff       	jmp    80107260 <alltraps>

8010813a <vector210>:
.globl vector210
vector210:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $210
8010813c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80108141:	e9 1a f1 ff ff       	jmp    80107260 <alltraps>

80108146 <vector211>:
.globl vector211
vector211:
  pushl $0
80108146:	6a 00                	push   $0x0
  pushl $211
80108148:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010814d:	e9 0e f1 ff ff       	jmp    80107260 <alltraps>

80108152 <vector212>:
.globl vector212
vector212:
  pushl $0
80108152:	6a 00                	push   $0x0
  pushl $212
80108154:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108159:	e9 02 f1 ff ff       	jmp    80107260 <alltraps>

8010815e <vector213>:
.globl vector213
vector213:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $213
80108160:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108165:	e9 f6 f0 ff ff       	jmp    80107260 <alltraps>

8010816a <vector214>:
.globl vector214
vector214:
  pushl $0
8010816a:	6a 00                	push   $0x0
  pushl $214
8010816c:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80108171:	e9 ea f0 ff ff       	jmp    80107260 <alltraps>

80108176 <vector215>:
.globl vector215
vector215:
  pushl $0
80108176:	6a 00                	push   $0x0
  pushl $215
80108178:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010817d:	e9 de f0 ff ff       	jmp    80107260 <alltraps>

80108182 <vector216>:
.globl vector216
vector216:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $216
80108184:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80108189:	e9 d2 f0 ff ff       	jmp    80107260 <alltraps>

8010818e <vector217>:
.globl vector217
vector217:
  pushl $0
8010818e:	6a 00                	push   $0x0
  pushl $217
80108190:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80108195:	e9 c6 f0 ff ff       	jmp    80107260 <alltraps>

8010819a <vector218>:
.globl vector218
vector218:
  pushl $0
8010819a:	6a 00                	push   $0x0
  pushl $218
8010819c:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801081a1:	e9 ba f0 ff ff       	jmp    80107260 <alltraps>

801081a6 <vector219>:
.globl vector219
vector219:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $219
801081a8:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801081ad:	e9 ae f0 ff ff       	jmp    80107260 <alltraps>

801081b2 <vector220>:
.globl vector220
vector220:
  pushl $0
801081b2:	6a 00                	push   $0x0
  pushl $220
801081b4:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801081b9:	e9 a2 f0 ff ff       	jmp    80107260 <alltraps>

801081be <vector221>:
.globl vector221
vector221:
  pushl $0
801081be:	6a 00                	push   $0x0
  pushl $221
801081c0:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801081c5:	e9 96 f0 ff ff       	jmp    80107260 <alltraps>

801081ca <vector222>:
.globl vector222
vector222:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $222
801081cc:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801081d1:	e9 8a f0 ff ff       	jmp    80107260 <alltraps>

801081d6 <vector223>:
.globl vector223
vector223:
  pushl $0
801081d6:	6a 00                	push   $0x0
  pushl $223
801081d8:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801081dd:	e9 7e f0 ff ff       	jmp    80107260 <alltraps>

801081e2 <vector224>:
.globl vector224
vector224:
  pushl $0
801081e2:	6a 00                	push   $0x0
  pushl $224
801081e4:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801081e9:	e9 72 f0 ff ff       	jmp    80107260 <alltraps>

801081ee <vector225>:
.globl vector225
vector225:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $225
801081f0:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801081f5:	e9 66 f0 ff ff       	jmp    80107260 <alltraps>

801081fa <vector226>:
.globl vector226
vector226:
  pushl $0
801081fa:	6a 00                	push   $0x0
  pushl $226
801081fc:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108201:	e9 5a f0 ff ff       	jmp    80107260 <alltraps>

80108206 <vector227>:
.globl vector227
vector227:
  pushl $0
80108206:	6a 00                	push   $0x0
  pushl $227
80108208:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010820d:	e9 4e f0 ff ff       	jmp    80107260 <alltraps>

80108212 <vector228>:
.globl vector228
vector228:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $228
80108214:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108219:	e9 42 f0 ff ff       	jmp    80107260 <alltraps>

8010821e <vector229>:
.globl vector229
vector229:
  pushl $0
8010821e:	6a 00                	push   $0x0
  pushl $229
80108220:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108225:	e9 36 f0 ff ff       	jmp    80107260 <alltraps>

8010822a <vector230>:
.globl vector230
vector230:
  pushl $0
8010822a:	6a 00                	push   $0x0
  pushl $230
8010822c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108231:	e9 2a f0 ff ff       	jmp    80107260 <alltraps>

80108236 <vector231>:
.globl vector231
vector231:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $231
80108238:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010823d:	e9 1e f0 ff ff       	jmp    80107260 <alltraps>

80108242 <vector232>:
.globl vector232
vector232:
  pushl $0
80108242:	6a 00                	push   $0x0
  pushl $232
80108244:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108249:	e9 12 f0 ff ff       	jmp    80107260 <alltraps>

8010824e <vector233>:
.globl vector233
vector233:
  pushl $0
8010824e:	6a 00                	push   $0x0
  pushl $233
80108250:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108255:	e9 06 f0 ff ff       	jmp    80107260 <alltraps>

8010825a <vector234>:
.globl vector234
vector234:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $234
8010825c:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80108261:	e9 fa ef ff ff       	jmp    80107260 <alltraps>

80108266 <vector235>:
.globl vector235
vector235:
  pushl $0
80108266:	6a 00                	push   $0x0
  pushl $235
80108268:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010826d:	e9 ee ef ff ff       	jmp    80107260 <alltraps>

80108272 <vector236>:
.globl vector236
vector236:
  pushl $0
80108272:	6a 00                	push   $0x0
  pushl $236
80108274:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108279:	e9 e2 ef ff ff       	jmp    80107260 <alltraps>

8010827e <vector237>:
.globl vector237
vector237:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $237
80108280:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80108285:	e9 d6 ef ff ff       	jmp    80107260 <alltraps>

8010828a <vector238>:
.globl vector238
vector238:
  pushl $0
8010828a:	6a 00                	push   $0x0
  pushl $238
8010828c:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80108291:	e9 ca ef ff ff       	jmp    80107260 <alltraps>

80108296 <vector239>:
.globl vector239
vector239:
  pushl $0
80108296:	6a 00                	push   $0x0
  pushl $239
80108298:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
8010829d:	e9 be ef ff ff       	jmp    80107260 <alltraps>

801082a2 <vector240>:
.globl vector240
vector240:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $240
801082a4:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801082a9:	e9 b2 ef ff ff       	jmp    80107260 <alltraps>

801082ae <vector241>:
.globl vector241
vector241:
  pushl $0
801082ae:	6a 00                	push   $0x0
  pushl $241
801082b0:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801082b5:	e9 a6 ef ff ff       	jmp    80107260 <alltraps>

801082ba <vector242>:
.globl vector242
vector242:
  pushl $0
801082ba:	6a 00                	push   $0x0
  pushl $242
801082bc:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801082c1:	e9 9a ef ff ff       	jmp    80107260 <alltraps>

801082c6 <vector243>:
.globl vector243
vector243:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $243
801082c8:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801082cd:	e9 8e ef ff ff       	jmp    80107260 <alltraps>

801082d2 <vector244>:
.globl vector244
vector244:
  pushl $0
801082d2:	6a 00                	push   $0x0
  pushl $244
801082d4:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801082d9:	e9 82 ef ff ff       	jmp    80107260 <alltraps>

801082de <vector245>:
.globl vector245
vector245:
  pushl $0
801082de:	6a 00                	push   $0x0
  pushl $245
801082e0:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801082e5:	e9 76 ef ff ff       	jmp    80107260 <alltraps>

801082ea <vector246>:
.globl vector246
vector246:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $246
801082ec:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801082f1:	e9 6a ef ff ff       	jmp    80107260 <alltraps>

801082f6 <vector247>:
.globl vector247
vector247:
  pushl $0
801082f6:	6a 00                	push   $0x0
  pushl $247
801082f8:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801082fd:	e9 5e ef ff ff       	jmp    80107260 <alltraps>

80108302 <vector248>:
.globl vector248
vector248:
  pushl $0
80108302:	6a 00                	push   $0x0
  pushl $248
80108304:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108309:	e9 52 ef ff ff       	jmp    80107260 <alltraps>

8010830e <vector249>:
.globl vector249
vector249:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $249
80108310:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108315:	e9 46 ef ff ff       	jmp    80107260 <alltraps>

8010831a <vector250>:
.globl vector250
vector250:
  pushl $0
8010831a:	6a 00                	push   $0x0
  pushl $250
8010831c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108321:	e9 3a ef ff ff       	jmp    80107260 <alltraps>

80108326 <vector251>:
.globl vector251
vector251:
  pushl $0
80108326:	6a 00                	push   $0x0
  pushl $251
80108328:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010832d:	e9 2e ef ff ff       	jmp    80107260 <alltraps>

80108332 <vector252>:
.globl vector252
vector252:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $252
80108334:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108339:	e9 22 ef ff ff       	jmp    80107260 <alltraps>

8010833e <vector253>:
.globl vector253
vector253:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $253
80108340:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108345:	e9 16 ef ff ff       	jmp    80107260 <alltraps>

8010834a <vector254>:
.globl vector254
vector254:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $254
8010834c:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80108351:	e9 0a ef ff ff       	jmp    80107260 <alltraps>

80108356 <vector255>:
.globl vector255
vector255:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $255
80108358:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010835d:	e9 fe ee ff ff       	jmp    80107260 <alltraps>
	...

80108364 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108364:	55                   	push   %ebp
80108365:	89 e5                	mov    %esp,%ebp
80108367:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010836a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010836d:	83 e8 01             	sub    $0x1,%eax
80108370:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108374:	8b 45 08             	mov    0x8(%ebp),%eax
80108377:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010837b:	8b 45 08             	mov    0x8(%ebp),%eax
8010837e:	c1 e8 10             	shr    $0x10,%eax
80108381:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80108385:	8d 45 fa             	lea    -0x6(%ebp),%eax
80108388:	0f 01 10             	lgdtl  (%eax)
}
8010838b:	c9                   	leave  
8010838c:	c3                   	ret    

8010838d <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010838d:	55                   	push   %ebp
8010838e:	89 e5                	mov    %esp,%ebp
80108390:	83 ec 04             	sub    $0x4,%esp
80108393:	8b 45 08             	mov    0x8(%ebp),%eax
80108396:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010839a:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010839e:	0f 00 d8             	ltr    %ax
}
801083a1:	c9                   	leave  
801083a2:	c3                   	ret    

801083a3 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801083a3:	55                   	push   %ebp
801083a4:	89 e5                	mov    %esp,%ebp
801083a6:	83 ec 04             	sub    $0x4,%esp
801083a9:	8b 45 08             	mov    0x8(%ebp),%eax
801083ac:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801083b0:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801083b4:	8e e8                	mov    %eax,%gs
}
801083b6:	c9                   	leave  
801083b7:	c3                   	ret    

801083b8 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801083b8:	55                   	push   %ebp
801083b9:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801083bb:	8b 45 08             	mov    0x8(%ebp),%eax
801083be:	0f 22 d8             	mov    %eax,%cr3
}
801083c1:	5d                   	pop    %ebp
801083c2:	c3                   	ret    

801083c3 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801083c3:	55                   	push   %ebp
801083c4:	89 e5                	mov    %esp,%ebp
801083c6:	8b 45 08             	mov    0x8(%ebp),%eax
801083c9:	05 00 00 00 80       	add    $0x80000000,%eax
801083ce:	5d                   	pop    %ebp
801083cf:	c3                   	ret    

801083d0 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801083d0:	55                   	push   %ebp
801083d1:	89 e5                	mov    %esp,%ebp
801083d3:	8b 45 08             	mov    0x8(%ebp),%eax
801083d6:	05 00 00 00 80       	add    $0x80000000,%eax
801083db:	5d                   	pop    %ebp
801083dc:	c3                   	ret    

801083dd <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801083dd:	55                   	push   %ebp
801083de:	89 e5                	mov    %esp,%ebp
801083e0:	53                   	push   %ebx
801083e1:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
801083e4:	e8 4c b9 ff ff       	call   80103d35 <cpunum>
801083e9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801083ef:	05 40 09 11 80       	add    $0x80110940,%eax
801083f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801083f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083fa:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108400:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108403:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108409:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010840c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108410:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108413:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108417:	83 e2 f0             	and    $0xfffffff0,%edx
8010841a:	83 ca 0a             	or     $0xa,%edx
8010841d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108420:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108423:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108427:	83 ca 10             	or     $0x10,%edx
8010842a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010842d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108430:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108434:	83 e2 9f             	and    $0xffffff9f,%edx
80108437:	88 50 7d             	mov    %dl,0x7d(%eax)
8010843a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010843d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108441:	83 ca 80             	or     $0xffffff80,%edx
80108444:	88 50 7d             	mov    %dl,0x7d(%eax)
80108447:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010844e:	83 ca 0f             	or     $0xf,%edx
80108451:	88 50 7e             	mov    %dl,0x7e(%eax)
80108454:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108457:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010845b:	83 e2 ef             	and    $0xffffffef,%edx
8010845e:	88 50 7e             	mov    %dl,0x7e(%eax)
80108461:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108464:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108468:	83 e2 df             	and    $0xffffffdf,%edx
8010846b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010846e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108471:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108475:	83 ca 40             	or     $0x40,%edx
80108478:	88 50 7e             	mov    %dl,0x7e(%eax)
8010847b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010847e:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108482:	83 ca 80             	or     $0xffffff80,%edx
80108485:	88 50 7e             	mov    %dl,0x7e(%eax)
80108488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010848b:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010848f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108492:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80108499:	ff ff 
8010849b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849e:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801084a5:	00 00 
801084a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084aa:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801084b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084b4:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084bb:	83 e2 f0             	and    $0xfffffff0,%edx
801084be:	83 ca 02             	or     $0x2,%edx
801084c1:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ca:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084d1:	83 ca 10             	or     $0x10,%edx
801084d4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084dd:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084e4:	83 e2 9f             	and    $0xffffff9f,%edx
801084e7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084f7:	83 ca 80             	or     $0xffffff80,%edx
801084fa:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108500:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108503:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010850a:	83 ca 0f             	or     $0xf,%edx
8010850d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108513:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108516:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010851d:	83 e2 ef             	and    $0xffffffef,%edx
80108520:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108529:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108530:	83 e2 df             	and    $0xffffffdf,%edx
80108533:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108539:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010853c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108543:	83 ca 40             	or     $0x40,%edx
80108546:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010854c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010854f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108556:	83 ca 80             	or     $0xffffff80,%edx
80108559:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010855f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108562:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856c:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80108573:	ff ff 
80108575:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108578:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010857f:	00 00 
80108581:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108584:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010858b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010858e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108595:	83 e2 f0             	and    $0xfffffff0,%edx
80108598:	83 ca 0a             	or     $0xa,%edx
8010859b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a4:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085ab:	83 ca 10             	or     $0x10,%edx
801085ae:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085b7:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085be:	83 ca 60             	or     $0x60,%edx
801085c1:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085ca:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085d1:	83 ca 80             	or     $0xffffff80,%edx
801085d4:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085dd:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801085e4:	83 ca 0f             	or     $0xf,%edx
801085e7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801085ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801085f7:	83 e2 ef             	and    $0xffffffef,%edx
801085fa:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108600:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108603:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010860a:	83 e2 df             	and    $0xffffffdf,%edx
8010860d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108616:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010861d:	83 ca 40             	or     $0x40,%edx
80108620:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108626:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108629:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108630:	83 ca 80             	or     $0xffffff80,%edx
80108633:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010863c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80108643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108646:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
8010864d:	ff ff 
8010864f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108652:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108659:	00 00 
8010865b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010865e:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108665:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108668:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010866f:	83 e2 f0             	and    $0xfffffff0,%edx
80108672:	83 ca 02             	or     $0x2,%edx
80108675:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010867b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010867e:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108685:	83 ca 10             	or     $0x10,%edx
80108688:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010868e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108691:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108698:	83 ca 60             	or     $0x60,%edx
8010869b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086ab:	83 ca 80             	or     $0xffffff80,%edx
801086ae:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086b7:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086be:	83 ca 0f             	or     $0xf,%edx
801086c1:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ca:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086d1:	83 e2 ef             	and    $0xffffffef,%edx
801086d4:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086dd:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086e4:	83 e2 df             	and    $0xffffffdf,%edx
801086e7:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f0:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086f7:	83 ca 40             	or     $0x40,%edx
801086fa:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108700:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108703:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010870a:	83 ca 80             	or     $0xffffff80,%edx
8010870d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108713:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108716:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
8010871d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108720:	05 b4 00 00 00       	add    $0xb4,%eax
80108725:	89 c3                	mov    %eax,%ebx
80108727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010872a:	05 b4 00 00 00       	add    $0xb4,%eax
8010872f:	c1 e8 10             	shr    $0x10,%eax
80108732:	89 c1                	mov    %eax,%ecx
80108734:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108737:	05 b4 00 00 00       	add    $0xb4,%eax
8010873c:	c1 e8 18             	shr    $0x18,%eax
8010873f:	89 c2                	mov    %eax,%edx
80108741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108744:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
8010874b:	00 00 
8010874d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108750:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010875a:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108760:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108763:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010876a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010876d:	83 c9 02             	or     $0x2,%ecx
80108770:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108776:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108779:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108780:	83 c9 10             	or     $0x10,%ecx
80108783:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108789:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010878c:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108793:	83 e1 9f             	and    $0xffffff9f,%ecx
80108796:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010879c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801087a6:	83 c9 80             	or     $0xffffff80,%ecx
801087a9:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b2:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087b9:	83 e1 f0             	and    $0xfffffff0,%ecx
801087bc:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087c5:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087cc:	83 e1 ef             	and    $0xffffffef,%ecx
801087cf:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087d8:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087df:	83 e1 df             	and    $0xffffffdf,%ecx
801087e2:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087eb:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087f2:	83 c9 40             	or     $0x40,%ecx
801087f5:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087fe:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108805:	83 c9 80             	or     $0xffffff80,%ecx
80108808:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010880e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108811:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010881a:	83 c0 70             	add    $0x70,%eax
8010881d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108824:	00 
80108825:	89 04 24             	mov    %eax,(%esp)
80108828:	e8 37 fb ff ff       	call   80108364 <lgdt>
  loadgs(SEG_KCPU << 3);
8010882d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108834:	e8 6a fb ff ff       	call   801083a3 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108839:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108842:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108849:	00 00 00 00 
}
8010884d:	83 c4 24             	add    $0x24,%esp
80108850:	5b                   	pop    %ebx
80108851:	5d                   	pop    %ebp
80108852:	c3                   	ret    

80108853 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108853:	55                   	push   %ebp
80108854:	89 e5                	mov    %esp,%ebp
80108856:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108859:	8b 45 0c             	mov    0xc(%ebp),%eax
8010885c:	c1 e8 16             	shr    $0x16,%eax
8010885f:	c1 e0 02             	shl    $0x2,%eax
80108862:	03 45 08             	add    0x8(%ebp),%eax
80108865:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108868:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010886b:	8b 00                	mov    (%eax),%eax
8010886d:	83 e0 01             	and    $0x1,%eax
80108870:	84 c0                	test   %al,%al
80108872:	74 17                	je     8010888b <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108874:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108877:	8b 00                	mov    (%eax),%eax
80108879:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010887e:	89 04 24             	mov    %eax,(%esp)
80108881:	e8 4a fb ff ff       	call   801083d0 <p2v>
80108886:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108889:	eb 4b                	jmp    801088d6 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010888b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010888f:	74 0e                	je     8010889f <walkpgdir+0x4c>
80108891:	e8 11 b1 ff ff       	call   801039a7 <kalloc>
80108896:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108899:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010889d:	75 07                	jne    801088a6 <walkpgdir+0x53>
      return 0;
8010889f:	b8 00 00 00 00       	mov    $0x0,%eax
801088a4:	eb 41                	jmp    801088e7 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801088a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801088ad:	00 
801088ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801088b5:	00 
801088b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088b9:	89 04 24             	mov    %eax,(%esp)
801088bc:	e8 d9 d3 ff ff       	call   80105c9a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801088c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c4:	89 04 24             	mov    %eax,(%esp)
801088c7:	e8 f7 fa ff ff       	call   801083c3 <v2p>
801088cc:	89 c2                	mov    %eax,%edx
801088ce:	83 ca 07             	or     $0x7,%edx
801088d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088d4:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801088d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801088d9:	c1 e8 0c             	shr    $0xc,%eax
801088dc:	25 ff 03 00 00       	and    $0x3ff,%eax
801088e1:	c1 e0 02             	shl    $0x2,%eax
801088e4:	03 45 f4             	add    -0xc(%ebp),%eax
}
801088e7:	c9                   	leave  
801088e8:	c3                   	ret    

801088e9 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801088e9:	55                   	push   %ebp
801088ea:	89 e5                	mov    %esp,%ebp
801088ec:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801088ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801088f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801088fa:	8b 45 0c             	mov    0xc(%ebp),%eax
801088fd:	03 45 10             	add    0x10(%ebp),%eax
80108900:	83 e8 01             	sub    $0x1,%eax
80108903:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108908:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010890b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108912:	00 
80108913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108916:	89 44 24 04          	mov    %eax,0x4(%esp)
8010891a:	8b 45 08             	mov    0x8(%ebp),%eax
8010891d:	89 04 24             	mov    %eax,(%esp)
80108920:	e8 2e ff ff ff       	call   80108853 <walkpgdir>
80108925:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108928:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010892c:	75 07                	jne    80108935 <mappages+0x4c>
      return -1;
8010892e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108933:	eb 46                	jmp    8010897b <mappages+0x92>
    if(*pte & PTE_P)
80108935:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108938:	8b 00                	mov    (%eax),%eax
8010893a:	83 e0 01             	and    $0x1,%eax
8010893d:	84 c0                	test   %al,%al
8010893f:	74 0c                	je     8010894d <mappages+0x64>
      panic("remap");
80108941:	c7 04 24 30 9a 10 80 	movl   $0x80109a30,(%esp)
80108948:	e8 f0 7b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
8010894d:	8b 45 18             	mov    0x18(%ebp),%eax
80108950:	0b 45 14             	or     0x14(%ebp),%eax
80108953:	89 c2                	mov    %eax,%edx
80108955:	83 ca 01             	or     $0x1,%edx
80108958:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010895b:	89 10                	mov    %edx,(%eax)
    if(a == last)
8010895d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108960:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108963:	74 10                	je     80108975 <mappages+0x8c>
      break;
    a += PGSIZE;
80108965:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
8010896c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108973:	eb 96                	jmp    8010890b <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108975:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108976:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010897b:	c9                   	leave  
8010897c:	c3                   	ret    

8010897d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
8010897d:	55                   	push   %ebp
8010897e:	89 e5                	mov    %esp,%ebp
80108980:	53                   	push   %ebx
80108981:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108984:	e8 1e b0 ff ff       	call   801039a7 <kalloc>
80108989:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010898c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108990:	75 0a                	jne    8010899c <setupkvm+0x1f>
    return 0;
80108992:	b8 00 00 00 00       	mov    $0x0,%eax
80108997:	e9 98 00 00 00       	jmp    80108a34 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
8010899c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089a3:	00 
801089a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089ab:	00 
801089ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089af:	89 04 24             	mov    %eax,(%esp)
801089b2:	e8 e3 d2 ff ff       	call   80105c9a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801089b7:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801089be:	e8 0d fa ff ff       	call   801083d0 <p2v>
801089c3:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801089c8:	76 0c                	jbe    801089d6 <setupkvm+0x59>
    panic("PHYSTOP too high");
801089ca:	c7 04 24 36 9a 10 80 	movl   $0x80109a36,(%esp)
801089d1:	e8 67 7b ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801089d6:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
801089dd:	eb 49                	jmp    80108a28 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801089df:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801089e2:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801089e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801089e8:	8b 50 04             	mov    0x4(%eax),%edx
801089eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089ee:	8b 58 08             	mov    0x8(%eax),%ebx
801089f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f4:	8b 40 04             	mov    0x4(%eax),%eax
801089f7:	29 c3                	sub    %eax,%ebx
801089f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089fc:	8b 00                	mov    (%eax),%eax
801089fe:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108a02:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108a06:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108a0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a11:	89 04 24             	mov    %eax,(%esp)
80108a14:	e8 d0 fe ff ff       	call   801088e9 <mappages>
80108a19:	85 c0                	test   %eax,%eax
80108a1b:	79 07                	jns    80108a24 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108a1d:	b8 00 00 00 00       	mov    $0x0,%eax
80108a22:	eb 10                	jmp    80108a34 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108a24:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108a28:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108a2f:	72 ae                	jb     801089df <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108a31:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108a34:	83 c4 34             	add    $0x34,%esp
80108a37:	5b                   	pop    %ebx
80108a38:	5d                   	pop    %ebp
80108a39:	c3                   	ret    

80108a3a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108a3a:	55                   	push   %ebp
80108a3b:	89 e5                	mov    %esp,%ebp
80108a3d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108a40:	e8 38 ff ff ff       	call   8010897d <setupkvm>
80108a45:	a3 18 37 11 80       	mov    %eax,0x80113718
  switchkvm();
80108a4a:	e8 02 00 00 00       	call   80108a51 <switchkvm>
}
80108a4f:	c9                   	leave  
80108a50:	c3                   	ret    

80108a51 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108a51:	55                   	push   %ebp
80108a52:	89 e5                	mov    %esp,%ebp
80108a54:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108a57:	a1 18 37 11 80       	mov    0x80113718,%eax
80108a5c:	89 04 24             	mov    %eax,(%esp)
80108a5f:	e8 5f f9 ff ff       	call   801083c3 <v2p>
80108a64:	89 04 24             	mov    %eax,(%esp)
80108a67:	e8 4c f9 ff ff       	call   801083b8 <lcr3>
}
80108a6c:	c9                   	leave  
80108a6d:	c3                   	ret    

80108a6e <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108a6e:	55                   	push   %ebp
80108a6f:	89 e5                	mov    %esp,%ebp
80108a71:	53                   	push   %ebx
80108a72:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108a75:	e8 19 d1 ff ff       	call   80105b93 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108a7a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108a80:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108a87:	83 c2 08             	add    $0x8,%edx
80108a8a:	89 d3                	mov    %edx,%ebx
80108a8c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108a93:	83 c2 08             	add    $0x8,%edx
80108a96:	c1 ea 10             	shr    $0x10,%edx
80108a99:	89 d1                	mov    %edx,%ecx
80108a9b:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108aa2:	83 c2 08             	add    $0x8,%edx
80108aa5:	c1 ea 18             	shr    $0x18,%edx
80108aa8:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108aaf:	67 00 
80108ab1:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108ab8:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108abe:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ac5:	83 e1 f0             	and    $0xfffffff0,%ecx
80108ac8:	83 c9 09             	or     $0x9,%ecx
80108acb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ad1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ad8:	83 c9 10             	or     $0x10,%ecx
80108adb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108ae1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108ae8:	83 e1 9f             	and    $0xffffff9f,%ecx
80108aeb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108af1:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108af8:	83 c9 80             	or     $0xffffff80,%ecx
80108afb:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108b01:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b08:	83 e1 f0             	and    $0xfffffff0,%ecx
80108b0b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b11:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b18:	83 e1 ef             	and    $0xffffffef,%ecx
80108b1b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b21:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b28:	83 e1 df             	and    $0xffffffdf,%ecx
80108b2b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b31:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b38:	83 c9 40             	or     $0x40,%ecx
80108b3b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b41:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b48:	83 e1 7f             	and    $0x7f,%ecx
80108b4b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b51:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108b57:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b5d:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108b64:	83 e2 ef             	and    $0xffffffef,%edx
80108b67:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108b6d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b73:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108b79:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b7f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108b86:	8b 52 08             	mov    0x8(%edx),%edx
80108b89:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108b8f:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108b92:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108b99:	e8 ef f7 ff ff       	call   8010838d <ltr>
  if(p->pgdir == 0)
80108b9e:	8b 45 08             	mov    0x8(%ebp),%eax
80108ba1:	8b 40 04             	mov    0x4(%eax),%eax
80108ba4:	85 c0                	test   %eax,%eax
80108ba6:	75 0c                	jne    80108bb4 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108ba8:	c7 04 24 47 9a 10 80 	movl   $0x80109a47,(%esp)
80108baf:	e8 89 79 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80108bb7:	8b 40 04             	mov    0x4(%eax),%eax
80108bba:	89 04 24             	mov    %eax,(%esp)
80108bbd:	e8 01 f8 ff ff       	call   801083c3 <v2p>
80108bc2:	89 04 24             	mov    %eax,(%esp)
80108bc5:	e8 ee f7 ff ff       	call   801083b8 <lcr3>
  popcli();
80108bca:	e8 0c d0 ff ff       	call   80105bdb <popcli>
}
80108bcf:	83 c4 14             	add    $0x14,%esp
80108bd2:	5b                   	pop    %ebx
80108bd3:	5d                   	pop    %ebp
80108bd4:	c3                   	ret    

80108bd5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108bd5:	55                   	push   %ebp
80108bd6:	89 e5                	mov    %esp,%ebp
80108bd8:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108bdb:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108be2:	76 0c                	jbe    80108bf0 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108be4:	c7 04 24 5b 9a 10 80 	movl   $0x80109a5b,(%esp)
80108beb:	e8 4d 79 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108bf0:	e8 b2 ad ff ff       	call   801039a7 <kalloc>
80108bf5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108bf8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108bff:	00 
80108c00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c07:	00 
80108c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c0b:	89 04 24             	mov    %eax,(%esp)
80108c0e:	e8 87 d0 ff ff       	call   80105c9a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108c13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c16:	89 04 24             	mov    %eax,(%esp)
80108c19:	e8 a5 f7 ff ff       	call   801083c3 <v2p>
80108c1e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c25:	00 
80108c26:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c2a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c31:	00 
80108c32:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c39:	00 
80108c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80108c3d:	89 04 24             	mov    %eax,(%esp)
80108c40:	e8 a4 fc ff ff       	call   801088e9 <mappages>
  memmove(mem, init, sz);
80108c45:	8b 45 10             	mov    0x10(%ebp),%eax
80108c48:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c4c:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c56:	89 04 24             	mov    %eax,(%esp)
80108c59:	e8 0f d1 ff ff       	call   80105d6d <memmove>
}
80108c5e:	c9                   	leave  
80108c5f:	c3                   	ret    

80108c60 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108c60:	55                   	push   %ebp
80108c61:	89 e5                	mov    %esp,%ebp
80108c63:	53                   	push   %ebx
80108c64:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108c67:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c6a:	25 ff 0f 00 00       	and    $0xfff,%eax
80108c6f:	85 c0                	test   %eax,%eax
80108c71:	74 0c                	je     80108c7f <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108c73:	c7 04 24 78 9a 10 80 	movl   $0x80109a78,(%esp)
80108c7a:	e8 be 78 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108c7f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108c86:	e9 ad 00 00 00       	jmp    80108d38 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108c8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c8e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108c91:	01 d0                	add    %edx,%eax
80108c93:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108c9a:	00 
80108c9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80108ca2:	89 04 24             	mov    %eax,(%esp)
80108ca5:	e8 a9 fb ff ff       	call   80108853 <walkpgdir>
80108caa:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108cad:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108cb1:	75 0c                	jne    80108cbf <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108cb3:	c7 04 24 9b 9a 10 80 	movl   $0x80109a9b,(%esp)
80108cba:	e8 7e 78 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108cbf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108cc2:	8b 00                	mov    (%eax),%eax
80108cc4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cc9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108ccc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ccf:	8b 55 18             	mov    0x18(%ebp),%edx
80108cd2:	89 d1                	mov    %edx,%ecx
80108cd4:	29 c1                	sub    %eax,%ecx
80108cd6:	89 c8                	mov    %ecx,%eax
80108cd8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108cdd:	77 11                	ja     80108cf0 <loaduvm+0x90>
      n = sz - i;
80108cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ce2:	8b 55 18             	mov    0x18(%ebp),%edx
80108ce5:	89 d1                	mov    %edx,%ecx
80108ce7:	29 c1                	sub    %eax,%ecx
80108ce9:	89 c8                	mov    %ecx,%eax
80108ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108cee:	eb 07                	jmp    80108cf7 <loaduvm+0x97>
    else
      n = PGSIZE;
80108cf0:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108cf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfa:	8b 55 14             	mov    0x14(%ebp),%edx
80108cfd:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108d00:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d03:	89 04 24             	mov    %eax,(%esp)
80108d06:	e8 c5 f6 ff ff       	call   801083d0 <p2v>
80108d0b:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d0e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108d12:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108d16:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d1a:	8b 45 10             	mov    0x10(%ebp),%eax
80108d1d:	89 04 24             	mov    %eax,(%esp)
80108d20:	e8 bd 9b ff ff       	call   801028e2 <readi>
80108d25:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108d28:	74 07                	je     80108d31 <loaduvm+0xd1>
      return -1;
80108d2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d2f:	eb 18                	jmp    80108d49 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108d31:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d3b:	3b 45 18             	cmp    0x18(%ebp),%eax
80108d3e:	0f 82 47 ff ff ff    	jb     80108c8b <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108d44:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108d49:	83 c4 24             	add    $0x24,%esp
80108d4c:	5b                   	pop    %ebx
80108d4d:	5d                   	pop    %ebp
80108d4e:	c3                   	ret    

80108d4f <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108d4f:	55                   	push   %ebp
80108d50:	89 e5                	mov    %esp,%ebp
80108d52:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108d55:	8b 45 10             	mov    0x10(%ebp),%eax
80108d58:	85 c0                	test   %eax,%eax
80108d5a:	79 0a                	jns    80108d66 <allocuvm+0x17>
    return 0;
80108d5c:	b8 00 00 00 00       	mov    $0x0,%eax
80108d61:	e9 c1 00 00 00       	jmp    80108e27 <allocuvm+0xd8>
  if(newsz < oldsz)
80108d66:	8b 45 10             	mov    0x10(%ebp),%eax
80108d69:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108d6c:	73 08                	jae    80108d76 <allocuvm+0x27>
    return oldsz;
80108d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d71:	e9 b1 00 00 00       	jmp    80108e27 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108d76:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d79:	05 ff 0f 00 00       	add    $0xfff,%eax
80108d7e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108d83:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108d86:	e9 8d 00 00 00       	jmp    80108e18 <allocuvm+0xc9>
    mem = kalloc();
80108d8b:	e8 17 ac ff ff       	call   801039a7 <kalloc>
80108d90:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108d93:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108d97:	75 2c                	jne    80108dc5 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108d99:	c7 04 24 b9 9a 10 80 	movl   $0x80109ab9,(%esp)
80108da0:	e8 fc 75 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108da5:	8b 45 0c             	mov    0xc(%ebp),%eax
80108da8:	89 44 24 08          	mov    %eax,0x8(%esp)
80108dac:	8b 45 10             	mov    0x10(%ebp),%eax
80108daf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108db3:	8b 45 08             	mov    0x8(%ebp),%eax
80108db6:	89 04 24             	mov    %eax,(%esp)
80108db9:	e8 6b 00 00 00       	call   80108e29 <deallocuvm>
      return 0;
80108dbe:	b8 00 00 00 00       	mov    $0x0,%eax
80108dc3:	eb 62                	jmp    80108e27 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108dc5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108dcc:	00 
80108dcd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108dd4:	00 
80108dd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108dd8:	89 04 24             	mov    %eax,(%esp)
80108ddb:	e8 ba ce ff ff       	call   80105c9a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108de0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108de3:	89 04 24             	mov    %eax,(%esp)
80108de6:	e8 d8 f5 ff ff       	call   801083c3 <v2p>
80108deb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108dee:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108df5:	00 
80108df6:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108dfa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e01:	00 
80108e02:	89 54 24 04          	mov    %edx,0x4(%esp)
80108e06:	8b 45 08             	mov    0x8(%ebp),%eax
80108e09:	89 04 24             	mov    %eax,(%esp)
80108e0c:	e8 d8 fa ff ff       	call   801088e9 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108e11:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e1b:	3b 45 10             	cmp    0x10(%ebp),%eax
80108e1e:	0f 82 67 ff ff ff    	jb     80108d8b <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108e24:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108e27:	c9                   	leave  
80108e28:	c3                   	ret    

80108e29 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108e29:	55                   	push   %ebp
80108e2a:	89 e5                	mov    %esp,%ebp
80108e2c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108e2f:	8b 45 10             	mov    0x10(%ebp),%eax
80108e32:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108e35:	72 08                	jb     80108e3f <deallocuvm+0x16>
    return oldsz;
80108e37:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e3a:	e9 a4 00 00 00       	jmp    80108ee3 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108e3f:	8b 45 10             	mov    0x10(%ebp),%eax
80108e42:	05 ff 0f 00 00       	add    $0xfff,%eax
80108e47:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108e4f:	e9 80 00 00 00       	jmp    80108ed4 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108e54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e57:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e5e:	00 
80108e5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e63:	8b 45 08             	mov    0x8(%ebp),%eax
80108e66:	89 04 24             	mov    %eax,(%esp)
80108e69:	e8 e5 f9 ff ff       	call   80108853 <walkpgdir>
80108e6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108e71:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e75:	75 09                	jne    80108e80 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108e77:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108e7e:	eb 4d                	jmp    80108ecd <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e83:	8b 00                	mov    (%eax),%eax
80108e85:	83 e0 01             	and    $0x1,%eax
80108e88:	84 c0                	test   %al,%al
80108e8a:	74 41                	je     80108ecd <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108e8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e8f:	8b 00                	mov    (%eax),%eax
80108e91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e96:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108e99:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108e9d:	75 0c                	jne    80108eab <deallocuvm+0x82>
        panic("kfree");
80108e9f:	c7 04 24 d1 9a 10 80 	movl   $0x80109ad1,(%esp)
80108ea6:	e8 92 76 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108eab:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108eae:	89 04 24             	mov    %eax,(%esp)
80108eb1:	e8 1a f5 ff ff       	call   801083d0 <p2v>
80108eb6:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108eb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ebc:	89 04 24             	mov    %eax,(%esp)
80108ebf:	e8 4a aa ff ff       	call   8010390e <kfree>
      *pte = 0;
80108ec4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108ec7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108ecd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ed7:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108eda:	0f 82 74 ff ff ff    	jb     80108e54 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108ee0:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108ee3:	c9                   	leave  
80108ee4:	c3                   	ret    

80108ee5 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108ee5:	55                   	push   %ebp
80108ee6:	89 e5                	mov    %esp,%ebp
80108ee8:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108eeb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108eef:	75 0c                	jne    80108efd <freevm+0x18>
    panic("freevm: no pgdir");
80108ef1:	c7 04 24 d7 9a 10 80 	movl   $0x80109ad7,(%esp)
80108ef8:	e8 40 76 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108efd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f04:	00 
80108f05:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108f0c:	80 
80108f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80108f10:	89 04 24             	mov    %eax,(%esp)
80108f13:	e8 11 ff ff ff       	call   80108e29 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108f18:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f1f:	eb 3c                	jmp    80108f5d <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108f21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f24:	c1 e0 02             	shl    $0x2,%eax
80108f27:	03 45 08             	add    0x8(%ebp),%eax
80108f2a:	8b 00                	mov    (%eax),%eax
80108f2c:	83 e0 01             	and    $0x1,%eax
80108f2f:	84 c0                	test   %al,%al
80108f31:	74 26                	je     80108f59 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f36:	c1 e0 02             	shl    $0x2,%eax
80108f39:	03 45 08             	add    0x8(%ebp),%eax
80108f3c:	8b 00                	mov    (%eax),%eax
80108f3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f43:	89 04 24             	mov    %eax,(%esp)
80108f46:	e8 85 f4 ff ff       	call   801083d0 <p2v>
80108f4b:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108f4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f51:	89 04 24             	mov    %eax,(%esp)
80108f54:	e8 b5 a9 ff ff       	call   8010390e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108f59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108f5d:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108f64:	76 bb                	jbe    80108f21 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108f66:	8b 45 08             	mov    0x8(%ebp),%eax
80108f69:	89 04 24             	mov    %eax,(%esp)
80108f6c:	e8 9d a9 ff ff       	call   8010390e <kfree>
}
80108f71:	c9                   	leave  
80108f72:	c3                   	ret    

80108f73 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108f73:	55                   	push   %ebp
80108f74:	89 e5                	mov    %esp,%ebp
80108f76:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108f79:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f80:	00 
80108f81:	8b 45 0c             	mov    0xc(%ebp),%eax
80108f84:	89 44 24 04          	mov    %eax,0x4(%esp)
80108f88:	8b 45 08             	mov    0x8(%ebp),%eax
80108f8b:	89 04 24             	mov    %eax,(%esp)
80108f8e:	e8 c0 f8 ff ff       	call   80108853 <walkpgdir>
80108f93:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108f96:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108f9a:	75 0c                	jne    80108fa8 <clearpteu+0x35>
    panic("clearpteu");
80108f9c:	c7 04 24 e8 9a 10 80 	movl   $0x80109ae8,(%esp)
80108fa3:	e8 95 75 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108fa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fab:	8b 00                	mov    (%eax),%eax
80108fad:	89 c2                	mov    %eax,%edx
80108faf:	83 e2 fb             	and    $0xfffffffb,%edx
80108fb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fb5:	89 10                	mov    %edx,(%eax)
}
80108fb7:	c9                   	leave  
80108fb8:	c3                   	ret    

80108fb9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108fb9:	55                   	push   %ebp
80108fba:	89 e5                	mov    %esp,%ebp
80108fbc:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108fbf:	e8 b9 f9 ff ff       	call   8010897d <setupkvm>
80108fc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108fc7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108fcb:	75 0a                	jne    80108fd7 <copyuvm+0x1e>
    return 0;
80108fcd:	b8 00 00 00 00       	mov    $0x0,%eax
80108fd2:	e9 f1 00 00 00       	jmp    801090c8 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80108fd7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108fde:	e9 c0 00 00 00       	jmp    801090a3 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108fe3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fe6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108fed:	00 
80108fee:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ff2:	8b 45 08             	mov    0x8(%ebp),%eax
80108ff5:	89 04 24             	mov    %eax,(%esp)
80108ff8:	e8 56 f8 ff ff       	call   80108853 <walkpgdir>
80108ffd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109000:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109004:	75 0c                	jne    80109012 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80109006:	c7 04 24 f2 9a 10 80 	movl   $0x80109af2,(%esp)
8010900d:	e8 2b 75 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109012:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109015:	8b 00                	mov    (%eax),%eax
80109017:	83 e0 01             	and    $0x1,%eax
8010901a:	85 c0                	test   %eax,%eax
8010901c:	75 0c                	jne    8010902a <copyuvm+0x71>
      panic("copyuvm: page not present");
8010901e:	c7 04 24 0c 9b 10 80 	movl   $0x80109b0c,(%esp)
80109025:	e8 13 75 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010902a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010902d:	8b 00                	mov    (%eax),%eax
8010902f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109034:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109037:	e8 6b a9 ff ff       	call   801039a7 <kalloc>
8010903c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010903f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80109043:	74 6f                	je     801090b4 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109045:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109048:	89 04 24             	mov    %eax,(%esp)
8010904b:	e8 80 f3 ff ff       	call   801083d0 <p2v>
80109050:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109057:	00 
80109058:	89 44 24 04          	mov    %eax,0x4(%esp)
8010905c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010905f:	89 04 24             	mov    %eax,(%esp)
80109062:	e8 06 cd ff ff       	call   80105d6d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
80109067:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010906a:	89 04 24             	mov    %eax,(%esp)
8010906d:	e8 51 f3 ff ff       	call   801083c3 <v2p>
80109072:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109075:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010907c:	00 
8010907d:	89 44 24 0c          	mov    %eax,0xc(%esp)
80109081:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109088:	00 
80109089:	89 54 24 04          	mov    %edx,0x4(%esp)
8010908d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109090:	89 04 24             	mov    %eax,(%esp)
80109093:	e8 51 f8 ff ff       	call   801088e9 <mappages>
80109098:	85 c0                	test   %eax,%eax
8010909a:	78 1b                	js     801090b7 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010909c:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090a6:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090a9:	0f 82 34 ff ff ff    	jb     80108fe3 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801090af:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090b2:	eb 14                	jmp    801090c8 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801090b4:	90                   	nop
801090b5:	eb 01                	jmp    801090b8 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801090b7:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801090b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090bb:	89 04 24             	mov    %eax,(%esp)
801090be:	e8 22 fe ff ff       	call   80108ee5 <freevm>
  return 0;
801090c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801090c8:	c9                   	leave  
801090c9:	c3                   	ret    

801090ca <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801090ca:	55                   	push   %ebp
801090cb:	89 e5                	mov    %esp,%ebp
801090cd:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801090d0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801090d7:	00 
801090d8:	8b 45 0c             	mov    0xc(%ebp),%eax
801090db:	89 44 24 04          	mov    %eax,0x4(%esp)
801090df:	8b 45 08             	mov    0x8(%ebp),%eax
801090e2:	89 04 24             	mov    %eax,(%esp)
801090e5:	e8 69 f7 ff ff       	call   80108853 <walkpgdir>
801090ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801090ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090f0:	8b 00                	mov    (%eax),%eax
801090f2:	83 e0 01             	and    $0x1,%eax
801090f5:	85 c0                	test   %eax,%eax
801090f7:	75 07                	jne    80109100 <uva2ka+0x36>
    return 0;
801090f9:	b8 00 00 00 00       	mov    $0x0,%eax
801090fe:	eb 25                	jmp    80109125 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109100:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109103:	8b 00                	mov    (%eax),%eax
80109105:	83 e0 04             	and    $0x4,%eax
80109108:	85 c0                	test   %eax,%eax
8010910a:	75 07                	jne    80109113 <uva2ka+0x49>
    return 0;
8010910c:	b8 00 00 00 00       	mov    $0x0,%eax
80109111:	eb 12                	jmp    80109125 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109113:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109116:	8b 00                	mov    (%eax),%eax
80109118:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010911d:	89 04 24             	mov    %eax,(%esp)
80109120:	e8 ab f2 ff ff       	call   801083d0 <p2v>
}
80109125:	c9                   	leave  
80109126:	c3                   	ret    

80109127 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109127:	55                   	push   %ebp
80109128:	89 e5                	mov    %esp,%ebp
8010912a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010912d:	8b 45 10             	mov    0x10(%ebp),%eax
80109130:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109133:	e9 8b 00 00 00       	jmp    801091c3 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109138:	8b 45 0c             	mov    0xc(%ebp),%eax
8010913b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109140:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109143:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109146:	89 44 24 04          	mov    %eax,0x4(%esp)
8010914a:	8b 45 08             	mov    0x8(%ebp),%eax
8010914d:	89 04 24             	mov    %eax,(%esp)
80109150:	e8 75 ff ff ff       	call   801090ca <uva2ka>
80109155:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80109158:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010915c:	75 07                	jne    80109165 <copyout+0x3e>
      return -1;
8010915e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80109163:	eb 6d                	jmp    801091d2 <copyout+0xab>
    n = PGSIZE - (va - va0);
80109165:	8b 45 0c             	mov    0xc(%ebp),%eax
80109168:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010916b:	89 d1                	mov    %edx,%ecx
8010916d:	29 c1                	sub    %eax,%ecx
8010916f:	89 c8                	mov    %ecx,%eax
80109171:	05 00 10 00 00       	add    $0x1000,%eax
80109176:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80109179:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010917c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010917f:	76 06                	jbe    80109187 <copyout+0x60>
      n = len;
80109181:	8b 45 14             	mov    0x14(%ebp),%eax
80109184:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
80109187:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010918a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010918d:	89 d1                	mov    %edx,%ecx
8010918f:	29 c1                	sub    %eax,%ecx
80109191:	89 c8                	mov    %ecx,%eax
80109193:	03 45 e8             	add    -0x18(%ebp),%eax
80109196:	8b 55 f0             	mov    -0x10(%ebp),%edx
80109199:	89 54 24 08          	mov    %edx,0x8(%esp)
8010919d:	8b 55 f4             	mov    -0xc(%ebp),%edx
801091a0:	89 54 24 04          	mov    %edx,0x4(%esp)
801091a4:	89 04 24             	mov    %eax,(%esp)
801091a7:	e8 c1 cb ff ff       	call   80105d6d <memmove>
    len -= n;
801091ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091af:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801091b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091b5:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801091b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091bb:	05 00 10 00 00       	add    $0x1000,%eax
801091c0:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801091c3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801091c7:	0f 85 6b ff ff ff    	jne    80109138 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801091cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801091d2:	c9                   	leave  
801091d3:	c3                   	ret    

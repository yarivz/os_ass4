
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
8010002d:	b8 0b 46 10 80       	mov    $0x8010460b,%eax
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
8010003a:	c7 44 24 04 34 95 10 	movl   $0x80109534,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 38 5d 00 00       	call   80105d86 <initlock>

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
801000bd:	e8 e5 5c 00 00       	call   80105da7 <acquire>

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
80100104:	e8 00 5d 00 00       	call   80105e09 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 a5 59 00 00       	call   80105ac9 <sleep>
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
8010017c:	e8 88 5c 00 00       	call   80105e09 <release>
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
80100198:	c7 04 24 3b 95 10 80 	movl   $0x8010953b,(%esp)
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
801001d3:	e8 e0 37 00 00       	call   801039b8 <iderw>
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
801001ef:	c7 04 24 4c 95 10 80 	movl   $0x8010954c,(%esp)
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
80100210:	e8 a3 37 00 00       	call   801039b8 <iderw>
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
80100229:	c7 04 24 53 95 10 80 	movl   $0x80109553,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 66 5b 00 00       	call   80105da7 <acquire>

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
8010029d:	e8 00 59 00 00       	call   80105ba2 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 5b 5b 00 00       	call   80105e09 <release>
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
801003bc:	e8 e6 59 00 00       	call   80105da7 <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 5a 95 10 80 	movl   $0x8010955a,(%esp)
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
801004af:	c7 45 ec 63 95 10 80 	movl   $0x80109563,-0x14(%ebp)
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
80100536:	e8 ce 58 00 00       	call   80105e09 <release>
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
80100562:	c7 04 24 6a 95 10 80 	movl   $0x8010956a,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 79 95 10 80 	movl   $0x80109579,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 c1 58 00 00       	call   80105e58 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 7b 95 10 80 	movl   $0x8010957b,(%esp)
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
801006b2:	e8 12 5a 00 00       	call   801060c9 <memmove>
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
801006e1:	e8 10 59 00 00       	call   80105ff6 <memset>
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
80100776:	e8 1e 74 00 00       	call   80107b99 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 12 74 00 00       	call   80107b99 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 06 74 00 00       	call   80107b99 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 f9 73 00 00       	call   80107b99 <uartputc>
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
801007ba:	e8 e8 55 00 00       	call   80105da7 <acquire>
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
801007ea:	e8 56 54 00 00       	call   80105c45 <procdump>
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
801008f7:	e8 a6 52 00 00       	call   80105ba2 <wakeup>
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
8010091e:	e8 e6 54 00 00       	call   80105e09 <release>
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
80100943:	e8 5f 54 00 00       	call   80105da7 <acquire>
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
80100961:	e8 a3 54 00 00       	call   80105e09 <release>
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
8010098a:	e8 3a 51 00 00       	call   80105ac9 <sleep>
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
80100a08:	e8 fc 53 00 00       	call   80105e09 <release>
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
80100a3e:	e8 64 53 00 00       	call   80105da7 <acquire>
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
80100a78:	e8 8c 53 00 00       	call   80105e09 <release>
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
80100a93:	c7 44 24 04 7f 95 10 	movl   $0x8010957f,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100aa2:	e8 df 52 00 00       	call   80105d86 <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 87 95 10 	movl   $0x80109587,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80100ab6:	e8 cb 52 00 00       	call   80105d86 <initlock>

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
80100ae0:	e8 e0 41 00 00       	call   80104cc5 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 81 30 00 00       	call   80103b7a <ioapicenable>
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
80100b0b:	e8 eb 27 00 00       	call   801032fb <namei>
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
80100b74:	c7 04 24 03 3d 10 80 	movl   $0x80103d03,(%esp)
80100b7b:	e8 5d 81 00 00       	call   80108cdd <setupkvm>
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
80100c14:	e8 96 84 00 00       	call   801090af <allocuvm>
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
80100c51:	e8 6a 83 00 00       	call   80108fc0 <loaduvm>
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
80100cbc:	e8 ee 83 00 00       	call   801090af <allocuvm>
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
80100ce0:	e8 ee 85 00 00       	call   801092d3 <clearpteu>
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
80100d0f:	e8 60 55 00 00       	call   80106274 <strlen>
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
80100d2d:	e8 42 55 00 00       	call   80106274 <strlen>
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
80100d57:	e8 2b 87 00 00       	call   80109487 <copyout>
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
80100df7:	e8 8b 86 00 00       	call   80109487 <copyout>
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
80100e4e:	e8 d3 53 00 00       	call   80106226 <safestrcpy>

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
80100ea0:	e8 29 7f 00 00       	call   80108dce <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 95 83 00 00       	call   80109245 <freevm>
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
80100ee2:	e8 5e 83 00 00       	call   80109245 <freevm>
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
80100f06:	c7 44 24 04 90 95 10 	movl   $0x80109590,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100f15:	e8 6c 4e 00 00       	call   80105d86 <initlock>
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
80100f29:	e8 79 4e 00 00       	call   80105da7 <acquire>
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
80100f52:	e8 b2 4e 00 00       	call   80105e09 <release>
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
80100f70:	e8 94 4e 00 00       	call   80105e09 <release>
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
80100f89:	e8 19 4e 00 00       	call   80105da7 <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 97 95 10 80 	movl   $0x80109597,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 a0 ee 10 80 	movl   $0x8010eea0,(%esp)
80100fba:	e8 4a 4e 00 00       	call   80105e09 <release>
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
80100fd1:	e8 d1 4d 00 00       	call   80105da7 <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 9f 95 10 80 	movl   $0x8010959f,(%esp)
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
8010100c:	e8 f8 4d 00 00       	call   80105e09 <release>
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
80101056:	e8 ae 4d 00 00       	call   80105e09 <release>
  
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
80101074:	e8 06 3f 00 00       	call   80104f7f <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 99 33 00 00       	call   80104421 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 90 17 00 00       	call   80102823 <iput>
    commit_trans();
80101093:	e8 d2 33 00 00       	call   8010446a <commit_trans>
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
80101125:	e8 d7 3f 00 00       	call   80105101 <piperead>
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
80101197:	c7 04 24 a9 95 10 80 	movl   $0x801095a9,(%esp)
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
801011e2:	e8 2a 3e 00 00       	call   80105011 <pipewrite>
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
8010122a:	e8 f2 31 00 00       	call   80104421 <begin_trans>
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
80101290:	e8 d5 31 00 00       	call   8010446a <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 b2 95 10 80 	movl   $0x801095b2,(%esp)
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
801012d8:	c7 04 24 c2 95 10 80 	movl   $0x801095c2,(%esp)
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
801012fe:	e8 22 5a 00 00       	call   80106d25 <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 cc 95 10 80 	movl   $0x801095cc,(%esp)
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
80101344:	c7 04 24 e4 95 10 80 	movl   $0x801095e4,(%esp)
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
80101382:	c7 04 24 07 96 10 80 	movl   $0x80109607,(%esp)
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
801013b7:	c7 04 24 20 96 10 80 	movl   $0x80109620,(%esp)
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
80101414:	c7 04 24 3f 96 10 80 	movl   $0x8010963f,(%esp)
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
8010162b:	e8 74 1e 00 00       	call   801034a4 <updateBlkRef>
  int ref = getBlkRef(b1->sector);
80101630:	8b 45 10             	mov    0x10(%ebp),%eax
80101633:	8b 40 08             	mov    0x8(%eax),%eax
80101636:	89 04 24             	mov    %eax,(%esp)
80101639:	e8 95 1f 00 00       	call   801035d3 <getBlkRef>
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
80101658:	e8 47 1e 00 00       	call   801034a4 <updateBlkRef>
8010165d:	eb 28                	jmp    80101687 <deletedups+0xff>
  else if(ref == 0)
8010165f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101663:	75 22                	jne    80101687 <deletedups+0xff>
  {
    begin_trans();
80101665:	e8 b7 2d 00 00       	call   80104421 <begin_trans>
    bfree(b1->dev, b1->sector);
8010166a:	8b 45 10             	mov    0x10(%ebp),%eax
8010166d:	8b 50 08             	mov    0x8(%eax),%edx
80101670:	8b 45 10             	mov    0x10(%ebp),%eax
80101673:	8b 40 04             	mov    0x4(%eax),%eax
80101676:	89 54 24 04          	mov    %edx,0x4(%esp)
8010167a:	89 04 24             	mov    %eax,(%esp)
8010167d:	e8 60 0c 00 00       	call   801022e2 <bfree>
    commit_trans();
80101682:	e8 e3 2d 00 00       	call   8010446a <commit_trans>
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
80101706:	e8 3a 1f 00 00       	call   80103645 <zeroNextInum>
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
80101e1e:	e8 d0 15 00 00       	call   801033f3 <getPrevInode>
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
80101e8d:	e8 8f 25 00 00       	call   80104421 <begin_trans>
      iupdate(ip1);
80101e92:	8b 45 c0             	mov    -0x40(%ebp),%eax
80101e95:	89 04 24             	mov    %eax,(%esp)
80101e98:	e8 17 06 00 00       	call   801024b4 <iupdate>
      commit_trans();
80101e9d:	e8 c8 25 00 00       	call   8010446a <commit_trans>
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
80101ead:	e8 8d 14 00 00       	call   8010333f <getNextInode>
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
80101faa:	c7 04 24 58 96 10 80 	movl   $0x80109658,(%esp)
80101fb1:	e8 eb e3 ff ff       	call   801003a1 <cprintf>
   
  cprintf("Shared block rate is: 0.");
80101fb6:	c7 04 24 70 96 10 80 	movl   $0x80109670,(%esp)
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
80101fee:	c7 04 24 89 96 10 80 	movl   $0x80109689,(%esp)
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
80102012:	c7 04 24 8c 96 10 80 	movl   $0x8010968c,(%esp)
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
80102128:	e8 9c 3f 00 00       	call   801060c9 <memmove>
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
8010216e:	e8 83 3e 00 00       	call   80105ff6 <memset>
  log_write(bp);
80102173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102176:	89 04 24             	mov    %eax,(%esp)
80102179:	e8 44 23 00 00       	call   801044c2 <log_write>
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
8010225f:	e8 5e 22 00 00       	call   801044c2 <log_write>
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
801022d6:	c7 04 24 8e 96 10 80 	movl   $0x8010968e,(%esp)
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
8010236d:	c7 04 24 a4 96 10 80 	movl   $0x801096a4,(%esp)
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
801023a5:	e8 18 21 00 00       	call   801044c2 <log_write>
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
801023c1:	c7 44 24 04 b7 96 10 	movl   $0x801096b7,0x4(%esp)
801023c8:	80 
801023c9:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801023d0:	e8 b1 39 00 00       	call   80105d86 <initlock>
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
80102452:	e8 9f 3b 00 00       	call   80105ff6 <memset>
      dip->type = type;
80102457:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010245a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010245e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80102461:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102464:	89 04 24             	mov    %eax,(%esp)
80102467:	e8 56 20 00 00       	call   801044c2 <log_write>
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
801024a8:	c7 04 24 be 96 10 80 	movl   $0x801096be,(%esp)
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
8010254f:	e8 75 3b 00 00       	call   801060c9 <memmove>
  log_write(bp);
80102554:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102557:	89 04 24             	mov    %eax,(%esp)
8010255a:	e8 63 1f 00 00       	call   801044c2 <log_write>
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
80102579:	e8 29 38 00 00       	call   80105da7 <acquire>

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
801025c3:	e8 41 38 00 00       	call   80105e09 <release>
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
801025f6:	c7 04 24 d0 96 10 80 	movl   $0x801096d0,(%esp)
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
80102634:	e8 d0 37 00 00       	call   80105e09 <release>

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
8010264b:	e8 57 37 00 00       	call   80105da7 <acquire>
  ip->ref++;
80102650:	8b 45 08             	mov    0x8(%ebp),%eax
80102653:	8b 40 08             	mov    0x8(%eax),%eax
80102656:	8d 50 01             	lea    0x1(%eax),%edx
80102659:	8b 45 08             	mov    0x8(%ebp),%eax
8010265c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010265f:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102666:	e8 9e 37 00 00       	call   80105e09 <release>
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
80102686:	c7 04 24 e0 96 10 80 	movl   $0x801096e0,(%esp)
8010268d:	e8 ab de ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80102692:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80102699:	e8 09 37 00 00       	call   80105da7 <acquire>
  while(ip->flags & I_BUSY)
8010269e:	eb 13                	jmp    801026b3 <ilock+0x43>
    sleep(ip, &icache.lock);
801026a0:	c7 44 24 04 a0 f8 10 	movl   $0x8010f8a0,0x4(%esp)
801026a7:	80 
801026a8:	8b 45 08             	mov    0x8(%ebp),%eax
801026ab:	89 04 24             	mov    %eax,(%esp)
801026ae:	e8 16 34 00 00       	call   80105ac9 <sleep>

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
801026d8:	e8 2c 37 00 00       	call   80105e09 <release>

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
80102783:	e8 41 39 00 00       	call   801060c9 <memmove>
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
801027b0:	c7 04 24 e6 96 10 80 	movl   $0x801096e6,(%esp)
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
801027e1:	c7 04 24 f5 96 10 80 	movl   $0x801096f5,(%esp)
801027e8:	e8 50 dd ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801027ed:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801027f4:	e8 ae 35 00 00       	call   80105da7 <acquire>
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
80102810:	e8 8d 33 00 00       	call   80105ba2 <wakeup>
  release(&icache.lock);
80102815:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
8010281c:	e8 e8 35 00 00       	call   80105e09 <release>
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
80102830:	e8 72 35 00 00       	call   80105da7 <acquire>
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
8010286e:	c7 04 24 fd 96 10 80 	movl   $0x801096fd,(%esp)
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
80102892:	e8 72 35 00 00       	call   80105e09 <release>
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
801028bd:	e8 e5 34 00 00       	call   80105da7 <acquire>
    ip->flags = 0;
801028c2:	8b 45 08             	mov    0x8(%ebp),%eax
801028c5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
801028cc:	8b 45 08             	mov    0x8(%ebp),%eax
801028cf:	89 04 24             	mov    %eax,(%esp)
801028d2:	e8 cb 32 00 00       	call   80105ba2 <wakeup>
  }
  ip->ref--;
801028d7:	8b 45 08             	mov    0x8(%ebp),%eax
801028da:	8b 40 08             	mov    0x8(%eax),%eax
801028dd:	8d 50 ff             	lea    -0x1(%eax),%edx
801028e0:	8b 45 08             	mov    0x8(%ebp),%eax
801028e3:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801028e6:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801028ed:	e8 17 35 00 00       	call   80105e09 <release>
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
801029ed:	e8 d0 1a 00 00       	call   801044c2 <log_write>
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
80102a02:	c7 04 24 07 97 10 80 	movl   $0x80109707,(%esp)
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
80102a44:	e8 8a 0b 00 00       	call   801035d3 <getBlkRef>
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
80102a65:	e8 3a 0a 00 00       	call   801034a4 <updateBlkRef>
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
80102b00:	e8 ce 0a 00 00       	call   801035d3 <getBlkRef>
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
80102b1f:	e8 80 09 00 00       	call   801034a4 <updateBlkRef>
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
80102d0a:	e8 ba 33 00 00       	call   801060c9 <memmove>
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
  uint tot, m;
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
80102d86:	e9 bf 01 00 00       	jmp    80102f4a <writei+0x209>
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
80102db0:	e9 95 01 00 00       	jmp    80102f4a <writei+0x209>
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
80102dd2:	e9 73 01 00 00       	jmp    80102f4a <writei+0x209>
  if(off + n > MAXFILE*BSIZE)
80102dd7:	8b 45 14             	mov    0x14(%ebp),%eax
80102dda:	8b 55 10             	mov    0x10(%ebp),%edx
80102ddd:	01 d0                	add    %edx,%eax
80102ddf:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102de4:	76 0a                	jbe    80102df0 <writei+0xaf>
    return -1;
80102de6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102deb:	e9 5a 01 00 00       	jmp    80102f4a <writei+0x209>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102df0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102df7:	e9 1a 01 00 00       	jmp    80102f16 <writei+0x1d5>
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
    if(getBlkRef(bp->sector) > 0)
80102e25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e28:	8b 40 08             	mov    0x8(%eax),%eax
80102e2b:	89 04 24             	mov    %eax,(%esp)
80102e2e:	e8 a0 07 00 00       	call   801035d3 <getBlkRef>
80102e33:	85 c0                	test   %eax,%eax
80102e35:	7e 67                	jle    80102e9e <writei+0x15d>
    {//cprintf ("inside\n");
      uint old = bp->sector;
80102e37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e3a:	8b 40 08             	mov    0x8(%eax),%eax
80102e3d:	89 45 ec             	mov    %eax,-0x14(%ebp)
      updateBlkRef(old,-1);
80102e40:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
80102e47:	ff 
80102e48:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102e4b:	89 04 24             	mov    %eax,(%esp)
80102e4e:	e8 51 06 00 00       	call   801034a4 <updateBlkRef>
      brelse(bp);
80102e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102e56:	89 04 24             	mov    %eax,(%esp)
80102e59:	e8 b9 d3 ff ff       	call   80100217 <brelse>
      uint new = balloc(ip->dev);
80102e5e:	8b 45 08             	mov    0x8(%ebp),%eax
80102e61:	8b 00                	mov    (%eax),%eax
80102e63:	89 04 24             	mov    %eax,(%esp)
80102e66:	e8 20 f3 ff ff       	call   8010218b <balloc>
80102e6b:	89 45 e8             	mov    %eax,-0x18(%ebp)
      replaceBlk(ip,old,new);
80102e6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102e71:	89 44 24 08          	mov    %eax,0x8(%esp)
80102e75:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80102e7c:	8b 45 08             	mov    0x8(%ebp),%eax
80102e7f:	89 04 24             	mov    %eax,(%esp)
80102e82:	e8 a5 f1 ff ff       	call   8010202c <replaceBlk>
      bp = bread(ip->dev,new);
80102e87:	8b 45 08             	mov    0x8(%ebp),%eax
80102e8a:	8b 00                	mov    (%eax),%eax
80102e8c:	8b 55 e8             	mov    -0x18(%ebp),%edx
80102e8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80102e93:	89 04 24             	mov    %eax,(%esp)
80102e96:	e8 0b d3 ff ff       	call   801001a6 <bread>
80102e9b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    m = min(n - tot, BSIZE - off%BSIZE);
80102e9e:	8b 45 10             	mov    0x10(%ebp),%eax
80102ea1:	89 c2                	mov    %eax,%edx
80102ea3:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102ea9:	b8 00 02 00 00       	mov    $0x200,%eax
80102eae:	89 c1                	mov    %eax,%ecx
80102eb0:	29 d1                	sub    %edx,%ecx
80102eb2:	89 ca                	mov    %ecx,%edx
80102eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eb7:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102eba:	89 cb                	mov    %ecx,%ebx
80102ebc:	29 c3                	sub    %eax,%ebx
80102ebe:	89 d8                	mov    %ebx,%eax
80102ec0:	39 c2                	cmp    %eax,%edx
80102ec2:	0f 46 c2             	cmovbe %edx,%eax
80102ec5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102ec8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ecb:	8d 50 18             	lea    0x18(%eax),%edx
80102ece:	8b 45 10             	mov    0x10(%ebp),%eax
80102ed1:	25 ff 01 00 00       	and    $0x1ff,%eax
80102ed6:	01 c2                	add    %eax,%edx
80102ed8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102edb:	89 44 24 08          	mov    %eax,0x8(%esp)
80102edf:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ee2:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ee6:	89 14 24             	mov    %edx,(%esp)
80102ee9:	e8 db 31 00 00       	call   801060c9 <memmove>
    log_write(bp);
80102eee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102ef1:	89 04 24             	mov    %eax,(%esp)
80102ef4:	e8 c9 15 00 00       	call   801044c2 <log_write>
    brelse(bp);
80102ef9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102efc:	89 04 24             	mov    %eax,(%esp)
80102eff:	e8 13 d3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102f04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f07:	01 45 f4             	add    %eax,-0xc(%ebp)
80102f0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f0d:	01 45 10             	add    %eax,0x10(%ebp)
80102f10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f13:	01 45 0c             	add    %eax,0xc(%ebp)
80102f16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102f19:	3b 45 14             	cmp    0x14(%ebp),%eax
80102f1c:	0f 82 da fe ff ff    	jb     80102dfc <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102f22:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102f26:	74 1f                	je     80102f47 <writei+0x206>
80102f28:	8b 45 08             	mov    0x8(%ebp),%eax
80102f2b:	8b 40 18             	mov    0x18(%eax),%eax
80102f2e:	3b 45 10             	cmp    0x10(%ebp),%eax
80102f31:	73 14                	jae    80102f47 <writei+0x206>
    ip->size = off;
80102f33:	8b 45 08             	mov    0x8(%ebp),%eax
80102f36:	8b 55 10             	mov    0x10(%ebp),%edx
80102f39:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102f3c:	8b 45 08             	mov    0x8(%ebp),%eax
80102f3f:	89 04 24             	mov    %eax,(%esp)
80102f42:	e8 6d f5 ff ff       	call   801024b4 <iupdate>
  }
  return n;
80102f47:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102f4a:	83 c4 34             	add    $0x34,%esp
80102f4d:	5b                   	pop    %ebx
80102f4e:	5d                   	pop    %ebp
80102f4f:	c3                   	ret    

80102f50 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102f50:	55                   	push   %ebp
80102f51:	89 e5                	mov    %esp,%ebp
80102f53:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102f56:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102f5d:	00 
80102f5e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f61:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f65:	8b 45 08             	mov    0x8(%ebp),%eax
80102f68:	89 04 24             	mov    %eax,(%esp)
80102f6b:	e8 fd 31 00 00       	call   8010616d <strncmp>
}
80102f70:	c9                   	leave  
80102f71:	c3                   	ret    

80102f72 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102f72:	55                   	push   %ebp
80102f73:	89 e5                	mov    %esp,%ebp
80102f75:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102f78:	8b 45 08             	mov    0x8(%ebp),%eax
80102f7b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102f7f:	66 83 f8 01          	cmp    $0x1,%ax
80102f83:	74 0c                	je     80102f91 <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102f85:	c7 04 24 1a 97 10 80 	movl   $0x8010971a,(%esp)
80102f8c:	e8 ac d5 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102f91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102f98:	e9 87 00 00 00       	jmp    80103024 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102f9d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102fa4:	00 
80102fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fa8:	89 44 24 08          	mov    %eax,0x8(%esp)
80102fac:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102faf:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fb3:	8b 45 08             	mov    0x8(%ebp),%eax
80102fb6:	89 04 24             	mov    %eax,(%esp)
80102fb9:	e8 18 fc ff ff       	call   80102bd6 <readi>
80102fbe:	83 f8 10             	cmp    $0x10,%eax
80102fc1:	74 0c                	je     80102fcf <dirlookup+0x5d>
      panic("dirlink read");
80102fc3:	c7 04 24 2c 97 10 80 	movl   $0x8010972c,(%esp)
80102fca:	e8 6e d5 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102fcf:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102fd3:	66 85 c0             	test   %ax,%ax
80102fd6:	74 47                	je     8010301f <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102fd8:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102fdb:	83 c0 02             	add    $0x2,%eax
80102fde:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fe2:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fe5:	89 04 24             	mov    %eax,(%esp)
80102fe8:	e8 63 ff ff ff       	call   80102f50 <namecmp>
80102fed:	85 c0                	test   %eax,%eax
80102fef:	75 2f                	jne    80103020 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102ff1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102ff5:	74 08                	je     80102fff <dirlookup+0x8d>
        *poff = off;
80102ff7:	8b 45 10             	mov    0x10(%ebp),%eax
80102ffa:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ffd:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102fff:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80103003:	0f b7 c0             	movzwl %ax,%eax
80103006:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80103009:	8b 45 08             	mov    0x8(%ebp),%eax
8010300c:	8b 00                	mov    (%eax),%eax
8010300e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80103011:	89 54 24 04          	mov    %edx,0x4(%esp)
80103015:	89 04 24             	mov    %eax,(%esp)
80103018:	e8 4f f5 ff ff       	call   8010256c <iget>
8010301d:	eb 19                	jmp    80103038 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
8010301f:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80103020:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103024:	8b 45 08             	mov    0x8(%ebp),%eax
80103027:	8b 40 18             	mov    0x18(%eax),%eax
8010302a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010302d:	0f 87 6a ff ff ff    	ja     80102f9d <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80103033:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103038:	c9                   	leave  
80103039:	c3                   	ret    

8010303a <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
8010303a:	55                   	push   %ebp
8010303b:	89 e5                	mov    %esp,%ebp
8010303d:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80103040:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103047:	00 
80103048:	8b 45 0c             	mov    0xc(%ebp),%eax
8010304b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010304f:	8b 45 08             	mov    0x8(%ebp),%eax
80103052:	89 04 24             	mov    %eax,(%esp)
80103055:	e8 18 ff ff ff       	call   80102f72 <dirlookup>
8010305a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010305d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103061:	74 15                	je     80103078 <dirlink+0x3e>
    iput(ip);
80103063:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103066:	89 04 24             	mov    %eax,(%esp)
80103069:	e8 b5 f7 ff ff       	call   80102823 <iput>
    return -1;
8010306e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103073:	e9 b8 00 00 00       	jmp    80103130 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80103078:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010307f:	eb 44                	jmp    801030c5 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80103081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103084:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010308b:	00 
8010308c:	89 44 24 08          	mov    %eax,0x8(%esp)
80103090:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103093:	89 44 24 04          	mov    %eax,0x4(%esp)
80103097:	8b 45 08             	mov    0x8(%ebp),%eax
8010309a:	89 04 24             	mov    %eax,(%esp)
8010309d:	e8 34 fb ff ff       	call   80102bd6 <readi>
801030a2:	83 f8 10             	cmp    $0x10,%eax
801030a5:	74 0c                	je     801030b3 <dirlink+0x79>
      panic("dirlink read");
801030a7:	c7 04 24 2c 97 10 80 	movl   $0x8010972c,(%esp)
801030ae:	e8 8a d4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
801030b3:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801030b7:	66 85 c0             	test   %ax,%ax
801030ba:	74 18                	je     801030d4 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801030bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030bf:	83 c0 10             	add    $0x10,%eax
801030c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801030c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801030c8:	8b 45 08             	mov    0x8(%ebp),%eax
801030cb:	8b 40 18             	mov    0x18(%eax),%eax
801030ce:	39 c2                	cmp    %eax,%edx
801030d0:	72 af                	jb     80103081 <dirlink+0x47>
801030d2:	eb 01                	jmp    801030d5 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
801030d4:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
801030d5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801030dc:	00 
801030dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801030e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801030e4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801030e7:	83 c0 02             	add    $0x2,%eax
801030ea:	89 04 24             	mov    %eax,(%esp)
801030ed:	e8 d3 30 00 00       	call   801061c5 <strncpy>
  de.inum = inum;
801030f2:	8b 45 10             	mov    0x10(%ebp),%eax
801030f5:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801030f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030fc:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80103103:	00 
80103104:	89 44 24 08          	mov    %eax,0x8(%esp)
80103108:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010310b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010310f:	8b 45 08             	mov    0x8(%ebp),%eax
80103112:	89 04 24             	mov    %eax,(%esp)
80103115:	e8 27 fc ff ff       	call   80102d41 <writei>
8010311a:	83 f8 10             	cmp    $0x10,%eax
8010311d:	74 0c                	je     8010312b <dirlink+0xf1>
    panic("dirlink");
8010311f:	c7 04 24 39 97 10 80 	movl   $0x80109739,(%esp)
80103126:	e8 12 d4 ff ff       	call   8010053d <panic>
  
  return 0;
8010312b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103130:	c9                   	leave  
80103131:	c3                   	ret    

80103132 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80103132:	55                   	push   %ebp
80103133:	89 e5                	mov    %esp,%ebp
80103135:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80103138:	eb 04                	jmp    8010313e <skipelem+0xc>
    path++;
8010313a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
8010313e:	8b 45 08             	mov    0x8(%ebp),%eax
80103141:	0f b6 00             	movzbl (%eax),%eax
80103144:	3c 2f                	cmp    $0x2f,%al
80103146:	74 f2                	je     8010313a <skipelem+0x8>
    path++;
  if(*path == 0)
80103148:	8b 45 08             	mov    0x8(%ebp),%eax
8010314b:	0f b6 00             	movzbl (%eax),%eax
8010314e:	84 c0                	test   %al,%al
80103150:	75 0a                	jne    8010315c <skipelem+0x2a>
    return 0;
80103152:	b8 00 00 00 00       	mov    $0x0,%eax
80103157:	e9 86 00 00 00       	jmp    801031e2 <skipelem+0xb0>
  s = path;
8010315c:	8b 45 08             	mov    0x8(%ebp),%eax
8010315f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80103162:	eb 04                	jmp    80103168 <skipelem+0x36>
    path++;
80103164:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80103168:	8b 45 08             	mov    0x8(%ebp),%eax
8010316b:	0f b6 00             	movzbl (%eax),%eax
8010316e:	3c 2f                	cmp    $0x2f,%al
80103170:	74 0a                	je     8010317c <skipelem+0x4a>
80103172:	8b 45 08             	mov    0x8(%ebp),%eax
80103175:	0f b6 00             	movzbl (%eax),%eax
80103178:	84 c0                	test   %al,%al
8010317a:	75 e8                	jne    80103164 <skipelem+0x32>
    path++;
  len = path - s;
8010317c:	8b 55 08             	mov    0x8(%ebp),%edx
8010317f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103182:	89 d1                	mov    %edx,%ecx
80103184:	29 c1                	sub    %eax,%ecx
80103186:	89 c8                	mov    %ecx,%eax
80103188:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
8010318b:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010318f:	7e 1c                	jle    801031ad <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80103191:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80103198:	00 
80103199:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010319c:	89 44 24 04          	mov    %eax,0x4(%esp)
801031a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801031a3:	89 04 24             	mov    %eax,(%esp)
801031a6:	e8 1e 2f 00 00       	call   801060c9 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801031ab:	eb 28                	jmp    801031d5 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801031ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031b0:	89 44 24 08          	mov    %eax,0x8(%esp)
801031b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801031bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801031be:	89 04 24             	mov    %eax,(%esp)
801031c1:	e8 03 2f 00 00       	call   801060c9 <memmove>
    name[len] = 0;
801031c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031c9:	03 45 0c             	add    0xc(%ebp),%eax
801031cc:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801031cf:	eb 04                	jmp    801031d5 <skipelem+0xa3>
    path++;
801031d1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801031d5:	8b 45 08             	mov    0x8(%ebp),%eax
801031d8:	0f b6 00             	movzbl (%eax),%eax
801031db:	3c 2f                	cmp    $0x2f,%al
801031dd:	74 f2                	je     801031d1 <skipelem+0x9f>
    path++;
  return path;
801031df:	8b 45 08             	mov    0x8(%ebp),%eax
}
801031e2:	c9                   	leave  
801031e3:	c3                   	ret    

801031e4 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801031e4:	55                   	push   %ebp
801031e5:	89 e5                	mov    %esp,%ebp
801031e7:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801031ea:	8b 45 08             	mov    0x8(%ebp),%eax
801031ed:	0f b6 00             	movzbl (%eax),%eax
801031f0:	3c 2f                	cmp    $0x2f,%al
801031f2:	75 1c                	jne    80103210 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801031f4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801031fb:	00 
801031fc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103203:	e8 64 f3 ff ff       	call   8010256c <iget>
80103208:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010320b:	e9 af 00 00 00       	jmp    801032bf <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80103210:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103216:	8b 40 68             	mov    0x68(%eax),%eax
80103219:	89 04 24             	mov    %eax,(%esp)
8010321c:	e8 1d f4 ff ff       	call   8010263e <idup>
80103221:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80103224:	e9 96 00 00 00       	jmp    801032bf <namex+0xdb>
    ilock(ip);
80103229:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010322c:	89 04 24             	mov    %eax,(%esp)
8010322f:	e8 3c f4 ff ff       	call   80102670 <ilock>
    if(ip->type != T_DIR){
80103234:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103237:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010323b:	66 83 f8 01          	cmp    $0x1,%ax
8010323f:	74 15                	je     80103256 <namex+0x72>
      iunlockput(ip);
80103241:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103244:	89 04 24             	mov    %eax,(%esp)
80103247:	e8 a8 f6 ff ff       	call   801028f4 <iunlockput>
      return 0;
8010324c:	b8 00 00 00 00       	mov    $0x0,%eax
80103251:	e9 a3 00 00 00       	jmp    801032f9 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80103256:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010325a:	74 1d                	je     80103279 <namex+0x95>
8010325c:	8b 45 08             	mov    0x8(%ebp),%eax
8010325f:	0f b6 00             	movzbl (%eax),%eax
80103262:	84 c0                	test   %al,%al
80103264:	75 13                	jne    80103279 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80103266:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103269:	89 04 24             	mov    %eax,(%esp)
8010326c:	e8 4d f5 ff ff       	call   801027be <iunlock>
      return ip;
80103271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103274:	e9 80 00 00 00       	jmp    801032f9 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80103279:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80103280:	00 
80103281:	8b 45 10             	mov    0x10(%ebp),%eax
80103284:	89 44 24 04          	mov    %eax,0x4(%esp)
80103288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010328b:	89 04 24             	mov    %eax,(%esp)
8010328e:	e8 df fc ff ff       	call   80102f72 <dirlookup>
80103293:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103296:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010329a:	75 12                	jne    801032ae <namex+0xca>
      iunlockput(ip);
8010329c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010329f:	89 04 24             	mov    %eax,(%esp)
801032a2:	e8 4d f6 ff ff       	call   801028f4 <iunlockput>
      return 0;
801032a7:	b8 00 00 00 00       	mov    $0x0,%eax
801032ac:	eb 4b                	jmp    801032f9 <namex+0x115>
    }
    iunlockput(ip);
801032ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032b1:	89 04 24             	mov    %eax,(%esp)
801032b4:	e8 3b f6 ff ff       	call   801028f4 <iunlockput>
    ip = next;
801032b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801032bf:	8b 45 10             	mov    0x10(%ebp),%eax
801032c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801032c6:	8b 45 08             	mov    0x8(%ebp),%eax
801032c9:	89 04 24             	mov    %eax,(%esp)
801032cc:	e8 61 fe ff ff       	call   80103132 <skipelem>
801032d1:	89 45 08             	mov    %eax,0x8(%ebp)
801032d4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801032d8:	0f 85 4b ff ff ff    	jne    80103229 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801032de:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801032e2:	74 12                	je     801032f6 <namex+0x112>
    iput(ip);
801032e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032e7:	89 04 24             	mov    %eax,(%esp)
801032ea:	e8 34 f5 ff ff       	call   80102823 <iput>
    return 0;
801032ef:	b8 00 00 00 00       	mov    $0x0,%eax
801032f4:	eb 03                	jmp    801032f9 <namex+0x115>
  }
  return ip;
801032f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801032f9:	c9                   	leave  
801032fa:	c3                   	ret    

801032fb <namei>:

struct inode*
namei(char *path)
{
801032fb:	55                   	push   %ebp
801032fc:	89 e5                	mov    %esp,%ebp
801032fe:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80103301:	8d 45 ea             	lea    -0x16(%ebp),%eax
80103304:	89 44 24 08          	mov    %eax,0x8(%esp)
80103308:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010330f:	00 
80103310:	8b 45 08             	mov    0x8(%ebp),%eax
80103313:	89 04 24             	mov    %eax,(%esp)
80103316:	e8 c9 fe ff ff       	call   801031e4 <namex>
}
8010331b:	c9                   	leave  
8010331c:	c3                   	ret    

8010331d <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010331d:	55                   	push   %ebp
8010331e:	89 e5                	mov    %esp,%ebp
80103320:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80103323:	8b 45 0c             	mov    0xc(%ebp),%eax
80103326:	89 44 24 08          	mov    %eax,0x8(%esp)
8010332a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103331:	00 
80103332:	8b 45 08             	mov    0x8(%ebp),%eax
80103335:	89 04 24             	mov    %eax,(%esp)
80103338:	e8 a7 fe ff ff       	call   801031e4 <namex>
}
8010333d:	c9                   	leave  
8010333e:	c3                   	ret    

8010333f <getNextInode>:

struct inode*
getNextInode(void)
{
8010333f:	55                   	push   %ebp
80103340:	89 e5                	mov    %esp,%ebp
80103342:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
80103345:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103348:	89 44 24 04          	mov    %eax,0x4(%esp)
8010334c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103353:	e8 9c ed ff ff       	call   801020f4 <readsb>
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
80103358:	a1 18 c6 10 80       	mov    0x8010c618,%eax
8010335d:	83 c0 01             	add    $0x1,%eax
80103360:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103363:	eb 79                	jmp    801033de <getNextInode+0x9f>
  {
    bp = bread(1, IBLOCK(inum));
80103365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103368:	c1 e8 03             	shr    $0x3,%eax
8010336b:	83 c0 02             	add    $0x2,%eax
8010336e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103372:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103379:	e8 28 ce ff ff       	call   801001a6 <bread>
8010337e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80103381:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103384:	8d 50 18             	lea    0x18(%eax),%edx
80103387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010338a:	83 e0 07             	and    $0x7,%eax
8010338d:	c1 e0 06             	shl    $0x6,%eax
80103390:	01 d0                	add    %edx,%eax
80103392:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103395:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103398:	0f b7 00             	movzwl (%eax),%eax
8010339b:	66 83 f8 02          	cmp    $0x2,%ax
8010339f:	75 2e                	jne    801033cf <getNextInode+0x90>
    {
      nextInum = inum;
801033a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033a4:	a3 18 c6 10 80       	mov    %eax,0x8010c618
      //cprintf("next: nextInum = %d\n",nextInum);
      ip = iget(1,inum);
801033a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801033b0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033b7:	e8 b0 f1 ff ff       	call   8010256c <iget>
801033bc:	89 45 e8             	mov    %eax,-0x18(%ebp)
      brelse(bp);
801033bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c2:	89 04 24             	mov    %eax,(%esp)
801033c5:	e8 4d ce ff ff       	call   80100217 <brelse>
      return ip;
801033ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
801033cd:	eb 22                	jmp    801033f1 <getNextInode+0xb2>
    }
    brelse(bp);
801033cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033d2:	89 04 24             	mov    %eax,(%esp)
801033d5:	e8 3d ce ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct inode* ip;
  struct superblock sb;

  readsb(1, &sb);
  for(inum = nextInum+1; inum < sb.ninodes; inum++)
801033da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033de:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801033e4:	39 c2                	cmp    %eax,%edx
801033e6:	0f 82 79 ff ff ff    	jb     80103365 <getNextInode+0x26>
      brelse(bp);
      return ip;
    }
    brelse(bp);
  }
  return 0;
801033ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033f1:	c9                   	leave  
801033f2:	c3                   	ret    

801033f3 <getPrevInode>:

struct inode*
getPrevInode(int* prevInum)
{
801033f3:	55                   	push   %ebp
801033f4:	89 e5                	mov    %esp,%ebp
801033f6:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
801033f9:	e9 8d 00 00 00       	jmp    8010348b <getPrevInode+0x98>
  {
    bp = bread(1, IBLOCK(*prevInum));
801033fe:	8b 45 08             	mov    0x8(%ebp),%eax
80103401:	8b 00                	mov    (%eax),%eax
80103403:	c1 e8 03             	shr    $0x3,%eax
80103406:	83 c0 02             	add    $0x2,%eax
80103409:	89 44 24 04          	mov    %eax,0x4(%esp)
8010340d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103414:	e8 8d cd ff ff       	call   801001a6 <bread>
80103419:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + (*prevInum)%IPB;
8010341c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010341f:	8d 50 18             	lea    0x18(%eax),%edx
80103422:	8b 45 08             	mov    0x8(%ebp),%eax
80103425:	8b 00                	mov    (%eax),%eax
80103427:	83 e0 07             	and    $0x7,%eax
8010342a:	c1 e0 06             	shl    $0x6,%eax
8010342d:	01 d0                	add    %edx,%eax
8010342f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(dip->type == T_FILE)  // a file inode
80103432:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103435:	0f b7 00             	movzwl (%eax),%eax
80103438:	66 83 f8 02          	cmp    $0x2,%ax
8010343c:	75 35                	jne    80103473 <getPrevInode+0x80>
    {
      ip = iget(1,*prevInum);
8010343e:	8b 45 08             	mov    0x8(%ebp),%eax
80103441:	8b 00                	mov    (%eax),%eax
80103443:	89 44 24 04          	mov    %eax,0x4(%esp)
80103447:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010344e:	e8 19 f1 ff ff       	call   8010256c <iget>
80103453:	89 45 ec             	mov    %eax,-0x14(%ebp)
      brelse(bp);
80103456:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103459:	89 04 24             	mov    %eax,(%esp)
8010345c:	e8 b6 cd ff ff       	call   80100217 <brelse>
      //cprintf("prev: before --, prevInum = %d\n",*prevInum);
      (*prevInum)--;
80103461:	8b 45 08             	mov    0x8(%ebp),%eax
80103464:	8b 00                	mov    (%eax),%eax
80103466:	8d 50 ff             	lea    -0x1(%eax),%edx
80103469:	8b 45 08             	mov    0x8(%ebp),%eax
8010346c:	89 10                	mov    %edx,(%eax)
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
8010346e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103471:	eb 2f                	jmp    801034a2 <getPrevInode+0xaf>
    }
    brelse(bp);
80103473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103476:	89 04 24             	mov    %eax,(%esp)
80103479:	e8 99 cd ff ff       	call   80100217 <brelse>
{
  struct buf *bp;
  struct dinode *dip;
  struct inode* ip;
   
  for(; (*prevInum) > nextInum ; (*prevInum)--)
8010347e:	8b 45 08             	mov    0x8(%ebp),%eax
80103481:	8b 00                	mov    (%eax),%eax
80103483:	8d 50 ff             	lea    -0x1(%eax),%edx
80103486:	8b 45 08             	mov    0x8(%ebp),%eax
80103489:	89 10                	mov    %edx,(%eax)
8010348b:	8b 45 08             	mov    0x8(%ebp),%eax
8010348e:	8b 10                	mov    (%eax),%edx
80103490:	a1 18 c6 10 80       	mov    0x8010c618,%eax
80103495:	39 c2                	cmp    %eax,%edx
80103497:	0f 8f 61 ff ff ff    	jg     801033fe <getPrevInode+0xb>
      //cprintf("prev: after --, prevInum = %d\n",*prevInum);
      return ip;
    }
    brelse(bp);
  }
  return 0;
8010349d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034a2:	c9                   	leave  
801034a3:	c3                   	ret    

801034a4 <updateBlkRef>:


void
updateBlkRef(uint sector, int flag)
{
801034a4:	55                   	push   %ebp
801034a5:	89 e5                	mov    %esp,%ebp
801034a7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  if(sector < 512)
801034aa:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801034b1:	0f 87 89 00 00 00    	ja     80103540 <updateBlkRef+0x9c>
  {
    bp = bread(1,1024);
801034b7:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801034be:	00 
801034bf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801034c6:	e8 db cc ff ff       	call   801001a6 <bread>
801034cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
801034ce:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
801034d2:	75 1e                	jne    801034f2 <updateBlkRef+0x4e>
      bp->data[sector]++;
801034d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d7:	03 45 08             	add    0x8(%ebp),%eax
801034da:	83 c0 10             	add    $0x10,%eax
801034dd:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801034e1:	8d 50 01             	lea    0x1(%eax),%edx
801034e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034e7:	03 45 08             	add    0x8(%ebp),%eax
801034ea:	83 c0 10             	add    $0x10,%eax
801034ed:	88 50 08             	mov    %dl,0x8(%eax)
801034f0:	eb 33                	jmp    80103525 <updateBlkRef+0x81>
    else if(flag == -1)
801034f2:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
801034f6:	75 2d                	jne    80103525 <updateBlkRef+0x81>
      if(bp->data[sector] > 0)
801034f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034fb:	03 45 08             	add    0x8(%ebp),%eax
801034fe:	83 c0 10             	add    $0x10,%eax
80103501:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103505:	84 c0                	test   %al,%al
80103507:	74 1c                	je     80103525 <updateBlkRef+0x81>
	bp->data[sector]--;
80103509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010350c:	03 45 08             	add    0x8(%ebp),%eax
8010350f:	83 c0 10             	add    $0x10,%eax
80103512:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80103516:	8d 50 ff             	lea    -0x1(%eax),%edx
80103519:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010351c:	03 45 08             	add    0x8(%ebp),%eax
8010351f:	83 c0 10             	add    $0x10,%eax
80103522:	88 50 08             	mov    %dl,0x8(%eax)
    bwrite(bp);
80103525:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103528:	89 04 24             	mov    %eax,(%esp)
8010352b:	e8 ad cc ff ff       	call   801001dd <bwrite>
    brelse(bp);
80103530:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103533:	89 04 24             	mov    %eax,(%esp)
80103536:	e8 dc cc ff ff       	call   80100217 <brelse>
8010353b:	e9 91 00 00 00       	jmp    801035d1 <updateBlkRef+0x12d>
  }
  else if(sector < 1024)
80103540:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103547:	0f 87 84 00 00 00    	ja     801035d1 <updateBlkRef+0x12d>
  {
    bp = bread(1,1025);
8010354d:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80103554:	00 
80103555:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010355c:	e8 45 cc ff ff       	call   801001a6 <bread>
80103561:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(flag == 1)
80103564:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
80103568:	75 1c                	jne    80103586 <updateBlkRef+0xe2>
      bp->data[sector-512]++;
8010356a:	8b 45 08             	mov    0x8(%ebp),%eax
8010356d:	2d 00 02 00 00       	sub    $0x200,%eax
80103572:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103575:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010357a:	8d 4a 01             	lea    0x1(%edx),%ecx
8010357d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103580:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
80103584:	eb 35                	jmp    801035bb <updateBlkRef+0x117>
    else if(flag == -1)
80103586:	83 7d 0c ff          	cmpl   $0xffffffff,0xc(%ebp)
8010358a:	75 2f                	jne    801035bb <updateBlkRef+0x117>
      if(bp->data[sector-512] > 0)
8010358c:	8b 45 08             	mov    0x8(%ebp),%eax
8010358f:	8d 90 00 fe ff ff    	lea    -0x200(%eax),%edx
80103595:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103598:	0f b6 44 10 18       	movzbl 0x18(%eax,%edx,1),%eax
8010359d:	84 c0                	test   %al,%al
8010359f:	74 1a                	je     801035bb <updateBlkRef+0x117>
	bp->data[sector-512]--;
801035a1:	8b 45 08             	mov    0x8(%ebp),%eax
801035a4:	2d 00 02 00 00       	sub    $0x200,%eax
801035a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035ac:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801035b1:	8d 4a ff             	lea    -0x1(%edx),%ecx
801035b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035b7:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
    bwrite(bp);
801035bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035be:	89 04 24             	mov    %eax,(%esp)
801035c1:	e8 17 cc ff ff       	call   801001dd <bwrite>
    brelse(bp);
801035c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035c9:	89 04 24             	mov    %eax,(%esp)
801035cc:	e8 46 cc ff ff       	call   80100217 <brelse>
  }  
}
801035d1:	c9                   	leave  
801035d2:	c3                   	ret    

801035d3 <getBlkRef>:

int
getBlkRef(uint sector)
{
801035d3:	55                   	push   %ebp
801035d4:	89 e5                	mov    %esp,%ebp
801035d6:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  int ret = -1;
801035d9:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  
  if(sector < 512)
801035e0:	81 7d 08 ff 01 00 00 	cmpl   $0x1ff,0x8(%ebp)
801035e7:	77 19                	ja     80103602 <getBlkRef+0x2f>
    bp = bread(1,1024);
801035e9:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801035f0:	00 
801035f1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801035f8:	e8 a9 cb ff ff       	call   801001a6 <bread>
801035fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103600:	eb 20                	jmp    80103622 <getBlkRef+0x4f>
  else if(sector < 1024)
80103602:	81 7d 08 ff 03 00 00 	cmpl   $0x3ff,0x8(%ebp)
80103609:	77 17                	ja     80103622 <getBlkRef+0x4f>
    bp = bread(1,1025);
8010360b:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
80103612:	00 
80103613:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010361a:	e8 87 cb ff ff       	call   801001a6 <bread>
8010361f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ret = bp->data[sector];
80103622:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103625:	03 45 08             	add    0x8(%ebp),%eax
80103628:	83 c0 10             	add    $0x10,%eax
8010362b:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010362f:	0f b6 c0             	movzbl %al,%eax
80103632:	89 45 f0             	mov    %eax,-0x10(%ebp)
  brelse(bp);
80103635:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103638:	89 04 24             	mov    %eax,(%esp)
8010363b:	e8 d7 cb ff ff       	call   80100217 <brelse>
  return ret;
80103640:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103643:	c9                   	leave  
80103644:	c3                   	ret    

80103645 <zeroNextInum>:

void
zeroNextInum(void)
{
80103645:	55                   	push   %ebp
80103646:	89 e5                	mov    %esp,%ebp
  nextInum = 0;
80103648:	c7 05 18 c6 10 80 00 	movl   $0x0,0x8010c618
8010364f:	00 00 00 
}
80103652:	5d                   	pop    %ebp
80103653:	c3                   	ret    

80103654 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103654:	55                   	push   %ebp
80103655:	89 e5                	mov    %esp,%ebp
80103657:	53                   	push   %ebx
80103658:	83 ec 14             	sub    $0x14,%esp
8010365b:	8b 45 08             	mov    0x8(%ebp),%eax
8010365e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103662:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103666:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010366a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010366e:	ec                   	in     (%dx),%al
8010366f:	89 c3                	mov    %eax,%ebx
80103671:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103674:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103678:	83 c4 14             	add    $0x14,%esp
8010367b:	5b                   	pop    %ebx
8010367c:	5d                   	pop    %ebp
8010367d:	c3                   	ret    

8010367e <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010367e:	55                   	push   %ebp
8010367f:	89 e5                	mov    %esp,%ebp
80103681:	57                   	push   %edi
80103682:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80103683:	8b 55 08             	mov    0x8(%ebp),%edx
80103686:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103689:	8b 45 10             	mov    0x10(%ebp),%eax
8010368c:	89 cb                	mov    %ecx,%ebx
8010368e:	89 df                	mov    %ebx,%edi
80103690:	89 c1                	mov    %eax,%ecx
80103692:	fc                   	cld    
80103693:	f3 6d                	rep insl (%dx),%es:(%edi)
80103695:	89 c8                	mov    %ecx,%eax
80103697:	89 fb                	mov    %edi,%ebx
80103699:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010369c:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010369f:	5b                   	pop    %ebx
801036a0:	5f                   	pop    %edi
801036a1:	5d                   	pop    %ebp
801036a2:	c3                   	ret    

801036a3 <outb>:

static inline void
outb(ushort port, uchar data)
{
801036a3:	55                   	push   %ebp
801036a4:	89 e5                	mov    %esp,%ebp
801036a6:	83 ec 08             	sub    $0x8,%esp
801036a9:	8b 55 08             	mov    0x8(%ebp),%edx
801036ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801036af:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801036b3:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801036b6:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801036ba:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801036be:	ee                   	out    %al,(%dx)
}
801036bf:	c9                   	leave  
801036c0:	c3                   	ret    

801036c1 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801036c1:	55                   	push   %ebp
801036c2:	89 e5                	mov    %esp,%ebp
801036c4:	56                   	push   %esi
801036c5:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801036c6:	8b 55 08             	mov    0x8(%ebp),%edx
801036c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801036cc:	8b 45 10             	mov    0x10(%ebp),%eax
801036cf:	89 cb                	mov    %ecx,%ebx
801036d1:	89 de                	mov    %ebx,%esi
801036d3:	89 c1                	mov    %eax,%ecx
801036d5:	fc                   	cld    
801036d6:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801036d8:	89 c8                	mov    %ecx,%eax
801036da:	89 f3                	mov    %esi,%ebx
801036dc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801036df:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801036e2:	5b                   	pop    %ebx
801036e3:	5e                   	pop    %esi
801036e4:	5d                   	pop    %ebp
801036e5:	c3                   	ret    

801036e6 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801036e6:	55                   	push   %ebp
801036e7:	89 e5                	mov    %esp,%ebp
801036e9:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801036ec:	90                   	nop
801036ed:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801036f4:	e8 5b ff ff ff       	call   80103654 <inb>
801036f9:	0f b6 c0             	movzbl %al,%eax
801036fc:	89 45 fc             	mov    %eax,-0x4(%ebp)
801036ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103702:	25 c0 00 00 00       	and    $0xc0,%eax
80103707:	83 f8 40             	cmp    $0x40,%eax
8010370a:	75 e1                	jne    801036ed <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
8010370c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80103710:	74 11                	je     80103723 <idewait+0x3d>
80103712:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103715:	83 e0 21             	and    $0x21,%eax
80103718:	85 c0                	test   %eax,%eax
8010371a:	74 07                	je     80103723 <idewait+0x3d>
    return -1;
8010371c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103721:	eb 05                	jmp    80103728 <idewait+0x42>
  return 0;
80103723:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103728:	c9                   	leave  
80103729:	c3                   	ret    

8010372a <ideinit>:

void
ideinit(void)
{
8010372a:	55                   	push   %ebp
8010372b:	89 e5                	mov    %esp,%ebp
8010372d:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80103730:	c7 44 24 04 41 97 10 	movl   $0x80109741,0x4(%esp)
80103737:	80 
80103738:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010373f:	e8 42 26 00 00       	call   80105d86 <initlock>
  picenable(IRQ_IDE);
80103744:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010374b:	e8 75 15 00 00       	call   80104cc5 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80103750:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80103755:	83 e8 01             	sub    $0x1,%eax
80103758:	89 44 24 04          	mov    %eax,0x4(%esp)
8010375c:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80103763:	e8 12 04 00 00       	call   80103b7a <ioapicenable>
  idewait(0);
80103768:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010376f:	e8 72 ff ff ff       	call   801036e6 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80103774:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010377b:	00 
8010377c:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80103783:	e8 1b ff ff ff       	call   801036a3 <outb>
  for(i=0; i<1000; i++){
80103788:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010378f:	eb 20                	jmp    801037b1 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80103791:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80103798:	e8 b7 fe ff ff       	call   80103654 <inb>
8010379d:	84 c0                	test   %al,%al
8010379f:	74 0c                	je     801037ad <ideinit+0x83>
      havedisk1 = 1;
801037a1:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
801037a8:	00 00 00 
      break;
801037ab:	eb 0d                	jmp    801037ba <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801037ad:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037b1:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801037b8:	7e d7                	jle    80103791 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801037ba:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801037c1:	00 
801037c2:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801037c9:	e8 d5 fe ff ff       	call   801036a3 <outb>
}
801037ce:	c9                   	leave  
801037cf:	c3                   	ret    

801037d0 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801037d0:	55                   	push   %ebp
801037d1:	89 e5                	mov    %esp,%ebp
801037d3:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801037d6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801037da:	75 0c                	jne    801037e8 <idestart+0x18>
    panic("idestart");
801037dc:	c7 04 24 45 97 10 80 	movl   $0x80109745,(%esp)
801037e3:	e8 55 cd ff ff       	call   8010053d <panic>

  idewait(0);
801037e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801037ef:	e8 f2 fe ff ff       	call   801036e6 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801037f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801037fb:	00 
801037fc:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80103803:	e8 9b fe ff ff       	call   801036a3 <outb>
  outb(0x1f2, 1);  // number of sectors
80103808:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010380f:	00 
80103810:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80103817:	e8 87 fe ff ff       	call   801036a3 <outb>
  outb(0x1f3, b->sector & 0xff);
8010381c:	8b 45 08             	mov    0x8(%ebp),%eax
8010381f:	8b 40 08             	mov    0x8(%eax),%eax
80103822:	0f b6 c0             	movzbl %al,%eax
80103825:	89 44 24 04          	mov    %eax,0x4(%esp)
80103829:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80103830:	e8 6e fe ff ff       	call   801036a3 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80103835:	8b 45 08             	mov    0x8(%ebp),%eax
80103838:	8b 40 08             	mov    0x8(%eax),%eax
8010383b:	c1 e8 08             	shr    $0x8,%eax
8010383e:	0f b6 c0             	movzbl %al,%eax
80103841:	89 44 24 04          	mov    %eax,0x4(%esp)
80103845:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
8010384c:	e8 52 fe ff ff       	call   801036a3 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80103851:	8b 45 08             	mov    0x8(%ebp),%eax
80103854:	8b 40 08             	mov    0x8(%eax),%eax
80103857:	c1 e8 10             	shr    $0x10,%eax
8010385a:	0f b6 c0             	movzbl %al,%eax
8010385d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103861:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80103868:	e8 36 fe ff ff       	call   801036a3 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
8010386d:	8b 45 08             	mov    0x8(%ebp),%eax
80103870:	8b 40 04             	mov    0x4(%eax),%eax
80103873:	83 e0 01             	and    $0x1,%eax
80103876:	89 c2                	mov    %eax,%edx
80103878:	c1 e2 04             	shl    $0x4,%edx
8010387b:	8b 45 08             	mov    0x8(%ebp),%eax
8010387e:	8b 40 08             	mov    0x8(%eax),%eax
80103881:	c1 e8 18             	shr    $0x18,%eax
80103884:	83 e0 0f             	and    $0xf,%eax
80103887:	09 d0                	or     %edx,%eax
80103889:	83 c8 e0             	or     $0xffffffe0,%eax
8010388c:	0f b6 c0             	movzbl %al,%eax
8010388f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103893:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010389a:	e8 04 fe ff ff       	call   801036a3 <outb>
  if(b->flags & B_DIRTY){
8010389f:	8b 45 08             	mov    0x8(%ebp),%eax
801038a2:	8b 00                	mov    (%eax),%eax
801038a4:	83 e0 04             	and    $0x4,%eax
801038a7:	85 c0                	test   %eax,%eax
801038a9:	74 34                	je     801038df <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801038ab:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801038b2:	00 
801038b3:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801038ba:	e8 e4 fd ff ff       	call   801036a3 <outb>
    outsl(0x1f0, b->data, 512/4);
801038bf:	8b 45 08             	mov    0x8(%ebp),%eax
801038c2:	83 c0 18             	add    $0x18,%eax
801038c5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801038cc:	00 
801038cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801038d1:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801038d8:	e8 e4 fd ff ff       	call   801036c1 <outsl>
801038dd:	eb 14                	jmp    801038f3 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801038df:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801038e6:	00 
801038e7:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801038ee:	e8 b0 fd ff ff       	call   801036a3 <outb>
  }
}
801038f3:	c9                   	leave  
801038f4:	c3                   	ret    

801038f5 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801038f5:	55                   	push   %ebp
801038f6:	89 e5                	mov    %esp,%ebp
801038f8:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801038fb:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103902:	e8 a0 24 00 00       	call   80105da7 <acquire>
  if((b = idequeue) == 0){
80103907:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010390c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010390f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103913:	75 11                	jne    80103926 <ideintr+0x31>
    release(&idelock);
80103915:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010391c:	e8 e8 24 00 00       	call   80105e09 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80103921:	e9 90 00 00 00       	jmp    801039b6 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80103926:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103929:	8b 40 14             	mov    0x14(%eax),%eax
8010392c:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80103931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103934:	8b 00                	mov    (%eax),%eax
80103936:	83 e0 04             	and    $0x4,%eax
80103939:	85 c0                	test   %eax,%eax
8010393b:	75 2e                	jne    8010396b <ideintr+0x76>
8010393d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103944:	e8 9d fd ff ff       	call   801036e6 <idewait>
80103949:	85 c0                	test   %eax,%eax
8010394b:	78 1e                	js     8010396b <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
8010394d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103950:	83 c0 18             	add    $0x18,%eax
80103953:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010395a:	00 
8010395b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010395f:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80103966:	e8 13 fd ff ff       	call   8010367e <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010396b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010396e:	8b 00                	mov    (%eax),%eax
80103970:	89 c2                	mov    %eax,%edx
80103972:	83 ca 02             	or     $0x2,%edx
80103975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103978:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010397a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010397d:	8b 00                	mov    (%eax),%eax
8010397f:	89 c2                	mov    %eax,%edx
80103981:	83 e2 fb             	and    $0xfffffffb,%edx
80103984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103987:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80103989:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010398c:	89 04 24             	mov    %eax,(%esp)
8010398f:	e8 0e 22 00 00       	call   80105ba2 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80103994:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103999:	85 c0                	test   %eax,%eax
8010399b:	74 0d                	je     801039aa <ideintr+0xb5>
    idestart(idequeue);
8010399d:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801039a2:	89 04 24             	mov    %eax,(%esp)
801039a5:	e8 26 fe ff ff       	call   801037d0 <idestart>

  release(&idelock);
801039aa:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801039b1:	e8 53 24 00 00       	call   80105e09 <release>
}
801039b6:	c9                   	leave  
801039b7:	c3                   	ret    

801039b8 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801039b8:	55                   	push   %ebp
801039b9:	89 e5                	mov    %esp,%ebp
801039bb:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801039be:	8b 45 08             	mov    0x8(%ebp),%eax
801039c1:	8b 00                	mov    (%eax),%eax
801039c3:	83 e0 01             	and    $0x1,%eax
801039c6:	85 c0                	test   %eax,%eax
801039c8:	75 0c                	jne    801039d6 <iderw+0x1e>
    panic("iderw: buf not busy");
801039ca:	c7 04 24 4e 97 10 80 	movl   $0x8010974e,(%esp)
801039d1:	e8 67 cb ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801039d6:	8b 45 08             	mov    0x8(%ebp),%eax
801039d9:	8b 00                	mov    (%eax),%eax
801039db:	83 e0 06             	and    $0x6,%eax
801039de:	83 f8 02             	cmp    $0x2,%eax
801039e1:	75 0c                	jne    801039ef <iderw+0x37>
    panic("iderw: nothing to do");
801039e3:	c7 04 24 62 97 10 80 	movl   $0x80109762,(%esp)
801039ea:	e8 4e cb ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801039ef:	8b 45 08             	mov    0x8(%ebp),%eax
801039f2:	8b 40 04             	mov    0x4(%eax),%eax
801039f5:	85 c0                	test   %eax,%eax
801039f7:	74 15                	je     80103a0e <iderw+0x56>
801039f9:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801039fe:	85 c0                	test   %eax,%eax
80103a00:	75 0c                	jne    80103a0e <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80103a02:	c7 04 24 77 97 10 80 	movl   $0x80109777,(%esp)
80103a09:	e8 2f cb ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80103a0e:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a15:	e8 8d 23 00 00       	call   80105da7 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80103a1a:	8b 45 08             	mov    0x8(%ebp),%eax
80103a1d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80103a24:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
80103a2b:	eb 0b                	jmp    80103a38 <iderw+0x80>
80103a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a30:	8b 00                	mov    (%eax),%eax
80103a32:	83 c0 14             	add    $0x14,%eax
80103a35:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a3b:	8b 00                	mov    (%eax),%eax
80103a3d:	85 c0                	test   %eax,%eax
80103a3f:	75 ec                	jne    80103a2d <iderw+0x75>
    ;
  *pp = b;
80103a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a44:	8b 55 08             	mov    0x8(%ebp),%edx
80103a47:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80103a49:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80103a4e:	3b 45 08             	cmp    0x8(%ebp),%eax
80103a51:	75 22                	jne    80103a75 <iderw+0xbd>
    idestart(b);
80103a53:	8b 45 08             	mov    0x8(%ebp),%eax
80103a56:	89 04 24             	mov    %eax,(%esp)
80103a59:	e8 72 fd ff ff       	call   801037d0 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103a5e:	eb 15                	jmp    80103a75 <iderw+0xbd>
    sleep(b, &idelock);
80103a60:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80103a67:	80 
80103a68:	8b 45 08             	mov    0x8(%ebp),%eax
80103a6b:	89 04 24             	mov    %eax,(%esp)
80103a6e:	e8 56 20 00 00       	call   80105ac9 <sleep>
80103a73:	eb 01                	jmp    80103a76 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80103a75:	90                   	nop
80103a76:	8b 45 08             	mov    0x8(%ebp),%eax
80103a79:	8b 00                	mov    (%eax),%eax
80103a7b:	83 e0 06             	and    $0x6,%eax
80103a7e:	83 f8 02             	cmp    $0x2,%eax
80103a81:	75 dd                	jne    80103a60 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80103a83:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80103a8a:	e8 7a 23 00 00       	call   80105e09 <release>
}
80103a8f:	c9                   	leave  
80103a90:	c3                   	ret    
80103a91:	00 00                	add    %al,(%eax)
	...

80103a94 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80103a94:	55                   	push   %ebp
80103a95:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103a97:	a1 74 08 11 80       	mov    0x80110874,%eax
80103a9c:	8b 55 08             	mov    0x8(%ebp),%edx
80103a9f:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80103aa1:	a1 74 08 11 80       	mov    0x80110874,%eax
80103aa6:	8b 40 10             	mov    0x10(%eax),%eax
}
80103aa9:	5d                   	pop    %ebp
80103aaa:	c3                   	ret    

80103aab <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80103aab:	55                   	push   %ebp
80103aac:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80103aae:	a1 74 08 11 80       	mov    0x80110874,%eax
80103ab3:	8b 55 08             	mov    0x8(%ebp),%edx
80103ab6:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80103ab8:	a1 74 08 11 80       	mov    0x80110874,%eax
80103abd:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ac0:	89 50 10             	mov    %edx,0x10(%eax)
}
80103ac3:	5d                   	pop    %ebp
80103ac4:	c3                   	ret    

80103ac5 <ioapicinit>:

void
ioapicinit(void)
{
80103ac5:	55                   	push   %ebp
80103ac6:	89 e5                	mov    %esp,%ebp
80103ac8:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80103acb:	a1 44 09 11 80       	mov    0x80110944,%eax
80103ad0:	85 c0                	test   %eax,%eax
80103ad2:	0f 84 9f 00 00 00    	je     80103b77 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80103ad8:	c7 05 74 08 11 80 00 	movl   $0xfec00000,0x80110874
80103adf:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80103ae2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103ae9:	e8 a6 ff ff ff       	call   80103a94 <ioapicread>
80103aee:	c1 e8 10             	shr    $0x10,%eax
80103af1:	25 ff 00 00 00       	and    $0xff,%eax
80103af6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80103af9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103b00:	e8 8f ff ff ff       	call   80103a94 <ioapicread>
80103b05:	c1 e8 18             	shr    $0x18,%eax
80103b08:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80103b0b:	0f b6 05 40 09 11 80 	movzbl 0x80110940,%eax
80103b12:	0f b6 c0             	movzbl %al,%eax
80103b15:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103b18:	74 0c                	je     80103b26 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80103b1a:	c7 04 24 98 97 10 80 	movl   $0x80109798,(%esp)
80103b21:	e8 7b c8 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103b26:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103b2d:	eb 3e                	jmp    80103b6d <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80103b2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b32:	83 c0 20             	add    $0x20,%eax
80103b35:	0d 00 00 01 00       	or     $0x10000,%eax
80103b3a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103b3d:	83 c2 08             	add    $0x8,%edx
80103b40:	01 d2                	add    %edx,%edx
80103b42:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b46:	89 14 24             	mov    %edx,(%esp)
80103b49:	e8 5d ff ff ff       	call   80103aab <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80103b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b51:	83 c0 08             	add    $0x8,%eax
80103b54:	01 c0                	add    %eax,%eax
80103b56:	83 c0 01             	add    $0x1,%eax
80103b59:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103b60:	00 
80103b61:	89 04 24             	mov    %eax,(%esp)
80103b64:	e8 42 ff ff ff       	call   80103aab <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80103b69:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103b6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b70:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80103b73:	7e ba                	jle    80103b2f <ioapicinit+0x6a>
80103b75:	eb 01                	jmp    80103b78 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80103b77:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80103b78:	c9                   	leave  
80103b79:	c3                   	ret    

80103b7a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80103b7a:	55                   	push   %ebp
80103b7b:	89 e5                	mov    %esp,%ebp
80103b7d:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80103b80:	a1 44 09 11 80       	mov    0x80110944,%eax
80103b85:	85 c0                	test   %eax,%eax
80103b87:	74 39                	je     80103bc2 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80103b89:	8b 45 08             	mov    0x8(%ebp),%eax
80103b8c:	83 c0 20             	add    $0x20,%eax
80103b8f:	8b 55 08             	mov    0x8(%ebp),%edx
80103b92:	83 c2 08             	add    $0x8,%edx
80103b95:	01 d2                	add    %edx,%edx
80103b97:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b9b:	89 14 24             	mov    %edx,(%esp)
80103b9e:	e8 08 ff ff ff       	call   80103aab <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103ba3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ba6:	c1 e0 18             	shl    $0x18,%eax
80103ba9:	8b 55 08             	mov    0x8(%ebp),%edx
80103bac:	83 c2 08             	add    $0x8,%edx
80103baf:	01 d2                	add    %edx,%edx
80103bb1:	83 c2 01             	add    $0x1,%edx
80103bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
80103bb8:	89 14 24             	mov    %edx,(%esp)
80103bbb:	e8 eb fe ff ff       	call   80103aab <ioapicwrite>
80103bc0:	eb 01                	jmp    80103bc3 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103bc2:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103bc3:	c9                   	leave  
80103bc4:	c3                   	ret    
80103bc5:	00 00                	add    %al,(%eax)
	...

80103bc8 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80103bc8:	55                   	push   %ebp
80103bc9:	89 e5                	mov    %esp,%ebp
80103bcb:	8b 45 08             	mov    0x8(%ebp),%eax
80103bce:	05 00 00 00 80       	add    $0x80000000,%eax
80103bd3:	5d                   	pop    %ebp
80103bd4:	c3                   	ret    

80103bd5 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103bd5:	55                   	push   %ebp
80103bd6:	89 e5                	mov    %esp,%ebp
80103bd8:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80103bdb:	c7 44 24 04 ca 97 10 	movl   $0x801097ca,0x4(%esp)
80103be2:	80 
80103be3:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103bea:	e8 97 21 00 00       	call   80105d86 <initlock>
  kmem.use_lock = 0;
80103bef:	c7 05 b4 08 11 80 00 	movl   $0x0,0x801108b4
80103bf6:	00 00 00 
  freerange(vstart, vend);
80103bf9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bfc:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c00:	8b 45 08             	mov    0x8(%ebp),%eax
80103c03:	89 04 24             	mov    %eax,(%esp)
80103c06:	e8 26 00 00 00       	call   80103c31 <freerange>
}
80103c0b:	c9                   	leave  
80103c0c:	c3                   	ret    

80103c0d <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103c0d:	55                   	push   %ebp
80103c0e:	89 e5                	mov    %esp,%ebp
80103c10:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103c13:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c16:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c1a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c1d:	89 04 24             	mov    %eax,(%esp)
80103c20:	e8 0c 00 00 00       	call   80103c31 <freerange>
  kmem.use_lock = 1;
80103c25:	c7 05 b4 08 11 80 01 	movl   $0x1,0x801108b4
80103c2c:	00 00 00 
}
80103c2f:	c9                   	leave  
80103c30:	c3                   	ret    

80103c31 <freerange>:

void
freerange(void *vstart, void *vend)
{
80103c31:	55                   	push   %ebp
80103c32:	89 e5                	mov    %esp,%ebp
80103c34:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80103c37:	8b 45 08             	mov    0x8(%ebp),%eax
80103c3a:	05 ff 0f 00 00       	add    $0xfff,%eax
80103c3f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80103c44:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103c47:	eb 12                	jmp    80103c5b <freerange+0x2a>
    kfree(p);
80103c49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c4c:	89 04 24             	mov    %eax,(%esp)
80103c4f:	e8 16 00 00 00       	call   80103c6a <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80103c54:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80103c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c5e:	05 00 10 00 00       	add    $0x1000,%eax
80103c63:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103c66:	76 e1                	jbe    80103c49 <freerange+0x18>
    kfree(p);
}
80103c68:	c9                   	leave  
80103c69:	c3                   	ret    

80103c6a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80103c6a:	55                   	push   %ebp
80103c6b:	89 e5                	mov    %esp,%ebp
80103c6d:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80103c70:	8b 45 08             	mov    0x8(%ebp),%eax
80103c73:	25 ff 0f 00 00       	and    $0xfff,%eax
80103c78:	85 c0                	test   %eax,%eax
80103c7a:	75 1b                	jne    80103c97 <kfree+0x2d>
80103c7c:	81 7d 08 3c 37 11 80 	cmpl   $0x8011373c,0x8(%ebp)
80103c83:	72 12                	jb     80103c97 <kfree+0x2d>
80103c85:	8b 45 08             	mov    0x8(%ebp),%eax
80103c88:	89 04 24             	mov    %eax,(%esp)
80103c8b:	e8 38 ff ff ff       	call   80103bc8 <v2p>
80103c90:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103c95:	76 0c                	jbe    80103ca3 <kfree+0x39>
    panic("kfree");
80103c97:	c7 04 24 cf 97 10 80 	movl   $0x801097cf,(%esp)
80103c9e:	e8 9a c8 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103ca3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80103caa:	00 
80103cab:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103cb2:	00 
80103cb3:	8b 45 08             	mov    0x8(%ebp),%eax
80103cb6:	89 04 24             	mov    %eax,(%esp)
80103cb9:	e8 38 23 00 00       	call   80105ff6 <memset>

  if(kmem.use_lock)
80103cbe:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103cc3:	85 c0                	test   %eax,%eax
80103cc5:	74 0c                	je     80103cd3 <kfree+0x69>
    acquire(&kmem.lock);
80103cc7:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103cce:	e8 d4 20 00 00       	call   80105da7 <acquire>
  r = (struct run*)v;
80103cd3:	8b 45 08             	mov    0x8(%ebp),%eax
80103cd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80103cd9:	8b 15 b8 08 11 80    	mov    0x801108b8,%edx
80103cdf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce2:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103ce4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ce7:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103cec:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103cf1:	85 c0                	test   %eax,%eax
80103cf3:	74 0c                	je     80103d01 <kfree+0x97>
    release(&kmem.lock);
80103cf5:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103cfc:	e8 08 21 00 00       	call   80105e09 <release>
}
80103d01:	c9                   	leave  
80103d02:	c3                   	ret    

80103d03 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103d03:	55                   	push   %ebp
80103d04:	89 e5                	mov    %esp,%ebp
80103d06:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80103d09:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d0e:	85 c0                	test   %eax,%eax
80103d10:	74 0c                	je     80103d1e <kalloc+0x1b>
    acquire(&kmem.lock);
80103d12:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103d19:	e8 89 20 00 00       	call   80105da7 <acquire>
  r = kmem.freelist;
80103d1e:	a1 b8 08 11 80       	mov    0x801108b8,%eax
80103d23:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80103d26:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d2a:	74 0a                	je     80103d36 <kalloc+0x33>
    kmem.freelist = r->next;
80103d2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d2f:	8b 00                	mov    (%eax),%eax
80103d31:	a3 b8 08 11 80       	mov    %eax,0x801108b8
  if(kmem.use_lock)
80103d36:	a1 b4 08 11 80       	mov    0x801108b4,%eax
80103d3b:	85 c0                	test   %eax,%eax
80103d3d:	74 0c                	je     80103d4b <kalloc+0x48>
    release(&kmem.lock);
80103d3f:	c7 04 24 80 08 11 80 	movl   $0x80110880,(%esp)
80103d46:	e8 be 20 00 00       	call   80105e09 <release>
  return (char*)r;
80103d4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80103d4e:	c9                   	leave  
80103d4f:	c3                   	ret    

80103d50 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103d50:	55                   	push   %ebp
80103d51:	89 e5                	mov    %esp,%ebp
80103d53:	53                   	push   %ebx
80103d54:	83 ec 14             	sub    $0x14,%esp
80103d57:	8b 45 08             	mov    0x8(%ebp),%eax
80103d5a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103d5e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103d62:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103d66:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103d6a:	ec                   	in     (%dx),%al
80103d6b:	89 c3                	mov    %eax,%ebx
80103d6d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103d70:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103d74:	83 c4 14             	add    $0x14,%esp
80103d77:	5b                   	pop    %ebx
80103d78:	5d                   	pop    %ebp
80103d79:	c3                   	ret    

80103d7a <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80103d7a:	55                   	push   %ebp
80103d7b:	89 e5                	mov    %esp,%ebp
80103d7d:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80103d80:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103d87:	e8 c4 ff ff ff       	call   80103d50 <inb>
80103d8c:	0f b6 c0             	movzbl %al,%eax
80103d8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103d92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d95:	83 e0 01             	and    $0x1,%eax
80103d98:	85 c0                	test   %eax,%eax
80103d9a:	75 0a                	jne    80103da6 <kbdgetc+0x2c>
    return -1;
80103d9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103da1:	e9 23 01 00 00       	jmp    80103ec9 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80103da6:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103dad:	e8 9e ff ff ff       	call   80103d50 <inb>
80103db2:	0f b6 c0             	movzbl %al,%eax
80103db5:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80103db8:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103dbf:	75 17                	jne    80103dd8 <kbdgetc+0x5e>
    shift |= E0ESC;
80103dc1:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103dc6:	83 c8 40             	or     $0x40,%eax
80103dc9:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103dce:	b8 00 00 00 00       	mov    $0x0,%eax
80103dd3:	e9 f1 00 00 00       	jmp    80103ec9 <kbdgetc+0x14f>
  } else if(data & 0x80){
80103dd8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103ddb:	25 80 00 00 00       	and    $0x80,%eax
80103de0:	85 c0                	test   %eax,%eax
80103de2:	74 45                	je     80103e29 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103de4:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103de9:	83 e0 40             	and    $0x40,%eax
80103dec:	85 c0                	test   %eax,%eax
80103dee:	75 08                	jne    80103df8 <kbdgetc+0x7e>
80103df0:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103df3:	83 e0 7f             	and    $0x7f,%eax
80103df6:	eb 03                	jmp    80103dfb <kbdgetc+0x81>
80103df8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103dfb:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103dfe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e01:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103e06:	0f b6 00             	movzbl (%eax),%eax
80103e09:	83 c8 40             	or     $0x40,%eax
80103e0c:	0f b6 c0             	movzbl %al,%eax
80103e0f:	f7 d0                	not    %eax
80103e11:	89 c2                	mov    %eax,%edx
80103e13:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e18:	21 d0                	and    %edx,%eax
80103e1a:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80103e1f:	b8 00 00 00 00       	mov    $0x0,%eax
80103e24:	e9 a0 00 00 00       	jmp    80103ec9 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80103e29:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e2e:	83 e0 40             	and    $0x40,%eax
80103e31:	85 c0                	test   %eax,%eax
80103e33:	74 14                	je     80103e49 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80103e35:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80103e3c:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e41:	83 e0 bf             	and    $0xffffffbf,%eax
80103e44:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80103e49:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e4c:	05 20 a0 10 80       	add    $0x8010a020,%eax
80103e51:	0f b6 00             	movzbl (%eax),%eax
80103e54:	0f b6 d0             	movzbl %al,%edx
80103e57:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e5c:	09 d0                	or     %edx,%eax
80103e5e:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80103e63:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103e66:	05 20 a1 10 80       	add    $0x8010a120,%eax
80103e6b:	0f b6 00             	movzbl (%eax),%eax
80103e6e:	0f b6 d0             	movzbl %al,%edx
80103e71:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e76:	31 d0                	xor    %edx,%eax
80103e78:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80103e7d:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e82:	83 e0 03             	and    $0x3,%eax
80103e85:	8b 04 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%eax
80103e8c:	03 45 fc             	add    -0x4(%ebp),%eax
80103e8f:	0f b6 00             	movzbl (%eax),%eax
80103e92:	0f b6 c0             	movzbl %al,%eax
80103e95:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80103e98:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80103e9d:	83 e0 08             	and    $0x8,%eax
80103ea0:	85 c0                	test   %eax,%eax
80103ea2:	74 22                	je     80103ec6 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103ea4:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80103ea8:	76 0c                	jbe    80103eb6 <kbdgetc+0x13c>
80103eaa:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103eae:	77 06                	ja     80103eb6 <kbdgetc+0x13c>
      c += 'A' - 'a';
80103eb0:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103eb4:	eb 10                	jmp    80103ec6 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80103eb6:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80103eba:	76 0a                	jbe    80103ec6 <kbdgetc+0x14c>
80103ebc:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103ec0:	77 04                	ja     80103ec6 <kbdgetc+0x14c>
      c += 'a' - 'A';
80103ec2:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80103ec6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103ec9:	c9                   	leave  
80103eca:	c3                   	ret    

80103ecb <kbdintr>:

void
kbdintr(void)
{
80103ecb:	55                   	push   %ebp
80103ecc:	89 e5                	mov    %esp,%ebp
80103ece:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103ed1:	c7 04 24 7a 3d 10 80 	movl   $0x80103d7a,(%esp)
80103ed8:	e8 d0 c8 ff ff       	call   801007ad <consoleintr>
}
80103edd:	c9                   	leave  
80103ede:	c3                   	ret    
	...

80103ee0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103ee0:	55                   	push   %ebp
80103ee1:	89 e5                	mov    %esp,%ebp
80103ee3:	83 ec 08             	sub    $0x8,%esp
80103ee6:	8b 55 08             	mov    0x8(%ebp),%edx
80103ee9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eec:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103ef0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103ef3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103ef7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103efb:	ee                   	out    %al,(%dx)
}
80103efc:	c9                   	leave  
80103efd:	c3                   	ret    

80103efe <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103efe:	55                   	push   %ebp
80103eff:	89 e5                	mov    %esp,%ebp
80103f01:	53                   	push   %ebx
80103f02:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103f05:	9c                   	pushf  
80103f06:	5b                   	pop    %ebx
80103f07:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80103f0a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103f0d:	83 c4 10             	add    $0x10,%esp
80103f10:	5b                   	pop    %ebx
80103f11:	5d                   	pop    %ebp
80103f12:	c3                   	ret    

80103f13 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103f13:	55                   	push   %ebp
80103f14:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80103f16:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f1b:	8b 55 08             	mov    0x8(%ebp),%edx
80103f1e:	c1 e2 02             	shl    $0x2,%edx
80103f21:	01 c2                	add    %eax,%edx
80103f23:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f26:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80103f28:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f2d:	83 c0 20             	add    $0x20,%eax
80103f30:	8b 00                	mov    (%eax),%eax
}
80103f32:	5d                   	pop    %ebp
80103f33:	c3                   	ret    

80103f34 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80103f34:	55                   	push   %ebp
80103f35:	89 e5                	mov    %esp,%ebp
80103f37:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80103f3a:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103f3f:	85 c0                	test   %eax,%eax
80103f41:	0f 84 47 01 00 00    	je     8010408e <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80103f47:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80103f4e:	00 
80103f4f:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80103f56:	e8 b8 ff ff ff       	call   80103f13 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80103f5b:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80103f62:	00 
80103f63:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80103f6a:	e8 a4 ff ff ff       	call   80103f13 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80103f6f:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80103f76:	00 
80103f77:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103f7e:	e8 90 ff ff ff       	call   80103f13 <lapicw>
  lapicw(TICR, 10000000); 
80103f83:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80103f8a:	00 
80103f8b:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103f92:	e8 7c ff ff ff       	call   80103f13 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80103f97:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103f9e:	00 
80103f9f:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80103fa6:	e8 68 ff ff ff       	call   80103f13 <lapicw>
  lapicw(LINT1, MASKED);
80103fab:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103fb2:	00 
80103fb3:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103fba:	e8 54 ff ff ff       	call   80103f13 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103fbf:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80103fc4:	83 c0 30             	add    $0x30,%eax
80103fc7:	8b 00                	mov    (%eax),%eax
80103fc9:	c1 e8 10             	shr    $0x10,%eax
80103fcc:	25 ff 00 00 00       	and    $0xff,%eax
80103fd1:	83 f8 03             	cmp    $0x3,%eax
80103fd4:	76 14                	jbe    80103fea <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80103fd6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103fdd:	00 
80103fde:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103fe5:	e8 29 ff ff ff       	call   80103f13 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103fea:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103ff1:	00 
80103ff2:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103ff9:	e8 15 ff ff ff       	call   80103f13 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103ffe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104005:	00 
80104006:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
8010400d:	e8 01 ff ff ff       	call   80103f13 <lapicw>
  lapicw(ESR, 0);
80104012:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104019:	00 
8010401a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104021:	e8 ed fe ff ff       	call   80103f13 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80104026:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010402d:	00 
8010402e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80104035:	e8 d9 fe ff ff       	call   80103f13 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
8010403a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104041:	00 
80104042:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80104049:	e8 c5 fe ff ff       	call   80103f13 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010404e:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80104055:	00 
80104056:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010405d:	e8 b1 fe ff ff       	call   80103f13 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80104062:	90                   	nop
80104063:	a1 bc 08 11 80       	mov    0x801108bc,%eax
80104068:	05 00 03 00 00       	add    $0x300,%eax
8010406d:	8b 00                	mov    (%eax),%eax
8010406f:	25 00 10 00 00       	and    $0x1000,%eax
80104074:	85 c0                	test   %eax,%eax
80104076:	75 eb                	jne    80104063 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80104078:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010407f:	00 
80104080:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104087:	e8 87 fe ff ff       	call   80103f13 <lapicw>
8010408c:	eb 01                	jmp    8010408f <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
8010408e:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
8010408f:	c9                   	leave  
80104090:	c3                   	ret    

80104091 <cpunum>:

int
cpunum(void)
{
80104091:	55                   	push   %ebp
80104092:	89 e5                	mov    %esp,%ebp
80104094:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80104097:	e8 62 fe ff ff       	call   80103efe <readeflags>
8010409c:	25 00 02 00 00       	and    $0x200,%eax
801040a1:	85 c0                	test   %eax,%eax
801040a3:	74 29                	je     801040ce <cpunum+0x3d>
    static int n;
    if(n++ == 0)
801040a5:	a1 60 c6 10 80       	mov    0x8010c660,%eax
801040aa:	85 c0                	test   %eax,%eax
801040ac:	0f 94 c2             	sete   %dl
801040af:	83 c0 01             	add    $0x1,%eax
801040b2:	a3 60 c6 10 80       	mov    %eax,0x8010c660
801040b7:	84 d2                	test   %dl,%dl
801040b9:	74 13                	je     801040ce <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
801040bb:	8b 45 04             	mov    0x4(%ebp),%eax
801040be:	89 44 24 04          	mov    %eax,0x4(%esp)
801040c2:	c7 04 24 d8 97 10 80 	movl   $0x801097d8,(%esp)
801040c9:	e8 d3 c2 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
801040ce:	a1 bc 08 11 80       	mov    0x801108bc,%eax
801040d3:	85 c0                	test   %eax,%eax
801040d5:	74 0f                	je     801040e6 <cpunum+0x55>
    return lapic[ID]>>24;
801040d7:	a1 bc 08 11 80       	mov    0x801108bc,%eax
801040dc:	83 c0 20             	add    $0x20,%eax
801040df:	8b 00                	mov    (%eax),%eax
801040e1:	c1 e8 18             	shr    $0x18,%eax
801040e4:	eb 05                	jmp    801040eb <cpunum+0x5a>
  return 0;
801040e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040eb:	c9                   	leave  
801040ec:	c3                   	ret    

801040ed <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801040ed:	55                   	push   %ebp
801040ee:	89 e5                	mov    %esp,%ebp
801040f0:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801040f3:	a1 bc 08 11 80       	mov    0x801108bc,%eax
801040f8:	85 c0                	test   %eax,%eax
801040fa:	74 14                	je     80104110 <lapiceoi+0x23>
    lapicw(EOI, 0);
801040fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104103:	00 
80104104:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010410b:	e8 03 fe ff ff       	call   80103f13 <lapicw>
}
80104110:	c9                   	leave  
80104111:	c3                   	ret    

80104112 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80104112:	55                   	push   %ebp
80104113:	89 e5                	mov    %esp,%ebp
}
80104115:	5d                   	pop    %ebp
80104116:	c3                   	ret    

80104117 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80104117:	55                   	push   %ebp
80104118:	89 e5                	mov    %esp,%ebp
8010411a:	83 ec 1c             	sub    $0x1c,%esp
8010411d:	8b 45 08             	mov    0x8(%ebp),%eax
80104120:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80104123:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010412a:	00 
8010412b:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80104132:	e8 a9 fd ff ff       	call   80103ee0 <outb>
  outb(IO_RTC+1, 0x0A);
80104137:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010413e:	00 
8010413f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80104146:	e8 95 fd ff ff       	call   80103ee0 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
8010414b:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80104152:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104155:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010415a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010415d:	8d 50 02             	lea    0x2(%eax),%edx
80104160:	8b 45 0c             	mov    0xc(%ebp),%eax
80104163:	c1 e8 04             	shr    $0x4,%eax
80104166:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80104169:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010416d:	c1 e0 18             	shl    $0x18,%eax
80104170:	89 44 24 04          	mov    %eax,0x4(%esp)
80104174:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010417b:	e8 93 fd ff ff       	call   80103f13 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80104180:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80104187:	00 
80104188:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010418f:	e8 7f fd ff ff       	call   80103f13 <lapicw>
  microdelay(200);
80104194:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010419b:	e8 72 ff ff ff       	call   80104112 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
801041a0:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
801041a7:	00 
801041a8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801041af:	e8 5f fd ff ff       	call   80103f13 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801041b4:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801041bb:	e8 52 ff ff ff       	call   80104112 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801041c0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801041c7:	eb 40                	jmp    80104209 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
801041c9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801041cd:	c1 e0 18             	shl    $0x18,%eax
801041d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801041d4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801041db:	e8 33 fd ff ff       	call   80103f13 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801041e0:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e3:	c1 e8 0c             	shr    $0xc,%eax
801041e6:	80 cc 06             	or     $0x6,%ah
801041e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801041ed:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801041f4:	e8 1a fd ff ff       	call   80103f13 <lapicw>
    microdelay(200);
801041f9:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80104200:	e8 0d ff ff ff       	call   80104112 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80104205:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104209:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010420d:	7e ba                	jle    801041c9 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010420f:	c9                   	leave  
80104210:	c3                   	ret    
80104211:	00 00                	add    %al,(%eax)
	...

80104214 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80104214:	55                   	push   %ebp
80104215:	89 e5                	mov    %esp,%ebp
80104217:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010421a:	c7 44 24 04 04 98 10 	movl   $0x80109804,0x4(%esp)
80104221:	80 
80104222:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104229:	e8 58 1b 00 00       	call   80105d86 <initlock>
  readsb(ROOTDEV, &sb);
8010422e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104231:	89 44 24 04          	mov    %eax,0x4(%esp)
80104235:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010423c:	e8 b3 de ff ff       	call   801020f4 <readsb>
  log.start = sb.size - sb.nlog;
80104241:	8b 55 e8             	mov    -0x18(%ebp),%edx
80104244:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104247:	89 d1                	mov    %edx,%ecx
80104249:	29 c1                	sub    %eax,%ecx
8010424b:	89 c8                	mov    %ecx,%eax
8010424d:	a3 f4 08 11 80       	mov    %eax,0x801108f4
  log.size = sb.nlog;
80104252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104255:	a3 f8 08 11 80       	mov    %eax,0x801108f8
  log.dev = ROOTDEV;
8010425a:	c7 05 00 09 11 80 01 	movl   $0x1,0x80110900
80104261:	00 00 00 
  recover_from_log();
80104264:	e8 97 01 00 00       	call   80104400 <recover_from_log>
}
80104269:	c9                   	leave  
8010426a:	c3                   	ret    

8010426b <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010426b:	55                   	push   %ebp
8010426c:	89 e5                	mov    %esp,%ebp
8010426e:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104271:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104278:	e9 89 00 00 00       	jmp    80104306 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010427d:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104282:	03 45 f4             	add    -0xc(%ebp),%eax
80104285:	83 c0 01             	add    $0x1,%eax
80104288:	89 c2                	mov    %eax,%edx
8010428a:	a1 00 09 11 80       	mov    0x80110900,%eax
8010428f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104293:	89 04 24             	mov    %eax,(%esp)
80104296:	e8 0b bf ff ff       	call   801001a6 <bread>
8010429b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
8010429e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a1:	83 c0 10             	add    $0x10,%eax
801042a4:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
801042ab:	89 c2                	mov    %eax,%edx
801042ad:	a1 00 09 11 80       	mov    0x80110900,%eax
801042b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801042b6:	89 04 24             	mov    %eax,(%esp)
801042b9:	e8 e8 be ff ff       	call   801001a6 <bread>
801042be:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801042c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042c4:	8d 50 18             	lea    0x18(%eax),%edx
801042c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042ca:	83 c0 18             	add    $0x18,%eax
801042cd:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801042d4:	00 
801042d5:	89 54 24 04          	mov    %edx,0x4(%esp)
801042d9:	89 04 24             	mov    %eax,(%esp)
801042dc:	e8 e8 1d 00 00       	call   801060c9 <memmove>
    bwrite(dbuf);  // write dst to disk
801042e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042e4:	89 04 24             	mov    %eax,(%esp)
801042e7:	e8 f1 be ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801042ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801042ef:	89 04 24             	mov    %eax,(%esp)
801042f2:	e8 20 bf ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801042f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801042fa:	89 04 24             	mov    %eax,(%esp)
801042fd:	e8 15 bf ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80104302:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104306:	a1 04 09 11 80       	mov    0x80110904,%eax
8010430b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010430e:	0f 8f 69 ff ff ff    	jg     8010427d <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80104314:	c9                   	leave  
80104315:	c3                   	ret    

80104316 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80104316:	55                   	push   %ebp
80104317:	89 e5                	mov    %esp,%ebp
80104319:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010431c:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104321:	89 c2                	mov    %eax,%edx
80104323:	a1 00 09 11 80       	mov    0x80110900,%eax
80104328:	89 54 24 04          	mov    %edx,0x4(%esp)
8010432c:	89 04 24             	mov    %eax,(%esp)
8010432f:	e8 72 be ff ff       	call   801001a6 <bread>
80104334:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80104337:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010433a:	83 c0 18             	add    $0x18,%eax
8010433d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80104340:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104343:	8b 00                	mov    (%eax),%eax
80104345:	a3 04 09 11 80       	mov    %eax,0x80110904
  for (i = 0; i < log.lh.n; i++) {
8010434a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104351:	eb 1b                	jmp    8010436e <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80104353:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104356:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104359:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010435d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104360:	83 c2 10             	add    $0x10,%edx
80104363:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010436a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010436e:	a1 04 09 11 80       	mov    0x80110904,%eax
80104373:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104376:	7f db                	jg     80104353 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
80104378:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010437b:	89 04 24             	mov    %eax,(%esp)
8010437e:	e8 94 be ff ff       	call   80100217 <brelse>
}
80104383:	c9                   	leave  
80104384:	c3                   	ret    

80104385 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80104385:	55                   	push   %ebp
80104386:	89 e5                	mov    %esp,%ebp
80104388:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010438b:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104390:	89 c2                	mov    %eax,%edx
80104392:	a1 00 09 11 80       	mov    0x80110900,%eax
80104397:	89 54 24 04          	mov    %edx,0x4(%esp)
8010439b:	89 04 24             	mov    %eax,(%esp)
8010439e:	e8 03 be ff ff       	call   801001a6 <bread>
801043a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801043a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043a9:	83 c0 18             	add    $0x18,%eax
801043ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801043af:	8b 15 04 09 11 80    	mov    0x80110904,%edx
801043b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043b8:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801043ba:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801043c1:	eb 1b                	jmp    801043de <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
801043c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c6:	83 c0 10             	add    $0x10,%eax
801043c9:	8b 0c 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%ecx
801043d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801043d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043d6:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801043da:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801043de:	a1 04 09 11 80       	mov    0x80110904,%eax
801043e3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801043e6:	7f db                	jg     801043c3 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801043e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043eb:	89 04 24             	mov    %eax,(%esp)
801043ee:	e8 ea bd ff ff       	call   801001dd <bwrite>
  brelse(buf);
801043f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801043f6:	89 04 24             	mov    %eax,(%esp)
801043f9:	e8 19 be ff ff       	call   80100217 <brelse>
}
801043fe:	c9                   	leave  
801043ff:	c3                   	ret    

80104400 <recover_from_log>:

static void
recover_from_log(void)
{
80104400:	55                   	push   %ebp
80104401:	89 e5                	mov    %esp,%ebp
80104403:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80104406:	e8 0b ff ff ff       	call   80104316 <read_head>
  install_trans(); // if committed, copy from log to disk
8010440b:	e8 5b fe ff ff       	call   8010426b <install_trans>
  log.lh.n = 0;
80104410:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
80104417:	00 00 00 
  write_head(); // clear the log
8010441a:	e8 66 ff ff ff       	call   80104385 <write_head>
}
8010441f:	c9                   	leave  
80104420:	c3                   	ret    

80104421 <begin_trans>:

void
begin_trans(void)
{
80104421:	55                   	push   %ebp
80104422:	89 e5                	mov    %esp,%ebp
80104424:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80104427:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
8010442e:	e8 74 19 00 00       	call   80105da7 <acquire>
  while (log.busy) {
80104433:	eb 14                	jmp    80104449 <begin_trans+0x28>
    sleep(&log, &log.lock);
80104435:	c7 44 24 04 c0 08 11 	movl   $0x801108c0,0x4(%esp)
8010443c:	80 
8010443d:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104444:	e8 80 16 00 00       	call   80105ac9 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80104449:	a1 fc 08 11 80       	mov    0x801108fc,%eax
8010444e:	85 c0                	test   %eax,%eax
80104450:	75 e3                	jne    80104435 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80104452:	c7 05 fc 08 11 80 01 	movl   $0x1,0x801108fc
80104459:	00 00 00 
  release(&log.lock);
8010445c:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104463:	e8 a1 19 00 00       	call   80105e09 <release>
}
80104468:	c9                   	leave  
80104469:	c3                   	ret    

8010446a <commit_trans>:

void
commit_trans(void)
{
8010446a:	55                   	push   %ebp
8010446b:	89 e5                	mov    %esp,%ebp
8010446d:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80104470:	a1 04 09 11 80       	mov    0x80110904,%eax
80104475:	85 c0                	test   %eax,%eax
80104477:	7e 19                	jle    80104492 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
80104479:	e8 07 ff ff ff       	call   80104385 <write_head>
    install_trans(); // Now install writes to home locations
8010447e:	e8 e8 fd ff ff       	call   8010426b <install_trans>
    log.lh.n = 0; 
80104483:	c7 05 04 09 11 80 00 	movl   $0x0,0x80110904
8010448a:	00 00 00 
    write_head();    // Erase the transaction from the log
8010448d:	e8 f3 fe ff ff       	call   80104385 <write_head>
  }
  
  acquire(&log.lock);
80104492:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
80104499:	e8 09 19 00 00       	call   80105da7 <acquire>
  log.busy = 0;
8010449e:	c7 05 fc 08 11 80 00 	movl   $0x0,0x801108fc
801044a5:	00 00 00 
  wakeup(&log);
801044a8:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801044af:	e8 ee 16 00 00       	call   80105ba2 <wakeup>
  release(&log.lock);
801044b4:	c7 04 24 c0 08 11 80 	movl   $0x801108c0,(%esp)
801044bb:	e8 49 19 00 00       	call   80105e09 <release>
}
801044c0:	c9                   	leave  
801044c1:	c3                   	ret    

801044c2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801044c2:	55                   	push   %ebp
801044c3:	89 e5                	mov    %esp,%ebp
801044c5:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801044c8:	a1 04 09 11 80       	mov    0x80110904,%eax
801044cd:	83 f8 09             	cmp    $0x9,%eax
801044d0:	7f 12                	jg     801044e4 <log_write+0x22>
801044d2:	a1 04 09 11 80       	mov    0x80110904,%eax
801044d7:	8b 15 f8 08 11 80    	mov    0x801108f8,%edx
801044dd:	83 ea 01             	sub    $0x1,%edx
801044e0:	39 d0                	cmp    %edx,%eax
801044e2:	7c 0c                	jl     801044f0 <log_write+0x2e>
    panic("too big a transaction");
801044e4:	c7 04 24 08 98 10 80 	movl   $0x80109808,(%esp)
801044eb:	e8 4d c0 ff ff       	call   8010053d <panic>
  if (!log.busy)
801044f0:	a1 fc 08 11 80       	mov    0x801108fc,%eax
801044f5:	85 c0                	test   %eax,%eax
801044f7:	75 0c                	jne    80104505 <log_write+0x43>
    panic("write outside of trans");
801044f9:	c7 04 24 1e 98 10 80 	movl   $0x8010981e,(%esp)
80104500:	e8 38 c0 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80104505:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010450c:	eb 1d                	jmp    8010452b <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010450e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104511:	83 c0 10             	add    $0x10,%eax
80104514:	8b 04 85 c8 08 11 80 	mov    -0x7feef738(,%eax,4),%eax
8010451b:	89 c2                	mov    %eax,%edx
8010451d:	8b 45 08             	mov    0x8(%ebp),%eax
80104520:	8b 40 08             	mov    0x8(%eax),%eax
80104523:	39 c2                	cmp    %eax,%edx
80104525:	74 10                	je     80104537 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80104527:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010452b:	a1 04 09 11 80       	mov    0x80110904,%eax
80104530:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104533:	7f d9                	jg     8010450e <log_write+0x4c>
80104535:	eb 01                	jmp    80104538 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80104537:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80104538:	8b 45 08             	mov    0x8(%ebp),%eax
8010453b:	8b 40 08             	mov    0x8(%eax),%eax
8010453e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104541:	83 c2 10             	add    $0x10,%edx
80104544:	89 04 95 c8 08 11 80 	mov    %eax,-0x7feef738(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010454b:	a1 f4 08 11 80       	mov    0x801108f4,%eax
80104550:	03 45 f4             	add    -0xc(%ebp),%eax
80104553:	83 c0 01             	add    $0x1,%eax
80104556:	89 c2                	mov    %eax,%edx
80104558:	8b 45 08             	mov    0x8(%ebp),%eax
8010455b:	8b 40 04             	mov    0x4(%eax),%eax
8010455e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104562:	89 04 24             	mov    %eax,(%esp)
80104565:	e8 3c bc ff ff       	call   801001a6 <bread>
8010456a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
8010456d:	8b 45 08             	mov    0x8(%ebp),%eax
80104570:	8d 50 18             	lea    0x18(%eax),%edx
80104573:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104576:	83 c0 18             	add    $0x18,%eax
80104579:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80104580:	00 
80104581:	89 54 24 04          	mov    %edx,0x4(%esp)
80104585:	89 04 24             	mov    %eax,(%esp)
80104588:	e8 3c 1b 00 00       	call   801060c9 <memmove>
  bwrite(lbuf);
8010458d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104590:	89 04 24             	mov    %eax,(%esp)
80104593:	e8 45 bc ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80104598:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010459b:	89 04 24             	mov    %eax,(%esp)
8010459e:	e8 74 bc ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801045a3:	a1 04 09 11 80       	mov    0x80110904,%eax
801045a8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801045ab:	75 0d                	jne    801045ba <log_write+0xf8>
    log.lh.n++;
801045ad:	a1 04 09 11 80       	mov    0x80110904,%eax
801045b2:	83 c0 01             	add    $0x1,%eax
801045b5:	a3 04 09 11 80       	mov    %eax,0x80110904
  b->flags |= B_DIRTY; // XXX prevent eviction
801045ba:	8b 45 08             	mov    0x8(%ebp),%eax
801045bd:	8b 00                	mov    (%eax),%eax
801045bf:	89 c2                	mov    %eax,%edx
801045c1:	83 ca 04             	or     $0x4,%edx
801045c4:	8b 45 08             	mov    0x8(%ebp),%eax
801045c7:	89 10                	mov    %edx,(%eax)
}
801045c9:	c9                   	leave  
801045ca:	c3                   	ret    
	...

801045cc <v2p>:
801045cc:	55                   	push   %ebp
801045cd:	89 e5                	mov    %esp,%ebp
801045cf:	8b 45 08             	mov    0x8(%ebp),%eax
801045d2:	05 00 00 00 80       	add    $0x80000000,%eax
801045d7:	5d                   	pop    %ebp
801045d8:	c3                   	ret    

801045d9 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801045d9:	55                   	push   %ebp
801045da:	89 e5                	mov    %esp,%ebp
801045dc:	8b 45 08             	mov    0x8(%ebp),%eax
801045df:	05 00 00 00 80       	add    $0x80000000,%eax
801045e4:	5d                   	pop    %ebp
801045e5:	c3                   	ret    

801045e6 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801045e6:	55                   	push   %ebp
801045e7:	89 e5                	mov    %esp,%ebp
801045e9:	53                   	push   %ebx
801045ea:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801045ed:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801045f0:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801045f3:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801045f6:	89 c3                	mov    %eax,%ebx
801045f8:	89 d8                	mov    %ebx,%eax
801045fa:	f0 87 02             	lock xchg %eax,(%edx)
801045fd:	89 c3                	mov    %eax,%ebx
801045ff:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104602:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104605:	83 c4 10             	add    $0x10,%esp
80104608:	5b                   	pop    %ebx
80104609:	5d                   	pop    %ebp
8010460a:	c3                   	ret    

8010460b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010460b:	55                   	push   %ebp
8010460c:	89 e5                	mov    %esp,%ebp
8010460e:	83 e4 f0             	and    $0xfffffff0,%esp
80104611:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80104614:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010461b:	80 
8010461c:	c7 04 24 3c 37 11 80 	movl   $0x8011373c,(%esp)
80104623:	e8 ad f5 ff ff       	call   80103bd5 <kinit1>
  kvmalloc();      // kernel page table
80104628:	e8 6d 47 00 00       	call   80108d9a <kvmalloc>
  mpinit();        // collect info about this machine
8010462d:	e8 63 04 00 00       	call   80104a95 <mpinit>
  lapicinit(mpbcpu());
80104632:	e8 2e 02 00 00       	call   80104865 <mpbcpu>
80104637:	89 04 24             	mov    %eax,(%esp)
8010463a:	e8 f5 f8 ff ff       	call   80103f34 <lapicinit>
  seginit();       // set up segments
8010463f:	e8 f9 40 00 00       	call   8010873d <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80104644:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010464a:	0f b6 00             	movzbl (%eax),%eax
8010464d:	0f b6 c0             	movzbl %al,%eax
80104650:	89 44 24 04          	mov    %eax,0x4(%esp)
80104654:	c7 04 24 35 98 10 80 	movl   $0x80109835,(%esp)
8010465b:	e8 41 bd ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80104660:	e8 95 06 00 00       	call   80104cfa <picinit>
  ioapicinit();    // another interrupt controller
80104665:	e8 5b f4 ff ff       	call   80103ac5 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010466a:	e8 1e c4 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
8010466f:	e8 14 34 00 00       	call   80107a88 <uartinit>
  pinit();         // process table
80104674:	e8 96 0b 00 00       	call   8010520f <pinit>
  tvinit();        // trap vectors
80104679:	e8 ad 2f 00 00       	call   8010762b <tvinit>
  binit();         // buffer cache
8010467e:	e8 b1 b9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80104683:	e8 78 c8 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
80104688:	e8 2e dd ff ff       	call   801023bb <iinit>
  ideinit();       // disk
8010468d:	e8 98 f0 ff ff       	call   8010372a <ideinit>
  if(!ismp)
80104692:	a1 44 09 11 80       	mov    0x80110944,%eax
80104697:	85 c0                	test   %eax,%eax
80104699:	75 05                	jne    801046a0 <main+0x95>
    timerinit();   // uniprocessor timer
8010469b:	e8 ce 2e 00 00       	call   8010756e <timerinit>
  startothers();   // start other processors
801046a0:	e8 87 00 00 00       	call   8010472c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801046a5:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801046ac:	8e 
801046ad:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801046b4:	e8 54 f5 ff ff       	call   80103c0d <kinit2>
  userinit();      // first user process
801046b9:	e8 6c 0c 00 00       	call   8010532a <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801046be:	e8 22 00 00 00       	call   801046e5 <mpmain>

801046c3 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801046c3:	55                   	push   %ebp
801046c4:	89 e5                	mov    %esp,%ebp
801046c6:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
801046c9:	e8 e3 46 00 00       	call   80108db1 <switchkvm>
  seginit();
801046ce:	e8 6a 40 00 00       	call   8010873d <seginit>
  lapicinit(cpunum());
801046d3:	e8 b9 f9 ff ff       	call   80104091 <cpunum>
801046d8:	89 04 24             	mov    %eax,(%esp)
801046db:	e8 54 f8 ff ff       	call   80103f34 <lapicinit>
  mpmain();
801046e0:	e8 00 00 00 00       	call   801046e5 <mpmain>

801046e5 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801046e5:	55                   	push   %ebp
801046e6:	89 e5                	mov    %esp,%ebp
801046e8:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801046eb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801046f1:	0f b6 00             	movzbl (%eax),%eax
801046f4:	0f b6 c0             	movzbl %al,%eax
801046f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801046fb:	c7 04 24 4c 98 10 80 	movl   $0x8010984c,(%esp)
80104702:	e8 9a bc ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80104707:	e8 93 30 00 00       	call   8010779f <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010470c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104712:	05 a8 00 00 00       	add    $0xa8,%eax
80104717:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010471e:	00 
8010471f:	89 04 24             	mov    %eax,(%esp)
80104722:	e8 bf fe ff ff       	call   801045e6 <xchg>
  scheduler();     // start running processes
80104727:	e8 f4 11 00 00       	call   80105920 <scheduler>

8010472c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010472c:	55                   	push   %ebp
8010472d:	89 e5                	mov    %esp,%ebp
8010472f:	53                   	push   %ebx
80104730:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80104733:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010473a:	e8 9a fe ff ff       	call   801045d9 <p2v>
8010473f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80104742:	b8 8a 00 00 00       	mov    $0x8a,%eax
80104747:	89 44 24 08          	mov    %eax,0x8(%esp)
8010474b:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80104752:	80 
80104753:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104756:	89 04 24             	mov    %eax,(%esp)
80104759:	e8 6b 19 00 00       	call   801060c9 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
8010475e:	c7 45 f4 60 09 11 80 	movl   $0x80110960,-0xc(%ebp)
80104765:	e9 86 00 00 00       	jmp    801047f0 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010476a:	e8 22 f9 ff ff       	call   80104091 <cpunum>
8010476f:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104775:	05 60 09 11 80       	add    $0x80110960,%eax
8010477a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010477d:	74 69                	je     801047e8 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
8010477f:	e8 7f f5 ff ff       	call   80103d03 <kalloc>
80104784:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80104787:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010478a:	83 e8 04             	sub    $0x4,%eax
8010478d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104790:	81 c2 00 10 00 00    	add    $0x1000,%edx
80104796:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80104798:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010479b:	83 e8 08             	sub    $0x8,%eax
8010479e:	c7 00 c3 46 10 80    	movl   $0x801046c3,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801047a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047a7:	8d 58 f4             	lea    -0xc(%eax),%ebx
801047aa:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
801047b1:	e8 16 fe ff ff       	call   801045cc <v2p>
801047b6:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801047b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801047bb:	89 04 24             	mov    %eax,(%esp)
801047be:	e8 09 fe ff ff       	call   801045cc <v2p>
801047c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047c6:	0f b6 12             	movzbl (%edx),%edx
801047c9:	0f b6 d2             	movzbl %dl,%edx
801047cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801047d0:	89 14 24             	mov    %edx,(%esp)
801047d3:	e8 3f f9 ff ff       	call   80104117 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801047d8:	90                   	nop
801047d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047dc:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
801047e2:	85 c0                	test   %eax,%eax
801047e4:	74 f3                	je     801047d9 <startothers+0xad>
801047e6:	eb 01                	jmp    801047e9 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
801047e8:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801047e9:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801047f0:	a1 40 0f 11 80       	mov    0x80110f40,%eax
801047f5:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801047fb:	05 60 09 11 80       	add    $0x80110960,%eax
80104800:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104803:	0f 87 61 ff ff ff    	ja     8010476a <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80104809:	83 c4 24             	add    $0x24,%esp
8010480c:	5b                   	pop    %ebx
8010480d:	5d                   	pop    %ebp
8010480e:	c3                   	ret    
	...

80104810 <p2v>:
80104810:	55                   	push   %ebp
80104811:	89 e5                	mov    %esp,%ebp
80104813:	8b 45 08             	mov    0x8(%ebp),%eax
80104816:	05 00 00 00 80       	add    $0x80000000,%eax
8010481b:	5d                   	pop    %ebp
8010481c:	c3                   	ret    

8010481d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010481d:	55                   	push   %ebp
8010481e:	89 e5                	mov    %esp,%ebp
80104820:	53                   	push   %ebx
80104821:	83 ec 14             	sub    $0x14,%esp
80104824:	8b 45 08             	mov    0x8(%ebp),%eax
80104827:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010482b:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010482f:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80104833:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80104837:	ec                   	in     (%dx),%al
80104838:	89 c3                	mov    %eax,%ebx
8010483a:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
8010483d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80104841:	83 c4 14             	add    $0x14,%esp
80104844:	5b                   	pop    %ebx
80104845:	5d                   	pop    %ebp
80104846:	c3                   	ret    

80104847 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104847:	55                   	push   %ebp
80104848:	89 e5                	mov    %esp,%ebp
8010484a:	83 ec 08             	sub    $0x8,%esp
8010484d:	8b 55 08             	mov    0x8(%ebp),%edx
80104850:	8b 45 0c             	mov    0xc(%ebp),%eax
80104853:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104857:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010485a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010485e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104862:	ee                   	out    %al,(%dx)
}
80104863:	c9                   	leave  
80104864:	c3                   	ret    

80104865 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80104865:	55                   	push   %ebp
80104866:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80104868:	a1 64 c6 10 80       	mov    0x8010c664,%eax
8010486d:	89 c2                	mov    %eax,%edx
8010486f:	b8 60 09 11 80       	mov    $0x80110960,%eax
80104874:	89 d1                	mov    %edx,%ecx
80104876:	29 c1                	sub    %eax,%ecx
80104878:	89 c8                	mov    %ecx,%eax
8010487a:	c1 f8 02             	sar    $0x2,%eax
8010487d:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80104883:	5d                   	pop    %ebp
80104884:	c3                   	ret    

80104885 <sum>:

static uchar
sum(uchar *addr, int len)
{
80104885:	55                   	push   %ebp
80104886:	89 e5                	mov    %esp,%ebp
80104888:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010488b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80104892:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80104899:	eb 13                	jmp    801048ae <sum+0x29>
    sum += addr[i];
8010489b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010489e:	03 45 08             	add    0x8(%ebp),%eax
801048a1:	0f b6 00             	movzbl (%eax),%eax
801048a4:	0f b6 c0             	movzbl %al,%eax
801048a7:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801048aa:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801048ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
801048b1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801048b4:	7c e5                	jl     8010489b <sum+0x16>
    sum += addr[i];
  return sum;
801048b6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801048b9:	c9                   	leave  
801048ba:	c3                   	ret    

801048bb <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801048bb:	55                   	push   %ebp
801048bc:	89 e5                	mov    %esp,%ebp
801048be:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801048c1:	8b 45 08             	mov    0x8(%ebp),%eax
801048c4:	89 04 24             	mov    %eax,(%esp)
801048c7:	e8 44 ff ff ff       	call   80104810 <p2v>
801048cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801048cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801048d2:	03 45 f0             	add    -0x10(%ebp),%eax
801048d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801048d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801048db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801048de:	eb 3f                	jmp    8010491f <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
801048e0:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801048e7:	00 
801048e8:	c7 44 24 04 60 98 10 	movl   $0x80109860,0x4(%esp)
801048ef:	80 
801048f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048f3:	89 04 24             	mov    %eax,(%esp)
801048f6:	e8 72 17 00 00       	call   8010606d <memcmp>
801048fb:	85 c0                	test   %eax,%eax
801048fd:	75 1c                	jne    8010491b <mpsearch1+0x60>
801048ff:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80104906:	00 
80104907:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010490a:	89 04 24             	mov    %eax,(%esp)
8010490d:	e8 73 ff ff ff       	call   80104885 <sum>
80104912:	84 c0                	test   %al,%al
80104914:	75 05                	jne    8010491b <mpsearch1+0x60>
      return (struct mp*)p;
80104916:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104919:	eb 11                	jmp    8010492c <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010491b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010491f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104922:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104925:	72 b9                	jb     801048e0 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80104927:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010492c:	c9                   	leave  
8010492d:	c3                   	ret    

8010492e <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
8010492e:	55                   	push   %ebp
8010492f:	89 e5                	mov    %esp,%ebp
80104931:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80104934:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010493b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010493e:	83 c0 0f             	add    $0xf,%eax
80104941:	0f b6 00             	movzbl (%eax),%eax
80104944:	0f b6 c0             	movzbl %al,%eax
80104947:	89 c2                	mov    %eax,%edx
80104949:	c1 e2 08             	shl    $0x8,%edx
8010494c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494f:	83 c0 0e             	add    $0xe,%eax
80104952:	0f b6 00             	movzbl (%eax),%eax
80104955:	0f b6 c0             	movzbl %al,%eax
80104958:	09 d0                	or     %edx,%eax
8010495a:	c1 e0 04             	shl    $0x4,%eax
8010495d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104960:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104964:	74 21                	je     80104987 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80104966:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010496d:	00 
8010496e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104971:	89 04 24             	mov    %eax,(%esp)
80104974:	e8 42 ff ff ff       	call   801048bb <mpsearch1>
80104979:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010497c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80104980:	74 50                	je     801049d2 <mpsearch+0xa4>
      return mp;
80104982:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104985:	eb 5f                	jmp    801049e6 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80104987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010498a:	83 c0 14             	add    $0x14,%eax
8010498d:	0f b6 00             	movzbl (%eax),%eax
80104990:	0f b6 c0             	movzbl %al,%eax
80104993:	89 c2                	mov    %eax,%edx
80104995:	c1 e2 08             	shl    $0x8,%edx
80104998:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010499b:	83 c0 13             	add    $0x13,%eax
8010499e:	0f b6 00             	movzbl (%eax),%eax
801049a1:	0f b6 c0             	movzbl %al,%eax
801049a4:	09 d0                	or     %edx,%eax
801049a6:	c1 e0 0a             	shl    $0xa,%eax
801049a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801049ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049af:	2d 00 04 00 00       	sub    $0x400,%eax
801049b4:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801049bb:	00 
801049bc:	89 04 24             	mov    %eax,(%esp)
801049bf:	e8 f7 fe ff ff       	call   801048bb <mpsearch1>
801049c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
801049c7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801049cb:	74 05                	je     801049d2 <mpsearch+0xa4>
      return mp;
801049cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801049d0:	eb 14                	jmp    801049e6 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
801049d2:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
801049d9:	00 
801049da:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
801049e1:	e8 d5 fe ff ff       	call   801048bb <mpsearch1>
}
801049e6:	c9                   	leave  
801049e7:	c3                   	ret    

801049e8 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
801049e8:	55                   	push   %ebp
801049e9:	89 e5                	mov    %esp,%ebp
801049eb:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801049ee:	e8 3b ff ff ff       	call   8010492e <mpsearch>
801049f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801049f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801049fa:	74 0a                	je     80104a06 <mpconfig+0x1e>
801049fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ff:	8b 40 04             	mov    0x4(%eax),%eax
80104a02:	85 c0                	test   %eax,%eax
80104a04:	75 0a                	jne    80104a10 <mpconfig+0x28>
    return 0;
80104a06:	b8 00 00 00 00       	mov    $0x0,%eax
80104a0b:	e9 83 00 00 00       	jmp    80104a93 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80104a10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a13:	8b 40 04             	mov    0x4(%eax),%eax
80104a16:	89 04 24             	mov    %eax,(%esp)
80104a19:	e8 f2 fd ff ff       	call   80104810 <p2v>
80104a1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80104a21:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80104a28:	00 
80104a29:	c7 44 24 04 65 98 10 	movl   $0x80109865,0x4(%esp)
80104a30:	80 
80104a31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a34:	89 04 24             	mov    %eax,(%esp)
80104a37:	e8 31 16 00 00       	call   8010606d <memcmp>
80104a3c:	85 c0                	test   %eax,%eax
80104a3e:	74 07                	je     80104a47 <mpconfig+0x5f>
    return 0;
80104a40:	b8 00 00 00 00       	mov    $0x0,%eax
80104a45:	eb 4c                	jmp    80104a93 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80104a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a4a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104a4e:	3c 01                	cmp    $0x1,%al
80104a50:	74 12                	je     80104a64 <mpconfig+0x7c>
80104a52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a55:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80104a59:	3c 04                	cmp    $0x4,%al
80104a5b:	74 07                	je     80104a64 <mpconfig+0x7c>
    return 0;
80104a5d:	b8 00 00 00 00       	mov    $0x0,%eax
80104a62:	eb 2f                	jmp    80104a93 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80104a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a67:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104a6b:	0f b7 c0             	movzwl %ax,%eax
80104a6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104a72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a75:	89 04 24             	mov    %eax,(%esp)
80104a78:	e8 08 fe ff ff       	call   80104885 <sum>
80104a7d:	84 c0                	test   %al,%al
80104a7f:	74 07                	je     80104a88 <mpconfig+0xa0>
    return 0;
80104a81:	b8 00 00 00 00       	mov    $0x0,%eax
80104a86:	eb 0b                	jmp    80104a93 <mpconfig+0xab>
  *pmp = mp;
80104a88:	8b 45 08             	mov    0x8(%ebp),%eax
80104a8b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a8e:	89 10                	mov    %edx,(%eax)
  return conf;
80104a90:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80104a93:	c9                   	leave  
80104a94:	c3                   	ret    

80104a95 <mpinit>:

void
mpinit(void)
{
80104a95:	55                   	push   %ebp
80104a96:	89 e5                	mov    %esp,%ebp
80104a98:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80104a9b:	c7 05 64 c6 10 80 60 	movl   $0x80110960,0x8010c664
80104aa2:	09 11 80 
  if((conf = mpconfig(&mp)) == 0)
80104aa5:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104aa8:	89 04 24             	mov    %eax,(%esp)
80104aab:	e8 38 ff ff ff       	call   801049e8 <mpconfig>
80104ab0:	89 45 f0             	mov    %eax,-0x10(%ebp)
80104ab3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104ab7:	0f 84 9c 01 00 00    	je     80104c59 <mpinit+0x1c4>
    return;
  ismp = 1;
80104abd:	c7 05 44 09 11 80 01 	movl   $0x1,0x80110944
80104ac4:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80104ac7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aca:	8b 40 24             	mov    0x24(%eax),%eax
80104acd:	a3 bc 08 11 80       	mov    %eax,0x801108bc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ad5:	83 c0 2c             	add    $0x2c,%eax
80104ad8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104adb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ade:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80104ae2:	0f b7 c0             	movzwl %ax,%eax
80104ae5:	03 45 f0             	add    -0x10(%ebp),%eax
80104ae8:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104aeb:	e9 f4 00 00 00       	jmp    80104be4 <mpinit+0x14f>
    switch(*p){
80104af0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104af3:	0f b6 00             	movzbl (%eax),%eax
80104af6:	0f b6 c0             	movzbl %al,%eax
80104af9:	83 f8 04             	cmp    $0x4,%eax
80104afc:	0f 87 bf 00 00 00    	ja     80104bc1 <mpinit+0x12c>
80104b02:	8b 04 85 a8 98 10 80 	mov    -0x7fef6758(,%eax,4),%eax
80104b09:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80104b0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b0e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80104b11:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b14:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104b18:	0f b6 d0             	movzbl %al,%edx
80104b1b:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b20:	39 c2                	cmp    %eax,%edx
80104b22:	74 2d                	je     80104b51 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80104b24:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b27:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104b2b:	0f b6 d0             	movzbl %al,%edx
80104b2e:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b33:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b37:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b3b:	c7 04 24 6a 98 10 80 	movl   $0x8010986a,(%esp)
80104b42:	e8 5a b8 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80104b47:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
80104b4e:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80104b51:	8b 45 e8             	mov    -0x18(%ebp),%eax
80104b54:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80104b58:	0f b6 c0             	movzbl %al,%eax
80104b5b:	83 e0 02             	and    $0x2,%eax
80104b5e:	85 c0                	test   %eax,%eax
80104b60:	74 15                	je     80104b77 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80104b62:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b67:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80104b6d:	05 60 09 11 80       	add    $0x80110960,%eax
80104b72:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80104b77:	8b 15 40 0f 11 80    	mov    0x80110f40,%edx
80104b7d:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b82:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80104b88:	81 c2 60 09 11 80    	add    $0x80110960,%edx
80104b8e:	88 02                	mov    %al,(%edx)
      ncpu++;
80104b90:	a1 40 0f 11 80       	mov    0x80110f40,%eax
80104b95:	83 c0 01             	add    $0x1,%eax
80104b98:	a3 40 0f 11 80       	mov    %eax,0x80110f40
      p += sizeof(struct mpproc);
80104b9d:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104ba1:	eb 41                	jmp    80104be4 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104ba3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80104ba9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104bac:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104bb0:	a2 40 09 11 80       	mov    %al,0x80110940
      p += sizeof(struct mpioapic);
80104bb5:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104bb9:	eb 29                	jmp    80104be4 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80104bbb:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104bbf:	eb 23                	jmp    80104be4 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bc4:	0f b6 00             	movzbl (%eax),%eax
80104bc7:	0f b6 c0             	movzbl %al,%eax
80104bca:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bce:	c7 04 24 88 98 10 80 	movl   $0x80109888,(%esp)
80104bd5:	e8 c7 b7 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80104bda:	c7 05 44 09 11 80 00 	movl   $0x0,0x80110944
80104be1:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104be4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104be7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104bea:	0f 82 00 ff ff ff    	jb     80104af0 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104bf0:	a1 44 09 11 80       	mov    0x80110944,%eax
80104bf5:	85 c0                	test   %eax,%eax
80104bf7:	75 1d                	jne    80104c16 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80104bf9:	c7 05 40 0f 11 80 01 	movl   $0x1,0x80110f40
80104c00:	00 00 00 
    lapic = 0;
80104c03:	c7 05 bc 08 11 80 00 	movl   $0x0,0x801108bc
80104c0a:	00 00 00 
    ioapicid = 0;
80104c0d:	c6 05 40 09 11 80 00 	movb   $0x0,0x80110940
    return;
80104c14:	eb 44                	jmp    80104c5a <mpinit+0x1c5>
  }

  if(mp->imcrp){
80104c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104c19:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104c1d:	84 c0                	test   %al,%al
80104c1f:	74 39                	je     80104c5a <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104c21:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80104c28:	00 
80104c29:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80104c30:	e8 12 fc ff ff       	call   80104847 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80104c35:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104c3c:	e8 dc fb ff ff       	call   8010481d <inb>
80104c41:	83 c8 01             	or     $0x1,%eax
80104c44:	0f b6 c0             	movzbl %al,%eax
80104c47:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c4b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80104c52:	e8 f0 fb ff ff       	call   80104847 <outb>
80104c57:	eb 01                	jmp    80104c5a <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80104c59:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80104c5a:	c9                   	leave  
80104c5b:	c3                   	ret    

80104c5c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80104c5c:	55                   	push   %ebp
80104c5d:	89 e5                	mov    %esp,%ebp
80104c5f:	83 ec 08             	sub    $0x8,%esp
80104c62:	8b 55 08             	mov    0x8(%ebp),%edx
80104c65:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c68:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80104c6c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80104c6f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80104c73:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80104c77:	ee                   	out    %al,(%dx)
}
80104c78:	c9                   	leave  
80104c79:	c3                   	ret    

80104c7a <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80104c7a:	55                   	push   %ebp
80104c7b:	89 e5                	mov    %esp,%ebp
80104c7d:	83 ec 0c             	sub    $0xc,%esp
80104c80:	8b 45 08             	mov    0x8(%ebp),%eax
80104c83:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80104c87:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104c8b:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80104c91:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104c95:	0f b6 c0             	movzbl %al,%eax
80104c98:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c9c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104ca3:	e8 b4 ff ff ff       	call   80104c5c <outb>
  outb(IO_PIC2+1, mask >> 8);
80104ca8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104cac:	66 c1 e8 08          	shr    $0x8,%ax
80104cb0:	0f b6 c0             	movzbl %al,%eax
80104cb3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cb7:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104cbe:	e8 99 ff ff ff       	call   80104c5c <outb>
}
80104cc3:	c9                   	leave  
80104cc4:	c3                   	ret    

80104cc5 <picenable>:

void
picenable(int irq)
{
80104cc5:	55                   	push   %ebp
80104cc6:	89 e5                	mov    %esp,%ebp
80104cc8:	53                   	push   %ebx
80104cc9:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104ccc:	8b 45 08             	mov    0x8(%ebp),%eax
80104ccf:	ba 01 00 00 00       	mov    $0x1,%edx
80104cd4:	89 d3                	mov    %edx,%ebx
80104cd6:	89 c1                	mov    %eax,%ecx
80104cd8:	d3 e3                	shl    %cl,%ebx
80104cda:	89 d8                	mov    %ebx,%eax
80104cdc:	89 c2                	mov    %eax,%edx
80104cde:	f7 d2                	not    %edx
80104ce0:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104ce7:	21 d0                	and    %edx,%eax
80104ce9:	0f b7 c0             	movzwl %ax,%eax
80104cec:	89 04 24             	mov    %eax,(%esp)
80104cef:	e8 86 ff ff ff       	call   80104c7a <picsetmask>
}
80104cf4:	83 c4 04             	add    $0x4,%esp
80104cf7:	5b                   	pop    %ebx
80104cf8:	5d                   	pop    %ebp
80104cf9:	c3                   	ret    

80104cfa <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80104cfa:	55                   	push   %ebp
80104cfb:	89 e5                	mov    %esp,%ebp
80104cfd:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104d00:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104d07:	00 
80104d08:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d0f:	e8 48 ff ff ff       	call   80104c5c <outb>
  outb(IO_PIC2+1, 0xFF);
80104d14:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80104d1b:	00 
80104d1c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104d23:	e8 34 ff ff ff       	call   80104c5c <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80104d28:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104d2f:	00 
80104d30:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104d37:	e8 20 ff ff ff       	call   80104c5c <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80104d3c:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104d43:	00 
80104d44:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d4b:	e8 0c ff ff ff       	call   80104c5c <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104d50:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104d57:	00 
80104d58:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d5f:	e8 f8 fe ff ff       	call   80104c5c <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104d64:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104d6b:	00 
80104d6c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104d73:	e8 e4 fe ff ff       	call   80104c5c <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104d78:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80104d7f:	00 
80104d80:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104d87:	e8 d0 fe ff ff       	call   80104c5c <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104d8c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104d93:	00 
80104d94:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104d9b:	e8 bc fe ff ff       	call   80104c5c <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104da0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104da7:	00 
80104da8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104daf:	e8 a8 fe ff ff       	call   80104c5c <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104db4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80104dbb:	00 
80104dbc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104dc3:	e8 94 fe ff ff       	call   80104c5c <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104dc8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104dcf:	00 
80104dd0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104dd7:	e8 80 fe ff ff       	call   80104c5c <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104ddc:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104de3:	00 
80104de4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104deb:	e8 6c fe ff ff       	call   80104c5c <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104df0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104df7:	00 
80104df8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104dff:	e8 58 fe ff ff       	call   80104c5c <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104e04:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104e0b:	00 
80104e0c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104e13:	e8 44 fe ff ff       	call   80104c5c <outb>

  if(irqmask != 0xFFFF)
80104e18:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104e1f:	66 83 f8 ff          	cmp    $0xffff,%ax
80104e23:	74 12                	je     80104e37 <picinit+0x13d>
    picsetmask(irqmask);
80104e25:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80104e2c:	0f b7 c0             	movzwl %ax,%eax
80104e2f:	89 04 24             	mov    %eax,(%esp)
80104e32:	e8 43 fe ff ff       	call   80104c7a <picsetmask>
}
80104e37:	c9                   	leave  
80104e38:	c3                   	ret    
80104e39:	00 00                	add    %al,(%eax)
	...

80104e3c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80104e3c:	55                   	push   %ebp
80104e3d:	89 e5                	mov    %esp,%ebp
80104e3f:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80104e42:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104e49:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e4c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80104e52:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e55:	8b 10                	mov    (%eax),%edx
80104e57:	8b 45 08             	mov    0x8(%ebp),%eax
80104e5a:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104e5c:	e8 bb c0 ff ff       	call   80100f1c <filealloc>
80104e61:	8b 55 08             	mov    0x8(%ebp),%edx
80104e64:	89 02                	mov    %eax,(%edx)
80104e66:	8b 45 08             	mov    0x8(%ebp),%eax
80104e69:	8b 00                	mov    (%eax),%eax
80104e6b:	85 c0                	test   %eax,%eax
80104e6d:	0f 84 c8 00 00 00    	je     80104f3b <pipealloc+0xff>
80104e73:	e8 a4 c0 ff ff       	call   80100f1c <filealloc>
80104e78:	8b 55 0c             	mov    0xc(%ebp),%edx
80104e7b:	89 02                	mov    %eax,(%edx)
80104e7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e80:	8b 00                	mov    (%eax),%eax
80104e82:	85 c0                	test   %eax,%eax
80104e84:	0f 84 b1 00 00 00    	je     80104f3b <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104e8a:	e8 74 ee ff ff       	call   80103d03 <kalloc>
80104e8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104e92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104e96:	0f 84 9e 00 00 00    	je     80104f3a <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104e9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e9f:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104ea6:	00 00 00 
  p->writeopen = 1;
80104ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eac:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104eb3:	00 00 00 
  p->nwrite = 0;
80104eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eb9:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104ec0:	00 00 00 
  p->nread = 0;
80104ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec6:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104ecd:	00 00 00 
  initlock(&p->lock, "pipe");
80104ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ed3:	c7 44 24 04 bc 98 10 	movl   $0x801098bc,0x4(%esp)
80104eda:	80 
80104edb:	89 04 24             	mov    %eax,(%esp)
80104ede:	e8 a3 0e 00 00       	call   80105d86 <initlock>
  (*f0)->type = FD_PIPE;
80104ee3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee6:	8b 00                	mov    (%eax),%eax
80104ee8:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104eee:	8b 45 08             	mov    0x8(%ebp),%eax
80104ef1:	8b 00                	mov    (%eax),%eax
80104ef3:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104ef7:	8b 45 08             	mov    0x8(%ebp),%eax
80104efa:	8b 00                	mov    (%eax),%eax
80104efc:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104f00:	8b 45 08             	mov    0x8(%ebp),%eax
80104f03:	8b 00                	mov    (%eax),%eax
80104f05:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f08:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f0e:	8b 00                	mov    (%eax),%eax
80104f10:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104f16:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f19:	8b 00                	mov    (%eax),%eax
80104f1b:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104f1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f22:	8b 00                	mov    (%eax),%eax
80104f24:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104f28:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f2b:	8b 00                	mov    (%eax),%eax
80104f2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f30:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104f33:	b8 00 00 00 00       	mov    $0x0,%eax
80104f38:	eb 43                	jmp    80104f7d <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80104f3a:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80104f3b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104f3f:	74 0b                	je     80104f4c <pipealloc+0x110>
    kfree((char*)p);
80104f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f44:	89 04 24             	mov    %eax,(%esp)
80104f47:	e8 1e ed ff ff       	call   80103c6a <kfree>
  if(*f0)
80104f4c:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4f:	8b 00                	mov    (%eax),%eax
80104f51:	85 c0                	test   %eax,%eax
80104f53:	74 0d                	je     80104f62 <pipealloc+0x126>
    fileclose(*f0);
80104f55:	8b 45 08             	mov    0x8(%ebp),%eax
80104f58:	8b 00                	mov    (%eax),%eax
80104f5a:	89 04 24             	mov    %eax,(%esp)
80104f5d:	e8 62 c0 ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80104f62:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f65:	8b 00                	mov    (%eax),%eax
80104f67:	85 c0                	test   %eax,%eax
80104f69:	74 0d                	je     80104f78 <pipealloc+0x13c>
    fileclose(*f1);
80104f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f6e:	8b 00                	mov    (%eax),%eax
80104f70:	89 04 24             	mov    %eax,(%esp)
80104f73:	e8 4c c0 ff ff       	call   80100fc4 <fileclose>
  return -1;
80104f78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104f7d:	c9                   	leave  
80104f7e:	c3                   	ret    

80104f7f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80104f7f:	55                   	push   %ebp
80104f80:	89 e5                	mov    %esp,%ebp
80104f82:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104f85:	8b 45 08             	mov    0x8(%ebp),%eax
80104f88:	89 04 24             	mov    %eax,(%esp)
80104f8b:	e8 17 0e 00 00       	call   80105da7 <acquire>
  if(writable){
80104f90:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104f94:	74 1f                	je     80104fb5 <pipeclose+0x36>
    p->writeopen = 0;
80104f96:	8b 45 08             	mov    0x8(%ebp),%eax
80104f99:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104fa0:	00 00 00 
    wakeup(&p->nread);
80104fa3:	8b 45 08             	mov    0x8(%ebp),%eax
80104fa6:	05 34 02 00 00       	add    $0x234,%eax
80104fab:	89 04 24             	mov    %eax,(%esp)
80104fae:	e8 ef 0b 00 00       	call   80105ba2 <wakeup>
80104fb3:	eb 1d                	jmp    80104fd2 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104fb5:	8b 45 08             	mov    0x8(%ebp),%eax
80104fb8:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104fbf:	00 00 00 
    wakeup(&p->nwrite);
80104fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80104fc5:	05 38 02 00 00       	add    $0x238,%eax
80104fca:	89 04 24             	mov    %eax,(%esp)
80104fcd:	e8 d0 0b 00 00       	call   80105ba2 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80104fd5:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104fdb:	85 c0                	test   %eax,%eax
80104fdd:	75 25                	jne    80105004 <pipeclose+0x85>
80104fdf:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe2:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104fe8:	85 c0                	test   %eax,%eax
80104fea:	75 18                	jne    80105004 <pipeclose+0x85>
    release(&p->lock);
80104fec:	8b 45 08             	mov    0x8(%ebp),%eax
80104fef:	89 04 24             	mov    %eax,(%esp)
80104ff2:	e8 12 0e 00 00       	call   80105e09 <release>
    kfree((char*)p);
80104ff7:	8b 45 08             	mov    0x8(%ebp),%eax
80104ffa:	89 04 24             	mov    %eax,(%esp)
80104ffd:	e8 68 ec ff ff       	call   80103c6a <kfree>
80105002:	eb 0b                	jmp    8010500f <pipeclose+0x90>
  } else
    release(&p->lock);
80105004:	8b 45 08             	mov    0x8(%ebp),%eax
80105007:	89 04 24             	mov    %eax,(%esp)
8010500a:	e8 fa 0d 00 00       	call   80105e09 <release>
}
8010500f:	c9                   	leave  
80105010:	c3                   	ret    

80105011 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80105011:	55                   	push   %ebp
80105012:	89 e5                	mov    %esp,%ebp
80105014:	53                   	push   %ebx
80105015:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80105018:	8b 45 08             	mov    0x8(%ebp),%eax
8010501b:	89 04 24             	mov    %eax,(%esp)
8010501e:	e8 84 0d 00 00       	call   80105da7 <acquire>
  for(i = 0; i < n; i++){
80105023:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010502a:	e9 a6 00 00 00       	jmp    801050d5 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
8010502f:	8b 45 08             	mov    0x8(%ebp),%eax
80105032:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80105038:	85 c0                	test   %eax,%eax
8010503a:	74 0d                	je     80105049 <pipewrite+0x38>
8010503c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105042:	8b 40 24             	mov    0x24(%eax),%eax
80105045:	85 c0                	test   %eax,%eax
80105047:	74 15                	je     8010505e <pipewrite+0x4d>
        release(&p->lock);
80105049:	8b 45 08             	mov    0x8(%ebp),%eax
8010504c:	89 04 24             	mov    %eax,(%esp)
8010504f:	e8 b5 0d 00 00       	call   80105e09 <release>
        return -1;
80105054:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105059:	e9 9d 00 00 00       	jmp    801050fb <pipewrite+0xea>
      }
      wakeup(&p->nread);
8010505e:	8b 45 08             	mov    0x8(%ebp),%eax
80105061:	05 34 02 00 00       	add    $0x234,%eax
80105066:	89 04 24             	mov    %eax,(%esp)
80105069:	e8 34 0b 00 00       	call   80105ba2 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010506e:	8b 45 08             	mov    0x8(%ebp),%eax
80105071:	8b 55 08             	mov    0x8(%ebp),%edx
80105074:	81 c2 38 02 00 00    	add    $0x238,%edx
8010507a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010507e:	89 14 24             	mov    %edx,(%esp)
80105081:	e8 43 0a 00 00       	call   80105ac9 <sleep>
80105086:	eb 01                	jmp    80105089 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80105088:	90                   	nop
80105089:	8b 45 08             	mov    0x8(%ebp),%eax
8010508c:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80105092:	8b 45 08             	mov    0x8(%ebp),%eax
80105095:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010509b:	05 00 02 00 00       	add    $0x200,%eax
801050a0:	39 c2                	cmp    %eax,%edx
801050a2:	74 8b                	je     8010502f <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801050a4:	8b 45 08             	mov    0x8(%ebp),%eax
801050a7:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801050ad:	89 c3                	mov    %eax,%ebx
801050af:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801050b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801050b8:	03 55 0c             	add    0xc(%ebp),%edx
801050bb:	0f b6 0a             	movzbl (%edx),%ecx
801050be:	8b 55 08             	mov    0x8(%ebp),%edx
801050c1:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
801050c5:	8d 50 01             	lea    0x1(%eax),%edx
801050c8:	8b 45 08             	mov    0x8(%ebp),%eax
801050cb:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801050d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801050d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050d8:	3b 45 10             	cmp    0x10(%ebp),%eax
801050db:	7c ab                	jl     80105088 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801050dd:	8b 45 08             	mov    0x8(%ebp),%eax
801050e0:	05 34 02 00 00       	add    $0x234,%eax
801050e5:	89 04 24             	mov    %eax,(%esp)
801050e8:	e8 b5 0a 00 00       	call   80105ba2 <wakeup>
  release(&p->lock);
801050ed:	8b 45 08             	mov    0x8(%ebp),%eax
801050f0:	89 04 24             	mov    %eax,(%esp)
801050f3:	e8 11 0d 00 00       	call   80105e09 <release>
  return n;
801050f8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801050fb:	83 c4 24             	add    $0x24,%esp
801050fe:	5b                   	pop    %ebx
801050ff:	5d                   	pop    %ebp
80105100:	c3                   	ret    

80105101 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80105101:	55                   	push   %ebp
80105102:	89 e5                	mov    %esp,%ebp
80105104:	53                   	push   %ebx
80105105:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80105108:	8b 45 08             	mov    0x8(%ebp),%eax
8010510b:	89 04 24             	mov    %eax,(%esp)
8010510e:	e8 94 0c 00 00       	call   80105da7 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80105113:	eb 3a                	jmp    8010514f <piperead+0x4e>
    if(proc->killed){
80105115:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010511b:	8b 40 24             	mov    0x24(%eax),%eax
8010511e:	85 c0                	test   %eax,%eax
80105120:	74 15                	je     80105137 <piperead+0x36>
      release(&p->lock);
80105122:	8b 45 08             	mov    0x8(%ebp),%eax
80105125:	89 04 24             	mov    %eax,(%esp)
80105128:	e8 dc 0c 00 00       	call   80105e09 <release>
      return -1;
8010512d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105132:	e9 b6 00 00 00       	jmp    801051ed <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80105137:	8b 45 08             	mov    0x8(%ebp),%eax
8010513a:	8b 55 08             	mov    0x8(%ebp),%edx
8010513d:	81 c2 34 02 00 00    	add    $0x234,%edx
80105143:	89 44 24 04          	mov    %eax,0x4(%esp)
80105147:	89 14 24             	mov    %edx,(%esp)
8010514a:	e8 7a 09 00 00       	call   80105ac9 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010514f:	8b 45 08             	mov    0x8(%ebp),%eax
80105152:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80105158:	8b 45 08             	mov    0x8(%ebp),%eax
8010515b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80105161:	39 c2                	cmp    %eax,%edx
80105163:	75 0d                	jne    80105172 <piperead+0x71>
80105165:	8b 45 08             	mov    0x8(%ebp),%eax
80105168:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010516e:	85 c0                	test   %eax,%eax
80105170:	75 a3                	jne    80105115 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80105172:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105179:	eb 49                	jmp    801051c4 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010517b:	8b 45 08             	mov    0x8(%ebp),%eax
8010517e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80105184:	8b 45 08             	mov    0x8(%ebp),%eax
80105187:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010518d:	39 c2                	cmp    %eax,%edx
8010518f:	74 3d                	je     801051ce <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80105191:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105194:	89 c2                	mov    %eax,%edx
80105196:	03 55 0c             	add    0xc(%ebp),%edx
80105199:	8b 45 08             	mov    0x8(%ebp),%eax
8010519c:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801051a2:	89 c3                	mov    %eax,%ebx
801051a4:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
801051aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051ad:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
801051b2:	88 0a                	mov    %cl,(%edx)
801051b4:	8d 50 01             	lea    0x1(%eax),%edx
801051b7:	8b 45 08             	mov    0x8(%ebp),%eax
801051ba:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801051c0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801051c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051c7:	3b 45 10             	cmp    0x10(%ebp),%eax
801051ca:	7c af                	jl     8010517b <piperead+0x7a>
801051cc:	eb 01                	jmp    801051cf <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
801051ce:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801051cf:	8b 45 08             	mov    0x8(%ebp),%eax
801051d2:	05 38 02 00 00       	add    $0x238,%eax
801051d7:	89 04 24             	mov    %eax,(%esp)
801051da:	e8 c3 09 00 00       	call   80105ba2 <wakeup>
  release(&p->lock);
801051df:	8b 45 08             	mov    0x8(%ebp),%eax
801051e2:	89 04 24             	mov    %eax,(%esp)
801051e5:	e8 1f 0c 00 00       	call   80105e09 <release>
  return i;
801051ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801051ed:	83 c4 24             	add    $0x24,%esp
801051f0:	5b                   	pop    %ebx
801051f1:	5d                   	pop    %ebp
801051f2:	c3                   	ret    
	...

801051f4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801051f4:	55                   	push   %ebp
801051f5:	89 e5                	mov    %esp,%ebp
801051f7:	53                   	push   %ebx
801051f8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801051fb:	9c                   	pushf  
801051fc:	5b                   	pop    %ebx
801051fd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105200:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105203:	83 c4 10             	add    $0x10,%esp
80105206:	5b                   	pop    %ebx
80105207:	5d                   	pop    %ebp
80105208:	c3                   	ret    

80105209 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80105209:	55                   	push   %ebp
8010520a:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010520c:	fb                   	sti    
}
8010520d:	5d                   	pop    %ebp
8010520e:	c3                   	ret    

8010520f <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
8010520f:	55                   	push   %ebp
80105210:	89 e5                	mov    %esp,%ebp
80105212:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80105215:	c7 44 24 04 c1 98 10 	movl   $0x801098c1,0x4(%esp)
8010521c:	80 
8010521d:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105224:	e8 5d 0b 00 00       	call   80105d86 <initlock>
}
80105229:	c9                   	leave  
8010522a:	c3                   	ret    

8010522b <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010522b:	55                   	push   %ebp
8010522c:	89 e5                	mov    %esp,%ebp
8010522e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80105231:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105238:	e8 6a 0b 00 00       	call   80105da7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010523d:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105244:	eb 0e                	jmp    80105254 <allocproc+0x29>
    if(p->state == UNUSED)
80105246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105249:	8b 40 0c             	mov    0xc(%eax),%eax
8010524c:	85 c0                	test   %eax,%eax
8010524e:	74 23                	je     80105273 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105250:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105254:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
8010525b:	72 e9                	jb     80105246 <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
8010525d:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105264:	e8 a0 0b 00 00       	call   80105e09 <release>
  return 0;
80105269:	b8 00 00 00 00       	mov    $0x0,%eax
8010526e:	e9 b5 00 00 00       	jmp    80105328 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80105273:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80105274:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105277:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010527e:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80105283:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105286:	89 42 10             	mov    %eax,0x10(%edx)
80105289:	83 c0 01             	add    $0x1,%eax
8010528c:	a3 04 c0 10 80       	mov    %eax,0x8010c004
  release(&ptable.lock);
80105291:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105298:	e8 6c 0b 00 00       	call   80105e09 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
8010529d:	e8 61 ea ff ff       	call   80103d03 <kalloc>
801052a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801052a5:	89 42 08             	mov    %eax,0x8(%edx)
801052a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052ab:	8b 40 08             	mov    0x8(%eax),%eax
801052ae:	85 c0                	test   %eax,%eax
801052b0:	75 11                	jne    801052c3 <allocproc+0x98>
    p->state = UNUSED;
801052b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052b5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801052bc:	b8 00 00 00 00       	mov    $0x0,%eax
801052c1:	eb 65                	jmp    80105328 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
801052c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052c6:	8b 40 08             	mov    0x8(%eax),%eax
801052c9:	05 00 10 00 00       	add    $0x1000,%eax
801052ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
801052d1:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
801052d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052db:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
801052de:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
801052e2:	ba e0 75 10 80       	mov    $0x801075e0,%edx
801052e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801052ea:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801052ec:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801052f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801052f6:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801052f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052fc:	8b 40 1c             	mov    0x1c(%eax),%eax
801052ff:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105306:	00 
80105307:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010530e:	00 
8010530f:	89 04 24             	mov    %eax,(%esp)
80105312:	e8 df 0c 00 00       	call   80105ff6 <memset>
  p->context->eip = (uint)forkret;
80105317:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010531a:	8b 40 1c             	mov    0x1c(%eax),%eax
8010531d:	ba 9d 5a 10 80       	mov    $0x80105a9d,%edx
80105322:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80105325:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105328:	c9                   	leave  
80105329:	c3                   	ret    

8010532a <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010532a:	55                   	push   %ebp
8010532b:	89 e5                	mov    %esp,%ebp
8010532d:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80105330:	e8 f6 fe ff ff       	call   8010522b <allocproc>
80105335:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80105338:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010533b:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm(kalloc)) == 0)
80105340:	c7 04 24 03 3d 10 80 	movl   $0x80103d03,(%esp)
80105347:	e8 91 39 00 00       	call   80108cdd <setupkvm>
8010534c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010534f:	89 42 04             	mov    %eax,0x4(%edx)
80105352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105355:	8b 40 04             	mov    0x4(%eax),%eax
80105358:	85 c0                	test   %eax,%eax
8010535a:	75 0c                	jne    80105368 <userinit+0x3e>
    panic("userinit: out of memory?");
8010535c:	c7 04 24 c8 98 10 80 	movl   $0x801098c8,(%esp)
80105363:	e8 d5 b1 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80105368:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010536d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105370:	8b 40 04             	mov    0x4(%eax),%eax
80105373:	89 54 24 08          	mov    %edx,0x8(%esp)
80105377:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
8010537e:	80 
8010537f:	89 04 24             	mov    %eax,(%esp)
80105382:	e8 ae 3b 00 00       	call   80108f35 <inituvm>
  p->sz = PGSIZE;
80105387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010538a:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80105390:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105393:	8b 40 18             	mov    0x18(%eax),%eax
80105396:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010539d:	00 
8010539e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801053a5:	00 
801053a6:	89 04 24             	mov    %eax,(%esp)
801053a9:	e8 48 0c 00 00       	call   80105ff6 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801053ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053b1:	8b 40 18             	mov    0x18(%eax),%eax
801053b4:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801053ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053bd:	8b 40 18             	mov    0x18(%eax),%eax
801053c0:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801053c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053c9:	8b 40 18             	mov    0x18(%eax),%eax
801053cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053cf:	8b 52 18             	mov    0x18(%edx),%edx
801053d2:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801053d6:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801053da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053dd:	8b 40 18             	mov    0x18(%eax),%eax
801053e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801053e3:	8b 52 18             	mov    0x18(%edx),%edx
801053e6:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801053ea:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801053ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053f1:	8b 40 18             	mov    0x18(%eax),%eax
801053f4:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801053fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801053fe:	8b 40 18             	mov    0x18(%eax),%eax
80105401:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80105408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010540b:	8b 40 18             	mov    0x18(%eax),%eax
8010540e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80105415:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105418:	83 c0 6c             	add    $0x6c,%eax
8010541b:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105422:	00 
80105423:	c7 44 24 04 e1 98 10 	movl   $0x801098e1,0x4(%esp)
8010542a:	80 
8010542b:	89 04 24             	mov    %eax,(%esp)
8010542e:	e8 f3 0d 00 00       	call   80106226 <safestrcpy>
  p->cwd = namei("/");
80105433:	c7 04 24 ea 98 10 80 	movl   $0x801098ea,(%esp)
8010543a:	e8 bc de ff ff       	call   801032fb <namei>
8010543f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105442:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
80105445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105448:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
8010544f:	c9                   	leave  
80105450:	c3                   	ret    

80105451 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80105451:	55                   	push   %ebp
80105452:	89 e5                	mov    %esp,%ebp
80105454:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80105457:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010545d:	8b 00                	mov    (%eax),%eax
8010545f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80105462:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80105466:	7e 34                	jle    8010549c <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80105468:	8b 45 08             	mov    0x8(%ebp),%eax
8010546b:	89 c2                	mov    %eax,%edx
8010546d:	03 55 f4             	add    -0xc(%ebp),%edx
80105470:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105476:	8b 40 04             	mov    0x4(%eax),%eax
80105479:	89 54 24 08          	mov    %edx,0x8(%esp)
8010547d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105480:	89 54 24 04          	mov    %edx,0x4(%esp)
80105484:	89 04 24             	mov    %eax,(%esp)
80105487:	e8 23 3c 00 00       	call   801090af <allocuvm>
8010548c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010548f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105493:	75 41                	jne    801054d6 <growproc+0x85>
      return -1;
80105495:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010549a:	eb 58                	jmp    801054f4 <growproc+0xa3>
  } else if(n < 0){
8010549c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801054a0:	79 34                	jns    801054d6 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801054a2:	8b 45 08             	mov    0x8(%ebp),%eax
801054a5:	89 c2                	mov    %eax,%edx
801054a7:	03 55 f4             	add    -0xc(%ebp),%edx
801054aa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054b0:	8b 40 04             	mov    0x4(%eax),%eax
801054b3:	89 54 24 08          	mov    %edx,0x8(%esp)
801054b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801054be:	89 04 24             	mov    %eax,(%esp)
801054c1:	e8 c3 3c 00 00       	call   80109189 <deallocuvm>
801054c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801054cd:	75 07                	jne    801054d6 <growproc+0x85>
      return -1;
801054cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054d4:	eb 1e                	jmp    801054f4 <growproc+0xa3>
  }
  proc->sz = sz;
801054d6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054df:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
801054e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054e7:	89 04 24             	mov    %eax,(%esp)
801054ea:	e8 df 38 00 00       	call   80108dce <switchuvm>
  return 0;
801054ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
801054f4:	c9                   	leave  
801054f5:	c3                   	ret    

801054f6 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801054f6:	55                   	push   %ebp
801054f7:	89 e5                	mov    %esp,%ebp
801054f9:	57                   	push   %edi
801054fa:	56                   	push   %esi
801054fb:	53                   	push   %ebx
801054fc:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801054ff:	e8 27 fd ff ff       	call   8010522b <allocproc>
80105504:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105507:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010550b:	75 0a                	jne    80105517 <fork+0x21>
    return -1;
8010550d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105512:	e9 3a 01 00 00       	jmp    80105651 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80105517:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010551d:	8b 10                	mov    (%eax),%edx
8010551f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105525:	8b 40 04             	mov    0x4(%eax),%eax
80105528:	89 54 24 04          	mov    %edx,0x4(%esp)
8010552c:	89 04 24             	mov    %eax,(%esp)
8010552f:	e8 e5 3d 00 00       	call   80109319 <copyuvm>
80105534:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105537:	89 42 04             	mov    %eax,0x4(%edx)
8010553a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010553d:	8b 40 04             	mov    0x4(%eax),%eax
80105540:	85 c0                	test   %eax,%eax
80105542:	75 2c                	jne    80105570 <fork+0x7a>
    kfree(np->kstack);
80105544:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105547:	8b 40 08             	mov    0x8(%eax),%eax
8010554a:	89 04 24             	mov    %eax,(%esp)
8010554d:	e8 18 e7 ff ff       	call   80103c6a <kfree>
    np->kstack = 0;
80105552:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105555:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010555c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010555f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80105566:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010556b:	e9 e1 00 00 00       	jmp    80105651 <fork+0x15b>
  }
  np->sz = proc->sz;
80105570:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105576:	8b 10                	mov    (%eax),%edx
80105578:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010557b:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010557d:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105584:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105587:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010558a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010558d:	8b 50 18             	mov    0x18(%eax),%edx
80105590:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105596:	8b 40 18             	mov    0x18(%eax),%eax
80105599:	89 c3                	mov    %eax,%ebx
8010559b:	b8 13 00 00 00       	mov    $0x13,%eax
801055a0:	89 d7                	mov    %edx,%edi
801055a2:	89 de                	mov    %ebx,%esi
801055a4:	89 c1                	mov    %eax,%ecx
801055a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
801055a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801055ab:	8b 40 18             	mov    0x18(%eax),%eax
801055ae:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
801055b5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801055bc:	eb 3d                	jmp    801055fb <fork+0x105>
    if(proc->ofile[i])
801055be:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055c4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801055c7:	83 c2 08             	add    $0x8,%edx
801055ca:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801055ce:	85 c0                	test   %eax,%eax
801055d0:	74 25                	je     801055f7 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
801055d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055d8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801055db:	83 c2 08             	add    $0x8,%edx
801055de:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801055e2:	89 04 24             	mov    %eax,(%esp)
801055e5:	e8 92 b9 ff ff       	call   80100f7c <filedup>
801055ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
801055ed:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801055f0:	83 c1 08             	add    $0x8,%ecx
801055f3:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801055f7:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801055fb:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801055ff:	7e bd                	jle    801055be <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80105601:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105607:	8b 40 68             	mov    0x68(%eax),%eax
8010560a:	89 04 24             	mov    %eax,(%esp)
8010560d:	e8 2c d0 ff ff       	call   8010263e <idup>
80105612:	8b 55 e0             	mov    -0x20(%ebp),%edx
80105615:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80105618:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010561b:	8b 40 10             	mov    0x10(%eax),%eax
8010561e:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80105621:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105624:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
8010562b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105631:	8d 50 6c             	lea    0x6c(%eax),%edx
80105634:	8b 45 e0             	mov    -0x20(%ebp),%eax
80105637:	83 c0 6c             	add    $0x6c,%eax
8010563a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105641:	00 
80105642:	89 54 24 04          	mov    %edx,0x4(%esp)
80105646:	89 04 24             	mov    %eax,(%esp)
80105649:	e8 d8 0b 00 00       	call   80106226 <safestrcpy>
  return pid;
8010564e:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80105651:	83 c4 2c             	add    $0x2c,%esp
80105654:	5b                   	pop    %ebx
80105655:	5e                   	pop    %esi
80105656:	5f                   	pop    %edi
80105657:	5d                   	pop    %ebp
80105658:	c3                   	ret    

80105659 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80105659:	55                   	push   %ebp
8010565a:	89 e5                	mov    %esp,%ebp
8010565c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
8010565f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105666:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010566b:	39 c2                	cmp    %eax,%edx
8010566d:	75 0c                	jne    8010567b <exit+0x22>
    panic("init exiting");
8010566f:	c7 04 24 ec 98 10 80 	movl   $0x801098ec,(%esp)
80105676:	e8 c2 ae ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010567b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80105682:	eb 44                	jmp    801056c8 <exit+0x6f>
    if(proc->ofile[fd]){
80105684:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010568a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010568d:	83 c2 08             	add    $0x8,%edx
80105690:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105694:	85 c0                	test   %eax,%eax
80105696:	74 2c                	je     801056c4 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80105698:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010569e:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056a1:	83 c2 08             	add    $0x8,%edx
801056a4:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801056a8:	89 04 24             	mov    %eax,(%esp)
801056ab:	e8 14 b9 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
801056b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056b6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056b9:	83 c2 08             	add    $0x8,%edx
801056bc:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801056c3:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801056c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801056c8:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
801056cc:	7e b6                	jle    80105684 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
801056ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056d4:	8b 40 68             	mov    0x68(%eax),%eax
801056d7:	89 04 24             	mov    %eax,(%esp)
801056da:	e8 44 d1 ff ff       	call   80102823 <iput>
  proc->cwd = 0;
801056df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056e5:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801056ec:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801056f3:	e8 af 06 00 00       	call   80105da7 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801056f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056fe:	8b 40 14             	mov    0x14(%eax),%eax
80105701:	89 04 24             	mov    %eax,(%esp)
80105704:	e8 5b 04 00 00       	call   80105b64 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105709:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105710:	eb 38                	jmp    8010574a <exit+0xf1>
    if(p->parent == proc){
80105712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105715:	8b 50 14             	mov    0x14(%eax),%edx
80105718:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010571e:	39 c2                	cmp    %eax,%edx
80105720:	75 24                	jne    80105746 <exit+0xed>
      p->parent = initproc;
80105722:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
80105728:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010572b:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
8010572e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105731:	8b 40 0c             	mov    0xc(%eax),%eax
80105734:	83 f8 05             	cmp    $0x5,%eax
80105737:	75 0d                	jne    80105746 <exit+0xed>
        wakeup1(initproc);
80105739:	a1 68 c6 10 80       	mov    0x8010c668,%eax
8010573e:	89 04 24             	mov    %eax,(%esp)
80105741:	e8 1e 04 00 00       	call   80105b64 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105746:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010574a:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105751:	72 bf                	jb     80105712 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80105753:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105759:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80105760:	e8 54 02 00 00       	call   801059b9 <sched>
  panic("zombie exit");
80105765:	c7 04 24 f9 98 10 80 	movl   $0x801098f9,(%esp)
8010576c:	e8 cc ad ff ff       	call   8010053d <panic>

80105771 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80105771:	55                   	push   %ebp
80105772:	89 e5                	mov    %esp,%ebp
80105774:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80105777:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
8010577e:	e8 24 06 00 00       	call   80105da7 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80105783:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010578a:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105791:	e9 9a 00 00 00       	jmp    80105830 <wait+0xbf>
      if(p->parent != proc)
80105796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105799:	8b 50 14             	mov    0x14(%eax),%edx
8010579c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057a2:	39 c2                	cmp    %eax,%edx
801057a4:	0f 85 81 00 00 00    	jne    8010582b <wait+0xba>
        continue;
      havekids = 1;
801057aa:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
801057b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b4:	8b 40 0c             	mov    0xc(%eax),%eax
801057b7:	83 f8 05             	cmp    $0x5,%eax
801057ba:	75 70                	jne    8010582c <wait+0xbb>
        // Found one.
        pid = p->pid;
801057bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057bf:	8b 40 10             	mov    0x10(%eax),%eax
801057c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
801057c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c8:	8b 40 08             	mov    0x8(%eax),%eax
801057cb:	89 04 24             	mov    %eax,(%esp)
801057ce:	e8 97 e4 ff ff       	call   80103c6a <kfree>
        p->kstack = 0;
801057d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057d6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801057dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057e0:	8b 40 04             	mov    0x4(%eax),%eax
801057e3:	89 04 24             	mov    %eax,(%esp)
801057e6:	e8 5a 3a 00 00       	call   80109245 <freevm>
        p->state = UNUSED;
801057eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ee:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801057f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057f8:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801057ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105802:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80105809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010580c:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80105810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105813:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010581a:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105821:	e8 e3 05 00 00       	call   80105e09 <release>
        return pid;
80105826:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105829:	eb 53                	jmp    8010587e <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
8010582b:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010582c:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105830:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105837:	0f 82 59 ff ff ff    	jb     80105796 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
8010583d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105841:	74 0d                	je     80105850 <wait+0xdf>
80105843:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105849:	8b 40 24             	mov    0x24(%eax),%eax
8010584c:	85 c0                	test   %eax,%eax
8010584e:	74 13                	je     80105863 <wait+0xf2>
      release(&ptable.lock);
80105850:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105857:	e8 ad 05 00 00       	call   80105e09 <release>
      return -1;
8010585c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105861:	eb 1b                	jmp    8010587e <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80105863:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105869:	c7 44 24 04 60 0f 11 	movl   $0x80110f60,0x4(%esp)
80105870:	80 
80105871:	89 04 24             	mov    %eax,(%esp)
80105874:	e8 50 02 00 00       	call   80105ac9 <sleep>
  }
80105879:	e9 05 ff ff ff       	jmp    80105783 <wait+0x12>
}
8010587e:	c9                   	leave  
8010587f:	c3                   	ret    

80105880 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80105880:	55                   	push   %ebp
80105881:	89 e5                	mov    %esp,%ebp
80105883:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80105886:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010588c:	8b 40 18             	mov    0x18(%eax),%eax
8010588f:	8b 40 44             	mov    0x44(%eax),%eax
80105892:	89 c2                	mov    %eax,%edx
80105894:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010589a:	8b 40 04             	mov    0x4(%eax),%eax
8010589d:	89 54 24 04          	mov    %edx,0x4(%esp)
801058a1:	89 04 24             	mov    %eax,(%esp)
801058a4:	e8 81 3b 00 00       	call   8010942a <uva2ka>
801058a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
801058ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058b2:	8b 40 18             	mov    0x18(%eax),%eax
801058b5:	8b 40 44             	mov    0x44(%eax),%eax
801058b8:	25 ff 0f 00 00       	and    $0xfff,%eax
801058bd:	85 c0                	test   %eax,%eax
801058bf:	75 0c                	jne    801058cd <register_handler+0x4d>
    panic("esp_offset == 0");
801058c1:	c7 04 24 05 99 10 80 	movl   $0x80109905,(%esp)
801058c8:	e8 70 ac ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
801058cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058d3:	8b 40 18             	mov    0x18(%eax),%eax
801058d6:	8b 40 44             	mov    0x44(%eax),%eax
801058d9:	83 e8 04             	sub    $0x4,%eax
801058dc:	25 ff 0f 00 00       	and    $0xfff,%eax
801058e1:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
801058e4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801058eb:	8b 52 18             	mov    0x18(%edx),%edx
801058ee:	8b 52 38             	mov    0x38(%edx),%edx
801058f1:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801058f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058f9:	8b 40 18             	mov    0x18(%eax),%eax
801058fc:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105903:	8b 52 18             	mov    0x18(%edx),%edx
80105906:	8b 52 44             	mov    0x44(%edx),%edx
80105909:	83 ea 04             	sub    $0x4,%edx
8010590c:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
8010590f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105915:	8b 40 18             	mov    0x18(%eax),%eax
80105918:	8b 55 08             	mov    0x8(%ebp),%edx
8010591b:	89 50 38             	mov    %edx,0x38(%eax)
}
8010591e:	c9                   	leave  
8010591f:	c3                   	ret    

80105920 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80105920:	55                   	push   %ebp
80105921:	89 e5                	mov    %esp,%ebp
80105923:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80105926:	e8 de f8 ff ff       	call   80105209 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010592b:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105932:	e8 70 04 00 00       	call   80105da7 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105937:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
8010593e:	eb 5f                	jmp    8010599f <scheduler+0x7f>
      if(p->state != RUNNABLE)
80105940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105943:	8b 40 0c             	mov    0xc(%eax),%eax
80105946:	83 f8 03             	cmp    $0x3,%eax
80105949:	75 4f                	jne    8010599a <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
8010594b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010594e:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80105954:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105957:	89 04 24             	mov    %eax,(%esp)
8010595a:	e8 6f 34 00 00       	call   80108dce <switchuvm>
      p->state = RUNNING;
8010595f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105962:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80105969:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010596f:	8b 40 1c             	mov    0x1c(%eax),%eax
80105972:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105979:	83 c2 04             	add    $0x4,%edx
8010597c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105980:	89 14 24             	mov    %edx,(%esp)
80105983:	e8 14 09 00 00       	call   8010629c <swtch>
      switchkvm();
80105988:	e8 24 34 00 00       	call   80108db1 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
8010598d:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80105994:	00 00 00 00 
80105998:	eb 01                	jmp    8010599b <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010599a:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010599b:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010599f:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
801059a6:	72 98                	jb     80105940 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
801059a8:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801059af:	e8 55 04 00 00       	call   80105e09 <release>

  }
801059b4:	e9 6d ff ff ff       	jmp    80105926 <scheduler+0x6>

801059b9 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
801059b9:	55                   	push   %ebp
801059ba:	89 e5                	mov    %esp,%ebp
801059bc:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
801059bf:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
801059c6:	e8 fa 04 00 00       	call   80105ec5 <holding>
801059cb:	85 c0                	test   %eax,%eax
801059cd:	75 0c                	jne    801059db <sched+0x22>
    panic("sched ptable.lock");
801059cf:	c7 04 24 15 99 10 80 	movl   $0x80109915,(%esp)
801059d6:	e8 62 ab ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
801059db:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801059e1:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801059e7:	83 f8 01             	cmp    $0x1,%eax
801059ea:	74 0c                	je     801059f8 <sched+0x3f>
    panic("sched locks");
801059ec:	c7 04 24 27 99 10 80 	movl   $0x80109927,(%esp)
801059f3:	e8 45 ab ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801059f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059fe:	8b 40 0c             	mov    0xc(%eax),%eax
80105a01:	83 f8 04             	cmp    $0x4,%eax
80105a04:	75 0c                	jne    80105a12 <sched+0x59>
    panic("sched running");
80105a06:	c7 04 24 33 99 10 80 	movl   $0x80109933,(%esp)
80105a0d:	e8 2b ab ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80105a12:	e8 dd f7 ff ff       	call   801051f4 <readeflags>
80105a17:	25 00 02 00 00       	and    $0x200,%eax
80105a1c:	85 c0                	test   %eax,%eax
80105a1e:	74 0c                	je     80105a2c <sched+0x73>
    panic("sched interruptible");
80105a20:	c7 04 24 41 99 10 80 	movl   $0x80109941,(%esp)
80105a27:	e8 11 ab ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80105a2c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a32:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105a38:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80105a3b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a41:	8b 40 04             	mov    0x4(%eax),%eax
80105a44:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80105a4b:	83 c2 1c             	add    $0x1c,%edx
80105a4e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a52:	89 14 24             	mov    %edx,(%esp)
80105a55:	e8 42 08 00 00       	call   8010629c <swtch>
  cpu->intena = intena;
80105a5a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105a60:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105a63:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105a69:	c9                   	leave  
80105a6a:	c3                   	ret    

80105a6b <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80105a6b:	55                   	push   %ebp
80105a6c:	89 e5                	mov    %esp,%ebp
80105a6e:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80105a71:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a78:	e8 2a 03 00 00       	call   80105da7 <acquire>
  proc->state = RUNNABLE;
80105a7d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105a83:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80105a8a:	e8 2a ff ff ff       	call   801059b9 <sched>
  release(&ptable.lock);
80105a8f:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105a96:	e8 6e 03 00 00       	call   80105e09 <release>
}
80105a9b:	c9                   	leave  
80105a9c:	c3                   	ret    

80105a9d <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80105a9d:	55                   	push   %ebp
80105a9e:	89 e5                	mov    %esp,%ebp
80105aa0:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80105aa3:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105aaa:	e8 5a 03 00 00       	call   80105e09 <release>

  if (first) {
80105aaf:	a1 20 c0 10 80       	mov    0x8010c020,%eax
80105ab4:	85 c0                	test   %eax,%eax
80105ab6:	74 0f                	je     80105ac7 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80105ab8:	c7 05 20 c0 10 80 00 	movl   $0x0,0x8010c020
80105abf:	00 00 00 
    initlog();
80105ac2:	e8 4d e7 ff ff       	call   80104214 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80105ac7:	c9                   	leave  
80105ac8:	c3                   	ret    

80105ac9 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80105ac9:	55                   	push   %ebp
80105aca:	89 e5                	mov    %esp,%ebp
80105acc:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80105acf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105ad5:	85 c0                	test   %eax,%eax
80105ad7:	75 0c                	jne    80105ae5 <sleep+0x1c>
    panic("sleep");
80105ad9:	c7 04 24 55 99 10 80 	movl   $0x80109955,(%esp)
80105ae0:	e8 58 aa ff ff       	call   8010053d <panic>

  if(lk == 0)
80105ae5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105ae9:	75 0c                	jne    80105af7 <sleep+0x2e>
    panic("sleep without lk");
80105aeb:	c7 04 24 5b 99 10 80 	movl   $0x8010995b,(%esp)
80105af2:	e8 46 aa ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80105af7:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
80105afe:	74 17                	je     80105b17 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80105b00:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105b07:	e8 9b 02 00 00       	call   80105da7 <acquire>
    release(lk);
80105b0c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b0f:	89 04 24             	mov    %eax,(%esp)
80105b12:	e8 f2 02 00 00       	call   80105e09 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80105b17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b1d:	8b 55 08             	mov    0x8(%ebp),%edx
80105b20:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80105b23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b29:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80105b30:	e8 84 fe ff ff       	call   801059b9 <sched>

  // Tidy up.
  proc->chan = 0;
80105b35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b3b:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80105b42:	81 7d 0c 60 0f 11 80 	cmpl   $0x80110f60,0xc(%ebp)
80105b49:	74 17                	je     80105b62 <sleep+0x99>
    release(&ptable.lock);
80105b4b:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105b52:	e8 b2 02 00 00       	call   80105e09 <release>
    acquire(lk);
80105b57:	8b 45 0c             	mov    0xc(%ebp),%eax
80105b5a:	89 04 24             	mov    %eax,(%esp)
80105b5d:	e8 45 02 00 00       	call   80105da7 <acquire>
  }
}
80105b62:	c9                   	leave  
80105b63:	c3                   	ret    

80105b64 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80105b64:	55                   	push   %ebp
80105b65:	89 e5                	mov    %esp,%ebp
80105b67:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105b6a:	c7 45 fc 94 0f 11 80 	movl   $0x80110f94,-0x4(%ebp)
80105b71:	eb 24                	jmp    80105b97 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80105b73:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b76:	8b 40 0c             	mov    0xc(%eax),%eax
80105b79:	83 f8 02             	cmp    $0x2,%eax
80105b7c:	75 15                	jne    80105b93 <wakeup1+0x2f>
80105b7e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b81:	8b 40 20             	mov    0x20(%eax),%eax
80105b84:	3b 45 08             	cmp    0x8(%ebp),%eax
80105b87:	75 0a                	jne    80105b93 <wakeup1+0x2f>
      p->state = RUNNABLE;
80105b89:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105b8c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105b93:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80105b97:	81 7d fc 94 2e 11 80 	cmpl   $0x80112e94,-0x4(%ebp)
80105b9e:	72 d3                	jb     80105b73 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105ba0:	c9                   	leave  
80105ba1:	c3                   	ret    

80105ba2 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105ba2:	55                   	push   %ebp
80105ba3:	89 e5                	mov    %esp,%ebp
80105ba5:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80105ba8:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105baf:	e8 f3 01 00 00       	call   80105da7 <acquire>
  wakeup1(chan);
80105bb4:	8b 45 08             	mov    0x8(%ebp),%eax
80105bb7:	89 04 24             	mov    %eax,(%esp)
80105bba:	e8 a5 ff ff ff       	call   80105b64 <wakeup1>
  release(&ptable.lock);
80105bbf:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105bc6:	e8 3e 02 00 00       	call   80105e09 <release>
}
80105bcb:	c9                   	leave  
80105bcc:	c3                   	ret    

80105bcd <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105bcd:	55                   	push   %ebp
80105bce:	89 e5                	mov    %esp,%ebp
80105bd0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105bd3:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105bda:	e8 c8 01 00 00       	call   80105da7 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105bdf:	c7 45 f4 94 0f 11 80 	movl   $0x80110f94,-0xc(%ebp)
80105be6:	eb 41                	jmp    80105c29 <kill+0x5c>
    if(p->pid == pid){
80105be8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105beb:	8b 40 10             	mov    0x10(%eax),%eax
80105bee:	3b 45 08             	cmp    0x8(%ebp),%eax
80105bf1:	75 32                	jne    80105c25 <kill+0x58>
      p->killed = 1;
80105bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bf6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c00:	8b 40 0c             	mov    0xc(%eax),%eax
80105c03:	83 f8 02             	cmp    $0x2,%eax
80105c06:	75 0a                	jne    80105c12 <kill+0x45>
        p->state = RUNNABLE;
80105c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c0b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105c12:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c19:	e8 eb 01 00 00       	call   80105e09 <release>
      return 0;
80105c1e:	b8 00 00 00 00       	mov    $0x0,%eax
80105c23:	eb 1e                	jmp    80105c43 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105c25:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80105c29:	81 7d f4 94 2e 11 80 	cmpl   $0x80112e94,-0xc(%ebp)
80105c30:	72 b6                	jb     80105be8 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80105c32:	c7 04 24 60 0f 11 80 	movl   $0x80110f60,(%esp)
80105c39:	e8 cb 01 00 00       	call   80105e09 <release>
  return -1;
80105c3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105c43:	c9                   	leave  
80105c44:	c3                   	ret    

80105c45 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80105c45:	55                   	push   %ebp
80105c46:	89 e5                	mov    %esp,%ebp
80105c48:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105c4b:	c7 45 f0 94 0f 11 80 	movl   $0x80110f94,-0x10(%ebp)
80105c52:	e9 d8 00 00 00       	jmp    80105d2f <procdump+0xea>
    if(p->state == UNUSED)
80105c57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c5a:	8b 40 0c             	mov    0xc(%eax),%eax
80105c5d:	85 c0                	test   %eax,%eax
80105c5f:	0f 84 c5 00 00 00    	je     80105d2a <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80105c65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c68:	8b 40 0c             	mov    0xc(%eax),%eax
80105c6b:	83 f8 05             	cmp    $0x5,%eax
80105c6e:	77 23                	ja     80105c93 <procdump+0x4e>
80105c70:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c73:	8b 40 0c             	mov    0xc(%eax),%eax
80105c76:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105c7d:	85 c0                	test   %eax,%eax
80105c7f:	74 12                	je     80105c93 <procdump+0x4e>
      state = states[p->state];
80105c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c84:	8b 40 0c             	mov    0xc(%eax),%eax
80105c87:	8b 04 85 08 c0 10 80 	mov    -0x7fef3ff8(,%eax,4),%eax
80105c8e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105c91:	eb 07                	jmp    80105c9a <procdump+0x55>
    else
      state = "???";
80105c93:	c7 45 ec 6c 99 10 80 	movl   $0x8010996c,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80105c9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c9d:	8d 50 6c             	lea    0x6c(%eax),%edx
80105ca0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ca3:	8b 40 10             	mov    0x10(%eax),%eax
80105ca6:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105caa:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105cad:	89 54 24 08          	mov    %edx,0x8(%esp)
80105cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cb5:	c7 04 24 70 99 10 80 	movl   $0x80109970,(%esp)
80105cbc:	e8 e0 a6 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105cc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc4:	8b 40 0c             	mov    0xc(%eax),%eax
80105cc7:	83 f8 02             	cmp    $0x2,%eax
80105cca:	75 50                	jne    80105d1c <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105ccc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ccf:	8b 40 1c             	mov    0x1c(%eax),%eax
80105cd2:	8b 40 0c             	mov    0xc(%eax),%eax
80105cd5:	83 c0 08             	add    $0x8,%eax
80105cd8:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80105cdb:	89 54 24 04          	mov    %edx,0x4(%esp)
80105cdf:	89 04 24             	mov    %eax,(%esp)
80105ce2:	e8 71 01 00 00       	call   80105e58 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80105ce7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105cee:	eb 1b                	jmp    80105d0b <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105cf0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf3:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105cf7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cfb:	c7 04 24 79 99 10 80 	movl   $0x80109979,(%esp)
80105d02:	e8 9a a6 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80105d07:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80105d0b:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105d0f:	7f 0b                	jg     80105d1c <procdump+0xd7>
80105d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d14:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80105d18:	85 c0                	test   %eax,%eax
80105d1a:	75 d4                	jne    80105cf0 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105d1c:	c7 04 24 7d 99 10 80 	movl   $0x8010997d,(%esp)
80105d23:	e8 79 a6 ff ff       	call   801003a1 <cprintf>
80105d28:	eb 01                	jmp    80105d2b <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80105d2a:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105d2b:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80105d2f:	81 7d f0 94 2e 11 80 	cmpl   $0x80112e94,-0x10(%ebp)
80105d36:	0f 82 1b ff ff ff    	jb     80105c57 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80105d3c:	c9                   	leave  
80105d3d:	c3                   	ret    
	...

80105d40 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105d40:	55                   	push   %ebp
80105d41:	89 e5                	mov    %esp,%ebp
80105d43:	53                   	push   %ebx
80105d44:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105d47:	9c                   	pushf  
80105d48:	5b                   	pop    %ebx
80105d49:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80105d4c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105d4f:	83 c4 10             	add    $0x10,%esp
80105d52:	5b                   	pop    %ebx
80105d53:	5d                   	pop    %ebp
80105d54:	c3                   	ret    

80105d55 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105d55:	55                   	push   %ebp
80105d56:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105d58:	fa                   	cli    
}
80105d59:	5d                   	pop    %ebp
80105d5a:	c3                   	ret    

80105d5b <sti>:

static inline void
sti(void)
{
80105d5b:	55                   	push   %ebp
80105d5c:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105d5e:	fb                   	sti    
}
80105d5f:	5d                   	pop    %ebp
80105d60:	c3                   	ret    

80105d61 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105d61:	55                   	push   %ebp
80105d62:	89 e5                	mov    %esp,%ebp
80105d64:	53                   	push   %ebx
80105d65:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80105d68:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105d6b:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80105d6e:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105d71:	89 c3                	mov    %eax,%ebx
80105d73:	89 d8                	mov    %ebx,%eax
80105d75:	f0 87 02             	lock xchg %eax,(%edx)
80105d78:	89 c3                	mov    %eax,%ebx
80105d7a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105d7d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80105d80:	83 c4 10             	add    $0x10,%esp
80105d83:	5b                   	pop    %ebx
80105d84:	5d                   	pop    %ebp
80105d85:	c3                   	ret    

80105d86 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105d86:	55                   	push   %ebp
80105d87:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105d89:	8b 45 08             	mov    0x8(%ebp),%eax
80105d8c:	8b 55 0c             	mov    0xc(%ebp),%edx
80105d8f:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105d92:	8b 45 08             	mov    0x8(%ebp),%eax
80105d95:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105d9b:	8b 45 08             	mov    0x8(%ebp),%eax
80105d9e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105da5:	5d                   	pop    %ebp
80105da6:	c3                   	ret    

80105da7 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105da7:	55                   	push   %ebp
80105da8:	89 e5                	mov    %esp,%ebp
80105daa:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105dad:	e8 3d 01 00 00       	call   80105eef <pushcli>
  if(holding(lk))
80105db2:	8b 45 08             	mov    0x8(%ebp),%eax
80105db5:	89 04 24             	mov    %eax,(%esp)
80105db8:	e8 08 01 00 00       	call   80105ec5 <holding>
80105dbd:	85 c0                	test   %eax,%eax
80105dbf:	74 0c                	je     80105dcd <acquire+0x26>
    panic("acquire");
80105dc1:	c7 04 24 a9 99 10 80 	movl   $0x801099a9,(%esp)
80105dc8:	e8 70 a7 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105dcd:	90                   	nop
80105dce:	8b 45 08             	mov    0x8(%ebp),%eax
80105dd1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105dd8:	00 
80105dd9:	89 04 24             	mov    %eax,(%esp)
80105ddc:	e8 80 ff ff ff       	call   80105d61 <xchg>
80105de1:	85 c0                	test   %eax,%eax
80105de3:	75 e9                	jne    80105dce <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105de5:	8b 45 08             	mov    0x8(%ebp),%eax
80105de8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105def:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105df2:	8b 45 08             	mov    0x8(%ebp),%eax
80105df5:	83 c0 0c             	add    $0xc,%eax
80105df8:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dfc:	8d 45 08             	lea    0x8(%ebp),%eax
80105dff:	89 04 24             	mov    %eax,(%esp)
80105e02:	e8 51 00 00 00       	call   80105e58 <getcallerpcs>
}
80105e07:	c9                   	leave  
80105e08:	c3                   	ret    

80105e09 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105e09:	55                   	push   %ebp
80105e0a:	89 e5                	mov    %esp,%ebp
80105e0c:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e12:	89 04 24             	mov    %eax,(%esp)
80105e15:	e8 ab 00 00 00       	call   80105ec5 <holding>
80105e1a:	85 c0                	test   %eax,%eax
80105e1c:	75 0c                	jne    80105e2a <release+0x21>
    panic("release");
80105e1e:	c7 04 24 b1 99 10 80 	movl   $0x801099b1,(%esp)
80105e25:	e8 13 a7 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80105e2a:	8b 45 08             	mov    0x8(%ebp),%eax
80105e2d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105e34:	8b 45 08             	mov    0x8(%ebp),%eax
80105e37:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105e3e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e41:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105e48:	00 
80105e49:	89 04 24             	mov    %eax,(%esp)
80105e4c:	e8 10 ff ff ff       	call   80105d61 <xchg>

  popcli();
80105e51:	e8 e1 00 00 00       	call   80105f37 <popcli>
}
80105e56:	c9                   	leave  
80105e57:	c3                   	ret    

80105e58 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105e58:	55                   	push   %ebp
80105e59:	89 e5                	mov    %esp,%ebp
80105e5b:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105e5e:	8b 45 08             	mov    0x8(%ebp),%eax
80105e61:	83 e8 08             	sub    $0x8,%eax
80105e64:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105e67:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105e6e:	eb 32                	jmp    80105ea2 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105e70:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105e74:	74 47                	je     80105ebd <getcallerpcs+0x65>
80105e76:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105e7d:	76 3e                	jbe    80105ebd <getcallerpcs+0x65>
80105e7f:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105e83:	74 38                	je     80105ebd <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105e85:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105e88:	c1 e0 02             	shl    $0x2,%eax
80105e8b:	03 45 0c             	add    0xc(%ebp),%eax
80105e8e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e91:	8b 52 04             	mov    0x4(%edx),%edx
80105e94:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80105e96:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e99:	8b 00                	mov    (%eax),%eax
80105e9b:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105e9e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ea2:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105ea6:	7e c8                	jle    80105e70 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105ea8:	eb 13                	jmp    80105ebd <getcallerpcs+0x65>
    pcs[i] = 0;
80105eaa:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105ead:	c1 e0 02             	shl    $0x2,%eax
80105eb0:	03 45 0c             	add    0xc(%ebp),%eax
80105eb3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105eb9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105ebd:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105ec1:	7e e7                	jle    80105eaa <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105ec3:	c9                   	leave  
80105ec4:	c3                   	ret    

80105ec5 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105ec5:	55                   	push   %ebp
80105ec6:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105ec8:	8b 45 08             	mov    0x8(%ebp),%eax
80105ecb:	8b 00                	mov    (%eax),%eax
80105ecd:	85 c0                	test   %eax,%eax
80105ecf:	74 17                	je     80105ee8 <holding+0x23>
80105ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ed4:	8b 50 08             	mov    0x8(%eax),%edx
80105ed7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105edd:	39 c2                	cmp    %eax,%edx
80105edf:	75 07                	jne    80105ee8 <holding+0x23>
80105ee1:	b8 01 00 00 00       	mov    $0x1,%eax
80105ee6:	eb 05                	jmp    80105eed <holding+0x28>
80105ee8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105eed:	5d                   	pop    %ebp
80105eee:	c3                   	ret    

80105eef <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105eef:	55                   	push   %ebp
80105ef0:	89 e5                	mov    %esp,%ebp
80105ef2:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105ef5:	e8 46 fe ff ff       	call   80105d40 <readeflags>
80105efa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105efd:	e8 53 fe ff ff       	call   80105d55 <cli>
  if(cpu->ncli++ == 0)
80105f02:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f08:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105f0e:	85 d2                	test   %edx,%edx
80105f10:	0f 94 c1             	sete   %cl
80105f13:	83 c2 01             	add    $0x1,%edx
80105f16:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105f1c:	84 c9                	test   %cl,%cl
80105f1e:	74 15                	je     80105f35 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105f20:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f26:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105f29:	81 e2 00 02 00 00    	and    $0x200,%edx
80105f2f:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105f35:	c9                   	leave  
80105f36:	c3                   	ret    

80105f37 <popcli>:

void
popcli(void)
{
80105f37:	55                   	push   %ebp
80105f38:	89 e5                	mov    %esp,%ebp
80105f3a:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105f3d:	e8 fe fd ff ff       	call   80105d40 <readeflags>
80105f42:	25 00 02 00 00       	and    $0x200,%eax
80105f47:	85 c0                	test   %eax,%eax
80105f49:	74 0c                	je     80105f57 <popcli+0x20>
    panic("popcli - interruptible");
80105f4b:	c7 04 24 b9 99 10 80 	movl   $0x801099b9,(%esp)
80105f52:	e8 e6 a5 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80105f57:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f5d:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105f63:	83 ea 01             	sub    $0x1,%edx
80105f66:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105f6c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105f72:	85 c0                	test   %eax,%eax
80105f74:	79 0c                	jns    80105f82 <popcli+0x4b>
    panic("popcli");
80105f76:	c7 04 24 d0 99 10 80 	movl   $0x801099d0,(%esp)
80105f7d:	e8 bb a5 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105f82:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f88:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105f8e:	85 c0                	test   %eax,%eax
80105f90:	75 15                	jne    80105fa7 <popcli+0x70>
80105f92:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105f98:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105f9e:	85 c0                	test   %eax,%eax
80105fa0:	74 05                	je     80105fa7 <popcli+0x70>
    sti();
80105fa2:	e8 b4 fd ff ff       	call   80105d5b <sti>
}
80105fa7:	c9                   	leave  
80105fa8:	c3                   	ret    
80105fa9:	00 00                	add    %al,(%eax)
	...

80105fac <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105fac:	55                   	push   %ebp
80105fad:	89 e5                	mov    %esp,%ebp
80105faf:	57                   	push   %edi
80105fb0:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105fb1:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105fb4:	8b 55 10             	mov    0x10(%ebp),%edx
80105fb7:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fba:	89 cb                	mov    %ecx,%ebx
80105fbc:	89 df                	mov    %ebx,%edi
80105fbe:	89 d1                	mov    %edx,%ecx
80105fc0:	fc                   	cld    
80105fc1:	f3 aa                	rep stos %al,%es:(%edi)
80105fc3:	89 ca                	mov    %ecx,%edx
80105fc5:	89 fb                	mov    %edi,%ebx
80105fc7:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105fca:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105fcd:	5b                   	pop    %ebx
80105fce:	5f                   	pop    %edi
80105fcf:	5d                   	pop    %ebp
80105fd0:	c3                   	ret    

80105fd1 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105fd1:	55                   	push   %ebp
80105fd2:	89 e5                	mov    %esp,%ebp
80105fd4:	57                   	push   %edi
80105fd5:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105fd6:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105fd9:	8b 55 10             	mov    0x10(%ebp),%edx
80105fdc:	8b 45 0c             	mov    0xc(%ebp),%eax
80105fdf:	89 cb                	mov    %ecx,%ebx
80105fe1:	89 df                	mov    %ebx,%edi
80105fe3:	89 d1                	mov    %edx,%ecx
80105fe5:	fc                   	cld    
80105fe6:	f3 ab                	rep stos %eax,%es:(%edi)
80105fe8:	89 ca                	mov    %ecx,%edx
80105fea:	89 fb                	mov    %edi,%ebx
80105fec:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105fef:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105ff2:	5b                   	pop    %ebx
80105ff3:	5f                   	pop    %edi
80105ff4:	5d                   	pop    %ebp
80105ff5:	c3                   	ret    

80105ff6 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105ff6:	55                   	push   %ebp
80105ff7:	89 e5                	mov    %esp,%ebp
80105ff9:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80105fff:	83 e0 03             	and    $0x3,%eax
80106002:	85 c0                	test   %eax,%eax
80106004:	75 49                	jne    8010604f <memset+0x59>
80106006:	8b 45 10             	mov    0x10(%ebp),%eax
80106009:	83 e0 03             	and    $0x3,%eax
8010600c:	85 c0                	test   %eax,%eax
8010600e:	75 3f                	jne    8010604f <memset+0x59>
    c &= 0xFF;
80106010:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80106017:	8b 45 10             	mov    0x10(%ebp),%eax
8010601a:	c1 e8 02             	shr    $0x2,%eax
8010601d:	89 c2                	mov    %eax,%edx
8010601f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106022:	89 c1                	mov    %eax,%ecx
80106024:	c1 e1 18             	shl    $0x18,%ecx
80106027:	8b 45 0c             	mov    0xc(%ebp),%eax
8010602a:	c1 e0 10             	shl    $0x10,%eax
8010602d:	09 c1                	or     %eax,%ecx
8010602f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106032:	c1 e0 08             	shl    $0x8,%eax
80106035:	09 c8                	or     %ecx,%eax
80106037:	0b 45 0c             	or     0xc(%ebp),%eax
8010603a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010603e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106042:	8b 45 08             	mov    0x8(%ebp),%eax
80106045:	89 04 24             	mov    %eax,(%esp)
80106048:	e8 84 ff ff ff       	call   80105fd1 <stosl>
8010604d:	eb 19                	jmp    80106068 <memset+0x72>
  } else
    stosb(dst, c, n);
8010604f:	8b 45 10             	mov    0x10(%ebp),%eax
80106052:	89 44 24 08          	mov    %eax,0x8(%esp)
80106056:	8b 45 0c             	mov    0xc(%ebp),%eax
80106059:	89 44 24 04          	mov    %eax,0x4(%esp)
8010605d:	8b 45 08             	mov    0x8(%ebp),%eax
80106060:	89 04 24             	mov    %eax,(%esp)
80106063:	e8 44 ff ff ff       	call   80105fac <stosb>
  return dst;
80106068:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010606b:	c9                   	leave  
8010606c:	c3                   	ret    

8010606d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
8010606d:	55                   	push   %ebp
8010606e:	89 e5                	mov    %esp,%ebp
80106070:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80106073:	8b 45 08             	mov    0x8(%ebp),%eax
80106076:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80106079:	8b 45 0c             	mov    0xc(%ebp),%eax
8010607c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
8010607f:	eb 32                	jmp    801060b3 <memcmp+0x46>
    if(*s1 != *s2)
80106081:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106084:	0f b6 10             	movzbl (%eax),%edx
80106087:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010608a:	0f b6 00             	movzbl (%eax),%eax
8010608d:	38 c2                	cmp    %al,%dl
8010608f:	74 1a                	je     801060ab <memcmp+0x3e>
      return *s1 - *s2;
80106091:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106094:	0f b6 00             	movzbl (%eax),%eax
80106097:	0f b6 d0             	movzbl %al,%edx
8010609a:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010609d:	0f b6 00             	movzbl (%eax),%eax
801060a0:	0f b6 c0             	movzbl %al,%eax
801060a3:	89 d1                	mov    %edx,%ecx
801060a5:	29 c1                	sub    %eax,%ecx
801060a7:	89 c8                	mov    %ecx,%eax
801060a9:	eb 1c                	jmp    801060c7 <memcmp+0x5a>
    s1++, s2++;
801060ab:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801060af:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801060b3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801060b7:	0f 95 c0             	setne  %al
801060ba:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801060be:	84 c0                	test   %al,%al
801060c0:	75 bf                	jne    80106081 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
801060c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060c7:	c9                   	leave  
801060c8:	c3                   	ret    

801060c9 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801060c9:	55                   	push   %ebp
801060ca:	89 e5                	mov    %esp,%ebp
801060cc:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
801060cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801060d2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
801060d5:	8b 45 08             	mov    0x8(%ebp),%eax
801060d8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
801060db:	8b 45 fc             	mov    -0x4(%ebp),%eax
801060de:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801060e1:	73 54                	jae    80106137 <memmove+0x6e>
801060e3:	8b 45 10             	mov    0x10(%ebp),%eax
801060e6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801060e9:	01 d0                	add    %edx,%eax
801060eb:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801060ee:	76 47                	jbe    80106137 <memmove+0x6e>
    s += n;
801060f0:	8b 45 10             	mov    0x10(%ebp),%eax
801060f3:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801060f6:	8b 45 10             	mov    0x10(%ebp),%eax
801060f9:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801060fc:	eb 13                	jmp    80106111 <memmove+0x48>
      *--d = *--s;
801060fe:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80106102:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80106106:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106109:	0f b6 10             	movzbl (%eax),%edx
8010610c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010610f:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80106111:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106115:	0f 95 c0             	setne  %al
80106118:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010611c:	84 c0                	test   %al,%al
8010611e:	75 de                	jne    801060fe <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80106120:	eb 25                	jmp    80106147 <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80106122:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106125:	0f b6 10             	movzbl (%eax),%edx
80106128:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010612b:	88 10                	mov    %dl,(%eax)
8010612d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80106131:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106135:	eb 01                	jmp    80106138 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80106137:	90                   	nop
80106138:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010613c:	0f 95 c0             	setne  %al
8010613f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106143:	84 c0                	test   %al,%al
80106145:	75 db                	jne    80106122 <memmove+0x59>
      *d++ = *s++;

  return dst;
80106147:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010614a:	c9                   	leave  
8010614b:	c3                   	ret    

8010614c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010614c:	55                   	push   %ebp
8010614d:	89 e5                	mov    %esp,%ebp
8010614f:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80106152:	8b 45 10             	mov    0x10(%ebp),%eax
80106155:	89 44 24 08          	mov    %eax,0x8(%esp)
80106159:	8b 45 0c             	mov    0xc(%ebp),%eax
8010615c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106160:	8b 45 08             	mov    0x8(%ebp),%eax
80106163:	89 04 24             	mov    %eax,(%esp)
80106166:	e8 5e ff ff ff       	call   801060c9 <memmove>
}
8010616b:	c9                   	leave  
8010616c:	c3                   	ret    

8010616d <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010616d:	55                   	push   %ebp
8010616e:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80106170:	eb 0c                	jmp    8010617e <strncmp+0x11>
    n--, p++, q++;
80106172:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106176:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010617a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
8010617e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106182:	74 1a                	je     8010619e <strncmp+0x31>
80106184:	8b 45 08             	mov    0x8(%ebp),%eax
80106187:	0f b6 00             	movzbl (%eax),%eax
8010618a:	84 c0                	test   %al,%al
8010618c:	74 10                	je     8010619e <strncmp+0x31>
8010618e:	8b 45 08             	mov    0x8(%ebp),%eax
80106191:	0f b6 10             	movzbl (%eax),%edx
80106194:	8b 45 0c             	mov    0xc(%ebp),%eax
80106197:	0f b6 00             	movzbl (%eax),%eax
8010619a:	38 c2                	cmp    %al,%dl
8010619c:	74 d4                	je     80106172 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
8010619e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061a2:	75 07                	jne    801061ab <strncmp+0x3e>
    return 0;
801061a4:	b8 00 00 00 00       	mov    $0x0,%eax
801061a9:	eb 18                	jmp    801061c3 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
801061ab:	8b 45 08             	mov    0x8(%ebp),%eax
801061ae:	0f b6 00             	movzbl (%eax),%eax
801061b1:	0f b6 d0             	movzbl %al,%edx
801061b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801061b7:	0f b6 00             	movzbl (%eax),%eax
801061ba:	0f b6 c0             	movzbl %al,%eax
801061bd:	89 d1                	mov    %edx,%ecx
801061bf:	29 c1                	sub    %eax,%ecx
801061c1:	89 c8                	mov    %ecx,%eax
}
801061c3:	5d                   	pop    %ebp
801061c4:	c3                   	ret    

801061c5 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801061c5:	55                   	push   %ebp
801061c6:	89 e5                	mov    %esp,%ebp
801061c8:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801061cb:	8b 45 08             	mov    0x8(%ebp),%eax
801061ce:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
801061d1:	90                   	nop
801061d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801061d6:	0f 9f c0             	setg   %al
801061d9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801061dd:	84 c0                	test   %al,%al
801061df:	74 30                	je     80106211 <strncpy+0x4c>
801061e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801061e4:	0f b6 10             	movzbl (%eax),%edx
801061e7:	8b 45 08             	mov    0x8(%ebp),%eax
801061ea:	88 10                	mov    %dl,(%eax)
801061ec:	8b 45 08             	mov    0x8(%ebp),%eax
801061ef:	0f b6 00             	movzbl (%eax),%eax
801061f2:	84 c0                	test   %al,%al
801061f4:	0f 95 c0             	setne  %al
801061f7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801061fb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801061ff:	84 c0                	test   %al,%al
80106201:	75 cf                	jne    801061d2 <strncpy+0xd>
    ;
  while(n-- > 0)
80106203:	eb 0c                	jmp    80106211 <strncpy+0x4c>
    *s++ = 0;
80106205:	8b 45 08             	mov    0x8(%ebp),%eax
80106208:	c6 00 00             	movb   $0x0,(%eax)
8010620b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010620f:	eb 01                	jmp    80106212 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80106211:	90                   	nop
80106212:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106216:	0f 9f c0             	setg   %al
80106219:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010621d:	84 c0                	test   %al,%al
8010621f:	75 e4                	jne    80106205 <strncpy+0x40>
    *s++ = 0;
  return os;
80106221:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106224:	c9                   	leave  
80106225:	c3                   	ret    

80106226 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80106226:	55                   	push   %ebp
80106227:	89 e5                	mov    %esp,%ebp
80106229:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010622c:	8b 45 08             	mov    0x8(%ebp),%eax
8010622f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80106232:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106236:	7f 05                	jg     8010623d <safestrcpy+0x17>
    return os;
80106238:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010623b:	eb 35                	jmp    80106272 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
8010623d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80106241:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106245:	7e 22                	jle    80106269 <safestrcpy+0x43>
80106247:	8b 45 0c             	mov    0xc(%ebp),%eax
8010624a:	0f b6 10             	movzbl (%eax),%edx
8010624d:	8b 45 08             	mov    0x8(%ebp),%eax
80106250:	88 10                	mov    %dl,(%eax)
80106252:	8b 45 08             	mov    0x8(%ebp),%eax
80106255:	0f b6 00             	movzbl (%eax),%eax
80106258:	84 c0                	test   %al,%al
8010625a:	0f 95 c0             	setne  %al
8010625d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80106261:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80106265:	84 c0                	test   %al,%al
80106267:	75 d4                	jne    8010623d <safestrcpy+0x17>
    ;
  *s = 0;
80106269:	8b 45 08             	mov    0x8(%ebp),%eax
8010626c:	c6 00 00             	movb   $0x0,(%eax)
  return os;
8010626f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106272:	c9                   	leave  
80106273:	c3                   	ret    

80106274 <strlen>:

int
strlen(const char *s)
{
80106274:	55                   	push   %ebp
80106275:	89 e5                	mov    %esp,%ebp
80106277:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010627a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106281:	eb 04                	jmp    80106287 <strlen+0x13>
80106283:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106287:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010628a:	03 45 08             	add    0x8(%ebp),%eax
8010628d:	0f b6 00             	movzbl (%eax),%eax
80106290:	84 c0                	test   %al,%al
80106292:	75 ef                	jne    80106283 <strlen+0xf>
    ;
  return n;
80106294:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106297:	c9                   	leave  
80106298:	c3                   	ret    
80106299:	00 00                	add    %al,(%eax)
	...

8010629c <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010629c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801062a0:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801062a4:	55                   	push   %ebp
  pushl %ebx
801062a5:	53                   	push   %ebx
  pushl %esi
801062a6:	56                   	push   %esi
  pushl %edi
801062a7:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801062a8:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801062aa:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801062ac:	5f                   	pop    %edi
  popl %esi
801062ad:	5e                   	pop    %esi
  popl %ebx
801062ae:	5b                   	pop    %ebx
  popl %ebp
801062af:	5d                   	pop    %ebp
  ret
801062b0:	c3                   	ret    
801062b1:	00 00                	add    %al,(%eax)
	...

801062b4 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
801062b4:	55                   	push   %ebp
801062b5:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
801062b7:	8b 45 08             	mov    0x8(%ebp),%eax
801062ba:	8b 00                	mov    (%eax),%eax
801062bc:	3b 45 0c             	cmp    0xc(%ebp),%eax
801062bf:	76 0f                	jbe    801062d0 <fetchint+0x1c>
801062c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801062c4:	8d 50 04             	lea    0x4(%eax),%edx
801062c7:	8b 45 08             	mov    0x8(%ebp),%eax
801062ca:	8b 00                	mov    (%eax),%eax
801062cc:	39 c2                	cmp    %eax,%edx
801062ce:	76 07                	jbe    801062d7 <fetchint+0x23>
    return -1;
801062d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d5:	eb 0f                	jmp    801062e6 <fetchint+0x32>
  *ip = *(int*)(addr);
801062d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801062da:	8b 10                	mov    (%eax),%edx
801062dc:	8b 45 10             	mov    0x10(%ebp),%eax
801062df:	89 10                	mov    %edx,(%eax)
  return 0;
801062e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062e6:	5d                   	pop    %ebp
801062e7:	c3                   	ret    

801062e8 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
801062e8:	55                   	push   %ebp
801062e9:	89 e5                	mov    %esp,%ebp
801062eb:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
801062ee:	8b 45 08             	mov    0x8(%ebp),%eax
801062f1:	8b 00                	mov    (%eax),%eax
801062f3:	3b 45 0c             	cmp    0xc(%ebp),%eax
801062f6:	77 07                	ja     801062ff <fetchstr+0x17>
    return -1;
801062f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062fd:	eb 45                	jmp    80106344 <fetchstr+0x5c>
  *pp = (char*)addr;
801062ff:	8b 55 0c             	mov    0xc(%ebp),%edx
80106302:	8b 45 10             	mov    0x10(%ebp),%eax
80106305:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
80106307:	8b 45 08             	mov    0x8(%ebp),%eax
8010630a:	8b 00                	mov    (%eax),%eax
8010630c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010630f:	8b 45 10             	mov    0x10(%ebp),%eax
80106312:	8b 00                	mov    (%eax),%eax
80106314:	89 45 fc             	mov    %eax,-0x4(%ebp)
80106317:	eb 1e                	jmp    80106337 <fetchstr+0x4f>
    if(*s == 0)
80106319:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010631c:	0f b6 00             	movzbl (%eax),%eax
8010631f:	84 c0                	test   %al,%al
80106321:	75 10                	jne    80106333 <fetchstr+0x4b>
      return s - *pp;
80106323:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106326:	8b 45 10             	mov    0x10(%ebp),%eax
80106329:	8b 00                	mov    (%eax),%eax
8010632b:	89 d1                	mov    %edx,%ecx
8010632d:	29 c1                	sub    %eax,%ecx
8010632f:	89 c8                	mov    %ecx,%eax
80106331:	eb 11                	jmp    80106344 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
80106333:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106337:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010633a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010633d:	72 da                	jb     80106319 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
8010633f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106344:	c9                   	leave  
80106345:	c3                   	ret    

80106346 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80106346:	55                   	push   %ebp
80106347:	89 e5                	mov    %esp,%ebp
80106349:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
8010634c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106352:	8b 40 18             	mov    0x18(%eax),%eax
80106355:	8b 50 44             	mov    0x44(%eax),%edx
80106358:	8b 45 08             	mov    0x8(%ebp),%eax
8010635b:	c1 e0 02             	shl    $0x2,%eax
8010635e:	01 d0                	add    %edx,%eax
80106360:	8d 48 04             	lea    0x4(%eax),%ecx
80106363:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106369:	8b 55 0c             	mov    0xc(%ebp),%edx
8010636c:	89 54 24 08          	mov    %edx,0x8(%esp)
80106370:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106374:	89 04 24             	mov    %eax,(%esp)
80106377:	e8 38 ff ff ff       	call   801062b4 <fetchint>
}
8010637c:	c9                   	leave  
8010637d:	c3                   	ret    

8010637e <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010637e:	55                   	push   %ebp
8010637f:	89 e5                	mov    %esp,%ebp
80106381:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80106384:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106387:	89 44 24 04          	mov    %eax,0x4(%esp)
8010638b:	8b 45 08             	mov    0x8(%ebp),%eax
8010638e:	89 04 24             	mov    %eax,(%esp)
80106391:	e8 b0 ff ff ff       	call   80106346 <argint>
80106396:	85 c0                	test   %eax,%eax
80106398:	79 07                	jns    801063a1 <argptr+0x23>
    return -1;
8010639a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010639f:	eb 3d                	jmp    801063de <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801063a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063a4:	89 c2                	mov    %eax,%edx
801063a6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063ac:	8b 00                	mov    (%eax),%eax
801063ae:	39 c2                	cmp    %eax,%edx
801063b0:	73 16                	jae    801063c8 <argptr+0x4a>
801063b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063b5:	89 c2                	mov    %eax,%edx
801063b7:	8b 45 10             	mov    0x10(%ebp),%eax
801063ba:	01 c2                	add    %eax,%edx
801063bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063c2:	8b 00                	mov    (%eax),%eax
801063c4:	39 c2                	cmp    %eax,%edx
801063c6:	76 07                	jbe    801063cf <argptr+0x51>
    return -1;
801063c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063cd:	eb 0f                	jmp    801063de <argptr+0x60>
  *pp = (char*)i;
801063cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
801063d2:	89 c2                	mov    %eax,%edx
801063d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801063d7:	89 10                	mov    %edx,(%eax)
  return 0;
801063d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063de:	c9                   	leave  
801063df:	c3                   	ret    

801063e0 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801063e0:	55                   	push   %ebp
801063e1:	89 e5                	mov    %esp,%ebp
801063e3:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
801063e6:	8d 45 fc             	lea    -0x4(%ebp),%eax
801063e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801063ed:	8b 45 08             	mov    0x8(%ebp),%eax
801063f0:	89 04 24             	mov    %eax,(%esp)
801063f3:	e8 4e ff ff ff       	call   80106346 <argint>
801063f8:	85 c0                	test   %eax,%eax
801063fa:	79 07                	jns    80106403 <argstr+0x23>
    return -1;
801063fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106401:	eb 1e                	jmp    80106421 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80106403:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106406:	89 c2                	mov    %eax,%edx
80106408:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010640e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106411:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106415:	89 54 24 04          	mov    %edx,0x4(%esp)
80106419:	89 04 24             	mov    %eax,(%esp)
8010641c:	e8 c7 fe ff ff       	call   801062e8 <fetchstr>
}
80106421:	c9                   	leave  
80106422:	c3                   	ret    

80106423 <syscall>:
[SYS_dedup]   sys_dedup,
};

void
syscall(void)
{
80106423:	55                   	push   %ebp
80106424:	89 e5                	mov    %esp,%ebp
80106426:	53                   	push   %ebx
80106427:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010642a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106430:	8b 40 18             	mov    0x18(%eax),%eax
80106433:	8b 40 1c             	mov    0x1c(%eax),%eax
80106436:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
80106439:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010643d:	78 2e                	js     8010646d <syscall+0x4a>
8010643f:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106443:	7f 28                	jg     8010646d <syscall+0x4a>
80106445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106448:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010644f:	85 c0                	test   %eax,%eax
80106451:	74 1a                	je     8010646d <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80106453:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106459:	8b 58 18             	mov    0x18(%eax),%ebx
8010645c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010645f:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106466:	ff d0                	call   *%eax
80106468:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010646b:	eb 73                	jmp    801064e0 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
8010646d:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80106471:	7e 30                	jle    801064a3 <syscall+0x80>
80106473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106476:	83 f8 19             	cmp    $0x19,%eax
80106479:	77 28                	ja     801064a3 <syscall+0x80>
8010647b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010647e:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
80106485:	85 c0                	test   %eax,%eax
80106487:	74 1a                	je     801064a3 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80106489:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010648f:	8b 58 18             	mov    0x18(%eax),%ebx
80106492:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106495:	8b 04 85 40 c0 10 80 	mov    -0x7fef3fc0(,%eax,4),%eax
8010649c:	ff d0                	call   *%eax
8010649e:	89 43 1c             	mov    %eax,0x1c(%ebx)
801064a1:	eb 3d                	jmp    801064e0 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801064a3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064a9:	8d 48 6c             	lea    0x6c(%eax),%ecx
801064ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801064b2:	8b 40 10             	mov    0x10(%eax),%eax
801064b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064b8:	89 54 24 0c          	mov    %edx,0xc(%esp)
801064bc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801064c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801064c4:	c7 04 24 d7 99 10 80 	movl   $0x801099d7,(%esp)
801064cb:	e8 d1 9e ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801064d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d6:	8b 40 18             	mov    0x18(%eax),%eax
801064d9:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801064e0:	83 c4 24             	add    $0x24,%esp
801064e3:	5b                   	pop    %ebx
801064e4:	5d                   	pop    %ebp
801064e5:	c3                   	ret    
	...

801064e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801064e8:	55                   	push   %ebp
801064e9:	89 e5                	mov    %esp,%ebp
801064eb:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801064ee:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064f1:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f5:	8b 45 08             	mov    0x8(%ebp),%eax
801064f8:	89 04 24             	mov    %eax,(%esp)
801064fb:	e8 46 fe ff ff       	call   80106346 <argint>
80106500:	85 c0                	test   %eax,%eax
80106502:	79 07                	jns    8010650b <argfd+0x23>
    return -1;
80106504:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106509:	eb 50                	jmp    8010655b <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010650b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010650e:	85 c0                	test   %eax,%eax
80106510:	78 21                	js     80106533 <argfd+0x4b>
80106512:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106515:	83 f8 0f             	cmp    $0xf,%eax
80106518:	7f 19                	jg     80106533 <argfd+0x4b>
8010651a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106520:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106523:	83 c2 08             	add    $0x8,%edx
80106526:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010652a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010652d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106531:	75 07                	jne    8010653a <argfd+0x52>
    return -1;
80106533:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106538:	eb 21                	jmp    8010655b <argfd+0x73>
  if(pfd)
8010653a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010653e:	74 08                	je     80106548 <argfd+0x60>
    *pfd = fd;
80106540:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106543:	8b 45 0c             	mov    0xc(%ebp),%eax
80106546:	89 10                	mov    %edx,(%eax)
  if(pf)
80106548:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010654c:	74 08                	je     80106556 <argfd+0x6e>
    *pf = f;
8010654e:	8b 45 10             	mov    0x10(%ebp),%eax
80106551:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106554:	89 10                	mov    %edx,(%eax)
  return 0;
80106556:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010655b:	c9                   	leave  
8010655c:	c3                   	ret    

8010655d <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010655d:	55                   	push   %ebp
8010655e:	89 e5                	mov    %esp,%ebp
80106560:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106563:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010656a:	eb 30                	jmp    8010659c <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
8010656c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106572:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106575:	83 c2 08             	add    $0x8,%edx
80106578:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010657c:	85 c0                	test   %eax,%eax
8010657e:	75 18                	jne    80106598 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80106580:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106586:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106589:	8d 4a 08             	lea    0x8(%edx),%ecx
8010658c:	8b 55 08             	mov    0x8(%ebp),%edx
8010658f:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80106593:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106596:	eb 0f                	jmp    801065a7 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106598:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010659c:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
801065a0:	7e ca                	jle    8010656c <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
801065a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801065a7:	c9                   	leave  
801065a8:	c3                   	ret    

801065a9 <sys_dup>:

int
sys_dup(void)
{
801065a9:	55                   	push   %ebp
801065aa:	89 e5                	mov    %esp,%ebp
801065ac:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801065af:	8d 45 f0             	lea    -0x10(%ebp),%eax
801065b2:	89 44 24 08          	mov    %eax,0x8(%esp)
801065b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801065bd:	00 
801065be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065c5:	e8 1e ff ff ff       	call   801064e8 <argfd>
801065ca:	85 c0                	test   %eax,%eax
801065cc:	79 07                	jns    801065d5 <sys_dup+0x2c>
    return -1;
801065ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065d3:	eb 29                	jmp    801065fe <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801065d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065d8:	89 04 24             	mov    %eax,(%esp)
801065db:	e8 7d ff ff ff       	call   8010655d <fdalloc>
801065e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065e3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065e7:	79 07                	jns    801065f0 <sys_dup+0x47>
    return -1;
801065e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065ee:	eb 0e                	jmp    801065fe <sys_dup+0x55>
  filedup(f);
801065f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065f3:	89 04 24             	mov    %eax,(%esp)
801065f6:	e8 81 a9 ff ff       	call   80100f7c <filedup>
  return fd;
801065fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801065fe:	c9                   	leave  
801065ff:	c3                   	ret    

80106600 <sys_read>:

int
sys_read(void)
{
80106600:	55                   	push   %ebp
80106601:	89 e5                	mov    %esp,%ebp
80106603:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106606:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106609:	89 44 24 08          	mov    %eax,0x8(%esp)
8010660d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106614:	00 
80106615:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010661c:	e8 c7 fe ff ff       	call   801064e8 <argfd>
80106621:	85 c0                	test   %eax,%eax
80106623:	78 35                	js     8010665a <sys_read+0x5a>
80106625:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106628:	89 44 24 04          	mov    %eax,0x4(%esp)
8010662c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106633:	e8 0e fd ff ff       	call   80106346 <argint>
80106638:	85 c0                	test   %eax,%eax
8010663a:	78 1e                	js     8010665a <sys_read+0x5a>
8010663c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010663f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106643:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106646:	89 44 24 04          	mov    %eax,0x4(%esp)
8010664a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106651:	e8 28 fd ff ff       	call   8010637e <argptr>
80106656:	85 c0                	test   %eax,%eax
80106658:	79 07                	jns    80106661 <sys_read+0x61>
    return -1;
8010665a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010665f:	eb 19                	jmp    8010667a <sys_read+0x7a>
  return fileread(f, p, n);
80106661:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106664:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106667:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010666a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010666e:	89 54 24 04          	mov    %edx,0x4(%esp)
80106672:	89 04 24             	mov    %eax,(%esp)
80106675:	e8 6f aa ff ff       	call   801010e9 <fileread>
}
8010667a:	c9                   	leave  
8010667b:	c3                   	ret    

8010667c <sys_write>:

int
sys_write(void)
{
8010667c:	55                   	push   %ebp
8010667d:	89 e5                	mov    %esp,%ebp
8010667f:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80106682:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106685:	89 44 24 08          	mov    %eax,0x8(%esp)
80106689:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106690:	00 
80106691:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106698:	e8 4b fe ff ff       	call   801064e8 <argfd>
8010669d:	85 c0                	test   %eax,%eax
8010669f:	78 35                	js     801066d6 <sys_write+0x5a>
801066a1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801066a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801066a8:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801066af:	e8 92 fc ff ff       	call   80106346 <argint>
801066b4:	85 c0                	test   %eax,%eax
801066b6:	78 1e                	js     801066d6 <sys_write+0x5a>
801066b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066bb:	89 44 24 08          	mov    %eax,0x8(%esp)
801066bf:	8d 45 ec             	lea    -0x14(%ebp),%eax
801066c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801066c6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801066cd:	e8 ac fc ff ff       	call   8010637e <argptr>
801066d2:	85 c0                	test   %eax,%eax
801066d4:	79 07                	jns    801066dd <sys_write+0x61>
    return -1;
801066d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066db:	eb 19                	jmp    801066f6 <sys_write+0x7a>
  return filewrite(f, p, n);
801066dd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801066e0:	8b 55 ec             	mov    -0x14(%ebp),%edx
801066e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801066ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801066ee:	89 04 24             	mov    %eax,(%esp)
801066f1:	e8 af aa ff ff       	call   801011a5 <filewrite>
}
801066f6:	c9                   	leave  
801066f7:	c3                   	ret    

801066f8 <sys_close>:

int
sys_close(void)
{
801066f8:	55                   	push   %ebp
801066f9:	89 e5                	mov    %esp,%ebp
801066fb:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801066fe:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106701:	89 44 24 08          	mov    %eax,0x8(%esp)
80106705:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106708:	89 44 24 04          	mov    %eax,0x4(%esp)
8010670c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106713:	e8 d0 fd ff ff       	call   801064e8 <argfd>
80106718:	85 c0                	test   %eax,%eax
8010671a:	79 07                	jns    80106723 <sys_close+0x2b>
    return -1;
8010671c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106721:	eb 24                	jmp    80106747 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80106723:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106729:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010672c:	83 c2 08             	add    $0x8,%edx
8010672f:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106736:	00 
  fileclose(f);
80106737:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010673a:	89 04 24             	mov    %eax,(%esp)
8010673d:	e8 82 a8 ff ff       	call   80100fc4 <fileclose>
  return 0;
80106742:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106747:	c9                   	leave  
80106748:	c3                   	ret    

80106749 <sys_fstat>:

int
sys_fstat(void)
{
80106749:	55                   	push   %ebp
8010674a:	89 e5                	mov    %esp,%ebp
8010674c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010674f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106752:	89 44 24 08          	mov    %eax,0x8(%esp)
80106756:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010675d:	00 
8010675e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106765:	e8 7e fd ff ff       	call   801064e8 <argfd>
8010676a:	85 c0                	test   %eax,%eax
8010676c:	78 1f                	js     8010678d <sys_fstat+0x44>
8010676e:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106775:	00 
80106776:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106779:	89 44 24 04          	mov    %eax,0x4(%esp)
8010677d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106784:	e8 f5 fb ff ff       	call   8010637e <argptr>
80106789:	85 c0                	test   %eax,%eax
8010678b:	79 07                	jns    80106794 <sys_fstat+0x4b>
    return -1;
8010678d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106792:	eb 12                	jmp    801067a6 <sys_fstat+0x5d>
  return filestat(f, st);
80106794:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106797:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010679a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010679e:	89 04 24             	mov    %eax,(%esp)
801067a1:	e8 f4 a8 ff ff       	call   8010109a <filestat>
}
801067a6:	c9                   	leave  
801067a7:	c3                   	ret    

801067a8 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801067a8:	55                   	push   %ebp
801067a9:	89 e5                	mov    %esp,%ebp
801067ab:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801067ae:	8d 45 d8             	lea    -0x28(%ebp),%eax
801067b1:	89 44 24 04          	mov    %eax,0x4(%esp)
801067b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067bc:	e8 1f fc ff ff       	call   801063e0 <argstr>
801067c1:	85 c0                	test   %eax,%eax
801067c3:	78 17                	js     801067dc <sys_link+0x34>
801067c5:	8d 45 dc             	lea    -0x24(%ebp),%eax
801067c8:	89 44 24 04          	mov    %eax,0x4(%esp)
801067cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801067d3:	e8 08 fc ff ff       	call   801063e0 <argstr>
801067d8:	85 c0                	test   %eax,%eax
801067da:	79 0a                	jns    801067e6 <sys_link+0x3e>
    return -1;
801067dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067e1:	e9 3c 01 00 00       	jmp    80106922 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
801067e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
801067e9:	89 04 24             	mov    %eax,(%esp)
801067ec:	e8 0a cb ff ff       	call   801032fb <namei>
801067f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067f8:	75 0a                	jne    80106804 <sys_link+0x5c>
    return -1;
801067fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067ff:	e9 1e 01 00 00       	jmp    80106922 <sys_link+0x17a>

  begin_trans();
80106804:	e8 18 dc ff ff       	call   80104421 <begin_trans>

  ilock(ip);
80106809:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010680c:	89 04 24             	mov    %eax,(%esp)
8010680f:	e8 5c be ff ff       	call   80102670 <ilock>
  if(ip->type == T_DIR){
80106814:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106817:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010681b:	66 83 f8 01          	cmp    $0x1,%ax
8010681f:	75 1a                	jne    8010683b <sys_link+0x93>
    iunlockput(ip);
80106821:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106824:	89 04 24             	mov    %eax,(%esp)
80106827:	e8 c8 c0 ff ff       	call   801028f4 <iunlockput>
    commit_trans();
8010682c:	e8 39 dc ff ff       	call   8010446a <commit_trans>
    return -1;
80106831:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106836:	e9 e7 00 00 00       	jmp    80106922 <sys_link+0x17a>
  }

  ip->nlink++;
8010683b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010683e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106842:	8d 50 01             	lea    0x1(%eax),%edx
80106845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106848:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010684c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010684f:	89 04 24             	mov    %eax,(%esp)
80106852:	e8 5d bc ff ff       	call   801024b4 <iupdate>
  iunlock(ip);
80106857:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010685a:	89 04 24             	mov    %eax,(%esp)
8010685d:	e8 5c bf ff ff       	call   801027be <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106862:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106865:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106868:	89 54 24 04          	mov    %edx,0x4(%esp)
8010686c:	89 04 24             	mov    %eax,(%esp)
8010686f:	e8 a9 ca ff ff       	call   8010331d <nameiparent>
80106874:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106877:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010687b:	74 68                	je     801068e5 <sys_link+0x13d>
    goto bad;
  ilock(dp);
8010687d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106880:	89 04 24             	mov    %eax,(%esp)
80106883:	e8 e8 bd ff ff       	call   80102670 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80106888:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010688b:	8b 10                	mov    (%eax),%edx
8010688d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106890:	8b 00                	mov    (%eax),%eax
80106892:	39 c2                	cmp    %eax,%edx
80106894:	75 20                	jne    801068b6 <sys_link+0x10e>
80106896:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106899:	8b 40 04             	mov    0x4(%eax),%eax
8010689c:	89 44 24 08          	mov    %eax,0x8(%esp)
801068a0:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801068a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801068a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068aa:	89 04 24             	mov    %eax,(%esp)
801068ad:	e8 88 c7 ff ff       	call   8010303a <dirlink>
801068b2:	85 c0                	test   %eax,%eax
801068b4:	79 0d                	jns    801068c3 <sys_link+0x11b>
    iunlockput(dp);
801068b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068b9:	89 04 24             	mov    %eax,(%esp)
801068bc:	e8 33 c0 ff ff       	call   801028f4 <iunlockput>
    goto bad;
801068c1:	eb 23                	jmp    801068e6 <sys_link+0x13e>
  }
  iunlockput(dp);
801068c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068c6:	89 04 24             	mov    %eax,(%esp)
801068c9:	e8 26 c0 ff ff       	call   801028f4 <iunlockput>
  iput(ip);
801068ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068d1:	89 04 24             	mov    %eax,(%esp)
801068d4:	e8 4a bf ff ff       	call   80102823 <iput>

  commit_trans();
801068d9:	e8 8c db ff ff       	call   8010446a <commit_trans>

  return 0;
801068de:	b8 00 00 00 00       	mov    $0x0,%eax
801068e3:	eb 3d                	jmp    80106922 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
801068e5:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
801068e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e9:	89 04 24             	mov    %eax,(%esp)
801068ec:	e8 7f bd ff ff       	call   80102670 <ilock>
  ip->nlink--;
801068f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068f8:	8d 50 ff             	lea    -0x1(%eax),%edx
801068fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068fe:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106902:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106905:	89 04 24             	mov    %eax,(%esp)
80106908:	e8 a7 bb ff ff       	call   801024b4 <iupdate>
  iunlockput(ip);
8010690d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106910:	89 04 24             	mov    %eax,(%esp)
80106913:	e8 dc bf ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80106918:	e8 4d db ff ff       	call   8010446a <commit_trans>
  return -1;
8010691d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106922:	c9                   	leave  
80106923:	c3                   	ret    

80106924 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106924:	55                   	push   %ebp
80106925:	89 e5                	mov    %esp,%ebp
80106927:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010692a:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106931:	eb 4b                	jmp    8010697e <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106933:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106936:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010693d:	00 
8010693e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106942:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106945:	89 44 24 04          	mov    %eax,0x4(%esp)
80106949:	8b 45 08             	mov    0x8(%ebp),%eax
8010694c:	89 04 24             	mov    %eax,(%esp)
8010694f:	e8 82 c2 ff ff       	call   80102bd6 <readi>
80106954:	83 f8 10             	cmp    $0x10,%eax
80106957:	74 0c                	je     80106965 <isdirempty+0x41>
      panic("isdirempty: readi");
80106959:	c7 04 24 f3 99 10 80 	movl   $0x801099f3,(%esp)
80106960:	e8 d8 9b ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80106965:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80106969:	66 85 c0             	test   %ax,%ax
8010696c:	74 07                	je     80106975 <isdirempty+0x51>
      return 0;
8010696e:	b8 00 00 00 00       	mov    $0x0,%eax
80106973:	eb 1b                	jmp    80106990 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106978:	83 c0 10             	add    $0x10,%eax
8010697b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010697e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106981:	8b 45 08             	mov    0x8(%ebp),%eax
80106984:	8b 40 18             	mov    0x18(%eax),%eax
80106987:	39 c2                	cmp    %eax,%edx
80106989:	72 a8                	jb     80106933 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010698b:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106990:	c9                   	leave  
80106991:	c3                   	ret    

80106992 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106992:	55                   	push   %ebp
80106993:	89 e5                	mov    %esp,%ebp
80106995:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106998:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010699b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010699f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801069a6:	e8 35 fa ff ff       	call   801063e0 <argstr>
801069ab:	85 c0                	test   %eax,%eax
801069ad:	79 0a                	jns    801069b9 <sys_unlink+0x27>
    return -1;
801069af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069b4:	e9 aa 01 00 00       	jmp    80106b63 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
801069b9:	8b 45 cc             	mov    -0x34(%ebp),%eax
801069bc:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801069bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801069c3:	89 04 24             	mov    %eax,(%esp)
801069c6:	e8 52 c9 ff ff       	call   8010331d <nameiparent>
801069cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801069ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801069d2:	75 0a                	jne    801069de <sys_unlink+0x4c>
    return -1;
801069d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069d9:	e9 85 01 00 00       	jmp    80106b63 <sys_unlink+0x1d1>

  begin_trans();
801069de:	e8 3e da ff ff       	call   80104421 <begin_trans>

  ilock(dp);
801069e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069e6:	89 04 24             	mov    %eax,(%esp)
801069e9:	e8 82 bc ff ff       	call   80102670 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801069ee:	c7 44 24 04 05 9a 10 	movl   $0x80109a05,0x4(%esp)
801069f5:	80 
801069f6:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801069f9:	89 04 24             	mov    %eax,(%esp)
801069fc:	e8 4f c5 ff ff       	call   80102f50 <namecmp>
80106a01:	85 c0                	test   %eax,%eax
80106a03:	0f 84 45 01 00 00    	je     80106b4e <sys_unlink+0x1bc>
80106a09:	c7 44 24 04 07 9a 10 	movl   $0x80109a07,0x4(%esp)
80106a10:	80 
80106a11:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a14:	89 04 24             	mov    %eax,(%esp)
80106a17:	e8 34 c5 ff ff       	call   80102f50 <namecmp>
80106a1c:	85 c0                	test   %eax,%eax
80106a1e:	0f 84 2a 01 00 00    	je     80106b4e <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80106a24:	8d 45 c8             	lea    -0x38(%ebp),%eax
80106a27:	89 44 24 08          	mov    %eax,0x8(%esp)
80106a2b:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106a2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a35:	89 04 24             	mov    %eax,(%esp)
80106a38:	e8 35 c5 ff ff       	call   80102f72 <dirlookup>
80106a3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a40:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a44:	0f 84 03 01 00 00    	je     80106b4d <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80106a4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a4d:	89 04 24             	mov    %eax,(%esp)
80106a50:	e8 1b bc ff ff       	call   80102670 <ilock>

  if(ip->nlink < 1)
80106a55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a58:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a5c:	66 85 c0             	test   %ax,%ax
80106a5f:	7f 0c                	jg     80106a6d <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80106a61:	c7 04 24 0a 9a 10 80 	movl   $0x80109a0a,(%esp)
80106a68:	e8 d0 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106a6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a70:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a74:	66 83 f8 01          	cmp    $0x1,%ax
80106a78:	75 1f                	jne    80106a99 <sys_unlink+0x107>
80106a7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a7d:	89 04 24             	mov    %eax,(%esp)
80106a80:	e8 9f fe ff ff       	call   80106924 <isdirempty>
80106a85:	85 c0                	test   %eax,%eax
80106a87:	75 10                	jne    80106a99 <sys_unlink+0x107>
    iunlockput(ip);
80106a89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a8c:	89 04 24             	mov    %eax,(%esp)
80106a8f:	e8 60 be ff ff       	call   801028f4 <iunlockput>
    goto bad;
80106a94:	e9 b5 00 00 00       	jmp    80106b4e <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80106a99:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106aa0:	00 
80106aa1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106aa8:	00 
80106aa9:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106aac:	89 04 24             	mov    %eax,(%esp)
80106aaf:	e8 42 f5 ff ff       	call   80105ff6 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106ab4:	8b 45 c8             	mov    -0x38(%ebp),%eax
80106ab7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80106abe:	00 
80106abf:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ac3:	8d 45 e0             	lea    -0x20(%ebp),%eax
80106ac6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106aca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106acd:	89 04 24             	mov    %eax,(%esp)
80106ad0:	e8 6c c2 ff ff       	call   80102d41 <writei>
80106ad5:	83 f8 10             	cmp    $0x10,%eax
80106ad8:	74 0c                	je     80106ae6 <sys_unlink+0x154>
    panic("unlink: writei");
80106ada:	c7 04 24 1c 9a 10 80 	movl   $0x80109a1c,(%esp)
80106ae1:	e8 57 9a ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80106ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae9:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106aed:	66 83 f8 01          	cmp    $0x1,%ax
80106af1:	75 1c                	jne    80106b0f <sys_unlink+0x17d>
    dp->nlink--;
80106af3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106af6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106afa:	8d 50 ff             	lea    -0x1(%eax),%edx
80106afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b00:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106b04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b07:	89 04 24             	mov    %eax,(%esp)
80106b0a:	e8 a5 b9 ff ff       	call   801024b4 <iupdate>
  }
  iunlockput(dp);
80106b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b12:	89 04 24             	mov    %eax,(%esp)
80106b15:	e8 da bd ff ff       	call   801028f4 <iunlockput>

  ip->nlink--;
80106b1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b1d:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106b21:	8d 50 ff             	lea    -0x1(%eax),%edx
80106b24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b27:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106b2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b2e:	89 04 24             	mov    %eax,(%esp)
80106b31:	e8 7e b9 ff ff       	call   801024b4 <iupdate>
  iunlockput(ip);
80106b36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b39:	89 04 24             	mov    %eax,(%esp)
80106b3c:	e8 b3 bd ff ff       	call   801028f4 <iunlockput>

  commit_trans();
80106b41:	e8 24 d9 ff ff       	call   8010446a <commit_trans>

  return 0;
80106b46:	b8 00 00 00 00       	mov    $0x0,%eax
80106b4b:	eb 16                	jmp    80106b63 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80106b4d:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80106b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b51:	89 04 24             	mov    %eax,(%esp)
80106b54:	e8 9b bd ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80106b59:	e8 0c d9 ff ff       	call   8010446a <commit_trans>
  return -1;
80106b5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106b63:	c9                   	leave  
80106b64:	c3                   	ret    

80106b65 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80106b65:	55                   	push   %ebp
80106b66:	89 e5                	mov    %esp,%ebp
80106b68:	83 ec 48             	sub    $0x48,%esp
80106b6b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106b6e:	8b 55 10             	mov    0x10(%ebp),%edx
80106b71:	8b 45 14             	mov    0x14(%ebp),%eax
80106b74:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80106b78:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106b7c:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106b80:	8d 45 de             	lea    -0x22(%ebp),%eax
80106b83:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b87:	8b 45 08             	mov    0x8(%ebp),%eax
80106b8a:	89 04 24             	mov    %eax,(%esp)
80106b8d:	e8 8b c7 ff ff       	call   8010331d <nameiparent>
80106b92:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106b95:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106b99:	75 0a                	jne    80106ba5 <create+0x40>
    return 0;
80106b9b:	b8 00 00 00 00       	mov    $0x0,%eax
80106ba0:	e9 7e 01 00 00       	jmp    80106d23 <create+0x1be>
  ilock(dp);
80106ba5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ba8:	89 04 24             	mov    %eax,(%esp)
80106bab:	e8 c0 ba ff ff       	call   80102670 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106bb0:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106bb3:	89 44 24 08          	mov    %eax,0x8(%esp)
80106bb7:	8d 45 de             	lea    -0x22(%ebp),%eax
80106bba:	89 44 24 04          	mov    %eax,0x4(%esp)
80106bbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bc1:	89 04 24             	mov    %eax,(%esp)
80106bc4:	e8 a9 c3 ff ff       	call   80102f72 <dirlookup>
80106bc9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106bcc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106bd0:	74 47                	je     80106c19 <create+0xb4>
    iunlockput(dp);
80106bd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd5:	89 04 24             	mov    %eax,(%esp)
80106bd8:	e8 17 bd ff ff       	call   801028f4 <iunlockput>
    ilock(ip);
80106bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106be0:	89 04 24             	mov    %eax,(%esp)
80106be3:	e8 88 ba ff ff       	call   80102670 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106be8:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106bed:	75 15                	jne    80106c04 <create+0x9f>
80106bef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bf2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bf6:	66 83 f8 02          	cmp    $0x2,%ax
80106bfa:	75 08                	jne    80106c04 <create+0x9f>
      return ip;
80106bfc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106bff:	e9 1f 01 00 00       	jmp    80106d23 <create+0x1be>
    iunlockput(ip);
80106c04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c07:	89 04 24             	mov    %eax,(%esp)
80106c0a:	e8 e5 bc ff ff       	call   801028f4 <iunlockput>
    return 0;
80106c0f:	b8 00 00 00 00       	mov    $0x0,%eax
80106c14:	e9 0a 01 00 00       	jmp    80106d23 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106c19:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c20:	8b 00                	mov    (%eax),%eax
80106c22:	89 54 24 04          	mov    %edx,0x4(%esp)
80106c26:	89 04 24             	mov    %eax,(%esp)
80106c29:	e8 a9 b7 ff ff       	call   801023d7 <ialloc>
80106c2e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c31:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c35:	75 0c                	jne    80106c43 <create+0xde>
    panic("create: ialloc");
80106c37:	c7 04 24 2b 9a 10 80 	movl   $0x80109a2b,(%esp)
80106c3e:	e8 fa 98 ff ff       	call   8010053d <panic>

  ilock(ip);
80106c43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c46:	89 04 24             	mov    %eax,(%esp)
80106c49:	e8 22 ba ff ff       	call   80102670 <ilock>
  ip->major = major;
80106c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c51:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106c55:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106c59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c5c:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106c60:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106c64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c67:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106c6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c70:	89 04 24             	mov    %eax,(%esp)
80106c73:	e8 3c b8 ff ff       	call   801024b4 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106c78:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106c7d:	75 6a                	jne    80106ce9 <create+0x184>
    dp->nlink++;  // for ".."
80106c7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c82:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106c86:	8d 50 01             	lea    0x1(%eax),%edx
80106c89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c8c:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c93:	89 04 24             	mov    %eax,(%esp)
80106c96:	e8 19 b8 ff ff       	call   801024b4 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106c9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c9e:	8b 40 04             	mov    0x4(%eax),%eax
80106ca1:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ca5:	c7 44 24 04 05 9a 10 	movl   $0x80109a05,0x4(%esp)
80106cac:	80 
80106cad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cb0:	89 04 24             	mov    %eax,(%esp)
80106cb3:	e8 82 c3 ff ff       	call   8010303a <dirlink>
80106cb8:	85 c0                	test   %eax,%eax
80106cba:	78 21                	js     80106cdd <create+0x178>
80106cbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cbf:	8b 40 04             	mov    0x4(%eax),%eax
80106cc2:	89 44 24 08          	mov    %eax,0x8(%esp)
80106cc6:	c7 44 24 04 07 9a 10 	movl   $0x80109a07,0x4(%esp)
80106ccd:	80 
80106cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cd1:	89 04 24             	mov    %eax,(%esp)
80106cd4:	e8 61 c3 ff ff       	call   8010303a <dirlink>
80106cd9:	85 c0                	test   %eax,%eax
80106cdb:	79 0c                	jns    80106ce9 <create+0x184>
      panic("create dots");
80106cdd:	c7 04 24 3a 9a 10 80 	movl   $0x80109a3a,(%esp)
80106ce4:	e8 54 98 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106ce9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cec:	8b 40 04             	mov    0x4(%eax),%eax
80106cef:	89 44 24 08          	mov    %eax,0x8(%esp)
80106cf3:	8d 45 de             	lea    -0x22(%ebp),%eax
80106cf6:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106cfd:	89 04 24             	mov    %eax,(%esp)
80106d00:	e8 35 c3 ff ff       	call   8010303a <dirlink>
80106d05:	85 c0                	test   %eax,%eax
80106d07:	79 0c                	jns    80106d15 <create+0x1b0>
    panic("create: dirlink");
80106d09:	c7 04 24 46 9a 10 80 	movl   $0x80109a46,(%esp)
80106d10:	e8 28 98 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106d15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d18:	89 04 24             	mov    %eax,(%esp)
80106d1b:	e8 d4 bb ff ff       	call   801028f4 <iunlockput>

  return ip;
80106d20:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106d23:	c9                   	leave  
80106d24:	c3                   	ret    

80106d25 <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80106d25:	55                   	push   %ebp
80106d26:	89 e5                	mov    %esp,%ebp
80106d28:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80106d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106d2e:	25 00 02 00 00       	and    $0x200,%eax
80106d33:	85 c0                	test   %eax,%eax
80106d35:	74 40                	je     80106d77 <fileopen+0x52>
    begin_trans();
80106d37:	e8 e5 d6 ff ff       	call   80104421 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106d3c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106d43:	00 
80106d44:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106d4b:	00 
80106d4c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106d53:	00 
80106d54:	8b 45 08             	mov    0x8(%ebp),%eax
80106d57:	89 04 24             	mov    %eax,(%esp)
80106d5a:	e8 06 fe ff ff       	call   80106b65 <create>
80106d5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106d62:	e8 03 d7 ff ff       	call   8010446a <commit_trans>
    if(ip == 0)
80106d67:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d6b:	75 5b                	jne    80106dc8 <fileopen+0xa3>
      return 0;
80106d6d:	b8 00 00 00 00       	mov    $0x0,%eax
80106d72:	e9 e5 00 00 00       	jmp    80106e5c <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80106d77:	8b 45 08             	mov    0x8(%ebp),%eax
80106d7a:	89 04 24             	mov    %eax,(%esp)
80106d7d:	e8 79 c5 ff ff       	call   801032fb <namei>
80106d82:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d85:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d89:	75 0a                	jne    80106d95 <fileopen+0x70>
      return 0;
80106d8b:	b8 00 00 00 00       	mov    $0x0,%eax
80106d90:	e9 c7 00 00 00       	jmp    80106e5c <fileopen+0x137>
    ilock(ip);
80106d95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d98:	89 04 24             	mov    %eax,(%esp)
80106d9b:	e8 d0 b8 ff ff       	call   80102670 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106da0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106da3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106da7:	66 83 f8 01          	cmp    $0x1,%ax
80106dab:	75 1b                	jne    80106dc8 <fileopen+0xa3>
80106dad:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106db1:	74 15                	je     80106dc8 <fileopen+0xa3>
      iunlockput(ip);
80106db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106db6:	89 04 24             	mov    %eax,(%esp)
80106db9:	e8 36 bb ff ff       	call   801028f4 <iunlockput>
      return 0;
80106dbe:	b8 00 00 00 00       	mov    $0x0,%eax
80106dc3:	e9 94 00 00 00       	jmp    80106e5c <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80106dc8:	e8 4f a1 ff ff       	call   80100f1c <filealloc>
80106dcd:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106dd0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106dd4:	75 23                	jne    80106df9 <fileopen+0xd4>
    if(f)
80106dd6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106dda:	74 0b                	je     80106de7 <fileopen+0xc2>
      fileclose(f);
80106ddc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ddf:	89 04 24             	mov    %eax,(%esp)
80106de2:	e8 dd a1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106de7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dea:	89 04 24             	mov    %eax,(%esp)
80106ded:	e8 02 bb ff ff       	call   801028f4 <iunlockput>
    return 0;
80106df2:	b8 00 00 00 00       	mov    $0x0,%eax
80106df7:	eb 63                	jmp    80106e5c <fileopen+0x137>
  }
  iunlock(ip);
80106df9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106dfc:	89 04 24             	mov    %eax,(%esp)
80106dff:	e8 ba b9 ff ff       	call   801027be <iunlock>

  f->type = FD_INODE;
80106e04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e07:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106e0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e10:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e13:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106e16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e19:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106e20:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e23:	83 e0 01             	and    $0x1,%eax
80106e26:	85 c0                	test   %eax,%eax
80106e28:	0f 94 c2             	sete   %dl
80106e2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e2e:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106e31:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e34:	83 e0 01             	and    $0x1,%eax
80106e37:	84 c0                	test   %al,%al
80106e39:	75 0a                	jne    80106e45 <fileopen+0x120>
80106e3b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e3e:	83 e0 02             	and    $0x2,%eax
80106e41:	85 c0                	test   %eax,%eax
80106e43:	74 07                	je     80106e4c <fileopen+0x127>
80106e45:	b8 01 00 00 00       	mov    $0x1,%eax
80106e4a:	eb 05                	jmp    80106e51 <fileopen+0x12c>
80106e4c:	b8 00 00 00 00       	mov    $0x0,%eax
80106e51:	89 c2                	mov    %eax,%edx
80106e53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e56:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80106e59:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106e5c:	c9                   	leave  
80106e5d:	c3                   	ret    

80106e5e <sys_open>:

int
sys_open(void)
{
80106e5e:	55                   	push   %ebp
80106e5f:	89 e5                	mov    %esp,%ebp
80106e61:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106e64:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106e67:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e6b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e72:	e8 69 f5 ff ff       	call   801063e0 <argstr>
80106e77:	85 c0                	test   %eax,%eax
80106e79:	78 17                	js     80106e92 <sys_open+0x34>
80106e7b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106e7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e82:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106e89:	e8 b8 f4 ff ff       	call   80106346 <argint>
80106e8e:	85 c0                	test   %eax,%eax
80106e90:	79 0a                	jns    80106e9c <sys_open+0x3e>
    return -1;
80106e92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e97:	e9 46 01 00 00       	jmp    80106fe2 <sys_open+0x184>
  if(omode & O_CREATE){
80106e9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106e9f:	25 00 02 00 00       	and    $0x200,%eax
80106ea4:	85 c0                	test   %eax,%eax
80106ea6:	74 40                	je     80106ee8 <sys_open+0x8a>
    begin_trans();
80106ea8:	e8 74 d5 ff ff       	call   80104421 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80106ead:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106eb0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106eb7:	00 
80106eb8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106ebf:	00 
80106ec0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106ec7:	00 
80106ec8:	89 04 24             	mov    %eax,(%esp)
80106ecb:	e8 95 fc ff ff       	call   80106b65 <create>
80106ed0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80106ed3:	e8 92 d5 ff ff       	call   8010446a <commit_trans>
    if(ip == 0)
80106ed8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106edc:	75 5c                	jne    80106f3a <sys_open+0xdc>
      return -1;
80106ede:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ee3:	e9 fa 00 00 00       	jmp    80106fe2 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106ee8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106eeb:	89 04 24             	mov    %eax,(%esp)
80106eee:	e8 08 c4 ff ff       	call   801032fb <namei>
80106ef3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106ef6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106efa:	75 0a                	jne    80106f06 <sys_open+0xa8>
      return -1;
80106efc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f01:	e9 dc 00 00 00       	jmp    80106fe2 <sys_open+0x184>
    ilock(ip);
80106f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f09:	89 04 24             	mov    %eax,(%esp)
80106f0c:	e8 5f b7 ff ff       	call   80102670 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106f11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f14:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106f18:	66 83 f8 01          	cmp    $0x1,%ax
80106f1c:	75 1c                	jne    80106f3a <sys_open+0xdc>
80106f1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106f21:	85 c0                	test   %eax,%eax
80106f23:	74 15                	je     80106f3a <sys_open+0xdc>
      iunlockput(ip);
80106f25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f28:	89 04 24             	mov    %eax,(%esp)
80106f2b:	e8 c4 b9 ff ff       	call   801028f4 <iunlockput>
      return -1;
80106f30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f35:	e9 a8 00 00 00       	jmp    80106fe2 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106f3a:	e8 dd 9f ff ff       	call   80100f1c <filealloc>
80106f3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106f42:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f46:	74 14                	je     80106f5c <sys_open+0xfe>
80106f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f4b:	89 04 24             	mov    %eax,(%esp)
80106f4e:	e8 0a f6 ff ff       	call   8010655d <fdalloc>
80106f53:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106f56:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106f5a:	79 23                	jns    80106f7f <sys_open+0x121>
    if(f)
80106f5c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106f60:	74 0b                	je     80106f6d <sys_open+0x10f>
      fileclose(f);
80106f62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f65:	89 04 24             	mov    %eax,(%esp)
80106f68:	e8 57 a0 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80106f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f70:	89 04 24             	mov    %eax,(%esp)
80106f73:	e8 7c b9 ff ff       	call   801028f4 <iunlockput>
    return -1;
80106f78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f7d:	eb 63                	jmp    80106fe2 <sys_open+0x184>
  }
  iunlock(ip);
80106f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f82:	89 04 24             	mov    %eax,(%esp)
80106f85:	e8 34 b8 ff ff       	call   801027be <iunlock>

  f->type = FD_INODE;
80106f8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f8d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106f93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f96:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106f99:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106f9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9f:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106fa6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fa9:	83 e0 01             	and    $0x1,%eax
80106fac:	85 c0                	test   %eax,%eax
80106fae:	0f 94 c2             	sete   %dl
80106fb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fb4:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106fb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fba:	83 e0 01             	and    $0x1,%eax
80106fbd:	84 c0                	test   %al,%al
80106fbf:	75 0a                	jne    80106fcb <sys_open+0x16d>
80106fc1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106fc4:	83 e0 02             	and    $0x2,%eax
80106fc7:	85 c0                	test   %eax,%eax
80106fc9:	74 07                	je     80106fd2 <sys_open+0x174>
80106fcb:	b8 01 00 00 00       	mov    $0x1,%eax
80106fd0:	eb 05                	jmp    80106fd7 <sys_open+0x179>
80106fd2:	b8 00 00 00 00       	mov    $0x0,%eax
80106fd7:	89 c2                	mov    %eax,%edx
80106fd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106fdc:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106fdf:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106fe2:	c9                   	leave  
80106fe3:	c3                   	ret    

80106fe4 <sys_mkdir>:

int
sys_mkdir(void)
{
80106fe4:	55                   	push   %ebp
80106fe5:	89 e5                	mov    %esp,%ebp
80106fe7:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106fea:	e8 32 d4 ff ff       	call   80104421 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106fef:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ff2:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ff6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ffd:	e8 de f3 ff ff       	call   801063e0 <argstr>
80107002:	85 c0                	test   %eax,%eax
80107004:	78 2c                	js     80107032 <sys_mkdir+0x4e>
80107006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107009:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80107010:	00 
80107011:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107018:	00 
80107019:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107020:	00 
80107021:	89 04 24             	mov    %eax,(%esp)
80107024:	e8 3c fb ff ff       	call   80106b65 <create>
80107029:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010702c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107030:	75 0c                	jne    8010703e <sys_mkdir+0x5a>
    commit_trans();
80107032:	e8 33 d4 ff ff       	call   8010446a <commit_trans>
    return -1;
80107037:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010703c:	eb 15                	jmp    80107053 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
8010703e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107041:	89 04 24             	mov    %eax,(%esp)
80107044:	e8 ab b8 ff ff       	call   801028f4 <iunlockput>
  commit_trans();
80107049:	e8 1c d4 ff ff       	call   8010446a <commit_trans>
  return 0;
8010704e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107053:	c9                   	leave  
80107054:	c3                   	ret    

80107055 <sys_mknod>:

int
sys_mknod(void)
{
80107055:	55                   	push   %ebp
80107056:	89 e5                	mov    %esp,%ebp
80107058:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
8010705b:	e8 c1 d3 ff ff       	call   80104421 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80107060:	8d 45 ec             	lea    -0x14(%ebp),%eax
80107063:	89 44 24 04          	mov    %eax,0x4(%esp)
80107067:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010706e:	e8 6d f3 ff ff       	call   801063e0 <argstr>
80107073:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107076:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010707a:	78 5e                	js     801070da <sys_mknod+0x85>
     argint(1, &major) < 0 ||
8010707c:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010707f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107083:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010708a:	e8 b7 f2 ff ff       	call   80106346 <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
8010708f:	85 c0                	test   %eax,%eax
80107091:	78 47                	js     801070da <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80107093:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80107096:	89 44 24 04          	mov    %eax,0x4(%esp)
8010709a:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801070a1:	e8 a0 f2 ff ff       	call   80106346 <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801070a6:	85 c0                	test   %eax,%eax
801070a8:	78 30                	js     801070da <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801070aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801070ad:	0f bf c8             	movswl %ax,%ecx
801070b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801070b3:	0f bf d0             	movswl %ax,%edx
801070b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801070b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801070bd:	89 54 24 08          	mov    %edx,0x8(%esp)
801070c1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801070c8:	00 
801070c9:	89 04 24             	mov    %eax,(%esp)
801070cc:	e8 94 fa ff ff       	call   80106b65 <create>
801070d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801070d4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801070d8:	75 0c                	jne    801070e6 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
801070da:	e8 8b d3 ff ff       	call   8010446a <commit_trans>
    return -1;
801070df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801070e4:	eb 15                	jmp    801070fb <sys_mknod+0xa6>
  }
  iunlockput(ip);
801070e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070e9:	89 04 24             	mov    %eax,(%esp)
801070ec:	e8 03 b8 ff ff       	call   801028f4 <iunlockput>
  commit_trans();
801070f1:	e8 74 d3 ff ff       	call   8010446a <commit_trans>
  return 0;
801070f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070fb:	c9                   	leave  
801070fc:	c3                   	ret    

801070fd <sys_chdir>:

int
sys_chdir(void)
{
801070fd:	55                   	push   %ebp
801070fe:	89 e5                	mov    %esp,%ebp
80107100:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80107103:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107106:	89 44 24 04          	mov    %eax,0x4(%esp)
8010710a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107111:	e8 ca f2 ff ff       	call   801063e0 <argstr>
80107116:	85 c0                	test   %eax,%eax
80107118:	78 14                	js     8010712e <sys_chdir+0x31>
8010711a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010711d:	89 04 24             	mov    %eax,(%esp)
80107120:	e8 d6 c1 ff ff       	call   801032fb <namei>
80107125:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107128:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010712c:	75 07                	jne    80107135 <sys_chdir+0x38>
    return -1;
8010712e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107133:	eb 57                	jmp    8010718c <sys_chdir+0x8f>
  ilock(ip);
80107135:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107138:	89 04 24             	mov    %eax,(%esp)
8010713b:	e8 30 b5 ff ff       	call   80102670 <ilock>
  if(ip->type != T_DIR){
80107140:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107143:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80107147:	66 83 f8 01          	cmp    $0x1,%ax
8010714b:	74 12                	je     8010715f <sys_chdir+0x62>
    iunlockput(ip);
8010714d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107150:	89 04 24             	mov    %eax,(%esp)
80107153:	e8 9c b7 ff ff       	call   801028f4 <iunlockput>
    return -1;
80107158:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010715d:	eb 2d                	jmp    8010718c <sys_chdir+0x8f>
  }
  iunlock(ip);
8010715f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107162:	89 04 24             	mov    %eax,(%esp)
80107165:	e8 54 b6 ff ff       	call   801027be <iunlock>
  iput(proc->cwd);
8010716a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107170:	8b 40 68             	mov    0x68(%eax),%eax
80107173:	89 04 24             	mov    %eax,(%esp)
80107176:	e8 a8 b6 ff ff       	call   80102823 <iput>
  proc->cwd = ip;
8010717b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107181:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107184:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80107187:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010718c:	c9                   	leave  
8010718d:	c3                   	ret    

8010718e <sys_exec>:

int
sys_exec(void)
{
8010718e:	55                   	push   %ebp
8010718f:	89 e5                	mov    %esp,%ebp
80107191:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80107197:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010719a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010719e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801071a5:	e8 36 f2 ff ff       	call   801063e0 <argstr>
801071aa:	85 c0                	test   %eax,%eax
801071ac:	78 1a                	js     801071c8 <sys_exec+0x3a>
801071ae:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801071b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801071b8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801071bf:	e8 82 f1 ff ff       	call   80106346 <argint>
801071c4:	85 c0                	test   %eax,%eax
801071c6:	79 0a                	jns    801071d2 <sys_exec+0x44>
    return -1;
801071c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071cd:	e9 e2 00 00 00       	jmp    801072b4 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
801071d2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801071d9:	00 
801071da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801071e1:	00 
801071e2:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801071e8:	89 04 24             	mov    %eax,(%esp)
801071eb:	e8 06 ee ff ff       	call   80105ff6 <memset>
  for(i=0;; i++){
801071f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801071f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801071fa:	83 f8 1f             	cmp    $0x1f,%eax
801071fd:	76 0a                	jbe    80107209 <sys_exec+0x7b>
      return -1;
801071ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107204:	e9 ab 00 00 00       	jmp    801072b4 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80107209:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010720c:	c1 e0 02             	shl    $0x2,%eax
8010720f:	89 c2                	mov    %eax,%edx
80107211:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80107217:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
8010721a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107220:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80107226:	89 54 24 08          	mov    %edx,0x8(%esp)
8010722a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010722e:	89 04 24             	mov    %eax,(%esp)
80107231:	e8 7e f0 ff ff       	call   801062b4 <fetchint>
80107236:	85 c0                	test   %eax,%eax
80107238:	79 07                	jns    80107241 <sys_exec+0xb3>
      return -1;
8010723a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010723f:	eb 73                	jmp    801072b4 <sys_exec+0x126>
    if(uarg == 0){
80107241:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80107247:	85 c0                	test   %eax,%eax
80107249:	75 26                	jne    80107271 <sys_exec+0xe3>
      argv[i] = 0;
8010724b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010724e:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80107255:	00 00 00 00 
      break;
80107259:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
8010725a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010725d:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80107263:	89 54 24 04          	mov    %edx,0x4(%esp)
80107267:	89 04 24             	mov    %eax,(%esp)
8010726a:	e8 8d 98 ff ff       	call   80100afc <exec>
8010726f:	eb 43                	jmp    801072b4 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80107271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107274:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010727b:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80107281:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80107284:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
8010728a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107290:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107294:	89 54 24 04          	mov    %edx,0x4(%esp)
80107298:	89 04 24             	mov    %eax,(%esp)
8010729b:	e8 48 f0 ff ff       	call   801062e8 <fetchstr>
801072a0:	85 c0                	test   %eax,%eax
801072a2:	79 07                	jns    801072ab <sys_exec+0x11d>
      return -1;
801072a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072a9:	eb 09                	jmp    801072b4 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801072ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801072af:	e9 43 ff ff ff       	jmp    801071f7 <sys_exec+0x69>
  return exec(path, argv);
}
801072b4:	c9                   	leave  
801072b5:	c3                   	ret    

801072b6 <sys_pipe>:

int
sys_pipe(void)
{
801072b6:	55                   	push   %ebp
801072b7:	89 e5                	mov    %esp,%ebp
801072b9:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801072bc:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801072c3:	00 
801072c4:	8d 45 ec             	lea    -0x14(%ebp),%eax
801072c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801072cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801072d2:	e8 a7 f0 ff ff       	call   8010637e <argptr>
801072d7:	85 c0                	test   %eax,%eax
801072d9:	79 0a                	jns    801072e5 <sys_pipe+0x2f>
    return -1;
801072db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801072e0:	e9 9b 00 00 00       	jmp    80107380 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801072e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801072e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801072ec:	8d 45 e8             	lea    -0x18(%ebp),%eax
801072ef:	89 04 24             	mov    %eax,(%esp)
801072f2:	e8 45 db ff ff       	call   80104e3c <pipealloc>
801072f7:	85 c0                	test   %eax,%eax
801072f9:	79 07                	jns    80107302 <sys_pipe+0x4c>
    return -1;
801072fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107300:	eb 7e                	jmp    80107380 <sys_pipe+0xca>
  fd0 = -1;
80107302:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80107309:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010730c:	89 04 24             	mov    %eax,(%esp)
8010730f:	e8 49 f2 ff ff       	call   8010655d <fdalloc>
80107314:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107317:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010731b:	78 14                	js     80107331 <sys_pipe+0x7b>
8010731d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107320:	89 04 24             	mov    %eax,(%esp)
80107323:	e8 35 f2 ff ff       	call   8010655d <fdalloc>
80107328:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010732b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010732f:	79 37                	jns    80107368 <sys_pipe+0xb2>
    if(fd0 >= 0)
80107331:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107335:	78 14                	js     8010734b <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80107337:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010733d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107340:	83 c2 08             	add    $0x8,%edx
80107343:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010734a:	00 
    fileclose(rf);
8010734b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010734e:	89 04 24             	mov    %eax,(%esp)
80107351:	e8 6e 9c ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
80107356:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107359:	89 04 24             	mov    %eax,(%esp)
8010735c:	e8 63 9c ff ff       	call   80100fc4 <fileclose>
    return -1;
80107361:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107366:	eb 18                	jmp    80107380 <sys_pipe+0xca>
  }
  fd[0] = fd0;
80107368:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010736b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010736e:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
80107370:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107373:	8d 50 04             	lea    0x4(%eax),%edx
80107376:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107379:	89 02                	mov    %eax,(%edx)
  return 0;
8010737b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107380:	c9                   	leave  
80107381:	c3                   	ret    
	...

80107384 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80107384:	55                   	push   %ebp
80107385:	89 e5                	mov    %esp,%ebp
80107387:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010738a:	e8 67 e1 ff ff       	call   801054f6 <fork>
}
8010738f:	c9                   	leave  
80107390:	c3                   	ret    

80107391 <sys_exit>:

int
sys_exit(void)
{
80107391:	55                   	push   %ebp
80107392:	89 e5                	mov    %esp,%ebp
80107394:	83 ec 08             	sub    $0x8,%esp
  exit();
80107397:	e8 bd e2 ff ff       	call   80105659 <exit>
  return 0;  // not reached
8010739c:	b8 00 00 00 00       	mov    $0x0,%eax
}
801073a1:	c9                   	leave  
801073a2:	c3                   	ret    

801073a3 <sys_wait>:

int
sys_wait(void)
{
801073a3:	55                   	push   %ebp
801073a4:	89 e5                	mov    %esp,%ebp
801073a6:	83 ec 08             	sub    $0x8,%esp
  return wait();
801073a9:	e8 c3 e3 ff ff       	call   80105771 <wait>
}
801073ae:	c9                   	leave  
801073af:	c3                   	ret    

801073b0 <sys_kill>:

int
sys_kill(void)
{
801073b0:	55                   	push   %ebp
801073b1:	89 e5                	mov    %esp,%ebp
801073b3:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801073b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801073b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801073bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801073c4:	e8 7d ef ff ff       	call   80106346 <argint>
801073c9:	85 c0                	test   %eax,%eax
801073cb:	79 07                	jns    801073d4 <sys_kill+0x24>
    return -1;
801073cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801073d2:	eb 0b                	jmp    801073df <sys_kill+0x2f>
  return kill(pid);
801073d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073d7:	89 04 24             	mov    %eax,(%esp)
801073da:	e8 ee e7 ff ff       	call   80105bcd <kill>
}
801073df:	c9                   	leave  
801073e0:	c3                   	ret    

801073e1 <sys_getpid>:

int
sys_getpid(void)
{
801073e1:	55                   	push   %ebp
801073e2:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801073e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801073ea:	8b 40 10             	mov    0x10(%eax),%eax
}
801073ed:	5d                   	pop    %ebp
801073ee:	c3                   	ret    

801073ef <sys_sbrk>:

int
sys_sbrk(void)
{
801073ef:	55                   	push   %ebp
801073f0:	89 e5                	mov    %esp,%ebp
801073f2:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801073f5:	8d 45 f0             	lea    -0x10(%ebp),%eax
801073f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801073fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107403:	e8 3e ef ff ff       	call   80106346 <argint>
80107408:	85 c0                	test   %eax,%eax
8010740a:	79 07                	jns    80107413 <sys_sbrk+0x24>
    return -1;
8010740c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107411:	eb 24                	jmp    80107437 <sys_sbrk+0x48>
  addr = proc->sz;
80107413:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107419:	8b 00                	mov    (%eax),%eax
8010741b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010741e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107421:	89 04 24             	mov    %eax,(%esp)
80107424:	e8 28 e0 ff ff       	call   80105451 <growproc>
80107429:	85 c0                	test   %eax,%eax
8010742b:	79 07                	jns    80107434 <sys_sbrk+0x45>
    return -1;
8010742d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107432:	eb 03                	jmp    80107437 <sys_sbrk+0x48>
  return addr;
80107434:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107437:	c9                   	leave  
80107438:	c3                   	ret    

80107439 <sys_sleep>:

int
sys_sleep(void)
{
80107439:	55                   	push   %ebp
8010743a:	89 e5                	mov    %esp,%ebp
8010743c:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010743f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107442:	89 44 24 04          	mov    %eax,0x4(%esp)
80107446:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010744d:	e8 f4 ee ff ff       	call   80106346 <argint>
80107452:	85 c0                	test   %eax,%eax
80107454:	79 07                	jns    8010745d <sys_sleep+0x24>
    return -1;
80107456:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010745b:	eb 6c                	jmp    801074c9 <sys_sleep+0x90>
  acquire(&tickslock);
8010745d:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107464:	e8 3e e9 ff ff       	call   80105da7 <acquire>
  ticks0 = ticks;
80107469:	a1 e0 36 11 80       	mov    0x801136e0,%eax
8010746e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80107471:	eb 34                	jmp    801074a7 <sys_sleep+0x6e>
    if(proc->killed){
80107473:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107479:	8b 40 24             	mov    0x24(%eax),%eax
8010747c:	85 c0                	test   %eax,%eax
8010747e:	74 13                	je     80107493 <sys_sleep+0x5a>
      release(&tickslock);
80107480:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107487:	e8 7d e9 ff ff       	call   80105e09 <release>
      return -1;
8010748c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107491:	eb 36                	jmp    801074c9 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80107493:	c7 44 24 04 a0 2e 11 	movl   $0x80112ea0,0x4(%esp)
8010749a:	80 
8010749b:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
801074a2:	e8 22 e6 ff ff       	call   80105ac9 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801074a7:	a1 e0 36 11 80       	mov    0x801136e0,%eax
801074ac:	89 c2                	mov    %eax,%edx
801074ae:	2b 55 f4             	sub    -0xc(%ebp),%edx
801074b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801074b4:	39 c2                	cmp    %eax,%edx
801074b6:	72 bb                	jb     80107473 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801074b8:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801074bf:	e8 45 e9 ff ff       	call   80105e09 <release>
  return 0;
801074c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801074c9:	c9                   	leave  
801074ca:	c3                   	ret    

801074cb <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801074cb:	55                   	push   %ebp
801074cc:	89 e5                	mov    %esp,%ebp
801074ce:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801074d1:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801074d8:	e8 ca e8 ff ff       	call   80105da7 <acquire>
  xticks = ticks;
801074dd:	a1 e0 36 11 80       	mov    0x801136e0,%eax
801074e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801074e5:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
801074ec:	e8 18 e9 ff ff       	call   80105e09 <release>
  return xticks;
801074f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801074f4:	c9                   	leave  
801074f5:	c3                   	ret    

801074f6 <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
801074f6:	55                   	push   %ebp
801074f7:	89 e5                	mov    %esp,%ebp
801074f9:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
801074fc:	8d 45 f4             	lea    -0xc(%ebp),%eax
801074ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80107503:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010750a:	e8 d1 ee ff ff       	call   801063e0 <argstr>
8010750f:	85 c0                	test   %eax,%eax
80107511:	79 07                	jns    8010751a <sys_getFileBlocks+0x24>
    return -1;
80107513:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107518:	eb 0b                	jmp    80107525 <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
8010751a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010751d:	89 04 24             	mov    %eax,(%esp)
80107520:	e8 c5 9d ff ff       	call   801012ea <getFileBlocks>
}
80107525:	c9                   	leave  
80107526:	c3                   	ret    

80107527 <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
80107527:	55                   	push   %ebp
80107528:	89 e5                	mov    %esp,%ebp
8010752a:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
8010752d:	e8 15 9f ff ff       	call   80101447 <getFreeBlocks>
}
80107532:	c9                   	leave  
80107533:	c3                   	ret    

80107534 <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
80107534:	55                   	push   %ebp
80107535:	89 e5                	mov    %esp,%ebp
80107537:	83 ec 08             	sub    $0x8,%esp
  return getSharedBlocksRate();
8010753a:	e8 87 a9 ff ff       	call   80101ec6 <getSharedBlocksRate>
}
8010753f:	c9                   	leave  
80107540:	c3                   	ret    

80107541 <sys_dedup>:

int
sys_dedup(void)
{
80107541:	55                   	push   %ebp
80107542:	89 e5                	mov    %esp,%ebp
80107544:	83 ec 08             	sub    $0x8,%esp
  return dedup();
80107547:	e8 3d a1 ff ff       	call   80101689 <dedup>
}
8010754c:	c9                   	leave  
8010754d:	c3                   	ret    
	...

80107550 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107550:	55                   	push   %ebp
80107551:	89 e5                	mov    %esp,%ebp
80107553:	83 ec 08             	sub    $0x8,%esp
80107556:	8b 55 08             	mov    0x8(%ebp),%edx
80107559:	8b 45 0c             	mov    0xc(%ebp),%eax
8010755c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107560:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107563:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107567:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010756b:	ee                   	out    %al,(%dx)
}
8010756c:	c9                   	leave  
8010756d:	c3                   	ret    

8010756e <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010756e:	55                   	push   %ebp
8010756f:	89 e5                	mov    %esp,%ebp
80107571:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80107574:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010757b:	00 
8010757c:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80107583:	e8 c8 ff ff ff       	call   80107550 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80107588:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010758f:	00 
80107590:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107597:	e8 b4 ff ff ff       	call   80107550 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
8010759c:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801075a3:	00 
801075a4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801075ab:	e8 a0 ff ff ff       	call   80107550 <outb>
  picenable(IRQ_TIMER);
801075b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801075b7:	e8 09 d7 ff ff       	call   80104cc5 <picenable>
}
801075bc:	c9                   	leave  
801075bd:	c3                   	ret    
	...

801075c0 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801075c0:	1e                   	push   %ds
  pushl %es
801075c1:	06                   	push   %es
  pushl %fs
801075c2:	0f a0                	push   %fs
  pushl %gs
801075c4:	0f a8                	push   %gs
  pushal
801075c6:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801075c7:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801075cb:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801075cd:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801075cf:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801075d3:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801075d5:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801075d7:	54                   	push   %esp
  call trap
801075d8:	e8 de 01 00 00       	call   801077bb <trap>
  addl $4, %esp
801075dd:	83 c4 04             	add    $0x4,%esp

801075e0 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801075e0:	61                   	popa   
  popl %gs
801075e1:	0f a9                	pop    %gs
  popl %fs
801075e3:	0f a1                	pop    %fs
  popl %es
801075e5:	07                   	pop    %es
  popl %ds
801075e6:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801075e7:	83 c4 08             	add    $0x8,%esp
  iret
801075ea:	cf                   	iret   
	...

801075ec <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801075ec:	55                   	push   %ebp
801075ed:	89 e5                	mov    %esp,%ebp
801075ef:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801075f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801075f5:	83 e8 01             	sub    $0x1,%eax
801075f8:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801075fc:	8b 45 08             	mov    0x8(%ebp),%eax
801075ff:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107603:	8b 45 08             	mov    0x8(%ebp),%eax
80107606:	c1 e8 10             	shr    $0x10,%eax
80107609:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010760d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107610:	0f 01 18             	lidtl  (%eax)
}
80107613:	c9                   	leave  
80107614:	c3                   	ret    

80107615 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80107615:	55                   	push   %ebp
80107616:	89 e5                	mov    %esp,%ebp
80107618:	53                   	push   %ebx
80107619:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010761c:	0f 20 d3             	mov    %cr2,%ebx
8010761f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80107622:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80107625:	83 c4 10             	add    $0x10,%esp
80107628:	5b                   	pop    %ebx
80107629:	5d                   	pop    %ebp
8010762a:	c3                   	ret    

8010762b <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010762b:	55                   	push   %ebp
8010762c:	89 e5                	mov    %esp,%ebp
8010762e:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107631:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107638:	e9 c3 00 00 00       	jmp    80107700 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010763d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107640:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
80107647:	89 c2                	mov    %eax,%edx
80107649:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764c:	66 89 14 c5 e0 2e 11 	mov    %dx,-0x7feed120(,%eax,8)
80107653:	80 
80107654:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107657:	66 c7 04 c5 e2 2e 11 	movw   $0x8,-0x7feed11e(,%eax,8)
8010765e:	80 08 00 
80107661:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107664:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
8010766b:	80 
8010766c:	83 e2 e0             	and    $0xffffffe0,%edx
8010766f:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
80107676:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107679:	0f b6 14 c5 e4 2e 11 	movzbl -0x7feed11c(,%eax,8),%edx
80107680:	80 
80107681:	83 e2 1f             	and    $0x1f,%edx
80107684:	88 14 c5 e4 2e 11 80 	mov    %dl,-0x7feed11c(,%eax,8)
8010768b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010768e:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
80107695:	80 
80107696:	83 e2 f0             	and    $0xfffffff0,%edx
80107699:	83 ca 0e             	or     $0xe,%edx
8010769c:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
801076a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a6:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
801076ad:	80 
801076ae:	83 e2 ef             	and    $0xffffffef,%edx
801076b1:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
801076b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076bb:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
801076c2:	80 
801076c3:	83 e2 9f             	and    $0xffffff9f,%edx
801076c6:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
801076cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d0:	0f b6 14 c5 e5 2e 11 	movzbl -0x7feed11b(,%eax,8),%edx
801076d7:	80 
801076d8:	83 ca 80             	or     $0xffffff80,%edx
801076db:	88 14 c5 e5 2e 11 80 	mov    %dl,-0x7feed11b(,%eax,8)
801076e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e5:	8b 04 85 a8 c0 10 80 	mov    -0x7fef3f58(,%eax,4),%eax
801076ec:	c1 e8 10             	shr    $0x10,%eax
801076ef:	89 c2                	mov    %eax,%edx
801076f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f4:	66 89 14 c5 e6 2e 11 	mov    %dx,-0x7feed11a(,%eax,8)
801076fb:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801076fc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107700:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80107707:	0f 8e 30 ff ff ff    	jle    8010763d <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010770d:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107712:	66 a3 e0 30 11 80    	mov    %ax,0x801130e0
80107718:	66 c7 05 e2 30 11 80 	movw   $0x8,0x801130e2
8010771f:	08 00 
80107721:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
80107728:	83 e0 e0             	and    $0xffffffe0,%eax
8010772b:	a2 e4 30 11 80       	mov    %al,0x801130e4
80107730:	0f b6 05 e4 30 11 80 	movzbl 0x801130e4,%eax
80107737:	83 e0 1f             	and    $0x1f,%eax
8010773a:	a2 e4 30 11 80       	mov    %al,0x801130e4
8010773f:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107746:	83 c8 0f             	or     $0xf,%eax
80107749:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010774e:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107755:	83 e0 ef             	and    $0xffffffef,%eax
80107758:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010775d:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107764:	83 c8 60             	or     $0x60,%eax
80107767:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010776c:	0f b6 05 e5 30 11 80 	movzbl 0x801130e5,%eax
80107773:	83 c8 80             	or     $0xffffff80,%eax
80107776:	a2 e5 30 11 80       	mov    %al,0x801130e5
8010777b:	a1 a8 c1 10 80       	mov    0x8010c1a8,%eax
80107780:	c1 e8 10             	shr    $0x10,%eax
80107783:	66 a3 e6 30 11 80    	mov    %ax,0x801130e6
  
  initlock(&tickslock, "time");
80107789:	c7 44 24 04 58 9a 10 	movl   $0x80109a58,0x4(%esp)
80107790:	80 
80107791:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107798:	e8 e9 e5 ff ff       	call   80105d86 <initlock>
}
8010779d:	c9                   	leave  
8010779e:	c3                   	ret    

8010779f <idtinit>:

void
idtinit(void)
{
8010779f:	55                   	push   %ebp
801077a0:	89 e5                	mov    %esp,%ebp
801077a2:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801077a5:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801077ac:	00 
801077ad:	c7 04 24 e0 2e 11 80 	movl   $0x80112ee0,(%esp)
801077b4:	e8 33 fe ff ff       	call   801075ec <lidt>
}
801077b9:	c9                   	leave  
801077ba:	c3                   	ret    

801077bb <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801077bb:	55                   	push   %ebp
801077bc:	89 e5                	mov    %esp,%ebp
801077be:	57                   	push   %edi
801077bf:	56                   	push   %esi
801077c0:	53                   	push   %ebx
801077c1:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801077c4:	8b 45 08             	mov    0x8(%ebp),%eax
801077c7:	8b 40 30             	mov    0x30(%eax),%eax
801077ca:	83 f8 40             	cmp    $0x40,%eax
801077cd:	75 3e                	jne    8010780d <trap+0x52>
    if(proc->killed)
801077cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801077d5:	8b 40 24             	mov    0x24(%eax),%eax
801077d8:	85 c0                	test   %eax,%eax
801077da:	74 05                	je     801077e1 <trap+0x26>
      exit();
801077dc:	e8 78 de ff ff       	call   80105659 <exit>
    proc->tf = tf;
801077e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801077e7:	8b 55 08             	mov    0x8(%ebp),%edx
801077ea:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801077ed:	e8 31 ec ff ff       	call   80106423 <syscall>
    if(proc->killed)
801077f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801077f8:	8b 40 24             	mov    0x24(%eax),%eax
801077fb:	85 c0                	test   %eax,%eax
801077fd:	0f 84 34 02 00 00    	je     80107a37 <trap+0x27c>
      exit();
80107803:	e8 51 de ff ff       	call   80105659 <exit>
    return;
80107808:	e9 2a 02 00 00       	jmp    80107a37 <trap+0x27c>
  }

  switch(tf->trapno){
8010780d:	8b 45 08             	mov    0x8(%ebp),%eax
80107810:	8b 40 30             	mov    0x30(%eax),%eax
80107813:	83 e8 20             	sub    $0x20,%eax
80107816:	83 f8 1f             	cmp    $0x1f,%eax
80107819:	0f 87 bc 00 00 00    	ja     801078db <trap+0x120>
8010781f:	8b 04 85 00 9b 10 80 	mov    -0x7fef6500(,%eax,4),%eax
80107826:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80107828:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010782e:	0f b6 00             	movzbl (%eax),%eax
80107831:	84 c0                	test   %al,%al
80107833:	75 31                	jne    80107866 <trap+0xab>
      acquire(&tickslock);
80107835:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
8010783c:	e8 66 e5 ff ff       	call   80105da7 <acquire>
      ticks++;
80107841:	a1 e0 36 11 80       	mov    0x801136e0,%eax
80107846:	83 c0 01             	add    $0x1,%eax
80107849:	a3 e0 36 11 80       	mov    %eax,0x801136e0
      wakeup(&ticks);
8010784e:	c7 04 24 e0 36 11 80 	movl   $0x801136e0,(%esp)
80107855:	e8 48 e3 ff ff       	call   80105ba2 <wakeup>
      release(&tickslock);
8010785a:	c7 04 24 a0 2e 11 80 	movl   $0x80112ea0,(%esp)
80107861:	e8 a3 e5 ff ff       	call   80105e09 <release>
    }
    lapiceoi();
80107866:	e8 82 c8 ff ff       	call   801040ed <lapiceoi>
    break;
8010786b:	e9 41 01 00 00       	jmp    801079b1 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107870:	e8 80 c0 ff ff       	call   801038f5 <ideintr>
    lapiceoi();
80107875:	e8 73 c8 ff ff       	call   801040ed <lapiceoi>
    break;
8010787a:	e9 32 01 00 00       	jmp    801079b1 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010787f:	e8 47 c6 ff ff       	call   80103ecb <kbdintr>
    lapiceoi();
80107884:	e8 64 c8 ff ff       	call   801040ed <lapiceoi>
    break;
80107889:	e9 23 01 00 00       	jmp    801079b1 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010788e:	e8 a9 03 00 00       	call   80107c3c <uartintr>
    lapiceoi();
80107893:	e8 55 c8 ff ff       	call   801040ed <lapiceoi>
    break;
80107898:	e9 14 01 00 00       	jmp    801079b1 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
8010789d:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801078a0:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801078a3:	8b 45 08             	mov    0x8(%ebp),%eax
801078a6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801078aa:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801078ad:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801078b3:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801078b6:	0f b6 c0             	movzbl %al,%eax
801078b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801078bd:	89 54 24 08          	mov    %edx,0x8(%esp)
801078c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801078c5:	c7 04 24 60 9a 10 80 	movl   $0x80109a60,(%esp)
801078cc:	e8 d0 8a ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801078d1:	e8 17 c8 ff ff       	call   801040ed <lapiceoi>
    break;
801078d6:	e9 d6 00 00 00       	jmp    801079b1 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801078db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801078e1:	85 c0                	test   %eax,%eax
801078e3:	74 11                	je     801078f6 <trap+0x13b>
801078e5:	8b 45 08             	mov    0x8(%ebp),%eax
801078e8:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801078ec:	0f b7 c0             	movzwl %ax,%eax
801078ef:	83 e0 03             	and    $0x3,%eax
801078f2:	85 c0                	test   %eax,%eax
801078f4:	75 46                	jne    8010793c <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801078f6:	e8 1a fd ff ff       	call   80107615 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
801078fb:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801078fe:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80107901:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107908:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010790b:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
8010790e:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80107911:	8b 52 30             	mov    0x30(%edx),%edx
80107914:	89 44 24 10          	mov    %eax,0x10(%esp)
80107918:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
8010791c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80107920:	89 54 24 04          	mov    %edx,0x4(%esp)
80107924:	c7 04 24 84 9a 10 80 	movl   $0x80109a84,(%esp)
8010792b:	e8 71 8a ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107930:	c7 04 24 b6 9a 10 80 	movl   $0x80109ab6,(%esp)
80107937:	e8 01 8c ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010793c:	e8 d4 fc ff ff       	call   80107615 <rcr2>
80107941:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107943:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107946:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107949:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010794f:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107952:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107955:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107958:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010795b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010795e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107961:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107967:	83 c0 6c             	add    $0x6c,%eax
8010796a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010796d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107973:	8b 40 10             	mov    0x10(%eax),%eax
80107976:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010797a:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010797e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107982:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107986:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010798a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010798d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107991:	89 44 24 04          	mov    %eax,0x4(%esp)
80107995:	c7 04 24 bc 9a 10 80 	movl   $0x80109abc,(%esp)
8010799c:	e8 00 8a ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801079a1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079a7:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801079ae:	eb 01                	jmp    801079b1 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801079b0:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801079b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079b7:	85 c0                	test   %eax,%eax
801079b9:	74 24                	je     801079df <trap+0x224>
801079bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079c1:	8b 40 24             	mov    0x24(%eax),%eax
801079c4:	85 c0                	test   %eax,%eax
801079c6:	74 17                	je     801079df <trap+0x224>
801079c8:	8b 45 08             	mov    0x8(%ebp),%eax
801079cb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801079cf:	0f b7 c0             	movzwl %ax,%eax
801079d2:	83 e0 03             	and    $0x3,%eax
801079d5:	83 f8 03             	cmp    $0x3,%eax
801079d8:	75 05                	jne    801079df <trap+0x224>
    exit();
801079da:	e8 7a dc ff ff       	call   80105659 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
801079df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079e5:	85 c0                	test   %eax,%eax
801079e7:	74 1e                	je     80107a07 <trap+0x24c>
801079e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801079ef:	8b 40 0c             	mov    0xc(%eax),%eax
801079f2:	83 f8 04             	cmp    $0x4,%eax
801079f5:	75 10                	jne    80107a07 <trap+0x24c>
801079f7:	8b 45 08             	mov    0x8(%ebp),%eax
801079fa:	8b 40 30             	mov    0x30(%eax),%eax
801079fd:	83 f8 20             	cmp    $0x20,%eax
80107a00:	75 05                	jne    80107a07 <trap+0x24c>
    yield();
80107a02:	e8 64 e0 ff ff       	call   80105a6b <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107a07:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a0d:	85 c0                	test   %eax,%eax
80107a0f:	74 27                	je     80107a38 <trap+0x27d>
80107a11:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107a17:	8b 40 24             	mov    0x24(%eax),%eax
80107a1a:	85 c0                	test   %eax,%eax
80107a1c:	74 1a                	je     80107a38 <trap+0x27d>
80107a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80107a21:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80107a25:	0f b7 c0             	movzwl %ax,%eax
80107a28:	83 e0 03             	and    $0x3,%eax
80107a2b:	83 f8 03             	cmp    $0x3,%eax
80107a2e:	75 08                	jne    80107a38 <trap+0x27d>
    exit();
80107a30:	e8 24 dc ff ff       	call   80105659 <exit>
80107a35:	eb 01                	jmp    80107a38 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80107a37:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80107a38:	83 c4 3c             	add    $0x3c,%esp
80107a3b:	5b                   	pop    %ebx
80107a3c:	5e                   	pop    %esi
80107a3d:	5f                   	pop    %edi
80107a3e:	5d                   	pop    %ebp
80107a3f:	c3                   	ret    

80107a40 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80107a40:	55                   	push   %ebp
80107a41:	89 e5                	mov    %esp,%ebp
80107a43:	53                   	push   %ebx
80107a44:	83 ec 14             	sub    $0x14,%esp
80107a47:	8b 45 08             	mov    0x8(%ebp),%eax
80107a4a:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80107a4e:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80107a52:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80107a56:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80107a5a:	ec                   	in     (%dx),%al
80107a5b:	89 c3                	mov    %eax,%ebx
80107a5d:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80107a60:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80107a64:	83 c4 14             	add    $0x14,%esp
80107a67:	5b                   	pop    %ebx
80107a68:	5d                   	pop    %ebp
80107a69:	c3                   	ret    

80107a6a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107a6a:	55                   	push   %ebp
80107a6b:	89 e5                	mov    %esp,%ebp
80107a6d:	83 ec 08             	sub    $0x8,%esp
80107a70:	8b 55 08             	mov    0x8(%ebp),%edx
80107a73:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a76:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107a7a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80107a7d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107a81:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107a85:	ee                   	out    %al,(%dx)
}
80107a86:	c9                   	leave  
80107a87:	c3                   	ret    

80107a88 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107a88:	55                   	push   %ebp
80107a89:	89 e5                	mov    %esp,%ebp
80107a8b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80107a8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a95:	00 
80107a96:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107a9d:	e8 c8 ff ff ff       	call   80107a6a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107aa2:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107aa9:	00 
80107aaa:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107ab1:	e8 b4 ff ff ff       	call   80107a6a <outb>
  outb(COM1+0, 115200/9600);
80107ab6:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80107abd:	00 
80107abe:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107ac5:	e8 a0 ff ff ff       	call   80107a6a <outb>
  outb(COM1+1, 0);
80107aca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ad1:	00 
80107ad2:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107ad9:	e8 8c ff ff ff       	call   80107a6a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80107ade:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80107ae5:	00 
80107ae6:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107aed:	e8 78 ff ff ff       	call   80107a6a <outb>
  outb(COM1+4, 0);
80107af2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107af9:	00 
80107afa:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80107b01:	e8 64 ff ff ff       	call   80107a6a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80107b06:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80107b0d:	00 
80107b0e:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107b15:	e8 50 ff ff ff       	call   80107a6a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80107b1a:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107b21:	e8 1a ff ff ff       	call   80107a40 <inb>
80107b26:	3c ff                	cmp    $0xff,%al
80107b28:	74 6c                	je     80107b96 <uartinit+0x10e>
    return;
  uart = 1;
80107b2a:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
80107b31:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80107b34:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80107b3b:	e8 00 ff ff ff       	call   80107a40 <inb>
  inb(COM1+0);
80107b40:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107b47:	e8 f4 fe ff ff       	call   80107a40 <inb>
  picenable(IRQ_COM1);
80107b4c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107b53:	e8 6d d1 ff ff       	call   80104cc5 <picenable>
  ioapicenable(IRQ_COM1, 0);
80107b58:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107b5f:	00 
80107b60:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107b67:	e8 0e c0 ff ff       	call   80103b7a <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107b6c:	c7 45 f4 80 9b 10 80 	movl   $0x80109b80,-0xc(%ebp)
80107b73:	eb 15                	jmp    80107b8a <uartinit+0x102>
    uartputc(*p);
80107b75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b78:	0f b6 00             	movzbl (%eax),%eax
80107b7b:	0f be c0             	movsbl %al,%eax
80107b7e:	89 04 24             	mov    %eax,(%esp)
80107b81:	e8 13 00 00 00       	call   80107b99 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107b86:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107b8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8d:	0f b6 00             	movzbl (%eax),%eax
80107b90:	84 c0                	test   %al,%al
80107b92:	75 e1                	jne    80107b75 <uartinit+0xed>
80107b94:	eb 01                	jmp    80107b97 <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80107b96:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80107b97:	c9                   	leave  
80107b98:	c3                   	ret    

80107b99 <uartputc>:

void
uartputc(int c)
{
80107b99:	55                   	push   %ebp
80107b9a:	89 e5                	mov    %esp,%ebp
80107b9c:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80107b9f:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107ba4:	85 c0                	test   %eax,%eax
80107ba6:	74 4d                	je     80107bf5 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107ba8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107baf:	eb 10                	jmp    80107bc1 <uartputc+0x28>
    microdelay(10);
80107bb1:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107bb8:	e8 55 c5 ff ff       	call   80104112 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107bbd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107bc1:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107bc5:	7f 16                	jg     80107bdd <uartputc+0x44>
80107bc7:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107bce:	e8 6d fe ff ff       	call   80107a40 <inb>
80107bd3:	0f b6 c0             	movzbl %al,%eax
80107bd6:	83 e0 20             	and    $0x20,%eax
80107bd9:	85 c0                	test   %eax,%eax
80107bdb:	74 d4                	je     80107bb1 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80107bdd:	8b 45 08             	mov    0x8(%ebp),%eax
80107be0:	0f b6 c0             	movzbl %al,%eax
80107be3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107be7:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107bee:	e8 77 fe ff ff       	call   80107a6a <outb>
80107bf3:	eb 01                	jmp    80107bf6 <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80107bf5:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80107bf6:	c9                   	leave  
80107bf7:	c3                   	ret    

80107bf8 <uartgetc>:

static int
uartgetc(void)
{
80107bf8:	55                   	push   %ebp
80107bf9:	89 e5                	mov    %esp,%ebp
80107bfb:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80107bfe:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107c03:	85 c0                	test   %eax,%eax
80107c05:	75 07                	jne    80107c0e <uartgetc+0x16>
    return -1;
80107c07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107c0c:	eb 2c                	jmp    80107c3a <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80107c0e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80107c15:	e8 26 fe ff ff       	call   80107a40 <inb>
80107c1a:	0f b6 c0             	movzbl %al,%eax
80107c1d:	83 e0 01             	and    $0x1,%eax
80107c20:	85 c0                	test   %eax,%eax
80107c22:	75 07                	jne    80107c2b <uartgetc+0x33>
    return -1;
80107c24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107c29:	eb 0f                	jmp    80107c3a <uartgetc+0x42>
  return inb(COM1+0);
80107c2b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107c32:	e8 09 fe ff ff       	call   80107a40 <inb>
80107c37:	0f b6 c0             	movzbl %al,%eax
}
80107c3a:	c9                   	leave  
80107c3b:	c3                   	ret    

80107c3c <uartintr>:

void
uartintr(void)
{
80107c3c:	55                   	push   %ebp
80107c3d:	89 e5                	mov    %esp,%ebp
80107c3f:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107c42:	c7 04 24 f8 7b 10 80 	movl   $0x80107bf8,(%esp)
80107c49:	e8 5f 8b ff ff       	call   801007ad <consoleintr>
}
80107c4e:	c9                   	leave  
80107c4f:	c3                   	ret    

80107c50 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80107c50:	6a 00                	push   $0x0
  pushl $0
80107c52:	6a 00                	push   $0x0
  jmp alltraps
80107c54:	e9 67 f9 ff ff       	jmp    801075c0 <alltraps>

80107c59 <vector1>:
.globl vector1
vector1:
  pushl $0
80107c59:	6a 00                	push   $0x0
  pushl $1
80107c5b:	6a 01                	push   $0x1
  jmp alltraps
80107c5d:	e9 5e f9 ff ff       	jmp    801075c0 <alltraps>

80107c62 <vector2>:
.globl vector2
vector2:
  pushl $0
80107c62:	6a 00                	push   $0x0
  pushl $2
80107c64:	6a 02                	push   $0x2
  jmp alltraps
80107c66:	e9 55 f9 ff ff       	jmp    801075c0 <alltraps>

80107c6b <vector3>:
.globl vector3
vector3:
  pushl $0
80107c6b:	6a 00                	push   $0x0
  pushl $3
80107c6d:	6a 03                	push   $0x3
  jmp alltraps
80107c6f:	e9 4c f9 ff ff       	jmp    801075c0 <alltraps>

80107c74 <vector4>:
.globl vector4
vector4:
  pushl $0
80107c74:	6a 00                	push   $0x0
  pushl $4
80107c76:	6a 04                	push   $0x4
  jmp alltraps
80107c78:	e9 43 f9 ff ff       	jmp    801075c0 <alltraps>

80107c7d <vector5>:
.globl vector5
vector5:
  pushl $0
80107c7d:	6a 00                	push   $0x0
  pushl $5
80107c7f:	6a 05                	push   $0x5
  jmp alltraps
80107c81:	e9 3a f9 ff ff       	jmp    801075c0 <alltraps>

80107c86 <vector6>:
.globl vector6
vector6:
  pushl $0
80107c86:	6a 00                	push   $0x0
  pushl $6
80107c88:	6a 06                	push   $0x6
  jmp alltraps
80107c8a:	e9 31 f9 ff ff       	jmp    801075c0 <alltraps>

80107c8f <vector7>:
.globl vector7
vector7:
  pushl $0
80107c8f:	6a 00                	push   $0x0
  pushl $7
80107c91:	6a 07                	push   $0x7
  jmp alltraps
80107c93:	e9 28 f9 ff ff       	jmp    801075c0 <alltraps>

80107c98 <vector8>:
.globl vector8
vector8:
  pushl $8
80107c98:	6a 08                	push   $0x8
  jmp alltraps
80107c9a:	e9 21 f9 ff ff       	jmp    801075c0 <alltraps>

80107c9f <vector9>:
.globl vector9
vector9:
  pushl $0
80107c9f:	6a 00                	push   $0x0
  pushl $9
80107ca1:	6a 09                	push   $0x9
  jmp alltraps
80107ca3:	e9 18 f9 ff ff       	jmp    801075c0 <alltraps>

80107ca8 <vector10>:
.globl vector10
vector10:
  pushl $10
80107ca8:	6a 0a                	push   $0xa
  jmp alltraps
80107caa:	e9 11 f9 ff ff       	jmp    801075c0 <alltraps>

80107caf <vector11>:
.globl vector11
vector11:
  pushl $11
80107caf:	6a 0b                	push   $0xb
  jmp alltraps
80107cb1:	e9 0a f9 ff ff       	jmp    801075c0 <alltraps>

80107cb6 <vector12>:
.globl vector12
vector12:
  pushl $12
80107cb6:	6a 0c                	push   $0xc
  jmp alltraps
80107cb8:	e9 03 f9 ff ff       	jmp    801075c0 <alltraps>

80107cbd <vector13>:
.globl vector13
vector13:
  pushl $13
80107cbd:	6a 0d                	push   $0xd
  jmp alltraps
80107cbf:	e9 fc f8 ff ff       	jmp    801075c0 <alltraps>

80107cc4 <vector14>:
.globl vector14
vector14:
  pushl $14
80107cc4:	6a 0e                	push   $0xe
  jmp alltraps
80107cc6:	e9 f5 f8 ff ff       	jmp    801075c0 <alltraps>

80107ccb <vector15>:
.globl vector15
vector15:
  pushl $0
80107ccb:	6a 00                	push   $0x0
  pushl $15
80107ccd:	6a 0f                	push   $0xf
  jmp alltraps
80107ccf:	e9 ec f8 ff ff       	jmp    801075c0 <alltraps>

80107cd4 <vector16>:
.globl vector16
vector16:
  pushl $0
80107cd4:	6a 00                	push   $0x0
  pushl $16
80107cd6:	6a 10                	push   $0x10
  jmp alltraps
80107cd8:	e9 e3 f8 ff ff       	jmp    801075c0 <alltraps>

80107cdd <vector17>:
.globl vector17
vector17:
  pushl $17
80107cdd:	6a 11                	push   $0x11
  jmp alltraps
80107cdf:	e9 dc f8 ff ff       	jmp    801075c0 <alltraps>

80107ce4 <vector18>:
.globl vector18
vector18:
  pushl $0
80107ce4:	6a 00                	push   $0x0
  pushl $18
80107ce6:	6a 12                	push   $0x12
  jmp alltraps
80107ce8:	e9 d3 f8 ff ff       	jmp    801075c0 <alltraps>

80107ced <vector19>:
.globl vector19
vector19:
  pushl $0
80107ced:	6a 00                	push   $0x0
  pushl $19
80107cef:	6a 13                	push   $0x13
  jmp alltraps
80107cf1:	e9 ca f8 ff ff       	jmp    801075c0 <alltraps>

80107cf6 <vector20>:
.globl vector20
vector20:
  pushl $0
80107cf6:	6a 00                	push   $0x0
  pushl $20
80107cf8:	6a 14                	push   $0x14
  jmp alltraps
80107cfa:	e9 c1 f8 ff ff       	jmp    801075c0 <alltraps>

80107cff <vector21>:
.globl vector21
vector21:
  pushl $0
80107cff:	6a 00                	push   $0x0
  pushl $21
80107d01:	6a 15                	push   $0x15
  jmp alltraps
80107d03:	e9 b8 f8 ff ff       	jmp    801075c0 <alltraps>

80107d08 <vector22>:
.globl vector22
vector22:
  pushl $0
80107d08:	6a 00                	push   $0x0
  pushl $22
80107d0a:	6a 16                	push   $0x16
  jmp alltraps
80107d0c:	e9 af f8 ff ff       	jmp    801075c0 <alltraps>

80107d11 <vector23>:
.globl vector23
vector23:
  pushl $0
80107d11:	6a 00                	push   $0x0
  pushl $23
80107d13:	6a 17                	push   $0x17
  jmp alltraps
80107d15:	e9 a6 f8 ff ff       	jmp    801075c0 <alltraps>

80107d1a <vector24>:
.globl vector24
vector24:
  pushl $0
80107d1a:	6a 00                	push   $0x0
  pushl $24
80107d1c:	6a 18                	push   $0x18
  jmp alltraps
80107d1e:	e9 9d f8 ff ff       	jmp    801075c0 <alltraps>

80107d23 <vector25>:
.globl vector25
vector25:
  pushl $0
80107d23:	6a 00                	push   $0x0
  pushl $25
80107d25:	6a 19                	push   $0x19
  jmp alltraps
80107d27:	e9 94 f8 ff ff       	jmp    801075c0 <alltraps>

80107d2c <vector26>:
.globl vector26
vector26:
  pushl $0
80107d2c:	6a 00                	push   $0x0
  pushl $26
80107d2e:	6a 1a                	push   $0x1a
  jmp alltraps
80107d30:	e9 8b f8 ff ff       	jmp    801075c0 <alltraps>

80107d35 <vector27>:
.globl vector27
vector27:
  pushl $0
80107d35:	6a 00                	push   $0x0
  pushl $27
80107d37:	6a 1b                	push   $0x1b
  jmp alltraps
80107d39:	e9 82 f8 ff ff       	jmp    801075c0 <alltraps>

80107d3e <vector28>:
.globl vector28
vector28:
  pushl $0
80107d3e:	6a 00                	push   $0x0
  pushl $28
80107d40:	6a 1c                	push   $0x1c
  jmp alltraps
80107d42:	e9 79 f8 ff ff       	jmp    801075c0 <alltraps>

80107d47 <vector29>:
.globl vector29
vector29:
  pushl $0
80107d47:	6a 00                	push   $0x0
  pushl $29
80107d49:	6a 1d                	push   $0x1d
  jmp alltraps
80107d4b:	e9 70 f8 ff ff       	jmp    801075c0 <alltraps>

80107d50 <vector30>:
.globl vector30
vector30:
  pushl $0
80107d50:	6a 00                	push   $0x0
  pushl $30
80107d52:	6a 1e                	push   $0x1e
  jmp alltraps
80107d54:	e9 67 f8 ff ff       	jmp    801075c0 <alltraps>

80107d59 <vector31>:
.globl vector31
vector31:
  pushl $0
80107d59:	6a 00                	push   $0x0
  pushl $31
80107d5b:	6a 1f                	push   $0x1f
  jmp alltraps
80107d5d:	e9 5e f8 ff ff       	jmp    801075c0 <alltraps>

80107d62 <vector32>:
.globl vector32
vector32:
  pushl $0
80107d62:	6a 00                	push   $0x0
  pushl $32
80107d64:	6a 20                	push   $0x20
  jmp alltraps
80107d66:	e9 55 f8 ff ff       	jmp    801075c0 <alltraps>

80107d6b <vector33>:
.globl vector33
vector33:
  pushl $0
80107d6b:	6a 00                	push   $0x0
  pushl $33
80107d6d:	6a 21                	push   $0x21
  jmp alltraps
80107d6f:	e9 4c f8 ff ff       	jmp    801075c0 <alltraps>

80107d74 <vector34>:
.globl vector34
vector34:
  pushl $0
80107d74:	6a 00                	push   $0x0
  pushl $34
80107d76:	6a 22                	push   $0x22
  jmp alltraps
80107d78:	e9 43 f8 ff ff       	jmp    801075c0 <alltraps>

80107d7d <vector35>:
.globl vector35
vector35:
  pushl $0
80107d7d:	6a 00                	push   $0x0
  pushl $35
80107d7f:	6a 23                	push   $0x23
  jmp alltraps
80107d81:	e9 3a f8 ff ff       	jmp    801075c0 <alltraps>

80107d86 <vector36>:
.globl vector36
vector36:
  pushl $0
80107d86:	6a 00                	push   $0x0
  pushl $36
80107d88:	6a 24                	push   $0x24
  jmp alltraps
80107d8a:	e9 31 f8 ff ff       	jmp    801075c0 <alltraps>

80107d8f <vector37>:
.globl vector37
vector37:
  pushl $0
80107d8f:	6a 00                	push   $0x0
  pushl $37
80107d91:	6a 25                	push   $0x25
  jmp alltraps
80107d93:	e9 28 f8 ff ff       	jmp    801075c0 <alltraps>

80107d98 <vector38>:
.globl vector38
vector38:
  pushl $0
80107d98:	6a 00                	push   $0x0
  pushl $38
80107d9a:	6a 26                	push   $0x26
  jmp alltraps
80107d9c:	e9 1f f8 ff ff       	jmp    801075c0 <alltraps>

80107da1 <vector39>:
.globl vector39
vector39:
  pushl $0
80107da1:	6a 00                	push   $0x0
  pushl $39
80107da3:	6a 27                	push   $0x27
  jmp alltraps
80107da5:	e9 16 f8 ff ff       	jmp    801075c0 <alltraps>

80107daa <vector40>:
.globl vector40
vector40:
  pushl $0
80107daa:	6a 00                	push   $0x0
  pushl $40
80107dac:	6a 28                	push   $0x28
  jmp alltraps
80107dae:	e9 0d f8 ff ff       	jmp    801075c0 <alltraps>

80107db3 <vector41>:
.globl vector41
vector41:
  pushl $0
80107db3:	6a 00                	push   $0x0
  pushl $41
80107db5:	6a 29                	push   $0x29
  jmp alltraps
80107db7:	e9 04 f8 ff ff       	jmp    801075c0 <alltraps>

80107dbc <vector42>:
.globl vector42
vector42:
  pushl $0
80107dbc:	6a 00                	push   $0x0
  pushl $42
80107dbe:	6a 2a                	push   $0x2a
  jmp alltraps
80107dc0:	e9 fb f7 ff ff       	jmp    801075c0 <alltraps>

80107dc5 <vector43>:
.globl vector43
vector43:
  pushl $0
80107dc5:	6a 00                	push   $0x0
  pushl $43
80107dc7:	6a 2b                	push   $0x2b
  jmp alltraps
80107dc9:	e9 f2 f7 ff ff       	jmp    801075c0 <alltraps>

80107dce <vector44>:
.globl vector44
vector44:
  pushl $0
80107dce:	6a 00                	push   $0x0
  pushl $44
80107dd0:	6a 2c                	push   $0x2c
  jmp alltraps
80107dd2:	e9 e9 f7 ff ff       	jmp    801075c0 <alltraps>

80107dd7 <vector45>:
.globl vector45
vector45:
  pushl $0
80107dd7:	6a 00                	push   $0x0
  pushl $45
80107dd9:	6a 2d                	push   $0x2d
  jmp alltraps
80107ddb:	e9 e0 f7 ff ff       	jmp    801075c0 <alltraps>

80107de0 <vector46>:
.globl vector46
vector46:
  pushl $0
80107de0:	6a 00                	push   $0x0
  pushl $46
80107de2:	6a 2e                	push   $0x2e
  jmp alltraps
80107de4:	e9 d7 f7 ff ff       	jmp    801075c0 <alltraps>

80107de9 <vector47>:
.globl vector47
vector47:
  pushl $0
80107de9:	6a 00                	push   $0x0
  pushl $47
80107deb:	6a 2f                	push   $0x2f
  jmp alltraps
80107ded:	e9 ce f7 ff ff       	jmp    801075c0 <alltraps>

80107df2 <vector48>:
.globl vector48
vector48:
  pushl $0
80107df2:	6a 00                	push   $0x0
  pushl $48
80107df4:	6a 30                	push   $0x30
  jmp alltraps
80107df6:	e9 c5 f7 ff ff       	jmp    801075c0 <alltraps>

80107dfb <vector49>:
.globl vector49
vector49:
  pushl $0
80107dfb:	6a 00                	push   $0x0
  pushl $49
80107dfd:	6a 31                	push   $0x31
  jmp alltraps
80107dff:	e9 bc f7 ff ff       	jmp    801075c0 <alltraps>

80107e04 <vector50>:
.globl vector50
vector50:
  pushl $0
80107e04:	6a 00                	push   $0x0
  pushl $50
80107e06:	6a 32                	push   $0x32
  jmp alltraps
80107e08:	e9 b3 f7 ff ff       	jmp    801075c0 <alltraps>

80107e0d <vector51>:
.globl vector51
vector51:
  pushl $0
80107e0d:	6a 00                	push   $0x0
  pushl $51
80107e0f:	6a 33                	push   $0x33
  jmp alltraps
80107e11:	e9 aa f7 ff ff       	jmp    801075c0 <alltraps>

80107e16 <vector52>:
.globl vector52
vector52:
  pushl $0
80107e16:	6a 00                	push   $0x0
  pushl $52
80107e18:	6a 34                	push   $0x34
  jmp alltraps
80107e1a:	e9 a1 f7 ff ff       	jmp    801075c0 <alltraps>

80107e1f <vector53>:
.globl vector53
vector53:
  pushl $0
80107e1f:	6a 00                	push   $0x0
  pushl $53
80107e21:	6a 35                	push   $0x35
  jmp alltraps
80107e23:	e9 98 f7 ff ff       	jmp    801075c0 <alltraps>

80107e28 <vector54>:
.globl vector54
vector54:
  pushl $0
80107e28:	6a 00                	push   $0x0
  pushl $54
80107e2a:	6a 36                	push   $0x36
  jmp alltraps
80107e2c:	e9 8f f7 ff ff       	jmp    801075c0 <alltraps>

80107e31 <vector55>:
.globl vector55
vector55:
  pushl $0
80107e31:	6a 00                	push   $0x0
  pushl $55
80107e33:	6a 37                	push   $0x37
  jmp alltraps
80107e35:	e9 86 f7 ff ff       	jmp    801075c0 <alltraps>

80107e3a <vector56>:
.globl vector56
vector56:
  pushl $0
80107e3a:	6a 00                	push   $0x0
  pushl $56
80107e3c:	6a 38                	push   $0x38
  jmp alltraps
80107e3e:	e9 7d f7 ff ff       	jmp    801075c0 <alltraps>

80107e43 <vector57>:
.globl vector57
vector57:
  pushl $0
80107e43:	6a 00                	push   $0x0
  pushl $57
80107e45:	6a 39                	push   $0x39
  jmp alltraps
80107e47:	e9 74 f7 ff ff       	jmp    801075c0 <alltraps>

80107e4c <vector58>:
.globl vector58
vector58:
  pushl $0
80107e4c:	6a 00                	push   $0x0
  pushl $58
80107e4e:	6a 3a                	push   $0x3a
  jmp alltraps
80107e50:	e9 6b f7 ff ff       	jmp    801075c0 <alltraps>

80107e55 <vector59>:
.globl vector59
vector59:
  pushl $0
80107e55:	6a 00                	push   $0x0
  pushl $59
80107e57:	6a 3b                	push   $0x3b
  jmp alltraps
80107e59:	e9 62 f7 ff ff       	jmp    801075c0 <alltraps>

80107e5e <vector60>:
.globl vector60
vector60:
  pushl $0
80107e5e:	6a 00                	push   $0x0
  pushl $60
80107e60:	6a 3c                	push   $0x3c
  jmp alltraps
80107e62:	e9 59 f7 ff ff       	jmp    801075c0 <alltraps>

80107e67 <vector61>:
.globl vector61
vector61:
  pushl $0
80107e67:	6a 00                	push   $0x0
  pushl $61
80107e69:	6a 3d                	push   $0x3d
  jmp alltraps
80107e6b:	e9 50 f7 ff ff       	jmp    801075c0 <alltraps>

80107e70 <vector62>:
.globl vector62
vector62:
  pushl $0
80107e70:	6a 00                	push   $0x0
  pushl $62
80107e72:	6a 3e                	push   $0x3e
  jmp alltraps
80107e74:	e9 47 f7 ff ff       	jmp    801075c0 <alltraps>

80107e79 <vector63>:
.globl vector63
vector63:
  pushl $0
80107e79:	6a 00                	push   $0x0
  pushl $63
80107e7b:	6a 3f                	push   $0x3f
  jmp alltraps
80107e7d:	e9 3e f7 ff ff       	jmp    801075c0 <alltraps>

80107e82 <vector64>:
.globl vector64
vector64:
  pushl $0
80107e82:	6a 00                	push   $0x0
  pushl $64
80107e84:	6a 40                	push   $0x40
  jmp alltraps
80107e86:	e9 35 f7 ff ff       	jmp    801075c0 <alltraps>

80107e8b <vector65>:
.globl vector65
vector65:
  pushl $0
80107e8b:	6a 00                	push   $0x0
  pushl $65
80107e8d:	6a 41                	push   $0x41
  jmp alltraps
80107e8f:	e9 2c f7 ff ff       	jmp    801075c0 <alltraps>

80107e94 <vector66>:
.globl vector66
vector66:
  pushl $0
80107e94:	6a 00                	push   $0x0
  pushl $66
80107e96:	6a 42                	push   $0x42
  jmp alltraps
80107e98:	e9 23 f7 ff ff       	jmp    801075c0 <alltraps>

80107e9d <vector67>:
.globl vector67
vector67:
  pushl $0
80107e9d:	6a 00                	push   $0x0
  pushl $67
80107e9f:	6a 43                	push   $0x43
  jmp alltraps
80107ea1:	e9 1a f7 ff ff       	jmp    801075c0 <alltraps>

80107ea6 <vector68>:
.globl vector68
vector68:
  pushl $0
80107ea6:	6a 00                	push   $0x0
  pushl $68
80107ea8:	6a 44                	push   $0x44
  jmp alltraps
80107eaa:	e9 11 f7 ff ff       	jmp    801075c0 <alltraps>

80107eaf <vector69>:
.globl vector69
vector69:
  pushl $0
80107eaf:	6a 00                	push   $0x0
  pushl $69
80107eb1:	6a 45                	push   $0x45
  jmp alltraps
80107eb3:	e9 08 f7 ff ff       	jmp    801075c0 <alltraps>

80107eb8 <vector70>:
.globl vector70
vector70:
  pushl $0
80107eb8:	6a 00                	push   $0x0
  pushl $70
80107eba:	6a 46                	push   $0x46
  jmp alltraps
80107ebc:	e9 ff f6 ff ff       	jmp    801075c0 <alltraps>

80107ec1 <vector71>:
.globl vector71
vector71:
  pushl $0
80107ec1:	6a 00                	push   $0x0
  pushl $71
80107ec3:	6a 47                	push   $0x47
  jmp alltraps
80107ec5:	e9 f6 f6 ff ff       	jmp    801075c0 <alltraps>

80107eca <vector72>:
.globl vector72
vector72:
  pushl $0
80107eca:	6a 00                	push   $0x0
  pushl $72
80107ecc:	6a 48                	push   $0x48
  jmp alltraps
80107ece:	e9 ed f6 ff ff       	jmp    801075c0 <alltraps>

80107ed3 <vector73>:
.globl vector73
vector73:
  pushl $0
80107ed3:	6a 00                	push   $0x0
  pushl $73
80107ed5:	6a 49                	push   $0x49
  jmp alltraps
80107ed7:	e9 e4 f6 ff ff       	jmp    801075c0 <alltraps>

80107edc <vector74>:
.globl vector74
vector74:
  pushl $0
80107edc:	6a 00                	push   $0x0
  pushl $74
80107ede:	6a 4a                	push   $0x4a
  jmp alltraps
80107ee0:	e9 db f6 ff ff       	jmp    801075c0 <alltraps>

80107ee5 <vector75>:
.globl vector75
vector75:
  pushl $0
80107ee5:	6a 00                	push   $0x0
  pushl $75
80107ee7:	6a 4b                	push   $0x4b
  jmp alltraps
80107ee9:	e9 d2 f6 ff ff       	jmp    801075c0 <alltraps>

80107eee <vector76>:
.globl vector76
vector76:
  pushl $0
80107eee:	6a 00                	push   $0x0
  pushl $76
80107ef0:	6a 4c                	push   $0x4c
  jmp alltraps
80107ef2:	e9 c9 f6 ff ff       	jmp    801075c0 <alltraps>

80107ef7 <vector77>:
.globl vector77
vector77:
  pushl $0
80107ef7:	6a 00                	push   $0x0
  pushl $77
80107ef9:	6a 4d                	push   $0x4d
  jmp alltraps
80107efb:	e9 c0 f6 ff ff       	jmp    801075c0 <alltraps>

80107f00 <vector78>:
.globl vector78
vector78:
  pushl $0
80107f00:	6a 00                	push   $0x0
  pushl $78
80107f02:	6a 4e                	push   $0x4e
  jmp alltraps
80107f04:	e9 b7 f6 ff ff       	jmp    801075c0 <alltraps>

80107f09 <vector79>:
.globl vector79
vector79:
  pushl $0
80107f09:	6a 00                	push   $0x0
  pushl $79
80107f0b:	6a 4f                	push   $0x4f
  jmp alltraps
80107f0d:	e9 ae f6 ff ff       	jmp    801075c0 <alltraps>

80107f12 <vector80>:
.globl vector80
vector80:
  pushl $0
80107f12:	6a 00                	push   $0x0
  pushl $80
80107f14:	6a 50                	push   $0x50
  jmp alltraps
80107f16:	e9 a5 f6 ff ff       	jmp    801075c0 <alltraps>

80107f1b <vector81>:
.globl vector81
vector81:
  pushl $0
80107f1b:	6a 00                	push   $0x0
  pushl $81
80107f1d:	6a 51                	push   $0x51
  jmp alltraps
80107f1f:	e9 9c f6 ff ff       	jmp    801075c0 <alltraps>

80107f24 <vector82>:
.globl vector82
vector82:
  pushl $0
80107f24:	6a 00                	push   $0x0
  pushl $82
80107f26:	6a 52                	push   $0x52
  jmp alltraps
80107f28:	e9 93 f6 ff ff       	jmp    801075c0 <alltraps>

80107f2d <vector83>:
.globl vector83
vector83:
  pushl $0
80107f2d:	6a 00                	push   $0x0
  pushl $83
80107f2f:	6a 53                	push   $0x53
  jmp alltraps
80107f31:	e9 8a f6 ff ff       	jmp    801075c0 <alltraps>

80107f36 <vector84>:
.globl vector84
vector84:
  pushl $0
80107f36:	6a 00                	push   $0x0
  pushl $84
80107f38:	6a 54                	push   $0x54
  jmp alltraps
80107f3a:	e9 81 f6 ff ff       	jmp    801075c0 <alltraps>

80107f3f <vector85>:
.globl vector85
vector85:
  pushl $0
80107f3f:	6a 00                	push   $0x0
  pushl $85
80107f41:	6a 55                	push   $0x55
  jmp alltraps
80107f43:	e9 78 f6 ff ff       	jmp    801075c0 <alltraps>

80107f48 <vector86>:
.globl vector86
vector86:
  pushl $0
80107f48:	6a 00                	push   $0x0
  pushl $86
80107f4a:	6a 56                	push   $0x56
  jmp alltraps
80107f4c:	e9 6f f6 ff ff       	jmp    801075c0 <alltraps>

80107f51 <vector87>:
.globl vector87
vector87:
  pushl $0
80107f51:	6a 00                	push   $0x0
  pushl $87
80107f53:	6a 57                	push   $0x57
  jmp alltraps
80107f55:	e9 66 f6 ff ff       	jmp    801075c0 <alltraps>

80107f5a <vector88>:
.globl vector88
vector88:
  pushl $0
80107f5a:	6a 00                	push   $0x0
  pushl $88
80107f5c:	6a 58                	push   $0x58
  jmp alltraps
80107f5e:	e9 5d f6 ff ff       	jmp    801075c0 <alltraps>

80107f63 <vector89>:
.globl vector89
vector89:
  pushl $0
80107f63:	6a 00                	push   $0x0
  pushl $89
80107f65:	6a 59                	push   $0x59
  jmp alltraps
80107f67:	e9 54 f6 ff ff       	jmp    801075c0 <alltraps>

80107f6c <vector90>:
.globl vector90
vector90:
  pushl $0
80107f6c:	6a 00                	push   $0x0
  pushl $90
80107f6e:	6a 5a                	push   $0x5a
  jmp alltraps
80107f70:	e9 4b f6 ff ff       	jmp    801075c0 <alltraps>

80107f75 <vector91>:
.globl vector91
vector91:
  pushl $0
80107f75:	6a 00                	push   $0x0
  pushl $91
80107f77:	6a 5b                	push   $0x5b
  jmp alltraps
80107f79:	e9 42 f6 ff ff       	jmp    801075c0 <alltraps>

80107f7e <vector92>:
.globl vector92
vector92:
  pushl $0
80107f7e:	6a 00                	push   $0x0
  pushl $92
80107f80:	6a 5c                	push   $0x5c
  jmp alltraps
80107f82:	e9 39 f6 ff ff       	jmp    801075c0 <alltraps>

80107f87 <vector93>:
.globl vector93
vector93:
  pushl $0
80107f87:	6a 00                	push   $0x0
  pushl $93
80107f89:	6a 5d                	push   $0x5d
  jmp alltraps
80107f8b:	e9 30 f6 ff ff       	jmp    801075c0 <alltraps>

80107f90 <vector94>:
.globl vector94
vector94:
  pushl $0
80107f90:	6a 00                	push   $0x0
  pushl $94
80107f92:	6a 5e                	push   $0x5e
  jmp alltraps
80107f94:	e9 27 f6 ff ff       	jmp    801075c0 <alltraps>

80107f99 <vector95>:
.globl vector95
vector95:
  pushl $0
80107f99:	6a 00                	push   $0x0
  pushl $95
80107f9b:	6a 5f                	push   $0x5f
  jmp alltraps
80107f9d:	e9 1e f6 ff ff       	jmp    801075c0 <alltraps>

80107fa2 <vector96>:
.globl vector96
vector96:
  pushl $0
80107fa2:	6a 00                	push   $0x0
  pushl $96
80107fa4:	6a 60                	push   $0x60
  jmp alltraps
80107fa6:	e9 15 f6 ff ff       	jmp    801075c0 <alltraps>

80107fab <vector97>:
.globl vector97
vector97:
  pushl $0
80107fab:	6a 00                	push   $0x0
  pushl $97
80107fad:	6a 61                	push   $0x61
  jmp alltraps
80107faf:	e9 0c f6 ff ff       	jmp    801075c0 <alltraps>

80107fb4 <vector98>:
.globl vector98
vector98:
  pushl $0
80107fb4:	6a 00                	push   $0x0
  pushl $98
80107fb6:	6a 62                	push   $0x62
  jmp alltraps
80107fb8:	e9 03 f6 ff ff       	jmp    801075c0 <alltraps>

80107fbd <vector99>:
.globl vector99
vector99:
  pushl $0
80107fbd:	6a 00                	push   $0x0
  pushl $99
80107fbf:	6a 63                	push   $0x63
  jmp alltraps
80107fc1:	e9 fa f5 ff ff       	jmp    801075c0 <alltraps>

80107fc6 <vector100>:
.globl vector100
vector100:
  pushl $0
80107fc6:	6a 00                	push   $0x0
  pushl $100
80107fc8:	6a 64                	push   $0x64
  jmp alltraps
80107fca:	e9 f1 f5 ff ff       	jmp    801075c0 <alltraps>

80107fcf <vector101>:
.globl vector101
vector101:
  pushl $0
80107fcf:	6a 00                	push   $0x0
  pushl $101
80107fd1:	6a 65                	push   $0x65
  jmp alltraps
80107fd3:	e9 e8 f5 ff ff       	jmp    801075c0 <alltraps>

80107fd8 <vector102>:
.globl vector102
vector102:
  pushl $0
80107fd8:	6a 00                	push   $0x0
  pushl $102
80107fda:	6a 66                	push   $0x66
  jmp alltraps
80107fdc:	e9 df f5 ff ff       	jmp    801075c0 <alltraps>

80107fe1 <vector103>:
.globl vector103
vector103:
  pushl $0
80107fe1:	6a 00                	push   $0x0
  pushl $103
80107fe3:	6a 67                	push   $0x67
  jmp alltraps
80107fe5:	e9 d6 f5 ff ff       	jmp    801075c0 <alltraps>

80107fea <vector104>:
.globl vector104
vector104:
  pushl $0
80107fea:	6a 00                	push   $0x0
  pushl $104
80107fec:	6a 68                	push   $0x68
  jmp alltraps
80107fee:	e9 cd f5 ff ff       	jmp    801075c0 <alltraps>

80107ff3 <vector105>:
.globl vector105
vector105:
  pushl $0
80107ff3:	6a 00                	push   $0x0
  pushl $105
80107ff5:	6a 69                	push   $0x69
  jmp alltraps
80107ff7:	e9 c4 f5 ff ff       	jmp    801075c0 <alltraps>

80107ffc <vector106>:
.globl vector106
vector106:
  pushl $0
80107ffc:	6a 00                	push   $0x0
  pushl $106
80107ffe:	6a 6a                	push   $0x6a
  jmp alltraps
80108000:	e9 bb f5 ff ff       	jmp    801075c0 <alltraps>

80108005 <vector107>:
.globl vector107
vector107:
  pushl $0
80108005:	6a 00                	push   $0x0
  pushl $107
80108007:	6a 6b                	push   $0x6b
  jmp alltraps
80108009:	e9 b2 f5 ff ff       	jmp    801075c0 <alltraps>

8010800e <vector108>:
.globl vector108
vector108:
  pushl $0
8010800e:	6a 00                	push   $0x0
  pushl $108
80108010:	6a 6c                	push   $0x6c
  jmp alltraps
80108012:	e9 a9 f5 ff ff       	jmp    801075c0 <alltraps>

80108017 <vector109>:
.globl vector109
vector109:
  pushl $0
80108017:	6a 00                	push   $0x0
  pushl $109
80108019:	6a 6d                	push   $0x6d
  jmp alltraps
8010801b:	e9 a0 f5 ff ff       	jmp    801075c0 <alltraps>

80108020 <vector110>:
.globl vector110
vector110:
  pushl $0
80108020:	6a 00                	push   $0x0
  pushl $110
80108022:	6a 6e                	push   $0x6e
  jmp alltraps
80108024:	e9 97 f5 ff ff       	jmp    801075c0 <alltraps>

80108029 <vector111>:
.globl vector111
vector111:
  pushl $0
80108029:	6a 00                	push   $0x0
  pushl $111
8010802b:	6a 6f                	push   $0x6f
  jmp alltraps
8010802d:	e9 8e f5 ff ff       	jmp    801075c0 <alltraps>

80108032 <vector112>:
.globl vector112
vector112:
  pushl $0
80108032:	6a 00                	push   $0x0
  pushl $112
80108034:	6a 70                	push   $0x70
  jmp alltraps
80108036:	e9 85 f5 ff ff       	jmp    801075c0 <alltraps>

8010803b <vector113>:
.globl vector113
vector113:
  pushl $0
8010803b:	6a 00                	push   $0x0
  pushl $113
8010803d:	6a 71                	push   $0x71
  jmp alltraps
8010803f:	e9 7c f5 ff ff       	jmp    801075c0 <alltraps>

80108044 <vector114>:
.globl vector114
vector114:
  pushl $0
80108044:	6a 00                	push   $0x0
  pushl $114
80108046:	6a 72                	push   $0x72
  jmp alltraps
80108048:	e9 73 f5 ff ff       	jmp    801075c0 <alltraps>

8010804d <vector115>:
.globl vector115
vector115:
  pushl $0
8010804d:	6a 00                	push   $0x0
  pushl $115
8010804f:	6a 73                	push   $0x73
  jmp alltraps
80108051:	e9 6a f5 ff ff       	jmp    801075c0 <alltraps>

80108056 <vector116>:
.globl vector116
vector116:
  pushl $0
80108056:	6a 00                	push   $0x0
  pushl $116
80108058:	6a 74                	push   $0x74
  jmp alltraps
8010805a:	e9 61 f5 ff ff       	jmp    801075c0 <alltraps>

8010805f <vector117>:
.globl vector117
vector117:
  pushl $0
8010805f:	6a 00                	push   $0x0
  pushl $117
80108061:	6a 75                	push   $0x75
  jmp alltraps
80108063:	e9 58 f5 ff ff       	jmp    801075c0 <alltraps>

80108068 <vector118>:
.globl vector118
vector118:
  pushl $0
80108068:	6a 00                	push   $0x0
  pushl $118
8010806a:	6a 76                	push   $0x76
  jmp alltraps
8010806c:	e9 4f f5 ff ff       	jmp    801075c0 <alltraps>

80108071 <vector119>:
.globl vector119
vector119:
  pushl $0
80108071:	6a 00                	push   $0x0
  pushl $119
80108073:	6a 77                	push   $0x77
  jmp alltraps
80108075:	e9 46 f5 ff ff       	jmp    801075c0 <alltraps>

8010807a <vector120>:
.globl vector120
vector120:
  pushl $0
8010807a:	6a 00                	push   $0x0
  pushl $120
8010807c:	6a 78                	push   $0x78
  jmp alltraps
8010807e:	e9 3d f5 ff ff       	jmp    801075c0 <alltraps>

80108083 <vector121>:
.globl vector121
vector121:
  pushl $0
80108083:	6a 00                	push   $0x0
  pushl $121
80108085:	6a 79                	push   $0x79
  jmp alltraps
80108087:	e9 34 f5 ff ff       	jmp    801075c0 <alltraps>

8010808c <vector122>:
.globl vector122
vector122:
  pushl $0
8010808c:	6a 00                	push   $0x0
  pushl $122
8010808e:	6a 7a                	push   $0x7a
  jmp alltraps
80108090:	e9 2b f5 ff ff       	jmp    801075c0 <alltraps>

80108095 <vector123>:
.globl vector123
vector123:
  pushl $0
80108095:	6a 00                	push   $0x0
  pushl $123
80108097:	6a 7b                	push   $0x7b
  jmp alltraps
80108099:	e9 22 f5 ff ff       	jmp    801075c0 <alltraps>

8010809e <vector124>:
.globl vector124
vector124:
  pushl $0
8010809e:	6a 00                	push   $0x0
  pushl $124
801080a0:	6a 7c                	push   $0x7c
  jmp alltraps
801080a2:	e9 19 f5 ff ff       	jmp    801075c0 <alltraps>

801080a7 <vector125>:
.globl vector125
vector125:
  pushl $0
801080a7:	6a 00                	push   $0x0
  pushl $125
801080a9:	6a 7d                	push   $0x7d
  jmp alltraps
801080ab:	e9 10 f5 ff ff       	jmp    801075c0 <alltraps>

801080b0 <vector126>:
.globl vector126
vector126:
  pushl $0
801080b0:	6a 00                	push   $0x0
  pushl $126
801080b2:	6a 7e                	push   $0x7e
  jmp alltraps
801080b4:	e9 07 f5 ff ff       	jmp    801075c0 <alltraps>

801080b9 <vector127>:
.globl vector127
vector127:
  pushl $0
801080b9:	6a 00                	push   $0x0
  pushl $127
801080bb:	6a 7f                	push   $0x7f
  jmp alltraps
801080bd:	e9 fe f4 ff ff       	jmp    801075c0 <alltraps>

801080c2 <vector128>:
.globl vector128
vector128:
  pushl $0
801080c2:	6a 00                	push   $0x0
  pushl $128
801080c4:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801080c9:	e9 f2 f4 ff ff       	jmp    801075c0 <alltraps>

801080ce <vector129>:
.globl vector129
vector129:
  pushl $0
801080ce:	6a 00                	push   $0x0
  pushl $129
801080d0:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801080d5:	e9 e6 f4 ff ff       	jmp    801075c0 <alltraps>

801080da <vector130>:
.globl vector130
vector130:
  pushl $0
801080da:	6a 00                	push   $0x0
  pushl $130
801080dc:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801080e1:	e9 da f4 ff ff       	jmp    801075c0 <alltraps>

801080e6 <vector131>:
.globl vector131
vector131:
  pushl $0
801080e6:	6a 00                	push   $0x0
  pushl $131
801080e8:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801080ed:	e9 ce f4 ff ff       	jmp    801075c0 <alltraps>

801080f2 <vector132>:
.globl vector132
vector132:
  pushl $0
801080f2:	6a 00                	push   $0x0
  pushl $132
801080f4:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801080f9:	e9 c2 f4 ff ff       	jmp    801075c0 <alltraps>

801080fe <vector133>:
.globl vector133
vector133:
  pushl $0
801080fe:	6a 00                	push   $0x0
  pushl $133
80108100:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80108105:	e9 b6 f4 ff ff       	jmp    801075c0 <alltraps>

8010810a <vector134>:
.globl vector134
vector134:
  pushl $0
8010810a:	6a 00                	push   $0x0
  pushl $134
8010810c:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80108111:	e9 aa f4 ff ff       	jmp    801075c0 <alltraps>

80108116 <vector135>:
.globl vector135
vector135:
  pushl $0
80108116:	6a 00                	push   $0x0
  pushl $135
80108118:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010811d:	e9 9e f4 ff ff       	jmp    801075c0 <alltraps>

80108122 <vector136>:
.globl vector136
vector136:
  pushl $0
80108122:	6a 00                	push   $0x0
  pushl $136
80108124:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80108129:	e9 92 f4 ff ff       	jmp    801075c0 <alltraps>

8010812e <vector137>:
.globl vector137
vector137:
  pushl $0
8010812e:	6a 00                	push   $0x0
  pushl $137
80108130:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80108135:	e9 86 f4 ff ff       	jmp    801075c0 <alltraps>

8010813a <vector138>:
.globl vector138
vector138:
  pushl $0
8010813a:	6a 00                	push   $0x0
  pushl $138
8010813c:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80108141:	e9 7a f4 ff ff       	jmp    801075c0 <alltraps>

80108146 <vector139>:
.globl vector139
vector139:
  pushl $0
80108146:	6a 00                	push   $0x0
  pushl $139
80108148:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010814d:	e9 6e f4 ff ff       	jmp    801075c0 <alltraps>

80108152 <vector140>:
.globl vector140
vector140:
  pushl $0
80108152:	6a 00                	push   $0x0
  pushl $140
80108154:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80108159:	e9 62 f4 ff ff       	jmp    801075c0 <alltraps>

8010815e <vector141>:
.globl vector141
vector141:
  pushl $0
8010815e:	6a 00                	push   $0x0
  pushl $141
80108160:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80108165:	e9 56 f4 ff ff       	jmp    801075c0 <alltraps>

8010816a <vector142>:
.globl vector142
vector142:
  pushl $0
8010816a:	6a 00                	push   $0x0
  pushl $142
8010816c:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80108171:	e9 4a f4 ff ff       	jmp    801075c0 <alltraps>

80108176 <vector143>:
.globl vector143
vector143:
  pushl $0
80108176:	6a 00                	push   $0x0
  pushl $143
80108178:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010817d:	e9 3e f4 ff ff       	jmp    801075c0 <alltraps>

80108182 <vector144>:
.globl vector144
vector144:
  pushl $0
80108182:	6a 00                	push   $0x0
  pushl $144
80108184:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80108189:	e9 32 f4 ff ff       	jmp    801075c0 <alltraps>

8010818e <vector145>:
.globl vector145
vector145:
  pushl $0
8010818e:	6a 00                	push   $0x0
  pushl $145
80108190:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80108195:	e9 26 f4 ff ff       	jmp    801075c0 <alltraps>

8010819a <vector146>:
.globl vector146
vector146:
  pushl $0
8010819a:	6a 00                	push   $0x0
  pushl $146
8010819c:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801081a1:	e9 1a f4 ff ff       	jmp    801075c0 <alltraps>

801081a6 <vector147>:
.globl vector147
vector147:
  pushl $0
801081a6:	6a 00                	push   $0x0
  pushl $147
801081a8:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801081ad:	e9 0e f4 ff ff       	jmp    801075c0 <alltraps>

801081b2 <vector148>:
.globl vector148
vector148:
  pushl $0
801081b2:	6a 00                	push   $0x0
  pushl $148
801081b4:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801081b9:	e9 02 f4 ff ff       	jmp    801075c0 <alltraps>

801081be <vector149>:
.globl vector149
vector149:
  pushl $0
801081be:	6a 00                	push   $0x0
  pushl $149
801081c0:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801081c5:	e9 f6 f3 ff ff       	jmp    801075c0 <alltraps>

801081ca <vector150>:
.globl vector150
vector150:
  pushl $0
801081ca:	6a 00                	push   $0x0
  pushl $150
801081cc:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801081d1:	e9 ea f3 ff ff       	jmp    801075c0 <alltraps>

801081d6 <vector151>:
.globl vector151
vector151:
  pushl $0
801081d6:	6a 00                	push   $0x0
  pushl $151
801081d8:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801081dd:	e9 de f3 ff ff       	jmp    801075c0 <alltraps>

801081e2 <vector152>:
.globl vector152
vector152:
  pushl $0
801081e2:	6a 00                	push   $0x0
  pushl $152
801081e4:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801081e9:	e9 d2 f3 ff ff       	jmp    801075c0 <alltraps>

801081ee <vector153>:
.globl vector153
vector153:
  pushl $0
801081ee:	6a 00                	push   $0x0
  pushl $153
801081f0:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801081f5:	e9 c6 f3 ff ff       	jmp    801075c0 <alltraps>

801081fa <vector154>:
.globl vector154
vector154:
  pushl $0
801081fa:	6a 00                	push   $0x0
  pushl $154
801081fc:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80108201:	e9 ba f3 ff ff       	jmp    801075c0 <alltraps>

80108206 <vector155>:
.globl vector155
vector155:
  pushl $0
80108206:	6a 00                	push   $0x0
  pushl $155
80108208:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010820d:	e9 ae f3 ff ff       	jmp    801075c0 <alltraps>

80108212 <vector156>:
.globl vector156
vector156:
  pushl $0
80108212:	6a 00                	push   $0x0
  pushl $156
80108214:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80108219:	e9 a2 f3 ff ff       	jmp    801075c0 <alltraps>

8010821e <vector157>:
.globl vector157
vector157:
  pushl $0
8010821e:	6a 00                	push   $0x0
  pushl $157
80108220:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80108225:	e9 96 f3 ff ff       	jmp    801075c0 <alltraps>

8010822a <vector158>:
.globl vector158
vector158:
  pushl $0
8010822a:	6a 00                	push   $0x0
  pushl $158
8010822c:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80108231:	e9 8a f3 ff ff       	jmp    801075c0 <alltraps>

80108236 <vector159>:
.globl vector159
vector159:
  pushl $0
80108236:	6a 00                	push   $0x0
  pushl $159
80108238:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010823d:	e9 7e f3 ff ff       	jmp    801075c0 <alltraps>

80108242 <vector160>:
.globl vector160
vector160:
  pushl $0
80108242:	6a 00                	push   $0x0
  pushl $160
80108244:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80108249:	e9 72 f3 ff ff       	jmp    801075c0 <alltraps>

8010824e <vector161>:
.globl vector161
vector161:
  pushl $0
8010824e:	6a 00                	push   $0x0
  pushl $161
80108250:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80108255:	e9 66 f3 ff ff       	jmp    801075c0 <alltraps>

8010825a <vector162>:
.globl vector162
vector162:
  pushl $0
8010825a:	6a 00                	push   $0x0
  pushl $162
8010825c:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80108261:	e9 5a f3 ff ff       	jmp    801075c0 <alltraps>

80108266 <vector163>:
.globl vector163
vector163:
  pushl $0
80108266:	6a 00                	push   $0x0
  pushl $163
80108268:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010826d:	e9 4e f3 ff ff       	jmp    801075c0 <alltraps>

80108272 <vector164>:
.globl vector164
vector164:
  pushl $0
80108272:	6a 00                	push   $0x0
  pushl $164
80108274:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80108279:	e9 42 f3 ff ff       	jmp    801075c0 <alltraps>

8010827e <vector165>:
.globl vector165
vector165:
  pushl $0
8010827e:	6a 00                	push   $0x0
  pushl $165
80108280:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80108285:	e9 36 f3 ff ff       	jmp    801075c0 <alltraps>

8010828a <vector166>:
.globl vector166
vector166:
  pushl $0
8010828a:	6a 00                	push   $0x0
  pushl $166
8010828c:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80108291:	e9 2a f3 ff ff       	jmp    801075c0 <alltraps>

80108296 <vector167>:
.globl vector167
vector167:
  pushl $0
80108296:	6a 00                	push   $0x0
  pushl $167
80108298:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010829d:	e9 1e f3 ff ff       	jmp    801075c0 <alltraps>

801082a2 <vector168>:
.globl vector168
vector168:
  pushl $0
801082a2:	6a 00                	push   $0x0
  pushl $168
801082a4:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801082a9:	e9 12 f3 ff ff       	jmp    801075c0 <alltraps>

801082ae <vector169>:
.globl vector169
vector169:
  pushl $0
801082ae:	6a 00                	push   $0x0
  pushl $169
801082b0:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801082b5:	e9 06 f3 ff ff       	jmp    801075c0 <alltraps>

801082ba <vector170>:
.globl vector170
vector170:
  pushl $0
801082ba:	6a 00                	push   $0x0
  pushl $170
801082bc:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801082c1:	e9 fa f2 ff ff       	jmp    801075c0 <alltraps>

801082c6 <vector171>:
.globl vector171
vector171:
  pushl $0
801082c6:	6a 00                	push   $0x0
  pushl $171
801082c8:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801082cd:	e9 ee f2 ff ff       	jmp    801075c0 <alltraps>

801082d2 <vector172>:
.globl vector172
vector172:
  pushl $0
801082d2:	6a 00                	push   $0x0
  pushl $172
801082d4:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801082d9:	e9 e2 f2 ff ff       	jmp    801075c0 <alltraps>

801082de <vector173>:
.globl vector173
vector173:
  pushl $0
801082de:	6a 00                	push   $0x0
  pushl $173
801082e0:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801082e5:	e9 d6 f2 ff ff       	jmp    801075c0 <alltraps>

801082ea <vector174>:
.globl vector174
vector174:
  pushl $0
801082ea:	6a 00                	push   $0x0
  pushl $174
801082ec:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801082f1:	e9 ca f2 ff ff       	jmp    801075c0 <alltraps>

801082f6 <vector175>:
.globl vector175
vector175:
  pushl $0
801082f6:	6a 00                	push   $0x0
  pushl $175
801082f8:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801082fd:	e9 be f2 ff ff       	jmp    801075c0 <alltraps>

80108302 <vector176>:
.globl vector176
vector176:
  pushl $0
80108302:	6a 00                	push   $0x0
  pushl $176
80108304:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80108309:	e9 b2 f2 ff ff       	jmp    801075c0 <alltraps>

8010830e <vector177>:
.globl vector177
vector177:
  pushl $0
8010830e:	6a 00                	push   $0x0
  pushl $177
80108310:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80108315:	e9 a6 f2 ff ff       	jmp    801075c0 <alltraps>

8010831a <vector178>:
.globl vector178
vector178:
  pushl $0
8010831a:	6a 00                	push   $0x0
  pushl $178
8010831c:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80108321:	e9 9a f2 ff ff       	jmp    801075c0 <alltraps>

80108326 <vector179>:
.globl vector179
vector179:
  pushl $0
80108326:	6a 00                	push   $0x0
  pushl $179
80108328:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010832d:	e9 8e f2 ff ff       	jmp    801075c0 <alltraps>

80108332 <vector180>:
.globl vector180
vector180:
  pushl $0
80108332:	6a 00                	push   $0x0
  pushl $180
80108334:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80108339:	e9 82 f2 ff ff       	jmp    801075c0 <alltraps>

8010833e <vector181>:
.globl vector181
vector181:
  pushl $0
8010833e:	6a 00                	push   $0x0
  pushl $181
80108340:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80108345:	e9 76 f2 ff ff       	jmp    801075c0 <alltraps>

8010834a <vector182>:
.globl vector182
vector182:
  pushl $0
8010834a:	6a 00                	push   $0x0
  pushl $182
8010834c:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80108351:	e9 6a f2 ff ff       	jmp    801075c0 <alltraps>

80108356 <vector183>:
.globl vector183
vector183:
  pushl $0
80108356:	6a 00                	push   $0x0
  pushl $183
80108358:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010835d:	e9 5e f2 ff ff       	jmp    801075c0 <alltraps>

80108362 <vector184>:
.globl vector184
vector184:
  pushl $0
80108362:	6a 00                	push   $0x0
  pushl $184
80108364:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108369:	e9 52 f2 ff ff       	jmp    801075c0 <alltraps>

8010836e <vector185>:
.globl vector185
vector185:
  pushl $0
8010836e:	6a 00                	push   $0x0
  pushl $185
80108370:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108375:	e9 46 f2 ff ff       	jmp    801075c0 <alltraps>

8010837a <vector186>:
.globl vector186
vector186:
  pushl $0
8010837a:	6a 00                	push   $0x0
  pushl $186
8010837c:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80108381:	e9 3a f2 ff ff       	jmp    801075c0 <alltraps>

80108386 <vector187>:
.globl vector187
vector187:
  pushl $0
80108386:	6a 00                	push   $0x0
  pushl $187
80108388:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010838d:	e9 2e f2 ff ff       	jmp    801075c0 <alltraps>

80108392 <vector188>:
.globl vector188
vector188:
  pushl $0
80108392:	6a 00                	push   $0x0
  pushl $188
80108394:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108399:	e9 22 f2 ff ff       	jmp    801075c0 <alltraps>

8010839e <vector189>:
.globl vector189
vector189:
  pushl $0
8010839e:	6a 00                	push   $0x0
  pushl $189
801083a0:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801083a5:	e9 16 f2 ff ff       	jmp    801075c0 <alltraps>

801083aa <vector190>:
.globl vector190
vector190:
  pushl $0
801083aa:	6a 00                	push   $0x0
  pushl $190
801083ac:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801083b1:	e9 0a f2 ff ff       	jmp    801075c0 <alltraps>

801083b6 <vector191>:
.globl vector191
vector191:
  pushl $0
801083b6:	6a 00                	push   $0x0
  pushl $191
801083b8:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801083bd:	e9 fe f1 ff ff       	jmp    801075c0 <alltraps>

801083c2 <vector192>:
.globl vector192
vector192:
  pushl $0
801083c2:	6a 00                	push   $0x0
  pushl $192
801083c4:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801083c9:	e9 f2 f1 ff ff       	jmp    801075c0 <alltraps>

801083ce <vector193>:
.globl vector193
vector193:
  pushl $0
801083ce:	6a 00                	push   $0x0
  pushl $193
801083d0:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801083d5:	e9 e6 f1 ff ff       	jmp    801075c0 <alltraps>

801083da <vector194>:
.globl vector194
vector194:
  pushl $0
801083da:	6a 00                	push   $0x0
  pushl $194
801083dc:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801083e1:	e9 da f1 ff ff       	jmp    801075c0 <alltraps>

801083e6 <vector195>:
.globl vector195
vector195:
  pushl $0
801083e6:	6a 00                	push   $0x0
  pushl $195
801083e8:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801083ed:	e9 ce f1 ff ff       	jmp    801075c0 <alltraps>

801083f2 <vector196>:
.globl vector196
vector196:
  pushl $0
801083f2:	6a 00                	push   $0x0
  pushl $196
801083f4:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801083f9:	e9 c2 f1 ff ff       	jmp    801075c0 <alltraps>

801083fe <vector197>:
.globl vector197
vector197:
  pushl $0
801083fe:	6a 00                	push   $0x0
  pushl $197
80108400:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80108405:	e9 b6 f1 ff ff       	jmp    801075c0 <alltraps>

8010840a <vector198>:
.globl vector198
vector198:
  pushl $0
8010840a:	6a 00                	push   $0x0
  pushl $198
8010840c:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80108411:	e9 aa f1 ff ff       	jmp    801075c0 <alltraps>

80108416 <vector199>:
.globl vector199
vector199:
  pushl $0
80108416:	6a 00                	push   $0x0
  pushl $199
80108418:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
8010841d:	e9 9e f1 ff ff       	jmp    801075c0 <alltraps>

80108422 <vector200>:
.globl vector200
vector200:
  pushl $0
80108422:	6a 00                	push   $0x0
  pushl $200
80108424:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80108429:	e9 92 f1 ff ff       	jmp    801075c0 <alltraps>

8010842e <vector201>:
.globl vector201
vector201:
  pushl $0
8010842e:	6a 00                	push   $0x0
  pushl $201
80108430:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80108435:	e9 86 f1 ff ff       	jmp    801075c0 <alltraps>

8010843a <vector202>:
.globl vector202
vector202:
  pushl $0
8010843a:	6a 00                	push   $0x0
  pushl $202
8010843c:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80108441:	e9 7a f1 ff ff       	jmp    801075c0 <alltraps>

80108446 <vector203>:
.globl vector203
vector203:
  pushl $0
80108446:	6a 00                	push   $0x0
  pushl $203
80108448:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010844d:	e9 6e f1 ff ff       	jmp    801075c0 <alltraps>

80108452 <vector204>:
.globl vector204
vector204:
  pushl $0
80108452:	6a 00                	push   $0x0
  pushl $204
80108454:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108459:	e9 62 f1 ff ff       	jmp    801075c0 <alltraps>

8010845e <vector205>:
.globl vector205
vector205:
  pushl $0
8010845e:	6a 00                	push   $0x0
  pushl $205
80108460:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108465:	e9 56 f1 ff ff       	jmp    801075c0 <alltraps>

8010846a <vector206>:
.globl vector206
vector206:
  pushl $0
8010846a:	6a 00                	push   $0x0
  pushl $206
8010846c:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80108471:	e9 4a f1 ff ff       	jmp    801075c0 <alltraps>

80108476 <vector207>:
.globl vector207
vector207:
  pushl $0
80108476:	6a 00                	push   $0x0
  pushl $207
80108478:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010847d:	e9 3e f1 ff ff       	jmp    801075c0 <alltraps>

80108482 <vector208>:
.globl vector208
vector208:
  pushl $0
80108482:	6a 00                	push   $0x0
  pushl $208
80108484:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108489:	e9 32 f1 ff ff       	jmp    801075c0 <alltraps>

8010848e <vector209>:
.globl vector209
vector209:
  pushl $0
8010848e:	6a 00                	push   $0x0
  pushl $209
80108490:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108495:	e9 26 f1 ff ff       	jmp    801075c0 <alltraps>

8010849a <vector210>:
.globl vector210
vector210:
  pushl $0
8010849a:	6a 00                	push   $0x0
  pushl $210
8010849c:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801084a1:	e9 1a f1 ff ff       	jmp    801075c0 <alltraps>

801084a6 <vector211>:
.globl vector211
vector211:
  pushl $0
801084a6:	6a 00                	push   $0x0
  pushl $211
801084a8:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801084ad:	e9 0e f1 ff ff       	jmp    801075c0 <alltraps>

801084b2 <vector212>:
.globl vector212
vector212:
  pushl $0
801084b2:	6a 00                	push   $0x0
  pushl $212
801084b4:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801084b9:	e9 02 f1 ff ff       	jmp    801075c0 <alltraps>

801084be <vector213>:
.globl vector213
vector213:
  pushl $0
801084be:	6a 00                	push   $0x0
  pushl $213
801084c0:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801084c5:	e9 f6 f0 ff ff       	jmp    801075c0 <alltraps>

801084ca <vector214>:
.globl vector214
vector214:
  pushl $0
801084ca:	6a 00                	push   $0x0
  pushl $214
801084cc:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801084d1:	e9 ea f0 ff ff       	jmp    801075c0 <alltraps>

801084d6 <vector215>:
.globl vector215
vector215:
  pushl $0
801084d6:	6a 00                	push   $0x0
  pushl $215
801084d8:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801084dd:	e9 de f0 ff ff       	jmp    801075c0 <alltraps>

801084e2 <vector216>:
.globl vector216
vector216:
  pushl $0
801084e2:	6a 00                	push   $0x0
  pushl $216
801084e4:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801084e9:	e9 d2 f0 ff ff       	jmp    801075c0 <alltraps>

801084ee <vector217>:
.globl vector217
vector217:
  pushl $0
801084ee:	6a 00                	push   $0x0
  pushl $217
801084f0:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801084f5:	e9 c6 f0 ff ff       	jmp    801075c0 <alltraps>

801084fa <vector218>:
.globl vector218
vector218:
  pushl $0
801084fa:	6a 00                	push   $0x0
  pushl $218
801084fc:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80108501:	e9 ba f0 ff ff       	jmp    801075c0 <alltraps>

80108506 <vector219>:
.globl vector219
vector219:
  pushl $0
80108506:	6a 00                	push   $0x0
  pushl $219
80108508:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
8010850d:	e9 ae f0 ff ff       	jmp    801075c0 <alltraps>

80108512 <vector220>:
.globl vector220
vector220:
  pushl $0
80108512:	6a 00                	push   $0x0
  pushl $220
80108514:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80108519:	e9 a2 f0 ff ff       	jmp    801075c0 <alltraps>

8010851e <vector221>:
.globl vector221
vector221:
  pushl $0
8010851e:	6a 00                	push   $0x0
  pushl $221
80108520:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80108525:	e9 96 f0 ff ff       	jmp    801075c0 <alltraps>

8010852a <vector222>:
.globl vector222
vector222:
  pushl $0
8010852a:	6a 00                	push   $0x0
  pushl $222
8010852c:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80108531:	e9 8a f0 ff ff       	jmp    801075c0 <alltraps>

80108536 <vector223>:
.globl vector223
vector223:
  pushl $0
80108536:	6a 00                	push   $0x0
  pushl $223
80108538:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
8010853d:	e9 7e f0 ff ff       	jmp    801075c0 <alltraps>

80108542 <vector224>:
.globl vector224
vector224:
  pushl $0
80108542:	6a 00                	push   $0x0
  pushl $224
80108544:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80108549:	e9 72 f0 ff ff       	jmp    801075c0 <alltraps>

8010854e <vector225>:
.globl vector225
vector225:
  pushl $0
8010854e:	6a 00                	push   $0x0
  pushl $225
80108550:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108555:	e9 66 f0 ff ff       	jmp    801075c0 <alltraps>

8010855a <vector226>:
.globl vector226
vector226:
  pushl $0
8010855a:	6a 00                	push   $0x0
  pushl $226
8010855c:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80108561:	e9 5a f0 ff ff       	jmp    801075c0 <alltraps>

80108566 <vector227>:
.globl vector227
vector227:
  pushl $0
80108566:	6a 00                	push   $0x0
  pushl $227
80108568:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010856d:	e9 4e f0 ff ff       	jmp    801075c0 <alltraps>

80108572 <vector228>:
.globl vector228
vector228:
  pushl $0
80108572:	6a 00                	push   $0x0
  pushl $228
80108574:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108579:	e9 42 f0 ff ff       	jmp    801075c0 <alltraps>

8010857e <vector229>:
.globl vector229
vector229:
  pushl $0
8010857e:	6a 00                	push   $0x0
  pushl $229
80108580:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108585:	e9 36 f0 ff ff       	jmp    801075c0 <alltraps>

8010858a <vector230>:
.globl vector230
vector230:
  pushl $0
8010858a:	6a 00                	push   $0x0
  pushl $230
8010858c:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80108591:	e9 2a f0 ff ff       	jmp    801075c0 <alltraps>

80108596 <vector231>:
.globl vector231
vector231:
  pushl $0
80108596:	6a 00                	push   $0x0
  pushl $231
80108598:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010859d:	e9 1e f0 ff ff       	jmp    801075c0 <alltraps>

801085a2 <vector232>:
.globl vector232
vector232:
  pushl $0
801085a2:	6a 00                	push   $0x0
  pushl $232
801085a4:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801085a9:	e9 12 f0 ff ff       	jmp    801075c0 <alltraps>

801085ae <vector233>:
.globl vector233
vector233:
  pushl $0
801085ae:	6a 00                	push   $0x0
  pushl $233
801085b0:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801085b5:	e9 06 f0 ff ff       	jmp    801075c0 <alltraps>

801085ba <vector234>:
.globl vector234
vector234:
  pushl $0
801085ba:	6a 00                	push   $0x0
  pushl $234
801085bc:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801085c1:	e9 fa ef ff ff       	jmp    801075c0 <alltraps>

801085c6 <vector235>:
.globl vector235
vector235:
  pushl $0
801085c6:	6a 00                	push   $0x0
  pushl $235
801085c8:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801085cd:	e9 ee ef ff ff       	jmp    801075c0 <alltraps>

801085d2 <vector236>:
.globl vector236
vector236:
  pushl $0
801085d2:	6a 00                	push   $0x0
  pushl $236
801085d4:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801085d9:	e9 e2 ef ff ff       	jmp    801075c0 <alltraps>

801085de <vector237>:
.globl vector237
vector237:
  pushl $0
801085de:	6a 00                	push   $0x0
  pushl $237
801085e0:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801085e5:	e9 d6 ef ff ff       	jmp    801075c0 <alltraps>

801085ea <vector238>:
.globl vector238
vector238:
  pushl $0
801085ea:	6a 00                	push   $0x0
  pushl $238
801085ec:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801085f1:	e9 ca ef ff ff       	jmp    801075c0 <alltraps>

801085f6 <vector239>:
.globl vector239
vector239:
  pushl $0
801085f6:	6a 00                	push   $0x0
  pushl $239
801085f8:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801085fd:	e9 be ef ff ff       	jmp    801075c0 <alltraps>

80108602 <vector240>:
.globl vector240
vector240:
  pushl $0
80108602:	6a 00                	push   $0x0
  pushl $240
80108604:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80108609:	e9 b2 ef ff ff       	jmp    801075c0 <alltraps>

8010860e <vector241>:
.globl vector241
vector241:
  pushl $0
8010860e:	6a 00                	push   $0x0
  pushl $241
80108610:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80108615:	e9 a6 ef ff ff       	jmp    801075c0 <alltraps>

8010861a <vector242>:
.globl vector242
vector242:
  pushl $0
8010861a:	6a 00                	push   $0x0
  pushl $242
8010861c:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80108621:	e9 9a ef ff ff       	jmp    801075c0 <alltraps>

80108626 <vector243>:
.globl vector243
vector243:
  pushl $0
80108626:	6a 00                	push   $0x0
  pushl $243
80108628:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
8010862d:	e9 8e ef ff ff       	jmp    801075c0 <alltraps>

80108632 <vector244>:
.globl vector244
vector244:
  pushl $0
80108632:	6a 00                	push   $0x0
  pushl $244
80108634:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80108639:	e9 82 ef ff ff       	jmp    801075c0 <alltraps>

8010863e <vector245>:
.globl vector245
vector245:
  pushl $0
8010863e:	6a 00                	push   $0x0
  pushl $245
80108640:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80108645:	e9 76 ef ff ff       	jmp    801075c0 <alltraps>

8010864a <vector246>:
.globl vector246
vector246:
  pushl $0
8010864a:	6a 00                	push   $0x0
  pushl $246
8010864c:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80108651:	e9 6a ef ff ff       	jmp    801075c0 <alltraps>

80108656 <vector247>:
.globl vector247
vector247:
  pushl $0
80108656:	6a 00                	push   $0x0
  pushl $247
80108658:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010865d:	e9 5e ef ff ff       	jmp    801075c0 <alltraps>

80108662 <vector248>:
.globl vector248
vector248:
  pushl $0
80108662:	6a 00                	push   $0x0
  pushl $248
80108664:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108669:	e9 52 ef ff ff       	jmp    801075c0 <alltraps>

8010866e <vector249>:
.globl vector249
vector249:
  pushl $0
8010866e:	6a 00                	push   $0x0
  pushl $249
80108670:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108675:	e9 46 ef ff ff       	jmp    801075c0 <alltraps>

8010867a <vector250>:
.globl vector250
vector250:
  pushl $0
8010867a:	6a 00                	push   $0x0
  pushl $250
8010867c:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80108681:	e9 3a ef ff ff       	jmp    801075c0 <alltraps>

80108686 <vector251>:
.globl vector251
vector251:
  pushl $0
80108686:	6a 00                	push   $0x0
  pushl $251
80108688:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010868d:	e9 2e ef ff ff       	jmp    801075c0 <alltraps>

80108692 <vector252>:
.globl vector252
vector252:
  pushl $0
80108692:	6a 00                	push   $0x0
  pushl $252
80108694:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108699:	e9 22 ef ff ff       	jmp    801075c0 <alltraps>

8010869e <vector253>:
.globl vector253
vector253:
  pushl $0
8010869e:	6a 00                	push   $0x0
  pushl $253
801086a0:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801086a5:	e9 16 ef ff ff       	jmp    801075c0 <alltraps>

801086aa <vector254>:
.globl vector254
vector254:
  pushl $0
801086aa:	6a 00                	push   $0x0
  pushl $254
801086ac:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801086b1:	e9 0a ef ff ff       	jmp    801075c0 <alltraps>

801086b6 <vector255>:
.globl vector255
vector255:
  pushl $0
801086b6:	6a 00                	push   $0x0
  pushl $255
801086b8:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801086bd:	e9 fe ee ff ff       	jmp    801075c0 <alltraps>
	...

801086c4 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801086c4:	55                   	push   %ebp
801086c5:	89 e5                	mov    %esp,%ebp
801086c7:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801086ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801086cd:	83 e8 01             	sub    $0x1,%eax
801086d0:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801086d4:	8b 45 08             	mov    0x8(%ebp),%eax
801086d7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801086db:	8b 45 08             	mov    0x8(%ebp),%eax
801086de:	c1 e8 10             	shr    $0x10,%eax
801086e1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801086e5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801086e8:	0f 01 10             	lgdtl  (%eax)
}
801086eb:	c9                   	leave  
801086ec:	c3                   	ret    

801086ed <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801086ed:	55                   	push   %ebp
801086ee:	89 e5                	mov    %esp,%ebp
801086f0:	83 ec 04             	sub    $0x4,%esp
801086f3:	8b 45 08             	mov    0x8(%ebp),%eax
801086f6:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801086fa:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801086fe:	0f 00 d8             	ltr    %ax
}
80108701:	c9                   	leave  
80108702:	c3                   	ret    

80108703 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80108703:	55                   	push   %ebp
80108704:	89 e5                	mov    %esp,%ebp
80108706:	83 ec 04             	sub    $0x4,%esp
80108709:	8b 45 08             	mov    0x8(%ebp),%eax
8010870c:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80108710:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80108714:	8e e8                	mov    %eax,%gs
}
80108716:	c9                   	leave  
80108717:	c3                   	ret    

80108718 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80108718:	55                   	push   %ebp
80108719:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010871b:	8b 45 08             	mov    0x8(%ebp),%eax
8010871e:	0f 22 d8             	mov    %eax,%cr3
}
80108721:	5d                   	pop    %ebp
80108722:	c3                   	ret    

80108723 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80108723:	55                   	push   %ebp
80108724:	89 e5                	mov    %esp,%ebp
80108726:	8b 45 08             	mov    0x8(%ebp),%eax
80108729:	05 00 00 00 80       	add    $0x80000000,%eax
8010872e:	5d                   	pop    %ebp
8010872f:	c3                   	ret    

80108730 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80108730:	55                   	push   %ebp
80108731:	89 e5                	mov    %esp,%ebp
80108733:	8b 45 08             	mov    0x8(%ebp),%eax
80108736:	05 00 00 00 80       	add    $0x80000000,%eax
8010873b:	5d                   	pop    %ebp
8010873c:	c3                   	ret    

8010873d <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
8010873d:	55                   	push   %ebp
8010873e:	89 e5                	mov    %esp,%ebp
80108740:	53                   	push   %ebx
80108741:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108744:	e8 48 b9 ff ff       	call   80104091 <cpunum>
80108749:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010874f:	05 60 09 11 80       	add    $0x80110960,%eax
80108754:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010875a:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80108760:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108763:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010876c:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80108770:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108773:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108777:	83 e2 f0             	and    $0xfffffff0,%edx
8010877a:	83 ca 0a             	or     $0xa,%edx
8010877d:	88 50 7d             	mov    %dl,0x7d(%eax)
80108780:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108783:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108787:	83 ca 10             	or     $0x10,%edx
8010878a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010878d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108790:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108794:	83 e2 9f             	and    $0xffffff9f,%edx
80108797:	88 50 7d             	mov    %dl,0x7d(%eax)
8010879a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879d:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801087a1:	83 ca 80             	or     $0xffffff80,%edx
801087a4:	88 50 7d             	mov    %dl,0x7d(%eax)
801087a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087aa:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801087ae:	83 ca 0f             	or     $0xf,%edx
801087b1:	88 50 7e             	mov    %dl,0x7e(%eax)
801087b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087b7:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801087bb:	83 e2 ef             	and    $0xffffffef,%edx
801087be:	88 50 7e             	mov    %dl,0x7e(%eax)
801087c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087c4:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801087c8:	83 e2 df             	and    $0xffffffdf,%edx
801087cb:	88 50 7e             	mov    %dl,0x7e(%eax)
801087ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087d1:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801087d5:	83 ca 40             	or     $0x40,%edx
801087d8:	88 50 7e             	mov    %dl,0x7e(%eax)
801087db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087de:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801087e2:	83 ca 80             	or     $0xffffff80,%edx
801087e5:	88 50 7e             	mov    %dl,0x7e(%eax)
801087e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087eb:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801087ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f2:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801087f9:	ff ff 
801087fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087fe:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80108805:	00 00 
80108807:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010880a:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80108811:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108814:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010881b:	83 e2 f0             	and    $0xfffffff0,%edx
8010881e:	83 ca 02             	or     $0x2,%edx
80108821:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108827:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882a:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108831:	83 ca 10             	or     $0x10,%edx
80108834:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010883a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010883d:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108844:	83 e2 9f             	and    $0xffffff9f,%edx
80108847:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010884d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108850:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108857:	83 ca 80             	or     $0xffffff80,%edx
8010885a:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108860:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108863:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010886a:	83 ca 0f             	or     $0xf,%edx
8010886d:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108873:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108876:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010887d:	83 e2 ef             	and    $0xffffffef,%edx
80108880:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108886:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108889:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108890:	83 e2 df             	and    $0xffffffdf,%edx
80108893:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108899:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010889c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801088a3:	83 ca 40             	or     $0x40,%edx
801088a6:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801088ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088af:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801088b6:	83 ca 80             	or     $0xffffff80,%edx
801088b9:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801088bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088c2:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801088c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088cc:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801088d3:	ff ff 
801088d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088d8:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801088df:	00 00 
801088e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e4:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801088eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088ee:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801088f5:	83 e2 f0             	and    $0xfffffff0,%edx
801088f8:	83 ca 0a             	or     $0xa,%edx
801088fb:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108901:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108904:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010890b:	83 ca 10             	or     $0x10,%edx
8010890e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108914:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108917:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010891e:	83 ca 60             	or     $0x60,%edx
80108921:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80108927:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010892a:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80108931:	83 ca 80             	or     $0xffffff80,%edx
80108934:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010893a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010893d:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108944:	83 ca 0f             	or     $0xf,%edx
80108947:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010894d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108950:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108957:	83 e2 ef             	and    $0xffffffef,%edx
8010895a:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108963:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010896a:	83 e2 df             	and    $0xffffffdf,%edx
8010896d:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108976:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010897d:	83 ca 40             	or     $0x40,%edx
80108980:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108986:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108989:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108990:	83 ca 80             	or     $0xffffff80,%edx
80108993:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010899c:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801089a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089a6:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801089ad:	ff ff 
801089af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089b2:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801089b9:	00 00 
801089bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089be:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801089c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089c8:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801089cf:	83 e2 f0             	and    $0xfffffff0,%edx
801089d2:	83 ca 02             	or     $0x2,%edx
801089d5:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801089db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089de:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801089e5:	83 ca 10             	or     $0x10,%edx
801089e8:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801089ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801089f1:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801089f8:	83 ca 60             	or     $0x60,%edx
801089fb:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a04:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80108a0b:	83 ca 80             	or     $0xffffff80,%edx
80108a0e:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a17:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108a1e:	83 ca 0f             	or     $0xf,%edx
80108a21:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a2a:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108a31:	83 e2 ef             	and    $0xffffffef,%edx
80108a34:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108a3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a3d:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108a44:	83 e2 df             	and    $0xffffffdf,%edx
80108a47:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108a4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a50:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108a57:	83 ca 40             	or     $0x40,%edx
80108a5a:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108a60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a63:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108a6a:	83 ca 80             	or     $0xffffff80,%edx
80108a6d:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108a73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a76:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a80:	05 b4 00 00 00       	add    $0xb4,%eax
80108a85:	89 c3                	mov    %eax,%ebx
80108a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a8a:	05 b4 00 00 00       	add    $0xb4,%eax
80108a8f:	c1 e8 10             	shr    $0x10,%eax
80108a92:	89 c1                	mov    %eax,%ecx
80108a94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a97:	05 b4 00 00 00       	add    $0xb4,%eax
80108a9c:	c1 e8 18             	shr    $0x18,%eax
80108a9f:	89 c2                	mov    %eax,%edx
80108aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aa4:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108aab:	00 00 
80108aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ab0:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108ab7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aba:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80108ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ac3:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108aca:	83 e1 f0             	and    $0xfffffff0,%ecx
80108acd:	83 c9 02             	or     $0x2,%ecx
80108ad0:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108ad9:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108ae0:	83 c9 10             	or     $0x10,%ecx
80108ae3:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aec:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108af3:	83 e1 9f             	and    $0xffffff9f,%ecx
80108af6:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108aff:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108b06:	83 c9 80             	or     $0xffffff80,%ecx
80108b09:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b12:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108b19:	83 e1 f0             	and    $0xfffffff0,%ecx
80108b1c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b25:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108b2c:	83 e1 ef             	and    $0xffffffef,%ecx
80108b2f:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108b35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b38:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108b3f:	83 e1 df             	and    $0xffffffdf,%ecx
80108b42:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b4b:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108b52:	83 c9 40             	or     $0x40,%ecx
80108b55:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b5e:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108b65:	83 c9 80             	or     $0xffffff80,%ecx
80108b68:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108b6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b71:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108b77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b7a:	83 c0 70             	add    $0x70,%eax
80108b7d:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108b84:	00 
80108b85:	89 04 24             	mov    %eax,(%esp)
80108b88:	e8 37 fb ff ff       	call   801086c4 <lgdt>
  loadgs(SEG_KCPU << 3);
80108b8d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108b94:	e8 6a fb ff ff       	call   80108703 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108b99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108b9c:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80108ba2:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108ba9:	00 00 00 00 
}
80108bad:	83 c4 24             	add    $0x24,%esp
80108bb0:	5b                   	pop    %ebx
80108bb1:	5d                   	pop    %ebp
80108bb2:	c3                   	ret    

80108bb3 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80108bb3:	55                   	push   %ebp
80108bb4:	89 e5                	mov    %esp,%ebp
80108bb6:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80108bbc:	c1 e8 16             	shr    $0x16,%eax
80108bbf:	c1 e0 02             	shl    $0x2,%eax
80108bc2:	03 45 08             	add    0x8(%ebp),%eax
80108bc5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80108bc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bcb:	8b 00                	mov    (%eax),%eax
80108bcd:	83 e0 01             	and    $0x1,%eax
80108bd0:	84 c0                	test   %al,%al
80108bd2:	74 17                	je     80108beb <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108bd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108bd7:	8b 00                	mov    (%eax),%eax
80108bd9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108bde:	89 04 24             	mov    %eax,(%esp)
80108be1:	e8 4a fb ff ff       	call   80108730 <p2v>
80108be6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108be9:	eb 4b                	jmp    80108c36 <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80108beb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80108bef:	74 0e                	je     80108bff <walkpgdir+0x4c>
80108bf1:	e8 0d b1 ff ff       	call   80103d03 <kalloc>
80108bf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108bf9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108bfd:	75 07                	jne    80108c06 <walkpgdir+0x53>
      return 0;
80108bff:	b8 00 00 00 00       	mov    $0x0,%eax
80108c04:	eb 41                	jmp    80108c47 <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80108c06:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c0d:	00 
80108c0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c15:	00 
80108c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c19:	89 04 24             	mov    %eax,(%esp)
80108c1c:	e8 d5 d3 ff ff       	call   80105ff6 <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80108c21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c24:	89 04 24             	mov    %eax,(%esp)
80108c27:	e8 f7 fa ff ff       	call   80108723 <v2p>
80108c2c:	89 c2                	mov    %eax,%edx
80108c2e:	83 ca 07             	or     $0x7,%edx
80108c31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108c34:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80108c36:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c39:	c1 e8 0c             	shr    $0xc,%eax
80108c3c:	25 ff 03 00 00       	and    $0x3ff,%eax
80108c41:	c1 e0 02             	shl    $0x2,%eax
80108c44:	03 45 f4             	add    -0xc(%ebp),%eax
}
80108c47:	c9                   	leave  
80108c48:	c3                   	ret    

80108c49 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108c49:	55                   	push   %ebp
80108c4a:	89 e5                	mov    %esp,%ebp
80108c4c:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108c4f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c52:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c57:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c5d:	03 45 10             	add    0x10(%ebp),%eax
80108c60:	83 e8 01             	sub    $0x1,%eax
80108c63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108c68:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108c6b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80108c72:	00 
80108c73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c76:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c7a:	8b 45 08             	mov    0x8(%ebp),%eax
80108c7d:	89 04 24             	mov    %eax,(%esp)
80108c80:	e8 2e ff ff ff       	call   80108bb3 <walkpgdir>
80108c85:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108c88:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108c8c:	75 07                	jne    80108c95 <mappages+0x4c>
      return -1;
80108c8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108c93:	eb 46                	jmp    80108cdb <mappages+0x92>
    if(*pte & PTE_P)
80108c95:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108c98:	8b 00                	mov    (%eax),%eax
80108c9a:	83 e0 01             	and    $0x1,%eax
80108c9d:	84 c0                	test   %al,%al
80108c9f:	74 0c                	je     80108cad <mappages+0x64>
      panic("remap");
80108ca1:	c7 04 24 88 9b 10 80 	movl   $0x80109b88,(%esp)
80108ca8:	e8 90 78 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108cad:	8b 45 18             	mov    0x18(%ebp),%eax
80108cb0:	0b 45 14             	or     0x14(%ebp),%eax
80108cb3:	89 c2                	mov    %eax,%edx
80108cb5:	83 ca 01             	or     $0x1,%edx
80108cb8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108cbb:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108cbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cc0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108cc3:	74 10                	je     80108cd5 <mappages+0x8c>
      break;
    a += PGSIZE;
80108cc5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108ccc:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80108cd3:	eb 96                	jmp    80108c6b <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80108cd5:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108cd6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108cdb:	c9                   	leave  
80108cdc:	c3                   	ret    

80108cdd <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108cdd:	55                   	push   %ebp
80108cde:	89 e5                	mov    %esp,%ebp
80108ce0:	53                   	push   %ebx
80108ce1:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80108ce4:	e8 1a b0 ff ff       	call   80103d03 <kalloc>
80108ce9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108cec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108cf0:	75 0a                	jne    80108cfc <setupkvm+0x1f>
    return 0;
80108cf2:	b8 00 00 00 00       	mov    $0x0,%eax
80108cf7:	e9 98 00 00 00       	jmp    80108d94 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108cfc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108d03:	00 
80108d04:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108d0b:	00 
80108d0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d0f:	89 04 24             	mov    %eax,(%esp)
80108d12:	e8 df d2 ff ff       	call   80105ff6 <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80108d17:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80108d1e:	e8 0d fa ff ff       	call   80108730 <p2v>
80108d23:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80108d28:	76 0c                	jbe    80108d36 <setupkvm+0x59>
    panic("PHYSTOP too high");
80108d2a:	c7 04 24 8e 9b 10 80 	movl   $0x80109b8e,(%esp)
80108d31:	e8 07 78 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108d36:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108d3d:	eb 49                	jmp    80108d88 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80108d3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108d42:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80108d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108d48:	8b 50 04             	mov    0x4(%eax),%edx
80108d4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d4e:	8b 58 08             	mov    0x8(%eax),%ebx
80108d51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d54:	8b 40 04             	mov    0x4(%eax),%eax
80108d57:	29 c3                	sub    %eax,%ebx
80108d59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d5c:	8b 00                	mov    (%eax),%eax
80108d5e:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108d62:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108d66:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108d71:	89 04 24             	mov    %eax,(%esp)
80108d74:	e8 d0 fe ff ff       	call   80108c49 <mappages>
80108d79:	85 c0                	test   %eax,%eax
80108d7b:	79 07                	jns    80108d84 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108d7d:	b8 00 00 00 00       	mov    $0x0,%eax
80108d82:	eb 10                	jmp    80108d94 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108d84:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108d88:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108d8f:	72 ae                	jb     80108d3f <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108d91:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108d94:	83 c4 34             	add    $0x34,%esp
80108d97:	5b                   	pop    %ebx
80108d98:	5d                   	pop    %ebp
80108d99:	c3                   	ret    

80108d9a <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108d9a:	55                   	push   %ebp
80108d9b:	89 e5                	mov    %esp,%ebp
80108d9d:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108da0:	e8 38 ff ff ff       	call   80108cdd <setupkvm>
80108da5:	a3 38 37 11 80       	mov    %eax,0x80113738
  switchkvm();
80108daa:	e8 02 00 00 00       	call   80108db1 <switchkvm>
}
80108daf:	c9                   	leave  
80108db0:	c3                   	ret    

80108db1 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108db1:	55                   	push   %ebp
80108db2:	89 e5                	mov    %esp,%ebp
80108db4:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108db7:	a1 38 37 11 80       	mov    0x80113738,%eax
80108dbc:	89 04 24             	mov    %eax,(%esp)
80108dbf:	e8 5f f9 ff ff       	call   80108723 <v2p>
80108dc4:	89 04 24             	mov    %eax,(%esp)
80108dc7:	e8 4c f9 ff ff       	call   80108718 <lcr3>
}
80108dcc:	c9                   	leave  
80108dcd:	c3                   	ret    

80108dce <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108dce:	55                   	push   %ebp
80108dcf:	89 e5                	mov    %esp,%ebp
80108dd1:	53                   	push   %ebx
80108dd2:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108dd5:	e8 15 d1 ff ff       	call   80105eef <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108dda:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108de0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108de7:	83 c2 08             	add    $0x8,%edx
80108dea:	89 d3                	mov    %edx,%ebx
80108dec:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108df3:	83 c2 08             	add    $0x8,%edx
80108df6:	c1 ea 10             	shr    $0x10,%edx
80108df9:	89 d1                	mov    %edx,%ecx
80108dfb:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108e02:	83 c2 08             	add    $0x8,%edx
80108e05:	c1 ea 18             	shr    $0x18,%edx
80108e08:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108e0f:	67 00 
80108e11:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108e18:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108e1e:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108e25:	83 e1 f0             	and    $0xfffffff0,%ecx
80108e28:	83 c9 09             	or     $0x9,%ecx
80108e2b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108e31:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108e38:	83 c9 10             	or     $0x10,%ecx
80108e3b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108e41:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108e48:	83 e1 9f             	and    $0xffffff9f,%ecx
80108e4b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108e51:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108e58:	83 c9 80             	or     $0xffffff80,%ecx
80108e5b:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108e61:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e68:	83 e1 f0             	and    $0xfffffff0,%ecx
80108e6b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108e71:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e78:	83 e1 ef             	and    $0xffffffef,%ecx
80108e7b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108e81:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e88:	83 e1 df             	and    $0xffffffdf,%ecx
80108e8b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108e91:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108e98:	83 c9 40             	or     $0x40,%ecx
80108e9b:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108ea1:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108ea8:	83 e1 7f             	and    $0x7f,%ecx
80108eab:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108eb1:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108eb7:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108ebd:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108ec4:	83 e2 ef             	and    $0xffffffef,%edx
80108ec7:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108ecd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108ed3:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108ed9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108edf:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108ee6:	8b 52 08             	mov    0x8(%edx),%edx
80108ee9:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108eef:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108ef2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108ef9:	e8 ef f7 ff ff       	call   801086ed <ltr>
  if(p->pgdir == 0)
80108efe:	8b 45 08             	mov    0x8(%ebp),%eax
80108f01:	8b 40 04             	mov    0x4(%eax),%eax
80108f04:	85 c0                	test   %eax,%eax
80108f06:	75 0c                	jne    80108f14 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108f08:	c7 04 24 9f 9b 10 80 	movl   $0x80109b9f,(%esp)
80108f0f:	e8 29 76 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108f14:	8b 45 08             	mov    0x8(%ebp),%eax
80108f17:	8b 40 04             	mov    0x4(%eax),%eax
80108f1a:	89 04 24             	mov    %eax,(%esp)
80108f1d:	e8 01 f8 ff ff       	call   80108723 <v2p>
80108f22:	89 04 24             	mov    %eax,(%esp)
80108f25:	e8 ee f7 ff ff       	call   80108718 <lcr3>
  popcli();
80108f2a:	e8 08 d0 ff ff       	call   80105f37 <popcli>
}
80108f2f:	83 c4 14             	add    $0x14,%esp
80108f32:	5b                   	pop    %ebx
80108f33:	5d                   	pop    %ebp
80108f34:	c3                   	ret    

80108f35 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108f35:	55                   	push   %ebp
80108f36:	89 e5                	mov    %esp,%ebp
80108f38:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108f3b:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108f42:	76 0c                	jbe    80108f50 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108f44:	c7 04 24 b3 9b 10 80 	movl   $0x80109bb3,(%esp)
80108f4b:	e8 ed 75 ff ff       	call   8010053d <panic>
  mem = kalloc();
80108f50:	e8 ae ad ff ff       	call   80103d03 <kalloc>
80108f55:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108f58:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f5f:	00 
80108f60:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f67:	00 
80108f68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f6b:	89 04 24             	mov    %eax,(%esp)
80108f6e:	e8 83 d0 ff ff       	call   80105ff6 <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f76:	89 04 24             	mov    %eax,(%esp)
80108f79:	e8 a5 f7 ff ff       	call   80108723 <v2p>
80108f7e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108f85:	00 
80108f86:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108f8a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108f91:	00 
80108f92:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108f99:	00 
80108f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80108f9d:	89 04 24             	mov    %eax,(%esp)
80108fa0:	e8 a4 fc ff ff       	call   80108c49 <mappages>
  memmove(mem, init, sz);
80108fa5:	8b 45 10             	mov    0x10(%ebp),%eax
80108fa8:	89 44 24 08          	mov    %eax,0x8(%esp)
80108fac:	8b 45 0c             	mov    0xc(%ebp),%eax
80108faf:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fb6:	89 04 24             	mov    %eax,(%esp)
80108fb9:	e8 0b d1 ff ff       	call   801060c9 <memmove>
}
80108fbe:	c9                   	leave  
80108fbf:	c3                   	ret    

80108fc0 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108fc0:	55                   	push   %ebp
80108fc1:	89 e5                	mov    %esp,%ebp
80108fc3:	53                   	push   %ebx
80108fc4:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80108fca:	25 ff 0f 00 00       	and    $0xfff,%eax
80108fcf:	85 c0                	test   %eax,%eax
80108fd1:	74 0c                	je     80108fdf <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108fd3:	c7 04 24 d0 9b 10 80 	movl   $0x80109bd0,(%esp)
80108fda:	e8 5e 75 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108fdf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108fe6:	e9 ad 00 00 00       	jmp    80109098 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108feb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fee:	8b 55 0c             	mov    0xc(%ebp),%edx
80108ff1:	01 d0                	add    %edx,%eax
80108ff3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108ffa:	00 
80108ffb:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fff:	8b 45 08             	mov    0x8(%ebp),%eax
80109002:	89 04 24             	mov    %eax,(%esp)
80109005:	e8 a9 fb ff ff       	call   80108bb3 <walkpgdir>
8010900a:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010900d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109011:	75 0c                	jne    8010901f <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80109013:	c7 04 24 f3 9b 10 80 	movl   $0x80109bf3,(%esp)
8010901a:	e8 1e 75 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010901f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109022:	8b 00                	mov    (%eax),%eax
80109024:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109029:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
8010902c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010902f:	8b 55 18             	mov    0x18(%ebp),%edx
80109032:	89 d1                	mov    %edx,%ecx
80109034:	29 c1                	sub    %eax,%ecx
80109036:	89 c8                	mov    %ecx,%eax
80109038:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010903d:	77 11                	ja     80109050 <loaduvm+0x90>
      n = sz - i;
8010903f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109042:	8b 55 18             	mov    0x18(%ebp),%edx
80109045:	89 d1                	mov    %edx,%ecx
80109047:	29 c1                	sub    %eax,%ecx
80109049:	89 c8                	mov    %ecx,%eax
8010904b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010904e:	eb 07                	jmp    80109057 <loaduvm+0x97>
    else
      n = PGSIZE;
80109050:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80109057:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010905a:	8b 55 14             	mov    0x14(%ebp),%edx
8010905d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80109060:	8b 45 e8             	mov    -0x18(%ebp),%eax
80109063:	89 04 24             	mov    %eax,(%esp)
80109066:	e8 c5 f6 ff ff       	call   80108730 <p2v>
8010906b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010906e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80109072:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80109076:	89 44 24 04          	mov    %eax,0x4(%esp)
8010907a:	8b 45 10             	mov    0x10(%ebp),%eax
8010907d:	89 04 24             	mov    %eax,(%esp)
80109080:	e8 51 9b ff ff       	call   80102bd6 <readi>
80109085:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80109088:	74 07                	je     80109091 <loaduvm+0xd1>
      return -1;
8010908a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010908f:	eb 18                	jmp    801090a9 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80109091:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109098:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010909b:	3b 45 18             	cmp    0x18(%ebp),%eax
8010909e:	0f 82 47 ff ff ff    	jb     80108feb <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801090a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801090a9:	83 c4 24             	add    $0x24,%esp
801090ac:	5b                   	pop    %ebx
801090ad:	5d                   	pop    %ebp
801090ae:	c3                   	ret    

801090af <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801090af:	55                   	push   %ebp
801090b0:	89 e5                	mov    %esp,%ebp
801090b2:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
801090b5:	8b 45 10             	mov    0x10(%ebp),%eax
801090b8:	85 c0                	test   %eax,%eax
801090ba:	79 0a                	jns    801090c6 <allocuvm+0x17>
    return 0;
801090bc:	b8 00 00 00 00       	mov    $0x0,%eax
801090c1:	e9 c1 00 00 00       	jmp    80109187 <allocuvm+0xd8>
  if(newsz < oldsz)
801090c6:	8b 45 10             	mov    0x10(%ebp),%eax
801090c9:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090cc:	73 08                	jae    801090d6 <allocuvm+0x27>
    return oldsz;
801090ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801090d1:	e9 b1 00 00 00       	jmp    80109187 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801090d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801090d9:	05 ff 0f 00 00       	add    $0xfff,%eax
801090de:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801090e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801090e6:	e9 8d 00 00 00       	jmp    80109178 <allocuvm+0xc9>
    mem = kalloc();
801090eb:	e8 13 ac ff ff       	call   80103d03 <kalloc>
801090f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801090f3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801090f7:	75 2c                	jne    80109125 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801090f9:	c7 04 24 11 9c 10 80 	movl   $0x80109c11,(%esp)
80109100:	e8 9c 72 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80109105:	8b 45 0c             	mov    0xc(%ebp),%eax
80109108:	89 44 24 08          	mov    %eax,0x8(%esp)
8010910c:	8b 45 10             	mov    0x10(%ebp),%eax
8010910f:	89 44 24 04          	mov    %eax,0x4(%esp)
80109113:	8b 45 08             	mov    0x8(%ebp),%eax
80109116:	89 04 24             	mov    %eax,(%esp)
80109119:	e8 6b 00 00 00       	call   80109189 <deallocuvm>
      return 0;
8010911e:	b8 00 00 00 00       	mov    $0x0,%eax
80109123:	eb 62                	jmp    80109187 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80109125:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010912c:	00 
8010912d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80109134:	00 
80109135:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109138:	89 04 24             	mov    %eax,(%esp)
8010913b:	e8 b6 ce ff ff       	call   80105ff6 <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80109140:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109143:	89 04 24             	mov    %eax,(%esp)
80109146:	e8 d8 f5 ff ff       	call   80108723 <v2p>
8010914b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010914e:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80109155:	00 
80109156:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010915a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80109161:	00 
80109162:	89 54 24 04          	mov    %edx,0x4(%esp)
80109166:	8b 45 08             	mov    0x8(%ebp),%eax
80109169:	89 04 24             	mov    %eax,(%esp)
8010916c:	e8 d8 fa ff ff       	call   80108c49 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80109171:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109178:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010917b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010917e:	0f 82 67 ff ff ff    	jb     801090eb <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80109184:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109187:	c9                   	leave  
80109188:	c3                   	ret    

80109189 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80109189:	55                   	push   %ebp
8010918a:	89 e5                	mov    %esp,%ebp
8010918c:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010918f:	8b 45 10             	mov    0x10(%ebp),%eax
80109192:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109195:	72 08                	jb     8010919f <deallocuvm+0x16>
    return oldsz;
80109197:	8b 45 0c             	mov    0xc(%ebp),%eax
8010919a:	e9 a4 00 00 00       	jmp    80109243 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010919f:	8b 45 10             	mov    0x10(%ebp),%eax
801091a2:	05 ff 0f 00 00       	add    $0xfff,%eax
801091a7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
801091af:	e9 80 00 00 00       	jmp    80109234 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
801091b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091b7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801091be:	00 
801091bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801091c3:	8b 45 08             	mov    0x8(%ebp),%eax
801091c6:	89 04 24             	mov    %eax,(%esp)
801091c9:	e8 e5 f9 ff ff       	call   80108bb3 <walkpgdir>
801091ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
801091d1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801091d5:	75 09                	jne    801091e0 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801091d7:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801091de:	eb 4d                	jmp    8010922d <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801091e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091e3:	8b 00                	mov    (%eax),%eax
801091e5:	83 e0 01             	and    $0x1,%eax
801091e8:	84 c0                	test   %al,%al
801091ea:	74 41                	je     8010922d <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801091ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091ef:	8b 00                	mov    (%eax),%eax
801091f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801091f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801091f9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801091fd:	75 0c                	jne    8010920b <deallocuvm+0x82>
        panic("kfree");
801091ff:	c7 04 24 29 9c 10 80 	movl   $0x80109c29,(%esp)
80109206:	e8 32 73 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
8010920b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010920e:	89 04 24             	mov    %eax,(%esp)
80109211:	e8 1a f5 ff ff       	call   80108730 <p2v>
80109216:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80109219:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010921c:	89 04 24             	mov    %eax,(%esp)
8010921f:	e8 46 aa ff ff       	call   80103c6a <kfree>
      *pte = 0;
80109224:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109227:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
8010922d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109234:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109237:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010923a:	0f 82 74 ff ff ff    	jb     801091b4 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80109240:	8b 45 10             	mov    0x10(%ebp),%eax
}
80109243:	c9                   	leave  
80109244:	c3                   	ret    

80109245 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80109245:	55                   	push   %ebp
80109246:	89 e5                	mov    %esp,%ebp
80109248:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
8010924b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010924f:	75 0c                	jne    8010925d <freevm+0x18>
    panic("freevm: no pgdir");
80109251:	c7 04 24 2f 9c 10 80 	movl   $0x80109c2f,(%esp)
80109258:	e8 e0 72 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010925d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109264:	00 
80109265:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010926c:	80 
8010926d:	8b 45 08             	mov    0x8(%ebp),%eax
80109270:	89 04 24             	mov    %eax,(%esp)
80109273:	e8 11 ff ff ff       	call   80109189 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80109278:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010927f:	eb 3c                	jmp    801092bd <freevm+0x78>
    if(pgdir[i] & PTE_P){
80109281:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109284:	c1 e0 02             	shl    $0x2,%eax
80109287:	03 45 08             	add    0x8(%ebp),%eax
8010928a:	8b 00                	mov    (%eax),%eax
8010928c:	83 e0 01             	and    $0x1,%eax
8010928f:	84 c0                	test   %al,%al
80109291:	74 26                	je     801092b9 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80109293:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109296:	c1 e0 02             	shl    $0x2,%eax
80109299:	03 45 08             	add    0x8(%ebp),%eax
8010929c:	8b 00                	mov    (%eax),%eax
8010929e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801092a3:	89 04 24             	mov    %eax,(%esp)
801092a6:	e8 85 f4 ff ff       	call   80108730 <p2v>
801092ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
801092ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801092b1:	89 04 24             	mov    %eax,(%esp)
801092b4:	e8 b1 a9 ff ff       	call   80103c6a <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
801092b9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801092bd:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
801092c4:	76 bb                	jbe    80109281 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801092c6:	8b 45 08             	mov    0x8(%ebp),%eax
801092c9:	89 04 24             	mov    %eax,(%esp)
801092cc:	e8 99 a9 ff ff       	call   80103c6a <kfree>
}
801092d1:	c9                   	leave  
801092d2:	c3                   	ret    

801092d3 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801092d3:	55                   	push   %ebp
801092d4:	89 e5                	mov    %esp,%ebp
801092d6:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801092d9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801092e0:	00 
801092e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801092e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801092e8:	8b 45 08             	mov    0x8(%ebp),%eax
801092eb:	89 04 24             	mov    %eax,(%esp)
801092ee:	e8 c0 f8 ff ff       	call   80108bb3 <walkpgdir>
801092f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801092f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801092fa:	75 0c                	jne    80109308 <clearpteu+0x35>
    panic("clearpteu");
801092fc:	c7 04 24 40 9c 10 80 	movl   $0x80109c40,(%esp)
80109303:	e8 35 72 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80109308:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010930b:	8b 00                	mov    (%eax),%eax
8010930d:	89 c2                	mov    %eax,%edx
8010930f:	83 e2 fb             	and    $0xfffffffb,%edx
80109312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109315:	89 10                	mov    %edx,(%eax)
}
80109317:	c9                   	leave  
80109318:	c3                   	ret    

80109319 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80109319:	55                   	push   %ebp
8010931a:	89 e5                	mov    %esp,%ebp
8010931c:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
8010931f:	e8 b9 f9 ff ff       	call   80108cdd <setupkvm>
80109324:	89 45 f0             	mov    %eax,-0x10(%ebp)
80109327:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010932b:	75 0a                	jne    80109337 <copyuvm+0x1e>
    return 0;
8010932d:	b8 00 00 00 00       	mov    $0x0,%eax
80109332:	e9 f1 00 00 00       	jmp    80109428 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
80109337:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010933e:	e9 c0 00 00 00       	jmp    80109403 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80109343:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109346:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010934d:	00 
8010934e:	89 44 24 04          	mov    %eax,0x4(%esp)
80109352:	8b 45 08             	mov    0x8(%ebp),%eax
80109355:	89 04 24             	mov    %eax,(%esp)
80109358:	e8 56 f8 ff ff       	call   80108bb3 <walkpgdir>
8010935d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109360:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109364:	75 0c                	jne    80109372 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
80109366:	c7 04 24 4a 9c 10 80 	movl   $0x80109c4a,(%esp)
8010936d:	e8 cb 71 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80109372:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109375:	8b 00                	mov    (%eax),%eax
80109377:	83 e0 01             	and    $0x1,%eax
8010937a:	85 c0                	test   %eax,%eax
8010937c:	75 0c                	jne    8010938a <copyuvm+0x71>
      panic("copyuvm: page not present");
8010937e:	c7 04 24 64 9c 10 80 	movl   $0x80109c64,(%esp)
80109385:	e8 b3 71 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
8010938a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010938d:	8b 00                	mov    (%eax),%eax
8010938f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109394:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
80109397:	e8 67 a9 ff ff       	call   80103d03 <kalloc>
8010939c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010939f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801093a3:	74 6f                	je     80109414 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801093a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801093a8:	89 04 24             	mov    %eax,(%esp)
801093ab:	e8 80 f3 ff ff       	call   80108730 <p2v>
801093b0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801093b7:	00 
801093b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801093bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801093bf:	89 04 24             	mov    %eax,(%esp)
801093c2:	e8 02 cd ff ff       	call   801060c9 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801093c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801093ca:	89 04 24             	mov    %eax,(%esp)
801093cd:	e8 51 f3 ff ff       	call   80108723 <v2p>
801093d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801093d5:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801093dc:	00 
801093dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
801093e1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801093e8:	00 
801093e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801093ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801093f0:	89 04 24             	mov    %eax,(%esp)
801093f3:	e8 51 f8 ff ff       	call   80108c49 <mappages>
801093f8:	85 c0                	test   %eax,%eax
801093fa:	78 1b                	js     80109417 <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801093fc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80109403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109406:	3b 45 0c             	cmp    0xc(%ebp),%eax
80109409:	0f 82 34 ff ff ff    	jb     80109343 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
8010940f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109412:	eb 14                	jmp    80109428 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80109414:	90                   	nop
80109415:	eb 01                	jmp    80109418 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
80109417:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80109418:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010941b:	89 04 24             	mov    %eax,(%esp)
8010941e:	e8 22 fe ff ff       	call   80109245 <freevm>
  return 0;
80109423:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109428:	c9                   	leave  
80109429:	c3                   	ret    

8010942a <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010942a:	55                   	push   %ebp
8010942b:	89 e5                	mov    %esp,%ebp
8010942d:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109430:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109437:	00 
80109438:	8b 45 0c             	mov    0xc(%ebp),%eax
8010943b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010943f:	8b 45 08             	mov    0x8(%ebp),%eax
80109442:	89 04 24             	mov    %eax,(%esp)
80109445:	e8 69 f7 ff ff       	call   80108bb3 <walkpgdir>
8010944a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
8010944d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109450:	8b 00                	mov    (%eax),%eax
80109452:	83 e0 01             	and    $0x1,%eax
80109455:	85 c0                	test   %eax,%eax
80109457:	75 07                	jne    80109460 <uva2ka+0x36>
    return 0;
80109459:	b8 00 00 00 00       	mov    $0x0,%eax
8010945e:	eb 25                	jmp    80109485 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109460:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109463:	8b 00                	mov    (%eax),%eax
80109465:	83 e0 04             	and    $0x4,%eax
80109468:	85 c0                	test   %eax,%eax
8010946a:	75 07                	jne    80109473 <uva2ka+0x49>
    return 0;
8010946c:	b8 00 00 00 00       	mov    $0x0,%eax
80109471:	eb 12                	jmp    80109485 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109473:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109476:	8b 00                	mov    (%eax),%eax
80109478:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010947d:	89 04 24             	mov    %eax,(%esp)
80109480:	e8 ab f2 ff ff       	call   80108730 <p2v>
}
80109485:	c9                   	leave  
80109486:	c3                   	ret    

80109487 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80109487:	55                   	push   %ebp
80109488:	89 e5                	mov    %esp,%ebp
8010948a:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
8010948d:	8b 45 10             	mov    0x10(%ebp),%eax
80109490:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109493:	e9 8b 00 00 00       	jmp    80109523 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80109498:	8b 45 0c             	mov    0xc(%ebp),%eax
8010949b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801094a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801094a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801094aa:	8b 45 08             	mov    0x8(%ebp),%eax
801094ad:	89 04 24             	mov    %eax,(%esp)
801094b0:	e8 75 ff ff ff       	call   8010942a <uva2ka>
801094b5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801094b8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801094bc:	75 07                	jne    801094c5 <copyout+0x3e>
      return -1;
801094be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801094c3:	eb 6d                	jmp    80109532 <copyout+0xab>
    n = PGSIZE - (va - va0);
801094c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801094c8:	8b 55 ec             	mov    -0x14(%ebp),%edx
801094cb:	89 d1                	mov    %edx,%ecx
801094cd:	29 c1                	sub    %eax,%ecx
801094cf:	89 c8                	mov    %ecx,%eax
801094d1:	05 00 10 00 00       	add    $0x1000,%eax
801094d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801094d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801094dc:	3b 45 14             	cmp    0x14(%ebp),%eax
801094df:	76 06                	jbe    801094e7 <copyout+0x60>
      n = len;
801094e1:	8b 45 14             	mov    0x14(%ebp),%eax
801094e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801094e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801094ea:	8b 55 0c             	mov    0xc(%ebp),%edx
801094ed:	89 d1                	mov    %edx,%ecx
801094ef:	29 c1                	sub    %eax,%ecx
801094f1:	89 c8                	mov    %ecx,%eax
801094f3:	03 45 e8             	add    -0x18(%ebp),%eax
801094f6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801094f9:	89 54 24 08          	mov    %edx,0x8(%esp)
801094fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80109500:	89 54 24 04          	mov    %edx,0x4(%esp)
80109504:	89 04 24             	mov    %eax,(%esp)
80109507:	e8 bd cb ff ff       	call   801060c9 <memmove>
    len -= n;
8010950c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010950f:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80109512:	8b 45 f0             	mov    -0x10(%ebp),%eax
80109515:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80109518:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010951b:	05 00 10 00 00       	add    $0x1000,%eax
80109520:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109523:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109527:	0f 85 6b ff ff ff    	jne    80109498 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010952d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109532:	c9                   	leave  
80109533:	c3                   	ret    


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
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
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
80100028:	bc 70 c6 10 80       	mov    $0x8010c670,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 73 36 10 80       	mov    $0x80103673,%eax
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
8010003a:	c7 44 24 04 8c 85 10 	movl   $0x8010858c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80100049:	e8 a0 4d 00 00       	call   80104dee <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 b0 db 10 80 a4 	movl   $0x8010dba4,0x8010dbb0
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 b4 db 10 80 a4 	movl   $0x8010dba4,0x8010dbb4
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 c6 10 80 	movl   $0x8010c6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 b4 db 10 80    	mov    0x8010dbb4,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c a4 db 10 80 	movl   $0x8010dba4,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 b4 db 10 80       	mov    0x8010dbb4,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 b4 db 10 80       	mov    %eax,0x8010dbb4

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 a4 db 10 80 	cmpl   $0x8010dba4,-0xc(%ebp)
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
801000b6:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
801000bd:	e8 4d 4d 00 00       	call   80104e0f <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 b4 db 10 80       	mov    0x8010dbb4,%eax
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
801000fd:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
80100104:	e8 68 4d 00 00       	call   80104e71 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 c6 10 	movl   $0x8010c680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 0d 4a 00 00       	call   80104b31 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 a4 db 10 80 	cmpl   $0x8010dba4,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 b0 db 10 80       	mov    0x8010dbb0,%eax
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
80100175:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
8010017c:	e8 f0 4c 00 00       	call   80104e71 <release>
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
8010018f:	81 7d f4 a4 db 10 80 	cmpl   $0x8010dba4,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 93 85 10 80 	movl   $0x80108593,(%esp)
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
801001d3:	e8 48 28 00 00       	call   80102a20 <iderw>
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
801001ef:	c7 04 24 a4 85 10 80 	movl   $0x801085a4,(%esp)
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
80100210:	e8 0b 28 00 00       	call   80102a20 <iderw>
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
80100229:	c7 04 24 ab 85 10 80 	movl   $0x801085ab,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
8010023c:	e8 ce 4b 00 00       	call   80104e0f <acquire>

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
8010025f:	8b 15 b4 db 10 80    	mov    0x8010dbb4,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c a4 db 10 80 	movl   $0x8010dba4,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 b4 db 10 80       	mov    0x8010dbb4,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 b4 db 10 80       	mov    %eax,0x8010dbb4

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
8010029d:	e8 68 49 00 00       	call   80104c0a <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 c6 10 80 	movl   $0x8010c680,(%esp)
801002a9:	e8 c3 4b 00 00       	call   80104e71 <release>
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
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
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
801003a7:	a1 14 b6 10 80       	mov    0x8010b614,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
801003bc:	e8 4e 4a 00 00       	call   80104e0f <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 b2 85 10 80 	movl   $0x801085b2,(%esp)
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
801004af:	c7 45 ec bb 85 10 80 	movl   $0x801085bb,-0x14(%ebp)
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
8010052f:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100536:	e8 36 49 00 00       	call   80104e71 <release>
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
80100548:	c7 05 14 b6 10 80 00 	movl   $0x0,0x8010b614
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 c2 85 10 80 	movl   $0x801085c2,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 d1 85 10 80 	movl   $0x801085d1,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 29 49 00 00       	call   80104ec0 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 d3 85 10 80 	movl   $0x801085d3,(%esp)
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
801005c1:	c7 05 c0 b5 10 80 01 	movl   $0x1,0x8010b5c0
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
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
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
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 7a 4a 00 00       	call   80105131 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 78 49 00 00       	call   8010505e <memset>
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
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
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
80100756:	a1 c0 b5 10 80       	mov    0x8010b5c0,%eax
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
80100776:	e8 76 64 00 00       	call   80106bf1 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 6a 64 00 00       	call   80106bf1 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 5e 64 00 00       	call   80106bf1 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 51 64 00 00       	call   80106bf1 <uartputc>
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
801007b3:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
801007ba:	e8 50 46 00 00       	call   80104e0f <acquire>
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
801007ea:	e8 be 44 00 00       	call   80104cad <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 7c de 10 80       	mov    0x8010de7c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 7c de 10 80       	mov    %eax,0x8010de7c
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
80100810:	8b 15 7c de 10 80    	mov    0x8010de7c,%edx
80100816:	a1 78 de 10 80       	mov    0x8010de78,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 7c de 10 80       	mov    0x8010de7c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 f4 dd 10 80 	movzbl -0x7fef220c(%eax),%eax
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
8010083e:	8b 15 7c de 10 80    	mov    0x8010de7c,%edx
80100844:	a1 78 de 10 80       	mov    0x8010de78,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 7c de 10 80       	mov    0x8010de7c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 7c de 10 80       	mov    %eax,0x8010de7c
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
80100879:	8b 15 7c de 10 80    	mov    0x8010de7c,%edx
8010087f:	a1 74 de 10 80       	mov    0x8010de74,%eax
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
801008a2:	a1 7c de 10 80       	mov    0x8010de7c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 f4 dd 10 80    	mov    %dl,-0x7fef220c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 7c de 10 80       	mov    %eax,0x8010de7c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 7c de 10 80       	mov    0x8010de7c,%eax
801008d9:	8b 15 74 de 10 80    	mov    0x8010de74,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 7c de 10 80       	mov    0x8010de7c,%eax
801008eb:	a3 78 de 10 80       	mov    %eax,0x8010de78
          wakeup(&input.r);
801008f0:	c7 04 24 74 de 10 80 	movl   $0x8010de74,(%esp)
801008f7:	e8 0e 43 00 00       	call   80104c0a <wakeup>
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
80100917:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
8010091e:	e8 4e 45 00 00       	call   80104e71 <release>
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
80100931:	e8 ec 12 00 00       	call   80101c22 <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
80100943:	e8 c7 44 00 00       	call   80104e0f <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
80100961:	e8 0b 45 00 00       	call   80104e71 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 63 11 00 00       	call   80101ad4 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 c0 dd 10 	movl   $0x8010ddc0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 74 de 10 80 	movl   $0x8010de74,(%esp)
8010098a:	e8 a2 41 00 00       	call   80104b31 <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 74 de 10 80    	mov    0x8010de74,%edx
80100998:	a1 78 de 10 80       	mov    0x8010de78,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 74 de 10 80       	mov    0x8010de74,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 f4 dd 10 80 	movzbl -0x7fef220c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 74 de 10 80       	mov    %eax,0x8010de74
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
801009ce:	a1 74 de 10 80       	mov    0x8010de74,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 74 de 10 80       	mov    %eax,0x8010de74
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
80100a01:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
80100a08:	e8 64 44 00 00       	call   80104e71 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 bc 10 00 00       	call   80101ad4 <ilock>

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
80100a32:	e8 eb 11 00 00       	call   80101c22 <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100a3e:	e8 cc 43 00 00       	call   80104e0f <acquire>
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
80100a71:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100a78:	e8 f4 43 00 00       	call   80104e71 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 4c 10 00 00       	call   80101ad4 <ilock>

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
80100a93:	c7 44 24 04 d7 85 10 	movl   $0x801085d7,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100aa2:	e8 47 43 00 00       	call   80104dee <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 df 85 10 	movl   $0x801085df,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 c0 dd 10 80 	movl   $0x8010ddc0,(%esp)
80100ab6:	e8 33 43 00 00       	call   80104dee <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 2c e8 10 80 26 	movl   $0x80100a26,0x8010e82c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 28 e8 10 80 25 	movl   $0x80100925,0x8010e828
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 14 b6 10 80 01 	movl   $0x1,0x8010b614
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 48 32 00 00       	call   80103d2d <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 e9 20 00 00       	call   80102be2 <ioapicenable>
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
80100b0b:	e8 66 1b 00 00       	call   80102676 <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 0a                	jne    80100b23 <exec+0x27>
    return -1;
80100b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1e:	e9 da 03 00 00       	jmp    80100efd <exec+0x401>
  ilock(ip);
80100b23:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b26:	89 04 24             	mov    %eax,(%esp)
80100b29:	e8 a6 0f 00 00       	call   80101ad4 <ilock>
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
80100b55:	e8 70 14 00 00       	call   80101fca <readi>
80100b5a:	83 f8 33             	cmp    $0x33,%eax
80100b5d:	0f 86 54 03 00 00    	jbe    80100eb7 <exec+0x3bb>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100b63:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b69:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6e:	0f 85 46 03 00 00    	jne    80100eba <exec+0x3be>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100b74:	c7 04 24 6b 2d 10 80 	movl   $0x80102d6b,(%esp)
80100b7b:	e8 b5 71 00 00       	call   80107d35 <setupkvm>
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
80100bc8:	e8 fd 13 00 00       	call   80101fca <readi>
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
80100c14:	e8 ee 74 00 00       	call   80108107 <allocuvm>
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
80100c51:	e8 c2 73 00 00       	call   80108018 <loaduvm>
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
80100c87:	e8 cc 10 00 00       	call   80101d58 <iunlockput>
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
80100cbc:	e8 46 74 00 00       	call   80108107 <allocuvm>
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
80100ce0:	e8 46 76 00 00       	call   8010832b <clearpteu>
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
80100d0f:	e8 c8 45 00 00       	call   801052dc <strlen>
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
80100d2d:	e8 aa 45 00 00       	call   801052dc <strlen>
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
80100d57:	e8 83 77 00 00       	call   801084df <copyout>
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
80100df7:	e8 e3 76 00 00       	call   801084df <copyout>
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
80100e4e:	e8 3b 44 00 00       	call   8010528e <safestrcpy>

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
80100ea0:	e8 81 6f 00 00       	call   80107e26 <switchuvm>
  freevm(oldpgdir);
80100ea5:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ea8:	89 04 24             	mov    %eax,(%esp)
80100eab:	e8 ed 73 00 00       	call   8010829d <freevm>
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
80100ee2:	e8 b6 73 00 00       	call   8010829d <freevm>
  if(ip)
80100ee7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100eeb:	74 0b                	je     80100ef8 <exec+0x3fc>
    iunlockput(ip);
80100eed:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef0:	89 04 24             	mov    %eax,(%esp)
80100ef3:	e8 60 0e 00 00       	call   80101d58 <iunlockput>
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
80100f06:	c7 44 24 04 e8 85 10 	movl   $0x801085e8,0x4(%esp)
80100f0d:	80 
80100f0e:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100f15:	e8 d4 3e 00 00       	call   80104dee <initlock>
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
80100f22:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100f29:	e8 e1 3e 00 00       	call   80104e0f <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f2e:	c7 45 f4 b4 de 10 80 	movl   $0x8010deb4,-0xc(%ebp)
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
80100f4b:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100f52:	e8 1a 3f 00 00       	call   80104e71 <release>
      return f;
80100f57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f5a:	eb 1e                	jmp    80100f7a <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f5c:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f60:	81 7d f4 14 e8 10 80 	cmpl   $0x8010e814,-0xc(%ebp)
80100f67:	72 ce                	jb     80100f37 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f69:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100f70:	e8 fc 3e 00 00       	call   80104e71 <release>
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
80100f82:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100f89:	e8 81 3e 00 00       	call   80104e0f <acquire>
  if(f->ref < 1)
80100f8e:	8b 45 08             	mov    0x8(%ebp),%eax
80100f91:	8b 40 04             	mov    0x4(%eax),%eax
80100f94:	85 c0                	test   %eax,%eax
80100f96:	7f 0c                	jg     80100fa4 <filedup+0x28>
    panic("filedup");
80100f98:	c7 04 24 ef 85 10 80 	movl   $0x801085ef,(%esp)
80100f9f:	e8 99 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80100fa7:	8b 40 04             	mov    0x4(%eax),%eax
80100faa:	8d 50 01             	lea    0x1(%eax),%edx
80100fad:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb0:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fb3:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100fba:	e8 b2 3e 00 00       	call   80104e71 <release>
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
80100fca:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80100fd1:	e8 39 3e 00 00       	call   80104e0f <acquire>
  if(f->ref < 1)
80100fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80100fd9:	8b 40 04             	mov    0x4(%eax),%eax
80100fdc:	85 c0                	test   %eax,%eax
80100fde:	7f 0c                	jg     80100fec <fileclose+0x28>
    panic("fileclose");
80100fe0:	c7 04 24 f7 85 10 80 	movl   $0x801085f7,(%esp)
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
80101005:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
8010100c:	e8 60 3e 00 00       	call   80104e71 <release>
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
8010104f:	c7 04 24 80 de 10 80 	movl   $0x8010de80,(%esp)
80101056:	e8 16 3e 00 00       	call   80104e71 <release>
  
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
80101074:	e8 6e 2f 00 00       	call   80103fe7 <pipeclose>
80101079:	eb 1d                	jmp    80101098 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010107b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010107e:	83 f8 02             	cmp    $0x2,%eax
80101081:	75 15                	jne    80101098 <fileclose+0xd4>
    begin_trans();
80101083:	e8 01 24 00 00       	call   80103489 <begin_trans>
    iput(ff.ip);
80101088:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010108b:	89 04 24             	mov    %eax,(%esp)
8010108e:	e8 f4 0b 00 00       	call   80101c87 <iput>
    commit_trans();
80101093:	e8 3a 24 00 00       	call   801034d2 <commit_trans>
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
801010b3:	e8 1c 0a 00 00       	call   80101ad4 <ilock>
    stati(f->ip, st);
801010b8:	8b 45 08             	mov    0x8(%ebp),%eax
801010bb:	8b 40 10             	mov    0x10(%eax),%eax
801010be:	8b 55 0c             	mov    0xc(%ebp),%edx
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 b8 0e 00 00       	call   80101f85 <stati>
    iunlock(f->ip);
801010cd:	8b 45 08             	mov    0x8(%ebp),%eax
801010d0:	8b 40 10             	mov    0x10(%eax),%eax
801010d3:	89 04 24             	mov    %eax,(%esp)
801010d6:	e8 47 0b 00 00       	call   80101c22 <iunlock>
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
80101125:	e8 3f 30 00 00       	call   80104169 <piperead>
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
8010113f:	e8 90 09 00 00       	call   80101ad4 <ilock>
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
80101165:	e8 60 0e 00 00       	call   80101fca <readi>
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
8010118d:	e8 90 0a 00 00       	call   80101c22 <iunlock>
    return r;
80101192:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101195:	eb 0c                	jmp    801011a3 <fileread+0xba>
  }
  panic("fileread");
80101197:	c7 04 24 01 86 10 80 	movl   $0x80108601,(%esp)
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
801011e2:	e8 92 2e 00 00       	call   80104079 <pipewrite>
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
8010122a:	e8 5a 22 00 00       	call   80103489 <begin_trans>
      ilock(f->ip);
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 40 10             	mov    0x10(%eax),%eax
80101235:	89 04 24             	mov    %eax,(%esp)
80101238:	e8 97 08 00 00       	call   80101ad4 <ilock>
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
80101263:	e8 cd 0e 00 00       	call   80102135 <writei>
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
8010128b:	e8 92 09 00 00       	call   80101c22 <iunlock>
      commit_trans();
80101290:	e8 3d 22 00 00       	call   801034d2 <commit_trans>

      if(r < 0)
80101295:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101299:	78 28                	js     801012c3 <filewrite+0x11e>
        break;
      if(r != n1)
8010129b:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010129e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012a1:	74 0c                	je     801012af <filewrite+0x10a>
        panic("short filewrite");
801012a3:	c7 04 24 0a 86 10 80 	movl   $0x8010860a,(%esp)
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
801012d8:	c7 04 24 1a 86 10 80 	movl   $0x8010861a,(%esp)
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
801012fe:	e8 8a 4a 00 00       	call   80105d8d <fileopen>
80101303:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101306:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010130a:	75 1d                	jne    80101329 <getFileBlocks+0x3f>
  {
    cprintf("Could not open file %s\n",path);
8010130c:	8b 45 08             	mov    0x8(%ebp),%eax
8010130f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101313:	c7 04 24 24 86 10 80 	movl   $0x80108624,(%esp)
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
80101338:	e8 97 07 00 00       	call   80101ad4 <ilock>
  
  cprintf("Printing all blocks for file %s:\n\n",path);
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	89 44 24 04          	mov    %eax,0x4(%esp)
80101344:	c7 04 24 3c 86 10 80 	movl   $0x8010863c,(%esp)
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
80101382:	c7 04 24 5f 86 10 80 	movl   $0x8010865f,(%esp)
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
801013b7:	c7 04 24 78 86 10 80 	movl   $0x80108678,(%esp)
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
80101414:	c7 04 24 97 86 10 80 	movl   $0x80108697,(%esp)
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
8010143b:	e8 e2 07 00 00       	call   80101c22 <iunlock>
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
8010146a:	e8 e9 00 00 00       	call   80101558 <readsb>
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
8010153e:	c7 04 24 b0 86 10 80 	movl   $0x801086b0,(%esp)
80101545:	e8 57 ee ff ff       	call   801003a1 <cprintf>
  return 0;
8010154a:	b8 00 00 00 00       	mov    $0x0,%eax
8010154f:	83 c4 44             	add    $0x44,%esp
80101552:	5b                   	pop    %ebx
80101553:	5d                   	pop    %ebp
80101554:	c3                   	ret    
80101555:	00 00                	add    %al,(%eax)
	...

80101558 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101558:	55                   	push   %ebp
80101559:	89 e5                	mov    %esp,%ebp
8010155b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010155e:	8b 45 08             	mov    0x8(%ebp),%eax
80101561:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101568:	00 
80101569:	89 04 24             	mov    %eax,(%esp)
8010156c:	e8 35 ec ff ff       	call   801001a6 <bread>
80101571:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101574:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101577:	83 c0 18             	add    $0x18,%eax
8010157a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101581:	00 
80101582:	89 44 24 04          	mov    %eax,0x4(%esp)
80101586:	8b 45 0c             	mov    0xc(%ebp),%eax
80101589:	89 04 24             	mov    %eax,(%esp)
8010158c:	e8 a0 3b 00 00       	call   80105131 <memmove>
  brelse(bp);
80101591:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101594:	89 04 24             	mov    %eax,(%esp)
80101597:	e8 7b ec ff ff       	call   80100217 <brelse>
}
8010159c:	c9                   	leave  
8010159d:	c3                   	ret    

8010159e <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
8010159e:	55                   	push   %ebp
8010159f:	89 e5                	mov    %esp,%ebp
801015a1:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801015a4:	8b 55 0c             	mov    0xc(%ebp),%edx
801015a7:	8b 45 08             	mov    0x8(%ebp),%eax
801015aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801015ae:	89 04 24             	mov    %eax,(%esp)
801015b1:	e8 f0 eb ff ff       	call   801001a6 <bread>
801015b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801015b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015bc:	83 c0 18             	add    $0x18,%eax
801015bf:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801015c6:	00 
801015c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801015ce:	00 
801015cf:	89 04 24             	mov    %eax,(%esp)
801015d2:	e8 87 3a 00 00       	call   8010505e <memset>
  log_write(bp);
801015d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015da:	89 04 24             	mov    %eax,(%esp)
801015dd:	e8 48 1f 00 00       	call   8010352a <log_write>
  brelse(bp);
801015e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015e5:	89 04 24             	mov    %eax,(%esp)
801015e8:	e8 2a ec ff ff       	call   80100217 <brelse>
}
801015ed:	c9                   	leave  
801015ee:	c3                   	ret    

801015ef <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801015ef:	55                   	push   %ebp
801015f0:	89 e5                	mov    %esp,%ebp
801015f2:	53                   	push   %ebx
801015f3:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801015f6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801015fd:	8b 45 08             	mov    0x8(%ebp),%eax
80101600:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101603:	89 54 24 04          	mov    %edx,0x4(%esp)
80101607:	89 04 24             	mov    %eax,(%esp)
8010160a:	e8 49 ff ff ff       	call   80101558 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010160f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101616:	e9 11 01 00 00       	jmp    8010172c <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
8010161b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010161e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101624:	85 c0                	test   %eax,%eax
80101626:	0f 48 c2             	cmovs  %edx,%eax
80101629:	c1 f8 0c             	sar    $0xc,%eax
8010162c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010162f:	c1 ea 03             	shr    $0x3,%edx
80101632:	01 d0                	add    %edx,%eax
80101634:	83 c0 03             	add    $0x3,%eax
80101637:	89 44 24 04          	mov    %eax,0x4(%esp)
8010163b:	8b 45 08             	mov    0x8(%ebp),%eax
8010163e:	89 04 24             	mov    %eax,(%esp)
80101641:	e8 60 eb ff ff       	call   801001a6 <bread>
80101646:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101649:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101650:	e9 a7 00 00 00       	jmp    801016fc <balloc+0x10d>
      m = 1 << (bi % 8);
80101655:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101658:	89 c2                	mov    %eax,%edx
8010165a:	c1 fa 1f             	sar    $0x1f,%edx
8010165d:	c1 ea 1d             	shr    $0x1d,%edx
80101660:	01 d0                	add    %edx,%eax
80101662:	83 e0 07             	and    $0x7,%eax
80101665:	29 d0                	sub    %edx,%eax
80101667:	ba 01 00 00 00       	mov    $0x1,%edx
8010166c:	89 d3                	mov    %edx,%ebx
8010166e:	89 c1                	mov    %eax,%ecx
80101670:	d3 e3                	shl    %cl,%ebx
80101672:	89 d8                	mov    %ebx,%eax
80101674:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010167a:	8d 50 07             	lea    0x7(%eax),%edx
8010167d:	85 c0                	test   %eax,%eax
8010167f:	0f 48 c2             	cmovs  %edx,%eax
80101682:	c1 f8 03             	sar    $0x3,%eax
80101685:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101688:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010168d:	0f b6 c0             	movzbl %al,%eax
80101690:	23 45 e8             	and    -0x18(%ebp),%eax
80101693:	85 c0                	test   %eax,%eax
80101695:	75 61                	jne    801016f8 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101697:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010169a:	8d 50 07             	lea    0x7(%eax),%edx
8010169d:	85 c0                	test   %eax,%eax
8010169f:	0f 48 c2             	cmovs  %edx,%eax
801016a2:	c1 f8 03             	sar    $0x3,%eax
801016a5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801016a8:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801016ad:	89 d1                	mov    %edx,%ecx
801016af:	8b 55 e8             	mov    -0x18(%ebp),%edx
801016b2:	09 ca                	or     %ecx,%edx
801016b4:	89 d1                	mov    %edx,%ecx
801016b6:	8b 55 ec             	mov    -0x14(%ebp),%edx
801016b9:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
801016bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016c0:	89 04 24             	mov    %eax,(%esp)
801016c3:	e8 62 1e 00 00       	call   8010352a <log_write>
        brelse(bp);
801016c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016cb:	89 04 24             	mov    %eax,(%esp)
801016ce:	e8 44 eb ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801016d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016d9:	01 c2                	add    %eax,%edx
801016db:	8b 45 08             	mov    0x8(%ebp),%eax
801016de:	89 54 24 04          	mov    %edx,0x4(%esp)
801016e2:	89 04 24             	mov    %eax,(%esp)
801016e5:	e8 b4 fe ff ff       	call   8010159e <bzero>
        return b + bi;
801016ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016f0:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801016f2:	83 c4 34             	add    $0x34,%esp
801016f5:	5b                   	pop    %ebx
801016f6:	5d                   	pop    %ebp
801016f7:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801016f8:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801016fc:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101703:	7f 15                	jg     8010171a <balloc+0x12b>
80101705:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101708:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010170b:	01 d0                	add    %edx,%eax
8010170d:	89 c2                	mov    %eax,%edx
8010170f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101712:	39 c2                	cmp    %eax,%edx
80101714:	0f 82 3b ff ff ff    	jb     80101655 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
8010171a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010171d:	89 04 24             	mov    %eax,(%esp)
80101720:	e8 f2 ea ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101725:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010172c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010172f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101732:	39 c2                	cmp    %eax,%edx
80101734:	0f 82 e1 fe ff ff    	jb     8010161b <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
8010173a:	c7 04 24 c9 86 10 80 	movl   $0x801086c9,(%esp)
80101741:	e8 f7 ed ff ff       	call   8010053d <panic>

80101746 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101746:	55                   	push   %ebp
80101747:	89 e5                	mov    %esp,%ebp
80101749:	53                   	push   %ebx
8010174a:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
8010174d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101750:	89 44 24 04          	mov    %eax,0x4(%esp)
80101754:	8b 45 08             	mov    0x8(%ebp),%eax
80101757:	89 04 24             	mov    %eax,(%esp)
8010175a:	e8 f9 fd ff ff       	call   80101558 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
8010175f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101762:	89 c2                	mov    %eax,%edx
80101764:	c1 ea 0c             	shr    $0xc,%edx
80101767:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010176a:	c1 e8 03             	shr    $0x3,%eax
8010176d:	01 d0                	add    %edx,%eax
8010176f:	8d 50 03             	lea    0x3(%eax),%edx
80101772:	8b 45 08             	mov    0x8(%ebp),%eax
80101775:	89 54 24 04          	mov    %edx,0x4(%esp)
80101779:	89 04 24             	mov    %eax,(%esp)
8010177c:	e8 25 ea ff ff       	call   801001a6 <bread>
80101781:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101784:	8b 45 0c             	mov    0xc(%ebp),%eax
80101787:	25 ff 0f 00 00       	and    $0xfff,%eax
8010178c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010178f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101792:	89 c2                	mov    %eax,%edx
80101794:	c1 fa 1f             	sar    $0x1f,%edx
80101797:	c1 ea 1d             	shr    $0x1d,%edx
8010179a:	01 d0                	add    %edx,%eax
8010179c:	83 e0 07             	and    $0x7,%eax
8010179f:	29 d0                	sub    %edx,%eax
801017a1:	ba 01 00 00 00       	mov    $0x1,%edx
801017a6:	89 d3                	mov    %edx,%ebx
801017a8:	89 c1                	mov    %eax,%ecx
801017aa:	d3 e3                	shl    %cl,%ebx
801017ac:	89 d8                	mov    %ebx,%eax
801017ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801017b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017b4:	8d 50 07             	lea    0x7(%eax),%edx
801017b7:	85 c0                	test   %eax,%eax
801017b9:	0f 48 c2             	cmovs  %edx,%eax
801017bc:	c1 f8 03             	sar    $0x3,%eax
801017bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017c2:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801017c7:	0f b6 c0             	movzbl %al,%eax
801017ca:	23 45 ec             	and    -0x14(%ebp),%eax
801017cd:	85 c0                	test   %eax,%eax
801017cf:	75 0c                	jne    801017dd <bfree+0x97>
    panic("freeing free block");
801017d1:	c7 04 24 df 86 10 80 	movl   $0x801086df,(%esp)
801017d8:	e8 60 ed ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801017dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017e0:	8d 50 07             	lea    0x7(%eax),%edx
801017e3:	85 c0                	test   %eax,%eax
801017e5:	0f 48 c2             	cmovs  %edx,%eax
801017e8:	c1 f8 03             	sar    $0x3,%eax
801017eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017ee:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801017f3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801017f6:	f7 d1                	not    %ecx
801017f8:	21 ca                	and    %ecx,%edx
801017fa:	89 d1                	mov    %edx,%ecx
801017fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801017ff:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101806:	89 04 24             	mov    %eax,(%esp)
80101809:	e8 1c 1d 00 00       	call   8010352a <log_write>
  brelse(bp);
8010180e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101811:	89 04 24             	mov    %eax,(%esp)
80101814:	e8 fe e9 ff ff       	call   80100217 <brelse>
}
80101819:	83 c4 34             	add    $0x34,%esp
8010181c:	5b                   	pop    %ebx
8010181d:	5d                   	pop    %ebp
8010181e:	c3                   	ret    

8010181f <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010181f:	55                   	push   %ebp
80101820:	89 e5                	mov    %esp,%ebp
80101822:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80101825:	c7 44 24 04 f2 86 10 	movl   $0x801086f2,0x4(%esp)
8010182c:	80 
8010182d:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101834:	e8 b5 35 00 00       	call   80104dee <initlock>
}
80101839:	c9                   	leave  
8010183a:	c3                   	ret    

8010183b <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
8010183b:	55                   	push   %ebp
8010183c:	89 e5                	mov    %esp,%ebp
8010183e:	83 ec 48             	sub    $0x48,%esp
80101841:	8b 45 0c             	mov    0xc(%ebp),%eax
80101844:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101848:	8b 45 08             	mov    0x8(%ebp),%eax
8010184b:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010184e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101852:	89 04 24             	mov    %eax,(%esp)
80101855:	e8 fe fc ff ff       	call   80101558 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
8010185a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101861:	e9 98 00 00 00       	jmp    801018fe <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101866:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101869:	c1 e8 03             	shr    $0x3,%eax
8010186c:	83 c0 02             	add    $0x2,%eax
8010186f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101873:	8b 45 08             	mov    0x8(%ebp),%eax
80101876:	89 04 24             	mov    %eax,(%esp)
80101879:	e8 28 e9 ff ff       	call   801001a6 <bread>
8010187e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101881:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101884:	8d 50 18             	lea    0x18(%eax),%edx
80101887:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010188a:	83 e0 07             	and    $0x7,%eax
8010188d:	c1 e0 06             	shl    $0x6,%eax
80101890:	01 d0                	add    %edx,%eax
80101892:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101895:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101898:	0f b7 00             	movzwl (%eax),%eax
8010189b:	66 85 c0             	test   %ax,%ax
8010189e:	75 4f                	jne    801018ef <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801018a0:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801018a7:	00 
801018a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801018af:	00 
801018b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801018b3:	89 04 24             	mov    %eax,(%esp)
801018b6:	e8 a3 37 00 00       	call   8010505e <memset>
      dip->type = type;
801018bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801018be:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801018c2:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801018c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018c8:	89 04 24             	mov    %eax,(%esp)
801018cb:	e8 5a 1c 00 00       	call   8010352a <log_write>
      brelse(bp);
801018d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018d3:	89 04 24             	mov    %eax,(%esp)
801018d6:	e8 3c e9 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801018db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018de:	89 44 24 04          	mov    %eax,0x4(%esp)
801018e2:	8b 45 08             	mov    0x8(%ebp),%eax
801018e5:	89 04 24             	mov    %eax,(%esp)
801018e8:	e8 e3 00 00 00       	call   801019d0 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801018ed:	c9                   	leave  
801018ee:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801018ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018f2:	89 04 24             	mov    %eax,(%esp)
801018f5:	e8 1d e9 ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801018fa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801018fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101901:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101904:	39 c2                	cmp    %eax,%edx
80101906:	0f 82 5a ff ff ff    	jb     80101866 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
8010190c:	c7 04 24 f9 86 10 80 	movl   $0x801086f9,(%esp)
80101913:	e8 25 ec ff ff       	call   8010053d <panic>

80101918 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101918:	55                   	push   %ebp
80101919:	89 e5                	mov    %esp,%ebp
8010191b:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	8b 40 04             	mov    0x4(%eax),%eax
80101924:	c1 e8 03             	shr    $0x3,%eax
80101927:	8d 50 02             	lea    0x2(%eax),%edx
8010192a:	8b 45 08             	mov    0x8(%ebp),%eax
8010192d:	8b 00                	mov    (%eax),%eax
8010192f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101933:	89 04 24             	mov    %eax,(%esp)
80101936:	e8 6b e8 ff ff       	call   801001a6 <bread>
8010193b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010193e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101941:	8d 50 18             	lea    0x18(%eax),%edx
80101944:	8b 45 08             	mov    0x8(%ebp),%eax
80101947:	8b 40 04             	mov    0x4(%eax),%eax
8010194a:	83 e0 07             	and    $0x7,%eax
8010194d:	c1 e0 06             	shl    $0x6,%eax
80101950:	01 d0                	add    %edx,%eax
80101952:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101955:	8b 45 08             	mov    0x8(%ebp),%eax
80101958:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010195c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010195f:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101962:	8b 45 08             	mov    0x8(%ebp),%eax
80101965:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101969:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010196c:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101970:	8b 45 08             	mov    0x8(%ebp),%eax
80101973:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101977:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010197a:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
8010197e:	8b 45 08             	mov    0x8(%ebp),%eax
80101981:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101985:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101988:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010198c:	8b 45 08             	mov    0x8(%ebp),%eax
8010198f:	8b 50 18             	mov    0x18(%eax),%edx
80101992:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101995:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101998:	8b 45 08             	mov    0x8(%ebp),%eax
8010199b:	8d 50 1c             	lea    0x1c(%eax),%edx
8010199e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019a1:	83 c0 0c             	add    $0xc,%eax
801019a4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801019ab:	00 
801019ac:	89 54 24 04          	mov    %edx,0x4(%esp)
801019b0:	89 04 24             	mov    %eax,(%esp)
801019b3:	e8 79 37 00 00       	call   80105131 <memmove>
  log_write(bp);
801019b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019bb:	89 04 24             	mov    %eax,(%esp)
801019be:	e8 67 1b 00 00       	call   8010352a <log_write>
  brelse(bp);
801019c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c6:	89 04 24             	mov    %eax,(%esp)
801019c9:	e8 49 e8 ff ff       	call   80100217 <brelse>
}
801019ce:	c9                   	leave  
801019cf:	c3                   	ret    

801019d0 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801019d0:	55                   	push   %ebp
801019d1:	89 e5                	mov    %esp,%ebp
801019d3:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801019d6:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
801019dd:	e8 2d 34 00 00       	call   80104e0f <acquire>

  // Is the inode already cached?
  empty = 0;
801019e2:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801019e9:	c7 45 f4 b4 e8 10 80 	movl   $0x8010e8b4,-0xc(%ebp)
801019f0:	eb 59                	jmp    80101a4b <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801019f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019f5:	8b 40 08             	mov    0x8(%eax),%eax
801019f8:	85 c0                	test   %eax,%eax
801019fa:	7e 35                	jle    80101a31 <iget+0x61>
801019fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ff:	8b 00                	mov    (%eax),%eax
80101a01:	3b 45 08             	cmp    0x8(%ebp),%eax
80101a04:	75 2b                	jne    80101a31 <iget+0x61>
80101a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a09:	8b 40 04             	mov    0x4(%eax),%eax
80101a0c:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101a0f:	75 20                	jne    80101a31 <iget+0x61>
      ip->ref++;
80101a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a14:	8b 40 08             	mov    0x8(%eax),%eax
80101a17:	8d 50 01             	lea    0x1(%eax),%edx
80101a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a1d:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101a20:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101a27:	e8 45 34 00 00       	call   80104e71 <release>
      return ip;
80101a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a2f:	eb 6f                	jmp    80101aa0 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101a31:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101a35:	75 10                	jne    80101a47 <iget+0x77>
80101a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a3a:	8b 40 08             	mov    0x8(%eax),%eax
80101a3d:	85 c0                	test   %eax,%eax
80101a3f:	75 06                	jne    80101a47 <iget+0x77>
      empty = ip;
80101a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a44:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101a47:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101a4b:	81 7d f4 54 f8 10 80 	cmpl   $0x8010f854,-0xc(%ebp)
80101a52:	72 9e                	jb     801019f2 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101a54:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101a58:	75 0c                	jne    80101a66 <iget+0x96>
    panic("iget: no inodes");
80101a5a:	c7 04 24 0b 87 10 80 	movl   $0x8010870b,(%esp)
80101a61:	e8 d7 ea ff ff       	call   8010053d <panic>

  ip = empty;
80101a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a69:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a6f:	8b 55 08             	mov    0x8(%ebp),%edx
80101a72:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a77:	8b 55 0c             	mov    0xc(%ebp),%edx
80101a7a:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a80:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a8a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101a91:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101a98:	e8 d4 33 00 00       	call   80104e71 <release>

  return ip;
80101a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101aa0:	c9                   	leave  
80101aa1:	c3                   	ret    

80101aa2 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101aa2:	55                   	push   %ebp
80101aa3:	89 e5                	mov    %esp,%ebp
80101aa5:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101aa8:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101aaf:	e8 5b 33 00 00       	call   80104e0f <acquire>
  ip->ref++;
80101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab7:	8b 40 08             	mov    0x8(%eax),%eax
80101aba:	8d 50 01             	lea    0x1(%eax),%edx
80101abd:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac0:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ac3:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101aca:	e8 a2 33 00 00       	call   80104e71 <release>
  return ip;
80101acf:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101ad2:	c9                   	leave  
80101ad3:	c3                   	ret    

80101ad4 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101ad4:	55                   	push   %ebp
80101ad5:	89 e5                	mov    %esp,%ebp
80101ad7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101ada:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101ade:	74 0a                	je     80101aea <ilock+0x16>
80101ae0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae3:	8b 40 08             	mov    0x8(%eax),%eax
80101ae6:	85 c0                	test   %eax,%eax
80101ae8:	7f 0c                	jg     80101af6 <ilock+0x22>
    panic("ilock");
80101aea:	c7 04 24 1b 87 10 80 	movl   $0x8010871b,(%esp)
80101af1:	e8 47 ea ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101af6:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101afd:	e8 0d 33 00 00       	call   80104e0f <acquire>
  while(ip->flags & I_BUSY)
80101b02:	eb 13                	jmp    80101b17 <ilock+0x43>
    sleep(ip, &icache.lock);
80101b04:	c7 44 24 04 80 e8 10 	movl   $0x8010e880,0x4(%esp)
80101b0b:	80 
80101b0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0f:	89 04 24             	mov    %eax,(%esp)
80101b12:	e8 1a 30 00 00       	call   80104b31 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101b17:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1a:	8b 40 0c             	mov    0xc(%eax),%eax
80101b1d:	83 e0 01             	and    $0x1,%eax
80101b20:	84 c0                	test   %al,%al
80101b22:	75 e0                	jne    80101b04 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101b24:	8b 45 08             	mov    0x8(%ebp),%eax
80101b27:	8b 40 0c             	mov    0xc(%eax),%eax
80101b2a:	89 c2                	mov    %eax,%edx
80101b2c:	83 ca 01             	or     $0x1,%edx
80101b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b32:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101b35:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101b3c:	e8 30 33 00 00       	call   80104e71 <release>

  if(!(ip->flags & I_VALID)){
80101b41:	8b 45 08             	mov    0x8(%ebp),%eax
80101b44:	8b 40 0c             	mov    0xc(%eax),%eax
80101b47:	83 e0 02             	and    $0x2,%eax
80101b4a:	85 c0                	test   %eax,%eax
80101b4c:	0f 85 ce 00 00 00    	jne    80101c20 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101b52:	8b 45 08             	mov    0x8(%ebp),%eax
80101b55:	8b 40 04             	mov    0x4(%eax),%eax
80101b58:	c1 e8 03             	shr    $0x3,%eax
80101b5b:	8d 50 02             	lea    0x2(%eax),%edx
80101b5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b61:	8b 00                	mov    (%eax),%eax
80101b63:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b67:	89 04 24             	mov    %eax,(%esp)
80101b6a:	e8 37 e6 ff ff       	call   801001a6 <bread>
80101b6f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101b72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b75:	8d 50 18             	lea    0x18(%eax),%edx
80101b78:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7b:	8b 40 04             	mov    0x4(%eax),%eax
80101b7e:	83 e0 07             	and    $0x7,%eax
80101b81:	c1 e0 06             	shl    $0x6,%eax
80101b84:	01 d0                	add    %edx,%eax
80101b86:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101b89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b8c:	0f b7 10             	movzwl (%eax),%edx
80101b8f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b92:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101b96:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b99:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101b9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba0:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101ba4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ba7:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101bab:	8b 45 08             	mov    0x8(%ebp),%eax
80101bae:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101bb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bb5:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101bb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101bbc:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bc3:	8b 50 08             	mov    0x8(%eax),%edx
80101bc6:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc9:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101bcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bcf:	8d 50 0c             	lea    0xc(%eax),%edx
80101bd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd5:	83 c0 1c             	add    $0x1c,%eax
80101bd8:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101bdf:	00 
80101be0:	89 54 24 04          	mov    %edx,0x4(%esp)
80101be4:	89 04 24             	mov    %eax,(%esp)
80101be7:	e8 45 35 00 00       	call   80105131 <memmove>
    brelse(bp);
80101bec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bef:	89 04 24             	mov    %eax,(%esp)
80101bf2:	e8 20 e6 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101bf7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfa:	8b 40 0c             	mov    0xc(%eax),%eax
80101bfd:	89 c2                	mov    %eax,%edx
80101bff:	83 ca 02             	or     $0x2,%edx
80101c02:	8b 45 08             	mov    0x8(%ebp),%eax
80101c05:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101c08:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101c0f:	66 85 c0             	test   %ax,%ax
80101c12:	75 0c                	jne    80101c20 <ilock+0x14c>
      panic("ilock: no type");
80101c14:	c7 04 24 21 87 10 80 	movl   $0x80108721,(%esp)
80101c1b:	e8 1d e9 ff ff       	call   8010053d <panic>
  }
}
80101c20:	c9                   	leave  
80101c21:	c3                   	ret    

80101c22 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101c22:	55                   	push   %ebp
80101c23:	89 e5                	mov    %esp,%ebp
80101c25:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101c28:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101c2c:	74 17                	je     80101c45 <iunlock+0x23>
80101c2e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c31:	8b 40 0c             	mov    0xc(%eax),%eax
80101c34:	83 e0 01             	and    $0x1,%eax
80101c37:	85 c0                	test   %eax,%eax
80101c39:	74 0a                	je     80101c45 <iunlock+0x23>
80101c3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3e:	8b 40 08             	mov    0x8(%eax),%eax
80101c41:	85 c0                	test   %eax,%eax
80101c43:	7f 0c                	jg     80101c51 <iunlock+0x2f>
    panic("iunlock");
80101c45:	c7 04 24 30 87 10 80 	movl   $0x80108730,(%esp)
80101c4c:	e8 ec e8 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101c51:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101c58:	e8 b2 31 00 00       	call   80104e0f <acquire>
  ip->flags &= ~I_BUSY;
80101c5d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c60:	8b 40 0c             	mov    0xc(%eax),%eax
80101c63:	89 c2                	mov    %eax,%edx
80101c65:	83 e2 fe             	and    $0xfffffffe,%edx
80101c68:	8b 45 08             	mov    0x8(%ebp),%eax
80101c6b:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101c6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c71:	89 04 24             	mov    %eax,(%esp)
80101c74:	e8 91 2f 00 00       	call   80104c0a <wakeup>
  release(&icache.lock);
80101c79:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101c80:	e8 ec 31 00 00       	call   80104e71 <release>
}
80101c85:	c9                   	leave  
80101c86:	c3                   	ret    

80101c87 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101c87:	55                   	push   %ebp
80101c88:	89 e5                	mov    %esp,%ebp
80101c8a:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101c8d:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101c94:	e8 76 31 00 00       	call   80104e0f <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101c99:	8b 45 08             	mov    0x8(%ebp),%eax
80101c9c:	8b 40 08             	mov    0x8(%eax),%eax
80101c9f:	83 f8 01             	cmp    $0x1,%eax
80101ca2:	0f 85 93 00 00 00    	jne    80101d3b <iput+0xb4>
80101ca8:	8b 45 08             	mov    0x8(%ebp),%eax
80101cab:	8b 40 0c             	mov    0xc(%eax),%eax
80101cae:	83 e0 02             	and    $0x2,%eax
80101cb1:	85 c0                	test   %eax,%eax
80101cb3:	0f 84 82 00 00 00    	je     80101d3b <iput+0xb4>
80101cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101cc0:	66 85 c0             	test   %ax,%ax
80101cc3:	75 76                	jne    80101d3b <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101cc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc8:	8b 40 0c             	mov    0xc(%eax),%eax
80101ccb:	83 e0 01             	and    $0x1,%eax
80101cce:	84 c0                	test   %al,%al
80101cd0:	74 0c                	je     80101cde <iput+0x57>
      panic("iput busy");
80101cd2:	c7 04 24 38 87 10 80 	movl   $0x80108738,(%esp)
80101cd9:	e8 5f e8 ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101cde:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce1:	8b 40 0c             	mov    0xc(%eax),%eax
80101ce4:	89 c2                	mov    %eax,%edx
80101ce6:	83 ca 01             	or     $0x1,%edx
80101ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cec:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101cef:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101cf6:	e8 76 31 00 00       	call   80104e71 <release>
    itrunc(ip);
80101cfb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cfe:	89 04 24             	mov    %eax,(%esp)
80101d01:	e8 72 01 00 00       	call   80101e78 <itrunc>
    ip->type = 0;
80101d06:	8b 45 08             	mov    0x8(%ebp),%eax
80101d09:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101d0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d12:	89 04 24             	mov    %eax,(%esp)
80101d15:	e8 fe fb ff ff       	call   80101918 <iupdate>
    acquire(&icache.lock);
80101d1a:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101d21:	e8 e9 30 00 00       	call   80104e0f <acquire>
    ip->flags = 0;
80101d26:	8b 45 08             	mov    0x8(%ebp),%eax
80101d29:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101d30:	8b 45 08             	mov    0x8(%ebp),%eax
80101d33:	89 04 24             	mov    %eax,(%esp)
80101d36:	e8 cf 2e 00 00       	call   80104c0a <wakeup>
  }
  ip->ref--;
80101d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3e:	8b 40 08             	mov    0x8(%eax),%eax
80101d41:	8d 50 ff             	lea    -0x1(%eax),%edx
80101d44:	8b 45 08             	mov    0x8(%ebp),%eax
80101d47:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101d4a:	c7 04 24 80 e8 10 80 	movl   $0x8010e880,(%esp)
80101d51:	e8 1b 31 00 00       	call   80104e71 <release>
}
80101d56:	c9                   	leave  
80101d57:	c3                   	ret    

80101d58 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101d58:	55                   	push   %ebp
80101d59:	89 e5                	mov    %esp,%ebp
80101d5b:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101d5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d61:	89 04 24             	mov    %eax,(%esp)
80101d64:	e8 b9 fe ff ff       	call   80101c22 <iunlock>
  iput(ip);
80101d69:	8b 45 08             	mov    0x8(%ebp),%eax
80101d6c:	89 04 24             	mov    %eax,(%esp)
80101d6f:	e8 13 ff ff ff       	call   80101c87 <iput>
}
80101d74:	c9                   	leave  
80101d75:	c3                   	ret    

80101d76 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101d76:	55                   	push   %ebp
80101d77:	89 e5                	mov    %esp,%ebp
80101d79:	53                   	push   %ebx
80101d7a:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101d7d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101d81:	77 3e                	ja     80101dc1 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101d83:	8b 45 08             	mov    0x8(%ebp),%eax
80101d86:	8b 55 0c             	mov    0xc(%ebp),%edx
80101d89:	83 c2 04             	add    $0x4,%edx
80101d8c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101d90:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d93:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d97:	75 20                	jne    80101db9 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101d99:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9c:	8b 00                	mov    (%eax),%eax
80101d9e:	89 04 24             	mov    %eax,(%esp)
80101da1:	e8 49 f8 ff ff       	call   801015ef <balloc>
80101da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101da9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dac:	8b 55 0c             	mov    0xc(%ebp),%edx
80101daf:	8d 4a 04             	lea    0x4(%edx),%ecx
80101db2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101db5:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dbc:	e9 b1 00 00 00       	jmp    80101e72 <bmap+0xfc>
  }
  bn -= NDIRECT;
80101dc1:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101dc5:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101dc9:	0f 87 97 00 00 00    	ja     80101e66 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101dcf:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd2:	8b 40 4c             	mov    0x4c(%eax),%eax
80101dd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101dd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101ddc:	75 19                	jne    80101df7 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101dde:	8b 45 08             	mov    0x8(%ebp),%eax
80101de1:	8b 00                	mov    (%eax),%eax
80101de3:	89 04 24             	mov    %eax,(%esp)
80101de6:	e8 04 f8 ff ff       	call   801015ef <balloc>
80101deb:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101dee:	8b 45 08             	mov    0x8(%ebp),%eax
80101df1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101df4:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101df7:	8b 45 08             	mov    0x8(%ebp),%eax
80101dfa:	8b 00                	mov    (%eax),%eax
80101dfc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dff:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e03:	89 04 24             	mov    %eax,(%esp)
80101e06:	e8 9b e3 ff ff       	call   801001a6 <bread>
80101e0b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101e0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e11:	83 c0 18             	add    $0x18,%eax
80101e14:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101e17:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e1a:	c1 e0 02             	shl    $0x2,%eax
80101e1d:	03 45 ec             	add    -0x14(%ebp),%eax
80101e20:	8b 00                	mov    (%eax),%eax
80101e22:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101e25:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101e29:	75 2b                	jne    80101e56 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101e2b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e2e:	c1 e0 02             	shl    $0x2,%eax
80101e31:	89 c3                	mov    %eax,%ebx
80101e33:	03 5d ec             	add    -0x14(%ebp),%ebx
80101e36:	8b 45 08             	mov    0x8(%ebp),%eax
80101e39:	8b 00                	mov    (%eax),%eax
80101e3b:	89 04 24             	mov    %eax,(%esp)
80101e3e:	e8 ac f7 ff ff       	call   801015ef <balloc>
80101e43:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101e46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e49:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101e4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e4e:	89 04 24             	mov    %eax,(%esp)
80101e51:	e8 d4 16 00 00       	call   8010352a <log_write>
    }
    brelse(bp);
80101e56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e59:	89 04 24             	mov    %eax,(%esp)
80101e5c:	e8 b6 e3 ff ff       	call   80100217 <brelse>
    return addr;
80101e61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e64:	eb 0c                	jmp    80101e72 <bmap+0xfc>
  }

  panic("bmap: out of range");
80101e66:	c7 04 24 42 87 10 80 	movl   $0x80108742,(%esp)
80101e6d:	e8 cb e6 ff ff       	call   8010053d <panic>
}
80101e72:	83 c4 24             	add    $0x24,%esp
80101e75:	5b                   	pop    %ebx
80101e76:	5d                   	pop    %ebp
80101e77:	c3                   	ret    

80101e78 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101e78:	55                   	push   %ebp
80101e79:	89 e5                	mov    %esp,%ebp
80101e7b:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101e7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e85:	eb 44                	jmp    80101ecb <itrunc+0x53>
    if(ip->addrs[i]){
80101e87:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101e8d:	83 c2 04             	add    $0x4,%edx
80101e90:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101e94:	85 c0                	test   %eax,%eax
80101e96:	74 2f                	je     80101ec7 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101e98:	8b 45 08             	mov    0x8(%ebp),%eax
80101e9b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101e9e:	83 c2 04             	add    $0x4,%edx
80101ea1:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101ea5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea8:	8b 00                	mov    (%eax),%eax
80101eaa:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eae:	89 04 24             	mov    %eax,(%esp)
80101eb1:	e8 90 f8 ff ff       	call   80101746 <bfree>
      ip->addrs[i] = 0;
80101eb6:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ebc:	83 c2 04             	add    $0x4,%edx
80101ebf:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101ec6:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101ec7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101ecb:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101ecf:	7e b6                	jle    80101e87 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101ed1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed4:	8b 40 4c             	mov    0x4c(%eax),%eax
80101ed7:	85 c0                	test   %eax,%eax
80101ed9:	0f 84 8f 00 00 00    	je     80101f6e <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ee5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee8:	8b 00                	mov    (%eax),%eax
80101eea:	89 54 24 04          	mov    %edx,0x4(%esp)
80101eee:	89 04 24             	mov    %eax,(%esp)
80101ef1:	e8 b0 e2 ff ff       	call   801001a6 <bread>
80101ef6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101ef9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101efc:	83 c0 18             	add    $0x18,%eax
80101eff:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101f02:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101f09:	eb 2f                	jmp    80101f3a <itrunc+0xc2>
      if(a[j])
80101f0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f0e:	c1 e0 02             	shl    $0x2,%eax
80101f11:	03 45 e8             	add    -0x18(%ebp),%eax
80101f14:	8b 00                	mov    (%eax),%eax
80101f16:	85 c0                	test   %eax,%eax
80101f18:	74 1c                	je     80101f36 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101f1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f1d:	c1 e0 02             	shl    $0x2,%eax
80101f20:	03 45 e8             	add    -0x18(%ebp),%eax
80101f23:	8b 10                	mov    (%eax),%edx
80101f25:	8b 45 08             	mov    0x8(%ebp),%eax
80101f28:	8b 00                	mov    (%eax),%eax
80101f2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f2e:	89 04 24             	mov    %eax,(%esp)
80101f31:	e8 10 f8 ff ff       	call   80101746 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101f36:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101f3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f3d:	83 f8 7f             	cmp    $0x7f,%eax
80101f40:	76 c9                	jbe    80101f0b <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101f42:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f45:	89 04 24             	mov    %eax,(%esp)
80101f48:	e8 ca e2 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f50:	8b 50 4c             	mov    0x4c(%eax),%edx
80101f53:	8b 45 08             	mov    0x8(%ebp),%eax
80101f56:	8b 00                	mov    (%eax),%eax
80101f58:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f5c:	89 04 24             	mov    %eax,(%esp)
80101f5f:	e8 e2 f7 ff ff       	call   80101746 <bfree>
    ip->addrs[NDIRECT] = 0;
80101f64:	8b 45 08             	mov    0x8(%ebp),%eax
80101f67:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101f6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f71:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101f78:	8b 45 08             	mov    0x8(%ebp),%eax
80101f7b:	89 04 24             	mov    %eax,(%esp)
80101f7e:	e8 95 f9 ff ff       	call   80101918 <iupdate>
}
80101f83:	c9                   	leave  
80101f84:	c3                   	ret    

80101f85 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101f85:	55                   	push   %ebp
80101f86:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101f88:	8b 45 08             	mov    0x8(%ebp),%eax
80101f8b:	8b 00                	mov    (%eax),%eax
80101f8d:	89 c2                	mov    %eax,%edx
80101f8f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f92:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101f95:	8b 45 08             	mov    0x8(%ebp),%eax
80101f98:	8b 50 04             	mov    0x4(%eax),%edx
80101f9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f9e:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101fa8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fab:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101fae:	8b 45 08             	mov    0x8(%ebp),%eax
80101fb1:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101fb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fb8:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101fbc:	8b 45 08             	mov    0x8(%ebp),%eax
80101fbf:	8b 50 18             	mov    0x18(%eax),%edx
80101fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fc5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101fc8:	5d                   	pop    %ebp
80101fc9:	c3                   	ret    

80101fca <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101fca:	55                   	push   %ebp
80101fcb:	89 e5                	mov    %esp,%ebp
80101fcd:	53                   	push   %ebx
80101fce:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101fd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101fd8:	66 83 f8 03          	cmp    $0x3,%ax
80101fdc:	75 60                	jne    8010203e <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101fde:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fe5:	66 85 c0             	test   %ax,%ax
80101fe8:	78 20                	js     8010200a <readi+0x40>
80101fea:	8b 45 08             	mov    0x8(%ebp),%eax
80101fed:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ff1:	66 83 f8 09          	cmp    $0x9,%ax
80101ff5:	7f 13                	jg     8010200a <readi+0x40>
80101ff7:	8b 45 08             	mov    0x8(%ebp),%eax
80101ffa:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ffe:	98                   	cwtl   
80101fff:	8b 04 c5 20 e8 10 80 	mov    -0x7fef17e0(,%eax,8),%eax
80102006:	85 c0                	test   %eax,%eax
80102008:	75 0a                	jne    80102014 <readi+0x4a>
      return -1;
8010200a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010200f:	e9 1b 01 00 00       	jmp    8010212f <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102014:	8b 45 08             	mov    0x8(%ebp),%eax
80102017:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010201b:	98                   	cwtl   
8010201c:	8b 14 c5 20 e8 10 80 	mov    -0x7fef17e0(,%eax,8),%edx
80102023:	8b 45 14             	mov    0x14(%ebp),%eax
80102026:	89 44 24 08          	mov    %eax,0x8(%esp)
8010202a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010202d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102031:	8b 45 08             	mov    0x8(%ebp),%eax
80102034:	89 04 24             	mov    %eax,(%esp)
80102037:	ff d2                	call   *%edx
80102039:	e9 f1 00 00 00       	jmp    8010212f <readi+0x165>
  }

  if(off > ip->size || off + n < off)
8010203e:	8b 45 08             	mov    0x8(%ebp),%eax
80102041:	8b 40 18             	mov    0x18(%eax),%eax
80102044:	3b 45 10             	cmp    0x10(%ebp),%eax
80102047:	72 0d                	jb     80102056 <readi+0x8c>
80102049:	8b 45 14             	mov    0x14(%ebp),%eax
8010204c:	8b 55 10             	mov    0x10(%ebp),%edx
8010204f:	01 d0                	add    %edx,%eax
80102051:	3b 45 10             	cmp    0x10(%ebp),%eax
80102054:	73 0a                	jae    80102060 <readi+0x96>
    return -1;
80102056:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010205b:	e9 cf 00 00 00       	jmp    8010212f <readi+0x165>
  if(off + n > ip->size)
80102060:	8b 45 14             	mov    0x14(%ebp),%eax
80102063:	8b 55 10             	mov    0x10(%ebp),%edx
80102066:	01 c2                	add    %eax,%edx
80102068:	8b 45 08             	mov    0x8(%ebp),%eax
8010206b:	8b 40 18             	mov    0x18(%eax),%eax
8010206e:	39 c2                	cmp    %eax,%edx
80102070:	76 0c                	jbe    8010207e <readi+0xb4>
    n = ip->size - off;
80102072:	8b 45 08             	mov    0x8(%ebp),%eax
80102075:	8b 40 18             	mov    0x18(%eax),%eax
80102078:	2b 45 10             	sub    0x10(%ebp),%eax
8010207b:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010207e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102085:	e9 96 00 00 00       	jmp    80102120 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010208a:	8b 45 10             	mov    0x10(%ebp),%eax
8010208d:	c1 e8 09             	shr    $0x9,%eax
80102090:	89 44 24 04          	mov    %eax,0x4(%esp)
80102094:	8b 45 08             	mov    0x8(%ebp),%eax
80102097:	89 04 24             	mov    %eax,(%esp)
8010209a:	e8 d7 fc ff ff       	call   80101d76 <bmap>
8010209f:	8b 55 08             	mov    0x8(%ebp),%edx
801020a2:	8b 12                	mov    (%edx),%edx
801020a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801020a8:	89 14 24             	mov    %edx,(%esp)
801020ab:	e8 f6 e0 ff ff       	call   801001a6 <bread>
801020b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801020b3:	8b 45 10             	mov    0x10(%ebp),%eax
801020b6:	89 c2                	mov    %eax,%edx
801020b8:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801020be:	b8 00 02 00 00       	mov    $0x200,%eax
801020c3:	89 c1                	mov    %eax,%ecx
801020c5:	29 d1                	sub    %edx,%ecx
801020c7:	89 ca                	mov    %ecx,%edx
801020c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020cc:	8b 4d 14             	mov    0x14(%ebp),%ecx
801020cf:	89 cb                	mov    %ecx,%ebx
801020d1:	29 c3                	sub    %eax,%ebx
801020d3:	89 d8                	mov    %ebx,%eax
801020d5:	39 c2                	cmp    %eax,%edx
801020d7:	0f 46 c2             	cmovbe %edx,%eax
801020da:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801020dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020e0:	8d 50 18             	lea    0x18(%eax),%edx
801020e3:	8b 45 10             	mov    0x10(%ebp),%eax
801020e6:	25 ff 01 00 00       	and    $0x1ff,%eax
801020eb:	01 c2                	add    %eax,%edx
801020ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020f0:	89 44 24 08          	mov    %eax,0x8(%esp)
801020f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801020f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801020fb:	89 04 24             	mov    %eax,(%esp)
801020fe:	e8 2e 30 00 00       	call   80105131 <memmove>
    brelse(bp);
80102103:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102106:	89 04 24             	mov    %eax,(%esp)
80102109:	e8 09 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010210e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102111:	01 45 f4             	add    %eax,-0xc(%ebp)
80102114:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102117:	01 45 10             	add    %eax,0x10(%ebp)
8010211a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010211d:	01 45 0c             	add    %eax,0xc(%ebp)
80102120:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102123:	3b 45 14             	cmp    0x14(%ebp),%eax
80102126:	0f 82 5e ff ff ff    	jb     8010208a <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
8010212c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010212f:	83 c4 24             	add    $0x24,%esp
80102132:	5b                   	pop    %ebx
80102133:	5d                   	pop    %ebp
80102134:	c3                   	ret    

80102135 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102135:	55                   	push   %ebp
80102136:	89 e5                	mov    %esp,%ebp
80102138:	53                   	push   %ebx
80102139:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010213c:	8b 45 08             	mov    0x8(%ebp),%eax
8010213f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102143:	66 83 f8 03          	cmp    $0x3,%ax
80102147:	75 60                	jne    801021a9 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102149:	8b 45 08             	mov    0x8(%ebp),%eax
8010214c:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102150:	66 85 c0             	test   %ax,%ax
80102153:	78 20                	js     80102175 <writei+0x40>
80102155:	8b 45 08             	mov    0x8(%ebp),%eax
80102158:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010215c:	66 83 f8 09          	cmp    $0x9,%ax
80102160:	7f 13                	jg     80102175 <writei+0x40>
80102162:	8b 45 08             	mov    0x8(%ebp),%eax
80102165:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102169:	98                   	cwtl   
8010216a:	8b 04 c5 24 e8 10 80 	mov    -0x7fef17dc(,%eax,8),%eax
80102171:	85 c0                	test   %eax,%eax
80102173:	75 0a                	jne    8010217f <writei+0x4a>
      return -1;
80102175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010217a:	e9 46 01 00 00       	jmp    801022c5 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
8010217f:	8b 45 08             	mov    0x8(%ebp),%eax
80102182:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102186:	98                   	cwtl   
80102187:	8b 14 c5 24 e8 10 80 	mov    -0x7fef17dc(,%eax,8),%edx
8010218e:	8b 45 14             	mov    0x14(%ebp),%eax
80102191:	89 44 24 08          	mov    %eax,0x8(%esp)
80102195:	8b 45 0c             	mov    0xc(%ebp),%eax
80102198:	89 44 24 04          	mov    %eax,0x4(%esp)
8010219c:	8b 45 08             	mov    0x8(%ebp),%eax
8010219f:	89 04 24             	mov    %eax,(%esp)
801021a2:	ff d2                	call   *%edx
801021a4:	e9 1c 01 00 00       	jmp    801022c5 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
801021a9:	8b 45 08             	mov    0x8(%ebp),%eax
801021ac:	8b 40 18             	mov    0x18(%eax),%eax
801021af:	3b 45 10             	cmp    0x10(%ebp),%eax
801021b2:	72 0d                	jb     801021c1 <writei+0x8c>
801021b4:	8b 45 14             	mov    0x14(%ebp),%eax
801021b7:	8b 55 10             	mov    0x10(%ebp),%edx
801021ba:	01 d0                	add    %edx,%eax
801021bc:	3b 45 10             	cmp    0x10(%ebp),%eax
801021bf:	73 0a                	jae    801021cb <writei+0x96>
    return -1;
801021c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021c6:	e9 fa 00 00 00       	jmp    801022c5 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
801021cb:	8b 45 14             	mov    0x14(%ebp),%eax
801021ce:	8b 55 10             	mov    0x10(%ebp),%edx
801021d1:	01 d0                	add    %edx,%eax
801021d3:	3d 00 18 01 00       	cmp    $0x11800,%eax
801021d8:	76 0a                	jbe    801021e4 <writei+0xaf>
    return -1;
801021da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021df:	e9 e1 00 00 00       	jmp    801022c5 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801021e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021eb:	e9 a1 00 00 00       	jmp    80102291 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801021f0:	8b 45 10             	mov    0x10(%ebp),%eax
801021f3:	c1 e8 09             	shr    $0x9,%eax
801021f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021fa:	8b 45 08             	mov    0x8(%ebp),%eax
801021fd:	89 04 24             	mov    %eax,(%esp)
80102200:	e8 71 fb ff ff       	call   80101d76 <bmap>
80102205:	8b 55 08             	mov    0x8(%ebp),%edx
80102208:	8b 12                	mov    (%edx),%edx
8010220a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010220e:	89 14 24             	mov    %edx,(%esp)
80102211:	e8 90 df ff ff       	call   801001a6 <bread>
80102216:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102219:	8b 45 10             	mov    0x10(%ebp),%eax
8010221c:	89 c2                	mov    %eax,%edx
8010221e:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102224:	b8 00 02 00 00       	mov    $0x200,%eax
80102229:	89 c1                	mov    %eax,%ecx
8010222b:	29 d1                	sub    %edx,%ecx
8010222d:	89 ca                	mov    %ecx,%edx
8010222f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102232:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102235:	89 cb                	mov    %ecx,%ebx
80102237:	29 c3                	sub    %eax,%ebx
80102239:	89 d8                	mov    %ebx,%eax
8010223b:	39 c2                	cmp    %eax,%edx
8010223d:	0f 46 c2             	cmovbe %edx,%eax
80102240:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102243:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102246:	8d 50 18             	lea    0x18(%eax),%edx
80102249:	8b 45 10             	mov    0x10(%ebp),%eax
8010224c:	25 ff 01 00 00       	and    $0x1ff,%eax
80102251:	01 c2                	add    %eax,%edx
80102253:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102256:	89 44 24 08          	mov    %eax,0x8(%esp)
8010225a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010225d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102261:	89 14 24             	mov    %edx,(%esp)
80102264:	e8 c8 2e 00 00       	call   80105131 <memmove>
    log_write(bp);
80102269:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010226c:	89 04 24             	mov    %eax,(%esp)
8010226f:	e8 b6 12 00 00       	call   8010352a <log_write>
    brelse(bp);
80102274:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102277:	89 04 24             	mov    %eax,(%esp)
8010227a:	e8 98 df ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010227f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102282:	01 45 f4             	add    %eax,-0xc(%ebp)
80102285:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102288:	01 45 10             	add    %eax,0x10(%ebp)
8010228b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010228e:	01 45 0c             	add    %eax,0xc(%ebp)
80102291:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102294:	3b 45 14             	cmp    0x14(%ebp),%eax
80102297:	0f 82 53 ff ff ff    	jb     801021f0 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
8010229d:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801022a1:	74 1f                	je     801022c2 <writei+0x18d>
801022a3:	8b 45 08             	mov    0x8(%ebp),%eax
801022a6:	8b 40 18             	mov    0x18(%eax),%eax
801022a9:	3b 45 10             	cmp    0x10(%ebp),%eax
801022ac:	73 14                	jae    801022c2 <writei+0x18d>
    ip->size = off;
801022ae:	8b 45 08             	mov    0x8(%ebp),%eax
801022b1:	8b 55 10             	mov    0x10(%ebp),%edx
801022b4:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801022b7:	8b 45 08             	mov    0x8(%ebp),%eax
801022ba:	89 04 24             	mov    %eax,(%esp)
801022bd:	e8 56 f6 ff ff       	call   80101918 <iupdate>
  }
  return n;
801022c2:	8b 45 14             	mov    0x14(%ebp),%eax
}
801022c5:	83 c4 24             	add    $0x24,%esp
801022c8:	5b                   	pop    %ebx
801022c9:	5d                   	pop    %ebp
801022ca:	c3                   	ret    

801022cb <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801022cb:	55                   	push   %ebp
801022cc:	89 e5                	mov    %esp,%ebp
801022ce:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801022d1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022d8:	00 
801022d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801022dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801022e0:	8b 45 08             	mov    0x8(%ebp),%eax
801022e3:	89 04 24             	mov    %eax,(%esp)
801022e6:	e8 ea 2e 00 00       	call   801051d5 <strncmp>
}
801022eb:	c9                   	leave  
801022ec:	c3                   	ret    

801022ed <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801022ed:	55                   	push   %ebp
801022ee:	89 e5                	mov    %esp,%ebp
801022f0:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801022f3:	8b 45 08             	mov    0x8(%ebp),%eax
801022f6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801022fa:	66 83 f8 01          	cmp    $0x1,%ax
801022fe:	74 0c                	je     8010230c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102300:	c7 04 24 55 87 10 80 	movl   $0x80108755,(%esp)
80102307:	e8 31 e2 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010230c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102313:	e9 87 00 00 00       	jmp    8010239f <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102318:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010231f:	00 
80102320:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102323:	89 44 24 08          	mov    %eax,0x8(%esp)
80102327:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010232a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010232e:	8b 45 08             	mov    0x8(%ebp),%eax
80102331:	89 04 24             	mov    %eax,(%esp)
80102334:	e8 91 fc ff ff       	call   80101fca <readi>
80102339:	83 f8 10             	cmp    $0x10,%eax
8010233c:	74 0c                	je     8010234a <dirlookup+0x5d>
      panic("dirlink read");
8010233e:	c7 04 24 67 87 10 80 	movl   $0x80108767,(%esp)
80102345:	e8 f3 e1 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010234a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010234e:	66 85 c0             	test   %ax,%ax
80102351:	74 47                	je     8010239a <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
80102353:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102356:	83 c0 02             	add    $0x2,%eax
80102359:	89 44 24 04          	mov    %eax,0x4(%esp)
8010235d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102360:	89 04 24             	mov    %eax,(%esp)
80102363:	e8 63 ff ff ff       	call   801022cb <namecmp>
80102368:	85 c0                	test   %eax,%eax
8010236a:	75 2f                	jne    8010239b <dirlookup+0xae>
      // entry matches path element
      if(poff)
8010236c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102370:	74 08                	je     8010237a <dirlookup+0x8d>
        *poff = off;
80102372:	8b 45 10             	mov    0x10(%ebp),%eax
80102375:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102378:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010237a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010237e:	0f b7 c0             	movzwl %ax,%eax
80102381:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102384:	8b 45 08             	mov    0x8(%ebp),%eax
80102387:	8b 00                	mov    (%eax),%eax
80102389:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010238c:	89 54 24 04          	mov    %edx,0x4(%esp)
80102390:	89 04 24             	mov    %eax,(%esp)
80102393:	e8 38 f6 ff ff       	call   801019d0 <iget>
80102398:	eb 19                	jmp    801023b3 <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
8010239a:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010239b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010239f:	8b 45 08             	mov    0x8(%ebp),%eax
801023a2:	8b 40 18             	mov    0x18(%eax),%eax
801023a5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801023a8:	0f 87 6a ff ff ff    	ja     80102318 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801023ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801023b3:	c9                   	leave  
801023b4:	c3                   	ret    

801023b5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801023b5:	55                   	push   %ebp
801023b6:	89 e5                	mov    %esp,%ebp
801023b8:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801023bb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801023c2:	00 
801023c3:	8b 45 0c             	mov    0xc(%ebp),%eax
801023c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801023ca:	8b 45 08             	mov    0x8(%ebp),%eax
801023cd:	89 04 24             	mov    %eax,(%esp)
801023d0:	e8 18 ff ff ff       	call   801022ed <dirlookup>
801023d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023d8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023dc:	74 15                	je     801023f3 <dirlink+0x3e>
    iput(ip);
801023de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023e1:	89 04 24             	mov    %eax,(%esp)
801023e4:	e8 9e f8 ff ff       	call   80101c87 <iput>
    return -1;
801023e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023ee:	e9 b8 00 00 00       	jmp    801024ab <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801023f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801023fa:	eb 44                	jmp    80102440 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801023fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ff:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102406:	00 
80102407:	89 44 24 08          	mov    %eax,0x8(%esp)
8010240b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010240e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102412:	8b 45 08             	mov    0x8(%ebp),%eax
80102415:	89 04 24             	mov    %eax,(%esp)
80102418:	e8 ad fb ff ff       	call   80101fca <readi>
8010241d:	83 f8 10             	cmp    $0x10,%eax
80102420:	74 0c                	je     8010242e <dirlink+0x79>
      panic("dirlink read");
80102422:	c7 04 24 67 87 10 80 	movl   $0x80108767,(%esp)
80102429:	e8 0f e1 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010242e:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102432:	66 85 c0             	test   %ax,%ax
80102435:	74 18                	je     8010244f <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102437:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010243a:	83 c0 10             	add    $0x10,%eax
8010243d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102440:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102443:	8b 45 08             	mov    0x8(%ebp),%eax
80102446:	8b 40 18             	mov    0x18(%eax),%eax
80102449:	39 c2                	cmp    %eax,%edx
8010244b:	72 af                	jb     801023fc <dirlink+0x47>
8010244d:	eb 01                	jmp    80102450 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010244f:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102450:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102457:	00 
80102458:	8b 45 0c             	mov    0xc(%ebp),%eax
8010245b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010245f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102462:	83 c0 02             	add    $0x2,%eax
80102465:	89 04 24             	mov    %eax,(%esp)
80102468:	e8 c0 2d 00 00       	call   8010522d <strncpy>
  de.inum = inum;
8010246d:	8b 45 10             	mov    0x10(%ebp),%eax
80102470:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102474:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102477:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010247e:	00 
8010247f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102483:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102486:	89 44 24 04          	mov    %eax,0x4(%esp)
8010248a:	8b 45 08             	mov    0x8(%ebp),%eax
8010248d:	89 04 24             	mov    %eax,(%esp)
80102490:	e8 a0 fc ff ff       	call   80102135 <writei>
80102495:	83 f8 10             	cmp    $0x10,%eax
80102498:	74 0c                	je     801024a6 <dirlink+0xf1>
    panic("dirlink");
8010249a:	c7 04 24 74 87 10 80 	movl   $0x80108774,(%esp)
801024a1:	e8 97 e0 ff ff       	call   8010053d <panic>
  
  return 0;
801024a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801024ab:	c9                   	leave  
801024ac:	c3                   	ret    

801024ad <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801024ad:	55                   	push   %ebp
801024ae:	89 e5                	mov    %esp,%ebp
801024b0:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801024b3:	eb 04                	jmp    801024b9 <skipelem+0xc>
    path++;
801024b5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801024b9:	8b 45 08             	mov    0x8(%ebp),%eax
801024bc:	0f b6 00             	movzbl (%eax),%eax
801024bf:	3c 2f                	cmp    $0x2f,%al
801024c1:	74 f2                	je     801024b5 <skipelem+0x8>
    path++;
  if(*path == 0)
801024c3:	8b 45 08             	mov    0x8(%ebp),%eax
801024c6:	0f b6 00             	movzbl (%eax),%eax
801024c9:	84 c0                	test   %al,%al
801024cb:	75 0a                	jne    801024d7 <skipelem+0x2a>
    return 0;
801024cd:	b8 00 00 00 00       	mov    $0x0,%eax
801024d2:	e9 86 00 00 00       	jmp    8010255d <skipelem+0xb0>
  s = path;
801024d7:	8b 45 08             	mov    0x8(%ebp),%eax
801024da:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801024dd:	eb 04                	jmp    801024e3 <skipelem+0x36>
    path++;
801024df:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801024e3:	8b 45 08             	mov    0x8(%ebp),%eax
801024e6:	0f b6 00             	movzbl (%eax),%eax
801024e9:	3c 2f                	cmp    $0x2f,%al
801024eb:	74 0a                	je     801024f7 <skipelem+0x4a>
801024ed:	8b 45 08             	mov    0x8(%ebp),%eax
801024f0:	0f b6 00             	movzbl (%eax),%eax
801024f3:	84 c0                	test   %al,%al
801024f5:	75 e8                	jne    801024df <skipelem+0x32>
    path++;
  len = path - s;
801024f7:	8b 55 08             	mov    0x8(%ebp),%edx
801024fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024fd:	89 d1                	mov    %edx,%ecx
801024ff:	29 c1                	sub    %eax,%ecx
80102501:	89 c8                	mov    %ecx,%eax
80102503:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102506:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010250a:	7e 1c                	jle    80102528 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
8010250c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102513:	00 
80102514:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102517:	89 44 24 04          	mov    %eax,0x4(%esp)
8010251b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010251e:	89 04 24             	mov    %eax,(%esp)
80102521:	e8 0b 2c 00 00       	call   80105131 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102526:	eb 28                	jmp    80102550 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102528:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010252b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010252f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102532:	89 44 24 04          	mov    %eax,0x4(%esp)
80102536:	8b 45 0c             	mov    0xc(%ebp),%eax
80102539:	89 04 24             	mov    %eax,(%esp)
8010253c:	e8 f0 2b 00 00       	call   80105131 <memmove>
    name[len] = 0;
80102541:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102544:	03 45 0c             	add    0xc(%ebp),%eax
80102547:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010254a:	eb 04                	jmp    80102550 <skipelem+0xa3>
    path++;
8010254c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102550:	8b 45 08             	mov    0x8(%ebp),%eax
80102553:	0f b6 00             	movzbl (%eax),%eax
80102556:	3c 2f                	cmp    $0x2f,%al
80102558:	74 f2                	je     8010254c <skipelem+0x9f>
    path++;
  return path;
8010255a:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010255d:	c9                   	leave  
8010255e:	c3                   	ret    

8010255f <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010255f:	55                   	push   %ebp
80102560:	89 e5                	mov    %esp,%ebp
80102562:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102565:	8b 45 08             	mov    0x8(%ebp),%eax
80102568:	0f b6 00             	movzbl (%eax),%eax
8010256b:	3c 2f                	cmp    $0x2f,%al
8010256d:	75 1c                	jne    8010258b <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010256f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102576:	00 
80102577:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010257e:	e8 4d f4 ff ff       	call   801019d0 <iget>
80102583:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102586:	e9 af 00 00 00       	jmp    8010263a <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010258b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102591:	8b 40 68             	mov    0x68(%eax),%eax
80102594:	89 04 24             	mov    %eax,(%esp)
80102597:	e8 06 f5 ff ff       	call   80101aa2 <idup>
8010259c:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010259f:	e9 96 00 00 00       	jmp    8010263a <namex+0xdb>
    ilock(ip);
801025a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025a7:	89 04 24             	mov    %eax,(%esp)
801025aa:	e8 25 f5 ff ff       	call   80101ad4 <ilock>
    if(ip->type != T_DIR){
801025af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025b2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801025b6:	66 83 f8 01          	cmp    $0x1,%ax
801025ba:	74 15                	je     801025d1 <namex+0x72>
      iunlockput(ip);
801025bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025bf:	89 04 24             	mov    %eax,(%esp)
801025c2:	e8 91 f7 ff ff       	call   80101d58 <iunlockput>
      return 0;
801025c7:	b8 00 00 00 00       	mov    $0x0,%eax
801025cc:	e9 a3 00 00 00       	jmp    80102674 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801025d1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025d5:	74 1d                	je     801025f4 <namex+0x95>
801025d7:	8b 45 08             	mov    0x8(%ebp),%eax
801025da:	0f b6 00             	movzbl (%eax),%eax
801025dd:	84 c0                	test   %al,%al
801025df:	75 13                	jne    801025f4 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801025e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025e4:	89 04 24             	mov    %eax,(%esp)
801025e7:	e8 36 f6 ff ff       	call   80101c22 <iunlock>
      return ip;
801025ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025ef:	e9 80 00 00 00       	jmp    80102674 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801025f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801025fb:	00 
801025fc:	8b 45 10             	mov    0x10(%ebp),%eax
801025ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80102603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102606:	89 04 24             	mov    %eax,(%esp)
80102609:	e8 df fc ff ff       	call   801022ed <dirlookup>
8010260e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102611:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102615:	75 12                	jne    80102629 <namex+0xca>
      iunlockput(ip);
80102617:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010261a:	89 04 24             	mov    %eax,(%esp)
8010261d:	e8 36 f7 ff ff       	call   80101d58 <iunlockput>
      return 0;
80102622:	b8 00 00 00 00       	mov    $0x0,%eax
80102627:	eb 4b                	jmp    80102674 <namex+0x115>
    }
    iunlockput(ip);
80102629:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010262c:	89 04 24             	mov    %eax,(%esp)
8010262f:	e8 24 f7 ff ff       	call   80101d58 <iunlockput>
    ip = next;
80102634:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102637:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010263a:	8b 45 10             	mov    0x10(%ebp),%eax
8010263d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102641:	8b 45 08             	mov    0x8(%ebp),%eax
80102644:	89 04 24             	mov    %eax,(%esp)
80102647:	e8 61 fe ff ff       	call   801024ad <skipelem>
8010264c:	89 45 08             	mov    %eax,0x8(%ebp)
8010264f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102653:	0f 85 4b ff ff ff    	jne    801025a4 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102659:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010265d:	74 12                	je     80102671 <namex+0x112>
    iput(ip);
8010265f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102662:	89 04 24             	mov    %eax,(%esp)
80102665:	e8 1d f6 ff ff       	call   80101c87 <iput>
    return 0;
8010266a:	b8 00 00 00 00       	mov    $0x0,%eax
8010266f:	eb 03                	jmp    80102674 <namex+0x115>
  }
  return ip;
80102671:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102674:	c9                   	leave  
80102675:	c3                   	ret    

80102676 <namei>:

struct inode*
namei(char *path)
{
80102676:	55                   	push   %ebp
80102677:	89 e5                	mov    %esp,%ebp
80102679:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010267c:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010267f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102683:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010268a:	00 
8010268b:	8b 45 08             	mov    0x8(%ebp),%eax
8010268e:	89 04 24             	mov    %eax,(%esp)
80102691:	e8 c9 fe ff ff       	call   8010255f <namex>
}
80102696:	c9                   	leave  
80102697:	c3                   	ret    

80102698 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102698:	55                   	push   %ebp
80102699:	89 e5                	mov    %esp,%ebp
8010269b:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010269e:	8b 45 0c             	mov    0xc(%ebp),%eax
801026a1:	89 44 24 08          	mov    %eax,0x8(%esp)
801026a5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801026ac:	00 
801026ad:	8b 45 08             	mov    0x8(%ebp),%eax
801026b0:	89 04 24             	mov    %eax,(%esp)
801026b3:	e8 a7 fe ff ff       	call   8010255f <namex>
}
801026b8:	c9                   	leave  
801026b9:	c3                   	ret    
	...

801026bc <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801026bc:	55                   	push   %ebp
801026bd:	89 e5                	mov    %esp,%ebp
801026bf:	53                   	push   %ebx
801026c0:	83 ec 14             	sub    $0x14,%esp
801026c3:	8b 45 08             	mov    0x8(%ebp),%eax
801026c6:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801026ca:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801026ce:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801026d2:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801026d6:	ec                   	in     (%dx),%al
801026d7:	89 c3                	mov    %eax,%ebx
801026d9:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801026dc:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801026e0:	83 c4 14             	add    $0x14,%esp
801026e3:	5b                   	pop    %ebx
801026e4:	5d                   	pop    %ebp
801026e5:	c3                   	ret    

801026e6 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801026e6:	55                   	push   %ebp
801026e7:	89 e5                	mov    %esp,%ebp
801026e9:	57                   	push   %edi
801026ea:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801026eb:	8b 55 08             	mov    0x8(%ebp),%edx
801026ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801026f1:	8b 45 10             	mov    0x10(%ebp),%eax
801026f4:	89 cb                	mov    %ecx,%ebx
801026f6:	89 df                	mov    %ebx,%edi
801026f8:	89 c1                	mov    %eax,%ecx
801026fa:	fc                   	cld    
801026fb:	f3 6d                	rep insl (%dx),%es:(%edi)
801026fd:	89 c8                	mov    %ecx,%eax
801026ff:	89 fb                	mov    %edi,%ebx
80102701:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102704:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102707:	5b                   	pop    %ebx
80102708:	5f                   	pop    %edi
80102709:	5d                   	pop    %ebp
8010270a:	c3                   	ret    

8010270b <outb>:

static inline void
outb(ushort port, uchar data)
{
8010270b:	55                   	push   %ebp
8010270c:	89 e5                	mov    %esp,%ebp
8010270e:	83 ec 08             	sub    $0x8,%esp
80102711:	8b 55 08             	mov    0x8(%ebp),%edx
80102714:	8b 45 0c             	mov    0xc(%ebp),%eax
80102717:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010271b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010271e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102722:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102726:	ee                   	out    %al,(%dx)
}
80102727:	c9                   	leave  
80102728:	c3                   	ret    

80102729 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102729:	55                   	push   %ebp
8010272a:	89 e5                	mov    %esp,%ebp
8010272c:	56                   	push   %esi
8010272d:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010272e:	8b 55 08             	mov    0x8(%ebp),%edx
80102731:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102734:	8b 45 10             	mov    0x10(%ebp),%eax
80102737:	89 cb                	mov    %ecx,%ebx
80102739:	89 de                	mov    %ebx,%esi
8010273b:	89 c1                	mov    %eax,%ecx
8010273d:	fc                   	cld    
8010273e:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102740:	89 c8                	mov    %ecx,%eax
80102742:	89 f3                	mov    %esi,%ebx
80102744:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102747:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010274a:	5b                   	pop    %ebx
8010274b:	5e                   	pop    %esi
8010274c:	5d                   	pop    %ebp
8010274d:	c3                   	ret    

8010274e <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010274e:	55                   	push   %ebp
8010274f:	89 e5                	mov    %esp,%ebp
80102751:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102754:	90                   	nop
80102755:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010275c:	e8 5b ff ff ff       	call   801026bc <inb>
80102761:	0f b6 c0             	movzbl %al,%eax
80102764:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102767:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010276a:	25 c0 00 00 00       	and    $0xc0,%eax
8010276f:	83 f8 40             	cmp    $0x40,%eax
80102772:	75 e1                	jne    80102755 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102774:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102778:	74 11                	je     8010278b <idewait+0x3d>
8010277a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010277d:	83 e0 21             	and    $0x21,%eax
80102780:	85 c0                	test   %eax,%eax
80102782:	74 07                	je     8010278b <idewait+0x3d>
    return -1;
80102784:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102789:	eb 05                	jmp    80102790 <idewait+0x42>
  return 0;
8010278b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102790:	c9                   	leave  
80102791:	c3                   	ret    

80102792 <ideinit>:

void
ideinit(void)
{
80102792:	55                   	push   %ebp
80102793:	89 e5                	mov    %esp,%ebp
80102795:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102798:	c7 44 24 04 7c 87 10 	movl   $0x8010877c,0x4(%esp)
8010279f:	80 
801027a0:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
801027a7:	e8 42 26 00 00       	call   80104dee <initlock>
  picenable(IRQ_IDE);
801027ac:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801027b3:	e8 75 15 00 00       	call   80103d2d <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801027b8:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
801027bd:	83 e8 01             	sub    $0x1,%eax
801027c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801027c4:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801027cb:	e8 12 04 00 00       	call   80102be2 <ioapicenable>
  idewait(0);
801027d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801027d7:	e8 72 ff ff ff       	call   8010274e <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801027dc:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801027e3:	00 
801027e4:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801027eb:	e8 1b ff ff ff       	call   8010270b <outb>
  for(i=0; i<1000; i++){
801027f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801027f7:	eb 20                	jmp    80102819 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801027f9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102800:	e8 b7 fe ff ff       	call   801026bc <inb>
80102805:	84 c0                	test   %al,%al
80102807:	74 0c                	je     80102815 <ideinit+0x83>
      havedisk1 = 1;
80102809:	c7 05 58 b6 10 80 01 	movl   $0x1,0x8010b658
80102810:	00 00 00 
      break;
80102813:	eb 0d                	jmp    80102822 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102815:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102819:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102820:	7e d7                	jle    801027f9 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102822:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102829:	00 
8010282a:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102831:	e8 d5 fe ff ff       	call   8010270b <outb>
}
80102836:	c9                   	leave  
80102837:	c3                   	ret    

80102838 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102838:	55                   	push   %ebp
80102839:	89 e5                	mov    %esp,%ebp
8010283b:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010283e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102842:	75 0c                	jne    80102850 <idestart+0x18>
    panic("idestart");
80102844:	c7 04 24 80 87 10 80 	movl   $0x80108780,(%esp)
8010284b:	e8 ed dc ff ff       	call   8010053d <panic>

  idewait(0);
80102850:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102857:	e8 f2 fe ff ff       	call   8010274e <idewait>
  outb(0x3f6, 0);  // generate interrupt
8010285c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102863:	00 
80102864:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010286b:	e8 9b fe ff ff       	call   8010270b <outb>
  outb(0x1f2, 1);  // number of sectors
80102870:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102877:	00 
80102878:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
8010287f:	e8 87 fe ff ff       	call   8010270b <outb>
  outb(0x1f3, b->sector & 0xff);
80102884:	8b 45 08             	mov    0x8(%ebp),%eax
80102887:	8b 40 08             	mov    0x8(%eax),%eax
8010288a:	0f b6 c0             	movzbl %al,%eax
8010288d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102891:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102898:	e8 6e fe ff ff       	call   8010270b <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
8010289d:	8b 45 08             	mov    0x8(%ebp),%eax
801028a0:	8b 40 08             	mov    0x8(%eax),%eax
801028a3:	c1 e8 08             	shr    $0x8,%eax
801028a6:	0f b6 c0             	movzbl %al,%eax
801028a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801028ad:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
801028b4:	e8 52 fe ff ff       	call   8010270b <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801028b9:	8b 45 08             	mov    0x8(%ebp),%eax
801028bc:	8b 40 08             	mov    0x8(%eax),%eax
801028bf:	c1 e8 10             	shr    $0x10,%eax
801028c2:	0f b6 c0             	movzbl %al,%eax
801028c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801028c9:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801028d0:	e8 36 fe ff ff       	call   8010270b <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801028d5:	8b 45 08             	mov    0x8(%ebp),%eax
801028d8:	8b 40 04             	mov    0x4(%eax),%eax
801028db:	83 e0 01             	and    $0x1,%eax
801028de:	89 c2                	mov    %eax,%edx
801028e0:	c1 e2 04             	shl    $0x4,%edx
801028e3:	8b 45 08             	mov    0x8(%ebp),%eax
801028e6:	8b 40 08             	mov    0x8(%eax),%eax
801028e9:	c1 e8 18             	shr    $0x18,%eax
801028ec:	83 e0 0f             	and    $0xf,%eax
801028ef:	09 d0                	or     %edx,%eax
801028f1:	83 c8 e0             	or     $0xffffffe0,%eax
801028f4:	0f b6 c0             	movzbl %al,%eax
801028f7:	89 44 24 04          	mov    %eax,0x4(%esp)
801028fb:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102902:	e8 04 fe ff ff       	call   8010270b <outb>
  if(b->flags & B_DIRTY){
80102907:	8b 45 08             	mov    0x8(%ebp),%eax
8010290a:	8b 00                	mov    (%eax),%eax
8010290c:	83 e0 04             	and    $0x4,%eax
8010290f:	85 c0                	test   %eax,%eax
80102911:	74 34                	je     80102947 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80102913:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
8010291a:	00 
8010291b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102922:	e8 e4 fd ff ff       	call   8010270b <outb>
    outsl(0x1f0, b->data, 512/4);
80102927:	8b 45 08             	mov    0x8(%ebp),%eax
8010292a:	83 c0 18             	add    $0x18,%eax
8010292d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102934:	00 
80102935:	89 44 24 04          	mov    %eax,0x4(%esp)
80102939:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102940:	e8 e4 fd ff ff       	call   80102729 <outsl>
80102945:	eb 14                	jmp    8010295b <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102947:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010294e:	00 
8010294f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102956:	e8 b0 fd ff ff       	call   8010270b <outb>
  }
}
8010295b:	c9                   	leave  
8010295c:	c3                   	ret    

8010295d <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
8010295d:	55                   	push   %ebp
8010295e:	89 e5                	mov    %esp,%ebp
80102960:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102963:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
8010296a:	e8 a0 24 00 00       	call   80104e0f <acquire>
  if((b = idequeue) == 0){
8010296f:	a1 54 b6 10 80       	mov    0x8010b654,%eax
80102974:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102977:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010297b:	75 11                	jne    8010298e <ideintr+0x31>
    release(&idelock);
8010297d:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
80102984:	e8 e8 24 00 00       	call   80104e71 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102989:	e9 90 00 00 00       	jmp    80102a1e <ideintr+0xc1>
  }
  idequeue = b->qnext;
8010298e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102991:	8b 40 14             	mov    0x14(%eax),%eax
80102994:	a3 54 b6 10 80       	mov    %eax,0x8010b654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102999:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010299c:	8b 00                	mov    (%eax),%eax
8010299e:	83 e0 04             	and    $0x4,%eax
801029a1:	85 c0                	test   %eax,%eax
801029a3:	75 2e                	jne    801029d3 <ideintr+0x76>
801029a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801029ac:	e8 9d fd ff ff       	call   8010274e <idewait>
801029b1:	85 c0                	test   %eax,%eax
801029b3:	78 1e                	js     801029d3 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
801029b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029b8:	83 c0 18             	add    $0x18,%eax
801029bb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801029c2:	00 
801029c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801029c7:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801029ce:	e8 13 fd ff ff       	call   801026e6 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801029d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029d6:	8b 00                	mov    (%eax),%eax
801029d8:	89 c2                	mov    %eax,%edx
801029da:	83 ca 02             	or     $0x2,%edx
801029dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e0:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801029e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e5:	8b 00                	mov    (%eax),%eax
801029e7:	89 c2                	mov    %eax,%edx
801029e9:	83 e2 fb             	and    $0xfffffffb,%edx
801029ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ef:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801029f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f4:	89 04 24             	mov    %eax,(%esp)
801029f7:	e8 0e 22 00 00       	call   80104c0a <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801029fc:	a1 54 b6 10 80       	mov    0x8010b654,%eax
80102a01:	85 c0                	test   %eax,%eax
80102a03:	74 0d                	je     80102a12 <ideintr+0xb5>
    idestart(idequeue);
80102a05:	a1 54 b6 10 80       	mov    0x8010b654,%eax
80102a0a:	89 04 24             	mov    %eax,(%esp)
80102a0d:	e8 26 fe ff ff       	call   80102838 <idestart>

  release(&idelock);
80102a12:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
80102a19:	e8 53 24 00 00       	call   80104e71 <release>
}
80102a1e:	c9                   	leave  
80102a1f:	c3                   	ret    

80102a20 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102a20:	55                   	push   %ebp
80102a21:	89 e5                	mov    %esp,%ebp
80102a23:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102a26:	8b 45 08             	mov    0x8(%ebp),%eax
80102a29:	8b 00                	mov    (%eax),%eax
80102a2b:	83 e0 01             	and    $0x1,%eax
80102a2e:	85 c0                	test   %eax,%eax
80102a30:	75 0c                	jne    80102a3e <iderw+0x1e>
    panic("iderw: buf not busy");
80102a32:	c7 04 24 89 87 10 80 	movl   $0x80108789,(%esp)
80102a39:	e8 ff da ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102a3e:	8b 45 08             	mov    0x8(%ebp),%eax
80102a41:	8b 00                	mov    (%eax),%eax
80102a43:	83 e0 06             	and    $0x6,%eax
80102a46:	83 f8 02             	cmp    $0x2,%eax
80102a49:	75 0c                	jne    80102a57 <iderw+0x37>
    panic("iderw: nothing to do");
80102a4b:	c7 04 24 9d 87 10 80 	movl   $0x8010879d,(%esp)
80102a52:	e8 e6 da ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80102a57:	8b 45 08             	mov    0x8(%ebp),%eax
80102a5a:	8b 40 04             	mov    0x4(%eax),%eax
80102a5d:	85 c0                	test   %eax,%eax
80102a5f:	74 15                	je     80102a76 <iderw+0x56>
80102a61:	a1 58 b6 10 80       	mov    0x8010b658,%eax
80102a66:	85 c0                	test   %eax,%eax
80102a68:	75 0c                	jne    80102a76 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102a6a:	c7 04 24 b2 87 10 80 	movl   $0x801087b2,(%esp)
80102a71:	e8 c7 da ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102a76:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
80102a7d:	e8 8d 23 00 00       	call   80104e0f <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102a82:	8b 45 08             	mov    0x8(%ebp),%eax
80102a85:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102a8c:	c7 45 f4 54 b6 10 80 	movl   $0x8010b654,-0xc(%ebp)
80102a93:	eb 0b                	jmp    80102aa0 <iderw+0x80>
80102a95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a98:	8b 00                	mov    (%eax),%eax
80102a9a:	83 c0 14             	add    $0x14,%eax
80102a9d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aa3:	8b 00                	mov    (%eax),%eax
80102aa5:	85 c0                	test   %eax,%eax
80102aa7:	75 ec                	jne    80102a95 <iderw+0x75>
    ;
  *pp = b;
80102aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aac:	8b 55 08             	mov    0x8(%ebp),%edx
80102aaf:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102ab1:	a1 54 b6 10 80       	mov    0x8010b654,%eax
80102ab6:	3b 45 08             	cmp    0x8(%ebp),%eax
80102ab9:	75 22                	jne    80102add <iderw+0xbd>
    idestart(b);
80102abb:	8b 45 08             	mov    0x8(%ebp),%eax
80102abe:	89 04 24             	mov    %eax,(%esp)
80102ac1:	e8 72 fd ff ff       	call   80102838 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ac6:	eb 15                	jmp    80102add <iderw+0xbd>
    sleep(b, &idelock);
80102ac8:	c7 44 24 04 20 b6 10 	movl   $0x8010b620,0x4(%esp)
80102acf:	80 
80102ad0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad3:	89 04 24             	mov    %eax,(%esp)
80102ad6:	e8 56 20 00 00       	call   80104b31 <sleep>
80102adb:	eb 01                	jmp    80102ade <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102add:	90                   	nop
80102ade:	8b 45 08             	mov    0x8(%ebp),%eax
80102ae1:	8b 00                	mov    (%eax),%eax
80102ae3:	83 e0 06             	and    $0x6,%eax
80102ae6:	83 f8 02             	cmp    $0x2,%eax
80102ae9:	75 dd                	jne    80102ac8 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102aeb:	c7 04 24 20 b6 10 80 	movl   $0x8010b620,(%esp)
80102af2:	e8 7a 23 00 00       	call   80104e71 <release>
}
80102af7:	c9                   	leave  
80102af8:	c3                   	ret    
80102af9:	00 00                	add    %al,(%eax)
	...

80102afc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102afc:	55                   	push   %ebp
80102afd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102aff:	a1 54 f8 10 80       	mov    0x8010f854,%eax
80102b04:	8b 55 08             	mov    0x8(%ebp),%edx
80102b07:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102b09:	a1 54 f8 10 80       	mov    0x8010f854,%eax
80102b0e:	8b 40 10             	mov    0x10(%eax),%eax
}
80102b11:	5d                   	pop    %ebp
80102b12:	c3                   	ret    

80102b13 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102b13:	55                   	push   %ebp
80102b14:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102b16:	a1 54 f8 10 80       	mov    0x8010f854,%eax
80102b1b:	8b 55 08             	mov    0x8(%ebp),%edx
80102b1e:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102b20:	a1 54 f8 10 80       	mov    0x8010f854,%eax
80102b25:	8b 55 0c             	mov    0xc(%ebp),%edx
80102b28:	89 50 10             	mov    %edx,0x10(%eax)
}
80102b2b:	5d                   	pop    %ebp
80102b2c:	c3                   	ret    

80102b2d <ioapicinit>:

void
ioapicinit(void)
{
80102b2d:	55                   	push   %ebp
80102b2e:	89 e5                	mov    %esp,%ebp
80102b30:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102b33:	a1 24 f9 10 80       	mov    0x8010f924,%eax
80102b38:	85 c0                	test   %eax,%eax
80102b3a:	0f 84 9f 00 00 00    	je     80102bdf <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102b40:	c7 05 54 f8 10 80 00 	movl   $0xfec00000,0x8010f854
80102b47:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102b4a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102b51:	e8 a6 ff ff ff       	call   80102afc <ioapicread>
80102b56:	c1 e8 10             	shr    $0x10,%eax
80102b59:	25 ff 00 00 00       	and    $0xff,%eax
80102b5e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102b61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102b68:	e8 8f ff ff ff       	call   80102afc <ioapicread>
80102b6d:	c1 e8 18             	shr    $0x18,%eax
80102b70:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102b73:	0f b6 05 20 f9 10 80 	movzbl 0x8010f920,%eax
80102b7a:	0f b6 c0             	movzbl %al,%eax
80102b7d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102b80:	74 0c                	je     80102b8e <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102b82:	c7 04 24 d0 87 10 80 	movl   $0x801087d0,(%esp)
80102b89:	e8 13 d8 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b8e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102b95:	eb 3e                	jmp    80102bd5 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b9a:	83 c0 20             	add    $0x20,%eax
80102b9d:	0d 00 00 01 00       	or     $0x10000,%eax
80102ba2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102ba5:	83 c2 08             	add    $0x8,%edx
80102ba8:	01 d2                	add    %edx,%edx
80102baa:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bae:	89 14 24             	mov    %edx,(%esp)
80102bb1:	e8 5d ff ff ff       	call   80102b13 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102bb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bb9:	83 c0 08             	add    $0x8,%eax
80102bbc:	01 c0                	add    %eax,%eax
80102bbe:	83 c0 01             	add    $0x1,%eax
80102bc1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102bc8:	00 
80102bc9:	89 04 24             	mov    %eax,(%esp)
80102bcc:	e8 42 ff ff ff       	call   80102b13 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102bd1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102bd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bd8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102bdb:	7e ba                	jle    80102b97 <ioapicinit+0x6a>
80102bdd:	eb 01                	jmp    80102be0 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102bdf:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102be0:	c9                   	leave  
80102be1:	c3                   	ret    

80102be2 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102be2:	55                   	push   %ebp
80102be3:	89 e5                	mov    %esp,%ebp
80102be5:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102be8:	a1 24 f9 10 80       	mov    0x8010f924,%eax
80102bed:	85 c0                	test   %eax,%eax
80102bef:	74 39                	je     80102c2a <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102bf1:	8b 45 08             	mov    0x8(%ebp),%eax
80102bf4:	83 c0 20             	add    $0x20,%eax
80102bf7:	8b 55 08             	mov    0x8(%ebp),%edx
80102bfa:	83 c2 08             	add    $0x8,%edx
80102bfd:	01 d2                	add    %edx,%edx
80102bff:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c03:	89 14 24             	mov    %edx,(%esp)
80102c06:	e8 08 ff ff ff       	call   80102b13 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102c0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c0e:	c1 e0 18             	shl    $0x18,%eax
80102c11:	8b 55 08             	mov    0x8(%ebp),%edx
80102c14:	83 c2 08             	add    $0x8,%edx
80102c17:	01 d2                	add    %edx,%edx
80102c19:	83 c2 01             	add    $0x1,%edx
80102c1c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c20:	89 14 24             	mov    %edx,(%esp)
80102c23:	e8 eb fe ff ff       	call   80102b13 <ioapicwrite>
80102c28:	eb 01                	jmp    80102c2b <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102c2a:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102c2b:	c9                   	leave  
80102c2c:	c3                   	ret    
80102c2d:	00 00                	add    %al,(%eax)
	...

80102c30 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102c30:	55                   	push   %ebp
80102c31:	89 e5                	mov    %esp,%ebp
80102c33:	8b 45 08             	mov    0x8(%ebp),%eax
80102c36:	05 00 00 00 80       	add    $0x80000000,%eax
80102c3b:	5d                   	pop    %ebp
80102c3c:	c3                   	ret    

80102c3d <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102c3d:	55                   	push   %ebp
80102c3e:	89 e5                	mov    %esp,%ebp
80102c40:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102c43:	c7 44 24 04 02 88 10 	movl   $0x80108802,0x4(%esp)
80102c4a:	80 
80102c4b:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80102c52:	e8 97 21 00 00       	call   80104dee <initlock>
  kmem.use_lock = 0;
80102c57:	c7 05 94 f8 10 80 00 	movl   $0x0,0x8010f894
80102c5e:	00 00 00 
  freerange(vstart, vend);
80102c61:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c64:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c68:	8b 45 08             	mov    0x8(%ebp),%eax
80102c6b:	89 04 24             	mov    %eax,(%esp)
80102c6e:	e8 26 00 00 00       	call   80102c99 <freerange>
}
80102c73:	c9                   	leave  
80102c74:	c3                   	ret    

80102c75 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102c75:	55                   	push   %ebp
80102c76:	89 e5                	mov    %esp,%ebp
80102c78:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102c7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c82:	8b 45 08             	mov    0x8(%ebp),%eax
80102c85:	89 04 24             	mov    %eax,(%esp)
80102c88:	e8 0c 00 00 00       	call   80102c99 <freerange>
  kmem.use_lock = 1;
80102c8d:	c7 05 94 f8 10 80 01 	movl   $0x1,0x8010f894
80102c94:	00 00 00 
}
80102c97:	c9                   	leave  
80102c98:	c3                   	ret    

80102c99 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102c99:	55                   	push   %ebp
80102c9a:	89 e5                	mov    %esp,%ebp
80102c9c:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80102ca2:	05 ff 0f 00 00       	add    $0xfff,%eax
80102ca7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102cac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102caf:	eb 12                	jmp    80102cc3 <freerange+0x2a>
    kfree(p);
80102cb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cb4:	89 04 24             	mov    %eax,(%esp)
80102cb7:	e8 16 00 00 00       	call   80102cd2 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102cbc:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cc6:	05 00 10 00 00       	add    $0x1000,%eax
80102ccb:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102cce:	76 e1                	jbe    80102cb1 <freerange+0x18>
    kfree(p);
}
80102cd0:	c9                   	leave  
80102cd1:	c3                   	ret    

80102cd2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102cd2:	55                   	push   %ebp
80102cd3:	89 e5                	mov    %esp,%ebp
80102cd5:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102cd8:	8b 45 08             	mov    0x8(%ebp),%eax
80102cdb:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ce0:	85 c0                	test   %eax,%eax
80102ce2:	75 1b                	jne    80102cff <kfree+0x2d>
80102ce4:	81 7d 08 1c 27 11 80 	cmpl   $0x8011271c,0x8(%ebp)
80102ceb:	72 12                	jb     80102cff <kfree+0x2d>
80102ced:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf0:	89 04 24             	mov    %eax,(%esp)
80102cf3:	e8 38 ff ff ff       	call   80102c30 <v2p>
80102cf8:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102cfd:	76 0c                	jbe    80102d0b <kfree+0x39>
    panic("kfree");
80102cff:	c7 04 24 07 88 10 80 	movl   $0x80108807,(%esp)
80102d06:	e8 32 d8 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102d0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102d12:	00 
80102d13:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102d1a:	00 
80102d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d1e:	89 04 24             	mov    %eax,(%esp)
80102d21:	e8 38 23 00 00       	call   8010505e <memset>

  if(kmem.use_lock)
80102d26:	a1 94 f8 10 80       	mov    0x8010f894,%eax
80102d2b:	85 c0                	test   %eax,%eax
80102d2d:	74 0c                	je     80102d3b <kfree+0x69>
    acquire(&kmem.lock);
80102d2f:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80102d36:	e8 d4 20 00 00       	call   80104e0f <acquire>
  r = (struct run*)v;
80102d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80102d3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102d41:	8b 15 98 f8 10 80    	mov    0x8010f898,%edx
80102d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d4a:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d4f:	a3 98 f8 10 80       	mov    %eax,0x8010f898
  if(kmem.use_lock)
80102d54:	a1 94 f8 10 80       	mov    0x8010f894,%eax
80102d59:	85 c0                	test   %eax,%eax
80102d5b:	74 0c                	je     80102d69 <kfree+0x97>
    release(&kmem.lock);
80102d5d:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80102d64:	e8 08 21 00 00       	call   80104e71 <release>
}
80102d69:	c9                   	leave  
80102d6a:	c3                   	ret    

80102d6b <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102d6b:	55                   	push   %ebp
80102d6c:	89 e5                	mov    %esp,%ebp
80102d6e:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102d71:	a1 94 f8 10 80       	mov    0x8010f894,%eax
80102d76:	85 c0                	test   %eax,%eax
80102d78:	74 0c                	je     80102d86 <kalloc+0x1b>
    acquire(&kmem.lock);
80102d7a:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80102d81:	e8 89 20 00 00       	call   80104e0f <acquire>
  r = kmem.freelist;
80102d86:	a1 98 f8 10 80       	mov    0x8010f898,%eax
80102d8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102d8e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d92:	74 0a                	je     80102d9e <kalloc+0x33>
    kmem.freelist = r->next;
80102d94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d97:	8b 00                	mov    (%eax),%eax
80102d99:	a3 98 f8 10 80       	mov    %eax,0x8010f898
  if(kmem.use_lock)
80102d9e:	a1 94 f8 10 80       	mov    0x8010f894,%eax
80102da3:	85 c0                	test   %eax,%eax
80102da5:	74 0c                	je     80102db3 <kalloc+0x48>
    release(&kmem.lock);
80102da7:	c7 04 24 60 f8 10 80 	movl   $0x8010f860,(%esp)
80102dae:	e8 be 20 00 00       	call   80104e71 <release>
  return (char*)r;
80102db3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102db6:	c9                   	leave  
80102db7:	c3                   	ret    

80102db8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102db8:	55                   	push   %ebp
80102db9:	89 e5                	mov    %esp,%ebp
80102dbb:	53                   	push   %ebx
80102dbc:	83 ec 14             	sub    $0x14,%esp
80102dbf:	8b 45 08             	mov    0x8(%ebp),%eax
80102dc2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dc6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102dca:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102dce:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102dd2:	ec                   	in     (%dx),%al
80102dd3:	89 c3                	mov    %eax,%ebx
80102dd5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102dd8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102ddc:	83 c4 14             	add    $0x14,%esp
80102ddf:	5b                   	pop    %ebx
80102de0:	5d                   	pop    %ebp
80102de1:	c3                   	ret    

80102de2 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102de2:	55                   	push   %ebp
80102de3:	89 e5                	mov    %esp,%ebp
80102de5:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102de8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102def:	e8 c4 ff ff ff       	call   80102db8 <inb>
80102df4:	0f b6 c0             	movzbl %al,%eax
80102df7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102dfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dfd:	83 e0 01             	and    $0x1,%eax
80102e00:	85 c0                	test   %eax,%eax
80102e02:	75 0a                	jne    80102e0e <kbdgetc+0x2c>
    return -1;
80102e04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e09:	e9 23 01 00 00       	jmp    80102f31 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102e0e:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102e15:	e8 9e ff ff ff       	call   80102db8 <inb>
80102e1a:	0f b6 c0             	movzbl %al,%eax
80102e1d:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102e20:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102e27:	75 17                	jne    80102e40 <kbdgetc+0x5e>
    shift |= E0ESC;
80102e29:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102e2e:	83 c8 40             	or     $0x40,%eax
80102e31:	a3 5c b6 10 80       	mov    %eax,0x8010b65c
    return 0;
80102e36:	b8 00 00 00 00       	mov    $0x0,%eax
80102e3b:	e9 f1 00 00 00       	jmp    80102f31 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102e40:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e43:	25 80 00 00 00       	and    $0x80,%eax
80102e48:	85 c0                	test   %eax,%eax
80102e4a:	74 45                	je     80102e91 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102e4c:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102e51:	83 e0 40             	and    $0x40,%eax
80102e54:	85 c0                	test   %eax,%eax
80102e56:	75 08                	jne    80102e60 <kbdgetc+0x7e>
80102e58:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e5b:	83 e0 7f             	and    $0x7f,%eax
80102e5e:	eb 03                	jmp    80102e63 <kbdgetc+0x81>
80102e60:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e63:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102e66:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e69:	05 20 90 10 80       	add    $0x80109020,%eax
80102e6e:	0f b6 00             	movzbl (%eax),%eax
80102e71:	83 c8 40             	or     $0x40,%eax
80102e74:	0f b6 c0             	movzbl %al,%eax
80102e77:	f7 d0                	not    %eax
80102e79:	89 c2                	mov    %eax,%edx
80102e7b:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102e80:	21 d0                	and    %edx,%eax
80102e82:	a3 5c b6 10 80       	mov    %eax,0x8010b65c
    return 0;
80102e87:	b8 00 00 00 00       	mov    $0x0,%eax
80102e8c:	e9 a0 00 00 00       	jmp    80102f31 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102e91:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102e96:	83 e0 40             	and    $0x40,%eax
80102e99:	85 c0                	test   %eax,%eax
80102e9b:	74 14                	je     80102eb1 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102e9d:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102ea4:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102ea9:	83 e0 bf             	and    $0xffffffbf,%eax
80102eac:	a3 5c b6 10 80       	mov    %eax,0x8010b65c
  }

  shift |= shiftcode[data];
80102eb1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102eb4:	05 20 90 10 80       	add    $0x80109020,%eax
80102eb9:	0f b6 00             	movzbl (%eax),%eax
80102ebc:	0f b6 d0             	movzbl %al,%edx
80102ebf:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102ec4:	09 d0                	or     %edx,%eax
80102ec6:	a3 5c b6 10 80       	mov    %eax,0x8010b65c
  shift ^= togglecode[data];
80102ecb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ece:	05 20 91 10 80       	add    $0x80109120,%eax
80102ed3:	0f b6 00             	movzbl (%eax),%eax
80102ed6:	0f b6 d0             	movzbl %al,%edx
80102ed9:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102ede:	31 d0                	xor    %edx,%eax
80102ee0:	a3 5c b6 10 80       	mov    %eax,0x8010b65c
  c = charcode[shift & (CTL | SHIFT)][data];
80102ee5:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102eea:	83 e0 03             	and    $0x3,%eax
80102eed:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102ef4:	03 45 fc             	add    -0x4(%ebp),%eax
80102ef7:	0f b6 00             	movzbl (%eax),%eax
80102efa:	0f b6 c0             	movzbl %al,%eax
80102efd:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102f00:	a1 5c b6 10 80       	mov    0x8010b65c,%eax
80102f05:	83 e0 08             	and    $0x8,%eax
80102f08:	85 c0                	test   %eax,%eax
80102f0a:	74 22                	je     80102f2e <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102f0c:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102f10:	76 0c                	jbe    80102f1e <kbdgetc+0x13c>
80102f12:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102f16:	77 06                	ja     80102f1e <kbdgetc+0x13c>
      c += 'A' - 'a';
80102f18:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102f1c:	eb 10                	jmp    80102f2e <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102f1e:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102f22:	76 0a                	jbe    80102f2e <kbdgetc+0x14c>
80102f24:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102f28:	77 04                	ja     80102f2e <kbdgetc+0x14c>
      c += 'a' - 'A';
80102f2a:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102f2e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102f31:	c9                   	leave  
80102f32:	c3                   	ret    

80102f33 <kbdintr>:

void
kbdintr(void)
{
80102f33:	55                   	push   %ebp
80102f34:	89 e5                	mov    %esp,%ebp
80102f36:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102f39:	c7 04 24 e2 2d 10 80 	movl   $0x80102de2,(%esp)
80102f40:	e8 68 d8 ff ff       	call   801007ad <consoleintr>
}
80102f45:	c9                   	leave  
80102f46:	c3                   	ret    
	...

80102f48 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102f48:	55                   	push   %ebp
80102f49:	89 e5                	mov    %esp,%ebp
80102f4b:	83 ec 08             	sub    $0x8,%esp
80102f4e:	8b 55 08             	mov    0x8(%ebp),%edx
80102f51:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f54:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102f58:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f5b:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102f5f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102f63:	ee                   	out    %al,(%dx)
}
80102f64:	c9                   	leave  
80102f65:	c3                   	ret    

80102f66 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102f66:	55                   	push   %ebp
80102f67:	89 e5                	mov    %esp,%ebp
80102f69:	53                   	push   %ebx
80102f6a:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102f6d:	9c                   	pushf  
80102f6e:	5b                   	pop    %ebx
80102f6f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102f72:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102f75:	83 c4 10             	add    $0x10,%esp
80102f78:	5b                   	pop    %ebx
80102f79:	5d                   	pop    %ebp
80102f7a:	c3                   	ret    

80102f7b <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102f7b:	55                   	push   %ebp
80102f7c:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102f7e:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
80102f83:	8b 55 08             	mov    0x8(%ebp),%edx
80102f86:	c1 e2 02             	shl    $0x2,%edx
80102f89:	01 c2                	add    %eax,%edx
80102f8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f8e:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102f90:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
80102f95:	83 c0 20             	add    $0x20,%eax
80102f98:	8b 00                	mov    (%eax),%eax
}
80102f9a:	5d                   	pop    %ebp
80102f9b:	c3                   	ret    

80102f9c <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102f9c:	55                   	push   %ebp
80102f9d:	89 e5                	mov    %esp,%ebp
80102f9f:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102fa2:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
80102fa7:	85 c0                	test   %eax,%eax
80102fa9:	0f 84 47 01 00 00    	je     801030f6 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102faf:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102fb6:	00 
80102fb7:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102fbe:	e8 b8 ff ff ff       	call   80102f7b <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102fc3:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102fca:	00 
80102fcb:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102fd2:	e8 a4 ff ff ff       	call   80102f7b <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102fd7:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102fde:	00 
80102fdf:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fe6:	e8 90 ff ff ff       	call   80102f7b <lapicw>
  lapicw(TICR, 10000000); 
80102feb:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102ff2:	00 
80102ff3:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102ffa:	e8 7c ff ff ff       	call   80102f7b <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102fff:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103006:	00 
80103007:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010300e:	e8 68 ff ff ff       	call   80102f7b <lapicw>
  lapicw(LINT1, MASKED);
80103013:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010301a:	00 
8010301b:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80103022:	e8 54 ff ff ff       	call   80102f7b <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103027:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
8010302c:	83 c0 30             	add    $0x30,%eax
8010302f:	8b 00                	mov    (%eax),%eax
80103031:	c1 e8 10             	shr    $0x10,%eax
80103034:	25 ff 00 00 00       	and    $0xff,%eax
80103039:	83 f8 03             	cmp    $0x3,%eax
8010303c:	76 14                	jbe    80103052 <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010303e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103045:	00 
80103046:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
8010304d:	e8 29 ff ff ff       	call   80102f7b <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80103052:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103059:	00 
8010305a:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80103061:	e8 15 ff ff ff       	call   80102f7b <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103066:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010306d:	00 
8010306e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103075:	e8 01 ff ff ff       	call   80102f7b <lapicw>
  lapicw(ESR, 0);
8010307a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103081:	00 
80103082:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103089:	e8 ed fe ff ff       	call   80102f7b <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010308e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103095:	00 
80103096:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010309d:	e8 d9 fe ff ff       	call   80102f7b <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801030a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030a9:	00 
801030aa:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801030b1:	e8 c5 fe ff ff       	call   80102f7b <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801030b6:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801030bd:	00 
801030be:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030c5:	e8 b1 fe ff ff       	call   80102f7b <lapicw>
  while(lapic[ICRLO] & DELIVS)
801030ca:	90                   	nop
801030cb:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
801030d0:	05 00 03 00 00       	add    $0x300,%eax
801030d5:	8b 00                	mov    (%eax),%eax
801030d7:	25 00 10 00 00       	and    $0x1000,%eax
801030dc:	85 c0                	test   %eax,%eax
801030de:	75 eb                	jne    801030cb <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801030e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030e7:	00 
801030e8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801030ef:	e8 87 fe ff ff       	call   80102f7b <lapicw>
801030f4:	eb 01                	jmp    801030f7 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
801030f6:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
801030f7:	c9                   	leave  
801030f8:	c3                   	ret    

801030f9 <cpunum>:

int
cpunum(void)
{
801030f9:	55                   	push   %ebp
801030fa:	89 e5                	mov    %esp,%ebp
801030fc:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
801030ff:	e8 62 fe ff ff       	call   80102f66 <readeflags>
80103104:	25 00 02 00 00       	and    $0x200,%eax
80103109:	85 c0                	test   %eax,%eax
8010310b:	74 29                	je     80103136 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
8010310d:	a1 60 b6 10 80       	mov    0x8010b660,%eax
80103112:	85 c0                	test   %eax,%eax
80103114:	0f 94 c2             	sete   %dl
80103117:	83 c0 01             	add    $0x1,%eax
8010311a:	a3 60 b6 10 80       	mov    %eax,0x8010b660
8010311f:	84 d2                	test   %dl,%dl
80103121:	74 13                	je     80103136 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80103123:	8b 45 04             	mov    0x4(%ebp),%eax
80103126:	89 44 24 04          	mov    %eax,0x4(%esp)
8010312a:	c7 04 24 10 88 10 80 	movl   $0x80108810,(%esp)
80103131:	e8 6b d2 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103136:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
8010313b:	85 c0                	test   %eax,%eax
8010313d:	74 0f                	je     8010314e <cpunum+0x55>
    return lapic[ID]>>24;
8010313f:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
80103144:	83 c0 20             	add    $0x20,%eax
80103147:	8b 00                	mov    (%eax),%eax
80103149:	c1 e8 18             	shr    $0x18,%eax
8010314c:	eb 05                	jmp    80103153 <cpunum+0x5a>
  return 0;
8010314e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103153:	c9                   	leave  
80103154:	c3                   	ret    

80103155 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103155:	55                   	push   %ebp
80103156:	89 e5                	mov    %esp,%ebp
80103158:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
8010315b:	a1 9c f8 10 80       	mov    0x8010f89c,%eax
80103160:	85 c0                	test   %eax,%eax
80103162:	74 14                	je     80103178 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103164:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010316b:	00 
8010316c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80103173:	e8 03 fe ff ff       	call   80102f7b <lapicw>
}
80103178:	c9                   	leave  
80103179:	c3                   	ret    

8010317a <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
8010317a:	55                   	push   %ebp
8010317b:	89 e5                	mov    %esp,%ebp
}
8010317d:	5d                   	pop    %ebp
8010317e:	c3                   	ret    

8010317f <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010317f:	55                   	push   %ebp
80103180:	89 e5                	mov    %esp,%ebp
80103182:	83 ec 1c             	sub    $0x1c,%esp
80103185:	8b 45 08             	mov    0x8(%ebp),%eax
80103188:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
8010318b:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80103192:	00 
80103193:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
8010319a:	e8 a9 fd ff ff       	call   80102f48 <outb>
  outb(IO_RTC+1, 0x0A);
8010319f:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801031a6:	00 
801031a7:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801031ae:	e8 95 fd ff ff       	call   80102f48 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801031b3:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801031ba:	8b 45 f8             	mov    -0x8(%ebp),%eax
801031bd:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801031c2:	8b 45 f8             	mov    -0x8(%ebp),%eax
801031c5:	8d 50 02             	lea    0x2(%eax),%edx
801031c8:	8b 45 0c             	mov    0xc(%ebp),%eax
801031cb:	c1 e8 04             	shr    $0x4,%eax
801031ce:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801031d1:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801031d5:	c1 e0 18             	shl    $0x18,%eax
801031d8:	89 44 24 04          	mov    %eax,0x4(%esp)
801031dc:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801031e3:	e8 93 fd ff ff       	call   80102f7b <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801031e8:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801031ef:	00 
801031f0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031f7:	e8 7f fd ff ff       	call   80102f7b <lapicw>
  microdelay(200);
801031fc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103203:	e8 72 ff ff ff       	call   8010317a <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103208:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010320f:	00 
80103210:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103217:	e8 5f fd ff ff       	call   80102f7b <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010321c:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103223:	e8 52 ff ff ff       	call   8010317a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103228:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010322f:	eb 40                	jmp    80103271 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103231:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103235:	c1 e0 18             	shl    $0x18,%eax
80103238:	89 44 24 04          	mov    %eax,0x4(%esp)
8010323c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103243:	e8 33 fd ff ff       	call   80102f7b <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103248:	8b 45 0c             	mov    0xc(%ebp),%eax
8010324b:	c1 e8 0c             	shr    $0xc,%eax
8010324e:	80 cc 06             	or     $0x6,%ah
80103251:	89 44 24 04          	mov    %eax,0x4(%esp)
80103255:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010325c:	e8 1a fd ff ff       	call   80102f7b <lapicw>
    microdelay(200);
80103261:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103268:	e8 0d ff ff ff       	call   8010317a <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010326d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103271:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103275:	7e ba                	jle    80103231 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103277:	c9                   	leave  
80103278:	c3                   	ret    
80103279:	00 00                	add    %al,(%eax)
	...

8010327c <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
8010327c:	55                   	push   %ebp
8010327d:	89 e5                	mov    %esp,%ebp
8010327f:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
80103282:	c7 44 24 04 3c 88 10 	movl   $0x8010883c,0x4(%esp)
80103289:	80 
8010328a:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80103291:	e8 58 1b 00 00       	call   80104dee <initlock>
  readsb(ROOTDEV, &sb);
80103296:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103299:	89 44 24 04          	mov    %eax,0x4(%esp)
8010329d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032a4:	e8 af e2 ff ff       	call   80101558 <readsb>
  log.start = sb.size - sb.nlog;
801032a9:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032af:	89 d1                	mov    %edx,%ecx
801032b1:	29 c1                	sub    %eax,%ecx
801032b3:	89 c8                	mov    %ecx,%eax
801032b5:	a3 d4 f8 10 80       	mov    %eax,0x8010f8d4
  log.size = sb.nlog;
801032ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032bd:	a3 d8 f8 10 80       	mov    %eax,0x8010f8d8
  log.dev = ROOTDEV;
801032c2:	c7 05 e0 f8 10 80 01 	movl   $0x1,0x8010f8e0
801032c9:	00 00 00 
  recover_from_log();
801032cc:	e8 97 01 00 00       	call   80103468 <recover_from_log>
}
801032d1:	c9                   	leave  
801032d2:	c3                   	ret    

801032d3 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801032d3:	55                   	push   %ebp
801032d4:	89 e5                	mov    %esp,%ebp
801032d6:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801032d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801032e0:	e9 89 00 00 00       	jmp    8010336e <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032e5:	a1 d4 f8 10 80       	mov    0x8010f8d4,%eax
801032ea:	03 45 f4             	add    -0xc(%ebp),%eax
801032ed:	83 c0 01             	add    $0x1,%eax
801032f0:	89 c2                	mov    %eax,%edx
801032f2:	a1 e0 f8 10 80       	mov    0x8010f8e0,%eax
801032f7:	89 54 24 04          	mov    %edx,0x4(%esp)
801032fb:	89 04 24             	mov    %eax,(%esp)
801032fe:	e8 a3 ce ff ff       	call   801001a6 <bread>
80103303:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103306:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103309:	83 c0 10             	add    $0x10,%eax
8010330c:	8b 04 85 a8 f8 10 80 	mov    -0x7fef0758(,%eax,4),%eax
80103313:	89 c2                	mov    %eax,%edx
80103315:	a1 e0 f8 10 80       	mov    0x8010f8e0,%eax
8010331a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010331e:	89 04 24             	mov    %eax,(%esp)
80103321:	e8 80 ce ff ff       	call   801001a6 <bread>
80103326:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103329:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010332c:	8d 50 18             	lea    0x18(%eax),%edx
8010332f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103332:	83 c0 18             	add    $0x18,%eax
80103335:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010333c:	00 
8010333d:	89 54 24 04          	mov    %edx,0x4(%esp)
80103341:	89 04 24             	mov    %eax,(%esp)
80103344:	e8 e8 1d 00 00       	call   80105131 <memmove>
    bwrite(dbuf);  // write dst to disk
80103349:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010334c:	89 04 24             	mov    %eax,(%esp)
8010334f:	e8 89 ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103354:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103357:	89 04 24             	mov    %eax,(%esp)
8010335a:	e8 b8 ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010335f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103362:	89 04 24             	mov    %eax,(%esp)
80103365:	e8 ad ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010336a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010336e:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
80103373:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103376:	0f 8f 69 ff ff ff    	jg     801032e5 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010337c:	c9                   	leave  
8010337d:	c3                   	ret    

8010337e <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010337e:	55                   	push   %ebp
8010337f:	89 e5                	mov    %esp,%ebp
80103381:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103384:	a1 d4 f8 10 80       	mov    0x8010f8d4,%eax
80103389:	89 c2                	mov    %eax,%edx
8010338b:	a1 e0 f8 10 80       	mov    0x8010f8e0,%eax
80103390:	89 54 24 04          	mov    %edx,0x4(%esp)
80103394:	89 04 24             	mov    %eax,(%esp)
80103397:	e8 0a ce ff ff       	call   801001a6 <bread>
8010339c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010339f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033a2:	83 c0 18             	add    $0x18,%eax
801033a5:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801033a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033ab:	8b 00                	mov    (%eax),%eax
801033ad:	a3 e4 f8 10 80       	mov    %eax,0x8010f8e4
  for (i = 0; i < log.lh.n; i++) {
801033b2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033b9:	eb 1b                	jmp    801033d6 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801033bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c1:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801033c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033c8:	83 c2 10             	add    $0x10,%edx
801033cb:	89 04 95 a8 f8 10 80 	mov    %eax,-0x7fef0758(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801033d2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033d6:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
801033db:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033de:	7f db                	jg     801033bb <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801033e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e3:	89 04 24             	mov    %eax,(%esp)
801033e6:	e8 2c ce ff ff       	call   80100217 <brelse>
}
801033eb:	c9                   	leave  
801033ec:	c3                   	ret    

801033ed <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033ed:	55                   	push   %ebp
801033ee:	89 e5                	mov    %esp,%ebp
801033f0:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801033f3:	a1 d4 f8 10 80       	mov    0x8010f8d4,%eax
801033f8:	89 c2                	mov    %eax,%edx
801033fa:	a1 e0 f8 10 80       	mov    0x8010f8e0,%eax
801033ff:	89 54 24 04          	mov    %edx,0x4(%esp)
80103403:	89 04 24             	mov    %eax,(%esp)
80103406:	e8 9b cd ff ff       	call   801001a6 <bread>
8010340b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010340e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103411:	83 c0 18             	add    $0x18,%eax
80103414:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103417:	8b 15 e4 f8 10 80    	mov    0x8010f8e4,%edx
8010341d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103420:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
80103422:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103429:	eb 1b                	jmp    80103446 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
8010342b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010342e:	83 c0 10             	add    $0x10,%eax
80103431:	8b 0c 85 a8 f8 10 80 	mov    -0x7fef0758(,%eax,4),%ecx
80103438:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010343b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010343e:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103442:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103446:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
8010344b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010344e:	7f db                	jg     8010342b <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103450:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103453:	89 04 24             	mov    %eax,(%esp)
80103456:	e8 82 cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
8010345b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010345e:	89 04 24             	mov    %eax,(%esp)
80103461:	e8 b1 cd ff ff       	call   80100217 <brelse>
}
80103466:	c9                   	leave  
80103467:	c3                   	ret    

80103468 <recover_from_log>:

static void
recover_from_log(void)
{
80103468:	55                   	push   %ebp
80103469:	89 e5                	mov    %esp,%ebp
8010346b:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010346e:	e8 0b ff ff ff       	call   8010337e <read_head>
  install_trans(); // if committed, copy from log to disk
80103473:	e8 5b fe ff ff       	call   801032d3 <install_trans>
  log.lh.n = 0;
80103478:	c7 05 e4 f8 10 80 00 	movl   $0x0,0x8010f8e4
8010347f:	00 00 00 
  write_head(); // clear the log
80103482:	e8 66 ff ff ff       	call   801033ed <write_head>
}
80103487:	c9                   	leave  
80103488:	c3                   	ret    

80103489 <begin_trans>:

void
begin_trans(void)
{
80103489:	55                   	push   %ebp
8010348a:	89 e5                	mov    %esp,%ebp
8010348c:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010348f:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80103496:	e8 74 19 00 00       	call   80104e0f <acquire>
  while (log.busy) {
8010349b:	eb 14                	jmp    801034b1 <begin_trans+0x28>
    sleep(&log, &log.lock);
8010349d:	c7 44 24 04 a0 f8 10 	movl   $0x8010f8a0,0x4(%esp)
801034a4:	80 
801034a5:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801034ac:	e8 80 16 00 00       	call   80104b31 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801034b1:	a1 dc f8 10 80       	mov    0x8010f8dc,%eax
801034b6:	85 c0                	test   %eax,%eax
801034b8:	75 e3                	jne    8010349d <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801034ba:	c7 05 dc f8 10 80 01 	movl   $0x1,0x8010f8dc
801034c1:	00 00 00 
  release(&log.lock);
801034c4:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
801034cb:	e8 a1 19 00 00       	call   80104e71 <release>
}
801034d0:	c9                   	leave  
801034d1:	c3                   	ret    

801034d2 <commit_trans>:

void
commit_trans(void)
{
801034d2:	55                   	push   %ebp
801034d3:	89 e5                	mov    %esp,%ebp
801034d5:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801034d8:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
801034dd:	85 c0                	test   %eax,%eax
801034df:	7e 19                	jle    801034fa <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801034e1:	e8 07 ff ff ff       	call   801033ed <write_head>
    install_trans(); // Now install writes to home locations
801034e6:	e8 e8 fd ff ff       	call   801032d3 <install_trans>
    log.lh.n = 0; 
801034eb:	c7 05 e4 f8 10 80 00 	movl   $0x0,0x8010f8e4
801034f2:	00 00 00 
    write_head();    // Erase the transaction from the log
801034f5:	e8 f3 fe ff ff       	call   801033ed <write_head>
  }
  
  acquire(&log.lock);
801034fa:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80103501:	e8 09 19 00 00       	call   80104e0f <acquire>
  log.busy = 0;
80103506:	c7 05 dc f8 10 80 00 	movl   $0x0,0x8010f8dc
8010350d:	00 00 00 
  wakeup(&log);
80103510:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80103517:	e8 ee 16 00 00       	call   80104c0a <wakeup>
  release(&log.lock);
8010351c:	c7 04 24 a0 f8 10 80 	movl   $0x8010f8a0,(%esp)
80103523:	e8 49 19 00 00       	call   80104e71 <release>
}
80103528:	c9                   	leave  
80103529:	c3                   	ret    

8010352a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010352a:	55                   	push   %ebp
8010352b:	89 e5                	mov    %esp,%ebp
8010352d:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103530:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
80103535:	83 f8 09             	cmp    $0x9,%eax
80103538:	7f 12                	jg     8010354c <log_write+0x22>
8010353a:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
8010353f:	8b 15 d8 f8 10 80    	mov    0x8010f8d8,%edx
80103545:	83 ea 01             	sub    $0x1,%edx
80103548:	39 d0                	cmp    %edx,%eax
8010354a:	7c 0c                	jl     80103558 <log_write+0x2e>
    panic("too big a transaction");
8010354c:	c7 04 24 40 88 10 80 	movl   $0x80108840,(%esp)
80103553:	e8 e5 cf ff ff       	call   8010053d <panic>
  if (!log.busy)
80103558:	a1 dc f8 10 80       	mov    0x8010f8dc,%eax
8010355d:	85 c0                	test   %eax,%eax
8010355f:	75 0c                	jne    8010356d <log_write+0x43>
    panic("write outside of trans");
80103561:	c7 04 24 56 88 10 80 	movl   $0x80108856,(%esp)
80103568:	e8 d0 cf ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
8010356d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103574:	eb 1d                	jmp    80103593 <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103576:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103579:	83 c0 10             	add    $0x10,%eax
8010357c:	8b 04 85 a8 f8 10 80 	mov    -0x7fef0758(,%eax,4),%eax
80103583:	89 c2                	mov    %eax,%edx
80103585:	8b 45 08             	mov    0x8(%ebp),%eax
80103588:	8b 40 08             	mov    0x8(%eax),%eax
8010358b:	39 c2                	cmp    %eax,%edx
8010358d:	74 10                	je     8010359f <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010358f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103593:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
80103598:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010359b:	7f d9                	jg     80103576 <log_write+0x4c>
8010359d:	eb 01                	jmp    801035a0 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
8010359f:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801035a0:	8b 45 08             	mov    0x8(%ebp),%eax
801035a3:	8b 40 08             	mov    0x8(%eax),%eax
801035a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801035a9:	83 c2 10             	add    $0x10,%edx
801035ac:	89 04 95 a8 f8 10 80 	mov    %eax,-0x7fef0758(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801035b3:	a1 d4 f8 10 80       	mov    0x8010f8d4,%eax
801035b8:	03 45 f4             	add    -0xc(%ebp),%eax
801035bb:	83 c0 01             	add    $0x1,%eax
801035be:	89 c2                	mov    %eax,%edx
801035c0:	8b 45 08             	mov    0x8(%ebp),%eax
801035c3:	8b 40 04             	mov    0x4(%eax),%eax
801035c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801035ca:	89 04 24             	mov    %eax,(%esp)
801035cd:	e8 d4 cb ff ff       	call   801001a6 <bread>
801035d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801035d5:	8b 45 08             	mov    0x8(%ebp),%eax
801035d8:	8d 50 18             	lea    0x18(%eax),%edx
801035db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035de:	83 c0 18             	add    $0x18,%eax
801035e1:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801035e8:	00 
801035e9:	89 54 24 04          	mov    %edx,0x4(%esp)
801035ed:	89 04 24             	mov    %eax,(%esp)
801035f0:	e8 3c 1b 00 00       	call   80105131 <memmove>
  bwrite(lbuf);
801035f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f8:	89 04 24             	mov    %eax,(%esp)
801035fb:	e8 dd cb ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103600:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103603:	89 04 24             	mov    %eax,(%esp)
80103606:	e8 0c cc ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
8010360b:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
80103610:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103613:	75 0d                	jne    80103622 <log_write+0xf8>
    log.lh.n++;
80103615:	a1 e4 f8 10 80       	mov    0x8010f8e4,%eax
8010361a:	83 c0 01             	add    $0x1,%eax
8010361d:	a3 e4 f8 10 80       	mov    %eax,0x8010f8e4
  b->flags |= B_DIRTY; // XXX prevent eviction
80103622:	8b 45 08             	mov    0x8(%ebp),%eax
80103625:	8b 00                	mov    (%eax),%eax
80103627:	89 c2                	mov    %eax,%edx
80103629:	83 ca 04             	or     $0x4,%edx
8010362c:	8b 45 08             	mov    0x8(%ebp),%eax
8010362f:	89 10                	mov    %edx,(%eax)
}
80103631:	c9                   	leave  
80103632:	c3                   	ret    
	...

80103634 <v2p>:
80103634:	55                   	push   %ebp
80103635:	89 e5                	mov    %esp,%ebp
80103637:	8b 45 08             	mov    0x8(%ebp),%eax
8010363a:	05 00 00 00 80       	add    $0x80000000,%eax
8010363f:	5d                   	pop    %ebp
80103640:	c3                   	ret    

80103641 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103641:	55                   	push   %ebp
80103642:	89 e5                	mov    %esp,%ebp
80103644:	8b 45 08             	mov    0x8(%ebp),%eax
80103647:	05 00 00 00 80       	add    $0x80000000,%eax
8010364c:	5d                   	pop    %ebp
8010364d:	c3                   	ret    

8010364e <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010364e:	55                   	push   %ebp
8010364f:	89 e5                	mov    %esp,%ebp
80103651:	53                   	push   %ebx
80103652:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103655:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103658:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
8010365b:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010365e:	89 c3                	mov    %eax,%ebx
80103660:	89 d8                	mov    %ebx,%eax
80103662:	f0 87 02             	lock xchg %eax,(%edx)
80103665:	89 c3                	mov    %eax,%ebx
80103667:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
8010366a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010366d:	83 c4 10             	add    $0x10,%esp
80103670:	5b                   	pop    %ebx
80103671:	5d                   	pop    %ebp
80103672:	c3                   	ret    

80103673 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103673:	55                   	push   %ebp
80103674:	89 e5                	mov    %esp,%ebp
80103676:	83 e4 f0             	and    $0xfffffff0,%esp
80103679:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010367c:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103683:	80 
80103684:	c7 04 24 1c 27 11 80 	movl   $0x8011271c,(%esp)
8010368b:	e8 ad f5 ff ff       	call   80102c3d <kinit1>
  kvmalloc();      // kernel page table
80103690:	e8 5d 47 00 00       	call   80107df2 <kvmalloc>
  mpinit();        // collect info about this machine
80103695:	e8 63 04 00 00       	call   80103afd <mpinit>
  lapicinit(mpbcpu());
8010369a:	e8 2e 02 00 00       	call   801038cd <mpbcpu>
8010369f:	89 04 24             	mov    %eax,(%esp)
801036a2:	e8 f5 f8 ff ff       	call   80102f9c <lapicinit>
  seginit();       // set up segments
801036a7:	e8 e9 40 00 00       	call   80107795 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801036ac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801036b2:	0f b6 00             	movzbl (%eax),%eax
801036b5:	0f b6 c0             	movzbl %al,%eax
801036b8:	89 44 24 04          	mov    %eax,0x4(%esp)
801036bc:	c7 04 24 6d 88 10 80 	movl   $0x8010886d,(%esp)
801036c3:	e8 d9 cc ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801036c8:	e8 95 06 00 00       	call   80103d62 <picinit>
  ioapicinit();    // another interrupt controller
801036cd:	e8 5b f4 ff ff       	call   80102b2d <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801036d2:	e8 b6 d3 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801036d7:	e8 04 34 00 00       	call   80106ae0 <uartinit>
  pinit();         // process table
801036dc:	e8 96 0b 00 00       	call   80104277 <pinit>
  tvinit();        // trap vectors
801036e1:	e8 9d 2f 00 00       	call   80106683 <tvinit>
  binit();         // buffer cache
801036e6:	e8 49 c9 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801036eb:	e8 10 d8 ff ff       	call   80100f00 <fileinit>
  iinit();         // inode cache
801036f0:	e8 2a e1 ff ff       	call   8010181f <iinit>
  ideinit();       // disk
801036f5:	e8 98 f0 ff ff       	call   80102792 <ideinit>
  if(!ismp)
801036fa:	a1 24 f9 10 80       	mov    0x8010f924,%eax
801036ff:	85 c0                	test   %eax,%eax
80103701:	75 05                	jne    80103708 <main+0x95>
    timerinit();   // uniprocessor timer
80103703:	e8 be 2e 00 00       	call   801065c6 <timerinit>
  startothers();   // start other processors
80103708:	e8 87 00 00 00       	call   80103794 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
8010370d:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103714:	8e 
80103715:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
8010371c:	e8 54 f5 ff ff       	call   80102c75 <kinit2>
  userinit();      // first user process
80103721:	e8 6c 0c 00 00       	call   80104392 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103726:	e8 22 00 00 00       	call   8010374d <mpmain>

8010372b <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010372b:	55                   	push   %ebp
8010372c:	89 e5                	mov    %esp,%ebp
8010372e:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103731:	e8 d3 46 00 00       	call   80107e09 <switchkvm>
  seginit();
80103736:	e8 5a 40 00 00       	call   80107795 <seginit>
  lapicinit(cpunum());
8010373b:	e8 b9 f9 ff ff       	call   801030f9 <cpunum>
80103740:	89 04 24             	mov    %eax,(%esp)
80103743:	e8 54 f8 ff ff       	call   80102f9c <lapicinit>
  mpmain();
80103748:	e8 00 00 00 00       	call   8010374d <mpmain>

8010374d <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
8010374d:	55                   	push   %ebp
8010374e:	89 e5                	mov    %esp,%ebp
80103750:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103753:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103759:	0f b6 00             	movzbl (%eax),%eax
8010375c:	0f b6 c0             	movzbl %al,%eax
8010375f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103763:	c7 04 24 84 88 10 80 	movl   $0x80108884,(%esp)
8010376a:	e8 32 cc ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
8010376f:	e8 83 30 00 00       	call   801067f7 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103774:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010377a:	05 a8 00 00 00       	add    $0xa8,%eax
8010377f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103786:	00 
80103787:	89 04 24             	mov    %eax,(%esp)
8010378a:	e8 bf fe ff ff       	call   8010364e <xchg>
  scheduler();     // start running processes
8010378f:	e8 f4 11 00 00       	call   80104988 <scheduler>

80103794 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103794:	55                   	push   %ebp
80103795:	89 e5                	mov    %esp,%ebp
80103797:	53                   	push   %ebx
80103798:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
8010379b:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801037a2:	e8 9a fe ff ff       	call   80103641 <p2v>
801037a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801037aa:	b8 8a 00 00 00       	mov    $0x8a,%eax
801037af:	89 44 24 08          	mov    %eax,0x8(%esp)
801037b3:	c7 44 24 04 2c b5 10 	movl   $0x8010b52c,0x4(%esp)
801037ba:	80 
801037bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037be:	89 04 24             	mov    %eax,(%esp)
801037c1:	e8 6b 19 00 00       	call   80105131 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801037c6:	c7 45 f4 40 f9 10 80 	movl   $0x8010f940,-0xc(%ebp)
801037cd:	e9 86 00 00 00       	jmp    80103858 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801037d2:	e8 22 f9 ff ff       	call   801030f9 <cpunum>
801037d7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801037dd:	05 40 f9 10 80       	add    $0x8010f940,%eax
801037e2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037e5:	74 69                	je     80103850 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801037e7:	e8 7f f5 ff ff       	call   80102d6b <kalloc>
801037ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801037ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037f2:	83 e8 04             	sub    $0x4,%eax
801037f5:	8b 55 ec             	mov    -0x14(%ebp),%edx
801037f8:	81 c2 00 10 00 00    	add    $0x1000,%edx
801037fe:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103800:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103803:	83 e8 08             	sub    $0x8,%eax
80103806:	c7 00 2b 37 10 80    	movl   $0x8010372b,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
8010380c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010380f:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103812:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103819:	e8 16 fe ff ff       	call   80103634 <v2p>
8010381e:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103820:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103823:	89 04 24             	mov    %eax,(%esp)
80103826:	e8 09 fe ff ff       	call   80103634 <v2p>
8010382b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010382e:	0f b6 12             	movzbl (%edx),%edx
80103831:	0f b6 d2             	movzbl %dl,%edx
80103834:	89 44 24 04          	mov    %eax,0x4(%esp)
80103838:	89 14 24             	mov    %edx,(%esp)
8010383b:	e8 3f f9 ff ff       	call   8010317f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103840:	90                   	nop
80103841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103844:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
8010384a:	85 c0                	test   %eax,%eax
8010384c:	74 f3                	je     80103841 <startothers+0xad>
8010384e:	eb 01                	jmp    80103851 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103850:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103851:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103858:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
8010385d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103863:	05 40 f9 10 80       	add    $0x8010f940,%eax
80103868:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010386b:	0f 87 61 ff ff ff    	ja     801037d2 <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103871:	83 c4 24             	add    $0x24,%esp
80103874:	5b                   	pop    %ebx
80103875:	5d                   	pop    %ebp
80103876:	c3                   	ret    
	...

80103878 <p2v>:
80103878:	55                   	push   %ebp
80103879:	89 e5                	mov    %esp,%ebp
8010387b:	8b 45 08             	mov    0x8(%ebp),%eax
8010387e:	05 00 00 00 80       	add    $0x80000000,%eax
80103883:	5d                   	pop    %ebp
80103884:	c3                   	ret    

80103885 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103885:	55                   	push   %ebp
80103886:	89 e5                	mov    %esp,%ebp
80103888:	53                   	push   %ebx
80103889:	83 ec 14             	sub    $0x14,%esp
8010388c:	8b 45 08             	mov    0x8(%ebp),%eax
8010388f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103893:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103897:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010389b:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010389f:	ec                   	in     (%dx),%al
801038a0:	89 c3                	mov    %eax,%ebx
801038a2:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801038a5:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801038a9:	83 c4 14             	add    $0x14,%esp
801038ac:	5b                   	pop    %ebx
801038ad:	5d                   	pop    %ebp
801038ae:	c3                   	ret    

801038af <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801038af:	55                   	push   %ebp
801038b0:	89 e5                	mov    %esp,%ebp
801038b2:	83 ec 08             	sub    $0x8,%esp
801038b5:	8b 55 08             	mov    0x8(%ebp),%edx
801038b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801038bb:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801038bf:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801038c2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801038c6:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801038ca:	ee                   	out    %al,(%dx)
}
801038cb:	c9                   	leave  
801038cc:	c3                   	ret    

801038cd <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801038cd:	55                   	push   %ebp
801038ce:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801038d0:	a1 64 b6 10 80       	mov    0x8010b664,%eax
801038d5:	89 c2                	mov    %eax,%edx
801038d7:	b8 40 f9 10 80       	mov    $0x8010f940,%eax
801038dc:	89 d1                	mov    %edx,%ecx
801038de:	29 c1                	sub    %eax,%ecx
801038e0:	89 c8                	mov    %ecx,%eax
801038e2:	c1 f8 02             	sar    $0x2,%eax
801038e5:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801038eb:	5d                   	pop    %ebp
801038ec:	c3                   	ret    

801038ed <sum>:

static uchar
sum(uchar *addr, int len)
{
801038ed:	55                   	push   %ebp
801038ee:	89 e5                	mov    %esp,%ebp
801038f0:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801038f3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801038fa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103901:	eb 13                	jmp    80103916 <sum+0x29>
    sum += addr[i];
80103903:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103906:	03 45 08             	add    0x8(%ebp),%eax
80103909:	0f b6 00             	movzbl (%eax),%eax
8010390c:	0f b6 c0             	movzbl %al,%eax
8010390f:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103912:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103916:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103919:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010391c:	7c e5                	jl     80103903 <sum+0x16>
    sum += addr[i];
  return sum;
8010391e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103921:	c9                   	leave  
80103922:	c3                   	ret    

80103923 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103923:	55                   	push   %ebp
80103924:	89 e5                	mov    %esp,%ebp
80103926:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103929:	8b 45 08             	mov    0x8(%ebp),%eax
8010392c:	89 04 24             	mov    %eax,(%esp)
8010392f:	e8 44 ff ff ff       	call   80103878 <p2v>
80103934:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103937:	8b 45 0c             	mov    0xc(%ebp),%eax
8010393a:	03 45 f0             	add    -0x10(%ebp),%eax
8010393d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103940:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103943:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103946:	eb 3f                	jmp    80103987 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103948:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010394f:	00 
80103950:	c7 44 24 04 98 88 10 	movl   $0x80108898,0x4(%esp)
80103957:	80 
80103958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010395b:	89 04 24             	mov    %eax,(%esp)
8010395e:	e8 72 17 00 00       	call   801050d5 <memcmp>
80103963:	85 c0                	test   %eax,%eax
80103965:	75 1c                	jne    80103983 <mpsearch1+0x60>
80103967:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010396e:	00 
8010396f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103972:	89 04 24             	mov    %eax,(%esp)
80103975:	e8 73 ff ff ff       	call   801038ed <sum>
8010397a:	84 c0                	test   %al,%al
8010397c:	75 05                	jne    80103983 <mpsearch1+0x60>
      return (struct mp*)p;
8010397e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103981:	eb 11                	jmp    80103994 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103983:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010398a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010398d:	72 b9                	jb     80103948 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
8010398f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103994:	c9                   	leave  
80103995:	c3                   	ret    

80103996 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103996:	55                   	push   %ebp
80103997:	89 e5                	mov    %esp,%ebp
80103999:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
8010399c:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801039a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039a6:	83 c0 0f             	add    $0xf,%eax
801039a9:	0f b6 00             	movzbl (%eax),%eax
801039ac:	0f b6 c0             	movzbl %al,%eax
801039af:	89 c2                	mov    %eax,%edx
801039b1:	c1 e2 08             	shl    $0x8,%edx
801039b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039b7:	83 c0 0e             	add    $0xe,%eax
801039ba:	0f b6 00             	movzbl (%eax),%eax
801039bd:	0f b6 c0             	movzbl %al,%eax
801039c0:	09 d0                	or     %edx,%eax
801039c2:	c1 e0 04             	shl    $0x4,%eax
801039c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801039c8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801039cc:	74 21                	je     801039ef <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801039ce:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801039d5:	00 
801039d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039d9:	89 04 24             	mov    %eax,(%esp)
801039dc:	e8 42 ff ff ff       	call   80103923 <mpsearch1>
801039e1:	89 45 ec             	mov    %eax,-0x14(%ebp)
801039e4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801039e8:	74 50                	je     80103a3a <mpsearch+0xa4>
      return mp;
801039ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
801039ed:	eb 5f                	jmp    80103a4e <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801039ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f2:	83 c0 14             	add    $0x14,%eax
801039f5:	0f b6 00             	movzbl (%eax),%eax
801039f8:	0f b6 c0             	movzbl %al,%eax
801039fb:	89 c2                	mov    %eax,%edx
801039fd:	c1 e2 08             	shl    $0x8,%edx
80103a00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a03:	83 c0 13             	add    $0x13,%eax
80103a06:	0f b6 00             	movzbl (%eax),%eax
80103a09:	0f b6 c0             	movzbl %al,%eax
80103a0c:	09 d0                	or     %edx,%eax
80103a0e:	c1 e0 0a             	shl    $0xa,%eax
80103a11:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a17:	2d 00 04 00 00       	sub    $0x400,%eax
80103a1c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a23:	00 
80103a24:	89 04 24             	mov    %eax,(%esp)
80103a27:	e8 f7 fe ff ff       	call   80103923 <mpsearch1>
80103a2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103a2f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103a33:	74 05                	je     80103a3a <mpsearch+0xa4>
      return mp;
80103a35:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103a38:	eb 14                	jmp    80103a4e <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103a3a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103a41:	00 
80103a42:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103a49:	e8 d5 fe ff ff       	call   80103923 <mpsearch1>
}
80103a4e:	c9                   	leave  
80103a4f:	c3                   	ret    

80103a50 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103a50:	55                   	push   %ebp
80103a51:	89 e5                	mov    %esp,%ebp
80103a53:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103a56:	e8 3b ff ff ff       	call   80103996 <mpsearch>
80103a5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a5e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103a62:	74 0a                	je     80103a6e <mpconfig+0x1e>
80103a64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a67:	8b 40 04             	mov    0x4(%eax),%eax
80103a6a:	85 c0                	test   %eax,%eax
80103a6c:	75 0a                	jne    80103a78 <mpconfig+0x28>
    return 0;
80103a6e:	b8 00 00 00 00       	mov    $0x0,%eax
80103a73:	e9 83 00 00 00       	jmp    80103afb <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103a78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a7b:	8b 40 04             	mov    0x4(%eax),%eax
80103a7e:	89 04 24             	mov    %eax,(%esp)
80103a81:	e8 f2 fd ff ff       	call   80103878 <p2v>
80103a86:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103a89:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103a90:	00 
80103a91:	c7 44 24 04 9d 88 10 	movl   $0x8010889d,0x4(%esp)
80103a98:	80 
80103a99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a9c:	89 04 24             	mov    %eax,(%esp)
80103a9f:	e8 31 16 00 00       	call   801050d5 <memcmp>
80103aa4:	85 c0                	test   %eax,%eax
80103aa6:	74 07                	je     80103aaf <mpconfig+0x5f>
    return 0;
80103aa8:	b8 00 00 00 00       	mov    $0x0,%eax
80103aad:	eb 4c                	jmp    80103afb <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103aaf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ab2:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103ab6:	3c 01                	cmp    $0x1,%al
80103ab8:	74 12                	je     80103acc <mpconfig+0x7c>
80103aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103abd:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103ac1:	3c 04                	cmp    $0x4,%al
80103ac3:	74 07                	je     80103acc <mpconfig+0x7c>
    return 0;
80103ac5:	b8 00 00 00 00       	mov    $0x0,%eax
80103aca:	eb 2f                	jmp    80103afb <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103acc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103acf:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103ad3:	0f b7 c0             	movzwl %ax,%eax
80103ad6:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ada:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103add:	89 04 24             	mov    %eax,(%esp)
80103ae0:	e8 08 fe ff ff       	call   801038ed <sum>
80103ae5:	84 c0                	test   %al,%al
80103ae7:	74 07                	je     80103af0 <mpconfig+0xa0>
    return 0;
80103ae9:	b8 00 00 00 00       	mov    $0x0,%eax
80103aee:	eb 0b                	jmp    80103afb <mpconfig+0xab>
  *pmp = mp;
80103af0:	8b 45 08             	mov    0x8(%ebp),%eax
80103af3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103af6:	89 10                	mov    %edx,(%eax)
  return conf;
80103af8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103afb:	c9                   	leave  
80103afc:	c3                   	ret    

80103afd <mpinit>:

void
mpinit(void)
{
80103afd:	55                   	push   %ebp
80103afe:	89 e5                	mov    %esp,%ebp
80103b00:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103b03:	c7 05 64 b6 10 80 40 	movl   $0x8010f940,0x8010b664
80103b0a:	f9 10 80 
  if((conf = mpconfig(&mp)) == 0)
80103b0d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103b10:	89 04 24             	mov    %eax,(%esp)
80103b13:	e8 38 ff ff ff       	call   80103a50 <mpconfig>
80103b18:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b1b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b1f:	0f 84 9c 01 00 00    	je     80103cc1 <mpinit+0x1c4>
    return;
  ismp = 1;
80103b25:	c7 05 24 f9 10 80 01 	movl   $0x1,0x8010f924
80103b2c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103b2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b32:	8b 40 24             	mov    0x24(%eax),%eax
80103b35:	a3 9c f8 10 80       	mov    %eax,0x8010f89c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103b3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b3d:	83 c0 2c             	add    $0x2c,%eax
80103b40:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b43:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b46:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b4a:	0f b7 c0             	movzwl %ax,%eax
80103b4d:	03 45 f0             	add    -0x10(%ebp),%eax
80103b50:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b53:	e9 f4 00 00 00       	jmp    80103c4c <mpinit+0x14f>
    switch(*p){
80103b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b5b:	0f b6 00             	movzbl (%eax),%eax
80103b5e:	0f b6 c0             	movzbl %al,%eax
80103b61:	83 f8 04             	cmp    $0x4,%eax
80103b64:	0f 87 bf 00 00 00    	ja     80103c29 <mpinit+0x12c>
80103b6a:	8b 04 85 e0 88 10 80 	mov    -0x7fef7720(,%eax,4),%eax
80103b71:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103b73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b76:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103b79:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b7c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b80:	0f b6 d0             	movzbl %al,%edx
80103b83:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
80103b88:	39 c2                	cmp    %eax,%edx
80103b8a:	74 2d                	je     80103bb9 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103b8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103b8f:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103b93:	0f b6 d0             	movzbl %al,%edx
80103b96:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
80103b9b:	89 54 24 08          	mov    %edx,0x8(%esp)
80103b9f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ba3:	c7 04 24 a2 88 10 80 	movl   $0x801088a2,(%esp)
80103baa:	e8 f2 c7 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103baf:	c7 05 24 f9 10 80 00 	movl   $0x0,0x8010f924
80103bb6:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103bb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103bbc:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103bc0:	0f b6 c0             	movzbl %al,%eax
80103bc3:	83 e0 02             	and    $0x2,%eax
80103bc6:	85 c0                	test   %eax,%eax
80103bc8:	74 15                	je     80103bdf <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103bca:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
80103bcf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103bd5:	05 40 f9 10 80       	add    $0x8010f940,%eax
80103bda:	a3 64 b6 10 80       	mov    %eax,0x8010b664
      cpus[ncpu].id = ncpu;
80103bdf:	8b 15 20 ff 10 80    	mov    0x8010ff20,%edx
80103be5:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
80103bea:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103bf0:	81 c2 40 f9 10 80    	add    $0x8010f940,%edx
80103bf6:	88 02                	mov    %al,(%edx)
      ncpu++;
80103bf8:	a1 20 ff 10 80       	mov    0x8010ff20,%eax
80103bfd:	83 c0 01             	add    $0x1,%eax
80103c00:	a3 20 ff 10 80       	mov    %eax,0x8010ff20
      p += sizeof(struct mpproc);
80103c05:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103c09:	eb 41                	jmp    80103c4c <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c0e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103c11:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103c14:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c18:	a2 20 f9 10 80       	mov    %al,0x8010f920
      p += sizeof(struct mpioapic);
80103c1d:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c21:	eb 29                	jmp    80103c4c <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103c23:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103c27:	eb 23                	jmp    80103c4c <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103c29:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c2c:	0f b6 00             	movzbl (%eax),%eax
80103c2f:	0f b6 c0             	movzbl %al,%eax
80103c32:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c36:	c7 04 24 c0 88 10 80 	movl   $0x801088c0,(%esp)
80103c3d:	e8 5f c7 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103c42:	c7 05 24 f9 10 80 00 	movl   $0x0,0x8010f924
80103c49:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c4f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103c52:	0f 82 00 ff ff ff    	jb     80103b58 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103c58:	a1 24 f9 10 80       	mov    0x8010f924,%eax
80103c5d:	85 c0                	test   %eax,%eax
80103c5f:	75 1d                	jne    80103c7e <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103c61:	c7 05 20 ff 10 80 01 	movl   $0x1,0x8010ff20
80103c68:	00 00 00 
    lapic = 0;
80103c6b:	c7 05 9c f8 10 80 00 	movl   $0x0,0x8010f89c
80103c72:	00 00 00 
    ioapicid = 0;
80103c75:	c6 05 20 f9 10 80 00 	movb   $0x0,0x8010f920
    return;
80103c7c:	eb 44                	jmp    80103cc2 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103c7e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103c81:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103c85:	84 c0                	test   %al,%al
80103c87:	74 39                	je     80103cc2 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103c89:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103c90:	00 
80103c91:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103c98:	e8 12 fc ff ff       	call   801038af <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103c9d:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103ca4:	e8 dc fb ff ff       	call   80103885 <inb>
80103ca9:	83 c8 01             	or     $0x1,%eax
80103cac:	0f b6 c0             	movzbl %al,%eax
80103caf:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cb3:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103cba:	e8 f0 fb ff ff       	call   801038af <outb>
80103cbf:	eb 01                	jmp    80103cc2 <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103cc1:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103cc2:	c9                   	leave  
80103cc3:	c3                   	ret    

80103cc4 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103cc4:	55                   	push   %ebp
80103cc5:	89 e5                	mov    %esp,%ebp
80103cc7:	83 ec 08             	sub    $0x8,%esp
80103cca:	8b 55 08             	mov    0x8(%ebp),%edx
80103ccd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cd0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103cd4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103cd7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103cdb:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103cdf:	ee                   	out    %al,(%dx)
}
80103ce0:	c9                   	leave  
80103ce1:	c3                   	ret    

80103ce2 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103ce2:	55                   	push   %ebp
80103ce3:	89 e5                	mov    %esp,%ebp
80103ce5:	83 ec 0c             	sub    $0xc,%esp
80103ce8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ceb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103cef:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cf3:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103cf9:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103cfd:	0f b6 c0             	movzbl %al,%eax
80103d00:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d04:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d0b:	e8 b4 ff ff ff       	call   80103cc4 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103d10:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103d14:	66 c1 e8 08          	shr    $0x8,%ax
80103d18:	0f b6 c0             	movzbl %al,%eax
80103d1b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d1f:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d26:	e8 99 ff ff ff       	call   80103cc4 <outb>
}
80103d2b:	c9                   	leave  
80103d2c:	c3                   	ret    

80103d2d <picenable>:

void
picenable(int irq)
{
80103d2d:	55                   	push   %ebp
80103d2e:	89 e5                	mov    %esp,%ebp
80103d30:	53                   	push   %ebx
80103d31:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103d34:	8b 45 08             	mov    0x8(%ebp),%eax
80103d37:	ba 01 00 00 00       	mov    $0x1,%edx
80103d3c:	89 d3                	mov    %edx,%ebx
80103d3e:	89 c1                	mov    %eax,%ecx
80103d40:	d3 e3                	shl    %cl,%ebx
80103d42:	89 d8                	mov    %ebx,%eax
80103d44:	89 c2                	mov    %eax,%edx
80103d46:	f7 d2                	not    %edx
80103d48:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103d4f:	21 d0                	and    %edx,%eax
80103d51:	0f b7 c0             	movzwl %ax,%eax
80103d54:	89 04 24             	mov    %eax,(%esp)
80103d57:	e8 86 ff ff ff       	call   80103ce2 <picsetmask>
}
80103d5c:	83 c4 04             	add    $0x4,%esp
80103d5f:	5b                   	pop    %ebx
80103d60:	5d                   	pop    %ebp
80103d61:	c3                   	ret    

80103d62 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103d62:	55                   	push   %ebp
80103d63:	89 e5                	mov    %esp,%ebp
80103d65:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d68:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d6f:	00 
80103d70:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103d77:	e8 48 ff ff ff       	call   80103cc4 <outb>
  outb(IO_PIC2+1, 0xFF);
80103d7c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103d83:	00 
80103d84:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103d8b:	e8 34 ff ff ff       	call   80103cc4 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103d90:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103d97:	00 
80103d98:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103d9f:	e8 20 ff ff ff       	call   80103cc4 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103da4:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103dab:	00 
80103dac:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103db3:	e8 0c ff ff ff       	call   80103cc4 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103db8:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103dbf:	00 
80103dc0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103dc7:	e8 f8 fe ff ff       	call   80103cc4 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103dcc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103dd3:	00 
80103dd4:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103ddb:	e8 e4 fe ff ff       	call   80103cc4 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103de0:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103de7:	00 
80103de8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103def:	e8 d0 fe ff ff       	call   80103cc4 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103df4:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103dfb:	00 
80103dfc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e03:	e8 bc fe ff ff       	call   80103cc4 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103e08:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103e0f:	00 
80103e10:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e17:	e8 a8 fe ff ff       	call   80103cc4 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103e1c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103e23:	00 
80103e24:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e2b:	e8 94 fe ff ff       	call   80103cc4 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103e30:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e37:	00 
80103e38:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e3f:	e8 80 fe ff ff       	call   80103cc4 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103e44:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e4b:	00 
80103e4c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e53:	e8 6c fe ff ff       	call   80103cc4 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103e58:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103e5f:	00 
80103e60:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e67:	e8 58 fe ff ff       	call   80103cc4 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103e6c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103e73:	00 
80103e74:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103e7b:	e8 44 fe ff ff       	call   80103cc4 <outb>

  if(irqmask != 0xFFFF)
80103e80:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e87:	66 83 f8 ff          	cmp    $0xffff,%ax
80103e8b:	74 12                	je     80103e9f <picinit+0x13d>
    picsetmask(irqmask);
80103e8d:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e94:	0f b7 c0             	movzwl %ax,%eax
80103e97:	89 04 24             	mov    %eax,(%esp)
80103e9a:	e8 43 fe ff ff       	call   80103ce2 <picsetmask>
}
80103e9f:	c9                   	leave  
80103ea0:	c3                   	ret    
80103ea1:	00 00                	add    %al,(%eax)
	...

80103ea4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103ea4:	55                   	push   %ebp
80103ea5:	89 e5                	mov    %esp,%ebp
80103ea7:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103eaa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103eb1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eb4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103eba:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ebd:	8b 10                	mov    (%eax),%edx
80103ebf:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec2:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103ec4:	e8 53 d0 ff ff       	call   80100f1c <filealloc>
80103ec9:	8b 55 08             	mov    0x8(%ebp),%edx
80103ecc:	89 02                	mov    %eax,(%edx)
80103ece:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed1:	8b 00                	mov    (%eax),%eax
80103ed3:	85 c0                	test   %eax,%eax
80103ed5:	0f 84 c8 00 00 00    	je     80103fa3 <pipealloc+0xff>
80103edb:	e8 3c d0 ff ff       	call   80100f1c <filealloc>
80103ee0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ee3:	89 02                	mov    %eax,(%edx)
80103ee5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ee8:	8b 00                	mov    (%eax),%eax
80103eea:	85 c0                	test   %eax,%eax
80103eec:	0f 84 b1 00 00 00    	je     80103fa3 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103ef2:	e8 74 ee ff ff       	call   80102d6b <kalloc>
80103ef7:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103efa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103efe:	0f 84 9e 00 00 00    	je     80103fa2 <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f07:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103f0e:	00 00 00 
  p->writeopen = 1;
80103f11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f14:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103f1b:	00 00 00 
  p->nwrite = 0;
80103f1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f21:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103f28:	00 00 00 
  p->nread = 0;
80103f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f2e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103f35:	00 00 00 
  initlock(&p->lock, "pipe");
80103f38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f3b:	c7 44 24 04 f4 88 10 	movl   $0x801088f4,0x4(%esp)
80103f42:	80 
80103f43:	89 04 24             	mov    %eax,(%esp)
80103f46:	e8 a3 0e 00 00       	call   80104dee <initlock>
  (*f0)->type = FD_PIPE;
80103f4b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4e:	8b 00                	mov    (%eax),%eax
80103f50:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103f56:	8b 45 08             	mov    0x8(%ebp),%eax
80103f59:	8b 00                	mov    (%eax),%eax
80103f5b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103f5f:	8b 45 08             	mov    0x8(%ebp),%eax
80103f62:	8b 00                	mov    (%eax),%eax
80103f64:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103f68:	8b 45 08             	mov    0x8(%ebp),%eax
80103f6b:	8b 00                	mov    (%eax),%eax
80103f6d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f70:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103f73:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f76:	8b 00                	mov    (%eax),%eax
80103f78:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f81:	8b 00                	mov    (%eax),%eax
80103f83:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103f87:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f8a:	8b 00                	mov    (%eax),%eax
80103f8c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103f90:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f93:	8b 00                	mov    (%eax),%eax
80103f95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f98:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103f9b:	b8 00 00 00 00       	mov    $0x0,%eax
80103fa0:	eb 43                	jmp    80103fe5 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103fa2:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103fa3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103fa7:	74 0b                	je     80103fb4 <pipealloc+0x110>
    kfree((char*)p);
80103fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fac:	89 04 24             	mov    %eax,(%esp)
80103faf:	e8 1e ed ff ff       	call   80102cd2 <kfree>
  if(*f0)
80103fb4:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb7:	8b 00                	mov    (%eax),%eax
80103fb9:	85 c0                	test   %eax,%eax
80103fbb:	74 0d                	je     80103fca <pipealloc+0x126>
    fileclose(*f0);
80103fbd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc0:	8b 00                	mov    (%eax),%eax
80103fc2:	89 04 24             	mov    %eax,(%esp)
80103fc5:	e8 fa cf ff ff       	call   80100fc4 <fileclose>
  if(*f1)
80103fca:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fcd:	8b 00                	mov    (%eax),%eax
80103fcf:	85 c0                	test   %eax,%eax
80103fd1:	74 0d                	je     80103fe0 <pipealloc+0x13c>
    fileclose(*f1);
80103fd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103fd6:	8b 00                	mov    (%eax),%eax
80103fd8:	89 04 24             	mov    %eax,(%esp)
80103fdb:	e8 e4 cf ff ff       	call   80100fc4 <fileclose>
  return -1;
80103fe0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fe5:	c9                   	leave  
80103fe6:	c3                   	ret    

80103fe7 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103fe7:	55                   	push   %ebp
80103fe8:	89 e5                	mov    %esp,%ebp
80103fea:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103fed:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff0:	89 04 24             	mov    %eax,(%esp)
80103ff3:	e8 17 0e 00 00       	call   80104e0f <acquire>
  if(writable){
80103ff8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103ffc:	74 1f                	je     8010401d <pipeclose+0x36>
    p->writeopen = 0;
80103ffe:	8b 45 08             	mov    0x8(%ebp),%eax
80104001:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104008:	00 00 00 
    wakeup(&p->nread);
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	05 34 02 00 00       	add    $0x234,%eax
80104013:	89 04 24             	mov    %eax,(%esp)
80104016:	e8 ef 0b 00 00       	call   80104c0a <wakeup>
8010401b:	eb 1d                	jmp    8010403a <pipeclose+0x53>
  } else {
    p->readopen = 0;
8010401d:	8b 45 08             	mov    0x8(%ebp),%eax
80104020:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104027:	00 00 00 
    wakeup(&p->nwrite);
8010402a:	8b 45 08             	mov    0x8(%ebp),%eax
8010402d:	05 38 02 00 00       	add    $0x238,%eax
80104032:	89 04 24             	mov    %eax,(%esp)
80104035:	e8 d0 0b 00 00       	call   80104c0a <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010403a:	8b 45 08             	mov    0x8(%ebp),%eax
8010403d:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104043:	85 c0                	test   %eax,%eax
80104045:	75 25                	jne    8010406c <pipeclose+0x85>
80104047:	8b 45 08             	mov    0x8(%ebp),%eax
8010404a:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104050:	85 c0                	test   %eax,%eax
80104052:	75 18                	jne    8010406c <pipeclose+0x85>
    release(&p->lock);
80104054:	8b 45 08             	mov    0x8(%ebp),%eax
80104057:	89 04 24             	mov    %eax,(%esp)
8010405a:	e8 12 0e 00 00       	call   80104e71 <release>
    kfree((char*)p);
8010405f:	8b 45 08             	mov    0x8(%ebp),%eax
80104062:	89 04 24             	mov    %eax,(%esp)
80104065:	e8 68 ec ff ff       	call   80102cd2 <kfree>
8010406a:	eb 0b                	jmp    80104077 <pipeclose+0x90>
  } else
    release(&p->lock);
8010406c:	8b 45 08             	mov    0x8(%ebp),%eax
8010406f:	89 04 24             	mov    %eax,(%esp)
80104072:	e8 fa 0d 00 00       	call   80104e71 <release>
}
80104077:	c9                   	leave  
80104078:	c3                   	ret    

80104079 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104079:	55                   	push   %ebp
8010407a:	89 e5                	mov    %esp,%ebp
8010407c:	53                   	push   %ebx
8010407d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104080:	8b 45 08             	mov    0x8(%ebp),%eax
80104083:	89 04 24             	mov    %eax,(%esp)
80104086:	e8 84 0d 00 00       	call   80104e0f <acquire>
  for(i = 0; i < n; i++){
8010408b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104092:	e9 a6 00 00 00       	jmp    8010413d <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80104097:	8b 45 08             	mov    0x8(%ebp),%eax
8010409a:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801040a0:	85 c0                	test   %eax,%eax
801040a2:	74 0d                	je     801040b1 <pipewrite+0x38>
801040a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801040aa:	8b 40 24             	mov    0x24(%eax),%eax
801040ad:	85 c0                	test   %eax,%eax
801040af:	74 15                	je     801040c6 <pipewrite+0x4d>
        release(&p->lock);
801040b1:	8b 45 08             	mov    0x8(%ebp),%eax
801040b4:	89 04 24             	mov    %eax,(%esp)
801040b7:	e8 b5 0d 00 00       	call   80104e71 <release>
        return -1;
801040bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040c1:	e9 9d 00 00 00       	jmp    80104163 <pipewrite+0xea>
      }
      wakeup(&p->nread);
801040c6:	8b 45 08             	mov    0x8(%ebp),%eax
801040c9:	05 34 02 00 00       	add    $0x234,%eax
801040ce:	89 04 24             	mov    %eax,(%esp)
801040d1:	e8 34 0b 00 00       	call   80104c0a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801040d6:	8b 45 08             	mov    0x8(%ebp),%eax
801040d9:	8b 55 08             	mov    0x8(%ebp),%edx
801040dc:	81 c2 38 02 00 00    	add    $0x238,%edx
801040e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801040e6:	89 14 24             	mov    %edx,(%esp)
801040e9:	e8 43 0a 00 00       	call   80104b31 <sleep>
801040ee:	eb 01                	jmp    801040f1 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801040f0:	90                   	nop
801040f1:	8b 45 08             	mov    0x8(%ebp),%eax
801040f4:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801040fa:	8b 45 08             	mov    0x8(%ebp),%eax
801040fd:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104103:	05 00 02 00 00       	add    $0x200,%eax
80104108:	39 c2                	cmp    %eax,%edx
8010410a:	74 8b                	je     80104097 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010410c:	8b 45 08             	mov    0x8(%ebp),%eax
8010410f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104115:	89 c3                	mov    %eax,%ebx
80104117:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010411d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104120:	03 55 0c             	add    0xc(%ebp),%edx
80104123:	0f b6 0a             	movzbl (%edx),%ecx
80104126:	8b 55 08             	mov    0x8(%ebp),%edx
80104129:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
8010412d:	8d 50 01             	lea    0x1(%eax),%edx
80104130:	8b 45 08             	mov    0x8(%ebp),%eax
80104133:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104139:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010413d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104140:	3b 45 10             	cmp    0x10(%ebp),%eax
80104143:	7c ab                	jl     801040f0 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104145:	8b 45 08             	mov    0x8(%ebp),%eax
80104148:	05 34 02 00 00       	add    $0x234,%eax
8010414d:	89 04 24             	mov    %eax,(%esp)
80104150:	e8 b5 0a 00 00       	call   80104c0a <wakeup>
  release(&p->lock);
80104155:	8b 45 08             	mov    0x8(%ebp),%eax
80104158:	89 04 24             	mov    %eax,(%esp)
8010415b:	e8 11 0d 00 00       	call   80104e71 <release>
  return n;
80104160:	8b 45 10             	mov    0x10(%ebp),%eax
}
80104163:	83 c4 24             	add    $0x24,%esp
80104166:	5b                   	pop    %ebx
80104167:	5d                   	pop    %ebp
80104168:	c3                   	ret    

80104169 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104169:	55                   	push   %ebp
8010416a:	89 e5                	mov    %esp,%ebp
8010416c:	53                   	push   %ebx
8010416d:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104170:	8b 45 08             	mov    0x8(%ebp),%eax
80104173:	89 04 24             	mov    %eax,(%esp)
80104176:	e8 94 0c 00 00       	call   80104e0f <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010417b:	eb 3a                	jmp    801041b7 <piperead+0x4e>
    if(proc->killed){
8010417d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104183:	8b 40 24             	mov    0x24(%eax),%eax
80104186:	85 c0                	test   %eax,%eax
80104188:	74 15                	je     8010419f <piperead+0x36>
      release(&p->lock);
8010418a:	8b 45 08             	mov    0x8(%ebp),%eax
8010418d:	89 04 24             	mov    %eax,(%esp)
80104190:	e8 dc 0c 00 00       	call   80104e71 <release>
      return -1;
80104195:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010419a:	e9 b6 00 00 00       	jmp    80104255 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010419f:	8b 45 08             	mov    0x8(%ebp),%eax
801041a2:	8b 55 08             	mov    0x8(%ebp),%edx
801041a5:	81 c2 34 02 00 00    	add    $0x234,%edx
801041ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801041af:	89 14 24             	mov    %edx,(%esp)
801041b2:	e8 7a 09 00 00       	call   80104b31 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801041b7:	8b 45 08             	mov    0x8(%ebp),%eax
801041ba:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041c0:	8b 45 08             	mov    0x8(%ebp),%eax
801041c3:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041c9:	39 c2                	cmp    %eax,%edx
801041cb:	75 0d                	jne    801041da <piperead+0x71>
801041cd:	8b 45 08             	mov    0x8(%ebp),%eax
801041d0:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801041d6:	85 c0                	test   %eax,%eax
801041d8:	75 a3                	jne    8010417d <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801041da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801041e1:	eb 49                	jmp    8010422c <piperead+0xc3>
    if(p->nread == p->nwrite)
801041e3:	8b 45 08             	mov    0x8(%ebp),%eax
801041e6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801041ec:	8b 45 08             	mov    0x8(%ebp),%eax
801041ef:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041f5:	39 c2                	cmp    %eax,%edx
801041f7:	74 3d                	je     80104236 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801041f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041fc:	89 c2                	mov    %eax,%edx
801041fe:	03 55 0c             	add    0xc(%ebp),%edx
80104201:	8b 45 08             	mov    0x8(%ebp),%eax
80104204:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010420a:	89 c3                	mov    %eax,%ebx
8010420c:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104212:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104215:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
8010421a:	88 0a                	mov    %cl,(%edx)
8010421c:	8d 50 01             	lea    0x1(%eax),%edx
8010421f:	8b 45 08             	mov    0x8(%ebp),%eax
80104222:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104228:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010422c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010422f:	3b 45 10             	cmp    0x10(%ebp),%eax
80104232:	7c af                	jl     801041e3 <piperead+0x7a>
80104234:	eb 01                	jmp    80104237 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104236:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104237:	8b 45 08             	mov    0x8(%ebp),%eax
8010423a:	05 38 02 00 00       	add    $0x238,%eax
8010423f:	89 04 24             	mov    %eax,(%esp)
80104242:	e8 c3 09 00 00       	call   80104c0a <wakeup>
  release(&p->lock);
80104247:	8b 45 08             	mov    0x8(%ebp),%eax
8010424a:	89 04 24             	mov    %eax,(%esp)
8010424d:	e8 1f 0c 00 00       	call   80104e71 <release>
  return i;
80104252:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104255:	83 c4 24             	add    $0x24,%esp
80104258:	5b                   	pop    %ebx
80104259:	5d                   	pop    %ebp
8010425a:	c3                   	ret    
	...

8010425c <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010425c:	55                   	push   %ebp
8010425d:	89 e5                	mov    %esp,%ebp
8010425f:	53                   	push   %ebx
80104260:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104263:	9c                   	pushf  
80104264:	5b                   	pop    %ebx
80104265:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104268:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010426b:	83 c4 10             	add    $0x10,%esp
8010426e:	5b                   	pop    %ebx
8010426f:	5d                   	pop    %ebp
80104270:	c3                   	ret    

80104271 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104271:	55                   	push   %ebp
80104272:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104274:	fb                   	sti    
}
80104275:	5d                   	pop    %ebp
80104276:	c3                   	ret    

80104277 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104277:	55                   	push   %ebp
80104278:	89 e5                	mov    %esp,%ebp
8010427a:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
8010427d:	c7 44 24 04 f9 88 10 	movl   $0x801088f9,0x4(%esp)
80104284:	80 
80104285:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
8010428c:	e8 5d 0b 00 00       	call   80104dee <initlock>
}
80104291:	c9                   	leave  
80104292:	c3                   	ret    

80104293 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
80104293:	55                   	push   %ebp
80104294:	89 e5                	mov    %esp,%ebp
80104296:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104299:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
801042a0:	e8 6a 0b 00 00       	call   80104e0f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042a5:	c7 45 f4 74 ff 10 80 	movl   $0x8010ff74,-0xc(%ebp)
801042ac:	eb 0e                	jmp    801042bc <allocproc+0x29>
    if(p->state == UNUSED)
801042ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b1:	8b 40 0c             	mov    0xc(%eax),%eax
801042b4:	85 c0                	test   %eax,%eax
801042b6:	74 23                	je     801042db <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042b8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801042bc:	81 7d f4 74 1e 11 80 	cmpl   $0x80111e74,-0xc(%ebp)
801042c3:	72 e9                	jb     801042ae <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801042c5:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
801042cc:	e8 a0 0b 00 00       	call   80104e71 <release>
  return 0;
801042d1:	b8 00 00 00 00       	mov    $0x0,%eax
801042d6:	e9 b5 00 00 00       	jmp    80104390 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801042db:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801042dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042df:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801042e6:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801042eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042ee:	89 42 10             	mov    %eax,0x10(%edx)
801042f1:	83 c0 01             	add    $0x1,%eax
801042f4:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
801042f9:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104300:	e8 6c 0b 00 00       	call   80104e71 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104305:	e8 61 ea ff ff       	call   80102d6b <kalloc>
8010430a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010430d:	89 42 08             	mov    %eax,0x8(%edx)
80104310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104313:	8b 40 08             	mov    0x8(%eax),%eax
80104316:	85 c0                	test   %eax,%eax
80104318:	75 11                	jne    8010432b <allocproc+0x98>
    p->state = UNUSED;
8010431a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010431d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104324:	b8 00 00 00 00       	mov    $0x0,%eax
80104329:	eb 65                	jmp    80104390 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010432b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010432e:	8b 40 08             	mov    0x8(%eax),%eax
80104331:	05 00 10 00 00       	add    $0x1000,%eax
80104336:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104339:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010433d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104340:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104343:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104346:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010434a:	ba 38 66 10 80       	mov    $0x80106638,%edx
8010434f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104352:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104354:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010435e:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
80104361:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104364:	8b 40 1c             	mov    0x1c(%eax),%eax
80104367:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010436e:	00 
8010436f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104376:	00 
80104377:	89 04 24             	mov    %eax,(%esp)
8010437a:	e8 df 0c 00 00       	call   8010505e <memset>
  p->context->eip = (uint)forkret;
8010437f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104382:	8b 40 1c             	mov    0x1c(%eax),%eax
80104385:	ba 05 4b 10 80       	mov    $0x80104b05,%edx
8010438a:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010438d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104390:	c9                   	leave  
80104391:	c3                   	ret    

80104392 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
80104392:	55                   	push   %ebp
80104393:	89 e5                	mov    %esp,%ebp
80104395:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
80104398:	e8 f6 fe ff ff       	call   80104293 <allocproc>
8010439d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801043a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a3:	a3 68 b6 10 80       	mov    %eax,0x8010b668
  if((p->pgdir = setupkvm(kalloc)) == 0)
801043a8:	c7 04 24 6b 2d 10 80 	movl   $0x80102d6b,(%esp)
801043af:	e8 81 39 00 00       	call   80107d35 <setupkvm>
801043b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043b7:	89 42 04             	mov    %eax,0x4(%edx)
801043ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043bd:	8b 40 04             	mov    0x4(%eax),%eax
801043c0:	85 c0                	test   %eax,%eax
801043c2:	75 0c                	jne    801043d0 <userinit+0x3e>
    panic("userinit: out of memory?");
801043c4:	c7 04 24 00 89 10 80 	movl   $0x80108900,(%esp)
801043cb:	e8 6d c1 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801043d0:	ba 2c 00 00 00       	mov    $0x2c,%edx
801043d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d8:	8b 40 04             	mov    0x4(%eax),%eax
801043db:	89 54 24 08          	mov    %edx,0x8(%esp)
801043df:	c7 44 24 04 00 b5 10 	movl   $0x8010b500,0x4(%esp)
801043e6:	80 
801043e7:	89 04 24             	mov    %eax,(%esp)
801043ea:	e8 9e 3b 00 00       	call   80107f8d <inituvm>
  p->sz = PGSIZE;
801043ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043f2:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801043f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fb:	8b 40 18             	mov    0x18(%eax),%eax
801043fe:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104405:	00 
80104406:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010440d:	00 
8010440e:	89 04 24             	mov    %eax,(%esp)
80104411:	e8 48 0c 00 00       	call   8010505e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104416:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104419:	8b 40 18             	mov    0x18(%eax),%eax
8010441c:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104422:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104425:	8b 40 18             	mov    0x18(%eax),%eax
80104428:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010442e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104431:	8b 40 18             	mov    0x18(%eax),%eax
80104434:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104437:	8b 52 18             	mov    0x18(%edx),%edx
8010443a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010443e:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104445:	8b 40 18             	mov    0x18(%eax),%eax
80104448:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010444b:	8b 52 18             	mov    0x18(%edx),%edx
8010444e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104452:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104456:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104459:	8b 40 18             	mov    0x18(%eax),%eax
8010445c:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104466:	8b 40 18             	mov    0x18(%eax),%eax
80104469:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104473:	8b 40 18             	mov    0x18(%eax),%eax
80104476:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010447d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104480:	83 c0 6c             	add    $0x6c,%eax
80104483:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010448a:	00 
8010448b:	c7 44 24 04 19 89 10 	movl   $0x80108919,0x4(%esp)
80104492:	80 
80104493:	89 04 24             	mov    %eax,(%esp)
80104496:	e8 f3 0d 00 00       	call   8010528e <safestrcpy>
  p->cwd = namei("/");
8010449b:	c7 04 24 22 89 10 80 	movl   $0x80108922,(%esp)
801044a2:	e8 cf e1 ff ff       	call   80102676 <namei>
801044a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044aa:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801044ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044b0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801044b7:	c9                   	leave  
801044b8:	c3                   	ret    

801044b9 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801044b9:	55                   	push   %ebp
801044ba:	89 e5                	mov    %esp,%ebp
801044bc:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801044bf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044c5:	8b 00                	mov    (%eax),%eax
801044c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801044ca:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801044ce:	7e 34                	jle    80104504 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801044d0:	8b 45 08             	mov    0x8(%ebp),%eax
801044d3:	89 c2                	mov    %eax,%edx
801044d5:	03 55 f4             	add    -0xc(%ebp),%edx
801044d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044de:	8b 40 04             	mov    0x4(%eax),%eax
801044e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801044e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044e8:	89 54 24 04          	mov    %edx,0x4(%esp)
801044ec:	89 04 24             	mov    %eax,(%esp)
801044ef:	e8 13 3c 00 00       	call   80108107 <allocuvm>
801044f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801044f7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801044fb:	75 41                	jne    8010453e <growproc+0x85>
      return -1;
801044fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104502:	eb 58                	jmp    8010455c <growproc+0xa3>
  } else if(n < 0){
80104504:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104508:	79 34                	jns    8010453e <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
8010450a:	8b 45 08             	mov    0x8(%ebp),%eax
8010450d:	89 c2                	mov    %eax,%edx
8010450f:	03 55 f4             	add    -0xc(%ebp),%edx
80104512:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104518:	8b 40 04             	mov    0x4(%eax),%eax
8010451b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010451f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104522:	89 54 24 04          	mov    %edx,0x4(%esp)
80104526:	89 04 24             	mov    %eax,(%esp)
80104529:	e8 b3 3c 00 00       	call   801081e1 <deallocuvm>
8010452e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104531:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104535:	75 07                	jne    8010453e <growproc+0x85>
      return -1;
80104537:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010453c:	eb 1e                	jmp    8010455c <growproc+0xa3>
  }
  proc->sz = sz;
8010453e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104544:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104547:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104549:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010454f:	89 04 24             	mov    %eax,(%esp)
80104552:	e8 cf 38 00 00       	call   80107e26 <switchuvm>
  return 0;
80104557:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010455c:	c9                   	leave  
8010455d:	c3                   	ret    

8010455e <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010455e:	55                   	push   %ebp
8010455f:	89 e5                	mov    %esp,%ebp
80104561:	57                   	push   %edi
80104562:	56                   	push   %esi
80104563:	53                   	push   %ebx
80104564:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104567:	e8 27 fd ff ff       	call   80104293 <allocproc>
8010456c:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010456f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104573:	75 0a                	jne    8010457f <fork+0x21>
    return -1;
80104575:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010457a:	e9 3a 01 00 00       	jmp    801046b9 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010457f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104585:	8b 10                	mov    (%eax),%edx
80104587:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010458d:	8b 40 04             	mov    0x4(%eax),%eax
80104590:	89 54 24 04          	mov    %edx,0x4(%esp)
80104594:	89 04 24             	mov    %eax,(%esp)
80104597:	e8 d5 3d 00 00       	call   80108371 <copyuvm>
8010459c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010459f:	89 42 04             	mov    %eax,0x4(%edx)
801045a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045a5:	8b 40 04             	mov    0x4(%eax),%eax
801045a8:	85 c0                	test   %eax,%eax
801045aa:	75 2c                	jne    801045d8 <fork+0x7a>
    kfree(np->kstack);
801045ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045af:	8b 40 08             	mov    0x8(%eax),%eax
801045b2:	89 04 24             	mov    %eax,(%esp)
801045b5:	e8 18 e7 ff ff       	call   80102cd2 <kfree>
    np->kstack = 0;
801045ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045bd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801045c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045c7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801045ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045d3:	e9 e1 00 00 00       	jmp    801046b9 <fork+0x15b>
  }
  np->sz = proc->sz;
801045d8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045de:	8b 10                	mov    (%eax),%edx
801045e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045e3:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801045e5:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801045ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045ef:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801045f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045f5:	8b 50 18             	mov    0x18(%eax),%edx
801045f8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045fe:	8b 40 18             	mov    0x18(%eax),%eax
80104601:	89 c3                	mov    %eax,%ebx
80104603:	b8 13 00 00 00       	mov    $0x13,%eax
80104608:	89 d7                	mov    %edx,%edi
8010460a:	89 de                	mov    %ebx,%esi
8010460c:	89 c1                	mov    %eax,%ecx
8010460e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104610:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104613:	8b 40 18             	mov    0x18(%eax),%eax
80104616:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010461d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104624:	eb 3d                	jmp    80104663 <fork+0x105>
    if(proc->ofile[i])
80104626:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010462c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010462f:	83 c2 08             	add    $0x8,%edx
80104632:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104636:	85 c0                	test   %eax,%eax
80104638:	74 25                	je     8010465f <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010463a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104640:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104643:	83 c2 08             	add    $0x8,%edx
80104646:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010464a:	89 04 24             	mov    %eax,(%esp)
8010464d:	e8 2a c9 ff ff       	call   80100f7c <filedup>
80104652:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104655:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104658:	83 c1 08             	add    $0x8,%ecx
8010465b:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010465f:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104663:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104667:	7e bd                	jle    80104626 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104669:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010466f:	8b 40 68             	mov    0x68(%eax),%eax
80104672:	89 04 24             	mov    %eax,(%esp)
80104675:	e8 28 d4 ff ff       	call   80101aa2 <idup>
8010467a:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010467d:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104680:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104683:	8b 40 10             	mov    0x10(%eax),%eax
80104686:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104689:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010468c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104693:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104699:	8d 50 6c             	lea    0x6c(%eax),%edx
8010469c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010469f:	83 c0 6c             	add    $0x6c,%eax
801046a2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801046a9:	00 
801046aa:	89 54 24 04          	mov    %edx,0x4(%esp)
801046ae:	89 04 24             	mov    %eax,(%esp)
801046b1:	e8 d8 0b 00 00       	call   8010528e <safestrcpy>
  return pid;
801046b6:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801046b9:	83 c4 2c             	add    $0x2c,%esp
801046bc:	5b                   	pop    %ebx
801046bd:	5e                   	pop    %esi
801046be:	5f                   	pop    %edi
801046bf:	5d                   	pop    %ebp
801046c0:	c3                   	ret    

801046c1 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801046c1:	55                   	push   %ebp
801046c2:	89 e5                	mov    %esp,%ebp
801046c4:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801046c7:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801046ce:	a1 68 b6 10 80       	mov    0x8010b668,%eax
801046d3:	39 c2                	cmp    %eax,%edx
801046d5:	75 0c                	jne    801046e3 <exit+0x22>
    panic("init exiting");
801046d7:	c7 04 24 24 89 10 80 	movl   $0x80108924,(%esp)
801046de:	e8 5a be ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801046e3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801046ea:	eb 44                	jmp    80104730 <exit+0x6f>
    if(proc->ofile[fd]){
801046ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f2:	8b 55 f0             	mov    -0x10(%ebp),%edx
801046f5:	83 c2 08             	add    $0x8,%edx
801046f8:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801046fc:	85 c0                	test   %eax,%eax
801046fe:	74 2c                	je     8010472c <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104700:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104706:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104709:	83 c2 08             	add    $0x8,%edx
8010470c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104710:	89 04 24             	mov    %eax,(%esp)
80104713:	e8 ac c8 ff ff       	call   80100fc4 <fileclose>
      proc->ofile[fd] = 0;
80104718:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104721:	83 c2 08             	add    $0x8,%edx
80104724:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010472b:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010472c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104730:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104734:	7e b6                	jle    801046ec <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104736:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010473c:	8b 40 68             	mov    0x68(%eax),%eax
8010473f:	89 04 24             	mov    %eax,(%esp)
80104742:	e8 40 d5 ff ff       	call   80101c87 <iput>
  proc->cwd = 0;
80104747:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474d:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104754:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
8010475b:	e8 af 06 00 00       	call   80104e0f <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104760:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104766:	8b 40 14             	mov    0x14(%eax),%eax
80104769:	89 04 24             	mov    %eax,(%esp)
8010476c:	e8 5b 04 00 00       	call   80104bcc <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104771:	c7 45 f4 74 ff 10 80 	movl   $0x8010ff74,-0xc(%ebp)
80104778:	eb 38                	jmp    801047b2 <exit+0xf1>
    if(p->parent == proc){
8010477a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010477d:	8b 50 14             	mov    0x14(%eax),%edx
80104780:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104786:	39 c2                	cmp    %eax,%edx
80104788:	75 24                	jne    801047ae <exit+0xed>
      p->parent = initproc;
8010478a:	8b 15 68 b6 10 80    	mov    0x8010b668,%edx
80104790:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104793:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104796:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104799:	8b 40 0c             	mov    0xc(%eax),%eax
8010479c:	83 f8 05             	cmp    $0x5,%eax
8010479f:	75 0d                	jne    801047ae <exit+0xed>
        wakeup1(initproc);
801047a1:	a1 68 b6 10 80       	mov    0x8010b668,%eax
801047a6:	89 04 24             	mov    %eax,(%esp)
801047a9:	e8 1e 04 00 00       	call   80104bcc <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047ae:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801047b2:	81 7d f4 74 1e 11 80 	cmpl   $0x80111e74,-0xc(%ebp)
801047b9:	72 bf                	jb     8010477a <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801047bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047c1:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801047c8:	e8 54 02 00 00       	call   80104a21 <sched>
  panic("zombie exit");
801047cd:	c7 04 24 31 89 10 80 	movl   $0x80108931,(%esp)
801047d4:	e8 64 bd ff ff       	call   8010053d <panic>

801047d9 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801047d9:	55                   	push   %ebp
801047da:	89 e5                	mov    %esp,%ebp
801047dc:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801047df:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
801047e6:	e8 24 06 00 00       	call   80104e0f <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
801047eb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047f2:	c7 45 f4 74 ff 10 80 	movl   $0x8010ff74,-0xc(%ebp)
801047f9:	e9 9a 00 00 00       	jmp    80104898 <wait+0xbf>
      if(p->parent != proc)
801047fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104801:	8b 50 14             	mov    0x14(%eax),%edx
80104804:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010480a:	39 c2                	cmp    %eax,%edx
8010480c:	0f 85 81 00 00 00    	jne    80104893 <wait+0xba>
        continue;
      havekids = 1;
80104812:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010481c:	8b 40 0c             	mov    0xc(%eax),%eax
8010481f:	83 f8 05             	cmp    $0x5,%eax
80104822:	75 70                	jne    80104894 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104824:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104827:	8b 40 10             	mov    0x10(%eax),%eax
8010482a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010482d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104830:	8b 40 08             	mov    0x8(%eax),%eax
80104833:	89 04 24             	mov    %eax,(%esp)
80104836:	e8 97 e4 ff ff       	call   80102cd2 <kfree>
        p->kstack = 0;
8010483b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104848:	8b 40 04             	mov    0x4(%eax),%eax
8010484b:	89 04 24             	mov    %eax,(%esp)
8010484e:	e8 4a 3a 00 00       	call   8010829d <freevm>
        p->state = UNUSED;
80104853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104856:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
8010485d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104860:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104867:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010486a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104874:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487b:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104882:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104889:	e8 e3 05 00 00       	call   80104e71 <release>
        return pid;
8010488e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104891:	eb 53                	jmp    801048e6 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104893:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104894:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104898:	81 7d f4 74 1e 11 80 	cmpl   $0x80111e74,-0xc(%ebp)
8010489f:	0f 82 59 ff ff ff    	jb     801047fe <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801048a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801048a9:	74 0d                	je     801048b8 <wait+0xdf>
801048ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048b1:	8b 40 24             	mov    0x24(%eax),%eax
801048b4:	85 c0                	test   %eax,%eax
801048b6:	74 13                	je     801048cb <wait+0xf2>
      release(&ptable.lock);
801048b8:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
801048bf:	e8 ad 05 00 00       	call   80104e71 <release>
      return -1;
801048c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048c9:	eb 1b                	jmp    801048e6 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801048cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d1:	c7 44 24 04 40 ff 10 	movl   $0x8010ff40,0x4(%esp)
801048d8:	80 
801048d9:	89 04 24             	mov    %eax,(%esp)
801048dc:	e8 50 02 00 00       	call   80104b31 <sleep>
  }
801048e1:	e9 05 ff ff ff       	jmp    801047eb <wait+0x12>
}
801048e6:	c9                   	leave  
801048e7:	c3                   	ret    

801048e8 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
801048e8:	55                   	push   %ebp
801048e9:	89 e5                	mov    %esp,%ebp
801048eb:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
801048ee:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048f4:	8b 40 18             	mov    0x18(%eax),%eax
801048f7:	8b 40 44             	mov    0x44(%eax),%eax
801048fa:	89 c2                	mov    %eax,%edx
801048fc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104902:	8b 40 04             	mov    0x4(%eax),%eax
80104905:	89 54 24 04          	mov    %edx,0x4(%esp)
80104909:	89 04 24             	mov    %eax,(%esp)
8010490c:	e8 71 3b 00 00       	call   80108482 <uva2ka>
80104911:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104914:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010491a:	8b 40 18             	mov    0x18(%eax),%eax
8010491d:	8b 40 44             	mov    0x44(%eax),%eax
80104920:	25 ff 0f 00 00       	and    $0xfff,%eax
80104925:	85 c0                	test   %eax,%eax
80104927:	75 0c                	jne    80104935 <register_handler+0x4d>
    panic("esp_offset == 0");
80104929:	c7 04 24 3d 89 10 80 	movl   $0x8010893d,(%esp)
80104930:	e8 08 bc ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104935:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493b:	8b 40 18             	mov    0x18(%eax),%eax
8010493e:	8b 40 44             	mov    0x44(%eax),%eax
80104941:	83 e8 04             	sub    $0x4,%eax
80104944:	25 ff 0f 00 00       	and    $0xfff,%eax
80104949:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010494c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104953:	8b 52 18             	mov    0x18(%edx),%edx
80104956:	8b 52 38             	mov    0x38(%edx),%edx
80104959:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
8010495b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104961:	8b 40 18             	mov    0x18(%eax),%eax
80104964:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010496b:	8b 52 18             	mov    0x18(%edx),%edx
8010496e:	8b 52 44             	mov    0x44(%edx),%edx
80104971:	83 ea 04             	sub    $0x4,%edx
80104974:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104977:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497d:	8b 40 18             	mov    0x18(%eax),%eax
80104980:	8b 55 08             	mov    0x8(%ebp),%edx
80104983:	89 50 38             	mov    %edx,0x38(%eax)
}
80104986:	c9                   	leave  
80104987:	c3                   	ret    

80104988 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104988:	55                   	push   %ebp
80104989:	89 e5                	mov    %esp,%ebp
8010498b:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
8010498e:	e8 de f8 ff ff       	call   80104271 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104993:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
8010499a:	e8 70 04 00 00       	call   80104e0f <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010499f:	c7 45 f4 74 ff 10 80 	movl   $0x8010ff74,-0xc(%ebp)
801049a6:	eb 5f                	jmp    80104a07 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801049a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ab:	8b 40 0c             	mov    0xc(%eax),%eax
801049ae:	83 f8 03             	cmp    $0x3,%eax
801049b1:	75 4f                	jne    80104a02 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801049b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b6:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
801049bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049bf:	89 04 24             	mov    %eax,(%esp)
801049c2:	e8 5f 34 00 00       	call   80107e26 <switchuvm>
      p->state = RUNNING;
801049c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ca:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
801049d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d7:	8b 40 1c             	mov    0x1c(%eax),%eax
801049da:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801049e1:	83 c2 04             	add    $0x4,%edx
801049e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801049e8:	89 14 24             	mov    %edx,(%esp)
801049eb:	e8 14 09 00 00       	call   80105304 <swtch>
      switchkvm();
801049f0:	e8 14 34 00 00       	call   80107e09 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
801049f5:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801049fc:	00 00 00 00 
80104a00:	eb 01                	jmp    80104a03 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104a02:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a03:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104a07:	81 7d f4 74 1e 11 80 	cmpl   $0x80111e74,-0xc(%ebp)
80104a0e:	72 98                	jb     801049a8 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104a10:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104a17:	e8 55 04 00 00       	call   80104e71 <release>

  }
80104a1c:	e9 6d ff ff ff       	jmp    8010498e <scheduler+0x6>

80104a21 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104a21:	55                   	push   %ebp
80104a22:	89 e5                	mov    %esp,%ebp
80104a24:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104a27:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104a2e:	e8 fa 04 00 00       	call   80104f2d <holding>
80104a33:	85 c0                	test   %eax,%eax
80104a35:	75 0c                	jne    80104a43 <sched+0x22>
    panic("sched ptable.lock");
80104a37:	c7 04 24 4d 89 10 80 	movl   $0x8010894d,(%esp)
80104a3e:	e8 fa ba ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104a43:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104a49:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104a4f:	83 f8 01             	cmp    $0x1,%eax
80104a52:	74 0c                	je     80104a60 <sched+0x3f>
    panic("sched locks");
80104a54:	c7 04 24 5f 89 10 80 	movl   $0x8010895f,(%esp)
80104a5b:	e8 dd ba ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104a60:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a66:	8b 40 0c             	mov    0xc(%eax),%eax
80104a69:	83 f8 04             	cmp    $0x4,%eax
80104a6c:	75 0c                	jne    80104a7a <sched+0x59>
    panic("sched running");
80104a6e:	c7 04 24 6b 89 10 80 	movl   $0x8010896b,(%esp)
80104a75:	e8 c3 ba ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104a7a:	e8 dd f7 ff ff       	call   8010425c <readeflags>
80104a7f:	25 00 02 00 00       	and    $0x200,%eax
80104a84:	85 c0                	test   %eax,%eax
80104a86:	74 0c                	je     80104a94 <sched+0x73>
    panic("sched interruptible");
80104a88:	c7 04 24 79 89 10 80 	movl   $0x80108979,(%esp)
80104a8f:	e8 a9 ba ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104a94:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104a9a:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104aa0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104aa3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104aa9:	8b 40 04             	mov    0x4(%eax),%eax
80104aac:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ab3:	83 c2 1c             	add    $0x1c,%edx
80104ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104aba:	89 14 24             	mov    %edx,(%esp)
80104abd:	e8 42 08 00 00       	call   80105304 <swtch>
  cpu->intena = intena;
80104ac2:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ac8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104acb:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ad1:	c9                   	leave  
80104ad2:	c3                   	ret    

80104ad3 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ad3:	55                   	push   %ebp
80104ad4:	89 e5                	mov    %esp,%ebp
80104ad6:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ad9:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104ae0:	e8 2a 03 00 00       	call   80104e0f <acquire>
  proc->state = RUNNABLE;
80104ae5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aeb:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104af2:	e8 2a ff ff ff       	call   80104a21 <sched>
  release(&ptable.lock);
80104af7:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104afe:	e8 6e 03 00 00       	call   80104e71 <release>
}
80104b03:	c9                   	leave  
80104b04:	c3                   	ret    

80104b05 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104b05:	55                   	push   %ebp
80104b06:	89 e5                	mov    %esp,%ebp
80104b08:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104b0b:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104b12:	e8 5a 03 00 00       	call   80104e71 <release>

  if (first) {
80104b17:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104b1c:	85 c0                	test   %eax,%eax
80104b1e:	74 0f                	je     80104b2f <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104b20:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104b27:	00 00 00 
    initlog();
80104b2a:	e8 4d e7 ff ff       	call   8010327c <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104b2f:	c9                   	leave  
80104b30:	c3                   	ret    

80104b31 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104b31:	55                   	push   %ebp
80104b32:	89 e5                	mov    %esp,%ebp
80104b34:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104b37:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b3d:	85 c0                	test   %eax,%eax
80104b3f:	75 0c                	jne    80104b4d <sleep+0x1c>
    panic("sleep");
80104b41:	c7 04 24 8d 89 10 80 	movl   $0x8010898d,(%esp)
80104b48:	e8 f0 b9 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104b4d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104b51:	75 0c                	jne    80104b5f <sleep+0x2e>
    panic("sleep without lk");
80104b53:	c7 04 24 93 89 10 80 	movl   $0x80108993,(%esp)
80104b5a:	e8 de b9 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104b5f:	81 7d 0c 40 ff 10 80 	cmpl   $0x8010ff40,0xc(%ebp)
80104b66:	74 17                	je     80104b7f <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104b68:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104b6f:	e8 9b 02 00 00       	call   80104e0f <acquire>
    release(lk);
80104b74:	8b 45 0c             	mov    0xc(%ebp),%eax
80104b77:	89 04 24             	mov    %eax,(%esp)
80104b7a:	e8 f2 02 00 00       	call   80104e71 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104b7f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b85:	8b 55 08             	mov    0x8(%ebp),%edx
80104b88:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104b8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b91:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104b98:	e8 84 fe ff ff       	call   80104a21 <sched>

  // Tidy up.
  proc->chan = 0;
80104b9d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ba3:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104baa:	81 7d 0c 40 ff 10 80 	cmpl   $0x8010ff40,0xc(%ebp)
80104bb1:	74 17                	je     80104bca <sleep+0x99>
    release(&ptable.lock);
80104bb3:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104bba:	e8 b2 02 00 00       	call   80104e71 <release>
    acquire(lk);
80104bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104bc2:	89 04 24             	mov    %eax,(%esp)
80104bc5:	e8 45 02 00 00       	call   80104e0f <acquire>
  }
}
80104bca:	c9                   	leave  
80104bcb:	c3                   	ret    

80104bcc <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104bcc:	55                   	push   %ebp
80104bcd:	89 e5                	mov    %esp,%ebp
80104bcf:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bd2:	c7 45 fc 74 ff 10 80 	movl   $0x8010ff74,-0x4(%ebp)
80104bd9:	eb 24                	jmp    80104bff <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104bdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bde:	8b 40 0c             	mov    0xc(%eax),%eax
80104be1:	83 f8 02             	cmp    $0x2,%eax
80104be4:	75 15                	jne    80104bfb <wakeup1+0x2f>
80104be6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104be9:	8b 40 20             	mov    0x20(%eax),%eax
80104bec:	3b 45 08             	cmp    0x8(%ebp),%eax
80104bef:	75 0a                	jne    80104bfb <wakeup1+0x2f>
      p->state = RUNNABLE;
80104bf1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bf4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bfb:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104bff:	81 7d fc 74 1e 11 80 	cmpl   $0x80111e74,-0x4(%ebp)
80104c06:	72 d3                	jb     80104bdb <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104c08:	c9                   	leave  
80104c09:	c3                   	ret    

80104c0a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104c0a:	55                   	push   %ebp
80104c0b:	89 e5                	mov    %esp,%ebp
80104c0d:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104c10:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104c17:	e8 f3 01 00 00       	call   80104e0f <acquire>
  wakeup1(chan);
80104c1c:	8b 45 08             	mov    0x8(%ebp),%eax
80104c1f:	89 04 24             	mov    %eax,(%esp)
80104c22:	e8 a5 ff ff ff       	call   80104bcc <wakeup1>
  release(&ptable.lock);
80104c27:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104c2e:	e8 3e 02 00 00       	call   80104e71 <release>
}
80104c33:	c9                   	leave  
80104c34:	c3                   	ret    

80104c35 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104c35:	55                   	push   %ebp
80104c36:	89 e5                	mov    %esp,%ebp
80104c38:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104c3b:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104c42:	e8 c8 01 00 00       	call   80104e0f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c47:	c7 45 f4 74 ff 10 80 	movl   $0x8010ff74,-0xc(%ebp)
80104c4e:	eb 41                	jmp    80104c91 <kill+0x5c>
    if(p->pid == pid){
80104c50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c53:	8b 40 10             	mov    0x10(%eax),%eax
80104c56:	3b 45 08             	cmp    0x8(%ebp),%eax
80104c59:	75 32                	jne    80104c8d <kill+0x58>
      p->killed = 1;
80104c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c5e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c68:	8b 40 0c             	mov    0xc(%eax),%eax
80104c6b:	83 f8 02             	cmp    $0x2,%eax
80104c6e:	75 0a                	jne    80104c7a <kill+0x45>
        p->state = RUNNABLE;
80104c70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c73:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104c7a:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104c81:	e8 eb 01 00 00       	call   80104e71 <release>
      return 0;
80104c86:	b8 00 00 00 00       	mov    $0x0,%eax
80104c8b:	eb 1e                	jmp    80104cab <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c8d:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104c91:	81 7d f4 74 1e 11 80 	cmpl   $0x80111e74,-0xc(%ebp)
80104c98:	72 b6                	jb     80104c50 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104c9a:	c7 04 24 40 ff 10 80 	movl   $0x8010ff40,(%esp)
80104ca1:	e8 cb 01 00 00       	call   80104e71 <release>
  return -1;
80104ca6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104cab:	c9                   	leave  
80104cac:	c3                   	ret    

80104cad <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104cad:	55                   	push   %ebp
80104cae:	89 e5                	mov    %esp,%ebp
80104cb0:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cb3:	c7 45 f0 74 ff 10 80 	movl   $0x8010ff74,-0x10(%ebp)
80104cba:	e9 d8 00 00 00       	jmp    80104d97 <procdump+0xea>
    if(p->state == UNUSED)
80104cbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cc2:	8b 40 0c             	mov    0xc(%eax),%eax
80104cc5:	85 c0                	test   %eax,%eax
80104cc7:	0f 84 c5 00 00 00    	je     80104d92 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104ccd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cd0:	8b 40 0c             	mov    0xc(%eax),%eax
80104cd3:	83 f8 05             	cmp    $0x5,%eax
80104cd6:	77 23                	ja     80104cfb <procdump+0x4e>
80104cd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cdb:	8b 40 0c             	mov    0xc(%eax),%eax
80104cde:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104ce5:	85 c0                	test   %eax,%eax
80104ce7:	74 12                	je     80104cfb <procdump+0x4e>
      state = states[p->state];
80104ce9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cec:	8b 40 0c             	mov    0xc(%eax),%eax
80104cef:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104cf6:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104cf9:	eb 07                	jmp    80104d02 <procdump+0x55>
    else
      state = "???";
80104cfb:	c7 45 ec a4 89 10 80 	movl   $0x801089a4,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104d02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d05:	8d 50 6c             	lea    0x6c(%eax),%edx
80104d08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d0b:	8b 40 10             	mov    0x10(%eax),%eax
80104d0e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104d12:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104d15:	89 54 24 08          	mov    %edx,0x8(%esp)
80104d19:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d1d:	c7 04 24 a8 89 10 80 	movl   $0x801089a8,(%esp)
80104d24:	e8 78 b6 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104d29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d2c:	8b 40 0c             	mov    0xc(%eax),%eax
80104d2f:	83 f8 02             	cmp    $0x2,%eax
80104d32:	75 50                	jne    80104d84 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d37:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d3a:	8b 40 0c             	mov    0xc(%eax),%eax
80104d3d:	83 c0 08             	add    $0x8,%eax
80104d40:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104d43:	89 54 24 04          	mov    %edx,0x4(%esp)
80104d47:	89 04 24             	mov    %eax,(%esp)
80104d4a:	e8 71 01 00 00       	call   80104ec0 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104d4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104d56:	eb 1b                	jmp    80104d73 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104d58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d5b:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104d5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80104d63:	c7 04 24 b1 89 10 80 	movl   $0x801089b1,(%esp)
80104d6a:	e8 32 b6 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104d6f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d73:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104d77:	7f 0b                	jg     80104d84 <procdump+0xd7>
80104d79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d7c:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104d80:	85 c0                	test   %eax,%eax
80104d82:	75 d4                	jne    80104d58 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104d84:	c7 04 24 b5 89 10 80 	movl   $0x801089b5,(%esp)
80104d8b:	e8 11 b6 ff ff       	call   801003a1 <cprintf>
80104d90:	eb 01                	jmp    80104d93 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104d92:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d93:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104d97:	81 7d f0 74 1e 11 80 	cmpl   $0x80111e74,-0x10(%ebp)
80104d9e:	0f 82 1b ff ff ff    	jb     80104cbf <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104da4:	c9                   	leave  
80104da5:	c3                   	ret    
	...

80104da8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104da8:	55                   	push   %ebp
80104da9:	89 e5                	mov    %esp,%ebp
80104dab:	53                   	push   %ebx
80104dac:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104daf:	9c                   	pushf  
80104db0:	5b                   	pop    %ebx
80104db1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104db4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104db7:	83 c4 10             	add    $0x10,%esp
80104dba:	5b                   	pop    %ebx
80104dbb:	5d                   	pop    %ebp
80104dbc:	c3                   	ret    

80104dbd <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104dbd:	55                   	push   %ebp
80104dbe:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104dc0:	fa                   	cli    
}
80104dc1:	5d                   	pop    %ebp
80104dc2:	c3                   	ret    

80104dc3 <sti>:

static inline void
sti(void)
{
80104dc3:	55                   	push   %ebp
80104dc4:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104dc6:	fb                   	sti    
}
80104dc7:	5d                   	pop    %ebp
80104dc8:	c3                   	ret    

80104dc9 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104dc9:	55                   	push   %ebp
80104dca:	89 e5                	mov    %esp,%ebp
80104dcc:	53                   	push   %ebx
80104dcd:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104dd0:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104dd6:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104dd9:	89 c3                	mov    %eax,%ebx
80104ddb:	89 d8                	mov    %ebx,%eax
80104ddd:	f0 87 02             	lock xchg %eax,(%edx)
80104de0:	89 c3                	mov    %eax,%ebx
80104de2:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104de5:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104de8:	83 c4 10             	add    $0x10,%esp
80104deb:	5b                   	pop    %ebx
80104dec:	5d                   	pop    %ebp
80104ded:	c3                   	ret    

80104dee <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104dee:	55                   	push   %ebp
80104def:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104df1:	8b 45 08             	mov    0x8(%ebp),%eax
80104df4:	8b 55 0c             	mov    0xc(%ebp),%edx
80104df7:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104dfa:	8b 45 08             	mov    0x8(%ebp),%eax
80104dfd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104e03:	8b 45 08             	mov    0x8(%ebp),%eax
80104e06:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104e0d:	5d                   	pop    %ebp
80104e0e:	c3                   	ret    

80104e0f <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104e0f:	55                   	push   %ebp
80104e10:	89 e5                	mov    %esp,%ebp
80104e12:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104e15:	e8 3d 01 00 00       	call   80104f57 <pushcli>
  if(holding(lk))
80104e1a:	8b 45 08             	mov    0x8(%ebp),%eax
80104e1d:	89 04 24             	mov    %eax,(%esp)
80104e20:	e8 08 01 00 00       	call   80104f2d <holding>
80104e25:	85 c0                	test   %eax,%eax
80104e27:	74 0c                	je     80104e35 <acquire+0x26>
    panic("acquire");
80104e29:	c7 04 24 e1 89 10 80 	movl   $0x801089e1,(%esp)
80104e30:	e8 08 b7 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104e35:	90                   	nop
80104e36:	8b 45 08             	mov    0x8(%ebp),%eax
80104e39:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104e40:	00 
80104e41:	89 04 24             	mov    %eax,(%esp)
80104e44:	e8 80 ff ff ff       	call   80104dc9 <xchg>
80104e49:	85 c0                	test   %eax,%eax
80104e4b:	75 e9                	jne    80104e36 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104e4d:	8b 45 08             	mov    0x8(%ebp),%eax
80104e50:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104e57:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104e5a:	8b 45 08             	mov    0x8(%ebp),%eax
80104e5d:	83 c0 0c             	add    $0xc,%eax
80104e60:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e64:	8d 45 08             	lea    0x8(%ebp),%eax
80104e67:	89 04 24             	mov    %eax,(%esp)
80104e6a:	e8 51 00 00 00       	call   80104ec0 <getcallerpcs>
}
80104e6f:	c9                   	leave  
80104e70:	c3                   	ret    

80104e71 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104e71:	55                   	push   %ebp
80104e72:	89 e5                	mov    %esp,%ebp
80104e74:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104e77:	8b 45 08             	mov    0x8(%ebp),%eax
80104e7a:	89 04 24             	mov    %eax,(%esp)
80104e7d:	e8 ab 00 00 00       	call   80104f2d <holding>
80104e82:	85 c0                	test   %eax,%eax
80104e84:	75 0c                	jne    80104e92 <release+0x21>
    panic("release");
80104e86:	c7 04 24 e9 89 10 80 	movl   $0x801089e9,(%esp)
80104e8d:	e8 ab b6 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104e92:	8b 45 08             	mov    0x8(%ebp),%eax
80104e95:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104e9c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104ea6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ea9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104eb0:	00 
80104eb1:	89 04 24             	mov    %eax,(%esp)
80104eb4:	e8 10 ff ff ff       	call   80104dc9 <xchg>

  popcli();
80104eb9:	e8 e1 00 00 00       	call   80104f9f <popcli>
}
80104ebe:	c9                   	leave  
80104ebf:	c3                   	ret    

80104ec0 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104ec0:	55                   	push   %ebp
80104ec1:	89 e5                	mov    %esp,%ebp
80104ec3:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ec9:	83 e8 08             	sub    $0x8,%eax
80104ecc:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104ecf:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104ed6:	eb 32                	jmp    80104f0a <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104ed8:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104edc:	74 47                	je     80104f25 <getcallerpcs+0x65>
80104ede:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104ee5:	76 3e                	jbe    80104f25 <getcallerpcs+0x65>
80104ee7:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104eeb:	74 38                	je     80104f25 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104eed:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104ef0:	c1 e0 02             	shl    $0x2,%eax
80104ef3:	03 45 0c             	add    0xc(%ebp),%eax
80104ef6:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104ef9:	8b 52 04             	mov    0x4(%edx),%edx
80104efc:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104efe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f01:	8b 00                	mov    (%eax),%eax
80104f03:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104f06:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104f0a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104f0e:	7e c8                	jle    80104ed8 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104f10:	eb 13                	jmp    80104f25 <getcallerpcs+0x65>
    pcs[i] = 0;
80104f12:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f15:	c1 e0 02             	shl    $0x2,%eax
80104f18:	03 45 0c             	add    0xc(%ebp),%eax
80104f1b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104f21:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104f25:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104f29:	7e e7                	jle    80104f12 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104f2b:	c9                   	leave  
80104f2c:	c3                   	ret    

80104f2d <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104f2d:	55                   	push   %ebp
80104f2e:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104f30:	8b 45 08             	mov    0x8(%ebp),%eax
80104f33:	8b 00                	mov    (%eax),%eax
80104f35:	85 c0                	test   %eax,%eax
80104f37:	74 17                	je     80104f50 <holding+0x23>
80104f39:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3c:	8b 50 08             	mov    0x8(%eax),%edx
80104f3f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f45:	39 c2                	cmp    %eax,%edx
80104f47:	75 07                	jne    80104f50 <holding+0x23>
80104f49:	b8 01 00 00 00       	mov    $0x1,%eax
80104f4e:	eb 05                	jmp    80104f55 <holding+0x28>
80104f50:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f55:	5d                   	pop    %ebp
80104f56:	c3                   	ret    

80104f57 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104f57:	55                   	push   %ebp
80104f58:	89 e5                	mov    %esp,%ebp
80104f5a:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104f5d:	e8 46 fe ff ff       	call   80104da8 <readeflags>
80104f62:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104f65:	e8 53 fe ff ff       	call   80104dbd <cli>
  if(cpu->ncli++ == 0)
80104f6a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f70:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104f76:	85 d2                	test   %edx,%edx
80104f78:	0f 94 c1             	sete   %cl
80104f7b:	83 c2 01             	add    $0x1,%edx
80104f7e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104f84:	84 c9                	test   %cl,%cl
80104f86:	74 15                	je     80104f9d <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104f88:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104f8e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104f91:	81 e2 00 02 00 00    	and    $0x200,%edx
80104f97:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104f9d:	c9                   	leave  
80104f9e:	c3                   	ret    

80104f9f <popcli>:

void
popcli(void)
{
80104f9f:	55                   	push   %ebp
80104fa0:	89 e5                	mov    %esp,%ebp
80104fa2:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104fa5:	e8 fe fd ff ff       	call   80104da8 <readeflags>
80104faa:	25 00 02 00 00       	and    $0x200,%eax
80104faf:	85 c0                	test   %eax,%eax
80104fb1:	74 0c                	je     80104fbf <popcli+0x20>
    panic("popcli - interruptible");
80104fb3:	c7 04 24 f1 89 10 80 	movl   $0x801089f1,(%esp)
80104fba:	e8 7e b5 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104fbf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104fc5:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104fcb:	83 ea 01             	sub    $0x1,%edx
80104fce:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104fd4:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104fda:	85 c0                	test   %eax,%eax
80104fdc:	79 0c                	jns    80104fea <popcli+0x4b>
    panic("popcli");
80104fde:	c7 04 24 08 8a 10 80 	movl   $0x80108a08,(%esp)
80104fe5:	e8 53 b5 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104fea:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ff0:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104ff6:	85 c0                	test   %eax,%eax
80104ff8:	75 15                	jne    8010500f <popcli+0x70>
80104ffa:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105000:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105006:	85 c0                	test   %eax,%eax
80105008:	74 05                	je     8010500f <popcli+0x70>
    sti();
8010500a:	e8 b4 fd ff ff       	call   80104dc3 <sti>
}
8010500f:	c9                   	leave  
80105010:	c3                   	ret    
80105011:	00 00                	add    %al,(%eax)
	...

80105014 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105014:	55                   	push   %ebp
80105015:	89 e5                	mov    %esp,%ebp
80105017:	57                   	push   %edi
80105018:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105019:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010501c:	8b 55 10             	mov    0x10(%ebp),%edx
8010501f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105022:	89 cb                	mov    %ecx,%ebx
80105024:	89 df                	mov    %ebx,%edi
80105026:	89 d1                	mov    %edx,%ecx
80105028:	fc                   	cld    
80105029:	f3 aa                	rep stos %al,%es:(%edi)
8010502b:	89 ca                	mov    %ecx,%edx
8010502d:	89 fb                	mov    %edi,%ebx
8010502f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105032:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105035:	5b                   	pop    %ebx
80105036:	5f                   	pop    %edi
80105037:	5d                   	pop    %ebp
80105038:	c3                   	ret    

80105039 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105039:	55                   	push   %ebp
8010503a:	89 e5                	mov    %esp,%ebp
8010503c:	57                   	push   %edi
8010503d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010503e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105041:	8b 55 10             	mov    0x10(%ebp),%edx
80105044:	8b 45 0c             	mov    0xc(%ebp),%eax
80105047:	89 cb                	mov    %ecx,%ebx
80105049:	89 df                	mov    %ebx,%edi
8010504b:	89 d1                	mov    %edx,%ecx
8010504d:	fc                   	cld    
8010504e:	f3 ab                	rep stos %eax,%es:(%edi)
80105050:	89 ca                	mov    %ecx,%edx
80105052:	89 fb                	mov    %edi,%ebx
80105054:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105057:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
8010505a:	5b                   	pop    %ebx
8010505b:	5f                   	pop    %edi
8010505c:	5d                   	pop    %ebp
8010505d:	c3                   	ret    

8010505e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010505e:	55                   	push   %ebp
8010505f:	89 e5                	mov    %esp,%ebp
80105061:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105064:	8b 45 08             	mov    0x8(%ebp),%eax
80105067:	83 e0 03             	and    $0x3,%eax
8010506a:	85 c0                	test   %eax,%eax
8010506c:	75 49                	jne    801050b7 <memset+0x59>
8010506e:	8b 45 10             	mov    0x10(%ebp),%eax
80105071:	83 e0 03             	and    $0x3,%eax
80105074:	85 c0                	test   %eax,%eax
80105076:	75 3f                	jne    801050b7 <memset+0x59>
    c &= 0xFF;
80105078:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010507f:	8b 45 10             	mov    0x10(%ebp),%eax
80105082:	c1 e8 02             	shr    $0x2,%eax
80105085:	89 c2                	mov    %eax,%edx
80105087:	8b 45 0c             	mov    0xc(%ebp),%eax
8010508a:	89 c1                	mov    %eax,%ecx
8010508c:	c1 e1 18             	shl    $0x18,%ecx
8010508f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105092:	c1 e0 10             	shl    $0x10,%eax
80105095:	09 c1                	or     %eax,%ecx
80105097:	8b 45 0c             	mov    0xc(%ebp),%eax
8010509a:	c1 e0 08             	shl    $0x8,%eax
8010509d:	09 c8                	or     %ecx,%eax
8010509f:	0b 45 0c             	or     0xc(%ebp),%eax
801050a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801050a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801050aa:	8b 45 08             	mov    0x8(%ebp),%eax
801050ad:	89 04 24             	mov    %eax,(%esp)
801050b0:	e8 84 ff ff ff       	call   80105039 <stosl>
801050b5:	eb 19                	jmp    801050d0 <memset+0x72>
  } else
    stosb(dst, c, n);
801050b7:	8b 45 10             	mov    0x10(%ebp),%eax
801050ba:	89 44 24 08          	mov    %eax,0x8(%esp)
801050be:	8b 45 0c             	mov    0xc(%ebp),%eax
801050c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801050c5:	8b 45 08             	mov    0x8(%ebp),%eax
801050c8:	89 04 24             	mov    %eax,(%esp)
801050cb:	e8 44 ff ff ff       	call   80105014 <stosb>
  return dst;
801050d0:	8b 45 08             	mov    0x8(%ebp),%eax
}
801050d3:	c9                   	leave  
801050d4:	c3                   	ret    

801050d5 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801050d5:	55                   	push   %ebp
801050d6:	89 e5                	mov    %esp,%ebp
801050d8:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801050db:	8b 45 08             	mov    0x8(%ebp),%eax
801050de:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801050e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801050e4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801050e7:	eb 32                	jmp    8010511b <memcmp+0x46>
    if(*s1 != *s2)
801050e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050ec:	0f b6 10             	movzbl (%eax),%edx
801050ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050f2:	0f b6 00             	movzbl (%eax),%eax
801050f5:	38 c2                	cmp    %al,%dl
801050f7:	74 1a                	je     80105113 <memcmp+0x3e>
      return *s1 - *s2;
801050f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050fc:	0f b6 00             	movzbl (%eax),%eax
801050ff:	0f b6 d0             	movzbl %al,%edx
80105102:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105105:	0f b6 00             	movzbl (%eax),%eax
80105108:	0f b6 c0             	movzbl %al,%eax
8010510b:	89 d1                	mov    %edx,%ecx
8010510d:	29 c1                	sub    %eax,%ecx
8010510f:	89 c8                	mov    %ecx,%eax
80105111:	eb 1c                	jmp    8010512f <memcmp+0x5a>
    s1++, s2++;
80105113:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105117:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
8010511b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010511f:	0f 95 c0             	setne  %al
80105122:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105126:	84 c0                	test   %al,%al
80105128:	75 bf                	jne    801050e9 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
8010512a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010512f:	c9                   	leave  
80105130:	c3                   	ret    

80105131 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105131:	55                   	push   %ebp
80105132:	89 e5                	mov    %esp,%ebp
80105134:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105137:	8b 45 0c             	mov    0xc(%ebp),%eax
8010513a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
8010513d:	8b 45 08             	mov    0x8(%ebp),%eax
80105140:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105143:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105146:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105149:	73 54                	jae    8010519f <memmove+0x6e>
8010514b:	8b 45 10             	mov    0x10(%ebp),%eax
8010514e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105151:	01 d0                	add    %edx,%eax
80105153:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105156:	76 47                	jbe    8010519f <memmove+0x6e>
    s += n;
80105158:	8b 45 10             	mov    0x10(%ebp),%eax
8010515b:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010515e:	8b 45 10             	mov    0x10(%ebp),%eax
80105161:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105164:	eb 13                	jmp    80105179 <memmove+0x48>
      *--d = *--s;
80105166:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
8010516a:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010516e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105171:	0f b6 10             	movzbl (%eax),%edx
80105174:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105177:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105179:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010517d:	0f 95 c0             	setne  %al
80105180:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105184:	84 c0                	test   %al,%al
80105186:	75 de                	jne    80105166 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105188:	eb 25                	jmp    801051af <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
8010518a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010518d:	0f b6 10             	movzbl (%eax),%edx
80105190:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105193:	88 10                	mov    %dl,(%eax)
80105195:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105199:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010519d:	eb 01                	jmp    801051a0 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010519f:	90                   	nop
801051a0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801051a4:	0f 95 c0             	setne  %al
801051a7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801051ab:	84 c0                	test   %al,%al
801051ad:	75 db                	jne    8010518a <memmove+0x59>
      *d++ = *s++;

  return dst;
801051af:	8b 45 08             	mov    0x8(%ebp),%eax
}
801051b2:	c9                   	leave  
801051b3:	c3                   	ret    

801051b4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801051b4:	55                   	push   %ebp
801051b5:	89 e5                	mov    %esp,%ebp
801051b7:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801051ba:	8b 45 10             	mov    0x10(%ebp),%eax
801051bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801051c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801051c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801051c8:	8b 45 08             	mov    0x8(%ebp),%eax
801051cb:	89 04 24             	mov    %eax,(%esp)
801051ce:	e8 5e ff ff ff       	call   80105131 <memmove>
}
801051d3:	c9                   	leave  
801051d4:	c3                   	ret    

801051d5 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801051d5:	55                   	push   %ebp
801051d6:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801051d8:	eb 0c                	jmp    801051e6 <strncmp+0x11>
    n--, p++, q++;
801051da:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801051de:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801051e2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801051e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801051ea:	74 1a                	je     80105206 <strncmp+0x31>
801051ec:	8b 45 08             	mov    0x8(%ebp),%eax
801051ef:	0f b6 00             	movzbl (%eax),%eax
801051f2:	84 c0                	test   %al,%al
801051f4:	74 10                	je     80105206 <strncmp+0x31>
801051f6:	8b 45 08             	mov    0x8(%ebp),%eax
801051f9:	0f b6 10             	movzbl (%eax),%edx
801051fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801051ff:	0f b6 00             	movzbl (%eax),%eax
80105202:	38 c2                	cmp    %al,%dl
80105204:	74 d4                	je     801051da <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105206:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010520a:	75 07                	jne    80105213 <strncmp+0x3e>
    return 0;
8010520c:	b8 00 00 00 00       	mov    $0x0,%eax
80105211:	eb 18                	jmp    8010522b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105213:	8b 45 08             	mov    0x8(%ebp),%eax
80105216:	0f b6 00             	movzbl (%eax),%eax
80105219:	0f b6 d0             	movzbl %al,%edx
8010521c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010521f:	0f b6 00             	movzbl (%eax),%eax
80105222:	0f b6 c0             	movzbl %al,%eax
80105225:	89 d1                	mov    %edx,%ecx
80105227:	29 c1                	sub    %eax,%ecx
80105229:	89 c8                	mov    %ecx,%eax
}
8010522b:	5d                   	pop    %ebp
8010522c:	c3                   	ret    

8010522d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010522d:	55                   	push   %ebp
8010522e:	89 e5                	mov    %esp,%ebp
80105230:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105233:	8b 45 08             	mov    0x8(%ebp),%eax
80105236:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105239:	90                   	nop
8010523a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010523e:	0f 9f c0             	setg   %al
80105241:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105245:	84 c0                	test   %al,%al
80105247:	74 30                	je     80105279 <strncpy+0x4c>
80105249:	8b 45 0c             	mov    0xc(%ebp),%eax
8010524c:	0f b6 10             	movzbl (%eax),%edx
8010524f:	8b 45 08             	mov    0x8(%ebp),%eax
80105252:	88 10                	mov    %dl,(%eax)
80105254:	8b 45 08             	mov    0x8(%ebp),%eax
80105257:	0f b6 00             	movzbl (%eax),%eax
8010525a:	84 c0                	test   %al,%al
8010525c:	0f 95 c0             	setne  %al
8010525f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105263:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105267:	84 c0                	test   %al,%al
80105269:	75 cf                	jne    8010523a <strncpy+0xd>
    ;
  while(n-- > 0)
8010526b:	eb 0c                	jmp    80105279 <strncpy+0x4c>
    *s++ = 0;
8010526d:	8b 45 08             	mov    0x8(%ebp),%eax
80105270:	c6 00 00             	movb   $0x0,(%eax)
80105273:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105277:	eb 01                	jmp    8010527a <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105279:	90                   	nop
8010527a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010527e:	0f 9f c0             	setg   %al
80105281:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105285:	84 c0                	test   %al,%al
80105287:	75 e4                	jne    8010526d <strncpy+0x40>
    *s++ = 0;
  return os;
80105289:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010528c:	c9                   	leave  
8010528d:	c3                   	ret    

8010528e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010528e:	55                   	push   %ebp
8010528f:	89 e5                	mov    %esp,%ebp
80105291:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105294:	8b 45 08             	mov    0x8(%ebp),%eax
80105297:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
8010529a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010529e:	7f 05                	jg     801052a5 <safestrcpy+0x17>
    return os;
801052a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052a3:	eb 35                	jmp    801052da <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801052a5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801052a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801052ad:	7e 22                	jle    801052d1 <safestrcpy+0x43>
801052af:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b2:	0f b6 10             	movzbl (%eax),%edx
801052b5:	8b 45 08             	mov    0x8(%ebp),%eax
801052b8:	88 10                	mov    %dl,(%eax)
801052ba:	8b 45 08             	mov    0x8(%ebp),%eax
801052bd:	0f b6 00             	movzbl (%eax),%eax
801052c0:	84 c0                	test   %al,%al
801052c2:	0f 95 c0             	setne  %al
801052c5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801052c9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801052cd:	84 c0                	test   %al,%al
801052cf:	75 d4                	jne    801052a5 <safestrcpy+0x17>
    ;
  *s = 0;
801052d1:	8b 45 08             	mov    0x8(%ebp),%eax
801052d4:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801052d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801052da:	c9                   	leave  
801052db:	c3                   	ret    

801052dc <strlen>:

int
strlen(const char *s)
{
801052dc:	55                   	push   %ebp
801052dd:	89 e5                	mov    %esp,%ebp
801052df:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801052e2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801052e9:	eb 04                	jmp    801052ef <strlen+0x13>
801052eb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801052ef:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052f2:	03 45 08             	add    0x8(%ebp),%eax
801052f5:	0f b6 00             	movzbl (%eax),%eax
801052f8:	84 c0                	test   %al,%al
801052fa:	75 ef                	jne    801052eb <strlen+0xf>
    ;
  return n;
801052fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801052ff:	c9                   	leave  
80105300:	c3                   	ret    
80105301:	00 00                	add    %al,(%eax)
	...

80105304 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105304:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105308:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010530c:	55                   	push   %ebp
  pushl %ebx
8010530d:	53                   	push   %ebx
  pushl %esi
8010530e:	56                   	push   %esi
  pushl %edi
8010530f:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105310:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105312:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105314:	5f                   	pop    %edi
  popl %esi
80105315:	5e                   	pop    %esi
  popl %ebx
80105316:	5b                   	pop    %ebx
  popl %ebp
80105317:	5d                   	pop    %ebp
  ret
80105318:	c3                   	ret    
80105319:	00 00                	add    %al,(%eax)
	...

8010531c <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
8010531c:	55                   	push   %ebp
8010531d:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010531f:	8b 45 08             	mov    0x8(%ebp),%eax
80105322:	8b 00                	mov    (%eax),%eax
80105324:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105327:	76 0f                	jbe    80105338 <fetchint+0x1c>
80105329:	8b 45 0c             	mov    0xc(%ebp),%eax
8010532c:	8d 50 04             	lea    0x4(%eax),%edx
8010532f:	8b 45 08             	mov    0x8(%ebp),%eax
80105332:	8b 00                	mov    (%eax),%eax
80105334:	39 c2                	cmp    %eax,%edx
80105336:	76 07                	jbe    8010533f <fetchint+0x23>
    return -1;
80105338:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010533d:	eb 0f                	jmp    8010534e <fetchint+0x32>
  *ip = *(int*)(addr);
8010533f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105342:	8b 10                	mov    (%eax),%edx
80105344:	8b 45 10             	mov    0x10(%ebp),%eax
80105347:	89 10                	mov    %edx,(%eax)
  return 0;
80105349:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010534e:	5d                   	pop    %ebp
8010534f:	c3                   	ret    

80105350 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
80105350:	55                   	push   %ebp
80105351:	89 e5                	mov    %esp,%ebp
80105353:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105356:	8b 45 08             	mov    0x8(%ebp),%eax
80105359:	8b 00                	mov    (%eax),%eax
8010535b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010535e:	77 07                	ja     80105367 <fetchstr+0x17>
    return -1;
80105360:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105365:	eb 45                	jmp    801053ac <fetchstr+0x5c>
  *pp = (char*)addr;
80105367:	8b 55 0c             	mov    0xc(%ebp),%edx
8010536a:	8b 45 10             	mov    0x10(%ebp),%eax
8010536d:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010536f:	8b 45 08             	mov    0x8(%ebp),%eax
80105372:	8b 00                	mov    (%eax),%eax
80105374:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105377:	8b 45 10             	mov    0x10(%ebp),%eax
8010537a:	8b 00                	mov    (%eax),%eax
8010537c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010537f:	eb 1e                	jmp    8010539f <fetchstr+0x4f>
    if(*s == 0)
80105381:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105384:	0f b6 00             	movzbl (%eax),%eax
80105387:	84 c0                	test   %al,%al
80105389:	75 10                	jne    8010539b <fetchstr+0x4b>
      return s - *pp;
8010538b:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010538e:	8b 45 10             	mov    0x10(%ebp),%eax
80105391:	8b 00                	mov    (%eax),%eax
80105393:	89 d1                	mov    %edx,%ecx
80105395:	29 c1                	sub    %eax,%ecx
80105397:	89 c8                	mov    %ecx,%eax
80105399:	eb 11                	jmp    801053ac <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
8010539b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010539f:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053a2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801053a5:	72 da                	jb     80105381 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801053a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801053ac:	c9                   	leave  
801053ad:	c3                   	ret    

801053ae <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801053ae:	55                   	push   %ebp
801053af:	89 e5                	mov    %esp,%ebp
801053b1:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801053b4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053ba:	8b 40 18             	mov    0x18(%eax),%eax
801053bd:	8b 50 44             	mov    0x44(%eax),%edx
801053c0:	8b 45 08             	mov    0x8(%ebp),%eax
801053c3:	c1 e0 02             	shl    $0x2,%eax
801053c6:	01 d0                	add    %edx,%eax
801053c8:	8d 48 04             	lea    0x4(%eax),%ecx
801053cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d1:	8b 55 0c             	mov    0xc(%ebp),%edx
801053d4:	89 54 24 08          	mov    %edx,0x8(%esp)
801053d8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801053dc:	89 04 24             	mov    %eax,(%esp)
801053df:	e8 38 ff ff ff       	call   8010531c <fetchint>
}
801053e4:	c9                   	leave  
801053e5:	c3                   	ret    

801053e6 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801053e6:	55                   	push   %ebp
801053e7:	89 e5                	mov    %esp,%ebp
801053e9:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801053ec:	8d 45 fc             	lea    -0x4(%ebp),%eax
801053ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f3:	8b 45 08             	mov    0x8(%ebp),%eax
801053f6:	89 04 24             	mov    %eax,(%esp)
801053f9:	e8 b0 ff ff ff       	call   801053ae <argint>
801053fe:	85 c0                	test   %eax,%eax
80105400:	79 07                	jns    80105409 <argptr+0x23>
    return -1;
80105402:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105407:	eb 3d                	jmp    80105446 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105409:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010540c:	89 c2                	mov    %eax,%edx
8010540e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105414:	8b 00                	mov    (%eax),%eax
80105416:	39 c2                	cmp    %eax,%edx
80105418:	73 16                	jae    80105430 <argptr+0x4a>
8010541a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010541d:	89 c2                	mov    %eax,%edx
8010541f:	8b 45 10             	mov    0x10(%ebp),%eax
80105422:	01 c2                	add    %eax,%edx
80105424:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010542a:	8b 00                	mov    (%eax),%eax
8010542c:	39 c2                	cmp    %eax,%edx
8010542e:	76 07                	jbe    80105437 <argptr+0x51>
    return -1;
80105430:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105435:	eb 0f                	jmp    80105446 <argptr+0x60>
  *pp = (char*)i;
80105437:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010543a:	89 c2                	mov    %eax,%edx
8010543c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010543f:	89 10                	mov    %edx,(%eax)
  return 0;
80105441:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105446:	c9                   	leave  
80105447:	c3                   	ret    

80105448 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105448:	55                   	push   %ebp
80105449:	89 e5                	mov    %esp,%ebp
8010544b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010544e:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105451:	89 44 24 04          	mov    %eax,0x4(%esp)
80105455:	8b 45 08             	mov    0x8(%ebp),%eax
80105458:	89 04 24             	mov    %eax,(%esp)
8010545b:	e8 4e ff ff ff       	call   801053ae <argint>
80105460:	85 c0                	test   %eax,%eax
80105462:	79 07                	jns    8010546b <argstr+0x23>
    return -1;
80105464:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105469:	eb 1e                	jmp    80105489 <argstr+0x41>
  return fetchstr(proc, addr, pp);
8010546b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010546e:	89 c2                	mov    %eax,%edx
80105470:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105476:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105479:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010547d:	89 54 24 04          	mov    %edx,0x4(%esp)
80105481:	89 04 24             	mov    %eax,(%esp)
80105484:	e8 c7 fe ff ff       	call   80105350 <fetchstr>
}
80105489:	c9                   	leave  
8010548a:	c3                   	ret    

8010548b <syscall>:
[SYS_getSharedBlocksRate] sys_getSharedBlocksRate,
};

void
syscall(void)
{
8010548b:	55                   	push   %ebp
8010548c:	89 e5                	mov    %esp,%ebp
8010548e:	53                   	push   %ebx
8010548f:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
80105492:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105498:	8b 40 18             	mov    0x18(%eax),%eax
8010549b:	8b 40 1c             	mov    0x1c(%eax),%eax
8010549e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801054a1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801054a5:	78 2e                	js     801054d5 <syscall+0x4a>
801054a7:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801054ab:	7f 28                	jg     801054d5 <syscall+0x4a>
801054ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054b0:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801054b7:	85 c0                	test   %eax,%eax
801054b9:	74 1a                	je     801054d5 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801054bb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054c1:	8b 58 18             	mov    0x18(%eax),%ebx
801054c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054c7:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801054ce:	ff d0                	call   *%eax
801054d0:	89 43 1c             	mov    %eax,0x1c(%ebx)
801054d3:	eb 73                	jmp    80105548 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801054d5:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801054d9:	7e 30                	jle    8010550b <syscall+0x80>
801054db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054de:	83 f8 18             	cmp    $0x18,%eax
801054e1:	77 28                	ja     8010550b <syscall+0x80>
801054e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054e6:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801054ed:	85 c0                	test   %eax,%eax
801054ef:	74 1a                	je     8010550b <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801054f1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054f7:	8b 58 18             	mov    0x18(%eax),%ebx
801054fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054fd:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105504:	ff d0                	call   *%eax
80105506:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105509:	eb 3d                	jmp    80105548 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010550b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105511:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105514:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010551a:	8b 40 10             	mov    0x10(%eax),%eax
8010551d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105520:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105524:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105528:	89 44 24 04          	mov    %eax,0x4(%esp)
8010552c:	c7 04 24 0f 8a 10 80 	movl   $0x80108a0f,(%esp)
80105533:	e8 69 ae ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105538:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010553e:	8b 40 18             	mov    0x18(%eax),%eax
80105541:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105548:	83 c4 24             	add    $0x24,%esp
8010554b:	5b                   	pop    %ebx
8010554c:	5d                   	pop    %ebp
8010554d:	c3                   	ret    
	...

80105550 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105550:	55                   	push   %ebp
80105551:	89 e5                	mov    %esp,%ebp
80105553:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105556:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105559:	89 44 24 04          	mov    %eax,0x4(%esp)
8010555d:	8b 45 08             	mov    0x8(%ebp),%eax
80105560:	89 04 24             	mov    %eax,(%esp)
80105563:	e8 46 fe ff ff       	call   801053ae <argint>
80105568:	85 c0                	test   %eax,%eax
8010556a:	79 07                	jns    80105573 <argfd+0x23>
    return -1;
8010556c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105571:	eb 50                	jmp    801055c3 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105573:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105576:	85 c0                	test   %eax,%eax
80105578:	78 21                	js     8010559b <argfd+0x4b>
8010557a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010557d:	83 f8 0f             	cmp    $0xf,%eax
80105580:	7f 19                	jg     8010559b <argfd+0x4b>
80105582:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105588:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010558b:	83 c2 08             	add    $0x8,%edx
8010558e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105592:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105595:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105599:	75 07                	jne    801055a2 <argfd+0x52>
    return -1;
8010559b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055a0:	eb 21                	jmp    801055c3 <argfd+0x73>
  if(pfd)
801055a2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801055a6:	74 08                	je     801055b0 <argfd+0x60>
    *pfd = fd;
801055a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801055ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801055ae:	89 10                	mov    %edx,(%eax)
  if(pf)
801055b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055b4:	74 08                	je     801055be <argfd+0x6e>
    *pf = f;
801055b6:	8b 45 10             	mov    0x10(%ebp),%eax
801055b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055bc:	89 10                	mov    %edx,(%eax)
  return 0;
801055be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055c3:	c9                   	leave  
801055c4:	c3                   	ret    

801055c5 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801055c5:	55                   	push   %ebp
801055c6:	89 e5                	mov    %esp,%ebp
801055c8:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801055cb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801055d2:	eb 30                	jmp    80105604 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801055d4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055da:	8b 55 fc             	mov    -0x4(%ebp),%edx
801055dd:	83 c2 08             	add    $0x8,%edx
801055e0:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801055e4:	85 c0                	test   %eax,%eax
801055e6:	75 18                	jne    80105600 <fdalloc+0x3b>
      proc->ofile[fd] = f;
801055e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055ee:	8b 55 fc             	mov    -0x4(%ebp),%edx
801055f1:	8d 4a 08             	lea    0x8(%edx),%ecx
801055f4:	8b 55 08             	mov    0x8(%ebp),%edx
801055f7:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801055fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055fe:	eb 0f                	jmp    8010560f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105600:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105604:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105608:	7e ca                	jle    801055d4 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010560a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010560f:	c9                   	leave  
80105610:	c3                   	ret    

80105611 <sys_dup>:

int
sys_dup(void)
{
80105611:	55                   	push   %ebp
80105612:	89 e5                	mov    %esp,%ebp
80105614:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105617:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010561a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010561e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105625:	00 
80105626:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010562d:	e8 1e ff ff ff       	call   80105550 <argfd>
80105632:	85 c0                	test   %eax,%eax
80105634:	79 07                	jns    8010563d <sys_dup+0x2c>
    return -1;
80105636:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010563b:	eb 29                	jmp    80105666 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010563d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105640:	89 04 24             	mov    %eax,(%esp)
80105643:	e8 7d ff ff ff       	call   801055c5 <fdalloc>
80105648:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010564b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010564f:	79 07                	jns    80105658 <sys_dup+0x47>
    return -1;
80105651:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105656:	eb 0e                	jmp    80105666 <sys_dup+0x55>
  filedup(f);
80105658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010565b:	89 04 24             	mov    %eax,(%esp)
8010565e:	e8 19 b9 ff ff       	call   80100f7c <filedup>
  return fd;
80105663:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105666:	c9                   	leave  
80105667:	c3                   	ret    

80105668 <sys_read>:

int
sys_read(void)
{
80105668:	55                   	push   %ebp
80105669:	89 e5                	mov    %esp,%ebp
8010566b:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010566e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105671:	89 44 24 08          	mov    %eax,0x8(%esp)
80105675:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010567c:	00 
8010567d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105684:	e8 c7 fe ff ff       	call   80105550 <argfd>
80105689:	85 c0                	test   %eax,%eax
8010568b:	78 35                	js     801056c2 <sys_read+0x5a>
8010568d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105690:	89 44 24 04          	mov    %eax,0x4(%esp)
80105694:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010569b:	e8 0e fd ff ff       	call   801053ae <argint>
801056a0:	85 c0                	test   %eax,%eax
801056a2:	78 1e                	js     801056c2 <sys_read+0x5a>
801056a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801056ab:	8d 45 ec             	lea    -0x14(%ebp),%eax
801056ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801056b2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801056b9:	e8 28 fd ff ff       	call   801053e6 <argptr>
801056be:	85 c0                	test   %eax,%eax
801056c0:	79 07                	jns    801056c9 <sys_read+0x61>
    return -1;
801056c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056c7:	eb 19                	jmp    801056e2 <sys_read+0x7a>
  return fileread(f, p, n);
801056c9:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801056cc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801056cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056d2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801056d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801056da:	89 04 24             	mov    %eax,(%esp)
801056dd:	e8 07 ba ff ff       	call   801010e9 <fileread>
}
801056e2:	c9                   	leave  
801056e3:	c3                   	ret    

801056e4 <sys_write>:

int
sys_write(void)
{
801056e4:	55                   	push   %ebp
801056e5:	89 e5                	mov    %esp,%ebp
801056e7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801056ea:	8d 45 f4             	lea    -0xc(%ebp),%eax
801056ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801056f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801056f8:	00 
801056f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105700:	e8 4b fe ff ff       	call   80105550 <argfd>
80105705:	85 c0                	test   %eax,%eax
80105707:	78 35                	js     8010573e <sys_write+0x5a>
80105709:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010570c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105710:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105717:	e8 92 fc ff ff       	call   801053ae <argint>
8010571c:	85 c0                	test   %eax,%eax
8010571e:	78 1e                	js     8010573e <sys_write+0x5a>
80105720:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105723:	89 44 24 08          	mov    %eax,0x8(%esp)
80105727:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010572a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010572e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105735:	e8 ac fc ff ff       	call   801053e6 <argptr>
8010573a:	85 c0                	test   %eax,%eax
8010573c:	79 07                	jns    80105745 <sys_write+0x61>
    return -1;
8010573e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105743:	eb 19                	jmp    8010575e <sys_write+0x7a>
  return filewrite(f, p, n);
80105745:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105748:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010574b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010574e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105752:	89 54 24 04          	mov    %edx,0x4(%esp)
80105756:	89 04 24             	mov    %eax,(%esp)
80105759:	e8 47 ba ff ff       	call   801011a5 <filewrite>
}
8010575e:	c9                   	leave  
8010575f:	c3                   	ret    

80105760 <sys_close>:

int
sys_close(void)
{
80105760:	55                   	push   %ebp
80105761:	89 e5                	mov    %esp,%ebp
80105763:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105766:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105769:	89 44 24 08          	mov    %eax,0x8(%esp)
8010576d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105770:	89 44 24 04          	mov    %eax,0x4(%esp)
80105774:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010577b:	e8 d0 fd ff ff       	call   80105550 <argfd>
80105780:	85 c0                	test   %eax,%eax
80105782:	79 07                	jns    8010578b <sys_close+0x2b>
    return -1;
80105784:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105789:	eb 24                	jmp    801057af <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010578b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105791:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105794:	83 c2 08             	add    $0x8,%edx
80105797:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010579e:	00 
  fileclose(f);
8010579f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057a2:	89 04 24             	mov    %eax,(%esp)
801057a5:	e8 1a b8 ff ff       	call   80100fc4 <fileclose>
  return 0;
801057aa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801057af:	c9                   	leave  
801057b0:	c3                   	ret    

801057b1 <sys_fstat>:

int
sys_fstat(void)
{
801057b1:	55                   	push   %ebp
801057b2:	89 e5                	mov    %esp,%ebp
801057b4:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801057b7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057ba:	89 44 24 08          	mov    %eax,0x8(%esp)
801057be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057c5:	00 
801057c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057cd:	e8 7e fd ff ff       	call   80105550 <argfd>
801057d2:	85 c0                	test   %eax,%eax
801057d4:	78 1f                	js     801057f5 <sys_fstat+0x44>
801057d6:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801057dd:	00 
801057de:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801057e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801057ec:	e8 f5 fb ff ff       	call   801053e6 <argptr>
801057f1:	85 c0                	test   %eax,%eax
801057f3:	79 07                	jns    801057fc <sys_fstat+0x4b>
    return -1;
801057f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057fa:	eb 12                	jmp    8010580e <sys_fstat+0x5d>
  return filestat(f, st);
801057fc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801057ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105802:	89 54 24 04          	mov    %edx,0x4(%esp)
80105806:	89 04 24             	mov    %eax,(%esp)
80105809:	e8 8c b8 ff ff       	call   8010109a <filestat>
}
8010580e:	c9                   	leave  
8010580f:	c3                   	ret    

80105810 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105810:	55                   	push   %ebp
80105811:	89 e5                	mov    %esp,%ebp
80105813:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105816:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105819:	89 44 24 04          	mov    %eax,0x4(%esp)
8010581d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105824:	e8 1f fc ff ff       	call   80105448 <argstr>
80105829:	85 c0                	test   %eax,%eax
8010582b:	78 17                	js     80105844 <sys_link+0x34>
8010582d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105830:	89 44 24 04          	mov    %eax,0x4(%esp)
80105834:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010583b:	e8 08 fc ff ff       	call   80105448 <argstr>
80105840:	85 c0                	test   %eax,%eax
80105842:	79 0a                	jns    8010584e <sys_link+0x3e>
    return -1;
80105844:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105849:	e9 3c 01 00 00       	jmp    8010598a <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010584e:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105851:	89 04 24             	mov    %eax,(%esp)
80105854:	e8 1d ce ff ff       	call   80102676 <namei>
80105859:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010585c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105860:	75 0a                	jne    8010586c <sys_link+0x5c>
    return -1;
80105862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105867:	e9 1e 01 00 00       	jmp    8010598a <sys_link+0x17a>

  begin_trans();
8010586c:	e8 18 dc ff ff       	call   80103489 <begin_trans>

  ilock(ip);
80105871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105874:	89 04 24             	mov    %eax,(%esp)
80105877:	e8 58 c2 ff ff       	call   80101ad4 <ilock>
  if(ip->type == T_DIR){
8010587c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010587f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105883:	66 83 f8 01          	cmp    $0x1,%ax
80105887:	75 1a                	jne    801058a3 <sys_link+0x93>
    iunlockput(ip);
80105889:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010588c:	89 04 24             	mov    %eax,(%esp)
8010588f:	e8 c4 c4 ff ff       	call   80101d58 <iunlockput>
    commit_trans();
80105894:	e8 39 dc ff ff       	call   801034d2 <commit_trans>
    return -1;
80105899:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010589e:	e9 e7 00 00 00       	jmp    8010598a <sys_link+0x17a>
  }

  ip->nlink++;
801058a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058a6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801058aa:	8d 50 01             	lea    0x1(%eax),%edx
801058ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b0:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801058b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058b7:	89 04 24             	mov    %eax,(%esp)
801058ba:	e8 59 c0 ff ff       	call   80101918 <iupdate>
  iunlock(ip);
801058bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058c2:	89 04 24             	mov    %eax,(%esp)
801058c5:	e8 58 c3 ff ff       	call   80101c22 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
801058ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
801058cd:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801058d0:	89 54 24 04          	mov    %edx,0x4(%esp)
801058d4:	89 04 24             	mov    %eax,(%esp)
801058d7:	e8 bc cd ff ff       	call   80102698 <nameiparent>
801058dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801058df:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058e3:	74 68                	je     8010594d <sys_link+0x13d>
    goto bad;
  ilock(dp);
801058e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058e8:	89 04 24             	mov    %eax,(%esp)
801058eb:	e8 e4 c1 ff ff       	call   80101ad4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801058f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058f3:	8b 10                	mov    (%eax),%edx
801058f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f8:	8b 00                	mov    (%eax),%eax
801058fa:	39 c2                	cmp    %eax,%edx
801058fc:	75 20                	jne    8010591e <sys_link+0x10e>
801058fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105901:	8b 40 04             	mov    0x4(%eax),%eax
80105904:	89 44 24 08          	mov    %eax,0x8(%esp)
80105908:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010590b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010590f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105912:	89 04 24             	mov    %eax,(%esp)
80105915:	e8 9b ca ff ff       	call   801023b5 <dirlink>
8010591a:	85 c0                	test   %eax,%eax
8010591c:	79 0d                	jns    8010592b <sys_link+0x11b>
    iunlockput(dp);
8010591e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105921:	89 04 24             	mov    %eax,(%esp)
80105924:	e8 2f c4 ff ff       	call   80101d58 <iunlockput>
    goto bad;
80105929:	eb 23                	jmp    8010594e <sys_link+0x13e>
  }
  iunlockput(dp);
8010592b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010592e:	89 04 24             	mov    %eax,(%esp)
80105931:	e8 22 c4 ff ff       	call   80101d58 <iunlockput>
  iput(ip);
80105936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105939:	89 04 24             	mov    %eax,(%esp)
8010593c:	e8 46 c3 ff ff       	call   80101c87 <iput>

  commit_trans();
80105941:	e8 8c db ff ff       	call   801034d2 <commit_trans>

  return 0;
80105946:	b8 00 00 00 00       	mov    $0x0,%eax
8010594b:	eb 3d                	jmp    8010598a <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
8010594d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010594e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105951:	89 04 24             	mov    %eax,(%esp)
80105954:	e8 7b c1 ff ff       	call   80101ad4 <ilock>
  ip->nlink--;
80105959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010595c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105960:	8d 50 ff             	lea    -0x1(%eax),%edx
80105963:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105966:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010596a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010596d:	89 04 24             	mov    %eax,(%esp)
80105970:	e8 a3 bf ff ff       	call   80101918 <iupdate>
  iunlockput(ip);
80105975:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105978:	89 04 24             	mov    %eax,(%esp)
8010597b:	e8 d8 c3 ff ff       	call   80101d58 <iunlockput>
  commit_trans();
80105980:	e8 4d db ff ff       	call   801034d2 <commit_trans>
  return -1;
80105985:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010598a:	c9                   	leave  
8010598b:	c3                   	ret    

8010598c <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010598c:	55                   	push   %ebp
8010598d:	89 e5                	mov    %esp,%ebp
8010598f:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105992:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105999:	eb 4b                	jmp    801059e6 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010599b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010599e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801059a5:	00 
801059a6:	89 44 24 08          	mov    %eax,0x8(%esp)
801059aa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801059ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801059b1:	8b 45 08             	mov    0x8(%ebp),%eax
801059b4:	89 04 24             	mov    %eax,(%esp)
801059b7:	e8 0e c6 ff ff       	call   80101fca <readi>
801059bc:	83 f8 10             	cmp    $0x10,%eax
801059bf:	74 0c                	je     801059cd <isdirempty+0x41>
      panic("isdirempty: readi");
801059c1:	c7 04 24 2b 8a 10 80 	movl   $0x80108a2b,(%esp)
801059c8:	e8 70 ab ff ff       	call   8010053d <panic>
    if(de.inum != 0)
801059cd:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
801059d1:	66 85 c0             	test   %ax,%ax
801059d4:	74 07                	je     801059dd <isdirempty+0x51>
      return 0;
801059d6:	b8 00 00 00 00       	mov    $0x0,%eax
801059db:	eb 1b                	jmp    801059f8 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801059dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059e0:	83 c0 10             	add    $0x10,%eax
801059e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801059e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801059e9:	8b 45 08             	mov    0x8(%ebp),%eax
801059ec:	8b 40 18             	mov    0x18(%eax),%eax
801059ef:	39 c2                	cmp    %eax,%edx
801059f1:	72 a8                	jb     8010599b <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
801059f3:	b8 01 00 00 00       	mov    $0x1,%eax
}
801059f8:	c9                   	leave  
801059f9:	c3                   	ret    

801059fa <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
801059fa:	55                   	push   %ebp
801059fb:	89 e5                	mov    %esp,%ebp
801059fd:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105a00:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105a03:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a0e:	e8 35 fa ff ff       	call   80105448 <argstr>
80105a13:	85 c0                	test   %eax,%eax
80105a15:	79 0a                	jns    80105a21 <sys_unlink+0x27>
    return -1;
80105a17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a1c:	e9 aa 01 00 00       	jmp    80105bcb <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105a21:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105a24:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105a27:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a2b:	89 04 24             	mov    %eax,(%esp)
80105a2e:	e8 65 cc ff ff       	call   80102698 <nameiparent>
80105a33:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a36:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a3a:	75 0a                	jne    80105a46 <sys_unlink+0x4c>
    return -1;
80105a3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a41:	e9 85 01 00 00       	jmp    80105bcb <sys_unlink+0x1d1>

  begin_trans();
80105a46:	e8 3e da ff ff       	call   80103489 <begin_trans>

  ilock(dp);
80105a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4e:	89 04 24             	mov    %eax,(%esp)
80105a51:	e8 7e c0 ff ff       	call   80101ad4 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105a56:	c7 44 24 04 3d 8a 10 	movl   $0x80108a3d,0x4(%esp)
80105a5d:	80 
80105a5e:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105a61:	89 04 24             	mov    %eax,(%esp)
80105a64:	e8 62 c8 ff ff       	call   801022cb <namecmp>
80105a69:	85 c0                	test   %eax,%eax
80105a6b:	0f 84 45 01 00 00    	je     80105bb6 <sys_unlink+0x1bc>
80105a71:	c7 44 24 04 3f 8a 10 	movl   $0x80108a3f,0x4(%esp)
80105a78:	80 
80105a79:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105a7c:	89 04 24             	mov    %eax,(%esp)
80105a7f:	e8 47 c8 ff ff       	call   801022cb <namecmp>
80105a84:	85 c0                	test   %eax,%eax
80105a86:	0f 84 2a 01 00 00    	je     80105bb6 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105a8c:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105a8f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a93:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105a96:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a9d:	89 04 24             	mov    %eax,(%esp)
80105aa0:	e8 48 c8 ff ff       	call   801022ed <dirlookup>
80105aa5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105aa8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105aac:	0f 84 03 01 00 00    	je     80105bb5 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105ab2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ab5:	89 04 24             	mov    %eax,(%esp)
80105ab8:	e8 17 c0 ff ff       	call   80101ad4 <ilock>

  if(ip->nlink < 1)
80105abd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ac0:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ac4:	66 85 c0             	test   %ax,%ax
80105ac7:	7f 0c                	jg     80105ad5 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105ac9:	c7 04 24 42 8a 10 80 	movl   $0x80108a42,(%esp)
80105ad0:	e8 68 aa ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105ad5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ad8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105adc:	66 83 f8 01          	cmp    $0x1,%ax
80105ae0:	75 1f                	jne    80105b01 <sys_unlink+0x107>
80105ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ae5:	89 04 24             	mov    %eax,(%esp)
80105ae8:	e8 9f fe ff ff       	call   8010598c <isdirempty>
80105aed:	85 c0                	test   %eax,%eax
80105aef:	75 10                	jne    80105b01 <sys_unlink+0x107>
    iunlockput(ip);
80105af1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105af4:	89 04 24             	mov    %eax,(%esp)
80105af7:	e8 5c c2 ff ff       	call   80101d58 <iunlockput>
    goto bad;
80105afc:	e9 b5 00 00 00       	jmp    80105bb6 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105b01:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105b08:	00 
80105b09:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105b10:	00 
80105b11:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105b14:	89 04 24             	mov    %eax,(%esp)
80105b17:	e8 42 f5 ff ff       	call   8010505e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105b1c:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105b1f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105b26:	00 
80105b27:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b2b:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105b2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b35:	89 04 24             	mov    %eax,(%esp)
80105b38:	e8 f8 c5 ff ff       	call   80102135 <writei>
80105b3d:	83 f8 10             	cmp    $0x10,%eax
80105b40:	74 0c                	je     80105b4e <sys_unlink+0x154>
    panic("unlink: writei");
80105b42:	c7 04 24 54 8a 10 80 	movl   $0x80108a54,(%esp)
80105b49:	e8 ef a9 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105b4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b51:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105b55:	66 83 f8 01          	cmp    $0x1,%ax
80105b59:	75 1c                	jne    80105b77 <sys_unlink+0x17d>
    dp->nlink--;
80105b5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b62:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b68:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105b6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b6f:	89 04 24             	mov    %eax,(%esp)
80105b72:	e8 a1 bd ff ff       	call   80101918 <iupdate>
  }
  iunlockput(dp);
80105b77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b7a:	89 04 24             	mov    %eax,(%esp)
80105b7d:	e8 d6 c1 ff ff       	call   80101d58 <iunlockput>

  ip->nlink--;
80105b82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b85:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b89:	8d 50 ff             	lea    -0x1(%eax),%edx
80105b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b8f:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b96:	89 04 24             	mov    %eax,(%esp)
80105b99:	e8 7a bd ff ff       	call   80101918 <iupdate>
  iunlockput(ip);
80105b9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba1:	89 04 24             	mov    %eax,(%esp)
80105ba4:	e8 af c1 ff ff       	call   80101d58 <iunlockput>

  commit_trans();
80105ba9:	e8 24 d9 ff ff       	call   801034d2 <commit_trans>

  return 0;
80105bae:	b8 00 00 00 00       	mov    $0x0,%eax
80105bb3:	eb 16                	jmp    80105bcb <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105bb5:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105bb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb9:	89 04 24             	mov    %eax,(%esp)
80105bbc:	e8 97 c1 ff ff       	call   80101d58 <iunlockput>
  commit_trans();
80105bc1:	e8 0c d9 ff ff       	call   801034d2 <commit_trans>
  return -1;
80105bc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105bcb:	c9                   	leave  
80105bcc:	c3                   	ret    

80105bcd <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105bcd:	55                   	push   %ebp
80105bce:	89 e5                	mov    %esp,%ebp
80105bd0:	83 ec 48             	sub    $0x48,%esp
80105bd3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105bd6:	8b 55 10             	mov    0x10(%ebp),%edx
80105bd9:	8b 45 14             	mov    0x14(%ebp),%eax
80105bdc:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105be0:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105be4:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105be8:	8d 45 de             	lea    -0x22(%ebp),%eax
80105beb:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bef:	8b 45 08             	mov    0x8(%ebp),%eax
80105bf2:	89 04 24             	mov    %eax,(%esp)
80105bf5:	e8 9e ca ff ff       	call   80102698 <nameiparent>
80105bfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bfd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c01:	75 0a                	jne    80105c0d <create+0x40>
    return 0;
80105c03:	b8 00 00 00 00       	mov    $0x0,%eax
80105c08:	e9 7e 01 00 00       	jmp    80105d8b <create+0x1be>
  ilock(dp);
80105c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c10:	89 04 24             	mov    %eax,(%esp)
80105c13:	e8 bc be ff ff       	call   80101ad4 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105c18:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105c1b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c1f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105c22:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c29:	89 04 24             	mov    %eax,(%esp)
80105c2c:	e8 bc c6 ff ff       	call   801022ed <dirlookup>
80105c31:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c34:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c38:	74 47                	je     80105c81 <create+0xb4>
    iunlockput(dp);
80105c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3d:	89 04 24             	mov    %eax,(%esp)
80105c40:	e8 13 c1 ff ff       	call   80101d58 <iunlockput>
    ilock(ip);
80105c45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c48:	89 04 24             	mov    %eax,(%esp)
80105c4b:	e8 84 be ff ff       	call   80101ad4 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105c50:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105c55:	75 15                	jne    80105c6c <create+0x9f>
80105c57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c5a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c5e:	66 83 f8 02          	cmp    $0x2,%ax
80105c62:	75 08                	jne    80105c6c <create+0x9f>
      return ip;
80105c64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c67:	e9 1f 01 00 00       	jmp    80105d8b <create+0x1be>
    iunlockput(ip);
80105c6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c6f:	89 04 24             	mov    %eax,(%esp)
80105c72:	e8 e1 c0 ff ff       	call   80101d58 <iunlockput>
    return 0;
80105c77:	b8 00 00 00 00       	mov    $0x0,%eax
80105c7c:	e9 0a 01 00 00       	jmp    80105d8b <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105c81:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105c85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c88:	8b 00                	mov    (%eax),%eax
80105c8a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105c8e:	89 04 24             	mov    %eax,(%esp)
80105c91:	e8 a5 bb ff ff       	call   8010183b <ialloc>
80105c96:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c99:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c9d:	75 0c                	jne    80105cab <create+0xde>
    panic("create: ialloc");
80105c9f:	c7 04 24 63 8a 10 80 	movl   $0x80108a63,(%esp)
80105ca6:	e8 92 a8 ff ff       	call   8010053d <panic>

  ilock(ip);
80105cab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cae:	89 04 24             	mov    %eax,(%esp)
80105cb1:	e8 1e be ff ff       	call   80101ad4 <ilock>
  ip->major = major;
80105cb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cb9:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105cbd:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105cc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc4:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105cc8:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105ccc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ccf:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105cd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cd8:	89 04 24             	mov    %eax,(%esp)
80105cdb:	e8 38 bc ff ff       	call   80101918 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105ce0:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105ce5:	75 6a                	jne    80105d51 <create+0x184>
    dp->nlink++;  // for ".."
80105ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cea:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105cee:	8d 50 01             	lea    0x1(%eax),%edx
80105cf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cf4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105cf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cfb:	89 04 24             	mov    %eax,(%esp)
80105cfe:	e8 15 bc ff ff       	call   80101918 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105d03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d06:	8b 40 04             	mov    0x4(%eax),%eax
80105d09:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d0d:	c7 44 24 04 3d 8a 10 	movl   $0x80108a3d,0x4(%esp)
80105d14:	80 
80105d15:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d18:	89 04 24             	mov    %eax,(%esp)
80105d1b:	e8 95 c6 ff ff       	call   801023b5 <dirlink>
80105d20:	85 c0                	test   %eax,%eax
80105d22:	78 21                	js     80105d45 <create+0x178>
80105d24:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d27:	8b 40 04             	mov    0x4(%eax),%eax
80105d2a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d2e:	c7 44 24 04 3f 8a 10 	movl   $0x80108a3f,0x4(%esp)
80105d35:	80 
80105d36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d39:	89 04 24             	mov    %eax,(%esp)
80105d3c:	e8 74 c6 ff ff       	call   801023b5 <dirlink>
80105d41:	85 c0                	test   %eax,%eax
80105d43:	79 0c                	jns    80105d51 <create+0x184>
      panic("create dots");
80105d45:	c7 04 24 72 8a 10 80 	movl   $0x80108a72,(%esp)
80105d4c:	e8 ec a7 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105d51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d54:	8b 40 04             	mov    0x4(%eax),%eax
80105d57:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d5b:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d62:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d65:	89 04 24             	mov    %eax,(%esp)
80105d68:	e8 48 c6 ff ff       	call   801023b5 <dirlink>
80105d6d:	85 c0                	test   %eax,%eax
80105d6f:	79 0c                	jns    80105d7d <create+0x1b0>
    panic("create: dirlink");
80105d71:	c7 04 24 7e 8a 10 80 	movl   $0x80108a7e,(%esp)
80105d78:	e8 c0 a7 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d80:	89 04 24             	mov    %eax,(%esp)
80105d83:	e8 d0 bf ff ff       	call   80101d58 <iunlockput>

  return ip;
80105d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105d8b:	c9                   	leave  
80105d8c:	c3                   	ret    

80105d8d <fileopen>:

struct file*
fileopen(char* path, int omode)
{
80105d8d:	55                   	push   %ebp
80105d8e:	89 e5                	mov    %esp,%ebp
80105d90:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct inode *ip;

  if(omode & O_CREATE){
80105d93:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d96:	25 00 02 00 00       	and    $0x200,%eax
80105d9b:	85 c0                	test   %eax,%eax
80105d9d:	74 40                	je     80105ddf <fileopen+0x52>
    begin_trans();
80105d9f:	e8 e5 d6 ff ff       	call   80103489 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105da4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105dab:	00 
80105dac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105db3:	00 
80105db4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105dbb:	00 
80105dbc:	8b 45 08             	mov    0x8(%ebp),%eax
80105dbf:	89 04 24             	mov    %eax,(%esp)
80105dc2:	e8 06 fe ff ff       	call   80105bcd <create>
80105dc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105dca:	e8 03 d7 ff ff       	call   801034d2 <commit_trans>
    if(ip == 0)
80105dcf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105dd3:	75 5b                	jne    80105e30 <fileopen+0xa3>
      return 0;
80105dd5:	b8 00 00 00 00       	mov    $0x0,%eax
80105dda:	e9 e5 00 00 00       	jmp    80105ec4 <fileopen+0x137>
  } else {
    if((ip = namei(path)) == 0)
80105ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80105de2:	89 04 24             	mov    %eax,(%esp)
80105de5:	e8 8c c8 ff ff       	call   80102676 <namei>
80105dea:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ded:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105df1:	75 0a                	jne    80105dfd <fileopen+0x70>
      return 0;
80105df3:	b8 00 00 00 00       	mov    $0x0,%eax
80105df8:	e9 c7 00 00 00       	jmp    80105ec4 <fileopen+0x137>
    ilock(ip);
80105dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e00:	89 04 24             	mov    %eax,(%esp)
80105e03:	e8 cc bc ff ff       	call   80101ad4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105e08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e0b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105e0f:	66 83 f8 01          	cmp    $0x1,%ax
80105e13:	75 1b                	jne    80105e30 <fileopen+0xa3>
80105e15:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80105e19:	74 15                	je     80105e30 <fileopen+0xa3>
      iunlockput(ip);
80105e1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e1e:	89 04 24             	mov    %eax,(%esp)
80105e21:	e8 32 bf ff ff       	call   80101d58 <iunlockput>
      return 0;
80105e26:	b8 00 00 00 00       	mov    $0x0,%eax
80105e2b:	e9 94 00 00 00       	jmp    80105ec4 <fileopen+0x137>
    }
  }

  if((f = filealloc()) == 0 ){
80105e30:	e8 e7 b0 ff ff       	call   80100f1c <filealloc>
80105e35:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e38:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e3c:	75 23                	jne    80105e61 <fileopen+0xd4>
    if(f)
80105e3e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e42:	74 0b                	je     80105e4f <fileopen+0xc2>
      fileclose(f);
80105e44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e47:	89 04 24             	mov    %eax,(%esp)
80105e4a:	e8 75 b1 ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80105e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e52:	89 04 24             	mov    %eax,(%esp)
80105e55:	e8 fe be ff ff       	call   80101d58 <iunlockput>
    return 0;
80105e5a:	b8 00 00 00 00       	mov    $0x0,%eax
80105e5f:	eb 63                	jmp    80105ec4 <fileopen+0x137>
  }
  iunlock(ip);
80105e61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e64:	89 04 24             	mov    %eax,(%esp)
80105e67:	e8 b6 bd ff ff       	call   80101c22 <iunlock>

  f->type = FD_INODE;
80105e6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e6f:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105e7b:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105e7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e81:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105e88:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e8b:	83 e0 01             	and    $0x1,%eax
80105e8e:	85 c0                	test   %eax,%eax
80105e90:	0f 94 c2             	sete   %dl
80105e93:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e96:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105e99:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e9c:	83 e0 01             	and    $0x1,%eax
80105e9f:	84 c0                	test   %al,%al
80105ea1:	75 0a                	jne    80105ead <fileopen+0x120>
80105ea3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ea6:	83 e0 02             	and    $0x2,%eax
80105ea9:	85 c0                	test   %eax,%eax
80105eab:	74 07                	je     80105eb4 <fileopen+0x127>
80105ead:	b8 01 00 00 00       	mov    $0x1,%eax
80105eb2:	eb 05                	jmp    80105eb9 <fileopen+0x12c>
80105eb4:	b8 00 00 00 00       	mov    $0x0,%eax
80105eb9:	89 c2                	mov    %eax,%edx
80105ebb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ebe:	88 50 09             	mov    %dl,0x9(%eax)
  return f;
80105ec1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105ec4:	c9                   	leave  
80105ec5:	c3                   	ret    

80105ec6 <sys_open>:

int
sys_open(void)
{
80105ec6:	55                   	push   %ebp
80105ec7:	89 e5                	mov    %esp,%ebp
80105ec9:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105ecc:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105ecf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ed3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105eda:	e8 69 f5 ff ff       	call   80105448 <argstr>
80105edf:	85 c0                	test   %eax,%eax
80105ee1:	78 17                	js     80105efa <sys_open+0x34>
80105ee3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105ee6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105eea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ef1:	e8 b8 f4 ff ff       	call   801053ae <argint>
80105ef6:	85 c0                	test   %eax,%eax
80105ef8:	79 0a                	jns    80105f04 <sys_open+0x3e>
    return -1;
80105efa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eff:	e9 46 01 00 00       	jmp    8010604a <sys_open+0x184>
  if(omode & O_CREATE){
80105f04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f07:	25 00 02 00 00       	and    $0x200,%eax
80105f0c:	85 c0                	test   %eax,%eax
80105f0e:	74 40                	je     80105f50 <sys_open+0x8a>
    begin_trans();
80105f10:	e8 74 d5 ff ff       	call   80103489 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105f15:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f18:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105f1f:	00 
80105f20:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105f27:	00 
80105f28:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105f2f:	00 
80105f30:	89 04 24             	mov    %eax,(%esp)
80105f33:	e8 95 fc ff ff       	call   80105bcd <create>
80105f38:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105f3b:	e8 92 d5 ff ff       	call   801034d2 <commit_trans>
    if(ip == 0)
80105f40:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f44:	75 5c                	jne    80105fa2 <sys_open+0xdc>
      return -1;
80105f46:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f4b:	e9 fa 00 00 00       	jmp    8010604a <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105f50:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f53:	89 04 24             	mov    %eax,(%esp)
80105f56:	e8 1b c7 ff ff       	call   80102676 <namei>
80105f5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f5e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f62:	75 0a                	jne    80105f6e <sys_open+0xa8>
      return -1;
80105f64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f69:	e9 dc 00 00 00       	jmp    8010604a <sys_open+0x184>
    ilock(ip);
80105f6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f71:	89 04 24             	mov    %eax,(%esp)
80105f74:	e8 5b bb ff ff       	call   80101ad4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f7c:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f80:	66 83 f8 01          	cmp    $0x1,%ax
80105f84:	75 1c                	jne    80105fa2 <sys_open+0xdc>
80105f86:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f89:	85 c0                	test   %eax,%eax
80105f8b:	74 15                	je     80105fa2 <sys_open+0xdc>
      iunlockput(ip);
80105f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f90:	89 04 24             	mov    %eax,(%esp)
80105f93:	e8 c0 bd ff ff       	call   80101d58 <iunlockput>
      return -1;
80105f98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f9d:	e9 a8 00 00 00       	jmp    8010604a <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105fa2:	e8 75 af ff ff       	call   80100f1c <filealloc>
80105fa7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105faa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fae:	74 14                	je     80105fc4 <sys_open+0xfe>
80105fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fb3:	89 04 24             	mov    %eax,(%esp)
80105fb6:	e8 0a f6 ff ff       	call   801055c5 <fdalloc>
80105fbb:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105fbe:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105fc2:	79 23                	jns    80105fe7 <sys_open+0x121>
    if(f)
80105fc4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105fc8:	74 0b                	je     80105fd5 <sys_open+0x10f>
      fileclose(f);
80105fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fcd:	89 04 24             	mov    %eax,(%esp)
80105fd0:	e8 ef af ff ff       	call   80100fc4 <fileclose>
    iunlockput(ip);
80105fd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fd8:	89 04 24             	mov    %eax,(%esp)
80105fdb:	e8 78 bd ff ff       	call   80101d58 <iunlockput>
    return -1;
80105fe0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fe5:	eb 63                	jmp    8010604a <sys_open+0x184>
  }
  iunlock(ip);
80105fe7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fea:	89 04 24             	mov    %eax,(%esp)
80105fed:	e8 30 bc ff ff       	call   80101c22 <iunlock>

  f->type = FD_INODE;
80105ff2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ff5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105ffb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ffe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106001:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106004:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106007:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
8010600e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106011:	83 e0 01             	and    $0x1,%eax
80106014:	85 c0                	test   %eax,%eax
80106016:	0f 94 c2             	sete   %dl
80106019:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010601c:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010601f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106022:	83 e0 01             	and    $0x1,%eax
80106025:	84 c0                	test   %al,%al
80106027:	75 0a                	jne    80106033 <sys_open+0x16d>
80106029:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010602c:	83 e0 02             	and    $0x2,%eax
8010602f:	85 c0                	test   %eax,%eax
80106031:	74 07                	je     8010603a <sys_open+0x174>
80106033:	b8 01 00 00 00       	mov    $0x1,%eax
80106038:	eb 05                	jmp    8010603f <sys_open+0x179>
8010603a:	b8 00 00 00 00       	mov    $0x0,%eax
8010603f:	89 c2                	mov    %eax,%edx
80106041:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106044:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106047:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010604a:	c9                   	leave  
8010604b:	c3                   	ret    

8010604c <sys_mkdir>:

int
sys_mkdir(void)
{
8010604c:	55                   	push   %ebp
8010604d:	89 e5                	mov    %esp,%ebp
8010604f:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106052:	e8 32 d4 ff ff       	call   80103489 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106057:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010605a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010605e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106065:	e8 de f3 ff ff       	call   80105448 <argstr>
8010606a:	85 c0                	test   %eax,%eax
8010606c:	78 2c                	js     8010609a <sys_mkdir+0x4e>
8010606e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106071:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106078:	00 
80106079:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106080:	00 
80106081:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106088:	00 
80106089:	89 04 24             	mov    %eax,(%esp)
8010608c:	e8 3c fb ff ff       	call   80105bcd <create>
80106091:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106094:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106098:	75 0c                	jne    801060a6 <sys_mkdir+0x5a>
    commit_trans();
8010609a:	e8 33 d4 ff ff       	call   801034d2 <commit_trans>
    return -1;
8010609f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060a4:	eb 15                	jmp    801060bb <sys_mkdir+0x6f>
  }
  iunlockput(ip);
801060a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060a9:	89 04 24             	mov    %eax,(%esp)
801060ac:	e8 a7 bc ff ff       	call   80101d58 <iunlockput>
  commit_trans();
801060b1:	e8 1c d4 ff ff       	call   801034d2 <commit_trans>
  return 0;
801060b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060bb:	c9                   	leave  
801060bc:	c3                   	ret    

801060bd <sys_mknod>:

int
sys_mknod(void)
{
801060bd:	55                   	push   %ebp
801060be:	89 e5                	mov    %esp,%ebp
801060c0:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
801060c3:	e8 c1 d3 ff ff       	call   80103489 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
801060c8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801060cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060d6:	e8 6d f3 ff ff       	call   80105448 <argstr>
801060db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060de:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060e2:	78 5e                	js     80106142 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801060e4:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801060eb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801060f2:	e8 b7 f2 ff ff       	call   801053ae <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801060f7:	85 c0                	test   %eax,%eax
801060f9:	78 47                	js     80106142 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060fb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801060fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80106102:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106109:	e8 a0 f2 ff ff       	call   801053ae <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010610e:	85 c0                	test   %eax,%eax
80106110:	78 30                	js     80106142 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106112:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106115:	0f bf c8             	movswl %ax,%ecx
80106118:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010611b:	0f bf d0             	movswl %ax,%edx
8010611e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106121:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106125:	89 54 24 08          	mov    %edx,0x8(%esp)
80106129:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106130:	00 
80106131:	89 04 24             	mov    %eax,(%esp)
80106134:	e8 94 fa ff ff       	call   80105bcd <create>
80106139:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010613c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106140:	75 0c                	jne    8010614e <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106142:	e8 8b d3 ff ff       	call   801034d2 <commit_trans>
    return -1;
80106147:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010614c:	eb 15                	jmp    80106163 <sys_mknod+0xa6>
  }
  iunlockput(ip);
8010614e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106151:	89 04 24             	mov    %eax,(%esp)
80106154:	e8 ff bb ff ff       	call   80101d58 <iunlockput>
  commit_trans();
80106159:	e8 74 d3 ff ff       	call   801034d2 <commit_trans>
  return 0;
8010615e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106163:	c9                   	leave  
80106164:	c3                   	ret    

80106165 <sys_chdir>:

int
sys_chdir(void)
{
80106165:	55                   	push   %ebp
80106166:	89 e5                	mov    %esp,%ebp
80106168:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
8010616b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010616e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106172:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106179:	e8 ca f2 ff ff       	call   80105448 <argstr>
8010617e:	85 c0                	test   %eax,%eax
80106180:	78 14                	js     80106196 <sys_chdir+0x31>
80106182:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106185:	89 04 24             	mov    %eax,(%esp)
80106188:	e8 e9 c4 ff ff       	call   80102676 <namei>
8010618d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106190:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106194:	75 07                	jne    8010619d <sys_chdir+0x38>
    return -1;
80106196:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010619b:	eb 57                	jmp    801061f4 <sys_chdir+0x8f>
  ilock(ip);
8010619d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061a0:	89 04 24             	mov    %eax,(%esp)
801061a3:	e8 2c b9 ff ff       	call   80101ad4 <ilock>
  if(ip->type != T_DIR){
801061a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ab:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801061af:	66 83 f8 01          	cmp    $0x1,%ax
801061b3:	74 12                	je     801061c7 <sys_chdir+0x62>
    iunlockput(ip);
801061b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b8:	89 04 24             	mov    %eax,(%esp)
801061bb:	e8 98 bb ff ff       	call   80101d58 <iunlockput>
    return -1;
801061c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c5:	eb 2d                	jmp    801061f4 <sys_chdir+0x8f>
  }
  iunlock(ip);
801061c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ca:	89 04 24             	mov    %eax,(%esp)
801061cd:	e8 50 ba ff ff       	call   80101c22 <iunlock>
  iput(proc->cwd);
801061d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061d8:	8b 40 68             	mov    0x68(%eax),%eax
801061db:	89 04 24             	mov    %eax,(%esp)
801061de:	e8 a4 ba ff ff       	call   80101c87 <iput>
  proc->cwd = ip;
801061e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801061ec:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801061ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061f4:	c9                   	leave  
801061f5:	c3                   	ret    

801061f6 <sys_exec>:

int
sys_exec(void)
{
801061f6:	55                   	push   %ebp
801061f7:	89 e5                	mov    %esp,%ebp
801061f9:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801061ff:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106202:	89 44 24 04          	mov    %eax,0x4(%esp)
80106206:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010620d:	e8 36 f2 ff ff       	call   80105448 <argstr>
80106212:	85 c0                	test   %eax,%eax
80106214:	78 1a                	js     80106230 <sys_exec+0x3a>
80106216:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
8010621c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106220:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106227:	e8 82 f1 ff ff       	call   801053ae <argint>
8010622c:	85 c0                	test   %eax,%eax
8010622e:	79 0a                	jns    8010623a <sys_exec+0x44>
    return -1;
80106230:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106235:	e9 e2 00 00 00       	jmp    8010631c <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
8010623a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106241:	00 
80106242:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106249:	00 
8010624a:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106250:	89 04 24             	mov    %eax,(%esp)
80106253:	e8 06 ee ff ff       	call   8010505e <memset>
  for(i=0;; i++){
80106258:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010625f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106262:	83 f8 1f             	cmp    $0x1f,%eax
80106265:	76 0a                	jbe    80106271 <sys_exec+0x7b>
      return -1;
80106267:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010626c:	e9 ab 00 00 00       	jmp    8010631c <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106271:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106274:	c1 e0 02             	shl    $0x2,%eax
80106277:	89 c2                	mov    %eax,%edx
80106279:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010627f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106282:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106288:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
8010628e:	89 54 24 08          	mov    %edx,0x8(%esp)
80106292:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106296:	89 04 24             	mov    %eax,(%esp)
80106299:	e8 7e f0 ff ff       	call   8010531c <fetchint>
8010629e:	85 c0                	test   %eax,%eax
801062a0:	79 07                	jns    801062a9 <sys_exec+0xb3>
      return -1;
801062a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062a7:	eb 73                	jmp    8010631c <sys_exec+0x126>
    if(uarg == 0){
801062a9:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062af:	85 c0                	test   %eax,%eax
801062b1:	75 26                	jne    801062d9 <sys_exec+0xe3>
      argv[i] = 0;
801062b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062b6:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
801062bd:	00 00 00 00 
      break;
801062c1:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
801062c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062c5:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801062cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801062cf:	89 04 24             	mov    %eax,(%esp)
801062d2:	e8 25 a8 ff ff       	call   80100afc <exec>
801062d7:	eb 43                	jmp    8010631c <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801062d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062dc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801062e3:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062e9:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801062ec:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801062f2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062fc:	89 54 24 04          	mov    %edx,0x4(%esp)
80106300:	89 04 24             	mov    %eax,(%esp)
80106303:	e8 48 f0 ff ff       	call   80105350 <fetchstr>
80106308:	85 c0                	test   %eax,%eax
8010630a:	79 07                	jns    80106313 <sys_exec+0x11d>
      return -1;
8010630c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106311:	eb 09                	jmp    8010631c <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106313:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
80106317:	e9 43 ff ff ff       	jmp    8010625f <sys_exec+0x69>
  return exec(path, argv);
}
8010631c:	c9                   	leave  
8010631d:	c3                   	ret    

8010631e <sys_pipe>:

int
sys_pipe(void)
{
8010631e:	55                   	push   %ebp
8010631f:	89 e5                	mov    %esp,%ebp
80106321:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106324:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010632b:	00 
8010632c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010632f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106333:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010633a:	e8 a7 f0 ff ff       	call   801053e6 <argptr>
8010633f:	85 c0                	test   %eax,%eax
80106341:	79 0a                	jns    8010634d <sys_pipe+0x2f>
    return -1;
80106343:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106348:	e9 9b 00 00 00       	jmp    801063e8 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
8010634d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106350:	89 44 24 04          	mov    %eax,0x4(%esp)
80106354:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106357:	89 04 24             	mov    %eax,(%esp)
8010635a:	e8 45 db ff ff       	call   80103ea4 <pipealloc>
8010635f:	85 c0                	test   %eax,%eax
80106361:	79 07                	jns    8010636a <sys_pipe+0x4c>
    return -1;
80106363:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106368:	eb 7e                	jmp    801063e8 <sys_pipe+0xca>
  fd0 = -1;
8010636a:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106371:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106374:	89 04 24             	mov    %eax,(%esp)
80106377:	e8 49 f2 ff ff       	call   801055c5 <fdalloc>
8010637c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010637f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106383:	78 14                	js     80106399 <sys_pipe+0x7b>
80106385:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106388:	89 04 24             	mov    %eax,(%esp)
8010638b:	e8 35 f2 ff ff       	call   801055c5 <fdalloc>
80106390:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106393:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106397:	79 37                	jns    801063d0 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010639d:	78 14                	js     801063b3 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010639f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801063a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063a8:	83 c2 08             	add    $0x8,%edx
801063ab:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801063b2:	00 
    fileclose(rf);
801063b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063b6:	89 04 24             	mov    %eax,(%esp)
801063b9:	e8 06 ac ff ff       	call   80100fc4 <fileclose>
    fileclose(wf);
801063be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063c1:	89 04 24             	mov    %eax,(%esp)
801063c4:	e8 fb ab ff ff       	call   80100fc4 <fileclose>
    return -1;
801063c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063ce:	eb 18                	jmp    801063e8 <sys_pipe+0xca>
  }
  fd[0] = fd0;
801063d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063d6:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801063d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063db:	8d 50 04             	lea    0x4(%eax),%edx
801063de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063e1:	89 02                	mov    %eax,(%edx)
  return 0;
801063e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063e8:	c9                   	leave  
801063e9:	c3                   	ret    
	...

801063ec <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801063ec:	55                   	push   %ebp
801063ed:	89 e5                	mov    %esp,%ebp
801063ef:	83 ec 08             	sub    $0x8,%esp
  return fork();
801063f2:	e8 67 e1 ff ff       	call   8010455e <fork>
}
801063f7:	c9                   	leave  
801063f8:	c3                   	ret    

801063f9 <sys_exit>:

int
sys_exit(void)
{
801063f9:	55                   	push   %ebp
801063fa:	89 e5                	mov    %esp,%ebp
801063fc:	83 ec 08             	sub    $0x8,%esp
  exit();
801063ff:	e8 bd e2 ff ff       	call   801046c1 <exit>
  return 0;  // not reached
80106404:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106409:	c9                   	leave  
8010640a:	c3                   	ret    

8010640b <sys_wait>:

int
sys_wait(void)
{
8010640b:	55                   	push   %ebp
8010640c:	89 e5                	mov    %esp,%ebp
8010640e:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106411:	e8 c3 e3 ff ff       	call   801047d9 <wait>
}
80106416:	c9                   	leave  
80106417:	c3                   	ret    

80106418 <sys_kill>:

int
sys_kill(void)
{
80106418:	55                   	push   %ebp
80106419:	89 e5                	mov    %esp,%ebp
8010641b:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
8010641e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106421:	89 44 24 04          	mov    %eax,0x4(%esp)
80106425:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010642c:	e8 7d ef ff ff       	call   801053ae <argint>
80106431:	85 c0                	test   %eax,%eax
80106433:	79 07                	jns    8010643c <sys_kill+0x24>
    return -1;
80106435:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010643a:	eb 0b                	jmp    80106447 <sys_kill+0x2f>
  return kill(pid);
8010643c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010643f:	89 04 24             	mov    %eax,(%esp)
80106442:	e8 ee e7 ff ff       	call   80104c35 <kill>
}
80106447:	c9                   	leave  
80106448:	c3                   	ret    

80106449 <sys_getpid>:

int
sys_getpid(void)
{
80106449:	55                   	push   %ebp
8010644a:	89 e5                	mov    %esp,%ebp
  return proc->pid;
8010644c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106452:	8b 40 10             	mov    0x10(%eax),%eax
}
80106455:	5d                   	pop    %ebp
80106456:	c3                   	ret    

80106457 <sys_sbrk>:

int
sys_sbrk(void)
{
80106457:	55                   	push   %ebp
80106458:	89 e5                	mov    %esp,%ebp
8010645a:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
8010645d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106460:	89 44 24 04          	mov    %eax,0x4(%esp)
80106464:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010646b:	e8 3e ef ff ff       	call   801053ae <argint>
80106470:	85 c0                	test   %eax,%eax
80106472:	79 07                	jns    8010647b <sys_sbrk+0x24>
    return -1;
80106474:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106479:	eb 24                	jmp    8010649f <sys_sbrk+0x48>
  addr = proc->sz;
8010647b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106481:	8b 00                	mov    (%eax),%eax
80106483:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
80106486:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106489:	89 04 24             	mov    %eax,(%esp)
8010648c:	e8 28 e0 ff ff       	call   801044b9 <growproc>
80106491:	85 c0                	test   %eax,%eax
80106493:	79 07                	jns    8010649c <sys_sbrk+0x45>
    return -1;
80106495:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010649a:	eb 03                	jmp    8010649f <sys_sbrk+0x48>
  return addr;
8010649c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010649f:	c9                   	leave  
801064a0:	c3                   	ret    

801064a1 <sys_sleep>:

int
sys_sleep(void)
{
801064a1:	55                   	push   %ebp
801064a2:	89 e5                	mov    %esp,%ebp
801064a4:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801064a7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064aa:	89 44 24 04          	mov    %eax,0x4(%esp)
801064ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064b5:	e8 f4 ee ff ff       	call   801053ae <argint>
801064ba:	85 c0                	test   %eax,%eax
801064bc:	79 07                	jns    801064c5 <sys_sleep+0x24>
    return -1;
801064be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064c3:	eb 6c                	jmp    80106531 <sys_sleep+0x90>
  acquire(&tickslock);
801064c5:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
801064cc:	e8 3e e9 ff ff       	call   80104e0f <acquire>
  ticks0 = ticks;
801064d1:	a1 c0 26 11 80       	mov    0x801126c0,%eax
801064d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801064d9:	eb 34                	jmp    8010650f <sys_sleep+0x6e>
    if(proc->killed){
801064db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064e1:	8b 40 24             	mov    0x24(%eax),%eax
801064e4:	85 c0                	test   %eax,%eax
801064e6:	74 13                	je     801064fb <sys_sleep+0x5a>
      release(&tickslock);
801064e8:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
801064ef:	e8 7d e9 ff ff       	call   80104e71 <release>
      return -1;
801064f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064f9:	eb 36                	jmp    80106531 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801064fb:	c7 44 24 04 80 1e 11 	movl   $0x80111e80,0x4(%esp)
80106502:	80 
80106503:	c7 04 24 c0 26 11 80 	movl   $0x801126c0,(%esp)
8010650a:	e8 22 e6 ff ff       	call   80104b31 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
8010650f:	a1 c0 26 11 80       	mov    0x801126c0,%eax
80106514:	89 c2                	mov    %eax,%edx
80106516:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106519:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010651c:	39 c2                	cmp    %eax,%edx
8010651e:	72 bb                	jb     801064db <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106520:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
80106527:	e8 45 e9 ff ff       	call   80104e71 <release>
  return 0;
8010652c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106531:	c9                   	leave  
80106532:	c3                   	ret    

80106533 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106533:	55                   	push   %ebp
80106534:	89 e5                	mov    %esp,%ebp
80106536:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106539:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
80106540:	e8 ca e8 ff ff       	call   80104e0f <acquire>
  xticks = ticks;
80106545:	a1 c0 26 11 80       	mov    0x801126c0,%eax
8010654a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
8010654d:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
80106554:	e8 18 e9 ff ff       	call   80104e71 <release>
  return xticks;
80106559:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010655c:	c9                   	leave  
8010655d:	c3                   	ret    

8010655e <sys_getFileBlocks>:

int
sys_getFileBlocks(void)
{
8010655e:	55                   	push   %ebp
8010655f:	89 e5                	mov    %esp,%ebp
80106561:	83 ec 28             	sub    $0x28,%esp
  char* path;
  if(argstr(0, &path) < 0)
80106564:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106567:	89 44 24 04          	mov    %eax,0x4(%esp)
8010656b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106572:	e8 d1 ee ff ff       	call   80105448 <argstr>
80106577:	85 c0                	test   %eax,%eax
80106579:	79 07                	jns    80106582 <sys_getFileBlocks+0x24>
    return -1;
8010657b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106580:	eb 0b                	jmp    8010658d <sys_getFileBlocks+0x2f>
  return getFileBlocks(path);  
80106582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106585:	89 04 24             	mov    %eax,(%esp)
80106588:	e8 5d ad ff ff       	call   801012ea <getFileBlocks>
}
8010658d:	c9                   	leave  
8010658e:	c3                   	ret    

8010658f <sys_getFreeBlocks>:

int
sys_getFreeBlocks(void)
{
8010658f:	55                   	push   %ebp
80106590:	89 e5                	mov    %esp,%ebp
80106592:	83 ec 08             	sub    $0x8,%esp
  return getFreeBlocks();
80106595:	e8 ad ae ff ff       	call   80101447 <getFreeBlocks>
}
8010659a:	c9                   	leave  
8010659b:	c3                   	ret    

8010659c <sys_getSharedBlocksRate>:

int
sys_getSharedBlocksRate(void)
{
8010659c:	55                   	push   %ebp
8010659d:	89 e5                	mov    %esp,%ebp
  return 0;
8010659f:	b8 00 00 00 00       	mov    $0x0,%eax
  
}
801065a4:	5d                   	pop    %ebp
801065a5:	c3                   	ret    
	...

801065a8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801065a8:	55                   	push   %ebp
801065a9:	89 e5                	mov    %esp,%ebp
801065ab:	83 ec 08             	sub    $0x8,%esp
801065ae:	8b 55 08             	mov    0x8(%ebp),%edx
801065b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801065b4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801065b8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801065bb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801065bf:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801065c3:	ee                   	out    %al,(%dx)
}
801065c4:	c9                   	leave  
801065c5:	c3                   	ret    

801065c6 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801065c6:	55                   	push   %ebp
801065c7:	89 e5                	mov    %esp,%ebp
801065c9:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801065cc:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801065d3:	00 
801065d4:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801065db:	e8 c8 ff ff ff       	call   801065a8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801065e0:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801065e7:	00 
801065e8:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801065ef:	e8 b4 ff ff ff       	call   801065a8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801065f4:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801065fb:	00 
801065fc:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106603:	e8 a0 ff ff ff       	call   801065a8 <outb>
  picenable(IRQ_TIMER);
80106608:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010660f:	e8 19 d7 ff ff       	call   80103d2d <picenable>
}
80106614:	c9                   	leave  
80106615:	c3                   	ret    
	...

80106618 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106618:	1e                   	push   %ds
  pushl %es
80106619:	06                   	push   %es
  pushl %fs
8010661a:	0f a0                	push   %fs
  pushl %gs
8010661c:	0f a8                	push   %gs
  pushal
8010661e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010661f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106623:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106625:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106627:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010662b:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010662d:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010662f:	54                   	push   %esp
  call trap
80106630:	e8 de 01 00 00       	call   80106813 <trap>
  addl $4, %esp
80106635:	83 c4 04             	add    $0x4,%esp

80106638 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106638:	61                   	popa   
  popl %gs
80106639:	0f a9                	pop    %gs
  popl %fs
8010663b:	0f a1                	pop    %fs
  popl %es
8010663d:	07                   	pop    %es
  popl %ds
8010663e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010663f:	83 c4 08             	add    $0x8,%esp
  iret
80106642:	cf                   	iret   
	...

80106644 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106644:	55                   	push   %ebp
80106645:	89 e5                	mov    %esp,%ebp
80106647:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010664a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010664d:	83 e8 01             	sub    $0x1,%eax
80106650:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106654:	8b 45 08             	mov    0x8(%ebp),%eax
80106657:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010665b:	8b 45 08             	mov    0x8(%ebp),%eax
8010665e:	c1 e8 10             	shr    $0x10,%eax
80106661:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106665:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106668:	0f 01 18             	lidtl  (%eax)
}
8010666b:	c9                   	leave  
8010666c:	c3                   	ret    

8010666d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010666d:	55                   	push   %ebp
8010666e:	89 e5                	mov    %esp,%ebp
80106670:	53                   	push   %ebx
80106671:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106674:	0f 20 d3             	mov    %cr2,%ebx
80106677:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
8010667a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010667d:	83 c4 10             	add    $0x10,%esp
80106680:	5b                   	pop    %ebx
80106681:	5d                   	pop    %ebp
80106682:	c3                   	ret    

80106683 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106683:	55                   	push   %ebp
80106684:	89 e5                	mov    %esp,%ebp
80106686:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106689:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106690:	e9 c3 00 00 00       	jmp    80106758 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106695:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106698:	8b 04 85 a4 b0 10 80 	mov    -0x7fef4f5c(,%eax,4),%eax
8010669f:	89 c2                	mov    %eax,%edx
801066a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066a4:	66 89 14 c5 c0 1e 11 	mov    %dx,-0x7feee140(,%eax,8)
801066ab:	80 
801066ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066af:	66 c7 04 c5 c2 1e 11 	movw   $0x8,-0x7feee13e(,%eax,8)
801066b6:	80 08 00 
801066b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066bc:	0f b6 14 c5 c4 1e 11 	movzbl -0x7feee13c(,%eax,8),%edx
801066c3:	80 
801066c4:	83 e2 e0             	and    $0xffffffe0,%edx
801066c7:	88 14 c5 c4 1e 11 80 	mov    %dl,-0x7feee13c(,%eax,8)
801066ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066d1:	0f b6 14 c5 c4 1e 11 	movzbl -0x7feee13c(,%eax,8),%edx
801066d8:	80 
801066d9:	83 e2 1f             	and    $0x1f,%edx
801066dc:	88 14 c5 c4 1e 11 80 	mov    %dl,-0x7feee13c(,%eax,8)
801066e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e6:	0f b6 14 c5 c5 1e 11 	movzbl -0x7feee13b(,%eax,8),%edx
801066ed:	80 
801066ee:	83 e2 f0             	and    $0xfffffff0,%edx
801066f1:	83 ca 0e             	or     $0xe,%edx
801066f4:	88 14 c5 c5 1e 11 80 	mov    %dl,-0x7feee13b(,%eax,8)
801066fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066fe:	0f b6 14 c5 c5 1e 11 	movzbl -0x7feee13b(,%eax,8),%edx
80106705:	80 
80106706:	83 e2 ef             	and    $0xffffffef,%edx
80106709:	88 14 c5 c5 1e 11 80 	mov    %dl,-0x7feee13b(,%eax,8)
80106710:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106713:	0f b6 14 c5 c5 1e 11 	movzbl -0x7feee13b(,%eax,8),%edx
8010671a:	80 
8010671b:	83 e2 9f             	and    $0xffffff9f,%edx
8010671e:	88 14 c5 c5 1e 11 80 	mov    %dl,-0x7feee13b(,%eax,8)
80106725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106728:	0f b6 14 c5 c5 1e 11 	movzbl -0x7feee13b(,%eax,8),%edx
8010672f:	80 
80106730:	83 ca 80             	or     $0xffffff80,%edx
80106733:	88 14 c5 c5 1e 11 80 	mov    %dl,-0x7feee13b(,%eax,8)
8010673a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010673d:	8b 04 85 a4 b0 10 80 	mov    -0x7fef4f5c(,%eax,4),%eax
80106744:	c1 e8 10             	shr    $0x10,%eax
80106747:	89 c2                	mov    %eax,%edx
80106749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674c:	66 89 14 c5 c6 1e 11 	mov    %dx,-0x7feee13a(,%eax,8)
80106753:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106754:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106758:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010675f:	0f 8e 30 ff ff ff    	jle    80106695 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106765:	a1 a4 b1 10 80       	mov    0x8010b1a4,%eax
8010676a:	66 a3 c0 20 11 80    	mov    %ax,0x801120c0
80106770:	66 c7 05 c2 20 11 80 	movw   $0x8,0x801120c2
80106777:	08 00 
80106779:	0f b6 05 c4 20 11 80 	movzbl 0x801120c4,%eax
80106780:	83 e0 e0             	and    $0xffffffe0,%eax
80106783:	a2 c4 20 11 80       	mov    %al,0x801120c4
80106788:	0f b6 05 c4 20 11 80 	movzbl 0x801120c4,%eax
8010678f:	83 e0 1f             	and    $0x1f,%eax
80106792:	a2 c4 20 11 80       	mov    %al,0x801120c4
80106797:	0f b6 05 c5 20 11 80 	movzbl 0x801120c5,%eax
8010679e:	83 c8 0f             	or     $0xf,%eax
801067a1:	a2 c5 20 11 80       	mov    %al,0x801120c5
801067a6:	0f b6 05 c5 20 11 80 	movzbl 0x801120c5,%eax
801067ad:	83 e0 ef             	and    $0xffffffef,%eax
801067b0:	a2 c5 20 11 80       	mov    %al,0x801120c5
801067b5:	0f b6 05 c5 20 11 80 	movzbl 0x801120c5,%eax
801067bc:	83 c8 60             	or     $0x60,%eax
801067bf:	a2 c5 20 11 80       	mov    %al,0x801120c5
801067c4:	0f b6 05 c5 20 11 80 	movzbl 0x801120c5,%eax
801067cb:	83 c8 80             	or     $0xffffff80,%eax
801067ce:	a2 c5 20 11 80       	mov    %al,0x801120c5
801067d3:	a1 a4 b1 10 80       	mov    0x8010b1a4,%eax
801067d8:	c1 e8 10             	shr    $0x10,%eax
801067db:	66 a3 c6 20 11 80    	mov    %ax,0x801120c6
  
  initlock(&tickslock, "time");
801067e1:	c7 44 24 04 90 8a 10 	movl   $0x80108a90,0x4(%esp)
801067e8:	80 
801067e9:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
801067f0:	e8 f9 e5 ff ff       	call   80104dee <initlock>
}
801067f5:	c9                   	leave  
801067f6:	c3                   	ret    

801067f7 <idtinit>:

void
idtinit(void)
{
801067f7:	55                   	push   %ebp
801067f8:	89 e5                	mov    %esp,%ebp
801067fa:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801067fd:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106804:	00 
80106805:	c7 04 24 c0 1e 11 80 	movl   $0x80111ec0,(%esp)
8010680c:	e8 33 fe ff ff       	call   80106644 <lidt>
}
80106811:	c9                   	leave  
80106812:	c3                   	ret    

80106813 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106813:	55                   	push   %ebp
80106814:	89 e5                	mov    %esp,%ebp
80106816:	57                   	push   %edi
80106817:	56                   	push   %esi
80106818:	53                   	push   %ebx
80106819:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010681c:	8b 45 08             	mov    0x8(%ebp),%eax
8010681f:	8b 40 30             	mov    0x30(%eax),%eax
80106822:	83 f8 40             	cmp    $0x40,%eax
80106825:	75 3e                	jne    80106865 <trap+0x52>
    if(proc->killed)
80106827:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010682d:	8b 40 24             	mov    0x24(%eax),%eax
80106830:	85 c0                	test   %eax,%eax
80106832:	74 05                	je     80106839 <trap+0x26>
      exit();
80106834:	e8 88 de ff ff       	call   801046c1 <exit>
    proc->tf = tf;
80106839:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010683f:	8b 55 08             	mov    0x8(%ebp),%edx
80106842:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106845:	e8 41 ec ff ff       	call   8010548b <syscall>
    if(proc->killed)
8010684a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106850:	8b 40 24             	mov    0x24(%eax),%eax
80106853:	85 c0                	test   %eax,%eax
80106855:	0f 84 34 02 00 00    	je     80106a8f <trap+0x27c>
      exit();
8010685b:	e8 61 de ff ff       	call   801046c1 <exit>
    return;
80106860:	e9 2a 02 00 00       	jmp    80106a8f <trap+0x27c>
  }

  switch(tf->trapno){
80106865:	8b 45 08             	mov    0x8(%ebp),%eax
80106868:	8b 40 30             	mov    0x30(%eax),%eax
8010686b:	83 e8 20             	sub    $0x20,%eax
8010686e:	83 f8 1f             	cmp    $0x1f,%eax
80106871:	0f 87 bc 00 00 00    	ja     80106933 <trap+0x120>
80106877:	8b 04 85 38 8b 10 80 	mov    -0x7fef74c8(,%eax,4),%eax
8010687e:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106880:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106886:	0f b6 00             	movzbl (%eax),%eax
80106889:	84 c0                	test   %al,%al
8010688b:	75 31                	jne    801068be <trap+0xab>
      acquire(&tickslock);
8010688d:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
80106894:	e8 76 e5 ff ff       	call   80104e0f <acquire>
      ticks++;
80106899:	a1 c0 26 11 80       	mov    0x801126c0,%eax
8010689e:	83 c0 01             	add    $0x1,%eax
801068a1:	a3 c0 26 11 80       	mov    %eax,0x801126c0
      wakeup(&ticks);
801068a6:	c7 04 24 c0 26 11 80 	movl   $0x801126c0,(%esp)
801068ad:	e8 58 e3 ff ff       	call   80104c0a <wakeup>
      release(&tickslock);
801068b2:	c7 04 24 80 1e 11 80 	movl   $0x80111e80,(%esp)
801068b9:	e8 b3 e5 ff ff       	call   80104e71 <release>
    }
    lapiceoi();
801068be:	e8 92 c8 ff ff       	call   80103155 <lapiceoi>
    break;
801068c3:	e9 41 01 00 00       	jmp    80106a09 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801068c8:	e8 90 c0 ff ff       	call   8010295d <ideintr>
    lapiceoi();
801068cd:	e8 83 c8 ff ff       	call   80103155 <lapiceoi>
    break;
801068d2:	e9 32 01 00 00       	jmp    80106a09 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801068d7:	e8 57 c6 ff ff       	call   80102f33 <kbdintr>
    lapiceoi();
801068dc:	e8 74 c8 ff ff       	call   80103155 <lapiceoi>
    break;
801068e1:	e9 23 01 00 00       	jmp    80106a09 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801068e6:	e8 a9 03 00 00       	call   80106c94 <uartintr>
    lapiceoi();
801068eb:	e8 65 c8 ff ff       	call   80103155 <lapiceoi>
    break;
801068f0:	e9 14 01 00 00       	jmp    80106a09 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
801068f5:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801068f8:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801068fb:	8b 45 08             	mov    0x8(%ebp),%eax
801068fe:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106902:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106905:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010690b:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010690e:	0f b6 c0             	movzbl %al,%eax
80106911:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106915:	89 54 24 08          	mov    %edx,0x8(%esp)
80106919:	89 44 24 04          	mov    %eax,0x4(%esp)
8010691d:	c7 04 24 98 8a 10 80 	movl   $0x80108a98,(%esp)
80106924:	e8 78 9a ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106929:	e8 27 c8 ff ff       	call   80103155 <lapiceoi>
    break;
8010692e:	e9 d6 00 00 00       	jmp    80106a09 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106933:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106939:	85 c0                	test   %eax,%eax
8010693b:	74 11                	je     8010694e <trap+0x13b>
8010693d:	8b 45 08             	mov    0x8(%ebp),%eax
80106940:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106944:	0f b7 c0             	movzwl %ax,%eax
80106947:	83 e0 03             	and    $0x3,%eax
8010694a:	85 c0                	test   %eax,%eax
8010694c:	75 46                	jne    80106994 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010694e:	e8 1a fd ff ff       	call   8010666d <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106953:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106956:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106959:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106960:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106963:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106966:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106969:	8b 52 30             	mov    0x30(%edx),%edx
8010696c:	89 44 24 10          	mov    %eax,0x10(%esp)
80106970:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106974:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106978:	89 54 24 04          	mov    %edx,0x4(%esp)
8010697c:	c7 04 24 bc 8a 10 80 	movl   $0x80108abc,(%esp)
80106983:	e8 19 9a ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106988:	c7 04 24 ee 8a 10 80 	movl   $0x80108aee,(%esp)
8010698f:	e8 a9 9b ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106994:	e8 d4 fc ff ff       	call   8010666d <rcr2>
80106999:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010699b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010699e:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801069a7:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069aa:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069ad:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069b0:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069b3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069b6:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801069b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069bf:	83 c0 6c             	add    $0x6c,%eax
801069c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801069c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801069cb:	8b 40 10             	mov    0x10(%eax),%eax
801069ce:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801069d2:	89 7c 24 18          	mov    %edi,0x18(%esp)
801069d6:	89 74 24 14          	mov    %esi,0x14(%esp)
801069da:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801069de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801069e2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801069e5:	89 54 24 08          	mov    %edx,0x8(%esp)
801069e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801069ed:	c7 04 24 f4 8a 10 80 	movl   $0x80108af4,(%esp)
801069f4:	e8 a8 99 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801069f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069ff:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106a06:	eb 01                	jmp    80106a09 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106a08:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a0f:	85 c0                	test   %eax,%eax
80106a11:	74 24                	je     80106a37 <trap+0x224>
80106a13:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a19:	8b 40 24             	mov    0x24(%eax),%eax
80106a1c:	85 c0                	test   %eax,%eax
80106a1e:	74 17                	je     80106a37 <trap+0x224>
80106a20:	8b 45 08             	mov    0x8(%ebp),%eax
80106a23:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a27:	0f b7 c0             	movzwl %ax,%eax
80106a2a:	83 e0 03             	and    $0x3,%eax
80106a2d:	83 f8 03             	cmp    $0x3,%eax
80106a30:	75 05                	jne    80106a37 <trap+0x224>
    exit();
80106a32:	e8 8a dc ff ff       	call   801046c1 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106a37:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a3d:	85 c0                	test   %eax,%eax
80106a3f:	74 1e                	je     80106a5f <trap+0x24c>
80106a41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a47:	8b 40 0c             	mov    0xc(%eax),%eax
80106a4a:	83 f8 04             	cmp    $0x4,%eax
80106a4d:	75 10                	jne    80106a5f <trap+0x24c>
80106a4f:	8b 45 08             	mov    0x8(%ebp),%eax
80106a52:	8b 40 30             	mov    0x30(%eax),%eax
80106a55:	83 f8 20             	cmp    $0x20,%eax
80106a58:	75 05                	jne    80106a5f <trap+0x24c>
    yield();
80106a5a:	e8 74 e0 ff ff       	call   80104ad3 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a5f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a65:	85 c0                	test   %eax,%eax
80106a67:	74 27                	je     80106a90 <trap+0x27d>
80106a69:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a6f:	8b 40 24             	mov    0x24(%eax),%eax
80106a72:	85 c0                	test   %eax,%eax
80106a74:	74 1a                	je     80106a90 <trap+0x27d>
80106a76:	8b 45 08             	mov    0x8(%ebp),%eax
80106a79:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106a7d:	0f b7 c0             	movzwl %ax,%eax
80106a80:	83 e0 03             	and    $0x3,%eax
80106a83:	83 f8 03             	cmp    $0x3,%eax
80106a86:	75 08                	jne    80106a90 <trap+0x27d>
    exit();
80106a88:	e8 34 dc ff ff       	call   801046c1 <exit>
80106a8d:	eb 01                	jmp    80106a90 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106a8f:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106a90:	83 c4 3c             	add    $0x3c,%esp
80106a93:	5b                   	pop    %ebx
80106a94:	5e                   	pop    %esi
80106a95:	5f                   	pop    %edi
80106a96:	5d                   	pop    %ebp
80106a97:	c3                   	ret    

80106a98 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106a98:	55                   	push   %ebp
80106a99:	89 e5                	mov    %esp,%ebp
80106a9b:	53                   	push   %ebx
80106a9c:	83 ec 14             	sub    $0x14,%esp
80106a9f:	8b 45 08             	mov    0x8(%ebp),%eax
80106aa2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106aa6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106aaa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106aae:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106ab2:	ec                   	in     (%dx),%al
80106ab3:	89 c3                	mov    %eax,%ebx
80106ab5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106ab8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106abc:	83 c4 14             	add    $0x14,%esp
80106abf:	5b                   	pop    %ebx
80106ac0:	5d                   	pop    %ebp
80106ac1:	c3                   	ret    

80106ac2 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106ac2:	55                   	push   %ebp
80106ac3:	89 e5                	mov    %esp,%ebp
80106ac5:	83 ec 08             	sub    $0x8,%esp
80106ac8:	8b 55 08             	mov    0x8(%ebp),%edx
80106acb:	8b 45 0c             	mov    0xc(%ebp),%eax
80106ace:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106ad2:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106ad5:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106ad9:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106add:	ee                   	out    %al,(%dx)
}
80106ade:	c9                   	leave  
80106adf:	c3                   	ret    

80106ae0 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106ae0:	55                   	push   %ebp
80106ae1:	89 e5                	mov    %esp,%ebp
80106ae3:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106ae6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106aed:	00 
80106aee:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106af5:	e8 c8 ff ff ff       	call   80106ac2 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106afa:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106b01:	00 
80106b02:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b09:	e8 b4 ff ff ff       	call   80106ac2 <outb>
  outb(COM1+0, 115200/9600);
80106b0e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106b15:	00 
80106b16:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b1d:	e8 a0 ff ff ff       	call   80106ac2 <outb>
  outb(COM1+1, 0);
80106b22:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b29:	00 
80106b2a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b31:	e8 8c ff ff ff       	call   80106ac2 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106b36:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106b3d:	00 
80106b3e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b45:	e8 78 ff ff ff       	call   80106ac2 <outb>
  outb(COM1+4, 0);
80106b4a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b51:	00 
80106b52:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106b59:	e8 64 ff ff ff       	call   80106ac2 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106b5e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106b65:	00 
80106b66:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b6d:	e8 50 ff ff ff       	call   80106ac2 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106b72:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106b79:	e8 1a ff ff ff       	call   80106a98 <inb>
80106b7e:	3c ff                	cmp    $0xff,%al
80106b80:	74 6c                	je     80106bee <uartinit+0x10e>
    return;
  uart = 1;
80106b82:	c7 05 6c b6 10 80 01 	movl   $0x1,0x8010b66c
80106b89:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106b8c:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106b93:	e8 00 ff ff ff       	call   80106a98 <inb>
  inb(COM1+0);
80106b98:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b9f:	e8 f4 fe ff ff       	call   80106a98 <inb>
  picenable(IRQ_COM1);
80106ba4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106bab:	e8 7d d1 ff ff       	call   80103d2d <picenable>
  ioapicenable(IRQ_COM1, 0);
80106bb0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106bb7:	00 
80106bb8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106bbf:	e8 1e c0 ff ff       	call   80102be2 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106bc4:	c7 45 f4 b8 8b 10 80 	movl   $0x80108bb8,-0xc(%ebp)
80106bcb:	eb 15                	jmp    80106be2 <uartinit+0x102>
    uartputc(*p);
80106bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bd0:	0f b6 00             	movzbl (%eax),%eax
80106bd3:	0f be c0             	movsbl %al,%eax
80106bd6:	89 04 24             	mov    %eax,(%esp)
80106bd9:	e8 13 00 00 00       	call   80106bf1 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106bde:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106be2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106be5:	0f b6 00             	movzbl (%eax),%eax
80106be8:	84 c0                	test   %al,%al
80106bea:	75 e1                	jne    80106bcd <uartinit+0xed>
80106bec:	eb 01                	jmp    80106bef <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106bee:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106bef:	c9                   	leave  
80106bf0:	c3                   	ret    

80106bf1 <uartputc>:

void
uartputc(int c)
{
80106bf1:	55                   	push   %ebp
80106bf2:	89 e5                	mov    %esp,%ebp
80106bf4:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106bf7:	a1 6c b6 10 80       	mov    0x8010b66c,%eax
80106bfc:	85 c0                	test   %eax,%eax
80106bfe:	74 4d                	je     80106c4d <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c00:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106c07:	eb 10                	jmp    80106c19 <uartputc+0x28>
    microdelay(10);
80106c09:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106c10:	e8 65 c5 ff ff       	call   8010317a <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c19:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106c1d:	7f 16                	jg     80106c35 <uartputc+0x44>
80106c1f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c26:	e8 6d fe ff ff       	call   80106a98 <inb>
80106c2b:	0f b6 c0             	movzbl %al,%eax
80106c2e:	83 e0 20             	and    $0x20,%eax
80106c31:	85 c0                	test   %eax,%eax
80106c33:	74 d4                	je     80106c09 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106c35:	8b 45 08             	mov    0x8(%ebp),%eax
80106c38:	0f b6 c0             	movzbl %al,%eax
80106c3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c3f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c46:	e8 77 fe ff ff       	call   80106ac2 <outb>
80106c4b:	eb 01                	jmp    80106c4e <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106c4d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106c4e:	c9                   	leave  
80106c4f:	c3                   	ret    

80106c50 <uartgetc>:

static int
uartgetc(void)
{
80106c50:	55                   	push   %ebp
80106c51:	89 e5                	mov    %esp,%ebp
80106c53:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106c56:	a1 6c b6 10 80       	mov    0x8010b66c,%eax
80106c5b:	85 c0                	test   %eax,%eax
80106c5d:	75 07                	jne    80106c66 <uartgetc+0x16>
    return -1;
80106c5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c64:	eb 2c                	jmp    80106c92 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106c66:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c6d:	e8 26 fe ff ff       	call   80106a98 <inb>
80106c72:	0f b6 c0             	movzbl %al,%eax
80106c75:	83 e0 01             	and    $0x1,%eax
80106c78:	85 c0                	test   %eax,%eax
80106c7a:	75 07                	jne    80106c83 <uartgetc+0x33>
    return -1;
80106c7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c81:	eb 0f                	jmp    80106c92 <uartgetc+0x42>
  return inb(COM1+0);
80106c83:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c8a:	e8 09 fe ff ff       	call   80106a98 <inb>
80106c8f:	0f b6 c0             	movzbl %al,%eax
}
80106c92:	c9                   	leave  
80106c93:	c3                   	ret    

80106c94 <uartintr>:

void
uartintr(void)
{
80106c94:	55                   	push   %ebp
80106c95:	89 e5                	mov    %esp,%ebp
80106c97:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106c9a:	c7 04 24 50 6c 10 80 	movl   $0x80106c50,(%esp)
80106ca1:	e8 07 9b ff ff       	call   801007ad <consoleintr>
}
80106ca6:	c9                   	leave  
80106ca7:	c3                   	ret    

80106ca8 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106ca8:	6a 00                	push   $0x0
  pushl $0
80106caa:	6a 00                	push   $0x0
  jmp alltraps
80106cac:	e9 67 f9 ff ff       	jmp    80106618 <alltraps>

80106cb1 <vector1>:
.globl vector1
vector1:
  pushl $0
80106cb1:	6a 00                	push   $0x0
  pushl $1
80106cb3:	6a 01                	push   $0x1
  jmp alltraps
80106cb5:	e9 5e f9 ff ff       	jmp    80106618 <alltraps>

80106cba <vector2>:
.globl vector2
vector2:
  pushl $0
80106cba:	6a 00                	push   $0x0
  pushl $2
80106cbc:	6a 02                	push   $0x2
  jmp alltraps
80106cbe:	e9 55 f9 ff ff       	jmp    80106618 <alltraps>

80106cc3 <vector3>:
.globl vector3
vector3:
  pushl $0
80106cc3:	6a 00                	push   $0x0
  pushl $3
80106cc5:	6a 03                	push   $0x3
  jmp alltraps
80106cc7:	e9 4c f9 ff ff       	jmp    80106618 <alltraps>

80106ccc <vector4>:
.globl vector4
vector4:
  pushl $0
80106ccc:	6a 00                	push   $0x0
  pushl $4
80106cce:	6a 04                	push   $0x4
  jmp alltraps
80106cd0:	e9 43 f9 ff ff       	jmp    80106618 <alltraps>

80106cd5 <vector5>:
.globl vector5
vector5:
  pushl $0
80106cd5:	6a 00                	push   $0x0
  pushl $5
80106cd7:	6a 05                	push   $0x5
  jmp alltraps
80106cd9:	e9 3a f9 ff ff       	jmp    80106618 <alltraps>

80106cde <vector6>:
.globl vector6
vector6:
  pushl $0
80106cde:	6a 00                	push   $0x0
  pushl $6
80106ce0:	6a 06                	push   $0x6
  jmp alltraps
80106ce2:	e9 31 f9 ff ff       	jmp    80106618 <alltraps>

80106ce7 <vector7>:
.globl vector7
vector7:
  pushl $0
80106ce7:	6a 00                	push   $0x0
  pushl $7
80106ce9:	6a 07                	push   $0x7
  jmp alltraps
80106ceb:	e9 28 f9 ff ff       	jmp    80106618 <alltraps>

80106cf0 <vector8>:
.globl vector8
vector8:
  pushl $8
80106cf0:	6a 08                	push   $0x8
  jmp alltraps
80106cf2:	e9 21 f9 ff ff       	jmp    80106618 <alltraps>

80106cf7 <vector9>:
.globl vector9
vector9:
  pushl $0
80106cf7:	6a 00                	push   $0x0
  pushl $9
80106cf9:	6a 09                	push   $0x9
  jmp alltraps
80106cfb:	e9 18 f9 ff ff       	jmp    80106618 <alltraps>

80106d00 <vector10>:
.globl vector10
vector10:
  pushl $10
80106d00:	6a 0a                	push   $0xa
  jmp alltraps
80106d02:	e9 11 f9 ff ff       	jmp    80106618 <alltraps>

80106d07 <vector11>:
.globl vector11
vector11:
  pushl $11
80106d07:	6a 0b                	push   $0xb
  jmp alltraps
80106d09:	e9 0a f9 ff ff       	jmp    80106618 <alltraps>

80106d0e <vector12>:
.globl vector12
vector12:
  pushl $12
80106d0e:	6a 0c                	push   $0xc
  jmp alltraps
80106d10:	e9 03 f9 ff ff       	jmp    80106618 <alltraps>

80106d15 <vector13>:
.globl vector13
vector13:
  pushl $13
80106d15:	6a 0d                	push   $0xd
  jmp alltraps
80106d17:	e9 fc f8 ff ff       	jmp    80106618 <alltraps>

80106d1c <vector14>:
.globl vector14
vector14:
  pushl $14
80106d1c:	6a 0e                	push   $0xe
  jmp alltraps
80106d1e:	e9 f5 f8 ff ff       	jmp    80106618 <alltraps>

80106d23 <vector15>:
.globl vector15
vector15:
  pushl $0
80106d23:	6a 00                	push   $0x0
  pushl $15
80106d25:	6a 0f                	push   $0xf
  jmp alltraps
80106d27:	e9 ec f8 ff ff       	jmp    80106618 <alltraps>

80106d2c <vector16>:
.globl vector16
vector16:
  pushl $0
80106d2c:	6a 00                	push   $0x0
  pushl $16
80106d2e:	6a 10                	push   $0x10
  jmp alltraps
80106d30:	e9 e3 f8 ff ff       	jmp    80106618 <alltraps>

80106d35 <vector17>:
.globl vector17
vector17:
  pushl $17
80106d35:	6a 11                	push   $0x11
  jmp alltraps
80106d37:	e9 dc f8 ff ff       	jmp    80106618 <alltraps>

80106d3c <vector18>:
.globl vector18
vector18:
  pushl $0
80106d3c:	6a 00                	push   $0x0
  pushl $18
80106d3e:	6a 12                	push   $0x12
  jmp alltraps
80106d40:	e9 d3 f8 ff ff       	jmp    80106618 <alltraps>

80106d45 <vector19>:
.globl vector19
vector19:
  pushl $0
80106d45:	6a 00                	push   $0x0
  pushl $19
80106d47:	6a 13                	push   $0x13
  jmp alltraps
80106d49:	e9 ca f8 ff ff       	jmp    80106618 <alltraps>

80106d4e <vector20>:
.globl vector20
vector20:
  pushl $0
80106d4e:	6a 00                	push   $0x0
  pushl $20
80106d50:	6a 14                	push   $0x14
  jmp alltraps
80106d52:	e9 c1 f8 ff ff       	jmp    80106618 <alltraps>

80106d57 <vector21>:
.globl vector21
vector21:
  pushl $0
80106d57:	6a 00                	push   $0x0
  pushl $21
80106d59:	6a 15                	push   $0x15
  jmp alltraps
80106d5b:	e9 b8 f8 ff ff       	jmp    80106618 <alltraps>

80106d60 <vector22>:
.globl vector22
vector22:
  pushl $0
80106d60:	6a 00                	push   $0x0
  pushl $22
80106d62:	6a 16                	push   $0x16
  jmp alltraps
80106d64:	e9 af f8 ff ff       	jmp    80106618 <alltraps>

80106d69 <vector23>:
.globl vector23
vector23:
  pushl $0
80106d69:	6a 00                	push   $0x0
  pushl $23
80106d6b:	6a 17                	push   $0x17
  jmp alltraps
80106d6d:	e9 a6 f8 ff ff       	jmp    80106618 <alltraps>

80106d72 <vector24>:
.globl vector24
vector24:
  pushl $0
80106d72:	6a 00                	push   $0x0
  pushl $24
80106d74:	6a 18                	push   $0x18
  jmp alltraps
80106d76:	e9 9d f8 ff ff       	jmp    80106618 <alltraps>

80106d7b <vector25>:
.globl vector25
vector25:
  pushl $0
80106d7b:	6a 00                	push   $0x0
  pushl $25
80106d7d:	6a 19                	push   $0x19
  jmp alltraps
80106d7f:	e9 94 f8 ff ff       	jmp    80106618 <alltraps>

80106d84 <vector26>:
.globl vector26
vector26:
  pushl $0
80106d84:	6a 00                	push   $0x0
  pushl $26
80106d86:	6a 1a                	push   $0x1a
  jmp alltraps
80106d88:	e9 8b f8 ff ff       	jmp    80106618 <alltraps>

80106d8d <vector27>:
.globl vector27
vector27:
  pushl $0
80106d8d:	6a 00                	push   $0x0
  pushl $27
80106d8f:	6a 1b                	push   $0x1b
  jmp alltraps
80106d91:	e9 82 f8 ff ff       	jmp    80106618 <alltraps>

80106d96 <vector28>:
.globl vector28
vector28:
  pushl $0
80106d96:	6a 00                	push   $0x0
  pushl $28
80106d98:	6a 1c                	push   $0x1c
  jmp alltraps
80106d9a:	e9 79 f8 ff ff       	jmp    80106618 <alltraps>

80106d9f <vector29>:
.globl vector29
vector29:
  pushl $0
80106d9f:	6a 00                	push   $0x0
  pushl $29
80106da1:	6a 1d                	push   $0x1d
  jmp alltraps
80106da3:	e9 70 f8 ff ff       	jmp    80106618 <alltraps>

80106da8 <vector30>:
.globl vector30
vector30:
  pushl $0
80106da8:	6a 00                	push   $0x0
  pushl $30
80106daa:	6a 1e                	push   $0x1e
  jmp alltraps
80106dac:	e9 67 f8 ff ff       	jmp    80106618 <alltraps>

80106db1 <vector31>:
.globl vector31
vector31:
  pushl $0
80106db1:	6a 00                	push   $0x0
  pushl $31
80106db3:	6a 1f                	push   $0x1f
  jmp alltraps
80106db5:	e9 5e f8 ff ff       	jmp    80106618 <alltraps>

80106dba <vector32>:
.globl vector32
vector32:
  pushl $0
80106dba:	6a 00                	push   $0x0
  pushl $32
80106dbc:	6a 20                	push   $0x20
  jmp alltraps
80106dbe:	e9 55 f8 ff ff       	jmp    80106618 <alltraps>

80106dc3 <vector33>:
.globl vector33
vector33:
  pushl $0
80106dc3:	6a 00                	push   $0x0
  pushl $33
80106dc5:	6a 21                	push   $0x21
  jmp alltraps
80106dc7:	e9 4c f8 ff ff       	jmp    80106618 <alltraps>

80106dcc <vector34>:
.globl vector34
vector34:
  pushl $0
80106dcc:	6a 00                	push   $0x0
  pushl $34
80106dce:	6a 22                	push   $0x22
  jmp alltraps
80106dd0:	e9 43 f8 ff ff       	jmp    80106618 <alltraps>

80106dd5 <vector35>:
.globl vector35
vector35:
  pushl $0
80106dd5:	6a 00                	push   $0x0
  pushl $35
80106dd7:	6a 23                	push   $0x23
  jmp alltraps
80106dd9:	e9 3a f8 ff ff       	jmp    80106618 <alltraps>

80106dde <vector36>:
.globl vector36
vector36:
  pushl $0
80106dde:	6a 00                	push   $0x0
  pushl $36
80106de0:	6a 24                	push   $0x24
  jmp alltraps
80106de2:	e9 31 f8 ff ff       	jmp    80106618 <alltraps>

80106de7 <vector37>:
.globl vector37
vector37:
  pushl $0
80106de7:	6a 00                	push   $0x0
  pushl $37
80106de9:	6a 25                	push   $0x25
  jmp alltraps
80106deb:	e9 28 f8 ff ff       	jmp    80106618 <alltraps>

80106df0 <vector38>:
.globl vector38
vector38:
  pushl $0
80106df0:	6a 00                	push   $0x0
  pushl $38
80106df2:	6a 26                	push   $0x26
  jmp alltraps
80106df4:	e9 1f f8 ff ff       	jmp    80106618 <alltraps>

80106df9 <vector39>:
.globl vector39
vector39:
  pushl $0
80106df9:	6a 00                	push   $0x0
  pushl $39
80106dfb:	6a 27                	push   $0x27
  jmp alltraps
80106dfd:	e9 16 f8 ff ff       	jmp    80106618 <alltraps>

80106e02 <vector40>:
.globl vector40
vector40:
  pushl $0
80106e02:	6a 00                	push   $0x0
  pushl $40
80106e04:	6a 28                	push   $0x28
  jmp alltraps
80106e06:	e9 0d f8 ff ff       	jmp    80106618 <alltraps>

80106e0b <vector41>:
.globl vector41
vector41:
  pushl $0
80106e0b:	6a 00                	push   $0x0
  pushl $41
80106e0d:	6a 29                	push   $0x29
  jmp alltraps
80106e0f:	e9 04 f8 ff ff       	jmp    80106618 <alltraps>

80106e14 <vector42>:
.globl vector42
vector42:
  pushl $0
80106e14:	6a 00                	push   $0x0
  pushl $42
80106e16:	6a 2a                	push   $0x2a
  jmp alltraps
80106e18:	e9 fb f7 ff ff       	jmp    80106618 <alltraps>

80106e1d <vector43>:
.globl vector43
vector43:
  pushl $0
80106e1d:	6a 00                	push   $0x0
  pushl $43
80106e1f:	6a 2b                	push   $0x2b
  jmp alltraps
80106e21:	e9 f2 f7 ff ff       	jmp    80106618 <alltraps>

80106e26 <vector44>:
.globl vector44
vector44:
  pushl $0
80106e26:	6a 00                	push   $0x0
  pushl $44
80106e28:	6a 2c                	push   $0x2c
  jmp alltraps
80106e2a:	e9 e9 f7 ff ff       	jmp    80106618 <alltraps>

80106e2f <vector45>:
.globl vector45
vector45:
  pushl $0
80106e2f:	6a 00                	push   $0x0
  pushl $45
80106e31:	6a 2d                	push   $0x2d
  jmp alltraps
80106e33:	e9 e0 f7 ff ff       	jmp    80106618 <alltraps>

80106e38 <vector46>:
.globl vector46
vector46:
  pushl $0
80106e38:	6a 00                	push   $0x0
  pushl $46
80106e3a:	6a 2e                	push   $0x2e
  jmp alltraps
80106e3c:	e9 d7 f7 ff ff       	jmp    80106618 <alltraps>

80106e41 <vector47>:
.globl vector47
vector47:
  pushl $0
80106e41:	6a 00                	push   $0x0
  pushl $47
80106e43:	6a 2f                	push   $0x2f
  jmp alltraps
80106e45:	e9 ce f7 ff ff       	jmp    80106618 <alltraps>

80106e4a <vector48>:
.globl vector48
vector48:
  pushl $0
80106e4a:	6a 00                	push   $0x0
  pushl $48
80106e4c:	6a 30                	push   $0x30
  jmp alltraps
80106e4e:	e9 c5 f7 ff ff       	jmp    80106618 <alltraps>

80106e53 <vector49>:
.globl vector49
vector49:
  pushl $0
80106e53:	6a 00                	push   $0x0
  pushl $49
80106e55:	6a 31                	push   $0x31
  jmp alltraps
80106e57:	e9 bc f7 ff ff       	jmp    80106618 <alltraps>

80106e5c <vector50>:
.globl vector50
vector50:
  pushl $0
80106e5c:	6a 00                	push   $0x0
  pushl $50
80106e5e:	6a 32                	push   $0x32
  jmp alltraps
80106e60:	e9 b3 f7 ff ff       	jmp    80106618 <alltraps>

80106e65 <vector51>:
.globl vector51
vector51:
  pushl $0
80106e65:	6a 00                	push   $0x0
  pushl $51
80106e67:	6a 33                	push   $0x33
  jmp alltraps
80106e69:	e9 aa f7 ff ff       	jmp    80106618 <alltraps>

80106e6e <vector52>:
.globl vector52
vector52:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $52
80106e70:	6a 34                	push   $0x34
  jmp alltraps
80106e72:	e9 a1 f7 ff ff       	jmp    80106618 <alltraps>

80106e77 <vector53>:
.globl vector53
vector53:
  pushl $0
80106e77:	6a 00                	push   $0x0
  pushl $53
80106e79:	6a 35                	push   $0x35
  jmp alltraps
80106e7b:	e9 98 f7 ff ff       	jmp    80106618 <alltraps>

80106e80 <vector54>:
.globl vector54
vector54:
  pushl $0
80106e80:	6a 00                	push   $0x0
  pushl $54
80106e82:	6a 36                	push   $0x36
  jmp alltraps
80106e84:	e9 8f f7 ff ff       	jmp    80106618 <alltraps>

80106e89 <vector55>:
.globl vector55
vector55:
  pushl $0
80106e89:	6a 00                	push   $0x0
  pushl $55
80106e8b:	6a 37                	push   $0x37
  jmp alltraps
80106e8d:	e9 86 f7 ff ff       	jmp    80106618 <alltraps>

80106e92 <vector56>:
.globl vector56
vector56:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $56
80106e94:	6a 38                	push   $0x38
  jmp alltraps
80106e96:	e9 7d f7 ff ff       	jmp    80106618 <alltraps>

80106e9b <vector57>:
.globl vector57
vector57:
  pushl $0
80106e9b:	6a 00                	push   $0x0
  pushl $57
80106e9d:	6a 39                	push   $0x39
  jmp alltraps
80106e9f:	e9 74 f7 ff ff       	jmp    80106618 <alltraps>

80106ea4 <vector58>:
.globl vector58
vector58:
  pushl $0
80106ea4:	6a 00                	push   $0x0
  pushl $58
80106ea6:	6a 3a                	push   $0x3a
  jmp alltraps
80106ea8:	e9 6b f7 ff ff       	jmp    80106618 <alltraps>

80106ead <vector59>:
.globl vector59
vector59:
  pushl $0
80106ead:	6a 00                	push   $0x0
  pushl $59
80106eaf:	6a 3b                	push   $0x3b
  jmp alltraps
80106eb1:	e9 62 f7 ff ff       	jmp    80106618 <alltraps>

80106eb6 <vector60>:
.globl vector60
vector60:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $60
80106eb8:	6a 3c                	push   $0x3c
  jmp alltraps
80106eba:	e9 59 f7 ff ff       	jmp    80106618 <alltraps>

80106ebf <vector61>:
.globl vector61
vector61:
  pushl $0
80106ebf:	6a 00                	push   $0x0
  pushl $61
80106ec1:	6a 3d                	push   $0x3d
  jmp alltraps
80106ec3:	e9 50 f7 ff ff       	jmp    80106618 <alltraps>

80106ec8 <vector62>:
.globl vector62
vector62:
  pushl $0
80106ec8:	6a 00                	push   $0x0
  pushl $62
80106eca:	6a 3e                	push   $0x3e
  jmp alltraps
80106ecc:	e9 47 f7 ff ff       	jmp    80106618 <alltraps>

80106ed1 <vector63>:
.globl vector63
vector63:
  pushl $0
80106ed1:	6a 00                	push   $0x0
  pushl $63
80106ed3:	6a 3f                	push   $0x3f
  jmp alltraps
80106ed5:	e9 3e f7 ff ff       	jmp    80106618 <alltraps>

80106eda <vector64>:
.globl vector64
vector64:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $64
80106edc:	6a 40                	push   $0x40
  jmp alltraps
80106ede:	e9 35 f7 ff ff       	jmp    80106618 <alltraps>

80106ee3 <vector65>:
.globl vector65
vector65:
  pushl $0
80106ee3:	6a 00                	push   $0x0
  pushl $65
80106ee5:	6a 41                	push   $0x41
  jmp alltraps
80106ee7:	e9 2c f7 ff ff       	jmp    80106618 <alltraps>

80106eec <vector66>:
.globl vector66
vector66:
  pushl $0
80106eec:	6a 00                	push   $0x0
  pushl $66
80106eee:	6a 42                	push   $0x42
  jmp alltraps
80106ef0:	e9 23 f7 ff ff       	jmp    80106618 <alltraps>

80106ef5 <vector67>:
.globl vector67
vector67:
  pushl $0
80106ef5:	6a 00                	push   $0x0
  pushl $67
80106ef7:	6a 43                	push   $0x43
  jmp alltraps
80106ef9:	e9 1a f7 ff ff       	jmp    80106618 <alltraps>

80106efe <vector68>:
.globl vector68
vector68:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $68
80106f00:	6a 44                	push   $0x44
  jmp alltraps
80106f02:	e9 11 f7 ff ff       	jmp    80106618 <alltraps>

80106f07 <vector69>:
.globl vector69
vector69:
  pushl $0
80106f07:	6a 00                	push   $0x0
  pushl $69
80106f09:	6a 45                	push   $0x45
  jmp alltraps
80106f0b:	e9 08 f7 ff ff       	jmp    80106618 <alltraps>

80106f10 <vector70>:
.globl vector70
vector70:
  pushl $0
80106f10:	6a 00                	push   $0x0
  pushl $70
80106f12:	6a 46                	push   $0x46
  jmp alltraps
80106f14:	e9 ff f6 ff ff       	jmp    80106618 <alltraps>

80106f19 <vector71>:
.globl vector71
vector71:
  pushl $0
80106f19:	6a 00                	push   $0x0
  pushl $71
80106f1b:	6a 47                	push   $0x47
  jmp alltraps
80106f1d:	e9 f6 f6 ff ff       	jmp    80106618 <alltraps>

80106f22 <vector72>:
.globl vector72
vector72:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $72
80106f24:	6a 48                	push   $0x48
  jmp alltraps
80106f26:	e9 ed f6 ff ff       	jmp    80106618 <alltraps>

80106f2b <vector73>:
.globl vector73
vector73:
  pushl $0
80106f2b:	6a 00                	push   $0x0
  pushl $73
80106f2d:	6a 49                	push   $0x49
  jmp alltraps
80106f2f:	e9 e4 f6 ff ff       	jmp    80106618 <alltraps>

80106f34 <vector74>:
.globl vector74
vector74:
  pushl $0
80106f34:	6a 00                	push   $0x0
  pushl $74
80106f36:	6a 4a                	push   $0x4a
  jmp alltraps
80106f38:	e9 db f6 ff ff       	jmp    80106618 <alltraps>

80106f3d <vector75>:
.globl vector75
vector75:
  pushl $0
80106f3d:	6a 00                	push   $0x0
  pushl $75
80106f3f:	6a 4b                	push   $0x4b
  jmp alltraps
80106f41:	e9 d2 f6 ff ff       	jmp    80106618 <alltraps>

80106f46 <vector76>:
.globl vector76
vector76:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $76
80106f48:	6a 4c                	push   $0x4c
  jmp alltraps
80106f4a:	e9 c9 f6 ff ff       	jmp    80106618 <alltraps>

80106f4f <vector77>:
.globl vector77
vector77:
  pushl $0
80106f4f:	6a 00                	push   $0x0
  pushl $77
80106f51:	6a 4d                	push   $0x4d
  jmp alltraps
80106f53:	e9 c0 f6 ff ff       	jmp    80106618 <alltraps>

80106f58 <vector78>:
.globl vector78
vector78:
  pushl $0
80106f58:	6a 00                	push   $0x0
  pushl $78
80106f5a:	6a 4e                	push   $0x4e
  jmp alltraps
80106f5c:	e9 b7 f6 ff ff       	jmp    80106618 <alltraps>

80106f61 <vector79>:
.globl vector79
vector79:
  pushl $0
80106f61:	6a 00                	push   $0x0
  pushl $79
80106f63:	6a 4f                	push   $0x4f
  jmp alltraps
80106f65:	e9 ae f6 ff ff       	jmp    80106618 <alltraps>

80106f6a <vector80>:
.globl vector80
vector80:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $80
80106f6c:	6a 50                	push   $0x50
  jmp alltraps
80106f6e:	e9 a5 f6 ff ff       	jmp    80106618 <alltraps>

80106f73 <vector81>:
.globl vector81
vector81:
  pushl $0
80106f73:	6a 00                	push   $0x0
  pushl $81
80106f75:	6a 51                	push   $0x51
  jmp alltraps
80106f77:	e9 9c f6 ff ff       	jmp    80106618 <alltraps>

80106f7c <vector82>:
.globl vector82
vector82:
  pushl $0
80106f7c:	6a 00                	push   $0x0
  pushl $82
80106f7e:	6a 52                	push   $0x52
  jmp alltraps
80106f80:	e9 93 f6 ff ff       	jmp    80106618 <alltraps>

80106f85 <vector83>:
.globl vector83
vector83:
  pushl $0
80106f85:	6a 00                	push   $0x0
  pushl $83
80106f87:	6a 53                	push   $0x53
  jmp alltraps
80106f89:	e9 8a f6 ff ff       	jmp    80106618 <alltraps>

80106f8e <vector84>:
.globl vector84
vector84:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $84
80106f90:	6a 54                	push   $0x54
  jmp alltraps
80106f92:	e9 81 f6 ff ff       	jmp    80106618 <alltraps>

80106f97 <vector85>:
.globl vector85
vector85:
  pushl $0
80106f97:	6a 00                	push   $0x0
  pushl $85
80106f99:	6a 55                	push   $0x55
  jmp alltraps
80106f9b:	e9 78 f6 ff ff       	jmp    80106618 <alltraps>

80106fa0 <vector86>:
.globl vector86
vector86:
  pushl $0
80106fa0:	6a 00                	push   $0x0
  pushl $86
80106fa2:	6a 56                	push   $0x56
  jmp alltraps
80106fa4:	e9 6f f6 ff ff       	jmp    80106618 <alltraps>

80106fa9 <vector87>:
.globl vector87
vector87:
  pushl $0
80106fa9:	6a 00                	push   $0x0
  pushl $87
80106fab:	6a 57                	push   $0x57
  jmp alltraps
80106fad:	e9 66 f6 ff ff       	jmp    80106618 <alltraps>

80106fb2 <vector88>:
.globl vector88
vector88:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $88
80106fb4:	6a 58                	push   $0x58
  jmp alltraps
80106fb6:	e9 5d f6 ff ff       	jmp    80106618 <alltraps>

80106fbb <vector89>:
.globl vector89
vector89:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $89
80106fbd:	6a 59                	push   $0x59
  jmp alltraps
80106fbf:	e9 54 f6 ff ff       	jmp    80106618 <alltraps>

80106fc4 <vector90>:
.globl vector90
vector90:
  pushl $0
80106fc4:	6a 00                	push   $0x0
  pushl $90
80106fc6:	6a 5a                	push   $0x5a
  jmp alltraps
80106fc8:	e9 4b f6 ff ff       	jmp    80106618 <alltraps>

80106fcd <vector91>:
.globl vector91
vector91:
  pushl $0
80106fcd:	6a 00                	push   $0x0
  pushl $91
80106fcf:	6a 5b                	push   $0x5b
  jmp alltraps
80106fd1:	e9 42 f6 ff ff       	jmp    80106618 <alltraps>

80106fd6 <vector92>:
.globl vector92
vector92:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $92
80106fd8:	6a 5c                	push   $0x5c
  jmp alltraps
80106fda:	e9 39 f6 ff ff       	jmp    80106618 <alltraps>

80106fdf <vector93>:
.globl vector93
vector93:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $93
80106fe1:	6a 5d                	push   $0x5d
  jmp alltraps
80106fe3:	e9 30 f6 ff ff       	jmp    80106618 <alltraps>

80106fe8 <vector94>:
.globl vector94
vector94:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $94
80106fea:	6a 5e                	push   $0x5e
  jmp alltraps
80106fec:	e9 27 f6 ff ff       	jmp    80106618 <alltraps>

80106ff1 <vector95>:
.globl vector95
vector95:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $95
80106ff3:	6a 5f                	push   $0x5f
  jmp alltraps
80106ff5:	e9 1e f6 ff ff       	jmp    80106618 <alltraps>

80106ffa <vector96>:
.globl vector96
vector96:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $96
80106ffc:	6a 60                	push   $0x60
  jmp alltraps
80106ffe:	e9 15 f6 ff ff       	jmp    80106618 <alltraps>

80107003 <vector97>:
.globl vector97
vector97:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $97
80107005:	6a 61                	push   $0x61
  jmp alltraps
80107007:	e9 0c f6 ff ff       	jmp    80106618 <alltraps>

8010700c <vector98>:
.globl vector98
vector98:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $98
8010700e:	6a 62                	push   $0x62
  jmp alltraps
80107010:	e9 03 f6 ff ff       	jmp    80106618 <alltraps>

80107015 <vector99>:
.globl vector99
vector99:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $99
80107017:	6a 63                	push   $0x63
  jmp alltraps
80107019:	e9 fa f5 ff ff       	jmp    80106618 <alltraps>

8010701e <vector100>:
.globl vector100
vector100:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $100
80107020:	6a 64                	push   $0x64
  jmp alltraps
80107022:	e9 f1 f5 ff ff       	jmp    80106618 <alltraps>

80107027 <vector101>:
.globl vector101
vector101:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $101
80107029:	6a 65                	push   $0x65
  jmp alltraps
8010702b:	e9 e8 f5 ff ff       	jmp    80106618 <alltraps>

80107030 <vector102>:
.globl vector102
vector102:
  pushl $0
80107030:	6a 00                	push   $0x0
  pushl $102
80107032:	6a 66                	push   $0x66
  jmp alltraps
80107034:	e9 df f5 ff ff       	jmp    80106618 <alltraps>

80107039 <vector103>:
.globl vector103
vector103:
  pushl $0
80107039:	6a 00                	push   $0x0
  pushl $103
8010703b:	6a 67                	push   $0x67
  jmp alltraps
8010703d:	e9 d6 f5 ff ff       	jmp    80106618 <alltraps>

80107042 <vector104>:
.globl vector104
vector104:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $104
80107044:	6a 68                	push   $0x68
  jmp alltraps
80107046:	e9 cd f5 ff ff       	jmp    80106618 <alltraps>

8010704b <vector105>:
.globl vector105
vector105:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $105
8010704d:	6a 69                	push   $0x69
  jmp alltraps
8010704f:	e9 c4 f5 ff ff       	jmp    80106618 <alltraps>

80107054 <vector106>:
.globl vector106
vector106:
  pushl $0
80107054:	6a 00                	push   $0x0
  pushl $106
80107056:	6a 6a                	push   $0x6a
  jmp alltraps
80107058:	e9 bb f5 ff ff       	jmp    80106618 <alltraps>

8010705d <vector107>:
.globl vector107
vector107:
  pushl $0
8010705d:	6a 00                	push   $0x0
  pushl $107
8010705f:	6a 6b                	push   $0x6b
  jmp alltraps
80107061:	e9 b2 f5 ff ff       	jmp    80106618 <alltraps>

80107066 <vector108>:
.globl vector108
vector108:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $108
80107068:	6a 6c                	push   $0x6c
  jmp alltraps
8010706a:	e9 a9 f5 ff ff       	jmp    80106618 <alltraps>

8010706f <vector109>:
.globl vector109
vector109:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $109
80107071:	6a 6d                	push   $0x6d
  jmp alltraps
80107073:	e9 a0 f5 ff ff       	jmp    80106618 <alltraps>

80107078 <vector110>:
.globl vector110
vector110:
  pushl $0
80107078:	6a 00                	push   $0x0
  pushl $110
8010707a:	6a 6e                	push   $0x6e
  jmp alltraps
8010707c:	e9 97 f5 ff ff       	jmp    80106618 <alltraps>

80107081 <vector111>:
.globl vector111
vector111:
  pushl $0
80107081:	6a 00                	push   $0x0
  pushl $111
80107083:	6a 6f                	push   $0x6f
  jmp alltraps
80107085:	e9 8e f5 ff ff       	jmp    80106618 <alltraps>

8010708a <vector112>:
.globl vector112
vector112:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $112
8010708c:	6a 70                	push   $0x70
  jmp alltraps
8010708e:	e9 85 f5 ff ff       	jmp    80106618 <alltraps>

80107093 <vector113>:
.globl vector113
vector113:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $113
80107095:	6a 71                	push   $0x71
  jmp alltraps
80107097:	e9 7c f5 ff ff       	jmp    80106618 <alltraps>

8010709c <vector114>:
.globl vector114
vector114:
  pushl $0
8010709c:	6a 00                	push   $0x0
  pushl $114
8010709e:	6a 72                	push   $0x72
  jmp alltraps
801070a0:	e9 73 f5 ff ff       	jmp    80106618 <alltraps>

801070a5 <vector115>:
.globl vector115
vector115:
  pushl $0
801070a5:	6a 00                	push   $0x0
  pushl $115
801070a7:	6a 73                	push   $0x73
  jmp alltraps
801070a9:	e9 6a f5 ff ff       	jmp    80106618 <alltraps>

801070ae <vector116>:
.globl vector116
vector116:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $116
801070b0:	6a 74                	push   $0x74
  jmp alltraps
801070b2:	e9 61 f5 ff ff       	jmp    80106618 <alltraps>

801070b7 <vector117>:
.globl vector117
vector117:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $117
801070b9:	6a 75                	push   $0x75
  jmp alltraps
801070bb:	e9 58 f5 ff ff       	jmp    80106618 <alltraps>

801070c0 <vector118>:
.globl vector118
vector118:
  pushl $0
801070c0:	6a 00                	push   $0x0
  pushl $118
801070c2:	6a 76                	push   $0x76
  jmp alltraps
801070c4:	e9 4f f5 ff ff       	jmp    80106618 <alltraps>

801070c9 <vector119>:
.globl vector119
vector119:
  pushl $0
801070c9:	6a 00                	push   $0x0
  pushl $119
801070cb:	6a 77                	push   $0x77
  jmp alltraps
801070cd:	e9 46 f5 ff ff       	jmp    80106618 <alltraps>

801070d2 <vector120>:
.globl vector120
vector120:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $120
801070d4:	6a 78                	push   $0x78
  jmp alltraps
801070d6:	e9 3d f5 ff ff       	jmp    80106618 <alltraps>

801070db <vector121>:
.globl vector121
vector121:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $121
801070dd:	6a 79                	push   $0x79
  jmp alltraps
801070df:	e9 34 f5 ff ff       	jmp    80106618 <alltraps>

801070e4 <vector122>:
.globl vector122
vector122:
  pushl $0
801070e4:	6a 00                	push   $0x0
  pushl $122
801070e6:	6a 7a                	push   $0x7a
  jmp alltraps
801070e8:	e9 2b f5 ff ff       	jmp    80106618 <alltraps>

801070ed <vector123>:
.globl vector123
vector123:
  pushl $0
801070ed:	6a 00                	push   $0x0
  pushl $123
801070ef:	6a 7b                	push   $0x7b
  jmp alltraps
801070f1:	e9 22 f5 ff ff       	jmp    80106618 <alltraps>

801070f6 <vector124>:
.globl vector124
vector124:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $124
801070f8:	6a 7c                	push   $0x7c
  jmp alltraps
801070fa:	e9 19 f5 ff ff       	jmp    80106618 <alltraps>

801070ff <vector125>:
.globl vector125
vector125:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $125
80107101:	6a 7d                	push   $0x7d
  jmp alltraps
80107103:	e9 10 f5 ff ff       	jmp    80106618 <alltraps>

80107108 <vector126>:
.globl vector126
vector126:
  pushl $0
80107108:	6a 00                	push   $0x0
  pushl $126
8010710a:	6a 7e                	push   $0x7e
  jmp alltraps
8010710c:	e9 07 f5 ff ff       	jmp    80106618 <alltraps>

80107111 <vector127>:
.globl vector127
vector127:
  pushl $0
80107111:	6a 00                	push   $0x0
  pushl $127
80107113:	6a 7f                	push   $0x7f
  jmp alltraps
80107115:	e9 fe f4 ff ff       	jmp    80106618 <alltraps>

8010711a <vector128>:
.globl vector128
vector128:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $128
8010711c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107121:	e9 f2 f4 ff ff       	jmp    80106618 <alltraps>

80107126 <vector129>:
.globl vector129
vector129:
  pushl $0
80107126:	6a 00                	push   $0x0
  pushl $129
80107128:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010712d:	e9 e6 f4 ff ff       	jmp    80106618 <alltraps>

80107132 <vector130>:
.globl vector130
vector130:
  pushl $0
80107132:	6a 00                	push   $0x0
  pushl $130
80107134:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107139:	e9 da f4 ff ff       	jmp    80106618 <alltraps>

8010713e <vector131>:
.globl vector131
vector131:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $131
80107140:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107145:	e9 ce f4 ff ff       	jmp    80106618 <alltraps>

8010714a <vector132>:
.globl vector132
vector132:
  pushl $0
8010714a:	6a 00                	push   $0x0
  pushl $132
8010714c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107151:	e9 c2 f4 ff ff       	jmp    80106618 <alltraps>

80107156 <vector133>:
.globl vector133
vector133:
  pushl $0
80107156:	6a 00                	push   $0x0
  pushl $133
80107158:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010715d:	e9 b6 f4 ff ff       	jmp    80106618 <alltraps>

80107162 <vector134>:
.globl vector134
vector134:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $134
80107164:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107169:	e9 aa f4 ff ff       	jmp    80106618 <alltraps>

8010716e <vector135>:
.globl vector135
vector135:
  pushl $0
8010716e:	6a 00                	push   $0x0
  pushl $135
80107170:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107175:	e9 9e f4 ff ff       	jmp    80106618 <alltraps>

8010717a <vector136>:
.globl vector136
vector136:
  pushl $0
8010717a:	6a 00                	push   $0x0
  pushl $136
8010717c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107181:	e9 92 f4 ff ff       	jmp    80106618 <alltraps>

80107186 <vector137>:
.globl vector137
vector137:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $137
80107188:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010718d:	e9 86 f4 ff ff       	jmp    80106618 <alltraps>

80107192 <vector138>:
.globl vector138
vector138:
  pushl $0
80107192:	6a 00                	push   $0x0
  pushl $138
80107194:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107199:	e9 7a f4 ff ff       	jmp    80106618 <alltraps>

8010719e <vector139>:
.globl vector139
vector139:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $139
801071a0:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801071a5:	e9 6e f4 ff ff       	jmp    80106618 <alltraps>

801071aa <vector140>:
.globl vector140
vector140:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $140
801071ac:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801071b1:	e9 62 f4 ff ff       	jmp    80106618 <alltraps>

801071b6 <vector141>:
.globl vector141
vector141:
  pushl $0
801071b6:	6a 00                	push   $0x0
  pushl $141
801071b8:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801071bd:	e9 56 f4 ff ff       	jmp    80106618 <alltraps>

801071c2 <vector142>:
.globl vector142
vector142:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $142
801071c4:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801071c9:	e9 4a f4 ff ff       	jmp    80106618 <alltraps>

801071ce <vector143>:
.globl vector143
vector143:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $143
801071d0:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801071d5:	e9 3e f4 ff ff       	jmp    80106618 <alltraps>

801071da <vector144>:
.globl vector144
vector144:
  pushl $0
801071da:	6a 00                	push   $0x0
  pushl $144
801071dc:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801071e1:	e9 32 f4 ff ff       	jmp    80106618 <alltraps>

801071e6 <vector145>:
.globl vector145
vector145:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $145
801071e8:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801071ed:	e9 26 f4 ff ff       	jmp    80106618 <alltraps>

801071f2 <vector146>:
.globl vector146
vector146:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $146
801071f4:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801071f9:	e9 1a f4 ff ff       	jmp    80106618 <alltraps>

801071fe <vector147>:
.globl vector147
vector147:
  pushl $0
801071fe:	6a 00                	push   $0x0
  pushl $147
80107200:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107205:	e9 0e f4 ff ff       	jmp    80106618 <alltraps>

8010720a <vector148>:
.globl vector148
vector148:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $148
8010720c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107211:	e9 02 f4 ff ff       	jmp    80106618 <alltraps>

80107216 <vector149>:
.globl vector149
vector149:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $149
80107218:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010721d:	e9 f6 f3 ff ff       	jmp    80106618 <alltraps>

80107222 <vector150>:
.globl vector150
vector150:
  pushl $0
80107222:	6a 00                	push   $0x0
  pushl $150
80107224:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107229:	e9 ea f3 ff ff       	jmp    80106618 <alltraps>

8010722e <vector151>:
.globl vector151
vector151:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $151
80107230:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107235:	e9 de f3 ff ff       	jmp    80106618 <alltraps>

8010723a <vector152>:
.globl vector152
vector152:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $152
8010723c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107241:	e9 d2 f3 ff ff       	jmp    80106618 <alltraps>

80107246 <vector153>:
.globl vector153
vector153:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $153
80107248:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010724d:	e9 c6 f3 ff ff       	jmp    80106618 <alltraps>

80107252 <vector154>:
.globl vector154
vector154:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $154
80107254:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107259:	e9 ba f3 ff ff       	jmp    80106618 <alltraps>

8010725e <vector155>:
.globl vector155
vector155:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $155
80107260:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107265:	e9 ae f3 ff ff       	jmp    80106618 <alltraps>

8010726a <vector156>:
.globl vector156
vector156:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $156
8010726c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107271:	e9 a2 f3 ff ff       	jmp    80106618 <alltraps>

80107276 <vector157>:
.globl vector157
vector157:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $157
80107278:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010727d:	e9 96 f3 ff ff       	jmp    80106618 <alltraps>

80107282 <vector158>:
.globl vector158
vector158:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $158
80107284:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107289:	e9 8a f3 ff ff       	jmp    80106618 <alltraps>

8010728e <vector159>:
.globl vector159
vector159:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $159
80107290:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107295:	e9 7e f3 ff ff       	jmp    80106618 <alltraps>

8010729a <vector160>:
.globl vector160
vector160:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $160
8010729c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801072a1:	e9 72 f3 ff ff       	jmp    80106618 <alltraps>

801072a6 <vector161>:
.globl vector161
vector161:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $161
801072a8:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801072ad:	e9 66 f3 ff ff       	jmp    80106618 <alltraps>

801072b2 <vector162>:
.globl vector162
vector162:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $162
801072b4:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801072b9:	e9 5a f3 ff ff       	jmp    80106618 <alltraps>

801072be <vector163>:
.globl vector163
vector163:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $163
801072c0:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801072c5:	e9 4e f3 ff ff       	jmp    80106618 <alltraps>

801072ca <vector164>:
.globl vector164
vector164:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $164
801072cc:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801072d1:	e9 42 f3 ff ff       	jmp    80106618 <alltraps>

801072d6 <vector165>:
.globl vector165
vector165:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $165
801072d8:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801072dd:	e9 36 f3 ff ff       	jmp    80106618 <alltraps>

801072e2 <vector166>:
.globl vector166
vector166:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $166
801072e4:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801072e9:	e9 2a f3 ff ff       	jmp    80106618 <alltraps>

801072ee <vector167>:
.globl vector167
vector167:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $167
801072f0:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801072f5:	e9 1e f3 ff ff       	jmp    80106618 <alltraps>

801072fa <vector168>:
.globl vector168
vector168:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $168
801072fc:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107301:	e9 12 f3 ff ff       	jmp    80106618 <alltraps>

80107306 <vector169>:
.globl vector169
vector169:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $169
80107308:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010730d:	e9 06 f3 ff ff       	jmp    80106618 <alltraps>

80107312 <vector170>:
.globl vector170
vector170:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $170
80107314:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107319:	e9 fa f2 ff ff       	jmp    80106618 <alltraps>

8010731e <vector171>:
.globl vector171
vector171:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $171
80107320:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107325:	e9 ee f2 ff ff       	jmp    80106618 <alltraps>

8010732a <vector172>:
.globl vector172
vector172:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $172
8010732c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107331:	e9 e2 f2 ff ff       	jmp    80106618 <alltraps>

80107336 <vector173>:
.globl vector173
vector173:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $173
80107338:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010733d:	e9 d6 f2 ff ff       	jmp    80106618 <alltraps>

80107342 <vector174>:
.globl vector174
vector174:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $174
80107344:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107349:	e9 ca f2 ff ff       	jmp    80106618 <alltraps>

8010734e <vector175>:
.globl vector175
vector175:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $175
80107350:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107355:	e9 be f2 ff ff       	jmp    80106618 <alltraps>

8010735a <vector176>:
.globl vector176
vector176:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $176
8010735c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107361:	e9 b2 f2 ff ff       	jmp    80106618 <alltraps>

80107366 <vector177>:
.globl vector177
vector177:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $177
80107368:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010736d:	e9 a6 f2 ff ff       	jmp    80106618 <alltraps>

80107372 <vector178>:
.globl vector178
vector178:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $178
80107374:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107379:	e9 9a f2 ff ff       	jmp    80106618 <alltraps>

8010737e <vector179>:
.globl vector179
vector179:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $179
80107380:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107385:	e9 8e f2 ff ff       	jmp    80106618 <alltraps>

8010738a <vector180>:
.globl vector180
vector180:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $180
8010738c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107391:	e9 82 f2 ff ff       	jmp    80106618 <alltraps>

80107396 <vector181>:
.globl vector181
vector181:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $181
80107398:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010739d:	e9 76 f2 ff ff       	jmp    80106618 <alltraps>

801073a2 <vector182>:
.globl vector182
vector182:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $182
801073a4:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801073a9:	e9 6a f2 ff ff       	jmp    80106618 <alltraps>

801073ae <vector183>:
.globl vector183
vector183:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $183
801073b0:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801073b5:	e9 5e f2 ff ff       	jmp    80106618 <alltraps>

801073ba <vector184>:
.globl vector184
vector184:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $184
801073bc:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801073c1:	e9 52 f2 ff ff       	jmp    80106618 <alltraps>

801073c6 <vector185>:
.globl vector185
vector185:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $185
801073c8:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801073cd:	e9 46 f2 ff ff       	jmp    80106618 <alltraps>

801073d2 <vector186>:
.globl vector186
vector186:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $186
801073d4:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801073d9:	e9 3a f2 ff ff       	jmp    80106618 <alltraps>

801073de <vector187>:
.globl vector187
vector187:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $187
801073e0:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801073e5:	e9 2e f2 ff ff       	jmp    80106618 <alltraps>

801073ea <vector188>:
.globl vector188
vector188:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $188
801073ec:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801073f1:	e9 22 f2 ff ff       	jmp    80106618 <alltraps>

801073f6 <vector189>:
.globl vector189
vector189:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $189
801073f8:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801073fd:	e9 16 f2 ff ff       	jmp    80106618 <alltraps>

80107402 <vector190>:
.globl vector190
vector190:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $190
80107404:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107409:	e9 0a f2 ff ff       	jmp    80106618 <alltraps>

8010740e <vector191>:
.globl vector191
vector191:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $191
80107410:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107415:	e9 fe f1 ff ff       	jmp    80106618 <alltraps>

8010741a <vector192>:
.globl vector192
vector192:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $192
8010741c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107421:	e9 f2 f1 ff ff       	jmp    80106618 <alltraps>

80107426 <vector193>:
.globl vector193
vector193:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $193
80107428:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010742d:	e9 e6 f1 ff ff       	jmp    80106618 <alltraps>

80107432 <vector194>:
.globl vector194
vector194:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $194
80107434:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107439:	e9 da f1 ff ff       	jmp    80106618 <alltraps>

8010743e <vector195>:
.globl vector195
vector195:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $195
80107440:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107445:	e9 ce f1 ff ff       	jmp    80106618 <alltraps>

8010744a <vector196>:
.globl vector196
vector196:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $196
8010744c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107451:	e9 c2 f1 ff ff       	jmp    80106618 <alltraps>

80107456 <vector197>:
.globl vector197
vector197:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $197
80107458:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010745d:	e9 b6 f1 ff ff       	jmp    80106618 <alltraps>

80107462 <vector198>:
.globl vector198
vector198:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $198
80107464:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107469:	e9 aa f1 ff ff       	jmp    80106618 <alltraps>

8010746e <vector199>:
.globl vector199
vector199:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $199
80107470:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107475:	e9 9e f1 ff ff       	jmp    80106618 <alltraps>

8010747a <vector200>:
.globl vector200
vector200:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $200
8010747c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107481:	e9 92 f1 ff ff       	jmp    80106618 <alltraps>

80107486 <vector201>:
.globl vector201
vector201:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $201
80107488:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010748d:	e9 86 f1 ff ff       	jmp    80106618 <alltraps>

80107492 <vector202>:
.globl vector202
vector202:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $202
80107494:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107499:	e9 7a f1 ff ff       	jmp    80106618 <alltraps>

8010749e <vector203>:
.globl vector203
vector203:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $203
801074a0:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801074a5:	e9 6e f1 ff ff       	jmp    80106618 <alltraps>

801074aa <vector204>:
.globl vector204
vector204:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $204
801074ac:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801074b1:	e9 62 f1 ff ff       	jmp    80106618 <alltraps>

801074b6 <vector205>:
.globl vector205
vector205:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $205
801074b8:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801074bd:	e9 56 f1 ff ff       	jmp    80106618 <alltraps>

801074c2 <vector206>:
.globl vector206
vector206:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $206
801074c4:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801074c9:	e9 4a f1 ff ff       	jmp    80106618 <alltraps>

801074ce <vector207>:
.globl vector207
vector207:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $207
801074d0:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801074d5:	e9 3e f1 ff ff       	jmp    80106618 <alltraps>

801074da <vector208>:
.globl vector208
vector208:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $208
801074dc:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801074e1:	e9 32 f1 ff ff       	jmp    80106618 <alltraps>

801074e6 <vector209>:
.globl vector209
vector209:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $209
801074e8:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801074ed:	e9 26 f1 ff ff       	jmp    80106618 <alltraps>

801074f2 <vector210>:
.globl vector210
vector210:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $210
801074f4:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801074f9:	e9 1a f1 ff ff       	jmp    80106618 <alltraps>

801074fe <vector211>:
.globl vector211
vector211:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $211
80107500:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107505:	e9 0e f1 ff ff       	jmp    80106618 <alltraps>

8010750a <vector212>:
.globl vector212
vector212:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $212
8010750c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107511:	e9 02 f1 ff ff       	jmp    80106618 <alltraps>

80107516 <vector213>:
.globl vector213
vector213:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $213
80107518:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010751d:	e9 f6 f0 ff ff       	jmp    80106618 <alltraps>

80107522 <vector214>:
.globl vector214
vector214:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $214
80107524:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107529:	e9 ea f0 ff ff       	jmp    80106618 <alltraps>

8010752e <vector215>:
.globl vector215
vector215:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $215
80107530:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107535:	e9 de f0 ff ff       	jmp    80106618 <alltraps>

8010753a <vector216>:
.globl vector216
vector216:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $216
8010753c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107541:	e9 d2 f0 ff ff       	jmp    80106618 <alltraps>

80107546 <vector217>:
.globl vector217
vector217:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $217
80107548:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010754d:	e9 c6 f0 ff ff       	jmp    80106618 <alltraps>

80107552 <vector218>:
.globl vector218
vector218:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $218
80107554:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107559:	e9 ba f0 ff ff       	jmp    80106618 <alltraps>

8010755e <vector219>:
.globl vector219
vector219:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $219
80107560:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107565:	e9 ae f0 ff ff       	jmp    80106618 <alltraps>

8010756a <vector220>:
.globl vector220
vector220:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $220
8010756c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107571:	e9 a2 f0 ff ff       	jmp    80106618 <alltraps>

80107576 <vector221>:
.globl vector221
vector221:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $221
80107578:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010757d:	e9 96 f0 ff ff       	jmp    80106618 <alltraps>

80107582 <vector222>:
.globl vector222
vector222:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $222
80107584:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107589:	e9 8a f0 ff ff       	jmp    80106618 <alltraps>

8010758e <vector223>:
.globl vector223
vector223:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $223
80107590:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107595:	e9 7e f0 ff ff       	jmp    80106618 <alltraps>

8010759a <vector224>:
.globl vector224
vector224:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $224
8010759c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801075a1:	e9 72 f0 ff ff       	jmp    80106618 <alltraps>

801075a6 <vector225>:
.globl vector225
vector225:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $225
801075a8:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801075ad:	e9 66 f0 ff ff       	jmp    80106618 <alltraps>

801075b2 <vector226>:
.globl vector226
vector226:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $226
801075b4:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801075b9:	e9 5a f0 ff ff       	jmp    80106618 <alltraps>

801075be <vector227>:
.globl vector227
vector227:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $227
801075c0:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801075c5:	e9 4e f0 ff ff       	jmp    80106618 <alltraps>

801075ca <vector228>:
.globl vector228
vector228:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $228
801075cc:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801075d1:	e9 42 f0 ff ff       	jmp    80106618 <alltraps>

801075d6 <vector229>:
.globl vector229
vector229:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $229
801075d8:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801075dd:	e9 36 f0 ff ff       	jmp    80106618 <alltraps>

801075e2 <vector230>:
.globl vector230
vector230:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $230
801075e4:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801075e9:	e9 2a f0 ff ff       	jmp    80106618 <alltraps>

801075ee <vector231>:
.globl vector231
vector231:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $231
801075f0:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801075f5:	e9 1e f0 ff ff       	jmp    80106618 <alltraps>

801075fa <vector232>:
.globl vector232
vector232:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $232
801075fc:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107601:	e9 12 f0 ff ff       	jmp    80106618 <alltraps>

80107606 <vector233>:
.globl vector233
vector233:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $233
80107608:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010760d:	e9 06 f0 ff ff       	jmp    80106618 <alltraps>

80107612 <vector234>:
.globl vector234
vector234:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $234
80107614:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107619:	e9 fa ef ff ff       	jmp    80106618 <alltraps>

8010761e <vector235>:
.globl vector235
vector235:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $235
80107620:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107625:	e9 ee ef ff ff       	jmp    80106618 <alltraps>

8010762a <vector236>:
.globl vector236
vector236:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $236
8010762c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107631:	e9 e2 ef ff ff       	jmp    80106618 <alltraps>

80107636 <vector237>:
.globl vector237
vector237:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $237
80107638:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010763d:	e9 d6 ef ff ff       	jmp    80106618 <alltraps>

80107642 <vector238>:
.globl vector238
vector238:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $238
80107644:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107649:	e9 ca ef ff ff       	jmp    80106618 <alltraps>

8010764e <vector239>:
.globl vector239
vector239:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $239
80107650:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107655:	e9 be ef ff ff       	jmp    80106618 <alltraps>

8010765a <vector240>:
.globl vector240
vector240:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $240
8010765c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107661:	e9 b2 ef ff ff       	jmp    80106618 <alltraps>

80107666 <vector241>:
.globl vector241
vector241:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $241
80107668:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010766d:	e9 a6 ef ff ff       	jmp    80106618 <alltraps>

80107672 <vector242>:
.globl vector242
vector242:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $242
80107674:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107679:	e9 9a ef ff ff       	jmp    80106618 <alltraps>

8010767e <vector243>:
.globl vector243
vector243:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $243
80107680:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107685:	e9 8e ef ff ff       	jmp    80106618 <alltraps>

8010768a <vector244>:
.globl vector244
vector244:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $244
8010768c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107691:	e9 82 ef ff ff       	jmp    80106618 <alltraps>

80107696 <vector245>:
.globl vector245
vector245:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $245
80107698:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010769d:	e9 76 ef ff ff       	jmp    80106618 <alltraps>

801076a2 <vector246>:
.globl vector246
vector246:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $246
801076a4:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801076a9:	e9 6a ef ff ff       	jmp    80106618 <alltraps>

801076ae <vector247>:
.globl vector247
vector247:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $247
801076b0:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801076b5:	e9 5e ef ff ff       	jmp    80106618 <alltraps>

801076ba <vector248>:
.globl vector248
vector248:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $248
801076bc:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801076c1:	e9 52 ef ff ff       	jmp    80106618 <alltraps>

801076c6 <vector249>:
.globl vector249
vector249:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $249
801076c8:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801076cd:	e9 46 ef ff ff       	jmp    80106618 <alltraps>

801076d2 <vector250>:
.globl vector250
vector250:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $250
801076d4:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801076d9:	e9 3a ef ff ff       	jmp    80106618 <alltraps>

801076de <vector251>:
.globl vector251
vector251:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $251
801076e0:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801076e5:	e9 2e ef ff ff       	jmp    80106618 <alltraps>

801076ea <vector252>:
.globl vector252
vector252:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $252
801076ec:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801076f1:	e9 22 ef ff ff       	jmp    80106618 <alltraps>

801076f6 <vector253>:
.globl vector253
vector253:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $253
801076f8:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801076fd:	e9 16 ef ff ff       	jmp    80106618 <alltraps>

80107702 <vector254>:
.globl vector254
vector254:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $254
80107704:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107709:	e9 0a ef ff ff       	jmp    80106618 <alltraps>

8010770e <vector255>:
.globl vector255
vector255:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $255
80107710:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107715:	e9 fe ee ff ff       	jmp    80106618 <alltraps>
	...

8010771c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010771c:	55                   	push   %ebp
8010771d:	89 e5                	mov    %esp,%ebp
8010771f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107722:	8b 45 0c             	mov    0xc(%ebp),%eax
80107725:	83 e8 01             	sub    $0x1,%eax
80107728:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010772c:	8b 45 08             	mov    0x8(%ebp),%eax
8010772f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107733:	8b 45 08             	mov    0x8(%ebp),%eax
80107736:	c1 e8 10             	shr    $0x10,%eax
80107739:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010773d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107740:	0f 01 10             	lgdtl  (%eax)
}
80107743:	c9                   	leave  
80107744:	c3                   	ret    

80107745 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107745:	55                   	push   %ebp
80107746:	89 e5                	mov    %esp,%ebp
80107748:	83 ec 04             	sub    $0x4,%esp
8010774b:	8b 45 08             	mov    0x8(%ebp),%eax
8010774e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107752:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107756:	0f 00 d8             	ltr    %ax
}
80107759:	c9                   	leave  
8010775a:	c3                   	ret    

8010775b <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010775b:	55                   	push   %ebp
8010775c:	89 e5                	mov    %esp,%ebp
8010775e:	83 ec 04             	sub    $0x4,%esp
80107761:	8b 45 08             	mov    0x8(%ebp),%eax
80107764:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107768:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010776c:	8e e8                	mov    %eax,%gs
}
8010776e:	c9                   	leave  
8010776f:	c3                   	ret    

80107770 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107770:	55                   	push   %ebp
80107771:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107773:	8b 45 08             	mov    0x8(%ebp),%eax
80107776:	0f 22 d8             	mov    %eax,%cr3
}
80107779:	5d                   	pop    %ebp
8010777a:	c3                   	ret    

8010777b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010777b:	55                   	push   %ebp
8010777c:	89 e5                	mov    %esp,%ebp
8010777e:	8b 45 08             	mov    0x8(%ebp),%eax
80107781:	05 00 00 00 80       	add    $0x80000000,%eax
80107786:	5d                   	pop    %ebp
80107787:	c3                   	ret    

80107788 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107788:	55                   	push   %ebp
80107789:	89 e5                	mov    %esp,%ebp
8010778b:	8b 45 08             	mov    0x8(%ebp),%eax
8010778e:	05 00 00 00 80       	add    $0x80000000,%eax
80107793:	5d                   	pop    %ebp
80107794:	c3                   	ret    

80107795 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107795:	55                   	push   %ebp
80107796:	89 e5                	mov    %esp,%ebp
80107798:	53                   	push   %ebx
80107799:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010779c:	e8 58 b9 ff ff       	call   801030f9 <cpunum>
801077a1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801077a7:	05 40 f9 10 80       	add    $0x8010f940,%eax
801077ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801077af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077b2:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801077b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077bb:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801077c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c4:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801077c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077cb:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077cf:	83 e2 f0             	and    $0xfffffff0,%edx
801077d2:	83 ca 0a             	or     $0xa,%edx
801077d5:	88 50 7d             	mov    %dl,0x7d(%eax)
801077d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077db:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077df:	83 ca 10             	or     $0x10,%edx
801077e2:	88 50 7d             	mov    %dl,0x7d(%eax)
801077e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e8:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077ec:	83 e2 9f             	and    $0xffffff9f,%edx
801077ef:	88 50 7d             	mov    %dl,0x7d(%eax)
801077f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f5:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077f9:	83 ca 80             	or     $0xffffff80,%edx
801077fc:	88 50 7d             	mov    %dl,0x7d(%eax)
801077ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107802:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107806:	83 ca 0f             	or     $0xf,%edx
80107809:	88 50 7e             	mov    %dl,0x7e(%eax)
8010780c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010780f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107813:	83 e2 ef             	and    $0xffffffef,%edx
80107816:	88 50 7e             	mov    %dl,0x7e(%eax)
80107819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107820:	83 e2 df             	and    $0xffffffdf,%edx
80107823:	88 50 7e             	mov    %dl,0x7e(%eax)
80107826:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107829:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010782d:	83 ca 40             	or     $0x40,%edx
80107830:	88 50 7e             	mov    %dl,0x7e(%eax)
80107833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107836:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010783a:	83 ca 80             	or     $0xffffff80,%edx
8010783d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107840:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107843:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107847:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107851:	ff ff 
80107853:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107856:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010785d:	00 00 
8010785f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107862:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107873:	83 e2 f0             	and    $0xfffffff0,%edx
80107876:	83 ca 02             	or     $0x2,%edx
80107879:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010787f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107882:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107889:	83 ca 10             	or     $0x10,%edx
8010788c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107892:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107895:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010789c:	83 e2 9f             	and    $0xffffff9f,%edx
8010789f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078af:	83 ca 80             	or     $0xffffff80,%edx
801078b2:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078bb:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078c2:	83 ca 0f             	or     $0xf,%edx
801078c5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ce:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078d5:	83 e2 ef             	and    $0xffffffef,%edx
801078d8:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e1:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078e8:	83 e2 df             	and    $0xffffffdf,%edx
801078eb:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f4:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078fb:	83 ca 40             	or     $0x40,%edx
801078fe:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107907:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010790e:	83 ca 80             	or     $0xffffff80,%edx
80107911:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107917:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010791a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107921:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107924:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010792b:	ff ff 
8010792d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107930:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107937:	00 00 
80107939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107943:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107946:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010794d:	83 e2 f0             	and    $0xfffffff0,%edx
80107950:	83 ca 0a             	or     $0xa,%edx
80107953:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107959:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107963:	83 ca 10             	or     $0x10,%edx
80107966:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010796c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010796f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107976:	83 ca 60             	or     $0x60,%edx
80107979:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010797f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107982:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107989:	83 ca 80             	or     $0xffffff80,%edx
8010798c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107992:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107995:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010799c:	83 ca 0f             	or     $0xf,%edx
8010799f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079af:	83 e2 ef             	and    $0xffffffef,%edx
801079b2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079bb:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079c2:	83 e2 df             	and    $0xffffffdf,%edx
801079c5:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ce:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079d5:	83 ca 40             	or     $0x40,%edx
801079d8:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801079e8:	83 ca 80             	or     $0xffffff80,%edx
801079eb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801079f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079f4:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801079fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079fe:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107a05:	ff ff 
80107a07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a0a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107a11:	00 00 
80107a13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a16:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a20:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a27:	83 e2 f0             	and    $0xfffffff0,%edx
80107a2a:	83 ca 02             	or     $0x2,%edx
80107a2d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a36:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a3d:	83 ca 10             	or     $0x10,%edx
80107a40:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a49:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a50:	83 ca 60             	or     $0x60,%edx
80107a53:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a63:	83 ca 80             	or     $0xffffff80,%edx
80107a66:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a6f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a76:	83 ca 0f             	or     $0xf,%edx
80107a79:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a82:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a89:	83 e2 ef             	and    $0xffffffef,%edx
80107a8c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a95:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107a9c:	83 e2 df             	and    $0xffffffdf,%edx
80107a9f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107aaf:	83 ca 40             	or     $0x40,%edx
80107ab2:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107abb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ac2:	83 ca 80             	or     $0xffffff80,%edx
80107ac5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ace:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad8:	05 b4 00 00 00       	add    $0xb4,%eax
80107add:	89 c3                	mov    %eax,%ebx
80107adf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae2:	05 b4 00 00 00       	add    $0xb4,%eax
80107ae7:	c1 e8 10             	shr    $0x10,%eax
80107aea:	89 c1                	mov    %eax,%ecx
80107aec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aef:	05 b4 00 00 00       	add    $0xb4,%eax
80107af4:	c1 e8 18             	shr    $0x18,%eax
80107af7:	89 c2                	mov    %eax,%edx
80107af9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afc:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107b03:	00 00 
80107b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b08:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b12:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107b18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b22:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b25:	83 c9 02             	or     $0x2,%ecx
80107b28:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b31:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b38:	83 c9 10             	or     $0x10,%ecx
80107b3b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b44:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b4b:	83 e1 9f             	and    $0xffffff9f,%ecx
80107b4e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b57:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b5e:	83 c9 80             	or     $0xffffff80,%ecx
80107b61:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b6a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b71:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b74:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b84:	83 e1 ef             	and    $0xffffffef,%ecx
80107b87:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107b8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b90:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107b97:	83 e1 df             	and    $0xffffffdf,%ecx
80107b9a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ba0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107baa:	83 c9 40             	or     $0x40,%ecx
80107bad:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bb6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107bbd:	83 c9 80             	or     $0xffffff80,%ecx
80107bc0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc9:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107bcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bd2:	83 c0 70             	add    $0x70,%eax
80107bd5:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107bdc:	00 
80107bdd:	89 04 24             	mov    %eax,(%esp)
80107be0:	e8 37 fb ff ff       	call   8010771c <lgdt>
  loadgs(SEG_KCPU << 3);
80107be5:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107bec:	e8 6a fb ff ff       	call   8010775b <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bf4:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107bfa:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107c01:	00 00 00 00 
}
80107c05:	83 c4 24             	add    $0x24,%esp
80107c08:	5b                   	pop    %ebx
80107c09:	5d                   	pop    %ebp
80107c0a:	c3                   	ret    

80107c0b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107c0b:	55                   	push   %ebp
80107c0c:	89 e5                	mov    %esp,%ebp
80107c0e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107c11:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c14:	c1 e8 16             	shr    $0x16,%eax
80107c17:	c1 e0 02             	shl    $0x2,%eax
80107c1a:	03 45 08             	add    0x8(%ebp),%eax
80107c1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107c20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c23:	8b 00                	mov    (%eax),%eax
80107c25:	83 e0 01             	and    $0x1,%eax
80107c28:	84 c0                	test   %al,%al
80107c2a:	74 17                	je     80107c43 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107c2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c2f:	8b 00                	mov    (%eax),%eax
80107c31:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107c36:	89 04 24             	mov    %eax,(%esp)
80107c39:	e8 4a fb ff ff       	call   80107788 <p2v>
80107c3e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c41:	eb 4b                	jmp    80107c8e <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107c43:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107c47:	74 0e                	je     80107c57 <walkpgdir+0x4c>
80107c49:	e8 1d b1 ff ff       	call   80102d6b <kalloc>
80107c4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107c51:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107c55:	75 07                	jne    80107c5e <walkpgdir+0x53>
      return 0;
80107c57:	b8 00 00 00 00       	mov    $0x0,%eax
80107c5c:	eb 41                	jmp    80107c9f <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107c5e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c65:	00 
80107c66:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c6d:	00 
80107c6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c71:	89 04 24             	mov    %eax,(%esp)
80107c74:	e8 e5 d3 ff ff       	call   8010505e <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c7c:	89 04 24             	mov    %eax,(%esp)
80107c7f:	e8 f7 fa ff ff       	call   8010777b <v2p>
80107c84:	89 c2                	mov    %eax,%edx
80107c86:	83 ca 07             	or     $0x7,%edx
80107c89:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c8c:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c91:	c1 e8 0c             	shr    $0xc,%eax
80107c94:	25 ff 03 00 00       	and    $0x3ff,%eax
80107c99:	c1 e0 02             	shl    $0x2,%eax
80107c9c:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107c9f:	c9                   	leave  
80107ca0:	c3                   	ret    

80107ca1 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107ca1:	55                   	push   %ebp
80107ca2:	89 e5                	mov    %esp,%ebp
80107ca4:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107ca7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107caa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107caf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107cb2:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cb5:	03 45 10             	add    0x10(%ebp),%eax
80107cb8:	83 e8 01             	sub    $0x1,%eax
80107cbb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107cc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107cc3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107cca:	00 
80107ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cce:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cd2:	8b 45 08             	mov    0x8(%ebp),%eax
80107cd5:	89 04 24             	mov    %eax,(%esp)
80107cd8:	e8 2e ff ff ff       	call   80107c0b <walkpgdir>
80107cdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107ce0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107ce4:	75 07                	jne    80107ced <mappages+0x4c>
      return -1;
80107ce6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107ceb:	eb 46                	jmp    80107d33 <mappages+0x92>
    if(*pte & PTE_P)
80107ced:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107cf0:	8b 00                	mov    (%eax),%eax
80107cf2:	83 e0 01             	and    $0x1,%eax
80107cf5:	84 c0                	test   %al,%al
80107cf7:	74 0c                	je     80107d05 <mappages+0x64>
      panic("remap");
80107cf9:	c7 04 24 c0 8b 10 80 	movl   $0x80108bc0,(%esp)
80107d00:	e8 38 88 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107d05:	8b 45 18             	mov    0x18(%ebp),%eax
80107d08:	0b 45 14             	or     0x14(%ebp),%eax
80107d0b:	89 c2                	mov    %eax,%edx
80107d0d:	83 ca 01             	or     $0x1,%edx
80107d10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d13:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107d15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d18:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d1b:	74 10                	je     80107d2d <mappages+0x8c>
      break;
    a += PGSIZE;
80107d1d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107d24:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107d2b:	eb 96                	jmp    80107cc3 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107d2d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107d2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107d33:	c9                   	leave  
80107d34:	c3                   	ret    

80107d35 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107d35:	55                   	push   %ebp
80107d36:	89 e5                	mov    %esp,%ebp
80107d38:	53                   	push   %ebx
80107d39:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107d3c:	e8 2a b0 ff ff       	call   80102d6b <kalloc>
80107d41:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107d44:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107d48:	75 0a                	jne    80107d54 <setupkvm+0x1f>
    return 0;
80107d4a:	b8 00 00 00 00       	mov    $0x0,%eax
80107d4f:	e9 98 00 00 00       	jmp    80107dec <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107d54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107d5b:	00 
80107d5c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107d63:	00 
80107d64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107d67:	89 04 24             	mov    %eax,(%esp)
80107d6a:	e8 ef d2 ff ff       	call   8010505e <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107d6f:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107d76:	e8 0d fa ff ff       	call   80107788 <p2v>
80107d7b:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107d80:	76 0c                	jbe    80107d8e <setupkvm+0x59>
    panic("PHYSTOP too high");
80107d82:	c7 04 24 c6 8b 10 80 	movl   $0x80108bc6,(%esp)
80107d89:	e8 af 87 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107d8e:	c7 45 f4 c0 b4 10 80 	movl   $0x8010b4c0,-0xc(%ebp)
80107d95:	eb 49                	jmp    80107de0 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107d97:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107d9a:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107d9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107da0:	8b 50 04             	mov    0x4(%eax),%edx
80107da3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107da6:	8b 58 08             	mov    0x8(%eax),%ebx
80107da9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dac:	8b 40 04             	mov    0x4(%eax),%eax
80107daf:	29 c3                	sub    %eax,%ebx
80107db1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db4:	8b 00                	mov    (%eax),%eax
80107db6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107dba:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107dbe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107dc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107dc9:	89 04 24             	mov    %eax,(%esp)
80107dcc:	e8 d0 fe ff ff       	call   80107ca1 <mappages>
80107dd1:	85 c0                	test   %eax,%eax
80107dd3:	79 07                	jns    80107ddc <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107dd5:	b8 00 00 00 00       	mov    $0x0,%eax
80107dda:	eb 10                	jmp    80107dec <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107ddc:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107de0:	81 7d f4 00 b5 10 80 	cmpl   $0x8010b500,-0xc(%ebp)
80107de7:	72 ae                	jb     80107d97 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107de9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107dec:	83 c4 34             	add    $0x34,%esp
80107def:	5b                   	pop    %ebx
80107df0:	5d                   	pop    %ebp
80107df1:	c3                   	ret    

80107df2 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107df2:	55                   	push   %ebp
80107df3:	89 e5                	mov    %esp,%ebp
80107df5:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107df8:	e8 38 ff ff ff       	call   80107d35 <setupkvm>
80107dfd:	a3 18 27 11 80       	mov    %eax,0x80112718
  switchkvm();
80107e02:	e8 02 00 00 00       	call   80107e09 <switchkvm>
}
80107e07:	c9                   	leave  
80107e08:	c3                   	ret    

80107e09 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107e09:	55                   	push   %ebp
80107e0a:	89 e5                	mov    %esp,%ebp
80107e0c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107e0f:	a1 18 27 11 80       	mov    0x80112718,%eax
80107e14:	89 04 24             	mov    %eax,(%esp)
80107e17:	e8 5f f9 ff ff       	call   8010777b <v2p>
80107e1c:	89 04 24             	mov    %eax,(%esp)
80107e1f:	e8 4c f9 ff ff       	call   80107770 <lcr3>
}
80107e24:	c9                   	leave  
80107e25:	c3                   	ret    

80107e26 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107e26:	55                   	push   %ebp
80107e27:	89 e5                	mov    %esp,%ebp
80107e29:	53                   	push   %ebx
80107e2a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107e2d:	e8 25 d1 ff ff       	call   80104f57 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107e32:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107e38:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e3f:	83 c2 08             	add    $0x8,%edx
80107e42:	89 d3                	mov    %edx,%ebx
80107e44:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e4b:	83 c2 08             	add    $0x8,%edx
80107e4e:	c1 ea 10             	shr    $0x10,%edx
80107e51:	89 d1                	mov    %edx,%ecx
80107e53:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107e5a:	83 c2 08             	add    $0x8,%edx
80107e5d:	c1 ea 18             	shr    $0x18,%edx
80107e60:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107e67:	67 00 
80107e69:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107e70:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107e76:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107e7d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e80:	83 c9 09             	or     $0x9,%ecx
80107e83:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107e89:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107e90:	83 c9 10             	or     $0x10,%ecx
80107e93:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107e99:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ea0:	83 e1 9f             	and    $0xffffff9f,%ecx
80107ea3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ea9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107eb0:	83 c9 80             	or     $0xffffff80,%ecx
80107eb3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107eb9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ec0:	83 e1 f0             	and    $0xfffffff0,%ecx
80107ec3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ec9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ed0:	83 e1 ef             	and    $0xffffffef,%ecx
80107ed3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ed9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ee0:	83 e1 df             	and    $0xffffffdf,%ecx
80107ee3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ee9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107ef0:	83 c9 40             	or     $0x40,%ecx
80107ef3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ef9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f00:	83 e1 7f             	and    $0x7f,%ecx
80107f03:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f09:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107f0f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f15:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107f1c:	83 e2 ef             	and    $0xffffffef,%edx
80107f1f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107f25:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f2b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107f31:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f37:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107f3e:	8b 52 08             	mov    0x8(%edx),%edx
80107f41:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107f47:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107f4a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107f51:	e8 ef f7 ff ff       	call   80107745 <ltr>
  if(p->pgdir == 0)
80107f56:	8b 45 08             	mov    0x8(%ebp),%eax
80107f59:	8b 40 04             	mov    0x4(%eax),%eax
80107f5c:	85 c0                	test   %eax,%eax
80107f5e:	75 0c                	jne    80107f6c <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107f60:	c7 04 24 d7 8b 10 80 	movl   $0x80108bd7,(%esp)
80107f67:	e8 d1 85 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107f6c:	8b 45 08             	mov    0x8(%ebp),%eax
80107f6f:	8b 40 04             	mov    0x4(%eax),%eax
80107f72:	89 04 24             	mov    %eax,(%esp)
80107f75:	e8 01 f8 ff ff       	call   8010777b <v2p>
80107f7a:	89 04 24             	mov    %eax,(%esp)
80107f7d:	e8 ee f7 ff ff       	call   80107770 <lcr3>
  popcli();
80107f82:	e8 18 d0 ff ff       	call   80104f9f <popcli>
}
80107f87:	83 c4 14             	add    $0x14,%esp
80107f8a:	5b                   	pop    %ebx
80107f8b:	5d                   	pop    %ebp
80107f8c:	c3                   	ret    

80107f8d <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107f8d:	55                   	push   %ebp
80107f8e:	89 e5                	mov    %esp,%ebp
80107f90:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107f93:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107f9a:	76 0c                	jbe    80107fa8 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107f9c:	c7 04 24 eb 8b 10 80 	movl   $0x80108beb,(%esp)
80107fa3:	e8 95 85 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107fa8:	e8 be ad ff ff       	call   80102d6b <kalloc>
80107fad:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107fb0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fb7:	00 
80107fb8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107fbf:	00 
80107fc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fc3:	89 04 24             	mov    %eax,(%esp)
80107fc6:	e8 93 d0 ff ff       	call   8010505e <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107fcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fce:	89 04 24             	mov    %eax,(%esp)
80107fd1:	e8 a5 f7 ff ff       	call   8010777b <v2p>
80107fd6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107fdd:	00 
80107fde:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107fe2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fe9:	00 
80107fea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ff1:	00 
80107ff2:	8b 45 08             	mov    0x8(%ebp),%eax
80107ff5:	89 04 24             	mov    %eax,(%esp)
80107ff8:	e8 a4 fc ff ff       	call   80107ca1 <mappages>
  memmove(mem, init, sz);
80107ffd:	8b 45 10             	mov    0x10(%ebp),%eax
80108000:	89 44 24 08          	mov    %eax,0x8(%esp)
80108004:	8b 45 0c             	mov    0xc(%ebp),%eax
80108007:	89 44 24 04          	mov    %eax,0x4(%esp)
8010800b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800e:	89 04 24             	mov    %eax,(%esp)
80108011:	e8 1b d1 ff ff       	call   80105131 <memmove>
}
80108016:	c9                   	leave  
80108017:	c3                   	ret    

80108018 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108018:	55                   	push   %ebp
80108019:	89 e5                	mov    %esp,%ebp
8010801b:	53                   	push   %ebx
8010801c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010801f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108022:	25 ff 0f 00 00       	and    $0xfff,%eax
80108027:	85 c0                	test   %eax,%eax
80108029:	74 0c                	je     80108037 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010802b:	c7 04 24 08 8c 10 80 	movl   $0x80108c08,(%esp)
80108032:	e8 06 85 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108037:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010803e:	e9 ad 00 00 00       	jmp    801080f0 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108043:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108046:	8b 55 0c             	mov    0xc(%ebp),%edx
80108049:	01 d0                	add    %edx,%eax
8010804b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108052:	00 
80108053:	89 44 24 04          	mov    %eax,0x4(%esp)
80108057:	8b 45 08             	mov    0x8(%ebp),%eax
8010805a:	89 04 24             	mov    %eax,(%esp)
8010805d:	e8 a9 fb ff ff       	call   80107c0b <walkpgdir>
80108062:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108065:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108069:	75 0c                	jne    80108077 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
8010806b:	c7 04 24 2b 8c 10 80 	movl   $0x80108c2b,(%esp)
80108072:	e8 c6 84 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108077:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010807a:	8b 00                	mov    (%eax),%eax
8010807c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108081:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108084:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108087:	8b 55 18             	mov    0x18(%ebp),%edx
8010808a:	89 d1                	mov    %edx,%ecx
8010808c:	29 c1                	sub    %eax,%ecx
8010808e:	89 c8                	mov    %ecx,%eax
80108090:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108095:	77 11                	ja     801080a8 <loaduvm+0x90>
      n = sz - i;
80108097:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809a:	8b 55 18             	mov    0x18(%ebp),%edx
8010809d:	89 d1                	mov    %edx,%ecx
8010809f:	29 c1                	sub    %eax,%ecx
801080a1:	89 c8                	mov    %ecx,%eax
801080a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801080a6:	eb 07                	jmp    801080af <loaduvm+0x97>
    else
      n = PGSIZE;
801080a8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801080af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080b2:	8b 55 14             	mov    0x14(%ebp),%edx
801080b5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801080b8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801080bb:	89 04 24             	mov    %eax,(%esp)
801080be:	e8 c5 f6 ff ff       	call   80107788 <p2v>
801080c3:	8b 55 f0             	mov    -0x10(%ebp),%edx
801080c6:	89 54 24 0c          	mov    %edx,0xc(%esp)
801080ca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
801080ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d2:	8b 45 10             	mov    0x10(%ebp),%eax
801080d5:	89 04 24             	mov    %eax,(%esp)
801080d8:	e8 ed 9e ff ff       	call   80101fca <readi>
801080dd:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801080e0:	74 07                	je     801080e9 <loaduvm+0xd1>
      return -1;
801080e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801080e7:	eb 18                	jmp    80108101 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801080e9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801080f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f3:	3b 45 18             	cmp    0x18(%ebp),%eax
801080f6:	0f 82 47 ff ff ff    	jb     80108043 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
801080fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108101:	83 c4 24             	add    $0x24,%esp
80108104:	5b                   	pop    %ebx
80108105:	5d                   	pop    %ebp
80108106:	c3                   	ret    

80108107 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108107:	55                   	push   %ebp
80108108:	89 e5                	mov    %esp,%ebp
8010810a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
8010810d:	8b 45 10             	mov    0x10(%ebp),%eax
80108110:	85 c0                	test   %eax,%eax
80108112:	79 0a                	jns    8010811e <allocuvm+0x17>
    return 0;
80108114:	b8 00 00 00 00       	mov    $0x0,%eax
80108119:	e9 c1 00 00 00       	jmp    801081df <allocuvm+0xd8>
  if(newsz < oldsz)
8010811e:	8b 45 10             	mov    0x10(%ebp),%eax
80108121:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108124:	73 08                	jae    8010812e <allocuvm+0x27>
    return oldsz;
80108126:	8b 45 0c             	mov    0xc(%ebp),%eax
80108129:	e9 b1 00 00 00       	jmp    801081df <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010812e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108131:	05 ff 0f 00 00       	add    $0xfff,%eax
80108136:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010813b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010813e:	e9 8d 00 00 00       	jmp    801081d0 <allocuvm+0xc9>
    mem = kalloc();
80108143:	e8 23 ac ff ff       	call   80102d6b <kalloc>
80108148:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010814b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010814f:	75 2c                	jne    8010817d <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108151:	c7 04 24 49 8c 10 80 	movl   $0x80108c49,(%esp)
80108158:	e8 44 82 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010815d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108160:	89 44 24 08          	mov    %eax,0x8(%esp)
80108164:	8b 45 10             	mov    0x10(%ebp),%eax
80108167:	89 44 24 04          	mov    %eax,0x4(%esp)
8010816b:	8b 45 08             	mov    0x8(%ebp),%eax
8010816e:	89 04 24             	mov    %eax,(%esp)
80108171:	e8 6b 00 00 00       	call   801081e1 <deallocuvm>
      return 0;
80108176:	b8 00 00 00 00       	mov    $0x0,%eax
8010817b:	eb 62                	jmp    801081df <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
8010817d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108184:	00 
80108185:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010818c:	00 
8010818d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108190:	89 04 24             	mov    %eax,(%esp)
80108193:	e8 c6 ce ff ff       	call   8010505e <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108198:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010819b:	89 04 24             	mov    %eax,(%esp)
8010819e:	e8 d8 f5 ff ff       	call   8010777b <v2p>
801081a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801081a6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801081ad:	00 
801081ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
801081b2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081b9:	00 
801081ba:	89 54 24 04          	mov    %edx,0x4(%esp)
801081be:	8b 45 08             	mov    0x8(%ebp),%eax
801081c1:	89 04 24             	mov    %eax,(%esp)
801081c4:	e8 d8 fa ff ff       	call   80107ca1 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801081c9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801081d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081d3:	3b 45 10             	cmp    0x10(%ebp),%eax
801081d6:	0f 82 67 ff ff ff    	jb     80108143 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
801081dc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801081df:	c9                   	leave  
801081e0:	c3                   	ret    

801081e1 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801081e1:	55                   	push   %ebp
801081e2:	89 e5                	mov    %esp,%ebp
801081e4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801081e7:	8b 45 10             	mov    0x10(%ebp),%eax
801081ea:	3b 45 0c             	cmp    0xc(%ebp),%eax
801081ed:	72 08                	jb     801081f7 <deallocuvm+0x16>
    return oldsz;
801081ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801081f2:	e9 a4 00 00 00       	jmp    8010829b <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
801081f7:	8b 45 10             	mov    0x10(%ebp),%eax
801081fa:	05 ff 0f 00 00       	add    $0xfff,%eax
801081ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108204:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108207:	e9 80 00 00 00       	jmp    8010828c <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010820c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010820f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108216:	00 
80108217:	89 44 24 04          	mov    %eax,0x4(%esp)
8010821b:	8b 45 08             	mov    0x8(%ebp),%eax
8010821e:	89 04 24             	mov    %eax,(%esp)
80108221:	e8 e5 f9 ff ff       	call   80107c0b <walkpgdir>
80108226:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108229:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010822d:	75 09                	jne    80108238 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010822f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108236:	eb 4d                	jmp    80108285 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108238:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010823b:	8b 00                	mov    (%eax),%eax
8010823d:	83 e0 01             	and    $0x1,%eax
80108240:	84 c0                	test   %al,%al
80108242:	74 41                	je     80108285 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108244:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108247:	8b 00                	mov    (%eax),%eax
80108249:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010824e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108251:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108255:	75 0c                	jne    80108263 <deallocuvm+0x82>
        panic("kfree");
80108257:	c7 04 24 61 8c 10 80 	movl   $0x80108c61,(%esp)
8010825e:	e8 da 82 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80108263:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108266:	89 04 24             	mov    %eax,(%esp)
80108269:	e8 1a f5 ff ff       	call   80107788 <p2v>
8010826e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108271:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108274:	89 04 24             	mov    %eax,(%esp)
80108277:	e8 56 aa ff ff       	call   80102cd2 <kfree>
      *pte = 0;
8010827c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010827f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108285:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010828c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010828f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108292:	0f 82 74 ff ff ff    	jb     8010820c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108298:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010829b:	c9                   	leave  
8010829c:	c3                   	ret    

8010829d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010829d:	55                   	push   %ebp
8010829e:	89 e5                	mov    %esp,%ebp
801082a0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801082a3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801082a7:	75 0c                	jne    801082b5 <freevm+0x18>
    panic("freevm: no pgdir");
801082a9:	c7 04 24 67 8c 10 80 	movl   $0x80108c67,(%esp)
801082b0:	e8 88 82 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801082b5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801082bc:	00 
801082bd:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
801082c4:	80 
801082c5:	8b 45 08             	mov    0x8(%ebp),%eax
801082c8:	89 04 24             	mov    %eax,(%esp)
801082cb:	e8 11 ff ff ff       	call   801081e1 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801082d0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801082d7:	eb 3c                	jmp    80108315 <freevm+0x78>
    if(pgdir[i] & PTE_P){
801082d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082dc:	c1 e0 02             	shl    $0x2,%eax
801082df:	03 45 08             	add    0x8(%ebp),%eax
801082e2:	8b 00                	mov    (%eax),%eax
801082e4:	83 e0 01             	and    $0x1,%eax
801082e7:	84 c0                	test   %al,%al
801082e9:	74 26                	je     80108311 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
801082eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082ee:	c1 e0 02             	shl    $0x2,%eax
801082f1:	03 45 08             	add    0x8(%ebp),%eax
801082f4:	8b 00                	mov    (%eax),%eax
801082f6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082fb:	89 04 24             	mov    %eax,(%esp)
801082fe:	e8 85 f4 ff ff       	call   80107788 <p2v>
80108303:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108306:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108309:	89 04 24             	mov    %eax,(%esp)
8010830c:	e8 c1 a9 ff ff       	call   80102cd2 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108311:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108315:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010831c:	76 bb                	jbe    801082d9 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010831e:	8b 45 08             	mov    0x8(%ebp),%eax
80108321:	89 04 24             	mov    %eax,(%esp)
80108324:	e8 a9 a9 ff ff       	call   80102cd2 <kfree>
}
80108329:	c9                   	leave  
8010832a:	c3                   	ret    

8010832b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010832b:	55                   	push   %ebp
8010832c:	89 e5                	mov    %esp,%ebp
8010832e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108331:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108338:	00 
80108339:	8b 45 0c             	mov    0xc(%ebp),%eax
8010833c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108340:	8b 45 08             	mov    0x8(%ebp),%eax
80108343:	89 04 24             	mov    %eax,(%esp)
80108346:	e8 c0 f8 ff ff       	call   80107c0b <walkpgdir>
8010834b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010834e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108352:	75 0c                	jne    80108360 <clearpteu+0x35>
    panic("clearpteu");
80108354:	c7 04 24 78 8c 10 80 	movl   $0x80108c78,(%esp)
8010835b:	e8 dd 81 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108363:	8b 00                	mov    (%eax),%eax
80108365:	89 c2                	mov    %eax,%edx
80108367:	83 e2 fb             	and    $0xfffffffb,%edx
8010836a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836d:	89 10                	mov    %edx,(%eax)
}
8010836f:	c9                   	leave  
80108370:	c3                   	ret    

80108371 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108371:	55                   	push   %ebp
80108372:	89 e5                	mov    %esp,%ebp
80108374:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108377:	e8 b9 f9 ff ff       	call   80107d35 <setupkvm>
8010837c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010837f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108383:	75 0a                	jne    8010838f <copyuvm+0x1e>
    return 0;
80108385:	b8 00 00 00 00       	mov    $0x0,%eax
8010838a:	e9 f1 00 00 00       	jmp    80108480 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010838f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108396:	e9 c0 00 00 00       	jmp    8010845b <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010839b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010839e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083a5:	00 
801083a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801083aa:	8b 45 08             	mov    0x8(%ebp),%eax
801083ad:	89 04 24             	mov    %eax,(%esp)
801083b0:	e8 56 f8 ff ff       	call   80107c0b <walkpgdir>
801083b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801083b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801083bc:	75 0c                	jne    801083ca <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801083be:	c7 04 24 82 8c 10 80 	movl   $0x80108c82,(%esp)
801083c5:	e8 73 81 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801083ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083cd:	8b 00                	mov    (%eax),%eax
801083cf:	83 e0 01             	and    $0x1,%eax
801083d2:	85 c0                	test   %eax,%eax
801083d4:	75 0c                	jne    801083e2 <copyuvm+0x71>
      panic("copyuvm: page not present");
801083d6:	c7 04 24 9c 8c 10 80 	movl   $0x80108c9c,(%esp)
801083dd:	e8 5b 81 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801083e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083e5:	8b 00                	mov    (%eax),%eax
801083e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083ec:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801083ef:	e8 77 a9 ff ff       	call   80102d6b <kalloc>
801083f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801083f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801083fb:	74 6f                	je     8010846c <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801083fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108400:	89 04 24             	mov    %eax,(%esp)
80108403:	e8 80 f3 ff ff       	call   80107788 <p2v>
80108408:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010840f:	00 
80108410:	89 44 24 04          	mov    %eax,0x4(%esp)
80108414:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108417:	89 04 24             	mov    %eax,(%esp)
8010841a:	e8 12 cd ff ff       	call   80105131 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010841f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108422:	89 04 24             	mov    %eax,(%esp)
80108425:	e8 51 f3 ff ff       	call   8010777b <v2p>
8010842a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010842d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108434:	00 
80108435:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108439:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108440:	00 
80108441:	89 54 24 04          	mov    %edx,0x4(%esp)
80108445:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108448:	89 04 24             	mov    %eax,(%esp)
8010844b:	e8 51 f8 ff ff       	call   80107ca1 <mappages>
80108450:	85 c0                	test   %eax,%eax
80108452:	78 1b                	js     8010846f <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108454:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010845b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010845e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108461:	0f 82 34 ff ff ff    	jb     8010839b <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108467:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010846a:	eb 14                	jmp    80108480 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
8010846c:	90                   	nop
8010846d:	eb 01                	jmp    80108470 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010846f:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108470:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108473:	89 04 24             	mov    %eax,(%esp)
80108476:	e8 22 fe ff ff       	call   8010829d <freevm>
  return 0;
8010847b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108480:	c9                   	leave  
80108481:	c3                   	ret    

80108482 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108482:	55                   	push   %ebp
80108483:	89 e5                	mov    %esp,%ebp
80108485:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108488:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010848f:	00 
80108490:	8b 45 0c             	mov    0xc(%ebp),%eax
80108493:	89 44 24 04          	mov    %eax,0x4(%esp)
80108497:	8b 45 08             	mov    0x8(%ebp),%eax
8010849a:	89 04 24             	mov    %eax,(%esp)
8010849d:	e8 69 f7 ff ff       	call   80107c0b <walkpgdir>
801084a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801084a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a8:	8b 00                	mov    (%eax),%eax
801084aa:	83 e0 01             	and    $0x1,%eax
801084ad:	85 c0                	test   %eax,%eax
801084af:	75 07                	jne    801084b8 <uva2ka+0x36>
    return 0;
801084b1:	b8 00 00 00 00       	mov    $0x0,%eax
801084b6:	eb 25                	jmp    801084dd <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801084b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084bb:	8b 00                	mov    (%eax),%eax
801084bd:	83 e0 04             	and    $0x4,%eax
801084c0:	85 c0                	test   %eax,%eax
801084c2:	75 07                	jne    801084cb <uva2ka+0x49>
    return 0;
801084c4:	b8 00 00 00 00       	mov    $0x0,%eax
801084c9:	eb 12                	jmp    801084dd <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801084cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ce:	8b 00                	mov    (%eax),%eax
801084d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084d5:	89 04 24             	mov    %eax,(%esp)
801084d8:	e8 ab f2 ff ff       	call   80107788 <p2v>
}
801084dd:	c9                   	leave  
801084de:	c3                   	ret    

801084df <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801084df:	55                   	push   %ebp
801084e0:	89 e5                	mov    %esp,%ebp
801084e2:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801084e5:	8b 45 10             	mov    0x10(%ebp),%eax
801084e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801084eb:	e9 8b 00 00 00       	jmp    8010857b <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801084f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801084f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801084f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801084fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801084fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80108502:	8b 45 08             	mov    0x8(%ebp),%eax
80108505:	89 04 24             	mov    %eax,(%esp)
80108508:	e8 75 ff ff ff       	call   80108482 <uva2ka>
8010850d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108510:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108514:	75 07                	jne    8010851d <copyout+0x3e>
      return -1;
80108516:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010851b:	eb 6d                	jmp    8010858a <copyout+0xab>
    n = PGSIZE - (va - va0);
8010851d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108520:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108523:	89 d1                	mov    %edx,%ecx
80108525:	29 c1                	sub    %eax,%ecx
80108527:	89 c8                	mov    %ecx,%eax
80108529:	05 00 10 00 00       	add    $0x1000,%eax
8010852e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108531:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108534:	3b 45 14             	cmp    0x14(%ebp),%eax
80108537:	76 06                	jbe    8010853f <copyout+0x60>
      n = len;
80108539:	8b 45 14             	mov    0x14(%ebp),%eax
8010853c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010853f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108542:	8b 55 0c             	mov    0xc(%ebp),%edx
80108545:	89 d1                	mov    %edx,%ecx
80108547:	29 c1                	sub    %eax,%ecx
80108549:	89 c8                	mov    %ecx,%eax
8010854b:	03 45 e8             	add    -0x18(%ebp),%eax
8010854e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108551:	89 54 24 08          	mov    %edx,0x8(%esp)
80108555:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108558:	89 54 24 04          	mov    %edx,0x4(%esp)
8010855c:	89 04 24             	mov    %eax,(%esp)
8010855f:	e8 cd cb ff ff       	call   80105131 <memmove>
    len -= n;
80108564:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108567:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010856a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010856d:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108570:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108573:	05 00 10 00 00       	add    $0x1000,%eax
80108578:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010857b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010857f:	0f 85 6b ff ff ff    	jne    801084f0 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108585:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010858a:	c9                   	leave  
8010858b:	c3                   	ret    

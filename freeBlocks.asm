
_freeBlocks:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:



int 
main(void)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
  getFreeBlocks();
   6:	e8 11 03 00 00       	call   31c <getFreeBlocks>
  exit();
   b:	e8 64 02 00 00       	call   274 <exit>

00000010 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  10:	55                   	push   %ebp
  11:	89 e5                	mov    %esp,%ebp
  13:	57                   	push   %edi
  14:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  15:	8b 4d 08             	mov    0x8(%ebp),%ecx
  18:	8b 55 10             	mov    0x10(%ebp),%edx
  1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  1e:	89 cb                	mov    %ecx,%ebx
  20:	89 df                	mov    %ebx,%edi
  22:	89 d1                	mov    %edx,%ecx
  24:	fc                   	cld    
  25:	f3 aa                	rep stos %al,%es:(%edi)
  27:	89 ca                	mov    %ecx,%edx
  29:	89 fb                	mov    %edi,%ebx
  2b:	89 5d 08             	mov    %ebx,0x8(%ebp)
  2e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  31:	5b                   	pop    %ebx
  32:	5f                   	pop    %edi
  33:	5d                   	pop    %ebp
  34:	c3                   	ret    

00000035 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  35:	55                   	push   %ebp
  36:	89 e5                	mov    %esp,%ebp
  38:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  3b:	8b 45 08             	mov    0x8(%ebp),%eax
  3e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  41:	90                   	nop
  42:	8b 45 0c             	mov    0xc(%ebp),%eax
  45:	0f b6 10             	movzbl (%eax),%edx
  48:	8b 45 08             	mov    0x8(%ebp),%eax
  4b:	88 10                	mov    %dl,(%eax)
  4d:	8b 45 08             	mov    0x8(%ebp),%eax
  50:	0f b6 00             	movzbl (%eax),%eax
  53:	84 c0                	test   %al,%al
  55:	0f 95 c0             	setne  %al
  58:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  5c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  60:	84 c0                	test   %al,%al
  62:	75 de                	jne    42 <strcpy+0xd>
    ;
  return os;
  64:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  67:	c9                   	leave  
  68:	c3                   	ret    

00000069 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  69:	55                   	push   %ebp
  6a:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  6c:	eb 08                	jmp    76 <strcmp+0xd>
    p++, q++;
  6e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  72:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  76:	8b 45 08             	mov    0x8(%ebp),%eax
  79:	0f b6 00             	movzbl (%eax),%eax
  7c:	84 c0                	test   %al,%al
  7e:	74 10                	je     90 <strcmp+0x27>
  80:	8b 45 08             	mov    0x8(%ebp),%eax
  83:	0f b6 10             	movzbl (%eax),%edx
  86:	8b 45 0c             	mov    0xc(%ebp),%eax
  89:	0f b6 00             	movzbl (%eax),%eax
  8c:	38 c2                	cmp    %al,%dl
  8e:	74 de                	je     6e <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  90:	8b 45 08             	mov    0x8(%ebp),%eax
  93:	0f b6 00             	movzbl (%eax),%eax
  96:	0f b6 d0             	movzbl %al,%edx
  99:	8b 45 0c             	mov    0xc(%ebp),%eax
  9c:	0f b6 00             	movzbl (%eax),%eax
  9f:	0f b6 c0             	movzbl %al,%eax
  a2:	89 d1                	mov    %edx,%ecx
  a4:	29 c1                	sub    %eax,%ecx
  a6:	89 c8                	mov    %ecx,%eax
}
  a8:	5d                   	pop    %ebp
  a9:	c3                   	ret    

000000aa <strlen>:

uint
strlen(char *s)
{
  aa:	55                   	push   %ebp
  ab:	89 e5                	mov    %esp,%ebp
  ad:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
  b0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  b7:	eb 04                	jmp    bd <strlen+0x13>
  b9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  c0:	03 45 08             	add    0x8(%ebp),%eax
  c3:	0f b6 00             	movzbl (%eax),%eax
  c6:	84 c0                	test   %al,%al
  c8:	75 ef                	jne    b9 <strlen+0xf>
    ;
  return n;
  ca:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  cd:	c9                   	leave  
  ce:	c3                   	ret    

000000cf <memset>:

void*
memset(void *dst, int c, uint n)
{
  cf:	55                   	push   %ebp
  d0:	89 e5                	mov    %esp,%ebp
  d2:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
  d5:	8b 45 10             	mov    0x10(%ebp),%eax
  d8:	89 44 24 08          	mov    %eax,0x8(%esp)
  dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  df:	89 44 24 04          	mov    %eax,0x4(%esp)
  e3:	8b 45 08             	mov    0x8(%ebp),%eax
  e6:	89 04 24             	mov    %eax,(%esp)
  e9:	e8 22 ff ff ff       	call   10 <stosb>
  return dst;
  ee:	8b 45 08             	mov    0x8(%ebp),%eax
}
  f1:	c9                   	leave  
  f2:	c3                   	ret    

000000f3 <strchr>:

char*
strchr(const char *s, char c)
{
  f3:	55                   	push   %ebp
  f4:	89 e5                	mov    %esp,%ebp
  f6:	83 ec 04             	sub    $0x4,%esp
  f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  fc:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
  ff:	eb 14                	jmp    115 <strchr+0x22>
    if(*s == c)
 101:	8b 45 08             	mov    0x8(%ebp),%eax
 104:	0f b6 00             	movzbl (%eax),%eax
 107:	3a 45 fc             	cmp    -0x4(%ebp),%al
 10a:	75 05                	jne    111 <strchr+0x1e>
      return (char*)s;
 10c:	8b 45 08             	mov    0x8(%ebp),%eax
 10f:	eb 13                	jmp    124 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 111:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 115:	8b 45 08             	mov    0x8(%ebp),%eax
 118:	0f b6 00             	movzbl (%eax),%eax
 11b:	84 c0                	test   %al,%al
 11d:	75 e2                	jne    101 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 11f:	b8 00 00 00 00       	mov    $0x0,%eax
}
 124:	c9                   	leave  
 125:	c3                   	ret    

00000126 <gets>:

char*
gets(char *buf, int max)
{
 126:	55                   	push   %ebp
 127:	89 e5                	mov    %esp,%ebp
 129:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 12c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 133:	eb 44                	jmp    179 <gets+0x53>
    cc = read(0, &c, 1);
 135:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 13c:	00 
 13d:	8d 45 ef             	lea    -0x11(%ebp),%eax
 140:	89 44 24 04          	mov    %eax,0x4(%esp)
 144:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 14b:	e8 3c 01 00 00       	call   28c <read>
 150:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 153:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 157:	7e 2d                	jle    186 <gets+0x60>
      break;
    buf[i++] = c;
 159:	8b 45 f4             	mov    -0xc(%ebp),%eax
 15c:	03 45 08             	add    0x8(%ebp),%eax
 15f:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 163:	88 10                	mov    %dl,(%eax)
 165:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 169:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 16d:	3c 0a                	cmp    $0xa,%al
 16f:	74 16                	je     187 <gets+0x61>
 171:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 175:	3c 0d                	cmp    $0xd,%al
 177:	74 0e                	je     187 <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 179:	8b 45 f4             	mov    -0xc(%ebp),%eax
 17c:	83 c0 01             	add    $0x1,%eax
 17f:	3b 45 0c             	cmp    0xc(%ebp),%eax
 182:	7c b1                	jl     135 <gets+0xf>
 184:	eb 01                	jmp    187 <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 186:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 187:	8b 45 f4             	mov    -0xc(%ebp),%eax
 18a:	03 45 08             	add    0x8(%ebp),%eax
 18d:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 190:	8b 45 08             	mov    0x8(%ebp),%eax
}
 193:	c9                   	leave  
 194:	c3                   	ret    

00000195 <stat>:

int
stat(char *n, struct stat *st)
{
 195:	55                   	push   %ebp
 196:	89 e5                	mov    %esp,%ebp
 198:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 19b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1a2:	00 
 1a3:	8b 45 08             	mov    0x8(%ebp),%eax
 1a6:	89 04 24             	mov    %eax,(%esp)
 1a9:	e8 06 01 00 00       	call   2b4 <open>
 1ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 1b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 1b5:	79 07                	jns    1be <stat+0x29>
    return -1;
 1b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 1bc:	eb 23                	jmp    1e1 <stat+0x4c>
  r = fstat(fd, st);
 1be:	8b 45 0c             	mov    0xc(%ebp),%eax
 1c1:	89 44 24 04          	mov    %eax,0x4(%esp)
 1c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1c8:	89 04 24             	mov    %eax,(%esp)
 1cb:	e8 fc 00 00 00       	call   2cc <fstat>
 1d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 1d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1d6:	89 04 24             	mov    %eax,(%esp)
 1d9:	e8 be 00 00 00       	call   29c <close>
  return r;
 1de:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 1e1:	c9                   	leave  
 1e2:	c3                   	ret    

000001e3 <atoi>:

int
atoi(const char *s)
{
 1e3:	55                   	push   %ebp
 1e4:	89 e5                	mov    %esp,%ebp
 1e6:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 1e9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 1f0:	eb 23                	jmp    215 <atoi+0x32>
    n = n*10 + *s++ - '0';
 1f2:	8b 55 fc             	mov    -0x4(%ebp),%edx
 1f5:	89 d0                	mov    %edx,%eax
 1f7:	c1 e0 02             	shl    $0x2,%eax
 1fa:	01 d0                	add    %edx,%eax
 1fc:	01 c0                	add    %eax,%eax
 1fe:	89 c2                	mov    %eax,%edx
 200:	8b 45 08             	mov    0x8(%ebp),%eax
 203:	0f b6 00             	movzbl (%eax),%eax
 206:	0f be c0             	movsbl %al,%eax
 209:	01 d0                	add    %edx,%eax
 20b:	83 e8 30             	sub    $0x30,%eax
 20e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 211:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 215:	8b 45 08             	mov    0x8(%ebp),%eax
 218:	0f b6 00             	movzbl (%eax),%eax
 21b:	3c 2f                	cmp    $0x2f,%al
 21d:	7e 0a                	jle    229 <atoi+0x46>
 21f:	8b 45 08             	mov    0x8(%ebp),%eax
 222:	0f b6 00             	movzbl (%eax),%eax
 225:	3c 39                	cmp    $0x39,%al
 227:	7e c9                	jle    1f2 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 229:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 22c:	c9                   	leave  
 22d:	c3                   	ret    

0000022e <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 22e:	55                   	push   %ebp
 22f:	89 e5                	mov    %esp,%ebp
 231:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 234:	8b 45 08             	mov    0x8(%ebp),%eax
 237:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 23a:	8b 45 0c             	mov    0xc(%ebp),%eax
 23d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 240:	eb 13                	jmp    255 <memmove+0x27>
    *dst++ = *src++;
 242:	8b 45 f8             	mov    -0x8(%ebp),%eax
 245:	0f b6 10             	movzbl (%eax),%edx
 248:	8b 45 fc             	mov    -0x4(%ebp),%eax
 24b:	88 10                	mov    %dl,(%eax)
 24d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 251:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 255:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 259:	0f 9f c0             	setg   %al
 25c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 260:	84 c0                	test   %al,%al
 262:	75 de                	jne    242 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 264:	8b 45 08             	mov    0x8(%ebp),%eax
}
 267:	c9                   	leave  
 268:	c3                   	ret    
 269:	90                   	nop
 26a:	90                   	nop
 26b:	90                   	nop

0000026c <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 26c:	b8 01 00 00 00       	mov    $0x1,%eax
 271:	cd 40                	int    $0x40
 273:	c3                   	ret    

00000274 <exit>:
SYSCALL(exit)
 274:	b8 02 00 00 00       	mov    $0x2,%eax
 279:	cd 40                	int    $0x40
 27b:	c3                   	ret    

0000027c <wait>:
SYSCALL(wait)
 27c:	b8 03 00 00 00       	mov    $0x3,%eax
 281:	cd 40                	int    $0x40
 283:	c3                   	ret    

00000284 <pipe>:
SYSCALL(pipe)
 284:	b8 04 00 00 00       	mov    $0x4,%eax
 289:	cd 40                	int    $0x40
 28b:	c3                   	ret    

0000028c <read>:
SYSCALL(read)
 28c:	b8 05 00 00 00       	mov    $0x5,%eax
 291:	cd 40                	int    $0x40
 293:	c3                   	ret    

00000294 <write>:
SYSCALL(write)
 294:	b8 10 00 00 00       	mov    $0x10,%eax
 299:	cd 40                	int    $0x40
 29b:	c3                   	ret    

0000029c <close>:
SYSCALL(close)
 29c:	b8 15 00 00 00       	mov    $0x15,%eax
 2a1:	cd 40                	int    $0x40
 2a3:	c3                   	ret    

000002a4 <kill>:
SYSCALL(kill)
 2a4:	b8 06 00 00 00       	mov    $0x6,%eax
 2a9:	cd 40                	int    $0x40
 2ab:	c3                   	ret    

000002ac <exec>:
SYSCALL(exec)
 2ac:	b8 07 00 00 00       	mov    $0x7,%eax
 2b1:	cd 40                	int    $0x40
 2b3:	c3                   	ret    

000002b4 <open>:
SYSCALL(open)
 2b4:	b8 0f 00 00 00       	mov    $0xf,%eax
 2b9:	cd 40                	int    $0x40
 2bb:	c3                   	ret    

000002bc <mknod>:
SYSCALL(mknod)
 2bc:	b8 11 00 00 00       	mov    $0x11,%eax
 2c1:	cd 40                	int    $0x40
 2c3:	c3                   	ret    

000002c4 <unlink>:
SYSCALL(unlink)
 2c4:	b8 12 00 00 00       	mov    $0x12,%eax
 2c9:	cd 40                	int    $0x40
 2cb:	c3                   	ret    

000002cc <fstat>:
SYSCALL(fstat)
 2cc:	b8 08 00 00 00       	mov    $0x8,%eax
 2d1:	cd 40                	int    $0x40
 2d3:	c3                   	ret    

000002d4 <link>:
SYSCALL(link)
 2d4:	b8 13 00 00 00       	mov    $0x13,%eax
 2d9:	cd 40                	int    $0x40
 2db:	c3                   	ret    

000002dc <mkdir>:
SYSCALL(mkdir)
 2dc:	b8 14 00 00 00       	mov    $0x14,%eax
 2e1:	cd 40                	int    $0x40
 2e3:	c3                   	ret    

000002e4 <chdir>:
SYSCALL(chdir)
 2e4:	b8 09 00 00 00       	mov    $0x9,%eax
 2e9:	cd 40                	int    $0x40
 2eb:	c3                   	ret    

000002ec <dup>:
SYSCALL(dup)
 2ec:	b8 0a 00 00 00       	mov    $0xa,%eax
 2f1:	cd 40                	int    $0x40
 2f3:	c3                   	ret    

000002f4 <getpid>:
SYSCALL(getpid)
 2f4:	b8 0b 00 00 00       	mov    $0xb,%eax
 2f9:	cd 40                	int    $0x40
 2fb:	c3                   	ret    

000002fc <sbrk>:
SYSCALL(sbrk)
 2fc:	b8 0c 00 00 00       	mov    $0xc,%eax
 301:	cd 40                	int    $0x40
 303:	c3                   	ret    

00000304 <sleep>:
SYSCALL(sleep)
 304:	b8 0d 00 00 00       	mov    $0xd,%eax
 309:	cd 40                	int    $0x40
 30b:	c3                   	ret    

0000030c <uptime>:
SYSCALL(uptime)
 30c:	b8 0e 00 00 00       	mov    $0xe,%eax
 311:	cd 40                	int    $0x40
 313:	c3                   	ret    

00000314 <getFileBlocks>:
SYSCALL(getFileBlocks)
 314:	b8 16 00 00 00       	mov    $0x16,%eax
 319:	cd 40                	int    $0x40
 31b:	c3                   	ret    

0000031c <getFreeBlocks>:
SYSCALL(getFreeBlocks)
 31c:	b8 17 00 00 00       	mov    $0x17,%eax
 321:	cd 40                	int    $0x40
 323:	c3                   	ret    

00000324 <getSharedBlocksRate>:
SYSCALL(getSharedBlocksRate)
 324:	b8 18 00 00 00       	mov    $0x18,%eax
 329:	cd 40                	int    $0x40
 32b:	c3                   	ret    

0000032c <dedup>:
SYSCALL(dedup)
 32c:	b8 19 00 00 00       	mov    $0x19,%eax
 331:	cd 40                	int    $0x40
 333:	c3                   	ret    

00000334 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 334:	55                   	push   %ebp
 335:	89 e5                	mov    %esp,%ebp
 337:	83 ec 28             	sub    $0x28,%esp
 33a:	8b 45 0c             	mov    0xc(%ebp),%eax
 33d:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 340:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 347:	00 
 348:	8d 45 f4             	lea    -0xc(%ebp),%eax
 34b:	89 44 24 04          	mov    %eax,0x4(%esp)
 34f:	8b 45 08             	mov    0x8(%ebp),%eax
 352:	89 04 24             	mov    %eax,(%esp)
 355:	e8 3a ff ff ff       	call   294 <write>
}
 35a:	c9                   	leave  
 35b:	c3                   	ret    

0000035c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 35c:	55                   	push   %ebp
 35d:	89 e5                	mov    %esp,%ebp
 35f:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 362:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 369:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 36d:	74 17                	je     386 <printint+0x2a>
 36f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 373:	79 11                	jns    386 <printint+0x2a>
    neg = 1;
 375:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 37c:	8b 45 0c             	mov    0xc(%ebp),%eax
 37f:	f7 d8                	neg    %eax
 381:	89 45 ec             	mov    %eax,-0x14(%ebp)
 384:	eb 06                	jmp    38c <printint+0x30>
  } else {
    x = xx;
 386:	8b 45 0c             	mov    0xc(%ebp),%eax
 389:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 38c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 393:	8b 4d 10             	mov    0x10(%ebp),%ecx
 396:	8b 45 ec             	mov    -0x14(%ebp),%eax
 399:	ba 00 00 00 00       	mov    $0x0,%edx
 39e:	f7 f1                	div    %ecx
 3a0:	89 d0                	mov    %edx,%eax
 3a2:	0f b6 90 14 0a 00 00 	movzbl 0xa14(%eax),%edx
 3a9:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3ac:	03 45 f4             	add    -0xc(%ebp),%eax
 3af:	88 10                	mov    %dl,(%eax)
 3b1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 3b5:	8b 55 10             	mov    0x10(%ebp),%edx
 3b8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 3bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3be:	ba 00 00 00 00       	mov    $0x0,%edx
 3c3:	f7 75 d4             	divl   -0x2c(%ebp)
 3c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3c9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 3cd:	75 c4                	jne    393 <printint+0x37>
  if(neg)
 3cf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 3d3:	74 2a                	je     3ff <printint+0xa3>
    buf[i++] = '-';
 3d5:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3d8:	03 45 f4             	add    -0xc(%ebp),%eax
 3db:	c6 00 2d             	movb   $0x2d,(%eax)
 3de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 3e2:	eb 1b                	jmp    3ff <printint+0xa3>
    putc(fd, buf[i]);
 3e4:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3e7:	03 45 f4             	add    -0xc(%ebp),%eax
 3ea:	0f b6 00             	movzbl (%eax),%eax
 3ed:	0f be c0             	movsbl %al,%eax
 3f0:	89 44 24 04          	mov    %eax,0x4(%esp)
 3f4:	8b 45 08             	mov    0x8(%ebp),%eax
 3f7:	89 04 24             	mov    %eax,(%esp)
 3fa:	e8 35 ff ff ff       	call   334 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 3ff:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 403:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 407:	79 db                	jns    3e4 <printint+0x88>
    putc(fd, buf[i]);
}
 409:	c9                   	leave  
 40a:	c3                   	ret    

0000040b <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 40b:	55                   	push   %ebp
 40c:	89 e5                	mov    %esp,%ebp
 40e:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 411:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 418:	8d 45 0c             	lea    0xc(%ebp),%eax
 41b:	83 c0 04             	add    $0x4,%eax
 41e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 421:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 428:	e9 7d 01 00 00       	jmp    5aa <printf+0x19f>
    c = fmt[i] & 0xff;
 42d:	8b 55 0c             	mov    0xc(%ebp),%edx
 430:	8b 45 f0             	mov    -0x10(%ebp),%eax
 433:	01 d0                	add    %edx,%eax
 435:	0f b6 00             	movzbl (%eax),%eax
 438:	0f be c0             	movsbl %al,%eax
 43b:	25 ff 00 00 00       	and    $0xff,%eax
 440:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 443:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 447:	75 2c                	jne    475 <printf+0x6a>
      if(c == '%'){
 449:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 44d:	75 0c                	jne    45b <printf+0x50>
        state = '%';
 44f:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 456:	e9 4b 01 00 00       	jmp    5a6 <printf+0x19b>
      } else {
        putc(fd, c);
 45b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 45e:	0f be c0             	movsbl %al,%eax
 461:	89 44 24 04          	mov    %eax,0x4(%esp)
 465:	8b 45 08             	mov    0x8(%ebp),%eax
 468:	89 04 24             	mov    %eax,(%esp)
 46b:	e8 c4 fe ff ff       	call   334 <putc>
 470:	e9 31 01 00 00       	jmp    5a6 <printf+0x19b>
      }
    } else if(state == '%'){
 475:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 479:	0f 85 27 01 00 00    	jne    5a6 <printf+0x19b>
      if(c == 'd'){
 47f:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 483:	75 2d                	jne    4b2 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 485:	8b 45 e8             	mov    -0x18(%ebp),%eax
 488:	8b 00                	mov    (%eax),%eax
 48a:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 491:	00 
 492:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 499:	00 
 49a:	89 44 24 04          	mov    %eax,0x4(%esp)
 49e:	8b 45 08             	mov    0x8(%ebp),%eax
 4a1:	89 04 24             	mov    %eax,(%esp)
 4a4:	e8 b3 fe ff ff       	call   35c <printint>
        ap++;
 4a9:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4ad:	e9 ed 00 00 00       	jmp    59f <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 4b2:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4b6:	74 06                	je     4be <printf+0xb3>
 4b8:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4bc:	75 2d                	jne    4eb <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4be:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4c1:	8b 00                	mov    (%eax),%eax
 4c3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 4ca:	00 
 4cb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 4d2:	00 
 4d3:	89 44 24 04          	mov    %eax,0x4(%esp)
 4d7:	8b 45 08             	mov    0x8(%ebp),%eax
 4da:	89 04 24             	mov    %eax,(%esp)
 4dd:	e8 7a fe ff ff       	call   35c <printint>
        ap++;
 4e2:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4e6:	e9 b4 00 00 00       	jmp    59f <printf+0x194>
      } else if(c == 's'){
 4eb:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 4ef:	75 46                	jne    537 <printf+0x12c>
        s = (char*)*ap;
 4f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4f4:	8b 00                	mov    (%eax),%eax
 4f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 4f9:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 4fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 501:	75 27                	jne    52a <printf+0x11f>
          s = "(null)";
 503:	c7 45 f4 cf 07 00 00 	movl   $0x7cf,-0xc(%ebp)
        while(*s != 0){
 50a:	eb 1e                	jmp    52a <printf+0x11f>
          putc(fd, *s);
 50c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 50f:	0f b6 00             	movzbl (%eax),%eax
 512:	0f be c0             	movsbl %al,%eax
 515:	89 44 24 04          	mov    %eax,0x4(%esp)
 519:	8b 45 08             	mov    0x8(%ebp),%eax
 51c:	89 04 24             	mov    %eax,(%esp)
 51f:	e8 10 fe ff ff       	call   334 <putc>
          s++;
 524:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 528:	eb 01                	jmp    52b <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 52a:	90                   	nop
 52b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 52e:	0f b6 00             	movzbl (%eax),%eax
 531:	84 c0                	test   %al,%al
 533:	75 d7                	jne    50c <printf+0x101>
 535:	eb 68                	jmp    59f <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 537:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 53b:	75 1d                	jne    55a <printf+0x14f>
        putc(fd, *ap);
 53d:	8b 45 e8             	mov    -0x18(%ebp),%eax
 540:	8b 00                	mov    (%eax),%eax
 542:	0f be c0             	movsbl %al,%eax
 545:	89 44 24 04          	mov    %eax,0x4(%esp)
 549:	8b 45 08             	mov    0x8(%ebp),%eax
 54c:	89 04 24             	mov    %eax,(%esp)
 54f:	e8 e0 fd ff ff       	call   334 <putc>
        ap++;
 554:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 558:	eb 45                	jmp    59f <printf+0x194>
      } else if(c == '%'){
 55a:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 55e:	75 17                	jne    577 <printf+0x16c>
        putc(fd, c);
 560:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 563:	0f be c0             	movsbl %al,%eax
 566:	89 44 24 04          	mov    %eax,0x4(%esp)
 56a:	8b 45 08             	mov    0x8(%ebp),%eax
 56d:	89 04 24             	mov    %eax,(%esp)
 570:	e8 bf fd ff ff       	call   334 <putc>
 575:	eb 28                	jmp    59f <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 577:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 57e:	00 
 57f:	8b 45 08             	mov    0x8(%ebp),%eax
 582:	89 04 24             	mov    %eax,(%esp)
 585:	e8 aa fd ff ff       	call   334 <putc>
        putc(fd, c);
 58a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 58d:	0f be c0             	movsbl %al,%eax
 590:	89 44 24 04          	mov    %eax,0x4(%esp)
 594:	8b 45 08             	mov    0x8(%ebp),%eax
 597:	89 04 24             	mov    %eax,(%esp)
 59a:	e8 95 fd ff ff       	call   334 <putc>
      }
      state = 0;
 59f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5a6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5aa:	8b 55 0c             	mov    0xc(%ebp),%edx
 5ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5b0:	01 d0                	add    %edx,%eax
 5b2:	0f b6 00             	movzbl (%eax),%eax
 5b5:	84 c0                	test   %al,%al
 5b7:	0f 85 70 fe ff ff    	jne    42d <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5bd:	c9                   	leave  
 5be:	c3                   	ret    
 5bf:	90                   	nop

000005c0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5c0:	55                   	push   %ebp
 5c1:	89 e5                	mov    %esp,%ebp
 5c3:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5c6:	8b 45 08             	mov    0x8(%ebp),%eax
 5c9:	83 e8 08             	sub    $0x8,%eax
 5cc:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5cf:	a1 30 0a 00 00       	mov    0xa30,%eax
 5d4:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5d7:	eb 24                	jmp    5fd <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5dc:	8b 00                	mov    (%eax),%eax
 5de:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5e1:	77 12                	ja     5f5 <free+0x35>
 5e3:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5e6:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5e9:	77 24                	ja     60f <free+0x4f>
 5eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5ee:	8b 00                	mov    (%eax),%eax
 5f0:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 5f3:	77 1a                	ja     60f <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5f8:	8b 00                	mov    (%eax),%eax
 5fa:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5fd:	8b 45 f8             	mov    -0x8(%ebp),%eax
 600:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 603:	76 d4                	jbe    5d9 <free+0x19>
 605:	8b 45 fc             	mov    -0x4(%ebp),%eax
 608:	8b 00                	mov    (%eax),%eax
 60a:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 60d:	76 ca                	jbe    5d9 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 60f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 612:	8b 40 04             	mov    0x4(%eax),%eax
 615:	c1 e0 03             	shl    $0x3,%eax
 618:	89 c2                	mov    %eax,%edx
 61a:	03 55 f8             	add    -0x8(%ebp),%edx
 61d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 620:	8b 00                	mov    (%eax),%eax
 622:	39 c2                	cmp    %eax,%edx
 624:	75 24                	jne    64a <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 626:	8b 45 f8             	mov    -0x8(%ebp),%eax
 629:	8b 50 04             	mov    0x4(%eax),%edx
 62c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 62f:	8b 00                	mov    (%eax),%eax
 631:	8b 40 04             	mov    0x4(%eax),%eax
 634:	01 c2                	add    %eax,%edx
 636:	8b 45 f8             	mov    -0x8(%ebp),%eax
 639:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 63c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 63f:	8b 00                	mov    (%eax),%eax
 641:	8b 10                	mov    (%eax),%edx
 643:	8b 45 f8             	mov    -0x8(%ebp),%eax
 646:	89 10                	mov    %edx,(%eax)
 648:	eb 0a                	jmp    654 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 64a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 64d:	8b 10                	mov    (%eax),%edx
 64f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 652:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 654:	8b 45 fc             	mov    -0x4(%ebp),%eax
 657:	8b 40 04             	mov    0x4(%eax),%eax
 65a:	c1 e0 03             	shl    $0x3,%eax
 65d:	03 45 fc             	add    -0x4(%ebp),%eax
 660:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 663:	75 20                	jne    685 <free+0xc5>
    p->s.size += bp->s.size;
 665:	8b 45 fc             	mov    -0x4(%ebp),%eax
 668:	8b 50 04             	mov    0x4(%eax),%edx
 66b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 66e:	8b 40 04             	mov    0x4(%eax),%eax
 671:	01 c2                	add    %eax,%edx
 673:	8b 45 fc             	mov    -0x4(%ebp),%eax
 676:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 679:	8b 45 f8             	mov    -0x8(%ebp),%eax
 67c:	8b 10                	mov    (%eax),%edx
 67e:	8b 45 fc             	mov    -0x4(%ebp),%eax
 681:	89 10                	mov    %edx,(%eax)
 683:	eb 08                	jmp    68d <free+0xcd>
  } else
    p->s.ptr = bp;
 685:	8b 45 fc             	mov    -0x4(%ebp),%eax
 688:	8b 55 f8             	mov    -0x8(%ebp),%edx
 68b:	89 10                	mov    %edx,(%eax)
  freep = p;
 68d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 690:	a3 30 0a 00 00       	mov    %eax,0xa30
}
 695:	c9                   	leave  
 696:	c3                   	ret    

00000697 <morecore>:

static Header*
morecore(uint nu)
{
 697:	55                   	push   %ebp
 698:	89 e5                	mov    %esp,%ebp
 69a:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 69d:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6a4:	77 07                	ja     6ad <morecore+0x16>
    nu = 4096;
 6a6:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6ad:	8b 45 08             	mov    0x8(%ebp),%eax
 6b0:	c1 e0 03             	shl    $0x3,%eax
 6b3:	89 04 24             	mov    %eax,(%esp)
 6b6:	e8 41 fc ff ff       	call   2fc <sbrk>
 6bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 6be:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 6c2:	75 07                	jne    6cb <morecore+0x34>
    return 0;
 6c4:	b8 00 00 00 00       	mov    $0x0,%eax
 6c9:	eb 22                	jmp    6ed <morecore+0x56>
  hp = (Header*)p;
 6cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 6d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6d4:	8b 55 08             	mov    0x8(%ebp),%edx
 6d7:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 6da:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6dd:	83 c0 08             	add    $0x8,%eax
 6e0:	89 04 24             	mov    %eax,(%esp)
 6e3:	e8 d8 fe ff ff       	call   5c0 <free>
  return freep;
 6e8:	a1 30 0a 00 00       	mov    0xa30,%eax
}
 6ed:	c9                   	leave  
 6ee:	c3                   	ret    

000006ef <malloc>:

void*
malloc(uint nbytes)
{
 6ef:	55                   	push   %ebp
 6f0:	89 e5                	mov    %esp,%ebp
 6f2:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f5:	8b 45 08             	mov    0x8(%ebp),%eax
 6f8:	83 c0 07             	add    $0x7,%eax
 6fb:	c1 e8 03             	shr    $0x3,%eax
 6fe:	83 c0 01             	add    $0x1,%eax
 701:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 704:	a1 30 0a 00 00       	mov    0xa30,%eax
 709:	89 45 f0             	mov    %eax,-0x10(%ebp)
 70c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 710:	75 23                	jne    735 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 712:	c7 45 f0 28 0a 00 00 	movl   $0xa28,-0x10(%ebp)
 719:	8b 45 f0             	mov    -0x10(%ebp),%eax
 71c:	a3 30 0a 00 00       	mov    %eax,0xa30
 721:	a1 30 0a 00 00       	mov    0xa30,%eax
 726:	a3 28 0a 00 00       	mov    %eax,0xa28
    base.s.size = 0;
 72b:	c7 05 2c 0a 00 00 00 	movl   $0x0,0xa2c
 732:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 735:	8b 45 f0             	mov    -0x10(%ebp),%eax
 738:	8b 00                	mov    (%eax),%eax
 73a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 73d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 740:	8b 40 04             	mov    0x4(%eax),%eax
 743:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 746:	72 4d                	jb     795 <malloc+0xa6>
      if(p->s.size == nunits)
 748:	8b 45 f4             	mov    -0xc(%ebp),%eax
 74b:	8b 40 04             	mov    0x4(%eax),%eax
 74e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 751:	75 0c                	jne    75f <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 753:	8b 45 f4             	mov    -0xc(%ebp),%eax
 756:	8b 10                	mov    (%eax),%edx
 758:	8b 45 f0             	mov    -0x10(%ebp),%eax
 75b:	89 10                	mov    %edx,(%eax)
 75d:	eb 26                	jmp    785 <malloc+0x96>
      else {
        p->s.size -= nunits;
 75f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 762:	8b 40 04             	mov    0x4(%eax),%eax
 765:	89 c2                	mov    %eax,%edx
 767:	2b 55 ec             	sub    -0x14(%ebp),%edx
 76a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 76d:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 770:	8b 45 f4             	mov    -0xc(%ebp),%eax
 773:	8b 40 04             	mov    0x4(%eax),%eax
 776:	c1 e0 03             	shl    $0x3,%eax
 779:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 77c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 77f:	8b 55 ec             	mov    -0x14(%ebp),%edx
 782:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 785:	8b 45 f0             	mov    -0x10(%ebp),%eax
 788:	a3 30 0a 00 00       	mov    %eax,0xa30
      return (void*)(p + 1);
 78d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 790:	83 c0 08             	add    $0x8,%eax
 793:	eb 38                	jmp    7cd <malloc+0xde>
    }
    if(p == freep)
 795:	a1 30 0a 00 00       	mov    0xa30,%eax
 79a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 79d:	75 1b                	jne    7ba <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 79f:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7a2:	89 04 24             	mov    %eax,(%esp)
 7a5:	e8 ed fe ff ff       	call   697 <morecore>
 7aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7b1:	75 07                	jne    7ba <malloc+0xcb>
        return 0;
 7b3:	b8 00 00 00 00       	mov    $0x0,%eax
 7b8:	eb 13                	jmp    7cd <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c3:	8b 00                	mov    (%eax),%eax
 7c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 7c8:	e9 70 ff ff ff       	jmp    73d <malloc+0x4e>
}
 7cd:	c9                   	leave  
 7ce:	c3                   	ret    

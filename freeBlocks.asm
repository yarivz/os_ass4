
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

0000032c <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 32c:	55                   	push   %ebp
 32d:	89 e5                	mov    %esp,%ebp
 32f:	83 ec 28             	sub    $0x28,%esp
 332:	8b 45 0c             	mov    0xc(%ebp),%eax
 335:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 338:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 33f:	00 
 340:	8d 45 f4             	lea    -0xc(%ebp),%eax
 343:	89 44 24 04          	mov    %eax,0x4(%esp)
 347:	8b 45 08             	mov    0x8(%ebp),%eax
 34a:	89 04 24             	mov    %eax,(%esp)
 34d:	e8 42 ff ff ff       	call   294 <write>
}
 352:	c9                   	leave  
 353:	c3                   	ret    

00000354 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 354:	55                   	push   %ebp
 355:	89 e5                	mov    %esp,%ebp
 357:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 35a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 361:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 365:	74 17                	je     37e <printint+0x2a>
 367:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 36b:	79 11                	jns    37e <printint+0x2a>
    neg = 1;
 36d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 374:	8b 45 0c             	mov    0xc(%ebp),%eax
 377:	f7 d8                	neg    %eax
 379:	89 45 ec             	mov    %eax,-0x14(%ebp)
 37c:	eb 06                	jmp    384 <printint+0x30>
  } else {
    x = xx;
 37e:	8b 45 0c             	mov    0xc(%ebp),%eax
 381:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 384:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 38b:	8b 4d 10             	mov    0x10(%ebp),%ecx
 38e:	8b 45 ec             	mov    -0x14(%ebp),%eax
 391:	ba 00 00 00 00       	mov    $0x0,%edx
 396:	f7 f1                	div    %ecx
 398:	89 d0                	mov    %edx,%eax
 39a:	0f b6 90 0c 0a 00 00 	movzbl 0xa0c(%eax),%edx
 3a1:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3a4:	03 45 f4             	add    -0xc(%ebp),%eax
 3a7:	88 10                	mov    %dl,(%eax)
 3a9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 3ad:	8b 55 10             	mov    0x10(%ebp),%edx
 3b0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 3b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3b6:	ba 00 00 00 00       	mov    $0x0,%edx
 3bb:	f7 75 d4             	divl   -0x2c(%ebp)
 3be:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3c1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 3c5:	75 c4                	jne    38b <printint+0x37>
  if(neg)
 3c7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 3cb:	74 2a                	je     3f7 <printint+0xa3>
    buf[i++] = '-';
 3cd:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3d0:	03 45 f4             	add    -0xc(%ebp),%eax
 3d3:	c6 00 2d             	movb   $0x2d,(%eax)
 3d6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 3da:	eb 1b                	jmp    3f7 <printint+0xa3>
    putc(fd, buf[i]);
 3dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3df:	03 45 f4             	add    -0xc(%ebp),%eax
 3e2:	0f b6 00             	movzbl (%eax),%eax
 3e5:	0f be c0             	movsbl %al,%eax
 3e8:	89 44 24 04          	mov    %eax,0x4(%esp)
 3ec:	8b 45 08             	mov    0x8(%ebp),%eax
 3ef:	89 04 24             	mov    %eax,(%esp)
 3f2:	e8 35 ff ff ff       	call   32c <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 3f7:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 3fb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 3ff:	79 db                	jns    3dc <printint+0x88>
    putc(fd, buf[i]);
}
 401:	c9                   	leave  
 402:	c3                   	ret    

00000403 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 403:	55                   	push   %ebp
 404:	89 e5                	mov    %esp,%ebp
 406:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 409:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 410:	8d 45 0c             	lea    0xc(%ebp),%eax
 413:	83 c0 04             	add    $0x4,%eax
 416:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 419:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 420:	e9 7d 01 00 00       	jmp    5a2 <printf+0x19f>
    c = fmt[i] & 0xff;
 425:	8b 55 0c             	mov    0xc(%ebp),%edx
 428:	8b 45 f0             	mov    -0x10(%ebp),%eax
 42b:	01 d0                	add    %edx,%eax
 42d:	0f b6 00             	movzbl (%eax),%eax
 430:	0f be c0             	movsbl %al,%eax
 433:	25 ff 00 00 00       	and    $0xff,%eax
 438:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 43b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 43f:	75 2c                	jne    46d <printf+0x6a>
      if(c == '%'){
 441:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 445:	75 0c                	jne    453 <printf+0x50>
        state = '%';
 447:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 44e:	e9 4b 01 00 00       	jmp    59e <printf+0x19b>
      } else {
        putc(fd, c);
 453:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 456:	0f be c0             	movsbl %al,%eax
 459:	89 44 24 04          	mov    %eax,0x4(%esp)
 45d:	8b 45 08             	mov    0x8(%ebp),%eax
 460:	89 04 24             	mov    %eax,(%esp)
 463:	e8 c4 fe ff ff       	call   32c <putc>
 468:	e9 31 01 00 00       	jmp    59e <printf+0x19b>
      }
    } else if(state == '%'){
 46d:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 471:	0f 85 27 01 00 00    	jne    59e <printf+0x19b>
      if(c == 'd'){
 477:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 47b:	75 2d                	jne    4aa <printf+0xa7>
        printint(fd, *ap, 10, 1);
 47d:	8b 45 e8             	mov    -0x18(%ebp),%eax
 480:	8b 00                	mov    (%eax),%eax
 482:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 489:	00 
 48a:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 491:	00 
 492:	89 44 24 04          	mov    %eax,0x4(%esp)
 496:	8b 45 08             	mov    0x8(%ebp),%eax
 499:	89 04 24             	mov    %eax,(%esp)
 49c:	e8 b3 fe ff ff       	call   354 <printint>
        ap++;
 4a1:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4a5:	e9 ed 00 00 00       	jmp    597 <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 4aa:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4ae:	74 06                	je     4b6 <printf+0xb3>
 4b0:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4b4:	75 2d                	jne    4e3 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4b9:	8b 00                	mov    (%eax),%eax
 4bb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 4c2:	00 
 4c3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 4ca:	00 
 4cb:	89 44 24 04          	mov    %eax,0x4(%esp)
 4cf:	8b 45 08             	mov    0x8(%ebp),%eax
 4d2:	89 04 24             	mov    %eax,(%esp)
 4d5:	e8 7a fe ff ff       	call   354 <printint>
        ap++;
 4da:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4de:	e9 b4 00 00 00       	jmp    597 <printf+0x194>
      } else if(c == 's'){
 4e3:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 4e7:	75 46                	jne    52f <printf+0x12c>
        s = (char*)*ap;
 4e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4ec:	8b 00                	mov    (%eax),%eax
 4ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 4f1:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 4f5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4f9:	75 27                	jne    522 <printf+0x11f>
          s = "(null)";
 4fb:	c7 45 f4 c7 07 00 00 	movl   $0x7c7,-0xc(%ebp)
        while(*s != 0){
 502:	eb 1e                	jmp    522 <printf+0x11f>
          putc(fd, *s);
 504:	8b 45 f4             	mov    -0xc(%ebp),%eax
 507:	0f b6 00             	movzbl (%eax),%eax
 50a:	0f be c0             	movsbl %al,%eax
 50d:	89 44 24 04          	mov    %eax,0x4(%esp)
 511:	8b 45 08             	mov    0x8(%ebp),%eax
 514:	89 04 24             	mov    %eax,(%esp)
 517:	e8 10 fe ff ff       	call   32c <putc>
          s++;
 51c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 520:	eb 01                	jmp    523 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 522:	90                   	nop
 523:	8b 45 f4             	mov    -0xc(%ebp),%eax
 526:	0f b6 00             	movzbl (%eax),%eax
 529:	84 c0                	test   %al,%al
 52b:	75 d7                	jne    504 <printf+0x101>
 52d:	eb 68                	jmp    597 <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 52f:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 533:	75 1d                	jne    552 <printf+0x14f>
        putc(fd, *ap);
 535:	8b 45 e8             	mov    -0x18(%ebp),%eax
 538:	8b 00                	mov    (%eax),%eax
 53a:	0f be c0             	movsbl %al,%eax
 53d:	89 44 24 04          	mov    %eax,0x4(%esp)
 541:	8b 45 08             	mov    0x8(%ebp),%eax
 544:	89 04 24             	mov    %eax,(%esp)
 547:	e8 e0 fd ff ff       	call   32c <putc>
        ap++;
 54c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 550:	eb 45                	jmp    597 <printf+0x194>
      } else if(c == '%'){
 552:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 556:	75 17                	jne    56f <printf+0x16c>
        putc(fd, c);
 558:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 55b:	0f be c0             	movsbl %al,%eax
 55e:	89 44 24 04          	mov    %eax,0x4(%esp)
 562:	8b 45 08             	mov    0x8(%ebp),%eax
 565:	89 04 24             	mov    %eax,(%esp)
 568:	e8 bf fd ff ff       	call   32c <putc>
 56d:	eb 28                	jmp    597 <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 56f:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 576:	00 
 577:	8b 45 08             	mov    0x8(%ebp),%eax
 57a:	89 04 24             	mov    %eax,(%esp)
 57d:	e8 aa fd ff ff       	call   32c <putc>
        putc(fd, c);
 582:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 585:	0f be c0             	movsbl %al,%eax
 588:	89 44 24 04          	mov    %eax,0x4(%esp)
 58c:	8b 45 08             	mov    0x8(%ebp),%eax
 58f:	89 04 24             	mov    %eax,(%esp)
 592:	e8 95 fd ff ff       	call   32c <putc>
      }
      state = 0;
 597:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 59e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5a2:	8b 55 0c             	mov    0xc(%ebp),%edx
 5a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5a8:	01 d0                	add    %edx,%eax
 5aa:	0f b6 00             	movzbl (%eax),%eax
 5ad:	84 c0                	test   %al,%al
 5af:	0f 85 70 fe ff ff    	jne    425 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5b5:	c9                   	leave  
 5b6:	c3                   	ret    
 5b7:	90                   	nop

000005b8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5b8:	55                   	push   %ebp
 5b9:	89 e5                	mov    %esp,%ebp
 5bb:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5be:	8b 45 08             	mov    0x8(%ebp),%eax
 5c1:	83 e8 08             	sub    $0x8,%eax
 5c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5c7:	a1 28 0a 00 00       	mov    0xa28,%eax
 5cc:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5cf:	eb 24                	jmp    5f5 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5d4:	8b 00                	mov    (%eax),%eax
 5d6:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5d9:	77 12                	ja     5ed <free+0x35>
 5db:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5de:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5e1:	77 24                	ja     607 <free+0x4f>
 5e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5e6:	8b 00                	mov    (%eax),%eax
 5e8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 5eb:	77 1a                	ja     607 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5ed:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5f0:	8b 00                	mov    (%eax),%eax
 5f2:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5f5:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5f8:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5fb:	76 d4                	jbe    5d1 <free+0x19>
 5fd:	8b 45 fc             	mov    -0x4(%ebp),%eax
 600:	8b 00                	mov    (%eax),%eax
 602:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 605:	76 ca                	jbe    5d1 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 607:	8b 45 f8             	mov    -0x8(%ebp),%eax
 60a:	8b 40 04             	mov    0x4(%eax),%eax
 60d:	c1 e0 03             	shl    $0x3,%eax
 610:	89 c2                	mov    %eax,%edx
 612:	03 55 f8             	add    -0x8(%ebp),%edx
 615:	8b 45 fc             	mov    -0x4(%ebp),%eax
 618:	8b 00                	mov    (%eax),%eax
 61a:	39 c2                	cmp    %eax,%edx
 61c:	75 24                	jne    642 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 61e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 621:	8b 50 04             	mov    0x4(%eax),%edx
 624:	8b 45 fc             	mov    -0x4(%ebp),%eax
 627:	8b 00                	mov    (%eax),%eax
 629:	8b 40 04             	mov    0x4(%eax),%eax
 62c:	01 c2                	add    %eax,%edx
 62e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 631:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 634:	8b 45 fc             	mov    -0x4(%ebp),%eax
 637:	8b 00                	mov    (%eax),%eax
 639:	8b 10                	mov    (%eax),%edx
 63b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 63e:	89 10                	mov    %edx,(%eax)
 640:	eb 0a                	jmp    64c <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 642:	8b 45 fc             	mov    -0x4(%ebp),%eax
 645:	8b 10                	mov    (%eax),%edx
 647:	8b 45 f8             	mov    -0x8(%ebp),%eax
 64a:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 64c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 64f:	8b 40 04             	mov    0x4(%eax),%eax
 652:	c1 e0 03             	shl    $0x3,%eax
 655:	03 45 fc             	add    -0x4(%ebp),%eax
 658:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 65b:	75 20                	jne    67d <free+0xc5>
    p->s.size += bp->s.size;
 65d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 660:	8b 50 04             	mov    0x4(%eax),%edx
 663:	8b 45 f8             	mov    -0x8(%ebp),%eax
 666:	8b 40 04             	mov    0x4(%eax),%eax
 669:	01 c2                	add    %eax,%edx
 66b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 66e:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 671:	8b 45 f8             	mov    -0x8(%ebp),%eax
 674:	8b 10                	mov    (%eax),%edx
 676:	8b 45 fc             	mov    -0x4(%ebp),%eax
 679:	89 10                	mov    %edx,(%eax)
 67b:	eb 08                	jmp    685 <free+0xcd>
  } else
    p->s.ptr = bp;
 67d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 680:	8b 55 f8             	mov    -0x8(%ebp),%edx
 683:	89 10                	mov    %edx,(%eax)
  freep = p;
 685:	8b 45 fc             	mov    -0x4(%ebp),%eax
 688:	a3 28 0a 00 00       	mov    %eax,0xa28
}
 68d:	c9                   	leave  
 68e:	c3                   	ret    

0000068f <morecore>:

static Header*
morecore(uint nu)
{
 68f:	55                   	push   %ebp
 690:	89 e5                	mov    %esp,%ebp
 692:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 695:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 69c:	77 07                	ja     6a5 <morecore+0x16>
    nu = 4096;
 69e:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6a5:	8b 45 08             	mov    0x8(%ebp),%eax
 6a8:	c1 e0 03             	shl    $0x3,%eax
 6ab:	89 04 24             	mov    %eax,(%esp)
 6ae:	e8 49 fc ff ff       	call   2fc <sbrk>
 6b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 6b6:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 6ba:	75 07                	jne    6c3 <morecore+0x34>
    return 0;
 6bc:	b8 00 00 00 00       	mov    $0x0,%eax
 6c1:	eb 22                	jmp    6e5 <morecore+0x56>
  hp = (Header*)p;
 6c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 6c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6cc:	8b 55 08             	mov    0x8(%ebp),%edx
 6cf:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 6d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6d5:	83 c0 08             	add    $0x8,%eax
 6d8:	89 04 24             	mov    %eax,(%esp)
 6db:	e8 d8 fe ff ff       	call   5b8 <free>
  return freep;
 6e0:	a1 28 0a 00 00       	mov    0xa28,%eax
}
 6e5:	c9                   	leave  
 6e6:	c3                   	ret    

000006e7 <malloc>:

void*
malloc(uint nbytes)
{
 6e7:	55                   	push   %ebp
 6e8:	89 e5                	mov    %esp,%ebp
 6ea:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6ed:	8b 45 08             	mov    0x8(%ebp),%eax
 6f0:	83 c0 07             	add    $0x7,%eax
 6f3:	c1 e8 03             	shr    $0x3,%eax
 6f6:	83 c0 01             	add    $0x1,%eax
 6f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 6fc:	a1 28 0a 00 00       	mov    0xa28,%eax
 701:	89 45 f0             	mov    %eax,-0x10(%ebp)
 704:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 708:	75 23                	jne    72d <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 70a:	c7 45 f0 20 0a 00 00 	movl   $0xa20,-0x10(%ebp)
 711:	8b 45 f0             	mov    -0x10(%ebp),%eax
 714:	a3 28 0a 00 00       	mov    %eax,0xa28
 719:	a1 28 0a 00 00       	mov    0xa28,%eax
 71e:	a3 20 0a 00 00       	mov    %eax,0xa20
    base.s.size = 0;
 723:	c7 05 24 0a 00 00 00 	movl   $0x0,0xa24
 72a:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 72d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 730:	8b 00                	mov    (%eax),%eax
 732:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 735:	8b 45 f4             	mov    -0xc(%ebp),%eax
 738:	8b 40 04             	mov    0x4(%eax),%eax
 73b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 73e:	72 4d                	jb     78d <malloc+0xa6>
      if(p->s.size == nunits)
 740:	8b 45 f4             	mov    -0xc(%ebp),%eax
 743:	8b 40 04             	mov    0x4(%eax),%eax
 746:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 749:	75 0c                	jne    757 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 74b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 74e:	8b 10                	mov    (%eax),%edx
 750:	8b 45 f0             	mov    -0x10(%ebp),%eax
 753:	89 10                	mov    %edx,(%eax)
 755:	eb 26                	jmp    77d <malloc+0x96>
      else {
        p->s.size -= nunits;
 757:	8b 45 f4             	mov    -0xc(%ebp),%eax
 75a:	8b 40 04             	mov    0x4(%eax),%eax
 75d:	89 c2                	mov    %eax,%edx
 75f:	2b 55 ec             	sub    -0x14(%ebp),%edx
 762:	8b 45 f4             	mov    -0xc(%ebp),%eax
 765:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 768:	8b 45 f4             	mov    -0xc(%ebp),%eax
 76b:	8b 40 04             	mov    0x4(%eax),%eax
 76e:	c1 e0 03             	shl    $0x3,%eax
 771:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 774:	8b 45 f4             	mov    -0xc(%ebp),%eax
 777:	8b 55 ec             	mov    -0x14(%ebp),%edx
 77a:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 77d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 780:	a3 28 0a 00 00       	mov    %eax,0xa28
      return (void*)(p + 1);
 785:	8b 45 f4             	mov    -0xc(%ebp),%eax
 788:	83 c0 08             	add    $0x8,%eax
 78b:	eb 38                	jmp    7c5 <malloc+0xde>
    }
    if(p == freep)
 78d:	a1 28 0a 00 00       	mov    0xa28,%eax
 792:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 795:	75 1b                	jne    7b2 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 797:	8b 45 ec             	mov    -0x14(%ebp),%eax
 79a:	89 04 24             	mov    %eax,(%esp)
 79d:	e8 ed fe ff ff       	call   68f <morecore>
 7a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7a9:	75 07                	jne    7b2 <malloc+0xcb>
        return 0;
 7ab:	b8 00 00 00 00       	mov    $0x0,%eax
 7b0:	eb 13                	jmp    7c5 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7bb:	8b 00                	mov    (%eax),%eax
 7bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 7c0:	e9 70 ff ff ff       	jmp    735 <malloc+0x4e>
}
 7c5:	c9                   	leave  
 7c6:	c3                   	ret    

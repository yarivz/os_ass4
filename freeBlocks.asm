
_freeBlocks:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:



int 
main(int argc, char** argv)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 10             	sub    $0x10,%esp
  if(argc != 1)
   9:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
   d:	74 14                	je     23 <main+0x23>
    printf(1,"Too many arguments\n");
   f:	c7 44 24 04 e7 07 00 	movl   $0x7e7,0x4(%esp)
  16:	00 
  17:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1e:	e8 00 04 00 00       	call   423 <printf>
  getFreeBlocks();
  23:	e8 14 03 00 00       	call   33c <getFreeBlocks>
  exit();
  28:	e8 67 02 00 00       	call   294 <exit>
  2d:	90                   	nop
  2e:	90                   	nop
  2f:	90                   	nop

00000030 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  30:	55                   	push   %ebp
  31:	89 e5                	mov    %esp,%ebp
  33:	57                   	push   %edi
  34:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  35:	8b 4d 08             	mov    0x8(%ebp),%ecx
  38:	8b 55 10             	mov    0x10(%ebp),%edx
  3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  3e:	89 cb                	mov    %ecx,%ebx
  40:	89 df                	mov    %ebx,%edi
  42:	89 d1                	mov    %edx,%ecx
  44:	fc                   	cld    
  45:	f3 aa                	rep stos %al,%es:(%edi)
  47:	89 ca                	mov    %ecx,%edx
  49:	89 fb                	mov    %edi,%ebx
  4b:	89 5d 08             	mov    %ebx,0x8(%ebp)
  4e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  51:	5b                   	pop    %ebx
  52:	5f                   	pop    %edi
  53:	5d                   	pop    %ebp
  54:	c3                   	ret    

00000055 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  55:	55                   	push   %ebp
  56:	89 e5                	mov    %esp,%ebp
  58:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  5b:	8b 45 08             	mov    0x8(%ebp),%eax
  5e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  61:	90                   	nop
  62:	8b 45 0c             	mov    0xc(%ebp),%eax
  65:	0f b6 10             	movzbl (%eax),%edx
  68:	8b 45 08             	mov    0x8(%ebp),%eax
  6b:	88 10                	mov    %dl,(%eax)
  6d:	8b 45 08             	mov    0x8(%ebp),%eax
  70:	0f b6 00             	movzbl (%eax),%eax
  73:	84 c0                	test   %al,%al
  75:	0f 95 c0             	setne  %al
  78:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  7c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  80:	84 c0                	test   %al,%al
  82:	75 de                	jne    62 <strcpy+0xd>
    ;
  return os;
  84:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  87:	c9                   	leave  
  88:	c3                   	ret    

00000089 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  89:	55                   	push   %ebp
  8a:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  8c:	eb 08                	jmp    96 <strcmp+0xd>
    p++, q++;
  8e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  92:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  96:	8b 45 08             	mov    0x8(%ebp),%eax
  99:	0f b6 00             	movzbl (%eax),%eax
  9c:	84 c0                	test   %al,%al
  9e:	74 10                	je     b0 <strcmp+0x27>
  a0:	8b 45 08             	mov    0x8(%ebp),%eax
  a3:	0f b6 10             	movzbl (%eax),%edx
  a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  a9:	0f b6 00             	movzbl (%eax),%eax
  ac:	38 c2                	cmp    %al,%dl
  ae:	74 de                	je     8e <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  b0:	8b 45 08             	mov    0x8(%ebp),%eax
  b3:	0f b6 00             	movzbl (%eax),%eax
  b6:	0f b6 d0             	movzbl %al,%edx
  b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  bc:	0f b6 00             	movzbl (%eax),%eax
  bf:	0f b6 c0             	movzbl %al,%eax
  c2:	89 d1                	mov    %edx,%ecx
  c4:	29 c1                	sub    %eax,%ecx
  c6:	89 c8                	mov    %ecx,%eax
}
  c8:	5d                   	pop    %ebp
  c9:	c3                   	ret    

000000ca <strlen>:

uint
strlen(char *s)
{
  ca:	55                   	push   %ebp
  cb:	89 e5                	mov    %esp,%ebp
  cd:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
  d0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  d7:	eb 04                	jmp    dd <strlen+0x13>
  d9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  dd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  e0:	03 45 08             	add    0x8(%ebp),%eax
  e3:	0f b6 00             	movzbl (%eax),%eax
  e6:	84 c0                	test   %al,%al
  e8:	75 ef                	jne    d9 <strlen+0xf>
    ;
  return n;
  ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  ed:	c9                   	leave  
  ee:	c3                   	ret    

000000ef <memset>:

void*
memset(void *dst, int c, uint n)
{
  ef:	55                   	push   %ebp
  f0:	89 e5                	mov    %esp,%ebp
  f2:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
  f5:	8b 45 10             	mov    0x10(%ebp),%eax
  f8:	89 44 24 08          	mov    %eax,0x8(%esp)
  fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  ff:	89 44 24 04          	mov    %eax,0x4(%esp)
 103:	8b 45 08             	mov    0x8(%ebp),%eax
 106:	89 04 24             	mov    %eax,(%esp)
 109:	e8 22 ff ff ff       	call   30 <stosb>
  return dst;
 10e:	8b 45 08             	mov    0x8(%ebp),%eax
}
 111:	c9                   	leave  
 112:	c3                   	ret    

00000113 <strchr>:

char*
strchr(const char *s, char c)
{
 113:	55                   	push   %ebp
 114:	89 e5                	mov    %esp,%ebp
 116:	83 ec 04             	sub    $0x4,%esp
 119:	8b 45 0c             	mov    0xc(%ebp),%eax
 11c:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 11f:	eb 14                	jmp    135 <strchr+0x22>
    if(*s == c)
 121:	8b 45 08             	mov    0x8(%ebp),%eax
 124:	0f b6 00             	movzbl (%eax),%eax
 127:	3a 45 fc             	cmp    -0x4(%ebp),%al
 12a:	75 05                	jne    131 <strchr+0x1e>
      return (char*)s;
 12c:	8b 45 08             	mov    0x8(%ebp),%eax
 12f:	eb 13                	jmp    144 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 131:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 135:	8b 45 08             	mov    0x8(%ebp),%eax
 138:	0f b6 00             	movzbl (%eax),%eax
 13b:	84 c0                	test   %al,%al
 13d:	75 e2                	jne    121 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 13f:	b8 00 00 00 00       	mov    $0x0,%eax
}
 144:	c9                   	leave  
 145:	c3                   	ret    

00000146 <gets>:

char*
gets(char *buf, int max)
{
 146:	55                   	push   %ebp
 147:	89 e5                	mov    %esp,%ebp
 149:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 153:	eb 44                	jmp    199 <gets+0x53>
    cc = read(0, &c, 1);
 155:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 15c:	00 
 15d:	8d 45 ef             	lea    -0x11(%ebp),%eax
 160:	89 44 24 04          	mov    %eax,0x4(%esp)
 164:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 16b:	e8 3c 01 00 00       	call   2ac <read>
 170:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 173:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 177:	7e 2d                	jle    1a6 <gets+0x60>
      break;
    buf[i++] = c;
 179:	8b 45 f4             	mov    -0xc(%ebp),%eax
 17c:	03 45 08             	add    0x8(%ebp),%eax
 17f:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 183:	88 10                	mov    %dl,(%eax)
 185:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 189:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 18d:	3c 0a                	cmp    $0xa,%al
 18f:	74 16                	je     1a7 <gets+0x61>
 191:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 195:	3c 0d                	cmp    $0xd,%al
 197:	74 0e                	je     1a7 <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 199:	8b 45 f4             	mov    -0xc(%ebp),%eax
 19c:	83 c0 01             	add    $0x1,%eax
 19f:	3b 45 0c             	cmp    0xc(%ebp),%eax
 1a2:	7c b1                	jl     155 <gets+0xf>
 1a4:	eb 01                	jmp    1a7 <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 1a6:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 1a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1aa:	03 45 08             	add    0x8(%ebp),%eax
 1ad:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1b0:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1b3:	c9                   	leave  
 1b4:	c3                   	ret    

000001b5 <stat>:

int
stat(char *n, struct stat *st)
{
 1b5:	55                   	push   %ebp
 1b6:	89 e5                	mov    %esp,%ebp
 1b8:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1bb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1c2:	00 
 1c3:	8b 45 08             	mov    0x8(%ebp),%eax
 1c6:	89 04 24             	mov    %eax,(%esp)
 1c9:	e8 06 01 00 00       	call   2d4 <open>
 1ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 1d1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 1d5:	79 07                	jns    1de <stat+0x29>
    return -1;
 1d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 1dc:	eb 23                	jmp    201 <stat+0x4c>
  r = fstat(fd, st);
 1de:	8b 45 0c             	mov    0xc(%ebp),%eax
 1e1:	89 44 24 04          	mov    %eax,0x4(%esp)
 1e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1e8:	89 04 24             	mov    %eax,(%esp)
 1eb:	e8 fc 00 00 00       	call   2ec <fstat>
 1f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 1f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1f6:	89 04 24             	mov    %eax,(%esp)
 1f9:	e8 be 00 00 00       	call   2bc <close>
  return r;
 1fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 201:	c9                   	leave  
 202:	c3                   	ret    

00000203 <atoi>:

int
atoi(const char *s)
{
 203:	55                   	push   %ebp
 204:	89 e5                	mov    %esp,%ebp
 206:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 209:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 210:	eb 23                	jmp    235 <atoi+0x32>
    n = n*10 + *s++ - '0';
 212:	8b 55 fc             	mov    -0x4(%ebp),%edx
 215:	89 d0                	mov    %edx,%eax
 217:	c1 e0 02             	shl    $0x2,%eax
 21a:	01 d0                	add    %edx,%eax
 21c:	01 c0                	add    %eax,%eax
 21e:	89 c2                	mov    %eax,%edx
 220:	8b 45 08             	mov    0x8(%ebp),%eax
 223:	0f b6 00             	movzbl (%eax),%eax
 226:	0f be c0             	movsbl %al,%eax
 229:	01 d0                	add    %edx,%eax
 22b:	83 e8 30             	sub    $0x30,%eax
 22e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 231:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 235:	8b 45 08             	mov    0x8(%ebp),%eax
 238:	0f b6 00             	movzbl (%eax),%eax
 23b:	3c 2f                	cmp    $0x2f,%al
 23d:	7e 0a                	jle    249 <atoi+0x46>
 23f:	8b 45 08             	mov    0x8(%ebp),%eax
 242:	0f b6 00             	movzbl (%eax),%eax
 245:	3c 39                	cmp    $0x39,%al
 247:	7e c9                	jle    212 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 249:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 24c:	c9                   	leave  
 24d:	c3                   	ret    

0000024e <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 24e:	55                   	push   %ebp
 24f:	89 e5                	mov    %esp,%ebp
 251:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 254:	8b 45 08             	mov    0x8(%ebp),%eax
 257:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 25a:	8b 45 0c             	mov    0xc(%ebp),%eax
 25d:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 260:	eb 13                	jmp    275 <memmove+0x27>
    *dst++ = *src++;
 262:	8b 45 f8             	mov    -0x8(%ebp),%eax
 265:	0f b6 10             	movzbl (%eax),%edx
 268:	8b 45 fc             	mov    -0x4(%ebp),%eax
 26b:	88 10                	mov    %dl,(%eax)
 26d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 271:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 275:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 279:	0f 9f c0             	setg   %al
 27c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 280:	84 c0                	test   %al,%al
 282:	75 de                	jne    262 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 284:	8b 45 08             	mov    0x8(%ebp),%eax
}
 287:	c9                   	leave  
 288:	c3                   	ret    
 289:	90                   	nop
 28a:	90                   	nop
 28b:	90                   	nop

0000028c <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 28c:	b8 01 00 00 00       	mov    $0x1,%eax
 291:	cd 40                	int    $0x40
 293:	c3                   	ret    

00000294 <exit>:
SYSCALL(exit)
 294:	b8 02 00 00 00       	mov    $0x2,%eax
 299:	cd 40                	int    $0x40
 29b:	c3                   	ret    

0000029c <wait>:
SYSCALL(wait)
 29c:	b8 03 00 00 00       	mov    $0x3,%eax
 2a1:	cd 40                	int    $0x40
 2a3:	c3                   	ret    

000002a4 <pipe>:
SYSCALL(pipe)
 2a4:	b8 04 00 00 00       	mov    $0x4,%eax
 2a9:	cd 40                	int    $0x40
 2ab:	c3                   	ret    

000002ac <read>:
SYSCALL(read)
 2ac:	b8 05 00 00 00       	mov    $0x5,%eax
 2b1:	cd 40                	int    $0x40
 2b3:	c3                   	ret    

000002b4 <write>:
SYSCALL(write)
 2b4:	b8 10 00 00 00       	mov    $0x10,%eax
 2b9:	cd 40                	int    $0x40
 2bb:	c3                   	ret    

000002bc <close>:
SYSCALL(close)
 2bc:	b8 15 00 00 00       	mov    $0x15,%eax
 2c1:	cd 40                	int    $0x40
 2c3:	c3                   	ret    

000002c4 <kill>:
SYSCALL(kill)
 2c4:	b8 06 00 00 00       	mov    $0x6,%eax
 2c9:	cd 40                	int    $0x40
 2cb:	c3                   	ret    

000002cc <exec>:
SYSCALL(exec)
 2cc:	b8 07 00 00 00       	mov    $0x7,%eax
 2d1:	cd 40                	int    $0x40
 2d3:	c3                   	ret    

000002d4 <open>:
SYSCALL(open)
 2d4:	b8 0f 00 00 00       	mov    $0xf,%eax
 2d9:	cd 40                	int    $0x40
 2db:	c3                   	ret    

000002dc <mknod>:
SYSCALL(mknod)
 2dc:	b8 11 00 00 00       	mov    $0x11,%eax
 2e1:	cd 40                	int    $0x40
 2e3:	c3                   	ret    

000002e4 <unlink>:
SYSCALL(unlink)
 2e4:	b8 12 00 00 00       	mov    $0x12,%eax
 2e9:	cd 40                	int    $0x40
 2eb:	c3                   	ret    

000002ec <fstat>:
SYSCALL(fstat)
 2ec:	b8 08 00 00 00       	mov    $0x8,%eax
 2f1:	cd 40                	int    $0x40
 2f3:	c3                   	ret    

000002f4 <link>:
SYSCALL(link)
 2f4:	b8 13 00 00 00       	mov    $0x13,%eax
 2f9:	cd 40                	int    $0x40
 2fb:	c3                   	ret    

000002fc <mkdir>:
SYSCALL(mkdir)
 2fc:	b8 14 00 00 00       	mov    $0x14,%eax
 301:	cd 40                	int    $0x40
 303:	c3                   	ret    

00000304 <chdir>:
SYSCALL(chdir)
 304:	b8 09 00 00 00       	mov    $0x9,%eax
 309:	cd 40                	int    $0x40
 30b:	c3                   	ret    

0000030c <dup>:
SYSCALL(dup)
 30c:	b8 0a 00 00 00       	mov    $0xa,%eax
 311:	cd 40                	int    $0x40
 313:	c3                   	ret    

00000314 <getpid>:
SYSCALL(getpid)
 314:	b8 0b 00 00 00       	mov    $0xb,%eax
 319:	cd 40                	int    $0x40
 31b:	c3                   	ret    

0000031c <sbrk>:
SYSCALL(sbrk)
 31c:	b8 0c 00 00 00       	mov    $0xc,%eax
 321:	cd 40                	int    $0x40
 323:	c3                   	ret    

00000324 <sleep>:
SYSCALL(sleep)
 324:	b8 0d 00 00 00       	mov    $0xd,%eax
 329:	cd 40                	int    $0x40
 32b:	c3                   	ret    

0000032c <uptime>:
SYSCALL(uptime)
 32c:	b8 0e 00 00 00       	mov    $0xe,%eax
 331:	cd 40                	int    $0x40
 333:	c3                   	ret    

00000334 <getFileBlocks>:
SYSCALL(getFileBlocks)
 334:	b8 16 00 00 00       	mov    $0x16,%eax
 339:	cd 40                	int    $0x40
 33b:	c3                   	ret    

0000033c <getFreeBlocks>:
SYSCALL(getFreeBlocks)
 33c:	b8 17 00 00 00       	mov    $0x17,%eax
 341:	cd 40                	int    $0x40
 343:	c3                   	ret    

00000344 <getSharedBlocksRate>:
SYSCALL(getSharedBlocksRate)
 344:	b8 18 00 00 00       	mov    $0x18,%eax
 349:	cd 40                	int    $0x40
 34b:	c3                   	ret    

0000034c <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 34c:	55                   	push   %ebp
 34d:	89 e5                	mov    %esp,%ebp
 34f:	83 ec 28             	sub    $0x28,%esp
 352:	8b 45 0c             	mov    0xc(%ebp),%eax
 355:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 358:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 35f:	00 
 360:	8d 45 f4             	lea    -0xc(%ebp),%eax
 363:	89 44 24 04          	mov    %eax,0x4(%esp)
 367:	8b 45 08             	mov    0x8(%ebp),%eax
 36a:	89 04 24             	mov    %eax,(%esp)
 36d:	e8 42 ff ff ff       	call   2b4 <write>
}
 372:	c9                   	leave  
 373:	c3                   	ret    

00000374 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 374:	55                   	push   %ebp
 375:	89 e5                	mov    %esp,%ebp
 377:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 37a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 381:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 385:	74 17                	je     39e <printint+0x2a>
 387:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 38b:	79 11                	jns    39e <printint+0x2a>
    neg = 1;
 38d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 394:	8b 45 0c             	mov    0xc(%ebp),%eax
 397:	f7 d8                	neg    %eax
 399:	89 45 ec             	mov    %eax,-0x14(%ebp)
 39c:	eb 06                	jmp    3a4 <printint+0x30>
  } else {
    x = xx;
 39e:	8b 45 0c             	mov    0xc(%ebp),%eax
 3a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 3a4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 3ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
 3ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3b1:	ba 00 00 00 00       	mov    $0x0,%edx
 3b6:	f7 f1                	div    %ecx
 3b8:	89 d0                	mov    %edx,%eax
 3ba:	0f b6 90 40 0a 00 00 	movzbl 0xa40(%eax),%edx
 3c1:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3c4:	03 45 f4             	add    -0xc(%ebp),%eax
 3c7:	88 10                	mov    %dl,(%eax)
 3c9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 3cd:	8b 55 10             	mov    0x10(%ebp),%edx
 3d0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 3d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3d6:	ba 00 00 00 00       	mov    $0x0,%edx
 3db:	f7 75 d4             	divl   -0x2c(%ebp)
 3de:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3e1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 3e5:	75 c4                	jne    3ab <printint+0x37>
  if(neg)
 3e7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 3eb:	74 2a                	je     417 <printint+0xa3>
    buf[i++] = '-';
 3ed:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3f0:	03 45 f4             	add    -0xc(%ebp),%eax
 3f3:	c6 00 2d             	movb   $0x2d,(%eax)
 3f6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 3fa:	eb 1b                	jmp    417 <printint+0xa3>
    putc(fd, buf[i]);
 3fc:	8d 45 dc             	lea    -0x24(%ebp),%eax
 3ff:	03 45 f4             	add    -0xc(%ebp),%eax
 402:	0f b6 00             	movzbl (%eax),%eax
 405:	0f be c0             	movsbl %al,%eax
 408:	89 44 24 04          	mov    %eax,0x4(%esp)
 40c:	8b 45 08             	mov    0x8(%ebp),%eax
 40f:	89 04 24             	mov    %eax,(%esp)
 412:	e8 35 ff ff ff       	call   34c <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 417:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 41b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 41f:	79 db                	jns    3fc <printint+0x88>
    putc(fd, buf[i]);
}
 421:	c9                   	leave  
 422:	c3                   	ret    

00000423 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 423:	55                   	push   %ebp
 424:	89 e5                	mov    %esp,%ebp
 426:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 429:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 430:	8d 45 0c             	lea    0xc(%ebp),%eax
 433:	83 c0 04             	add    $0x4,%eax
 436:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 439:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 440:	e9 7d 01 00 00       	jmp    5c2 <printf+0x19f>
    c = fmt[i] & 0xff;
 445:	8b 55 0c             	mov    0xc(%ebp),%edx
 448:	8b 45 f0             	mov    -0x10(%ebp),%eax
 44b:	01 d0                	add    %edx,%eax
 44d:	0f b6 00             	movzbl (%eax),%eax
 450:	0f be c0             	movsbl %al,%eax
 453:	25 ff 00 00 00       	and    $0xff,%eax
 458:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 45b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 45f:	75 2c                	jne    48d <printf+0x6a>
      if(c == '%'){
 461:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 465:	75 0c                	jne    473 <printf+0x50>
        state = '%';
 467:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 46e:	e9 4b 01 00 00       	jmp    5be <printf+0x19b>
      } else {
        putc(fd, c);
 473:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 476:	0f be c0             	movsbl %al,%eax
 479:	89 44 24 04          	mov    %eax,0x4(%esp)
 47d:	8b 45 08             	mov    0x8(%ebp),%eax
 480:	89 04 24             	mov    %eax,(%esp)
 483:	e8 c4 fe ff ff       	call   34c <putc>
 488:	e9 31 01 00 00       	jmp    5be <printf+0x19b>
      }
    } else if(state == '%'){
 48d:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 491:	0f 85 27 01 00 00    	jne    5be <printf+0x19b>
      if(c == 'd'){
 497:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 49b:	75 2d                	jne    4ca <printf+0xa7>
        printint(fd, *ap, 10, 1);
 49d:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4a0:	8b 00                	mov    (%eax),%eax
 4a2:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 4a9:	00 
 4aa:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 4b1:	00 
 4b2:	89 44 24 04          	mov    %eax,0x4(%esp)
 4b6:	8b 45 08             	mov    0x8(%ebp),%eax
 4b9:	89 04 24             	mov    %eax,(%esp)
 4bc:	e8 b3 fe ff ff       	call   374 <printint>
        ap++;
 4c1:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4c5:	e9 ed 00 00 00       	jmp    5b7 <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 4ca:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4ce:	74 06                	je     4d6 <printf+0xb3>
 4d0:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4d4:	75 2d                	jne    503 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4d6:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4d9:	8b 00                	mov    (%eax),%eax
 4db:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 4e2:	00 
 4e3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 4ea:	00 
 4eb:	89 44 24 04          	mov    %eax,0x4(%esp)
 4ef:	8b 45 08             	mov    0x8(%ebp),%eax
 4f2:	89 04 24             	mov    %eax,(%esp)
 4f5:	e8 7a fe ff ff       	call   374 <printint>
        ap++;
 4fa:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4fe:	e9 b4 00 00 00       	jmp    5b7 <printf+0x194>
      } else if(c == 's'){
 503:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 507:	75 46                	jne    54f <printf+0x12c>
        s = (char*)*ap;
 509:	8b 45 e8             	mov    -0x18(%ebp),%eax
 50c:	8b 00                	mov    (%eax),%eax
 50e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 511:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 515:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 519:	75 27                	jne    542 <printf+0x11f>
          s = "(null)";
 51b:	c7 45 f4 fb 07 00 00 	movl   $0x7fb,-0xc(%ebp)
        while(*s != 0){
 522:	eb 1e                	jmp    542 <printf+0x11f>
          putc(fd, *s);
 524:	8b 45 f4             	mov    -0xc(%ebp),%eax
 527:	0f b6 00             	movzbl (%eax),%eax
 52a:	0f be c0             	movsbl %al,%eax
 52d:	89 44 24 04          	mov    %eax,0x4(%esp)
 531:	8b 45 08             	mov    0x8(%ebp),%eax
 534:	89 04 24             	mov    %eax,(%esp)
 537:	e8 10 fe ff ff       	call   34c <putc>
          s++;
 53c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 540:	eb 01                	jmp    543 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 542:	90                   	nop
 543:	8b 45 f4             	mov    -0xc(%ebp),%eax
 546:	0f b6 00             	movzbl (%eax),%eax
 549:	84 c0                	test   %al,%al
 54b:	75 d7                	jne    524 <printf+0x101>
 54d:	eb 68                	jmp    5b7 <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 54f:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 553:	75 1d                	jne    572 <printf+0x14f>
        putc(fd, *ap);
 555:	8b 45 e8             	mov    -0x18(%ebp),%eax
 558:	8b 00                	mov    (%eax),%eax
 55a:	0f be c0             	movsbl %al,%eax
 55d:	89 44 24 04          	mov    %eax,0x4(%esp)
 561:	8b 45 08             	mov    0x8(%ebp),%eax
 564:	89 04 24             	mov    %eax,(%esp)
 567:	e8 e0 fd ff ff       	call   34c <putc>
        ap++;
 56c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 570:	eb 45                	jmp    5b7 <printf+0x194>
      } else if(c == '%'){
 572:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 576:	75 17                	jne    58f <printf+0x16c>
        putc(fd, c);
 578:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 57b:	0f be c0             	movsbl %al,%eax
 57e:	89 44 24 04          	mov    %eax,0x4(%esp)
 582:	8b 45 08             	mov    0x8(%ebp),%eax
 585:	89 04 24             	mov    %eax,(%esp)
 588:	e8 bf fd ff ff       	call   34c <putc>
 58d:	eb 28                	jmp    5b7 <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 58f:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 596:	00 
 597:	8b 45 08             	mov    0x8(%ebp),%eax
 59a:	89 04 24             	mov    %eax,(%esp)
 59d:	e8 aa fd ff ff       	call   34c <putc>
        putc(fd, c);
 5a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5a5:	0f be c0             	movsbl %al,%eax
 5a8:	89 44 24 04          	mov    %eax,0x4(%esp)
 5ac:	8b 45 08             	mov    0x8(%ebp),%eax
 5af:	89 04 24             	mov    %eax,(%esp)
 5b2:	e8 95 fd ff ff       	call   34c <putc>
      }
      state = 0;
 5b7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5be:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5c2:	8b 55 0c             	mov    0xc(%ebp),%edx
 5c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5c8:	01 d0                	add    %edx,%eax
 5ca:	0f b6 00             	movzbl (%eax),%eax
 5cd:	84 c0                	test   %al,%al
 5cf:	0f 85 70 fe ff ff    	jne    445 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5d5:	c9                   	leave  
 5d6:	c3                   	ret    
 5d7:	90                   	nop

000005d8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5d8:	55                   	push   %ebp
 5d9:	89 e5                	mov    %esp,%ebp
 5db:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 5de:	8b 45 08             	mov    0x8(%ebp),%eax
 5e1:	83 e8 08             	sub    $0x8,%eax
 5e4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 5e7:	a1 5c 0a 00 00       	mov    0xa5c,%eax
 5ec:	89 45 fc             	mov    %eax,-0x4(%ebp)
 5ef:	eb 24                	jmp    615 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 5f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 5f4:	8b 00                	mov    (%eax),%eax
 5f6:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 5f9:	77 12                	ja     60d <free+0x35>
 5fb:	8b 45 f8             	mov    -0x8(%ebp),%eax
 5fe:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 601:	77 24                	ja     627 <free+0x4f>
 603:	8b 45 fc             	mov    -0x4(%ebp),%eax
 606:	8b 00                	mov    (%eax),%eax
 608:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 60b:	77 1a                	ja     627 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 60d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 610:	8b 00                	mov    (%eax),%eax
 612:	89 45 fc             	mov    %eax,-0x4(%ebp)
 615:	8b 45 f8             	mov    -0x8(%ebp),%eax
 618:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 61b:	76 d4                	jbe    5f1 <free+0x19>
 61d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 620:	8b 00                	mov    (%eax),%eax
 622:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 625:	76 ca                	jbe    5f1 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 627:	8b 45 f8             	mov    -0x8(%ebp),%eax
 62a:	8b 40 04             	mov    0x4(%eax),%eax
 62d:	c1 e0 03             	shl    $0x3,%eax
 630:	89 c2                	mov    %eax,%edx
 632:	03 55 f8             	add    -0x8(%ebp),%edx
 635:	8b 45 fc             	mov    -0x4(%ebp),%eax
 638:	8b 00                	mov    (%eax),%eax
 63a:	39 c2                	cmp    %eax,%edx
 63c:	75 24                	jne    662 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 63e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 641:	8b 50 04             	mov    0x4(%eax),%edx
 644:	8b 45 fc             	mov    -0x4(%ebp),%eax
 647:	8b 00                	mov    (%eax),%eax
 649:	8b 40 04             	mov    0x4(%eax),%eax
 64c:	01 c2                	add    %eax,%edx
 64e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 651:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 654:	8b 45 fc             	mov    -0x4(%ebp),%eax
 657:	8b 00                	mov    (%eax),%eax
 659:	8b 10                	mov    (%eax),%edx
 65b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 65e:	89 10                	mov    %edx,(%eax)
 660:	eb 0a                	jmp    66c <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 662:	8b 45 fc             	mov    -0x4(%ebp),%eax
 665:	8b 10                	mov    (%eax),%edx
 667:	8b 45 f8             	mov    -0x8(%ebp),%eax
 66a:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 66c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 66f:	8b 40 04             	mov    0x4(%eax),%eax
 672:	c1 e0 03             	shl    $0x3,%eax
 675:	03 45 fc             	add    -0x4(%ebp),%eax
 678:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 67b:	75 20                	jne    69d <free+0xc5>
    p->s.size += bp->s.size;
 67d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 680:	8b 50 04             	mov    0x4(%eax),%edx
 683:	8b 45 f8             	mov    -0x8(%ebp),%eax
 686:	8b 40 04             	mov    0x4(%eax),%eax
 689:	01 c2                	add    %eax,%edx
 68b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 68e:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 691:	8b 45 f8             	mov    -0x8(%ebp),%eax
 694:	8b 10                	mov    (%eax),%edx
 696:	8b 45 fc             	mov    -0x4(%ebp),%eax
 699:	89 10                	mov    %edx,(%eax)
 69b:	eb 08                	jmp    6a5 <free+0xcd>
  } else
    p->s.ptr = bp;
 69d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a0:	8b 55 f8             	mov    -0x8(%ebp),%edx
 6a3:	89 10                	mov    %edx,(%eax)
  freep = p;
 6a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a8:	a3 5c 0a 00 00       	mov    %eax,0xa5c
}
 6ad:	c9                   	leave  
 6ae:	c3                   	ret    

000006af <morecore>:

static Header*
morecore(uint nu)
{
 6af:	55                   	push   %ebp
 6b0:	89 e5                	mov    %esp,%ebp
 6b2:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 6b5:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6bc:	77 07                	ja     6c5 <morecore+0x16>
    nu = 4096;
 6be:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6c5:	8b 45 08             	mov    0x8(%ebp),%eax
 6c8:	c1 e0 03             	shl    $0x3,%eax
 6cb:	89 04 24             	mov    %eax,(%esp)
 6ce:	e8 49 fc ff ff       	call   31c <sbrk>
 6d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 6d6:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 6da:	75 07                	jne    6e3 <morecore+0x34>
    return 0;
 6dc:	b8 00 00 00 00       	mov    $0x0,%eax
 6e1:	eb 22                	jmp    705 <morecore+0x56>
  hp = (Header*)p;
 6e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 6e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 6e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6ec:	8b 55 08             	mov    0x8(%ebp),%edx
 6ef:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 6f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6f5:	83 c0 08             	add    $0x8,%eax
 6f8:	89 04 24             	mov    %eax,(%esp)
 6fb:	e8 d8 fe ff ff       	call   5d8 <free>
  return freep;
 700:	a1 5c 0a 00 00       	mov    0xa5c,%eax
}
 705:	c9                   	leave  
 706:	c3                   	ret    

00000707 <malloc>:

void*
malloc(uint nbytes)
{
 707:	55                   	push   %ebp
 708:	89 e5                	mov    %esp,%ebp
 70a:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 70d:	8b 45 08             	mov    0x8(%ebp),%eax
 710:	83 c0 07             	add    $0x7,%eax
 713:	c1 e8 03             	shr    $0x3,%eax
 716:	83 c0 01             	add    $0x1,%eax
 719:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 71c:	a1 5c 0a 00 00       	mov    0xa5c,%eax
 721:	89 45 f0             	mov    %eax,-0x10(%ebp)
 724:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 728:	75 23                	jne    74d <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 72a:	c7 45 f0 54 0a 00 00 	movl   $0xa54,-0x10(%ebp)
 731:	8b 45 f0             	mov    -0x10(%ebp),%eax
 734:	a3 5c 0a 00 00       	mov    %eax,0xa5c
 739:	a1 5c 0a 00 00       	mov    0xa5c,%eax
 73e:	a3 54 0a 00 00       	mov    %eax,0xa54
    base.s.size = 0;
 743:	c7 05 58 0a 00 00 00 	movl   $0x0,0xa58
 74a:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 74d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 750:	8b 00                	mov    (%eax),%eax
 752:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 755:	8b 45 f4             	mov    -0xc(%ebp),%eax
 758:	8b 40 04             	mov    0x4(%eax),%eax
 75b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 75e:	72 4d                	jb     7ad <malloc+0xa6>
      if(p->s.size == nunits)
 760:	8b 45 f4             	mov    -0xc(%ebp),%eax
 763:	8b 40 04             	mov    0x4(%eax),%eax
 766:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 769:	75 0c                	jne    777 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 76b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 76e:	8b 10                	mov    (%eax),%edx
 770:	8b 45 f0             	mov    -0x10(%ebp),%eax
 773:	89 10                	mov    %edx,(%eax)
 775:	eb 26                	jmp    79d <malloc+0x96>
      else {
        p->s.size -= nunits;
 777:	8b 45 f4             	mov    -0xc(%ebp),%eax
 77a:	8b 40 04             	mov    0x4(%eax),%eax
 77d:	89 c2                	mov    %eax,%edx
 77f:	2b 55 ec             	sub    -0x14(%ebp),%edx
 782:	8b 45 f4             	mov    -0xc(%ebp),%eax
 785:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 788:	8b 45 f4             	mov    -0xc(%ebp),%eax
 78b:	8b 40 04             	mov    0x4(%eax),%eax
 78e:	c1 e0 03             	shl    $0x3,%eax
 791:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 794:	8b 45 f4             	mov    -0xc(%ebp),%eax
 797:	8b 55 ec             	mov    -0x14(%ebp),%edx
 79a:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 79d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7a0:	a3 5c 0a 00 00       	mov    %eax,0xa5c
      return (void*)(p + 1);
 7a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7a8:	83 c0 08             	add    $0x8,%eax
 7ab:	eb 38                	jmp    7e5 <malloc+0xde>
    }
    if(p == freep)
 7ad:	a1 5c 0a 00 00       	mov    0xa5c,%eax
 7b2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 7b5:	75 1b                	jne    7d2 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 7b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7ba:	89 04 24             	mov    %eax,(%esp)
 7bd:	e8 ed fe ff ff       	call   6af <morecore>
 7c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7c5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7c9:	75 07                	jne    7d2 <malloc+0xcb>
        return 0;
 7cb:	b8 00 00 00 00       	mov    $0x0,%eax
 7d0:	eb 13                	jmp    7e5 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7db:	8b 00                	mov    (%eax),%eax
 7dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 7e0:	e9 70 ff ff ff       	jmp    755 <malloc+0x4e>
}
 7e5:	c9                   	leave  
 7e6:	c3                   	ret    

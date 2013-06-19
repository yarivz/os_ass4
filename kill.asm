
_kill:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "stat.h"
#include "user.h"

int
main(int argc, char **argv)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 20             	sub    $0x20,%esp
  int i;

  if(argc < 1){
   9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
   d:	7f 19                	jg     28 <main+0x28>
    printf(2, "usage: kill pid...\n");
   f:	c7 44 24 04 23 08 00 	movl   $0x823,0x4(%esp)
  16:	00 
  17:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  1e:	e8 3c 04 00 00       	call   45f <printf>
    exit();
  23:	e8 a0 02 00 00       	call   2c8 <exit>
  }
  for(i=1; i<argc; i++)
  28:	c7 44 24 1c 01 00 00 	movl   $0x1,0x1c(%esp)
  2f:	00 
  30:	eb 21                	jmp    53 <main+0x53>
    kill(atoi(argv[i]));
  32:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  36:	c1 e0 02             	shl    $0x2,%eax
  39:	03 45 0c             	add    0xc(%ebp),%eax
  3c:	8b 00                	mov    (%eax),%eax
  3e:	89 04 24             	mov    %eax,(%esp)
  41:	e8 f1 01 00 00       	call   237 <atoi>
  46:	89 04 24             	mov    %eax,(%esp)
  49:	e8 aa 02 00 00       	call   2f8 <kill>

  if(argc < 1){
    printf(2, "usage: kill pid...\n");
    exit();
  }
  for(i=1; i<argc; i++)
  4e:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  53:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  57:	3b 45 08             	cmp    0x8(%ebp),%eax
  5a:	7c d6                	jl     32 <main+0x32>
    kill(atoi(argv[i]));
  exit();
  5c:	e8 67 02 00 00       	call   2c8 <exit>
  61:	90                   	nop
  62:	90                   	nop
  63:	90                   	nop

00000064 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  64:	55                   	push   %ebp
  65:	89 e5                	mov    %esp,%ebp
  67:	57                   	push   %edi
  68:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  69:	8b 4d 08             	mov    0x8(%ebp),%ecx
  6c:	8b 55 10             	mov    0x10(%ebp),%edx
  6f:	8b 45 0c             	mov    0xc(%ebp),%eax
  72:	89 cb                	mov    %ecx,%ebx
  74:	89 df                	mov    %ebx,%edi
  76:	89 d1                	mov    %edx,%ecx
  78:	fc                   	cld    
  79:	f3 aa                	rep stos %al,%es:(%edi)
  7b:	89 ca                	mov    %ecx,%edx
  7d:	89 fb                	mov    %edi,%ebx
  7f:	89 5d 08             	mov    %ebx,0x8(%ebp)
  82:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  85:	5b                   	pop    %ebx
  86:	5f                   	pop    %edi
  87:	5d                   	pop    %ebp
  88:	c3                   	ret    

00000089 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  89:	55                   	push   %ebp
  8a:	89 e5                	mov    %esp,%ebp
  8c:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  8f:	8b 45 08             	mov    0x8(%ebp),%eax
  92:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  95:	90                   	nop
  96:	8b 45 0c             	mov    0xc(%ebp),%eax
  99:	0f b6 10             	movzbl (%eax),%edx
  9c:	8b 45 08             	mov    0x8(%ebp),%eax
  9f:	88 10                	mov    %dl,(%eax)
  a1:	8b 45 08             	mov    0x8(%ebp),%eax
  a4:	0f b6 00             	movzbl (%eax),%eax
  a7:	84 c0                	test   %al,%al
  a9:	0f 95 c0             	setne  %al
  ac:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  b0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  b4:	84 c0                	test   %al,%al
  b6:	75 de                	jne    96 <strcpy+0xd>
    ;
  return os;
  b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  bb:	c9                   	leave  
  bc:	c3                   	ret    

000000bd <strcmp>:

int
strcmp(const char *p, const char *q)
{
  bd:	55                   	push   %ebp
  be:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  c0:	eb 08                	jmp    ca <strcmp+0xd>
    p++, q++;
  c2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  c6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  ca:	8b 45 08             	mov    0x8(%ebp),%eax
  cd:	0f b6 00             	movzbl (%eax),%eax
  d0:	84 c0                	test   %al,%al
  d2:	74 10                	je     e4 <strcmp+0x27>
  d4:	8b 45 08             	mov    0x8(%ebp),%eax
  d7:	0f b6 10             	movzbl (%eax),%edx
  da:	8b 45 0c             	mov    0xc(%ebp),%eax
  dd:	0f b6 00             	movzbl (%eax),%eax
  e0:	38 c2                	cmp    %al,%dl
  e2:	74 de                	je     c2 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  e4:	8b 45 08             	mov    0x8(%ebp),%eax
  e7:	0f b6 00             	movzbl (%eax),%eax
  ea:	0f b6 d0             	movzbl %al,%edx
  ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  f0:	0f b6 00             	movzbl (%eax),%eax
  f3:	0f b6 c0             	movzbl %al,%eax
  f6:	89 d1                	mov    %edx,%ecx
  f8:	29 c1                	sub    %eax,%ecx
  fa:	89 c8                	mov    %ecx,%eax
}
  fc:	5d                   	pop    %ebp
  fd:	c3                   	ret    

000000fe <strlen>:

uint
strlen(char *s)
{
  fe:	55                   	push   %ebp
  ff:	89 e5                	mov    %esp,%ebp
 101:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 104:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 10b:	eb 04                	jmp    111 <strlen+0x13>
 10d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 111:	8b 45 fc             	mov    -0x4(%ebp),%eax
 114:	03 45 08             	add    0x8(%ebp),%eax
 117:	0f b6 00             	movzbl (%eax),%eax
 11a:	84 c0                	test   %al,%al
 11c:	75 ef                	jne    10d <strlen+0xf>
    ;
  return n;
 11e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 121:	c9                   	leave  
 122:	c3                   	ret    

00000123 <memset>:

void*
memset(void *dst, int c, uint n)
{
 123:	55                   	push   %ebp
 124:	89 e5                	mov    %esp,%ebp
 126:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 129:	8b 45 10             	mov    0x10(%ebp),%eax
 12c:	89 44 24 08          	mov    %eax,0x8(%esp)
 130:	8b 45 0c             	mov    0xc(%ebp),%eax
 133:	89 44 24 04          	mov    %eax,0x4(%esp)
 137:	8b 45 08             	mov    0x8(%ebp),%eax
 13a:	89 04 24             	mov    %eax,(%esp)
 13d:	e8 22 ff ff ff       	call   64 <stosb>
  return dst;
 142:	8b 45 08             	mov    0x8(%ebp),%eax
}
 145:	c9                   	leave  
 146:	c3                   	ret    

00000147 <strchr>:

char*
strchr(const char *s, char c)
{
 147:	55                   	push   %ebp
 148:	89 e5                	mov    %esp,%ebp
 14a:	83 ec 04             	sub    $0x4,%esp
 14d:	8b 45 0c             	mov    0xc(%ebp),%eax
 150:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 153:	eb 14                	jmp    169 <strchr+0x22>
    if(*s == c)
 155:	8b 45 08             	mov    0x8(%ebp),%eax
 158:	0f b6 00             	movzbl (%eax),%eax
 15b:	3a 45 fc             	cmp    -0x4(%ebp),%al
 15e:	75 05                	jne    165 <strchr+0x1e>
      return (char*)s;
 160:	8b 45 08             	mov    0x8(%ebp),%eax
 163:	eb 13                	jmp    178 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 165:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 169:	8b 45 08             	mov    0x8(%ebp),%eax
 16c:	0f b6 00             	movzbl (%eax),%eax
 16f:	84 c0                	test   %al,%al
 171:	75 e2                	jne    155 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 173:	b8 00 00 00 00       	mov    $0x0,%eax
}
 178:	c9                   	leave  
 179:	c3                   	ret    

0000017a <gets>:

char*
gets(char *buf, int max)
{
 17a:	55                   	push   %ebp
 17b:	89 e5                	mov    %esp,%ebp
 17d:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 180:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 187:	eb 44                	jmp    1cd <gets+0x53>
    cc = read(0, &c, 1);
 189:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 190:	00 
 191:	8d 45 ef             	lea    -0x11(%ebp),%eax
 194:	89 44 24 04          	mov    %eax,0x4(%esp)
 198:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 19f:	e8 3c 01 00 00       	call   2e0 <read>
 1a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 1a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 1ab:	7e 2d                	jle    1da <gets+0x60>
      break;
    buf[i++] = c;
 1ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1b0:	03 45 08             	add    0x8(%ebp),%eax
 1b3:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 1b7:	88 10                	mov    %dl,(%eax)
 1b9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 1bd:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1c1:	3c 0a                	cmp    $0xa,%al
 1c3:	74 16                	je     1db <gets+0x61>
 1c5:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1c9:	3c 0d                	cmp    $0xd,%al
 1cb:	74 0e                	je     1db <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1d0:	83 c0 01             	add    $0x1,%eax
 1d3:	3b 45 0c             	cmp    0xc(%ebp),%eax
 1d6:	7c b1                	jl     189 <gets+0xf>
 1d8:	eb 01                	jmp    1db <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 1da:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 1db:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1de:	03 45 08             	add    0x8(%ebp),%eax
 1e1:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1e4:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1e7:	c9                   	leave  
 1e8:	c3                   	ret    

000001e9 <stat>:

int
stat(char *n, struct stat *st)
{
 1e9:	55                   	push   %ebp
 1ea:	89 e5                	mov    %esp,%ebp
 1ec:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1f6:	00 
 1f7:	8b 45 08             	mov    0x8(%ebp),%eax
 1fa:	89 04 24             	mov    %eax,(%esp)
 1fd:	e8 06 01 00 00       	call   308 <open>
 202:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 205:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 209:	79 07                	jns    212 <stat+0x29>
    return -1;
 20b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 210:	eb 23                	jmp    235 <stat+0x4c>
  r = fstat(fd, st);
 212:	8b 45 0c             	mov    0xc(%ebp),%eax
 215:	89 44 24 04          	mov    %eax,0x4(%esp)
 219:	8b 45 f4             	mov    -0xc(%ebp),%eax
 21c:	89 04 24             	mov    %eax,(%esp)
 21f:	e8 fc 00 00 00       	call   320 <fstat>
 224:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 227:	8b 45 f4             	mov    -0xc(%ebp),%eax
 22a:	89 04 24             	mov    %eax,(%esp)
 22d:	e8 be 00 00 00       	call   2f0 <close>
  return r;
 232:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 235:	c9                   	leave  
 236:	c3                   	ret    

00000237 <atoi>:

int
atoi(const char *s)
{
 237:	55                   	push   %ebp
 238:	89 e5                	mov    %esp,%ebp
 23a:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 23d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 244:	eb 23                	jmp    269 <atoi+0x32>
    n = n*10 + *s++ - '0';
 246:	8b 55 fc             	mov    -0x4(%ebp),%edx
 249:	89 d0                	mov    %edx,%eax
 24b:	c1 e0 02             	shl    $0x2,%eax
 24e:	01 d0                	add    %edx,%eax
 250:	01 c0                	add    %eax,%eax
 252:	89 c2                	mov    %eax,%edx
 254:	8b 45 08             	mov    0x8(%ebp),%eax
 257:	0f b6 00             	movzbl (%eax),%eax
 25a:	0f be c0             	movsbl %al,%eax
 25d:	01 d0                	add    %edx,%eax
 25f:	83 e8 30             	sub    $0x30,%eax
 262:	89 45 fc             	mov    %eax,-0x4(%ebp)
 265:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 269:	8b 45 08             	mov    0x8(%ebp),%eax
 26c:	0f b6 00             	movzbl (%eax),%eax
 26f:	3c 2f                	cmp    $0x2f,%al
 271:	7e 0a                	jle    27d <atoi+0x46>
 273:	8b 45 08             	mov    0x8(%ebp),%eax
 276:	0f b6 00             	movzbl (%eax),%eax
 279:	3c 39                	cmp    $0x39,%al
 27b:	7e c9                	jle    246 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 27d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 280:	c9                   	leave  
 281:	c3                   	ret    

00000282 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 282:	55                   	push   %ebp
 283:	89 e5                	mov    %esp,%ebp
 285:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 288:	8b 45 08             	mov    0x8(%ebp),%eax
 28b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 28e:	8b 45 0c             	mov    0xc(%ebp),%eax
 291:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 294:	eb 13                	jmp    2a9 <memmove+0x27>
    *dst++ = *src++;
 296:	8b 45 f8             	mov    -0x8(%ebp),%eax
 299:	0f b6 10             	movzbl (%eax),%edx
 29c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 29f:	88 10                	mov    %dl,(%eax)
 2a1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 2a5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 2a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 2ad:	0f 9f c0             	setg   %al
 2b0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 2b4:	84 c0                	test   %al,%al
 2b6:	75 de                	jne    296 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 2b8:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2bb:	c9                   	leave  
 2bc:	c3                   	ret    
 2bd:	90                   	nop
 2be:	90                   	nop
 2bf:	90                   	nop

000002c0 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 2c0:	b8 01 00 00 00       	mov    $0x1,%eax
 2c5:	cd 40                	int    $0x40
 2c7:	c3                   	ret    

000002c8 <exit>:
SYSCALL(exit)
 2c8:	b8 02 00 00 00       	mov    $0x2,%eax
 2cd:	cd 40                	int    $0x40
 2cf:	c3                   	ret    

000002d0 <wait>:
SYSCALL(wait)
 2d0:	b8 03 00 00 00       	mov    $0x3,%eax
 2d5:	cd 40                	int    $0x40
 2d7:	c3                   	ret    

000002d8 <pipe>:
SYSCALL(pipe)
 2d8:	b8 04 00 00 00       	mov    $0x4,%eax
 2dd:	cd 40                	int    $0x40
 2df:	c3                   	ret    

000002e0 <read>:
SYSCALL(read)
 2e0:	b8 05 00 00 00       	mov    $0x5,%eax
 2e5:	cd 40                	int    $0x40
 2e7:	c3                   	ret    

000002e8 <write>:
SYSCALL(write)
 2e8:	b8 10 00 00 00       	mov    $0x10,%eax
 2ed:	cd 40                	int    $0x40
 2ef:	c3                   	ret    

000002f0 <close>:
SYSCALL(close)
 2f0:	b8 15 00 00 00       	mov    $0x15,%eax
 2f5:	cd 40                	int    $0x40
 2f7:	c3                   	ret    

000002f8 <kill>:
SYSCALL(kill)
 2f8:	b8 06 00 00 00       	mov    $0x6,%eax
 2fd:	cd 40                	int    $0x40
 2ff:	c3                   	ret    

00000300 <exec>:
SYSCALL(exec)
 300:	b8 07 00 00 00       	mov    $0x7,%eax
 305:	cd 40                	int    $0x40
 307:	c3                   	ret    

00000308 <open>:
SYSCALL(open)
 308:	b8 0f 00 00 00       	mov    $0xf,%eax
 30d:	cd 40                	int    $0x40
 30f:	c3                   	ret    

00000310 <mknod>:
SYSCALL(mknod)
 310:	b8 11 00 00 00       	mov    $0x11,%eax
 315:	cd 40                	int    $0x40
 317:	c3                   	ret    

00000318 <unlink>:
SYSCALL(unlink)
 318:	b8 12 00 00 00       	mov    $0x12,%eax
 31d:	cd 40                	int    $0x40
 31f:	c3                   	ret    

00000320 <fstat>:
SYSCALL(fstat)
 320:	b8 08 00 00 00       	mov    $0x8,%eax
 325:	cd 40                	int    $0x40
 327:	c3                   	ret    

00000328 <link>:
SYSCALL(link)
 328:	b8 13 00 00 00       	mov    $0x13,%eax
 32d:	cd 40                	int    $0x40
 32f:	c3                   	ret    

00000330 <mkdir>:
SYSCALL(mkdir)
 330:	b8 14 00 00 00       	mov    $0x14,%eax
 335:	cd 40                	int    $0x40
 337:	c3                   	ret    

00000338 <chdir>:
SYSCALL(chdir)
 338:	b8 09 00 00 00       	mov    $0x9,%eax
 33d:	cd 40                	int    $0x40
 33f:	c3                   	ret    

00000340 <dup>:
SYSCALL(dup)
 340:	b8 0a 00 00 00       	mov    $0xa,%eax
 345:	cd 40                	int    $0x40
 347:	c3                   	ret    

00000348 <getpid>:
SYSCALL(getpid)
 348:	b8 0b 00 00 00       	mov    $0xb,%eax
 34d:	cd 40                	int    $0x40
 34f:	c3                   	ret    

00000350 <sbrk>:
SYSCALL(sbrk)
 350:	b8 0c 00 00 00       	mov    $0xc,%eax
 355:	cd 40                	int    $0x40
 357:	c3                   	ret    

00000358 <sleep>:
SYSCALL(sleep)
 358:	b8 0d 00 00 00       	mov    $0xd,%eax
 35d:	cd 40                	int    $0x40
 35f:	c3                   	ret    

00000360 <uptime>:
SYSCALL(uptime)
 360:	b8 0e 00 00 00       	mov    $0xe,%eax
 365:	cd 40                	int    $0x40
 367:	c3                   	ret    

00000368 <getFileBlocks>:
SYSCALL(getFileBlocks)
 368:	b8 16 00 00 00       	mov    $0x16,%eax
 36d:	cd 40                	int    $0x40
 36f:	c3                   	ret    

00000370 <getFreeBlocks>:
SYSCALL(getFreeBlocks)
 370:	b8 17 00 00 00       	mov    $0x17,%eax
 375:	cd 40                	int    $0x40
 377:	c3                   	ret    

00000378 <getSharedBlocksRate>:
SYSCALL(getSharedBlocksRate)
 378:	b8 18 00 00 00       	mov    $0x18,%eax
 37d:	cd 40                	int    $0x40
 37f:	c3                   	ret    

00000380 <dedup>:
SYSCALL(dedup)
 380:	b8 19 00 00 00       	mov    $0x19,%eax
 385:	cd 40                	int    $0x40
 387:	c3                   	ret    

00000388 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 388:	55                   	push   %ebp
 389:	89 e5                	mov    %esp,%ebp
 38b:	83 ec 28             	sub    $0x28,%esp
 38e:	8b 45 0c             	mov    0xc(%ebp),%eax
 391:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 394:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 39b:	00 
 39c:	8d 45 f4             	lea    -0xc(%ebp),%eax
 39f:	89 44 24 04          	mov    %eax,0x4(%esp)
 3a3:	8b 45 08             	mov    0x8(%ebp),%eax
 3a6:	89 04 24             	mov    %eax,(%esp)
 3a9:	e8 3a ff ff ff       	call   2e8 <write>
}
 3ae:	c9                   	leave  
 3af:	c3                   	ret    

000003b0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3b0:	55                   	push   %ebp
 3b1:	89 e5                	mov    %esp,%ebp
 3b3:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 3b6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 3bd:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 3c1:	74 17                	je     3da <printint+0x2a>
 3c3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 3c7:	79 11                	jns    3da <printint+0x2a>
    neg = 1;
 3c9:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 3d0:	8b 45 0c             	mov    0xc(%ebp),%eax
 3d3:	f7 d8                	neg    %eax
 3d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3d8:	eb 06                	jmp    3e0 <printint+0x30>
  } else {
    x = xx;
 3da:	8b 45 0c             	mov    0xc(%ebp),%eax
 3dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 3e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 3e7:	8b 4d 10             	mov    0x10(%ebp),%ecx
 3ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3ed:	ba 00 00 00 00       	mov    $0x0,%edx
 3f2:	f7 f1                	div    %ecx
 3f4:	89 d0                	mov    %edx,%eax
 3f6:	0f b6 90 7c 0a 00 00 	movzbl 0xa7c(%eax),%edx
 3fd:	8d 45 dc             	lea    -0x24(%ebp),%eax
 400:	03 45 f4             	add    -0xc(%ebp),%eax
 403:	88 10                	mov    %dl,(%eax)
 405:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 409:	8b 55 10             	mov    0x10(%ebp),%edx
 40c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 40f:	8b 45 ec             	mov    -0x14(%ebp),%eax
 412:	ba 00 00 00 00       	mov    $0x0,%edx
 417:	f7 75 d4             	divl   -0x2c(%ebp)
 41a:	89 45 ec             	mov    %eax,-0x14(%ebp)
 41d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 421:	75 c4                	jne    3e7 <printint+0x37>
  if(neg)
 423:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 427:	74 2a                	je     453 <printint+0xa3>
    buf[i++] = '-';
 429:	8d 45 dc             	lea    -0x24(%ebp),%eax
 42c:	03 45 f4             	add    -0xc(%ebp),%eax
 42f:	c6 00 2d             	movb   $0x2d,(%eax)
 432:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 436:	eb 1b                	jmp    453 <printint+0xa3>
    putc(fd, buf[i]);
 438:	8d 45 dc             	lea    -0x24(%ebp),%eax
 43b:	03 45 f4             	add    -0xc(%ebp),%eax
 43e:	0f b6 00             	movzbl (%eax),%eax
 441:	0f be c0             	movsbl %al,%eax
 444:	89 44 24 04          	mov    %eax,0x4(%esp)
 448:	8b 45 08             	mov    0x8(%ebp),%eax
 44b:	89 04 24             	mov    %eax,(%esp)
 44e:	e8 35 ff ff ff       	call   388 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 453:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 457:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 45b:	79 db                	jns    438 <printint+0x88>
    putc(fd, buf[i]);
}
 45d:	c9                   	leave  
 45e:	c3                   	ret    

0000045f <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 45f:	55                   	push   %ebp
 460:	89 e5                	mov    %esp,%ebp
 462:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 465:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 46c:	8d 45 0c             	lea    0xc(%ebp),%eax
 46f:	83 c0 04             	add    $0x4,%eax
 472:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 475:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 47c:	e9 7d 01 00 00       	jmp    5fe <printf+0x19f>
    c = fmt[i] & 0xff;
 481:	8b 55 0c             	mov    0xc(%ebp),%edx
 484:	8b 45 f0             	mov    -0x10(%ebp),%eax
 487:	01 d0                	add    %edx,%eax
 489:	0f b6 00             	movzbl (%eax),%eax
 48c:	0f be c0             	movsbl %al,%eax
 48f:	25 ff 00 00 00       	and    $0xff,%eax
 494:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 497:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 49b:	75 2c                	jne    4c9 <printf+0x6a>
      if(c == '%'){
 49d:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 4a1:	75 0c                	jne    4af <printf+0x50>
        state = '%';
 4a3:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 4aa:	e9 4b 01 00 00       	jmp    5fa <printf+0x19b>
      } else {
        putc(fd, c);
 4af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 4b2:	0f be c0             	movsbl %al,%eax
 4b5:	89 44 24 04          	mov    %eax,0x4(%esp)
 4b9:	8b 45 08             	mov    0x8(%ebp),%eax
 4bc:	89 04 24             	mov    %eax,(%esp)
 4bf:	e8 c4 fe ff ff       	call   388 <putc>
 4c4:	e9 31 01 00 00       	jmp    5fa <printf+0x19b>
      }
    } else if(state == '%'){
 4c9:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 4cd:	0f 85 27 01 00 00    	jne    5fa <printf+0x19b>
      if(c == 'd'){
 4d3:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 4d7:	75 2d                	jne    506 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 4d9:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4dc:	8b 00                	mov    (%eax),%eax
 4de:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 4e5:	00 
 4e6:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 4ed:	00 
 4ee:	89 44 24 04          	mov    %eax,0x4(%esp)
 4f2:	8b 45 08             	mov    0x8(%ebp),%eax
 4f5:	89 04 24             	mov    %eax,(%esp)
 4f8:	e8 b3 fe ff ff       	call   3b0 <printint>
        ap++;
 4fd:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 501:	e9 ed 00 00 00       	jmp    5f3 <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 506:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 50a:	74 06                	je     512 <printf+0xb3>
 50c:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 510:	75 2d                	jne    53f <printf+0xe0>
        printint(fd, *ap, 16, 0);
 512:	8b 45 e8             	mov    -0x18(%ebp),%eax
 515:	8b 00                	mov    (%eax),%eax
 517:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 51e:	00 
 51f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 526:	00 
 527:	89 44 24 04          	mov    %eax,0x4(%esp)
 52b:	8b 45 08             	mov    0x8(%ebp),%eax
 52e:	89 04 24             	mov    %eax,(%esp)
 531:	e8 7a fe ff ff       	call   3b0 <printint>
        ap++;
 536:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 53a:	e9 b4 00 00 00       	jmp    5f3 <printf+0x194>
      } else if(c == 's'){
 53f:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 543:	75 46                	jne    58b <printf+0x12c>
        s = (char*)*ap;
 545:	8b 45 e8             	mov    -0x18(%ebp),%eax
 548:	8b 00                	mov    (%eax),%eax
 54a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 54d:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 551:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 555:	75 27                	jne    57e <printf+0x11f>
          s = "(null)";
 557:	c7 45 f4 37 08 00 00 	movl   $0x837,-0xc(%ebp)
        while(*s != 0){
 55e:	eb 1e                	jmp    57e <printf+0x11f>
          putc(fd, *s);
 560:	8b 45 f4             	mov    -0xc(%ebp),%eax
 563:	0f b6 00             	movzbl (%eax),%eax
 566:	0f be c0             	movsbl %al,%eax
 569:	89 44 24 04          	mov    %eax,0x4(%esp)
 56d:	8b 45 08             	mov    0x8(%ebp),%eax
 570:	89 04 24             	mov    %eax,(%esp)
 573:	e8 10 fe ff ff       	call   388 <putc>
          s++;
 578:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 57c:	eb 01                	jmp    57f <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 57e:	90                   	nop
 57f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 582:	0f b6 00             	movzbl (%eax),%eax
 585:	84 c0                	test   %al,%al
 587:	75 d7                	jne    560 <printf+0x101>
 589:	eb 68                	jmp    5f3 <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 58b:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 58f:	75 1d                	jne    5ae <printf+0x14f>
        putc(fd, *ap);
 591:	8b 45 e8             	mov    -0x18(%ebp),%eax
 594:	8b 00                	mov    (%eax),%eax
 596:	0f be c0             	movsbl %al,%eax
 599:	89 44 24 04          	mov    %eax,0x4(%esp)
 59d:	8b 45 08             	mov    0x8(%ebp),%eax
 5a0:	89 04 24             	mov    %eax,(%esp)
 5a3:	e8 e0 fd ff ff       	call   388 <putc>
        ap++;
 5a8:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5ac:	eb 45                	jmp    5f3 <printf+0x194>
      } else if(c == '%'){
 5ae:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 5b2:	75 17                	jne    5cb <printf+0x16c>
        putc(fd, c);
 5b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5b7:	0f be c0             	movsbl %al,%eax
 5ba:	89 44 24 04          	mov    %eax,0x4(%esp)
 5be:	8b 45 08             	mov    0x8(%ebp),%eax
 5c1:	89 04 24             	mov    %eax,(%esp)
 5c4:	e8 bf fd ff ff       	call   388 <putc>
 5c9:	eb 28                	jmp    5f3 <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5cb:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 5d2:	00 
 5d3:	8b 45 08             	mov    0x8(%ebp),%eax
 5d6:	89 04 24             	mov    %eax,(%esp)
 5d9:	e8 aa fd ff ff       	call   388 <putc>
        putc(fd, c);
 5de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5e1:	0f be c0             	movsbl %al,%eax
 5e4:	89 44 24 04          	mov    %eax,0x4(%esp)
 5e8:	8b 45 08             	mov    0x8(%ebp),%eax
 5eb:	89 04 24             	mov    %eax,(%esp)
 5ee:	e8 95 fd ff ff       	call   388 <putc>
      }
      state = 0;
 5f3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5fa:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5fe:	8b 55 0c             	mov    0xc(%ebp),%edx
 601:	8b 45 f0             	mov    -0x10(%ebp),%eax
 604:	01 d0                	add    %edx,%eax
 606:	0f b6 00             	movzbl (%eax),%eax
 609:	84 c0                	test   %al,%al
 60b:	0f 85 70 fe ff ff    	jne    481 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 611:	c9                   	leave  
 612:	c3                   	ret    
 613:	90                   	nop

00000614 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 614:	55                   	push   %ebp
 615:	89 e5                	mov    %esp,%ebp
 617:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 61a:	8b 45 08             	mov    0x8(%ebp),%eax
 61d:	83 e8 08             	sub    $0x8,%eax
 620:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 623:	a1 98 0a 00 00       	mov    0xa98,%eax
 628:	89 45 fc             	mov    %eax,-0x4(%ebp)
 62b:	eb 24                	jmp    651 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 62d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 630:	8b 00                	mov    (%eax),%eax
 632:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 635:	77 12                	ja     649 <free+0x35>
 637:	8b 45 f8             	mov    -0x8(%ebp),%eax
 63a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 63d:	77 24                	ja     663 <free+0x4f>
 63f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 642:	8b 00                	mov    (%eax),%eax
 644:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 647:	77 1a                	ja     663 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 649:	8b 45 fc             	mov    -0x4(%ebp),%eax
 64c:	8b 00                	mov    (%eax),%eax
 64e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 651:	8b 45 f8             	mov    -0x8(%ebp),%eax
 654:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 657:	76 d4                	jbe    62d <free+0x19>
 659:	8b 45 fc             	mov    -0x4(%ebp),%eax
 65c:	8b 00                	mov    (%eax),%eax
 65e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 661:	76 ca                	jbe    62d <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 663:	8b 45 f8             	mov    -0x8(%ebp),%eax
 666:	8b 40 04             	mov    0x4(%eax),%eax
 669:	c1 e0 03             	shl    $0x3,%eax
 66c:	89 c2                	mov    %eax,%edx
 66e:	03 55 f8             	add    -0x8(%ebp),%edx
 671:	8b 45 fc             	mov    -0x4(%ebp),%eax
 674:	8b 00                	mov    (%eax),%eax
 676:	39 c2                	cmp    %eax,%edx
 678:	75 24                	jne    69e <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 67a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 67d:	8b 50 04             	mov    0x4(%eax),%edx
 680:	8b 45 fc             	mov    -0x4(%ebp),%eax
 683:	8b 00                	mov    (%eax),%eax
 685:	8b 40 04             	mov    0x4(%eax),%eax
 688:	01 c2                	add    %eax,%edx
 68a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 68d:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 690:	8b 45 fc             	mov    -0x4(%ebp),%eax
 693:	8b 00                	mov    (%eax),%eax
 695:	8b 10                	mov    (%eax),%edx
 697:	8b 45 f8             	mov    -0x8(%ebp),%eax
 69a:	89 10                	mov    %edx,(%eax)
 69c:	eb 0a                	jmp    6a8 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 69e:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a1:	8b 10                	mov    (%eax),%edx
 6a3:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6a6:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 6a8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ab:	8b 40 04             	mov    0x4(%eax),%eax
 6ae:	c1 e0 03             	shl    $0x3,%eax
 6b1:	03 45 fc             	add    -0x4(%ebp),%eax
 6b4:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6b7:	75 20                	jne    6d9 <free+0xc5>
    p->s.size += bp->s.size;
 6b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6bc:	8b 50 04             	mov    0x4(%eax),%edx
 6bf:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6c2:	8b 40 04             	mov    0x4(%eax),%eax
 6c5:	01 c2                	add    %eax,%edx
 6c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ca:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 6cd:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6d0:	8b 10                	mov    (%eax),%edx
 6d2:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6d5:	89 10                	mov    %edx,(%eax)
 6d7:	eb 08                	jmp    6e1 <free+0xcd>
  } else
    p->s.ptr = bp;
 6d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6dc:	8b 55 f8             	mov    -0x8(%ebp),%edx
 6df:	89 10                	mov    %edx,(%eax)
  freep = p;
 6e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6e4:	a3 98 0a 00 00       	mov    %eax,0xa98
}
 6e9:	c9                   	leave  
 6ea:	c3                   	ret    

000006eb <morecore>:

static Header*
morecore(uint nu)
{
 6eb:	55                   	push   %ebp
 6ec:	89 e5                	mov    %esp,%ebp
 6ee:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 6f1:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6f8:	77 07                	ja     701 <morecore+0x16>
    nu = 4096;
 6fa:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 701:	8b 45 08             	mov    0x8(%ebp),%eax
 704:	c1 e0 03             	shl    $0x3,%eax
 707:	89 04 24             	mov    %eax,(%esp)
 70a:	e8 41 fc ff ff       	call   350 <sbrk>
 70f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 712:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 716:	75 07                	jne    71f <morecore+0x34>
    return 0;
 718:	b8 00 00 00 00       	mov    $0x0,%eax
 71d:	eb 22                	jmp    741 <morecore+0x56>
  hp = (Header*)p;
 71f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 722:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 725:	8b 45 f0             	mov    -0x10(%ebp),%eax
 728:	8b 55 08             	mov    0x8(%ebp),%edx
 72b:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 72e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 731:	83 c0 08             	add    $0x8,%eax
 734:	89 04 24             	mov    %eax,(%esp)
 737:	e8 d8 fe ff ff       	call   614 <free>
  return freep;
 73c:	a1 98 0a 00 00       	mov    0xa98,%eax
}
 741:	c9                   	leave  
 742:	c3                   	ret    

00000743 <malloc>:

void*
malloc(uint nbytes)
{
 743:	55                   	push   %ebp
 744:	89 e5                	mov    %esp,%ebp
 746:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 749:	8b 45 08             	mov    0x8(%ebp),%eax
 74c:	83 c0 07             	add    $0x7,%eax
 74f:	c1 e8 03             	shr    $0x3,%eax
 752:	83 c0 01             	add    $0x1,%eax
 755:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 758:	a1 98 0a 00 00       	mov    0xa98,%eax
 75d:	89 45 f0             	mov    %eax,-0x10(%ebp)
 760:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 764:	75 23                	jne    789 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 766:	c7 45 f0 90 0a 00 00 	movl   $0xa90,-0x10(%ebp)
 76d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 770:	a3 98 0a 00 00       	mov    %eax,0xa98
 775:	a1 98 0a 00 00       	mov    0xa98,%eax
 77a:	a3 90 0a 00 00       	mov    %eax,0xa90
    base.s.size = 0;
 77f:	c7 05 94 0a 00 00 00 	movl   $0x0,0xa94
 786:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 789:	8b 45 f0             	mov    -0x10(%ebp),%eax
 78c:	8b 00                	mov    (%eax),%eax
 78e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 791:	8b 45 f4             	mov    -0xc(%ebp),%eax
 794:	8b 40 04             	mov    0x4(%eax),%eax
 797:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 79a:	72 4d                	jb     7e9 <malloc+0xa6>
      if(p->s.size == nunits)
 79c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 79f:	8b 40 04             	mov    0x4(%eax),%eax
 7a2:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 7a5:	75 0c                	jne    7b3 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 7a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7aa:	8b 10                	mov    (%eax),%edx
 7ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7af:	89 10                	mov    %edx,(%eax)
 7b1:	eb 26                	jmp    7d9 <malloc+0x96>
      else {
        p->s.size -= nunits;
 7b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7b6:	8b 40 04             	mov    0x4(%eax),%eax
 7b9:	89 c2                	mov    %eax,%edx
 7bb:	2b 55 ec             	sub    -0x14(%ebp),%edx
 7be:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c1:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 7c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c7:	8b 40 04             	mov    0x4(%eax),%eax
 7ca:	c1 e0 03             	shl    $0x3,%eax
 7cd:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 7d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7d3:	8b 55 ec             	mov    -0x14(%ebp),%edx
 7d6:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 7d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7dc:	a3 98 0a 00 00       	mov    %eax,0xa98
      return (void*)(p + 1);
 7e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7e4:	83 c0 08             	add    $0x8,%eax
 7e7:	eb 38                	jmp    821 <malloc+0xde>
    }
    if(p == freep)
 7e9:	a1 98 0a 00 00       	mov    0xa98,%eax
 7ee:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 7f1:	75 1b                	jne    80e <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 7f3:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7f6:	89 04 24             	mov    %eax,(%esp)
 7f9:	e8 ed fe ff ff       	call   6eb <morecore>
 7fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
 801:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 805:	75 07                	jne    80e <malloc+0xcb>
        return 0;
 807:	b8 00 00 00 00       	mov    $0x0,%eax
 80c:	eb 13                	jmp    821 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 80e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 811:	89 45 f0             	mov    %eax,-0x10(%ebp)
 814:	8b 45 f4             	mov    -0xc(%ebp),%eax
 817:	8b 00                	mov    (%eax),%eax
 819:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 81c:	e9 70 ff ff ff       	jmp    791 <malloc+0x4e>
}
 821:	c9                   	leave  
 822:	c3                   	ret    

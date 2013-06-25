
_init:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:

char *argv[] = { "sh", 0 };

int
main(void)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 20             	sub    $0x20,%esp
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
   9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  10:	00 
  11:	c7 04 24 de 08 00 00 	movl   $0x8de,(%esp)
  18:	e8 9b 03 00 00       	call   3b8 <open>
  1d:	85 c0                	test   %eax,%eax
  1f:	79 30                	jns    51 <main+0x51>
    mknod("console", 1, 1);
  21:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  28:	00 
  29:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  30:	00 
  31:	c7 04 24 de 08 00 00 	movl   $0x8de,(%esp)
  38:	e8 83 03 00 00       	call   3c0 <mknod>
    open("console", O_RDWR);
  3d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  44:	00 
  45:	c7 04 24 de 08 00 00 	movl   $0x8de,(%esp)
  4c:	e8 67 03 00 00       	call   3b8 <open>
  }
  dup(0);  // stdout
  51:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  58:	e8 93 03 00 00       	call   3f0 <dup>
  dup(0);  // stderr
  5d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  64:	e8 87 03 00 00       	call   3f0 <dup>
  69:	eb 01                	jmp    6c <main+0x6c>
      printf(1, "init: exec sh failed\n");
      exit();
    }
    while((wpid=wait()) >= 0 && wpid != pid)
      printf(1, "zombie!\n");
  }
  6b:	90                   	nop
  }
  dup(0);  // stdout
  dup(0);  // stderr

  for(;;){
    printf(1, "init: starting sh\n");
  6c:	c7 44 24 04 e6 08 00 	movl   $0x8e6,0x4(%esp)
  73:	00 
  74:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  7b:	e8 97 04 00 00       	call   517 <printf>
    pid = fork();
  80:	e8 eb 02 00 00       	call   370 <fork>
  85:	89 44 24 1c          	mov    %eax,0x1c(%esp)
    if(pid < 0){
  89:	83 7c 24 1c 00       	cmpl   $0x0,0x1c(%esp)
  8e:	79 19                	jns    a9 <main+0xa9>
      printf(1, "init: fork failed\n");
  90:	c7 44 24 04 f9 08 00 	movl   $0x8f9,0x4(%esp)
  97:	00 
  98:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  9f:	e8 73 04 00 00       	call   517 <printf>
      exit();
  a4:	e8 cf 02 00 00       	call   378 <exit>
    }
    
    if(pid == 0){
  a9:	83 7c 24 1c 00       	cmpl   $0x0,0x1c(%esp)
  ae:	75 41                	jne    f1 <main+0xf1>
      exec("sh", argv);
  b0:	c7 44 24 04 70 0b 00 	movl   $0xb70,0x4(%esp)
  b7:	00 
  b8:	c7 04 24 db 08 00 00 	movl   $0x8db,(%esp)
  bf:	e8 ec 02 00 00       	call   3b0 <exec>
      printf(1, "init: exec sh failed\n");
  c4:	c7 44 24 04 0c 09 00 	movl   $0x90c,0x4(%esp)
  cb:	00 
  cc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  d3:	e8 3f 04 00 00       	call   517 <printf>
      exit();
  d8:	e8 9b 02 00 00       	call   378 <exit>
    }
    while((wpid=wait()) >= 0 && wpid != pid)
      printf(1, "zombie!\n");
  dd:	c7 44 24 04 22 09 00 	movl   $0x922,0x4(%esp)
  e4:	00 
  e5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  ec:	e8 26 04 00 00       	call   517 <printf>
    if(pid == 0){
      exec("sh", argv);
      printf(1, "init: exec sh failed\n");
      exit();
    }
    while((wpid=wait()) >= 0 && wpid != pid)
  f1:	e8 8a 02 00 00       	call   380 <wait>
  f6:	89 44 24 18          	mov    %eax,0x18(%esp)
  fa:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
  ff:	0f 88 66 ff ff ff    	js     6b <main+0x6b>
 105:	8b 44 24 18          	mov    0x18(%esp),%eax
 109:	3b 44 24 1c          	cmp    0x1c(%esp),%eax
 10d:	75 ce                	jne    dd <main+0xdd>
      printf(1, "zombie!\n");
  }
 10f:	e9 57 ff ff ff       	jmp    6b <main+0x6b>

00000114 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 114:	55                   	push   %ebp
 115:	89 e5                	mov    %esp,%ebp
 117:	57                   	push   %edi
 118:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 119:	8b 4d 08             	mov    0x8(%ebp),%ecx
 11c:	8b 55 10             	mov    0x10(%ebp),%edx
 11f:	8b 45 0c             	mov    0xc(%ebp),%eax
 122:	89 cb                	mov    %ecx,%ebx
 124:	89 df                	mov    %ebx,%edi
 126:	89 d1                	mov    %edx,%ecx
 128:	fc                   	cld    
 129:	f3 aa                	rep stos %al,%es:(%edi)
 12b:	89 ca                	mov    %ecx,%edx
 12d:	89 fb                	mov    %edi,%ebx
 12f:	89 5d 08             	mov    %ebx,0x8(%ebp)
 132:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 135:	5b                   	pop    %ebx
 136:	5f                   	pop    %edi
 137:	5d                   	pop    %ebp
 138:	c3                   	ret    

00000139 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 139:	55                   	push   %ebp
 13a:	89 e5                	mov    %esp,%ebp
 13c:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 13f:	8b 45 08             	mov    0x8(%ebp),%eax
 142:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 145:	90                   	nop
 146:	8b 45 0c             	mov    0xc(%ebp),%eax
 149:	0f b6 10             	movzbl (%eax),%edx
 14c:	8b 45 08             	mov    0x8(%ebp),%eax
 14f:	88 10                	mov    %dl,(%eax)
 151:	8b 45 08             	mov    0x8(%ebp),%eax
 154:	0f b6 00             	movzbl (%eax),%eax
 157:	84 c0                	test   %al,%al
 159:	0f 95 c0             	setne  %al
 15c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 160:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 164:	84 c0                	test   %al,%al
 166:	75 de                	jne    146 <strcpy+0xd>
    ;
  return os;
 168:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 16b:	c9                   	leave  
 16c:	c3                   	ret    

0000016d <strcmp>:

int
strcmp(const char *p, const char *q)
{
 16d:	55                   	push   %ebp
 16e:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 170:	eb 08                	jmp    17a <strcmp+0xd>
    p++, q++;
 172:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 176:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 17a:	8b 45 08             	mov    0x8(%ebp),%eax
 17d:	0f b6 00             	movzbl (%eax),%eax
 180:	84 c0                	test   %al,%al
 182:	74 10                	je     194 <strcmp+0x27>
 184:	8b 45 08             	mov    0x8(%ebp),%eax
 187:	0f b6 10             	movzbl (%eax),%edx
 18a:	8b 45 0c             	mov    0xc(%ebp),%eax
 18d:	0f b6 00             	movzbl (%eax),%eax
 190:	38 c2                	cmp    %al,%dl
 192:	74 de                	je     172 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 194:	8b 45 08             	mov    0x8(%ebp),%eax
 197:	0f b6 00             	movzbl (%eax),%eax
 19a:	0f b6 d0             	movzbl %al,%edx
 19d:	8b 45 0c             	mov    0xc(%ebp),%eax
 1a0:	0f b6 00             	movzbl (%eax),%eax
 1a3:	0f b6 c0             	movzbl %al,%eax
 1a6:	89 d1                	mov    %edx,%ecx
 1a8:	29 c1                	sub    %eax,%ecx
 1aa:	89 c8                	mov    %ecx,%eax
}
 1ac:	5d                   	pop    %ebp
 1ad:	c3                   	ret    

000001ae <strlen>:

uint
strlen(char *s)
{
 1ae:	55                   	push   %ebp
 1af:	89 e5                	mov    %esp,%ebp
 1b1:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 1b4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 1bb:	eb 04                	jmp    1c1 <strlen+0x13>
 1bd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 1c1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 1c4:	03 45 08             	add    0x8(%ebp),%eax
 1c7:	0f b6 00             	movzbl (%eax),%eax
 1ca:	84 c0                	test   %al,%al
 1cc:	75 ef                	jne    1bd <strlen+0xf>
    ;
  return n;
 1ce:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1d1:	c9                   	leave  
 1d2:	c3                   	ret    

000001d3 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1d3:	55                   	push   %ebp
 1d4:	89 e5                	mov    %esp,%ebp
 1d6:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 1d9:	8b 45 10             	mov    0x10(%ebp),%eax
 1dc:	89 44 24 08          	mov    %eax,0x8(%esp)
 1e0:	8b 45 0c             	mov    0xc(%ebp),%eax
 1e3:	89 44 24 04          	mov    %eax,0x4(%esp)
 1e7:	8b 45 08             	mov    0x8(%ebp),%eax
 1ea:	89 04 24             	mov    %eax,(%esp)
 1ed:	e8 22 ff ff ff       	call   114 <stosb>
  return dst;
 1f2:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1f5:	c9                   	leave  
 1f6:	c3                   	ret    

000001f7 <strchr>:

char*
strchr(const char *s, char c)
{
 1f7:	55                   	push   %ebp
 1f8:	89 e5                	mov    %esp,%ebp
 1fa:	83 ec 04             	sub    $0x4,%esp
 1fd:	8b 45 0c             	mov    0xc(%ebp),%eax
 200:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 203:	eb 14                	jmp    219 <strchr+0x22>
    if(*s == c)
 205:	8b 45 08             	mov    0x8(%ebp),%eax
 208:	0f b6 00             	movzbl (%eax),%eax
 20b:	3a 45 fc             	cmp    -0x4(%ebp),%al
 20e:	75 05                	jne    215 <strchr+0x1e>
      return (char*)s;
 210:	8b 45 08             	mov    0x8(%ebp),%eax
 213:	eb 13                	jmp    228 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 215:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 219:	8b 45 08             	mov    0x8(%ebp),%eax
 21c:	0f b6 00             	movzbl (%eax),%eax
 21f:	84 c0                	test   %al,%al
 221:	75 e2                	jne    205 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 223:	b8 00 00 00 00       	mov    $0x0,%eax
}
 228:	c9                   	leave  
 229:	c3                   	ret    

0000022a <gets>:

char*
gets(char *buf, int max)
{
 22a:	55                   	push   %ebp
 22b:	89 e5                	mov    %esp,%ebp
 22d:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 230:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 237:	eb 44                	jmp    27d <gets+0x53>
    cc = read(0, &c, 1);
 239:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 240:	00 
 241:	8d 45 ef             	lea    -0x11(%ebp),%eax
 244:	89 44 24 04          	mov    %eax,0x4(%esp)
 248:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 24f:	e8 3c 01 00 00       	call   390 <read>
 254:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 257:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 25b:	7e 2d                	jle    28a <gets+0x60>
      break;
    buf[i++] = c;
 25d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 260:	03 45 08             	add    0x8(%ebp),%eax
 263:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 267:	88 10                	mov    %dl,(%eax)
 269:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 26d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 271:	3c 0a                	cmp    $0xa,%al
 273:	74 16                	je     28b <gets+0x61>
 275:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 279:	3c 0d                	cmp    $0xd,%al
 27b:	74 0e                	je     28b <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 27d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 280:	83 c0 01             	add    $0x1,%eax
 283:	3b 45 0c             	cmp    0xc(%ebp),%eax
 286:	7c b1                	jl     239 <gets+0xf>
 288:	eb 01                	jmp    28b <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 28a:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 28b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 28e:	03 45 08             	add    0x8(%ebp),%eax
 291:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 294:	8b 45 08             	mov    0x8(%ebp),%eax
}
 297:	c9                   	leave  
 298:	c3                   	ret    

00000299 <stat>:

int
stat(char *n, struct stat *st)
{
 299:	55                   	push   %ebp
 29a:	89 e5                	mov    %esp,%ebp
 29c:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 29f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 2a6:	00 
 2a7:	8b 45 08             	mov    0x8(%ebp),%eax
 2aa:	89 04 24             	mov    %eax,(%esp)
 2ad:	e8 06 01 00 00       	call   3b8 <open>
 2b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 2b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 2b9:	79 07                	jns    2c2 <stat+0x29>
    return -1;
 2bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 2c0:	eb 23                	jmp    2e5 <stat+0x4c>
  r = fstat(fd, st);
 2c2:	8b 45 0c             	mov    0xc(%ebp),%eax
 2c5:	89 44 24 04          	mov    %eax,0x4(%esp)
 2c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2cc:	89 04 24             	mov    %eax,(%esp)
 2cf:	e8 fc 00 00 00       	call   3d0 <fstat>
 2d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 2d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2da:	89 04 24             	mov    %eax,(%esp)
 2dd:	e8 be 00 00 00       	call   3a0 <close>
  return r;
 2e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 2e5:	c9                   	leave  
 2e6:	c3                   	ret    

000002e7 <atoi>:

int
atoi(const char *s)
{
 2e7:	55                   	push   %ebp
 2e8:	89 e5                	mov    %esp,%ebp
 2ea:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 2ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 2f4:	eb 23                	jmp    319 <atoi+0x32>
    n = n*10 + *s++ - '0';
 2f6:	8b 55 fc             	mov    -0x4(%ebp),%edx
 2f9:	89 d0                	mov    %edx,%eax
 2fb:	c1 e0 02             	shl    $0x2,%eax
 2fe:	01 d0                	add    %edx,%eax
 300:	01 c0                	add    %eax,%eax
 302:	89 c2                	mov    %eax,%edx
 304:	8b 45 08             	mov    0x8(%ebp),%eax
 307:	0f b6 00             	movzbl (%eax),%eax
 30a:	0f be c0             	movsbl %al,%eax
 30d:	01 d0                	add    %edx,%eax
 30f:	83 e8 30             	sub    $0x30,%eax
 312:	89 45 fc             	mov    %eax,-0x4(%ebp)
 315:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 319:	8b 45 08             	mov    0x8(%ebp),%eax
 31c:	0f b6 00             	movzbl (%eax),%eax
 31f:	3c 2f                	cmp    $0x2f,%al
 321:	7e 0a                	jle    32d <atoi+0x46>
 323:	8b 45 08             	mov    0x8(%ebp),%eax
 326:	0f b6 00             	movzbl (%eax),%eax
 329:	3c 39                	cmp    $0x39,%al
 32b:	7e c9                	jle    2f6 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 32d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 330:	c9                   	leave  
 331:	c3                   	ret    

00000332 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 332:	55                   	push   %ebp
 333:	89 e5                	mov    %esp,%ebp
 335:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 338:	8b 45 08             	mov    0x8(%ebp),%eax
 33b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 33e:	8b 45 0c             	mov    0xc(%ebp),%eax
 341:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 344:	eb 13                	jmp    359 <memmove+0x27>
    *dst++ = *src++;
 346:	8b 45 f8             	mov    -0x8(%ebp),%eax
 349:	0f b6 10             	movzbl (%eax),%edx
 34c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 34f:	88 10                	mov    %dl,(%eax)
 351:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 355:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 359:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 35d:	0f 9f c0             	setg   %al
 360:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 364:	84 c0                	test   %al,%al
 366:	75 de                	jne    346 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 368:	8b 45 08             	mov    0x8(%ebp),%eax
}
 36b:	c9                   	leave  
 36c:	c3                   	ret    
 36d:	90                   	nop
 36e:	90                   	nop
 36f:	90                   	nop

00000370 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 370:	b8 01 00 00 00       	mov    $0x1,%eax
 375:	cd 40                	int    $0x40
 377:	c3                   	ret    

00000378 <exit>:
SYSCALL(exit)
 378:	b8 02 00 00 00       	mov    $0x2,%eax
 37d:	cd 40                	int    $0x40
 37f:	c3                   	ret    

00000380 <wait>:
SYSCALL(wait)
 380:	b8 03 00 00 00       	mov    $0x3,%eax
 385:	cd 40                	int    $0x40
 387:	c3                   	ret    

00000388 <pipe>:
SYSCALL(pipe)
 388:	b8 04 00 00 00       	mov    $0x4,%eax
 38d:	cd 40                	int    $0x40
 38f:	c3                   	ret    

00000390 <read>:
SYSCALL(read)
 390:	b8 05 00 00 00       	mov    $0x5,%eax
 395:	cd 40                	int    $0x40
 397:	c3                   	ret    

00000398 <write>:
SYSCALL(write)
 398:	b8 10 00 00 00       	mov    $0x10,%eax
 39d:	cd 40                	int    $0x40
 39f:	c3                   	ret    

000003a0 <close>:
SYSCALL(close)
 3a0:	b8 15 00 00 00       	mov    $0x15,%eax
 3a5:	cd 40                	int    $0x40
 3a7:	c3                   	ret    

000003a8 <kill>:
SYSCALL(kill)
 3a8:	b8 06 00 00 00       	mov    $0x6,%eax
 3ad:	cd 40                	int    $0x40
 3af:	c3                   	ret    

000003b0 <exec>:
SYSCALL(exec)
 3b0:	b8 07 00 00 00       	mov    $0x7,%eax
 3b5:	cd 40                	int    $0x40
 3b7:	c3                   	ret    

000003b8 <open>:
SYSCALL(open)
 3b8:	b8 0f 00 00 00       	mov    $0xf,%eax
 3bd:	cd 40                	int    $0x40
 3bf:	c3                   	ret    

000003c0 <mknod>:
SYSCALL(mknod)
 3c0:	b8 11 00 00 00       	mov    $0x11,%eax
 3c5:	cd 40                	int    $0x40
 3c7:	c3                   	ret    

000003c8 <unlink>:
SYSCALL(unlink)
 3c8:	b8 12 00 00 00       	mov    $0x12,%eax
 3cd:	cd 40                	int    $0x40
 3cf:	c3                   	ret    

000003d0 <fstat>:
SYSCALL(fstat)
 3d0:	b8 08 00 00 00       	mov    $0x8,%eax
 3d5:	cd 40                	int    $0x40
 3d7:	c3                   	ret    

000003d8 <link>:
SYSCALL(link)
 3d8:	b8 13 00 00 00       	mov    $0x13,%eax
 3dd:	cd 40                	int    $0x40
 3df:	c3                   	ret    

000003e0 <mkdir>:
SYSCALL(mkdir)
 3e0:	b8 14 00 00 00       	mov    $0x14,%eax
 3e5:	cd 40                	int    $0x40
 3e7:	c3                   	ret    

000003e8 <chdir>:
SYSCALL(chdir)
 3e8:	b8 09 00 00 00       	mov    $0x9,%eax
 3ed:	cd 40                	int    $0x40
 3ef:	c3                   	ret    

000003f0 <dup>:
SYSCALL(dup)
 3f0:	b8 0a 00 00 00       	mov    $0xa,%eax
 3f5:	cd 40                	int    $0x40
 3f7:	c3                   	ret    

000003f8 <getpid>:
SYSCALL(getpid)
 3f8:	b8 0b 00 00 00       	mov    $0xb,%eax
 3fd:	cd 40                	int    $0x40
 3ff:	c3                   	ret    

00000400 <sbrk>:
SYSCALL(sbrk)
 400:	b8 0c 00 00 00       	mov    $0xc,%eax
 405:	cd 40                	int    $0x40
 407:	c3                   	ret    

00000408 <sleep>:
SYSCALL(sleep)
 408:	b8 0d 00 00 00       	mov    $0xd,%eax
 40d:	cd 40                	int    $0x40
 40f:	c3                   	ret    

00000410 <uptime>:
SYSCALL(uptime)
 410:	b8 0e 00 00 00       	mov    $0xe,%eax
 415:	cd 40                	int    $0x40
 417:	c3                   	ret    

00000418 <getFileBlocks>:
SYSCALL(getFileBlocks)
 418:	b8 16 00 00 00       	mov    $0x16,%eax
 41d:	cd 40                	int    $0x40
 41f:	c3                   	ret    

00000420 <getFreeBlocks>:
SYSCALL(getFreeBlocks)
 420:	b8 17 00 00 00       	mov    $0x17,%eax
 425:	cd 40                	int    $0x40
 427:	c3                   	ret    

00000428 <getSharedBlocksRate>:
SYSCALL(getSharedBlocksRate)
 428:	b8 18 00 00 00       	mov    $0x18,%eax
 42d:	cd 40                	int    $0x40
 42f:	c3                   	ret    

00000430 <dedup>:
SYSCALL(dedup)
 430:	b8 19 00 00 00       	mov    $0x19,%eax
 435:	cd 40                	int    $0x40
 437:	c3                   	ret    

00000438 <getBlkRef>:
SYSCALL(getBlkRef)
 438:	b8 1a 00 00 00       	mov    $0x1a,%eax
 43d:	cd 40                	int    $0x40
 43f:	c3                   	ret    

00000440 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 440:	55                   	push   %ebp
 441:	89 e5                	mov    %esp,%ebp
 443:	83 ec 28             	sub    $0x28,%esp
 446:	8b 45 0c             	mov    0xc(%ebp),%eax
 449:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 44c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 453:	00 
 454:	8d 45 f4             	lea    -0xc(%ebp),%eax
 457:	89 44 24 04          	mov    %eax,0x4(%esp)
 45b:	8b 45 08             	mov    0x8(%ebp),%eax
 45e:	89 04 24             	mov    %eax,(%esp)
 461:	e8 32 ff ff ff       	call   398 <write>
}
 466:	c9                   	leave  
 467:	c3                   	ret    

00000468 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 468:	55                   	push   %ebp
 469:	89 e5                	mov    %esp,%ebp
 46b:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 46e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 475:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 479:	74 17                	je     492 <printint+0x2a>
 47b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 47f:	79 11                	jns    492 <printint+0x2a>
    neg = 1;
 481:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 488:	8b 45 0c             	mov    0xc(%ebp),%eax
 48b:	f7 d8                	neg    %eax
 48d:	89 45 ec             	mov    %eax,-0x14(%ebp)
 490:	eb 06                	jmp    498 <printint+0x30>
  } else {
    x = xx;
 492:	8b 45 0c             	mov    0xc(%ebp),%eax
 495:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 498:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 49f:	8b 4d 10             	mov    0x10(%ebp),%ecx
 4a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4a5:	ba 00 00 00 00       	mov    $0x0,%edx
 4aa:	f7 f1                	div    %ecx
 4ac:	89 d0                	mov    %edx,%eax
 4ae:	0f b6 90 78 0b 00 00 	movzbl 0xb78(%eax),%edx
 4b5:	8d 45 dc             	lea    -0x24(%ebp),%eax
 4b8:	03 45 f4             	add    -0xc(%ebp),%eax
 4bb:	88 10                	mov    %dl,(%eax)
 4bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 4c1:	8b 55 10             	mov    0x10(%ebp),%edx
 4c4:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 4c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
 4ca:	ba 00 00 00 00       	mov    $0x0,%edx
 4cf:	f7 75 d4             	divl   -0x2c(%ebp)
 4d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4d5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 4d9:	75 c4                	jne    49f <printint+0x37>
  if(neg)
 4db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 4df:	74 2a                	je     50b <printint+0xa3>
    buf[i++] = '-';
 4e1:	8d 45 dc             	lea    -0x24(%ebp),%eax
 4e4:	03 45 f4             	add    -0xc(%ebp),%eax
 4e7:	c6 00 2d             	movb   $0x2d,(%eax)
 4ea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 4ee:	eb 1b                	jmp    50b <printint+0xa3>
    putc(fd, buf[i]);
 4f0:	8d 45 dc             	lea    -0x24(%ebp),%eax
 4f3:	03 45 f4             	add    -0xc(%ebp),%eax
 4f6:	0f b6 00             	movzbl (%eax),%eax
 4f9:	0f be c0             	movsbl %al,%eax
 4fc:	89 44 24 04          	mov    %eax,0x4(%esp)
 500:	8b 45 08             	mov    0x8(%ebp),%eax
 503:	89 04 24             	mov    %eax,(%esp)
 506:	e8 35 ff ff ff       	call   440 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 50b:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 50f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 513:	79 db                	jns    4f0 <printint+0x88>
    putc(fd, buf[i]);
}
 515:	c9                   	leave  
 516:	c3                   	ret    

00000517 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 517:	55                   	push   %ebp
 518:	89 e5                	mov    %esp,%ebp
 51a:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 51d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 524:	8d 45 0c             	lea    0xc(%ebp),%eax
 527:	83 c0 04             	add    $0x4,%eax
 52a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 52d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 534:	e9 7d 01 00 00       	jmp    6b6 <printf+0x19f>
    c = fmt[i] & 0xff;
 539:	8b 55 0c             	mov    0xc(%ebp),%edx
 53c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 53f:	01 d0                	add    %edx,%eax
 541:	0f b6 00             	movzbl (%eax),%eax
 544:	0f be c0             	movsbl %al,%eax
 547:	25 ff 00 00 00       	and    $0xff,%eax
 54c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 54f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 553:	75 2c                	jne    581 <printf+0x6a>
      if(c == '%'){
 555:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 559:	75 0c                	jne    567 <printf+0x50>
        state = '%';
 55b:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 562:	e9 4b 01 00 00       	jmp    6b2 <printf+0x19b>
      } else {
        putc(fd, c);
 567:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 56a:	0f be c0             	movsbl %al,%eax
 56d:	89 44 24 04          	mov    %eax,0x4(%esp)
 571:	8b 45 08             	mov    0x8(%ebp),%eax
 574:	89 04 24             	mov    %eax,(%esp)
 577:	e8 c4 fe ff ff       	call   440 <putc>
 57c:	e9 31 01 00 00       	jmp    6b2 <printf+0x19b>
      }
    } else if(state == '%'){
 581:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 585:	0f 85 27 01 00 00    	jne    6b2 <printf+0x19b>
      if(c == 'd'){
 58b:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 58f:	75 2d                	jne    5be <printf+0xa7>
        printint(fd, *ap, 10, 1);
 591:	8b 45 e8             	mov    -0x18(%ebp),%eax
 594:	8b 00                	mov    (%eax),%eax
 596:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 59d:	00 
 59e:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 5a5:	00 
 5a6:	89 44 24 04          	mov    %eax,0x4(%esp)
 5aa:	8b 45 08             	mov    0x8(%ebp),%eax
 5ad:	89 04 24             	mov    %eax,(%esp)
 5b0:	e8 b3 fe ff ff       	call   468 <printint>
        ap++;
 5b5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5b9:	e9 ed 00 00 00       	jmp    6ab <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 5be:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 5c2:	74 06                	je     5ca <printf+0xb3>
 5c4:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 5c8:	75 2d                	jne    5f7 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 5ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5cd:	8b 00                	mov    (%eax),%eax
 5cf:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 5d6:	00 
 5d7:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 5de:	00 
 5df:	89 44 24 04          	mov    %eax,0x4(%esp)
 5e3:	8b 45 08             	mov    0x8(%ebp),%eax
 5e6:	89 04 24             	mov    %eax,(%esp)
 5e9:	e8 7a fe ff ff       	call   468 <printint>
        ap++;
 5ee:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5f2:	e9 b4 00 00 00       	jmp    6ab <printf+0x194>
      } else if(c == 's'){
 5f7:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 5fb:	75 46                	jne    643 <printf+0x12c>
        s = (char*)*ap;
 5fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
 600:	8b 00                	mov    (%eax),%eax
 602:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 605:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 609:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 60d:	75 27                	jne    636 <printf+0x11f>
          s = "(null)";
 60f:	c7 45 f4 2b 09 00 00 	movl   $0x92b,-0xc(%ebp)
        while(*s != 0){
 616:	eb 1e                	jmp    636 <printf+0x11f>
          putc(fd, *s);
 618:	8b 45 f4             	mov    -0xc(%ebp),%eax
 61b:	0f b6 00             	movzbl (%eax),%eax
 61e:	0f be c0             	movsbl %al,%eax
 621:	89 44 24 04          	mov    %eax,0x4(%esp)
 625:	8b 45 08             	mov    0x8(%ebp),%eax
 628:	89 04 24             	mov    %eax,(%esp)
 62b:	e8 10 fe ff ff       	call   440 <putc>
          s++;
 630:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 634:	eb 01                	jmp    637 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 636:	90                   	nop
 637:	8b 45 f4             	mov    -0xc(%ebp),%eax
 63a:	0f b6 00             	movzbl (%eax),%eax
 63d:	84 c0                	test   %al,%al
 63f:	75 d7                	jne    618 <printf+0x101>
 641:	eb 68                	jmp    6ab <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 643:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 647:	75 1d                	jne    666 <printf+0x14f>
        putc(fd, *ap);
 649:	8b 45 e8             	mov    -0x18(%ebp),%eax
 64c:	8b 00                	mov    (%eax),%eax
 64e:	0f be c0             	movsbl %al,%eax
 651:	89 44 24 04          	mov    %eax,0x4(%esp)
 655:	8b 45 08             	mov    0x8(%ebp),%eax
 658:	89 04 24             	mov    %eax,(%esp)
 65b:	e8 e0 fd ff ff       	call   440 <putc>
        ap++;
 660:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 664:	eb 45                	jmp    6ab <printf+0x194>
      } else if(c == '%'){
 666:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 66a:	75 17                	jne    683 <printf+0x16c>
        putc(fd, c);
 66c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 66f:	0f be c0             	movsbl %al,%eax
 672:	89 44 24 04          	mov    %eax,0x4(%esp)
 676:	8b 45 08             	mov    0x8(%ebp),%eax
 679:	89 04 24             	mov    %eax,(%esp)
 67c:	e8 bf fd ff ff       	call   440 <putc>
 681:	eb 28                	jmp    6ab <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 683:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 68a:	00 
 68b:	8b 45 08             	mov    0x8(%ebp),%eax
 68e:	89 04 24             	mov    %eax,(%esp)
 691:	e8 aa fd ff ff       	call   440 <putc>
        putc(fd, c);
 696:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 699:	0f be c0             	movsbl %al,%eax
 69c:	89 44 24 04          	mov    %eax,0x4(%esp)
 6a0:	8b 45 08             	mov    0x8(%ebp),%eax
 6a3:	89 04 24             	mov    %eax,(%esp)
 6a6:	e8 95 fd ff ff       	call   440 <putc>
      }
      state = 0;
 6ab:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 6b2:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 6b6:	8b 55 0c             	mov    0xc(%ebp),%edx
 6b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6bc:	01 d0                	add    %edx,%eax
 6be:	0f b6 00             	movzbl (%eax),%eax
 6c1:	84 c0                	test   %al,%al
 6c3:	0f 85 70 fe ff ff    	jne    539 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 6c9:	c9                   	leave  
 6ca:	c3                   	ret    
 6cb:	90                   	nop

000006cc <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6cc:	55                   	push   %ebp
 6cd:	89 e5                	mov    %esp,%ebp
 6cf:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d2:	8b 45 08             	mov    0x8(%ebp),%eax
 6d5:	83 e8 08             	sub    $0x8,%eax
 6d8:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6db:	a1 94 0b 00 00       	mov    0xb94,%eax
 6e0:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6e3:	eb 24                	jmp    709 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6e8:	8b 00                	mov    (%eax),%eax
 6ea:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6ed:	77 12                	ja     701 <free+0x35>
 6ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6f2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6f5:	77 24                	ja     71b <free+0x4f>
 6f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6fa:	8b 00                	mov    (%eax),%eax
 6fc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6ff:	77 1a                	ja     71b <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 701:	8b 45 fc             	mov    -0x4(%ebp),%eax
 704:	8b 00                	mov    (%eax),%eax
 706:	89 45 fc             	mov    %eax,-0x4(%ebp)
 709:	8b 45 f8             	mov    -0x8(%ebp),%eax
 70c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 70f:	76 d4                	jbe    6e5 <free+0x19>
 711:	8b 45 fc             	mov    -0x4(%ebp),%eax
 714:	8b 00                	mov    (%eax),%eax
 716:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 719:	76 ca                	jbe    6e5 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 71b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 71e:	8b 40 04             	mov    0x4(%eax),%eax
 721:	c1 e0 03             	shl    $0x3,%eax
 724:	89 c2                	mov    %eax,%edx
 726:	03 55 f8             	add    -0x8(%ebp),%edx
 729:	8b 45 fc             	mov    -0x4(%ebp),%eax
 72c:	8b 00                	mov    (%eax),%eax
 72e:	39 c2                	cmp    %eax,%edx
 730:	75 24                	jne    756 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 732:	8b 45 f8             	mov    -0x8(%ebp),%eax
 735:	8b 50 04             	mov    0x4(%eax),%edx
 738:	8b 45 fc             	mov    -0x4(%ebp),%eax
 73b:	8b 00                	mov    (%eax),%eax
 73d:	8b 40 04             	mov    0x4(%eax),%eax
 740:	01 c2                	add    %eax,%edx
 742:	8b 45 f8             	mov    -0x8(%ebp),%eax
 745:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 748:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74b:	8b 00                	mov    (%eax),%eax
 74d:	8b 10                	mov    (%eax),%edx
 74f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 752:	89 10                	mov    %edx,(%eax)
 754:	eb 0a                	jmp    760 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 756:	8b 45 fc             	mov    -0x4(%ebp),%eax
 759:	8b 10                	mov    (%eax),%edx
 75b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 75e:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 760:	8b 45 fc             	mov    -0x4(%ebp),%eax
 763:	8b 40 04             	mov    0x4(%eax),%eax
 766:	c1 e0 03             	shl    $0x3,%eax
 769:	03 45 fc             	add    -0x4(%ebp),%eax
 76c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 76f:	75 20                	jne    791 <free+0xc5>
    p->s.size += bp->s.size;
 771:	8b 45 fc             	mov    -0x4(%ebp),%eax
 774:	8b 50 04             	mov    0x4(%eax),%edx
 777:	8b 45 f8             	mov    -0x8(%ebp),%eax
 77a:	8b 40 04             	mov    0x4(%eax),%eax
 77d:	01 c2                	add    %eax,%edx
 77f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 782:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 785:	8b 45 f8             	mov    -0x8(%ebp),%eax
 788:	8b 10                	mov    (%eax),%edx
 78a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 78d:	89 10                	mov    %edx,(%eax)
 78f:	eb 08                	jmp    799 <free+0xcd>
  } else
    p->s.ptr = bp;
 791:	8b 45 fc             	mov    -0x4(%ebp),%eax
 794:	8b 55 f8             	mov    -0x8(%ebp),%edx
 797:	89 10                	mov    %edx,(%eax)
  freep = p;
 799:	8b 45 fc             	mov    -0x4(%ebp),%eax
 79c:	a3 94 0b 00 00       	mov    %eax,0xb94
}
 7a1:	c9                   	leave  
 7a2:	c3                   	ret    

000007a3 <morecore>:

static Header*
morecore(uint nu)
{
 7a3:	55                   	push   %ebp
 7a4:	89 e5                	mov    %esp,%ebp
 7a6:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 7a9:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 7b0:	77 07                	ja     7b9 <morecore+0x16>
    nu = 4096;
 7b2:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 7b9:	8b 45 08             	mov    0x8(%ebp),%eax
 7bc:	c1 e0 03             	shl    $0x3,%eax
 7bf:	89 04 24             	mov    %eax,(%esp)
 7c2:	e8 39 fc ff ff       	call   400 <sbrk>
 7c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 7ca:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 7ce:	75 07                	jne    7d7 <morecore+0x34>
    return 0;
 7d0:	b8 00 00 00 00       	mov    $0x0,%eax
 7d5:	eb 22                	jmp    7f9 <morecore+0x56>
  hp = (Header*)p;
 7d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7da:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 7dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7e0:	8b 55 08             	mov    0x8(%ebp),%edx
 7e3:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 7e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7e9:	83 c0 08             	add    $0x8,%eax
 7ec:	89 04 24             	mov    %eax,(%esp)
 7ef:	e8 d8 fe ff ff       	call   6cc <free>
  return freep;
 7f4:	a1 94 0b 00 00       	mov    0xb94,%eax
}
 7f9:	c9                   	leave  
 7fa:	c3                   	ret    

000007fb <malloc>:

void*
malloc(uint nbytes)
{
 7fb:	55                   	push   %ebp
 7fc:	89 e5                	mov    %esp,%ebp
 7fe:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 801:	8b 45 08             	mov    0x8(%ebp),%eax
 804:	83 c0 07             	add    $0x7,%eax
 807:	c1 e8 03             	shr    $0x3,%eax
 80a:	83 c0 01             	add    $0x1,%eax
 80d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 810:	a1 94 0b 00 00       	mov    0xb94,%eax
 815:	89 45 f0             	mov    %eax,-0x10(%ebp)
 818:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 81c:	75 23                	jne    841 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 81e:	c7 45 f0 8c 0b 00 00 	movl   $0xb8c,-0x10(%ebp)
 825:	8b 45 f0             	mov    -0x10(%ebp),%eax
 828:	a3 94 0b 00 00       	mov    %eax,0xb94
 82d:	a1 94 0b 00 00       	mov    0xb94,%eax
 832:	a3 8c 0b 00 00       	mov    %eax,0xb8c
    base.s.size = 0;
 837:	c7 05 90 0b 00 00 00 	movl   $0x0,0xb90
 83e:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 841:	8b 45 f0             	mov    -0x10(%ebp),%eax
 844:	8b 00                	mov    (%eax),%eax
 846:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 849:	8b 45 f4             	mov    -0xc(%ebp),%eax
 84c:	8b 40 04             	mov    0x4(%eax),%eax
 84f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 852:	72 4d                	jb     8a1 <malloc+0xa6>
      if(p->s.size == nunits)
 854:	8b 45 f4             	mov    -0xc(%ebp),%eax
 857:	8b 40 04             	mov    0x4(%eax),%eax
 85a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 85d:	75 0c                	jne    86b <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 85f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 862:	8b 10                	mov    (%eax),%edx
 864:	8b 45 f0             	mov    -0x10(%ebp),%eax
 867:	89 10                	mov    %edx,(%eax)
 869:	eb 26                	jmp    891 <malloc+0x96>
      else {
        p->s.size -= nunits;
 86b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 86e:	8b 40 04             	mov    0x4(%eax),%eax
 871:	89 c2                	mov    %eax,%edx
 873:	2b 55 ec             	sub    -0x14(%ebp),%edx
 876:	8b 45 f4             	mov    -0xc(%ebp),%eax
 879:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 87c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 87f:	8b 40 04             	mov    0x4(%eax),%eax
 882:	c1 e0 03             	shl    $0x3,%eax
 885:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 888:	8b 45 f4             	mov    -0xc(%ebp),%eax
 88b:	8b 55 ec             	mov    -0x14(%ebp),%edx
 88e:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 891:	8b 45 f0             	mov    -0x10(%ebp),%eax
 894:	a3 94 0b 00 00       	mov    %eax,0xb94
      return (void*)(p + 1);
 899:	8b 45 f4             	mov    -0xc(%ebp),%eax
 89c:	83 c0 08             	add    $0x8,%eax
 89f:	eb 38                	jmp    8d9 <malloc+0xde>
    }
    if(p == freep)
 8a1:	a1 94 0b 00 00       	mov    0xb94,%eax
 8a6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 8a9:	75 1b                	jne    8c6 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 8ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
 8ae:	89 04 24             	mov    %eax,(%esp)
 8b1:	e8 ed fe ff ff       	call   7a3 <morecore>
 8b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
 8b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 8bd:	75 07                	jne    8c6 <malloc+0xcb>
        return 0;
 8bf:	b8 00 00 00 00       	mov    $0x0,%eax
 8c4:	eb 13                	jmp    8d9 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
 8cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8cf:	8b 00                	mov    (%eax),%eax
 8d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 8d4:	e9 70 ff ff ff       	jmp    849 <malloc+0x4e>
}
 8d9:	c9                   	leave  
 8da:	c3                   	ret    

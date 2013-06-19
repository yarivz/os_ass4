//
// File descriptors
//

#include "types.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "file.h"
#include "spinlock.h"
#include "buf.h"
#include "fcntl.h"

struct devsw devsw[NDEV];
struct {
  struct spinlock lock;
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  f->ref++;
  release(&ftable.lock);
  return f;
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
    return;
  }
  ff = *f;
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);
  
  if(ff.type == FD_PIPE)
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE){
    begin_trans();
    iput(ff.ip);
    commit_trans();
  }
}

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
  if(f->type == FD_INODE){
    ilock(f->ip);
    stati(f->ip, st);
    iunlock(f->ip);
    return 0;
  }
  return -1;
}

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
  int r;

  if(f->readable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
    ilock(f->ip);
    if((r = readi(f->ip, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
    return r;
  }
  panic("fileread");
}

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
  int r;

  if(f->writable == 0)
    return -1;
  if(f->type == FD_PIPE)
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_trans();
      ilock(f->ip);
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
  }
  panic("filewrite");
}

int
getFileBlocks(char* path)
{
  struct file * f;
  struct inode* ip;
  struct buf* bp;
  uint i ,*a;
  
  if((f = fileopen(path,O_RDONLY)) == 0)
  {
    cprintf("Could not open file %s\n",path);
    return -1;
  }
  ip = f->ip;
  ilock(ip);
  
  cprintf("Printing all blocks for file %s:\n\n",path);
  
  for(i = 0; i < NDIRECT ; i++)
  {
    if(ip->addrs[i])
      cprintf("DIRECT block #%d = %d\n",i,ip->addrs[i]);
  }
  if(ip->addrs[NDIRECT]){
    cprintf("INDIRECT TABLE block #%d = %d\n",i,ip->addrs[NDIRECT]);
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(i = 0; i < NINDIRECT; i++){
      if(a[i])
        cprintf("INDIRECT block #%d = %d\n",i,a[i]);
    }
    brelse(bp);
    
  }
  iunlock(ip);
  return 0;  
}

int
getFreeBlocks(void)
{
  int b, bi, m,count = 0;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(1, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(1, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // Is block free?
	  count++;
      }
    }
    brelse(bp);
  }
  cprintf("No. of free blocks = %d\n",count);
  return 0;
}

int
blkcmp(struct buf* b1, struct buf* b2)
{
  int i;
  for(i = 0; i<BSIZE; i++)
  {
    if(b1->data[i] != b2->data[i])
      return 0;
  }
  return 1;  
}

int
dedup(void)
{
  int i,j,k,n,found=0;
  struct file f1, f2;
  struct inode* ip1, *ip2;
  struct buf *b1, *b2, *bp1, *bp2;
  uint *a = 0, *b = 0;
  
  acquire(&ftable.lock);
  for(i=0; i < NFILE - 1; i++) //iterate over all the files in the system - outer file loop
  {
    f1 = ftable.file[i];
    if(f1.ip)
    {
      ip1 = f1.ip;				//iterate over the i-th file's blocks and look for duplicate data
      if(ip1->addrs[NDIRECT])
      {
	bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
	a = (uint*)bp1->data;
      }
      for(j = 0; j < NDIRECT + NINDIRECT && !found; j++) 		//get the first block - outer block loop
      {
	if(j<NDIRECT)
	{
	  b1 = bread(ip1->dev,ip1->addrs[j]);
	  for(k = NDIRECT; k > j  ; k--) 		// compare direct to direct
	  {
	    if(ip1->addrs[j] && ip1->addrs[k]) 		//make sure both blocks are valid
	    {
	      b2 = bread(ip1->dev,ip1->addrs[k]);
	      if(blkcmp(b1,b2))
	      {
		deletedups();				//TODO implement this   
		brelse(b1);				// release the outer loop block
		found = 1;
		break;
	      }
	      brelse(b2);
	    }
	  }
	  
	  if(a && !found)
	  {
	    for(n = NINDIRECT-1; n >= 0 ; n--)		// compare direct block to all the indirect
	    {
	      if(ip1->addrs[j] && a[n])
	      {
		b2 = bread(ip1->dev,a[n]);
		if(blkcmp(b1,b2))
		{
		  deletedups();	
		  brelse(b1);				// release the outer loop block
		  found = 1;
		  break;
		}
		brelse(b2);
	      }
	    }
	  }
	}
	else if(!found)
	{
	  if(a)
	  {
	    int m = j - NDIRECT;
	    b1 = bread(ip1->dev,a[m]);
	    for(n = NINDIRECT-1;n>m;n--)		// compare indirect to indirect
	    {
	      if(ip1->addrs[j] && a[m])
	      {
		b2 = bread(ip1->dev,a[n]);
		if(blkcmp(b1,b2))
		{
		  deletedups();	
		  brelse(b1);				// release the outer loop block
		  found = 1;
		  break;
		}
		brelse(b2);
	      }
	    }
	  }
	}
	
	if(!found)
	{
	  for(j=NFILE - 1; j > i && !found; j--) //iterate over all the files in the system - get the next file - inner file loop
	  {
	    f2 = ftable.file[j];
	    if(f2.ip)
	    {
	      ip2 = f2.ip;				//iterate over the i-th file's blocks and look for duplicate data
	      if(ip2->addrs[NDIRECT])
	      {
		bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
		b = (uint*)bp2->data;
	      }
	      
	      for(j = 0; j < NDIRECT + NINDIRECT; j++) 		//get the first block - outer block loop
	      {
		if(j<NDIRECT)
		{
		  b2 = bread(ip1->dev,ip1->addrs[j]);
		  if(blkcmp(b1,b2))
		  {
		    deletedups();	
		    brelse(b1);				// release the outer loop block
		    found = 1;
		    break;
		  }
		 brelse(b2);
		}
		else if(!found)
		{
		  if(a)
		  {
		    int m = j - NDIRECT;
		    b2 = bread(ip1->dev,a[m]);
		    if(blkcmp(b1,b2))
		    {
		      deletedups();	
		      brelse(b1);				// release the outer loop block
		      found = 1;
		      break;
		    }
		 brelse(b2);
		  }
		}
	      }
	      
	      if(ip2->addrs[NDIRECT])
		brelse(bp2);
	    }
	  }
	}	  
	brelse(b1);				// release the outer loop block
      }
      
      if(ip1->addrs[NDIRECT])
	brelse(bp1);
    }
  }
  
  
  return 0;		
}


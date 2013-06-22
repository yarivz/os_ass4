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

int directChanged, indirectChanged;

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
{//cprintf("in blkcmp\n");
  int i;
  for(i = 0; i<BSIZE; i++)
  {
    if(b1->data[i] != b2->data[i])
      return 0;
  }
  return 1;  
}

void
deletedups(struct inode* ip1,struct inode* ip2,struct buf *b1,struct buf *b2,int b1Index,int b2Index,uint* a, uint* b)
{
  if(!a)
  {
    if(!b)
      ip1->addrs[b1Index] = ip2->addrs[b2Index];
    else
      ip1->addrs[b1Index] = b[b2Index];
    directChanged = 1;
  }
  else
  {
    if(!b)
      a[b1Index] = ip2->addrs[b2Index];
    else
      a[b1Index] = b[b2Index];
    indirectChanged = 1;
  }
  updateBlkRef(b2->sector,1);
  int ref = getBlkRef(b1->sector);
  if(ref > 1)
    updateBlkRef(b1->sector,-1);
  else if(ref == 1)
  {
    updateBlkRef(b1->sector,-1);
    begin_trans();
    bfree(b1->dev, b1->sector);
    commit_trans();
  }
}

int
dedup(void)
{
  int blockIndex1,blockIndex2,found=0,indirects1=0,indirects2=0,ninodes=0,prevInum=0;
  struct inode* ip1=0, *ip2=0;
  struct buf *b1=0, *b2=0, *bp1=0, *bp2=0;
  uint *a = 0, *b = 0;
  struct superblock sb;
  readsb(1, &sb);
  ninodes = sb.ninodes;
  zeroNextInum();
  while((ip1 = getNextInode()) != 0) //iterate over all the dinodes in the system - outer file loop
  {  //cprintf("in first while ip1->inum = %d\n",ip1->inum);
    indirects1=0;
    directChanged = 0;
    indirectChanged = 0;
    ilock(ip1);				//iterate over the i-th file's blocks and look for duplicate data
    if(ip1->addrs[NDIRECT])
    {
      bp1 = bread(ip1->dev, ip1->addrs[NDIRECT]);
      a = (uint*)bp1->data;
      indirects1 = NINDIRECT;
    }
    for(blockIndex1 = 0,found = 0; blockIndex1 < NDIRECT + indirects1; blockIndex1++,found=0) 		//get the first block - outer block loop
    {//cprintf("in first for blockIndex1 = %d\n",blockIndex1);
      if(blockIndex1<NDIRECT)							// in the same file
      {
	if(ip1->addrs[blockIndex1])
	{
	  b1 = bread(ip1->dev,ip1->addrs[blockIndex1]);
	  for(blockIndex2 = NDIRECT + indirects1-1; blockIndex2 > blockIndex1  ; blockIndex2--) 		// compare direct to rect
	  {
	    if(blockIndex2 < NDIRECT)
	    {
	      if(ip1->addrs[blockIndex1] && ip1->addrs[blockIndex2] && ip1->addrs[blockIndex1] != ip1->addrs[blockIndex2]) 		//make sure both blocks are valid
	      {//cprintf("in 2nd for if\n");
		b2 = bread(ip1->dev,ip1->addrs[blockIndex2]);
		//cprintf("before blkcmp 1\n");
		if(blkcmp(b1,b2))
		{//cprintf("after blkcmp\n");
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,0);
		  brelse(b1);				// release the outer loop block
		  brelse(b2);
		  found = 1;
		  break;
		}
		brelse(b2);
	      }
	    }
	    else if(a)
	    {								//same file, direct to indirect block
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
	      if(ip1->addrs[blockIndex1] && a[blockIndex2Offset] && ip1->addrs[blockIndex1] != a[blockIndex2Offset])
	      {
		b2 = bread(ip1->dev,a[blockIndex2Offset]);//cprintf("before blkcmp 2\n");
		if(blkcmp(b1,b2))
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2Offset,0,a);
		  brelse(b1);				// release the outer loop block
		  brelse(b2);
		  found = 1;
		  break;
		}
		brelse(b2);
	      }
	    } // for blockindex2 < NINDIRECT in ip1
	      
	  } //for blockindex2 < NDIRECT in ip1
	} //if blockindex1 != 0
	else
	{//cprintf("in 2nd else\n");
	  //brelse(b1);
	  b1 = 0;
	  continue;
	}
      }
	
// 	if(b1 && a && !found)
// 	{//cprintf("in indirect 1st if\n");
// 	  for(blockIndex2 = NINDIRECT-1; blockIndex2 >= 0 ; blockIndex2--)		// compare direct block to all the indirect
// 	  {//cprintf("in indirect for\n");
// 	    if(ip1->addrs[blockIndex1] && a[blockIndex2])
// 	    {
// 	      b2 = bread(ip1->dev,a[blockIndex2]);//cprintf("before blkcmp 2\n");
// 	      if(blkcmp(b1,b2))
// 	      {
// 		deletedups(ip1,ip1,b1,b2,blockIndex1,blockIndex2,0,a);
// 		brelse(b1);				// release the outer loop block
// 		brelse(b2);
// 		found = 1;
// 		directChanged = 1;
// 		break;
// 	      }
// 	      brelse(b2);
// 	    }
// 	  } // for blockindex2 < NINDIRECT in ip1
// 	} //if not found match, check INDIRECT
//       } // if blockindex1 is < NDIRECT
      else if(!found)					// in the same file
      {
	if(a)
	{
	  int blockIndex1Offset = blockIndex1 - NDIRECT;
	  if(a[blockIndex1Offset])
	  {
	    b1 = bread(ip1->dev,a[blockIndex1Offset]);
	    for(blockIndex2 = NINDIRECT-1;blockIndex2>blockIndex1Offset;blockIndex2--)		// compare indirect to indirect
	    {
	      if(a[blockIndex2] && a[blockIndex2] != a[blockIndex1Offset])
	      {
		b2 = bread(ip1->dev,a[blockIndex2]);//cprintf("before blkcmp 3\n");
		if(blkcmp(b1,b2))
		{
		  deletedups(ip1,ip1,b1,b2,blockIndex1Offset,blockIndex2,a,a);	
		  brelse(b1);				// release the outer loop block
		  brelse(b2);
		  found = 1;
		  indirectChanged = 1;
		  break;
		}
		brelse(b2);
	      }
	    } //for blockIndex2 < NINDIRECT in ip1
	  } // if blockIndex1Offset in INDIRECT != 0
	  else
	  {
	    b1 = 0;
	    continue;
	  }
	} // if has INDIRECT
      } //if not found, compare INDIRECT to INDIRECT
      
      if(!found && b1)					// in other files
      {
	uint* aSub = 0;
	int blockIndex1Offset = blockIndex1;
	if(blockIndex1 >= NDIRECT)
	{
	  aSub = a;
	  blockIndex1Offset = blockIndex1 - NDIRECT;
	}
	prevInum = ninodes-1;
	
	while(!found && (ip2 = getPrevInode(&prevInum)) != 0) 			//iterate over all the files in the system - outer file loop
	{//cprintf("ip2->inum = %d\n",ip2->inum);
	  indirects2=0;
	  ilock(ip2);
	  if(ip2->addrs[NDIRECT])
	  {
	    bp2 = bread(ip2->dev, ip2->addrs[NDIRECT]);
	    b = (uint*)bp2->data;
	    indirects2 = NINDIRECT;
	  } // if ip2 has INDIRECT
	  //cprintf("before 1st for\n");
	  for(blockIndex2 = NDIRECT + indirects2 -1; blockIndex2 >= 0 ; blockIndex2--) 		//get the first block - outer block loop
	  {
	    if(blockIndex2<NDIRECT)
	    {
	      if((aSub && (ip2->addrs[blockIndex2] == aSub[blockIndex1Offset])) || (ip2->addrs[blockIndex2] == ip1->addrs[blockIndex1Offset]))
		continue;
	      if(ip2->addrs[blockIndex2])
	      {
		//if(blockIndex1==1)
		  //cprintf("direct ip2->addrs[blockIndex2] = %d, ip1->addrs[blockIndex1Offset] = %d\n",ip2->addrs[blockIndex2],ip1->addrs[blockIndex1Offset]);
		b2 = bread(ip2->dev,ip2->addrs[blockIndex2]);//cprintf("before blkcmp 4\n");
		if(blkcmp(b1,b2))
		{
		  //cprintf("direct blockIndex2 = %d\n",blockIndex2);
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2,aSub,0);
		  //cprintf("*****************before 1st brelse direct\n"); 
		  brelse(b1);				// release the outer loop block
		  //cprintf("*****************after 1st brelse b1 direct\n"); 
		  brelse(b2);
		  //cprintf("*****************after 1st brelse b2 direct\n"); 
		  found = 1;
		  break;
		}//cprintf("before 1st brelse\n");
		brelse(b2);
		//cprintf("after 1st brelse\n");
	      } // if blockIndex2 in ip2
	    } // if blockindex2 in ip2 < NDIRECT 
	    
	    else if(b)
	    {//cprintf("inside else if\n");
	      int blockIndex2Offset = blockIndex2 - NDIRECT;
	      
	      if((aSub && (b[blockIndex2Offset] == aSub[blockIndex1Offset])) || (b[blockIndex2Offset] == ip1->addrs[blockIndex1Offset]))
		continue;
	      if(b[blockIndex2Offset])
	      {
		//if(blockIndex1==1)
		  //cprintf("indirect b[blockIndex2Offset] = %d, ip, ip1->addrs[blockIndex1Offset] = %d\n",b[blockIndex2Offset],ip1->addrs[blockIndex1Offset]);
		b2 = bread(ip2->dev,b[blockIndex2Offset]);//cprintf("before blkcmp 5\n");
		if(blkcmp(b1,b2))
		{
		  cprintf("indirect b1->sector = %d, b2->sector = %d\n",b1->sector,b2->sector);
		  deletedups(ip1,ip2,b1,b2,blockIndex1Offset,blockIndex2Offset,aSub,b);
		  //cprintf("*****************before 2nd brelse indirect\n"); 
		  brelse(b1);				// release the outer loop block
		  //cprintf("*****************after 2nd brelse indirect\n"); 
		  brelse(b2);
		  //cprintf("*****************after 2nd brelse indirect\n"); 
		  found = 1;
		  break;
		}//cprintf("before 2nd brelse\n");
		brelse(b2);
	      } // if blockIndex2Offset in ip2 != 0
	    } // if not found and blockIndex2 > NDIRECT
	  } //for blockindex2 from 0 to NDIRECT + NINDIRECT
	  
	  if(ip2->addrs[NDIRECT])
	  {
	    //cprintf("before bp2 brelse\n");
	    brelse(bp2);
	    //cprintf("after bp2 brelse\n"); 
	  }
	  
	  iunlockput(ip2);
	} //while ip2
      }
      if(!found)
      {
	//cprintf("*****************before 1st brelse\n"); 
	brelse(b1);				// release the outer loop block
	//cprintf("*****************after 1st brelse\n"); 
      }
    } //for blockindex1
        
    if(ip1->addrs[NDIRECT])
    {
      if(indirectChanged)
	bwrite(bp1);
      //cprintf("*****************before bp1 brelse\n"); 
      brelse(bp1);
      //cprintf("*****************after bp1 brelse\n");
    }
    
    if(directChanged)
    {
      begin_trans();
      iupdate(ip1);
      commit_trans();
    }
    iunlockput(ip1);
  } // while ip1
    
  return 0;		
}

int
getSharedBlocksRate(void)
{
  int i;
  uchar saved = 0,total = 0;
  
  struct buf* bp1 = bread(1,1024);
  struct buf* bp2 = bread(1,1025);
  
  for(i=0;i<BSIZE;i++)
  {
    if(bp1->data[i] > 1)
    {
      saved += bp1->data[i]-1;
      total += bp1->data[i];
    }
    else if(bp1->data[i] == 1)
      total++;
    
    if(bp2->data[i] > 1)
    {
      saved += bp2->data[i]-1;
      total += bp2->data[i];
    }
    else if(bp2->data[i] == 1)
      total++;
  }
  
  double res = saved/total;
  cprintf("saved = %d, total = %d\n",saved,total);
  int conv = res*1000;
  cprintf("Shared block rate is: 0.%d\n",conv);
  
  return 0;
}


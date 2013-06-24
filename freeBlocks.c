#include "types.h"
#include "fs.h"
#include "file.h"
#include "user.h"




int 
main(void)
{
  int i;
  for(i = 0; i < 1024; i++)
      printf(1,"block = %d, ref = %d\n",i,getBlkRef(i));
  
  printf(1,"No. of free blocks = %d\n",getFreeBlocks());
  exit();
}
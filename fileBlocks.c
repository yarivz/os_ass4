#include "types.h"
#include "fs.h"
#include "file.h"
#include "user.h"




int 
main(int argc, char** argv)
{
  if(argc != 2)
    printf(1,"Usage: fileBlocks file\n");
  getFileBlocks(argv[1]);
  exit();
}
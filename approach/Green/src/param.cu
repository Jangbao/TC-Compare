#include "../include/param.cuh"
namespace globalParam
{
  const std::vector<int64_t> blockSizeParam{32, 64, 96, 128, 192, 256, 512, 1024};
  const std::vector<int64_t> threadPerIntersectionParam{1, 2, 4, 8, 16, 32};
}

std::string paramRead(std::vector<int64_t> &paramVec, int argc,
                      char *argv[])
{
  std::string fileName(argv[PAR_FILENAME]);
  for (int i = PAR_FILENAME + 1; i < argc; i++)
  {
    std::string argString(argv[i]);
    std::stringstream sstr(argString);
    int64_t argVal;
    sstr >> argVal;
    paramVec.push_back(argVal);
  }
  return fileName;
}

Param paramProcess(int argc, char *argv[])
{
  Param param;
  std::vector<int64_t> paramVec;

  if (argc < (PAR_FILENAME + 1))
  {
    std::cerr << "Filename not provided.\n";
    std::cerr << "Help --     \n\
          PAR_FILENAME        1 (Required)\n\
          PAR_DEVICE          2 (' ' | device)\n\
          PAR_BLOCKS          3 (' ' | blocks)\n\
          PAR_BLOCKSIZE       4 (' ' | 32,64,96,128,192,256,512,1024)\n\
          PAR_THPERINTER      5 (' ' | 1,2,4,8,16,32)\n\
          PAR_PARTITION       6 (' ' | < PAR_BLOCKS)\n";

    // std::cerr << "Help --     \n\
    //   PAR_FILENAME        1 (Required)\n\
    //   PAR_BLOCKS          2 (Required)\n\
    //   PAR_BLOCKSIZE       3 (' ' | 32,64,96,128,192,256,512,1024)\n\
    //   PAR_THPERINTER      4 (' ' | 1,2,4,8,16,32)\n\
    //   PAR_PARTITION       5 (' ' | < PAR_BLOCKS)\n";
    param.valid = false;
  }
  else
  {
    paramVec.push_back(1);
    paramVec.push_back(1);
    param.fileName = paramRead(paramVec, argc, argv);
    param.valid = true;
  }

  if (argc > PAR_DEVICE)
  {
    int64_t device = paramVec.at(PAR_DEVICE);
    param.device = device;
  }

  if (1)
  {
    if (argc > PAR_BLOCKS)
    {
      param.blocks = paramVec.at(PAR_BLOCKS);
    }
    else
    {
      std::cerr << "Number of blocks not provided for GPU(1) run.\n";
      param.valid = false;
    }

    if (argc > PAR_BLOCKSIZE)
    {
      param.threadCount = paramVec.at(PAR_BLOCKSIZE);
      param.testAll = false;
      if (!std::binary_search(globalParam::blockSizeParam.begin(),
                              globalParam::blockSizeParam.end(), param.threadCount))
      {
        std::cerr << "Invalid block size parameter(32,64,96,128,192,256,512,1024).\n";
        param.valid = false;
      }

      if (argc > PAR_THPERINTER)
      {
        param.threadPerInt = paramVec.at(PAR_THPERINTER);
      }
      else
      {
        std::cerr << "Threads per intersection not provided for single GPU run.\n";
        param.valid = false;
      }

      if (!std::binary_search(globalParam::threadPerIntersectionParam.begin(),
                              globalParam::threadPerIntersectionParam.end(), param.threadPerInt))
      {
        std::cerr << "Invalid threads per intersection(1,2,4,8,16,32).\n";
        param.valid = false;
      }
    }
    else
    {
      param.testAll = true;
    }

    if (argc > PAR_PARTITION)
    {
      param.partitionCount = paramVec.at(PAR_PARTITION);
      param.doPartitionRun = true;
      if (param.partitionCount >= param.blocks)
      {
        std::cerr << "More number of partitions than blocks!\n";
        param.valid = false;
      }
    }

    if (argc > PAR_DEVICELIST)
    {
      for (int i = PAR_DEVICELIST; i < argc; i++)
      {
        (param.deviceMap).push_back((paramVec.at(i)));
      }
      if ((param.deviceMap).size() > 1)
      {
        param.multiDevice = true;
      }
      else
      {
        param.multiDevice = false;
      }
    }
  }
  else if (argc > PAR_CPU_PARTITION)
  {
    param.partitionCount = paramVec.at(PAR_CPU_PARTITION);
    param.doPartitionRun = true;
  }

  if (!param.valid)
  {
    Param zeroParam;
    param = zeroParam;
  }

  return param;
}

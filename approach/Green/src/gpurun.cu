#include "../include/gpurun.cuh"
#include <cuda_profiler_api.h>
template <typename T>
void singleParamTestGPURun(Param param)
{
  T *offsetVector;
  T *indexVector;
  T vertexCount;
  T edgeCount;

  cudaProfilerStop();
  {
    thrust::device_vector<int> memory(1);
  }

  readBinGraph(param.fileName, offsetVector, indexVector,
               vertexCount, edgeCount);

  std::cout << "dataset\t" << param.fileName << std::endl;
  std::cout << "Number of nodes: " << vertexCount
            << ", number of edges: " << edgeCount << std::endl;

  // std::chrono::time_point<std::chrono::system_clock> execStart, execEnd, kernelStart, kernelEnd, memAllocEnd;

  // execStart = std::chrono::system_clock::now();
  cudaProfilerStop();
  thrust::device_vector<T> dOffsetVector(offsetVector,
                                         offsetVector + vertexCount + 1);
  thrust::device_vector<T> dIndexVector(indexVector, indexVector + edgeCount);
  thrust::device_vector<T> dTriangleOutputVector(vertexCount, 0);

  T const *const dOffset = thrust::raw_pointer_cast(dOffsetVector.data());
  T const *const dIndex = thrust::raw_pointer_cast(dIndexVector.data());
  T *const dTriangle = thrust::raw_pointer_cast(dTriangleOutputVector.data());
  cudaDeviceSynchronize();
  // memAllocEnd = std::chrono::system_clock::now();

  unsigned int blocks = param.blocks;
  blocks = 1000000;
  if (edgeCount / 10 < blocks)
  {
    blocks = edgeCount / 10;
  }
  unsigned int blockSize = param.threadCount;
  T threadsPerIntsctn = param.threadPerInt;
  T intsctnPerBlock = param.threadCount / param.threadPerInt;
  T threadShift = std::log2(param.threadPerInt);
  T triangleCount;

  double total_kernel_use = 0;
  int iterator_count = param.blocks;
  double startKernel, ee;
  for (int i = 0; i < iterator_count; i++)
  {
    startKernel = omp_get_wtime();
    cudaProfilerStart();
    kernelCall(blocks, blockSize, vertexCount, dOffset,
               dIndex, dTriangle, threadsPerIntsctn, intsctnPerBlock, threadShift);
    cudaDeviceSynchronize();
    cudaProfilerStop();
    triangleCount = thrust::reduce(dTriangleOutputVector.begin(),
                                   dTriangleOutputVector.end());
    ee = omp_get_wtime();
    total_kernel_use += ee - startKernel;
  }
  // std::chrono::duration<float, std::milli> memAllocDuration = memAllocEnd -
  //                                                             execStart;
  // std::chrono::duration<float, std::milli> tCountDuration = execEnd -
  //                                                           memAllocEnd;
  // std::chrono::duration<float, std::milli> kernelDuration = kernelEnd -
  //                                                           kernelStart;
  // std::chrono::duration<float, std::milli> execDuration = execEnd -
  //                                                         execStart;

  printf("iter %d, avg kernel use %lf s\n", iterator_count, total_kernel_use / iterator_count);
  printf("triangle count %ld \n\n", triangleCount);

  // std::cout << "vertexCount\t"
  //           << "edgeCount \t"
  //           << "totalTriangleCount\t"
  //           << "memAlloc\t"
  //           << "tCount\t"
  //           << "kernel\t"
  //           << "exec\n";

  // std::cout << vertexCount << "\t" << edgeCount << "\t" << totalTriangleCount << "\t" << memAllocDuration.count() << "ms\t" << tCountDuration.count() << "ms\t" << kernelDuration.count() << "ms\t" << execDuration.count() << "ms\n";

  delete[] offsetVector;
  delete[] indexVector;
}

template <typename T>
void singleGPURun(Param param,
                  T *offsetVector, T vertexCount, T *indexVector, T edgeCount)
{
  {
    thrust::device_vector<int> memory(1);
  }
  std::string fileName = std::string("runresult/") + param.fileName +
                         std::string(".o.") + std::to_string(param.blocks) + std::string(".") +
                         std::to_string(param.threadCount) + std::string(".") +
                         std::to_string(param.threadPerInt);
  std::ofstream fout(fileName, std::ios::out | std::ios::app);

  std::chrono::time_point<std::chrono::system_clock> execStart, execEnd,
      memAllocEnd;
  execStart = std::chrono::system_clock::now();
  thrust::device_vector<T> dOffsetVector(offsetVector,
                                         offsetVector + vertexCount + 1);
  thrust::device_vector<T> dIndexVector(indexVector, indexVector + edgeCount);
  thrust::device_vector<T> dTriangleOutputVector(vertexCount, 0);

  T const *const dOffset = thrust::raw_pointer_cast(dOffsetVector.data());
  T const *const dIndex = thrust::raw_pointer_cast(dIndexVector.data());
  T *const dTriangle = thrust::raw_pointer_cast(dTriangleOutputVector.data());
  cudaDeviceSynchronize();
  memAllocEnd = std::chrono::system_clock::now();

  unsigned int blocks = param.blocks;
  unsigned int blockSize = param.threadCount;
  T threadsPerIntsctn = param.threadPerInt;
  T intsctnPerBlock = param.threadCount / param.threadPerInt;
  T threadShift = std::log2(param.threadPerInt);
  kernelCall(blocks, blockSize, vertexCount, dOffset,
             dIndex, dTriangle, threadsPerIntsctn, intsctnPerBlock, threadShift);
  cudaDeviceSynchronize();
  execEnd = std::chrono::system_clock::now();
  T totalTriangleCount = thrust::reduce(dTriangleOutputVector.begin(),
                                        dTriangleOutputVector.end());

  std::chrono::duration<float, std::milli> memAllocDuration = memAllocEnd -
                                                              execStart;
  std::chrono::duration<float, std::milli> tCountDuration = execEnd -
                                                            memAllocEnd;
  std::chrono::duration<float, std::milli> execDuration = execEnd -
                                                          execStart;
  fout << "ctime\t1\t" << tCountDuration.count() << "\n\n";
  fout.close();
  /*
  std::cout<<vertexCount<<"\t"<<totalTriangleCount<<"\t"<<
    memAllocDuration.count()<<"\t"<<tCountDuration.count()<<"\t"<<
    execDuration.count()<<"\n";
    */
}

template <typename T>
void allParamTestGPURun(Param param)
{
  T *offsetVector;
  T *indexVector;
  T vertexCount;
  T edgeCount;

  {
    thrust::device_vector<int> memory(1);
  }

  readBinGraph(param.fileName, offsetVector, indexVector,
               vertexCount, edgeCount);
  cudaDeviceSynchronize();

  thrust::device_vector<T> dOffsetVector(offsetVector, offsetVector + vertexCount + 1);
  thrust::device_vector<T> dIndexVector(indexVector, indexVector + edgeCount);
  thrust::device_vector<T> dTriangleOutputVector(dOffsetVector.size(), 0);

  T const *const dOffset = thrust::raw_pointer_cast(dOffsetVector.data());
  T const *const dIndex = thrust::raw_pointer_cast(dIndexVector.data());
  T *const dTriangle = thrust::raw_pointer_cast(dTriangleOutputVector.data());

  std::string dataset = getFileName(param.fileName);
  std::string fileOutName = std::string("./output/") + dataset + std::string("_") + std::to_string(param.blocks) + std::string(".output");

  printf("output: %s\n", fileOutName.c_str());
  std::ofstream writeFile(fileOutName);
  writeFile << param.fileName << std::endl;
  writeFile << "Number of nodes: " << vertexCount
            << ", number of edges: " << edgeCount << std::endl;
  T sumTriangles;
  for (auto paramBlockSize : globalParam::blockSizeParam)
  {
    for (auto paramThreadsPerIntsctn : globalParam::threadPerIntersectionParam)
    {
      double total_kernel_use = 0;
      int iterator_count = param.blocks;
      double startKernel, ee;
      for (int i = 0; i < iterator_count; i++)
      {
        startKernel = omp_get_wtime();

        thrust::fill(dTriangleOutputVector.begin(), dTriangleOutputVector.end(), 0);
        unsigned int blocks = param.blocks;
        unsigned int blockSize = paramBlockSize;
        T threadsPerIntsctn = paramThreadsPerIntsctn;
        T intsctnPerBlock = paramBlockSize / paramThreadsPerIntsctn;
        T threadShift = std::log2(paramThreadsPerIntsctn);
        kernelCall(blocks, blockSize, vertexCount, dOffset,
                   dIndex, dTriangle, threadsPerIntsctn, intsctnPerBlock, threadShift);
        sumTriangles = thrust::reduce(dTriangleOutputVector.begin(), dTriangleOutputVector.end());
        cudaDeviceSynchronize();
        cudaError_t err = cudaGetLastError();
        if (err != cudaSuccess)
        {
          printf("%s in %s at line %d\n", cudaGetErrorString(err), __FILE__, __LINE__);
        }

        ee = omp_get_wtime();
        total_kernel_use += ee - startKernel;
      }
      writeFile << "block size " << paramBlockSize << ", threads per intersection " << paramThreadsPerIntsctn << std::endl;
      writeFile << "iter " << iterator_count << ", avg kernel use " << total_kernel_use / iterator_count << " s" << std::endl;
      writeFile << "triangle count  " << sumTriangles << std::endl
                << std::endl;
    }
  }
  writeFile.close();
}

template void singleParamTestGPURun<int32_t>(Param param);

template void singleGPURun<int32_t>(Param param,
                                    int32_t *offsetVector, int32_t vertexCount,
                                    int32_t *indexVector, int32_t edgeCount);
template void allParamTestGPURun<int32_t>(Param param);

template void singleParamTestGPURun<int64_t>(Param param);
template void singleGPURun<int64_t>(Param param,
                                    int64_t *offsetVector, int64_t vertexCount,
                                    int64_t *indexVector, int64_t edgeCount);

template void allParamTestGPURun<int64_t>(Param param);

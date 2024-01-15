#include "gpu-thrust.h"

#include <thrust/device_ptr.h>
#include <thrust/functional.h>
#include <thrust/reduce.h>
#include <thrust/sort.h>
#include <cuda_profiler_api.h>

int NumVerticesGPU(int m, int *edges)
{
  thrust::device_ptr<int> ptr(edges);
  cudaProfilerStop();
  return 1 + thrust::reduce(ptr, ptr + 2 * m, 0, thrust::maximum<int>());
}

void SortEdges(int m, int *edges)
{
  cudaProfilerStop();
  thrust::device_ptr<uint64_t> ptr((uint64_t *)edges);
  thrust::sort(ptr, ptr + m);
}

void RemoveMarkedEdges(int m, int *edges, bool *flags)
{
  thrust::device_ptr<uint64_t> ptr((uint64_t *)edges);
  thrust::device_ptr<bool> ptr_flags(flags);
  cudaProfilerStop();
  thrust::remove_if(ptr, ptr + m, ptr_flags, thrust::identity<bool>());
}

uint64_t SumResults(int size, uint64_t *results)
{
  thrust::device_ptr<uint64_t> ptr(results);
  cudaProfilerStop();
  return thrust::reduce(ptr, ptr + size);
}

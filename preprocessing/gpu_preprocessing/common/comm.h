#ifndef COMM_HEADER
#define COMM_HEADER
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <thrust/device_ptr.h>
#include <thrust/functional.h>
#include <thrust/device_vector.h>
#include <thrust/device_malloc.h>
#include <thrust/device_free.h>
#include <thrust/reduce.h>
#include <thrust/sort.h>
#include <cuda_profiler_api.h>
#include <sys/time.h>

typedef long int index_t;
typedef int vertex_t;

inline off_t fsize(const char *filename)
{
	struct stat st;
	if (stat(filename, &st) == 0)
	{
		return st.st_size;
	}
	return -1;
}


double wtime()
{
    double time[2];
    struct timeval time1;
    gettimeofday(&time1, NULL);

    time[0] = time1.tv_sec;
    time[1] = time1.tv_usec;

    return time[0] + time[1] * 1.0e-6;
}

static void HandleError(cudaError_t err,
                        const char *file,
                        int line)
{
    if (err != cudaSuccess)
    {
        printf("%s in %s at line %d\n",
               cudaGetErrorString(err),
               file, line);
        exit(EXIT_FAILURE);
    }
}
#define HRR(err) \
    (HandleError(err, __FILE__, __LINE__))

#endif


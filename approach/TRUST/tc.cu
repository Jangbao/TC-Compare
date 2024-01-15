#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <iostream>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <queue>
#include <set>
#include <iterator>
#include "../comm/cuda_comm.h"
#include <math.h>
using namespace std;

struct arguments
{
   int edge_count;
   long long count;
   double time;
   int degree;
   int vertices;
};

struct arguments Triangle_count(char input[100], struct arguments args, int threads, int blocks, int chunk_size);

int iterator_count = 100;

int main(int argc, char *argv[])
{
   char *name = argv[1];
   int device = atoi(argv[2]);
   iterator_count = atoi(argv[3]);
   // int N_THREADS = atoi(argv[2]);
   // int N_BLOCKS = atoi(argv[3]);
   // int chunk_size = atoi(argv[4]);
   int N_THREADS = 1024;
   int N_BLOCKS = 1024;
   int chunk_size = 1;
   struct arguments args = {};
   //  call the function
   // long long sum = 0;
   // double time = 0;
   cudaSetDevice(device);
   args = Triangle_count(name, args, N_THREADS, N_BLOCKS, chunk_size);
   // time = args.time;
   // sum = args.count;
   // printf("%s,%d,%d,%lld,%f,%f \n", argv[1], args.vertices, args.edge_count, sum, time, (args.edge_count / time / 1000000000));
   return 0;
}

// #define dynamic
#define static
#define shared_BUCKET_SIZE 6
#define SUM_SIZE 1
#define USE_CTA 100
#define USE_WARP 2
#define without_combination 0
#define use_static 0

#define block_bucketnum 1024
#define warp_bucketnum 32

using namespace std;

__device__ int linear_search(int neighbor, int *shared_partition, int *partition, int *bin_count, int bin, int BIN_START)
{

   for (;;)
   {
      int i = bin;
      int len = bin_count[i];
      int step = 0;
      int nowlen;
      if (len < shared_BUCKET_SIZE)
         nowlen = len;
      else
         nowlen = shared_BUCKET_SIZE;
      while (step < nowlen)
      {
         if (shared_partition[i] == neighbor)
         {
            return 1;
         }
         i += block_bucketnum;
         step += 1;
      }

      len -= shared_BUCKET_SIZE;
      i = bin + BIN_START;
      step = 0;
      while (step < len)
      {
         if (partition[i] == neighbor)
         {
            return 1;
         }
         i += block_bucketnum;
         step += 1;
      }
      if (len + shared_BUCKET_SIZE < 99)
         break;
      bin++;
   }
   return 0;
}

int my_binary_search(int len, int val, index_t *beg)
{
   int l = 0, r = len;
   while (l < r - 1)
   {
      int mid = (l + r) / 2;
      if (beg[mid + 1] - beg[mid] > val)
         l = mid;
      else
         r = mid;
   }
   if (beg[l + 1] - beg[l] <= val)
      return -1;
   return l;
}

__global__ void
trust(vertex_t *adj_list, index_t *beg_pos, int edge_count, int vertex_count, int *partition, unsigned long long *GLOBAL_COUNT, int BUCKET_SIZE, int T_Group, int *G_INDEX, int CHUNK_SIZE, int warpfirstvertex)
{

   // int tid=threadIdx.x+blockIdx.x*blockDim.x;
   // hashTable bucket 计数器
   __shared__ int bin_count[block_bucketnum];
   // 共享内存中的 hashTable
   __shared__ int shared_partition[block_bucketnum * shared_BUCKET_SIZE + 1];
   // useless[threadIdx.x]=1;
   unsigned long long __shared__ G_counter;
   int WARPSIZE = 32;
   if (threadIdx.x == 0)
   {
      G_counter = 0;
   }

   int BIN_START = blockIdx.x * block_bucketnum * BUCKET_SIZE;
   // __syncthreads();
   unsigned long long P_counter = 0;

   // start_time = clock64();
   // CTA for large degree vertex
   int vertex = blockIdx.x * CHUNK_SIZE;
   int vertex_end = vertex + CHUNK_SIZE;
   __shared__ int ver;
   while (vertex < warpfirstvertex)
   // while (0)
   {
      // if (degree<=USE_CTA) break;
      int start = beg_pos[vertex];
      int end = beg_pos[vertex + 1];
      int now = threadIdx.x + start;
      int MODULO = block_bucketnum - 1;
      // int divide=(vert_count/blockDim.x);
      int BIN_OFFSET = 0;
      // clean bin_count
      // 初始化 hashTable bucket 计数器
      for (int i = threadIdx.x; i < block_bucketnum; i += blockDim.x)
         bin_count[i] = 0;
      __syncthreads();

      // start_time = clock64();
      // count hash bin
      // 生成 hashTable
      while (now < end)
      {
         int temp = adj_list[now];
         int bin = temp & MODULO;
         int index;
         index = atomicAdd(&bin_count[bin], 1);
         if (index < shared_BUCKET_SIZE)
         {
            shared_partition[index * block_bucketnum + bin] = temp;
         }
         else if (index < BUCKET_SIZE)
         {
            index = index - shared_BUCKET_SIZE;
            partition[index * block_bucketnum + bin + BIN_START] = temp;
         }
         now += blockDim.x;
      }
      __syncthreads();

      // unsigned long long hash_time=clock64()-start_time;
      // start_time = clock64();
      // list intersection
      now = beg_pos[vertex];
      end = beg_pos[vertex + 1];
      int superwarp_ID = threadIdx.x / 64;
      int superwarp_TID = threadIdx.x % 64;
      int workid = superwarp_TID;
      now = now + superwarp_ID;
      // 获取二跳邻居节点
      int neighbor = adj_list[now];
      int neighbor_start = beg_pos[neighbor];
      int neighbor_degree = beg_pos[neighbor + 1] - neighbor_start;
      while (now < end)
      {
         // 如果当前一阶邻居节点已被处理完，找下一个一阶邻居节点去处理
         while (now < end && workid >= neighbor_degree)
         {
            now += 16;
            workid -= neighbor_degree;
            neighbor = adj_list[now];
            neighbor_start = beg_pos[neighbor];
            neighbor_degree = beg_pos[neighbor + 1] - neighbor_start;
         }
         if (now < end)
         {
            int temp = adj_list[neighbor_start + workid];
            int bin = temp & MODULO;
            P_counter += linear_search(temp, shared_partition, partition, bin_count, bin + BIN_OFFSET, BIN_START);
         }
         // __syncthreads();
         workid += 64;
      }

      __syncthreads();
      // if (vertex>1) break;
      vertex++;
      if (vertex == vertex_end)
      {
         if (threadIdx.x == 0)
         {
            ver = atomicAdd(&G_INDEX[1], CHUNK_SIZE);
         }
         __syncthreads();
         vertex = ver;
         vertex_end = vertex + CHUNK_SIZE;
      }
      // __syncthreads();
   }

   // warp method
   int WARPID = threadIdx.x / WARPSIZE;
   int WARP_TID = threadIdx.x % WARPSIZE;
   vertex = warpfirstvertex + ((WARPID + blockIdx.x * blockDim.x / WARPSIZE)) * CHUNK_SIZE;
   vertex_end = vertex + CHUNK_SIZE;
   while (vertex < vertex_count)
   {
      int degree = beg_pos[vertex + 1] - beg_pos[vertex];
      if (degree < USE_WARP)
         break;
      int start = beg_pos[vertex];
      int end = beg_pos[vertex + 1];
      int now = WARP_TID + start;
      int MODULO = warp_bucketnum - 1;
      int BIN_OFFSET = WARPID * warp_bucketnum;
      // clean bin_count

      for (int i = BIN_OFFSET + WARP_TID; i < BIN_OFFSET + warp_bucketnum; i += WARPSIZE)
         bin_count[i] = 0;
      // bin_count[threadIdx.x]=0;
      //__syncwarp();

      // count hash bin
      while (now < end)
      {
         int temp = adj_list[now];
         int bin = temp & MODULO;
         bin += BIN_OFFSET;
         int index;
         index = atomicAdd(&bin_count[bin], 1);
         if (index < shared_BUCKET_SIZE)
         {
            shared_partition[index * block_bucketnum + bin] = temp;
         }
         else if (index < BUCKET_SIZE)
         {
            index = index - shared_BUCKET_SIZE;
            partition[index * block_bucketnum + bin + BIN_START] = temp;
         }
         now += WARPSIZE;
      }
      //__syncwarp();

      now = beg_pos[vertex];
      end = beg_pos[vertex + 1];

      int workid = WARP_TID;
      while (now < end)
      {
         int neighbor = adj_list[now];
         int neighbor_start = beg_pos[neighbor];
         int neighbor_degree = beg_pos[neighbor + 1] - neighbor_start;

         while (now < end && workid >= neighbor_degree)
         {
            now++;
            workid -= neighbor_degree;
            neighbor = adj_list[now];
            neighbor_start = beg_pos[neighbor];
            neighbor_degree = beg_pos[neighbor + 1] - neighbor_start;
         }
         if (now < end)
         {
            int temp = adj_list[neighbor_start + workid];
            int bin = temp & MODULO;
            P_counter += linear_search(temp, shared_partition, partition, bin_count, bin + BIN_OFFSET, BIN_START);
         }
         //__syncwarp();
         now = __shfl_sync(0xffffffff, now, 31);
         workid = __shfl_sync(0xffffffff, workid, 31);
         workid += WARP_TID + 1;

         // workid+=WARPSIZE;
      }
      //__syncwarp();
      vertex++;
      if (vertex == vertex_end)
      {
         if (WARP_TID == 0)
         {
            vertex = atomicAdd(&G_INDEX[2], CHUNK_SIZE);
         }
         //__syncwarp();
         vertex = __shfl_sync(0xffffffff, vertex, 0);
         vertex_end = vertex + CHUNK_SIZE;
      }
   }

   atomicAdd(&G_counter, P_counter);

   __syncthreads();
   if (threadIdx.x == 0)
   {
      atomicAdd(&GLOBAL_COUNT[0], G_counter);
   }
}

struct arguments Triangle_count(char name[100], struct arguments args, int n_threads, int n_blocks, int chunk_size)
{

   int T_Group = 32;
   int BUCKET_SIZE = 100;
   int total = n_blocks * block_bucketnum * BUCKET_SIZE;
   unsigned long long *counter = (unsigned long long *)malloc(sizeof(unsigned long long) * 10);
   string json_file = name;
   graph *graph_d = new graph(json_file);
   index_t vertex_count = graph_d->vertex_count;
   index_t edge_count = graph_d->edge_count;
   index_t edges = graph_d->edge_count;
   int maxDegree = 0;
   for (int i = 1; i <= graph_d->vertex_count; i++)
   {
      int degree = graph_d->beg_pos[i] - graph_d->beg_pos[i - 1];
      if (degree > maxDegree)
      {
         maxDegree = degree;
      }
   }

   cout << "dataset\t" << json_file << endl;
   cout << "Number of nodes: " << vertex_count
        << ", number of edges: " << edge_count << endl;
   // cout << "load graph file:" << name << "  vCount:" << graph_d->vertex_count << "  eCount:" << graph_d->edge_count << "  maxDegree:" << maxDegree << endl;

   // ofstream outFile("/home/LiJB/cuda_project/TRUST/output/adj_list.txt", ios::out);
   // for (int i = 0; i < vertex_count; i++)
   // {
   //    int start = graph_d->beg_pos[i];
   //    int end = graph_d->beg_pos[i + 1];
   //    for (int j = start; j < end; j++)
   //    {
   //       outFile << i << "  " << graph_d->adj_list[j] << endl;
   //    }
   // }

   /* Preprocessing Step to calculate the ratio */
   int *prefix = (int *)malloc(sizeof(int) * vertex_count);

   int warpfirstvertex = my_binary_search(vertex_count, USE_CTA, graph_d->beg_pos) + 1;

   int *BIN_MEM;
   unsigned long long *GLOBAL_COUNT;
   int *G_INDEX;
   index_t *d_beg_pos;
   vertex_t *d_adj_list;
   HRR(cudaMalloc((void **)&GLOBAL_COUNT, sizeof(unsigned long long) * 10));
   HRR(cudaMalloc((void **)&G_INDEX, sizeof(int) * 3));
   HRR(cudaMalloc((void **)&d_beg_pos, sizeof(index_t) * (vertex_count + 1)));
   HRR(cudaMalloc((void **)&d_adj_list, sizeof(vertex_t) * (edge_count)));
   // Swap edge list count with Eend - estart; --> gives error; may add some more

   int nowindex[3];
   nowindex[0] = chunk_size * n_blocks * n_threads / T_Group;
   nowindex[1] = chunk_size * n_blocks;
   nowindex[2] = warpfirstvertex + chunk_size * (n_blocks * n_threads / T_Group);
   // unsigned long long cou=0;
   // int nowindex=0;

   HRR(cudaMemcpy(G_INDEX, &nowindex, sizeof(int) * 3, cudaMemcpyHostToDevice));
   HRR(cudaMemcpy(d_beg_pos, graph_d->beg_pos, sizeof(index_t) * (vertex_count + 1), cudaMemcpyHostToDevice));
   HRR(cudaMemcpy(d_adj_list, graph_d->adj_list, sizeof(vertex_t) * edge_count, cudaMemcpyHostToDevice));
   double t1 = wtime();
   double cmp_time;
   HRR(cudaMalloc((void **)&BIN_MEM, sizeof(int) * total));

   double total_kernel_use = 0;
   double startKernel, ee = 0;
   for (int i = 0; i < iterator_count; i++)
   {
      HRR(cudaMemcpy(G_INDEX, &nowindex, sizeof(int) * 3, cudaMemcpyHostToDevice));
      double time_start = clock();
      startKernel = wtime();
      cudaMemset(GLOBAL_COUNT, 0, sizeof(unsigned long long) * 10);
      trust<<<n_blocks, n_threads>>>(d_adj_list, d_beg_pos, edge_count, vertex_count, BIN_MEM, GLOBAL_COUNT, BUCKET_SIZE, T_Group, G_INDEX, chunk_size, warpfirstvertex);
      HRR(cudaDeviceSynchronize());
      ee = wtime();
      total_kernel_use += ee - startKernel;
      // cout << "kernel use " << ee - startKernel << endl;
      cmp_time = clock() - time_start;
   }

   // HRR(cudaFree(BIN_MEM));
   cmp_time = cmp_time / CLOCKS_PER_SEC;
   HRR(cudaFree(BIN_MEM));

   HRR(cudaMemcpy(counter, GLOBAL_COUNT, sizeof(unsigned long long) * 10, cudaMemcpyDeviceToHost));
   printf("iter %d, avg kernel use %lf s\n", iterator_count, total_kernel_use / iterator_count);
   printf("triangle count %ld \n\n", counter[0]);
   // cout << "total triangle count: " << counter[0] << endl
   //      << endl;
   // printf("avg kernel use %lf s\n\n", total_kernel_use / iterator_count);
   HRR(cudaFree(GLOBAL_COUNT));
   HRR(cudaFree(G_INDEX));
   HRR(cudaFree(d_beg_pos));
   HRR(cudaFree(d_adj_list));
   free(prefix);
   delete graph_d;
   args.time = cmp_time;
   args.count = counter[0];

   args.edge_count = edges;
   args.degree = edges / vertex_count;
   args.vertices = vertex_count;
   return args;
}

#include <iostream>
#include <algorithm>
#include <fstream>
#include <cstdio>
#include <vector>
#include <sstream>
#include <cmath>

#include "./common/comm.h"

using namespace std;

typedef struct edge
{
    index_t u, v;
} edge;

typedef struct vertex
{
    index_t old_id;
    int degree;
} vertex;

bool cmp1(vertex &a, vertex &b);
bool cmp2(vertex &a, vertex &b);
bool cmp3(edge &a, edge &b);
int printMaxDegree(string str);

__global__ void cal_degree(int edge_count, int vertex_count, int *d_degreeArr, int *d_edgeArr, int *d_srcArr, int *d_dstArr);
__global__ void redirect_edge(int edge_count, int vertex_count, int *d_degreeArr, int *d_edgeArr);
__global__ void unzip_edge(int edge_count, int vertex_count, int *d_edgeArr, int *d_srcArr, int *d_dstArr);
__global__ void cal_offset(int edge_count, int vertex_count, int *d_srcArr, index_t *d_offsetArr);
void comparasion(vertex_t *d_degreeArr,
                 vertex_t *d_srcArr,
                 vertex_t *d_dstArr,
                 vertex_t *d_edgeArr,
                 index_t *d_offsetArr,
                 vertex_t *degreeArr,
                 vertex_t *srcArr,
                 vertex_t *dstArr,
                 vertex_t *edgeArr,
                 index_t *offsetArr);

int vertex_count;
long long int edge_count;

index_t *offsetArr;
vertex_t *srcArr;
vertex_t *dstArr;

long long sizeEdgeList;
long long sizeOffsetList;

void loadgraph(string prefix)
{
    string s_begin = prefix + "begin.bin";
    string s_source = prefix + "source.bin";
    string s_adj = prefix + "adjacent.bin";

    char *begin_file = const_cast<char *>(s_begin.c_str());
    char *source_file = const_cast<char *>(s_source.c_str());
    char *adj_file = const_cast<char *>(s_adj.c_str());

    ifstream beginFile(begin_file, ios::in | ios::binary);
    ifstream sourceFile(source_file, ios::in | ios::binary);
    ifstream adjFile(adj_file, ios::in | ios::binary);

    vertex_count = fsize(begin_file) / sizeof(index_t) - 1;
    edge_count = fsize(adj_file) / sizeof(vertex_t);

    cout << "vertex: " << vertex_count << "   edge: " << edge_count << endl;
    sizeOffsetList = sizeof(index_t) * (vertex_count + 1);
    sizeEdgeList = sizeof(vertex_t) * edge_count;

    offsetArr = (index_t *)malloc(sizeOffsetList);
    srcArr = (vertex_t *)malloc(sizeEdgeList);
    dstArr = (vertex_t *)malloc(sizeEdgeList);

    beginFile.read((char *)&offsetArr[0], sizeOffsetList);
    sourceFile.read((char *)&srcArr[0], sizeEdgeList);
    adjFile.read((char *)&dstArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();
}

void writeback(string prefix)
{
    ofstream beginFile((prefix + "begin.bin").c_str(), ios::out | ios::binary);
    ofstream sourceFile((prefix + "source.bin").c_str(), ios::out | ios::binary);
    ofstream adjFile((prefix + "adjacent.bin").c_str(), ios::out | ios::binary);

    // ofstream outFile((prefix + "graph.txt").c_str(), ios::out);

    // for (int i = 0; i < 100; i++)
    // {
    //     outFile << i << " " << srcArr[i] << endl;
    // }

    // outFile << "===========================================" << endl;

    // for (int i = 0; i < 100; i++)
    // {
    //     outFile << i << " " << offsetArr[i] << endl;
    // }
    // outFile.close();

    beginFile.write((char *)&offsetArr[0], sizeOffsetList);
    sourceFile.write((char *)&srcArr[0], sizeEdgeList);
    adjFile.write((char *)&dstArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    free(srcArr);
    free(dstArr);
    free(offsetArr);
}

void compute()
{
    cudaSetDevice(1);
    
    vertex_t *d_degreeArr;
    vertex_t *d_srcArr;
    vertex_t *d_dstArr;
    vertex_t *d_edgeArr;
    index_t *d_offsetArr;

    size_t sizeVertexArr = sizeof(vertex_t) * vertex_count;
    size_t sizeEdgeArr = sizeof(vertex_t) * edge_count;

    HRR(cudaMalloc((void **)&d_degreeArr, sizeVertexArr));
    HRR(cudaMalloc((void **)&d_srcArr, sizeEdgeArr));
    HRR(cudaMalloc((void **)&d_dstArr, sizeEdgeArr));
    HRR(cudaMalloc((void **)&d_edgeArr, sizeEdgeArr * 2));
    HRR(cudaMalloc((void **)&d_offsetArr, sizeOffsetList));

    HRR(cudaMemcpy(d_srcArr, srcArr, sizeEdgeArr, cudaMemcpyHostToDevice));
    HRR(cudaMemcpy(d_dstArr, dstArr, sizeEdgeArr, cudaMemcpyHostToDevice));
    HRR(cudaMemset(d_degreeArr, 0, sizeVertexArr));

    int block_size = 1024;
    int grid_size = (edge_count - 1) / block_size + 1;

    printMaxDegree("before compute");
    double t_start = wtime();
    int iteration = 10;
    for (int k = 0; k < iteration; k++)
    {
        cal_degree<<<grid_size, block_size>>>(edge_count, vertex_count, d_degreeArr, d_edgeArr, d_srcArr, d_dstArr);
        // HRR(cudaDeviceSynchronize());

        redirect_edge<<<grid_size, block_size>>>(edge_count, vertex_count, d_degreeArr, d_edgeArr);
        // HRR(cudaDeviceSynchronize());

        thrust::device_ptr<uint64_t> sort_ptr((uint64_t *)d_edgeArr);
        thrust::sort(sort_ptr, sort_ptr + edge_count);

        unzip_edge<<<grid_size, block_size>>>(edge_count, vertex_count, d_edgeArr, d_srcArr, d_dstArr);
        // HRR(cudaDeviceSynchronize());

        cal_offset<<<grid_size, block_size>>>(edge_count, vertex_count, d_srcArr, d_offsetArr);
        // HRR(cudaDeviceSynchronize());
    }
    double t_end = wtime();

    cout << "compute time spent " << (t_end - t_start) / iteration << " s" << endl;

    HRR(cudaMemcpy(offsetArr, d_offsetArr, sizeOffsetList, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(srcArr, d_srcArr, sizeEdgeArr, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(dstArr, d_dstArr, sizeEdgeArr, cudaMemcpyDeviceToHost));
    printMaxDegree("after compute");

    cudaFree(d_degreeArr);
    cudaFree(d_offsetArr);
    cudaFree(d_edgeArr);
    cudaFree(d_srcArr);
    cudaFree(d_dstArr);
}

__global__ void cal_degree(int edge_count, int vertex_count, int *d_degreeArr, int *d_edgeArr, int *d_srcArr, int *d_dstArr)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= edge_count)
    {
        return;
    }
    int src = d_srcArr[i];
    int dst = d_dstArr[i];
    d_edgeArr[i * 2] = src;
    d_edgeArr[i * 2 + 1] = dst;

    atomicAdd(d_degreeArr + src, 1);
    atomicAdd(d_degreeArr + dst, 1);
}

__global__ void redirect_edge(int edge_count, int vertex_count, int *d_degreeArr, int *d_edgeArr)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= edge_count)
    {
        return;
    }
    int dst = d_edgeArr[i * 2];
    int src = d_edgeArr[i * 2 + 1];
    // redirect edge
    if (d_degreeArr[src] > d_degreeArr[dst] || (d_degreeArr[src] == d_degreeArr[dst] && src > dst))
    {
        d_edgeArr[i * 2] = src;
        d_edgeArr[i * 2 + 1] = dst;
    }
}

__global__ void unzip_edge(int edge_count, int vertex_count, int *d_edgeArr, int *d_srcArr, int *d_dstArr)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= edge_count)
    {
        return;
    }
    d_srcArr[i] = d_edgeArr[i * 2 + 1];
    d_dstArr[i] = d_edgeArr[i * 2];
}

__global__ void cal_offset(int edge_count, int vertex_count, int *d_srcArr, index_t *d_offsetArr)
{
    int from = blockDim.x * blockIdx.x + threadIdx.x;
    int step = gridDim.x * blockDim.x;
    for (int i = from; i <= edge_count; i += step)
    {
        int prev = i > 0 ? d_srcArr[i - 1] : -1;
        int next = i < edge_count ? d_srcArr[i] : vertex_count;
        // The calculation of offset is possible only if the previous element is smaller than the next element.
        for (int j = prev + 1; j <= next; ++j)
            d_offsetArr[j] = i;
    }
}

void comparasion(vertex_t *d_degreeArr,
                 vertex_t *d_srcArr,
                 vertex_t *d_dstArr,
                 vertex_t *d_edgeArr,
                 index_t *d_offsetArr,
                 vertex_t *degreeArr,
                 vertex_t *srcArr,
                 vertex_t *dstArr,
                 vertex_t *edgeArr,
                 index_t *offsetArr)
{
    vertex_t *degreeArr2 = (vertex_t *)malloc(sizeof(vertex_t) * vertex_count);
    vertex_t *srcArr2 = (vertex_t *)malloc(sizeof(vertex_t) * edge_count);
    vertex_t *dstArr2 = (vertex_t *)malloc(sizeof(vertex_t) * edge_count);
    vertex_t *edgeArr2 = (vertex_t *)malloc(sizeof(vertex_t) * edge_count * 2);
    vertex_t *offsetArr2 = (vertex_t *)malloc(sizeof(index_t) * (vertex_count + 1));

    HRR(cudaMemcpy(degreeArr2, d_degreeArr, sizeof(vertex_t) * vertex_count, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(srcArr2, d_srcArr, sizeof(vertex_t) * edge_count, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(dstArr2, d_dstArr, sizeof(vertex_t) * edge_count, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(edgeArr2, d_edgeArr, sizeof(vertex_t) * edge_count * 2, cudaMemcpyDeviceToHost));
    HRR(cudaMemcpy(offsetArr2, d_offsetArr, sizeof(index_t) * (vertex_count + 1), cudaMemcpyDeviceToHost));

    for (int i = 0; i < edge_count * 2; i++)
    {
        if (i < vertex_count && degreeArr2[i] != degreeArr[i])
        {
            cout << "degree " << i << "  " << degreeArr2[i] << "  " << degreeArr[i] << endl;
        }
        if (i < edge_count && srcArr2[i] != srcArr[i])
        {
            cout << "src " << i << "  " << srcArr2[i] << "  " << srcArr[i] << endl;
        }
        if (i < edge_count && dstArr2[i] != dstArr[i])
        {
            cout << "dst " << i << "  " << dstArr2[i] << "  " << dstArr[i] << endl;
        }
        if (edgeArr2[i] != edgeArr[i])
        {
            cout << "edge " << i << "  " << edgeArr2[i] << "  " << edgeArr[i] << endl;
        }
        if (i < vertex_count + 1 && offsetArr2[i] != offsetArr[i])
        {
            // cout << "offset " << i << "  " << offsetArr2[i] << "  " << offsetArr[i] << endl;
        }
    }

    free(degreeArr2);
    free(srcArr2);
    free(dstArr2);
    free(edgeArr2);
    free(offsetArr2);
}

void riddcsr(string inPrefix, string outPrefix)
{
    loadgraph(inPrefix);
    cout << "loadok" << endl;

    compute();

    writeback(outPrefix);
    cout << "writebackok" << endl;
}

int main(int argc, char *argv[])
{
    string inPrefix = argv[1];
    string outPrefix = argv[2];

    cout << "inPath: " << inPrefix << endl;
    cout << "outPath: " << outPrefix << endl;
    riddcsr(inPrefix, outPrefix);
    cout << endl;
}

bool cmp1(vertex &a, vertex &b)
{
    return a.degree < b.degree;
}

bool cmp2(vertex &a, vertex &b)
{
    return a.degree > b.degree;
}

bool cmp3(edge &a, edge &b)
{
    return a.u < b.u || (a.u == b.u && a.v < b.v);
}

int printMaxDegree(string str)
{
    int maxDegre = 0;
    for (index_t i = 1; i <= vertex_count; i++)
    {
        if (offsetArr[i] - offsetArr[i - 1] > maxDegre)
        {
            maxDegre = offsetArr[i] - offsetArr[i - 1];
        }
    }
    cout << str << " max degree :" << maxDegre << endl;
    return maxDegre;
}
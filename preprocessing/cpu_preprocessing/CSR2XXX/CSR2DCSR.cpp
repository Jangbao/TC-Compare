#include <iostream>
#include <algorithm>
#include <fstream>
#include <cstdio>
#include <vector>
#include <sstream>
#include <cmath>
#include "../common/comm.h"

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

int vertex_count;
long long int edge_count;

index_t *beginArr;
vertex_t *sourceArr;
vertex_t *adjArr;

long long sizeEdgeList;
long long sizeOffsetList;

static bool cmp1(vertex &a, vertex &b)
{
    return a.degree < b.degree;
}

static bool cmp2(vertex &a, vertex &b)
{
    return a.degree > b.degree;
}

static bool cmp3(edge &a, edge &b)
{
    return a.u < b.u || (a.u == b.u && a.v < b.v);
}

int printMaxDegree(int size, index_t *offsetArr)
{
    int maxDegre = 0;
    for (index_t i = 1; i <= size; i++)
    {
        if (offsetArr[i] - offsetArr[i - 1] > maxDegre)
        {
            maxDegre = offsetArr[i] - offsetArr[i - 1];
        }
    }
    cout << "max degree :" << maxDegre << endl;
    return maxDegre;
}

void id_ressign_loadgraph(string prefix)
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
    sizeEdgeList = sizeof(vertex_t) * edge_count;
    sizeOffsetList = sizeof(index_t) * (vertex_count + 1);

    beginArr = (index_t *)malloc(sizeOffsetList);
    sourceArr = (vertex_t *)malloc(sizeEdgeList);
    adjArr = (vertex_t *)malloc(sizeEdgeList);

    beginFile.read((char *)&beginArr[0], sizeOffsetList);
    sourceFile.read((char *)&sourceArr[0], sizeEdgeList);
    adjFile.read((char *)&adjArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    printMaxDegree(vertex_count, beginArr);

    vertex *degreeArr = (vertex *)malloc(vertex_count * sizeof(vertex));

    for (index_t i = 0; i < vertex_count; i++)
    {
        degreeArr[i].degree = 0;
    }

    for (long long int i = 0; i < edge_count; i++)
    {
        int u = sourceArr[i];
        int v = adjArr[i];
        degreeArr[u].degree++;
        degreeArr[v].degree++;
    }
    
    edge *edgeArr = (edge *)malloc(sizeof(edge) * edge_count);
    int du, dv, temp, u, v;
    for (long long int i = 0; i < edge_count; i++)
    {
        u = sourceArr[i];
        v = adjArr[i];
        du = degreeArr[u].degree;
        dv = degreeArr[v].degree;
        if (du > dv || (du == dv && u > v))
        {
            temp = u;
            u = v;
            v = temp;
        }
        edgeArr[i].u = u;
        edgeArr[i].v = v;
    }
    sort(edgeArr, edgeArr + edge_count, cmp3);
    int prevU = -1;
    for (int i = 0; i < edge_count; i++)
    {
        u = edgeArr[i].u;
        sourceArr[i] = edgeArr[i].u;
        adjArr[i] = edgeArr[i].v;
        if (u != prevU)
        {
            for (int j = prevU + 1; j <= u; j++)
            {
                beginArr[j] = i;
            }
            prevU = u;
        }
    }
    for (index_t i = prevU + 1; i < vertex_count + 1; i++)
    {
        beginArr[i] = edge_count;
    }

    printMaxDegree(vertex_count, beginArr);

    free(degreeArr);
    free(edgeArr);
}

void id_ressign_writeback(string prefix)
{
    ofstream beginFile((prefix + "begin.bin").c_str(), ios::out | ios::binary);
    ofstream sourceFile((prefix + "source.bin").c_str(), ios::out | ios::binary);
    ofstream adjFile((prefix + "adjacent.bin").c_str(), ios::out | ios::binary);

    // ofstream outFile((prefix + "graph.txt").c_str(), ios::out);

    // for (int i = 0; i < edge_count; i++)
    // {
    //     outFile << sourceArr[i] << " " << adjArr[i] << endl;
    // }
    // outFile.close();

    beginFile.write((char *)&beginArr[0], sizeOffsetList);
    sourceFile.write((char *)&sourceArr[0], sizeEdgeList);
    adjFile.write((char *)&adjArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    free(sourceArr);
    free(adjArr);
    free(beginArr);
}

void id_ressign(string inPrefix, string outPrefix)
{
    id_ressign_loadgraph(inPrefix);
    cout << "loadok" << endl;

    id_ressign_writeback(outPrefix);
    cout << "writebackok" << endl;
}

int main(int argc, char *argv[])
{
    string inPrefix = argv[1];
    string outPrefix = argv[2];

    cout << "inPath: " << inPrefix << endl;
    cout << "outPath: " << outPrefix << endl;
    id_ressign(inPrefix, outPrefix);
}
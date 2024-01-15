#include <iostream>
#include <algorithm>
#include <fstream>
#include <cstdio>
#include <vector>
#include <sstream>
#include "../common/comm.h"
#define bounder 100

using namespace std;

int vertex_count;
long long edge_count;
long long sizeEdgeList;
long long sizeVertexList;

index_t *beginArr;
vertex_t *sourceArr;
vertex_t *adjArr;

typedef struct edge_list
{
    int vertexID;
    vector<int> edge;
    int newid;
} edge_list;
vector<edge_list> vertex;
vector<edge_list> vertexb;
bool cmp1(edge_list a, edge_list b)
{
    return a.edge.size() < b.edge.size();
}
bool cmp2(edge_list a, edge_list b)
{
    return a.edge.size() > b.edge.size();
}


int binary_search(int value)
{
    int l = 0, r = vertex_count - 1;
    while (l < r - 1)
    {
        int mid = (l + r) >> 1;
        if (vertex[mid].edge.size() >= value)
            l = mid;
        else
            r = mid;
    }
    // if (arr[r]<=value) return r;
    return l;
}

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

    // cout << "vertex：" << vertex_count << "   edge：" << edge_count << endl;
    sizeEdgeList = sizeof(vertex_t) * edge_count;
    sizeVertexList = sizeof(index_t) * (vertex_count + 1);

    beginArr = (index_t *)malloc(sizeVertexList);
    sourceArr = (vertex_t *)malloc(sizeEdgeList);
    adjArr = (vertex_t *)malloc(sizeEdgeList);

    beginFile.read((char *)&beginArr[0], sizeVertexList);
    sourceFile.read((char *)&sourceArr[0], sizeEdgeList);
    adjFile.read((char *)&adjArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    vertex.resize(vertex_count);
    for (int i = 0; i < vertex_count; i++)
    {
        vertex[i].vertexID = i;
    }
    int u, v;
    for (long long int i = 0; i < edge_count; i++)
    {
        u = sourceArr[i];
        v = adjArr[i];
        vertex[u].edge.push_back(v);
        vertex[v].edge.push_back(u);
    }
    // int c = 0;
    // for (int i = 0; i < vertex_count; i++)
    // {
    //     int size = vertex[i].edge.size();
    //     for (int j = 0; j < size; j++)
    //     {
    //         if (c++ < 1000)
    //         {
    //             cout << i << "  " << vertex[i].edge[j] << endl;
    //         }
    //     }
    // }
}

void orientation()
{
    int *a = new int[vertex_count];
    for (int i = 0; i < vertex_count; i++)
    {
        a[vertex[i].vertexID] = i;
    }

    for (int i = 0; i < vertex_count; i++)
    {
        vector<int> x(vertex[i].edge);
        vertex[i].edge.clear();
        while (!x.empty())
        {
            int v = x.back();
            x.pop_back();
            if (a[v] > i)
                vertex[i].edge.push_back(v);
        }
    }
}

void reassignID()
{
    int k1 = 0, k2 = -1, k3 = -1;
    for (int i = 0; i < vertex_count; i++)
    {
        vertex[i].newid = -1;
        if (k2 == -1 && vertex[i].edge.size() <= bounder)
            k2 = i;

        if (k3 == -1 && vertex[i].edge.size() < 2)
            k3 = i;
    }
    // cout << k2 << ' ' << k3 << endl;
    int s1 = k1, s2 = k2, s3 = k3;
    for (int i = 0; i < vertex_count; i++)
    {
        if (vertex[i].edge.size() <= 2)
            break;
        for (int j = 0; j < vertex[i].edge.size(); j++)
        {
            int v = vertex[i].edge[j];
            if (vertex[v].newid == -1)
            {
                if (v >= s3)
                {
                    vertex[v].newid = k3;
                    k3++;
                }
                else if (v >= s2)
                {
                    vertex[v].newid = k2;
                    k2++;
                }
                else
                {
                    vertex[v].newid = k1;
                    k1++;
                }
            }
        }
    }
    for (int i = 0; i < vertex_count; i++)
    {
        int u = vertex[i].newid;
        if (u == -1)
        {
            if (i >= s3)
            {
                vertex[i].newid = k3;
                k3++;
            }
            else if (i >= s2)
            {
                vertex[i].newid = k2;
                k2++;
            }
            else
            {
                vertex[i].newid = k1;
                k1++;
            }
        }
    }
    vertexb.swap(vertex);
    vertex.resize(vertex_count);

    for (int i = 0; i < vertex_count; i++)
    {
        int u = vertexb[i].newid;

        for (int j = 0; j < vertexb[i].edge.size(); j++)
        {
            int v = vertexb[i].edge[j];
            v = vertexb[v].newid;
            // cout<<u<<' '<<v<<endl;
            vertex[u].edge.push_back(v);
        }
    }
}
void computeCSR(string prefix)
{
    int *a = new int[vertex_count];
    for (int i = 0; i < vertex_count; i++)
    {
        a[vertex[i].vertexID] = i;
    }
    for (int i = 0; i < vertex_count; i++)
    {
        for (int j = 0; j < vertex[i].edge.size(); j++)
        {
            vertex[i].edge[j] = a[vertex[i].edge[j]];
        }
        vertex[i].vertexID = i;
    }

    reassignID();

    ofstream beginFile((prefix + "begin.bin").c_str(), ios::out | ios::binary);
    ofstream sourceFile((prefix + "source.bin").c_str(), ios::out | ios::binary);
    ofstream adjFile((prefix + "adjacent.bin").c_str(), ios::out | ios::binary);
    int edgePoint = 0;
    long long sum = 0;
    for (int i = 0; i < vertex_count; i++)
    {
        beginArr[i] = sum;
        int size = vertex[i].edge.size();
        sort(vertex[i].edge.begin(), vertex[i].edge.end());
        sum += size;
        for (int j = 0; j < size; j++)
        {
            sourceArr[edgePoint] = i;
            adjArr[edgePoint] = vertex[i].edge[j];
            edgePoint++;
        }
    }
    beginArr[vertex_count] = edgePoint;

    beginFile.write((char *)&beginArr[0], sizeVertexList);
    sourceFile.write((char *)&sourceArr[0], sizeEdgeList);
    adjFile.write((char *)&adjArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    free(beginArr);
    free(sourceArr);
    free(adjArr);
}
int main(int argc, char *argv[])
{

    string inPrefix = argv[1];
    string outPrefix = argv[2];
    cout << "inPath: " << inPrefix << endl;
    cout << "outPath: " << outPrefix << endl;
    loadgraph(inPrefix);
    sort(vertex.begin(), vertex.end(), cmp1);

    orientation();

    sort(vertex.begin(), vertex.end(), cmp2);

    int k = binary_search(32);
    computeCSR(outPrefix);

    return 0;
}
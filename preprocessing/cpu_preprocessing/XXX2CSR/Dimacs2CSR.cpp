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
    int u, v;
} edge;

vector<edge> edgelist;
int maxvertex = 0;
int vertex_count, edge_count;

bool cmp(edge a, edge b)
{
    return a.u < b.u || (a.u == b.u && a.v < b.v);
}

void loadgraph(string filename)
{
    ifstream inFile(filename.c_str(), ios::in);
    if (!inFile)
    {
        cout << "error" << endl;
        exit(1);
    }
    int x;
    int p = 0;
    string line;
    stringstream ss;

    getline(inFile, line);
    ss << line;
    ss >> vertex_count >> edge_count;
    cout << "vertex_count:" << vertex_count << " edge_count:" << edge_count << endl;
    int u = 1;
    int v;
    while (getline(inFile, line))
    {
        ss.str("");
        ss.clear();
        ss << line;
        while (ss >> v)
        {
            edge e;
            e.u = u - 1;
            e.v = v - 1;
            edgelist.push_back(e);
        }
        u++;
    }
}

void deleteedge()
{
    sort(edgelist.begin(), edgelist.end(), cmp);
    int edgeListSize = edgelist.size();
    int slow = 0;
    int prevU = -1;
    int prevV = -1;
    for (int i = 0; i < edgeListSize; i++)
    {
        int u = edgelist[i].u;
        int v = edgelist[i].v;
        if (prevU == u && prevV == v || u == v)
        {
            continue;
        }
        if (u > v)
        {
            swap(u, v);
        }
        else
        {
            edgelist[slow].u = u;
            edgelist[slow].v = v;
            prevU = u;
            prevV = v;
            slow++;
        }
    }
    edge_count = slow;
}

void writeback(string outPath)
{
    ofstream beginFile((outPath + "begin.bin").c_str(), ios::out | ios::binary);
    ofstream sourceFile((outPath + "source.bin").c_str(), ios::out | ios::binary);
    ofstream adjFile((outPath + "adjacent.bin").c_str(), ios::out | ios::binary);

    long long sizeEdgeList = sizeof(vertex_t) * edge_count;
    long long sizeAdjList = sizeof(index_t) * (vertex_count + 1);

    index_t *beginArr = (index_t *)malloc(sizeAdjList);
    vertex_t *sourceArr = (vertex_t *)malloc(sizeEdgeList);
    vertex_t *adjArr = (vertex_t *)malloc(sizeEdgeList);

    int u = 0;
    int prevU = -1;
    for (int i = 0; i < edge_count; i++)
    {
        u = edgelist[i].u;
        sourceArr[i] = edgelist[i].u;
        adjArr[i] = edgelist[i].v;
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

    beginFile.write((char *)&beginArr[0], sizeAdjList);
    sourceFile.write((char *)&sourceArr[0], sizeEdgeList);
    adjFile.write((char *)&adjArr[0], sizeEdgeList);

    beginFile.close();
    sourceFile.close();
    adjFile.close();

    free(sourceArr);
    free(adjArr);
    free(beginArr);
}

int main(int argc, char *argv[])
{
    string infilename = argv[1];

    cout << "infilename: " << infilename << endl;
    string outPath = argv[2];
    cout << "outPath: " << outPath << endl;
    loadgraph(infilename);
    cout << "load ok" << endl;
    deleteedge();
    cout << "delete ok" << endl;
    writeback(outPath);
    cout << "writeback ok" << endl;
}
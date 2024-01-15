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
    }
    int x;
    int p = 0;
    string line;
    stringstream ss;
    while (getline(inFile, line))
    {
        if (line[0] < '0' || line[0] > '9')
            continue;
        ss.str("");
        ss.clear();
        ss << line;
        edge e;
        ss >> e.u >> e.v >> x;
        edgelist.push_back(e);
        maxvertex = max(maxvertex, max(e.u, e.v));
    }
}

void selectVertex()
{
    int *a = new int[maxvertex + 10];
    int *b = new int[maxvertex + 10];

    for (int i = 0; i <= maxvertex; i++)
    {
        a[i] = 0;
    }
    for (int i = 0; i < edgelist.size(); i++)
    {
        a[edgelist[i].u] = 1;
        a[edgelist[i].v] = 1;
    }
    int k = 0;
    for (int i = 0; i <= maxvertex; i++)
    {
        if (a[i])
        {
            a[i] = k;
            k++;
        }
    }
    vertex_count = k;
    for (int i = 0; i < edgelist.size(); i++)
    {
        int u = a[edgelist[i].u];
        int v = a[edgelist[i].v];
        if (u > v)
            swap(u, v);
        edgelist[i].u = u;
        edgelist[i].v = v;
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
    selectVertex();
    cout << "select ok" << endl;
    deleteedge();
    cout << "delete ok" << endl;
    writeback(outPath);
    cout << "writeback ok" << endl;
}
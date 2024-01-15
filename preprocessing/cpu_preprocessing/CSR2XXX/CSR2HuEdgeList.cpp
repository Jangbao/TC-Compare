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

typedef struct edge_list
{
    int vertexID;
    vector<int> edge;
} edge_list;

vector<edge_list> vertex;
int vertex_count;
long long int edge_count;

bool cmp(int a, int b)
{
    return a > b;
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

    cout << "vertex: " << vertex_count << "   edge: " << edge_count << endl;
    long long int sizeEdgeList = sizeof(vertex_t) * edge_count;

    vertex_t *sourceArr = (vertex_t *)malloc(sizeEdgeList);
    vertex_t *adjArr = (vertex_t *)malloc(sizeEdgeList);

    sourceFile.read((char *)&sourceArr[0], sizeEdgeList);
    adjFile.read((char *)&adjArr[0], sizeEdgeList);

    sourceFile.close();
    adjFile.close();

    vertex.resize(vertex_count);
    for (int i = 0; i < edge_count; i++)
    {
        vertex[sourceArr[i]].edge.push_back(adjArr[i]);
    }
    free(sourceArr);
    free(adjArr);
}

void writeback(string filename)
{
    int k = 0;
    ofstream outFile((filename + "edges.bin").c_str(), ios::out | ios::binary);
    for (int i = 0; i < vertex.size(); i++)
    {
        for (int j = 0; j < vertex[i].edge.size(); j++)
        {
            edge Edge;
            Edge.u = i;
            Edge.v = vertex[i].edge[j];
            if (k < 100)
            {
                // printf("%d %d \t ", Edge.u, Edge.v);
                k++;
            }
            outFile.write((char *)&Edge, sizeof(struct edge));
        }
    }
}

int main(int argc, char *argv[])
{
    string Infilename = argv[1];
    string Outfilename = argv[2];

    cout << "infilename: " << Infilename << endl;
    cout << "outfilename: " << Outfilename << endl;
    loadgraph(Infilename);
    cout << "load ok" << endl;
    writeback(Outfilename);
    cout << "writebackok" << endl;
}
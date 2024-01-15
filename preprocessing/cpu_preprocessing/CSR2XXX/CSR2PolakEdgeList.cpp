#include "../common/comm.h"

#include <vector>
#include <utility>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <unordered_map>

using namespace std;

typedef std::vector<std::pair<int, int>> Edges;
typedef std::vector<std::vector<int>> AdjList;

Edges ReadEdgesFromFile(const char *filename)
{
  Edges edges;
  ifstream in(filename, ios::binary);
  int m;
  in.read((char *)&m, sizeof(int));
  edges.resize(m);
  in.read((char *)edges.data(), 2 * m * sizeof(int));
  return edges;
}

void WriteEdgesToFile(const Edges &edges, string filename)
{
  ofstream out(filename.c_str(), ios::binary);
  size_t m = edges.size();
  long long int sizeEdgeList = 2 * m * sizeof(int);
  out.write((char *)&m, sizeof(int));
  out.write((char *)edges.data(), sizeEdgeList);
}

int NumVertices(const Edges &edges)
{
  int num_vertices = 0;
  for (const pair<int, int> &edge : edges)
    num_vertices = max(num_vertices, 1 + max(edge.first, edge.second));
  return num_vertices;
}

void RemoveDuplicateEdges(Edges *edges)
{
  sort(edges->begin(), edges->end());
  edges->erase(unique(edges->begin(), edges->end()), edges->end());
}

void RemoveSelfLoops(Edges *edges)
{
  for (size_t i = 0; i < edges->size(); ++i)
  {
    if ((*edges)[i].first == (*edges)[i].second)
    {
      edges->at(i) = edges->back();
      edges->pop_back();
      --i;
    }
  }
}

void MakeUndirected(Edges *edges)
{
  const size_t n = edges->size();
  for (size_t i = 0; i < n; ++i)
  {
    pair<int, int> edge = (*edges)[i];
    swap(edge.first, edge.second);
    edges->push_back(edge);
  }
}

void PermuteEdges(Edges *edges)
{
  random_shuffle(edges->begin(), edges->end());
}

void PermuteVertices(Edges *edges)
{
  vector<int> p(NumVertices(*edges));
  for (size_t i = 0; i < p.size(); ++i)
    p[i] = i;
  random_shuffle(p.begin(), p.end());
  for (pair<int, int> &edge : *edges)
  {
    edge.first = p[edge.first];
    edge.second = p[edge.second];
  }
}

AdjList EdgesToAdjList(const Edges &edges)
{
  // Sorting edges with std::sort to optimize memory access pattern when
  // creating graph gives less than 20% speedup.
  AdjList graph(NumVertices(edges));
  for (const pair<int, int> &edge : edges)
    graph[edge.first].push_back(edge.second);
  return graph;
}

Edges ReadEdgesFromCSRFile(string prefix)
{
  Edges edges;
  string s_begin = prefix + "begin.bin";
  string s_source = prefix + "source.bin";
  string s_adj = prefix + "adjacent.bin";

  char *begin_file = const_cast<char *>(s_begin.c_str());
  char *source_file = const_cast<char *>(s_source.c_str());
  char *adj_file = const_cast<char *>(s_adj.c_str());

  ifstream beginFile(begin_file, ios::in | ios::binary);
  ifstream sourceFile(source_file, ios::in | ios::binary);
  ifstream adjFile(adj_file, ios::in | ios::binary);

  int vertex_count = fsize(begin_file) / sizeof(index_t) - 1;
  long long int edge_count = fsize(adj_file) / sizeof(vertex_t);

  cout << "vertex: " << vertex_count << "   edge: " << edge_count << endl;
  long long int sizeEdgeList = sizeof(vertex_t) * edge_count;

  vertex_t *sourceArr = (vertex_t *)malloc(sizeEdgeList);
  vertex_t *adjArr = (vertex_t *)malloc(sizeEdgeList);

  sourceFile.read((char *)&sourceArr[0], sizeEdgeList);
  adjFile.read((char *)&adjArr[0], sizeEdgeList);

  sourceFile.close();
  adjFile.close();

  for (int i = 0; i < edge_count; i++)
  {
    edges.push_back(make_pair(sourceArr[i], adjArr[i]));
  }
  return edges;
}

void NormalizeEdges(Edges *edges)
{
  MakeUndirected(edges);
  size_t m = (*edges).size();
  printf("MakeUndirected  m %ld\n", m);
  RemoveDuplicateEdges(edges);
  m = (*edges).size();
  printf("RemoveDuplicateEdges  m %ld\n", m);
  RemoveSelfLoops(edges);
  m = (*edges).size();
  printf("RemoveSelfLoops  m %ld\n", m);
  PermuteEdges(edges);
  m = (*edges).size();
  printf("PermuteEdges  m %ld\n", m);
  PermuteVertices(edges);
  m = (*edges).size();
  printf("PermuteVertices  m %ld\n", m);
}

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    cerr << "Usage: " << argv[0] << " IN OUT" << endl;
    exit(1);
  }

  char *infile = argv[1];
  char *outfile = argv[2];

  cout << "infile: " << infile << endl;
  cout << "outfile: " << outfile << endl;
  Edges edges = ReadEdgesFromCSRFile(infile);
  printf("ReadEdgesFromCSRFile finished ...\n");
  NormalizeEdges(&edges);
  printf("NormalizeEdges finished ...\n");
  WriteEdgesToFile(edges, outfile);
  size_t m = edges.size();
  printf("m %ld\n", m);
  printf("WriteEdgesToFile finished ...\n");
}

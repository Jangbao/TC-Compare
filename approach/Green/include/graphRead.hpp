#ifndef GRAPHREAD
#define GRAPHREAD
#include <fstream>
#include <sys/stat.h>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>

typedef int count_t;
typedef long int index_t;
typedef int vertex_t;

template <typename T>
void readGraph(std::string filePath,
               T *&offset, T *&index, T &numVertices, T &numEdges);

template <typename T>
void readBinGraph(std::string filePath,
                  T *&offset, T *&index, T &numVertices, T &numEdges);

template <typename T>
void readPartition(std::string filePath, T partitionCount,
                   T *&partition, T &numVertices);

std::string getFileName(std::string data);

inline off_t fsize(const char *filename);
#endif

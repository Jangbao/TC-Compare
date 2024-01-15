#include "../include/graphRead.hpp"

template <typename T>
void readGraph(std::string filePath,
               T *&offset, T *&index, T &numVertices, T &numEdges)
{
  std::string infoFile = filePath;
  // infoFile.append(".info");
  printf("%s\n", infoFile.c_str());
  std::ifstream readGraphInfo(infoFile);
  readGraphInfo >> numVertices >> numEdges;
  offset = new T[numVertices];
  index = new T[numEdges];
  for (T i = 0; i < numVertices; i++)
  {
    T offsetInput;
    readGraphInfo >> offsetInput;
    offset[i] = offsetInput;
  }
  for (T i = 0; i < numEdges; i++)
  {
    T indexInput;
    readGraphInfo >> indexInput;
    index[i] = indexInput;
  }
  --numVertices;
  readGraphInfo.close();
}

template <typename T>
void readBinGraph(std::string filePath,
                  T *&offset, T *&index, T &numVertices, T &numEdges)
{
  std::string jsonfile = filePath;
  std::string s_begin = jsonfile + "/begin.bin";
  std::string s_adj = jsonfile + "/adjacent.bin";

  char *begin_file = const_cast<char *>(s_begin.c_str());
  char *adj_file = const_cast<char *>(s_adj.c_str());

  numVertices = fsize(begin_file) / sizeof(index_t) - 1;
  numEdges = fsize(adj_file) / sizeof(vertex_t);

  FILE *pFile3 = fopen(begin_file, "rb");
  index_t *beg_pos = (index_t *)malloc(fsize(begin_file));
  size_t sizeRead = fread(beg_pos, sizeof(index_t), numVertices + 1, pFile3);
  if (sizeRead != numVertices + 1)
  {
    printf("error!\n");
  }
  fclose(pFile3);

  FILE *pFile1 = fopen(adj_file, "rb");
  vertex_t *adj_list = (vertex_t *)malloc(fsize(adj_file));
  sizeRead = fread(adj_list, sizeof(vertex_t), numEdges, pFile1);
  if (sizeRead != numEdges)
  {
    printf("error!\n");
  }
  fclose(pFile1);

  offset = new T[numVertices + 1];
  index = new T[numEdges];
  for (T i = 0; i < numVertices + 1; i++)
  {
    offset[i] = beg_pos[i];
  }
  for (T i = 0; i < numEdges; i++)
  {
    index[i] = adj_list[i];
  }

  free(beg_pos);
  free(adj_list);
}

template <typename T>
void readPartition(std::string filePath, T partitionCount,
                   T *&partition, T &numVertices)
{
  std::string partitionFile = filePath;
  std::string ext = std::string(".part.") + std::to_string(partitionCount);
  partitionFile.append(ext);
  std::ifstream readGraphPartition(partitionFile);
  readGraphPartition >> numVertices;
  partition = new T[numVertices];
  for (T i = 0; i < numVertices; i++)
  {
    T vertex;
    readGraphPartition >> vertex;
    partition[i] = vertex;
  }
  readGraphPartition.close();
}

std::string getFileName(std::string data)
{
    std::vector<std::string> strings;
    std::istringstream f(data);
    std::string s;
    char sep = '/';
    while (getline(f, s, sep))
    {
        strings.emplace_back(s);
    }
    return strings[strings.size() - 1];
}

inline off_t fsize(const char *filename)
{
  struct stat st;
  if (stat(filename, &st) == 0)
  {
    return st.st_size;
  }
  return -1;
}

template void readGraph<int32_t>(std::string filePath,
                                 int32_t *&offset, int32_t *&index, int32_t &numVertices, int32_t &numEdges);

template void readGraph<int64_t>(std::string filePath,
                                 int64_t *&offset, int64_t *&index, int64_t &numVertices, int64_t &numEdges);

template void readBinGraph<int32_t>(std::string filePath,
                                    int32_t *&offset, int32_t *&index, int32_t &numVertices, int32_t &numEdges);

template void readBinGraph<int64_t>(std::string filePath,
                                    int64_t *&offset, int64_t *&index, int64_t &numVertices, int64_t &numEdges);

template void readPartition<int32_t>(std::string filePath,
                                     int32_t partitionCount, int32_t *&partition, int32_t &numVertices);

template void readPartition<int64_t>(std::string filePath,
                                     int64_t partitionCount, int64_t *&partition, int64_t &numVertices);

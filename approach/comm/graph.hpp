// Graph format:
// Simplified json format:
// src degree dest0 dest1 ...

//#include "graph.h"
#include "comm.h"
#include "wtime.h"
#include <fstream>
#include <omp.h>

#define FILE_NOT_EXIST 1
#define FILE_EXIST 0

#define CPU_id GPU_NUM
using namespace std;

graph::graph(
	string jsonfile) //,
{
	string s_begin = jsonfile + "/begin.bin";
	string s_source = jsonfile + "/source.bin";
	string s_adj = jsonfile + "/adjacent.bin";

	char *begin_file = const_cast<char *>(s_begin.c_str());
	char *source_file = const_cast<char *>(s_source.c_str());
	char *adj_file = const_cast<char *>(s_adj.c_str());

	vertex_count = fsize(begin_file) / sizeof(index_t) - 1;
	edge_count = fsize(adj_file) / sizeof(vertex_t);

	FILE *pFile = fopen(source_file, "rb");
	source_list = (vertex_t *)malloc(fsize(source_file));
	fread(source_list, sizeof(vertex_t), edge_count, pFile);
	fclose(pFile);

	FILE *pFile1 = fopen(adj_file, "rb");
	adj_list = (vertex_t *)malloc(fsize(adj_file));
	fread(adj_list, sizeof(vertex_t), edge_count, pFile1);
	fclose(pFile1);

	FILE *pFile3 = fopen(begin_file, "rb");
	beg_pos = (index_t *)malloc(fsize(begin_file));
	fread(beg_pos, sizeof(index_t), vertex_count + 1, pFile3);
	fclose(pFile3);
}
graph::~graph()
{
	free(source_list);
	free(adj_list);
	free(beg_pos);
}


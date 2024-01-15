#ifndef GRAPH_H
#define GRAPH_H

#include <fstream>
#include <string>
#include <iostream>
#include <sstream>
#include <queue>
#include "comm.h"

class graph
{

	// variable
public:
	vertex_t vertex_count;
	vertex_t edge_count;
	vertex_t max_degree;
	vertex_t *source_list;
	vertex_t *adj_list;
	vertex_t *head_list;
	vertex_t *edge_list;
	index_t *beg_pos;
	// after sort
	//	vertex_t	*upperAdj;
	//	vertex_t	*upperHead;
	// constructor
public:
	graph(){};
	graph(std::string filename); //,
	~graph();
};

#include "graph.hpp"
#endif

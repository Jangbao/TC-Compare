CXX=g++
CXXFLAGS=-O3 -std=c++14 -fopenmp -Iinclude
NVCC= nvcc
# NVCC= nvcc -g -G
# NVCCFLAGS=-gencode=arch=compute_61,code=sm_61 -O2 -std=c++14 -Iinclude -rdc=true 
NVCCFLAGS= -O3 -std=c++14 -Iinclude -rdc=true 
OPENMP = -Xcompiler -fopenmp

all : tricore

tricore : main.o tricount_gpu.o log.o gpu.o
	$(CXX) $(CXXFLAGS) -o tricore main.o tricount_gpu.o log.o gpu.o -L /usr/local/cuda-11.3/lib64 -lcudart -lcudadevrt 

main.o : src/main.cpp
	$(CXX) $(CXXFLAGS) -c src/main.cpp -o main.o   

tricount_gpu.o : src/tricount_gpu.cu
	$(NVCC) $(NVCCFLAGS)   -dc src/tricount_gpu.cu -o tricount_gpu.o

gpu.o : tricount_gpu.o
	$(NVCC) $(NVCCFLAGS)  -dlink tricount_gpu.o -o gpu.o -lcudadevrt  
log.o : src/log.cpp
	$(CXX) $(CXXFLAGS) -c src/log.cpp -o log.o

.PHONY : clean
clean :
	rm tricore *.o


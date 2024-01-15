exe=hindex
N=1
cucc=  nvcc
cc= "$(shell which mpicxx)"
commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64
# cuflags= -g -G  -maxrregcount=32 --compiler-options -v -Xcudafe  -\# --resource-usage 
cuflags=  --compiler-options -v -Xcudafe  -\# --resource-usage 

objs	= $(patsubst %.cu,%.o,$(wildcard *.cu)) \
	$(patsubst %.cpp,%.o,$(wildcard *.cpp))

deps	= $(wildcard ./*.cuh) \
	$(wildcard ./*.hpp) \
	$(wildcard ./*.h) \


%.o:%.cu $(deps)
	$(cucc) -c $(cuflags) $< -o $@

%.o:%.cpp $(deps)
	$(cucc) -c  $< -o $@

$(exe):$(objs)
	$(cucc) $(objs) $(commflags) -o $(exe)


test:$(exe)
	@#mpirun -n $(N) cuda-memcheck $(exe) /gpfs/alpine/proj-shared/csc289/trianglecounting/snap/p2p-Gnutella08_adj/ $(N) 32 1 32 0 0
	mpirun -n $(N) $(exe) data/p2p08/input $(N) 128 1280 32 0 0 
	@#mpirun -n $(N) $(exe) /gpfs/alpine/proj-shared/csc289/trianglecounting/snap/email-EuAll_adj/ $(N) 32 1 32 0 0


clean:
	rm -rf *.o ${exe}

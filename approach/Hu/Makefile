
# NVCC = nvcc  -g -G  -lcudadevrt -rdc=true -O3 #-g -G --ptxas-options=-v
NVCC = nvcc  -lcudadevrt -rdc=true -O3 #-g -G --ptxas-options=-v
# NVCC = nvcc -arch=sm_35 -lcudadevrt -rdc=true -O3 #-g -G --ptxas-options=-v
# CFLAGS = -c -Wall -O6 -g
CFLAGS = -c -Wall -O6 
EXEFLAG = -O6
OPENMP = -Xcompiler -fopenmp

library = -lcudadevrt

hu: tc.cu preTC.cu 
	$(NVCC) -o hu tc.cu $(OPENMP)
.PHONY : clean
clean:
	rm hu

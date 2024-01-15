
NVCC = nvcc   -lcudadevrt -rdc=true -O3 #--ptxas-options=-v
# NVCC = nvcc   -lcudadevrt -rdc=true -O3 -g -G #--ptxas-options=-v
CFLAGS = -c -Wall -O6
# CFLAGS = -c -Wall -O6 -g
EXEFLAG = -O6
OPENMP = -Xcompiler -fopenmp

library = -lcudadevrt

bisson: tc.cu preTC.cu 
	$(NVCC) -o bisson tc.cu $(OPENMP)
.PHONY : clean
clean:
	rm bisson

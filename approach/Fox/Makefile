
NVCC = nvcc -O3 -lcudadevrt -rdc=true #-g # -G # --ptxas-options=-v
CFLAGS = -c -Wall -O6 
EXEFLAG = -O6
OPENMP = -Xcompiler -fopenmp

library = -lcudadevrt

fox: tc.cu preTC.cu 
	$(NVCC) -o fox tc.cu $(OPENMP)
.PHONY : clean
clean:
	rm fox

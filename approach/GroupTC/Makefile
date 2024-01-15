# NVCC = nvcc -g -G -O3  --maxrregcount=32  #-g -G --ptxas-options=-v
NVCC = nvcc -O3 #-g -G --ptxas-options=-v
# CFLAGS = -c -Wall -O6 -g
CFLAGS = -c -Wall -O6 
EXEFLAG = -O6
# OPENMP = -Xcompiler -fopenmp

grouptc: tc.cu    
	$(NVCC) -o grouptc tc.cu   
.PHONY : clean
clean:
	rm grouptc





./../omp-csr/omp-csr -R -s $1 -e $2

cd /home/LiJB/cuda_project/TC-forward/data_convert_util/G500/
g++ G5002CSR.cpp -o G5002CSR
./G5002CSR /home/LiJB/cuda_project/graph500-2.1.4/data/edges.bin /home/LiJB/cuda_project/graph500-2.1.4/data/ 
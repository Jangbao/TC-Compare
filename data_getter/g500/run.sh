export G500_PATH=$(pwd)/cache.bin
cd graph500-2.1.4
make
cd ..

cp ./graph500-2.1.4/seq-csr/seq-csr seq-csr
chmod +x seq-csr 


./seq-csr  xxx/edges.bin  -R  -s 17  -e 2 
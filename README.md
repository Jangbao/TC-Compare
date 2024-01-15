# TC-Compare
This repository contains 9 triangle counting algorithms, 8 of which are derived from previous work, and a new triangle counting algorithm GroupTC proposed by us.

Fortunately, 8 previous works have provided source code. The following is their original repository address. Bisson, Fox, Hu, and tricore from Lin Hu's previous work [accelerating-TC](https://github.com/pkumod/accelerating-TC/), H-INDEX and TRUST from Santosh Pandey's work [H-INDEX_Triangle_Counting](https://github.com/concept-inversion/H-INDEX_Triangle_Counting) and [TRUST](https://github.com/wzbxpy/TRUST/). Green comes from [GpuTriangleCounting](https://github.com/ogreen/GpuTriangleCounting), and polak comes from [triangles](https://github.com/adampolak/triangles). We organized and tested based on these codes. Finally, we proposed GroupTC, which showed good performance on all the datasets we tested. More details about the algorithm and testing can be found in the paper.


All algorithms are placed in the **approach** folder and they can be made by their Makefile.

Taking the Com-Dblp dataset as an example, the algorithm can be run using the following command (xxx needs to be replaced with the corresponding path).

```shell
./bisson  -f  xxx/TC-Compare/data/hu_dataset/Com-Dblp/edges.bin  1 1  100
./fox  -f  xxx/TC-Compare/data/hu_dataset/Com-Dblp/edges.bin  0   1  100
./green xxx/TC-Compare/data/dcsr_dataset/Com-Dblp/  1   100   512  32
./grouptc  xxx/TC-Compare/data/rid_dcsr_dataset/Com-Dblp/   1  100 
./hindex  xxx/TC-Compare/data/dcsr_dataset/Com-Dblp/  1  1024 1024 32 0 0 1 100
./hu -f  xxx/TC-Compare/data/hu_dataset/Com-Dblp/edges.bin  1  100 
./polak  xxx/TC-Compare/data/polak_dataset/Com-Dblp/edges.bin   1  100
./tricore  -f  xxx/TC-Compare/data/hu_dataset/Com-Dblp/edges.bin  1  100
./trust xxx/TC-Compare/data/trust_dataset/Com-Dblp/  1  100
```

The **data** folder stores all datasets, the **data_getter** folder is used to obtain datasets, and the **preprocessing** folder contains some tools for data preprocessing.
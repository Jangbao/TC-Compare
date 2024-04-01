# TC-Compare

## Overview
This is the source code of "A Comparative Study of Intersection-Based Triangle Counting Algorithms on GPUs" (IPDPS 2024), by Jiangbo Li, Prof. Zichen Xu, Minh Pham, Prof. Yicheng Tu, and Qihe Zhou.

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

## How to reproduce our work

1. The first step is to obtain the dataset. Some datasets can be obtained through data_getter. The dataset consists of two parts, [SNAP](https://snap.stanford.edu/data/) natural dataset and [graph 500](https://github.com/graph500/graph500) synthetic dataset. Our experiments mainly use the SNAP dataset, and the shell scripts for downloading the corresponding datasets have been written, so it is very easy to use them!

2. The second step is to convert the SNAP dataset into CSR format. SNAP datasets cannot be used directly, they need to be converted into the corresponding CSR format. CSR is the standard format we use to calculate triangle counts, and in the process of SNAP to CSR we remove some vertices without neighbors, duplicate edges, etc.

3. The third step is to convert the CSR format into a format that can be used by the corresponding algorithm. Many algorithms (such as polak, TRUST, GroupTC) use additional techniques, so the CSR needs to be converted into a format usable by these algorithms. For the correspondence between the dataset format and the algorithm, see shell in Overview.

4. Finally, run the algorithm. After completing the above steps, you can execute the **make** command in the corresponding algorithm directory, and then use the shell in Overview to run the corresponding algorithm. If you get results similar to the ones below, congratulations! Additionally, the profiler results can be obtained using nvprof.

    ```
    dataset  xxx/TC-compare-V100/data/rid_dcsr_dataset/Com-Dblp/
    Number of nodes: 317080, number of edges: 1049866
    iter 100, avg kernel use 0.000148 s
    triangle count 2224385
    ```

**NOTE:**

1. All hardware and software configurations are explained in the paper. The same configuration is more likely to get the same results as ours.

2. Data format conversion is included in **preprocessing** and is named xxx2xxx.cpp/xxx2xxx.cu (for example, SNAP2CSR.cpp).


Thank you for your interest in **IPDPS** and our work. If you have any questions, please contact us!
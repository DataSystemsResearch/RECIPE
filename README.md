## RECIPE : Converting Concurrent DRAM Indexes to Persistent-Memory Indexes (SOSP 2019)

RECIPE proposes a principled approach for converting concurrent indexes built for DRAM into crash-consistent indexes for persistent memory. This repository includes the implementations of the index structures for persistent memory converted from the existing concurrent DRAM indexes by following RECIPE. For performance evaluations, this repository also provides the microbenchmarks for index structures based on YCSB. This repository contains all the information needed to reproduce the main results from our paper.

Please cite the following paper if you use the RECIPE approach or RECIPE-converted indexes: 

**RECIPE : Converting Concurrent DRAM Indexes to Persistent-Memory Indexes**.
Se Kwon Lee, Jayashree Mohan, Sanidhya Kashyap, Taesoo Kim, Vijay Chidambaram. 
*Proceedings of the The 27th ACM Symposium on Operating Systems Principles (SOSP 19)*. 
[Paper PDF](https://www.cs.utexas.edu/~vijay/papers/sosp19-recipe.pdf). [Bibtex](https://www.cs.utexas.edu/~vijay/bibtex/sosp19-recipe.bib).

## Integrating RECIPE indexes into your own project

Apart from benchmark code with `ycsb.cpp`, we provide simple example codes (`P-*/example.cpp` for each RECIPE index) 
to help developers who want to apply RECIPE indexes into their own project to easily identify how to use each index's APIs. 
These example source codes run insert and lookup operations with custom integer keys. For more details of usage for each index, 
please refer to `P-*/README.md` in each index's directory and `ycsb.cpp` as well.

## Contents

1. `P-CLHT/` contains the source code for P-CLHT. It is converted from Cache-Line Hash Table to be persistent. The original source code and paper can be found in [code](https://github.com/LPD-EPFL/CLHT) and [paper](https://dl.acm.org/citation.cfm?id=2694359).
2. `P-HOT/` contains the source code for P-HOT. It is converted from Height Optimized Trie to be persistent. The original source code and paper can be found in [code](https://github.com/speedskater/hot) and [paper](https://dl.acm.org/citation.cfm?id=3196896).
3. `P-BwTree/` contains the source code for P-BwTree. It is converted from an open sourced implementation of BwTree for persistent memory. The original source code and paper can be found in [code](https://github.com/wangziqi2013/BwTree) and [paper](https://dl.acm.org/citation.cfm?id=3196895).
4. `P-ART/` contains the source code for P-ART. It is converted for persistent memory from Adaptive Radix Tree using ROWEX for concurrency. The original source code and paper can be found in [code](https://github.com/flode/ARTSynchronized) and [paper](https://dl.acm.org/citation.cfm?id=2933352).
5. `P-Masstree/` contains the source code for P-Masstree. It is converted from Masstree to be persistent and is custumized for the compact version. The original source code and paper can be found in [code](https://github.com/kohler/masstree-beta) and [paper](https://dl.acm.org/citation.cfm?id=2168855).
6. `index-microbench/` contains the benchmark framework to generate YCSB workloads. The original source code can be found in [code](https://github.com/wangziqi2016/index-microbench).

### Recommended use cases for RECIPE indexes

1. `P-CLHT` is a good fit for applications requiring high-performance point queries.
2. `P-HOT` is a good fit for  applications with read-dominated workloads.
3. `P-BwTree` provides well-balanced performance for insertion, lookup, and range scan operations for applications using integer keys.
4. `P-ART` is suitable for  applications with insertion-dominated workloads and a small number of range queries.
5. `P-Masstree` provides well-balanced performance for insertion, lookup, and range scan operations for applications using either integer or string keys.

## Running RECIPE Indexes on Persistent Memory and DRAM

### Configurations for Persistent Memory 

For running the indexes on Intel Optane DC Persistent Memory, we will use 
[libvmmalloc](http://pmem.io/pmdk/manpages/linux/v1.3/libvmmalloc.3.html) to 
transparently converts all dynamic memory allocations into Persistent Memory 
allocations, mapped by pmem.

#### Ext4-DAX mount
```
$ mkfs.ext4 -b 4096 -E stride=512 -F /dev/pmem0
$ mount -o dax /dev/pmem0 /mnt/pmem
```

#### Install [PMDK](https://github.com/pmem/pmdk) & jemalloc provided in PMDK package
<pre>
<b>Install PMDK</b>
$ git clone https://github.com/pmem/pmdk.git
$ cd pmdk
$ git checkout tags/1.6
$ make -j

<b>Install jemalloc</b>
$ cd src/jemalloc
$ ./autogen.sh
$ ./configure
$ make -j
$ cd ../../../
</pre>

#### Configuration for [libvmmalloc](http://pmem.io/pmdk/manpages/linux/v1.3/libvmmalloc.3.html)
- LD_PRELOAD=path

Specifies a path to libvmmalloc.so.1. The default indicates the path to libvmmalloc.so.1 that is built from the instructions installing PMDK above.

- VMMALLOC_POOR_DIR=path

Specifies a path to the directory where the memory pool file should be created. The directory must exist and be writable.

- VMMALLOC_POOL_SIZE=len

Defines the desired size (in bytes) of the memory pool file.
```
$ vi ./scripts/set_vmmalloc.sh

Please change below configurations to fit for your environment.

export LD_PRELOAD="./pmdk/src/nondebug/libvmmalloc.so.1"
export VMMALLOC_POOL_SIZE=$((64*1024*1024*1024))
export VMMALLOC_POOL_DIR="/mnt/pmem"
```

### Building & Running on Persistent Memory and DRAM

Please check first [Benchmark Details](https://github.com/utsaslab/RECIPE#benchmark-details) section below to make sure the required dependencies.

#### Build P-CLHT

Because CLHT is based on C language, we first make static library and then separately link it to main project source.
```
$ cd ./P-CLHT
$ bash compile.sh lb
$ cd ..
```

#### DRAM environment
Build all
```
$ mkdir build
$ cd build
$ cmake ..
$ make
```
Run
```
$ cd ${project root directory}
$ ./build/ycsb art a randint uniform 4
Usage: ./ycsb [index type] [ycsb workload type] [key distribution] [access pattern] [number of threads]
       1. index type: art hot bwtree masstree clht
                      fastfair levelhash cceh
       2. ycsb workload type: a, b, c, e
       3. key distribution: randint, string
       4. access pattern: uniform, zipfian
       5. number of threads (integer)
```

#### Persistent Memory environment
Build all
<pre>
$ mkdir build
$ cd build
<b>$ cmake -DPMEM_TEST=ON ..</b>
$ make
</pre>
Run
<pre>
$ cd ${project root directory}
<b>$ source ./scripts/set_vmmalloc.sh</b>
$ ./build/ycsb art a randint uniform 4
<b>$ source ./scripts/unset_vmmalloc.sh</b>
</pre>

## Artifact Evaluation

For artifact evaluation, we will evaluate again the performance of the index structures presented in the paper by using YCSB benchmark. The index structures tested for artifact evaluation include `P-CLHT` `P-ART`, `P-HOT`, `P-Masstree`, `P-Bwtree`, `FAST&FAIR`, `WOART`, `CCEH`, and `Level hashing`. The evaluation results will be stored in `./results` directory as csv files. Please make sure to check the contents at least by `checklists` subsection in [Benchmark details](https://github.com/utsaslab/RECIPE#benchmark-details) section below, before beginning artifact evaluation. Note that the evaluations re-generated for artifact evaluation will be based on DRAM because Optane DC persistent memory machine used for the evaluations presented in the paper has the hard access limitation from external users. For more detail, please refer to [experiments.md](https://github.com/utsaslab/RECIPE/blob/master/experiments.md).

**RECIPE** has been awarded three badges: **Artifact Available**, **Artifact Functional**, and **Results Reproduced**.

## Benchmark Details

### Desired system configurations for Artifact Evaluation
- Ubuntu 18.04.1 LTS
- At least 32GB DRAM
- x86-64 CPU supporting at least 16 threads
- x86-64 CPU supporting at least the AVX-2 and BMI-2 instruction sets (Haswell and newer)

### Required compile packages
- cmake
- Compiler: g++-7, gcc-7, c++17

### Dependencies
#### Install build packages
```
$ sudo apt-get install build-essential cmake libboost-all-dev libpapi-dev default-jdk
```
#### Install jemalloc and tbb
```
$ sudo apt-get install libtbb-dev libjemalloc-dev
```

### Checklists
#### Configuration for workload size.
- Change `LOAD_SIZE` and `RUN_SIZE` variables to be same with the generated workload size, which are hard-coded in `ycsb.cpp` (Default is 64000000).
```
$ vi ycsb.cpp
```
#### Configuration for cache line flush instruction.
- Check supported cache line flush instructions. Current default configurations are based on `CLFLUSH` instruction to flush the dirty cache lines. If your CPU ISA supports `CLWB` or `CLFLUSHOPT`, please make sure to change the options in `./CMakeLists.txt` and `./CLHT/Makefile`. There are three options (clflush, clflushopt, clwb).
```
$ lscpu | grep clflush
$ lscpu | grep clflushopt
$ lscpu | grep clwb
```
- Overall
```
$ vi CMakeLists.txt
- add_definitions(-DCLFLUSH) (default configuration)
or
- add_definitions(-DCLFLUSH_OPT)
or
- add_definitions(-DCLWB)
```
- CLHT
```
$ vi CLHT/Makefile
- CFLAGS= -D_GNU_SOURCE -DCLFLUSH (default configuration)
or
- CFLAGS= -D_GNU_SOURCE -DCLFLUSH_OPT
or
- CFLAGS= -D_GNU_SOURCE -DCLWB
```

#### Check if your machine supports AVX-2 and BMI-2.
```
$ lscpu | grep avx2
$ lscpu | grep bmi2
```
AVX-2 and BMI-2 are required to run HOT ([Height Optimized Trie](https://github.com/speedskater/hot)).
If your machine does not provide those primitives, please disable HOT from `CMakeLists.txt`.
You can complete compile and run other index structures, except for HOT.
```
$ vi CMakeLists.txt
set(HOT TRUE) --> set(HOT FALSE)
```

### Generating YCSB workloads
#### Download YCSB source code
```
$ cd ./index-microbench
$ curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.11.0/ycsb-0.11.0.tar.gz
$ tar xfvz ycsb-0.11.0.tar.gz
$ mv ycsb-0.11.0 YCSB
```
#### How to configure and generate workloads
- Configure the options of each workloads (a, b, c, e), would only need to change `$recordcount` and `$operationcount`.
```
$ vi ./index-microbench/workload_spec/<workloada or workloadb or workloadc or workloade>
```
- Select which workloads to be generated. Default configuration will generate all workloads (a, b, c, e). Change the code line `for WORKLOAD_TYPE in <a b c e>; do`, depending on which workload you want to generate.
```
$ vi ./index-microbench/generate_all_workloads.sh
```
- Generate the workloads. This will generate both random integer keys and string ycsb keys with the specified key distribution.
```
$ cd ./index-microbench/
$ mkdir workloads
$ make generate_workload
```

## Limitations
Current implementations are based on general volatile memory allocation API such as `malloc`, `posix_memalign`, `new`, and etc.
Just for performance testing on real PM, you can use [libvmmalloc](http://pmem.io/pmdk/manpages/linux/v1.3/libvmmalloc.3.html), 
which transparently converts all the dynamic memory allocations into Persistent Memory allocations.
However, if you want to apply RECIPE indexes into your real PM application, you would need to change current volatile 
memory allocators using [libpmem](https://pmem.io/pmdk/) APIs.

## License

The licence for most of the P-* family of persistent indexes is Apache License (https://www.apache.org/licenses/LICENSE-2.0). This is consistent with the most of the indexes we build on, with the exception of CLHT and HOT, which uses the MIT and ISC License respectively. Accordingly, P-CLHT is under the MIT license (https://opensource.org/licenses/MIT). P-HOT is under the ISC license (https://opensource.org/licenses/ISC).

Copyright for RECIPE indexes is held by the University of Texas at Austin. Please contact us if you would like to obtain a license to use RECIPE indexes in your commercial product. 

## Acknowledgements

We thank the National Science Foundation, VMware, Google, and Facebook for partially funding this project.

## Contact

Please contact us at `sklee@cs.utexas.edu` and `vijayc@utexas.edu` with any questions.

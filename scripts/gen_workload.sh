#!/bin/bash

source scripts/compile_config.sh

sudo apt-get -y install build-essential cmake libboost-all-dev libpapi-dev
sudo apt-get -y install libtbb-dev libjemalloc-dev

cd ./index-microbench
curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.11.0/ycsb-0.11.0.tar.gz
tar xfvz ycsb-0.11.0.tar.gz
mv ycsb-0.11.0 YCSB
mkdir ./workloads
make generate_workload
cd ..

mkdir ./results

cd ./CLHT
bash compile.sh lb
cd ..
mkdir ./build

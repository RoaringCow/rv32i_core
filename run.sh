#/bin/bash

cd derleyici
make clean
make
cd ..

mkdir build

verilator --binary --trace -Wno-fatal -j  tb/test_tb.v rtl/*.v --top-module test_tb -Mdir tb/build 2>&1

./tb/build/Vtest_tb

#surfer test_tb.vcd

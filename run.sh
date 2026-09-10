#/bin/bash

verilator --binary --trace -Wno-fatal -j  tb/test_tb.v rtl/*.v --top-module test_tb -Mdir tb/build/top 2>&1

./tb/build/top/Vtest_tb

#surfer test_tb.vcd

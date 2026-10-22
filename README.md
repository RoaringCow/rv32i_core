# rv32i_core

A multicycle (not pipelined) RV32I core written in Verilog from scratch.

## Bad Apple demo
This is currently the highlight of the project as i wanted to show what it could do in a real fpga. So here it is playing Bad Apple on an i2c oled display:




https://github.com/user-attachments/assets/8bce3da7-4b10-469b-9576-9e8ff0fb2bd2


Sound is edited in.
The video is only 20 seconds because the BRAM is at %95 usage.
I could have implemented xor delta encoding but there is no need. (it would be around 40s so still not the whole video)


## Supported instructions

The decoder handles all of RV32I, but these aren't implemented yet.

- FENCE
- ECALL
- EBREAK

So basically these run as nop instruction.

## Multicycle state machine
The core has the classic 5 stages and skips the ones an instruction doesn't need:
- Fetch
- Decode
- Execute
- Memory op
- Writeback


I intentionally did not attempt pipelining as i wanted to get a simpler core up and running

## Verification

No proper verification has been done yet, so there may be undiscovered edge cases in a few instructions (possibly the shift instructions).
Nonetheless, I've run a bunch of test C programs with no apparent issues.


# How to Run 

You first have to change the address in `rtl/mem.v` line 28
``` verilog
initial $readmemh("/home/ersan/rv32i_core/derleyici/out.hex", mem);
```
The path is currently set for my own machine.


## Running With Verilator
Make sure you have Verilator and a RISC-V GCC toolchain (e.g. `riscv32-unknown-elf-gcc`) installed.
Bad apple is only set up to run with the fpga so for now running with verilator has no purpose. It just runs C programs and prints out debug data from `test_tb.v`.

**Also the main file currently contains the code to run the oled display. So you might to remove all code except a fresh main function**

```bash
git clone https://github.com/RoaringCow/rv32i_core.git
cd rv32i_core

./run.sh
```

## Running on FPGA (using vivado)
Make sure you have Vivado, ffmpeg, Python 3, and a RISC-V GCC toolchain (e.g. `riscv32-unknown-elf-gcc`) installed.
The project is currently set up to use the included Bad Apple video. The Nexys A7 only has enough memory for 20 seconds at 12 fps, so the frame extraction is configured for that. I haven't put much effort into optimizing storage yet, since I plan to move the video to an SD card.

I tested on vivado 2025.2 version and did not test in any other version.

### Hardware
- FPGA: Nexys A7-100T
- Oled display: one of ssd1306


### Commands to run
```bash
git clone https://github.com/RoaringCow/rv32i_core.git
cd rv32i_core


cd video
mkdir frames
ffmpeg -ss 0 -t 20 -i badapple.mp4 -vf "fps=12,scale=128:64" frames/%03d.png
python3 frames_to_header.py

cd ../derleyici/
make clean
make
cd ..

vivado -mode batch -source vivado/create_project.tcl
```
after these steps:
1) Open the project in vivado
2) Generate bitstream
3) Open Hardware Manager
4) Open Target (connect the fpga of course)
5) program device





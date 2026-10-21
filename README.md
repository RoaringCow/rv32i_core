# rv32i_core

A multicycle (not pipelined) RV32I core written in Verilog from scratch.

## Bad Apple demo
This is currently the highlight of the project as i wanted to show what it could do in a real fpga. So here it is playing Bad Apple on an i2c oled display:


![Bad Apple running on the core](docs/badapple.gif)



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

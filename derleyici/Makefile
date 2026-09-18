CC      = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
CFLAGS  = -march=rv32i -mabi=ilp32 -nostdlib -T link.ld

all: out.hex

out.elf: crt0.S main.c link.ld
	$(CC) $(CFLAGS) -o $@ crt0.S main.c

out.hex: out.elf
	$(OBJCOPY) -O binary $< out.bin
	printf '@00000000\n' > $@
	od -An -tx4 -v out.bin | tr -s ' \t' '\n' | grep -v '^$$' >> $@

clean:
	rm -f out.elf out.bin out.hex

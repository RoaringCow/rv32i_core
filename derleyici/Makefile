CC      = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
OBJDUMP = riscv32-unknown-elf-objdump
CFLAGS  = -march=rv32i -mabi=ilp32 -nostdlib -T link.ld

all: out.hex out.asm

out.elf: crt0.S main.c i2c.c oled_driver/ssd1306.c link.ld
	$(CC) $(CFLAGS) -Ioled_driver -o $@ crt0.S main.c i2c.c oled_driver/ssd1306.c

out.hex: out.elf
	$(OBJCOPY) -O binary $< out.bin
	printf '@00000000\n' > $@
	od -An -tx4 -v out.bin | tr -s ' \t' '\n' | grep -v '^$$' >> $@

out.asm: out.elf
	$(OBJDUMP) -d -M no-aliases $< > $@

clean:
	rm -f out.elf out.bin out.hex out.asm

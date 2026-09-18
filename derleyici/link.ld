OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
	RAM (rwx): ORIGIN = 0x0, LENGTH = 0x4000
}

SECTIONS {
    .text : {
        *(.text.init)
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > RAM

    .data : {
        *(.data .data.*)
    } > RAM

    .bss : {
        __bss_start = .; /* bunu tam anlamadım */
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}

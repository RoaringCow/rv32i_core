	.section .text.init
    .globl _start
_start:
	la sp, _stack_top


	la      a0, __bss_start
    la      a1, __bss_end
bss_loop:
    bgeu    a0, a1, bss_done
    sw      zero, 0(a0)
    addi    a0, a0, 4
    j       bss_loop
bss_done:

    call    main
halt:
    j       halt

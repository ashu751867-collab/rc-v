# P11 program - Binary and one bits
        .text
        .globl p11_main
p11_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)
        call    rcv_read_dec
        mv      s0, a0
        la      a0, p11_str_bin
        call    rcv_puts
        li      s1, 31
        li      s2, 0
p11_loop:
        blt     s1, zero, p11_done
        srl     t0, s0, s1
        andi    t0, t0, 1
        add     s2, s2, t0
        addi    a0, t0, 48
        call    rcv_putc
        addi    s1, s1, -1
        j       p11_loop
p11_done:
        call    rcv_newline
        la      a0, p11_str_ones
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_udec
        call    rcv_newline
        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret
        .rodata
p11_str_bin:
        .asciz  "binary: "
p11_str_ones:
        .asciz  "ones: "
        .align  2

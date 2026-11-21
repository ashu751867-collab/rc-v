        .text
p15_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)

        jal     ra, rcv_read_dec
        mv      s0, a0
        li      s1, 1

p15_loop:
        bgt     s1, s0, p15_end

        mv      a0, s1
        jal     ra, rcv_print_udec
        la      a0, p15_msg
        jal     ra, rcv_puts

        mv      a0, s1
        jal     ra, p15_fact
        jal     ra, rcv_print_udec
        jal     ra, rcv_newline

        addi    s1, s1, 1
        j       p15_loop

p15_end:
        lw      ra, 12(sp)
        lw      s0, 8(sp)
        lw      s1, 4(sp)
        addi    sp, sp, 16
        ret

p15_fact:
        addi    sp, sp, -8
        sw      ra, 4(sp)
        sw      a0, 0(sp)

        li      t0, 1
        bleu    a0, t0, p15_base

        addi    a0, a0, -1
        jal     ra, p15_fact
        lw      a1, 0(sp)
        jal     ra, rcv_umul
        j       p15_ret

p15_base:
        li      a0, 1

p15_ret:
        lw      ra, 4(sp)
        addi    sp, sp, 8
        ret

        .rodata
p15_msg:
        .asciz  "! = "
        .align  2

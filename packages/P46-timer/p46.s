# P46 program - see README.md for the task.
# Rules: start at the label p46_main and finish with ret; every label you
# create starts with p46_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p46_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        jal     ra, rcv_read_dec
        mv      s0, a0

        li      t0, TIMER_CTRL
        sw      zero, 0(t0)
        li      t3, TIMER_COUNT
        sw      zero, 0(t3)

        li      t1, 1
        mv      t2, s0
        li      a0, 0

        sw      t1, 0(t0)
p46_loop:
        add     a0, a0, t2
        addi    t2, t2, -1
        bnez    t2, p46_loop
        sw      zero, 0(t0)

        mv      s1, a0
        lw      s2, 0(t3)

        la      a0, p46_msg_sum
        jal     ra, rcv_puts
        mv      a0, s1
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        la      a0, p46_msg_cycles
        jal     ra, rcv_puts
        mv      a0, s2
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        la      a0, p46_msg_per
        jal     ra, rcv_puts
        mv      a0, s2
        mv      a1, s0
        jal     ra, rcv_udiv
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        lw      ra, 12(sp)
        lw      s0, 8(sp)
        lw      s1, 4(sp)
        lw      s2, 0(sp)
        addi    sp, sp, 16
        ret

        .rodata
p46_msg_sum:
        .asciz  "sum = "
p46_msg_cycles:
        .asciz  "cycles = "
p46_msg_per:
        .asciz  "per iteration = "
        .align  2

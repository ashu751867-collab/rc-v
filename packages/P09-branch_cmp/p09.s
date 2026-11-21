# P09 program - Maximum and minimum until 0.
# Rules: start at the label p09_main and finish with ret; every label you
# create starts with p09_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p09_main:
        addi    sp, sp, -12
        sw      ra, 8(sp)
        sw      s0, 4(sp)
        sw      s1, 0(sp)

        call    rcv_read_dec        # read first number into a0
        beq     a0, zero, p09_empty

        mv      s0, a0              # s0 = current max
        mv      s1, a0              # s1 = current min

p09_loop:
        call    rcv_read_dec        # read next number into a0
        beq     a0, zero, p09_done  # stop if 0

        bge     s0, a0, p09_chk_min # if s0 >= a0, skip max update
        mv      s0, a0              # s0 = a0 (new max)

p09_chk_min:
        ble     s1, a0, p09_loop    # if s1 <= a0, skip min update
        mv      s1, a0              # s1 = a0 (new min)
        j       p09_loop

p09_done:
        la      a0, p09_max_lbl
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_dec
        call    rcv_newline

        la      a0, p09_min_lbl
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_dec
        call    rcv_newline
        j       p09_exit

p09_empty:
        la      a0, p09_no_num
        call    rcv_puts

p09_exit:
        lw      s1, 0(sp)
        lw      s0, 4(sp)
        lw      ra, 8(sp)
        addi    sp, sp, 12
        ret

        .rodata
p09_max_lbl:
        .asciz  "max = "
p09_min_lbl:
        .asciz  "min = "
p09_no_num:
        .asciz  "no numbers\n"
        .align  2

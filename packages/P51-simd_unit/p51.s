# P51 program - Brighten pixels with SIMD
# Rules: start at the label p51_main and finish with ret; every label you
# create starts with p51_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p51_main:
        addi    sp, sp, -48
        sw      ra, 44(sp)
        sw      s0, 40(sp)
        sw      s1, 36(sp)
        sw      s2, 32(sp)
        sw      s3, 28(sp)
        sw      s4, 24(sp)
        sw      s5, 20(sp)
        sw      s6, 16(sp)
        sw      s7, 12(sp)
        sw      s8, 8(sp)
        sw      s9, 4(sp)

        # Read first 4 pixels and pack into s1 (w0)
        li      s9, 0
        li      s1, 0
p51_read_w0:
        call    rcv_read_dec
        andi    a0, a0, 0xFF
        sll     a0, a0, s9
        or      s1, s1, a0
        addi    s9, s9, 8
        li      t0, 32
        blt     s9, t0, p51_read_w0

        # Read next 4 pixels and pack into s2 (w1)
        li      s9, 0
        li      s2, 0
p51_read_w1:
        call    rcv_read_dec
        andi    a0, a0, 0xFF
        sll     a0, a0, s9
        or      s2, s2, a0
        addi    s9, s9, 8
        li      t0, 32
        blt     s9, t0, p51_read_w1

        # Read brightness b and pack into all 4 lanes in s3
        call    rcv_read_dec
        andi    a0, a0, 0xFF
        slli    t0, a0, 8
        or      t0, t0, a0
        slli    t1, t0, 16
        or      s3, t0, t1

        # Read threshold t and pack into all 4 lanes in s4
        call    rcv_read_dec
        andi    a0, a0, 0xFF
        slli    t0, a0, 8
        or      t0, t0, a0
        slli    t1, t0, 16
        or      s4, t0, t1

        # SIMD accelerator slot 9 registers:
        # Base: 0x00020240
        # +0: SIMD_A, +4: SIMD_B, +8: SIMD_SUM, +12: SIMD_MAX, +16: SIMD_SUB
        li      s0, 0x00020240

        # Word 0: add brightness, then apply threshold max
        sw      s1, 0(s0)       # SIMD_A = pixels
        sw      s3, 4(s0)       # SIMD_B = b
        lw      s5, 8(s0)       # s5 = SIMD_SUM
        sw      s5, 0(s0)       # SIMD_A = sum
        sw      s4, 4(s0)       # SIMD_B = t
        lw      s7, 12(s0)      # s7 = SIMD_MAX

        # Word 1: add brightness, then apply threshold max
        sw      s2, 0(s0)       # SIMD_A = pixels
        sw      s3, 4(s0)       # SIMD_B = b
        lw      s6, 8(s0)       # s6 = SIMD_SUM
        sw      s6, 0(s0)       # SIMD_A = sum
        sw      s4, 4(s0)       # SIMD_B = t
        lw      s8, 12(s0)      # s8 = SIMD_MAX

        # Print "sum:" followed by 8 values
        la      a0, p51_str_sum
        call    rcv_puts

        mv      s9, s5
        li      s1, 4
p51_print_sum_w0:
        li      a0, ' '
        call    rcv_putc
        andi    a0, s9, 0xFF
        call    rcv_print_dec
        srli    s9, s9, 8
        addi    s1, s1, -1
        bnez    s1, p51_print_sum_w0

        mv      s9, s6
        li      s1, 4
p51_print_sum_w1:
        li      a0, ' '
        call    rcv_putc
        andi    a0, s9, 0xFF
        call    rcv_print_dec
        srli    s9, s9, 8
        addi    s1, s1, -1
        bnez    s1, p51_print_sum_w1

        call    rcv_newline

        # Print "max:" followed by 8 values
        la      a0, p51_str_max
        call    rcv_puts

        mv      s9, s7
        li      s1, 4
p51_print_max_w0:
        li      a0, ' '
        call    rcv_putc
        andi    a0, s9, 0xFF
        call    rcv_print_dec
        srli    s9, s9, 8
        addi    s1, s1, -1
        bnez    s1, p51_print_max_w0

        mv      s9, s8
        li      s1, 4
p51_print_max_w1:
        li      a0, ' '
        call    rcv_putc
        andi    a0, s9, 0xFF
        call    rcv_print_dec
        srli    s9, s9, 8
        addi    s1, s1, -1
        bnez    s1, p51_print_max_w1

        call    rcv_newline

        # Restore callee-saved registers and return
        lw      s9, 4(sp)
        lw      s8, 8(sp)
        lw      s7, 12(sp)
        lw      s6, 16(sp)
        lw      s5, 20(sp)
        lw      s4, 24(sp)
        lw      s3, 28(sp)
        lw      s2, 32(sp)
        lw      s1, 36(sp)
        lw      s0, 40(sp)
        lw      ra, 44(sp)
        addi    sp, sp, 48
        ret

        .rodata
p51_str_sum:
        .asciz  "sum:"
        .align  2
p51_str_max:
        .asciz  "max:"
        .align  2

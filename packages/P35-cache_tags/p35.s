# P35 program - sum an array twice
# Read k, fill a[i] = k + i (i = 0..31), print "sum 1: <s>" and "sum 2: <s>".

        .text
p35_main:
        addi    sp, sp, -20
        sw      ra, 16(sp)
        sw      s0, 12(sp)
        sw      s1, 8(sp)
        sw      s2, 4(sp)
        sw      s3, 0(sp)

        call    rcv_read_dec            # a0 = k
        mv      s0, a0
        la      s1, p35_arr             # s1 = array base
        li      s2, 0                   # i
        li      s3, 32                  # N

p35_fill:
        add     t0, s0, s2              # k + i
        slli    t1, s2, 2
        add     t1, s1, t1
        sw      t0, 0(t1)
        addi    s2, s2, 1
        blt     s2, s3, p35_fill

        # pass 1
        la      a0, p35_m1
        call    rcv_puts
        call    p35_sum
        call    rcv_print_dec
        call    rcv_newline

        # pass 2 (same addresses again -> cache hits)
        la      a0, p35_m2
        call    rcv_puts
        call    p35_sum
        call    rcv_print_dec
        call    rcv_newline

        lw      s3, 0(sp)
        lw      s2, 4(sp)
        lw      s1, 8(sp)
        lw      s0, 12(sp)
        lw      ra, 16(sp)
        addi    sp, sp, 20
        ret

# p35_sum: sums the 32 words at s1, result in a0 (leaf, uses only t regs)
p35_sum:
        li      t0, 0                   # sum
        li      t1, 0                   # i
        li      t2, 32
        mv      t3, s1
p35_loop:
        lw      t4, 0(t3)
        add     t0, t0, t4
        addi    t3, t3, 4
        addi    t1, t1, 1
        blt     t1, t2, p35_loop
        mv      a0, t0
        ret

        .data
        .align  2
p35_arr:
        .space  128

        .rodata
p35_m1:
        .asciz  "sum 1: "
p35_m2:
        .asciz  "sum 2: "
        .align  2

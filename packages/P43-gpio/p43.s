# P43 program: Knight Rider LEDs
# Reads N, moves one lit LED across the 16 LEDs for N steps,
# prints each LED value in binary, then prints the buttons in hex.

        .text
p43_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s1, 24(sp)
        sw      s2, 20(sp)
        sw      s3, 16(sp)
        sw      s4, 12(sp)
        sw      s5, 8(sp)

        jal     ra, rcv_read_dec
        mv      s1, a0
        li      s2, 0
        li      s3, 1

p43_step:
        beqz    s1, p43_buttons

        li      t0, 1
        sll     t0, t0, s2
        li      t1, GPIO_LEDS
        sw      t0, 0(t1)
        lw      s4, 0(t1)

        li      s5, 15
p43_bit:
        srl     t2, s4, s5
        andi    t2, t2, 1
        addi    a0, t2, 48
        jal     ra, rcv_putc
        addi    s5, s5, -1
        bgez    s5, p43_bit

        jal     ra, rcv_newline

        add     s2, s2, s3
        li      t3, 15
        bne     s2, t3, p43_not_top
        li      s3, -1
p43_not_top:
        bnez    s2, p43_not_bottom
        li      s3, 1
p43_not_bottom:
        addi    s1, s1, -1
        j       p43_step

p43_buttons:
        li      a0, 98
        jal     ra, rcv_putc
        li      a0, 117
        jal     ra, rcv_putc
        li      a0, 116
        jal     ra, rcv_putc
        li      a0, 116
        jal     ra, rcv_putc
        li      a0, 111
        jal     ra, rcv_putc
        li      a0, 110
        jal     ra, rcv_putc
        li      a0, 115
        jal     ra, rcv_putc
        li      a0, 58
        jal     ra, rcv_putc
        li      a0, 32
        jal     ra, rcv_putc

        li      t0, GPIO_BUTTONS
        lw      a0, 0(t0)
        jal     ra, rcv_print_hex
        jal     ra, rcv_newline

        lw      ra, 28(sp)
        lw      s1, 24(sp)
        lw      s2, 20(sp)
        lw      s3, 16(sp)
        lw      s4, 12(sp)
        lw      s5, 8(sp)
        addi    sp, sp, 32
        ret

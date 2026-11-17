# P53 program - Watchdog
# Reads K (1..9) and W, arms the watchdog (LOAD = 1000), then for each chunk
# runs W empty-loop iterations, reports whether the dog bit, clears the bite
# flag and kicks. Finally it stops kicking, waits for the bite, disables the
# watchdog and prints "watchdog bit".
#
# Slot 11 registers at 0x000202C0:  +0 LOAD  +4 CTRL  +8 STATUS  +12 COUNT  +16 KICK

        .text
        .globl  p53_main
p53_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s1, 24(sp)          # K
        sw      s2, 20(sp)          # W
        sw      s3, 16(sp)          # watchdog base address
        sw      s4, 12(sp)          # chunk number k
        sw      s5, 8(sp)           # bite bit of the current chunk

        jal     ra, rcv_read_dec    # K
        mv      s1, a0
        jal     ra, rcv_read_dec    # W
        mv      s2, a0

        li      s3, 0x000202C0
        li      t0, 1000
        sw      t0, 0(s3)           # WDT_LOAD = 1000
        sw      zero, 8(s3)         # WDT_STATUS: clear
        li      t0, 1
        sw      t0, 4(s3)           # WDT_CTRL = 1 (enable)

        li      s4, 1
p53_chunk:
        bgt     s4, s1, p53_wait    # all K chunks done
        mv      t0, s2
p53_work:
        addi    t0, t0, -1          # W iterations of an empty counting loop
        bgtz    t0, p53_work

        lw      s5, 8(s3)           # read STATUS
        andi    s5, s5, 1           # bite bit
        sw      zero, 8(s3)         # clear bite
        sw      zero, 16(s3)        # kick

        la      a0, p53_s_chunk
        jal     ra, rcv_puts
        addi    a0, s4, 48          # '0' + k  (k is 1..9)
        jal     ra, rcv_putc
        bnez    s5, p53_bitten
        la      a0, p53_s_ok
        j       p53_print
p53_bitten:
        la      a0, p53_s_bitten
p53_print:
        jal     ra, rcv_puts
        jal     ra, rcv_newline
        addi    s4, s4, 1
        j       p53_chunk

p53_wait:                           # stop kicking: wait for the bite
        lw      t0, 8(s3)
        andi    t0, t0, 1
        beqz    t0, p53_wait
        sw      zero, 4(s3)         # WDT_CTRL = 0
        sw      zero, 8(s3)         # clear STATUS
        la      a0, p53_s_wd
        jal     ra, rcv_puts
        jal     ra, rcv_newline

        lw      ra, 28(sp)
        lw      s1, 24(sp)
        lw      s2, 20(sp)
        lw      s3, 16(sp)
        lw      s4, 12(sp)
        lw      s5, 8(sp)
        addi    sp, sp, 32
        ret

        .rodata
p53_s_chunk:
        .asciz  "chunk "
p53_s_ok:
        .asciz  ": ok"
p53_s_bitten:
        .asciz  ": bitten"
p53_s_wd:
        .asciz  "watchdog bit"
        .align  2

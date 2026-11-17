# P34 - Copy a string word by word, then print the copy and the word count.
# Stack frame: buffer 1 at 0(sp), buffer 2 at 64(sp), saved ra and s0 above them.

        .equ    p34_BUF2,  64
        .equ    p34_RA,    128
        .equ    p34_S0,    132
        .equ    p34_FRAME, 144

        .text
p34_main:
        addi    sp, sp, -p34_FRAME
        sw      ra, p34_RA(sp)
        sw      s0, p34_S0(sp)

        # Read a line into buffer 1; a0 = length
        addi    a0, sp, 0
        addi    a1, zero, p34_BUF2      # buffer size = 64
        jal     ra, rcv_read_line

        # words = length / 4 + 1 (the +1 covers the word with the terminating 0)
        srli    s0, a0, 2
        addi    s0, s0, 1

        # Copy buffer 1 to buffer 2, one whole word per loop
        addi    t0, sp, 0
        addi    t1, sp, p34_BUF2
        addi    t2, s0, 0
p34_copy:
        lw      t3, 0(t0)
        sw      t3, 0(t1)
        addi    t0, t0, 4
        addi    t1, t1, 4
        addi    t2, t2, -1
        bne     t2, zero, p34_copy

        # Print "copy: <text from buffer 2>"
        la      a0, p34_msg_copy
        jal     ra, rcv_puts
        addi    a0, sp, p34_BUF2
        jal     ra, rcv_puts
        jal     ra, rcv_newline

        # Print "words: <n>"
        la      a0, p34_msg_words
        jal     ra, rcv_puts
        addi    a0, s0, 0
        jal     ra, rcv_print_dec
        jal     ra, rcv_newline

        lw      s0, p34_S0(sp)
        lw      ra, p34_RA(sp)
        addi    sp, sp, p34_FRAME
        ret

        .rodata
p34_msg_copy:
        .asciz  "copy: "
p34_msg_words:
        .asciz  "words: "
        .align  2

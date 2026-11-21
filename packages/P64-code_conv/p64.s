# P64 program: Binary, Gray and excess-3 table
#
# Rules: start at label p64_main and finish with ret; every label you create
# starts with p64_ ; save ra and any s registers used on the stack (16-byte aligned).

        .text
        .globl  p64_main

p64_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)

        # Print header: " n bin  gray xs3\n"
        la      a0, p64_str_hdr
        call    rcv_puts

        # Loop n = 0..15
        li      s0, 0               # s0 = n
        li      s1, 16              # limit = 16
        li      s2, 0x00020580      # s2 = CODECONV base address

p64_loop:
        # 1. Print n right-aligned in 2 characters
        li      t0, 10
        bge     s0, t0, p64_n_two_digits
        li      a0, ' '
        call    rcv_putc
        addi    a0, s0, '0'
        call    rcv_putc
        j       p64_after_n

p64_n_two_digits:
        li      a0, '1'
        call    rcv_putc
        addi    a0, s0, -10
        addi    a0, a0, '0'
        call    rcv_putc

p64_after_n:
        # Space
        li      a0, ' '
        call    rcv_putc

        # 2. Print n as 4 binary digits
        mv      a0, s0
        li      a1, 4
        call    p64_print_bin

        # Space
        li      a0, ' '
        call    rcv_putc

        # 3. Write n to CODECONV_VAL, read CODECONV_GRAY, print as 4 binary digits
        sw      s0, 0(s2)           # write n to VAL (offset 0)
        lw      s3, 4(s2)           # read GRAY (offset 4)
        mv      a0, s3
        li      a1, 4
        call    p64_print_bin

        # Space
        li      a0, ' '
        call    rcv_putc

        # 4. Read CODECONV_XS3, print as 8 binary digits
        lw      s3, 12(s2)          # read XS3 (offset 12 = 0x0C)
        mv      a0, s3
        li      a1, 8
        call    p64_print_bin

        # Newline
        call    rcv_newline

        addi    s0, s0, 1
        blt     s0, s1, p64_loop

        # Read number v (0..65535)
        call    rcv_read_dec
        mv      s0, a0              # s0 = v

        # Write v to CODECONV_VAL
        sw      s0, 0(s2)

        # Read GRAY and print "gray: <8 hex digits>\n"
        lw      s1, 4(s2)           # s1 = gray
        la      a0, p64_str_gray
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex
        call    rcv_newline

        # Read XS3 and print "xs3: <8 hex digits>\n"
        lw      s3, 12(s2)          # s3 = xs3
        la      a0, p64_str_xs3
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_hex
        call    rcv_newline

        # Write gray code to VAL, then read FROMGRAY
        sw      s1, 0(s2)
        lw      s3, 8(s2)           # read FROMGRAY (offset 8)

        # Print "back: <decimal>\n"
        la      a0, p64_str_back
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_dec
        call    rcv_newline

        # Epilogue
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret

# Helper: print lower a1 bits of a0 in binary ('0' or '1') from MSB to LSB
p64_print_bin:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        mv      s0, a0              # s0 = value
        addi    s1, a1, -1          # s1 = shift bit index

p64_pb_loop:
        srl     t0, s0, s1
        andi    t0, t0, 1
        addi    a0, t0, '0'
        call    rcv_putc
        addi    s1, s1, -1
        bgez    s1, p64_pb_loop

        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
        .align  2
p64_str_hdr:
        .asciz  " n bin  gray xs3\n"
p64_str_gray:
        .asciz  "gray: "
p64_str_xs3:
        .asciz  "xs3: "
p64_str_back:
        .asciz  "back: "
        .balign 4

# P18 program: Sign-extension explorer
#
# Rules: start at p18_main and finish with ret; every label starts with p18_;
# save ra and any used s-registers (s0, s1) on the stack and restore before ret.

        .text
p18_main:
        addi    sp, sp, -16             # allocate 16-byte stack frame
        sw      ra, 12(sp)              # save return address
        sw      s0, 8(sp)               # save s0 (holds 12-bit input / byte addr)
        sw      s1, 4(sp)               # save s1 (holds extended value)

        # 1. Read a 12-bit hex value (000..FFF)
        call    rcv_read_hex
        mv      s0, a0                  # s0 = raw 12-bit value

        # 2. Sign-extend bit 11 to 32 bits using slli 20 + srai 20
        slli    s1, s0, 20              # shift bit 11 into sign bit (bit 31)
        srai    s1, s1, 20              # arithmetic right shift replicates sign bit

        la      a0, p18_str_sign
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex           # print 8 uppercase hex digits
        la      a0, p18_str_lparen
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_dec           # print signed decimal
        la      a0, p18_str_rparen
        call    rcv_puts

        # 3. Zero-extend 12-bit value to 32 bits using slli 20 + srli 20
        slli    s1, s0, 20              # discard any bits above bit 11
        srli    s1, s1, 20              # logical right shift fills upper bits with 0

        la      a0, p18_str_zero
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex
        la      a0, p18_str_lparen
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_dec
        la      a0, p18_str_rparen
        call    rcv_puts

        # 4. Read a decimal byte (0..255) and store it into RAM using sb
        call    rcv_read_dec
        la      s0, p18_byte_slot       # s0 = address of allocated byte in RAM
        sb      a0, 0(s0)               # store low 8 bits

        # 5. Load byte back sign-extended (lb) and print "lb:  <dec>"
        la      a0, p18_str_lb
        call    rcv_puts
        lb      a0, 0(s0)               # sign-extend bit 7 to 32 bits
        call    rcv_print_dec
        call    rcv_newline

        # 6. Load byte back zero-extended (lbu) and print "lbu: <dec>"
        la      a0, p18_str_lbu
        call    rcv_puts
        lbu     a0, 0(s0)               # zero-extend byte to 32 bits
        call    rcv_print_dec
        call    rcv_newline

        # Restore saved registers and stack pointer, then return
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .data
p18_byte_slot:
        .byte   0                       # 1-byte RAM slot for sb/lb/lbu test
        .align  2

        .rodata
p18_str_sign:
        .asciz  "sign-extended: "
p18_str_zero:
        .asciz  "zero-extended: "
p18_str_lparen:
        .asciz  " ("
p18_str_rparen:
        .asciz  ")\n"
p18_str_lb:
        .asciz  "lb:  "
p18_str_lbu:
        .asciz  "lbu: "
        .align  2

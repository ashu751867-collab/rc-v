# P37 program: Write and read a CSR
#
# Reads a signed decimal number, writes it to the CSR mscratch (csrw),
# clears the register that held it, reads the CSR back (csrr) into a
# different register, and prints:  mscratch = <n>
#
# Registers:
#   a0 - argument/result for library calls (destroyed by every call)
#   s1 - holds the value read back from mscratch (survives library calls)
#
# Stack frame (8 bytes):
#   4(sp) = saved ra   (overwritten by every call)
#   0(sp) = saved s1   (we use it, so we must give it back unchanged)

    .text
p37_main:
    addi    sp, sp, -8              # make room for two words
    sw      ra, 4(sp)               # save return address
    sw      s1, 0(sp)               # save s1 (callee-saved register)

    call    rcv_read_dec            # a0 = signed number typed by the user
    csrw    mscratch, a0            # write it into the CSR file (P37 block)
    li      a0, 0                   # clear the register we used

    csrr    s1, mscratch            # read it back into a DIFFERENT register
                                    # (s1 survives the calls below; t0 would not)

    la      a0, p37_msg             # a0 = address of "mscratch = "
    call    rcv_puts                # print the label text
    mv      a0, s1                  # a0 = the value read back from the CSR
    call    rcv_print_dec           # print it as a signed decimal
    call    rcv_newline             # end the line

    lw      s1, 0(sp)               # restore s1
    lw      ra, 4(sp)               # restore return address
    addi    sp, sp, 8               # give the stack space back
    ret

    .rodata
p37_msg:
    .asciz  "mscratch = "
    .align  2

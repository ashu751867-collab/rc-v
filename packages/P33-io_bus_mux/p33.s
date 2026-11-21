# P33 - Device census
# Read FIRST and LAST slot, then print the non-empty device IDs in that range.

        .text
p33_main:
        # Preserve return address and all callee-saved registers used below.
        addi    sp, sp, -24
        sw      ra, 20(sp)
        sw      s1, 16(sp)
        sw      s2, 12(sp)
        sw      s3, 8(sp)
        sw      s4, 4(sp)
        sw      s5, 0(sp)

        # Input: inclusive range FIRST..LAST.
        call    rcv_read_dec
        mv      s1, a0              # FIRST
        call    rcv_read_dec
        mv      s2, a0              # LAST
        mv      s3, s1              # current slot
        li      s4, 0               # devices found

p33_loop:
        bgtu    s3, s2, p33_done

        # IO address = IO_BASE + slot*64 + register15*4.
        li      t0, IO_BASE
        slli    t1, s3, 6
        add     t0, t0, t1
        lw      s5, 60(t0)          # device ID (register 15)

        beqz    s5, p33_next

        # Print: "slot " + slot + ": " + ID + newline.
        la      a0, p33_slot_text
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_udec
        la      a0, p33_sep_text
        call    rcv_puts
        mv      a0, s5
        call    rcv_print_udec
        call    rcv_newline
        addi    s4, s4, 1

p33_next:
        addi    s3, s3, 1
        j       p33_loop

p33_done:
        la      a0, p33_count_text
        call    rcv_puts
        mv      a0, s4
        call    rcv_print_udec
        call    rcv_newline

        lw      s5, 0(sp)
        lw      s4, 4(sp)
        lw      s3, 8(sp)
        lw      s2, 12(sp)
        lw      s1, 16(sp)
        lw      ra, 20(sp)
        addi    sp, sp, 24
        ret

        .rodata
p33_slot_text:
        .asciz  "slot "
p33_sep_text:
        .asciz  ": "
p33_count_text:
        .asciz  "devices found: "
        .align  2

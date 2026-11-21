# P66 program - see README.md for the task.
# Rules: start at the label p66_main and finish with ret; every label you
# create starts with p66_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...
        .text

p66_main:
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

        # Print POST
        la      a0, p66_msg_post
        call    rcv_puts
        call    rcv_newline

        # Read n and LED pattern
        call    rcv_read_dec
        mv      s0, a0

        call    rcv_read_hex
        mv      s1, a0

        li      s2, 0

        # RAM test 1: 55555555
        li      s3, 0x55555555
        mv      a0, s3
        call    p66_ram_test
        mv      s7, a0

        la      a0, p66_msg_ram
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_hex

        beqz    s7, p66_ram1_ok
        addi    s2, s2, 1
        la      a0, p66_msg_fail
        j       p66_ram1_print

p66_ram1_ok:
        la      a0, p66_msg_ok

p66_ram1_print:
        call    rcv_puts
        call    rcv_newline

        # RAM test 2: AAAAAAAA
        li      s3, 0xAAAAAAAA
        mv      a0, s3
        call    p66_ram_test
        mv      s7, a0

        la      a0, p66_msg_ram
        call    rcv_puts
        mv      a0, s3
        call    rcv_print_hex

        beqz    s7, p66_ram2_ok
        addi    s2, s2, 1
        la      a0, p66_msg_fail
        j       p66_ram2_print

p66_ram2_ok:
        la      a0, p66_msg_ok

p66_ram2_print:
        call    rcv_puts
        call    rcv_newline

        # ROM checksum
        la      s6, p66_rom_table
        mv      s4, s0
        li      s5, 0

p66_rom_loop:
        beqz    s4, p66_rom_done
        lw      t0, 0(s6)
        add     s5, s5, t0
        addi    s6, s6, 4
        addi    s4, s4, -1
        j       p66_rom_loop

p66_rom_done:
        la      a0, p66_msg_rom
        call    rcv_puts
        mv      a0, s5
        call    rcv_print_hex
        call    rcv_newline

        # LED test
        li      t0, GPIO_LEDS
        sw      s1, 0(t0)
        lw      t1, 0(t0)

        li      s7, 0
        beq     t1, s1, p66_led_ok
        li      s7, 1
        addi    s2, s2, 1

p66_led_ok:
        la      a0, p66_msg_led
        call    rcv_puts
        mv      a0, s1
        call    rcv_print_hex

        beqz    s7, p66_led_pass
        la      a0, p66_msg_fail
        j       p66_led_print

p66_led_pass:
        la      a0, p66_msg_ok

p66_led_print:
        call    rcv_puts
        call    rcv_newline

        # UART test: maximum 100 polls
        li      t0, UART_TXSTATUS
        li      t1, 100

p66_uart_loop:
        lw      t2, 0(t0)
        andi    t2, t2, 1
        bnez    t2, p66_uart_ok
        addi    t1, t1, -1
        bnez    t1, p66_uart_loop

        addi    s2, s2, 1
        la      a0, p66_msg_uart_fail
        j       p66_uart_print

p66_uart_ok:
        la      a0, p66_msg_uart_ok

p66_uart_print:
        call    rcv_puts
        call    rcv_newline

        # Final POST result
        beqz    s2, p66_post_pass

        la      a0, p66_msg_post_fail
        call    rcv_puts
        mv      a0, s2
        call    rcv_print_dec
        la      a0, p66_msg_errors
        call    rcv_puts
        j       p66_post_done

p66_post_pass:
        la      a0, p66_msg_post_ok
        call    rcv_puts

p66_post_done:
        # Restore saved registers
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


# RAM test subroutine
# Input: a0 = test pattern
# Output: a0 = 0 (pass), 1 (fail)

p66_ram_test:
        mv      t4, a0
        la      t0, p66_ram
        li      t1, 0
        li      t2, 32

p66_ram_write:
        slli    t3, t1, 2
        add     t3, t0, t3
        sw      t4, 0(t3)
        addi    t1, t1, 1
        blt     t1, t2, p66_ram_write

        li      t1, 0

p66_ram_read:
        slli    t3, t1, 2
        add     t3, t0, t3
        lw      t5, 0(t3)
        bne     t5, t4, p66_ram_fail
        addi    t1, t1, 1
        blt     t1, t2, p66_ram_read

        li      a0, 0
        ret

p66_ram_fail:
        li      a0, 1
        ret


        .rodata

p66_msg_post:
        .asciz "POST"

p66_msg_ram:
        .asciz "RAM "

p66_msg_rom:
        .asciz "ROM checksum: "

p66_msg_led:
        .asciz "LEDS "

p66_msg_ok:
        .asciz ": OK"

p66_msg_fail:
        .asciz ": FAIL"

p66_msg_uart_ok:
        .asciz "UART: OK"

p66_msg_uart_fail:
        .asciz "UART: FAIL"

p66_msg_post_ok:
        .asciz "POST passed\n"

p66_msg_post_fail:
        .asciz "POST failed ("

p66_msg_errors:
        .asciz " errors)\n"

        .align 2

# ROM table: k * 0x01010101, k = 1 to 16
p66_rom_table:
        .word 0x01010101
        .word 0x02020202
        .word 0x03030303
        .word 0x04040404
        .word 0x05050505
        .word 0x06060606
        .word 0x07070707
        .word 0x08080808
        .word 0x09090909
        .word 0x0A0A0A0A
        .word 0x0B0B0B0B
        .word 0x0C0C0C0C
        .word 0x0D0D0D0D
        .word 0x0E0E0E0E
        .word 0x0F0F0F0F
        .word 0x10101010

        .data
        .align 2

# 32 words = 128 bytes
p66_ram:
        .space 128
        

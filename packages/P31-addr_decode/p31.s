# P31 program - Memory-map explorer

    .text
p31_main:
    addi    sp, sp, -8
    sw      ra, 4(sp)
    sw      s0, 0(sp)

    # Print ROM_BASE
    la      a0, p31_str_rom
    call    rcv_puts
    li      a0, ROM_BASE
    call    rcv_print_hex
    call    rcv_newline

    # Print RAM_BASE
    la      a0, p31_str_ram
    call    rcv_puts
    li      a0, RAM_BASE
    call    rcv_print_hex
    call    rcv_newline

    # Print IO_BASE
    la      a0, p31_str_io
    call    rcv_puts
    li      a0, IO_BASE
    call    rcv_print_hex
    call    rcv_newline

    # Read and print GPIO_BUTTONS
    la      a0, p31_str_btn
    call    rcv_puts
    li      t0, GPIO_BUTTONS
    lw      a0, 0(t0)
    call    rcv_print_hex
    call    rcv_newline

    # Read hex input and store to GPIO_LEDS
    call    rcv_read_hex
    mv      s0, a0
    li      t0, GPIO_LEDS
    sw      s0, 0(t0)

    # Print what was written
    la      a0, p31_str_wrote
    call    rcv_puts
    mv      a0, s0
    call    rcv_print_hex
    call    rcv_newline

    # Read back GPIO_LEDS and print
    la      a0, p31_str_leds
    call    rcv_puts
    li      t0, GPIO_LEDS
    lw      a0, 0(t0)
    call    rcv_print_hex
    call    rcv_newline

    lw      s0, 0(sp)
    lw      ra, 4(sp)
    addi    sp, sp, 8
    ret

    .rodata
p31_str_rom:
    .asciz  "ROM base = "
p31_str_ram:
    .asciz  "RAM base = "
p31_str_io:
    .asciz  "I/O base = "
p31_str_btn:
    .asciz  "buttons  = "
p31_str_wrote:
    .asciz  "wrote    = "
p31_str_leds:
    .asciz  "leds     = "
    .align  2

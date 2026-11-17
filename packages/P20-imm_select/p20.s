
.text
.globl p20_main

p20_main:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)

    li s0, 0
    li s1, 0
    li s2, 0

    la s3, p20_numbers
    mv s4, s3

p20_input_loop:
    li t0, 20
    bge s0, t0, p20_input_done

    call p20_read_dec
    beqz a0, p20_input_done

    sw a0, 0(s4)
    addi s4, s4, 4
    addi s0, s0, 1
    j p20_input_loop

p20_input_done:
    beqz s0, p20_empty

    mv s4, s3
    li s5, 0
    li s1, 0
    li s2, 0

p20_calculate_loop:
    bge s5, s0, p20_calculate_done

    lw t0, 0(s4)
    add s1, s1, t0

    bge s2, t0, p20_no_max_update
    mv s2, t0

p20_no_max_update:
    addi s4, s4, 4
    addi s5, s5, 1
    j p20_calculate_loop

p20_calculate_done:
    la a0, p20_count_label
    call rcv_puts
    mv a0, s0
    call rcv_print_udec
    call rcv_newline

    la a0, p20_sum_label
    call rcv_puts
    mv a0, s1
    call rcv_print_udec
    call rcv_newline

    la a0, p20_mean_label
    call rcv_puts
    mv a0, s1
    mv a1, s0
    call rcv_udiv
    call rcv_print_udec
    call rcv_newline

    la a0, p20_max_label
    call rcv_puts
    mv a0, s2
    call rcv_print_udec
    call rcv_newline

    j p20_exit

p20_empty:
    la a0, p20_count_label
    call rcv_puts
    li a0, 0
    call rcv_print_udec
    call rcv_newline

p20_exit:
    lw s5, 4(sp)
    lw s4, 8(sp)
    lw s3, 12(sp)
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret

p20_read_dec:
    li t0, 0x00020044

p20_wait_first:
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, p20_wait_first

    li t0, 0x00020040
    lw t1, 0(t0)
    andi t1, t1, 255

    li t2, 10
    beq t1, t2, p20_read_dec
    li t2, 13
    beq t1, t2, p20_read_dec

    li t2, 48
    beq t1, t2, p20_zero

    addi a0, t1, -48

p20_read_more:
    li t0, 0x00020044

p20_wait_more:
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, p20_wait_more

    li t0, 0x00020040
    lw t1, 0(t0)
    andi t1, t1, 255

    li t2, 10
    beq t1, t2, p20_read_done
    li t2, 13
    beq t1, t2, p20_read_done

    slli t2, a0, 3
    slli t3, a0, 1
    add a0, t2, t3
    addi t1, t1, -48
    add a0, a0, t1
    j p20_read_more

p20_read_done:
    ret

p20_zero:
    li a0, 0
    ret

.data
.align 2

p20_numbers:
    .space 80

.rodata

p20_count_label:
    .asciz "count: "

p20_sum_label:
    .asciz "sum: "

p20_mean_label:
    .asciz "mean: "

p20_max_label:
    .asciz "max: "

.align 2


# P32 program - Student records
# Reads 5 student records, finds topper and calculates average.

        .text
p32_main:
        # Save registers
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        sw      s5, 4(sp)
        sw      s6, 0(sp)

        # s0 = RAM records base address
        la      s0, p32_records
        li      s1, 0              # Student counter
        li      s4, 0              # Total marks

# Read 5 student records
p32_input_loop:
        call    rcv_read_dec       # Read roll number
        mv      s5, a0

        call    rcv_read_dec       # Read marks
        mv      s6, a0

        # Address = base + index * 8
        slli    t0, s1, 3
        add     t0, s0, t0

        sw      s5, 0(t0)          # Store roll
        sw      s6, 4(t0)          # Store marks

        add     s4, s4, s6        # Update total marks

        addi    s1, s1, 1
        li      t0, 5
        blt     s1, t0, p32_input_loop

# Find topper
        lw      s2, 0(s0)          # Topper roll
        lw      s3, 4(s0)          # Highest marks
        li      s1, 1              # Start from second student

p32_topper_loop:
        li      t0, 5
        bge     s1, t0, p32_topper_done

        slli    t0, s1, 3
        add     t0, s0, t0

        lw      s5, 0(t0)          # Current roll
        lw      s6, 4(t0)          # Current marks

        # Update only if current marks are greater
        bgeu    s3, s6, p32_skip_update

        mv      s2, s5
        mv      s3, s6

p32_skip_update:
        addi    s1, s1, 1
        j       p32_topper_loop

p32_topper_done:
        # Print topper message
        la      a0, p32_topper_msg
        call    rcv_puts

        mv      a0, s2
        call    rcv_print_udec

        la      a0, p32_marks_msg
        call    rcv_puts

        mv      a0, s3
        call    rcv_print_udec

        la      a0, p32_close_msg
        call    rcv_puts

        # Calculate average = total / 5
        la      a0, p32_average_msg
        call    rcv_puts

        mv      a0, s4
        li      a1, 5
        call    rcv_udiv

        call    rcv_print_udec
        call    rcv_newline

        # Restore registers
        lw      s6, 0(sp)
        lw      s5, 4(sp)
        lw      s4, 8(sp)
        lw      s3, 12(sp)
        lw      s2, 16(sp)
        lw      s1, 20(sp)
        lw      s0, 24(sp)
        lw      ra, 28(sp)
        addi    sp, sp, 32
        ret

        .data
        .align  2
p32_records:
        .space  40                # 5 records * 8 bytes

        .rodata
p32_topper_msg:
        .asciz  "topper: roll "
p32_marks_msg:
        .asciz  " (marks "
p32_close_msg:
        .asciz  ")\n"
p32_average_msg:
        .asciz  "average: "

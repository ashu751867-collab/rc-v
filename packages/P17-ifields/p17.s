
# P17 - Instruction field splitter
# Mini disassembler

        .text
p17_main:
        # Save registers and return address
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        sw      s2, 0(sp)

        # s0 = instruction
        # s1 = opcode
        # s2 = funct3
        # s3 is not used

p17_read_loop:
        call    rcv_read_hex
        mv      s0, a0

        # Stop when input is zero
        beqz    s0, p17_done

        # Extract opcode: instr[6:0]
        andi    s1, s0, 127

        # Extract funct3: instr[14:12]
        srli    s2, s0, 12
        andi    s2, s2, 7

        # Check R-type opcode (0x33)
        li      t0, 0x33
        beq     s1, t0, p17_r_type

        # Check I-type opcodes
        li      t0, 0x13
        beq     s1, t0, p17_i_type
        li      t0, 0x03
        beq     s1, t0, p17_i_type
        li      t0, 0x67
        beq     s1, t0, p17_i_type
        li      t0, 0x73
        beq     s1, t0, p17_i_type

        # Check S-type opcode
        li      t0, 0x23
        beq     s1, t0, p17_s_type

        # Check B-type opcode
        li      t0, 0x63
        beq     s1, t0, p17_b_type

        # Check U-type opcodes
        li      t0, 0x37
        beq     s1, t0, p17_u_type
        li      t0, 0x17
        beq     s1, t0, p17_u_type

        # Check J-type opcode
        li      t0, 0x6F
        beq     s1, t0, p17_j_type

        j       p17_unknown

p17_r_type:
        # Extract funct7: instr[31:25]
        srli    t0, s0, 25

        # Select the correct table
        beqz    t0, p17_r_funct7_zero

        li      t1, 0x20
        beq     t0, t1, p17_r_funct7_20

        j       p17_unknown

p17_r_funct7_zero:
        # Look up instruction name using funct3
        la      t0, p17_r_names
        slli    t1, s2, 2
        add     t0, t0, t1
        lw      a0, 0(t0)
        beqz    a0, p17_unknown

        call    rcv_puts
        j       p17_print_registers

p17_r_funct7_20:
        # Only SUB (funct3=0) and SRA (funct3=5)
        la      t0, p17_r_names_20
        slli    t1, s2, 2
        add     t0, t0, t1
        lw      a0, 0(t0)
        beqz    a0, p17_unknown

        call    rcv_puts

p17_print_registers:
        # Print destination register: x[rd]
        li      a0, ' '
        call    rcv_putc
        li      a0, 'x'
        call    rcv_putc

        srli    a0, s0, 7
        andi    a0, a0, 31
        call    rcv_print_udec

        # Print comma and space
        la      a0, p17_comma
        call    rcv_puts

        # Print first source register: x[rs1]
        li      a0, 'x'
        call    rcv_putc

        srli    a0, s0, 15
        andi    a0, a0, 31
        call    rcv_print_udec

        # Print comma and space
        la      a0, p17_comma
        call    rcv_puts

        # Print second source register: x[rs2]
        li      a0, 'x'
        call    rcv_putc

        srli    a0, s0, 20
        andi    a0, a0, 31
        call    rcv_print_udec

        call    rcv_newline
        j       p17_read_loop

p17_i_type:
        la      a0, p17_i_string
        call    rcv_puts
        j       p17_print_line

p17_s_type:
        la      a0, p17_s_string
        call    rcv_puts
        j       p17_print_line

p17_b_type:
        la      a0, p17_b_string
        call    rcv_puts
        j       p17_print_line

p17_u_type:
        la      a0, p17_u_string
        call    rcv_puts
        j       p17_print_line

p17_j_type:
        la      a0, p17_j_string
        call    rcv_puts
        j       p17_print_line

p17_unknown:
        la      a0, p17_unknown_string
        call    rcv_puts

p17_print_line:
        call    rcv_newline
        j       p17_read_loop

p17_done:
        # Restore registers
        lw      s2, 0(sp)
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret


        .rodata
        .align  2

# Function names indexed by funct3
p17_r_names:
        .word   p17_add
        .word   p17_sll
        .word   p17_slt
        .word   p17_sltu
        .word   p17_xor
        .word   p17_srl
        .word   p17_or
        .word   p17_and

# Function names for funct7 = 0x20
p17_r_names_20:
        .word   p17_sub
        .word   0
        .word   0
        .word   0
        .word   0
        .word   p17_sra
        .word   0
        .word   0

p17_add:
        .asciz  "add"
p17_sll:
        .asciz  "sll"
p17_slt:
        .asciz  "slt"
p17_sltu:
        .asciz  "sltu"
p17_xor:
        .asciz  "xor"
p17_srl:
        .asciz  "srl"
p17_or:
        .asciz  "or"
p17_and:
        .asciz  "and"
p17_sub:
        .asciz  "sub"
p17_sra:
        .asciz  "sra"

p17_i_string:
        .asciz  "I-type"
p17_s_string:
        .asciz  "S-type"
p17_b_string:
        .asciz  "B-type"
p17_u_string:
        .asciz  "U-type"
p17_j_string:
        .asciz  "J-type"
p17_unknown_string:
        .asciz  "unknown"

p17_comma:
        .asciz  ", "


.align 2
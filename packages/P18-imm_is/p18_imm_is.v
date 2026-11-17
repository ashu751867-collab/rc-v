// P18 Immediate generator I/S
// Combinational Verilog module extracting and sign-extending I-type and S-type immediates.
module p18_imm_is (
    input  wire [31:0] instr,
    output wire [31:0] imm_i,
    output wire [31:0] imm_s
);

    // imm_i: extract bits [31:20] and sign-extend by replicating bit 31 twenty times
    assign imm_i = {{20{instr[31]}}, instr[31:20]};

    // imm_s: extract bits [31:25] and [11:7], concatenate, and sign-extend by replicating bit 31 twenty times
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

endmodule

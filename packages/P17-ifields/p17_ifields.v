 // P17 Instruction field splitter
module p17_ifields (
    input  wire [31:0] instr,
    output wire [6:0] opcode,
    output wire [4:0] rd,
    output wire [2:0] funct3,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [6:0] funct7,
    output wire [11:0] csr
);

    // Extract opcode: instruction bits [6:0]
    assign opcode = instr[6:0];

    // Extract destination register: bits [11:7]
    assign rd = instr[11:7];

    // Extract funct3: bits [14:12]
    assign funct3 = instr[14:12];

    // Extract source register 1: bits [19:15]
    assign rs1 = instr[19:15];

    // Extract source register 2: bits [24:20]
    assign rs2 = instr[24:20];

    // Extract funct7: bits [31:25]
    assign funct7 = instr[31:25];

    // Extract CSR field: bits [31:20]
    assign csr = instr[31:20];

endmodule

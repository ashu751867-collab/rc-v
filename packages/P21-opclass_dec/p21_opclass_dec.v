// P21 Opcode class decoder
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p21_opclass_dec (
    input  wire [31:0] instr,
    output wire is_lui,
    output wire is_auipc,
    output wire is_jal,
    output wire is_jalr,
    output wire is_branch,
    output wire is_load,
    output wire is_store,
    output wire is_opimm,
    output wire is_op,
    output wire is_system,
    output wire is_ecall,
    output wire is_mret
);

    wire [6:0] opcode = instr[6:0];

    assign is_lui    = (opcode == 7'b0110111);
    assign is_auipc  = (opcode == 7'b0010111);
    assign is_jal    = (opcode == 7'b1101111);
    assign is_jalr   = (opcode == 7'b1100111);
    assign is_branch = (opcode == 7'b1100011);
    assign is_load   = (opcode == 7'b0000011);
    assign is_store  = (opcode == 7'b0100011);
    assign is_opimm  = (opcode == 7'b0010011);
    assign is_op     = (opcode == 7'b0110011);
    assign is_system = (opcode == 7'b1110011);

    assign is_ecall  = (instr == 32'h00000073);
    assign is_mret   = (instr == 32'h30200073);

endmodule

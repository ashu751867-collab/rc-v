module p15_next_pc (
    input  wire [2:0] sel,
    input  wire [31:0] pc4,
    input  wire [31:0] target,
    input  wire [31:0] jalr_y,
    input  wire [31:0] mtvec,
    input  wire [31:0] mepc,
    output wire [31:0] npc
);

    assign npc = (sel == 3'd1) ? target :
                 (sel == 3'd2) ? (jalr_y & 32'hFFFFFFFE) :
                 (sel == 3'd3) ? mtvec :
                 (sel == 3'd4) ? mepc :
                                 pc4;

endmodule

// P09 Branch comparator
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p09_branch_cmp (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0] funct3,
    output reg take
);

    wire eq  = (a == b);
    wire lt  = ($signed(a) < $signed(b));
    wire ltu = (a < b);

    always @(*) begin
        case (funct3)
            3'd0: take = eq;    // BEQ
            3'd1: take = ~eq;   // BNE
            3'd4: take = lt;    // BLT
            3'd5: take = ~lt;   // BGE
            3'd6: take = ltu;   // BLTU
            3'd7: take = ~ltu;  // BGEU
            default: take = 1'b0;
        endcase
    end

endmodule

// P51 Four-lane vector unit (mini GPU)
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p51_simd_unit (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] a_reg;
    reg [31:0] b_reg;

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 32'd0;
            b_reg <= 32'd0;
        end else if (sel && we) begin
            if (ridx == 4'd0)
                a_reg <= wdata;
            else if (ridx == 4'd1)
                b_reg <= wdata;
        end
    end

    // Four 8-bit lanes
    wire [7:0] a0 = a_reg[7:0];
    wire [7:0] a1 = a_reg[15:8];
    wire [7:0] a2 = a_reg[23:16];
    wire [7:0] a3 = a_reg[31:24];

    wire [7:0] b0 = b_reg[7:0];
    wire [7:0] b1 = b_reg[15:8];
    wire [7:0] b2 = b_reg[23:16];
    wire [7:0] b3 = b_reg[31:24];

    // Lane operations (wrap-around addition, unsigned max, wrap-around subtraction)
    wire [7:0] sum0 = a0 + b0;
    wire [7:0] sum1 = a1 + b1;
    wire [7:0] sum2 = a2 + b2;
    wire [7:0] sum3 = a3 + b3;
    wire [31:0] sum_val = {sum3, sum2, sum1, sum0};

    wire [7:0] max0 = (a0 >= b0) ? a0 : b0;
    wire [7:0] max1 = (a1 >= b1) ? a1 : b1;
    wire [7:0] max2 = (a2 >= b2) ? a2 : b2;
    wire [7:0] max3 = (a3 >= b3) ? a3 : b3;
    wire [31:0] max_val = {max3, max2, max1, max0};

    wire [7:0] sub0 = a0 - b0;
    wire [7:0] sub1 = a1 - b1;
    wire [7:0] sub2 = a2 - b2;
    wire [7:0] sub3 = a3 - b3;
    wire [31:0] sub_val = {sub3, sub2, sub1, sub0};

    // rdata multiplexing
    assign rdata = (ridx == 4'd0)  ? a_reg :
                   (ridx == 4'd1)  ? b_reg :
                   (ridx == 4'd2)  ? sum_val :
                   (ridx == 4'd3)  ? max_val :
                   (ridx == 4'd4)  ? sub_val :
                   (ridx == 4'd15) ? 32'd51 :
                                     32'd0;

endmodule

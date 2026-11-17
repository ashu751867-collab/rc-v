// P60 Parity generator
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.

module p60_parity_unit (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    // register 0: DATA
    reg [31:0] data;
    always @(posedge clk) begin
        if (rst)
            data <= 32'd0;
        else if (sel && we && ridx == 4'd0)
            data <= wdata;
    end

    // parity of each byte: XOR of its 8 bits
    wire p0 = ^data[7:0];
    wire p1 = ^data[15:8];
    wire p2 = ^data[23:16];
    wire p3 = ^data[31:24];

    // register 1: PARITY (bit k = byte k, bit 4 = whole word)
    wire [4:0] parity = {p0 ^ p1 ^ p2 ^ p3, p3, p2, p1, p0};

    // register 2: ODD (how many bytes have odd parity, 0 to 4)
    wire [2:0] odd = {2'b00, p0} + {2'b00, p1} + {2'b00, p2} + {2'b00, p3};

    // read side: rdata always shows the register that ridx points at
    assign rdata = (ridx == 4'd0)  ? data :
                   (ridx == 4'd1)  ? {27'd0, parity} :
                   (ridx == 4'd2)  ? {29'd0, odd} :
                   (ridx == 4'd15) ? 32'd60 :
                                     32'd0;

endmodule

// P64 Code converter (Gray, excess-3)
// Slot 22: VAL, GRAY, FROMGRAY, XS3 (excess-3 of the four decimal digits)
// Registers at 0x00020580; register 15 reads 64 (the package number)

module p64_code_conv (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [15:0] val;

    always @(posedge clk) begin
        if (rst) begin
            val <= 16'd0;
        end else if (sel && we && (ridx == 4'h0)) begin
            val <= wdata[15:0];
        end
    end

    function [15:0] gray_to_bin;
        input [15:0] g;
        integer i;
        begin
            gray_to_bin[15] = g[15];
            for (i = 14; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i+1] ^ g[i];
            end
        end
    endfunction

    wire [3:0] d0 = (val % 10) + 4'd3;
    wire [3:0] d1 = ((val / 10) % 10) + 4'd3;
    wire [3:0] d2 = ((val / 100) % 10) + 4'd3;
    wire [3:0] d3 = ((val / 1000) % 10) + 4'd3;
    wire [15:0] xs3_out = {d3, d2, d1, d0};

    reg [31:0] rdata_comb;
    always @(*) begin
        case (ridx)
            4'h0: rdata_comb = {16'd0, val};
            4'h1: rdata_comb = {16'd0, val ^ (val >> 1)};
            4'h2: rdata_comb = {16'd0, gray_to_bin(val)};
            4'h3: rdata_comb = {16'd0, xs3_out};
            4'hf: rdata_comb = 32'd64;
            default: rdata_comb = 32'd0;
        endcase
    end

    assign rdata = rdata_comb;

endmodule

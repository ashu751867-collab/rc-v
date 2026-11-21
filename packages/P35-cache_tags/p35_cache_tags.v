// P35 - Cache tag store (4 lines, index = addr[3:2], tag = addr[7:4])
// Same behaviour as P35.dig:
//  - posedge clk, rst=1      -> all valid bits cleared
//  - posedge clk, access=1   -> line[index] gets valid=1 and tag stored
//  - hit = access & valid[index] & (stored tag == addr tag)   (combinational)
module p35_cache_tags (
    input  wire       clk,
    input  wire       rst,
    input  wire       access,
    input  wire [7:0] addr,
    output wire       hit
);
    wire [1:0] index = addr[3:2];
    wire [3:0] tag   = addr[7:4];

    reg [3:0] valid;
    reg [3:0] tags [0:3];

    integer i;
    initial begin
        valid = 4'b0000;
        for (i = 0; i < 4; i = i + 1) tags[i] = 4'b0000;
    end

    always @(posedge clk) begin
        if (rst) begin
            valid <= 4'b0000;
        end else if (access) begin
            valid[index] <= 1'b1;
            tags[index]  <= tag;
        end
    end

    assign hit = access & valid[index] & (tags[index] == tag);
endmodule

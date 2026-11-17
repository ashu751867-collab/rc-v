module p29_data_ram (
    input  wire clk,
    input  wire we,
    input  wire [11:0] addr,
    input  wire [3:0] be,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:4095];
    reg [31:0] w;
    integer i;

    initial begin
        for (i = 0; i < 4096; i = i + 1)
            mem[i] = 32'd0;
    end

    assign rdata = mem[addr];

    always @(posedge clk) begin
        if (we) begin
            w = mem[addr];
            if (be[0]) w[7:0]   = wdata[7:0];
            if (be[1]) w[15:8]  = wdata[15:8];
            if (be[2]) w[23:16] = wdata[23:16];
            if (be[3]) w[31:24] = wdata[31:24];
            mem[addr] <= w;
        end
    end

endmodule
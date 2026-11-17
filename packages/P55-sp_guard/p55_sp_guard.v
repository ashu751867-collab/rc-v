// P55 Stack guard
// Device slot 13. Registers: 0 LIMIT, 1 STATUS, 2 MINSP, 15 = package number (55).
// It watches every write to register x2 (sp) and remembers the lowest value seen.
module p55_sp_guard (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire commit,
    input  wire rf_we,
    input  wire [4:0] rd,
    input  wire [31:0] rf_wd,
    output wire irq
);

    reg [31:0] limit_r;    // register 0: sp limit, written by the program
    reg [31:0] minsp_r;    // register 2: lowest sp value seen so far
    reg        status_r;   // register 1, bit 0: sp went below LIMIT

    // The program writes a device register
    wire dev_write = sel & we;

    // The processor writes x2 (sp) and the instruction really completes
    wire sp_write = commit & rf_we & (rd == 5'd2);

    // Next values. LIMIT write counts first; a STATUS write beats the sp watcher.
    reg [31:0] limit_n;
    reg [31:0] minsp_n;
    reg        status_n;

    always @* begin
        limit_n  = limit_r;
        minsp_n  = minsp_r;
        status_n = status_r;

        // write LIMIT
        if (dev_write && ridx == 4'd0)
            limit_n = wdata;

        // any write to STATUS clears it and resets MINSP
        if (dev_write && ridx == 4'd1) begin
            status_n = 1'b0;
            minsp_n  = 32'hFFFF_FFFF;
        end

        // new sp value: keep the minimum, raise the flag if below LIMIT.
        // A STATUS write in the same cycle wins, so the sp value is dropped.
        else if (sp_write) begin
            if (rf_wd < minsp_n)
                minsp_n = rf_wd;
            if (rf_wd < limit_n)
                status_n = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            limit_r  <= 32'd0;
            minsp_r  <= 32'hFFFF_FFFF;
            status_r <= 1'b0;
        end else begin
            limit_r  <= limit_n;
            minsp_r  <= minsp_n;
            status_r <= status_n;
        end
    end

    // rdata always shows the register chosen by ridx
    assign rdata = (ridx == 4'd0)  ? limit_r :
                   (ridx == 4'd1)  ? {31'd0, status_r} :
                   (ridx == 4'd2)  ? minsp_r :
                   (ridx == 4'd15) ? 32'd55 :
                                     32'd0;

    // interrupt request = STATUS bit 0
    assign irq = status_r;

endmodule

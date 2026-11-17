// P53 Watchdog timer
// Slot 11 registers (ridx): 0 LOAD, 1 CTRL (bit0 enable), 2 STATUS (bit0 = bite),
//                           3 COUNT, 4 KICK, 15 = 53 (package number)
//
// Counts down while enabled. At 0 it sets the sticky bite flag and reloads from LOAD.
// A write to KICK reloads the counter from LOAD (wins over a bite on the same cycle).
// A write to CTRL with bit0 = 1 arms the watchdog: it also reloads the counter.
// A write to CTRL with bit0 = 0 stops it at once: the counter freezes.
// A write to STATUS clears the bite flag, unless the counter bites on that same cycle.
// A write to LOAD changes LOAD only; the counter takes the new value at the next reload.
// rst clears everything.
//
// Everything, including rdata, changes only on the rising edge of clk.
// rdata shows the register selected by ridx as it is AFTER that edge (the reading
// does not depend on sel/re, and rdata is not cleared when the block is idle).
module p53_watchdog (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire        re,
    input  wire [3:0]  ridx,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg [31:0] load, count;
    reg        en, bite;

    wire wr      = sel & we;
    wire wr_load = wr & (ridx == 4'd0);
    wire wr_ctrl = wr & (ridx == 4'd1);
    wire wr_stat = wr & (ridx == 4'd2);
    wire kick    = wr & (ridx == 4'd4);

    // values as they are after this clock edge
    wire        n_en   = wr_ctrl ? wdata[0] : en;
    wire [31:0] n_load = wr_load ? wdata    : load;
    wire        expire = n_en & (count == 32'd0);

    reg [31:0] n_count;
    reg        n_bite;

    always @* begin
        // counter
        if (kick | (wr_ctrl & wdata[0]))
            n_count = n_load;                // kick or arm: reload
        else if (!n_en)
            n_count = count;                 // stopped: freeze
        else if (count == 32'd0)
            n_count = n_load;                // reached 0: reload
        else
            n_count = count - 32'd1;         // count down

        // sticky bite flag (a bite on this cycle wins over a clear)
        if (expire & ~kick)
            n_bite = 1'b1;
        else if (wr_stat)
            n_bite = 1'b0;
        else
            n_bite = bite;
    end

    always @(posedge clk) begin
        if (rst) begin
            load  <= 32'd0;
            count <= 32'd0;
            en    <= 1'b0;
            bite  <= 1'b0;
            rdata <= 32'd0;
        end else begin
            load  <= n_load;
            en    <= n_en;
            count <= n_count;
            bite  <= n_bite;
            case (ridx)
                4'd0:    rdata <= n_load;
                4'd1:    rdata <= {31'd0, n_en};
                4'd2:    rdata <= {31'd0, n_bite};
                4'd3:    rdata <= n_count;
                4'd15:   rdata <= 32'd53;
                default: rdata <= 32'd0;
            endcase
        end
    end

endmodule

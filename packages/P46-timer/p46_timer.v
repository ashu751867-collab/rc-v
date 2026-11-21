// P46 Timer
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
// P46 Timer  (I/O device slot 3, registers at 0x000200C0)
//   reg 0  COUNT   (read/write)  counts up every cycle while CTRL.bit0 = 1
//   reg 1  CMP     (read/write)
//   reg 2  CTRL    bit0 = enable, bit1 = interrupt enable
//   reg 3  STATUS  bit0 = match (set when COUNT == CMP while enabled,
//                                cleared by writing STATUS)
//   reg 15 ID      always reads 46 (the package number)
//   irq = match AND CTRL.bit1
// Reads are combinational (rdata must not wait for the clock);
// all state changes happen on the rising edge of clk.
// P46 Timer  (I/O device slot 3, registers at 0x000200C0)
//   reg 0  COUNT   (read/write)  counts up every cycle while CTRL.bit0 = 1
//   reg 1  CMP     (read/write)
//   reg 2  CTRL    bit0 = enable, bit1 = interrupt enable
//   reg 3  STATUS  bit0 = match (set when COUNT == CMP while enabled,
//                                cleared by writing STATUS)
//   reg 15 ID      always reads 46 (the package number)
//   irq = match AND CTRL.bit1
// Reads are combinational (rdata must not wait for the clock) and always
// show register ridx; writes need sel & we;
// all state changes happen on the rising edge of clk.
module p46_timer (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire irq
);

    localparam [3:0] R_COUNT  = 4'd0;
    localparam [3:0] R_CMP    = 4'd1;
    localparam [3:0] R_CTRL   = 4'd2;
    localparam [3:0] R_STATUS = 4'd3;
    localparam [3:0] R_ID     = 4'd15;

    reg [31:0] count;
    reg [31:0] cmp;
    reg        en;      // CTRL bit 0
    reg        ie;      // CTRL bit 1
    reg        match;   // STATUS bit 0

    wire wr  = sel & we;
    wire hit = en & (count == cmp);

    assign irq = match & ie;

    // ---------------- registers (rising edge only) ----------------
    always @(posedge clk) begin
        if (rst) begin
            count <= 32'd0;
            cmp   <= 32'd0;
            en    <= 1'b0;
            ie    <= 1'b0;
            match <= 1'b0;
        end else begin
            // COUNT: a write wins over counting
            if (wr && ridx == R_COUNT)
                count <= wdata;
            else if (en)
                count <= count + 32'd1;

            if (wr && ridx == R_CMP)
                cmp <= wdata;

            if (wr && ridx == R_CTRL) begin
                en <= wdata[0];
                ie <= wdata[1];
            end

            // STATUS: sticky match flag, writing STATUS clears it
            if (wr && ridx == R_STATUS)
                match <= 1'b0;
            else if (hit)
                match <= 1'b1;
        end
    end

    // ---------------- read port (combinational) ----------------
    // rdata always shows the register addressed by ridx; it does not wait
    // for the clock and does not depend on sel / re.
    always @* begin
        case (ridx)
            R_COUNT:  rdata = count;
            R_CMP:    rdata = cmp;
            R_CTRL:   rdata = {30'd0, ie, en};
            R_STATUS: rdata = {31'd0, match};
            R_ID:     rdata = 32'd46;
            default:  rdata = 32'd0;
        endcase
    end

endmodule

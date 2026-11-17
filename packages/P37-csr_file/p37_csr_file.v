// P37 Control and status registers
module p37_csr_file (
    input  wire clk,
    input  wire rst,
    input  wire [11:0] addr,
    input  wire we,
    input  wire [31:0] wdata,
    input  wire trap,
    input  wire [31:0] cause,
    input  wire [31:0] pc,
    input  wire mret,
    output wire [31:0] rdata,
    output wire [31:0] mtvec,
    output wire [31:0] mepc,
    output wire mie
);

    // CSR numbers (standard RISC-V)
    localparam MSTATUS  = 12'h300;
    localparam MTVEC    = 12'h305;
    localparam MSCRATCH = 12'h340;
    localparam MEPC     = 12'h341;
    localparam MCAUSE   = 12'h342;

    // the stored values (flip-flops)
    reg [31:0] mtvec_r, mscratch_r, mepc_r, mcause_r;
    reg        mie_r, mpie_r;
    reg [31:0] rdata_r;

    // wires from the stored values to the output pins
    assign mtvec = mtvec_r;
    assign mepc  = mepc_r;
    assign mie   = mie_r;
    assign rdata = rdata_r;

    // what happens on each clock tick (priority: rst, trap, mret, write)
    always @(posedge clk) begin
        if (rst) begin
            mtvec_r <= 0;  mscratch_r <= 0;
            mepc_r  <= 0;  mcause_r   <= 0;
            mie_r   <= 0;  mpie_r     <= 0;
        end else if (trap) begin
            mepc_r   <= pc;
            mcause_r <= cause;
            mpie_r   <= mie_r;
            mie_r    <= 1'b0;
        end else if (mret) begin
            mie_r  <= mpie_r;
            mpie_r <= 1'b1;
        end else if (we) begin
            case (addr)
                MSTATUS:  begin mie_r <= wdata[3]; mpie_r <= wdata[7]; end
                MTVEC:    mtvec_r    <= wdata;
                MSCRATCH: mscratch_r <= wdata;
                MEPC:     mepc_r     <= wdata;
                MCAUSE:   mcause_r   <= wdata;
                default:  ;
            endcase
        end
    end

    // reading: rdata shows the register that addr points to
    always @* begin
        case (addr)
            MSTATUS:  rdata_r = {24'b0, mpie_r, 3'b0, mie_r, 3'b0};
            MTVEC:    rdata_r = mtvec_r;
            MSCRATCH: rdata_r = mscratch_r;
            MEPC:     rdata_r = mepc_r;
            MCAUSE:   rdata_r = mcause_r;
            default:  rdata_r = 32'd0;
        endcase
    end

endmodule

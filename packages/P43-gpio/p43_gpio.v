module p43_gpio (
    input         clk,
    input         rst,
    input         sel,
    input         we,
    input         re,
    input  [3:0]  ridx,
    input  [31:0] wdata,
    output [31:0] rdata,
    input  [7:0]  buttons,
    output [15:0] leds,
    output [31:0] seg
);
    reg [15:0] led_reg;
    reg [31:0] seg_reg;
    reg [31:0] rdata_int;

    always @(posedge clk) begin
        if (rst) begin
            led_reg <= 16'd0;
            seg_reg <= 32'd0;
        end else if (sel && we) begin
            if (ridx == 4'd0) led_reg <= wdata[15:0];
            if (ridx == 4'd1) seg_reg <= wdata;
        end
    end

    always @* begin
        case (ridx)
            4'd0:    rdata_int = {16'd0, led_reg};
            4'd1:    rdata_int = seg_reg;
            4'd2:    rdata_int = {24'd0, buttons};
            4'd15:   rdata_int = 32'd43;
            default: rdata_int = 32'd0;
        endcase
    end

    assign rdata = rdata_int;
    assign leds  = led_reg;
    assign seg   = seg_reg;
endmodule

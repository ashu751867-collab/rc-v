// P11 Register-file write decoder
module p11_rf_decoder (
    input wire we,
    input wire [4:0] rd,
    output wire [31:0] wen
);
    assign wen = (we && (rd != 5'd0)) ? (32'b1 << rd) : 32'd0;
endmodule

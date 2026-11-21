// P33 I/O read bus
// Select one 32-bit device word from the 32 packed device words.
// Slot k occupies dev_flat[32*k +: 32].
module p33_io_bus_mux (
    input  wire [1023:0] dev_flat,
    input  wire [4:0] dev,
    output wire [31:0] rdata
);
    assign rdata = dev_flat[dev * 32 +: 32];
endmodule

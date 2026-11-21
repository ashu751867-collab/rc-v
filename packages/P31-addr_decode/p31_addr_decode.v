// P31 Address decoder (memory map)
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p31_addr_decode (
    input  wire [31:0] addr,
    output wire sel_rom,
    output wire sel_ram,
    output wire sel_io,
    output wire [4:0] dev,
    output wire [3:0] ridx
);

    assign sel_rom = (addr >= 32'h00000000) && (addr <= 32'h0000FFFF);
    assign sel_ram = (addr >= 32'h00010000) && (addr <= 32'h00013FFF);
    assign sel_io  = (addr >= 32'h00020000) && (addr <= 32'h000207FF);
    assign dev     = addr[10:6];
    assign ridx    = addr[5:2];

endmodule

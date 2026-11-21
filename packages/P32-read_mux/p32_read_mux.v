// P32 Memory read selector
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p32_read_mux (
    input  wire sel_rom,
    input  wire sel_ram,
    input  wire sel_io,
    input  wire [31:0] rom_d,
    input  wire [31:0] ram_d,
    input  wire [31:0] io_d,
    output wire [31:0] rdata
);

    assign rdata =
        ({32{sel_rom}} & rom_d) |
        ({32{sel_ram}} & ram_d) |
        ({32{sel_io} } & io_d);

endmodule

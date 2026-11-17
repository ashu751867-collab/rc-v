// P30 Boot ROM
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p30_boot_rom #(parameter INIT_FILE = "boot.hex") (
    input  wire [13:0] iaddr,
    input  wire [13:0] daddr,
    output wire [31:0] idata,
    output wire [31:0] ddata
);

    reg [31:0] mem [0:16383];

    initial $readmemh(INIT_FILE, mem);

    assign idata = mem[iaddr];
    assign ddata = mem[daddr];

endmodule

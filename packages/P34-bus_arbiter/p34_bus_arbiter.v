// P34 Bus arbiter (CPU vs DMA)
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p34_bus_arbiter (
    input  wire dma_req,
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire cpu_we,
    input  wire [3:0] cpu_be,
    input  wire [31:0] dma_addr,
    input  wire [31:0] dma_wdata,
    input  wire dma_we,
    output wire grant,
    output wire stall,
    output wire [31:0] addr,
    output wire [31:0] wdata,
    output wire we,
    output wire [3:0] be
);

    assign grant = dma_req;
    assign stall = dma_req;
    assign addr = dma_req ? dma_addr : cpu_addr;
    assign wdata = dma_req ? dma_wdata : cpu_wdata;
    assign we = dma_req ? dma_we : cpu_we;
    assign be = dma_req ? 4'hF : cpu_be;

endmodule

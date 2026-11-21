// P66 Reset controller
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.

module p66_reset_ctrl (
    input  wire clk,
    input  wire btn,
    output wire rst
);

    reg [2:0] count;
    initial begin
    count = 3'd4;
    end

    always @(posedge clk) begin
        if (btn)
            count <= 3'd4;
        else if (count != 3'd0)
            count <= count - 3'd1;
    end

    assign rst = (count != 3'd0); 

endmodule



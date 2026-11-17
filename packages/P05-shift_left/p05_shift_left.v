// P05 Left barrel shifter
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p05_shift_left (
    input wire [31:0] a,
    input wire [4:0] sh,
    output wire [31:0] y
);

wire [31:0] s1, s2, s3, s4;

assign s1 = sh[0] ? (a << 1) : a;
assign s2 = sh[1] ? (s1 << 2) : s1;
assign s3 = sh[2] ? (s2 << 4) : s2;
assign s4 = sh[3] ? (s3 << 8) : s3;
assign y  = sh[4] ? (s4 << 16) : s4;

endmodule

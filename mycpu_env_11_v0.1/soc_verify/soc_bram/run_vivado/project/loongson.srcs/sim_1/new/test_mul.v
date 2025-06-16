`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 17:10:46
// Design Name: 
// Module Name: test_mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_mul;

reg [31:0] a,b;
reg clk;
reg reset;
reg ce;
wire [31:0] c;

initial
begin
    a = 32'h000001a0;
    b = 32'h02001000;
    reset = 0;
    clk = 0;
    ce = 0;
    #10
    ce = 1;
    #90
    $finish;
end

always #5
clk = ~clk;

mult_signed mul_1(
.CLK(clk),
.A(a),
.B(b),
.P(c)
);

endmodule

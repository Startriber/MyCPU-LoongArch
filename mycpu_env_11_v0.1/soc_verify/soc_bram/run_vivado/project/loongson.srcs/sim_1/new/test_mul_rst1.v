`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 20:48:22
// Design Name: 
// Module Name: test_mul_rst1
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


module test_mul_rst1;

reg [31:0] a,b;

initial begin
    a = 32'hd70d6000;
    b = 32'h000004f0;
    #500
    a = 32'h45b90738;
    b = 32'hd70d64f0;
end

wire [31:0] mul;
assign mul = $signed(a) * $signed(b);
endmodule

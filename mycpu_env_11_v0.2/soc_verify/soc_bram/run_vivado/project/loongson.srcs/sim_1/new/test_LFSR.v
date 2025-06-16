`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 08:58:12
// Design Name: 
// Module Name: test_LFSR
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


module test_LFSR;
reg clk,reset;
wire [7:0] random;

initial
begin
    reset = 1;
    clk = 0;
    #100
    reset = 0;
    #5000
    $finish;
end

always #5
clk = ~clk;

LFSR lsfr(
.clk(clk),
.reset(reset),
.random(random)
);

endmodule

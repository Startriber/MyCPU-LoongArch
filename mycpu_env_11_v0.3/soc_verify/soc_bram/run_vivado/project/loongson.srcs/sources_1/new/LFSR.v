`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 08:47:12
// Design Name: 
// Module Name: LFSR
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


module LFSR(
input wire clk,
input wire reset,
output reg [7:0] random
    );

wire reflection;

assign reflection = random[7] + ~(|random[6:0]);    

always@(posedge clk)
begin
    if(reset)
        random <= 8'hff;
    else
    begin
        random[0] <= reflection;
        random[1] <= random[0];
        random[2] <= random[1];
        random[3] <= random[2] ^ reflection;
        random[4] <= random[3];
        random[5] <= random[4] ^ reflection;
        random[6] <= random[5] ^ reflection;
        random[7] <= random[6];
    end
end
    
endmodule

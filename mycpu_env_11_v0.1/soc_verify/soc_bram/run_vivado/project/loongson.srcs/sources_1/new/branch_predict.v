`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 13:44:52
// Design Name: 
// Module Name: branch_predict
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


module branch_predict(
input wire reset,
input wire clk,
input wire [7:0] raddr,
input wire branch,
input wire [31:0] br_target,
input wire [7:0] waddr,
output wire prediction,
output wire [31:0] pre_br_target
    );
    
reg [255:0] pre_bit0,pre_bit1;
reg [31:0] predict_target [255:0];

assign prediction = pre_bit1[raddr];
assign pre_br_target = predict_target[raddr];

always@(posedge clk)
begin
    if(reset)
    begin
        pre_bit0 <= 256'h0;
        pre_bit1 <= 256'h0;
    end
    else
    begin
        pre_bit0[waddr] <= (~pre_bit0[waddr] & branch) || (pre_bit1[waddr] & pre_bit0[waddr] & branch) || (pre_bit1[waddr] & ~pre_bit0[waddr]);
        pre_bit1[waddr] <= ((pre_bit0[waddr] | pre_bit1[waddr]) & branch) || (pre_bit0[waddr] & pre_bit1[waddr] & ~branch) ;
    end
end

always@(posedge clk)
begin
    if(branch)
    begin
        predict_target[waddr] <= br_target;
    end
    else
    begin
        predict_target[waddr] <= predict_target[waddr];
    end
end
endmodule

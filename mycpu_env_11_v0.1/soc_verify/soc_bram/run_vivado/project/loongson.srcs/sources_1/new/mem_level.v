`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/08 16:27:50
// Design Name: 
// Module Name: mem_level
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


module mem_level(
    input wire                         clk           ,
    input wire                         reset         ,
    //allowin
    input wire                         wen           ,
    //from es
    input wire [75:                 0] es_to_ms_bus  ,
    //to ws
    output wire[106:                 0] ms_to_ws_bus  ,
    //from data-sram
    input  wire[31:                 0] data_sram_rdata,
	
	output wire [37:                0] ms_to_ds_bus,
	output wire                        ms_load_op
);


wire        ms_gr_we;
reg [75:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
wire        ms_ld_b;
wire        ms_ld_h;
wire        ms_ld_bu;
wire        ms_ld_hu;

assign {ms_load_op     ,
        ms_ld_b        ,
        ms_ld_h        ,
		ms_ld_bu       ,
		ms_ld_hu       ,

        ms_res_from_mem,  //70:70
        ms_gr_we    ,  //69:69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result;
wire [31:0] ms_final_result;

assign ms_to_ws_bus = {mem_result  ,
                       ms_ld_b     ,
                       ms_ld_h     ,
		               ms_ld_bu    ,
		               ms_ld_hu    ,

                       ms_res_from_mem,
                       ms_gr_we    ,  //69:69
                       ms_dest        ,  //68:64
                       ms_alu_result,  //63:32
                       ms_pc             //31:0
                      };
assign ms_to_ds_bus = {ms_gr_we    ,  
                       ms_dest        ,  
                       ms_alu_result};


always @(posedge clk) begin
    if (reset) begin
        es_to_ms_bus_r <= 76'h0;
    end
    else if (wen) begin
        es_to_ms_bus_r <= es_to_ms_bus;
    end
    else begin
        es_to_ms_bus_r <= es_to_ms_bus_r;
    end
end

assign mem_result = data_sram_rdata;


										 


endmodule


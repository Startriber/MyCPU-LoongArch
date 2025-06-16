/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/
`timescale 1ns / 1ps

`define TRACE_REF_FILE "../../../../../../../../gettrace/golden_trace.txt"
`define CONFREG_NUM_REG      soc_lite.u_confreg.num_data
`define CONFREG_OPEN_TRACE   soc_lite.u_confreg.open_trace
`define CONFREG_NUM_MONITOR  soc_lite.u_confreg.num_monitor
`define CONFREG_UART_DISPLAY soc_lite.u_confreg.write_uart_valid
`define CONFREG_UART_DATA    soc_lite.u_confreg.write_uart_data
`define END_PC 32'h1c000100

module tb_top( );
reg resetn;
reg clk;

//goio
wire [15:0] led;
wire [1 :0] led_rg0;
wire [1 :0] led_rg1;
wire [7 :0] num_csn;
wire [6 :0] num_a_g;
wire [7 :0] switch;
wire [3 :0] btn_key_col;
wire [3 :0] btn_key_row;
wire [1 :0] btn_step;
assign switch      = 8'hff;
assign btn_key_row = 4'd0;
assign btn_step    = 2'd3;

initial
begin
    $dumpfile("dump.vcd");
    $dumpvars;
    clk = 1'b0;
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
end
always #5 clk=~clk;
soc_lite_top #(.SIMULATION(1'b1)) soc_lite
(
       .resetn      (resetn     ), 
       .clk         (clk        ),
    
        //------gpio-------
        .num_csn    (num_csn    ),
        .num_a_g    (num_a_g    ),
        .led        (led        ),
        .led_rg0    (led_rg0    ),
        .led_rg1    (led_rg1    ),
        .switch     (switch     ),
        .btn_key_col(btn_key_col),
        .btn_key_row(btn_key_row),
        .btn_step   (btn_step   )
    );   

//soc lite signals
//"soc_clk" means clk in cpu
//"wb" means write-back stage in pipeline
//"rf" means regfiles in cpu
//"w" in "wen/wnum/wdata" means writing
wire soc_clk;

assign soc_clk           = soc_lite.cpu_clk;

wire [31:0] pc,pc_IF,pc_ID,pc_EX,pc_MEM;
wire [31:0] next_pc;
wire [31:0] ir,ir_IF;
wire load_stall,branch_cancel,calculate_stall,miss_stall;

wire miss;
wire [31:0] pc_r;
wire [19:0] tag,rtag0,rtag1;
wire choose_way0,choose_way1;

wire [19:0] wtag0,wtag1;
wire [3:0] wea_way0,wea_way1;
wire tag_valid0,tag_valid1;

wire [4:0] state;
wire [3:0] wea_r;
wire [31:0] addr_r;
wire [127:0] all_rdata_r;

wire [1:0] inside_addr;
wire inside_addr_eq_0,inside_addr_eq_1,inside_addr_eq_2,inside_addr_eq_3;

wire [31:0] rdata0_0,rdata0_1,rdata0_2,rdata0_3;
wire [31:0] rdata1_0,rdata1_1,rdata1_2,rdata1_3;

wire[31:0] inst_sram_rdata;
wire [31:0] inst_sram_addr;

wire         IF_IDreset;
wire         ID_EXreset;
wire         EX_MEMreset;
wire         MEM_WBreset;
wire gr_we,gr_we_ID,gr_we_EX;
wire [4:0] rj,rd,rkd;
wire [11:0] alu_op;
wire [31:0] real_data_rj,real_data_rkd;
wire [31:0] data_rj,data_rkd;
wire sel_ex_A,sel_ex_B;
wire sel_mem_A,sel_mem_B; 
wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] exrst,memrst;
wire [31:0] alu_rst,memdata,mem,wdata,wdata_MEM;
wire        rf_valid;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

assign pc = mycpu_top.pc;
assign pc_IF = id_level.ds_pc;
assign pc_ID = ex_level.es_pc;
assign pc_EX = mem_level.ms_pc;
assign pc_MEM = wb_level.ws_pc;

assign next_pc = mycpu_top.next_pc;

assign ir = mycpu_top.inst;
assign ir_IF = id_level.ds_inst;

assign load_stall = mycpu_top.load_stall;
assign branch_cancel = mycpu_top.branch_cancel;
assign calculate_stall = mycpu_top.calculate_stall;
assign miss_stall = mycpu_top.miss_stall;

assign miss = icache.miss;
assign pc_r = icache.pc_r;
assign tag = icache.tag;
assign rtag0 = icache.rtagv_0[20:1];
assign rtag1 = icache.rtagv_1[20:1];
assign choose_way0 = icache.choose_way0;
assign choose_way1 = icache.choose_way1;

assign wtag0 = icache.wtagv_0[20:1];
assign wtag1 = icache.wtagv_1[20:1];
assign wea_way0 = icache.wea_way0;
assign wea_way1 = icache.wea_way1;
assign tag_valid0 = icache.rtagv_0[0];
assign tag_valid1 = icache.rtagv_1[0];

assign state = icache.state;
assign wea_r = icache.wea_r;

assign all_rdata_r = icache.all_rdata_r;

assign inside_addr = icache.inside_addr;
assign inside_addr_eq_0 = icache.inside_addr_eq_0;
assign inside_addr_eq_1 = icache.inside_addr_eq_1;
assign inside_addr_eq_2 = icache.inside_addr_eq_2;
assign inside_addr_eq_3 = icache.inside_addr_eq_3;

assign rdata0_0 = icache.rdata0_0;
assign rdata0_1 = icache.rdata0_1;
assign rdata0_2 = icache.rdata0_2;
assign rdata0_3 = icache.rdata0_3;

assign rdata1_0 = icache.rdata1_0;
assign rdata1_1 = icache.rdata1_1;
assign rdata1_2 = icache.rdata1_2;
assign rdata1_3 = icache.rdata1_3;

assign inst_sram_rdata = soc_lite_top.cpu_inst_rdata;
assign inst_sram_addr = soc_lite_top.cpu_inst_addr;  

assign IF_IDreset = mycpu_top.IF_IDreset;
assign ID_EXreset = mycpu_top.ID_EXreset;
assign EX_MEMreset = mycpu_top.EX_MEMreset;
assign MEM_WBreset = mycpu_top.MEM_WBreset;

assign gr_we = id_level.gr_we;
assign gr_we_ID = ex_level.es_gr_we_in;
assign gr_we_EX = mem_level.ms_gr_we;

assign rj = id_level.rj;
assign rd = id_level.rd;
assign rkd = id_level.rkd;
assign alu_op = id_level.alu_op;
assign real_data_rj = regfile.rf[rj];
assign real_data_rkd = regfile.rf[rkd];
assign data_rj = id_level.rj_value;
assign data_rkd = id_level.rkd_value;
assign sel_ex_A = id_level.sel_ex_A;
assign sel_ex_B = id_level.sel_ex_B;
assign sel_mem_A = id_level.sel_mem_A;
assign sel_mem_B = id_level.sel_mem_B;
assign es_alu_src1 = ex_level.es_alu_src1;
assign es_alu_src2 = ex_level.es_alu_src2;
assign exrst = mycpu_top.es_to_ds_value;
assign memrst = id_level.ms_to_ds_value;
assign alu_rst = ex_level.es_result;
assign memdata = mem_level.mem_result;
assign mem = wb_level.mem;
assign wdata = mem_level.ms_final_result;
assign wdata_MEM = wb_level.ws_final_result;

assign rf_valid = mycpu_top.rf_valid;
assign rf_we = id_level.rf_we;
assign rf_waddr = id_level.rf_waddr;
assign rf_wdata = id_level.rf_wdata;

wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_we;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;

assign debug_wb_pc       = soc_lite.debug_wb_pc;
assign debug_wb_rf_we    = soc_lite.debug_wb_rf_we;
assign debug_wb_rf_wnum  = soc_lite.debug_wb_rf_wnum;
assign debug_wb_rf_wdata = soc_lite.debug_wb_rf_wdata;

// open the trace file;
integer trace_ref;
initial begin
    trace_ref = $fopen(`TRACE_REF_FILE, "r");
end

//get reference result in falling edge
reg        trace_cmp_flag;
reg        debug_end;

reg [31:0] ref_wb_pc;
reg [4 :0] ref_wb_rf_wnum;
reg [31:0] ref_wb_rf_wdata;

integer a;
always @(posedge soc_clk)
begin 
    #1;
    if(|debug_wb_rf_we && debug_wb_rf_wnum!=5'd0 && !debug_end && `CONFREG_OPEN_TRACE)
    begin
        trace_cmp_flag=1'b0;
        while (!trace_cmp_flag && !($feof(trace_ref)))
        begin
            a = $fscanf(trace_ref, "%h %h %h %h", trace_cmp_flag,
                    ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
        end
    end
end

//wdata[i*8+7 : i*8] is valid, only wehile wen[i] is valid
wire [31:0] debug_wb_rf_wdata_v;
wire [31:0] ref_wb_rf_wdata_v;
assign debug_wb_rf_wdata_v[31:24] = debug_wb_rf_wdata[31:24] & {8{debug_wb_rf_we[3]}};
assign debug_wb_rf_wdata_v[23:16] = debug_wb_rf_wdata[23:16] & {8{debug_wb_rf_we[2]}};
assign debug_wb_rf_wdata_v[15: 8] = debug_wb_rf_wdata[15: 8] & {8{debug_wb_rf_we[1]}};
assign debug_wb_rf_wdata_v[7 : 0] = debug_wb_rf_wdata[7 : 0] & {8{debug_wb_rf_we[0]}};
assign   ref_wb_rf_wdata_v[31:24] =   ref_wb_rf_wdata[31:24] & {8{debug_wb_rf_we[3]}};
assign   ref_wb_rf_wdata_v[23:16] =   ref_wb_rf_wdata[23:16] & {8{debug_wb_rf_we[2]}};
assign   ref_wb_rf_wdata_v[15: 8] =   ref_wb_rf_wdata[15: 8] & {8{debug_wb_rf_we[1]}};
assign   ref_wb_rf_wdata_v[7 : 0] =   ref_wb_rf_wdata[7 : 0] & {8{debug_wb_rf_we[0]}};


//compare result in rsing edge 
reg debug_wb_err;
always @(posedge soc_clk)
begin
    #2;
    if(!resetn)
    begin
        debug_wb_err <= 1'b0;
    end
    else if(|debug_wb_rf_we && debug_wb_rf_wnum!=5'd0 && !debug_end && `CONFREG_OPEN_TRACE)
    begin
        if (  (debug_wb_pc!==ref_wb_pc) || (debug_wb_rf_wnum!==ref_wb_rf_wnum)
            ||(debug_wb_rf_wdata_v!==ref_wb_rf_wdata_v) )
        begin
            $display("--------------------------------------------------------------");
            $display("[%t] Error!!!",$time);
            $display("    reference: PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                      ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata_v);
            $display("    mycpu    : PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                      debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata_v);
            $display("--------------------------------------------------------------");
            debug_wb_err <= 1'b1;
            #40;
            $finish;
        end
    end
end

//monitor numeric display
reg [7:0] err_count;
wire [31:0] confreg_num_reg = `CONFREG_NUM_REG;
reg  [31:0] confreg_num_reg_r;
always @(posedge soc_clk)
begin
    confreg_num_reg_r <= confreg_num_reg;
    if (!resetn)
    begin
        err_count <= 8'd0;
    end
    else if (confreg_num_reg_r != confreg_num_reg && `CONFREG_NUM_MONITOR)
    begin
        if(confreg_num_reg[7:0]!=confreg_num_reg_r[7:0]+1'b1)
        begin
            $display("--------------------------------------------------------------");
            $display("[%t] Error(%d)!!! Occurred in number 8'd%02d Functional Test Point!",$time, err_count, confreg_num_reg[31:24]);
            $display("--------------------------------------------------------------");
            err_count <= err_count + 1'b1;
        end
        else if(confreg_num_reg[31:24]!=confreg_num_reg_r[31:24]+1'b1)
        begin
            $display("--------------------------------------------------------------");
            $display("[%t] Error(%d)!!! Unknown, Functional Test Point numbers are unequal!",$time,err_count);
            $display("--------------------------------------------------------------");
            $display("==============================================================");
            err_count <= err_count + 1'b1;
        end
        else
        begin
            $display("----[%t] Number 8'd%02d Functional Test Point PASS!!!", $time, confreg_num_reg[31:24]);
        end
    end
end

//monitor test
initial
begin
    $timeformat(-9,0," ns",10);
    while(!resetn) #5;
    $display("==============================================================");
    $display("Test begin!");

    #10000;
    while(`CONFREG_NUM_MONITOR)
    begin
        #10000;
        $display ("        [%t] Test is running, debug_wb_pc = 0x%8h",$time, debug_wb_pc);
    end
end

//模拟串口打印
wire uart_display;
wire [7:0] uart_data;
assign uart_display = `CONFREG_UART_DISPLAY;
assign uart_data    = `CONFREG_UART_DATA;

always @(posedge soc_clk)
begin
    if(uart_display)
    begin
        if(uart_data==8'hff)
        begin
            ;//$finish;
        end
        else
        begin
            $write("%c",uart_data);
        end
    end
end

//test end
wire global_err = debug_wb_err || (err_count!=8'd0);
wire test_end = (debug_wb_pc==`END_PC) || (uart_display && uart_data==8'hff);
always @(posedge soc_clk)
begin
    if (!resetn)
    begin
        debug_end <= 1'b0;
    end
    else if(test_end && !debug_end)
    begin
        debug_end <= 1'b1;
        $display("==============================================================");
        $display("Test end!");
        #40;
        $fclose(trace_ref);
        if (global_err)
        begin
            $display("Fail!!!Total %d errors!",err_count);
        end
        else
        begin
            $display("----PASS!!!");
        end
	    $finish;
	end
end
endmodule

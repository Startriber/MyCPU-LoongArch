module alu(
  input  [11:0] alu_op,
  input  [31:0] alu_src1,
  input  [31:0] alu_src2,
  output [31:0] alu_result
);


wire [31:0] add_sub_result;
wire [31:0] and_result;
wire [31:0] or_result;
wire [31:0] nor_result;
wire [31:0] xor_result;
wire [31:0] sll_result;
wire [31:0] sr_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] lui_result;

wire [63:0] sr64_result;



// 32-bit adder
wire [31:0] a;
wire [31:0] b;
wire cin;
wire cout;
wire zf;

assign cin = alu_op[1] | alu_op[9] | alu_op[10];
assign a   = alu_src1;
assign b   = cin ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk

// ADD, SUB result
assign {cout,add_sub_result} = a + b + cin;
assign zf = ~(|add_sub_result);

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << i5

// SRL, SRA result

assign sr_result   = {{32{alu_op[8] & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0];

// SLT result
assign slt_result = {31'b0,(alu_src1[31] & ~alu_src2[31]) | (~(alu_src1[31] ^ alu_src2[31]) & add_sub_result[31])};

// SLTU result
assign sltu_result = {31'b0,~cout};

assign lui_result = alu_src2;


// final result mux
assign alu_result = ({32{alu_op[0]|alu_op[1]}} & add_sub_result)
                  | ({32{alu_op[2]          }} & and_result)
                  | ({32{alu_op[3]          }} & or_result)
                  | ({32{alu_op[4]          }} & nor_result)
                  | ({32{alu_op[5]          }} & xor_result)
                  | ({32{alu_op[6]          }} & sll_result)
                  | ({32{alu_op[7]|alu_op[8]}} & sr_result)
                  | ({32{alu_op[9]          }} & slt_result)
                  | ({32{alu_op[10]         }} & sltu_result)
                  | ({32{alu_op[11]         }} & lui_result);

endmodule

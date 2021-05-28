`timescale 1ns/1ps

module tomasulo_tb;

reg CLK;

//reg [2:0] Pr_Tag;
//reg [31:0] Pr_result;

wire [2:0] Pr_Instr;
wire [31:0] Pr_sv1, Pr_sv2;
wire [11:0] Pr_immediate, Pr_offset;
wire [2:0] Pr_reg_Tag, Pr_tag;
wire [31:0] Pr_ROB_value;
wire [31:0] Pr_result;
wire [4:0] Pr_rs1, Pr_rs2, Pr_rd;
//wire [4:0] 
tomasulo uut (CLK);//(CLK,Pr_sv1,Pr_sv2,Pr_tag,Pr_offset,Pr_Instr);

initial
begin
    CLK=1;
end

always #5 CLK = ~CLK ;

endmodule
`timescale 1ns/1ps

module verilator_top (
    input clk
);

    // reg CLK;

    //reg [2:0] Pr_Tag;
    //reg [31:0] Pr_result;

    reg [7:0] clk_counter;

    wire [2:0] Pr_Instr;
    wire [31:0] Pr_sv1, Pr_sv2;
    wire [11:0] Pr_immediate, Pr_offset;
    wire [2:0] Pr_reg_Tag, Pr_tag;
    wire [31:0] Pr_ROB_value;
    wire [31:0] Pr_result;
    wire [4:0] Pr_rs1, Pr_rs2, Pr_rd;
    //wire [4:0] 

    Tomasulo uut (clk);//(CLK,Pr_sv1,Pr_sv2,Pr_tag,Pr_offset,Pr_Instr);
    // initial
    // begin
    //     CLK=1;
    // end
    // always #5 CLK = ~CLK ;

    always @(posedge clk ) begin
        clk_counter <= clk_counter + 1;
        if (clk_counter == 20) begin
            $finish;
        end    
    end

    

endmodule
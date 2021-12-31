`timescale 1ns/1ps

module Tomasulo (
    input clk,
    input reset
);
    
reg [31:0] memory [0:31];
initial 
begin
    counter = 0;
    memory[0] = 32'h002200b3; // R1
    memory[1] = 32'h00120133; // R2
    memory[2] = 32'h00520333; // R6
    memory[3] = 32'h006202b3; // R5
end


/* =====================================
    INFO: fetch stage rgisters
===================================== */

// fetch stage registers
reg [5:0]   PC;
integer     x;
reg [6:0]   counter;
reg [31:0]  pr_instr_fetch;  // Pipeline register of Fetch stage
reg         stall_flag;

always @(posedge clk) begin 
    if (reset) begin 
        x <= 0;
        PC <= 5'b00000;
        pr_instr_fetch <= 0;
    end else begin 
        counter <= counter + 1;
        pr_instr_fetch <= memory[x];
        // Info: executes the system in a tight loop
        if(stall_flag==0) begin
            PC <= PC+4;
            if (x != 3) begin
                x <= x + 1;
            end else begin
                // PC<=0;
                x <= 0;
            end
        end
    end
end

/* =====================================
    INFO: decode stage registers
===================================== */
reg [2:0] pr_instr;               // Tells what type of instruction it is after decoding
reg [6:0] pr_funct7, pr_opcode;   // pipeline registers for Decode Stage
reg [4:0] pr_rs1, pr_rs2, pr_rd;
reg [2:0] pr_funct3;
reg [11:0] pr_immediate;
reg [4:0] Decode_PC;

parameter ADD = 3'b001;
parameter SUB = 3'b010;
parameter MUL = 3'b011;
parameter DIV = 3'b100;
parameter LOAD = 3'b101;


always @(posedge clk) begin
    if (reset) begin 
        pr_instr <= 0;
        Decode_PC <= 0;
    end else begin 
        Decode_PC <= PC;
        // Info: always the current instruction
        pr_opcode = pr_instr_fetch[6:0];   
        pr_funct7 = pr_instr_fetch[31:25];
        pr_funct3 = pr_instr_fetch[14:12];
        pr_rs2 <= pr_instr_fetch[24:20];
        pr_immediate <= pr_instr_fetch[31:20];
        pr_rs1 <= pr_instr_fetch[19:15];
        pr_rd <= pr_instr_fetch[11:7];
        
        if(pr_opcode==7'b0000011)
            pr_instr<=LOAD;
        else if ((pr_opcode==7'b0110011) && (pr_funct7==7'b0000000))
            pr_instr<=ADD;
        else if ((pr_opcode==7'b0110011) && (pr_funct7==7'b0100000))
            pr_instr<=SUB;
        else if ((pr_opcode==7'b0110011) && (pr_funct7==7'b0000001) && (pr_funct3==3'b000))
            pr_instr<=MUL;
        else if ((pr_opcode==7'b0110011) && (pr_funct7==7'b0000001) && (pr_funct3==3'b100))
            pr_instr<=DIV;
        else
            pr_instr<=3'b000;
    end
end

/* ====================================================
    INFO: reorder buffer/reservation station registers
==================================================== */

reg [31:0] Arch_reg [1:32];            //Defining Architectural Registers
reg [3:0] RAT [1:32];                  //Defining the RAT

reg [2:0] ROB_head_ptr;                //ROB Head Pointer
reg [2:0] ROB_tail_ptr;                //ROB Tail Pointer
reg [2:0] ROB_Instr [0:7];            //Defining ROB entries
reg [4:0] ROB_Dest [0:7];
reg [31:0] ROB_Value [0:7];
reg ROB_busy [0:7];
reg ROB_valid[0:7];
reg [4:0] ROB_PC [0:7];

reg [2:0] RS_Add_Instr [0:3];         //Defining RS_ADD/SUB entries
reg RS_Add_busy [0:3];
reg [2:0] RS_Add_Dest_tag [0:3];
reg [2:0] RS_Add_S1_tag [0:3];
reg [2:0] RS_Add_S2_tag [0:3];
reg [31:0] RS_Add_S1_value [0:3];
reg RS_Add_S1_valid [0:3];
reg [31:0] RS_Add_S2_value [0:3];
reg RS_Add_S2_valid [0:3];
reg [1:0] RS_Add_count;
reg [4:0] RS_Add_PC [0:3];

always @(posedge clk) begin
    if (reset) begin 
        Arch_reg[1]=32'h0000000c; 
        Arch_reg[2]=32'h00000010; 
        Arch_reg[3]=32'h0000002d; 
        Arch_reg[4]=32'h00000005; 
        Arch_reg[5]=32'h00000003; 
        Arch_reg[6]=32'h00000004; 
        Arch_reg[7]=32'h00000001; 
        Arch_reg[8]=32'h00000002; 
        Arch_reg[9]=32'h00000002; 
        Arch_reg[10]=32'h00000003;
    
    end
end



/* ================================================================
    INFO: logic for the ROB
================================================================ */

always @(posedge clk) begin
    if (reset) begin 
        stall_flag = 0;
        ROB_head_ptr<=3'b000;
        ROB_tail_ptr<=3'b000;    
        // todo: move to RS/ROB
        ROB_Instr[0]=0;
        ROB_Instr[1]=0;
        ROB_Instr[2]=0;
        ROB_Instr[3]=0;
        ROB_Instr[4]=0;
        ROB_Instr[5]=0;
        ROB_Instr[6]=0;
        ROB_Instr[7]=0;
        // pushed to end
        ROB_busy[0]<=0;
        ROB_busy[1]<=0;
        ROB_busy[2]<=0;
        ROB_busy[3]<=0;
        ROB_busy[4]<=0;
        ROB_busy[5]<=0;
        ROB_busy[6]<=0;
        ROB_busy[7]<=0;
        // todo: move to RS/ROB
        ROB_valid[0]<=0;
        ROB_valid[1]<=0;
        ROB_valid[2]<=0;
        ROB_valid[3]<=0;
        ROB_valid[4]<=0;
        ROB_valid[5]<=0;
        ROB_valid[6]<=0;
        ROB_valid[7]<=0;
        // INFO: register retagging table
        RAT[1]<=4'b1000;     
        RAT[2]<=4'b1000;   
        RAT[3]<=4'b1000;     
        RAT[4]<=4'b1000;     
        RAT[5]<=4'b1000;    
        RAT[6]<=4'b1000;     
        RAT[7]<=4'b1000;
        RAT[8]<=4'b1000;
        RAT[9]<=4'b1000;
        RAT[10]<=4'b1000;
    end else begin 
        if(ROB_busy[ROB_tail_ptr] == 1)
            // stall if the tail of ROB is filled: stall only stalls increment of 'x/PC'
            stall_flag = 1;
        else begin
            if ((pr_instr==ADD) || (pr_instr==SUB)) begin
                if (RS_Add_busy[RS_Add_count] == 1) begin
                    stall_flag = 1;
                end else begin
                    stall_flag = 0;
                    ROB_Instr[ROB_tail_ptr]<=pr_instr;
                    ROB_PC[ROB_tail_ptr]<=Decode_PC;
                    ROB_Dest[ROB_tail_ptr]<=pr_rd;
                    ROB_busy[ROB_tail_ptr]<=1;
                    // todo: check pushed to end: now pulled from end
                    RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                    ROB_tail_ptr<=ROB_tail_ptr+3'b001;  
                end 
            end
        end

        if (pr_Add_Sub_result_valid==1) begin
            ROB_valid[pr_Add_Sub_Tag]<=1; 
        end
    
        // ? note reqally required
        if (ROB_valid[ROB_head_ptr]==1) begin
            // ROB_Instr[ROB_head_ptr]<=3'b000;
            // ROB_Value[ROB_head_ptr]<=32'bx;
            // ROB_Dest[ROB_head_ptr]<=5'bx;
            ROB_busy[ROB_head_ptr]<=0;
            // if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 1)) begin
                
            //     ROB_busy[ROB_tail_ptr]<=1;
            // end else ROB_busy[ROB_head_ptr]<=0;
            ROB_valid[ROB_head_ptr]<=0;
            ROB_head_ptr<=ROB_head_ptr+1;  
            
            // RAT resetting
            if (RAT[ROB_Dest[ROB_head_ptr]]=={1'b0, ROB_head_ptr}) begin
                RAT[ROB_Dest[ROB_head_ptr]]<=4'b1000;
                // ! was pulled here
                // if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 0)) begin
                //     RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                // end
            end 
            // else if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 0)) begin
            //         RAT[pr_rd]<={1'b0, ROB_tail_ptr};
            // end
        end
    end
end


/* ================================================================
    INFO: logic for the RS for Add_Sub
================================================================ */

// ! changes registers related to the reservation stations

always @(posedge clk) begin
    if (reset) begin 
        RS_Add_count<=2'b00;
        RS_Add_S1_valid [0]<=0;      RS_Add_S2_valid [0]<=0;    RS_Add_PC[0]<=0;
        RS_Add_S1_valid [1]<=0;      RS_Add_S2_valid [1]<=0;    RS_Add_PC[1]<=0;
        RS_Add_S1_valid [2]<=0;      RS_Add_S2_valid [2]<=0;    RS_Add_PC[2]<=0;
        RS_Add_S1_valid [3]<=0;      RS_Add_S2_valid [3]<=0;    RS_Add_PC[3]<=0;

        RS_Add_busy[0]<=0;
        RS_Add_busy[1]<=0;
        RS_Add_busy[2]<=0;
        RS_Add_busy[3]<=0;
        
    end else begin 
        if ((ROB_busy[ROB_tail_ptr] != 1) && ((pr_instr==ADD) || (pr_instr==SUB))) begin 
            if (RS_Add_busy[RS_Add_count] == 1) begin
                // stall_flag = 1;
                RS_Add_count <= RS_Add_count+2'b01;
            end else begin 
                RS_Add_Instr[RS_Add_count]<=pr_instr;
                RS_Add_PC[RS_Add_count]<=Decode_PC;
                // TODO: reconcile
                RS_Add_busy[RS_Add_count]<=1'b1;
                RS_Add_Dest_tag[RS_Add_count]<=ROB_tail_ptr;
                if (RAT[pr_rs1]==4'b1000) begin
                    RS_Add_S1_value[RS_Add_count]<=Arch_reg[pr_rs1];
                    RS_Add_S1_valid[RS_Add_count]<=1;
                end else begin  
                    RS_Add_S1_tag[RS_Add_count]<=RAT[pr_rs1][2:0];
                    RS_Add_S1_valid[RS_Add_count]<=1'b0;
                end 
                if (RAT[pr_rs2]==4'b1000) begin 
                    RS_Add_S2_value[RS_Add_count]<=Arch_reg[pr_rs2];
                    RS_Add_S2_valid[RS_Add_count]<=1;
                end else begin  
                    RS_Add_S2_tag[RS_Add_count]<=RAT[pr_rs2][2:0];
                    RS_Add_S2_valid[RS_Add_count]<=1'b0;
                end 
                RS_Add_count <= RS_Add_count+2'b01; 
            end
        end
        
        if (RS_Add_S1_valid[0]==1 && RS_Add_S2_valid[0]==1 && RS_Add_busy[0]==1) begin
            RS_Add_busy[0]<=1'b0;
            RS_Add_S1_valid[0]<=0;
            RS_Add_S2_valid[0]<=0;
        end else if (RS_Add_S1_valid[1]==1 && RS_Add_S2_valid[1]==1 && RS_Add_busy[1]==1) begin 
            RS_Add_busy[1]<=1'b0;
            RS_Add_S1_valid[1]<=0;
            RS_Add_S2_valid[1]<=0;
        end else if (RS_Add_S1_valid[2]==1 && RS_Add_S2_valid[2]==1 && RS_Add_busy[2]==1) begin 
            RS_Add_busy[2]<=1'b0;
            RS_Add_S1_valid[2]<=0;
            RS_Add_S2_valid[2]<=0;
        end else if (RS_Add_S1_valid[3]==1 && RS_Add_S2_valid[3]==1 && RS_Add_busy[3]==1) begin 
            RS_Add_busy[3]<=1'b0;
            RS_Add_S1_valid[3]<=0;
            RS_Add_S2_valid[3]<=0;
        end

        // =======================================================
        // INFO: from the writeback stage: includes bypassing to RSes
        // =======================================================
        if (pr_Add_Sub_result_valid) begin
            if(RS_Add_S1_tag[0]==pr_Add_Sub_Tag && RS_Add_busy[0] && !RS_Add_S1_valid[0])
            begin
                RS_Add_S1_value[0]<=pr_Add_Sub_result;
                RS_Add_S1_valid[0]<=1;
                // RS_Add_S1_tag[0]<=3'bxxx;
            end
            if(RS_Add_S2_tag[0] == pr_Add_Sub_Tag && RS_Add_busy[0] && !RS_Add_S2_valid[0])
            begin
                RS_Add_S2_value[0]<=pr_Add_Sub_result;
                RS_Add_S2_valid[0]<=1;
                // RS_Add_S2_tag[0]<=3'bxxx;
            end
            if(RS_Add_S1_tag[1]==pr_Add_Sub_Tag && RS_Add_busy[1] && !RS_Add_S1_valid[1])
            begin
                RS_Add_S1_value[1]<=pr_Add_Sub_result;
                RS_Add_S1_valid[1]<=1;
                // RS_Add_S1_tag[1]<=3'bxxx;
            end
            if(RS_Add_S2_tag[1]==pr_Add_Sub_Tag && RS_Add_busy[1] && !RS_Add_S2_valid[1])
            begin
                RS_Add_S2_value[1]<=pr_Add_Sub_result;
                RS_Add_S2_valid[1]<=1;
                // RS_Add_S2_tag[1]<=3'bxxx;
            end
            if(RS_Add_S1_tag[2]==pr_Add_Sub_Tag && RS_Add_busy[2] && !RS_Add_S1_valid[2])
            begin
                RS_Add_S1_value[2]<=pr_Add_Sub_result;
                RS_Add_S1_valid[2]<=1;
                // RS_Add_S1_tag[2]<=3'bxxx;
            end
            if(RS_Add_S2_tag[2]==pr_Add_Sub_Tag && RS_Add_busy[2] && !RS_Add_S2_valid[2])
            begin
                RS_Add_S2_value[2]<=pr_Add_Sub_result;
                RS_Add_S2_valid[2]<=1;
                // RS_Add_S2_tag[2]<=3'bxxx;
            end
            if(RS_Add_S1_tag[3]==pr_Add_Sub_Tag && RS_Add_busy[3] && !RS_Add_S1_valid[3])
            begin
                RS_Add_S1_value[3]<=pr_Add_Sub_result;
                RS_Add_S1_valid[3]<=1;
                // RS_Add_S1_tag[3]<=3'bxxx;
            end
            if(RS_Add_S2_tag[3]==pr_Add_Sub_Tag && RS_Add_busy[3] && !RS_Add_S2_valid[3])
            begin
                RS_Add_S2_value[3]<=pr_Add_Sub_result;
                RS_Add_S2_valid[3]<=1;
                // RS_Add_S2_tag[3]<=3'bxxx;
            end
        end

    end
end


/* ================================
    INFO: issue and execute
================================ */

reg [31:0] pr_Add_Sub_sv1, pr_Add_Sub_sv2;  // , pr_sv1, pr_Add_Sub_sv2,pr_Mul_Div_sv1,pr_Mul_Div_sv2;  //Pipeline registers for Issue stage
reg [2:0] pr_Add_Sub_tag;   // , pr_LD_tag, pr_Mul_Div_tag;
reg [11:0] pr_offset;
reg [2:0] pr_Add_Sub_Instr; // , pr_LD_Instr, pr_Mul_Instr, pr_Div_Instr;
reg [4:0] pr_Add_Sub_PC;    // , pr_Mul_PC, pr_Div_PC;

/* ========== Issue =========*/

// ! handles the pipeline registers for the issue (input/opcode) and execute (result/valid) stages

always @(posedge clk) begin 
    if (reset) begin 
        // moved to later (execute stage)
        // pr_Add_Sub_result_valid=0;
        // pr_Mul_Div_result_valid=0; 
        // pr_LD_result_valid=0; 
        pr_Add_Sub_PC<=0; 
        // pr_Mul_Div_result_PC=0;
        // pr_sv1=0; 
        pr_Add_Sub_sv1<=0;
        pr_Add_Sub_sv2<=0;
        // pr_Mul_Div_sv1=0;
        // pr_Mul_Div_sv2=0;
        pr_Add_Sub_tag<=0;
        pr_Add_Sub_Instr<=0;
    end else begin
        if(RS_Add_S1_valid[0]==1 && RS_Add_S2_valid[0]==1 && RS_Add_busy[0]==1) begin
            pr_Add_Sub_sv1<=RS_Add_S1_value[0];
            pr_Add_Sub_sv2<=RS_Add_S2_value[0];
            pr_Add_Sub_tag<=RS_Add_Dest_tag[0];
            pr_Add_Sub_Instr<=RS_Add_Instr[0];
            pr_Add_Sub_PC<=RS_Add_PC[0];
        end else if(RS_Add_S1_valid[1]==1 && RS_Add_S2_valid[1]==1 && RS_Add_busy[1]==1) begin
            pr_Add_Sub_sv1<=RS_Add_S1_value[1];
            pr_Add_Sub_sv2<=RS_Add_S2_value[1];
            pr_Add_Sub_tag<=RS_Add_Dest_tag[1];
            pr_Add_Sub_Instr<=RS_Add_Instr[1];
            pr_Add_Sub_PC<=RS_Add_PC[1];        
        end else if(RS_Add_S1_valid[2]==1 && RS_Add_S2_valid[2]==1 && RS_Add_busy[2]==1) 
        begin
            pr_Add_Sub_sv1<=RS_Add_S1_value[2];
            pr_Add_Sub_sv2<=RS_Add_S2_value[2];
            pr_Add_Sub_tag<=RS_Add_Dest_tag[2];
            pr_Add_Sub_Instr<=RS_Add_Instr[2];
            pr_Add_Sub_PC<=RS_Add_PC[2];
        end
        else if(RS_Add_S1_valid[3]==1 && RS_Add_S2_valid[3]==1 && RS_Add_busy[3]==1) 
        begin
            pr_Add_Sub_sv1<=RS_Add_S1_value[3];
            pr_Add_Sub_sv2<=RS_Add_S2_value[3];
            pr_Add_Sub_tag<=RS_Add_Dest_tag[3];
            pr_Add_Sub_Instr<=RS_Add_Instr[3];
            pr_Add_Sub_PC<=RS_Add_PC[3];
        end else begin
            pr_Add_Sub_Instr<=0;
        end        
    end
end

// ============= EXECUTE STAGE =============

reg [31:0] pr_Add_Sub_result;   // , pr_Mul_Div_result, pr_LD_result;
reg [2:0] pr_Add_Sub_Tag;       // , pr_Mul_Div_Tag, pr_LD_Tag;
reg pr_Add_Sub_result_valid;    // , pr_Mul_Div_result_valid, pr_LD_result_valid;
reg [4:0] pr_Add_Sub_result_PC; // , pr_Mul_Div_result_PC;

// reg [31:0] Mem [1:32];
// reg [31:0] EAD;
// reg [31:0] Sign_Extented_Offset;
// reg [319:0] Shift_Mul;       reg [29:0] Shift_Mul_tag ;
// reg [1279:0] Shift_Div;      reg [119:0] Shift_Div_tag ;
// reg [159:0] Shift_LD_ST;     reg [14:0] Shift_LD_ST_tag;

// reg [39:0] Shift_Div_valid ;
// reg [9:0] Shift_Mul_valid ;
// reg [4:0] Shift_LD_ST_valid ;

reg [31:0] add1, add2, sub1, sub2;  // , mul1, mul2, div1, div2;


always @(posedge clk) begin 
    if (reset) begin 
        pr_Add_Sub_result_valid<=0;
        // ! note that this is the tag from the execute stage not the issue stage
        pr_Add_Sub_Tag<=0;
        // pr_Mul_Div_result_valid=0; 
        // pr_LD_result_valid=0; 
        pr_Add_Sub_result_PC<=0; 
        // pr_Mul_Div_result_PC=0; 
    end else begin 
        if (pr_Add_Sub_Instr==ADD) begin
            add1=pr_Add_Sub_sv1; add2=pr_Add_Sub_sv2;
            pr_Add_Sub_result <= add1+add2;
            pr_Add_Sub_result_valid<=1;
            pr_Add_Sub_result_PC<=pr_Add_Sub_PC;
            // add1=32'hx; add2=32'hx;
            pr_Add_Sub_Tag<=pr_Add_Sub_tag;
            // pr_Add_Sub_Instr<=0;
        end else if (pr_Add_Sub_Instr==SUB) begin
            sub1=pr_Add_Sub_sv1; sub2=pr_Add_Sub_sv2;
            pr_Add_Sub_result<= sub1 - sub2;
            pr_Add_Sub_result_valid<=1;
            pr_Add_Sub_result_PC<=pr_Add_Sub_PC;
            // sub1=32'hx; sub2=32'hx;
            pr_Add_Sub_Tag<=pr_Add_Sub_tag;
            // pr_Add_Sub_Instr<=3'bxxx;
        end else begin
            pr_Add_Sub_result_valid<=0;
        end
    end 
end

/* ================================================================ 
    INFO: writeback stage: includes bypassing to RSes
================================================================ */

reg [4:0] WB_Add_Sub_PC;    // , WB_Mul_Div_PC;

always @(posedge clk) begin 
    if (reset) begin 
        WB_Add_Sub_PC<=0;
    end else begin 
        if (pr_Add_Sub_result_valid==1) begin
            ROB_Value[pr_Add_Sub_Tag]<=pr_Add_Sub_result;
            // ! moved to the ROB section earlier
            // ROB_valid[pr_Add_Sub_Tag]<=1; 
            // pr_Add_Sub_result_valid<=0;
            WB_Add_Sub_PC<=pr_Add_Sub_result_PC;     
        end
    end
end

/* ==============================
    INFO: commit stage
============================== */

reg [4:0] Commit_PC;

always@(posedge clk)
begin
    if (reset) begin 
        Commit_PC<=0;
    end else if (ROB_valid[ROB_head_ptr]==1) begin
        Commit_PC<=ROB_PC[ROB_head_ptr];
        Arch_reg[ROB_Dest[ROB_head_ptr]]<=ROB_Value[ROB_head_ptr];
        
        // ! moved to the ROB section earlier
        // if (RAT[ROB_Dest[ROB_head_ptr]]=={1'b0, ROB_head_ptr}) begin
        //     RAT[ROB_Dest[ROB_head_ptr]]<=4'b1000;
        //     // ! pulled here
        //     if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 0)) begin
        //         RAT[pr_rd]<={1'b0, ROB_tail_ptr};
        //     end
        // end else if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 0)) begin
        //     RAT[pr_rd]<={1'b0, ROB_tail_ptr};
        // end
        
        // ROB_Instr[ROB_head_ptr]<=3'b000;
        // // ROB_Value[ROB_head_ptr]<=32'bx;
        // // ROB_Dest[ROB_head_ptr]<=5'bx;
        // if ((pr_instr==ADD || pr_instr==SUB) && (RS_Add_busy[RS_Add_count] == 1)) begin
        //     ROB_busy[ROB_head_ptr]<=0;
        //     ROB_busy[ROB_tail_ptr]<=1;
        // end else ROB_busy[ROB_head_ptr]<=0;
        // ROB_valid[ROB_head_ptr]<=0;
        // ROB_head_ptr<=ROB_head_ptr+1;  
    end
end
    `include "formal.v"
endmodule


 //---------------------------------------------INSTRUCTION FETCH STAGE------------------------------------------------------

//LW R3, 0(R2)
//DIV R2,R3,R4
//MUL R1,R5,R6
//ADD R3,R7,R8
//MUL R1,R1,R3
//SUB R4,R1,R5
//ADD R1,R4,R2

//R-Format: funct7(7)  rs1(5)  rs2(5)  funct3(3)  rd(5)  opcode(7)
//Load/Stores: Immediate(12)  rs(5)  funct3(3)  rd(5)  opcode(7)

module Tomasulo (clk);

input clk;
reg stall_flag;
reg [31:0] pr_instr_fetch; //Pipeline register of Fetch stage
reg [4:0] PC;              //Program Counter

reg [31:0] memory [0:31];         //Main Memory

integer x;

reg [7:0] counter;

initial 
begin
    counter = 0;

    memory[0] = 32'h002200b3; // R1
    memory[1] = 32'h00120133; // R2
    memory[2] = 32'h00520333; // R6
    memory[3] = 32'h006202b3; // R5
    // memory[1] = 32'h002200b3;
    // memory[2] = 32'h002200b3;
    // memory[3] = 32'h00120133;
    // memory[4] = 32'h002200b3;
    // memory[5] = 32'h00120133;
    // memory[6] = 32'h002200b3;
    // 000000000000 00010 010 00011 0000011
    // memory[0]=32'h00012183;           //Instructions stored in Main Memory
    // memory[1]=32'h0241c133;
    // memory[2]=32'h026280b3;
    // memory[3]=32'h008381b3;
    // memory[4]=32'h023080b3;
    // memory[5]=32'h40508233;
    // ADD R1,R4,R2:    0000000 00010 00100 000 00001 0110011
    // ADD R2,R4,R1:    0000000 00001 00100 000 00010 0110011
    // memory[6]=32'h002200b3;    
end

initial 
begin
    x=0;
    PC=5'b00000;
end

always@(posedge clk)
begin
    counter <= counter + 1;
    // TODO: execute the system in a tight loop
    if(stall_flag==0)
        begin
        pr_instr_fetch<=memory[x];
        Decode_PC<=PC;
            // if(memory[x]!=32'bx)
                // info: PC<=PC+4;           //****ALARM: PC keeps on incrementing even if new instruction is not being fetched
                // x<=x+1;
            // end
            PC<=PC+4;
            if (x != 3) begin
                x=x+1;
            end else begin
                // PC<=0;
                x=0;
            end
        end
    else begin
        // pr_instr_fetch<=32'bx;  
        pr_instr_fetch<=memory[x];
    end
end 

//-----------------------------------------------------DECODE STAGE---------------------------------------------------------

reg [2:0] pr_instr;               //Tells what type of instruction it is after decoding
reg [6:0] pr_funct7, pr_opcode;   //pipeline registers for Decode Stage
reg [4:0] pr_rs1, pr_rs2, pr_rd;
reg [2:0] pr_funct3;
reg [11:0] pr_immediate;
reg [4:0] Decode_PC;

parameter LOAD = 3'b101;
parameter ADD = 3'b001;
parameter SUB = 3'b010;
parameter MUL = 3'b011;
parameter DIV = 3'b100;

always@(posedge clk)
begin
//    if(stall_flag==0)
//    begin
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
    // end
   
//    else
    //   pr_instr<=3'b000;

end

//--------------------------------------------------DISPATCH STAGE------------------------------------------------------------------

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
// TODO: add PCs
reg [4:0] RS_Add_PC [0:3];

reg [2:0] RS_Mul_Instr [0:3];        //Defining RS_MUL/DIV entri
reg RS_Mul_busy [0:3];
reg [2:0] RS_Mul_Dest_tag [0:3];
reg [2:0] RS_Mul_S1_tag [0:3];
reg [2:0] RS_Mul_S2_tag [0:3];
reg [31:0] RS_Mul_S1_value [0:3];
reg RS_Mul_S1_valid [0:3];
reg [31:0] RS_Mul_S2_value [0:3];
reg RS_Mul_S2_valid [0:3];
reg [1:0] RS_Mul_count;
reg [4:0] RS_Mul_PC [0:3];

reg [2:0] LD_ST_Buffer_Instr [0:3];    //Defining Load/Store Buffer entries
reg LD_ST_Buffer_busy [0:3];
reg [2:0] LD_ST_Buffer_Dest_tag [0:3];
reg [11:0] LD_ST_Buffer_Offset [0:3];
reg [2:0] LD_ST_Buffer_Source_tag [0:3];
reg [31:0] LD_ST_Buffer_Source_value [0:3];
reg LD_ST_Buffer_Source_valid [0:3];
reg [1:0] RS_LD_ST_count;


initial 
begin
    RS_Add_count=2'b00;
    RS_Mul_count=2'b00;
    RS_LD_ST_count=2'b00;
    ROB_head_ptr=3'b000;
    ROB_tail_ptr=3'b000;

    ROB_busy[0]=0;        ROB_valid[0]=0;
    ROB_busy[1]=0;        ROB_valid[1]=0;
    ROB_busy[2]=0;        ROB_valid[2]=0;
    ROB_busy[3]=0;        ROB_valid[3]=0;
    ROB_busy[4]=0;        ROB_valid[4]=0;
    ROB_busy[5]=0;        ROB_valid[5]=0;
    ROB_busy[6]=0;        ROB_valid[6]=0;
    ROB_busy[7]=0;        ROB_valid[7]=0;

    stall_flag=1'b0;

    LD_ST_Buffer_Source_valid[0]=0;     LD_ST_Buffer_busy[0]=0;
    LD_ST_Buffer_Source_valid[1]=0;     LD_ST_Buffer_busy[1]=0;
    LD_ST_Buffer_Source_valid[2]=0;     LD_ST_Buffer_busy[2]=0;
    LD_ST_Buffer_Source_valid[3]=0;     LD_ST_Buffer_busy[3]=0;
    
    RS_Add_S1_valid [0]=0;      RS_Add_S2_valid [0]=0;     RS_Add_busy[0]=0;
    RS_Add_S1_valid [1]=0;      RS_Add_S2_valid [1]=0;     RS_Add_busy[1]=0;
    RS_Add_S1_valid [2]=0;      RS_Add_S2_valid [2]=0;     RS_Add_busy[2]=0;
    RS_Add_S1_valid [3]=0;      RS_Add_S2_valid [3]=0;     RS_Add_busy[3]=0;


    RS_Mul_S1_valid [0]=0;      RS_Mul_S2_valid [0]=0;     RS_Mul_busy[0]=0;
    RS_Mul_S1_valid [1]=0;      RS_Mul_S2_valid [1]=0;     RS_Mul_busy[1]=0;
    RS_Mul_S1_valid [2]=0;      RS_Mul_S2_valid [2]=0;     RS_Mul_busy[2]=0;
    RS_Mul_S1_valid [3]=0;      RS_Mul_S2_valid [3]=0;     RS_Mul_busy[3]=0;

    Arch_reg[1]=32'h0000000c;     RAT[1]=4'b1000;     
    Arch_reg[2]=32'h00000010;     RAT[2]=4'b1000;   
    Arch_reg[3]=32'h0000002d;     RAT[3]=4'b1000;     
    Arch_reg[4]=32'h00000005;     RAT[4]=4'b1000;     
    Arch_reg[5]=32'h00000003;     RAT[5]=4'b1000;    
    Arch_reg[6]=32'h00000004;     RAT[6]=4'b1000;     
    Arch_reg[7]=32'h00000001;     RAT[7]=4'b1000;
    Arch_reg[8]=32'h00000002;     RAT[8]=4'b1000;
    Arch_reg[9]=32'h00000002;     RAT[9]=4'b1000;
    Arch_reg[10]=32'h00000003;    RAT[10]=4'b1000;
end

always@(posedge clk)
begin
    if(ROB_busy[ROB_tail_ptr]==1)
        stall_flag=1;    //stall
    
    else 
      begin
        if(pr_instr==LOAD)     //if LOAD instruction
        begin
           if(LD_ST_Buffer_busy[RS_LD_ST_count]==1)     //if LOAD buffer if full then STALL
             stall_flag=1;
           else
             begin   
               ROB_Instr[ROB_tail_ptr]<=pr_instr;
               ROB_PC[ROB_tail_ptr]<=Decode_PC;
               ROB_Dest[ROB_tail_ptr]<=pr_rd;
               ROB_busy[ROB_tail_ptr]<=1;
               LD_ST_Buffer_Instr[RS_LD_ST_count]<=pr_instr; 
               LD_ST_Buffer_busy[RS_LD_ST_count]<=1'b1; 
               LD_ST_Buffer_Dest_tag[RS_LD_ST_count]<=ROB_tail_ptr;
               LD_ST_Buffer_Offset[RS_LD_ST_count]<=pr_immediate;
               RAT[pr_rd]<={1'b0, ROB_tail_ptr}; 
                if(RAT[pr_rs1] == 4'b1000)     //if RAT has no tag, get value from Arch Register
                 begin
                  LD_ST_Buffer_Source_value[RS_LD_ST_count]<=Arch_reg[pr_rs1]; 
                  LD_ST_Buffer_Source_valid[RS_LD_ST_count]<=1'b1; 
                 end 
               else
                 begin
                  LD_ST_Buffer_Source_tag[RS_LD_ST_count]<=RAT[pr_rs1][2:0]; //if RAT has some tag, get the tag
                  LD_ST_Buffer_Source_valid[RS_LD_ST_count]<=1'b0;  
                 end  
               ROB_tail_ptr<=ROB_tail_ptr+3'b001;
               RS_LD_ST_count<=RS_LD_ST_count+2'b01;
             end 
        end     
        else if(pr_instr==ADD)
        begin
           if (RS_Add_busy[RS_Add_count]==1) begin
              stall_flag=1;
              RS_Add_count<=RS_Add_count+2'b01;
           end
           else
             begin
                stall_flag=0;
                ROB_Instr[ROB_tail_ptr]<=pr_instr;
                ROB_PC[ROB_tail_ptr]<=Decode_PC;
                ROB_Dest[ROB_tail_ptr]<=pr_rd;
                ROB_busy[ROB_tail_ptr]<=1;
                RS_Add_Instr[RS_Add_count]<=pr_instr;
                RS_Add_PC[RS_Add_count]<=Decode_PC;
                RS_Add_busy[RS_Add_count]<=1'b1;
                RS_Add_Dest_tag[RS_Add_count]<=ROB_tail_ptr;
                RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                if(RAT[pr_rs1]==4'b1000)
                  begin
                   $display("@%d: RS_Add_S1_value[RS_Add_count]<=Arch_reg[pr_rs1]: %d <= %d and RS_Add_S1_valid: %d ", counter, RS_Add_count, Arch_reg[pr_rs1], RS_Add_S1_valid[RS_Add_count]);
                   RS_Add_S1_value[RS_Add_count]<=Arch_reg[pr_rs1];
                   RS_Add_S1_valid[RS_Add_count]<=1;
                  end
                else 
                  begin  
                   RS_Add_S1_tag[RS_Add_count]<=RAT[pr_rs1][2:0];
                   RS_Add_S1_valid[RS_Add_count]<=1'b0;
                  end 
                if(RAT[pr_rs2]==4'b1000)  
                  begin 
                   RS_Add_S2_value[RS_Add_count]<=Arch_reg[pr_rs2];
                   RS_Add_S2_valid[RS_Add_count]<=1;
                  end
                else 
                  begin  
                   RS_Add_S2_tag[RS_Add_count]<=RAT[pr_rs2][2:0];
                   RS_Add_S2_valid[RS_Add_count]<=1'b0;
                  end 
                ROB_tail_ptr<=ROB_tail_ptr+3'b001;  
                RS_Add_count<=RS_Add_count+2'b01; 
             end     
        end 
        else if(pr_instr==SUB)
        begin
           if (RS_Add_busy[RS_Add_count]==1)
              stall_flag=1;
           else
             begin
                ROB_Instr[ROB_tail_ptr]<=pr_instr;
                ROB_PC[ROB_tail_ptr]<=Decode_PC;
                ROB_Dest[ROB_tail_ptr]<=pr_rd;
                ROB_busy[ROB_tail_ptr]<=1;
                RS_Add_Instr[RS_Add_count]<=pr_instr;
                RS_Add_PC[RS_Add_count]<=Decode_PC;
                RS_Add_busy[RS_Add_count]<=1'b1;
                RS_Add_Dest_tag[RS_Add_count]<=ROB_tail_ptr;
                RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                if(RAT[pr_rs1]==4'b1000)
                  begin
                   RS_Add_S1_value[RS_Add_count]<=Arch_reg[pr_rs1];
                   RS_Add_S1_valid[RS_Add_count]<=1;
                   $display("SUB triggered here");
                  end
                else 
                  begin  
                   RS_Add_S1_tag[RS_Add_count]<=RAT[pr_rs1][2:0];
                   RS_Add_S1_valid[RS_Add_count]<=1'b0;
                  end 
                if(RAT[pr_rs2]==4'b1000)  
                  begin 
                   RS_Add_S2_value[RS_Add_count]<=Arch_reg[pr_rs2];
                   RS_Add_S2_valid[RS_Add_count]<=1;
                  end
                else 
                  begin  
                   RS_Add_S2_tag[RS_Add_count]<=RAT[pr_rs2][2:0];
                   RS_Add_S2_valid[RS_Add_count]<=1'b0;
                  end 
                ROB_tail_ptr<=ROB_tail_ptr+3'b001;  
                RS_Add_count<=RS_Add_count+2'b01;   
             end     
        end 
        else if(pr_instr==MUL)
        begin
           if (RS_Mul_busy[RS_Mul_count]==1)
              stall_flag=1;
           else
             begin
                ROB_Instr[ROB_tail_ptr]<=pr_instr;
                ROB_PC[ROB_tail_ptr]<=Decode_PC;
                ROB_Dest[ROB_tail_ptr]<=pr_rd;
                ROB_busy[ROB_tail_ptr]<=1;
                RS_Mul_Instr[RS_Mul_count]<=pr_instr;
                RS_Mul_PC[RS_Mul_count]<=Decode_PC;
                RS_Mul_busy[RS_Mul_count]<=1'b1;
                RS_Mul_Dest_tag[RS_Mul_count]<=ROB_tail_ptr;
                RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                if(RAT[pr_rs1]==4'b1000)
                  begin
                   RS_Mul_S1_value[RS_Mul_count]<=Arch_reg[pr_rs1];
                   RS_Mul_S1_valid[RS_Mul_count]<=1'b1;
                  end
                else 
                  begin  
                   RS_Mul_S1_tag[RS_Mul_count]<=RAT[pr_rs1][2:0];
                   RS_Mul_S1_valid[RS_Mul_count]<=1'b0;
                  end 
                if(RAT[pr_rs2]==4'b1000) 
                  begin  
                   RS_Mul_S2_value[RS_Mul_count]<=Arch_reg[pr_rs2];
                   RS_Mul_S2_valid[RS_Mul_count]<=1'b1;
                  end
                else
                  begin   
                   RS_Mul_S2_tag[RS_Mul_count]<=RAT[pr_rs2][2:0];
                   RS_Mul_S2_valid[RS_Mul_count]<=1'b0;
                  end
                ROB_tail_ptr<=ROB_tail_ptr+3'b001;  
                RS_Mul_count<=RS_Mul_count+2'b01; 
             end     
        end 
        else if(pr_instr==DIV)
        begin
           if (RS_Mul_busy[RS_Mul_count]==1)
              stall_flag=1;
           else
             begin
                ROB_Instr[ROB_tail_ptr]<=pr_instr;
                ROB_PC[ROB_tail_ptr]<=Decode_PC;
                ROB_Dest[ROB_tail_ptr]<=pr_rd;
                ROB_busy[ROB_tail_ptr]<=1;
                RS_Mul_Instr[RS_Mul_count]<=pr_instr;
                RS_Mul_PC[RS_Mul_count]<=Decode_PC;
                RS_Mul_busy[RS_Mul_count]<=1'b1;
                RS_Mul_Dest_tag[RS_Mul_count]<=ROB_tail_ptr;
                RAT[pr_rd]<={1'b0, ROB_tail_ptr};
                if(RAT[pr_rs1]==4'b1000)
                  begin
                   RS_Mul_S1_value[RS_Mul_count]<=Arch_reg[pr_rs1];
                   RS_Mul_S1_valid[RS_Mul_count]<=1'b1;
                  end
                else 
                  begin  
                   RS_Mul_S1_tag[RS_Mul_count]<=RAT[pr_rs1][2:0];
                   RS_Mul_S1_valid[RS_Mul_count]<=1'b0;
                  end 
                if(RAT[pr_rs2]==4'b1000) 
                  begin  
                   RS_Mul_S2_value[RS_Mul_count]<=Arch_reg[pr_rs2];
                   RS_Mul_S2_valid[RS_Mul_count]<=1'b1;
                  end
                else
                  begin   
                   RS_Mul_S2_tag[RS_Mul_count]<=RAT[pr_rs2][2:0];
                   RS_Mul_S2_valid[RS_Mul_count]<=1'b0;
                  end
                ROB_tail_ptr<=ROB_tail_ptr+3'b001;  
                RS_Mul_count<=RS_Mul_count+2'b01;  
             end     
        end 
    end  
  end   

//-------------------------------------------------------------ISSUE STAGE--------------------------------------------------------------

reg [31:0] pr_sv1, pr_Add_Sub_sv1,pr_Add_Sub_sv2,pr_Mul_Div_sv1,pr_Mul_Div_sv2;  //Pipeline registers for Issue stage
reg [2:0] pr_LD_tag, pr_Add_Sub_tag, pr_Mul_Div_tag;
reg [11:0] pr_offset;
reg [2:0] pr_LD_Instr, pr_Add_Sub_Instr, pr_Mul_Instr, pr_Div_Instr;
reg [4:0] pr_Add_Sub_PC, pr_Mul_PC, pr_Div_PC;

always@(posedge clk)          //****ALARM: Priority for instructions issue has not been set properly!
begin
    if(LD_ST_Buffer_Source_valid[0]==1)     //busy bit has been used as 'VALID' bit
    begin
        pr_sv1<=LD_ST_Buffer_Source_value[0];    //get all necessary data into the pipeline registers
        pr_offset<=LD_ST_Buffer_Offset[0];
        pr_LD_tag<=LD_ST_Buffer_Dest_tag[0];
        pr_LD_Instr<=LD_ST_Buffer_Instr[0];
        
        LD_ST_Buffer_Source_value[0]<=32'hx;
        LD_ST_Buffer_Offset[0]<=12'hx;
        LD_ST_Buffer_Dest_tag[0]<=3'bx;
        LD_ST_Buffer_Instr[0]<=3'bx;
        LD_ST_Buffer_busy[0]<=1'b0;
        LD_ST_Buffer_Source_valid[0]<=0;
    end 
    else if(LD_ST_Buffer_Source_valid[1]==1)     //busy bit has been used as 'VALID' bit
    begin
        pr_sv1<=LD_ST_Buffer_Source_value[1];    //get all necessary data into the pipeline registers
        pr_offset<=LD_ST_Buffer_Offset[1];
        pr_LD_tag<=LD_ST_Buffer_Dest_tag[1];
        pr_LD_Instr<=LD_ST_Buffer_Instr[1];
        
        LD_ST_Buffer_Source_value[1]<=32'hx;
        LD_ST_Buffer_Offset[1]<=12'hx;
        LD_ST_Buffer_Dest_tag[1]<=3'bx;
        LD_ST_Buffer_Instr[1]<=3'bx;
        LD_ST_Buffer_busy[1]<=1'b0;
        LD_ST_Buffer_Source_valid[1]<=0;
    end
    else if(LD_ST_Buffer_Source_valid[2]==1)     //busy bit has been used as 'VALID' bit
    begin
        pr_sv1<=LD_ST_Buffer_Source_value[2];    //get all necessary data into the pipeline registers
        pr_offset<=LD_ST_Buffer_Offset[2];
        pr_LD_tag<=LD_ST_Buffer_Dest_tag[2];
        pr_LD_Instr<=LD_ST_Buffer_Instr[2];
        
        LD_ST_Buffer_Source_value[2]<=32'hx;
        LD_ST_Buffer_Offset[2]<=12'hx;
        LD_ST_Buffer_Dest_tag[2]<=3'bx;
        LD_ST_Buffer_Instr[2]<=3'bx;
        LD_ST_Buffer_busy[2]<=1'b0;
        LD_ST_Buffer_Source_valid[2]<=0;
    end
    else if(LD_ST_Buffer_Source_valid[3]==1)     //busy bit has been used as 'VALID' bit
    begin
        pr_sv1<=LD_ST_Buffer_Source_value[3];    //get all necessary data into the pipeline registers
        pr_offset<=LD_ST_Buffer_Offset[3];
        pr_LD_tag<=LD_ST_Buffer_Dest_tag[3];
        pr_LD_Instr<=LD_ST_Buffer_Instr[3];
        
        LD_ST_Buffer_Source_value[3]<=32'hx;
        LD_ST_Buffer_Offset[3]<=12'hx;
        LD_ST_Buffer_Dest_tag[3]<=3'bx;
        LD_ST_Buffer_Instr[3]<=3'bx;
        LD_ST_Buffer_busy[3]<=1'b0;
        LD_ST_Buffer_Source_valid[3]<=0;
    end

    if(RS_Mul_S1_valid[0]==1 && RS_Mul_S2_valid[0]==1)
    begin
        pr_Mul_Div_sv1<=RS_Mul_S1_value[0];
        pr_Mul_Div_sv2<=RS_Mul_S2_value[0];
        pr_Mul_Div_tag<=RS_Mul_Dest_tag[0];
        if(RS_Mul_Instr[0]==MUL) begin
            pr_Mul_Instr<=RS_Mul_Instr[0];
            pr_Mul_PC<=RS_Mul_PC[0];
        end else begin
            pr_Div_Instr<=RS_Mul_Instr[0];
            pr_Div_PC<=RS_Mul_PC[0];
        end    
           
        RS_Mul_S1_value[0]<=32'hx;
        RS_Mul_S2_value[0]<=32'hx;
        RS_Mul_Dest_tag[0]<=3'bx;
        RS_Mul_Instr[0]<=3'bx;
        RS_Mul_busy[0]<=1'b0;
        RS_Mul_S1_valid[0]<=0;
        RS_Mul_S2_valid[0]<=0;
    end
    else if(RS_Mul_S1_valid[1]==1 && RS_Mul_S2_valid[1]==1)
    begin
        pr_Mul_Div_sv1<=RS_Mul_S1_value[1];
        pr_Mul_Div_sv2<=RS_Mul_S2_value[1];
        pr_Mul_Div_tag<=RS_Mul_Dest_tag[1];
        if(RS_Mul_Instr[1]==MUL) begin 
            pr_Mul_Instr<=RS_Mul_Instr[1];
            pr_Mul_PC<=RS_Mul_PC[1];
        end else begin 
            pr_Div_Instr<=RS_Mul_Instr[1];
            pr_Div_PC<=RS_Mul_PC[1];
        end
         
        RS_Mul_S1_value[1]<=32'hx;
        RS_Mul_S2_value[1]<=32'hx;
        RS_Mul_Dest_tag[1]<=3'bx;
        RS_Mul_Instr[1]<=3'bx;
        RS_Mul_busy[1]<=1'b0;
        RS_Mul_S1_valid[1]<=0;
        RS_Mul_S2_valid[1]<=0;
    end
    else if(RS_Mul_S1_valid[2]==1 && RS_Mul_S2_valid[2]==1)
    begin
        pr_Mul_Div_sv1<=RS_Mul_S1_value[2];
        pr_Mul_Div_sv2<=RS_Mul_S2_value[2];
        pr_Mul_Div_tag<=RS_Mul_Dest_tag[2];
        if(RS_Mul_Instr[2]==MUL) begin 
            pr_Mul_Instr<=RS_Mul_Instr[2];
            pr_Mul_PC<=RS_Mul_PC[2];
        end else begin 
            pr_Div_Instr<=RS_Mul_Instr[2];
            pr_Div_PC<=RS_Mul_PC[2];
        end
         
        RS_Mul_S1_value[2]<=32'hx;
        RS_Mul_S2_value[2]<=32'hx;
        RS_Mul_Dest_tag[2]<=3'bx;
        RS_Mul_Instr[2]<=3'bx;
        RS_Mul_busy[2]<=1'b0;
        RS_Mul_S1_valid[2]<=0;
        RS_Mul_S2_valid[2]<=0;
    end
    else if(RS_Mul_S1_valid[3]==1 && RS_Mul_S2_valid[3]==1)
    begin
        pr_Mul_Div_sv1<=RS_Mul_S1_value[3];
        pr_Mul_Div_sv2<=RS_Mul_S2_value[3];
        pr_Mul_Div_tag<=RS_Mul_Dest_tag[3];
        if(RS_Mul_Instr[3]==MUL) begin 
            pr_Mul_Instr<=RS_Mul_Instr[3];
            pr_Mul_PC<=RS_Mul_PC[3];
        end else begin
            pr_Div_Instr<=RS_Mul_Instr[3];
            pr_Div_PC<=RS_Mul_PC[3];
        end
         
        RS_Mul_S1_value[3]<=32'hx;
        RS_Mul_S2_value[3]<=32'hx;
        RS_Mul_Dest_tag[3]<=3'bx;
        RS_Mul_Instr[3]<=3'bx;
        RS_Mul_busy[3]<=1'b0;
        RS_Mul_S1_valid[3]<=0;
        RS_Mul_S2_valid[3]<=0;
    end

    if(RS_Add_S1_valid[0]==1 && RS_Add_S2_valid[0]==1) 
    begin
        pr_Add_Sub_sv1<=RS_Add_S1_value[0];
        pr_Add_Sub_sv2<=RS_Add_S2_value[0];
        pr_Add_Sub_tag<=RS_Add_Dest_tag[0];
        pr_Add_Sub_Instr<=RS_Add_Instr[0];
        pr_Add_Sub_PC<=RS_Add_PC[0];
         
        RS_Add_S1_value[0]<=32'hx;
        RS_Add_S2_value[0]<=32'hx;
        RS_Add_Dest_tag[0]<=3'bx;
        RS_Add_Instr[0]<=3'bx;
        RS_Add_busy[0]<=1'b0;
        RS_Add_S1_valid[0]<=0;
        RS_Add_S2_valid[0]<=0;
    end
    else if(RS_Add_S1_valid[1]==1 && RS_Add_S2_valid[1]==1) 
    begin
        pr_Add_Sub_sv1<=RS_Add_S1_value[1];
        pr_Add_Sub_sv2<=RS_Add_S2_value[1];
        pr_Add_Sub_tag<=RS_Add_Dest_tag[1];
        pr_Add_Sub_Instr<=RS_Add_Instr[1];
        pr_Add_Sub_PC<=RS_Add_PC[1];        
         
        RS_Add_S1_value[1]<=32'hx;
        RS_Add_S2_value[1]<=32'hx;
        RS_Add_Dest_tag[1]<=3'bx;
        RS_Add_Instr[1]<=3'bx;
        RS_Add_busy[1]<=1'b0;
        RS_Add_S1_valid[1]<=0;
        RS_Add_S2_valid[1]<=0;
    end
    else if(RS_Add_S1_valid[2]==1 && RS_Add_S2_valid[2]==1) 
    begin
        pr_Add_Sub_sv1<=RS_Add_S1_value[2];
        pr_Add_Sub_sv2<=RS_Add_S2_value[2];
        pr_Add_Sub_tag<=RS_Add_Dest_tag[2];
        pr_Add_Sub_Instr<=RS_Add_Instr[2];
        pr_Add_Sub_PC<=RS_Add_PC[2];
         
        RS_Add_S1_value[2]<=32'hx;
        RS_Add_S2_value[2]<=32'hx;
        RS_Add_Dest_tag[2]<=3'bx;
        RS_Add_Instr[2]<=3'bx;
        RS_Add_busy[2]<=1'b0;
        RS_Add_S1_valid[2]<=0;
        RS_Add_S2_valid[2]<=0;
    end
    else if(RS_Add_S1_valid[3]==1 && RS_Add_S2_valid[3]==1) 
    begin
        pr_Add_Sub_sv1<=RS_Add_S1_value[3];
        pr_Add_Sub_sv2<=RS_Add_S2_value[3];
        pr_Add_Sub_tag<=RS_Add_Dest_tag[3];
        pr_Add_Sub_Instr<=RS_Add_Instr[3];
        pr_Add_Sub_PC<=RS_Add_PC[3];
         
        RS_Add_S1_value[3]<=32'hx;
        RS_Add_S2_value[3]<=32'hx;
        RS_Add_Dest_tag[3]<=3'bx;
        RS_Add_Instr[3]<=3'bx;
        RS_Add_busy[3]<=1'b0;
        RS_Add_S1_valid[3]<=0;
        RS_Add_S2_valid[3]<=0;
    end
end

//--------------------------------------------------------EXECUTE STAGE------------------------------------------------------------------

reg [31:0] pr_Add_Sub_result, pr_Mul_Div_result, pr_LD_result;
reg [2:0] pr_Add_Sub_Tag, pr_Mul_Div_Tag, pr_LD_Tag;
reg pr_Add_Sub_result_valid, pr_Mul_Div_result_valid, pr_LD_result_valid;
reg [4:0] pr_Add_Sub_result_PC, pr_Mul_Div_result_PC;

reg [31:0] Mem [1:32];
reg [31:0] EAD;
reg [31:0] Sign_Extented_Offset;

reg [319:0] Shift_Mul;       reg [29:0] Shift_Mul_tag ;
reg [1279:0] Shift_Div;      reg [119:0] Shift_Div_tag ;
reg [159:0] Shift_LD_ST;     reg [14:0] Shift_LD_ST_tag;

reg [39:0] Shift_Div_valid ;
reg [9:0] Shift_Mul_valid ;
reg [4:0] Shift_LD_ST_valid ;

reg [31:0] add1, add2, sub1, sub2, mul1, mul2, div1, div2;

initial 
begin
    Mem[16]=32'h00000005;
   
    Shift_LD_ST_valid=5'b00000;      //for the shift registers to give the idea of pipeplines EX
    Shift_Mul_valid=10'b0000000000;
    Shift_Div_valid=40'h0000000000;   
    pr_Add_Sub_result_valid=0; pr_Mul_Div_result_valid=0; pr_LD_result_valid=0; 
end

always@(posedge clk)
begin
    if(pr_LD_Instr==LOAD)
      begin
          if(pr_offset[11]==1)
            Sign_Extented_Offset={20'hfffff, pr_offset[11:0]};
          else
            Sign_Extented_Offset={20'h00000, pr_offset[11:0]};

        EAD=Sign_Extented_Offset+pr_sv1;
        pr_LD_result<=Mem[EAD[4:0]];
        pr_LD_Tag<=pr_LD_tag;
        pr_LD_result_valid<=1;
        //Shift_LD_ST[31:0] <= Mem[EAD[4:0]];
        //Shift_LD_ST_tag[2:0] <= pr_LD_tag;
        //Shift_LD_ST_valid[0]<=1'b1;    
        pr_LD_Instr<=3'bxxx;
      end
    /*else
        begin
            Shift_LD_ST[31:0] <= 32'b0;
            Shift_LD_ST_tag[2:0] <= 3'b000;
            Shift_LD_ST_valid[0]<=1'b0; 
        end*/

    if(pr_Add_Sub_Instr==ADD)
      begin
          add1=pr_Add_Sub_sv1; add2=pr_Add_Sub_sv2;
          pr_Add_Sub_result <= add1+add2;
          pr_Add_Sub_result_valid<=1;
          pr_Add_Sub_result_PC<=pr_Add_Sub_PC;
          add1=32'hx; add2=32'hx;
          pr_Add_Sub_Tag<=pr_Add_Sub_tag;
          pr_Add_Sub_Instr<=3'bxxx;
      end 
       
    if(pr_Add_Sub_Instr==SUB)
      begin
          sub1=pr_Add_Sub_sv1; sub2=pr_Add_Sub_sv2;
          pr_Add_Sub_result<= sub1 - sub2;
          pr_Add_Sub_result_valid<=1;
          pr_Add_Sub_result_PC<=pr_Add_Sub_PC;
          sub1=32'hx; sub2=32'hx;
          pr_Add_Sub_Tag<=pr_Add_Sub_tag;
          pr_Add_Sub_Instr<=3'bxxx;
      end 

    if(pr_Mul_Instr==MUL)
      begin
          mul1= pr_Mul_Div_sv1; mul2=pr_Mul_Div_sv2;
          //Shift_Mul[31:0]<= mul1 * mul2;
          pr_Mul_Div_result<=mul1*mul2;
          mul1=32'hx; mul2=32'hx;
          pr_Mul_Div_Tag<=pr_Mul_Div_tag;
          pr_Mul_Div_result_valid<=1;
          pr_Mul_Div_result_PC<=pr_Mul_PC;
          //Shift_Mul_tag [2:0] <= pr_Mul_Div_tag;
          //Shift_Mul_valid[0]<=1'b1;
          pr_Mul_Instr<=3'bxxx;
      end  
   /* else
       begin
          Shift_Mul[31:0] <= 32'h00000000;
          Shift_Mul_tag[2:0] <= 3'b000;
          Shift_Mul_valid[0]<=1'b0;
       end  */  
    
    if(pr_Div_Instr==DIV)
      begin
          div1=pr_Mul_Div_sv1; div2=pr_Mul_Div_sv2;
          //Shift_Div[31:0]<= div1/div2;
          pr_Mul_Div_result<=div1/div2;
          pr_Mul_Div_Tag<=pr_Mul_Div_tag;
          pr_Mul_Div_result_valid<=1;
          pr_Mul_Div_result_PC<=pr_Div_PC;
          div1=32'hx; div2=32'hx;
         // Shift_Div_tag [2:0] <= pr_Mul_Div_tag;
          //Shift_Div_valid[0]<=1'b1;
          pr_Div_Instr<=3'bxxx;
      end 
   /* else
       begin
        Shift_Div[31:0]<= 32'b0;
        Shift_Div_tag[2:0]<= 3'b000;
        Shift_Div_valid[0]<=1'b0; 
       end  */       
end

/*always@(posedge clk)
begin
      
   
    if(Shift_Mul_valid[9]==1)
      begin
        pr_Mul_Div_result=Shift_Mul[319:288];
        pr_Mul_Div_Tag=Shift_Mul_tag[29:27];
        pr_Mul_Div_result_valid=1;
      end    
    else
      begin 
        pr_Mul_Div_result_valid=0;
        pr_Mul_Div_result=32'bx;
        pr_Mul_Div_Tag=3'bxxx;
      end  
    Shift_Mul[319:32]<=Shift_Mul[287:0];
    Shift_Mul_tag[29:3]<=Shift_Mul_tag[26:0];
    Shift_Mul_valid[9:1]<=Shift_Mul_valid[8:0];  

    
    if(Shift_Div_valid[39]==1'b1)
      begin
        pr_Mul_Div_result=Shift_Div[1279:1248]; 
        pr_Mul_Div_Tag=Shift_Div_tag[119:117];  
        pr_Mul_Div_result_valid=1; 
      end    
    else
      begin
        pr_Mul_Div_result_valid=0;
        pr_Mul_Div_result=32'bx;
        pr_Mul_Div_Tag=3'bxxx;
      end  
    Shift_Div[1279:32]<=Shift_Div[1247:0];
    Shift_Div_tag[119:3]<=Shift_Div_tag[116:0];
    Shift_Div_valid[39:1]<=Shift_Div_valid[38:0];   
        
   
    if(Shift_LD_ST_valid[4]==1'b1)
      begin
        pr_LD_result=Shift_LD_ST[159:128]; 
        pr_LD_Tag=Shift_LD_ST_tag[14:12]; 
        pr_LD_result_valid=1;
      end   
    else 
      begin
        pr_LD_result_valid=0;
        pr_LD_result=32'bx;
        pr_LD_Tag=3'bxxx;
      end  
    Shift_LD_ST[159:32]<=Shift_LD_ST[127:0];
    Shift_LD_ST_tag[14:3]<=Shift_LD_ST_tag[11:0];
    Shift_LD_ST_valid[4:1]<=Shift_LD_ST_valid[3:0];    
            
end*/

//---------------------------------------------------------WRITE BACK STAGE--------------------------------------------------------------

reg [4:0] WB_Add_Sub_PC, WB_Mul_Div_PC;

always@(posedge clk)
begin
    if(pr_LD_result_valid==1)
    begin
        ROB_Value[pr_LD_Tag]<=pr_LD_result;
        ROB_valid[pr_LD_Tag]<=1;
        if(RS_Add_S1_tag[0]==pr_LD_Tag)
        begin
            RS_Add_S1_value[0]<=pr_LD_result;
            $display("@%d: Trigerred in WB: here", counter);
            RS_Add_S1_valid[0]<=1;
            RS_Add_S1_tag[0]<=3'bxxx; 
        end
        if(RS_Add_S2_tag[0]==pr_LD_Tag)
        begin
            RS_Add_S2_value[0]<=pr_LD_result;
            RS_Add_S2_valid[0]<=1;
            RS_Add_S2_tag[0]<=3'bxxx; 
        end
        if(RS_Add_S1_tag[1]==pr_LD_Tag)
        begin
            RS_Add_S1_value[1]<=pr_LD_result;
            RS_Add_S1_valid[1]<=1;
            RS_Add_S1_tag[1]<=3'bxxx; 
        end
        if(RS_Add_S2_tag[1]==pr_LD_Tag)
        begin
            RS_Add_S2_value[1]<=pr_LD_result;
            RS_Add_S2_valid[1]<=1;
            RS_Add_S2_tag[1]<=3'bxxx; 
        end
        if(RS_Add_S1_tag[2]==pr_LD_Tag)
        begin
            RS_Add_S1_value[2]<=pr_LD_result;
            RS_Add_S1_valid[2]<=1;
            RS_Add_S1_tag[2]<=3'bxxx; 
        end
        if(RS_Add_S2_tag[2]==pr_LD_Tag)
        begin
            RS_Add_S2_value[2]<=pr_LD_result;
            RS_Add_S2_valid[2]<=1;
            RS_Add_S2_tag[2]<=3'bxxx; 
        end
        if(RS_Add_S1_tag[3]==pr_LD_Tag)
        begin
            RS_Add_S1_value[3]<=pr_LD_result;
            RS_Add_S1_valid[3]<=1;
            RS_Add_S1_tag[3]<=3'bxxx; 
        end
        if(RS_Add_S2_tag[3]==pr_LD_Tag)
        begin
            RS_Add_S2_value[3]<=pr_LD_result;
            RS_Add_S2_valid[3]<=1;
            RS_Add_S2_tag[3]<=3'bxxx; 
        end
        if(RS_Mul_S1_tag[0]==pr_LD_Tag)
        begin
            RS_Mul_S1_value[0]<=pr_LD_result;
            RS_Mul_S1_valid[0]<=1;
            RS_Mul_S1_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[0]==pr_LD_Tag)
        begin
            RS_Mul_S2_value[0]<=pr_LD_result;
            RS_Mul_S2_valid[0]<=1;
            RS_Mul_S2_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[1]==pr_LD_Tag)
        begin
            RS_Mul_S1_value[1]<=pr_LD_result;
            RS_Mul_S1_valid[1]<=1;
            RS_Mul_S1_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[1]==pr_LD_Tag)
        begin
            RS_Mul_S2_value[1]<=pr_LD_result;
            RS_Mul_S2_valid[1]<=1;
            RS_Mul_S2_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[2]==pr_LD_Tag)
        begin
            RS_Mul_S1_value[2]<=pr_LD_result;
            RS_Mul_S1_valid[2]<=1;
            RS_Mul_S1_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[2]==pr_LD_Tag)
        begin
            RS_Mul_S2_value[2]<=pr_LD_result;
            RS_Mul_S2_valid[2]<=1;
            RS_Mul_S2_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[3]==pr_LD_Tag)
        begin
            RS_Mul_S1_value[3]<=pr_LD_result;
            RS_Mul_S1_valid[3]<=1;
            RS_Mul_S1_tag[3]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[3]==pr_LD_Tag)
        begin
            RS_Mul_S2_value[3]<=pr_LD_result;
            RS_Mul_S2_valid[3]<=1;
            RS_Mul_S2_tag[3]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[0]==pr_LD_Tag)
        begin
            LD_ST_Buffer_Source_value[0]<=pr_LD_result;
            LD_ST_Buffer_Source_valid[0]<=1;
            LD_ST_Buffer_Source_tag[0]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[1]==pr_LD_Tag)
        begin
            LD_ST_Buffer_Source_value[1]<=pr_LD_result;
            LD_ST_Buffer_Source_valid[1]<=1;
            LD_ST_Buffer_Source_tag[1]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[2]==pr_LD_Tag)
        begin
            LD_ST_Buffer_Source_value[2]<=pr_LD_result;
            LD_ST_Buffer_Source_valid[2]<=1;
            LD_ST_Buffer_Source_tag[2]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[3]==pr_LD_Tag)
        begin
            LD_ST_Buffer_Source_value[3]<=pr_LD_result;
            LD_ST_Buffer_Source_valid[3]<=1;
            LD_ST_Buffer_Source_tag[3]<=3'bxxx;
        end
    end    

    if(pr_Add_Sub_result_valid==1)
    begin
        ROB_Value[pr_Add_Sub_Tag]<=pr_Add_Sub_result;
        ROB_valid[pr_Add_Sub_Tag]<=1; 
        pr_Add_Sub_result_valid<=0;
        WB_Add_Sub_PC<=pr_Add_Sub_result_PC;
        if(RS_Add_S1_tag[0]==pr_Add_Sub_Tag && RS_Add_busy[0] && !RS_Add_S1_valid[0])
        begin
            RS_Add_S1_value[0]<=pr_Add_Sub_result;
            RS_Add_S1_valid[0]<=1;
            RS_Add_S1_tag[0]<=3'bxxx;
        end
        if(RS_Add_S2_tag[0]==pr_Add_Sub_Tag && RS_Add_busy[0] && !RS_Add_S2_valid[0])
        begin
            RS_Add_S2_value[0]<=pr_Add_Sub_result;
            RS_Add_S2_valid[0]<=1;
            RS_Add_S2_tag[0]<=3'bxxx;
        end
        if(RS_Add_S1_tag[1]==pr_Add_Sub_Tag && RS_Add_busy[1] && !RS_Add_S1_valid[1])
        begin
            RS_Add_S1_value[1]<=pr_Add_Sub_result;
            RS_Add_S1_valid[1]<=1;
            RS_Add_S1_tag[1]<=3'bxxx;
        end
        if(RS_Add_S2_tag[1]==pr_Add_Sub_Tag && RS_Add_busy[1] && !RS_Add_S2_valid[1])
        begin
            RS_Add_S2_value[1]<=pr_Add_Sub_result;
            RS_Add_S2_valid[1]<=1;
            RS_Add_S2_tag[1]<=3'bxxx;
        end
        if(RS_Add_S1_tag[2]==pr_Add_Sub_Tag && RS_Add_busy[2] && !RS_Add_S1_valid[2])
        begin
            RS_Add_S1_value[2]<=pr_Add_Sub_result;
            RS_Add_S1_valid[2]<=1;
            RS_Add_S1_tag[2]<=3'bxxx;
        end
        // if(RS_Add_S1_tag[2]==pr_Add_Sub_Tag && RS_Add_busy[2] && !RS_Add_S1_valid[2])
        // begin
        //     RS_Add_S1_value[2]<=pr_Add_Sub_result;
        //     RS_Add_S1_valid[2]<=1;
        //     RS_Add_S1_tag[2]<=3'bxxx;
        // end
        if(RS_Add_S2_tag[2]==pr_Add_Sub_Tag && RS_Add_busy[2] && !RS_Add_S2_valid[2])
        begin
            RS_Add_S2_value[2]<=pr_Add_Sub_result;
            RS_Add_S2_valid[2]<=1;
            RS_Add_S2_tag[2]<=3'bxxx;
        end
        if(RS_Add_S1_tag[3]==pr_Add_Sub_Tag && RS_Add_busy[3] && !RS_Add_S1_valid[3])
        begin
            RS_Add_S1_value[3]<=pr_Add_Sub_result;
            RS_Add_S1_valid[3]<=1;
            RS_Add_S1_tag[3]<=3'bxxx;
        end
        if(RS_Add_S2_tag[3]==pr_Add_Sub_Tag && RS_Add_busy[3] && !RS_Add_S2_valid[3])
        begin
            RS_Add_S2_value[3]<=pr_Add_Sub_result;
            RS_Add_S2_valid[3]<=1;
            RS_Add_S2_tag[3]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[0]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S1_value[0]<=pr_Add_Sub_result;
            RS_Mul_S1_valid[0]<=1;
            RS_Mul_S1_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[0]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S2_value[0]<=pr_Add_Sub_result;
            RS_Mul_S2_valid[0]<=1;
            RS_Mul_S2_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[1]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S1_value[1]<=pr_Add_Sub_result;
            RS_Mul_S1_valid[1]<=1;
            RS_Mul_S1_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[1]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S2_value[1]<=pr_Add_Sub_result;
            RS_Mul_S2_valid[1]<=1;
            RS_Mul_S2_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[2]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S1_value[2]<=pr_Add_Sub_result;
            RS_Mul_S1_valid[2]<=1;
            RS_Mul_S1_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[2]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S2_value[2]<=pr_Add_Sub_result;
            RS_Mul_S2_valid[2]<=1;
            RS_Mul_S2_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[3]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S1_value[3]<=pr_Add_Sub_result;
            RS_Mul_S1_valid[3]<=1;
            RS_Mul_S1_tag[3]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[3]==pr_Add_Sub_Tag)
        begin
            RS_Mul_S2_value[3]<=pr_Add_Sub_result;
            RS_Mul_S2_valid[3]<=1;
            RS_Mul_S2_tag[3]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[0]==pr_Add_Sub_Tag)
        begin
            LD_ST_Buffer_Source_value[0]<=pr_Add_Sub_result;
            LD_ST_Buffer_Source_valid[0]<=1;
            LD_ST_Buffer_Source_tag[0]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[1]==pr_Add_Sub_Tag)
        begin
            LD_ST_Buffer_Source_value[1]<=pr_Add_Sub_result;
            LD_ST_Buffer_Source_valid[1]<=1;
            LD_ST_Buffer_Source_tag[1]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[2]==pr_Add_Sub_Tag)
        begin
            LD_ST_Buffer_Source_value[2]<=pr_Add_Sub_result;
            LD_ST_Buffer_Source_valid[2]<=1;
            LD_ST_Buffer_Source_tag[2]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[3]==pr_Add_Sub_Tag)
        begin
            LD_ST_Buffer_Source_value[3]<=pr_Add_Sub_result;
            LD_ST_Buffer_Source_valid[3]<=1;
            LD_ST_Buffer_Source_tag[3]<=3'bxxx;
        end
    end

    if(pr_Mul_Div_result_valid==1)
    begin
        ROB_Value[pr_Mul_Div_Tag]<=pr_Mul_Div_result;
        ROB_valid[pr_Mul_Div_Tag]<=1; 
        WB_Mul_Div_PC<=pr_Mul_Div_result_PC;
        if(RS_Add_S1_tag[0]==pr_Mul_Div_Tag)
        begin
            RS_Add_S1_value[0]<=pr_Mul_Div_result;
            RS_Add_S1_valid[0]<=1;
            RS_Add_S1_tag[0]<=3'bxxx;
        end
        if(RS_Add_S2_tag[0]==pr_Mul_Div_Tag)
        begin
            RS_Add_S2_value[0]<=pr_Mul_Div_result;
            RS_Add_S2_valid[0]<=1;
            RS_Add_S2_tag[0]<=3'bxxx;
        end
        if(RS_Add_S1_tag[1]==pr_Mul_Div_Tag)
        begin
            RS_Add_S1_value[1]<=pr_Mul_Div_result;
            RS_Add_S1_valid[1]<=1;
            RS_Add_S1_tag[1]<=3'bxxx;
        end
        if(RS_Add_S2_tag[1]==pr_Mul_Div_Tag)
        begin
            RS_Add_S2_value[1]<=pr_Mul_Div_result;
            RS_Add_S2_valid[1]<=1;
            RS_Add_S2_tag[1]<=3'bxxx;
        end
        if(RS_Add_S1_tag[2]==pr_Mul_Div_Tag)
        begin
            RS_Add_S1_value[2]<=pr_Mul_Div_result;
            RS_Add_S1_valid[2]<=1;
            RS_Add_S1_tag[2]<=3'bxxx;
        end
        if(RS_Add_S1_tag[2]==pr_Mul_Div_Tag)
        begin
            RS_Add_S1_value[2]<=pr_Mul_Div_result;
            RS_Add_S1_valid[2]<=1;
            RS_Add_S1_tag[2]<=3'bxxx;
        end
        if(RS_Add_S2_tag[2]==pr_Mul_Div_Tag)
        begin
            RS_Add_S2_value[2]<=pr_Mul_Div_result;
            RS_Add_S2_valid[2]<=1;
            RS_Add_S2_tag[2]<=3'bxxx;
        end
        if(RS_Add_S1_tag[3]==pr_Mul_Div_Tag)
        begin
            RS_Add_S1_value[3]<=pr_Mul_Div_result;
            RS_Add_S1_valid[3]<=1;
            RS_Add_S1_tag[3]<=3'bxxx;
        end
        if(RS_Add_S2_tag[3]==pr_Mul_Div_Tag)
        begin
            RS_Add_S2_value[3]<=pr_Mul_Div_result;
            RS_Add_S2_valid[3]<=1;
            RS_Add_S2_tag[3]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[0]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S1_value[0]<=pr_Mul_Div_result;
            RS_Mul_S1_valid[0]<=1;
            RS_Mul_S1_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[0]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S2_value[0]<=pr_Mul_Div_result;
            RS_Mul_S2_valid[0]<=1;
            RS_Mul_S2_tag[0]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[1]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S1_value[1]<=pr_Mul_Div_result;
            RS_Mul_S1_valid[1]<=1;
            RS_Mul_S1_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[1]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S2_value[1]<=pr_Mul_Div_result;
            RS_Mul_S2_valid[1]<=1;
            RS_Mul_S2_tag[1]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[2]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S1_value[2]<=pr_Mul_Div_result;
            RS_Mul_S1_valid[2]<=1;
            RS_Mul_S1_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[2]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S2_value[2]<=pr_Mul_Div_result;
            RS_Mul_S2_valid[2]<=1;
            RS_Mul_S2_tag[2]<=3'bxxx;
        end
        if(RS_Mul_S1_tag[3]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S1_value[3]<=pr_Mul_Div_result;
            RS_Mul_S1_valid[3]<=1;
            RS_Mul_S1_tag[3]<=3'bxxx;
        end
        if(RS_Mul_S2_tag[3]==pr_Mul_Div_Tag)
        begin
            RS_Mul_S2_value[3]<=pr_Mul_Div_result;
            RS_Mul_S2_valid[3]<=1;
            RS_Mul_S2_tag[3]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[0]==pr_Mul_Div_Tag)
        begin
            LD_ST_Buffer_Source_value[0]<=pr_Mul_Div_result;
            LD_ST_Buffer_Source_valid[0]<=1;
            LD_ST_Buffer_Source_tag[0]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[1]==pr_Mul_Div_Tag)
        begin
            LD_ST_Buffer_Source_value[1]<=pr_Mul_Div_result;
            LD_ST_Buffer_Source_valid[1]<=1;
            LD_ST_Buffer_Source_tag[1]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[2]==pr_Mul_Div_Tag)
        begin
            LD_ST_Buffer_Source_value[2]<=pr_Mul_Div_result;
            LD_ST_Buffer_Source_valid[2]<=1;
            LD_ST_Buffer_Source_tag[2]<=3'bxxx;
        end
        if(LD_ST_Buffer_Source_tag[3]==pr_Mul_Div_Tag)
        begin
            LD_ST_Buffer_Source_value[3]<=pr_Mul_Div_result;
            LD_ST_Buffer_Source_valid[3]<=1;
            LD_ST_Buffer_Source_tag[3]<=3'bxxx;
        end
    end
end

//------------------------------------------------------------COMMIT STAGE-------------------------------------------------------------------

reg [4:0] Commit_PC;

always@(posedge clk)
begin
    if(ROB_valid[ROB_head_ptr]==1)
    begin
        Commit_PC<=ROB_PC[ROB_head_ptr];
        Arch_reg[ROB_Dest[ROB_head_ptr]]<=ROB_Value[ROB_head_ptr];
        if(RAT[ROB_Dest[ROB_head_ptr]]=={1'b0, ROB_head_ptr} && (ROB_Dest[ROB_head_ptr]!=pr_rd || stall_flag))
            RAT[ROB_Dest[ROB_head_ptr]]<=4'b1000;

        ROB_Instr[ROB_head_ptr]<=3'b000;
        ROB_Value[ROB_head_ptr]<=32'bx;
        ROB_Dest[ROB_head_ptr]<=5'bx;
        ROB_busy[ROB_head_ptr]<=0;
        ROB_valid[ROB_head_ptr]<=0;
        ROB_head_ptr<=ROB_head_ptr+1;  
    end
end


`include "formal.v"


endmodule



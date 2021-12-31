    `ifdef FORMAL
        `define XPR_LEN 5
        `define PIPELINE_DEPTH 1
        `define PIPELINE_WIDTH 6
        `define PRED_WIDTH 1

        reg [`XPR_LEN-1:0]  windows [0:`PIPELINE_WIDTH-1];
        reg [`XPR_LEN-1:0]  next_pc;
        reg [`PIPELINE_DEPTH-1:0]     events  [0:`PIPELINE_WIDTH-1];
        // wire                done    [0:`PIPELINE_WIDTH-1];
        // wire                bad     [0:`PIPELINE_WIDTH-1];      

        // reg [`STATE_WIDTH-1:0] automaton_state [0:`PIPELINE_WIDTH-1] [0:`PIPELINE_WIDTH-1];
        
        reg [`PRED_WIDTH-1:0]   predicate [0:`PIPELINE_WIDTH-1] [0:`PIPELINE_WIDTH-1];
        wire                    bad     [0:`PIPELINE_WIDTH-1] [0:`PIPELINE_WIDTH-1];      
        reg                     conj_bad;  

        genvar i_pred, j_pred;
        for (i_pred = 0; i_pred < `PIPELINE_WIDTH; i_pred=i_pred+1) begin
            for (j_pred = 0; j_pred < `PIPELINE_WIDTH; j_pred=j_pred+1) begin
                if ((i_pred == 0 && j_pred == 1) || (i_pred == 2 && j_pred == 3) || (i_pred == 4 && j_pred == 5)) begin
                    assign predicate[i_pred][j_pred] = 1;
                end else begin
                    assign predicate[i_pred][j_pred] = 0;
                end
                assign bad[i_pred][j_pred] = predicate[i_pred][j_pred] && (!events[i_pred][0]) && events[j_pred][0];
            end
        end

        always @(*) begin
            integer i_conj_bad, j_conj_bad;
            conj_bad = 1'b0;
            for (i_conj_bad = 0; i_conj_bad < `PIPELINE_WIDTH; i_conj_bad=i_conj_bad+1) begin
                for (j_conj_bad = 0; j_conj_bad < `PIPELINE_WIDTH; j_conj_bad=j_conj_bad+1) begin
                    conj_bad = conj_bad || bad[i_conj_bad][j_conj_bad];
                end
            end
        end



        // assign done[0]  = &events[0];
        // assign done[1]  = &events[1];
        // assign done[2]  = &events[2];

        // assign bad[0]   = events[0][2:2] && !(events[0][0:0] && events[0][1:1]);
        // assign bad[1]   = events[1][2:2] && !(events[1][0:0] && events[1][1:1]);
        // assign bad[2]   = events[2][2:2] && !(events[2][0:0] && events[2][1:1]);

        // reg [2:0]           counter;
        reg init;
        reg Pinit;
        reg [1:0]           head_ptr;

        initial begin
            counter = 3'd0;
            init        = 1'b1;
            Pinit       = 1'b1;
            head_ptr    = 2'd0;

            windows[0]  = `XPR_LEN'd4;
            windows[1]  = `XPR_LEN'd8;
            windows[2]  = `XPR_LEN'd12;
            windows[3]  = `XPR_LEN'd16;
            windows[4]  = `XPR_LEN'd20;
            windows[5]  = `XPR_LEN'd24;
            // windows[4]  = `XPR_LEN'd20;
            // windows[5]  = `XPR_LEN'd24;
            // windows[6]  = `XPR_LEN'd28;
            // next_pc     = `XPR_LEN'd4;
            events[0]   = `PIPELINE_WIDTH'd0;
            events[1]   = `PIPELINE_WIDTH'd0;
            events[2]   = `PIPELINE_WIDTH'd0;
            events[3]   = `PIPELINE_WIDTH'd0;
            events[4]   = `PIPELINE_WIDTH'd0;
            events[5]   = `PIPELINE_WIDTH'd0;

            // 00200293002002930020029300000013
            // 00100313001002930450002300000013
            // assume(port_mem[31:0]               == 32'h00200293);
            // assume(port_mem[63:32]              == 32'h00200293);
            // assume(port_mem[95:64]              == 32'h00200293);
            // assume(port_mem[127:96]             == 32'h00000013);
            // assume(port_mem[32*5-1:32*4]        == 32'h00000013);
            // assume(port_mem[32*6-1:32*5]        == 32'h04500023);
            // assume(port_mem[32*7-1:32*6]        == 32'h00100293);
            // assume(port_mem[1*128-1:0*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[2*128-1:1*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[3*128-1:2*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[4*128-1:3*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[5*128-1:4*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[6*128-1:5*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[7*128-1:6*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[8*128-1:7*128]          == 128'h00000013000000130000001300000013);
            // assume(port_mem[5*128-1:4*128]      == 128'd0);
        end

        always @(posedge clk) begin
            // counter <= counter + 1;
            init    <= 1'b0;
            if (init == 0) begin
                Pinit <= 1'b0;
            end
        end

        // always @(posedge clk) begin
        //     assume(htif_pcr_req_valid == 0);
        //     assume(htif_pcr_req_rw == 0);
        //     assume(htif_pcr_req_addr == 0);
        //     assume(htif_pcr_req_data == 0);
        //     assume(htif_pcr_resp_ready == 0);
        //     assume(arbiter_next_core == 0);
        // end

        integer i_window;
        // Monitor for the pipeline events
        always @(posedge clk) begin
            if (counter >= 3) begin
                // if (done[head_ptr]) begin
                //     events[head_ptr] = `PIPELINE_WIDTH'b000;
                //     windows[head_ptr] = next_pc;
                //     case (next_pc)
                //         12      : next_pc = 4;
                //         default : next_pc = next_pc + 4;
                //     endcase
                //     case (head_ptr)
                //         0       : head_ptr = 1;
                //         1       : head_ptr = 2;
                //         2       : head_ptr = 0;
                //         default : head_ptr = 0;
                //     endcase
                // end
                // IF
                for (i_window = 0; i_window < `PIPELINE_WIDTH; i_window=i_window+1) begin
                    if (pr_Add_Sub_PC == windows[i_window]) begin
                        events[i_window][0:0] = 1'b1;
                    end
                end
            end
        end

        always @(posedge clk) begin
            if (init) begin
                assume(reset);
            end else begin
                assume(!reset);
            end

            // if (counter < 10) begin
                // assert(port_mem[5*128-1:4*128] != 128'd2);
            // assert(!(bad[0] || bad[1] || bad[2]));
            // Inductiveness constraints
            // assert(windows[0] == 4 || windows[0] == 8 || windows[0] == 12);
            // assert(windows[1] == 4 || windows[1] == 8 || windows[1] == 12);
            // assert(windows[2] == 4 || windows[2] == 8 || windows[2] == 12);
            // assert(windows[2] == 12);
            
            // end
            if (counter > 3) begin
                assert(!conj_bad);
            end

            // if (counter == 11) begin
            //     assert(0);
            // end
        end
    `endif

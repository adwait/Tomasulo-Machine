`ifdef FORMAL

    reg [2:0] counter;
    reg init;
    reg Pinit;

    initial begin
        counter = 0;
        // initial clock cycle
        init    = 0;
        // second clock cycle
        Pinit   = 0;
    end

    always @(posedge clk) begin
        counter <= counter + 1;
        init <= 0;
        if (init == 0) begin
            Pinit <= 0;
        end
    end

    always @(posedge clk) begin
        
    end

`endif // FORMAL
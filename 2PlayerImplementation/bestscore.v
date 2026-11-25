module bestscore(reaction, bestReact, CLOCK_50, resetn, done);
    input [15:0] reaction;
    output [15:0] bestReact;
    input [2:0] done;
    reg [15:0] currReact;
	 input CLOCK_50;
	 input resetn;
    assign bestReact = currReact;
    always@(posedge CLOCK_50)
    begin
        if (!resetn)
            currReact <= 16'hFFFF;
        if ((done == 3'd4) && reaction < currReact && reaction > 16'd0)
            currReact <= reaction;
    end
endmodule
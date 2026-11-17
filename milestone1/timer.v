module timer (KEY, CLOCK_50, one_millisecond, start_timer, reaction_time);

    input [0:0] KEY;
    input one_millisecond;
    input player1_press;
    input CLOCK_50, start_timer;
    output [16:0] reg reaction_time;

    always@(posedge CLOCK_50)
    begin
        if(KEY[0] == 1'b0)
            reaction_time <= 16'b0;
        else if(start_timer && one_millisecond)
            reaction_time <= reaction_time + 1'b1;
    end

endmodule

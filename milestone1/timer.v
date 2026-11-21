// ============================================================================
// timer.v 
//
// ROLE: measure ONE player's reaction time in ms.
//  1. clear = 1   -> reset to 0 (controller in IDLE)
//  2. running = 1 -> count every ms (controller in GO)
//  3. stop_pulse  -> freeze the time and set finished = 1 (until next clear, to displayed)
//
// ============================================================================

module timer (CLOCK_50, resetn, one_millisecond, clear, run, stop_pulse, reaction_time, finished);

     //------------code------------//
    input CLOCK_50;
    input resetn;
    input one_millisecond;
    input clear;
    input run;
    input stop_pulse;

    output reg [15:0] reaction_time;
    output reg finished; //signal to froze time

    always@(posedge CLOCK_50)
    begin
        if(!resetn || clear)
        begin
            reaction_time <= 16'b0;
            finished <= 1'b0;
        end
        else if(run && !finished) 
        begin
            if(stop_pulse)
                finished <= 1'b1;
            else if(one_millisecond)
                reaction_time <= reaction_time + 1'b1; 
        end
    end

endmodule

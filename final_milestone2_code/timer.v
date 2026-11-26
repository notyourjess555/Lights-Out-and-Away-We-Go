// ============================================================================
// timer.v 
//
// ROLE: measure ONE player's reaction time in ms.
//  1. clear = 1   -> reset to 0 (controller in IDLE)
//  2. running = 1 -> count every ms (controller in GO)
//  3. stop_pulse  -> freeze the time and set finished = 1 (until next clear, to displayed)
//
// ============================================================================

module timer (CLOCK_50, resetn, one_millisecond, clear, run, stop_pulse1, stop_pulse2, reaction_time, p1finished, p2finished);

     //------------code------------//
    input CLOCK_50;
    input resetn;
    input one_millisecond;
    input clear;
    input run;
    input stop_pulse1, stop_pulse2;

    output reg [15:0] reaction_time;
    output reg p1finished, p2finished; //signal to froze time

     //NEW: BCD counter//
     wire [3:0] ones, tens, hundreds, thousands;
     assign ones = reaction_time[3:0];
     assign tens = reaction_time[7:4];
     assign hundreds = reaction_time[11:8];
     assign thousands = reaction_time[15:12];

    always@(posedge CLOCK_50)
    begin
         if(!resetn || clear) //global reset, time specific reset
        begin
            reaction_time <= 16'b0;
            p1finished <= 1'b0;
				p2finished <= 1'b0;
        end
         else if(run && !p1finished && !p2finished) //run: start timer, finished: =1 means reacted
        begin
            if(stop_pulse1)
                p1finished <= 1'b1;
				else if(stop_pulse2)
					p2finished <= 1'b1;
				else if(one_millisecond && reaction_time != 16'h9999)
          //new logic for display
               if(ones != 4'd9) // not 9
                      reaction_time[3:0] <= ones + 4'd1; 
               else
               begin
                    reaction_time[3:0] <= 4'd0;
                    if(tens != 4'd9)//if tens are not 9
                         reaction_time[7:4] <= tens + 4'd1;
                    else
                    begin
                         reaction_time[7:4] <= 4'd0;
                         if(hundreds != 4'd9)// hundreds not 9
                              reaction_time[11:8] <= hundreds + 4'd1;
                         else
                         begin
                              reaction_time[11:8] <= 4'd0;
                              reaction_time[15:12] <= thousands + 4'd1;
                         end
                    end
                end
                            
          end
    end

endmodule
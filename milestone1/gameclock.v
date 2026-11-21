// ============================================================================
// gameclock.v  -  "the official race clock"
//
// ROLE: 1. turn the 50 MHz board clock into one time base for the whole game.
//       2. Outputs a 1-cycle pulse every 1 ms.
//       3. Every delay (light spacing, random hold, reaction time) is counted in these ms ticks
//
// NOTE: one_millisecond is an ENABLE. All logic still runs when tick_ms == 1.
//
// MODELSIM: set counter != to a smaller number (e.g. 2)
// ============================================================================

module gameclock(CLOCK_50, KEY, one_second, one_millisecond);

    //------------code------------//

    input CLOCK_50;
    input resetn;
    output reg one_millisecond;

    //counter
    reg [15:0] counter;
    
    always@(posedge CLOCK_50)
    begin
        if(!resetn)
        begin
            counter <= 16'b0;
            one_millisecond <= 1'b0;
        end
        else if(counter == 16'd49999)
        begin
            counter <= 16'b0;
            one_millisecond <= 1'b1;
        end
        else
        begin
            counter <= counter + 16'b1;
            one_millisecond <= 1'b0;
        end
    end

endmodule

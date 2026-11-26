// ============================================================================
// userinput.v 
//
// ROLE: turn buttons into clean 1-cycle "press" pulses.
//  For each button:
//  1. detect the moments from released -> pressed
//  2. output a pulse that is high for one clock cycle
//
// (for testing) 
// DE1-SoC KEYs are active-low: 0 = pressed, 1 = released.
//
// KEY function (single player):
//  KEY[3] -> start_pulse   (player 2 reaction button)
//  KEY[2] -> start_pulse   (start around / go back to start screen)
//  KEY[1] -> p1_pulse      (player 1 reaction button)
// ============================================================================

module userinput(CLOCK_50, resetn, KEY, start_pulse, p1_pulse, p2_pulse);


    input CLOCK_50;
    input resetn;
    input [3:0] KEY;
	output start_pulse;
    output p1_pulse;
    output p2_pulse;


    
    //-------code-------    
    key_pulse p2_button(CLOCK_50, resetn, KEY[3], p2_pulse);
    key_pulse start_button(CLOCK_50, resetn, KEY[2], start_pulse);
    key_pulse p1_button(CLOCK_50, resetn, KEY[1], p1_pulse);

endmodule

//helper function
module key_pulse(CLOCK_50, resetn, key, press_pulse);

    input CLOCK_50;
    input resetn;
    input key;
    output press_pulse;

    reg current_press;
    reg press_last_cycle;

    always @(posedge CLOCK_50) begin
        if (!resetn) 
        begin
            current_press <= 1'b0;
            press_last_cycle <= 1'b0;
        end
        else 
        begin
            //invert the active low, 1 = pressed, 0 = not pressed
            current_press <= ~key;  
            press_last_cycle <= current_press;
        end
    end

    assign press_pulse = current_press && ~press_last_cycle;

endmodule
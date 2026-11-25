// ============================================================================
// top.v  -  connects all modules to test
//
// KEYS:
// KEY[0] - reset (hold to reset everything)
// KEY[3] - start round / back to start screen
// KEY[1] - player 1 reaction button
//
// LEDs (for board testing):
// LEDR[4:0] - the 5 traffic lights
// LEDR[7:5] - current state (0 IDLE, 1 LIGHTS, 2 HOLD, 3 GO, 4 RESULT)
// LEDR[8]   - player 1 reacted
// LEDR[9]   - player 1 false start
//
// HEX (reaction time in ms, from timer.v):
// HEX3 HEX2 HEX1 HEX0 = thousands hundreds tens ones 
// ============================================================================
module top(SW, CLOCK_50, KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX5, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK);

    input CLOCK_50;
    input [3:0] KEY;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX5;
	 input [9:0] SW;
	 
    //outputs (to the VGA pins)
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    input         AUD_ADCDAT;
    inout         AUD_BCLK;
    inout         AUD_ADCLRCK;
    inout         AUD_DACLRCK;
    inout         FPGA_I2C_SDAT;
    output        AUD_XCK;
    output        AUD_DACDAT;
    output        FPGA_I2C_SCLK;

    //------------code------------//

    parameter GO = 3'd3, IDLE = 3'd0;   //must match gamecontroller.v

    wire resetn;
    wire one_millisecond;
    wire start_pulse, p1_pulse, p2_pulse;
    wire [2:0] state;
    wire [4:0] lights;
    wire p1_false_start;
    wire [15:0] p1_reaction_ms;   //4 BCD digits
    wire p1_finished;
    wire [3:0] random_value;
    wire multip;
    wire p2_false_start;
    wire p2_finished;
    wire winner;
    wire [15:0] best_reaction_ms;
    wire lightTrigger;

    assign resetn = KEY[0];

    //TEMPORARY: fixed hold of 4 x 250 ms = 1 s, replace with ranNum output
    assign random_value = 4'd4;

    gameclock U1(CLOCK_50, resetn, one_millisecond);

    userinput U2(CLOCK_50, resetn, KEY, start_pulse, p1_pulse, p2_pulse);

    gamecontroller U3(CLOCK_50, resetn, one_millisecond, start_pulse, p1_pulse, p1_finished, random_value,
                      state, lights, p1_false_start, multip, p2_pulse, p2_finished, p2_false_start, winner, lightTrigger);

	 wire finished;
	 assign finished = (p1_finished || p2_finished);

    //timer clears in IDLE, counts in GO
    timer U4(CLOCK_50, resetn, one_millisecond, (state == IDLE), (state == GO), p1_pulse, p2_pulse,
             p1_reaction_ms, p1_finished, p2_finished);
				 
	vgadisplaycircle U5 (CLOCK_50, resetn, lights, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    p1p2 U6(KEY[2], SW[0], multip, CLOCK_50);

    bestscore U7(p1_reaction_ms, best_reaction_ms, CLOCK_50, resetn, state);

    audio U8(CLOCK_50, KEY[3:0], AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK, SW[3:0], lightTrigger);

	 wire [3:0] bestDig1;
	 wire [3:0] bestDig2;
	 wire [3:0] bestDig3;
	 wire [3:0] bestDig4;
	 
	 
    //reaction time on the HEX displays
    hexdisplay H0(p1_reaction_ms[3:0],   best_reaction_ms[3:0], HEX0, SW[1], state);   //ones
    hexdisplay H1(p1_reaction_ms[7:4],   best_reaction_ms[7:4], HEX1, SW[1], state);   //tens
    hexdisplay H2(p1_reaction_ms[11:8],  best_reaction_ms[11:8], HEX2, SW[1], state);   //hundreds
    hexdisplay H3(p1_reaction_ms[15:12], best_reaction_ms[15:12], HEX3, SW[1], state);   //thousands
    windisplay H5(multip, winner, HEX5, state); //winner display

    assign LEDR[4:0] = lights;
    assign LEDR[7:5] = state;
    assign LEDR[8]   = p1_finished;
    assign LEDR[9]   = winner;

endmodule
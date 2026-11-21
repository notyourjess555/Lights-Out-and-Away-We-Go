// ============================================================================
// top.v  -  connects all modules to test
//
// KEYS:
// KEY[0] - reset (hold to reset everything)
// KEY[3] - start round / back to start screen
// KEY[1] - player 1 reaction button
//
// LEDs (for board testing):
//  LEDR[4:0] - the 5 traffic lights
//  LEDR[7:5] - current state (0 IDLE, 1 LIGHTS, 2 HOLD, 3 GO, 4 RESULT)
//  LEDR[8]   - player 1 reacted
//  LEDR[9]   - player 1 false start
// ============================================================================

module top(CLOCK_50, KEY, LEDR);

    inputs CLOCK_50;
    input [3:0] KEY;
    output [9:0] LEDR;

    parameter GO = 3'd3, IDLE = 3'd0;

    //wires
    wire resetn;
    wire one_millisecond;
    wire start_pulse, p1_pulse;
    wire [2:0] state;
    wire [4:0] lights;
    wire p1_false_start;
    wire [13:0] p1_reaction_ms;
    wire p1_finished;
    wire [3:0] random_value;

    assign resetn = KEY[0];

    // ============================================================================
// top.v  -  connects all modules to the DE1-SoC pins
//
// CONTROLS:
//   KEY[0] - reset (hold to reset everything)
//   KEY[3] - start round / back to start screen
//   KEY[1] - player 1 reaction button
//
// LEDs (for board testing until VGA is connected):
//   LEDR[4:0] - the 5 traffic lights
//   LEDR[7:5] - current state (0 IDLE, 1 LIGHTS, 2 HOLD, 3 GO, 4 RESULT)
//   LEDR[8]   - player 1 reacted
//   LEDR[9]   - player 1 false start
// ============================================================================

module top(CLOCK_50, KEY, LEDR);

    input CLOCK_50;
    input [3:0] KEY;
    output [9:0] LEDR;

    //------------code------------//

    parameter GO = 3'd3, IDLE = 3'd0;   //must match gamecontroller.v

    wire resetn;
    wire one_millisecond;
    wire start_pulse, p1_pulse;
    wire [2:0] state;
    wire [4:0] lights;
    wire p1_false_start;
    wire [13:0] p1_reaction_ms;
    wire p1_finished;
    wire [3:0] random_value;

    assign resetn = KEY[0];

    //TEMPORARY: fixed hold of 4 x 250 ms = 1 s, replace with ranNum output
    assign random_value = 4'd4;

    gameclock U1(CLOCK_50, resetn, one_millisecond);

    userinput U2(CLOCK_50, resetn, KEY, start_pulse, p1_pulse);

    gamecontroller U3(CLOCK_50, resetn, one_millisecond, start_pulse, p1_pulse, p1_finished, random_value,
                      state, lights, p1_false_start);

    //timer clears in IDLE, counts in GO
    timer U4(CLOCK_50, resetn, one_millisecond, (state == IDLE), (state == GO), p1_pulse,
             p1_reaction_ms, p1_finished);

    assign LEDR[4:0] = lights;
    assign LEDR[7:5] = state;
    assign LEDR[8]   = p1_finished;
    assign LEDR[9]   = p1_false_start;

endmodule

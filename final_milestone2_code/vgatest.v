// ============================================================================
// vgatest.v  -  test vgadisplay.v alone (DESim / board), no game logic
//
//   KEY[0]   - reset (screen goes black, then 5 grey lights)
//   SW[4:0]  - pretend "lights": flip a switch -> that light turns red / grey
//              SW[4] = leftmost light
// ============================================================================

module vgatest(CLOCK_50, KEY, SW, VGA_R, VGA_G, VGA_B,
               VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    input CLOCK_50;
    input [3:0] KEY;
    input [9:0] SW;
    output [7:0] VGA_R, VGA_G, VGA_B;
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

    vgadisplay U1(CLOCK_50, KEY[0], SW[4:0], VGA_R, VGA_G, VGA_B,
                  VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

endmodule

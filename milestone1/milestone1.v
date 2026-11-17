module milestone1(
    input CLOCK_50,
    input [1:0] KEY,
    output [5:0] LEDR
);

    wire one_second;
    wire one_millisecond;
    wire player1_press;
	 

    // Game clock
    gameclock U1(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY[0]),
        .one_second(one_second),
        .one_millisecond(one_millisecond)
    );

    // Traffic light sequencer
    trafficlightsequencer U2(
        .KEY(KEY),
        .CLOCK_50(CLOCK_50),
        .one_second(one_second),
        .LEDR(LEDR),
		  .start_game_signal(1'b0)
    );

    // User input
    userinput U3(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .player1_press(player1_press)
    );

endmodule

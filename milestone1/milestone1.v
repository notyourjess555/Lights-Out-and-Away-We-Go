module milestone1(
    input CLOCK_50,
    input [1:0] KEY,
    output [5:0] LEDR
);

    wire one_second;
    wire one_millisecond;
    wire start_game_signal;
    wire player1_press;
    wire start_timer;
	 wire lights_done;
	 

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
		  .player1_press(player1_press),
		.start_game_signal(start_game_signal),
		.start_timer(start_timer),
		.lights_done(lights_done)
    );

    // User input
    userinput U3(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .start_game_signal(start_game_signal),
        .player1_press(player1_press)
    );

endmodule

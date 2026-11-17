module userinput(KEY, CLOCK_50, player1_press, start_game_signal);


    input CLOCK_50;
    input [1:0] KEY;
	input lightsOff;
    //output reg falseStart;

    //for milestone1
    //LEDR as traffic lights
    //LEDR[5] - indicate reset, start of the game
    //LEDR[4:0] - the traffic lights, turn off sequencly


    //idea: 
    //1. LEDR[5] is on when game not start OR reset is pressed (KEY[0])
    //2. user watches the sequence turn off
    //3. user press KEY[1]

    //function of userinput.v
    //detect key inputs (select & reset)
    //detect false start

    //-------code-------    
    //reg round_done;
    //reg player1_time

    
    reg previous_key;
	output reg start_game_signal;
    output reg player1_press;

    //variables
    always@(posedge CLOCK_50)
    begin
        if(KEY[0] == 1'b0)
        begin
            previous_key <= 1'b1;
            player1_press <= 1'b0;
            start_game_signal <= 1'b0;
        end
        else 
        begin
            start_game_signal <= (previous_key && !KEY[1]);
            player1_press <= (previous_key && !KEY[1]); //previous release (1), now pressed (0)
            previous_key <= KEY[1];
        end
    end


endmodule
     


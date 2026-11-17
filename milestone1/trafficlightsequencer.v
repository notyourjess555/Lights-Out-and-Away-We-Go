module trafficlightsequencer(KEY, CLOCK_50, one_second, player1_press, LEDR, start_game_signal, start_timer ,lights_done);

    //idea
    //1. all 5 lights off
    //2. enable of intervals of lights switching on, 1s per intervals
    //3. implement random number generator and wait
    //4. recieve singal, turn off all 
    //5. call timer to record time -> winning logic

    //for milestone1
    //LEDR as traffic lights
    //LEDR[5] - indicate reset, start of the game [reset is pressed (KEY[0])]
    //LEDR[4:0] - the traffic lights, turn off sequencly


    //---------code---------

    input [1:0] KEY;
    input CLOCK_50, one_second;
    input start_game_signal;
	
    //input go_signal; 
    output [5:0] LEDR;

    //variables
    reg [4:0] lights;
    output lights_done, 
    output reg start_timer;

    //check if first start
    reg game_started;
    always @(posedge CLOCK_50)
    begin
    if (KEY[0] == 1'b0)
        game_started <= 1'b0;
    else if (start_game_signal)
        game_started <= 1'b1;
    end
	 

    //control lights like shift registor
	 
	//using one sec to try: use random later
	reg go_signal;

	always @(posedge CLOCK_50) 
    begin
	    if (KEY[0] == 1'b0) begin
		  go_signal <= 1'b0;
	end
	    else if (lights_done && one_second)
		    go_signal <= 1'b1;
	end
		 

    always@(posedge CLOCK_50)
    begin
        if(KEY[0]== 1'b0)
        begin
            lights <= 5'b00000;
            start_timer <= 1'b0;
        end
        else if (game_started && one_second && lights != 5'b11111)
        begin
            lights <= {1'b1, lights [3:0]};
            start_timer <= 1'b0;
        end
        else if(go_signal)
        begin
            lights <= 5'b00000;
            
            if(player1_press)
                start_timer <= 1'b1;
            else
                start_timer <= 1'b0;

        end
    end

    assign LEDR[4:0] = lights;
    assign LEDR[5] = ~KEY[0];

    //all lights up, replace with random num 
    assign lights_done = (lights == 5'b11111);
	 
	 

endmodule

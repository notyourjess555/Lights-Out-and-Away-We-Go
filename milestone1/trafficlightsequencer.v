module trafficlightsequencer(KEY, LEDR, CLOCK_50, one_second);

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
    input go_signal; 
    output [5:0] LEDR;

    //variables
    reg [4:0] lights;
    //reg lightsOff;

    //control lights like shift registor

    always@(posedge CLOCK_50)
    begin
        if(KEY[0]== 1'b0)
            lights <= 5'b00000;
        else if (one_second && lights != 5'b11111)
            lights <= {lights [3:0], 1'b1};
        else if(go_signal)
        begin
            lights <= 5'b00000;
            //lightsOff <= 1'b1;
        end
    end

    assign LEDR[4:0] = lights;
    assign LEDR[5] = ~KEY[0];

endmodule
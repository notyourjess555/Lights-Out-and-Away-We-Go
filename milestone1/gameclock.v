module gameclock(CLOCK_50, KEY, one_second, one_millisecond);

    //enable = 1 every 1 ms
    //using clock 50 as per unit: 1 millisecond (ms) | 50,000000 clock cycles

    //function of timer.v
    //1. act as general clock input for logics
    //2. used for reaction speedtimer

    //------------code------------//

    input CLOCK_50;
    input [0:0]KEY;
    output reg one_second;
    output reg one_millisecond;

    //1 second clock section
    reg [25:0] counter;  

    always@(posedge CLOCK_50)
    begin
        if(KEY[0] == 1'b0)
        begin
            counter <= 26'b0;
            one_second <= 1'b0;
        end
        else if(counter != 26'd49999999)
        begin
            counter <= counter + 1'b1;
            one_second <= 1'b0;
        end
        else if(counter == 26'd49999999)
        begin
            counter <= 26'b0;
            one_second <= 1'b1;
        end
    end

    //1ms clock
    reg [15:0] counter2;
    
    always@(posedge CLOCK_50)
    begin
        if(KEY[0] == 1'b0)
        begin
            counter2 <= 16'b0;
            one_millisecond <= 1'b0;
        end
        else if(counter2 != 16'd49999)
        begin
            counter2 <= counter2 + 1'b1;
            one_millisecond <= 1'b0;
        end
        else if(counter2 == 16'd49999)
        begin
            counter2 <= 16'b0;
            one_millisecond <= 1'b1;
        end
    end


endmodule

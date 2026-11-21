// ============================================================================
// gamecontroller.v  
// ROLE: 1. decides the game STATE 
//       2. control the 5 traffic LIGHTS
//       3. decides reaction or false start
//
// STATES:
// 
// IDLE   - start screen, waiting for start_pulse
// LIGHTS - lights turn on one by one, per second
// HOLD   - all 5 lights on, wait a random time
// GO     - lights out! start counting the reaction time
// RESULT - show reaction time or "false start", wait for start_pulse
//
// FALSE START: player presses during LIGHTS or HOLD -> RESULT with p1_false_start = 1
// TIMEOUT:     nobody presses within TIMEOUT_MS after GO -> RESULT
//
// ============================================================================

module gamecontroller(CLOCK_50, resetn, one_millisecond, start_pulse, p1_pulse, 
p1_finished, random_num, state, lights, p1_false_start);

    //--------variables---------//

    //inputs
    input CLOCK_50;
    input resetn;
    input one_millisecond;
    input start_pulse;
    input [15:0]random_num; //TO MODIFITY: change if bits are wrong for random num

    //player1
    input p1_pulse;
    input p1_finished;

    //outputs
    output reg [2:0] state;
    output reg [4:0] lights;

    //false starts
    output reg p1_false_start;
    

    //----------------------STATES-----------------------//

    parameter IDLE = 3'd0, LIGHTS = 3'd1, WAIT = 3'd2, GO = 3'd3, RESULT = 3'd4;

    //----------------------CLOCK-----------------------//
    
    parameter ONE_SECOND = 1000; //1ms x 1000 = 1s
    parameter TIMEOUT = 5000; //stop waiting for a key to be pressed after 5 seconds

    //---------------------stopwatch-------------------//

    reg [15:0] current_state_ms; //how long since the current state started
    reg [15:0] wait_ms; //how long WAIT last = the random time wait

    //---------code---------//

    always@(posedge CLOCK_50)
    begin
    
    //----reset settings----//
        if(!resetn)
        begin
            state <= IDLE;
            lights <= 5'b00000;
            p1_false_start <= 1'b0;
            current_state_ms <= 16'b0;
            wait_ms <= 16'b0;
        end

    //----game settings----//
        else
        begin
            if(one_millisecond)
                current_state_ms <= current_state_ms + 1'b1;

            case(state)

            //---start---//
                IDLE:
                begin
                    if(start_pulse)
                    begin
                        lights <= 5'b0;
                        p1_false_start <= 1'b0;
                        current_state_ms <= 16'b0;
                        state <= LIGHTS; 
                    end
                end
            
            //-----traffic lights turning on-----//
            LIGHTS:
            begin
                if(p1_pulse)
                begin
                    p1_false_start <= 1'b1; //pressed when lights are still turning on
                    state <= RESULT;
                end
                else if (one_millisecond && current_state_ms == ONE_SECOND -1)
                begin

                    current_state_ms <= 14'b0;
                    lights <= {1'b1, lights[4:1]};

                    if(lights==5'b11110)
                    begin
                        wait_ms <= random_num * 14'd250; //TO ADD: the real random num gen
                        state <= WAIT;
                    end
                end
            end

            //-----waiting for random num-----//
            WAIT:
            begin
                if(p1_pulse)
                begin
                    p1_false_start <= 1'b1; //pressed when still waiting
                    state <= RESULT;
                end
                else if (one_millisecond && current_state_ms == wait_ms)
                begin
                    //LIGHTS OUT AND AWAY WE GOOOOO
                    lights <= 5'b0;
                    current_state_ms <= 14'b00000;
                    state <= GO;
                end
            end

            //-----lights off, start counting or times up-----//

            GO:
            begin
                if(p1_finished)
                    state <= RESULT;
                else if (one_millisecond && current_state_ms == TIMEOUT-1)
                    state <= RESULT;
            end

            //-----game done-----//

            RESULT:
            begin
                if(start_pulse)
                begin
                    lights <= 5'b0;
                    state <= IDLE;
                end
            end

            default: state <= IDLE;

        endcase
    end

endmodule

reg [1:0] state;
reg go_signal;

always @(posedge CLOCK_50) begin
    if (reset) begin
        state <= LIGHT_SEQUENCE;
        go_signal <= 1'b0;
    end
    else begin
        case (state)

            LIGHT_SEQUENCE: begin
                go_signal <= 1'b0;

                if (lights_done)
                    state <= WAIT_ONE_SECOND;
            end

            WAIT_ONE_SECOND: begin
                if (one_second) begin
                    go_signal <= 1'b1;
                    state <= GO;
                end
            end

            GO: begin
                go_signal <= 1'b1;
            end

        endcase
    end
end

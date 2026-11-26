`timescale 1ns/1ps

module audiotb;

    reg        CLOCK_50;
    reg  [3:0] KEY;
    reg  [3:0] SW;
    reg        AUD_ADCDAT;
    wire       AUD_BCLK;
    wire       AUD_ADCLRCK;
    wire       AUD_DACLRCK;
    wire       FPGA_I2C_SDAT;
    wire       AUD_XCK;
    wire       AUD_DACDAT;
    wire       FPGA_I2C_SCLK;
    reg        lightTrigger;

    audio dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
        .SW(SW),
        .lightTrigger(lightTrigger)
    );

    // 50 MHz clock -> 10 ns half-period
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // Reset and 1-second lightTrigger pulses
    initial begin
        KEY          = 4'b1111; // KEY[0]=1 means not in reset
        SW           = 4'b0000;
        AUD_ADCDAT   = 1'b0;
        lightTrigger = 1'b0;

        // Assert active-low reset on KEY[0] for 100 ns
        #20;
        KEY[0] = 1'b0;
        #100;
        KEY[0] = 1'b1;

        // Pulse lightTrigger every 1 second (1,000,000,000 ns)
        forever begin
            #1000000000;
            @(posedge CLOCK_50);
            lightTrigger <= 1'b1;
            @(posedge CLOCK_50);
            lightTrigger <= 1'b0;
        end
    end

    // Stop simulation after ~3.5 seconds of simulated time
    initial begin
        #3500000000;
        $display("Simulation finished at %0t ns", $time);
        $stop;
    end

endmodule

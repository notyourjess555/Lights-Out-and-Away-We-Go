module ranNum(CLOCK_50, KEY, num);
	input [0:0] KEY;
	output [3:0] num;
	input CLOCK_50;
	
	wire reset;
	assign reset = KEY[0];
	
	
	
	wire a, b, c, d, e;
	
	reg [25:0] bigCounter;
	reg [4:0] smallCounter;
	reg [2:0] fiveCount;
	
	always@(posedge CLOCK_50)
	begin
		if (bigCounter == 26'd9)
			bigCounter <= 26'd0;
		else if (reset == 1'b0)
			bigCounter <= 26'd0;
		else
			bigCounter <= bigCounter + 1'b1;
	end
	
	initial begin
		smallCounter = 5'd0;
		bigCounter = 26'd0;
	end
	
	always@(posedge CLOCK_50)
	begin
		if (bigCounter == 26'd0)
		
		begin
			if (smallCounter == 5'd31)
				smallCounter <= 5'd0;
			else
			begin
				smallCounter <= smallCounter + 1'b1;
			end
		end
	end
	
	
	assign a = smallCounter[4];
	assign b = smallCounter[3];
	assign c = smallCounter[2];
	assign d = smallCounter[1];
	assign e = smallCounter[0];
	
	wire inA;
	wire [4:0] randomVals;
	
	assign inA = (~randomVals[2] & randomVals[4])|(randomVals[2] & ~randomVals[4]);
	
	
	
	ff f1(CLOCK_50, reset, a, inA, randomVals[0]);
	ff f2(CLOCK_50, reset, b, randomVals[0], randomVals[1]);
	ff f3(CLOCK_50, reset, c, randomVals[1], randomVals[2]);
	ff f4(CLOCK_50, reset, d, randomVals[2], randomVals[3]);
	ff f5(CLOCK_50, reset, e, randomVals[3], randomVals[4]);
	
	wire [3:0] outNum;
	assign outNum[2] = randomVals[2];
	assign outNum[1] = randomVals[3];
	assign outNum[0] = randomVals[4];
	assign outNum[3] = 0;
	
	displayLight l1(CLOCK_50, reset, outNum, num[3:0]);
		
endmodule
	
	
	
module displayLight(clock, reset, num, light);
	input clock;
	input reset;
	input [3:0] num;
	output reg [3:0] light;
	reg flag;
	
	reg [5:0] bigCount;
	
	always@(posedge clock)
	begin
		if (reset == 1'b0)
		begin
			bigCount <= 6'd0;
			flag <= 1'b0;
		end
		else if (flag == 1'b0)
		begin
			if (bigCount == 6'd63)
			begin
				flag <= 1'b1;
				light <= num + 3'd2;
			end
			else
				bigCount <= bigCount + 1'b1;
		end
	end
	
endmodule
	
	
module ff(clock, resetn, valStart, inp, Q);
	input clock, resetn, valStart, inp;
	output reg Q;
	always@(posedge clock)
	begin
		if (resetn == 1'b0)
			Q <= valStart;
		else
			Q <= inp;
	end
endmodule

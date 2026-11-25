

module trafficLight5(CLOCK50, SW, KEY, LEDR, PS2CLK, PS2DAT,
                     VGAR, VGAG, VGAB,
                     VGAHS, VGAVS, VGABLANKN, VGASYNCN, VGACLK);

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    // state names for the FSM
    parameter A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

    // spacebar scancode and step interval (50,000,000 = 1s at 50 MHz)
    parameter [7:0]  SPACESCAN = 8'h29;
    parameter        counter = 32'd50000000;
    parameter        OFFMIF    = "./MIF/offL.mif";
    parameter        ONMIF     = "./MIF/onL.mif";

    input  wire       CLOCK50;
    input  wire [9:0] SW;
    input  wire [3:0] KEY;
    output wire [9:0] LEDR;
    inout  wire       PS2CLK, PS2DAT;
    output wire [7:0] VGAR;
    output wire [7:0] VGAG;
    output wire [7:0] VGAB; 
    output wire       VGAHS;
    output wire       VGAVS;
    output wire       VGABLANKN;
    output wire       VGASYNCN;
    output wire       VGACLK;
	 
	 wire key1sync;
	 wire key1press;
	 reg key1prev;
	 sync key1(~KEY[1], Resetn, CLOCK50, key1sync);
	 
	 always@(posedge CLOCK50)
	 begin
		if (!Resetn)
		begin
			key1prev <= 1'b0;
		end
		else
		begin
			key1prev <= key1sync;
		end
	end
	assign key1press = key1sync & ~key1prev;
	
	

    // Multiplexed pixel signals for the 5 traffic lights -> VGA adapter
    wire [nX-1:0] MUXx;
    wire [nY-1:0] MUXy;
    wire [8:0]    MUXcolor;
    wire          MUXwrite;

    reg        prevps2clk;     // ps2clk value in the previous clock cycle
    wire       negedgeps2clk;  // falling edge of synchronized PS2CLK
    wire       ps2rec;          // set when a PS2 packet has been received
    reg  [32:0] Serial;          // 33-bit PS2 shift register
    reg  [3:0]  Packet;          // counts received PS2 bits
    wire [7:0]  scancode;        // current latched PS2 scancode
    reg         Esc;             // enable scancode register
    reg         step;            // pulse to trigger a draw/erase pass across all 5 lights
    reg  [1:0]  yQ, YD;        // FSM state register and next-state logic

    wire Resetn;
    wire PS2CLKS, PS2DATS;

    assign Resetn = KEY[0];

    sync S3 (PS2CLK, Resetn, CLOCK50, PS2CLKS);
    sync S4 (PS2DAT, Resetn, CLOCK50, PS2DATS);

    always @(posedge CLOCK50)
        prevps2clk <= PS2CLKS;

    assign negedgeps2clk = (prevps2clk & !PS2CLKS);

    always @(posedge CLOCK50) begin
        if (Resetn == 0)
            Serial <= 33'b0;
        else if (negedgeps2clk) begin
            Serial[31:0] <= Serial[32:1];
            Serial[32]   <= PS2DATS;
        end
    end

    always @(posedge CLOCK50) begin
        if (!Resetn || Packet == 'd11)
            Packet <= 'b0;
        else if (negedgeps2clk) begin
            Packet <= Packet + 'b1;
        end
    end

    assign ps2rec = (Packet == 'd11) && (Serial[30:23] == Serial[8:1]);

    regn USC (Serial[8:1], Resetn, Esc, CLOCK50, scancode);

    // 5-light state, start/stop toggle, erase flag, and time progression
    reg        lightsrunning;  // 0 = lights hidden/off, 1 = lights started/active
    reg        eraseall;       // 1 = erase 5 lights, 0 = draw 5 lights
    reg  [4:0] lights;          // 5-light ON/OFF pattern
    reg  [31:0] timecnt;

    wire [nX-1:0] tlx     [0:4];
    wire [nY-1:0] tly     [0:4];
    wire [8:0]    tlcolor [0:4];
	 wire [12:0] 	tlromaddr [4:0];
    wire [4:0]    tlwrite;
    wire [4:0]    tldone;
    wire [4:0]    tlstart;

    wire anytlwrite = |tlwrite;
    wire done         = tldone[4];

    assign LEDR = {4'b0000, lightsrunning, lights};

    always @(posedge CLOCK50) begin
        if (!Resetn)
            yQ <= A;
        else
            yQ <= YD;
    end

    // FSM state table
    always @(*)
        case (yQ)
            A:  if (!ps2rec) YD = A;
                else          YD = B;
            B:  YD = C;        // enable scancode register
            C:  YD = D;        // assert step if spacebar pressed
            D:  if (done == 1'b0 && anytlwrite == 1'b1) YD = D;
                else if (done == 1'b0 && !lightsrunning && !eraseall) YD = D;
                else YD = A;
            default: YD = A;
        endcase

    // FSM outputs
    always @(*) begin
        Esc  = 1'b0;
        step = 1'b0;
        case (yQ)
            A:  ;
            B:  Esc = 1'b1;
            C:  if (scancode == SPACESCAN) step = 1'b1;
            D:  ;
        endcase
		  if (key1press && ~anytlwrite)
		  begin
			step = 1'b1;
		  end
    end

    // Spacebar toggle (1st press: lights start; 2nd press: lights are gone) + time stepping
    always @(posedge CLOCK50) begin
        if (!Resetn) begin
            lightsrunning <= 1'b0;
            eraseall      <= 1'b0;
            lights         <= 5'b00000;
            timecnt       <= 32'd0;
        end else begin
            if (step) begin
                if (!lightsrunning) begin
                    lightsrunning <= 1'b1;
                    eraseall      <= 1'b0;
                    lights         <= 5'b00001;
                    timecnt       <= 32'd0;
                end else begin
                    lightsrunning <= 1'b0;
                    eraseall      <= 1'b1;
                    lights         <= 5'b00000;
                    timecnt       <= 32'd0;
                end
            end else if (lightsrunning && !anytlwrite && (yQ == A)) begin
                if (timecnt == counter - 1) begin
                    timecnt <= 32'd0;
                    if (lights == 5'b11111)
                        lights <= 5'b00000;
                    else
                        lights <= {lights[3:0], 1'b1};
                end else begin
                    timecnt <= timecnt + 32'd1;
                end
            end
        end
    end

    // Trigger redraw whenever step is asserted or lights changes while running
    reg [4:0] prevlights;
    always @(posedge CLOCK50) begin
        if (!Resetn)
            prevlights <= 5'b00000;
        else
            prevlights <= lights;
    end

    wire redrawpulse = step || (lightsrunning && (lights != prevlights));
	 
	 wire [8:0] qoff;
	 wire [8:0] qon;
	 wire [12:0] romaddr = tlromaddr[0] | tlromaddr[1] | tlromaddr[2] | tlromaddr[3] | tlromaddr[4];
	 
	 objectmem #(.n(9), .Mn(13), .INITFILE(OFFMIF)) offL (romaddr, CLOCK50, qoff);
    objectmem #(.n(9), .Mn(13), .INITFILE(ONMIF))  onL  (romaddr, CLOCK50, qon);

	 
    // Chain start pulses across the 5 trafficLight instances so only one writes at a time
    assign tlstart[0] = redrawpulse;
    assign tlstart[1] = tldone[0];
    assign tlstart[2] = tldone[1];
    assign tlstart[3] = tldone[2];
    assign tlstart[4] = tldone[3];

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : genlights
            trafficLight #(
                .nX(nX),
                .nY(nY),
                .width(36),
                .height(148),
                .address(13),
                .BASEX(10'd180 + i * 10'd44),
                .BASEY(9'd150),
                .removeLights(9'b000000000),
                .offLight(OFFMIF),
                .onLight(ONMIF)
                .CLOCK50(CLOCK50),
                .reset(Resetn),
                .start(tlstart[i]),
                .lights(lights),
                .oX(tlx[i]),
                .oY(tly[i]),
                .colourO(tlcolor[i]),
                .write(tlwrite[i]),
                .done(tldone[i]),
                .erase(eraseall),
                .on(lights[i]),
		.qoff(qoff),
		.qon(qon),
		.romaddress(tlromaddr[i])
            );
        end
    endgenerate

    assign MUXx     = tlwrite[0] ? tlx[0]     :
                       tlwrite[1] ? tlx[1]     :
                       tlwrite[2] ? tlx[2]     :
                       tlwrite[3] ? tlx[3]     : tlx[4];

    assign MUXy     = tlwrite[0] ? tly[0]     :
                       tlwrite[1] ? tly[1]     :
                       tlwrite[2] ? tly[2]     :
                       tlwrite[3] ? tly[3]     : tly[4];

    assign MUXcolor = tlwrite[0] ? tlcolor[0] :
                       tlwrite[1] ? tlcolor[1] :
                       tlwrite[2] ? tlcolor[2] :
                       tlwrite[3] ? tlcolor[3] : tlcolor[4];

    assign MUXwrite = |tlwrite;

    // connect to VGA controller
    vgaadapter VGA (
        .resetn(Resetn),
        .clock(CLOCK50),
        .color(MUXcolor),
        .x(MUXx),
        .y(MUXy),
        .write(MUXwrite),
        .VGAR(VGAR),
        .VGAG(VGAG),
        .VGAB(VGAB),
        .VGAHS(VGAHS),
        .VGAVS(VGAVS),
        .VGABLANKN(VGABLANKN),
        .VGASYNCN(VGASYNCN),
        .VGACLK(VGACLK)
    );

endmodule


// synchronizer, implemented as two FFs in series
module sync(D, Resetn, Clock, Q);
    input  wire D;
    input  wire Resetn, Clock;
    output reg  Q;

    reg Qi; // internal node

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q  <= 1'b0;
        end else begin
            Qi <= D;
            Q  <= Qi;
        end
endmodule


// 8-bit register with enable and active-low synchronous reset
module regn(D, Resetn, en, Clock, Q);
    parameter n = 8;
    input  wire [n-1:0] D;
    input  wire         Resetn, en, Clock;
    output reg  [n-1:0] Q;

    always @(posedge Clock) begin
        if (!Resetn)
            Q <= {n{1'b0}};
        else if (en)
            Q <= D;
    end
endmodule


module trafficLight(CLOCK50, reset, start, lights, oX, oY, colourO, write, done, erase, on, qoff, qon, romaddress);
    parameter nX           = 10;
    parameter nY           = 9;
    parameter width        = 36;
    parameter height       = 148;
    parameter address      = 13;
    parameter [nX-1:0] BASEX       = 10'd180;
    parameter [nY-1:0] BASEY       = 9'd150;
    parameter [8:0]    removeLights = 9'b000000000;
    parameter          offLight     = "./MIF/offL.mif";
    parameter          onLight      = "./MIF/onL.mif";
    parameter OFF = 2'b00, WRITING = 2'b01, DONE = 2'b10;

    input  wire          CLOCK50;
    input  wire          reset;
    input  wire          start;
    input  wire [4:0]    lights;
    output reg  [nX-1:0] oX;
    output reg  [nY-1:0] oY;
    output reg  [8:0]    colourO;
    output reg           write;
    output reg           done;
    input  wire          erase;
    input  wire          on;
	 output wire [address-1:0] romaddress;

    reg [7:0] yc;
    reg [5:0] xc;

    reg [1:0] currState;

    reg [nX-1:0] xd1;
    reg [nY-1:0] yd1;
    reg          ond1;
    reg          erased1;
    reg          d1valid;

    input wire [8:0]           qoff;
    input wire [8:0]           qon;

    assign romaddress = yc * width + xc;

    always @(posedge CLOCK50 or negedge reset) begin
        if (!reset) begin
            currState <= OFF;
            yc        <= 8'd0;
            xc        <= 6'd0;
            xd1       <= {nX{1'b0}};
            yd1       <= {nY{1'b0}};
            ond1      <= 1'b0;
            erased1  <= 1'b0;
            d1valid   <= 1'b0;
            oX        <= {nX{1'b0}};
            oY        <= {nY{1'b0}};
            colourO   <= 9'd0;
            write     <= 1'b0;
            done      <= 1'b0;
        end else begin
            done    <= 1'b0;
            write   <= d1valid;
            if (d1valid) begin
                oX      <= xd1;
                oY      <= yd1;
                colourO <= erased1 ? removeLights : (ond1 ? qon : qoff);
            end
            d1valid <= 1'b0;

            case (currState)
                OFF: begin
                    if (start) begin
                        yc        <= 8'd0;
                        xc        <= 6'd0;
                        currState <= WRITING;
                    end
                end

                WRITING: begin
                    xd1      <= BASEX + xc;
                    yd1      <= BASEY + yc;
                    ond1     <= on;
                    erased1 <= erase;
                    d1valid  <= 1'b1;

                    if (xc == width - 1) begin
                        xc <= 6'd0;
                        if (yc == height - 1) begin
                            yc        <= 8'd0;
                            currState <= DONE;
                        end else begin
                            yc <= yc + 8'd1;
                        end
                    end else begin
                        xc <= xc + 6'd1;
                    end
                end

                DONE: begin
                    done      <= 1'b1;
                    currState <= OFF;
                end

                default: currState <= OFF;
            endcase
        end
    end

endmodule


	
	
	
	
	

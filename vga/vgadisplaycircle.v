// ============================================================================
// vgadisplaycircle.v - 320 x 240 to save memory
//
// ROLE: draw the 5 traffic lights on the monitor using an FSM + counters.
//       It only READS "lights" from the game, it never changes the game.
//
// GAME LOOP (screen side):
//   1. INIT   : CLEAR paints the whole 640x480 screen black, then the first
//               pass draws all 5 lights grey (what the player sees at start-up)
//   2. WAIT   : do nothing until "lights" is different from what is on screen
//   3. DRAW   : go through the 5 lights, only redraw the ones that changed
//               (draw = red box, erase = grey box), then go back to WAIT
//
// COUNTERS (Up_count, same as boxmaking.v):
//   XC - x inside the box (or inside the screen while clearing)
//   YC - y inside the box (or inside the screen while clearing)
//   LC - which light we are checking (0 = leftmost ... 4 = rightmost)
//
// STATES:
//   CLEAR      - one pixel per clock, XC 0..319 then YC + 1, until (319,239)
//   WAIT       - hold all counters at 0, wait for lights to change
//   CHECK      - did light LC change? yes -> DRAW_ROW, no -> NEXT_LIGHT
//   DRAW_ROW   - draw one pixel of light LC per clock, XC + 1
//   NEXT_ROW   - XC back to 0, YC + 1 (same as state C in boxmaking.v)
//   NEXT_LIGHT - remember what light LC now shows, LC + 1
//
// ============================================================================

module vgadisplaycircle(CLOCK_50, resetn, lights, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    //-------variables-------//

    //input
	input CLOCK_50;
    input resetn;
    input [4:0] lights;   

    //outputs (VGA pins)
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    //--------------STATES-----------//
    parameter CLEAR = 3'd0, WAIT = 3'd1, CHECK = 3'd2, DRAW_ROW = 3'd3,
    NEXT_ROW = 3'd4, NEXT_LIGHT = 3'd5;


    //-------------screen-------------//
	//change to match screen
    parameter X_START = 97;   //x of the leftmost light (top-left corner)
    parameter Y_START = 85;   //y of all lights (top-left corner)
    parameter BOX_W = 14;      //each light box is BOX_W x BOX_H pixels
    parameter BOX_H = 28;      //(2 bulbs stacked vertically)
    parameter SPACING = 28;    //distance between the left edges of two lights

    parameter BLACK = 9'b000_000_000;  //colour = RRR GGG BBB
    parameter RED   = 9'b111_000_000;
    parameter GREY  = 9'b010_010_010;

    //NEW:------introducing new colours--------//
    parameter DARK_RED  = 9'b100_000_000;
    parameter DARK_GREY = 9'b001_001_001;

    //NEW:-------------round light-------------//
    parameter CENTER_X = 7;    //bulb centre x inside the box
    parameter CENTER_Y1 = 7;   //top bulb centre y inside the box
    parameter CENTER_Y2 = 20;  //bottom bulb centre y inside the box
    parameter INNER_R2 = 20;   //bulb radius ~4.5 -> 4.5*4.5
    parameter OUTER_R2 = 42;   //glow ring radius ~6.5 -> 6.5*6.5
	
    //------counters----//
    wire [8:0] XC; //X-coordinate
    wire [7:0] YC; //Y-coordinate
    wire [2:0] LC; //Light counter

    //-------------screen right now----------------//
    reg [4:0] drawn_lights;
    reg target_on; //1 red, 0 
    
    //light LC in the game right now
    wire light_now;

    //light LC on the screen right now
    wire light_drawn;

    assign light_now = lights[3'd4 - LC];
    assign light_drawn = drawn_lights[3'd4 - LC];

    //----FSM signals----//
    reg[2:0] y_Q, Y_D;  //current state, next state
    reg write;
    reg [8:0] colour;
    reg Lxc, Lyc, Llc;  //load counter to 0
    reg Exc, Eyc, Elc;  //enable counter

    //-----round light-----//
    //colour depends on distance from the box centre

    wire signed [6:0] dx, dy;  //signed: negative = left of / above the centre
    wire [9:0] dist2;          //distance squared (no square root needed)
    //Changed
	//top half of the box -> measure from the top bulb
	//bottom half -> from the bottom bulb
    assign dx = $signed({2'b00, XC[4:0]}) - CENTER_X;
    assign dy = (YC < 14) ? ($signed({2'b00, YC[4:0]}) - CENTER_Y1)
                          : ($signed({2'b00, YC[4:0]}) - CENTER_Y2);
    assign dist2 = dx*dx + dy*dy;
	
	reg [8:0] light_colour;
    always@(*)
    begin
        if(dist2 < INNER_R2)        light_colour = target_on ? RED : GREY;            //bulb
        else if(dist2 < OUTER_R2)   light_colour = target_on ? DARK_RED : DARK_GREY;  //glow ring
        else                        light_colour = BLACK;                             //housing
    end

    //------------------------code------------------------//

    //-----counters-----//
    Up_count UX (9'd0, CLOCK_50, resetn, Lxc, Exc, XC);
        defparam UX.n = 9;
    Up_count UY (8'd0, CLOCK_50, resetn, Lyc, Eyc, YC);
        defparam UY.n = 8;
    Up_count UL (3'd0, CLOCK_50, resetn, Llc, Elc, LC);
        defparam UL.n = 3;


    //-------FSM-------//
    always@(*)
    begin
        case(y_Q)

            CLEAR: if(YC < 239 || XC < 319) Y_D = CLEAR;
                else Y_D = WAIT;

            WAIT: if(lights != drawn_lights) Y_D = CHECK;
                else Y_D = WAIT;

            CHECK: if(light_now != light_drawn) Y_D = DRAW_ROW;
                else Y_D = NEXT_LIGHT;

			DRAW_ROW:  if(XC != BOX_W-1) Y_D = DRAW_ROW; //still inside this row
                else Y_D = NEXT_ROW;

			NEXT_ROW: if(YC != BOX_H-1) Y_D = DRAW_ROW;  //more rows to draw
                else Y_D = NEXT_LIGHT;

            NEXT_LIGHT: if(LC != 3'd4) Y_D = CHECK;   //more lights to check
                else Y_D = WAIT;
            
            default: Y_D = CLEAR;
        endcase
    end

    //-----FSM outputs-----//
    always@(*)
    begin
        //default: do nothing
        write = 1'b0; colour = BLACK;
        Lxc = 1'b0; Lyc = 1'b0; Llc = 1'b0;
        Exc = 1'b0; Eyc = 1'b0; Elc = 1'b0;

        case(y_Q)

            //--------------CLEAR--------------//
            //erase the screen(cover with black pixels)

            CLEAR:
            begin
                write = 1'b1; 
                colour = BLACK; 
                Exc = 1'b1;
                if(XC == 319) //end of a screen row
                begin
                    Lxc = 1'b1; //reset xc to 0
                    Eyc = 1'b1; //increment yc to next row
                end
            end

            //--------------WAIT--------------//
            //prepare the counters
            WAIT:
            begin 
                Lxc = 1'b1; 
                Lyc = 1'b1; 
                Llc = 1'b1; 
            end   //all counters to 0

            //--------------CHECK--------------//
            //prepare to draw one light
            //to draw the next light, set light's xc and yc drawing area to 0
            CHECK:
            begin 
                Lxc = 1'b1; 
                Lyc = 1'b1; 
            end      

            //--------------DRAW_ROW--------------//
            DRAW_ROW:
            begin 
                write = 1'b1;
                Exc = 1'b1;
                colour = light_colour;
            end

            //--------------NEXT_ROW--------------//
            NEXT_ROW:
            begin 
                Lxc = 1'b1;
                Eyc = 1'b1;
            end

            //------------NEXT_LIGHT------------//
            NEXT_LIGHT:
                Elc = 1'b1;
        endcase
    end

    //----------state register-------------//
    //remember what is on screen
    always@(posedge CLOCK_50)
    begin
        if(!resetn)
        begin
            y_Q <= WAIT; //changed from clear to wait, no earse

            //pretend all lights are ON, so the first pass draws all 5 grey
            //lights = 0 after reset
            drawn_lights <= 5'b11111;
            target_on <= 1'b0;
        end
        else
        begin
            y_Q <= Y_D;

            //take a snapshot of the light,
            //so a change in the middle of drawing does not mix colours
            if(y_Q == CHECK)
                target_on <= light_now;

            //this light is now on the screen
            if(y_Q == NEXT_LIGHT)
                //from bit4 to bit0
                drawn_lights[3'd4 - LC] <= target_on;
        end
    end

    //-----pixel position-----//
    wire [8:0] pixel_x;
    wire [7:0] pixel_y;
    assign pixel_x = (y_Q == CLEAR) ? XC : (X_START + LC * SPACING + XC);
    assign pixel_y = (y_Q == CLEAR) ? YC : (Y_START + YC);

    //-----VGA adapter-----//
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(colour),
        .x(pixel_x),
        .y(pixel_y),
        .write(write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));

		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.BACKGROUND_IMAGE = "./f1_home_320_9.mif";

endmodule

//n-bit up-counter with reset, load, and enable
module Up_count(R, Clock, Resetn, L, E, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Clock, Resetn, E, L;
    output reg [n-1:0] Q;

    always@(posedge Clock)
        if(Resetn == 0)
            Q <= {n{1'b0}};
        else if(L == 1)
            Q <= R;
        else if(E)
            Q <= Q + 1'b1;
endmodule

// ============================================================================
// vgadisplay.v 
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
//   CLEAR      - one pixel per clock, XC 0..639 then YC + 1, until (639,479)
//   WAIT       - hold all counters at 0, wait for lights to change
//   CHECK      - did light LC change? yes -> DRAW_ROW, no -> NEXT_LIGHT
//   DRAW_ROW   - draw one pixel of light LC per clock, XC + 1
//   NEXT_ROW   - XC back to 0, YC + 1 (same as state C in boxmaking.v)
//   NEXT_LIGHT - remember what light LC now shows, LC + 1
//
// NEEDS: vga_adapter.v, vga_controller.v, vga_address_translator.v, vga_pll.v
// ============================================================================

module vgadisplay(CLOCK_50, resetn, lights, VGA_R, VGA_G, VGA_B,
                  VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    //--------variables---------//

    //inputs
    input CLOCK_50;
    input resetn;
    input [4:0] lights;              //from gamecontroller, lights[4] = leftmost light

    //outputs (VGA pins)
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    //----------------------STATES-----------------------//

    parameter CLEAR = 3'd0, WAIT = 3'd1, CHECK = 3'd2, DRAW_ROW = 3'd3, NEXT_ROW = 3'd4, NEXT_LIGHT = 3'd5;

    //----------------------SCREEN-----------------------//

    parameter X_START = 160;         //x of the leftmost light (top-left corner)
    parameter Y_START = 200;         //y of all lights (top-left corner)
    parameter SIZE = 48;             //each light is SIZE x SIZE pixels
    parameter SPACING = 64;          //distance between the left edges of two lights

    parameter BLACK = 9'b000_000_000;   //colour = RRR GGG BBB
    parameter RED   = 9'b111_000_000;
    parameter GREY  = 9'b010_010_010;

    //----------------------FSM signals-----------------------//

    reg [2:0] y_Q, Y_D;              //current state, next state
    reg write;                       //1 = write the pixel (x,y) this clock
    reg [8:0] colour;                //colour of the pixel being written
    reg Lxc, Lyc, Llc;               //load (reset) counter to 0
    reg Exc, Eyc, Elc;               //enable counter (+1)

    //counters
    wire [9:0] XC;
    wire [8:0] YC;
    wire [2:0] LC;

    //what is on the screen right now
    reg [4:0] drawn_lights;
    reg target_on;                   //colour chosen for the light being drawn (1 = red)

    wire light_now;                  //light LC in the game right now
    wire light_drawn;                //light LC on the screen right now
    assign light_now = lights[3'd4 - LC];
    assign light_drawn = drawn_lights[3'd4 - LC];

    //---------code---------//

    //-----counters-----//
    Up_count UX (10'd0, CLOCK_50, resetn, Lxc, Exc, XC);
        defparam UX.n = 10;
    Up_count UY (9'd0, CLOCK_50, resetn, Lyc, Eyc, YC);
        defparam UY.n = 9;
    Up_count UL (3'd0, CLOCK_50, resetn, Llc, Elc, LC);
        defparam UL.n = 3;

    //-----FSM state table (next state)-----//
    always@(*)
    begin
        case(y_Q)
            CLEAR:      if(YC < 479 || XC < 639) Y_D = CLEAR;
                        else Y_D = WAIT;

            WAIT:       if(lights != drawn_lights) Y_D = CHECK;
                        else Y_D = WAIT;

            CHECK:      if(light_now != light_drawn) Y_D = DRAW_ROW;
                        else Y_D = NEXT_LIGHT;

            DRAW_ROW:   if(XC != SIZE-1) Y_D = DRAW_ROW;     //still inside this row
                        else Y_D = NEXT_ROW;

            NEXT_ROW:   if(YC != SIZE-1) Y_D = DRAW_ROW;     //more rows to draw
                        else Y_D = NEXT_LIGHT;

            NEXT_LIGHT: if(LC != 3'd4) Y_D = CHECK;          //more lights to check
                        else Y_D = WAIT;

            default:    Y_D = CLEAR;
        endcase
    end

    //-----FSM outputs (control signals)-----//
    always@(*)
    begin
        //default: do nothing
        write = 1'b0; colour = BLACK;
        Lxc = 1'b0; Lyc = 1'b0; Llc = 1'b0;
        Exc = 1'b0; Eyc = 1'b0; Elc = 1'b0;

        case(y_Q)
            CLEAR:
            begin
                write = 1'b1; colour = BLACK; Exc = 1'b1;
                if(XC == 639)               //end of a screen row
                begin
                    Lxc = 1'b1;
                    Eyc = 1'b1;
                end
            end

            WAIT:       begin Lxc = 1'b1; Lyc = 1'b1; Llc = 1'b1; end   //all counters to 0

            CHECK:      begin Lxc = 1'b1; Lyc = 1'b1; end               //start box at (0,0)

            DRAW_ROW:   begin write = 1'b1; Exc = 1'b1; colour = target_on ? RED : GREY; end

            NEXT_ROW:   begin Lxc = 1'b1; Eyc = 1'b1; end

            NEXT_LIGHT: Elc = 1'b1;
        endcase
    end

    //-----state register + remember what is on screen-----//
    always@(posedge CLOCK_50)
    begin
        if(!resetn)
        begin
            y_Q <= CLEAR;
            //pretend all lights are ON, so the first pass draws all 5 grey (lights = 0 after reset)
            drawn_lights <= 5'b11111;
            target_on <= 1'b0;
        end
        else
        begin
            y_Q <= Y_D;

            //take a snapshot of the light, so a change in the middle of drawing does not mix colours
            if(y_Q == CHECK)
                target_on <= light_now;

            //this light is now on the screen
            if(y_Q == NEXT_LIGHT)
                drawn_lights[3'd4 - LC] <= target_on;
        end
    end //end always

    //-----pixel position-----//
    wire [9:0] pixel_x;
    wire [8:0] pixel_y;
    assign pixel_x = (y_Q == CLEAR) ? XC : (X_START + LC * SPACING + XC);
    assign pixel_y = (y_Q == CLEAR) ? YC : (Y_START + YC);

    //-----VGA adapter (course code)-----//
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

endmodule


//n-bit up-counter with reset, load, and enable (from boxmaking.v / course demo)
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

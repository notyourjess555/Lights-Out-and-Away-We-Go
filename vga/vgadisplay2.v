// ============================================================================
// vgadisplay.v 
//
// ROLE: show the game on the monitor. It only READS lights/state from the
//       controller, it never changes the game.
//
// HOW IT WORKS:
//   The VGA adapter has its own memory, so a pixel stays on screen until we
//   overwrite it. We do not redraw every frame, we only redraw when something
//   changes (lights, state or false start).
//
//   Redraw = sweep a 320 x 64 pixel area, one pixel per clock:
//     rows  0..47 : 5 lights, each 48x48, one light every 64 pixels
//     rows 48..55 : black gap
//     rows 56..63 : status bar, colour depends on the state
//   320 x 64 = 20,480 clocks = 0.4 ms, too fast for the eye to see.
//
// COLOURS (9-bit, RRR GGG BBB):
//   light on  = red      light off = dark grey
//   status bar: IDLE white, LIGHTS/WAIT red, GO green,
//               RESULT blue (reacted) or yellow (false start)
//
// NEEDS: the course vga_adapter files in the project (same ones as boxmaking.v)
// ============================================================================

module vgadisplay(CLOCK_50, resetn, lights, state, p1_false_start,
                  VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    //--------variables---------//

    //inputs (from gamecontroller)
    input CLOCK_50;
    input resetn;
    input [4:0] lights;
    input [2:0] state;
    input p1_false_start;

    //outputs (to the VGA pins)
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    //states, must match gamecontroller.v
    parameter IDLE = 3'd0, LIGHTS = 3'd1, WAIT = 3'd2, GO = 3'd3, RESULT = 3'd4;

    //where the drawing area starts on the 640x480 screen (top-left corner)
    parameter X_START = 160;
    parameter Y_START = 200;
    parameter LIGHT_SIZE = 48;

    //colours
    parameter BLACK  = 9'b000_000_000;
    parameter WHITE  = 9'b111_111_111;
    parameter RED    = 9'b111_000_000;
    parameter GREEN  = 9'b000_111_000;
    parameter BLUE   = 9'b000_000_111;
    parameter YELLOW = 9'b111_111_000;
    parameter GREY   = 9'b010_010_010;

    //what is on the screen right now (copied when a redraw starts)
    reg [4:0] drawn_lights;
    reg [2:0] drawn_state;
    reg drawn_false_start;

    //drawing counters
    reg drawing;          //1 = currently sweeping the area
    reg [8:0] x_count;    //0..319
    reg [5:0] y_count;    //0..63

    //---------code---------//

    //-----decide when to redraw and move the x/y counters-----//
    always@(posedge CLOCK_50)
    begin
        if(!resetn)
        begin
            drawing <= 1'b1;          //draw once after reset (all lights off)
            x_count <= 9'd0;
            y_count <= 6'd0;
            drawn_lights <= 5'b0;
            drawn_state <= IDLE;
            drawn_false_start <= 1'b0;
        end
        else if(!drawing)
        begin
            //something changed -> take a snapshot and start a new sweep
            if(lights != drawn_lights || state != drawn_state || p1_false_start != drawn_false_start)
            begin
                drawn_lights <= lights;
                drawn_state <= state;
                drawn_false_start <= p1_false_start;
                x_count <= 9'd0;
                y_count <= 6'd0;
                drawing <= 1'b1;
            end
        end
        else
        begin
            //sweep: left to right, then next row
            if(x_count == 9'd319)
            begin
                x_count <= 9'd0;
                if(y_count == 6'd63)
                    drawing <= 1'b0;  //finished the whole area
                else
                    y_count <= y_count + 1'b1;
            end
            else
                x_count <= x_count + 1'b1;
        end
    end //end always

    //-----pick the colour of the current pixel-----//

    //each light takes 64 pixels: x_count[8:6] = which light (0..4), x_count[5:0] = position inside it
    wire [2:0] light_index;
    wire inside_light;
    wire light_on;

    assign light_index = x_count[8:6];
    assign inside_light = (x_count[5:0] < LIGHT_SIZE) && (y_count < LIGHT_SIZE);
    assign light_on = drawn_lights[3'd4 - light_index];   //lights[4] is the leftmost light

    reg [8:0] status_colour;
    always@(*)
    begin
        case(drawn_state)
            IDLE:    status_colour = WHITE;
            LIGHTS:  status_colour = RED;
            WAIT:    status_colour = RED;
            GO:      status_colour = GREEN;
            RESULT:  status_colour = drawn_false_start ? YELLOW : BLUE;
            default: status_colour = BLACK;
        endcase
    end

    reg [8:0] pixel_colour;
    always@(*)
    begin
        if(y_count >= 6'd56)
            pixel_colour = status_colour;           //status bar
        else if(inside_light)
            pixel_colour = light_on ? RED : GREY;   //a light
        else
            pixel_colour = BLACK;                   //gaps
    end

    //screen position of the current pixel (640x480: x needs 10 bits, y needs 9 bits)
    wire [9:0] pixel_x;
    wire [8:0] pixel_y;
    assign pixel_x = X_START + x_count;
    assign pixel_y = Y_START + y_count;

    //-----VGA adapter (course code)-----//
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(pixel_colour),
        .x(pixel_x),
        .y(pixel_y),
        .write(drawing),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));

endmodule

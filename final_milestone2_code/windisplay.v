module windisplay(multiplayer, winner, HEX, state);
    input multiplayer, winner;
    output [6:0] HEX;
    input [2:0] state;
    assign HEX = ((state != 3'd4) || !multiplayer) ? 7'b1111111 : winner ? 7'b0100100 : 7'b1111001;
endmodule
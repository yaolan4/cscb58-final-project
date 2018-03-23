// Top level module. Handles instantiation, controls,
// Also potentially bouncing of bees. Might want to refactor this into mechanics

module proj (
	input CLOCK_50,
	input [17:0] SW,
    input [3:0] KEY,
	output [17:0] LEDR);
	
	
    wire [3:0] player_dir;
    wire player_load_xy;
    wire player_clear;
    reg  [2:0] player_color = 3'b111;     // Change color to whatever
    wire [2:0] player_color_out;
    wire [6:0] player_x_out;
    wire [6:0] player_y_out;
    reg [6:0] player_x_start;
    reg [6:0] player_y_start;
    wire player_writeEn;
    reg [27:0] player_rate;
    reg [27:0] player_offset;

    

    datapath data_player(// Input
                        .clk(CLOCK_50),
                        .dir_in(player_dir),
                        .load_xy(player_load_xy),
                        .clear(player_clear),
                        .x_in(player_x_start),
                        .y_in(player_y_start),
                        .color_in(player_color),
                        // Output
                        .x_out(player_x_out),
                        .y_out(player_y_out),
                        .color_out(player_color_out),
                        .writeEn(player_writeEn)
                        );

    control ctrl_player(// Input
                        .clk(CLOCK_50),
                        .dir_in(KEY[3:0]),
                        .reset_n(),
                        .game_reset(),
                        .rate(player_rate),
                        .offset(player_offset),
                        // Outputs
                        .load_xy(player_load_xy),
                        .clear(player_clear),
                        .dir_out(player_dir)
                        );

    // fuck you quartus
endmodule 

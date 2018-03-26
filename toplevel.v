// Top level module. Handles instantiation, controls,
// Also potentially bouncing of bees. Might want to refactor this into mechanics

module proj (
        input CLOCK_50,
        input [17:0] SW,
        input [3:0] KEY,
        output [17:0] LEDR
    );
	


	
    
   // Create an Instance of a VGA controller - there can be only one!
   // Define the number of colours as well as the initial background
   // image file (.MIF) for the controller.
   vga_adapter VGA(
           .resetn(resetn),
           .clock(CLOCK_50),
           .colour(colour),
           .x(x),
           .y(y),
           .plot(writeEn),
           /* Signals for the DAC to drive the monitor. */
           .VGA_R(VGA_R),
           .VGA_G(VGA_G),
           .VGA_B(VGA_B),
           .VGA_HS(VGA_HS),
           .VGA_VS(VGA_VS),
           .VGA_BLANK(VGA_BLANK_N),
           .VGA_SYNC(VGA_SYNC_N),
           .VGA_CLK(VGA_CLK));
   defparam VGA.RESOLUTION = "160x120";
   defparam VGA.MONOCHROME = "FALSE";
   defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
   defparam VGA.BACKGROUND_IMAGE = "black.mif";



    wire game_over;
    wire reg [1:0] lives;
    wire reg [7:0] score;
    wire reg [7:0] high_score;

    mechanics mech(
        // Inputs
        .reset_n(),
        .user_x(player_x_out),
        .user_y(player_y_out),
        .bees_x(70'b0),
        .bees_y(70'b0),
        // Outputs
        .game_reset(),
        .game_over(game_over),
        .lives(lives),
        .score(),
        .high_score()
        );

    // -------------------------Player------------------------

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

    // ------------------------ Player modules end -----------------------
    // ---------------------------- Bees begin  --------------------------





    // fuck you quartus
endmodule 

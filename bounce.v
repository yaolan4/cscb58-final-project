// Part 2 skeleton

module bounce
    (
        CLOCK_50,						//	On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        LEDG,
        HEX0,
        HEX1,
        HEX2,
        HEX3,
        HEX4,
        HEX5,
        HEX6,
        HEX7,

        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,   						//	VGA Clock
        VGA_HS,							//	VGA H_SYNC
        VGA_VS,							//	VGA V_SYNC
        VGA_BLANK_N,					//	VGA BLANK
        VGA_SYNC_N,						//	VGA SYNC
        VGA_R,   						//	VGA Red[9:0]
        VGA_G,	 						//	VGA Green[9:0]
        VGA_B   						//	VGA Blue[9:0]
    );

    input	        CLOCK_50;				//	50 MHz
    input   [17:0]  SW;
    input   [3:0]   KEY;
    output 	[17:0]  LEDR;
    output 	[7:0]   LEDG;
    output 	[6:0]   HEX0;
    output 	[6:0]  HEX1;
    output 	[6:0]  HEX2;
    output 	[6:0]  HEX3;
    output 	[6:0]  HEX4;
    output 	[6:0]  HEX5;
    output 	[6:0]  HEX6;
    output 	[6:0]  HEX7;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output			VGA_CLK;   				//	VGA Clock
    output			VGA_HS;					//	VGA H_SYNC
    output			VGA_VS;					//	VGA V_SYNC
    output			VGA_BLANK_N;			//	VGA BLANK
    output			VGA_SYNC_N;				//	VGA SYNC
    output	[9:0]	VGA_R;   				//	VGA Red[9:0]
    output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
    output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

    // Unused.
    // wire resetn;
    // assign resetn = SW[17];

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    reg [2:0] color;
    reg [7:0] x;
    reg [6:0] y;
    reg writeEn;

    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(1'b1),
            .clock(CLOCK_50),
            .colour(color),
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
        defparam VGA.BACKGROUND_IMAGE = "bees2.mif";

    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    ///////////////////////////////// GAME MECHANICS /////////////////////////////////////////////////////////

    // Defining all registers needed.
    reg player_reset = 1'b0;
    reg game_over = 1'b0;
    reg [1:0] player_lives = 2'b11;
    reg [7:0] score = 8'd0;
    reg [7:0] high_score = 8'd0;

    // Checking collisions with borders
    wire walls_collided = 	(player_x >= 8'd152) || (player_x <= 7'd4)
                                || (player_y == 7'd112) || (player_y == 7'd24);

    // Checking collisions with bees
    // But only the enabled ones
    assign bees_collided =
        (   (player_x >= bee0_x - 2'd3) && (player_x <= bee0_x + 2'd3)
        &&  (player_y >= bee0_y - 2'd3) && (player_y <= bee0_y + 2'd3)
          && bee0_enable)
        ||
        (   (player_x >= bee1_x - 2'd3) && (player_x <= bee1_x + 2'd3)
        &&  (player_y >= bee1_y - 2'd3) && (player_y <= bee1_y + 2'd3)
          && bee1_enable)
        ||
        (   (player_x >= bee2_x - 2'd3) && (player_x <= bee2_x + 2'd3)
        &&  (player_y >= bee2_y - 2'd3) && (player_y <= bee2_y + 2'd3)
          && bee2_enable)
        ||
        (   (player_x >= bee3_x - 2'd3) && (player_x <= bee3_x + 2'd3)
        &&  (player_y >= bee3_y - 2'd3) && (player_y <= bee3_y + 2'd3)
        && bee3_enable)
        ||
        (   (player_x >= bee4_x - 2'd3) && (player_x <= bee4_x + 2'd3)
        &&  (player_y >= bee4_y - 2'd3) && (player_y <= bee4_y + 2'd3)
          && bee4_enable)
        ||
        (   (player_x >= bee5_x - 2'd3) && (player_x <= bee5_x + 2'd3)
        &&  (player_y >= bee5_y - 2'd3) && (player_y <= bee5_y + 2'd3)
          && bee5_enable);


    // Main logic here
    always @(posedge CLOCK_50)
        begin
            // Default cases
            game_over = 1'b0;

            // This is to make sure reset isn't left on.
            if (player_reset && player_slow)
                player_reset = 1'b0;

            // Otherwise if collided
            else if ((walls_collided || bees_collided) && player_slow && ~over)
                // The following is just checking logic for all lives.
                begin
                    if (player_lives[1:0] == 2'b00)
                        begin
                            game_over = 1'b1;   // Game over is lives = 0 and collision
                            player_reset = 1'b1;
                            player_lives = 2'b10;
                        end
                    else if (player_lives[1:0] == 2'b01)
                        begin
                            player_reset = 1'b1;
                            player_lives = 2'b00;
                        end
                    else if (player_lives[1:0] == 2'b10)
                        begin
                            player_reset = 1'b1;
                            player_lives = 2'b01;
                        end
                    else if (player_lives[1:0] == 2'b11)
                        begin
                            player_reset = 1'b1;
                            player_lives = 2'b10;
                        end
                end
    end

    //////////////////////////////////// GAME OVER ///////////////////////////////////////////////////////////

    // Turn on all LEDS when game over
    // assign LEDR[17] = over;
    // assign LEDR[16] = over;
    assign LEDR[15] = over;     // Indicates switch to reset
    // assign LEDR[14] = over;
    // assign LEDR[13] = over;
    // assign LEDR[12] = over;
    // assign LEDR[11] = over;
    // assign LEDR[10] = over;
    // assign LEDR[9] = over;
    // assign LEDR[8] = over;
    // assign LEDR[7] = over;
    // assign LEDR[6] = over;
    // assign LEDR[5] = over;
    // assign LEDR[4] = over;
    // assign LEDR[3] = over;
    // assign LEDR[2] = over;
    // assign LEDR[1] = over;
    // assign LEDR[0] = over;

    // assign LEDG[7] = over;
    // assign LEDG[7] = over;
    // assign LEDG[5] = over;
    // assign LEDG[4] = over;
    // assign LEDG[3] = over;
    // assign LEDG[2] = over;
    // assign LEDG[1] = over;
    // assign LEDG[0] = over;

    wire [6:0] hex0;
    wire [6:0] hex1;
    wire [6:0] hex2;
    wire [6:0] hex3;
    wire [6:0] hex4;
    wire [6:0] hex5;
    wire [6:0] hex6;
    wire [6:0] hex7;

    assign HEX0 = over ? 7'b0101111 : hex0;
    assign HEX1 = over ? 7'b0000110 : 7'b1111111;
    assign HEX2 = over ? 7'b1000001 : 7'b1111111;
    assign HEX3 = over ? 7'b1000000 : 7'b1111111;
    assign HEX4 = over ? 7'b0000110 : hex4;
    assign HEX5 = over ? 7'b1101010 : hex5;
    assign HEX6 = over ? 7'b0001000 : hex6;
    assign HEX7 = over ? 7'b1000010 : hex7;

    reg over = 1'b0;
    reg overoff = 1'b0;

    always @(posedge CLOCK_50)
        if (game_over)
            begin
                over = 1'b1;
                overoff = 1'b0;
            end
        else if (SW[15])
                overoff = 1'b1;
        else if (~SW[15] && overoff)
            begin
                over = 1'b0;
                overoff = 1'b0;
            end

    ///////////////////////////////////// LIVES DRAW /////////////////////////////////////////////////////////

    // Instanciating Datapaths and Controls for blocks
    // In the top right of screen that show number of lives

    wire lives1_slow = rate_out == 28'd1000;
    wire lives2_slow = rate_out == 28'd900;
    wire lives3_slow = rate_out == 28'd800;

    // ------------------------------------------- Lives 1 ------------------------------------------------------ //

    wire lives1_clear, lives1_update, lives1_done, lives1_waiting;
    wire lives1_rdout, lives1_writeEn;
    wire [7:0] lives1_x;
    wire [6:0] lives1_y;
    wire [2:0] lives1_c;

    // Instansiate datapath for Lives 1
    datapath lives1_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(lives1_done), .update(lives1_update), .clear(lives1_clear),  .bee(1'b0),
        .waiting(lives1_waiting), .c_in(3'b100), .c2_in(3'b000), .x_in(8'd144), .y_in(7'd12), .dir_in(4'b000),
        // Outputs
        .x_out(lives1_x), .y_out(lives1_y), .c_out(lives1_c), .writeEn(lives1_writeEn)
    );

    // Instansiate FSM control Lives 1
    control lives1_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(lives1_slow), .resetn(1'b1), .moved(1'b0),
        // Outputs
        .update(lives1_update), .clear(lives1_clear), .done(lives1_done), .waiting(lives1_waiting),
    );

    // ------------------------------------------- Lives 2 ------------------------------------------------------ //

    wire lives2_clear, lives2_update, lives2_done, lives2_waiting;
    wire lives2_rdout, lives2_writeEn;
    wire [7:0] lives2_x;
    wire [6:0] lives2_y;
    wire [2:0] lives2_c;

    // Instansiate datapath for Lives 2
    datapath lives2_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(lives2_done), .update(lives2_update), .clear(lives2_clear),  .bee(1'b0),
        .waiting(lives2_waiting), .c_in(3'b100), .c2_in(3'b000), .x_in(8'd136), .y_in(7'd12), .dir_in(4'b000),
        // Outputs
        .x_out(lives2_x), .y_out(lives2_y), .c_out(lives2_c), .writeEn(lives2_writeEn)
    );

    // Instansiate FSM control Lives 2
    control lives2_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(lives2_slow), .resetn(1'b1), .moved(1'b0),
        // Outputs
        .update(lives2_update), .clear(lives2_clear), .done(lives2_done), .waiting(lives2_waiting),
    );

    // ------------------------------------------- Lives 3 ------------------------------------------------------ //

    wire lives3_clear, lives3_update, lives3_done, lives3_waiting;
    wire lives3_rdout, lives3_writeEn;
    wire [7:0] lives3_x;
    wire [6:0] lives3_y;
    wire [2:0] lives3_c;

    // Instansiate datapath for Lives 3
    datapath lives3_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(lives3_done), .update(lives3_update), .clear(lives3_clear),  .bee(1'b0),
        .waiting(lives3_waiting), .c_in(3'b100), .c2_in(3'b000), .x_in(8'd128), .y_in(7'd12), .dir_in(4'b000),
        // Outputs
        .x_out(lives3_x), .y_out(lives3_y), .c_out(lives3_c), .writeEn(lives3_writeEn)
    );

    // Instansiate FSM control Lives 3
    control lives3_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(lives3_slow), .resetn(1'b1), .moved(1'b0),
        // Outputs
        .update(lives3_update), .clear(lives3_clear), .done(lives3_done), .waiting(lives3_waiting),
    );


    ////////////////////////////////////// SCORE  /////////////////////////////////////////////////////////////


    // These are the wires used in the rate divider
    // That handles the interval for scoring
    wire [27:0] score_rdout;
    wire sctime;
    assign sctime = (score_rdout == 28'd0);

    // Rate divider for scoring.
    // Currently set to 2 seconds.
    rate_divider score_rd(
        .clk(CLOCK_50),
        .load_val(28'd100000000),
        .out(score_rdout)
    );

    // Update score. If game over, reset.
    // Update high score when needed.
    always @(posedge CLOCK_50)
    begin
        if (game_over)
            score = 1'b0;
        else if (sctime && ~over && (| SW[5:0]))
            score = score + 1'b1;

        if (score >= high_score)
            high_score = score;
    end

    // Display Score
    hex_display sc1(.IN(score[3:0]), .OUT(hex4));
    hex_display sc2(.IN(score[7:4]), .OUT(hex5));

    // Display high score
    hex_display highsc1(.IN(high_score[3:0]), .OUT(hex6));
    hex_display highsc2(.IN(high_score[7:4]), .OUT(hex7));


    ////////////////////////////////////// RATE DIVIDER /////////////////////////////////////////////////////////////

    // Controls the speed of the game
    wire [27:0] rate_out;
    // Can switch between 2 speeds using Switch.
    reg [27:0] main_rd_in;

    always @(posedge CLOCK_50)
    begin
        case (SW[17:16])
            // Turn either on to make it a bit faster.
            // Turn both on for fastest mode.
            2'b00: main_rd_in = 28'd1000000;
            2'b01: main_rd_in = 28'd750000;
            2'b10: main_rd_in = 28'd750000;
            2'b11: main_rd_in = 28'd500000;
        endcase
    end

    // Instantiate Rate divider game speed
    rate_divider bee0_rd(
        .clk(CLOCK_50),
        .load_val(main_rd_in),
        .out(rate_out)
    );

    ////////////////////////////////////// WHICH ONE DRAWS ///////////////////////////////////////////////////////////

    // Handles sending the appropriate input to the VGA
    always @(*) begin
    writeEn = 1'b0;
        if (player_writeEn)
            begin
                x = player_x;
                y = player_y;
                color = (~over) ? player_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee0_writeEn)
            begin
                x = bee0_x;
                y = bee0_y;
                color = (bee0_enable && ~over) ? bee0_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee1_writeEn)
            begin
                x = bee1_x;
                y = bee1_y;
                color = (bee1_enable && ~over) ? bee1_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee2_writeEn)
            begin
                x = bee2_x;
                y = bee2_y;
                color = (bee2_enable && ~over) ? bee2_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee3_writeEn)
            begin
                x = bee3_x;
                y = bee3_y;
                color = (bee3_enable && ~over) ? bee3_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee4_writeEn)
            begin
                x = bee4_x;
                y = bee4_y;
                color = (bee4_enable && ~over) ? bee4_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (bee5_writeEn)
            begin
                x = bee5_x;
                y = bee5_y;
                color = (bee5_enable && ~over) ? bee5_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (lives1_writeEn)
            begin
                x = lives1_x;
                y = lives1_y;
                color = (player_lives >= 2'b00 && ~over) ? lives1_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (lives2_writeEn)
            begin
                x = lives2_x;
                y = lives2_y;
                color = (player_lives >= 2'b01 && ~over) ? lives2_c : 3'b111;
                writeEn = 1'b1;
            end
        else if (lives3_writeEn)
            begin
                x = lives3_x;
                y = lives3_y;
                color = (player_lives == 2'b10 && ~over) ? lives3_c : 3'b111;
                writeEn = 1'b1;
            end
    end

    /////////////////////////////////////////// PLAYER INSTANTIATION //////////////////////////////////////////////////////

    wire player_clear, player_update, player_done, player_waiting;
    wire player_rdout, player_writeEn;
    wire [7:0] player_x;
    wire [6:0] player_y;
    wire [2:0] player_c;

    reg [7:0] player_x_in = 8'd80;
    reg [6:0] player_y_in = 7'd60;
    reg [27:0] player_offset  = 28'd0;

    wire [3:0] player_dir;
    assign player_dir = over ? 4'b000 : 4'b1111 ^ KEY[3:0];

    wire player_slow;
    assign player_slow = rate_out == player_offset;

    reg [2:0] player_color_in = 3'b001;

    hex_display liveshex(.IN(player_lives + 1'b1), .OUT(hex0));

     always @(player_lives)
     begin
         case (player_lives)
             2'b00: player_color_in = 3'b100;
             2'b01: player_color_in = 3'b101;
             2'b10: player_color_in = 3'b001;
             2'b11: player_color_in = 3'b001;
         endcase
     end

     reg [7:0] rand_x = 8'd80;
     reg [6:0] rand_y = 7'd60;
     always @(posedge CLOCK_50)
     begin
        if (rand_x < 8'd120)
            rand_x = rand_x + 1;
        else if (rand_x >= 8'd120)
            rand_x = 8'd29;
        if (rand_y < 7'd87)
            rand_y = rand_y + 1;
        else if (rand_y >= 7'd87)
            rand_y = 7'd49;
     end




    // Instansiate datapath for Player
    datapath player_data(
        // Inputs
        .clk(CLOCK_50), .resetn(~player_reset), .done(player_done), .update(player_update), .clear(player_clear),  .bee(1'b0),
        .waiting(player_waiting), .c_in(player_color_in), .c2_in(3'b000), .x_in(rand_x), .y_in(rand_y), .dir_in(player_dir),
        // Outputs
        .x_out(player_x), .y_out(player_y), .c_out(player_c), .writeEn(player_writeEn)
    );

    // Instansiate FSM control Player
    control player_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(player_slow), .resetn(~player_reset), .moved(| player_dir),
        // Outputs
        .update(player_update), .clear(player_clear), .done(player_done), .waiting(player_waiting),
    );


    /////////////////////////////////////////// BEE 0 INSTANTIATION //////////////////////////////////////////////////////

    wire bee0_clear, bee0_update, bee0_done, bee0_waiting;
    wire bee0_rdout, bee0_writeEn;
    wire [7:0] bee0_x;
    wire [6:0] bee0_y;
    wire [2:0] bee0_c;

    reg [7:0] bee0_x_in = 8'd30;
    reg [6:0] bee0_y_in = 7'd48;
    reg [3:0] bee0_dir   = 4'b1010;
    reg [27:0] bee0_offset  = 28'd100;

    wire bee0_slow;
    assign bee0_slow = rate_out == bee0_offset;

    // Can enable/disable the bee.
    wire bee0_enable;
    assign bee0_enable = SW[0];

    // Handles the boing boing
    always @(posedge bee0_slow)
    begin
        if      (bee0_x >= 8'd152)  bee0_dir = {1'b1, bee0_dir[2:1], 1'b0};
        else if (bee0_x <= 7'd4)    bee0_dir = {1'b0, bee0_dir[2:1], 1'b1};
        if      (bee0_y == 7'd112)  bee0_dir = {bee0_dir[3], 2'b01, bee0_dir[0]};
        else if (bee0_y == 7'd24)    bee0_dir = {bee0_dir[3], 2'b10, bee0_dir[0]};
    end

    // Instansiate datapath for Bee 0
    datapath bee0_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee0_done), .update(bee0_update), .clear(bee0_clear), .bee(1'b1),
        .waiting(bee0_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee0_x_in), .y_in(bee0_y_in), .dir_in(bee0_dir),
        // Outputs
        .x_out(bee0_x), .y_out(bee0_y), .c_out(bee0_c), .writeEn(bee0_writeEn)
    );

    // Instansiate FSM control Bee 0
    control bee0_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee0_slow), .resetn(1'b1), .moved(| bee0_dir),
        // Outputs
        .update(bee0_update), .clear(bee0_clear), .done(bee0_done), .waiting(bee0_waiting),
    );

    /////////////////////////////////////////// BEE 1 INSTANTIATION //////////////////////////////////////////////////////

    wire bee1_clear, bee1_update, bee1_done, bee1_waiting;
    wire bee1_rdout, bee1_writeEn;
    wire [7:0] bee1_x;
    wire [6:0] bee1_y;
    wire [2:0] bee1_c;

    reg [7:0] bee1_x_in = 8'd34;
    reg [6:0] bee1_y_in = 7'd74;
    reg [3:0] bee1_dir = 4'b1100;
    reg [27:0] bee1_offset = 27'd200;

    wire bee1_slow;
    assign bee1_slow = rate_out == bee1_offset;

    // Can enable/disable the bee.
    wire bee1_enable;
    assign bee1_enable = SW[1];

    // Handles the boing boing
    always @(posedge bee1_slow)
    begin
        if      (bee1_x >= 8'd152)  bee1_dir = {1'b1, bee1_dir[2:1], 1'b0};
        else if (bee1_x <= 7'd4)    bee1_dir = {1'b0, bee1_dir[2:1], 1'b1};
        if      (bee1_y == 7'd112)  bee1_dir = {bee1_dir[3], 2'b01, bee1_dir[0]};
        else if (bee1_y == 7'd24)    bee1_dir = {bee1_dir[3], 2'b10, bee1_dir[0]};
    end

    // Instansiate datapath for Bee 1
    datapath bee1_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee1_done), .update(bee1_update), .clear(bee1_clear), .bee(1'b1),
        .waiting(bee1_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee1_x_in), .y_in(bee1_y_in), .dir_in(bee1_dir),
        // Outputs
        .x_out(bee1_x), .y_out(bee1_y), .c_out(bee1_c), .writeEn(bee1_writeEn)
    );

    // Instansiate FSM control Bee 1
    control bee1_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee1_slow), .resetn(1'b1), .moved(| bee1_dir),
        // Outputs
        .update(bee1_update), .clear(bee1_clear), .done(bee1_done), .waiting(bee1_waiting),
    );

    /////////////////////////////////////////// BEE 2 INSTANTIATION //////////////////////////////////////////////////////

    wire bee2_clear, bee2_update, bee2_done, bee2_waiting;
    wire bee2_rdout, bee2_writeEn;
    wire [7:0] bee2_x;
    wire [6:0] bee2_y;
    wire [2:0] bee2_c;

    reg [7:0] bee2_x_in = 8'd103;
    reg [6:0] bee2_y_in = 7'd89;
    reg [3:0] bee2_dir   = 4'b0011;
    reg [27:0] bee2_offset = 28'd300;

    wire bee2_slow;
    assign bee2_slow = rate_out == bee2_offset;

    // Can enable/disable the bee.
    wire bee2_enable;
    assign bee2_enable = SW[2];

    // Handles the boing boing
    always @(posedge bee2_slow)
    begin
        if      (bee2_x >= 8'd152)  bee2_dir = {1'b1, bee2_dir[2:1], 1'b0};
        else if (bee2_x <= 7'd4)    bee2_dir = {1'b0, bee2_dir[2:1], 1'b1};
        if      (bee2_y == 7'd112)  bee2_dir = {bee2_dir[3], 2'b01, bee2_dir[0]};
        else if (bee2_y == 7'd24)    bee2_dir = {bee2_dir[3], 2'b10, bee2_dir[0]};
    end

    // Instansiate datapath for Bee 2
    datapath bee2_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee2_done), .update(bee2_update), .clear(bee2_clear), .bee(1'b1),
        .waiting(bee2_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee2_x_in), .y_in(bee2_y_in), .dir_in(bee2_dir),
        // Outputs
        .x_out(bee2_x), .y_out(bee2_y), .c_out(bee2_c), .writeEn(bee2_writeEn)
    );

    // Instansiate FSM control Bee 2
    control bee2_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee2_slow), .resetn(1'b1), .moved(| bee2_dir),
        // Outputs
        .update(bee2_update), .clear(bee2_clear), .done(bee2_done), .waiting(bee2_waiting),
    );

    /////////////////////////////////////////// BEE 3 INSTANTIATION //////////////////////////////////////////////////////

    wire bee3_clear, bee3_update, bee3_done, bee3_waiting;
    wire bee3_rdout, bee3_writeEn;
    wire [7:0] bee3_x;
    wire [6:0] bee3_y;
    wire [2:0] bee3_c;


    reg [7:0] bee3_x_in = 8'd67;
    reg [6:0] bee3_y_in = 7'd100;
    reg [3:0] bee3_dir   = 4'b0101;
    reg [27:0] bee3_offset = 28'd400;

    wire bee3_slow;
    assign bee3_slow = rate_out == bee3_offset;

    // Can enable/disable the bee.
    wire bee3_enable;
    assign bee3_enable = SW[3];

    // Handles the boing boing
    always @(posedge bee3_slow)
    begin
        if      (bee3_x >= 8'd152)  bee3_dir = {1'b1, bee3_dir[2:1], 1'b0};
        else if (bee3_x <= 7'd4)    bee3_dir = {1'b0, bee3_dir[2:1], 1'b1};
        if      (bee3_y == 7'd112)  bee3_dir = {bee3_dir[3], 2'b01, bee3_dir[0]};
        else if (bee3_y == 7'd24)    bee3_dir = {bee3_dir[3], 2'b10, bee3_dir[0]};
    end

    // Instansiate datapath for Bee 3
    datapath bee3_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee3_done), .update(bee3_update), .clear(bee3_clear), .bee(1'b1),
        .waiting(bee3_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee3_x_in), .y_in(bee3_y_in), .dir_in(bee3_dir),
        // Outputs
        .x_out(bee3_x), .y_out(bee3_y), .c_out(bee3_c), .writeEn(bee3_writeEn)
    );

    // Instansiate FSM control Bee 3
    control bee3_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee3_slow), .resetn(1'b1), .moved(| bee3_dir),
        // Outputs
        .update(bee3_update), .clear(bee3_clear), .done(bee3_done), .waiting(bee3_waiting),
    );

    /////////////////////////////////////////// BEE 4 INSTANTIATION //////////////////////////////////////////////////////

    wire bee4_clear, bee4_update, bee4_done, bee4_waiting;
    wire bee4_rdout, bee4_writeEn;
    wire [7:0] bee4_x;
    wire [6:0] bee4_y;
    wire [2:0] bee4_c;


    reg [7:0] bee4_x_in = 8'd108;
    reg [6:0] bee4_y_in = 7'd56;
    reg [3:0] bee4_dir   = 4'b0101;
    reg [27:0] bee4_offset = 28'd500;

    wire bee4_slow;
    assign bee4_slow = rate_out == bee4_offset;

    // Can enable/disable the bee.
    wire bee4_enable;
    assign bee4_enable = SW[4];

    // Handles the boing boing
    always @(posedge bee4_slow)
    begin
        if      (bee4_x >= 8'd152)  bee4_dir = {1'b1, bee4_dir[2:1], 1'b0};
        else if (bee4_x <= 7'd4)    bee4_dir = {1'b0, bee4_dir[2:1], 1'b1};
        if      (bee4_y == 7'd112)  bee4_dir = {bee4_dir[3], 2'b01, bee4_dir[0]};
        else if (bee4_y == 7'd24)    bee4_dir = {bee4_dir[3], 2'b10, bee4_dir[0]};
    end

    // Instansiate datapath for Bee 4
    datapath bee4_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee4_done), .update(bee4_update), .clear(bee4_clear), .bee(1'b1),
        .waiting(bee4_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee4_x_in), .y_in(bee4_y_in), .dir_in(bee4_dir),
        // Outputs
        .x_out(bee4_x), .y_out(bee4_y), .c_out(bee4_c), .writeEn(bee4_writeEn)
    );

    // Instansiate FSM control Bee 4
    control bee4_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee4_slow), .resetn(1'b1), .moved(| bee4_dir),
        // Outputs
        .update(bee4_update), .clear(bee4_clear), .done(bee4_done), .waiting(bee4_waiting),
    );

/////////////////////////////////////////// BEE 5 INSTANTIATION //////////////////////////////////////////////////////

    wire bee5_clear, bee5_update, bee5_done, bee5_waiting;
    wire bee5_rdout, bee5_writeEn;
    wire [7:0] bee5_x;
    wire [6:0] bee5_y;
    wire [2:0] bee5_c;


    reg [7:0] bee5_x_in = 8'd67;
    reg [6:0] bee5_y_in = 7'd29;
    reg [3:0] bee5_dir   = 4'b1100;
    reg [27:0] bee5_offset = 28'd600;

    wire bee5_slow;
    assign bee5_slow = rate_out == bee5_offset;

    // Can enable/disable the bee.
    wire bee5_enable;
    assign bee5_enable = SW[5];

    // Handles the boing boing
    always @(posedge bee5_slow)
    begin
        if      (bee5_x >= 8'd152)  bee5_dir = {1'b1, bee5_dir[2:1], 1'b0};
        else if (bee5_x <= 7'd5)    bee5_dir = {1'b0, bee5_dir[2:1], 1'b1};
        if      (bee5_y == 7'd112)  bee5_dir = {bee5_dir[3], 2'b01, bee5_dir[0]};
        else if (bee5_y == 7'd25)    bee5_dir = {bee5_dir[3], 2'b10, bee5_dir[0]};
    end

    // Instansiate datapath for Bee 5
    datapath bee5_data(
        // Inputs
        .clk(CLOCK_50), .resetn(1'b1), .done(bee5_done), .update(bee5_update), .clear(bee5_clear), .bee(1'b1),
        .waiting(bee5_waiting), .c_in(3'b110), .c2_in(3'b000), .x_in(bee5_x_in), .y_in(bee5_y_in), .dir_in(bee5_dir),
        // Outputs
        .x_out(bee5_x), .y_out(bee5_y), .c_out(bee5_c), .writeEn(bee5_writeEn)
    );

    // Instansiate FSM control Bee 5
    control bee5_control(
        // Inputs
        .clk(CLOCK_50), .slowClk(bee5_slow), .resetn(1'b1), .moved(| bee5_dir),
        // Outputs
        .update(bee5_update), .clear(bee5_clear), .done(bee5_done), .waiting(bee5_waiting),
    );

endmodule

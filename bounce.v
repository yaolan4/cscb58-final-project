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
//        HEX1,
//        HEX2,
//        HEX3,
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

    input			CLOCK_50;				//	50 MHz
    input   [17:0]   SW;
    input   [3:0]   KEY;
    output 	[17:0]  LEDR;
    output 	[7:0]  LEDG;
    output 	[6:0]  HEX0;
//    output 	[6:0]  HEX1;
//    output 	[6:0]  HEX2;
//    output 	[6:0]  HEX3;
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
    wire resetn;
    assign resetn = SW[17];
    
    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    reg [2:0] color;
    reg [7:0] x;
    reg [6:0] y;
    reg writeEn;
	
    // for Debugging
	 //assign LEDR[17:0] = bee1_offset[17:0];
//	assign LEDR[0] = x == 7'd80;
//    assign LEDR[1] = y == 7'd60;
    // assign LEDG[0] = bee0_load;
    // assign LEDG[1] = bee0_clear;
    // assign LEDG[2] = bee0_waiting;
    // assign LEDG[3] = bee0_done;
	 
	//assign LEDG[0] = reset_game;
	//assign LEDG[2:1] = lives;


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
        defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
//		  

//		 assign LEDR[0] = bee0_writeEn;
//		 assign LEDR[1] = bee1_writeEn;
//            
    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    ///////////////////////////////// GAME MECHANICS /////////////////////////////////////////////////////////

    reg player_reset = 1'b0;
	 reg game_over = 1'b0;
    reg [1:0] player_lives = 2'b11;
    reg [7:0] score = 8'd0;
    reg [7:0] high_score = 8'd0;

    assign LEDG[1:0] = player_lives;
	assign LEDG[3] = player_lives == 2'b00;
	 
	wire walls_collided = 	(player_x >= 8'd152) || (player_x <= 7'd4)
								|| (player_y == 7'd112) || (player_y == 7'd24);
								
	assign bees_collided = //1'b0;
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
        && bee3_enable);

    assign LEDR[0] = bees_collided;
    
   always @(posedge CLOCK_50)
       begin
				// Default cases
				game_over = 1'b0;
		 
           if 		 (player_reset && player_slow) 		  player_reset = 1'b0;
           else 
                   if ((walls_collided || bees_collided) && player_slow) 
                       begin
                           if (player_lives[1:0] == 2'b00)
                               begin
												game_over = 1'b1;
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
	

    ////////////////////////////////////// SCORE  /////////////////////////////////////////////////////////////
		
    wire [27:0] score_rdout;
    wire sctime;
    assign sctime = (score_rdout == 28'd0);

    rate_divider score_rd(
        .clk(CLOCK_50),
        .load_val(28'd100000000),
        .out(score_rdout)
    );

    always @(posedge CLOCK_50)
    begin
			if (game_over)
				score = 1'b0;
			else if (sctime)
				score = score + 1'b1;
				
			if (score >= high_score)
				high_score = score;
    end
	 
	// Display Score
	hex_display sc1(.IN(score[3:0]), .OUT(HEX4));
   hex_display sc2(.IN(score[7:4]), .OUT(HEX5));
	 
	// Display high score
	hex_display highsc1(.IN(high_score[3:0]), .OUT(HEX6));
   hex_display highsc2(.IN(high_score[7:4]), .OUT(HEX7));
	 

    ////////////////////////////////////// RATE DIVIDER /////////////////////////////////////////////////////////////

    wire [27:0] rate_out;
	 wire [27:0] main_rd_in = SW[16] ? 28'd500000 : 28'd1000000; 

    // Instantiate Rate divider for Bee 0
    rate_divider bee0_rd(
        .clk(CLOCK_50), 
        .load_val(main_rd_in), 
        .out(rate_out)
    );

    ////////////////////////////////////// WHICH ONE DRAWS ///////////////////////////////////////////////////////////
	 
	 always @(*) begin
        writeEn = 1'b0;
		  if (player_writeEn)
            begin
                x = player_x;
                y = player_y;
                color = player_c;
                writeEn = 1'b1;
            end 
		  else if (bee0_writeEn)
            begin
                x = bee0_x;
                y = bee0_y;
                color = bee0_enable ? bee0_c : 3'b111;
                writeEn = 1'b1;
            end 
       else if (bee1_writeEn)
           begin
               x = bee1_x;
               y = bee1_y;
               color = bee1_enable ? bee1_c : 3'b111;
               writeEn = 1'b1;
           end
       else if (bee2_writeEn)
       begin
           x = bee2_x;
           y = bee2_y;
           color = bee2_enable ? bee2_c : 3'b111;
           writeEn = 1'b1;
       end
       else if (bee3_writeEn)
       begin
           x = bee3_x;
           y = bee3_y;
           color = bee3_enable ? bee3_c : 3'b111;;
           writeEn = 1'b1;
       end 
	 end

    /////////////////////////////////////////// PLAYER INSTANTIATION //////////////////////////////////////////////////////
    
    wire player_clear, player_update, player_done, player_waiting;
    wire player_rdout, player_writeEn;
    wire [7:0] player_x;
    wire [6:0] player_y;
    wire [2:0] player_c;
	 
	 //assign LEDG[3:0] = player_dir;

    reg [7:0] player_x_in = 8'd80;
    reg [6:0] player_y_in = 7'd60;
    reg [27:0] player_offset  = 28'd0; 
    
    wire [3:0] player_dir;
    assign player_dir = 4'b1111 ^ KEY[3:0];

    wire player_slow;
    assign player_slow = rate_out == player_offset;
	 
	 assign LEDR[17] = player_reset;
	
	reg [2:0] player_color_in = 3'b001;

    hex_display liveshex(.IN(player_lives), .OUT(HEX0));
	
	 always @(player_lives)
	 begin
	 	case (player_lives)
	 		2'b00: player_color_in = 3'b100;
	 		2'b01: player_color_in = 3'b101;
	 		2'b10: player_color_in = 3'b001;
	 		2'b11: player_color_in = 3'b001;
	 	endcase
	 end
	
	
    // Instansiate datapath for Player
    datapath player_data(
        // Inputs
        .clk(CLOCK_50), .resetn(~player_reset), .done(player_done), .update(player_update), .clear(player_clear),  .bee(1'b0),
		.waiting(player_waiting), .c_in(player_color_in), .c2_in(3'b000), .x_in(player_x_in), .y_in(player_y_in), .dir_in(player_dir),
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
	 
	 //assign LEDG[3:0] = bee0_dir;

    reg [7:0] bee0_x_in = 8'd30;
    reg [6:0] bee0_y_in = 7'd48;
    reg [3:0] bee0_dir   = 4'b1010;
    reg [27:0] bee0_offset  = 28'd100; 

    wire bee0_slow;
    assign bee0_slow = rate_out == bee0_offset;

	 wire bee0_enable;
    reg bee0_reset = 1'b1;
	 assign bee0_enable = SW[0];

    always @(bee0_enable)
    begin
        if (bee0_enable)
            bee0_reset = 1'b1;
        else
            bee0_reset = 1'b0;

    end
   always @(posedge bee0_slow)
	    begin
       begin
           if      (bee0_x >= 8'd152)  bee0_dir = {1'b1, bee0_dir[2:1], 1'b0};
           else if (bee0_x <= 7'd4)    bee0_dir = {1'b0, bee0_dir[2:1], 1'b1};
           if      (bee0_y == 7'd112)  bee0_dir = {bee0_dir[3], 2'b01, bee0_dir[0]};
           else if (bee0_y == 7'd24)    bee0_dir = {bee0_dir[3], 2'b10, bee0_dir[0]};
       end
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
    // wire [27:0] bee1_offset;
	 wire bee1_enable;
    reg bee1_reset = 1'b1;
	 assign bee1_enable = SW[1];

    always @(bee1_enable)
    begin
        if (bee1_enable)
            bee1_reset = 1'b1;
        else
            bee1_reset = 1'b0;

    end
	 
	
	// assign bee1_offset = {11'd0, SW[17:1]};
    wire bee1_slow;
    assign bee1_slow = rate_out == bee1_offset;

    always @(posedge bee1_slow)
	    begin
        begin
            if      (bee1_x >= 8'd152)  bee1_dir = {1'b1, bee1_dir[2:1], 1'b0};
            else if (bee1_x <= 7'd4)    bee1_dir = {1'b0, bee1_dir[2:1], 1'b1};
            if      (bee1_y == 7'd112)  bee1_dir = {bee1_dir[3], 2'b01, bee1_dir[0]};
            else if (bee1_y == 7'd24)    bee1_dir = {bee1_dir[3], 2'b10, bee1_dir[0]};
        end
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
	 
	 wire bee2_enable;
    reg bee2_reset = 1'b1;
	 assign bee2_enable = SW[2];

    always @(bee2_enable)
    begin
        if (bee2_enable)
            bee2_reset = 1'b1;
        else
            bee2_reset = 1'b0;

    end

    always @(posedge bee2_slow)
	    begin
        begin
            if      (bee2_x >= 8'd152)  bee2_dir = {1'b1, bee2_dir[2:1], 1'b0};
            else if (bee2_x <= 7'd4)    bee2_dir = {1'b0, bee2_dir[2:1], 1'b1};
            if      (bee2_y == 7'd112)  bee2_dir = {bee2_dir[3], 2'b01, bee2_dir[0]};
            else if (bee2_y == 7'd24)    bee2_dir = {bee2_dir[3], 2'b10, bee2_dir[0]};
        end
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
	 
	 wire bee3_enable;
    reg bee3_reset = 1'b1;
	 assign bee3_enable = SW[3];

    always @(bee3_enable)
    begin
        if (bee3_enable)
            bee3_reset = 1'b1;
        else
            bee3_reset = 1'b0;
    end

    wire bee3_slow;
    assign bee3_slow = rate_out == bee3_offset;

    always @(posedge bee3_slow)
	    begin
        begin
            if      (bee3_x >= 8'd152)  bee3_dir = {1'b1, bee3_dir[2:1], 1'b0};
            else if (bee3_x <= 7'd4)    bee3_dir = {1'b0, bee3_dir[2:1], 1'b1};
            if      (bee3_y == 7'd112)  bee3_dir = {bee3_dir[3], 2'b01, bee3_dir[0]};
            else if (bee3_y == 7'd24)    bee3_dir = {bee3_dir[3], 2'b10, bee3_dir[0]};
        end
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

    
    
    
endmodule
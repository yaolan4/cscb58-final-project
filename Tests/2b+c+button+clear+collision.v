// +test with 2 bees and a char; +joystick; -FSM clear; +collision

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module beehive
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		HEX0,
		HEX2,
		HEX3,

		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	// Declare your inputs and outputs here
	input	CLOCK_50;				    // 50 MHz Clock
	input [9:0] SW;
	input [3:0] KEY;
	output [6:0]HEX0;
	output [6:0]HEX2;
	output [6:0]HEX3;

	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(outcolour),
			.x(outx),
			.y(outy),
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

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

    wire resetn;
	assign resetn = SW[0];

	////////////////////////// BOY INSTANTIATION //////////////////////////////
	// wires from b0
	wire [2:0] outcolour0;
	wire [7:0] outx0;
	wire [6:0] outy0;
	wire [0:0] writeEn0;
	wire [0:0]strt;

	baby B0(
			.CLOCK_50(CLOCK_50),
			.resetn(resetn),
			.xin(8'd70),
			.yin(7'd70),
			.colourin(3'b111),

			// cycle per second, not -1
			.cycleload(28'b0010111110101111000010000000),
			.movement({KEY[3], KEY[2], KEY[1], KEY[0]}),

			.outx(outx0),
			.outy(outy0),
			.outcolour(outcolour0),
			.writeEn(writeEn0),

			.strt(strt)
			);
	////////////////////////// END BOY INSTANTIATION //////////////////////////

    ////////////////////////// BEE 1 INSTANTIATION ////////////////////////////
    //wires from b1
	wire [2:0] outcolour1;
	wire [7:0] outx1;
	wire [6:0] outy1;
	wire [0:0] writeEn1;

	beeby B1(
		.CLOCK_50(CLOCK_50),
		.resetn(resetn),
		.xin(8'd10),
		.yin(7'd10),
		.colourin(3'b001),

		// cycle per second, not -1
	    .cycleload(28'b0010111110101111000010000000),

		.outx(outx1),
		.outy(outy1),
		.outcolour(outcolour1),
		.writeEn(writeEn1)
		);
	///////////////////////// END BEE 1 INSTANTIATION /////////////////////////

	////////////////////////// BEE 2 INSTANTIATION ////////////////////////////
    //wires from b2
	wire [2:0] outcolour2;
	wire [7:0] outx2;
	wire [6:0] outy2;
	wire [0:0] writeEn2;

	beeby B2(
		.CLOCK_50(CLOCK_50),
		.resetn(resetn),
		.xin(8'd40),
		.yin(7'd40),
		.colourin(3'b010),

		// cycle per second, not -1
	    .cycleload(28'b0010111110101111000010000000),

		.outx(outx2),
		.outy(outy2),
		.outcolour(outcolour2),
		.writeEn(writeEn2)
		);
	///////////////////////// END BEE 2 INSTANTIATION /////////////////////////

	/////////////////////////// CHOOSE MOVEMENT INSTANTIATION /////////////////
    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [2:0] outcolour;
    wire [7:0] outx;
    wire [6:0] outy;
    wire [0:0] writeEn;

	chooseMovement CM(
	    .CLOCK_50(CLOCK_50),
		.strt(strt),
		.resetn(resetn),

		// wires from char
	    .outcolour0(outcolour0),
		.outx0(outx0),
		.outy0(outy0),
		.writeEn0(writeEn0),

        // wires from b1
		.outcolour1(outcolour1),
		.outx1(outx1),
		.outy1(outy1),
		.writeEn1(writeEn1),

        // wires form b2
		.outcolour2(outcolour2),
		.outx2(outx2),
		.outy2(outy2),
		.writeEn2(writeEn2),

        // wires to VGA
		.outcolour(outcolour),
		.outx(outx),
		.outy(outy),
		.writeEn(writeEn),

		.deaths(deaths),
		.reset_score(reset_score)
		);
	///////////////////////// END CHOOSE MOVEMENT INSTANTIATION ///////////////

	////////////////////////////// SCORE AND LIVES ////////////////////////////
	wire [1:0]deaths;
	wire reset_score, timer;

	rateDivider score_divider(
		.clock(CLOCK_50),
		.cycleload(28'b0010111110101111000010000000),
		.Enable(timer)
	);

	reg [7:0]score;

	always@(posedge timer or posedge resetn or posedge reset_score)
	begin
		if(reset_score == 1'b1)
			score[7:0] <= 8'd0;
		else if (resetn == 1'b1)
			score[7:0] <= 8'd0;
		else
			score <= score + 1'b1;
	end

	hex_display h0(
		.IN({2'b00, 2'd3 - deaths}),
		.OUT(HEX0[6:0])
	);

	hex_display h2(
		.IN(score[3:0]),
		.OUT(HEX2[6:0])
	);

	hex_display h3(
		.IN(score[7:4]),
		.OUT(HEX3[6:0])
	);
	/////////////////////////// END SCORE AND LIVES ////////////////////////////


endmodule

// chooses which object is moved on VGA and clears
module chooseMovement( CLOCK_50, strt,  resetn, outcolour0, outx0, outy0, writeEn0,
						outcolour1, outx1, outy1, writeEn1,
						outcolour2, outx2, outy2, writeEn2,
						outcolour, outx, outy, writeEn,
						deaths, reset_score);
	input CLOCK_50;
	input strt;
	input resetn;

    input [2:0] outcolour0;
    input [7:0] outx0;
    input [6:0] outy0;
    input [0:0] writeEn0;

    input [2:0] outcolour1;
    input [7:0] outx1;
    input [6:0] outy1;
    input [0:0] writeEn1;

    input [2:0] outcolour2;
    input [7:0] outx2;
    input [6:0] outy2;
    input [0:0] writeEn2;

    output reg [2:0] outcolour;
    output reg [7:0] outx;
    output reg [6:0] outy;
    output reg [0:0] writeEn;

	output [1:0] deaths;
	output reset_score;

	always @(posedge CLOCK_50)
	begin
		writeEn <= 1'b1;
		outx <= outx;
		outy <= outy;
		outcolour = 3'b000;
		if(writeEn0) //player
			begin
				writeEn <= writeEn0;
				outx <= outx0;
				outy <= outy0;
				outcolour = outcolour0;
			end
		else if(writeEn1) // bee1, if prior arent moving, then let this move
			begin
				writeEn <= writeEn1;
				outx <= outx1;
				outy <= outy1;
				outcolour = outcolour1;
			end
		else if (writeEn2)    // bee2, if prior arent moving, then let this move
			begin
				writeEn <= writeEn2;
				outx <= outx2;
				outy <= outy2;
				outcolour <= outcolour;
			end
	end

	deaths life(
		.CLOCK_50(CLOCK_50),
		.strt(strt),
		.resetn(resetn),

		// wires from char
		.outx0(outx0),
		.outy0(outy0),

        // wires from b1
		.outx1(outx1),
		.outy1(outy1),

        // wires form b2
		.outx2(outx2),
		.outy2(outy2),

		// output
		.deaths(deaths),
		.reset_score(reset_score)
		);

endmodule

// counts the number of deaths before resetting the score, max 3
module deaths(CLOCK_50, strt, resetn,  outx0, outy0,
						outx1, outy1,
						outx2, outy2,
						deaths, reset_score);
	input CLOCK_50;
	input strt;
	input resetn;

	input [7:0] outx0;
	input [6:0] outy0;

	input [7:0] outx1;
	input [6:0] outy1;

	input [7:0] outx2;
	input [6:0] outy2;

	output reg [1:0]deaths;
	output reg reset_score;

	always@(*)
	begin
		if(strt)
			deaths <= 2'b0;
		if(((outx0 == outx1) && (outy0 == outy1)) || ((outx0 == outx2) && (outy0 == outy2)))
			deaths <= deaths + 1'b1;

		if(deaths == 2'd3)
			begin
				reset_score <= 1'b1;
				deaths <= 2'b0;
			end
		else
			reset_score <= 1'b0;
	end

endmodule

// char module inclusing fsm and datapath, uses keys for movement
module baby( CLOCK_50, resetn, xin, yin, colourin, cycleload, movement, outx, outy, outcolour, writeEn, strt);
        input CLOCK_50;
        input resetn;

        input [7:0]xin;
        input [6:0]yin;
        input [2:0]colourin;

        // load value to create speed from rate divider
        input [27:0]cycleload;
        input[3:0]movement;

        output [7:0] outx;
        output [6:0] outy;
        output [2:0] outcolour;
        output [0:0] writeEn;
		output strt;

        wire [0:0] ld, clear, update, divider_go;
		assign strt = ld;

        // rate divider for speed
        rateDivider rd(
        .clock(CLOCK_50),
        .cycleload(cycleload),
        .Enable(divider_go)
        );

        // Instansiate FSM control
        bee_control C(
                 .clk(CLOCK_50),
                 .resetn(resetn),

                 //clock from rate divider for speed
                 .go(divider_go),

                 .ld(ld),
                 .clear(clear),
                 .update(update)
        );

        // Instansiate datapath
        boy_datapath D(
                .clk(CLOCK_50),
                .ld(ld),
                .update(update),
                .clear(clear),

                .xin(xin),
                .yin(yin),
                .colourin(colourin),

                .movement(movement),

                .b_x(outx),
                .b_y(outy),
                .outcolour(outcolour),
                .writeEn(writeEn)
                );

endmodule

//boy datapath. takes CLOCK_50 and ld, update, clear, from bee_control.
// outputs x value, y value, colour and plot-enable-signal for VGA.
module boy_datapath( clk, ld, update, clear, xin, yin, colourin, movement, b_x, b_y, outcolour, writeEn);

        input clk;
        input [0:0]ld;
        input [0:0]update;
        input [0:0]clear;

        input [7:0]xin;
        input [6:0]yin;
        input [2:0]colourin;

        input[3:0]movement;

        output reg [7:0] b_x;
        output reg [6:0] b_y;
        output reg [2:0] outcolour;
        output reg [0:0] writeEn;

		// input registers
        always@(posedge clk)
        begin

            if(ld)
            begin
                b_x <= xin;
                b_y <= yin;
                outcolour <= colourin;
                writeEn <= 1'b1;
            end
            else if(clear)
            begin
                outcolour <= 3'b000;
                writeEn <= 1'b1;
            end
            else if(update)
            begin
                // right
                if ((~movement[0]) && (b_x != 8'd160))
                        b_x <= b_x + 1'b1;
                // down
                if ((~movement[1]) && (b_x != 8'd0))
                        b_y <= b_y + 1'b1;
                // up
                if ((~movement[2]) && (b_x != 8'd0))
                        b_y <= b_y - 1'b1;
                // left
                if ((~movement[3]) && (b_x != 8'd120))
                        b_x <= b_x - 1'b1;

                outcolour <= colourin;
                writeEn <= 1'b1;
            end
        end

endmodule

// bee module including FSM and datapath.
module beeby( CLOCK_50, resetn, xin, yin, colourin, cycleload, outx, outy, outcolour, writeEn);
        input CLOCK_50;
        input resetn;

        input [7:0]xin;
        input [6:0]yin;
        input [2:0]colourin;

        // load value to create speed from rate divider
        input [27:0]cycleload;

        output [7:0] outx;
        output [6:0] outy;
        output [2:0] outcolour;
        output [0:0] writeEn;

        wire [0:0]ld, clear, update, divider_go;

        // rate divider for speed
        rateDivider rd(
            .clock(CLOCK_50),
            .cycleload(cycleload),
            .Enable(divider_go)
        );

        // Instansiate FSM control
        bee_control C(
             .clk(CLOCK_50),
             .resetn(resetn),

             //clock from rate divider for speed
             .go(divider_go),

             .ld(ld),
             .clear(clear),
             .update(update)
        );

        // Instansiate datapath
        bee_datapath D(
            .clk(CLOCK_50),
            .ld(ld),
            .update(update),
            .clear(clear),

            .xin(xin),
            .yin(yin),
            .colourin(colourin),

            .b_x(outx),
            .b_y(outy),
            .outcolour(outcolour),
            .writeEn(writeEn)
        );

endmodule

// bee FSM and control path. takes input of CLOCK_50, reset_signal, (go)speed.
// outputs ld, clear or update to incicate what state we're in.
module bee_control( clk, resetn, go, ld, clear, update);
    input clk;
    input resetn;
    input go;

    output reg  ld, clear, update;

    reg [6:0] current_state, next_state;

    localparam  S_LOAD        = 4'd0,
                S_LOAD_WAIT   = 4'd1,
                S_CLEAR       = 4'd2,
                S_UPDATE      = 4'd3;

    // Next state logic aka our state table
     // load values for x and y then keep looping between clearing the previous, and updating to the new value
    always @(*)
    begin: state_table
            case (current_state)
                S_LOAD: next_state = S_LOAD_WAIT;
                S_LOAD_WAIT: next_state = go ? S_CLEAR : S_LOAD_WAIT;
                S_CLEAR: next_state = S_UPDATE;
                S_UPDATE: next_state = S_LOAD_WAIT;

            default:     next_state = S_LOAD;
            endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld = 1'b0;
        update = 1'b0;
        clear = 1'b0;
        case (current_state)
            S_LOAD: begin
                    ld = 1'b1;
                    update = 1'b0;
                    clear = 1'b0;
                end
            S_CLEAR: begin
                    clear = 1'b1;
                    ld = 1'b0;
                    update = 1'b0;
                end
            S_UPDATE: begin
                    ld = 1'b0;
                    update = 1'b1;
                    clear = 1'b0;
                end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
        // reset to initial position
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD;
        else
            current_state <= next_state;
    end // state_FFS

endmodule

//bee datapath. takes CLOCK_50 and ld, update, clear, from bee_control.
// outputs x value, y value, colour and plot-enable-signal for VGA.
module bee_datapath( clk, ld, update, clear, xin, yin, colourin, b_x, b_y, outcolour, writeEn);
    input clk;
    input [0:0]ld;
    input [0:0]update;
    input [0:0]clear;

    input [7:0]xin;
    input [6:0]yin;
    input [2:0]colourin;

    output reg [7:0] b_x;
    output reg [6:0] b_y;
    output reg [2:0] outcolour;
    output reg [0:0] writeEn;

    reg [0:0]b_x_direction, b_y_direction;

    // input registers
    always@(posedge clk)
    begin
        if ((b_x == 8'd0) || (b_x == 8'd160))
            begin
                b_x_direction <= ~b_x_direction;
                if ((b_x == 8'd0)) b_x <= 8'd1;
                else if ((b_x == 8'd160)) b_x <= 8'd159;
            end

        if ((b_y == 7'd0) || (b_y == 7'd120))
            begin
                b_y_direction <= ~b_y_direction;
                if ((b_y == 7'd0)) b_y <= 7'd1;
                else if ((b_y == 7'd120)) b_y <= 7'd119;
            end

        if(ld)
            begin
                b_x <= xin;
                b_y <= yin;
                outcolour <= colourin;
                writeEn <= 1'b1;
                b_x_direction<= 1'b0;
                b_y_direction <= 1'b0;
            end
        else if(clear || (b_x == 8'd0) || (b_x == 8'd160) || (b_y == 7'd0) || (b_y == 7'd120))
            begin
                outcolour <= 3'b000;
                writeEn <= 1'b1;
            end
        else if(update)
            begin

                if (~b_x_direction) b_x <= b_x + 1'b1;
                else b_x <= b_x - 1'b1;
                if (b_y_direction) b_y <= b_y + 1'b1;
                else b_y <= b_y - 1'b1;

                outcolour <= colourin;
                writeEn <= 1'b1;
            end
    end

endmodule

// rate divider
module rateDivider(clock, cycleload, Enable);
    input clock;
    input [27:0]cycleload;
    output [0:0]Enable;

    reg [27:0] q;

    always @(posedge clock)
    begin
        if(q[27:0] == 28'b0000000000000000000000000000)
            q[27:0] <= cycleload - 1'b1;
        else
            q <= q - 1'b1;
    end

    assign Enable = (q == 28'b0000000000000000000000000000) ? 1'b1 : 1'b0;

endmodule

//hex display
module hex_display(IN, OUT);
  input [3:0] IN;
  output reg [6:0] OUT;

  always @(*)
  begin
    case(IN[3:0])
      4'b0000: OUT = 7'b1000000;
      4'b0001: OUT = 7'b1111001;
      4'b0010: OUT = 7'b0100100;
      4'b0011: OUT = 7'b0110000;
      4'b0100: OUT = 7'b0011001;
      4'b0101: OUT = 7'b0010010;
      4'b0110: OUT = 7'b0000010;
      4'b0111: OUT = 7'b1111000;
      4'b1000: OUT = 7'b0000000;
      4'b1001: OUT = 7'b0011000;
      4'b1010: OUT = 7'b0001000;
      4'b1011: OUT = 7'b0000011;
      4'b1100: OUT = 7'b1000110;
      4'b1101: OUT = 7'b0100001;
      4'b1110: OUT = 7'b0000110;
      4'b1111: OUT = 7'b0001110;
      default: OUT = 7'b0111111;
    endcase
  end

endmodule

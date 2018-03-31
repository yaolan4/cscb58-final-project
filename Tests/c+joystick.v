// +test char; +joystick;

`timescale 1ns / 1ns // `timescale time_unit/time_precision

module beehive
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        GPIO,

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

	input [10:5]GPIO;	// 5:x, 7:y, 9:sw

    output [3:0] LEDR;

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
	assign resetn = KEY[0];

	////////////////////////// BOY INSTANTIATION //////////////////////////////

    wire [2:0] outcolour;
    wire [7:0] outx;
    wire [6:0] outy;
    wire [0:0] writeEn;


	// joystick stuff
	wire [3:0]movement;

	joystick j(
		.ix(GPIO[5]),
		.iy(GPIO[7]),

		.movement(movement)
		);

	baby B0(
			.CLOCK_50(CLOCK_50),
			.resetn(resetn),
			.xin(8'd70),
			.yin(7'd70),
			.colourin(3'b111),

			// cycle per second, not -1
			.cycleload(28'b0010111110101111000010000000),
			.movement(movement),

			.outx(outx),
			.outy(outy),
			.outcolour(outcolour),
			.writeEn(writeEn)
			);
	////////////////////////// END BOY INSTANTIATION //////////////////////////

    assign LEDR[3:0] = movement[3:0];

endmodule

// char module inclusing fsm and datapath, uses keys for movement
module baby( CLOCK_50, resetn, xin, yin, colourin, cycleload, movement, outx, outy, outcolour, writeEn);
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

        wire [0:0] ld, clear, update, divider_go;

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

// makes joystick input into input similar to keys concated
module joystick(ix, iy, movement);
	input ix, iy;
	output reg [3:0] movement;

	always@(*)
	begin
		movement[3:0] <= 4'b1111;
		// left
		if(ix == 1'b1)
		movement[3] <= 1'b0;
		// right
		else if (ix == 1'b0)
		movement[0] <= 1'b0;
		// up
		if(iy == 1'b1)
		movement[2] <= 1'b0;
		//down
		else if (iy == 1'b0)
		movement[1] <= 1'b0;
	end

endmodule

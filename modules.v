//////////////////////////////////////// DATAPATH /////////////////////////////////////////////////////

module datapath(
    input clk,
    input update,
    input clear,
    input bee,
	input waiting,
    input resetn,
    input [2:0] c_in,
    input [2:0] c2_in,
    input [7:0] x_in,
    input [6:0] y_in,
    input [3:0] dir_in,
    output [7:0] x_out,
    output [6:0] y_out,
    output reg [2:0] c_out,
    output reg writeEn,
    output reg done
    );

    // input registers
    reg [3:0] offset = 4'b0000;
    reg [2:0] c_val;
    reg [7:0] x_val;
    reg [6:0] y_val;
	 
	 reg up = 1'b1;
	 
    // Registers x, y, c with respective input logic
    always@(posedge clk) begin
	 
		writeEn = 1'b0;

        if (~resetn)
            begin
					 up = 1'b1;
            end

        else begin
            if (clear)
                begin
                    c_out <= 3'b111;
                    writeEn <= 1'b1;
                end
            else if (update)  // UPDATE HERE
					
					if (up)
						begin
							x_val = x_in;
							y_val = y_in;
							up = 1'b0;
						end
						
                else begin
                    writeEn =	 1'b0;
                    if (dir_in[0] == 1'b1)  // RIGHT
                        x_val = x_val + 1;
                    if (dir_in[3] == 1'b1)	// LEFT
                        x_val = x_val - 1;
                    if (dir_in[2] == 1'b1)	// DOWN
                        y_val = y_val + 1;
                    if (dir_in[1] == 1'b1)	// UP
                        y_val = y_val - 1;
                end 
            else if (~waiting)      // DRAWING STATE
                begin
                    writeEn = 1'b1;
                    // Checks what type of object it is and draws shape
                    if (bee)
                        c_out = (offset[0]) ? c2_in : c_in;
                    else
                        c_out = c_in;
                        
                end
                
        end
    end

    // Increment offset, first 2 bits for x,2nd for y
    always@(posedge clk) 
	 begin
        if (waiting || update)
            done = 1'b0;
			
        if (~waiting && ~update && ~done) 
		  begin
		  
            if (offset == 4'b1111)
            begin
                offset <= 4'b0000;
                done = 1'b1;
            end 
            else
                offset = offset + 1'b1;
        end
    end

        assign x_out = x_val + offset[1:0];
        assign y_out = y_val + offset[3:2];

endmodule // datapath

///////////////////////////////////////////////////////// CONTROL ///////////////////////////////////////////////////////////

module control(
    input clk,
	input slowClk,
    input resetn,
    input done,
	input moved,
    output reg  clear,
    output reg update,
	output reg waiting
    );

    reg [2:0] current_state, next_state;

    localparam  S_CLEAR   	= 5'd1,
                S_UPDATE 	= 5'd2,	
                S_DRAW      = 5'd3,
				S_WAIT		= 5'd4;

    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                S_WAIT: next_state = slowClk ? S_CLEAR : S_WAIT; // Loop in current state until go signal goes low
                S_CLEAR: next_state = done ? S_UPDATE : S_CLEAR; // Loop in current state until value is input
                S_UPDATE : next_state = S_DRAW;
                S_DRAW: next_state = done ? S_WAIT : S_DRAW; // Draw state, Go back to X
            default:     next_state = S_CLEAR;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        clear = 1'b0;
        update = 1'b0;
		waiting = 1'b0;
        case (current_state)
			S_WAIT:     waiting = 1'b1;
            S_CLEAR:    clear = 1'b1;
            S_UPDATE:   update = 1'b1;
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        current_state <= next_state;
    end // state_FFS
endmodule // control

////////////////////////////////////////// RATE DIVIDER ////////////////////////////////////////////////////

module rate_divider(clk, load_val, out);
	input clk;
	input [27:0] load_val;
	output [27:0] out;
	
	reg [27:0] count;
	
    assign out = count;
	
	always @(posedge clk)
	begin
		if (count == 28'h0000000)
			count <= load_val;
		else
			count <= count - 1;
	end
endmodule 

/////////////////////////////////////////// HEX DISPLAY /////////////////////////////////////////////////////////

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


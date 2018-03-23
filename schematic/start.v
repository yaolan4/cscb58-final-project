// Top level module. Handles instantiation, controls,
// Also potentially bouncing of bees. Might want to refactor this into mechanics

module proj (
	input CLOCK_50,
	input [17:0] SW,
	output [17:0] LEDR);
	
	
    control c0(1'b1, SW[7:4], SW[9],
        28'h1111111, 28'h1111111, LEDR[1], LEDR[2], LEDR[9:6]);
    assign LEDR[0] = SW[0];
    // fuck you quartus
endmodule 

// Module that handles all the game mechanics
// including user collisions, boundary detection,
// scoring, lives, etc
module mechanics (
        // Inputs
        input reset_n,
        input [6:0] user_x,
        input [6:0] user_y,
		  
        input [69:0] bees_x,       // Hardcoded for now, assuming 10 bees
        input [69:0] bees_y,		  // index [6:0], [13:7], [20, 14]...
		  
        // input [9:0] bees_enable      // Can be used later to make bees appear?

        // Outputs
        output reg game_reset,
        output reg game_over,           // Unused for now, happens when lives over
        output reg [1:0] lives,         // 4 lives for now
        output reg [7:0] score,
        output reg [7:0] high_score

    );
	 
	 // Important TODO
	 // Figure out how to do the scoring.
	 // Time maybe? Rate Divider and count up every couple seconds?

    initial begin
        lives       = 2'b11;
        score       = 8'h00;
        high_score  = 8'h00;
    end

    // Placeholder values, need to change these to
    // appropriate screen boundary vaues in pixels
    localparam LEFTEDGE     = 7'b0000000;
    localparam RIGHTEDGE    = 7'b111111;
    localparam TOPEDGE      = 7'b0000000;
    localparam BOTTOMEDGE   = 7'b111111;
    

    wire bees_collided, edges_collided;
    // Checking for collisions between all bees
    // (can do && with bees_enable index later...)
	 
	 // Maybe refactor this, avoided inputting individually
	 // because code gets really messy really fast.
    assign bees_collided = 
        (user_x == bees_x[6:  0] && user_y == bees_y[6:  0]) ||
        (user_x == bees_x[13: 7] && user_y == bees_y[13: 7]) ||
        (user_x == bees_x[20:14] && user_y == bees_y[20:14]) || 
        (user_x == bees_x[27:21] && user_y == bees_y[27:21]) ||
        (user_x == bees_x[34:28] && user_y == bees_y[34:28]) ||
        (user_x == bees_x[41:35] && user_y == bees_y[41:35]) ||
        (user_x == bees_x[48:42] && user_y == bees_y[48:42]) ||
        (user_x == bees_x[55:49] && user_y == bees_y[55:49]) ||
        (user_x == bees_x[62:56] && user_y == bees_y[62:56]) ||
        (user_x == bees_x[69:63] && user_y == bees_y[69:63]);

    assign edges_collided = 
        (user_x >= RIGHTEDGE) ||
        (user_x <= LEFTEDGE)  ||
        (user_y <= TOPEDGE)   ||
        (user_y >= BOTTOMEDGE);

    assign collided = bees_collided || edges_collided;

    // Actual logic here
    always @(*)
    begin
        game_reset = 1'b0;
        game_over = 1'b0;

        // If reset is pressed
        if (reset_n)
            begin
                game_reset = 1'b1;
                score      = 1'b0;
                lives      = 2'b11;
            end
        
        // If player has collided with something 
        else if (collided)
            begin
                // If no more lives, want to end game (TODO)
                if (lives == 2'b00)
                    begin 
                        game_over = 1'b1;		// Figure out Game over. Maybe new state in FSM?
                        game_reset = 1'b1;      
                        lives = 2'b11;        // For now just resetting lives
                        score = 8'h00;
                    end
                // Else just reset and reduce one life
                else
                    begin
                        game_reset = 1'b1;
                        lives = lives - 1'b1;
                    end
            end

        // Update high score (Hopefully useful after scoring works)
        if (score >= high_score)
            high_score = score;

    end

endmodule // mechanics

module datapath (
        // Inputs
        input clk,
        input [3:0] dir_in,
        input load_xy,
        // input reset_n,
        input clear,
        input [6:0] x_in,
        input [6:0] y_in,
        input [2:0] color_in,

        // Outputs
        output reg [6:0] x_out,
        output reg [6:0] y_out,
        output reg [2:0] color_out,
        output reg writeEn
    );


    // Interpret dir_in bits as follows
    // [left, down, up, right]

    
    always @(posedge clk)
    begin
        // Load in values from input
        if (load_xy)
            begin
                x_out = x_in;
                y_out = y_in;
                writeEn = 1'b0;
                color_out = color_in;
            end

        // Draw black square at current location
        else if (clear)
            begin
                writeEn = 1'b1;
                color_out = 3'b000;
            end

        // ---------- MOVEMENT CASES ----------

        // Going right (like nothing in my life)
        else if (dir_in == 4'b0001)
            begin
                x_out = x_out + 1'b1;
                y_out = y_out;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going up
        else if (dir_in == 4'b0010)
            begin
                x_out = x_out;
                y_out = y_out - 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going down (like my gpa)
        else if (dir_in == 4'b0100)
            begin
                x_out = x_out;
                y_out = y_out + 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going left
        else if (dir_in == 4'b1000)
            begin
                x_out = x_out - 1'b1;
                y_out = y_out;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // ---------- DIAGONAL MOVEMENT ----------

        // Going diagonally top right
        else if (dir_in == 4'b0011)
            begin
                x_out = x_out + 1'b1;
                y_out = y_out - 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going diagonally top left
        else if (dir_in == 4'b1010)
            begin
                x_out = x_out - 1'b1;
                y_out = y_out - 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going diagonally bottom right  
        else if (dir_in == 4'b0101)
            begin
                x_out = x_out + 1'b1;
                y_out = y_out + 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // Going diagonally bottom left
        else if (dir_in == 4'b1100)
            begin
                x_out = x_out - 1'b1;
                y_out = y_out + 1'b1;
                color_out = color_in;
                writeEn = 1'b1;
            end

        // -------- END MOVEMENT CASES ----------

    end

endmodule // datapath


module control (
        // Inputs
        input clk,
        input [3:0] dir_in,
        input reset_n,
        input game_reset,
        input [27:0] rate,    // For the rate divider
        input [27:0] offset,  // Offset to ensure VGA display 

        // Outputs
        output reg load_xy,
        output reg clear,
        output reg [3:0] dir_out
    );

    reg [2:0] current_state;
    reg [2:0] next_state;
        
    wire rate_out;
        
    // State definitions
    localparam UPDATE_XY    = 3'b000;
    localparam SELECT_DIR   = 3'b001;
    localparam CLEAR        = 3'b010;
    localparam MOVE         = 3'b011;
    localparam RESET        = 3'b100;

    // Need RateDivider that outputs rate_out
    // Offsets different for each 'object' to
    // draw them onto the screen at different cycles
    rate_divider rd(
        .clk(clk), 
        .compare(offset), 
        .load_val(rate), 
        .out(rate_out)
    );

    // State transitions
    always @(*)
    begin
        case (current_state)
            UPDATE_XY:  next_state = SELECT_DIR;
            SELECT_DIR:      
                begin
                    if (game_reset)
                        next_state <= RESET;
                    else if (rate_out)
                        next_state <= CLEAR;
                    else
                        next_state <= UPDATE_XY;
                end
            CLEAR:      next_state = MOVE;
            MOVE:       next_state = game_reset ? RESET : UPDATE_XY;
        
            default:    next_state = RESET;
        endcase
    end

    // State functions
    always @(*)
    begin
        load_xy = 1'b0;
        clear = 1'b0;
        dir_out = 4'h0;

        case (current_state)
            UPDATE_XY:  load_xy = 1'b1;
            CLEAR:      clear   = 1'b1;
            MOVE:       dir_out = dir_in;
            RESET:      clear   = 1'b1;
        endcase 
    end

    // State change on clock edge
    always @(posedge clk)
    begin: states
        if(reset_n)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

endmodule // control

// Takes in a load value as well as a compare value
// Sets out to 1 whenever interal counter == compare
module rate_divider (
        input clk, 
        input [27:0] compare, 
        input [27:0] load_val, 
        output out
    );
    
    reg [27:0] count;
    
    assign out = (count == compare) ? 1 : 0;
    
    always @(posedge clk)
    begin
        // Reset once it hits the max
        if (count == load_val)
            count <= 28'h0000000;
        else
            count <= count + 1;
    end
endmodule // rate_divider

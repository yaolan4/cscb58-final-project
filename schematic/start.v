module datapath(input clk,
                input [3:0] dir_in,
                input load_xy,
                // input reset_n,
                input clear,
                input [6:0] x_in,
                input [6:0] y_in,
                input [2:0] color_in,
                output reg [6:0] x_out,
                output reg [6:0] y_out,
                output reg [2:0] color_out,
                output reg writeEn
                );
    // dir_in interpret as the following:
    // [left, down, up, right]

    always @(posedge clk)
    begin

        if (load_xy)
            begin
                x_out = x_in;
                y_out = y_in;
                writeEn = 1'b0;
                color_out = color_in;
            end
        else if (clear)
            begin
                writeEn = 1'b1;
                color_out = 3'b000;
            end
        // Going right
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

        // Going down (like gpa)
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
    end

endmodule


module control( input clk,
                input [3:0] dir_in,
                input reset_n,
                input game_reset,
                input [27:0] rate,    // For the rate divider
                input [27:0] offset,  // Offset to ensure VGA display 
                output load_xy,
                output clear,
                output [3:0] dir_out
                );

    reg [2:0] curr_state;
    reg [2:0] next_state;
        
    wire rate_out;
        
    // State definitions
    localparam UPDATE_XY    = 3'b000;
    localparam SELECT_DIR   = 3'b001;
    localparam CLEAR        = 3'b010;
    localparam MOVE         = 3'b011;
    localparam RESET        = 3'b100;

    // Need RateDivider that outputs rate_out
    rate_divider rd(
        .clk(clk), 
        .compare(offset), 
        .load_val(rate), 
        .out(rate_out)
    );

    always @(*)
    begin: Transition_States
        case (curr_state)
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

    always @(posedge clk)
    begin: states
        if(reset_n)
            curr_state <= RESET;
        else
            curr_state <= next_state;
    end

endmodule

module rate_divider(clk, compare, load_val, out);
    input clk;
   input [27:0] compare;
    input [27:0] load_val;
    output out;
    
    reg [27:0] count;
    
    assign out = (count == compare) ? 1 : 0;
    
    always @(posedge clk)
    begin
        if (count == load_val)
            count <= 28'h0000000;
        else
            count <= count + 1;
    end
endmodule


module proj(LEDR, SW);
    input [9:0] SW;
    output [9:0] LEDR;
    control c0(1'b1, SW[7:4], SW[9],
        28'h1111111, 28'h1111111, LEDR[1], LEDR[2], LEDR[9:6]);
    assign LEDR[0] = SW[0];
    // fuck you quartus
endmodule 

module control(input clk,
              input [3:0] dir_in,
              input reset_n,
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
   localparam MOVE         = 3'b011; // Possibly unwanted
   localparam RESET        = 3'b100;

   //Need RateDivider that outputs rate_out
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
                    if (reset_n)
                        next_state <= RESET;
                    else if (rate_out)
                        next_state <= CLEAR;
                    else
                        next_state <= UPDATE_XY;
                end
           CLEAR:      next_state = MOVE;
           MOVE:       next_state = reset_n ? RESET : UPDATE_XY;
       
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

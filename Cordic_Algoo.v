module Cordic_Algoo#(
    // Declare Constants (how module behaves)
   parameter IW = 10, // # of bits for input
    parameter OW = 10, // # of bits for output
    parameter PIPESTAGE = 10, // # of pipeline stages
    parameter WW = 12, // # of bits for width
    parameter PW = 14 // # of bits for phase variables
)
( // External Signals
    input wire i_clk, i_reset, i_enable, // clock, reset, enable signals
    input wire signed [(IW-1):0] i_xcord, i_ycord, // input x and y coordinates
    input wire signed [(PW-1):0] i_phase, // input phase variable
    output reg signed [(OW-1):0] o_xcord, o_ycord, // output x and y coordinates
    input wire i_aux, // auxiliary input for additional control
    output reg o_aux // auxiliary output for additional control
);

// Ex: [(IW-1):0] = [(12):0] = 13 bits

// variable declarations for all stages

wire signed [(WW-1):0] e_xcord, e_ycord; // external x and y values
reg signed [(WW-1):0] x_vec [0:(PIPESTAGE)]; // x vector for each stage
reg signed [(WW-1):0] y_vec [0:(PIPESTAGE)]; // y vector for each stage
reg  [(PW-1):0] phase_vec [0:(PIPESTAGE)]; // phase vector for each stage
reg [(PIPESTAGE):0] aux_vec; // auxiliary vector for each stage

// array of registers for each stage
// x_vec[0] is input pre rotation
// x_vec[1] is output of stage 0 then keeps going each stage

assign	e_xcord = { {i_xcord[(IW-1)]}, i_xcord, {(WW-IW-1){1'b0}} };
assign	e_ycord = { {i_ycord[(IW-1)]}, i_ycord, {(WW-IW-1){1'b0}} };

initial aux_vec = 0; // initialize auxiliary vector
always @(posedge i_clk) 
    if (i_reset)  // if reset is high clear auxiliary vector
        aux_vec <= 0;
     else if (i_enable) // if enable is high shift in auxiliary input
        aux_vec <= {aux_vec[(PIPESTAGE-1):0], i_aux}; // Take old value in aux_vec and shift in new value

initial begin
   x_vec[0] = 0; // for simulation purposes
   y_vec[0] = 0;
   phase_vec[0] = 0; 
    
end

always @(posedge i_clk) 
    if (i_reset) begin // if reset is high clear all vectors
        x_vec[0] <= 0;
        y_vec[0] <= 0;
        phase_vec[0] <= 0;
    end else if (i_enable) begin // if enable is high shift in new values
       case (i_phase[(PW-1):(PW-3)]) // use the top 2 bits of phase to determine operation
       3'b000: begin	// 0 .. 45, No change
		// {{{
			x_vec[0] <= e_xcord;
			y_vec[0] <= e_ycord;
			phase_vec[0] <= i_phase;
			end
			// }}}
		3'b001: begin	// 45 .. 90
		// {{{
			x_vec[0] <= -e_ycord;
			y_vec[0] <= e_xcord;
			phase_vec[0] <= i_phase - 20'h40000;
			end
			// }}}
		3'b010: begin	// 90 .. 135
		// {{{
			x_vec[0] <= -e_ycord;
			y_vec[0] <= e_xcord;
			phase_vec[0] <= i_phase - 20'h40000;
			end
			// }}}
		3'b011: begin	// 135 .. 180
		// {{{
			x_vec[0] <= -e_xcord;
			y_vec[0] <= -e_ycord;
			phase_vec[0] <= i_phase - 20'h80000;
			end
			// }}}
		3'b100: begin	// 180 .. 225
		// {{{
			x_vec[0] <= -e_xcord;
			y_vec[0] <= -e_ycord;
			phase_vec[0] <= i_phase - 20'h80000;
			end
			// }}}
		3'b101: begin	// 225 .. 270
		// {{{
			x_vec[0] <= e_ycord;
			y_vec[0] <= -e_xcord;
			phase_vec[0] <= i_phase - 20'hc0000;
			end
			// }}}
		3'b110: begin	// 270 .. 315
		// {{{
			x_vec[0] <= e_ycord;
			y_vec[0] <= -e_xcord;
			phase_vec[0] <= i_phase - 20'hc0000;
			end
			// }}}
		3'b111: begin	// 315 .. 360, No change
		// {{{
			x_vec[0] <= e_xcord;
			y_vec[0] <= e_ycord;
			phase_vec[0] <= i_phase;
			end
			// }}}
		endcase
		// }}}
	end

    wire	[19:0]	cordic_angle [0:(PIPESTAGE-1)];

    // CORDIC angles for each stage
	assign	cordic_angle[ 0] = 20'h1_2e40; //  26.565051 deg
	assign	cordic_angle[ 1] = 20'h0_9fb3; //  14.036243 deg
	assign	cordic_angle[ 2] = 20'h0_5111; //   7.125016 deg
	assign	cordic_angle[ 3] = 20'h0_28b0; //   3.576334 deg
	assign	cordic_angle[ 4] = 20'h0_145d; //   1.789911 deg
	assign	cordic_angle[ 5] = 20'h0_0a2f; //   0.895174 deg
	assign	cordic_angle[ 6] = 20'h0_0517; //   0.447614 deg
	assign	cordic_angle[ 7] = 20'h0_028b; //   0.223811 deg
	assign	cordic_angle[ 8] = 20'h0_0145; //   0.111906 deg
	assign	cordic_angle[ 9] = 20'h0_00a2; //   0.055953 deg
	assign	cordic_angle[10] = 20'h0_0051; //   0.027976 deg
	assign	cordic_angle[11] = 20'h0_0028; //   0.013988 deg
	assign	cordic_angle[12] = 20'h0_0014; //   0.006994 deg
	assign	cordic_angle[13] = 20'h0_000a; //   0.003497 deg
	assign	cordic_angle[14] = 20'h0_0005; //   0.001749 deg
	assign	cordic_angle[15] = 20'h0_0002; //   0.000874 deg


    genvar	i;
	generate for(i=0; i<PIPESTAGE; i=i+1) begin : CORDICops

        initial begin
			x_vec[i+1] = 0;
			y_vec[i+1] = 0;
			phase_vec[i+1] = 0;
		end

		always @(posedge i_clk)
	if (i_reset)
		begin
			x_vec[i+1] <= 0;
			y_vec[i+1] <= 0;
			phase_vec[i+1] <= 0;
		end else if (i_enable) begin
        if ((cordic_angle[i] == 0)||(i >= WW))
			begin
                x_vec[i+1] <= x_vec[i];
                y_vec[i+1] <= y_vec[i];
                phase_vec[i+1] <= phase_vec[i];
            end else if (phase_vec[i][PW-1]) begin // if phase is negative
                x_vec[i+1] <= x_vec[i] + (y_vec[i] >>> i);
                y_vec[i+1] <= y_vec[i] - (x_vec[i] >>> i);
                phase_vec[i+1] <= phase_vec[i] + cordic_angle[i];
            end else begin // if phase is positive
                x_vec[i+1] <= x_vec[i] - (y_vec[i] >>> i);
                y_vec[i+1] <= y_vec[i] + (x_vec[i] >>> i);
                phase_vec[i+1] <= phase_vec[i] - cordic_angle[i];
            end

        end
    end endgenerate

    wire	[(WW-1):0]	pre_xcord, pre_ycord;

    assign	pre_xcord = x_vec[PIPESTAGE] + $signed({ {(OW){1'b0}},
				x_vec[PIPESTAGE][(WW-OW)],
				{(WW-OW-1){!x_vec[PIPESTAGE][WW-OW]}} });
	assign	pre_ycord = y_vec[PIPESTAGE] + $signed({ {(OW){1'b0}},
				y_vec[PIPESTAGE][(WW-OW)],
				{(WW-OW-1){!y_vec[PIPESTAGE][WW-OW]}} });

initial begin
		o_xcord = 0;
		o_ycord = 0;
		o_aux  = 0;
	end
	always @(posedge i_clk)
if (i_reset) begin
	o_xcord <= 0;
	o_ycord <= 0;
	o_aux   <= 0;
end else if (i_enable) begin
	o_xcord <= pre_xcord[(WW-1):(WW-OW)];
	o_ycord <= pre_ycord[(WW-1):(WW-OW)];
	o_aux   <= aux_vec[PIPESTAGE]; 
end


endmodule
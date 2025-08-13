`timescale 1ns/1ps

module tb_Cordic_Algoo;

  localparam IW = 13;
  localparam OW = 13;
  localparam PW = 20;

  reg i_clk = 0;
  reg i_reset = 1;
  reg i_enable = 0;
  reg signed [IW-1:0] i_xcord = 0;
  reg signed [IW-1:0] i_ycord = 0;
  reg [PW-1:0] i_phase = 0;
  reg i_aux = 0;

  wire signed [OW-1:0] o_xcord;
  wire signed [OW-1:0] o_ycord;
  wire o_aux;

  // Instantiate your DUT
  Cordic_Algoo dut (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_enable(i_enable),
    .i_xcord(i_xcord),
    .i_ycord(i_ycord),
    .i_phase(i_phase),
    .i_aux(i_aux),
    .o_xcord(o_xcord),
    .o_ycord(o_ycord),
    .o_aux(o_aux)
  );

  // Clock generation
  always #5 i_clk = ~i_clk;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_Cordic_Algoo);

    // Initial delay and reset
    #10;
    i_reset = 0;
    i_enable = 1;

    // Input: Rotate (1, 0) by 45 degrees
    i_xcord = 13'sd4096;      // 1.0 in Q12
    i_ycord = 13'sd0;
    i_phase = 20'd262144;     // 45 degrees
    i_aux = 1;

    #10 i_aux = 0;

    // Wait for o_aux to go high (means output is valid)
    wait (o_aux == 1);
    $display("Output: x = %d, y = %d (valid)", o_xcord, o_ycord);

    // Try a second test input: 90 degrees
    i_xcord = 13'sd4096;
    i_ycord = 13'sd0;
    i_phase = 20'd524288;     // 90 degrees
    i_aux = 1;

    #10 i_aux = 0;

    wait (o_aux == 1);
    $display("Output: x = %d, y = %d (valid)", o_xcord, o_ycord);

    #50;
    $finish;
  end

endmodule

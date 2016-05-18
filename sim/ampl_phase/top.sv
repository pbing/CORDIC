/* Amplitude/Phase */

module top;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tclk = 1s / 100.0e6;

   parameter width  = 16;
   parameter iterations = width + 1;

   bit                       reset;      // reset
   bit                       clk;        // clock
   bit  signed [width - 1:0] x0, y0, z0; // inputs
   wire signed [width    :0] x, y;       // outputs (scaled with K=1.6767605)
   wire signed [width - 1:0] z;          // output
   bit  signed [width - 1:0] phase;
   int                       ch;

   cordic
     #(.vectoring (1),
       .width     (width),
       .iterations(iterations))
   dut(.*);

   always #(tclk/2) clk = ~clk;

   always @(negedge clk)
     if (reset)
       phase <= 0;
     else
       phase <= phase + 1;

   always_comb
     begin
        x0 = (2**(width - 1) - 1) * $cos(6.28318530718 * phase / 2**width);
        y0 = (2**(width - 1) - 1) * $sin(6.28318530718 * phase / 2**width);
     end

   initial
     begin:main
        z0 = 0;

        ch = $fopen("ampl_phase.csv");
        $fdisplay(ch, "x, y, z");

        reset = 1'b1;
        repeat (2) @(negedge clk);
        reset = 1'b0;

        repeat (iterations + 3) @(negedge clk);

        repeat (2**width)
          begin
             @(negedge clk);
             $fdisplay(ch, "%d, %d, %d", x, y, z);
          end

        $fclose(ch);
        $finish;
     end:main
endmodule

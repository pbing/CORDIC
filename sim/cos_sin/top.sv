/* Cosinus/Sinus */

module top;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tclk = 1s / 100.0e6;

   parameter width      = 16;
   parameter iterations = width + 2;

   bit                       reset;      // reset
   bit                       clk;        // clock
   bit  signed [width - 1:0] x0, y0, z0; // inputs
   wire signed [width    :0] x, y;       // outputs (scaled with K=1.6767605)
   wire signed [width - 1:0] z;          // output
   int                       ch;         // file channel

   cordic
     #(.vectoring (0),
       .width     (width),
       .iterations(iterations))
   dut(.*);

   always #(tclk/2) clk = ~clk;

   always @(negedge clk)
     if (reset)
       z0 <= -2**(width - 1);
     else
       z0 <= z0 + 1;

   initial
     begin:main
        x0 = 2**(width - 1) - 1; // max. input range (ideal 16 bit ENOB = 16.50453)
        y0 = 0;

        ch = $fopen("cos_sin.csv");
        $fdisplay(ch, "x, y, z");

        reset = 1'b1;
        repeat (2) @(negedge clk);
        reset = 1'b0;

`ifdef SHOW_FLOAT
        repeat (iterations - 1) @(negedge clk);

        repeat (2**width)
          begin
             @(negedge clk);
             $fdisplay(ch, "%f, %f, %f", 
                       dut.xr[iterations - 1] * 2.0**(-dut.guard_bits),
                       dut.yr[iterations - 1] * 2.0**(-dut.guard_bits),
                       dut.zr[iterations - 1] * 2.0**(-dut.guard_bits));
          end
`else
        repeat (iterations) @(negedge clk);

        repeat (2**width)
          begin
             @(negedge clk);
             $fdisplay(ch, "%8d, %8d, %8d", x, y, z);
          end
`endif

        $fclose(ch);
        $finish;
     end:main
endmodule

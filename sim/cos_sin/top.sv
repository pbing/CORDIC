/* Cosinus/Sinus */

module top;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tclk = 1s / 100.0e6;

   parameter width      = 16;                          // number of bits
   parameter iterations = width + 2;                   // number of iterations
   parameter guard_bits = iterations - 1;              // equal to number of right shifts of x and y
   //parameter guard_bits = $ceil(iterations / 2);
   //parameter guard_bits = $clog2(iterations);

   bit                       reset;      // reset
   bit                       clk;        // clock
   bit  signed [width - 1:0] x0, y0, z0; // inputs
   wire signed [width    :0] x, y;       // outputs (scaled with K=1.6467...)
   wire signed [width - 1:0] z;          // output
   int                       ch;         // file channel

   cordic
     #(.vectoring (0),
       .width     (width),
       .iterations(iterations),
       .guard_bits(guard_bits))
   dut(.*);

   always #(tclk/2) clk = ~clk;

   always @(negedge clk)
     if (reset)
       z0 <= -2**(width - 1);
     else
       z0 <= z0 + 1;

   initial
     begin:main
        real xr, yr, zr;

        x0 = 2**(width - 1) - 1; // max. input range (ideal 16 bit ENOB = 16.7196 [-53959...53959])
        y0 = 0;

        ch = $fopen("imp.csv");
        $fdisplay(ch, "xr, yr, zr, x, y, z");

        reset = 1'b1;
        repeat (2) @(negedge clk);
        reset = 1'b0;

        repeat (iterations + 1) @(negedge clk);

        xr <= dut.xr[iterations] * 2.0**(-guard_bits);
        yr <= dut.yr[iterations] * 2.0**(-guard_bits);
        zr <= dut.zr[iterations] * 2.0**(-guard_bits);

        repeat (2**width)
          begin
             @(negedge clk);
             $fdisplay(ch, "%f, %f, %f, %d, %d, %d", xr, yr, zr,x, y, z);

             xr <= dut.xr[iterations] * 2.0**(-guard_bits);
             yr <= dut.yr[iterations] * 2.0**(-guard_bits);
             zr <= dut.zr[iterations] * 2.0**(-guard_bits);
          end

        $fclose(ch);
        $finish;
     end:main
endmodule

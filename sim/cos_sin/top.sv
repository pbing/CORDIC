/* Cosinus/Sinus */

module top;
   timeunit 1ns;
   timeprecision 1ps;

   const realtime tclk = 1s / 100.0e6;

   parameter width  = 16;
   parameter iterations = width + 1;

   bit                       reset;
   bit                       clk;
   bit  signed [width - 1:0] x0, y0, z0;
   wire signed [width - 1:0] x, y, z;
   int                       ch;

   cordic #(width, iterations) dut(.*);

   always #(tclk/2) clk = ~clk;

   always @(negedge clk)
     if (reset)
       z0 <= 0;
     else
       z0 <= z0 + 1;

   initial
     begin:main
        x0 = 19898; // adjust for max. amplitude
        y0 = 0;
        z0 = 0;
        ch = $fopen("cos_sin.csv");
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

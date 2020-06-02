/* Pipelined CORDIC, polar coordinates
 *
 * π/2    := 2**(width - 2)
 * π      := 2**(width - 1)
 * atan() := 2**(with + guard_bits - 1) / π * atan(2**(-i))
 */

module cordic
  #(vectoring = 0,                                // 0: rotating mode, 1:vectoring mode
    width = 16,                                   // number of bits
    iterations = width + 2,                       // number of iterations
    guard_bits = iterations - 1)                  // equal to number of right shifts of x and y
   (input  wire                       reset,      // reset
    input  wire                       clk,        // clock
    input  wire                       en,         // clock enable
    input  wire  signed [width - 1:0] x0, y0, z0, // inputs
    output logic signed [width    :0] x, y,       // outputs (scaled with K=1.6467...)
    output logic signed [width - 1:0] z);         // output (not scaled)

   const bit signed [width - 1:0] pi_2 = 2**(width - 2); // π/2

`include "atan_z.svh" // change this according to number of iterations

   logic signed [width + guard_bits    :0] xr[iterations + 1], yr[iterations + 1];
   logic signed [width + guard_bits - 1:0] zr[iterations + 1];

   always_ff @(posedge clk or posedge reset)
     if (reset)
       for (int i = 0; i < iterations + 1; ++i)
         begin
            xr[i] <= '0;
            yr[i] <= '0;
            zr[i] <= '0;
         end
     else
       if (en)
         for (int i = -1; i < iterations; ++i)
           if (i == -1)

	     /* Input scaling and
	      * map argument -π...π to -π/2...π/2.
              *
              * Replace <width> bit wide comparision operators
              * with 2 bit comparision due to
              * [0   ,  π/2) = 00...
              * [π/2 ,  π  ) = 01...
              * [0   , -π/2) = 11...
              * [-π/2, -π  ) = 10...
	      */
             if (vectoring == 1)
               if (x0 < 0 && y0 >= 0) // z0 >= π/2
                 begin
                    xr[0] <= y0          << guard_bits;
                    yr[0] <= -x0         << guard_bits;
                    zr[0] <= (z0 + pi_2) << guard_bits;
                 end
               else if (x0 < 0 && y0 < 0) // z0 <= -π/2
                 begin
                    xr[0] <= -y0         << guard_bits;
                    yr[0] <= x0          << guard_bits;
                    zr[0] <= (z0 - pi_2) << guard_bits;
                 end
               else
                 begin
                    xr[0] <= x0 << guard_bits;
                    yr[0] <= y0 << guard_bits;
                    zr[0] <= z0 << guard_bits;
                 end
             else
               if (z0[$left(z0)-:2] == 2'b10) // z0 <= -π/2
                 begin
                    xr[0] <= y0          << guard_bits;
                    yr[0] <= -x0         << guard_bits;
                    zr[0] <= (z0 + pi_2) << guard_bits;
                 end
               else if (z0[$left(z0)-:2] == 2'b01) // z0 >= π/2
                 begin
                    xr[0] <= -y0         << guard_bits;
                    yr[0] <= x0          << guard_bits;
                    zr[0] <= (z0 - pi_2) << guard_bits;
                 end
               else
                 begin
                    xr[0] <= x0 << guard_bits;
                    yr[0] <= y0 << guard_bits;
                    zr[0] <= z0 << guard_bits;
                 end
           else
             if (vectoring == 1)

               /* Vectoring Mode */
               if (yr[i] >= 0)
                 begin
                    xr[i + 1] <= xr[i] + (yr[i] >>> i);
                    yr[i + 1] <= yr[i] - (xr[i] >>> i);
                    zr[i + 1] <= zr[i] + atan_z[i];
                 end
               else
                 begin
                    xr[i + 1] <= xr[i] - (yr[i] >>> i);
                    yr[i + 1] <= yr[i] + (xr[i] >>> i);
                    zr[i + 1] <= zr[i] - atan_z[i];
                 end
             else

               /* Rotating Mode */
               if (zr[i] < 0)
                 begin
                    xr[i + 1] <= xr[i] + (yr[i] >>> i);
                    yr[i + 1] <= yr[i] - (xr[i] >>> i);
                    zr[i + 1] <= zr[i] + atan_z[i];
                 end
               else
                 begin
                    xr[i + 1] <= xr[i] - (yr[i] >>> i);
                    yr[i + 1] <= yr[i] + (xr[i] >>> i);
                    zr[i + 1] <= zr[i] - atan_z[i];
                 end

   /* output register */
   always_ff @(posedge clk or posedge reset)
     if (reset)
       begin
          x <= '0;
          y <= '0;
          z <= '0;
       end
     else
       if (en)
         begin
            x <= round_result(xr[iterations]);
            y <= round_result(yr[iterations]);
            z <= round_result(zr[iterations]);
         end

   function signed [width:0] round_result(input signed [width + guard_bits:0] x);
      return (x + 2**(guard_bits - 1)) >>> guard_bits;
   endfunction
endmodule

/* Pipelined CORDIC, polar coordinates
 *
 * π/2    := 2**(width - 2)
 * π      := 2**(width - 1)
 * atan() := 2**(with + iterations - 1) / π * atan(2**(-i))
 */

module cordic
  #(vectoring,                                    // 0: rotating mode, 1:vectoring mode
    width,                                        // number of bits
    iterations = width + 1)                       // number of iterations
   (input  wire                       reset,      // reset
    input  wire                       clk,        // clock
    input  wire  signed [width - 1:0] x0, y0, z0, // inputs
    output logic signed [width    :0] x, y,       // outputs (scaled with K=1.6767605)
    output logic signed [width - 1:0] z);         // output

   localparam guard_bits  = $clog2(iterations);

   const bit signed [width - 1:0] pi_2 = 2**(width - 2); // π/2

`include "atan_z_17.svh" // change this according to number of iterations

   logic signed [width + guard_bits + 1:0] xr[iterations], yr[iterations];
   logic signed [width + guard_bits - 1:0] zr[iterations];

   genvar i;
   generate
      for (i = -1; i < iterations - 1; ++i)
        if (i == -1)
          always_ff @(posedge clk or posedge reset)
            if (reset)
              begin
                 xr[0] <= '0;
                 yr[0] <= '0;
                 zr[0] <= '0;
              end
            else

	      /*
	       * Input scaling and
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
          always_ff @(posedge clk or posedge reset)
            if (reset)
              begin
                 xr[i + 1] <= '0;
                 yr[i + 1] <= '0;
                 zr[i + 1] <= '0;
              end
            else
              if (vectoring == 1)

                /* Vectoring Mode */
                if (yr[i] >= 0)
                  begin
                     xr[i + 1] <= xr[i] + rounded_shift(yr[i], i);
                     yr[i + 1] <= yr[i] - rounded_shift(xr[i], i);
                     zr[i + 1] <= zr[i] + atan_z[i];
                  end
                else
                  begin
                     xr[i + 1] <= xr[i] - rounded_shift(yr[i], i);
                     yr[i + 1] <= yr[i] + rounded_shift(xr[i], i);
                     zr[i + 1] <= zr[i] - atan_z[i];
                  end
              else

                /* Rotating Mode */
                if (zr[i] < 0)
                  begin
                     xr[i + 1] <= xr[i] + rounded_shift(yr[i], i);
                     yr[i + 1] <= yr[i] - rounded_shift(xr[i], i);
                     zr[i + 1] <= zr[i] + atan_z[i];
                  end
                else
                  begin
                     xr[i + 1] <= xr[i] - rounded_shift(yr[i], i);
                     yr[i + 1] <= yr[i] + rounded_shift(xr[i], i);
                     zr[i + 1] <= zr[i] - atan_z[i];
                  end
   endgenerate

   /* output register */
   always_ff @(posedge clk or posedge reset)
     if (reset)
       begin
          x <= '0;
          y <= '0;
          z <= '0;
       end
     else
       begin
          x <= round_to_width(xr[iterations - 1]);
          y <= round_to_width(yr[iterations - 1]);
          z <= round_to_width_z(zr[iterations - 1]);
       end

   function signed [width:0] round_to_width(input signed [width + guard_bits + 1:0] x);
      return (x + 2**(guard_bits - 1)) >>> guard_bits;
   endfunction

   function signed [width - 1:0] round_to_width_z(input signed [width + guard_bits - 1:0] x);
      return (x + 2**(guard_bits - 1)) >>> guard_bits;
   endfunction

   function signed [width + guard_bits + 1:0] rounded_shift(input signed [width + guard_bits + 1:0] x, input int i);
      return (x + 2**(i - 1)) >>> i;
   endfunction
endmodule

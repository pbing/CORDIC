/* Pipelined CORDIC, polar coordinates, rotation mode
 *
 * π/2    := 2**(width - 2)
 * π      := 2**(width - 1)
 * atan() := 2**(with + iterations - 1) / π * atan(2**(-i))
 */

module cordic
  #(width      = 16,
    iterations = width + 1)
   (input  wire                       reset,      // reset
    input  wire                       clk,        // clock
    input  wire  signed [width - 1:0] x0, y0, z0, // inputs
    output logic signed [width - 1:0] x, y, z);   // outputs

   localparam guard_bits  = $clog2(iterations);

`include "atan_z_17.svh" // change this according to number of iterations

   logic signed [width + guard_bits - 1:0] xr[iterations], yr[iterations];
   logic signed [width + guard_bits - 3:0] zr[iterations];

   /*
    * [0   ,  π/2) = 00...
    * [π/2 ,  π  ) = 01...
    * [0   , -π/2) = 11...
    * [-π/2, -π  ) = 10...
    */
   logic [1:0] quadrant[iterations];

   always_ff @(posedge clk or posedge reset)
     if (reset)
       begin
          x <= '0;
          y <= '0;
          z <= '0;
       end
     else
       begin
          case (quadrant[iterations - 1])
            2'b00:
              begin
                 x <=  round_to_width(xr[iterations - 1]);
                 y <=  round_to_width(yr[iterations - 1]);
              end

            2'b01:
              begin
                 x <= -round_to_width(yr[iterations - 1]);
                 y <=  round_to_width(xr[iterations - 1]);
              end

            2'b10:
              begin
                 x <= -round_to_width(xr[iterations - 1]);
                 y <= -round_to_width(yr[iterations - 1]);
              end

            2'b11:
              begin
                 x <=  round_to_width(yr[iterations - 1]);
                 y <= -round_to_width(xr[iterations - 1]);
              end

          endcase

          z <= round_to_width(zr[iterations - 1] << 2);
       end

   genvar i;
   generate
      for (i = -1; i < iterations - 1; ++i)
        if (i == -1)
          always_ff @(posedge clk or posedge reset)
            if (reset)
              begin
                 xr[0]       <= '0;
                 yr[0]       <= '0;
                 zr[0]       <= '0;
                 quadrant[0] <='0;
              end
            else
              begin
                 xr[0]       <= x0                  << guard_bits;
                 yr[0]       <= y0                  << guard_bits;
                 zr[0]       <= z0[$left(z0) - 2:0] << (guard_bits - 2);
                 quadrant[0] <= z0[$left(z0)-:2];
              end
        else
          always_ff @(posedge clk or posedge reset)
            if (reset)
              begin
                 xr[i + 1]       <= '0;
                 yr[i + 1]       <= '0;
                 zr[i + 1]       <= '0;
                 quadrant[i + 1] <= '0;
              end
            else
              if (zr[i] < 0)
                begin
                   xr[i + 1]       <= xr[i] + rounded_shift(yr[i], i);
                   yr[i + 1]       <= yr[i] - rounded_shift(xr[i], i);
                   zr[i + 1]       <= zr[i] + atan_z[i];
                   quadrant[i + 1] <= quadrant[i];
                end
              else
                begin
                   xr[i + 1]       <= xr[i] - rounded_shift(yr[i], i);
                   yr[i + 1]       <= yr[i] + rounded_shift(xr[i], i);
                   zr[i + 1]       <= zr[i] - atan_z[i];
                   quadrant[i + 1] <= quadrant[i];
                end
   endgenerate

   function signed [width - 1:0] round_to_width(input signed [width + guard_bits - 1:0] x);
      return (x + 2**(guard_bits - 1)) >>> guard_bits;
   endfunction

   function signed [width + guard_bits - 1:0] rounded_shift(input signed [width + guard_bits - 1:0] x, input int i);
      return (x + 2**(i - 1)) >>> i;
   endfunction
endmodule

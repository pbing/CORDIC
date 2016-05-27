/* Compare CORDIC implementation width ideal model. */

module top;
   localparam width = 16;

   const int iterations = width + 2; // width + 4 for no visible spectral lines

   const bit signed [width - 1:0] dz = 1;

   /* inputs */
   bit signed [width - 1:0] x0, y0, z0;

   /* reference */
   bit signed [width    :0] x_ref, y_ref;
   bit signed [width - 1:0] z_ref;

   /* implementation */
   bit signed [width    :0] x, y;
   bit signed [width - 1:0] z;

   initial
     begin:main
        int ch_ref, ch_imp; // output channels


        ch_ref = $fopen("ref.csv");
        ch_imp = $fopen("imp.csv");

        $fdisplay(ch_ref, "xr, yr, zr, x, y, z");
        $fdisplay(ch_imp, "xr, yr, zr, x, y, z");

        x0 = 2**(width - 1) - 1;
        y0 = 0;
        z0 = -2**(width - 1);

        repeat (2**(width) / dz)
          begin
             cordic_ref(x0, y0, z0);

             $fdisplay(ch_ref, "%f, %f, %f, %d, %d, %d",
                       cordic_ref.xr, cordic_ref.yr, cordic_ref.zr,
                       x_ref, y_ref, z_ref);

             cordic_imp(x0, y0, z0);

             $fdisplay(ch_imp, "%f, %f, %f, %d, %d, %d",
                       cordic_imp.xr, cordic_imp.yr, cordic_imp.zr,
                       x, y, z);

             z0 += dz;
          end

        $fclose(ch_imp);
        $fclose(ch_ref);

        $finish;
     end:main

   /* reference */
   function void cordic_ref(input bit signed [width - 1:0] x0, y0, z0);
      const real pi = 4.0 * $atan(1.0);

      real A, phi, xr, yr, zr;

      /* gain */
      A = 1.0;
      for (int i = 0; i < iterations; ++i)
        A *= $sqrt(1.0 + 2.0**(-2*i));

      phi = z0 * pi * 2.0**-(width - 1);
      xr  = A * x0 * $cos(phi);
      yr  = A * x0 * $sin(phi);
      zr  = 0.0;

      x_ref = xr;
      y_ref = yr;
      z_ref = zr;
   endfunction

   /* implementation */
   function void cordic_imp(input bit signed [width - 1:0] x0, y0, z0);
      const bit signed [width - 1:0] pi_2 = 2**(width - 2); // π/2

      real xr, yr, zr;

      /*
       * Input scaling and
       * map argument -π...π to -π/2...π/2.
       */
      if (z0[$left(z0)-:2] == 2'b10) // z0 <= -π/2
        begin
           xr = y0;
           yr = -x0;
           zr = (z0 + pi_2);
        end
      else if (z0[$left(z0)-:2] == 2'b01) // z0 >= π/2
        begin
           xr = -y0;
           yr = x0;
           zr = (z0 - pi_2);
        end
      else
        begin
           xr = x0;
           yr = y0;
           zr = z0;
        end

      for (int i = 0; i < iterations; ++i)
        begin
           const real z_scale = 2.0**(width - 3) / $atan(1.0); // π = 2**(width - 1)

           real xt, yt, pow2;

           pow2 = 2.0**(-i);

           if (zr < 0.0)
             begin
                xt = xr + yr * pow2;
                yt = yr - xr * pow2;

                xr = xt;
                yr = yt;
                zr = zr + z_scale * $atan(pow2);
             end
           else
             begin
                xt = xr - yr * pow2;
                yt = yr + xr * pow2;

                xr = xt;
                yr = yt;
                zr = zr - z_scale * $atan(pow2);
             end
        end

      x = xr;
      y = yr;
      z = zr;
   endfunction
endmodule

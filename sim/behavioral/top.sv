/* Compare CORDIC implemtation width ideal model. */

module top;
   localparam width = 16;

   const int iterations = width + 2;

   const bit signed [width - 1:0] dz = 1;

   bit signed [width - 1:0] x0, y0, z0, z;
   bit signed [width    :0] x, y, xx, yy;

   initial
     begin:main
        int ch_cos_sin, ch_error; // output channels


        ch_cos_sin = $fopen("cos_sin.csv");
        ch_error   = $fopen("error.csv");

        $fdisplay(ch_cos_sin, "x, y, z");
        $fdisplay(ch_error,   "x, y, z");

        x0 = 2**(width - 1) - 1;
        y0 = 0;
        z0 = -2**(width - 1);

        repeat (2**(width) / dz)
          begin
             cordic_ideal(x0, y0, z0);
             cordic      (x0, y0, z0);

             //$display("z0 = %d, x = %d (%d), y = %d (%d), z = %d", z0, x, xx, y, yy, z);
             //$fdisplay(ch_cos_sin, "%f, %f, %f", cordic.xr, cordic.yr, cordic.zr);
             $fdisplay(ch_cos_sin, "%8d, %8d, %8d", x, y, z);
             $fdisplay(ch_error,   "%8d, %8d, %8d", x - xx, y - yy, z);
             
             z0 += dz;
          end

        $fclose(ch_cos_sin);
        $fclose(ch_error);

        $finish;
     end:main

   function void cordic_ideal(input bit signed [width - 1:0] x0, y0, z0);
      const real pi = 4.0 * $atan(1.0);

      real A;
      real phi;

      /* gain */
      A = 1.0;
      for (int i = 0; i < iterations; ++i)
        A *= $sqrt(1.0 + 2.0**(-2*i));

      phi = z0 * pi * 2.0**-(width - 1);
      xx  = A * x0 * $cos(phi);
      yy  = A * x0 * $sin(phi);           
   endfunction



   function void cordic(input bit signed [width - 1:0] x0, y0, z0);
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

# coding=utf-8
# CORDIC in polar coordinates (rotating, vectoring)

from math import sqrt, pi, cos, sin, atan, copysign

def cordic (x0, y0, z0, vectoring = False, iterations = 10):
    A = 1.0

    # Input scaling and
    # map argument -π...π to -π/2...π/2.
    #
    # Replace <width> bit wide comparision operators
    # with 2 bit comparision due to
    # [0   ,  π/2) = 00...
    # [π/2 ,  π  ) = 01...
    # [0   , -π/2) = 11...
    # [-π/2, -π  ) = 10...
    if vectoring:
        if x0 < 0 and y0 > 0:
            x, y, z = y0, -x0, z0 + pi/2
        elif x0 < 0 and y0 < 0:
            x, y, z  = -y0, x0, z0 - pi/2
        else:
            x, y, z  = x0, y0, z0
    else:
        if z0 < -pi/2:
            x, y, z  = y0, -x0, z0 + pi/2
        elif z0 > pi/2:
            x, y, z  = -y0, x0, z0 - pi/2
        else:
            x, y, z  = x0, y0, z0

    for i in xrange(iterations):
        A = A * sqrt(1 + 2**(-2 * i))
        pow2 = 2**(-i)

        if vectoring:
            d = -copysign(1, y)
        else:
            d = copysign(1, z)

        x, y, z = x - y * d * pow2, y + x * d * pow2, z - d * atan(pow2)

    return x, y, z, A


if __name__ == "__main__":

    bits = 16
    iterations = bits + 2
    N = bits


    # print format like ../cos_sim/cos_sin/top.sv
    print "xr, yr, zr, x, y, z"

    for i in xrange(2**N):
	x0 = 2**(bits - 1) - 1
	y0 = 0
	z0 = ((i - 2**(N - 1)) * pi / 2**(N - 1))

	x, y, z, A = cordic(x0, y0, z0, False, iterations)

        z = 2**(bits - 1) / pi * z

        # ideal response
        # x, y, z = A * x0 * cos(z0), A * x0 * sin(z0), 0
        
        # error plot
	# x, y = x - A * x0 * cos(z0), y - A * x0 * sin(z0)

	print "%f, %f, %f, %d, %d, %d" % (x, y, z, round(x), round(y), round(z))

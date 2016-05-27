# Calculate ENOB

# reference
ref  <- read.csv('../behavioral/ref.csv')
N <- length(ref$x)
A <- max(abs(ref$x))

# implementation
imp <- read.csv('imp.csv')

delta <- imp - ref
# plot(delta$xr, type='l')
# plot(delta$yr, type='l')
# plot(delta$zr, type='l')

# FFT
# f.x <- fft(ref$xr)
# f.y <- fft(ref$yr)

# f.x <- fft(ref$x)
# f.y <- fft(ref$x)

# f.x <- fft(imp$xr)
# f.y <- fft(imp$yr)

f.x <- fft(imp$x)
f.y <- fft(imp$y)

pwr.dB <- 10 * log((abs(f.x[1:(N/2+1)])^2 + abs(f.y[1:(N/2+1)])^2)/(as.double(N) * as.double(A))^2, 10)
pwr.dB <- pmax(pwr.dB, -200)

# signal + noise + distorsion
ss.x <- sum(abs(f.x)^2) / N
ss.y <- sum(abs(f.y)^2) / N

# distorsion
# [1]      : D.C.
# [2]      : signal
# [3:N - 1]: noise
# [N]      : signal
dd.x <- (abs(f.x[1])^2 + sum(abs(f.x[3:(N - 1)])^2)) / N
dd.y <- (abs(f.y[1])^2 + sum(abs(f.y[3:(N - 1)])^2)) / N

# SINAD
sinad <- 10 * log((ss.x + ss.y) / (dd.x + dd.y), 10)

# ENOB
enob <- (sinad - 1.76) / 6.02
enob

plot(delta$xr, type='l')
readline("Press key to continue...")
plot(delta$yr, type='l')
readline("Press key to continue....")
plot(delta$zr, type='l')
readline("Press key to continue....")
plot(pwr.dB, type='l')

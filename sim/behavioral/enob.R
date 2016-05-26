# Calculate ENOB

data <- read.csv('cos_sin.csv')
N <- length(data$x)
A <- max(abs(data$x))

# # ideal 16-bit DAC
# i <- seq(0, N - 1)
# A <- (2^(16 - 1) - 1)
# data$x <- round(A * cos(2 * pi * i / N))
# data$y <- round(A * sin(2 * pi * i / N))

# FFT
f.x <- fft(data$x)
f.y <- fft(data$y)

pwr.dB <- 10 * log((abs(f.x[1:(N/2+1)])^2 + abs(f.y[1:(N/2+1)])^2)/(as.double(N) * as.double(A))^2, 10)
# plot(pmax(pwr.dB, -100), type='l')

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

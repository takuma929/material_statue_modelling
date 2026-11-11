Put the nine stimulus files here:

    BC.mat  BR.mat  BS.mat
    HC.mat  HR.mat  HS.mat
    PC.mat  PR.mat  PS.mat

The file name is the condition: statue (B, H, P) followed by material (C, R, S).
Each file holds one variable, `img`: a 1 x 61 cell array of 1024 x 1024 x 3
images (double, sRGB-encoded, between 0 and 1), one per rendered frame.
The stimulus files are not distributed with the code.

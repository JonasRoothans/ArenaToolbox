function [out] = A_lps2ras(in)
%LPS2RAS Summary of this function goes here
%   Detailed explanation goes here
if isvector(in)
    out = in;
    out(1:2) = -1*out(1:2);
else
    out = in;
    out(:,[1,2]) = out(:,[1,2])*-1;
end


function [out] = A_lps2ras(in)
%A_LPS2RAS inverts X and Y
if isvector(in)
    out = in;
    out(1:2) = -1*out(1:2);
else
    out = in;
    out(:,[1,2]) = out(:,[1,2])*-1;
end


function [modified,T] = A_rigidT(T)
%A_RIGIDT Summary of this function goes here
%   Detailed explanation goes here
if and(sum(abs(T(4,1:3)))<0.1,...
        sum(abs(T(1:3,4)))>0.1)
    T = T';
end

T_original = T;

scalingX = Vector3D(T(1,1:3)).norm;
scalingY = Vector3D(T(2,1:3)).norm;
scalingZ = Vector3D(T(3,1:3)).norm;

T(1,1:3) = T(1,1:3)/scalingX;
T(2,1:3) = T(2,1:3)/scalingY;
T(3,1:3) = T(3,1:3)/scalingZ;


if any(not(T_original==T))
    modified = 1;
else
    modified =  0;
end
    


end


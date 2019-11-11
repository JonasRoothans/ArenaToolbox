function [ xq,yq,zq ] = A_imref2meshgrid( imref )
%IMREF2MESHGRID Summary of this function goes here
%   Detailed explanation goes here

%Meshgrid for full range
x = imref.XWorldLimits(1):imref.PixelExtentInWorldX:imref.XWorldLimits(2);
y = imref.YWorldLimits(1):imref.PixelExtentInWorldY:imref.YWorldLimits(2);
z = imref.ZWorldLimits(1):imref.PixelExtentInWorldZ:imref.ZWorldLimits(2);

%But the center of the pixel should be sampled. So Shift everything 0.5
%pixel.
x = x(1:end-1)+imref.PixelExtentInWorldX/2;
y = y(1:end-1)+imref.PixelExtentInWorldY/2;
z = z(1:end-1)+imref.PixelExtentInWorldZ/2;

%Make meshgrid
[xq,yq,zq] = meshgrid(x,y,z);


end


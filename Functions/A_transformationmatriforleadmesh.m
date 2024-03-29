function [T] = A_transformationmatriforleadmesh(location,zdirection, roll)
%A_TRANSFORMATIONMATRIFORLEADMESH Trasformation from leadspace to world.
zdirection = zdirection.unit.getArray()';
if nargin<3
    roll=0;
end
xdirection = cross([sin(deg2rad(roll)), cos(deg2rad(roll)), 0],zdirection);
% xdirection = cross([0 1 0],zdirection);

ydirection = cross(zdirection,xdirection);
T = [xdirection/norm(xdirection);ydirection/norm(ydirection);zdirection/norm(zdirection);location.getArray()'];
T(4,4) = 1;
[modified,T] = A_rigidT(T);



end


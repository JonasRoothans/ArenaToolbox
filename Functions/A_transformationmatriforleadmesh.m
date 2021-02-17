function [T] = A_transformationmatriforleadmesh(location,zdirection)
%A_TRANSFORMATIONMATRIFORLEADMESH Trasformation from leadspace to world.
zdirection = zdirection.unit.getArray()';
xdirection = cross([0 1 0],zdirection);
ydirection = cross(zdirection,xdirection);
T = [xdirection;ydirection;zdirection;location.getArray()'];
T(4,4) = 1;
[modified,T] = A_rigidT(T);



end


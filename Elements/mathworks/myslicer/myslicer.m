function h = myslicer(vol,T);

if nargin < 2
  T = eye(4);
end



h1 = slice3i(vol,T,1,round(size(vol,1)/2));
h2 = slice3i(vol,T,2,round(size(vol,2)/2));
h3 = slice3i(vol,T,3,round(size(vol,3)/2));

h = [h1,h2,h3];

view(30,45);
axis equal;
axis vis3d;



 
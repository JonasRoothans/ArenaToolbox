function [B, x, y, z] = A_obliquesliceParallelToElectrode(VD, e, normal)
    % convert e to point and pol
    point = e.C0;
    pol = e.getPOL;
    normalpoint = point+normal*10;
 
   
    % Convert the 3D point to subscript indices
%     subscript = pointToIntrinsic(VD, point);
%     subscriptPOL = pointToIntrinsic(VD, pol);
%     subscriptnormalpoint = pointToIntrinsic(VD,normalpoint);
%     
%     normal = Vector3D(subscriptnormalpoint - subscript).unit();

subscript = point.getArray;


    
    %set margin
    margin = 100;

    % Generate a grid of coordinates for the output slice
    [x, y] = meshgrid(subscript(1I'm)-margin/2:subscript(1)+margin/2,...
        subscript(2)-margin/2:subscript(2)+margin/2);

    % Calculate the z-coordinate of the output slice
    z = (subscript(3)) * ones(size(x));

    % Compute the distance of each voxel to the plane
    distances = (x - subscript(1)) * normal.x + (y - subscript(2)) * normal.y + (z - subscript(3)) * normal.z;

    % Interpolate the slice values from the input volume
    B = interp3(VD.Voxels, x, y, z + distances, 'linear', 0);
end
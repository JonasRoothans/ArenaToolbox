classdef CroppedVoxelData < VoxelData
    %CROPPEDVOXELDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
        LeftDown
        RightUp
        T %to parent
    end
    
    methods
        function obj = CroppedVoxelData(Voxels,R,leftdown,rightup,parent)
            obj.Voxels = Voxels;
            obj.R = R;
            obj.LeftDown = leftdown;
            obj.RightUp = rightup;
            obj.parent = parent;
            obj.T = eye(4);
            %CROPPEDVOXELDATA Construct an instance of this class
            %   Detailed explanation goes here
           
        end
        
        function obj = imwarp(obj,T)
            obj.T = T;
            obj = imwarp@VoxelData(obj,T);
        end
        
        
    end
end


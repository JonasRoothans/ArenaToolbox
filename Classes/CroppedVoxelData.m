classdef CroppedVoxelData < VoxelData
    %CROPPEDVOXELDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
        LeftDown
        RightUp
    end
    
    methods
        function obj = CroppedVoxelData(Voxels,R,leftdown,rightup,parent)
            obj.Voxels = Voxels;
            obj.R = R;
            obj.LeftDown = leftdown;
            obj.RightUp = rightup;
            obj.parent = parent;
            %CROPPEDVOXELDATA Construct an instance of this class
            %   Detailed explanation goes here
           
        end
        
        
    end
end


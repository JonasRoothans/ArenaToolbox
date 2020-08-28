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
            
            out = imwarp@VoxelData(obj,T);
            obj.T = T;
            obj.Voxels = out.Voxels;
            obj.R = out.R;
            
        end
        
        function obj = padcropped(obj,type)
                switch lower(type)
                    case 'surface'
                        %nothing.
                    case 'light'
                        obj.R.XWorldLimits = [obj.R.XWorldLimits] + [-1 1]*obj.R.PixelExtentInWorldX;
                        obj.R.ImageSize = obj.R.ImageSize + [2 2 2]; 
                        
                        v =obj.Voxels;
                        obj.Voxels = ones(size(v)+[2 2 2])*(min(v(:))-1);
                        obj.Voxels(2:end-1,2:end-1,2:end-1) =  v;
                        
                    case 'dark'
                        obj.R.XWorldLimits = [obj.R.XWorldLimits] + [-1 1]*obj.R.PixelExtentInWorldX;
                        obj.R.ImageSize = obj.R.ImageSize + [2 2 2]; 
                        
                        v =obj.Voxels;
                        obj.Voxels = ones(size(v)+[2 2 2])*(max(v(:))+1);
                        obj.Voxels(2:end-1,2:end-1,2:end-1) =  v;
                end
        end
        
    end
end


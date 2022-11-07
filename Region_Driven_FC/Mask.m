classdef Mask<handle
    %this is a single mask of a cortical segmentation
    %   Detailed explanation goes here

    properties
        Segmentation VoxelData
        Voxels logical
        Area (1,1) 
        Tag string

    end

    methods
        function obj = Mask(segmentation,area,Tag)
          
            obj.Segmentation = VoxelData(segmentation);
            obj.Voxels = obj.Segmentation.Voxels == area;
            obj.Area = area;

            if nargin>2

                obj.Tag = Tag ;
            end




        end

        function obj = warpto(obj,target,T)
            
            obj.Segmentation = obj.Segmentation.warpto(target,T);
            obj.Voxels = obj.Segmentation.Voxels == area;

           
           
        end

        function obj = serialize(obj)

             obj.Voxels = obj.Voxels(:);

        end
    end
end
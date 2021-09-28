classdef Heatmap < handle
    
    properties
        Tmap
        Pmap
        Signedpmap
        Amap
        Cmap
        Rmap
        Fzmap
        Raw
        Description
        VoxelDataStack
    end
    
    methods
        function obj = Heatmap()

        end
        
        
        function fz = makeFzMap(obj)
            if not(isempty(obj.Fzmap))
                fz = obj.Fzmap;
                return
            end
            if isempty(obj.Rmap)
                error('requires an rmap')
            end
            
            fzVoxels = atanh(obj.Rmap.Voxels);
            obj.Fzmap = VoxelData(fzVoxels,obj.Rmap.R);
        end
      
        
    end
    
    
    
end


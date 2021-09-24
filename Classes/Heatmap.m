classdef Heatmap < handle
    
    properties
        tmap
        pmap
        signedpmap
        amap
        cmap
        rmap
        fzmap
        raw
        description
    end
    
    methods
        function obj = Heatmap()

        end
        
        
        function fz = makeFzMap(obj)
            if not(isempty(obj.fzmap))
                fz = obj.fzmap;
                return
            end
            if isempty(obj.rmap)
                error('requires an rmap')
            end
            
            fzVoxels = atanh(obj.rmap.Voxels);
            obj.fzmap = VoxelData(fzVoxels,obj.rmap.R);
        end
      
        
    end
    
    
    
end


classdef Heatmap < handle 
    
    properties
        Tag
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
        
        function newObj = copy(obj)
            newObj = Heatmap();
            props = properties(obj);
            for iProp = 1:numel(props)
                if isempty(obj.(props{iProp}))
                    newObj.(props{iProp}) = [];
                else
                    if isa(obj.(props{iProp}),'handle')
                        try
                        newObj.(props{iProp}) = copy(obj.(props{iProp}));
                        catch
                            keyboard
                        end
                    else
                        
                        newObj.(props{iProp}) = obj.(props{iProp});
                    end
                end
            end
          
        end
        
        function save(obj,filename, memory)
            %voxelstack is not saved by default as it is very big.
            %thisHeatmap.save('filename.heatmap','memory') will save
            %memory.
            save_memory = 0;
            if nargin==3
                if strcmp(memory,'memory')
                    save_memory = 1;
                end
            end
            
            if nargin==1
                if not(isempty(obj.Tag))
                    [fname,pname] = uiputfile([obj.Tag,'.heatmap']);
                else
                    [fname,pname] = uiputfile('*.heatmap');
                end
                filename = fullfile(pname,fname);
            end
                
            %make a new version without the VoxelDataStack to save memory.
            hm = copy(obj);
            hm.VoxelDataStack = [];
            
            
             %write heatmap
            [folder,file,~] = fileparts(filename);
            out.hm = hm;
            save(fullfile(folder,[file,'.heatmap']),'-struct','out');
            
            %write memory
            if save_memory
                vds  = obj.VoxelDataStack;
                save(fullfile(folder,['memory_',file,'.mat']),vds)
            end
            
            Done;
        end
      
        
    end
    
    
    
end


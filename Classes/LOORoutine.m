classdef LOORoutine < handle
    
    properties
        HeatmapFolder
        MemoryFile
        LOOmdl
    end
    
    properties (Hidden)
        CleanHistograms
        LoadedMemory
    end
    
    
    
    methods
        function LOOroutine()
        end
        
        function setHeatmapFolder(obj)
            obj.HeatmapFolder = uigetdir();
        end
        
        function setMemoryFile(obj)
             [filename,foldername] = uigetfile('*.heatmap');
             obj.MemoryFile = fullfile(foldername,filename);
        end
        
        
        
        function clearMemory(obj)
            obj.LoadedMemory = [];
        end
        
        function LOOregression(obj)
            obj.loadMemory() % this is slow, so will only do it once.
            
            filenames = obj.LoadedMemory.LayerLabels;
            f = figure;
            for iFilename = 1:length(filenames)
                    
                thisFilename = filenames{iFilename};
                [folder,file,extension] = fileparts(thisFilename);
                disp(file)
                
                
                %load LOO set.
                LOO_heatmap = load(fullfile(obj.HeatmapFolder,[file,'.heatmap']),'-mat');
                LOO_signedP = LOO_heatmap.signedpmap;
                LOO_tmap = LOO_heatmap.tmap;
                LOO_VTA = obj.LoadedMemory.getVoxelDataAtPosition(iFilename);
                
                %take a bite
                sample = LOO_signedP.Voxels(and(LOO_VTA.Voxels>0.5,LOO_tmap~=0));
                
                %analyse bite
                edges = -1:0.13333333333:1; % define the bins
                h = histogram(sample,edges);
                obj.CleanHistograms(iFilename,1:numel(edges)-1) = zscore(h.Values); 
                delete(h)
                
            end
            close(f)
            
            obj.LOOmdl = fitlm(obj.CleanHistograms,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            figure;obj.LOOMdl.plot
        end
        
        function LOOCV(obj)
            if isempty(obj.CleanHistograms)
                error('Run .LOOregression() first!')
            end
            
            
        end
        
 
    end
    
    methods(Hidden)
        function loadMemory(obj)
            if isempty(obj.LoadedMemory)
                Stack = load(obj.MemoryFile,'-mat');
                obj.LoadedMemory = Stack.memory;
            end
        end
    end
end

classdef LOORoutine < handle
    
    properties
        HeatmapFolder
        MemoryFile
        LOOmdl
        LOOCVmdl
    end
    
    properties (Hidden)
        CleanHistograms
        LoadedMemory
        LOOCVpredictions
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
            figure;obj.LOOmdl.plot
        end
        
        function LOOCV(obj)
            if isempty(obj.CleanHistograms)
                error('Run .LOOregression() first!')
            end
            
            
            for i = 1:numel(obj.LoadedMemory.Weights)
                %getsubsets
                subX = obj.CleanHistograms;
                subX(i,:) = [];
                subY = obj.LoadedMemory.Weights;
                subY(i) = [];
                
                %train
                X = [ones(size(subX,1),1),subX];
                [b] = regress(subY',X);
                
                
                %predict
                LOO_x = [1,obj.CleanHistograms(i,:)];
                Prediction = LOO_x*b;
                
                %save
                obj.LOOCVpredictions(i) = Prediction;
                
            end
            %evaluate prediction
            obj.LOOCVmdl = fitlm(obj.LOOCVpredictions,obj.LoadedMemory.Weights);
            obj.LOOCVmdl
            figure; obj.LOOCVmdl.plot
            
            
            
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

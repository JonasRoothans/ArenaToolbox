classdef LOORoutine < handle
    
    properties
        HeatmapFolder
        MemoryFile
        LOOmdl
    end
    
    properties (Hidden)
        CleanPredictors
        LoadedMemory
        SamplingMethod = 'Histogram' %or Average
        NumberOfBins = 15;
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
                %--with value 1
                sample = LOO_signedP.Voxels(and(LOO_VTA.Voxels>=1,LOO_tmap~=0));
                %-- with value 2
                %sample = [sample;LOO_signedP.Voxels(and(LOO_VTA.Voxels>=2,LOO_tmap~=0))];
                
                
                %analyse bite
                switch obj.SamplingMethod
                    case 'Histogram'
                        edges = linspace(-1,1,obj.NumberOfBins+1);
                        h = histogram(sample,edges);
                        obj.CleanPredictors(iFilename,1:numel(edges)-1) = zscore(h.Values); 
                        delete(h)
                    case 'Average'
                        obj.CleanPredictors(iFilename,1) = mean(sample);
                    otherwise
                       error('No valid method') 
                       
                end
                
                
            end
            close(f)
            
            obj.LOOmdl = fitlm(obj.CleanPredictors,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            figure;obj.LOOmdl.plot
        end
        
        function LOOCV(obj)
            if isempty(obj.CleanPredictors)
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

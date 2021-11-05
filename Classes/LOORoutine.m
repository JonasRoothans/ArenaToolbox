classdef LOORoutine < handle
    
    properties
        Heatmap
        Memory
        LOOmdl
        LOOCVmdl
    end
    
    properties (Hidden)
        SamplingMethod = @A_15bins
        MemoryFile
        HeatmapFolder
        CleanPredictors
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
        
        function saveTraining(obj,path)
            [~ ,filename] = fileparts(obj.LoadedMemory.RecipePath);
            mdl = obj.LOOmdl;
            save(fullfile(path,['training_',filename,'.mat']),'mdl');
        end
        
        function LOOmdl = LOOregression(obj)
            obj.loadMemory() % this is slow, so will only do it once.
            
            filenames = obj.LoadedMemory.LayerLabels;
            f = figure;
            for iFilename = 1:length(filenames)
                
                thisFilename = filenames{iFilename};
                [folder,file,extension] = fileparts(thisFilename);
                disp(file)
                
                
                %load LOO set.
                LOO_heatmap = obj.loadHeatmap(file,iFilename);
                
                LOO_signedP = LOO_heatmap.Signedpmap;
                LOO_tmap = LOO_heatmap.Tmap;
                LOO_VTA = obj.LoadedMemory.getVoxelDataAtPosition(iFilename);
                
                %take a bite
                sample = LOO_signedP.Voxels(and(LOO_VTA.Voxels>0.5,LOO_tmap~=0));
                
                %analyse bite
                
                predictors = feval(obj.SamplingMethod,sample);
                
                obj.CleanPredictors(iFilename,1:length(predictors)) = predictors;
       
                
            end
            close(f)
            
            obj.LOOmdl = fitlm(obj.CleanPredictors,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            LOOmdl = obj.LOOmdl;
        end
        
        function LOOCV(obj)
            if isempty(obj.CleanPredictors)
                error('Run .LOOregression() first!')
            end
            
            
            for i = 1:numel(obj.LoadedMemory.Weights)
                %getsubsets
                subX = obj.CleanPredictors;
                subX(i,:) = [];
                subY = obj.LoadedMemory.Weights;
                subY(i) = [];
                
                %train
                X = [ones(size(subX,1),1),subX];
                [b] = regress(subY',X);
                
                
                %predict
                LOO_x = [1,obj.CleanPredictors(i,:)];
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
                if not(isempty(obj.Memory))
                    switch class(obj.Memory)
                        case 'char'
                            Stack = load(obj.MemoryFile,'-mat');
                            obj.LoadedMemory = Stack.memory;
                        case 'VoxelDataStack'
                            obj.LoadedMemory = obj.Memory;
                    end
                    
                else 
                    msgbox('Please provide memory before running the routine','error','error')
                    error('Please provide memory before running the routine');
                end
            end
        end
        
        function LOO_heatmap = loadHeatmap(obj,file,i)
            if not(isempty(obj.Heatmap))
                switch class(obj.Heatmap)
                    case 'char'
                        LOO_heatmap = load(fullfile(obj.Heatmap,[file,'.heatmap']),'-mat');
                    case 'struct'
                        LOO_heatmap.Signedpmap = obj.Heatmap.Signedpmap.getVoxelDataAtPosition(i);
                        LOO_heatmap.Tmap = obj.Heatmap.Tmap.getVoxelDataAtPosition(i);
                end
            else
                msgbox('Please provide Heatmap folder or stack','error','error')
                error('Please provide Heatmap folder or stack')
            end
        end
    end
end

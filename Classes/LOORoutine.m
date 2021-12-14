classdef LOORoutine < handle
    
    properties
        SamplingMethod
        VDS %can be VoxelDataStack OR path to this file
        LOOmdl
        LOOCVmdl
    end
    
    properties (Hidden)
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
            
            
            %get required info from samplingMethod
            samplingMethod = feval(obj.SamplingMethod);
            requiredMaps = samplingMethod.RequiredHeatmaps;
            
            %print info
            home;
            disp('---------------------------------')
            disp(['Leave one out regression method: ', func2str(obj.SamplingMethod)])
            disp(['Leave one out heatmap iterations: ',num2str(length(obj.LoadedMemory.LayerLabels))])
            for line = 1:length(samplingMethod.Description)
                disp(['   ',samplingMethod.Description(line)])
            end
            disp(' ')
            disp('Training begins. This will take a while. Time for coffee.')
            
            
            filenames = obj.LoadedMemory.LayerLabels;
            for iFilename = 1:length(filenames)
                
                %indicate progress
                thisFilename = filenames{iFilename};
                try
                [~,file,~] = fileparts(thisFilename);
                catch
                    file=thisFilename;
                end
                if iscell(file)
                    file = file{1};
                end
                disp([num2str(iFilename),'. ',file])
                
                
                
                %make LOO map
                map = obj.LoadedMemory.convertToLOOHeatmap(iFilename,requiredMaps);
                
                %get ROI
                roi = obj.LoadedMemory.getVoxelDataAtPosition(iFilename);
                
                %Take a bite
                ba = BiteAnalysis(map,roi,obj.SamplingMethod);
                
               %save predictors to object
                obj.CleanPredictors(iFilename,1:length(ba.Predictors)) = ba.Predictors;
       
                
            end
 
            
            obj.LOOmdl = fitlm(obj.CleanPredictors,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            LOOmdl = obj.LOOmdl;
        end
        
        
        
        function LOOCV(obj)
            if isempty(obj.CleanPredictors)
                error('Run .LOOregression() first!')
            end
            
            x = obj.CleanPredictors;
            y = obj.LoadedMemory.Weights;
            
            [obj.LOOCVmdl,obj.LOOCVpredictions] = LOORoutine.quickLOOCV(x,y);
            
            obj.LOOCVmdl
            figure; obj.LOOCVmdl.plot
            
            
            
        end
        
        
    end
    
    methods(Hidden)
        function loadMemory(obj)
            disp('...Loading data into LOO routine.')
            if isempty(obj.LoadedMemory)
                if not(isempty(obj.VDS))
                    switch class(obj.VDS)
                        case 'char'
                            Stack = load(obj.VDS,'-mat');
                            obj.LoadedMemory = Stack.memory;
                        case 'VoxelDataStack'
                            obj.LoadedMemory = obj.VDS;
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
    
    methods (Static)
        function [LOOCVmdl,LOOCVpredictions] = quickLOOCV(predictors,truth)
            LOOCVpredictions = [];
            for i = 1:numel(truth)
                %getsubsets
                subX = predictors;
                subX(i,:) = [];
                subY = truth;
                subY(i) = [];
                
                %train
                if not(subX(1,1)==1)
                    X = [ones(size(subX,1),1),subX];
                    LOO_x = [1,predictors(i,:)];
                else
                    X = subX;
                    LOO_x = predictors(i,:);
                end
                [b] = regress(subY',X);
                
                
                %predict
                Prediction = LOO_x*b;
                
                %save
                LOOCVpredictions(i) = Prediction;
                
            end
            %evaluate prediction
            LOOCVmdl = fitlm(LOOCVpredictions,truth);
            
            
        end
    end
end

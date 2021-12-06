
classdef RegressionRoutine < handle
    
    properties
        SamplingMethod = @A_15bins
        Heatmap
        VoxelDataStack
        Mdl
    end
    
    properties (Hidden)
        Predictors
        LoadedMemory
        LOOCVpredictions
    end
    
    
    
    methods
        function obj = RegressionRoutine(HeatmapData,ImageDataStack,SamplingMethodInput)
            if nargin>0
                obj.Heatmap = HeatmapData;
            end
            if nargin>1
                obj.VoxelDataStack = ImageDataStack;
                %             else
                %                 obj.ImageDataStack=VoxelDataStack;
            end
            if nargin>2
                if isa(a,SamplingMethodInput)
                    obj.SamplingMethod = SamplingMethodInput;
                end
            end
        end
        
        function obj=loadRegressionData(obj)
            
            if isempty(obj.Heatmap)
                waitfor(msgbox('Find a file that serves as a heatmap'))
                obj.Heatmap = Heatmap; %#ok
                obj.Heatmap.loadHeatmap();
            end
            if isempty(obj.VoxelDataStack.Voxels)
                
                answer = questdlg('do you have a recipe file?');
                switch answer
                    case 'Yes'
                        obj.VoxelDataStack.loadStudyDataFromRecipe()
                    case 'No'
                        obj.VoxelDataStack.loadDataFromFolder()
                end
            end
            
        end
        
        
        
        function  obj=execute(obj)
            
            %%
            obj.loadMemory() % this is slow, so will only do it once.
            
            
            %get required info from samplingMethod
            samplingMethod = feval(obj.SamplingMethod);
            requiredMaps = samplingMethod.RequiredHeatmaps;
            
            %print info
            home;
            disp('---------------------------------')
            disp(['Regression method: ', func2str(obj.SamplingMethod)])

            for line = 1:length(samplingMethod.Description)
                disp(['   ',samplingMethod.Description{line}])
            end
            disp(' ')
            disp('Regression begins')
            
            
            %Check if required maps are provided;
            obj.Heatmap.has(requiredMaps); %aborts if invalid
            
            
            for iROI = 1:length(obj.LoadedMemory)
                
                %get ROI
                roi = obj.LoadedMemory.getVoxelDataAtPosition(iROI);

                %Take a bite
                ba = BiteAnalysis(obj.Heatmap,roi,obj.SamplingMethod);

               %save predictors to object
                obj.Predictors(iROI,1:length(ba.Predictors)) = ba.Predictors;

            end
           
 
            
            obj.Mdl = fitlm(obj.Predictors,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            mdl = obj.Mdl;
            assignin('base','mdl',mdl);
            mdl
            
        end
        
        function askForSaving(obj)
            if isempty(obj.Mdl)
                errordlg('This regression routine does not yet contain a model')
                return
            end
        
            answer =questdlg('Do you want to save this as a Prediction Model?','Arena - Heatmapmaker','Of course','Rather not','Of course');
            switch answer
                case 'Of course'
                    obj.saveAsPredictionModel()
            end
            
        end
        
        function saveAsPredictionModel(obj)
            p = PredictionModel;
            p.Heatmap = obj.Heatmap;
            p.SamplingMethod = obj.SamplingMethod;
            p.TrainingLinearModel = obj.Mdl;
            p.B = obj.Mdl.Coefficients.Estimate;
            p.save();
            
        end
            
        
        
        
        
    end
    
    methods(Hidden)
        function loadMemory(obj)
            disp('...Loading data into LOO routine.')
            if isempty(obj.LoadedMemory)
                if not(isempty(obj.VoxelDataStack))
                    switch class(obj.VoxelDataStack)
                        case 'char'
                            Stack = load(obj.VoxelDataStack,'-mat');
                            obj.LoadedMemory = Stack.memory;
                        case 'VoxelDataStack'
                            obj.LoadedMemory = obj.VoxelDataStack;
                    end
                    
                else 
                    msgbox('Please provide memory before running the routine','error','error')
                    error('Please provide memory before running the routine');
                end
            end
        end
    end
        
        
end






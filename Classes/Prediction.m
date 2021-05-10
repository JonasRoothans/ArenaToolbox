classdef Prediction < handle
    %PREDICTIOON Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model
        Input
        Output
        Comments = {};
    end
    
    methods
        function obj = Prediction(Input,Model)
            %PREDICTIOON Construct an instance of this class
            %   Detailed explanation goes here
            obj.Model = Model;
            obj.Input = Input;
        end
        
        function obj = runVTAPrediction(obj)
            [obj.Output,obj.Comments] = obj.Model.predictionForVTAs(obj.Input.VTAs);
        end
        
        function printInfo(obj)
            fprintf('#########\n')
            %--vta's
            n = 0;
            for iVTA  = obj.Input.VTAs
                n = n+1;
                    iVTA.printInfo()
                    fprintf(2,'%s\n',obj.Comments{n})
            end
            %--model
            fprintf('---\nModel used: \t %s \n',obj.Model.Tag)
            fprintf('Therapy name:\t %s\n',obj.Input.Tag);
            %--Prediction
            fprintf('===>> PredictionOutcome: %4.2f \n \n',obj.Output)
            
            
        end
                
        
        
       
        function obj = runMultipleVTAPrediction(obj)
            %several options here:
            % - Input is a list of VTAs
            % - Input is a list of therapys each with one VTA
            % - Input is one therapy, with a long list of VTAs.
     
            warning('This function does not exist yet. -Jonas')
         end
    end
end


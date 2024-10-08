classdef Prediction < handle
    %PREDICTIOON Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model
        Input
        Output
        Confidence
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
            [obj.Output,obj.Confidence,obj.Comments] = obj.Model.predictionForVTAs(obj.Input.VTAs);
        end
        
        function printInfo(obj)
            fprintf('#########\n')
            %--vta's
            n = 0;
            for iVTA  = obj.Input.VTAs
                n = n+1;
                    iVTA.printInfo()
                    try
                        fprintf(2,'%s\n',obj.Comments{n})
                    catch
                        %fine
                    end
            end
            %--model
            fprintf('---\nModel used: \t %s \n',obj.Model.Tag)
            fprintf('Therapy name:\t %s\n',obj.Input.Tag);
            %--Prediction
            fprintf('===>> Prediction Outcome: %4.2f \n',obj.Output)
            fprintf('===>> Prediction Confidence: %4.2f \n \n',obj.Confidence)
            try
            fprintf('===>> Comment: %4.2f \n \n',obj.Comments{1})
            catch
                %currently only works if comment is a number in a cell.
            end
            
            
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


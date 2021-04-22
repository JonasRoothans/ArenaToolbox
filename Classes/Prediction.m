classdef Prediction < handle
    %PREDICTIOON Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model
        Output
        Input
    end
    
    methods
        function obj = Prediction(Input,Model)
            %PREDICTIOON Construct an instance of this class
            %   Detailed explanation goes here
            obj.Model = Model;
            obj.Input = Input;
        end
        
        function obj = runSingleVTAPrediction(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            for iVTA = 1:numel(obj.Input.VTAs)
                thisVTA = obj.Input.VTAs(iVTA);
                obj.Ouptut{iVTA} = obj.Model.sampleWithVTA(thisVTA);
                
            end
            keyboard
        end
        
        function obj = runMultipleVTAPrediction(obj)
             keyboard
         end
    end
end



classdef SamplingMethod
    %BITEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = BiteMethod(inputArg1,inputArg2)
           
        end
        
        function ok = mapIsOk(obj,map)
            for required = 1:length(obj.RequiredHeatmaps)
                if isempty(map.(obj.RequiredHeatmaps{required}))
                    error(['Expected Heatmap: ',obj.RequiredHeatmaps{required}])
                end
            end
            ok = true; %all passed
          
        end
    end
end


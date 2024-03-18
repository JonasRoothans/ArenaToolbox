classdef Null < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'Null'
        HeatmapModel

        PostSettings
        
    end
    
    methods
        function obj = Null()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        

        
        
        
        function [prediction, confidence, comments] = predictionForVTAs(obj,VTAlist)

                prediction = 1;
                confidence = 1;
                comments = '';
            end

    
    

        function PostSettings = definePostProcessingSettings(obj)

                
            PostSettings.Mode  = 'null';
            
    


        end
            %-------- Postprocessing
    end
    methods (Static)
        
        
        function performReviewPostProcessing(tag,predictionList,PostSettings,pairs)
            %nothing
        end
    end
    
    
    
end



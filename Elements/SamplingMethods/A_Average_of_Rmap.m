classdef A_Average_of_Rmap < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Rmap'}
        Description = {'The average of the Correlation map'};
        Output = []
    end
    
    
    methods
        function [obj] = A_Average_of_Rmap(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            
            
            %data
            map= Map.Amap.Voxels(:);
            roi = IndividualProfile.Voxels(:);
            
            anynan = or(isnan(map),isnan(roi));
            map(anynan) = [];
            roi(anynan) = [];
            
            mean = (map'*roi) / sum(roi);
            
            %mask
          
            obj.Output = mean;

            
            
        end
    end
end

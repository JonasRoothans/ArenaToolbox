classdef A_Average_of_Average < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Amap'}
        Description = {'The average of the average map'};
        Output = []
    end
    
    
    methods
        function [obj] = A_Average_of_Average(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
  
            
            %data
            map= Map.Amap.Voxels;
            roi = IndividualProfile.Voxels>0.5;
            
            %mask
          
            
            %
            bite= map(roi);
            obj.Output = nanmean(bite);

            
            
        end
    end
end

classdef A_AverageNonZeroTmap < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Tmap'}
        Description = {'nothing fancy','Binary ROI >0','Average of NONZERO tmap'};
        Output = []
    end
    
    
    methods
        function [obj] = A_AverageNonZeroTmap(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
  
            
            %data
            map= Map.Tmap.Voxels;
            roi = IndividualProfile.Voxels>0.5;
            
            %mask
          
            
            %
            bite= map(roi);
            bite(bite==0) = [];
            obj.Output = nanmean(bite);

            
            
        end
    end
end

classdef A_averageN < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Nmap'}
        Description = {'The average of the N map'};
        Output = []
    end
    
    
    methods
        function [obj] = A_averageN(Map, IndividualProfile)
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

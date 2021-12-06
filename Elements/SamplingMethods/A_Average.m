classdef A_Average < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Signedpmap'}
        Description = {'nothing fancy, just average of signedpmap'};
        Output = []
    end
    
    
    methods
        function [obj] = A_Average(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
  
            
            %data
            map= Map.Signedpmap.Voxels;
            roi = IndividualProfile.Voxels>0.5;
            
            %mask
          
            
            %
            bite= map(roi);
            obj.Output = mean(bite);

            
            
        end
    end
end

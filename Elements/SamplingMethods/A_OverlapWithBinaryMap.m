classdef A_OverlapWithBinaryMap < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Binarymap'}
        Description = {'Percentage of overlap with the Binary map'};
        Output = []
    end
    
    
    methods
        function [obj] = A_OverlapWithBinaryMap(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            %data
            map= Map.Binarymap.Voxels;
            roi = IndividualProfile.Voxels>0.5;
            
            %mask
          
            %
            bite= map(roi);
            obj.Output = sum(bite(:))/sum(map(:))*100;

            
            
        end
    end
end

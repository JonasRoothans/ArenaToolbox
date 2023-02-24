classdef A_TotalNegativeRmapOfBinaryROI < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Rmap'}
        Description = {'ROI is made binary (>0)','Then overlap with Negative R is counted','Output is the sum'};
        Output = []
    end
    
    
    methods
        function [obj] = A_TotalNegativeRmapOfBinaryROI(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            
            
            %data
            map= Map.Rmap.Voxels(:);
            roi = (IndividualProfile.Voxels(:)>20)*1.0;
            
            anynan = or(isnan(map),isnan(roi));
            map(anynan) = [];
            roi(anynan) = [];
            

            neg = map<-0.3;
            
            ratio = (neg'*roi);
            
            %mask
          
            obj.Output = ratio;

            
            
        end
    end
end

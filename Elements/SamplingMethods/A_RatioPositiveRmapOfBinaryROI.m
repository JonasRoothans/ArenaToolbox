classdef A_RatioPositiveRmapOfBinaryROI < SamplingMethod
    properties %              map         
        RequiredHeatmaps = {'Rmap'}
        Description = {'ROI is made binary (>0)','Then overlap with Negative and Positive R is counted','Output is the ratio'};
        Output = []
    end
    
    
    methods
        function [obj] = A_RatioPositiveRmapOfBinaryROI(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            
            
            %data
            map= Map.Rmap.Voxels(:);
            roi = (IndividualProfile.Voxels(:)>0.5)*1.0;
            
            anynan = or(isnan(map),isnan(roi));
            map(anynan) = [];
            roi(anynan) = [];
            
            pos = map>0;
            neg = map<0;
            
            ratio = (pos'*roi) / (neg'*roi);
            
            %mask
          
            obj.Output = ratio;

            
            
        end
    end
end

classdef A_Pearson < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        Description = 'Correlates both images. NaNs will be removed first.'
        
    end
    
    methods
        function [predictors] = A_Pearson(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            predictors.mapIsOk(Map);  %this is a hack. Do not try this at home.
            
            %---- customize code below
            
            %data
            map = Map.Signedpmap.Voxels;
            roi = IndividualProfile.Voxels;
            
            %filters
            nanfilter = and(~isnan(map),~isnan(roi));
            mask = Map.Tmap.Voxels~=0;
            
            %sample
            bite=corr(...
                map(and(mask,nanfilter)),...
                roi(and(mask,nanfilter)));
            
            predictors=bite;
        end
        
    end
    
    
end



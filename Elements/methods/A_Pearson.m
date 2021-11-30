classdef A_Pearson < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        
    end
    
    methods
        function [predictors] = A_Pearson(Map, IndividualProfile)
            %---- keep this
            obj.mapIsOk(Map)
            
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
                roi(and(mask,nanfilteR)));
            
            predictors=bite;
        end
        
    end
    
    
end



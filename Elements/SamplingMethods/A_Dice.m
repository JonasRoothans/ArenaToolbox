classdef A_Dice < SamplingMethod
    properties %              map
        RequiredHeatmaps = {'Signedpmap','Tmap'}
        
    end
    
    methods
        function [predictors] = A_Dice(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map)
            
            %---- customize code below
            
            %data
            map = Map.Signedpmap.Voxels;
            mask = Map.Tmap.Voxels~=0;
            roi = IndividualProfile.Voxels;
            
            bite=dice(...
                map(mask),...
                roi(mask));
            
            
            predictors=bite;
        end
    end
    
end
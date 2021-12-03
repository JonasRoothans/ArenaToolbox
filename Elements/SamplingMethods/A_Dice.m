classdef A_Dice < SamplingMethod
    properties %              map
        RequiredHeatmaps = {'Signedpmap','Tmap'}
        Description = 'finds the similarity between two binary images'
        
    end
    
    methods
        function [predictors] = A_Dice(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            predictors.mapIsOk(Map);  %this is a hack. Do not try this at home.
            
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
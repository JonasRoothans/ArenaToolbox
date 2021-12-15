classdef A_Dice < SamplingMethod
    properties %              map
        RequiredHeatmaps = {'Signedpmap','Tmap'}
        Description = 'finds the similarity between two binary images'
        Output = [];
        
    end
    
    methods
        function [obj] = A_Dice(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map);  
            
            %---- customize code below
            
            %data
            map = Map.Signedpmap.Voxels;
           % mask is not needed for dice
            roi = IndividualProfile.Voxels;
            
            bite=dice(map>0,roi>0); % positive in signedpmap Vs positive in connectome
            
            
            obj.Output=bite;
        end
    end
    
end
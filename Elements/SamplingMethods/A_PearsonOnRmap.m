classdef A_PearsonOnRmap < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Rmap','Nmap'}
        Description = 'Correlates both images. NaNs will be removed first.'
        Output = [];
    end
    
    methods
        function [obj] = A_PearsonOnRmap(Map, IndividualProfile)
            %---- keep this
           if nargin==0
                return
            end
            obj.mapIsOk(Map);  
            
            %---- customize code below
            
            %data
            map = Map.Rmap.Voxels;
            roi = IndividualProfile.Voxels;
            
            %filters
            nanfilter = and(~isnan(map),~isnan(roi));
            mask = Map.Nmap.Voxels~=0;
            
            %sample
            bite=corr(...
                map(and(mask,nanfilter)),...
                roi(and(mask,nanfilter)));
            
            obj.Output=bite;
        end
        
    end
    
    
end



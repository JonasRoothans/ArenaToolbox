classdef A_SpearmanOnAverage < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Amap', 'Nmap'}
        Description = 'Correlates both images. NaNs will be removed first.'
        Output = [];
    end
    
    methods
        function [obj] = A_SpearmanOnAverage(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map);  
            
            %---- customize code below
            
            %data
            map = Map.Amap.Voxels;
            roi = IndividualProfile.Voxels;
            
            %filters
            nanfilter = and(~isnan(map),~isnan(roi));
            mask = Map.Nmap.Voxels~=0;
            
            %sample
            bite=corr(...
                map(and(mask,nanfilter)),...
                roi(and(mask,nanfilter)),...
                'Type','Spearman');
            
            obj.Output=bite;
        end
        
    end
    
    
end



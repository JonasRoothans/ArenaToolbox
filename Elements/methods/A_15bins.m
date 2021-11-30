classdef A_15bins < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        
    end
    
    methods
        function [predictors] = A_15bins(Map, IndividualProfile)
            %---- keep this
            obj.mapIsOk(Map)
            
            %---- customize code below
            
            %settings
            N_edges = 15;
            edges = linspace(-1,1,N_edges+1);
            
            %data
            map= Map.Signedpmap.Voxels;
            roi = IndividualProfile.Voxels>0.5;
            
            %mask
            mask = Map.Tmap.Voxels~=0;
            
            %
            bite=Map(and(roi,mask));
            f = figure;
            h = histogram(bite,edges);
            predictors = [1,zscore(h.Values)];
            close(f);
            
            
        end
    end
end

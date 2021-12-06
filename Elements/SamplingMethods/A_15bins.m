classdef A_15bins < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        Description = {'This method was used in the Dystonia Paper',...
            'A mask is created based on where the model exists',...
            'Then a binary ROI samples the heatmap',...
            'A 15 bin histogram is calculated for this sample',...
            'the output is the zscored histogram'};
        Output = []
    end
    
    
    methods
        function [obj] = A_15bins(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
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
            bite= map(and(roi,mask));
            f = figure;
            h = histogram(bite,edges);
            predictors = [1,zscore(h.Values)];
            obj.Output = predictors;
            close(f);
            
            
        end
    end
end

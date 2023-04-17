classdef A_9bins < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        Description = {'This concept was used in the Dystonia Paper but with more bins',...
            'A mask is created based on where the model exists',...
            'Then a binary ROI samples the heatmap',...
            'A 9 bin histogram is calculated for this sample',...
            'the output is the zscored histogram'...
            'This method supports bilateral sampling using subfolders!'};
        Output = []
    end
    
    
    methods
        function [obj] = A_9bins(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            %settings
            N_edges = 9;
            edges = linspace(-1,1,N_edges+1);
            
            
            bite = [];
            
            lowerthreshold =0;
            while any(IndividualProfile.Voxels(:)>(0.5+lowerthreshold))
                %data
                map= Map.Signedpmap.Voxels;
                roi = IndividualProfile.Voxels>(0.5+lowerthreshold);

                %mask
                mask = Map.Tmap.Voxels~=0;

                %
                bite=[bite;map(and(roi,mask))];

                %next iteration
                lowerthreshold = lowerthreshold+1;
            end
            f = figure;
            h = histogram(bite,edges);
            predictors = [1,zscore(h.Values)];
            obj.Output = predictors;
            close(f);
            
            
        end
    end
end

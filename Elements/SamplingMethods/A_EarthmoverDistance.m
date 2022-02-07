classdef A_EarthmoverDistance < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap'}
        Description = {'This method was used in the Dystonia Paper',...
            'A mask is created based on where the model exists',...
            'Then a binary ROI samples the heatmap',...
            'A 11 bin histogram is calculated for this sample',...
            'the output is the zscored histogram'...
            'This method supports bilateral sampling using subfolders!'};
        Output = []
    end
    
    
    methods
        function [obj] = A_11bins(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            
            %rescale to [0 1]
            Map=rescale(Map);
            
            
            %settings
           
            f = figure;
            h = histogram(bite,'Normalization','probability');
            predictors = [1,zscore(h.Values)];
            obj.Output = predictors;
            close(f);
            
            
        end
    end
end

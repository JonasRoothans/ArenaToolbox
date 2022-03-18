classdef A_EarthmoverDistance < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap'}
        Description = {'This method changes a spatial signal into a curve based signal' ... 
            'spatial into spatiotemporal and then calculates wasserstein distance to move profile to template'};
        Output = []
    end
    
    
    methods
        function [obj] = A_EarthmoverDistance(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            
            
            %rescale to [0 1]
            Map=rescale(Map);
            
            %vectorise map
            Map=Map(:);
            Probability_sum=sum(Map(:));
            Probability_matrix_map=Map/Probability_sum;
            
            %find index of data
            location_index=find(Map);
            
           
   
            
            %vectorise Individual Profile
            IndividualProfile=IndividualProfile(:);
            Probability_sum_IP=sum(IndividualProfile(:));
            Probability_matrix_IP=IndividualProfile/Probability_sum_IP;
            
            
           [flow value]=emd(1:numel(IndividualProfile),1:numel(Map),double(Probability_matrix_IP),double(Probability_matrix_map), @gdf);
            
                
%             get probability distribution of map
            Map2=histogram(Map,'Normalization','probability');
            
%             get probability distribution of individual profile
            IndividualProfile2=histogram(IndividualProfile,'Normalization','probability');
            [flow value]=emd(1:numel(IndividualProfile),1:numel(Map),double(Probability_matrix_IP),double(Probability_matrix_map), @gdf);
            
            %settings
            
           
            predictors = [1,zscore(h.Values)];
            obj.Output = predictors;
            close(f);
            
            
        end
    end
end

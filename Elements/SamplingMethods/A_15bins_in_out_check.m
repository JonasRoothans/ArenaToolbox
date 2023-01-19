classdef A_15bins_in_out_check < SamplingMethod
    properties %              map          mask
        RequiredHeatmaps = {'Signedpmap', 'Tmap'}
        Description = {'This method was used in the Dystonia Paper',...
            'A mask is created based on where the model exists',...
            'Then a binary ROI samples the heatmap',...
            'A 15 bin histogram is calculated for this sample',...
            'the output is the zscored histogram',...
            'This method supports bilateral sampling using subfolders!',...
            'Attention: VTAs that are >50% out will be ignored!'
            };
        Output = []
        MinimumOverlapPercentage = 50%
    end
    
    
    methods
        function [obj] = A_15bins_in_out_check(Map, IndividualProfile)
            %---- keep this
            if nargin==0
                return
            end
            obj.mapIsOk(Map); 
            
            %---- customize code below
            
            %settings
            N_edges = 15;
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
               
                % IN/OUT CHECK
                overlap = and(roi,mask);
                if sum(overlap(:)) / sum(roi(:)) < obj.MinimumOverlapPercentage/100
                    reject = true;
                else
                    reject = false;
                end
                    
                
                

                %next iteration
                lowerthreshold = lowerthreshold+1;
            end
            f = figure;
            h = histogram(bite,edges);
            predictors = [1,zscore(h.Values)];
            obj.Output = predictors;
            if reject
                obj.Output = nan;
            end
            close(f);
            
            
        end
    end
end

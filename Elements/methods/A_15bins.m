function [predictors] = A_15bins(sample)

%settings
edges = -1:0.13333333333:1;

f = figure;
h = histogram(sample,edges);
predictors = [1,zscore(h.Values)];
close(f);


end


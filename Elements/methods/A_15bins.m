function [predictors] = A_15bins(Map, IndividualProfile, Mask)


if nargin <3
    error(' please add a tmap mask for the signedp map')
end


bite=Map.Voxels(and(IndividualProfile.Voxels>0.5,Mask.Voxels~=0));


%settings
edges = -1:0.13333333333:1;

%take bite
f = figure;
h = histogram(bite,edges);
predictors = [1,zscore(h.Values)];
close(f);


end


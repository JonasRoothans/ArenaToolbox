function [predictors] = A_Pearson(Map, IndividualProfile, Mask)

if nargin <3
  
    error(' please add a tmap mask for the signedp map')
end


  bite=corr(Map.Voxels(and(Mask.Voxels~=0,~isnan(Map.Voxels))),IndividualProfile.Voxels(~isnan(IndividualProfile.Voxels)));


predictors=bite;


end
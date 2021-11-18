function [predictors] = A_Dice(Map, IndividualProfile, Mask)

if nargin <3
  
    error(' please add a tmap mask for the signedp map')
end


bite=dice(Map.Voxels(Mask.Voxels~=0),IndividualProfile.Voxels);


predictors=bite;


end
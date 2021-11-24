function [predictors] = A_15bins(Map, IndividualProfile, varargin)

p=inputParser;

if nargin>2
    
defaultmask=varargin{2};

checkInput_A_15=@(x) isa(x,'VoxelData'); 

addRequired(p,'Map', @checkInput_A_15);
addRequired(p,'IndividualProfile', @checkInput_A_15);
addParameter(p,'Mask',defaultmask, @checkInput_A_15);

p.KeepUnmatched=false;
   
bite=Map.Voxels(and(IndividualProfile.Voxels>0.5,defaultmask.Voxels~=0));

else
    warning ('no mask selected, proceeding without masking')
     
    bite=Map.Voxels(IndividualProfile.Voxels>0.5);
end
    

%settings
edges = -1:0.13333333333:1;

%take bite
f = figure;
h = histogram(bite,edges);
predictors = [1,zscore(h.Values)];
close(f);


end


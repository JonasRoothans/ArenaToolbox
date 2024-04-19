function [outputArg1,outputArg2] = HeatmapMaker_DistanceToHotspot(menu,eventdata,scene)
%HEATMAPMAKER_DISTANCETOHOTSPOT Summary of this function goes here
%   Detailed explanation goes here
vds = VoxelDataStack;
[vds,filename] = vds.loadStudyDataFromRecipe;

[~,~, actor] = scene.selectActor;
actor_cog = actor.getCOG;

names = {};
distances = [];
scores = vds.Weights';
for iPatient = 1:length(vds)
    names{iPatient,1} = vds.LayerLabels{iPatient}{1};
    for iSide = 1:depth(vds)
        vd = vds.getVoxelDataAtPosition(iPatient,iSide);
        cog = vd.getmesh(0.5).getCOG;
        distance = norm(cog-actor_cog);
        distances(iPatient,iSide) = distance;
    end
end


t = table(names,distances,scores)
assignin('base','t',t)
disp('table is saved in workspace as ''t''')
end


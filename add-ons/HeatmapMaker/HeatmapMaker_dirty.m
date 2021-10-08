function [mdl] = sweetspotstation_makerecipe(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here



HM = Heatmap;
HM.loadHeatmap;

if isempty(HM.VoxelDataStack)
warning('need to make a tool that will then load the VoxelDataStack via .mat file, or other .heatmap file')
end



R = RegressionRoutine();
R.Heatmap = HM;
R.VoxelDataStack = HM.VoxelDataStack;
R.SamplingSettings = '15bin';
mdl = R.execute();




end


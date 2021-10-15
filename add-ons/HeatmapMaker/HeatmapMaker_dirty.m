function [mdl] = sweetspotstation_dirty(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here



HM = Heatmap;
waitfor(msgbox('Load a heatmap. Ideally one that contains source data (*_wVDS.heatmap)'))
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


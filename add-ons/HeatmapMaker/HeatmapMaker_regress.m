function [mdl] = HeatmapMaker_regress(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here



HM = Heatmap;
HM.loadHeatmap;

sm = SamplingMethod.choosedlg();

VDS = VoxelDataStack;
VDS.templateSpace(HM);
VDS.loadStudyDataFromRecipe;

R = RegressionRoutine();
R.Heatmap = HM;
R.VoxelDataStack = VDS;
R.SamplingMethod = sm;
mdl = R.execute();

R.askForSaving()




end


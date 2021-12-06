function [outputArg1,outputArg2] = HeatmapMaker_cook(menu,eventdata,scene)
%SWEETSPOTSTATION_MAKERECIPE Summary of this function goes here
%   Detailed explanation goes here


heatmap=Heatmap;
heatmap.fromVoxelDataStack();
heatmap.save();



end
          

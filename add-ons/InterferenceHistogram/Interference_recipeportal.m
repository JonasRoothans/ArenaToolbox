function [outputArg1,outputArg2] = Interference_recipeportal()

if ~exist('HeatmapMaker_makerecipe','file')
    error('Heatmapmaker add-on appears to be unavailable')
end

eval('HeatmapMaker_makerecipe')

end


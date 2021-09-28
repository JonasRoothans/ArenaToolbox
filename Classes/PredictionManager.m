classdef PredictionManager < handle
    %HEATMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Heatmaps = {};
        Predictions = Prediction.empty
    end
    
    methods
        function obj = PredictionManager()
            %fill up the heatmaplist
            obj.loadHeatmaps();
        end
        
        function obj = loadHeatmaps(obj)
            heatmapdir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Elements','heatmaps');
            subfolders = A_getsubfolders(heatmapdir);
            
            for iSubFolder = 1:numel(subfolders)
                addpath(fullfile(subfolders(iSubFolder).folder,subfolders(iSubFolder).name))
                eval(['m = ',subfolders(iSubFolder).name,';'])
                if isa(m,'HeatmapModelSupport')
                    obj.Heatmaps{end+1} = m;
                else
                        disp([subfolders.name,' does not appear to be a Heatmap. Make sure the class inherits "Heatmap"'])
                end
                    
            end
               
        end
        
        function p = newPrediction(obj,therapy, heatmap)
            if nargin==2
                heatmap = obj.selectHeatmap();
            end
            p = Prediction(therapy,heatmap);
            p.runVTAPrediction();
            obj.Predictions(end+1) = p;
        end
        
        function heatmap = selectHeatmap(obj)
            allnames = cellfun(@(x) x.Tag,obj.Heatmaps,'UniformOutput',0);
            index = listdlg('PromptString','Select a heatmap / prediction model:',...
                'ListString',allnames,'ListSize',[200,100],'SelectionMode','single');
            heatmap = obj.Heatmaps{index};
        end
            
            
        
        
    end
end


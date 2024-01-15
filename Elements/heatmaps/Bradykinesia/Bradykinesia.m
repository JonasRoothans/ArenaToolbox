classdef Bradykinesia < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'Bradykinesia'
        HeatmapModel
        RiskThresholds = [0.0119, 0.2957]; %will convert a value to 0,1,2 (2  = high risk)
        
    end
    
    methods
        function obj = CognitiveDecline()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function [risk,score] = predictVD(obj,VD)
            if isempty(obj.HeatmapModel)
                obj = obj.load();
            end
            
            %use intrinsic method:
            score = obj.HeatmapModel.predictVoxelData(VD);
            risk = 1;
            risk(score>obj.RiskThresholds(2)) = 2;
            risk(score<obj.RiskThresholds(1)) = 0;
            
            
        end
        
        function obj = load(obj)
            load('model.mat')
            obj.HeatmapModel = mdl;
            
        end
        
        %--- required:
        function PostSettings = definePostProcessingSettings(obj)
            PostSettings = nan;
        end
        
        function [prediction, confidence, comments] = predictionForVTAs(obj,VTAlist)
            sample = [];
            comments = {};
            confidence = [];
            for iVTA = 1:numel(VTAlist)
                VTA = VTAlist(iVTA);
                
                switch class(VTA.Volume)
                    case 'VoxelData'
                        VTA_voxelData = VoxelData(double(VTA.Volume.Voxels > 0.5),VTA.Volume.R);
                    case 'Mesh'
                        VTA_voxelData = VoxelData(double(VTA.Volume.Source.Voxels > VTA.Volume.Settings.T),VTA.Volume.Source.R);
                end
                
                %check the space and fix if it's not matching.
                if VTA.Space~=Space.MNI2009b
                    error('wrong space')
                end
                
                %predict
                [prediction(iVTA),comments{iVTA}] = obj.predictVD(VTA_voxelData);
                
                %check confidence
                %sample map to see if it's overlapping enough with the model!
                    allvoxels = obj.HeatmapModel.Heatmap.Nmap.Voxels(VTA_voxelData.Voxels>0.5);
                    outofmodel = sum(allvoxels==0);
                    if outofmodel/numel(allvoxels)>0.3
                        warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);

                    end
                    confidence(iVTA) = 1-outofmodel/numel(allvoxels);
                
            end
            
            
            
            
            
        end
        
        %get the voxeldata
        
        
        
    end
end


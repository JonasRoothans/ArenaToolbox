classdef FoG_2024 < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'Freezing of gait (2024)'
        HeatmapModel
        PostSettings
        
    end
    
    methods
        function obj = FoG_2024()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function [score] = predictVD(obj,VD)
            if isempty(obj.HeatmapModel)
                obj = obj.load();
            end
            
            %use intrinsic method:
            score = obj.HeatmapModel.predictVoxelData(VD);
           
            
            
        end
        
        function obj = load(obj)
            load('FoG.mat')
            obj.HeatmapModel = mdl;
            
        end
        
        
        function [prediction, confidence, comments] = predictionForVTAs(obj,VTAlist)
             if isempty(obj.HeatmapModel)
                obj = obj.load();
             end
            
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
                
                %check if it is on the right side then mirror
                if VTA_voxelData.getcog.x >  1 %
                    VTA_voxelData = VTA_voxelData.mirror();
                end
                
                %warp to heatmap
                VTA_voxelData.warpto(obj.HeatmapModel.Heatmap.Signedpmap)
                
                %check confidence
                %sample map to see if it's overlapping enough with the model!
                allvoxels = obj.HeatmapModel.Heatmap.Nmap.Voxels(VTA_voxelData.Voxels>0.5);
                outofmodel = sum(allvoxels==0);
                if outofmodel/numel(allvoxels)>0.3
                    warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);
                    
                end
                confidence(iVTA) = 1-outofmodel/numel(allvoxels);
                
                %add them together
                if iVTA == 1
                    together = VTA_voxelData;
                else
                    if not(all(together.size==VTA_voxelData.size))
                        %something went wrong.. They should be warped to
                        %the model.
                        keyboard
                    end
                    together = together+VTA_voxelData;
                end
            end
                %predict

            [prediction] = obj.predictVD(together);
            comments = '';
   
                
                
                
            end

    
    

        function PostSettings = definePostProcessingSettings(obj)


            PostSettings.Mode  = 'default';
            obj.PostSettings = PostSettings;
            
    


        end
            %-------- Postprocessing
    end
    methods (Static)
        
        
        function performReviewPostProcessing(tag,predictionList,PostSettings,pairs)
%             keybaord
%             %hier verder!! opt = {'risk categories', 'rawvalue'};
%             switch PostSettings.Mode
%                 case 'risk categories'
%                     keyboard
%                 case 'raw value'
%                     keyboard
%             end
%             HeatmapModelSupport.printPredictionList(tag,predictionList,pairs,[],'ascend')
        end
    end
    
    
    
end



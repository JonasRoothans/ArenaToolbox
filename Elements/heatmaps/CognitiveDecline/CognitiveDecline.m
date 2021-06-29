classdef CognitiveDecline < Heatmap & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'Cognitive Decline'
        HeatmapModel

    end
    
    methods
        function obj = CognitiveDecline()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function obj = load(obj)
            map = VoxelData;
            map.loadnii('cogdec_SE_vs_noSE_orig_fz_use_design_palm_vox_tstat_yeo1000_dil_precomputed_corr_R_Fz.nii')
            obj.HeatmapModel = map;
            
        end
        
        function [prediction, confidence comments] = predictionForVTAs(obj,VTAlist)
            sample = [];
            comments = {};
            confidence = [];
            for iVTA = 1:numel(VTAlist)
                lastwarn('');
                thisVTA = VTAlist(iVTA);
                [newSample,newConfidence] = obj.sampleWithVTA(thisVTA);
                sample = [sample,newSample'];
                confidence(iVTA) = newConfidence;
                comments{iVTA} = lastwarn;
            end
            prediction = obj.predictForSample(sample);
        end
        
        function [sample,confidence] = sampleWithVTA(obj,VTA)
            comment = '';
            %load the model
            if isempty(obj.HeatmapModel)
                obj = obj.load();
            end
            
            %get the voxeldata of the VTA
            switch class(VTA.Volume)
                case 'VoxelData'
                    VTA_voxelData = VoxelData(double(VTA.Volume.Voxels > 0.5),VTA.Volume.R);
                case 'Mesh'
                     VTA_voxelData = VoxelData(double(VTA.Volume.Source.Voxels > VTA.Volume.Settings.T),VTA.Volume.Source.R);
            end
            
            %check the space and fix if it's not matching.
            if VTA.Space~=Space.MNI2009b
                VTA_voxelData = CognitiveDecline.fixSpace(VTA.Space,VTA_voxelData);
            end
            

            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel);
            
            %sample map to see if it's overlapping enough with the model!
            allvoxels = obj.HeatmapModel.Voxels(VTA_voxelData.Voxels>0.5);
            outofmodel = sum(allvoxels==0);
            if outofmodel/numel(allvoxels)>0.3
                warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);
                
            end
            confidence = 1-outofmodel/numel(allvoxels);
            
            %sample those voxels where VTA and model both are.
            sample = allvoxels;
        end
        
        function y = predictForSample(obj,sample)
            if mean(sample) < 0
                y = 0;
            elseif mean(sample) < 0.15
                y = 1;
            else
                y = 2;
      
            end
            
        end
        
        

    end
    

    
    methods (Static)
        function out = fixSpace(oldspace,voxeldata)
            switch oldspace
                case Space.Legacy
                    T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                    out = voxeldata.imwarp(T);
                case Space.Unknown
                    error('wrong space')
                case Space.PatientNative
                    error('wrong space')
            end
        end
        
        function settings = definePostProcessingSettings()
            settings = nan;
        end
        
        
        function VTA_voxelData = mirror(VTA_voxelData)
            T = load('Tapproved.mat');
            Tvta = T.mni2rightgpi*T.leftgpi2mni;
            VTA_voxelData = VTA_voxelData.imwarp(Tvta);
        end
        
    end
end


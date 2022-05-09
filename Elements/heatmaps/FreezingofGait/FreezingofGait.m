classdef FreezingofGait < HeatmapModelSupport & handle
    %Freezing of Gait parkinson Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'FreezingofGait [beta]'
        HeatmapModel
        b=[-0.634200000000000;0.144400000000000;...
            -1.07900000000000;0.960900000000000;-0.0974000000000000;0.783700000000000;...
            0.722300000000000;-0.627400000000000;-0.327400000000000;-1.98830000000000;0.831400000000000;-0.531100000000000;...
            0;1.80780000000000;-1.18860000000000;1.37500000000000]; % removed first b value with zero
        edges = -1:0.13333333333:1;
    end
    
     methods
        function obj = FreezingofGait()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function obj = load(obj)
            map  = load('FreezingofGait_heatmap.heatmap','-mat');
            map=map.heatmap.Signedpmap;
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
                VTA_voxelData = FreezingofGait.fixSpace(VTA.Space,VTA_voxelData);
            end
            

            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel);
            
            %make sure to mirror VTAs if heatmap unilateral
            CoG_map=obj.HeatmapModel.getcog;
            CoG_VTA=VTA_voxelData.getcog;
            if sign(CoG_map.x)~=sign(CoG_VTA.x)
               VTA_voxelData=VTA_voxelData.mirror;
            end
            
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
            h = histogram(sample,obj.edges);
            X = [1,zscore(h.Values)];
            y = X*obj.b;
            delete(h)
        end
        end
        
        



methods(Static)

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
    
    function performReviewPostProcessing(tag,predictionList,filterSettings,pairs)
    
    
    HeatmapModelSupport.printPredictionList(tag,predictionList,pairs);
    
    
    end
    
    
    function VTA_voxelData = mirror(VTA_voxelData)
    T = load('Tapproved.mat');
    Tvta = T.mni2rightgpi*T.leftgpi2mni;
    VTA_voxelData = VTA_voxelData.imwarp(Tvta);
    end
    end

end

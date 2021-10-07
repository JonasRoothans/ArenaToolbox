classdef GPiDystonia < HeatmapModelSupport & handle
    %GPIDYSTONA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Tag = 'GPiDystonia'
        HeatmapModel
        b = [57.6598809951595;12.0664757620877;15.6438035692808;4.57530292424259;-3.13275389368958;-14.8795376587032;-14.5891044360106;0;16.9708673876284;12.6398172008286;8.23591228720219;13.9285582004609;4.62858440753228;-25.9956758412821;17.0527413996103;8.60861313752535];
        edges = -1:0.13333333333:1;
    end
    
    methods
        function obj = GPiDystonia()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        
        function obj = load(obj)
            sweetspot  = load('Final_Bilateral_t_p_average.swtspt','-mat');
            sleft = sweetspot.sweetspot.left;
            obj.HeatmapModel.tmap = VoxelData(sleft.sweetspotArray(1).Data,sleft.imref);
            obj.HeatmapModel.pmap = VoxelData(sleft.sweetspotArray(2).Data,sleft.imref);
            obj.HeatmapModel.signed_p_map = VoxelData((1-obj.HeatmapModel.pmap.Voxels).*sign(obj.HeatmapModel.tmap.Voxels),sleft.imref);
        end
        
        function [prediction, confidence, comments] = predictionForVTAs(obj,VTAlist)
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
            
            %get the voxeldata
            switch class(VTA.Volume)
                case 'VoxelData'
                    VTA_voxelData = VoxelData(double(VTA.Volume.Voxels > 0.5),VTA.Volume.R);
                case 'Mesh'
                     VTA_voxelData = VoxelData(double(VTA.Volume.Source.Voxels > VTA.Volume.Settings.T),VTA.Volume.Source.R);
            end
            
            %check the space and fix if it's not matching.
            if VTA.Space~=Space.Legacy
                VTA_voxelData = GPiDystonia.fixSpace(VTA.Space,VTA_voxelData);
            end
            
            %check if it is on the right side then mirror
            if VTA_voxelData.getcog.x <  1 %legacy is LPS, so negative X = right side
                VTA_voxelData = GPiDystonia.mirror(VTA_voxelData);
            end
            
            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel.signed_p_map);
            
            %sample map to see if it's overlapping enough with the model!
            allvoxels = obj.HeatmapModel.pmap.Voxels(VTA_voxelData.Voxels>0.5);
            outofmodel = sum(allvoxels==0);
            if outofmodel/numel(allvoxels)>0.3
                warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);
                
            end
            confidence = 1-outofmodel/numel(allvoxels);
            
            %sample those voxels where VTA and model both are.
            sample = obj.HeatmapModel.signed_p_map.Voxels(and(...
                VTA_voxelData.Voxels>0.5,...
                obj.HeatmapModel.pmap.Voxels>0));
        end
        
        function y = predictForSample(obj,sample)
            h = histogram(sample,obj.edges);
            X = [1,zscore(h.Values)];
            y = X*obj.b;
            delete(h)
        end
        

    end
    
    methods (Static)
        function out = fixSpace(oldspace,voxeldata)
            switch oldspace
                case Space.MNI2009b
                    T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                    out = voxeldata.imwarp(T);
                case Space.Unknown
                case Space.PatientNative
            end
        end
        
        function VTA_voxelData = mirror(VTA_voxelData)
            T = load('Tapproved.mat');
            Tvta = T.mni2rightgpi*T.leftgpi2mni;
            VTA_voxelData = VTA_voxelData.imwarp(Tvta);
        end
        
        function filterSettings = definePostProcessingSettings()
            filterSettings = nan;
            if 0 %temporarily switched off
                userinput = inputdlg({'Minimal confidence of the heatmap [0-1]',...
                    'Amplitude optimization based on  n = ',...
                    'Maximal accepted amplitude deviation (sigma)'},...
                    'Post processing',...
                    1,...
                    {'0.5','5','1'});
                filterSettings.minConfidence = str2num(userinput{1});
                filterSettings.n = str2num(userinput{2});
                filterSettings.sigma = str2num(userinput{3});
            end
        end
        
        function performReviewPostProcessing(tag,predictionList,filterSettings,pairs)
            
            blackOrRed = GPiDystonia.filterPredictions(predictionList,filterSettings);
            HeatmapModelSupport.printPredictionList(tag,predictionList,pairs,blackOrRed);
            
            
        end
        
        function blackOrRed = filterPredictions(predictionList,filterSettings)
            if isnan(filterSettings)
                blackOrRed = ones(size(predictionList));
                return
            end
            [sorted,order] = sort(vertcat(predictionList.Output),'descend');
            powerConsumption = [];
            
            for iPair = 1:length(predictionList)
                sum_of_amplitudes = 0;
                for iVTA = 1:numel(predictionList(iPair).Input.VTAs)
                    sum_of_amplitudes  =  sum_of_amplitudes+ predictionList(iPair).Input.VTAs(iVTA).Settings.amplitude;
                end
                powerConsumption(iPair) = sum_of_amplitudes/iVTA;
            end
            
            
            power_sorted = powerConsumption(order);
            
            %             %-- confidence check
            leastconfidence = min(vertcat(predictionList(:).Confidence)');
            if length(leastconfidence)==1
                passedConfidenceTest = vertcat(predictionList(:).Confidence)' > filterSettings.minConfidence;
            else
                passedConfidenceTest = leastconfidence > filterSettings.minConfidence;
            end
            %
            %             %-- outlier amplitudes
            power_filtered_and_sorted = power_sorted(passedConfidenceTest);
            
            if length(power_filtered_and_sorted)<filterSettings.n
                filterSettings.n = length(power_filtered_and_sorted);
            end
            mu_power = mean(power_filtered_and_sorted(1:filterSettings.n));
            sigma_power = std(power_filtered_and_sorted(1:filterSettings.n));
            amp_cutoff = mu_power+sigma_power*filterSettings.sigma;
            passedAmpTest = power_sorted<amp_cutoff;
            
            if sigma_power==0 %if all amps are equal, all should pass.
                passedAmpTest = true(1,length(passedAmpTest));
            end
%             
        end
        
        
    end
end


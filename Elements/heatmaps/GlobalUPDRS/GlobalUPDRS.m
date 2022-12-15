classdef GlobalUPDRS < HeatmapModelSupport & handle
    %Freezing of Gait parkinson Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Tag = 'GlobalUPDRS [beta]'
        HeatmapModel
%         b=[0;-0.0257;-0.334; -0.0487;0.3151;-0.0198;-0.2735;-0.3101; -0.2684
%          0;0.2608;-0.3608; -0.3218; -0.2052;0.2308;-0.0830]; 
        b=[0;52.8276;2.4813;1.4668;-0.9377;-4.1356;4.8413;3.3430;-4.0142;0;-3.1444;-7.2003;4.1323;9.8561;13.0352;-9.9589;-1.0060] % removed first b value with zero
        edges = -1:0.13333333333:1;
    end
    
     methods
            
        function obj = FreezingofGait()
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
        function toggle_callonHeatmap(obj)
            notify(obj,'callonHeatmap')
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
            X = [1,1,zscore(h.Values)];
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
    
    function  filterSettings = definePostProcessingSettings(obj)
        
        
        Prompt = {};
        DefAns = struct([]);
       formats = struct('type', {}, 'style', {}, 'items', {}, ...
            'format', {}, 'limits', {}, 'size', {});



        Options.Resize = 'on';
        Options.Interpreter = 'tex';
        Options.CancelButton = 'on';
        Options.ApplyButton = 'on';
        Options.ButtonNames = {'Continue','Cancel'}; %<- default names, included here just for illustration
        Options.Dim = 4; % Horizontal dimension in fields

Title='filter sets window, to be applied after monopolar review';
   
      
        
        
        Prompt(1,:) = {'Minimal confidence of the heatmap [0-1]', 'minimal',[]};

        formats(1,1).type   = 'edit';
        formats(1,1).format = 'float';
        formats(1,1).limits = [0 1];
        DefAns(1).minimal=0.85;
        
        Prompt(end+1,:)={'Amplitude optimization based on  n = ', 'Amplitude',[]};
        formats(2,1).type   = 'edit';
        formats(2,1).format = 'float';
        formats(2,1).limits = [0 5];
        DefAns.Amplitude=2;
        
        
        Prompt(end+1,:)={'Maximal accepted amplitude deviation (sigma)', 'Sigma',[]};
        formats(3,1).type   = 'edit';
        formats(3,1).format = 'integer';
        formats(3,1).limits = [0 4];
        DefAns.Sigma= 3;
        
        Prompt(end+1,:)={'filtering based on secondary heatmap', 'heatmap',[]};
        formats(4,1).type = 'edit';
        formats(4,1).format = 'file';
        formats(4,1).items = {'*.swtspt';'*.mat';'*.heatmap';'*.nii'};
        formats(4,1).limits = [0 1]; % single file get
        formats(4,1).size = [-1 0];
         DefAns.heatmap= pwd;
        
   
        Prompt(end+1,:)={'select heatmap', 'heatmapchoice',[]};
        formats(5,1).type = 'list';
        formats(5,1).style = 'listbox';
        formats(5,1).format = 'text'; % Answer will give value shown in items, disable to get integer
        formats(5,1).items = {'positive (improvement)';'negative (worsening)';'no change '};
        formats(5,1).limits = [0 4]; % multi-select
        formats(5,1).size = [140 80];
       
        DefAns.heatmapchoice = {'positive (improvement)'};

        
        [answer, cancelled] = inputsdlg(Prompt, Title, formats, DefAns,Options);
        
        if ~isempty(filtersettings)
            disp('not empty')
        end

        


      
    end
    
    function performReviewPostProcessing(tag,predictionList,filterSettings,pairs)
    
        if isfield(filterSettings,'FOGroutineFilteringRoutine')
            %this routine requires to do nothing here.. All postprocessing
            %is within "FreezingOfGait.m"  in "performReviewPostProcessing"
            return
        end
    
    HeatmapModelSupport.printPredictionList(tag,predictionList,pairs);
    
    
    end
    
    
    function VTA_voxelData = mirror(VTA_voxelData)
    T = load('Tapproved.mat');
    Tvta = T.mni2rightgpi*T.leftgpi2mni;
    VTA_voxelData = VTA_voxelData.imwarp(Tvta);
    end
    end

end
